extends SceneTree
## Run: godot --headless --path . --script res://games/bitcatcher/selftest.gd

const R := preload("res://games/bitcatcher/rules.gd")


func _init() -> void:
	var f: Array[String] = []
	if R.rol8(0b10000001) != 0b00000011 or R.ror8(0b00000011) != 0b10000001:
		f.append("rol/ror wrap")
	for x in 256:
		if R.ror8(R.rol8(x)) != x or R.rotate8(x, 8) != x or R.popcount8(R.rol8(x)) != R.popcount8(x):
			f.append("rotate invariants " + str(x))
			break
	if R.rotate8(0b01000000, -1) != 0b10000000:
		f.append("rotate8 negative is left")
	if R.col_mask(0) != 128 or R.col_mask(7) != 1:
		f.append("col_mask")
	if R.bits_string(0b10110000) != "10110000" or R.bytes_string(3) != "11100000":
		f.append("strings")
	if R.land_one(0, 0b10000000, 0) != R.SET or R.land_one(0b10000000, 0b10000000, 0) != R.WRONG \
			or R.land_one(0, 0b10000000, 1) != R.WRONG:
		f.append("land_one")
	if R.land_zero(0b01000000, 1) != R.LOST or R.land_zero(0b01000000, 0) != R.DODGE:
		f.append("land_zero")
	if R.apply_one(0, 7) != 1 or R.apply_zero(0xFF, 7) != 0xFE:
		f.append("apply")
	if R.best_shift(0, 0b10000000, 0, true) != 0 or R.best_shift(0, 0b01000000, 0, true) != -1 \
			or R.best_shift(0, 0b00000001, 0, true) != 1:
		f.append("best_shift basics")
	var bad := 0
	for t in range(1, 256):
		var n := R.popcount8(t)
		if n > 4:
			continue
		for reg in 256:
			if (reg & t) != reg or reg == t:
				continue
			for c in 8:
				var d := R.best_shift(reg, t, c, true)
				if absi(d) > 4 or R.land_one(R.rotate8(reg, d), R.rotate8(t, d), c) != R.SET:
					bad += 1
	if bad > 0:
		f.append("best_shift exhaustive fails %d" % bad)
	if R.ramp_time(0.0, 1) != 30.0 or R.ramp_time(5.0, 0) != 5.0:
		f.append("ramp_time")
	if R.fall_time(0.0) != 3.0 or R.fall_time(45.0) != 1.5 or R.fall_time(1000.0) != 1.5:
		f.append("fall_time")
	if R.ones_for(5.0) != 2 or R.ones_for(15.0) != 3 or R.ones_for(35.0) != 4:
		f.append("ones_for")
	if R.zero_chance(19.9) != 0.0 or R.zero_chance(1000.0) != 0.30 or R.zero_chance(25.0) != 0.25:
		f.append("zero_chance")
	if not R.hints_on(29.9) or R.hints_on(30.0) or not R.is_grace(9.9) or R.is_grace(10.0):
		f.append("hints/grace")
	if R.phase_name(5.0) != "" or R.phase_name(15.0) != "FASTER" or R.phase_name(45.0) != "TOP SPEED":
		f.append("phase_name")
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var prev := 0b11100000
	for i in 50:
		var tg := R.make_target(3, prev, rng)
		if R.popcount8(tg) != 3 or tg == prev:
			f.append("make_target")
			break
		prev = tg
	if R.hit_points(0, false) != 10 or R.hit_points(100, true) != 35:
		f.append("hit_points")
	if R.shift_pitch(100) != 1.5 or R.final_score(1000, 2) != 1100:
		f.append("pitch/final")
	if R.touch_zone(Vector2(639, 300)) != R.LEFT or R.touch_zone(Vector2(640, 300)) != R.RIGHT \
			or R.touch_zone(Vector2(640, 650)) != R.DROP or R.touch_zone(Vector2(300, 650)) != R.LEFT \
			or R.touch_zone(Vector2(1000, 650)) != R.RIGHT:
		f.append("touch_zone")
	if R.col_x(0) != 248.0 or R.col_x(7) != 1032.0:
		f.append("col_x")
	for m in f:
		printerr("SELFTEST FAIL: " + m)
	if f.is_empty():
		print("SELFTEST OK")
	quit(1 if not f.is_empty() else 0)
