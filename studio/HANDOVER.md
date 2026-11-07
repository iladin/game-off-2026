# Handover (after R0020, 2026-11-07 14:30 PT)
Phase: BUILD · Mode: BUILD (Lane B, two rounds of two) · Hub: 8 games (Shapeshifter, Gear Grind, Upper Case, Bit Catcher, Phase Shift, Cargo Shift, Night Watch, Red Shift) + OVERFLOW finale cell · Days to deadline: 24

## What this run did
- **T-0070 Red Shift: pads teach BRAKE = ember, BOOST = blue** (b7d8544). Pure `Rules.teach_pad`: BRAKE pulses from r 0 until the first ember enemy, BOOST in the 5 s before blue; 80x32 hue chips with band shapes on both pads. QA verify PASS.
- **T-0069 Shared: 96 px HUB/SOUND hit areas + TAP AGAIN** (d132218). Invisible 96 px overlays over the 48 px buttons; mid-round HUB needs a second tap within 1.5 s; Esc unchanged. New `shared/ui_rules.gd` + `shared/ui_selftest.gd`. QA verify PASS (xvfb click test).
- **T-0072 Red Shift: ringed r9 bullets; --rstart via qa_ramp** (cf37379). Hitbox unchanged; BULLET_MAX and off-screen selftests. QA verify PASS (with --rstart=25 the bot loses before 50 s: T-0078).
- **T-0071 Shared: OVERFLOW card tones + clear card on the grid** (83cc819). `GauntletRules.card_midi` A minor pentatonic rising per slot; clear card BG + TRACE grid; score line SCORE n. QA verify PASS.
- Filed P2s from QA: T-0077..T-0079. INBOX empty, no GitHub issues, no prompt drift.

## Build health
check.sh all: PASS (preflight and after all four commits) · registry: ok · CI: ok (797b4ec, before this run's commits) · push: pending (WSL loop; sandbox has no credentials)

## In flight / uncommitted
Nothing. Scratch in git-ignored `.tools/`: `qa20-rs/`, `qa20-rs2/`, `qa20-ui/`, `qa20-gt/`, `shots/r20/`, `shots-r20/`, `msg-t00*.txt`, plus older leftovers.

## Scores (latest review, R0018)
- Collection: Overall 7.4 · Gameplay 6.8 · Graphics 7.3 · Audio 6.9 · Innovation 7.7 · Theme 8.6.
- Shapeshifter 7.2 (Innovation 6.0) · Gear Grind 7.2 (Innovation 5.8) · Upper Case 7.0 (Innovation 6.2) · Bit Catcher 6.9 (Gameplay 6.4) · Phase Shift 6.9 (Innovation 5.6) · Cargo Shift 6.9 (Gameplay 6.3) · Night Watch 6.9 (Graphics 6.6) · Red Shift 6.6 before T-0064/T-0070/T-0072 (Gameplay 6.3) · OVERFLOW 7.5 (Audio 6.6) · Hub 7.6 (Audio 6.8).
- R0019/R0020 changes target the weak spots of Night Watch, Cargo Shift, Phase Shift, Red Shift, OVERFLOW audio and the hub; not yet re-scored.

## Next run should
1. BUILD Lane B, P2s on different files, two at a time: T-0074 (hub) + T-0073 (phaseshift); then T-0075 (cargoshift) + T-0076/T-0063 (nightwatch); then T-0061/T-0062 (geargrind), T-0077/T-0078 (redshift), T-0079 (shared). T-0031 stays blocked on Daniel; T-0028 needs the Creative Director (or Daniel's call).
2. QA tips: wrap shot runs in `flock .tools/shots.lock`; OVERFLOW clear card: `--resultdemo` frames 30/180; gauntlet card: `--gauntlet` frame 40 (Godot run directly under xvfb, see .tools/qa20-gt); click tests need xvfb, not headless. Red Shift BOOST cue: non-autoplay idle frames ~1058. `hub/selftest.gd` and `shared/ui_selftest.gd` are NOT run by check.sh: run them by hand after shared/hub changes.
3. Run `check.sh` in the foreground with `timeout 170` (~50 s for all).
4. Next review due at R0024 (re-score Red Shift, Phase Shift stepping, OVERFLOW audio, hub touch).

## Needs Daniel
1. **T-0031 (P1) web Left/Right Shift.** Simplest option now (Critic): open `build/web` once in your own desktop Chrome, press Left and Right Shift in Upper Case, and leave an INBOX note saying whether both register. The other options still work: (a) allowlist `cdn.playwright.dev`; (b) install chromium on the VM; (c) approve `@sparticuz/chromium` in `.tools/pw`; (d) run `scripts/browser_check.mjs` in CI. `build/web` is from R0014; a re-export first would be better (a run can do it on request).
2. Keep `./scripts/push_loop.sh` running in WSL (R0020 adds b7d8544, d132218, cf37379, 83cc819 + bookkeeping).
3. Proposed `studio/procedure.md` rule 5 / step 0.7 and CLAUDE.md "Commands" change (unchanged since R0001): background jobs die when a device_bash call returns. Replace with:
   > **Long commands.** `device_bash` calls time out at 180 s and background jobs are killed when the call returns. Run `check.sh` in the foreground with `timeout 170` (device_bash `timeout_ms: 180000`); when `all` would take longer, run `check.sh hub` and then `check.sh <slug>...` in batches across calls. Exports and downloads the same way, in steps.
4. Optional `scripts/` changes: `check.sh hub` should run `res://hub/selftest.gd` and `res://shared/ui_selftest.gd` (both print SELFTEST OK; new pitch and HUB-confirm asserts are ungated), per-game `touch_check.tscn` and a gauntlet run; `shots.sh` should document `SHIFT_QA` / `--rstart` and add a gauntlet card shot; also `shots.sh hub` ignores its frame argument (hardcoded frame 60), so hub attract shots at 600/690 need Godot run directly.
5. Git leaves `tmp_obj_*` and `.lock` files under `.git`; run `git gc` / `git prune` from WSL now and then. `.tools/tpl/tpl.tpz` (1.28 GB) can be deleted.
6. Optional T-0028 decision: show the dim locked OVERFLOW cell from 0 bits (teaser) or hide it until unlocked, as VISION says? QA flagged it again in R0018.
