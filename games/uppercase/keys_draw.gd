extends RefCounted
## Drawing helpers for Upper Case. All take the CanvasItem to draw on.

const Rules := preload("res://games/uppercase/rules.gd")

const BG := Color("0B0E14")
const PANEL := Color("151A24")
const TRACE := Color("1E2738")
const DIM := Color("6B7489")
const INK := Color("E8ECF4")
const ACCENT := Color("3DDCFF")
const GOOD := Color("FFD34D")
const BAD := Color("FF3B5C")
const SCREEN := Rect2(0, 0, 1280, 720)
const TILE := 64.0
const FALL_END_Y := 494.0
const GLOW_CLIP := Rect2(0, 604, 1280, 116)


static func text(ci: CanvasItem, s: String, center: Vector2, size: int, col: Color) -> void:
	var font: Font = ThemeDB.fallback_font
	ci.draw_string(font, Vector2(center.x - 400.0, center.y + size * 0.35), s, HORIZONTAL_ALIGNMENT_CENTER, 800.0, size, col)


static func draw_backdrop(ci: CanvasItem, columns_x: Array[float]) -> void:
	ci.draw_rect(SCREEN, BG)
	for i in range(0, 1281, 40):
		ci.draw_line(Vector2(i, 0), Vector2(i, 720), TRACE, 1.0)
	for j in range(0, 721, 40):
		ci.draw_line(Vector2(0, j), Vector2(1280, j), TRACE, 1.0)
	for x in columns_x:
		ci.draw_line(Vector2(x, Rules.SPAWN_Y), Vector2(x, 494.0), TRACE, 1.0)



## Repaints the area below the fall so tiles are cut off by their bottom edge at FALL_END_Y.
static func draw_below_fall(ci: CanvasItem) -> void:
	ci.draw_rect(Rect2(0, FALL_END_Y, 1280, 720 - FALL_END_Y), BG)
	for i in range(0, 1281, 40):
		ci.draw_line(Vector2(i, FALL_END_Y), Vector2(i, 720), TRACE, 1.0)
	for j in range(0, 721, 40):
		if j > FALL_END_Y:
			ci.draw_line(Vector2(0, j), Vector2(1280, j), TRACE, 1.0)


static func draw_line_zone(ci: CanvasItem, beat_frac: float) -> void:
	var win := Color(ACCENT, 0.25)
	ci.draw_line(Vector2(200, Rules.LINE_Y - Rules.GOOD_PX), Vector2(1080, Rules.LINE_Y - Rules.GOOD_PX), win, 2.0)
	ci.draw_line(Vector2(200, Rules.LINE_Y + Rules.GOOD_PX), Vector2(1080, Rules.LINE_Y + Rules.GOOD_PX), win, 2.0)
	var a := lerpf(1.0, 0.6, clampf(beat_frac * 2.0, 0.0, 1.0))
	ci.draw_line(Vector2(200, Rules.LINE_Y), Vector2(1080, Rules.LINE_Y), Color(INK, a), 4.0)


static func draw_tile(ci: CanvasItem, pos: Vector2, ch: String, upper: bool, alpha: float, tint: Color, squash: float) -> void:
	if pos.y > Rules.TILE_GONE_Y:
		return
	ci.draw_set_transform(pos, 0.0, Vector2(squash, squash))
	var h := TILE * 0.5
	var r := Rect2(-h, -h, TILE, TILE)
	ci.draw_rect(r, Color(PANEL, alpha))
	var edge := tint if tint.a > 0.0 else (ACCENT if upper else DIM)
	ci.draw_rect(r, Color(edge, alpha), false, 4.0 if upper else 2.0)
	var inkc := tint if tint.a > 0.0 else (INK if upper else DIM)
	text(ci, ch if upper else ch.to_lower(), Vector2(0, -2), 44, Color(inkc, alpha))
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


static func draw_strip(ci: CanvasItem, lit_ch: String, lit_upper: bool, flash_ch: String, flash_a: float) -> void:
	for row in Rules.ROWS.size():
		var s: String = Rules.ROWS[row]
		for col in s.length():
			var ch: String = s[col]
			var r := Rect2(Rules.ROW_X0[row] + col * Rules.KEY_PITCH, Rules.ROW_Y[row], Rules.KEY_W, Rules.KEY_H)
			var fill := PANEL
			var edge := TRACE
			var inkc := DIM
			if ch == lit_ch and lit_upper:
				fill = ACCENT
				inkc = BG
			elif ch == lit_ch:
				edge = DIM
			ci.draw_rect(r, fill)
			ci.draw_rect(r, edge, false, 2.0)
			if ch == flash_ch and flash_a > 0.0:
				ci.draw_rect(r, Color(GOOD, flash_a))
			text(ci, ch, r.get_center() + Vector2(0, -1), 24, inkc)
		var dx: float = Rules.ROW_X0[row] + Rules.SPLIT_COL * Rules.KEY_PITCH - 4.0
		ci.draw_line(Vector2(dx, Rules.ROW_Y[row]), Vector2(dx, Rules.ROW_Y[row] + Rules.KEY_H), TRACE, 2.0)


static func _glow(ci: CanvasItem, rect: Rect2, inset: float, a: float, side: int) -> void:
	# Fixed inset around the hinted key only; never crosses the midpoint of the gap to the other Shift key.
	var big := rect.grow(inset).intersection(GLOW_CLIP)
	var mid := SCREEN.size.x * 0.5
	if side == Rules.LEFT:
		big.end.x = minf(big.end.x, mid)
	else:
		var x0 := maxf(big.position.x, mid)
		big.size.x = big.end.x - x0
		big.position.x = x0
	if big.size.x > 0.0 and big.size.y > 0.0:
		ci.draw_rect(big, Color(ACCENT, a))


static func draw_shift_key(ci: CanvasItem, rect: Rect2, side: int, down: bool, hint: bool, bad: bool, flash: bool, t: float) -> void:
	var r := rect
	if down:
		r.position.y += 6.0
	if hint:
		var pulse := 0.5 + 0.5 * sin(TAU * 3.0 * t)
		_glow(ci, r, 22.0, 0.10, side)
		_glow(ci, r, 10.0, 0.25, side)
		ci.draw_rect(r, PANEL)
		ci.draw_rect(r, Color(ACCENT, pulse), false, 6.0)
	else:
		ci.draw_rect(r, ACCENT if down or flash else PANEL)
		var edge := BAD if bad else (ACCENT if flash else TRACE)
		ci.draw_rect(r, edge, false, 4.0)
	var lit := down or flash
	var inkc := BG if lit else INK
	var c := r.get_center()
	text(ci, "SHIFT", c, 36, inkc)
	var gx: float = r.position.x + 60.0 if side == Rules.LEFT else r.end.x - 60.0
	var o := Vector2(gx, c.y)
	var pts := PackedVector2Array([Vector2(0, -21), Vector2(20, 3), Vector2(10, 3), Vector2(10, 21), Vector2(-10, 21), Vector2(-10, 3), Vector2(-20, 3), Vector2(0, -21)])
	for i in pts.size():
		pts[i] += o
	ci.draw_polyline(pts, inkc, 4.0)
	var lx: float = r.end.x - 30.0 if side == Rules.LEFT else r.position.x + 30.0
	text(ci, "F" if side == Rules.LEFT else "J", Vector2(lx, r.end.y - 28.0), 32, BG if lit else DIM)


static func draw_hud(ci: CanvasItem, score: int, lives: int, max_lives: int, life_flash: float, lost_idx: int, progress: float, banner: String, banner_alpha: float, score_scale: float) -> void:
	ci.draw_set_transform(Vector2(640, 40), 0.0, Vector2(score_scale, score_scale))
	text(ci, "%d" % score, Vector2(0, 0), 40, INK)
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	for i in max_lives:
		var r := Rect2(598 + i * 32, 70, 20, 20)
		if i < lives:
			ci.draw_rect(r, ACCENT)
		elif i == lost_idx and life_flash > 0.0:
			ci.draw_rect(r, BAD)
		else:
			ci.draw_rect(r, DIM, false, 2.0)
	var bar := Rect2(440, 100, 400, 8)
	ci.draw_rect(Rect2(bar.position, Vector2(bar.size.x * clampf(progress, 0.0, 1.0), bar.size.y)), ACCENT)
	ci.draw_rect(bar, TRACE, false, 2.0)
	if banner != "" and banner_alpha > 0.0:
		text(ci, banner, Vector2(640, 154), 40, Color(ACCENT, banner_alpha))
