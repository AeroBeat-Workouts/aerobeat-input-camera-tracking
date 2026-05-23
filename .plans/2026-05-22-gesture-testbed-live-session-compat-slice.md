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

**Status:** ✅ Complete

**Results:** QA passed independently against the repo-owned slice. I first verified the bead was unblocked (`bd show aerobeat-input-camera-tracking-gte --json`, dependency `aerobeat-input-camera-tracking-moz` closed) and claimed it with `bd update aerobeat-input-camera-tracking-gte --status in_progress --json`. Diff/ownership review showed the implementation stayed narrow: `git diff --name-only 45a9dfa..HEAD` touched only `src/input_provider.gd`, `.testbed/tests/unit/test_input_provider_adapter.gd`, and this plan file — no edits landed in `src/camera_view.gd`, `src/autostart_manager.gd`, `aerobeat-tool-camera-tracking`, or `aerobeat-vendor-mediapipe-python`, which supports the claim that preview/runtime ownership was not reclaimed.

Validation reruns:
- `python3 scripts/refresh_testbed_workbench.py` ✅ refreshed `.testbed`, reran `godotenv addons install`, and completed headless import successfully.
- `godot --headless --path .testbed --script addons/gut/gut_cmdln.gd -gtest=res://tests/unit/test_input_provider_adapter.gd -gexit` ✅ `11/11` passed.
- `godot --headless --path .testbed --script addons/gut/gut_cmdln.gd -gdir=res://tests -ginclude_subdirs -gexit` ⚠️ still shows the same three unrelated failures already called out by the coder: `test_mediapipe_process.gd`, `test_mediapipe_provider.gd`, and `test_proving_harness_trails.gd`. No new failures appeared in the adapter slice.

Focused extra QA proof beyond the repo test file: I created a temporary minimal Godot project that symlink-mounted this repo as `res://addons/aerobeat-input-mediapipe-python` plus `aerobeat-input-core`, ran `godot --headless --path <tmp> --import --quit-after 1000`, then launched a disposable probe scene. That probe successfully loaded `res://addons/aerobeat-input-mediapipe-python/src/input_provider.gd`, `src/camera_view.gd`, and `src/autostart_manager.gd` under the legacy addon alias, started the provider, and proved the live session contract end to end: `QA_REQUEST_OK=true`, `QA_SESSION_KEY=mediapipe_python`, `QA_PROVIDER_ID=mediapipe_python`, `QA_METADATA_RUNTIME=live`, `QA_METADATA_CAMERA=/dev/video11`, `QA_METADATA_OVERLAY=optimized`, `QA_METADATA_INTERVAL=4`, `QA_METADATA_MIN_VIS=0.41`, `QA_ACQUIRE_OK=true`, `QA_BORROWER_COUNT_AFTER_ACQUIRE=1`, `QA_DEBUG_ROLE=owned`, `QA_DEBUG_BORROWED=false`, `QA_DEBUG_PROVIDER_LANE=legacy_mediapipe`, `QA_SWITCH_OK=true`, `QA_UPDATED_CAMERA=/dev/video12`, `QA_RELEASE_OK=true`, `QA_BORROWER_COUNT_AFTER_RELEASE=0`, `QA_CAMERA_VIEW_LOAD_OK=true`, and `QA_AUTOSTART_LOAD_OK=true`.

That evidence confirms the split adapter now publishes the metadata keys the gesture testbed matches on, preserves the `provider_id/session_key = mediapipe_python` reuse assumption, truthfully exposes owned-session debug state, performs borrower acquire/release bookkeeping through the registry, republish-updates session metadata when the selected camera changes, and still relies on the existing tool/vendor-owned surfaces rather than editing or absorbing them. The only false start in QA was an initial temp-project probe without a prior Godot import; after adding the required `--import` step so class-name registration matched a real consumer boot, the mounted-addon compatibility check passed cleanly.

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

**Status:** ✅ Complete

**Results:** Auditor verified the slice as planned and kept it inside the repo-owned adapter seam. I first confirmed the bead was genuinely unblocked (`bd show aerobeat-input-camera-tracking-yu1 --json`, dependency `aerobeat-input-camera-tracking-gte` closed) and claimed it with `bd update aerobeat-input-camera-tracking-yu1 --status in_progress --json`.

Independent checks performed:
- **Diff / scope check:** `git show --name-only --stat --oneline 8565a31 --` and `git diff --name-only 45a9dfa..8565a31` showed the implementation commit only touched `src/input_provider.gd`, `.testbed/tests/unit/test_input_provider_adapter.gd`, and this plan file. No changes landed in `src/camera_view.gd`, `src/autostart_manager.gd`, `aerobeat-tool-camera-tracking`, or `aerobeat-vendor-mediapipe-python`, so preview ownership and vendor runtime ownership were not reclaimed.
- **Implementation diff check:** `git show --unified=40 8565a31 -- src/input_provider.gd .testbed/tests/unit/test_input_provider_adapter.gd` confirmed the adapter now exposes `request_shared_session`, `acquire_shared_session`, `release_shared_session`, and `get_shared_session_debug_state`; publishes the live metadata keys (`provider_id`, `runtime_mode`, `camera_source`, `tracking_overlay_mode`, `gesture_eval_interval_frames`, `min_visibility`) while preserving `session_key = mediapipe_python`; and republish-updates the published session when camera/device state changes.
- **Replay scope check:** `git show 8565a31 -- src/input_provider.gd .testbed/tests/unit/test_input_provider_adapter.gd` contained no `replay` or `video_file` additions in the implementation/test changes, so this slice did not drift into replay.
- **Targeted repo-local validation:** `godot --headless --path .testbed --script addons/gut/gut_cmdln.gd -gtest=res://tests/unit/test_input_provider_adapter.gd -gexit` passed `11/11`, independently re-proving metadata publication, acquire/release bookkeeping, owned-session debug state, stop/unpublish behavior, collision handling, and the camera-tracking lane fallback boundary.
- **Legacy addon-path truth check:** I created a disposable Godot project mounting this repo as `res://addons/aerobeat-input-mediapipe-python` plus `aerobeat-input-core` and `aerobeat-tool-camera-tracking`, ran `godot --headless --path <tmp> --import --quit-after 1000`, then launched a probe scene. The probe loaded `res://addons/aerobeat-input-mediapipe-python/src/input_provider.gd`, `src/camera_view.gd`, and `src/autostart_manager.gd` successfully and printed: `AUDIT_ALIAS_PROVIDER_LOAD=true`, `AUDIT_ALIAS_CAMERA_VIEW_LOAD=true`, `AUDIT_ALIAS_AUTOSTART_LOAD=true`, `AUDIT_START_OK=true`, `AUDIT_REQUEST_OK=true`, `AUDIT_ACQUIRE_OK=true`, `AUDIT_SESSION_KEY=mediapipe_python`, `AUDIT_PROVIDER_ID=mediapipe_python`, `AUDIT_RUNTIME_MODE=live`, `AUDIT_CAMERA_SOURCE=/dev/video11`, `AUDIT_OVERLAY=optimized`, `AUDIT_INTERVAL=4`, `AUDIT_MIN_VIS=0.41`, `AUDIT_BORROWER_COUNT=1`, `AUDIT_DEBUG_ROLE=owned`, `AUDIT_DEBUG_BORROWED=false`, `AUDIT_DEBUG_PROVIDER_LANE=legacy_mediapipe`, `AUDIT_REPUBLISH_OK=true`, `AUDIT_RELEASE_OK=true`, and `AUDIT_BORROWER_COUNT_AFTER_RELEASE=0`.

Audit conclusion: the live session-compatibility slice is genuinely complete for its planned scope. The adapter now publishes the metadata the downstream live matcher requires, preserves `provider_id/session_key` compatibility, provides real request/acquire/release/debug behavior at the adapter layer, keeps the legacy addon alias route truthful enough for the downstream live path, does not reclaim preview/runtime ownership from tool/vendor repos, and stays out of replay scope.

---

## Dependency Shape

- `aerobeat-input-camera-tracking-moz` → coder implementation bead
- `aerobeat-input-camera-tracking-gte` depends on `aerobeat-input-camera-tracking-moz`
- `aerobeat-input-camera-tracking-yu1` depends on `aerobeat-input-camera-tracking-gte`

Cross-repo coordination note: this is the recommended first implementation slice in the full parity wave. The tool live slice should start after this auditor bead closes.

---

## Final Results

**Status:** ✅ Complete

**What We Built:** The repo-owned live compatibility slice landed in `aerobeat-input-camera-tracking` without stealing tool/vendor responsibilities. `src/input_provider.gd` now publishes the live provider-session metadata the gesture testbed matches on, preserves the canonical `provider_id/session_key = mediapipe_python` reuse contract, exposes adapter-level request/acquire/release/debug helpers for owned shared sessions, and republish-updates metadata when live camera selection changes. Repo-local adapter tests prove the owned/borrowed bookkeeping surface, and the legacy addon alias `aerobeat-input-mediapipe-python` still resolves `input_provider.gd`, `camera_view.gd`, and `autostart_manager.gd` for downstream live consumers.

**Reference Check:**
- `REF-02` / `REF-03`: satisfied for the live matching/reuse contract — metadata keys now line up with the gesture-testbed live request path, and the adapter presents the borrower/debug seam the downstream testbed expects.
- `REF-04` / `REF-07`: satisfied — the adapter now truthfully layers on top of the provider session registry without changing the underlying registry contract, and `provider_id/session_key` compatibility remains intact as `mediapipe_python`.
- `REF-05` / `REF-06`: satisfied for the planned compatibility route — the legacy addon alias can still load `camera_view.gd` and `autostart_manager.gd` from this repo without treating those files as newly owned by this slice.
- Ownership boundary / scope checks also held: no changes landed in tool-camera-tracking preview code, no vendor-mediapipe-python runtime/source ownership was reclaimed, and no replay behavior was added in this slice.

**Commits:**
- `8565a31` - Add live session adapter compatibility helpers

**Lessons Learned:** The honest fix here was narrow adapter compatibility, not broader runtime takeover. Publishing the exact live metadata and borrower bookkeeping at the adapter seam was enough to unlock downstream live reuse while keeping preview/runtime ownership where it already belongs.

---

*Prepared on 2026-05-22*
