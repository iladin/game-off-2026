# Handover (after R0004, 2026-11-03 00:46 PT)
Phase: BUILD · Mode: BUILD · Hub: 3 games (Shapeshifter, Gear Grind, Upper Case) · Days to deadline: 28

## What this run did
- **Shipped Upper Case** (0fdfdd8), slot 3. Built by Sonnet from the R0003 design. QA verify: DESIGN items 1-9 PASS, verdict SHIP; autoplay `ARCADE finished uppercase score=2430 won=true`. QA P2s filed as T-0008 and T-0009.
- **T-0006 Gear Grind layout fixes** (62cb02c): lever label inside the box, TOP label moved out of the needle path, rival mini-map square offset, 160-point tach arcs. QA PASS (TOP label by geometry only; on-screen check is in T-0009).
- **T-0004 Shapeshifter popup** (531c780): `+N` now spawns at y 220 and ends below the HUD band. QA PASS (frame 270 caught the end of the rise).
- **T-0005 Shapeshifter hole gap and depth tint** (59494ce): the first QA round FAILED (gap not visible), and the fix round PASSED.
- **Bit Catcher designed** (0ae44d0), slot 4: DESIGN.md and scaffold, status draft.
- **Bit Catcher built but NOT committed** (see below).

## Build health
check.sh all: PASS (hub with 3 games, _template, bitcatcher (uncommitted build), geargrind, shapeshifter, uppercase) · registry: ok · CI: unknown (HTTP 404: repo not on GitHub) · push: pending (WSL loop; `git push` fails, no repo/remote)

Environment notes: run `check.sh` in the foreground with `timeout 170` (all 6 targets fit). `shots.sh` play frames take about 25-30 s each, so ask for at most 3-4 per call.

## In flight / uncommitted
**`games/bitcatcher/`**: the full build is in the working tree, uncommitted, and `game.json` is still `draft`. Changed: DESIGN.md, game.gd, rules.gd and selftest.gd. New: bits_draw.gd, bits_fx.gd and bits_input.gd, with their .uid files. `check.sh bitcatcher` passes.
- QA round 1 was NO-SHIP for two reasons. The bot won in about 18 s, under VISION's 30-90 s. The shift slide, byte flash, byte squash, socket pop-in and life flash were declared but never triggered.
- The fix round wired all of those effects (QA confirmed by code read). It also retuned the bot: `BOT_STEP` 0.15, `BOT_REACT` 0.50, and the new `BOT_SLAM_CHANCE` 0.5.
- **Still failing:** the bot is randomised, and QA saw no finish by frame 3000 in 4 of 4 runs. The finish landed between frames 3000 and 3600, so `check.sh` will flake against the 60 s autoplay limit.
- **To finish it:**
  1. Tune the bot only, so the median first finish is about frames 2200-2600, for example `BOT_SLAM_CHANCE` about 0.8 and `BOT_REACT` about 0.3. Rounds must stay at 30 s or more.
  2. Run headless autoplay 5 times. `$GODOT --headless --path . --fixed-fps 60 --quit-after 3600 -- --game=bitcatcher --autoplay` should finish each time before frame 3300 with won=true.
  3. QA re-verify: shots in the ZEROS phase (a falling 0, LOST BIT) and a caught row slide, plus the DESIGN checklist.
  4. Ship it as slot 4 and run `registry.py`.
- If it can't pass in one run, leave it as is. Don't move it to `.tools/failed`, because it is close.

## Scores (latest review)
No reviews yet. The first REVIEW is due at R0006 (`run_counter - last_review_run >= 6`).

## Next run should
1. **Lane A: finish Bit Catcher** (Gameplay Engineer, `games/bitcatcher/` only) as described above. Then QA, and ship it in slot 4.
2. **Lane B, in parallel: T-0008**, the Upper Case hint glow spill and the lower-case tile over the key strip (`games/uppercase/`).
3. If time remains: Game Designer for slot 5 per VISION's slate. T-0003 (OVERFLOW) can now be staffed, since 3 games are shipped. It is the Platform Engineer's, touches hub+shared, and is larger.
4. The R0006 REVIEW is two runs away.

## Needs Daniel
1. **GitHub isn't set up yet**, so commits stay local, and CI and issues return 404. In WSL: `cd /mnt/c/git/game-off-2026 && bash scripts/setup_github.sh`, then leave `./scripts/push_loop.sh` running. Local `main` now has 11 commits plus this bookkeeping commit that aren't pushed.
2. **Proposed change to `studio/procedure.md` rule 5 and step 0.7, and the CLAUDE.md "Commands" note** (unchanged since R0001). Background jobs die when a device_bash call returns. Replace the rule with:
   > **Long commands.** `device_bash` calls time out at 180 s and background jobs are killed when the call returns. Run `check.sh` in the foreground with `timeout 170` (device_bash `timeout_ms: 180000`); when `all` would take longer, run `check.sh hub` and then `check.sh <slug>...` in batches across calls. Exports and downloads the same way, in steps.
3. A hands-on playtest of the 3 hub games with keys and touch would help. Upper Case's Left Shift vs Right Shift detection (`InputEventKey.location`) has never run in a real browser; F and J are the fallbacks.
