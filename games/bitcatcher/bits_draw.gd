extends RefCounted
## Bit Catcher drawing helpers. All static, take the CanvasItem to draw on.

const R := preload("res://games/bitcatcher/rules.gd")

const BG := Color("0B0E14")
const PANEL := Color("151A24")
const TRACE := Color("1E2738")
const DIM := Color("6B7489")
const INK := Color("E8ECF4")
const ACCENT := Color("A3E635")
const GOOD := Color("FFD34D")
const BAD := Color("FF3B5C")
const SLIDE_TIME := 0.10
const WRAP_SPAN := 896.0


static func text(ci: CanvasItem, cx: float, base: float, s: String, size: int, col: Color) -> void:
	ci.draw_string(ThemeDB.fallback_font, Vector2(cx - 300.0, base), s, HORIZONTAL_ALIGNMENT_CENTER, 600.0, size, col)


static func glow(ci: CanvasItem, rect: Rect2, col: Color) -> void:
	for k in [[1.3, 0.25], [1.6, 0.10]]:
		var d: Vector2 = rect.size * (float(k[0]) - 1.0) * 0.5
		var g := Rect2(rect.position - d, rect.size + d * 2.0)
		ci.draw_rect(g, Color(col, float(k[1])))


static func draw_backdrop(ci: CanvasItem, t: float) -> void:
	ci.draw_rect(Rect2(0, 0, 1280, 720), BG)
	for i in range(0, 1281, 40):
		ci.draw_line(Vector2(i, 0), Vector2(i, 720), TRACE, 1.0)
	for j in range(0, 721, 40):
		ci.draw_line(Vector2(0, j), Vector2(1280, j), TRACE, 1.0)
	for c in R.CELLS:
		ci.draw_line(Vector2(R.col_x(c), 180), Vector2(R.col_x(c), 480), TRACE, 1.0)
	ci.draw_rect(Rect2(186, 470, 908, 120), PANEL)
	ci.draw_rect(Rect2(186, 470, 908, 120), TRACE, false, 2.0)
	ci.draw_line(Vector2(186, 596), Vector2(1094, 596), TRACE, 2.0)
	var off := fmod(t * 120.0, 112.0)
	var x := 186.0 + off
	while x < 1094.0:
		ci.draw_rect(Rect2(x - 2, 594, 4, 4), INK)
		x += 112.0


static func _cell(ci: CanvasItem, c: int, dx: float, reg: int, target: int, t: float, a: float,
		sc: float, flash: float, bad: float, pop: float) -> void:
	var cx := R.col_x(c) + dx
	var r := Rect2(cx - 50, R.REG_Y, 100, 100)
	var one := R.bit_at(reg, c) == 1
	var sock := R.bit_at(target, c) == 1
	if sc != 1.0:
		r = Rect2(r.get_center() - r.size * sc * 0.5, r.size * sc)
	if one and sock:
		if a > 0.5:
			glow(ci, r, Color(ACCENT, a))
		ci.draw_rect(r, Color(ACCENT, a))
		text(ci, cx, r.position.y + 70.0 * sc, "1", int(56 * sc), Color(BG, a))
	else:
		ci.draw_rect(r, Color(PANEL, a))
		ci.draw_rect(r, Color(TRACE, a), false, 2.0)
		if sock:
			var sr := r
			if pop < 1.0:
				var s := 0.6 + 0.4 * ease_back(pop)
				sr = Rect2(r.get_center() - r.size * s * 0.5, r.size * s)
			var al := (0.55 + 0.45 * sin(TAU * 2.0 * t)) * a
			ci.draw_rect(sr, Color(ACCENT, al), false, 4.0)
			ci.draw_rect(Rect2(r.position.x, r.end.y - 6.0, r.size.x, 6.0), Color(ACCENT, a))
		text(ci, cx, r.position.y + 66.0 * sc, "0", int(48 * sc), Color(DIM, a))
	if flash > 0.0:
		ci.draw_rect(r, Color(GOOD, 0.6 * a))
	if bad > 0.0:
		ci.draw_rect(r, Color(BAD, a), false, 4.0)



static func ease_back(p: float) -> float:
	var k := 1.70158
	var q := p - 1.0
	return 1.0 + (k + 1.0) * q * q * q + k * q * q


static func draw_register(ci: CanvasItem, reg: int, target: int, slide_px: float, prog: float, wrap_col: int,
		squash_c: int, squash: float, flash_t: float, bad_c: int, bad_t: float, pop: float, t: float) -> void:
	for c in R.CELLS:
		var a := 1.0
		if c == wrap_col and prog < 1.0:
			a = prog
			var gx := slide_px - WRAP_SPAN if slide_px > 0.0 else slide_px + WRAP_SPAN
			_cell(ci, c, gx, reg, target, t, 1.0 - prog, 1.0, 0.0, 0.0, 1.0)
		var sc := squash if c == squash_c else 1.0
		_cell(ci, c, slide_px, reg, target, t, a, sc, flash_t, bad_t if c == bad_c else 0.0, pop)


static func draw_bit(ci: CanvasItem, pos: Vector2, is_one: bool, alpha: float, tint: float, fast: bool) -> void:
	if fast:
		for k in 3:
			_bit(ci, pos - Vector2(0, 24.0 * (k + 1)), is_one, alpha * (0.30 - 0.10 * k), 0.0)
	_bit(ci, pos, is_one, alpha, tint)


static func _bit(ci: CanvasItem, pos: Vector2, is_one: bool, a: float, tint: float) -> void:
	var r := Rect2(pos - Vector2(40, 40), Vector2(80, 80))
	var edge := ACCENT if is_one else DIM
	if tint > 0.0:
		edge = BAD
	if is_one:
		glow(ci, r, Color(ACCENT, a))
	ci.draw_rect(r, Color(PANEL, a))
	ci.draw_rect(r, Color(edge, a), false, 4.0 if is_one else 2.0)
	text(ci, pos.x, pos.y + 20.0, "1" if is_one else "0", 56, Color(INK if is_one else DIM, a))


static func draw_hint(ci: CanvasItem, col: int, bit_y: float, good: bool, t: float) -> void:
	var col_c := ACCENT if good else BAD
	var x := R.col_x(col)
	ci.draw_line(Vector2(x, bit_y + 40.0), Vector2(x, R.REG_Y), Color(col_c, 0.5), 4.0)
	var pulse := 0.6 + 0.4 * sin(TAU * 3.0 * t)
	ci.draw_rect(Rect2(x - 50, R.REG_Y, 100, 100), Color(col_c, 0.5 * pulse + 0.3), false, 6.0)


static func draw_pads(ci: CanvasItem, pads: Array[Rect2], down: Array[bool]) -> void:
	for i in 3:
		var r := pads[i]
		var d := down[i]
		if d:
			r.position.y += 6.0
		ci.draw_rect(r, ACCENT if d else PANEL)
		ci.draw_rect(r, TRACE, false, 4.0)
		var ctr := r.get_center()
		var col := BG if d else INK
		var pts := PackedVector2Array()
		if i == R.LEFT:
			pts = PackedVector2Array([ctr + Vector2(-24, 0), ctr + Vector2(24, -28), ctr + Vector2(24, 28)])
		elif i == R.RIGHT:
			pts = PackedVector2Array([ctr + Vector2(24, 0), ctr + Vector2(-24, -28), ctr + Vector2(-24, 28)])
		else:
			pts = PackedVector2Array([ctr + Vector2(0, 24), ctr + Vector2(-28, -24), ctr + Vector2(28, -24)])
		ci.draw_colored_polygon(pts, col)


static func draw_hud(ci: CanvasItem, score: int, lives: int, max_lives: int, life_flash: float, bytes_done: int,
		byte_squash: float, banner: String, banner_a: float) -> void:
	text(ci, 640, 56, str(score), 40, INK)
	for i in max_lives:
		var r := Rect2(598 + i * 32, 66, 20, 20)
		if i < lives:
			ci.draw_rect(r, ACCENT)
		else:
			ci.draw_rect(r, Color(BAD, 0.8) if (life_flash > 0.0 and i == lives) else PANEL)
			ci.draw_rect(r, DIM, false, 2.0)
	var s := R.bytes_string(bytes_done)
	for i in R.CELLS:
		var on := s[i] == "1"
		var sz := 28
		if on and i == bytes_done - 1 and byte_squash > 1.0:
			sz = int(28 * byte_squash)
		text(ci, 640.0 + (i - 3.5) * 22.0, 112, s[i], sz, GOOD if on else DIM)
	if banner != "" and banner_a > 0.0:
		text(ci, 640, 168, banner, 40, Color(ACCENT, banner_a))


## Whole scene for the game node g (reads its state).
static func draw_scene(g: Node2D) -> void:
	var fx = g.fx
	var inp = g.inp
	var now := Time.get_ticks_msec() / 1000.0
	draw_backdrop(g, now)
	var sp: float = 0.0
	if fx.slide_t < 1.0:
		sp = fx.slide_dir * R.CELL_PITCH * pow(1.0 - fx.slide_t, 3.0)
	var sq: float = 1.0
	if fx.squash_t > 0.0:
		sq = 1.0 + 0.25 * sin(PI * (1.0 - fx.squash_t / g.SQUASH_TIME))
	draw_register(g, g.reg, g.target, sp, fx.slide_t, fx.wrap_col, fx.squash_c, sq, fx.byte_flash_t,
			fx.bad_c, fx.bad_t, fx.pop_t, now)
	if fx.hint_flash_t > 0.0 and int(fx.hint_flash_t / (g.HINT_FLASH_TIME / 4.0)) % 2 == 1:
		for c in R.CELLS:
			if R.bit_at(g.target, c) == 1 and R.bit_at(g.reg, c) == 0:
				g.draw_rect(Rect2(R.col_x(c) - 50 + sp, R.REG_Y, 100, 100), Color(ACCENT, 0.4))
	if fx.ring_t > 0.0 and fx.ring_c >= 0:
		g.draw_rect(Rect2(R.col_x(fx.ring_c) - 56, R.REG_Y - 6, 112, 112), INK, false, 2.0)
	if g.bit_alive:
		if R.hints_on(g._ramp()):
			var good: bool = R.land_one(g.reg, g.target, g.bit_col) == R.SET if g.bit_one \
					else R.land_zero(g.reg, g.bit_col) == R.DODGE
			draw_hint(g, g.bit_col, g.bit_y, good, now)
		draw_bit(g, Vector2(R.col_x(g.bit_col), g.bit_y), g.bit_one, minf(1.0, g.bit_age / g.FADE_IN),
				1.0 if fx.tint_t > 0.0 else 0.0, g.fast)
	var pads: Array[Rect2] = [inp.LEFT_PAD, inp.RIGHT_PAD, inp.DROP_PAD]
	var down: Array[bool] = [fx.pad_down_t[0] > 0.0, fx.pad_down_t[1] > 0.0,
			fx.pad_down_t[2] > 0.0 or inp.drop_key or inp.drop_touch]
	draw_pads(g, pads, down)
	var bsq: float = 1.0 + 0.25 * (fx.byte_squash_t / g.SQUASH_TIME)
	draw_hud(g, g.score, g.lives, g.LIVES, fx.life_flash_t, g.bytes_done, bsq, fx.banner_text,
			minf(1.0, fx.banner_t / 0.3))
