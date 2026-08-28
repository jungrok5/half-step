extends SceneTree

## Renders every cat in the codex onto its own sky, so the whole roster can be
## checked at a glance.
##
##   godot --path . --script res://tools/render_cats.gd -- <output.png>
##
## Needs a real display; under CI use `xvfb-run` with a software GL driver.

const CELL := Vector2i(150, 176)
const COLUMNS := 6


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var arguments := OS.get_cmdline_user_args()
	var path := arguments[0] if arguments.size() > 0 else "res://cats.png"
	var cats := CatConfig.all()
	var rows := int(ceil(float(cats.size()) / float(COLUMNS)))
	var viewport := SubViewport.new()
	viewport.size = Vector2i(CELL.x * COLUMNS, CELL.y * rows)
	viewport.transparent_bg = false
	viewport.disable_3d = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	var sheet := CatSheet.new()
	sheet.cats = cats
	viewport.add_child(sheet)
	root.add_child(viewport)
	await process_frame
	await RenderingServer.frame_post_draw
	viewport.get_texture().get_image().save_png(path)
	print("wrote ", path, " (", cats.size(), " cats)")
	quit(0)


class CatSheet:
	extends Node2D

	var cats: Array[Dictionary] = []

	func _draw() -> void:
		for i in cats.size():
			var cat := cats[i]
			var origin := Vector2(float(i % COLUMNS) * CELL.x, float(i / COLUMNS) * CELL.y)
			var cell := Rect2(origin, Vector2(CELL))
			var zone := CatConfig.zone_of(cat)
			CssPaint.linear_gradient(self, cell, 160.0, [[0.0, zone.top], [1.0, zone.bottom]])
			draw_set_transform(origin + Vector2(CELL.x * 0.5, CELL.y * 0.5 - 4.0), 0.0, Vector2(2.2, 2.2))
			Art.draw_cat_portrait(self, cat, Color(zone.top).lerp(zone.bottom, 0.5))
			draw_set_transform(Vector2.ZERO)
			var label := "%s  %s" % [String(cat.code), CatConfig.condition_label(cat)]
			draw_rect(Rect2(origin, Vector2(CELL.x, 18.0)), Color(0.02, 0.03, 0.07, 0.55))
			draw_string(CssText.font(), origin + Vector2(6.0, 13.0), label,
				HORIZONTAL_ALIGNMENT_LEFT, -1.0, 10, Color(1.0, 1.0, 1.0))
