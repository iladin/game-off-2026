extends Node2D
## Hub v1: the SHIFT REGISTER (studio/VISION.md section 7). One cell per game in
## Arcade.games, a 0/1 digit per cell (1 = cleared), a read head on the selected
## cell and an info panel with a drawn PLAY button. Logic lives in hub_rules.gd.
## Debug: `-- --hubdemo=8` shows placeholder entries (no Save, launching only plays select).
## Bit-set ceremony: a game cleared but not in Save setting "seen_cleared" flips 0 to 1 once.
## OVERFLOW finale: one extra cell after the last bit (dim and locked until Rules.overflow_unlocked, then gold;
## launching it runs Arcade.start_gauntlet()). Debug: `-- --qa-overflow` fakes every bit set (inert: no Save writes);
## `-- --hubdemo=8` shows the locked cell, `-- --hubdemo=8 --qa-overflow` the unlocked one.
## Debug: `-- --qa-touch` shows the touch footer (TAP A BIT   TAP PLAY) without a touch.
## Debug: `-- --hubempty` shows the zero-games empty state.
## Debug: `-- --hubdemo=8 --hubceremony=2` plays the ceremony on demo cell 3 (index 2) at 0.5 s.

const Rules := preload("res://hub/hub_rules.gd")

const BG := Color("0b0e14")
const PANEL := Color("151a24")
const TRACE := Color("1e2738")
const DIM := Color("6b7489")
const INK := Color("e8ecf4")
const GOOD := Color("ffd34d")
const NEUTRAL := Color("3ddcff")
const GRID := 40
const ONE_INK := Vector2(-5.0, -1.0) ## measured offset of the 64 px "1" ink centre from its draw centre
const EMPTY_OUTLINE := Color(DIM, 0.7) ## empty-state cell outlines: DIM so they read against the TRACE grid
const BUS_Y := 400.0
const DOT_SPEED := 120.0
const DOT_SPACING := 160.0
const HEAD_TIME := 0.15
const PANEL_RECT := Rect2(64, 440, 1152, 236)
const PLAY_SIZE := Vector2(280, 104) ## at least 96 px tall for touch; sits in the panel, below the cell row
const FLIP_DELAY := 0.5
const FLIP_TIME := 0.25
const FLIP_GAP := 0.6
const MUSIC := [57, 0, 64, 0, 60, 0, 64, 67, 57, 0, 64, 0, 62, 0, 60, 59]

var selected: int = 0
var t: float = 0.0
var font: Font = ThemeDB.fallback_font
var _entries: Array[Dictionary] = []
var _rects: Array[Rect2] = []
var _demo: bool = false
var _touch: bool = false ## true after a touch input (or `-- --qa-touch`): footer shows touch wording
var _overflow_on: bool = false
var _head: Rect2 = Rect2()
var _head_from: Rect2 = Rect2()
var _head_to: Rect2 = Rect2()
var _head_t: float = 1.0
var _flips: Dictionary = {} ## cell index -> t when its flip starts
var _flip_done: Dictionary = {} ## cell index -> true once the 1 has landed (burst and coin played)


func _ready() -> void:
	_demo = Arcade.hubdemo > 0
	_touch = "--qa-touch" in OS.get_cmdline_user_args()
	if _demo:
		_entries = Rules.demo_entries(Arcade.hubdemo)
		for a in OS.get_cmdline_user_args():
			if a.begins_with("--hubceremony="):
				var ci := int(a.get_slice("=", 1))
				if ci >= 0 and ci < _entries.size():
					_entries[ci]["cleared"] = true
					_flips[ci] = FLIP_DELAY
	else:
		for g in Arcade.games:
			if "--hubempty" in OS.get_cmdline_user_args():
				break
			var e: Dictionary = g.duplicate()
			e["cleared"] = Save.cleared(e["slug"])
			e["best"] = Save.best(e["slug"])
			_entries.append(e)
		selected = clampi(int(Save.setting("hub_selected", 0)), 0, maxi(0, _cells() - 1))
		_plan_ceremony()
	if "--qa-overflow" in OS.get_cmdline_user_args():
		for e in _entries:
			e["cleared"] = true
	var slugs: Array = []
	var cleared := {}
	for e in _entries:
		slugs.append(e["slug"])
		cleared[e["slug"]] = e["cleared"]
	_overflow_on = Rules.overflow_unlocked(slugs, cleared)
	selected = clampi(selected, 0, maxi(0, _cells() - 1))
	_rects = Rules.cell_rects(_cells())
	if not _rects.is_empty():
		_head = _rects[selected]
		_head_from = _head
		_head_to = _head
	Synth.loop(MUSIC, 96.0, "triangle", 0.10)


## Register cells: one per game plus the OVERFLOW cell (none when there are no games).
func _cells() -> int:
	return _entries.size() + 1 if not _entries.is_empty() else 0


func _is_overflow(i: int) -> bool:
	return i == _entries.size() and not _entries.is_empty()


func _plan_ceremony() -> void:
	var slugs: Array = []
	var cleared := {}
	for e in _entries:
		slugs.append(e["slug"])
		cleared[e["slug"]] = e["cleared"]
	var seen: Array = Save.setting("seen_cleared", [])
	var fresh := Rules.newly_cleared(slugs, cleared, seen)
	var n := 0
	for slug in fresh:
		_flips[slugs.find(slug)] = FLIP_DELAY + n * FLIP_GAP
		n += 1


## 0..1 progress of cell i's flip, or -1 when it has none (or it is finished).
func _flip_p(i: int) -> float:
	if not _flips.has(i) or _flip_done.has(i):
		return -1.0
	return clampf((t - float(_flips[i])) / FLIP_TIME, 0.0, 1.0) if t >= float(_flips[i]) else 0.0


func _bit_on(i: int) -> bool:
	return _entries[i]["cleared"] and not (_flips.has(i) and not _flip_done.has(i))


func _tick_flips() -> void:
	for i in _flips.keys():
		if _flip_done.has(i):
			continue
		var st: float = _flips[i]
		if t >= st and not _flip_done.has(-1 - i):
			_flip_done[-1 - i] = true # started: play shift once
			Synth.sfx("shift")
			if not _demo: # recorded only now that the ceremony really starts, so it never replays
				var seen: Array = Save.setting("seen_cleared", [])
				Save.set_setting("seen_cleared", Rules.merge_seen(seen, [_entries[i]["slug"]]))
		if t >= st + FLIP_TIME * 0.5 and not _flip_done.has(-1000 - i):
			_flip_done[-1000 - i] = true # the 1 appears: coin and burst
			Synth.sfx("coin")
			Juice.burst(self, _rects[i].position + Vector2(60, 68), _entries[i]["accent"], 18, 300.0)
		if t >= st + FLIP_TIME:
			_flip_done[i] = true


func _process(delta: float) -> void:
	t += delta
	_tick_flips()
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
	if event is InputEventScreenTouch or event is InputEventScreenDrag:
		_touch = true
	elif event is InputEventKey or event is InputEventJoypadButton:
		_touch = false
	var n := _cells()
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
		elif _can_play() and _play_rect().has_point(event.position):
			_open()


func _key(event: InputEvent, key: Key) -> bool:
	return event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == key


func _can_play() -> bool:
	return not _is_overflow(selected) or _overflow_on


func _open() -> void:
	if not _can_play():
		Synth.sfx("back")
		return
	Synth.sfx("select")
	if _demo:
		return
	if _is_overflow(selected):
		Save.set_setting("hub_selected", selected)
		Arcade.start_gauntlet()
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
	for j in n:
		if _bit_on(j):
			k += 1
	_text("SHIFT REGISTER", Vector2(640, 110), 64, INK)
	_text("%d OF %d BITS SET" % [k, n], Vector2(640, 170), 28, DIM)
	if n == 0:
		for r in Rules.cell_rects(8):
			draw_rect(r, PANEL)
			draw_rect(r, EMPTY_OUTLINE, false, 2.0)
		_bus()
		_text("THE FACTORY IS BUILDING THE FIRST BIT", Vector2(640, 490), 32, DIM)
		_footer()
		return
	for i in n:
		_cell(i)
	_overflow_cell()
	_bus()
	_read_head()
	_info()
	_footer()


func _cell(i: int) -> void:
	var e := _entries[i]
	var r := _rects[i]
	var accent: Color = e["accent"]
	var on: bool = _bit_on(i)
	var p := _flip_p(i)
	draw_rect(r, PANEL)
	draw_rect(r, TRACE, false, 2.0)
	_text_left("%d" % (i + 1), r.position + Vector2(10, 30), 22, DIM)
	var c := r.position + Vector2(60, 68)
	if p >= 0.0:
		var sy := absf(1.0 - 2.0 * p) # squash to a line at p 0.5, then back up
		draw_set_transform(Vector2(0, c.y * (1.0 - sy)), 0.0, Vector2(1, sy))
		if p < 0.5:
			_digit("0", c, 64, DIM)
		else:
			_glow("1", c, 1.3, Color(accent, 0.25), Transform2D(0.0, Vector2(1, sy), 0.0, Vector2(0, c.y * (1.0 - sy))))
			_digit("1", c, 64, accent)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	elif on:
		_glow("1", c, 1.6, Color(accent, 0.10))
		_glow("1", c, 1.3, Color(accent, 0.25))
		_digit("1", c, 64, accent)
	else:
		_digit("0", c, 64, DIM)
	var word := String(e.get("sense", e["title"])).to_upper()
	var sz := 22
	while sz > 12 and font.get_string_size(word, HORIZONTAL_ALIGNMENT_LEFT, -1, sz).x > r.size.x - 8.0:
		sz -= 1
	_text(word, r.position + Vector2(60, 118), sz, INK if on else DIM)
	draw_rect(Rect2(r.position + Vector2(0, r.size.y - 6), Vector2(r.size.x, 6)), accent)


func _overflow_cell() -> void:
	var r := _rects[_entries.size()]
	var col := GOOD if _overflow_on else DIM
	draw_rect(r, PANEL)
	draw_rect(r, GOOD if _overflow_on else DIM, false, 2.0)
	_text_left("%d" % (_entries.size() + 1), r.position + Vector2(10, 30), 22, DIM)
	var c := r.position + Vector2(60, 68)
	if _overflow_on:
		var pulse := 0.5 + 0.5 * sin(t * TAU * 1.5)
		draw_arc(c, 34.0 + 3.0 * pulse, 0.0, TAU, 40, Color(GOOD, 0.25), 8.0)
	draw_arc(c, 30.0, 0.0, TAU, 40, col, 5.0)
	draw_line(c + Vector2(-14, 0), c + Vector2(14, 0), col, 5.0)
	draw_line(c + Vector2(0, -14), c + Vector2(0, 14), col, 5.0)
	var word := "OVERFLOW"
	var sz := 22
	while sz > 12 and font.get_string_size(word, HORIZONTAL_ALIGNMENT_LEFT, -1, sz).x > r.size.x - 8.0:
		sz -= 1
	_text(word, r.position + Vector2(60, 118), sz, GOOD if _overflow_on else DIM)
	draw_rect(Rect2(r.position + Vector2(0, r.size.y - 6), Vector2(r.size.x, 6)), GOOD if _overflow_on else TRACE)


func _bus() -> void:
	draw_line(Vector2(0, BUS_Y), Vector2(1280, BUS_Y), TRACE, 2.0)
	for i in 9:
		var x := fposmod(t * DOT_SPEED + i * DOT_SPACING, 1280.0 + DOT_SPACING) - DOT_SPACING * 0.5
		draw_circle(Vector2(x, BUS_Y), 4.0, Color(INK, 0.8))


func _read_head() -> void:
	var accent: Color = GOOD if _is_overflow(selected) else _entries[selected]["accent"]
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


func _info_overflow() -> void:
	draw_rect(PANEL_RECT, PANEL)
	draw_rect(PANEL_RECT, TRACE, false, 2.0)
	draw_rect(Rect2(PANEL_RECT.position, Vector2(6, PANEL_RECT.size.y)), GOOD if _overflow_on else DIM)
	var x := PANEL_RECT.position.x + 32.0
	_text_left("OVERFLOW", Vector2(x, 496), 48, GOOD if _overflow_on else DIM)
	if not _overflow_on:
		_text_left("LOCKED", Vector2(x, 540), 28, INK)
		_text_left("Set every bit to open the finale", Vector2(x, 578), 24, DIM)
		return
	_text_left("Every game, one run, no breaks", Vector2(x, 540), 28, INK)
	_text_left("8 seconds each   3 lives", Vector2(x, 578), 24, DIM)
	var best := 0 if _demo else Save.best("overflow")
	_text_left("BEST %d" % best if best > 0 else "NEW", Vector2(x, 630), 28, GOOD if best > 0 else DIM)
	var pr := _play_rect()
	draw_rect(pr, GOOD)
	_text("PLAY", pr.get_center(), 36, BG)


func _info() -> void:
	if _is_overflow(selected):
		_info_overflow()
		return
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
	if _bit_on(selected):
		var w := font.get_string_size(line, HORIZONTAL_ALIGNMENT_LEFT, -1, 28).x
		_text_left("CLEARED", Vector2(x + w + 32.0, 630), 28, GOOD)
	var pr := _play_rect()
	draw_rect(pr, accent)
	_text("PLAY", pr.get_center(), 36, BG)


func _footer() -> void:
	_text(Rules.footer_text(_touch), Vector2(640, 700), 22, DIM)


## Centred on `center` (both axes).
func _text(s: String, center: Vector2, size: int, color: Color) -> void:
	var base := center.y + (font.get_ascent(size) - font.get_descent(size)) * 0.5
	draw_string(font, Vector2(center.x - 640.0, base), s, HORIZONTAL_ALIGNMENT_CENTER, 1280, size, color)


func _text_left(s: String, pos: Vector2, size: int, color: Color) -> void:
	draw_string(font, pos, s, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)


## A digit centred on `center` by cap height, so scaled glow copies stay concentric.
func _digit(s: String, center: Vector2, size: int, color: Color) -> void:
	draw_string(font, Vector2(center.x - 640.0, center.y + 0.36 * size), s, HORIZONTAL_ALIGNMENT_CENTER, 1280, size, color)


## A glow copy of the 64 px digit: the same glyph scaled by `k` about the ink centre of the glyph (so it is
## concentric with the plain digit), under an optional outer transform `outer`.
func _glow(s: String, center: Vector2, k: float, color: Color, outer: Transform2D = Transform2D.IDENTITY) -> void:
	var pivot := center + ONE_INK
	var scale_about := Transform2D(0.0, Vector2(k, k), 0.0, pivot * (1.0 - k))
	draw_set_transform_matrix(outer * scale_about)
	_digit(s, center, 64, color)
	draw_set_transform_matrix(outer)
