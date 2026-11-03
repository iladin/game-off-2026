# Phase Shift

<!-- Written by the Game Designer before any code. The Gameplay Engineer builds exactly this. -->
<!-- R0005, slate slot 5, sense PHASE. Accent #A78BFA (world A, violet), second world #3DDCFF (world B, cyan). Budget: about 30 min, under ~850 lines of GDScript. -->

## Pitch
A square runs to the right on its own, over a floor made of two overlapping worlds. Every floor tile and every wall exists in only one world: world A (violet) or world B (cyan); grey tiles exist in both. Solid shapes are in your world; faint outlines are in the other one. **Phase** to flip worlds so the floor under you exists and the wall ahead does not; **jump** over the holes that are in neither world. Reach the gold gate at the end of the course to clear the PHASE bit.

## How it uses SHIFT
SHIFT = **the phase shift between two worlds**. Phasing is the core verb and the only way to deal with most hazards: a violet run of floor can only be stood on in world A; a cyan wall can only be passed in world A. One press swaps which world is solid, swaps the whole colour scheme of the level (solid to outline and back), and shifts the music 5 semitones up (to world B) or back down (to world A). Every phase plays `Synth.sfx("shift", Rules.shift_pitch(streak))`.

## Core loop
Every 1.5-3 s:
1. A run of floor in the other world scrolls in from the right (drawn as faint outlines in its colour). While hints are on, it glows and your square's outline pulses in that colour.
2. A grey bridge (both worlds) leads into it. Phase while you are on the bridge (or in the air).
3. From 10 s: a hole in a run. Jump: the jump is fixed (0.69 s, 156 px high), so the decision is only *when*.
4. From 20 s: a wall on a bridge. If it is solid (your world), phase so it becomes an outline and you pass through; then you may need to phase straight back for the next run.
5. From 30 s: cross gaps: the floor ends in a hole and the far side is in the other world. Jump, then phase in mid-air.

The decision: which world you must be in for the next thing, and doing the phase inside the bridge window (not too early: phasing early drops you off a single-world tile; not too late: you fall or crash).

## Controls (keyboard AND touch)
| Action | Keyboard | Touch / mouse |
|---|---|---|
| Jump | Space, Up or W (`pressed and not echo`) | press anywhere on the right half (x >= 640). The JUMP pad `Rect2(810, 616, 300, 96)` is drawn there as the visual. Fires on press |
| Phase | Shift (either), Down, S or X (`pressed and not echo`) | press anywhere on the left half (x < 640). The PHASE pad `Rect2(170, 616, 300, 96)` is drawn there. Fires on press |

- Read `InputEventKey` (KEY_SPACE, KEY_UP, KEY_W; KEY_SHIFT, KEY_DOWN, KEY_S, KEY_X) and `InputEventMouseButton` (MOUSE_BUTTON_LEFT, pressed) in `_unhandled_input`, so Arcade's HUB / SOUND buttons take their clicks first. `emulate_mouse_from_touch=true`: do NOT also handle `InputEventScreenTouch` / `InputEventScreenDrag` (double fire). Never Esc, P or M.
- Input sets `jump_req = true` / `phase_req = true` and lights that pad (`pad_t[side] = PAD_DOWN_TIME`) in the same frame; `_process` consumes the flags in the next step. Keys and touch use the same flags, so touch alone earns the same score. Each half is 640 x 720; each drawn pad is 300 x 96.
- Ignore input when `autoplay`, `is_finished()`, or during the 0.6 s intro.
- `Rules.touch_zone(pos) -> int`: `PHASE` if `pos.x < 640` else `JUMP`.

## Round: fail / win, score
- **Win (clears the PHASE bit):** the run distance `dist` reaches `GOAL_DIST = 14400` px. `finish(Rules.final_score(score, lives), true)` in that frame. **The round length does not depend on skill:** distance comes only from the speed ramp, so every surviving round (human or bot) ends at t = 40.0 s (difficulty 0) or about 33.2 s (difficulty 1), plus the 0.6 s intro. This is the fix for Bit Catcher's bot that was first too fast, then too slow.
- **Lives:** 3, accent squares at top centre.
- **Hard fail (costs a life):** `EV_FALL` (fell below `FAIL_Y`) or `EV_CRASH` (centre inside a wall cell of your own world). Then `Rules.rescue(...)`: back on the floor line, 1.2 s invulnerable (a ghost bridge holds you up, walls are ignored), world auto-fitted to the floor ahead. **Grace:** while `r < GRACE_END` (10 s) a hard fail costs nothing: soft-fail feedback plus a one-word popup in DIM naming what was needed (`PHASE` or `JUMP`), then the same rescue. So the first 10 s cannot be lost.
- **Lose:** lives reach 0: `finish(score, false)` in the same frame as the hard-fail effects.
- `finish()` exactly once per round (return right after). Never play `win` / `lose`.
- **Score:** `CELL_PTS = 2` per new floor cell reached (180 cells to the gate = 360). Orb (collect in your world): `Rules.orb_points(streak) = 20 + 2 * min(streak, 10)` (streak before this orb). Passing through a wall: `WALL_PTS = 15`. Win: `+150` per life left. `streak` counts orbs and wall passes since the last fail (any fail, grace included, resets it). A clean bot round (no fails, win) scores about 1,750-1,950 (`sim_bot_round` over seeds 1-20 at difficulty 0: 1,730-2,040, mean about 1,870; `res.score` already includes the 450 life bonus).
- **Typical length:** 40.6 s for any surviving round including the intro (34 s at difficulty 1). A losing round ends sooner.

## Ramp (with numbers)
Round time `t` counts from the loop start (end of intro). Ramp time `r = Rules.ramp_time(t, difficulty) = t + (30.0 if difficulty >= 1 else 0.0)`.

- **Speed:** `speed(r) = min(440, 280 + 4 r)` px/s (280 at the start, 320 at r 10, 360 at r 20, 400 at r 30, 440 clamp from r 40). Each frame: `t += dt; r = ramp_time(t, d); v = speed(r); x_prev = dist; dist += v * dt`.
- Difficulty 0: `dist_at(t) = 280 t + 2 t^2`, so `dist_at(40) = 14400 = GOAL_DIST` exactly. Difficulty 1: 4,200 px in the first 10 s, then 440 px/s: goal at t = 33.18 s.
- **Course zones** are fixed by floor cell (cell = 80 px), matching the ramp time at difficulty 0: `zone_at(c, d)` = 3 if `d >= 1`; else 0 for c < 37, 1 for c < 80, 2 for c < 127, 3 otherwise (cell 37 is reached at t = 9.9 s, cell 80 at t = 20 s, cell 127 at t = 29.9 s).

| Zone (time at d 0) | Speed px/s | Run length (cells) | Hole inside a run | Separator between runs | Bridge cells | Banner `phase_name(r)` |
|---|---|---|---|---|---|---|
| 0 (0-10 s) | 280-320 | 6-9 | none | bridge | 3 | `""` |
| 1 (10-20 s) | 320-360 | 6-9 | 1 cell | bridge | 2 | `JUMP` |
| 2 (20-30 s) | 360-400 | 5-8 | 1 cell | 50%: wall bridge (2, wall, 2), else bridge | 2 | `WALLS` |
| 3 (30 s+) | 400-440 | 6-8 | 1 or 2 cells (50/50) | 1/3 wall bridge (1, wall, 1); 1/3 cross gap (1 or 2 hole cells, no bridge); 1/3 bridge | 1 | `TOP SPEED` |

- `hints_on(r)`: r < 30. `is_grace(r)`: r < 10. Banners show when `phase_name(r)` differs from the last shown (start `""`), so at difficulty 1 `TOP SPEED` shows at once.
- Jump geometry: `JUMP_V = -900`, `GRAVITY = 2600`: air time `AIR_TIME = 2 * 900 / 2600 = 0.692` s, apex 156 px. Air distance 221 px at 320 px/s, 305 px at 440. A 1-cell hole (80 px) leaves 141 px of take-off window at 320 px/s (0.44 s); a 2-cell hole (160 px) at 400 px/s leaves 117 px (0.29 s). Walls are 360 px tall: never jumpable.
- Phase windows: a bridge cell is 80 px (0.29 s at 280, 0.18 s at 440) plus `COYOTE = 0.10` s after the floor vanishes.

### Course generation (`Rules.build_course(rng, difficulty) -> Course`, pure)
Arrays of `TOTAL_CELLS = 210` bytes: `ground` (0 hole, 1 world A, 2 world B, 3 both), `wall` (0 none, 1 A, 2 B), `orb` (0 none, 1 A, 2 B). Start with every `ground = 3`. Then:
```
c = START_CELLS (8)            # cells 0-7 stay BOTH: the start platform
w = 2                          # first run is world B: the player starts in A, so the verb appears at about 2 s
while c < GOAL_CELLS (180):
    z = zone_at(c, difficulty)
    n = rng.randi_range(RUN_MIN[z], RUN_MAX[z])
    a = n / 2 (integer); b = n - a
    hole = 0 if z == 0 else (rng.randi_range(1, 2) if z == 3 else 1)
    write a cells of ground w, then hole cells of 0, then b cells of ground w   # a, b >= 2
    orbs: on run cells with odd index i (counting from the run's first cell, holes excluded),
          in world w, but never within 2 cells of a hole
    c += a + hole + b
    w = 3 - w                  # the next run is always the other world
    separator by zone (table above):
        bridge k:       k cells of 3
        wall bridge:    m cells of 3, 1 cell of 3 with wall = rng.randi_range(1, 2), m cells of 3  (m = 2 in zone 2, 1 in zone 3)
        cross gap:      rng.randi_range(1, 2) cells of 0
    c += separator length
# cells from c to the end stay 3 (run-out past the gate)
```
Invariants (selftest checks them): cells 0-7 and every cell >= `GOAL_CELLS + 16` are 3; a ground-1 cell is never next to a ground-2 cell; a wall cell and both its neighbours are ground 3; every hole stretch is 1-2 cells long with at least 2 ground cells on each side; cells below 37 at difficulty 0 hold no hole and no wall; an orb sits only on a single-world cell of its own world.

## The physics step (`Rules.step`, pure, shared by the game, the bot and the selftest)
`class Body` (inner class in rules.gd, `extends RefCounted`): `y: float = GROUND_Y` (feet), `vy: float = 0`, `world: int = 1`, `grounded: bool = true`, `coyote: float = 0`, `jump_buf: float = 0`, `invuln: float = 0`, `phase_cd: float = 0`, `orb_cell: int = -1`.
`cell_of(x) = floori(x / CELL)`. The player's world x is `dist`; the player is drawn at screen x `PLAYER_X = 320`.
`has_ground(course, c, world)`: `ground[c] == 3 or ground[c] == world` (cells past the array count as 3).

`step(b, course, x_prev, x, dt, jump, phase) -> int` (bitmask of events), in this order:
1. `b.phase_cd -= dt`. If `phase` and `b.phase_cd <= 0`: `b.world = 3 - b.world`, `b.phase_cd = PHASE_COOLDOWN (0.15)`, ev |= `EV_PHASE (1)`. (Allowed on the ground and in the air. The cooldown stops mashing from beating swaps: 0.15 s in the wrong world is longer than the 0.10 s coyote.)
2. If `jump`: `b.jump_buf = JUMP_BUFFER (0.10)`. If `b.jump_buf > 0` and (`b.grounded` or `b.coyote > 0`): `vy = JUMP_V`, grounded false, coyote 0, jump_buf 0, ev |= `EV_JUMP (2)`. Then `b.jump_buf -= dt`.
3. `ok = has_ground(course, cell_of(x), b.world) or b.invuln > 0`.
   - grounded and not ok: grounded = false, `coyote = COYOTE (0.10)`, vy = 0.
   - not grounded and coyote > 0: if ok: grounded = true, coyote = 0 (a phase in time saves you); else `coyote -= dt` (y stays on the line).
   - not grounded and coyote <= 0: `vy += GRAVITY * dt; y_prev = y; y += vy * dt`. If `vy > 0 and y_prev <= GROUND_Y and y >= GROUND_Y and ok`: y = GROUND_Y, vy = 0, grounded = true, ev |= `EV_LAND (4)`. Else if `y > FAIL_Y (680)`: ev |= `EV_FALL (8)`. (Once below the floor line you cannot land: holes must be jumped.)
4. Walls (only when `b.invuln <= 0`): `c = cell_of(x)`, `wx = c * CELL + CELL / 2`. If `wall[c] == b.world`: ev |= `EV_CRASH (16)`. Else if `wall[c] != 0 and x_prev < wx and x >= wx`: ev |= `EV_WALL (32)`.
5. Orbs: if `orb[c] == b.world and b.y > GROUND_Y - ORB_REACH (100)`: ev |= `EV_ORB (64)`, `b.orb_cell = c`. (The game sets `orb[c] = 0`.)
6. If `b.invuln > 0`: `b.invuln -= dt`; when it drops to <= 0 this step: `b.world = fit_world(course, c, b.world)` (silent).

`fit_world(course, c, world)`: if `wall[c] == world` return `3 - world`; if `ground[c]` is 1 or 2 return `ground[c]`; else `world`.
`rescue(b, course, x, v)`: y = GROUND_Y, vy 0, grounded true, coyote 0, jump_buf 0, `invuln = INVULN (1.2)`, `world = fit_world(course, cell_of(x + v * INVULN), b.world)`.

## Look (palette hex + how each thing is drawn, per studio/VISION.md)
Colours: BG `#0B0E14`, PANEL `#151A24`, TRACE `#1E2738`, DIM `#6B7489`, INK `#E8ECF4`, WORLD_A = ACCENT `#A78BFA`, WORLD_B `#3DDCFF`, GOOD `#FFD34D`, BAD `#FF3B5C`. Nothing else. `world_col(1) = WORLD_A`, `world_col(2) = WORLD_B`.

Screen map (1280 x 720):
| y | Band |
|---|---|
| 0-112 | HUD: score, lives, progress bar (x 170-1090 only) |
| 128-176 | banner |
| 200-560 | play area: walls from y 200 to 560; the player's feet on `GROUND_Y = 560` |
| 560-600 | floor slabs |
| 616-712 | PHASE pad (left) and JUMP pad (right) |

Screen x of cell c: `sx = PLAYER_X + c * CELL - dist` (draw only cells with `sx` in -80..1280).
- **BG:** fill BG; 1 px TRACE grid at 40 px pitch, scrolled left at half speed (`x offset = -fmod(dist * 0.5, 40)`).
- **Floor cells** (78 x 40 at `(sx + 1, 560)`):
  - both (3): PANEL fill, 2 px TRACE outline, a 4 px INK line along the top at alpha 0.5.
  - your world: fill `world_col`, 4 px INK line along the top.
  - the other world: 2 px outline in its colour at alpha 0.35, no fill (it is not there).
  - hole: nothing.
- **Walls** (40 x 360, centred on the cell, y 200-560): your world: fill `world_col`, 4 px INK outline, glow (1.3x alpha 0.25, 1.6x alpha 0.10). Other world: 2 px outline at alpha 0.35 (you pass through it).
- **Orbs:** circle r 12 at (cell centre, `GROUND_Y - 40`). Your world: filled `world_col`, 2 px INK outline, glow. Other world: 2 px outline at alpha 0.35.
- **Gate:** at screen x `PLAYER_X + GOAL_DIST - dist` when on screen: an 8 px GOOD bar from y 200 to 560 with glow.
- **Player:** 48 x 48 square, bottom-centre at (320, y): fill `world_col(world)`, 6 px INK outline, glow in `world_col`. In the air it turns: angle `= (PI / 2) * clamp(air_t / AIR_TIME, 0, 1)`; back to 0 on landing. During `invuln` it blinks (hidden when `fmod(invuln, 0.16) < 0.08`) and a 4 px INK line at alpha 0.5 is drawn on the floor line from x 260 to 380 (the ghost bridge).
- **Hint** (while `hints_on(r)`): `hw = Rules.hint_world(course, dist, world)` (scan cells `cell_of(dist) + 1` to `cell_of(dist + HINT_LOOK 240)`; the first with `need_world != 0`; return it if it differs from `world`, else 0). When `hw != 0`: the player's outline is drawn in `world_col(hw)` instead of INK, alpha pulsing `0.55 + 0.45 sin(TAU * 4 t)`, and that hint cell (floor or wall) is drawn again at 1.3x in `world_col(hw)` at alpha 0.25 (glow). No text.
- **Pads:** PANEL fill, 4 px TRACE outline. PHASE: two 40 x 40 squares with 4 px outlines, WORLD_A at offset (-10, -10) and WORLD_B at (+10, +10) from the centre; the current world's square is filled. JUMP: a filled INK triangle pointing up (56 wide, 48 tall). Pressed (`pad_t > 0`): offset +6 px down, ACCENT fill (WORLD_B fill on PHASE while in world B), the shape in BG colour. No text on pads.
- **HUD** (x 170-1090; nothing at x < 150 or x > 1100 above y 70):
  - Score 40 px INK centred, baseline y 56.
  - Lives: 3 squares 20 x 20 at y 66-86, centres x 608 / 640 / 672: ACCENT alive, 2 px DIM outline when lost (BAD fill for 0.4 s right after: `life_flash_t`).
  - Progress bar: x 340-940, y 98-106: TRACE fill, `world_col(world)` fill to `dist / GOAL_DIST`, a 4 x 16 GOOD tick at x 940.
  - Banner 40 px ACCENT centred, baseline y 168, 1.2 s, fades over the last 0.3 s.
- The only words ever on screen: the banners and the popups below (`+N`, `THROUGH`, `PHASE`, `JUMP`). No READY text.

## Sound (Synth presets/tones/loop used, per studio/VISION.md)
| Event | Call |
|---|---|
| Phase (the verb, `EV_PHASE`) | `Synth.sfx("shift", Rules.shift_pitch(streak))`, `shift_pitch = min(1.5, 1.0 + 0.04 * streak)`; then `Synth.loop(Rules.loop_notes(world), 128.0, "saw", LOOP_VOL)` (restart transposed) |
| Jump (`EV_JUMP`) | `Synth.sfx("jump", randf_range(0.95, 1.05))` |
| Land (`EV_LAND`) | `Synth.tone(110.0, 0.05, "triangle", 0.20, 80.0)` (thud) |
| Orb (`EV_ORB`) | `Synth.sfx("coin", pow(2.0, mini(streak, 12) / 12.0))` (streak before the orb) |
| Wall pass (`EV_WALL`) | `Synth.tone(880.0, 0.12, "sine", 0.22, 1320.0)` (shimmer) |
| Grace fail | `Synth.sfx("miss", randf_range(0.92, 1.08))` |
| Hard fail (life lost) | `Synth.sfx("boom", randf_range(0.95, 1.05))`; `Synth.stop_loop()`; restart `loop_notes(world)` after 0.5 s |
| Banner | `Synth.sfx("blip", 1.5)` |
| Round intro | `blip` at 0.0 and 0.3 s; loop starts at 0.6 s and `t` starts at 0 that frame |
| Round end | nothing (Arcade plays `win` / `lose`) |

**Music:** saw, 128 bpm, `LOOP_VOL = 0.09`, A minor pentatonic in world A: `LOOP_A = [45, 0, 57, 0, 52, 57, 0, 55, 45, 0, 57, 0, 60, 57, 55, 52]`. `Rules.loop_notes(world)`: LOOP_A for world 1; for world 2 every non-zero note +5 (rests stay 0). `Synth.loop` restarts at step 0, which is the audible phase shift. At most 3 sounds start in one frame (worst case: phase + orb + wall pass).

## Juice list (each item names its state variable; QA checks it is set in the trigger and read in a draw call)
| # | Event (trigger in game.gd) | Effect | State set there, read in drawing |
|---|---|---|---|
| 1 | `EV_PHASE` in `_on_events` | `Juice.flash(Color(world_col(new), 0.12), 0.1)`; a ring at the player (radius 30 to 90, 4 px, new world colour, alpha 1 to 0, ease out) and a ghost square of the OLD world colour at alpha 0.5 fading out, both over 0.2 s; pad pressed look | `phase_fx_t = PHASE_FX_TIME (0.2)`, `phase_old_world` |
| 2 | `EV_JUMP` | player stretch 0.8 wide x 1.2 tall, back to 1.0 over 0.12 s | `squash_t = SQUASH_TIME`, `squash_kind = STRETCH` |
| 3 | `EV_LAND` | squash 1.25 wide x 0.8 tall back over 0.12 s; `Juice.burst(self, Vector2(320, 560), INK, 6, 120.0)` (dust) | `squash_t`, `squash_kind = SQUASH` |
| 4 | `EV_ORB` | `Juice.burst(self, orb_pos, world_col, 14)`; `Juice.popup(self, orb_pos - Vector2(0, 50), "+%d" % pts, GOOD)`; orb removed | `course.orb[c] = 0` |
| 5 | `EV_WALL` | the passed wall drawn INK-filled at alpha 0.6 for 0.15 s; popup `THROUGH` GOOD 28 px above it; `Juice.shake(4)` | `wall_flash_c = c`, `wall_flash_t = 0.15` |
| 6 | Grace fail (`EV_FALL` or `EV_CRASH` while `is_grace`) | player tinted BAD for 0.2 s; `Juice.shake(4)`; popup `JUMP` (if it was a fall over a hole cell) or `PHASE` (otherwise) in DIM at 32 px above the player; rescue | `fail_tint_t = 0.2` |
| 7 | Hard fail (after grace) | `Juice.flash(Color(BAD, 0.35), 0.2)`, `Juice.shake(14)`, `Juice.hitstop(0.06)`, `Juice.burst(self, player_pos, BAD)`; player tinted BAD 0.2 s; lost life square flashes BAD 0.4 s; loop silent 0.5 s; rescue (blink + ghost bridge) | `fail_tint_t`, `life_flash_t = 0.4`, `loop_restart_t = 0.5`, `body.invuln` |
| 8 | Banner change | banner fades in/out as above | `banner_text`, `banner_t` |

## Build plan (scripts, data structures, every tunable with a start value)
Files (target ~820 lines, each under 300):
- `rules.gd` (~270 lines, pure: no nodes, no autoloads; a passed-in `RandomNumberGenerator` is fine): constants, inner classes `Body` and `Course` (`ground`, `wall`, `orb`: `PackedByteArray`), and static functions: `ramp_time`, `speed`, `dist_at(t, d)` (closed form / piecewise, for the selftest), `zone_at`, `phase_name`, `hints_on`, `is_grace`, `build_course`, `cell_of`, `has_ground`, `need_world(course, c)` (wall: `3 - wall`; ground 1 or 2: that; else 0), `hint_world`, `fit_world`, `step`, `rescue`, `next_hole(course, x) -> Vector2i` (start cell and length of the first hole stretch starting at or after `cell_of(x)` within 6 cells, or `(-1, 0)`), `bot_input(b, course, x, v) -> int`, `sim_bot_round(seed, difficulty) -> Dictionary`, `orb_points`, `shift_pitch`, `final_score`, `loop_notes`, `touch_zone`.
- `selftest.gd` (~100 lines): the assertions in the checklist; prints `SELFTEST OK`.
- `game.gd` (~260 lines, `extends MicroGame`): state, `begin()`, `_process()` (intro, loop restart, timers, advance `dist`, collect input or bot flags, `Rules.step`, `_on_events(ev)`, cell score, finish checks), `_unhandled_input()`, `_on_events()`, `_hard_fail()`, `_draw()` calling the helpers.
- `phase_draw.gd` (~190 lines, `extends RefCounted`, static helpers taking `ci: CanvasItem`; preload like Rules): `draw_backdrop(ci, dist)`, `draw_course(ci, course, dist, world, hint_c, hint_w, wall_flash_c, wall_flash_t, t)`, `draw_player(ci, y, world, angle, sx, sy, tint_t, outline_col, invuln, phase_fx_t, old_world)`, `draw_pads(ci, pad_t, world)`, `draw_hud(ci, font, score, lives, life_flash_t, progress, world, banner, banner_alpha)`, `glow_rect(...)`.

**Per-frame order in `_process(dt)` (the selftest's `sim_bot_round` uses the same order):**
1. Intro / timers / loop restart. 2. `t += dt; r = ramp_time; v = speed(r); x_prev = dist; dist += v * dt`. 3. Flags: if `autoplay`: `f = Rules.bot_input(body, course, dist, v)`, `jump = f & 1`, `phase = f & 2`; else `jump_req` / `phase_req` (then clear them). 4. `ev = Rules.step(body, course, x_prev, dist, dt, jump, phase)`. 5. `_on_events(ev)` (score, sounds, juice; on FALL or CRASH: grace or hard fail, then `Rules.rescue`; if lives reach 0: `finish(score, false)`; return). 6. Cell score: `while last_cell < cell_of(dist): last_cell += 1; score += CELL_PTS`. 7. If `dist >= GOAL_DIST`: `finish(Rules.final_score(score, lives), true)`; return. 8. Banner check; `queue_redraw()`.

**rules.gd tunables:**
| Name | Start value |
|---|---|
| PHASE, JUMP (touch zones) | 0, 1 |
| EV_PHASE, EV_JUMP, EV_LAND, EV_FALL, EV_CRASH, EV_WALL, EV_ORB | 1, 2, 4, 8, 16, 32, 64 |
| CELL | 80.0 |
| PLAYER_X, GROUND_Y, FAIL_Y | 320.0, 560.0, 680.0 |
| SPEED_START, SPEED_RAMP, SPEED_MAX | 280.0, 4.0, 440.0 |
| GOAL_DIST, GOAL_CELLS, TOTAL_CELLS, START_CELLS | 14400.0, 180, 210, 8 |
| ZONE_CELLS | [37, 80, 127] |
| RUN_MIN, RUN_MAX | [6, 6, 5, 6], [9, 9, 8, 8] |
| BRIDGE_CELLS | [3, 2, 2, 1] |
| JUMP_V, GRAVITY, AIR_TIME | -900.0, 2600.0, 0.6923 |
| COYOTE, JUMP_BUFFER, PHASE_COOLDOWN | 0.10, 0.10, 0.15 |
| INVULN | 1.2 |
| ORB_REACH | 100.0 |
| HINT_LOOK | 240.0 |
| GRACE_END, HINTS_END, JUMP_AT, WALLS_AT, TOP_AT | 10.0, 30.0, 10.0, 20.0, 30.0 |
| DIFFICULTY_OFFSET | 30.0 |
| CELL_PTS, ORB_PTS, STREAK_PTS, STREAK_CAP, WALL_PTS, LIFE_BONUS | 2, 20, 2, 10, 15, 150 |
| PITCH_STEP, PITCH_MAX | 0.04, 1.5 |
| BOT_PHASE_LOOK, BOT_MIN_LEAD | 44.0, 8.0 |
| LOOP_A, B_TRANSPOSE | as above, 5 |

**game.gd tunables:** palette Colors; `LIVES = 3`; `INTRO_TIME = 0.6`; `PLAYER_SIZE = 48.0`; `PHASE_PAD = Rect2(170, 616, 300, 96)`, `JUMP_PAD = Rect2(810, 616, 300, 96)`; `PAD_DOWN_PX = 6.0`, `PAD_DOWN_TIME = 0.1`; `SQUASH_TIME = 0.12`; `PHASE_FX_TIME = 0.2`; `FAIL_TINT_TIME = 0.2`; `LIFE_FLASH_TIME = 0.4`; `WALL_FLASH_TIME = 0.15`; `BANNER_TIME = 1.2`; `LOOP_VOL = 0.09`, `LOOP_BPM = 128.0`, `LOOP_RESTART_DELAY = 0.5`; `SHAKE_SOFT = 4.0`, `SHAKE_HARD = 14.0`, `HITSTOP = 0.06`.

**State (game.gd):** `rng`, `course`, `body`, `intro`, `t`, `dist`, `last_cell`, `score`, `streak`, `lives`, `air_t`, `jump_req`, `phase_req`, `pad_t[2]`, `squash_t`, `squash_kind`, `phase_fx_t`, `phase_old_world`, `wall_flash_c`, `wall_flash_t`, `fail_tint_t`, `life_flash_t`, `banner_text`, `banner_t`, `last_phase_name`, `loop_restart_t`.
- `begin()`: reset ALL state (Arcade calls it on every retry and autoplay restart); `rng.randomize()`; `course = Rules.build_course(rng, difficulty)`; `body = Rules.Body.new()`; blips at 0.0 / 0.3; at intro end `Synth.loop(Rules.loop_notes(1), ...)`, `t = 0`.
- `difficulty` is read only through `Rules.ramp_time` and `Rules.build_course`.

## Autoplay bot (how it plays; must reach finish() within 60 s)
Deterministic, pure, and the same code the selftest simulates: `Rules.bot_input(b, course, x, v) -> int` (bit 1 = jump, bit 2 = phase), called every frame in step 3 above, and its flags go through the same `Rules.step` as the player's keys and taps. It never reads `rng`.
- **Phase:** `need = need_world(course, cell_of(x + BOT_PHASE_LOOK))` (44 px ahead). If `need != 0 and need != b.world`: phase. (Bridges and the cell before a wall are at least 1 cell = 80 px of both-world floor, so 44 px ahead always fires on a safe cell; over a cross gap it fires in mid-air. If `phase_cd` blocks it, it simply asks again next frame.)
- **Jump (one hole ahead):** if `b.grounded or b.coyote > 0`: `h = next_hole(course, x)`; if `h.x >= 0`: `to_hole = h.x * CELL - x`, `span = v * AIR_TIME - h.y * CELL` (air distance minus the hole), `lead = max(BOT_MIN_LEAD, span / 2.0)` (lands `lead` px past the hole, centring the arc). It also looks at the hole after that one: `h2 = next_hole(course, (h.x + h.y) * CELL)`; if there is one, `after = h2.x * CELL - (h.x + h.y) * CELL`, `lead2 = max(BOT_MIN_LEAD, (v * AIR_TIME - h2.y * CELL) / 2.0)` and `lead = clamp(lead, BOT_MIN_LEAD, max(BOT_MIN_LEAD, after - lead2))`, so it lands early enough to take off for the next hole. Jump when `to_hole <= span - lead`.
- The bot never fails (the selftest proves it on 20 seeds per difficulty), so it **wins**, and because the round ends by distance, it calls `finish(score, true)` at t = 40.0 s, i.e. about **40.6 s of game time** (about frame 2440 of the 3600 the gate allows; difficulty 1: about 33.8 s). Not randomised, so `check.sh` cannot flake on time.
- It collects every orb on its path (orbs are on the runs it must stand on) and passes every wall, so `streak` climbs and the shift pitch rises audibly.
- Shots: frame 240 (4.0 s, t = 3.4 s, dist about 975, cell 12): the player is cyan (phased into world B at about t = 2.1 s) on the first cyan run, violet outlines and the grey start platform visible, score about 50-120. Frame 900 (15.0 s, t = 14.4 s, dist about 4450, cell 55): zone 1, at least one hole visible on screen or just passed, score above 300, three lives, progress bar about 30%.

## Acceptance checklist (testable items)
1. `timeout 170 ./scripts/check.sh phaseshift` prints `PASS`; the autoplay log shows `ARCADE finished phaseshift` with `won` true, at about 40.6 s of game time (well under the 3600 frames). Run headless autoplay 3 times (`$GODOT --headless --path . --fixed-fps 60 --quit-after 3600 -- --game=phaseshift --autoplay`): each finishes, won, between frames 2380 and 2560.
2. **selftest, ramp and zones:** `ramp_time(0.0, 1) == 30.0`; `speed(0) == 280`, `speed(10) == 320`, `speed(40) == 440`, `speed(1000) == 440`; `absf(dist_at(40.0, 0) - 14400.0) < 0.01`; `zone_at(36, 0) == 0`, `zone_at(37, 0) == 1`, `zone_at(80, 0) == 2`, `zone_at(127, 0) == 3`, `zone_at(0, 1) == 3`; `phase_name(5) == ""`, `phase_name(15) == "JUMP"`, `phase_name(25) == "WALLS"`, `phase_name(35) == "TOP SPEED"`; `is_grace(9.9)` and not `is_grace(10.0)`; `hints_on(29.9)` and not `hints_on(30.0)`.
3. **selftest, course invariants** (30 seeds x difficulty 0 and 1): every invariant listed under Course generation holds; at difficulty 0 each course has at least one hole cell and at least one wall; at difficulty 1 at least one cross gap (a hole stretch with ground 1 on one side and 2 on the other).
4. **selftest, physics step** (on hand-built courses): (a) all-3 floor: a jump gives `EV_JUMP`, `vy == JUMP_V`, and `EV_LAND` comes 40-43 frames later at dt 1/60; (b) floor all 1, body in world 2: no `EV_FALL` for the first 6 frames (coyote), `EV_FALL` within 30 frames; (c) same, but phase on frame 3: never `EV_FALL` in 60 frames; (d) wall 1 on cell 2, body world 1, walking in: `EV_CRASH`; body world 2: `EV_WALL` once, no crash; (e) two phase requests 6 frames apart: only one `EV_PHASE`; (f) `fit_world` and `rescue` put the body in the right world.
5. **selftest, the bot:** for seeds 1-20 and difficulty 0: `sim_bot_round(seed, 0)` returns `fails == 0`, `won == true`, `time` in 39.7-40.3, `phases >= 15`, `orbs >= 20`; for difficulty 1: `fails == 0`, `won`, `time` in 32.9-33.5. Scoring: `orb_points(0) == 20`, `orb_points(100) == 40`, `shift_pitch(100) == 1.5`, `final_score(1000, 2) == 1300`; `loop_notes(2)[0] == 50`, `loop_notes(2)[1] == 0`; `touch_zone(Vector2(639, 300)) == PHASE`, `touch_zone(Vector2(640, 300)) == JUMP`.
6. **Shot `start`:** BG with the TRACE grid; the grey start platform under a violet player square at x 320 on y 560; cyan floor outlines ahead (faint, unfilled); the PHASE pad (two overlapping squares) and JUMP pad (up triangle), no text on them; score `0`, three violet life squares and the progress bar at top centre; nothing in the corners (x < 150 or x > 1100, y < 70).
7. **Shot `play-240`:** the player is cyan on solid cyan floor; violet runs ahead drawn as outlines; score above 0.
8. **Shot `play-900`:** a hole in the floor on screen or the progress bar about 30% with score above 300; three lives; HUD text at least 28 px; only palette colours; no empty glyph boxes.
9. **Code read (grep `games/phaseshift`):** `Synth.sfx("shift", Rules.shift_pitch(streak))` and a `Synth.loop(Rules.loop_notes(` call both in the EV_PHASE branch; `Synth.loop(` uses `128.0, "saw"`; no `"win"` / `"lose"` sfx; `difficulty` used only via `Rules.ramp_time` and `Rules.build_course`; exactly one `finish(` with `true` and one with `false`; the bot path goes through `Rules.bot_input` and `Rules.step` (no direct writes to `body.world` or `body.vy` in game.gd outside `Rules.rescue`); no `InputEventScreenTouch` / `InputEventScreenDrag`; Esc, P and M are not read.
10. **Juice wired:** for each row of the Juice table, the named state variable is assigned in the named trigger and read in a draw function (grep both); `Juice.flash`, `Juice.shake`, `Juice.hitstop`, `Juice.burst` and `Juice.popup` each appear in game.gd.
11. **Touch:** a press at (300, 300) phases in that frame (pad lights); a press at (1000, 300) jumps; a press on the HUB or SOUND button does neither.

## Out of scope
- Variable jump height, double jump, slopes, raised platforms or multiple floor heights; enemies; anything that scrolls vertically.
- Player-controlled speed, a level select, hand-made levels (the course is generated per round from the zone table).
- A third world, or phasing that changes anything except which world is solid.
- Tutorial text, READY screens, per-game menus; any file assets (everything is `_draw()` and Synth).
- Symbols on screen: no arrow glyphs (the JUMP pad draws a triangle).
- Gamepad support (a free bonus at most).
