# HALF STEP — Cloud Development Workflow

## Objective

Develop from a phone as much as practical.

Desired pipeline:

Mobile instruction
→ cloud agent
→ GitHub repo change
→ Godot headless tests
→ visual render tests
→ PR
→ GitHub Actions
→ Android APK
→ GitHub Release/artifact
→ install on physical phone
→ human feel test
→ repeat

## Repository as source of truth

All important design decisions must live in this repo, especially AGENTS.md.

Do not rely only on conversational memory.

## Godot cloud environment

Recommended packages/tooling:
- Godot 4.x Linux headless/editor binary
- export templates
- Android SDK/JDK if building APK in cloud
- Xvfb if native rendered screenshot testing requires an X server
- Mesa/software renderer where needed

Exact provisioning depends on Work/Codex environment capabilities.

## Headless validation

Example commands to adapt:

```bash
godot --headless --path . --editor --quit
```

Gameplay tests should preferably exercise pure logic without requiring rendering.

## Visual tests

Create test/debug entry points that can force:
- score 0
- score 60
- score 150
- score 300
- score 400
- score 550
- score 750
- score 1000

Then render screenshots at a consistent portrait resolution.

For native rendering environments, Xvfb/Mesa may be needed.

Agents must report whether they actually inspected screenshots or only produced them.

## Android

Use CI to create debug APKs for device testing.

Recommended:
- every PR: validation + tests
- optionally every PR: Android debug artifact
- main/tag: release APK via GitHub Release

## GitHub Actions target

PR:
1. install Godot
2. import/validate project
3. run tests
4. optional render snapshots
5. Android debug export

Release tag:
1. clean build
2. export APK
3. attach APK to GitHub Release

## Human device test

The user tests:
- touch latency
- missed input
- vibration
- sound feel
- real Android share sheet
- screen sizing
- ad behavior
- sustained high-speed feel

Agent should never claim these are validated from cloud tests alone.
