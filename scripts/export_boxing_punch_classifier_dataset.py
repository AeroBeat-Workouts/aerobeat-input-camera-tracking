#!/usr/bin/env python3
from __future__ import annotations

import argparse
import hashlib
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
    FEATURE_SET_BASELINE_V1,
    MASK_PROFILE_HOOK_UPPERCUT_FAMILY_V1,
    MASK_PROFILE_STRAIGHT_FAMILY_V1,
    SUPPORTED_FEATURE_SETS,
    PUNCH_CLASS_ORDER,
    PUNCH_GESTURE_NAMES,
    assign_chronological_holdout_splits,
    build_feature_snapshots,
    complement_intervals,
    derive_masked_dataset,
    ensure_clean_dir,
    evenly_pick,
    extract_window_sample,
    feature_names_per_side,
    fixture_duration_ms,
    format_confusion_markdown,
    frame_feature_names,
    normalize_feature_set,
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


def _load_snapshot_manifest(repo_root: Path, snapshot_manifest_path: str) -> dict:
    snapshot_file = (repo_root / snapshot_manifest_path).resolve()
    snapshot = load_json(snapshot_file)
    snapshot["_snapshot_manifest_path"] = snapshot_manifest_path
    return snapshot


def _sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def _verify_snapshot_inputs(repo_root: Path, snapshot: dict, manifest_path: str, captures_dir: Path) -> dict:
    benchmark_manifest = snapshot.get("benchmark_manifest", {}) if isinstance(snapshot.get("benchmark_manifest", {}), dict) else {}
    expected_manifest_path = str(benchmark_manifest.get("path", "")).strip()
    if expected_manifest_path and expected_manifest_path != manifest_path:
        raise ValueError(
            f"snapshot manifest expects benchmark manifest {expected_manifest_path}, got {manifest_path}"
        )
    manifest_file = (repo_root / manifest_path).resolve()
    if benchmark_manifest.get("sha256") and _sha256_file(manifest_file) != str(benchmark_manifest.get("sha256")):
        raise ValueError(f"benchmark manifest hash mismatch for {manifest_path}")

    capture_source = snapshot.get("capture_report_source", {}) if isinstance(snapshot.get("capture_report_source", {}), dict) else {}
    expected_capture_dir = str(capture_source.get("root_dir", "")).strip()
    expected_capture_dir_rel = Path(expected_capture_dir).as_posix() if expected_capture_dir else ""
    actual_capture_dir_rel = captures_dir.relative_to(repo_root).as_posix()
    if expected_capture_dir_rel and expected_capture_dir_rel != actual_capture_dir_rel:
        raise ValueError(
            f"snapshot manifest expects captures dir {expected_capture_dir_rel}, got {actual_capture_dir_rel}"
        )

    file_verification = {
        "manifest_sha256": _sha256_file(manifest_file),
        "fixtures": [],
        "capture_reports": [],
    }
    for fixture_entry in snapshot.get("fixtures", []) or []:
        if not isinstance(fixture_entry, dict):
            continue
        fixture_path = str(fixture_entry.get("fixture_path", "")).strip()
        source_path = str(fixture_entry.get("source_path", "")).strip()
        fixture_file = (repo_root / fixture_path).resolve()
        source_file = (repo_root / source_path).resolve()
        actual_fixture_sha = _sha256_file(fixture_file)
        actual_source_sha = _sha256_file(source_file)
        if fixture_entry.get("fixture_sha256") and actual_fixture_sha != str(fixture_entry.get("fixture_sha256")):
            raise ValueError(f"fixture YAML hash mismatch for {fixture_path}")
        if fixture_entry.get("source_sha256") and actual_source_sha != str(fixture_entry.get("source_sha256")):
            raise ValueError(f"fixture video hash mismatch for {source_path}")
        file_verification["fixtures"].append(
            {
                "fixture_id": fixture_entry.get("fixture_id", ""),
                "fixture_path": fixture_path,
                "fixture_sha256": actual_fixture_sha,
                "source_path": source_path,
                "source_sha256": actual_source_sha,
            }
        )

    for report_entry in capture_source.get("reports", []) or []:
        if not isinstance(report_entry, dict):
            continue
        report_path = str(report_entry.get("report_path", "")).strip()
        report_file = (repo_root / report_path).resolve()
        actual_report_sha = _sha256_file(report_file)
        if report_entry.get("report_sha256") and actual_report_sha != str(report_entry.get("report_sha256")):
            raise ValueError(f"capture report hash mismatch for {report_path}")
        file_verification["capture_reports"].append(
            {
                "fixture_id": report_entry.get("fixture_id", ""),
                "report_path": report_path,
                "report_sha256": actual_report_sha,
            }
        )
    return file_verification


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



def _resolve_export_artifact_metadata(snapshot: dict | None = None) -> dict:
    metadata = snapshot.get("export_artifact_metadata", {}) if snapshot and isinstance(snapshot.get("export_artifact_metadata", {}), dict) else {}
    exported_at = str(metadata.get("exported_at", "")).strip()
    if not exported_at:
        exported_at = datetime.now(timezone.utc).isoformat()
    version = int(metadata.get("version", 3) or 3)
    return {
        "version": version,
        "exported_at": exported_at,
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
    feature_set: str = FEATURE_SET_BASELINE_V1,
    snapshot: dict | None = None,
    snapshot_verification: dict | None = None,
) -> tuple[dict, dict]:
    resolved_feature_set = normalize_feature_set(feature_set)
    resolved_side_feature_names = feature_names_per_side(resolved_feature_set)
    resolved_frame_feature_names = frame_feature_names(resolved_feature_set)
    samples = []
    fixture_summaries = []
    background_no_punch_candidates = []
    transition_no_punch_candidates = []

    for fixture in manifest.get("fixtures", []):
        fixture_path = (repo_root / fixture["fixture_path"]).resolve()
        fixture_yaml = load_yaml(fixture_path)
        capture_report = load_json(captures_dir / "captures" / fixture["id"] / "report.json")
        feature_snapshots = build_feature_snapshots(capture_report, feature_set=resolved_feature_set)

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
                    feature_set=resolved_feature_set,
                    frame_feature_names_override=resolved_frame_feature_names,
                    side_feature_names_override=resolved_side_feature_names,
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
                feature_set=resolved_feature_set,
                frame_feature_names_override=resolved_frame_feature_names,
                side_feature_names_override=resolved_side_feature_names,
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
                    feature_set=resolved_feature_set,
                    frame_feature_names_override=resolved_frame_feature_names,
                    side_feature_names_override=resolved_side_feature_names,
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
                    feature_set=resolved_feature_set,
                    frame_feature_names_override=resolved_frame_feature_names,
                    side_feature_names_override=resolved_side_feature_names,
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
    export_artifact_metadata = _resolve_export_artifact_metadata(snapshot)
    export_summary = {
        "schema": "aerobeat.boxing_punch_classifier_export",
        "version": export_artifact_metadata["version"],
        "exported_at": export_artifact_metadata["exported_at"],
        "manifest_path": manifest["_manifest_path"],
        "capture_dir": captures_dir.relative_to(repo_root).as_posix(),
        "window_frame_count": frame_count,
        "feature_set": resolved_feature_set,
        "frame_feature_count": len(resolved_frame_feature_names),
        "side_feature_names": list(resolved_side_feature_names),
        "frame_feature_names": list(resolved_frame_feature_names),
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
        "source_snapshot": {
            "snapshot_id": snapshot.get("snapshot_id", "") if snapshot else "",
            "snapshot_manifest_path": snapshot.get("_snapshot_manifest_path", "") if snapshot else "",
            "anchor_artifacts": {
                "dataset_path": str(snapshot.get("dataset_anchor", {}).get("dataset_path", "")) if snapshot else "",
                "export_summary_path": str(snapshot.get("dataset_anchor", {}).get("export_summary_path", "")) if snapshot else "",
                "threshold_baseline_path": str(snapshot.get("dataset_anchor", {}).get("threshold_baseline_path", "")) if snapshot else "",
                "threshold_baseline_sha256": str(snapshot.get("dataset_anchor", {}).get("threshold_baseline_sha256", "")) if snapshot else "",
            },
            "capture_report_source": snapshot.get("capture_report_source", {}) if snapshot else {},
            "export_parameters": snapshot.get("export_parameters", {}) if snapshot else {},
            "file_verification": snapshot_verification or {},
        },
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
    source_snapshot = export_summary.get("source_snapshot", {}) if isinstance(export_summary.get("source_snapshot", {}), dict) else {}
    lines = [
        "# Boxing Punch Classifier Export",
        "",
        f"- Exported at: `{export_summary['exported_at']}`",
        f"- Manifest: `{export_summary['manifest_path']}`",
        f"- Capture dir: `{export_summary['capture_dir']}`",
        f"- Snapshot ID: `{source_snapshot.get('snapshot_id', '') or 'none'}`",
        f"- Snapshot manifest: `{source_snapshot.get('snapshot_manifest_path', '') or 'none'}`",
        f"- Class order: `{', '.join(export_summary['class_order'])}`",
        f"- Split strategy: `{export_summary.get('split_strategy', 'unknown')}`",
        f"- Window shape: `{export_summary['window_frame_count']} frames x {export_summary['frame_feature_count']} features/frame`",
        f"- Samples: **{export_summary['sample_count']}**",
        f"- Label counts: `{json.dumps(export_summary['label_counts'], sort_keys=True)}`",
        f"- Split counts: `{json.dumps(export_summary['split_counts'], sort_keys=True)}`",
        f"- Sample kinds: `{json.dumps(export_summary.get('sample_kind_counts', {}), sort_keys=True)}`",
        f"- No-punch contexts: `{json.dumps(export_summary.get('negative_context_counts', {}), sort_keys=True)}`",
    ]
    mask_inventory = export_summary.get("mask_inventory", {}) if isinstance(export_summary.get("mask_inventory", {}), dict) else {}
    derived_from = export_summary.get("derived_from", {}) if isinstance(export_summary.get("derived_from", {}), dict) else {}
    if mask_inventory:
        lines.extend(
            [
                f"- Mask profile: `{mask_inventory.get('mask_profile', '')}`",
                f"- Active side features: `{json.dumps(mask_inventory.get('active_side_feature_names', []))}`",
                f"- Masked side features: `{json.dumps(mask_inventory.get('masked_side_feature_names', []))}`",
            ]
        )
    if derived_from:
        lines.extend(
            [
                f"- Derived from feature set: `{derived_from.get('source_feature_set', '')}`",
                f"- Derived from frame feature count: **{derived_from.get('source_frame_feature_count', 0)}**",
                f"- Derived from sample count: **{derived_from.get('source_sample_count', 0)}**",
            ]
        )
    lines.extend(["", "## Frozen source snapshot", ""])
    if source_snapshot.get("snapshot_id"):
        anchor_artifacts = source_snapshot.get("anchor_artifacts", {}) if isinstance(source_snapshot.get("anchor_artifacts", {}), dict) else {}
        capture_report_source = source_snapshot.get("capture_report_source", {}) if isinstance(source_snapshot.get("capture_report_source", {}), dict) else {}
        export_parameters = source_snapshot.get("export_parameters", {}) if isinstance(source_snapshot.get("export_parameters", {}), dict) else {}
        lines.extend(
            [
                f"- Capture package: `{capture_report_source.get('package_id', '')}`",
                f"- Capture source root: `{capture_report_source.get('root_dir', '')}`",
                f"- Alignment basis: `{capture_report_source.get('alignment_basis', '')}`",
                f"- Dataset anchor path: `{anchor_artifacts.get('dataset_path', '')}`",
                f"- Export summary anchor path: `{anchor_artifacts.get('export_summary_path', '')}`",
                f"- Threshold anchor: `{anchor_artifacts.get('threshold_baseline_path', '')}` sha256=`{anchor_artifacts.get('threshold_baseline_sha256', '')}`",
                f"- Export parameters: `{json.dumps(export_parameters, sort_keys=True)}`",
                "",
            ]
        )
    else:
        lines.extend(["- No explicit frozen snapshot manifest supplied.", ""])
    lines.extend([
        "## Alignment summary",
        "",
    ])
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
    parser.add_argument("--snapshot-manifest", help="Frozen snapshot manifest JSON relative to the repo root. When set, manifest/captures/export parameters are resolved from the snapshot unless explicitly overridden later in code.")
    parser.add_argument("--source-dataset", help="Existing dataset.json relative to the repo root. When set, derive a masked family/head export from that dataset instead of rerunning capture export.")
    parser.add_argument("--mask-profile", choices=[MASK_PROFILE_STRAIGHT_FAMILY_V1, MASK_PROFILE_HOOK_UPPERCUT_FAMILY_V1], help="Family/head mask profile to derive from --source-dataset.")
    parser.add_argument("--derived-feature-set", help="Optional metadata name for a derived masked dataset feature_set.")
    parser.add_argument("--output-dir", required=True, help="Directory for export-summary.{json,md} and dataset.json")
    parser.add_argument("--godot", default=DEFAULT_GODOT_BIN)
    parser.add_argument("--capture-delay-ms", type=int, default=7000)
    parser.add_argument("--frame-count", type=int, default=DEFAULT_WINDOW_FRAME_COUNT)
    parser.add_argument("--no-punch-window-ms", type=int, default=DEFAULT_THRESHOLD_WINDOW_MS)
    parser.add_argument("--no-punch-stride-ms", type=int, default=DEFAULT_NO_PUNCH_STRIDE_MS)
    parser.add_argument("--max-no-punch-samples", type=int, default=DEFAULT_MAX_NO_PUNCH_SAMPLES)
    parser.add_argument("--max-transition-no-punch-samples", type=int, default=DEFAULT_MAX_TRANSITION_NO_PUNCH_SAMPLES)
    parser.add_argument("--feature-set", default=FEATURE_SET_BASELINE_V1, choices=SUPPORTED_FEATURE_SETS, help="Feature schema to export/train with.")
    parser.add_argument("--skip-captures", action="store_true", help="Reuse existing report.json files under --captures-dir instead of rerunning Godot capture.")
    args = parser.parse_args()

    repo_root = _repo_root()
    output_dir = (repo_root / args.output_dir).resolve()
    ensure_clean_dir(output_dir)

    if args.source_dataset:
        if not args.mask_profile:
            raise ValueError("--mask-profile is required when using --source-dataset")
        source_dataset_path = (repo_root / args.source_dataset).resolve()
        source_dataset = load_json(source_dataset_path)
        export_summary, threshold_summary = derive_masked_dataset(
            source_dataset,
            mask_profile=args.mask_profile,
            derived_feature_set=args.derived_feature_set or args.mask_profile,
        )
        export_summary.setdefault("manifest_path", str(source_dataset.get("manifest_path", "")))
        export_summary.setdefault("capture_dir", str(source_dataset.get("capture_dir", "")))
        export_summary.setdefault("exported_at", datetime.now(timezone.utc).isoformat())
        export_summary.setdefault("version", int(source_dataset.get("version", 1) or 1))
        export_summary.setdefault("window_frame_count", int(source_dataset.get("window_frame_count", 0) or 0))
        export_summary.setdefault("split_strategy", str(source_dataset.get("split_strategy", "unknown")))
        export_summary.setdefault("split_counts", dict(source_dataset.get("split_counts", {})))
        export_summary.setdefault("sample_kind_counts", dict(source_dataset.get("sample_kind_counts", {})))
        export_summary.setdefault("negative_context_counts", dict(source_dataset.get("negative_context_counts", {})))
        export_summary["source_dataset_path"] = args.source_dataset
        write_json(output_dir / "dataset.json", export_summary)
        write_json(output_dir / "threshold-baseline.json", threshold_summary)
        write_json(output_dir / "export-summary.json", {k: v for k, v in export_summary.items() if k != "samples"})
        (output_dir / "export-summary.md").write_text(_render_markdown(export_summary, threshold_summary), encoding="utf-8")
        return 0

    snapshot = _load_snapshot_manifest(repo_root, args.snapshot_manifest) if args.snapshot_manifest else None
    resolved_manifest_path = args.manifest
    resolved_captures_dir = args.captures_dir
    resolved_frame_count = args.frame_count
    resolved_no_punch_window_ms = args.no_punch_window_ms
    resolved_no_punch_stride_ms = args.no_punch_stride_ms
    resolved_max_no_punch_samples = args.max_no_punch_samples
    resolved_max_transition_no_punch_samples = args.max_transition_no_punch_samples
    resolved_feature_set = normalize_feature_set(args.feature_set)
    if snapshot:
        benchmark_manifest = snapshot.get("benchmark_manifest", {}) if isinstance(snapshot.get("benchmark_manifest", {}), dict) else {}
        export_parameters = snapshot.get("export_parameters", {}) if isinstance(snapshot.get("export_parameters", {}), dict) else {}
        capture_report_source = snapshot.get("capture_report_source", {}) if isinstance(snapshot.get("capture_report_source", {}), dict) else {}
        resolved_manifest_path = str(benchmark_manifest.get("path") or resolved_manifest_path)
        resolved_captures_dir = str(capture_report_source.get("root_dir") or resolved_captures_dir)
        resolved_frame_count = int(export_parameters.get("frame_count", resolved_frame_count))
        resolved_no_punch_window_ms = int(export_parameters.get("no_punch_window_ms", resolved_no_punch_window_ms))
        resolved_no_punch_stride_ms = int(export_parameters.get("no_punch_stride_ms", resolved_no_punch_stride_ms))
        resolved_max_no_punch_samples = int(export_parameters.get("max_no_punch_samples", resolved_max_no_punch_samples))
        resolved_max_transition_no_punch_samples = int(export_parameters.get("max_transition_no_punch_samples", resolved_max_transition_no_punch_samples))
        resolved_feature_set = normalize_feature_set(export_parameters.get("feature_set", resolved_feature_set))

    manifest = _load_manifest(repo_root, resolved_manifest_path)
    captures_dir = (repo_root / resolved_captures_dir).resolve()
    if not args.skip_captures:
        ensure_clean_dir(captures_dir)
        for fixture in manifest.get("fixtures", []):
            run_capture(repo_root, fixture, captures_dir, godot_bin=args.godot, capture_delay_ms=args.capture_delay_ms)

    snapshot_verification = None
    if snapshot:
        snapshot_verification = _verify_snapshot_inputs(repo_root, snapshot, resolved_manifest_path, captures_dir)

    export_summary, threshold_summary = _export_dataset(
        repo_root,
        manifest,
        captures_dir,
        frame_count=resolved_frame_count,
        no_punch_window_ms=resolved_no_punch_window_ms,
        no_punch_stride_ms=resolved_no_punch_stride_ms,
        max_no_punch_samples=resolved_max_no_punch_samples,
        max_transition_no_punch_samples=resolved_max_transition_no_punch_samples,
        feature_set=resolved_feature_set,
        snapshot=snapshot,
        snapshot_verification=snapshot_verification,
    )
    write_json(output_dir / "dataset.json", export_summary)
    write_json(output_dir / "threshold-baseline.json", threshold_summary)
    write_json(output_dir / "export-summary.json", {k: v for k, v in export_summary.items() if k != "samples"})
    (output_dir / "export-summary.md").write_text(_render_markdown(export_summary, threshold_summary), encoding="utf-8")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
