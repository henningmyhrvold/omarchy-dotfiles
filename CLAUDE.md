# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

Personal dotfiles and one-shot customization scripts for an Arch Linux workstation running **Omarchy**. This repo holds no build system, no tests, and no application code — it is configuration plus bash. The companion repo `~/src/omarchy-playbook` is the Ansible playbook that consumes parts of it.

There is no entry point that provisions the whole repo. Different directories are consumed by completely different mechanisms, and knowing which is which is the main thing to understand before editing.

## The three consumption paths

**1. Symlinked by Ansible.** Only two directories are wired into the playbook:

- `zsh/` — `roles/dotfiles` symlinks `zsh/.zshrc`, `zsh/.zsh_profile`, `zsh/.p10k.zsh` into `$HOME`. The list lives in the playbook's `config.yml` under `dotfiles_links`, not here.
- `skills/` — `roles/skills` discovers every `skills/*/SKILL.md`, then symlinks each skill *directory* into both `~/.claude/skills/` and `~/.pi/agent/skills/`, and prunes stale symlinks whose source no longer exists.

Both roles clone this repo to `~/src/omarchy-dotfiles` with `force: false, update: false` — Ansible creates the checkout once and then never pulls over it. Your working copy is authoritative; the playbook will not overwrite local edits.

**2. Run by hand, once.** `scripts/omarchy-mods-*.sh` are manual post-install mods. Nothing invokes them automatically — not Ansible, not Omarchy. `omarchy-mods-first-time.sh` is the closest thing to an orchestrator: it installs themes, copies the theme-set hook, then `bash`-invokes waybar → hyprland-global → branding → cleanup in that order.

**3. Installed into Omarchy's own extension points.** `omarchy-hooks/theme-set` is copied into `~/.config/omarchy/hooks/theme-set.d/` and run by `omarchy-hook` on every theme change.

`ghostty/`, `logo/`, `wallpapers/`, `mcp/`, and `ai_tips/` are referenced by scripts or copied manually. Nothing automates them.

## Architecture: why the scripts look the way they do

Omarchy owns the desktop and regenerates its configs. This repo's central problem is **reapplying personal preferences after Omarchy overwrites them**, and it solves that two different ways:

- **Theme changes** wipe per-app config. `omarchy-hooks/theme-set` re-asserts non-color preferences (padding, opacity, font size, `command = zsh`, mako rules) after every theme switch. It writes *delimited blocks* — `# >>> user-overrides >>>` … `# <<< user-overrides <<<` — via an `awk` upsert so the block is replaced in place rather than appended repeatedly. This is why the hook is safe to re-run and why you must keep the markers intact when editing.
- **One-time system state** (branding, removed packages, input config) is handled by `scripts/`, which patch Omarchy's generated files in place with `sed`.

That `sed`-patching approach is inherently coupled to Omarchy's file formats and paths. When Omarchy changes a config format, these scripts break silently or corrupt the target. Treat every script as version-specific to the Omarchy release it was written against.

## Conventions to match

- **Back up before mutating.** Every script that edits a system file first copies it to `<file>.backup-$(date +%Y%m%d-%H%M%S)` (or `.bak`) and prints the path. `omarchy-mods-waybar.sh` uses `sed -i.backup` for the same effect.
- **Detect format, don't assume it.** `omarchy-mods-hyprland-global.sh` is the model: it probes for `input.lua` before `input.conf` and dispatches to `update_lua()` or `update_conf()`. New scripts touching Hyprland config should do the same.
- **`set -e` everywhere**, which makes the `first-time.sh` chain fail-fast: any sub-script that exits non-zero aborts the whole run and the later scripts never execute. Consider that when ordering work or when a target file may legitimately be absent.
- **Idempotency by grep-then-branch.** Scripts check whether a key is already present (and whether it is commented out) before deciding to rewrite versus insert.
- **Skills use gerund naming** — `brainstorming/`, `writing-plans/`, `systematic-debugging/`. Each needs a `SKILL.md` with YAML frontmatter (`name`, `description`); supporting `.md`/`.sh`/`.ts` files sit alongside it in the same directory and are symlinked with it.

## Gotchas

- **Hardcoded username.** `zsh/.zshrc` hardcodes `/home/henning/go` and `/home/henning/.npm-global`; `mcp/mcphub.json` hardcodes `/home/henning/.config/mcp/`. Most scripts correctly use `$HOME`. The playbook's `rename.sh` does not reach into this repo.
- **`zsh/.zshrc` prepends `~/.npm-global/bin` to PATH at the very end of the file**, so it wins over anything Omarchy or mise sets up. This is deliberate today but collides with Omarchy 4's mise-managed tooling — see `PLAN.md`.
- **`.gitignore` excludes `.claude/` and lowercase `.claude.md`**, not `CLAUDE.md`. This file is tracked.
- **`scripts/omarchy-mods-spectra-theme.sh` is commented out** of `first-time.sh` and targets a separate repo (`henningmyhrvold/omarchy-spectra-theme`) installed into `~/.config/omarchy/themes/spectra/`.
- **`mcp/` is vestigial.** The playbook's MCP container roles were deleted in its commit `4d3e6e7`; nothing consumes `docker-compose.mcp.yml`, `hub.json`, or `mcphub.json` any more.
- **`ai_tips/` is reference material**, not config — notes and a sample project scaffold for Ralph/Pi agent workflows. Nothing symlinks it.

## Omarchy version coupling

The scripts were written against **Omarchy 3.x**. Omarchy 4 ("Quattro") changes Hyprland config to Lua, replaces Waybar with a Quickshell bar, and drops Mako, Walker, and SwayOSD. Several scripts here break outright on Quattro.

**Read `PLAN.md` before touching anything under `scripts/` or `omarchy-hooks/`** — it documents exactly which files break, why, and what replaces them.
