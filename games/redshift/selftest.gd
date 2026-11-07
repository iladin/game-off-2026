extends SceneTree
## Run: godot --headless --path . --script res://games/redshift/selftest.gd

const R := preload("res://games/redshift/rules.gd")
const Bot := preload("res://games/redshift/rules_bot.gd")
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
	_t(R.teach_pad(0.0, 1, -1) == -1 and R.teach_pad(2.0, 1, -1) == -1 and R.teach_pad(5.5, 1, -1) == -1 and R.teach_pad(9.9, 1, 1) == -1, "teach: BRAKE cued before first ember enemy")
	_t(R.teach_pad(10.5, 1, -1) == 0 and R.teach_pad(14.9, 1, -1) == 0 and R.teach_pad(16.0, 1, -1) == 1 and R.teach_pad(12.0, 1, 2) == 1 and R.teach_pad(12.0, 1, 0) == -1 and R.teach_pad(12.0, 1, 1) == 0, "teach: BOOST before blue, target-based after")
	_t(R.teach_pad(35.0, 1, 2) == 0, "teach: off with hints")
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
	# (g) enemy bullets: fire, hit the ship, get popped by a matching shot, pass a wrong-band shot
	s = _quiet()
	var sh_e := _enemy(s, 900.0, 200.0, 0)
	sh_e.shooter = true
	var fev := 0
	for i in 60:
		fev |= R.step(s, dt, R.FIRE_AT, 0.0, rng)
	_t((fev & R.EV_FIRE) != 0 and s.bullets.size() == 1 and s.bullets[0].band == 0 and s.bullets[0].vel.x < 0.0, "shooter fires a band-coloured bullet")
	_t(absf(s.bullets[0].vel.length() - R.BULLET_SPEED) < 0.01, "bullet speed")
	s = _quiet()
	var shy := _enemy(s, 900.0, 200.0, 0)
	shy.shooter = true
	for i in 120:
		R.step(s, dt, R.FIRE_AT - 5.0, 0.0, rng)
	_t(s.bullets.is_empty(), "no return fire before FIRE_AT")
	s = _quiet()
	var bu := R.EBullet.new()
	bu.pos = Vector2(R.SHIP_X + 40.0, s.ship_y)
	bu.vel = Vector2(-R.BULLET_SPEED, 0.0)
	bu.band = 0
	s.bullets.append(bu)
	var bev := 0
	for i in 30:
		bev |= R.step(s, dt, 25.0, 0.0, rng)
	_t((bev & R.EV_CRASH) != 0 and s.invuln > 0.0 and s.bullets.is_empty(), "bullet hit costs a crash")
	s = _quiet()
	s.invuln = 1.0
	bu = R.EBullet.new()
	bu.pos = Vector2(R.SHIP_X + 10.0, s.ship_y)
	bu.vel = Vector2(-R.BULLET_SPEED, 0.0)
	bu.band = 0
	s.bullets.append(bu)
	_t((R.step(s, dt, 25.0, 0.0, rng) & R.EV_CRASH) == 0, "invuln ignores bullet")
	s = _quiet()
	s.band = 0
	bu = R.EBullet.new()
	bu.pos = Vector2(R.SHIP_X + 300.0, s.ship_y)
	bu.vel = Vector2(-R.BULLET_SPEED, 0.0)
	bu.band = 0
	s.bullets.append(bu)
	var pops := 0
	for i in 60:
		if R.step(s, dt, 25.0, 0.0, rng) & R.EV_POP:
			pops += 1
	_t(pops == 1 and s.bullets.is_empty() and s.invuln == 0.0, "matching shot destroys bullet")
	s = _quiet()
	s.band = 2
	bu = R.EBullet.new()
	bu.pos = Vector2(R.SHIP_X + 300.0, s.ship_y)
	bu.vel = Vector2(-R.BULLET_SPEED, 0.0)
	bu.band = 0
	s.bullets.append(bu)
	pops = 0
	for i in 60:
		if R.step(s, dt, 25.0, 0.0, rng) & R.EV_POP:
			pops += 1
	_t(pops == 0, "wrong-band shot passes through bullet")
	# (h) BULLET_MAX caps live bullets; off-screen bullets are removed
	s = _quiet()
	for i in 9:
		var cap_e := _enemy(s, 900.0 + 8.0 * i, 130.0 + 40.0 * i, i % 3)
		cap_e.shooter = true
	var peak := 0
	var over := false
	for i in 100:
		R.step(s, dt, 25.0, 0.0, rng)
		peak = maxi(peak, s.bullets.size())
		over = over or s.bullets.size() > R.BULLET_MAX
	_t(peak == R.BULLET_MAX and not over, "BULLET_MAX caps live bullets")
	s = _quiet()
	for pos in [Vector2(600.0, -20.0), Vector2(600.0, 760.0), Vector2(R.ESCAPE_X - 10.0, 300.0), Vector2(R.SPAWN_X + 30.0, 300.0)]:
		var off := R.EBullet.new()
		off.pos = pos
		off.vel = Vector2.ZERO
		s.bullets.append(off)
	var live := R.EBullet.new()
	live.pos = Vector2(700.0, 120.0)
	live.vel = Vector2(-R.BULLET_SPEED, 0.0)
	s.bullets.append(live)
	R.step(s, dt, 25.0, 0.0, rng)
	_t(s.bullets.size() == 1 and s.bullets[0] == live, "off-screen bullets are removed")
	# sims
	for sd in range(1, 11):
		for d in 2:
			var o := Bot.sim_round(sd, d)
			_t(o.won and o.crashes <= 2 and o.time > 49.9 and o.time < 50.1 and o.kills >= 30 and o.shifts >= 10, "sim seed %d d%d %s" % [sd, d, str(o)])
		var idle := Bot.sim_round(sd, 0, "idle")
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
	for py in [-50.0, 0.0, 70.0, 102.0, 168.0, 400.0]:
		var pp := R.popup_pos(Vector2(0, py))
		_t(pp.y - R.POPUP_SIZE - R.POPUP_RISE >= R.HUD_BOTTOM, "popup top clear of HUD y=%s" % py)
		_t(pp.x == R.POPUP_MIN_X and R.popup_pos(Vector2(2000, py)).x == R.POPUP_MAX_X, "popup x clamp")
	_t(R.popup_pos(Vector2(500, 400)) == Vector2(500, 400), "popup unclamped passthrough")
	_t(R.popup_alpha(R.DODGE_HOLD, R.DODGE_HOLD, R.DODGE_LIFE) == 1.0 and R.DODGE_HOLD >= 0.6 and R.popup_alpha(R.DODGE_LIFE, R.DODGE_HOLD, R.DODGE_LIFE) == 0.0, "dodge popup holds full alpha >= 0.6 s")
	var dp := R.dodge_pos(400.0, Vector2(280, 420))
	_t(dp.x == 280.0 and dp.y == 370.0 and R.dodge_pos(100.0, Vector2(2000, 100)).x == R.POPUP_MAX_X and R.dodge_pos(100.0, Vector2(0, 100)).y >= R.POPUP_MIN_Y, "dodge_pos near crash, clamped")
	var b := Vector2(500, 300)
	_t(R.stagger_pos(b, 1.0, []) == b, "stagger: alone")
	_t(R.stagger_pos(b, 1.2, [{"pos": b + Vector2(30, 0), "t": 1.0}]).y == b.y + R.STAGGER_DY, "stagger: close kill drops")
	var third := R.stagger_pos(b, 1.2, [{"pos": b, "t": 1.0, "out": b}, {"pos": b + Vector2(0, 20), "t": 1.1, "out": b + Vector2(0, 66)}])
	_t(third.y == b.y + R.STAGGER_MAX_DROP, "stagger: third stacks (capped)")
	_t(R.stagger_pos(b, 1.5, [{"pos": b, "t": 1.0}]) == b, "stagger: too late")
	_t(R.stagger_pos(b, 1.2, [{"pos": b + Vector2(90, 0), "t": 1.0}]) == b, "stagger: too far")
	# earlier popup placed LOWER than this base: gap is measured from it, at least DY after rise too
	var rz := R.stagger_pos(Vector2(500, 300), 1.28, [{"pos": Vector2(500, 370), "t": 1.0, "out": Vector2(500, 370)}])
	_t(rz.y - (370.0 - R.popup_rise(0.28)) >= R.STAGGER_DY and rz.y > 300.0, "stagger: matches earlier popup by its risen position")
	var hi := R.stagger_pos(b, 1.2, [{"pos": b + Vector2(0, 20), "t": 1.0, "out": b + Vector2(0, 20)}])
	_t(hi.y - (b.y + 20.0) >= R.STAGGER_DY, "stagger: gap from earlier spawn >= DY")
	_t(hi.y - (b.y + 20.0 - R.popup_rise(0.2)) >= R.STAGGER_DY, "stagger: gap from earlier risen pos >= DY")
	_t(R.popup_rise(0.0) == 0.0 and R.popup_rise(R.POPUP_LIFE) == R.POPUP_RISE and R.popup_rise(0.2) > 0.0, "popup_rise curve")
	# top clamp: stagger stays within 2 levels and above the pad area, popup top still clear of the HUD
	var tp := R.popup_pos(Vector2(500, 0))
	var chain: Array = []
	var last := tp
	for i in 5:
		last = R.stagger_pos(tp, 1.0 + 0.01 * i, chain)
		chain.append({"pos": tp, "t": 1.0 + 0.01 * i, "out": last})
		_t(last.y <= tp.y + R.STAGGER_MAX_DROP and last.y < R.BRAKE_RECT.position.y and last.y - R.POPUP_SIZE - R.POPUP_RISE >= R.HUD_BOTTOM, "stagger bound at top clamp i=%d" % i)
	var low := R.stagger_pos(Vector2(500, 580), 1.1, [{"pos": Vector2(500, 580), "t": 1.0, "out": Vector2(500, 580)}])
	_t(low.y <= R.STAGGER_MAX_Y, "stagger stops above the pads")
	_t(R.STAGGER_DY >= R.POPUP_SIZE, "stagger clears label height")
	# popup constants must be the ones game.gd draws with and the ones Juice.popup rises by
	var src := FileAccess.get_file_as_string("res://games/redshift/game.gd")
	var jsrc := FileAccess.get_file_as_string("res://shared/juice.gd")
	_t(src.contains("R.POPUP_SIZE") and src.contains("R.POPUP_RISE") and src.contains("R.POPUP_FADE_DELAY"), "game.gd popup uses R constants")
	_t(src.contains("R.popup_alpha(age, hold, life)") and not src.contains('"modulate:a"') and src.contains("R.DODGE_HOLD, R.DODGE_LIFE"), "live popup fade is driven by Rules.popup_alpha with DODGE_HOLD/DODGE_LIFE")
	_t(not src.contains("Juice.popup("), "game.gd has no second popup path")
	_t(jsrc.contains("position.y - %d.0" % int(R.POPUP_RISE)), "POPUP_RISE matches Juice.popup rise")
	_t(R.POPUP_FADE_DELAY > 0.25 and R.POPUP_FADE_DELAY < R.POPUP_LIFE, "popup fades later than Juice default")
	for f in fails:
		printerr("SELFTEST FAIL: " + f)
	if fails.is_empty():
		print("SELFTEST OK")
	quit(1 if not fails.is_empty() else 0)
