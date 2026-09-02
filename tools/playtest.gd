extends SceneTree

## Plays the game and photographs it, in every language, so somebody can look.
##
##   godot --path . --rendering-driver opengl3 --script res://tools/playtest.gd \
##       -- <output-dir> [locale ...]
##
## Needs a display; `xvfb-run` with a software GL driver is enough.
##
## Everything here goes through `_input` and `_process` — the same path a thumb
## and a frame take. Nothing pokes at the rules to arrange a screen, because a
## screen that only exists when it is arranged by hand is not a screen anybody
## will see. The one exception is the score, which is set directly to reach the
## late skies: playing to 600 honestly takes twenty minutes per language.
##
## Every moment is captured twice: once as it looks, and once with every string
## drawn in magenta. Subtracting the two gives an exact mask of which pixels are
## text, which is how `tools/playtest_check.py` measures whether any of it is
## readable against what is behind it. See PROTOTYPE_HISTORY.md — white text on
## a white cloud has shipped here before.

const SETTLE := 6
const TINT := Color(1.0, 0.0, 1.0, 1.0)

var shots: Array[Dictionary] = []
var notes: Array[String] = []
var output := ""


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var arguments := OS.get_cmdline_user_args()
	output = arguments[0] if arguments.size() > 0 else "res://playtest"
	var locales: Array = arguments.slice(1) if arguments.size() > 1 else ["en"]
	DirAccess.make_dir_recursive_absolute(output)
	CssText.start_recording()

	for locale: String in locales:
		await _session(String(locale))

	var report := {
		"locales": locales,
		"shots": shots,
		"overflows": CssText.overflows,
		"notes": notes,
	}
	var file := FileAccess.open("%s/report.json" % output, FileAccess.WRITE)
	file.store_string(JSON.stringify(report, "  "))
	file.close()
	print("%d shots, %d overflows" % [shots.size(), CssText.overflows.size()])
	quit(0)


## One language, played from a cold launch to the memorial.
func _session(locale: String) -> void:
	I18n.use(locale)
	var game: Node = load("res://scenes/main.tscn").instantiate()
	# Set before the node enters the tree, because `_ready` is where the save is
	# first touched. This harness finishes runs and plays cut scenes to the end,
	# all of which write progress; on the real path it would eat a developer's
	# game every time it ran.
	game.set("save_path", "user://playtest.cfg")
	root.add_child(game)
	await process_frame
	# The engine's own `_process` is turned off and every frame is stepped by
	# hand. Otherwise the world advances twice per iteration at unpredictable
	# sizes, and at score 700 — where a beat is 45 ms and the crossing window is
	# 22 — that alone decides whether the run survives. Drawing is unaffected.
	game.process_mode = Node.PROCESS_MODE_DISABLED
	var state: HalfStepState = game.get("state")
	var progress: Progress = game.get("progress")

	# A profile nobody has touched, so the title, the intro and the tutorial all
	# happen the way they do for a new player.
	progress.seen_intro = false
	progress.seen_ending = false
	progress.seen_tutorial = false
	progress.owned = {CatConfig.STARTER: true}
	progress.equipped = CatConfig.STARTER
	progress.experience = 0.0
	progress.tori_steps = 0
	game.call("reset")
	game.get("title_screen").call("open", progress, game.call("game_rect"))
	await _shoot(game, locale, "01-title-cold")

	_tap(game, Vector2(195, 260))
	await _settle(game)
	await _shoot(game, locale, "02-intro-1")
	_tap(game, Vector2(195, 500))
	await _settle(game)
	await _shoot(game, locale, "03-intro-2")
	_tap(game, Vector2(195, 500))
	_tap(game, Vector2(195, 500))
	_check(game, "the intro ends after its frames",
		not bool(game.get("story_screen").get("visible")))

	# The tutorial: it should be waiting, then asking, then out of the way.
	await _run_frames(game, 40)
	await _shoot(game, locale, "04-tutorial-wait")
	await _until(game, func() -> bool: return bool(game.get("tutorial_hold")), 900)
	_check(game, "the tutorial stops the world and asks", bool(game.get("tutorial_hold")))
	await _shoot(game, locale, "05-tutorial-ask")
	_tap(game, Vector2(195, 500))
	_check(game, "the taught tap crosses", state.is_running())
	await _until(game, func() -> bool: return bool(game.get("tutorial_hold")), 900)
	_tap(game, Vector2(195, 500))
	await _run_frames(game, 20)
	await _shoot(game, locale, "06-tutorial-go")
	_check(game, "and the run survives being taught", state.is_running())

	# Play on. `_play` taps only when a bridge is genuinely in reach, which is
	# the game's own rule rather than a cheat.
	await _play(game, 30)
	await _shoot(game, locale, "07-playing")
	_check(game, "thirty honest landings", state.score >= 25)

	# The late skies. Reaching 600 by playing takes twenty minutes a language.
	for score: int in [90, 340, 700]:
		state.score = score
		state.step_interval = maxf(HalfStepState.MIN_INTERVAL_MS,
			560.0 * pow(HalfStepState.SPEED_FACTOR, float(score)))
		game.set("zone_index", -1)
		game.call("apply_zone", true)
		game.call("build_background")
		await _play(game, 6)
		# The zone banner at its peak rather than wherever the last landing left
		# it. It is a real moment and it is only worth grading at full strength.
		game.set("banner_text", String(ZoneConfig.ZONES[int(game.get("zone_index"))].name))
		game.set("banner_secret", false)
		game.set("banner_duration", 1250.0)
		game.set("banner_time", 1250.0 * 0.4)
		await _shoot(game, locale, "08-sky-%d" % score)

	# Death, and the card it leaves.
	game.call("die")
	await _run_frames(game, 45)
	_check(game, "the result card comes up", float(game.get("death_time")) >= 500.0)
	await _shoot(game, locale, "09-result")

	# HOME, and the menu a new player sees there.
	var layout: Dictionary = game.call("result_layout")
	_tap(game, Rect2(layout.home).get_center())
	_check(game, "HOME goes back to the title", bool(game.get("title_screen").get("visible")))
	await _shoot(game, locale, "10-title-locked")

	# Everything unlocked, which is what the screen looks like for anybody who
	# has finished the walk.
	progress.seen_ending = true
	progress.seen_intro = true
	for id: String in ["milk", "soot", "ash", "cocoa"]:
		if CatConfig.by_id(id).has("id"):
			progress.owned[id] = true
	progress.experience = 40000.0
	progress.total_steps = 4213
	progress.total_falls = 168
	progress.days_played = 9
	progress.bests[CatConfig.STARTER] = 342
	game.get("title_screen").call("open", progress, game.call("game_rect"))
	await _shoot(game, locale, "11-title-open")

	var title: Node = game.get("title_screen")
	_tap(game, _menu(title, "codex").get_center())
	_check(game, "the codex opens from the title", bool(game.get("codex_screen").get("visible")))
	await _shoot(game, locale, "12-codex-top")
	game.get("codex_screen").set("scroll", 320.0)
	await _shoot(game, locale, "13-codex-mid")
	game.get("codex_screen").set("scroll",
		float(game.get("codex_screen").call("max_scroll")))
	await _shoot(game, locale, "14-codex-end")
	_tap(game, Rect2(game.get("codex_screen").get("_close")).get_center())
	_check(game, "and closes back to the title", bool(title.get("visible")))

	_tap(game, _menu(title, "memorial").get_center())
	await _settle(game)
	_check(game, "the memorial opens on its own",
		bool(game.get("story_screen").call("showing_memorial")))
	await _shoot(game, locale, "15-memorial")
	_tap(game, Vector2(195, 60))

	_tap(game, _menu(title, "ending").get_center())
	await _settle(game)
	await _shoot(game, locale, "16-ending-1")
	_tap(game, Vector2(195, 500))
	await _settle(game)
	await _shoot(game, locale, "17-ending-3")

	root.remove_child(game)
	game.free()


# --- driving ----------------------------------------------------------------

func _tap(game: Node, position: Vector2) -> void:
	var down := InputEventScreenTouch.new()
	down.index = 0
	down.pressed = true
	down.position = position
	game.call("_input", down)
	var up := InputEventScreenTouch.new()
	up.index = 0
	up.pressed = false
	up.position = position
	game.call("_input", up)


## Past the end of any fade, so nothing is photographed half way in.
func _settle(game: Node) -> void:
	await _run_frames(game, int(StoryConfig.FADE_MS / 16.0) + 8)


func _run_frames(game: Node, count: int) -> void:
	for _i in count:
		game.call("_process", 0.016)
		await process_frame


## Plays [param landings] beats properly: it taps when, and only when, the bridge
## it needs is genuinely within reach.
func _play(game: Node, landings: int) -> void:
	var state: HalfStepState = game.get("state")
	var target := state.score + landings
	var guard := 0
	while state.is_running() and state.score < target and guard < 20000:
		var far := 1 - state.lane
		if state.can_cross(game.call("base_y"), game.get("row_scroll"), far):
			_tap(game, Vector2(195, 500))
		# Four milliseconds a step: at score 700 the whole crossing window is
		# 22 ms wide, and a bot that steps past it is measuring its own reflexes
		# rather than the game's.
		game.call("_process", 0.004)
		guard += 1
		if guard % 40 == 0:
			await process_frame
	_check(game, "a competent player survives %d landings" % landings, state.is_running())


func _menu(title: Node, id: String) -> Rect2:
	for row in title.get("_rows"):
		if String(row.id) == id:
			return Rect2(row.rect)
	return Rect2()


## A failed check records what the game looked like when it failed, because
## "the run did not survive" on its own sends the reader back to guessing.
func _check(game: Node, what: String, ok: bool) -> void:
	if ok:
		return
	var state: HalfStepState = game.get("state")
	notes.append("BROKEN: %s [score %d, lane %d, step %d, hold %s, dead %s, doomed %s]" % [
		what, state.score, state.lane, int(game.get("tutorial_step")),
		str(game.get("tutorial_hold")), str(not state.is_running()),
		str(game.get("doomed_leap"))])


# --- capture ----------------------------------------------------------------

## The frame as it looks, and the same frame with every string in magenta.
func _shoot(game: Node, locale: String, name: String) -> void:
	var stem := "%s-%s" % [locale, name]
	await _capture("%s/%s.png" % [output, stem])
	CssText.debug_tint = TINT
	await _capture("%s/%s.text.png" % [output, stem])
	CssText.debug_tint = Color(0.0, 0.0, 0.0, 0.0)
	shots.append({"locale": locale, "name": name, "stem": stem})


func _capture(path: String) -> void:
	_redraw()
	for _i in SETTLE:
		await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(path)


func _redraw() -> void:
	for node in root.get_children():
		_dirty(node)


func _dirty(node: Node) -> void:
	if node is CanvasItem:
		node.queue_redraw()
	for child in node.get_children():
		_dirty(child)


## Runs until [param condition] or [param limit] frames, whichever first.
func _until(game: Node, condition: Callable, limit: int) -> void:
	var guard := 0
	while not condition.call() and guard < limit:
		game.call("_process", 0.016)
		guard += 1
		if guard % 12 == 0:
			await process_frame
