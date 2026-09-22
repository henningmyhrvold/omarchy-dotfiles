#!/usr/bin/env python3
"""Unbind selected app descriptions without editing Omarchy's defaults."""

import importlib.util
import json
from pathlib import Path
import subprocess
import sys

spec = importlib.util.spec_from_file_location("config_edit", Path(__file__).with_name("config-edit.py"))
edit = importlib.util.module_from_spec(spec)
spec.loader.exec_module(edit)

target = Path(sys.argv[1])
descriptions = set(sys.argv[2:])
bindings = json.loads(subprocess.check_output(["hyprctl", "-j", "binds"]))
begin, end = "-- >>> omarchy-dotfiles-cleanup >>>", "-- <<< omarchy-dotfiles-cleanup <<<"
text = target.read_text()
# Keep previous unbinds on subsequent runs, when those bindings are no longer live.
lines = set()
if begin in text and end in text:
    lines.update(text.split(begin, 1)[1].split(end, 1)[0].strip().splitlines())
for binding in bindings:
    description = binding.get("description", "")
    if description not in descriptions:
        continue
    if binding.get("submap"):
        continue
    key = binding.get("key") or f"code:{binding['keycode']}"
    mask = binding["modmask"]
    modifiers = [(1, "SHIFT"), (2, "CAPS"), (4, "CTRL"), (8, "ALT"),
                 (16, "MOD2"), (32, "MOD3"), (64, "SUPER"), (128, "MOD5")]
    chord = " + ".join([name for bit, name in modifiers if mask & bit] + [key])
    lines.add(f"hl.unbind({json.dumps(chord)}) -- {description}")
    print(f"Unbinding {chord}: {description}")
edit.write(target, edit.block(text, "\n".join(sorted(lines)), "omarchy-dotfiles-cleanup").encode())
