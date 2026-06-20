#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
DEFAULT_METADATA="$SCRIPT_DIR/depth-models.yaml"
DEFAULT_REPO_ROOT=$(cd -- "$SCRIPT_DIR/.." && pwd)

exec python3 - "$@" "$DEFAULT_METADATA" "$DEFAULT_REPO_ROOT" <<'PY'
import argparse
import json
import os
from pathlib import Path
import shutil
import sys
import tempfile
import urllib.error
import urllib.request

DEFAULT_METADATA = Path(sys.argv[-2])
DEFAULT_REPO_ROOT = Path(sys.argv[-1])
ARGS = sys.argv[1:-2]
ADDON_PREFIX = "res://addons/aerobeat-input-camera-tracking/"


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        prog="fetch-depth-models.sh",
        description=(
            "Fetch approved AeroBeat depth-model artifacts into repo-local asset paths "
            "without committing the binaries to git."
        ),
    )
    parser.add_argument(
        "--metadata",
        default=str(DEFAULT_METADATA),
        help="Path to the JSON-compatible YAML sidecar to read (default: %(default)s)",
    )
    parser.add_argument(
        "--repo-root",
        default=str(DEFAULT_REPO_ROOT),
        help="Owning repo root used to resolve res:// addon paths (default: %(default)s)",
    )
    parser.add_argument(
        "--model",
        dest="models",
        action="append",
        help="Fetch only the given model id. May be passed multiple times.",
    )
    parser.add_argument(
        "--force",
        action="store_true",
        help="Re-download artifacts even when the destination already exists.",
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Print what would happen without creating directories or downloading files.",
    )
    parser.add_argument(
        "--list",
        action="store_true",
        help="List model ids and destination paths, then exit.",
    )
    return parser


def load_metadata(path: Path) -> dict:
    try:
        with path.open("r", encoding="utf-8") as handle:
            return json.load(handle)
    except json.JSONDecodeError as exc:
        raise SystemExit(
            f"Metadata parse failed for {path}: {exc}. "
            "This sidecar intentionally uses the JSON-compatible subset of YAML so the fetch script stays dependency-free."
        ) from exc


def resolve_destination(repo_root: Path, destination_path: str) -> Path:
    if not destination_path.startswith(ADDON_PREFIX):
        raise SystemExit(
            f"Unsupported destination path {destination_path!r}. "
            f"Expected it to start with {ADDON_PREFIX!r}."
        )
    return repo_root / destination_path[len(ADDON_PREFIX):]


def iter_selected_models(models: list[dict], selected_ids: set[str] | None) -> list[dict]:
    if not selected_ids:
        return models
    by_id = {model["id"]: model for model in models}
    missing = sorted(selected_ids - set(by_id))
    if missing:
        raise SystemExit(f"Unknown --model id(s): {', '.join(missing)}")
    return [by_id[model_id] for model_id in sorted(selected_ids)]


def ensure_parent(path: Path, dry_run: bool) -> None:
    if dry_run:
        return
    path.mkdir(parents=True, exist_ok=True)


def download(url: str, destination: Path) -> None:
    with urllib.request.urlopen(url) as response:
        with tempfile.NamedTemporaryFile(delete=False, dir=str(destination.parent)) as tmp:
            shutil.copyfileobj(response, tmp)
            tmp_path = Path(tmp.name)
    tmp_path.replace(destination)


def print_model_header(model: dict, resolved_destination: Path) -> None:
    print(f"MODEL {model['id']}: {model['name']}")
    print(f"  destination.res: {model['destination_path']}")
    print(f"  destination.fs:  {resolved_destination}")
    print(f"  source.kind:     {model['source_kind']}")
    for note in model.get("notes", []):
        print(f"  note:            {note}")


def handle_model(model: dict, repo_root: Path, force: bool, dry_run: bool) -> None:
    destination_kind = model["destination_kind"]
    resolved_destination = resolve_destination(repo_root, model["destination_path"])
    sources = model.get("sources", [])
    if not sources:
        raise SystemExit(f"Model {model['id']} has no sources configured.")
    if destination_kind == "file" and len(sources) != 1:
        raise SystemExit(f"Model {model['id']} must have exactly one source for a file destination.")

    print_model_header(model, resolved_destination)

    if not model.get("direct_fetch_supported", False):
        print("  status:          skipped (metadata says direct fetch is not supported)")
        return

    if destination_kind == "directory":
        for source in sources:
            target_path = resolved_destination / source["target_name"]
            if target_path.exists() and not force:
                print(f"  skip:            {target_path} already exists")
                continue
            if dry_run:
                print(f"  dry-run:         would download {source['url']} -> {target_path}")
                continue
            ensure_parent(target_path.parent, dry_run=False)
            print(f"  fetch:           {source['url']} -> {target_path}")
            try:
                download(source["url"], target_path)
            except urllib.error.URLError as exc:
                raise SystemExit(f"Download failed for {source['url']}: {exc}") from exc
    else:
        source = sources[0]
        target_path = resolved_destination
        if target_path.exists() and not force:
            print(f"  skip:            {target_path} already exists")
            return
        if dry_run:
            print(f"  dry-run:         would download {source['url']} -> {target_path}")
            return
        ensure_parent(target_path.parent, dry_run=False)
        print(f"  fetch:           {source['url']} -> {target_path}")
        try:
            download(source["url"], target_path)
        except urllib.error.URLError as exc:
            raise SystemExit(f"Download failed for {source['url']}: {exc}") from exc


def main() -> int:
    parser = build_parser()
    args = parser.parse_args(ARGS)
    metadata_path = Path(args.metadata).resolve()
    repo_root = Path(args.repo_root).resolve()
    metadata = load_metadata(metadata_path)
    models = metadata.get("models", [])
    selected_models = iter_selected_models(models, set(args.models) if args.models else None)

    if args.list:
        for model in selected_models:
            resolved_destination = resolve_destination(repo_root, model["destination_path"])
            print(f"{model['id']}\t{model['destination_path']}\t{resolved_destination}")
        return 0

    print(f"Metadata: {metadata_path}")
    print(f"Repo root: {repo_root}")
    print(f"Dry run: {'yes' if args.dry_run else 'no'}")
    print(f"Force: {'yes' if args.force else 'no'}")
    print("")

    for model in selected_models:
        handle_model(model, repo_root=repo_root, force=args.force, dry_run=args.dry_run)
        print("")

    print("Done.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
PY
