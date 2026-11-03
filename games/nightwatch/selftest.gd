extends SceneTree
## Run: godot --headless --path . --script res://games/nightwatch/selftest.gd

const R := preload("res://games/nightwatch/rules.gd")
var fails: Array[String] = []


func _t(ok: bool, msg: String) -> void:
	if not ok:
		fails.append(msg)


func _init() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	_t(R.ramp_time(5, 0) == 5.0 and R.ramp_time(5, 1) == 35.0, "ramp_time")
	_t(R.fill_time(0) == 14.0 and absf(R.fill_time(20) - 8.0) < 1e-4 and R.fill_time(100) == 4.0, "fill_time")
	_t(R.phase_name(5) == "" and R.phase_name(15) == "CAM 3" and R.phase_name(25) == "CAM 1" and R.phase_name(35) == "IT MOVES", "phase_name")
	_t(R.is_grace(9.9) and not R.is_grace(10.0), "grace")
	_t(R.hints_on(29.9) and not R.hints_on(30.0), "hints")
	_t(R.clock_text(0) == "12 AM" and R.clock_text(8.0) == "1 AM" and R.clock_text(47.9) == "5 AM" and R.clock_text(48.0) == "6 AM", "clock_text")
	# (a) creep
	var s := R.Watch.new()
	for i in 60:
		R.step(s, 1.0 / 60.0, 0.0, rng)
	_t(s.awake[1] and not s.awake[0] and not s.awake[2], "only feed 2 awake")
	_t(absf(s.d[1] - 1.0 / 14.0) < 1e-3 and s.d[0] == 0.0 and s.d[2] == 0.0, "feed 2 creeps 1/14 in 1s")
	# (b) watching freezes
	_t(R.switch(s, 1) == R.EV_SHIFT and R.switch(s, 1) == 0, "switch")
	var d1: float = s.d[1]
	for i in 300:
		R.step(s, 1.0 / 60.0, 5.0, rng)
	_t(absf(s.d[1] - d1) < 1e-6, "watched freezes")
	# (c) IT MOVES
	var a := s.d[1]
	R.step(s, 1.0, 35.0, rng)
	var moved: float = s.d[1] - a
	var b := s.d[0]
	R.step(s, 0.01, 35.0, rng)
	_t(moved > 0.0 and s.d[0] >= b, "watched creeps at r35")
	var s2 := R.Watch.new()
	s2.awake = [true, true, true]
	s2.speed = PackedFloat32Array([1, 1, 1])
	s2.watched = 1
	R.step(s2, 1.0, 35.0, rng)
	_t(absf(s2.d[1] / s2.d[0] - 0.25) < 0.01, "quarter rate")
	# (d) flash
	var s3 := R.Watch.new()
	s3.awake = [true, false, false]
	s3.d[0] = 0.1
	_t(R.flash(s3, 5.0, rng) == R.EV_EMPTY and s3.cooldown == 1.0, "flash empty")
	_t(R.flash(s3, 5.0, rng) == 0, "flash cooldown")
	s3.cooldown = 0.0
	s3.d[0] = 0.6
	_t(R.flash(s3, 5.0, rng) == R.EV_REPEL and s3.d[0] == 0.0 and absf(s3.flash_d - 0.6) < 1e-6, "flash repel")
	# (e) breach
	var s4 := R.Watch.new()
	s4.awake = [true, true, true]
	s4.watched = 0
	s4.d[1] = 0.99
	s4.d[2] = 0.8
	var nb := 0
	for i in 30:
		if R.step(s4, 1.0 / 60.0, 5.0, rng) & R.EV_BREACH:
			nb += 1
	_t(nb == 1 and s4.d[1] < 0.1 and s4.d[2] <= 0.6, "breach")
	# (f) footsteps
	var s5 := R.Watch.new()
	s5.awake = [false, true, false]
	var steps := 0
	while s5.d[1] < 0.8:
		if R.step(s5, 1.0 / 60.0, 5.0, rng) & R.EV_STEP:
			steps += 1
	_t(steps == 3, "3 footsteps got %d" % steps)
	# bot / idle
	for sd in range(1, 21):
		for df in 2:
			var o := R.sim_round(sd, df)
			_t(o.won and o.breaches == 0 and o.time > 47.9 and o.time < 48.1 and o.empties == 0 and o.flashes >= 25 and o.max_d < 0.85,
				"bot seed %d d%d %s" % [sd, df, str(o)])
		var idle := R.sim_round(sd, 0, true)
		_t(not idle.won and idle.first_breach > 10.0 and idle.time < 30.0, "idle seed %d %s" % [sd, str(idle)])
	# scoring / input
	_t(R.flash_points(0.5, 0) == 30 and R.flash_points(0.5, 99) == 80, "flash_points")
	_t(R.shift_pitch(100) == 1.5 and R.final_score(1000, 2) == 1300, "pitch/final")
	_t(R.tap_target(Vector2(1000, 200)) == 0 and R.tap_target(Vector2(1000, 520)) == 2 and R.tap_target(Vector2(500, 300)) == 3
		and R.tap_target(Vector2(500, 650)) == 3 and R.tap_target(Vector2(1260, 700)) == -1, "tap_target")
	for rc: Rect2 in R.THUMB_RECTS:
		_t(rc.size.x >= 96 and rc.size.y >= 96, "thumb size")
	_t(R.danger_band(0.6, 0) == 1 and R.danger_band(0.8, 0) == 2 and R.danger_band(0.72, 2) == 2
		and R.danger_band(0.68, 2) == 1 and R.danger_band(0.47, 1) == 1 and R.danger_band(0.44, 1) == 0, "danger_band")
	if fails.is_empty():
		print("SELFTEST OK")
		quit(0)
	else:
		for f in fails:
			print("FAIL: ", f)
		quit(1)
