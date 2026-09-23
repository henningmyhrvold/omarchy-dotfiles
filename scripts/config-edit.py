#!/usr/bin/env python3
"""Small, backed-up config edits used by the Omarchy 4 installers."""

import argparse
from datetime import datetime
import os
from pathlib import Path
import shutil
import subprocess
import tempfile


def backup(path):
    if not path.exists() and not path.is_symlink():
        return
    stamp = datetime.now().strftime("%Y%m%d-%H%M%S-%f")
    destination = path.with_name(f".{path.name}.backup-{stamp}")
    if path.is_dir() and not path.is_symlink():
        shutil.copytree(path, destination, symlinks=True)
    else:
        shutil.copy2(path, destination, follow_symlinks=False)
    print(f"Backup: {destination}")
    return destination


def write(path, data):
    # Preserve symlinks into user-owned dotfiles when editing their contents.
    path = path.resolve()
    if path.exists() and path.read_bytes() == data:
        print(f"Unchanged: {path}")
        return
    path.parent.mkdir(parents=True, exist_ok=True)
    fd, tmp = tempfile.mkstemp(prefix=f".{path.name}.", dir=path.parent)
    try:
        with os.fdopen(fd, "wb") as stream:
            stream.write(data)
        if path.suffix == ".lua":
            subprocess.run(["luac", "-p", tmp], check=True)
        os.chmod(tmp, path.stat().st_mode & 0o777 if path.exists() else 0o644)
        backup(path)
        os.replace(tmp, path)
    finally:
        if os.path.exists(tmp):
            os.unlink(tmp)
    print(f"Changed: {path}")


def block(text, content, marker):
    begin, end = f"-- >>> {marker} >>>", f"-- <<< {marker} <<<"
    if text.count(begin) != text.count(end) or text.count(begin) > 1:
        raise ValueError(f"Malformed managed block: {marker}")
    replacement = f"{begin}\n{content.rstrip()}\n{end}"
    if begin in text:
        start, finish = text.index(begin), text.index(end)
        if finish < start:
            raise ValueError(f"Reversed managed block: {marker}")
        return text[:start] + replacement + text[finish + len(end):]
    return text.rstrip() + "\n\n" + replacement + "\n"


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("action", choices=["block", "copy", "link", "backup"])
    parser.add_argument("target", type=Path)
    parser.add_argument("source", nargs="?", type=Path)
    parser.add_argument("--marker", default="omarchy-dotfiles")
    args = parser.parse_args()
    target = args.target.expanduser()
    if args.action == "backup":
        backup(target)
    elif args.source is None:
        parser.error("source is required")
    elif args.action == "link":
        source = args.source.expanduser().resolve(strict=True)
        if target.is_symlink() and target.resolve() == source:
            print(f"Unchanged: {target}")
            return
        target.parent.mkdir(parents=True, exist_ok=True)
        if target.exists() or target.is_symlink():
            # Rename, rather than delete, an existing checkout/config.
            saved = target.with_name(f".{target.name}.backup-{datetime.now():%Y%m%d-%H%M%S-%f}")
            target.rename(saved)
            print(f"Backup: {saved}")
        target.symlink_to(source, target_is_directory=source.is_dir())
        print(f"Changed: {target}")
    elif args.action == "copy":
        write(target, args.source.read_bytes())
    else:
        text = target.read_text() if target.exists() else ""
        write(target, block(text, args.source.read_text(), args.marker).encode())


if __name__ == "__main__":
    main()
