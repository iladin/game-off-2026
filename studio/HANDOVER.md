# Handover (after R0009, 2026-11-03 07:40 PT)
Phase: BUILD · Mode: BUILD (Lane A + Lane B, two rounds) · Hub: 8 games (Shapeshifter, Gear Grind, Upper Case, Bit Catcher, Phase Shift, Cargo Shift, Night Watch, Red Shift) + OVERFLOW finale cell · Days to deadline: 28

## What this run did
- **Shipped Night Watch** (b2a7fcd, slot 7): three camera feeds; the creeper in any feed you are not watching advances; flash the watched feed to send it back. Built by the Gameplay Engineer from DESIGN.md (rules.gd / game.gd / watch_draw.gd). QA verify SHIP: 10/10 checklist and the ship bar; P2 nits filed as T-0023.
- **Designed and shipped Red Shift** (8cfe2b9 design, 833b540 game, slot 8): hue is speed (brake ember, cruise lime, boost blue); auto-fire only hurts matching-hue enemies; survive 50 s. Game Designer (Opus) scoped it small (fixed-x ship, straight-line enemies, 3 bands) with a Python balance model; Gameplay Engineer built it; QA verify SHIP 10/10. Heavies not yet seen in a shot: T-0024.
- **The slate is complete: all 8 VISION slots are shipped.** `--gauntlet --autoplay` clears all 8 (`ARCADE gauntlet done score=1429 won=true`).
- **T-0015 Gear Grind** (9f69a32): GO moment (white then GOOD lights, 56 px GO banner, lever pulse) and the SPACE OR TAP cue stays until the first shift. QA PASS.
- **T-0022 Upper Case + Bit Catcher** (4efc29a): F/J label margin, phase banner clamped to x 170-1090. Also confirmed Upper Case already honours `difficulty >= 1` (rules.gd:49, selftest.gd:28), closing R0008's open question. QA PASS.
- Filed T-0023, T-0024. INBOX empty; no issues need attention.

## Build health
check.sh all: PASS at preflight (43 s, foreground); after the changes check.sh hub (8 games) and nightwatch, geargrind, uppercase, bitcatcher, redshift PASS individually · registry: ok · CI: ok at preflight (3dcf8a5) · push: pending (WSL loop; sandbox push failed for lack of credentials, as expected)

## In flight / uncommitted
Nothing.

## Scores (latest review, R0006; many fixes landed since)
- Collection: 6.6 (weakest: Audio 6.3).
- Shapeshifter: 7.2 (weakest: Innovation 6.0).
- Gear Grind: 6.8 (weakest: Innovation 5.8).
- Upper Case: 6.6 (weakest: Audio 6.0).
- Bit Catcher: 6.3, below the 6.5 ship bar (weakest: Graphics 5.8); T-0010, T-0011, T-0018, T-0022 address it.
- Phase Shift, Cargo Shift, Night Watch, Red Shift, OVERFLOW: not yet reviewed.

## Next run should
1. **No Lane A left** (8 of 8 slots shipped). Per the procedure, BUILD Lane B takes the top two Ready tasks touching different files: T-0017 (touch hub, Platform Engineer) and T-0020 (Cargo Shift RODE IT popup), then T-0023, T-0024, T-0019, and the QA sweeps T-0007, T-0009, T-0021.
2. The next REVIEW is due at R0012 (run_counter - last_review_run >= 6). It will give first scores for Phase Shift, Cargo Shift, Night Watch, Red Shift and the OVERFLOW gauntlet; four unreviewed games is a lot, so if Ready runs thin before then, take the IDLE rule's early review.
3. Keep `check.sh all` in the foreground with `timeout 170` (43 s with 8 games + template).

## Needs Daniel
1. Keep `./scripts/push_loop.sh` running in WSL: 5 game commits plus bookkeeping are waiting this run.
2. **Proposed change to `studio/procedure.md` rule 5 and step 0.7, and the CLAUDE.md "Commands" note** (unchanged since R0001): background jobs die when a device_bash call returns. Replace the rule with:
   > **Long commands.** `device_bash` calls time out at 180 s and background jobs are killed when the call returns. Run `check.sh` in the foreground with `timeout 170` (device_bash `timeout_ms: 180000`); when `all` would take longer, run `check.sh hub` and then `check.sh <slug>...` in batches across calls. Exports and downloads the same way, in steps.
3. **Optional: add the gauntlet to the gate.** `scripts/check.sh` could run `$GODOT --headless --path . --fixed-fps 60 --quit-after 4500 -- --gauntlet --autoplay` and assert `ARCADE gauntlet done` (now 8 games, about 4,300 frames).
4. **Git leaves `tmp_obj_*` and `.lock` files** under `.git` (the sandbox can't delete). Run `git gc` or `git prune` from WSL now and then.
5. A hands-on playtest would help most now that the full slate is in: Night Watch and Red Shift by touch, Cargo Shift's drag, Phase Shift's touch halves, Upper Case's Left/Right Shift in a real browser, and the OVERFLOW cell (clear all 8 to unlock it).
