class_name StoryArt
extends RefCounted

## The six intro and ending stills, drawn from the same primitives as the game,
## plus Tori's portrait for the memorial.
##
## The stills exist so the cut scenes are finished today. `tools/render_story.gd`
## bakes them to `assets/story/*.png`, which is where [StoryConfig] already
## looks — so replacing one with a piece of real art is dropping a file on top
## of it. Nothing in the game loads them from here at run time.
##
## The portrait is the exception: [StoryScreen] draws it live, because it is
## laid out against numbers from the save file. It has the same swap-in slot —
## [PHOTO] — for the day there is a photograph of the real cat.
##
## Every frame is composed in a 1080x1920 space and scaled, so one set of
## coordinates serves any output size. The palettes are the game's own
## [ZoneConfig] skies and [Art] fur, because a cut scene that does not match the
## playfield is a cut scene from a different game.

const FRAME := Vector2(1080.0, 1920.0)

## Warm interior, the colours the intro opens on and the ending returns to.
const LAMP := Color("ffdca0")
const LOW_SUN := Color("ff9a78")
const WOOD := Color("8b5a3c")
const WOOD_DARK := Color("5b3a26")
const CLOTH := Color("f6f1e6")
const CUSHION := Color("42586d")
const SHADOW := Color("24313d")

## The same room at night.
const MOON := Color("745b9e")
const NIGHT := Color("172b66")
const WOOD_COLD := Color("3f4c5a")
const DUST := Color("8ba0b3")

const DECK := Color("2b3846")
const DECK_TOP := Color("42586d")
const DECK_SHADOW := Color("151d24")

## Ids in the order they play, matching [StoryConfig].
const FRAMES: PackedStringArray = [
	"intro_1", "intro_2", "intro_3", "ending_1", "ending_2", "ending_3",
]


static func draw_frame(canvas: CanvasItem, id: String) -> void:
	match id:
		"intro_1": _intro_room_dusk(canvas)
		"intro_2": _intro_room_night(canvas)
		"intro_3": _intro_setting_off(canvas)
		"ending_1": _ending_quiet(canvas)
		"ending_2": _ending_figure(canvas)
		"ending_3": _ending_hands(canvas)


# --- pieces -----------------------------------------------------------------

## A bridge deck seen from straight above: planks, a rail down each long edge,
## and a soft shadow far below. No thickness, because there is none to see.
static func _deck(canvas: CanvasItem, rect: Rect2, radius := 26.0) -> void:
	for step in 4:
		var spread := 1.0 + float(step) * 0.05
		var grown := Rect2(rect.get_center() - rect.size * spread * 0.5 + Vector2(6.0, 30.0),
			rect.size * spread)
		Shapes.rounded_rect(canvas, grown, radius, Color(0.05, 0.09, 0.15, 0.05))
	Shapes.rounded_rect(canvas, rect, radius, DECK)
	var planks := int(rect.size.y / 84.0)
	for i in range(1, maxi(planks, 1)):
		var y := rect.position.y + rect.size.y * float(i) / float(maxi(planks, 1))
		canvas.draw_line(Vector2(rect.position.x + 20.0, y), Vector2(rect.end.x - 20.0, y),
			Color(0.0, 0.0, 0.0, 0.20), 4.0, true)
	for x: float in [rect.position.x, rect.end.x - 15.0]:
		Shapes.rounded_rect(canvas, Rect2(Vector2(x, rect.position.y), Vector2(15.0, rect.size.y)),
			7.0, DECK_TOP)


## A person seen from straight overhead: the crown of the head sitting ON the
## shoulders, and a long shadow. From this angle there is no face — which is the
## point. The person is anyone's.
##
## Two earlier attempts failed and both are worth remembering. Ellipses beside
## the head read as pigtails. A head balanced above a wide shoulder ellipse read
## as a flying saucer. What works is the head OVERLAPPING a rounded torso only a
## little wider than it is — which is what looking down at someone actually
## looks like.
static func draw_person(canvas: CanvasItem, centre: Vector2, scale: float, tone: Color,
		shadow_length := 1.0) -> void:
	if shadow_length > 0.0:
		Shapes.fill(canvas, Shapes.ellipse_polygon(
			centre + Vector2(0.0, 230.0 * scale * shadow_length),
			Vector2(80.0, 260.0 * shadow_length) * scale), Color(SHADOW, 0.15))
	Shapes.rounded_rect(canvas, Rect2(centre + Vector2(-98.0, -10.0) * scale,
		Vector2(196.0, 176.0) * scale), 74.0 * scale, tone)
	Shapes.fill(canvas, Shapes.circle_polygon(centre + Vector2(0.0, 26.0 * scale), 62.0 * scale),
		Color(tone).lerp(Color(0.0, 0.0, 0.0), 0.16))


## Two arms reaching down into frame, ending in open hands. Used only by the
## last frame, where the arms are the whole subject.
static func _reaching_arms(canvas: CanvasItem, from_y: float, to_y: float, spread: float,
		sleeve: Color, hand: Color) -> void:
	for side: float in [-1.0, 1.0]:
		# They enter from above the frame and angle inward, so the two of them
		# never close into a horseshoe across the top.
		var top := Vector2(540.0 + side * spread * 1.35, from_y)
		var wrist := Vector2(540.0 + side * spread * 0.62, to_y)
		Shapes.capsule(canvas, top, wrist, 76.0, sleeve)
		Shapes.fill(canvas, Shapes.circle_polygon(wrist + Vector2(side * -14.0, 44.0), 58.0), hand)


## The cat, at a story scale rather than a playfield one.
static func _tori(canvas: CanvasItem, centre: Vector2, scale: float, tail := 0.62,
		leap := 0.0) -> void:
	canvas.draw_set_transform(centre, 0.0, Vector2(scale, scale))
	Art.draw_cat(canvas, 1.0, tail, leap, CatConfig.by_id(CatConfig.STARTER))
	canvas.draw_set_transform(Vector2.ZERO)


static func _cloud(canvas: CanvasItem, centre: Vector2, scale: float, color: Color) -> void:
	canvas.draw_set_transform(centre, 0.0, Vector2(scale, scale))
	Art.draw_cloud(canvas, color)
	canvas.draw_set_transform(Vector2.ZERO)


## Darkens the corners so the eye goes where the light is.
static func _vignette(canvas: CanvasItem, strength: float, tint: Color) -> void:
	CssPaint.radial_gradient_at(canvas, FRAME * Vector2(0.5, 0.42), FRAME.x * 1.05, [
		[0.42, Color(tint, 0.0)], [1.0, Color(tint, strength)],
	])


## The band the caption is drawn over. Every frame leaves it quiet.
static func _caption_room(canvas: CanvasItem, tint: Color) -> void:
	CssPaint.linear_gradient(canvas, Rect2(Vector2(0.0, FRAME.y * 0.58),
		Vector2(FRAME.x, FRAME.y * 0.42)), 180.0, [
		[0.0, Color(tint, 0.0)], [1.0, Color(tint, 0.45)],
	])


# --- the room ---------------------------------------------------------------

## Floor, table, cushions and slippers, in the same places in both room frames.
## Repetition is what makes the time pass between them, so nothing moves except
## the light and the cat.
static func _room(canvas: CanvasItem, floor_color: Color, seam: Color, cushion: Color,
		cloth: Color, warm: bool) -> void:
	canvas.draw_rect(Rect2(Vector2.ZERO, FRAME), floor_color)
	for i in 9:
		var x := FRAME.x * float(i) / 9.0
		canvas.draw_line(Vector2(x, 0.0), Vector2(x, FRAME.y), Color(seam, 0.55), 5.0, true)
	# A rug the whole scene sits on, so the objects are not floating.
	Shapes.rounded_rect(canvas, Rect2(Vector2(120.0, 520.0), Vector2(840.0, 900.0)), 40.0,
		Color(cloth, 0.16 if warm else 0.10))

	# The low table, with a cup nobody moved.
	Shapes.rounded_rect(canvas, Rect2(Vector2(392.0, 560.0), Vector2(300.0, 210.0)), 26.0,
		Color(seam, 0.9))
	Shapes.rounded_rect(canvas, Rect2(Vector2(408.0, 574.0), Vector2(268.0, 182.0)), 20.0,
		Color(floor_color).lerp(cloth, 0.22))
	Shapes.fill(canvas, Shapes.circle_polygon(Vector2(596.0, 660.0), 34.0), cloth)
	Shapes.fill(canvas, Shapes.circle_polygon(Vector2(596.0, 660.0), 24.0),
		Color(seam).lerp(cloth, 0.25))

	# Two cushions. The right one is the one that is empty.
	for centre: Vector2 in [Vector2(392.0, 1080.0), Vector2(688.0, 1080.0)]:
		Shapes.rounded_rect(canvas, Rect2(centre - Vector2(130.0, 96.0), Vector2(260.0, 192.0)),
			54.0, Color(SHADOW, 0.16))
		Shapes.rounded_rect(canvas, Rect2(centre - Vector2(124.0, 92.0), Vector2(248.0, 184.0)),
			50.0, cushion)
		Shapes.rounded_rect(canvas, Rect2(centre - Vector2(96.0, 68.0), Vector2(192.0, 136.0)),
			38.0, Color(cushion).lerp(cloth, 0.14))

	# Slippers, set down neatly beside the empty cushion.
	for x: float in [836.0, 916.0]:
		Shapes.rounded_rect(canvas, Rect2(Vector2(x, 1040.0), Vector2(58.0, 128.0)), 26.0,
			Color(cloth, 0.86 if warm else 0.5))

	# A blanket pushed aside at the top of the frame.
	Shapes.rounded_rect(canvas, Rect2(Vector2(150.0, 300.0), Vector2(330.0, 190.0)), 44.0,
		Color(cloth, 0.55 if warm else 0.30))


static func _intro_room_dusk(canvas: CanvasItem) -> void:
	_room(canvas, WOOD, WOOD_DARK, CUSHION, CLOTH, true)
	# One long rectangle of late light from a window out of frame. It is the
	# only warm thing in the picture and it falls across the empty cushion.
	canvas.draw_set_transform(Vector2(FRAME.x * 0.52, FRAME.y * 0.48), -0.30)
	CssPaint.linear_gradient(canvas, Rect2(Vector2(-300.0, -1000.0), Vector2(600.0, 2000.0)), 90.0,
		[[0.0, Color(LAMP, 0.0)], [0.30, Color(LAMP, 0.78)], [0.70, Color(LOW_SUN, 0.55)],
		 [1.0, Color(LOW_SUN, 0.0)]])
	canvas.draw_set_transform(Vector2.ZERO)
	_tori(canvas, Vector2(392.0, 1064.0), 3.1, 0.30)
	# Light, not gloom: the room is empty, not grim.
	_vignette(canvas, 0.30, SHADOW)
	_caption_room(canvas, SHADOW)


static func _intro_room_night(canvas: CanvasItem) -> void:
	_room(canvas, WOOD_COLD, Color("2a343f"), Color("2f3b4d"), Color("dfe9f2"), false)
	CssPaint.linear_gradient(canvas, Rect2(Vector2.ZERO, FRAME), 160.0,
		[[0.0, Color(NIGHT, 0.55)], [1.0, Color(MOON, 0.30)]])
	# Dust on the cushion nobody has sat on since.
	var rng := RandomNumberGenerator.new()
	rng.seed = 4
	for i in 90:
		canvas.draw_circle(Vector2(688.0, 1080.0) + Vector2(rng.randf_range(-104.0, 104.0),
			rng.randf_range(-74.0, 74.0)), rng.randf_range(1.5, 4.0),
			Color(DUST, rng.randf_range(0.12, 0.34)), true, -1.0, true)
	# The doorway, and Tori sitting in it with her back to us.
	Shapes.rounded_rect(canvas, Rect2(Vector2(346.0, -60.0), Vector2(388.0, 330.0)), 26.0,
		Color("05080f"))
	CssPaint.linear_gradient(canvas, Rect2(Vector2(346.0, 200.0), Vector2(388.0, 220.0)), 180.0,
		[[0.0, Color("05080f")], [1.0, Color("05080f", 0.0)]])
	# She sits in the doorway with her back to us, clear of the frame edge.
	_tori(canvas, Vector2(540.0, 400.0), 3.1, 0.30)
	_vignette(canvas, 0.46, Color("060a14"))
	_caption_room(canvas, Color("060a14"))


static func _intro_setting_off(canvas: CanvasItem) -> void:
	var sky: Dictionary = ZoneConfig.ZONES[0]
	CssPaint.linear_gradient(canvas, Rect2(Vector2.ZERO, FRAME), 180.0,
		[[0.0, sky.top], [1.0, sky.bottom]])
	for spec: Array in [[Vector2(180.0, 520.0), 3.0], [Vector2(880.0, 760.0), 2.4],
			[Vector2(300.0, 1180.0), 3.6], [Vector2(820.0, 1420.0), 2.8]]:
		_cloud(canvas, spec[0], spec[1], Color(1.0, 1.0, 1.0, 0.9))
	# The deck ahead, and the one after it, so the journey has a direction.
	_deck(canvas, Rect2(Vector2(250.0, 200.0), Vector2(360.0, 190.0)))
	_deck(canvas, Rect2(Vector2(390.0, 660.0), Vector2(380.0, 200.0)))
	_tori(canvas, Vector2(580.0, 762.0), 3.2, 0.62, 0.35)
	# The room, far below and shrinking: a rectangle of doorway light.
	CssPaint.radial_gradient_at(canvas, Vector2(540.0, 1720.0), 520.0,
		[[0.0, Color(LAMP, 0.85)], [0.5, Color(LOW_SUN, 0.34)], [1.0, Color(LAMP, 0.0)]])
	Shapes.rounded_rect(canvas, Rect2(Vector2(432.0, 1630.0), Vector2(216.0, 190.0)), 24.0,
		Color(LAMP))
	Shapes.rounded_rect(canvas, Rect2(Vector2(456.0, 1654.0), Vector2(168.0, 142.0)), 16.0,
		Color("fff4dc"))
	_cloud(canvas, Vector2(560.0, 1560.0), 4.2, Color(1.0, 1.0, 1.0, 0.42))
	_caption_room(canvas, Color("1b3350"))


# --- the ending -------------------------------------------------------------

static func _ending_quiet(canvas: CanvasItem) -> void:
	var sky: Dictionary = ZoneConfig.ZONES[9]
	CssPaint.linear_gradient(canvas, Rect2(Vector2.ZERO, FRAME), 180.0,
		[[0.0, sky.top], [1.0, sky.bottom]])
	# Clouds thinned almost to nothing: everything that was moving has stopped.
	for spec: Array in [[Vector2(240.0, 420.0), 3.4], [Vector2(860.0, 980.0), 3.0],
			[Vector2(420.0, 1500.0), 3.8]]:
		_cloud(canvas, spec[0], spec[1], Color(1.0, 1.0, 1.0, 0.30))
	# One deck, ending partway up the frame, with nothing after it.
	# Narrow and long, so it reads as a bridge, and stopping partway up the frame
	# with nothing after it is the whole picture.
	_deck(canvas, Rect2(Vector2(452.0, 520.0), Vector2(216.0, 900.0)), 30.0)
	_tori(canvas, Vector2(560.0, 660.0), 2.7)
	_vignette(canvas, 0.10, Color("8ba0b3"))
	_caption_room(canvas, Color("6d8293"))


static func _ending_figure(canvas: CanvasItem) -> void:
	CssPaint.linear_gradient(canvas, Rect2(Vector2.ZERO, FRAME), 180.0,
		[[0.0, Color("fff4dc")], [1.0, Color("eaf7ff")]])
	_deck(canvas, Rect2(Vector2(390.0, 240.0), Vector2(300.0, 1060.0)), 36.0)
	# The light gathers behind the figure so its edges glow and its face never
	# resolves. The distance between the two of them is the subject.
	CssPaint.radial_gradient_at(canvas, Vector2(540.0, 470.0), 430.0,
		[[0.0, Color(1.0, 1.0, 1.0, 0.72)], [0.5, Color(LAMP, 0.26)], [1.0, Color(LAMP, 0.0)]])
	draw_person(canvas, Vector2(540.0, 450.0), 1.0, Color("42586d"), 1.2)
	_tori(canvas, Vector2(540.0, 1130.0), 2.8, 0.62, 0.2)
	_caption_room(canvas, Color("42596d"))


static func _ending_hands(canvas: CanvasItem) -> void:
	CssPaint.linear_gradient(canvas, Rect2(Vector2.ZERO, FRAME), 180.0,
		[[0.0, LAMP], [1.0, LOW_SUN]])
	CssPaint.radial_gradient_at(canvas, Vector2(540.0, 620.0), 760.0,
		[[0.0, Color("fff4dc", 0.9)], [1.0, Color("fff4dc", 0.0)]])
	# No deck at all. The bridge is behind them now and the sky has become a
	# lamplit room — anything with edges reads as an object lying in the frame.
	CssPaint.radial_gradient_at(canvas, Vector2(540.0, 980.0), 620.0,
		[[0.0, Color("fff4dc", 0.55)], [1.0, Color("fff4dc", 0.0)]])
	# The person is out of frame. Only their arms come into it, which is closer
	# and quieter than showing the whole of them again.
	_reaching_arms(canvas, -120.0, 800.0, 232.0, Color("42586d"), Color("ffeee7"))
	_tori(canvas, Vector2(540.0, 1090.0), 4.2, 0.5, 0.15)
	_caption_room(canvas, Color("8b5a3c"))


# --- the memorial -----------------------------------------------------------

## Where a photograph of the real cat goes. Drop a square image here and the
## memorial uses it instead of the drawing below; nothing else has to change.
const PHOTO := "res://assets/story/tori_photo.png"

## The radius the portrait is drawn inside. Everything it paints stays within
## this circle, so the caller only has to pick a size.
const PORTRAIT_RADIUS := 118.0

## Tori, face on, inside [PORTRAIT_RADIUS] around the origin.
##
## This is the one place the game's own rule is suspended. Everywhere else the
## camera looks straight down and a cat has no face (see [Art]); here the cat is
## being looked AT rather than followed, and a memorial without a face is a
## memorial to nobody. So this is a portrait: front on, eyes open, the same fur.
##
## It is framed like a photograph — the body runs off the bottom of the circle
## rather than stopping inside it, because a cat that fits neatly in a disc
## reads as a sticker.
static func draw_tori_portrait(canvas: CanvasItem) -> void:
	var cat := CatConfig.by_id(CatConfig.STARTER)
	var fur := Color(cat.get("fur", Art.FUR_COLOR))
	var dark := Color(cat.get("fur_dark", Art.FUR_DARK_COLOR))
	var pale := Color(cat.get("paw", Art.PAW_COLOR))
	var inner := Color(cat.get("inner_ear", Art.INNER_EAR_COLOR))
	var nose := Color("c9616c")
	var disc := Shapes.circle_polygon(Vector2.ZERO, PORTRAIT_RADIUS, 72)

	Shapes.fill(canvas, disc, Color("f2e2d0"))
	# Light behind her, the way a photograph taken on a windowsill has. Clipped
	# to the frame rather than faded out: a soft gradient here would paint over
	# whatever the caller has already drawn around the circle.
	for lit: PackedVector2Array in Geometry2D.intersect_polygons(
			Shapes.ellipse_polygon(Vector2(0.0, -46.0), Vector2(126.0, 112.0)), disc):
		Shapes.fill(canvas, lit, Color("fff1dd"))

	# The chest, cropped by the frame instead of stopping short of it.
	for chest: PackedVector2Array in Geometry2D.intersect_polygons(
			Shapes.ellipse_polygon(Vector2(0.0, 156.0), Vector2(94.0, 94.0)), disc):
		Shapes.fill(canvas, chest, Color(fur).lerp(dark, 0.75))

	# Ears before the head, so the head's edge covers where they join. The inner
	# ear is the outer triangle shrunk toward its own centroid, which keeps it
	# centred in the ear at any shape — nudging the corners by hand gave a
	# sliver leaning against one edge.
	for side: float in [-1.0, 1.0]:
		var corners := PackedVector2Array([Vector2(side * 20.0, -52.0),
			Vector2(side * 58.0, -102.0), Vector2(side * 70.0, -22.0)])
		Shapes.fill(canvas, corners, fur)
		var middle := (corners[0] + corners[1] + corners[2]) / 3.0 + Vector2(0.0, 4.0)
		var petal := PackedVector2Array()
		for corner in corners:
			petal.append(middle + (corner - middle) * 0.58)
		Shapes.fill(canvas, petal, inner)

	# Head and cheeks. The cheeks are the wide, low half of a cat's face, and
	# the reason a round head on its own reads as a bear.
	Shapes.fill_all(canvas, [
		Shapes.ellipse_polygon(Vector2(0.0, 2.0), Vector2(76.0, 70.0)),
		Shapes.ellipse_polygon(Vector2(-34.0, 42.0), Vector2(42.0, 34.0)),
		Shapes.ellipse_polygon(Vector2(34.0, 42.0), Vector2(42.0, 34.0)),
	], fur)

	# The tabby M, the marking that makes her this cat rather than a cat.
	for stripe: Array in [[0.0, 8.0], [-24.0, 6.0], [24.0, 6.0]]:
		var x := float(stripe[0])
		Shapes.capsule(canvas, Vector2(x, -60.0), Vector2(x * 1.3, -30.0), float(stripe[1]), dark)
	for side: float in [-1.0, 1.0]:
		Shapes.capsule(canvas, Vector2(side * 60.0, -12.0), Vector2(side * 70.0, 12.0), 7.0, dark)

	# Whiskers, under the muzzle so they come out from beneath it.
	for side: float in [-1.0, 1.0]:
		for row: Array in [[-6.0, -16.0], [2.0, 2.0], [10.0, 20.0]]:
			canvas.draw_line(Vector2(side * 40.0, 44.0 + float(row[0])),
				Vector2(side * 106.0, 44.0 + float(row[1])), Color(pale, 0.9), 3.0, true)

	# Muzzle, nose, mouth.
	Shapes.fill_all(canvas, [
		Shapes.ellipse_polygon(Vector2(-19.0, 48.0), Vector2(25.0, 19.0)),
		Shapes.ellipse_polygon(Vector2(19.0, 48.0), Vector2(25.0, 19.0)),
	], pale)
	Shapes.fill(canvas, PackedVector2Array([
		Vector2(-14.0, 31.0), Vector2(14.0, 31.0), Vector2(0.0, 48.0),
	]), nose)
	# Nose to mouth, then the two curves of a cat's mouth. Drawn as polylines
	# rather than arcs: an arc at this size lands as a straight stroke and the
	# mouth comes out a capital T.
	var line := Color(Art.EYE_COLOR, 0.82)
	canvas.draw_line(Vector2(0.0, 48.0), Vector2(0.0, 58.0), line, 3.5, true)
	for side: float in [-1.0, 1.0]:
		canvas.draw_polyline(PackedVector2Array([Vector2(0.0, 58.0),
			Vector2(side * 9.0, 65.0), Vector2(side * 18.0, 66.0),
			Vector2(side * 23.0, 62.0)]), line, 3.5, true)

	# Eyes. Open, looking straight out — the whole reason this frame exists.
	for side: float in [-1.0, 1.0]:
		var eye := Vector2(side * 33.0, -4.0)
		Shapes.fill(canvas, Shapes.ellipse_polygon(eye, Vector2(19.0, 22.0)), Color("2f6b4f"))
		Shapes.fill(canvas, Shapes.ellipse_polygon(eye, Vector2(8.0, 18.0)), Art.EYE_COLOR)
		canvas.draw_circle(eye + Vector2(side * 6.0, -8.0), 5.5,
			Color(1.0, 1.0, 1.0, 0.92), true, -1.0, true)


## Draws the photograph at [PHOTO] as a circle of [param radius] around the
## origin, or returns false when there is no photograph yet.
static func draw_tori_photo(canvas: CanvasItem, radius := PORTRAIT_RADIUS) -> bool:
	if not ResourceLoader.exists(PHOTO):
		return false
	var texture := ResourceLoader.load(PHOTO) as Texture2D
	if texture == null:
		return false
	# A circular crop, done with UVs because Godot's 2D canvas has no clipping.
	var ring := Shapes.circle_polygon(Vector2.ZERO, radius, 64)
	var uvs := PackedVector2Array()
	for point in ring:
		uvs.append(point / (radius * 2.0) + Vector2(0.5, 0.5))
	canvas.draw_colored_polygon(ring, Color(1.0, 1.0, 1.0), uvs, texture)
	return true
