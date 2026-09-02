#!/usr/bin/env python3
"""Rebuild the subset UI fonts HALF STEP ships in assets/fonts/.

The web prototype relies on the system `monospace` family at `font-weight:1000`
and on the browser's Korean fallback. Godot has neither, so the port bundles two
subsets containing only the characters the UI actually draws:

  HalfStepMono.ttf   DejaVu Sans Mono Bold  Bitstream Vera license  Latin, digits
  HalfStepLatin.ttf  Noto Sans Bold         SIL OFL 1.1  accents, Cyrillic
  HalfStepKR.ttf     Noto Sans KR Bold      SIL OFL 1.1  Hangul
  HalfStepJP.ttf     Noto Sans JP Bold      SIL OFL 1.1  kana, kanji
  HalfStepSC.ttf     Noto Sans SC Bold      SIL OFL 1.1  simplified Han
  HalfStepTC.ttf     Noto Sans TC Bold      SIL OFL 1.1  traditional Han

Both licences permit redistributing a subset inside a closed-source game, and
both require the licence text to travel with the font — see
assets/fonts/licenses/. Do not swap in a GPL-licensed font such as GNU Unifont:
the Debian build carries no font-embedding exception, so embedding it in the
exported .pck would push its copyleft onto the whole distributed game.

Every subset is derived from `assets/i18n/half_step.csv`, so a font can never
fall behind the UI. Run this again after changing any translated string or
adding a language, then commit the rebuilt fonts:

    pip install fonttools brotli
    python3 tools/build_fonts.py
"""
import csv
import os
import re
import subprocess
import sys
import urllib.parse
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / "assets" / "fonts"
# Upstream fonts land here, whole. Shares the directory the Godot download uses.
CACHE = Path(os.environ.get("HALF_STEP_CACHE", Path.home() / ".cache" / "half-step")) / "fonts"
# A per-script subset of a few hundred characters is tens of kilobytes. Anything
# near a megabyte is the entire family, which has happened — see `source_font`.
MAX_SUBSET_BYTES = 400_000

MONO_SOURCE = "/usr/share/fonts/truetype/dejavu/DejaVuSansMono-Bold.ttf"
# Google Fonts returns a woff2 holding exactly the characters in `text`.
GOOGLE_CSS = "https://fonts.googleapis.com/css2?family=%s&text="
BROWSER_AGENT = (
    "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 "
    "(KHTML, like Gecko) Chrome/120.0 Safari/537.36"
)

LATIN = "".join(chr(c) for c in range(0x20, 0x7F)) + "\u00b7\u2026\u2014\u2013\u2019\u2018\u201c\u201d\u00d7"

# Which characters each shipped font has to carry. Everything is derived from
# `assets/i18n/half_step.csv`, so a subset can never fall behind the UI: adding
# copy or a language needs a rebuild, not an edit here.
#
# Splitting by script rather than by language keeps the download small — the
# Korean, Japanese and Chinese columns share almost nothing, and Latin languages
# share almost everything.
TRANSLATIONS = ROOT / "assets" / "i18n" / "half_step.csv"

SCRIPTS = {
    # target file            Google Fonts family      locale columns
    "HalfStepLatin.ttf": ("Noto Sans:wght@700", ["en", "es", "pt_BR", "fr", "de", "ru", "id", "vi"]),
    "HalfStepKR.ttf": ("Noto Sans KR:wght@700", ["ko"]),
    "HalfStepJP.ttf": ("Noto Sans JP:wght@700", ["ja"]),
    "HalfStepSC.ttf": ("Noto Sans SC:wght@700", ["zh_Hans"]),
    "HalfStepTC.ttf": ("Noto Sans TC:wght@700", ["zh_Hant"]),
}

# Copy assembled at runtime, so it never appears whole in the table.
RUNTIME_CHARACTERS = "0123456789·×?—…"


def translation_table() -> dict:
    """The CSV as {locale: "".join(every string that locale can draw)}."""
    with TRANSLATIONS.open(encoding="utf-8") as handle:
        rows = list(csv.reader(handle))
    header = rows[0][1:]
    table = {locale: [] for locale in header}
    for row in rows[1:]:
        for locale, text in zip(header, row[1:]):
            table[locale].append(text)
    return {locale: "".join(parts) for locale, parts in table.items()}


def characters_for(locales: list) -> str:
    table = translation_table()
    missing = [locale for locale in locales if locale not in table]
    if missing:
        sys.exit(f"{TRANSLATIONS} has no column for {missing}")
    found = set(RUNTIME_CHARACTERS)
    for locale in locales:
        found.update(table[locale])
    # The Latin subset already covers ASCII; a script font only needs what ASCII
    # does not, which is what keeps a CJK subset in the tens of kilobytes.
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


def source_font(family: str, characters: str, cache: Path) -> Path:
    """The upstream font, as a .ttf. Cached, because it can be several MB.

    Google's `text=` endpoint is asked for a subset, and when it obliges the
    download is tens of kilobytes. It cannot be relied on: past roughly 1900
    characters of URL — and, as of 2026-08-29, for any request it has not
    already cached — it silently returns the ENTIRE family instead, with no
    error and no change in shape. A 6 MB Korean font in the .pck is not
    something anyone notices until the download. So whatever comes back is
    treated as a source, never as the answer; `build_script` subsets it here.
    """
    from fontTools.ttLib import TTFont

    cache.mkdir(parents=True, exist_ok=True)
    cached = cache / (family.split(":")[0].replace("+", "") + ".ttf")
    if cached.exists():
        # A cache entry can be a genuine subset from a day when the endpoint was
        # still subsetting, and a subset of yesterday's strings is missing
        # today's. Checked here rather than after subsetting, where the failure
        # reads as "upstream has no glyph for 홈" and blames Google.
        covered = TTFont(cached).getBestCmap()
        if all(c.isspace() or ord(c) in covered for c in characters):
            return cached
        cached.unlink()

    request = urllib.request.Request(
        GOOGLE_CSS % family + urllib.parse.quote(characters),
        headers={"User-Agent": BROWSER_AGENT},
    )
    with urllib.request.urlopen(request, timeout=60) as response:
        css = response.read().decode("utf-8")
    urls = re.findall(r"url\((https://fonts\.gstatic\.com/[^)]+)\)", css)
    if not urls:
        sys.exit(f"Google Fonts returned no font for {family}")
    with urllib.request.urlopen(urls[0], timeout=180) as response:
        cached.with_suffix(".woff2").write_bytes(response.read())
    font = TTFont(cached.with_suffix(".woff2"))
    font.flavor = None
    font.save(cached)
    cached.with_suffix(".woff2").unlink()
    return cached


def build_script(target: Path, family: str, locales: list) -> None:
    from fontTools.ttLib import TTFont

    characters = characters_for(locales)
    source = source_font(family, characters, CACHE)
    # The character list goes through a file: a Korean subset is already 2 KB
    # of UTF-8 and a command line is not the place for it.
    listing = target.with_suffix(".txt")
    listing.write_text(characters, encoding="utf-8")
    subprocess.run(
        [
            sys.executable, "-m", "fontTools.subset", str(source),
            f"--text-file={listing}",
            f"--output-file={target}",
            "--layout-features=",
            "--drop-tables+=DSIG",
            "--no-hinting",
            "--name-IDs=1,2,4,6",
            "--recalc-bounds",
        ],
        check=True,
    )
    listing.unlink()

    # Both halves of "did this work" checked here rather than trusted: a font
    # that is missing a character draws tofu, and a font that kept the whole
    # family costs the player megabytes. Neither shows up anywhere else.
    font = TTFont(target)
    cmap = font.getBestCmap()
    missing = sorted({c for c in characters if not c.isspace() and ord(c) not in cmap})
    if missing:
        sys.exit(f"{target.name}: upstream has no glyph for {''.join(missing)}")
    if target.stat().st_size > MAX_SUBSET_BYTES:
        sys.exit(
            f"{target.name} came out at {target.stat().st_size} bytes for "
            f"{len(characters)} characters — that is the whole family, not a subset"
        )


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    build_latin(OUT / "HalfStepMono.ttf")
    for name, (family, locales) in SCRIPTS.items():
        characters = characters_for(locales)
        build_script(OUT / name, family.replace(" ", "+"), locales)
        print(f"{name}: {len(characters)} characters from {', '.join(locales)}")
    total = 0
    for font in sorted(OUT.glob("*.ttf")):
        total += font.stat().st_size
        print(f"{font.name}: {font.stat().st_size} bytes")
    print(f"total: {total} bytes")


if __name__ == "__main__":
    main()
