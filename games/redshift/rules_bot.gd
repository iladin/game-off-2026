extends RefCounted
## Red Shift autoplay bot and headless round simulation. Pure: no nodes, no autoloads.

const R := preload("res://games/redshift/rules.gd")


static func target(s: R.Run) -> R.Enemy:
	var best: R.Enemy = null
	for e in s.enemies:
		if e.pos.x > R.SHIP_X + 30.0 and (best == null or e.pos.x < best.pos.x):
			best = e
	return best


static func bot_think(s: R.Run) -> Dictionary:
	var tgt := target(s)
	if tgt == null:
		return {"shift": 0, "aim_y": R.SHIP_Y0}
	var aim := tgt.pos.y
	for e in s.enemies:
		if e != tgt and e.pos.x > R.SHIP_X and e.pos.x - R.SHIP_X < R.BOT_DODGE_X and absf(e.pos.y - aim) < R.BOT_DODGE_DY:
			aim = e.pos.y + R.BOT_DODGE_OFS if e.pos.y < R.SHIP_Y0 else e.pos.y - R.BOT_DODGE_OFS
	return {"shift": signi(tgt.band - s.band), "aim_y": clampf(aim, R.SHIP_Y_MIN, R.SHIP_Y_MAX)}


static func sim_round(seed_value: int, difficulty: int, mode: String = "bot") -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var s := R.Run.new()
	var dt := 1.0 / 60.0
	var t := 0.0
	var think := 0.0
	var aim := R.SHIP_Y0
	var lives := R.LIVES
	var out := {"won": false, "time": 0.0, "crashes": 0, "first_crash": -1.0, "kills": 0, "escapes": 0, "shifts": 0, "score": 0}
	while t < R.ROUND_TIME - 1e-6:
		t += dt
		var r := R.ramp_time(t, difficulty)
		var move := 0.0
		if mode == "bot":
			think -= dt
			if think <= 0.0:
				think = R.BOT_THINK
				var d := bot_think(s)
				aim = d.aim_y
				if d.shift != 0 and R.shift(s, d.shift) != 0:
					out.shifts += 1
			move = R.follow_dir(aim, s.ship_y)
		var ev := R.step(s, dt, r, move, rng)
		for kd in s.kills:
			out.score += kd.pts
			out.kills += 1
		if ev & R.EV_ESCAPE:
			out.escapes += 1
		if ev & R.EV_CRASH:
			out.crashes += 1
			if out.first_crash < 0.0:
				out.first_crash = t
			if not R.is_grace(r):
				lives -= 1
				if lives <= 0:
					out.time = t
					return out
	out.time = t
	out.won = true
	out.score = R.final_score(out.score, lives)
	return out
