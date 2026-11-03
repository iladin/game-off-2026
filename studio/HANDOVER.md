# Handover (after R0001, 2026-11-02 20:34 PT)
Phase: KICKOFF (now BUILD: VISION is locked) · Mode: KICKOFF · Hub: 0 games (hub v1 built, empty register) · Days to deadline: 28

## What this run did
- The scheduled firing at 04:06 UTC started without the repo folder attached and stopped; Daniel's "retry" re-ran it with the folder attached. That is this run, R0001.
- **VISION locked** (af22a48). Creative Director (Opus) chose framing A, **SHIFT REGISTER**: the hub is an N-bit register with one bit per shipped game; clearing a game sets its bit, and each cell shows its sense word.
  - Slate: shapeshifter, geargrind, uppercase, bitcatcher, phaseshift, cargoshift, nightwatch, redshift. Bench: overtime, turnabout, pitchshift, swingshift.
  - Finale: OVERFLOW (built later).
  - New per-game rules: `game.json` gets a `"sense"` word, and `difficulty >= 1` starts the ramp at its 30 s point.
- **Hub v1** (0d73d66). Platform Engineer (Sonnet) rebuilt the hub per VISION 7 v1, with pure rules in `hub/hub_rules.gd` and `hub/selftest.gd`.
  - New debug flag `--hubdemo=<n>` (additive, in Arcade) shows n placeholder cells, so the hub can be screenshotted before any game ships.
  - QA Lead: PASS on every accept line. Input was checked by code review only.
- **Shapeshifter design** (c4ab13c). Game Designer (Opus) ran `new_game.sh shapeshifter` and wrote `games/shapeshifter/DESIGN.md` (201 lines, build plan of about 570 lines).
  - `game.json` is filled: sense SHAPE, slot 1, status draft.
  - The game code is still the template's. Not in the hub.

## Build health
check.sh all: PASS (hub, _template, shapeshifter; run by the Producer, R0001) · registry: ok (empty) · CI: unknown (HTTP 404: repo not on GitHub yet) · push: pending (WSL loop). `git push` fails because the GitHub repo doesn't exist yet and `git remote -v` shows no remote.

Environment notes for the next Producer:
- **Background jobs die when a device_bash call returns.** Both `nohup ... &` and `setsid nohup ... &` were killed. Run `check.sh` in the foreground: `timeout 170 ./scripts/check.sh all` with device_bash `timeout_ms: 180000`. With 3 targets it took under a minute. When it grows, split it into `check.sh hub` and per-slug calls.
- **Git commits print `unable to unlink tmp_obj` warnings.** These are harmless. Run `scripts/git_unlock.sh --now` after every git write, as the procedure says. It moves HEAD.lock and maintenance.lock aside.
- Commit messages go through `.tools/msg/*.txt` with `git commit -F`.

## In flight / uncommitted
Nothing.

## Scores (latest review)
No reviews yet.

## Next run should
1. **BUILD Lane A: build Shapeshifter.** Gameplay Engineer (Sonnet) builds `games/shapeshifter/` from its DESIGN.md (rules.gd, selftest.gd, game.gd, tunnel_draw.gd). The main risk is drawing walls with holes; the design's ray-sampled ring avoids triangulation, and the builder must keep to it.
2. **QA verifies Shapeshifter** against the DESIGN.md acceptance checklist.
   - On PASS: set `"status": "shipped"`, keep `slot` 1, run `python3 scripts/registry.py`, then re-run `check.sh hub` (the tour now includes it).
   - QA must also check the **hub's non-demo path with a real game**: the cell shows SHAPE, BEST and CLEARED in the info panel, and the accent is parsed from `game.json`. This path has never been exercised.
3. **BUILD Lane B, in parallel (touches only hub/): T-0001, the bit-set ceremony** (Platform Engineer).
4. Next Lane A, after Shapeshifter ships: Game Designer for slot 2, `geargrind`.

## Needs Daniel
1. **GitHub isn't set up yet**, so commits stay local, and CI and issues return 404.
   - In WSL: `cd /mnt/c/git/game-off-2026 && bash scripts/setup_github.sh`.
   - Then leave `./scripts/push_loop.sh` running.
2. **Proposed change to `studio/procedure.md` rule 5** (Daniel-owned): background jobs don't survive the end of a device_bash call in this sandbox. Replace the rule with:
   > **Long commands.** `device_bash` calls time out at 180 s and background jobs are killed when the call returns. Run `check.sh` in the foreground with `timeout 170` (device_bash `timeout_ms: 180000`); when `all` would take longer, run `check.sh hub` and then `check.sh <slug>...` in batches across calls. Exports and downloads the same way, in steps.

   Step 0.7 should say the same. `CLAUDE.md`'s "Commands" note about running in the background needs the same change.
3. The 04:06 UTC scheduled firing had no folder attached (`connectedFolders` was empty). If it happens again, check that the scheduled task still has `C:\git\game-off-2026` attached.
