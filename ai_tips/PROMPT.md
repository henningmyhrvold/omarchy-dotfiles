# PROMPT.md — Python Calculator

## Context
You are building a Python CLI calculator. All project conventions are in `CLAUDE.md`.
Your task list is in `plan.json`. Track progress by updating `plan.json`.

## Each Iteration — Follow This Exactly

1. Read `plan.json` and find the FIRST task where `"passes": false`
2. Read `CLAUDE.md` to understand project conventions (read it every time)
3. Read any source files you plan to edit BEFORE editing them (use cat or read tools)
4. Complete that single task — do not work on multiple tasks at once
5. Run the task's `verify` command from `plan.json`
6. If verify FAILS: fix the issue and re-run verify (max 3 attempts per task)
7. If verify still fails after 3 attempts: append the error to `activity.md` and output exactly:
   `STUCK: <task-id>`
8. If verify PASSES: set `"passes": true` for that task in `plan.json`
9. Append a one-line summary to `activity.md` in format: `[t00X] <what you did>`
10. Commit: `git add -A && git commit -m "feat: <task description>"`
11. Check if ALL tasks in `plan.json` now have `"passes": true`
12. If all pass: output exactly on its own line: `TASK_COMPLETE`
13. If tasks remain: do not output anything — the loop will restart you

## Hard Stops

After ALL Phase 1 tasks pass: run `python -m pytest tests/ -v` before continuing to Phase 2.
If any test fails, fix it in the current iteration before marking Phase 2 as started.

After ALL Phase 2 tasks pass: run `python -m pytest tests/ -v --cov=src/calculator --cov-report=term-missing`
Coverage on `src/calculator/core.py` must be 100% before Phase 3.

## Signs (Guardrails — Read These Before Every Action)

- ALWAYS read a file before editing it
- NEVER mark a task complete without running its `verify` command from plan.json
- NEVER work on more than ONE task per iteration — complete one, commit, stop
- NEVER create files or directories not listed in CLAUDE.md project structure
- NEVER use pip — use `uv` for any package operations
- NEVER use print() for debugging — remove debug prints before committing
- NEVER commit with failing tests
- NEVER refactor code from a previous task unless the verify command requires it
- When updating plan.json, ONLY change the `"passes"` field of the completed task — nothing else
- CLI output must be ONLY the result number — no labels, no "Result:", no extra newlines
- If a directory doesn't exist when you need to create a file, create the directory first
- Run `ls` to confirm paths before creating files — never assume a directory exists

## Completion

When all tasks in plan.json have `"passes": true`, your final output must be exactly:
TASK_COMPLETE
