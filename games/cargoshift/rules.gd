extends RefCounted
## Cargo Shift pure rules: 1D ship roll physics, ramp, scoring, bot, headless round sim.
## No nodes, no autoloads.

const EV_SHIFT := 1
const EV_STOP := 2
const EV_THUD := 4
const EV_CAPSIZE := 8

const ROLL_STIFF := 4.0
const ROLL_DAMP := 1.6
const MOMENT_GAIN := 1.0
const BALLAST_MASS := 1.0
const BALLAST_SPEED := 1.25
const CRATE_MASS := 0.5
const CARGO_HOME := [-0.35, 0.35]
const STICK := 0.05
const CARGO_SLIDE := 2.0
const CRATE_GAP_PX := 8.0
const CRATE3_AT := 20.0
const CRATE3_X := 0.6
const CAPSIZE := 0.45
const INVULN := 1.2
const LEVEL_BAND := 0.12
const SWELL_START := 0.05
const SWELL_RAMP := 0.01
const SWELL_MAX := 0.35
const SWELL_PERIOD := 5.0
const LIST_TORQUE := 0.35
const LIST_RISE := 2.5
const LIST_HOLD_END := 10.0
const LIST_FADE := 3.0
const WAVES_AT := 10.0
const WAVE_WARN := 1.5
const WAVE_HIT := 1.0
const WAVE_GAP_START := 6.0
const WAVE_GAP_RAMP := 0.1
const WAVE_GAP_MIN := 3.0
const WAVE_PEAK_START := 0.5
const WAVE_PEAK_RAMP := 0.02
const WAVE_PEAK_MAX := 1.0
const WAVE_PEAK_JITTER := 0.85
const ROUND_TIME := 45.0
const TICK := 1.0
const GRACE_END := 10.0
const HINTS_END := 30.0
const STORM_AT := 30.0
const DIFFICULTY_OFFSET := 30.0
const STEADY_PTS := 10
const STREAK_PTS := 2
const STREAK_CAP := 10
const WAVE_PTS := 25
const LIFE_BONUS := 150
const PITCH_STEP := 0.04
const PITCH_MAX := 1.5
const BOT_LEAD := 0.35
const BOT_KP := 2.5
const BOT_KD := 0.8
const BOT_DEAD := 0.05
const HALF_X := 640.0
const DRAG_GRAB := 96.0
const DRAG_DEAD := 12.0
const LIVES := 3


class Ship extends RefCounted:
	var tilt: float = 0.0
	var roll_v: float = 0.0
	var ballast: float = 0.0
	var cargo: PackedFloat32Array = PackedFloat32Array([-0.35, 0.35])
	var home: PackedFloat32Array = PackedFloat32Array([-0.35, 0.35])
	var last_dir: int = 0
	var invuln: float = 0.0
	var thud_i: int = 0


class Wave extends RefCounted:
	var t_hit: float = 0.0
	var side: int = -1
	var peak: float = 0.0
	var spawn_fail_count: int = 0
	var hit_fired: bool = false
	var done: bool = false


static func ramp_time(t: float, difficulty: int) -> float:
	return t + (DIFFICULTY_OFFSET if difficulty >= 1 else 0.0)


static func swell_amp(r: float) -> float:
	return minf(SWELL_MAX, SWELL_START + SWELL_RAMP * r)


static func swell(r: float, t: float) -> float:
	return swell_amp(r) * sin(TAU * t / SWELL_PERIOD)


## Opening list: a steady push (side = +1 or -1) that rises over LIST_RISE, holds, then fades after LIST_HOLD_END.
static func list_torque(t: float, side: int, difficulty: int = 0) -> float:
	if difficulty >= 1:
		return 0.0
	var up := clampf(t / LIST_RISE, 0.0, 1.0)
	var down := clampf(1.0 - (t - LIST_HOLD_END) / LIST_FADE, 0.0, 1.0)
	return float(side) * LIST_TORQUE * up * down


static func wave_gap(r: float) -> float:
	return maxf(WAVE_GAP_MIN, WAVE_GAP_START - WAVE_GAP_RAMP * (r - WAVES_AT))


static func wave_peak(r: float, rng: RandomNumberGenerator) -> float:
	return minf(WAVE_PEAK_MAX, WAVE_PEAK_START + WAVE_PEAK_RAMP * r) * rng.randf_range(WAVE_PEAK_JITTER, 1.0)


static func wave_torque(waves: Array, t: float) -> float:
	var sum := 0.0
	for w: Wave in waves:
		var u := (t - w.t_hit) / WAVE_HIT
		if u >= 0.0 and u <= 1.0:
			sum += -float(w.side) * w.peak * sin(PI * u)
	return sum


static func phase_name(r: float) -> String:
	if r >= STORM_AT:
		return "STORM"
	if r >= CRATE3_AT:
		return "CARGO"
	if r >= WAVES_AT:
		return "WAVES"
	return ""


static func hints_on(r: float) -> bool:
	return r < HINTS_END


static func is_grace(r: float) -> bool:
	return r < GRACE_END


static func moment(s: Ship) -> float:
	var m := BALLAST_MASS * s.ballast
	for c in s.cargo:
		m += CRATE_MASS * c
	return m


static func step(s: Ship, dt: float, dir: int, ext_torque: float) -> int:
	var ev := 0
	if dir != 0 and dir != s.last_dir:
		ev |= EV_SHIFT
	s.last_dir = dir
	var b0 := s.ballast
	s.ballast = clampf(b0 + dir * BALLAST_SPEED * dt, -1.0, 1.0)
	if dir != 0 and absf(s.ballast) == 1.0 and absf(b0) < 1.0:
		ev |= EV_STOP
	var acc := -ROLL_STIFF * s.tilt - ROLL_DAMP * s.roll_v + MOMENT_GAIN * moment(s) + ext_torque
	s.roll_v += acc * dt
	s.tilt += s.roll_v * dt
	if absf(s.tilt) > STICK:
		for i in s.cargo.size():
			var c0 := s.cargo[i]
			var c := clampf(c0 + CARGO_SLIDE * (s.tilt - signf(s.tilt) * STICK) * dt, -1.0, 1.0)
			s.cargo[i] = c
			if absf(c) == 1.0 and absf(c0) < 1.0:
				ev |= EV_THUD
				s.thud_i = i
	if s.invuln > 0.0:
		s.invuln -= dt
	elif absf(s.tilt) >= CAPSIZE:
		ev |= EV_CAPSIZE
	return ev


static func rescue(s: Ship) -> void:
	s.tilt = 0.0
	s.roll_v = 0.0
	s.ballast = 0.0
	s.cargo = s.home.duplicate()
	s.last_dir = 0
	s.invuln = INVULN


static func add_crate(s: Ship, x: float) -> void:
	s.cargo.append(x)
	s.home.append(x)


## Display positions with at least min_gap (deck units, centre to centre) between crates.
static func spread_cargo(cargo: Array, min_gap: float) -> Array:
	var idx := range(cargo.size())
	idx.sort_custom(func(a, b): return cargo[a] < cargo[b])
	var xs := []
	for i in idx:
		var x: float = cargo[i]
		if not xs.is_empty():
			x = maxf(x, xs[-1] + min_gap)
		xs.append(x)
	var over: float = xs[-1] - 1.0 if not xs.is_empty() else 0.0
	if over > 0.0:
		for k in xs.size():
			xs[k] -= over
		for k in range(xs.size() - 2, -1, -1):
			xs[k] = minf(xs[k], xs[k + 1] - min_gap)
	var out := []
	out.resize(cargo.size())
	for k in idx.size():
		out[idx[k]] = xs[k]
	return out


static func steady_points(streak: int) -> int:
	return STEADY_PTS + STREAK_PTS * mini(streak, STREAK_CAP)


static func shift_pitch(streak: int) -> float:
	return minf(PITCH_MAX, 1.0 + PITCH_STEP * streak)


static func final_score(score: int, lives: int) -> int:
	return score + LIFE_BONUS * lives


static func pointer_dir(pos: Vector2, drag: bool, ballast_sx: float) -> int:
	if drag:
		var gap := pos.x - ballast_sx
		if absf(gap) <= DRAG_DEAD:
			return 0
		return 1 if gap > 0.0 else -1
	return -1 if pos.x < HALF_X else 1


static func is_grab(pos: Vector2, ballast_pos: Vector2) -> bool:
	return pos.distance_to(ballast_pos) <= DRAG_GRAB


static func bot_dir(s: Ship, waves: Array, t: float) -> int:
	var crate_sum := 0.0
	for c in s.cargo:
		crate_sum += c
	var target := -(CRATE_MASS * crate_sum + wave_torque(waves, t + BOT_LEAD) / MOMENT_GAIN) / BALLAST_MASS \
		- BOT_KP * s.tilt - BOT_KD * s.roll_v
	target = clampf(target, -1.0, 1.0)
	if target - s.ballast > BOT_DEAD:
		return 1
	if target - s.ballast < -BOT_DEAD:
		return -1
	return 0


## Same frame order as game.gd, headless. idle = no input at all.
static func sim_round(seed_v: int, difficulty: int, idle: bool = false, tilt6: Array = []) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_v
	var s := Ship.new()
	if ramp_time(0.0, difficulty) >= CRATE3_AT:
		add_crate(s, CRATE3_X * float(rng.randi_range(0, 1) * 2 - 1))
	var waves: Array = []
	var dt := 1.0 / 60.0
	var t := 0.0
	var next_wave_t := maxf(0.0, WAVES_AT - (DIFFICULTY_OFFSET if difficulty >= 1 else 0.0))
	var score := 0
	var streak := 0
	var lives := LIVES
	var tick_t := 0.0
	var tick_max := 0.0
	var capsizes := 0
	var first_capsize := -1.0
	var max_tilt := 0.0
	var shifts := 0
	var wave_count := 0
	for _f in 20000:
		t += dt
		var r := ramp_time(t, difficulty)
		if r >= CRATE3_AT and s.cargo.size() == 2:
			add_crate(s, CRATE3_X * float(rng.randi_range(0, 1) * 2 - 1))
		if r >= WAVES_AT and t >= next_wave_t:
			var w := Wave.new()
			w.t_hit = t + WAVE_WARN
			w.side = rng.randi_range(0, 1) * 2 - 1
			w.peak = wave_peak(r, rng)
			w.spawn_fail_count = capsizes
			waves.append(w)
			wave_count += 1
			next_wave_t = t + wave_gap(r)
		var dir := 0 if idle else bot_dir(s, waves, t)
		var ev := step(s, dt, dir, swell(r, t) + wave_torque(waves, t) + list_torque(t, 1, difficulty))
		if absf(t - 6.0) < dt * 0.5:
			tilt6.append(s.tilt)
		if ev & EV_SHIFT:
			shifts += 1
		max_tilt = maxf(max_tilt, absf(s.tilt))
		if ev & EV_CAPSIZE:
			capsizes += 1
			if first_capsize < 0.0:
				first_capsize = t
			streak = 0
			if not is_grace(r):
				lives -= 1
			rescue(s)
			if lives <= 0:
				return {"won": false, "time": t, "capsizes": capsizes, "first_capsize": first_capsize,
					"max_tilt": max_tilt, "score": score, "waves": wave_count, "shifts": shifts}
		for w: Wave in waves:
			if not w.done and t >= w.t_hit + WAVE_HIT:
				w.done = true
				if capsizes == w.spawn_fail_count:
					score += WAVE_PTS
		waves = waves.filter(func(w: Wave) -> bool: return t <= w.t_hit + WAVE_HIT + 0.5)
		tick_max = maxf(tick_max, absf(s.tilt))
		tick_t += dt
		if tick_t >= TICK:
			tick_t -= TICK
			if tick_max < LEVEL_BAND:
				score += steady_points(streak)
				streak += 1
			else:
				streak = 0
			tick_max = 0.0
		if t >= ROUND_TIME:
			return {"won": true, "time": t, "capsizes": capsizes, "first_capsize": first_capsize,
				"max_tilt": max_tilt, "score": final_score(score, lives), "waves": wave_count, "shifts": shifts}
	return {"won": false, "time": t, "capsizes": capsizes, "first_capsize": first_capsize,
		"max_tilt": max_tilt, "score": score, "waves": wave_count, "shifts": shifts}
