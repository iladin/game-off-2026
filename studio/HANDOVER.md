# Handover (after R0008, 2026-11-03 05:45 PT)
Phase: BUILD · Mode: BUILD (Lane A + Lane B, two rounds) · Hub: 6 games (Shapeshifter, Gear Grind, Upper Case, Bit Catcher, Phase Shift, Cargo Shift) + OVERFLOW finale cell · Days to deadline: 28

## What this run did
- **Shipped Cargo Shift** (fb5efc8, slot 6): ballast-vs-list storm crossing, built by the Gameplay Engineer from DESIGN.md. QA verify PASS on 10/10 checklist items plus the ship bar; autoplay wins deterministically at frame 2745 (score 1890). P2 nits filed as T-0020; unseen states (STORM banner, difficulty 1 start, live touch) as T-0021.
- **T-0003 OVERFLOW** (af2b9bf): locked dim cell, gold unlocked cell, additive `Arcade.start_gauntlet()` / `--gauntlet` (slot order, difficulty 1, 8 s each, 3 lives, plain score sum, slug `overflow`, one card), pure `shared/gauntlet_rules.gd` with selftests, inert `--qa-overflow` flag for shots. First QA failed (gauntlet label overlapped game scores, lives as text, a +100 pass bonus, result card off-centre); one fix round fixed all four, re-verify PASS. The shared result card box is now centred for every game; QA confirmed the normal card looks the same.
- **T-0018 Bit Catcher** (3647192): phase banner moved into the HUD row (x 340, y 56), DESIGN.md caught up. QA PASS on 3 phase-change shots.
- **T-0016 Upper Case** (9fa4f58): typewriter clack on hits, ding on phase banners, F/J labels 32 px. QA PASS (J margin only ~2 px when pressed: T-0022).
- **Night Watch designed** (1bf4702, slot 7, draft): Game Designer (Opus) ran new_game.sh and wrote DESIGN.md, balance simulated (bot 20/20, idle loses after the grace). Scaffold only.
- Filed T-0020..T-0022. INBOX empty; no issues need attention.

## Build health
check.sh all: PASS at preflight (5 shipped + _template + cargoshift); after the changes, check.sh hub (6 games) and every game (shapeshifter, geargrind, uppercase, bitcatcher, phaseshift, cargoshift, nightwatch) PASS individually · registry: ok · CI: running at preflight (ca18b3a; GitHub repo now exists) · push: pending (WSL loop; sandbox push failed for lack of credentials, as expected)

## In flight / uncommitted
Nothing. Night Watch (`games/nightwatch/`) is committed as a draft: DESIGN.md plus template scaffold.

## Scores (latest review, R0006; many fixes landed since)
- Collection: 6.6 (weakest: Audio 6.3).
- Shapeshifter: 7.2 (weakest: Innovation 6.0).
- Gear Grind: 6.8 (weakest: Innovation 5.8).
- Upper Case: 6.6 (weakest: Audio 6.0; T-0016 landed).
- Bit Catcher: 6.3, below the 6.5 ship bar (weakest: Graphics 5.8); T-0010, T-0011, T-0018 address it.
- Phase Shift, Cargo Shift, OVERFLOW: not yet reviewed.

## Next run should
1. **Lane A: build Night Watch** (Gameplay Engineer, from `games/nightwatch/DESIGN.md`; the draw code is the risk, plan says `watch_draw.gd`), QA verify against its 10-item checklist, ship as slot 7.
2. **Lane B:** T-0015 (Gear Grind GO moment), then T-0017 (touch hub), T-0020, T-0022, T-0019 docs.
3. Ask the Gameplay Engineer to confirm `difficulty >= 1` starts the ramp at 30 s in **uppercase** (the Platform Engineer couldn't find a `difficulty` reference there); OVERFLOW depends on it. Fold into T-0022 or a new task.
4. The next REVIEW is due at R0012 (first scores for Phase Shift, Cargo Shift and the OVERFLOW gauntlet).

## Needs Daniel
1. **GitHub is set up now (CI ran on ca18b3a), thanks.** Keep `./scripts/push_loop.sh` running in WSL; 5 new commits plus bookkeeping are waiting this run.
2. **Proposed change to `studio/procedure.md` rule 5 and step 0.7, and the CLAUDE.md "Commands" note** (unchanged since R0001): background jobs die when a device_bash call returns. Replace the rule with:
   > **Long commands.** `device_bash` calls time out at 180 s and background jobs are killed when the call returns. Run `check.sh` in the foreground with `timeout 170` (device_bash `timeout_ms: 180000`); when `all` would take longer, run `check.sh hub` and then `check.sh <slug>...` in batches across calls. Exports and downloads the same way, in steps.
3. **Optional: add the gauntlet to the gate.** `scripts/check.sh` could run `$GODOT --headless --path . --fixed-fps 60 --quit-after 4000 -- --gauntlet --autoplay` and assert `ARCADE gauntlet done` (a Daniel-owned file).
4. **Git leaves `tmp_obj_*` files** under `.git/objects` (the sandbox can't delete). Run `git gc` or `git prune` from WSL now and then.
5. A hands-on playtest with keys and touch would help: Cargo Shift's drag, Phase Shift's touch halves, Upper Case's Left/Right Shift in a real browser, and the OVERFLOW cell (clear all 6 games to unlock it).
