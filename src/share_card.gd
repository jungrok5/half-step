class_name ShareCard
extends Node2D

## 1080x1920 share image, ported from `makeShareCardBlob()` in
## `reference/web-prototypes/half_step_pixel_skin.html`, plus the
## `shareScore()` hand-off to the platform share sheet.

const SIZE := Vector2i(1080, 1920)

const CLIPBOARD_STATUS := "공유 미지원 · 텍스트를 클립보드에 복사했어요"
const UNSUPPORTED_STATUS := "이 브라우저는 공유를 지원하지 않아요"
const CANCELLED_STATUS := "공유를 취소했어요"

var score := 0
var zone: Dictionary = {}
var zone_name := ""

static var _callback_ref: Variant = null


## Renders the card off-screen and returns it as an [Image].
static func render(host: Node, card_score: int, card_zone: Dictionary, card_zone_name: String) -> Image:
	var viewport := SubViewport.new()
	viewport.size = SIZE
	viewport.transparent_bg = false
	viewport.disable_3d = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	var card := ShareCard.new()
	card.score = card_score
	card.zone = card_zone
	card.zone_name = card_zone_name
	viewport.add_child(card)
	host.add_child(viewport)
	await host.get_tree().process_frame
	await RenderingServer.frame_post_draw
	var image := viewport.get_texture().get_image()
	viewport.queue_free()
	return image


## Hands the card to the platform. On web this is `navigator.share`, with the
## prototype's clipboard fallback; elsewhere the text goes to the clipboard
## because Godot has no built-in native share sheet.
static func share(text: String, image: Image, card_score: int, on_status: Callable) -> void:
	if not OS.has_feature("web"):
		DisplayServer.clipboard_set(text)
		on_status.call(CLIPBOARD_STATUS)
		return
	var window := JavaScriptBridge.get_interface("window")
	if window == null:
		DisplayServer.clipboard_set(text)
		on_status.call(CLIPBOARD_STATUS)
		return
	_callback_ref = JavaScriptBridge.create_callback(func(args: Array) -> void:
		# The share sheet can resolve after the scene is gone.
		if on_status.is_valid():
			on_status.call(String(args[0]) if args.size() > 0 else "")
	)
	window.halfStepShareStatus = _callback_ref
	# Every value below is interpolated through JSON.stringify, so it lands in
	# the script as an escaped string literal and cannot close out of it. The
	# page URL is read inside the script rather than passed in, which keeps the
	# only value the game does not control out of the interpolation entirely.
	var script := """
(function(b64, name, title, text, clipboardStatus, unsupportedStatus, cancelledStatus){
  var report = function(message){
    var report_to = window.halfStepShareStatus;
    // One shot: drop the global so nothing else on the page can drive the
    // game's share status afterwards.
    delete window.halfStepShareStatus;
    if (report_to) report_to(message);
  };
  var data = {title: title, text: text, url: location.href};
  var binary = atob(b64);
  var bytes = new Uint8Array(binary.length);
  for (var i = 0; i < binary.length; i++) bytes[i] = binary.charCodeAt(i);
  var file = new File([new Blob([bytes], {type: 'image/png'})], name, {type: 'image/png'});
  (async function(){
    try {
      if (navigator.share) {
        if (navigator.canShare && navigator.canShare({files: [file]})) {
          await navigator.share({title: data.title, text: data.text, url: data.url, files: [file]});
        } else {
          await navigator.share(data);
        }
        report('');
        return;
      }
      if (navigator.clipboard) {
        await navigator.clipboard.writeText(data.text + '\\n' + data.url);
        report(clipboardStatus);
        return;
      }
      report(unsupportedStatus);
    } catch (error) {
      report(cancelledStatus);
    }
  })();
})(%s, %s, %s, %s, %s, %s, %s);
""" % [
		JSON.stringify(Marshalls.raw_to_base64(image.save_png_to_buffer())),
		JSON.stringify("half-step-%d.png" % card_score),
		JSON.stringify("HALF STEP"),
		JSON.stringify(text),
		JSON.stringify(CLIPBOARD_STATUS),
		JSON.stringify(UNSUPPORTED_STATUS),
		JSON.stringify(CANCELLED_STATUS),
	]
	JavaScriptBridge.eval(script, true)

func _draw() -> void:
	var width := float(SIZE.x)
	var height := float(SIZE.y)
	var canvas := Rect2(Vector2.ZERO, Vector2(width, height))
	CssPaint.linear_gradient(self, canvas, 180.0, [[0.0, zone.top], [1.0, zone.bottom]])
	if score >= 210:
		CssPaint.radial_gradient_at(self, Vector2(width * 0.5, 360.0), 560.0, [
			[120.0 / 560.0, Color(1.0, 1.0, 1.0, 0.18)],
			[1.0, Color(1.0, 1.0, 1.0, 0.0)],
		])
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	if float(zone.stars) > 0.3:
		for i in 180:
			var radius := float((i % 3) + 2) * 0.6
			draw_circle(Vector2(rng.randf() * width, rng.randf() * height * 0.6), radius,
				Color(1.0, 1.0, 1.0, 0.9), true, -1.0, true)
	for i in 16:
		var scale := 0.9 + (float(i) / 16.0) * 1.2
		var color := Color("eaf5fc") if i % 2 == 1 else Color("ffffff")
		_draw_cloud(Vector2(60.0 + float(i * 61 % 900), 220.0 + float(i) * 95.0), scale, color)
	for i in 26:
		var top := Vector2(82.0 + float(i * 37 % 920), 180.0 + float(i) * 54.0)
		var length := 44.0 + float(score) / 18.0
		Shapes.capsule(self, top, top + Vector2(0.0, length), 4.0, Color(1.0, 1.0, 1.0, 0.5))
	draw_rect(Rect2(90.0, 90.0, 900.0, 1740.0), Color("08101a", 0.20))
	draw_rect(Rect2(114.0, 114.0, 852.0, 1692.0), Color(1.0, 1.0, 1.0, 0.88))
	_fill_text("HALF STEP", 170.0, 240.0, 58.0, Color("2a3b4b"))
	_center_text(str(score), 560.0, 240.0, Color("24313d"))
	_center_text("REACHED · %s" % zone_name, 650.0, 42.0, Color("6e8292"))
	Shapes.rounded_rect(self, Rect2(350.0, 1010.0, 170.0, 58.0), 18.0, Color("111921"))
	Shapes.rounded_rect(self, Rect2(350.0, 1000.0, 170.0, 56.0), 18.0, Color("25313c"))
	Shapes.fill(self, Shapes.rounded_rect_polygon(Rect2(350.0, 1000.0, 170.0, 22.0),
		Vector4(18.0, 18.0, 0.0, 0.0)), Color("42586d"))
	# The same bird the game draws, scaled up for the card.
	draw_set_transform(Vector2(572.0, 928.0), 0.0, Vector2(2.6, 2.6))
	Art.draw_bird(self)
	draw_set_transform(Vector2.ZERO)
	for i in 8:
		draw_line(Vector2(572.0, 945.0), Vector2(380.0 + float(i) * 52.0, 1220.0 + float(i) * 54.0), Color("24313d", 0.16), 4.0)
	_center_text(ZoneConfig.milestone_tag_for_score(score), 1280.0, 36.0, Color("ef6a5b"))
	_center_text(String(zone.share_line).to_upper(), 1340.0, 30.0, Color("42596d"))
	var y := 1480.0
	for line in ["I MISSED A STEP AND FELL INTO THE SKY.", "HOW FAR CAN YOU GO?"]:
		_center_text(line, y, 28.0, Color("607585"))
		y += 52.0
	_center_text("PLAY. FAIL. SHARE. REPEAT.", 1740.0, 34.0, Color("24313d"))


func _draw_cloud(position: Vector2, scale: float, color: Color) -> void:
	draw_set_transform(position + Art.CLOUD_ORIGIN * scale, 0.0, Vector2(scale, scale))
	Art.draw_cloud(self, color)
	draw_set_transform(Vector2.ZERO)


## `ctx.fillText(text, x, y)` — [param y] is the baseline.
func _fill_text(text: String, x: float, baseline: float, size: float, color: Color) -> void:
	draw_string(CssText.font(), Vector2(x, baseline), text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, int(size), color)


func _center_text(text: String, baseline: float, size: float, color: Color) -> void:
	var width := CssText.width(text, size, 0.0)
	_fill_text(text, (float(SIZE.x) - width) * 0.5, baseline, size, color)
