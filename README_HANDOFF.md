# HALF STEP — Work Handoff Pack

This folder contains the design/context required to continue HALF STEP development in a fresh ChatGPT Work session.

## Start here

1. Upload/push this folder into the GitHub repo.
2. Put the HTML prototypes under `reference/web-prototypes/`.
3. Connect the repo to ChatGPT Work.
4. Send the prompt in `WORK_START_PROMPT.md`.
5. Tell the agent to read `AGENTS.md` before coding.

## Most important files

- `AGENTS.md` — non-negotiable gameplay constraints
- `PROTOTYPE_HISTORY.md` — rejected experiments; prevents regression
- `GAME_DESIGN.md` — current game rules
- `AUDIO_RULES.md` — success melody / death audio
- `ART_DIRECTION.md` — pixel/cloud/high-score visual direction
- `VIRAL_DESIGN.md` — secret zones and social sharing
- `CLOUD_DEV_WORKFLOW.md` — desired cloud Godot / GitHub / APK workflow
- `WORK_START_PROMPT.md` — first message for the new Work session

## Current state

The web prototypes validated direction, not final production code.

Next major milestone:
Implement the game natively in Godot and establish a cloud test/build pipeline before expanding art/content.
