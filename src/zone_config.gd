class_name ZoneConfig
extends RefCounted

const ZONES := [
	{"score": 0, "name": "BLUE SKY", "top": Color("79beff"), "bottom": Color("eaf7ff")},
	{"score": 30, "name": "GOLDEN WIND", "top": Color("67b7ff"), "bottom": Color("ffdca0")},
	{"score": 60, "name": "SUNSET RUN", "top": Color("7287dd"), "bottom": Color("ff9a78")},
	{"score": 100, "name": "NIGHT BREAK", "top": Color("172b66"), "bottom": Color("745b9e")},
	{"score": 150, "name": "STAR RUSH", "top": Color("071633"), "bottom": Color("244d79")},
	{"score": 210, "name": "AURORA EDGE", "top": Color("07182b"), "bottom": Color("174d56")},
	{"score": 300, "name": "RED STRATOS", "top": Color("250915"), "bottom": Color("8f2b36")},
	{"score": 400, "name": "VOID CURRENT", "top": Color("030611"), "bottom": Color("171c3f")},
	{"score": 550, "name": "CHROMA STORM", "top": Color("140521"), "bottom": Color("27506f")},
	{"score": 750, "name": "WHITE HORIZON", "top": Color("d7e5ef"), "bottom": Color("ffffff")},
	{"score": 1000, "name": "BEYOND", "top": Color("020204"), "bottom": Color("111318")},
]

static func for_score(score: int) -> Dictionary:
	var selected: Dictionary = ZONES[0]
	for zone: Dictionary in ZONES:
		if score < int(zone.score):
			break
		selected = zone
	return selected

