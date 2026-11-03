# VISION: SHIFT REGISTER

## 1. Title and pitch
**SHIFT REGISTER**: eight tiny games, eight meanings of one word. Clear a game to set its bit; set every bit and the register overflows.

## 2. Framing: A, the Shift Register (sharpened)
- **The hub is an N-bit register.** Each shipped game is one bit cell. Clearing a game (`finish(score, true)` once) flips its bit from 0 to 1. The register reads like a real one: a row of big `0`/`1` digits.
- **Each bit is a different *sense* of SHIFT** (shape, gear, key, bit, phase, cargo, night, red). The cell shows that sense as one word, so the hub doubles as a dictionary of the theme. This is the Theme Interpretation pitch: one word, read eight ways, inside a hub that is itself a literal shift register.
- **Finale (later): OVERFLOW.** When every bit is 1 (and at least `min_games` = 5 are shipped), an extra gold cell appears past the end of the register. It runs a gauntlet: each game in slot order at `difficulty = 1` for 8 seconds, 3 lives. That is the Innovation pitch: the collection remixes itself.
- **Why not B or C.** Graveyard Shift needs writing, characters and text the web font and the hourly team handle badly. Gearbox doubles the content of every game (gears plus reverse rules). A costs ~3 Platform Engineer tasks (hub v1, bit-set ceremony, OVERFLOW), gives a strong code-drawn look, and never blocks a game.
- **No story, no dialogue.** The connective tissue is the register, the sense words and OVERFLOW.

## 3. Pillars (a Critic can check each one)
1. **One verb, one shift.** Each game's core verb *is* its SHIFT reading, you can name it in one word, and it plays `Synth.sfx("shift")` every time it happens.
2. **Teaches itself in 10 seconds without reading.** At most 3 words of instruction on screen at once. The first 10 seconds are nearly impossible to lose. The first hazard comes slowly and the correct response is shown by a glow or outline, not by text.
3. **Every input answers in the same frame, the same way everywhere.** A press gives visible and audible feedback that frame. Hits and fails look and sound like the bibles below in every game. Touch alone can earn the same score as keys (targets at least 96 px).
4. **Shapes, not glyphs; one screen; one short round.** Everything is drawn in code in this palette on a 1280x720 screen. A round lasts 30 to 90 s and ends in `finish(score, won)`. No per-game menus, title or game-over screens.

## 4. Slate (`slots` = 8; build order = hub order)
Slots 1 to 3 are the safest builds: no physics, two or three inputs, one screen.

| Slot | Slug | Title | Genre | SHIFT reading (sense word) | Core verb | Controls: keys / touch | Why it's in |
|---|---|---|---|---|---|---|---|
| 1 | `shapeshifter` | Shapeshifter | reflex tunnel dodger | SHAPE: shape-shifting | become the shape of the hole before the wall reaches you | Left / Up / Right (or A / W / D) = circle / triangle / square. Touch: three drawn shape buttons along the bottom | Safest build (no physics, 3 inputs). Pure shapes show off the art bible at once. Best first impression. |
| 2 | `geargrind` | Gear Grind | timing drag racer | GEAR: shifting gears | shift up while the tach needle is in the green band | Space or Up = shift up. Touch: tap anywhere (a big drawn lever on the right) | One-button timing that is tight and readable. The engine tones give us an Audio showcase. |
| 3 | `uppercase` | Upper Case | rhythm typing | KEY: the Shift key | press the correct Shift as a capital crosses the line | Left Shift (or F) / Right Shift (or J); the correct one is on the opposite side of the keyboard from the letter. Touch: tap the left or right half (two big drawn Shift keys). Tell left from right Shift with `InputEventKey.location` | The most literal SHIFT. Two inputs, letters spawned on the beat. A drawn keyboard strip lights the right Shift. |
| 4 | `bitcatcher` | Bit Catcher | falling-bit puzzle | BIT: bit shift | rotate your register so falling 1s land where the target byte needs them | Left / Right (A / D) = shift; Down (S) = drop faster. Touch: tap the left or right half; swipe down to drop | Echoes the hub. Our only puzzle. Moderate build. |
| 5 | `phaseshift` | Phase Shift | auto-runner | PHASE: phase shift between two worlds | phase so the platform under you exists | Space / Up = jump; Shift / Down / X = phase. Touch: right half = jump, left half = phase | Proven genre with a two-colour look; the music phase-shifts too. |
| 6 | `cargoshift` | Cargo Shift | balance / physics-lite | CARGO: shifting cargo | slide the ballast against the list as waves move the cargo | Hold Left / Right (A / D). Touch: hold the left or right half, or drag the ballast | A calmer change of pace with storm sound design. 1D custom physics, no rigid bodies. |
| 7 | `nightwatch` | Night Watch | attention survival | NIGHT: the night shift (and shifting your gaze) | switch camera feeds; whatever you are not watching creeps closer | 1 / 2 / 3 or Left / Right = feed; Space = flash. Touch: tap a feed thumbnail to watch it; tap the main view to flash | Innovation and mood. Uses silence as information. Survive from 12 to 6 on a drawn clock. |
| 8 | `redshift` | Red Shift | side-scrolling shmup | RED: redshift / blueshift (Doppler) | change speed to shift your hue so matching enemies become hittable | Up / Down (W / S) = move; Left / Right (A / D) = brake / boost; auto-fire. Touch: drag on the left two thirds to move; BRAKE and BOOST pads on the right | Spectacle closer. Most complex, so it is the first to be swapped for a bench pitch if we are behind. |

**Every game also:** fills `game.json` `sense` with its one-word sense in caps (`"SHAPE"`, `"GEAR"` and so on; the hub shows it). Treats `difficulty >= 1` as "start the ramp at its 30 s point" (needed for OVERFLOW; a one-line offset). Never plays `win` or `lose` itself (Arcade does that on finish).

**Bench (replacements, in preference order)**
- `overtime` **Overtime** (sorting): stamp and sort crates on a line; at every shift change (every 15 s) the controls swap. SHIFT: the shift change.
- `turnabout` **Turnabout** (gravity puzzle): rotate the maze 90 degrees and gravity rolls the ball. Generate the levels procedurally, or hand-make 6 small ones.
- `pitchshift` **Pitch Shift** (music): steer a note up and down to stay on a scrolling melody line; Synth.tone follows you. An Audio showcase.
- `swingshift` **Swing Shift** (momentum): release and grab trapeze bars; a fake pendulum, no physics engine.

## 5. Art bible
**Palette (use these hexes; nothing else except tints of them)**
| Token | Hex | Use |
|---|---|---|
| BG | `#0B0E14` | every background base |
| PANEL | `#151A24` | cells, cards, ground, UI fills |
| TRACE | `#1E2738` | 1 px grid (40 px pitch), bus lines, inactive outlines |
| DIM | `#6B7489` | secondary text, unlit bits, disabled |
| INK | `#E8ECF4` | primary text, the player when not tinted, hit flash |
| GOOD | `#FFD34D` | score popups, NEW BEST, cleared marks, the OVERFLOW cell |
| BAD | `#FF3B5C` | fail flash, damage, "wrong" outlines |

**Game accents (`game.json` `accent`, one per game)**: Shapeshifter `#FF5FA2` pink, Gear Grind `#FF9F1C` amber, Upper Case `#3DDCFF` cyan, Bit Catcher `#A3E635` lime, Phase Shift `#A78BFA` violet (second world: `#3DDCFF`), Cargo Shift `#2DD4BF` teal, Night Watch `#8FA8FF` moon blue, Red Shift `#FF7A45` ember (its hue bands are `#3D7BFF`, `#A3E635` and `#FF7A45`). A game uses BG/PANEL/TRACE/INK/DIM plus its own accent, with GOOD/BAD for meaning only.

**Shape language**: flat, geometric, hard-edged: circles, squares, triangles, rectangles, lines. Squared corners (round things are circles). The faint TRACE grid is the house motif, a circuit board. **Glow** = draw the shape again at 1.3x scale and alpha 0.25, then 1.6x at alpha 0.10 (no HDR glow in Compatibility). No gradients except optional CanvasItem shaders on backgrounds; no screen-reading shaders.
**Line weights**: 1 px grid; 2 px traces and decoration; 4 px entity outlines; 6 px the player, focus and selection.
**Text**: the fallback font only. Latin letters, digits and `. , : ! ? - ' ( ) /`. **No arrows, shapes, bullets or emoji in any string**: draw a triangle for an arrow, a circle for a dot. Sizes: gameplay HUD at least 28 px (score 40 px INK, top centre), titles 56 px or more, the hub footer at least 22 px. Labels in CAPS. Keep the corners clear for Arcade's buttons: top-left x 0 to 150, y 0 to 70 (HUB) and top-right x 1100 to 1280, y 0 to 70 (SOUND). HUD lives in x 170 to 1090.
**Motion**: arrivals ease out (cubic or back) over 0.15 to 0.25 s; UI moves 0.12 to 0.2 s; no gameplay tween longer than 0.4 s. Pulses are a 2 to 4 Hz sine. Impact squash 1.25x then back to 1.0 over 0.12 s. Shake: small 4, medium 10, big 18 (Juice.shake). Hitstop 0.04 to 0.06 s, only for big moments.
**A hit looks like**: Juice.burst in the game's accent (14 particles), a squash on the struck shape, Juice.popup `+N` in GOOD at 32 px; big hits add a white flash (alpha 0.15, 0.1 s).
**A soft fail (wrong or late input) looks like**: the player shape tinted BAD for 0.2 s plus shake 4.
**A hard fail (life lost, crash) looks like**: Juice.flash BAD at alpha 0.35 for 0.2 s, shake 14, hitstop 0.06, a BAD burst. Lives are drawn as accent squares at top centre, never as text.

## 6. Audio bible (Synth presets: same sound = same meaning everywhere)
| Preset | Means | Never use it for |
|---|---|---|
| `shift` | **the game's core SHIFT verb** (change shape, shift gear, press Shift, rotate register, phase, slide ballast, switch feed, change speed band). Pitch up with a streak: `1.0 + 0.04 * streak`, at most 1.5 | anything else |
| `coin` | you scored or collected (a correct hit). Combo: pitch by semitones `pow(2, n / 12.0)`, n at most 12 | menus |
| `hit` | you struck or destroyed something | the player being hurt |
| `miss` | a soft fail: wrong, early or late input; a near miss | life lost |
| `boom` | a hard fail: life lost, crash, capsize, engine blown | ordinary hits |
| `jump` | the player leaves the ground, or something launches upward | |
| `blip` | UI focus or move; neutral ticks (countdown, clock tick) | rewards |
| `select` / `back` | confirm or launch / cancel or leave (hub and Arcade) | gameplay |
| `win` / `lose` | **reserved for Arcade** at the end of a round | games never call them |

- Custom sounds use `Synth.tone()` for things with no preset meaning (an engine hum, wave noise, a camera static burst). Never re-use a preset for a new meaning.
- Vary repeated SFX with pitch 0.92 to 1.08. At most 3 SFX start in one frame: there are 12 shared voices, and the loop uses one per eighth note.
- **Music**: one `Synth.loop()` per game, 90 to 150 bpm (Night Watch may go to 70). Loop `vol` is 0.08 to 0.12 (never the 0.15 default), so music sits well under the SFX (0.25 to 0.55). 16 or 32 steps; a minor pentatonic is the house scale.
- **Loop character**: hub triangle 96 bpm, a calm A-minor arpeggio. Shapeshifter square 132, driving. Gear Grind saw 140, low and bassy under the engine tones. Upper Case triangle 112, letters spawn on beats. Bit Catcher square 120, staccato. Phase Shift saw 128, and on each phase the loop restarts 5 semitones up or down. Cargo Shift sine 92, rolling. Night Watch sine 70, mostly rests. Red Shift square 150, and boost or brake restarts it transposed.
- **Silence is information**: the round opens with a 0.6 s beat of two `blip`s, then the loop starts. After a hard fail the loop stops for 0.5 s, then restarts. In Night Watch the music thins out as danger gets closer. Arcade stops the loop on finish (already built).

## 7. Hub (Platform Engineer)
**v1 (one ~20 min task; behaviour and look):**
- BG with the TRACE 40 px grid. Title `SHIFT REGISTER` at 64 px INK, centred at y 110. Under it at 28 px DIM: `<k> OF <n> BITS SET` (`k` = cleared games, `n` = shipped games).
- **The register**: one cell per entry in `Arcade.games`, in slot order, as one centred row. A cell is 120x150 PANEL with a 16 px gap (8 cells span 1072 px), top at y 220. In each cell: a big digit at 64 px, `1` in the game's accent with the glow if `Save.cleared(slug)`, else `0` in DIM; the slot number at 22 px DIM in the top-left corner; the sense word (`game.json` `sense`, falling back to the title) at 22 px under the digit; a 6 px accent bar along the bottom.
- A 2 px TRACE **bus line** runs under all the cells (y 400), with small INK dots travelling along it at 120 px/s (cheap life).
- The **read head**: a 6 px accent bracket around the selected cell that eases to the new cell in 0.15 s (ease out cubic) and pulses at 3 Hz.
- **Info panel** for the selected game, from y 440: title 48 px INK, tagline 28 px INK, controls 24 px DIM, then `BEST <n>` in GOOD (or `NEW` in DIM), and `CLEARED` in GOOD when it is cleared. A drawn **PLAY button** (260x80, accent fill, `PLAY` 36 px in BG colour) at the bottom right of the panel.
- **Input**: Left / Right (A / D) move the head with wrap-around (`blip`); Enter or Space launches (`select`). Mouse or touch: hover selects; tapping a cell selects it; tapping the selected cell or PLAY launches. The selection persists via `Save.setting("hub_selected")` (already there).
- Footer at 22 px DIM, y 700: `LEFT / RIGHT choose   ENTER or tap PLAY   M sound`. Words only, no symbols.
- Music: `Synth.loop([57,0,64,0,60,0,64,67, 57,0,64,0,62,0,60,59], 96.0, "triangle", 0.10)`.
- With zero games: the empty register outline and `THE FACTORY IS BUILDING THE FIRST BIT` at 32 px DIM.
- Pure logic in `hub/hub_rules.gd` (bit string such as `"10100"`, the count of set bits, the OVERFLOW unlock test, cell layout rects), asserted by `hub/selftest.gd`.

**Later (separate tasks, in this order):**
1. **Bit-set ceremony**: on returning to the hub after a first clear, that cell's digit flips from 0 to 1 (a 0.25 s vertical squash), with `shift`, then `coin`, and an accent burst. A seen-cleared list in Save settings makes it play once.
2. **OVERFLOW**: when `hub_rules.overflow_unlocked()` is true (every bit set and n at least 5), a GOOD cell `OVERFLOW` joins the end of the register. It needs an additive Arcade gauntlet API: launch each game at `difficulty = 1`; 8 s survived = pass; `finish(_, false)` before that costs 1 of 3 lives; the score is the sum; the result is recorded under the slug `overflow`; one shared result card at the end.
3. Polish: the register rotates under a fixed head instead of the head moving (a literal circular shift, `shift` sound); a per-game emblem shape in each cell; idle attract after 30 s.

## 8. Ship bar (in the hub = `"status": "shipped"`)
- `./scripts/check.sh <slug>` PASS (glyph lint, import, smoke, autoplay round under 60 s, selftest), and the DESIGN.md acceptance checklist passes.
- Shots show only bible colours, drawn shapes, a readable HUD (at least 28 px) and clear corners. No placeholder rectangles standing in for art that was planned.
- Pillars 1 to 4 hold. A Critic can name the verb, finds the first 10 s forgiving, and sees no instruction longer than 3 words.
- Touch alone can play a full round (on-screen targets at least 96 px). Keys work too, without Esc, P or M.
- It has a music loop, the `shift` sound on the core verb, and hit and fail feedback per the bibles.
- Jam Critic overall at least `ship_bar` = 6.5, with no category below 5. A shipped game below 6.5 that can't be fixed in 2 tasks is a cut candidate in POLISH (never below `min_games` = 5 in the hub).

## 9. Not doing
- Narrative, dialogue, characters with names, cutscenes (the Graveyard Shift framing).
- Gearbox-style remixes or reverse modes per game (the only remix is OVERFLOW's `difficulty = 1` offset).
- Per-game title, tutorial, settings or game-over screens; options menus beyond mute.
- Online leaderboards, accounts, analytics, multiplayer, localisation.
- Downloaded fonts, sprites or audio files; recorded voice; sample-based music.
- Rigid-body physics piles, scrolling worlds bigger than the genre needs, 3D, Shader-heavy post-processing.
- Sample-accurate rhythm judging (judge by position on screen, not by the audio clock).
- More than 8 games, or a 9th slot before all 8 are shipped or cut.
- Gamepad support as a requirement (allowed as a free bonus only).

## Changelog
- R0001 (2026-11-03): kickoff. Framing A (Shift Register) with sense words and OVERFLOW; slate of 8; bench of 4.

Status: LOCKED (R0001, 2026-11-03)
