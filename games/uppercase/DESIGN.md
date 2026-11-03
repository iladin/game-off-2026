# Upper Case

<!-- Written by the Game Designer before any code. The Gameplay Engineer builds exactly this. -->
<!-- R0003, slate slot 3, sense KEY. Accent #3DDCFF. Budget: about 15-20 min, under ~600 lines of GDScript. -->

## Pitch
Letter tiles fall down the screen, each one above its own key on a drawn keyboard strip. When a CAPITAL crosses the line, press the Shift key on the **other** side of the keyboard, the way a touch typist does: a capital Q (left hand) takes Right Shift, a capital P (right hand) takes Left Shift. Letters arrive on the beat of a 112 bpm loop. Small (lower case) letters sneak in later: let them pass. Survive the page to clear the KEY bit.

## How it uses SHIFT
SHIFT = **the Shift key**, and pressing it is the only verb. There are exactly two inputs, Left Shift and Right Shift, and the whole skill is choosing the right one in time. Every press of either Shift plays `Synth.sfx("shift", Rules.shift_pitch(streak))` and the drawn Shift key goes down. The letters are literally being shifted from lower to upper case: a correct hit turns the tile's letter into a GOOD capital that bursts.

## Core loop
Every 0.5-1.1 s (one letter per 1-2 beats):
1. A tile appears at the top above its key (x = its key's x on the strip) and falls at a constant speed so it reaches the line exactly on a beat.
2. The keyboard strip lights that letter's key; while hints are on, the correct Shift glows.
3. As the tile crosses the line, press the opposite-side Shift. Distance from the line at the press decides PERFECT / GOOD; the wrong Shift is a TYPO; no press is MISSED.

The decision: which side is this letter on (left hand QWERT ASDFG ZXCVB, right hand YUIOP HJKL NM), so which Shift, and is it a capital at all. The tile's x position already tells you the side: a tile falling on the left of the screen wants the RIGHT Shift. From 30 s the Shift glow is gone and you must read the position yourself.

## Controls (keyboard AND touch)
| Action | Keyboard | Touch / mouse |
|---|---|---|
| Left Shift | Left Shift (`keycode == KEY_SHIFT and location == KEY_LOCATION_LEFT`), or F | tap / click the left half of the screen (x < 640); the drawn LEFT SHIFT key (460 x 100 px) is the visual target |
| Right Shift | Right Shift (`keycode == KEY_SHIFT and location == KEY_LOCATION_RIGHT`), or J | tap / click the right half (x >= 640); the drawn RIGHT SHIFT key (460 x 100 px) |

- Read `InputEventKey` (`pressed and not echo`) and `InputEventMouseButton` (pressed, MOUSE_BUTTON_LEFT, side from `event.position.x`, as Shapeshifter does) in `_unhandled_input`, so Arcade's HUB / SOUND buttons take their clicks first. `emulate_mouse_from_touch=true`: do NOT also handle `InputEventScreenTouch` (double fire). Never Esc, P or M.
- A Shift event with `location == KEY_LOCATION_UNSPECIFIED` (some browsers or keyboards): ignore it (no sound). F and J always work; the drawn keys show `F` and `J` so players can fall back.
- Ignore input when `autoplay`, `is_finished()`, or during the 0.6 s intro.
- Every press answers in the same frame: `shift` sound plus that Shift key depresses, even when nothing is in the window.
- Touch and keys call the same `_press(side)`, so touch alone earns the same score. Each touch target is half the screen (640 x 720).

## Round: fail / win, score
- **Lives:** 3, accent squares at top centre.
- **Hard fails (cost a life):** TYPO = a capital in the window judged with the wrong Shift; MISSED = a capital whose y passes `LINE_Y + GOOD_PX` unpressed. **Grace:** while ramp time `r < GRACE_END` (10 s) these cost nothing: the popup is `OTHER SIDE` (TYPO) or `MISSED` in DIM, and the correct Shift key flashes ACCENT twice (0.3 s) to teach. So the first 10 s cannot be lost.
- **Soft fails (streak reset, no life):** a press with no letter within `GOOD_PX` of the line (stray), or a press whose nearest letter in the window is lower case (that tile is consumed, popup `SMALL` BAD).
- **Win (clears the KEY bit):** spawning stops at `SPAWN_END = 44.0` s of round time; when every spawned letter has been judged and lives > 0: `finish(Rules.final_score(score, lives), true)`.
- **Lose:** lives reach 0: `finish(score, false)` in the same frame as the hard-fail effects.
- `finish()` exactly once (return right after). Never play `win` / `lose`.
- **Score:** PERFECT 30, GOOD 15, each plus a streak bonus `2 * min(streak, 10)` (streak before this hit). A lower-case tile let past the line: +5. Round won: +50 per life left. A clean bot round is about 2,000-2,300.
- **Typical length:** about 46 s (0.6 s intro, 44 s of spawns, the last tile lands within ~1.6 s). A losing round ends sooner. Same length at difficulty 1.

## Ramp (with numbers)
`BPM = 112`, `BEAT = 60 / 112 = 0.5357` s. Round time `t` counts from the loop start (end of intro); `beat = t / BEAT`. Ramp time `r = t + (DIFFICULTY_OFFSET 30.0 if difficulty >= 1 else 0.0)`. A tile spawns on every integer beat `b` with `b % spawn_every(r) == 0` while `t < SPAWN_END`; its `travel` (beats) is sampled at spawn and never changes, so it reaches the line at beat `b + travel`, on the beat.

| Quantity (rules.gd) | r 0-10 | 10-20 | 20-30 | 30-40 | 40+ |
|---|---|---|---|---|---|
| `spawn_every(r)` (beats) | 2 | 2 | 1 | 1 | 1 |
| `travel_beats(r)` | 4.0 (145 px/s) | 3.0 (193 px/s) | 3.0 | 3.0 | 2.0 (289 px/s) |
| `lower_chance(r)` | 0 | 0 | 0.25 | 0.30 | 0.35 (clamp) |
| `hints_on(r)` (Shift glow) | yes | yes | yes | no | no |
| `is_grace(r)` | yes | no | no | no | no |
| `phase_name(r)` banner | `""` | `FASTER` | `LET LOWER PASS` | `NO HINTS` | `TOP SPEED` |

Speed = `(LINE_Y - SPAWN_Y) / (travel * BEAT)` = 310 / (travel * 0.5357). Tile spacing at the line is `speed * BEAT * spawn_every`: at its tightest (r 20-40) 103 px, at r 40+ 155 px, both more than `2 * GOOD_PX = 88`, so **at most one tile is ever in the window**.
Banners show when `phase_name(r)` differs from the last shown one (start value `""`), so at difficulty 1 `NO HINTS` shows at once. Letters: uniform random from the 26, never the same letter twice in a row; a tile is lower case with `lower_chance(r)`, except the first 4 tiles of a round (always capitals). Bot round at difficulty 0: ~10 + ~9 + ~45 tiles, ~50 capitals.

## Look (palette hex + how each thing is drawn, per studio/VISION.md)
Colours: BG `#0B0E14`, PANEL `#151A24`, TRACE `#1E2738`, DIM `#6B7489`, INK `#E8ECF4`, ACCENT `#3DDCFF`, GOOD `#FFD34D`, BAD `#FF3B5C`. Nothing else.

Screen map (1280 x 720):
| y | Band |
|---|---|
| 0-112 | HUD: score, lives, page progress (x 170-1090 only) |
| 130-176 | banner |
| 140-494 | the fall: tiles from `SPAWN_Y = 140` to the line `LINE_Y = 450` |
| 502-600 | keyboard strip (3 rows) |
| 612-712 | LEFT SHIFT and RIGHT SHIFT keys |

- **BG:** fill BG; 1 px TRACE grid at 40 px pitch.
- **Columns:** for each of the 26 key x positions, a 1 px TRACE vertical line from y 140 to 494 (faint lanes that tie tiles to keys).
- **Hit line:** 4 px INK line x 200-1080 at `LINE_Y`; window edges at `LINE_Y +- GOOD_PX` as 2 px ACCENT lines, alpha 0.25. On each beat the line flashes alpha 1.0 and decays to 0.6 over half a beat.
- **Tiles:** square 64 x 64 centred at `(key_x, y)`. Capital: PANEL fill, 4 px ACCENT outline, the letter 44 px INK centred. Lower case: PANEL fill, 2 px DIM outline, the lower-case letter 44 px DIM. A tile fades in over its first 0.15 s (alpha) and, once judged, plays its effect and is removed (miss: drawn BAD for 0.2 s while it keeps falling, then removed). Tiles are not drawn below y 494.
- **Keyboard strip:** keys 72 x 30, PANEL fill, 2 px TRACE outline, the letter 24 px DIM centred. Rows (`ROWS = ["QWERTYUIOP", "ASDFGHJKL", "ZXCVBNM"]`): left x of key 0 = `ROW_X0 = [240, 260, 300]`, pitch `KEY_PITCH = 80`, top y `ROW_Y = [502, 536, 570]`. Key centre x = `ROW_X0[row] + col * 80 + 36`. Left-hand keys (col < 5) and right-hand keys get a 2 px divider: a TRACE vertical line between col 4 and col 5 of each row (the touch-typist split). The key of the nearest pending tile: ACCENT fill, letter in BG colour (capital) or 2 px DIM outline only (lower case).
- **Shift keys:** `LEFT_KEY = Rect2(170, 612, 460, 100)`, `RIGHT_KEY = Rect2(650, 612, 460, 100)`. PANEL fill, 4 px TRACE outline. Inside: `SHIFT` 36 px INK centred; a drawn shift glyph (polygon outline, 4 px INK: a triangle 40 wide x 24 tall on top of a 20 x 18 stem) 60 px from the outer edge (left of the word on the left key, right of it on the right key); `F` / `J` 24 px DIM in the inner bottom corner. Pressed: offset +6 px down and ACCENT fill (letters in BG colour) for 0.1 s. **Hint** (while `hints_on(r)` and a capital is pending): the correct key's outline 6 px ACCENT pulsing (alpha 0.5 + 0.5 sin(TAU * 3 t)) plus the glow (rect again at 1.3x alpha 0.25 / 1.6x alpha 0.10, clipped to the screen). TYPO / MISSED: the pressed (or correct, for MISSED) key outline BAD for 0.2 s.
- **HUD** (x 170-1090; nothing at x < 150 or x > 1100 above y 70):
  - Score 40 px INK centred, baseline y 56.
  - Lives: 3 squares 20 x 20 at y 70-90, centres x 608 / 640 / 672: ACCENT alive, 2 px DIM outline lost (BAD fill 0.4 s right after).
  - Page progress: 2 px TRACE outline rect x 440-840, y 100-108, ACCENT fill to `t / SPAWN_END`.
  - Banner 40 px ACCENT centred, baseline y 168, 1.2 s, fades over the last 0.3 s.
- No READY text, no other instructions (the drawn `SHIFT`, `F`, `J` key labels are the only words besides the banners).

## Sound (Synth presets/tones/loop used, per studio/VISION.md)
| Event | Call |
|---|---|
| Any Shift press (the verb) | `Synth.sfx("shift", Rules.shift_pitch(streak))`, `shift_pitch = min(1.5, 1.0 + 0.04 * streak)` (before the judge updates streak) |
| PERFECT | also `Synth.sfx("coin", pow(2.0, mini(streak, 12) / 12.0))` |
| GOOD | also `Synth.sfx("coin", 0.84)` |
| Stray press / lower case pressed / grace TYPO or MISSED | also `Synth.sfx("miss", randf_range(0.92, 1.08))` |
| TYPO / MISSED (life lost) | `Synth.sfx("boom", randf_range(0.95, 1.05))`; `Synth.stop_loop()`, restart after 0.5 s at the next integer beat (so the music stays on the spawn grid) |
| Lower case let past | nothing (silence is the reward; +5 popup only) |
| Round intro | `blip` at 0.0 and 0.3 s; loop starts at 0.6 s and `t` starts at 0 that frame |
| Round end | nothing (Arcade plays `win` / `lose`) |

**Music:** `Synth.loop(LOOP_NOTES, 112.0, "triangle", 0.10)`, A minor pentatonic, one note per eighth so two steps per beat: `LOOP_NOTES = [57, 0, 60, 64, 0, 64, 62, 60, 57, 0, 60, 64, 67, 0, 64, 62]`. From `TOP_SPEED` (r >= 40) restart it with notes +12 on the next beat (brighter, same grid). At most 3 sounds per frame: a press starts 2.

## Juice list
1. **Every press:** the Shift key drops 6 px and fills ACCENT for 0.1 s; same frame as the `shift` sound.
2. **PERFECT:** the tile's letter turns GOOD and the tile squashes 1.25x then is removed after 0.12 s; `Juice.burst(self, tile_pos, ACCENT)` (14); `Juice.popup(self, tile_pos - Vector2(0, 50), "PERFECT", GOOD)`; the strip key flashes GOOD 0.15 s; every 10th streak adds `Juice.flash(Color(1, 1, 1, 0.15), 0.1)`.
3. **GOOD:** squash and burst as PERFECT (burst 8 particles); popup `"+%d" % pts` GOOD.
4. **Soft fail:** stray: the pressed key outline BAD 0.2 s, `Juice.shake(4)`. Lower case pressed: the tile tinted BAD 0.2 s, popup `SMALL` BAD, `Juice.shake(4)`.
5. **Hard fail (TYPO / MISSED after grace):** `Juice.flash(Color(BAD, 0.35), 0.2)`, `Juice.shake(14)`, `Juice.hitstop(0.06)`, `Juice.burst(self, tile_pos, BAD)`; popup `TYPO` / `MISSED` BAD; the lost life square flashes BAD 0.4 s; loop silent 0.5 s.
6. **On the beat:** the hit line flashes; the score digits squash 1.1x on each scoring hit.

## Build plan (scripts, data structures, every tunable with a start value)
Files (target ~560 lines, each under 300):
- `rules.gd` (~110 lines, pure: no nodes, no autoloads): constants and static functions below.
- `selftest.gd` (~50 lines): the assertions in the checklist.
- `game.gd` (~250 lines, `extends MicroGame`): state, `begin()`, `_process()` (intro, beat clock, spawn, move/miss check, loop restart, bot), `_unhandled_input()`, `_press(side)`, `_hard_fail(tile, text)`, `_draw()` calling the helpers.
- `keys_draw.gd` (~150 lines, `extends RefCounted`, static helpers taking `ci: CanvasItem`; preload like Rules): `draw_backdrop(ci, columns_x)`, `draw_line_zone(ci, beat_frac)`, `draw_tile(ci, pos, ch, upper, alpha, tint, squash)`, `draw_strip(ci, lit_ch, lit_upper, flash_ch)`, `draw_shift_key(ci, rect, side, down, hint, bad, t)`, `draw_hud(ci, score, lives, life_flash, progress, banner, alpha)`.

**Tile data:** a small inner class `Tile` (or Dictionary) `{ch: String (upper-case letter), upper: bool, x: float, spawn_beat: float, travel: float, judged: bool, fx_t: float, bot_off: float}`; `y = Rules.letter_y(beat - spawn_beat, travel)`.

**rules.gd functions:** `ramp_time(t: float, difficulty: int) -> float`, `side_of(ch: String) -> int` (LEFT 0 / RIGHT 1, by col < 5 in its row), `correct_shift(ch) -> int` (`1 - side_of(ch)`), `key_center(ch) -> Vector2`, `spawn_every(r) -> int`, `travel_beats(r) -> float`, `lower_chance(r) -> float`, `hints_on(r) -> bool`, `is_grace(r) -> bool`, `phase_name(r) -> String`, `letter_y(age_beats: float, travel: float) -> float` (`SPAWN_Y + (LINE_Y - SPAWN_Y) * age / travel`, unclamped), `judge(dy: float) -> int` (PERFECT if `abs(dy) <= PERFECT_PX`, GOOD if `<= GOOD_PX`, else NONE), `is_missed(y) -> bool` (`y > LINE_Y + GOOD_PX`), `hit_points(j, streak) -> int`, `shift_pitch(streak) -> float`, `final_score(score, lives) -> int`, `side_for_tap_x(x) -> int` (x < 640 LEFT).

**rules.gd tunables:**
| Name | Start value |
|---|---|
| LEFT, RIGHT | 0, 1 |
| NONE, GOOD, PERFECT | 0, 1, 2 |
| ROWS | ["QWERTYUIOP", "ASDFGHJKL", "ZXCVBNM"] |
| ROW_X0, ROW_Y, KEY_PITCH, KEY_W, KEY_H | [240, 260, 300], [502, 536, 570], 80, 72, 30 |
| SPLIT_COL | 5 |
| BPM, BEAT | 112.0, 60.0 / 112.0 |
| SPAWN_Y, LINE_Y | 140.0, 450.0 |
| PERFECT_PX, GOOD_PX | 16.0, 44.0 |
| TRAVEL | 4.0 (r < 10), 3.0 (r < 40), 2.0 |
| SPAWN_EVERY | 2 (r < 20), 1 |
| LOWER_AT, LOWER_CHANCES | 20.0, [0.25 at 20, 0.30 at 30, 0.35 at 40+] |
| HINTS_END, GRACE_END | 30.0, 10.0 |
| FAST_AT, TOP_AT | 10.0, 40.0 |
| DIFFICULTY_OFFSET | 30.0 |
| SPAWN_END | 44.0 |
| POINTS | [0, 15, 30] (by judge), STREAK_PTS 2, STREAK_CAP 10, LOWER_PASS_PTS 5, LIFE_BONUS 50 |
| PITCH_STEP, PITCH_MAX | 0.04, 1.5 |

**game.gd tunables:** palette Colors; `LIVES = 3`; `INTRO_TIME = 0.6`; `FIRST_CAPS = 4`; `LEFT_KEY`, `RIGHT_KEY` (above); `KEY_DOWN_PX = 6.0`, `KEY_DOWN_TIME = 0.1`; `FADE_IN = 0.15`; `SQUASH = 1.25`, `SQUASH_TIME = 0.12`; `FAIL_TINT_TIME = 0.2`; `BANNER_TIME = 1.2`; `HINT_FLASH_TIME = 0.3`; `LOOP_NOTES`, `LOOP_VOL = 0.10`, `LOOP_RESTART_DELAY = 0.5`, `TOP_TRANSPOSE = 12`; `SHAKE_SOFT = 4.0`, `SHAKE_HARD = 14.0`, `HITSTOP = 0.06`; `BOT_SPREAD = 12.0` (px).

**State (game.gd):** `intro`, `t`, `beat`, `last_spawn_beat` (int, -1), `tiles: Array`, `last_ch`, `spawned`, `score`, `streak`, `lives`, `key_down_t[2]`, `key_bad_t[2]`, `hint_flash_t`, `life_flash_t`, `banner_text`, `banner_t`, `last_phase`, `loop_restart_t`, `loop_wait_beat`, `top_music`.

**Flow:**
- `begin()`: reset ALL state (Arcade calls it on every retry and autoplay restart); blips at 0.0 / 0.3; at intro end `Synth.loop(...)`, `t = 0`.
- `_process(dt)`: `t += dt; beat = t / BEAT; r = Rules.ramp_time(t, difficulty)`. Phase banner check. Spawn: `var b := int(floor(beat))`; if `b > last_spawn_beat` and `t < SPAWN_END`: `last_spawn_beat = b`; if `b % Rules.spawn_every(r) == 0`: spawn a tile with `spawn_beat = b`, `travel = Rules.travel_beats(r)`. Then for each unjudged tile: if `Rules.is_missed(y)`: capital = `_hard_fail(tile, "MISSED")`, lower = +5 popup DIM; mark judged. Bot. Remove tiles whose `fx_t` ran out. Win: `t >= SPAWN_END` and no unjudged tiles: `finish(Rules.final_score(score, lives), true)`; return.
- `_press(side)`: shift sound, key down. Target = the unjudged tile with the smallest `abs(y - LINE_Y)` that has `Rules.judge(y - LINE_Y) != NONE`. None: stray soft fail. Lower case: SMALL soft fail, judged. Capital and `side == Rules.correct_shift(ch)`: hit (points, streak += 1 after scoring, sounds, juice). Else `_hard_fail(tile, "TYPO")`.
- `_hard_fail(tile, text)`: streak 0; if `Rules.is_grace(r)`: grace feedback; else lives -= 1, hard-fail juice, stop loop; if `lives <= 0`: `finish(score, false)`.

## Autoplay bot (how it plays; must reach finish() within 60 s)
- Runs in `_process` after moving tiles, only when `autoplay`, and calls the same `_press(side)` as keys and taps.
- Each tile rolls `bot_off = randf_range(-BOT_SPREAD, BOT_SPREAD)` at spawn. For the nearest unjudged **capital**, the bot calls `_press(Rules.correct_shift(ch))` the first frame `y >= LINE_Y + bot_off` (so about 3 in 4 hits are PERFECT, the rest GOOD). It never presses for lower case (they pass for +5) and never presses with nothing near the line.
- It never loses a life, so it **wins**: spawns stop at t = 44 s, the last tile lands by ~45.6 s, `finish(score, true)` at about **46.2 s** of game time including the intro. Same at difficulty 1. Within the gate's 3600 frames.
- Shots: frame 240 (4.0 s, t = 3.4 s, beat 6.3): tiles spawned on beats 0, 2, 4, 6; the first hit happened at beat 4 (2.14 s) so the score is 30-ish; the Shift hint glowing. Frame 900 (15.0 s, t = 14.4 s): the faster phase, several tiles in the air, score above 300, three lives.

## Acceptance checklist (6–10 testable items, incl. 2–4 rules.gd assertions)
1. `./scripts/check.sh uppercase` prints `PASS`; the autoplay log shows `ARCADE finished uppercase` with `won` true, within the 3600 frames (expected ~46 s).
2. **selftest, the touch-typist rule:** `correct_shift("Q") == RIGHT`, `correct_shift("G") == RIGHT`, `correct_shift("B") == RIGHT`, `correct_shift("H") == LEFT`, `correct_shift("N") == LEFT`, `correct_shift("P") == LEFT`; every letter A-Z has `key_center(ch).x` within 240-1040; `side_for_tap_x(639.0) == LEFT`, `side_for_tap_x(640.0) == RIGHT`.
3. **selftest, judging by position:** `letter_y(0.0, 4.0) == SPAWN_Y`, `letter_y(3.0, 3.0) == LINE_Y`; `judge(0.0) == PERFECT`, `judge(16.0) == PERFECT`, `judge(-30.0) == GOOD`, `judge(45.0) == NONE`; `is_missed(LINE_Y + 44.0)` false, `is_missed(LINE_Y + 45.0)` true; one-tile-in-window: `(LINE_Y - SPAWN_Y) / travel_beats(25.0) * spawn_every(25.0) > 2 * GOOD_PX` and the same at r 45.
4. **selftest, ramp and scoring:** `ramp_time(0.0, 1) == 30.0`, `ramp_time(12.0, 0) == 12.0`; `travel_beats(0) == 4.0`, `travel_beats(15) == 3.0`, `travel_beats(45) == 2.0`; `spawn_every(5) == 2`, `spawn_every(25) == 1`; `lower_chance(19.9) == 0.0`, `lower_chance(1000) == 0.35`; `hints_on(29.9)` and not `hints_on(30.0)`; `is_grace(9.9)` and not `is_grace(10.0)`; `hit_points(PERFECT, 0) == 30`, `hit_points(GOOD, 100) == 35`; `shift_pitch(100) == 1.5`; `final_score(1000, 2) == 1100`.
5. **Shot `start`:** BG with TRACE grid and faint column lines; the INK hit line with faint ACCENT window lines; the three-row keyboard strip with letters A-Z on keys; two big SHIFT keys at the bottom with `F` and `J`; score `0`, three ACCENT life squares and the empty progress bar at top centre; nothing in the corners (x < 150 or x > 1100, y < 70).
6. **Shot `play-240`:** 1-3 ACCENT-outlined capital tiles falling at different heights, each above its key; the matching strip key lit ACCENT; the opposite Shift key glowing (hint); score around 30-60.
7. **Shot `play-900`:** several tiles in flight, score above 300, three lives, progress bar about a third full; HUD text at least 28 px; only palette colours; no empty glyph boxes.
8. **Code read (grep `games/uppercase`):** `KEY_LOCATION_LEFT` and `KEY_LOCATION_RIGHT` used for Shift, plus `KEY_F` / `KEY_J`; `Synth.sfx("shift", Rules.shift_pitch(streak))` in `_press`; `Synth.loop(` with `112.0, "triangle"`; no `"win"` / `"lose"` sfx; `difficulty` used only via `Rules.ramp_time`; exactly one `finish(` with `true` and one with `false`; judging uses tile y, never `Synth` timing.
9. **Touch and keys:** a mouse/tap press on the left half presses Left Shift and on the right half Right Shift (no `InputEventScreenTouch` handler); Esc, P and M are not read by the game.

## Out of scope
- Typing actual letters (only the two Shift keys are inputs), words, sentences, spelling, a text to copy.
- Caps Lock, other modifier keys, chords of two Shifts, held notes, combo multipliers beyond the streak bonus.
- Judging against the audio clock or latency calibration; the tile position at the press is the only judge.
- Keyboard layouts other than QWERTY (AZERTY etc.), remapping, a settings screen.
- Digits, punctuation or symbols on tiles or keys (letters A-Z and a-z only: the web font has no symbols).
- A song editor, multiple songs, per-song charts; the chart is random on the beat grid.
- Per-game title, READY or tutorial screens; files of any kind (everything is `_draw()` and Synth).
- Gamepad support (a free bonus at most).
