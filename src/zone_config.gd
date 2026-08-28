class_name ZoneConfig
extends RefCounted

## `share_line` is a translation key, not text — see `assets/i18n/half_step.csv`.
## Zone NAMES stay English on purpose: they are stylised proper nouns and part of
## the visual identity, like the milestone tags.
##
## Sky zone table, ported verbatim from the `zones` array in
## `reference/web-prototypes/half_step_pixel_skin.html`.
##
## `atmo` replaces the prototype's CSS gradient string with the same gradient
## expressed as data so it can be rasterised in `_draw`. A stop whose alpha is
## zero stands for the CSS `transparent` keyword and borrows the RGB of the
## neighbouring stop, matching premultiplied gradient interpolation in browsers.

const NO_ATMOSPHERE := {"kind": "none"}
const TRANSPARENT := Color(0.0, 0.0, 0.0, 0.0)

const ZONES: Array[Dictionary] = [
	{
		"score": 0, "name": "BLUE SKY", "top": Color("79beff"), "bottom": Color("eaf7ff"),
		"stars": 0.0, "scan": 0.0, "boost": 1.0, "share_line": "ZONE_LINE_0",
		"atmo": {"kind": "none"},
	},
	{
		"score": 30, "name": "GOLDEN WIND", "top": Color("67b7ff"), "bottom": Color("ffdca0"),
		"stars": 0.0, "scan": 0.0, "boost": 1.10, "share_line": "ZONE_LINE_1",
		"atmo": {"kind": "linear", "angle": 180.0, "stops": [
			[0.45, Color(0.0, 0.0, 0.0, 0.0)], [1.0, Color("ffbe56", 0.20)],
		]},
	},
	{
		"score": 60, "name": "SUNSET RUN", "top": Color("7287dd"), "bottom": Color("ff9a78"),
		"stars": 0.0, "scan": 0.0, "boost": 1.22, "share_line": "ZONE_LINE_2",
		"atmo": {"kind": "linear", "angle": 180.0, "stops": [
			[0.0, Color("5449a4", 0.10)], [1.0, Color("ff765e", 0.22)],
		]},
	},
	{
		"score": 100, "name": "NIGHT BREAK", "top": Color("172b66"), "bottom": Color("745b9e"),
		"stars": 0.48, "scan": 0.0, "boost": 1.38, "share_line": "ZONE_LINE_3",
		"atmo": {"kind": "linear", "angle": 180.0, "stops": [
			[0.0, Color("071137", 0.25)], [1.0, Color("75529b", 0.18)],
		]},
	},
	{
		"score": 150, "name": "STAR RUSH", "top": Color("071633"), "bottom": Color("244d79"),
		"stars": 0.92, "scan": 0.0, "boost": 1.58, "share_line": "ZONE_LINE_4",
		"atmo": {"kind": "radial", "center": Vector2(0.5, 0.25), "stops": [
			[0.0, Color("53aeff", 0.18)], [0.36, Color(0.0, 0.0, 0.0, 0.0)],
		]},
	},
	{
		"score": 210, "name": "AURORA EDGE", "top": Color("07182b"), "bottom": Color("174d56"),
		"stars": 1.0, "scan": 0.0, "boost": 1.85, "share_line": "ZONE_LINE_5",
		"atmo": {"kind": "linear", "angle": 115.0, "stops": [
			[0.20, Color(0.0, 0.0, 0.0, 0.0)], [0.42, Color("55ffc1", 0.18)],
			[0.58, Color("7f68ff", 0.18)], [0.78, Color(0.0, 0.0, 0.0, 0.0)],
		]},
	},
	{
		"score": 300, "name": "RED STRATOS", "top": Color("250915"), "bottom": Color("8f2b36"),
		"stars": 0.72, "scan": 0.12, "boost": 2.10, "share_line": "ZONE_LINE_6",
		"atmo": {"kind": "radial", "center": Vector2(0.5, 0.22), "stops": [
			[0.0, Color("ff714e", 0.26)], [0.42, Color(0.0, 0.0, 0.0, 0.0)],
		]},
	},
	{
		"score": 400, "name": "VOID CURRENT", "top": Color("030611"), "bottom": Color("171c3f"),
		"stars": 1.0, "scan": 0.20, "boost": 2.38, "share_line": "ZONE_LINE_7",
		"atmo": {"kind": "radial", "center": Vector2(0.5, 0.40), "stops": [
			[0.0, Color("5849ff", 0.22)], [0.44, Color(0.0, 0.0, 0.0, 0.0)],
		]},
	},
	{
		"score": 550, "name": "CHROMA STORM", "top": Color("140521"), "bottom": Color("27506f"),
		"stars": 1.0, "scan": 0.28, "boost": 2.72, "share_line": "ZONE_LINE_8",
		"atmo": {"kind": "linear", "angle": 125.0, "stops": [
			[0.0, Color("ff46b7", 0.18)], [0.35, Color(0.0, 0.0, 0.0, 0.0)],
			[0.62, Color("4bffe4", 0.18)], [0.82, Color(0.0, 0.0, 0.0, 0.0)],
		]},
	},
	{
		"score": 750, "name": "WHITE HORIZON", "top": Color("d7e5ef"), "bottom": Color("ffffff"),
		"stars": 0.24, "scan": 0.08, "boost": 3.10, "share_line": "ZONE_LINE_9",
		"atmo": {"kind": "radial", "center": Vector2(0.5, 0.35), "stops": [
			[0.0, Color("ffffff", 0.85)], [0.40, Color(0.0, 0.0, 0.0, 0.0)],
		]},
	},
	{
		"score": 1000, "name": "BEYOND", "top": Color("020204"), "bottom": Color("111318"),
		"stars": 1.0, "scan": 0.36, "boost": 3.55, "share_line": "ZONE_LINE_10",
		"atmo": {"kind": "radial", "center": Vector2(0.5, 0.30), "stops": [
			[0.0, Color("ffffff", 0.11)], [0.32, Color(0.0, 0.0, 0.0, 0.0)],
		]},
	},
]

## Secret milestone text flashed exactly on these scores (`secretFlash`).
const MILESTONES := {
	300: "YOU SHOULD NOT BE HERE",
	400: "THE SKY IS GONE",
	550: "KEEP GOING",
	750: "NO ONE WAS SUPPOSED TO SEE THIS",
	1000: "BEYOND",
}


static func index_for_score(score: int) -> int:
	var selected := 0
	for i in ZONES.size():
		if score >= int(ZONES[i].score):
			selected = i
	return selected


static func for_score(score: int) -> Dictionary:
	return ZONES[index_for_score(score)]


static func milestone_for_score(score: int) -> String:
	return String(MILESTONES.get(score, ""))


## `getMilestoneTag` from the prototype's share card.
static func milestone_tag_for_score(score: int) -> String:
	if score >= 1000:
		return "NO ONE WAS SUPPOSED TO SEE THIS"
	if score >= 750:
		return "WHITE HORIZON REACHED"
	if score >= 550:
		return "THE SKY CHANGED"
	if score >= 400:
		return "THE SKY IS GONE"
	if score >= 300:
		return "YOU SHOULD NOT BE HERE"
	if score >= 150:
		return "KEEP CLIMBING"
	return "CAN YOU REACH THIS SKY?"
