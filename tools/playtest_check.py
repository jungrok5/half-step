#!/usr/bin/env python3
"""Grade the screenshots `tools/playtest.gd` took.

    python3 tools/playtest_check.py <playtest-dir>

Three defects, all of which have shipped in this game at least once and none of
which any gameplay test can see:

  contrast   Text drawn in a colour the background happens to share, with no rim
             or shadow to separate it. The harness renders every frame twice —
             once as it looks, once with every string in magenta — so the
             difference is an exact mask of which pixels are text. Each run is
             then graded on the better of two ways it could be legible: against
             what is behind it, or against a rim the game drew it. White
             captions on a white cloud is the case that shipped; see
             PROTOTYPE_HISTORY.md.
  edge       Text touching the edge of the screen, which on a phone means text
             under the rounded corner or the home indicator.
  overflow   A translation wider than the box it was centred in. Recorded by
             `CssText` while the harness plays, and reported here so one command
             covers the whole pass.

Exit code is the number of findings, so this can gate a build.

It is plain Python over every pixel of every shot — a few seconds per screen, a
few minutes for all twelve languages. That is why `playtest.sh` defaults to four
of them; pass the rest when a layout has changed.
"""
import json
import sys
from collections import deque
from pathlib import Path

from PIL import Image

# WCAG's ratio. 4.5 is the reading threshold and 3.0 the large-text one; a game
# HUD over moving art is judged at 3.0, and anything under 2.0 is unreadable
# rather than merely low.
CONTRAST_FAIL = 2.0
CONTRAST_WARN = 3.0
# A text run smaller than this is a stray antialiased pixel, not a word.
MIN_RUN_PIXELS = 40
# Flood tolerance, in pixels. Wide enough to keep a word together, narrower than
# the letter-spacing this game draws with.
GAP = 2
# How far out from the text to sample the background.
HALO = 3
EDGE = 2
# Which part of a glyph the eye locks onto. Text here is often drawn with a
# shadow under it, so the mask covers both the bright stroke and the dark shadow;
# averaging them describes neither. This takes the pixels furthest from the
# background instead — which still reads 1:1 when the text really is invisible,
# because then no pixel differs from it.
INK_PERCENTILE = 0.80


def luminance(pixel) -> float:
    channels = []
    for value in pixel[:3]:
        v = value / 255.0
        channels.append(v / 12.92 if v <= 0.04045 else ((v + 0.055) / 1.055) ** 2.4)
    return 0.2126 * channels[0] + 0.7152 * channels[1] + 0.0722 * channels[2]


def ratio(a: float, b: float) -> float:
    high, low = max(a, b), min(a, b)
    return (high + 0.05) / (low + 0.05)


def text_mask(plain: Image.Image, tinted: Image.Image) -> list:
    """Pixels that are magenta in the tinted render and were not before."""
    width, height = plain.size
    plain_px = plain.load()
    tint_px = tinted.load()
    mask = [[False] * width for _ in range(height)]
    for y in range(height):
        for x in range(width):
            r, g, b = tint_px[x, y][:3]
            if r > 150 and b > 150 and g < 110 and plain_px[x, y][:3] != (r, g, b):
                mask[y][x] = True
    return mask


def runs(mask: list, width: int, height: int):
    """Connected components of the mask, merged into words by an 8-neighbour
    flood with a two-pixel gap tolerance so letters of one word stay together."""
    seen = [[False] * width for _ in range(height)]
    for y in range(height):
        for x in range(width):
            if not mask[y][x] or seen[y][x]:
                continue
            queue = deque([(x, y)])
            seen[y][x] = True
            points = []
            while queue:
                cx, cy = queue.popleft()
                points.append((cx, cy))
                for dy in range(-GAP, GAP + 1):
                    for dx in range(-GAP, GAP + 1):
                        nx, ny = cx + dx, cy + dy
                        if 0 <= nx < width and 0 <= ny < height \
                                and mask[ny][nx] and not seen[ny][nx]:
                            seen[ny][nx] = True
                            queue.append((nx, ny))
            if len(points) >= MIN_RUN_PIXELS:
                yield points


def grade(plain_path: Path, tinted_path: Path) -> list:
    plain = Image.open(plain_path).convert("RGB")
    tinted = Image.open(tinted_path).convert("RGB")
    if plain.size != tinted.size:
        return [("broken", f"{plain_path.name}: the two renders differ in size")]
    width, height = plain.size
    mask = text_mask(plain, tinted)
    pixels = plain.load()
    findings = []
    measured = []
    for points in runs(mask, width, height):
        xs = [p[0] for p in points]
        ys = [p[1] for p in points]
        box = (min(xs), min(ys), max(xs), max(ys))

        # The paper: a ring just outside the glyphs, which is what the reader's
        # eye compares them against.
        around = set()
        covered = set(points)
        for x, y in points:
            for dy in range(-HALO, HALO + 1):
                for dx in range(-HALO, HALO + 1):
                    nx, ny = x + dx, y + dy
                    if 0 <= nx < width and 0 <= ny < height \
                            and (nx, ny) not in covered and not mask[ny][nx]:
                        around.add((nx, ny))
        if not around:
            continue
        paper = sum(luminance(pixels[x, y]) for x, y in around) / len(around)
        inks = sorted(luminance(pixels[x, y]) for x, y in points)
        distances = sorted(abs(value - paper) for value in inks)
        target = distances[int((len(distances) - 1) * INK_PERCENTILE)]
        ink = paper + target if inks[-1] > paper else paper - target
        # Two ways a glyph can be legible, and it only needs one. Either it
        # stands against what is behind it, or the game drew it a rim or a
        # shadow and it stands against that. Text with neither, on a background
        # its own colour, fails both — which is the case that ships.
        against_paper = ratio(ink, paper)
        low = inks[int((len(inks) - 1) * 0.10)]
        high = inks[int((len(inks) - 1) * 0.90)]
        measured.append((box, max(against_paper, ratio(high, low))))

    for box, contrast in merge(measured):
        where = f"{plain_path.stem} at {box[0]},{box[1]}-{box[2]},{box[3]}"
        if contrast < CONTRAST_FAIL:
            findings.append(("contrast", f"{where}: {contrast:.2f}:1 — unreadable"))
        elif contrast < CONTRAST_WARN:
            findings.append(("contrast-low", f"{where}: {contrast:.2f}:1 — marginal"))
        if box[0] <= EDGE or box[1] <= EDGE or box[2] >= width - 1 - EDGE \
                or box[3] >= height - 1 - EDGE:
            findings.append(("edge", f"{where}: text runs into the screen edge"))
    return findings


def merge(measured: list) -> list:
    """One finding per line of text, not one per letter.

    Letters are separate runs — this game draws with letter-spacing — so they
    are joined back into lines by sharing a row band and sitting close
    horizontally. The line takes its worst letter's contrast.
    """
    lines = []
    for box, contrast in sorted(measured, key=lambda item: (item[0][1], item[0][0])):
        for i, (other, worst) in enumerate(lines):
            overlap = min(box[3], other[3]) - max(box[1], other[1])
            height = min(box[3] - box[1], other[3] - other[1]) + 1
            gap = box[0] - other[2]
            if overlap >= height * 0.5 and -4 <= gap <= 14:
                lines[i] = ((min(box[0], other[0]), min(box[1], other[1]),
                             max(box[2], other[2]), max(box[3], other[3])),
                            min(worst, contrast))
                break
        else:
            lines.append((box, contrast))
    return lines


def main() -> int:
    directory = Path(sys.argv[1] if len(sys.argv) > 1 else "playtest")
    report = json.loads((directory / "report.json").read_text())
    findings = []
    for note in report.get("notes", []):
        findings.append(("play", note))
    for overflow in report.get("overflows", []):
        findings.append((
            "overflow",
            "%s (%s): %.0fpx of text in a %.0fpx box" % (
                overflow["text"], overflow["locale"], overflow["width"], overflow["box"]),
        ))
    for shot in report.get("shots", []):
        stem = shot["stem"]
        plain = directory / f"{stem}.png"
        tinted = directory / f"{stem}.text.png"
        if not plain.exists() or not tinted.exists():
            findings.append(("missing", f"{stem} was not captured"))
            continue
        findings.extend(grade(plain, tinted))

    hard = [f for f in findings if f[0] not in ("contrast-low",)]
    lines = ["# Playtest findings", ""]
    if not findings:
        lines.append("Nothing found.")
    for kind in sorted({f[0] for f in findings}):
        lines.append(f"## {kind}")
        for found in findings:
            if found[0] == kind:
                lines.append(f"- {found[1]}")
        lines.append("")
    (directory / "findings.md").write_text("\n".join(lines))
    print("\n".join(lines))
    return len(hard)


if __name__ == "__main__":
    sys.exit(main())
