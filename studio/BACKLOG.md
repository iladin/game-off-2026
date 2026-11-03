# Backlog

Format: `- [T-####] P0|P1|P2 | role | game-or-area | title` with an indented `accept:` line (one or more testable criteria) and optional `source:` (review, INBOX, #issue).
P0 = broken or blocks the jam · P1 = clearly hurts a jam score · P2 = polish. The Producer keeps Ready sorted P0 → P2, then oldest first.
Next id: T-0023

## Ready
- [T-0015] P2 | gameplay-engineer | geargrind | GO moment and lasting tap cue
  accept: at the end of staging the lights flash white then GOOD, a 56 px `GO` banner shows and the lever pulses (a shot at staging t about 1.7 s shows them); the `SPACE OR TAP` cue stays until the first successful shift; `./scripts/check.sh geargrind` PASS.
  source: review R0006 (critic fix 6, QA 8)
- [T-0017] P2 | platform-engineer | hub | Touch-friendly hub
  accept: the PLAY button is at least 96 px tall (or the whole info panel launches); after a touch input the footer reads touch wording (e.g. `TAP A BIT   TAP PLAY`), keyboard wording otherwise; hub selftest and `./scripts/check.sh hub` PASS.
  source: review R0006 (QA 6, 7)
- [T-0007] P2 | qa-lead | geargrind+hub | Late-phase and real-save sweep
  accept: Gear Grind shots at frames 1500 and 2400 show the band-moving phase, fifth gear and the redline/blow feedback per the bibles (findings filed as tasks); the hub's real (non-demo) bit-set ceremony plays once after a first clear and does not replay after a reload (evidence: shots or logs).
  source: R0003 QA verify (T-0001, Gear Grind)
- [T-0009] P2 | qa-lead | uppercase+geargrind | Unseen states: Upper Case banners, web Shift location, Gear Grind TOP label
  accept: shots show an Upper Case ramp banner (FASTER / LET LOWER PASS / NO HINTS / TOP SPEED) readable and clear of HUD; a frame of Gear Grind in top gear shows the moved TOP label clear of the needle; if a web build is available, note whether Left/Right Shift `location` is reported in Chromium (findings filed as tasks). Shoot 1-2 play frames per call (each ~25-30 s).
  source: R0004 QA verify (Upper Case, T-0006)
- [T-0019] P2 | gameplay-engineer | phaseshift+shapeshifter+bitcatcher | DESIGN.md catch-ups after R0007
  accept: phaseshift DESIGN.md shows zone-3 run lengths 6/8 (not 4/7), the one-hole-ahead bot and a clean bot score of about 1,750-1,950; shapeshifter DESIGN.md describes the INK >= 4 px hole outline, the steady 6 px BAD warning past p 0.75 and the --qa-mismatch flag (no 4 Hz pulse); bitcatcher DESIGN.md Juice item 3 says the newest progress square squashes and the banner position matches the code (y 262) or the code moves to the doc; docs only, `./scripts/check.sh` for those three PASS.
  source: R0007 builder and QA reports
- [T-0020] P2 | gameplay-engineer | cargoshift | RODE IT popup clear of the voyage bar; tidy dead state
  accept: the RODE IT popup no longer overlaps the voyage bar (y 116-122) or the +N popup/banner (e.g. offset PIVOT + (0, -200) or between them); `ridden_t` is either drawn (a brief ship glow) or removed; a shot at a ridden wave (about frame 1500) shows it clear; `./scripts/check.sh cargoshift` PASS.
  source: R0008 QA verify (Cargo Shift P2 1, 2)
- [T-0021] P2 | qa-lead | cargoshift+hub | Unseen states: Cargo Shift STORM banner, difficulty 1 start, touch drag; 7-cell hub with OVERFLOW
  accept: shots show Cargo Shift's STORM banner (about frame 1900), a difficulty 1 start (via the gauntlet, game 6) with storm on and hints off, and the real 6-game hub with `--qa-overflow` (7 cells, clear corners); a non-autoplay gauntlet run that loses a life shows the dim lost-life square; findings filed as tasks.
  source: R0008 QA verify (Cargo Shift, T-0003)
- [T-0022] P2 | gameplay-engineer | uppercase+bitcatcher | Small layout margins
  accept: Upper Case's pressed J label has >= 6 px margin above its key outline (e.g. `keys_draw.gd:130` offset r.end.y - 28); Bit Catcher's phase banner is clamped so any phase name stays inside x 170-1090; shots of both; check.sh for both PASS.
  source: R0008 QA verify (T-0016, T-0018)

## In progress

## Done
<!-- - [T-####] ... · R#### · <sha> -->
- [T-0003] P2 | platform-engineer | hub+shared | OVERFLOW finale: gold cell and additive Arcade gauntlet API (VISION 7, later #2) · R0008 · af2b9bf
- [T-0018] P2 | gameplay-engineer | bitcatcher | Phase banner off the fall zone; DESIGN.md catch-up · R0008 · 3647192
- [T-0016] P2 | audio-designer | uppercase | Custom tones and readable key labels · R0008 · 9fa4f58
- [T-0011] P1 | gameplay-engineer | bitcatcher | Progress squares, landing lane, calmer byte flash · R0007 · 279c520
- [T-0012] P1 | gameplay-engineer | uppercase | Shift hint glow stays on its own key · R0007 · b9d37b1
- [T-0013] P1 | gameplay-engineer | shapeshifter | Steady crash warning · R0007 · 6a18a83
- [T-0014] P1 | gameplay-engineer | geargrind | Show speed and the race · R0007 · db1bf5e
- [T-0010] P1 | gameplay-engineer | bitcatcher | Make the register and target readable in the first 10 s · R0006 · 58b0db9
- [T-0008] P2 | gameplay-engineer | uppercase | Hint glow spill and lower-case tile overlap · R0005 · 0ef5096
- [T-0005] P2 | gameplay-engineer | shapeshifter | Hole readability at mid depth and wall depth tint · R0004 · 59494ce
- [T-0006] P2 | gameplay-engineer | geargrind | Layout fixes: lever label, TOP label, mini-map overlap, tach seams · R0004 · 62cb02c
- [T-0004] P2 | gameplay-engineer | shapeshifter | +N popup rises into the life squares · R0004 · 531c780
- [T-0001] P1 | platform-engineer | hub | Bit-set ceremony on first clear · R0003 · f543a00
- [T-0002] P2 | platform-engineer | hub | Concentric glow and readable empty-state outlines · R0003 · 58b38a6
