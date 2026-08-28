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


func release_touch(game: Node, position: Vector2) -> void:
	var touch := InputEventScreenTouch.new()
	touch.index = 0
	touch.pressed = false
	touch.position = position
	game.call("_input", touch)


func drag_touch(game: Node, by: float) -> void:
	var drag := InputEventScreenDrag.new()
	drag.index = 0
	drag.relative = Vector2(0.0, by)
	game.call("_input", drag)


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

	# Input is never dropped, at any point in the beat or while a leap is
	# already in the air. A tap can be a fatal jump now, but it is never ignored.
	state.step_timer = state.step_interval * 0.5
	game.call("_process", 0.0)
	press_touch(game, Vector2(100, 100))
	expect(state.lane == HalfStepState.Lane.RIGHT, "a tap mid-beat still toggles")
	expect(float(game.get("lane_time")) >= 0.0, "and starts a leap")
	press_touch(game, Vector2(100, 100))
	expect(state.lane == HalfStepState.Lane.LEFT, "a tap while a leap is in the air still toggles")
	game.call("reset")

	# A tap is almost always in flight when the run ends, so the fall and the
	# card have to survive it — otherwise the run silently restarts.
	state.run_state = HalfStepState.RunState.DEAD
	game.set("death_time", 120.0)
	press_touch(game, Vector2(100, 100))
	expect(state.run_state == HalfStepState.RunState.DEAD,
		"the tap that was already in flight when the run ended does not retry")
	game.set("death_time", 480.0)
	press_touch(game, Vector2(100, 100))
	expect(state.run_state == HalfStepState.RunState.DEAD, "taps stay ignored until the card is up")

	game.set("death_time", 600.0)
	press_touch(game, Vector2(4, 4))
	expect(state.run_state == HalfStepState.RunState.PLAYING, "once the card is up, a tap anywhere retries")
	expect(state.score == 0, "retry clears the score")
	expect(int(game.get("tutorial_taps")) == 0, "retry brings the hint back")

	state.run_state = HalfStepState.RunState.DEAD
	game.set("death_time", 600.0)
	var layout: Dictionary = game.call("result_layout")
	press_touch(game, Rect2(layout.retry).get_center())
	expect(state.run_state == HalfStepState.RunState.PLAYING, "the RETRY button restarts the run")

	# SHARE is the one target that must not be swallowed by the instant retry.
	state.run_state = HalfStepState.RunState.DEAD
	game.set("death_time", 600.0)
	press_touch(game, Rect2(layout.share).get_center())
	expect(state.run_state == HalfStepState.RunState.DEAD, "tapping SHARE does not restart the run")
	press_touch(game, Rect2(layout.card).position + Vector2(6, 6))
	expect(state.run_state == HalfStepState.RunState.PLAYING, "a tap anywhere else on the card retries")

	# --- the codex and the acquisition card ---------------------------------
	var progress: Progress = game.get("progress")
	var codex: Node = game.get("codex_screen")

	# A cat that opened puts one line on the result card, and that line is the
	# only way to the acquisition card. Everything else still retries, because
	# AGENTS.md section 2 requires restart to stay immediate.
	state.run_state = HalfStepState.RunState.DEAD
	game.set("death_time", 600.0)
	game.set("opened_cats", PackedStringArray(["milk", "soot"]))
	layout = game.call("result_layout")
	press_touch(game, Rect2(layout.new_cat).get_center())
	expect(int(game.get("card_index")) == 0, "the new-cat line opens the acquisition card")
	expect(state.run_state == HalfStepState.RunState.DEAD, "and does not retry")
	var card: Dictionary = game.call("card_layout")
	press_touch(game, Rect2(card.share).get_center())
	expect(int(game.get("card_index")) == 0, "tapping SHARE stays on the card")
	press_touch(game, Rect2(card.card).position + Vector2(6, 6))
	expect(int(game.get("card_index")) == 1, "a tap anywhere else steps to the next new cat")
	press_touch(game, Rect2(card.card).position + Vector2(6, 6))
	expect(int(game.get("card_index")) == -1, "and the last one closes it")
	expect(state.run_state == HalfStepState.RunState.DEAD, "closing the card does not retry")

	# The codex opens from the result card and takes input until it closes.
	game.set("opened_cats", PackedStringArray())
	layout = game.call("result_layout")
	press_touch(game, Rect2(layout.codex).get_center())
	expect(bool(codex.get("visible")), "the codex row opens the codex")
	expect(state.run_state == HalfStepState.RunState.DEAD, "opening the codex does not retry")
	press_touch(game, Vector2(4, 4))
	expect(state.run_state == HalfStepState.RunState.DEAD, "taps behind the codex never reach the game")

	# Dragging scrolls; a tap on an owned cat equips it and a locked one does not.
	codex.call("layout", game.call("game_rect"))
	drag_touch(game, -60.0)
	expect(float(codex.get("scroll")) > 0.0, "dragging scrolls the codex")
	codex.set("scroll", 0.0)
	progress.owned["milk"] = true
	var milk := _card_rect(codex, "milk")
	press_touch(game, milk.get_center())
	release_touch(game, milk.get_center())
	expect(progress.equipped == "milk", "tapping an owned cat equips it")
	var locked := _card_rect(codex, "galaxy")
	press_touch(game, locked.get_center())
	release_touch(game, locked.get_center())
	expect(progress.equipped == "milk", "tapping a locked cat changes nothing")

	# A drag that ends over a cat is a scroll, not a tap.
	progress.owned["soot"] = true
	var soot := _card_rect(codex, "soot")
	press_touch(game, soot.get_center())
	drag_touch(game, -40.0)
	release_touch(game, soot.get_center())
	expect(progress.equipped == "milk", "a drag that ends over a cat does not equip it")

	press_touch(game, Rect2(codex.get("_close")).get_center())
	expect(not bool(codex.get("visible")), "the close button closes the codex")

	root.remove_child(game)
	game.free()
	if failures == 0:
		print("PASS: mouse and touch input reach HALF STEP")
	quit(failures)


## Where a cat's card currently sits on screen.
func _card_rect(codex: Node, id: String) -> Rect2:
	for card: Dictionary in codex.get("_cards"):
		if String(card.cat.id) == id:
			return Rect2(Rect2(card.rect).position - Vector2(0.0, float(codex.get("scroll"))),
				CodexScreen.CARD)
	push_error("FAIL: no codex card for " + id)
	failures += 1
	return Rect2()
