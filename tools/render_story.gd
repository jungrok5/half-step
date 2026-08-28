extends SceneTree

## Bakes the six intro and ending stills to `assets/story/*.png`.
##
##   godot --path . --script res://tools/render_story.gd
##
## Needs a real display; under CI use `xvfb-run` with a software GL driver.
##
## These are placeholders drawn from the game's own primitives, so the cut
## scenes are finished now. Replacing one with real art is dropping a file with
## the same name on top of it — nothing in the game reads [StoryArt] at run time.
## `tools/imagegen/story_art.py` generates that art through the Codex CLI.

const OUT := "res://assets/story"


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var arguments := OS.get_cmdline_user_args()
	var out := arguments[0] if arguments.size() > 0 else OUT
	DirAccess.make_dir_recursive_absolute(out)
	# The wordmark is its own slot so real lettering can replace it without
	# touching the title screen. Drawn from the translation table, so what ships
	# is the game's actual name rather than a placeholder word.
	await _bake(root, out, "wordmark", Vector2i(760, 260), WordmarkFrame.new())
	for id: String in StoryArt.FRAMES:
		var frame := StoryFrame.new()
		frame.id = id
		await _bake(root, out, id, Vector2i(StoryArt.FRAME), frame)
	quit(0)


func _bake(host: Node, out: String, id: String, size: Vector2i, node: Node2D) -> void:
	var viewport := SubViewport.new()
	viewport.size = size
	viewport.transparent_bg = id == "wordmark"
	viewport.disable_3d = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	viewport.add_child(node)
	host.add_child(viewport)
	await process_frame
	await RenderingServer.frame_post_draw
	var path := "%s/%s.png" % [out, id]
	viewport.get_texture().get_image().save_png(path)
	viewport.queue_free()
	print("wrote ", path)


class StoryFrame:
	extends Node2D

	var id := ""

	func _draw() -> void:
		StoryArt.draw_frame(self, id)


class WordmarkFrame:
	extends Node2D

	func _draw() -> void:
		I18n.use("en")
		var text := I18n.t("TITLE")
		var width := CssText.width(text, 132.0, 14.0)
		CssText.draw_at(self, text, Vector2((760.0 - width) * 0.5, 46.0), 132.0, 14.0,
			Color(1.0, 1.0, 1.0))
