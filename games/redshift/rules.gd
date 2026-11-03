extends RefCounted
## Red Shift pure rules: no nodes, no autoloads. Shared by game.gd, the bot and selftest.gd.

const EV_SHIFT := 1
const EV_KILL := 2
const EV_DAMAGE := 4
const EV_CRASH := 8
const EV_ESCAPE := 16
const EV_BLOCK := 32

const BANDS := 3
const START_BAND := 1
const SPEED_MUL := [0.75, 1.0, 1.3]
const K_EASE := 4.0
const SHIP_X := 240.0
# Juice.popup: label top = pos.y - size, then rises POPUP_RISE over its life. The HUD owns y < HUD_BOTTOM.
const POPUP_MIN_X := 170.0  # clear of the left HUD and the SOUND corner
const POPUP_MAX_X := 1090.0
const POPUP_SIZE := 32.0
const POPUP_RISE := 70.0
const HUD_BOTTOM := 64.0
const POPUP_MIN_Y := HUD_BOTTOM + POPUP_RISE + POPUP_SIZE + 2.0  # 168: final label top = 66
const SHIP_Y0 := 340.0
const SHIP_Y_MIN := 110.0
const SHIP_Y_MAX := 570.0
const SHIP_R := 22.0
const MOVE_SPEED := 420.0
const FIRE_GAP := 0.16
const SHOT_SPEED := 900.0
const SPAWN_X := 1320.0
const ESCAPE_X := -40.0
const ENEMY_Y_MIN := 130.0
const ENEMY_Y_MAX := 550.0
const ENEMY_R := 26.0
const HEAVY_R := 36.0
const SPEED_START := 150.0
const SPEED_RAMP := 3.5
const SPEED_MAX := 260.0
const GAP_START := 1.6
const GAP_RAMP := 0.02
const GAP_MIN := 0.85
const FIRST_SPAWN := 0.5
const RED_AT := 10.0
const BLUE_AT := 20.0
const HEAVY_AT := 30.0
const HEAVY_CHANCE := 0.25
const HEAVY_HP := 3
const HEAVY_SLOW := 0.8
const LIVES := 3
const INVULN := 1.0
const ROUND_TIME := 50.0
const GRACE_END := 10.0
const HINTS_END := 30.0
const DIFFICULTY_OFFSET := 30.0
const KILL_PTS := 10
const STREAK_PTS := 2
const STREAK_CAP := 10
const HEAVY_MULT := 3
const LIFE_BONUS := 100
const PITCH_STEP := 0.04
const PITCH_MAX := 1.5
const LOOP_BASE := [45, 0, 57, 45, 52, 0, 55, 57, 45, 0, 57, 60, 57, 55, 52, 50]
const TRANSPOSE := [-5, 0, 7]
const BOT_THINK := 0.1
const BOT_DODGE_X := 320.0
const BOT_DODGE_DY := 75.0
const BOT_DODGE_OFS := 150.0
const FOLLOW_DEAD := 6.0
const BRAKE_RECT := Rect2(870, 598, 190, 110)
const BOOST_RECT := Rect2(1074, 598, 190, 110)
const MOVE_ZONE_X := 853.0
const TAP_BRAKE := 0
const TAP_BOOST := 1
const TAP_MOVE := 2


class Enemy extends RefCounted:
	var pos: Vector2 = Vector2.ZERO
	var band: int = 1
	var hp: int = 1
	var heavy: bool = false
	var radius: float = 26.0


class Shot extends RefCounted:
	var pos: Vector2 = Vector2.ZERO
	var band: int = 1


class Run extends RefCounted:
	var ship_y: float = 340.0
	var band: int = 1
	var k: float = 1.0
	var enemies: Array[Enemy] = []
	var shots: Array[Shot] = []
	var fire_t: float = 0.0
	var spawn_t: float = 0.5
	var invuln: float = 0.0
	var streak: int = 0
	var kills: Array[Dictionary] = []
	var hurt: Array[Enemy] = []
	var crash_pos: Vector2 = Vector2.ZERO
	var blocked: Array[Vector2] = []


# --- ramp ----------------------------------------------------------------------
static func ramp_time(t: float, difficulty: int) -> float:
	return t + (DIFFICULTY_OFFSET if difficulty >= 1 else 0.0)


static func enemy_speed(r: float) -> float:
	return minf(SPEED_MAX, SPEED_START + SPEED_RAMP * r)


static func spawn_gap(r: float) -> float:
	return maxf(GAP_MIN, GAP_START - GAP_RAMP * r)


static func spawn_bands(r: float) -> Array:
	if r < RED_AT:
		return [1]
	if r < BLUE_AT:
		return [0, 1]
	return [0, 1, 2]


static func phase_name(r: float) -> String:
	if r < RED_AT:
		return ""
	if r < BLUE_AT:
		return "RED"
	if r < HEAVY_AT:
		return "BLUE"
	return "HEAVY"


static func hints_on(r: float) -> bool:
	return r < HINTS_END


static func is_grace(r: float) -> bool:
	return r < GRACE_END


static func popup_pos(p: Vector2) -> Vector2:
	return Vector2(clampf(p.x, POPUP_MIN_X, POPUP_MAX_X), maxf(p.y, POPUP_MIN_Y))


# --- scoring, sound, input -----------------------------------------------------
static func kill_points(streak: int, heavy: bool) -> int:
	return (KILL_PTS + STREAK_PTS * mini(streak, STREAK_CAP)) * (HEAVY_MULT if heavy else 1)


static func shift_pitch(streak: int) -> float:
	return minf(PITCH_MAX, 1.0 + PITCH_STEP * streak)


static func final_score(score: int, lives: int) -> int:
	return score + LIFE_BONUS * lives


static func loop_notes(band: int) -> Array:
	var out: Array = []
	for n in LOOP_BASE:
		out.append(0 if n == 0 else n + TRANSPOSE[band])
	return out


static func tap_target(pos: Vector2) -> int:
	if BRAKE_RECT.has_point(pos):
		return TAP_BRAKE
	if BOOST_RECT.has_point(pos):
		return TAP_BOOST
	if pos.x < MOVE_ZONE_X and pos.y >= 70.0:
		return TAP_MOVE
	return -1


static func follow_dir(target_y: float, ship_y: float) -> float:
	var dy := target_y - ship_y
	return 0.0 if absf(dy) < FOLLOW_DEAD else signf(dy)


# --- the step ------------------------------------------------------------------
static func shift(s: Run, dir: int) -> int:
	var nb := clampi(s.band + dir, 0, BANDS - 1)
	if nb == s.band:
		return 0
	s.band = nb
	return EV_SHIFT


static func _spawn(s: Run, r: float, rng: RandomNumberGenerator) -> void:
	var e := Enemy.new()
	var bands := spawn_bands(r)
	e.pos = Vector2(SPAWN_X, rng.randf_range(ENEMY_Y_MIN, ENEMY_Y_MAX))
	e.band = bands[rng.randi() % bands.size()]
	e.heavy = r >= HEAVY_AT and rng.randf() < HEAVY_CHANCE
	e.hp = HEAVY_HP if e.heavy else 1
	e.radius = HEAVY_R if e.heavy else ENEMY_R
	s.enemies.append(e)


static func step(s: Run, dt: float, r: float, move: float, rng: RandomNumberGenerator) -> int:
	var ev := 0
	s.kills.clear()
	s.blocked.clear()
	s.hurt.clear()
	s.invuln = maxf(0.0, s.invuln - dt)
	s.k += (SPEED_MUL[s.band] - s.k) * minf(1.0, K_EASE * dt)
	s.ship_y = clampf(s.ship_y + move * MOVE_SPEED * dt, SHIP_Y_MIN, SHIP_Y_MAX)
	s.spawn_t -= dt
	if s.spawn_t <= 0.0:
		_spawn(s, r, rng)
		s.spawn_t = spawn_gap(r)
	s.fire_t -= dt
	if s.fire_t <= 0.0:
		s.fire_t = FIRE_GAP
		var sh := Shot.new()
		sh.pos = Vector2(SHIP_X + 30.0, s.ship_y)
		sh.band = s.band
		s.shots.append(sh)
	var spd := enemy_speed(r) * s.k
	for e in s.enemies:
		e.pos.x -= spd * (HEAVY_SLOW if e.heavy else 1.0) * dt
	# shots vs enemies
	var keep: Array[Shot] = []
	for sh in s.shots:
		sh.pos.x += SHOT_SPEED * dt
		var used := false
		for e in s.enemies:
			if e.hp > 0 and absf(sh.pos.x - e.pos.x) < e.radius and absf(sh.pos.y - e.pos.y) < e.radius:
				used = true
				if e.band == sh.band:
					e.hp -= 1
					if e.hp > 0:
						ev |= EV_DAMAGE
						s.hurt.append(e)
				else:
					s.blocked.append(sh.pos)
					ev |= EV_BLOCK
				break
		if not used and sh.pos.x <= SPAWN_X:
			keep.append(sh)
	s.shots = keep
	# kills, crashes, escapes
	var alive: Array[Enemy] = []
	var ship := Vector2(SHIP_X, s.ship_y)
	for e in s.enemies:
		if e.hp <= 0:
			s.kills.append({"pos": e.pos, "band": e.band, "heavy": e.heavy, "pts": kill_points(s.streak, e.heavy)})
			s.streak += 1
			ev |= EV_KILL
		elif s.invuln <= 0.0 and e.pos.distance_to(ship) < e.radius + SHIP_R:
			s.streak = 0
			s.invuln = INVULN
			s.crash_pos = e.pos
			ev |= EV_CRASH
		elif e.pos.x < ESCAPE_X:
			s.streak = 0
			ev |= EV_ESCAPE
		else:
			alive.append(e)
	s.enemies = alive
	return ev
