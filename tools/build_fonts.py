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

Run this again after adding new UI copy, then commit the rebuilt fonts:

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

KOREAN_STRINGS = [
    # in-game hint
    "화면을 탭해서 반대편으로",
    "멀리 갈수록 다른 하늘이 열린다",
    # result card buttons
    "다시하기",
    "공유하기",
    # share status lines
    "공유 미지원 · 텍스트를 클립보드에 복사했어요",
    "이 브라우저는 공유를 지원하지 않아요",
    "공유를 취소했어요",
    # share message
    "점 · 까지 도달! 이 기록 넘을 수 있어?",
    # zone share lines
    "첫 하늘", "황금빛 바람", "노을 질주", "밤을 뚫고", "별 사이를 통과",
    "오로라 경계", "붉은 성층권", "공허의 흐름", "색채 폭풍", "백색 지평선",
    "그 너머",
]


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

    characters = "".join(sorted(set("".join(KOREAN_STRINGS))))
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
    for font in sorted(OUT.glob("*.ttf")):
        print(f"{font.name}: {font.stat().st_size} bytes")


if __name__ == "__main__":
    main()
