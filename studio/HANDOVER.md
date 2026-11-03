# Handover (after R0013, 2026-11-03 12:05 PT)
Phase: BUILD · Mode: BUILD (Lane B, four rounds) · Hub: 8 games (Shapeshifter, Gear Grind, Upper Case, Bit Catcher, Phase Shift, Cargo Shift, Night Watch, Red Shift) + OVERFLOW finale cell · Days to deadline: 28

## What this run did
Seven backlog tasks committed, each re-gated by the Producer and verified PASS by a QA Lead subagent:
- **T-0034 Phase Shift: parallax block rows** (ec26439): two block rows (0.3x/0.6x) fill y 200-520; current world filled, other outlined; 0.15 s swap. QA measured 59% fill coverage.
- **T-0033 Red Shift: two-finger touch** (48b3639): steering and pads by finger index; emulated mouse ignored; new headless check `res://games/redshift/touch_check.tscn` prints TOUCH CHECK OK.
- **T-0035 Night Watch: danger cues** (cdd67c4): pulsing BAD thumbnail outline from d 0.3 (~4 s) and a main-view edge bar from d 0.6.
- **T-0036 Cargo Shift: solid hull, separated crates** (0e4f018): sea drawn before hull, teal waterline stripe, display-only crate spread (8 px gap, selftested).
- **T-0030 Shared: gauntlet interstitial card** (0b1590e): 0.6 s sense-word card with slot flip and shift sound; slot clock holds at 8.0 until the game is playable (MicroGame `mark_playable()` / `in_intro` / `intro`); clear result card ripples the carry then OVERFLOW. Debug flag `--resultdemo`.
- **T-0037 Cargo Shift: early list** (40673f6): opening list torque (difficulty 0 only) so the ship tilts ~12 deg by 6 s; no capsize before 10 s (selftested).
- **T-0038 Red Shift: popup clamp** (73aad9e): kill popups spawn inside x 170-1090, label top >= 70.
- T-0039 Night Watch flash: already within the bible (hit flash INK a0.15 for 0.1 s); closed with no change.
- Filed T-0040..T-0043 (P2) from QA verify notes. INBOX empty; no GitHub issues need attention. No prompt drift.

## Build health
check.sh all: PASS (preflight and again after T-0030; per-game check.sh re-run after each later change) · registry: ok · CI: ok (d1d3e75) · push: pending (WSL loop; sandbox has no credentials)

## In flight / uncommitted
Nothing. Scratch only in git-ignored .tools/ (msg-t00xx.txt, qa/, shots, t6.gd).

## Scores (latest review, R0012)
- Collection: Overall 7.2 · Gameplay 6.7 · Graphics 7.1 · Audio 6.9 · Innovation 7.4 · Theme 8.4.
- Shapeshifter 7.2 · Gear Grind 7.0 · Upper Case 7.0 · Bit Catcher 6.9 · Night Watch 6.8 · Cargo Shift 6.7 · Phase Shift 6.6 (Graphics 6.0; T-0034 landed after scoring) · Red Shift 6.5 (Graphics 6.4) · OVERFLOW gauntlet 7.0 · Hub 7.6.

## Next run should
1. BUILD Lane B: Ready is now P1 T-0031 (blocked on the first web export) and P2s. Take two on different files: T-0041 (Night Watch cue strength) and T-0040 (Red Shift popup rise), then T-0042, T-0043, T-0025 -> T-0026.
2. Consider doing the first web export (`export_web.sh` in steps, `browser_check.mjs`) early to unblock T-0031 and catch web-only issues; no game is in progress, slots are full (8/8).
3. T-0028 still wants Daniel's call or a Creative Director decision.
4. Keep `check.sh all` in the foreground with `timeout 170` (~50 s). At most 2 Godot processes per device_bash call. Next review due at R0018.

## Needs Daniel
1. Keep `./scripts/push_loop.sh` running in WSL: 7 task commits plus R0013 bookkeeping are waiting.
2. **Proposed change to `studio/procedure.md` rule 5 / step 0.7 and the CLAUDE.md "Commands" note** (unchanged since R0001): background jobs die when a device_bash call returns. Replace with:
   > **Long commands.** `device_bash` calls time out at 180 s and background jobs are killed when the call returns. Run `check.sh` in the foreground with `timeout 170` (device_bash `timeout_ms: 180000`); when `all` would take longer, run `check.sh hub` and then `check.sh <slug>...` in batches across calls. Exports and downloads the same way, in steps.
3. Optional (`scripts/check.sh`, Daniel-owned): run per-game touch checks when present, e.g. after the selftest step: `[ -f games/$slug/touch_check.tscn ] && "$GODOT" --headless --path . res://games/$slug/touch_check.tscn | grep -q "TOUCH CHECK OK"`; and add the gauntlet (`--gauntlet --autoplay`, assert `ARCADE gauntlet done`).
4. Git leaves `tmp_obj_*` and `.lock` files under `.git`; run `git gc` / `git prune` from WSL now and then.
5. Optional decision for T-0028: should the dim locked OVERFLOW cell show before all 8 bits are set (a teaser), or stay hidden as VISION says? A one-line INBOX note settles it.
6. A hands-on phone playtest helps most: Red Shift's two-finger steering (T-0033 now in), Night Watch and Cargo Shift's opening list.
