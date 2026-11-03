extends MicroGame
## Gear Grind: shift up while the tach needle is in the amber band. Win 4 heats.
## Space / Up / W or tap anywhere = shift up.

const Rules := preload("res://games/geargrind/rules.gd")
const SD := preload("res://games/geargrind/strip_draw.gd")

enum { STAGING, RACING, RESULT }
enum { WON, LOST, BLOWN }

const ACCENT := Color("FF9F1C")
const GOOD := Color("FFD34D")
const BAD := Color("FF3B5C")
const INK := Color("E8ECF4")
const DIM := Color("6B7489")
const TRACE := Color("1E2738")

const LIVES := 3
const HEATS_TO_WIN := 4
const INTRO_TIME := 0.6
const STAGE_TIME := 1.6
const LIGHT_TIMES: Array[float] = [0.4, 0.8, 1.2]
const RESULT_TIME := 1.0
const TREE_AT_M := 28.0
const PLAYER_GROUND := 446.0
const RIVAL_GROUND := 300.0
const KNOB_REST := 620.0
const KNOB_KICK := 566.0
const KNOB_TIME := 0.15
const SQUAT := 0.85
const SQUAT_TIME := 0.12
const FAIL_TINT_TIME := 0.2
const BANNER_TIME := 1.2
const GO_TIME := 0.9
const GO_FLASH := 0.12
const ENGINE_TICK := 0.09
const ENGINE_VOL := 0.10
const IDLE_TICK := 0.18
const LOOP_NOTES: Array = [45, 0, 45, 57, 0, 45, 55, 0, 45, 0, 45, 57, 52, 0, 55, 57]
const LOOP_BPM := 140.0
const LOOP_VOL := 0.09
const LOOP_VOL_TOP := 0.11
const TOP_TRANSPOSE := 5
const LOOP_RESTART_DELAY := 0.5
const SHAKE_SOFT := 4.0
const SHAKE_HARD := 14.0
const HITSTOP := 0.06
const BOT_SPREAD := 0.25

var elapsed: float = 0.0
var intro: float = 0.0
var blip2_done: bool = false
var state: int = STAGING
var state_t: float = 0.0
var lights: int = 0
var heat: int = 0
var heat_r: float = 0.0
var gears: int = 3
var rival_T: float = 10.0
var g: int = 0
var v: float = 0.0
var d: float = 0.0
var race_t: float = 0.0
var boost_t: float = 0.0
var bog_t: float = 0.0
var red_t: float = 0.0
var lo: float = 0.65
var hi: float = 0.95
var shown_rpm: float = Rules.IDLE_RPM
var score: int = 0
var streak: int = 0
var perfects: int = 0
var lives: int = LIVES
var wins: int = 0
var knob_t: float = 0.0
var squat_t: float = 0.0
var digit_t: float = 0.0
var fail_tint_t: float = 0.0
var life_flash_t: float = 0.0
var win_pop_t: float = 0.0
var banner_text: String = ""
var banner_color: Color = ACCENT
var banner_t: float = 0.0
var last_phase: String = ""
var engine_t: float = 0.0
var engine_skip: bool = false
var loop_restart_t: float = -1.0
var top_loop: bool = false
var bot_target: float = 0.8
var sloppy: bool = false
var clock: float = 0.0
var go_t: float = 0.0
var shifted_once: bool = false
var dead: bool = false
var pop_slot: int = -1
var pop_at: float = -100.0


## QA only (desktop, never on web): `--sloppy` in the launch args or SHIFT_QA makes the autoplay bot shift late.
func _qa_sloppy() -> bool:
	if OS.has_feature("web"):
		return false
	return "--sloppy" in OS.get_cmdline_user_args() or "--sloppy" in OS.get_environment("SHIFT_QA").split(" ", false)


func begin() -> void:
	sloppy = autoplay and _qa_sloppy()
	elapsed = 0.0
	pop_at = -100.0
	pop_slot = -1
	intro = INTRO_TIME
	blip2_done = false
	state = STAGING
	state_t = 0.0
	lights = 0
	heat = 0
	g = 0
	v = 0.0
	d = 0.0
	race_t = 0.0
	boost_t = 0.0
	bog_t = 0.0
	red_t = 0.0
	shown_rpm = Rules.IDLE_RPM
	score = 0
	streak = 0
	perfects = 0
	lives = LIVES
	wins = 0
	knob_t = 0.0
	squat_t = 0.0
	digit_t = 0.0
	fail_tint_t = 0.0
	life_flash_t = 0.0
	win_pop_t = 0.0
	banner_text = ""
	banner_t = 0.0
	last_phase = Rules.phase_name(Rules.ramp_time(qa_ramp, difficulty))
	engine_t = 0.0
	engine_skip = false
	loop_restart_t = -1.0
	top_loop = false
	clock = 0.0
	go_t = 0.0
	shifted_once = false
	dead = false
	heat_r = Rules.ramp_time(qa_ramp, difficulty)
	gears = Rules.gears_for(heat_r)
	rival_T = Rules.rival_time(gears, heat_r)
	Synth.stop_loop()
	Synth.sfx("blip")


func _start_loop() -> void:
	var notes: Array = []
	for n in LOOP_NOTES:
		notes.append(int(n) + (TOP_TRANSPOSE if top_loop and int(n) > 0 else 0))
	Synth.loop(notes, LOOP_BPM, "saw", LOOP_VOL_TOP if top_loop else LOOP_VOL)


func _start_heat() -> void:
	heat += 1
	heat_r = Rules.ramp_time(elapsed + qa_ramp, difficulty)
	gears = Rules.gears_for(heat_r)
	rival_T = Rules.rival_time(gears, heat_r)
	g = 0
	v = 0.0
	d = 0.0
	race_t = 0.0
	boost_t = 0.0
	bog_t = 0.0
	red_t = 0.0
	dead = false
	streak = 0
	perfects = 0
	lights = 0
	state = STAGING
	state_t = 0.0
	engine_t = 0.0
	var pn := Rules.phase_name(heat_r)
	if pn != "" and pn != last_phase:
		banner_text = pn
		if heat_r >= Rules.GEARS_5_AT and not top_loop:
			top_loop = true
			_start_loop()
	else:
		banner_text = "HEAT %d" % heat
	last_phase = pn
	banner_color = ACCENT
	banner_t = BANNER_TIME
	_engage()


## Roll the band of the gear just engaged (and the bot's target for it).
func _engage() -> void:
	var b := Rules.band(heat_r, randi() % 4)
	lo = b.x
	hi = b.y
	bot_target = (lo + hi) * 0.5 + randf_range(-BOT_SPREAD, BOT_SPREAD) * (hi - lo)


func _process(delta: float) -> void:
	queue_redraw()
	if is_finished():
		return
	clock += delta
	fail_tint_t = maxf(0.0, fail_tint_t - delta)
	life_flash_t = maxf(0.0, life_flash_t - delta)
	knob_t = maxf(0.0, knob_t - delta)
	squat_t = maxf(0.0, squat_t - delta)
	digit_t = maxf(0.0, digit_t - delta)
	win_pop_t = maxf(0.0, win_pop_t - delta)
	banner_t = maxf(0.0, banner_t - delta)
	go_t = maxf(0.0, go_t - delta)
	if loop_restart_t > 0.0:
		loop_restart_t -= delta
		if loop_restart_t <= 0.0:
			_start_loop()
	if intro > 0.0:
		intro -= delta
		if not blip2_done and intro <= INTRO_TIME - 0.3:
			blip2_done = true
			Synth.sfx("blip")
		if intro <= 0.0:
			_start_loop()
			_start_heat()
		return
	elapsed += delta
	state_t += delta
	var target := Rules.IDLE_RPM
	match state:
		STAGING:
			_stage(delta)
		RACING:
			_race(delta)
			target = maxf(Rules.IDLE_RPM, Rules.rpm(v, g))
			if autoplay and state == RACING:
				_bot()
		RESULT:
			target = Rules.IDLE_RPM
			if state_t >= RESULT_TIME:
				_start_heat()
	shown_rpm = lerpf(shown_rpm, target, 1.0 - exp(-30.0 * delta))


func _stage(delta: float) -> void:
	while lights < 3 and state_t >= LIGHT_TIMES[lights]:
		lights += 1
		Synth.sfx("blip")
	engine_t -= delta
	if engine_t <= 0.0:
		engine_t = IDLE_TICK
		Synth.tone(60.0, 0.11, "square", ENGINE_VOL, 62.0)
	if state_t >= STAGE_TIME:
		state = RACING
		state_t = 0.0
		engine_t = 0.0
		go_t = GO_TIME
		Synth.sfx("jump")
		Juice.flash(Color(INK, 0.12), 0.1)


func _race(delta: float) -> void:
	var a := Rules.accel(g, boost_t, bog_t)
	boost_t -= delta
	bog_t -= delta
	v = minf(Rules.CAPS[g], v + a * delta)
	d += v * delta
	race_t += delta
	var r := Rules.rpm(v, g)
	if g < gears - 1 and r >= 1.0:
		red_t += delta
	else:
		red_t = 0.0
	engine_t -= delta
	if engine_t <= 0.0:
		engine_t = ENGINE_TICK
		engine_skip = not engine_skip
		if red_t <= 0.0 or engine_skip:
			var hz := Rules.engine_hz(r)
			Synth.tone(hz, 0.11, "square", ENGINE_VOL, hz * 1.04)
	if red_t >= Rules.BLOW_TIME and Rules.blow_on(heat_r):
		_end_heat(BLOWN)
	elif d >= Rules.TRACK:
		_end_heat(WON)
	elif race_t >= rival_T:
		_end_heat(LOST)


func _bot() -> void:
	if sloppy:
		# QA: heat 1 shifts only after 0.4 s in the red zone (late); later heats never shift and so BLOW.
		if heat <= 1 and g < gears - 1 and red_t >= 0.4:
			_shift()
		return
	if g < gears - 1 and Rules.rpm(v, g) >= bot_target:
		_shift()


func _unhandled_input(event: InputEvent) -> void:
	if autoplay or is_finished() or intro > 0.0:
		return
	var key: bool = event is InputEventKey and event.pressed and not event.echo \
			and (event.keycode == KEY_SPACE or event.keycode == KEY_UP or event.keycode == KEY_W)
	var tap: bool = event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT
	if key or tap:
		_shift()


func _shift() -> void:
	if state != RACING or g >= gears - 1:
		Synth.sfx("blip", 0.9)
		knob_t = KNOB_TIME * 0.4
		return
	var j := Rules.judge(Rules.rpm(v, g), lo, hi)
	g += 1
	shifted_once = true
	red_t = 0.0
	_engage()
	var pts := Rules.shift_points(j)
	score += pts
	Synth.sfx("shift", Rules.shift_pitch(streak))
	knob_t = KNOB_TIME
	squat_t = SQUAT_TIME
	digit_t = 0.2
	var now := elapsed
	pop_slot = Rules.popup_slot(pop_slot, now - pop_at)
	var at := Vector2(640, Rules.popup_slot_y(520.0, pop_slot))
	pop_at = now
	match j:
		Rules.PERFECT:
			Synth.sfx("coin", pow(2.0, mini(perfects, 12) / 12.0))
			boost_t = Rules.BOOST_TIME
			streak += 1
			perfects += 1
			Juice.burst(self, Vector2(300, 418), ACCENT)
			Juice.popup(self, at, "PERFECT +30", GOOD)
			Juice.shake(SHAKE_SOFT)
		Rules.GOOD:
			Synth.sfx("coin", 0.84)
			streak += 1
			perfects = 0
			Juice.popup(self, at, "+15", GOOD)
		Rules.EARLY:
			Synth.sfx("miss", randf_range(0.92, 1.08))
			bog_t = Rules.BOG_TIME
			boost_t = 0.0
			streak = 0
			perfects = 0
			fail_tint_t = FAIL_TINT_TIME
			Juice.shake(SHAKE_SOFT)
			Juice.popup(self, at, "EARLY", BAD)
			Juice.burst(self, Vector2(300, 418), DIM, 8, 120.0)
		_:
			Synth.sfx("miss", randf_range(0.92, 1.08))
			streak = 0
			perfects = 0
			Juice.popup(self, at, "LATE +5", DIM)


func _end_heat(result: int) -> void:
	state = RESULT
	state_t = 0.0
	banner_t = BANNER_TIME
	if result == WON:
		wins += 1
		win_pop_t = 0.2
		var pts := Rules.HEAT_POINTS + Rules.heat_bonus(rival_T - race_t)
		score += pts
		banner_text = "HEAT WON"
		banner_color = GOOD
		Synth.sfx("coin", 1.5)
		Juice.burst(self, Vector2(SD.FRONT_X, 410), GOOD)
		Juice.popup(self, Vector2(640, 300), "+%d" % pts, GOOD)
		Juice.flash(Color(1, 1, 1, 0.15), 0.1)
		if wins >= HEATS_TO_WIN:
			finish(Rules.final_score(score, lives), true)
		return
	if Rules.is_grace(heat_r):
		banner_text = "TRY AGAIN"
		banner_color = DIM
		Synth.sfx("miss")
		return
	lives -= 1
	life_flash_t = 0.4
	banner_text = "BLOWN" if result == BLOWN else "HEAT LOST"
	banner_color = BAD
	Synth.sfx("boom", randf_range(0.95, 1.05))
	Juice.flash(Color(BAD, 0.35), 0.2)
	Juice.shake(SHAKE_HARD)
	Juice.hitstop(HITSTOP)
	Juice.burst(self, Vector2(380, 410), BAD)
	if result == BLOWN:
		dead = true
		Juice.burst(self, Vector2(380, 410), DIM, 20, 160.0)
	Synth.stop_loop()
	if lives <= 0:
		finish(score, false)
		return
	loop_restart_t = LOOP_RESTART_DELAY


func _draw() -> void:
	var racing := state == RACING
	var rival_d := Rules.rival_dist(race_t, rival_T)
	var top_gear := g >= gears - 1
	var tint_blow := red_t >= Rules.BLOW_TIME * 0.5 and Rules.blow_on(heat_r) and sin(TAU * 4.0 * clock) > 0.0
	var tinted := fail_tint_t > 0.0 or tint_blow
	var squash := lerpf(1.0, SQUAT, squat_t / SQUAT_TIME)
	SD.draw_backdrop(self)
	SD.draw_skyline(self, d)
	SD.draw_road(self, d)
	SD.draw_lines_and_tree(self, d, lights, state != STAGING, TREE_AT_M, go_t > GO_TIME - GO_FLASH)
	var rx := SD.sx(rival_d, d) - SD.CAR_LEN
	if rx > -200.0 and rx < 1480.0:
		SD.draw_car(self, Vector2(rx, RIVAL_GROUND), DIM, TRACE, 4.0, 1.0, rival_d / 22.0 * 6.0, false)
	var boosting := boost_t > 0.0 and racing
	if boosting:
		SD.draw_flame(self, clock)
	var body := DIM if dead else (BAD if tinted else ACCENT)
	SD.draw_car(self, Vector2(SD.FRONT_X - SD.CAR_LEN, PLAYER_GROUND), body,
			TRACE if dead else body, 6.0, squash, d / 22.0, boosting)
	if dead:
		SD.draw_smoke(self, Vector2(SD.FRONT_X - 30.0, PLAYER_GROUND - 56.0), state_t)
	SD.draw_gap(self, d, rival_d)
	SD.draw_minimap(self, d, rival_d)
	var in_band := racing and not top_gear and Rules.rpm(v, g) >= lo and Rules.rpm(v, g) <= hi
	SD.draw_tach(self, shown_rpm, lo, hi, top_gear, red_t, clock, in_band, dead)
	SD.draw_gear_box(self, g + 1, digit_t / 0.2)
	var ke := 1.0 - pow(knob_t / KNOB_TIME, 3.0) if knob_t > 0.0 else 1.0
	SD.draw_lever(self, lerpf(KNOB_KICK, KNOB_REST, ke), in_band or go_t > 0.0, clock, not shifted_once)
	var ba := 1.0 if banner_t > 0.3 else banner_t / 0.3
	if go_t > 0.0:
		SD.draw_go(self, GO_TIME - go_t, GO_TIME)
	SD.draw_hud(self, score, lives, wins, win_pop_t / 0.2, life_flash_t, banner_text, banner_color, ba)
