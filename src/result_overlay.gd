class_name ResultOverlay
extends Node2D

## `#overlay{backdrop-filter:blur(5px)}` — the frozen run stays visible behind
## the result card, blurred.
##
## Canvas items draw before their children, so the world and HUD painted by
## `game.gd` are already in the back buffer by the time this node's children
## run: copy the buffer, blur it horizontally, copy again, blur vertically, then
## paint the card on top.

const BLUR_RADIUS := 12
## CSS `blur(<length>)` is a Gaussian whose standard deviation is that length.
const BLUR_SIGMA := 5.0

const SHADER_CODE := """
shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_linear;
uniform vec2 direction = vec2(1.0, 0.0);
uniform float sigma = 5.0;

void fragment() {
	vec2 step_size = direction * SCREEN_PIXEL_SIZE;
	vec4 total = vec4(0.0);
	float weight_total = 0.0;
	for (int i = -%d; i <= %d; i++) {
		float offset = float(i);
		float weight = exp(-(offset * offset) / (2.0 * sigma * sigma));
		total += texture(screen_texture, SCREEN_UV + step_size * offset) * weight;
		weight_total += weight;
	}
	COLOR = vec4((total / weight_total).rgb, 1.0);
}
""" % [BLUR_RADIUS, BLUR_RADIUS]


class BlurPass:
	extends Node2D
	var rect := Rect2()

	func _draw() -> void:
		draw_rect(rect, Color(1.0, 1.0, 1.0))


class CardLayer:
	extends Node2D
	var game: Node = null

	func _draw() -> void:
		if game == null:
			return
		# The acquisition card replaces the result card while it is open, so the
		# blurred backdrop is shared and retry stays one tap away behind it.
		if int(game.get("card_index")) >= 0:
			game.draw_cat_card(self)
		else:
			game.draw_result(self)


var _passes: Array[BlurPass] = []
var _card: CardLayer
var _shader: Shader


func _ready() -> void:
	_shader = Shader.new()
	_shader.code = SHADER_CODE
	for direction: Vector2 in [Vector2(1.0, 0.0), Vector2(0.0, 1.0)]:
		var copy := BackBufferCopy.new()
		copy.copy_mode = BackBufferCopy.COPY_MODE_VIEWPORT
		add_child(copy)
		var pass_node := BlurPass.new()
		var material := ShaderMaterial.new()
		material.shader = _shader
		material.set_shader_parameter("direction", direction)
		pass_node.material = material
		add_child(pass_node)
		_passes.append(pass_node)
	_card = CardLayer.new()
	_card.game = get_parent()
	add_child(_card)


## Resizes the blur quads and matches the blur radius to the stretch scale, so
## the blur stays 5 game units wide whatever the device resolution is.
func refresh(rect: Rect2) -> void:
	var scale := get_viewport_transform().get_scale().x
	for pass_node in _passes:
		pass_node.rect = rect
		pass_node.material.set_shader_parameter("sigma", BLUR_SIGMA * maxf(scale, 0.01))
		pass_node.queue_redraw()
	_card.queue_redraw()
