extends RefCounted
## Bit Catcher input: keys, mouse and (emulated) touch. Emits shifted(dir) and dropped().
## Pads act on press; taps in the play area act on release; a swipe down drops.

signal shifted(dir: int)
signal dropped

const R := preload("res://games/bitcatcher/rules.gd")
const SWIPE_PX := 48.0
const TAP_SLOP := 40.0
const LEFT_PAD := Rect2(170, 600, 300, 112)
const DROP_PAD := Rect2(490, 600, 300, 112)
const RIGHT_PAD := Rect2(810, 600, 300, 112)

var drop_key: bool = false
var drop_touch: bool = false
var press_pos: Vector2 = Vector2.ZERO
var press_zone: int = 0
var pressing: bool = false
var swiped: bool = false


func handle(event: InputEvent, in_intro: bool) -> void:
	if event is InputEventKey:
		var ke := event as InputEventKey
		if ke.echo or in_intro:
			return
		if ke.keycode == KEY_DOWN or ke.keycode == KEY_S:
			drop_key = ke.pressed
			if ke.pressed:
				dropped.emit()
		elif ke.pressed and (ke.keycode == KEY_LEFT or ke.keycode == KEY_A):
			shifted.emit(R.LEFT)
		elif ke.pressed and (ke.keycode == KEY_RIGHT or ke.keycode == KEY_D):
			shifted.emit(R.RIGHT)
	elif event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index != MOUSE_BUTTON_LEFT:
			return
		if mb.pressed:
			_press(mb.position, in_intro)
		else:
			_release(mb.position)
	elif event is InputEventMouseMotion and pressing and not swiped:
		var d: Vector2 = (event as InputEventMouseMotion).position - press_pos
		if d.y >= SWIPE_PX and d.y > absf(d.x):
			swiped = true
			drop_touch = true
			dropped.emit()


func _press(pos: Vector2, in_intro: bool) -> void:
	if in_intro:
		return
	if pos.y >= R.PAD_Y:
		if LEFT_PAD.has_point(pos):
			shifted.emit(R.LEFT)
		elif RIGHT_PAD.has_point(pos):
			shifted.emit(R.RIGHT)
		elif DROP_PAD.has_point(pos):
			drop_touch = true
			dropped.emit()
		return
	pressing = true
	swiped = false
	press_pos = pos
	press_zone = R.touch_zone(pos)


func _release(pos: Vector2) -> void:
	drop_touch = false
	if not pressing:
		return
	pressing = false
	if not swiped and pos.distance_to(press_pos) < TAP_SLOP:
		shifted.emit(press_zone)
	swiped = false
