extends SceneTree
## Run: godot --headless --path . --script res://games/redshift/selftest.gd

const R := preload("res://games/redshift/rules.gd")
var fails: Array[String] = []


func _t(ok: bool, msg: String) -> void:
	if not ok:
		fails.append(msg)


func _enemy(s: R.Run, x: float, y: float, band: int, heavy: bool = false) -> R.Enemy:
	var e := R.Enemy.new()
	e.pos = Vector2(x, y)
	e.band = band
	e.heavy = heavy
	e.hp = R.HEAVY_HP if heavy else 1
	e.radius = R.HEAVY_R if heavy else R.ENEMY_R
	s.enemies.append(e)
	return e


func _quiet() -> R.Run:
	var s := R.Run.new()
	s.spawn_t = 999.0
	return s


func _init() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var dt := 1.0 / 60.0
	_t(R.ramp_time(5, 0) == 5.0 and R.ramp_time(5, 1) == 35.0, "ramp_time")
	_t(R.enemy_speed(0) == 150.0 and R.enemy_speed(20) == 220.0 and R.enemy_speed(100) == 260.0, "enemy_speed")
	_t(R.spawn_gap(0) == 1.6 and R.spawn_gap(100) == 0.85, "spawn_gap")
	_t(R.spawn_bands(5) == [1] and R.spawn_bands(15) == [0, 1] and R.spawn_bands(25).size() == 3, "spawn_bands")
	_t(R.phase_name(5) == "" and R.phase_name(15) == "RED" and R.phase_name(25) == "BLUE" and R.phase_name(35) == "HEAVY", "phase_name")
	_t(R.is_grace(9.9) and not R.is_grace(10.0), "grace")
	_t(R.hints_on(29.9) and not R.hints_on(30.0), "hints")
	# (a) shift
	var s := R.Run.new()
	_t(R.shift(s, -1) == R.EV_SHIFT and s.band == 0 and R.shift(s, -1) == 0, "shift down and end stop")
	_t(R.shift(s, 1) == R.EV_SHIFT and R.shift(s, 1) == R.EV_SHIFT and s.band == 2 and R.shift(s, 1) == 0, "shift up")
	# (b) k eases
	s = _quiet()
	s.band = 2
	for i in 60:
		R.step(s, dt, 0.0, 0.0, rng)
	_t(absf(s.k - 1.3) < 0.02, "k eases to 1.3")
	# (c) kill and block
	s = _quiet()
	_enemy(s, 600.0, s.ship_y, 1)
	var kills := 0
	var pts := 0
	for i in 60:
		var ev := R.step(s, dt, 0.0, 0.0, rng)
		if ev & R.EV_KILL:
			kills += 1
			pts = s.kills[0].pts
	_t(kills == 1 and pts == 10, "lime kills lime")
	s = _quiet()
	_enemy(s, 600.0, s.ship_y, 0)
	kills = 0
	var blocks := 0
	for i in 40:
		var ev := R.step(s, dt, 0.0, 0.0, rng)
		if ev & R.EV_KILL:
			kills += 1
		if ev & R.EV_BLOCK:
			blocks += 1
	_t(kills == 0 and blocks > 0, "ember not hurt by lime")
	# (d) heavy
	s = _quiet()
	_enemy(s, 600.0, s.ship_y, 1, true)
	var dmg := 0
	pts = 0
	for i in 90:
		var ev := R.step(s, dt, 0.0, 0.0, rng)
		if ev & R.EV_DAMAGE:
			dmg += 1
		if ev & R.EV_KILL:
			pts = s.kills[0].pts
	_t(dmg == 2 and pts == 30, "heavy takes 3 hits")
	# (e) crash
	s = _quiet()
	_enemy(s, R.SHIP_X, s.ship_y, 0)
	var ev2 := R.step(s, dt, 0.0, 0.0, rng)
	_t((ev2 & R.EV_CRASH) != 0 and s.invuln > 0.98, "crash")
	_enemy(s, R.SHIP_X, s.ship_y, 0)
	_t((R.step(s, dt, 0.0, 0.0, rng) & R.EV_CRASH) == 0, "invuln blocks second crash")
	# (f) clamp
	s = _quiet()
	for i in 120:
		R.step(s, dt, 0.0, -1.0, rng)
	_t(s.ship_y == R.SHIP_Y_MIN, "ship clamps")
	# sims
	for sd in range(1, 11):
		for d in 2:
			var o := R.sim_round(sd, d)
			_t(o.won and o.crashes <= 2 and o.time > 49.9 and o.time < 50.1 and o.kills >= 30 and o.shifts >= 10, "sim seed %d d%d %s" % [sd, d, str(o)])
		var idle := R.sim_round(sd, 0, "idle")
		_t(not idle.won and idle.first_crash > 3.0 and idle.time < 50.0, "idle seed %d %s" % [sd, str(idle)])
	# scoring, sound, input
	_t(R.kill_points(0, false) == 10 and R.kill_points(99, false) == 30 and R.kill_points(0, true) == 30, "kill_points")
	_t(R.shift_pitch(100) == 1.5 and R.final_score(1000, 2) == 1200, "pitch and final")
	_t(R.loop_notes(0)[0] == 40 and R.loop_notes(2)[0] == 52 and R.loop_notes(0)[1] == 0, "loop_notes")
	_t(R.tap_target(Vector2(960, 650)) == R.TAP_BRAKE and R.tap_target(Vector2(1160, 650)) == R.TAP_BOOST, "tap pads")
	_t(R.tap_target(Vector2(400, 300)) == R.TAP_MOVE and R.tap_target(Vector2(60, 30)) == -1 and R.tap_target(Vector2(1000, 300)) == -1, "tap move/corner")
	_t(R.BRAKE_RECT.size.x >= 96 and R.BRAKE_RECT.size.y >= 96 and R.BOOST_RECT.size.x >= 96 and R.BOOST_RECT.size.y >= 96, "pads 96")
	_t(R.BRAKE_RECT.position.x > 150 and R.BOOST_RECT.end.x <= 1280 and R.BRAKE_RECT.position.y > 70, "pads clear corners")
	_t(R.follow_dir(100, 340) == -1.0 and R.follow_dir(343, 340) == 0.0, "follow_dir")
	for f in fails:
		printerr("SELFTEST FAIL: " + f)
	if fails.is_empty():
		print("SELFTEST OK")
	quit(1 if not fails.is_empty() else 0)
