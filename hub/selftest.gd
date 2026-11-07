extends SceneTree
## Run: $GODOT --headless --path . --script res://hub/selftest.gd

const Rules := preload("res://hub/hub_rules.gd")
const G := preload("res://shared/gauntlet_rules.gd")


func _init() -> void:
	assert(G.card_midi(0) == 57 and G.card_midi(1) == 60 and G.card_midi(4) == 67 and G.card_midi(5) == 69)
	assert(G.card_midi(0) != G.card_midi(4))
	for i in 12:
		assert(G.card_midi(i + 1) > G.card_midi(i))
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
	var r9 := Rules.cell_rects(9)
	assert(r9[0].position.x >= 16.0 and r9[8].end.x <= 1264.0)
	assert(Rules.footer_text(true) == "TAP A BIT   TAP PLAY" and Rules.footer_text(false).contains("ENTER"))
	assert(Rules.span(1) > 0.0)
	assert(not Rules.attract_due(7.9, 8.0, 5) and Rules.attract_due(8.0, 8.0, 5) and not Rules.attract_due(99.0, 8.0, 1))
	assert(Rules.attract_selected(2, 3, 8) == 5 and Rules.attract_selected(6, 4, 8) == 2 and Rules.attract_selected(0, 0, 0) == 0)
	for sh in 12:
		var seen_slots := {}
		for ci in 9:
			seen_slots[Rules.shift_slot(ci, sh, 9)] = true
		assert(seen_slots.size() == 9) # a permutation: every slot filled once
		assert(Rules.shift_slot(Rules.attract_selected(3, sh, 9), sh, 9) == 3) # the same slot stays under the head
	var r9b := Rules.cell_rects(9)
	assert(is_equal_approx(Rules.shift_dx(r9b, 4, 1, 0.0), 0.0) and is_equal_approx(Rules.shift_dx(r9b, 4, 1, 1.0), -(120.0 + 16.0)))
	assert(is_equal_approx(Rules.shift_dx(r9b, 4, 1, 0.5), -68.0))
	assert(is_equal_approx(Rules.shift_dx(r9b, 0, 1, 0.1), r9b[8].position.x - r9b[0].position.x)) # wrapper snaps to the far end
	var g := G.new_state(3)
	assert(g["lives"] == 3 and g["index"] == 0 and not G.is_done(g))
	G.tick(g, 7.9, 50)
	assert(g["index"] == 0 and absf(G.time_left(g) - 0.1) < 0.001)
	G.tick(g, 0.2, 50) # 8 s survived: pass
	assert(g["index"] == 1 and g["passed"] == 1 and G.total(g) == 50 + G.PASS_BONUS and G.PASS_BONUS == 0 and g["elapsed"] == 0.0)
	G.on_finish(g, 30, false) # early loss: life gone, next game
	assert(g["lives"] == 2 and g["index"] == 2 and G.total(g) == 80 and not G.is_done(g))
	G.on_finish(g, 10, true) # early win counts as a pass; last game done
	assert(G.is_done(g) and G.completed(g) and g["passed"] == 2 and G.total(g) == 90)
	G.tick(g, 100.0, 999) # nothing changes once done
	assert(G.total(g) == 90)
	var h := G.new_state(8)
	for i in 3:
		G.on_finish(h, 0, false)
	assert(G.is_done(h) and not G.completed(h) and h["index"] == 3 and h["lives"] == 0)
	assert(G.is_done(G.new_state(0)))
	assert(G.status(G.new_state(8)) == "GAME 1 OF 8   8.0")
	assert(G.card_word({"sense": "key", "title": "Keys"}) == "KEY" and G.card_word({"title": "Tilt"}) == "TILT")
	assert(G.card_word({"sense": "  ", "title": "Tilt"}) == "TILT" and G.card_word({}) == "?")
	var f: Font = ThemeDB.fallback_font
	for w in ["CARGO", "A", "WWWWWWWWWWWWWWWWWWWWWWWW", "SUPERCALIFRAGILISTICEXPIALIDOCIOUS"]:
		var fz := G.fit_size(f, w, 96)
		assert(fz >= G.CARD_MIN_SIZE and fz <= 96)
		assert(fz == G.CARD_MIN_SIZE or f.get_string_size(w, HORIZONTAL_ALIGNMENT_LEFT, -1, fz).x <= G.CARD_MAX_W)
	print("SELFTEST OK")
	quit()
