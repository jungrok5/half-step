extends SceneTree

var failures := 0

func _init() -> void:
	call_deferred("_run")

func expect(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error("FAIL: " + message)

func _run() -> void:
	var game: Node = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	var state: HalfStepState = game.get("state")

	var mouse := InputEventMouseButton.new()
	mouse.button_index = MOUSE_BUTTON_LEFT
	mouse.pressed = true
	mouse.position = Vector2(100, 100)
	Input.parse_input_event(mouse)
	await process_frame
	expect(state.lane == HalfStepState.Lane.RIGHT, "web mouse click toggles lane")

	var touch := InputEventScreenTouch.new()
	touch.index = 0
	touch.pressed = true
	touch.position = Vector2(100, 100)
	game.call("_input", touch)
	await process_frame
	expect(state.lane == HalfStepState.Lane.LEFT, "mobile screen touch handler toggles lane")
	expect(int(game.get("tutorial_taps")) == 2, "both input paths reach presentation")

	var emulated_mouse := InputEventMouseButton.new()
	emulated_mouse.button_index = MOUSE_BUTTON_LEFT
	emulated_mouse.pressed = true
	emulated_mouse.device = InputEvent.DEVICE_ID_EMULATION
	game.call("_input", emulated_mouse)
	expect(state.lane == HalfStepState.Lane.LEFT, "emulated mouse duplicate is ignored after touch")

	state.run_state = HalfStepState.RunState.DEAD
	game.set("death_time", 0.05)
	game.call("_input", touch)
	expect(state.run_state == HalfStepState.RunState.PLAYING, "tap immediately restarts before result card appears")

	if failures == 0:
		print("PASS: mouse and touch input reach HALF STEP")
	quit(failures)
