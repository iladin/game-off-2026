# Backlog

Format: `- [T-####] P0|P1|P2 | role | game-or-area | title` with an indented `accept:` line (one or more testable criteria) and optional `source:` (review, INBOX, #issue).
P0 = broken or blocks the jam · P1 = clearly hurts a jam score · P2 = polish. The Producer keeps Ready sorted P0 → P2, then oldest first.
Next id: T-0077

## Ready
- [T-0031] P1 | release-manager | uppercase (web) | Chromium reports Left/Right Shift location
  accept: in the first web build, a headless Chromium check dispatching ShiftLeft and ShiftRight keydowns shows Upper Case registering the left and right Shift (location 1 and 2); if not, the on-screen key labels show the fallback keys (F/J) that work on the web.
  source: R0011 QA T-0009 (finding 3); R0012 Jam Critic fix 3 (raised to P1; do it with the first web export)
  status R0018: still blocked; Critic fix 3 asks Daniel to test Left/Right Shift once in his own desktop Chrome (see HANDOVER Needs Daniel 1). QA: also guard the arcade.gd:565 screenshot DirAccess path off web.
  status R0014: first web export DONE (build/web, wasm 38 MB, pck 306 KB, no warnings); the browser check is BLOCKED: no Chromium on the machine (cdn.playwright.dev and storage.googleapis.com are 403 by the allowlist), and running an npm-bundled Chromium (@sparticuz/chromium) was denied by the permission system. Needs Daniel (see HANDOVER). Code reading: F/J fallback already works and is labeled.
- [T-0028] P2 | creative-director | hub+VISION | OVERFLOW teaser cell: bless it or hide it
  accept: VISION.md section 2/7/8 and hub/hub.gd agree: either VISION says a dim locked OVERFLOW cell shows from the start (and section 8's cell-span numbers match 9 cells), or a Platform task is filed to hide the cell until `overflow_unlocked()`.
  source: R0011 QA T-0007 (finding 3), T-0021 (finding 3)
- [T-0026] P2 | qa-lead | geargrind | See fifth gear, redline and BLOWN (after T-0044; T-0025 done)
  accept: shots show gear 5 with a moved band, the needle in the red with the pulsing red zone and BAD tint, and the BLOWN banner with its red flash (needs T-0025 and a bot option that shifts late); findings filed as tasks.
  source: R0011 QA T-0007 (findings 1, 2)
  status R0015: unblocked (T-0044 `--sloppy`). QA saw the red zone (play-840) and BLOWN (play-900) with `SHIFT_QA="--rstart=40 --sloppy"`; findings filed as T-0051, T-0053. Left: FIFTH GEAR / HEAT banners not caught at those frames.

- [T-0061] P2 | gameplay-engineer | geargrind | Popups clear of the RIVAL AHEAD label and rival car
  accept: with `SHIFT_QA="--rstart=40"` shots at 790, 810, 830 (one per run) no popup glyph box intersects the "RIVAL AHEAD n m" label/bracket (y ~315-370, x ~520-760) or the rival car (e.g. skip candidate y 255..370 in `Rules.popup_pick_y`, or draw the label above popups); the unused `popup_slot`/`popup_slot_y`/`POP_SLOTS` helpers are removed from rules.gd; selftest 40 px gap still passes; check.sh geargrind PASS.
  source: R0017 QA re-verify T-0056 (findings 1, 2; b830 popup at y~314 over "27 m", b810 over the rival car)
- [T-0062] P2 | gameplay-engineer | geargrind | Bumper tick readable against the checker at the start
  accept: in `SHIFT_QA="--rstart=40" ./scripts/shots.sh geargrind 1080` the LEVEL bumper tick (x ~470, y 361..385) is distinguishable from the checker (outline or nudge), optionally tied to the LEVEL panel by a short leader; check.sh geargrind PASS.
  source: R0017 QA verify T-0057 (findings 1, 2)
- [T-0063] P2 | gameplay-engineer | nightwatch | --nwqa-hold cap in the selftest; recipe wording
  accept: a pure `R.hold_cap` (or similar) is used by game.gd and a selftest asserts an awake unwatched feed forced to 1.2 ends at 0.92 while the watched feed is untouched; DESIGN.md recipe says "CAM 2 and CAM 3 held at 0.92 (CAM 1 watched)" for frame 1250 without --nwqa; no-flag path unchanged; check.sh nightwatch PASS.
  source: R0017 QA verify T-0059 (findings 1, 3)

- [T-0073] P2 | gameplay-engineer | phaseshift | Skyline follows raised floors; step pacing feel
  accept: on raised runs (floor top y 480/400) the skyline base sits at or below the floor top in a play-900 shot; HEIGHT_CHANCE reviewed in a playtest note (100 now = a step every run) and either kept or lowered with the 16-cell two-heights selftest still passing; check.sh phaseshift PASS.
  source: R0019 QA verify T-0067 (P2 findings 1, 2)
- [T-0074] P2 | platform-engineer | hub | Info panel controls text clear of PLAY; attract keeps the manual pick
  accept: in a hub shot with Bit Catcher selected the controls line wraps or truncates and no glyph overlaps the PLAY button; when attract mode stops, `hub_selected` stays the player's last manual choice (selftest or code check); check.sh hub PASS.
  source: R0019 QA verify T-0068 (P2 findings 1, 2)
- [T-0075] P2 | gameplay-engineer | cargoshift | ROGUE SWELL popup clear of score popups; deterministic swell shot
  accept: the ROGUE SWELL popup never overlaps "+N"/phase popups or the progress bar (shots 668, 725); a QA flag or seed makes the swell side fixed so a shot at the shove frame and +0.3 s shows >= 60 px crate travel every time; check.sh cargoshift PASS.
  source: R0019 QA verify T-0066 (P2 findings 1, 2)
- [T-0076] P2 | gameplay-engineer | nightwatch | Bigger calm silhouette; stray CAM label box
  accept: the d~0 silhouette reads in play-300 (e.g. SIL_MIN >= 90 or standing in front of the door) and stays frozen while watched; the leftover "CAM n" label/pale box above the main frame in `--nwqa-hold` frame 1250 shots is explained or removed; check.sh nightwatch PASS.
  source: R0019 QA verify T-0065 (P2 findings 1, 2)
- [T-0077] P2 | gameplay-engineer | redshift | Teach-pad glow never fully fades; triangle clear of pad word
  accept: the cued pad's glow alpha stays >= ~35% of peak through the pulse (any frame in the cue window shows a halo); >= 4 px between the pad triangle and the BRAKE/BOOST word; a selftest documents teach_pad(16, 0, -1) == 0 (no BOOST pre-cue when already ember); check.sh redshift PASS.
  source: R0020 QA verify T-0070 (P2 findings 1-3)
- [T-0078] P2 | gameplay-engineer | redshift | No draw_rect width warning; --rstart=25 look documented
  accept: shot/check logs have no `draw_rect() "width" argument has no effect` warning (redshift_draw.gd emblem); DESIGN.md says --rstart=25 is a look-only flag (bot may lose before 50 s) or the bot survives it; 3 consecutive `--autoplay` frame-1500 shot runs show no ObjectDB leak, or it is shown in other games at the same rate.
  source: R0020 QA verify T-0072 (P2 findings 1-3)
- [T-0079] P2 | platform-engineer | shared | HUB confirm polish: TAP AGAIN fits; pause clears the arm; corner strips documented
  accept: a shot 2 frames after a first mid-round HUB tap shows TAP AGAIN fully inside the button; pressing P while armed resets the label to "< HUB"; each game's DESIGN.md (or a shared note) confirms the top-corner 96 px HUD strips (x 8-144, 1106-1272) hold no primary action; check.sh hub PASS.
  source: R0020 QA verify T-0069 (P2 findings 2-4)
## In progress

## Done
<!-- - [T-####] ... · R#### · <sha> -->
- [T-0070] P1 | gameplay-engineer | redshift | Red Shift pads teach BRAKE = ember, BOOST = blue; 32 px hue chips · R0020 · b7d8544
- [T-0069] P1 | platform-engineer | shared | 96 px HUB/SOUND hit areas; HUB TAP AGAIN confirm mid-round · R0020 · d132218
- [T-0072] P2 | gameplay-engineer | redshift | Ringed r9 enemy bullets; --rstart via MicroGame.qa_ramp; bullet selftests · R0020 · cf37379
- [T-0071] P2 | platform-engineer | shared (gauntlet) | OVERFLOW rising pentatonic card tones; clear card on BG + TRACE grid · R0020 · 83cc819
- [T-0065] P1 | gameplay-engineer | nightwatch | Night Watch main-view creeper silhouette and TRACE scanline (one follow-up round) · R0019 · 9328133
- [T-0066] P1 | gameplay-engineer | cargoshift | Cargo Shift rogue swell every 8-12 s · R0019 · 6e03100
- [T-0067] P1 | gameplay-engineer | phaseshift | Phase Shift ground at three heights; filled orbs (passed after one fix round) · R0019 · 0badec2
- [T-0068] P1 | platform-engineer | hub | Hub attract mode rotates the register under the head · R0019 · 6a5f9cf
- [T-0064] P1 | gameplay-engineer | redshift | Formations return fire (band-coloured bullets from r >= 20 s) · R0018 · 48facc0
- [T-0056] P2 | gameplay-engineer | geargrind | Popup slots clear of the tach (free-y picker; passed after one fix round) · R0017 · ba3f475
- [T-0058] P2 | gameplay-engineer | redshift | DODGE popup full INK at the crash point · R0017 · 9b67e65
- [T-0059] P2 | gameplay-engineer | nightwatch | --nwqa-hold QA flag for high-danger thumbs · R0017 · fa85817
- [T-0057] P2 | gameplay-engineer | geargrind | LEVEL gap label on a panel clear of the checker · R0017 · 8674834
- [T-0060] P2 | gameplay-engineer | redshift | Popup fade from Rules.popup_alpha; --seed=4 DODGE recipe (filed and done in R0017) · R0017 · bd3354d
- [T-0050] P2 | gameplay-engineer | cargoshift | DESIGN.md sea wording: amplitude at the deck edges · R0016 · 36ca573
- [T-0051] P2 | gameplay-engineer | geargrind | BLOWN aftermath reads as a dead engine; TOP inside the dial · R0016 · 6b21645
- [T-0052] P2 | gameplay-engineer | redshift | Stagger close-kill popups; DODGE popup readable · R0016 · 8719e64
- [T-0053] P2 | gameplay-engineer | geargrind | Stagger stacked shift popups · R0016 · 68b7647
- [T-0054] P2 | gameplay-engineer | nightwatch | Clamped thumbnail eyes still show approach · R0016 · 9a107f2
- [T-0055] P2 | gameplay-engineer | redshift | Stagger from the earlier popup's risen position (filed and done in R0016) · R0016 · 1618e81
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
