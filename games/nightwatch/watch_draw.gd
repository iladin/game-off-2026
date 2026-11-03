extends RefCounted
## Night Watch drawing helpers (static). `g` is the game node (reads its state).

const R := preload("res://games/nightwatch/rules.gd")
const BG := Color("0B0E14")
const PANEL := Color("151A24")
const TRACE := Color("1E2738")
const DIM := Color("6B7489")
const INK := Color("E8ECF4")
const ACCENT := Color("8FA8FF")
const GOOD := Color("FFD34D")
const BAD := Color("FF3B5C")
const BODY := Vector2(200.0, 330.0)
const DOOR_LIGHT := [Vector2(0.08, 0.08), Vector2(0.92, 0.08), Vector2(0.5, 0.04)]


static func a(c: Color, al: float) -> Color:
	return Color(c, al)


static func draw_backdrop(ci: CanvasItem) -> void:
	ci.draw_rect(Rect2(0, 0, 1280, 720), BG)
	for x in range(0, 1281, 40):
		ci.draw_line(Vector2(x, 0), Vector2(x, 720), TRACE, 1.0)
	for y in range(0, 721, 40):
		ci.draw_line(Vector2(0, y), Vector2(1280, y), TRACE, 1.0)


static func door_rect(rc: Rect2) -> Rect2:
	var sz := Vector2(rc.size.x * 0.14, rc.size.y * 0.30)
	return Rect2(Vector2(rc.get_center().x - sz.x * 0.5, rc.position.y + rc.size.y * 0.38 - sz.y * 0.5), sz)


static func foot(rc: Rect2, z: float) -> Vector2:
	var dr := door_rect(rc)
	var sc := rc.size.x / 730.0
	return Vector2(rc.get_center().x, lerpf(dr.end.y, rc.end.y - 20.0 * sc, ease(clampf(z, 0.0, 1.0), 2.0)))


static func body_scale(rc: Rect2, z: float) -> float:
	return (0.18 + 0.82 * z) * rc.size.x / 730.0


static func head_pos(rc: Rect2, z: float) -> Vector2:
	var sc := body_scale(rc, z)
	return foot(rc, z) - Vector2(0, BODY.y * sc + 0.1 * BODY.x * sc)


static func creeper_center(rc: Rect2, z: float) -> Vector2:
	return foot(rc, z) - Vector2(0, BODY.y * body_scale(rc, z) * 0.5)


static func draw_hall(ci: CanvasItem, rc: Rect2, feed: int, al: float) -> void:
	var lw := maxf(1.0, 2.0 * rc.size.x / 730.0)
	ci.draw_rect(rc, a(PANEL, al))
	var dr := door_rect(rc)
	var tl := rc.position
	var tr := Vector2(rc.end.x, rc.position.y)
	var bl := Vector2(rc.position.x, rc.end.y)
	var tc := a(TRACE, al)
	ci.draw_line(tl, dr.position, tc, lw)
	ci.draw_line(tr, Vector2(dr.end.x, dr.position.y), tc, lw)
	ci.draw_line(bl, Vector2(dr.position.x, dr.end.y), tc, lw)
	ci.draw_line(rc.end, dr.end, tc, lw)
	for q in [0.25, 0.5, 0.75]:
		var y := foot(rc, q).y
		var k := (y - dr.end.y) / maxf(1.0, rc.end.y - dr.end.y)
		ci.draw_line(Vector2(lerpf(dr.position.x, rc.position.x, k), y), Vector2(lerpf(dr.end.x, rc.end.x, k), y), tc, lw)
	ci.draw_rect(dr, a(BG, al))
	ci.draw_rect(dr, a(DIM, al), false, lw)
	var dl: Vector2 = DOOR_LIGHT[feed]
	ci.draw_circle(rc.position + dl * rc.size, 6.0 * rc.size.x / 730.0 + 1.0, a(DIM, al))


static func blink_on(t: float, feed: int) -> bool:
	return fposmod(t + feed * 0.8, 2.5) > 0.12


static func draw_eyes(ci: CanvasItem, rc: Rect2, z: float, t: float, feed: int, rad: float, col: Color = INK) -> void:
	if not blink_on(t, feed):
		return
	var hp := head_pos(rc, z)
	var sep := 0.066 * BODY.x * body_scale(rc, z)
	ci.draw_circle(hp + Vector2(-sep, 0), rad, col)
	ci.draw_circle(hp + Vector2(sep, 0), rad, col)


static func draw_body(ci: CanvasItem, rc: Rect2, z: float, fill: Color, line: Color, lw: float, grow: float = 1.0) -> void:
	var sc := body_scale(rc, z) * grow
	var f := foot(rc, z)
	var sz := BODY * sc
	var body := Rect2(f - Vector2(sz.x * 0.5, sz.y), sz)
	var hp := head_pos(rc, z) - Vector2(0, (grow - 1.0) * sz.y * 0.0)
	var hr := 0.22 * sz.x
	ci.draw_rect(body, fill)
	ci.draw_circle(hp, hr, fill)
	if line.a > 0.0 and lw > 0.0:
		ci.draw_rect(body, line, false, lw)
		ci.draw_arc(hp, hr, 0.0, TAU, 28, line, lw)


static func draw_creeper(ci: CanvasItem, rc: Rect2, z: float, t: float, feed: int, hints: bool) -> void:
	if z >= R.FLASH_MIN:
		if hints:
			var p := 0.5 + 0.5 * sin(TAU * 3.0 * t)
			draw_body(ci, rc, z, a(ACCENT, 0.25 * (0.6 + 0.4 * p)), Color(0, 0, 0, 0), 0.0, 1.3)
			draw_body(ci, rc, z, a(ACCENT, 0.10 * (0.6 + 0.4 * p)), Color(0, 0, 0, 0), 0.0, 1.6)
		draw_body(ci, rc, z, BG, ACCENT, 4.0)
	draw_eyes(ci, rc, z, t, feed, 3.0 + 7.0 * z)


static func draw_static(ci: CanvasItem, rc: Rect2, n: int, w: float, h: float, col: Color) -> void:
	for i in n:
		ci.draw_rect(Rect2(rc.position.x + randf() * (rc.size.x - w), rc.position.y + randf() * (rc.size.y - h), w, h), col)


static func draw_main(ci: CanvasItem, font: Font, g) -> void:
	var rc: Rect2 = R.MAIN_RECT
	var s = g.watch
	var feed: int = s.watched
	var stat: bool = s.static_t > 0.0
	var off := 0.0
	if g.switch_fx_t > 0.0:
		var p: float = 1.0 - g.switch_fx_t / 0.15
		off = (1.0 - (1.0 - pow(1.0 - p, 3.0))) * 12.0 * g.switch_dir
	ci.draw_set_transform(Vector2(off, 0))
	draw_hall(ci, rc, feed, 0.3 if stat else 1.0)
	if s.awake[feed] and not stat:
		draw_creeper(ci, rc, s.d[feed], g.anim, feed, R.hints_on(g.r))
	if g.flash_fx_t > 0.0 and g.flash_fx_feed == feed:
		var p2: float = 1.0 - g.flash_fx_t / 0.25
		draw_body(ci, rc, g.flash_fx_d * (1.0 - p2), a(INK, 1.0 - p2), Color(0, 0, 0, 0), 0.0)
	if g.jump_t > 0.0:
		draw_body(ci, rc, 1.0, BG, BAD, 6.0)
	ci.draw_set_transform(Vector2.ZERO)
	if stat:
		draw_static(ci, rc, 120, 4.0, 2.0, a(INK, 0.5))
	var frame := ACCENT
	if g.empty_t > 0.0:
		ci.draw_rect(rc, a(BAD, 0.25))
		frame = BAD
	ci.draw_rect(rc, frame, false, 6.0)
	ci.draw_string(font, Vector2(186, 190), str(feed + 1), HORIZONTAL_ALIGNMENT_LEFT, -1, 40, INK)
	var hz := 4.0 if g.band == 2 else 1.0
	if fposmod(g.anim * hz, 1.0) < 0.5:
		ci.draw_circle(Vector2(870, 162), 8.0, BAD)


static func draw_thumbs(ci: CanvasItem, font: Font, g) -> void:
	var s = g.watch
	var hint: int = R.hint_feed(s) if R.hints_on(g.r) else -1
	for i in R.FEEDS:
		var rc: Rect2 = R.THUMB_RECTS[i]
		if g.step_t[i] > 0.0:
			rc.position.y += 4.0 * sin(PI * (1.0 - g.step_t[i] / 0.1))
		if g.squash_t > 0.0 and g.squash_feed == i:
			rc = rc.grow(8.0 * g.squash_t / 0.12)
		if not s.awake[i]:
			ci.draw_rect(rc, PANEL)
			ci.draw_rect(rc, TRACE, false, 2.0)
			ci.draw_string(font, rc.position + Vector2(10, 34), str(i + 1), HORIZONTAL_ALIGNMENT_LEFT, -1, 32, DIM)
			continue
		draw_hall(ci, rc, i, 0.6)
		draw_static(ci, rc, 24, 3.0, 2.0, DIM)
		draw_eyes(ci, rc, s.d[i], g.anim, i, 2.0 + 5.0 * s.d[i])
		ci.draw_string(font, rc.position + Vector2(10, 34), str(i + 1), HORIZONTAL_ALIGNMENT_LEFT, -1, 32, DIM)
		if i == s.watched:
			ci.draw_rect(rc, a(PANEL, 0.8))
			ci.draw_rect(rc, ACCENT, false, 6.0)
			continue
		var bc := TRACE.lerp(BAD, clampf((s.d[i] - 0.4) / 0.5, 0.0, 1.0))
		if s.d[i] >= 0.75:
			bc.a = 0.6 + 0.4 * sin(TAU * 4.0 * g.anim)
		if g.breach_tint_t > 0.0 and g.breach_feed == i:
			ci.draw_rect(rc, a(BAD, 0.35))
		if hint == i:
			ci.draw_rect(rc.grow(10), a(ACCENT, 0.10), false, 6.0)
			ci.draw_rect(rc.grow(5), a(ACCENT, 0.25), false, 4.0)
			bc = ACCENT
			var cy := rc.get_center().y
			ci.draw_colored_polygon(PackedVector2Array([Vector2(902, cy), Vector2(926, cy - 14), Vector2(926, cy + 14)]), ACCENT)
		ci.draw_rect(rc, bc, false, 4.0)


static func draw_lamp(ci: CanvasItem, font: Font, g) -> void:
	var s = g.watch
	var rc: Rect2 = R.LAMP_RECT
	var ready: bool = s.cooldown <= 0.0
	var live: bool = ready and s.awake[s.watched] and s.d[s.watched] >= R.FLASH_MIN
	var pulse := 0.5 + 0.5 * sin(TAU * 3.0 * g.anim)
	ci.draw_rect(rc, PANEL)
	var oc := TRACE
	if g.lamp_blink_t > 0.0:
		oc = DIM
	if live:
		oc = ACCENT
		ci.draw_rect(rc.grow(4), a(ACCENT, 0.15 + 0.2 * pulse), false, 6.0)
	ci.draw_rect(rc, oc, false, 4.0)
	var lc := ACCENT if ready else DIM
	if live:
		ci.draw_circle(Vector2(230, 652), 30.0 + 8.0 * pulse, a(ACCENT, 0.2))
	ci.draw_circle(Vector2(230, 652), 30.0, lc)
	ci.draw_rect(Rect2(290, 640, 590, 24), TRACE)
	ci.draw_rect(Rect2(290, 640, 590.0 * (1.0 - s.cooldown / R.FLASH_COOLDOWN), 24), ACCENT)
	ci.draw_string(font, Vector2(170, 696), "FLASH", HORIZONTAL_ALIGNMENT_CENTER, 730, 28, DIM)


static func draw_clock(ci: CanvasItem, font: Font, g) -> void:
	var c := Vector2(1080, 668)
	ci.draw_circle(c, 44.0, PANEL)
	ci.draw_arc(c, 44.0, 0.0, TAU, 40, GOOD if g.hour_flash_t > 0.0 else DIM, 4.0)
	for k in 12:
		var v := Vector2.from_angle(TAU * k / 12.0)
		ci.draw_line(c + v * 36.0, c + v * 42.0, TRACE, 2.0)
	var th: float = -PI / 2.0 + TAU * (g.t / R.HOUR_LEN) / 12.0
	var tm: float = -PI / 2.0 + TAU * fposmod(g.t, R.HOUR_LEN) / R.HOUR_LEN
	ci.draw_line(c, c + Vector2.from_angle(tm) * 36.0, ACCENT, 4.0)
	ci.draw_line(c, c + Vector2.from_angle(th) * 24.0, INK, 6.0)
	ci.draw_string(font, Vector2(824, 680), R.clock_text(g.t), HORIZONTAL_ALIGNMENT_RIGHT, 200, 28, INK)


static func draw_hud(ci: CanvasItem, font: Font, g) -> void:
	ci.draw_string(font, Vector2(340, 52), str(g.score), HORIZONTAL_ALIGNMENT_CENTER, 600, 40, INK)
	for i in R.LIVES:
		var rc := Rect2(598 + i * 32, 62, 20, 20)
		if i < g.lives:
			ci.draw_rect(rc, ACCENT)
		else:
			ci.draw_rect(rc, DIM, false, 2.0)
			if g.life_flash_t > 0.0 and i == g.lives:
				ci.draw_rect(rc, a(BAD, 1.0))
	if g.banner_t > 0.0 and g.banner_text != "":
		ci.draw_string(font, Vector2(235, 122), g.banner_text, HORIZONTAL_ALIGNMENT_CENTER, 600, 40, a(ACCENT, minf(1.0, g.banner_t / 0.3)))
