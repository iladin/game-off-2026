# Handover (after R0014, 2026-11-03 12:37 PT)
Phase: BUILD · Mode: BUILD (Lane B, three rounds) · Hub: 8 games (Shapeshifter, Gear Grind, Upper Case, Bit Catcher, Phase Shift, Cargo Shift, Night Watch, Red Shift) + OVERFLOW finale cell · Days to deadline: 28

## What this run did
Five backlog tasks committed. The Producer re-ran the gate for each, and a QA Lead subagent verified each one as PASS:
- **T-0041 Night Watch: stronger danger cues** (5ab0c53). There is now one cue implementation, in watch_draw.gd. The BAD outline is drawn inside the thumbnail and the main-view bar is 8 px wide at x 886-894. Both pulse between alpha 0.6 and 1.0 and sit at least 3 px clear of the hint glow and arrow.
- **T-0040 Red Shift: popup rise stays below the HUD** (6e0e62a). `R.popup_pos` sets POPUP_MIN_Y to 168, so a popup's label top ends at y 66 or lower. The DODGE popup is clamped now as well. Selftested.
- **T-0042 Cargo Shift: waterline follows the sea** (39adf0c). The hull is clipped against a world-space band at SEA_Y, so the line stays level while the hull tilts.
- **T-0025 Shared: late-round QA flags** (491ded2). Two new flags: `--difficulty=N` and `--rstart=<s>` (MicroGame.qa_ramp). They also work as `SHIFT_QA="--rstart=40" ./scripts/shots.sh geargrind 380`, which reaches fifth gear. Desktop single-game launches only.
- **T-0043 Shared: cap the gauntlet card word** (d7ad814). `fit_size` keeps the card word within 1100 px. A game with no `sense` falls back to its title. New debug flag `--cardword=`.
- **T-0031 (P1), first web export DONE but browser check BLOCKED.** The Release Manager installed the 4.7.2 web templates on the machine and exported `build/web` (wasm 38 MB, pck 306 KB, no warnings). Chromium is not reachable:
  - `cdn.playwright.dev` and `storage.googleapis.com` both return 403 under the allowlist.
  - Running the npm-bundled `@sparticuz/chromium` (in `.tools/pw`) was denied by the permission system. I did not work around that denial.
- Filed T-0044..T-0048 (P2) from QA notes. INBOX was empty and no GitHub issues need attention. No prompt drift.

## Build health
check.sh all: PASS (at preflight, after T-0040/41/42/25, and after T-0043) · hub selftest: SELFTEST OK · registry: ok · CI: ok (0b1590e) · push: pending (WSL loop; sandbox has no credentials)

## In flight / uncommitted
Nothing. Scratch only in git-ignored paths: `build/web/` (first export), `.tools/tpl/tpl.tpz` (1.28 GB templates download; Daniel can delete it), `.tools/pw/` (node playwright + @sparticuz/chromium, unused), shots and msg-t00xx.txt.

## Scores (latest review, R0012)
- Collection: Overall 7.2 · Gameplay 6.7 · Graphics 7.1 · Audio 6.9 · Innovation 7.4 · Theme 8.4.
- Shapeshifter 7.2 · Gear Grind 7.0 · Upper Case 7.0 · Bit Catcher 6.9 · Night Watch 6.8 · Cargo Shift 6.7 · Phase Shift 6.6 (Graphics 6.0) · Red Shift 6.5 (Graphics 6.4) · OVERFLOW gauntlet 7.0 · Hub 7.6.

## Next run should
1. BUILD Lane B with two tasks on different files: T-0044 (Gear Grind sloppy-bot flag, which unblocks T-0026) and T-0047 or T-0048. Then T-0045, T-0046 and T-0026.
2. T-0031 stays blocked until Daniel answers Needs Daniel #1. To redo the export: `GODOT=$PWD/.tools/godot; timeout 150 $GODOT --headless --path . --import`, then `timeout 170 ./scripts/export_web.sh`. The templates are already installed on the machine.
3. T-0028 still needs Daniel's call or a Creative Director decision.
4. Run `check.sh all` in the foreground with `timeout 170` (about 50 s). The next review is due at R0018.

## Needs Daniel
1. **Web browser check (T-0031, P1).** No headless Chromium is reachable here, so pick one of these:
   - (a) allowlist `cdn.playwright.dev` so `npx playwright install chromium` works;
   - (b) install chromium on the machine/VM;
   - (c) approve running the npm package `@sparticuz/chromium` that is already in `.tools/pw`;
   - (d) run `scripts/browser_check.mjs` in CI.
   
   A one-line INBOX note settles it. The F/J fallback keys already work and are labelled on the web either way.
2. Keep `./scripts/push_loop.sh` running in WSL. 5 task commits plus the R0014 bookkeeping are waiting.
3. **Proposed change to `studio/procedure.md` rule 5 / step 0.7 and the CLAUDE.md "Commands" note** (unchanged since R0001). Background jobs die when a device_bash call returns. Replace the text with:
   > **Long commands.** `device_bash` calls time out at 180 s and background jobs are killed when the call returns. Run `check.sh` in the foreground with `timeout 170` (device_bash `timeout_ms: 180000`); when `all` would take longer, run `check.sh hub` and then `check.sh <slug>...` in batches across calls. Exports and downloads the same way, in steps.
4. Optional changes to `scripts/` (Daniel-owned):
   - `check.sh hub`: also run `res://hub/selftest.gd` (it isn't in the gate today); run per-game `touch_check.tscn` when present; add a gauntlet run.
   - `shots.sh`: document `SHIFT_QA` / `--rstart` and add a gauntlet card shot.
5. Git leaves `tmp_obj_*` and `.lock` files under `.git`. Run `git gc` / `git prune` from WSL now and then. You can also delete `.tools/tpl/tpl.tpz` (1.28 GB).
6. Optional decision for T-0028: should the dim locked OVERFLOW cell show before all 8 bits are set (a teaser), or stay hidden as VISION says?
