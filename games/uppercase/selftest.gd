extends SceneTree
## Run: godot --headless --path . --script res://games/uppercase/selftest.gd

const R := preload("res://games/uppercase/rules.gd")


func _init() -> void:
	var f: Array[String] = []
	if R.correct_shift("Q") != R.RIGHT or R.correct_shift("G") != R.RIGHT or R.correct_shift("B") != R.RIGHT:
		f.append("left-hand letters want Right Shift")
	if R.correct_shift("H") != R.LEFT or R.correct_shift("N") != R.LEFT or R.correct_shift("P") != R.LEFT:
		f.append("right-hand letters want Left Shift")
	for i in 26:
		var x: float = R.key_center(char(65 + i)).x
		if x < 240.0 or x > 1040.0:
			f.append("key x in range " + char(65 + i))
	if R.side_for_tap_x(639.0) != R.LEFT or R.side_for_tap_x(640.0) != R.RIGHT:
		f.append("tap split at 640")
	if R.letter_y(0.0, 4.0) != R.SPAWN_Y or R.letter_y(3.0, 3.0) != R.LINE_Y:
		f.append("letter_y")
	if R.judge(0.0) != R.PERFECT or R.judge(16.0) != R.PERFECT or R.judge(-30.0) != R.GOOD or R.judge(45.0) != R.NONE:
		f.append("judge")
	if R.is_missed(R.LINE_Y + 44.0) or not R.is_missed(R.LINE_Y + 45.0):
		f.append("is_missed")
	for r in [25.0, 45.0]:
		if (R.LINE_Y - R.SPAWN_Y) / R.travel_beats(r) * R.spawn_every(r) <= 2.0 * R.GOOD_PX:
			f.append("one tile in window at r=%s" % r)
	if R.ramp_time(0.0, 1) != 30.0 or R.ramp_time(12.0, 0) != 12.0:
		f.append("ramp_time")
	if R.travel_beats(0.0) != 4.0 or R.travel_beats(15.0) != 3.0 or R.travel_beats(45.0) != 2.0:
		f.append("travel_beats")
	if R.spawn_every(5.0) != 2 or R.spawn_every(25.0) != 1:
		f.append("spawn_every")
	if R.lower_chance(19.9) != 0.0 or R.lower_chance(1000.0) != 0.35:
		f.append("lower_chance")
	if not R.hints_on(29.9) or R.hints_on(30.0):
		f.append("hints_on")
	if not R.is_grace(9.9) or R.is_grace(10.0):
		f.append("is_grace")
	if R.hit_points(R.PERFECT, 0) != 30 or R.hit_points(R.GOOD, 100) != 35:
		f.append("hit_points")
	if R.shift_pitch(100) != 1.5 or R.final_score(1000, 2) != 1100:
		f.append("pitch/final")
	for m in f:
		printerr("SELFTEST FAIL: " + m)
	if f.is_empty():
		print("SELFTEST OK")
	quit(1 if not f.is_empty() else 0)
