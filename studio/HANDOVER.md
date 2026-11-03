# Handover (after R0015, 2026-11-03 13:37 PT)
Phase: BUILD · Mode: BUILD (Lane B, three rounds) · Hub: 8 games (Shapeshifter, Gear Grind, Upper Case, Bit Catcher, Phase Shift, Cargo Shift, Night Watch, Red Shift) + OVERFLOW finale cell · Days to deadline: 28

## What this run did
Six backlog tasks committed. For each one the Producer re-ran `check.sh <slug>` and a QA Lead subagent verified it PASS with screenshots:
- **T-0044 Gear Grind: `--sloppy` QA bot flag** (c186968). Desktop + autoplay only. The bot shifts late in heat 1 and never from heat 2, so `SHIFT_QA="--rstart=40 --sloppy" ./scripts/shots.sh geargrind 840 900` shows the red zone (840) and BLOWN (900). The no-flag path is unchanged. This unblocks T-0026.
- **T-0047 Cargo Shift: waterline on the wave, submerged tint** (0773842). One `R.SEA_Y` (470) is used by both the sea and the hull clip. `R.sea_offset` keeps the swell calm under the hull. The clip math moved to pure helpers in rules.gd and the selftest covers it. The hull below the sea gets an ACCENT tint at alpha 0.22.
- **T-0046 Night Watch: thumbnail eyes stay inside the danger outline** (d2d0416). The main-view bar stays at d > 0.6 (~8 s), as documented in DESIGN.md.
- **T-0048 Red Shift: brighter kill popups** (107639f). A game-side `_popup` holds GOOD at full alpha until 0.55 s, at 36 px with an opaque outline. The T-0040 HUD clamp is kept, and the selftest ties the constants to Juice's rise.
- **T-0045 Gear Grind: rival gap label** (119b8c4). The label is drawn in INK (not BAD) between the two cars.
- **T-0049 Cargo Shift: livelier sea at the hull edges + DESIGN.md catch-up** (64e2807). It was filed and done in this run.
- Filed T-0050..T-0054 (P2) from the QA notes and added a status note to T-0026. INBOX was empty, there were no GitHub issues, and there was no prompt drift.

## Build health
check.sh all: PASS (at preflight and after all six commits) · registry: ok · CI: ok (54e348b) · push: pending (WSL loop; sandbox has no credentials)

## In flight / uncommitted
Nothing. Scratch only, in git-ignored `.tools/`: shots, `msg-t00xx.txt`, QA copies (`keep.png`, `qa-slop900.png`, `sl-*/ns-*`), plus the R0014 leftovers `build/web`, `.tools/tpl/tpl.tpz` and `.tools/pw`.

## Scores (latest review, R0012)
- Collection: Overall 7.2 · Gameplay 6.7 · Graphics 7.1 · Audio 6.9 · Innovation 7.4 · Theme 8.4.
- Shapeshifter 7.2 · Gear Grind 7.0 · Upper Case 7.0 · Bit Catcher 6.9 · Night Watch 6.8 · Cargo Shift 6.7 · Phase Shift 6.6 (Graphics 6.0) · Red Shift 6.5 (Graphics 6.4) · OVERFLOW gauntlet 7.0 · Hub 7.6.

## Next run should
1. BUILD Lane B, two tasks on different files. Take T-0051 (Gear Grind BLOWN aftermath, TOP in the dial) together with T-0052 (Red Shift popup stagger) or T-0054 (Night Watch eyes). After those: T-0050, T-0053, then the rest of T-0026 (FIFTH GEAR / HEAT banners).
2. Gear Grind tasks clash on `games/geargrind/`, so don't pair T-0051 with T-0053.
3. Run `check.sh all` in the foreground with `timeout 170` (~50 s). A REVIEW (Jam Critic + QA sweep) is due at R0018.
4. Phase Shift (Graphics 6.0) and Red Shift (6.5, at ship_bar) are the weakest scores. If Ready runs dry before R0018, consider an early review.
5. T-0031 is still blocked on Needs Daniel #1. T-0028 still needs Daniel's call (#6) or a Creative Director decision.

## Needs Daniel
1. **Web browser check (T-0031, P1).** No headless Chromium is reachable here, so pick one of these:
   - (a) allowlist `cdn.playwright.dev` so `npx playwright install chromium` works;
   - (b) install chromium on the machine/VM;
   - (c) approve running the npm package `@sparticuz/chromium` that is already in `.tools/pw`;
   - (d) run `scripts/browser_check.mjs` in CI.
   
   A one-line INBOX note settles it. The F/J fallback keys already work and are labelled on the web either way.
2. Keep `./scripts/push_loop.sh` running in WSL. CI ran green on 54e348b (R0014), so the loop is publishing; R0015 adds 6 task commits plus bookkeeping.
3. **Proposed change to `studio/procedure.md` rule 5 / step 0.7 and the CLAUDE.md "Commands" note** (unchanged since R0001). Background jobs die when a device_bash call returns. Replace the text with:
   > **Long commands.** `device_bash` calls time out at 180 s and background jobs are killed when the call returns. Run `check.sh` in the foreground with `timeout 170` (device_bash `timeout_ms: 180000`); when `all` would take longer, run `check.sh hub` and then `check.sh <slug>...` in batches across calls. Exports and downloads the same way, in steps.
4. Optional changes to `scripts/` (Daniel-owned):
   - `check.sh hub`: also run `res://hub/selftest.gd` (it isn't in the gate today); run per-game `touch_check.tscn` when present; add a gauntlet run.
   - `shots.sh`: document `SHIFT_QA` / `--rstart` and add a gauntlet card shot.
5. Git leaves `tmp_obj_*` and `.lock` files under `.git`. Run `git gc` / `git prune` from WSL now and then. You can also delete `.tools/tpl/tpl.tpz` (1.28 GB).
6. Optional decision for T-0028: should the dim locked OVERFLOW cell show before all 8 bits are set (a teaser), or stay hidden as VISION says?
