extends MicroGame
## TEMPLATE game ("Zone"): a marker shifts back and forth along a bar; press while
## it's inside the green zone. Hits shrink the zone and speed the marker up.
## 3 misses = game over; 15 hits = clear. It exists to show the MicroGame contract:
## begin() / finish(score, won), autoplay bot, Synth, Juice, rules.gd + selftest.
## Replace the gameplay when you build a real game; keep the structure.

const Rules := preload("res://games/cargoshift/rules.gd")

# --- Tunables -------------------------------------------------------------------
const BG := Color("101018")
const BAR := Color("2a2a3a")
const ZONE := Color("4ade80")
const MARKER := Color("f8fafc")
const DANGER := Color("f43f5e")
const BAR_RECT := Rect2(160, 330, 960, 60)
const MAX_MISSES := 3
const HITS_TO_CLEAR := 15
const INTRO_TIME := 0.8

var hits: int = 0
var misses: int = 0
var score: int = 0
var marker_x: float = 0.0
var direction: float = 1.0
var zone_center: float = 640.0
var intro: float = 0.0
var bot_cooldown: float = 0.0
var font: Font = ThemeDB.fallback_font


func begin() -> void:
	hits = 0
	misses = 0
	score = 0
	marker_x = BAR_RECT.position.x
	direction = 1.0
	intro = INTRO_TIME
	_place_zone()
	Synth.loop([60, 0, 67, 0, 64, 0, 67, 72], 128.0)


func _place_zone() -> void:
	var w := Rules.zone_width(hits)
	zone_center = randf_range(BAR_RECT.position.x + w * 0.5, BAR_RECT.end.x - w * 0.5)


func _process(delta: float) -> void:
	queue_redraw()
	if is_finished():
		return
	if intro > 0.0:
		intro -= delta
		return
	marker_x += direction * Rules.marker_speed(hits) * delta
	if marker_x > BAR_RECT.end.x or marker_x < BAR_RECT.position.x:
		direction = -direction
		marker_x = clampf(marker_x, BAR_RECT.position.x, BAR_RECT.end.x)
	if autoplay:
		_bot(delta)


func _bot(delta: float) -> void:
	# A decent but imperfect player: presses when close to the zone centre.
	bot_cooldown -= delta
	if bot_cooldown <= 0.0 and absf(marker_x - zone_center) < Rules.zone_width(hits) * randf_range(0.2, 0.7):
		bot_cooldown = 0.25
		_press()


func _unhandled_input(event: InputEvent) -> void:
	if autoplay or is_finished() or intro > 0.0:
		return
	var key := event.is_action_pressed("ui_accept")
	var tap: bool = event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT
	if key or tap:
		_press()


func _press() -> void:
	var w := Rules.zone_width(hits)
	var p := Rules.points(marker_x, zone_center, w)
	var at := Vector2(marker_x, BAR_RECT.get_center().y)
	if p > 0:
		hits += 1
		score += p
		Synth.sfx("coin", 1.0 + 0.04 * hits)
		Juice.burst(self, at, ZONE)
		Juice.popup(self, at - Vector2(0, 40), "PERFECT +2" if p == 2 else "+1", ZONE)
		if hits >= HITS_TO_CLEAR:
			finish(score, true)
			return
		_place_zone()
	else:
		misses += 1
		Synth.sfx("miss")
		Juice.shake(10.0)
		Juice.flash(Color(DANGER, 0.3))
		if misses >= MAX_MISSES:
			finish(score, false)


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, view_size()), BG)
	draw_rect(BAR_RECT, BAR)
	var w := Rules.zone_width(hits)
	draw_rect(Rect2(zone_center - w * 0.5, BAR_RECT.position.y, w, BAR_RECT.size.y), ZONE.darkened(0.3))
	draw_rect(Rect2(zone_center - w / 6.0, BAR_RECT.position.y, w / 3.0, BAR_RECT.size.y), ZONE)
	draw_rect(Rect2(marker_x - 4, BAR_RECT.position.y - 20, 8, BAR_RECT.size.y + 40), MARKER)
	draw_string(font, Vector2(0, 150), "%d" % score, HORIZONTAL_ALIGNMENT_CENTER, 1280, 72, MARKER)
	for i in MAX_MISSES: # lives: filled = left, ring = lost (draw shapes; the web font has no symbols)
		var c := Vector2(640 + (i - 1) * 36, 200)
		if i >= misses:
			draw_circle(c, 11, DANGER)
		else:
			draw_arc(c, 11, 0, TAU, 24, DANGER, 2.0)
	draw_string(font, Vector2(0, 520), "Space / tap when the marker is in the green", HORIZONTAL_ALIGNMENT_CENTER, 1280, 28, MARKER.darkened(0.4))
	if intro > 0.0:
		draw_string(font, Vector2(0, 460), "READY", HORIZONTAL_ALIGNMENT_CENTER, 1280, 56, ZONE)
