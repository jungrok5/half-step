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

- `tools/build_fonts.py`
  Rebuild the subset UI fonts in `assets/fonts/` after adding new UI copy.

Still missing:

- `build_android.sh` — export an Android debug/release APK.

Keep scripts non-interactive and CI-friendly.
