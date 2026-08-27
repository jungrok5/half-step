class_name CssPaint
extends RefCounted

## Rasterises the CSS constructs the prototype leans on — linear/radial
## gradients, repeating dash patterns — with `CanvasItem` draw calls.

const _RADIAL_SEGMENTS := 64


## Resolves the CSS `transparent` keyword. Browsers interpolate gradients with
## premultiplied alpha, so a fully transparent stop takes the RGB of whichever
## neighbour it is being interpolated against instead of fading through black.
static func _resolve(stop_color: Color, neighbour: Color) -> Color:
	if stop_color.a > 0.0:
		return stop_color
	return Color(neighbour.r, neighbour.g, neighbour.b, 0.0)


## CSS `linear-gradient(<angle>, ...)`. 0deg points to the top, angles run
## clockwise. [param stops] is an array of `[position, Color]` pairs.
static func linear_gradient(canvas: CanvasItem, rect: Rect2, angle_degrees: float, stops: Array) -> void:
	if stops.size() < 2 or rect.size.x <= 0.0 or rect.size.y <= 0.0:
		return
	var angle := deg_to_rad(angle_degrees)
	var direction := Vector2(sin(angle), -cos(angle))
	var length := absf(rect.size.x * sin(angle)) + absf(rect.size.y * cos(angle))
	if length <= 0.0:
		return
	var origin := rect.get_center() - direction * length * 0.5
	var normal := Vector2(-direction.y, direction.x)
	var extent := rect.size.x + rect.size.y
	var clip := PackedVector2Array([
		rect.position,
		Vector2(rect.end.x, rect.position.y),
		rect.end,
		Vector2(rect.position.x, rect.end.y),
	])
	# CSS holds the first and last stop colours flat beyond the gradient line
	# instead of continuing to ramp, so those runs are drawn as solid bands.
	var extension := (rect.size.x + rect.size.y) / length + 1.0
	var first_position: float = float(stops[0][0])
	var last_position: float = float(stops[stops.size() - 1][0])
	var segments: Array = [[first_position - extension, first_position, stops[0][1], stops[0][1]]]
	for i in range(stops.size() - 1):
		segments.append([
			float(stops[i][0]), float(stops[i + 1][0]),
			_resolve(stops[i][1], stops[i + 1][1]), _resolve(stops[i + 1][1], stops[i][1]),
		])
	segments.append([last_position, last_position + extension,
		stops[stops.size() - 1][1], stops[stops.size() - 1][1]])
	for segment: Array in segments:
		var from_position: float = segment[0]
		var to_position: float = segment[1]
		if to_position <= from_position:
			continue
		var from_color: Color = segment[2]
		var to_color: Color = segment[3]
		if from_color.a <= 0.0 and to_color.a <= 0.0:
			continue
		var from_point := origin + direction * (from_position * length)
		var to_point := origin + direction * (to_position * length)
		var band := PackedVector2Array([
			from_point - normal * extent,
			from_point + normal * extent,
			to_point + normal * extent,
			to_point - normal * extent,
		])
		var span := (to_position - from_position) * length
		for piece in Geometry2D.intersect_polygons(band, clip):
			var colors := PackedColorArray()
			for point in piece:
				var t := clampf((point - from_point).dot(direction) / span, 0.0, 1.0)
				colors.append(from_color.lerp(to_color, t))
			canvas.draw_polygon(piece, colors)


## CSS `radial-gradient(circle at <x> <y>, ...)` with the default
## `farthest-corner` sizing. Stop positions are fractions of that radius.
static func radial_gradient(canvas: CanvasItem, rect: Rect2, center_ratio: Vector2, stops: Array) -> void:
	if rect.size.x <= 0.0 or rect.size.y <= 0.0:
		return
	var center := rect.position + rect.size * center_ratio
	var radius := 0.0
	for corner in [rect.position, Vector2(rect.end.x, rect.position.y), rect.end, Vector2(rect.position.x, rect.end.y)]:
		radius = maxf(radius, center.distance_to(corner))
	radial_gradient_at(canvas, center, radius, stops)


## Radial gradient with an explicit outer radius. Stop positions are fractions
## of [param radius], matching `ctx.createRadialGradient` offsets on the card.
static func radial_gradient_at(canvas: CanvasItem, center: Vector2, radius: float, stops: Array) -> void:
	if stops.size() < 2 or radius <= 0.0:
		return
	var unit: Array[Vector2] = []
	for i in _RADIAL_SEGMENTS:
		var a := TAU * float(i) / float(_RADIAL_SEGMENTS)
		unit.append(Vector2(cos(a), sin(a)))
	var inner_radius: float = float(stops[0][0]) * radius
	var inner_color: Color = _resolve(stops[0][1], stops[1][1])
	if inner_radius > 0.0 and inner_color.a > 0.0:
		var disc := PackedVector2Array()
		var disc_colors := PackedColorArray()
		for point in unit:
			disc.append(center + point * inner_radius)
			disc_colors.append(inner_color)
		canvas.draw_polygon(disc, disc_colors)
	for i in range(stops.size() - 1):
		var from_radius: float = float(stops[i][0]) * radius
		var to_radius: float = float(stops[i + 1][0]) * radius
		if to_radius <= from_radius:
			continue
		var from_color := _resolve(stops[i][1], stops[i + 1][1])
		var to_color := _resolve(stops[i + 1][1], stops[i][1])
		if from_color.a <= 0.0 and to_color.a <= 0.0:
			continue
		for s in _RADIAL_SEGMENTS:
			var a := unit[s]
			var b := unit[(s + 1) % _RADIAL_SEGMENTS]
			canvas.draw_polygon(
				PackedVector2Array([
					center + a * from_radius, center + b * from_radius,
					center + b * to_radius, center + a * to_radius,
				]),
				PackedColorArray([from_color, from_color, to_color, to_color])
			)
	var outer_color: Color = stops[stops.size() - 1][1]
	if outer_color.a > 0.0:
		var outer_radius: float = float(stops[stops.size() - 1][0]) * radius
		for s in _RADIAL_SEGMENTS:
			var a := unit[s]
			var b := unit[(s + 1) % _RADIAL_SEGMENTS]
			canvas.draw_polygon(
				PackedVector2Array([
					center + a * outer_radius, center + b * outer_radius,
					center + b * radius * 2.0, center + a * radius * 2.0,
				]),
				PackedColorArray([outer_color, outer_color, outer_color, outer_color])
			)


## Paints the gradient described by a `ZoneConfig` `atmo` dictionary.
static func atmosphere(canvas: CanvasItem, rect: Rect2, atmo: Dictionary, opacity: float) -> void:
	if opacity <= 0.0:
		return
	var kind := String(atmo.get("kind", "none"))
	if kind == "none":
		return
	var stops: Array = []
	for stop in atmo.stops:
		var faded: Color = stop[1]
		faded.a *= opacity
		stops.append([stop[0], faded])
	if kind == "linear":
		linear_gradient(canvas, rect, float(atmo.angle), stops)
	elif kind == "radial":
		radial_gradient(canvas, rect, atmo.center, stops)


## A horizontal run of `repeating-linear-gradient(to right, ...)` dashes.
static func dashed_row(canvas: CanvasItem, from: Vector2, width: float, height: float, dash: float, gap: float, color: Color) -> void:
	var x := 0.0
	while x < width:
		canvas.draw_rect(Rect2(from + Vector2(x, 0.0), Vector2(minf(dash, width - x), height)), color)
		x += dash + gap


## A CSS `dashed` outline drawn inside [param rect] with the given width.
static func dashed_outline(canvas: CanvasItem, rect: Rect2, thickness: float, dash: float, gap: float, color: Color) -> void:
	dashed_row(canvas, rect.position, rect.size.x, thickness, dash, gap, color)
	dashed_row(canvas, Vector2(rect.position.x, rect.end.y - thickness), rect.size.x, thickness, dash, gap, color)
	var y := dash + gap
	while y < rect.size.y - thickness:
		var run := minf(dash, rect.size.y - thickness - y)
		canvas.draw_rect(Rect2(rect.position + Vector2(0.0, y), Vector2(thickness, run)), color)
		canvas.draw_rect(Rect2(Vector2(rect.end.x - thickness, rect.position.y + y), Vector2(thickness, run)), color)
		y += dash + gap
