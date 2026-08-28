#!/usr/bin/env python3
"""Rebuild the subset UI fonts HALF STEP ships in assets/fonts/.

The web prototype relies on the system `monospace` family at `font-weight:1000`
and on the browser's Korean fallback. Godot has neither, so the port bundles two
subsets containing only the characters the UI actually draws:

  HalfStepMono.ttf  DejaVu Sans Mono Bold  Bitstream Vera license  Latin, digits
  HalfStepKR.ttf    Noto Sans KR Bold      SIL OFL 1.1             Hangul

Both licences permit redistributing a subset inside a closed-source game, and
both require the licence text to travel with the font — see
assets/fonts/licenses/. Do not swap in a GPL-licensed font such as GNU Unifont:
the Debian build carries no font-embedding exception, so embedding it in the
exported .pck would push its copyleft onto the whole distributed game.

The Hangul subset is derived from the game's own source, so adding UI copy only
needs a rebuild. Run this again after changing any Korean string, then commit
the rebuilt fonts:

    pip install fonttools brotli
    python3 tools/build_fonts.py
"""
import re
import subprocess
import sys
import urllib.parse
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / "assets" / "fonts"

MONO_SOURCE = "/usr/share/fonts/truetype/dejavu/DejaVuSansMono-Bold.ttf"
# Google Fonts returns a woff2 holding exactly the characters in `text`.
KOREAN_CSS = "https://fonts.googleapis.com/css2?family=Noto+Sans+KR:wght@700&text="
BROWSER_AGENT = (
    "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 "
    "(KHTML, like Gecko) Chrome/120.0 Safari/537.36"
)

LATIN = "".join(chr(c) for c in range(0x20, 0x7F)) + "\u00b7\u2026\u2014\u2013\u2019\u2018\u201c\u201d\u00d7"

# Every Hangul syllable and jamo the UI can draw, scraped straight out of the
# GDScript rather than listed by hand. A hand-kept list silently falls behind
# the moment someone edits a string, and the only symptom is a tofu box on a
# player's screen — which is exactly how this was found. Adding UI copy now
# needs nothing but a rebuild.
HANGUL = re.compile(r"[\uac00-\ud7a3\u1100-\u11ff\u3130-\u318f]")
SOURCE_DIRS = ["src", "scenes"]

# Copy that is built at runtime and so never appears whole in the source.
RUNTIME_STRINGS = [
    # `condition_text` and the share lines interpolate around these.
    "점",
    # ShareCard status lines already live in the source, but the share message
    # in game.gd is assembled from format strings.
    "을(를) 얻었다",
]


def korean_characters() -> str:
    """Every Hangul character reachable from the game's own source."""
    found = set()
    for directory in SOURCE_DIRS:
        for path in sorted((ROOT / directory).rglob("*.gd")):
            found.update(HANGUL.findall(path.read_text(encoding="utf-8")))
    for text in RUNTIME_STRINGS:
        found.update(HANGUL.findall(text))
    if not found:
        sys.exit("no Hangul found in the source; the subset would be empty")
    return "".join(sorted(found))


def build_latin(target: Path) -> None:
    if not Path(MONO_SOURCE).exists():
        sys.exit(f"missing source font: {MONO_SOURCE}")
    subprocess.run(
        [
            sys.executable, "-m", "fontTools.subset", MONO_SOURCE,
            f"--text={LATIN}",
            f"--output-file={target}",
            "--layout-features=",
            "--drop-tables+=DSIG",
            "--no-hinting",
            "--desubroutinize",
            "--name-IDs=1,2,4,6",
            "--recalc-bounds",
        ],
        check=True,
    )


def build_korean(target: Path) -> None:
    from fontTools.ttLib import TTFont

    characters = korean_characters()
    request = urllib.request.Request(
        KOREAN_CSS + urllib.parse.quote(characters),
        headers={"User-Agent": BROWSER_AGENT},
    )
    with urllib.request.urlopen(request, timeout=60) as response:
        css = response.read().decode("utf-8")
    urls = re.findall(r"url\((https://fonts\.gstatic\.com/[^)]+)\)", css)
    if not urls:
        sys.exit("Google Fonts returned no font URL for the requested characters")
    with urllib.request.urlopen(urls[0], timeout=120) as response:
        target.with_suffix(".woff2").write_bytes(response.read())
    font = TTFont(target.with_suffix(".woff2"))
    font.flavor = None
    font.save(target)
    target.with_suffix(".woff2").unlink()


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    build_latin(OUT / "HalfStepMono.ttf")
    build_korean(OUT / "HalfStepKR.ttf")
    print(f"Hangul characters in the subset: {len(korean_characters())}")
    for font in sorted(OUT.glob("*.ttf")):
        print(f"{font.name}: {font.stat().st_size} bytes")


if __name__ == "__main__":
    main()
