class_name TonePlayer
extends AudioStreamPlayer

## Web Audio equivalent for the prototype's `tone()` and `fallSound()`.
##
## Both prototype sounds are a single oscillator with an exponential gain ramp,
## so the same envelopes are synthesised here into an AudioStreamGenerator.
## Voices are mixed rather than replaced: past a few hundred points the cadence
## is shorter than a note, exactly as overlapping oscillators behave in Web Audio.

enum Wave { TRIANGLE, SINE }

const MIX_RATE := 44100.0
const BUFFER_LENGTH := 0.06
## `successSound()` — major scale across three octaves from a 260 Hz root.
const SCALE := [0, 2, 4, 5, 7, 9, 11, 12]
const PHRASE_LENGTH := 24
const BASE_FREQUENCY := 260.0
const MAX_VOICES := 12

class Voice:
	var wave: int = Wave.TRIANGLE
	var frequency_from := 440.0
	var frequency_to := 440.0
	var frequency_seconds := 1.0
	var gain_from := 0.06
	var gain_to := 0.001
	var gain_seconds := 0.09
	var duration := 0.09
	var elapsed := 0.0
	var phase := 0.0

var _playback: AudioStreamGeneratorPlayback
var _voices: Array[Voice] = []


func _ready() -> void:
	var generator := AudioStreamGenerator.new()
	generator.mix_rate = MIX_RATE
	generator.buffer_length = BUFFER_LENGTH
	stream = generator
	# The project routes web audio through sampled playback, which a generator
	# cannot provide — on the web export that silences the game and logs
	# "trying to play a sample from a stream that cannot be sampled".
	playback_type = AudioServer.PLAYBACK_TYPE_STREAM
	play()
	_playback = get_stream_playback()


## Frequency of the note played for [param phrase_position] (0-23).
static func note_frequency(phrase_position: int) -> float:
	var position := posmod(phrase_position, PHRASE_LENGTH)
	var degree: int = SCALE[position % 8]
	var octave: int = position / 8
	return BASE_FREQUENCY * pow(2.0, float(degree + 12 * octave) / 12.0)


## `successSound()` — one note per successful landing, left/right agnostic.
func play_success_note(phrase_position: int) -> void:
	var voice := Voice.new()
	voice.wave = Wave.TRIANGLE
	voice.frequency_from = note_frequency(phrase_position)
	voice.frequency_to = voice.frequency_from
	voice.gain_from = 0.06
	voice.gain_to = 0.001
	voice.gain_seconds = 0.09
	voice.duration = 0.09
	_push(voice)


## `fallSound()` — 780 Hz sliding down to 80 Hz while fading out.
func play_fall() -> void:
	var voice := Voice.new()
	voice.wave = Wave.SINE
	voice.frequency_from = 780.0
	voice.frequency_to = 80.0
	voice.frequency_seconds = 0.84
	voice.gain_from = 0.065
	voice.gain_to = 0.001
	voice.gain_seconds = 0.88
	voice.duration = 0.9
	_push(voice)


func stop_all() -> void:
	_voices.clear()


func _push(voice: Voice) -> void:
	if _voices.size() >= MAX_VOICES:
		_voices.pop_front()
	_voices.append(voice)


func _process(_delta: float) -> void:
	if _playback == null:
		return
	var frames := _playback.get_frames_available()
	if frames <= 0:
		return
	var step := 1.0 / MIX_RATE
	for _i in frames:
		var sample := next_sample(step)
		_playback.push_frame(Vector2(sample, sample))
	_prune()


## One mixed frame, advanced by [param step] seconds. Split out from [method
## _process] so the synthesis can be driven directly: the headless audio driver
## never pulls frames from the generator.
func next_sample(step: float) -> float:
	var sample := 0.0
	for voice in _voices:
		sample += _advance(voice, step)
	return clampf(sample, -1.0, 1.0)


func _prune() -> void:
	var alive: Array[Voice] = []
	for voice in _voices:
		if voice.elapsed < voice.duration:
			alive.append(voice)
	_voices = alive


func _advance(voice: Voice, step: float) -> float:
	if voice.elapsed >= voice.duration:
		return 0.0
	var frequency := voice.frequency_from
	if not is_equal_approx(voice.frequency_to, voice.frequency_from):
		var ratio := minf(voice.elapsed / voice.frequency_seconds, 1.0)
		frequency = voice.frequency_from * pow(voice.frequency_to / voice.frequency_from, ratio)
	var gain_ratio := minf(voice.elapsed / voice.gain_seconds, 1.0)
	var gain: float = voice.gain_from * pow(voice.gain_to / voice.gain_from, gain_ratio)
	voice.phase = fmod(voice.phase + frequency * step, 1.0)
	voice.elapsed += step
	return _wave(voice.wave, voice.phase) * gain


static func _wave(wave: int, phase: float) -> float:
	if wave == Wave.SINE:
		return sin(phase * TAU)
	return 1.0 - 4.0 * absf(fmod(phase + 0.25, 1.0) - 0.5)
