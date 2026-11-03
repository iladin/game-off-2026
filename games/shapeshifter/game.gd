extends MicroGame
## Shapeshifter: become the shape of the hole before the wall reaches you.
## Left/Up/Right (A/W/D) or the three bottom buttons = circle/triangle/square.

const Rules := preload("res://games/shapeshifter/rules.gd")
const TD := preload("res://games/shapeshifter/tunnel_draw.gd")

const LIVES := 3
const INTRO_TIME := 0.6
const LOOP_NOTES: Array = [52, 64, 59, 64, 55, 64, 59, 62, 52, 64, 59, 64, 57, 62, 59, 55]
const LOOP_BPM := 132.0
const LOOP_VOL := 0.10
const LOOP_VOL_RUSH := 0.12
const RUSH_TRANSPOSE := 5
const LOOP_RESTART_DELAY := 0.5
const MORPH_TIME := 0.08
const HOLE_MORPH_TIME := 0.12
const SQUASH := 1.25
const SQUASH_SAME := 1.1
const SQUASH_TIME := 0.12
const GHOST_TIME := 0.15
const FAIL_TINT_TIME := 0.2
const PASS_OUT_TIME := 0.12
const FADE_IN_P := 0.15
const WARN_P := 0.75
const HINT_WALLS := 3
const LABEL_TIME := 10.0
const BANNER_TIME := 1.2
const SHAKE_SOFT := 4.0
const SHAKE_HARD := 14.0
const HITSTOP := 0.06
const BOT_LEAD_MIN := 0.30
const BOT_LEAD_MAX := 0.70
const BOT_FUMBLE_EVERY := 4
const BOT_GIVE_UP := 45.0
const BANNERS: Array[String] = ["", "", "DOUBLE", "MORPH", "RUSH"]


class Wall:
	var idx: int = 0
	var shape: int = 0
	var from_shape: int = 0
	var morph_k: float = 1.0
	var age: float = 0.0
	var travel: float = 3.0
	var morph: bool = false
	var morphed: bool = false
	var judged: bool = false
	var out_t: float = -1.0
	var bot_fumble: bool = false
	var bot_done: bool = false
	var bot_lead: float = 0.5

	func p() -> float:
		return age / travel


var elapsed: float = 0.0
var intro: float = 0.0
var blip2_done: bool = false
var player_shape: int = 0
var prev_shape: int = 0
var morph_k: float = 1.0
var squash_t: float = 0.0
var squash_amp: float = SQUASH
var ghost_t: float = 0.0
var fail_tint_t: float = 0.0
var score: int = 0
var streak: int = 0
var lives: int = LIVES
var walls: Array[Wall] = []
var next_spawn_at: float = 0.0
var pair_pending: bool = false
var last_hole: int = 0
var walls_spawned: int = 0
var ring_phase: float = 0.0
var banner_text: String = ""
var banner_t: float = 0.0
var last_phase: int = 0
var loop_restart_t: float = -1.0
var life_flash_t: float = 0.0
var bot_walls: int = 0
var rush_loop: bool = false
var font: Font = ThemeDB.fallback_font


func begin() -> void:
	elapsed = 0.0
	intro = INTRO_TIME
	blip2_done = false
	player_shape = Rules.CIRCLE
	prev_shape = Rules.CIRCLE
	morph_k = 1.0
	squash_t = 0.0
	ghost_t = 0.0
	fail_tint_t = 0.0
	score = 0
	streak = 0
	lives = LIVES
	walls.clear()
	next_spawn_at = 0.0
	pair_pending = false
	last_hole = Rules.CIRCLE
	walls_spawned = 0
	ring_phase = 0.0
	banner_text = ""
	banner_t = 0.0
	last_phase = Rules.phase(Rules.ramp_time(0.0, difficulty))
	loop_restart_t = -1.0
	life_flash_t = 0.0
	bot_walls = 0
	rush_loop = last_phase >= 4
	Synth.stop_loop()
	Synth.sfx("blip")


func _start_loop() -> void:
	var notes: Array = []
	for n in LOOP_NOTES:
		notes.append(int(n) + (RUSH_TRANSPOSE if rush_loop and int(n) > 0 else 0))
	Synth.loop(notes, LOOP_BPM, "square", LOOP_VOL_RUSH if rush_loop else LOOP_VOL)


func _process(delta: float) -> void:
	queue_redraw()
	if is_finished():
		return
	fail_tint_t = maxf(0.0, fail_tint_t - delta)
	squash_t = maxf(0.0, squash_t - delta)
	ghost_t = maxf(0.0, ghost_t - delta)
	life_flash_t = maxf(0.0, life_flash_t - delta)
	banner_t = maxf(0.0, banner_t - delta)
	morph_k = minf(1.0, morph_k + delta / MORPH_TIME)
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
		return
	elapsed += delta
	var r := Rules.ramp_time(elapsed, difficulty)
	_check_phase(r)
	ring_phase += delta / Rules.travel_time(r)
	if elapsed >= next_spawn_at and Rules.can_spawn(r):
		_spawn(r)
	_advance_walls(delta)
	if is_finished():
		return
	if r >= Rules.ROUND_TIME and lives > 0:
		finish(Rules.final_score(score, lives), true)
		return
	if autoplay:
		_bot()


func _check_phase(r: float) -> void:
	var ph := Rules.phase(r)
	if ph > last_phase:
		last_phase = ph
		if BANNERS[ph] != "":
			banner_text = BANNERS[ph]
			banner_t = BANNER_TIME
			Synth.sfx("blip", 1.2)
		if ph == 4:
			rush_loop = true
			_start_loop()


func _spawn(r: float) -> void:
	var w := Wall.new()
	w.idx = walls_spawned
	walls_spawned += 1
	w.shape = Rules.next_shape(last_hole, randi() % 2)
	w.from_shape = w.shape
	w.travel = Rules.travel_time(r)
	w.bot_lead = randf_range(BOT_LEAD_MIN, BOT_LEAD_MAX)
	if pair_pending:
		pair_pending = false
		next_spawn_at = elapsed + Rules.spawn_gap(r)
	elif randf() < Rules.double_chance(r):
		pair_pending = true
		next_spawn_at = elapsed + Rules.DOUBLE_GAP
	else:
		next_spawn_at = elapsed + Rules.spawn_gap(r)
		w.morph = randf() < Rules.morph_chance(r)
	last_hole = w.shape
	if r + w.travel >= Rules.GRACE_END:
		bot_walls += 1
		w.bot_fumble = bot_walls % BOT_FUMBLE_EVERY == 0 or elapsed >= BOT_GIVE_UP
	walls.append(w)


func _advance_walls(delta: float) -> void:
	var r := Rules.ramp_time(elapsed, difficulty)
	for w in walls:
		if w.out_t >= 0.0:
			w.out_t += delta
			continue
		w.age += delta
		w.morph_k = minf(1.0, w.morph_k + delta / HOLE_MORPH_TIME)
		if w.morph and not w.morphed and w.p() >= Rules.MORPH_AT_P:
			w.morphed = true
			w.from_shape = w.shape
			w.shape = Rules.next_shape(w.shape, randi() % 2)
			w.morph_k = 0.0
			last_hole = w.shape if w == walls[walls.size() - 1] else last_hole
			Synth.tone(990.0, 0.07, "sine", 0.22, 495.0)
	for w in walls:
		if w.out_t < 0.0 and not w.judged and w.p() >= 1.0:
			w.judged = true
			if Rules.passes(player_shape, w.shape):
				_pass(w)
			else:
				_crash(w, Rules.is_grace(r))
			if is_finished():
				return
			break
	for i in range(walls.size() - 1, -1, -1):
		var w2 := walls[i]
		if (w2.judged and w2.out_t < 0.0) or w2.out_t > PASS_OUT_TIME:
			walls.remove_at(i)


func _pass(w: Wall) -> void:
	streak += 1
	var pts := Rules.wall_points(streak)
	score += pts
	w.out_t = 0.0
	Synth.sfx("coin", pow(2.0, mini(streak, 12) / 12.0))
	Juice.burst(self, TD.VP, TD.ACCENT)
	Juice.popup(self, TD.VP - Vector2(0, 150), "+%d" % pts, TD.GOOD)
	if streak % Rules.MULT_EVERY == 0 and Rules.multiplier(streak) < Rules.MULT_MAX + 1 and streak <= Rules.MULT_EVERY * (Rules.MULT_MAX - 1):
		Juice.flash(Color(1, 1, 1, 0.15), 0.1)
		Juice.popup(self, TD.VP + Vector2(0, 170), "X%d" % Rules.multiplier(streak), TD.GOOD)
		Juice.shake(SHAKE_SOFT)


func _crash(_w: Wall, grace: bool) -> void:
	streak = 0
	fail_tint_t = FAIL_TINT_TIME
	if grace:
		Synth.sfx("miss", randf_range(0.92, 1.08))
		Juice.shake(SHAKE_SOFT)
		Juice.burst(self, TD.VP, TD.DIM)
		return
	lives -= 1
	life_flash_t = 0.4
	Synth.sfx("boom", randf_range(0.95, 1.05))
	Juice.flash(Color(TD.BAD, 0.35), 0.2)
	Juice.shake(SHAKE_HARD)
	Juice.hitstop(HITSTOP)
	Juice.burst(self, TD.VP, TD.BAD)
	Synth.stop_loop()
	loop_restart_t = LOOP_RESTART_DELAY
	if lives <= 0:
		finish(score, false)


func _unhandled_input(event: InputEvent) -> void:
	if autoplay or is_finished() or intro > 0.0:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_LEFT, KEY_A:
				_select_shape(Rules.CIRCLE)
			KEY_UP, KEY_W:
				_select_shape(Rules.TRIANGLE)
			KEY_RIGHT, KEY_D:
				_select_shape(Rules.SQUARE)
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_select_shape(Rules.shape_for_tap_x(event.position.x))


func _select_shape(s: int) -> void:
	if s == player_shape:
		Synth.sfx("blip", 0.9)
		squash_amp = SQUASH_SAME
		squash_t = SQUASH_TIME
		return
	prev_shape = player_shape
	player_shape = s
	morph_k = 0.0
	squash_amp = SQUASH
	squash_t = SQUASH_TIME
	ghost_t = GHOST_TIME
	Synth.sfx("shift", Rules.shift_pitch(streak))


func _bot() -> void:
	var target: Wall = null
	for w in walls:
		if w.out_t < 0.0 and not w.judged and (target == null or w.p() > target.p()):
			target = w
	if target == null or target.bot_done:
		return
	if target.morph and not target.morphed:
		return
	if target.travel * (1.0 - target.p()) <= target.bot_lead:
		target.bot_done = true
		_select_shape((target.shape + 1) % 3 if target.bot_fumble else target.shape)


func _draw() -> void:
	var r := Rules.ramp_time(elapsed, difficulty)
	TD.draw_backdrop(self)
	if r > 73.0:
		TD.draw_exit(self, clampf((r - 73.0) / 2.0, 0.0, 1.0))
	TD.draw_rings(self, ring_phase, r >= Rules.RUSH_AT)
	var nearest: Wall = null
	for w in walls:
		if w.out_t < 0.0 and (nearest == null or w.p() > nearest.p()):
			nearest = w
	for i in range(walls.size() - 1, -1, -1):
		if walls[i].out_t < 0.0:
			_draw_wall(walls[i], 1.0, 1.0, false)
	var sq := 1.0 + (squash_amp - 1.0) * (squash_t / SQUASH_TIME)
	var tint := TD.BAD if fail_tint_t > 0.0 else TD.ACCENT
	TD.draw_player(self, prev_shape, player_shape, morph_k, sq, tint, prev_shape, 1.0 - ghost_t / GHOST_TIME if ghost_t > 0.0 else 1.0)
	for w in walls:
		if w.out_t < 0.0:
			_draw_wall(w, 1.0, 1.0, true)
	for w in walls:
		if w.out_t >= 0.0:
			var k := clampf(w.out_t / PASS_OUT_TIME, 0.0, 1.0)
			_draw_wall(w, lerpf(1.0, 1.6, k), 1.0 - k, false)
	var glow := -1
	if nearest != null and nearest.idx < HINT_WALLS and nearest.shape != player_shape:
		glow = nearest.shape
	var ga := 0.25 + 0.2 * sin(TAU * 3.0 * elapsed)
	TD.draw_buttons(self, font, player_shape, glow, ga, elapsed < LABEL_TIME)
	var ba := clampf(banner_t / 0.3, 0.0, 1.0)
	TD.draw_hud(self, font, score, Rules.multiplier(streak), lives, LIVES, life_flash_t, r / Rules.ROUND_TIME, banner_text, ba)


func _draw_wall(w: Wall, s_mul: float, a_mul: float, outline_only: bool) -> void:
	var p := minf(w.p(), 1.0)
	var s := Rules.wall_scale(p) * s_mul
	var alpha := clampf(p / FADE_IN_P, 0.0, 1.0) * a_mul
	var col := Color(TD.ACCENT, (0.5 + 0.5 * p) * a_mul)
	var lw := maxf(1.5, 4.0 * s)
	if w.out_t < 0.0 and p > WARN_P:
		if Rules.passes(player_shape, w.shape):
			col = TD.ACCENT
			lw = 6.0
		else:
			col = Color(TD.BAD, 0.5 + 0.5 * absf(sin(TAU * 2.0 * elapsed)))
			lw = 4.0
	var rad := TD.radii(w.from_shape, w.shape, w.morph_k, s, true)
	if outline_only:
		# Drawn over the player, so accent-on-accent would vanish: use INK (or BAD) here.
		if absf(col.g - TD.ACCENT.g) < 0.01:
			col = Color(TD.INK, maxf(col.a, 0.5 + 0.5 * p))
		TD.draw_outline(self, TD.VP, rad, col, maxf(lw, 3.0))
	else:
		TD.draw_wall(self, rad, s, alpha, col, lw)
