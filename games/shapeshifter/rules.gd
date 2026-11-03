extends RefCounted
## Pure rules for Shapeshifter: ramp, matching, scoring, radial shape geometry.

const CIRCLE := 0
const TRIANGLE := 1
const SQUARE := 2

const ROUND_TIME := 75.0
const GRACE_END := 10.0
const DOUBLE_AT := 20.0
const MORPH_AT := 40.0
const RUSH_AT := 60.0
const DIFFICULTY_OFFSET := 30.0
const TRAVEL_START := 3.0
const TRAVEL_DROP := 0.025
const TRAVEL_MIN := 1.1
const GAP_START := 2.6
const GAP_DROP := 0.022
const GAP_MIN := 0.95
const RUSH_MULT := 0.85
const DOUBLE_GAP := 0.65
const DOUBLE_CHANCE := 0.35
const DOUBLE_CHANCE_RUSH := 0.5
const MORPH_CHANCE := 0.35
const MORPH_AT_P := 0.5
const EXIT_CLEAR := 1.0
const SCALE_FAR := 0.06
const SCALE_POW := 1.7
const SHAPE_R: Array[float] = [80.0, 110.0, 93.0]
const HOLE_SCALE := 1.15
const N_RAYS := 48
const BASE_POINTS := 10
const MULT_EVERY := 5
const MULT_MAX := 4
const LIFE_BONUS := 50
const PITCH_STEP := 0.04
const PITCH_MAX := 1.5
const TAP_SPLIT_1 := 510.0
const TAP_SPLIT_2 := 770.0


static func ramp_time(elapsed: float, difficulty: int) -> float:
	return elapsed + (DIFFICULTY_OFFSET if difficulty >= 1 else 0.0)


## 0 WARM-UP, 1 RUN, 2 DOUBLE, 3 MORPH, 4 RUSH
static func phase(r: float) -> int:
	if r >= RUSH_AT:
		return 4
	if r >= MORPH_AT:
		return 3
	if r >= DOUBLE_AT:
		return 2
	if r >= GRACE_END:
		return 1
	return 0


static func _rush(r: float) -> float:
	return RUSH_MULT if r >= RUSH_AT else 1.0


static func travel_time(r: float) -> float:
	return maxf(TRAVEL_MIN, (TRAVEL_START - TRAVEL_DROP * r) * _rush(r))


static func spawn_gap(r: float) -> float:
	return maxf(GAP_MIN, (GAP_START - GAP_DROP * r) * _rush(r))


static func double_chance(r: float) -> float:
	if r >= RUSH_AT:
		return DOUBLE_CHANCE_RUSH
	return DOUBLE_CHANCE if r >= DOUBLE_AT else 0.0


static func morph_chance(r: float) -> float:
	return MORPH_CHANCE if r >= MORPH_AT else 0.0


static func can_spawn(r: float) -> bool:
	return r + travel_time(r) <= ROUND_TIME - EXIT_CLEAR


static func is_grace(r: float) -> bool:
	return r < GRACE_END


static func passes(player: int, hole: int) -> bool:
	return player == hole


## Never returns prev. roll is 0 or 1.
static func next_shape(prev: int, roll: int) -> int:
	return (prev + 1 + (roll % 2)) % 3


static func wall_scale(p: float) -> float:
	return lerpf(SCALE_FAR, 1.0, pow(clampf(p, 0.0, 1.0), SCALE_POW))


static func ray_angle(i: int) -> float:
	return TAU * float(i) / float(N_RAYS)


static func _ngon(n: int, a0: float, a: float, r: float) -> float:
	var seg := TAU / float(n)
	var phi := fposmod(a - a0, seg) - seg * 0.5
	return r * cos(PI / float(n)) / cos(phi)


## Distance from the shape centre to its edge along angle a (r = circumradius).
static func shape_radius(shape: int, a: float, r: float) -> float:
	if shape == TRIANGLE:
		return _ngon(3, -PI * 0.5, a, r)
	if shape == SQUARE:
		return _ngon(4, PI * 0.25, a, r)
	return r


static func square_radius(a: float, half: float) -> float:
	return half / maxf(absf(cos(a)), absf(sin(a)))


static func multiplier(streak: int) -> int:
	return mini(1 + streak / MULT_EVERY, MULT_MAX)


static func wall_points(streak: int) -> int:
	return BASE_POINTS * multiplier(streak)


static func shift_pitch(streak: int) -> float:
	return minf(PITCH_MAX, 1.0 + PITCH_STEP * float(streak))


static func shape_for_tap_x(x: float) -> int:
	if x < TAP_SPLIT_1:
		return CIRCLE
	return TRIANGLE if x < TAP_SPLIT_2 else SQUARE


static func final_score(score: int, lives: int) -> int:
	return score + LIFE_BONUS * lives
