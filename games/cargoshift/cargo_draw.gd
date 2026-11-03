extends RefCounted
## Cargo Shift drawing helpers (static, take the CanvasItem to draw on).

const R := preload("res://games/cargoshift/rules.gd")

const BG := Color("0B0E14")
const PANEL := Color("151A24")
const TRACE := Color("1E2738")
const DIM := Color("6B7489")
const INK := Color("E8ECF4")
const ACCENT := Color("2DD4BF")
const GOOD := Color("FFD34D")
const BAD := Color("FF3B5C")
const PIVOT := Vector2(640, 440)
const SEA_Y := 470.0
const DECK_RANGE := 264.0
const BALLAST_RANGE := 240.0
const BALLAST_Y := 55.0
const CRATE_SIZE := 72.0
const LEFT_PAD := Rect2(170, 616, 300, 96)
const RIGHT_PAD := Rect2(810, 616, 300, 96)
const PAD_DOWN_PX := 6.0


static func ease_back(x: float) -> float:
	var c1 := 1.70158
	var c3 := c1 + 1.0
	return 1.0 + c3 * pow(x - 1.0, 3.0) + c1 * pow(x - 1.0, 2.0)


static func draw_backdrop(ci: CanvasItem) -> void:
	ci.draw_rect(Rect2(0, 0, 1280, 720), BG)
	for i in range(0, 33):
		ci.draw_line(Vector2(i * 40, 0), Vector2(i * 40, 720), TRACE, 1.0)
	for j in range(0, 19):
		ci.draw_line(Vector2(0, j * 40), Vector2(1280, j * 40), TRACE, 1.0)


static func _sea_pts(t: float, dy: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in 33:
		var x := i * 40.0
		pts.append(Vector2(x, SEA_Y + dy + 10.0 * sin(x / 90.0 + t * 1.3) + 6.0 * sin(x / 37.0 - t * 2.1)))
	return pts


static func draw_sea(ci: CanvasItem, t: float) -> void:
	var top := _sea_pts(t, 0.0)
	var poly := PackedVector2Array(top)
	poly.append(Vector2(1280, 720))
	poly.append(Vector2(0, 720))
	ci.draw_colored_polygon(poly, PANEL)
	ci.draw_polyline(top, TRACE, 2.0)
	ci.draw_polyline(_sea_pts(t, 24.0), Color(TRACE, 0.5), 2.0)


static func glow_rect(ci: CanvasItem, c: Vector2, size: Vector2, col: Color) -> void:
	ci.draw_rect(Rect2(c - size * 0.8, size * 1.6), Color(col, 0.10))
	ci.draw_rect(Rect2(c - size * 0.65, size * 1.3), Color(col, 0.25))


## fx: shift_fx_t, shift_fx_dir, squash_t, stop_flash_t, thud_t, thud_i, fail_tint_t, crate3_drop_t, hint_side
static func draw_ship(ci: CanvasItem, s: R.Ship, t: float, hint_side: int, fx: Dictionary, top_pass: bool) -> void:
	ci.draw_set_transform(PIVOT, s.tilt)
	if top_pass:
		_draw_ballast(ci, s, t, hint_side, fx)
		ci.draw_set_transform(Vector2.ZERO, 0.0)
		return
	var hull := PackedVector2Array([Vector2(-340, -20), Vector2(340, -20), Vector2(260, 110), Vector2(-260, 110)])
	ci.draw_colored_polygon(hull, PANEL)
	var outline := PackedVector2Array(hull)
	outline.append(hull[0])
	ci.draw_polyline(outline, INK, 4.0)
	ci.draw_line(Vector2(-340, -20), Vector2(340, -20), INK, 6.0)
	ci.draw_rect(Rect2(-338, -56, 4, 36), INK)
	ci.draw_rect(Rect2(334, -56, 4, 36), INK)
	ci.draw_line(Vector2(0, -20), Vector2(0, -200), DIM, 4.0)
	ci.draw_line(Vector2(0, -200), Vector2(-336, -56), DIM, 2.0)
	ci.draw_line(Vector2(0, -200), Vector2(336, -56), DIM, 2.0)
	_draw_crates(ci, s, fx)
	ci.draw_set_transform(Vector2.ZERO, 0.0)


static func _draw_ballast(ci: CanvasItem, s: R.Ship, t: float, hint_side: int, fx: Dictionary) -> void:
	# ballast rail
	ci.draw_line(Vector2(-240, BALLAST_Y), Vector2(240, BALLAST_Y), DIM, 2.0)
	ci.draw_line(Vector2(-240, BALLAST_Y - 12), Vector2(-240, BALLAST_Y + 12), DIM, 4.0)
	ci.draw_line(Vector2(240, BALLAST_Y - 12), Vector2(240, BALLAST_Y + 12), DIM, 4.0)
	# ballast
	var bc := Vector2(s.ballast * BALLAST_RANGE, BALLAST_Y)
	var bsz := Vector2(96, 44)
	var sq: float = fx["squash_t"]
	if sq > 0.0:
		var k := sq / 0.12
		bsz = Vector2(96 * lerpf(1.0, 1.25, k), 44 * lerpf(1.0, 0.8, k))
	var fill := ACCENT
	if fx["stop_flash_t"] > 0.0:
		fill = INK
	if fx["fail_tint_t"] > 0.0:
		fill = BAD
	var sft: float = fx["shift_fx_t"]
	if sft > 0.0:
		var wd: int = fx["shift_fx_dir"]
		var a := sft / 0.2
		ci.draw_line(bc - Vector2(wd * 48, 0), bc - Vector2(wd * (48 + 40), 0), Color(ACCENT, 0.6 * a), 2.0)
	glow_rect(ci, bc, bsz, ACCENT)
	var br := Rect2(bc - bsz * 0.5, bsz)
	ci.draw_rect(br, fill)
	ci.draw_rect(br, INK, false, 6.0)
	if hint_side != 0:
		var hx := float(hint_side) * (BALLAST_RANGE + 96.0)
		var d := float(hint_side)
		var tri := PackedVector2Array([Vector2(hx + d * 20, BALLAST_Y), Vector2(hx - d * 20, BALLAST_Y - 18), Vector2(hx - d * 20, BALLAST_Y + 18)])
		ci.draw_colored_polygon(tri, Color(ACCENT, 0.55 + 0.45 * sin(TAU * 3.0 * t)))


static func draw_waves(ci: CanvasItem, waves: Array, t: float) -> void:
	for w: R.Wave in waves:
		if t >= w.t_hit + R.WAVE_HIT:
			continue
		var edge := 40.0 if w.side < 0 else 1240.0
		var near := 300.0 if w.side < 0 else 980.0
		var u := clampf((t - (w.t_hit - R.WAVE_WARN)) / R.WAVE_WARN, 0.0, 1.0)
		var cx := lerpf(edge, near, u * u)
		var h := 70.0
		if t >= w.t_hit:
			var k := (t - w.t_hit) / R.WAVE_HIT
			h = 70.0 * (1.0 - k)
			cx += -float(w.side) * -120.0 * k * -1.0
		var base := SEA_Y + 6.0
		var pts := PackedVector2Array([Vector2(cx - 80, base), Vector2(cx - 30, base - h), Vector2(cx + 30, base - h), Vector2(cx + 80, base)])
		ci.draw_colored_polygon(pts, Color(ACCENT, 0.35))
		ci.draw_line(pts[1], pts[2], ACCENT, 4.0)


static func draw_rain(ci: CanvasItem, t: float, bright: bool) -> void:
	var a := 0.7 if bright else 0.4
	for i in 60:
		var x := fmod(float(i) * 197.0 + 31.0, 1280.0)
		var y0 := fmod(float(i) * 83.0 + t * 900.0, 540.0) + 180.0
		ci.draw_line(Vector2(x, y0), Vector2(x - 8, y0 + 24), Color(DIM, a), 2.0)


static func draw_pads(ci: CanvasItem, dir: int, hint_side: int) -> void:
	for side in [-1, 1]:
		var r: Rect2 = LEFT_PAD if side < 0 else RIGHT_PAD
		var pressed: bool = dir == side
		if pressed:
			r.position.y += PAD_DOWN_PX
		ci.draw_rect(r, ACCENT if pressed else PANEL)
		ci.draw_rect(r, ACCENT if hint_side == side else TRACE, false, 4.0)
		var c := r.get_center()
		var d := float(side)
		var tri := PackedVector2Array([Vector2(c.x + d * 28, c.y), Vector2(c.x - d * 28, c.y - 24), Vector2(c.x - d * 28, c.y + 24)])
		ci.draw_colored_polygon(tri, BG if pressed else INK)


static func draw_hud(ci: CanvasItem, font: Font, score: int, lives: int, life_flash_t: float, tilt: float,
		progress: float, banner: String, banner_alpha: float, tick_flash_t: float) -> void:
	ci.draw_string(font, Vector2(170, 52), str(score), HORIZONTAL_ALIGNMENT_CENTER, 920, 40, INK)
	for i in R.LIVES:
		var rc := Rect2(598 + i * 32, 62, 20, 20)
		if i < lives:
			ci.draw_rect(rc, ACCENT)
		else:
			ci.draw_rect(rc, BAD if life_flash_t > 0.0 and i == lives else DIM, life_flash_t > 0.0 and i == lives, 2.0)
	ci.draw_rect(Rect2(440, 92, 400, 12), TRACE)
	var bw := 640.0 * 0.0 + 200.0 * R.LEVEL_BAND / R.CAPSIZE
	ci.draw_rect(Rect2(640 - bw, 92, bw * 2, 12), Color(GOOD, 1.0 if tick_flash_t > 0.0 else 0.45))
	ci.draw_rect(Rect2(440, 92, 4, 12), BAD)
	ci.draw_rect(Rect2(836, 92, 4, 12), BAD)
	var nx := 640.0 + 200.0 * clampf(tilt / R.CAPSIZE, -1.0, 1.0)
	ci.draw_rect(Rect2(nx - 3, 87, 6, 22), BAD if absf(tilt) > 0.3 else INK)
	ci.draw_rect(Rect2(340, 116, 600, 6), TRACE)
	ci.draw_rect(Rect2(340, 116, 600.0 * clampf(progress, 0.0, 1.0), 6), ACCENT)
	ci.draw_rect(Rect2(936, 110, 4, 16), GOOD)
	if banner != "" and banner_alpha > 0.0:
		ci.draw_string(font, Vector2(170, 172), banner, HORIZONTAL_ALIGNMENT_CENTER, 920, 40, Color(ACCENT, banner_alpha))


static func _draw_crates(ci: CanvasItem, s: R.Ship, fx: Dictionary) -> void:
	# crates
	for i in s.cargo.size():
		var cy := -56.0
		var drop: float = fx["crate3_drop_t"]
		if i == 2 and drop > 0.0:
			cy = lerpf(-56.0, -300.0, 1.0 - ease_back(1.0 - drop / 0.25))
		var sz := Vector2(CRATE_SIZE, CRATE_SIZE)
		var col := ACCENT
		if fx["thud_t"] > 0.0 and fx["thud_i"] == i:
			sz = Vector2(CRATE_SIZE * 0.8, CRATE_SIZE * 1.2)
			col = BAD
		var c := Vector2(s.cargo[i] * DECK_RANGE, cy)
		var rc := Rect2(c - sz * 0.5, sz)
		ci.draw_rect(rc, PANEL)
		ci.draw_rect(rc, col, false, 4.0)
		ci.draw_line(rc.position, rc.end, col, 2.0)
		ci.draw_line(Vector2(rc.end.x, rc.position.y), Vector2(rc.position.x, rc.end.y), col, 2.0)
