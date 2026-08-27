#!/usr/bin/env bash
#
# HALF STEP — build the HTML5 export and push it to itch.io without GitHub
# Actions. Same steps the workflow runs: validate, test, export, butler push.
#
#   BUTLER_API_KEY=... tools/deploy_itch.sh              # build, test and push
#   tools/deploy_itch.sh --build-only                    # stop after the export
#   tools/deploy_itch.sh --skip-tests                    # export from a known-good tree
#
# A GitHub repository secret cannot be read outside a workflow run, so the key
# has to reach this script through the environment: export BUTLER_API_KEY in the
# shell, or add it to the environment variables of the Claude Code environment
# so agent sessions can deploy on request.
#
# Downloads Godot, the web export templates and butler on first use and caches
# them under HALF_STEP_CACHE (default ~/.cache/half-step).

set -euo pipefail

ITCH_CHANNEL="${ITCH_CHANNEL:-jungrok5/half:html5}"
CACHE="${HALF_STEP_CACHE:-$HOME/.cache/half-step}"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD="$ROOT/build/web"

BUILD_ONLY=0
SKIP_TESTS=0
for argument in "$@"; do
  case "$argument" in
    --build-only) BUILD_ONLY=1 ;;
    --skip-tests) SKIP_TESTS=1 ;;
    -h|--help) sed -n '2,20p' "${BASH_SOURCE[0]}"; exit 0 ;;
    *) echo "unknown option: $argument" >&2; exit 2 ;;
  esac
done

log() { printf '\n\033[1m==> %s\033[0m\n' "$*"; }

fetch() {
  curl --fail --location --silent --show-error --retry 5 --retry-all-errors --output "$1" "$2"
}

# --- Godot and the web export templates -------------------------------------
GODOT_BIN="$("$ROOT/tools/setup_godot.sh")"

# --- validate and test ------------------------------------------------------
log "Importing project"
"$GODOT_BIN" --headless --path "$ROOT" --editor --quit >/dev/null

if [ "$SKIP_TESTS" -eq 0 ]; then
  for suite in test_runner step_cycle_test audio_test input_integration_test; do
    log "Running $suite"
    "$GODOT_BIN" --headless --path "$ROOT" --script "res://tests/$suite.gd"
  done
fi

# --- export -----------------------------------------------------------------
log "Exporting web release"
rm -rf "$BUILD"
mkdir -p "$BUILD"
"$GODOT_BIN" --headless --path "$ROOT" --export-release Web "$BUILD/index.html" >/dev/null
[ -s "$BUILD/index.wasm" ] || { echo "export produced no index.wasm" >&2; exit 1; }
du -sh "$BUILD"

if [ "$BUILD_ONLY" -eq 1 ]; then
  log "Built $BUILD (not pushed)"
  exit 0
fi

# --- butler -----------------------------------------------------------------
if [ -z "${BUTLER_API_KEY:-}" ]; then
  cat >&2 <<'MSG'
BUTLER_API_KEY is not set, so the build cannot be pushed.

The GitHub repository secret is only readable inside a GitHub Actions run; it
cannot be handed to this script. Provide the key through the environment:

  export BUTLER_API_KEY=...        # get one at https://itch.io/user/settings/api-keys

The build is ready under build/web and can be uploaded by hand instead.
MSG
  exit 1
fi

BUTLER="$CACHE/butler/butler"
if [ ! -x "$BUTLER" ]; then
  log "Installing butler"
  mkdir -p "$CACHE/butler"
  fetch "$CACHE/butler.zip" "https://broth.itch.zone/butler/linux-amd64/LATEST/archive/default"
  unzip -o -q "$CACHE/butler.zip" -d "$CACHE/butler"
  rm -f "$CACHE/butler.zip"
  chmod +x "$BUTLER"
fi
log "butler: $("$BUTLER" version)"

log "Validating build"
"$BUTLER" validate "$BUILD"

VERSION="$(git -C "$ROOT" rev-parse --short=12 HEAD 2>/dev/null || date -u +%Y%m%d%H%M)"
log "Pushing to $ITCH_CHANNEL as $VERSION"
"$BUTLER" push "$BUILD" "$ITCH_CHANNEL" --userversion "$VERSION"
log "Deployed $VERSION to $ITCH_CHANNEL"
