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


## The tutorial: it stops the world at the instant a jump would work and asks
## for one. Until it does, a tap does nothing at all — a player who has never
## played must not be able to kill themselves while being taught.
func _test_tutorial(game: Node) -> void:
	var state: HalfStepState = game.get("state")
	var progress: Progress = game.get("progress")
	game.get("title_screen").call("close")
	game.get("story_screen").call("stop")
	progress.seen_tutorial = false
	game.call("reset")
	expect(int(game.get("tutorial_step")) == 0, "a fresh profile opens in the tutorial")

	# The first bridge comes straight on and needs no tap. Taps meanwhile are
	# swallowed rather than sending the cat into open sky.
	var guard := 0
	while state.score < 1 and guard < 600:
		press_touch(game, Vector2(195, 400))
		game.call("_process", 0.016)
		guard += 1
	expect(state.score == 1, "the first bridge arrives under the cat on its own")
	expect(state.is_running(), "and none of those taps killed anybody")

	# Then it steers one to the far lane and freezes at the instant it is
	# reachable.
	guard = 0
	while not bool(game.get("tutorial_hold")) and guard < 600:
		game.call("_process", 0.016)
		guard += 1
	expect(bool(game.get("tutorial_hold")), "the world stops when the jump would land")
	var far := 1 - state.lane
	expect(state.can_cross(game.call("base_y"), game.get("row_scroll"), far),
		"and it stops at a moment when the jump really would land")
	var frozen := float(state.step_timer)
	for _i in 30:
		game.call("_process", 0.016)
	expect(is_equal_approx(float(state.step_timer), frozen), "nothing moves while it waits")
	expect(state.score == 1, "least of all the score")

	# The taught tap. It jumps, and the tutorial moves on to ask once more.
	press_touch(game, Vector2(195, 400))
	expect(not bool(game.get("tutorial_hold")), "the taught tap releases the world")
	expect(state.lane == far, "and it is the jump, not a mime of one")
	expect(int(game.get("tutorial_step")) == 2, "the second ask is queued")

	guard = 0
	while int(game.get("tutorial_step")) != 3 and guard < 900:
		if bool(game.get("tutorial_hold")):
			press_touch(game, Vector2(195, 400))
		game.call("_process", 0.016)
		guard += 1
	expect(int(game.get("tutorial_step")) == 3, "two taught jumps and it hands over")
	expect(state.is_running(), "with the run still alive")

	# The send-off keeps the bridges straight ahead so an unwatched beat cannot
	# kill. That must not turn the first tap the player takes on their own into
	# a jump at nothing: the game says "now it is your turn" and would then
	# punish the turn. A well-timed tap during it lands.
	guard = 0
	while not state.can_cross(game.call("base_y"), game.get("row_scroll"), 1 - state.lane) \
			and not state.next_row_in_reach(game.call("base_y"), game.get("row_scroll")) \
			and guard < 400:
		game.call("_process", 0.008)
		guard += 1
	var lane_before := state.lane
	press_touch(game, Vector2(195, 400))
	expect(state.lane != lane_before, "a tap during the send-off is a real jump")
	expect(not bool(game.get("doomed_leap")), "and it is not a jump at nothing")
	guard = 0
	var scored := state.score
	while state.is_running() and state.score == scored and guard < 400:
		game.call("_process", 0.008)
		guard += 1
	expect(state.is_running(), "the bridge is there when the cat comes down")
	# Learned is learned. Dying on the next bridge must not make this player sit
	# through the whole thing again.
	expect(progress.seen_tutorial, "and it is marked learned there, not later")
	game.call("die")
	game.call("reset")
	expect(int(game.get("tutorial_step")) == 4, "so the next run is the player's own")


## Every screen has to fit a screen. The viewport is 390 units wide and its
## height follows the real aspect ratio, so a 4:3 tablet in portrait is 390x520
## — and both the title menu and the memorial card used to run off the bottom
## of it.
func _test_short_screen(game: Node) -> void:
	var progress: Progress = game.get("progress")
	progress.seen_ending = true
	progress.seen_intro = true
	var title: Node = game.get("title_screen")
	var story: Node = game.get("story_screen")
	for height: float in [844.0, 640.0, 520.0, 487.0]:
		var rect := Rect2(Vector2.ZERO, Vector2(390.0, height))
		title.call("layout", rect)
		for row in title.get("_rows"):
			var box := Rect2(row.rect)
			expect(box.end.y <= height,
				"the %s row fits a %dpx screen, ends at %d" % [row.id, int(height), int(box.end.y)])
			expect(box.position.y >= 0.0, "and starts on it")
		story.call("play", "memorial", rect)
		story.set("frame", 0)
		story.set("time", StoryConfig.FADE_MS)
		var card: Rect2 = story.call("_memorial_layout", rect.size).card
		expect(card.position.y >= 0.0 and card.end.y <= height,
			"the memorial fits a %dpx screen, %d..%d" % [int(height), int(card.position.y),
				int(card.end.y)])
		story.call("stop")
	title.call("layout", game.call("game_rect"))


## The title menu row with [param id], or an empty rect when it is not offered.
func _menu_rect(title: Node, id: String) -> Rect2:
	for row in title.get("_rows"):
		if String(row.id) == id:
			return Rect2(row.rect)
	return Rect2()


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
	# A cold launch shows the title, and a fresh profile shows the intro after
	# it. Walk through both the way a player does before driving the game — and
	# check on the way that each one actually holds the run back.
	var state: HalfStepState = game.get("state")
	var title: Node = game.get("title_screen")
	var story: Node = game.get("story_screen")
	# `user://half_step.cfg` survives between runs, so a machine that has run
	# this suite before already has the intro marked seen. State the precondition
	# rather than inheriting it, or this passes in CI and fails locally.
	game.get("progress").set("seen_intro", false)
	game.get("progress").set("seen_tutorial", true)
	game.call("reset")
	expect(bool(title.get("visible")), "a cold launch opens on the title")
	press_touch(game, Vector2(100, 100))
	expect(not bool(title.get("visible")), "a tap leaves the title")
	expect(bool(story.get("visible")), "and a first launch runs the intro next")
	expect(int(state.score) == 0, "no tap during either reaches the run")
	for _frame in 3:
		press_touch(game, Vector2(100, 100))
	expect(not bool(story.get("visible")), "tapping through the intro ends it")
	expect(state.lane == HalfStepState.Lane.LEFT, "and none of those taps moved the cat")

	var real_mouse := InputEventMouseButton.new()
	real_mouse.button_index = MOUSE_BUTTON_LEFT
	real_mouse.pressed = true
	real_mouse.position = Vector2(100, 100)
	Input.parse_input_event(real_mouse)
	await process_frame
	expect(state.lane == HalfStepState.Lane.RIGHT, "web mouse click toggles lane")

	press_touch(game, Vector2(100, 100))
	expect(state.lane == HalfStepState.Lane.LEFT, "mobile screen touch toggles lane")
	# Not just the rules: the lane slide is presentation, and it started.
	expect(float(game.get("lane_time")) >= 0.0, "both input paths reach the presentation layer")

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
	expect(float(game.get("lane_time")) < 0.0, "and the lane slide with it")

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

	# Before the ending a cat still opens, but it is not announced: the codex it
	# would send the player to is shut.
	progress.seen_ending = false
	progress.experience = 0.0
	progress.owned = {CatConfig.STARTER: true}
	state.score = 90
	state.run_experience = 100000.0
	game.call("die")
	expect(progress.owned_count() > 1, "a run that earns a cat still opens it")
	expect(PackedStringArray(game.get("opened_cats")).is_empty(),
		"but nothing is announced while the codex is shut")

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

	# HOME leaves the run for the title. Retry never passes through it, but this
	# is the one way back that does.
	game.set("opened_cats", PackedStringArray())
	layout = game.call("result_layout")
	press_touch(game, Rect2(layout.home).get_center())
	expect(bool(title.get("visible")), "HOME goes back to the title")
	expect(state.score == 0, "and the finished run is gone")

	# The codex is reached from the title, and only after the ending: before it
	# the row is drawn locked, so the player can see a button will appear there.
	progress.seen_ending = false
	title.call("layout", game.call("game_rect"))
	var codex_row: Rect2 = _menu_rect(title, "codex")
	press_touch(game, codex_row.get_center())
	expect(not bool(codex.get("visible")), "the codex row does nothing before the ending")
	expect(bool(title.get("visible")), "and a tap on a locked row does not start a run either")
	expect(_menu_rect(title, "memorial") == Rect2(),
		"the memorial is not offered before it has been reached")

	progress.seen_ending = true
	title.call("layout", game.call("game_rect"))
	expect(_menu_rect(title, "memorial") != Rect2(), "and is offered once it has")
	press_touch(game, _menu_rect(title, "codex").get_center())
	expect(bool(codex.get("visible")), "the codex row opens the codex once the ending is seen")
	expect(bool(title.get("visible")), "over the title, which is still standing behind it")
	press_touch(game, Vector2(4, 4))
	expect(state.run_state == HalfStepState.RunState.PLAYING and state.score == 0,
		"taps behind the codex never reach the game")

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

	# --- the cut scenes and the music underneath them ------------------------
	var music: Node = game.get("music_player")
	game.call("play_story", "ending")
	expect(String(music.get("track")) == AudioBank.MUSIC_ENDING, "the ending plays its own track")
	story.set("frame", StoryConfig.ENDING.size() - 1)
	story.set("time", 0.0)
	expect(bool(story.call("showing_memorial")), "the ending finishes on the memorial")
	# The memorial holds, so the ending's one-shot would run out under it.
	game.call("_process", 0.016)
	expect(String(music.get("track")) == AudioBank.MUSIC_MEMORIAL,
		"the memorial brings its own bed, which loops")
	var held := float(story.get("time"))
	for _i in 400:
		game.call("_process", 0.016)
	expect(bool(story.get("visible")), "and the memorial never times out")
	expect(float(story.get("time")) >= held, "its fade still finishes")

	press_touch(game, Vector2(195, 200))
	expect(not bool(story.get("visible")), "a tap leaves the memorial")
	# It was opened from the title, so leaving it comes back to the title —
	# not to a run the player never started.
	expect(bool(title.get("visible")) and String(music.get("track")) == AudioBank.MUSIC_TITLE,
		"and music goes back to whatever is underneath it")

	_test_tutorial(game)
	_test_short_screen(game)

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
