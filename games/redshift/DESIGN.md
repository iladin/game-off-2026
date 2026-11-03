# Red Shift

<!-- Written by the Game Designer before any code. The Gameplay Engineer builds exactly this. -->
<!-- R0009, slate slot 8, sense RED. Accent #FF7A45 (ember). Hue bands #FF7A45 / #A3E635 / #3D7BFF. Budget: about 25 min, under ~850 lines of GDScript. -->
<!-- The core numbers were run through a 60 Hz Python model of exactly this Rules.step (20 seeds x difficulty 0 and 1, see "Simulated balance"). -->
<!-- SCOPE GUARD (VISION calls this the most complex build): no scrolling world, no level data, no physics. The ship has a fixed x; enemies fly in straight lines from the right; the only "world" is a parallax star field and a TRACE grid. -->

## Pitch
A small ship flies right through deep space. Enemies stream in from the right in three hues: ember, lime and blue. Your guns fire on their own, but **a shot only hurts an enemy of your own hue**, and your hue is your speed: **brake** and you redshift to ember, **cruise** and you are lime, **boost** and you blueshift to blue. Change speed to match the enemy in front of you, steer up and down to line it up or dodge the ones you cannot hurt, and survive a 50-second run to set the RED bit.

## How it uses SHIFT
SHIFT = **redshift / blueshift**, the Doppler effect: the faster you close in, the bluer you look; the slower, the redder. The one verb is a speed change (BRAKE or BOOST, one band per press). Every band change plays `Synth.sfx("shift", Rules.shift_pitch(streak))`, restarts the music loop transposed (down for red, up for blue), stretches or shortens the star streaks, and recolours the ship and its shots in the same frame. Speed is also risk: boosting makes everything come at you faster (enemy closing speed x1.3), braking slows the world down (x0.75), so blue enemies are always the hardest to deal with.

## Core loop
Every 1-3 s:
1. Look at the nearest enemy on the right. Its shape and colour tell you its band (ember square, lime triangle, blue circle).
2. **Shift** to its band: BRAKE (toward ember) or BOOST (toward blue). The ship turns that colour; matching enemies glow (while hints are on).
3. Steer up or down into its row; your auto-fire stream destroys it (`+N`, burst, coin).
4. Anything you cannot hurt (wrong hue, or a heavy you will not finish in time) you dodge by steering out of its row. A collision costs a life.

The decision: which enemy to match next and whether to commit (shift and line up) or dodge. Shots of the wrong hue are blocked by an enemy, so a wrong-hue enemy in front shields the one behind it.

## Controls (keyboard AND touch)
| Action | Keyboard | Touch / mouse |
|---|---|---|
| Move up / down | hold Up or W / Down or S | press and drag anywhere in the left two thirds (`x < MOVE_ZONE_X = 853`): the ship moves toward the finger's y at the same `MOVE_SPEED` (no speed advantage) |
| Brake (one band toward ember) | Left or A (press) | tap `BRAKE_RECT = Rect2(870, 598, 190, 110)` |
| Boost (one band toward blue) | Right or D (press) | tap `BOOST_RECT = Rect2(1074, 598, 190, 110)` |
| Fire | automatic | automatic |

- Movement keys are **polled** each frame: `Input.is_physical_key_pressed(KEY_UP)` or `KEY_W` gives -1, `KEY_DOWN` or `KEY_S` gives +1, both or neither 0.
- Brake / boost keys: `InputEventKey` `pressed and not echo`, by `physical_keycode`, in `_unhandled_input`. Pointer: `InputEventMouseButton` (MOUSE_BUTTON_LEFT) and `InputEventMouseMotion` in `_unhandled_input` (so Arcade's HUB / SOUND buttons get their clicks first). `emulate_mouse_from_touch=true`: do NOT also handle `InputEventScreenTouch` / `InputEventScreenDrag`.
- `Rules.tap_target(pos) -> int`: `TAP_BRAKE = 0` in `BRAKE_RECT`, `TAP_BOOST = 1` in `BOOST_RECT`, `TAP_MOVE = 2` if `pos.x < MOVE_ZONE_X` and `pos.y >= 70` (keeps the HUB corner clear), else -1. On press: brake / boost calls `_shift(-1)` / `_shift(+1)`; move sets `ptr_down = true, ptr_y = pos.y`. Motion while down updates `ptr_y`; release clears it.
- Pointer move dir: `Rules.follow_dir(ptr_y, ship_y) = 0 if abs(dy) < FOLLOW_DEAD 6 else sign(dy)`. Final `move`: keys if nonzero, else pointer if down, else 0.
- `_shift(dir)` is the only place a band changes (keys, pads and the bot all call it). Shifting past an end (brake while ember, boost while blue) does nothing except blink that pad DIM 0.12 s (no sound).
- Ignore input when `autoplay`, `is_finished()`, or during the 0.6 s intro. Never Esc, P or M.

## Round: fail / win, score
- **Win (sets the RED bit):** survive to `t >= ROUND_TIME = 50.0` s. `finish(Rules.final_score(score, lives), true)` that frame. Every surviving round is 50.6 s with the intro, at any difficulty.
- **Lives:** 3, ember squares at top centre.
- **Hard fail = crash:** an enemy's circle overlaps the ship's (`distance < enemy.radius + SHIP_R 22`) while `invuln <= 0`. The enemy is destroyed (no points), `streak = 0`, `invuln = INVULN 1.0` s (ship blinks at 10 Hz). **Grace:** while `r < GRACE_END = 10` a crash costs no life (soft-fail feedback, popup `DODGE` in INK, since DIM is too dark on the popup outline).
- **Lose:** lives reach 0: `finish(score, false)` in the same frame as the hard-fail effects; return; `finish()` exactly once.
- **Score:**
  - **Kill** (enemy hp reaches 0): `Rules.kill_points(streak, heavy) = (KILL_PTS 10 + STREAK_PTS 2 * min(streak, STREAK_CAP 10)) * (HEAVY_MULT 3 if heavy else 1)`, then `streak += 1`.
  - **Escape** (an enemy passes `x < ESCAPE_X = -40`): no points lost, `streak = 0`.
  - **Win:** `+LIFE_BONUS = 100` per life left.
  - Model: the bot scores 1,570-2,050 at difficulty 0 (2,350-3,010 at 1).
- **Typical length:** 50.6 s. An idle player loses by t 37-43.

## Ramp (with numbers)
Round time `t` counts from the loop start. Ramp time `r = Rules.ramp_time(t, difficulty) = t + (DIFFICULTY_OFFSET 30.0 if difficulty >= 1 else 0.0)`. Everything reads `r`; nothing else reads `difficulty`.

| r (s) | New thing | Enemy speed `enemy_speed(r)` px/s (at x1.0) | Spawn gap `spawn_gap(r)` s | Bands that spawn `spawn_bands(r)` | Banner `phase_name(r)` | Hints |
|---|---|---|---|---|---|---|
| 0-10 | lime only (you start lime, so just steer) | 150 to 185 | 1.60 to 1.40 | [1] | `""` | on |
| 10-20 | **ember** enemies: brake to hit them | 185 to 220 | 1.40 to 1.20 | [0, 1] | `RED` | on |
| 20-30 | **blue** enemies: boost (and everything comes faster) | 220 to 255 | 1.20 to 1.00 | [0, 1, 2] | `BLUE` | on |
| 30+ | **heavies** (25%): 3 hp, bigger, x0.8 speed, x3 points; no hints | 255 to 260 (clamp at r 31.4) | 1.00 to 0.85 (clamp at r 37.5) | [0, 1, 2] | `HEAVY` | off |

- `enemy_speed(r) = min(SPEED_MAX 260, SPEED_START 150 + SPEED_RAMP 3.5 * r)`. An enemy moves left by `enemy_speed(r) * s.k * (HEAVY_SLOW 0.8 if heavy else 1.0) * dt`, where `s.k` is the ship's eased speed factor (below). From spawn to the ship (1080 px) takes 7.2 s at the start, 4.2 s at r 30 lime, 3.2 s when boosting blue.
- `spawn_gap(r) = max(GAP_MIN 0.85, GAP_START 1.6 - GAP_RAMP 0.02 * r)`. First spawn at `t = FIRST_SPAWN 0.5`. Spawn: `x = SPAWN_X 1320`, `y = rng.randf_range(ENEMY_Y_MIN 130, ENEMY_Y_MAX 550)`, `band = spawn_bands(r)[rng.randi() % n]`, `heavy = r >= HEAVY_AT 30 and rng.randf() < HEAVY_CHANCE 0.25`.
- `SPEED_MUL = [0.75, 1.0, 1.3]` (ember, lime, blue). `s.k` eases toward `SPEED_MUL[band]`: `k += (target - k) * min(1, K_EASE 4.0 * dt)` (about 0.5 s to settle; the star field shows it).
- **Formations (T-0032, in `game.gd` `_form_up()`, not in `rules.gd`):** each spawn event (detected as `spawn_t - dt <= 0` before `step`; the new enemy is the one not in the pre-step list; if it was shot the very frame it appeared, no formation that event) of `Rules.step` is turned into `FORM_SIZE 3` enemies of ONE hue, `FORM_DY 70` px apart: either a **V** (leader in front at `SPAWN_X`, two wingmen `FORM_DX 60` px behind it at y -70 / +70) or a **vertical line** (same x, y -70 / 0 / +70); 50/50 by `rng`. The leader's y is clamped to `ENEMY_Y_MIN + 74 .. ENEMY_Y_MAX - 74` so the whole formation fits the playfield. The leader keeps the `Rules` roll for `heavy` (25% from r 30); wingmen are never heavy (1 hp), so a heavy leads two normal enemies. Hue: lime only before `RED_AT`; from then on each formation's hue **differs from the previous formation's** (random among the other unlocked bands), so hues mix across consecutive formations. After a formation, `run.spawn_t = spawn_gap(r) * FORM_GAP_MUL 1.6` (GAP_START stays 1.6; formations come every about 2.6 s at r 0, 1.4 s at the clamp), about 1.2 enemies per second on screen-time versus 0.6 before; the first 10 s has no more than 3 lime in a row.
- `hints_on(r)`: `r < HINTS_END 30`. `is_grace(r)`: `r < GRACE_END 10`. Banners show when `phase_name(r)` differs from the last shown (start `""`), so difficulty 1 shows `HEAVY` at once.

### Simulated balance (Python model of this exact step, dt 1/60, seeds 1-20)
| Player | d 0: wins / crashes | d 1: wins / crashes | notes |
|---|---|---|---|
| Bot (below), thinks every 0.1 s | 20 / 0 | 20 / 0 | 42-55 kills, 0 escapes, 24-38 shifts per round |
| Human model: bot thinking 0.3 s | 20 / 1 | 20 / 2 | |
| Human model: bot thinking 0.5 s | 20 / 6 | 16 / 23 | a slow player loses lives in the heavy phase |
| Moves and lines up but never shifts | 0 / 60 | 0 / 60 | dies by t 29 (d 0): shifting is required |
| Idle | 0 / 60 | 0 / 60 | first crash t 6.9 (in grace), dead by t 37-43 |
A first, earlier draft (speed to 320, gap to 0.55) let even the 0.1 s bot lose 8 of 40 rounds; the clamps above are the fix. Godot's RNG differs from Python's, so the selftest bounds below have slack.

## The step (`Rules.step`, pure, shared by the game, the bot and the selftest)
Inner classes (`extends RefCounted`):
- `Enemy`: `pos: Vector2`, `band: int`, `hp: int`, `heavy: bool`, `radius: float` (`ENEMY_R 26`, `HEAVY_R 36`).
- `Shot`: `pos: Vector2`, `band: int`.
- `Run`: `ship_y: float = SHIP_Y0 340`, `band: int = START_BAND 1`, `k: float = 1.0`, `enemies: Array[Enemy]`, `shots: Array[Shot]`, `fire_t: float = 0`, `spawn_t: float = FIRST_SPAWN`, `invuln: float = 0`, `streak: int = 0`, and per-frame outputs `kills: Array[Dictionary]` (`{pos, band, heavy, pts}`), `crash_pos: Vector2`, `blocked: Array[Vector2]`.

`shift(s, dir) -> int`: `nb = clampi(s.band + dir, 0, 2)`; if `nb == s.band` return 0; `s.band = nb`; return `EV_SHIFT (1)`.
`step(s, dt, r, move, rng, grace) -> int`, in this order (clears the output arrays first):
1. Timers: `invuln` down to 0. Ease `k`.
2. Ship: `ship_y = clamp(ship_y + move * MOVE_SPEED 420 * dt, SHIP_Y_MIN 110, SHIP_Y_MAX 570)`. Ship x is the constant `SHIP_X = 240`.
3. Spawn: `spawn_t -= dt`; when `<= 0`: spawn one enemy (Ramp), `spawn_t = spawn_gap(r)`.
4. Fire: `fire_t -= dt`; when `<= 0`: `fire_t = FIRE_GAP 0.16`; append `Shot(Vector2(SHIP_X + 30, ship_y), band)`.
5. Move: shots `x += SHOT_SPEED 900 * dt`; enemies as in Ramp.
6. Shots vs enemies: for each shot, the first enemy with `abs(dx) < radius and abs(dy) < radius`: remove the shot; same band: `hp -= 1` (ev |= `EV_DAMAGE (4)` if hp is still > 0); other band: append the shot pos to `blocked`, ev |= `EV_BLOCK (32)`. Remove shots past x 1320.
7. Kills: each enemy with `hp <= 0`: append to `kills` with `kill_points(streak, heavy)`, `streak += 1`, remove; ev |= `EV_KILL (2)`.
8. Crash / escape: an enemy within `radius + SHIP_R` of `(SHIP_X, ship_y)` while `invuln <= 0`: remove it, `streak = 0`, `invuln = INVULN`, `crash_pos`, ev |= `EV_CRASH (8)` (at most one per frame). An enemy with `x < ESCAPE_X`: remove, `streak = 0`, ev |= `EV_ESCAPE (16)`.
The game owns lives (grace vs life) and the score total (sum of `kills[i].pts`).

## Look (palette hex + how each thing is drawn, per studio/VISION.md)
Colours: BG `#0B0E14`, PANEL `#151A24`, TRACE `#1E2738`, DIM `#6B7489`, INK `#E8ECF4`, GOOD `#FFD34D`, BAD `#FF3B5C`; accent EMBER `#FF7A45`; hue bands `BAND_COL = [#FF7A45, #A3E635, #3D7BFF]` (band 0 ember, 1 lime, 2 blue). Nothing else (tints = alpha only).

Screen map (1280 x 720):
| Region | Rect | Content |
|---|---|---|
| Corners (keep clear) | x 0-150 and x 1100-1280, y 0-70 | Arcade HUB / SOUND |
| HUD | x 170-1090, y 0-90 | hue meter (left), score + lives (centre), timer bar (right) |
| Playfield | x 0-1280, y 90-590 | stars, grid, ship (x 240, y 110-570), enemies (y 130-550) |
| Pads | `BRAKE_RECT` (870, 598) 190 x 110, `BOOST_RECT` (1074, 598) 190 x 110 | touch speed control |
| Move zone hint | x 0-853, y 598-710 | nothing drawn but a 2 px TRACE line at y 594 across the screen |

- **Background:** fill BG. A 1 px TRACE grid at 40 px pitch whose vertical lines scroll left at `GRID_SPEED 120 * k` px/s (wrap modulo 40). **Stars:** 3 layers x 36 stars (positions seeded once in `begin()`), scrolling left at `STAR_SPEED = [40, 90, 160] * k` px/s, wrapping at x -20 to 1300. Each star is a 2 px line of length `2 + STREAK_LEN 14 * (k - 0.75) * layer` (dots when braking, streaks when boosting), INK at alpha `[0.25, 0.4, 0.6]`; the nearest layer is tinted to the current band colour at alpha 0.5. That tint is the Doppler read: the whole sky warms or cools with you.
- **Ship** at (240, ship_y): a right-pointing triangle 64 wide x 40 tall (points (272, y), (208, y-20), (208, y+20)), PANEL fill, 6 px outline in `BAND_COL[band]`, plus the glow (1.3x alpha 0.25, 1.6x alpha 0.10) in the band colour. Inside it, at (226, y), the band's emblem shape at 14 px in the band colour (square / triangle / circle). An engine flame behind it: a band-coloured triangle from x 206 back to `206 - (12 + 30 * (k - 0.75))` px. Invulnerable: hidden on alternate 0.05 s.
- **Enemies:** each band has its own shape, so colour is never the only cue: band 0 = **square**, band 1 = **triangle** pointing left, band 2 = **circle**, all drawn with half extent `ENEMY_DRAW 24` (about 48 px, 52 with the 4 px outline). Heavy = the same shape drawn at 1.5x (`HEAVY_SCALE`; hitbox `HEAVY_R 36`) with `hp` small INK squares (8 px) stacked on its right. Fill BG, 4 px outline in the band colour. **Matching the ship's band** = hittable: outline at full alpha, slow 3 Hz pulse, and while `hints_on(r)` the glow. Not matching: outline at alpha 0.55, no glow.
- **Shots:** 16 x 4 rects in the band colour they were fired with. Blocked shot: a 2 px DIM spark (two crossing 8 px lines) for 0.1 s at `blocked` pos.
- **Pads:** PANEL fill, 4 px TRACE outline, 28 px word `BRAKE` / `BOOST` in INK centred at baseline y 690, and a 6 px band-coloured bar along the top edge: BRAKE uses the colour one band redder than now (DIM if already ember), BOOST one band bluer (DIM if already blue). Above each word a filled triangle 28 px wide (pointing left on BRAKE, right on BOOST) in the same colour. Pressed (key or tap): fill the pad with its bar colour at alpha 0.35 for 0.12 s. **Hint** (`hints_on(r)`): if the nearest enemy ahead (`Rules.target(s)`) has a different band, the pad that moves toward it glows and pulses at 3 Hz: the correct response is shown, never written.
- **HUD:** score 40 px INK centred at x 640, baseline y 52; lives 3 squares 20 x 20 at y 62-82, centres x 608 / 640 / 672 (EMBER alive; 2 px DIM outline lost; BAD fill 0.4 s after loss). **Hue meter** x 180-420, y 28-60: three 72 x 32 cells 12 px apart, each a 2 px outline in its band colour with its emblem shape inside; the current band filled at alpha 0.85 with the glow. **Timer bar** x 860-1080, y 40-52: TRACE fill, EMBER fill to `t / ROUND_TIME`. **Banner** 48 px in the colour of the new thing (`RED` ember, `BLUE` blue, `HEAVY` INK) centred at x 640, baseline y 140, 1.2 s, fading over the last 0.3 s.
- The only words ever on screen: the score, `BRAKE`, `BOOST`, banners, popups (`+N`, `DODGE`). No READY text, no arrow glyphs (triangles are drawn).

## Sound (Synth presets/tones/loop used, per studio/VISION.md)
| Event | Call |
|---|---|
| Band change (the verb, `EV_SHIFT`) | `Synth.sfx("shift", Rules.shift_pitch(streak))`, `shift_pitch = min(1.5, 1.0 + 0.04 * streak)`; then restart the loop transposed (below) |
| Kill (`EV_KILL`) | `Synth.sfx("hit", randf_range(0.92, 1.08))` and `Synth.sfx("coin", pow(2.0, mini(streak_before, 12) / 12.0))`; heavy kill: also `Juice.hitstop(0.05)` |
| Damage a heavy (`EV_DAMAGE`) | `Synth.tone(660.0, 0.04, "square", 0.12)` (a tick; at most once per 0.08 s) |
| Blocked shot (`EV_BLOCK`) | `Synth.tone(180.0, 0.03, "noise", 0.08)` at most once per 0.2 s (a dull "wrong colour" thud, quiet) |
| Escape (`EV_ESCAPE`) | `Synth.sfx("miss", 0.9)` only if `streak` was >= 3 (the streak broke) |
| Crash in grace | `Synth.sfx("miss", randf_range(0.92, 1.08))` |
| Crash (life lost) | `Synth.sfx("boom", randf_range(0.95, 1.05))`; `Synth.stop_loop()`; loop restarts after 0.5 s |
| Pad pressed at an end | nothing (DIM blink only) |
| Banner | `Synth.sfx("blip", 1.5)` |
| Round intro | `blip` at 0.0 and 0.3 s; loop starts at 0.6 s and `t` starts at 0 that frame |
| Round end | nothing (Arcade plays `win` / `lose`) |
No sound per shot (6 shots a second would eat the 12 voices); the shots are seen, not heard. At most 3 SFX start in a frame: shift (1) + kill (2) is the most; skip tick / thud in a frame that already started 2.

**Music:** square, 150 bpm, `LOOP_VOL = 0.10`, 16 steps, A minor pentatonic, driving: `LOOP_BASE = [45, 0, 57, 45, 52, 0, 55, 57, 45, 0, 57, 60, 57, 55, 52, 50]`. `Rules.loop_notes(band)` returns `LOOP_BASE` with every non-zero note moved by `TRANSPOSE = [-5, 0, 7][band]` (ember a fourth down, blue a fifth up). On every `EV_SHIFT`: `Synth.loop(Rules.loop_notes(band), 150.0, "square", 0.10)` (restart = the audible Doppler). After a crash restart, use the current band.

## Juice list (each item names its state variable; QA checks it is set in the trigger and read in a draw call)
| # | Event (trigger in game.gd) | Effect | State set there, read in drawing |
|---|---|---|---|
| 1 | `EV_SHIFT` | ship squashes 1.25x wide then back over 0.12 s; a ring (circle outline 6 px, band colour) expands from the ship from r 24 to 90 and fades over 0.25 s; star streaks and flame follow `k` | `shift_fx_t = 0.25` |
| 2 | `EV_KILL` | `Juice.burst(self, pos, BAND_COL[band], 14)`; popup `+N` GOOD 36 px, full alpha until 0.55 s; popups within 0.3 s and 40 px of an earlier one sit at least 46 px below that popup's placed spawn position, which is also below where it is drawn after rising (`Rules.stagger_pos`, `popup_rise`); capped 92 px below the base and above y 586 so they never reach the ship row or pads; heavy kill: `Juice.flash(Color(INK, 0.15), 0.1)`, `Juice.shake(10)`, hitstop 0.05 | `kill_rings` (array of `{pos, band, t = 0.2}`: an expanding outline of the enemy's shape) |
| 3 | `EV_DAMAGE` | the heavy flashes INK fill for 0.06 s and squashes 1.25 to 1.0 over 0.12 s | `enemy.flash_t` kept in a game-side Dictionary keyed by the enemy |
| 4 | `EV_BLOCK` | DIM spark at the block point | `sparks` (array of `{pos, t = 0.1}`) |
| 5 | Crash in grace | ship tinted BAD 0.2 s; `Juice.shake(4)`; popup `DODGE` INK 36 px above the midpoint of ship and crash point (`Rules.dodge_pos`, clamped on-screen and below the HUD), full INK for `DODGE_HOLD 0.7` s then fades by `DODGE_LIFE 1.1` s | `tint_t = 0.2` |
| 6 | Crash (life lost) | `Juice.flash(Color(BAD, 0.35), 0.2)`, `Juice.shake(14)`, `Juice.hitstop(0.06)`, `Juice.burst(self, crash_pos, BAD)`; lost life square BAD 0.4 s; loop silent 0.5 s | `life_flash_t = 0.4`, `loop_restart_t = 0.5` |
| 7 | Pad pressed | pad fill flash 0.12 s (DIM if at an end) | `pad_t[0..1] = 0.12`, `pad_dead[0..1]` |
| 8 | Banner change | fades in/out as above | `banner_text`, `banner_t` |

## Build plan (scripts, data structures, every tunable with a start value)
Files (target ~800 lines, each under 300):
- `rules.gd` (~250 lines, pure: no nodes, no autoloads; a passed-in `RandomNumberGenerator`): constants, inner classes `Enemy`, `Shot`, `Run`; static `ramp_time`, `enemy_speed`, `spawn_gap`, `spawn_bands`, `phase_name`, `hints_on`, `is_grace`, `shift`, `step`, `kill_points`, `shift_pitch`, `final_score`, `loop_notes`, `tap_target`, `follow_dir`, `popup_pos`, `dodge_pos` (where the DODGE popup goes), `popup_alpha(age, hold, life)` (full alpha through the hold, then linear fade; game.gd `_popup` drives the label alpha from it each frame with `DODGE_HOLD`/`DODGE_LIFE`), `popup_rise`, `stagger_pos`.
- `rules_bot.gd` (pure, no nodes; preloaded as `Bot`; takes `R.Run`): static `target(s) -> Enemy` (nearest enemy with `x > SHIP_X + 30`, or null), `bot_think(s) -> Dictionary` (`{shift: -1/0/1, aim_y: float}`), `sim_round(seed, difficulty, mode := "bot") -> Dictionary` (`won`, `time`, `crashes`, `first_crash`, `kills`, `escapes`, `shifts`, `score`; modes `"bot"`, `"idle"`).
- `selftest.gd` (~100 lines): the assertions in the checklist; prints `SELFTEST OK`.
- `game.gd` (~250 lines, `extends MicroGame`): state, `begin()` (seed stars, `Run.new()`), `_process()`, `_unhandled_input()`, `_shift(dir)`, `_on_events(ev)`, `_crash()`, `_draw()` that only calls the draw helpers.
- `redshift_draw.gd` (~220 lines, `extends RefCounted`, static helpers taking `ci: CanvasItem`): `draw_space(ci, stars, grid_x, k, band)`, `draw_emblem(ci, band, pos, size, color, width, filled)`, `draw_ship(...)`, `draw_enemy(...)`, `draw_shots(...)`, `draw_pads(...)`, `draw_hud(...)`, `glow(...)`. All drawing lives here; game.gd keeps none.

**Per-frame order in `_process(dt)` (`sim_round` uses the same order with `dt = 1/60`):**
1. Intro / juice timers / loop restart. 2. `t += dt; r = ramp_time(t, difficulty)`. 3. Input: if `autoplay`, every `BOT_THINK = 0.1` s: `d = Rules.bot_think(run)`; `if d.shift != 0: _shift(d.shift)`; store `bot_aim_y = d.aim_y`; `move = Rules.follow_dir(bot_aim_y, run.ship_y)` every frame (the same follow the touch drag uses). Else `move` from keys / pointer. 4. `ev = Rules.step(run, dt, r, move, rng)`. 5. `_on_events(ev)`: add `kills` points, juice, sound; on `EV_CRASH` grace or life; lives 0: `finish(score, false)`; return. 6. If `t >= ROUND_TIME`: `finish(Rules.final_score(score, lives), true)`; return. 7. Scroll stars / grid by `k`, banner check, `queue_redraw()`.

**rules.gd tunables:**
| Name | Start value |
|---|---|
| EV_SHIFT, EV_KILL, EV_DAMAGE, EV_CRASH, EV_ESCAPE, EV_BLOCK | 1, 2, 4, 8, 16, 32 |
| BANDS, START_BAND, SPEED_MUL, K_EASE | 3, 1, [0.75, 1.0, 1.3], 4.0 |
| SHIP_X, SHIP_Y0, SHIP_Y_MIN, SHIP_Y_MAX, SHIP_R, MOVE_SPEED | 240, 340, 110, 570, 22, 420 |
| FIRE_GAP, SHOT_SPEED | 0.16, 900 |
| SPAWN_X, ESCAPE_X, ENEMY_Y_MIN, ENEMY_Y_MAX, ENEMY_R, HEAVY_R | 1320, -40, 130, 550, 26, 36 |
| SPEED_START, SPEED_RAMP, SPEED_MAX | 150, 3.5, 260 |
| GAP_START, GAP_RAMP, GAP_MIN, FIRST_SPAWN | 1.6, 0.02, 0.85, 0.5 |
| RED_AT, BLUE_AT, HEAVY_AT, HEAVY_CHANCE, HEAVY_HP, HEAVY_SLOW | 10, 20, 30, 0.25, 3, 0.8 |
| LIVES, INVULN, ROUND_TIME, GRACE_END, HINTS_END, DIFFICULTY_OFFSET | 3, 1.0, 50.0, 10.0, 30.0, 30.0 |
| KILL_PTS, STREAK_PTS, STREAK_CAP, HEAVY_MULT, LIFE_BONUS | 10, 2, 10, 3, 100 |
| PITCH_STEP, PITCH_MAX | 0.04, 1.5 |
| LOOP_BASE, TRANSPOSE | see Sound, [-5, 0, 7] |
| BOT_THINK, BOT_DODGE_X, BOT_DODGE_DY, BOT_DODGE_OFS, FOLLOW_DEAD | 0.1, 320, 75, 150, 6 |
| BRAKE_RECT, BOOST_RECT, MOVE_ZONE_X, TAP_BRAKE, TAP_BOOST, TAP_MOVE | see Controls, 0, 1, 2 |
game.gd / redshift_draw.gd: `INTRO = 0.6`, `BANNER_TIME = 1.2`, `LOOP_VOL = 0.10`, `LOOP_BPM = 150.0`, `STAR_SPEED = [40, 90, 160]`, `STAR_COUNT = 36`, `GRID_SPEED = 120`, `STREAK_LEN = 14`, `BAND_COL`.

## Autoplay bot (how it plays; must reach finish() within 60 s)
`Rules.bot_think(s)`, every `BOT_THINK = 0.1` s of game time, fed through `_shift` and `follow_dir` (real inputs, the same paths as the pads and the touch drag):
1. `tgt = Rules.target(s)` (nearest enemy ahead). If none: `{shift: 0, aim_y: SHIP_Y0}`.
2. `shift = sign(tgt.band - s.band)` (one band per think, so ember to blue takes two thinks); `aim_y = tgt.pos.y`.
3. Dodge: for every other enemy ahead with `x - SHIP_X < BOT_DODGE_X 320` and `abs(y - aim_y) < BOT_DODGE_DY 75`: `aim_y = y + 150` if `y < SHIP_Y0` else `y - 150`. Clamp `aim_y` to the ship range.
In the model it never crashes at difficulty 0 or 1 (seeds 1-20), kills 42-55 enemies, and always reaches `finish(_, true)` at t 50.0 (50.6 s with the intro), under the 60 s limit.

## Acceptance checklist (6–10 testable items, incl. 2–4 rules.gd assertions)
1. **Gate:** `./scripts/check.sh redshift` prints PASS (glyph lint, import, smoke, autoplay round reaching `finish` with `won == true` at about 50.6 s, selftest).
2. **selftest, ramp:** `ramp_time(5, 0) == 5`, `ramp_time(5, 1) == 35`; `enemy_speed(0) == 150`, `enemy_speed(20) == 220`, `enemy_speed(100) == 260`; `spawn_gap(0) == 1.6`, `spawn_gap(100) == 0.85`; `spawn_bands(5) == [1]`, `spawn_bands(15) == [0, 1]`, `spawn_bands(25).size() == 3`; `phase_name(5) == ""`, `phase_name(15) == "RED"`, `phase_name(25) == "BLUE"`, `phase_name(35) == "HEAVY"`; `is_grace(9.9)` and not `is_grace(10.0)`; `hints_on(29.9)` and not `hints_on(30.0)`.
3. **selftest, shift and step:** (a) a fresh `Run`: `shift(s, -1) == EV_SHIFT` and band 0; `shift(s, -1) == 0` (end stop); two `shift(s, +1)` give band 2, a third returns 0; (b) with band 2, 60 frames of `step` move `k` from 1.0 to within 0.02 of 1.3; (c) a lime enemy placed at (600, ship_y) with the ship lime: within 60 frames `EV_KILL` fires once and `kills[0].pts == 10`; the same enemy in ember with the ship lime: it is never killed and `EV_BLOCK` fires; (d) a heavy (hp 3) of the ship's band takes 3 hits: two `EV_DAMAGE`, then `EV_KILL` with `pts == 30`; (e) an enemy placed on the ship gives `EV_CRASH` once and `invuln == 1.0`; a second one placed on it the next frame gives no crash; (f) `move = -1` for 120 frames clamps `ship_y` at 110.
4. **selftest, sims:** for seeds 1-10, `sim_round(seed, 0)` and `sim_round(seed, 1)`: `won`, `crashes <= 2`, `time` in 49.9-50.1, `kills >= 30`, `shifts >= 10`; `sim_round(seed, 0, "idle")` is not `won`, its `first_crash > 3.0`, and it ends before t 50.
5. **selftest, scoring, sound and input:** `kill_points(0, false) == 10`, `kill_points(99, false) == 30`, `kill_points(0, true) == 30`; `shift_pitch(100) == 1.5`; `final_score(1000, 2) == 1200`; `loop_notes(0)[0] == 40`, `loop_notes(2)[0] == 52`, `loop_notes(0)[1] == 0` (rests stay rests); `tap_target(Vector2(960, 650)) == TAP_BRAKE`, `tap_target(Vector2(1160, 650)) == TAP_BOOST`, `tap_target(Vector2(400, 300)) == TAP_MOVE`, `tap_target(Vector2(60, 30)) == -1`, `tap_target(Vector2(1000, 300)) == -1`; both pad rects are at least 96 px each way and lie outside both corners; `follow_dir(100, 340) == -1`, `follow_dir(343, 340) == 0`.
6. **Shot `start`:** BG with the TRACE grid and stars; the lime ship (triangle, 6 px lime outline, glow) at the left middle; BRAKE pad with an ember bar, BOOST pad with a blue bar, both words readable; hue meter with lime filled; score `0`, three ember life squares; nothing in the corners (x < 150 or x > 1100, y < 70).
7. **Shot `play-1500`** (25 s into the bot round): enemies of at least two shapes / colours on screen, shots in the ship's colour, score above 200, the ship's colour matches the nearest enemy's (or is mid-shift); HUD at least 28 px; only palette colours; no empty glyph boxes.
8. **Code read (grep `games/redshift`):** `Synth.sfx("shift", Rules.shift_pitch(` in `_shift`; `Synth.loop(` uses `150.0, "square"` and `Rules.loop_notes(`; no `"win"` / `"lose"` sfx; `difficulty` used only via `Rules.ramp_time`; exactly one `finish(` with `true` and one with `false`; the bot path is `Rules.bot_think` into `_shift` / `follow_dir` (game.gd never writes `run.band` or `run.ship_y`); every `draw_` call lives in `redshift_draw.gd` (game.gd's `_draw` only calls its helpers); no `InputEventScreenTouch`; Esc, P and M not read.
9. **Juice wired:** for each Juice row, the named state variable is assigned in the named trigger and read in a draw function (grep both); `Juice.flash`, `Juice.shake`, `Juice.hitstop`, `Juice.burst` appear in game.gd; popups use game.gd `_popup` (Juice.popup look, brighter, constants from rules.gd).
10. **Touch:** a tap at (1160, 650) boosts (shift sound, ship turns blue, loop restarts higher); a press and drag at x 400 from y 340 to y 200 moves the ship up at the key speed; a tap on the HUB or SOUND button does neither.

## Out of scope
- A scrolling level, terrain, bosses, level data or scripted waves (formations of 3 are random V / line shapes, not scripted waves).
- Enemy bullets, power-ups, bombs, weapon upgrades, a shield meter.
- Continuous speed (exactly 3 bands), horizontal ship movement, any physics.
- Hue-shifting enemies (a possible later polish task, not in this build).
- Tutorial text, READY screens, per-game menus; arrow glyphs (pads draw triangles).
- Gamepad support (a free bonus at most).

## QA
Autoplay seeds its RNG with `QA_SEED = 7` (`game.gd`), so autoplay rounds are repeatable; `-- --seed=N` overrides it.

**Deterministic DODGE shot:** `--seed=4`, idle (no autoplay), `--shotframes=470` shows the DODGE popup at full INK (seed 4's first idle crash is about game frame 420, inside grace): `xvfb-run -a -s "-screen 0 1280x720x24" .tools/godot --path . --rendering-driver opengl3 --audio-driver Dummy --resolution 1280x720 --fixed-fps 60 -- --game=redshift --seed=4 --shotfile=.tools/shots-rs17/d470.png --shotframes=470`. `./scripts/shots.sh redshift 2550` shows a blue heavy (1.5x, 3 hp squares) at the top right.

Formations: autoplay bot (seeds 1, 2, 3, 7) wins every round, scores about 2,600-2,830 at difficulty 0 (the rules.gd `sim_round` model and its numbers above predate formations: they model single spawns). `./scripts/shots.sh redshift 1200` shows a lime line of 3 plus the next formation entering at the right.
