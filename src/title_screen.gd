class_name TitleScreen
extends Node2D

## Home. A tap anywhere starts the run — and on a first ever launch, the intro
## plays between the two.
##
## It is also where everything that is not the run lives: the codex, the two
## replays and the memorial. None of that belongs on the result card, which a
## player sees several hundred times and wants to leave immediately.
##
## The menu grows with the save file. On a first launch there is one row and it
## is locked, which is deliberate — the greyed "opens after the ending" row is
## how the player learns a button will appear there.
##
## It is drawn over the live playfield rather than replacing it, so the clouds
## behind the wordmark are the game's own parallax, still drifting. A static
## background image here would be a worse version of what the game already does.
##
## The wordmark is `assets/story/wordmark.png` when that file exists, so it can
## be replaced with real lettering; without it the title is drawn from the
## translation table, which is what keeps twelve languages honest.

signal started
## A menu row was chosen: "codex", "intro", "ending" or "memorial".
signal menu_selected(id: String)

const WORDMARK := "res://assets/story/wordmark.png"
const INK := Color("f6fbff")
const PULSE_MS := 1600.0
const ROW_HEIGHT := 42.0
const ROW_GAP := 8.0
const ROW_INSET := 42.0
## How much room is left under the last row. Roughly a phone's home indicator:
## a tappable row flush with the bottom of the screen is a row that competes
## with the system gesture for the same thumb.
const BOTTOM_MARGIN := 38.0

var progress: Progress
var time := 0.0

var _rect := Rect2()
var _texture: Texture2D = null
var _looked := false
var _rows: Array[Dictionary] = []
## Laid out in [method layout], read by [method _draw]: the screen is sized from
## the menu upward, so drawing must not re-derive any of it.
var _menu_top := 0.0
var _start_top := 0.0
var _deck_top := 0.0
var _title_y := 0.0


func open(from: Progress, rect: Rect2) -> void:
	progress = from
	visible = true
	time = 0.0
	layout(rect)
	queue_redraw()


func close() -> void:
	visible = false
	queue_redraw()
	started.emit()


## Places the menu. Kept apart from drawing so hit testing never depends on a
## frame having been rendered.
func layout(rect: Rect2) -> void:
	_rect = rect
	_rows.clear()
	var seen_intro := progress != null and progress.seen_intro
	var seen_ending := progress != null and progress.seen_ending
	# The codex row is always here, locked or not: an empty space where a button
	# will appear tells the player nothing.
	var count := "%d / %d" % [progress.owned_count(), CatConfig.CATS.size()] if seen_ending else ""
	_rows.append({"id": "codex", "key": "CODEX", "note": count, "open": seen_ending})
	if seen_intro:
		_rows.append({"id": "intro", "key": "STORY_INTRO_REPLAY", "note": "", "open": true})
	if seen_ending:
		_rows.append({"id": "ending", "key": "STORY_ENDING_REPLAY", "note": "", "open": true})
		_rows.append({"id": "memorial", "key": "MEMORIAL_REPLAY", "note": "", "open": true})
	# Stacked up from the bottom, not down from a fraction of the height. The
	# viewport is 390 units wide and its height follows the real aspect ratio
	# (`keep_width`), so a 4:3 tablet in portrait is 390x520 — and a menu
	# anchored at 70% of that put its last row off the bottom of the screen.
	var width: float = minf(rect.size.x - ROW_INSET * 2.0, 300.0)
	var left := rect.position.x + (rect.size.x - width) * 0.5
	var block := float(_rows.size()) * ROW_HEIGHT + float(maxi(_rows.size() - 1, 0)) * ROW_GAP
	_menu_top = rect.size.y - BOTTOM_MARGIN - block
	for i in _rows.size():
		_rows[i]["rect"] = Rect2(
			Vector2(left, rect.position.y + _menu_top + float(i) * (ROW_HEIGHT + ROW_GAP)),
			Vector2(width, ROW_HEIGHT))
	# Everything above the menu hangs off it, so a short screen tightens rather
	# than overlapping.
	_start_top = _menu_top - 38.0
	_deck_top = _start_top - 52.0
	_title_y = minf(rect.size.y * 0.26, _deck_top - 78.0)


func advance(delta_ms: float) -> void:
	time = fmod(time + delta_ms, PULSE_MS)
	queue_redraw()


## A tap on a menu row opens that row and leaves the title standing behind it.
## Anywhere else starts the run, which is what a title screen is for.
func handle_press(position: Vector2) -> void:
	for row in _rows:
		if not Rect2(row.rect).has_point(position):
			continue
		if bool(row.open):
			menu_selected.emit(String(row.id))
		return
	close()


func _wordmark() -> Texture2D:
	if not _looked:
		_looked = true
		if ResourceLoader.exists(WORDMARK):
			_texture = ResourceLoader.load(WORDMARK) as Texture2D
	return _texture


func _draw() -> void:
	var size := _rect.size
	draw_set_transform(_rect.position)
	# A wash so the wordmark holds against whatever sky is behind it, without
	# hiding the motion that makes the screen feel alive.
	# Deep enough at the top that the wordmark and its subtitle hold against a
	# white cloud drifting behind them, and deep again at the bottom for the
	# menu. The middle is left open so the sky is still visibly moving.
	CssPaint.linear_gradient(self, Rect2(Vector2.ZERO, size), 180.0, [
		[0.0, Color("0b1526", 0.66)], [0.42, Color("0b1526", 0.30)], [1.0, Color("0b1526", 0.72)],
	])

	var centre := Vector2(size.x * 0.5, _title_y)
	var mark := _wordmark()
	if mark != null:
		var source := Vector2(mark.get_size())
		var width: float = minf(size.x * 0.72, source.x)
		var drawn := source * (width / source.x)
		draw_texture_rect(mark, Rect2(centre - drawn * 0.5, drawn), false)
	else:
		CssText.draw_centered(self, I18n.t("TITLE"), 0.0, size.x,
			centre.y - CssText.line_height(56.0) * 0.5, 56.0, 6.0, INK)
	CssText.draw_centered_rimmed(self, I18n.t("SUBTITLE"), 0.0, size.x,
		centre.y + 44.0, 15.0, 2.4, Color(INK, 0.92), Color("06101f", 0.55), 1.8)

	# Tori waiting on a bridge, breathing. The tail sway is the game's own.
	var deck := Rect2(Vector2(size.x * 0.5 - 43.0, _deck_top), Vector2(86.0, 28.0))
	Shapes.rounded_rect(self, Rect2(deck.position + Vector2(0.0, 7.0), deck.size), 9.0,
		Color("151d24", 0.5))
	Shapes.rounded_rect(self, deck, 9.0, Color("2b3846"))
	draw_set_transform(_rect.position + deck.get_center() + Vector2(0.0, -6.0), 0.0, Vector2(1.2, 1.2))
	Art.draw_cat(self, 1.0, fmod(time / PULSE_MS, 1.0), 0.0,
		CatConfig.by_id(progress.equipped if progress != null else CatConfig.STARTER))
	draw_set_transform(_rect.position)

	var half := clampf(time / PULSE_MS, 0.0, 1.0)
	var pulse := half * 2.0 if half <= 0.5 else (1.0 - half) * 2.0
	var start := I18n.t("TAP_TO_START")
	var lit := lerpf(0.62, 1.0, CssAnim.curve(CssAnim.EASE, pulse))
	var start_top := _start_top
	# On a plate, like everything else on this screen: the sky behind it is the
	# live playfield and half the time that means a white cloud.
	var start_width := CssText.width(start, 13.0, 3.0)
	Shapes.rounded_rect(self, Rect2(size.x * 0.5 - start_width * 0.5 - 20.0, start_top - 11.0,
		start_width + 40.0, CssText.line_height(13.0) + 22.0),
		(CssText.line_height(13.0) + 22.0) * 0.5, Color("0b1526", 0.34 + 0.18 * lit))
	CssText.draw_centered(self, start, 0.0, size.x, start_top, 13.0, 3.0, Color(INK, lit))

	for row in _rows:
		_draw_row(Rect2(Rect2(row.rect).position - _rect.position, Rect2(row.rect).size), row)
	draw_set_transform(Vector2.ZERO)


## One menu row. A locked row is drawn, not hidden: what it says is that a
## button appears here later, which is the only way the player finds out.
func _draw_row(box: Rect2, row: Dictionary) -> void:
	var open := bool(row.open)
	# A dark plate, not a translucent white one: the sky behind this screen is
	# the live playfield and it is sometimes a white cloud.
	Shapes.rounded_rect(self, box, 8.0, Color("0b1526", 0.62 if open else 0.38))
	if open:
		draw_rect(box, Color(1.0, 1.0, 1.0, 0.18), false, 1.0)
	var note := String(row.note) if open else I18n.t("CODEX_LOCKED")
	var note_width := CssText.width(note, 10.0, 1.0) if not note.is_empty() else 0.0
	# The label gets whatever the note does not need. In German the note is half
	# the row, and a label drawn at a fixed size would run straight under it.
	var label := I18n.t(String(row.key))
	var label_size := CssText.fit_size(label, box.size.x - note_width - 42.0, 13.0, 0.8, 9.0)
	CssText.draw_at(self, label, box.position + Vector2(16.0, 14.0), label_size, 0.8,
		Color(INK, 0.95 if open else 0.66))
	if note.is_empty():
		return
	CssText.draw_at(self, note, box.position + Vector2(box.size.x - note_width - 16.0, 17.0),
		10.0, 1.0, Color(INK, 0.78 if open else 0.62))
