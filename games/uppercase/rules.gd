extends RefCounted
## Upper Case pure rules: no nodes, no autoloads, asserted by selftest.gd.

const LEFT := 0
const RIGHT := 1
const NONE := 0
const GOOD := 1
const PERFECT := 2

const ROWS: Array[String] = ["QWERTYUIOP", "ASDFGHJKL", "ZXCVBNM"]
const ROW_X0: Array[float] = [240.0, 260.0, 300.0]
const ROW_Y: Array[float] = [502.0, 536.0, 570.0]
const KEY_PITCH := 80.0
const KEY_W := 72.0
const KEY_H := 30.0
const SPLIT_COL := 5

const BPM := 112.0
const BEAT := 60.0 / 112.0
const SPAWN_Y := 140.0
const TILE_GONE_Y := 530.0 ## tile top edge is below the fall area (494) by here
const LINE_Y := 450.0
const PERFECT_PX := 16.0
const GOOD_PX := 44.0

const FAST_AT := 10.0
const TOP_AT := 40.0
const LOWER_AT := 20.0
const HINTS_END := 30.0
const GRACE_END := 10.0
const SPAWN_EVERY_SLOW_END := 20.0
const DIFFICULTY_OFFSET := 30.0
const SPAWN_END := 44.0
const TRAVEL_SLOW := 4.0
const TRAVEL_MID := 3.0
const TRAVEL_TOP := 2.0
const LOWER_CHANCES: Array[float] = [0.25, 0.30, 0.35]

const POINTS: Array[int] = [0, 15, 30]
const STREAK_PTS := 2
const STREAK_CAP := 10
const LOWER_PASS_PTS := 5
const LIFE_BONUS := 50
const PITCH_STEP := 0.04
const PITCH_MAX := 1.5


static func ramp_time(t: float, difficulty: int) -> float:
	return t + (DIFFICULTY_OFFSET if difficulty >= 1 else 0.0)


static func _pos(ch: String) -> Vector2i:
	var u := ch.to_upper()
	for row in ROWS.size():
		var col: int = ROWS[row].find(u)
		if col >= 0:
			return Vector2i(row, col)
	return Vector2i(0, 0)


static func side_of(ch: String) -> int:
	return LEFT if _pos(ch).y < SPLIT_COL else RIGHT


static func correct_shift(ch: String) -> int:
	return 1 - side_of(ch)


static func key_center(ch: String) -> Vector2:
	var p := _pos(ch)
	return Vector2(ROW_X0[p.x] + p.y * KEY_PITCH + KEY_W * 0.5, ROW_Y[p.x] + KEY_H * 0.5)


static func spawn_every(r: float) -> int:
	return 2 if r < SPAWN_EVERY_SLOW_END else 1


static func travel_beats(r: float) -> float:
	if r < FAST_AT:
		return TRAVEL_SLOW
	if r < TOP_AT:
		return TRAVEL_MID
	return TRAVEL_TOP


static func lower_chance(r: float) -> float:
	if r < LOWER_AT:
		return 0.0
	if r < 30.0:
		return LOWER_CHANCES[0]
	if r < TOP_AT:
		return LOWER_CHANCES[1]
	return LOWER_CHANCES[2]


static func hints_on(r: float) -> bool:
	return r < HINTS_END


static func is_grace(r: float) -> bool:
	return r < GRACE_END


static func phase_name(r: float) -> String:
	if r < FAST_AT:
		return ""
	if r < LOWER_AT:
		return "FASTER"
	if r < HINTS_END:
		return "LET LOWER PASS"
	if r < TOP_AT:
		return "NO HINTS"
	return "TOP SPEED"


static func letter_y(age_beats: float, travel: float) -> float:
	return SPAWN_Y + (LINE_Y - SPAWN_Y) * age_beats / travel


static func judge(dy: float) -> int:
	var a := absf(dy)
	if a <= PERFECT_PX:
		return PERFECT
	if a <= GOOD_PX:
		return GOOD
	return NONE


static func is_missed(y: float) -> bool:
	return y > LINE_Y + GOOD_PX


static func hit_points(j: int, streak: int) -> int:
	return POINTS[j] + STREAK_PTS * mini(streak, STREAK_CAP)


static func shift_pitch(streak: int) -> float:
	return minf(PITCH_MAX, 1.0 + PITCH_STEP * streak)


static func final_score(score: int, lives: int) -> int:
	return score + LIFE_BONUS * lives


static func side_for_tap_x(x: float) -> int:
	return LEFT if x < 640.0 else RIGHT
