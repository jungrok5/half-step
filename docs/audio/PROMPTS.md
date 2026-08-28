# TORI — sound

Every prompt for the music and the effects, plus what each one has to obey and
where the file goes.

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
| The eight music beds | **Suno** or Udio | This is what they are for. Ask for instrumental. |
| Cat meows, the fall | **ElevenLabs Sound Effects**, or a licensed cat library, or a real cat and a phone | Text-to-SFX, one-shots, a few seconds. A real recording of a real cat beats all of it and costs nothing. |
| Unlock chime, arrival | ElevenLabs SFX, or keep synthesising | Two sounds; not worth a subscription on their own. |

A phone recording of an actual cat, trimmed, is the best-sounding and cheapest
option for the four cat cues. Consider it first.

---

## 2. Rules every music track obeys

These are not stylistic preferences. Breaking any of them makes the track fight
the game.

**C major, A=440.** The landing melody is a C major scale climbing three octaves
(`TonePlayer.SCALE`, root now exactly middle C at 261.63 Hz). It plays over
everything, several times a second at speed. A track in any other key is a wrong
note dozens of times a minute.

**No drums. No pulse. No tempo.** The cadence goes from 560 ms per beat at the
start to 24 ms at the floor, continuously, inside a single run. Nothing with a
fixed tempo can stay with it. **The player's tapping is the rhythm section and
the landing melody is the lead** — the music is harmony and weather, nothing
else. Pads, drones, sustained strings, bowed metal, held choir. No kick, no
snare, no hats, no arpeggiated sequencer, no strummed guitar.

**Seamless loop, 40 seconds.** The five gameplay beds run under runs of any
length. The three one-shots (title, intro, ending) do not loop.

**Nothing in the 250–1100 Hz band should be loud.** That is where the melody
lives. Put the music below and above it: sub and low pads under, air and shimmer
over, a scooped middle.

**Instrumental. No vocals, no lyrics, no words.** A voice sits exactly in the
melody's range and the game is shipping in twelve languages.

**Quiet.** These are beds. Master around −16 LUFS; the game plays them at −9 dB
under everything else.

---

## 3. The music

Eight tracks. One per band of skies rather than one per sky — eleven zones would
be eleven downloads, and the skies change faster than music should.

Suno: paste the prompt into **Custom / Instrumental**, leave lyrics empty.

### `music/day.ogg` — score 0–59 · BLUE SKY, GOLDEN WIND

The first thing anyone hears. Warm, ordinary, a little empty. This is the sound
of a cat that has just set out and does not yet know how far it is.

```
Instrumental ambient. Key of C major, A=440. No percussion of any kind, no beat, no tempo, no arpeggios. Warm sustained pads, soft felt piano held long with the sustain pedal down, a distant bowed cello. Gentle, patient, a little lonely but not sad — morning light in an empty room. Slow evolving swells with no rhythmic pulse whatsoever. Scooped mids: keep the 250-1100 Hz range quiet and open. Loopable, seamless, quiet, no vocals, no lyrics, no spoken word.
```

### `music/dusk.ogg` — score 60–149 · SUNSET RUN, NIGHT BREAK

The light is going. Same world, lower.

```
Instrumental ambient. Key of C major, A=440. No percussion, no beat, no tempo, no arpeggios. Low warm strings and a soft analogue synth pad, a single sustained horn far away, faint tape hiss. Golden and fading, evening, the last of the light. Long slow swells, no rhythmic pulse. Slightly darker and lower than the previous cue. Scooped mids, keep 250-1100 Hz quiet. Loopable, seamless, quiet, no vocals, no lyrics.
```

### `music/star.ogg` — score 150–299 · STAR RUSH, AURORA EDGE

Where it stops being a nice walk. Cold, wide, a little thrilling.

```
Instrumental ambient. Key of C major, A=440. No percussion, no beat, no tempo. Cold shimmering pads, bowed vibraphone and glass harmonica, high sustained strings, wide reverb. Vast, weightless, night at altitude, beautiful and slightly frightening. Very slow evolution, no pulse. High shimmer above and deep sub below with the middle left empty. Loopable, seamless, quiet, no vocals.
```

### `music/deep.ogg` — score 300–549 · RED STRATOS, VOID CURRENT

Almost nobody hears this. It can be strange.

```
Instrumental ambient drone. Key of C major, A=440. No percussion, no beat, no tempo, no melody. Deep sustained sub bass, dark bowed metal, a slowly detuning pad, distant filtered noise like wind at extreme altitude. Airless, immense, unsettling but never aggressive. Nearly static, changing across thirty seconds rather than four bars. Almost nothing in the mids. Loopable, seamless, quiet, no vocals.
```

### `music/beyond.ogg` — score 550+ · CHROMA STORM, WHITE HORIZON, BEYOND

The end of the map. This is the one people will film.

```
Instrumental ambient drone. Key of C major, A=440. No percussion, no beat, no tempo. A single vast sustained chord in slowly shifting overtones, bowed cymbal, choir-like pad with no discernible voices or words, very long reverb tail. Overwhelming stillness, white light, the sound of somewhere nobody was meant to reach. Almost no change over time. Loopable, seamless, quiet, no vocals, no lyrics, no spoken word.
```

### `music/title.ogg` — the title screen

Short and inviting, so it does not wear out while somebody reads the buttons.

```
Instrumental ambient. Key of C major, A=440. No percussion, no beat, no tempo. Soft felt piano and one warm pad, spacious, unhurried, welcoming. A simple held motif that resolves and rests. Nostalgic and gentle, a memory of a home. Loopable, seamless, twenty to thirty seconds, quiet, no vocals.
```

### `music/intro.ogg` — the intro, plays once (~14 s)

The one place the story is stated, so this is allowed to be sad. Still no drums.

```
Instrumental. Key of C major, A=440. No percussion, no beat, no tempo. Solo felt piano, very close and quiet, with one distant sustained string entering halfway. Tender, restrained, grief without weeping. It does not resolve — it opens. Fifteen seconds, ending unfinished on a suspension rather than a chord. No vocals, no lyrics, no loop.
```

### `music/ending.ogg` — the ending, plays once (~14 s)

Twenty seconds that most players reach after forty minutes of walking. It has to
land, and then it has to stop.

```
Instrumental. Key of C major, A=440. No percussion, no beat, no tempo. Solo felt piano joined by warm strings, building very slowly to one full resolved major chord and holding it while everything decays into silence. Arrival, relief, being met. Warm, close, unhurried. Twenty seconds. Resolve fully on the tonic and let the reverb fall away to nothing. No vocals, no lyrics, no loop.
```

---

## 4. The effects

Four one-shots. All mono, 44.1 kHz, trimmed hard so they start on the first
sample — a cue with 40 ms of silence in front of it feels like input lag.

### `sfx/cross.ogg` — the tap, the jump across

**This is the sound the request is about.** The landing melody advances on every
beat whether or not the player crossed, so the melody says *you survived* and
this says *you jumped*. It rides on top of the melody; it does not replace it.

That is also what makes the two jumps different: staying in the same lane costs
no tap, so it makes only the melody note. Crossing adds a cat.

Bright, tiny, upward, over almost before it starts. It fires up to several times
a second at high scores, so anything with weight or length becomes noise. The
engine already refuses to retrigger it inside 160 ms.

```
A single short cute kitten chirp-meow, "nya", rising in pitch, bright and light, mouth closed then opening, 0.2 seconds, close mic, no reverb, no room, no music, dry, clean, one sound only.
```

Make **three or four variations** and name them `cross.ogg`, `cross_2.ogg` and so
on if you want them rotated — worth doing, because a single sample repeated forty
times a minute becomes obvious fast. (Rotation is not wired up yet; ask for it
and it is a few lines.)

### `sfx/fall.ogg` — the run ending

The long one. A cat falling away from you, pitch and volume going with it.
AUDIO_RULES.md: *the player is becoming smaller and farther away.* This sound is
allowed to break the melody, because the run is over.

```
A single cat meow falling in pitch as it fades into the distance, "nyaaaaaaang", starting close and bright then sliding continuously down about an octave over 0.9 seconds while getting quieter and more distant, ending in soft reverb tail, plaintive but comic not distressing, no music, one sound only.
```

Do not let it sound like an animal in pain. It is a cartoon fall — surprise, not
suffering. If a take sounds distressing, it is the wrong take.

### `sfx/unlock.ogg` — a new cat opens

Fires on the result card, once, after a run.

```
A short warm bell chime, two notes rising, C and G, soft mallet on glass, gentle and satisfying, half a second, light reverb, no music, one sound only.
```

Two notes, C and G, because the melody is in C. A chime in another key argues
with the last landing note still ringing.

### `sfx/arrive.ogg` — the reunion

Once ever, at the moment the ending starts. It plays *under* `music/ending.ogg`,
so it must be simple enough not to fight it.

```
One soft warm major chord on felt piano and strings, C major, swelling gently and holding, two seconds, warm reverb, resolved and complete, no melody, no percussion, one sound only.
```

---

## 5. After the render

Suno gives back MP3 or WAV, and neither ships.

```bash
# music beds — mono is fine for pads and halves the download
ffmpeg -i day.wav      -ac 1 -c:a libvorbis -q:a 2 assets/audio/music/day.ogg
# the two one-shots people hear once: keep them in stereo
ffmpeg -i ending.wav   -ac 2 -c:a libvorbis -q:a 5 assets/audio/music/ending.ogg
# effects — short, mono, trimmed to the first sample
ffmpeg -i cross.wav -ac 1 -af "silenceremove=start_periods=1:start_threshold=-50dB,loudnorm=I=-16" \
       -c:a libvorbis -q:a 4 assets/audio/sfx/cross.ogg
```

**Check the loop.** Suno does not make seamless loops. Play the bed twice in a
row and listen to the join; if it clicks or the reverb tail stops dead, crossfade
the last two seconds over the first two in any editor. A bed that thumps every
forty seconds is worse than no bed.

### What this costs to download

The exported `.pck` is **531 KB** today. Music is the largest thing that has ever
been added to it.

| | at `-q:a 2` mono | |
|---|---:|---|
| 5 gameplay beds, 40 s | ~1.3 MB | |
| title, 30 s | ~200 KB | |
| intro + ending, stereo | ~500 KB | |
| 4 effects | ~40 KB | |
| **total** | **~2 MB** | takes the build to ~2.5 MB |

That is a real cost on a phone connection and it is worth paying — but check it
after adding the files, not after shipping. `intro`, `ending` and `title` are
heard once and could be fetched after the first run rather than bundled, if the
number ends up too high.

---

## 6. Where things go, and what happens if they are missing

```
assets/audio/
  music/  day.ogg  dusk.ogg  star.ogg  deep.ogg  beyond.ogg
          title.ogg  intro.ogg  ending.ogg
  sfx/    cross.ogg  fall.ogg  unlock.ogg  arrive.ogg
```

| Slot | With a file | Without one |
|---|---|---|
| `cross` | plays it | a short rising sine chirp, deliberately unlike the melody |
| `fall` | plays it | the prototype's 780→80 Hz slide |
| `unlock`, `arrive` | plays it | silence |
| any music | crossfades in over 2.2 s | silence, and the next band still fades in cleanly |

Bands are `AudioBank.MUSIC_BANDS`, matched on score and re-checked on every
landing, so the track changes when the sky does.

**The landing melody is not in this list.** It stays synthesised: it has to be
in tune with a note that changes 24 times per phrase and fire every 24 ms at the
floor, and no sample bank does that better than an oscillator. AUDIO_RULES.md
governs it, not this document.
