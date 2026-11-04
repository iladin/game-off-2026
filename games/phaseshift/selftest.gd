extends SceneTree
## Run: godot --headless --path . --script res://games/phaseshift/selftest.gd

const R := preload("res://games/phaseshift/rules.gd")
var f: Array[String] = []


func _flat(g: int) -> R.Course:
	var c := R.Course.new()
	c.ground.fill(g)
	return c


func _run(b: R.Body, c: R.Course, frames: int, jump_at: int = -1, phase_at: Array = []) -> Array:
	# returns events per frame; x barely moves so the cell stays put (cell 10)
	var out: Array = []
	var x := 800.0
	for i in frames:
		out.append(R.step(b, c, x, x, 1.0 / 60.0, i == jump_at, phase_at.has(i)))
	return out


func _init() -> void:
	_ramp()
	_courses()
	_physics()
	_steps()
	_bot()
	_misc()
	for m in f:
		printerr("SELFTEST FAIL: " + m)
	if f.is_empty():
		print("SELFTEST OK")
	quit(1 if not f.is_empty() else 0)


func _ramp() -> void:
	if R.ramp_time(0.0, 1) != 30.0 or R.speed(0.0) != 280.0 or R.speed(10.0) != 320.0 \
			or R.speed(40.0) != 440.0 or R.speed(1000.0) != 440.0:
		f.append("ramp/speed")
	if absf(R.dist_at(40.0, 0) - 14400.0) > 0.01:
		f.append("dist_at(40) != goal")
	if R.zone_at(36, 0) != 0 or R.zone_at(37, 0) != 1 or R.zone_at(80, 0) != 2 \
			or R.zone_at(127, 0) != 3 or R.zone_at(0, 1) != 3:
		f.append("zone_at")
	if R.phase_name(5.0) != "" or R.phase_name(15.0) != "JUMP" or R.phase_name(25.0) != "WALLS" \
			or R.phase_name(35.0) != "TOP SPEED":
		f.append("phase_name")
	if not R.is_grace(9.9) or R.is_grace(10.0) or not R.hints_on(29.9) or R.hints_on(30.0):
		f.append("grace/hints")


func _courses() -> void:
	for d in 2:
		for s in range(1, 31):
			var rng := RandomNumberGenerator.new()
			rng.seed = s
			var c := R.build_course(rng, d)
			var holes := 0
			var walls := 0
			var cross := 0
			for i in R.TOTAL_CELLS:
				var g := int(c.ground[i])
				if i < R.START_CELLS or i >= R.GOAL_CELLS + 16:
					if g != 3:
						f.append("start/end cell not both %d" % i)
				if i > 0 and ((g == 1 and c.ground[i - 1] == 2) or (g == 2 and c.ground[i - 1] == 1)):
					f.append("1 next to 2 at %d (seed %d)" % [i, s])
				if c.wall[i] != 0:
					walls += 1
					if g != 3 or c.ground[i - 1] != 3 or c.ground[i + 1] != 3:
						f.append("wall neighbours")
				if d == 0 and i < 37 and (g == 0 or c.wall[i] != 0):
					f.append("hole/wall before cell 37")
				if c.orb[i] != 0 and c.orb[i] != g:
					f.append("orb not on own world cell")
				if g == 0:
					holes += 1
					if i > 0 and c.ground[i - 1] == 0:
						continue
					var n := 0
					while c.ground[i + n] == 0:
						n += 1
					if n > 2 or c.ground[i - 1] == 0 or c.ground[i + n] == 0 or c.ground[i - 2] == 0 or c.ground[i + n + 1] == 0:
						f.append("hole shape at %d" % i)
					if c.ground[i - 1] + c.ground[i + n] == 3 and c.ground[i - 1] != 3:
						cross += 1
			var levels := {}
			var apex := R.JUMP_V * R.JUMP_V / (2.0 * R.GRAVITY)
			for i in range(1, R.TOTAL_CELLS):
				levels[int(c.height[i])] = true
				var up := float(int(c.height[i]) - int(c.height[i - 1])) * R.HEIGHT_STEP
				if up > 160.0 or up > apex:
					f.append("step-up too high at %d (seed %d)" % [i, s])
				if up != 0.0 and (c.ground[i] == 0 or c.ground[i - 1] == 0):
					f.append("step beside a hole at %d" % i)
			for st in range(20, R.GOAL_CELLS - 16):
				var lo := 9
				var hi := -1
				for k in range(st, st + 16):
					lo = mini(lo, int(c.height[k]))
					hi = maxi(hi, int(c.height[k]))
				if lo == hi:
					f.append("flat 16-cell window at %d (seed %d d %d)" % [st, s, d])
					break
			if levels.size() < 2:
				f.append("course has one height (seed %d d %d)" % [s, d])
			var first := 0
			while first < R.TOTAL_CELLS and c.ground[first] == 3 and c.wall[first] == 0 and c.height[first] == 0:
				first += 1
			if d == 0 and float(first) * R.CELL < R.dist_at(3.0, 0):
				f.append("first obstacle before 3 s (seed %d)" % s)
			if d == 0 and (holes < 1 or walls < 1):
				f.append("d0 course lacks hole or wall")
			if d == 1 and cross < 1:
				f.append("d1 course lacks cross gap (seed %d)" % s)
	if f.size() > 10:
		f.resize(10)


func _physics() -> void:
	var c := _flat(3)
	var b := R.Body.new()
	var evs := _run(b, c, 120, 0)
	var land := -1
	for i in evs.size():
		if evs[i] & R.EV_LAND:
			land = i
	if not (evs[0] & R.EV_JUMP) or land < 40 or land > 43:
		f.append("jump/land timing %d" % land)
	# (b) wrong world floor
	c = _flat(1)
	b = R.Body.new()
	b.world = 2
	evs = _run(b, c, 40)
	var fall := -1
	for i in evs.size():
		if evs[i] & R.EV_FALL:
			fall = i
			break
	if fall < 6 or fall > 30:
		f.append("fall timing %d" % fall)
	# (c) phase in time
	b = R.Body.new()
	b.world = 2
	evs = _run(b, c, 60, -1, [3])
	for e in evs:
		if e & R.EV_FALL:
			f.append("phase in coyote should save")
			break
	# (d) walls
	c = _flat(3)
	c.wall[2] = 1
	b = R.Body.new()
	var crash := false
	var passes := 0
	for i in range(0, 400):
		var e := R.step(b, c, i * 1.0, i * 1.0 + 1.0, 1.0 / 60.0, false, false)
		if e & R.EV_CRASH:
			crash = true
	if not crash:
		f.append("wall crash")
	b = R.Body.new()
	b.world = 2
	crash = false
	for i in range(0, 400):
		var e := R.step(b, c, i * 1.0, i * 1.0 + 1.0, 1.0 / 60.0, false, false)
		if e & R.EV_CRASH:
			crash = true
		if e & R.EV_WALL:
			passes += 1
	if crash or passes != 1:
		f.append("wall pass %d" % passes)
	# (e) cooldown
	b = R.Body.new()
	evs = _run(b, _flat(3), 20, -1, [2, 8])
	var n := 0
	for e in evs:
		if e & R.EV_PHASE:
			n += 1
	if n != 1:
		f.append("phase cooldown")
	# (f) fit/rescue
	c = _flat(3)
	c.ground[10] = 2
	c.wall[11] = 2
	if R.fit_world(c, 10, 1) != 2 or R.fit_world(c, 11, 2) != 1 or R.fit_world(c, 12, 2) != 2:
		f.append("fit_world")
	b = R.Body.new()
	b.y = 700.0
	b.grounded = false
	R.rescue(b, c, 10.0 * R.CELL - R.INVULN * 300.0, 300.0)
	if b.world != 2 or b.y != R.GROUND_Y or not b.grounded or b.invuln != R.INVULN:
		f.append("rescue")


func _steps() -> void:
	var c := _flat(3)
	for i in range(11, R.TOTAL_CELLS):
		c.height[i] = 1
	var b := R.Body.new()
	var bumped := false
	for i in 5:
		bumped = bumped or (R.step(b, c, 870.0 + i * 3.0, 873.0 + i * 3.0, 1.0 / 60.0, false, false) & R.EV_BUMP) != 0
	if not bumped:
		f.append("walking into a step-up must bump")
	b = R.Body.new()
	var landed := false
	var x := 790.0
	for i in 70:
		var xn := x + 5.0
		var ev := R.step(b, c, x, xn, 1.0 / 60.0, i == 0 or i == 1, false)
		x = xn
		if ev & R.EV_BUMP:
			f.append("jump at the edge should clear a step")
		landed = landed or (ev & R.EV_LAND) != 0
	if not landed or b.y != R.GROUND_Y - R.HEIGHT_STEP:
		f.append("did not land on the raised floor: %f" % b.y)


func _bot() -> void:
	for s in range(1, 21):
		var r := R.sim_bot_round(s, 0)
		if r.fails != 0 or not r.won or r.time < 39.7 or r.time > 40.3 or r.phases < 15 or r.orbs < 20:
			f.append("bot d0 seed %d: %s" % [s, str(r)])
			break
		var r1 := R.sim_bot_round(s, 1)
		if r1.fails != 0 or not r1.won or r1.time < 32.9 or r1.time > 33.5:
			f.append("bot d1 seed %d: %s" % [s, str(r1)])
			break


func _misc() -> void:
	if R.orb_points(0) != 20 or R.orb_points(100) != 40 or R.shift_pitch(100) != 1.5 or R.final_score(1000, 2) != 1300:
		f.append("scoring")
	var n := R.loop_notes(2)
	if n[0] != 50 or n[1] != 0 or R.loop_notes(1)[0] != 45:
		f.append("loop_notes")
	if R.touch_zone(Vector2(639, 300)) != R.PHASE or R.touch_zone(Vector2(640, 300)) != R.JUMP:
		f.append("touch_zone")
	var c := _flat(3)
	c.ground[12] = 0
	c.ground[13] = 0
	if R.next_hole(c, 800.0) != Vector2i(12, 2) or R.next_hole(c, 0.0) != Vector2i(-1, 0):
		f.append("next_hole")
