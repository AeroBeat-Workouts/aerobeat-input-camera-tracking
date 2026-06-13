#!/usr/bin/env python3
import argparse
import json
import os
import shutil
import subprocess
import sys
from collections import defaultdict
from datetime import datetime
from pathlib import Path

ATTACK_EVENTS = {
    "punch_left",
    "punch_right",
    "hook_left",
    "hook_right",
    "uppercut_left",
    "uppercut_right",
}
CLASS_ORDER = [
    "straight_left",
    "straight_right",
    "hook_left",
    "hook_right",
    "uppercut_left",
    "uppercut_right",
]


def load_json(path: Path):
    with path.open("r", encoding="utf-8") as handle:
        return json.load(handle)


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


def _payload_class_name(event: dict) -> str:
    payload = event.get("payload", {}) if isinstance(event.get("payload", {}), dict) else {}
    prototype_match = payload.get("prototype_match", {}) if isinstance(payload.get("prototype_match", {}), dict) else {}
    return str(prototype_match.get("class_name", "")).strip()


def analyze_fixture(fixture: dict, report: dict) -> dict:
    fixture_capture = report.get("fixture_capture", {}) if isinstance(report.get("fixture_capture", {}), dict) else {}
    event_timeline = fixture_capture.get("event_timeline", []) if isinstance(fixture_capture.get("event_timeline", []), list) else []
    state_timeline = fixture_capture.get("state_timeline", []) if isinstance(fixture_capture.get("state_timeline", []), list) else []
    latest_state = fixture_capture.get("latest_state", {}) if isinstance(fixture_capture.get("latest_state", {}), dict) else {}
    matcher_latest = {}
    if isinstance(latest_state.get("gesture_debug", {}), dict):
        matcher_latest = latest_state.get("gesture_debug", {}).get("prototype_matcher", {}) or {}
        if not isinstance(matcher_latest, dict):
            matcher_latest = {}

    attack_events = []
    for entry in event_timeline:
        if not isinstance(entry, dict):
            continue
        name = str(entry.get("name", ""))
        if name not in ATTACK_EVENTS:
            continue
        payload = entry.get("payload", {}) if isinstance(entry.get("payload", {}), dict) else {}
        attack_events.append({
            "name": name,
            "timestamp_ms": int(entry.get("timestamp_ms", 0)),
            "count": int(entry.get("count", 0)),
            "power": float(payload.get("power", 0.0)),
            "backend": str(payload.get("backend", "threshold_gates") or "threshold_gates"),
            "prototype_match": payload.get("prototype_match", {}) if isinstance(payload.get("prototype_match", {}), dict) else {},
        })

    max_best_score = {class_name: 0.0 for class_name in CLASS_ORDER}
    max_class_score = {class_name: 0.0 for class_name in CLASS_ORDER}
    best_class_counts = {class_name: 0 for class_name in CLASS_ORDER}
    reasons = defaultdict(int)
    for entry in state_timeline:
        if not isinstance(entry, dict):
            continue
        matcher = entry.get("prototype_matcher", {}) if isinstance(entry.get("prototype_matcher", {}), dict) else {}
        if not matcher:
            continue
        best_class = str(matcher.get("best_class", "")).strip()
        best_score = float(matcher.get("best_score", 0.0))
        if best_class in max_best_score:
            max_best_score[best_class] = max(max_best_score[best_class], best_score)
            best_class_counts[best_class] += 1
        class_scores = matcher.get("class_scores", {}) if isinstance(matcher.get("class_scores", {}), dict) else {}
        for class_name, score in class_scores.items():
            class_name = str(class_name)
            if class_name in max_class_score:
                max_class_score[class_name] = max(max_class_score[class_name], float(score))
        reasons[str(matcher.get("reason", "idle"))] += 1

    expected_event = fixture.get("expected_event")
    expected_class = fixture.get("expected_class")
    expected_events = [event for event in attack_events if event["name"] == expected_event] if expected_event else []
    wrong_events = [event for event in attack_events if expected_event is None or event["name"] != expected_event]
    no_attack_expected = bool(fixture.get("expect_no_attack", False))

    findings = []
    if expected_event:
        if expected_events:
            findings.append(f"emitted expected {expected_event} {len(expected_events)} time(s)")
        else:
            findings.append(f"did not emit expected {expected_event}")
        if wrong_events:
            findings.append("also emitted other attack events: " + ", ".join(event["name"] for event in wrong_events))
    elif no_attack_expected:
        if attack_events:
            findings.append("negative control still emitted attack events: " + ", ".join(event["name"] for event in attack_events))
        else:
            findings.append("negative control emitted no attack events")

    if expected_class:
        findings.append(
            "peak expected-class score %.3f" % max(
                max_best_score.get(expected_class, 0.0),
                max_class_score.get(expected_class, 0.0),
            )
        )
    findings.append("latest matcher reason %s" % str(matcher_latest.get("reason", "unknown")))

    return {
        "fixture_id": fixture["id"],
        "label": fixture.get("label", fixture["id"]),
        "fixture_path": fixture["fixture_path"],
        "source_path": fixture["source_path"],
        "expected_event": expected_event,
        "expected_class": expected_class,
        "expect_no_attack": no_attack_expected,
        "capture_elapsed_ms": int(report.get("elapsed_ms", 0)),
        "event_count": len(attack_events),
        "expected_event_count": len(expected_events),
        "wrong_event_count": len(wrong_events),
        "attack_events": attack_events,
        "max_best_score_by_class": max_best_score,
        "max_class_score_by_class": max_class_score,
        "best_class_snapshot_counts": best_class_counts,
        "matcher_reason_counts": dict(sorted(reasons.items())),
        "latest_matcher_debug": matcher_latest,
        "status": {
            "expected_event_emitted": bool(expected_events) if expected_event else len(attack_events) == 0,
            "only_expected_attack_events": len(wrong_events) == 0,
            "negative_control_clean": (len(attack_events) == 0) if no_attack_expected else None,
        },
        "findings": findings,
    }


def build_aggregate(manifest: dict, fixture_results: list) -> dict:
    by_expected_class = {}
    for fixture in manifest.get("fixtures", []):
        expected_class = fixture.get("expected_class")
        if expected_class and expected_class not in by_expected_class:
            by_expected_class[expected_class] = {
                "fixture_count": 0,
                "fixtures_with_expected_event": 0,
                "fixtures_with_wrong_events": 0,
                "max_expected_class_score": 0.0,
            }

    negative_controls = {
        "fixture_count": 0,
        "clean_fixture_count": 0,
        "fixtures_with_attack_events": 0,
    }

    for result in fixture_results:
        expected_class = result.get("expected_class")
        if expected_class:
            bucket = by_expected_class[expected_class]
            bucket["fixture_count"] += 1
            if result.get("status", {}).get("expected_event_emitted"):
                bucket["fixtures_with_expected_event"] += 1
            if result.get("wrong_event_count", 0) > 0:
                bucket["fixtures_with_wrong_events"] += 1
            peak = max(
                float(result.get("max_best_score_by_class", {}).get(expected_class, 0.0)),
                float(result.get("max_class_score_by_class", {}).get(expected_class, 0.0)),
            )
            bucket["max_expected_class_score"] = max(bucket["max_expected_class_score"], peak)
        if result.get("expect_no_attack"):
            negative_controls["fixture_count"] += 1
            if result.get("event_count", 0) == 0:
                negative_controls["clean_fixture_count"] += 1
            else:
                negative_controls["fixtures_with_attack_events"] += 1

    return {
        "fixture_count": len(fixture_results),
        "expected_class_summary": by_expected_class,
        "negative_controls": negative_controls,
    }


def render_markdown(result: dict) -> str:
    lines = [
        "# Prototype Matcher Fixture Benchmark",
        "",
        f"- Benchmark ID: `{result['benchmark_id']}`",
        f"- Library ID: `{result['library_id']}`",
        f"- Profile: `{result['profile']}`",
        f"- Generated At: `{result['generated_at']}`",
        f"- Runner: `{result['runner']}`",
        "",
        "## Aggregate",
        "",
        f"- Fixture count: **{result['aggregate']['fixture_count']}**",
        f"- Negative controls clean: **{result['aggregate']['negative_controls']['clean_fixture_count']} / {result['aggregate']['negative_controls']['fixture_count']}**",
        "",
        "## Per Fixture",
        "",
    ]
    for fixture in result["fixtures"]:
        lines.append(f"### {fixture['label']}")
        lines.append("")
        lines.append(f"- Fixture: `{fixture['fixture_path']}`")
        lines.append(f"- Source: `{fixture['source_path']}`")
        lines.append(f"- Expected event: `{fixture['expected_event']}`")
        lines.append(f"- Expected class: `{fixture['expected_class']}`")
        lines.append(f"- Attack events emitted: **{fixture['event_count']}**")
        for finding in fixture.get("findings", []):
            lines.append(f"- {finding}")
        if fixture.get("attack_events"):
            lines.append("")
            lines.append("Emitted attack events:")
            for event in fixture["attack_events"]:
                proto = event.get("prototype_match", {})
                lines.append(
                    "- `%s` at `%dms` score=`%.3f` class=`%s` backend=`%s`" % (
                        event["name"],
                        int(event.get("timestamp_ms", 0)),
                        float(proto.get("score", event.get("power", 0.0))),
                        str(proto.get("class_name", "")),
                        str(event.get("backend", "")),
                    )
                )
        lines.append("")
    return "\n".join(lines).rstrip() + "\n"


def main() -> int:
    parser = argparse.ArgumentParser(description="Run the boxing prototype-matcher benchmark against committed replay fixtures.")
    parser.add_argument("--manifest", required=True, help="Benchmark manifest JSON path relative to repo root or absolute path.")
    parser.add_argument("--output-dir", required=True, help="Directory for machine-readable benchmark output.")
    parser.add_argument("--godot", default="godot", help="Godot executable to use.")
    parser.add_argument("--capture-delay-ms", type=int, default=None, help="Override capture delay for every fixture.")
    args = parser.parse_args()

    repo_root = Path(__file__).resolve().parent.parent
    manifest_path = Path(args.manifest)
    if not manifest_path.is_absolute():
        manifest_path = repo_root / manifest_path
    output_dir = Path(args.output_dir)
    if not output_dir.is_absolute():
        output_dir = repo_root / output_dir
    output_dir.mkdir(parents=True, exist_ok=True)

    manifest = load_json(manifest_path)
    capture_delay_ms = int(args.capture_delay_ms or manifest.get("capture_delay_ms", 7000))
    fixture_results = []
    for fixture in manifest.get("fixtures", []):
        report = run_capture(repo_root, fixture, output_dir, args.godot, capture_delay_ms)
        fixture_results.append(analyze_fixture(fixture, report))

    result = {
        "benchmark_id": manifest.get("benchmark_id", "prototype_matcher_fixture_benchmark"),
        "library_id": manifest.get("library_id", "boxing_side_aware_v1"),
        "profile": manifest.get("profile", "boxing"),
        "generated_at": datetime.now().astimezone().isoformat(timespec="seconds"),
        "runner": str(Path(__file__).resolve()),
        "manifest_path": str(manifest_path),
        "capture_delay_ms": capture_delay_ms,
        "fixtures": fixture_results,
        "aggregate": build_aggregate(manifest, fixture_results),
    }

    json_path = output_dir / "benchmark-results.json"
    md_path = output_dir / "benchmark-results.md"
    with json_path.open("w", encoding="utf-8") as handle:
        json.dump(result, handle, indent=2)
        handle.write("\n")
    md_path.write_text(render_markdown(result), encoding="utf-8")
    print(json_path)
    print(md_path)
    return 0


if __name__ == "__main__":
    sys.exit(main())
