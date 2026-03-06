# Ralph Wiggum: Zero to Hero Guide
## Autonomous AI Development Loops with Opencode + Pi

> *"Me fail English? That's unpossible!"* — Ralph Wiggum

---

## Table of Contents

1. [What Is the Ralph Wiggum Technique?](#1-what-is-the-ralph-wiggum-technique)
2. [Architecture: Your Two Primary Tools](#2-architecture-your-two-primary-tools)
3. [Global Setup: Prerequisites & Installation](#3-global-setup-prerequisites--installation)
4. [The Three Phases of Every Ralph Project](#4-the-three-phases-of-every-ralph-project)
5. [Task Definition Formats](#5-task-definition-formats)
6. [Project Initialization: The Full Ritual](#6-project-initialization-the-full-ritual)
7. [The Calculator Walkthrough: Zero to Hero](#7-the-calculator-walkthrough-zero-to-hero)
8. [Monitoring a Running Loop](#8-monitoring-a-running-loop)
9. [Reading the Output: What Success and Failure Look Like](#9-reading-the-output-what-success-and-failure-look-like)
10. [Prompt Tuning: The Core Skill](#10-prompt-tuning-the-core-skill)
11. [Ansible Role Integration](#11-ansible-role-integration)
12. [MCP Integration](#12-mcp-integration)
13. [Cost Management](#13-cost-management)
14. [Troubleshooting Reference](#14-troubleshooting-reference)

---

## 1. What Is the Ralph Wiggum Technique?

At its absolute core, Ralph Wiggum is this:

```bash
while :; do cat PROMPT.md | opencode run --format json; done
```

That's it. A bash loop that feeds the same prompt file to an AI agent repeatedly until the task is done. Geoffrey Huntley named it after Ralph Wiggum from The Simpsons: lovably persistent, not always competent, but eventually gets there.

### The Key Insight: State Lives in Files, Not in the Model

Each iteration of the loop starts with a fresh context window. The model has no memory of previous iterations. What it *does* have is the filesystem — your code, your task file, your git history. **All progress persists in files. The model is stateless. The files are stateful.**

This is why Ralph works for long-running tasks that would otherwise hit context limits or get confused by accumulated conversation history.

### The malloc/free Problem

In traditional programming, `malloc()` allocates memory and `free()` releases it. In LLM context, reading files, tool outputs, and conversation all allocate context — but there is no `free()`. Context cannot be selectively released. The only way to free it is to start a new conversation.

This creates two failure modes. The first is context pollution: failed attempts, unrelated code, and mixed concerns accumulate and confuse the model. The second is the gutter: once context is polluted, the model keeps referencing bad state — like a bowling ball in the gutter, there's no correcting it mid-session.

**Ralph's solution:** Deliberately rotate to fresh context before pollution builds up. State lives in files and git, not in the model's memory.

### The Playground Metaphor

Geoffrey Huntley describes it perfectly:

> *"Ralph is very good at making playgrounds, but he comes home bruised because he fell off the slide, so one then tunes Ralph by adding a sign next to the slide saying 'SLIDE DOWN, DON'T JUMP, LOOK AROUND,' and Ralph is more likely to look and see the sign."*

When Ralph fails, you don't blame the model. You add a guardrail to `PROMPT.md` that prevents the failure mode. Over time, the prompt accumulates enough guardrails to become reliable.

### Ralph's Three States

| State | Description |
|-------|-------------|
| **Under-baked** | Not enough iterations / guardrails / detail in the prompt |
| **Baked** | Task complete, output is good |
| **Baked with latent behaviors** | Done, but did unexpected things — sometimes nice, sometimes not |

### What Ralph Is Good At

- Greenfield projects with clear specs
- Repetitive multi-file tasks
- TDD workflows (write test → make it pass → repeat)
- Porting/migration between frameworks
- Projects where you can define "done" precisely as a file check or test pass

### What Ralph Struggles With

- Ambiguous requirements (fix with Phase 1: Clarify)
- Tasks requiring external API credentials it doesn't have
- Highly stateful UIs that need visual inspection
- Tasks where "done" cannot be expressed verifiably

---

## 2. Architecture: Your Two Primary Tools

You use opencode and Pi as your 90% stack, with Claude Code available manually for the remaining 10%. These are two distinct Ralph implementations with meaningfully different architectures.

### Tool A: ralph-wiggum-opencode (Primary for External Loop Runs)

**Repo:** `graffhyrum/ralph-wiggum-opencode`  
**Best for:** Projects you want to kick off and step away from. Longer runs. Any project where you want precise token tracking and gutter detection.

The opencode implementation is a bash wrapper. It manages the loop *externally* — opencode runs as a subprocess, and `ralph-loop.sh` restarts it with fresh context each iteration. Nothing accumulates. Each iteration is a clean slate that reads its state from files and git.

```
ralph-loop.sh (bash)
    └── opencode run --format json
            └── stream-parser.sh (token tracking, gutter detection)
            └── .ralph/ (state files, guardrails, activity log)
            └── git (progress checkpoints)
```

**How context rotation works:** The stream parser tracks actual bytes from every file read and write. At 70k tokens it injects an inline warning telling the agent to wrap up its current work. At 80k tokens it forces a fresh opencode subprocess. This means context pollution is mechanically impossible — the loop won't let a session run long enough to get into the gutter.

**Task definition:** `RALPH_TASK.md` with markdown `[ ]` checkboxes. Ralph counts unchecked boxes to determine if the task is done. When all are `[x]` the loop exits.

**The learning loop:** When something fails, the agent writes a "Sign" to `.ralph/guardrails.md`. The next iteration reads `guardrails.md` first. This is how failure knowledge persists across context rotations — it prevents the same mistake being made in iteration 5 that was made in iteration 2.

**Gutter detection:** If the same command fails three times in a row, or the same file gets written five times within ten minutes, the parser emits a GUTTER signal and halts. You check `.ralph/errors.log`, fix or add a guardrail, and re-run.

**Install:**
```bash
cd your-project
curl -fsSL https://raw.githubusercontent.com/agrimsingh/ralph-wiggum-opencode/main/install.sh | bash
```

**Start:**
```bash
./.opencode/ralph-scripts/ralph-loop.sh
```

**Files installed:**

| File | Purpose | Who reads/writes |
|------|---------|-----------------|
| `RALPH_TASK.md` | Task definition + checkbox criteria | You write; agent reads |
| `.ralph/progress.md` | What has been accomplished | Agent writes after work chunks |
| `.ralph/guardrails.md` | Lessons learned / Signs | Agent reads first, writes after failures |
| `.ralph/activity.log` | Tool call log with token health (🟢/🟡/🔴) | Parser writes; you monitor |
| `.ralph/errors.log` | Failure log for gutter detection | Parser writes; agent reads |
| `.ralph/.iteration` | Current iteration number | Parser manages |

**Context health indicators in activity.log:**

| Emoji | Token % | Meaning |
|-------|---------|---------|
| 🟢 | < 60% | Plenty of room |
| 🟡 | 60–80% | Approaching limit |
| 🔴 | > 80% | Rotation imminent |

**Configurable thresholds** (edit `.opencode/ralph-scripts/ralph-loop.sh`):
```bash
MAX_ITERATIONS=20       # Max rotations before stopping
WARN_THRESHOLD=70000    # Tokens: inject wrapup warning
ROTATE_THRESHOLD=80000  # Tokens: force fresh context
DEFAULT_MODEL="zen"     # Default model
```

---

### Tool B: ralph-wiggum Pi Extension (Primary for Interactive/TUI Work)

**Repo:** `tmustier/pi-extensions` (the `ralph-wiggum` folder)  
**Best for:** Projects where you want to stay in Pi's TUI, switch models mid-run, or use Pi's richer interface features alongside the loop.

The Pi implementation is an extension + skill combo that lives *inside* Pi rather than outside it. Pi's extension system lets TypeScript modules hook into lifecycle events, register slash commands, and add UI components. The ralph-wiggum extension wires into Pi's session management directly — no external bash loop.

This is described as the "flat version without subagents," which means it runs a single agent in a loop rather than spawning parallel tasks. It's simpler and more predictable than multi-agent setups.

**Two components in one:**

The **extension** handles loop mechanics inside Pi — it watches for completion signals, manages iteration state, and handles context rotation from within the TUI. The **skill** injects ralph-specific system instructions into the model's context, telling it how to commit progress to files and git, how to write guardrails, and when to signal completion.

**Install (via pi package manager):**
```bash
pi install git:github.com/tmustier/pi-extensions
```

**Or if you keep a local clone** (which your Ansible `pi_extensions` role likely does):
```json
{
  "extensions": [
    "~/pi-extensions/ralph-wiggum"
  ]
}
```

Add to `~/.pi/agent/settings.json`. The ralph-wiggum entry covers both the extension and the skill.

**Pairs well with:**

The Pi ecosystem has several extensions that work naturally alongside ralph-wiggum:

- **tab-status** — shows ✅ done / 🚧 stuck / 🛑 timed out in your terminal tabs. Essential if you run parallel Pi sessions.
- **agent-guidance** — lets you switch between Claude, Codex, and Gemini with model-specific guidance files (`CLAUDE.md`, `CODEX.md`, `GEMINI.md`). The prompt adapts per model automatically. Run `cd ~/pi-extensions/agent-guidance && ./setup.sh` to initialize.
- **/usage** — cost and token dashboard across sessions, by provider and model. Useful for tracking Ralph run costs over time.

**Task definition:** Pi's ralph-wiggum skill works with whatever task format you provide — it injects guidance, not a rigid schema. A markdown checklist or structured description both work. The skill tells the agent to commit progress to files and git, maintain a guardrails log, and signal when complete.

**Key difference from opencode:** The loop lives inside the Pi session. You stay in the TUI throughout. This is better for projects where you want to intervene, switch models, or inspect progress interactively. It does not have the external token-counting infrastructure that the opencode bash wrapper has, so context health is managed by Pi's native session handling.

---

### Choosing Between Them

| Situation | Use |
|-----------|-----|
| Long run, stepping away | opencode ralph-wiggum |
| Want token tracking + gutter detection | opencode ralph-wiggum |
| Staying in the TUI, want interactivity | Pi ralph-wiggum |
| Switching models mid-task | Pi ralph-wiggum + agent-guidance |
| Multi-session parallel work | Pi ralph-wiggum + tab-status |
| Unsure, starting a new project | Either — both use the same core files |

**The good news:** your task files are compatible with both. A well-written `RALPH_TASK.md` or markdown checklist works for opencode. The same content works as Pi's task input. You can start a project in Pi and continue it in opencode, or vice versa, because state lives in git and files — not in the tool.

### Claude Code (Your 10%)

For the occasional project where you set up Claude Code manually, the official `anthropics/claude-code` ralph-wiggum plugin works differently from both of the above. It uses a Stop hook that intercepts Claude's exit attempts and re-feeds the prompt *within the same session*, so context accumulates across iterations rather than resetting. This is fine for short tasks but can get polluted on longer runs. Install it inside a Claude Code session with `/install-github-plugin anthropics/claude-code plugins/ralph-wiggum`.

---

## 3. Global Setup: Prerequisites & Installation

### 3.1 Verify Your Ansible Setup Ran

```bash
# Verify Pi is installed
pi --version

# Verify opencode is installed
opencode --version

# Verify MCP containers are running
docker ps --format '{{.Names}}' | grep '^mcp-'
# Should show: mcp-filesystem, mcp-ref, mcp-docker

# Verify git is initialized in your project (required for state persistence)
git status
```

### 3.2 Install opencode (If Not Already Present)

```bash
curl https://opencode.ai/install -fsS | bash
```

Verify:
```bash
opencode --version
```

### 3.3 Install Pi ralph-wiggum Extension

If your `pi_extensions` Ansible role deployed a local clone, add to `~/.pi/agent/settings.json`:

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

If not, install from git:
```bash
pi install git:github.com/tmustier/pi-extensions
```

Then run the agent-guidance setup:
```bash
cd ~/pi-extensions/agent-guidance && ./setup.sh
```

### 3.4 Install opencode ralph-wiggum Scripts

This is per-project (not global). See Section 6 for the project initialization ritual.

### 3.5 Set Your API Key

Both opencode and Pi need your provider API key:

```bash
# Add to ~/.zshrc
export ANTHROPIC_API_KEY="sk-ant-..."

# Reload
source ~/.zshrc
```

---

## 4. The Three Phases of Every Ralph Project

Every Ralph project follows three phases. Never skip Phase 1. Never go straight to Phase 3 with a vague task description.

```
Phase 1: CLARIFY          Phase 2: PLAN              Phase 3: EXECUTE
─────────────────    →    ────────────────────    →   ────────────────
Interview yourself        Generate RALPH_TASK.md       Start the loop
Define done precisely     Add guardrails               Monitor activity.log
Check constraints         Commit everything            Tune on failure
Output: requirements.md   Output: RALPH_TASK.md        Output: working code
```

### Phase 1: Clarify

Before writing a single task, answer these questions clearly in `requirements.md`:

**Core requirements:** What exactly does this build or change? What does "working" mean — which commands should pass? What error cases must be handled?

**Technical constraints:** Language and version. Dependency manager. Test framework. Code style (linter, formatter). File naming conventions.

**Completion definition:** What is the exact terminal command that proves the project is done? If you cannot write that command, your requirements are not clear enough yet.

**Known failure modes:** Have you done this type of project before with Ralph? Any signs from previous runs that already apply?

### Phase 2: Plan

Convert your requirements into `RALPH_TASK.md`. For opencode this means a markdown checklist with clear, testable criteria. Each criterion should be achievable in a single context window. Each criterion should have a command that proves it done.

For Pi, the task description is more flexible — the skill will handle loop mechanics. But the same principle applies: be specific about what "done" means for each chunk of work, and specify how to verify it.

### Phase 3: Execute

Start the loop, monitor activity, intervene only when gutter detection fires or you see something clearly wrong. When Ralph completes, run your verification commands manually. Commit the final state if it looks good.

---

## 5. Task Definition Formats

### Format A: RALPH_TASK.md (opencode style)

Used by the opencode ralph-wiggum scripts. Completion is tracked by checkbox state.

```markdown
---
task: Build a Python CLI calculator
test_command: "python -m pytest tests/ -v"
---

# Task: Python CLI Calculator

Build a CLI calculator with add, subtract, multiply, divide.

## Success Criteria

1. [ ] Project structure created: src/, tests/, pyproject.toml
2. [ ] Core functions implemented: add, sub, mul, div with type hints
3. [ ] All functions covered by pytest (100% coverage)
4. [ ] CLI accepts two numbers and an operation, outputs only the result
5. [ ] ZeroDivisionError raised (not caught silently) on divide by zero
6. [ ] README documents install and usage

## Context

- Use Python 3.12, uv for package management
- Use pytest, ruff
- CLI output: ONLY the number. No labels, no trailing newlines.
- Commit after each criterion is met
```

Ralph counts `[ ]` boxes. When all become `[x]`, the loop exits.

**Important:** Each criterion should be specific and independently testable. Avoid vague criteria like "code is clean" — prefer "ruff check passes with zero warnings."

### Format B: Plan-based task file (Pi / flexible)

Pi's ralph-wiggum skill works with a more narrative format. You can use structured sections or phases rather than flat checkboxes. The key is still: state what done looks like, and tell the agent how to verify it.

```markdown
# Task: Python CLI Calculator

## Goal
Build a working CLI calculator with tests.

## Phases

### Phase 1: Foundation
Create project structure with uv. Implement add/sub/mul/div functions with type hints.
Done when: `python -m pytest tests/ -v` shows tests collected.

### Phase 2: Testing
Write pytest tests with 100% coverage.
Done when: `pytest --cov=src --cov-fail-under=100` passes.

### Phase 3: CLI
Add argparse CLI. CLI must output ONLY the number.
Done when: `python -m src.cli 10 add 5` outputs `15`.

## Completion
All phases done. Final verification: `pytest && python -m src.cli 10 div 2` outputs `5.0`.
```

### Which format to use

Use the checkbox format (`RALPH_TASK.md`) when running via opencode ralph-wiggum scripts — the loop explicitly scans for unchecked boxes. Use the phase/narrative format when running from Pi — the ralph-wiggum skill reads it and manages loop logic internally.

If you want a single file that works with both tools, use checkboxes. Both Pi and opencode can understand them, and the opencode scripts require them.

---

## 6. Project Initialization: The Full Ritual

### For Opencode Projects

```bash
# 1. Create project directory and initialize git
mkdir ~/src/myproject && cd ~/src/myproject
git init
git commit --allow-empty -m "init: ralph project"

# 2. Install opencode ralph-wiggum scripts
curl -fsSL https://raw.githubusercontent.com/agrimsingh/ralph-wiggum-opencode/main/install.sh | bash

# 3. Create your task file
# Edit RALPH_TASK.md — use the checkbox format from Section 5

# 4. Create CLAUDE.md (project conventions for the model)
# Include: project structure, key commands, tech stack, naming conventions

# 5. Commit everything
git add -A
git commit -m "chore: ralph project setup"

# 6. Verify prerequisites
opencode --version
git log --oneline  # Should show your setup commits
```

### For Pi Projects

```bash
# 1. Create project directory and initialize git
mkdir ~/src/myproject && cd ~/src/myproject
git init
git commit --allow-empty -m "init: ralph project"

# 2. Create task file (flexible format, see Section 5)
# Edit TASK.md or RALPH_TASK.md

# 3. Create CLAUDE.md (if using Claude model)
# or CODEX.md / GEMINI.md depending on which model you'll use

# 4. Commit everything
git add -A
git commit -m "chore: ralph project setup"

# 5. Open Pi and start
pi
# Then: describe the task or point it at your task file
```

### What Goes in CLAUDE.md (Project Memory)

`CLAUDE.md` (or model-specific equivalent for Pi + agent-guidance) is the agent's persistent memory file. It gets read at the start of every iteration. Keep it focused:

```markdown
# Project Memory

## Tech Stack
- Python 3.12, uv, pytest, ruff

## Project Structure
src/
  __init__.py
  calculator.py    # Core functions
  cli.py           # Argparse CLI
tests/
  test_calculator.py

## Key Commands
- Install: uv sync
- Test: uv run pytest
- Lint: uv run ruff check src/
- Run CLI: uv run python -m src.cli <num> <op> <num>

## Conventions
- All functions must have type hints
- CLI outputs ONLY the result number. No labels.
- Commit message format: feat:, test:, fix:, docs:
- ZeroDivisionError should propagate, not be caught silently
```

---

## 7. The Calculator Walkthrough: Zero to Hero

Here's how a complete calculator project runs from start to finish, using opencode ralph-wiggum.

### Setup (5 minutes)

```bash
mkdir ~/src/python-calculator && cd ~/src/python-calculator
git init && git commit --allow-empty -m "init"
curl -fsSL https://raw.githubusercontent.com/agrimsingh/ralph-wiggum-opencode/main/install.sh | bash
```

Write `RALPH_TASK.md` with 6 checkboxes: project structure, core functions, tests, CLI, error handling, README.

Write `CLAUDE.md` with the tech stack, paths, key commands, and conventions.

```bash
git add -A && git commit -m "chore: ralph setup"
```

### Run the loop

```bash
./.opencode/ralph-scripts/ralph-loop.sh
```

Ralph asks you to confirm the task summary, then starts the first iteration.

### What happens, iteration by iteration

**Iteration 1:** Fresh context. Ralph reads `RALPH_TASK.md`, finds the first `[ ]`. Creates `pyproject.toml`, `src/__init__.py`, directory structure. Marks `[x]`. Commits `feat: create project structure`. Context is at maybe 15k tokens — well under the 70k warning threshold. Loop rotates to fresh context.

**Iteration 2:** Fresh context. Reads `RALPH_TASK.md`, sees first box is `[x]`, finds the second `[ ]`. Reads `CLAUDE.md` for function signatures. Implements `add`, `sub`, `mul`, `div` with type hints in `src/calculator.py`. Marks `[x]`. Commits `feat: implement core arithmetic functions`. Loop rotates.

**Iteration 3:** Writes pytest tests in `tests/test_calculator.py`. Runs `pytest --cov=src --cov-fail-under=100`. If it passes, marks `[x]` and commits. If it doesn't pass, updates `.ralph/guardrails.md` with the failure and tries to fix on the same iteration.

**Iteration 4:** Implements `src/cli.py` with argparse. Runs `python -m src.cli 10 add 5` and verifies it outputs `15` with nothing else. Marks `[x]`. Commits `feat: implement CLI`.

**Iteration 5:** Writes README. Marks `[x]`. Commits `docs: add README`.

**Iteration 6:** All boxes are `[x]`. Ralph outputs its completion signal. Loop exits cleanly.

### What you see in activity.log during the run

```
[12:34:56] 🟢 READ RALPH_TASK.md (45 lines, ~1.8KB)
[12:34:57] 🟢 READ CLAUDE.md (30 lines, ~1.2KB)
[12:35:02] 🟢 WRITE src/calculator.py (40 lines, 1.6KB)
[12:35:08] 🟢 SHELL uv run pytest → exit 0
[12:35:10] 🟢 TOKENS: 28,450 / 80,000 (36%)
[12:35:11] 🟢 WRITE RALPH_TASK.md (45 lines — checkbox updated)
```

### If something goes wrong

Say the CLI outputs `Result: 15` instead of just `15`. The verify step fails (or you notice it in the log). Ralph writes a Sign to `.ralph/guardrails.md`:

```markdown
### Sign: CLI output format
- **Trigger**: Writing CLI output
- **Instruction**: Output ONLY the number. No "Result:" prefix, no labels, no newlines.
- **Added after**: Iteration 4 — verify failed because CLI printed "Result: 15"
```

On the next iteration, Ralph reads guardrails first and gets it right. You don't need to touch anything — the learning loop handles it.

### After completion

```bash
# Verify manually
uv run pytest -v
uv run python -m src.cli 10 add 5   # Should output: 15
uv run python -m src.cli 10 div 0   # Should raise ZeroDivisionError

# Review what was built
git log --oneline
cat .ralph/guardrails.md   # Signs Ralph learned during the run
```

---

## 8. Monitoring a Running Loop

### Opencode (four-terminal approach)

**Terminal 1 — The loop itself:**
```bash
./.opencode/ralph-scripts/ralph-loop.sh
```

**Terminal 2 — Real-time activity:**
```bash
tail -f .ralph/activity.log
```

This shows every file read, write, and shell command, with token health indicators. This is your primary monitoring view.

**Terminal 3 — Git commits rolling in:**
```bash
watch -n 10 'git log --oneline -10'
```

Commits are the clearest sign of progress. No new commits for 5+ minutes is a warning sign.

**Terminal 4 — Errors and gutter detection:**
```bash
tail -f .ralph/errors.log
```

Usually empty. If it fills up, something is stuck.

### Pi (inline TUI monitoring)

In Pi, monitoring is built into the interface. Add `tab-status` to see session health at a glance in terminal tabs. Add `/usage` to check token and cost stats during a run.

To see git progress alongside Pi:
```bash
# In a separate terminal
watch -n 10 'git log --oneline -10'
```

### Checkpoint progress manually

For either tool:
```bash
# Count completed checkboxes
grep -c '\[x\]' RALPH_TASK.md

# Count remaining
grep -c '\[ \]' RALPH_TASK.md

# See guardrails accumulated so far
cat .ralph/guardrails.md
```

---

## 9. Reading the Output: What Success and Failure Look Like

### Success signals

For opencode: all `[ ]` boxes become `[x]`. The loop exits with a completion message. Check `git log --oneline` — every task should have a corresponding commit.

For Pi: the ralph-wiggum skill outputs a completion phrase or the model signals done through the extension's completion detection. Tab-status shows ✅.

### Stuck signals

For opencode: gutter detection fires. `.ralph/errors.log` shows a pattern like "same command failed 3x" or "same file written 5x in 10 min." The loop halts. Check the errors log, fix or add a guardrail to `.ralph/guardrails.md`, and re-run.

For Pi: tab-status shows 🚧 (stuck). Check Pi's session output for what the model is repeating or getting wrong.

### Gutter vs. just slow

A model working on a hard task might take 2–3 iterations on one criterion. That's normal. Gutter is when it's running the exact same failing command repeatedly, or thrashing the same file. The difference shows up clearly in `activity.log` — a healthy iteration has varied file operations; a guttered iteration has the same entry repeating.

### After loop exits

Always run your verification commands manually after Ralph completes. Don't trust the loop's exit condition alone:

```bash
# Run tests
uv run pytest -v

# Run the specific verify commands from your task criteria
# Inspect git log for sensible commits
# Check RALPH_TASK.md — all boxes should be [x]
```

---

## 10. Prompt Tuning: The Core Skill

This is the most important skill to develop with Ralph. When Ralph fails, you tune the prompt. When Ralph succeeds, you study why so you can replicate it.

### The Tuning Cycle

```
1. Run Ralph
2. Observe what went wrong (check activity.log, errors.log, git diff)
3. Add ONE guardrail to the task file or guardrails.md
4. Commit the change
5. Reset to last working checkpoint (or clean state)
6. Re-run Ralph
7. Repeat until stable
```

Add one guardrail at a time. Adding five at once makes it impossible to know which one fixed the problem.

### For Opencode: Two Places to Add Signs

Signs go in two places depending on their nature. Put task-specific behavior in `.ralph/guardrails.md` (agent reads this at the start of each iteration). Put universal constraints in the `## Context` section of `RALPH_TASK.md`.

Signs format:
```markdown
### Sign: [descriptive name]
- **Trigger**: When doing X
- **Instruction**: Do Y instead
- **Added after**: Iteration N — [what went wrong]
```

### For Pi: Signs in CLAUDE.md

Pi's ralph-wiggum skill reads `CLAUDE.md` on each iteration. Add guardrails as explicit notes in a `## Known Issues` or `## Important` section:

```markdown
## Important
- CLI output must be ONLY the number. No labels, no "Result:", no extra newlines.
- Run ruff check after every file write. Fix before committing.
- Do not refactor functions from earlier phases unless a test explicitly requires it.
```

### Common Failure Modes and Their Signs

| Failure Mode | Guardrail to Add |
|---|---|
| Skips verify step | "NEVER mark a criterion complete without running its verify command" |
| Works on multiple tasks at once | "Complete EXACTLY ONE criterion per iteration. Stop after one commit." |
| Uses pip instead of uv | "Use `uv`, not `pip`, for all package operations" |
| CLI outputs extra text | "CLI output must be ONLY the result number. Nothing else. No labels." |
| Refactors code from earlier phases | "Do not touch code from previous phases unless a test explicitly requires it" |
| Writes tests without running them | "NEVER mark a test task complete without running pytest and seeing it pass" |
| Hallucinates file paths | "Run `ls` before creating files to confirm current directory" |
| Loop never finishes | Add explicit: "When ALL criteria are marked done, output exactly: TASK_COMPLETE" |
| Same error repeated | Check gutter detection; add a sign explaining how to handle that specific error |

### Prompt Length Sweet Spot

Under 50 words and Ralph goes off-script, invents tasks, ignores your structure. The sweet spot is 100–200 words for the task description. Over 500 words and the model may miss sections, especially guardrails near the bottom. If you need more than 500 words of instructions, split them between the task file (operational instructions) and `CLAUDE.md` (project conventions and memory).

---

## 11. Ansible Role Integration

### Pi Extension Role

Your `pi_extensions` Ansible role deploys the `tmustier/pi-extensions` collection. To ensure `ralph-wiggum` and the companion extensions are enabled, verify your role's settings template includes them in `~/.pi/agent/settings.json`. The relevant extensions for Ralph work are `ralph-wiggum`, `tab-status`, `agent-guidance`, and `usage-extension`.

After any role change:
```bash
cd ~/src/omarchy-playbook
ansible-playbook playbook.yml --tags pi --diff -v --ask-become-pass
```

### Adding ralph_orchestrator to Your Playbook (Optional)

Your `ralph_orchestrator` role exists in `roles/` but is not yet in `playbook.yml`. If you want ralph-orchestrator as a third option (separate Python wrapper, predates the opencode scripts), add it:

```yaml
# In playbook.yml, add after the AI tools section:
- { role: ralph_orchestrator, tags: ["ralph", "ai"] }
```

For most use cases, the opencode ralph-wiggum scripts cover what ralph-orchestrator provided. You probably don't need both.

---

## 12. MCP Integration

Your Ansible setup runs MCP servers that give the agent powerful tools. Both opencode and Pi inherit these when MCP is configured.

Your `~/src/.mcp.json` (deployed by the `claude_code` role) makes three servers available to any session under `~/src/`:

| MCP Server | What the Agent Can Do |
|---|---|
| `filesystem` | Read/write files in ~/src, ~/projects, ~/Documents |
| `ref` | Search documentation via Context7 |
| `docker` | Manage containers, inspect running services |

Your MCP servers are assumed to be running (Ansible manages them). Verify:

```bash
docker ps --format '{{.Names}}' | grep '^mcp-'
# Should show: mcp-filesystem, mcp-ref, mcp-docker
```

### MCP in Opencode

Opencode discovers `.mcp.json` in the project directory or parent directories. Since your projects live under `~/src/`, the `~/src/.mcp.json` file is picked up automatically. No additional configuration needed.

### MCP in Pi

Pi uses its own MCP configuration path. Check your `pi_coding_agent` Ansible role to confirm it deploys an MCP config for Pi. If not, you can manually add MCP server configs to Pi's settings.

---

## 13. Cost Management

### Rough Estimates

| Project | Iterations | Approximate Cost |
|---|---|---|
| Small (calculator, ~6 criteria) | 6–10 | $0.50–$2 |
| Medium (REST API, ~20 criteria) | 15–30 | $5–$20 |
| Large (full app, ~50 criteria) | 30–80 | $20–$100 |

These assume Claude Sonnet. Opencode supports free/cheaper models via the `DEFAULT_MODEL` variable in `ralph-loop.sh` — setting `DEFAULT_MODEL="zen"` uses a free model for lighter work.

### Setting Iteration Guards

For opencode, the MAX_ITERATIONS in `ralph-loop.sh` defaults to 20. Increase for larger projects, decrease if you want to run a limited batch and check progress manually:

```bash
# In .opencode/ralph-scripts/ralph-loop.sh
MAX_ITERATIONS=50   # Adjust per project
```

### Monitoring Cost in Pi

Use the `/usage` extension during a Pi ralph run to see cost, tokens, and messages by provider and model across the session.

### Overnight Budgeting

For overnight runs with opencode, set MAX_ITERATIONS conservatively (e.g. 30) so the loop stops before it spirals. Check `.ralph/activity.log` and `.ralph/errors.log` in the morning before deciding to continue.

---

## 14. Troubleshooting Reference

### opencode not found

```bash
curl https://opencode.ai/install -fsS | bash
# Then reload shell: source ~/.zshrc
which opencode
```

### Pi ralph-wiggum extension not working

```bash
# Verify extension is in settings.json
cat ~/.pi/agent/settings.json | grep ralph

# If installed via local clone, verify path exists
ls ~/pi-extensions/ralph-wiggum

# Reinstall from git if needed
pi install git:github.com/tmustier/pi-extensions
```

### MCP servers not available inside loop

```bash
# Verify containers are running
docker ps | grep mcp

# If not running
systemctl --user start mcp-filesystem.service
systemctl --user start mcp-ref.service
systemctl --user start mcp-docker.service

# Verify .mcp.json exists where expected
cat ~/src/.mcp.json
```

### Gutter detected, loop halted

```bash
# Check what pattern triggered gutter detection
cat .ralph/errors.log

# Identify the failure (same command 3x? same file written 5x?)
# Add a guardrail to .ralph/guardrails.md explaining the fix
# Then re-run
./.opencode/ralph-scripts/ralph-loop.sh
```

### Loop exits before all checkboxes complete

```bash
# Check if MAX_ITERATIONS was hit
cat .ralph/activity.log | grep "iteration"

# If hit, increase in ralph-loop.sh and re-run
# The loop continues from current checkbox state — it doesn't restart
```

### Task criteria never mark complete

The agent may be completing the work but not updating the checkbox. Add a guardrail:

```markdown
### Sign: Update checkbox after completion
- **Trigger**: After completing any criterion
- **Instruction**: Update RALPH_TASK.md immediately, changing [ ] to [x] for that criterion. Then commit.
```

### Context rotates too frequently

The agent is reading too many large files. Check `activity.log` for large READ entries. Add a guardrail telling it to use `grep` or targeted reads instead of loading entire files.

### Pi stuck indicator shows 🚧 but loop seems to be running

Tab-status timeout may be miscalibrated for a slow task. Check Pi's session output directly to see if the agent is actively working or genuinely stuck.

---

## Quick Reference Card

```
NEW PROJECT (opencode)
──────────────────────────────────────────────────
mkdir ~/src/myproject && cd ~/src/myproject
git init && git commit --allow-empty -m "init"
curl -fsSL https://raw.githubusercontent.com/agrimsingh/ralph-wiggum-opencode/main/install.sh | bash
# Write RALPH_TASK.md (checkboxes) and CLAUDE.md
git add -A && git commit -m "chore: ralph setup"

START LOOP (opencode)
──────────────────────────────────────────────────
./.opencode/ralph-scripts/ralph-loop.sh

MONITOR (opencode, four terminals)
──────────────────────────────────────────────────
tail -f .ralph/activity.log          # Terminal 2
watch -n 10 'git log --oneline -10'  # Terminal 3
tail -f .ralph/errors.log            # Terminal 4

NEW PROJECT (Pi)
──────────────────────────────────────────────────
mkdir ~/src/myproject && cd ~/src/myproject
git init && git commit --allow-empty -m "init"
# Write task file (markdown, flexible format)
# Write CLAUDE.md (or CODEX.md / GEMINI.md)
git add -A && git commit -m "chore: ralph setup"
pi  # Start Pi TUI, point at task file

WHEN RALPH FAILS
──────────────────────────────────────────────────
# Check: .ralph/activity.log and .ralph/errors.log
# Add ONE sign to .ralph/guardrails.md or CLAUDE.md
# Commit the fix
# Re-run — the loop picks up where it left off

AFTER COMPLETION
──────────────────────────────────────────────────
uv run pytest -v         # Verify manually
git log --oneline        # Review commits
cat .ralph/guardrails.md # Signs learned during run
```

---

*"I'm learnding!" — Ralph Wiggum*

*State lives in files. Context is temporary. Tune the prompt, not the model.*
