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
The camera hangs high in the sky and looks straight DOWN. This is forward
travel across a top-down world, not upward climbing and not a side view.

Reference sensation:
- classic vertical scrolling flight/shooting game
- player stays lower on screen
- environment streams from top toward bottom
- clouds nearer the camera sweep past faster than distant ones

Everything must be drawn from that viewpoint. Nothing may be drawn in profile.

## Character

A ginger cat **seen from above**, jumping between bridges hung in the sky. What
shows is its back: two ears, a striped spine, four paws poking out at the sides
and a tail curling behind. Never a side profile. Defined once in `src/art.gd`
and drawn by both the playfield and the share card, so they cannot drift apart.

The character needs:
- lovable at tiny scale — it is about 34px wide in play
- ears and tail doing the silhouette work, since a back has no face to read
- eyes and muzzle cheated into view anyway, because a featureless back is not
  charming
- paws placed clear of the body outline, or they simply do not show
- a silhouette that survives being scaled to 1080px on the share card
- readable shrinking death animation

A jump is the cat growing as it rises toward the lens while its shadow shrinks
and slides away below — not an arc across the screen. Straight down the camera,
that is what height looks like.

No sprite sheets, no frame animation for v1: motion comes from scaling and
rotating the vector shapes.

## Platforms

Platforms must remain recognizable at extreme speed.

Platforms are bridge sections seen from above.

Desired:
- dark cool-grey deck, a couple of plank seams across it
- a lighter rail down each edge, running the way the cat travels
- no thickness, no side faces: from straight overhead there are none to see
- height is carried by a soft shadow cast far below onto the clouds. Draw it as
  concentric rings at one offset — a single hard rectangle, or a staircase of
  offsets, reads as a second bridge rather than as a shadow
- the empty lane is the same rounded outline, unfilled

On impact:
- original platform stays
- slight squash
- duplicate shock ghost expands/fades
- very few pixels burst

## Clouds

A cloud is a flat mass **seen from above**: an irregular blob with no top and no
bottom. It must NOT have the flat base and billowing crown of a cloud seen from
the side — that was the earlier mistake.

Three depth layers, in `CLOUD_LAYERS`:
- **far** — small, slow, faint; reads as far below, near the ground
- **mid** — the body of the sky, behind the bridges
- **near** — large, fast, nearly transparent, drawn *over* the bridges and the
  cat, so cloud passes between the camera and the world

Keep the near layer faint. It sits on top of the platforms, and platforms must
stay instantly readable at speed.

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
