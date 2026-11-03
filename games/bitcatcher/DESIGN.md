# Bit Catcher

<!-- Written by the Game Designer before any code. The Gameplay Engineer builds exactly this. -->
<!-- R0004, slate slot 4, sense BIT. Accent #A3E635. Budget: about 25-30 min, under ~650 lines of GDScript. -->

## Pitch
Your register is a row of 8 cells at the bottom of the screen. Some cells are sockets: outlined in lime, they want a 1. One bit at a time falls down a column. You cannot move the bit: you **bit-shift the register** left or right (it wraps around, a circular shift) so the falling 1 lands in an empty socket. Fill every socket and the byte is done; a new byte appears. Later, 0s fall too, and a 0 that lands on a 1 you already set wipes it. Build 8 bytes to clear the BIT bit.

## How it uses SHIFT
SHIFT = **the bit shift**, done literally: the register and the target are two 8-bit integers, and Left / Right run `rol8` / `ror8` on both of them (rotate left / rotate right). The bits really move, the digits in the cells really change, and the whole puzzle is choosing which way to shift and how far. Shifting is the only way to act on the world (Down only hurries the bit). Every shift plays `Synth.sfx("shift", Rules.shift_pitch(streak))` and the row slides one cell with the end cell wrapping round.

## Core loop
Every 1-3.5 s:
1. A bit tile appears at the top in a random column (0-7) and falls straight down its lane.
2. While hints are on, the register cell under that lane is outlined: lime if the landing would be good, red if it would be bad.
3. Shift the register (1 to 4 presses either way) until a good cell sits under the lane, then optionally press Down to slam it in.
4. It lands: a 1 in an empty socket sets that bit (`reg |= mask`); anywhere else it is WRONG. A 0 landing on a set 1 clears it (LOST BIT); anywhere else it is harmless.
5. When `reg == target` the byte completes, flashes, and the next target appears.

The decision: which empty socket to aim for (the nearest one either way, or the one that keeps the next shot easy), and, once 0s fall, where to park them so they miss your 1s. Because every shift moves all sockets at once, the register is a little ring puzzle, not a catcher you steer.

## Controls (keyboard AND touch)
| Action | Keyboard | Touch / mouse |
|---|---|---|
| Shift left (ROL) | Left or A (`pressed and not echo`) | the LEFT pad `Rect2(170, 600, 300, 112)` fires on press; or tap the left half of the play area (y < 600, x < 640), fires on release |
| Shift right (ROR) | Right or D | the RIGHT pad `Rect2(810, 600, 300, 112)` on press; or tap the right half (y < 600, x >= 640) on release |
| Drop faster | hold Down or S | hold the DROP pad `Rect2(490, 600, 300, 112)`; or swipe down anywhere (drag at least 48 px down with `dy > abs(dx)`) and keep holding |

- Read `InputEventKey` (KEY_LEFT, KEY_A, KEY_RIGHT, KEY_D, KEY_DOWN, KEY_S; press and release for Down/S) and `InputEventMouseButton` / `InputEventMouseMotion` (MOUSE_BUTTON_LEFT) in `_unhandled_input`, so Arcade's HUB / SOUND buttons take their clicks first. `emulate_mouse_from_touch=true`: do NOT also handle `InputEventScreenTouch` / `InputEventScreenDrag` (double fire). Never Esc, P or M.
- **Tap vs swipe in the play area:** on press, store `press_pos` and the zone (`Rules.touch_zone(pos)`), and light that side's pad (pressed look) in the same frame. During motion, if `pos.y - press_pos.y >= SWIPE_PX (48)` and that is larger than `abs(dx)`, it is a swipe: `drop_touch = true`, the tap is cancelled. On release: if not a swipe and the pointer moved under `TAP_SLOP (40)` px, shift that side. Pads never wait: they act on press. `drop_touch` ends on release.
- **Fast drop must be fresh per bit:** at each spawn `fast = false`; it turns on only with a Down/S press, a DROP pad press or a swipe that starts after that spawn. Holding S across a landing does not slam the next bit.
- Shifting works at any time after the intro, including between bits and during the byte pause (sound and slide, nothing lands).
- Ignore input when `autoplay`, `is_finished()`, or during the 0.6 s intro.
- Keys and touch call the same `_shift(dir)` and `_drop()`, so touch alone earns the same score. Every pad is 300 x 112 px; the halves are 640 x 600.

## Round: fail / win, score
- **Lives:** 3, accent squares at top centre.
- **Hard fail (costs a life):** a 1 lands WRONG (on a cell whose target bit is 0, or on a socket already set). The bit shatters and is not stored. **Grace:** while `r < GRACE_END` (10 s) WRONG costs nothing: popup `NOT HERE` in DIM, and every empty socket flashes ACCENT twice (0.3 s) to teach. So the first 10 s cannot be lost.
- **Soft fail (streak reset, no life):** a 0 lands on a set 1 (LOST BIT): that bit is cleared (`reg &= ~mask`), the byte goes back one step.
- **Win (clears the BIT bit):** complete `BYTES_TO_WIN = 8` bytes: `finish(Rules.final_score(score, lives), true)` in the frame the 8th byte completes (no byte pause after it).
- **Lose:** lives reach 0: `finish(score, false)` in the same frame as the hard-fail effects.
- `finish()` exactly once (return right after). Never play `win` / `lose`.
- **Score:** SET +10 plus a streak bonus `2 * min(streak, 10)` (streak before this hit), +5 more if the bit was fast-dropped. Byte complete +100. A harmless 0 landing +5. Round won: +50 per life left. A clean bot round is about 1,700-2,000.
- **Typical length:** about 24 ones and 4 zeros. A player who never drops fast: about 75 s. With fast drops: about 50 s. The bot: about 35 s. A losing round ends sooner. At difficulty 1 (4 ones per byte from the start) the bot takes about 46 s.

## Ramp (with numbers)
Round time `t` counts from the loop start (end of intro). Ramp time `r = t + (DIFFICULTY_OFFSET 30.0 if difficulty >= 1 else 0.0)`. A bit's fall speed is sampled at its spawn; a byte's number of ones is sampled when the byte is made.

| Quantity (rules.gd) | r 0-10 | 10-20 | 20-30 | 30-40 | 40+ |
|---|---|---|---|---|---|
| `fall_time(r)` (s, spawn to land at normal speed) | 3.0 (73 px/s) | 2.4 (92) | 2.1 (105) | 1.8 (122) | 1.5 (147, clamp) |
| `spawn_gap(r)` (s after a landing) | 0.45 | 0.45 | 0.30 | 0.30 | 0.30 |
| `ones_for(r)` (sockets per byte) | 2 | 3 | 3 | 4 | 4 |
| `zero_chance(r)` | 0 | 0 | 0.25 | 0.25 | 0.30 (clamp) |
| `hints_on(r)` (landing-cell outline) | yes | yes | yes | no | no |
| `is_grace(r)` | yes | no | no | no | no |
| `phase_name(r)` banner | `""` | `FASTER` | `ZEROS` | `NO HINTS` | `TOP SPEED` |

- Fall distance `FALL_PX = LAND_Y - SPAWN_Y = 440 - 220 = 220` px; `fall_speed(r) = FALL_PX / fall_time(r)`. Fast drop: `FAST_SPEED = 1300` px/s (a 220 px fall in 0.17 s).
- At most one bit is in the air. The next spawns `spawn_gap(r)` after a landing, or after the byte pause (`BYTE_PAUSE = 0.5` s) when the landing completed a byte. The first bit of the round spawns at `t = 0.3`.
- Columns: uniform random 0-7, never the same column three times in a row. **The first bit of the round** spawns over a socket at the starting rotation, so doing nothing at all lands it (the game teaches itself).
- A bit is a 0 with `zero_chance(r)`, never two 0s in a row, and never while `reg == 0` (nothing to lose yet, so the 0 is pointless).
- Targets: `Rules.make_target(ones_for(r), prev_target, rng)`: exactly that many 1s at random cells, never equal to the previous target. A new byte sets `reg = 0`.
- Banners show when `phase_name(r)` differs from the last shown (start `""`), so at difficulty 1 `NO HINTS` shows at once.
- Worst case for a human: 4 shifts take well under the 1.5 s top-speed fall.

## Look (palette hex + how each thing is drawn, per studio/VISION.md)
Colours: BG `#0B0E14`, PANEL `#151A24`, TRACE `#1E2738`, DIM `#6B7489`, INK `#E8ECF4`, ACCENT `#A3E635`, GOOD `#FFD34D`, BAD `#FF3B5C`. Nothing else.

Screen map (1280 x 720):
| y | Band |
|---|---|
| 0-120 | HUD: score, lives, byte counter (x 170-1090 only) |
| 128-176 | banner |
| 180-470 | the fall: bit centres from `SPAWN_Y = 220` to `LAND_Y = 440` |
| 480-580 | the register: 8 cells |
| 600-712 | LEFT, DROP and RIGHT pads |

- **BG:** fill BG; 1 px TRACE grid at 40 px pitch.
- **Columns:** `CELL_W = 100`, `CELL_GAP = 12`, pitch 112, `COL_X0 = 198` (left edge of column 0), so column centre `col_x(c) = 248 + 112 c` (248 to 1032). A 1 px TRACE lane line at each column centre from y 180 to 480.
- **Register frame:** a PANEL rect x 186-1094, y 470-590 with a 2 px TRACE outline (the row's backplate); 2 px TRACE bus line from x 186 to 1094 at y 596 with small INK dots (4 x 4) travelling right at 120 px/s every 112 px (house motif, echoes the hub).
- **Cells** (100 x 100, top y 480, at `col_x(c) - 50`), drawn from the bits of `reg` and `target` at column c (`Rules.bit_at(x, c)`):
  - plain (target 0): PANEL fill, 2 px TRACE outline, `0` 48 px DIM centred.
  - empty socket (target 1, reg 0): PANEL fill, 4 px ACCENT outline at alpha `0.55 + 0.45 sin(TAU * 2 t)`, `0` 48 px DIM, a 6 px ACCENT bar along the cell bottom.
  - set (target 1, reg 1): ACCENT fill, `1` 56 px in BG colour, glow (rect at 1.3x alpha 0.25, 1.6x alpha 0.10).
  - just-cleared by a 0: BAD outline 0.2 s.
- **Shift slide:** the integers rotate at once; only the drawing eases. After ROL every cell at column c came from column c+1, so draw every cell at `x + slide_px` with `slide_px` starting at +112 (ROL) or -112 (ROR) and easing to 0 over `SLIDE_TIME = 0.10` s (ease out cubic); `prog` goes 0 to 1. The wrapped cell (`wrap_col` = 7 after ROL, 0 after ROR) slides in from just outside the frame at alpha `prog`, and a ghost copy of it is drawn at `x + slide_px - 896` (ROL) or `x + slide_px + 896` (ROR), sliding out of the other end at alpha `1 - prog`. No clipping API needed.
- **Falling bit:** 80 x 80 square centred at `(col_x(col), y)`. A 1: PANEL fill, 4 px ACCENT outline, `1` 56 px INK, glow. A 0: PANEL fill, 2 px DIM outline, `0` 56 px DIM. Fades in over 0.15 s. Fast: 3 ghost copies 24, 48, 72 px above at alpha 0.30, 0.20, 0.10.
- **Hint** (while `hints_on(r)` and a bit is falling): the lane under the bit drawn as a 4 px line (ACCENT for a good landing, BAD for a bad one) at alpha 0.5 from the bit to the cell, and that cell's outline 6 px in the same colour, pulsing at 3 Hz. Good = `Rules.land_one(...) == SET` for a 1, `Rules.land_zero(...) == DODGE` for a 0.
- **Pads:** PANEL fill, 4 px TRACE outline. LEFT: a filled INK triangle pointing left (48 wide, 56 tall) centred; RIGHT: mirrored; DROP: a triangle pointing down (56 wide, 48 tall). Pressed (0.1 s after a shift, or while the drop is held): offset +6 px down, ACCENT fill, triangle in BG colour. No text on pads.
- **HUD** (x 170-1090; nothing at x < 150 or x > 1100 above y 70):
  - Score 40 px INK centred, baseline y 56.
  - Lives: 3 squares 20 x 20 at y 66-86, centres x 608 / 640 / 672: ACCENT alive, 2 px DIM outline when lost (BAD fill 0.4 s right after).
  - Byte counter: 8 digits at 28 px, centred at y 112 (baseline), letter spacing 22 px, reading `Rules.bytes_string(bytes_done)`: `1` per finished byte in GOOD, `0` in DIM (for example `11100000`). This mini register is the round's progress bar.
  - Banner 40 px ACCENT centred, baseline y 168, 1.2 s, fades over the last 0.3 s.
- No READY text, no other instructions. The only words ever on screen: the banners and the popups below.

## Sound (Synth presets/tones/loop used, per studio/VISION.md)
| Event | Call |
|---|---|
| Any shift (the verb) | `Synth.sfx("shift", Rules.shift_pitch(streak))`, `shift_pitch = min(1.5, 1.0 + 0.04 * streak)` |
| Fast drop starts | `Synth.tone(520.0, 0.08, "triangle", 0.18, 260.0)` (a short whoosh down) |
| A 1 is SET | `Synth.sfx("coin", pow(2.0, mini(streak, 12) / 12.0))` (streak before the hit) |
| Byte complete | also `Synth.tone(1047.0, 0.16, "square", 0.30, 2093.0)` |
| A 0 lands harmless | `Synth.sfx("blip", randf_range(0.66, 0.74))` |
| LOST BIT (0 on a 1) / grace WRONG | `Synth.sfx("miss", randf_range(0.92, 1.08))` |
| WRONG (life lost) | `Synth.sfx("boom", randf_range(0.95, 1.05))`; `Synth.stop_loop()`, restart after 0.5 s |
| Round intro | `blip` at 0.0 and 0.3 s; loop starts at 0.6 s and `t` starts at 0 that frame |
| Round end | nothing (Arcade plays `win` / `lose`) |

**Music:** `Synth.loop(LOOP_NOTES, 120.0, "square", 0.09)`, A minor pentatonic, staccato (a rest after every note): `LOOP_NOTES = [57, 0, 64, 0, 60, 0, 57, 0, 62, 0, 64, 0, 67, 0, 64, 0]`. At `TOP SPEED` (r >= 40) restart it with every note +12. At most 3 sounds in one frame: the worst case (a SET that completes a byte, with a shift that frame) starts 3.

## Juice list
1. **Every shift:** the row slides 112 px with the wrap copy (0.10 s), the pressed pad drops 6 px and fills ACCENT for 0.1 s; same frame as the `shift` sound.
2. **SET:** the cell squashes 1.25x then back over 0.12 s; `Juice.burst(self, cell_centre, ACCENT)` (14); `Juice.popup(self, cell_centre - Vector2(0, 70), "+%d" % pts, GOOD)`.
3. **Byte complete:** all 8 cells flash GOOD for 0.15 s, `Juice.flash(Color(1, 1, 1, 0.15), 0.1)`, `Juice.shake(4)`, popup `BYTE` 40 px GOOD at (640, 400); the new byte digit in the HUD squashes 1.25x. Then the new target's sockets pop in (outline scale 0.6 to 1.0, ease out back, 0.2 s).
4. **Fast drop:** ghost trail on the bit; on landing a 2 px INK ring around the cell for 0.1 s and `Juice.shake(4)` only if it was a SET.
5. **Soft fail (LOST BIT):** the cell outline BAD 0.2 s, `Juice.shake(4)`, popup `LOST BIT` BAD, the 0 tile tinted BAD 0.2 s.
6. **Hard fail (WRONG after grace):** `Juice.flash(Color(BAD, 0.35), 0.2)`, `Juice.shake(14)`, `Juice.hitstop(0.06)`, `Juice.burst(self, cell_centre, BAD)`; popup `WRONG` BAD; the lost life square flashes BAD 0.4 s; music silent 0.5 s.

## Build plan (scripts, data structures, every tunable with a start value)
Files (target ~620 lines, each under 300):
- `rules.gd` (~150 lines, pure: no nodes, no autoloads; `RandomNumberGenerator` passed in is fine): constants and static functions below.
- `selftest.gd` (~70 lines): the assertions in the checklist.
- `game.gd` (~260 lines, `extends MicroGame`): state, `begin()`, `_process()` (intro, spawn, fall, land, byte pause, loop restart, bot), `_unhandled_input()`, `_shift(dir)`, `_drop()`, `_land()`, `_hard_fail(c)`, `_draw()` calling the helpers.
- `bits_draw.gd` (~150 lines, `extends RefCounted`, static helpers taking `ci: CanvasItem`; preload like Rules): `draw_backdrop(ci, t)`, `draw_register(ci, reg, target, slide_px, slide_prog, wrap_col, squash_c, squash, flash_t, bad_c, t)`, `draw_bit(ci, pos, is_one, alpha, tint, fast)`, `draw_hint(ci, col, bit_y, good, t)`, `draw_pads(ci, down_l, down_d, down_r)`, `draw_hud(ci, score, lives, life_flash, bytes_done, banner, alpha)`.

**Data:** `reg: int` and `target: int` (0-255). Column c (0 = left) reads bit `7 - c`: `col_mask(c) = 1 << (7 - c)`, so at any moment the cell digits read left to right are exactly `bits_string(reg)`. Shift left = `reg = rol8(reg); target = rol8(target)`; shift right = `ror8` on both. No separate rotation offset. The falling bit: `bit_col: int`, `bit_y: float`, `bit_one: bool`, `bit_speed: float`, `bit_alive: bool`, `fast: bool`.

**rules.gd functions:** `ramp_time(t: float, difficulty: int) -> float`; `rol8(x: int) -> int` (`((x << 1) | (x >> 7)) & 0xFF`); `ror8(x: int) -> int` (`((x >> 1) | (x << 7)) & 0xFF`); `rotate8(x, d) -> int` (d > 0: d RORs, d < 0: -d ROLs); `col_mask(c) -> int`; `bit_at(x, c) -> int`; `popcount8(x) -> int`; `land_one(reg, target, c) -> int` (SET if target bit 1 and reg bit 0, else WRONG); `land_zero(reg, c) -> int` (LOST if reg bit 1, else DODGE); `apply_one(reg, c) -> int`; `apply_zero(reg, c) -> int`; `make_target(ones, prev, rng) -> int`; `best_shift(reg, target, c, is_one) -> int` (the d in -4..4 with the smallest `abs(d)` whose `land_*` on `rotate8(reg, d)`, `rotate8(target, d)` is SET / DODGE; ties prefer the negative d; 0 if none); `fall_time(r)`, `fall_speed(r)`, `spawn_gap(r)`, `ones_for(r)`, `zero_chance(r)`, `hints_on(r)`, `is_grace(r)`, `phase_name(r)`; `hit_points(streak, fast) -> int`; `shift_pitch(streak) -> float`; `final_score(score, lives) -> int`; `bits_string(x) -> String` (8 chars of `0`/`1`, MSB first); `bytes_string(n) -> String` (n ones then zeros, 8 chars); `touch_zone(pos: Vector2) -> int` (y >= 600: x < 480 LEFT, x < 800 DROP, else RIGHT; y < 600: x < 640 LEFT, else RIGHT); `col_x(c) -> float`.

**rules.gd tunables:**
| Name | Start value |
|---|---|
| LEFT, RIGHT, DROP | 0, 1, 2 |
| SET, WRONG, DODGE, LOST | 0, 1, 2, 3 |
| CELLS | 8 |
| COL_X0, CELL_W, CELL_GAP, CELL_PITCH | 198.0, 100.0, 12.0, 112.0 |
| REG_Y | 480.0 |
| SPAWN_Y, LAND_Y | 220.0, 440.0 |
| FALL_TIMES | [3.0, 2.4, 2.1, 1.8, 1.5] by 10 s band |
| FAST_SPEED | 1300.0 |
| SPAWN_GAPS | 0.45 (r < 20), 0.30 |
| ONES | 2 (r < 10), 3 (r < 30), 4 |
| ZERO_AT, ZERO_CHANCES | 20.0, 0.25 (r < 40), 0.30 |
| HINTS_END, GRACE_END | 30.0, 10.0 |
| FAST_AT, TOP_AT | 10.0, 40.0 |
| DIFFICULTY_OFFSET | 30.0 |
| BYTES_TO_WIN | 8 |
| SET_PTS, STREAK_PTS, STREAK_CAP, FAST_PTS, BYTE_PTS, DODGE_PTS, LIFE_BONUS | 10, 2, 10, 5, 100, 5, 50 |
| PITCH_STEP, PITCH_MAX | 0.04, 1.5 |
| PAD_Y, PAD_SPLIT_L, PAD_SPLIT_R | 600.0, 480.0, 800.0 |

**game.gd tunables:** palette Colors; `LIVES = 3`; `INTRO_TIME = 0.6`; `FIRST_SPAWN = 0.3`; `BYTE_PAUSE = 0.5`; `SLIDE_TIME = 0.10`; `FADE_IN = 0.15`; `SWIPE_PX = 48.0`, `TAP_SLOP = 40.0`; `LEFT_PAD = Rect2(170, 600, 300, 112)`, `DROP_PAD = Rect2(490, 600, 300, 112)`, `RIGHT_PAD = Rect2(810, 600, 300, 112)`; `PAD_DOWN_PX = 6.0`, `PAD_DOWN_TIME = 0.1`; `SQUASH = 1.25`, `SQUASH_TIME = 0.12`; `FAIL_TINT_TIME = 0.2`; `BANNER_TIME = 1.2`; `HINT_FLASH_TIME = 0.3`; `LOOP_NOTES`, `LOOP_VOL = 0.09`, `LOOP_RESTART_DELAY = 0.5`, `TOP_TRANSPOSE = 12`; `SHAKE_SOFT = 4.0`, `SHAKE_HARD = 14.0`, `HITSTOP = 0.06`; `BOT_STEP = 0.15`, `BOT_REACT = 0.50`, `BOT_SLAM_CHANCE = 0.5`.

**State (game.gd):** `rng`, `intro`, `t`, `reg`, `target`, `bytes_done`, `score`, `streak`, `lives`, the falling-bit fields, `spawn_wait`, `last_cols[2]`, `last_was_zero`, `slide_px`, `slide_t`, `wrap_col`, `pad_down_t[3]`, `drop_key`, `drop_touch`, `press_pos`, `press_zone`, `pressing`, `swiped`, `squash_c`, `squash_t`, `byte_flash_t`, `bad_c`, `bad_t`, `life_flash_t`, `hint_flash_t`, `banner_text`, `banner_t`, `last_phase`, `loop_restart_t`, `top_music`, `bot_t`.

**Flow:**
- `begin()`: reset ALL state (Arcade calls it on every retry and autoplay restart); `target = Rules.make_target(Rules.ones_for(r0), -1, rng)`, `reg = 0`; blips at 0.0 / 0.3; at intro end `Synth.loop(...)`, `t = 0`, `spawn_wait = FIRST_SPAWN`.
- `_process(dt)`: `t += dt; r = Rules.ramp_time(t, difficulty)`. Banner check. Ease the slide. If no bit: count down `spawn_wait`, then spawn (column rule, 0 or 1 rule, `bit_speed = Rules.fall_speed(r)`, `fast = false`). If a bit: `bit_y += (FAST_SPEED if fast else bit_speed) * dt`; when `bit_y >= LAND_Y`: `_land()`. Bot. Loop restart timer.
- `_shift(dir)`: `reg`/`target` rotated, slide set, pad down, shift sound. Allowed even with no bit.
- `_drop()`: if a bit is alive and not fast: `fast = true`, whoosh tone.
- `_land()`: `c = bit_col`. A 1: `Rules.land_one(reg, target, c)`; SET: `reg = Rules.apply_one(reg, c)`, points `Rules.hit_points(streak, fast)`, `streak += 1`, juice; then if `reg == target`: `bytes_done += 1`, `+BYTE_PTS`; if `bytes_done >= BYTES_TO_WIN`: `finish(Rules.final_score(score, lives), true)`; return; else new target, `reg = 0`, `spawn_wait = BYTE_PAUSE`. WRONG: `_hard_fail(c)`. A 0: DODGE +5; LOST `reg = Rules.apply_zero(reg, c)`, streak 0, soft-fail juice. Bit dies; `spawn_wait = Rules.spawn_gap(r)` unless already set by a byte.
- `_hard_fail(c)`: streak 0; if `Rules.is_grace(r)`: grace feedback; else lives -= 1, hard-fail juice, stop loop; if `lives <= 0`: `finish(score, false)`; return.

## Autoplay bot (how it plays; must reach finish() within 60 s)
- Runs in `_process` after moving the bit, only when `autoplay`, and calls the same `_shift(dir)` and `_drop()` as keys and taps.
- Every `BOT_STEP = 0.15` s while a bit is alive and at least `BOT_REACT = 0.50` s old (R0004 retune: the bot slams only about half the bits, `BOT_SLAM_CHANCE`, so a round takes about 40-48 s; the first build finished in 17-21 s): `d = Rules.best_shift(reg, target, bit_col, bit_one)`. If `d < 0`: `_shift(LEFT)`; if `d > 0`: `_shift(RIGHT)`; if `d == 0`: `_drop()`. One action per step, so it visibly shifts cell by cell, then slams.
- For a 1, `best_shift` always finds an empty socket within 4 shifts (the byte is not done, so one exists). For a 0, it parks it on any cell whose reg bit is 0 (always exists). So the bot never loses a life or a bit, and it **wins**.
- Time per bit: react 0.2 + up to 4 steps 0.4 (2 on average) + the fall left (about 0.2) + gap 0.3-0.45, about 1.0 s. About 24 ones + 4 zeros + 7 byte pauses: `finish(score, true)` at about **35 s** of game time including the intro (about 46 s at difficulty 1, 4 ones per byte from the start). Within the gate's 3600 frames.
- Shots: frame 240 (4.0 s, t = 3.4 s): byte 1 done (HUD `10000000`), byte 2 under way, one ACCENT cell set, a bit falling or shifting; score about 150. Frame 900 (15.0 s, t = 14.4 s): the `FASTER` phase, 3 sockets per byte, HUD about `11111000`, score above 600, three lives.

## Acceptance checklist (6–10 testable items, incl. 2–4 rules.gd assertions)
1. `./scripts/check.sh bitcatcher` prints `PASS`; the autoplay log shows `ARCADE finished bitcatcher` with `won` true within the 3600 frames (expected about 35 s).
2. **selftest, the bit shift:** `rol8(0b10000001) == 0b00000011`; `ror8(0b00000011) == 0b10000001`; for every x in 0-255: `ror8(rol8(x)) == x`, `rotate8(x, 8) == x`, `popcount8(rol8(x)) == popcount8(x)`; `rotate8(0b01000000, -1) == 0b10000000`; `col_mask(0) == 128`, `col_mask(7) == 1`; `bits_string(0b10110000) == "10110000"`; `bytes_string(3) == "11100000"`.
3. **selftest, landing and the bot's aim:** `land_one(0, 0b10000000, 0) == SET`; `land_one(0b10000000, 0b10000000, 0) == WRONG`; `land_one(0, 0b10000000, 1) == WRONG`; `land_zero(0b01000000, 1) == LOST`; `land_zero(0b01000000, 0) == DODGE`; `apply_one(0, 7) == 1`; `apply_zero(0xFF, 7) == 0xFE`; `best_shift(0, 0b10000000, 0, true) == 0`; `best_shift(0, 0b01000000, 0, true) == -1`; `best_shift(0, 0b00000001, 0, true) == 1`; for every target t with 1-4 ones, every reg that is a proper subset of t (`reg & t == reg`, `reg != t`) and every column c: with `d = best_shift(reg, t, c, true)`, `abs(d) <= 4` and `land_one(rotate8(reg, d), rotate8(t, d), c) == SET`.
4. **selftest, ramp, targets and scoring:** `ramp_time(0.0, 1) == 30.0`; `fall_time(0) == 3.0`, `fall_time(45) == 1.5`, `fall_time(1000) == 1.5`; `ones_for(5) == 2`, `ones_for(15) == 3`, `ones_for(35) == 4`; `zero_chance(19.9) == 0.0`, `zero_chance(1000) == 0.30`; `hints_on(29.9)` and not `hints_on(30.0)`; `is_grace(9.9)` and not `is_grace(10.0)`; 50 rolls of `make_target(3, prev, rng)` each have popcount 3 and differ from `prev`; `hit_points(0, false) == 10`, `hit_points(100, true) == 35`; `shift_pitch(100) == 1.5`; `final_score(1000, 2) == 1100`; `touch_zone(Vector2(639, 300)) == LEFT`, `touch_zone(Vector2(640, 300)) == RIGHT`, `touch_zone(Vector2(640, 650)) == DROP`, `touch_zone(Vector2(300, 650)) == LEFT`, `touch_zone(Vector2(1000, 650)) == RIGHT`.
5. **Shot `start`:** BG with the TRACE grid and faint lane lines; the register row of 8 cells with exactly 2 lime sockets and 6 plain `0` cells; the three pads with drawn triangles (left, down, right) and no text; score `0`, three ACCENT life squares and the DIM `00000000` byte counter at top centre; nothing in the corners (x < 150 or x > 1100, y < 70).
6. **Shot `play-240`:** a falling bit tile above the register with its lane hint; at least one cell set (ACCENT fill, `1` in BG colour); the HUD counter shows at least one GOOD `1`; score above 0.
7. **Shot `play-900`:** 3 sockets in the current byte, the counter at 3 or more GOOD `1`s, score above 400, three lives; HUD text at least 28 px; only palette colours; no empty glyph boxes.
8. **Code read (grep `games/bitcatcher`):** `Rules.rol8` / `Rules.ror8` (or `rotate8`) applied to both `reg` and `target` in `_shift`; `Synth.sfx("shift", Rules.shift_pitch(streak))` in `_shift`; `Synth.loop(` with `120.0, "square"`; no `"win"` / `"lose"` sfx; `difficulty` used only via `Rules.ramp_time`; exactly one `finish(` with `true` and one with `false`; no `InputEventScreenTouch` / `InputEventScreenDrag`; Esc, P and M are not read.
9. **Touch:** a tap on the left half shifts left on release; a swipe down of 48 px drops the bit fast and does not shift; the DROP pad drops on press; the LEFT / RIGHT pads shift on press.

## Out of scope
- More than one falling bit at a time, Tetris-style stacking, rows of bits, gravity on the register.
- Logical shifts that lose bits (only circular rotates), XOR / AND puzzles, hex digits, arithmetic.
- Hand-made levels or a level select; targets are random by `ones_for(r)`.
- Hold-to-repeat shifting (one press, one shift).
- Tutorial text, READY screens, per-game menus; any file assets (everything is `_draw()` and Synth).
- Symbols on screen: no arrow glyphs (the pads draw triangles), no `0x` or `0b` notation shown to the player.
- Gamepad support (a free bonus at most).
