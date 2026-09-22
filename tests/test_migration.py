"""Migration regressions using temporary homes and installed Quattro templates.

Run: python -m unittest discover -s tests -v
No test changes the running desktop, packages, or services.
"""

import importlib.util
import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import tomllib
import unittest

REPO = Path(__file__).resolve().parents[1]
OMARCHY = Path(os.environ.get("OMARCHY_PATH", "/usr/share/omarchy"))
THEME = Path(os.environ.get("SPECTRA_THEME_DIR", REPO.parent / "omarchy-spectra-theme"))
spec = importlib.util.spec_from_file_location("edit", REPO / "scripts/config-edit.py")
edit = importlib.util.module_from_spec(spec)
spec.loader.exec_module(edit)


class MigrationTest(unittest.TestCase):
    def setUp(self):
        self.sandbox = tempfile.TemporaryDirectory(prefix="omarchy-migration-")
        self.addCleanup(self.sandbox.cleanup)
        self.home = Path(self.sandbox.name)
        self.env = dict(os.environ, HOME=str(self.home), OMARCHY_PATH=str(OMARCHY),
                        HYPRLAND_INSTANCE_SIGNATURE="", XDG_RUNTIME_DIR=str(self.home))

    def run_script(self, script, *args, **kwargs):
        return subprocess.run(["bash", str(REPO / script), *args], env=self.env,
                              text=True, capture_output=True, check=True, **kwargs)

    def test_commented_stock_input_is_valid_and_rerunnable(self):
        target = self.home / ".config/hypr/input.lua"
        target.parent.mkdir(parents=True)
        original = (OMARCHY / "config/hypr/input.lua").read_text() + '\nhl.config({ input = { sensitivity = 0.25 } })\n'
        target.write_text(original)
        self.run_script("scripts/omarchy-mods-hyprland-global.sh")
        once = target.read_text()
        self.run_script("scripts/omarchy-mods-hyprland-global.sh")
        self.assertEqual(once, target.read_text())
        self.assertTrue(once.startswith(original.rstrip()))
        self.assertEqual(once.count("-- >>> omarchy-dotfiles-input >>>"), 1)
        self.assertEqual(len(list(target.parent.glob(".input.lua.backup-*"))), 1)
        subprocess.run(["luac", "-p", str(target)], check=True)

    def test_invalid_lua_never_replaces_working_file(self):
        target = self.home / "input.lua"
        target.write_text("-- keep this config\n")
        with self.assertRaises(subprocess.CalledProcessError):
            edit.write(target, b'kb_layout = "us,no",\n')
        self.assertEqual(target.read_text(), "-- keep this config\n")
        with self.assertRaises(ValueError):
            edit.block("-- >>> prefs >>>\n", "new settings", "prefs")

    def test_hook_runs_as_bash_preserves_colors_and_is_idempotent(self):
        target = self.home / ".config/ghostty/config"
        target.parent.mkdir(parents=True)
        target.write_text((OMARCHY / "config/ghostty/config").read_text())
        # The old hook's Alacritty duplicate-table bug must not recur.
        alacritty = self.home / ".config/alacritty/alacritty.toml"
        alacritty.parent.mkdir(parents=True)
        original = (OMARCHY / "config/alacritty/alacritty.toml").read_bytes()
        alacritty.write_bytes(original)
        self.run_script("omarchy-hooks/theme-set")
        once = target.read_text()
        self.run_script("omarchy-hooks/theme-set")
        self.assertEqual(once, target.read_text())
        self.assertEqual(once.count("# >>> user-overrides >>>"), 1)
        self.assertIn('config-file = ?"~/.local/state/omarchy/current/theme/ghostty.conf"', once)
        self.assertEqual(alacritty.read_bytes(), original)
        tomllib.loads(alacritty.read_text())
        self.assertFalse((self.home / ".config/mako").exists())

    def test_cleanup_preserves_unrelated_bindings_and_previous_unbinds(self):
        binaries = self.home / "bin"
        binaries.mkdir()
        hyprctl = binaries / "hyprctl"
        binds = [{"description": "Music", "modmask": 65, "key": "M", "submap": ""},
                 {"description": "Terminal", "modmask": 64, "key": "RETURN", "submap": ""}]
        hyprctl.write_text("#!/bin/sh\nprintf '%s' '" + json.dumps(binds) + "'\n")
        hyprctl.chmod(0o755)
        self.env["PATH"] = str(binaries) + ":" + os.environ["PATH"]
        target = self.home / "bindings.lua"
        target.write_text('-- personal binding\no.bind("SUPER + R", "Notes", "nvim")\n')
        command = ["python", str(REPO / "scripts/cleanup-bindings.py"), str(target), "Music"]
        subprocess.run(command, env=self.env, check=True, capture_output=True)
        once = target.read_text()
        hyprctl.write_text("#!/bin/sh\nprintf '[]'\n")
        subprocess.run(command, env=self.env, check=True, capture_output=True)
        self.assertEqual(target.read_text(), once)
        self.assertIn('hl.unbind("SHIFT + SUPER + M") -- Music', once)
        self.assertIn('-- personal binding', once)
        self.assertNotIn('RETURN', once)

    def test_quattro_cloned_theme_staging_and_generated_configs(self):
        clone = self.home / ".config/omarchy/themes/spectra"
        shutil.copytree(THEME, clone, ignore=shutil.ignore_patterns(".git"))
        (clone / ".git").mkdir()  # Exercise the filtering path used by theme install.
        env = dict(self.env, OMARCHY_THEME_HEADLESS="1")
        result = subprocess.run(["omarchy", "theme", "set", "spectra"], env=env,
                                text=True, capture_output=True, check=True)
        self.assertNotIn("Ignored in", result.stderr)
        current = self.home / ".local/state/omarchy/current/theme"
        shell = tomllib.loads((current / "shell.toml").read_text())
        self.assertEqual(shell["menu"]["background-alpha"], 0.88)
        self.assertEqual(shell["bar"]["background-alpha"], 0.78)
        self.assertEqual(tomllib.loads((current / "alacritty.toml").read_text())["colors"]["primary"]["background"], "#1a1b1e")
        self.assertIn("97b6ffcc", (current / "hyprland.lua").read_text())
        for lua in current.glob("*.lua"):
            subprocess.run(["luac", "-p", str(lua)], check=True)
        for name in ["ghostty.conf", "foot.ini", "kitty.conf", "neovim.lua", "vscode-theme.json"]:
            rendered = (current / name).read_text()
            self.assertNotIn("{{", rendered, name)
        self.assertTrue((self.home / ".local/state/omarchy/current/background").is_file())


if __name__ == "__main__":
    unittest.main()
