class_name CatConfig
extends RefCounted

## The 24 cats and how each one opens. Static data, shaped like [ZoneConfig].
##
## A cat is a parameter set, never a sprite: every field below feeds
## [method Art.draw_cat], which builds the animal from primitives. See
## PROGRESSION.md sections 4 and 5.
##
## Cats are PURELY cosmetic. Nothing here may reach judgement, cadence, score
## or death.

enum Unlock {
	## Reached a level. `value` is the level.
	LEVEL,
	## Reached a score in ONE run. `value` is the score.
	SCORE,
	## A feat inside one run, or across consecutive runs. `value` is the
	## threshold and `feat` names the tally in [RunFeats].
	FEAT,
	## Saw other players' cats on shared cards. `value` is how many.
	WITNESS,
}

const FUR := Color("ef6a5b")
const FUR_DARK := Color("cf5347")
const PAW := Color("ffeee7")
const INNER_EAR := Color("ff9d8e")

## The starting cat: owned from the first run, never unlocked. This is Tori,
## the cat the whole story is about — see STORY.md.
const STARTER := "tori"
## What `STARTER` used to be called, so a save written before the rename still
## opens with the right cat equipped.
const STARTER_LEGACY_ID := "half_step"

## Every field except `id`, `name`, `code`, `unlock` and `value` has a default
## in [method normalise], so an entry only states what makes it different.
const CATS: Array[Dictionary] = [
	# --- level, 12 -----------------------------------------------------------
	{
		"id": "tori", "name": "CAT_TORI", "code": "TORI",
		"unlock": Unlock.LEVEL, "value": 1, "sky": 0,
	},
	{
		"id": "milk", "name": "CAT_MILK", "code": "MILK",
		"unlock": Unlock.LEVEL, "value": 2, "sky": 0,
		"fur": Color("fdfbf7"), "fur_dark": Color("e6ded2"), "paw": Color("fff7f0"),
		"inner_ear": Color("ffb9c4"), "pattern": "solid", "build": "slim",
	},
	{
		"id": "soot", "name": "CAT_SOOT", "code": "SOOT",
		"unlock": Unlock.LEVEL, "value": 3, "sky": 0,
		"fur": Color("7a8794"), "fur_dark": Color("59646f"), "paw": Color("dfe6ec"),
		"inner_ear": Color("c9a5a0"),
	},
	{
		"id": "butter", "name": "CAT_BUTTER", "code": "BUTTER",
		"unlock": Unlock.LEVEL, "value": 4, "sky": 1,
		"fur": Color("f2c572"), "fur_dark": Color("cf9a3c"), "paw": Color("fff4dc"),
		"inner_ear": Color("ffb99c"), "pattern": "spotted", "tail": "plume", "build": "chonk",
	},
	{
		"id": "tuxedo", "name": "CAT_TUXEDO", "code": "TUXEDO",
		"unlock": Unlock.LEVEL, "value": 5, "sky": 1,
		"fur": Color("2b3240"), "fur_dark": Color("1a1f29"), "paw": Color("fdfdfd"),
		"inner_ear": Color("e8a0a0"), "pattern": "tuxedo",
	},
	{
		"id": "calico", "name": "CAT_CALICO", "code": "CALICO",
		"unlock": Unlock.LEVEL, "value": 7, "sky": 1,
		"fur": Color("fdf6ee"), "fur_dark": Color("3a3129"), "paw": Color("ffffff"),
		"inner_ear": Color("ffb0b0"), "pattern": "calico",
		"patch_a": Color("e8873f"), "patch_b": Color("3a3129"),
	},
	{
		"id": "ember", "name": "CAT_EMBER", "code": "EMBER",
		"unlock": Unlock.LEVEL, "value": 9, "sky": 2,
		"fur": Color("ff8a5c"), "fur_dark": Color("d75f3a"), "paw": Color("ffe4d2"),
		"ears": "tufted", "tail": "plume", "build": "chonk",
	},
	{
		"id": "midnight", "name": "CAT_MIDNIGHT", "code": "MIDNIGHT",
		"unlock": Unlock.LEVEL, "value": 12, "sky": 3,
		"fur": Color("1b1f2e"), "fur_dark": Color("12151f"), "paw": Color("6b7280"),
		"inner_ear": Color("4b3f8a"), "pattern": "solid", "ears": "folded",
	},
	{
		"id": "nimbus", "name": "CAT_NIMBUS", "code": "NIMBUS",
		"unlock": Unlock.LEVEL, "value": 16, "sky": 2,
		"fur": Color("f6f9fc"), "fur_dark": Color("c3d0dc"), "paw": Color("ffffff"),
		"inner_ear": Color("f0c2c2"), "pattern": "van", "tail": "plume", "build": "chonk",
	},
	{
		"id": "rain", "name": "CAT_RAIN", "code": "RAIN",
		"unlock": Unlock.LEVEL, "value": 20, "sky": 3,
		"fur": Color("5b6b7d"), "fur_dark": Color("3f4c5a"), "paw": Color("cdd7e0"),
		"inner_ear": Color("b98f8f"), "pattern": "spotted", "tail": "bob", "build": "slim",
	},
	{
		"id": "frost", "name": "CAT_FROST", "code": "FROST",
		"unlock": Unlock.LEVEL, "value": 25, "sky": 4,
		"fur": Color("f5efe4"), "fur_dark": Color("4a5f7d"), "paw": Color("ffffff"),
		"inner_ear": Color("d9b8c6"), "pattern": "point", "build": "slim",
	},
	{
		"id": "galaxy", "name": "CAT_GALAXY", "code": "GALAXY",
		"unlock": Unlock.LEVEL, "value": 30, "sky": 4,
		"fur": Color("2a2352"), "fur_dark": Color("a99bf0"), "paw": Color("e7dcff"),
		"inner_ear": Color("7f68ff"), "pattern": "spotted", "tail": "plume",
	},

	# --- sky, 7 --------------------------------------------------------------
	{
		"id": "silence", "name": "CAT_SILENCE", "code": "SILENCE",
		"unlock": Unlock.SCORE, "value": 100, "sky": 3,
		"fur": Color("0d0f14"), "fur_dark": Color("0d0f14"), "paw": Color("f2f2f2"),
		"inner_ear": Color("2a2f3a"), "pattern": "solid", "ears": "curl", "marks": false,
	},
	{
		"id": "aurora", "name": "CAT_AURORA", "code": "AURORA",
		"unlock": Unlock.SCORE, "value": 210, "sky": 5,
		"fur": Color("55ffc1"), "fur_dark": Color("7f68ff"), "paw": Color("e9fff7"),
		"inner_ear": Color("9fffe0"), "pattern": "bicolor", "ears": "curl", "build": "slim",
		"aura": Color("55ffc1"),
	},
	{
		"id": "cinder", "name": "CAT_CINDER", "code": "CINDER",
		"unlock": Unlock.SCORE, "value": 300, "sky": 6,
		"fur": Color("8f2b36"), "fur_dark": Color("4a1119"), "paw": Color("ff9d7e"),
		"inner_ear": Color("ff714e"), "tail": "kinked",
	},
	{
		"id": "void", "name": "CAT_VOID", "code": "VOID",
		"unlock": Unlock.SCORE, "value": 400, "sky": 7,
		"fur": Color("2b3468"), "fur_dark": Color("141a3a"), "paw": Color("5849ff"),
		"inner_ear": Color("3a3f7f"), "pattern": "solid", "alpha": 0.8,
	},
	{
		"id": "chroma", "name": "CAT_CHROMA", "code": "CHROMA",
		"unlock": Unlock.SCORE, "value": 550, "sky": 8,
		"fur": Color("ff46b7"), "fur_dark": Color("4bffe4"), "paw": Color("fff0fa"),
		"inner_ear": Color("ff8fd6"), "pattern": "bicolor", "ears": "curl", "tail": "plume",
		"aura": Color("ff46b7"),
	},
	{
		"id": "horizon", "name": "CAT_HORIZON", "code": "HORIZON",
		"unlock": Unlock.SCORE, "value": 750, "sky": 9,
		"fur": Color("ffffff"), "fur_dark": Color("ffffff"), "paw": Color("ffffff"),
		"inner_ear": Color("ffe8e8"), "pattern": "solid", "tail": "plume", "build": "chonk",
		"marks": false, "aura": Color("ffffff"),
	},
	{
		"id": "beyond", "name": "CAT_BEYOND", "code": "BEYOND",
		"unlock": Unlock.SCORE, "value": 1000, "sky": 10,
		"pattern": "hole", "marks": false, "inner": false, "whiskers": false, "paws": false,
	},

	# --- feat, 4 -------------------------------------------------------------
	# Thresholds are estimates made before the tap-as-jump build was played.
	# PROGRESSION.md section 9 lists them as the first thing to retune.
	{
		"id": "meridian", "name": "CAT_MERIDIAN", "code": "MERIDIAN",
		"unlock": Unlock.FEAT, "feat": "crossings", "value": 40, "sky": 7,
		"fur": Color("cfc7ff"), "fur_dark": Color("5849ff"), "paw": Color("ffffff"),
		"inner_ear": Color("8f86ff"), "pattern": "van", "ears": "tufted", "tail": "plume",
		"build": "chonk", "aura": Color("5849ff"),
	},
	{
		"id": "obsidian", "name": "CAT_OBSIDIAN", "code": "OBSIDIAN",
		"unlock": Unlock.FEAT, "feat": "first_run_score", "value": 100, "sky": 3,
		"fur": Color("12141c"), "fur_dark": Color("030611"), "paw": Color("5849ff"),
		"inner_ear": Color("2a2f6a"), "pattern": "solid", "ears": "folded", "build": "slim",
		"aura": Color("5849ff"),
	},
	{
		"id": "polar", "name": "CAT_POLAR", "code": "POLAR",
		"unlock": Unlock.FEAT, "feat": "runs_over_sixty", "value": 3, "sky": 4,
		"fur": Color("ffffff"), "fur_dark": Color("d5e2ee"), "paw": Color("ffffff"),
		"inner_ear": Color("f0c2c2"), "ears": "tufted", "tail": "plume", "build": "chonk",
	},
	{
		"id": "last_step", "name": "CAT_LAST_STEP", "code": "LAST-STEP",
		"unlock": Unlock.FEAT, "feat": "early_jump_streak", "value": 30, "sky": 0,
		"pattern": "window", "marks": false, "inner": false, "whiskers": false,
		"paw": Color("ffffff"),
	},

	# --- witness, 1 ----------------------------------------------------------
	{
		"id": "nameless", "name": "CAT_NAMELESS", "code": "NAMELESS",
		"unlock": Unlock.WITNESS, "value": 5, "sky": 10,
		"fur": Color("000000"), "fur_dark": Color("000000"), "paw": Color("000000"),
		"pattern": "solid", "tail": "bob", "build": "slim",
		"marks": false, "inner": false, "whiskers": false, "paws": false,
	},
]

const DEFAULTS := {
	"fur": FUR, "fur_dark": FUR_DARK, "paw": PAW, "inner_ear": INNER_EAR,
	"pattern": "tabby", "ears": "pricked", "tail": "long", "build": "standard",
	"marks": true, "inner": true, "whiskers": true, "paws": true,
	"alpha": 1.0, "aura": Color(0.0, 0.0, 0.0, 0.0),
	"patch_a": FUR, "patch_b": FUR_DARK, "feat": "",
}

static var _by_id: Dictionary = {}


## Fills in every field an entry left out, so drawing code can read any key.
static func normalise(cat: Dictionary) -> Dictionary:
	var full := DEFAULTS.duplicate()
	full.merge(cat, true)
	return full


static func all() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for cat in CATS:
		out.append(normalise(cat))
	return out


static func by_id(id: String) -> Dictionary:
	if _by_id.is_empty():
		for cat in CATS:
			_by_id[String(cat.id)] = normalise(cat)
	return _by_id.get(id, _by_id[STARTER])


## The cat's name in the player's language. `cat.name` is a translation key.
static func display_name(cat: Dictionary) -> String:
	return I18n.t(String(cat.name))


static func has(id: String) -> bool:
	by_id(STARTER)
	return _by_id.has(id)


static func ids() -> PackedStringArray:
	var out := PackedStringArray()
	for cat in CATS:
		out.append(String(cat.id))
	return out


## The sky a codex card is drawn on, and the zone name an acquisition card
## prints for a sky cat.
static func zone_of(cat: Dictionary) -> Dictionary:
	return ZoneConfig.ZONES[clampi(int(cat.get("sky", 0)), 0, ZoneConfig.ZONES.size() - 1)]


## Translation key for how a cat opens. [param suffix] picks the short badge
## (empty) or the full sentence ("_FULL").
static func _condition_key(cat: Dictionary, suffix: String) -> String:
	match int(cat.unlock):
		Unlock.LEVEL:
			return "COND_LEVEL" + suffix
		Unlock.SCORE:
			return "COND_SCORE" + suffix
		Unlock.WITNESS:
			return "COND_WITNESS" + suffix
	match String(cat.get("feat", "")):
		"crossings":
			return "COND_CROSSINGS" + suffix
		"first_run_score":
			return "COND_FIRST_RUN" + suffix
		"runs_over_sixty":
			return "COND_STEADY" + suffix
		_:
			return "COND_EARLY" + suffix


## Short label for how a cat opens — the badge on a codex card.
static func condition_label(cat: Dictionary) -> String:
	return I18n.t(_condition_key(cat, "")) % int(cat.value)


## The full sentence, shown on an acquisition card and in the codex.
static func condition_text(cat: Dictionary) -> String:
	if int(cat.unlock) == Unlock.SCORE:
		return I18n.t("COND_SCORE_FULL") % [int(cat.value), String(zone_of(cat).name)]
	return I18n.t(_condition_key(cat, "_FULL")) % int(cat.value)
