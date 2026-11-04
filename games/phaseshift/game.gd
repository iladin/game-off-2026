extends MicroGame
## Phase Shift: an auto-runner over two overlapping worlds. Phase so the floor under you
## exists and the wall ahead does not; jump the holes that are in neither world.

const R := preload("res://games/phaseshift/rules.gd")
const D := preload("res://games/phaseshift/phase_draw.gd")

const LIVES := 3
const INTRO_TIME := 0.6
const PAD_DOWN_TIME := 0.1
const SQUASH_TIME := 0.12
const PHASE_FX_TIME := 0.2
const FAIL_TINT_TIME := 0.2
const LIFE_FLASH_TIME := 0.4
const WALL_FLASH_TIME := 0.15
const BANNER_TIME := 1.2
const LOOP_VOL := 0.09
const LOOP_BPM := 128.0
const LOOP_RESTART_DELAY := 0.5
const SHAKE_SOFT := 4.0
const SHAKE_HARD := 14.0
const HITSTOP := 0.06
const STRETCH := 1
const SQUASH := 2

var rng := RandomNumberGenerator.new()
var course: R.Course
var body: R.Body
var intro: float = 0.0
var intro_blip2: bool = false
var in_intro: bool = true
var t: float = 0.0
var dist: float = 0.0
var cur_v: float = R.SPEED_START
var last_cell: int = 0
var score: int = 0
var streak: int = 0
var lives: int = LIVES
var air_t: float = 0.0
var jump_req: bool = false
var phase_req: bool = false
var pad_t: Array[float] = [0.0, 0.0]
var squash_t: float = 0.0
var squash_kind: int = 0
var phase_fx_t: float = 0.0
var phase_old_world: int = 1
var wall_flash_c: int = -1
var wall_flash_t: float = 0.0
var fail_tint_t: float = 0.0
var life_flash_t: float = 0.0
var banner_text: String = ""
var banner_t: float = 0.0
var last_phase_name: String = ""
var loop_restart_t: float = 0.0
var hint_c: int = -1
var hint_w: int = 0
var world_blend: float = 1.0
var font: Font = ThemeDB.fallback_font


func begin() -> void:
	rng.randomize()
	course = R.build_course(rng, difficulty)
	body = R.Body.new()
	intro = 0.0; intro_blip2 = false; in_intro = true
	t = 0.0; dist = 0.0; cur_v = R.SPEED_START; last_cell = 0
	score = 0; streak = 0; lives = LIVES; air_t = 0.0
	jump_req = false; phase_req = false
	pad_t = [0.0, 0.0]
	squash_t = 0.0; squash_kind = 0; phase_fx_t = 0.0; phase_old_world = 1
	wall_flash_c = -1; wall_flash_t = 0.0; fail_tint_t = 0.0; life_flash_t = 0.0
	banner_text = ""; banner_t = 0.0; last_phase_name = ""; loop_restart_t = 0.0
	hint_c = -1; hint_w = 0
	world_blend = 1.0 if body.world == 1 else 0.0
	Synth.stop_loop()
	Synth.sfx("blip")


func _start_loop() -> void:
	Synth.loop(R.loop_notes(body.world), LOOP_BPM, "saw", LOOP_VOL)


func _process(delta: float) -> void:
	queue_redraw()
	if is_finished():
		return
	for i in 2:
		pad_t[i] = maxf(0.0, pad_t[i] - delta)
	squash_t = maxf(0.0, squash_t - delta)
	phase_fx_t = maxf(0.0, phase_fx_t - delta)
	world_blend = move_toward(world_blend, 1.0 if body.world == 1 else 0.0, delta / D.ROW_TWEEN)
	wall_flash_t = maxf(0.0, wall_flash_t - delta)
	fail_tint_t = maxf(0.0, fail_tint_t - delta)
	life_flash_t = maxf(0.0, life_flash_t - delta)
	banner_t = maxf(0.0, banner_t - delta)
	if in_intro:
		intro += delta
		if not intro_blip2 and intro >= 0.3:
			intro_blip2 = true
			Synth.sfx("blip")
		if intro >= INTRO_TIME:
			in_intro = false
			t = 0.0
			_start_loop()
		_update_hint(0.0)
		return
	if loop_restart_t > 0.0:
		loop_restart_t -= delta
		if loop_restart_t <= 0.0:
			_start_loop()
	t += delta
	var r := R.ramp_time(t, difficulty)
	cur_v = R.speed(r)
	var x_prev := dist
	dist += cur_v * delta
	var jump := false
	var phase := false
	if autoplay:
		var f := R.bot_input(body, course, dist, cur_v)
		jump = (f & 1) != 0
		phase = (f & 2) != 0
	else:
		jump = jump_req
		phase = phase_req
		jump_req = false
		phase_req = false
	var ev := R.step(body, course, x_prev, dist, delta, jump, phase)
	if body.grounded:
		air_t = 0.0
	else:
		air_t += delta
	_update_hint(r)
	if _on_events(ev, r):
		return
	while last_cell < R.cell_of(dist):
		last_cell += 1
		score += R.CELL_PTS
	if dist >= R.GOAL_DIST:
		finish(R.final_score(score, lives), true)
		return
	var ph := R.phase_name(r)
	if ph != last_phase_name:
		last_phase_name = ph
		if ph != "":
			banner_text = ph
			banner_t = BANNER_TIME
			Synth.sfx("blip", 1.5)


func _update_hint(r: float) -> void:
	hint_c = -1
	hint_w = 0
	if R.hints_on(r):
		var h := R.hint_info(course, dist, body.world)
		hint_c = h.x
		hint_w = h.y


func _unhandled_input(event: InputEvent) -> void:
	if autoplay or is_finished() or in_intro:
		return
	if event is InputEventKey:
		var ke := event as InputEventKey
		if not ke.pressed or ke.echo:
			return
		var k := ke.keycode
		if k == KEY_SPACE or k == KEY_UP or k == KEY_W:
			_press(R.JUMP)
		elif k == KEY_SHIFT or k == KEY_DOWN or k == KEY_S or k == KEY_X:
			_press(R.PHASE)
	elif event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
			_press(R.touch_zone(mb.position))


func _press(zone: int) -> void:
	pad_t[zone] = PAD_DOWN_TIME
	if zone == R.JUMP:
		jump_req = true
	else:
		phase_req = true


func _player_pos() -> Vector2:
	return Vector2(R.PLAYER_X, body.y - 24.0)


func _on_events(ev: int, r: float) -> bool:
	if ev & R.EV_PHASE:
		phase_old_world = 3 - body.world
		phase_fx_t = PHASE_FX_TIME
		Synth.sfx("shift", R.shift_pitch(streak))
		Synth.loop(R.loop_notes(body.world), 128.0, "saw", LOOP_VOL)
		if loop_restart_t > 0.0:
			Synth.stop_loop()
		Juice.flash(Color(D.world_col(body.world), 0.12), 0.1)
	if ev & R.EV_JUMP:
		squash_kind = STRETCH
		squash_t = SQUASH_TIME
		Synth.sfx("jump", randf_range(0.95, 1.05))
	if ev & R.EV_LAND:
		squash_kind = SQUASH
		squash_t = SQUASH_TIME
		Synth.tone(110.0, 0.05, "triangle", 0.20, 80.0)
		Juice.burst(self, Vector2(R.PLAYER_X, body.y), D.INK, 6, 120.0)
	if ev & R.EV_ORB:
		var c := body.orb_cell
		var pts := R.orb_points(streak)
		var opos := Vector2(R.PLAYER_X + c * R.CELL + 40.0 - dist, R.surface_y(course, c) - 40.0)
		Synth.sfx("coin", pow(2.0, mini(streak, 12) / 12.0))
		streak += 1
		score += pts
		course.orb[c] = 0
		Juice.burst(self, opos, D.world_col(body.world))
		Juice.popup(self, opos - Vector2(0, 50), "+%d" % pts, D.GOOD)
	if ev & R.EV_WALL:
		var wc := R.cell_of(dist)
		wall_flash_c = wc
		wall_flash_t = WALL_FLASH_TIME
		streak += 1
		score += R.WALL_PTS
		Synth.tone(880.0, 0.12, "sine", 0.22, 1320.0)
		Juice.shake(SHAKE_SOFT)
		Juice.popup(self, Vector2(R.PLAYER_X + wc * R.CELL + 40.0 - dist, 180.0), "THROUGH", D.GOOD, 28)
	if ev & (R.EV_FALL | R.EV_CRASH | R.EV_BUMP):
		return _fail(ev, r)
	return false


func _fail(ev: int, r: float) -> bool:
	var pp := _player_pos()
	streak = 0
	fail_tint_t = FAIL_TINT_TIME
	if R.is_grace(r):
		var word := "PHASE"
		if ev & R.EV_BUMP:
			word = "JUMP"
		elif ev & R.EV_FALL:
			var c0 := R.cell_of(dist)
			for c in range(c0 - 3, c0 + 1):
				if R.ground_at(course, c) == 0:
					word = "JUMP"
		Synth.sfx("miss", randf_range(0.92, 1.08))
		Juice.shake(SHAKE_SOFT)
		Juice.popup(self, pp - Vector2(0, 60), word, D.DIM)
		R.rescue(body, course, dist, cur_v)
		return false
	lives -= 1
	life_flash_t = LIFE_FLASH_TIME
	Synth.sfx("boom", randf_range(0.95, 1.05))
	Synth.stop_loop()
	loop_restart_t = LOOP_RESTART_DELAY
	Juice.flash(Color(D.BAD, 0.35), 0.2)
	Juice.shake(SHAKE_HARD)
	Juice.hitstop(HITSTOP)
	Juice.burst(self, pp, D.BAD)
	if lives <= 0:
		finish(score, false)
		return true
	R.rescue(body, course, dist, cur_v)
	return false


func _draw() -> void:
	if course == null:
		return
	D.draw_backdrop(self, dist, world_blend)
	D.draw_course(self, course, dist, body.world, hint_c, hint_w, wall_flash_c, wall_flash_t, t)
	var sx := 1.0
	var sy := 1.0
	if squash_t > 0.0:
		var k := squash_t / SQUASH_TIME
		if squash_kind == STRETCH:
			sx = lerpf(1.0, 0.8, k)
			sy = lerpf(1.0, 1.2, k)
		else:
			sx = lerpf(1.0, 1.25, k)
			sy = lerpf(1.0, 0.8, k)
	D.draw_player(self, body.y, body.world, air_t / R.AIR_TIME if not body.grounded else 0.0, sx, sy,
		fail_tint_t, hint_w, body.invuln, phase_fx_t, PHASE_FX_TIME, phase_old_world, t)
	D.draw_pads(self, pad_t, body.world)
	D.draw_hud(self, font, score, lives, LIVES, life_flash_t, dist / R.GOAL_DIST, body.world,
		banner_text, minf(1.0, banner_t / 0.3))
