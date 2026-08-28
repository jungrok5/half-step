class_name CodexScreen
extends Node2D

## The cat codex: four sections, one per way in. Drawn in the same units as the
## playfield and scrolled by dragging, because the roster is taller than a
## phone.
##
## Owned cats show their art and name, witnessed cats show art and name but stay
## locked, and locked cats show a silhouette and the condition only — AGENTS.md
## section 8: what you have not reached, you do not see.

const HEADER := 104.0
const CARD := Vector2(106.0, 140.0)
const GAP := 10.0
const COLUMNS := 3
const SECTION_HEAD := 38.0
const PAD := 18.0

const INK := Color("24313d")
const MUTED := Color("6d8293")
const ACCENT := Color("ef6a5b")
const PAPER := Color("f6fbff")
const RULE := Color("d6e7f1")

const SECTIONS := [
	{"key": CatConfig.Unlock.LEVEL, "title": "레벨", "note": "누적 경험치"},
	{"key": CatConfig.Unlock.SCORE, "title": "하늘", "note": "한 판의 도달 점수"},
	{"key": CatConfig.Unlock.FEAT, "title": "손끝", "note": "한 판 안의 위업"},
	{"key": CatConfig.Unlock.WITNESS, "title": "목격", "note": "남의 카드"},
]

var progress: Progress
var scroll := 0.0

var _rect := Rect2()
var _cards: Array[Dictionary] = []
var _content_height := 0.0
var _close := Rect2()
var _dragging := false
var _drag_moved := 0.0


func open(from: Progress, rect: Rect2) -> void:
	progress = from
	visible = true
	scroll = 0.0
	layout(rect)
	queue_redraw()


func close() -> void:
	visible = false
	queue_redraw()


## Places every card. Kept apart from drawing so hit testing never depends on a
## frame having been rendered.
func layout(rect: Rect2) -> void:
	_rect = rect
	_cards.clear()
	var grid_width := float(COLUMNS) * CARD.x + float(COLUMNS - 1) * GAP
	var left := rect.position.x + (rect.size.x - grid_width) * 0.5
	var y := rect.position.y + HEADER
	for section: Dictionary in SECTIONS:
		y += SECTION_HEAD
		var column := 0
		for cat in CatConfig.all():
			if int(cat.unlock) != int(section.key):
				continue
			_cards.append({
				"cat": cat,
				"rect": Rect2(Vector2(left + float(column) * (CARD.x + GAP), y), CARD),
				"section": section.title,
			})
			column += 1
			if column >= COLUMNS:
				column = 0
				y += CARD.y + GAP
		if column > 0:
			y += CARD.y + GAP
	_content_height = y - rect.position.y + PAD
	_close = Rect2(rect.end.x - 54.0, rect.position.y + 26.0, 36.0, 36.0)


func max_scroll() -> float:
	return maxf(0.0, _content_height - _rect.size.y)


## Returns true when the event was consumed.
func handle_press(position: Vector2) -> bool:
	if _close.has_point(position):
		close()
		return true
	_dragging = true
	_drag_moved = 0.0
	return true


func handle_drag(delta: float) -> void:
	if not _dragging:
		return
	_drag_moved += absf(delta)
	scroll = clampf(scroll - delta, 0.0, max_scroll())
	queue_redraw()


## A release that never became a drag is a tap: equip the cat under it.
func handle_release(position: Vector2) -> void:
	if not _dragging:
		return
	_dragging = false
	if _drag_moved > 8.0:
		return
	for card in _cards:
		var box := Rect2(Rect2(card.rect).position - Vector2(0.0, scroll), CARD)
		if not box.has_point(position):
			continue
		var id := String(card.cat.id)
		if progress != null and progress.owns(id):
			progress.equipped = id
			queue_redraw()
		return


func _draw() -> void:
	if progress == null:
		return
	var size := _rect.size
	draw_set_transform(_rect.position)
	draw_rect(Rect2(Vector2.ZERO, size), PAPER)

	# Cards first, clipped by simply skipping what is off screen.
	var visible_top := scroll + _rect.position.y
	for card in _cards:
		var box := Rect2(Rect2(card.rect).position - _rect.position - Vector2(0.0, scroll), CARD)
		if box.end.y < HEADER - CARD.y or box.position.y > size.y:
			continue
		_draw_card(box, card.cat)

	# Section headings ride with the cards.
	var seen: Dictionary = {}
	for card in _cards:
		var title: String = card.section
		if seen.has(title):
			continue
		seen[title] = true
		var note := ""
		for section: Dictionary in SECTIONS:
			if String(section.title) == title:
				note = String(section.note)
		var y: float = Rect2(card.rect).position.y - _rect.position.y - scroll - SECTION_HEAD + 12.0
		if y < HEADER - SECTION_HEAD or y > size.y:
			continue
		var left: float = Rect2(card.rect).position.x - _rect.position.x
		CssText.draw_at(self, title, Vector2(left, y), 15.0, 0.0, INK)
		CssText.draw_at(self, note, Vector2(left + CssText.width(title, 15.0, 0.0) + 10.0, y + 3.0), 10.0, 1.2, MUTED)

	_draw_header(size)
	draw_set_transform(Vector2.ZERO)


func _draw_header(size: Vector2) -> void:
	draw_rect(Rect2(Vector2.ZERO, Vector2(size.x, HEADER)), PAPER)
	draw_rect(Rect2(Vector2(0.0, HEADER - 1.0), Vector2(size.x, 1.0)), RULE)
	CssText.draw_at(self, "도감", Vector2(PAD, 34.0), 20.0, 0.0, INK)
	var owned := progress.owned_count()
	var total := CatConfig.CATS.size()
	CssText.draw_at(self, "%d / %d" % [owned, total], Vector2(PAD, 58.0), 11.0, 1.4, MUTED)

	var level := progress.level()
	var label := "LV %d" % level
	var width := CssText.width(label, 13.0, 1.4)
	CssText.draw_at(self, label, Vector2(size.x - PAD - width - 44.0, 34.0), 13.0, 1.4, ACCENT)

	# Progress to the next level. Flat when the level cap is reached.
	var bar := Rect2(PAD, 74.0, size.x - PAD * 2.0, 6.0)
	draw_rect(bar, RULE)
	draw_rect(Rect2(bar.position, Vector2(bar.size.x * progress.level_fraction(), bar.size.y)), ACCENT)

	var close := Rect2(_close.position - _rect.position, _close.size)
	draw_rect(close, Color("e7f2f9"))
	CssText.draw_centered(self, "×", close.position.x, close.size.x, close.position.y + 8.0, 18.0, 0.0, INK)


func _draw_card(box: Rect2, cat: Dictionary) -> void:
	var id := String(cat.id)
	var owned := progress.owns(id)
	var witnessed := progress.has_witnessed(id)
	var zone := CatConfig.zone_of(cat)
	var art := Rect2(box.position, Vector2(box.size.x, 92.0))
	if owned or witnessed:
		CssPaint.linear_gradient(self, art, 160.0, [[0.0, zone.top], [1.0, zone.bottom]])
	else:
		draw_rect(art, Color("cfdeea"))

	draw_set_transform(_rect.position + art.get_center() + Vector2(0.0, 4.0), 0.0, Vector2(1.35, 1.35))
	if owned:
		Art.draw_cat_portrait(self, cat, Color(zone.top).lerp(zone.bottom, 0.5))
	elif witnessed:
		# Fully drawn and plainly not yours yet: the most wanted state.
		Art.draw_cat_portrait(self, cat, Color(zone.top).lerp(zone.bottom, 0.5), 0.62, 0.0, 0.86)
	else:
		Shapes.fill(self, Art.cat_polygon(0.62, 0.0, cat), Color("8ba3b8", 0.55))
	draw_set_transform(_rect.position)

	if progress.equipped == id:
		draw_rect(box, ACCENT, false, 2.0)

	var strip := Rect2(box.position + Vector2(0.0, 92.0), Vector2(box.size.x, box.size.y - 92.0))
	draw_rect(strip, Color("edf4fa"))
	var name := String(cat.name) if owned or witnessed else "?"
	CssText.draw_at(self, name, Vector2(strip.position.x + 8.0, strip.position.y + 8.0), 13.0, 0.0,
		INK if owned else MUTED)
	var line := String(cat.code) if owned else CatConfig.condition_label(cat)
	if witnessed:
		line = "SEEN · %s" % String(cat.code)
	CssText.draw_at(self, line, Vector2(strip.position.x + 8.0, strip.position.y + 29.0), 9.0, 1.0, MUTED)

	# The best score reached with this cat rides on the art, not the name strip,
	# which has no room for a second line.
	var best := int(progress.bests.get(id, 0))
	if owned and best > 0:
		var label := "최고 %d" % best
		var chip_width := CssText.width(label, 9.0, 0.8) + 12.0
		var chip := Rect2(box.position + Vector2(box.size.x - chip_width - 6.0, 92.0 - 20.0),
			Vector2(chip_width, 15.0))
		draw_rect(chip, Color("0b1526", 0.52))
		CssText.draw_at(self, label, chip.position + Vector2(6.0, 2.0), 9.0, 0.8, Color(1.0, 1.0, 1.0, 0.92))
