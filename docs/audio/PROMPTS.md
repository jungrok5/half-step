# TORI — sound

Every sound the game looks for, with the prompt that makes it.

**Each prompt below is complete on its own.** Key, tempo, instrumentation, mood,
frequency range, length, loop behaviour and the "no vocals" rule are written
into every single block — there is no shared preamble to paste in front of them
and nothing to remember. Copy one block, paste it into the tool named above it,
generate. That is the whole procedure.

Sections 1 and 2 explain *why* the prompts say what they say. You do not need to
read them to use the prompts.

Drop an `.ogg` into `assets/audio/` and it plays. A slot with no file falls back
to the synthesised sound the prototype shipped with, or to silence for music, so
the game is never broken by audio that has not been made yet — the same contract
`assets/story/` uses for the stills.

---

## 1. Which tool for what

**Suno and Udio write songs. They cannot make a cat meow.** Asking them for one
returns a song *about* a cat. Splitting the work by tool is the difference
between an afternoon and a week:

| Asset | Tool | Why |
|---|---|---|
| The nine music beds | **Suno** or Udio | This is what they are for. Custom mode, Instrumental on, lyrics box empty. |
| Cat sounds — `cross`, `fall`, `equip` | **ElevenLabs Sound Effects**, or a licensed cat library, or a real cat and a phone | Text-to-SFX, one-shots, a few seconds. |
| `unlock`, `arrive`, `zone`, `milestone`, `ui` | ElevenLabs SFX, or keep synthesising | Five short abstract sounds; a musician with any DAW makes them faster. |

A phone recording of an actual cat, trimmed, is the best-sounding and cheapest
option for the three cat cues. Consider it first.

---

## 2. Why the prompts say what they say

Each rule below is already inside every prompt. This is only the reasoning.

**C major, A=440.** The landing melody is a C major scale climbing three octaves
(`TonePlayer.SCALE`, root exactly middle C at 261.63 Hz). It plays over
everything, several times a second at speed. A track in any other key is a wrong
note dozens of times a minute.

**No drums, no pulse, no tempo.** The cadence goes from 560 ms per beat at the
start to 24 ms at the floor, continuously, inside a single run. Nothing with a
fixed tempo can stay with it. **The player's tapping is the rhythm section and
the landing melody is the lead** — the music is harmony and weather. Pads,
drones, sustained strings, bowed metal, held choir. No kick, no snare, no hats,
no arpeggiated sequencer, no strummed guitar.

**Nothing loud between 250 and 1100 Hz.** That is where the melody lives. Put
the music below and above it: sub and low pads under, air and shimmer over, a
scooped middle.

**Instrumental, no words.** A voice sits exactly in the melody's range and the
game ships in twelve languages.

**Quiet.** These are beds, mastered around −16 LUFS; the game plays them at
−9 dB under everything else.

**Effects start on the first sample.** A cue with 40 ms of silence in front of
it feels like input lag. Section 5 trims it for you.

---

## 3. The music — nine tracks

Paste into **Suno → Custom → Instrumental**, lyrics box empty.

### `music/day.ogg` — score 0–59 · BLUE SKY, GOLDEN WIND

The first thing anyone hears. Warm, ordinary, a little empty: a cat that has just
set out and does not yet know how far it is.

```
Instrumental ambient bed in the key of C major, tuned to A=440. Absolutely no percussion of any kind: no drums, no beat, no tempo, no pulse, no arpeggios, no sequencer, no strummed guitar. Warm sustained pads, soft felt piano held long with the sustain pedal down, a distant bowed cello. Gentle, patient, a little lonely but not sad — morning light in an empty room. Slow evolving swells only. Scooped mids: keep 250-1100 Hz quiet and open, put the weight in the sub and the air above. Forty seconds, seamlessly loopable, ending where it begins. Very quiet, background level, mastered around -16 LUFS. Fully instrumental: no vocals, no lyrics, no spoken word, no humming, no choir syllables.
```

### `music/dusk.ogg` — score 60–149 · SUNSET RUN, NIGHT BREAK

The light is going. Same world, lower.

```
Instrumental ambient bed in the key of C major, tuned to A=440. Absolutely no percussion of any kind: no drums, no beat, no tempo, no pulse, no arpeggios, no sequencer. Low warm strings and a soft analogue synth pad, a single sustained horn far away, faint tape hiss. Golden and fading, evening, the last of the light — darker and lower than a bright morning cue. Long slow swells only, no rhythmic movement. Scooped mids: keep 250-1100 Hz quiet, weight in the sub and the air above. Forty seconds, seamlessly loopable, ending where it begins. Very quiet, background level, mastered around -16 LUFS. Fully instrumental: no vocals, no lyrics, no spoken word.
```

### `music/star.ogg` — score 150–299 · STAR RUSH, AURORA EDGE

Where it stops being a nice walk. Cold, wide, a little thrilling.

```
Instrumental ambient bed in the key of C major, tuned to A=440. Absolutely no percussion of any kind: no drums, no beat, no tempo, no pulse, no arpeggios. Cold shimmering pads, bowed vibraphone and glass harmonica, high sustained strings, wide reverb. Vast, weightless, night at high altitude, beautiful and slightly frightening. Very slow evolution, no rhythmic movement at all. High shimmer above and deep sub below with the middle left empty: nothing loud between 250 and 1100 Hz. Forty seconds, seamlessly loopable, ending where it begins. Very quiet, background level, mastered around -16 LUFS. Fully instrumental: no vocals, no lyrics, no spoken word.
```

### `music/deep.ogg` — score 300–549 · RED STRATOS, VOID CURRENT

Almost nobody hears this. It can be strange.

```
Instrumental ambient drone in the key of C major, tuned to A=440. Absolutely no percussion of any kind: no drums, no beat, no tempo, no pulse, no arpeggios, and no melody. Deep sustained sub bass, dark bowed metal, a slowly detuning pad, distant filtered noise like wind at extreme altitude. Airless, immense, unsettling but never aggressive. Nearly static — it should change across thirty seconds, not across four bars. Almost nothing between 250 and 1100 Hz. Forty seconds, seamlessly loopable, ending where it begins. Very quiet, background level, mastered around -16 LUFS. Fully instrumental: no vocals, no lyrics, no spoken word.
```

### `music/beyond.ogg` — score 550+ · CHROMA STORM, WHITE HORIZON, BEYOND

The end of the map. This is the one people will film.

```
Instrumental ambient drone in the key of C major, tuned to A=440. Absolutely no percussion of any kind: no drums, no beat, no tempo, no pulse, no arpeggios. One vast sustained chord in slowly shifting overtones, bowed cymbal, a choir-like pad with no discernible voices or words, very long reverb tail. Overwhelming stillness, white light, the sound of somewhere nobody was meant to reach. Almost no change over time. Nothing loud between 250 and 1100 Hz. Forty seconds, seamlessly loopable, ending where it begins. Very quiet, background level, mastered around -16 LUFS. Fully instrumental: no vocals, no lyrics, no spoken word, no choir syllables.
```

### `music/title.ogg` — the title screen

Short and inviting, so it does not wear out while somebody reads the buttons.

```
Instrumental ambient piece in the key of C major, tuned to A=440. Absolutely no percussion of any kind: no drums, no beat, no tempo, no pulse, no arpeggios. Soft felt piano and one warm pad, spacious and unhurried. A simple held motif that resolves and comes to rest. Nostalgic and gentle, the memory of a home. Nothing loud between 250 and 1100 Hz. Thirty seconds, seamlessly loopable, ending where it begins. Very quiet, background level, mastered around -16 LUFS. Fully instrumental: no vocals, no lyrics, no spoken word.
```

### `music/intro.ogg` — the intro, plays once, does not loop (~14 s)

The one place the story is stated, so this is allowed to be sad. Still no drums.

```
Instrumental piece in the key of C major, tuned to A=440. Absolutely no percussion of any kind: no drums, no beat, no tempo, no pulse, no arpeggios. Solo felt piano, very close and very quiet, with one distant sustained string entering halfway through. Tender, restrained, grief without weeping. It must not resolve — it opens. Fifteen seconds, ending unfinished on a suspension rather than a settled chord. Does not need to loop. Nothing loud between 250 and 1100 Hz. Quiet, mastered around -16 LUFS. Fully instrumental: no vocals, no lyrics, no spoken word.
```

### `music/ending.ogg` — the ending, plays once, does not loop (~20 s)

Twenty seconds that most players reach after forty minutes of walking. It has to
land, and then it has to stop — the memorial's own bed takes over from here.

```
Instrumental piece in the key of C major, tuned to A=440. Absolutely no percussion of any kind: no drums, no beat, no tempo, no pulse, no arpeggios. Solo felt piano joined by warm strings, building very slowly to one full resolved C major chord and holding it while everything decays into silence. Arrival, relief, being met. Warm, close, unhurried. Twenty seconds. Resolve fully on the tonic and let the reverb fall away to nothing. Does not need to loop. Quiet, mastered around -16 LUFS. Fully instrumental: no vocals, no lyrics, no spoken word.
```

### `music/memorial.ogg` — under the memorial card, loops

**This is the one that has to loop properly.** The memorial is the only frame in
the game that never times out, so a player can sit on it for as long as they
want — and many will. Quieter and stiller than everything else here; it is
almost the absence of music. If a join is audible it will be heard ten times.

```
Instrumental ambient bed in the key of C major, tuned to A=440. Absolutely no percussion of any kind: no drums, no beat, no tempo, no pulse, no arpeggios, and no melody. A single warm sustained C major chord on felt piano and low strings, barely moving, with a faint room tone underneath like a quiet house in the afternoon. Peaceful, settled, unbearably gentle — a photograph rather than a scene. It must not build to anything and must not resolve away; it simply continues. Nothing loud between 250 and 1100 Hz. Sixty seconds, perfectly seamless loop with identical start and end, no fade in and no fade out. Extremely quiet, background level, mastered around -18 LUFS. Fully instrumental: no vocals, no lyrics, no spoken word, no choir syllables.
```

---

## 4. The effects — eight one-shots

All mono, 44.1 kHz, trimmed so they start on the first sample. In ElevenLabs
Sound Effects, paste the block and set duration to the number it names.

### `sfx/cross.ogg` — the tap, the jump across

**The sound the whole request is about.** The landing melody advances on every
beat whether or not the player crossed, so the melody says *you survived* and
this says *you jumped*. It rides on top of the melody; it does not replace it.

That is also what makes the two jumps different: staying in the same lane costs
no tap, so it makes only the melody note. Crossing adds a cat.

It fires up to several times a second at high scores, so anything with weight or
length becomes noise. The engine refuses to retrigger it inside 160 ms.

```
A single short cute kitten chirp-meow, "nya", rising in pitch, bright and light, mouth closed then opening, playful not distressed. Exactly 0.2 seconds long, starting on the first sample with no silence in front of it. Close mic, completely dry: no reverb, no room, no echo, no music, no background. One single sound, mono, nothing else in the recording.
```

Make **three or four variations** and name them `cross.ogg`, `cross_2.ogg` and so
on if you want them rotated — worth doing, because a single sample repeated forty
times a minute becomes obvious fast. (Rotation is not wired up yet; ask for it
and it is a few lines.)

### `sfx/fall.ogg` — the run ending

The long one. A cat falling away from you, pitch and volume going with it.
AUDIO_RULES.md: *the player is becoming smaller and farther away.* This sound is
allowed to break the melody, because the run is over.

Do not let it sound like an animal in pain. It is a cartoon fall — surprise, not
suffering. If a take sounds distressing, it is the wrong take.

```
A single cat meow falling away into the distance, "nyaaaaaaang", starting close and bright then sliding continuously down about one octave over 0.9 seconds while getting quieter and more distant, ending in a soft reverb tail. Plaintive and comic, surprised rather than hurt — never distressed, never a cry of pain. Exactly 1 second long, starting on the first sample with no silence in front of it. One single sound, mono, no music, no background, nothing else in the recording.
```

### `sfx/equip.ogg` — a different cat takes the bridge

Fires in the codex when the player taps a cat they own. The cross cue is that cat
jumping; this is that cat answering. Lower, calmer and a little longer than
`cross`, so the two are never confused — and it plays in a quiet menu, where a
bright chirp would be startling.

```
A single soft contented adult cat meow, one syllable, "mrrow", warm and low-pitched, relaxed and friendly, gently falling in pitch at the end. Exactly 0.5 seconds long, starting on the first sample with no silence in front of it. Close mic, mostly dry with a very small room. Calm, not excited, not a demand for food. One single sound, mono, no music, no background, nothing else in the recording.
```

### `sfx/unlock.ogg` — a new cat opens

Fires on the result card, once, after a run. Two notes, C and G, because the
melody is in C: a chime in another key argues with the last landing note still
ringing.

```
A short warm bell chime of two rising notes, C then G, in the key of C major tuned to A=440. Soft mallet on glass, gentle and satisfying, a small reward. Exactly 0.5 seconds long, starting on the first sample with no silence in front of it. Light reverb, clean. One single sound, mono, no melody beyond the two notes, no percussion, no music bed, no background, nothing else in the recording.
```

### `sfx/arrive.ogg` — the reunion

Once ever, at the moment the ending starts. It plays *under* `music/ending.ogg`,
so it must be simple enough not to fight it.

```
One soft warm major chord on felt piano and strings, C major tuned to A=440, swelling gently from nothing and holding, resolved and complete. Exactly 2 seconds long, starting on the first sample with no silence in front of it. Warm reverb. No melody, no percussion, no beat, no music bed underneath. One single sound, no vocals, nothing else in the recording.
```

### `sfx/zone.ogg` — the sky changes

Fires with the zone banner when the sky turns over, so ten times in a very long
run and never in a short one. The music is crossfading to a new bed at the same
moment, which means this has to mark the change without competing with it: air,
not a chime.

```
A soft rising airy swell, like a breath of wind passing upward through a wide open space. Filtered noise and a faint high shimmer opening and fading away, no clear pitch and no melody, but if anything is tonal it must be C major tuned to A=440. Weightless, atmospheric, a change of altitude rather than an event. Exactly 1.2 seconds long, starting on the first sample with no silence in front of it. Nothing loud between 250 and 1100 Hz. One single sound, mono, no percussion, no beat, no impact, no whoosh transition effect, no music, nothing else in the recording.
```

### `sfx/milestone.ogg` — a milestone flash

Rarer and bigger than a zone change. The last one is at a score almost nobody
reaches, so it is allowed to feel like something.

```
A bright shimmering upward flourish, high bells and glass struck once and left to ring out, in the key of C major tuned to A=440. Wondrous, weightless, a small revelation. No downbeat and no impact at the front — it opens rather than hits. Exactly 1.5 seconds long, starting on the first sample with no silence in front of it, decaying to nothing. Keep the energy above 1100 Hz. One single sound, mono, no percussion, no drum, no beat, no music bed, nothing else in the recording.
```

### `sfx/ui.ogg` — a screen changes

The title screen starting a run, the codex opening, the codex closing. That is
the whole list, deliberately: everything inside a run already has a sound, and
adding a click to every tap would bury the cat.

```
A single tiny soft wooden tick, like one fingertip on a small hollow wooden box. Very short, very quiet, warm and dull rather than sharp or clicky, no pitch, no ring, no tail. Exactly 0.06 seconds long, starting on the first sample with no silence in front of it. Completely dry: no reverb, no room. One single sound, mono, no music, no background, nothing else in the recording.
```

---

## 5. After the render

Suno gives back MP3 or WAV, and neither ships.

```bash
# music beds — mono is fine for pads and halves the download
ffmpeg -i day.wav      -ac 1 -c:a libvorbis -q:a 2 assets/audio/music/day.ogg
ffmpeg -i memorial.wav -ac 1 -c:a libvorbis -q:a 2 assets/audio/music/memorial.ogg
# the one-shots people hear once: keep them in stereo
ffmpeg -i ending.wav   -ac 2 -c:a libvorbis -q:a 5 assets/audio/music/ending.ogg
# effects — short, mono, trimmed to the first sample
ffmpeg -i cross.wav -ac 1 -af "silenceremove=start_periods=1:start_threshold=-50dB,loudnorm=I=-16" \
       -c:a libvorbis -q:a 4 assets/audio/sfx/cross.ogg
```

**Check the loop.** Suno does not make seamless loops. Play the bed twice in a
row and listen to the join; if it clicks or the reverb tail stops dead, crossfade
the last two seconds over the first two in any editor. A bed that thumps every
forty seconds is worse than no bed — and `memorial.ogg` is the one that will be
heard looping most, because that card waits for the player.

### What this costs to download

The exported `.pck` is **562 KB** today. Music is the largest thing that has ever
been added to it.

| | at `-q:a 2` mono | |
|---|---:|---|
| 5 gameplay beds, 40 s | ~1.3 MB | |
| title 30 s + memorial 60 s | ~450 KB | |
| intro + ending, stereo | ~500 KB | |
| 8 effects | ~70 KB | |
| **total** | **~2.3 MB** | takes the build to ~2.9 MB |

That is a real cost on a phone connection and it is worth paying — but check it
after adding the files, not after shipping. `intro`, `ending`, `memorial` and
`title` are heard once per session at most and could be fetched after the first
run rather than bundled, if the number ends up too high.

---

## 6. Where things go, and what happens if they are missing

```
assets/audio/
  music/  day.ogg  dusk.ogg  star.ogg  deep.ogg  beyond.ogg
          title.ogg  intro.ogg  ending.ogg  memorial.ogg
  sfx/    cross.ogg  fall.ogg  equip.ogg  unlock.ogg
          arrive.ogg  zone.ogg  milestone.ogg  ui.ogg
```

| Slot | Fires when | Without a file |
|---|---|---|
| `cross` | the player taps to jump across | a short rising sine chirp, deliberately unlike the melody |
| `fall` | the run ends | the prototype's 780→80 Hz slide |
| `equip` | a cat is tapped in the codex | silence |
| `unlock` | a cat opens, on the result card | silence |
| `arrive` | the walk finishes, as the ending starts | silence |
| `zone` | the sky changes, with the banner | silence |
| `milestone` | a milestone flash | silence |
| `ui` | title start, codex open, codex close | silence |
| any music | the band, screen or cut scene changes | silence, and the next band still fades in cleanly |

Music crossfades over 2.2 s. Bands are `AudioBank.MUSIC_BANDS`, matched on score
and re-checked on every landing, so the track changes when the sky does. When a
cut scene ends the game hands music back to the band for the current score.

`audio_test.gd` fails if a slot exists in `AudioBank` with no prompt in this
file, so this list cannot fall behind the game.

### Two silences that are on purpose

**The landing melody stays synthesised.** It has to be in tune with a note that
changes 24 times per phrase and fire every 24 ms at the floor, and no sample bank
does that better than an oscillator. AUDIO_RULES.md governs it, not this file.

**The epilogue has no sound.** At score 1000 a second figure is walking the
bridges ahead of the cat. STORY.md is explicit that it has no card, no text and
nothing announced — a cue would announce it. It plays under `beyond.ogg` like
everything else out there.
