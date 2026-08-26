class_name ZoneConfig
extends RefCounted

const ZONES := [
	{"score": 0, "name": "BLUE SKY", "top": Color("79beff"), "bottom": Color("eaf7ff"), "stars": 0.0, "scan": 0.0, "boost": 1.0, "accent": Color("ffffff")},
	{"score": 30, "name": "GOLDEN WIND", "top": Color("67b7ff"), "bottom": Color("ffdca0"), "stars": 0.0, "scan": 0.0, "boost": 1.10, "accent": Color("ffbe56")},
	{"score": 60, "name": "SUNSET RUN", "top": Color("7287dd"), "bottom": Color("ff9a78"), "stars": 0.0, "scan": 0.0, "boost": 1.22, "accent": Color("ff765e")},
	{"score": 100, "name": "NIGHT BREAK", "top": Color("172b66"), "bottom": Color("745b9e"), "stars": 0.48, "scan": 0.0, "boost": 1.38, "accent": Color("8e9cff")},
	{"score": 150, "name": "STAR RUSH", "top": Color("071633"), "bottom": Color("244d79"), "stars": 0.92, "scan": 0.0, "boost": 1.58, "accent": Color("53aeff")},
	{"score": 210, "name": "AURORA EDGE", "top": Color("07182b"), "bottom": Color("174d56"), "stars": 1.0, "scan": 0.0, "boost": 1.85, "accent": Color("55ffc1")},
	{"score": 300, "name": "RED STRATOS", "top": Color("250915"), "bottom": Color("8f2b36"), "stars": 0.72, "scan": 0.12, "boost": 2.10, "accent": Color("ff714e")},
	{"score": 400, "name": "VOID CURRENT", "top": Color("030611"), "bottom": Color("171c3f"), "stars": 1.0, "scan": 0.20, "boost": 2.38, "accent": Color("5849ff")},
	{"score": 550, "name": "CHROMA STORM", "top": Color("140521"), "bottom": Color("27506f"), "stars": 1.0, "scan": 0.28, "boost": 2.72, "accent": Color("ff46b7")},
	{"score": 750, "name": "WHITE HORIZON", "top": Color("d7e5ef"), "bottom": Color("ffffff"), "stars": 0.24, "scan": 0.08, "boost": 3.10, "accent": Color("ffffff")},
	{"score": 1000, "name": "BEYOND", "top": Color("020204"), "bottom": Color("111318"), "stars": 1.0, "scan": 0.36, "boost": 3.55, "accent": Color("ffffff")},
]

static func for_score(score: int) -> Dictionary:
	var selected: Dictionary = ZONES[0]
	for zone: Dictionary in ZONES:
		if score < int(zone.score):
			break
		selected = zone
	return selected

static func milestone_for_score(score: int) -> String:
	match score:
		300: return "YOU SHOULD NOT BE HERE"
		400: return "THE SKY IS GONE"
		550: return "KEEP GOING"
		750: return "NO ONE WAS SUPPOSED TO SEE THIS"
		1000: return "BEYOND"
	return ""
