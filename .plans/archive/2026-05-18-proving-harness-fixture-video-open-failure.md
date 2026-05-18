# AeroBeat Input MediaPipe Python Proving Harness Fixture Video Open Failure

**Date:** 2026-05-18  
**Status:** Draft  
**Agent:** Pico 🐱‍🏍

---

## Goal

Diagnose and fix the proving-harness failure where the MediaPipe Python sidecar dies when the Flow/Boxing test scenes are pointed at prerecorded fixture videos.

---

## Overview

The immediate blocker is no longer runtime bootstrap. The sidecar now starts, validates Python dependencies, loads the model, and reaches the frame-capture phase successfully. The failure happens later, when the Python process tries to open the prerecorded source path as its input stream and exits with `RuntimeError: Could not open camera <fixture-path>`.

That points to a narrower surface: either the harness-to-sidecar source handoff is wrong, or OpenCV/MediaPipe’s file-source path cannot actually open the provided fixture format on this host. The current log strongly suggests the sidecar is intentionally receiving the fixture path as `camera_id`, and `FrameCapture` in `python_mediapipe/main.py` is failing at `cv2.VideoCapture(camera_id).isOpened()` before its file-source branch can continue. So the next pass should separate “bad path / bad handoff” from “valid path, but unsupported file/container/codec in OpenCV on this machine,” then implement the smallest fix.

---

## REFERENCES

| ID | Description | Path |
| --- | --- | --- |
| `REF-01` | Python sidecar frame capture logic | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-mediapipe-python/python_mediapipe/main.py` |
| `REF-02` | Shared proving harness source override path | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-mediapipe-python/.testbed/scripts/proving_harness.gd` |
| `REF-03` | Reproduced runtime log from Derrick showing sidecar dies on fixture path | `RuntimeError: Could not open camera ...flow_swing_left_3_right_3_to_left_6_right_6_x4.webm` |

---

## Tasks

### Task 1: Diagnose fixture video open failure path

**Bead ID:** `aerobeat-input-mediapipe-python-m0t`  
**SubAgent:** `primary` (for `research`)  
**Role:** `research`  
**References:** `REF-01`, `REF-02`, `REF-03`  
**Prompt:** Claim the assigned bead on start. Reproduce or inspect the proving-harness file-source failure and determine whether the root cause is (a) bad path handoff from the testbed harness, (b) unsupported container/codec or OpenCV file-open behavior on this host, or (c) sidecar logic that incorrectly treats prerecorded sources like live cameras. Ground the diagnosis in direct repo inspection and host-level reproduction.

**Folders Created/Deleted/Modified:**
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-mediapipe-python/.testbed/`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-mediapipe-python/python_mediapipe/`

**Files Created/Deleted/Modified:**
- `.testbed/scenes/flow_proving.tscn` (likely owner of the stale serialized source value)

**Status:** ✅ Complete

**Results:** Traced the source override from the proving scene through `proving_harness.gd`, `AutoStartManager`, and sidecar launch args into `python_mediapipe/main.py`. The handoff chain is functioning correctly. The actual problem is that `.testbed/scenes/flow_proving.tscn` serializes a nonexistent fixture path (`res://assets/fixtures/flow/flow_swing_left_3_right_3_to_left_6_right_6_x4.webm`), while the real fixture on disk is nested and uses `.mp4` (`res://assets/fixtures/flow/left_3_right_3_to_left_6_right_6/flow_swing_left_3_right_3_to_left_6_right_6_x4.mp4`). OpenCV on this host opens the real `.mp4` successfully and reproduces the exact failure only for the stale `.webm` path. Recommended fix: correct the serialized scene path and add a narrow preflight existence check so Godot surfaces a truthful error before Python launch. References validated: `REF-01`, `REF-02`, `REF-03`.

---

### Task 2: Implement the smallest robust fix

**Bead ID:** `aerobeat-input-mediapipe-python-yco`  
**SubAgent:** `primary` (for `coder`)  
**Role:** `coder`  
**References:** `REF-01`, `REF-02`, `REF-03`  
**Prompt:** Claim the assigned bead on start. Implement the smallest robust fix for the diagnosed prerecorded-fixture failure, keeping scope tight. Validate against the real proving harness or a direct sidecar reproduction on this host. Commit and push by default unless blocked.

**Folders Created/Deleted/Modified:**
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-mediapipe-python/.testbed/`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-mediapipe-python/python_mediapipe/`

**Files Created/Deleted/Modified:**
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-mediapipe-python/.testbed/scenes/flow_proving.tscn`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-mediapipe-python/src/autostart_manager.gd`

**Status:** ✅ Complete

**Results:** Corrected the stale serialized Flow proving-scene source from the nonexistent flat `.webm` path to the real nested `.mp4` fixture path. Added a narrow Godot-side preflight in `src/autostart_manager.gd` so prerecorded file sources are validated before Python launch; missing files now fail early with `Configured prerecorded camera source does not exist: <absolute path>`. Validation passed on host through direct OpenCV open of the real fixture, existing repo-local unit tests, positive proving-harness capture using the scene default Flow path, and negative-path proving capture showing the clear early failure message. Commit landed as `32f7011` (`Fix Flow proving fixture video source`). References validated: `REF-01`, `REF-02`, `REF-03`.

---

### Task 3: Audit end-to-end fixture playback in the proving harness

**Bead ID:** `aerobeat-input-mediapipe-python-l2x`  
**SubAgent:** `primary` (for `auditor`)  
**Role:** `auditor`  
**References:** `REF-01`, `REF-02`, `REF-03`  
**Prompt:** Claim the assigned bead on start. Independently verify the fix using the real proving harness fixture flow on this host. Confirm the sidecar remains up, the prerecorded source opens successfully, and the original `Could not open camera <fixture-path>` failure is gone. Close only if the user-facing behavior is actually fixed.

**Folders Created/Deleted/Modified:**
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-mediapipe-python/.testbed/`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-mediapipe-python/python_mediapipe/`

**Files Created/Deleted/Modified:**
- none expected beyond runtime/test artifacts

**Status:** ⏳ Pending

**Results:** Pending.

---

## Final Results

**Status:** ⏳ Pending

**What We Built:** Pending.

**Reference Check:** Pending.

**Commits:**
- Pending.

**Lessons Learned:** Pending.

---

*Completed on Pending*
