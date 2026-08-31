# Scripts

- `tools/setup_godot.sh`
  Install Godot and the web export templates and report the binary. Used by both
  the workflows and the local scripts, so CI and a developer machine run the same
  engine. Caches under `HALF_STEP_CACHE` (default `~/.cache/half-step`).

- `tools/deploy_itch.sh`
  Validate, test, export the HTML5 build and push it to itch.io with butler.
  Needs `BUTLER_API_KEY`; `--build-only` skips the push.

- `tools/playtest.sh`
  **Play the game and grade it.** Drives the real scene through the real input
  path — cold launch, intro, tutorial, thirty honest landings, three late skies,
  death, card, title menu, codex, memorial, ending — in every language asked
  for, and photographs each moment. Then measures whether the text on those
  photographs can actually be read, and whether any translation overflowed the
  box it was centred in. Writes `findings.md` beside the shots and exits
  non-zero on a finding.

  `tools/playtest.gd` is the playing half and `tools/playtest_check.py` the
  grading half; run either alone if you only want one. Neither can tell you
  whether the game is any *good* — look at the shots for that. What they catch
  is the class of defect that no gameplay test can see, because it is only
  visible as pixels: white text on a white cloud, a German string wider than its
  card, a screen drawn underneath the one it opened.

- `tools/render_snapshots.gd`
  Render one portrait screenshot per sky zone, the result card in both its
  states (before and after the codex opens), the share image, the title, and
  every cut-scene frame including the memorial. Needs a display; `xvfb-run` with
  a software GL driver is enough.

- `tools/imagegen/story_art.py`
  Draw the six intro/ending stills with the Codex CLI, six at a time. Needs
  `codex` on PATH and signed in (`codex login` — subscription auth, not an API
  key); it will not run in CI. `--check` lints the prompts in
  `docs/story/PROMPTS.md` without generating anything, and that part does run
  anywhere. Adapted from jungrok5/super-vs `tools/imagegen/gen.py`.

- `docs/audio/PROMPTS.md`
  Not a script — the prompts for every music bed and sound effect, which tool
  makes which, and the rules a track has to obey to sit under the landing
  melody. Files go in `assets/audio/`; missing ones fall back.

- `tools/render_story.gd`
  Bake the six intro/ending stills and the wordmark into `assets/story/` from
  `src/story_art.gd`. These are the placeholders that ship until real art
  replaces them. Needs a display, same as the other renderers.

- `tools/render_cats.gd`
  Render all 24 codex cats onto their own skies as one sheet, so the roster can
  be checked at a glance. Same display requirements as the snapshots.

- `tools/build_fonts.py`
  Rebuild the subset UI fonts in `assets/fonts/`, one per script, from
  `assets/i18n/half_step.csv`. It can never fall behind the UI — but it is a
  build step, not a runtime one. **Run it and commit the fonts after changing
  any translated string or adding a language**, or that string draws as tofu
  boxes on a player's screen.

  It downloads each upstream family whole (cached under `HALF_STEP_CACHE`) and
  subsets locally, then fails if a character has no glyph or a subset came out
  over 400 KB. Google's own `text=` endpoint is not trusted to subset: it
  silently returns entire 6 MB families — see PROTOTYPE_HISTORY.md.

  Adding a *row* also needs the CSV re-imported, which means one editor run:
  `godot --editor --quit --path .`. That run rewrites `project.godot` and drops
  hand-written settings — `git diff project.godot` afterwards and restore it.
  See PROTOTYPE_HISTORY.md.

Still missing:

- `build_android.sh` — export an Android debug/release APK.

Keep scripts non-interactive and CI-friendly.
