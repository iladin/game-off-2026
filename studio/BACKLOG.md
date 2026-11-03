# Backlog

Format: `- [T-####] P0|P1|P2 | role | game-or-area | title` with an indented `accept:` line (one or more testable criteria) and optional `source:` (review, INBOX, #issue).
P0 = broken or blocks the jam · P1 = clearly hurts a jam score · P2 = polish. The Producer keeps Ready sorted P0 → P2, then oldest first.
Next id: T-0008

## Ready
- [T-0004] P2 | gameplay-engineer | shapeshifter | +N popup rises into the life squares
  accept: in shots at frames 240, 600 and 900 no `+N` popup overlaps the HUD band y 60 to 110 (spawn at y >= 200 or clamp the rise); `./scripts/check.sh shapeshifter` PASS.
  source: R0003 QA verify
- [T-0005] P2 | gameplay-engineer | shapeshifter | Hole readability at mid depth and wall depth tint
  accept: at mid depth the hole reads as a gap (BG fill inside the hole or a thicker outline), and farther walls are tinted darker than nearer ones; shots play-450 and play-900 show both; palette only; `./scripts/check.sh shapeshifter` PASS.
  source: R0003 QA verify
- [T-0006] P2 | gameplay-engineer | geargrind | Layout fixes: lever label, TOP label, mini-map overlap, tach seams
  accept: `SPACE OR TAP` sits fully inside the lever box or below it with >= 4 px clearance; the `TOP` label never overlaps the needle path; the rival mini-map square stays visible when overlapped (outline or offset y); tach band arcs show no visible segment steps in `start.png`; `./scripts/check.sh geargrind` PASS.
  source: R0003 QA verify
- [T-0007] P2 | qa-lead | geargrind+hub | Late-phase and real-save sweep
  accept: Gear Grind shots at frames 1500 and 2400 show the band-moving phase, fifth gear and the redline/blow feedback per the bibles (findings filed as tasks); the hub's real (non-demo) bit-set ceremony plays once after a first clear and does not replay after a reload (evidence: shots or logs).
  source: R0003 QA verify (T-0001, Gear Grind)
- [T-0003] P2 | platform-engineer | hub+shared | OVERFLOW finale: gold cell and additive Arcade gauntlet API (VISION 7, later #2)
  accept: when `hub_rules.overflow_unlocked()` is true a GOOD `OVERFLOW` cell appears after the last bit; it runs every hub game in slot order at `difficulty = 1` for 8 s each with 3 lives (`finish(_, false)` before 8 s costs a life), sums the score, records it under slug `overflow`, and shows one shared result card; existing Arcade/MicroGame APIs and `ARCADE` log lines unchanged; hub selftest covers the gauntlet bookkeeping; `./scripts/check.sh all` PASS. Staff only once at least 3 games are shipped.
  source: VISION.md section 7

## In progress

## Done
<!-- - [T-####] ... · R#### · <sha> -->
- [T-0001] P1 | platform-engineer | hub | Bit-set ceremony on first clear · R0003 · f543a00
- [T-0002] P2 | platform-engineer | hub | Concentric glow and readable empty-state outlines · R0003 · 58b38a6
