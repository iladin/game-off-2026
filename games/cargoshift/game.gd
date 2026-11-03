extends MicroGame
## Cargo Shift: slide the ballast against the list while waves shift the cargo.

const R := preload("res://games/cargoshift/rules.gd")
const D := preload("res://games/cargoshift/cargo_draw.gd")

const INTRO_TIME := 0.6
const SHIFT_FX_TIME := 0.2
const SQUASH_TIME := 0.12
const STOP_FLASH_TIME := 0.08
const THUD_TIME := 0.2
const TICK_FLASH_TIME := 0.15
const FAIL_TINT_TIME := 0.2
const LIFE_FLASH_TIME := 0.4
const BANNER_TIME := 1.2
const SHIFT_SFX_GAP := 0.12
const THUNDER_GAP := 4.0
const LOOP_VOL := 0.10
const LOOP_BPM := 92.0
const LOOP_RESTART_DELAY := 0.5
const LOOP := [45, 52, 57, 52, 48, 55, 60, 55, 45, 52, 57, 52, 43, 50, 55, 50]
const SHAKE_SOFT := 4.0
const SHAKE_MED := 10.0
const SHAKE_HARD := 14.0
const HITSTOP := 0.06

var rng := RandomNumberGenerator.new()
var ship: R.Ship = R.Ship.new()
var waves: Array = []
var intro: float = INTRO_TIME
var intro_blip2: bool = false
var t: float = 0.0
var next_wave_t: float = 0.0
var score: int = 0
var streak: int = 0
var lives: int = R.LIVES
var tick_t: float = 0.0
var tick_max: float = 0.0
var ptr_down: bool = false
var ptr_pos: Vector2 = Vector2.ZERO
var ptr_drag: bool = false
var dir: int = 0
var last_shift_sfx_t: float = -10.0
var shift_fx_t: float = 0.0
var shift_fx_dir: int = 0
var squash_t: float = 0.0
var stop_flash_t: float = 0.0
var thud_t: float = 0.0
var thud_i: int = 0
var tick_flash_t: float = 0.0
var ridden_t: float = 0.0
var thunder_t: float = 0.0
var next_thunder_t: float = 0.0
var crate3_drop_t: float = 0.0
var fail_tint_t: float = 0.0
var life_flash_t: float = 0.0
var banner_text: String = ""
var banner_t: float = 0.0
var last_phase_name: String = ""
var loop_restart_t: float = -1.0
var capsizes_total: int = 0
var list_side: int = 1
var loop_started: bool = false
var font: Font = ThemeDB.fallback_font


func begin() -> void:
	rng.randomize()
	ship = R.Ship.new()
	waves = []
	intro = INTRO_TIME
	intro_blip2 = false
	t = 0.0
	score = 0
	streak = 0
	lives = R.LIVES
	tick_t = 0.0
	tick_max = 0.0
	ptr_down = false
	ptr_drag = false
	dir = 0
	last_shift_sfx_t = -10.0
	shift_fx_t = 0.0
	squash_t = 0.0
	stop_flash_t = 0.0
	thud_t = 0.0
	tick_flash_t = 0.0
	ridden_t = 0.0
	thunder_t = 0.0
	next_thunder_t = 0.0
	crate3_drop_t = 0.0
	fail_tint_t = 0.0
	life_flash_t = 0.0
	banner_text = ""
	banner_t = 0.0
	last_phase_name = ""
	loop_restart_t = -1.0
	capsizes_total = 0
	list_side = rng.randi_range(0, 1) * 2 - 1
	loop_started = false
	next_wave_t = maxf(0.0, R.WAVES_AT - (R.DIFFICULTY_OFFSET if difficulty >= 1 else 0.0))
	if R.ramp_time(0.0, difficulty) >= R.CRATE3_AT:
		R.add_crate(ship, R.CRATE3_X * float(rng.randi_range(0, 1) * 2 - 1))
	Synth.sfx("blip")


func _ballast_pos() -> Vector2:
	return D.PIVOT + Vector2(ship.ballast * D.BALLAST_RANGE, D.BALLAST_Y).rotated(ship.tilt)


func _key_dir() -> int:
	var d := 0
	if Input.is_physical_key_pressed(KEY_LEFT) or Input.is_physical_key_pressed(KEY_A):
		d -= 1
	if Input.is_physical_key_pressed(KEY_RIGHT) or Input.is_physical_key_pressed(KEY_D):
		d += 1
	return d


func _unhandled_input(event: InputEvent) -> void:
	if autoplay or is_finished():
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		ptr_down = event.pressed
		if event.pressed:
			ptr_pos = event.position
			ptr_drag = R.is_grab(ptr_pos, _ballast_pos())
	elif event is InputEventMouseMotion and ptr_down:
		ptr_pos = event.position


func _hint_side() -> int:
	if not R.hints_on(R.ramp_time(t, difficulty)):
		return 0
	for w: R.Wave in waves:
		if t < w.t_hit + R.WAVE_HIT:
			return w.side
	return 0


func _process(delta: float) -> void:
	queue_redraw()
	if is_finished():
		return
	shift_fx_t = maxf(0.0, shift_fx_t - delta)
	squash_t = maxf(0.0, squash_t - delta)
	stop_flash_t = maxf(0.0, stop_flash_t - delta)
	thud_t = maxf(0.0, thud_t - delta)
	tick_flash_t = maxf(0.0, tick_flash_t - delta)
	ridden_t = maxf(0.0, ridden_t - delta)
	thunder_t = maxf(0.0, thunder_t - delta)
	crate3_drop_t = maxf(0.0, crate3_drop_t - delta)
	fail_tint_t = maxf(0.0, fail_tint_t - delta)
	life_flash_t = maxf(0.0, life_flash_t - delta)
	banner_t = maxf(0.0, banner_t - delta)
	if loop_restart_t >= 0.0:
		loop_restart_t -= delta
		if loop_restart_t < 0.0:
			Synth.loop(LOOP, LOOP_BPM, "sine", LOOP_VOL)
	if intro > 0.0:
		intro -= delta
		if not intro_blip2 and intro <= INTRO_TIME - 0.3:
			intro_blip2 = true
			Synth.sfx("blip")
		if intro <= 0.0:
			Synth.loop(LOOP, LOOP_BPM, "sine", LOOP_VOL)
			loop_started = true
			t = 0.0
			_check_banner(R.ramp_time(0.0, difficulty))
		dir = 0
		return
	t += delta
	var r := R.ramp_time(t, difficulty)
	if r >= R.CRATE3_AT and ship.cargo.size() == 2:
		R.add_crate(ship, R.CRATE3_X * float(rng.randi_range(0, 1) * 2 - 1))
		crate3_drop_t = 0.25
	if r >= R.WAVES_AT and t >= next_wave_t:
		var w := R.Wave.new()
		w.t_hit = t + R.WAVE_WARN
		w.side = rng.randi_range(0, 1) * 2 - 1
		w.peak = R.wave_peak(r, rng)
		w.spawn_fail_count = capsizes_total
		waves.append(w)
		next_wave_t = t + R.wave_gap(r)
		Synth.tone(500.0, 1.4, "noise", 0.16, 150.0)
	if autoplay:
		dir = R.bot_dir(ship, waves, t)
	else:
		dir = _key_dir()
		if dir == 0 and ptr_down:
			dir = R.pointer_dir(ptr_pos, ptr_drag, _ballast_pos().x)
	var ev := R.step(ship, delta, dir, R.swell(r, t) + R.wave_torque(waves, t) + R.list_torque(t, list_side, difficulty))
	_on_events(ev, r)
	if is_finished():
		return
	for w: R.Wave in waves:
		if not w.hit_fired and t >= w.t_hit:
			w.hit_fired = true
			Synth.tone(90.0, 0.4, "sine", 0.30, 55.0)
			Juice.shake(SHAKE_MED if w.peak > 0.9 else SHAKE_SOFT)
			var cx := 300.0 if w.side < 0 else 980.0
			Juice.burst(self, Vector2(cx, D.SEA_Y), D.ACCENT, 14)
		if not w.done and t >= w.t_hit + R.WAVE_HIT:
			w.done = true
			if capsizes_total == w.spawn_fail_count:
				score += R.WAVE_PTS
				ridden_t = 0.6
				Synth.sfx("coin", 1.335)
				Juice.popup(self, D.PIVOT + Vector2(0, -110), "RODE IT", D.GOOD, 28)
	waves = waves.filter(func(w: R.Wave) -> bool: return t <= w.t_hit + R.WAVE_HIT + 0.5)
	if r >= R.STORM_AT and t >= next_thunder_t:
		next_thunder_t = t + THUNDER_GAP
		thunder_t = 0.1
		Synth.tone(220.0, 0.9, "noise", 0.22, 40.0)
		Juice.flash(Color(D.INK, 0.15), 0.1)
	tick_max = maxf(tick_max, absf(ship.tilt))
	tick_t += delta
	if tick_t >= R.TICK:
		tick_t -= R.TICK
		if tick_max < R.LEVEL_BAND:
			var pts := R.steady_points(streak)
			score += pts
			Synth.sfx("coin", pow(2.0, mini(streak, 12) / 12.0))
			streak += 1
			tick_flash_t = TICK_FLASH_TIME
			Juice.popup(self, Vector2(640, 250), "+%d" % pts, D.GOOD)
		else:
			streak = 0
		tick_max = 0.0
	if t >= R.ROUND_TIME:
		finish(R.final_score(score, lives), true)
		return
	_check_banner(r)


func _check_banner(r: float) -> void:
	var pn := R.phase_name(r)
	if pn != last_phase_name:
		last_phase_name = pn
		if pn != "":
			banner_text = pn
			banner_t = BANNER_TIME
			Synth.sfx("blip", 1.5)


func _on_events(ev: int, r: float) -> void:
	if ev & R.EV_SHIFT:
		shift_fx_t = SHIFT_FX_TIME
		shift_fx_dir = dir
		squash_t = SQUASH_TIME
		if t - last_shift_sfx_t >= SHIFT_SFX_GAP:
			last_shift_sfx_t = t
			Synth.sfx("shift", R.shift_pitch(streak))
	if ev & R.EV_STOP:
		stop_flash_t = STOP_FLASH_TIME
		Juice.shake(SHAKE_SOFT)
		Synth.tone(160.0, 0.06, "square", 0.18, 120.0)
	if ev & R.EV_THUD:
		thud_t = THUD_TIME
		thud_i = ship.thud_i
		Synth.sfx("miss", rng.randf_range(0.92, 1.08))
		Juice.shake(SHAKE_SOFT)
		var sp := R.spread_cargo(ship.cargo, (D.CRATE_SIZE + R.CRATE_GAP_PX) / D.DECK_RANGE)
		var cp := D.PIVOT + Vector2(sp[thud_i] * D.DECK_RANGE, -56.0).rotated(ship.tilt)
		Juice.burst(self, cp, D.INK, 6, 120.0)
	if ev & R.EV_CAPSIZE:
		_capsize(r)


func _capsize(r: float) -> void:
	capsizes_total += 1
	streak = 0
	fail_tint_t = FAIL_TINT_TIME
	if R.is_grace(r):
		Synth.sfx("miss", rng.randf_range(0.92, 1.08))
		Juice.shake(SHAKE_SOFT)
		Juice.popup(self, D.PIVOT + Vector2(0, -230), "SHIFT", D.DIM)
		R.rescue(ship)
		return
	lives -= 1
	life_flash_t = LIFE_FLASH_TIME
	Synth.sfx("boom", rng.randf_range(0.95, 1.05))
	Synth.stop_loop()
	Juice.flash(Color(D.BAD, 0.35), 0.2)
	Juice.shake(SHAKE_HARD)
	Juice.hitstop(HITSTOP)
	Juice.burst(self, D.PIVOT, D.BAD)
	R.rescue(ship)
	if lives <= 0:
		finish(score, false)
		return
	loop_restart_t = LOOP_RESTART_DELAY


func _draw() -> void:
	D.draw_backdrop(self)
	var hint := _hint_side()
	var fx := {"shift_fx_t": shift_fx_t, "shift_fx_dir": shift_fx_dir, "squash_t": squash_t,
		"stop_flash_t": stop_flash_t, "thud_t": thud_t, "thud_i": thud_i, "fail_tint_t": fail_tint_t,
		"crate3_drop_t": crate3_drop_t, "ridden_t": ridden_t}
	D.draw_sea(self, t)
	D.draw_waves(self, waves, t)
	if ship.invuln <= 0.0 or fmod(ship.invuln, 0.16) >= 0.08:
		D.draw_ship(self, ship, t, hint, fx, false)
	if ship.invuln <= 0.0 or fmod(ship.invuln, 0.16) >= 0.08:
		D.draw_ship(self, ship, t, hint, fx, true)
	if R.ramp_time(t, difficulty) >= R.STORM_AT:
		D.draw_rain(self, t, thunder_t > 0.0)
	D.draw_pads(self, dir, hint)
	var ba := 1.0
	if banner_t < 0.3:
		ba = banner_t / 0.3
	D.draw_hud(self, font, score, lives, life_flash_t, ship.tilt, t / R.ROUND_TIME, banner_text, ba, tick_flash_t)
