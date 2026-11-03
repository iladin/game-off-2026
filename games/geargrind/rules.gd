extends RefCounted
## Gear Grind pure rules: judging, ramp, car model, rival. No nodes, no autoloads.

const EARLY := 0
const GOOD := 1
const PERFECT := 2
const LATE := 3

const TRACK := 300.0
const CAPS: Array[float] = [22.0, 33.0, 48.0, 66.0, 86.0]
const REV: Array[float] = [0.50, 0.42, 0.36, 0.31, 0.27]
const BOOST_MULT := 1.8
const BOOST_TIME := 0.5
const BOG_MULT := 0.25
const BOG_TIME := 0.7
const BLOW_TIME := 0.9
const BAND_CENTER := 0.80
const BAND_START := 0.30
const BAND_DROP := 0.003
const BAND_MIN := 0.16
const BAND_MIN_LO := 0.40
const BAND_MAX_HI := 0.97
const MOVE_AT := 30.0
const MOVE_OFFSETS: Array[float] = [-0.10, -0.05, 0.0, 0.05]
const GEARS_4_AT := 20.0
const GEARS_5_AT := 40.0
const GRACE_END := 10.0
const DIFFICULTY_OFFSET := 30.0
const PAR_TIME: Array[float] = [0.0, 0.0, 0.0, 7.92, 6.53, 5.78]
const RIVAL_START := 1.32
const RIVAL_DROP := 0.0055
const RIVAL_MIN := 1.10
const RIVAL_POW := 1.6
const POINTS: Array[int] = [0, 15, 30, 5]
const HEAT_POINTS := 100
const MARGIN_PTS := 50.0
const LIFE_BONUS := 50
const PITCH_STEP := 0.04
const PITCH_MAX := 1.5
const RPM_MAX := 1.1
const IDLE_RPM := 0.08
const ENGINE_LO := 55.0
const ENGINE_SPAN := 165.0


static func ramp_time(elapsed: float, difficulty: int) -> float:
	return elapsed + (DIFFICULTY_OFFSET if difficulty >= 1 else 0.0)


static func gears_for(r: float) -> int:
	if r < GEARS_4_AT:
		return 3
	return 4 if r < GEARS_5_AT else 5


static func band_width(r: float) -> float:
	return maxf(BAND_MIN, BAND_START - BAND_DROP * r)


static func band_offset(roll: int, r: float) -> float:
	if r < MOVE_AT:
		return 0.0
	return MOVE_OFFSETS[roll % MOVE_OFFSETS.size()]


## x = lo, y = hi
static func band(r: float, roll: int) -> Vector2:
	var c := BAND_CENTER + band_offset(roll, r)
	var w := band_width(r)
	return Vector2(maxf(BAND_MIN_LO, c - w * 0.5), minf(BAND_MAX_HI, c + w * 0.5))


static func judge(rpm_v: float, lo: float, hi: float) -> int:
	if rpm_v < lo:
		return EARLY
	if rpm_v > hi:
		return LATE
	if absf(rpm_v - (lo + hi) * 0.5) <= (hi - lo) / 6.0:
		return PERFECT
	return GOOD


static func shift_points(j: int) -> int:
	return POINTS[j]


static func accel(g: int, boost_t: float, bog_t: float) -> float:
	var m := 1.0
	if boost_t > 0.0:
		m = BOOST_MULT
	elif bog_t > 0.0:
		m = BOG_MULT
	return CAPS[g] * REV[g] * m


static func rpm(v: float, g: int) -> float:
	return v / CAPS[g]


static func blow_on(r: float) -> bool:
	return r >= GRACE_END


static func is_grace(r: float) -> bool:
	return r < GRACE_END


static func rival_mult(r: float) -> float:
	return maxf(RIVAL_MIN, RIVAL_START - RIVAL_DROP * r)


static func rival_time(gears: int, r: float) -> float:
	return PAR_TIME[gears] * rival_mult(r)


static func rival_dist(t: float, total: float) -> float:
	return TRACK * pow(clampf(t / total, 0.0, 1.0), RIVAL_POW)


## The car model at dt 1/60, shifting the first frame rpm >= shift_rpm. Returns seconds.
static func simulate(gears: int, shift_rpm: float, lo: float, hi: float) -> float:
	var dt := 1.0 / 60.0
	var g := 0
	var v := 0.0
	var d := 0.0
	var t := 0.0
	var boost_t := 0.0
	var bog_t := 0.0
	while t < 60.0:
		var a := accel(g, boost_t, bog_t)
		boost_t -= dt
		bog_t -= dt
		v = minf(CAPS[g], v + a * dt)
		d += v * dt
		t += dt
		if d >= TRACK:
			return t
		if g < gears - 1 and rpm(v, g) >= shift_rpm:
			var j := judge(rpm(v, g), lo, hi)
			g += 1
			if j == PERFECT:
				boost_t = BOOST_TIME
			elif j == EARLY:
				bog_t = BOG_TIME
				boost_t = 0.0
	return t


static func heat_bonus(margin_s: float) -> int:
	return int(MARGIN_PTS * margin_s)


static func final_score(score: int, lives: int) -> int:
	return score + LIFE_BONUS * lives


static func shift_pitch(streak: int) -> float:
	return minf(PITCH_MAX, 1.0 + PITCH_STEP * streak)


static func needle_angle(rpm_v: float) -> float:
	return PI + PI * clampf(rpm_v, 0.0, RPM_MAX) / RPM_MAX


static func engine_hz(rpm_v: float) -> float:
	return ENGINE_LO + ENGINE_SPAN * clampf(rpm_v, 0.0, RPM_MAX)


static func phase_name(r: float) -> String:
	if r < GRACE_END:
		return ""
	if r < GEARS_4_AT:
		return "WATCH THE RED"
	if r < MOVE_AT:
		return "FOURTH GEAR"
	if r < GEARS_5_AT:
		return "BAND MOVES"
	return "FIFTH GEAR"


const POP_RISE := 70.0  # must match Juice.popup: rises 70 px, cubic ease-out, over 0.7 s
const POP_RISE_TIME := 0.7
const POP_LIFE := 0.95  # rise + fade; after this the earlier popup is gone
const POP_STEP := 40.0  # min vertical gap between stacked popup baselines


## Current baseline y of a popup born at birth_y, age seconds ago (cubic ease-out rise).
static func popup_y_now(birth_y: float, age: float) -> float:
	var k := clampf(age / POP_RISE_TIME, 0.0, 1.0)
	return birth_y - POP_RISE * (1.0 - pow(1.0 - k, 3.0))


const POP_SLOTS := 3


## Popups born within POP_LIFE of the previous one take the next slot down (slot * STEP below
## base). Every popup rises along the same curve, so slots stay STEP apart for their whole life
## (a gap measured only at birth, or from the earlier one's current y, vanishes as both rise).
## An expired or missing previous popup resets to slot 0. After the last slot it wraps to 0.
static func popup_slot(prev_slot: int, prev_age: float) -> int:
	if prev_slot < 0 or prev_age < 0.0 or prev_age >= POP_LIFE:
		return 0
	return (prev_slot + 1) % POP_SLOTS


static func popup_slot_y(base_y: float, slot: int) -> float:
	return base_y + POP_STEP * float(slot)
