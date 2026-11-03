#!/usr/bin/env python3
"""Scheduled tasks kept in git (studio/schedules/).

Each scheduled task is two files: <name>.json (settings) and <name>.prompt.md (the exact
prompt). Git is the source of truth; see studio/schedules/README.md for the sync rules.

  python3 scripts/schedules.py show                 # what git says should be running
  python3 scripts/schedules.py prompt <name>        # print a prompt, for create/update calls
  python3 scripts/schedules.py diff <live.json>     # compare git with the live scheduled tasks

live.json is the output of the list_triggers tool saved to a file (the {"data": [...]} object,
or just the list). diff exits 1 when anything differs, and says which way to sync.
"""
import hashlib
import json
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
DIR = ROOT / "studio" / "schedules"


def load_declared() -> dict:
    out = {}
    for meta_path in sorted(DIR.glob("*.json")):
        meta = json.loads(meta_path.read_text(encoding="utf-8"))
        meta["_name"] = meta_path.stem
        meta["_prompt"] = (DIR / meta["prompt_file"]).read_text(encoding="utf-8")
        out[meta_path.stem] = meta
    return out


def norm(text: str) -> str:
    return "\n".join(line.rstrip() for line in text.strip().splitlines())


def sha(text: str) -> str:
    return hashlib.sha256(norm(text).encode()).hexdigest()[:12]


def git_edited_since_sync(name: str) -> bool:
    """True if this schedule's files changed in git after the last 'schedules: sync' commit."""
    files = [f"studio/schedules/{name}.json", f"studio/schedules/{name}.prompt.md"]
    git = ["git", "-C", str(ROOT), "--no-optional-locks"]
    dirty = subprocess.run(git + ["status", "--porcelain", "--"] + files, capture_output=True, text=True).stdout.strip()
    if dirty:
        return True
    last_sync = subprocess.run(git + ["log", "-1", "--format=%H", "--grep=^schedules: sync", "--"] + files,
                               capture_output=True, text=True).stdout.strip()
    if not last_sync:
        return True
    later = subprocess.run(git + ["log", "--format=%H", f"{last_sync}..HEAD", "--"] + files,
                           capture_output=True, text=True).stdout.strip()
    return bool(later)


def cmd_show() -> int:
    for name, m in load_declared().items():
        state = "on " if m["enabled"] else "off"
        where = "computer" if m.get("requires_computer") else "cloud"
        print(f"{state}  {name:24} {m['cron']:12} {m['model']:20} {where:8} prompt {sha(m['_prompt'])}  {m['name']}")
    return 0


def cmd_prompt(name: str) -> int:
    print(load_declared()[name]["_prompt"], end="")
    return 0


def cmd_diff(live_path: str) -> int:
    raw = json.loads(Path(live_path).read_text(encoding="utf-8"))
    live = {t["id"]: t for t in (raw["data"] if isinstance(raw, dict) else raw)}
    declared = load_declared()
    drift = False
    for name, m in declared.items():
        t = live.pop(m["trigger_id"], None)
        if t is None:
            print(f"MISSING  {name}: {m['trigger_id']} is not a live scheduled task (deleted? recreate and update trigger_id)")
            drift = True
            continue
        ds = t.get("derived_state", {})
        diffs = []
        pairs = [("name", m["name"], t.get("name")), ("cron", m["cron"], t.get("cron_expression")),
                 ("enabled", m["enabled"], t.get("enabled")), ("model", m["model"], ds.get("model")),
                 ("permission_mode", m.get("permission_mode"), ds.get("permission_mode")),
                 ("folders", sorted(f.lower() for f in m.get("folders", [])), sorted(f.lower() for f in ds.get("folders", [])))]
        for field, want, have in pairs:
            if want != have:
                diffs.append(f"{field}: git={want!r} live={have!r}")
        if norm(m["_prompt"]) != norm(ds.get("prompt", "")):
            diffs.append(f"prompt: git sha {sha(m['_prompt'])} != live sha {sha(ds.get('prompt', ''))}")
        if not diffs:
            print(f"in sync  {name}")
            continue
        drift = True
        live_changed = t.get("updated_at", "") > m.get("synced_at", "")
        git_changed = git_edited_since_sync(name)
        if live_changed and git_changed:
            way = "CONFLICT: changed in both Claude and git since the last sync - ask Daniel which wins"
        elif live_changed:
            way = "changed in Claude since the last sync - copy the live values into git"
        else:
            way = "changed in git - apply to the scheduled task (update_trigger), or ask Daniel for app-only fields"
        print(f"DRIFT    {name}: {way}")
        for d in diffs:
            print(f"         {d}")
    for tid, t in live.items():
        # Other repos' scheduled tasks are listed too; only ours count.
        if "game-off-2026" not in t.get("derived_state", {}).get("prompt", ""):
            continue
        print(f"UNTRACKED live scheduled task {tid} '{t.get('name')}' has no file in studio/schedules/")
        drift = True
    return 1 if drift else 0


def main() -> int:
    args = sys.argv[1:]
    if not args or args[0] == "show":
        return cmd_show()
    if args[0] == "prompt" and len(args) == 2:
        return cmd_prompt(args[1])
    if args[0] == "diff" and len(args) == 2:
        return cmd_diff(args[1])
    print(__doc__)
    return 2


if __name__ == "__main__":
    sys.exit(main())
