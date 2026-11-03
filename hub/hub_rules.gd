extends RefCounted
## Pure hub logic (no nodes, no autoloads). Asserted by hub/selftest.gd.
##
##   const Rules := preload("res://hub/hub_rules.gd")
##   Rules.bits(["a", "b", "c"], {"b": true})            # "010"
##   Rules.count_set("010")                               # 1
##   Rules.overflow_unlocked(["a","b","c","d","e"], all)  # true when every bit set and n >= 5
##   Rules.cell_rects(8)                                  # 8 Rect2, 120x150, 16 px gap, centred on x 640

const CELL := Vector2(120, 150)
const GAP := 16.0
const TOP := 220.0
const CENTER_X := 640.0
const MIN_GAMES := 5

const DEMO_SENSES := ["SHAPE", "GEAR", "KEY", "BIT", "PHASE", "CARGO", "NIGHT", "RED"]
const DEMO_TITLES := ["Shapeshifter", "Gear Grind", "Upper Case", "Bit Catcher", "Phase Shift", "Cargo Shift", "Night Watch", "Red Shift"]
const DEMO_ACCENTS := ["ff5fa2", "ff9f1c", "3ddcff", "a3e635", "a78bfa", "2dd4bf", "8fa8ff", "ff7a45"]


## One char per slug, in order: "1" if cleared[slug] is true, else "0".
static func bits(slugs: Array, cleared: Dictionary) -> String:
	var s := ""
	for slug in slugs:
		s += "1" if bool(cleared.get(slug, false)) else "0"
	return s


static func count_set(bit_string: String) -> int:
	var n := 0
	for i in bit_string.length():
		if bit_string[i] == "1":
			n += 1
	return n


## True when every bit is set and there are at least `min_games` games.
static func overflow_unlocked(slugs: Array, cleared: Dictionary, min_games: int = MIN_GAMES) -> bool:
	var b := bits(slugs, cleared)
	return b.length() >= min_games and count_set(b) == b.length()


static func span(n: int) -> float:
	return n * CELL.x + maxf(0.0, n - 1.0) * GAP


## One centred row of cells.
static func cell_rects(n: int) -> Array[Rect2]:
	var out: Array[Rect2] = []
	var x0 := CENTER_X - span(n) * 0.5
	for i in n:
		out.append(Rect2(Vector2(x0 + i * (CELL.x + GAP), TOP), CELL))
	return out


## Index of the cell under pos, or -1.
static func cell_at(rects: Array[Rect2], pos: Vector2) -> int:
	for i in rects.size():
		if rects[i].has_point(pos):
			return i
	return -1


## Placeholder entries for Arcade's --hubdemo=<n>: every other one (index 1, 3, ...) is cleared.
static func demo_entries(n: int) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for i in clampi(n, 0, 8):
		out.append({
			"slug": "demo%d" % i, "title": DEMO_TITLES[i], "sense": DEMO_SENSES[i],
			"tagline": "Demo tagline for %s" % DEMO_TITLES[i], "controls": "LEFT / UP / RIGHT",
			"accent": Color.from_string("#" + String(DEMO_ACCENTS[i]), Color.WHITE),
			"cleared": i % 2 == 1, "best": 0 if i % 2 == 0 else 1200 + 340 * i,
		})
	return out
