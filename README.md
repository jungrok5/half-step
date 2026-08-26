# HALF STEP

Portrait one-thumb rhythm/reaction game built with Godot 4.7.2 and GDScript.

## Rules

Read `AGENTS.md` before changing gameplay. A tap immediately toggles lane. Landings occur on a monotonically accelerating cadence. Input is never locked or queued.

## Run

```bash
godot --path . --editor
```

## Test

```bash
godot --headless --path . --script res://tests/test_runner.gd
```

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
