# Handover (after R0019, 2026-11-03 17:38 PT)
Phase: BUILD · Mode: BUILD (Lane B, two rounds of two) · Hub: 8 games (Shapeshifter, Gear Grind, Upper Case, Bit Catcher, Phase Shift, Cargo Shift, Night Watch, Red Shift) + OVERFLOW finale cell · Days to deadline: 28

## What this run did
- **T-0065 Night Watch: creeper silhouette and scanline** (9328133). Calm watched feed shows a frozen PANEL/INK silhouette (height lerp(60,320,d)); a TRACE scanline sweeps the main view; lone eye dash removed in watch_draw.gd. QA verify PASS.
- **T-0066 Cargo Shift: rogue swell** (6e03100). Telegraphed (hiss + ROGUE SWELL LEFT/RIGHT) swell every 8-12 s from 12 s shoves crates 60-120 px and kicks the list >= 6 deg, with a thud; crates drift home. Bot asserts loosened (tilt 0.3/0.35, score floor 1000). QA verify PASS.
- **T-0068 Hub: attract mode** (6a5f9cf). After 8 s idle the register rotates one cell per 1.2 s under the head; any input stops it. QA verify PASS (600 vs 690: UPPER CASE vs BIT CATCHER).
- **T-0067 Phase Shift: three floor heights, filled orbs** (0badec2). First QA round FAILED (play-1200 showed one height); fix round makes every run step, with a 16-cell two-heights selftest. Re-verify PASS.
- Filed P2s from QA: T-0073..T-0076. INBOX empty, no GitHub issues, no prompt drift.

## Build health
check.sh all: PASS (preflight; nightwatch, cargoshift, hub, phaseshift re-run PASS after changes) · registry: ok · CI: ok (3490ebb) · push: pending (WSL loop; sandbox has no credentials)

## In flight / uncommitted
Nothing. Scratch in git-ignored `.tools/`: `qa19-nw/`, `qa19-cs/`, `qa19-hub/`, `qa19-ps/`, `msg-t006*.txt`, `shots.lock`, plus older leftovers.

## Scores (latest review, R0018)
- Collection: Overall 7.4 · Gameplay 6.8 · Graphics 7.3 · Audio 6.9 · Innovation 7.7 · Theme 8.6.
- Shapeshifter 7.2 (Innovation 6.0) · Gear Grind 7.2 (Innovation 5.8) · Upper Case 7.0 (Innovation 6.2) · Bit Catcher 6.9 (Gameplay 6.4) · Phase Shift 6.9 (Innovation 5.6) · Cargo Shift 6.9 (Gameplay 6.3) · Night Watch 6.9 (Graphics 6.6) · Red Shift 6.6 before T-0064 (Gameplay 6.3) · OVERFLOW 7.5 (Audio 6.6) · Hub 7.6 (Audio 6.8).
- R0019 changes (T-0065..T-0068) target the weak spots of Night Watch, Cargo Shift, Phase Shift and the hub; not yet re-scored.

## Next run should
1. BUILD Lane B, the remaining P1s in parallel: **T-0070** (Red Shift BRAKE/BOOST teaching) and **T-0069** (shared HUB/SOUND touch targets). T-0031 stays blocked on Daniel.
2. Then P2s on different files: T-0072 (redshift; after T-0070, not in parallel), T-0071 (gauntlet), T-0073..T-0076, T-0061..T-0063.
3. QA tips: wrap shot runs in `flock .tools/shots.lock` so two QAs can run in parallel; shots.sh takes space-separated frames; `shots.sh hub` ignores frames (run Godot with its flags directly). Cargo Shift swell: frames 690 vs 810 (random side). Phase Shift heights: 900/1200. Red Shift bullets: `--autoplay` frame 1500.
4. Run `check.sh` in the foreground with `timeout 170` (~50 s for all).
5. Next review due at R0024 (it should re-score Phase Shift's busier stepping; QA suggests a human feel check).

## Needs Daniel
1. **T-0031 (P1) web Left/Right Shift.** Simplest option now (Critic): open `build/web` once in your own desktop Chrome, press Left and Right Shift in Upper Case, and leave an INBOX note saying whether both register. The other options still work: (a) allowlist `cdn.playwright.dev`; (b) install chromium on the VM; (c) approve `@sparticuz/chromium` in `.tools/pw`; (d) run `scripts/browser_check.mjs` in CI. `build/web` is from R0014; a re-export first would be better (a run can do it on request).
2. Keep `./scripts/push_loop.sh` running in WSL (R0019 adds 9328133, 6e03100, 6a5f9cf, 0badec2 + bookkeeping).
3. Proposed `studio/procedure.md` rule 5 / step 0.7 and CLAUDE.md "Commands" change (unchanged since R0001): background jobs die when a device_bash call returns. Replace with:
   > **Long commands.** `device_bash` calls time out at 180 s and background jobs are killed when the call returns. Run `check.sh` in the foreground with `timeout 170` (device_bash `timeout_ms: 180000`); when `all` would take longer, run `check.sh hub` and then `check.sh <slug>...` in batches across calls. Exports and downloads the same way, in steps.
4. Optional `scripts/` changes: `check.sh hub` should run `res://hub/selftest.gd`, per-game `touch_check.tscn` and a gauntlet run; `shots.sh` should document `SHIFT_QA` / `--rstart` and add a gauntlet card shot; also `shots.sh hub` ignores its frame argument (hardcoded frame 60), so hub attract shots at 600/690 need Godot run directly.
5. Git leaves `tmp_obj_*` and `.lock` files under `.git`; run `git gc` / `git prune` from WSL now and then. `.tools/tpl/tpl.tpz` (1.28 GB) can be deleted.
6. Optional T-0028 decision: show the dim locked OVERFLOW cell from 0 bits (teaser) or hide it until unlocked, as VISION says? QA flagged it again in R0018.
