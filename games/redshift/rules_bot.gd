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
	var sidestep := bullet_dodge(s)
	if tgt == null:
		return {"shift": 0, "aim_y": sidestep if sidestep >= 0.0 else R.SHIP_Y0}
	var aim := tgt.pos.y
	for e in s.enemies:
		if e != tgt and e.pos.x > R.SHIP_X and e.pos.x - R.SHIP_X < R.BOT_DODGE_X and absf(e.pos.y - aim) < R.BOT_DODGE_DY:
			aim = e.pos.y + R.BOT_DODGE_OFS if e.pos.y < R.SHIP_Y0 else e.pos.y - R.BOT_DODGE_OFS
	if sidestep >= 0.0:
		aim = sidestep
	return {"shift": signi(tgt.band - s.band), "aim_y": clampf(aim, R.SHIP_Y_MIN, R.SHIP_Y_MAX)}


## A y to move to when an enemy bullet will cross the ship's row soon, else -1.
static func bullet_dodge(s: R.Run) -> float:
	for b in s.bullets:
		if b.vel.x >= 0.0 or b.pos.x < R.SHIP_X:
			continue
		var tt := (b.pos.x - R.SHIP_X) / -b.vel.x
		if tt > R.BOT_BULLET_T:
			continue
		var py := b.pos.y + b.vel.y * tt
		if absf(py - s.ship_y) < R.BOT_BULLET_DY:
			return clampf(s.ship_y + (110.0 if py <= s.ship_y else -110.0), R.SHIP_Y_MIN, R.SHIP_Y_MAX)
	return -1.0


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
