# Handover (after R0017, 2026-11-03 15:40 PT)
Phase: BUILD · Mode: BUILD (Lane B, three rounds) · Hub: 8 games (Shapeshifter, Gear Grind, Upper Case, Bit Catcher, Phase Shift, Cargo Shift, Night Watch, Red Shift) + OVERFLOW finale cell · Days to deadline: 28

## What this run did
Five backlog tasks committed. For each one the Producer re-ran `check.sh <slug>` and a QA Lead subagent verified it with screenshots:
- **T-0058 Red Shift: DODGE holds full INK at the crash point** (9b67e65). New pure `Rules.dodge_pos` and `popup_alpha`; hold 0.7 s, life 1.1 s. QA caught DODGE deterministically with `--seed=4 --shotframes=470`.
- **T-0056 Gear Grind: popups pick a free y clear of the tach** (ba3f475). The first try (slots 430/470/510) FAILED QA: the slot wrap 2->0 put two live popups ~14 px apart at frame 820. After one fix round, fixed slots are replaced by `Rules.popup_pick_y(live)` (births 425..505, then up to 300; >= 40 px from every live popup for life; skip label if none fits). QA re-verify: all pairs >= 40 px at 790..830, lowest label bottom ~485 vs arc 520.
- **T-0059 Night Watch: `--nwqa-hold` QA flag** (fa85817). Caps d at 0.92 on unwatched awake feeds; QA saw 19 px thumb eyes inside the outline at frame 1250 (vs 9 px at 290).
- **T-0057 Gear Grind: LEVEL label on a panel clear of the checker** (8674834). In `strip_draw.gd draw_gap()`.
- **T-0060 Red Shift: popup fade driven by `Rules.popup_alpha`; DODGE recipe in DESIGN.md** (bd3354d). Filed and done this run from the T-0058 QA.
- Filed T-0061..T-0063 (P2). INBOX was empty, no GitHub issues, no prompt drift.

## Build health
check.sh all: PASS (at preflight and after all five commits) · registry: ok · CI: ok (c4c8dc6) · push: pending (WSL loop; sandbox has no credentials)

## In flight / uncommitted
Nothing. Scratch only, in git-ignored `.tools/`: QA copies `qa17-*`, `shots-nw17/`, `shots-rs17/`, `qa17-rs/sim.gd` (a headless sim that finds the first idle Red Shift crash per seed), `msg-t00xx.txt`, plus older leftovers listed before (`build/web`, `.tools/tpl/tpl.tpz`, `.tools/pw`, stray `qa-r16-gg-sl*`).

## Scores (latest review, R0012)
- Collection: Overall 7.2 · Gameplay 6.7 · Graphics 7.1 · Audio 6.9 · Innovation 7.4 · Theme 8.4.
- Shapeshifter 7.2 · Gear Grind 7.0 · Upper Case 7.0 · Bit Catcher 6.9 · Night Watch 6.8 · Cargo Shift 6.7 · Phase Shift 6.6 (Graphics 6.0) · Red Shift 6.5 (Graphics 6.4) · OVERFLOW gauntlet 7.0 · Hub 7.6.

## Next run should
1. **REVIEW is due at R0018** (`last_review_run` 12, `review_every` 6): Jam Critic (opus) + QA Lead sweep (sonnet) in parallel -> `studio/reviews/R0018.md`, then turn the top findings into BACKLOG. The backlog is all small P2 polish; the Critic should point at the weakest games (Phase Shift Graphics 6.0, Red Shift 6.5 at ship_bar) and bigger P1s.
2. Then, if >= 20 min remain, one Lane B task: T-0061 (Gear Grind popups vs RIVAL label). T-0061 and T-0062 both touch geargrind, so don't pair them; T-0063 (nightwatch) can go alongside.
3. QA tips: `--shotframes` takes ONE frame per run; parallel godot shot runs can write nothing. Red Shift DODGE: `--seed=4` idle, frame 470 (in DESIGN.md). Night Watch high danger: `--nwqa-hold` frame 1250 (add `--nwqa` to isolate CAM 3). Gear Grind late round: `SHIFT_QA="--rstart=40"` (plus `--sloppy` for redline/BLOWN).
4. Run `check.sh all` in the foreground with `timeout 170` (~50 s). Background jobs die when a device_bash call returns.
5. T-0031 is still blocked on Needs Daniel #1. T-0028 still needs Daniel's call (#6) or a Creative Director decision; T-0026 has the FIFTH GEAR / HEAT banners left.

## Needs Daniel
1. **Web browser check (T-0031, P1).** No headless Chromium is reachable here, so pick one of these:
   - (a) allowlist `cdn.playwright.dev` so `npx playwright install chromium` works;
   - (b) install chromium on the machine/VM;
   - (c) approve running the npm package `@sparticuz/chromium` that is already in `.tools/pw`;
   - (d) run `scripts/browser_check.mjs` in CI.
   
   A one-line INBOX note settles it. The F/J fallback keys already work and are labelled on the web either way.
2. Keep `./scripts/push_loop.sh` running in WSL. CI ran green on d890881 (R0015), so the loop is publishing; R0016 and R0017 add 11 task commits plus bookkeeping.
3. **Proposed change to `studio/procedure.md` rule 5 / step 0.7 and the CLAUDE.md "Commands" note** (unchanged since R0001). Background jobs die when a device_bash call returns. Replace the text with:
   > **Long commands.** `device_bash` calls time out at 180 s and background jobs are killed when the call returns. Run `check.sh` in the foreground with `timeout 170` (device_bash `timeout_ms: 180000`); when `all` would take longer, run `check.sh hub` and then `check.sh <slug>...` in batches across calls. Exports and downloads the same way, in steps.
4. Optional changes to `scripts/` (Daniel-owned):
   - `check.sh hub`: also run `res://hub/selftest.gd` (it isn't in the gate today); run per-game `touch_check.tscn` when present; add a gauntlet run.
   - `shots.sh`: document `SHIFT_QA` / `--rstart` and add a gauntlet card shot.
5. Git leaves `tmp_obj_*` and `.lock` files under `.git`. Run `git gc` / `git prune` from WSL now and then. You can also delete `.tools/tpl/tpl.tpz` (1.28 GB).
6. Optional decision for T-0028: should the dim locked OVERFLOW cell show before all 8 bits are set (a teaser), or stay hidden as VISION says?
