# Backlog

Format: `- [T-####] P0|P1|P2 | role | game-or-area | title` with an indented `accept:` line (one or more testable criteria) and optional `source:` (review, INBOX, #issue).
P0 = broken or blocks the jam · P1 = clearly hurts a jam score · P2 = polish. The Producer keeps Ready sorted P0 → P2, then oldest first.
Next id: T-0019

## Ready
- [T-0011] P1 | gameplay-engineer | bitcatcher | Progress squares, landing lane, calmer byte flash
  accept: the `11110000`-style progress digit string is replaced by 8 drawn squares (play-900 has no unlabelled digit string); a 2 px lane line runs from the falling bit to its landing cell with a ghost outline on that cell; on byte complete the background stays BG/PANEL and only the cells flash (white at most alpha 0.15), digits stay readable (play-1500); `./scripts/check.sh bitcatcher` PASS.
  source: review R0006 (critic fix 3, QA 3)
- [T-0012] P1 | gameplay-engineer | uppercase | Shift hint glow stays on its own key
  accept: the hint glow is drawn as fixed insets (about +10 and +22 px) around the hinted Shift key only; in play-240 and play-900 no glow pixels lie under the other Shift key or more than 24 px past the hinted key's edge; `./scripts/check.sh uppercase` PASS.
  source: review R0006 (critic fix 1, QA 4); the 0ef5096 clip was vertical only
- [T-0013] P1 | gameplay-engineer | shapeshifter | Steady crash warning
  accept: when the player's shape doesn't match the hole and the wall is past p 0.75, the hole outline is a steady 6 px BAD line (no 4 Hz off phase) and the correct shape button glows; the hole outline at normal times is INK or BAD at 4 px or more; a forced-mismatch shot (or two consecutive frames) shows both; `./scripts/check.sh shapeshifter` PASS.
  source: review R0006 (critic fix 4, QA 9)
- [T-0014] P1 | gameplay-engineer | geargrind | Show speed and the race
  accept: roadside posts and a slower background row scroll with speed (post positions differ by at least 40 px between play-240 and play-270); a marker shows the gap to the rival (ahead/behind, visible in play-900); everything stays within y 704; `./scripts/check.sh geargrind` PASS.
  source: review R0006 (critic fix 5, QA 8)
- [T-0015] P2 | gameplay-engineer | geargrind | GO moment and lasting tap cue
  accept: at the end of staging the lights flash white then GOOD, a 56 px `GO` banner shows and the lever pulses (a shot at staging t about 1.7 s shows them); the `SPACE OR TAP` cue stays until the first successful shift; `./scripts/check.sh geargrind` PASS.
  source: review R0006 (critic fix 6, QA 8)
- [T-0018] P2 | gameplay-engineer | bitcatcher | Phase banner off the fall zone; DESIGN.md catch-up
  accept: the phase banner no longer draws over the falling bit or its lane (draw it under the bit, or place it clear of y 180-440 and the target row); DESIGN.md matches the T-0010 look (lime 1 cells, target row, FIRST_SPAWN 0.1, banner position); a shot at a phase change shows the banner and the falling bit both readable; `./scripts/check.sh bitcatcher` PASS.
  source: R0006 QA verify (T-0010)
- [T-0016] P2 | audio-designer | uppercase | Custom tones and readable key labels
  accept: two `Synth.tone` sounds (a typewriter clack on a hit, a ding on each phase banner) exist in games/uppercase and follow the audio bible volumes; the F/J key labels are 28 px or larger; `./scripts/check.sh uppercase` PASS.
  source: review R0006 (critic fix 7, QA 5)
- [T-0017] P2 | platform-engineer | hub | Touch-friendly hub
  accept: the PLAY button is at least 96 px tall (or the whole info panel launches); after a touch input the footer reads touch wording (e.g. `TAP A BIT   TAP PLAY`), keyboard wording otherwise; hub selftest and `./scripts/check.sh hub` PASS.
  source: review R0006 (QA 6, 7)
- [T-0007] P2 | qa-lead | geargrind+hub | Late-phase and real-save sweep
  accept: Gear Grind shots at frames 1500 and 2400 show the band-moving phase, fifth gear and the redline/blow feedback per the bibles (findings filed as tasks); the hub's real (non-demo) bit-set ceremony plays once after a first clear and does not replay after a reload (evidence: shots or logs).
  source: R0003 QA verify (T-0001, Gear Grind)
- [T-0003] P2 | platform-engineer | hub+shared | OVERFLOW finale: gold cell and additive Arcade gauntlet API (VISION 7, later #2)
  accept: when `hub_rules.overflow_unlocked()` is true a GOOD `OVERFLOW` cell appears after the last bit; it runs every hub game in slot order at `difficulty = 1` for 8 s each with 3 lives (`finish(_, false)` before 8 s costs a life), sums the score, records it under slug `overflow`, and shows one shared result card; existing Arcade/MicroGame APIs and `ARCADE` log lines unchanged; hub selftest covers the gauntlet bookkeeping; `./scripts/check.sh all` PASS. Staff only once at least 3 games are shipped. Review R0006 (critic fix 8): until it unlocks, show a dim locked `OVERFLOW` cell so voters see the finale exists.
  source: VISION.md section 7
- [T-0009] P2 | qa-lead | uppercase+geargrind | Unseen states: Upper Case banners, web Shift location, Gear Grind TOP label
  accept: shots show an Upper Case ramp banner (FASTER / LET LOWER PASS / NO HINTS / TOP SPEED) readable and clear of HUD; a frame of Gear Grind in top gear shows the moved TOP label clear of the needle; if a web build is available, note whether Left/Right Shift `location` is reported in Chromium (findings filed as tasks). Shoot 1-2 play frames per call (each ~25-30 s).
  source: R0004 QA verify (Upper Case, T-0006)

## In progress

## Done
<!-- - [T-####] ... · R#### · <sha> -->
- [T-0010] P1 | gameplay-engineer | bitcatcher | Make the register and target readable in the first 10 s · R0006 · 58b0db9
- [T-0008] P2 | gameplay-engineer | uppercase | Hint glow spill and lower-case tile overlap · R0005 · 0ef5096
- [T-0005] P2 | gameplay-engineer | shapeshifter | Hole readability at mid depth and wall depth tint · R0004 · 59494ce
- [T-0006] P2 | gameplay-engineer | geargrind | Layout fixes: lever label, TOP label, mini-map overlap, tach seams · R0004 · 62cb02c
- [T-0004] P2 | gameplay-engineer | shapeshifter | +N popup rises into the life squares · R0004 · 531c780
- [T-0001] P1 | platform-engineer | hub | Bit-set ceremony on first clear · R0003 · f543a00
- [T-0002] P2 | platform-engineer | hub | Concentric glow and readable empty-state outlines · R0003 · 58b38a6
