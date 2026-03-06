# Ralph Wiggum: Quick Reference
## Opencode + Pi Stack

---

## Your Two Tools

| Tool | When to Use |
|------|------------|
| **opencode ralph-wiggum** | Long runs, stepping away, want token tracking + gutter detection |
| **Pi ralph-wiggum extension** | TUI work, model switching, interactive/parallel sessions |

State lives in **files and git** — both tools read the same project state. Switch between them freely.

---

## Key Files

| File | Purpose | Format |
|------|---------|--------|
| `RALPH_TASK.md` | Task definition + completion criteria | Markdown checkboxes `[ ]` |
| `CLAUDE.md` | Project conventions, commands, structure | Free text (model reads each iteration) |
| `.ralph/guardrails.md` | Lessons learned / Signs | Accumulated per-run (opencode) |
| `.ralph/activity.log` | Tool call log with token health 🟢🟡🔴 | Opencode only |
| `.ralph/progress.md` | What has been accomplished | Agent writes |

---

## Start a New Project

### Opencode
```bash
mkdir ~/src/myproject && cd ~/src/myproject
git init && git commit --allow-empty -m "init"
curl -fsSL https://raw.githubusercontent.com/agrimsingh/ralph-wiggum-opencode/main/install.sh | bash
# Write RALPH_TASK.md (checkboxes) and CLAUDE.md
git add -A && git commit -m "chore: ralph setup"
./.opencode/ralph-scripts/ralph-loop.sh
```

### Pi
```bash
mkdir ~/src/myproject && cd ~/src/myproject
git init && git commit --allow-empty -m "init"
# Write task file and CLAUDE.md
git add -A && git commit -m "chore: ralph setup"
pi  # Start TUI, point at task
```

---

## Task File (Opencode Checkbox Format)

```markdown
---
task: Brief description
test_command: "the verify command"
---

# Task: Name

Description of what to build.

## Success Criteria

1. [ ] First measurable outcome — verified by: command
2. [ ] Second measurable outcome — verified by: command
3. [ ] All tests pass

## Context

- Tech stack, naming conventions, key constraints
- CLI output must be ONLY the result. No labels.
```

All `[ ]` → `[x]` = loop exits.

---

## Monitoring (Opencode, Four Terminals)

```bash
# T1: The loop
./.opencode/ralph-scripts/ralph-loop.sh

# T2: Real-time activity + token health
tail -f .ralph/activity.log

# T3: Commits rolling in (no new commits = warning)
watch -n 10 'git log --oneline -10'

# T4: Gutter detection
tail -f .ralph/errors.log
```

---

## Pi Companion Extensions

| Extension | Purpose |
|-----------|---------|
| `tab-status` | ✅ done / 🚧 stuck / 🛑 timed out per tab |
| `agent-guidance` | CLAUDE.md / CODEX.md / GEMINI.md auto-switching |
| `/usage` | Cost + token dashboard by model |

Enable in `~/.pi/agent/settings.json`:
```json
{
  "extensions": [
    "~/pi-extensions/ralph-wiggum",
    "~/pi-extensions/tab-status/tab-status.ts",
    "~/pi-extensions/agent-guidance/agent-guidance.ts",
    "~/pi-extensions/usage-extension"
  ]
}
```

---

## When Ralph Fails: Add a Sign

```markdown
# In .ralph/guardrails.md (opencode) or CLAUDE.md ## Important section (Pi)

### Sign: [name]
- **Trigger**: When doing X
- **Instruction**: Do Y instead
```

| Ralph Did | Sign to Add |
|-----------|-------------|
| Skipped verify | `NEVER mark [ ] → [x] without running its verify command` |
| Worked on 2 criteria | `Complete EXACTLY ONE criterion per iteration. One commit. Stop.` |
| Used pip | `Use uv, not pip, for all package operations` |
| Output "Result: 5" | `CLI output must be ONLY the number. Nothing else.` |
| Refactored old code | `Do not touch code from previous phases unless a test requires it` |
| Loop never finishes | `When ALL criteria are [x], output exactly: TASK_COMPLETE` |

Add one guardrail at a time. Commit it. Re-run.

---

## Gutter Detection (Opencode)

Fires when: same command fails 3× in a row, or same file written 5× in 10 minutes.

```bash
# 1. Check what triggered it
cat .ralph/errors.log

# 2. Fix manually or add a guardrail
# 3. Re-run (continues from current checkbox state)
./.opencode/ralph-scripts/ralph-loop.sh
```

---

## Recovery After Crash

```bash
# See checkpoints
git log --oneline

# Reset to last good state
git reset --hard <hash>

# Re-run — picks up from checkbox state in files
./.opencode/ralph-scripts/ralph-loop.sh
```

---

## Context Health (Opencode Activity Log)

| Emoji | Tokens | Meaning |
|-------|--------|---------|
| 🟢 | < 60% | Healthy |
| 🟡 | 60–80% | Approaching rotation |
| 🔴 | > 80% | Rotation imminent |

Rotation at 80k tokens is automatic — fresh context, same file state.

---

## Cost Estimates

| Project | Criteria | Iterations | ~Cost |
|---------|----------|------------|-------|
| Small (calculator) | 5–6 | 6–10 | $0.50–$2 |
| Medium (REST API) | ~20 | 15–30 | $5–$20 |
| Large (full app) | ~50 | 30–80 | $20–$100 |

Set `MAX_ITERATIONS` in `.opencode/ralph-scripts/ralph-loop.sh` to cap overnight runs.

---

## Opencode Config

```bash
# .opencode/ralph-scripts/ralph-loop.sh
MAX_ITERATIONS=20       # Max iterations before stopping
WARN_THRESHOLD=70000    # Tokens: inject wrapup warning
ROTATE_THRESHOLD=80000  # Tokens: force fresh context
DEFAULT_MODEL="zen"     # Use free model for light tasks
```

---

## After Completion

```bash
# Verify manually (never trust the loop alone)
uv run pytest -v

# Review what was built
git log --oneline

# Review what Ralph learned
cat .ralph/guardrails.md

# Check all boxes are ticked
grep '\[ \]' RALPH_TASK.md  # Should return nothing
```
