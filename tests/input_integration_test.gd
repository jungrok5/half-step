extends SceneTree

## Drives the real scene through mouse and touch input the way a phone and a
## browser deliver it, and checks the result card's hit targets.

var failures := 0


func _init() -> void:
	call_deferred("_run")


func expect(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error("FAIL: " + message)


func press_touch(game: Node, position: Vector2) -> void:
	var touch := InputEventScreenTouch.new()
	touch.index = 0
	touch.pressed = true
	touch.position = position
	game.call("_input", touch)


func press_mouse(game: Node, position: Vector2, emulated := false) -> void:
	var mouse := InputEventMouseButton.new()
	mouse.button_index = MOUSE_BUTTON_LEFT
	mouse.pressed = true
	mouse.position = position
	if emulated:
		mouse.device = InputEvent.DEVICE_ID_EMULATION
	game.call("_input", mouse)


func _run() -> void:
	var scene: PackedScene = load("res://scenes/main.tscn")
	var game: Node = scene.instantiate() if scene != null else null
	if game == null or game.get_script() == null:
		push_error("FAIL: res://scenes/main.tscn could not be instantiated")
		quit(1)
		return
	root.add_child(game)
	await process_frame
	var state: HalfStepState = game.get("state")

	var real_mouse := InputEventMouseButton.new()
	real_mouse.button_index = MOUSE_BUTTON_LEFT
	real_mouse.pressed = true
	real_mouse.position = Vector2(100, 100)
	Input.parse_input_event(real_mouse)
	await process_frame
	expect(state.lane == HalfStepState.Lane.RIGHT, "web mouse click toggles lane")

	press_touch(game, Vector2(100, 100))
	expect(state.lane == HalfStepState.Lane.LEFT, "mobile screen touch toggles lane")
	expect(int(game.get("tutorial_taps")) == 2, "both input paths reach the presentation layer")

	press_mouse(game, Vector2(100, 100), true)
	expect(state.lane == HalfStepState.Lane.LEFT, "the emulated mouse duplicate of a touch is ignored")

	# Input is never dropped, including during the hop and the settle window.
	game.set("hop_time", 60.0)
	press_touch(game, Vector2(100, 100))
	expect(state.lane == HalfStepState.Lane.RIGHT, "a tap during the hop still toggles")
	game.set("hop_time", -1.0)
	game.set("settle_time", 10.0)
	press_touch(game, Vector2(100, 100))
	expect(state.lane == HalfStepState.Lane.LEFT, "a tap during the post-landing settle still toggles")
	game.set("settle_time", -1.0)

	# `tap()` returns early on `!running`, so the fall is never interrupted.
	state.run_state = HalfStepState.RunState.DEAD
	game.set("death_time", 120.0)
	var lane_before := state.lane
	press_touch(game, Vector2(100, 100))
	expect(state.lane == lane_before, "taps do nothing while the fall animation plays")
	expect(state.run_state == HalfStepState.RunState.DEAD, "the run does not restart before the card appears")

	game.set("death_time", 600.0)
	var layout: Dictionary = game.call("result_layout")
	press_touch(game, Vector2(4, 4))
	expect(state.run_state == HalfStepState.RunState.DEAD, "tapping the overlay backdrop does not retry")
	press_touch(game, Rect2(layout.retry).get_center())
	expect(state.run_state == HalfStepState.RunState.PLAYING, "the RETRY button restarts the run")
	expect(state.score == 0, "retry clears the score")
	expect(int(game.get("tutorial_taps")) == 0, "retry brings the hint back")

	root.remove_child(game)
	game.free()
	if failures == 0:
		print("PASS: mouse and touch input reach HALF STEP")
	quit(failures)
