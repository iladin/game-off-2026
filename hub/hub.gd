extends Node2D
## Hub v1: the SHIFT REGISTER (studio/VISION.md section 7). One cell per game in
## Arcade.games, a 0/1 digit per cell (1 = cleared), a read head on the selected
## cell and an info panel with a drawn PLAY button. Logic lives in hub_rules.gd.
## Debug: `-- --hubdemo=8` shows placeholder entries (no Save, launching only plays select).

const Rules := preload("res://hub/hub_rules.gd")

const BG := Color("0b0e14")
const PANEL := Color("151a24")
const TRACE := Color("1e2738")
const DIM := Color("6b7489")
const INK := Color("e8ecf4")
const GOOD := Color("ffd34d")
const NEUTRAL := Color("3ddcff")
const GRID := 40
const BUS_Y := 400.0
const DOT_SPEED := 120.0
const DOT_SPACING := 160.0
const HEAD_TIME := 0.15
const PANEL_RECT := Rect2(64, 440, 1152, 236)
const PLAY_SIZE := Vector2(260, 80)
const MUSIC := [57, 0, 64, 0, 60, 0, 64, 67, 57, 0, 64, 0, 62, 0, 60, 59]

var selected: int = 0
var t: float = 0.0
var font: Font = ThemeDB.fallback_font
var _entries: Array[Dictionary] = []
var _rects: Array[Rect2] = []
var _demo: bool = false
var _head: Rect2 = Rect2()
var _head_from: Rect2 = Rect2()
var _head_to: Rect2 = Rect2()
var _head_t: float = 1.0


func _ready() -> void:
	_demo = Arcade.hubdemo > 0
	if _demo:
		_entries = Rules.demo_entries(Arcade.hubdemo)
	else:
		for g in Arcade.games:
			var e: Dictionary = g.duplicate()
			e["cleared"] = Save.cleared(e["slug"])
			e["best"] = Save.best(e["slug"])
			_entries.append(e)
		selected = clampi(int(Save.setting("hub_selected", 0)), 0, maxi(0, _entries.size() - 1))
	_rects = Rules.cell_rects(_entries.size())
	if not _rects.is_empty():
		_head = _rects[selected]
		_head_from = _head
		_head_to = _head
	Synth.loop(MUSIC, 96.0, "triangle", 0.10)


func _process(delta: float) -> void:
	t += delta
	if _head_t < 1.0:
		_head_t = minf(1.0, _head_t + delta / HEAD_TIME)
		var k := 1.0 - pow(1.0 - _head_t, 3.0)
		_head = Rect2(_head_from.position.lerp(_head_to.position, k), _head_to.size)
	queue_redraw()


func _select(i: int) -> void:
	if i == selected:
		return
	selected = i
	_head_from = _head
	_head_to = _rects[i]
	_head_t = 0.0
	if not _demo:
		Save.set_setting("hub_selected", i)
	Synth.sfx("blip")


func _unhandled_input(event: InputEvent) -> void:
	var n := _entries.size()
	if n == 0:
		return
	if event.is_action_pressed("ui_right") or _key(event, KEY_D):
		_select(posmod(selected + 1, n))
	elif event.is_action_pressed("ui_left") or _key(event, KEY_A):
		_select(posmod(selected - 1, n))
	elif event.is_action_pressed("ui_accept"):
		_open()
	elif event is InputEventMouseMotion:
		var i := Rules.cell_at(_rects, event.position)
		if i >= 0:
			_select(i)
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var i := Rules.cell_at(_rects, event.position)
		if i >= 0:
			if i == selected:
				_open()
			else:
				_select(i)
		elif _play_rect().has_point(event.position):
			_open()


func _key(event: InputEvent, key: Key) -> bool:
	return event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == key


func _open() -> void:
	Synth.sfx("select")
	if _demo:
		return
	Save.set_setting("hub_selected", selected)
	Arcade.launch(_entries[selected]["slug"])


func _play_rect() -> Rect2:
	return Rect2(PANEL_RECT.end - Vector2(24, 24) - PLAY_SIZE, PLAY_SIZE)


# --- Drawing ----------------------------------------------------------------------

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, Vector2(1280, 720)), BG)
	for x in range(0, 1281, GRID):
		draw_line(Vector2(x, 0), Vector2(x, 720), TRACE, 1.0)
	for y in range(0, 721, GRID):
		draw_line(Vector2(0, y), Vector2(1280, y), TRACE, 1.0)
	var n := _entries.size()
	var k := 0
	for e in _entries:
		if e["cleared"]:
			k += 1
	_text("SHIFT REGISTER", Vector2(640, 110), 64, INK)
	_text("%d OF %d BITS SET" % [k, n], Vector2(640, 170), 28, DIM)
	if n == 0:
		for r in Rules.cell_rects(8):
			draw_rect(r, TRACE, false, 2.0)
		_bus()
		_text("THE FACTORY IS BUILDING THE FIRST BIT", Vector2(640, 490), 32, DIM)
		_footer()
		return
	for i in n:
		_cell(i)
	_bus()
	_read_head()
	_info()
	_footer()


func _cell(i: int) -> void:
	var e := _entries[i]
	var r := _rects[i]
	var accent: Color = e["accent"]
	var on: bool = e["cleared"]
	draw_rect(r, PANEL)
	draw_rect(r, TRACE, false, 2.0)
	_text_left("%d" % (i + 1), r.position + Vector2(10, 30), 22, DIM)
	var c := r.position + Vector2(60, 68)
	if on:
		_digit("1", c, 64 * 1.6, Color(accent, 0.10))
		_digit("1", c, 64 * 1.3, Color(accent, 0.25))
		_digit("1", c, 64, accent)
	else:
		_digit("0", c, 64, DIM)
	var word := String(e.get("sense", e["title"])).to_upper()
	var sz := 22
	while sz > 12 and font.get_string_size(word, HORIZONTAL_ALIGNMENT_LEFT, -1, sz).x > r.size.x - 8.0:
		sz -= 1
	_text(word, r.position + Vector2(60, 118), sz, INK if on else DIM)
	draw_rect(Rect2(r.position + Vector2(0, r.size.y - 6), Vector2(r.size.x, 6)), accent)


func _bus() -> void:
	draw_line(Vector2(0, BUS_Y), Vector2(1280, BUS_Y), TRACE, 2.0)
	for i in 9:
		var x := fposmod(t * DOT_SPEED + i * DOT_SPACING, 1280.0 + DOT_SPACING) - DOT_SPACING * 0.5
		draw_circle(Vector2(x, BUS_Y), 4.0, Color(INK, 0.8))


func _read_head() -> void:
	var accent: Color = _entries[selected]["accent"]
	var pulse := 0.5 + 0.5 * sin(t * TAU * 3.0)
	var r := _head.grow(8.0 + 2.0 * pulse)
	var col := Color(accent, 0.7 + 0.3 * pulse)
	var l := 26.0
	var w := 6.0
	var h := w * 0.5
	var tl := r.position
	var br := r.end
	var tr := Vector2(br.x, tl.y)
	var bl := Vector2(tl.x, br.y)
	draw_line(tl + Vector2(-h, 0), tl + Vector2(l, 0), col, w)
	draw_line(tl, tl + Vector2(0, l), col, w)
	draw_line(tr + Vector2(h, 0), tr + Vector2(-l, 0), col, w)
	draw_line(tr, tr + Vector2(0, l), col, w)
	draw_line(bl + Vector2(-h, 0), bl + Vector2(l, 0), col, w)
	draw_line(bl, bl + Vector2(0, -l), col, w)
	draw_line(br + Vector2(h, 0), br + Vector2(-l, 0), col, w)
	draw_line(br, br + Vector2(0, -l), col, w)


func _info() -> void:
	var e := _entries[selected]
	var accent: Color = e["accent"]
	draw_rect(PANEL_RECT, PANEL)
	draw_rect(PANEL_RECT, TRACE, false, 2.0)
	draw_rect(Rect2(PANEL_RECT.position, Vector2(6, PANEL_RECT.size.y)), accent)
	var x := PANEL_RECT.position.x + 32.0
	_text_left(String(e["title"]).to_upper(), Vector2(x, 496), 48, INK)
	_text_left(String(e["tagline"]), Vector2(x, 540), 28, INK)
	_text_left(String(e["controls"]), Vector2(x, 578), 24, DIM)
	var best: int = e["best"]
	var line := "BEST %d" % best if best > 0 else "NEW"
	_text_left(line, Vector2(x, 630), 28, GOOD if best > 0 else DIM)
	if e["cleared"]:
		var w := font.get_string_size(line, HORIZONTAL_ALIGNMENT_LEFT, -1, 28).x
		_text_left("CLEARED", Vector2(x + w + 32.0, 630), 28, GOOD)
	var pr := _play_rect()
	draw_rect(pr, accent)
	_text("PLAY", pr.get_center(), 36, BG)


func _footer() -> void:
	_text("LEFT / RIGHT choose   ENTER or tap PLAY   M sound", Vector2(640, 700), 22, DIM)


## Centred on `center` (both axes).
func _text(s: String, center: Vector2, size: int, color: Color) -> void:
	var base := center.y + (font.get_ascent(size) - font.get_descent(size)) * 0.5
	draw_string(font, Vector2(center.x - 640.0, base), s, HORIZONTAL_ALIGNMENT_CENTER, 1280, size, color)


func _text_left(s: String, pos: Vector2, size: int, color: Color) -> void:
	draw_string(font, pos, s, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)


## A digit centred on `center` by cap height, so scaled glow copies stay concentric.
func _digit(s: String, center: Vector2, size: int, color: Color) -> void:
	draw_string(font, Vector2(center.x - 640.0, center.y + 0.36 * size), s, HORIZONTAL_ALIGNMENT_CENTER, 1280, size, color)
