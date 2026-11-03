extends SceneTree
## Run: $GODOT --headless --path . --script res://hub/selftest.gd

const Rules := preload("res://hub/hub_rules.gd")


func _init() -> void:
	assert(Rules.bits(["a", "b", "c"], {"b": true}) == "010")
	assert(Rules.bits([], {}) == "")
	assert(Rules.count_set("10110") == 3)
	assert(Rules.count_set("") == 0)
	var four := ["a", "b", "c", "d"]
	var five := ["a", "b", "c", "d", "e"]
	var all4 := {"a": true, "b": true, "c": true, "d": true}
	var all5 := {"a": true, "b": true, "c": true, "d": true, "e": true}
	assert(not Rules.overflow_unlocked(four, all4))
	assert(Rules.overflow_unlocked(five, all5))
	assert(not Rules.overflow_unlocked(five, all4))
	assert(not Rules.overflow_unlocked([], {}))
	var nc := Rules.newly_cleared(five, {"b": true, "d": true, "e": false}, ["d"])
	assert(nc == ["b"])
	assert(Rules.newly_cleared(five, {"b": true}, ["b"]).is_empty())
	assert(Rules.newly_cleared(five, {}, []).is_empty())
	assert(Rules.newly_cleared(five, {"a": true, "c": true}, []) == ["a", "c"])
	assert(Rules.newly_cleared(["a"], {"zz": true}, []).is_empty())
	assert(Rules.merge_seen(["d"], ["b", "d"]) == ["d", "b"])
	var r := Rules.cell_rects(8)
	assert(r.size() == 8)
	for c in r:
		assert(c.size == Vector2(120, 150))
		assert(c.position.y == 220.0)
	for i in 7:
		assert(r[i + 1].position.x - r[i].end.x == 16.0)
	assert(r[7].end.x - r[0].position.x == 1072.0)
	assert((r[0].position.x + r[7].end.x) * 0.5 == 640.0)
	assert(Rules.cell_at(r, r[3].get_center()) == 3)
	assert(Rules.cell_at(r, Vector2(5, 5)) == -1)
	assert(Rules.demo_entries(8).size() == 8)
	print("SELFTEST OK")
	quit()
