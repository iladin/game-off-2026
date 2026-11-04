# Handover (after R0018, 2026-11-03 16:26 PT)
Phase: BUILD · Mode: REVIEW + one Lane B task · Hub: 8 games (Shapeshifter, Gear Grind, Upper Case, Bit Catcher, Phase Shift, Cargo Shift, Night Watch, Red Shift) + OVERFLOW finale cell · Days to deadline: 28

## What this run did
- **Review R0018** (`studio/reviews/R0018.md`): Jam Critic (opus) + QA Lead sweep (sonnet) in parallel. Collection 7.4 (+0.2), Theme 8.6. No game below ship_bar; no cuts. Critic: stop popup nits, go after big P1s. Producer correction: Red Shift formations already exist (T-0032 in game.gd); only return fire was new.
- Filed 8 tasks from the review: T-0064..T-0070 (P1) and T-0071 (P2); `last_review_run` = 18.
- **T-0064 Red Shift: formations return fire** (48facc0). Formation leaders fire band-coloured bullets from r >= 20 s; matching shots pop them, otherwise a crash. Producer re-ran check.sh redshift: PASS; QA verify PASS (shots `.tools/qa18-rs/a1500.png`, `r25.png`). QA P2s filed as T-0072.
- INBOX empty, no GitHub issues, no prompt drift.

## Build health
check.sh all: PASS (preflight; redshift re-run PASS after T-0064) · registry: ok · CI: ok (ea5be34) · push: pending (WSL loop; sandbox has no credentials)

## In flight / uncommitted
Nothing. Scratch in git-ignored `.tools/`: `r18-critic.md`, `r18-qa.md`, `shots-r18/`, `qa18-rs/`, `msg-t0064.txt`, plus older leftovers (`build/web`, `.tools/tpl/tpl.tpz`, `.tools/pw`).

## Scores (latest review, R0018)
- Collection: Overall 7.4 · Gameplay 6.8 · Graphics 7.3 · Audio 6.9 · Innovation 7.7 · Theme 8.6.
- Shapeshifter 7.2 (Innovation 6.0) · Gear Grind 7.2 (Innovation 5.8) · Upper Case 7.0 (Innovation 6.2) · Bit Catcher 6.9 (Gameplay 6.4) · Phase Shift 6.9 (Innovation 5.6) · Cargo Shift 6.9 (Gameplay 6.3) · Night Watch 6.9 (Graphics 6.6) · Red Shift 6.6 before T-0064 (Gameplay 6.3) · OVERFLOW 7.5 (Audio 6.6) · Hub 7.6 (Audio 6.8).

## Next run should
1. BUILD Lane B, two P1s on different files in parallel: **T-0065** (Night Watch main-view creeper silhouette) and **T-0066** (Cargo Shift rogue swell). Then T-0067 (Phase Shift heights), T-0070 (Red Shift BRAKE/BOOST teaching; touches redshift, don't pair with T-0072), T-0068 (hub attract), T-0069 (shared touch targets).
2. Keep doing P1s before the P2 popup nits (T-0061..T-0063, T-0072).
3. QA tips: Red Shift bullets: `--autoplay` frame 1500, or `--rstart=25` frame 420. Others as before (Gear Grind `SHIFT_QA="--rstart=40"`, Night Watch `--nwqa-hold` frame 1250). One godot shot run at a time.
4. Run `check.sh` in the foreground with `timeout 170` (~50 s for all).
5. Next review due at R0024.

## Needs Daniel
1. **T-0031 (P1) web Left/Right Shift.** Simplest option now (Critic): open `build/web` once in your own desktop Chrome, press Left and Right Shift in Upper Case, and leave an INBOX note saying whether both register. The other options still work: (a) allowlist `cdn.playwright.dev`; (b) install chromium on the VM; (c) approve `@sparticuz/chromium` in `.tools/pw`; (d) run `scripts/browser_check.mjs` in CI. `build/web` is from R0014; a re-export first would be better (a run can do it on request).
2. Keep `./scripts/push_loop.sh` running in WSL (R0018 adds 48facc0 + bookkeeping).
3. Proposed `studio/procedure.md` rule 5 / step 0.7 and CLAUDE.md "Commands" change (unchanged since R0001): background jobs die when a device_bash call returns. Replace with:
   > **Long commands.** `device_bash` calls time out at 180 s and background jobs are killed when the call returns. Run `check.sh` in the foreground with `timeout 170` (device_bash `timeout_ms: 180000`); when `all` would take longer, run `check.sh hub` and then `check.sh <slug>...` in batches across calls. Exports and downloads the same way, in steps.
4. Optional `scripts/` changes: `check.sh hub` should run `res://hub/selftest.gd`, per-game `touch_check.tscn` and a gauntlet run; `shots.sh` should document `SHIFT_QA` / `--rstart` and add a gauntlet card shot.
5. Git leaves `tmp_obj_*` and `.lock` files under `.git`; run `git gc` / `git prune` from WSL now and then. `.tools/tpl/tpl.tpz` (1.28 GB) can be deleted.
6. Optional T-0028 decision: show the dim locked OVERFLOW cell from 0 bits (teaser) or hide it until unlocked, as VISION says? QA flagged it again in R0018.
