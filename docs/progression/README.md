# Progression documents

`sky-cat-codex.html` is the illustrated version of `PROGRESSION.md`. Open it in a
browser — it is a standalone page with no build step.

Every cat on it is drawn live from the same geometry as `src/art.gd`, and the
experience curve, the hour estimates and the per-run tables are computed in the
page from the game's real constants (`560 × 0.9964^score`, floor 24 ms). If those
constants change in `src/game_state.gd`, update the copies at the top of the
page's script so the two never drift.

The page is a design document, not part of the game. `docs/*` is excluded from
the Godot export in `export_presets.cfg`.

Published copy: https://claude.ai/code/artifact/02cdcb28-c03d-46f6-aa3b-d6f4d36d08ba
