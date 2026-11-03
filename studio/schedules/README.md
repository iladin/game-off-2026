# Scheduled tasks: kept in git

Every Claude scheduled task that works on this repo is defined here as two files:
- `<name>.json`: settings (trigger id, name, cron, enabled, model, computer, folders, permission mode, notifications, `synced_at`).
- `<name>.prompt.md`: the exact prompt each run starts with.

**Git is the source of truth.** Running tasks should match these files; any difference is drift.

| File | Scheduled task | Schedule | State |
|---|---|---|---|
| `shift-factory` | SHIFT studio: hourly run (Game Off 2026) | `48 * * * *` (hourly) | off until setup is done |

`python3 scripts/schedules.py show` prints this from the files.

## Keeping Claude and git in sync
1. **Changing a scheduled task** (in a Claude session or in the Claude app): update its files here in the same session and commit with a subject starting `schedules: sync`. Set `synced_at` to the task's `updated_at` after the change (`list_triggers` shows it).
2. **Editing these files**: apply the change to the scheduled task in the same session, then make the `schedules: sync` commit.
   - `name`, `cron`, `enabled`: `update_trigger` changes them directly.
   - `prompt`: `update_trigger` with the full text of the prompt file (`python3 scripts/schedules.py prompt shift-factory`). On a computer-bound task it takes effect only after Daniel approves it in a conversation linked to his computer; until then record it under **Pending**.
   - `model` and `folders`: only Daniel can change them, in the Claude desktop app (scheduled task settings). Ask him and add it to **Pending**.
   - Never delete and recreate a computer-bound task to change it; that loses its run history and its computer.
3. **Checking for drift**: save `list_triggers` JSON to `.tools/live_schedules.json` and run `python3 scripts/schedules.py diff .tools/live_schedules.json`. It says which way each difference should go (Claude-app edits since the last sync win; git edits get applied; both → ask Daniel).
4. **Every scheduled run** compares the prompt it started with to its `.prompt.md` and reports `DRIFT: prompt` in its log line and final message if they differ. It never fixes drift itself.

## Pending
Changes git describes that the live scheduled task doesn't have yet. Remove each line once applied.
- Folder: add `C:\git\game-off-2026` to the scheduled task in the Claude desktop app (scheduled task settings) once the repo is there, then set `"folders"` in `shift-factory.json`. (Daniel)
- Enable: turn the task on after the GitHub setup in `studio/HANDOVER.md` → Needs Daniel, then set `"enabled": true`. (Daniel)
- Model: the task runs the Producer on `claude-opus-5-5` (the old Game Factory used `claude-sonnet-5-5`). Daniel's call; change it in the app if wanted.
