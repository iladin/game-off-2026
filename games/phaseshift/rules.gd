extends RefCounted
## Phase Shift pure rules: ramp, course generation, the physics step, the bot, scoring.
## No nodes, no autoloads (a passed-in RandomNumberGenerator is fine).

const PHASE := 0
const JUMP := 1
const EV_PHASE := 1
const EV_JUMP := 2
const EV_LAND := 4
const EV_FALL := 8
const EV_CRASH := 16
const EV_WALL := 32
const EV_ORB := 64
const EV_BUMP := 128

const CELL := 80.0
const PLAYER_X := 320.0
const GROUND_Y := 560.0
const FAIL_Y := 680.0
const SPEED_START := 280.0
const SPEED_RAMP := 4.0
const SPEED_MAX := 440.0
const GOAL_DIST := 14400.0
const GOAL_CELLS := 180
const TOTAL_CELLS := 210
const START_CELLS := 12
const HEIGHT_STEP := 80.0
const MAX_HEIGHT := 2
const HEIGHT_FROM_CELL := 16
const HEIGHT_CHANCE := 100
const POST_CROSS_RUN := 7
const POST_CROSS_STEP := 3
const RUN_MIN_AFTER_STEP := 3
const BOT_STEP_LEAD := 0.22
const BUMP_TOL := 1.0
const ZONE_CELLS: Array[int] = [37, 80, 127]
const RUN_MIN: Array[int] = [6, 6, 5, 6]
const RUN_MAX: Array[int] = [9, 9, 8, 8]
const BRIDGE_CELLS: Array[int] = [3, 2, 2, 1]
const JUMP_V := -900.0
const GRAVITY := 2600.0
const AIR_TIME := 0.6923
const COYOTE := 0.10
const JUMP_BUFFER := 0.10
const PHASE_COOLDOWN := 0.15
const INVULN := 1.2
const ORB_REACH := 100.0
const HINT_LOOK := 240.0
const GRACE_END := 10.0
const HINTS_END := 30.0
const JUMP_AT := 10.0
const WALLS_AT := 20.0
const TOP_AT := 30.0
const DIFFICULTY_OFFSET := 30.0
const CELL_PTS := 2
const ORB_PTS := 20
const STREAK_PTS := 2
const STREAK_CAP := 10
const WALL_PTS := 15
const LIFE_BONUS := 150
const PITCH_STEP := 0.04
const PITCH_MAX := 1.5
const BOT_PHASE_LOOK := 44.0
const BOT_MIN_LEAD := 8.0
const B_TRANSPOSE := 5
const LOOP_A: Array[int] = [45, 0, 57, 0, 52, 57, 0, 55, 45, 0, 57, 0, 60, 57, 55, 52]


class Body extends RefCounted:
	var y: float = 560.0
	var vy: float = 0.0
	var world: int = 1
	var grounded: bool = true
	var coyote: float = 0.0
	var jump_buf: float = 0.0
	var invuln: float = 0.0
	var phase_cd: float = 0.0
	var orb_cell: int = -1


class Course extends RefCounted:
	var ground := PackedByteArray()
	var wall := PackedByteArray()
	var orb := PackedByteArray()
	var height := PackedByteArray()

	func _init() -> void:
		ground.resize(210)
		ground.fill(3)
		wall.resize(210)
		orb.resize(210)
		height.resize(210)


# --- ramp --------------------------------------------------------------------------
static func ramp_time(t: float, d: int) -> float:
	return t + (DIFFICULTY_OFFSET if d >= 1 else 0.0)


static func speed(r: float) -> float:
	return minf(SPEED_MAX, SPEED_START + SPEED_RAMP * r)


static func dist_at(t: float, d: int) -> float:
	var r0 := ramp_time(0.0, d)
	var t_cap := maxf(0.0, (SPEED_MAX - SPEED_START) / SPEED_RAMP - r0)
	var tt := minf(t, t_cap)
	var v0 := speed(r0)
	return v0 * tt + 0.5 * SPEED_RAMP * tt * tt + SPEED_MAX * maxf(0.0, t - t_cap)


static func zone_at(c: int, d: int) -> int:
	if d >= 1:
		return 3
	if c < ZONE_CELLS[0]:
		return 0
	if c < ZONE_CELLS[1]:
		return 1
	if c < ZONE_CELLS[2]:
		return 2
	return 3


static func phase_name(r: float) -> String:
	if r < JUMP_AT:
		return ""
	if r < WALLS_AT:
		return "JUMP"
	if r < TOP_AT:
		return "WALLS"
	return "TOP SPEED"


static func hints_on(r: float) -> bool:
	return r < HINTS_END


static func is_grace(r: float) -> bool:
	return r < GRACE_END


# --- course ------------------------------------------------------------------------
static func _put(course: Course, c: int, n: int, g: int) -> int:
	for i in n:
		if c + i < TOTAL_CELLS:
			course.ground[c + i] = g
	return c + n


static func build_course(rng: RandomNumberGenerator, d: int) -> Course:
	var course := Course.new()
	var c := START_CELLS
	var w := 2
	var h := 0
	var cross := false
	while c < GOAL_CELLS:
		var seg_start := c
		var stepped := false
		var post_cross := cross
		var h_pre := h
		if c >= HEIGHT_FROM_CELL and rng.randi_range(0, 99) < HEIGHT_CHANCE:
			if h == 0:
				h = 1
			elif h == MAX_HEIGHT:
				h -= 1
			else:
				h += 1 if rng.randi_range(0, 1) == 0 else -1
			stepped = true
		cross = false
		var z := zone_at(c, d)
		var n := rng.randi_range(RUN_MIN[z], RUN_MAX[z])
		var a := n / 2
		if stepped:
			a = maxi(a, POST_CROSS_RUN if post_cross else RUN_MIN_AFTER_STEP)
			n = maxi(n, a + 2)
		var b := n - a
		var hole := 0
		if z == 3:
			hole = rng.randi_range(1, 2)
		elif z > 0:
			hole = 1
		var run_start := c
		c = _put(course, c, a, w)
		var hs := c
		c = _put(course, c, hole, 0)
		c = _put(course, c, b, w)
		var idx := 0
		for k in range(run_start, c):
			if k >= hs and k < hs + hole:
				continue
			if idx % 2 == 1 and (hole == 0 or (k < hs - 2 or k > hs + hole - 1 + 2)):
				course.orb[k] = w
			idx += 1
		w = 3 - w
		match z:
			0:
				c = _put(course, c, BRIDGE_CELLS[0], 3)
			1:
				c = _put(course, c, BRIDGE_CELLS[1], 3)
			2:
				if rng.randi_range(0, 1) == 0:
					c = _put(course, c, 2, 3)
					course.wall[c] = rng.randi_range(1, 2)
					c = _put(course, c, 1, 3)
					c = _put(course, c, 2, 3)
				else:
					c = _put(course, c, BRIDGE_CELLS[2], 3)
			_:
				var kind := rng.randi_range(0, 2)
				if kind == 0:
					c = _put(course, c, 1, 3)
					course.wall[c] = rng.randi_range(1, 2)
					c = _put(course, c, 1, 3)
					c = _put(course, c, 1, 3)
				elif kind == 1:
					c = _put(course, c, rng.randi_range(1, 2), 0)
					cross = true
				else:
					c = _put(course, c, BRIDGE_CELLS[3], 3)
		for k in range(seg_start, mini(c, TOTAL_CELLS)):
			course.height[k] = h_pre if (post_cross and stepped and k < seg_start + POST_CROSS_STEP) else h
	for k in range(c, TOTAL_CELLS):
		course.height[k] = h
	return course


static func cell_of(x: float) -> int:
	return floori(x / CELL)


static func ground_at(course: Course, c: int) -> int:
	if c < 0 or c >= TOTAL_CELLS:
		return 3
	return course.ground[c]


static func wall_at(course: Course, c: int) -> int:
	if c < 0 or c >= TOTAL_CELLS:
		return 0
	return course.wall[c]


static func orb_at(course: Course, c: int) -> int:
	if c < 0 or c >= TOTAL_CELLS:
		return 0
	return course.orb[c]


static func height_at(course: Course, c: int) -> int:
	if c < 0 or c >= TOTAL_CELLS:
		return 0
	return course.height[c]


## Screen y of the floor top of cell c (feet rest here).
static func surface_y(course: Course, c: int) -> float:
	return GROUND_Y - HEIGHT_STEP * height_at(course, c)


static func has_ground(course: Course, c: int, world: int) -> bool:
	var g := ground_at(course, c)
	return g == 3 or g == world


static func need_world(course: Course, c: int) -> int:
	var wl := wall_at(course, c)
	if wl != 0:
		return 3 - wl
	var g := ground_at(course, c)
	return g if (g == 1 or g == 2) else 0


## First cell ahead (within HINT_LOOK) that needs another world: Vector2i(cell, world) or (-1, 0).
static func hint_info(course: Course, x: float, world: int) -> Vector2i:
	for c in range(cell_of(x) + 1, cell_of(x + HINT_LOOK) + 1):
		var nw := need_world(course, c)
		if nw != 0:
			return Vector2i(c, nw) if nw != world else Vector2i(-1, 0)
	return Vector2i(-1, 0)


static func hint_world(course: Course, x: float, world: int) -> int:
	return hint_info(course, x, world).y


static func fit_world(course: Course, c: int, world: int) -> int:
	if wall_at(course, c) == world:
		return 3 - world
	var g := ground_at(course, c)
	if g == 1 or g == 2:
		return g
	return world


static func rescue(b: Body, course: Course, x: float, v: float) -> void:
	b.y = surface_y(course, cell_of(x))
	b.vy = 0.0
	b.grounded = true
	b.coyote = 0.0
	b.jump_buf = 0.0
	b.invuln = INVULN
	b.world = fit_world(course, cell_of(x + v * INVULN), b.world)


# --- the physics step --------------------------------------------------------------
static func step(b: Body, course: Course, x_prev: float, x: float, dt: float, jump: bool, phase: bool) -> int:
	var ev := 0
	b.phase_cd -= dt
	if phase and b.phase_cd <= 0.0:
		b.world = 3 - b.world
		b.phase_cd = PHASE_COOLDOWN
		ev |= EV_PHASE
	if jump:
		b.jump_buf = JUMP_BUFFER
	if b.jump_buf > 0.0 and (b.grounded or b.coyote > 0.0):
		b.vy = JUMP_V
		b.grounded = false
		b.coyote = 0.0
		b.jump_buf = 0.0
		ev |= EV_JUMP
	b.jump_buf -= dt
	var c := cell_of(x)
	var ok := has_ground(course, c, b.world) or b.invuln > 0.0
	var surf := surface_y(course, c)
	if b.grounded:
		if not ok:
			b.grounded = false
			b.coyote = COYOTE
			b.vy = 0.0
		elif surf > b.y + BUMP_TOL:
			b.grounded = false  # walked off a ledge
			b.vy = 0.0
		elif surf < b.y - BUMP_TOL:
			if b.invuln > 0.0:
				b.y = surf
			else:
				ev |= EV_BUMP  # ran into the side of a higher step
	elif b.coyote > 0.0:
		if ok:
			b.grounded = true
			b.coyote = 0.0
			b.y = surf
		else:
			b.coyote -= dt
	else:
		b.vy += GRAVITY * dt
		var y_prev := b.y
		b.y += b.vy * dt
		if b.vy > 0.0 and y_prev <= surf and b.y >= surf and ok:
			b.y = surf
			b.vy = 0.0
			b.grounded = true
			ev |= EV_LAND
		elif ok and b.invuln <= 0.0 and b.y > surf + BUMP_TOL and has_ground(course, c, b.world):
			ev |= EV_BUMP
		elif b.y > FAIL_Y:
			ev |= EV_FALL
	if b.invuln <= 0.0:
		var wx := c * CELL + CELL / 2.0
		var wl := wall_at(course, c)
		if wl == b.world:
			ev |= EV_CRASH
		elif wl != 0 and x_prev < wx and x >= wx:
			ev |= EV_WALL
	if orb_at(course, c) == b.world and b.y > surf - ORB_REACH:
		ev |= EV_ORB
		b.orb_cell = c
	if b.invuln > 0.0:
		b.invuln -= dt
		if b.invuln <= 0.0:
			b.world = fit_world(course, c, b.world)
	return ev


# --- the bot -----------------------------------------------------------------------
static func next_hole(course: Course, x: float) -> Vector2i:
	var c0 := cell_of(x)
	for c in range(c0, c0 + 7):
		if ground_at(course, c) == 0 and (c == c0 or ground_at(course, c - 1) != 0):
			var n := 0
			while ground_at(course, c + n) == 0:
				n += 1
			return Vector2i(c, n)
	return Vector2i(-1, 0)


## Bot flags: bit 1 = jump, bit 2 = phase.
static func bot_input(b: Body, course: Course, x: float, v: float) -> int:
	var f := 0
	var need := need_world(course, cell_of(x + BOT_PHASE_LOOK))
	if need != 0 and need != b.world:
		f |= 2
	if b.grounded or b.coyote > 0.0:
		var cs := cell_of(x)
		var h0 := height_at(course, cs)
		for k in range(cs + 1, cs + 4):
			if height_at(course, k) != h0:
				if height_at(course, k) > h0 and k * CELL - x <= v * BOT_STEP_LEAD:
					f |= 1
				break
		var h := next_hole(course, x)
		if h.x >= 0:
			var to_hole := h.x * CELL - x
			var span := v * AIR_TIME - h.y * CELL
			var lead := maxf(BOT_MIN_LEAD, span / 2.0)
			# Two holes close together: land early enough to take off for the next one.
			var h2 := next_hole(course, (h.x + h.y) * CELL)
			if h2.x >= 0:
				var after := h2.x * CELL - (h.x + h.y) * CELL
				var lead2 := maxf(BOT_MIN_LEAD, (v * AIR_TIME - h2.y * CELL) / 2.0)
				lead = clampf(lead, BOT_MIN_LEAD, maxf(BOT_MIN_LEAD, after - lead2))
			if to_hole <= span - lead:
				f |= 1
	return f


static func sim_bot_round(seed_value: int, d: int) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var course := build_course(rng, d)
	var b := Body.new()
	var dt := 1.0 / 60.0
	var t := 0.0
	var dist := 0.0
	var res := {"fails": 0, "won": false, "time": 0.0, "phases": 0, "orbs": 0, "walls": 0, "score": 0}
	var streak := 0
	var last_cell := 0
	var score := 0
	var lives := 3
	while t < 80.0:
		t += dt
		var v := speed(ramp_time(t, d))
		var x_prev := dist
		dist += v * dt
		var f := bot_input(b, course, dist, v)
		var ev := step(b, course, x_prev, dist, dt, (f & 1) != 0, (f & 2) != 0)
		if ev & EV_PHASE:
			res.phases += 1
		if ev & EV_ORB:
			score += orb_points(streak)
			streak += 1
			res.orbs += 1
			course.orb[b.orb_cell] = 0
		if ev & EV_WALL:
			score += WALL_PTS
			streak += 1
			res.walls += 1
		if ev & (EV_FALL | EV_CRASH | EV_BUMP):
			res.fails += 1
			streak = 0
			lives -= 1
			rescue(b, course, dist, v)
		while last_cell < cell_of(dist):
			last_cell += 1
			score += CELL_PTS
		if dist >= GOAL_DIST:
			res.won = true
			break
	res.time = t
	res.score = final_score(score, lives)
	return res


# --- scoring / audio / touch -------------------------------------------------------
static func orb_points(streak: int) -> int:
	return ORB_PTS + STREAK_PTS * mini(streak, STREAK_CAP)


static func shift_pitch(streak: int) -> float:
	return minf(PITCH_MAX, 1.0 + PITCH_STEP * streak)


static func final_score(score: int, lives: int) -> int:
	return score + LIFE_BONUS * lives


static func loop_notes(world: int) -> Array:
	var out: Array = []
	for n in LOOP_A:
		out.append(n + B_TRANSPOSE if (world == 2 and n > 0) else n)
	return out


static func touch_zone(pos: Vector2) -> int:
	return PHASE if pos.x < 640.0 else JUMP
