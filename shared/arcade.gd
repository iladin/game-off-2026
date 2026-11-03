extends Node
## Arcade (autoload): the collection's shell. Owns the game registry, switching
## between the hub and games, the shared HUD (back, mute, pause), the result card
## after every round, and the command-line hooks scripts/check.sh and shots use.
##
## Command line (after `--`):
##   --game=<slug>          boot straight into a game (any folder with game.tscn)
##   --autoplay             the game's bot plays; after each round it restarts
##   --tour                 attract mode: autoplay every hub game in turn, return to hub between
##   --shotfile=<png>       save a screenshot after --shotframes=<n> frames (default 180), then quit
##
## Reserved keys (games must not use them): Esc = back to hub, P = pause, M = mute.
## Log lines start with "ARCADE " so check.sh can assert on them.

const HUB_SCENE := "res://hub/hub.tscn"
const REGISTRY := "res://games/registry.json"
const FADE_TIME := 0.12
const RESULT_INPUT_DELAY := 0.6
const AUTOPLAY_RESTART_DELAY := 0.5
const TOUR_SECONDS := 3.0

## Hub games in order: [{slug, title, tagline, controls, accent: Color, ...game.json}]
var games: Array[Dictionary] = []
var current_slug: String = ""
var autoplay: bool = false

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
var _font: Font = ThemeDB.fallback_font


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_args = parse_args(OS.get_cmdline_user_args())
	autoplay = _args.has("autoplay") or _args.has("tour")
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
	if _args.has("game"):
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
	launch(current_slug)


func _result_age() -> float:
	return Time.get_ticks_msec() / 1000.0 - _result_shown_at


# --- Screenshots -----------------------------------------------------------------

func _process(_delta: float) -> void:
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
	box.position = Vector2(1280, 720) * 0.5 - Vector2(300, 170)
	box.custom_minimum_size = Vector2(600, 340)
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
	_result_title.text = ("CLEAR!" if won else "GAME OVER")
	_result_title.add_theme_color_override("font_color", info["accent"])
	_result_score.text = "%s:  %d" % [info["title"], score]
	_result_best.text = "NEW BEST!" if new_best else "Best %d" % Save.best(slug)
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
