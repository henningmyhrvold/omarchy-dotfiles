# PLAN.md — Migrating omarchy-dotfiles to Omarchy 4 "Quattro"

**Status:** planning only. Only `PLAN.md` and `CLAUDE.md` were created; nothing else in this repo was changed.

**Baseline:** this laptop runs Omarchy **3.8.4**. **Target:** Omarchy **4.0.0.alpha** (`quattro` branch), now in beta.

**Companion plan:** `~/src/omarchy-playbook/PLAN.md` covers the Ansible side. A few items here are two halves of the same change and are cross-referenced.

**Decisions taken:**

| # | Decision |
|---|---|
| 1 | **Stay on Ghostty.** `omarchy-install-terminal` still supports it. |
| 2 | **Port the bar logo** to Quattro's Quickshell bar rather than dropping it. |
| 3 | **Spectra theme: flag as blocked**, minimal detail — porting spec deferred to that repo. |

---

## 1. Verification method

Every claim below was checked against Quattro sources, not release notes:

- Full `quattro` file tree via the GitHub API (1,394 blobs); `bin/` diffed against this machine's live 3.8.4 `bin/`.
- Individual files fetched raw via the jsDelivr GitHub mirror (`raw.githubusercontent.com` 403s here).
- `install/omarchy-base.packages` diffed against the local 3.8.4 manifest.
- Local state inspected directly (`~/.config/omarchy/`, `~/.config/hypr/`, the installed spectra theme).

Where something could not be confirmed without a running Quattro system, it is marked **VERIFY ON QUATTRO** rather than asserted.

---

## 2. Impact summary

| File | Verdict |
|---|---|
| `scripts/omarchy-mods-waybar.sh` | **Broken** — target file no longer exists; needs full rewrite (§3.1) |
| `scripts/omarchy-mods-hyprland-global.sh` | **Broken** — Lua branch emits invalid Lua (§3.2) |
| `scripts/omarchy-mods-cleanup.sh` | **Broken** — 5 packages absent, bindings format changed, 2 webapps gone (§3.3) |
| `scripts/omarchy-mods-first-time.sh` | **Broken** — pre-existing `cp` failure aborts the chain (§3.4) |
| `omarchy-hooks/theme-set` | **Partly dead** — mako block obsolete (§3.5) |
| `zsh/.zshrc` | **Conflicts** — PATH shadows mise; two stale plugins/aliases (§3.6) |
| `scripts/omarchy-mods-spectra-theme.sh` | **Blocked** — theme format incompatible (§3.7) |
| `scripts/omarchy-mods-branding.sh` | **Works**, one fix needed (§4.1) |
| `scripts/omarchy-mods-alacritty.sh` | **Redundant** (§5) |
| `ghostty/config` | **Works** — keep per decision #1 (§4.2) |
| `mcp/` | **Dead** — unrelated to Quattro (§5) |
| `skills/`, `ai_tips/`, `wallpapers/`, `logo/` | **Unaffected** |

---

## 3. Blocking breakages

### 3.1 `omarchy-mods-waybar.sh` — Waybar no longer exists

Quattro deletes Waybar entirely; the bar is a Quickshell plugin. `~/.config/waybar/config.jsonc` will not exist, so the script hits its guard and exits 1 — which also aborts `first-time.sh` (§3.4).

**Where the logo actually lives now.** It is *not* a `shell.json` setting. It is hardcoded in the menu plugin's bar widget, `shell/plugins/menu/BarWidget.qml`:

```qml
WidgetButton {
  text: ""
  fontFamily: "omarchy"
  ...
}
```

That is the same private-use glyph and the same `omarchy` font the old Waybar config used (`<span font='omarchy'></span>`) — the mechanism moved, the asset did not.

`~/.config/omarchy/shell.json` controls only *which* widgets appear and in what order:

```json
"bar": { "layout": { "left": [ { "id": "omarchy.menu" }, { "id": "omarchy.workspaces" } ] } }
```

**Do not** edit `/usr/share/omarchy/shell/plugins/menu/BarWidget.qml`. It is package-owned and will be reverted by the next `omarchy-update`.

**The supported route** is a user bar-widget plugin:

1. Create a plugin with a `manifest.json` declaring `"kinds": ["bar-widget"]` and a `barWidget` entry point, mirroring `shell/plugins/menu/manifest.json`.
2. Its `BarWidget.qml` copies the stock one but substitutes the Arch glyph — `text: ""` with a Nerd Font family rather than `"omarchy"` — and keeps the same `onPressed` handlers (left = `omarchy-shell shell toggle omarchy.menu`, right = `xdg-terminal-exec`).
3. Install with `omarchy plugin add <git-url> --enable`; plugins live in `~/.config/omarchy/plugins/<id>/`.
4. Swap `omarchy.menu` for your plugin id in the `bar.layout.left` array of `~/.config/omarchy/shell.json`.

**Caveat:** replacing `omarchy.menu` in the layout may disable the stock menu launcher, since the manifest sets `"allowMultiple": false` and `"keepLoaded": true`. **VERIFY ON QUATTRO** that the menu still opens on `Super+Space` with your widget substituted; if not, keep `omarchy.menu` in the layout and accept the stock glyph, or investigate whether the font itself can be overridden per-theme.

Rewrite the script to edit `shell.json` with `jq` (it is JSON, not JSONC — no comment-stripping needed) and drop the `pkill waybar` advice in favour of `omarchy-restart-shell`.

### 3.2 `omarchy-mods-hyprland-global.sh` — the Lua branch produces invalid Lua

The script already auto-detects `input.lua` vs `input.conf`, which was good foresight. But `update_lua()` is wrong for Quattro's actual file, and the failure is silent until Hyprland reloads.

Quattro ships `config/hypr/input.lua` with **everything commented out**, wrapped in a function call:

```lua
-- hl.config({
--   input = {
--     kb_layout = "us,dk,eu",
--     kb_options = "compose:caps,shift:both_capslock_cancel,grp:alts_toggle",
--     touchpad = {
--       natural_scroll = true,
--     },
--   },
-- })
```

Trace the script against that file:

1. `key_present "kb_layout"` matches — its regex allows an optional leading `--`.
2. `key_active "kb_layout"` does **not** match — the line starts with `--`.
3. So `rewrite_first` takes the else branch and rewrites the *first commented* occurrence, stripping the `--`.

The result is a single uncommented statement stranded inside a still-commented block:

```lua
-- hl.config({
--   input = {
    kb_layout = "us,no",
--     kb_options = ...
```

That is a syntax error at file scope (`unexpected symbol near '='`), not merely an ineffective edit. The same happens for `kb_options` and `natural_scroll`. On a fresh Quattro install this script will break Hyprland's input config.

**Fix direction.** Stop trying to sed individual keys inside a commented template. Because Quattro's file is *entirely* a commented example, the correct behaviour is to **append a complete, well-formed `hl.config({...})` block** at the end of the file:

```lua
-- >>> user-overrides >>>
hl.config({
  input = {
    kb_layout = "us,no",
    kb_options = "grp:alt_shift_toggle",
    touchpad = { natural_scroll = true },
  },
})
-- <<< user-overrides <<<
```

Reuse the delimited-block upsert already proven in `omarchy-hooks/theme-set` so re-runs replace rather than duplicate. Keep `update_conf()` untouched for the 3.x path, or delete it once you have cut over.

**VERIFY ON QUATTRO:** that `hl` is in scope at the end of `input.lua` and that later `hl.config` calls override earlier ones rather than erroring on duplicate keys.

### 3.3 `omarchy-mods-cleanup.sh` — three separate breakages

**(a) Five of ten packages are no longer installed**, so `pacman -Rns` errors with "target not found" and `set -e` aborts the script:

| Package | Quattro base |
|---|---|
| `1password-beta` | **absent** — the Quattro upgrade installs `1password` instead; name changed |
| `1password-cli` | **absent** |
| `spotify` | **absent** — now an on-demand `omarchy-install-service-spotify` |
| `typora` | **absent** |
| `wiremix` | **absent** |
| `kdenlive`, `localsend`, `obs-studio`, `pinta`, `xournalpp` | still shipped |

Fix by filtering to installed packages before removing:

```bash
to_remove=()
for p in "${PACKAGES[@]}"; do pacman -Qq "$p" &>/dev/null && to_remove+=("$p"); done
((${#to_remove[@]})) && sudo pacman -Rns --noconfirm "${to_remove[@]}"
```

**(b) The Hyprland bindings file changed format.** `BINDINGS_FILE="$HOME/.config/hypr/bindings.conf"` becomes `bindings.lua`. The `sed` regex matches `^bindd = ...` lines, which do not exist in Lua. The block is guarded by `[[ -f "$BINDINGS_FILE" ]]`, so it **fails silently** — no error, no removal. Rewrite against the Lua binding syntax in `config/hypr/bindings.lua`, or drop this block and remove the webapp bindings by removing the webapps themselves.

**(c) Two webapps no longer exist.** Quattro's `applications/` has no `Figma.desktop` or `Fizzy.desktop`. New defaults you may also want to strip: `ChatGPT`, `Discord`, `Google Maps`, `YouTube`, `Docker`. **VERIFY ON QUATTRO** whether `omarchy webapp remove` errors on an unknown name — if it does, this aborts the script too.

**Good news:** the command surface survives. `omarchy-install-terminal`, `omarchy-default-terminal`, `omarchy-webapp-remove`, and `omarchy-tui-remove` all still exist in Quattro, and `omarchy-install-terminal` still accepts `ghostty`. The `"Disk Usage"` TUI still ships. Per decision #1, the terminal-switching lines stay as they are.

### 3.4 `omarchy-mods-first-time.sh` — already broken today

Line:

```bash
cp ~/src/omarchy-dotfiles/omarchy-hooks/theme-set ~/.config/omarchy/hooks/theme-set.d/
```

`~/.config/omarchy/hooks/theme-set.d/` **does not exist on this machine** — the hooks directory contains `theme-set` as a plain file plus `.sample` files and a `post-boot.d/`. `cp` to a non-existent directory fails, and `set -e` aborts the script before the customizations section ever runs. The hook currently installed at `~/.config/omarchy/hooks/theme-set` must have been placed there by hand.

This is a **pre-existing bug, not a Quattro regression** — fix it independently of the migration. `omarchy-hook` runs both `hooks/<name>` and every file in `hooks/<name>.d/`, so either location works; just create the directory first:

```bash
mkdir -p ~/.config/omarchy/hooks/theme-set.d
cp ~/src/omarchy-dotfiles/omarchy-hooks/theme-set ~/.config/omarchy/hooks/theme-set.d/
```

The hook directory layout is unchanged in Quattro — `config/omarchy/hooks/theme-set.d/show-theme-notification.sample` still ships, and the hook still receives the snake-cased theme name as `$1`.

Also reconsider the `set -e` fail-fast chain: with §3.1 unfixed, waybar aborts the run and branding/cleanup silently never execute. Prefer running each sub-script under an explicit failure guard so one broken mod does not mask the rest.

### 3.5 `omarchy-hooks/theme-set` — mako block is dead

The hook mechanism itself survives Quattro intact. Two of its three blocks need attention:

- **`~/.config/mako/config` — remove.** Mako is gone from Quattro; notifications are handled by the Quickshell shell. The trailing `pkill -SIGUSR2 mako` becomes a no-op. Notification styling (width, position, timeout, the Spotify/DND rules) must be re-expressed against the Quickshell notification plugin — **VERIFY ON QUATTRO** what is configurable via `shell.json` or `omarchy plugin`.
- **`~/.config/alacritty/alacritty.toml` — keep, conditionally.** Alacritty is no longer installed by default but is still an approved terminal, and Quattro still ships `config/alacritty/alacritty.toml`. Harmless if the file is absent (the helper `touch`es it), but it will create a config for a terminal you do not have. Guard it on the binary existing.
- **`~/.config/ghostty/config` — keep as-is** per decision #1. Quattro still ships `config/ghostty/config`, so the path is valid.

**Worth adopting: Quattro's user-template system.** `~/.config/omarchy/themed/*.tpl` files are rendered with the active theme's palette (`{{ background }}`, `{{ foreground }}`, `{{ color0 }}`–`{{ color15 }}`, plus `_strip` and `_rgb` modifiers) and **take priority over Omarchy's built-in templates**. That directory already exists on this 3.x box. Your hook handles *non-color* preferences (padding, opacity, font size, `command = zsh`), which templates are not for — so keep the hook — but if you ever want color-derived config, templates are the supported mechanism and avoid the overwrite race entirely. Quattro also expands themes from 8 to 24 colors.

### 3.6 `zsh/.zshrc` — PATH shadowing and stale entries

**PATH conflict (cross-repo).** The last line is:

```sh
export PATH="/home/henning/.npm-global/bin:$PATH"
```

Quattro *appends* `~/.local/bin` and runs `mise activate`, then installs coding agents (`claude`, `codex`, `gemini`, `pi`, `opencode`) as lazy mise shims in `~/.local/bin`. Because this line prepends at the very end of `.zshrc`, `~/.npm-global/bin` wins over both. You would run npm-pinned agents while believing Omarchy manages them.

The playbook plan's decision #2 (**mise owns agent binaries, Ansible owns config**) requires removing this line — the playbook removes the equivalent `.bashrc` line, and this is the zsh half of the same change. Keep the `GOPATH`/`GOBIN` exports; only the npm-global line goes.

**Also stale:**

- `plugins=(git asdf zsh-autosuggestions)` — the oh-my-zsh **asdf** plugin. Omarchy has used `mise` since 3.x and Quattro ships no `asdf`; this plugin is already a no-op. Replace with mise's own activation if you want shell integration.
- `alias ls='lsd -a'` — `lsd` is not in Quattro's base (nor 3.8.4's; Omarchy ships `eza`). Either install `lsd` explicitly or switch the alias to `eza`.
- `source ~/.local/share/omarchy/default/bash/aliases` — still works on Quattro, because that path becomes a symlink to `/usr/share/omarchy`. Prefer `"$OMARCHY_PATH/default/bash/aliases"`, which Quattro exports and which survives any future layout change.
- `bindkey -s ^f "tmux-sessionizer\n"` — `tmux-sessionizer` is not provided by this repo or by Omarchy. **VERIFY** it is still on PATH after the upgrade.

### 3.7 `omarchy-mods-spectra-theme.sh` — blocked on the theme repo

Per decision #3, this section is a flag rather than a porting spec.

The script patches `~/.config/omarchy/themes/spectra/hyprland.conf` and `ghostty.conf`. The installed spectra theme currently contains:

```
alacritty.toml  btop.theme  chromium.theme  eza.yml  ghostty.conf  gtk.css
hyprland.conf   hyprlock.conf  icons.theme  kitty.conf  mako.ini
neovim.lua      swayosd.css  walker.css  waybar.css  backgrounds/
```

A Quattro theme looks nothing like that — `colors.toml`, `shell.lock.toml`, `neovim.lua`, `vscode.json`, `icons.theme`, `keyboard.rgb`, `backgrounds/`. Obsolete in Quattro: `hyprland.conf`, `ghostty.conf`, `alacritty.toml`, `kitty.conf`, `mako.ini`, `walker.css`, `waybar.css`, `swayosd.css`, `hyprlock.conf`, `gtk.css`, `btop.theme`, `eza.yml`. Themes are now **colors-only** with a 24-color palette; per-app config is generated from templates.

**Consequences:**

- `henningmyhrvold/omarchy-spectra-theme` must be ported before `omarchy-theme-install` will produce a usable theme on Quattro. Separate repo, separate task.
- `omarchy-mods-spectra-theme.sh` is unsalvageable as written — its Hyprland blur/gaps edits belong in `~/.config/hypr/looknfeel.lua` and its Ghostty edits already duplicate the theme-set hook. **Delete it** and fold anything still wanted into §3.2's block or the hook.
- Remove or update the `omarchy-theme-install` line in `first-time.sh` until the theme is ported. `omarchy-theme-install` itself still exists in Quattro. The second theme (`bjarneo/omarchy-pulsar-theme`) has the same problem and is not yours to fix.

---

## 4. Works, but needs a fix

### 4.1 `omarchy-mods-branding.sh` — paths survive, initramfs command does not

Both targets remain valid on Quattro:

- `~/.config/omarchy/branding/screensaver.txt` — still used; `omarchy-branding-screensaver` reads and resets it.
- `/usr/share/plymouth/themes/omarchy/logo.png` — still the Plymouth theme path.

**The fix:** the script ends with `sudo mkinitcpio -P`. Quattro's own `omarchy-refresh-plymouth` does:

```bash
if omarchy-cmd-present limine-mkinitcpio; then
  sudo limine-mkinitcpio
else
  sudo mkinitcpio -P
fi
```

Omarchy installs `limine`, `limine-mkinitcpio-hook`, and `limine-snapper-sync`. On a Limine system, plain `mkinitcpio -P` may not update the boot entry. Mirror Omarchy's conditional.

**New hazard:** Quattro adds `omarchy-refresh-plymouth`, `omarchy-plymouth-set`, `-list`, and `-set-by-theme`. `omarchy-refresh-plymouth` does `cp -r "$OMARCHY_PATH/default/plymouth/." /usr/share/plymouth/themes/omarchy/`, which **overwrites your custom logo**. The script's closing note already warns that major upgrades revert it; now a routine command does too. Re-run branding after any plymouth refresh or theme-driven plymouth change.

### 4.2 `ghostty/config` — keep

Per decision #1. Quattro still ships `config/ghostty/config` and `omarchy-install-terminal ghostty` still works, so no change is required.

Two notes. Ghostty is no longer in the base manifest, so it is installed on demand — confirm `omarchy-pkg-add ghostty` resolves after the upgrade. And Quattro adds `omarchy-theme-set-foot` but has no ghostty equivalent, meaning **theme color application for Ghostty may now depend on a `themed/` template** rather than a shipped `ghostty.conf`. **VERIFY ON QUATTRO** that Ghostty still retints on theme change; if not, add `~/.config/omarchy/themed/ghostty.config.tpl` using the template variables from §3.5.

Note this repo's `ghostty/config` is not symlinked by Ansible — it is a reference copy. The live file is `~/.config/ghostty/config`, which the theme-set hook appends its override block to.

---

## 5. Redundant — delete candidates

- **`scripts/omarchy-mods-alacritty.sh`** — writes a `NoDisplay=true` desktop entry to hide Alacritty from the menu. Alacritty is not installed on Quattro, so this creates a phantom entry for a nonexistent app. Delete unless you install Alacritty deliberately.
- **`mcp/`** (`docker-compose.mcp.yml`, `hub.json`, `mcphub.json`) — dead since the playbook deleted its MCP container roles in commit `4d3e6e7`. `hub.json` is already an empty server list, and `mcphub.json` hardcodes `/home/henning/.config/mcp/`. Unrelated to Quattro; delete while you are here. The playbook's `config.yml` also still creates `~/.config/mcp` and `~/.config/Claude` — see its plan §4.
- **`scripts/omarchy-mods-spectra-theme.sh`** — see §3.7.

**Keep unchanged:** `skills/` (agent-consumed, Omarchy-agnostic), `ai_tips/` (reference notes), `wallpapers/`, `logo/`, `zsh/.p10k.zsh`, `zsh/.zsh_profile`.

---

## 6. Cross-repo coupling

Two items are halves of a single change and must land together, or agents/PATH end up inconsistent:

| This repo | omarchy-playbook |
|---|---|
| Remove the `~/.npm-global/bin` line from `zsh/.zshrc` (§3.6) | Remove the `.bashrc` PATH lines from `pi_coding_agent`/`gemini_cli`; add `lineinfile: state=absent` cleanup (its plan §3.5) |
| Nothing to change — `skills/` layout is stable | `roles/skills` keeps managing `~/.pi/agent/settings.json`; Quattro's `omarchy-theme-set-pi` also writes that file, but both merge safely (its plan §2.6) |

Also note the playbook clones this repo with `update: false`, so **Ansible will never pull these changes** onto a machine that already has the checkout. Update it manually with `git -C ~/src/omarchy-dotfiles pull`.

---

## 7. Suggested execution order

| Step | Work | When |
|---|---|---|
| 1 | ~~Fix the `theme-set.d` `cp` bug (§3.4)~~ | **DONE** |
| 2 | ~~Delete `mcp/`, `omarchy-mods-alacritty.sh`, `omarchy-mods-spectra-theme.sh` (§5)~~ | **DONE** |
| 3 | ~~Fix the branding initramfs conditional (§4.1)~~ | **DONE** |
| 4 | ~~Make `cleanup.sh` filter to installed packages (§3.3a)~~ | **DONE** |
| 5 | **Upgrade:** `omarchy-upgrade-to-quattro`, reboot | — |
| 6 | Remove the npm-global PATH line from `.zshrc`, in lockstep with the playbook (§3.6, §6) | After 5 |
| 7 | Rewrite `hyprland-global.sh` to append a Lua block (§3.2) | After 5 |
| 8 | Strip the mako block from `theme-set`; guard the alacritty block (§3.5) | After 5 |
| 9 | Rewrite `cleanup.sh` bindings + webapp lists against Lua/Quattro (§3.3b, §3.3c) | After 5 |
| 10 | Build the bar-widget plugin and rewrite `waybar.sh` → `shell.sh` (§3.1) | After 5 |
| 11 | Port the spectra theme in its own repo; restore the `theme-install` line (§3.7) | Separate |

Steps 1–4 are safe on 3.8.4 today and are worth doing regardless of the upgrade.

---

## 8. Verification checklist

After step 10, on the upgraded machine:

- [ ] `bash -n` clean on every `scripts/*.sh` and on `omarchy-hooks/theme-set`.
- [ ] `hyprctl reload` reports no Lua error, and `hyprctl getoption input:kb_layout` returns `us,no`.
- [ ] Alt+Shift switches layout; touchpad scrolls naturally.
- [ ] Re-run `omarchy-mods-hyprland-global.sh` twice — `input.lua` gains exactly **one** `user-overrides` block.
- [ ] `omarchy theme set <name>` then confirm Ghostty padding/opacity/`command = zsh` survived, and that `~/.config/ghostty/config` has exactly one delimited block.
- [ ] `echo $SHELL` inside a fresh Ghostty window is zsh.
- [ ] `type -a claude gemini pi codex` resolves to `~/.local/bin` or mise — **never** `~/.npm-global/bin`.
- [ ] `grep npm-global ~/.zshrc ~/.bashrc` returns nothing.
- [ ] `ls ~/.claude/skills/ ~/.pi/agent/skills/` — all 11 skills symlinked, no stale entries.
- [ ] Bar shows the Arch glyph **and** `Super+Space` still opens the Omarchy menu (the §3.1 caveat).
- [ ] Reboot: Plymouth shows the custom logo during LUKS unlock.
- [ ] `omarchy-mods-cleanup.sh` runs to completion with no `target not found`.

---

## 9. Open questions

1. **Notification styling (§3.5).** Your mako block encodes real preferences — width 420, top-right, 5s timeout, Spotify suppressed, DND rules. What is the Quickshell equivalent, and is it `shell.json` or a plugin? This is the largest unknown in the plan and needs a live Quattro system.
2. **Bar logo vs. menu (§3.1).** If substituting the menu widget breaks `Super+Space`, do you prefer keeping the stock Omarchy glyph, or is a themed font override worth pursuing?
3. **Spectra theme (§3.7).** Port it to the 24-color Quattro format, or switch to one of the 22 bundled themes and retire both the theme repo and the `theme-install` lines?
4. **`first-time.sh` failure semantics (§3.4).** Keep `set -e` fail-fast, or run each mod under a guard so one breakage does not silently skip the rest? The current behaviour hid the waybar breakage from branding and cleanup.
5. **Ghostty long-term (decision #1).** Quattro ships `omarchy-theme-set-foot` but no ghostty equivalent. If Ghostty theming degrades, revisit foot — the config surface you would lose is small (`ghostty/config` is 14 lines plus the hook block).
