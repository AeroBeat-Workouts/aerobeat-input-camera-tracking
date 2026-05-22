#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
import shutil
import subprocess
import sys
from pathlib import Path


CACHE_GLOBS = [
    ".godot/global_script_class_cache.cfg",
    ".godot/editor/filesystem_cache*",
]


def _parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description=(
            "Refresh the repo-local .testbed workbench by restoring declared addons, pruning stale "
            "generated addon entries, clearing Godot class/index caches, and optionally re-importing."
        )
    )
    parser.add_argument(
        "--repo-root",
        default=Path(__file__).resolve().parent.parent,
        type=Path,
        help="Repo root containing .testbed/ (defaults to this script's parent repo).",
    )
    parser.add_argument(
        "--skip-install",
        action="store_true",
        help="Skip 'godotenv addons install'.",
    )
    parser.add_argument(
        "--skip-import",
        action="store_true",
        help="Skip headless Godot import after cache cleanup.",
    )
    parser.add_argument(
        "--json",
        action="store_true",
        help="Emit machine-readable summary JSON.",
    )
    return parser.parse_args()


def _strip_jsonc_comments(raw_text: str) -> str:
    cleaned_lines: list[str] = []
    for line in raw_text.splitlines():
        in_string = False
        escaped = False
        result_chars: list[str] = []
        i = 0
        while i < len(line):
            char = line[i]
            if in_string:
                result_chars.append(char)
                if escaped:
                    escaped = False
                elif char == "\\":
                    escaped = True
                elif char == '"':
                    in_string = False
                i += 1
                continue

            if char == '"':
                in_string = True
                result_chars.append(char)
                i += 1
                continue

            if char == "/" and i + 1 < len(line) and line[i + 1] == "/":
                break

            result_chars.append(char)
            i += 1

        cleaned_lines.append("".join(result_chars))

    return "\n".join(cleaned_lines)


def _load_declared_addons(addons_jsonc_path: Path) -> set[str]:
    payload = json.loads(_strip_jsonc_comments(addons_jsonc_path.read_text()))
    addons = payload.get("addons", {})
    if not isinstance(addons, dict):
        raise SystemExit(f"Expected object at 'addons' in {addons_jsonc_path}")
    return set(addons.keys())


def _run(command: list[str], *, cwd: Path) -> subprocess.CompletedProcess[str]:
    return subprocess.run(command, cwd=cwd, text=True, capture_output=True, check=False)


def _remove_path(path: Path) -> None:
    if path.is_symlink() or path.is_file():
        path.unlink()
        return
    shutil.rmtree(path)


def main() -> int:
    args = _parse_args()
    repo_root = args.repo_root.resolve()
    testbed_root = repo_root / ".testbed"
    addons_jsonc_path = testbed_root / "addons.jsonc"
    addons_dir = testbed_root / "addons"

    if not testbed_root.exists():
        raise SystemExit(f"Missing testbed directory: {testbed_root}")
    if not addons_jsonc_path.exists():
        raise SystemExit(f"Missing addons manifest: {addons_jsonc_path}")

    summary: dict[str, object] = {
        "repo_root": str(repo_root),
        "testbed_root": str(testbed_root),
        "declared_addons": [],
        "removed_addons": [],
        "cleared_cache_files": [],
        "install": None,
        "import": None,
    }

    declared_addons = sorted(_load_declared_addons(addons_jsonc_path))
    summary["declared_addons"] = declared_addons

    if not args.skip_install:
        install_result = _run(["godotenv", "addons", "install"], cwd=testbed_root)
        summary["install"] = {
            "command": "godotenv addons install",
            "returncode": install_result.returncode,
            "stdout": install_result.stdout,
            "stderr": install_result.stderr,
        }
        if install_result.returncode != 0:
            if args.json:
                print(json.dumps(summary, indent=2))
            else:
                sys.stderr.write(install_result.stdout)
                sys.stderr.write(install_result.stderr)
            return install_result.returncode

    removed_addons: list[str] = []
    if addons_dir.exists():
        for entry in sorted(addons_dir.iterdir(), key=lambda p: p.name):
            if entry.name.startswith("."):
                continue
            if entry.name in declared_addons:
                continue
            _remove_path(entry)
            removed_addons.append(entry.name)
    summary["removed_addons"] = removed_addons

    cleared_cache_files: list[str] = []
    for pattern in CACHE_GLOBS:
        for cache_path in sorted(testbed_root.glob(pattern)):
            if cache_path.exists():
                cache_path.unlink()
                cleared_cache_files.append(str(cache_path.relative_to(repo_root)))
    summary["cleared_cache_files"] = cleared_cache_files

    if not args.skip_import:
        import_result = _run(
            ["godot", "--headless", "--path", str(testbed_root), "--import", "--quit-after", "1000"],
            cwd=repo_root,
        )
        summary["import"] = {
            "command": f"godot --headless --path {testbed_root} --import --quit-after 1000",
            "returncode": import_result.returncode,
            "stdout": import_result.stdout,
            "stderr": import_result.stderr,
        }
        if import_result.returncode != 0:
            if args.json:
                print(json.dumps(summary, indent=2))
            else:
                sys.stderr.write(import_result.stdout)
                sys.stderr.write(import_result.stderr)
            return import_result.returncode

    if args.json:
        print(json.dumps(summary, indent=2))
    else:
        print(f"Refreshed testbed workbench at {testbed_root}")
        if removed_addons:
            print("Removed stale generated addons:")
            for addon in removed_addons:
                print(f"- {addon}")
        else:
            print("Removed stale generated addons: none")
        if cleared_cache_files:
            print("Cleared Godot caches:")
            for cache_file in cleared_cache_files:
                print(f"- {cache_file}")
        else:
            print("Cleared Godot caches: none")
        if summary["install"] is not None:
            print("Ran: godotenv addons install")
        if summary["import"] is not None:
            print("Ran: godot --headless --path .testbed --import --quit-after 1000")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
