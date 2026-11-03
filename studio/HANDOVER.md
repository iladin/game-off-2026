# Handover (after R0006, 2026-11-03 03:25 PT)
Phase: BUILD · Mode: REVIEW (+ one Lane B task) · Hub: 4 games (Shapeshifter, Gear Grind, Upper Case, Bit Catcher) · Days to deadline: 28

## What this run did
- **Took over R0005's stale lock** (since 09:07Z; R0005 never wrapped up). R0005 had committed Bit Catcher (3ea6769, slot 4), T-0008 Upper Case (0ef5096) and the Phase Shift design and scaffold (7d01c9b, draft, slot 5). Its uncommitted IDEAS/LOG/state edits are adopted into this run's bookkeeping, and `shipped` is now 4.
- **First REVIEW** (`studio/reviews/R0006.md`): Jam Critic (Opus) plus a QA Lead sweep (Sonnet). The findings became 8 BACKLOG items, T-0010 to T-0017. Critic fix 8 (a locked OVERFLOW cell) was folded into T-0003. `last_review_run` = 6.
- **T-0010 Bit Catcher readability** (58b0db9): lime `1` set cells, a target socket row above the register, the first falling bit visible for about 3 s, and the debug print removed. QA verify PASS on 6/6. Follow-up P2: T-0018 (the banner crosses the fall zone; DESIGN.md is out of date).

## Build health
check.sh all: PASS (hub with 4 games, _template, bitcatcher, geargrind, phaseshift, shapeshifter, uppercase; run in the foreground with `timeout 170`, which fits) · check.sh bitcatcher after T-0010: PASS · registry: ok · CI: unknown (HTTP 404: repo not on GitHub) · push: pending (WSL loop)

## In flight / uncommitted
Nothing. Phase Shift (`games/phaseshift/`) is committed as a draft: DESIGN.md plus scaffold, not built yet.

## Scores (latest review)
- Collection: 6.6 (Theme 7.8 is the strongest; Audio 6.3 is the weakest).
- Shapeshifter: 7.2 (weakest: Innovation 6.0).
- Gear Grind: 6.8 (weakest: Innovation 5.8).
- Upper Case: 6.6 (weakest: Audio 6.0).
- Bit Catcher: 6.3, **below the ship bar** (weakest: Graphics 5.8). T-0010 addressed its biggest readability gap, and T-0011 is the second fix. Re-score it at the next review.

## Next run should
1. **Lane A: build Phase Shift** (Gameplay Engineer, from `games/phaseshift/DESIGN.md`), then QA verify and ship it as slot 5. That unlocks `min_games` = 5 for OVERFLOW.
2. **Lane B, in parallel: T-0011** (Bit Catcher progress squares, lane line and calmer byte flash), so Bit Catcher clears the bar. Then T-0012 (the Upper Case glow), T-0013 and T-0014 in P1 order.
3. Once Phase Shift ships: Game Designer for slot 6 (Cargo Shift), and T-0003 (OVERFLOW) for the Platform Engineer.
4. The next REVIEW is due at R0012.

## Needs Daniel
1. **GitHub isn't set up yet**, so commits stay local and CI and issues return 404. In WSL: `cd /mnt/c/git/game-off-2026 && bash scripts/setup_github.sh`, then leave `./scripts/push_loop.sh` running.
2. **Proposed change to `studio/procedure.md` rule 5 and step 0.7, and to the CLAUDE.md "Commands" note** (unchanged since R0001). Background jobs die when a device_bash call returns. Replace the rule with:
   > **Long commands.** `device_bash` calls time out at 180 s and background jobs are killed when the call returns. Run `check.sh` in the foreground with `timeout 170` (device_bash `timeout_ms: 180000`); when `all` would take longer, run `check.sh hub` and then `check.sh <slug>...` in batches across calls. Exports and downloads the same way, in steps.
3. **Git leaves temp and lock files.** Commits print `unable to unlink .git/objects/.../tmp_obj_*` warnings, because the sandbox can't delete. `git_unlock.sh` handles the `.lock` files, but `tmp_obj_*` files pile up under `.git/objects`. Running `git gc` or `git prune` from WSL now and then cleans them up.
4. A hands-on playtest of the 4 hub games with keys and touch would help. Upper Case's Left Shift vs Right Shift detection has never run in a real browser.
