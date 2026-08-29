extends SceneTree

## The codex rules: experience, levels, and the four ways a cat opens.
## See PROGRESSION.md — every number checked here is stated there.

var failures := 0


func _init() -> void:
	_test_experience_beats_farming()
	_test_experience_matches_the_published_table()
	_test_level_curve()
	_test_level_unlocks()
	_test_score_unlocks()
	_test_feats()
	_test_witness()
	_test_persistence()
	_test_roster_is_well_formed()
	_test_reunion()
	_test_every_character_has_a_glyph()
	_test_epilogue()
	_test_story_frames()
	_test_memorial()
	_test_every_locale_is_complete()
	if failures == 0:
		print("PASS: HALF STEP progression and codex")
	quit(failures)


func expect(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error("FAIL: " + message)


## Runs a whole run's worth of landings through the real state machine.
func run_to(score: int) -> HalfStepState:
	var state := HalfStepState.new(7)
	var base_y := 600.0
	state.reset(base_y, 844.0, 7)
	for i in score:
		var index := state.nearest_row_index(base_y)
		state.lane = int(state.rows[index].safe_lane)
		expect(not state.resolve_landing(base_y).is_empty(), "landing %d succeeds" % i)
		state.advance_rows(base_y, 844.0)
	return state


## The reason experience is not the score. PROGRESSION.md section 2: if it were,
## repeating a short run would beat going deep, and the codex would measure
## patience instead of skill.
func _test_experience_beats_farming() -> void:
	var deep := run_to(400).run_experience
	var shallow := run_to(40).run_experience
	expect(deep > shallow * 20.0,
		"one run of 400 outpays twenty runs of 40 (%d vs %d)" % [int(deep), int(shallow * 20.0)])
	expect(run_to(1000).run_experience > run_to(60).run_experience * 1000.0,
		"a run of 1000 is worth more than a thousand runs of 60")


func _test_experience_matches_the_published_table() -> void:
	# PROGRESSION.md section 2, rounded to whole experience.
	for entry: Array in [[10, 10], [60, 75], [100, 147], [400, 2352], [1000, 144545]]:
		var earned := run_to(int(entry[0])).run_experience
		expect(absf(earned - float(entry[1])) <= 1.0,
			"score %d pays %d experience, got %d" % [entry[0], entry[1], int(earned)])
	# Past the 24ms speed floor every landing pays the same.
	var state := HalfStepState.new(1)
	state.reset(600.0, 844.0, 1)
	state.score = 900
	state.step_interval = HalfStepState.MIN_INTERVAL_MS
	var before := state.run_experience
	var index := state.nearest_row_index(600.0)
	state.lane = int(state.rows[index].safe_lane)
	state.resolve_landing(600.0)
	expect(absf((state.run_experience - before) - 544.4) < 0.5,
		"a landing at the speed floor pays 544, got %d" % int(state.run_experience - before))


func _test_level_curve() -> void:
	expect(is_zero_approx(Progress.threshold(1)), "level 1 is free")
	expect(is_equal_approx(Progress.threshold(2), 40.0), "level 2 costs 40")
	expect(is_equal_approx(Progress.threshold(30), 140483.0), "level 30 sits at 140,483")
	expect(is_equal_approx(Progress.threshold(50), 43199483.0), "level 50 sits at 43,199,483")
	expect(Progress.level_for(0.0) == 1, "no experience is level 1")
	expect(Progress.level_for(39.0) == 1, "one short of the threshold is still level 1")
	expect(Progress.level_for(40.0) == 2, "the threshold itself levels up")
	expect(Progress.level_for(1.0e12) == Progress.MAX_LEVEL, "the level is capped")
	# The curve may only steepen: ten levels costs about ten times the last ten.
	var previous := 0.0
	for i in Progress.LEVEL_STEPS.size():
		var step := float(Progress.LEVEL_STEPS[i])
		expect(step >= previous, "level step %d never cheapens" % i)
		previous = step
	# No cat hangs above level 30 — the prestige tail carries nothing.
	for cat in CatConfig.all():
		if int(cat.unlock) == CatConfig.Unlock.LEVEL:
			expect(int(cat.value) <= 30, "level cat %s sits at or below Lv30" % String(cat.code))


func _test_level_unlocks() -> void:
	var progress := Progress.new()
	expect(progress.owns(CatConfig.STARTER), "the starting cat is owned from the outset")
	expect(progress.owned_count() == 1, "and it is the only one")
	var opened := progress.finish_run(0, Progress.threshold(2), RunFeats.new())
	expect(opened == ["milk"], "reaching level 2 opens exactly MILK, got %s" % str(opened))
	expect(progress.level() == 2, "the level moved")
	# A jump of several levels opens every cat it passed, in table order.
	opened = progress.finish_run(0, Progress.threshold(7) - progress.experience, RunFeats.new())
	expect(opened == ["soot", "butter", "tuxedo", "calico"],
		"a multi-level jump opens all of them in order, got %s" % str(opened))
	# Opening is once only.
	expect(progress.finish_run(0, 0.0, RunFeats.new()).is_empty(), "nothing opens twice")


func _test_score_unlocks() -> void:
	var progress := Progress.new()
	expect(progress.finish_run(99, 0.0, RunFeats.new()).is_empty(), "99 opens nothing")
	expect(progress.finish_run(100, 0.0, RunFeats.new()) == ["silence"], "100 opens SILENCE")
	# The score has to happen in ONE run: two runs of 100 are not a run of 210.
	progress.finish_run(100, 0.0, RunFeats.new())
	expect(not progress.owns("aurora"), "two runs of 100 do not add up to 210")
	expect(progress.finish_run(1000, 0.0, RunFeats.new()).size() == 6,
		"a run of 1000 opens every remaining sky cat at once")
	expect(progress.owns("beyond"), "including BEYOND")


func _test_feats() -> void:
	# Crossings.
	var progress := Progress.new()
	var feats := RunFeats.new()
	for i in 39:
		feats.record_jump(0.5)
	expect(progress.finish_run(10, 0.0, feats).is_empty(), "39 crossings is not enough")
	feats.record_jump(0.5)
	expect(progress.finish_run(10, 0.0, feats) == ["meridian"], "40 crossings opens MERIDIAN")

	# The early-window streak, and that a late jump breaks it.
	feats = RunFeats.new()
	for i in 20:
		feats.record_jump(0.05)
	feats.record_jump(0.6)
	for i in 20:
		feats.record_jump(0.05)
	expect(feats.early_jump_streak == 20, "a late jump breaks the streak, got %d" % feats.early_jump_streak)
	expect(feats.crossings == 41, "every reachable jump still counts as a crossing")
	feats = RunFeats.new()
	for i in 30:
		feats.record_jump(0.02)
	progress = Progress.new()
	expect(progress.finish_run(10, 0.0, feats).has("last_step"), "30 early jumps opens LAST-STEP")

	# A jump that could not reach is not a crossing, and ends the streak.
	feats = RunFeats.new()
	feats.record_jump(0.02)
	feats.record_jump(-1.0)
	expect(feats.crossings == 1, "a jump into open sky is not a crossing")
	expect(feats.early_jump_streak == 1, "and it ends the streak")

	# First run after launch only.
	progress = Progress.new()
	expect(progress.finish_run(120, 0.0, RunFeats.new()).has("obsidian"), "100 on the first run opens OBSIDIAN")
	progress = Progress.new()
	progress.finish_run(10, 0.0, RunFeats.new())
	expect(not progress.finish_run(120, 0.0, RunFeats.new()).has("obsidian"),
		"the second run of a session cannot open OBSIDIAN")

	# Three consecutive runs at 60 or better.
	progress = Progress.new()
	progress.finish_run(60, 0.0, RunFeats.new())
	progress.finish_run(59, 0.0, RunFeats.new())
	progress.finish_run(60, 0.0, RunFeats.new())
	progress.finish_run(60, 0.0, RunFeats.new())
	expect(not progress.owns("polar"), "a run under 60 resets the streak")
	expect(progress.finish_run(60, 0.0, RunFeats.new()).has("polar"), "three in a row opens POLAR")


func _test_witness() -> void:
	var progress := Progress.new()
	expect(progress.witness("not_a_cat").is_empty(), "an unknown id is ignored")
	expect(not progress.has_witnessed("not_a_cat"), "and is not recorded")
	expect(progress.witness(CatConfig.STARTER).is_empty(), "a cat already owned is not witnessed")
	for id: String in ["aurora", "cinder", "void", "chroma"]:
		expect(progress.witness(id).is_empty(), "%s witnessed, nothing opens yet" % id)
	expect(progress.witness("aurora").is_empty(), "the same cat twice does not count twice")
	expect(progress.witness("horizon") == ["nameless"], "the fifth different cat opens NAMELESS")
	expect(not progress.owns("aurora"), "witnessing never hands the cat over")
	expect(progress.has_witnessed("aurora"), "it stays witnessed")


func _test_persistence() -> void:
	var progress := Progress.new()
	progress.finish_run(400, 12345.0, RunFeats.new())
	progress.witness("chroma")
	progress.equipped = "void"
	var config := ConfigFile.new()
	progress.save_to(config)

	var restored := Progress.new()
	restored.load_from(config)
	expect(is_equal_approx(restored.experience, progress.experience), "experience survives a save")
	expect(restored.owned_count() == progress.owned_count(), "the codex survives a save")
	expect(restored.owns("void"), "an owned cat survives")
	expect(restored.has_witnessed("chroma"), "a witnessed cat survives")
	expect(restored.equipped == "void", "the equipped cat survives")
	expect(restored.bests.get(CatConfig.STARTER, 0) == 400, "the per-cat best survives")
	expect(restored.runs_this_session == 0, "a launch resets the first-run feat")

	# A save that names a cat the player does not own must not equip it.
	config.set_value(Progress.SECTION, "equipped", "beyond")
	config.set_value(Progress.SECTION, "owned", PackedStringArray(["milk", "nonsense"]))
	var tampered := Progress.new()
	tampered.load_from(config)
	expect(tampered.equipped == CatConfig.STARTER, "an unowned equipped cat falls back to the starter")
	expect(tampered.owns(CatConfig.STARTER), "the starter is always owned")
	expect(not tampered.owns("nonsense"), "an unknown id in the save is dropped")


## The story: the walk is measured in landings made as Tori, and it is the one
## unlock that a failed run still advances.
func _test_reunion() -> void:
	var progress := Progress.new()
	expect(not progress.reunion_reached(), "the walk starts unfinished")
	expect(progress.steps_remaining() == StoryConfig.REUNION_STEPS, "with the whole distance left")
	progress.finish_run(40, 0.0, RunFeats.new())
	expect(progress.tori_steps == 40, "a run adds its score to the distance")
	expect(progress.steps_remaining() == StoryConfig.REUNION_STEPS - 40, "and takes it off what is left")
	# Another cat's run is that cat's, not Tori's.
	progress.owned["milk"] = true
	progress.equipped = "milk"
	progress.finish_run(100, 0.0, RunFeats.new())
	expect(progress.tori_steps == 40, "another cat's run does not walk Tori forward")
	progress.equipped = CatConfig.STARTER
	progress.finish_run(StoryConfig.REUNION_STEPS, 0.0, RunFeats.new())
	expect(progress.reunion_reached(), "enough distance finishes the walk")
	expect(progress.steps_remaining() == 0, "and nothing is left to walk")

	# The distance survives a save, or a player loses their whole journey.
	var config := ConfigFile.new()
	progress.seen_intro = true
	progress.seen_ending = true
	progress.save_to(config)
	var restored := Progress.new()
	restored.load_from(config)
	expect(restored.tori_steps == progress.tori_steps, "the distance survives a save")
	expect(restored.seen_intro and restored.seen_ending, "so does having seen the scenes")

	# A save from before the rename still opens with Tori and her record.
	var legacy := ConfigFile.new()
	legacy.set_value(Progress.SECTION, "owned", PackedStringArray([CatConfig.STARTER_LEGACY_ID]))
	legacy.set_value(Progress.SECTION, "equipped", CatConfig.STARTER_LEGACY_ID)
	legacy.set_value(Progress.SECTION, "bests", {CatConfig.STARTER_LEGACY_ID: 321})
	var migrated := Progress.new()
	migrated.load_from(legacy)
	expect(migrated.equipped == CatConfig.STARTER, "an old save still equips the starting cat")
	expect(int(migrated.bests.get(CatConfig.STARTER, 0)) == 321, "and keeps its record")


## Every string the player can see is a key with a row in every locale, and every
## format string survives being fed its arguments.
## The epilogue is the rare half of the split in STORY.md section 1. It reuses a
## threshold the game already has rather than inventing one, and this is what
## keeps that true.
func _test_epilogue() -> void:
	expect(StoryConfig.EPILOGUE_SCORE == 1000, "the epilogue sits at 1000")
	expect(int(ZoneConfig.ZONES[ZoneConfig.ZONES.size() - 1].score) == StoryConfig.EPILOGUE_SCORE,
		"which is where the last sky opens")
	var beyond := CatConfig.by_id("beyond")
	expect(int(beyond.unlock) == CatConfig.Unlock.SCORE
		and int(beyond.value) == StoryConfig.EPILOGUE_SCORE,
		"and where the codex's last cat opens")
	expect(StoryConfig.EPILOGUE_LEAD > 0, "the figure walks ahead, never beside")

	var progress := Progress.new()
	expect(not progress.seen_epilogue, "it starts unseen")
	progress.seen_epilogue = true
	var config := ConfigFile.new()
	progress.save_to(config)
	var restored := Progress.new()
	restored.load_from(config)
	expect(restored.seen_epilogue, "and having seen it survives a save")


## Every cut scene frame names a caption key that exists and a sky that does.
func _test_story_frames() -> void:
	expect(StoryConfig.INTRO.size() > 0 and StoryConfig.ENDING.size() > 0, "both sequences exist")
	# Every frame that names a still has one. The memorial names none: it is
	# drawn live from the save file, so there is nothing to bake.
	var stills := 0
	for frame: Dictionary in StoryConfig.INTRO + StoryConfig.ENDING:
		if not String(frame.get("image", "")).is_empty():
			stills += 1
	expect(StoryArt.FRAMES.size() == stills, "the placeholder art covers every still")
	for frame: Dictionary in StoryConfig.INTRO + StoryConfig.ENDING:
		var sky := int(frame.get("sky", 0))
		expect(sky >= 0 and sky < ZoneConfig.ZONES.size(),
			"%s names a real sky" % String(frame.text))
		# A frame with no art still plays; one pointing at art that is not there
		# is a typo, and this is where it shows up.
		var image := String(frame.get("image", ""))
		expect(image.is_empty() or ResourceLoader.exists(image),
			"%s points at art that exists: %s" % [String(frame.text), image])


## The memorial counts what the player and this cat actually did, and it is the
## last frame of the ending — so it is also what unlocks the codex.
func _test_memorial() -> void:
	var memorial: Dictionary = StoryConfig.ENDING[StoryConfig.ENDING.size() - 1]
	expect(bool(memorial.get("memorial", false)), "the ending finishes on the memorial")
	expect(bool(memorial.get("hold", false)), "and waits there instead of timing out")
	expect(StoryConfig.MEMORIAL_DATE == "2019. 09. 21.", "the date is the date")

	var progress := Progress.new()
	expect(progress.total_steps == 0 and progress.total_falls == 0, "the counters start empty")
	progress.finish_run(37, 0.0, RunFeats.new())
	progress.finish_run(12, 0.0, RunFeats.new())
	expect(progress.total_steps == 49, "every landing by any cat counts toward the total")
	expect(progress.total_falls == 2, "so does every run that ended")
	expect(progress.days_played == 1, "two runs on one day are one day together")
	progress.last_day = "1999-01-01"
	progress.mark_today()
	expect(progress.days_played == 2, "a new day counts once")
	progress.mark_today()
	expect(progress.days_played == 2, "and only once")

	var config := ConfigFile.new()
	progress.save_to(config)
	var restored := Progress.new()
	restored.load_from(config)
	expect(restored.total_steps == 49 and restored.total_falls == 2
		and restored.days_played == 2, "the memorial numbers survive a save")

	# The screen reads them without a save file too, because a replayed ending
	# is drawn from whatever the player has now.
	var screen := StoryScreen.new()
	screen.progress = restored
	var stats: Array = screen.call("_memorial_stats")
	expect(stats.size() == 4, "the card carries four numbers")
	var values := PackedStringArray()
	for row: Array in stats:
		expect(not String(row[0]).is_empty(), "each number is labelled")
		values.append(String(row[1]))
	expect(values[0] == "49" and values[1] == "2", "and they are this player's numbers")
	screen.free()


func _test_every_locale_is_complete() -> void:
	var cats := CatConfig.all()
	for locale: String in I18n.LOCALES:
		I18n.use(locale)
		expect(TranslationServer.get_locale() == locale, "locale %s loads" % locale)
		for cat in cats:
			var name := CatConfig.display_name(cat)
			expect(not name.is_empty() and name != String(cat.name),
				"%s has a name in %s, got %s" % [String(cat.code), locale, name])
			expect(not CatConfig.condition_label(cat).is_empty(),
				"%s has a badge in %s" % [String(cat.code), locale])
			expect(not CatConfig.condition_text(cat).is_empty(),
				"%s has a condition in %s" % [String(cat.code), locale])
		for zone in ZoneConfig.ZONES:
			var line := I18n.t(String(zone.share_line))
			expect(line != String(zone.share_line), "%s has a share line in %s" % [String(zone.name), locale])
		for key: String in ["TITLE", "SUBTITLE", "RUN_ENDED",
				"HOME", "RETRY", "SHARE", "CODEX", "TAP_TO_SEE", "MEMORIAL_REPLAY",
				"TUTORIAL_WAIT", "TUTORIAL_TAP", "TUTORIAL_AGAIN", "TUTORIAL_TAP_SUB",
				"TUTORIAL_GO",
				"TAP_TO_CLOSE", "LOCKED_SLOTS", "SECTION_LEVEL", "SECTION_SKY",
				"SECTION_FEAT", "SECTION_WITNESS", "SHARE_CLIPBOARD", "STORY_SKIP",
				"STORY_INTRO_REPLAY", "STORY_ENDING_REPLAY", "STORY_ARRIVED",
				"TAP_TO_START", "MEMORIAL_NAME", "MEMORIAL_LINE_1", "MEMORIAL_LINE_2",
				"MEMORIAL_STEPS", "MEMORIAL_FALLS", "MEMORIAL_DAYS", "MEMORIAL_BEST",
				"CODEX_LOCKED", "CODEX_OPENED"]:
			expect(I18n.t(key) != key, "%s is translated in %s" % [key, locale])
		# A translator writing % instead of %% would crash the game here.
		expect(not (I18n.t("CODEX_COUNT") % [1, 24, 3]).is_empty(), "CODEX_COUNT formats in %s" % locale)
		expect(not (I18n.t("NEW_CAT") % "x").is_empty(), "NEW_CAT formats in %s" % locale)
		expect(not (I18n.t("SHARE_RUN") % [1, "x"]).is_empty(), "SHARE_RUN formats in %s" % locale)
		expect(not (I18n.t("SHARE_CAT") % ["x", "y"]).is_empty(), "SHARE_CAT formats in %s" % locale)
		expect(not (I18n.t("STORY_DISTANCE") % 12).is_empty(), "STORY_DISTANCE formats in %s" % locale)
		for frame: Dictionary in StoryConfig.INTRO + StoryConfig.ENDING:
			expect(I18n.t(String(frame.text)) != String(frame.text),
				"%s is written in %s" % [String(frame.text), locale])
	I18n.use("en")


## Every character the game can draw has a glyph in the fonts that ship.
##
## The subsets are built from the translation table by `tools/build_fonts.py`,
## which is a build step — so adding a string and forgetting to run it leaves
## tofu boxes on a player's screen and nothing else notices. That has now
## happened twice. It is a test failure from here on.
func _test_every_character_has_a_glyph() -> void:
	var font := CssText.font()
	expect(font != null, "the UI font loads")
	if font == null:
		return
	var table := ConfigFile.new()
	var missing := {}
	for locale: String in I18n.LOCALES:
		I18n.use(locale)
		var strings: Array[String] = []
		for cat in CatConfig.all():
			strings.append(CatConfig.display_name(cat))
			strings.append(CatConfig.condition_label(cat))
			strings.append(CatConfig.condition_text(cat))
		for zone in ZoneConfig.ZONES:
			strings.append(I18n.t(String(zone.share_line)))
			strings.append(String(zone.name))
		for frame: Dictionary in StoryConfig.INTRO + StoryConfig.ENDING:
			strings.append(I18n.t(String(frame.text)))
		for key: String in ["TITLE", "SUBTITLE", "RUN_ENDED", "TAP_TO_START", "HOME",
				"MEMORIAL_REPLAY", "TUTORIAL_WAIT", "TUTORIAL_TAP", "TUTORIAL_AGAIN",
				"TUTORIAL_TAP_SUB", "TUTORIAL_GO",
				"RETRY", "SHARE", "CODEX", "CODEX_COUNT", "NEW_CAT", "NEW_CATS",
				"TAP_TO_SEE", "TAP_TO_CLOSE", "NEXT_MORE", "LOCKED_SLOTS", "BEST_WITH",
				"SECTION_LEVEL", "SECTION_LEVEL_NOTE", "SECTION_SKY", "SECTION_SKY_NOTE",
				"SECTION_FEAT", "SECTION_FEAT_NOTE", "SECTION_WITNESS", "SECTION_WITNESS_NOTE",
				"SHARE_CLIPBOARD", "SHARE_UNSUPPORTED", "SHARE_CANCELLED", "SHARE_RUN",
				"SHARE_CAT", "STORY_SKIP", "STORY_DISTANCE", "STORY_ARRIVED", "STORY_WALKED",
				"STORY_INTRO_REPLAY", "STORY_ENDING_REPLAY", "MEMORIAL_NAME",
				"MEMORIAL_LINE_1", "MEMORIAL_LINE_2", "MEMORIAL_STEPS", "MEMORIAL_FALLS",
				"MEMORIAL_DAYS", "MEMORIAL_BEST", "CODEX_LOCKED", "CODEX_OPENED"]:
			strings.append(I18n.t(key))
		strings.append(StoryConfig.MEMORIAL_DATE)
		for text: String in strings:
			for i in text.length():
				var code := text.unicode_at(i)
				# Format placeholders and newlines never reach a glyph lookup.
				if code <= 32 or char(code) == "%":
					continue
				if not font.has_char(code):
					missing[char(code)] = locale
	I18n.use("en")
	var report := ""
	for character: String in missing:
		report += "%s(%s) " % [character, missing[character]]
	expect(missing.is_empty(),
		"every character the UI draws has a glyph — run tools/build_fonts.py. Missing: " + report)


func _test_roster_is_well_formed() -> void:
	var cats := CatConfig.all()
	expect(cats.size() == 24, "the codex has 24 slots")
	var ids := {}
	var counts := {}
	for cat in cats:
		var id := String(cat.id)
		expect(not ids.has(id), "id %s is unique" % id)
		ids[id] = true
		expect(not String(cat.name).is_empty(), "%s has a name" % id)
		expect(not String(cat.code).is_empty(), "%s has a code" % id)
		expect(not CatConfig.condition_label(cat).is_empty(), "%s has a badge" % id)
		expect(not CatConfig.condition_text(cat).is_empty(), "%s has a condition" % id)
		expect(CatConfig.by_id(id).id == id, "%s is findable by id" % id)
		# Cosmetic only: nothing in a cat may reach the rules.
		for key: String in ["value", "unlock"]:
			expect(cat.has(key), "%s declares %s" % [id, key])
		counts[int(cat.unlock)] = int(counts.get(int(cat.unlock), 0)) + 1
	expect(counts.get(CatConfig.Unlock.LEVEL, 0) == 12, "12 cats open on level")
	expect(counts.get(CatConfig.Unlock.SCORE, 0) == 7, "7 open on a run's score")
	expect(counts.get(CatConfig.Unlock.FEAT, 0) == 4, "4 open on a feat")
	expect(counts.get(CatConfig.Unlock.WITNESS, 0) == 1, "1 opens on witnessing")
	expect(CatConfig.by_id("nope").id == CatConfig.STARTER, "an unknown id falls back to the starter")
