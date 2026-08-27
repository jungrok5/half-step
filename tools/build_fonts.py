#!/usr/bin/env python3
"""Subset the bundled UI fonts down to the glyphs HALF STEP actually draws.

The web prototype relies on the system `monospace` family at `font-weight:1000`
and on the browser's Korean fallback. Godot has no such fallback chain, so the
Godot port ships two tiny subsets instead:

  HalfStepMono.ttf  DejaVu Sans Mono Bold  -> Latin, digits, punctuation
  HalfStepKR.ttf    GNU Unifont            -> the Hangul syllables in the UI

Run this again after adding new UI copy:

    python3 tools/build_fonts.py
"""
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / "assets" / "fonts"

MONO_SOURCE = "/usr/share/fonts/truetype/dejavu/DejaVuSansMono-Bold.ttf"
KR_SOURCE = "/usr/share/fonts/opentype/unifont/unifont.otf"

LATIN = "".join(chr(c) for c in range(0x20, 0x7F)) + "·…—–’‘“”×"

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


def subset(source: str, text: str, target: Path) -> None:
    if not Path(source).exists():
        sys.exit(f"missing source font: {source}")
    subprocess.run(
        [
            sys.executable, "-m", "fontTools.subset", source,
            f"--text={text}",
            f"--output-file={target}",
            "--flavor=",
            "--layout-features=",
            "--drop-tables+=DSIG",
            "--no-hinting",
            "--desubroutinize",
            "--name-IDs=1,2,4,6",
            "--recalc-bounds",
        ],
        check=True,
    )


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    subset(MONO_SOURCE, LATIN, OUT / "HalfStepMono.ttf")
    subset(KR_SOURCE, "".join(sorted(set("".join(KOREAN_STRINGS)))), OUT / "HalfStepKR.ttf")
    for f in sorted(OUT.glob("*.ttf")):
        print(f"{f.name}: {f.stat().st_size} bytes")


if __name__ == "__main__":
    main()
