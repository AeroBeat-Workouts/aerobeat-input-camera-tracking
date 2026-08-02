# Camera Tracking Body-Grid Anchor Emission

**Date:** 2026-08-02
**Status:** In Progress
**Last Updated:** 2026-08-02 19:05 EDT
**Blocked Reason:** None
**Agent:** pico

---

## Goal

Emit first-class normalized body-grid nose, left-wrist, and right-wrist anchors from camera tracking through the input-core-compatible provider surface.

---

## Overview

Input-core now owns the stable body-grid contract. This repo should remain the concrete camera-tracking provider: it computes athlete-space normalized anchor payloads from calibrated bounds, emits one event per body part, and emits separate calibration lifecycle events without bundling them into pose payloads.

The implementation should keep preview/debug rendering concerns separate from the contract. Preview-space overlays can stay mirrored or presenter-oriented where they already are, but emitted body-grid `x/y` must be athlete-space top-left normalized coordinates so runner and input consumers can agree that cell `0` is the athlete's upper-left.

Debug config should follow the existing public YAML comment style from this repo: a short comment directly above each field, allowed options in comments where relevant, and an ownership tag such as `input debug only`.

---

## REFERENCES

| ID | Description | Path |
| --- | --- | --- |
| `REF-01` | Completed input-core contract plan | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-core/.plans/archive/2026-08-02-normalized-body-grid-pose-contract.md` |
| `REF-02` | Input-core implementation commit | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-core/src/interfaces/body_cell_input.gd`, `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-core/src/input_manager.gd` |
| `REF-03` | Camera provider outward signal/query surface | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/src/providers/camera_tracking_provider.gd`, `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/src/AeroCameraTracking.gd`, `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/src/input_provider.gd` |
| `REF-04` | Calibrated grid and pose detector internals | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/src/detectors/pose_detector_substrate.gd` |
| `REF-05` | Existing YAML documentation style | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/assets/flow.testbed_debug.yaml`, `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/assets/boxing.testbed_debug.yaml` |
| `REF-06` | Existing proving tests | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.testbed/tests/unit/test_camera_tracking_provider.gd`, `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.testbed/tests/unit/test_pose_detector_substrate.gd`, `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.testbed/tests/unit/test_aero_camera_tracking.gd` |

---

## Frozen Requirements

- Emit exactly one body-grid anchor signal per body part: `body_grid_nose_updated(anchor)`, `body_grid_left_wrist_updated(anchor)`, and `body_grid_right_wrist_updated(anchor)`.
- Emit calibration lifecycle separately: `body_grid_calibration_started(event)`, `body_grid_calibration_succeeded(event)`, `body_grid_calibration_failed(event)`, and `body_grid_calibration_canceled(event)`.
- Add matching queries for the latest nose, left-wrist, right-wrist, and calibration lifecycle state.
- Build anchor payloads with schema `aerobeat/body_grid_anchor`, version `1`, per-anchor `valid`, `calibration_id`, `timestamp_ms`, top-left row-major grid metadata, `raw_x/raw_y`, clamped `x/y`, `cell`, `row`, and `column`.
- Invalid anchors must retain the full schema and set `raw_x`, `raw_y`, `x`, `y`, `cell`, `row`, and `column` to `null`.
- Coordinates are athlete-space top-left normalized: `x = 0` left, `x = 1` right, `y = 0` top, `y = 1` bottom, and `cell = floor(y * rows) * columns + floor(x * columns)` clamped at the final row/column.
- Provider emission must happen on fresh calibrated landmark evaluation, even when a body part remains in the same cell.
- Emit invalid anchors on tracking timeout/loss, calibration start/cancel/fail, stop, and reset.
- `calibration_id` changes only after successful calibration and remains stable through normal tracking until the next successful calibration.
- Proving-scene debug options for body pose/grid, nose, left wrist, and right wrist should be exposed through the testbed debug YAMLs with the same comment style as existing fields.

---

## Tasks

### Task 1: Implement Camera-Tracking Body-Grid Emission

**Bead ID:** `oc-zex8`
**SubAgent:** `primary` (for `coder` workflow role)
**Role:** `coder`
**References:** `REF-01` through `REF-06`
**Prompt:** Claim bead `oc-zex8` on start. Implement camera-tracking provider emission for the input-core normalized body-grid contract. Keep `PoseDetectorSubstrate` responsible for calibrated athlete-space anchor/calibration state, and keep `CameraTrackingProvider`/wrapper surfaces responsible for outward signals and queries. Add tests for valid anchor payloads, invalid payloads on stop/loss/calibration start/cancel/fail, stable `calibration_id` semantics, per-frame same-cell emission, top-left cells `0/3/8/11`, wrapper proxying where applicable, and debug YAML options/comment style. Run relevant Godot import/unit validation. Commit and push on success; leave the bead open for QA/audit.

**Folders Created/Deleted/Modified:**
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/src/`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/assets/`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.testbed/tests/`

**Files Created/Deleted/Modified:**
- `src/detectors/pose_detector_substrate.gd`
- `src/providers/camera_tracking_provider.gd`
- `src/AeroCameraTracking.gd`
- `src/input_provider.gd`
- `assets/flow.testbed_debug.yaml`
- `assets/boxing.testbed_debug.yaml`
- `.testbed/tests/unit/test_camera_tracking_provider.gd`
- `.testbed/tests/unit/test_pose_detector_substrate.gd`
- `.testbed/tests/unit/test_aero_camera_tracking.gd`
- `.testbed/tests/unit/test_input_provider_adapter.gd`

**Status:** ✅ Complete

**Results:** Implemented normalized body-grid anchor emission and query surfaces for nose, left wrist, and right wrist. `PoseDetectorSubstrate` now owns calibrated athlete-space top-left anchor payload construction, while `CameraTrackingProvider`, `AeroCameraTracking`, and `input_provider.gd` own outward signals, lifecycle events, caches, and queries. Calibration lifecycle emits started/succeeded/failed/canceled separately from anchors; `calibration_id` is generated only on successful calibration and remains stable through normal tracking. Invalid schema-shaped anchors emit on tracking loss/timeout, calibration start/cancel/fail, stop, and reset. Proving-scene debug YAML exposes body-grid, nose, left-wrist, and right-wrist options with existing `input debug only` comment style.

Validation:
- `godot --headless --path .testbed --import` completed successfully.
- `godot --headless --path .testbed --script addons/aerobeat-vendor-godot-unit-test/gut_cmdln.gd -gtest=res://tests/unit/test_camera_tracking_provider.gd,res://tests/unit/test_pose_detector_substrate.gd,res://tests/unit/test_aero_camera_tracking.gd,res://tests/unit/test_input_provider_adapter.gd` passed: 162 tests, 1725 assertions.

Accepted gaps:
- Full repository GUT suite was not run; targeted suites covered the changed provider, substrate, facade, adapter, and debug YAML surfaces.

Commit:
- `1a22bde` Emit normalized body-grid anchors

---

### Task 2: QA Camera-Tracking Body-Grid Emission

**Bead ID:** `oc-zex8`
**SubAgent:** `primary` (for `qa` workflow role)
**Role:** `qa`
**References:** `REF-01` through `REF-06`
**Prompt:** Claim bead `oc-zex8` on start. Perform QA against the implementation commit and this plan. Verify emitted payload shape, calibration lifecycle separation, invalidation behavior, athlete-space top-left semantics, debug YAML comment style/options, and test coverage. Rerun relevant Godot import/unit validation. Do not close the bead; return pass/fail evidence and gaps.

**Folders Created/Deleted/Modified:**
- None expected.

**Files Created/Deleted/Modified:**
- None expected.

**Status:** ⏳ Pending

**Results:** Pending QA.

---

### Task 3: Audit Camera-Tracking Body-Grid Emission

**Bead ID:** `oc-zex8`
**SubAgent:** `primary` (for `auditor` workflow role)
**Role:** `auditor`
**References:** `REF-01` through `REF-06`
**Prompt:** Claim bead `oc-zex8` on start. Independently audit the implementation, QA evidence, plan, bead notes, and validation output. If the seam satisfies the frozen requirements, close the bead with a clear reason; otherwise leave it open and report exact gaps.

**Folders Created/Deleted/Modified:**
- None expected.

**Files Created/Deleted/Modified:**
- None expected.

**Status:** ⏳ Pending

**Results:** Pending audit.

---

## Final Results

**Status:** ⚠️ Partial

**What We Built:** Plan created; implementation pending.

**Reference Check:** Pending.

**Commits:**
- Pending.

**Lessons Learned:** Pending.

---

*Completed on Pending*
