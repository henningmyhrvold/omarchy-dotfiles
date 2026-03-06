# From Idea to Shipped: A Practitioner's Manual for OpenCode and Pi

A workflow guide covering everything from the first spark of an idea through planning, building, autonomous Ralph Wiggum loops, and shipping a finished product.

---

## Part 1: The Two Tools

### OpenCode

OpenCode is an open-source AI coding agent that runs in your terminal. It supports 75+ LLM providers (Anthropic, OpenAI, Google, local models via Ollama, and more) and provides a polished TUI with two primary modes you toggle with the **Tab** key:

- **Plan mode** — read-only. The agent analyzes your codebase and describes what it *would* do, step by step, without touching any files. Safe for exploration and requirements gathering.
- **Build mode** — the default. Full access to read files, write files, edit code, and run shell commands. This is where implementation happens.

OpenCode also ships with subagents (a general-purpose research agent and a fast read-only scout), session management, undo/redo, shareable session links, and GitHub Actions integration.

### Pi

Pi (`@mariozechner/pi-coding-agent`) is a minimal, opinionated coding agent harness created by Mario Zechner. Its philosophy is radical simplicity: a system prompt under 1,000 tokens and exactly four tools — `read`, `write`, `edit`, and `bash`. Everything else is extensible through skills, prompt templates, extensions, and packages.

Pi's key concepts:

- **AGENTS.md** — project instructions loaded at startup from `~/.pi/agent/`, parent directories, and the current working directory. This is how you teach Pi about your project's conventions, build commands, and patterns.
- **SYSTEM.md** — replace or append to the default system prompt per-project.
- **Skills** — on-demand capability packages (Markdown files with instructions). Invoked via `/skill:name` or loaded automatically. Placed in `~/.pi/agent/skills/`, `.pi/skills/`, or installed via packages.
- **Prompt templates** — reusable prompts as Markdown files. Type `/name` to expand.
- **Extensions** — TypeScript modules that add custom tools, commands, keyboard shortcuts, and event handlers.
- **Packages** — bundles of extensions, skills, prompts, and themes installed via `pi install npm:package-name` or `pi install git:github.com/user/repo`.

Pi intentionally ships *without* built-in sub-agents, plan mode, permission gates, or to-do lists. The idea is that you ask Pi to build what you need, or install a package that does it your way.

### Oh-My-Pi (omp)

Oh-My-Pi is a power-user layer on top of Pi that adds features many developers expect out of the box: hash-anchored edits, LSP integration, a Python IPython kernel, browser automation, structured to-do lists, smart commits, subagents, and memory. It discovers context from `.omp`, `.claude`, `.codex`, and `.gemini` directories and supports `--smol`, `--slow`, and `--plan` model role flags for assigning different models to different tasks.

### When to Use Which

Use **OpenCode** when you want a batteries-included experience with built-in Plan/Build mode separation, multi-session support, IDE integration, and quick provider switching. Use **Pi** when you want a minimal, hackable harness where you control the entire stack and can build exactly the workflow you need through extensions and skills.

Many developers use both. OpenCode for quick interactive work, Pi for long-running autonomous loops and deeply customized workflows.

---

## Part 2: Setting Up Your Project

### Step 1: Initialize the repository

```bash
mkdir my-product && cd my-product
git init
```

### Step 2: Create your AGENTS.md

Both OpenCode and Pi read `AGENTS.md` for project context. This file lives in your project root and gets committed to git. It tells the agent about your project's architecture, conventions, build commands, and testing approach.

```markdown
# Project: My Product

## Overview
A brief description of what this project does and who it's for.

## Tech Stack
- Language: TypeScript
- Framework: Next.js 15
- Database: PostgreSQL with Drizzle ORM
- Testing: Vitest

## Build & Run
- `npm run dev` — start development server
- `npm run build` — production build
- `npm run test` — run all tests
- `npm run lint` — lint and type-check

## Conventions
- Use functional components with hooks
- All API routes go in `src/app/api/`
- Database migrations in `drizzle/migrations/`
- Every new feature needs tests before merging

## Directory Structure
- `src/app/` — Next.js app router pages and layouts
- `src/components/` — reusable UI components
- `src/lib/` — shared utilities and database client
- `src/services/` — business logic layer
```

OpenCode can generate this for you by running `opencode init` when you first open the project. In Pi, you write it yourself or ask Pi to generate one.

### Step 3: Set up Pi-specific context (if using Pi)

For Pi, you can also create project-level skills and prompt templates:

```bash
mkdir -p .pi/skills .pi/prompts
```

A useful prompt template for planning:

```markdown
<!-- .pi/prompts/plan.md -->
Analyze the current codebase and create a detailed implementation plan for:
$@

Write the plan to PLAN.md. Include:
1. What needs to be built
2. Files to create or modify
3. Dependencies needed
4. Testing strategy
5. Order of implementation (what to build first)

Do NOT implement anything. Only plan.
```

Now you can type `/plan Build user authentication with OAuth` and Pi will expand the template with your description.

---

## Part 3: The Planning Phase

Good planning is the difference between an agent that ships a product and one that burns tokens going in circles. Whether you use OpenCode or Pi, the pattern is the same: think first, build second.

### Planning with OpenCode

Press **Tab** to switch to Plan mode. You'll see an indicator in the lower-right corner confirming you're in read-only mode. Now describe what you want:

```
I'm building a task management API. It should have:
- User authentication with JWT
- Task CRUD operations
- Task categories and tags
- Due date management with reminders

How would you approach this? Break it down into phases.
```

OpenCode will analyze your project (if it already has code) and outline an approach. Give it feedback, ask it to reconsider parts, or provide reference images by dragging them into the terminal. Once you're satisfied with the plan, press **Tab** to switch back to Build mode and say:

```
Sounds good! Go ahead and implement Phase 1.
```

### Planning with Pi

Pi doesn't have a built-in plan mode, which is intentional. You have several options:

**Option A: Use a prompt template.** If you created the `/plan` template above:

```
/plan Task management API with JWT auth, CRUD, categories, due dates
```

Pi will write a `PLAN.md` file without implementing anything.

**Option B: Use oh-my-pi's plan mode.** If you have `oh-pi` installed, start pi with `--plan` to assign a planning-optimized model:

```bash
pi --plan
```

**Option C: Just tell Pi to plan.** The models are good enough now to follow instructions:

```
I need you to plan, not build. Create a PLAN.md for a task management API with
JWT auth, task CRUD, categories, and due dates. Break it into small, ordered
phases. Each phase should be independently testable. Do not write any code.
```

### What makes a good plan

Whether you're working interactively or preparing for a Ralph loop, your plan should have these qualities:

- **Small, atomic tasks.** Each task should be completable in a single agent session without hitting context limits. A task like "implement the entire auth system" is too big. "Create the JWT token generation and validation utility" is about right.
- **Clear completion criteria.** Each task should specify how to verify it's done — what tests to run, what command should succeed, what the output should look like.
- **Explicit ordering.** Dependencies between tasks should be clear. Build the database schema before the API routes that query it.
- **Feedback loops built in.** After each task: run tests, run the type checker, run the linter. If any fail, fix before moving on.

---

## Part 4: Interactive Building

### Building with OpenCode

In Build mode, OpenCode has full access to your filesystem and shell. Ask it to implement things conversationally:

```
Implement the database schema for tasks. Use Drizzle ORM with PostgreSQL.
Each task should have: id, title, description, status, category, due_date,
created_at, updated_at. Add a migration.
```

OpenCode will create files, run commands, and show you diffs. Useful commands during a session:

- **/undo** — revert changes from the last response
- **/redo** — bring reverted changes back
- **/share** — create a shareable link to your session
- **/sessions** — resume a previous conversation

If something goes wrong, you can always undo and rephrase.

### Building with Pi

Pi works similarly but with its own interaction model. Start a session in your project directory:

```bash
pi
```

Then talk to it. Pi uses `read`, `write`, `edit`, and `bash` to fulfill requests. Some useful Pi interactions:

```
# Switch models mid-session
Ctrl+L  (or /model)

# Cycle through favorite models
Ctrl+P

# Queue a follow-up message while the agent is working
Alt+Enter

# Steer the agent while it's working (delivered after current tool)
Enter (type your message and hit enter while it's running)

# Continue a previous session
pi -c

# Browse past sessions
pi -r

# Non-interactive single task
pi -p "Add input validation to all API routes"
```

Pi's extension ecosystem adds capabilities. With the packages from your Ansible role installed:

- **oh-pi** — enhanced editing, LSP, Python kernel, smart commits, subagents, and more
- **pi-hooks** — lifecycle hooks for custom automation
- **pi-context** — enhanced context management
- **pi-interview** — structured interviewing for requirements gathering
- **pi-subagents** — multi-agent orchestration
- **pi-extensions** — the tmustier collection including ralph-wiggum, usage dashboard, code actions, and arcade games while tests run

### Using Pi's /usage dashboard

With the pi-extensions package installed, type `/usage` at any time to see your token consumption, cost breakdown by provider and model, and message counts. Useful for keeping an eye on spend during long sessions.

### Using /code for code blocks

Type `/code` to get a picker for code blocks from the conversation. You can copy them to clipboard, insert them into files, or run them directly.

---

## Part 5: The Ralph Wiggum Loop — Autonomous Shipping

This is where things get powerful. The Ralph Wiggum technique, coined by Geoffrey Huntley, is an autonomous development loop that repeatedly feeds the same prompt to an AI coding agent until the task is done. Progress lives in your files and git history, not in the agent's context window. When context fills up, you get a fresh agent that picks up where the last one left off by reading the files.

### The Core Idea

Ralph is three phases and one loop:

1. **Requirements phase** (you, interactively) — define what needs to be built, identify jobs to be done
2. **Planning phase** (you + agent) — gap analysis between specs and code, output a prioritized task list
3. **Building phase** (Ralph loop, autonomous) — the loop picks tasks from the plan, implements them, runs tests, commits, and repeats

### How Ralph Works in Pi

With the ralph-wiggum skill from pi-extensions installed, Ralph is available as a skill that enables long-running development loops. The basic flow:

1. **Write your task specification** — create a file describing what Ralph should build. Be specific about completion criteria and feedback loops.

2. **Set up your AGENTS.md** with Ralph-appropriate instructions:

```markdown
## Ralph Loop Instructions
- Pick the most important remaining task from PLAN.md
- Implement it in small steps
- After each change: run `npm test`, `npm run lint`, `npm run typecheck`
- Do NOT commit if any feedback loop fails. Fix issues first.
- When a task is complete, update PLAN.md to mark it done
- Commit with a conventional commit message
- Move to the next task
```

3. **Start the loop.** The simplest Ralph is a bash loop:

```bash
#!/bin/bash
# ralph.sh
PROMPT="Read PLAN.md. Pick the most important incomplete task.
Implement it. Run tests. If tests pass, commit and move on.
If all tasks are done, create a file called DONE."

while [ ! -f DONE ]; do
    pi -p "$PROMPT"
    sleep 2
done
echo "Ralph is done!"
```

4. **Run it and walk away:**

```bash
chmod +x ralph.sh
./ralph.sh
```

Each iteration gets a fresh context. Pi reads the files, sees what's been done (via git log and the PLAN.md), picks the next task, implements it, and exits. The loop starts it again.

### Ralph Tips for Success

**Keep tasks small.** Each Ralph iteration has startup costs — the agent must orient itself, read files, and gather context. If a task is too large, it won't finish in one iteration and will leave a mess. Bias toward tasks that can be completed in under 10 minutes of agent time.

**Build in feedback loops.** Every task should end with running tests, linting, and type-checking. Add this to your prompt:

```
After every change:
1. Run `npm test` — all tests must pass
2. Run `npm run lint` — no errors
3. Run `npm run typecheck` — no type errors
Do NOT commit if any step fails. Fix the issue first.
```

**Use git as the memory layer.** Ralph doesn't remember across iterations — git does. Each iteration can run `git log --oneline -10` to see what was recently done.

**Tackle hard things first.** Without guidance, Ralph will pick the easiest task. In your PLAN.md, either number tasks in priority order or add explicit instructions like "implement in this order."

**AFK vs. HITL.** For AFK (away-from-keyboard) Ralph, keep tasks very small and add extra guardrails. For HITL (human-in-the-loop) Ralph where you're watching, you can use slightly larger tasks and intervene when the agent goes off track.

**Cap your iterations.** Add a safety limit to prevent runaway loops:

```bash
MAX_ITERATIONS=20
ITERATION=0

while [ ! -f DONE ] && [ $ITERATION -lt $MAX_ITERATIONS ]; do
    pi -p "$PROMPT"
    ITERATION=$((ITERATION + 1))
    echo "Completed iteration $ITERATION of $MAX_ITERATIONS"
    sleep 2
done
```

### Running Ralph with OpenCode

OpenCode can also be used in Ralph loops using its non-interactive mode:

```bash
while [ ! -f DONE ]; do
    opencode -p "Read PLAN.md. Pick the next incomplete task. Implement it. Run tests. Commit if passing. Mark done in PLAN.md. If all tasks complete, create DONE file."
    sleep 2
done
```

### Parallel Ralph Loops

For larger projects, you can run multiple Ralph loops in parallel on different branches:

```bash
# Create isolated worktrees
git worktree add ../my-product-auth -b feature/auth
git worktree add ../my-product-api -b feature/api

# Terminal 1: Auth feature
cd ../my-product-auth
# (start ralph loop with auth-specific PLAN.md)

# Terminal 2: API feature
cd ../my-product-api
# (start ralph loop with api-specific PLAN.md)
```

Each worktree is isolated, so the agents can't step on each other's work.

### Cross-Model Review

A powerful extension of the Ralph pattern uses one model to build and a different model to review:

```bash
#!/bin/bash
# ralph-with-review.sh

while [ ! -f DONE ]; do
    # Work phase — use a fast model
    pi --model sonnet -p "Read PLAN.md. Implement the next task. Run tests. Write a summary to WORK_SUMMARY.md."

    # Review phase — use a strong model
    pi --model opus -p "Read PLAN.md and WORK_SUMMARY.md. Review the changes. If the work is complete and correct, write APPROVED to REVIEW_RESULT.md. If not, write specific feedback to REVIEW_FEEDBACK.md."

    if grep -q "APPROVED" REVIEW_RESULT.md 2>/dev/null; then
        git add -A && git commit -m "feat: $(head -1 WORK_SUMMARY.md)"
        rm -f WORK_SUMMARY.md REVIEW_RESULT.md REVIEW_FEEDBACK.md
    fi

    sleep 2
done
```

---

## Part 6: Shipping

### Pre-ship Checklist

Before you merge Ralph's work, review it like you would any developer's output:

1. **Read the git log.** `git log --oneline` shows you every commit Ralph made. Each should be a clean, atomic change.
2. **Run the full test suite.** `npm test` — Ralph should have been doing this, but verify.
3. **Review the diff.** `git diff main..feature/your-branch` — look for anything that seems off.
4. **Check for leftover artifacts.** Files like `DONE`, `PLAN.md`, `WORK_SUMMARY.md`, or `REVIEW_FEEDBACK.md` should be cleaned up before merging.
5. **Run a final code review.** Use Pi's sub-agent pattern or OpenCode's read-only mode:

```bash
# Pi code review via sub-agent
pi -p "Review all changes on this branch compared to main. Check for bugs, security issues, and code quality problems. Be thorough."

# OpenCode in Plan mode — Tab to Plan, then:
# "Review all uncommitted changes. Look for bugs and security issues."
```

### Merging and Deploying

Once you're satisfied:

```bash
git checkout main
git merge feature/your-branch
git push origin main
```

If your project has CI/CD set up, the push triggers your pipeline. If you're using OpenCode's GitHub integration, you can even mention `/opencode` in a PR comment to have it review or make changes within your GitHub Actions runner.

---

## Part 7: Quick Reference

### OpenCode Keybindings

| Key | Action |
|-----|--------|
| Tab | Toggle between Plan / Build / other modes |
| Ctrl+T | Cycle thinking levels (Low / Medium / High) |
| Ctrl+K | Open provider selector |
| /undo | Revert last changes |
| /redo | Restore reverted changes |
| /share | Create shareable session link |
| /sessions | Resume a previous session |
| /init | Generate AGENTS.md for your project |

### Pi Keybindings

| Key | Action |
|-----|--------|
| Ctrl+L | Open model selector |
| Ctrl+P | Cycle favorite models |
| Enter | Send steering message (while agent is working) |
| Alt+Enter | Queue follow-up message |
| Escape | Abort current operation |
| / | Trigger command/skill/template menu |

### Pi CLI Flags

| Flag | Description |
|------|-------------|
| `pi` | Start interactive session |
| `pi -p "prompt"` | Non-interactive, single prompt |
| `pi -c` | Continue most recent session |
| `pi -r` | Browse and resume past sessions |
| `pi --model sonnet` | Use a specific model |
| `pi --thinking high` | Set thinking level |
| `pi --no-session` | Ephemeral mode |

### Pi Extensions (from your Ansible roles)

| Package | What it provides |
|---------|-----------------|
| `oh-pi` | LSP, Python kernel, smart commits, enhanced editing |
| `pi-hooks` | Lifecycle hooks for custom automation |
| `pi-context` | Enhanced context management |
| `pi-interview` | Structured requirements interviews |
| `pi-subagents` | Multi-agent orchestration |
| `pi-extensions` | Ralph Wiggum skill, `/usage` dashboard, `/code` picker, arcade games, agent-guidance, file browser, tab status |
| `@aliou/pi-guardrails` | Safety guardrails for autonomous runs |

### The Ralph Workflow Summary

```
 YOU                          AGENT                         GIT
  │                             │                            │
  ├─ Define requirements ──────►│                            │
  ├─ Create PLAN.md ───────────►│                            │
  │                             │                            │
  │   ┌─── Ralph Loop ─────────┤                            │
  │   │  Read PLAN.md          │                            │
  │   │  Pick next task        │                            │
  │   │  Implement             │                            │
  │   │  Run tests ────────────┤                            │
  │   │  Tests pass? ──────────┤──── git commit ───────────►│
  │   │  Update PLAN.md        │                            │
  │   │  Exit (context fresh)  │                            │
  │   └────────────────────────┤                            │
  │         (loop restarts)    │                            │
  │                             │                            │
  ├─ Review git log ◄──────────┤────────────────────────────┤
  ├─ Code review ──────────────►│                            │
  ├─ Merge & deploy ───────────┤───────────────────────────►│
  │                             │                            │
```
