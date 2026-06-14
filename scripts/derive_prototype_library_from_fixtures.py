#!/usr/bin/env python3
import argparse
import json
import math
import os
import shutil
import subprocess
from pathlib import Path

import yaml

SUPPORTED_EVENT_TO_CLASS = {
    "punch_left": ("straight_left", "left"),
    "punch_right": ("straight_right", "right"),
    "hook_left": ("hook_left", "left"),
    "hook_right": ("hook_right", "right"),
    "uppercut_left": ("uppercut_left", "left"),
    "uppercut_right": ("uppercut_right", "right"),
}
FEATURE_NAMES = [
    "elbow_x_from_shoulder_over_shoulder_width",
    "elbow_y_from_shoulder_over_shoulder_width",
    "wrist_x_from_shoulder_over_shoulder_width",
    "wrist_y_from_shoulder_over_shoulder_width",
    "elbow_z_from_shoulder",
    "wrist_z_from_shoulder",
]
LANDMARK_IDS = {
    "left_shoulder": "11",
    "right_shoulder": "12",
    "left_elbow": "13",
    "right_elbow": "14",
    "left_wrist": "15",
    "right_wrist": "16",
}
DEFAULT_SAMPLE_COUNT = 5
DEFAULT_DISTANCE_SCALE = 0.45


def load_json(path: Path):
    with path.open("r", encoding="utf-8") as handle:
        return json.load(handle)


def load_yaml(path: Path):
    with path.open("r", encoding="utf-8") as handle:
        return yaml.safe_load(handle)


def ensure_clean_dir(path: Path) -> None:
    if path.exists():
        shutil.rmtree(path)
    path.mkdir(parents=True, exist_ok=True)


def rel_res_path(repo_root: Path, path: Path) -> str:
    return "res://" + path.relative_to(repo_root / ".testbed").as_posix()


def run_capture(repo_root: Path, fixture: dict, output_dir: Path, godot_bin: str, capture_delay_ms: int) -> dict:
    capture_dir = output_dir / "captures" / fixture["id"]
    ensure_clean_dir(capture_dir)

    source_path = (repo_root / fixture["source_path"]).resolve()
    fixture_path = (repo_root / fixture["fixture_path"]).resolve()
    if not source_path.exists():
        raise FileNotFoundError(f"fixture source missing: {source_path}")
    if not fixture_path.exists():
        raise FileNotFoundError(f"fixture yaml missing: {fixture_path}")

    env = os.environ.copy()
    env["AEROBEAT_CAMERA_TRACKING_SOURCE"] = str(source_path)
    env["AEROBEAT_PUNCH_BACKEND_OVERRIDE"] = "prototype_matcher"
    env["AEROBEAT_FIXTURE_STATE_TIMELINE_MODE"] = "full"

    cmd = [
        godot_bin,
        "--headless",
        "--path",
        ".testbed",
        "--script",
        "res://scripts/capture_fixture_proving.gd",
        "--",
        fixture.get("scene_path", "res://scenes/boxing_proving.tscn"),
        rel_res_path(repo_root, fixture_path),
        str(capture_dir),
        str(capture_delay_ms),
    ]
    log_path = capture_dir / "godot.log"
    with log_path.open("w", encoding="utf-8") as log_handle:
        process = subprocess.run(
            cmd,
            cwd=repo_root,
            env=env,
            stdout=log_handle,
            stderr=subprocess.STDOUT,
            check=False,
        )
    if process.returncode != 0:
        raise RuntimeError(f"capture failed for {fixture['id']} with exit code {process.returncode}; see {log_path}")
    report_path = capture_dir / "report.json"
    if not report_path.exists():
        raise FileNotFoundError(f"capture report missing for {fixture['id']}: {report_path}")
    return load_json(report_path)


def _landmark(landmarks_by_id: dict, key: str) -> dict:
    landmark = landmarks_by_id.get(LANDMARK_IDS[key], {})
    return landmark if isinstance(landmark, dict) else {}


def _extract_side_features(landmarks_by_id: dict, metrics: dict, side: str):
    measurements = metrics.get("measurements", {}) if isinstance(metrics.get("measurements", {}), dict) else {}
    shoulder_width = max(float(measurements.get("shoulder_width", 0.0)), 0.000001)
    shoulder = _landmark(landmarks_by_id, f"{side}_shoulder")
    elbow = _landmark(landmarks_by_id, f"{side}_elbow")
    wrist = _landmark(landmarks_by_id, f"{side}_wrist")
    if not shoulder or not elbow or not wrist:
        return None
    min_visibility = min(
        float(shoulder.get("v", 0.0)),
        float(elbow.get("v", 0.0)),
        float(wrist.get("v", 0.0)),
    )
    if min_visibility < 0.5:
        return None
    return [
        (float(elbow.get("x", 0.0)) - float(shoulder.get("x", 0.0))) / shoulder_width,
        (float(elbow.get("y", 0.0)) - float(shoulder.get("y", 0.0))) / shoulder_width,
        (float(wrist.get("x", 0.0)) - float(shoulder.get("x", 0.0))) / shoulder_width,
        (float(wrist.get("y", 0.0)) - float(shoulder.get("y", 0.0))) / shoulder_width,
        float(elbow.get("z", 0.0)) - float(shoulder.get("z", 0.0)),
        float(wrist.get("z", 0.0)) - float(shoulder.get("z", 0.0)),
    ]


def _resample_series(series: list[list[float]], target_count: int) -> list[list[float]]:
    if not series:
        return []
    if len(series) == target_count:
        return [[float(v) for v in row] for row in series]
    if target_count == 1:
        return [[float(v) for v in series[-1]]]
    result = []
    for idx in range(target_count):
        t = idx / float(target_count - 1)
        source_index = int(round(t * float(len(series) - 1)))
        source_index = max(0, min(source_index, len(series) - 1))
        result.append([float(v) for v in series[source_index]])
    return result


def _score_series(series_a: list[list[float]], series_b: list[list[float]]) -> float:
    sample_count = min(len(series_a), len(series_b))
    if sample_count <= 0:
        return 0.0
    total_distance = 0.0
    compared = 0
    for idx in range(sample_count):
        feature_count = min(len(series_a[idx]), len(series_b[idx]))
        if feature_count <= 0:
            continue
        frame_distance = 0.0
        for feature_idx in range(feature_count):
            frame_distance += abs(float(series_a[idx][feature_idx]) - float(series_b[idx][feature_idx]))
        total_distance += frame_distance / float(feature_count)
        compared += 1
    if compared <= 0:
        return 0.0
    return total_distance / float(compared)


def _derive_distance_scale(prototypes: list[dict]) -> float:
    by_class: dict[str, list[list[list[float]]]] = {}
    distances: list[float] = []
    for prototype in prototypes:
        by_class.setdefault(prototype["class_name"], []).append(prototype["samples"])
    for class_samples in by_class.values():
        if len(class_samples) < 2:
            continue
        for idx in range(len(class_samples)):
            best = None
            for other_idx in range(len(class_samples)):
                if idx == other_idx:
                    continue
                distance = _score_series(class_samples[idx], class_samples[other_idx])
                best = distance if best is None else min(best, distance)
            if best is not None:
                distances.append(best)
    if not distances:
        return DEFAULT_DISTANCE_SCALE
    distances.sort()
    percentile_index = min(len(distances) - 1, max(0, math.ceil(len(distances) * 0.9) - 1))
    return max(DEFAULT_DISTANCE_SCALE, round(distances[percentile_index] * 2.0, 4))


def _pose_snapshots(report: dict) -> list[dict]:
    fixture_capture = report.get("fixture_capture", {}) if isinstance(report.get("fixture_capture", {}), dict) else {}
    state_timeline = fixture_capture.get("state_timeline", []) if isinstance(fixture_capture.get("state_timeline", []), list) else []
    snapshots = []
    for entry in state_timeline:
        if not isinstance(entry, dict) or str(entry.get("reason", "")) != "pose_updated":
            continue
        pose_snapshot = entry.get("pose_snapshot", {}) if isinstance(entry.get("pose_snapshot", {}), dict) else {}
        if not pose_snapshot:
            continue
        snapshots.append(
            {
                "timestamp_ms": int(entry.get("timestamp_ms", pose_snapshot.get("timestamp_ms", 0))),
                "pose_snapshot": pose_snapshot,
            }
        )
    return snapshots


def _windows_for_event(fixture_yaml: dict, event_name: str) -> list[dict]:
    for gesture in fixture_yaml.get("expected_gestures", []) or []:
        if not isinstance(gesture, dict):
            continue
        if str(gesture.get("name", "")) != event_name:
            continue
        windows = gesture.get("windows", []) or []
        return [window for window in windows if isinstance(window, dict)]
    return []


def _capture_window_range_ms(capture_report: dict, start_ms: int, end_ms: int) -> tuple[int, int, dict]:
    fixture_capture = capture_report.get("fixture_capture", {}) if isinstance(capture_report.get("fixture_capture", {}), dict) else {}
    time_basis = str(fixture_capture.get("time_basis", ""))
    time_origin_reason = str(fixture_capture.get("time_origin_reason", ""))
    time_origin_offset_ms = int(fixture_capture.get("time_origin_offset_ms", 0) or 0)
    alignment = {
        "fixture_window_start_ms": start_ms,
        "fixture_window_end_ms": end_ms,
        "capture_window_start_ms": start_ms,
        "capture_window_end_ms": end_ms,
        "capture_time_basis": time_basis,
        "capture_time_origin_reason": time_origin_reason,
        "capture_time_origin_offset_ms": time_origin_offset_ms,
        "window_alignment_strategy": "fixture_window_direct",
    }
    if time_basis == "provider_tracking_ms_since_first_pose" and time_origin_offset_ms > 0:
        alignment["capture_window_start_ms"] = start_ms + time_origin_offset_ms
        alignment["capture_window_end_ms"] = end_ms + time_origin_offset_ms
        alignment["window_alignment_strategy"] = "fixture_window_plus_capture_time_origin_offset"
    return int(alignment["capture_window_start_ms"]), int(alignment["capture_window_end_ms"]), alignment


def derive_library(repo_root: Path, manifest: dict, captures_dir: Path, sample_count: int, library_id: str) -> tuple[dict, dict]:
    prototypes = []
    fixture_summaries = []
    classes_in_order = []
    skipped_windows = []
    for fixture in manifest.get("fixtures", []):
        expected_event = str(fixture.get("expected_event") or "")
        if expected_event not in SUPPORTED_EVENT_TO_CLASS:
            continue
        class_name, side = SUPPORTED_EVENT_TO_CLASS[expected_event]
        if class_name not in classes_in_order:
            classes_in_order.append(class_name)
        fixture_path = (repo_root / fixture["fixture_path"]).resolve()
        fixture_yaml = load_yaml(fixture_path)
        capture_report = load_json(captures_dir / "captures" / fixture["id"] / "report.json")
        snapshots = _pose_snapshots(capture_report)
        windows = _windows_for_event(fixture_yaml, expected_event)
        if not windows:
            raise ValueError(f"fixture {fixture['id']} has no verified windows for {expected_event}")
        window_summaries = []
        for window_index, window in enumerate(windows, start=1):
            start_ms = int(window.get("start_ms", 0))
            end_ms = int(window.get("end_ms", 0))
            capture_start_ms, capture_end_ms, alignment = _capture_window_range_ms(capture_report, start_ms, end_ms)
            matched_snapshots = [s for s in snapshots if capture_start_ms <= int(s["timestamp_ms"]) <= capture_end_ms]
            extracted_samples = []
            rejected_samples = 0
            source_timestamps = []
            for snapshot in matched_snapshots:
                pose_snapshot = snapshot["pose_snapshot"]
                landmarks_by_id = pose_snapshot.get("landmarks_by_id", {}) if isinstance(pose_snapshot.get("landmarks_by_id", {}), dict) else {}
                metrics = pose_snapshot.get("metrics", {}) if isinstance(pose_snapshot.get("metrics", {}), dict) else {}
                features = _extract_side_features(landmarks_by_id, metrics, side)
                if features is None:
                    rejected_samples += 1
                    continue
                extracted_samples.append(features)
                source_timestamps.append(int(snapshot["timestamp_ms"]))
            relative_fixture_path = fixture_path.relative_to(repo_root).as_posix()
            report_path = (captures_dir / "captures" / fixture["id"] / "report.json").relative_to(repo_root).as_posix()
            if not extracted_samples:
                skipped_windows.append(
                    {
                        "fixture_id": fixture["id"],
                        "fixture_path": relative_fixture_path,
                        "class_name": class_name,
                        "side": side,
                        "window_index": window_index,
                        "window_start_ms": start_ms,
                        "window_end_ms": end_ms,
                        "capture_report_path": report_path,
                        "reason": "no_valid_pose_samples",
                        "pose_samples_in_window": len(matched_snapshots),
                        "pose_samples_rejected": rejected_samples,
                        **alignment,
                    }
                )
                window_summaries.append(
                    {
                        "prototype_id": "",
                        "window_index": window_index,
                        "window_start_ms": start_ms,
                        "window_end_ms": end_ms,
                        "pose_samples_in_window": len(matched_snapshots),
                        "pose_samples_used": 0,
                        "pose_samples_rejected": rejected_samples,
                        "status": "skipped_no_valid_pose_samples",
                        **alignment,
                    }
                )
                continue
            resampled = _resample_series(extracted_samples, sample_count)
            prototype_id = f"{class_name}_{fixture['id']}_window_{window_index:02d}"
            prototypes.append(
                {
                    "id": prototype_id,
                    "class_name": class_name,
                    "side": side,
                    "source_ref": f"{relative_fixture_path}#window={window_index}",
                    "provenance": {
                        "fixture_id": str(fixture_yaml.get("fixture_id", fixture["id"])),
                        "fixture_path": relative_fixture_path,
                        "video_path": str(fixture.get("source_path", "")),
                        "capture_report_path": report_path,
                        "expected_event": expected_event,
                        "window_index": window_index,
                        "window_start_ms": start_ms,
                        "window_end_ms": end_ms,
                        "pose_samples_in_window": len(matched_snapshots),
                        "pose_samples_used": len(extracted_samples),
                        "pose_samples_rejected": rejected_samples,
                        "pose_sample_timestamps_ms": source_timestamps,
                        **alignment,
                    },
                    "samples": resampled,
                }
            )
            window_summaries.append(
                {
                    "prototype_id": prototype_id,
                    "window_index": window_index,
                    "window_start_ms": start_ms,
                    "window_end_ms": end_ms,
                    "pose_samples_in_window": len(matched_snapshots),
                    "pose_samples_used": len(extracted_samples),
                    "pose_samples_rejected": rejected_samples,
                    "status": "derived",
                    **alignment,
                }
            )
        fixture_summaries.append(
            {
                "fixture_id": fixture["id"],
                "fixture_path": fixture["fixture_path"],
                "source_path": fixture["source_path"],
                "expected_event": expected_event,
                "class_name": class_name,
                "side": side,
                "window_count": len(window_summaries),
                "windows": window_summaries,
            }
        )

    for class_name in classes_in_order:
        if not any(prototype["class_name"] == class_name for prototype in prototypes):
            raise ValueError(f"no derived prototypes available for class {class_name}")

    distance_scale = _derive_distance_scale(prototypes)
    library = {
        "schema": "aerobeat.prototype_library",
        "version": 1,
        "library_id": library_id,
        "profile": "boxing",
        "sample_count": sample_count,
        "distance_scale": distance_scale,
        "feature_names": FEATURE_NAMES,
        "classes": classes_in_order,
        "notes": [
            "Derived from verified boxing fixture videos via capture_fixture_proving.gd pose snapshots.",
            "Gesture truth comes from the human-verified YAML expected_gestures windows.",
            "Each prototype corresponds to one verified gesture window resampled to the matcher sample_count.",
        ],
        "prototypes": prototypes,
    }
    derivation_report = {
        "library_id": library_id,
        "manifest_path": str(manifest.get("_manifest_path", "")),
        "capture_delay_ms": int(manifest.get("capture_delay_ms", 0)),
        "sample_count": sample_count,
        "distance_scale": distance_scale,
        "prototype_count": len(prototypes),
        "skipped_window_count": len(skipped_windows),
        "skipped_windows": skipped_windows,
        "fixtures": fixture_summaries,
    }
    return library, derivation_report


def main() -> int:
    parser = argparse.ArgumentParser(description="Derive a prototype library from verified boxing fixture windows.")
    parser.add_argument(
        "--manifest",
        default=".testbed/assets/benchmarks/prototype_matcher_boxing_v1.benchmark.json",
        help="benchmark/fixture manifest JSON relative to the repo root",
    )
    parser.add_argument(
        "--output-library-id",
        default="boxing_side_aware_fixture_derived_v1",
        help="library id to write under assets/prototype_libraries/",
    )
    parser.add_argument("--godot", default="godot", help="Godot executable to use for headless captures")
    parser.add_argument("--capture-delay-ms", type=int, default=0, help="override fixture capture delay")
    parser.add_argument("--sample-count", type=int, default=DEFAULT_SAMPLE_COUNT, help="prototype matcher sample count")
    parser.add_argument(
        "--capture-output-dir",
        default=".temp/derived_prototype_library_from_fixtures",
        help="scratch dir for generated fixture capture reports relative to the repo root",
    )
    args = parser.parse_args()

    repo_root = Path(__file__).resolve().parents[1]
    manifest_path = Path(args.manifest)
    if not manifest_path.is_absolute():
        manifest_path = repo_root / manifest_path
    manifest = load_json(manifest_path)
    manifest["_manifest_path"] = str(manifest_path.relative_to(repo_root).as_posix())
    capture_delay_ms = int(args.capture_delay_ms or manifest.get("capture_delay_ms", 7000))

    captures_dir = Path(args.capture_output_dir)
    if not captures_dir.is_absolute():
        captures_dir = repo_root / captures_dir
    ensure_clean_dir(captures_dir)

    for fixture in manifest.get("fixtures", []):
        expected_event = str(fixture.get("expected_event") or "")
        if expected_event not in SUPPORTED_EVENT_TO_CLASS:
            continue
        run_capture(repo_root, fixture, captures_dir, args.godot, capture_delay_ms)

    library, derivation_report = derive_library(
        repo_root=repo_root,
        manifest=manifest,
        captures_dir=captures_dir,
        sample_count=max(1, int(args.sample_count)),
        library_id=args.output_library_id,
    )

    library_dir = repo_root / "assets" / "prototype_libraries" / args.output_library_id
    library_dir.mkdir(parents=True, exist_ok=True)
    library_path = library_dir / "library.json"
    report_path = library_dir / "derivation_report.json"
    readme_path = library_dir / "README.md"
    library_path.write_text(json.dumps(library, indent=2) + "\n", encoding="utf-8")
    report_path.write_text(json.dumps(derivation_report, indent=2) + "\n", encoding="utf-8")
    readme_path.write_text(
        "\n".join(
            [
                f"# {args.output_library_id}",
                "",
                "Derived prototype library for the boxing prototype matcher.",
                "",
                "## Provenance",
                "",
                f"- Manifest: `{manifest['_manifest_path']}`",
                "- Fixture source: `.testbed/assets/fixtures/boxing/` verified YAML windows + matching MP4s",
                "- Pose generation path: `.testbed/scripts/capture_fixture_proving.gd` -> `proving_harness.gd` full pose snapshots",
                f"- Derived library: `{library_path.relative_to(repo_root).as_posix()}`",
                f"- Derivation report: `{report_path.relative_to(repo_root).as_posix()}`",
                f"- Scratch captures: `{captures_dir.relative_to(repo_root).as_posix()}`",
                "",
                "## Regenerate",
                "",
                "```bash",
                f"python3 scripts/derive_prototype_library_from_fixtures.py --manifest {manifest['_manifest_path']} --output-library-id {args.output_library_id}",
                "```",
                "",
                "Each prototype corresponds to one human-verified gesture window from a fixture YAML file. The pose samples come from headless fixture replay capture reports, not manual seed editing.",
                "",
            ]
        ),
        encoding="utf-8",
    )

    print(f"[derive] wrote {library_path}")
    print(f"[derive] wrote {report_path}")
    print(f"[derive] wrote {readme_path}")
    print(f"[derive] prototype_count={len(library['prototypes'])} distance_scale={library['distance_scale']}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
