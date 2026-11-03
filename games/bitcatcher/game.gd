extends MicroGame
## Bit Catcher: a falling bit, an 8-bit register. You cannot move the bit; you rotate the
## register (rol8 / ror8, on both register and target) so each 1 lands in a socket.

const R := preload("res://games/bitcatcher/rules.gd")
const BD := preload("res://games/bitcatcher/bits_draw.gd")
const Fx := preload("res://games/bitcatcher/bits_fx.gd")
const Inp := preload("res://games/bitcatcher/bits_input.gd")

const LIVES := 3
const INTRO_TIME := 0.6
const FIRST_SPAWN := 0.1
const BYTE_PAUSE := 0.5
const FADE_IN := 0.15
const PAD_DOWN_TIME := 0.1
const SQUASH := 1.25
const SQUASH_TIME := 0.12
const BYTE_FLASH_TIME := 0.15
const POP_TIME := 0.2
const FAIL_TINT_TIME := 0.2
const LIFE_FLASH_TIME := 0.4
const BANNER_TIME := 1.2
const HINT_FLASH_TIME := 0.3
const RING_TIME := 0.1
const LOOP_NOTES: Array = [57, 0, 64, 0, 60, 0, 57, 0, 62, 0, 64, 0, 67, 0, 64, 0]
const LOOP_VOL := 0.09
const LOOP_RESTART_DELAY := 0.5
const TOP_TRANSPOSE := 12
const SHAKE_SOFT := 4.0
const SHAKE_HARD := 14.0
const HITSTOP := 0.06
const BOT_STEP := 0.1
const BOT_REACT := 0.36
const BOT_SLAM_CHANCE := 0.7

var rng := RandomNumberGenerator.new()
var fx := Fx.new()
var inp := Inp.new()
var intro_t: float = 0.0
var intro_blip2: bool = false
var in_intro: bool = true
var t: float = 0.0
var reg: int = 0
var target: int = 0
var bytes_done: int = 0
var score: int = 0
var streak: int = 0
var lives: int = LIVES
var bit_alive: bool = false
var bit_col: int = 0
var bit_y: float = 0.0
var bit_one: bool = true
var bit_speed: float = 100.0
var bit_age: float = 0.0
var fast: bool = false
var spawn_wait: float = 0.0
var last_cols: Array[int] = [-1, -1]
var last_was_zero: bool = false
var last_phase: String = ""
var loop_restart_t: float = 0.0
var top_music: bool = false
var bot_t: float = 0.0
var bot_slam: bool = true


func begin() -> void:
	rng.randomize()
	intro_t = 0.0; intro_blip2 = false; in_intro = true; t = 0.0; reg = 0
	bytes_done = 0; score = 0; streak = 0
	lives = LIVES
	bit_alive = false; fast = false; spawn_wait = 0.0; last_cols = [-1, -1]; last_was_zero = false
	last_phase = ""; loop_restart_t = 0.0; top_music = false; bot_t = 0.0
	fx = Fx.new()
	inp = Inp.new()
	inp.shifted.connect(_shift)
	inp.dropped.connect(_drop)
	target = R.make_target(R.ones_for(R.ramp_time(0.0, difficulty)), -1, rng)
	Synth.stop_loop()
	Synth.sfx("blip")


func _ramp() -> float: return R.ramp_time(t, difficulty)


func _start_loop() -> void:
	var notes: Array = LOOP_NOTES
	if top_music:
		notes = []
		for n in LOOP_NOTES:
			notes.append(n + TOP_TRANSPOSE if n > 0 else 0)
	Synth.loop(notes, 120.0, "square", LOOP_VOL)


func _process(delta: float) -> void:
	queue_redraw()
	if is_finished():
		return
	fx.tick(delta)
	if inp.pressing and not inp.swiped:
		fx.pad_down_t[inp.press_zone] = maxf(fx.pad_down_t[inp.press_zone], PAD_DOWN_TIME)
	if in_intro:
		intro_t += delta
		if not intro_blip2 and intro_t >= 0.3:
			intro_blip2 = true
			Synth.sfx("blip")
		if intro_t >= INTRO_TIME:
			in_intro = false
			t = 0.0
			spawn_wait = FIRST_SPAWN
			_start_loop()
		return
	t += delta
	var r := _ramp()
	var ph := R.phase_name(r)
	if ph != last_phase:
		last_phase = ph
		if ph != "":
			fx.banner_text = ph
			fx.banner_t = BANNER_TIME
		if r >= R.TOP_AT and not top_music:
			top_music = true
			if loop_restart_t <= 0.0:
				_start_loop()
	if loop_restart_t > 0.0:
		loop_restart_t -= delta
		if loop_restart_t <= 0.0:
			_start_loop()
	if not bit_alive:
		spawn_wait -= delta
		if spawn_wait <= 0.0:
			_spawn(r)
	else:
		bit_age += delta
		bit_y += (R.FAST_SPEED if fast else bit_speed) * delta
		if bit_y >= R.LAND_Y:
			_land(r)
			return
	if autoplay:
		_bot(delta)


func _spawn(r: float) -> void:
	var first := bytes_done == 0 and score == 0 and last_cols[1] == -1
	var c := rng.randi_range(0, R.CELLS - 1)
	if first:
		var socks: Array[int] = []
		for i in R.CELLS:
			if R.bit_at(target, i) == 1 and R.bit_at(reg, i) == 0:
				socks.append(i)
		c = socks[rng.randi_range(0, socks.size() - 1)]
	else:
		while c == last_cols[0] and c == last_cols[1]:
			c = rng.randi_range(0, R.CELLS - 1)
	last_cols = [last_cols[1], c]
	bit_one = true
	if not first and reg != 0 and not last_was_zero and rng.randf() < R.zero_chance(r):
		bit_one = false
	last_was_zero = not bit_one
	bit_col = c
	bit_y = R.SPAWN_Y
	bit_speed = R.fall_speed(r)
	bit_age = 0.0
	bit_alive = true
	fast = false
	bot_slam = rng.randf() < BOT_SLAM_CHANCE and not first


func _bot(delta: float) -> void:
	bot_t += delta
	if bot_t < BOT_STEP:
		return
	bot_t = 0.0
	if not bit_alive or fast or bit_age < BOT_REACT:
		return
	var d := R.best_shift(reg, target, bit_col, bit_one)
	if d < 0:
		_shift(R.LEFT)
	elif d > 0:
		_shift(R.RIGHT)
	elif bot_slam:
		_drop()


func _unhandled_input(event: InputEvent) -> void:
	if autoplay or is_finished():
		return
	inp.handle(event, in_intro)


func _shift(dir: int) -> void:
	if in_intro or is_finished():
		return
	if dir == R.LEFT:
		reg = R.rol8(reg)
		target = R.rol8(target)
		fx.wrap_col = 7
	else:
		reg = R.ror8(reg)
		target = R.ror8(target)
		fx.wrap_col = 0
	fx.slide_dir = 1 if dir == R.LEFT else -1
	fx.slide_t = 0.0
	fx.pad_down_t[dir] = PAD_DOWN_TIME
	Synth.sfx("shift", R.shift_pitch(streak))


func _drop() -> void:
	if bit_alive and not fast:
		fast = true
		Synth.tone(520.0, 0.08, "triangle", 0.18, 260.0)


func _cell_centre(c: int) -> Vector2:
	return Vector2(R.col_x(c), R.REG_Y + 50.0)


func _land(r: float) -> void:
	var c := bit_col
	var was_fast := fast
	var at := _cell_centre(c)
	bit_alive = false
	fast = false
	spawn_wait = R.spawn_gap(r)
	if was_fast:
		fx.ring_c = c
		fx.ring_t = RING_TIME
	if bit_one:
		if R.land_one(reg, target, c) == R.SET:
			var pts := R.hit_points(streak, was_fast)
			Synth.sfx("coin", pow(2.0, mini(streak, 12) / 12.0))
			streak += 1
			reg = R.apply_one(reg, c)
			score += pts
			fx.squash_c = c
			fx.squash_t = SQUASH_TIME
			Juice.burst(self, at, BD.ACCENT)
			Juice.popup(self, at - Vector2(0, 70), "+%d" % pts, BD.GOOD)
			if was_fast:
				Juice.shake(SHAKE_SOFT)
			if reg == target:
				_byte_done(r)
		else:
			_hard_fail(c, r)
	elif R.land_zero(reg, c) == R.LOST:
		reg = R.apply_zero(reg, c)
		streak = 0
		fx.bad_c = c
		fx.bad_t = FAIL_TINT_TIME
		fx.tint_t = FAIL_TINT_TIME
		Synth.sfx("miss", randf_range(0.92, 1.08))
		Juice.shake(SHAKE_SOFT)
		Juice.popup(self, at - Vector2(0, 70), "LOST BIT", BD.BAD)
	else:
		score += R.DODGE_PTS
		Synth.sfx("blip", randf_range(0.66, 0.74))


func _byte_done(r: float) -> void:
	bytes_done += 1
	fx.byte_flash_t = BYTE_FLASH_TIME
	fx.byte_squash_t = SQUASH_TIME
	fx.pop_t = 0.0
	score += R.BYTE_PTS
	Synth.tone(1047.0, 0.16, "square", 0.30, 2093.0)
	Juice.flash(Color(1, 1, 1, 0.15), 0.1)
	Juice.shake(SHAKE_SOFT)
	Juice.popup(self, Vector2(640, 400), "BYTE", BD.GOOD, 40)
	if bytes_done >= R.BYTES_TO_WIN:
		finish(R.final_score(score, lives), true)
		return
	target = R.make_target(R.ones_for(r), target, rng)
	reg = 0
	spawn_wait = BYTE_PAUSE


func _hard_fail(c: int, r: float) -> void:
	streak = 0
	var at := _cell_centre(c)
	if R.is_grace(r):
		fx.hint_flash_t = HINT_FLASH_TIME
		Synth.sfx("miss", randf_range(0.92, 1.08))
		Juice.popup(self, at - Vector2(0, 70), "NOT HERE", BD.DIM)
		return
	lives -= 1
	fx.life_flash_t = LIFE_FLASH_TIME
	Synth.sfx("boom", randf_range(0.95, 1.05))
	Synth.stop_loop()
	loop_restart_t = LOOP_RESTART_DELAY
	Juice.flash(Color(BD.BAD, 0.35), 0.2)
	Juice.shake(SHAKE_HARD)
	Juice.hitstop(HITSTOP)
	Juice.burst(self, at, BD.BAD)
	Juice.popup(self, at - Vector2(0, 70), "WRONG", BD.BAD)
	if lives <= 0:
		finish(score, false)


func _draw() -> void:
	BD.draw_scene(self)
