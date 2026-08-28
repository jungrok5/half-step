class_name Progress
extends RefCounted

## Experience, level, the codex, and what carries between runs.
##
## Persisted into the same `user://half_step.cfg` the best score already uses,
## under its own section. See PROGRESSION.md sections 2, 3 and 7.

const SECTION := "progress"

## Cost of each level-up, 1→2 first. Requirement multiplies by 1.24 through
## Lv 9, 1.27 to 19, 1.30 to 29, 1.33 to 39 and 1.36 above, from a base of 40,
## each result rounded to two significant figures — ten levels costs roughly ten
## times the previous ten, which is the shape this curve exists to have.
const LEVEL_STEPS: PackedInt64Array = [
	40, 50, 62, 76, 95, 120, 150, 180, 220, 280,
	350, 450, 570, 720, 920, 1200, 1500, 1900, 2400, 3000,
	3900, 5100, 6600, 8600, 11000, 15000, 19000, 25000, 32000, 42000,
	55000, 74000, 98000, 130000, 170000, 230000, 310000, 410000, 540000, 720000,
	980000, 1300000, 1800000, 2500000, 3400000, 4600000, 6200000, 8500000, 11000000,
]
const MAX_LEVEL := 50

## Runs at or above this score feed the consecutive-runs feat.
const STEADY_SCORE := 60

var experience := 0.0
## Cat ids the player owns, and the ids seen on other players' cards.
var owned: Dictionary = {}
var witnessed: Dictionary = {}
## Best score reached while each cat was equipped, by id.
var bests: Dictionary = {}
var equipped := CatConfig.STARTER

## Consecutive runs scoring at least [constant STEADY_SCORE].
var steady_streak := 0
## Cleared on load: the "first run after launch" feat only counts once.
var runs_this_session := 0

static var _thresholds: PackedFloat64Array = PackedFloat64Array()


func _init() -> void:
	owned[CatConfig.STARTER] = true


## Total experience needed to be at [param level]. Level 1 is free.
static func threshold(level: int) -> float:
	if _thresholds.is_empty():
		_thresholds.append(0.0)
		_thresholds.append(0.0)
		var total := 0.0
		for step in LEVEL_STEPS:
			total += float(step)
			_thresholds.append(total)
	return _thresholds[clampi(level, 1, MAX_LEVEL)]


static func level_for(value: float) -> int:
	var level := 1
	while level < MAX_LEVEL and value >= threshold(level + 1):
		level += 1
	return level


func level() -> int:
	return level_for(experience)


## How far through the current level, 0 to 1. Flat 1 at the cap.
func level_fraction() -> float:
	var current := level()
	if current >= MAX_LEVEL:
		return 1.0
	var floor_exp := threshold(current)
	var span := threshold(current + 1) - floor_exp
	if span <= 0.0:
		return 1.0
	return clampf((experience - floor_exp) / span, 0.0, 1.0)


func experience_to_next() -> float:
	var current := level()
	if current >= MAX_LEVEL:
		return 0.0
	return maxf(0.0, threshold(current + 1) - experience)


func owns(id: String) -> bool:
	return bool(owned.get(id, false))


func has_witnessed(id: String) -> bool:
	return bool(witnessed.get(id, false))


func owned_count() -> int:
	return owned.size()


## Records a cat seen on someone else's shared card. Returns the ids this
## opened — witnessing is itself an unlock condition.
func witness(id: String) -> Array[String]:
	if not CatConfig.has(id) or owns(id) or has_witnessed(id):
		return []
	witnessed[id] = true
	return _claim_unlocked(0, null)


## Folds one finished run into the codex. Returns the ids that opened, in table
## order, so the caller can announce them.
func finish_run(score: int, gained: float, feats: RunFeats) -> Array[String]:
	experience += gained
	runs_this_session += 1
	steady_streak = steady_streak + 1 if score >= STEADY_SCORE else 0
	if score > int(bests.get(equipped, 0)):
		bests[equipped] = score
	return _claim_unlocked(score, feats)


## Everything whose condition is now met and that is not owned yet.
func _claim_unlocked(score: int, feats: RunFeats) -> Array[String]:
	var opened: Array[String] = []
	for cat in CatConfig.all():
		var id := String(cat.id)
		if owns(id):
			continue
		if not _condition_met(cat, score, feats):
			continue
		owned[id] = true
		witnessed.erase(id)
		opened.append(id)
	return opened


func _condition_met(cat: Dictionary, score: int, feats: RunFeats) -> bool:
	var value := int(cat.value)
	match int(cat.unlock):
		CatConfig.Unlock.LEVEL:
			return level() >= value
		CatConfig.Unlock.SCORE:
			return score >= value
		CatConfig.Unlock.WITNESS:
			return witnessed.size() >= value
		_:
			match String(cat.get("feat", "")):
				"crossings":
					return feats != null and feats.crossings >= value
				"early_jump_streak":
					return feats != null and feats.early_jump_streak >= value
				"first_run_score":
					# Only the first run after launch, with no warm-up.
					return feats != null and runs_this_session == 1 and score >= value
				"runs_over_sixty":
					return steady_streak >= value
				_:
					return false


# --- persistence ------------------------------------------------------------

func save_to(config: ConfigFile) -> void:
	config.set_value(SECTION, "experience", experience)
	config.set_value(SECTION, "owned", PackedStringArray(owned.keys()))
	config.set_value(SECTION, "witnessed", PackedStringArray(witnessed.keys()))
	config.set_value(SECTION, "bests", bests)
	config.set_value(SECTION, "equipped", equipped)
	config.set_value(SECTION, "steady_streak", steady_streak)


func load_from(config: ConfigFile) -> void:
	experience = maxf(0.0, float(config.get_value(SECTION, "experience", 0.0)))
	steady_streak = maxi(0, int(config.get_value(SECTION, "steady_streak", 0)))
	# A launch is what makes the "first run" feat mean anything.
	runs_this_session = 0
	owned = {CatConfig.STARTER: true}
	for id: String in PackedStringArray(config.get_value(SECTION, "owned", PackedStringArray())):
		if CatConfig.has(id):
			owned[id] = true
	witnessed = {}
	for id: String in PackedStringArray(config.get_value(SECTION, "witnessed", PackedStringArray())):
		if CatConfig.has(id) and not owns(id):
			witnessed[id] = true
	bests = {}
	for id: Variant in Dictionary(config.get_value(SECTION, "bests", {})):
		if CatConfig.has(String(id)):
			bests[String(id)] = int(Dictionary(config.get_value(SECTION, "bests", {}))[id])
	var saved := String(config.get_value(SECTION, "equipped", CatConfig.STARTER))
	equipped = saved if owns(saved) else CatConfig.STARTER
