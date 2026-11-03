# Backlog

Format: `- [T-####] P0|P1|P2 | role | game-or-area | title` with an indented `accept:` line (one or more testable criteria) and optional `source:` (review, INBOX, #issue).
P0 = broken or blocks the jam · P1 = clearly hurts a jam score · P2 = polish. The Producer keeps Ready sorted P0 → P2, then oldest first.
Next id: T-0004

## Ready
- [T-0001] P1 | platform-engineer | hub | Bit-set ceremony when a game is cleared for the first time (VISION 7, later #1)
  accept: returning to the hub after a game's first win flips that cell's digit 0 to 1 with a 0.25 s vertical squash, plays `shift` then `coin`, and bursts in the accent; it plays once per game (seen-cleared list in Save settings) and never on later visits; hub selftest asserts the "newly cleared" detection; `./scripts/check.sh hub` PASS; glyph lint OK.
  source: VISION.md section 7
- [T-0002] P2 | platform-engineer | hub | Fix the hub glow offset behind the 1 digits and the faint empty-state outlines
  accept: in a `--hubdemo=8` shot the two glow layers are concentric with each `1` digit (no smear up-left); in the zero-games shot (`./scripts/shots.sh hub`) the 8 empty cell outlines use a DIM tint and read clearly against the TRACE grid; `./scripts/check.sh hub` PASS.
  source: R0001 QA verify (P2 findings)
- [T-0003] P2 | platform-engineer | hub+shared | OVERFLOW finale: gold cell and additive Arcade gauntlet API (VISION 7, later #2)
  accept: when `hub_rules.overflow_unlocked()` is true a GOOD `OVERFLOW` cell appears after the last bit; it runs every hub game in slot order at `difficulty = 1` for 8 s each with 3 lives (`finish(_, false)` before 8 s costs a life), sums the score, records it under slug `overflow`, and shows one shared result card; existing Arcade/MicroGame APIs and `ARCADE` log lines unchanged; hub selftest covers the gauntlet bookkeeping; `./scripts/check.sh all` PASS. Staff only once at least 3 games are shipped.
  source: VISION.md section 7

## In progress

## Done
<!-- - [T-####] ... · R#### · <sha> -->
