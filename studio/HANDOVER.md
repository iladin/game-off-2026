# Handover (after R0007, 2026-11-03 04:45 PT)
Phase: BUILD · Mode: BUILD (Lane A + Lane B, two rounds) · Hub: 5 games (Shapeshifter, Gear Grind, Upper Case, Bit Catcher, Phase Shift) · Days to deadline: 28

## What this run did
- **Shipped Phase Shift** (1d8f721, slot 5): two-world auto-runner, built by the Gameplay Engineer from DESIGN.md. QA verify PASS on 11/11 items; 4 headless autoplay runs won, finishing at frames 2441-2460. Builder's deviations (zone-3 runs 6/8, bot looks one hole ahead, bot score about 1,750-1,950) were judged acceptable; the doc catch-up is T-0019. A scratch `dbg_tmp.gd` (+ .uid) the builder couldn't delete was moved to `.tools/scratch/` (ignored), not committed.
- **Cargo Shift designed** (0faa038, slot 6, draft): Game Designer (Opus) ran new_game.sh and wrote DESIGN.md, with balance numbers simulated at 60 Hz (bot never capsizes; no input sinks). Scaffold only; not built.
- **T-0011 Bit Catcher** (279c520): progress squares, landing lane, calmer byte flash. QA PASS (the flash frame itself wasn't sampled; verified by code and the post-byte frame).
- **T-0012 Upper Case** (b9d37b1): fixed-inset hint glow on the hinted key only. QA PASS, measured with PIL.
- **T-0013 Shapeshifter** (6a18a83): steady 6 px BAD warning past p 0.75 plus correct-button glow; INK >= 4 px outline otherwise; inert `--qa-mismatch` flag for QA shots. QA PASS.
- **T-0014 Gear Grind** (db1bf5e): irregular roadside posts, 0.4x skyline, rival gap marker, everything within y 704. Failed QA on post aliasing and a 1-4 px stroke overshoot, fixed in one round, re-verify PASS.
- Filed T-0019 (P2 DESIGN.md catch-ups for phaseshift, shapeshifter and bitcatcher). INBOX empty; no issues (404).

## Build health
check.sh all: PASS (hub with 5 games, _template, bitcatcher, cargoshift, geargrind, phaseshift, shapeshifter, uppercase; foreground with `timeout 170`) · registry: ok · CI: unknown (HTTP 404: repo not on GitHub) · push: pending (WSL loop)

## In flight / uncommitted
Nothing. Cargo Shift (`games/cargoshift/`) is committed as a draft: DESIGN.md plus template scaffold.

## Scores (latest review, R0006; T-0011..T-0014 landed since)
- Collection: 6.6 (weakest: Audio 6.3).
- Shapeshifter: 7.2 (weakest: Innovation 6.0).
- Gear Grind: 6.8 (weakest: Innovation 5.8).
- Upper Case: 6.6 (weakest: Audio 6.0).
- Bit Catcher: 6.3, below the 6.5 ship bar (weakest: Graphics 5.8); T-0010 and T-0011 address it. Re-score at the next review.
- Phase Shift: not yet reviewed.

## Next run should
1. **Lane A: build Cargo Shift** (Gameplay Engineer, from `games/cargoshift/DESIGN.md`), QA verify against its 10-item checklist, ship as slot 6.
2. **Lane B: T-0003 OVERFLOW** (Platform Engineer). `min_games` = 5 is now met, so the finale can unlock; at least show the dim locked cell. If it is too big for one round, then T-0015 (Gear Grind GO moment) and T-0018 (Bit Catcher banner).
3. Then T-0016 (Upper Case audio, the weakest-category fix), T-0017 (touch hub), T-0019 docs.
4. The next REVIEW is due at R0012 (Phase Shift's first score).

## Needs Daniel
1. **GitHub isn't set up yet**, so commits stay local and CI and issues return 404. In WSL: `cd /mnt/c/git/game-off-2026 && bash scripts/setup_github.sh`, then leave `./scripts/push_loop.sh` running. 7 commits are waiting this run.
2. **Proposed change to `studio/procedure.md` rule 5 and step 0.7, and to the CLAUDE.md "Commands" note** (unchanged since R0001). Background jobs die when a device_bash call returns. Replace the rule with:
   > **Long commands.** `device_bash` calls time out at 180 s and background jobs are killed when the call returns. Run `check.sh` in the foreground with `timeout 170` (device_bash `timeout_ms: 180000`); when `all` would take longer, run `check.sh hub` and then `check.sh <slug>...` in batches across calls. Exports and downloads the same way, in steps.
3. **Git leaves `tmp_obj_*` files** under `.git/objects` (the sandbox can't delete). Run `git gc` or `git prune` from WSL now and then.
4. A hands-on playtest with keys and touch would help, especially Phase Shift's touch halves and Upper Case's Left/Right Shift in a real browser.
