extends SceneTree
## Logic assertions for Shapeshifter. Must print SELFTEST OK.

const Rules := preload("res://games/shapeshifter/rules.gd")


func _init() -> void:
	var fails: Array[String] = []
	for a in 3:
		for b in 3:
			if Rules.passes(a, b) != (a == b):
				fails.append("passes only on equal shapes")
		for roll in 2:
			if Rules.next_shape(a, roll) == a:
				fails.append("next_shape never repeats")
	if Rules.travel_time(0.0) != 3.0:
		fails.append("travel starts at 3.0")
	if Rules.travel_time(1000.0) != Rules.TRAVEL_MIN:
		fails.append("travel clamps")
	if Rules.spawn_gap(1000.0) != Rules.GAP_MIN:
		fails.append("gap clamps")
	if not (Rules.travel_time(60.0) < Rules.travel_time(59.9)):
		fails.append("rush speeds walls up")
	if Rules.ramp_time(0.0, 1) != 30.0 or Rules.ramp_time(12.0, 0) != 12.0:
		fails.append("difficulty offset")
	if not Rules.is_grace(9.9) or Rules.is_grace(10.0):
		fails.append("grace ends at 10")
	if Rules.phase(0.0) != 0 or Rules.phase(25.0) != 2 or Rules.phase(70.0) != 4:
		fails.append("phases")
	if Rules.can_spawn(74.0):
		fails.append("no spawns near the exit")
	if Rules.shift_pitch(0) != 1.0 or not is_equal_approx(Rules.shift_pitch(5), 1.2) or Rules.shift_pitch(100) != 1.5:
		fails.append("shift pitch")
	if Rules.multiplier(4) != 1 or Rules.multiplier(5) != 2 or Rules.multiplier(99) != 4:
		fails.append("multiplier")
	if Rules.shape_radius(Rules.CIRCLE, 1.0, 50.0) != 50.0:
		fails.append("circle radius")
	if not is_equal_approx(Rules.shape_radius(Rules.SQUARE, PI / 4.0, 50.0), 50.0):
		fails.append("square corner")
	if not is_equal_approx(Rules.shape_radius(Rules.SQUARE, 0.0, 50.0), 50.0 * cos(PI / 4.0)):
		fails.append("square side")
	if not is_equal_approx(Rules.shape_radius(Rules.TRIANGLE, -PI / 2.0, 50.0), 50.0):
		fails.append("triangle apex up")
	if Rules.shape_for_tap_x(100.0) != Rules.CIRCLE or Rules.shape_for_tap_x(640.0) != Rules.TRIANGLE or Rules.shape_for_tap_x(1200.0) != Rules.SQUARE:
		fails.append("tap columns")
	if Rules.final_score(100, 2) != 200:
		fails.append("final score")
	for f in fails:
		printerr("SELFTEST FAIL: " + f)
	if fails.is_empty():
		print("SELFTEST OK")
	quit(1 if not fails.is_empty() else 0)
