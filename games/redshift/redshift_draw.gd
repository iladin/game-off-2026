extends RefCounted
## Red Shift drawing helpers (static). `g` is the game node (reads its state).

const R := preload("res://games/redshift/rules.gd")
const Bot := preload("res://games/redshift/rules_bot.gd")
const BG := Color("0B0E14")
const PANEL := Color("151A24")
const TRACE := Color("1E2738")
const DIM := Color("6B7489")
const INK := Color("E8ECF4")
const GOOD := Color("FFD34D")
const BAD := Color("FF3B5C")
const EMBER := Color("FF7A45")
const BAND_COL := [Color("FF7A45"), Color("A3E635"), Color("3D7BFF")]
const STAR_SPEED := [40.0, 90.0, 160.0]
const STAR_ALPHA := [0.25, 0.4, 0.6]
const STREAK_LEN := 14.0
const GRID_SPEED := 120.0
const ENEMY_DRAW := 24.0
const HEAVY_SCALE := 1.5


static func a(c: Color, al: float) -> Color:
	return Color(c, al)


## Band emblem: 0 square, 1 triangle (points along dir), 2 circle. `size` is the half extent.
static func emblem(ci: CanvasItem, band: int, pos: Vector2, size: float, col: Color, width: float, filled: bool, dir: float = 1.0) -> void:
	if band == 0:
		ci.draw_rect(Rect2(pos - Vector2(size, size), Vector2(size, size) * 2.0), col, filled, width)
	elif band == 1:
		var pts := PackedVector2Array([pos + Vector2(dir * size, 0), pos + Vector2(-dir * size, -size), pos + Vector2(-dir * size, size)])
		if filled:
			ci.draw_colored_polygon(pts, col)
		else:
			pts.append(pts[0])
			ci.draw_polyline(pts, col, width)
	elif filled:
		ci.draw_circle(pos, size, col)
	else:
		ci.draw_arc(pos, size, 0.0, TAU, 32, col, width)


static func glow(ci: CanvasItem, band: int, pos: Vector2, size: float, col: Color, dir: float = 1.0) -> void:
	emblem(ci, band, pos, size * 1.3, a(col, 0.25), 1.0, true, dir)
	emblem(ci, band, pos, size * 1.6, a(col, 0.10), 1.0, true, dir)


static func text(ci: CanvasItem, s: String, pos: Vector2, size: int, col: Color, width: float = -1.0, align: int = HORIZONTAL_ALIGNMENT_LEFT) -> void:
	ci.draw_string(ThemeDB.fallback_font, pos, s, align, width, size, col)


static func draw_space(ci: CanvasItem, g) -> void:
	ci.draw_rect(Rect2(0, 0, 1280, 720), BG)
	var gx: float = g.grid_x
	for i in 33:
		ci.draw_line(Vector2(i * 40.0 - gx, 0), Vector2(i * 40.0 - gx, 720), TRACE, 1.0)
	for y in range(0, 721, 40):
		ci.draw_line(Vector2(0, y), Vector2(1280, y), TRACE, 1.0)
	var k: float = g.run.k
	for l in 3:
		var col: Color = INK if l < 2 else g.band_col_now
		var al: float = STAR_ALPHA[l] if l < 2 else 0.5
		var ln := 2.0 + STREAK_LEN * maxf(0.0, k - 0.75) * (l + 1)
		for p in g.stars[l]:
			ci.draw_line(p, p + Vector2(ln, 0), a(col, al), 2.0)


static func draw_ship(ci: CanvasItem, g) -> void:
	var s: R.Run = g.run
	if s.invuln > 0.0 and int(g.anim / 0.05) % 2 == 0:
		return
	var col: Color = BAD if g.tint_t > 0.0 else BAND_COL[s.band]
	var c := Vector2(R.SHIP_X, s.ship_y)
	var sq := 1.0 + 0.25 * clampf((g.shift_fx_t - 0.13) / 0.12, 0.0, 1.0)
	var fl := 12.0 + 30.0 * (s.k - 0.75)
	ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-34, -8), c + Vector2(-34 - fl, 0), c + Vector2(-34, 8)]), a(col, 0.8))
	var pts := PackedVector2Array([c + Vector2(32 * sq, 0), c + Vector2(-32 * sq, -20), c + Vector2(-32 * sq, 20)])
	ci.draw_colored_polygon(PackedVector2Array([c + Vector2(41.6 * sq, 0), c + Vector2(-41.6 * sq, -26), c + Vector2(-41.6 * sq, 26)]), a(col, 0.25))
	ci.draw_colored_polygon(PackedVector2Array([c + Vector2(51.2 * sq, 0), c + Vector2(-51.2 * sq, -32), c + Vector2(-51.2 * sq, 32)]), a(col, 0.10))
	ci.draw_colored_polygon(pts, PANEL)
	pts.append(pts[0])
	ci.draw_polyline(pts, col, 6.0)
	emblem(ci, s.band, c + Vector2(-14, 0), 7.0, col, 2.0, true)
	if g.shift_fx_t > 0.0:
		var p: float = 1.0 - g.shift_fx_t / 0.25
		ci.draw_arc(c, 24.0 + 66.0 * p, 0.0, TAU, 40, a(g.fx_col, 1.0 - p), 6.0)


static func draw_bullets(ci: CanvasItem, g) -> void:
	for b in g.run.bullets:
		var col: Color = BAND_COL[b.band]
		ci.draw_circle(b.pos, R.BULLET_R * 1.6, a(col, 0.10))
		ci.draw_circle(b.pos, R.BULLET_R * 1.3, a(col, 0.25))
		ci.draw_circle(b.pos, R.BULLET_R, col)
		ci.draw_arc(b.pos, R.BULLET_R, 0.0, TAU, 16, BG, 2.0)


static func draw_enemies(ci: CanvasItem, g) -> void:
	var s: R.Run = g.run
	var hints: bool = R.hints_on(g.r)
	for e in s.enemies:
		var col: Color = BAND_COL[e.band]
		var sz: float = ENEMY_DRAW * (HEAVY_SCALE if e.heavy else 1.0)
		var match_b: bool = e.band == s.band
		var fl: float = g.hit_flash.get(e, 0.0)
		var sq: float = 1.0 + 0.25 * clampf(fl / 0.06, 0.0, 1.0)
		if match_b:
			var pul := 0.75 + 0.25 * sin(g.anim * TAU * 3.0)
			if hints:
				glow(ci, e.band, e.pos, sz * sq, col, -1.0)
			emblem(ci, e.band, e.pos, sz * sq, BG, 1.0, true, -1.0)
			if fl > 0.0:
				emblem(ci, e.band, e.pos, sz * sq, INK, 1.0, true, -1.0)
			emblem(ci, e.band, e.pos, sz * sq, a(col, pul), 4.0, false, -1.0)
		else:
			emblem(ci, e.band, e.pos, sz, BG, 1.0, true, -1.0)
			emblem(ci, e.band, e.pos, sz, a(col, 0.55), 4.0, false, -1.0)
		if e.heavy:
			for i in e.hp:
				ci.draw_rect(Rect2(e.pos.x + e.radius + 6, e.pos.y - 14 + i * 12, 8, 8), INK)
	for kr in g.kill_rings:
		var p: float = 1.0 - kr.t / 0.2
		emblem(ci, kr.band, kr.pos, (26.0 if not kr.heavy else 36.0) * (1.0 + 0.8 * p), a(BAND_COL[kr.band], 1.0 - p), 3.0, false, -1.0)
	for sp in g.sparks:
		var q: Vector2 = sp.pos
		ci.draw_line(q + Vector2(-4, -4), q + Vector2(4, 4), DIM, 2.0)
		ci.draw_line(q + Vector2(-4, 4), q + Vector2(4, -4), DIM, 2.0)


static func draw_shots(ci: CanvasItem, g) -> void:
	for sh in g.run.shots:
		ci.draw_rect(Rect2(sh.pos - Vector2(8, 2), Vector2(16, 4)), BAND_COL[sh.band])


static func draw_pads(ci: CanvasItem, g) -> void:
	var s: R.Run = g.run
	ci.draw_line(Vector2(0, 594), Vector2(1280, 594), TRACE, 2.0)
	var tgt := Bot.target(s)
	var hint := R.teach_pad(g.r, s.band, tgt.band if tgt != null else -1)
	for i in 2:
		var rc: Rect2 = R.BRAKE_RECT if i == 0 else R.BOOST_RECT
		var nb := s.band - 1 if i == 0 else s.band + 1
		var dead := nb < 0 or nb > 2
		var col: Color = DIM if dead else BAND_COL[nb]
		if g.pad_dead[i] and g.pad_t[i] > 0.0:
			col = DIM
		var want := (hint < 0 and i == 0) or (hint > 0 and i == 1)
		if want:
			glow_rect(ci, rc, col, 0.5 + 0.5 * sin(g.anim * TAU * 3.0))
		ci.draw_rect(rc, PANEL)
		if g.pad_t[i] > 0.0:
			ci.draw_rect(rc, a(col, 0.35))
		ci.draw_rect(rc, TRACE, false, 4.0)
		ci.draw_rect(Rect2(rc.position, Vector2(rc.size.x, 6)), col)
		var cx := rc.get_center().x
		var d := -1.0 if i == 0 else 1.0
		var chip := Rect2(cx - 40, 608, 80, 32)  # hue chip: the colour and shape you become
		ci.draw_rect(chip, a(col, 0.85 if want else 0.5))
		ci.draw_rect(chip, col, false, 2.0)
		if not dead:
			emblem(ci, nb, chip.get_center(), 9.0, BG, 2.0, true)
		ci.draw_colored_polygon(PackedVector2Array([Vector2(cx + d * 14, 660), Vector2(cx - d * 14, 647), Vector2(cx - d * 14, 673)]), col)
		text(ci, "BRAKE" if i == 0 else "BOOST", Vector2(rc.position.x, 692), 28, INK, rc.size.x, HORIZONTAL_ALIGNMENT_CENTER)


static func glow_rect(ci: CanvasItem, rc: Rect2, col: Color, k: float) -> void:
	ci.draw_rect(rc.grow(8), a(col, 0.25 * k))
	ci.draw_rect(rc.grow(16), a(col, 0.10 * k))


static func draw_hud(ci: CanvasItem, g) -> void:
	var s: R.Run = g.run
	text(ci, "%d" % g.score, Vector2(440, 52), 40, INK, 400.0, HORIZONTAL_ALIGNMENT_CENTER)
	for i in R.LIVES:
		var rc := Rect2(598 + i * 32, 62, 20, 20)
		if i < g.lives:
			ci.draw_rect(rc, EMBER)
		else:
			ci.draw_rect(rc, a(BAD, 0.8) if (i == g.lives and g.life_flash_t > 0.0) else PANEL)
			ci.draw_rect(rc, DIM, false, 2.0)
	for b in 3:
		var rc := Rect2(180 + b * 84, 28, 72, 32)
		var col: Color = BAND_COL[b]
		if b == s.band:
			ci.draw_rect(rc.grow(6), a(col, 0.15))
			ci.draw_rect(rc, a(col, 0.85))
		ci.draw_rect(rc, col, false, 2.0)
		emblem(ci, b, rc.get_center(), 9.0, BG if b == s.band else col, 2.0, b == s.band)
	var f := clampf(g.t / R.ROUND_TIME, 0.0, 1.0)
	ci.draw_rect(Rect2(860, 40, 220, 12), TRACE)
	ci.draw_rect(Rect2(860, 40, 220 * f, 12), EMBER)
	if g.banner_t > 0.0:
		var col: Color = INK
		if g.banner_text == "RED":
			col = BAND_COL[0]
		elif g.banner_text == "BLUE":
			col = BAND_COL[2]
		text(ci, g.banner_text, Vector2(240, 140), 48, a(col, minf(1.0, g.banner_t / 0.3)), 800.0, HORIZONTAL_ALIGNMENT_CENTER)
