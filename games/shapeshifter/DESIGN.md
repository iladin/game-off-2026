# Shapeshifter

<!-- Written by the Game Designer before any code. The Gameplay Engineer builds exactly this. -->
<!-- R0001, slate slot 1, sense SHAPE. Accent #FF5FA2. Budget: about 30 min, under ~600 lines of GDScript. -->

## Pitch
You fly down a dark circuit-board tunnel as a glowing pink shape. Walls rush at you out of the vanishing point, each with one hole: a circle, a triangle or a square. Become the shape of the hole before the wall reaches you and you pop straight through; stay the wrong shape and you smash into it. Three lives, one tunnel, 75 seconds to the exit.

## How it uses SHIFT
SHIFT = **shape-shifting**, and it is the only verb. Every input changes what you ARE, never where you are: you do not steer or dodge, you shift. Every shape change plays `Synth.sfx("shift")` with pitch `1.0 + 0.04 * streak` (max 1.5), so a long streak sounds like it is climbing. From 40 s the walls shift too: MORPH walls change their hole once in flight, so the player has to shift late, not early.

## Core loop
Every 1 to 2.6 s (it speeds up):
1. A wall appears small at the vanishing point; its hole outline (accent) tells you the shape you need.
2. Decide which of the three shapes it is and press its key or button (one press, in the same frame the player morphs and `shift` plays).
3. The wall swells and arrives. Match = you pass through (+points, streak up). Mismatch = crash (life lost, streak to 0).

The decision inside it: which shape, and WHEN to commit. From 20 s a DOUBLE pair arrives 0.65 s apart (two shifts in a row, read the second wall through the first one's hole); from 40 s a MORPH wall swaps its hole halfway, so committing early can be wrong. Every wall's hole is a different shape from the wall before it, so every wall needs a shift.

## Controls (keyboard AND touch)
| Shape | Keyboard | Touch / mouse |
|---|---|---|
| CIRCLE (0) | Left or A | tap the left button (or anywhere in the left column, x < 510) |
| TRIANGLE (1) | Up or W | tap the middle button (or anywhere in the middle column, 510 <= x < 770) |
| SQUARE (2) | Right or D | tap the right button (or anywhere in the right column, x >= 770) |

- Three drawn shape buttons along the bottom: each 220 x 120 px, centres x = 380 / 640 / 900, top y = 586 (rects x 270-490, 530-750, 790-1010, y 586-706). The whole screen column above a button also counts, so a thumb can't miss.
- Keys: read `InputEventKey` with `pressed and not echo`, match `keycode` against KEY_LEFT/KEY_A, KEY_UP/KEY_W, KEY_RIGHT/KEY_D. Down/S and everything else do nothing.
- Touch: read `InputEventMouseButton` (pressed, MOUSE_BUTTON_LEFT) only. `project.godot` has `emulate_mouse_from_touch=true`, so a tap arrives as a mouse click; do NOT also handle `InputEventScreenTouch` (it would fire twice).
- All input in `_unhandled_input` (so Arcade's HUB and SOUND buttons get their clicks first). Never Esc, P or M. Ignore input when `autoplay`, `is_finished()` or during the 0.6 s intro.
- Pressing the shape you already are: no shift; a small 1.1x squash and `blip` at pitch 0.9 (every press answers).
- Touch alone can earn the same score as keys: the same `_select_shape()` handles both.

## Round: fail / win, score
- **Lives:** 3, drawn as accent squares at top centre.
- **Crash:** a wall arrives (progress p >= 1.0) while `player_shape != wall.shape`. Costs 1 life, streak = 0. **Exception, the warm-up grace:** while ramp time r < 10 s a mismatch is only a soft fail (no life lost, streak = 0). So the first 10 s cannot be lost.
- **Lose:** lives reach 0: call `finish(score, false)` at once (in the same frame as the crash effects).
- **Win ("cleared", sets the SHAPE bit in the hub):** reach the tunnel exit, i.e. ramp time r >= ROUND_TIME (75 s), with at least 1 life left. Call `finish(score + LIFE_BONUS * lives, true)`. `won` is true in exactly this case and false in every other finish. (At `difficulty >= 1` the ramp starts at 30 s, so the exit comes after 45 s of play.)
- **Score:** each wall passed: `streak += 1`, then `+BASE_POINTS * multiplier(streak)` with `multiplier = min(1 + streak / 5, 4)` (integer division): x1 for streak 1-4, x2 for 5-9, x3 for 10-14, x4 from 15. Exit bonus: +50 per life left. A clean win scores about 1,500 to 1,700; a typical loss 150-600.
- **Typical length:** a new player loses around 35-55 s; a good player reaches the exit at 75 s. Hard cap 75 s (+0.6 s intro).
- `finish()` is called exactly once (the base class guards it; still return right after calling it). No game-over screen; never call `Synth.sfx("win")` or `"lose"`.

## Ramp (with numbers)
Ramp time `r = elapsed + (30.0 if difficulty >= 1 else 0.0)`, where `elapsed` counts from the end of the 0.6 s intro. Everything below is a pure function of r in `rules.gd`.

| Quantity | Formula | r=0 | r=20 | r=40 | r=60 | r=72 | Clamp |
|---|---|---|---|---|---|---|---|
| `travel_time(r)`: spawn to arrival, s | `(3.0 - 0.025 r) * rush` | 3.00 | 2.50 | 2.00 | 1.28 | 1.10 | min 1.10 |
| `spawn_gap(r)`: between spawns, s | `(2.6 - 0.022 r) * rush` | 2.60 | 2.16 | 1.72 | 1.09 | 0.95 | min 0.95 |
| `double_chance(r)` | 0 / 0.35 / 0.50 | 0 | 0.35 | 0.35 | 0.50 | 0.50 | from 20 s; 0.5 from 60 s |
| `morph_chance(r)` | 0 / 0.35 | 0 | 0 | 0.35 | 0.35 | 0.35 | from 40 s |

`rush = RUSH_MULT (0.85) if r >= 60 else 1.0`.

**Phases** (`Rules.phase(r)`), something new every 20 s:
| r | Phase | What is new | Banner (40 px accent, 1.2 s) |
|---|---|---|---|
| 0-10 | WARM-UP | slow walls (3.0 s travel, 2.6 s apart), grace (no lives lost), the matching button glows for the first 3 walls, key labels shown | none |
| 10-20 | RUN | lives count now; the ramp keeps tightening | none |
| 20-40 | DOUBLE | 35% of spawns are a pair: the second wall spawns DOUBLE_GAP = 0.65 s after the first, same travel time, a different shape from the first. The next spawn after a pair waits `spawn_gap(r)` from the second wall | `DOUBLE` |
| 40-60 | MORPH | 35% of single walls are MORPH walls: at p = 0.5 the hole changes once to another shape (it may become the shape you already are). The pair walls of a DOUBLE are never MORPH walls | `MORPH` |
| 60-75 | RUSH | travel and gap x0.85, doubles 50%, the music restarts 5 semitones up and slightly louder, the speed rings turn accent | `RUSH` |
| 73-75 | EXIT | no spawns once `r + travel_time(r) > ROUND_TIME - 1.0`; a GOOD exit square grows from the vanishing point over the last 2 s | none |
| 75 | | `finish(score + 50 * lives, true)` | |

Banners fire only on crossing a boundary (so at `difficulty >= 1`, starting at r = 30, no DOUBLE banner; MORPH fires 10 s in). At most 3 words of instruction ever: the key labels LEFT / UP / RIGHT show only while `elapsed < 10`, and banners start at r = 20.

**Shape picking:** `Rules.next_shape(prev, roll)` with `roll = randi() % 2` returns `(prev + 1 + roll) % 3`, never `prev`. The first wall's `prev` is the player's start shape (CIRCLE), so wall 1 needs a shift. A MORPH wall's new hole is `next_shape(current_hole, roll)`.

## Look (palette hex + how each thing is drawn, per studio/VISION.md)
Colours: BG `#0B0E14`, PANEL `#151A24`, TRACE `#1E2738`, DIM `#6B7489`, INK `#E8ECF4`, ACCENT `#FF5FA2`, GOOD `#FFD34D` (popups, exit), BAD `#FF3B5C` (fails, warnings). Nothing else.

Vanishing point / player centre `VP = (640, 300)`.

**One radial function draws everything round-ish.** Every shape is described by its radius along a ray at angle `a` from its centre: `Rules.shape_radius(shape, a, R)` (R = circumradius). CIRCLE: R. TRIANGLE: regular 3-gon, a vertex pointing up (`a0 = -PI/2`). SQUARE: axis-aligned 4-gon (`a0 = PI/4`). For an n-gon: `seg = TAU / n; phi = fposmod(a - a0, seg) - seg / 2; r = R * cos(PI / n) / cos(phi)`. Rays: `N_RAYS = 48`, `a_i = TAU * i / 48`, which lands exactly on every triangle and square corner (and 24 would too, as a perf fallback). Morphing between two shapes = lerp the two radii per ray.

- **BG:** fill BG; 1 px TRACE grid at 40 px pitch over the whole screen (the house motif).
- **Tunnel:** 4 lines, 2 px TRACE, from the four screen corners to VP. Speed rings: 6 rectangle outlines (2 px TRACE; accent at alpha 0.35 in RUSH) centred on VP with half-size `(640, 360) * wall_scale(fract(ring_phase + k / 6.0))`; `ring_phase += delta / travel_time(r)`.
- **Wall:** progress `p = age / travel`, drawn scale `s = wall_scale(p) = lerp(0.06, 1.0, pow(p, 1.7))`. Body = a square of half-size `660 * s` around VP with the hole cut out, built per ray: inner point `I_i = VP + dir(a_i) * shape_radius(hole, a_i, SHAPE_R[hole] * 1.15) * s`, outer point `O_i = VP + dir(a_i) * square_radius(a_i, 660 * s)` with `square_radius(a, h) = h / max(|cos a|, |sin a|)`. Fill PANEL with **two triangles per ray step** (`[I_i, O_i, O_i+1]` and `[I_i, O_i+1, I_i+1]`, `draw_colored_polygon` with 3 points each). Never pass one big polygon with a hole: Godot cannot draw that and a failed triangulation prints an error that fails the gate. Outer edge: 2 px TRACE rect outline. Hole outline: closed polyline through the 48 `I_i`, width `max(1.5, 4 * s)`, accent with alpha `0.5 + 0.5 * p`. Fade-in: body alpha `clamp(p / 0.15, 0, 1)`. At full scale the wall covers the whole screen (660 from VP reaches every edge).
- **Warning outline:** when `p > 0.75`: if the player matches, the hole outline is full accent at 6 px; if not, it pulses BAD at 4 Hz.
- **Walls draw far to near** (newest first), so the next wall is visible through the current one's hole. Because the body is a ring, not a filled rect, nothing hides it.
- **Player:** sizes `SHAPE_R = [80, 110, 93]` (circle radius 80, triangle circumradius 110, square circumradius 93 = 132 px side). Holes are 1.15x these, chosen so only the matching shape visibly fits its hole (circle 80 > square hole half-side 76; square 93 > circle hole 92; triangle 110 > circle hole 92; circle 80 > triangle hole apothem 63). Drawn as a triangle fan from VP over the 48 rays (48 triangles, `draw_colored_polygon` 3 points each): glow first (same fan at 1.6x alpha 0.10 and 1.3x alpha 0.25, accent), then fill ACCENT (BAD while fail-tinted), then a 6 px INK closed polyline outline. Scale includes the squash.
- **Passed wall:** after passing, it keeps flying for 0.12 s: scale `1.0 -> 1.6`, alpha `1 -> 0`, drawn AFTER the player (it flies past the camera).
- **Exit light (last 2 s):** GOOD filled rect centred on VP, half-size `(640, 360) * wall_scale(k)`, `k = clamp((r - 73) / 2, 0, 1)`, alpha 0.5, drawn behind the walls.
- **HUD** (all inside x 170-1090; corners x < 150 and x > 1100 above y 70 stay empty):
  - Score: 40 px INK, centred, baseline y 56.
  - Multiplier `X2` / `X3` / `X4`: 28 px ACCENT, left-aligned at x 720, baseline y 56 (only when > 1).
  - Lives: 3 squares 20 x 20 at y 70-90, centres x 608 / 640 / 672: filled ACCENT when alive, 2 px DIM outline when lost (BAD fill for 0.4 s right after losing it).
  - Exit progress: bar x 440-840, y 102-108: TRACE track, ACCENT fill `r / ROUND_TIME`.
  - Banner: 40 px ACCENT, centred, baseline y 160; alpha fades out over the last 0.3 s of its 1.2 s.
  - Buttons (bottom): PANEL fill, 4 px TRACE outline; the icon (the shape at 0.42x player size, centre y 636) in DIM; the button of the current shape gets a 6 px ACCENT outline and an ACCENT icon. Key labels `LEFT`, `UP`, `RIGHT` at 28 px DIM, centred, baseline y 698, only while `elapsed < 10`.
  - Hint glow: for the first 3 walls, while the nearest wall's hole != player shape, its button glows (its rect drawn first, behind the button, at 1.1x in ACCENT alpha `0.25 + 0.2 * sin(TAU * 3 * t)`).
- No READY text: the intro is two blips and a frozen tunnel.

## Sound (Synth presets/tones/loop used, per studio/VISION.md)
| Event | Call |
|---|---|
| Shape change (the verb) | `Synth.sfx("shift", Rules.shift_pitch(streak))`, `shift_pitch = min(1.5, 1.0 + 0.04 * streak)` |
| Press the shape you already are | `Synth.sfx("blip", 0.9)` |
| Wall passed | `Synth.sfx("coin", pow(2.0, mini(streak, 12) / 12.0))` |
| Grace mismatch (soft fail, r < 10) | `Synth.sfx("miss", randf_range(0.92, 1.08))` |
| Crash (life lost) | `Synth.sfx("boom", randf_range(0.95, 1.05))` |
| MORPH wall changes its hole | custom `Synth.tone(990.0, 0.07, "sine", 0.22, 495.0)` (a falling warble; not `shift`, which is only the player's verb) |
| Phase banner | `Synth.sfx("blip", 1.2)` |
| Intro beat | `blip` at 0.0 s and 0.3 s, loop starts at 0.6 s |
| Round end | nothing (Arcade plays `win` / `lose`; never call them) |

**Music:** `Synth.loop(LOOP_NOTES, 132.0, "square", 0.10)`, E minor pentatonic, 16 eighths, driving:
`LOOP_NOTES = [52, 64, 59, 64, 55, 64, 59, 62, 52, 64, 59, 64, 57, 62, 59, 55]`.
RUSH (r >= 60): restart it with every non-zero note +5 and vol 0.12. After a crash: `Synth.stop_loop()`, restart the current loop 0.5 s later (silence is information). At most 3 SFX start in one frame (a pass plays one `coin`; a multiplier-up adds no extra sound).

## Juice list
1. **Shift (every press that changes shape):** logical shape changes this frame; the player morphs (radial lerp old to new over 0.08 s) and squashes 1.25x back to 1.0 over 0.12 s; a ghost outline of the old shape (2 px ACCENT) grows 1.0x to 1.4x and fades over 0.15 s.
2. **Pass:** `Juice.burst(self, VP, ACCENT)` (14), `Juice.popup(self, VP - Vector2(0, 150), "+%d" % pts, GOOD)`, the wall flies past the camera (scale 1.0 to 1.6, alpha to 0, 0.12 s).
3. **Multiplier up (streak reaches 5, 10, 15):** `Juice.flash(Color(1, 1, 1, 0.15), 0.1)`, popup `"X%d" % mult` in GOOD at `VP + Vector2(0, 170)`, `Juice.shake(4)`.
4. **Soft fail (grace mismatch):** player tinted BAD for 0.2 s, `Juice.shake(4)`, the wall shatters (`Juice.burst` DIM at VP) and is removed.
5. **Hard fail (crash):** `Juice.flash(Color(BAD, 0.35), 0.2)`, `Juice.shake(14)`, `Juice.hitstop(0.06)`, `Juice.burst(self, VP, BAD)`, the wall is removed, the lost life square flashes BAD 0.4 s, loop silent 0.5 s.
6. **Warning and speed:** the hole outline pulses BAD (4 Hz) when it is close and you are wrong, and goes solid 6 px ACCENT when you are right; the speed rings run faster as travel time drops and turn accent in RUSH.

## Build plan (scripts, data structures, every tunable with a start value)
Files (target ~570 lines total):
- `rules.gd` (~100 lines, pure: no nodes, no autoloads): constants and static functions below.
- `selftest.gd` (~50 lines): the assertions in the checklist.
- `game.gd` (~270 lines, `extends MicroGame`): state, `begin()`, `_process()` (intro, timers, spawn, advance, morph, judge, bot), `_unhandled_input()`, `_select_shape()`, `_pass()`, `_crash()`, `_draw()` (calls the helpers).
- `tunnel_draw.gd` (~150 lines, `extends RefCounted`, static helpers taking `ci: CanvasItem` and calling `ci.draw_*` from inside `game.gd`'s `_draw()`): `draw_backdrop`, `draw_rings`, `draw_wall`, `draw_shape_fan`, `draw_buttons`, `draw_hud`. Preload it like Rules.

**rules.gd functions:**
`ramp_time(elapsed: float, difficulty: int) -> float`, `phase(r) -> int` (0 WARM-UP, 1 RUN, 2 DOUBLE, 3 MORPH, 4 RUSH), `travel_time(r)`, `spawn_gap(r)`, `double_chance(r)`, `morph_chance(r)`, `can_spawn(r) -> bool` (`r + travel_time(r) <= ROUND_TIME - EXIT_CLEAR`), `is_grace(r) -> bool` (`r < GRACE_END`), `passes(player: int, hole: int) -> bool`, `next_shape(prev: int, roll: int) -> int`, `wall_scale(p: float) -> float`, `shape_radius(shape: int, a: float, r: float) -> float`, `square_radius(a: float, half: float) -> float`, `ray_angle(i: int) -> float`, `multiplier(streak: int) -> int`, `wall_points(streak: int) -> int`, `shift_pitch(streak: int) -> float`, `shape_for_tap_x(x: float) -> int`, `final_score(score: int, lives: int) -> int`.

**rules.gd tunables:**
| Name | Start value |
|---|---|
| CIRCLE, TRIANGLE, SQUARE | 0, 1, 2 |
| ROUND_TIME | 75.0 |
| GRACE_END | 10.0 |
| DOUBLE_AT, MORPH_AT, RUSH_AT | 20.0, 40.0, 60.0 |
| DIFFICULTY_OFFSET | 30.0 |
| TRAVEL_START, TRAVEL_DROP, TRAVEL_MIN | 3.0, 0.025, 1.1 |
| GAP_START, GAP_DROP, GAP_MIN | 2.6, 0.022, 0.95 |
| RUSH_MULT | 0.85 |
| DOUBLE_GAP | 0.65 |
| DOUBLE_CHANCE, DOUBLE_CHANCE_RUSH | 0.35, 0.5 |
| MORPH_CHANCE, MORPH_AT_P | 0.35, 0.5 |
| EXIT_CLEAR | 1.0 |
| SCALE_FAR, SCALE_POW | 0.06, 1.7 |
| SHAPE_R | [80.0, 110.0, 93.0] |
| HOLE_SCALE | 1.15 |
| N_RAYS | 48 |
| BASE_POINTS, MULT_EVERY, MULT_MAX | 10, 5, 4 |
| LIFE_BONUS | 50 |
| PITCH_STEP, PITCH_MAX | 0.04, 1.5 |
| TAP_SPLIT_1, TAP_SPLIT_2 | 510.0, 770.0 |

**game.gd tunables:** palette Colors above; `VP = Vector2(640, 300)`; `LIVES = 3`; `INTRO_TIME = 0.6`; `LOOP_NOTES` (above), `LOOP_BPM = 132.0`, `LOOP_VOL = 0.10`, `LOOP_VOL_RUSH = 0.12`, `RUSH_TRANSPOSE = 5`, `LOOP_RESTART_DELAY = 0.5`; `MORPH_TIME = 0.08` (player), `HOLE_MORPH_TIME = 0.12`; `SQUASH = 1.25`, `SQUASH_TIME = 0.12`, `GHOST_TIME = 0.15`; `FAIL_TINT_TIME = 0.2`; `PASS_OUT_TIME = 0.12`; `FADE_IN_P = 0.15`; `WARN_P = 0.75`; `HINT_WALLS = 3`; `LABEL_TIME = 10.0`; `BANNER_TIME = 1.2`; `WALL_HALF = 660.0`; `RING_COUNT = 6`; `BTN_SIZE = Vector2(220, 120)`, `BTN_X = [380.0, 640.0, 900.0]`, `BTN_TOP = 586.0`; `SHAKE_SOFT = 4.0`, `SHAKE_HARD = 14.0`, `HITSTOP = 0.06`; `BOT_LEAD_MIN = 0.30`, `BOT_LEAD_MAX = 0.70`, `BOT_FUMBLE_EVERY = 4`, `BOT_GIVE_UP = 45.0`.

**State (game.gd):** `elapsed`, `intro`, `player_shape`, `prev_shape` + `morph_k` (player morph), `squash_t`, `ghost_t`, `fail_tint_t`, `score`, `streak`, `lives`, `walls: Array[Wall]`, `next_spawn_at` (elapsed), `pair_pending: bool`, `last_hole` (shape of the last spawned wall's final hole), `walls_spawned`, `ring_phase`, `banner_text`, `banner_t`, `last_phase`, `loop_restart_t`, `life_flash_t`, `bot_walls`, `bot_lead`.

```gdscript
class Wall:
	var shape: int          # the hole now (what you must be at arrival)
	var from_shape: int     # the hole before a morph (for the 0.12 s radial lerp)
	var morph_k: float = 1.0
	var age: float = 0.0
	var travel: float = 3.0
	var morph: bool = false # is a MORPH wall
	var morphed: bool = false
	var judged: bool = false
	var out_t: float = -1.0 # >= 0 while flying past after a pass
	var bot_fumble: bool = false
```

**Per frame (`_process`):** `queue_redraw()`; return if finished. Intro: count down, `blip` at 0.0 and 0.3 s, at 0 start the loop. Then `elapsed += delta`, `r = Rules.ramp_time(elapsed, difficulty)`; phase crossing: banner + `blip` (+ RUSH loop restart). Spawn when `elapsed >= next_spawn_at and Rules.can_spawn(r)`: new Wall (shape `next_shape(last_hole, randi() % 2)`, travel `travel_time(r)`). If `pair_pending`, this is the second wall of a pair: `pair_pending = false`, next spawn after `spawn_gap(r)`, no morph. Else roll `randf() < double_chance(r)`: yes = first wall of a pair (`pair_pending = true`, next spawn after `DOUBLE_GAP`, no morph); no = a single wall (next spawn after `spawn_gap(r)`, `morph = randf() < morph_chance(r)`). Set `last_hole` to the new wall's shape (and update it again if that wall morphs). Advance every wall's age; at `p >= MORPH_AT_P` a MORPH wall morphs once (tone, `from_shape = shape`, `shape = next_shape(shape, roll)`, `morph_k = 0`). Judge the first unjudged wall with `p >= 1.0`: `_pass()` or `_crash()` (soft if `Rules.is_grace(r)`). Remove crashed walls at once and passed walls when `out_t > PASS_OUT_TIME`. Exit: `r >= ROUND_TIME` and lives > 0: `finish(Rules.final_score(score, lives), true)`. Bot last.

**`_select_shape(s: int)`** (keys, taps and the bot all call this): if `s == player_shape`: blip + 1.1x squash; else `prev_shape = player_shape; player_shape = s; morph_k = 0; squash_t = SQUASH_TIME; ghost_t = GHOST_TIME; Synth.sfx("shift", Rules.shift_pitch(streak))`.

## Autoplay bot (how it plays; must reach finish() within 60 s)
- Plays through the exact same `_select_shape()` the key and tap handlers call (as the template's bot calls `_press()`), in `_process` after the simulation step, only when `autoplay`.
- Target = the unjudged wall nearest to arrival. Time to arrival `tta = travel * (1 - p)`. The bot acts once `tta <= bot_lead` (re-rolled per wall, `randf_range(0.30, 0.70)`), and for a MORPH wall only after it has morphed. It selects `wall.shape`, or `(wall.shape + 1) % 3` if the wall is a fumble.
- Fumbles are deliberate so the round ends: at spawn, each wall whose arrival ramp time `r + travel >= GRACE_END` increments `bot_walls`, and every `BOT_FUMBLE_EVERY` (4th) such wall gets `bot_fumble = true`. Backstop: once `elapsed >= BOT_GIVE_UP` (45 s), every wall is a fumble.
- Expected timeline at difficulty 0: arrivals at about 3.0, 5.5, 8.0 s (grace, all passed, so the shots show passes and popups), then 10.4, 12.8, 15.1, 17.4 (fumble 1), ... fumble 3 near 30-34 s (sooner when DOUBLE pairs add walls), so `finish(score, false)` comes at about 31-35 s. Worst case with the backstop: 45 s + 3 walls at about 1.7 s gaps = under 51 s, inside the gate's 3600 frames (60 s). At difficulty 1 it is faster (no grace, shorter gaps).
- `begin()` resets everything (walls, timers, lives, score, streak, bot counters, loop) because Arcade calls it again on every autoplay restart.

## Acceptance checklist (6–10 testable items, incl. 2–4 rules.gd assertions)
1. `./scripts/check.sh shapeshifter` prints `PASS` (glyph lint, import, smoke, autoplay round, selftest); the autoplay log shows `ARCADE finished shapeshifter` within the 3600 frames.
2. **selftest, matching:** `Rules.passes(a, b) == (a == b)` for all 9 pairs of CIRCLE / TRIANGLE / SQUARE, and `Rules.next_shape(p, roll) != p` for every p in 0..2 and roll in 0..1.
3. **selftest, ramp and difficulty:** `travel_time(0) == 3.0`, `travel_time(1000) == TRAVEL_MIN`, `spawn_gap(1000) == GAP_MIN`, `travel_time(60) < travel_time(59.9)` (RUSH applies), `ramp_time(0.0, 1) == 30.0`, `ramp_time(12.0, 0) == 12.0`, `is_grace(9.9)` and not `is_grace(10.0)`.
4. **selftest, feel and geometry:** `shift_pitch(0) == 1.0`, `is_equal_approx(shift_pitch(5), 1.2)`, `shift_pitch(100) == 1.5`; `multiplier(4) == 1`, `multiplier(5) == 2`, `multiplier(99) == 4`; `shape_radius(CIRCLE, 1.0, 50) == 50`, `is_equal_approx(shape_radius(SQUARE, PI / 4, 50), 50)`, `is_equal_approx(shape_radius(SQUARE, 0, 50), 50 * cos(PI / 4))`; `shape_for_tap_x(100) == CIRCLE`, `(640) == TRIANGLE`, `(1200) == SQUARE`.
5. **Shot `start`:** BG with the faint TRACE grid and tunnel lines; a pink (#FF5FA2) circle with a white outline and glow at the centre; three drawn shape buttons (circle, triangle, square) along the bottom with `LEFT`, `UP`, `RIGHT` under them; score `0` at top centre and three pink life squares under it; nothing in the top-left (x < 150) or top-right (x > 1100) corners.
6. **Shot `play-240` (4 s, warm-up):** at least one wall with a clearly readable hole (accent outline) at some depth; the player's shape changes over the shots; the hint glow on a button; score above 0 if the first wall has arrived.
7. **Shot `play-900` (15 s):** walls at two or more depths, the farther one visible through the nearer one's hole; no key labels; HUD text at least 28 px; only palette colours (BG, PANEL, TRACE, DIM, INK, #FF5FA2, GOOD for popups, BAD for fails); no empty glyph boxes.
8. **Code read (grep `games/shapeshifter`):** `Synth.sfx("shift", Rules.shift_pitch(streak))` inside `_select_shape`; `Synth.loop(` with `132.0, "square"` and vol 0.10 / 0.12; no `"win"` or `"lose"` sfx; `difficulty` used only via `Rules.ramp_time`; exactly one `finish(` with `true` (the exit) and one with `false` (lives 0).
9. **Touch:** the button rects are at least 120 px tall (`BTN_SIZE = Vector2(220, 120)`), input uses `InputEventMouseButton` through `Rules.shape_for_tap_x`, and no `InputEventScreenTouch` handler (no double fire); keys Left/Up/Right and A/W/D work, Esc/P/M are untouched.

## Out of scope
- A 4th shape, rotating holes, holes off-centre, or steering/moving the player (the only verb is shifting).
- Geometric collision: a pass is `player_shape == wall.shape` at p >= 1.0, nothing else.
- Per-game title, READY screen, tutorial text, game-over screen, settings, difficulty menu.
- Lives pickups, power-ups, bosses, scrolling score tables, online leaderboards.
- Camera2D, 3D, shaders, textures or any file asset (everything is `_draw()` and Synth).
- Judging against the audio clock (walls are judged by their own progress `p`).
- Gamepad support (a free bonus at most).
