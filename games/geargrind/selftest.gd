extends SceneTree
## Gear Grind rule assertions. Must print SELFTEST OK.

const Rules := preload("res://games/geargrind/rules.gd")


func _init() -> void:
	var fails: Array[String] = []
	var lo := 0.65
	var hi := 0.95
	if Rules.judge(0.60, lo, hi) != Rules.EARLY: fails.append("judge early")
	if Rules.judge(0.70, lo, hi) != Rules.GOOD: fails.append("judge good")
	if Rules.judge(0.80, lo, hi) != Rules.PERFECT: fails.append("judge perfect")
	if Rules.judge(0.96, lo, hi) != Rules.LATE: fails.append("judge late")
	if Rules.judge(1.05, lo, hi) != Rules.LATE: fails.append("judge red is late")
	if Rules.shift_points(Rules.EARLY) != 0 or Rules.shift_points(Rules.GOOD) != 15 \
			or Rules.shift_points(Rules.PERFECT) != 30 or Rules.shift_points(Rules.LATE) != 5:
		fails.append("shift points 0/15/30/5")
	if Rules.shift_pitch(0) != 1.0: fails.append("pitch base")
	if not is_equal_approx(Rules.shift_pitch(5), 1.2): fails.append("pitch streak 5")
	if Rules.shift_pitch(100) != 1.5: fails.append("pitch cap")
	if Rules.ramp_time(0.0, 1) != 30.0: fails.append("ramp difficulty offset")
	if Rules.ramp_time(12.0, 0) != 12.0: fails.append("ramp plain")
	if Rules.gears_for(0.0) != 3 or Rules.gears_for(25.0) != 4 or Rules.gears_for(45.0) != 5:
		fails.append("gears_for")
	if Rules.band_width(1000.0) != Rules.BAND_MIN: fails.append("band min width")
	if Rules.band_offset(0, 29.9) != 0.0 or Rules.band_offset(0, 30.0) != -0.10:
		fails.append("band moves at 30")
	if not Rules.is_grace(9.9) or Rules.is_grace(10.0): fails.append("grace edge")
	if not Rules.blow_on(10.0) or Rules.blow_on(9.9): fails.append("blow edge")
	if Rules.rival_mult(1000.0) != Rules.RIVAL_MIN: fails.append("rival floor")
	var b := Rules.band(0.0, 0)
	if not is_equal_approx(b.x, 0.65) or not is_equal_approx(b.y, 0.95): fails.append("band at r=0")
	if absf(Rules.simulate(4, 0.80, lo, hi) - Rules.PAR_TIME[4]) >= 0.15: fails.append("sim par 4 gears")
	if Rules.simulate(3, 2.0, lo, hi) <= Rules.rival_time(3, 0.0): fails.append("never shifting loses warm-up")
	if Rules.simulate(3, 0.55, lo, hi) >= Rules.rival_time(3, 0.0): fails.append("all-early wins warm-up")
	if Rules.simulate(4, 0.88, lo, hi) >= Rules.rival_time(4, 30.0): fails.append("all-good wins at r=30")
	var rt := Rules.rival_time(4, 20.0)
	if Rules.rival_dist(rt, rt) != Rules.TRACK: fails.append("rival reaches TRACK at T")
	if Rules.final_score(100, 2) != 200: fails.append("final score")
	if Rules.popup_slot(-1, 0.0) != 0 or Rules.popup_slot(2, 5.0) != 0 or Rules.popup_slot(1, -1.0) != 0: fails.append("popup slot reset")
	if Rules.popup_slot(0, 0.3) != 1 or Rules.popup_slot(1, 0.9) != 2 or Rules.popup_slot(2, 0.5) != 0: fails.append("popup slot chain")
	if Rules.popup_slot_y(520.0, 0) != 520.0 or Rules.popup_slot_y(520.0, 2) != 600.0: fails.append("popup slot y")
	for slot in [0, 1]:  # successive popups stay a full STEP apart as both keep rising
		for age in [0.0, 0.1, 0.37, 0.6, 0.9]:
			var ny := Rules.popup_slot_y(520.0, Rules.popup_slot(slot, age))
			var py := Rules.popup_slot_y(520.0, slot)
			for dt in [0.0, 0.1, 0.3, 0.6]:
				if Rules.popup_y_now(ny, dt) - Rules.popup_y_now(py, age + dt) < Rules.POP_STEP - 0.01: fails.append("popup gap %s %s %s" % [slot, age, dt])
	for f in fails:
		printerr("SELFTEST FAIL: " + f)
	if fails.is_empty():
		print("SELFTEST OK")
	quit(1 if not fails.is_empty() else 0)
