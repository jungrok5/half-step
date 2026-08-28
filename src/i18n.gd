class_name I18n
extends RefCounted

## Translation lookup and the locale's writing system.
##
## Every player-visible string in the game is a key in
## `assets/i18n/half_step.csv`. Nothing may be a literal: the Hangul font is a
## subset built from that file, so a literal is a string with no glyphs.
##
## `Object.tr()` only exists on instances, and most of this game's text is drawn
## from static functions, so everything goes through [method t] instead.

## Locales the game ships. The first is the source language and the fallback.
const LOCALES: PackedStringArray = [
	"en", "ko", "ja", "zh_Hans", "zh_Hant", "es",
	"pt_BR", "fr", "de", "ru", "id", "vi",
]

## Locales whose script is drawn one glyph at a time so the CSS letter-spacing
## the HUD depends on can be applied. Everything else is drawn as a whole run.
##
## Arabic joins its letters, and Devanagari and Thai form clusters, so splitting
## a string into characters destroys the word. None of those ship yet, but the
## rule is here so adding one cannot quietly break its text.
const SEPARABLE_SCRIPTS: PackedStringArray = [
	"en", "ko", "ja", "zh_Hans", "zh_Hant", "es",
	"pt_BR", "fr", "de", "ru", "id", "vi",
]

static var _loaded := false


## Registers every locale. Called once at startup.
##
## Godot can do this from `internationalization/locale/translations`, but that
## makes the exporter bundle 4.8 MB of ICU data for bidirectional text and word
## breaking that none of these languages need — see project.godot. Loading them
## here costs twelve `load()` calls and saves the whole download.
static func load_all() -> void:
	if _loaded:
		return
	_loaded = true
	for locale in LOCALES:
		var path := "res://assets/i18n/half_step.%s.translation" % locale
		var translation := ResourceLoader.load(path) as Translation
		if translation != null:
			TranslationServer.add_translation(translation)
	# Godot picks the device's language; anything unshipped falls back to the
	# source language rather than showing raw keys.
	use(TranslationServer.get_locale())


static func t(key: String) -> String:
	load_all()
	return String(TranslationServer.translate(key))


## Whether the current locale's text survives being split into characters.
static func letters_separable() -> bool:
	return SEPARABLE_SCRIPTS.has(TranslationServer.get_locale())


## Picks the locale from the device, falling back to the source language. Godot
## already does this at startup; this exists so the setting can be changed at
## runtime and so tests can drive it.
static func use(locale: String) -> void:
	load_all()
	if LOCALES.has(locale):
		TranslationServer.set_locale(locale)
		return
	# "ko_KR" and "pt" should land on "ko" and "pt_BR", not on English.
	var language := locale.split("_")[0]
	for candidate in LOCALES:
		if candidate.split("_")[0] == language:
			TranslationServer.set_locale(candidate)
			return
	TranslationServer.set_locale(LOCALES[0])
