#!/usr/bin/env python3
"""Latest GitHub Actions result for main (public repo, no credentials needed).

  python3 scripts/ci_status.py     # one line: ok / failing (+ failed steps) / running / unknown

The factory reads this at preflight: a failing deploy on main is fixed before new work.
"""
import json
import sys
import urllib.request

REPO = "iladin/game-off-2026"
API = f"https://api.github.com/repos/{REPO}"


def get(url: str):
    req = urllib.request.Request(url, headers={"Accept": "application/vnd.github+json", "User-Agent": "shift-factory"})
    with urllib.request.urlopen(req, timeout=20) as r:
        return json.load(r)


def main() -> int:
    try:
        runs = get(f"{API}/actions/runs?branch=main&per_page=1").get("workflow_runs", [])
    except Exception as e:  # repo not created yet, network, rate limit: report, don't fail the run
        print(f"ci: unknown ({e})")
        return 0
    if not runs:
        print("ci: unknown (no workflow runs on main yet)")
        return 0
    r = runs[0]
    head = f"{r['head_sha'][:7]} {r['display_title'][:60]!r} {r['html_url']}"
    if r["status"] != "completed":
        print(f"ci: running ({head})")
    elif r["conclusion"] == "success":
        print(f"ci: ok ({head})")
    else:
        failed = []
        try:
            for job in get(r["jobs_url"]).get("jobs", []):
                failed += [f"{job['name']} > {s['name']}" for s in job.get("steps", []) if s.get("conclusion") == "failure"]
        except Exception:
            pass
        print(f"ci: failing [{r['conclusion']}] ({head}) failed steps: {', '.join(failed) or 'see the run'}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
