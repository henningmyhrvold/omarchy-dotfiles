#!/usr/bin/env python3
# check_progress.py
# Run from the project directory: python3 check_progress.py
# Or watch it: watch -n 15 'python3 check_progress.py'

import json
import subprocess
import sys
from pathlib import Path

PHASE_ICONS = {"phase-1": "🏗", "phase-2": "🧪", "phase-3": "🖥"}


def get_git_info():
    try:
        log = subprocess.check_output(
            ["git", "log", "--oneline", "-5"], stderr=subprocess.DEVNULL
        ).decode()
        return log.strip().splitlines()
    except Exception:
        return []


def main():
    plan_path = Path("plan.json")
    if not plan_path.exists():
        print("plan.json not found. Are you in the project directory?")
        sys.exit(1)

    with open(plan_path) as f:
        plan = json.load(f)

    phases = plan["phases"]
    total = sum(len(p["tasks"]) for p in phases)
    done = sum(1 for p in phases for t in p["tasks"] if t["passes"])

    bar_width = 30
    filled = int(bar_width * done / total) if total > 0 else 0
    bar = "█" * filled + "░" * (bar_width - filled)

    print(f"\n{'='*50}")
    print(f"  {plan['project']}")
    print(f"  [{bar}] {done}/{total} tasks")
    print(f"{'='*50}")

    for phase in phases:
        phase_done = all(t["passes"] for t in phase["tasks"])
        phase_partial = any(t["passes"] for t in phase["tasks"])
        icon = PHASE_ICONS.get(phase["id"], "📦")
        status = "✓" if phase_done else ("◑" if phase_partial else "○")
        print(f"\n  {status} {icon}  {phase['name']}")
        for task in phase["tasks"]:
            tick = "✓" if task["passes"] else "·"
            print(f"       {tick} [{task['id']}] {task['description']}")

    # Activity log
    activity = Path("activity.md")
    if activity.exists():
        lines = activity.read_text().splitlines()
        log_lines = [l for l in lines if l.startswith("[t")]
        if log_lines:
            print(f"\n  Last activity: {log_lines[-1]}")

    # Recent git commits
    commits = get_git_info()
    if commits:
        print(f"\n  Recent commits:")
        for c in commits:
            print(f"    {c}")

    print()


if __name__ == "__main__":
    main()
