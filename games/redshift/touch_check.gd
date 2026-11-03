extends Node
## Run: godot --headless --path . res://games/redshift/touch_check.tscn
## Two-pointer check: finger 0 steers (drag), finger 1 taps BRAKE; band changes, steering stays.

const R := preload("res://games/redshift/rules.gd")
var fails: Array[String] = []


func _t(ok: bool, msg: String) -> void:
	if not ok:
		fails.append(msg)


func _touch(g: Node, idx: int, pressed: bool, pos: Vector2) -> void:
	var e := InputEventScreenTouch.new()
	e.index = idx
	e.pressed = pressed
	e.position = pos
	g._unhandled_input(e)


func _drag(g: Node, idx: int, pos: Vector2) -> void:
	var e := InputEventScreenDrag.new()
	e.index = idx
	e.position = pos
	g._unhandled_input(e)


func _mouse(g: Node, pressed: bool, pos: Vector2, emu: bool) -> void:
	var e := InputEventMouseButton.new()
	e.button_index = MOUSE_BUTTON_LEFT
	e.pressed = pressed
	e.position = pos
	if emu:
		e.device = InputEvent.DEVICE_ID_EMULATION
	g._unhandled_input(e)


func _ready() -> void:
	var g: Node = load("res://games/redshift/game.tscn").instantiate()
	g.autoplay = false
	add_child(g)
	g.begin()
	g.intro = 0.0
	var band0: int = g.run.band
	var steer_pos := Vector2(100, 200)
	_touch(g, 0, true, steer_pos)
	_t(g.ptr_down and g.ptr_y == 200.0, "touch 0 starts steering")
	_drag(g, 0, Vector2(100, 400))
	_t(g.ptr_y == 400.0, "drag 0 moves target")
	var pad := R.BRAKE_RECT.get_center()
	_touch(g, 1, true, pad)
	_t(g.run.band == band0 - 1, "touch 1 on BRAKE changes band (%d -> %d)" % [band0, g.run.band])
	_t(g.ptr_down and g.steer_id == 0, "touch 0 still steering after pad tap")
	_touch(g, 1, false, pad)
	_t(g.ptr_down, "pad release does not release steering")
	_drag(g, 1, Vector2(900, 50))
	_t(g.ptr_y == 400.0, "drag of finger 1 does not steer")
	_drag(g, 0, Vector2(100, 500))
	_t(g.ptr_y == 500.0, "ship keeps following touch 0")
	_mouse(g, true, R.BOOST_RECT.get_center(), true)  # emulated mouse from touch: ignored
	_t(g.run.band == band0 - 1, "emulated mouse ignored")
	_touch(g, 1, true, R.BOOST_RECT.get_center())
	_t(g.run.band == band0, "touch 1 on BOOST changes band back")
	_touch(g, 0, false, steer_pos)
	_t(not g.ptr_down, "touch 0 release stops steering")
	# desktop mouse still works
	_mouse(g, true, Vector2(100, 300), false)
	_t(g.ptr_down and g.ptr_y == 300.0, "mouse steers")
	_mouse(g, false, Vector2(100, 300), false)
	_t(not g.ptr_down, "mouse release")
	if fails.is_empty():
		print("TOUCH CHECK OK")
	else:
		for f in fails:
			print("TOUCH CHECK FAIL: ", f)
	get_tree().quit(0 if fails.is_empty() else 1)
