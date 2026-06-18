#!/usr/bin/env python3
"""Shared export/eval helpers for boxing punch-classifier experiments.

This harness intentionally stays model-agnostic so the temporal MLP baseline and
follow-up temporal CNN can share the same capture, export, split, and threshold
comparison path.
"""

from __future__ import annotations

import json
import math
import os
import shutil
import subprocess
from collections import Counter
from pathlib import Path
from typing import Iterable

import yaml

PUNCH_EVENT_TO_CLASS = {
    "punch_left": "straight_left",
    "punch_right": "straight_right",
    "hook_left": "hook_left",
    "hook_right": "hook_right",
    "uppercut_left": "uppercut_left",
    "uppercut_right": "uppercut_right",
}
PUNCH_CLASS_TO_EVENT = {value: key for key, value in PUNCH_EVENT_TO_CLASS.items()}
PUNCH_CLASS_ORDER = [
    "straight_left",
    "straight_right",
    "hook_left",
    "hook_right",
    "uppercut_left",
    "uppercut_right",
    "no_punch",
]
PUNCH_GESTURE_NAMES = set(PUNCH_CLASS_TO_EVENT.keys())
LANDMARK_IDS = {
    "left_shoulder": "11",
    "right_shoulder": "12",
    "left_elbow": "13",
    "right_elbow": "14",
    "left_wrist": "15",
    "right_wrist": "16",
}
FEATURE_SET_BASELINE_V1 = "baseline_v1"
FEATURE_SET_CAMERA_DIRECTIONAL_V1 = "camera_directional_v1"
FEATURE_SET_BODY_DIRECTIONAL_V1 = "body_directional_v1"
FEATURE_SET_COMBINED_DIRECTIONAL_V1 = "combined_directional_v1"
FEATURE_SET_FAMILY_CAMERA_DIRECTIONAL_V1 = "family_camera_directional_v1"
FEATURE_SET_FAMILY_BODY_DIRECTIONAL_V1 = "family_body_directional_v1"
FEATURE_SET_FAMILY_COMBINED_DIRECTIONAL_V1 = "family_combined_directional_v1"
SUPPORTED_FEATURE_SETS = [
    FEATURE_SET_BASELINE_V1,
    FEATURE_SET_CAMERA_DIRECTIONAL_V1,
    FEATURE_SET_BODY_DIRECTIONAL_V1,
    FEATURE_SET_COMBINED_DIRECTIONAL_V1,
    FEATURE_SET_FAMILY_CAMERA_DIRECTIONAL_V1,
    FEATURE_SET_FAMILY_BODY_DIRECTIONAL_V1,
    FEATURE_SET_FAMILY_COMBINED_DIRECTIONAL_V1,
]
BASELINE_FEATURE_NAMES_PER_SIDE = [
    "shoulder_x",
    "shoulder_y",
    "elbow_x",
    "elbow_y",
    "wrist_x",
    "wrist_y",
    "combined_elbow_wrist_velocity_xy_magnitude",
    "elbow_shoulder_xy_distance_over_shoulder_width",
]
STRAIGHT_FAMILY_FEATURE_NAMES_PER_SIDE = [
    "elbow_x_from_shoulder_over_shoulder_width",
    "elbow_y_from_shoulder_over_shoulder_width",
    "elbow_shoulder_radial_velocity_over_shoulder_width",
]
CAMERA_DIRECTIONAL_FEATURE_NAMES_PER_SIDE = [
    "camera_signed_vx",
    "camera_signed_vy",
    "camera_direction_none",
    "camera_direction_up",
    "camera_direction_down",
    "camera_direction_left",
    "camera_direction_right",
]
BODY_DIRECTIONAL_FEATURE_NAMES_PER_SIDE = [
    "body_signed_vx",
    "body_signed_vy",
    "body_direction_none",
    "body_direction_up",
    "body_direction_down",
    "body_direction_left",
    "body_direction_right",
]
CAMERA_WRIST_DIRECTIONAL_FEATURE_NAMES_PER_SIDE = [
    "camera_wrist_signed_vx",
    "camera_wrist_signed_vy",
    "camera_wrist_direction_none",
    "camera_wrist_direction_up",
    "camera_wrist_direction_down",
    "camera_wrist_direction_left",
    "camera_wrist_direction_right",
]
BODY_WRIST_DIRECTIONAL_FEATURE_NAMES_PER_SIDE = [
    "body_wrist_signed_vx",
    "body_wrist_signed_vy",
    "body_wrist_direction_none",
    "body_wrist_direction_up",
    "body_wrist_direction_down",
    "body_wrist_direction_left",
    "body_wrist_direction_right",
]


def normalize_feature_set(feature_set: str | None) -> str:
    candidate = str(feature_set or FEATURE_SET_BASELINE_V1).strip() or FEATURE_SET_BASELINE_V1
    if candidate not in SUPPORTED_FEATURE_SETS:
        raise ValueError(f"unsupported feature_set '{candidate}' (expected one of {SUPPORTED_FEATURE_SETS})")
    return candidate


def feature_names_per_side(feature_set: str | None = None) -> list[str]:
    resolved = normalize_feature_set(feature_set)
    names = list(BASELINE_FEATURE_NAMES_PER_SIDE)
    if resolved in (
        FEATURE_SET_FAMILY_CAMERA_DIRECTIONAL_V1,
        FEATURE_SET_FAMILY_BODY_DIRECTIONAL_V1,
        FEATURE_SET_FAMILY_COMBINED_DIRECTIONAL_V1,
    ):
        names.extend(STRAIGHT_FAMILY_FEATURE_NAMES_PER_SIDE)
    if resolved in (FEATURE_SET_CAMERA_DIRECTIONAL_V1, FEATURE_SET_COMBINED_DIRECTIONAL_V1):
        names.extend(CAMERA_DIRECTIONAL_FEATURE_NAMES_PER_SIDE)
    if resolved in (FEATURE_SET_BODY_DIRECTIONAL_V1, FEATURE_SET_COMBINED_DIRECTIONAL_V1):
        names.extend(BODY_DIRECTIONAL_FEATURE_NAMES_PER_SIDE)
    if resolved in (FEATURE_SET_FAMILY_CAMERA_DIRECTIONAL_V1, FEATURE_SET_FAMILY_COMBINED_DIRECTIONAL_V1):
        names.extend(CAMERA_WRIST_DIRECTIONAL_FEATURE_NAMES_PER_SIDE)
    if resolved in (FEATURE_SET_FAMILY_BODY_DIRECTIONAL_V1, FEATURE_SET_FAMILY_COMBINED_DIRECTIONAL_V1):
        names.extend(BODY_WRIST_DIRECTIONAL_FEATURE_NAMES_PER_SIDE)
    return names


def frame_feature_names(feature_set: str | None = None) -> list[str]:
    per_side = feature_names_per_side(feature_set)
    return [f"left_{name}" for name in per_side] + [f"right_{name}" for name in per_side]


FEATURE_NAMES_PER_SIDE = feature_names_per_side(FEATURE_SET_BASELINE_V1)
FRAME_FEATURE_NAMES = frame_feature_names(FEATURE_SET_BASELINE_V1)
DEFAULT_WINDOW_FRAME_COUNT = 8
DEFAULT_THRESHOLD_WINDOW_MS = 250
DEFAULT_NO_PUNCH_STRIDE_MS = 250
DEFAULT_MAX_NO_PUNCH_SAMPLES = 48
DEFAULT_MAX_TRANSITION_NO_PUNCH_SAMPLES = 24
DEFAULT_GODOT_BIN = "godot"


def load_json(path: Path):
    with path.open("r", encoding="utf-8") as handle:
        return json.load(handle)


def write_json(path: Path, payload) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", encoding="utf-8") as handle:
        json.dump(payload, handle, indent=2)
        handle.write("\n")


def load_yaml(path: Path):
    with path.open("r", encoding="utf-8") as handle:
        return yaml.safe_load(handle)


def ensure_clean_dir(path: Path) -> None:
    if path.exists():
        shutil.rmtree(path)
    path.mkdir(parents=True, exist_ok=True)


def rel_res_path(repo_root: Path, path: Path) -> str:
    return "res://" + path.relative_to(repo_root / ".testbed").as_posix()


def run_capture(
    repo_root: Path,
    fixture: dict,
    output_dir: Path,
    godot_bin: str = DEFAULT_GODOT_BIN,
    capture_delay_ms: int = 0,
    punch_backend: str | None = None,
) -> dict:
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
    env["AEROBEAT_FIXTURE_STATE_TIMELINE_MODE"] = "full"
    if punch_backend:
        env["AEROBEAT_PUNCH_BACKEND_OVERRIDE"] = punch_backend

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


def _gesture_windows_by_name(fixture_yaml: dict) -> dict[str, list[dict]]:
    result: dict[str, list[dict]] = {}
    for gesture in fixture_yaml.get("expected_gestures", []) or []:
        if not isinstance(gesture, dict):
            continue
        name = str(gesture.get("name", "")).strip()
        if not name:
            continue
        windows = [window for window in (gesture.get("windows", []) or []) if isinstance(window, dict)]
        result.setdefault(name, []).extend(windows)
    return result


def fixture_duration_ms(fixture_yaml: dict) -> int:
    max_end = 0
    for windows in _gesture_windows_by_name(fixture_yaml).values():
        for window in windows:
            max_end = max(max_end, int(window.get("end_ms", 0) or 0))
    return max_end


def capture_window_range_ms(capture_report: dict, start_ms: int, end_ms: int) -> tuple[int, int, dict]:
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


def pose_snapshots(capture_report: dict) -> list[dict]:
    fixture_capture = capture_report.get("fixture_capture", {}) if isinstance(capture_report.get("fixture_capture", {}), dict) else {}
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


def attack_events(capture_report: dict) -> list[dict]:
    fixture_capture = capture_report.get("fixture_capture", {}) if isinstance(capture_report.get("fixture_capture", {}), dict) else {}
    event_timeline = fixture_capture.get("event_timeline", []) if isinstance(fixture_capture.get("event_timeline", []), list) else []
    events = []
    for entry in event_timeline:
        if not isinstance(entry, dict):
            continue
        name = str(entry.get("name", "")).strip()
        if name not in PUNCH_EVENT_TO_CLASS:
            continue
        payload = entry.get("payload", {}) if isinstance(entry.get("payload", {}), dict) else {}
        events.append(
            {
                "name": name,
                "class_name": PUNCH_EVENT_TO_CLASS[name],
                "timestamp_ms": int(entry.get("timestamp_ms", 0)),
                "count": int(entry.get("count", 0)),
                "power": float(payload.get("power", 0.0)),
                "backend": str(payload.get("backend", "threshold_gates") or "threshold_gates"),
            }
        )
    return events


def _landmark(landmarks_by_id: dict, key: str) -> dict:
    landmark = landmarks_by_id.get(LANDMARK_IDS[key], {})
    return landmark if isinstance(landmark, dict) else {}


def _distance_2d(a: dict, b: dict) -> float:
    return math.hypot(float(a.get("x", 0.0)) - float(b.get("x", 0.0)), float(a.get("y", 0.0)) - float(b.get("y", 0.0)))


def _resolve_signal_position(landmark: dict) -> tuple[float, float]:
    return (float(landmark.get("x", 0.0)), float(landmark.get("y", 0.0)))


def _resolve_combined_elbow_wrist_signal_position(elbow: dict, wrist: dict) -> tuple[float, float]:
    return (
        (float(elbow.get("x", 0.0)) + float(wrist.get("x", 0.0))) * 0.5,
        (float(elbow.get("y", 0.0)) + float(wrist.get("y", 0.0))) * 0.5,
    )


def _resolve_recent_velocity_components(history: list[dict], timestamp_ms: int, signal_position: tuple[float, float]) -> tuple[float, float]:
    entries = list(history)
    entries.append({"timestamp_ms": timestamp_ms, "signal_position": signal_position})
    if len(entries) < 2:
        return 0.0, 0.0
    velocity_sum_x = 0.0
    velocity_sum_y = 0.0
    velocity_sample_count = 0
    for index in range(1, len(entries)):
        previous_entry = entries[index - 1]
        current_entry = entries[index]
        segment_dt_ms = int(current_entry.get("timestamp_ms", timestamp_ms)) - int(previous_entry.get("timestamp_ms", timestamp_ms))
        if segment_dt_ms <= 0:
            continue
        previous_x, previous_y = previous_entry.get("signal_position", signal_position)
        current_x, current_y = current_entry.get("signal_position", signal_position)
        seconds = float(segment_dt_ms) / 1000.0
        velocity_sum_x += (float(current_x) - float(previous_x)) / seconds
        velocity_sum_y += (float(current_y) - float(previous_y)) / seconds
        velocity_sample_count += 1
    if velocity_sample_count <= 0:
        return 0.0, 0.0
    return velocity_sum_x / float(velocity_sample_count), velocity_sum_y / float(velocity_sample_count)


def _resolve_recent_combined_velocity_components(history: list[dict], timestamp_ms: int, signal_position: tuple[float, float]) -> tuple[float, float]:
    return _resolve_recent_velocity_components(history, timestamp_ms, signal_position)


def _resolve_recent_velocity_magnitude(history: list[dict], timestamp_ms: int, signal_position: tuple[float, float]) -> float:
    average_velocity_x, average_velocity_y = _resolve_recent_velocity_components(history, timestamp_ms, signal_position)
    return math.hypot(average_velocity_x, average_velocity_y)


def _resolve_recent_combined_velocity_magnitude(history: list[dict], timestamp_ms: int, signal_position: tuple[float, float]) -> float:
    return _resolve_recent_velocity_magnitude(history, timestamp_ms, signal_position)


def _body_lateral_unit_vector(left_shoulder: dict, right_shoulder: dict) -> tuple[float, float]:
    axis_x = float(left_shoulder.get("x", 0.0)) - float(right_shoulder.get("x", 0.0))
    axis_y = float(left_shoulder.get("y", 0.0)) - float(right_shoulder.get("y", 0.0))
    axis_length = math.hypot(axis_x, axis_y)
    if axis_length <= 1e-8:
        return 1.0, 0.0
    return axis_x / axis_length, axis_y / axis_length


def _coarse_direction_buckets(signed_vx: float, signed_vy: float, min_speed: float = 1e-6) -> dict[str, float]:
    speed = math.hypot(signed_vx, signed_vy)
    buckets = {
        "none": 0.0,
        "up": 0.0,
        "down": 0.0,
        "left": 0.0,
        "right": 0.0,
    }
    if speed <= min_speed:
        buckets["none"] = 1.0
        return buckets
    if abs(signed_vx) >= abs(signed_vy):
        buckets["right" if signed_vx >= 0.0 else "left"] = 1.0
    else:
        buckets["up" if signed_vy >= 0.0 else "down"] = 1.0
    return buckets


def _radial_velocity_over_shoulder_width(
    shoulder: dict,
    elbow: dict,
    elbow_velocity_x: float,
    elbow_velocity_y: float,
    shoulder_width: float,
) -> float:
    radial_x = float(elbow.get("x", 0.0)) - float(shoulder.get("x", 0.0))
    radial_y = float(elbow.get("y", 0.0)) - float(shoulder.get("y", 0.0))
    radial_length = math.hypot(radial_x, radial_y)
    if radial_length <= 1e-8:
        return 0.0
    radial_unit_x = radial_x / radial_length
    radial_unit_y = radial_y / radial_length
    radial_velocity = (elbow_velocity_x * radial_unit_x) + (elbow_velocity_y * radial_unit_y)
    return radial_velocity / max(float(shoulder_width), 1e-6)


def extract_side_features(
    landmarks_by_id: dict,
    metrics: dict,
    side: str,
    timestamp_ms: int,
    signal_history_by_side: dict[str, dict[str, list[dict]]],
    min_visibility: float = 0.5,
    feature_set: str = FEATURE_SET_BASELINE_V1,
    feature_names: list[str] | None = None,
):
    resolved_feature_set = normalize_feature_set(feature_set)
    resolved_feature_names = list(feature_names or feature_names_per_side(resolved_feature_set))
    shoulder = _landmark(landmarks_by_id, f"{side}_shoulder")
    elbow = _landmark(landmarks_by_id, f"{side}_elbow")
    wrist = _landmark(landmarks_by_id, f"{side}_wrist")
    opposite_side = "right" if side == "left" else "left"
    opposite_shoulder = _landmark(landmarks_by_id, f"{opposite_side}_shoulder")
    if not shoulder or not elbow or not wrist or not opposite_shoulder:
        return None
    if min(float(shoulder.get("v", 0.0)), float(elbow.get("v", 0.0)), float(wrist.get("v", 0.0)), float(opposite_shoulder.get("v", 0.0))) < min_visibility:
        return None
    measurements = metrics.get("measurements", {}) if isinstance(metrics.get("measurements", {}), dict) else {}
    shoulder_width = max(float(measurements.get("shoulder_width", 0.0)), 0.000001)

    side_histories = signal_history_by_side.setdefault(side, {"combined": [], "elbow": [], "wrist": []})
    combined_signal_position = _resolve_combined_elbow_wrist_signal_position(elbow, wrist)
    elbow_signal_position = _resolve_signal_position(elbow)
    wrist_signal_position = _resolve_signal_position(wrist)

    average_velocity_x, average_velocity_y = _resolve_recent_combined_velocity_components(
        side_histories.setdefault("combined", []),
        timestamp_ms,
        combined_signal_position,
    )
    elbow_velocity_x, elbow_velocity_y = _resolve_recent_velocity_components(
        side_histories.setdefault("elbow", []),
        timestamp_ms,
        elbow_signal_position,
    )
    wrist_velocity_x, wrist_velocity_y = _resolve_recent_velocity_components(
        side_histories.setdefault("wrist", []),
        timestamp_ms,
        wrist_signal_position,
    )

    camera_signed_vx = average_velocity_x
    camera_signed_vy = -average_velocity_y
    camera_wrist_signed_vx = wrist_velocity_x
    camera_wrist_signed_vy = -wrist_velocity_y
    lateral_axis_x, lateral_axis_y = _body_lateral_unit_vector(
        _landmark(landmarks_by_id, "left_shoulder"),
        _landmark(landmarks_by_id, "right_shoulder"),
    )
    body_signed_vx = (average_velocity_x * lateral_axis_x) + (average_velocity_y * lateral_axis_y)
    body_signed_vy = camera_signed_vy
    body_wrist_signed_vx = (wrist_velocity_x * lateral_axis_x) + (wrist_velocity_y * lateral_axis_y)
    body_wrist_signed_vy = camera_wrist_signed_vy
    camera_direction = _coarse_direction_buckets(camera_signed_vx, camera_signed_vy)
    body_direction = _coarse_direction_buckets(body_signed_vx, body_signed_vy)
    camera_wrist_direction = _coarse_direction_buckets(camera_wrist_signed_vx, camera_wrist_signed_vy)
    body_wrist_direction = _coarse_direction_buckets(body_wrist_signed_vx, body_wrist_signed_vy)
    combined_velocity_magnitude = math.hypot(average_velocity_x, average_velocity_y)
    elbow_shoulder_xy_distance_over_shoulder_width = _distance_2d(elbow, shoulder) / shoulder_width
    elbow_x_from_shoulder_over_shoulder_width = (float(elbow.get("x", 0.0)) - float(shoulder.get("x", 0.0))) / shoulder_width
    elbow_y_from_shoulder_over_shoulder_width = (float(elbow.get("y", 0.0)) - float(shoulder.get("y", 0.0))) / shoulder_width
    elbow_shoulder_radial_velocity_over_shoulder_width = _radial_velocity_over_shoulder_width(
        shoulder,
        elbow,
        elbow_velocity_x,
        elbow_velocity_y,
        shoulder_width,
    )
    feature_values = {
        "shoulder_x": float(shoulder.get("x", 0.0)),
        "shoulder_y": float(shoulder.get("y", 0.0)),
        "elbow_x": float(elbow.get("x", 0.0)),
        "elbow_y": float(elbow.get("y", 0.0)),
        "wrist_x": float(wrist.get("x", 0.0)),
        "wrist_y": float(wrist.get("y", 0.0)),
        "combined_elbow_wrist_velocity_xy_magnitude": combined_velocity_magnitude,
        "elbow_shoulder_xy_distance_over_shoulder_width": elbow_shoulder_xy_distance_over_shoulder_width,
        "elbow_x_from_shoulder_over_shoulder_width": elbow_x_from_shoulder_over_shoulder_width,
        "elbow_y_from_shoulder_over_shoulder_width": elbow_y_from_shoulder_over_shoulder_width,
        "elbow_shoulder_radial_velocity_over_shoulder_width": elbow_shoulder_radial_velocity_over_shoulder_width,
        "camera_signed_vx": camera_signed_vx,
        "camera_signed_vy": camera_signed_vy,
        "camera_direction_none": camera_direction["none"],
        "camera_direction_up": camera_direction["up"],
        "camera_direction_down": camera_direction["down"],
        "camera_direction_left": camera_direction["left"],
        "camera_direction_right": camera_direction["right"],
        "body_signed_vx": body_signed_vx,
        "body_signed_vy": body_signed_vy,
        "body_direction_none": body_direction["none"],
        "body_direction_up": body_direction["up"],
        "body_direction_down": body_direction["down"],
        "body_direction_left": body_direction["left"],
        "body_direction_right": body_direction["right"],
        "camera_wrist_signed_vx": camera_wrist_signed_vx,
        "camera_wrist_signed_vy": camera_wrist_signed_vy,
        "camera_wrist_direction_none": camera_wrist_direction["none"],
        "camera_wrist_direction_up": camera_wrist_direction["up"],
        "camera_wrist_direction_down": camera_wrist_direction["down"],
        "camera_wrist_direction_left": camera_wrist_direction["left"],
        "camera_wrist_direction_right": camera_wrist_direction["right"],
        "body_wrist_signed_vx": body_wrist_signed_vx,
        "body_wrist_signed_vy": body_wrist_signed_vy,
        "body_wrist_direction_none": body_wrist_direction["none"],
        "body_wrist_direction_up": body_wrist_direction["up"],
        "body_wrist_direction_down": body_wrist_direction["down"],
        "body_wrist_direction_left": body_wrist_direction["left"],
        "body_wrist_direction_right": body_wrist_direction["right"],
    }
    return {
        "feature_set": resolved_feature_set,
        "feature_names": resolved_feature_names,
        "features": [float(feature_values[name]) for name in resolved_feature_names],
        "signal_positions": {
            "combined": combined_signal_position,
            "elbow": elbow_signal_position,
            "wrist": wrist_signal_position,
        },
    }


def build_feature_snapshots(capture_report: dict, feature_set: str = FEATURE_SET_BASELINE_V1) -> list[dict]:
    resolved_feature_set = normalize_feature_set(feature_set)
    resolved_feature_names = feature_names_per_side(resolved_feature_set)
    resolved_frame_feature_names = frame_feature_names(resolved_feature_set)
    snapshots = []
    signal_history_by_side: dict[str, dict[str, list[dict]]] = {
        "left": {"combined": [], "elbow": [], "wrist": []},
        "right": {"combined": [], "elbow": [], "wrist": []},
    }
    for snapshot in pose_snapshots(capture_report):
        pose_snapshot = snapshot["pose_snapshot"]
        landmarks_by_id = pose_snapshot.get("landmarks_by_id", {}) if isinstance(pose_snapshot.get("landmarks_by_id", {}), dict) else {}
        metrics = pose_snapshot.get("metrics", {}) if isinstance(pose_snapshot.get("metrics", {}), dict) else {}
        timestamp_ms = int(snapshot["timestamp_ms"])
        left = extract_side_features(landmarks_by_id, metrics, "left", timestamp_ms, signal_history_by_side, feature_set=resolved_feature_set, feature_names=resolved_feature_names)
        right = extract_side_features(landmarks_by_id, metrics, "right", timestamp_ms, signal_history_by_side, feature_set=resolved_feature_set, feature_names=resolved_feature_names)
        if left is not None:
            for signal_name, signal_position in left["signal_positions"].items():
                signal_history_by_side["left"].setdefault(signal_name, []).append({"timestamp_ms": timestamp_ms, "signal_position": signal_position})
        if right is not None:
            for signal_name, signal_position in right["signal_positions"].items():
                signal_history_by_side["right"].setdefault(signal_name, []).append({"timestamp_ms": timestamp_ms, "signal_position": signal_position})
        if left is None or right is None:
            continue
        snapshots.append(
            {
                "timestamp_ms": timestamp_ms,
                "feature_set": resolved_feature_set,
                "feature_names": list(resolved_frame_feature_names),
                "side_feature_names": list(resolved_feature_names),
                "features": [float(v) for v in (left["features"] + right["features"])],
            }
        )
    return snapshots


def resample_series(series: list[list[float]], target_count: int) -> list[list[float]]:
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


def overlapping_gesture_names(gesture_windows_by_name: dict[str, list[dict]], start_ms: int, end_ms: int) -> list[str]:
    names = []
    for name, windows in gesture_windows_by_name.items():
        for window in windows:
            window_start = int(window.get("start_ms", 0) or 0)
            window_end = int(window.get("end_ms", 0) or 0)
            if max(start_ms, window_start) < min(end_ms, window_end):
                names.append(name)
                break
    return sorted(set(names))


def complement_intervals(total_start_ms: int, total_end_ms: int, excluded: Iterable[tuple[int, int]]) -> list[tuple[int, int]]:
    clamped = []
    for start_ms, end_ms in excluded:
        start_ms = max(total_start_ms, int(start_ms))
        end_ms = min(total_end_ms, int(end_ms))
        if end_ms > start_ms:
            clamped.append((start_ms, end_ms))
    clamped.sort()
    merged: list[tuple[int, int]] = []
    for start_ms, end_ms in clamped:
        if not merged or start_ms > merged[-1][1]:
            merged.append((start_ms, end_ms))
        else:
            merged[-1] = (merged[-1][0], max(merged[-1][1], end_ms))
    result: list[tuple[int, int]] = []
    cursor = total_start_ms
    for start_ms, end_ms in merged:
        if start_ms > cursor:
            result.append((cursor, start_ms))
        cursor = max(cursor, end_ms)
    if cursor < total_end_ms:
        result.append((cursor, total_end_ms))
    return result


def iter_fixed_windows(intervals: Iterable[tuple[int, int]], window_ms: int, stride_ms: int) -> list[tuple[int, int]]:
    result: list[tuple[int, int]] = []
    for start_ms, end_ms in intervals:
        cursor = int(start_ms)
        while cursor + window_ms <= int(end_ms):
            result.append((cursor, cursor + window_ms))
            cursor += stride_ms
    return result


def evenly_pick(items: list[dict], max_count: int) -> list[dict]:
    if len(items) <= max_count:
        return list(items)
    result = []
    for idx in range(max_count):
        source_index = int(round(idx * (len(items) - 1) / float(max_count - 1))) if max_count > 1 else len(items) - 1
        result.append(items[source_index])
    deduped = []
    seen = set()
    for item in result:
        key = item.get("sample_id") or json.dumps(item, sort_keys=True)
        if key in seen:
            continue
        seen.add(key)
        deduped.append(item)
    if len(deduped) < max_count:
        for item in items:
            key = item.get("sample_id") or json.dumps(item, sort_keys=True)
            if key in seen:
                continue
            seen.add(key)
            deduped.append(item)
            if len(deduped) >= max_count:
                break
    return deduped[:max_count]


def extract_window_sample(
    feature_snapshots: list[dict],
    capture_report: dict,
    label: str,
    sample_id: str,
    fixture: dict,
    fixture_yaml: dict,
    start_ms: int,
    end_ms: int,
    *,
    frame_count: int,
    sample_kind: str,
    source_window_index: int,
    source_gesture_name: str,
    feature_set: str = FEATURE_SET_BASELINE_V1,
    frame_feature_names_override: list[str] | None = None,
    side_feature_names_override: list[str] | None = None,
    extra_metadata: dict | None = None,
) -> dict | None:
    capture_start_ms, capture_end_ms, alignment = capture_window_range_ms(capture_report, start_ms, end_ms)
    matched = [snapshot for snapshot in feature_snapshots if capture_start_ms <= int(snapshot["timestamp_ms"]) <= capture_end_ms]
    if not matched:
        return None
    series = [snapshot["features"] for snapshot in matched]
    frames = resample_series(series, frame_count)
    gesture_windows = _gesture_windows_by_name(fixture_yaml)
    threshold_prediction = threshold_window_prediction(capture_report, capture_start_ms, capture_end_ms)
    matched_pose_start_ms = int(matched[0]["timestamp_ms"])
    matched_pose_end_ms = int(matched[-1]["timestamp_ms"])
    resolved_feature_set = normalize_feature_set(feature_set)
    resolved_frame_feature_names = list(frame_feature_names_override or frame_feature_names(resolved_feature_set))
    resolved_side_feature_names = list(side_feature_names_override or feature_names_per_side(resolved_feature_set))
    sample = {
        "sample_id": sample_id,
        "label": label,
        "sample_kind": sample_kind,
        "source_fixture_id": fixture["id"],
        "fixture_path": fixture["fixture_path"],
        "source_path": fixture["source_path"],
        "source_gesture_name": source_gesture_name,
        "source_window_index": source_window_index,
        "window_start_ms": start_ms,
        "window_end_ms": end_ms,
        "capture_window_start_ms": capture_start_ms,
        "capture_window_end_ms": capture_end_ms,
        "pose_samples_in_window": len(matched),
        "pose_sample_timestamps_ms": [int(snapshot["timestamp_ms"]) for snapshot in matched],
        "matched_pose_start_ms": matched_pose_start_ms,
        "matched_pose_end_ms": matched_pose_end_ms,
        "start_alignment_error_ms": matched_pose_start_ms - capture_start_ms,
        "end_alignment_error_ms": capture_end_ms - matched_pose_end_ms,
        "matched_pose_duration_ms": max(0, matched_pose_end_ms - matched_pose_start_ms),
        "frame_count": frame_count,
        "frame_feature_count": len(resolved_frame_feature_names),
        "feature_set": resolved_feature_set,
        "side_feature_names": resolved_side_feature_names,
        "feature_names": resolved_frame_feature_names,
        "frames": frames,
        "metadata_gestures": overlapping_gesture_names(gesture_windows, start_ms, end_ms),
        "threshold_baseline": threshold_prediction,
        **alignment,
    }
    if extra_metadata:
        sample.update(extra_metadata)
    return sample


def threshold_window_prediction(capture_report: dict, capture_start_ms: int, capture_end_ms: int) -> dict:
    matching_events = [
        event
        for event in attack_events(capture_report)
        if capture_start_ms <= int(event["timestamp_ms"]) <= capture_end_ms
    ]
    if not matching_events:
        return {
            "predicted_label": "no_punch",
            "predicted_event": "",
            "event_count": 0,
            "winning_event_timestamp_ms": None,
            "winning_event_power": 0.0,
            "events": [],
        }
    matching_events.sort(key=lambda event: (-float(event.get("power", 0.0)), int(event.get("timestamp_ms", 0)), str(event.get("name", ""))))
    winner = matching_events[0]
    return {
        "predicted_label": winner["class_name"],
        "predicted_event": winner["name"],
        "event_count": len(matching_events),
        "winning_event_timestamp_ms": int(winner.get("timestamp_ms", 0)),
        "winning_event_power": float(winner.get("power", 0.0)),
        "events": matching_events,
    }


def assign_deterministic_splits(samples: list[dict]) -> None:
    grouped: dict[str, list[dict]] = {label: [] for label in PUNCH_CLASS_ORDER}
    for sample in samples:
        grouped.setdefault(sample["label"], []).append(sample)
    for label, group in grouped.items():
        group.sort(key=lambda item: (str(item.get("source_fixture_id", "")), int(item.get("window_start_ms", 0)), str(item.get("sample_id", ""))))
        count = len(group)
        if count <= 1:
            for sample in group:
                sample["split"] = "train"
            continue
        test_indexes = {idx for idx in range(count) if idx % 4 == 3}
        if not test_indexes:
            test_indexes = {count - 1}
        if len(test_indexes) >= count:
            test_indexes = {count - 1}
        for idx, sample in enumerate(group):
            sample["split"] = "test" if idx in test_indexes else "train"
            sample["split_group"] = f"{label}::{sample.get('source_fixture_id', '')}"
            sample["split_strategy"] = "label_cycled_deterministic_v1"


def assign_chronological_holdout_splits(samples: list[dict], holdout_ratio: float = 0.25) -> None:
    positive_groups: dict[str, list[dict]] = {}
    negative_groups: dict[str, list[dict]] = {}
    for sample in samples:
        if sample["label"] == "no_punch":
            group_key = str(sample.get("source_fixture_id", "unknown_fixture"))
            negative_groups.setdefault(group_key, []).append(sample)
        else:
            group_key = f"{sample['label']}::{sample.get('source_fixture_id', 'unknown_fixture')}"
            positive_groups.setdefault(group_key, []).append(sample)

    grouped = {**positive_groups, **negative_groups}
    for group_key, group in grouped.items():
        group.sort(key=lambda item: (int(item.get("window_start_ms", 0)), int(item.get("window_end_ms", 0)), str(item.get("sample_id", ""))))
        count = len(group)
        test_count = max(1, int(math.ceil(count * holdout_ratio))) if count > 1 else 0
        if test_count >= count and count > 1:
            test_count = count - 1
        split_index = count - test_count
        for idx, sample in enumerate(group):
            sample["split"] = "test" if idx >= split_index and test_count > 0 else "train"
            sample["split_group"] = group_key
            sample["split_strategy"] = "chronological_holdout_v1"


def confusion_from_predictions(records: list[dict], labels: list[str]) -> dict:
    matrix = {actual: {predicted: 0 for predicted in labels} for actual in labels}
    for record in records:
        actual = str(record["actual"])
        predicted = str(record["predicted"])
        matrix.setdefault(actual, {label: 0 for label in labels})
        matrix[actual].setdefault(predicted, 0)
        matrix[actual][predicted] += 1
    return matrix


def classification_metrics(records: list[dict], labels: list[str]) -> dict:
    confusion = confusion_from_predictions(records, labels)
    total = len(records)
    correct = sum(1 for record in records if record["actual"] == record["predicted"])
    per_class = {}
    macro_precision = 0.0
    macro_recall = 0.0
    macro_f1 = 0.0
    for label in labels:
        tp = confusion.get(label, {}).get(label, 0)
        fp = sum(confusion.get(other, {}).get(label, 0) for other in labels if other != label)
        fn = sum(confusion.get(label, {}).get(other, 0) for other in labels if other != label)
        precision = tp / float(tp + fp) if (tp + fp) > 0 else 0.0
        recall = tp / float(tp + fn) if (tp + fn) > 0 else 0.0
        f1 = 0.0 if (precision + recall) <= 0 else (2.0 * precision * recall) / (precision + recall)
        support = sum(confusion.get(label, {}).values())
        per_class[label] = {
            "precision": precision,
            "recall": recall,
            "f1": f1,
            "support": support,
        }
        macro_precision += precision
        macro_recall += recall
        macro_f1 += f1
    label_count = len(labels) if labels else 1
    predicted_counts = Counter(record["predicted"] for record in records)
    actual_counts = Counter(record["actual"] for record in records)
    return {
        "sample_count": total,
        "accuracy": correct / float(total) if total > 0 else 0.0,
        "macro_precision": macro_precision / float(label_count),
        "macro_recall": macro_recall / float(label_count),
        "macro_f1": macro_f1 / float(label_count),
        "actual_counts": {label: actual_counts.get(label, 0) for label in labels},
        "predicted_counts": {label: predicted_counts.get(label, 0) for label in labels},
        "per_class": per_class,
        "confusion": confusion,
    }


def flatten_frames(frames: list[list[float]]) -> list[float]:
    flat = []
    for frame in frames:
        flat.extend(float(value) for value in frame)
    return flat


def compute_standardization(train_vectors: list[list[float]]) -> tuple[list[float], list[float]]:
    dimension = len(train_vectors[0]) if train_vectors else 0
    means = [0.0 for _ in range(dimension)]
    stds = [0.0 for _ in range(dimension)]
    if not train_vectors:
        return means, stds
    for vector in train_vectors:
        for idx, value in enumerate(vector):
            means[idx] += value
    sample_count = float(len(train_vectors))
    means = [value / sample_count for value in means]
    for vector in train_vectors:
        for idx, value in enumerate(vector):
            delta = value - means[idx]
            stds[idx] += delta * delta
    stds = [math.sqrt(value / sample_count) if value > 0.0 else 1.0 for value in stds]
    stds = [std if std > 1e-8 else 1.0 for std in stds]
    return means, stds


def apply_standardization(vectors: list[list[float]], means: list[float], stds: list[float]) -> list[list[float]]:
    return [[(value - means[idx]) / stds[idx] for idx, value in enumerate(vector)] for vector in vectors]


def format_confusion_markdown(confusion: dict, labels: list[str]) -> list[str]:
    lines = ["| actual \\ predicted | " + " | ".join(labels) + " |", "| --- | " + " | ".join(["---"] * len(labels)) + " |"]
    for actual in labels:
        row = [actual]
        for predicted in labels:
            row.append(str(int(confusion.get(actual, {}).get(predicted, 0))))
        lines.append("| " + " | ".join(row) + " |")
    return lines
