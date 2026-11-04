extends SceneTree
## Cargo Shift logic assertions. Must print SELFTEST OK.

const R := preload("res://games/cargoshift/rules.gd")


func _near(a: float, b: float, e: float = 1e-4) -> bool:
	return absf(a - b) <= e


func _run(s: R.Ship, frames: int, dir: int, torque: float) -> int:
	var ev := 0
	for _i in frames:
		ev |= R.step(s, 1.0 / 60.0, dir, torque)
	return ev


func _init() -> void:
	var f: Array[String] = []
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	if R.ramp_time(0.0, 1) != 30.0 or R.ramp_time(5.0, 0) != 5.0:
		f.append("ramp_time offset")
	if not _near(R.swell_amp(0.0), 0.05) or not _near(R.swell_amp(100.0), 0.35):
		f.append("swell_amp")
	if not _near(R.wave_gap(10.0), 6.0) or not _near(R.wave_gap(30.0), 4.0) or not _near(R.wave_gap(100.0), 3.0):
		f.append("wave_gap")
	var p10 := R.wave_peak(10.0, rng)
	var p100 := R.wave_peak(100.0, rng)
	if p10 < 0.595 or p10 > 0.70 or p100 < 0.85 or p100 > 1.0:
		f.append("wave_peak range")
	if R.phase_name(5.0) != "" or R.phase_name(15.0) != "WAVES" or R.phase_name(25.0) != "CARGO" or R.phase_name(35.0) != "STORM":
		f.append("phase_name")
	if not R.is_grace(9.9) or R.is_grace(10.0) or not R.hints_on(29.9) or R.hints_on(30.0):
		f.append("grace/hints")
	var w := R.Wave.new()
	w.t_hit = 1.0
	w.side = -1
	w.peak = 0.8
	if not _near(R.wave_torque([w], 1.5), 0.8) or R.wave_torque([w], 0.9) != 0.0 or R.wave_torque([w], 2.1) != 0.0:
		f.append("wave_torque")
	# physics
	var s := R.Ship.new()
	_run(s, 600, 0, 0.0)
	if s.tilt != 0.0 or not _near(s.cargo[0], -0.35) or not _near(s.cargo[1], 0.35):
		f.append("calm ship stays level")
	s = R.Ship.new()
	var ev := 0
	for _i in 600:
		ev |= R.step(s, 1.0 / 60.0, 0, 1.0)
	if not (s.cargo[0] + s.cargo[1] > 0.0) or not (ev & R.EV_CAPSIZE):
		f.append("unanswered torque capsizes")
	s = R.Ship.new()
	ev = 0
	for _i in 600:
		ev |= R.step(s, 1.0 / 60.0, -1, 1.0)
	if (ev & R.EV_CAPSIZE) or absf(s.tilt) > 0.3:
		f.append("ballast cancels torque")
	s = R.Ship.new()
	var evs: Array[int] = []
	for d in [1, 1, -1]:
		evs.append(R.step(s, 1.0 / 60.0, d, 0.0))
	if not (evs[0] & R.EV_SHIFT) or (evs[1] & R.EV_SHIFT) or not (evs[2] & R.EV_SHIFT):
		f.append("EV_SHIFT on start and reverse only")
	s = R.Ship.new()
	var stops := 0
	var stop_frame := 0
	for i in 100:
		if R.step(s, 1.0 / 60.0, 1, 0.0) & R.EV_STOP:
			stops += 1
			stop_frame = i + 1
	if stops != 1 or stop_frame < 48 or stop_frame > 49:
		f.append("EV_STOP once at frame 48/49 (got %d at %d)" % [stops, stop_frame])
	s = R.Ship.new()
	s.cargo = PackedFloat32Array([1.0, 1.0, 1.0])
	s.ballast = -1.0
	for _i in 1200:
		s.cargo = PackedFloat32Array([1.0, 1.0, 1.0])
		R.step(s, 1.0 / 60.0, 0, 0.0)
	if not _near(s.tilt, 0.125, 0.01):
		f.append("recoverability tilt %f" % s.tilt)
	s = R.Ship.new()
	s.tilt = 0.4
	s.ballast = 0.5
	R.rescue(s)
	if s.tilt != 0.0 or s.roll_v != 0.0 or s.ballast != 0.0 or s.invuln != R.INVULN or s.cargo != s.home:
		f.append("rescue")
	ev = 0
	s.tilt = 0.6
	ev = R.step(s, 1.0 / 60.0, 0, 0.0)
	if ev & R.EV_CAPSIZE:
		f.append("no capsize while invuln")
	# bot
	for sd in range(1, 21):
		var a := R.sim_round(sd, 0)
		if a["capsizes"] != 0 or not a["won"] or a["time"] < 44.9 or a["time"] > 45.1 or a["max_tilt"] >= 0.3 \
				or a["waves"] != 9 or a["shifts"] < 20 or a["score"] < 1000 or a["score"] > 2100:
			f.append("bot d0 seed %d: %s" % [sd, str(a)])
		var b := R.sim_round(sd, 1)
		if b["capsizes"] != 0 or not b["won"] or b["max_tilt"] >= 0.35 or b["waves"] != 15:
			f.append("bot d1 seed %d: %s" % [sd, str(b)])
		var t6: Array = []
		var c := R.sim_round(sd, 0, true, t6)
		if t6.is_empty() or absf(t6[0]) < deg_to_rad(8.0) or absf(t6[0]) >= R.CAPSIZE - 0.1 or c["first_capsize"] < R.GRACE_END:
			f.append("idle list at 6 s (>= 8 deg, no capsize in first 10 s) seed %d: %s %s" % [sd, str(t6), str(c)])
		if c["capsizes"] < 1 or c["first_capsize"] < 10.0:
			f.append("idle seed %d: %s" % [sd, str(c)])
	var gp := (72.0 + R.CRATE_GAP_PX) / 264.0
	for cs in [[-0.35, 0.35, 0.6], [1.0, 1.0, 1.0], [-1.0, -1.0, 0.0], [0.5, 0.5], [0.9, 1.0, 0.95]]:
		var sp := R.spread_cargo(cs, gp)
		var sorted := sp.duplicate()
		sorted.sort()
		for k in range(1, sorted.size()):
			if sorted[k] - sorted[k - 1] < gp - 0.0001:
				f.append("crate gap %s -> %s" % [str(cs), str(sp)])
	# rogue swell
	var rr := RandomNumberGenerator.new()
	rr.seed = 11
	if R.rogue_next_telegraph(-1.0, rr) + R.ROGUE_WARN < 10.0:
		f.append("rogue none before 10 s")
	for _i in 200:
		var iv := R.rogue_interval(rr)
		var px := R.rogue_shove_px(rr)
		if iv < 8.0 or iv > 12.0 or px < 60.0 or px > 120.0:
			f.append("rogue interval/shove %f %f" % [iv, px])
		var nt := R.rogue_next_telegraph(20.0, rr)
		if nt + R.ROGUE_WARN - 20.0 < 8.0 or nt + R.ROGUE_WARN - 20.0 > 12.0:
			f.append("rogue next telegraph gap")
	for sd in [1, -1]:
		for base in [[-0.35, 0.35], [1.0, 1.0], [-1.0, -1.0], [0.6, 0.35, -0.35]]:
			var rs := R.Ship.new()
			rs.cargo = PackedFloat32Array(base)
			rs.home = PackedFloat32Array(base)
			var pxs := 120.0
			var side := R.rogue_side(rs.cargo, sd, pxs)
			var lead0 := -2.0
			for c in rs.cargo:
				lead0 = maxf(lead0, float(side) * c)
			if 1.0 - lead0 < pxs / 264.0 - 1e-4:
				f.append("rogue side lacks room %s" % str(base))
	for sd in [1, -1]:
		var rs2 := R.Ship.new()
		var rmax := 0.0
		R.rogue_apply(rs2, sd, 100.0)
		if absf(rs2.cargo[0] - rs2.home[0]) * 264.0 < 99.0:
			f.append("rogue shove px")
		for _i in 90:
			var tgt := R.bot_dir(rs2, [], 0.0)
			R.step(rs2, 1.0 / 60.0, tgt, 0.0)
			rmax = maxf(rmax, absf(rs2.tilt))
		if rmax < deg_to_rad(6.0) or rmax >= R.CAPSIZE - 0.1:
			f.append("rogue kick tilt %f deg" % rad_to_deg(rmax))
	var rd := R.Ship.new()
	rd.cargo = PackedFloat32Array([0.0, 0.7])
	for _i in 600:
		R.rogue_drift(rd, 1.0 / 60.0)
	if not _near(rd.cargo[0], -0.35) or not _near(rd.cargo[1], 0.35):
		f.append("rogue drift home")
	for sd in range(1, 21):
		var ra := R.sim_round(sd, 0)
		if ra["rogues"] < 3 or ra["rogues"] > 4:
			f.append("rogue count seed %d: %s" % [sd, str(ra)])
	# scoring and input
	if R.steady_points(0) != 10 or R.steady_points(50) != 30 or R.shift_pitch(100) != 1.5 or R.final_score(1000, 2) != 1300:
		f.append("scoring")
	if R.pointer_dir(Vector2(639, 300), false, 0.0) != -1 or R.pointer_dir(Vector2(640, 300), false, 0.0) != 1:
		f.append("pointer halves")
	if R.pointer_dir(Vector2(700, 400), true, 650.0) != 1 or R.pointer_dir(Vector2(655, 400), true, 650.0) != 0:
		f.append("pointer drag")
	if not R.is_grab(Vector2(700, 495), Vector2(640, 495)) or R.is_grab(Vector2(800, 495), Vector2(640, 495)):
		f.append("is_grab")
	# waterline and submerged hull
	for tl in [-0.4, 0.0, 0.4]:
		var lo := 1e9
		var hi := -1e9
		for part in R.waterline_hull(tl):
			for p: Vector2 in part:
				lo = minf(lo, p.y)
				hi = maxf(hi, p.y)
		if lo < R.SEA_Y - 1.5 - 1e-3 or hi > R.SEA_Y + 1.5 + 1e-3 or hi < lo:
			f.append("waterline at tilt %f: %f..%f" % [tl, lo, hi])
		var slo := 1e9
		for part in R.submerged_hull(tl):
			for p: Vector2 in part:
				slo = minf(slo, p.y)
		if slo < R.SEA_Y - 1e-3:
			f.append("submerged above sea at tilt %f" % tl)
	for xx in range(330, 951, 20):
		for tt in [0.0, 1.7, 3.3, 6.1]:
			if absf(R.sea_offset(float(xx), tt)) > 4.0:
				f.append("sea surface under hull off SEA_Y at x %d" % xx)
	for m in f:
		printerr("SELFTEST FAIL: " + m)
	if f.is_empty():
		print("SELFTEST OK")
	quit(1 if not f.is_empty() else 0)
