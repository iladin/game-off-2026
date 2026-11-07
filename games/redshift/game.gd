extends MicroGame
## Red Shift: change speed to change hue; your auto-fire only hurts enemies of your hue.

const R := preload("res://games/redshift/rules.gd")
const D := preload("res://games/redshift/redshift_draw.gd")
const Bot := preload("res://games/redshift/rules_bot.gd")

const INTRO := 0.6
const BANNER_TIME := 1.2
const LOOP_VOL := 0.10
const LOOP_BPM := 150.0
const LOOP_RESTART := 0.5
const STAR_COUNT := 36
const QA_SEED := 7
const NO_POINTER := -1
const MOUSE_ID := -2  # touch finger indices are 0, 1, ...
const FORM_SIZE := 3  # enemies released per spawn event
const FORM_DX := 60.0  # V wings sit this far behind the leader
const FORM_DY := 70.0  # vertical spacing inside a formation
const FORM_GAP_MUL := 1.6  # a formation of 3 is followed by a longer pause
const FORM_HALF := FORM_DY + 4.0  # keeps the whole formation inside the playfield

var rng := RandomNumberGenerator.new()
var run: R.Run = R.Run.new()
var stars: Array = [PackedVector2Array(), PackedVector2Array(), PackedVector2Array()]
var grid_x: float = 0.0
var intro: float = 0.0
var intro_blip: bool = false
var t: float = 0.0
var r: float = 0.0
var anim: float = 0.0
var score: int = 0
var lives: int = R.LIVES
var think: float = 0.0
var bot_aim_y: float = R.SHIP_Y0
var ptr_down: bool = false
var steer_id: int = NO_POINTER  # the pointer (finger index or MOUSE_ID) that is steering
var ptr_y: float = 0.0
var last_phase: String = ""
var banner_text: String = ""
var banner_t: float = 0.0
var shift_fx_t: float = 0.0
var fx_col: Color = D.BAND_COL[1]
var kill_rings: Array = []
var sparks: Array = []
var hit_flash: Dictionary = {}
var tint_t: float = 0.0
var life_flash_t: float = 0.0
var loop_restart_t: float = 0.0
var pad_t: Array[float] = [0.0, 0.0]
var pad_dead: Array[bool] = [false, false]
var tick_t: float = 0.0
var thud_t: float = 0.0
var band_col_now: Color = D.BAND_COL[1]
var form_band: int = -1
var popup_log: Array = []  # recent popup base positions, for Rules.stagger_pos


func begin() -> void:
	rng.randomize()
	if autoplay:
		rng.seed = QA_SEED  # autoplay is repeatable, so shots show the same heavy every time
	for a in OS.get_cmdline_user_args():  # QA flag: --seed=N overrides
		if a.begins_with("--seed="):
			rng.seed = int(a.substr(7))
	run = R.Run.new()
	for l in 3:
		var arr := PackedVector2Array()
		for i in STAR_COUNT:
			arr.append(Vector2(rng.randf_range(-20.0, 1300.0), rng.randf_range(80.0, 590.0)))
		stars[l] = arr
	grid_x = 0.0
	intro = INTRO
	intro_blip = false
	t = 0.0
	r = R.ramp_time(t + qa_ramp, difficulty)  # qa_ramp: shared --rstart flag, ramp clock only
	anim = 0.0
	score = 0
	lives = R.LIVES
	think = 0.0
	bot_aim_y = R.SHIP_Y0
	ptr_down = false
	steer_id = NO_POINTER
	last_phase = ""
	banner_text = ""
	banner_t = 0.0
	shift_fx_t = 0.0
	kill_rings.clear()
	sparks.clear()
	hit_flash.clear()
	tint_t = 0.0
	life_flash_t = 0.0
	loop_restart_t = 0.0
	pad_t = [0.0, 0.0]
	pad_dead = [false, false]
	tick_t = 0.0
	thud_t = 0.0
	band_col_now = D.BAND_COL[run.band]
	form_band = -1
	popup_log.clear()
	Synth.stop_loop()
	Synth.sfx("blip")


func _popup_pos(p: Vector2) -> Vector2:
	var base := R.popup_pos(p)
	popup_log = popup_log.filter(func(e): return t - float(e.t) <= R.STAGGER_TIME)
	var out := R.stagger_pos(base, t, popup_log)
	popup_log.append({"pos": base, "t": t, "out": out})
	return out


# Same shape as Juice.popup (shared/ is read-only for this game) but holds full alpha longer
# and uses a thicker outline so it reads against the grid. Sizes and rise come from Rules.
func _popup(pos: Vector2, text: String, color: Color, hold: float = R.POPUP_FADE_DELAY, life: float = R.POPUP_LIFE) -> void:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", int(R.POPUP_SIZE))
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1.0))
	label.add_theme_constant_override("outline_size", 10)
	label.position = pos - Vector2(60, R.POPUP_SIZE)
	label.custom_minimum_size = Vector2(120, 0)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.z_index = 50
	add_child(label)
	var t := label.create_tween().set_parallel(true)
	t.tween_property(label, "position:y", label.position.y - R.POPUP_RISE, life).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	# alpha comes from Rules.popup_alpha(age, hold, life): the same numbers the selftest pins
	t.tween_method(func(age: float) -> void: label.modulate.a = R.popup_alpha(age, hold, life), 0.0, life, life)
	t.chain().tween_callback(label.queue_free)


func _process(dt: float) -> void:
	anim += dt
	queue_redraw()
	if is_finished():
		return
	_tick_fx(dt)
	if intro > 0.0:
		intro -= dt
		if not intro_blip and intro <= INTRO - 0.3:
			intro_blip = true
			Synth.sfx("blip")
		if intro <= 0.0:
			_apply_loop()
		return
	t += dt
	r = R.ramp_time(t + qa_ramp, difficulty)
	var move := 0.0
	if autoplay:
		think -= dt
		if think <= 0.0:
			think = R.BOT_THINK
			var d := Bot.bot_think(run)
			if d.shift != 0:
				_shift(d.shift)
			bot_aim_y = d.aim_y
		move = R.follow_dir(bot_aim_y, run.ship_y)
	else:
		move = _key_move()
		if move == 0.0 and ptr_down:
			move = R.follow_dir(ptr_y, run.ship_y)
	var sb := run.streak
	var spawning := run.spawn_t - dt <= 0.0  # Rules.step spawns exactly when this holds
	var before := run.enemies.duplicate()
	var ev := R.step(run, dt, r, move, rng)
	if spawning:
		_form_up(before)
	if _on_events(ev, sb):
		return
	if t >= R.ROUND_TIME:
		finish(R.final_score(score, lives), true)
		return
	var k := run.k
	grid_x = fposmod(grid_x + D.GRID_SPEED * k * dt, 40.0)
	for l in 3:
		var arr: PackedVector2Array = stars[l]
		for i in arr.size():
			var p := arr[i]
			p.x -= D.STAR_SPEED[l] * k * dt
			if p.x < -20.0:
				p.x += 1320.0
			arr[i] = p
		stars[l] = arr
	var ph := R.phase_name(r)
	if ph != last_phase:
		last_phase = ph
		if ph != "":
			banner_text = ph
			banner_t = BANNER_TIME
			Synth.sfx("blip", 1.5)


## Rules.step releases one enemy per spawn event; turn it into a formation of FORM_SIZE
## of one hue: a V (leader in front) or a vertical line, FORM_DY px apart. After RED_AT
## the hue differs from the previous formation. Only the leader can be heavy.
func _form_up(before: Array) -> void:
	run.spawn_t = R.spawn_gap(r) * FORM_GAP_MUL
	var lead: R.Enemy = null
	for e in run.enemies:
		if not before.has(e):
			lead = e
	if lead == null:  # the new enemy was shot the frame it appeared: no formation
		return
	var bands := R.spawn_bands(r)
	if bands.size() > 1 and form_band >= 0:
		bands = bands.filter(func(b): return b != form_band)
	lead.shooter = true
	lead.band = bands[rng.randi() % bands.size()]
	form_band = lead.band
	lead.pos.y = clampf(lead.pos.y, R.ENEMY_Y_MIN + FORM_HALF, R.ENEMY_Y_MAX - FORM_HALF)
	var line := rng.randf() < 0.5
	for i in FORM_SIZE - 1:
		var w := R.Enemy.new()
		var sgn := -1.0 if i == 0 else 1.0
		w.band = lead.band
		w.hp = 1
		w.radius = R.ENEMY_R
		w.pos = Vector2(lead.pos.x if line else lead.pos.x + FORM_DX, lead.pos.y + sgn * FORM_DY)
		run.enemies.append(w)


func _tick_fx(dt: float) -> void:
	shift_fx_t = maxf(0.0, shift_fx_t - dt)
	tint_t = maxf(0.0, tint_t - dt)
	life_flash_t = maxf(0.0, life_flash_t - dt)
	banner_t = maxf(0.0, banner_t - dt)
	tick_t = maxf(0.0, tick_t - dt)
	thud_t = maxf(0.0, thud_t - dt)
	for i in 2:
		pad_t[i] = maxf(0.0, pad_t[i] - dt)
	for e in hit_flash.keys():
		hit_flash[e] -= dt
		if hit_flash[e] <= 0.0:
			hit_flash.erase(e)
	for kr in kill_rings:
		kr.t -= dt
	kill_rings = kill_rings.filter(func(x): return x.t > 0.0)
	for sp in sparks:
		sp.t -= dt
	sparks = sparks.filter(func(x): return x.t > 0.0)
	if loop_restart_t > 0.0:
		loop_restart_t -= dt
		if loop_restart_t <= 0.0:
			_apply_loop()


func _apply_loop() -> void:
	if loop_restart_t > 0.0 or intro > 0.0:
		return
	Synth.loop(R.loop_notes(run.band), LOOP_BPM, "square", LOOP_VOL)


func _key_move() -> float:
	var m := 0.0
	if Input.is_physical_key_pressed(KEY_UP) or Input.is_physical_key_pressed(KEY_W):
		m -= 1.0
	if Input.is_physical_key_pressed(KEY_DOWN) or Input.is_physical_key_pressed(KEY_S):
		m += 1.0
	return m


func _unhandled_input(event: InputEvent) -> void:
	if autoplay or is_finished() or intro > 0.0:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		match event.physical_keycode:
			KEY_LEFT, KEY_A: _shift(-1)
			KEY_RIGHT, KEY_D: _shift(1)
	elif event is InputEventScreenTouch:
		_pointer_button(event.index, event.pressed, event.position)
	elif event is InputEventScreenDrag:
		if event.index == steer_id:
			ptr_y = event.position.y
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.device == InputEvent.DEVICE_ID_EMULATION:
			return  # emulated from a touch: the ScreenTouch already handled it
		_pointer_button(MOUSE_ID, event.pressed, event.position)
	elif event is InputEventMouseMotion and steer_id == MOUSE_ID:
		if event.device != InputEvent.DEVICE_ID_EMULATION:
			ptr_y = event.position.y


## One pointer (touch finger index, or MOUSE_ID) went down or up. Each pointer is
## tracked by its own id: one steers, others can tap the BRAKE / BOOST pads.
func _pointer_button(id: int, pressed: bool, pos: Vector2) -> void:
	if not pressed:
		if id == steer_id:
			steer_id = NO_POINTER
			ptr_down = false
		return
	var tg := R.tap_target(pos)
	if tg == R.TAP_BRAKE:
		_shift(-1)
	elif tg == R.TAP_BOOST:
		_shift(1)
	elif tg == R.TAP_MOVE and steer_id == NO_POINTER:
		steer_id = id
		ptr_down = true
		ptr_y = pos.y


func _shift(dir: int) -> void:
	if is_finished() or intro > 0.0:
		return
	var pi := 0 if dir < 0 else 1
	pad_t[pi] = 0.12
	if R.shift(run, dir) == 0:
		pad_dead[pi] = true
		return
	pad_dead[pi] = false
	shift_fx_t = 0.25
	fx_col = D.BAND_COL[run.band]
	band_col_now = fx_col
	Synth.sfx("shift", R.shift_pitch(run.streak))
	loop_restart_t = 0.0
	_apply_loop()


## Returns true when the round ended.
func _on_events(ev: int, streak_before: int) -> bool:
	var n_sfx := 0
	for e in run.hurt:
		hit_flash[e] = 0.12
	for sp in run.blocked:
		sparks.append({"pos": sp, "t": 0.1})
	for i in run.kills.size():
		var kd: Dictionary = run.kills[i]
		score += kd.pts
		var sbf := run.streak - run.kills.size() + i
		kill_rings.append({"pos": kd.pos, "band": kd.band, "heavy": kd.heavy, "t": 0.2})
		Synth.sfx("hit", rng.randf_range(0.92, 1.08))
		Synth.sfx("coin", pow(2.0, mini(sbf, 12) / 12.0))
		n_sfx += 2
		Juice.burst(self, kd.pos, D.BAND_COL[kd.band], 14)
		_popup(_popup_pos(kd.pos - Vector2(0, 30)), "+%d" % kd.pts, D.GOOD)
		if kd.heavy:
			Juice.flash(Color(D.INK, 0.15), 0.1)
			Juice.shake(10.0)
			Juice.hitstop(0.05)
	if ev & R.EV_DAMAGE and tick_t <= 0.0 and n_sfx < 2:
		tick_t = 0.08
		n_sfx += 1
		Synth.tone(660.0, 0.04, "square", 0.12)
	if ev & R.EV_FIRE and n_sfx < 2:
		n_sfx += 1
		Synth.tone(300.0, 0.08, "square", 0.1, 180.0)
	if ev & R.EV_POP:
		for pp in run.pops:
			Juice.burst(self, pp.pos, D.BAND_COL[pp.band], 6)
		if n_sfx < 2:
			n_sfx += 1
			Synth.tone(880.0, 0.05, "triangle", 0.12, 1320.0)
	if ev & R.EV_BLOCK and thud_t <= 0.0 and n_sfx < 2:
		thud_t = 0.2
		Synth.tone(180.0, 0.03, "noise", 0.08)
	if ev & R.EV_ESCAPE and streak_before >= 3:
		Synth.sfx("miss", 0.9)
	if ev & R.EV_CRASH:
		if R.is_grace(r):
			tint_t = 0.2
			Juice.shake(4.0)
			Synth.sfx("miss", rng.randf_range(0.92, 1.08))
			_popup(_popup_pos(R.dodge_pos(run.ship_y, run.crash_pos)), "DODGE", D.INK, R.DODGE_HOLD, R.DODGE_LIFE)  # INK, not DIM: DIM is too dark on the black outline
		else:
			lives -= 1
			life_flash_t = 0.4
			Juice.flash(Color(D.BAD, 0.35), 0.2)
			Juice.shake(14.0)
			Juice.hitstop(0.06)
			Juice.burst(self, run.crash_pos, D.BAD, 14)
			Synth.sfx("boom", rng.randf_range(0.95, 1.05))
			Synth.stop_loop()
			loop_restart_t = LOOP_RESTART
			if lives <= 0:
				finish(score, false)
				return true
	return false


func _draw() -> void:
	D.draw_space(self, self)
	D.draw_shots(self, self)
	D.draw_bullets(self, self)
	D.draw_enemies(self, self)
	D.draw_ship(self, self)
	D.draw_pads(self, self)
	D.draw_hud(self, self)
