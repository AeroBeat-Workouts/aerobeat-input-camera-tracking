#!/usr/bin/env python3
from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path

from boxing_classifier_harness import load_json, load_yaml, pose_snapshots


def _repo_root() -> Path:
    return Path(__file__).resolve().parents[1]


def _sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def _rel(repo_root: Path, path: Path) -> str:
    return path.resolve().relative_to(repo_root).as_posix()


def _truth_windows(fixture_yaml: dict) -> list[dict]:
    windows: list[dict] = []
    for gesture in fixture_yaml.get("expected_gestures", []) or []:
        if not isinstance(gesture, dict):
            continue
        gesture_name = str(gesture.get("name", "")).strip()
        for index, window in enumerate(gesture.get("windows", []) or [], start=1):
            if not isinstance(window, dict):
                continue
            windows.append(
                {
                    "gesture_name": gesture_name,
                    "window_index": index,
                    "start_ms": int(window.get("start_ms", 0) or 0),
                    "end_ms": int(window.get("end_ms", 0) or 0),
                }
            )
    return windows


def _capture_report_entry(repo_root: Path, capture_root: Path, fixture_id: str) -> dict:
    report_path = (capture_root / "captures" / fixture_id / "report.json").resolve()
    report = load_json(report_path)
    fixture_capture = report.get("fixture_capture", {}) if isinstance(report.get("fixture_capture", {}), dict) else {}
    return {
        "fixture_id": fixture_id,
        "report_path": _rel(repo_root, report_path),
        "report_sha256": _sha256_file(report_path),
        "pose_snapshot_count": len(pose_snapshots(report)),
        "time_basis": str(fixture_capture.get("time_basis", "")),
        "time_origin_reason": str(fixture_capture.get("time_origin_reason", "")),
        "time_origin_offset_ms": int(fixture_capture.get("time_origin_offset_ms", 0) or 0),
    }


def _render_markdown(snapshot: dict) -> str:
    lines = [
        f"# {snapshot['snapshot_id']}",
        "",
        snapshot.get("description", ""),
        "",
        "## Frozen inputs",
        "",
        f"- Benchmark manifest: `{snapshot['benchmark_manifest']['path']}`",
        f"- Capture package: `{snapshot['capture_report_source']['package_id']}`",
        f"- Capture source root: `{snapshot['capture_report_source']['root_dir']}`",
        f"- Alignment basis: `{snapshot['capture_report_source']['alignment_basis']}`",
        f"- Export parameters: `{json.dumps(snapshot['export_parameters'], sort_keys=True)}`",
        f"- Split strategy: `{snapshot['split_strategy']['name']}`",
        f"- Negative sampling policy: `{json.dumps(snapshot['negative_sampling_policy'], sort_keys=True)}`",
        "",
        "## Dataset anchor",
        "",
        f"- Dataset: `{snapshot['dataset_anchor']['dataset_path']}` sha256=`{snapshot['dataset_anchor']['dataset_sha256']}`",
        f"- Export summary: `{snapshot['dataset_anchor']['export_summary_path']}` sha256=`{snapshot['dataset_anchor']['export_summary_sha256']}`",
        f"- Threshold baseline: `{snapshot['dataset_anchor']['threshold_baseline_path']}` sha256=`{snapshot['dataset_anchor']['threshold_baseline_sha256']}`",
        "",
        "## Fixtures",
        "",
    ]
    for fixture in snapshot.get("fixtures", []):
        lines.extend(
            [
                f"### {fixture['fixture_id']}",
                f"- Fixture YAML: `{fixture['fixture_path']}` sha256=`{fixture['fixture_sha256']}`",
                f"- Source video: `{fixture['source_path']}` sha256=`{fixture['source_sha256']}`",
                f"- Capture report: `{fixture['capture_report']['report_path']}` sha256=`{fixture['capture_report']['report_sha256']}`",
                f"- Truth windows: **{len(fixture['truth_windows'])}**",
                "",
            ]
        )
    lines.extend(
        [
            "## Recreate this snapshot target",
            "",
            "```bash",
            f"python3 scripts/export_boxing_punch_classifier_dataset.py --snapshot-manifest {snapshot['_snapshot_manifest_path']} --skip-captures --output-dir .temp/boxing-punch-classifier-export/{snapshot['snapshot_id']}-rerun",
            "```",
            "",
        ]
    )
    return "\n".join(lines).rstrip() + "\n"


def main() -> int:
    parser = argparse.ArgumentParser(description="Freeze a named boxing punch-classifier dataset snapshot manifest.")
    parser.add_argument("--snapshot-id", required=True)
    parser.add_argument("--manifest", default=".testbed/assets/benchmarks/boxing_punch_classifier_v1.benchmark.json")
    parser.add_argument("--captures-dir", required=True)
    parser.add_argument("--dataset", required=True)
    parser.add_argument("--export-summary", required=True)
    parser.add_argument("--threshold-baseline", required=True)
    parser.add_argument("--output", required=True, help="Snapshot manifest JSON path relative to repo root")
    parser.add_argument("--description", default="Frozen benchmark snapshot for boxing punch-classifier reproducibility.")
    parser.add_argument("--frame-count", type=int, default=8)
    parser.add_argument("--no-punch-window-ms", type=int, default=250)
    parser.add_argument("--no-punch-stride-ms", type=int, default=250)
    parser.add_argument("--max-no-punch-samples", type=int, default=48)
    parser.add_argument("--max-transition-no-punch-samples", type=int, default=24)
    args = parser.parse_args()

    repo_root = _repo_root()
    manifest_path = (repo_root / args.manifest).resolve()
    captures_dir = (repo_root / args.captures_dir).resolve()
    dataset_path = (repo_root / args.dataset).resolve()
    export_summary_path = (repo_root / args.export_summary).resolve()
    threshold_baseline_path = (repo_root / args.threshold_baseline).resolve()
    output_path = (repo_root / args.output).resolve()

    manifest = load_json(manifest_path)

    fixtures: list[dict] = []
    reports: list[dict] = []
    for fixture in manifest.get("fixtures", []) or []:
        fixture_path = (repo_root / fixture["fixture_path"]).resolve()
        source_path = (repo_root / fixture["source_path"]).resolve()
        fixture_yaml = load_yaml(fixture_path)
        capture_report = _capture_report_entry(repo_root, captures_dir, str(fixture["id"]))
        reports.append(capture_report)
        fixtures.append(
            {
                "fixture_id": str(fixture["id"]),
                "label": str(fixture.get("label", "")),
                "scene_path": str(fixture.get("scene_path", "")),
                "fixture_path": _rel(repo_root, fixture_path),
                "fixture_sha256": _sha256_file(fixture_path),
                "source_path": _rel(repo_root, source_path),
                "source_sha256": _sha256_file(source_path),
                "truth_windows": _truth_windows(fixture_yaml),
                "capture_report": capture_report,
            }
        )

    snapshot = {
        "schema": "aerobeat.boxing_punch_classifier_snapshot",
        "version": 1,
        "snapshot_id": args.snapshot_id,
        "description": args.description,
        "benchmark_manifest": {
            "path": _rel(repo_root, manifest_path),
            "sha256": _sha256_file(manifest_path),
            "benchmark_id": str(manifest.get("benchmark_id", "")),
            "capture_delay_ms": int(manifest.get("capture_delay_ms", 0) or 0),
        },
        "capture_report_source": {
            "package_id": f"{args.snapshot_id}.capture_reports",
            "root_dir": _rel(repo_root, captures_dir),
            "alignment_basis": "fixture_window_plus_capture_time_origin_offset_from_provider_tracking_ms_since_first_pose",
            "reports": reports,
        },
        "export_parameters": {
            "frame_count": int(args.frame_count),
            "no_punch_window_ms": int(args.no_punch_window_ms),
            "no_punch_stride_ms": int(args.no_punch_stride_ms),
            "max_no_punch_samples": int(args.max_no_punch_samples),
            "max_transition_no_punch_samples": int(args.max_transition_no_punch_samples),
        },
        "split_strategy": {
            "name": "chronological_holdout_v1",
            "holdout_ratio": 0.25,
            "grouping_basis": "positive=label+fixture, negatives=fixture",
        },
        "negative_sampling_policy": {
            "background_windows": "complement_intervals iter_fixed_windows evenly_pick",
            "transition_windows": "before_and_after_each_punch_window clamped_to_non_punch_intervals evenly_pick",
        },
        "dataset_anchor": {
            "dataset_path": _rel(repo_root, dataset_path),
            "dataset_sha256": _sha256_file(dataset_path),
            "export_summary_path": _rel(repo_root, export_summary_path),
            "export_summary_sha256": _sha256_file(export_summary_path),
            "threshold_baseline_path": _rel(repo_root, threshold_baseline_path),
            "threshold_baseline_sha256": _sha256_file(threshold_baseline_path),
        },
        "fixtures": fixtures,
    }
    snapshot["_snapshot_manifest_path"] = _rel(repo_root, output_path)

    output_path.parent.mkdir(parents=True, exist_ok=True)
    output_path.write_text(json.dumps({k: v for k, v in snapshot.items() if not k.startswith('_')}, indent=2) + "\n", encoding="utf-8")
    markdown_path = output_path.with_suffix(".md")
    markdown_path.write_text(_render_markdown(snapshot), encoding="utf-8")
    print(f"[snapshot] wrote {output_path}")
    print(f"[snapshot] wrote {markdown_path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
