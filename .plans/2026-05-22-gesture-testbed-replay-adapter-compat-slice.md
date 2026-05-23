# AeroBeat Input Camera Tracking — Gesture-Testbed Replay Adapter Compatibility Slice

**Date:** 2026-05-22  
**Status:** In Progress  
**Agent:** Cookie 🍪

---

## Goal

Finish the assembly-facing replay adapter compatibility lane needed for `camera_gesture_testbed` to run `mediapipe_replay` through the split stack after vendor and tool replay support exist.

---

## Overview

Replay parity ends in this repo because the gesture testbed still consumes the assembly-facing adapter layer, the legacy addon path, and the provider-session metadata/debug surfaces published from `aerobeat-input-camera-tracking`. Even after vendor replay and tool replay are green, the testbed will still fail parity if this repo cannot publish truthful replay metadata, preserve compatibility routing, and adapt the replay session through the existing assembly-facing seams.

This slice therefore stays narrow and downstream-facing: consume the replay-capable public contract, publish truthful replay metadata/debug/session facts, preserve the legacy addon path continuity needed by the testbed, and avoid reclaiming vendor runtime or tool public-service ownership.

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
| `REF-08` | Tool replay public-service plan | `/workspace/projects/aerobeat/aerobeat-tool-camera-tracking/.plans/2026-05-22-gesture-testbed-replay-public-service-slice.md` |
| `REF-09` | Prior live adapter slice plan | `/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.plans/2026-05-22-gesture-testbed-live-session-compat-slice.md` |

---

## Slice Boundaries

### In scope

- consume the replay-capable `CameraTracking` contract through the assembly-facing adapter lane
- publish truthful replay metadata (`runtime_mode`, fixture/source identity, and any exact keys the gesture testbed matches) through the provider-session compatibility shell
- preserve legacy addon-path continuity for the testbed’s replay flow
- expose minimal replay-owned/borrowed debug/session facts needed by the downstream provider snapshot path
- add/update repo-local tests and proving glue for replay adapter behavior

### Explicitly out of scope

- new vendor runtime behavior
- new tool public-service semantics beyond what the adapter must consume
- broader product-wide session architecture redesign

---

## Tasks

### Task 1: Implement replay adapter compatibility for gesture testbed

**Bead ID:** `aerobeat-input-camera-tracking-0fg`  
**SubAgent:** `primary`  
**Role:** `coder`  
**References:** `REF-01`, `REF-02`, `REF-03`, `REF-04`, `REF-05`, `REF-06`, `REF-07`, `REF-08`, `REF-09`  
**Prompt:** In `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking`, claim bead `aerobeat-input-camera-tracking-0fg` with `bd update aerobeat-input-camera-tracking-0fg --status in_progress --json` when you start. Implement the narrowest honest replay slice from `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.plans/2026-05-22-gesture-testbed-replay-adapter-compat-slice.md`. Required outcomes: consume the replay-capable public contract through the assembly-facing adapter, publish truthful replay metadata/session facts needed by the gesture testbed, preserve legacy addon-path continuity for the replay flow, and keep vendor/tool ownership boundaries strict. Run relevant repo-local validation, commit, and push before handoff unless blocked.

**Folders Created/Deleted/Modified:**
- `/workspace/projects/aerobeat/aerobeat-input-camera-tracking/src/`
- `/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.testbed/`
- `/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.plans/`

**Files Created/Deleted/Modified:**
- `/workspace/projects/aerobeat/aerobeat-input-camera-tracking/src/input_provider.gd`
- `/workspace/projects/aerobeat/aerobeat-input-camera-tracking/src/providers/camera_tracking_provider.gd`
- `/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.testbed/tests/unit/test_input_provider_adapter.gd`
- `/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.testbed/tests/unit/test_camera_tracking_provider.gd`
- `/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.plans/2026-05-22-gesture-testbed-replay-adapter-compat-slice.md`

**Status:** ✅ Complete

**Results:** Claimed bead `aerobeat-input-camera-tracking-0fg` and kept the slice inside repo-owned adapter/provider compatibility behavior. `src/input_provider.gd` now derives shared-session truth from the active `CameraTracking` source config instead of hard-coding live mode: replay sessions publish `runtime_mode = replay`, `source_kind = video_file`, `camera_source = <fixture path>`, and `fixture_video_path = <fixture path>` through the same provider-session/debug compatibility shell the downstream gesture testbed already consumes. `src/providers/camera_tracking_provider.gd` now treats replay source identity truthfully at the adapter seam by surfacing `source.path` for `video_file`, refusing live-camera mutation while a replay session is active, and building a replay `CameraTracking` config when this provider owns session startup from a file-path camera source.

After QA found that the replay path still broke when this repo was mounted only under the legacy addon alias, I repaired that exact downstream compatibility seam without broadening ownership. `src/providers/camera_tracking_provider.gd` no longer hard-preloads or hard-loads repo-owned support scripts through the canonical addon key; instead it resolves `tracking_frame_adapter.gd` and `config/mediapipe_config.gd` relative to the provider script’s own mounted path. That keeps the replay provider bootable whether consumers mount this repo as `aerobeat-input-camera-tracking` or only as `aerobeat-input-mediapipe-python`, while leaving replay metadata behavior unchanged.

`.testbed/tests/unit/test_input_provider_adapter.gd` proves the replay compatibility lane directly: a started replay `CameraTracking` session is consumed through the adapter, publishes replay metadata/debug facts, preserves the `provider_id/session_key = mediapipe_python` reuse contract, and remains borrowable by downstream consumers using the replay metadata match shape. `.testbed/tests/unit/test_camera_tracking_provider.gd` now also proves the provider resolves its repo-owned helper scripts from its own mount-relative path instead of assuming the canonical addon name. This stayed deliberately narrow: no vendor runtime behavior changed, no new tool public-service semantics were claimed, and no consumer addon mirror was edited as owned source.

Validation run:
- `python3 scripts/refresh_testbed_workbench.py` ✅
- `godot --headless --path .testbed --script addons/gut/gut_cmdln.gd -gtest=res://tests/unit/test_camera_tracking_provider.gd -gexit` ✅ (`5/5` passed, `25` asserts)
- `godot --headless --path .testbed --script addons/gut/gut_cmdln.gd -gtest=res://tests/unit/test_input_provider_adapter.gd -gexit` ✅ (`12/12` passed, `78` asserts)
- disposable alias-only replay probe project (`aerobeat-input-mediapipe-python` + `aerobeat-input-core` + `aerobeat-tool-camera-tracking`, no parallel canonical self-mount) ✅ `QA_REPLAY_START_OK=true`, `QA_REQUEST_OK=true`, `QA_ACQUIRE_OK=true`, `QA_DEBUG_RUNTIME=replay`, `QA_DEBUG_SOURCE_KIND=video_file`

---

### Task 2: QA replay adapter compatibility for gesture testbed

**Bead ID:** `aerobeat-input-camera-tracking-0bt`  
**SubAgent:** `primary`  
**Role:** `qa`  
**References:** `REF-02`, `REF-03`, `REF-04`, `REF-05`, `REF-06`, `REF-07`, `REF-08`, `REF-09`  
**Prompt:** In `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking`, wait until bead `aerobeat-input-camera-tracking-0bt` is unblocked, then claim it with `bd update aerobeat-input-camera-tracking-0bt --status in_progress --json`. Independently verify the replay adapter slice. Prove replay metadata/session facts are published truthfully, prove the legacy addon-path route still resolves the required replay-facing seams, and confirm the adapter consumes replay through tool-owned public surfaces without reclaiming vendor/tool ownership. Record exact commands/results/gaps and leave the auditor bead open.

**Folders Created/Deleted/Modified:**
- validation-only use of repo-local proving surfaces

**Files Created/Deleted/Modified:**
- none required unless a minimal QA artifact is necessary

**Status:** ❌ Failed

**Results:** QA did **not** pass yet, so bead `aerobeat-input-camera-tracking-0bt` remains open. I first verified the bead was unblocked (`bd show aerobeat-input-camera-tracking-0bt --json`, dependency `aerobeat-input-camera-tracking-0fg` closed) and claimed it with `bd update aerobeat-input-camera-tracking-0bt --status in_progress --json`.

Focused validation that **passed**:
- `python3 scripts/refresh_testbed_workbench.py` ✅ refreshed `.testbed`, reran `godotenv addons install`, and completed headless import successfully.
- `godot --headless --path .testbed --script addons/gut/gut_cmdln.gd -gtest=res://tests/unit/test_input_provider_adapter.gd -gexit` ✅ `12/12` passed (`78` asserts).
- `godot --headless --path .testbed --script addons/gut/gut_cmdln.gd -gtest=res://tests/unit/test_camera_tracking_provider.gd -gexit` ✅ `4/4` passed (`22` asserts).
- Code / downstream matcher review showed the repo-local slice now publishes truthful replay metadata in the adapter/provider layer: `runtime_mode = replay`, `source_kind = video_file`, `camera_source = <fixture path>`, `fixture_video_path = <fixture path>`, and `provider_id/session_key = mediapipe_python`. `src/providers/camera_tracking_provider.gd` also correctly refuses live-camera mutation during replay by returning `false` from `set_selected_camera_device_id()` when the active source kind is `video_file`.

Focused validation that **failed** and blocks QA closure:
- I created a disposable consumer-shaped Godot probe project that mounted this repo only under the legacy addon alias `res://addons/aerobeat-input-mediapipe-python/` plus `aerobeat-input-core` and `aerobeat-tool-camera-tracking`, then ran `godot --headless --path <tmp> --import --quit-after 1000` followed by `godot --headless --path <tmp> --script res://probe.gd`.
- In that replay-shaped alias mount, provider startup failed before session publication/borrowing could succeed. The decisive runtime parse error was:
  - `Parse Error: Preload file "res://addons/aerobeat-input-camera-tracking/src/tracking_frame_adapter.gd" does not exist.`
  - originating from `res://addons/aerobeat-input-mediapipe-python/src/providers/camera_tracking_provider.gd:11`
- Because replay uses `camera_tracking_provider.gd`, the legacy alias alone is currently insufficient for the replay flow. The same probe printed `QA_REPLAY_START_OK=false`, `QA_REQUEST_OK=false`, `QA_ACQUIRE_OK=false`, `QA_REQUEST_AFTER_RELEASE_OK=false`, and `QA_REQUEST_AFTER_STOP_OK=false` even though the adapter’s debug state still reflected replay metadata truth (`QA_DEBUG_RUNTIME=replay`, `QA_DEBUG_SOURCE_KIND=video_file`, `QA_DEBUG_CAMERA=<fixture path>`).
- I also confirmed the downstream consumer repo currently mounts only `aerobeat-input-mediapipe-python` under `.testbed/addons/` and does **not** mount a parallel `aerobeat-input-camera-tracking` addon path there, so this is not just a synthetic temp-project issue. In other words: repo-local tests prove the replay metadata/mutation behavior, but the claimed legacy addon-path continuity for replay is still broken in the actual consumer-shaped mount because the replay provider path still hard-references the canonical addon name.

QA conclusion: the replay adapter/provider metadata behavior is good, replay mutation refusal is good, and borrow/release semantics are good in the repo-local testbed, but the slice is **not** yet QA-complete because the replay flow still breaks when consumed through the legacy addon alias the gesture testbed uses. Bead `aerobeat-input-camera-tracking-0bt` must stay open until that alias-path replay break is repaired and re-verified.

---

### Task 3: Audit replay adapter compatibility for gesture testbed

**Bead ID:** `aerobeat-input-camera-tracking-ub6`  
**SubAgent:** `primary`  
**Role:** `auditor`  
**References:** `REF-01`, `REF-02`, `REF-03`, `REF-04`, `REF-05`, `REF-06`, `REF-07`, `REF-08`, `REF-09`  
**Prompt:** In `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking`, wait until bead `aerobeat-input-camera-tracking-ub6` is unblocked, then claim it with `bd update aerobeat-input-camera-tracking-ub6 --status in_progress --json`. Independently audit the replay adapter slice against this plan, the diff, coder evidence, and QA evidence. Close the bead only if replay now works truthfully through the assembly-facing adapter and compatibility shell needed by the gesture testbed, and repo ownership boundaries stayed strict.

**Folders Created/Deleted/Modified:**
- audit notes only if needed

**Files Created/Deleted/Modified:**
- none required unless a minimal audit artifact is necessary

**Status:** ⏳ Pending

**Results:** Pending.

---

## Dependency Shape

- `aerobeat-input-camera-tracking-0fg` → coder implementation bead
- `aerobeat-input-camera-tracking-0bt` depends on `aerobeat-input-camera-tracking-0fg`
- `aerobeat-input-camera-tracking-ub6` depends on `aerobeat-input-camera-tracking-0bt`

Cross-repo coordination note: this replay input slice should begin after tool replay auditor bead `atct-mv8` closes.

---

## Final Results

**Status:** ⚠️ Partial

**What We Built:** The coder slice is implemented and the concrete QA-found alias-path replay break is now repaired in repo-owned code, but an independent QA rerun and audit rerun are still pending. `aerobeat-input-camera-tracking` now consumes replay-capable `CameraTracking` source truth through its adapter/provider layer, publishes replay-compatible provider-session metadata/debug facts for downstream borrowing, and resolves its provider-owned helper scripts from its own mount-relative path so replay can boot/start/borrow successfully even when the consumer mounts only `aerobeat-input-mediapipe-python`.

**Reference Check:** `REF-03`, `REF-04`, `REF-07`, `REF-08`, and `REF-09` are satisfied for coder scope: replay source truth crosses the assembly-facing adapter seam honestly, the provider-session compatibility shell distinguishes live vs replay, and the replay provider no longer assumes a parallel canonical addon mount for its own helper scripts. `REF-05` and `REF-06` remain unchanged. Final completion still depends on independent QA/audit reruns at the planned fidelity.

**Commits:**
- Pending coder commit

**Lessons Learned:** The replay gap here was not new tracking math. It was compatibility at two seams: provider-session metadata had to follow the active `CameraTracking` source mode, and provider-owned helper loads had to follow the mounted addon path actually used by downstream consumers instead of assuming the canonical repo name is always mounted in parallel.

---

*Prepared on 2026-05-22*
