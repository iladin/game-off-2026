extends RefCounted
## Scene drawing and input mapping for Upper Case (g = the game node).

const Rules := preload("res://games/uppercase/rules.gd")
const KD := preload("res://games/uppercase/keys_draw.gd")


static func side_from_event(event: InputEvent) -> int:
	if event is InputEventKey:
		var k := event as InputEventKey
		if not k.pressed or k.echo:
			return -1
		if k.keycode == KEY_SHIFT or k.physical_keycode == KEY_SHIFT:
			if k.location == KEY_LOCATION_LEFT:
				return Rules.LEFT
			if k.location == KEY_LOCATION_RIGHT:
				return Rules.RIGHT
		elif k.keycode == KEY_F:
			return Rules.LEFT
		elif k.keycode == KEY_J:
			return Rules.RIGHT
	elif event is InputEventMouseButton:
		var m := event as InputEventMouseButton
		if m.pressed and m.button_index == MOUSE_BUTTON_LEFT:
			return Rules.side_for_tap_x(m.position.x)
	return -1


static func draw(g) -> void:
	KD.draw_backdrop(g, g.columns_x)
	KD.draw_line_zone(g, g.beat - floor(g.beat))
	var nxt = g._nearest(false, false)
	for tl in g.tiles:
		var a := clampf(tl.age / g.FADE_IN, 0.0, 1.0)
		var tint := Color(0, 0, 0, 0)
		var sq := 1.0
		if tl.fx == 1:
			tint = g.GOOD
			sq = lerpf(1.0, g.SQUASH, 1.0 - clampf(tl.fx_t / g.SQUASH_TIME, 0.0, 1.0))
		elif tl.fx == 2:
			tint = g.BAD
		KD.draw_tile(g, Vector2(tl.x, tl.y), tl.ch, tl.upper, a, tint, sq)
	KD.draw_below_fall(g)
	var lit := ""
	var lit_up := true
	if nxt != null:
		lit = nxt.ch
		lit_up = nxt.upper
	KD.draw_strip(g, lit, lit_up, g.strip_flash_ch, g.strip_flash_t / g.STRIP_FLASH_TIME * 0.6)
	var hint_side := -1
	if Rules.hints_on(g.r) and nxt != null and nxt.upper:
		hint_side = Rules.correct_shift(nxt.ch)
	for s in 2:
		var rect: Rect2 = g.LEFT_KEY if s == Rules.LEFT else g.RIGHT_KEY
		var flash := false
		if g.hint_flash_t > 0.0 and g.hint_flash_side == s:
			flash = fmod((g.HINT_FLASH_TIME - g.hint_flash_t) / g.HINT_FLASH_TIME * 2.0, 1.0) < 0.6
		KD.draw_shift_key(g, rect, s, g.key_down_t[s] > 0.0, hint_side == s and not flash, g.key_bad_t[s] > 0.0, flash, g.clock)
	var ba := clampf(g.banner_t / 0.3, 0.0, 1.0)
	var lost: int = g.lives if g.lives < g.LIVES else -1
	KD.draw_hud(g, g.score, g.lives, g.LIVES, g.life_flash_t, lost, g.t / Rules.SPAWN_END, g.banner_text, ba, 1.0 + 0.1 * (g.score_squash_t / 0.12))
