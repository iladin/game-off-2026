# Backlog

Format: `- [T-####] P0|P1|P2 | role | game-or-area | title` with an indented `accept:` line (one or more testable criteria) and optional `source:` (review, INBOX, #issue).
P0 = broken or blocks the jam · P1 = clearly hurts a jam score · P2 = polish. The Producer keeps Ready sorted P0 → P2, then oldest first.
Next id: T-0010

## Ready
- [T-0007] P2 | qa-lead | geargrind+hub | Late-phase and real-save sweep
  accept: Gear Grind shots at frames 1500 and 2400 show the band-moving phase, fifth gear and the redline/blow feedback per the bibles (findings filed as tasks); the hub's real (non-demo) bit-set ceremony plays once after a first clear and does not replay after a reload (evidence: shots or logs).
  source: R0003 QA verify (T-0001, Gear Grind)
- [T-0003] P2 | platform-engineer | hub+shared | OVERFLOW finale: gold cell and additive Arcade gauntlet API (VISION 7, later #2)
  accept: when `hub_rules.overflow_unlocked()` is true a GOOD `OVERFLOW` cell appears after the last bit; it runs every hub game in slot order at `difficulty = 1` for 8 s each with 3 lives (`finish(_, false)` before 8 s costs a life), sums the score, records it under slug `overflow`, and shows one shared result card; existing Arcade/MicroGame APIs and `ARCADE` log lines unchanged; hub selftest covers the gauntlet bookkeeping; `./scripts/check.sh all` PASS. Staff only once at least 3 games are shipped.
  source: VISION.md section 7
- [T-0008] P2 | gameplay-engineer | uppercase | Hint glow spill and lower-case tile overlap
  accept: the Shift hint glow no longer washes over the bottom key row (clip to y >= 604 or lower alpha) in play-240/play-900; no tile (incl. lower-case) overlaps the top key row (cut off or clip by the tile's bottom edge, not its centre) in play-2400; game.gd brought toward the ~300-line target if it can be split cleanly (e.g. move bot/HUD into helpers); `./scripts/check.sh uppercase` PASS.
  source: R0004 QA verify (Upper Case)
- [T-0009] P2 | qa-lead | uppercase+geargrind | Unseen states: Upper Case banners, web Shift location, Gear Grind TOP label
  accept: shots show an Upper Case ramp banner (FASTER / LET LOWER PASS / NO HINTS / TOP SPEED) readable and clear of HUD; a frame of Gear Grind in top gear shows the moved TOP label clear of the needle; if a web build is available, note whether Left/Right Shift `location` is reported in Chromium (findings filed as tasks). Shoot 1-2 play frames per call (each ~25-30 s).
  source: R0004 QA verify (Upper Case, T-0006)

## In progress

## Done
<!-- - [T-####] ... · R#### · <sha> -->
- [T-0005] P2 | gameplay-engineer | shapeshifter | Hole readability at mid depth and wall depth tint · R0004 · 59494ce
- [T-0006] P2 | gameplay-engineer | geargrind | Layout fixes: lever label, TOP label, mini-map overlap, tach seams · R0004 · 62cb02c
- [T-0004] P2 | gameplay-engineer | shapeshifter | +N popup rises into the life squares · R0004 · 531c780
- [T-0001] P1 | platform-engineer | hub | Bit-set ceremony on first clear · R0003 · f543a00
- [T-0002] P2 | platform-engineer | hub | Concentric glow and readable empty-state outlines · R0003 · 58b38a6
