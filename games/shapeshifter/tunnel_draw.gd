extends RefCounted
## Drawing helpers for Shapeshifter. Everything round-ish is a ray-sampled ring:
## 48 rays from the centre, never one big polygon with a hole.

const Rules := preload("res://games/shapeshifter/rules.gd")

const BG := Color("0B0E14")
const PANEL := Color("151A24")
const TRACE := Color("1E2738")
const DIM := Color("6B7489")
const INK := Color("E8ECF4")
const ACCENT := Color("FF5FA2")
const GOOD := Color("FFD34D")
const BAD := Color("FF3B5C")

const VP := Vector2(640, 300)
const WALL_HALF := 660.0
const RING_COUNT := 6
const BTN_SIZE := Vector2(220, 120)
const BTN_X: Array[float] = [380.0, 640.0, 900.0]
const BTN_TOP := 586.0
const KEY_LABELS: Array[String] = ["LEFT", "UP", "RIGHT"]


static func btn_rect(i: int) -> Rect2:
	return Rect2(BTN_X[i] - BTN_SIZE.x * 0.5, BTN_TOP, BTN_SIZE.x, BTN_SIZE.y)


## Radius per ray for a shape morphing from `a` to `b` (k 0..1), scaled.
static func radii(a: int, b: int, k: float, scale: float, hole: bool) -> PackedFloat32Array:
	var out := PackedFloat32Array()
	out.resize(Rules.N_RAYS)
	for i in Rules.N_RAYS:
		var ang := Rules.ray_angle(i)
		var ra := Rules.shape_radius(a, ang, Rules.SHAPE_R[a] * (Rules.HOLE_SCALE if hole else 1.0))
		var rb := ra
		if b != a:
			rb = Rules.shape_radius(b, ang, Rules.SHAPE_R[b] * (Rules.HOLE_SCALE if hole else 1.0))
		out[i] = lerpf(ra, rb, k) * scale
	return out


static func ring_points(center: Vector2, rad: PackedFloat32Array) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in rad.size():
		pts.append(center + Vector2.from_angle(Rules.ray_angle(i)) * rad[i])
	return pts


static func draw_backdrop(ci: CanvasItem) -> void:
	ci.draw_rect(Rect2(Vector2.ZERO, Vector2(1280, 720)), BG)
	for x in range(0, 1281, 40):
		ci.draw_line(Vector2(x, 0), Vector2(x, 720), TRACE, 1.0)
	for y in range(0, 721, 40):
		ci.draw_line(Vector2(0, y), Vector2(1280, y), TRACE, 1.0)
	for c in [Vector2(0, 0), Vector2(1280, 0), Vector2(0, 720), Vector2(1280, 720)]:
		ci.draw_line(c, VP, TRACE, 2.0)


static func draw_rings(ci: CanvasItem, ring_phase: float, rush: bool) -> void:
	var col := Color(ACCENT, 0.35) if rush else TRACE
	for k in RING_COUNT:
		var s := Rules.wall_scale(fposmod(ring_phase + float(k) / RING_COUNT, 1.0))
		var half := Vector2(640, 360) * s
		ci.draw_rect(Rect2(VP - half, half * 2.0), col, false, 2.0)


static func draw_exit(ci: CanvasItem, k: float) -> void:
	var half := Vector2(640, 360) * Rules.wall_scale(k)
	ci.draw_rect(Rect2(VP - half, half * 2.0), Color(GOOD, 0.5))


## A wall: PANEL ring (square outside, shape hole inside) as 2 triangles per ray.
static func draw_wall(ci: CanvasItem, hole_rad: PackedFloat32Array, s: float, alpha: float, outline: Color, outline_w: float, depth: float = 1.0) -> void:
	var n := hole_rad.size()
	var inner := ring_points(VP, hole_rad)
	var outer := PackedVector2Array()
	for i in n:
		var ang := Rules.ray_angle(i)
		outer.append(VP + Vector2.from_angle(ang) * Rules.square_radius(ang, WALL_HALF * s))
	# Depth tint: far walls sink toward BG, near walls rise toward TRACE.
	var fill := Color(BG.lerp(PANEL, clampf(depth * 1.5, 0.0, 1.0)).lerp(TRACE, clampf(depth * 1.2 - 0.3, 0.0, 0.9)), alpha)
	for i in n:
		var j := (i + 1) % n
		ci.draw_colored_polygon(PackedVector2Array([inner[i], outer[i], outer[j]]), fill)
		ci.draw_colored_polygon(PackedVector2Array([inner[i], outer[j], inner[j]]), fill)
	# Hole reads as a gap: BG fill (partly see-through) so grid and rings stop at the wall.
	draw_fan(ci, VP, hole_rad, Color(BG, alpha))
	var half := WALL_HALF * s
	ci.draw_rect(Rect2(VP - Vector2(half, half), Vector2(half, half) * 2.0), Color(TRACE, alpha), false, 2.0)
	var line := PackedVector2Array(inner)
	line.append(inner[0])
	ci.draw_polyline(line, Color(BG, alpha), outline_w + 4.0, true)
	ci.draw_polyline(line, outline, outline_w, true)


## Filled shape as a triangle fan over the rays.
static func draw_fan(ci: CanvasItem, center: Vector2, rad: PackedFloat32Array, color: Color) -> void:
	var pts := ring_points(center, rad)
	var n := pts.size()
	for i in n:
		ci.draw_colored_polygon(PackedVector2Array([center, pts[i], pts[(i + 1) % n]]), color)


static func draw_outline(ci: CanvasItem, center: Vector2, rad: PackedFloat32Array, color: Color, w: float) -> void:
	var pts := ring_points(center, rad)
	pts.append(pts[0])
	ci.draw_polyline(pts, color, w, true)


static func draw_player(ci: CanvasItem, from_shape: int, shape: int, k: float, squash: float, tint: Color, ghost_shape: int, ghost_k: float) -> void:
	var rad := radii(from_shape, shape, k, squash, false)
	draw_fan(ci, VP, rad_scaled(rad, 1.6), Color(tint, 0.10))
	draw_fan(ci, VP, rad_scaled(rad, 1.3), Color(tint, 0.25))
	draw_fan(ci, VP, rad, tint)
	draw_outline(ci, VP, rad, INK, 6.0)
	if ghost_k < 1.0:
		var g := radii(ghost_shape, ghost_shape, 1.0, lerpf(1.0, 1.4, ghost_k), false)
		draw_outline(ci, VP, g, Color(ACCENT, 1.0 - ghost_k), 2.0)


static func rad_scaled(rad: PackedFloat32Array, f: float) -> PackedFloat32Array:
	var out := PackedFloat32Array()
	out.resize(rad.size())
	for i in rad.size():
		out[i] = rad[i] * f
	return out


static func draw_buttons(ci: CanvasItem, font: Font, player_shape: int, glow_shape: int, glow_a: float, show_labels: bool) -> void:
	for i in 3:
		var r := btn_rect(i)
		var on := i == player_shape
		if i == glow_shape:
			ci.draw_rect(r.grow(r.size.x * 0.05), Color(ACCENT, glow_a))
		ci.draw_rect(r, PANEL)
		ci.draw_rect(r, ACCENT if on else TRACE, false, 6.0 if on else 4.0)
		var c := Vector2(BTN_X[i], 636.0)
		draw_fan(ci, c, radii(i, i, 1.0, 0.42, false), ACCENT if on else DIM)
		if show_labels:
			ci.draw_string(font, Vector2(BTN_X[i] - 110.0, 698.0), KEY_LABELS[i], HORIZONTAL_ALIGNMENT_CENTER, 220, 28, DIM)


static func draw_hud(ci: CanvasItem, font: Font, score: int, mult: int, lives: int, life_max: int, life_flash: float, progress: float, banner: String, banner_a: float) -> void:
	ci.draw_string(font, Vector2(0, 56), "%d" % score, HORIZONTAL_ALIGNMENT_CENTER, 1280, 40, INK)
	if mult > 1:
		ci.draw_string(font, Vector2(720, 56), "X%d" % mult, HORIZONTAL_ALIGNMENT_LEFT, -1, 28, ACCENT)
	for i in life_max:
		var r := Rect2(598.0 + 32.0 * i, 70, 20, 20)
		if i < lives:
			ci.draw_rect(r, ACCENT)
		else:
			ci.draw_rect(r, BAD if (i == lives and life_flash > 0.0) else BG)
			if not (i == lives and life_flash > 0.0):
				ci.draw_rect(r, DIM, false, 2.0)
	ci.draw_rect(Rect2(440, 102, 400, 6), TRACE)
	ci.draw_rect(Rect2(440, 102, 400.0 * clampf(progress, 0.0, 1.0), 6), ACCENT)
	if banner != "" and banner_a > 0.0:
		ci.draw_string(font, Vector2(0, 160), banner, HORIZONTAL_ALIGNMENT_CENTER, 1280, 40, Color(ACCENT, banner_a))
