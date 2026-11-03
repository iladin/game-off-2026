extends MicroGame
## Night Watch: freeze the hallway you watch, flash the creeper you can see.

const R := preload("res://games/nightwatch/rules.gd")
const W := preload("res://games/nightwatch/watch_draw.gd")

const INTRO := 0.6
const BANNER_TIME := 1.2
const LOOP_VOL := 0.10
const LOOP_BPM := 70.0
const LOOP_CALM := [45, 0, 0, 52, 0, 0, 48, 0, 0, 0, 57, 0, 55, 0, 0, 0]
const LOOP_THIN := [45, 0, 0, 0, 0, 0, 0, 0, 44, 0, 0, 0, 0, 0, 0, 0]
const LOOP_RESTART := 0.5

var rng := RandomNumberGenerator.new()
var watch: R.Watch = R.Watch.new()
var font: Font = ThemeDB.fallback_font
var intro: float = 0.0
var intro_blip: bool = false
var t: float = 0.0
var r: float = 0.0
var anim: float = 0.0
var score: int = 0
var streak: int = 0
var lives: int = R.LIVES
var hour: int = 0
var band: int = 0
var heart_t: float = 0.0
var heart2_t: float = -1.0
var think: float = 0.0
var last_phase: String = ""
var banner_text: String = ""
var banner_t: float = 0.0
var chime_t: float = -1.0
var switch_fx_t: float = 0.0
var switch_dir: float = 1.0
var squash_t: float = 0.0
var squash_feed: int = 0
var flash_fx_t: float = 0.0
var flash_fx_d: float = 0.0
var flash_fx_feed: int = 0
var empty_t: float = 0.0
var step_t: Array[float] = [0.0, 0.0, 0.0]
var hour_flash_t: float = 0.0
var breach_tint_t: float = 0.0
var breach_feed: int = 0
var jump_t: float = 0.0
var life_flash_t: float = 0.0
var loop_restart_t: float = 0.0
var lamp_blink_t: float = 0.0
var qa_watch2: bool = "--nwqa" in OS.get_cmdline_user_args()  # QA shots: idle player who looks at CAM 2 at t 8


func begin() -> void:
	rng.randomize()
	watch = R.fresh()
	intro = INTRO
	intro_blip = false
	t = 0.0
	r = R.ramp_time(0.0, difficulty)
	R.step(watch, 0.0, r, rng)  # zero-dt step: wake the opening feeds so the first frame shows their eyes
	score = 0
	streak = 0
	lives = R.LIVES
	hour = 0
	band = 0
	heart_t = 0.0
	heart2_t = -1.0
	think = 0.0
	last_phase = ""
	banner_text = ""
	banner_t = 0.0
	chime_t = -1.0
	switch_fx_t = 0.0
	squash_t = 0.0
	flash_fx_t = 0.0
	empty_t = 0.0
	step_t = [0.0, 0.0, 0.0]
	hour_flash_t = 0.0
	breach_tint_t = 0.0
	jump_t = 0.0
	life_flash_t = 0.0
	loop_restart_t = 0.0
	lamp_blink_t = 0.0
	Synth.stop_loop()
	Synth.sfx("blip")


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
	r = R.ramp_time(t, difficulty)
	if autoplay:
		think -= dt
		if think <= 0.0:
			var act := R.bot_action(watch)
			if act >= 0:
				think = R.BOT_THINK
				if act == R.TAP_FLASH:
					_flash()
				else:
					_switch(act)
	if qa_watch2 and t >= 8.0 and watch.watched != 1:
		_switch(1)
	var ev := R.step(watch, dt, r, rng)
	if _on_events(ev):
		return
	if int(t / R.HOUR_LEN) > hour:
		hour = int(t / R.HOUR_LEN)
		score += R.HOUR_PTS
		hour_flash_t = 0.3
		chime_t = 0.0
		Synth.sfx("blip", 0.5)
		Juice.popup(self, Vector2(1080, 610), "6 AM" if hour >= 6 else "+%d" % R.HOUR_PTS, W.GOOD, 40 if hour >= 6 else 32)
	if t >= R.ROUND_TIME:
		finish(R.final_score(score, lives), true)
		return
	var nb := R.danger_band(R.danger(watch), band)
	if nb != band:
		band = nb
		_apply_loop()
	_heartbeat(dt)
	var ph := R.phase_name(r)
	if ph != last_phase:
		last_phase = ph
		if ph != "":
			banner_text = ph
			banner_t = BANNER_TIME
			Synth.sfx("blip", 1.5)


func _tick_fx(dt: float) -> void:
	switch_fx_t = maxf(0.0, switch_fx_t - dt)
	squash_t = maxf(0.0, squash_t - dt)
	flash_fx_t = maxf(0.0, flash_fx_t - dt)
	empty_t = maxf(0.0, empty_t - dt)
	hour_flash_t = maxf(0.0, hour_flash_t - dt)
	breach_tint_t = maxf(0.0, breach_tint_t - dt)
	jump_t = maxf(0.0, jump_t - dt)
	life_flash_t = maxf(0.0, life_flash_t - dt)
	banner_t = maxf(0.0, banner_t - dt)
	lamp_blink_t = maxf(0.0, lamp_blink_t - dt)
	for i in 3:
		step_t[i] = maxf(0.0, step_t[i] - dt)
	if chime_t >= 0.0:
		chime_t += dt
		if chime_t >= 0.25:
			chime_t = -1.0
			Synth.sfx("blip", 0.5)
	if loop_restart_t > 0.0:
		loop_restart_t -= dt
		if loop_restart_t <= 0.0:
			_apply_loop()


func _apply_loop() -> void:
	if loop_restart_t > 0.0 or intro > 0.0:
		return
	if band == 0:
		Synth.loop(LOOP_CALM, LOOP_BPM, "sine", LOOP_VOL)
	elif band == 1:
		Synth.loop(LOOP_THIN, LOOP_BPM, "sine", LOOP_VOL)
	else:
		Synth.stop_loop()


func _heartbeat(dt: float) -> void:
	if heart2_t >= 0.0:
		heart2_t -= dt
		if heart2_t < 0.0:
			Synth.tone(55.0, 0.12, "sine", 0.35, 42.0)
	if band >= 1:
		heart_t -= dt
		if heart_t <= 0.0:
			heart_t = R.HEART_GAP[band]
			Synth.tone(55.0, 0.12, "sine", 0.35, 42.0)
			heart2_t = 0.18


func _unhandled_input(event: InputEvent) -> void:
	if autoplay or is_finished() or intro > 0.0:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		match event.physical_keycode:
			KEY_1, KEY_KP_1: _switch(0)
			KEY_2, KEY_KP_2: _switch(1)
			KEY_3, KEY_KP_3: _switch(2)
			KEY_LEFT, KEY_A: _switch((watch.watched + 2) % 3)
			KEY_RIGHT, KEY_D: _switch((watch.watched + 1) % 3)
			KEY_SPACE, KEY_ENTER, KEY_KP_ENTER, KEY_UP, KEY_W: _flash()
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var tg := R.tap_target(event.position)
		if tg == R.TAP_FLASH:
			_flash()
		elif tg >= 0:
			_switch(tg)


func _switch(i: int) -> void:
	if is_finished() or intro > 0.0:
		return
	var old := watch.watched
	if R.switch(watch, i) == 0:
		return
	switch_dir = 1.0 if i > old else -1.0
	switch_fx_t = 0.15
	squash_t = 0.12
	squash_feed = i
	Synth.sfx("shift", R.shift_pitch(streak))
	Synth.tone(2400.0, 0.12, "noise", 0.12, 900.0)


func _flash() -> void:
	if is_finished() or intro > 0.0:
		return
	var ev := R.flash(watch, r, rng)
	if ev == 0:
		lamp_blink_t = 0.15
	elif ev == R.EV_EMPTY:
		streak = 0
		empty_t = 0.2
		Synth.sfx("miss", rng.randf_range(0.92, 1.08))
		Juice.shake(4.0)
	elif ev == R.EV_REPEL:
		var pts := R.flash_points(watch.flash_d, streak)
		score += pts
		flash_fx_t = 0.25
		flash_fx_d = watch.flash_d
		flash_fx_feed = watch.flash_i
		Synth.sfx("hit", rng.randf_range(0.92, 1.08))
		Synth.sfx("coin", pow(2.0, mini(streak, 12) / 12.0))
		streak += 1
		var pos := W.creeper_center(R.MAIN_RECT, flash_fx_d)
		Juice.flash(Color(W.INK, 0.15), 0.1)
		Juice.burst(self, pos, W.ACCENT, 14)
		Juice.popup(self, pos - Vector2(0, 30), "+%d" % pts, W.GOOD, 32)


## Returns true when the round ended.
func _on_events(ev: int) -> bool:
	if ev & R.EV_STEP:
		var q := watch.step_q
		step_t[watch.step_i] = 0.1
		Synth.tone(90.0 + 30.0 * q, 0.07, "noise", 0.10 + 0.06 * q, 50.0)
	if not (ev & R.EV_BREACH):
		return false
	var bi := watch.breach_i
	streak = 0
	if R.is_grace(r):
		breach_tint_t = 0.2
		breach_feed = bi
		Synth.sfx("miss", 0.8)
		Juice.shake(4.0)
		Juice.popup(self, R.MAIN_RECT.get_center(), "WATCH", W.DIM, 32)
		return false
	lives -= 1
	life_flash_t = 0.4
	breach_tint_t = 0.2
	breach_feed = bi
	jump_t = 0.3
	Synth.sfx("boom", rng.randf_range(0.95, 1.05))
	Synth.stop_loop()
	loop_restart_t = LOOP_RESTART
	Juice.flash(Color(W.BAD, 0.35), 0.2)
	Juice.shake(14.0)
	Juice.hitstop(0.06)
	Juice.burst(self, R.THUMB_RECTS[bi].get_center(), W.BAD, 14)
	if lives <= 0:
		finish(score, false)
		return true
	return false


func _draw() -> void:
	W.draw_backdrop(self)
	W.draw_thumbs(self, font, self)
	W.draw_lamp(self, font, self)
	W.draw_clock(self, font, self)
	if band == 2:
		draw_rect(Rect2(0, 0, 1280, 720), Color(W.BG, 0.25))
	W.draw_main(self, font, self)
	W.draw_hud(self, font, self)
