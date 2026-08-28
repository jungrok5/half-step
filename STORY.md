# TORI — Story, endings, and languages

Tori's person died first and went on ahead. Tori died later, and is walking to
find them. That is the whole game.

The cat formerly called 반걸음 / HALF-STEP is now **토리 / Tori**, and every
system that named it was renamed with it. A save written before the rename still
opens with Tori equipped and its record intact (`Progress._migrate`).

---

## 1. Where the ending sits

**The ending is gated on distance walked as Tori, not on score.**
`StoryConfig.REUNION_STEPS = 3000` landings, across every run, forever.

Roughly 40–60 minutes of total play spread over two to four sessions. Ordinary
players get there. That is the point.

### Why distance and not score

The story is a cat walking to someone who went ahead. Distance *is* the story,
and three things follow from measuring it that way:

- **A failed run still counts.** Every landing before the fall moved Tori
  forward. Death stops being only a loss, which is the exact feeling
  "조금만 더" describes.
- **It cannot be farmed or skill-walled.** It asks for nothing but coming back,
  which is what the story is about and what retention wants anyway.
- **It draws itself.** "1,820 steps to Tori's person" with a bar under it is a
  progress readout, a retention hook and a piece of writing at the same time.
  It is in the codex header.

Score would have made the ending a skill gate on a story about persistence.
Level would have worked, but a level is an abstraction; steps are the thing the
player is actually doing.

### Why not the second cat

Milk opens after about twenty seconds of play. An ending there is not an ending,
it is a tutorial. The resolution has to cost something or it resolves nothing.

### Why the ending is NOT the viral moment

This was the open question, and the answer is that one thing cannot do both jobs.

- **The ending is the story's payoff.** A story most players never finish is a
  failed story. It has to be reachable, and it is.
- **The viral moment needs to be rare.** If everyone has it, nobody films it.

Trying to make the ending do both breaks both: gate it high and the story never
lands; gate it low and there is nothing to brag about. So they are separated.

**Recommended, not yet built — the epilogue at score 1000 in one run.** The
BEYOND zone already exists there, already says NO ONE WAS SUPPOSED TO SEE THIS,
and already gates the game's hardest cat. After the reunion, Tori keeps running;
at 1000 a second silhouette is running the bridges alongside. No text, no ending
card, nothing announced. That is the clip people post, and it costs one new
scene rather than a second ending competing with the first.

### What the ending does not do

It does not end the game. After the reunion the run continues exactly as before,
the codex keeps opening, and the score keeps climbing. The ending is a thing that
happened on the way, not a wall at the end.

---

## 2. Intro and ending

`StoryConfig.INTRO` and `StoryConfig.ENDING` are lists of frames. Each frame is
a still, a caption key, and a sky to fall back to.

**Stills, not video.** Godot's web export only carries Theora, and a video large
enough to look good would be bigger than the rest of the game put together. A
still per beat streams in as a texture, costs almost nothing, and — because the
caption is *drawn* rather than burned into the image — a new language costs a row
in a table instead of a re-render of every frame.

Drop art at `res://assets/story/intro_1.png` and the rest; a frame whose image is
missing still plays, painting the sky it names. So the sequence runs, and is
testable, before any art exists.

| | |
|---|---|
| Intro | Plays once, before the first run ever. |
| Ending | Plays on the run that completes the walk, before the result card. |
| Skip | Always. A tap anywhere else steps a frame, so a replay is fast. |
| Replay | Both live at the bottom of the codex. |

**The ending's replay row only appears once the ending has been seen.** Offering
it earlier would give away that there is an ending at all.

The current captions are placeholders written from the scenario. Replace them in
`assets/i18n/half_step.csv` — the rows are `STORY_INTRO_1..3` and
`STORY_END_1..3`.

---

## 3. Languages

Twelve ship: **en, ko, ja, zh_Hans, zh_Hant, es, pt_BR, fr, de, ru, id, vi.**

Every player-visible string is a key in `assets/i18n/half_step.csv`, which Godot
imports into one `.translation` per locale. **Nothing may be a literal**: the
fonts are subsets built from that file, so a literal is a string with no glyphs
on the player's screen.

Lookup goes through `I18n.t()`, not `Object.tr()`, because most of this game's
text is drawn from static functions where `tr()` does not exist.

### Fonts

`tools/build_fonts.py` builds one subset per *script*, from the CSV:

| File | Covers | Size |
|---|---|---:|
| `HalfStepMono.ttf` | the HUD's Latin, from DejaVu Sans Mono Bold | 8 KB |
| `HalfStepLatin.ttf` | accents and Cyrillic — en, es, pt_BR, fr, de, ru, id, vi | 28 KB |
| `HalfStepKR.ttf` | Hangul | 35 KB |
| `HalfStepJP.ttf` | kana and kanji | 104 KB |
| `HalfStepSC.ttf` | simplified Han | 54 KB |
| `HalfStepTC.ttf` | traditional Han | 62 KB |

Twelve languages for 291 KB, because each subset holds only the few hundred
characters its languages actually use. The whole exported `.pck` is 381 KB. Splitting by script rather than by
language is what makes it cheap: the Latin languages share almost everything.

**Adding a language** is a column in the CSV, an entry in `I18n.LOCALES`, and a
rebuild. Adding a *script* also needs a row in `build_fonts.py` and
`CssText.FALLBACK_PATHS`.

### Why translations are not registered in project.godot

`I18n.load_all()` adds them at startup instead, and this is deliberate.

Listing them under `internationalization/locale/translations` makes the exporter
bundle **4.8 MB of ICU data** — bidirectional text and word-breaking tables —
into the `.pck`. That is more than ten times the size of everything else in the
game, and `locale/include_text_server_data=false` does not stop it. Measured:
5.18 MB with the setting, 381 KB without.

None of the twelve languages need it. Nothing in this game wraps text, and none
of them are right-to-left. **Adding Arabic, Hebrew or an Indic script means
putting the translations back in `project.godot` and accepting the 4.8 MB** —
along with taking that locale out of `I18n.SEPARABLE_SCRIPTS`.

### What stays English

Zone names (BLUE SKY … BEYOND), the milestone tags, and
`PLAY · FAIL · SHARE · REPEAT` are stylised proper nouns and part of the visual
identity, like a logo. They are not translated on purpose.

### Scripts that cannot be split

`CssText` draws text one glyph at a time so the HUD's CSS letter-spacing can be
applied. Arabic joins its letters and Indic scripts form clusters, so splitting
a string there destroys the word. `I18n.SEPARABLE_SCRIPTS` lists the locales
that survive it; anything else is drawn as a whole run and loses letter-spacing
rather than its text. **Add a locale to `LOCALES` and it is separable by
default — if it is not, take it out of `SEPARABLE_SCRIPTS` in the same commit.**

---

## 4. Open

1. **`REUNION_STEPS = 3000`** is calibrated from the archetype table in
   `PROGRESSION.md`, not from measurement. First thing to check against real
   sessions.
2. **The epilogue at score 1000** is designed above and not built.
3. **Art.** Six stills, and whatever the title screen becomes.
4. **A language picker.** The locale currently follows the device. Some players
   want to override it.
5. **The mobile deep link** for `?seen=` — web only so far.
