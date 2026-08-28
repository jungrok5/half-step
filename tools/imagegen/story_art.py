#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""TORI — intro/ending still generator, Codex CLI pipeline.

Adapted from jungrok5/super-vs `tools/imagegen/gen.py`, which solved this
already. What was carried over, and why each one is not negotiable:

  * `stdin=DEVNULL`. Without it `codex exec` blocks on "Reading additional
    input from stdin..." and dies with no session. super-vs lost a whole batch
    of six to this on 2026-08-03 and it left one line in the log.
  * Harvest by session id. Every `codex exec` prints its own session id and
    writes into `~/.codex/generated_images/<id>/`, so concurrent calls cannot
    collide. That is the entire basis for running these in parallel.
  * Threads in ONE process, never several processes. The lock below is
    cross-process; a second process fails silently against it.
  * Parallel by default. super-vs measured 8 images in 78 s against ~7 min
    serial — 5.5x. Their note: "매번 까먹네" — so it is the default here too.
  * The style spec lives in this file, not only in a document. A document
    evaporates between sessions; a generator that refuses does not.

What is different here: these are full-bleed portrait stills, not sprites, so
there is no chroma key and no transparency. And the captions are NEVER drawn
into the image — they are drawn at runtime and localised into twelve languages
(STORY.md section 3), which is why `lint` rejects any prompt that would put a
word in the frame.

    python3 tools/imagegen/story_art.py --check          # validate prompts only
    python3 tools/imagegen/story_art.py                  # generate everything missing
    python3 tools/imagegen/story_art.py intro_1 ending_3 # generate just these
    python3 tools/imagegen/story_art.py --force          # regenerate, keeping old as _vN
"""
import argparse
import glob
import io
import os
import re
import shutil
import subprocess
import sys
import threading
import time

if hasattr(sys.stdout, "reconfigure"):
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")
    sys.stderr.reconfigure(encoding="utf-8", errors="replace")

REPO = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
PROMPTS = os.path.join(REPO, "docs", "story", "PROMPTS.md")
OUT_DIR = os.path.join(REPO, "assets", "story")
LOCK = os.path.join(REPO, ".story_art.lock")

# super-vs measured 8 concurrent calls as the useful ceiling; there are only six
# frames here, so the whole set goes out at once.
DEFAULT_JOBS = int(os.environ.get("TORI_IMAGEGEN_JOBS", "6"))
TIMEOUT = 900

# ── The style spec. In the generator on purpose — see the module docstring. ──
#
# The game itself is flat vector drawn from primitives at runtime
# (ART_DIRECTION.md). Cut scenes are allowed to be richer than the playfield,
# but they have to read as the same world: the same coral cat, the same skies
# out of ZoneConfig, no outlines, no texture, no painterly rendering.
STYLE = (
    "Vertical portrait illustration, 9:16, for a mobile game cut scene. "
    "Flat vector art: large simple shapes, clean silhouettes, generous rounding, "
    "soft cel shading in at most three steps per colour. No outlines, no line art, "
    "no visible brush strokes, no canvas or paper texture, no painterly rendering, "
    "no photorealism, no 3D. Calm and warm, aimed at adults, never chibi or cartoonish. "
    "Composition leaves the bottom third of the frame quiet and uncluttered, "
    "because a caption is drawn over it at runtime."
)

# The caption is drawn by the game and translated into twelve languages, so a
# word baked into the image is a word that can never be translated.
NO_TEXT = (
    "Absolutely no text, no letters, no words, no numbers, no logo, no watermark, "
    "no signature, no UI elements and no subtitles anywhere in the image."
)

# The cat, stated identically in every frame so six calls return one animal.
TORI = (
    "Tori is a small ginger cat: coral orange fur #ef6a5b, darker coral tabby "
    "markings #cf5347, cream paws and muzzle #ffeee7, no collar. Small and "
    "unassuming in the frame, never heroic, never anthropomorphic."
)

# Checked against the prompt as it is actually sent, prefix included — the
# frame sections in PROMPTS.md are told not to repeat the shared style, so
# linting the fragment alone would reject every one of them.
REQUIRED_SENT = [
    ("9:16", "portrait aspect — the game is portrait and a square still gets cropped"),
    ("no text", "the no-text rule, or a word gets painted in and can never be translated"),
]
# Checked against the frame's own section, because these are the author's job.
REQUIRED_SECTION = [
    ("Palette", "an explicit hex palette, or six frames come back six different worlds"),
    ("#ef6a5b", "Tori's fur, so the cat is the same cat in every frame"),
    ("overhead", "the camera. This game is seen from straight down and the stills must be too"),
]
FORBIDDEN_SECTION = [
    ("transparent", "these are full-bleed stills; transparency has nothing to sit on"),
    ("chroma", "no chroma key — that is the sprite pipeline, not this one"),
    ("watermark", "the shared prefix already forbids it; saying it twice weakens both"),
]


def find_codex():
    """Codex CLI, wherever this machine keeps it."""
    found = shutil.which("codex") or shutil.which("codex.exe")
    if found:
        return found
    local = os.environ.get("LOCALAPPDATA")
    if local:
        bundled = glob.glob(os.path.join(local, "OpenAI", "Codex", "bin", "*", "codex.exe"))
        if bundled:
            return max(bundled, key=os.path.getmtime)
    for path in ("~/.codex/bin/codex", "/usr/local/bin/codex", "/opt/homebrew/bin/codex"):
        expanded = os.path.expanduser(path)
        if os.path.exists(expanded):
            return expanded
    sys.exit(
        "codex CLI not found. Install it and sign in first — this pipeline uses the\n"
        "subscription login, not an API key:  npm i -g @openai/codex && codex login"
    )


def load_prompts():
    """Every `## <id>.png` section of docs/story/PROMPTS.md, in file order."""
    with io.open(PROMPTS, encoding="utf-8") as handle:
        source = handle.read()
    found = re.findall(
        r"^## ([a-z0-9_]+)\.png[^\n]*\n(?:(?!## )[^\n]*\n)*?```\n(.*?)\n```",
        source, re.S | re.M)
    if not found:
        sys.exit(f"{PROMPTS}: no prompt sections found")
    return [(pid, body.strip()) for pid, body in found]


def full_prompt(prompt):
    return f"{STYLE}\n\n{TORI}\n\n{prompt}\n\n{NO_TEXT}"


def lint(pid, section):
    """Refuses a prompt that would break the spec. Returns a list of problems."""
    problems = []
    sent = full_prompt(section).lower()
    body = section.lower()
    for needle, why in REQUIRED_SENT:
        if needle.lower() not in sent:
            problems.append(f"the sent prompt is missing {needle!r} — {why}")
    for needle, why in REQUIRED_SECTION:
        if needle.lower() not in body:
            problems.append(f"missing {needle!r} — {why}")
    for needle, why in FORBIDDEN_SECTION:
        if needle.lower() in body:
            problems.append(f"contains {needle!r} — {why}")
    if len(section) < 300:
        problems.append("too short to pin a scene down")
    return problems


def run_codex(codex, prompt, workdir):
    result = subprocess.run(
        [codex, "exec", "--skip-git-repo-check", "-C", workdir, prompt],
        stdin=subprocess.DEVNULL,  # or codex waits on stdin and dies with no session
        capture_output=True, text=True, encoding="utf-8", errors="replace",
        timeout=TIMEOUT)
    output = (result.stdout or "") + (result.stderr or "")
    match = re.search(r"session id: ([0-9a-f-]+)", output)
    if not match:
        raise RuntimeError("codex exec produced no session id:\n" + output[-1500:])
    return match.group(1)


def harvest(session_id):
    directory = os.path.join(os.path.expanduser("~"), ".codex", "generated_images", session_id)
    images = sorted(glob.glob(os.path.join(directory, "*.png")), key=os.path.getmtime)
    if not images:
        raise RuntimeError(f"no image produced in {directory}")
    return images[-1]


def versioned(path):
    """Keeps an existing still as _vN rather than overwriting it."""
    if not os.path.exists(path):
        return path
    stem, ext = os.path.splitext(path)
    n = 2
    while os.path.exists(f"{stem}_v{n}{ext}"):
        n += 1
    os.replace(path, f"{stem}_v{n}{ext}")
    return path


_name_lock = threading.Lock()


def generate(jobs, codex, workdir, parallel):
    done, failed = [], []

    def one(item):
        pid, prompt = item
        started = time.time()
        try:
            session = run_codex(codex, full_prompt(prompt), workdir)
            source = harvest(session)
            with _name_lock:
                target = versioned(os.path.join(OUT_DIR, pid + ".png"))
                shutil.copyfile(source, target)
            print(f"    {pid}.png  ({time.time() - started:.0f}s, session {session})", flush=True)
            return pid, None
        except Exception as error:  # one frame failing must not take the batch
            return pid, repr(error)

    print(f">>> {len(jobs)} still(s), {parallel} at a time", flush=True)
    started = time.time()
    from concurrent.futures import ThreadPoolExecutor
    with ThreadPoolExecutor(max_workers=parallel) as pool:
        for pid, error in pool.map(one, jobs):
            (failed if error else done).append(pid if not error else f"{pid} ({error[:100]})")
    print(f"\n== {len(done)} done, {len(failed)} failed in {time.time() - started:.0f}s"
          + (f"\n   failed: {'; '.join(failed)}" if failed else ""), flush=True)
    return 1 if failed else 0


def main():
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("ids", nargs="*", help="frame ids; default is every one still missing")
    parser.add_argument("--check", action="store_true", help="lint the prompts and stop")
    parser.add_argument("--force", action="store_true", help="regenerate even if the file exists")
    parser.add_argument("--jobs", type=int, default=DEFAULT_JOBS)
    args = parser.parse_args()

    prompts = load_prompts()
    problems = {pid: lint(pid, body) for pid, body in prompts}
    broken = {pid: found for pid, found in problems.items() if found}
    for pid, found in broken.items():
        for line in found:
            print(f"{pid}: {line}", file=sys.stderr)
    if broken:
        sys.exit(f"{len(broken)} prompt(s) rejected")
    print(f"{len(prompts)} prompt(s) pass the spec")
    if args.check:
        return 0

    os.makedirs(OUT_DIR, exist_ok=True)
    wanted = args.ids or [pid for pid, _ in prompts]
    known = dict(prompts)
    unknown = [pid for pid in wanted if pid not in known]
    if unknown:
        sys.exit(f"not in {os.path.relpath(PROMPTS, REPO)}: {', '.join(unknown)}")
    jobs = [(pid, known[pid]) for pid in wanted
            if args.force or not os.path.exists(os.path.join(OUT_DIR, pid + ".png"))]
    if not jobs:
        print("every still already exists — pass --force to redraw")
        return 0

    codex = find_codex()

    # Cross-process, because several processes would race the same codex session
    # store. Threads inside one process are safe; that is why parallel lives here.
    if os.path.exists(LOCK):
        sys.exit(f"{LOCK} exists — another run is going, or one died. Remove it to continue.")
    io.open(LOCK, "w").close()
    try:
        return generate(jobs, codex, REPO, max(1, args.jobs))
    finally:
        os.remove(LOCK)


if __name__ == "__main__":
    sys.exit(main())
