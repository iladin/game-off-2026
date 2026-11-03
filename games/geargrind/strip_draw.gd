extends RefCounted
## Gear Grind drawing helpers. Each takes the CanvasItem to draw on (game.gd's _draw()).

const Rules := preload("res://games/geargrind/rules.gd")

const BG := Color("0B0E14")
const PANEL := Color("151A24")
const TRACE := Color("1E2738")
const DIM := Color("6B7489")
const INK := Color("E8ECF4")
const ACCENT := Color("FF9F1C")
const GOOD := Color("FFD34D")
const BAD := Color("FF3B5C")

const PX_PER_M := 6.0
const CAR_LEN := 168.0
const FRONT_X := 470.0
const TACH_C := Vector2(640, 712)
const TACH_R := 170.0
const LEVER_RECT := Rect2(1010, 516, 160, 196)
const ROAD_TOP := 196.0
const ROAD_BOT := 476.0


static func text(ci: CanvasItem, s: String, cx: float, base_y: float, size: int, col: Color, w: float = 600.0) -> void:
	ci.draw_string(ThemeDB.fallback_font, Vector2(cx - w * 0.5, base_y), s, HORIZONTAL_ALIGNMENT_CENTER, w, size, col)


static func sx(world_m: float, d: float) -> float:
	return FRONT_X + (world_m - d) * PX_PER_M


static func draw_backdrop(ci: CanvasItem) -> void:
	ci.draw_rect(Rect2(0, 0, 1280, 720), BG)
	for x in range(0, 1281, 40):
		ci.draw_line(Vector2(x, 0), Vector2(x, 720), TRACE, 1.0)
	for y in range(0, 721, 40):
		ci.draw_line(Vector2(0, y), Vector2(1280, y), TRACE, 1.0)


static func draw_road(ci: CanvasItem, d: float) -> void:
	ci.draw_rect(Rect2(0, ROAD_TOP, 1280, ROAD_BOT - ROAD_TOP), PANEL)
	ci.draw_line(Vector2(0, ROAD_TOP), Vector2(1280, ROAD_TOP), TRACE, 2.0)
	ci.draw_line(Vector2(0, ROAD_BOT), Vector2(1280, ROAD_BOT), TRACE, 2.0)
	var x0 := -fposmod(d * PX_PER_M, 96.0)
	var x := x0
	while x < 1280.0:
		ci.draw_rect(Rect2(x, 370, 48, 4), DIM)
		x += 96.0
	for m in range(0, 326, 25):
		var tx := sx(float(m), d)
		if tx > -4.0 and tx < 1284.0:
			ci.draw_line(Vector2(tx, ROAD_TOP), Vector2(tx, ROAD_TOP + 20), TRACE, 2.0)


static func _checker(ci: CanvasItem, x: float) -> void:
	if x < -40.0 or x > 1280.0:
		return
	var y := ROAD_TOP
	var row := 0
	while y < ROAD_BOT:
		for c in 2:
			ci.draw_rect(Rect2(x + c * 16.0, y, 16, minf(16.0, ROAD_BOT - y)), INK if (row + c) % 2 == 0 else PANEL)
		y += 16.0
		row += 1


static func draw_lines_and_tree(ci: CanvasItem, d: float, lit: int, go: bool, tree_m: float) -> void:
	_checker(ci, sx(0.0, d))
	_checker(ci, sx(Rules.TRACK, d))
	var px := sx(tree_m, d)
	if px < -60.0 or px > 1340.0:
		return
	ci.draw_line(Vector2(px, 200), Vector2(px, 470), TRACE, 6.0)
	for i in 3:
		var c := Vector2(px, 228.0 + 40.0 * i)
		if go:
			ci.draw_circle(c, 16.0 * 1.6, Color(GOOD, 0.10))
			ci.draw_circle(c, 16.0 * 1.3, Color(GOOD, 0.25))
			ci.draw_circle(c, 16.0, GOOD)
		elif i < lit:
			ci.draw_circle(c, 16.0 * 1.6, Color(ACCENT, 0.10))
			ci.draw_circle(c, 16.0 * 1.3, Color(ACCENT, 0.25))
			ci.draw_circle(c, 16.0, ACCENT)
		else:
			ci.draw_arc(c, 16.0, 0.0, TAU, 24, DIM, 2.0)


static func _wheel(ci: CanvasItem, c: Vector2, r: float, spin: float) -> void:
	ci.draw_circle(c, r, PANEL)
	ci.draw_arc(c, r, 0.0, TAU, 24, INK, 4.0)
	ci.draw_line(c, c + Vector2(cos(spin), sin(spin)) * (r - 2.0), INK, 2.0)


## p = rear wheel ground point, facing right.
static func draw_car(ci: CanvasItem, p: Vector2, body: Color, cabin: Color, outline_w: float, squash: float, spin: float, glow: bool) -> void:
	ci.draw_set_transform(p, 0.0, Vector2(1.0, squash))
	if glow:
		ci.draw_rect(Rect2(-6, -52 - 6, 168 * 1.3 - 20, 30 * 1.6), Color(body, 0.10))
		ci.draw_rect(Rect2(-3, -52 - 3, 168 * 1.15 - 10, 30 * 1.3), Color(body, 0.25))
	ci.draw_rect(Rect2(0, -52, 168, 30), body)
	ci.draw_rect(Rect2(0, -52, 168, 30), INK, false, outline_w)
	ci.draw_rect(Rect2(52, -74, 64, 22), cabin)
	ci.draw_rect(Rect2(-2, -54, 4, 22), INK)
	ci.draw_rect(Rect2(-6, -76, 30, 6), body)
	_wheel(ci, Vector2(34, -22), 22.0, spin / 22.0)
	_wheel(ci, Vector2(140, -14), 14.0, spin / 14.0)
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


static func draw_flame(ci: CanvasItem, t: float) -> void:
	var tip := Vector2(302.0 - 40.0 - 20.0 * sin(TAU * 12.0 * t), 418)
	ci.draw_colored_polygon(PackedVector2Array([Vector2(302, 410), Vector2(302, 426), tip]), GOOD)
	for i in 3:
		var y := 380.0 + 20.0 * i
		ci.draw_line(Vector2(290, y), Vector2(290 - 60.0 - 30.0 * i, y), INK, 2.0)


static func draw_minimap(ci: CanvasItem, d: float, rival_d: float) -> void:
	ci.draw_line(Vector2(240, 500), Vector2(1040, 500), TRACE, 4.0)
	ci.draw_rect(Rect2(1038, 490, 4, 20), GOOD)
	var rx := 240.0 + 800.0 * rival_d / Rules.TRACK
	ci.draw_rect(Rect2(rx - 6, 479, 12, 12), DIM)
	var px := 240.0 + 800.0 * d / Rules.TRACK
	ci.draw_rect(Rect2(px - 7, 493, 14, 14), ACCENT)


static func _arc(ci: CanvasItem, r0: float, r1: float, col: Color, w: float = 24.0) -> void:
	ci.draw_arc(TACH_C, TACH_R - 14.0, Rules.needle_angle(r0), Rules.needle_angle(r1), 160, col, w)


static func draw_tach(ci: CanvasItem, shown: float, lo: float, hi: float, top_gear: bool, red_t: float, t: float, in_band: bool) -> void:
	_arc(ci, 0.0, 1.0, TRACE)
	var red_col := BAD if (red_t > 0.0 and sin(TAU * 4.0 * t) > 0.0) else Color(BAD, 0.6)
	_arc(ci, 1.0, Rules.RPM_MAX, red_col)
	if top_gear:
		text(ci, "TOP", 880, 700, 28, DIM, 120.0)
	else:
		_arc(ci, lo, hi, ACCENT)
		var c := (lo + hi) * 0.5
		var h := (hi - lo) / 6.0
		_arc(ci, c - h, c + h, GOOD)
		if in_band:
			_arc(ci, lo, hi, Color(ACCENT, 0.3), 36.0)
	for i in 12:
		var a := Rules.needle_angle(0.1 * i)
		var dir := Vector2(cos(a), sin(a))
		ci.draw_line(TACH_C + dir * 150.0, TACH_C + dir * 170.0, INK if i == 10 else DIM, 4.0 if i == 10 else 2.0)
	var na := Rules.needle_angle(shown + (0.015 * sin(TAU * 25.0 * t) if red_t > 0.0 else 0.0))
	ci.draw_line(TACH_C, TACH_C + Vector2(cos(na), sin(na)) * 160.0, INK, 6.0)
	ci.draw_circle(TACH_C, 14.0, INK)


static func draw_gear_box(ci: CanvasItem, gear: int, digit_k: float) -> void:
	ci.draw_rect(Rect2(300, 560, 140, 144), PANEL)
	ci.draw_rect(Rect2(300, 560, 140, 144), TRACE, false, 4.0)
	text(ci, "GEAR", 370, 596, 28, DIM, 140.0)
	var size := int(80.0 * (1.0 + 0.25 * digit_k))
	text(ci, str(gear), 370, 690, size, ACCENT if digit_k > 0.0 else INK, 140.0)


static func draw_lever(ci: CanvasItem, knob_y: float, hot: bool, t: float, label: bool) -> void:
	ci.draw_rect(LEVER_RECT, PANEL)
	if hot:
		ci.draw_rect(LEVER_RECT, Color(ACCENT, 0.5 + 0.5 * sin(TAU * 3.0 * t)), false, 6.0)
	else:
		ci.draw_rect(LEVER_RECT, TRACE, false, 4.0)
	ci.draw_line(Vector2(1090, 556), Vector2(1090, 660), TRACE, 6.0)
	ci.draw_circle(Vector2(1090, knob_y), 36.0, ACCENT)
	ci.draw_arc(Vector2(1090, knob_y), 36.0, 0.0, TAU, 32, INK, 4.0)
	if label:
		text(ci, "SPACE OR TAP", 1090, 702, 20, DIM, 150.0)


static func draw_hud(ci: CanvasItem, score: int, lives: int, wins: int, win_k: float, life_flash: float, banner: String, banner_col: Color, banner_alpha: float) -> void:
	text(ci, str(score), 640, 56, 40, INK, 400.0)
	for i in 3:
		var r := Rect2(598 + 32 * i, 70, 20, 20)
		if i < lives:
			ci.draw_rect(r, ACCENT)
		elif life_flash > 0.0:
			ci.draw_rect(r, BAD)
		else:
			ci.draw_rect(r, DIM, false, 2.0)
	for i in 4:
		var c := Vector2(586.0 + 36.0 * i, 107)
		if i < wins:
			var k := 1.0 + (0.25 * win_k if i == wins - 1 else 0.0)
			ci.draw_rect(Rect2(c.x - 18 * k, c.y - 7 * k, 36 * k, 14 * k), GOOD)
		else:
			ci.draw_rect(Rect2(c.x - 18, c.y - 7, 36, 14), DIM, false, 2.0)
	if banner != "" and banner_alpha > 0.0:
		text(ci, banner, 640, 168, 40, Color(banner_col, banner_alpha), 700.0)
