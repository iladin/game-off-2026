# Handover (after R0011, 2026-11-03 09:40 PT)
Phase: BUILD · Mode: BUILD (Lane B, three rounds) · Hub: 8 games (Shapeshifter, Gear Grind, Upper Case, Bit Catcher, Phase Shift, Cargo Shift, Night Watch, Red Shift) + OVERFLOW finale cell · Days to deadline: 28

## What this run did
- **Took over R0010's stale lock** (since 15:08Z, 2 h at 17:08Z). R0010 had committed T-0017, T-0020, T-0023, T-0024 (6714a20..20d16c5) but never wrapped up; R0011 recorded them as Done and logged an R0010 line. The skipped R---- line from 16:07Z stays in LOG.
- **T-0019 docs catch-up** (e817a92): Phase Shift, Shapeshifter, Bit Catcher DESIGN.md match the code (measured Phase Shift bot score 1,730-2,040, mean ~1,870; Bit Catcher banner is at y 56, not 262).
- **QA sweeps T-0007, T-0009, T-0021** (no code): hub bit-set ceremony persists `seen_cleared` and doesn't replay (PASS); Upper Case banners, Gear Grind TOP label, Cargo Shift STORM / difficulty-1 start, the 9-cell OVERFLOW hub and the lost-life square all PASS. Gear Grind fifth gear, redline and BLOWN are unreachable by the bot (filed T-0025, T-0026). Web Shift `location` UNVERIFIED (no web build; T-0031).
- **T-0027 Shared: gauntlet HUD** (e8d83dc): status and gold lives moved to the left gutter with a RUN LIVES caption; QA verify PASS on Upper Case, Cargo Shift and Red Shift gauntlet shots.
- **T-0029 Upper Case: banner panel** (f1c487b): ramp banners sit on an opaque panel above fresh tiles; QA verify PASS on all four banners.
- Filed T-0025 (late-round QA flag), T-0026 (Gear Grind late-state shots), T-0028 (OVERFLOW teaser cell vs VISION), T-0030 (gauntlet timer vs intros), T-0031 (web Shift location). INBOX empty; no issues.

## Build health
check.sh all: PASS (52 s at preflight, and again after the commits) · registry: ok · CI: ok (20d16c5, so the WSL loop published R0010's work) · push: pending (WSL loop; sandbox has no credentials)

## In flight / uncommitted
Nothing. Stray scratch files in git-ignored .tools/ (tmp/sc.gd, qa-r0011/, shots) only.

## Scores (latest review, R0006; many fixes landed since)
- Collection: 6.6 (weakest: Audio 6.3).
- Shapeshifter 7.2 (Innovation 6.0) · Gear Grind 6.8 (Innovation 5.8) · Upper Case 6.6 (Audio 6.0) · Bit Catcher 6.3 (Graphics 5.8).
- Phase Shift, Cargo Shift, Night Watch, Red Shift, OVERFLOW: not yet reviewed.

## Next run should
1. **REVIEW is due at R0012** (12 - 6 >= 6): Jam Critic + QA sweep, first scores for Phase Shift, Cargo Shift, Night Watch, Red Shift and OVERFLOW. Then one Lane B task if >= 20 min remain.
2. Lane B after that: T-0028 (Creative Director decision on the OVERFLOW teaser cell; quick), T-0025 (Platform: late-round QA flag) then T-0026, T-0030.
3. T-0031 waits for the first web export (POLISH/RELEASE).
4. Keep `check.sh all` in the foreground with `timeout 170` (52 s now). Run at most 2 Godot shot processes per device_bash call (3-4 in parallel time out).

## Needs Daniel
1. Keep `./scripts/push_loop.sh` running in WSL: 3 task commits plus bookkeeping are waiting.
2. **Proposed change to `studio/procedure.md` rule 5 / step 0.7 and the CLAUDE.md "Commands" note** (unchanged since R0001): background jobs die when a device_bash call returns. Replace with:
   > **Long commands.** `device_bash` calls time out at 180 s and background jobs are killed when the call returns. Run `check.sh` in the foreground with `timeout 170` (device_bash `timeout_ms: 180000`); when `all` would take longer, run `check.sh hub` and then `check.sh <slug>...` in batches across calls. Exports and downloads the same way, in steps.
3. **Optional: add the gauntlet to the gate** (`--gauntlet --autoplay`, assert `ARCADE gauntlet done`).
4. Git leaves `tmp_obj_*` and `.lock` files under `.git`; run `git gc` / `git prune` from WSL now and then.
5. Optional decision for T-0028: should the dim locked OVERFLOW cell show before all 8 bits are set (a teaser), or stay hidden as VISION says? A one-line INBOX note settles it.
6. A hands-on playtest still helps most: touch play of Night Watch, Red Shift, Cargo Shift's drag, and Upper Case's Left/Right Shift in a real browser.
