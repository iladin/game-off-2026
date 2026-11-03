---
name: export-and-deploy
description: Export the SHIFT collection to one HTML5 build, test it in a real browser, publish to GitHub Pages and package it for itch.io, including the threads/COOP-COEP gotcha and the Game Off submission checklist. Use when exporting, deploying, packaging or submitting.
---

# Export & deploy

## Local
```bash
bash scripts/ensure_godot.sh --templates   # Godot + web export templates (~1 GB download, web files kept)
./scripts/export_web.sh                    # build/web/index.html: hub + every game, one build
node scripts/browser_check.mjs             # headless Chromium: boots the export, opens a game, screenshots
./scripts/serve.sh                         # http://localhost:8000 (file:// doesn't work)
./scripts/zip_for_itch.sh                  # dist/shift-web.zip
```
Export templates must match the engine version exactly (`GODOT_VERSION` in `.github/workflows/pages.yml`).

## Threads
`variant/thread_support=false` is the repo default: no COOP/COEP headers needed, works on GitHub Pages and itch.io without "SharedArrayBuffer support". Keep it off.

## GitHub Pages
`.github/workflows/pages.yml` runs on every push to `main`: registry check → `check.sh all` → export → browser check → deploy. One-time setup: repo Settings → Pages → Source: GitHub Actions. The URL is `https://iladin.github.io/game-off-2026/`.

## itch.io (Daniel uploads; the factory prepares everything)
1. `./scripts/export_web.sh && node scripts/browser_check.mjs && ./scripts/zip_for_itch.sh`
2. On itch.io: create the project → Kind of project: HTML → upload `dist/shift-web.zip` → tick "This file will be played in the browser" → viewport 1280×720 → enable the fullscreen button → paste the page text from `studio/release/ITCH_PAGE.md` (it includes the AI-use disclosure the jam asks for) → add screenshots from `studio/release/`.
3. Submit to https://itch.io/jam/game-off-2026 and link the GitHub repo. Deadline Dec 1, 13:37 PST.

## Size
The engine `index.wasm` is ~38 MB uncompressed (hosts gzip it to ~10 MB). Our own data is `index.pck`: keep it under 20 MB; `export_web.sh` warns above that.

## When CI fails
Open the failed run; each step prints per-game output. Reproduce with `./scripts/check.sh <slug>`.
