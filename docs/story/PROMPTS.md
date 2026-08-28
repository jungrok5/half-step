# TORI — story stills

Six frames: three for the intro, three for the ending. Run them with

```bash
python3 tools/imagegen/story_art.py            # everything missing, in parallel
python3 tools/imagegen/story_art.py --check    # lint the prompts, generate nothing
```

Results land in `assets/story/<id>.png`, which is where `StoryConfig` looks. An
existing still is kept as `<id>_v2.png` rather than overwritten.

**Every prompt is prefixed at run time** with the shared style spec, Tori's
description and the no-text rule from `tools/imagegen/story_art.py`. Do not
repeat those here; do not contradict them. The linter rejects a prompt that
drops the portrait aspect, the palette, or Tori's fur colour, and rejects one
that asks for transparency or for text.

**No words in the image, ever.** The captions are drawn by the game and
translated into twelve languages (STORY.md section 3). A word painted into a
still is a word that can never be translated.

The palettes below are the game's own — `ZoneConfig` skies and `Art` fur — so
the cut scenes and the playfield stay one world.

---

## intro_1.png — the person went on ahead

Interior, warm, seen from directly above, because the whole game is seen from
directly above. This is the only frame with a room in it; everything after is
sky, and the room is what gives the sky its meaning.

```
Seen from directly overhead, looking straight down into a small quiet room at dusk. A wooden floor, a low table, a rumpled blanket, and two floor cushions side by side. Tori is curled asleep on one cushion. The other cushion is empty, still holding the shape of someone who sat there. A pair of house slippers rests beside it, neatly placed. Late warm light falls in one long rectangle across the floor from a window out of frame. Nobody is in the room. Peaceful, not grim — the emptiness is a shape, not a wound. Deep shadow gathers in the corners so the lit rectangle carries the eye.

Palette — use only these: warm amber light #ffdca0, low sun #ff9a78, wood floor #8b5a3c, dark wood #5b3a26, blanket cream #f6f1e6, cushion slate #42586d, deep shadow #24313d, coral fur #ef6a5b, tabby markings #cf5347, cream paws #ffeee7.
```

## intro_2.png — Tori waited a long time

Deliberately the same camera and the same room as `intro_1`. Repetition is what
makes time pass; the only things that change are the light and where the cat is.

```
The exact same overhead view of the exact same room, the exact same furniture in the exact same places, but months later and at night. The warm rectangle of light is gone and the room is lit only by cold blue moonlight. The empty cushion has not been moved and a fine layer of dust has settled on it. Tori is not asleep now: she sits upright at the doorway on the far side of the room, facing out into the dark hallway, small in the frame, her back to us. A dish of water sits untouched. Cold, still, patient. The composition must match the first frame closely enough that a viewer sees the same room instantly.

Palette — use only these: moon blue #745b9e, deep night #172b66, cold wood #3f4c5a, dark wood #24313d, dust grey #8ba0b3, blanket cream #dfe9f2, deep shadow #12151f, coral fur #ef6a5b, tabby markings #cf5347, cream paws #ffeee7.
```

## intro_3.png — then Tori set off

The hand-off shot: the room falls away and becomes the game. The first bridge
is the game's real bridge — a flat dark deck with plank seams and a rail down
each edge, no thickness, because it is seen from straight above.

```
Seen from directly overhead. The room is far below now, reduced to a small warm rectangle of doorway light at the very bottom of the frame, shrinking away. Above it and filling most of the picture, a dark flat wooden bridge deck floats in open sky with nothing holding it up — plank seams across it, a low rail down each long edge, no visible thickness because we are looking straight down at it. Tori stands at the near end of the deck, small, facing away from us up the bridge into open blue. Overhead clouds drift between the camera and the bridge as soft translucent white masses with no top and no bottom. A second deck is visible further up, waiting.

Palette — use only these: sky blue #79beff, pale sky #eaf7ff, cloud white #ffffff, cloud shade #dfeef8, deck #2b3846, deck top face #42586d, deck shadow #151d24, doorway amber #ffdca0, coral fur #ef6a5b, tabby markings #cf5347, cream paws #ffeee7.
```

---

## ending_1.png — the clouds went quiet

The first frame of the ending has to feel like the game stopping. Everything
that was moving is gone: no wind streaks, no speed, no bridges ahead.

```
Seen from directly overhead. An enormous pale empty sky, almost white, with the clouds thinned to the faintest suggestions. One single dark bridge deck runs up the middle of the frame and ends partway, with nothing after it. Tori stands alone near the end of that last deck, very small against all the emptiness, facing up the frame. No wind, no motion, no other bridges, nothing in the distance yet. Vast, still, held breath. Most of the picture is empty light.

Palette — use only these: pale horizon #d7e5ef, white #ffffff, faint cloud #eaf7ff, cloud shade #dfeef8, deck #2b3846, deck top face #42586d, deck shadow #151d24, coral fur #ef6a5b, tabby markings #cf5347, cream paws #ffeee7.
```

## ending_2.png — someone was standing there

The one frame with a person in it. Seen from straight above, a standing person
is shoulders, the top of a head, and a long shadow — that foreshortening is the
whole shot, and it keeps the face unseen, which keeps the person anyone's.

```
Seen from directly overhead. Far up the frame, at the far end of the bridge, a person stands facing back toward us — from this angle only their shoulders, the top of their head and their long shadow across the deck are visible. No face, no features, no detail; a calm quiet silhouette lit from behind so their edges glow. Tori is in the near foreground, much smaller, stopped mid-stride, looking up the bridge at them. The distance between them is the subject of the picture. Light gathers softly around the standing figure and fades toward the edges of the frame.

Palette — use only these: warm white #ffffff, pale gold #ffdca0, soft glow #fff4dc, pale sky #eaf7ff, deck #2b3846, deck top face #42586d, figure silhouette #24313d, coral fur #ef6a5b, tabby markings #cf5347, cream paws #ffeee7.
```

## ending_3.png — I was waiting for you

Closes the loop: the palette returns to the warm amber of `intro_1`. The sky
becomes the room again.

```
Seen from directly overhead, close in. The person has crouched down and their arms reach into the frame toward Tori, hands open. Only their arms, shoulders and the top of their bowed head are in shot — still no face. Tori is walking into their hands, tail up. The bridge under them has softened into warm light and the sky around the edges has gone the same warm amber as a lamplit room. Nothing else is in the frame. Quiet, close, warm, the end of a long walk.

Palette — use only these: warm amber #ffdca0, low sun #ff9a78, lamp glow #fff4dc, warm white #ffffff, deck #42586d, soft shadow #8b5a3c, sleeve slate #42586d, coral fur #ef6a5b, tabby markings #cf5347, cream paws #ffeee7.
```
