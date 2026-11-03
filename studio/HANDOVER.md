# Handover (after R0012, 2026-11-03 10:46 PT)
Phase: BUILD · Mode: REVIEW (+ one Lane B task) · Hub: 8 games (Shapeshifter, Gear Grind, Upper Case, Bit Catcher, Phase Shift, Cargo Shift, Night Watch, Red Shift) + OVERFLOW finale cell · Days to deadline: 28

## What this run did
- **Second review** (`studio/reviews/R0012.md`): Jam Critic (Opus) scored all 8 games, OVERFLOW and the hub; QA Lead sweep (Sonnet) focused on the four unreviewed games and touch. Collection 7.2 overall (+0.6 vs R0006). No game below the 6.5 ship bar; Red Shift exactly on it. No cuts.
- **T-0032 Red Shift: formations of 3** (3dc4a0b): one-hue V or line formations, hues alternate after RED_AT, leader may be heavy. QA's first verify FAILED (a back()-based spawn detection made duplicate and mixed-hue formations); the builder fixed it in one round and QA re-verify PASSED (2 seeds x 29 formations scripted check, bot wins 2770/2800).
- Filed T-0033..T-0039 from the review; T-0030 widened into the gauntlet interstitial card (Critic fix 4) and raised to P1; T-0031 raised to P1.
- INBOX empty; no GitHub issues needing attention. No prompt drift.

## Build health
check.sh all: PASS (preflight; check.sh redshift PASS again after the change) · registry: ok · CI: ok (f0c60a1) · push: pending (WSL loop; sandbox has no credentials)

## In flight / uncommitted
Nothing. Scratch only in git-ignored .tools/ (review-R0012-*.md, qa/, dbg/, shots, msg-t0032.txt).

## Scores (latest review, R0012)
- Collection: Overall 7.2 · Gameplay 6.7 · Graphics 7.1 · Audio 6.9 · Innovation 7.4 · Theme 8.4.
- Shapeshifter 7.2 · Gear Grind 7.0 · Upper Case 7.0 · Bit Catcher 6.9 · Night Watch 6.8 (Innovation 7.6) · Cargo Shift 6.7 · Phase Shift 6.6 (Graphics 6.0) · Red Shift 6.5 (Graphics 6.4; formations landed after scoring) · OVERFLOW gauntlet 7.0 · Hub 7.6.

## Next run should
1. BUILD Lane B (slots full: 8/8, so no Lane A): two P1s on different files in parallel: T-0034 (Phase Shift parallax rows) and T-0033 (Red Shift two-finger touch). Then T-0035 (Night Watch), T-0036 (Cargo Shift), T-0030 (gauntlet card, Platform).
2. T-0031 waits for the first web export (do it with RELEASE or earlier if a run has spare time); T-0028 still wants Daniel's one-line call or a Creative Director decision.
3. Keep `check.sh all` in the foreground with `timeout 170` (about 50 s). At most 2 Godot processes per device_bash call.
4. Next review due at R0018.

## Needs Daniel
1. Keep `./scripts/push_loop.sh` running in WSL: T-0032 and the R0012 bookkeeping are waiting.
2. **Proposed change to `studio/procedure.md` rule 5 / step 0.7 and the CLAUDE.md "Commands" note** (unchanged since R0001): background jobs die when a device_bash call returns. Replace with:
   > **Long commands.** `device_bash` calls time out at 180 s and background jobs are killed when the call returns. Run `check.sh` in the foreground with `timeout 170` (device_bash `timeout_ms: 180000`); when `all` would take longer, run `check.sh hub` and then `check.sh <slug>...` in batches across calls. Exports and downloads the same way, in steps.
3. Optional: add the gauntlet to the gate (`--gauntlet --autoplay`, assert `ARCADE gauntlet done`), and consider a selftest hook for game-side spawn logic like Red Shift's `_form_up` (QA noted the rules.gd sim doesn't cover it).
4. Git leaves `tmp_obj_*` and `.lock` files under `.git`; run `git gc` / `git prune` from WSL now and then.
5. Optional decision for T-0028: should the dim locked OVERFLOW cell show before all 8 bits are set (a teaser), or stay hidden as VISION says? A one-line INBOX note settles it.
6. A hands-on phone playtest helps most, especially Red Shift (QA thinks steering + BRAKE/BOOST needs two fingers and only one works; T-0033), Night Watch and Cargo Shift's drag.
