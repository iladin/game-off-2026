# Cargo Shift

<!-- Written by the Game Designer before any code. The Gameplay Engineer builds exactly this. -->
<!-- R0007, slate slot 6, sense CARGO. Accent #2DD4BF (teal). Budget: about 30 min, under ~850 lines of GDScript. -->
<!-- Every number below was run through a 60 Hz Python model of exactly this Rules.step (20 seeds x difficulty 0 and 1, see "Simulated balance"). -->

## Pitch
A small cargo ship, seen end-on, rolls in a storm. Crates on its deck slide downhill whenever it lists, and every slide makes the list worse. **Hold Left or Right to slide the ballast** (a heavy teal block on a rail in the hull) against the list, ride out each incoming wave, and keep her level for a 45-second crossing. Reach port to set the CARGO bit.

## How it uses SHIFT
SHIFT = **shifting cargo**, read two ways that fight each other. The storm shifts your cargo (crates slide toward the low side, a real capsize mechanism); your one verb is to shift the ballast the other way. The moment you start (or reverse) a ballast slide plays `Synth.sfx("shift", Rules.shift_pitch(streak))`. Nothing else in the game moves weight: the whole skill is when and how far to shift.

## Core loop
Every 3-6 s:
1. A wave builds at the left or right edge of the sea (a teal crest that rolls toward the hull over `WAVE_WARN = 1.5` s, with a hiss). While hints are on, a teal triangle next to the ballast points toward the wave's side.
2. Slide the ballast **toward the wave** before it hits: the wave pushes the hull to list away from it, the ballast's weight pushes back.
3. The wave hits for `WAVE_HIT = 1.0` s (a torque pulse). The deck tilts; crates past the friction angle start to slide.
4. Bring the ballast back so the crates' new positions are balanced (crates on the right need ballast on the left), and settle the roll before the next wave.

The decision: how far to shift and when to come back. Too little and the wave plus sliding crates roll you over; too much (or too long) and the ballast itself lists you the other way, the crates slide over there, and the next wave finishes the job.

## Controls (keyboard AND touch)
| Action | Keyboard | Touch / mouse |
|---|---|---|
| Slide ballast left | hold Left or A | hold anywhere on the left half (x < 640). The LEFT pad `Rect2(170, 616, 300, 96)` is drawn there as the visual |
| Slide ballast right | hold Right or D | hold anywhere on the right half (x >= 640). The RIGHT pad `Rect2(810, 616, 300, 96)` is drawn there |
| Drag the ballast | (none) | press within `DRAG_GRAB = 96` px of the ballast's screen centre and drag: the ballast slides toward the finger's x at the same `BALLAST_SPEED` (no speed advantage) |

- Keys are **polled** every frame in `_process`: `Input.is_physical_key_pressed(KEY_LEFT)` or `KEY_A` gives -1, `KEY_RIGHT` or `KEY_D` gives +1, both or neither gives 0. Never Esc, P or M.
- Pointer: read `InputEventMouseButton` (MOUSE_BUTTON_LEFT) and `InputEventMouseMotion` in `_unhandled_input` so Arcade's HUB / SOUND buttons take their clicks first. `emulate_mouse_from_touch=true`: do NOT also handle `InputEventScreenTouch` / `InputEventScreenDrag`. On press: `ptr_down = true`, `ptr_pos = pos`, `ptr_drag = Rules.is_grab(pos, ballast_screen_pos)`; on motion while down: `ptr_pos = pos`; on release: `ptr_down = false`.
- Pointer direction: `Rules.pointer_dir(ptr_pos, ptr_drag, ballast_sx)`: drag mode: `sign(ptr_pos.x - ballast_sx)` if the gap is over `DRAG_DEAD = 12` px else 0; half mode: -1 if `x < 640` else +1.
- Final `dir`: keys if nonzero, else pointer if down, else 0. The pad on the `dir` side shows pressed in the same frame. Keys and touch produce the same `dir`, so touch alone earns the same score.
- Ignore input (dir 0) when `autoplay`, `is_finished()`, or during the 0.6 s intro.

## Round: fail / win, score
- **Win (sets the CARGO bit):** survive to `t >= ROUND_TIME = 45.0` s. `finish(Rules.final_score(score, lives), true)` in that frame. Round length never depends on skill: every surviving round is 45.6 s including the intro, at any difficulty.
- **Lives:** 3, accent squares at top centre.
- **Hard fail = capsize:** `|tilt| >= CAPSIZE = 0.45` rad (25.8 degrees) while `invuln <= 0`. Then `Rules.rescue(ship)`: tilt 0, roll speed 0, ballast to 0, every crate back to its home spot, `invuln = INVULN = 1.2` s (no capsize check; physics keeps running). **Grace:** while `r < GRACE_END = 10` a capsize costs no life: soft-fail feedback, popup `SHIFT` in DIM, same rescue. (With no input at difficulty 0 the first capsize comes at t >= 10 even with the opening list below, so the first 10 s are doubly safe; selftest asserts it.)

- **Opening list (T-0037):** so the list is visible in the first seconds, `Rules.list_torque(t, side, difficulty)` adds a steady torque of `LIST_TORQUE = 0.35` toward `side` (+1/-1, picked at random in `begin()` as `list_side`). It ramps in over `LIST_RISE = 2.5` s, holds until `LIST_HOLD_END = 10` s, then fades to 0 over `LIST_FADE = 3` s. It is 0 at difficulty >= 1 (that mode starts in storm ramp). It is added to swell and wave torque each frame (also in `sim_round`). With no input the ship is at about 0.22 rad (12 degrees) at t = 6 s, a crate has visibly slid and the needle is out of the level band; selftest asserts >= 8 degrees at 6 s and no capsize before 10 s for 20 seeds.
- **Lose:** lives reach 0: `finish(score, false)` in the same frame as the hard-fail effects. Return right after; `finish()` exactly once.
- **Score:**
  - **Steady tick:** every `TICK = 1.0` s of `t`: if the largest `|tilt|` during that second was under `LEVEL_BAND = 0.12` rad: `+Rules.steady_points(streak) = 10 + 2 * min(streak, 10)`, then `streak += 1`; else `streak = 0` (no penalty).
  - **Wave ridden:** when a wave's hit ends (`t >= t_hit + WAVE_HIT`) and no capsize happened since it was spawned: `+WAVE_PTS = 25`, popup `RODE IT`.
  - **Win:** `+LIFE_BONUS = 150` per life left.
  - Any capsize (grace included) resets `streak` to 0.
  - Model results: the bot scores 1,720-1,890 at difficulty 0 (1,370-2,040 at 1); a reactive human that only watches the tilt scores 350-1,100.
- **Typical length:** 45.6 s; a lost round ends sooner (a no-input player usually sinks between t 25 and 40).

## Ramp (with numbers)
Round time `t` counts from the loop start (end of intro). Ramp time `r = Rules.ramp_time(t, difficulty) = t + (DIFFICULTY_OFFSET 30.0 if difficulty >= 1 else 0.0)`. Everything below reads `r`; nothing reads `difficulty` directly.

| r (s) | New thing | Swell amp `swell_amp(r)` | Wave gap `wave_gap(r)` (s) | Wave peak `wave_peak(r)` | Crates | Banner `phase_name(r)` | Hints |
|---|---|---|---|---|---|---|---|
| 0-10 | calm swell only | 0.05 to 0.15 | no waves | - | 2 | `""` | on |
| 10-20 | **waves** | 0.15 to 0.25 | 6.0 to 5.0 | 0.70 to 0.90 | 2 | `WAVES` | on |
| 20-30 | **third crate** lands off-centre | 0.25 to 0.35 | 5.0 to 4.0 | 0.90 to 1.00 | 3 | `CARGO` | on |
| 30+ | **storm**: thunder, rain, no hints | 0.35 (clamp) | 4.0 to 3.0 (clamp at r 40) | 1.00 (clamp) | 3 | `STORM` | off |

- `swell_amp(r) = min(SWELL_MAX 0.35, SWELL_START 0.05 + SWELL_RAMP 0.01 * r)`; swell torque `Rules.swell(r, t) = swell_amp(r) * sin(TAU * t / SWELL_PERIOD 5.0)`. (Period 5 s is well clear of the hull's natural roll period of 3.1 s, so the swell rocks but never resonates.)
- `wave_gap(r) = max(WAVE_GAP_MIN 3.0, WAVE_GAP_START 6.0 - WAVE_GAP_RAMP 0.1 * (r - WAVES_AT 10))`.
- `wave_peak(r, rng) = min(WAVE_PEAK_MAX 1.0, WAVE_PEAK_START 0.5 + WAVE_PEAK_RAMP 0.02 * r) * rng.randf_range(0.85, 1.0)`.
- Wave spawning (in game.gd, and the same in `sim_bot_round`): `next_wave_t` starts at `max(0, WAVES_AT - offset)` (10.0 at difficulty 0, 0.0 at difficulty 1). When `r >= WAVES_AT and t >= next_wave_t`: append `Wave(t_hit = t + WAVE_WARN, side = rng.randi_range(0,1) * 2 - 1, peak = wave_peak(r, rng))`; `next_wave_t = t + wave_gap(r)`. Difficulty 0 gets 9 waves per round, difficulty 1 gets 15. Waves never overlap: spawn to end of hit is 2.5 s, shorter than the smallest gap (3.0 s).
- Wave torque: `Rules.wave_torque(waves, t) = sum over waves of -side * peak * sin(PI * u)` for `u = (t - t_hit) / WAVE_HIT` in [0, 1]. A wave from the left (`side = -1`) pushes positive torque: the hull lists right, away from it.
- Third crate: the first frame `r >= CRATE3_AT 20`: append a crate at `x = CRATE3_X 0.6 * (rng.randi_range(0,1) * 2 - 1)`; that is also its home. At difficulty 1 it is there from t 0.
- `hints_on(r)`: `r < HINTS_END 30`. `is_grace(r)`: `r < GRACE_END 10`. Banners show when `phase_name(r)` differs from the last shown (start `""`), so at difficulty 1 `STORM` shows at once.

### Balance the numbers give (statics, check these hold if you tune)
- Hull alone: `ROLL_STIFF 4.0` and `ROLL_DAMP 1.6` give a natural roll of 2 rad/s (period 3.1 s), damping ratio 0.4: it rolls about one and a half times after a push, which reads as a boat.
- Static list of a moment `m`: `tilt = MOMENT_GAIN * m / ROLL_STIFF = m / 4`. Ballast at the end stop (`BALLAST_MASS 1.0 * 1.0`): 0.25 rad. Three crates on one rail (`3 * CRATE_MASS 0.5 * 1.0`): 0.375 rad. So the ballast alone can always pull back three crates slammed to one side (net 0.125 < 0.45): every state short of capsize is recoverable.
- The strongest wave (peak 1.0) is exactly cancelled by the ballast at the end stop, so a perfect shift rides it flat; a wave with no response gives about 0.25 rad, plus the crates it starts sliding: two unanswered waves capsize you.
- Crates: friction holds them while `|tilt| <= STICK 0.05` rad; past it they slide at `CARGO_SLIDE 2.0 * (|tilt| - 0.05)` deck units/s toward the low side (0.3 units/s at 0.2 rad), clamped to the rails at +-1.

### Simulated balance (Python model of this exact step, dt 1/60, seeds 1-20)
| Player | d 0: wins / capsizes | d 1: wins / capsizes | max tilt |
|---|---|---|---|
| Bot (below) | 20 / 0 | 20 / 0 | 0.124 (d 0), 0.214 (d 1) |
| No input | 5 / 54 | 0 / 60 | capsize |
| Human model: reacts to tilt only, 0.25 s late | 18 / 24 | 16 / 35 | capsize |
| Human model: 0.4 s late, also reads roll speed | 20 / 10 | 19 / 9 | capsize |
A player who does nothing loses; a player who reacts wins most rounds losing about one life; reading the wave telegraph (shift before it hits) is what earns clean rounds and the big streak.

## The physics step (`Rules.step`, pure, shared by the game, the bot and the selftest)
`class Ship` (inner class in rules.gd, `extends RefCounted`): `tilt: float = 0` (rad, + = starboard/right side down), `roll_v: float = 0` (rad/s), `ballast: float = 0` (-1..1, + = right), `cargo: PackedFloat32Array = [-0.35, 0.35]` (deck units -1..1), `home: PackedFloat32Array` (copy of cargo), `last_dir: int = 0`, `invuln: float = 0`.
`moment(s) = BALLAST_MASS * s.ballast + CRATE_MASS * sum(s.cargo)`.

`step(s, dt, dir, ext_torque) -> int` (bitmask of events), in this order:
1. Shift: if `dir != 0 and dir != s.last_dir`: ev |= `EV_SHIFT (1)`. `s.last_dir = dir`.
2. Ballast: `b0 = s.ballast; s.ballast = clamp(b0 + dir * BALLAST_SPEED * dt, -1, 1)`. If `dir != 0` and `absf(s.ballast) == 1.0 and absf(b0) < 1.0`: ev |= `EV_STOP (2)` (hit the end stop).
3. Roll (semi-implicit Euler): `acc = -ROLL_STIFF * s.tilt - ROLL_DAMP * s.roll_v + MOMENT_GAIN * moment(s) + ext_torque`; `s.roll_v += acc * dt`; `s.tilt += s.roll_v * dt`.
4. Cargo: if `absf(s.tilt) > STICK`: for each crate `c0 = cargo[i]`, `c = clamp(c0 + CARGO_SLIDE * (s.tilt - signf(s.tilt) * STICK) * dt, -1, 1)`; if `absf(c) == 1.0 and absf(c0) < 1.0`: ev |= `EV_THUD (4)`, `s.thud_i = i`.
5. Capsize: if `s.invuln > 0`: `s.invuln -= dt`; elif `absf(s.tilt) >= CAPSIZE`: ev |= `EV_CAPSIZE (8)`. (The game decides grace vs life and calls `rescue`.)

`rescue(s)`: tilt 0, roll_v 0, ballast 0, `cargo = home.duplicate()`, `last_dir = 0`, `invuln = INVULN`.
`ext_torque` each frame = `Rules.swell(r, t) + Rules.wave_torque(waves, t)`.
`add_crate(s, x)`: append x to both `cargo` and `home`.

## Look (palette hex + how each thing is drawn, per studio/VISION.md)
Colours: BG `#0B0E14`, PANEL `#151A24`, TRACE `#1E2738`, DIM `#6B7489`, INK `#E8ECF4`, ACCENT `#2DD4BF`, GOOD `#FFD34D`, BAD `#FF3B5C`. Nothing else (tints = alpha only).

Screen map (1280 x 720):
| y | Band |
|---|---|
| 0-130 | HUD: score, lives, tilt gauge, voyage bar (x 170-1090 only) |
| 140-180 | banner |
| 180-470 | sky and ship (pivot `PIVOT = (640, 440)`) |
| 470-720 | sea (water line `SEA_Y = 470`); pads at 616-712 on top of it |

- **BG:** fill BG; 1 px TRACE grid at 40 px pitch, fixed (the sea moves, the grid does not).
- **Sea:** a filled polygon from the water line to y 720 in PANEL; its top edge is 33 points across x 0-1280 with `y = SEA_Y + 10 * sin(x / 90 + t * 1.3) + 6 * sin(x / 37 - t * 2.1)`, drawn as a 2 px TRACE polyline, plus a second polyline 24 px lower at alpha 0.5. The hull is drawn before the sea so the sea covers its bottom.
- **Ship** (everything below is drawn with `draw_set_transform(PIVOT, tilt)` in local px; reset after):
  - Hull: polygon `(-340, -20), (340, -20), (260, 110), (-260, 110)`, PANEL fill, 4 px INK outline. Deck: 6 px INK line from (-340, -20) to (340, -20). Rails: 4 x 36 px INK posts at x -336 and +336 above the deck.
  - Ballast rail: 2 px TRACE line from (-240, 55) to (240, 55) with 4 px DIM end-stop ticks. Ballast: 96 x 44 rect centred at `(ballast * 240, 55)`, ACCENT fill, 6 px INK outline (it is the player), glow (1.3x alpha 0.25, 1.6x alpha 0.10 in ACCENT).
  - Crates: 72 x 72 squares sitting on the deck, centre `(c * DECK_RANGE 264, -56)`: PANEL fill, 4 px ACCENT outline, two 2 px ACCENT diagonals (a cross brace). The third crate drops in from y -300 over 0.25 s (ease out back) when it arrives.
  - Mast: 4 px DIM line from (0, -20) up to (0, -200), a 2 px DIM line to each rail top (rigging).
- **Wave telegraph:** each wave with `t < t_hit + WAVE_HIT` draws a crest: a filled triangle-ish polygon 160 wide, 70 tall, sitting on the water line, ACCENT at alpha 0.35 with a 4 px ACCENT top edge. Its centre x eases from the screen edge on its side (x 40 or 1240) to the hull side (x 300 or 980) as `u_warn = (t - (t_hit - WAVE_WARN)) / WAVE_WARN` goes 0 to 1 (ease in), then during the hit it breaks: height shrinks 70 to 0 and it slides another 120 px under the hull.
- **Hint** (`hints_on(r)` and a wave is in warn or hit): a filled ACCENT triangle (40 wide, 36 tall) pointing toward the wave's side, drawn in ship-local space just outside the ballast's end on that side, alpha pulsing `0.55 + 0.45 sin(TAU * 3 t)`. Also that side's pad outline glows ACCENT. No text.
- **Storm** (`r >= 30`): 60 rain lines, 2 px DIM at alpha 0.4, 24 px long, slanted (dx -8 per 24 down), positions from a fixed pseudo-random table scrolled by `t * 900` px/s and wrapped in 180-720.
- **Pads:** PANEL fill, 4 px TRACE outline; a filled INK triangle (56 wide, 48 tall) pointing left or right. Pressed (`dir` on that side): offset +6 px down, ACCENT fill, triangle in BG colour. No text.
- **HUD** (x 170-1090; nothing at x < 150 or x > 1100 above y 70):
  - Score 40 px INK centred, baseline y 52.
  - Lives: 3 squares 20 x 20 at y 62-82, centres x 608 / 640 / 672: ACCENT alive, 2 px DIM outline when lost (BAD fill for 0.4 s after: `life_flash_t`).
  - Tilt gauge: bar x 440-840, y 92-104 (center 640 = level): TRACE fill; a GOOD band for `|tilt| < LEVEL_BAND` (x 640 +- 107); BAD 4 px caps at both ends (= `CAPSIZE`); a 6 x 22 INK needle at `x = 640 + 200 * clamp(tilt / CAPSIZE, -1, 1)`, BAD-tinted when `|tilt| > 0.3`.
  - Voyage bar: x 340-940, y 116-122: TRACE fill, ACCENT fill to `t / ROUND_TIME`, a 4 x 16 GOOD tick at x 940 (port).
  - Banner 40 px ACCENT centred, baseline y 172, 1.2 s, fades over the last 0.3 s.
- The only words ever on screen: the banners and popups (`+N`, `RODE IT`, `SHIFT`). No READY text.

## Sound (Synth presets/tones/loop used, per studio/VISION.md)
| Event | Call |
|---|---|
| Ballast shift starts or reverses (the verb, `EV_SHIFT`) | `Synth.sfx("shift", Rules.shift_pitch(streak))`, `shift_pitch = min(1.5, 1.0 + 0.04 * streak)`; rate-limited: skipped if the last one was under `SHIFT_SFX_GAP = 0.12` s ago (the bot can flip direction fast) |
| Ballast hits its end stop (`EV_STOP`) | `Synth.tone(160.0, 0.06, "square", 0.18, 120.0)` (clunk) |
| Crate slams a rail (`EV_THUD`) | `Synth.sfx("miss", randf_range(0.92, 1.08))` (a soft fail: you let it slide) |
| Steady tick scored | `Synth.sfx("coin", pow(2.0, mini(streak, 12) / 12.0))` (streak before the tick) |
| Wave spawns (warn starts) | `Synth.tone(500.0, 1.4, "noise", 0.16, 150.0)` (the hiss of the building crest) |
| Wave hits (`t` crosses `t_hit`) | `Synth.tone(90.0, 0.4, "sine", 0.30, 55.0)` (hull thump) |
| Wave ridden | `Synth.sfx("coin", 1.335)` (+5 semitones) |
| Thunder (storm, every `THUNDER_GAP = 4.0` s from r 30) | `Synth.tone(220.0, 0.9, "noise", 0.22, 40.0)` |
| Grace capsize | `Synth.sfx("miss", randf_range(0.92, 1.08))` |
| Capsize (life lost) | `Synth.sfx("boom", randf_range(0.95, 1.05))`; `Synth.stop_loop()`; restart the loop after 0.5 s |
| Banner | `Synth.sfx("blip", 1.5)` |
| Round intro | `blip` at 0.0 and 0.3 s; loop starts at 0.6 s and `t` starts at 0 that frame |
| Round end | nothing (Arcade plays `win` / `lose`) |

**Music:** sine, 92 bpm, `LOOP_VOL = 0.10`, a rolling A minor pentatonic arpeggio: `LOOP = [45, 52, 57, 52, 48, 55, 60, 55, 45, 52, 57, 52, 43, 50, 55, 50]`. At most 3 SFX start in one frame (worst case: shift + steady tick + wave hit; thunder is scheduled at tick time + 0.5 s so it never lands on a tick).

## Juice list (each item names its state variable; QA checks it is set in the trigger and read in a draw call)
| # | Event (trigger in game.gd) | Effect | State set there, read in drawing |
|---|---|---|---|
| 1 | `EV_SHIFT` in `_on_events` | ballast squash 1.25 wide x 0.8 tall back to 1.0 over 0.12 s (it lurches); a 2 px ACCENT wake line trailing 40 px behind it at alpha 0.6 fading over 0.2 s; pad pressed look | `shift_fx_t = SHIFT_FX_TIME (0.2)`, `shift_fx_dir` |
| 2 | `EV_STOP` | `Juice.shake(4)`; ballast flashes INK fill for 0.08 s | `stop_flash_t = 0.08` |
| 3 | `EV_THUD` | the slammed crate tinted BAD for 0.2 s, squash 0.8 wide x 1.2 tall; `Juice.shake(4)`; `Juice.burst(self, crate_screen_pos, INK, 6, 120.0)` (spray) | `thud_t = 0.2`, `thud_i` |
| 4 | Steady tick scored | `Juice.popup(self, Vector2(640, 250), "+%d" % pts, GOOD)`; gauge GOOD band brightens (alpha 1) for 0.15 s | `tick_flash_t = 0.15` |
| 5 | Wave hit / ridden | hit: `Juice.shake(4)` (10 if `peak > 0.9`), spray `Juice.burst(self, crest_pos, ACCENT, 14)`; ridden: popup `RODE IT` in GOOD 28 px at `PIVOT + (0, -110)` (clear of the voyage bar, banner and `+N`), hull outline glows GOOD for 0.6 s | `crest` geometry from `waves[]`; `ridden_t` |
| 6 | Thunder | `Juice.flash(Color(INK, 0.15), 0.1)` | `thunder_t` (rain brightens to alpha 0.7 for 0.1 s) |
| 7 | Grace capsize | ballast tinted BAD 0.2 s; `Juice.shake(4)`; popup `SHIFT` in DIM 32 px above the ship; rescue | `fail_tint_t = 0.2` |
| 8 | Capsize (life lost) | `Juice.flash(Color(BAD, 0.35), 0.2)`, `Juice.shake(14)`, `Juice.hitstop(0.06)`, `Juice.burst(self, PIVOT, BAD)`; lost life square BAD 0.4 s; loop silent 0.5 s; during `invuln` the ship blinks (hidden when `fmod(invuln, 0.16) < 0.08`) | `fail_tint_t`, `life_flash_t = 0.4`, `loop_restart_t = 0.5`, `ship.invuln` |
| 9 | Banner change | fades in/out as above | `banner_text`, `banner_t` |

## Build plan (scripts, data structures, every tunable with a start value)
Files (target ~800 lines, each under 300):
- `rules.gd` (~230 lines, pure: no nodes, no autoloads; a passed-in `RandomNumberGenerator` is fine): constants, inner classes `Ship` and `Wave` (`t_hit`, `side`, `peak`, `spawn_fail_count`), static functions: `ramp_time`, `swell_amp`, `swell`, `wave_gap`, `wave_peak`, `wave_torque`, `phase_name`, `hints_on`, `is_grace`, `moment`, `step`, `rescue`, `add_crate`, `steady_points`, `shift_pitch`, `final_score`, `pointer_dir`, `is_grab`, `bot_dir(s, waves, t) -> int`, `sim_bot_round(seed, difficulty) -> Dictionary` (`won`, `time`, `capsizes`, `max_tilt`, `score`, `waves`, `shifts`).
- `selftest.gd` (~100 lines): the assertions in the checklist; prints `SELFTEST OK`.
- `game.gd` (~270 lines, `extends MicroGame`): state, `begin()`, `_process()`, `_unhandled_input()`, `_on_events()`, `_capsize()`, `_draw()` calling the helpers.
- `cargo_draw.gd` (~200 lines, `extends RefCounted`, static helpers taking `ci: CanvasItem`): `draw_backdrop(ci, t)`, `draw_sea(ci, t)`, `draw_ship(ci, ship, fx...)`, `draw_waves(ci, waves, t)`, `draw_rain(ci, t, bright)`, `draw_pads(ci, dir, hint_side)`, `draw_hud(ci, font, score, lives, life_flash_t, tilt, progress, banner, banner_alpha, tick_flash_t)`, `glow_rect(...)`.

**Per-frame order in `_process(dt)` (`sim_bot_round` uses the same order with `dt = 1/60`):**
1. Intro / timers / loop restart / thunder. 2. `t += dt; r = ramp_time(t, difficulty)`. 3. Third crate if `r >= CRATE3_AT` and only 2 crates; wave spawn per the Ramp section (wave hiss). 4. `dir`: `Rules.bot_dir(ship, waves, t)` if `autoplay`, else keys/pointer. 5. `ev = Rules.step(ship, dt, dir, Rules.swell(r, t) + Rules.wave_torque(waves, t))`. 6. `_on_events(ev)` (sounds, juice; on `EV_CAPSIZE`: grace or life, `Rules.rescue`; mark every live wave as failed; if lives reach 0: `finish(score, false)`; return). 7. Wave hit / ridden checks; drop waves with `t > t_hit + WAVE_HIT + 0.5`. 8. Tick: `tick_max = max(tick_max, abs(tilt))`; `tick_t += dt`; when `tick_t >= TICK`: score it, `tick_t -= TICK`, `tick_max = 0`. 9. If `t >= ROUND_TIME`: `finish(Rules.final_score(score, lives), true)`; return. 10. Banner check; `queue_redraw()`.

**rules.gd tunables:**
| Name | Start value |
|---|---|
| EV_SHIFT, EV_STOP, EV_THUD, EV_CAPSIZE | 1, 2, 4, 8 |
| ROLL_STIFF, ROLL_DAMP, MOMENT_GAIN | 4.0, 1.6, 1.0 |
| BALLAST_MASS, BALLAST_SPEED | 1.0, 1.25 |
| CRATE_MASS, CARGO_HOME, STICK, CARGO_SLIDE | 0.5, [-0.35, 0.35], 0.05, 2.0 |
| CRATE3_AT, CRATE3_X | 20.0, 0.6 |
| CAPSIZE, INVULN, LEVEL_BAND | 0.45, 1.2, 0.12 |
| SWELL_START, SWELL_RAMP, SWELL_MAX, SWELL_PERIOD | 0.05, 0.01, 0.35, 5.0 |
| WAVES_AT, WAVE_WARN, WAVE_HIT | 10.0, 1.5, 1.0 |
| WAVE_GAP_START, WAVE_GAP_RAMP, WAVE_GAP_MIN | 6.0, 0.1, 3.0 |
| WAVE_PEAK_START, WAVE_PEAK_RAMP, WAVE_PEAK_MAX, WAVE_PEAK_JITTER | 0.5, 0.02, 1.0, 0.85 |
| ROUND_TIME, TICK, GRACE_END, HINTS_END, STORM_AT, DIFFICULTY_OFFSET | 45.0, 1.0, 10.0, 30.0, 30.0, 30.0 |
| STEADY_PTS, STREAK_PTS, STREAK_CAP, WAVE_PTS, LIFE_BONUS | 10, 2, 10, 25, 150 |
| PITCH_STEP, PITCH_MAX | 0.04, 1.5 |
| BOT_LEAD, BOT_KP, BOT_KD, BOT_DEAD | 0.35, 2.5, 0.8, 0.05 |
| HALF_X, DRAG_GRAB, DRAG_DEAD | 640.0, 96.0, 12.0 |

**game.gd tunables:** palette Colors; `LIVES = 3`; `INTRO_TIME = 0.6`; `PIVOT = Vector2(640, 440)`, `SEA_Y = 470.0`, `DECK_RANGE = 264.0`, `BALLAST_RANGE = 240.0`, `BALLAST_Y = 55.0`, `CRATE_SIZE = 72.0`; `LEFT_PAD = Rect2(170, 616, 300, 96)`, `RIGHT_PAD = Rect2(810, 616, 300, 96)`, `PAD_DOWN_PX = 6.0`; `SHIFT_FX_TIME = 0.2`, `SQUASH_TIME = 0.12`, `STOP_FLASH_TIME = 0.08`, `THUD_TIME = 0.2`, `TICK_FLASH_TIME = 0.15`, `FAIL_TINT_TIME = 0.2`, `LIFE_FLASH_TIME = 0.4`, `BANNER_TIME = 1.2`; `SHIFT_SFX_GAP = 0.12`; `THUNDER_GAP = 4.0`; `LOOP_VOL = 0.10`, `LOOP_BPM = 92.0`, `LOOP_RESTART_DELAY = 0.5`; `SHAKE_SOFT = 4.0`, `SHAKE_MED = 10.0`, `SHAKE_HARD = 14.0`, `HITSTOP = 0.06`.
- Ballast screen position (for drag and popups): `PIVOT + Vector2(ballast * BALLAST_RANGE, BALLAST_Y).rotated(tilt)`.

**State (game.gd):** `rng`, `ship`, `waves: Array`, `intro`, `t`, `next_wave_t`, `score`, `streak`, `lives`, `tick_t`, `tick_max`, `ptr_down`, `ptr_pos`, `ptr_drag`, `dir`, `last_shift_sfx_t`, `shift_fx_t`, `shift_fx_dir`, `squash_t`, `stop_flash_t`, `thud_t`, `thud_i`, `tick_flash_t`, `ridden_t`, `thunder_t`, `next_thunder_t`, `crate3_drop_t`, `fail_tint_t`, `life_flash_t`, `banner_text`, `banner_t`, `last_phase_name`, `loop_restart_t`, `capsizes_total`.
- `begin()`: reset ALL state (Arcade calls it on every retry and autoplay restart); `rng.randomize()`; `ship = Rules.Ship.new()`; if `ramp_time(0, difficulty) >= CRATE3_AT` add the third crate at once; blips at 0.0 / 0.3; at intro end `Synth.loop(LOOP, 92.0, "sine", LOOP_VOL)`, `t = 0`.

## Autoplay bot (how it plays; must reach finish() within 60 s)
Deterministic and pure: `Rules.bot_dir(s, waves, t) -> int` (-1, 0, +1), called in step 4; its `dir` goes through the same `Rules.step` as keys and taps. It never reads `rng`.
```
target = -(CRATE_MASS * sum(s.cargo) + wave_torque(waves, t + BOT_LEAD) / MOMENT_GAIN) / BALLAST_MASS
         - BOT_KP * s.tilt - BOT_KD * s.roll_v
target = clamp(target, -1, 1)
return +1 if target - s.ballast > BOT_DEAD, -1 if < -BOT_DEAD, else 0
```
(Balance the crates, cancel the wave it can see 0.35 s ahead, damp the roll.) In the model it never capsizes on 20 seeds per difficulty, max tilt 0.124 rad at difficulty 0, so it **wins** by surviving: `finish(score, true)` at t = 45.0 s, i.e. about **45.6 s of game time, frame about 2737** of the 3600 the gate allows, at any difficulty. Not randomised, so `check.sh` cannot flake on time. It flips direction often, so it exercises `EV_SHIFT` (expect 40+ shifts) and the sfx rate limit.

Shots: frame 240 (4.0 s, t = 3.4 s): calm swell, two crates near +-0.35, ballast near centre, tilt needle inside the GOOD band, score 30-40. Frame 900 (15.0 s, t = 14.4 s): waves zone, one crest on screen or just broken, score about 300-350, three lives, voyage bar about 32%.

## Acceptance checklist (testable items)
1. `timeout 170 ./scripts/check.sh cargoshift` prints `PASS`; the autoplay log shows `ARCADE finished cargoshift` with `won` true at about 45.6 s of game time. Headless autoplay 3 times (`$GODOT --headless --path . --fixed-fps 60 --quit-after 3600 -- --game=cargoshift --autoplay`): each finishes, won, between frames 2700 and 2780.
2. **selftest, ramp:** `ramp_time(0.0, 1) == 30.0`; `swell_amp(0) == 0.05`, `swell_amp(100) == 0.35`; `wave_gap(10) == 6.0`, `wave_gap(30) == 4.0`, `wave_gap(100) == 3.0`; with a seeded rng, `wave_peak(10, rng)` in [0.595, 0.70] and `wave_peak(100, rng)` in [0.85, 1.0]; `phase_name(5) == ""`, `phase_name(15) == "WAVES"`, `phase_name(25) == "CARGO"`, `phase_name(35) == "STORM"`; `is_grace(9.9)` and not `is_grace(10.0)`; `hints_on(29.9)` and not `hints_on(30.0)`; `wave_torque([Wave(t_hit 1.0, side -1, peak 0.8)], 1.5)` is +0.8 (within 1e-4) and 0 at t 0.9 and 2.1.
3. **selftest, physics step** (dt 1/60): (a) a fresh Ship with `dir 0` and no torque stays at tilt 0 for 600 frames and crates never move; (b) `ext_torque 1.0` constant, no input: crates slide (sum(cargo) > 0) and `EV_CAPSIZE` comes within 600 frames (crates at the rail add 0.25 rad to the 0.25 the torque gives); the same with `dir -1` held (ballast at -1 cancels the torque): no `EV_CAPSIZE` in 600 frames and tilt ends under 0.3; (c) `dir` +1 then +1 then -1: `EV_SHIFT` on frames 1 and 3 only; (d) holding +1 from ballast 0: `EV_STOP` exactly once, on frame 48 or 49 (1.0 / 1.25 s); (e) three crates forced to +1 and ballast -1: static tilt converges to 0.125 within 0.01 (the recoverability invariant); (f) `rescue` puts tilt, roll_v and ballast at 0, cargo equal to home and invuln 1.2, and no `EV_CAPSIZE` is reported while invuln > 0.
4. **selftest, the bot:** for seeds 1-20 at difficulty 0: `sim_bot_round(seed, 0)` returns `capsizes == 0`, `won`, `time` in 44.9-45.1, `max_tilt < 0.2`, `waves == 9`, `shifts >= 20`, score in 1,500-2,100; at difficulty 1: `capsizes == 0`, `won`, `max_tilt < 0.3`, `waves == 15`. Plus a no-input round: `sim_bot_round` variant with `dir` forced 0 (`sim_round(seed, d, idle = true)`) capsizes at least once on seeds 1-20 at difficulty 0, and never before t 10.
5. **selftest, scoring and input:** `steady_points(0) == 10`, `steady_points(50) == 30`; `shift_pitch(100) == 1.5`; `final_score(1000, 2) == 1300`; `pointer_dir(Vector2(639, 300), false, 0) == -1`, `pointer_dir(Vector2(640, 300), false, 0) == 1`; `pointer_dir(Vector2(700, 400), true, 650) == 1`, `pointer_dir(Vector2(655, 400), true, 650) == 0`; `is_grab(Vector2(700, 495), Vector2(640, 495))` true, `is_grab(Vector2(800, 495), Vector2(640, 495))` false.
6. **Shot `start`:** BG with the TRACE grid; the hull level at the pivot with two crates (PANEL, teal outline and cross brace) and the teal ballast with glow; sea polylines; LEFT and RIGHT pads with triangles, no text; score `0`, three teal life squares, tilt gauge needle centred in the GOOD band, voyage bar; nothing in the corners (x < 150 or x > 1100, y < 70).
7. **Shot `play-900`:** the ship visibly tilted or a teal crest on the sea; score above 200; three lives; HUD text at least 28 px; only palette colours; no empty glyph boxes.
8. **Code read (grep `games/cargoshift`):** `Synth.sfx("shift", Rules.shift_pitch(streak))` in the `EV_SHIFT` branch; `Synth.loop(` uses `92.0, "sine"`; no `"win"` / `"lose"` sfx; `difficulty` used only via `Rules.ramp_time` (and the crate check in `begin`); exactly one `finish(` with `true` and one with `false`; no `RigidBody2D` / physics nodes; the bot path goes through `Rules.bot_dir` and `Rules.step` (game.gd never writes `ship.tilt`, `ship.ballast` or `ship.cargo` outside `Rules.rescue` / `Rules.add_crate`); no `InputEventScreenTouch` / `InputEventScreenDrag`; Esc, P and M not read.
9. **Juice wired:** for each Juice row, the named state variable is assigned in the named trigger and read in a draw function (grep both); `Juice.flash`, `Juice.shake`, `Juice.hitstop`, `Juice.burst` and `Juice.popup` each appear in game.gd.
10. **Touch:** holding a press at (300, 300) moves the ballast left from that frame (LEFT pad lit); at (1000, 300) right; pressing on the ballast and dragging moves it toward the finger; a press on the HUB or SOUND button does neither.

## Out of scope
- Rigid bodies, stacking, crates that fall overboard, crates that collide with each other (crates pass through each other: each is a 1D slider).
- Pitch (fore-aft) roll, steering, a scrolling voyage, ports, weather choices.
- More than one ballast, pumps, throwing cargo overboard, loading cargo.
- Tutorial text, READY screens, per-game menus; any file assets (everything is `_draw()` and Synth).
- Symbols on screen: no arrow glyphs (pads and hints draw triangles).
- Gamepad support (a free bonus at most).

## Hull and crate layout (R0013)
Sea and waves draw first; the hull (PANEL fill, 4 px INK outline, teal waterline) draws over them so nothing shows through. Crates are drawn at `R.spread_cargo` positions, which keep at least CRATE_GAP_PX (8 px, selftest asserts 4 px minimum) between crate rects; physics still uses the raw positions.

The waterline (T-0042) is drawn at the world sea level `SEA_Y`: a 3 px teal band clipped to the rotated hull polygon (`Geometry2D.intersect_polygons`), so it stays level while the hull tilts.
