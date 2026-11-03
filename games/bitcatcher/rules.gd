extends RefCounted
## Bit Catcher pure rules: 8-bit rotates, landing outcomes, ramp, scoring, touch zones.

const LEFT := 0
const RIGHT := 1
const DROP := 2
const SET := 0
const WRONG := 1
const DODGE := 2
const LOST := 3
const CELLS := 8
const COL_X0 := 198.0
const CELL_W := 100.0
const CELL_GAP := 12.0
const CELL_PITCH := 112.0
const REG_Y := 480.0
const SPAWN_Y := 220.0
const LAND_Y := 440.0
const FALL_TIMES: Array[float] = [3.0, 2.4, 2.1, 1.8, 1.5]
const FAST_SPEED := 1300.0
const SPAWN_GAPS: Array[float] = [0.45, 0.30]
const ZERO_AT := 20.0
const ZERO_CHANCES: Array[float] = [0.25, 0.30]
const HINTS_END := 30.0
const GRACE_END := 10.0
const FAST_AT := 10.0
const TOP_AT := 40.0
const DIFFICULTY_OFFSET := 30.0
const BYTES_TO_WIN := 8
const SET_PTS := 10
const STREAK_PTS := 2
const STREAK_CAP := 10
const FAST_PTS := 5
const BYTE_PTS := 100
const DODGE_PTS := 5
const LIFE_BONUS := 50
const PITCH_STEP := 0.04
const PITCH_MAX := 1.5
const PAD_Y := 600.0
const PAD_SPLIT_L := 480.0
const PAD_SPLIT_R := 800.0


static func ramp_time(t: float, difficulty: int) -> float:
	return t + (DIFFICULTY_OFFSET if difficulty >= 1 else 0.0)


static func rol8(x: int) -> int:
	return ((x << 1) | (x >> 7)) & 0xFF


static func ror8(x: int) -> int:
	return ((x >> 1) | (x << 7)) & 0xFF


## d > 0: d rotates right; d < 0: -d rotates left.
static func rotate8(x: int, d: int) -> int:
	var v := x & 0xFF
	var n := posmod(d, 8)
	for i in n:
		v = ror8(v)
	return v


static func col_mask(c: int) -> int:
	return 1 << (7 - c)


static func bit_at(x: int, c: int) -> int:
	return 1 if (x & col_mask(c)) != 0 else 0


static func popcount8(x: int) -> int:
	var n := 0
	for c in CELLS:
		n += bit_at(x, c)
	return n


static func land_one(reg: int, target: int, c: int) -> int:
	return SET if bit_at(target, c) == 1 and bit_at(reg, c) == 0 else WRONG


static func land_zero(reg: int, c: int) -> int:
	return LOST if bit_at(reg, c) == 1 else DODGE


static func apply_one(reg: int, c: int) -> int:
	return reg | col_mask(c)


static func apply_zero(reg: int, c: int) -> int:
	return reg & ~col_mask(c) & 0xFF


static func make_target(ones: int, prev: int, rng: RandomNumberGenerator) -> int:
	while true:
		var x := 0
		while popcount8(x) < ones:
			x |= col_mask(rng.randi_range(0, CELLS - 1))
		if x != prev:
			return x
	return 0


## Smallest shift d in -4..4 that makes the falling bit good; ties prefer negative; 0 if none.
static func best_shift(reg: int, target: int, c: int, is_one: bool) -> int:
	var order: Array[int] = [0, -1, 1, -2, 2, -3, 3, -4, 4]
	for d in order:
		var rr := rotate8(reg, d)
		if is_one:
			if land_one(rr, rotate8(target, d), c) == SET:
				return d
		elif land_zero(rr, c) == DODGE:
			return d
	return 0


static func _band(r: float) -> int:
	return clampi(int(r / 10.0), 0, 4)


static func fall_time(r: float) -> float:
	return FALL_TIMES[_band(r)]


static func fall_speed(r: float) -> float:
	return (LAND_Y - SPAWN_Y) / fall_time(r)


static func spawn_gap(r: float) -> float:
	return SPAWN_GAPS[0] if r < 20.0 else SPAWN_GAPS[1]


static func ones_for(r: float) -> int:
	if r < 10.0:
		return 2
	return 3 if r < 30.0 else 4


static func zero_chance(r: float) -> float:
	if r < ZERO_AT:
		return 0.0
	return ZERO_CHANCES[0] if r < TOP_AT else ZERO_CHANCES[1]


static func hints_on(r: float) -> bool:
	return r < HINTS_END


static func is_grace(r: float) -> bool:
	return r < GRACE_END


static func phase_name(r: float) -> String:
	if r < 10.0:
		return ""
	if r < 20.0:
		return "FASTER"
	if r < 30.0:
		return "ZEROS"
	return "NO HINTS" if r < TOP_AT else "TOP SPEED"


static func hit_points(streak: int, fast: bool) -> int:
	return SET_PTS + STREAK_PTS * mini(streak, STREAK_CAP) + (FAST_PTS if fast else 0)


static func shift_pitch(streak: int) -> float:
	return minf(PITCH_MAX, 1.0 + PITCH_STEP * streak)


static func final_score(score: int, lives: int) -> int:
	return score + LIFE_BONUS * lives


static func bits_string(x: int) -> String:
	var s := ""
	for c in CELLS:
		s += str(bit_at(x, c))
	return s


static func bytes_string(n: int) -> String:
	var s := ""
	for i in CELLS:
		s += "1" if i < n else "0"
	return s


static func touch_zone(pos: Vector2) -> int:
	if pos.y >= PAD_Y:
		if pos.x < PAD_SPLIT_L:
			return LEFT
		return DROP if pos.x < PAD_SPLIT_R else RIGHT
	return LEFT if pos.x < 640.0 else RIGHT


static func col_x(c: int) -> float:
	return COL_X0 + CELL_W * 0.5 + CELL_PITCH * c
