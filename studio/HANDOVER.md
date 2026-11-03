# Handover (after R0003, 2026-11-02 23:40 PT)
Phase: BUILD · Mode: BUILD · Hub: 2 games (Shapeshifter, Gear Grind) · Days to deadline: 28

## What this run did
- **Took over R0002's stale lock.** R0002 took the lock at 05:07Z and died around 05:10Z without a handover or a LOG line. It had left an uncommitted Shapeshifter build and a T-0001 draft. Both passed `check.sh`, so this run adopted them.
- **Shipped Shapeshifter** (814c637), slot 1.
  - The Gameplay Engineer audited the build against DESIGN.md and fixed one bug: the hole outline over the player was pink on pink and couldn't be seen; it is now INK.
  - QA verify: items 1-9 PASS, verdict SHIP.
- **T-0001, bit-set ceremony** (f543a00).
  - Platform Engineer fix: the seen-cleared list is now written to Save only when a flip starts. R0002 wrote it in `_ready`, so leaving the hub within 0.5 s would have skipped the ceremony for good.
  - New debug flag `--hubdemo=8 --hubceremony=<i>` shows the ceremony for screenshots.
  - QA: PASS. The squash is visible at frame 42.
- **T-0002, hub glow and empty state** (58b38a6).
  - The digit glow is now concentric with the digit.
  - Empty cells have DIM outlines.
  - New flag `--hubempty` shows the empty state. QA: PASS.
- **Gear Grind: designed, built and shipped** (design 0f951ee, game 00e4e95), slot 2.
  - Designed by Opus, built by Sonnet.
  - The rival's balance is pinned by `simulate()` selftests.
  - QA: items 1-9 PASS, verdict SHIP.
- **Upper Case designed** (4476b1d), slot 3. It has DESIGN.md and the scaffold, status draft; no game code yet.
- Producer check: with the real hub and 1 shipped game, the cell shows SHAPE, the accent is parsed from `game.json`, and the panel shows NEW. That path had never been exercised before.

## Build health
check.sh all: PASS (hub with 2 games, _template, geargrind, shapeshifter; uppercase scaffold PASS separately) · registry: ok · CI: unknown (HTTP 404: repo not on GitHub) · push: pending (WSL loop; `git push` fails because there is no remote/repo)

Environment notes for the next Producer:
- Background jobs die when a device_bash call returns, so run `timeout 170 ./scripts/check.sh all` in the foreground with timeout_ms 180000. With 4 targets it still takes under a minute.
- Commits print `unable to unlink tmp_obj` warnings. They are harmless. Run `scripts/git_unlock.sh --now` after every git write.

## In flight / uncommitted
Nothing. The `uppercase` game is committed as a draft scaffold and is not in the hub.

## Scores (latest review)
No reviews yet. The first REVIEW is due when `run_counter - last_review_run >= 6`, which is R0006.

## Next run should
1. **BUILD Lane A: build Upper Case.** The Gameplay Engineer builds `games/uppercase/` from its DESIGN.md: rules.gd, selftest.gd, game.gd and keys_draw.gd. The main risk is telling Left Shift from Right Shift via `InputEventKey.location`; F and J are the fallbacks. Then QA verifies it against the DESIGN checklist. On PASS: set it shipped with slot 3, run `registry.py`, then `check.sh hub`.
2. **BUILD Lane B, in parallel: T-0006**, the Gear Grind layout fixes (Gameplay Engineer, `games/geargrind/` only). T-0004 or T-0005 for Shapeshifter would also work, but they touch a different game from Lane A, so either is fine.
3. If time remains: Game Designer for slot 4, `bitcatcher`.
4. T-0003 (OVERFLOW) waits until at least 3 games are shipped.

## Needs Daniel
1. **GitHub isn't set up yet**, so commits stay local, and CI and issues return 404.
   - In WSL: `cd /mnt/c/git/game-off-2026 && bash scripts/setup_github.sh`.
   - Then leave `./scripts/push_loop.sh` running.
   - Local `main` is now 6 commits ahead, plus this bookkeeping commit.
2. **Proposed change to `studio/procedure.md` rule 5 and step 0.7, and to the CLAUDE.md "Commands" note** (unchanged since R0001). Background jobs don't survive the end of a device_bash call. Replace the rule with:
   > **Long commands.** `device_bash` calls time out at 180 s and background jobs are killed when the call returns. Run `check.sh` in the foreground with `timeout 170` (device_bash `timeout_ms: 180000`); when `all` would take longer, run `check.sh hub` and then `check.sh <slug>...` in batches across calls. Exports and downloads the same way, in steps.
3. **R0002 died silently** about 3 minutes into its run, at roughly 05:10Z, and left no LOG line or handover. Its next firing at 06:07Z skipped because of the lock. You might check that session's transcript to see why it died: device disconnect, a crash, or a timeout.
4. A first hands-on playtest of Shapeshifter and Gear Grind with keys and touch would help. Neither has been hand-played; only the bot has played them.
