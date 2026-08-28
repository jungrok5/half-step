extends SceneTree

## Renders portrait screenshots of fixed game states so the Godot port can be
## compared side by side with the HTML prototype.
##
##   godot --path . --script res://tools/render_snapshots.gd -- <output-dir>
##
## Needs a real display; under CI use `xvfb-run` with a software GL driver.

const SCORES := [0, 12, 45, 120, 175, 260, 340, 430, 600, 820, 1050]
const SETTLE_FRAMES := 8


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var arguments := OS.get_cmdline_user_args()
	var output := arguments[0] if arguments.size() > 0 else "res://snapshots"
	DirAccess.make_dir_recursive_absolute(output)
	var game: Node = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	# Freeze the run so a fixed score stays put while the frame is captured.
	game.process_mode = Node.PROCESS_MODE_DISABLED
	# A cold launch opens on the title, which would otherwise sit on top of
	# every shot below. It gets its own capture at the end.
	game.get("title_screen").call("close")
	game.get("story_screen").call("stop")
	var state: HalfStepState = game.get("state")

	for score: int in SCORES:
		state.score = score
		state.success_streak = score
		state.step_interval = maxf(HalfStepState.MIN_INTERVAL_MS, 560.0 * pow(HalfStepState.SPEED_FACTOR, float(score)))
		game.set("zone_index", -1)
		game.call("apply_zone", true)
		game.call("build_background")
		# Let the parallax settle so the sky is not identical in every shot.
		for _i in 40:
			game.call("update_background", 16.0)
		await _capture(game, "%s/score-%04d.png" % [output, score])

	# The result card, at a score that reveals a late zone.
	state.score = 340
	state.run_state = HalfStepState.RunState.DEAD
	game.set("zone_index", -1)
	game.call("apply_zone", true)
	game.set("death_time", 900.0)
	var progress: Progress = game.get("progress")
	var seen := progress.seen_ending
	progress.seen_ending = true
	await _capture(game, "%s/result-card.png" % output)
	# The same card before the ending, where the codex row is the walk instead.
	progress.seen_ending = false
	await _capture(game, "%s/result-card-locked.png" % output)
	progress.seen_ending = seen

	# The share image handed to the OS share sheet.
	var zone := ZoneConfig.for_score(340)
	var card: Image = await ShareCard.render(game, 340, zone, String(zone.name))
	card.save_png("%s/share-card.png" % output)
	print("share-card.png")

	# The title, and every cut-scene frame. The memorial the ending finishes on
	# is drawn from the save file, so it is given numbers worth reading.
	state.run_state = HalfStepState.RunState.PLAYING
	game.set("death_time", -1.0)
	progress.total_steps = 4213
	progress.total_falls = 168
	progress.days_played = 9
	progress.bests[CatConfig.STARTER] = 342
	var title: Node = game.get("title_screen")
	title.call("open", progress, game.call("game_rect"))
	await _capture(game, "%s/title.png" % output)
	title.call("close")

	var story: Node = game.get("story_screen")
	for sequence: String in ["intro", "ending"]:
		# Straight to the screen rather than through `play_story`, which would
		# write "seen it" into the player's own save file.
		story.call("play", sequence, game.call("game_rect"))
		for i in StoryConfig.frames(sequence).size():
			story.set("frame", i)
			story.set("time", StoryConfig.FADE_MS)
			await _capture(game, "%s/story-%s-%d.png" % [output, sequence, i + 1])
		story.call("stop")

	root.remove_child(game)
	game.free()
	quit(0)


func _capture(game: Node, path: String) -> void:
	game.call("queue_redraw")
	for _i in SETTLE_FRAMES:
		await process_frame
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	image.save_png(path)
	print(path.get_file())
