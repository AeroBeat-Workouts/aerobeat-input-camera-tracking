#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
import statistics
from collections import Counter
from datetime import datetime, timezone
from pathlib import Path

from boxing_classifier_harness import (
    DEFAULT_GODOT_BIN,
    DEFAULT_MAX_NO_PUNCH_SAMPLES,
    DEFAULT_MAX_TRANSITION_NO_PUNCH_SAMPLES,
    DEFAULT_NO_PUNCH_STRIDE_MS,
    DEFAULT_THRESHOLD_WINDOW_MS,
    DEFAULT_WINDOW_FRAME_COUNT,
    PUNCH_CLASS_ORDER,
    PUNCH_GESTURE_NAMES,
    assign_chronological_holdout_splits,
    build_feature_snapshots,
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


def _window_dicts_for_name(fixture_yaml: dict, gesture_name: str) -> list[dict]:
    windows: list[dict] = []
    for gesture in fixture_yaml.get("expected_gestures", []) or []:
        if not isinstance(gesture, dict):
            continue
        if str(gesture.get("name", "")).strip() != gesture_name:
            continue
        windows.extend([window for window in (gesture.get("windows", []) or []) if isinstance(window, dict)])
    return windows


def _safe_transition_window(intervals: list[tuple[int, int]], desired_start_ms: int, desired_end_ms: int) -> tuple[int, int] | None:
    for interval_start_ms, interval_end_ms in intervals:
        start_ms = max(int(interval_start_ms), int(desired_start_ms))
        end_ms = min(int(interval_end_ms), int(desired_end_ms))
        if end_ms > start_ms:
            return (start_ms, end_ms)
    return None


def _summarize_alignment(samples: list[dict]) -> dict:
    if not samples:
        return {}
    start_errors = [int(sample.get("start_alignment_error_ms", 0)) for sample in samples]
    end_errors = [int(sample.get("end_alignment_error_ms", 0)) for sample in samples]
    offsets = [int(sample.get("capture_time_origin_offset_ms", 0)) for sample in samples]
    by_fixture: dict[str, dict] = {}
    for sample in samples:
        fixture_id = str(sample.get("source_fixture_id", "unknown_fixture"))
        fixture_entry = by_fixture.setdefault(
            fixture_id,
            {
                "sample_count": 0,
                "capture_time_origin_offset_ms": int(sample.get("capture_time_origin_offset_ms", 0)),
                "start_alignment_errors_ms": [],
                "end_alignment_errors_ms": [],
            },
        )
        fixture_entry["sample_count"] += 1
        fixture_entry["start_alignment_errors_ms"].append(int(sample.get("start_alignment_error_ms", 0)))
        fixture_entry["end_alignment_errors_ms"].append(int(sample.get("end_alignment_error_ms", 0)))
    for fixture_entry in by_fixture.values():
        fixture_entry["start_alignment_error_summary_ms"] = {
            "min": min(fixture_entry["start_alignment_errors_ms"]),
            "max": max(fixture_entry["start_alignment_errors_ms"]),
            "mean": statistics.fmean(fixture_entry["start_alignment_errors_ms"]),
        }
        fixture_entry["end_alignment_error_summary_ms"] = {
            "min": min(fixture_entry["end_alignment_errors_ms"]),
            "max": max(fixture_entry["end_alignment_errors_ms"]),
            "mean": statistics.fmean(fixture_entry["end_alignment_errors_ms"]),
        }
        del fixture_entry["start_alignment_errors_ms"]
        del fixture_entry["end_alignment_errors_ms"]
    return {
        "capture_time_origin_offset_ms": {
            "min": min(offsets),
            "max": max(offsets),
            "mean": statistics.fmean(offsets),
            "unique_values": sorted(set(offsets)),
        },
        "start_alignment_error_ms": {
            "min": min(start_errors),
            "max": max(start_errors),
            "mean": statistics.fmean(start_errors),
        },
        "end_alignment_error_ms": {
            "min": min(end_errors),
            "max": max(end_errors),
            "mean": statistics.fmean(end_errors),
        },
        "by_fixture": by_fixture,
    }



def _export_dataset(
    repo_root: Path,
    manifest: dict,
    captures_dir: Path,
    frame_count: int,
    no_punch_window_ms: int,
    no_punch_stride_ms: int,
    max_no_punch_samples: int,
    max_transition_no_punch_samples: int,
) -> tuple[dict, dict]:
    samples = []
    fixture_summaries = []
    background_no_punch_candidates = []
    transition_no_punch_candidates = []

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
        fixture_background_candidate_ids = []
        fixture_transition_candidate_ids = []
        positive_window_count = 0
        for gesture_name, windows in gesture_windows.items():
            if gesture_name not in PUNCH_GESTURE_NAMES:
                continue
            for window_index, window in enumerate(windows, start=1):
                start_ms = int(window.get("start_ms", 0) or 0)
                end_ms = int(window.get("end_ms", 0) or 0)
                positive_window_count += 1
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
                    extra_metadata={
                        "negative_context": "n/a",
                        "repetition_index": window_index,
                    },
                )
                if sample is not None:
                    samples.append(sample)
                    fixture_positive_samples.append(sample["sample_id"])

        duration_ms = max(fixture_duration_ms(fixture_yaml), fixture.get("duration_ms", 0) or 0)
        non_punch_intervals = complement_intervals(0, duration_ms, punch_windows)
        candidate_intervals = iter_fixed_windows(non_punch_intervals, no_punch_window_ms, no_punch_stride_ms)
        is_punch_fixture = positive_window_count > 0

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
                extra_metadata={
                    "negative_context": "punch_fixture_background" if is_punch_fixture else "non_punch_fixture_background",
                },
            )
            if sample is None:
                continue
            background_no_punch_candidates.append(sample)
            fixture_background_candidate_ids.append(sample["sample_id"])

        punch_only_windows = []
        for gesture_name in sorted(PUNCH_GESTURE_NAMES):
            for window in _window_dicts_for_name(fixture_yaml, gesture_name):
                punch_only_windows.append((int(window.get("start_ms", 0) or 0), int(window.get("end_ms", 0) or 0), gesture_name))
        punch_only_windows.sort()

        for punch_index, (start_ms, end_ms, gesture_name) in enumerate(punch_only_windows, start=1):
            before_window = _safe_transition_window(non_punch_intervals, start_ms - no_punch_window_ms, start_ms)
            if before_window is not None:
                sample = extract_window_sample(
                    feature_snapshots,
                    capture_report,
                    "no_punch",
                    f"{fixture['id']}::transition_before::{punch_index:02d}",
                    fixture,
                    fixture_yaml,
                    before_window[0],
                    before_window[1],
                    frame_count=frame_count,
                    sample_kind="transition_before_punch",
                    source_window_index=punch_index,
                    source_gesture_name=gesture_name,
                    extra_metadata={
                        "negative_context": "transition_before_punch",
                        "repetition_index": punch_index,
                        "paired_punch_label": gesture_name,
                    },
                )
                if sample is not None:
                    transition_no_punch_candidates.append(sample)
                    fixture_transition_candidate_ids.append(sample["sample_id"])
            after_window = _safe_transition_window(non_punch_intervals, end_ms, end_ms + no_punch_window_ms)
            if after_window is not None:
                sample = extract_window_sample(
                    feature_snapshots,
                    capture_report,
                    "no_punch",
                    f"{fixture['id']}::transition_after::{punch_index:02d}",
                    fixture,
                    fixture_yaml,
                    after_window[0],
                    after_window[1],
                    frame_count=frame_count,
                    sample_kind="transition_after_punch",
                    source_window_index=punch_index,
                    source_gesture_name=gesture_name,
                    extra_metadata={
                        "negative_context": "transition_after_punch",
                        "repetition_index": punch_index,
                        "paired_punch_label": gesture_name,
                    },
                )
                if sample is not None:
                    transition_no_punch_candidates.append(sample)
                    fixture_transition_candidate_ids.append(sample["sample_id"])

        fixture_summaries.append(
            {
                "fixture_id": fixture["id"],
                "fixture_path": fixture["fixture_path"],
                "source_path": fixture["source_path"],
                "feature_snapshots_retained": len(feature_snapshots),
                "annotated_punch_sample_ids": fixture_positive_samples,
                "annotated_punch_window_count": positive_window_count,
                "background_no_punch_candidate_sample_ids": fixture_background_candidate_ids,
                "background_no_punch_candidate_count": len(fixture_background_candidate_ids),
                "transition_no_punch_candidate_sample_ids": fixture_transition_candidate_ids,
                "transition_no_punch_candidate_count": len(fixture_transition_candidate_ids),
                "duration_ms": duration_ms,
            }
        )

    selected_background_no_punch = evenly_pick(background_no_punch_candidates, max_no_punch_samples)
    selected_transition_no_punch = evenly_pick(transition_no_punch_candidates, max_transition_no_punch_samples)
    samples.extend(selected_background_no_punch)
    samples.extend(selected_transition_no_punch)
    samples.sort(key=lambda item: (PUNCH_CLASS_ORDER.index(item["label"]), str(item.get("source_fixture_id", "")), int(item.get("window_start_ms", 0)), str(item.get("sample_id", ""))))
    assign_chronological_holdout_splits(samples, holdout_ratio=0.25)

    sample_kind_counts = dict(Counter(sample["sample_kind"] for sample in samples))
    negative_context_counts = dict(Counter(sample.get("negative_context", "n/a") for sample in samples if sample["label"] == "no_punch"))
    export_summary = {
        "schema": "aerobeat.boxing_punch_classifier_export",
        "version": 2,
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
        "max_transition_no_punch_samples": max_transition_no_punch_samples,
        "split_strategy": "chronological_holdout_v1",
        "sample_count": len(samples),
        "label_counts": dict(Counter(sample["label"] for sample in samples)),
        "split_counts": dict(Counter(sample["split"] for sample in samples)),
        "sample_kind_counts": sample_kind_counts,
        "negative_context_counts": negative_context_counts,
        "alignment_summary": _summarize_alignment(samples),
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
    alignment_summary = export_summary.get("alignment_summary", {})
    lines = [
        "# Boxing Punch Classifier Export",
        "",
        f"- Exported at: `{export_summary['exported_at']}`",
        f"- Manifest: `{export_summary['manifest_path']}`",
        f"- Capture dir: `{export_summary['capture_dir']}`",
        f"- Class order: `{', '.join(export_summary['class_order'])}`",
        f"- Split strategy: `{export_summary.get('split_strategy', 'unknown')}`",
        f"- Window shape: `{export_summary['window_frame_count']} frames x {export_summary['frame_feature_count']} features/frame`",
        f"- Samples: **{export_summary['sample_count']}**",
        f"- Label counts: `{json.dumps(export_summary['label_counts'], sort_keys=True)}`",
        f"- Split counts: `{json.dumps(export_summary['split_counts'], sort_keys=True)}`",
        f"- Sample kinds: `{json.dumps(export_summary.get('sample_kind_counts', {}), sort_keys=True)}`",
        f"- No-punch contexts: `{json.dumps(export_summary.get('negative_context_counts', {}), sort_keys=True)}`",
        "",
        "## Alignment summary",
        "",
    ]
    if alignment_summary:
        offset_summary = alignment_summary.get("capture_time_origin_offset_ms", {})
        lines.extend(
            [
                f"- Capture time-origin offset ms (min/mean/max): **{offset_summary.get('min', 0)} / {offset_summary.get('mean', 0):.1f} / {offset_summary.get('max', 0)}**",
                f"- Window start alignment error ms (min/mean/max): **{alignment_summary.get('start_alignment_error_ms', {}).get('min', 0)} / {alignment_summary.get('start_alignment_error_ms', {}).get('mean', 0):.1f} / {alignment_summary.get('start_alignment_error_ms', {}).get('max', 0)}**",
                f"- Window end alignment error ms (min/mean/max): **{alignment_summary.get('end_alignment_error_ms', {}).get('min', 0)} / {alignment_summary.get('end_alignment_error_ms', {}).get('mean', 0):.1f} / {alignment_summary.get('end_alignment_error_ms', {}).get('max', 0)}**",
                "",
            ]
        )
        for fixture_id, fixture_alignment in sorted(alignment_summary.get("by_fixture", {}).items()):
            lines.extend(
                [
                    f"- `{fixture_id}` offset={fixture_alignment['capture_time_origin_offset_ms']}ms start_err={fixture_alignment['start_alignment_error_summary_ms']['mean']:.1f}ms end_err={fixture_alignment['end_alignment_error_summary_ms']['mean']:.1f}ms samples={fixture_alignment['sample_count']}",
                ]
            )
        lines.append("")
    lines.extend(["## Fixture export summary", ""])
    for fixture in export_summary["fixtures"]:
        lines.extend(
            [
                f"### {fixture['fixture_id']}",
                f"- Fixture YAML: `{fixture['fixture_path']}`",
                f"- Source video: `{fixture['source_path']}`",
                f"- Retained feature snapshots: **{fixture['feature_snapshots_retained']}**",
                f"- Annotated punch windows: **{fixture['annotated_punch_window_count']}**",
                f"- Background no-punch candidates: **{fixture['background_no_punch_candidate_count']}**",
                f"- Transition no-punch candidates: **{fixture['transition_no_punch_candidate_count']}**",
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
    parser.add_argument("--max-transition-no-punch-samples", type=int, default=DEFAULT_MAX_TRANSITION_NO_PUNCH_SAMPLES)
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
        max_transition_no_punch_samples=args.max_transition_no_punch_samples,
    )
    write_json(output_dir / "dataset.json", export_summary)
    write_json(output_dir / "threshold-baseline.json", threshold_summary)
    write_json(output_dir / "export-summary.json", {k: v for k, v in export_summary.items() if k != "samples"})
    (output_dir / "export-summary.md").write_text(_render_markdown(export_summary, threshold_summary), encoding="utf-8")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
