# Handover (after R0016, 2026-11-03 14:41 PT)
Phase: BUILD · Mode: BUILD (Lane B, three rounds) · Hub: 8 games (Shapeshifter, Gear Grind, Upper Case, Bit Catcher, Phase Shift, Cargo Shift, Night Watch, Red Shift) + OVERFLOW finale cell · Days to deadline: 28

## What this run did
Six backlog tasks committed. For each one the Producer re-ran `check.sh <slug>` and a QA Lead subagent verified it with screenshots:
- **T-0051 Gear Grind: dead engine after BLOWN; TOP inside the dial** (6b21645). The car goes DIM with smoke through the result beat, and the red zone reads inactive in top gear.
- **T-0052 Red Shift: close-kill popup stagger; DODGE in INK** (8719e64). New pure `R.stagger_pos`, applied after the T-0040 HUD clamp.
- **T-0054 Night Watch: thumbnail eyes show approach** (9a107f2). `thumb_eye_pose(rc, d)` grows size, spacing and alpha with d and stays inside the outline (QA: ~5 px eyes at d 0.3 vs ~9 px at d 0.6).
- **T-0050 Cargo Shift: DESIGN.md sea numbers** (36ca573). Docs only; it fixes the wrong "half size at x 330/950".
- **T-0055 Red Shift: stagger from the risen position** (1618e81). Filed from the T-0052 QA. The pair went from ~26 px to ~67 px apart, with the drop capped above the pads.
- **T-0053 Gear Grind: shift popup slots + distinct inactive red zone** (68b7647). The first QA round FAILED: the popups overlapped because age was measured with the wall clock. After one fix round (game `elapsed` clock, 3 fixed slots) QA passed, and the Producer's own frames 800/820 show both popups live and separated.
- Filed T-0056..T-0059 (P2). INBOX was empty, there were no GitHub issues, and there was no prompt drift.

## Build health
check.sh all: PASS (at preflight and after all six commits) · registry: ok · CI: ok (d890881) · push: pending (WSL loop; sandbox has no credentials)

## In flight / uncommitted
Nothing. Scratch only, in git-ignored `.tools/`: shots, `msg-t00xx.txt`, QA copies (`qa16*/`, `qa-r16-*`; ~50 stray stale `qa-r16-gg-sl*` copies from a QA slip, safe to delete), plus the R0014 leftovers `build/web`, `.tools/tpl/tpl.tpz` and `.tools/pw`.

## Scores (latest review, R0012)
- Collection: Overall 7.2 · Gameplay 6.7 · Graphics 7.1 · Audio 6.9 · Innovation 7.4 · Theme 8.4.
- Shapeshifter 7.2 · Gear Grind 7.0 · Upper Case 7.0 · Bit Catcher 6.9 · Night Watch 6.8 · Cargo Shift 6.7 · Phase Shift 6.6 (Graphics 6.0) · Red Shift 6.5 (Graphics 6.4) · OVERFLOW gauntlet 7.0 · Hub 7.6.

## Next run should
1. BUILD Lane B: T-0056 (Gear Grind popup slots over the tach) with T-0058 (Red Shift DODGE) in parallel. T-0056 and T-0057 both touch `games/geargrind/`, so don't pair them.
2. Then T-0057, T-0059, and the rest of T-0026 (FIFTH GEAR / HEAT banners).
3. A REVIEW (Jam Critic + QA sweep) is due at R0018 (`last_review_run` 12, `review_every` 6). Ready is thin and the backlog is all small P2 juice; consider pulling the review forward to R0017 so the Critic can point at the weakest games (Phase Shift Graphics 6.0, Red Shift 6.5 at ship_bar).
4. QA tips: `--shotframes` takes ONE frame (a comma list writes nothing). Red Shift DODGE comes from an idle no-autoplay crash, which is not deterministic (seen at 660, not at 300..600). Night Watch idle without flags leaves CAM 2 unwatched (thumb eyes at frames 290/540).
5. Run `check.sh all` in the foreground with `timeout 170` (~50 s).
6. T-0031 is still blocked on Needs Daniel #1. T-0028 still needs Daniel's call (#6) or a Creative Director decision.

## Needs Daniel
1. **Web browser check (T-0031, P1).** No headless Chromium is reachable here, so pick one of these:
   - (a) allowlist `cdn.playwright.dev` so `npx playwright install chromium` works;
   - (b) install chromium on the machine/VM;
   - (c) approve running the npm package `@sparticuz/chromium` that is already in `.tools/pw`;
   - (d) run `scripts/browser_check.mjs` in CI.
   
   A one-line INBOX note settles it. The F/J fallback keys already work and are labelled on the web either way.
2. Keep `./scripts/push_loop.sh` running in WSL. CI ran green on d890881 (R0015), so the loop is publishing; R0016 adds 6 task commits plus bookkeeping.
3. **Proposed change to `studio/procedure.md` rule 5 / step 0.7 and the CLAUDE.md "Commands" note** (unchanged since R0001). Background jobs die when a device_bash call returns. Replace the text with:
   > **Long commands.** `device_bash` calls time out at 180 s and background jobs are killed when the call returns. Run `check.sh` in the foreground with `timeout 170` (device_bash `timeout_ms: 180000`); when `all` would take longer, run `check.sh hub` and then `check.sh <slug>...` in batches across calls. Exports and downloads the same way, in steps.
4. Optional changes to `scripts/` (Daniel-owned):
   - `check.sh hub`: also run `res://hub/selftest.gd` (it isn't in the gate today); run per-game `touch_check.tscn` when present; add a gauntlet run.
   - `shots.sh`: document `SHIFT_QA` / `--rstart` and add a gauntlet card shot.
5. Git leaves `tmp_obj_*` and `.lock` files under `.git`. Run `git gc` / `git prune` from WSL now and then. You can also delete `.tools/tpl/tpl.tpz` (1.28 GB).
6. Optional decision for T-0028: should the dim locked OVERFLOW cell show before all 8 bits are set (a teaser), or stay hidden as VISION says?
