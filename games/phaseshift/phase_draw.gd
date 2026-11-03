extends RefCounted
## Phase Shift drawing helpers (static, take the CanvasItem to draw on).

const R := preload("res://games/phaseshift/rules.gd")

const BG := Color("0B0E14")
const PANEL := Color("151A24")
const TRACE := Color("1E2738")
const DIM := Color("6B7489")
const INK := Color("E8ECF4")
const WORLD_A := Color("A78BFA")
const WORLD_B := Color("3DDCFF")
const GOOD := Color("FFD34D")
const BAD := Color("FF3B5C")
const PHASE_PAD := Rect2(170, 616, 300, 96)
const JUMP_PAD := Rect2(810, 616, 300, 96)
const PLAYER_SIZE := 48.0
const AIR_TURN := PI / 2.0
const ROW_BOTTOM := 520.0
const ROW_TWEEN := 0.15


static func world_col(w: int) -> Color:
	return WORLD_A if w == 1 else WORLD_B


static func glow_rect(ci: CanvasItem, r: Rect2, col: Color) -> void:
	for pair in [[1.6, 0.10], [1.3, 0.25]]:
		var k: float = pair[0]
		var g := Rect2(r.get_center() - r.size * k * 0.5, r.size * k)
		ci.draw_rect(g, Color(col, pair[1]))


static func _hash(i: int, salt: int) -> float:
	var h: int = (i * 73856093 + salt * 19349663) & 0x7fffffff
	h = (h ^ (h >> 13)) * 1274126177 & 0x7fffffff
	return float(h % 1000) / 1000.0


## One parallax row of block silhouettes for `world`. fill = 1 when it is the current world
## (PANEL tinted with the world colour), 0 when not (2 px outline only).
static func draw_block_row(ci: CanvasItem, dist: float, speed: float, world: int, fill: float, salt: int) -> void:
	var pitch := 130.0
	var base := dist * speed
	var i0 := floori(base / pitch)
	var col := world_col(world)
	for i in range(i0, i0 + 11):
		var x := i * pitch - base + (0.0 if world == 1 else 40.0)
		var w := 84.0 + _hash(i, salt) * 36.0
		var h := 150.0 + _hash(i, salt + 7) * 170.0
		var r := Rect2(x, ROW_BOTTOM - h, w, h)
		if fill > 0.0:
			ci.draw_rect(r, Color(PANEL.lerp(col, 0.22), fill))
		ci.draw_rect(r, Color(col, lerpf(0.4, 0.75, fill)), false, 2.0)


static func draw_backdrop(ci: CanvasItem, dist: float, blend: float = 1.0) -> void:
	ci.draw_rect(Rect2(0, 0, 1280, 720), BG)
	var off := -fmod(dist * 0.5, 40.0)
	var x := off
	while x < 1280.0:
		ci.draw_line(Vector2(x, 0), Vector2(x, 720), TRACE, 1.0)
		x += 40.0
	var y := 0.0
	while y < 720.0:
		ci.draw_line(Vector2(0, y), Vector2(1280, y), TRACE, 1.0)
		y += 40.0
	# blend: 1 = world A current, 0 = world B current (tweened by game.gd over ROW_TWEEN)
	draw_block_row(ci, dist, 0.3, 1, blend, 1)
	draw_block_row(ci, dist, 0.6, 2, 1.0 - blend, 2)


static func draw_course(ci: CanvasItem, course: R.Course, dist: float, world: int, hint_c: int,
		hint_w: int, wall_flash_c: int, wall_flash_t: float, t: float) -> void:
	var c0 := floori((dist - R.PLAYER_X - 80.0) / R.CELL)
	var c1 := ceili((dist - R.PLAYER_X + 1280.0) / R.CELL)
	for c in range(c0, c1 + 1):
		var sx := R.PLAYER_X + c * R.CELL - dist
		var g := R.ground_at(course, c)
		var fr := Rect2(sx + 1, R.GROUND_Y, 78, 40)
		if g == 3:
			ci.draw_rect(fr, PANEL)
			ci.draw_rect(fr, TRACE, false, 2.0)
			ci.draw_rect(Rect2(sx + 1, R.GROUND_Y, 78, 4), Color(INK, 0.5))
		elif g == world:
			ci.draw_rect(fr, world_col(g))
			ci.draw_rect(Rect2(sx + 1, R.GROUND_Y, 78, 4), INK)
		elif g != 0:
			ci.draw_rect(fr, Color(world_col(g), 0.35), false, 2.0)
		var wl := R.wall_at(course, c)
		if wl != 0:
			var wr := Rect2(sx + 20, 200, 40, 360)
			if wl == world:
				glow_rect(ci, wr, world_col(wl))
				ci.draw_rect(wr, world_col(wl))
				ci.draw_rect(wr, INK, false, 4.0)
			else:
				ci.draw_rect(wr, Color(world_col(wl), 0.35), false, 2.0)
			if c == wall_flash_c and wall_flash_t > 0.0:
				ci.draw_rect(wr, Color(INK, 0.6))
		var ob := R.orb_at(course, c)
		if ob != 0:
			var oc := Vector2(sx + 40, R.GROUND_Y - 40)
			if ob == world:
				ci.draw_circle(oc, 12 * 1.6, Color(world_col(ob), 0.10))
				ci.draw_circle(oc, 12 * 1.3, Color(world_col(ob), 0.25))
				ci.draw_circle(oc, 12, world_col(ob))
				ci.draw_arc(oc, 12, 0, TAU, 20, INK, 2.0)
			else:
				ci.draw_arc(oc, 12, 0, TAU, 20, Color(world_col(ob), 0.35), 2.0)
		if c == hint_c and hint_w != 0:
			var hr := fr
			if wl != 0:
				hr = Rect2(sx + 20, 200, 40, 360)
			var gr := Rect2(hr.get_center() - hr.size * 0.65, hr.size * 1.3)
			ci.draw_rect(gr, Color(world_col(hint_w), 0.25))
	var gx := R.PLAYER_X + R.GOAL_DIST - dist
	if gx > -40.0 and gx < 1320.0:
		glow_rect(ci, Rect2(gx - 4, 200, 8, 360), GOOD)
		ci.draw_rect(Rect2(gx - 4, 200, 8, 360), GOOD)


static func draw_player(ci: CanvasItem, y: float, world: int, air_frac: float, sx: float, sy: float,
		tint_t: float, hint_w: int, invuln: float, phase_fx_t: float, phase_fx_time: float,
		old_world: int, t: float) -> void:
	var col := BAD if tint_t > 0.0 else world_col(world)
	if invuln > 0.0:
		ci.draw_line(Vector2(260, R.GROUND_Y), Vector2(380, R.GROUND_Y), Color(INK, 0.5), 4.0)
		if fmod(invuln, 0.16) < 0.08:
			return
	var half := PLAYER_SIZE / 2.0
	if phase_fx_t > 0.0:
		var p := 1.0 - phase_fx_t / phase_fx_time
		var e := 1.0 - pow(1.0 - p, 3.0)
		var cen := Vector2(R.PLAYER_X, y - half)
		ci.draw_arc(cen, lerpf(30.0, 90.0, e), 0, TAU, 32, Color(world_col(world), 1.0 - p), 4.0)
		ci.draw_rect(Rect2(cen - Vector2(half, half), Vector2(PLAYER_SIZE, PLAYER_SIZE)),
			Color(world_col(old_world), 0.5 * (1.0 - p)))
	var ctr := Vector2(R.PLAYER_X, y - half * sy)
	ci.draw_set_transform(ctr, AIR_TURN * clampf(air_frac, 0.0, 1.0), Vector2(sx, sy))
	var r := Rect2(-half, -half, PLAYER_SIZE, PLAYER_SIZE)
	glow_rect(ci, r, col)
	ci.draw_rect(r, col)
	var oc := INK
	if hint_w != 0:
		oc = Color(world_col(hint_w), 0.55 + 0.45 * sin(TAU * 4.0 * t))
	ci.draw_rect(r, oc, false, 6.0)
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


static func draw_pads(ci: CanvasItem, pad_t: Array, world: int) -> void:
	# PHASE pad
	var pr := PHASE_PAD
	var down: bool = pad_t[0] > 0.0
	if down:
		pr.position.y += 6.0
	var fill := (WORLD_B if world == 2 else WORLD_A) if down else PANEL
	ci.draw_rect(pr, fill)
	ci.draw_rect(pr, TRACE, false, 4.0)
	var cen := pr.get_center()
	for i in 2:
		var w := i + 1
		var off := Vector2(-10, -10) if i == 0 else Vector2(10, 10)
		var sq := Rect2(cen + off - Vector2(20, 20), Vector2(40, 40))
		var colw := BG if down else world_col(w)
		if w == world:
			ci.draw_rect(sq, colw)
			ci.draw_rect(sq, BG if not down else colw, false, 4.0)
		else:
			ci.draw_rect(sq, colw, false, 4.0)
	# JUMP pad
	var jr := JUMP_PAD
	var jd: bool = pad_t[1] > 0.0
	if jd:
		jr.position.y += 6.0
	ci.draw_rect(jr, WORLD_A if jd else PANEL)
	ci.draw_rect(jr, TRACE, false, 4.0)
	var jc := jr.get_center()
	ci.draw_colored_polygon(PackedVector2Array([jc + Vector2(0, -24), jc + Vector2(28, 24), jc + Vector2(-28, 24)]),
		BG if jd else INK)


static func draw_hud(ci: CanvasItem, font: Font, score: int, lives: int, max_lives: int, life_flash_t: float,
		progress: float, world: int, banner: String, banner_alpha: float) -> void:
	ci.draw_string(font, Vector2(0, 56), "%d" % score, HORIZONTAL_ALIGNMENT_CENTER, 1280, 40, INK)
	for i in max_lives:
		var r := Rect2(608 + i * 32 - 10, 66, 20, 20)
		if i < lives:
			ci.draw_rect(r, WORLD_A)
		else:
			if life_flash_t > 0.0 and i == lives:
				ci.draw_rect(r, BAD)
			ci.draw_rect(r, DIM, false, 2.0)
	ci.draw_rect(Rect2(340, 98, 600, 8), TRACE)
	ci.draw_rect(Rect2(340, 98, 600.0 * clampf(progress, 0.0, 1.0), 8), world_col(world))
	ci.draw_rect(Rect2(938, 94, 4, 16), GOOD)
	if banner != "" and banner_alpha > 0.0:
		ci.draw_string(font, Vector2(0, 168), banner, HORIZONTAL_ALIGNMENT_CENTER, 1280, 40, Color(WORLD_A, banner_alpha))
