extends SceneTree
## Run: $GODOT --headless --path . --script res://shared/ui_selftest.gd

const U := preload("res://shared/ui_rules.gd")


func _init() -> void:
	var a := U.hub_tap(true, 10.0, -1.0) # live, first tap: arm only
	assert(not a["go"] and a["armed_at"] == 10.0)
	var b := U.hub_tap(true, 11.4, a["armed_at"]) # second tap inside 1.5 s: go
	assert(b["go"] and b["armed_at"] == -1.0)
	var c := U.hub_tap(true, 11.6, a["armed_at"]) # too late: re-arm
	assert(not c["go"] and c["armed_at"] == 11.6)
	assert(U.hub_tap(false, 5.0, -1.0)["go"]) # result card / hub: one tap
	assert(U.hub_armed(10.5, 10.0) and not U.hub_armed(11.6, 10.0) and not U.hub_armed(1.0, -1.0))
	assert(U.HIT_HEIGHT >= 96.0)
	print("SELFTEST OK")
	quit()
