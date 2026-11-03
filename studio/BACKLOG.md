# Backlog

Format: `- [T-####] P0|P1|P2 | role | game-or-area | title` with an indented `accept:` line (one or more testable criteria) and optional `source:` (review, INBOX, #issue).
P0 = broken or blocks the jam · P1 = clearly hurts a jam score · P2 = polish. The Producer keeps Ready sorted P0 → P2, then oldest first.
Next id: T-0040

## Ready
- [T-0030] P1 | platform-engineer | shared (gauntlet) | Gauntlet interstitial card; slot timer starts after each game's intro
  accept: before each gauntlet game a ~0.6 s card shows the next game's sense word at >= 72 px in its accent with its slot digit flipping 0->1 and a shift sound; the 8 s slot counts from the game's first playable frame (TIME shows 8.0 at the first input frame); on a run clear the result card shows the 8-cell register with a carry rippling left to right, then OVERFLOW in GOOD; shots show the card and the clear register; `./scripts/check.sh hub` PASS.
  source: R0011 QA T-0021 (finding 4); R0012 Jam Critic fix 4 (raised to P1)
- [T-0031] P1 | release-manager | uppercase (web) | Chromium reports Left/Right Shift location
  accept: in the first web build, a headless Chromium check dispatching ShiftLeft and ShiftRight keydowns shows Upper Case registering the left and right Shift (location 1 and 2); if not, the on-screen key labels show the fallback keys (F/J) that work on the web.
  source: R0011 QA T-0009 (finding 3); R0012 Jam Critic fix 3 (raised to P1; do it with the first web export)
- [T-0033] P1 | gameplay-engineer | redshift | Two-finger touch: steer and BRAKE/BOOST at once
  accept: steering and the BRAKE/BOOST pads read InputEventScreenTouch/ScreenDrag by index (not emulated mouse), so a pad tap doesn't release the steering pointer; a scripted two-pointer sequence (touch 0 dragging, touch 1 tapping BRAKE) changes band while the ship keeps following touch 0; keyboard unchanged; `./scripts/check.sh redshift` PASS.
  source: R0012 QA sweep finding 1
- [T-0034] P1 | gameplay-engineer | phaseshift | Fill the upper screen with two parallax block rows
  accept: two parallax rows of block silhouettes (0.3x and 0.6x scroll) at y 200-520, one per world; the current world's row is a PANEL fill tinted with that world's colour, the other a 2 px outline; they swap on phase with the floor's 0.15 s tween; play-300 shows blocks covering >= 30% of the y 200-520 band and a post-phase shot shows the rows swapped; check.sh phaseshift PASS.
  source: R0012 Jam Critic fix 2 (Graphics 6.0)
- [T-0035] P1 | gameplay-engineer | nightwatch | Bring the danger into view (main view bar + thumbnail cue)
  accept: when an unwatched feed has d > 0.6 a 6 px BAD bar pulses at 3 Hz on the main view's right edge level with that feed's thumbnail; that feed's thumbnail gets a pulsing BAD outline (visible in the first 10 s for the nearest creeper); the watched feed's creeper is >= 40 px tall from d >= 0.3; shots show the bar and outline; check.sh nightwatch PASS.
  source: R0012 Jam Critic fix 5, QA sweep finding 4
- [T-0036] P1 | gameplay-engineer | cargoshift | Solid hull and separated crates
  accept: the hull is filled with PANEL under its 4 px INK outline with a 2 px teal waterline (no sea or grid shows through in any shot); in a storm shot (frames 1900-2000) no two crate rects intersect (gap >= 4 px); check.sh cargoshift PASS.
  source: R0012 Jam Critic fix 6
- [T-0028] P2 | creative-director | hub+VISION | OVERFLOW teaser cell: bless it or hide it
  accept: VISION.md section 2/7/8 and hub/hub.gd agree: either VISION says a dim locked OVERFLOW cell shows from the start (and section 8's cell-span numbers match 9 cells), or a Platform task is filed to hide the cell until `overflow_unlocked()`.
  source: R0011 QA T-0007 (finding 3), T-0021 (finding 3)
- [T-0025] P2 | platform-engineer | shared | Late-round QA flags for single-game launches
  accept: a user arg (e.g. `--difficulty=N` and/or `--rstart=<seconds>`) makes a single-game launch start late in its ramp; documented in shared/arcade.gd; `./scripts/shots.sh geargrind` with it reaches fifth gear (shot shows gear 5); hub selftest and `./scripts/check.sh all` PASS.
  source: R0011 QA T-0007 (finding 1)
- [T-0026] P2 | qa-lead | geargrind | See fifth gear, redline and BLOWN (after T-0025)
  accept: shots show gear 5 with a moved band, the needle in the red with the pulsing red zone and BAD tint, and the BLOWN banner with its red flash (needs T-0025 and a bot option that shifts late); findings filed as tasks.
  source: R0011 QA T-0007 (findings 1, 2)
- [T-0037] P2 | gameplay-engineer | cargoshift | Make the list visible in the first 10 s
  accept: by t = 6 s of a fresh no-input round the ship tilts >= 8 degrees, a crate has visibly slid and the needle moves into the amber band; the first 10 s still can't lose a life; check.sh cargoshift PASS.
  source: R0012 QA sweep finding 3
- [T-0038] P2 | gameplay-engineer | redshift | +N popups clear of the SOUND corner
  accept: score popups spawn inside x 170-1090 and y > 70; a shot with a popup near the top right shows no overlap with SOUND or the progress bar end; check.sh redshift PASS.
  source: R0012 QA sweep finding 2
- [T-0039] P2 | gameplay-engineer | nightwatch | Flash per the art bible
  accept: a flash is a white tint at alpha <= 0.15 for <= 0.1 s (code), with no persistent flat grey screen in any shot; check.sh nightwatch PASS.
  source: R0012 QA sweep finding 5

## In progress

## Done
<!-- - [T-####] ... · R#### · <sha> -->
- [T-0032] P1 | gameplay-engineer | redshift | Spawn in formations of 3 · R0012 · 3dc4a0b
- [T-0029] P2 | gameplay-engineer | uppercase | Ramp banners on a panel above fresh tiles · R0011 · f1c487b
- [T-0027] P2 | platform-engineer | shared | Gauntlet HUD in the left gutter, RUN LIVES label · R0011 · e8d83dc
- [T-0021] P2 | qa-lead | cargoshift+hub | Unseen states sweep: STORM, difficulty 1, OVERFLOW hub, lost-life square (all PASS; filed T-0027, T-0028, T-0030) · R0011 · sweep
- [T-0009] P2 | qa-lead | uppercase+geargrind | Unseen states sweep: banners PASS, TOP label PASS, web Shift location UNVERIFIED (filed T-0029, T-0031) · R0011 · sweep
- [T-0007] P2 | qa-lead | geargrind+hub | Late-phase and real-save sweep: ceremony PASS; fifth gear/redline/blow unreachable by the bot (filed T-0025, T-0026, T-0028) · R0011 · sweep
- [T-0019] P2 | gameplay-engineer | phaseshift+shapeshifter+bitcatcher | DESIGN.md catch-ups after R0007 · R0011 · e817a92
- [T-0024] P2 | gameplay-engineer | redshift | Show the heavies; tidy names and size · R0010 · 20d16c5
- [T-0023] P2 | gameplay-engineer | nightwatch | Start-frame eyes and a scarier full-size creeper · R0010 · 0bcc57c
- [T-0020] P2 | gameplay-engineer | cargoshift | RODE IT popup clear of the voyage bar; ship glow · R0010 · d47c1f4
- [T-0017] P2 | platform-engineer | hub | Touch-friendly hub · R0010 · 6714a20
- [T-0022] P2 | gameplay-engineer | uppercase+bitcatcher | Small layout margins · R0009 · 4efc29a
- [T-0015] P2 | gameplay-engineer | geargrind | GO moment and lasting tap cue · R0009 · 9f69a32
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
