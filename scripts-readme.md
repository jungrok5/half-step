# Scripts

- `tools/setup_godot.sh`
  Install Godot and the web export templates and report the binary. Used by both
  the workflows and the local scripts, so CI and a developer machine run the same
  engine. Caches under `HALF_STEP_CACHE` (default `~/.cache/half-step`).

- `tools/deploy_itch.sh`
  Validate, test, export the HTML5 build and push it to itch.io with butler.
  Needs `BUTLER_API_KEY`; `--build-only` skips the push.

- `tools/render_snapshots.gd`
  Render one portrait screenshot per sky zone plus the result card and the share
  image. Needs a display; `xvfb-run` with a software GL driver is enough.

- `tools/imagegen/story_art.py`
  Draw the six intro/ending stills with the Codex CLI, six at a time. Needs
  `codex` on PATH and signed in (`codex login` — subscription auth, not an API
  key); it will not run in CI. `--check` lints the prompts in
  `docs/story/PROMPTS.md` without generating anything, and that part does run
  anywhere. Adapted from jungrok5/super-vs `tools/imagegen/gen.py`.

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

Still missing:

- `build_android.sh` — export an Android debug/release APK.

Keep scripts non-interactive and CI-friendly.
