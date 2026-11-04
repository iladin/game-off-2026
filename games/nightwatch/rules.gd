extends RefCounted
## Night Watch rules (pure): three hallway creepers creep while unwatched.

const EV_SHIFT := 1
const EV_REPEL := 2
const EV_EMPTY := 4
const EV_STEP := 8
const EV_BREACH := 16
const FEEDS := 3
const START_FEED := 0
const WAKE_AT := [20.0, 0.0, 10.0]
const FILL_START := 14.0
const FILL_RAMP := 0.3
const FILL_MIN := 4.0
const SPD_LO := 0.85
const SPD_HI := 1.2
const WATCHED_AT := 30.0
const WATCHED_FRAC := 0.25
const FLASH_MIN := 0.2
const FLASH_COOLDOWN := 1.0
const SWITCH_STATIC := 0.15
const BREACH_CALM := 0.5
const LIVES := 3
const ROUND_TIME := 48.0
const HOUR_LEN := 8.0
const GRACE_END := 10.0
const HINTS_END := 30.0
const DIFFICULTY_OFFSET := 30.0
const FLASH_PTS := 10
const DIST_PTS := 40
const STREAK_PTS := 5
const STREAK_CAP := 10
const HOUR_PTS := 50
const LIFE_BONUS := 150
const PITCH_STEP := 0.04
const PITCH_MAX := 1.5
const BAND_1 := 0.5
const BAND_2 := 0.75
const BAND_HYST := 0.05
const HEART_GAP := [0.0, 1.0, 0.55]
const BOT_THINK := 0.12
const BOT_MARGIN := 0.15
const MAIN_RECT := Rect2(170, 140, 730, 450)
const LAMP_RECT := Rect2(170, 600, 730, 104)
const THUMB_RECTS := [Rect2(930, 150, 300, 144), Rect2(930, 310, 300, 144), Rect2(930, 470, 300, 144)]
const TAP_FLASH := 3
const SIL_MIN := 60.0  # main-view silhouette height (px) at d 0
const SIL_MAX := 320.0  # ... and at d 1


class Watch extends RefCounted:
	var d := PackedFloat32Array([0.0, 0.0, 0.0])
	var speed := PackedFloat32Array([1.0, 1.0, 1.0])
	var awake: Array[bool] = [false, false, false]
	var watched: int = 0
	var cooldown: float = 0.0
	var static_t: float = 0.0
	var last_q := PackedInt32Array([0, 0, 0])
	var breach_i: int = -1
	var step_i: int = -1
	var step_q: int = 0
	var flash_d: float = 0.0
	var flash_i: int = 0


static func fresh() -> Watch:
	var s := Watch.new()
	s.watched = START_FEED
	return s


static func ramp_time(t: float, difficulty: int) -> float:
	return t + (DIFFICULTY_OFFSET if difficulty >= 1 else 0.0)


static func fill_time(r: float) -> float:
	return maxf(FILL_MIN, FILL_START - FILL_RAMP * r)


static func phase_name(r: float) -> String:
	if r >= WATCHED_AT:
		return "IT MOVES"
	if r >= WAKE_AT[0]:
		return "CAM 1"
	if r >= WAKE_AT[2]:
		return "CAM 3"
	return ""


static func hints_on(r: float) -> bool:
	return r < HINTS_END


static func is_grace(r: float) -> bool:
	return r < GRACE_END


static func reroll_speed(r: float, rng: RandomNumberGenerator) -> float:
	return 1.0 if r < GRACE_END else rng.randf_range(SPD_LO, SPD_HI)


static func switch(s: Watch, i: int) -> int:
	if i == s.watched:
		return 0
	s.watched = i
	s.static_t = SWITCH_STATIC
	return EV_SHIFT


static func flash(s: Watch, r: float, rng: RandomNumberGenerator) -> int:
	if s.cooldown > 0.0 or s.static_t > 0.0:
		return 0
	s.cooldown = FLASH_COOLDOWN
	var w := s.watched
	if s.awake[w] and s.d[w] >= FLASH_MIN:
		s.flash_d = s.d[w]
		s.flash_i = w
		s.d[w] = 0.0
		s.last_q[w] = 0
		s.speed[w] = reroll_speed(r, rng)
		return EV_REPEL
	return EV_EMPTY


static func breach(s: Watch, i: int, r: float, rng: RandomNumberGenerator) -> void:
	s.d[i] = 0.0
	s.speed[i] = reroll_speed(r, rng)
	for j in FEEDS:
		if j != i and s.d[j] > BREACH_CALM:
			s.d[j] = BREACH_CALM
		s.last_q[j] = int(s.d[j] * 4.0)


static func step(s: Watch, dt: float, r: float, rng: RandomNumberGenerator) -> int:
	var ev := 0
	s.cooldown = maxf(0.0, s.cooldown - dt)
	s.static_t = maxf(0.0, s.static_t - dt)
	s.breach_i = -1
	s.step_i = -1
	for i in FEEDS:
		if not s.awake[i] and r >= WAKE_AT[i]:
			s.awake[i] = true
			s.d[i] = 0.0
			s.last_q[i] = 0
			s.speed[i] = reroll_speed(r, rng)
	var ft := fill_time(r)
	for i in FEEDS:
		if not s.awake[i]:
			continue
		var k := 1.0
		if i == s.watched:
			k = WATCHED_FRAC if r >= WATCHED_AT else 0.0
		s.d[i] += s.speed[i] * k * dt / ft
		var q := int(s.d[i] * 4.0)
		if i != s.watched and q > s.last_q[i] and q <= 3:
			ev |= EV_STEP
			s.step_i = i
			s.step_q = q
		s.last_q[i] = q
	for i in FEEDS:
		if s.awake[i] and s.d[i] >= 1.0:
			ev |= EV_BREACH
			s.breach_i = i
			breach(s, i, r, rng)
			break
	return ev


## Highest d among awake unwatched feeds.
static func danger(s: Watch) -> float:
	var m := 0.0
	for i in FEEDS:
		if i != s.watched and s.awake[i]:
			m = maxf(m, s.d[i])
	return m


## Height in px of the main-view creeper silhouette for a feed at distance d.
static func silhouette_h(d: float) -> float:
	return lerpf(SIL_MIN, SIL_MAX, clampf(d, 0.0, 1.0))


static func danger_band(dmax: float, prev: int) -> int:
	var b := prev
	if dmax >= BAND_2:
		b = maxi(b, 2)
	elif dmax >= BAND_1:
		b = maxi(b, 1)
	while b > 0 and dmax < (BAND_2 if b == 2 else BAND_1) - BAND_HYST:
		b -= 1
	return b


static func flash_points(d: float, streak: int) -> int:
	return FLASH_PTS + int(DIST_PTS * d) + STREAK_PTS * mini(streak, STREAK_CAP)


static func shift_pitch(streak: int) -> float:
	return minf(PITCH_MAX, 1.0 + PITCH_STEP * streak)


static func final_score(score: int, lives: int) -> int:
	return score + LIFE_BONUS * lives


static func clock_text(t: float) -> String:
	var h := mini(6, int(t / HOUR_LEN))
	return "%d AM" % (12 if h == 0 else h)


static func tap_target(p: Vector2) -> int:
	for i in FEEDS:
		if THUMB_RECTS[i].has_point(p):
			return i
	if MAIN_RECT.has_point(p) or LAMP_RECT.has_point(p):
		return TAP_FLASH
	return -1


## The unwatched flashable feed with the highest d, or -1.
static func hint_feed(s: Watch) -> int:
	var best := -1
	var bd := FLASH_MIN
	for i in FEEDS:
		if i != s.watched and s.awake[i] and s.d[i] >= bd:
			bd = s.d[i]
			best = i
	return best


## 0-2 switch to that feed, 3 flash, -1 nothing.
static func bot_action(s: Watch) -> int:
	var w := s.watched
	var fw: bool = s.awake[w] and s.d[w] >= FLASH_MIN
	if fw and s.cooldown <= 0.0 and s.static_t <= 0.0:
		return TAP_FLASH
	var j := hint_feed(s)
	if j >= 0 and (not fw or s.d[j] > s.d[w] + BOT_MARGIN):
		return j
	return -1


static func sim_round(seed_v: int, difficulty: int, idle: bool = false) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_v
	var s := Watch.new()
	var res := {"won": false, "time": 0.0, "breaches": 0, "first_breach": -1.0, "max_d": 0.0,
		"score": 0, "flashes": 0, "shifts": 0, "empties": 0}
	var dt := 1.0 / 60.0
	var t := 0.0
	var think := 0.0
	var lives := LIVES
	var streak := 0
	var hour := 0
	while t < ROUND_TIME + 1.0:
		t += dt
		var r := ramp_time(t, difficulty)
		think -= dt
		if not idle and think <= 0.0:
			var a := bot_action(s)
			if a >= 0:
				think = BOT_THINK
				if a == TAP_FLASH:
					var e := flash(s, r, rng)
					if e == EV_REPEL:
						res.score += flash_points(s.flash_d, streak)
						streak += 1
						res.flashes += 1
					elif e == EV_EMPTY:
						streak = 0
						res.empties += 1
				elif switch(s, a) != 0:
					res.shifts += 1
		var ev := step(s, dt, r, rng)
		res.max_d = maxf(res.max_d, maxf(danger(s), s.d[s.watched]))
		if ev & EV_BREACH:
			res.breaches += 1
			streak = 0
			if res.first_breach < 0.0:
				res.first_breach = t
			if not is_grace(r):
				lives -= 1
				if lives <= 0:
					res.time = t
					return res
		if int(t / HOUR_LEN) > hour:
			hour = int(t / HOUR_LEN)
			res.score += HOUR_PTS
		if t >= ROUND_TIME:
			res.won = true
			res.time = t
			res.score = final_score(res.score, lives)
			return res
	res.time = t
	return res
