#!/usr/bin/env bash
#
# Install Godot and the web export templates, then report the binary.
#
# One implementation for both local builds and CI, so a green workflow means the
# same engine and templates a developer gets. Nothing is downloaded from a
# third-party GitHub Action: the engine and templates come straight from the
# godotengine/godot releases, the way jungrok5/super-vs does it.
#
#   GODOT_BIN="$(tools/setup_godot.sh)"     # path on stdout, progress on stderr
#
# Inside GitHub Actions it also exports GODOT_BIN and puts `godot` on PATH.
# Everything is cached under HALF_STEP_CACHE (default ~/.cache/half-step), so a
# workflow that restores that directory skips the download entirely.

set -euo pipefail

GODOT_VERSION="${GODOT_VERSION:-4.7.2}"
CACHE="${HALF_STEP_CACHE:-$HOME/.cache/half-step}"
TEMPLATE_DIR="$HOME/.local/share/godot/export_templates/${GODOT_VERSION}.stable"
GODOT_BIN="$CACHE/Godot_v${GODOT_VERSION}-stable_linux.x86_64"
RELEASE="https://github.com/godotengine/godot/releases/download/${GODOT_VERSION}-stable"

log() { printf '\033[1m==> %s\033[0m\n' "$*" >&2; }

fetch() {
	curl --fail --location --silent --show-error --retry 5 --retry-all-errors --output "$1" "$2"
}

mkdir -p "$CACHE"

if [ -n "${GODOT:-}" ] && [ -x "${GODOT}" ]; then
	GODOT_BIN="$GODOT"
elif [ ! -x "$GODOT_BIN" ]; then
	log "Downloading Godot $GODOT_VERSION"
	fetch "$CACHE/godot.zip" "$RELEASE/Godot_v${GODOT_VERSION}-stable_linux.x86_64.zip"
	unzip -o -q "$CACHE/godot.zip" -d "$CACHE"
	rm -f "$CACHE/godot.zip"
	chmod +x "$GODOT_BIN"
fi

# Only the web templates are needed. The published archive is monolithic, so it
# is downloaded whole and everything but templates/web* is thrown away.
if [ ! -f "$TEMPLATE_DIR/web_nothreads_release.zip" ]; then
	log "Installing web export templates for $GODOT_VERSION"
	mkdir -p "$TEMPLATE_DIR"
	fetch "$CACHE/templates.tpz" "$RELEASE/Godot_v${GODOT_VERSION}-stable_export_templates.tpz"
	unzip -o -j -q "$CACHE/templates.tpz" 'templates/web*' -d "$TEMPLATE_DIR"
	rm -f "$CACHE/templates.tpz"
fi

log "Godot: $("$GODOT_BIN" --version)"

if [ -n "${GITHUB_ENV:-}" ]; then
	echo "GODOT_BIN=$GODOT_BIN" >> "$GITHUB_ENV"
	# Put a `godot` on PATH so workflow steps read like the local commands.
	mkdir -p "$CACHE/bin"
	ln -sf "$GODOT_BIN" "$CACHE/bin/godot"
	echo "$CACHE/bin" >> "${GITHUB_PATH:-/dev/null}"
fi

echo "$GODOT_BIN"
