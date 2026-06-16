#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
from collections import Counter
from datetime import datetime, timezone
from pathlib import Path

from boxing_classifier_harness import (
    DEFAULT_GODOT_BIN,
    DEFAULT_MAX_NO_PUNCH_SAMPLES,
    DEFAULT_NO_PUNCH_STRIDE_MS,
    DEFAULT_THRESHOLD_WINDOW_MS,
    DEFAULT_WINDOW_FRAME_COUNT,
    PUNCH_CLASS_ORDER,
    PUNCH_EVENT_TO_CLASS,
    PUNCH_GESTURE_NAMES,
    assign_deterministic_splits,
    build_feature_snapshots,
    capture_window_range_ms,
    complement_intervals,
    ensure_clean_dir,
    evenly_pick,
    extract_window_sample,
    fixture_duration_ms,
    format_confusion_markdown,
    iter_fixed_windows,
    load_json,
    load_yaml,
    run_capture,
    write_json,
)


def _repo_root() -> Path:
    return Path(__file__).resolve().parents[1]


def _load_manifest(repo_root: Path, manifest_path: str) -> dict:
    manifest_file = (repo_root / manifest_path).resolve()
    manifest = load_json(manifest_file)
    manifest["_manifest_path"] = manifest_path
    return manifest


def _export_dataset(repo_root: Path, manifest: dict, captures_dir: Path, frame_count: int, no_punch_window_ms: int, no_punch_stride_ms: int, max_no_punch_samples: int) -> tuple[dict, dict]:
    samples = []
    fixture_summaries = []
    no_punch_candidates = []

    for fixture in manifest.get("fixtures", []):
        fixture_path = (repo_root / fixture["fixture_path"]).resolve()
        fixture_yaml = load_yaml(fixture_path)
        capture_report = load_json(captures_dir / "captures" / fixture["id"] / "report.json")
        feature_snapshots = build_feature_snapshots(capture_report)
        gesture_windows = {}
        for gesture in fixture_yaml.get("expected_gestures", []) or []:
            if not isinstance(gesture, dict):
                continue
            gesture_windows.setdefault(str(gesture.get("name", "")).strip(), []).extend(
                [window for window in (gesture.get("windows", []) or []) if isinstance(window, dict)]
            )

        punch_windows = []
        fixture_positive_samples = []
        for gesture_name, windows in gesture_windows.items():
            if gesture_name not in PUNCH_GESTURE_NAMES:
                continue
            for window_index, window in enumerate(windows, start=1):
                start_ms = int(window.get("start_ms", 0) or 0)
                end_ms = int(window.get("end_ms", 0) or 0)
                punch_windows.append((start_ms, end_ms))
                sample = extract_window_sample(
                    feature_snapshots,
                    capture_report,
                    gesture_name,
                    f"{fixture['id']}::{gesture_name}::{window_index:02d}",
                    fixture,
                    fixture_yaml,
                    start_ms,
                    end_ms,
                    frame_count=frame_count,
                    sample_kind="annotated_punch_window",
                    source_window_index=window_index,
                    source_gesture_name=gesture_name,
                )
                if sample is not None:
                    samples.append(sample)
                    fixture_positive_samples.append(sample["sample_id"])

        duration_ms = max(fixture_duration_ms(fixture_yaml), fixture.get("duration_ms", 0) or 0)
        non_punch_intervals = complement_intervals(0, duration_ms, punch_windows)
        candidate_intervals = iter_fixed_windows(non_punch_intervals, no_punch_window_ms, no_punch_stride_ms)
        fixture_candidate_ids = []
        for candidate_index, (start_ms, end_ms) in enumerate(candidate_intervals, start=1):
            sample = extract_window_sample(
                feature_snapshots,
                capture_report,
                "no_punch",
                f"{fixture['id']}::no_punch::{candidate_index:03d}",
                fixture,
                fixture_yaml,
                start_ms,
                end_ms,
                frame_count=frame_count,
                sample_kind="derived_no_punch_window",
                source_window_index=candidate_index,
                source_gesture_name="no_punch",
            )
            if sample is None:
                continue
            no_punch_candidates.append(sample)
            fixture_candidate_ids.append(sample["sample_id"])

        fixture_summaries.append(
            {
                "fixture_id": fixture["id"],
                "fixture_path": fixture["fixture_path"],
                "source_path": fixture["source_path"],
                "feature_snapshots_retained": len(feature_snapshots),
                "annotated_punch_sample_ids": fixture_positive_samples,
                "annotated_punch_window_count": len(punch_windows),
                "no_punch_candidate_sample_ids": fixture_candidate_ids,
                "no_punch_candidate_count": len(fixture_candidate_ids),
                "duration_ms": duration_ms,
            }
        )

    selected_no_punch = evenly_pick(no_punch_candidates, max_no_punch_samples)
    samples.extend(selected_no_punch)
    samples.sort(key=lambda item: (PUNCH_CLASS_ORDER.index(item["label"]), str(item["source_fixture_id"]), int(item["window_start_ms"]), str(item["sample_id"])))
    assign_deterministic_splits(samples)

    export_summary = {
        "schema": "aerobeat.boxing_punch_classifier_export",
        "version": 1,
        "exported_at": datetime.now(timezone.utc).isoformat(),
        "manifest_path": manifest["_manifest_path"],
        "capture_dir": captures_dir.relative_to(repo_root).as_posix(),
        "window_frame_count": frame_count,
        "frame_feature_count": len(samples[0]["feature_names"]) if samples else 0,
        "frame_feature_names": samples[0]["feature_names"] if samples else [],
        "class_order": list(PUNCH_CLASS_ORDER),
        "no_punch_window_ms": no_punch_window_ms,
        "no_punch_stride_ms": no_punch_stride_ms,
        "max_no_punch_samples": max_no_punch_samples,
        "sample_count": len(samples),
        "label_counts": dict(Counter(sample["label"] for sample in samples)),
        "split_counts": dict(Counter(sample["split"] for sample in samples)),
        "fixtures": fixture_summaries,
        "samples": samples,
    }

    threshold_records = [
        {
            "sample_id": sample["sample_id"],
            "split": sample["split"],
            "actual": sample["label"],
            "predicted": sample["threshold_baseline"]["predicted_label"],
        }
        for sample in samples
    ]
    threshold_by_split = {}
    for split in sorted(set(record["split"] for record in threshold_records)):
        subset = [record for record in threshold_records if record["split"] == split]
        from boxing_classifier_harness import classification_metrics

        threshold_by_split[split] = classification_metrics(subset, PUNCH_CLASS_ORDER)
    threshold_summary = {
        "comparison_target": "threshold_gates",
        "records": threshold_records,
        "metrics_by_split": threshold_by_split,
    }
    return export_summary, threshold_summary


def _render_markdown(export_summary: dict, threshold_summary: dict) -> str:
    lines = [
        "# Boxing Punch Classifier Export",
        "",
        f"- Exported at: `{export_summary['exported_at']}`",
        f"- Manifest: `{export_summary['manifest_path']}`",
        f"- Capture dir: `{export_summary['capture_dir']}`",
        f"- Class order: `{', '.join(export_summary['class_order'])}`",
        f"- Window shape: `{export_summary['window_frame_count']} frames x {export_summary['frame_feature_count']} features/frame`",
        f"- Samples: **{export_summary['sample_count']}**",
        f"- Label counts: `{json.dumps(export_summary['label_counts'], sort_keys=True)}`",
        f"- Split counts: `{json.dumps(export_summary['split_counts'], sort_keys=True)}`",
        "",
        "## Fixture export summary",
        "",
    ]
    for fixture in export_summary["fixtures"]:
        lines.extend(
            [
                f"### {fixture['fixture_id']}",
                f"- Fixture YAML: `{fixture['fixture_path']}`",
                f"- Source video: `{fixture['source_path']}`",
                f"- Retained feature snapshots: **{fixture['feature_snapshots_retained']}**",
                f"- Annotated punch windows: **{fixture['annotated_punch_window_count']}**",
                f"- Derived no-punch candidates: **{fixture['no_punch_candidate_count']}**",
                "",
            ]
        )
    lines.extend(["## Threshold baseline on exported windows", ""])
    for split, metrics in threshold_summary["metrics_by_split"].items():
        lines.extend(
            [
                f"### {split}",
                f"- Accuracy: **{metrics['accuracy']:.3f}**",
                f"- Macro F1: **{metrics['macro_f1']:.3f}**",
                f"- Macro precision: **{metrics['macro_precision']:.3f}**",
                f"- Macro recall: **{metrics['macro_recall']:.3f}**",
                "",
                *format_confusion_markdown(metrics["confusion"], export_summary["class_order"]),
                "",
            ]
        )
    return "\n".join(lines).rstrip() + "\n"


def main() -> int:
    parser = argparse.ArgumentParser(description="Export a reusable boxing punch-classifier dataset from committed fixture captures.")
    parser.add_argument("--manifest", default=".testbed/assets/benchmarks/boxing_punch_classifier_v1.benchmark.json")
    parser.add_argument("--captures-dir", default=".temp/boxing-punch-classifier-export/captures")
    parser.add_argument("--output-dir", required=True, help="Directory for export-summary.{json,md} and dataset.json")
    parser.add_argument("--godot", default=DEFAULT_GODOT_BIN)
    parser.add_argument("--capture-delay-ms", type=int, default=7000)
    parser.add_argument("--frame-count", type=int, default=DEFAULT_WINDOW_FRAME_COUNT)
    parser.add_argument("--no-punch-window-ms", type=int, default=DEFAULT_THRESHOLD_WINDOW_MS)
    parser.add_argument("--no-punch-stride-ms", type=int, default=DEFAULT_NO_PUNCH_STRIDE_MS)
    parser.add_argument("--max-no-punch-samples", type=int, default=DEFAULT_MAX_NO_PUNCH_SAMPLES)
    parser.add_argument("--skip-captures", action="store_true", help="Reuse existing report.json files under --captures-dir instead of rerunning Godot capture.")
    args = parser.parse_args()

    repo_root = _repo_root()
    manifest = _load_manifest(repo_root, args.manifest)
    captures_dir = (repo_root / args.captures_dir).resolve()
    output_dir = (repo_root / args.output_dir).resolve()
    ensure_clean_dir(output_dir)
    if not args.skip_captures:
        ensure_clean_dir(captures_dir)
        for fixture in manifest.get("fixtures", []):
            run_capture(repo_root, fixture, captures_dir, godot_bin=args.godot, capture_delay_ms=args.capture_delay_ms)

    export_summary, threshold_summary = _export_dataset(
        repo_root,
        manifest,
        captures_dir,
        frame_count=args.frame_count,
        no_punch_window_ms=args.no_punch_window_ms,
        no_punch_stride_ms=args.no_punch_stride_ms,
        max_no_punch_samples=args.max_no_punch_samples,
    )
    write_json(output_dir / "dataset.json", export_summary)
    write_json(output_dir / "threshold-baseline.json", threshold_summary)
    write_json(output_dir / "export-summary.json", {k: v for k, v in export_summary.items() if k != "samples"})
    (output_dir / "export-summary.md").write_text(_render_markdown(export_summary, threshold_summary), encoding="utf-8")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
