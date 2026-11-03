---
name: microgame
description: Build or change one game in the SHIFT collection: scaffold from games/_template, follow the MicroGame contract, rules.gd + selftest, Synth audio, Juice feel, autoplay bot, screenshots, check.sh. Use for any work inside games/<slug>/.
---

# Microgame: design doc → shipped game in the hub

Input: a slug and a `games/<slug>/DESIGN.md` written by the Game Designer (if there's no design doc, write one with the template's sections first).

## 1. Scaffold (new games only)
```bash
./scripts/new_game.sh <slug> "<Title>"
```
Touch nothing outside `games/<slug>/`. `shared/` and `hub/` belong to the Platform Engineer; if you need something there, say so in your report.

## 2. Read
`CLAUDE.md`, `studio/VISION.md` (palette, type, audio and feel rules all games share), `games/<slug>/DESIGN.md` (your spec), `games/_template/game.gd` (the contract in practice), and the `godot-web-gdscript` and `game-feel` skills.

## 3. Build in this order
1. **`rules.gd`**: the pure rules (scoring, ramps, collision maths, grid logic, level data) as static functions/constants. No nodes, no autoloads.
2. **`selftest.gd`**: the DESIGN.md logic assertions against `rules.gd`. It must print `SELFTEST OK` and `quit(0)`, or print `SELFTEST FAIL: ...` and `quit(1)`.
3. **`game.gd`** (`extends MicroGame`):
   - `begin()` resets EVERYTHING and starts the round (it is called again on retry). A short READY beat is fine; a title screen isn't.
   - Call `finish(score, won)` exactly once per round. Don't draw a game-over screen; Arcade shows the result card.
   - The autoplay bot (`if autoplay:`) feeds real gameplay input and reaches `finish()` within 60 s. It may play badly on purpose so rounds end.
   - Input: `_unhandled_input` / polling, keyboard AND mouse/touch. Don't use Esc, P or M.
   - Sound: `Synth.sfx(...)`, `Synth.tone(...)`, `Synth.loop(...)` for music. Every player action gets a sound.
   - Feel: `Juice.shake/flash/hitstop/burst/popup`. Every hit, score and failure gets visible feedback.
   - Look: VISION.md's palette and type sizes (HUD text at least 28 px). Shapes, not symbol characters (the web font has none).
   - Split anything over ~300 lines into more scripts in `games/<slug>/`.
4. **`game.json`**: title, tagline (the hook, under ~60 chars), controls (keys AND touch, one line), accent, genre, shift, `"status": "draft"`. Don't set `shipped`; the Producer does after QA.

## 4. Verify
```bash
./scripts/check.sh <slug>        # must print PASS
./scripts/shots.sh <slug>        # look at every PNG (start, play-30/240/900)
```
In the shots, check: nothing off-screen or overlapping the HUD buttons (top-left < HUB, top-right SOUND), text readable, palette as VISION.md says, the game state reads at a glance. Fix and re-run until both are clean. Never claim a check passed that you didn't run.

## 5. Report (it becomes the commit body)
What the game is and how a round plays · controls (keys + touch) · win/lose and score · ramp · sound and juice · tunables · selftest assertions · check.sh result · what the shots showed · known limitations · anything you needed from shared/ or hub/.
