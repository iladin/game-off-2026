extends Node2D
## Hub: PLACEHOLDER. The Platform Engineer replaces this look with the framing in
## studio/VISION.md (e.g. a shift register or a night-shift clock). Keep the
## behaviour: show every game in Arcade.games, keyboard + mouse/touch selection,
## launch with Arcade.launch(slug), show best score and cleared state.

const TITLE := "SHIFT"
const SUBTITLE := "GitHub Game Off 2026"
const BG := Color("0a0a12")
const INK := Color("e8e8f0")
const DIM := Color("6b6b80")
const COLS := 4
const CARD := Vector2(270, 150)
const GAP := Vector2(24, 24)
const GRID_TOP := 230.0

var selected: int = 0
var t: float = 0.0
var font: Font = ThemeDB.fallback_font


func _ready() -> void:
	selected = clampi(int(Save.setting("hub_selected", 0)), 0, maxi(0, Arcade.games.size() - 1))


func _process(delta: float) -> void:
	t += delta
	queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	var n := Arcade.games.size()
	if n == 0:
		return
	var move := 0
	if event.is_action_pressed("ui_right") or _key(event, KEY_D):
		move = 1
	elif event.is_action_pressed("ui_left") or _key(event, KEY_A):
		move = -1
	elif event.is_action_pressed("ui_down") or _key(event, KEY_S):
		move = COLS
	elif event.is_action_pressed("ui_up") or _key(event, KEY_W):
		move = -COLS
	if move != 0:
		selected = posmod(selected + move, n)
		Synth.sfx("blip")
		return
	if event.is_action_pressed("ui_accept"):
		_open(selected)
	elif event is InputEventMouseMotion:
		var i := _card_at(event.position)
		if i >= 0 and i != selected:
			selected = i
			Synth.sfx("blip")
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var i := _card_at(event.position)
		if i >= 0:
			if i == selected:
				_open(i)
			else:
				selected = i
				Synth.sfx("blip")


func _key(event: InputEvent, key: Key) -> bool:
	return event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == key


func _open(i: int) -> void:
	Save.set_setting("hub_selected", i)
	Synth.sfx("select")
	Arcade.launch(Arcade.games[i]["slug"])


func _card_rect(i: int) -> Rect2:
	var n := Arcade.games.size()
	var cols := mini(COLS, n)
	var width := cols * CARD.x + (cols - 1) * GAP.x
	var origin := Vector2((1280.0 - width) * 0.5, GRID_TOP)
	return Rect2(origin + Vector2(i % COLS, i / COLS) * (CARD + GAP), CARD)


func _card_at(pos: Vector2) -> int:
	for i in Arcade.games.size():
		if _card_rect(i).has_point(pos):
			return i
	return -1


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, Vector2(1280, 720)), BG)
	_text(TITLE, Vector2(640, 120), 96, INK)
	_text(SUBTITLE, Vector2(640, 170), 26, DIM)
	var games := Arcade.games
	if games.is_empty():
		_text("No games yet. The factory is building them.", Vector2(640, 380), 32, DIM)
		return
	for i in games.size():
		var g: Dictionary = games[i]
		var r := _card_rect(i)
		var accent: Color = g["accent"]
		var sel := i == selected
		if sel:
			var pulse := 4.0 + 2.0 * sin(t * 6.0)
			draw_rect(r.grow(pulse), accent, false, 3.0)
		draw_rect(r, accent.darkened(0.75 if not sel else 0.55))
		draw_rect(Rect2(r.position, Vector2(8, r.size.y)), accent)
		_text_left(g["title"], r.position + Vector2(24, 52), 30, INK)
		var best := Save.best(g["slug"])
		_text_left("Best %d" % best if best > 0 else "New", r.position + Vector2(24, 96), 22, DIM.lerp(INK, 0.4))
		if Save.cleared(g["slug"]):
			_text_left("CLEARED", r.position + Vector2(24, 130), 18, accent)
	var cur: Dictionary = games[selected]
	_text(cur["tagline"], Vector2(640, 620), 28, INK)
	_text(cur["controls"], Vector2(640, 660), 22, DIM)
	_text("Arrows choose · Enter / click to play · Esc back · M mute", Vector2(640, 705), 18, DIM)


func _text(s: String, center: Vector2, size: int, color: Color) -> void:
	draw_string(font, Vector2(0, center.y), s, HORIZONTAL_ALIGNMENT_CENTER, 1280, size, color)


func _text_left(s: String, pos: Vector2, size: int, color: Color) -> void:
	draw_string(font, pos, s, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)
