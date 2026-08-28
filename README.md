# HALF STEP

Portrait one-thumb rhythm/reaction game built with Godot 4.7.2 and GDScript.

## Rules

Read `AGENTS.md` before changing gameplay. A tap immediately toggles lane. Landings occur on a monotonically accelerating cadence. Input is never locked or queued.

## Design documents

`AGENTS.md` is the authority. `STORY.md` covers Tori's story, where the ending
sits and how the twelve languages are built. `PROGRESSION.md` specifies the
experience curve and the 24-cat codex; `docs/progression/sky-cat-codex.html` is the same document with
every cat drawn from the game's own geometry — open it in a browser.
`GAME_DESIGN.md`, `VIRAL_DESIGN.md`, `ART_DIRECTION.md` and `AUDIO_RULES.md` cover
their areas, and `PROTOTYPE_HISTORY.md` records what was tried and rejected.

## Reference prototype

`reference/web-prototypes/half_step_pixel_skin.html` is the current reference
build, and the Godot project is a direct port of it: the same layout constants,
step cycle, easing curves, zone table, melody, result card and share image.

The port works in the prototype's CSS pixel units. The viewport is 390x844 with
`keep_width` stretch, so one Godot unit is one CSS pixel on a 390 CSS px wide
phone and the height follows the device aspect exactly as `#game{height:100%}`
does in the browser. Every constant in `src/` is the number the prototype uses;
`src/css_anim.gd`, `src/css_paint.gd` and `src/css_text.gd` reproduce the CSS
timing functions, gradients and text metrics it relies on.

`tests/test_runner.gd` parses the prototype's own source and fails if the zone
table, cadence formula or layout constants drift apart.

### Deliberate deviations

The prototype is the reference for feel, not a spec to copy bug for bug. Five of
its behaviours are fixed rather than reproduced. Each has a regression test, so
do not "restore" them:

| Prototype behaviour | Why it is wrong | What the port does |
| --- | --- | --- |
| A landed row stays eligible for `nearestRow()`, and the slide leaves it 14px from the player while the next row is 78px away | The first row decides two landings, so every run opens with a forced repeat of `pattern[0]` | Rows are marked resolved; each decides exactly one landing |
| The 125ms hop plus the 50ms settle gate the step | Their 175ms sum becomes a hard speed ceiling around score 322, so the run stops accelerating right where the late zones start — against `AGENTS.md` section 7 | Both compress once the cadence drops below their sum, so the beat stays in charge down to the 24ms floor |
| Taps are swallowed until the card appears, then only its buttons respond | `AGENTS.md` requires immediate retry and that input is never dropped | Any tap retries at once; only SHARE is exempt |
| `resize` calls `reset()` | A phone browser hiding its address bar ends the run | The row stack is re-laid out around the new player height and the run continues |
| Only seven rows are built at the start | Leaves a bare strip at the top of a screen taller than 7x92px until the first landing | The opening stack is filled to the top like every later refill |

## Run

```bash
godot --path . --editor
```

## Test

```bash
godot --headless --path . --script res://tests/test_runner.gd
godot --headless --path . --script res://tests/step_cycle_test.gd
godot --headless --path . --script res://tests/audio_test.gd
godot --headless --path . --script res://tests/input_integration_test.gd
godot --headless --path . --script res://tests/progression_test.gd
```

## Portrait snapshots

Renders one screenshot per sky zone plus the result card and the share image.
Needs a display; a software GL driver under Xvfb is enough.

```bash
xvfb-run -a -s "-screen 0 800x1200x24" \
  env LIBGL_ALWAYS_SOFTWARE=1 \
  godot --path . --script res://tools/render_snapshots.gd -- "$PWD/snapshots"
```

## No third-party GitHub Actions

Every action used is first-party `actions/*`. Godot and the web export templates
are installed by `tools/setup_godot.sh`, which both the workflows and
`tools/deploy_itch.sh` call, and releases are cut with the `gh` CLI that ships on
the runner. A marketplace action runs its own code inside the job with the job's
token, and a `@v2` style tag can be repointed at any time — this repository has
no such dependency to trust or to pin.

## Fonts

`assets/fonts/` holds subsets of DejaVu Sans Mono Bold and GNU Unifont covering
the Latin and Hangul the UI draws. Rebuild them with
`python3 tools/build_fonts.py` after adding new UI copy — see
`assets/fonts/README.md`.

## Web export

```bash
mkdir -p build/web
godot --headless --path . --export-release Web build/web/index.html
```

Zip the complete `build/web` directory for distribution. Serve the unzipped directory over HTTP(S); opening `index.html` directly is not supported by WebAssembly browser security rules.

## Releases

Write a bare version into `release-request.txt` and push it to `main`:

```
0.1.0
```

The Web Release workflow runs the test suite, exports the build and attaches the
zip to a new `v0.1.0` GitHub release, with the release commit's own message as
the notes. Re-pushing a version that already has a release does nothing, and a
file holding only comments asks for nothing. The same workflow also takes a
version from the Actions tab.

## Play it

Every push to `main` builds the HTML5 export and publishes it to GitHub Pages
(`.github/workflows/pages.yml`). The workflow runs the full test suite first, so
a red test blocks the deploy.

The repository is public, so the Pages build is publicly playable and the source
— including the zone table and the secret milestone text `VIRAL_DESIGN.md` wants
to keep unseen — is public with it. Use the itch.io channel below if you need a
build that is not.

## Private phone testing on itch.io

Deliberate, not automatic:

```bash
export BUTLER_API_KEY=...          # https://itch.io/user/settings/api-keys
tools/deploy_itch.sh
```

The script validates the project, runs all four test suites, exports the HTML5
build and pushes it to `jungrok5/half:html5` with butler. Godot, the web export
templates and butler are downloaded on first use and cached under
`~/.cache/half-step`. `--build-only` stops after the export, `--skip-tests`
exports from a tree you have already tested.

The `Deploy Private Web Test to itch.io` workflow does the same from Actions on
manual dispatch, using the `BUTLERAPIKEY` repository secret. Keep the itch.io
project visibility set to **Restricted** and optionally enable its page
password.
