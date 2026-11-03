extends RefCounted
## Pure OVERFLOW gauntlet bookkeeping (no nodes, no autoloads). Asserted by hub/selftest.gd.
## Arcade.start_gauntlet() drives it; the state is a plain Dictionary.
##
##   const G := preload("res://shared/gauntlet_rules.gd")
##   var s := G.new_state(8)                  # 8 games, 3 lives, game 0
##   s = G.tick(s, dt, current_score)         # 8 s survived: pass (+PASS_BONUS + score), next game
##   s = G.on_finish(s, score, won)           # finish(_, false) before 8 s: lose a life, next game
##   G.is_done(s); G.completed(s); G.total(s); G.status(s)

const SECONDS := 8.0
const LIVES := 3
const DIFFICULTY := 1
const PASS_BONUS := 0 ## per-game pass bonus on top of the game score (0: the total is the plain sum of game scores)


static func new_state(n_games: int, lives: int = LIVES) -> Dictionary:
	return {"n": n_games, "index": 0, "lives": lives, "elapsed": 0.0, "score": 0, "passed": 0, "done": n_games <= 0}


## Advance the clock; when SECONDS elapse the current game is passed with `game_score` added.
static func tick(s: Dictionary, dt: float, game_score: int = 0) -> Dictionary:
	if bool(s["done"]):
		return s
	s["elapsed"] = float(s["elapsed"]) + dt
	if float(s["elapsed"]) >= SECONDS:
		_pass(s, game_score)
	return s


## The game called finish(score, won). Before SECONDS: won passes, a loss costs a life. Either way move on.
static func on_finish(s: Dictionary, score: int, won: bool) -> Dictionary:
	if bool(s["done"]):
		return s
	if won:
		_pass(s, score)
	else:
		s["score"] = int(s["score"]) + score
		s["lives"] = int(s["lives"]) - 1
		_advance(s)
	return s


static func _pass(s: Dictionary, score: int) -> void:
	s["score"] = int(s["score"]) + score + PASS_BONUS
	s["passed"] = int(s["passed"]) + 1
	_advance(s)


static func _advance(s: Dictionary) -> void:
	s["index"] = int(s["index"]) + 1
	s["elapsed"] = 0.0
	if int(s["lives"]) <= 0 or int(s["index"]) >= int(s["n"]):
		s["done"] = true


static func is_done(s: Dictionary) -> bool:
	return bool(s["done"])


## True when the whole slot list was run with a life left.
static func completed(s: Dictionary) -> bool:
	return bool(s["done"]) and int(s["lives"]) > 0


static func total(s: Dictionary) -> int:
	return int(s["score"])


static func time_left(s: Dictionary) -> float:
	return maxf(0.0, SECONDS - float(s["elapsed"]))


## HUD text, words only: "GAME 3 OF 8   5.2" (lives are drawn as squares by Arcade).
static func status(s: Dictionary) -> String:
	return "GAME %d OF %d   %.1f" % [mini(int(s["index"]) + 1, int(s["n"])), int(s["n"]), time_left(s)]


const CARD_MAX_W := 1100.0 ## widest the interstitial card word may be drawn
const CARD_MIN_SIZE := 28


## Card word for a game.json dict: `sense`, else `title`, else "?" (upper case). G.card_word({"title": "Tilt"}) == "TILT"
static func card_word(info: Dictionary) -> String:
	for k in ["sense", "title"]:
		var w := String(info.get(k, "")).strip_edges()
		if w != "":
			return w.to_upper()
	return "?"


## Largest font size <= base whose `word` fits `max_w` px (never below CARD_MIN_SIZE). G.fit_size(font, "CARGO", 96)
static func fit_size(font: Font, word: String, base: int, max_w: float = CARD_MAX_W) -> int:
	var sz := base
	while sz > CARD_MIN_SIZE and font.get_string_size(word, HORIZONTAL_ALIGNMENT_LEFT, -1, sz).x > max_w:
		sz -= 2
	return maxi(sz, mini(CARD_MIN_SIZE, base))
