extends SceneTree

## Checks that the synthesiser really produces the prototype's sounds. The
## headless audio driver never pulls frames from the generator, so the mixer is
## driven directly through [method TonePlayer.next_sample].

const STEP := 1.0 / TonePlayer.MIX_RATE

var failures := 0


func _init() -> void:
	call_deferred("_run")


func expect(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error("FAIL: " + message)


## Renders [param seconds] of audio and returns the samples.
func render(player: TonePlayer, seconds: float) -> PackedFloat32Array:
	var samples := PackedFloat32Array()
	for _i in int(TonePlayer.MIX_RATE * seconds):
		samples.append(player.next_sample(STEP))
	return samples


## Frequency estimated from zero crossings.
func frequency_of(samples: PackedFloat32Array, seconds: float) -> float:
	var crossings := 0
	for i in range(1, samples.size()):
		if (samples[i - 1] < 0.0) != (samples[i] < 0.0):
			crossings += 1
	return float(crossings) / (2.0 * seconds)


func peak(samples: PackedFloat32Array) -> float:
	var loudest := 0.0
	for sample in samples:
		loudest = maxf(loudest, absf(sample))
	return loudest


func _run() -> void:
	var player := TonePlayer.new()
	root.add_child(player)
	await process_frame

	# The web export routes audio through sampled playback by default, which an
	# AudioStreamGenerator cannot provide — the game would be silent in browsers.
	expect(player.playback_type == AudioServer.PLAYBACK_TYPE_STREAM,
		"the generator plays as a stream so the web export is not silent")

	expect(is_zero_approx(peak(render(player, 0.01))), "silence before anything is played")

	# A landing note: 260Hz root, audible, and gone within its 90ms envelope.
	player.play_success_note(0)
	var note := render(player, 0.05)
	expect(peak(note) > 0.01, "a landing note is audible")
	var measured := frequency_of(note, 0.05)
	expect(absf(measured - 260.0) < 12.0, "the root note is near 260Hz, measured %d" % int(measured))
	render(player, 0.045)
	expect(is_zero_approx(peak(render(player, 0.02))), "the note is over within its 90ms envelope")

	# An octave up after eight landings.
	player.play_success_note(8)
	var octave := frequency_of(render(player, 0.05), 0.05)
	expect(absf(octave - 520.0) < 24.0, "the ninth note is an octave up, measured %d" % int(octave))
	render(player, 0.05)

	# Notes overlap rather than cut each other off once the cadence is short.
	player.play_success_note(0)
	render(player, 0.02)
	player.play_success_note(4)
	expect(peak(render(player, 0.01)) > 0.01, "a second note layers over the first")
	render(player, 0.12)

	# The fall descends in pitch and fades, per AUDIO_RULES.md.
	# The sweep is exponential, so even a short opening window averages below the
	# 780Hz start: 20ms in it is already down to about 760Hz.
	player.play_fall()
	var opening := render(player, 0.02)
	var opening_frequency := frequency_of(opening, 0.02)
	render(player, 0.54)
	var ending := render(player, 0.06)
	var ending_frequency := frequency_of(ending, 0.06)
	expect(absf(opening_frequency - 780.0) < 45.0,
		"the fall starts near 780Hz, measured %d" % int(opening_frequency))
	expect(ending_frequency < opening_frequency * 0.5,
		"the fall slides down in pitch: %d -> %d" % [int(opening_frequency), int(ending_frequency)])
	expect(peak(ending) < peak(opening), "the fall fades as it descends")
	render(player, 0.4)
	expect(is_zero_approx(peak(render(player, 0.02))), "the fall ends after its 0.9s")

	player.play_fall()
	player.stop_all()
	expect(is_zero_approx(peak(render(player, 0.02))), "retrying cuts the fall short")

	root.remove_child(player)
	player.free()
	if failures == 0:
		print("PASS: HALF STEP audio matches the prototype")
	quit(failures)
