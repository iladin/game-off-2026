extends SceneTree
## Logic assertions for this game. check.sh runs:
##   godot --headless --path . --script res://games/<slug>/selftest.gd
## Must print SELFTEST OK. Test rules.gd only (autoloads aren't loaded here).

const Rules := preload("res://games/shapeshifter/rules.gd")


func _init() -> void:
	var fails: Array[String] = []
	if Rules.zone_width(0) != Rules.START_ZONE:
		fails.append("zone starts at START_ZONE")
	if Rules.zone_width(1000) != Rules.MIN_ZONE:
		fails.append("zone never shrinks below MIN_ZONE")
	if not Rules.is_hit(100.0, 100.0, 40.0) or Rules.is_hit(130.0, 100.0, 40.0):
		fails.append("is_hit uses half the width")
	if Rules.points(100.0, 100.0, 60.0) != 2 or Rules.points(125.0, 100.0, 60.0) != 1:
		fails.append("perfect hits score double")
	if Rules.marker_speed(10000) != Rules.MAX_SPEED:
		fails.append("speed is capped")
	for f in fails:
		printerr("SELFTEST FAIL: " + f)
	if fails.is_empty():
		print("SELFTEST OK")
	quit(1 if not fails.is_empty() else 0)
