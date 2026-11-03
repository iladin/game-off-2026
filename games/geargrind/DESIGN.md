# Gear Grind

<!-- Written by the Game Designer before any code. The Gameplay Engineer builds exactly this. -->
<!-- R0003, slate slot 2, sense GEAR. Accent #FF9F1C. Budget: about 20-30 min, under ~650 lines of GDScript. -->

## Pitch
A side-view quarter-mile drag strip, two lanes, one amber car and one grey rival. The lights drop, you launch, and the only thing you do is shift up: each time the big tach needle sweeps into the amber band, hit Space (or tap) and bang the next gear in. Shift in the middle of the band for a PERFECT and a burst of boost; shift early and the engine bogs; hang on too long and the needle sits in the red until the engine blows. Win four heats to clear the strip.

## How it uses SHIFT
SHIFT = **shifting gears**, and it is the only verb. You never steer, brake or accelerate: the car accelerates by itself and your whole race is the timing of 2 to 4 shifts. Every shift plays `Synth.sfx("shift", Rules.shift_pitch(streak))` (pitch climbs with a streak of in-band shifts), the gear digit changes, the needle drops and the lever snaps. The engine sound itself is shifted: its pitch follows the needle, so you can shift by ear.

## Core loop
One heat is about 10 s: 1.6 s staging lights, a 6-8 s run, a 1.0 s result beat. Inside a heat, every 1-2 s:
1. The needle climbs (faster in low gears, slower in high gears).
2. It enters the amber band (the band and the lever glow while it is in there).
3. Press. Where the needle is when you press decides the shift: PERFECT (inner third, boost), GOOD, EARLY (below the band, bog), LATE (above the band or in the red).
4. The needle drops into the next gear and climbs again. In the top gear there is nothing to shift: you ride it to the line.

The decision: commit early in the band (safe from the red) or wait for the centre (PERFECT boost). From 30 s the band moves to a different spot in every gear, so you must read the band, not memorise a needle angle.

## Controls (keyboard AND touch)
| Action | Keyboard | Touch / mouse |
|---|---|---|
| Shift up | Space, Up, or W (`pressed and not echo`) | tap / click anywhere on the screen; the drawn lever on the right (160 x 196 px) is the visual target |

- Read `InputEventKey` (`keycode` KEY_SPACE, KEY_UP, KEY_W) and `InputEventMouseButton` (pressed, MOUSE_BUTTON_LEFT) in `_unhandled_input`, so Arcade's HUB / SOUND buttons take their clicks first. `project.godot` has `emulate_mouse_from_touch=true`: do NOT also handle `InputEventScreenTouch` (double fire). Never Esc, P or M.
- Ignore input when `autoplay`, `is_finished()`, or during the 0.6 s round intro.
- Every press answers in the same frame. During staging, the result beat, or in the top gear (nothing to shift): `Synth.sfx("blip", 0.9)` and the lever knob twitches (1.1x squash). No penalty, no jump-start rule.
- Touch alone earns the same score as keys: both call the same `_shift()`. The whole screen is the button, so a 96 px target is trivially met.

## Round: fail / win, score
- **Heats:** each heat is a race of `TRACK = 300` m against a rival who finishes in exactly `Rules.rival_time(gears, r)` seconds. The heat ends the moment either car reaches 300 m. Player first = heat WON. Rival first = heat LOST.
- **Engine blown:** while not in the top gear, if the needle stays at the redline (rpm >= 1.0, the car is speed-capped) for `BLOW_TIME = 0.9` s continuously and `Rules.blow_on(r)`, the engine blows: the heat is LOST at once (hard fail).
- **Lives:** 3, accent squares at top centre. A LOST or BLOWN heat costs 1 life, **except in a grace heat** (one that started at ramp time r < `GRACE_END` = 10: heat 1 at difficulty 0). A lost grace heat costs nothing and shows `TRY AGAIN`. Blowing is off in a grace heat anyway. So the first 10+ s cannot be lost.
- **Win (clears the GEAR bit):** win `HEATS_TO_WIN = 4` heats: `finish(Rules.final_score(score, lives), true)` right as the 4th win is judged (no result beat after it).
- **Lose:** lives reach 0: `finish(score, false)` in the same frame as the hard-fail effects.
- `won` is true only for the 4th heat win. `finish()` exactly once (return right after). Never play `win` / `lose`.
- **Score:** per shift: PERFECT +30, GOOD +15, LATE +5, EARLY +0. Heat won: +100 plus `int(MARGIN_PTS * (rival_time - player_time))` with MARGIN_PTS = 50 (per second of margin). Round won: +50 per life left. A clean bot win scores about 900-1,100.
- **Typical length:** bot / good player wins in about 41 s (4 heats). A player who loses heats plays up to 8 heats (grace + 3 losses + 4 wins) = about 80 s. Within 30-90 s.

## Ramp (with numbers)
Ramp time `r = elapsed + (DIFFICULTY_OFFSET = 30.0 if difficulty >= 1 else 0.0)`; `elapsed` counts from the end of the 0.6 s intro and keeps running through staging and result beats. **All heat parameters are sampled once, at the start of a heat's staging** (`heat_r`), so a heat never changes mid-run.

| Quantity (rules.gd) | Formula | r=0 | 10 | 20 | 30 | 40+ | Clamp |
|---|---|---|---|---|---|---|---|
| `gears_for(r)` | 3 if r < 20, 4 if r < 40, else 5 | 3 | 3 | 4 | 4 | 5 | |
| `band_width(r)` | `0.30 - 0.003 r` | 0.30 | 0.27 | 0.24 | 0.21 | 0.18 | min 0.16 |
| band centre | `BAND_CENTER (0.80) + band_offset(roll, r)` | 0.80 | 0.80 | 0.80 | moves | moves | lo/hi clamped to 0.40 / 0.97 |
| `band_offset(roll, r)` | 0 if r < MOVE_AT (30), else `MOVE_OFFSETS[roll]`, `MOVE_OFFSETS = [-0.10, -0.05, 0.0, 0.05]`, roll = `randi() % 4` per gear | 0 | 0 | 0 | +-0.1 | +-0.1 | |
| `rival_mult(r)` | `1.32 - 0.0055 r` | 1.32 | 1.265 | 1.21 | 1.155 | 1.10 | min 1.10 |
| `rival_time(n, r)` | `PAR_TIME[n] * rival_mult(r)`, `PAR_TIME = [0, 0, 0, 7.92, 6.53, 5.78]` (all-PERFECT time) | 10.45 (3g) | 10.02 (3g) | 7.90 (4g) | 7.54 (4g) | 6.36 (5g) | |
| `blow_on(r)` | `r >= GRACE_END (10)` | no | yes | yes | yes | yes | |
| `is_grace(r)` | `r < GRACE_END` | yes | no | no | no | no | |

Measured with the step model below (dt 1/60): heat run times. 3 gears: all PERFECT 7.92 s, all GOOD 8.22, all EARLY 8.73. 4 gears: 6.53 / 7.05 / 7.87. 5 gears: 5.78 / 6.50 / 7.65. Never shifting: 14.6 s. So: warm-up heats are won with any shifting at all; at r = 30 all-GOOD wins (7.05 < 7.54) but all-EARLY loses; at 5 gears you need some PERFECTs (all-GOOD 6.50 > 6.36).

**Phases** (by `heat_r`; the banner shows during that heat's staging instead of `HEAT N`; banners only on crossing, so at difficulty 1 the first is `FIFTH GEAR`):
| heat_r | New thing | Banner (40 px accent) |
|---|---|---|
| 0-10 | 3 gears, wide band, no blow-up, grace heat, the `SPACE OR TAP` label on the lever | `HEAT 1` |
| 10-20 | the red is live: 0.9 s at the redline blows the engine | `WATCH THE RED` |
| 20-30 | a 4th gear | `FOURTH GEAR` |
| 30-40 | the band moves per gear | `BAND MOVES` |
| 40+ | a 5th gear, rival floor | `FIFTH GEAR` |

Bot timeline at difficulty 0 (heat starts at r = 0, ~10.6, ~21.2, ~30.4): 3g, 3g, 4g, 4g-moving. So every phase up to BAND MOVES appears in a winning bot round.

**Car model (pure, in rules.gd; game.gd and simulate() use the same order every frame):**
```
CAPS = [22.0, 33.0, 48.0, 66.0, 86.0]   # m/s top speed per gear (index g = gear - 1)
REV  = [0.50, 0.42, 0.36, 0.31, 0.27]   # fraction of the cap gained per second
accel(g, boost_t, bog_t) = CAPS[g] * REV[g] * (BOOST_MULT 1.8 if boost_t > 0 else BOG_MULT 0.25 if bog_t > 0 else 1.0)
each frame:  a = accel(g, boost_t, bog_t); boost_t -= dt; bog_t -= dt
             v = min(CAPS[g], v + a * dt); d += v * dt; t += dt
             rpm = v / CAPS[g]
             if g < gears - 1 and rpm >= 1.0: red_t += dt  else red_t = 0
on shift (only if g < gears - 1): j = judge(rpm, lo, hi); g += 1; red_t = 0
             PERFECT: boost_t = BOOST_TIME (0.5)   EARLY: bog_t = BOG_TIME (0.7)
```
Speed carries over a shift, so the needle drops to `v / CAPS[g+1]` (about 0.55 after a 0.80 shift). `judge(rpm, lo, hi)`: rpm < lo = EARLY; rpm > hi = LATE; `abs(rpm - (lo+hi)/2) <= (hi-lo)/6` = PERFECT; else GOOD. The new gear's band is rolled when that gear is engaged (and for gear 1 at GO).

**Rival:** `rival_dist(t, T) = TRACK * pow(clamp(t / T, 0, 1), RIVAL_POW)`, RIVAL_POW = 1.6 (slow off the line, then strong). The rival reaches 300 m exactly at T.

## Look (palette hex + how each thing is drawn, per studio/VISION.md)
Colours: BG `#0B0E14`, PANEL `#151A24`, TRACE `#1E2738`, DIM `#6B7489`, INK `#E8ECF4`, ACCENT `#FF9F1C`, GOOD `#FFD34D` (PERFECT core, popups, heat-won marks), BAD `#FF3B5C` (red zone, fails). Nothing else. The slate calls it the "green band"; the palette has no green, so **the band is ACCENT with a GOOD perfect core**. That is deliberate, not a bug.

Screen map (1280 x 720):
| y | Band |
|---|---|
| 0-120 | HUD: score, lives, heat marks (x 170-1090 only) |
| 130-176 | banner |
| 196-476 | the road: rival lane (ground y 300) and player lane (ground y 446) |
| 492-508 | mini-map |
| 516-720 | GEAR box (left), tach (centre), lever (right) |

- **BG:** fill BG; 1 px TRACE grid at 40 px pitch over the whole screen.
- **Road:** PANEL rect x 0-1280, y 196-476; 2 px TRACE edge lines at y 196 and 476. Lane divider: DIM dashes 48 x 4 px, gap 48, centred y 372, scrolling left at `v * PX_PER_M` (`PX_PER_M = 6.0`): `x0 = -fposmod(d * PX_PER_M, 96)`. Distance ticks: 2 px TRACE vertical lines y 196-216 every 25 m (world), same scroll.
- **World to screen:** `sx(world_m) = FRONT_X + (world_m - d) * PX_PER_M` with `FRONT_X = 470` (the player car's front bumper). The player car never moves on screen.
- **Start and finish lines:** at world 0 and 300: a checker column 2 squares wide (16 px squares, INK and PANEL alternating) spanning y 196-476; drawn only when on screen. The finish line becomes visible at d >= ~165 m.
- **Staging tree:** at world 28 m (screen x 638 at the start, scrolls away after launch): 6 px TRACE pole y 200-470; 3 lights as circles r 16 at y 228, 268, 308 (centres x on the pole). Unlit: 2 px DIM outline. They light ACCENT one by one at staging t = 0.4, 0.8, 1.2 s; at 1.6 s (GO) all three turn GOOD with the glow (1.3x alpha 0.25, 1.6x alpha 0.10).
- **Cars** (one helper, anchored at the rear wheel ground point `p`, facing right, body 168 px long): body rect `p + (0, -52)`, size 168 x 30; cabin rect `p + (52, -74)`, 64 x 22; wing: rect `p + (-6, -76)`, 30 x 6 on a 4 x 22 post; rear slick: circle `p + (34, -22)` r 22; front wheel: circle `p + (140, -14)` r 14. Wheels: PANEL fill, 4 px INK ring, one 2 px INK spoke rotated by `d / wheel_r` (rolls with distance).
  - Player: rear at `FRONT_X - 168 = 302`, ground y 446. Body and cabin ACCENT (BAD while fail-tinted), 6 px INK outline on the body, glow (1.3x / 1.6x accent rects) only while boosting.
  - Rival: rear at `sx(d_rival) - 168`, ground y 300, body DIM, cabin TRACE, 4 px INK outline, no glow. Draw only if it overlaps x -200..1480.
  - **Boost flame** (while boost_t > 0): a GOOD triangle behind the player car `(302, 410), (302, 426), (302 - 40 - 20 * sin(TAU * 12 t), 418)`, plus 3 INK speed lines 2 px, 60-120 px long, behind the car at y 380 / 400 / 420.
  - **Squat on shift:** the player body is drawn scaled vertically by `squash` around the ground point (1.0 at rest, 0.85 just after a shift, back to 1.0 in 0.12 s: a drag car squats).
- **Mini-map:** 4 px TRACE line x 240-1040 at y 500; GOOD tick 4 x 20 at x 1040; rival DIM square 12 px at `240 + 800 * d_rival / TRACK`; player ACCENT square 14 px at `240 + 800 * d / TRACK` (drawn last).
- **Tach** (centre `TACH_C = (640, 712)`, radius `TACH_R = 170`, so its top is y 542): angle `Rules.needle_angle(rpm) = PI + PI * clamp(rpm, 0, RPM_MAX) / RPM_MAX`, `RPM_MAX = 1.1` (PI = pointing left, 1.5 PI = up, 2 PI = right). Arcs with `draw_arc(TACH_C, TACH_R - 14, a0, a1, 32, color, 24)`:
  - base arc rpm 0 to 1.0 in TRACE; red zone 1.0 to 1.1 in BAD (alpha 0.6; pulses full BAD at 4 Hz while red_t > 0);
  - the band lo..hi in ACCENT; its perfect core (centre +- width/6) in GOOD. While the needle is inside the band, the band arc is drawn again at width 36 and alpha 0.3 (glow). In the top gear the band is not drawn (base arc only), the red zone is drawn inactive (DIM alpha 0.35, no pulse: nothing can blow) and `TOP` shows inside the dial at `TACH_C + (0, -60)`, 28 px INK.
  - ticks every 0.1 rpm: 2 px DIM lines from radius 150 to 170; a 4 px INK tick at 1.0.
  - needle: 6 px INK line from `TACH_C` to radius 160 at `needle_angle(shown_rpm)`; hub circle r 14 INK. `shown_rpm` = `max(IDLE_RPM 0.08, rpm)`, eased: `shown_rpm = lerp(shown_rpm, target, 1 - exp(-30 dt))` so a shift visibly drops it; while red_t > 0, add a jitter `0.015 * sin(TAU * 25 t)` (limiter bounce).
- **GEAR box:** PANEL rect x 300-440, y 560-704, 4 px TRACE outline; `GEAR` 28 px DIM centred, baseline y 596; the gear digit 80 px INK centred, baseline y 690 (ACCENT for 0.2 s after a shift, with a 1.25x squash).
- **Lever:** `LEVER_RECT = Rect2(1010, 516, 160, 196)` (y 516-712): PANEL fill, 4 px TRACE outline; slot = 6 px TRACE line x 1090, y 556 to 660; knob circle r 36 ACCENT with 4 px INK ring at `(1090, knob_y)`, rest `knob_y = 640`; a shift kicks it to 568 and it eases back (out cubic) over 0.15 s. While the needle is in the band: the lever rect outline goes 6 px ACCENT and pulses (alpha 0.5 + 0.5 sin(TAU * 3 t)): the glow is the "shift now" hint. `SPACE OR TAP` (heat 1 only) 28 px DIM centred over the lever x, baseline y 706. (3 words.)
- **HUD** (x 170-1090; nothing at x < 150 or x > 1100 above y 70):
  - Score: 40 px INK, centred, baseline y 56.
  - Streak `X5` style is NOT shown (keep the HUD to score, lives, heats).
  - Lives: 3 squares 20 x 20 at y 70-90, centres x 608 / 640 / 672: ACCENT when alive, 2 px DIM outline when lost (BAD fill for 0.4 s right after).
  - Heat marks: 4 rects 36 x 14 at y 100-114, centres x 586 / 622 / 658 / 694: GOOD fill once won (1.25x squash on the frame it fills), 2 px DIM outline otherwise.
  - Banner: 40 px, centred, baseline y 168, 1.2 s, fades over the last 0.3 s. Staging banner ACCENT (`HEAT 2` or a phase name). Result banner: `HEAT WON` GOOD, `HEAT LOST` BAD, `BLOWN` BAD, `TRY AGAIN` DIM.
- No READY text, no other instructions.

## Sound (Synth presets/tones/loop used, per studio/VISION.md)
| Event | Call |
|---|---|
| Shift (the verb, every real gear change) | `Synth.sfx("shift", Rules.shift_pitch(streak))`, `shift_pitch = min(1.5, 1.0 + 0.04 * streak)`; `streak` = consecutive GOOD/PERFECT shifts (EARLY/LATE reset it to 0, after the sound) |
| PERFECT | also `Synth.sfx("coin", pow(2.0, mini(perfects, 12) / 12.0))`, `perfects` = PERFECTs in a row |
| GOOD | also `Synth.sfx("coin", 0.84)` (lower, so PERFECT sounds better) |
| EARLY (bog) / LATE | also `Synth.sfx("miss", randf_range(0.92, 1.08))` |
| Press with nothing to shift | `Synth.sfx("blip", 0.9)` |
| Staging lights 1-3 | `Synth.sfx("blip")`; GO: `Synth.sfx("jump")` (the car launches) |
| Heat won | `Synth.sfx("coin", 1.5)` |
| Heat lost (life lost) / engine blown | `Synth.sfx("boom", randf_range(0.95, 1.05))`; then `Synth.stop_loop()`, restart it 0.5 s later |
| Grace heat lost | `Synth.sfx("miss")` |
| Engine (custom tone) | every `ENGINE_TICK = 0.09` s while racing: `Synth.tone(Rules.engine_hz(rpm), 0.11, "square", ENGINE_VOL 0.10, Rules.engine_hz(rpm) * 1.04)`, `engine_hz(rpm) = 55.0 + 165.0 * clamp(rpm, 0, 1.1)` (55 Hz idle to ~240 Hz at the limiter). At the limiter (red_t > 0) skip every other tick (the stutter of a rev limiter). During staging: idle ticks at 60 Hz every 0.18 s. Never during the result beat. |
| Round intro | `blip` at 0.0 s and 0.3 s; loop starts at 0.6 s, then heat 1 staging begins |
| Round end | nothing (Arcade plays `win` / `lose`) |

Voices: the engine uses at most 2 of the 12 voices, the loop 1. A shift frame starts at most 3 sounds (engine tick + shift + coin/miss): fine.

**Music:** `Synth.loop(LOOP_NOTES, 140.0, "saw", 0.09)`, A minor pentatonic, low and bassy so the engine sits on top:
`LOOP_NOTES = [45, 0, 45, 57, 0, 45, 55, 0, 45, 0, 45, 57, 52, 0, 55, 57]` (A2 pumping, octave and G/E fills). From `FIFTH GEAR` (heat_r >= 40) restart it with every non-zero note +5 and vol 0.11.

## Juice list
1. **Shift (every real gear change):** in the same frame: gear digit flips with a 1.25x squash and ACCENT tint 0.2 s; lever knob kicks up and eases back 0.15 s; car squats (body y-scale 0.85 back to 1.0 over 0.12 s); the needle visibly drops (eased).
2. **PERFECT:** `Juice.burst(self, Vector2(300, 418), ACCENT)` (14, from the exhaust); `Juice.popup(self, Vector2(640, 520), "PERFECT +30", GOOD)`; boost flame + speed lines and car glow for 0.5 s; `Juice.shake(4)`.
3. **GOOD:** `Juice.popup(self, Vector2(640, 520), "+15", GOOD)`. **EARLY:** car tinted BAD 0.2 s, `Juice.shake(4)`, popup `EARLY` BAD; a DIM `Juice.burst` (8 particles, speed 120) at the exhaust (the bog cough). **LATE:** popup `LATE +5` DIM.
4. **Redline:** red zone pulses BAD at 4 Hz, needle jitters, engine stutters; after 0.45 s in the red (half of BLOW_TIME) the player car tints BAD on and off at 4 Hz: the warning before the blow.
5. **Engine blown / heat lost with a life:** `Juice.flash(Color(BAD, 0.35), 0.2)`, `Juice.shake(14)`, `Juice.hitstop(0.06)`, `Juice.burst(self, Vector2(380, 410), BAD)`; blown also adds a DIM smoke burst (20 particles, speed 160); after a blow the player car stays DIM with a TRACE cabin and rising grey smoke puffs through the whole result beat (`dead`, cleared on the next heat) and the red zone goes inactive; the loop goes silent 0.5 s.
6. **Heat won:** `Juice.burst(self, Vector2(FRONT_X, 410), GOOD)`, popup `"+%d" % heat_pts` in GOOD at (640, 300), `Juice.flash(Color(1, 1, 1, 0.15), 0.1)`, the heat mark fills GOOD with a squash.

## Build plan (scripts, data structures, every tunable with a start value)
Files (target ~600 lines total, each under 300):
- `rules.gd` (~120 lines, pure: no nodes, no autoloads): the constants and static functions below.
- `selftest.gd` (~50 lines): the assertions in the checklist.
- `game.gd` (~260 lines, `extends MicroGame`): state, `begin()`, `_process()` (intro, staging, race step, judge heat, engine ticks, bot), `_unhandled_input()`, `_shift()`, `_end_heat(result)`, `_draw()` calling the helpers.
- `strip_draw.gd` (~170 lines, `extends RefCounted`, static helpers taking `ci: CanvasItem` and a few values, calling `ci.draw_*` from inside `game.gd`'s `_draw()`; preload like Rules): `draw_backdrop`, `draw_road(ci, d)`, `draw_lines_and_tree(ci, d, lights, go)`, `draw_car(ci, p, body, cabin, outline_w, squash, spin)`, `draw_flame(ci, t)`, `draw_minimap`, `draw_tach(ci, shown_rpm, lo, hi, top_gear, red_t, t)`, `draw_gear_box`, `draw_lever(ci, knob_y, hot, t, label)`, `draw_hud(ci, score, lives, wins, banner, alpha)`.

**rules.gd functions:** `ramp_time(elapsed: float, difficulty: int) -> float`, `gears_for(r) -> int`, `band_width(r) -> float`, `band_offset(roll: int, r: float) -> float`, `band(r: float, roll: int) -> Vector2` (x = lo, y = hi, clamped to BAND_MIN_LO / BAND_MAX_HI), `judge(rpm, lo, hi) -> int` (EARLY 0, GOOD 1, PERFECT 2, LATE 3), `shift_points(j) -> int`, `accel(g, boost_t, bog_t) -> float`, `rpm(v, g) -> float`, `blow_on(r) -> bool`, `is_grace(r) -> bool`, `rival_mult(r)`, `rival_time(gears, r)`, `rival_dist(t, T) -> float`, `simulate(gears: int, shift_rpm: float, lo: float, hi: float) -> float` (runs the car model at dt 1/60 from v = 0 to TRACK, shifting the first frame rpm >= shift_rpm, applying judge effects; returns seconds; cap the loop at 60 s), `heat_bonus(margin_s) -> int`, `final_score(score, lives) -> int`, `shift_pitch(streak) -> float`, `needle_angle(rpm) -> float`, `engine_hz(rpm) -> float`, `phase_name(r) -> String` (`""` for 0-10).

**rules.gd tunables:**
| Name | Start value |
|---|---|
| EARLY, GOOD, PERFECT, LATE | 0, 1, 2, 3 |
| TRACK | 300.0 (m) |
| CAPS | [22.0, 33.0, 48.0, 66.0, 86.0] |
| REV | [0.50, 0.42, 0.36, 0.31, 0.27] |
| BOOST_MULT, BOOST_TIME | 1.8, 0.5 |
| BOG_MULT, BOG_TIME | 0.25, 0.7 |
| BLOW_TIME | 0.9 |
| BAND_CENTER | 0.80 |
| BAND_START, BAND_DROP, BAND_MIN | 0.30, 0.003, 0.16 |
| BAND_MIN_LO, BAND_MAX_HI | 0.40, 0.97 |
| MOVE_AT, MOVE_OFFSETS | 30.0, [-0.10, -0.05, 0.0, 0.05] |
| GEARS_4_AT, GEARS_5_AT | 20.0, 40.0 |
| GRACE_END | 10.0 |
| DIFFICULTY_OFFSET | 30.0 |
| PAR_TIME | [0.0, 0.0, 0.0, 7.92, 6.53, 5.78] |
| RIVAL_START, RIVAL_DROP, RIVAL_MIN | 1.32, 0.0055, 1.10 |
| RIVAL_POW | 1.6 |
| POINTS | [0, 15, 30, 5] (by judge) |
| HEAT_POINTS, MARGIN_PTS, LIFE_BONUS | 100, 50.0, 50 |
| PITCH_STEP, PITCH_MAX | 0.04, 1.5 |
| RPM_MAX, IDLE_RPM | 1.1, 0.08 |
| ENGINE_LO, ENGINE_SPAN | 55.0, 165.0 |

**game.gd tunables:** palette Colors above; `LIVES = 3`; `HEATS_TO_WIN = 4`; `INTRO_TIME = 0.6`; `STAGE_TIME = 1.6`, `LIGHT_TIMES = [0.4, 0.8, 1.2]`; `RESULT_TIME = 1.0`; `PX_PER_M = 6.0`; `FRONT_X = 470.0`; `CAR_LEN = 168.0`; `PLAYER_GROUND = 446.0`, `RIVAL_GROUND = 300.0`; `TREE_AT_M = 28.0`; `TACH_C = Vector2(640, 712)`, `TACH_R = 170.0`; `LEVER_RECT = Rect2(1010, 516, 160, 196)`, `KNOB_REST = 640.0`, `KNOB_KICK = 568.0`, `KNOB_TIME = 0.15`; `SQUAT = 0.85`, `SQUAT_TIME = 0.12`; `FAIL_TINT_TIME = 0.2`; `BANNER_TIME = 1.2`; `ENGINE_TICK = 0.09`, `ENGINE_VOL = 0.10`, `IDLE_TICK = 0.18`; `LOOP_NOTES` (above), `LOOP_BPM = 140.0`, `LOOP_VOL = 0.09`, `LOOP_VOL_TOP = 0.11`, `TOP_TRANSPOSE = 5`, `LOOP_RESTART_DELAY = 0.5`; `SHAKE_SOFT = 4.0`, `SHAKE_HARD = 14.0`, `HITSTOP = 0.06`; `BOT_SPREAD = 0.25`.

**State (game.gd):** `elapsed`, `intro`, `state` (enum STAGING, RACING, RESULT), `state_t`, `heat` (1-based), `heat_r`, `gears`, `rival_T`, `g`, `v`, `d`, `race_t`, `boost_t`, `bog_t`, `red_t`, `lo`, `hi` (current gear's band), `shown_rpm`, `score`, `streak`, `perfects`, `lives`, `wins`, `knob_t`, `squat_t`, `digit_t`, `fail_tint_t`, `life_flash_t`, `banner_text`, `banner_color`, `banner_t`, `last_phase`, `engine_t`, `loop_restart_t`, `bot_target`.

**Flow:**
- `begin()`: reset ALL state (Arcade calls it again on every retry and autoplay restart), lives 3, wins 0, heat 0, `intro = INTRO_TIME`; blips at 0.0 / 0.3 s; at intro end start the loop and `_start_heat()`.
- `_start_heat()`: `heat += 1; heat_r = Rules.ramp_time(elapsed, difficulty); gears = Rules.gears_for(heat_r); rival_T = Rules.rival_time(gears, heat_r)`; reset g 0, v 0, d 0, race_t 0, timers; roll the gear-1 band; banner = `Rules.phase_name(heat_r)` if the phase changed since the last heat, else `"HEAT %d" % heat`; state STAGING. (Top-gear loop transpose when the phase becomes FIFTH GEAR.)
- STAGING: lights + blips at LIGHT_TIMES; at STAGE_TIME: `jump`, state RACING.
- RACING (per frame): the car model step (exact order above); engine tick; `if red_t >= BLOW_TIME and Rules.blow_on(heat_r): _end_heat(BLOWN)`; `elif d >= TRACK: _end_heat(WON)`; `elif race_t >= rival_T: _end_heat(LOST)`. Player wins a same-frame tie.
- `_end_heat(result)`: WON: `wins += 1`, `score += HEAT_POINTS + Rules.heat_bonus(rival_T - race_t)`, juice; if `wins >= HEATS_TO_WIN`: `finish(Rules.final_score(score, lives), true)`; return. LOST / BLOWN: if `Rules.is_grace(heat_r)`: TRY AGAIN, no life lost; else `lives -= 1`, hard fail; if `lives <= 0`: `finish(score, false)`; return. Otherwise state RESULT for RESULT_TIME, then `_start_heat()`.
- `_shift()` (keys, taps and the bot): if state != RACING or `g >= gears - 1`: blip 0.9 + knob twitch; return. Else `j = Rules.judge(Rules.rpm(v, g), lo, hi)`; `g += 1`; red_t 0; roll the new gear's band; points, streak, sounds, juice per the tables; PERFECT sets boost_t, EARLY sets bog_t (and clears boost_t).
- Rival distance is only for drawing: `Rules.rival_dist(race_t, rival_T)`.

## Autoplay bot (how it plays; must reach finish() within 60 s)
- Runs in `_process` after the race step, only when `autoplay`, and calls the same `_shift()` as keys and taps.
- When a gear is engaged (and at GO) it rolls `bot_target = centre + randf_range(-BOT_SPREAD, BOT_SPREAD) * (hi - lo)` with `centre = (lo + hi) / 2`, so every bot shift is GOOD or PERFECT (about 2 in 3 PERFECT). It calls `_shift()` the first frame `Rules.rpm(v, g) >= bot_target` and `g < gears - 1`. It never presses in the top gear, staging or result.
- It wins every heat: worst case it is all-GOOD, and all-GOOD beats every rival it meets at difficulty 0 (3g 8.22 < 10.0; 4g 7.05 < 7.54 at r = 30). Timeline at difficulty 0: intro 0.6 + 4 x (1.6 staging + ~6.6-8.0 run) + 3 x 1.0 result beats = **about 40-41 s** to `finish(score, true)`. Even one lost heat would only add ~10 s (51 s), inside the gate's 3600 frames.
- This is a deliberate WIN: the autoplay log shows a cleared round, which also exercises the `true` finish path.
- Shots: frame 240 (4.0 s) is heat 1 about 1.8 s after GO, gear 1 or 2, needle climbing, rival close; frame 900 (15.0 s) is heat 2 a few seconds into the run (heat 1 ends ~10.3 s, result to ~11.3, staging to ~12.9), one heat mark GOOD.

## Acceptance checklist (6–10 testable items, incl. 2–4 rules.gd assertions)
1. `./scripts/check.sh geargrind` prints `PASS`; the autoplay log shows `ARCADE finished geargrind` with `won` true, within the 3600 frames (expected ~41 s).
2. **selftest, judging:** with lo 0.65, hi 0.95: `judge(0.60) == EARLY`, `judge(0.70) == GOOD`, `judge(0.80) == PERFECT`, `judge(0.96) == LATE`, `judge(1.05) == LATE`; `shift_points` gives 0 / 15 / 30 / 5; `shift_pitch(0) == 1.0`, `is_equal_approx(shift_pitch(5), 1.2)`, `shift_pitch(100) == 1.5`.
3. **selftest, ramp and difficulty:** `ramp_time(0.0, 1) == 30.0`, `ramp_time(12.0, 0) == 12.0`; `gears_for(0) == 3`, `gears_for(25) == 4`, `gears_for(45) == 5`; `band_width(1000) == BAND_MIN`; `band_offset(0, 29.9) == 0.0` and `band_offset(0, 30.0) == -0.10`; `is_grace(9.9)` and not `is_grace(10.0)`; `blow_on(10.0)` and not `blow_on(9.9)`; `rival_mult(1000) == RIVAL_MIN`.
4. **selftest, the race is fair (the model and the rival agree):** `abs(simulate(4, 0.80, 0.65, 0.95) - PAR_TIME[4]) < 0.15`; `simulate(3, 2.0, 0.65, 0.95) > rival_time(3, 0.0)` (never shifting loses even the warm-up); `simulate(3, 0.55, 0.65, 0.95) < rival_time(3, 0.0)` (all-early still wins the warm-up); `simulate(4, 0.88, 0.65, 0.95) < rival_time(4, 30.0)` (all-GOOD wins at r = 30); `rival_dist(rival_time(4, 20.0), rival_time(4, 20.0)) == TRACK`.
5. **Shot `start`:** BG with the TRACE grid; the PANEL road with both cars at the start line (amber player car below, grey rival above), the checker start line and the staging tree; the tach at bottom centre with an ACCENT band, GOOD core and BAD red zone; the GEAR box showing `1`; the lever on the right with `SPACE OR TAP`; score `0`, three amber life squares and four empty heat marks at top centre; nothing in the corners (x < 150 or x > 1100, y < 70).
6. **Shot `play-240`:** the tree has scrolled left or is lit GOOD; lane dashes and ticks show motion; the needle somewhere on the dial; the gear digit 1 or 2; possibly a PERFECT popup or boost flame.
7. **Shot `play-900`:** heat 2 in progress: one heat mark filled GOOD, score above 100, the cars at different distances (mini-map squares apart); HUD text at least 28 px; only palette colours; no empty glyph boxes.
8. **Code read (grep `games/geargrind`):** `Synth.sfx("shift", Rules.shift_pitch(streak))` inside `_shift`; `Synth.loop(` with `140.0, "saw"` and vol 0.09; engine via `Synth.tone(`; no `"win"` / `"lose"` sfx; `difficulty` used only via `Rules.ramp_time`; exactly one `finish(` with `true` and one with `false`.
9. **Touch and keys:** a mouse/tap press anywhere calls `_shift()` (no `InputEventScreenTouch` handler); Space, Up and W shift; Esc, P and M are not read by the game.

## GO moment (T-0015)
- At the end of staging (state_t 1.6 s) the three tree lights flash white (INK, bigger glow) for 0.12 s, then settle to GOOD; a 56 px `GO` banner in GOOD appears at y 176 (scale 1.3 to 1.0 over 0.2 s ease-out, fades over its last 0.3 s, 0.9 s total); the lever frame pulses amber at 3 Hz for the same 0.9 s; a faint white screen flash (0.12 alpha, 0.1 s) and the existing `jump` sfx mark the start. Countdown ticks already use `blip`.
- The `SPACE OR TAP` cue under the lever stays until the first successful shift of the round (`shifted_once`), no longer only heat 1's start.
- Shots: staging ends at frame ~140 at 60 fps (flash at 143, GO at 150); `play-260` shows the cue gone after the first shift.

## Out of scope
- Steering, lane changes, braking, throttle control, clutch, downshifts, a reverse gear: the only verb is shifting up.
- Jump starts / reaction-time judging at the lights (presses during staging just blip).
- A physics engine, Camera2D, scrolling backgrounds beyond the dashes, ticks and lines described, parallax, crowds.
- Car upgrades, garages, multiple tracks, a rival that reacts to you, nitro buttons.
- Speed/time readouts as text, a timer, splits, speedometers (the tach and mini-map carry it).
- Per-game title, READY or tutorial screens, settings, difficulty menu.
- Judging against the audio clock; the needle position at the press is the only judge.
- Files of any kind (sprites, samples, fonts): everything is `_draw()` and Synth.
- Gamepad support (a free bonus at most).

## QA note: `--sloppy`
Desktop only (ignored on web), autoplay only. `--sloppy` (launch arg, or `SHIFT_QA="--rstart=40 --sloppy"`) makes the bot shift late: heat 1 shifts only after 0.4 s in the red zone (needle pinned red, LATE shifts), later heats never shift so the engine BLOWS. Without the flag nothing changes. Example: `SHIFT_QA="--rstart=40 --sloppy" ./scripts/shots.sh geargrind 150 400`.

## Popup stagger and inactive red zone (T-0053)
- Shift popups no longer stack: `Rules.popup_slot(prev_slot, prev_age)` gives a popup born within `POP_LIFE` (0.95 s) of the previous one the next of 3 slots, `Rules.popup_slot_y` puts slot k at 520 + 40k. All popups rise on the same curve (70 px, 0.7 s, cubic ease-out), so slots stay 40 px apart for their whole life. A gap measured at birth from the earlier popup's birth or current y fails, because both rise to the same height (seen in QA). Age uses the game's accumulated `elapsed`, not wall clock. Selftest asserts slot choice and that the gap holds at later times. Shot: `SHIFT_QA="--rstart=40" ./scripts/shots.sh geargrind 840`.
- Inactive tach red zone (top gear or dead engine): DIM at alpha 0.5 plus 2 px DIM outline arcs on its edges, so it no longer reads as the TRACE base arc. Check shots 960 / 1020 with `--rstart=40`.
- Popup age uses the game's accumulated `elapsed` (game time), not wall clock, so it matches Juice's tweens under `--fixed-fps` and pause.
