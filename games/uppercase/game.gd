extends MicroGame
## Upper Case: capitals fall over their keys; press the Shift on the OTHER side as
## each crosses the line. Lower case letters pass. Left/Right Shift (or F/J), or tap halves.

const Rules := preload("res://games/uppercase/rules.gd")
const KD := preload("res://games/uppercase/keys_draw.gd")
const Tile := preload("res://games/uppercase/tile.gd")
const SceneDraw := preload("res://games/uppercase/scene_draw.gd")

const ACCENT := Color("3DDCFF")
const GOOD := Color("FFD34D")
const BAD := Color("FF3B5C")
const DIM := Color("6B7489")
const LIVES := 3
const INTRO_TIME := 0.6
const FIRST_CAPS := 4
const LEFT_KEY := Rect2(170, 612, 460, 100)
const RIGHT_KEY := Rect2(650, 612, 460, 100)
const KEY_DOWN_TIME := 0.1
const FADE_IN := 0.15
const SQUASH := 1.25
const SQUASH_TIME := 0.12
const FAIL_TINT_TIME := 0.2
const BANNER_TIME := 1.2
const HINT_FLASH_TIME := 0.3
const STRIP_FLASH_TIME := 0.15
const LOOP_NOTES: Array = [57, 0, 60, 64, 0, 64, 62, 60, 57, 0, 60, 64, 67, 0, 64, 62]
const LOOP_VOL := 0.10
const LOOP_RESTART_DELAY := 0.5
const TOP_TRANSPOSE := 12
const SHAKE_SOFT := 4.0
const SHAKE_HARD := 14.0
const HITSTOP := 0.06
const BOT_SPREAD := 24.0

var intro: float = 0.0
var blip2_done: bool = false
var t: float = 0.0
var beat: float = 0.0
var r: float = 0.0
var clock: float = 0.0
var last_spawn_beat: int = -1
var tiles: Array[Tile] = []
var last_ch: String = ""
var spawned: int = 0
var score: int = 0
var streak: int = 0
var lives: int = LIVES
var key_down_t: Array[float] = [0.0, 0.0]
var key_bad_t: Array[float] = [0.0, 0.0]
var hint_flash_t: float = 0.0
var hint_flash_side: int = 0
var life_flash_t: float = 0.0
var strip_flash_t: float = 0.0
var strip_flash_ch: String = ""
var score_squash_t: float = 0.0
var banner_text: String = ""
var banner_t: float = 0.0
var last_phase: String = ""
var loop_wait_beat: int = -1
var top_music: bool = false
var columns_x: Array[float] = []


func begin() -> void:
	intro = INTRO_TIME
	blip2_done = false
	t = 0.0
	beat = 0.0
	clock = 0.0
	last_spawn_beat = -1
	tiles.clear()
	last_ch = ""
	spawned = 0
	score = 0
	streak = 0
	lives = LIVES
	key_down_t = [0.0, 0.0]
	key_bad_t = [0.0, 0.0]
	hint_flash_t = 0.0
	life_flash_t = 0.0
	strip_flash_t = 0.0
	strip_flash_ch = ""
	score_squash_t = 0.0
	banner_text = ""
	banner_t = 0.0
	last_phase = ""
	loop_wait_beat = -1
	top_music = false
	if columns_x.is_empty():
		for i in 26:
			columns_x.append(Rules.key_center(char(65 + i)).x)
	Synth.stop_loop()
	Synth.sfx("blip")
	r = Rules.ramp_time(0.0, difficulty)


func _start_loop() -> void:
	var notes: Array = LOOP_NOTES
	if top_music:
		notes = []
		for n in LOOP_NOTES:
			notes.append(n + TOP_TRANSPOSE if n > 0 else 0)
	Synth.loop(notes, Rules.BPM, "triangle", LOOP_VOL)


func _process(delta: float) -> void:
	queue_redraw()
	if is_finished():
		return
	clock += delta
	for i in 2:
		key_down_t[i] = maxf(0.0, key_down_t[i] - delta)
		key_bad_t[i] = maxf(0.0, key_bad_t[i] - delta)
	hint_flash_t = maxf(0.0, hint_flash_t - delta)
	life_flash_t = maxf(0.0, life_flash_t - delta)
	strip_flash_t = maxf(0.0, strip_flash_t - delta)
	score_squash_t = maxf(0.0, score_squash_t - delta)
	banner_t = maxf(0.0, banner_t - delta)
	if intro > 0.0:
		intro -= delta
		if not blip2_done and intro <= INTRO_TIME - 0.3:
			blip2_done = true
			Synth.sfx("blip")
		if intro > 0.0:
			return
		t = 0.0
		_start_loop()
	else:
		t += delta
	beat = t / Rules.BEAT
	r = Rules.ramp_time(t, difficulty)
	var ph := Rules.phase_name(r)
	if ph != last_phase:
		last_phase = ph
		if ph != "":
			banner_text = ph
			banner_t = BANNER_TIME
	if r >= Rules.TOP_AT and not top_music:
		top_music = true
		Synth.stop_loop()
		loop_wait_beat = int(floor(beat)) + 1
	if loop_wait_beat >= 0 and int(floor(beat)) >= loop_wait_beat:
		loop_wait_beat = -1
		_start_loop()
	_spawn()
	_move_tiles(delta)
	if is_finished():
		return
	if autoplay:
		_bot()
	if is_finished():
		return
	if t >= Rules.SPAWN_END:
		var open := false
		for tl in tiles:
			if not tl.judged:
				open = true
		if not open:
			finish(Rules.final_score(score, lives), true)


func _spawn() -> void:
	var b := int(floor(beat))
	if b <= last_spawn_beat or t >= Rules.SPAWN_END:
		return
	last_spawn_beat = b
	if b % Rules.spawn_every(r) != 0:
		return
	var tl := Tile.new()
	var ch := last_ch
	while ch == last_ch:
		ch = char(65 + randi_range(0, 25))
	last_ch = ch
	tl.ch = ch
	tl.x = Rules.key_center(ch).x
	tl.upper = spawned < FIRST_CAPS or randf() >= Rules.lower_chance(r)
	tl.spawn_beat = float(b)
	tl.travel = Rules.travel_beats(r)
	tl.bot_off = randf_range(-BOT_SPREAD, BOT_SPREAD)
	spawned += 1
	tiles.append(tl)


func _move_tiles(delta: float) -> void:
	for i in range(tiles.size() - 1, -1, -1):
		var tl: Tile = tiles[i]
		tl.age += delta
		tl.y = Rules.letter_y(beat - tl.spawn_beat, tl.travel)
		if tl.fx_t > 0.0:
			tl.fx_t -= delta
		if tl.judged:
			if (tl.fx in [1, 2] and tl.fx_t <= 0.0) or (tl.fx == 3 and tl.y > Rules.TILE_GONE_Y) or (tl.fx == 0 and tl.y > Rules.TILE_GONE_Y):
				tiles.remove_at(i)
			continue
		if Rules.is_missed(tl.y):
			tl.judged = true
			if tl.upper:
				tl.fx = 2
				tl.fx_t = FAIL_TINT_TIME
				_hard_fail(tl, "MISSED", Rules.correct_shift(tl.ch), -1)
				if is_finished():
					return
			else:
				tl.fx = 3
				score += Rules.LOWER_PASS_PTS
				Juice.popup(self, Vector2(tl.x, Rules.LINE_Y - 50.0), "+%d" % Rules.LOWER_PASS_PTS, DIM)


func _nearest(only_window: bool, only_upper: bool) -> Tile:
	var best: Tile = null
	var bd := 1.0e9
	for tl in tiles:
		if tl.judged or (only_upper and not tl.upper):
			continue
		var d := absf(tl.y - Rules.LINE_Y)
		if only_window and Rules.judge(tl.y - Rules.LINE_Y) == Rules.NONE:
			continue
		if d < bd:
			bd = d
			best = tl
	return best


func _bot() -> void:
	var tl := _nearest(false, true)
	if tl != null and tl.y >= Rules.LINE_Y + tl.bot_off and tl.y > Rules.LINE_Y - Rules.GOOD_PX:
		_press(Rules.correct_shift(tl.ch))


func _unhandled_input(event: InputEvent) -> void:
	if autoplay or is_finished() or intro > 0.0:
		return
	var side := SceneDraw.side_from_event(event)
	if side >= 0:
		_press(side)


func _press(side: int) -> void:
	Synth.sfx("shift", Rules.shift_pitch(streak))
	key_down_t[side] = KEY_DOWN_TIME
	var tl := _nearest(true, false)
	if tl == null:
		_soft_fail(null, "", side)
		return
	if not tl.upper:
		tl.judged = true
		tl.fx = 2
		tl.fx_t = FAIL_TINT_TIME
		_soft_fail(tl, "SMALL", side)
		return
	if side != Rules.correct_shift(tl.ch):
		tl.judged = true
		tl.fx = 2
		tl.fx_t = FAIL_TINT_TIME
		_hard_fail(tl, "TYPO", side, side)
		return
	var j := Rules.judge(tl.y - Rules.LINE_Y)
	var pts := Rules.hit_points(j, streak)
	var pos := Vector2(tl.x, tl.y)
	tl.judged = true
	tl.fx = 1
	tl.fx_t = SQUASH_TIME
	score += pts
	score_squash_t = 0.12
	strip_flash_ch = tl.ch
	strip_flash_t = STRIP_FLASH_TIME
	if j == Rules.PERFECT:
		Synth.sfx("coin", pow(2.0, mini(streak, 12) / 12.0))
		Juice.burst(self, pos, ACCENT, 14)
		Juice.popup(self, pos - Vector2(0, 50), "PERFECT", GOOD)
	else:
		Synth.sfx("coin", 0.84)
		Juice.burst(self, pos, ACCENT, 8)
		Juice.popup(self, pos - Vector2(0, 50), "+%d" % pts, GOOD)
	streak += 1
	if streak % 10 == 0:
		Juice.flash(Color(1, 1, 1, 0.15), 0.1)


func _soft_fail(tl: Tile, text: String, side: int) -> void:
	streak = 0
	Synth.sfx("miss", randf_range(0.92, 1.08))
	Juice.shake(SHAKE_SOFT)
	if tl == null:
		key_bad_t[side] = FAIL_TINT_TIME
	else:
		Juice.popup(self, Vector2(tl.x, tl.y - 50.0), text, BAD)


func _hard_fail(tl: Tile, text: String, correct: int, pressed: int) -> void:
	streak = 0
	var pos := Vector2(tl.x, minf(tl.y, 494.0))
	if Rules.is_grace(r):
		hint_flash_t = HINT_FLASH_TIME
		hint_flash_side = correct
		Synth.sfx("miss", randf_range(0.92, 1.08))
		Juice.popup(self, pos - Vector2(0, 50), "OTHER SIDE" if text == "TYPO" else text, DIM)
		return
	lives -= 1
	life_flash_t = 0.4
	key_bad_t[pressed if pressed >= 0 else correct] = FAIL_TINT_TIME
	Synth.sfx("boom", randf_range(0.95, 1.05))
	Synth.stop_loop()
	loop_wait_beat = int(ceil((t + LOOP_RESTART_DELAY) / Rules.BEAT))
	Juice.flash(Color(BAD, 0.35), 0.2)
	Juice.shake(SHAKE_HARD)
	Juice.hitstop(HITSTOP)
	Juice.burst(self, pos, BAD)
	Juice.popup(self, pos - Vector2(0, 50), text, BAD)
	if lives <= 0:
		finish(score, false)


func _draw() -> void:
	SceneDraw.draw(self)
