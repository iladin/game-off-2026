extends Node
## Arcade (autoload): the collection's shell. Owns the game registry, switching
## between the hub and games, the shared HUD (back, mute, pause), the result card
## after every round, and the command-line hooks scripts/check.sh and shots use.
##
## Command line (after `--`):
##   --game=<slug>          boot straight into a game (any folder with game.tscn)
##   --autoplay             the game's bot plays; after each round it restarts
##   --tour                 attract mode: autoplay every hub game in turn, return to hub between
##   --hubdemo=<n>          debug: the hub shows n (0 to 8) placeholder games, every other one cleared; no Save, no registry, launching only plays `select`
##   --gauntlet             boot straight into the OVERFLOW gauntlet (combine with --autoplay for a bot run)
##   --shotfile=<png>       save a screenshot after --shotframes=<n> frames (default 180), then quit
##
## OVERFLOW gauntlet (additive): `Arcade.start_gauntlet()` runs every hub game in slot order at difficulty 1,
## 8 s each, 3 lives (shared/gauntlet_rules.gd), records the sum under slug "overflow" and shows one result card.
## Log lines: "ARCADE gauntlet game <slug> <i>/<n>", "ARCADE gauntlet pass|life <slug> lives=<l> score=<s>", "ARCADE gauntlet done ...".
##
## Reserved keys (games must not use them): Esc = back to hub, P = pause, M = mute.
## Log lines start with "ARCADE " so check.sh can assert on them.

const HUB_SCENE := "res://hub/hub.tscn"
const REGISTRY := "res://games/registry.json"
const FADE_TIME := 0.12
const RESULT_INPUT_DELAY := 0.6
const AUTOPLAY_RESTART_DELAY := 0.5
const TOUR_SECONDS := 3.0
const GauntletRules := preload("res://shared/gauntlet_rules.gd")
const OVERFLOW_SLUG := "overflow"
const GOOD := Color("ffd34d")
const CARD_TIME := 0.6 ## gauntlet interstitial card
const CARD_FLIP_AT := 0.28
const CARD_WORD_SIZE := 96
const REG_STEP := 0.11 ## result register: seconds between carry steps

## Hub games in order: [{slug, title, tagline, controls, accent: Color, ...game.json}]
var games: Array[Dictionary] = []
var current_slug: String = ""
var autoplay: bool = false
## Debug (--hubdemo=<n>): number of placeholder hub entries to show, 0 = off.
var hubdemo: int = 0

var _args: Dictionary = {}
var _game: MicroGame = null
var _fade: ColorRect
var _hud: CanvasLayer
var _back_btn: Button
var _mute_btn: Button
var _pause_overlay: Control
var _result: Control
var _result_title: Label
var _result_score: Label
var _result_best: Label
var _result_shown_at: float = -1.0
var _shot_frames: int = -1
var _frames: int = 0
var _gauntlet: Dictionary = {}
var _gauntlet_game: MicroGame = null
var _gauntlet_label: Label
var _gauntlet_lives: Control
var _slot_live: bool = false
var _slot_playable: bool = false
var _card: Control
var _card_t: float = -1.0
var _card_info: Dictionary = {}
var _card_idx: int = 0
var _card_flipped: bool = false
var _reg: Control
var _reg_t: float = -1.0
var _reg_passed: int = 0
var _reg_n: int = 8
var _reg_won: bool = false
var _font: Font = ThemeDB.fallback_font


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_args = parse_args(OS.get_cmdline_user_args())
	autoplay = _args.has("autoplay") or _args.has("tour")
	if _args.has("hubdemo"):
		var hd := String(_args["hubdemo"])
		hubdemo = clampi(int(hd) if hd.is_valid_int() else 8, 0, 8)
	if _args.has("shotfile"):
		_shot_frames = int(_args.get("shotframes", "180"))
	games = load_registry()
	_build_ui()


static func parse_args(args: PackedStringArray) -> Dictionary:
	var out := {}
	for a in args:
		if not a.begins_with("--"):
			continue
		var kv := a.substr(2).split("=", true, 1)
		out[kv[0]] = kv[1] if kv.size() > 1 else "true"
	return out


## Called once by main.gd (deferred).
func boot() -> void:
	print("ARCADE boot games=%d args=%s" % [games.size(), _args])
	if _args.has("gauntlet"):
		start_gauntlet()
	elif _args.has("resultdemo"):
		_fade.color.a = 0.0
		_reg_passed = games.size()
		_show_result(OVERFLOW_SLUG, 1234, true, true)
	elif _args.has("game"):
		launch(String(_args["game"]))
	elif _args.has("tour"):
		_tour()
	else:
		to_hub()


# --- Registry ------------------------------------------------------------------

static func read_json(path: String) -> Variant:
	if not FileAccess.file_exists(path):
		return null
	return JSON.parse_string(FileAccess.get_file_as_string(path))


static func game_info(slug: String) -> Dictionary:
	var info: Variant = read_json("res://games/%s/game.json" % slug)
	var d: Dictionary = info if info is Dictionary else {}
	d["slug"] = slug
	d["title"] = String(d.get("title", slug))
	d["tagline"] = String(d.get("tagline", ""))
	d["controls"] = String(d.get("controls", ""))
	d["accent"] = Color.from_string(String(d.get("accent", "#5ee6ff")), Color("5ee6ff"))
	return d


static func load_registry() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var reg: Variant = read_json(REGISTRY)
	if not (reg is Dictionary):
		return out
	for slug in reg.get("order", []):
		if ResourceLoader.exists("res://games/%s/game.tscn" % slug):
			out.append(game_info(String(slug)))
	return out


func info_for(slug: String) -> Dictionary:
	for g in games:
		if g["slug"] == slug:
			return g
	return game_info(slug)


# --- Scene switching -------------------------------------------------------------

func to_hub() -> void:
	current_slug = ""
	_gauntlet = {}
	_gauntlet_game = null
	_gauntlet_label.visible = false
	_gauntlet_lives.visible = false
	_card.visible = false
	_card_t = -1.0
	_reg_t = -1.0
	await _fade_out()
	var scene: PackedScene = load(HUB_SCENE)
	_swap(scene.instantiate())
	_back_btn.visible = false
	_result.visible = false
	print("ARCADE hub")
	await _fade_in()


func launch(slug: String) -> void:
	var path := "res://games/%s/game.tscn" % slug
	if not ResourceLoader.exists(path):
		push_error("ARCADE no such game: %s" % slug)
		return
	await _fade_out()
	var node: Node = (load(path) as PackedScene).instantiate()
	if not (node is MicroGame):
		push_error("ARCADE %s/game.tscn root must extend MicroGame" % slug)
		node.free()
		return
	var g: MicroGame = node
	g.slug = slug
	g.autoplay = autoplay
	g.finished.connect(_on_finished.bind(g))
	current_slug = slug
	_game = g
	_swap(g)
	_result.visible = false
	_back_btn.visible = true
	print("ARCADE launch %s autoplay=%s" % [slug, autoplay])
	g.begin()
	await _fade_in()


# --- OVERFLOW gauntlet ---------------------------------------------------------------

func start_gauntlet() -> void:
	if games.is_empty():
		print("ARCADE gauntlet: no games")
		to_hub()
		return
	_gauntlet = GauntletRules.new_state(games.size())
	_gauntlet_game = null
	current_slug = OVERFLOW_SLUG
	print("ARCADE gauntlet start n=%d" % games.size())
	await _gauntlet_next()


func _gauntlet_next() -> void:
	if GauntletRules.is_done(_gauntlet):
		_gauntlet_end()
		return
	var i: int = _gauntlet["index"]
	var slug: String = games[i]["slug"]
	await _fade_out()
	if _gauntlet.is_empty():
		return # left for the hub meanwhile
	_swap(Node.new()) # clear the previous game behind the card
	_gauntlet_label.visible = false
	_gauntlet_lives.visible = false
	_back_btn.visible = true
	_card_start(i)
	await _fade_in()
	await get_tree().create_timer(CARD_TIME).timeout
	_card_t = -1.0
	_card.visible = false
	if _gauntlet.is_empty():
		return
	var node: Node = (load("res://games/%s/game.tscn" % slug) as PackedScene).instantiate()
	var g: MicroGame = node as MicroGame
	if g == null:
		node.free()
		_gauntlet = GauntletRules.on_finish(_gauntlet, 0, false)
		await _gauntlet_next()
		return
	g.slug = slug
	g.autoplay = autoplay
	g.difficulty = GauntletRules.DIFFICULTY
	g.finished.connect(_on_gauntlet_finished.bind(g))
	_slot_live = false
	_slot_playable = false
	g.playable.connect(func() -> void: _slot_playable = true)
	_gauntlet_game = g
	current_slug = OVERFLOW_SLUG
	_swap(g)
	_result.visible = false
	_back_btn.visible = true
	_gauntlet_label.text = _gauntlet_text()
	_gauntlet_label.visible = true
	_gauntlet_lives.visible = true
	_gauntlet_lives.queue_redraw()
	print("ARCADE gauntlet game %s %d/%d" % [slug, i + 1, games.size()])
	g.begin()


func _on_gauntlet_finished(score: int, won: bool, g: MicroGame) -> void:
	if g != _gauntlet_game or _gauntlet.is_empty():
		return
	_gauntlet_game = null
	_gauntlet = GauntletRules.on_finish(_gauntlet, score, won)
	print("ARCADE gauntlet %s %s lives=%d score=%d" % ["pass" if won else "life", g.slug, _gauntlet["lives"], GauntletRules.total(_gauntlet)])
	Synth.sfx("coin" if won else "hit")
	g.process_mode = Node.PROCESS_MODE_DISABLED
	await _gauntlet_next()


func _gauntlet_tick(delta: float) -> void:
	if _gauntlet.is_empty() or _gauntlet_game == null or get_tree().paused:
		return
	if not _slot_live:
		if _slot_playable or _intro_over(_gauntlet_game):
			_slot_live = true
		else:
			_gauntlet_text_refresh()
			return
	var gs: Variant = _gauntlet_game.get("score")
	var before: int = _gauntlet["index"]
	_gauntlet = GauntletRules.tick(_gauntlet, delta, int(gs) if gs is int or gs is float else 0)
	_gauntlet_label.text = _gauntlet_text()
	_gauntlet_lives.queue_redraw()
	if int(_gauntlet["index"]) != before:
		var g := _gauntlet_game
		_gauntlet_game = null
		print("ARCADE gauntlet pass %s lives=%d score=%d" % [g.slug, _gauntlet["lives"], GauntletRules.total(_gauntlet)])
		Synth.sfx("coin")
		g.process_mode = Node.PROCESS_MODE_DISABLED
		_gauntlet_next()


func _gauntlet_text_refresh() -> void:
	_gauntlet_label.text = _gauntlet_text()


## True when a game exposing `in_intro` / `intro` is past its intro (games without either count from begin()).
func _intro_over(g: MicroGame) -> bool:
	var a: Variant = g.get("in_intro")
	if a is bool:
		return not a
	var b: Variant = g.get("intro")
	if b is float:
		return b <= 0.0
	return true


func _card_start(i: int) -> void:
	_card_info = games[i]
	_card_idx = i
	_card_t = 0.0
	_card_flipped = false
	_card.visible = true
	_card.queue_redraw()


func _draw_card() -> void:
	if _card_t < 0.0 or _card_info.is_empty():
		return
	var acc: Color = _card_info["accent"]
	var word := String(_card_info.get("sense", _card_info["title"])).to_upper()
	var a := clampf(_card_t / 0.12, 0.0, 1.0)
	_card.draw_rect(Rect2(0, 0, 1280, 720), Color("0b0e14"))
	var sc := 1.0 + 0.25 * (1.0 - a)
	_card.draw_string(_font, Vector2(0, 360), word, HORIZONTAL_ALIGNMENT_CENTER, 1280, int(CARD_WORD_SIZE * sc), Color(acc, a))
	# register row: passed slots are 1, this slot flips 0 -> 1
	var n: int = int(_gauntlet.get("n", games.size())) if not _gauntlet.is_empty() else games.size()
	var cw := 64.0
	var x0 := 640.0 - (n * (cw + 12.0) - 12.0) * 0.5
	for k in n:
		var r := Rect2(x0 + k * (cw + 12.0), 430, cw, 80)
		var on := k < _card_idx or (k == _card_idx and _card_t >= CARD_FLIP_AT)
		var col := acc if k == _card_idx else Color("6b7489")
		_card.draw_rect(r, Color("151a24"))
		_card.draw_rect(r, Color(col, 1.0 if k == _card_idx else 0.5), false, 4.0 if k == _card_idx else 2.0)
		var sq := 1.0
		if k == _card_idx:
			var d := absf(_card_t - CARD_FLIP_AT)
			sq = lerpf(0.4, 1.0, clampf(d / 0.12, 0.0, 1.0))
		var fs := int(56 * sq)
		_card.draw_string(_font, Vector2(r.position.x, r.position.y + 58), "1" if on else "0", HORIZONTAL_ALIGNMENT_CENTER, cw, fs, acc if k == _card_idx else Color("e8ecf4"))


func _card_tick(delta: float) -> void:
	if _card_t < 0.0:
		return
	_card_t += delta
	if not _card_flipped and _card_t >= CARD_FLIP_AT:
		_card_flipped = true
		Synth.sfx("shift")
	_card.queue_redraw()


func _draw_reg() -> void:
	if _reg_t < 0.0:
		return
	var n := _reg_n
	var cw := 56.0
	var gap := 10.0
	var x0 := 300.0 - (n * (cw + gap) - gap) * 0.5
	var step := int(floor(_reg_t / REG_STEP)) if _reg_won else -1
	for k in n:
		var r := Rect2(x0 + k * (cw + gap), 10, cw, 72)
		var on := (k < _reg_passed) if not _reg_won else (k < step)
		var carry := _reg_won and k == step
		var edge := GOOD if (on or carry) else Color("6b7489")
		_reg.draw_rect(r, Color(GOOD, 0.35) if carry else Color("151a24"))
		_reg.draw_rect(r, edge, false, 3.0)
		_reg.draw_string(_font, Vector2(r.position.x, r.position.y + 54), "1" if on else "0", HORIZONTAL_ALIGNMENT_CENTER, cw, 48, GOOD if on else Color("e8ecf4"))


func _reg_tick(delta: float) -> void:
	if _reg_t < 0.0:
		return
	var before := _reg_t
	_reg_t += delta
	var s0 := int(floor(before / REG_STEP))
	var s1 := int(floor(_reg_t / REG_STEP))
	if _reg_won and s1 != s0 and s1 <= _reg_n:
		Synth.sfx("shift", 1.0 + 0.04 * s1)
		if s1 == _reg_n:
			_result_title.text = "OVERFLOW"
			_result_title.add_theme_color_override("font_color", GOOD)
			Synth.sfx("coin")
	_reg.queue_redraw()


func _gauntlet_text() -> String:
	return "GAME %d OF %d\nTIME %.1f\nRUN LIVES" % [mini(int(_gauntlet["index"]) + 1, int(_gauntlet["n"])), int(_gauntlet["n"]), GauntletRules.time_left(_gauntlet)]


func _draw_gauntlet_lives() -> void:
	if _gauntlet.is_empty():
		return
	for i in GauntletRules.LIVES:
		var r := Rect2(Vector2(16 + i * 30, 164), Vector2(20, 20))
		if i < int(_gauntlet["lives"]):
			_gauntlet_lives.draw_rect(r, GOOD)
		else:
			_gauntlet_lives.draw_rect(r, Color(GOOD, 0.35), false, 2.0)


func _gauntlet_end() -> void:
	var score := GauntletRules.total(_gauntlet)
	var won := GauntletRules.completed(_gauntlet)
	var new_best := Save.record(OVERFLOW_SLUG, score, won)
	print("ARCADE gauntlet done score=%d won=%s best=%d" % [score, won, Save.best(OVERFLOW_SLUG)])
	_reg_passed = int(_gauntlet["passed"])
	_reg_n = int(_gauntlet["n"])
	_gauntlet = {}
	_gauntlet_game = null
	_gauntlet_label.visible = false
	_gauntlet_lives.visible = false
	Synth.stop_loop()
	Synth.sfx("win" if won else "lose")
	if autoplay and not _args.has("shotfile"):
		return
	_show_result(OVERFLOW_SLUG, score, won, new_best)


func _swap(node: Node) -> void:
	var tree := get_tree()
	tree.paused = false
	_pause_overlay.visible = false
	Juice.reset()
	Synth.stop_loop()
	var old := tree.current_scene
	if old != null:
		tree.root.remove_child(old)
		old.queue_free()
	tree.root.add_child(node)
	tree.current_scene = node


func _on_finished(score: int, won: bool, g: MicroGame) -> void:
	if g != _game:
		return
	var new_best := Save.record(g.slug, score, won)
	print("ARCADE finished %s score=%d won=%s best=%d" % [g.slug, score, won, Save.best(g.slug)])
	g.process_mode = Node.PROCESS_MODE_DISABLED
	Synth.stop_loop()
	Synth.sfx("win" if won else "lose")
	if autoplay:
		if not _args.has("tour"):
			await get_tree().create_timer(AUTOPLAY_RESTART_DELAY).timeout
			if g == _game:
				launch(g.slug)
		return
	_show_result(g.slug, score, won, new_best)


# --- Tour (attract mode) -----------------------------------------------------------

func _tour() -> void:
	if games.is_empty():
		print("ARCADE tour: no games in registry")
		to_hub()
		return
	while true:
		for g in games:
			await launch(g["slug"])
			await get_tree().create_timer(TOUR_SECONDS).timeout
			await to_hub()
			await get_tree().create_timer(0.5).timeout
		print("ARCADE tour done")


# --- Input ------------------------------------------------------------------------

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.physical_keycode:
			KEY_ESCAPE:
				if current_slug != "":
					get_viewport().set_input_as_handled()
					Synth.sfx("back")
					to_hub()
			KEY_M:
				get_viewport().set_input_as_handled()
				_toggle_mute()
			KEY_P:
				if current_slug != "" and not _result.visible:
					get_viewport().set_input_as_handled()
					_set_paused(not get_tree().paused)
				return
	if _result.visible and _result_age() > RESULT_INPUT_DELAY:
		if event.is_action_pressed("ui_accept") or (event is InputEventKey and event.pressed and event.physical_keycode == KEY_R):
			get_viewport().set_input_as_handled()
			_retry()
	elif _pause_overlay.visible and _is_press(event):
		get_viewport().set_input_as_handled()
		_set_paused(false)


func _is_press(event: InputEvent) -> bool:
	return (event is InputEventKey and event.pressed) or (event is InputEventMouseButton and event.pressed)


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and current_slug != "" and not autoplay and not _result.visible:
		_set_paused(true)


func _set_paused(on: bool) -> void:
	get_tree().paused = on
	_pause_overlay.visible = on


func _toggle_mute() -> void:
	Synth.set_muted(not Synth.muted)
	_mute_btn.text = "SOUND OFF" if Synth.muted else "SOUND ON"


func _retry() -> void:
	Synth.sfx("select")
	if current_slug == OVERFLOW_SLUG:
		start_gauntlet()
		return
	launch(current_slug)


func _result_age() -> float:
	return Time.get_ticks_msec() / 1000.0 - _result_shown_at


# --- Screenshots -----------------------------------------------------------------

func _process(delta: float) -> void:
	_gauntlet_tick(delta)
	_card_tick(delta)
	_reg_tick(delta)
	if _shot_frames < 0:
		return
	_frames += 1
	if _frames < _shot_frames:
		return
	_shot_frames = -1
	var path := String(_args["shotfile"])
	var tex := get_viewport().get_texture()
	var img: Image = tex.get_image() if tex != null else null
	if img == null or img.is_empty():
		print("ARCADE shot FAILED (no renderer? run with xvfb-run and --rendering-driver opengl3)")
	else:
		DirAccess.make_dir_recursive_absolute(path.get_base_dir())
		img.save_png(path)
		print("ARCADE shot %s" % path)
	get_tree().quit()


# --- Shared UI --------------------------------------------------------------------

func _build_ui() -> void:
	_hud = CanvasLayer.new()
	_hud.layer = 80
	add_child(_hud)

	_back_btn = _make_button("< HUB", Vector2(120, 48))
	_back_btn.position = Vector2(16, 12)
	_hud.add_child(_back_btn)
	_back_btn.pressed.connect(func() -> void:
		Synth.sfx("back")
		to_hub())
	_back_btn.visible = false
	_gauntlet_label = _make_label("", 28, GOOD)
	# Left gutter (x 0-165, y 74+) is outside every game's HUD (art bible: HUD lives in x 170-1090).
	_gauntlet_label.position = Vector2(14, 76)
	_gauntlet_label.size = Vector2(150, 84)
	_gauntlet_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_gauntlet_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	_gauntlet_label.add_theme_font_size_override("font_size", 20)
	_gauntlet_label.visible = false
	_hud.add_child(_gauntlet_label)
	_gauntlet_lives = Control.new()
	_gauntlet_lives.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_gauntlet_lives.visible = false
	_gauntlet_lives.draw.connect(_draw_gauntlet_lives)
	_hud.add_child(_gauntlet_lives)
	_card = Control.new()
	_card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_card.visible = false
	_card.draw.connect(_draw_card)
	_hud.add_child(_card)
	_hud.move_child(_card, 0)
	_mute_btn = _make_button("SOUND ON", Vector2(150, 48))
	_mute_btn.position = Vector2(1280 - 16 - 150, 12)
	_hud.add_child(_mute_btn)
	_mute_btn.pressed.connect(_toggle_mute)
	_mute_btn.text = "SOUND OFF" if Synth.muted else "SOUND ON"

	_pause_overlay = _make_panel(Color(0, 0, 0, 0.7))
	var pl := _make_label("PAUSED\nclick or press any key", 44, Color.WHITE)
	pl.set_anchors_preset(Control.PRESET_FULL_RECT)
	_pause_overlay.add_child(pl)
	_pause_overlay.visible = false

	_result = _make_panel(Color(0, 0, 0, 0.72))
	var box := VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_CENTER)
	box.custom_minimum_size = Vector2(600, 340)
	box.offset_left = -300.0
	box.offset_right = 300.0
	box.offset_top = -170.0
	box.offset_bottom = 170.0
	box.grow_horizontal = Control.GROW_DIRECTION_BOTH
	box.grow_vertical = Control.GROW_DIRECTION_BOTH
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 14)
	_result.add_child(box)
	_result_title = _make_label("", 60, Color.WHITE)
	_result_score = _make_label("", 40, Color.WHITE)
	_result_best = _make_label("", 30, Color("ffcc4d"))
	box.add_child(_result_title)
	box.add_child(_result_score)
	box.add_child(_result_best)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 24)
	box.add_child(row)
	var retry := _make_button("RETRY  (Space)", Vector2(240, 64))
	retry.pressed.connect(_retry)
	var hub := _make_button("HUB  (Esc)", Vector2(200, 64))
	hub.pressed.connect(func() -> void:
		Synth.sfx("back")
		to_hub())
	row.add_child(retry)
	row.add_child(hub)
	_reg = Control.new()
	_reg.custom_minimum_size = Vector2(600, 92)
	_reg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_reg.visible = false
	_reg.draw.connect(_draw_reg)
	box.add_child(_reg)
	box.move_child(_reg, 1)
	_result.visible = false

	var fade_layer := CanvasLayer.new()
	fade_layer.layer = 100
	add_child(fade_layer)
	_fade = ColorRect.new()
	_fade.color = Color(0, 0, 0, 1)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	fade_layer.add_child(_fade)


func _show_result(slug: String, score: int, won: bool, new_best: bool) -> void:
	var info := info_for(slug)
	if slug == OVERFLOW_SLUG:
		info = {"title": "OVERFLOW", "accent": GOOD}
	_result_title.text = ("CLEAR!" if won else "GAME OVER")
	_result_title.add_theme_color_override("font_color", info["accent"])
	_result_score.text = "%s:  %d" % [info["title"], score]
	_result_best.text = "NEW BEST!" if new_best else "Best %d" % Save.best(slug)
	_reg.visible = slug == OVERFLOW_SLUG
	_reg_t = 0.0 if slug == OVERFLOW_SLUG else -1.0
	_reg_won = won
	if slug == OVERFLOW_SLUG and won:
		_result_title.text = ""
	_result.visible = true
	_result.modulate.a = 0.0
	create_tween().tween_property(_result, "modulate:a", 1.0, 0.2)
	_result_shown_at = Time.get_ticks_msec() / 1000.0


func _fade_out() -> void:
	var t := create_tween()
	t.tween_property(_fade, "color:a", 1.0, FADE_TIME)
	await t.finished


func _fade_in() -> void:
	var t := create_tween()
	t.tween_property(_fade, "color:a", 0.0, FADE_TIME)
	await t.finished


func _make_panel(color: Color) -> ColorRect:
	var r := ColorRect.new()
	r.color = color
	r.set_anchors_preset(Control.PRESET_FULL_RECT)
	r.mouse_filter = Control.MOUSE_FILTER_STOP
	_hud.add_child(r)
	return r


func _make_label(text: String, size: int, color: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


func _make_button(text: String, size: Vector2) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = size
	b.size = size
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_font_size_override("font_size", 22)
	return b
