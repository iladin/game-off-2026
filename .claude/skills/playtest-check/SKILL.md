---
name: playtest-check
description: Verify the SHIFT collection without a human: the check.sh gate (glyph lint, import, smoke, autoplay round, selftest, hub tour), real-renderer screenshots, and the browser check of the export. Use before declaring any game or hub change done, and when CI fails.
---

# Playtest check

## The gate
```bash
./scripts/check.sh <slug>     # one game
./scripts/check.sh hub        # hub boot + attract-mode tour through every hub game
./scripts/check.sh all        # everything (CI runs this)
```
Per game it runs, in the one Godot project:
1. **glyph lint**: no arrows/shapes/emoji in string literals (the web font can't draw them).
2. **import**: parse errors in any script fail here or in the next step.
3. **smoke**: `-- --game=<slug>` for 300 frames, no input. Catches errors in `begin()`, `_process`, `_draw`.
4. **autoplay**: `-- --game=<slug> --autoplay` for 3600 frames (60 s). The bot must reach `finish()` (`ARCADE finished <slug>` in the log); Arcade then restarts the game, so `begin()` is exercised twice.
5. **selftest**: `--script res://games/<slug>/selftest.gd` must print `SELFTEST OK`.
6. **game.json** has title, tagline, controls, accent.

Any `SCRIPT ERROR`, `Parse Error`, `Invalid call/access/assignment`, `Node not found` or line starting `ERROR:` fails the step.

## Screenshots: the only way to see the game
Headless runs draw nothing. `./scripts/shots.sh <slug>` renders with a real renderer under xvfb at 1280×720: `start.png` (no input) and `play-30/240/900.png` (autoplay). Look at every image. Check readability, overlap with the HUD buttons (top-left and top-right corners), palette, and whether the state of play reads at a glance.

## Browser check: the real export
`./scripts/export_web.sh && node scripts/browser_check.mjs` boots the HTML5 build in headless Chromium, waits for the hub, presses Enter to open the selected game, and fails on console errors. Screenshots go to `.tools/shots/browser/`. This catches web-only problems (missing glyphs, audio, file access) that desktop runs hide. It skips itself if Playwright isn't installed.

## selftest.gd pattern
```gdscript
extends SceneTree
const Rules := preload("res://games/<slug>/rules.gd")

func _init() -> void:
	var fails: Array[String] = []
	if Rules.points(3) != 100:
		fails.append("3-match scores 100")
	for f in fails:
		printerr("SELFTEST FAIL: " + f)
	if fails.is_empty():
		print("SELFTEST OK")
	quit(1 if not fails.is_empty() else 0)
```
Autoloads aren't available in `--script` mode, so selftests only touch `rules.gd`.

## Reading failures
- `Parse Error: Identifier "X" not declared` → typo or Godot 3 API (see godot-web-gdscript).
- `Cannot infer the type` → `:=` on a Variant (e.g. `event is X and ...`, a Dictionary value); add an explicit type.
- `expected /ARCADE finished <slug>/` → the bot never ended a round in 60 s: make it play worse, or end rounds sooner.
- `must extend MicroGame` → game.tscn's root script must `extends MicroGame`.
