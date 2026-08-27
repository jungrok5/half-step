# HALF STEP

Portrait one-thumb rhythm/reaction game built with Godot 4.7.2 and GDScript.

## Rules

Read `AGENTS.md` before changing gameplay. A tap immediately toggles lane. Landings occur on a monotonically accelerating cadence. Input is never locked or queued.

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
godot --headless --path . --script res://tests/input_integration_test.gd
```

## Portrait snapshots

Renders one screenshot per sky zone plus the result card and the share image.
Needs a display; a software GL driver under Xvfb is enough.

```bash
xvfb-run -a -s "-screen 0 800x1200x24" \
  env LIBGL_ALWAYS_SOFTWARE=1 \
  godot --path . --script res://tools/render_snapshots.gd -- "$PWD/snapshots"
```

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

## Private phone testing on itch.io

The `Deploy Private Web Test to itch.io` workflow builds and uploads the HTML5 version whenever `main` changes.

Required GitHub Actions secrets:

- `BUTLER_API_KEY` — itch.io API key used by the official butler CLI.

The deployment target is `jungrok5/half:html5`. Keep the itch.io project visibility set to **Restricted** and optionally enable its page password.
