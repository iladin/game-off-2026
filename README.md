# SHIFT: GitHub Game Off 2026

A browser game for [GitHub Game Off 2026](https://itch.io/jam/game-off-2026) (theme: **SHIFT**): a curated collection of small games, each a different take on SHIFT, behind one hub. Built in Godot 4.7 for the web.

**Play:** https://iladin.github.io/game-off-2026/ (once Pages is on) · itch.io page: coming with the release.

## How it's made
An AI studio of role agents (Creative Director, Game Designer, Gameplay/Platform Engineers, Audio Designer, Tech Artist, QA Lead, Jam Critic, Release Manager) runs every hour under a Producer, directed and curated by Daniel. See [`studio/README.md`](studio/README.md). AI use is disclosed on the submission page, as the jam asks.

## Run it locally
```bash
bash scripts/ensure_godot.sh --templates   # Godot 4.7.2 + web templates into .tools/
./scripts/check.sh all                     # the gate: every game + hub
./scripts/export_web.sh && ./scripts/serve.sh   # http://localhost:8000
```
Or open the folder in the Godot 4.7 editor and press F5. Run one game directly: `godot --path . -- --game=<slug>`.

## Layout
`shared/` (the shell: Arcade, Save, Synth, Juice, MicroGame) · `hub/` · `games/<slug>/` (one game each) · `studio/` (the AI team) · `scripts/` (tooling) · rules for agents in [`CLAUDE.md`](CLAUDE.md).
