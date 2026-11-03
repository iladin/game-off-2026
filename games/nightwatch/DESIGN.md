# Night Watch

<!-- Written by the Game Designer before any code. The Gameplay Engineer builds exactly this. -->
<!-- R0008, slate slot 7, sense NIGHT. Accent #8FA8FF (moon blue). Budget: about 30 min, under ~850 lines of GDScript. -->
<!-- Every number below was run through a 60 Hz Python model of exactly this Rules.step (20 seeds x difficulty 0 and 1, see "Simulated balance"). -->

## Pitch
You work the night shift in a security booth. Three hallway cameras, one big monitor. Something walks down each hallway toward your door, but **only while you are not watching it**. Switch feeds to freeze what you look at, and when one is close enough to see, hit the flash to send it back into the dark. Hold out from 12 to 6 on the wall clock to set the NIGHT bit.

## How it uses SHIFT
SHIFT = **the night shift**, and **shifting your gaze**. The one verb is switching the main monitor to another feed (keys 1 / 2 / 3, Left / Right, or tapping a thumbnail); every switch plays `Synth.sfx("shift", Rules.shift_pitch(streak))`. Watching is the defence (the watched creeper freezes), so every shift of attention is also a choice about which hallway you stop guarding. The flash is the payoff that only works on the feed you shifted to.

## Core loop
Every 1-3 s:
1. Glance at the three thumbnails (right column). Each shows a pair of eyes that grows as its creeper nears, and a border that warms from TRACE to BAD.
2. **Shift** the main view to the most dangerous feed. That creeper freezes the same frame.
3. If it is close enough to see (`d >= FLASH_MIN = 0.2`: its body is lit, outlined in moon blue), **flash** (Space or tap the main view): it is thrown back to the far door and you score more the closer it was.
4. The flash recharges for `FLASH_COOLDOWN = 1.0` s. Use that second to shift to the next feed.

The decision: which feed to leave unguarded, and how long to let a creeper come before flashing (closer = more points, but the others are creeping the whole time). Flashing an empty or too-far hallway wastes the charge and breaks the streak.

## Controls (keyboard AND touch)
| Action | Keyboard | Touch / mouse |
|---|---|---|
| Watch feed 1 / 2 / 3 | `1` / `2` / `3` (also keypad 1-3) | tap thumbnail 1 / 2 / 3: `THUMB_RECTS[i] = Rect2(930, 150 + i * 160, 300, 144)` (300 x 144, well over 96 px) |
| Previous / next feed (wraps) | Left or A / Right or D | (none needed) |
| Flash | Space (also Enter, Up or W) | tap anywhere in the main view `MAIN_RECT = Rect2(170, 140, 730, 450)` or on the lamp pad `LAMP_RECT = Rect2(170, 600, 730, 104)` |

- Read `InputEventKey` (`pressed and not echo`, by `physical_keycode`) and `InputEventMouseButton` (MOUSE_BUTTON_LEFT, pressed) in `_unhandled_input`, so Arcade's HUB / SOUND buttons take their clicks first. `emulate_mouse_from_touch=true`: do NOT also handle `InputEventScreenTouch`. Never Esc, P or M.
- Hit test: `Rules.tap_target(pos) -> int`: 0, 1, 2 for a thumbnail, `TAP_FLASH = 3` for the main view or lamp pad, -1 otherwise.
- Switching to the feed already watched does nothing (no sound). Keys and taps call the same two functions, `_switch(i)` and `_flash()`, so touch alone earns the same score.
- Ignore input when `autoplay`, `is_finished()`, or during the 0.6 s intro.

## Round: fail / win, score
- **Win (sets the NIGHT bit):** survive to `t >= ROUND_TIME = 48.0` s (6 hours of `HOUR_LEN = 8.0` s; the clock reads 12, 1, 2, 3, 4, 5, 6 AM). `finish(Rules.final_score(score, lives), true)` that frame. Every surviving round is 48.6 s including the intro, at any difficulty.
- **Lives:** 3, moon blue squares at top centre.
- **Hard fail = breach:** a creeper's `d >= 1.0` (it reached the door). Then `Rules.breach(s, i)`: that creeper back to `d = 0` with a new speed, every other creeper clamped to `d <= BREACH_CALM = 0.5`, streak 0. **Grace:** while `r < GRACE_END = 10` a breach costs no life (soft-fail feedback, popup `WATCH` in DIM). The model's idle player first breaches at t 12.1, so the grace is a second safety net.
- **Lose:** lives reach 0: `finish(score, false)` in the same frame as the hard-fail effects; return; `finish()` exactly once.
- **Score:**
  - **Flash hit** (watched `d >= FLASH_MIN`): `Rules.flash_points(d, streak) = FLASH_PTS 10 + int(DIST_PTS 40 * d) + STREAK_PTS 5 * min(streak, STREAK_CAP 10)`, then `streak += 1`.
  - **Flash miss** (dormant feed, or `d < FLASH_MIN`): 0 points, `streak = 0`, cooldown still spent.
  - **Hour survived:** `+HOUR_PTS = 50` each time `int(t / HOUR_LEN)` goes up (hours 1-5 inside the round; the 6 AM one lands in the win frame, so 6 x 50 on a win).
  - **Win:** `+LIFE_BONUS = 150` per life left.
  - Model: the bot scores 2,960-3,070 at difficulty 0 (4,290-4,420 at 1); a human model reacting in 0.6 s scores 2,240-2,400.
- **Typical length:** 48.6 s; an idle player loses all 3 lives between t 22 and 25.

## Ramp (with numbers)
Round time `t` counts from the loop start. Ramp time `r = Rules.ramp_time(t, difficulty) = t + (DIFFICULTY_OFFSET 30.0 if difficulty >= 1 else 0.0)`. Everything reads `r`; nothing else reads `difficulty`.

| r (s) | New thing | Fill time `fill_time(r)` (s, door in that long at speed 1) | Awake feeds | Banner `phase_name(r)` | Hints |
|---|---|---|---|---|---|
| 0-10 | one creeper on CAM 2 (you start on CAM 1, so it walks); its first speed is exactly 1.0 | 14.0 to 11.0 | 2 | `""` | on |
| 10-20 | **CAM 3 wakes** | 11.0 to 8.0 | 2, 3 | `CAM 3` | on |
| 20-30 | **CAM 1 wakes** (the feed you started on) | 8.0 to 5.0 | 1, 2, 3 | `CAM 1` | on |
| 30+ | **IT MOVES**: the watched creeper also creeps, at `WATCHED_FRAC = 0.25` speed; no hints | 5.0 to 4.0 (clamp at r 33.3) | all | `IT MOVES` | off |

- `fill_time(r) = max(FILL_MIN 4.0, FILL_START 14.0 - FILL_RAMP 0.3 * r)`. A creeper's `d` grows by `speed * k / fill_time(r) * dt`, `k = 1` if unwatched, `0` if watched (or `WATCHED_FRAC` when `r >= WATCHED_AT 30`).
- Waking: the first frame `r >= WAKE_AT[i]` (`WAKE_AT = [20.0, 0.0, 10.0]` for CAM 1, 2, 3): `awake[i] = true`, `d = 0`, `speed = 1.0` if `r < GRACE_END` else `rng.randf_range(SPD_LO 0.85, SPD_HI 1.2)`. Every repel and breach re-rolls the speed the same way. At difficulty 1 all three wake on frame 1 with random speeds.
- `hints_on(r)`: `r < HINTS_END 30`. `is_grace(r)`: `r < GRACE_END 10`. Banners show when `phase_name(r)` differs from the last shown (start `""`), so difficulty 1 shows `IT MOVES` at once.
- `danger_band(s)` (music and heartbeat, below): max `d` over awake **unwatched** feeds: band 0 under 0.5, band 1 under 0.75, band 2 at or above. Hysteresis: drop a band only when `d` is 0.05 under its threshold.

### Simulated balance (Python model of this exact step, dt 1/60, seeds 1-20)
| Player | d 0: wins / breaches | d 1: wins / breaches | notes |
|---|---|---|---|
| Bot (below) | 20 / 0 | 20 / 0 | max `d` 0.67; 33 flashes, 34 shifts per round (d 0) |
| Idle (never touches anything) | 0 / 60 | 0 / 60 | first breach t 12.1 (d 0), lose at t 22-25 |
| Human model: same priorities, 0.3 s late | 20 / 0 | 20 / 0 | |
| Human model: 0.6 s late | 20 / 0 | 20 / 0 | max `d` 0.88-0.98: it gets close |
| Human model: 0.9 s late | 10 / 43 | 0 / 60 | a slow or hesitant player loses lives after r 30 |
Doing nothing loses; a quick player wins clean; the last hours (IT MOVES, fill 4 s) are where hesitation costs lives.

## The step (`Rules.step`, pure, shared by the game, the bot and the selftest)
`class Watch` (inner class, `extends RefCounted`): `d: PackedFloat32Array = [0,0,0]`, `speed: PackedFloat32Array = [1,1,1]`, `awake: Array[bool] = [false,false,false]`, `watched: int = 0`, `cooldown: float = 0`, `static_t: float = 0`, `last_q: PackedInt32Array = [0,0,0]` (quarter of `d` last frame, for footsteps), `breach_i: int = -1`, `flash_d: float = 0`.

`switch(s, i) -> int`: if `i == s.watched` return 0; `s.watched = i; s.static_t = SWITCH_STATIC (0.15)`; return `EV_SHIFT (1)`.
`flash(s, rng) -> int`: if `s.cooldown > 0 or s.static_t > 0` return 0 (pressing during cooldown is ignored, the lamp pad just blinks DIM). Else `s.cooldown = FLASH_COOLDOWN`; if `awake[w] and d[w] >= FLASH_MIN`: `s.flash_d = d[w]; d[w] = 0; speed[w] = reroll`; return `EV_REPEL (2)`; else return `EV_EMPTY (4)`.
`step(s, dt, r, rng) -> int`, in this order:
1. Timers: `cooldown`, `static_t` down to 0.
2. Wake any feed with `r >= WAKE_AT[i]`.
3. Creep: for each awake feed, `d[i] += speed[i] * k * dt / fill_time(r)` (k as in Ramp). If an **unwatched** feed's `int(d * 4)` goes above `last_q[i]` (quarters 1-3): ev |= `EV_STEP (8)`, `step_i = i`. Update `last_q`.
4. Breach: the first feed with `d >= 1.0`: ev |= `EV_BREACH (16)`, `breach_i = i`, `Rules.breach(s, i, rng)` (d 0, reroll speed, others clamped to `BREACH_CALM`, `last_q` recomputed). The game decides grace vs life.

## Look (palette hex + how each thing is drawn, per studio/VISION.md)
Colours: BG `#0B0E14`, PANEL `#151A24`, TRACE `#1E2738`, DIM `#6B7489`, INK `#E8ECF4`, ACCENT `#8FA8FF`, GOOD `#FFD34D`, BAD `#FF3B5C`. Nothing else (tints = alpha only).

Screen map (1280 x 720):
| Region | Rect | Content |
|---|---|---|
| HUD | x 170-1090, y 0-130 | score, lives, clock |
| Main view | `MAIN_RECT` (170, 140) 730 x 450 | the watched hallway, big |
| Lamp pad | `LAMP_RECT` (170, 600) 730 x 104 | flash charge |
| Thumbnails | `THUMB_RECTS` x 930-1230, y 150-614 | the three feeds, small |
| Clock | centre (1080, 668), radius 44 | wall clock under the thumbnails |

- **BG:** fill BG; 1 px TRACE grid at 40 px pitch.
- **Hallway** (`draw_hall(ci, rect, alpha)`, used by the main view and, scaled, by the thumbnails): PANEL fill; a one-point perspective corridor: vanishing point at `rect` centre-x, 38% down; floor and ceiling edges as four 2 px TRACE lines from the corners to a far door rect (14% of the width, 30% of the height, 2 px DIM outline, BG fill); three 2 px TRACE cross lines on the floor at depths 0.25 / 0.5 / 0.75 (the same quarters as the footsteps). Fixed per feed except a small door-light circle (radius 6, DIM) in a different top corner per feed so the three halls read as three places.
- **Creeper** in the main view, at `d`: depth `z = d`; foot point lerps from the door's bottom centre to the rect's bottom centre (minus 20 px) with `ease(z, 2.0)` (it speeds up visually as it nears); scale `0.18 + 0.82 * z` of a full size body 200 x 330 px: a body rect (squared) plus a head circle (radius 0.22 x width), filled BG. Visibility: `d < FLASH_MIN`: body not drawn, only the eyes; `d >= FLASH_MIN`: body drawn with a 4 px ACCENT outline and, while `hints_on(r)`, the glow (1.3x alpha 0.25, 1.6x alpha 0.10 in ACCENT, pulsing 3 Hz). Eyes: two INK circles (radius `3 + 13 * z`; from z 0.5 a BAD alpha 0.25 halo at twice the radius; a faint INK inner edge, alpha `0.35 + 0.25 z`, on the lit body)  30% of the head width apart, always drawn; they blink (hidden for 0.12 s) every 2.5 s per feed, offset by feed index. Sleeping feed (`not awake`): no creeper, eyes absent.
- **Main view frame:** 6 px ACCENT outline (it is the player's focus); a `CAM 1` style label is NOT used: instead a 40 px INK digit (`"1"`, `"2"`, `"3"`) in the top-left at (186, 150) and a small BAD recording dot (circle radius 8 at (870, 162)) blinking at 1 Hz. On a switch: static for `SWITCH_STATIC` (120 random 4 x 2 INK rects at alpha 0.5 inside the rect, re-rolled each frame; the hall underneath at alpha 0.3).
- **Thumbnails:** each `draw_hall` scaled into its rect at alpha 0.6, with permanent light static (24 random 3 x 2 DIM dots per frame); only the creeper's **eyes** are drawn (no body: you must look to see it), size `2 + 5 * d`, positioned like the main view mapping. Digit `"1"`/`"2"`/`"3"` 32 px DIM top-left. Border 4 px, colour `TRACE.lerp(BAD, clamp((d - 0.4) / 0.5, 0, 1))`; when `d >= 0.75` it pulses (alpha `0.6 + 0.4 sin(TAU * 4 t)`). The watched thumbnail: 6 px ACCENT border and dark (BG at alpha 0.88 over it, drawn even while that feed is asleep, it is on the big screen). **Hint** (`hints_on(r)`): the unwatched feed with the highest `d` among those `>= FLASH_MIN` gets an ACCENT glow on its border (1.3x / 1.6x rect glow) and a filled ACCENT triangle (24 wide) pointing left at its left edge (x 914). Sleeping thumbnails: PANEL with a 2 px TRACE outline, no hall.
- **Lamp pad** (`LAMP_RECT`): PANEL fill, 4 px TRACE outline; a lamp circle (radius 30) at (230, 652): ACCENT fill when ready, DIM when recharging; a charge bar x 290-880, y 640-664: TRACE fill, ACCENT fill to `1 - cooldown / FLASH_COOLDOWN`. When ready **and** the watched creeper is flashable, the lamp and the pad outline glow and pulse at 3 Hz (the correct-response glow). The word `FLASH` 28 px DIM centred under the bar at baseline y 696 is the only instruction word on screen (1 word).
- **Clock:** circle radius 44, PANEL fill, 4 px DIM outline, 12 ticks (2 px TRACE); hour hand (6 px INK) pointing at hour `t / HOUR_LEN` (12 o clock at t 0, 6 at t 48: angle `-PI / 2 + TAU * (t / HOUR_LEN) / 12`); minute hand (4 px ACCENT) sweeping once per `HOUR_LEN`. The hour text `Rules.clock_text(t)` (`"12 AM"`, `"1 AM"` ... `"6 AM"`) at 28 px INK, left of the clock, right edge at x 1024, baseline y 680.
- **HUD:** score 40 px INK centred at x 640 (top centre of the HUD band), baseline y 52; lives 3 squares 20 x 20 at y 62-82, centres x 608 / 640 / 672 (ACCENT alive; 2 px DIM outline lost; BAD fill 0.4 s after loss). Banner 40 px ACCENT centred at x 535 (over the main view), baseline y 122, 1.2 s, fades over the last 0.3 s. Nothing at x < 150 or x > 1100 above y 70.
- **Darkness:** danger band 2: a BG rect at alpha 0.25 over the whole screen except the main view (the room gets darker as it closes in).
- The only words ever on screen: digits, the score, `FLASH`, the hour text, banners, popups (`+N`, `WATCH`, `6 AM`). No READY text, no arrows (triangles are drawn).

## Sound (Synth presets/tones/loop used, per studio/VISION.md)
| Event | Call |
|---|---|
| Feed switch (the verb, `EV_SHIFT`) | `Synth.sfx("shift", Rules.shift_pitch(streak))`, `shift_pitch = min(1.5, 1.0 + 0.04 * streak)`; plus the static: `Synth.tone(2400.0, 0.12, "noise", 0.12, 900.0)` |
| Flash repels (`EV_REPEL`) | `Synth.sfx("hit", randf_range(0.92, 1.08))` and `Synth.sfx("coin", pow(2.0, mini(streak, 12) / 12.0))` (streak before the increment) |
| Flash on nothing (`EV_EMPTY`) | `Synth.sfx("miss", randf_range(0.92, 1.08))` |
| Footstep in an unwatched hall (`EV_STEP`) | `Synth.tone(90.0 + 30.0 * q, 0.07, "noise", 0.10 + 0.06 * q, 50.0)` for quarter `q` 1-3 (louder and higher as it nears): you can hear where you are not looking |
| Heartbeat (danger band >= 1) | `Synth.tone(55.0, 0.12, "sine", 0.35, 42.0)` then a second one 0.18 s later; repeats every `HEART_GAP = [0, 1.0, 0.55][band]` s |
| Breach in grace | `Synth.sfx("miss", 0.8)` |
| Breach (life lost) | `Synth.sfx("boom", randf_range(0.95, 1.05))`; `Synth.stop_loop()`; loop restarts after 0.5 s |
| Hour passes | `Synth.sfx("blip", 0.5)` twice, 0.25 s apart (a chime) |
| Banner | `Synth.sfx("blip", 1.5)` |
| Round intro | `blip` at 0.0 and 0.3 s; loop starts at 0.6 s and `t` starts at 0 that frame |
| Round end | nothing (Arcade plays `win` / `lose`) |

**Music (silence is information):** sine, 70 bpm, `LOOP_VOL = 0.10`, A minor pentatonic, mostly rests. Band 0: `LOOP_CALM = [45, 0, 0, 52, 0, 0, 48, 0, 0, 0, 57, 0, 55, 0, 0, 0]`. Band 1: `LOOP_THIN = [45, 0, 0, 0, 0, 0, 0, 0, 44, 0, 0, 0, 0, 0, 0, 0]` (just a low pulse and a flat second). Band 2: `Synth.stop_loop()`: silence and the heartbeat. Call `Synth.loop` / `stop_loop` only when the band changes (after hysteresis) or after a breach restart. At most 3 SFX start in one frame: flash (2) never coincides with a switch (static blocks flash); footsteps are skipped in a frame that already started 2.

## Juice list (each item names its state variable; QA checks it is set in the trigger and read in a draw call)
| # | Event (trigger in game.gd) | Effect | State set there, read in drawing |
|---|---|---|---|
| 1 | `EV_SHIFT` | main view static (see Look); the new thumbnail's border squashes 1.25 then back over 0.12 s; main frame slides in 12 px from the side you came from, ease out cubic 0.15 s | `switch_fx_t = 0.15`, `switch_from` |
| 2 | `EV_REPEL` | `Juice.flash(Color(INK, 0.15), 0.1)` (the camera flash); the creeper's silhouette is drawn at its old `flash_d` in INK at alpha 1 fading to 0 over 0.25 s while shrinking toward the door; `Juice.burst(self, creeper_pos, ACCENT, 14)`; popup `+N` GOOD 32 px at the creeper | `flash_fx_t = 0.25`, `flash_fx_d`, `flash_fx_feed` |
| 3 | `EV_EMPTY` | main frame tinted BAD 0.2 s; `Juice.shake(4)` | `empty_t = 0.2` |
| 4 | `EV_STEP` | that thumbnail jolts 4 px down and back over 0.1 s | `step_t[i] = 0.1` |
| 5 | Hour passes | clock face flashes GOOD outline 0.3 s; popup `+50` GOOD at the clock; at 6 AM popup `6 AM` GOOD 40 px | `hour_flash_t = 0.3` |
| 6 | Breach in grace | thumbnail of that feed BAD 0.2 s; `Juice.shake(4)`; popup `WATCH` DIM 32 px at the main view centre | `breach_tint_t = 0.2`, `breach_feed` |
| 7 | Breach (life lost) | `Juice.flash(Color(BAD, 0.35), 0.2)`, `Juice.shake(14)`, `Juice.hitstop(0.06)`, `Juice.burst(self, thumb_centre, BAD)`; a full-size creeper silhouette (BG fill, BAD 6 px outline) fills the main view for 0.3 s; lost life square BAD 0.4 s; loop silent 0.5 s | `jump_t = 0.3`, `life_flash_t = 0.4`, `loop_restart_t = 0.5` |
| 8 | Danger band 2 | darkness overlay; the watched-frame recording dot blinks at 4 Hz | `band` |
| 9 | Banner change | fades in/out as above | `banner_text`, `banner_t` |

## Build plan (scripts, data structures, every tunable with a start value)
Files (target ~780 lines, each under 300):
- `rules.gd` (~200 lines, pure: no nodes, no autoloads; a passed-in `RandomNumberGenerator`): constants, inner class `Watch`, static functions `ramp_time`, `fill_time`, `phase_name`, `hints_on`, `is_grace`, `reroll_speed(r, rng)`, `switch`, `flash`, `step`, `breach`, `danger(s)` (max unwatched awake d), `danger_band(dmax, prev_band)`, `flash_points`, `shift_pitch`, `final_score`, `clock_text`, `tap_target`, `hint_feed(s)` (feed to glow, or -1), `bot_action(s) -> int` (0-2 = switch to feed, 3 = flash, -1 = nothing), `sim_round(seed, difficulty, idle := false) -> Dictionary` (`won`, `time`, `breaches`, `first_breach`, `max_d`, `score`, `flashes`, `shifts`, `empties`).
- `selftest.gd` (~100 lines): the assertions in the checklist; prints `SELFTEST OK`.
- `game.gd` (~260 lines, `extends MicroGame`): state, `begin()`, `_process()`, `_unhandled_input()`, `_switch(i)`, `_flash()`, `_on_events(ev)`, `_breach()`, `_set_band()`, `_draw()` calling the helpers.
- `watch_draw.gd` (~220 lines, `extends RefCounted`, static helpers taking `ci: CanvasItem`): `draw_backdrop`, `draw_hall(ci, rect, feed, alpha)`, `draw_creeper(ci, rect, d, lit, glow, t, feed)`, `draw_static(ci, rect, n, rng)`, `draw_thumbs(...)`, `draw_lamp(...)`, `draw_clock(ci, font, t)`, `draw_hud(...)`, `glow_rect(...)`.

**Per-frame order in `_process(dt)` (`sim_round` uses the same order with `dt = 1/60`):**
1. Intro / juice timers / loop restart / heartbeat timer. 2. `t += dt; r = ramp_time(t, difficulty)`. 3. Input: if `autoplay`, every `BOT_THINK = 0.12` s (timer reset only when it acts): `a = Rules.bot_action(watch)`; `a` 0-2 calls `_switch(a)`, 3 calls `_flash()` (the same functions the keys and taps call). Human input already ran in `_unhandled_input` this frame. 4. `ev = Rules.step(watch, dt, r, rng)`. 5. `_on_events(ev)` (on `EV_BREACH`: grace or life; lives 0: `finish(score, false)`; return). 6. Hour check (`int(t / HOUR_LEN)` up: `+HOUR_PTS`, chime). 7. If `t >= ROUND_TIME`: `finish(Rules.final_score(score, lives), true)`; return. 8. Danger band (music), banner check, `queue_redraw()`.

**rules.gd tunables:**
| Name | Start value |
|---|---|
| EV_SHIFT, EV_REPEL, EV_EMPTY, EV_STEP, EV_BREACH | 1, 2, 4, 8, 16 |
| FEEDS, START_FEED | 3, 0 (CAM 1) |
| WAKE_AT | [20.0, 0.0, 10.0] |
| FILL_START, FILL_RAMP, FILL_MIN | 14.0, 0.3, 4.0 |
| SPD_LO, SPD_HI | 0.85, 1.2 |
| WATCHED_AT, WATCHED_FRAC | 30.0, 0.25 |
| FLASH_MIN, FLASH_COOLDOWN, SWITCH_STATIC | 0.2, 1.0, 0.15 |
| BREACH_CALM, LIVES | 0.5, 3 |
| ROUND_TIME, HOUR_LEN, GRACE_END, HINTS_END, DIFFICULTY_OFFSET | 48.0, 8.0, 10.0, 30.0, 30.0 |
| FLASH_PTS, DIST_PTS, STREAK_PTS, STREAK_CAP, HOUR_PTS, LIFE_BONUS | 10, 40, 5, 10, 50, 150 |
| PITCH_STEP, PITCH_MAX | 0.04, 1.5 |
| BAND_1, BAND_2, BAND_HYST, HEART_GAP | 0.5, 0.75, 0.05, [0.0, 1.0, 0.55] |
| BOT_THINK, BOT_MARGIN | 0.12, 0.15 |
| MAIN_RECT, LAMP_RECT, THUMB_RECTS, TAP_FLASH | see Controls, 3 |
game.gd: `INTRO = 0.6`, `BANNER_TIME = 1.2`, `LOOP_VOL = 0.10`, `LOOP_BPM = 70.0`, `LOOP_CALM`, `LOOP_THIN`.

## Autoplay bot (how it plays; must reach finish() within 60 s)
`Rules.bot_action(s)`, called every `BOT_THINK = 0.12` s of game time and fed through `_switch` / `_flash` (real inputs, same code as keys and taps):
1. `fw = awake[watched] and d[watched] >= FLASH_MIN`. If `fw and cooldown <= 0 and static_t <= 0`: return 3 (flash).
2. Else `j` = the awake unwatched feed with the highest `d`. If `d[j] >= FLASH_MIN` and (`not fw` or `d[j] > d[watched] + BOT_MARGIN 0.15`): return `j` (switch).
3. Else return -1 (wait; the watched creeper is frozen and the others are still far).
The margin stops it flicking between two feeds while the flash recharges. In the model it never breaches (max `d` 0.67 at difficulty 0 and 1) and always reaches `finish(_, true)` at t 48.0 (48.6 s with the intro), under the 60 s limit. It never flashes an empty hall.

## Acceptance checklist (6–10 testable items, incl. 2–4 rules.gd assertions)
1. **Gate:** `./scripts/check.sh nightwatch` prints PASS (glyph lint, import, smoke, autoplay round reaching `finish` with `won == true` at about 48.6 s, selftest).
2. **selftest, ramp:** `ramp_time(5, 0) == 5`, `ramp_time(5, 1) == 35`; `fill_time(0) == 14.0`, `fill_time(20) == 8.0`, `fill_time(100) == 4.0`; `phase_name(5) == ""`, `phase_name(15) == "CAM 3"`, `phase_name(25) == "CAM 1"`, `phase_name(35) == "IT MOVES"`; `is_grace(9.9)` and not `is_grace(10.0)`; `hints_on(29.9)` and not `hints_on(30.0)`; `clock_text(0) == "12 AM"`, `clock_text(8.0) == "1 AM"`, `clock_text(47.9) == "5 AM"`, `clock_text(48.0) == "6 AM"`.
3. **selftest, step:** (a) a fresh `Watch`, 60 frames at r 0: feed 2 awake, `d[1]` within 1e-3 of `1/14`, feed 1 (watched) and 3 asleep at 0; (b) switch to feed 2 (`EV_SHIFT`), then 300 frames at r 5: `d[1]` unchanged (watched freezes) and `switch` to the same feed returns 0; (c) at r 35 the watched feed creeps at a quarter of the unwatched rate (within 1e-3); (d) `flash` with watched `d = 0.1` returns `EV_EMPTY` and sets cooldown 1.0; a second `flash` at once returns 0; with `d = 0.6` and cooldown 0 it returns `EV_REPEL`, `d` becomes 0 and `flash_d == 0.6`; (e) `d` forced to 0.99 on an unwatched feed with another at 0.8: the next frames give `EV_BREACH` once, that feed is 0 and the other is <= 0.5; (f) an unwatched feed crossing 0.25, 0.5 and 0.75 gives exactly 3 `EV_STEP`.
4. **selftest, the bot and the idle player:** for seeds 1-20, `sim_round(seed, 0)` and `sim_round(seed, 1)`: `won`, `breaches == 0`, `time` in 47.9-48.1, `empties == 0`, `flashes >= 25`, `max_d < 0.85`; `sim_round(seed, 0, true)` (idle) is not `won`, `first_breach > 10.0`, and ends before t 30.
5. **selftest, scoring and input:** `flash_points(0.5, 0) == 30`, `flash_points(0.5, 99) == 80`; `shift_pitch(100) == 1.5`; `final_score(1000, 2) == 1300`; `tap_target(Vector2(1000, 200)) == 0`, `tap_target(Vector2(1000, 520)) == 2`, `tap_target(Vector2(500, 300)) == 3`, `tap_target(Vector2(500, 650)) == 3`, `tap_target(Vector2(1260, 700)) == -1`; every `THUMB_RECTS` entry is at least 96 px each way; `danger_band(0.6, 0) == 1`, `danger_band(0.8, 0) == 2`, `danger_band(0.72, 2) == 2`, `danger_band(0.68, 2) == 1`, `danger_band(0.47, 1) == 1`, `danger_band(0.44, 1) == 0`.
6. **Shot `start`:** BG with the TRACE grid; main view (6 px moon blue frame) showing a hallway with a door; three thumbnails on the right (feed 1 dark as watched, feed 2 with small eyes, feed 3 sleeping PANEL); lamp pad with `FLASH`; clock at 12 with `12 AM`; score `0`, three moon blue life squares; nothing in the corners (x < 150 or x > 1100, y < 70).
7. **Shot `play-900`** (15 s into the bot round): the clock past 12; score above 100; a lit creeper or static on the main view or eyes in at least one thumbnail; HUD text at least 28 px; only palette colours; no empty glyph boxes.
8. **Code read (grep `games/nightwatch`):** `Synth.sfx("shift", Rules.shift_pitch(streak))` in `_switch`; `Synth.loop(` uses `70.0, "sine"`; no `"win"` / `"lose"` sfx; `difficulty` used only via `Rules.ramp_time`; exactly one `finish(` with `true` and one with `false`; the bot path is `Rules.bot_action` into `_switch` / `_flash` (game.gd never writes `watch.d` or `watch.watched` directly); no `InputEventScreenTouch`; Esc, P and M not read.
9. **Juice wired:** for each Juice row, the named state variable is assigned in the named trigger and read in a draw function (grep both); `Juice.flash`, `Juice.shake`, `Juice.hitstop`, `Juice.burst` and `Juice.popup` each appear in game.gd.
10. **Touch:** a tap at (1080, 380) watches feed 2 (shift sound, static); a tap on the main view flashes; a tap on the HUB or SOUND button does neither.

## Out of scope
- Doors, power meters, battery management, multiple rooms or a map; more than 3 feeds.
- Jump-scare screams, recorded audio, any file asset (everything is `_draw()` and Synth).
- Creepers with faces, names or characters from other games; gore.
- Tutorial text, READY screens, per-game menus.
- Symbols on screen: no arrow glyphs (hints draw triangles).
- Gamepad support (a free bonus at most).

## R0010 notes
- `begin()` builds the Watch with `Rules.fresh()` (watched = START_FEED) and runs one zero-dt `Rules.step` so the opening feeds are awake on frame 1 (feed 2 shows its eyes in the start shot).
- QA flag `--nwqa` (after `--`): an idle player who switches to CAM 2 at t 8, for shots of the full-size creeper: `--game=nightwatch --nwqa --shotfile=<png> --shotframes=1250` (no `--autoplay`).

## R0013 notes (T-0035: danger in view)
- Unwatched awake feed with `d >= CUE_OUTLINE_D 0.3` (about 4 s in for the first creeper): its thumbnail gets a pulsing BAD 4 px outline (3 Hz, just outside the thumb border).
- Unwatched awake feed with `d > CUE_BAR_D 0.6` (about 8 s in): a 6 px BAD bar pulses at 3 Hz on the main view's right edge, level with that feed's thumbnail (`draw_danger_bars` in watch_draw.gd).
- The watched creeper's body is already 140 px tall at d 0.3 (330 x (0.18 + 0.82 d)), so the 40 px minimum holds from d 0.2.
- Shots: `idle-560.png` and `idle-620.png` (no input, ~10 s of game time) show bar and outline.

## R0014 notes (T-0041: stronger danger cues)
- One implementation, in watch_draw.gd (`draw_thumbs`, `draw_danger_bars`); the R0013 cues are replaced. BAD alpha pulses `CUE_MIN_A 0.6 + 0.4 * pulse` at 3 Hz, so it never drops below 0.6.
- Thumbnail outline (unwatched awake, `d >= 0.3`): 4 px, inset 5-9 px INSIDE the thumb (the thumb border ends 2 px in: 3 px clear of the outward hint glow and its ACCENT border).
- Main-view bar (`d > 0.6`): 8 px wide at x 886-894, level with the feed's thumbnail: 3 px clear of the 6 px frame, 8 px clear of the hint arrow tip (x 902).
- Shots: `.tools/shots/nightwatch/r14b-idle-360.png` (~5 s), `r14b-idle-600.png` (~9 s).
