# Backlog

Format: `- [T-####] P0|P1|P2 | role | game-or-area | title` with an indented `accept:` line (one or more testable criteria) and optional `source:` (review, INBOX, #issue).
P0 = broken or blocks the jam · P1 = clearly hurts a jam score · P2 = polish. The Producer keeps Ready sorted P0 → P2, then oldest first.
Next id: T-0055

## Ready
- [T-0031] P1 | release-manager | uppercase (web) | Chromium reports Left/Right Shift location
  accept: in the first web build, a headless Chromium check dispatching ShiftLeft and ShiftRight keydowns shows Upper Case registering the left and right Shift (location 1 and 2); if not, the on-screen key labels show the fallback keys (F/J) that work on the web.
  source: R0011 QA T-0009 (finding 3); R0012 Jam Critic fix 3 (raised to P1; do it with the first web export)
  status R0014: first web export DONE (build/web, wasm 38 MB, pck 306 KB, no warnings); the browser check is BLOCKED: no Chromium on the machine (cdn.playwright.dev and storage.googleapis.com are 403 by the allowlist), and running an npm-bundled Chromium (@sparticuz/chromium) was denied by the permission system. Needs Daniel (see HANDOVER). Code reading: F/J fallback already works and is labeled.
- [T-0028] P2 | creative-director | hub+VISION | OVERFLOW teaser cell: bless it or hide it
  accept: VISION.md section 2/7/8 and hub/hub.gd agree: either VISION says a dim locked OVERFLOW cell shows from the start (and section 8's cell-span numbers match 9 cells), or a Platform task is filed to hide the cell until `overflow_unlocked()`.
  source: R0011 QA T-0007 (finding 3), T-0021 (finding 3)
- [T-0026] P2 | qa-lead | geargrind | See fifth gear, redline and BLOWN (after T-0044; T-0025 done)
  accept: shots show gear 5 with a moved band, the needle in the red with the pulsing red zone and BAD tint, and the BLOWN banner with its red flash (needs T-0025 and a bot option that shifts late); findings filed as tasks.
  source: R0011 QA T-0007 (findings 1, 2)
  status R0015: unblocked (T-0044 `--sloppy`). QA saw the red zone (play-840) and BLOWN (play-900) with `SHIFT_QA="--rstart=40 --sloppy"`; findings filed as T-0051, T-0053. Left: FIFTH GEAR / HEAT banners not caught at those frames.
- [T-0050] P2 | gameplay-engineer | cargoshift | DESIGN.md sea wording: amplitude at the deck edges
  accept: DESIGN.md's Sea section says the swell is 0.18x under the waterline extent (x 330..950), about 0.6x at the deck edges (x 300/980) and full by x 270/1010, matching R.sea_offset; check.sh cargoshift PASS.
  source: R0015 QA verify T-0049
- [T-0051] P2 | gameplay-engineer | geargrind | BLOWN aftermath reads as a dead engine; TOP inside the dial
  accept: with `SHIFT_QA="--rstart=40 --sloppy" ./scripts/shots.sh geargrind 900` the BLOWN heat shows smoke or a dimmed car through the result beat (not just a needle at idle); in a gear-5 shot (`--rstart=40`, frame 840) the TOP label sits inside the tach dial and the red zone reads clearly live or clearly inactive; check.sh geargrind PASS.
  source: R0015 QA verify T-0044 (findings 1, 3)
- [T-0052] P2 | gameplay-engineer | redshift | Stagger close-kill popups; DODGE popup readable
  accept: two kills within ~0.3 s and ~40 px get popups offset so both labels read (shot with `SHIFT_QA="--rstart=40" ./scripts/shots.sh redshift 540` or a selftest on the offset rule); a DODGE popup shot shows DIM text readable on its outline; check.sh redshift PASS.
  source: R0015 QA verify T-0048
- [T-0053] P2 | gameplay-engineer | geargrind | Stagger stacked shift popups
  accept: in `SHIFT_QA="--rstart=40" ./scripts/shots.sh geargrind 840` PERFECT +30 and a following +15 don't overlap (vertical stagger or merge); check.sh geargrind PASS.
  source: R0015 QA verify T-0044 (finding 4)
- [T-0054] P2 | gameplay-engineer | nightwatch | Clamped thumbnail eyes still show approach
  accept: in idle frames at d 0.3 vs d 0.6-0.9 (e.g. frames 300 and 540) the thumbnail eyes stay inside the outline and look visibly bigger or closer at the later frame; check.sh nightwatch PASS.
  source: R0015 QA verify T-0046

## In progress

## Done
<!-- - [T-####] ... · R#### · <sha> -->
- [T-0044] P2 | gameplay-engineer | geargrind | QA bot flag that misses shifts (unblocks T-0026) · R0015 · c186968
- [T-0047] P2 | gameplay-engineer | cargoshift | Waterline on the wave; submerged hull reads · R0015 · 0773842
- [T-0046] P2 | gameplay-engineer | nightwatch | Thumbnail outline vs creeper eyes; earlier main-view bar? · R0015 · d2d0416
- [T-0048] P2 | gameplay-engineer | redshift | Brighter kill popups · R0015 · 107639f
- [T-0045] P2 | gameplay-engineer | geargrind | "RIVAL AHEAD n m" label clear of the car · R0015 · 119b8c4
- [T-0049] P2 | gameplay-engineer | cargoshift | Livelier sea at the hull edges; DESIGN.md catch-up after T-0047 · R0015 · 64e2807
- [T-0025] P2 | platform-engineer | shared | Late-round QA flags for single-game launches · R0014 · 491ded2
- [T-0040] P2 | gameplay-engineer | redshift | Popup rise stays below the HUD · R0014 · 6e0e62a
- [T-0041] P2 | gameplay-engineer | nightwatch | Stronger danger cues · R0014 · 5ab0c53
- [T-0042] P2 | gameplay-engineer | cargoshift | Waterline follows the sea, not the hull · R0014 · 39adf0c
- [T-0043] P2 | platform-engineer | shared (gauntlet) | Cap the gauntlet card word · R0014 · d7ad814
- [T-0030] P1 | platform-engineer | shared (gauntlet) | Gauntlet interstitial card; slot timer starts after each game's intro · R0013 · 0b1590e
- [T-0033] P1 | gameplay-engineer | redshift | Two-finger touch: steer and BRAKE/BOOST at once · R0013 · 48b3639
- [T-0034] P1 | gameplay-engineer | phaseshift | Fill the upper screen with two parallax block rows · R0013 · ec26439
- [T-0035] P1 | gameplay-engineer | nightwatch | Bring the danger into view (main view bar + thumbnail cue) · R0013 · cdd67c4
- [T-0036] P1 | gameplay-engineer | cargoshift | Solid hull and separated crates · R0013 · 0e4f018
- [T-0037] P2 | gameplay-engineer | cargoshift | Make the list visible in the first 10 s · R0013 · 40673f6
- [T-0038] P2 | gameplay-engineer | redshift | +N popups clear of the SOUND corner · R0013 · 73aad9e
- [T-0039] P2 | gameplay-engineer | nightwatch | Flash per the art bible · R0013 · no change (already met: hit flash INK a0.15 0.1 s)
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
