#!/usr/bin/env bash
#
# Play the game, photograph it, and grade the photographs.
#
#   tools/playtest.sh [output-dir] [locale ...]
#
# Two halves. `playtest.gd` drives the real scene through the real input path —
# a cold launch, the intro, the tutorial, thirty honest landings, three late
# skies, a death, the card, the title menu, the codex, the memorial, the ending —
# and captures every one of them twice: once as it looks, once with every string
# drawn in magenta. `playtest_check.py` subtracts one from the other to find out
# which pixels are text, and measures whether any of it can be read.
#
# It exits non-zero on a finding, and writes findings.md next to the shots.
# Look at the shots too: it cannot tell you whether the game is any good.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT="${1:-$ROOT/build/playtest}"
shift || true
LOCALES=("$@")
if [ ${#LOCALES[@]} -eq 0 ]; then
	LOCALES=(en ko de vi)
fi

GODOT_BIN="${GODOT_BIN:-$("$ROOT/tools/setup_godot.sh")}"
rm -rf "$OUT"
mkdir -p "$OUT"

# Needs a real display for the renderer; software GL under Xvfb is enough.
RUNNER=()
if [ -z "${DISPLAY:-}" ]; then
	RUNNER=(xvfb-run -a)
fi
"${RUNNER[@]}" "$GODOT_BIN" --path "$ROOT" --rendering-driver opengl3 \
	--script res://tools/playtest.gd -- "$OUT" "${LOCALES[@]}"

python3 "$ROOT/tools/playtest_check.py" "$OUT"
