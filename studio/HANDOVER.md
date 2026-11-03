# Handover (initial setup, 2026-11-02)
Phase: KICKOFF · Mode: - · Hub: 0 games · Days to deadline: 29

## What this run did
Repo scaffolded by hand with Daniel: one Godot project with the shared shell (Arcade, Save, Synth, Juice, MicroGame), a placeholder hub, the reference game `games/_template`, the gate (`scripts/check.sh`), screenshots, web export, a headless-Chromium browser check, CI to GitHub Pages, and the studio (procedure, 10 roles, calendar).

## Build health
check.sh all: PASS (hub + _template) · registry: ok (empty) · CI: no runs yet · push: repo not on GitHub yet

## In flight / uncommitted
Nothing.

## Scores (latest review)
No reviews yet.

## Next run should
1. KICKOFF: Creative Director writes and locks `studio/VISION.md` (framing chosen by the team; controls free per game, keyboard + touch).
2. Platform Engineer turns the placeholder hub into VISION's framing (hub/, shared/ if needed), keeping the Arcade contract and check.sh green.
3. If time remains: Game Designer writes DESIGN.md for slate slot 1.

## Needs Daniel (one-time setup; the scheduled task stays off until it's done)
1. Put this repo at `C:\git\game-off-2026` (the folder holds `.git`, `project.godot`, `studio/`...).
2. WSL: `cd /mnt/c/git/game-off-2026 && bash scripts/setup_github.sh` (creates the public repo, pushes `main`, turns on Pages).
3. WSL: `./scripts/push_loop.sh` and leave it running (the studio commits locally; this publishes them).
4. Claude desktop app → scheduled tasks → "SHIFT studio: hourly run (Game Off 2026)" → add the folder `C:\git\game-off-2026` → turn it on. Then update `studio/schedules/shift-factory.json` (`enabled`, `folders`) in a `schedules: sync` commit, or ask Claude to.
