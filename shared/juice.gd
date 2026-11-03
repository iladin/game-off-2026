extends CanvasLayer
## Juice (autoload): shared game feel, so every game reacts the same way.
##
##   Juice.shake(12.0)                          # screen shake (pixels), decays
##   Juice.flash(Color(1, 1, 1, 0.5))            # full-screen flash, fades out
##   Juice.hitstop(0.06)                        # freeze time briefly on big hits
##   Juice.burst(self, pos, Color.GOLD)         # particle burst at pos (world coords of `parent`)
##   Juice.popup(self, pos, "+100", Color.WHITE) # floating text that rises and fades
##
## Shake moves the viewport's canvas transform (layer 0), so HUDs on their own
## CanvasLayer stay still. If a game uses a Camera2D, set Juice.camera to it and
## shake moves camera.offset instead. Arcade calls reset() between games.

const SHAKE_DECAY := 40.0 # pixels per second
const MAX_SHAKE := 40.0

var camera: Camera2D = null

var _shake: float = 0.0
var _flash_rect: ColorRect
var _font: Font = ThemeDB.fallback_font


func _ready() -> void:
	layer = 90
	process_mode = Node.PROCESS_MODE_ALWAYS
	_flash_rect = ColorRect.new()
	_flash_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_flash_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_flash_rect.color = Color(1, 1, 1, 0)
	add_child(_flash_rect)


func reset() -> void:
	_shake = 0.0
	camera = null
	Engine.time_scale = 1.0
	_flash_rect.color.a = 0.0
	_apply_offset(Vector2.ZERO)


func shake(amount: float) -> void:
	_shake = minf(MAX_SHAKE, maxf(_shake, amount))


func flash(color: Color = Color(1, 1, 1, 0.45), duration: float = 0.15) -> void:
	_flash_rect.color = color
	var t := create_tween()
	t.tween_property(_flash_rect, "color:a", 0.0, duration)


func hitstop(duration: float = 0.05) -> void:
	Engine.time_scale = 0.05
	await get_tree().create_timer(duration, true, false, true).timeout
	Engine.time_scale = 1.0


func burst(parent: Node, pos: Vector2, color: Color, amount: int = 14, speed: float = 260.0) -> void:
	if parent == null or not parent.is_inside_tree():
		return
	var p := CPUParticles2D.new()
	p.position = pos
	p.one_shot = true
	p.emitting = false
	p.amount = amount
	p.lifetime = 0.6
	p.explosiveness = 1.0
	p.direction = Vector2.UP
	p.spread = 180.0
	p.initial_velocity_min = speed * 0.5
	p.initial_velocity_max = speed
	p.gravity = Vector2(0, 500)
	p.scale_amount_min = 3.0
	p.scale_amount_max = 6.0
	p.color = color
	parent.add_child(p)
	p.emitting = true
	p.finished.connect(p.queue_free)


func popup(parent: Node, pos: Vector2, text: String, color: Color = Color.WHITE, size: int = 32) -> void:
	if parent == null or not parent.is_inside_tree():
		return
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	label.add_theme_constant_override("outline_size", 6)
	label.position = pos - Vector2(60, size)
	label.custom_minimum_size = Vector2(120, 0)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(label)
	var t := label.create_tween().set_parallel(true)
	t.tween_property(label, "position:y", label.position.y - 70.0, 0.7).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	t.tween_property(label, "modulate:a", 0.0, 0.7).set_delay(0.25)
	t.chain().tween_callback(label.queue_free)


func _process(delta: float) -> void:
	if _shake <= 0.0:
		return
	_shake = maxf(0.0, _shake - SHAKE_DECAY * delta / maxf(Engine.time_scale, 0.05))
	var off := Vector2(randf_range(-_shake, _shake), randf_range(-_shake, _shake))
	_apply_offset(off if _shake > 0.0 else Vector2.ZERO)


func _apply_offset(off: Vector2) -> void:
	if camera != null and is_instance_valid(camera):
		camera.offset = off
	else:
		get_viewport().canvas_transform = Transform2D(0.0, off)
