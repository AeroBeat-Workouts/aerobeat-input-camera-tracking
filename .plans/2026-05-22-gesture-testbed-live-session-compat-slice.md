# AeroBeat Input Camera Tracking — Gesture-Testbed Live Session Compatibility Slice

**Date:** 2026-05-22  
**Status:** In Progress  
**Agent:** Cookie 🍪

---

## Goal

Make `camera_gesture_testbed` live MediaPipe mode work honestly against the split stack through the assembly-facing adapter lane, including owned/borrowed session behavior, metadata matching, and legacy addon-path continuity.

---

## Overview

The downstream audit already proved the biggest live-only blocker sits here: `aerobeat-input-camera-tracking` publishes a shareable provider session, but it does not yet publish enough metadata for the gesture testbed to borrow the session it wants, and it does not yet provide a strict acquire/release compatibility lane for that borrowed-mode workflow. The testbed also still hardcodes the legacy addon path `aerobeat-input-mediapipe-python`, so live parity is still broken even before replay enters the picture.

This slice stays narrow and repo-owned. `aerobeat-input-camera-tracking` should own the assembly-facing provider/session adapter compatibility layer: publish the exact live metadata the testbed matches on, provide the minimal borrower bookkeeping/debug surface the testbed expects, and supply a truthful compatibility route for the old addon path without reclaiming tool-owned public service semantics or vendor-owned runtime behavior.

This is the recommended first implementation slice in the full parity wave. Replay is intentionally out of scope here.

---

## REFERENCES

| ID | Description | Path |
| --- | --- | --- |
| `REF-01` | Cross-repo coordination plan | `/workspace/projects/openclaw-cookie/.plans/aerobeat-architecture/2026-05-22-gesture-testbed-full-parity.md` |
| `REF-02` | Downstream parity audit | `/workspace/projects/openclaw-cookie/.plans/aerobeat-architecture/2026-05-22-downstream-testbed-parity-audit.md` |
| `REF-03` | Gesture testbed script | `/workspace/projects/aerobeat/aerobeat-tool-camera-gesture-control/.testbed/scripts/camera_gesture_testbed.gd` |
| `REF-04` | Assembly-facing input provider | `/workspace/projects/aerobeat/aerobeat-input-camera-tracking/src/input_provider.gd` |
| `REF-05` | Legacy-compatible camera view seam | `/workspace/projects/aerobeat/aerobeat-input-camera-tracking/src/camera_view.gd` |
| `REF-06` | Legacy-compatible autostart seam | `/workspace/projects/aerobeat/aerobeat-input-camera-tracking/src/autostart_manager.gd` |
| `REF-07` | Provider session registry contract | `/workspace/projects/aerobeat/aerobeat-input-core/src/runtime/provider_session_registry.gd` |
| `REF-08` | Prior assembly adapter slice already green | `/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.plans/2026-05-22-assembly-facing-camera-tracking-adapter-slice.md` |

---

## Slice Boundaries

### In scope

- publish the live metadata keys the gesture testbed matches on: `provider_id`, `runtime_mode`, `camera_source`, `tracking_overlay_mode`, `gesture_eval_interval_frames`, `min_visibility`, plus stable session-key/owner info
- provide strict acquire/release compatibility around borrowed provider-session use through the assembly-facing adapter lane
- expose minimal owned/borrowed debug fields needed by the gesture testbed’s provider snapshot path
- supply a truthful compatibility route for the legacy addon path `aerobeat-input-mediapipe-python` so the testbed can resolve `input_provider.gd`, `camera_view.gd`, and `autostart_manager.gd` without editing consumer mirrors as owned source
- add/update repo-local tests and any proving glue needed to verify the live owned/borrowed path

### Explicitly out of scope

- replay / `video_file` support
- richer tool-owned preview/public-state semantics beyond what this adapter must publish
- vendor runtime changes
- final product-wide session-discovery architecture beyond the narrow compatibility surface needed here

---

## Tasks

### Task 1: Implement live session adapter compatibility for gesture testbed

**Bead ID:** `aerobeat-input-camera-tracking-moz`  
**SubAgent:** `primary`  
**Role:** `coder`  
**References:** `REF-01`, `REF-02`, `REF-03`, `REF-04`, `REF-05`, `REF-06`, `REF-07`, `REF-08`  
**Prompt:** In `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking`, claim bead `aerobeat-input-camera-tracking-moz` with `bd update aerobeat-input-camera-tracking-moz --status in_progress --json` when you start. Implement the narrowest honest live compatibility slice from `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.plans/2026-05-22-gesture-testbed-live-session-compat-slice.md`. Required outcomes: publish the gesture-testbed live metadata keys from the assembly-facing provider/session adapter lane, make borrowed-session acquire/release bookkeeping and minimal owned-vs-borrowed debug fields truthful, and provide a compatibility route for the legacy addon path `aerobeat-input-mediapipe-python` covering `input_provider.gd`, `camera_view.gd`, and `autostart_manager.gd` without treating consumer mirrors as owned source. Keep replay out of scope. Run relevant repo-local validation, commit, and push before handoff unless blocked.

**Folders Created/Deleted/Modified:**
- `/workspace/projects/aerobeat/aerobeat-input-camera-tracking/src/`
- `/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.testbed/`
- `/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.plans/`

**Files Created/Deleted/Modified:**
- `/workspace/projects/aerobeat/aerobeat-input-camera-tracking/src/input_provider.gd`
- `/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.testbed/tests/unit/test_input_provider_adapter.gd`
- `/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.plans/2026-05-22-gesture-testbed-live-session-compat-slice.md`

**Status:** ✅ Complete

**Results:** Claimed bead `aerobeat-input-camera-tracking-moz`, then kept the slice inside the repo-owned adapter layer rather than stealing tool/vendor runtime semantics. `src/input_provider.gd` now publishes the live session metadata keys the downstream gesture testbed matches on (`runtime_mode`, `camera_source`, `tracking_overlay_mode`, `gesture_eval_interval_frames`, `min_visibility`) while preserving the existing `provider_id` / `session_key` reuse contract (`mediapipe_python`). Added narrow compatibility helpers on the adapter for `request_shared_session`, `acquire_shared_session`, `release_shared_session`, and `get_shared_session_debug_state`, plus republish-on-change behavior so live metadata stays truthful when the selected camera or tracking session changes. Repo-local tests now prove shared-session publication, borrowed-session acquire/release bookkeeping, and owned-session debug reporting in `.testbed/tests/unit/test_input_provider_adapter.gd`. No replay behavior was added. No consumer mirror files were treated as owned source; the existing repo entrypoints already satisfy the legacy addon alias when the consumer mounts this repo under `aerobeat-input-mediapipe-python`.

Validation run:
- `python3 scripts/refresh_testbed_workbench.py` ✅
- `godot --headless --path .testbed --script addons/gut/gut_cmdln.gd -gtest=res://tests/unit/test_input_provider_adapter.gd -gexit` ✅ (11/11 passed)
- `godot --headless --path .testbed --script addons/gut/gut_cmdln.gd -gdir=res://tests -ginclude_subdirs -gexit` ⚠️ repo has three pre-existing unrelated failures outside this slice (`test_mediapipe_process.gd`, `test_mediapipe_provider.gd`, `test_proving_harness_trails.gd`); the adapter test file passed cleanly.

---

### Task 2: QA live session adapter compatibility for gesture testbed

**Bead ID:** `aerobeat-input-camera-tracking-gte`  
**SubAgent:** `primary`  
**Role:** `qa`  
**References:** `REF-02`, `REF-03`, `REF-04`, `REF-05`, `REF-06`, `REF-07`  
**Prompt:** In `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking`, wait until bead `aerobeat-input-camera-tracking-gte` is unblocked, then claim it with `bd update aerobeat-input-camera-tracking-gte --status in_progress --json`. Independently verify the live gesture-testbed compatibility slice. Prove the adapter publishes the exact live metadata keys the testbed matches on, prove borrowed-session acquire/release bookkeeping and owned/borrowed debug fields are truthful, verify the legacy addon-path compatibility route resolves the required files, and confirm the change did not reclaim tool/vendor ownership or edit addon mirrors as owned source. Record exact commands/results/gaps and leave the auditor bead open.

**Folders Created/Deleted/Modified:**
- validation-only use of repo-local proving surfaces

**Files Created/Deleted/Modified:**
- none required unless a minimal QA artifact is necessary

**Status:** ⏳ Pending

**Results:** Pending.

---

### Task 3: Audit live session adapter compatibility for gesture testbed

**Bead ID:** `aerobeat-input-camera-tracking-yu1`  
**SubAgent:** `primary`  
**Role:** `auditor`  
**References:** `REF-01`, `REF-02`, `REF-03`, `REF-04`, `REF-05`, `REF-06`, `REF-07`, `REF-08`  
**Prompt:** In `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking`, wait until bead `aerobeat-input-camera-tracking-yu1` is unblocked, then claim it with `bd update aerobeat-input-camera-tracking-yu1 --status in_progress --json`. Independently audit the live gesture-testbed compatibility slice against this plan, the diff, coder evidence, and QA evidence. Close the bead only if live owned/borrowed compatibility is genuinely proven, the published metadata matches the downstream contract, the legacy path route is truthful, and repo ownership boundaries stayed strict.

**Folders Created/Deleted/Modified:**
- audit notes only if needed

**Files Created/Deleted/Modified:**
- none required unless a minimal audit artifact is necessary

**Status:** ⏳ Pending

**Results:** Pending.

---

## Dependency Shape

- `aerobeat-input-camera-tracking-moz` → coder implementation bead
- `aerobeat-input-camera-tracking-gte` depends on `aerobeat-input-camera-tracking-moz`
- `aerobeat-input-camera-tracking-yu1` depends on `aerobeat-input-camera-tracking-gte`

Cross-repo coordination note: this is the recommended first implementation slice in the full parity wave. The tool live slice should start after this auditor bead closes.

---

## Final Results

**Status:** ⏳ Draft

**What We Built:** Planning only so far.

**Reference Check:** Live session adapter compatibility is not yet implemented; this plan encodes the first repo-owned execution wave needed to satisfy the downstream gesture-testbed contract.

**Commits:**
- None yet.

**Lessons Learned:** The live parity blocker here is not generic tracking output. It is exact session publication/borrowing compatibility plus legacy path continuity.

---

*Prepared on 2026-05-22*
