# HALF STEP — Art Direction

## Core aesthetic

Flat vector mobile arcade game.

Everything is drawn from vector primitives at runtime (`src/shapes.gd`,
`src/art.gd`) rather than from sprite sheets: solid fills, generous rounding, no
outlines, no pixel grid. The bar is Flappy Bird — few shapes, instantly readable,
charming at a glance.

Edges are antialiased by `Shapes.fill()`, which traces each filled polygon with
an antialiased line. Do not reach for 2D MSAA instead: the Compatibility renderer
the web and mobile builds require rejects it ("2D MSAA is not yet supported for
GLES3").

Target:
- cute, warm, simple character
- highly readable platforms
- dramatic atmospheric sky
- clean silhouettes
- strong screenshot readability

The world can become visually surreal at high scores while core gameplay remains clear.

## Camera / movement

Critical:
This is forward travel, NOT upward climbing.

Reference sensation:
- classic vertical scrolling flight/shooting game
- player stays lower on screen
- environment streams from top toward bottom
- near clouds move more quickly than far clouds

## Character

A round coral bird: one body ellipse, a pale belly, a darker wing, a yellow
beak, one large white eye. Defined once in `src/art.gd` and drawn by both the
playfield and the share card, so they cannot drift apart.

The character needs:
- lovable at tiny scale — it is about 30px wide in play
- one big readable eye rather than two small ones
- a silhouette that survives being scaled to 1080px on the share card
- visible squash on landing
- readable shrinking death animation

No sprite sheets, no frame animation for v1: motion comes from squashing and
rotating the vector shapes.

## Platforms

Platforms must remain recognizable at extreme speed.

Desired:
- dark cool-grey rounded slab
- lighter top face, so the platform reads as a solid with thickness
- a darker slab offset below it for depth — no separate drop shadow, which
  detaches and reads as a second object
- no surface detail at all: the shape carries it
- the empty lane is the same rounded outline, unfilled

On impact:
- original platform stays
- slight squash
- duplicate shock ghost expands/fades
- very few pixels burst

## Clouds

Clouds should be layered:
- far
- middle
- near

At low speed:
gentle broad cloud movement.

At high speed:
- increasing downward movement
- stronger foreground motion
- wind streaks — thin, faint, round-capped; heavy bars read as solid poles
- perspective scale variation

A cloud is one merged silhouette, not stacked puffs: overlapping translucent
circles show a seam along every join.

## Sky progression

### BLUE SKY
Fresh, bright, inviting.

### GOLDEN WIND
Warm lower horizon, golden atmosphere.

### SUNSET RUN
Pink/orange sunset drama.

### NIGHT BREAK
Dark violet-blue, first stars.

### STAR RUSH
Deep night, obvious star streak sensation.

### AURORA EDGE
Aurora bands, mysterious edge-of-world feeling.

### RED STRATOS
Strange red atmospheric layer.
First moment that should look "wrong."

### VOID CURRENT
Clouds may reduce dramatically.
Black/indigo emptiness.
Motion conveyed by stars/particles.

### CHROMA STORM
Rare colorful storm/current.
Strong social-media spectacle.

### WHITE HORIZON
Nearly overexposed white high-speed environment.
Should surprise players who assumed later stages get darker.

### BEYOND
Minimal black / cosmic abstraction.
Must feel like secret content, not ordinary progression.

## Rule for secret zones

Do not put all of these in store screenshots.

Marketing should show enough to imply progression, not reveal the extreme content.

## UI

Minimal.

During run:
- score
- best
- temporary zone reveal
- optional subtle FLOW count if useful

Do not cover gameplay.

Result:
- giant score
- reached zone
- best
- retry
- share

No clutter.
