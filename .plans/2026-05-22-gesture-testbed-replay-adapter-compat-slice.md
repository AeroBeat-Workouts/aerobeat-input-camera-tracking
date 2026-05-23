# AeroBeat Input Camera Tracking — Gesture-Testbed Replay Adapter Compatibility Slice

**Date:** 2026-05-22  
**Status:** Complete  
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
- `/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.temp/qa-replay-alias-only/` (disposable alias-only replay probe project)

**Files Created/Deleted/Modified:**
- `/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.temp/qa-replay-alias-only/project.godot`
- `/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.temp/qa-replay-alias-only/probe.gd`

**Status:** ✅ Complete

**Results:** QA rerun passed after fix commit `1a03204`, and bead `aerobeat-input-camera-tracking-0bt` is now eligible to close. I re-claimed the existing QA bead with `bd update aerobeat-input-camera-tracking-0bt --status in_progress --json`, refreshed the repo-local workbench, reran the targeted replay adapter/provider tests, then reran the alias-only disposable consumer probe under a project that mounted this repo only as `res://addons/aerobeat-input-mediapipe-python` plus `aerobeat-input-core`, `aerobeat-tool-camera-tracking`, and the vendor repo — with **no** parallel `aerobeat-input-camera-tracking` self-mount.

Exact validation run:
- `python3 scripts/refresh_testbed_workbench.py` ✅ refreshed `.testbed`, reran `godotenv addons install`, and completed headless import successfully.
- `godot --headless --path .testbed --script addons/gut/gut_cmdln.gd -gtest=res://tests/unit/test_camera_tracking_provider.gd -gexit` ✅ `5/5` passed (`25` asserts).
- `godot --headless --path .testbed --script addons/gut/gut_cmdln.gd -gtest=res://tests/unit/test_input_provider_adapter.gd -gexit` ✅ `12/12` passed (`78` asserts).
- `godot --headless --path .temp/qa-replay-alias-only --import --quit-after 1000` ✅ completed successfully after updating script-class caches for the alias-only mounted project.
- `godot --headless --path .temp/qa-replay-alias-only --script res://probe.gd` ✅ alias-only replay probe passed and printed the decisive proof points:
  - load path continuity: `QA_ALIAS_INPUT_PROVIDER_LOAD_OK=true`, `QA_ALIAS_CAMERA_TRACKING_PROVIDER_LOAD_OK=true`, `QA_ALIAS_CAMERA_VIEW_LOAD_OK=true`, `QA_ALIAS_AUTOSTART_LOAD_OK=true`
  - replay startup/publication: `QA_REPLAY_START_OK=true`, `QA_REQUEST_OK=true`, `QA_SESSION_KEY=mediapipe_python`, `QA_PROVIDER_ID=mediapipe_python`
  - truthful replay metadata: `QA_METADATA_RUNTIME=replay`, `QA_METADATA_SOURCE_KIND=video_file`, `QA_METADATA_CAMERA_SOURCE=res://assets/fixtures/replay/head_rotate_left_repeat_04_take_01.mp4`, `QA_METADATA_FIXTURE_VIDEO_PATH=res://assets/fixtures/replay/head_rotate_left_repeat_04_take_01.mp4`, `QA_METADATA_PROVIDER_LANE=camera_tracking`, `QA_METADATA_LEGACY_FALLBACK=false`
  - borrowability/coherence: `QA_ACQUIRE_OK=true`, `QA_BORROWER_COUNT_AFTER_ACQUIRE=1`, `QA_RELEASE_OK=true`, `QA_BORROWER_COUNT_AFTER_RELEASE=0`, `QA_REQUEST_AFTER_RELEASE_OK=true`, `QA_REQUEST_AFTER_STOP_OK=false`
  - replay mutation refusal/debug truth: `QA_SET_LIVE_MUTATION_OK=false`, `QA_SOURCE_AFTER_MUTATION=res://assets/fixtures/replay/head_rotate_left_repeat_04_take_01.mp4`, `QA_DEBUG_ROLE=owned`, `QA_DEBUG_BORROWED=false`, `QA_DEBUG_PROVIDER_ID=mediapipe_python`, `QA_DEBUG_PROVIDER_LANE=camera_tracking`, `QA_DEBUG_RUNTIME=replay`, `QA_DEBUG_SOURCE_KIND=video_file`, `QA_DEBUG_CAMERA=res://assets/fixtures/replay/head_rotate_left_repeat_04_take_01.mp4`, `QA_DEBUG_FIXTURE_VIDEO_PATH=res://assets/fixtures/replay/head_rotate_left_repeat_04_take_01.mp4`

QA conclusion: this repo’s provider layer now publishes truthful replay adapter/session metadata, keeps `runtime_mode` / `source_kind` / source identity coherent for replay, refuses live-camera mutation while replay is active, keeps publication/borrow/release/unpublish behavior coherent, and the legacy alias-only consumer shape now works without requiring a parallel canonical self-mount. The earlier alias-path failure is resolved in the current codebase.

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

**Status:** ✅ Complete

**Results:** Audit passed and bead `aerobeat-input-camera-tracking-ub6` is eligible to close. I first verified the dependency gate was genuinely open (`bd show aerobeat-input-camera-tracking-ub6 --json` showed QA bead `aerobeat-input-camera-tracking-0bt` already closed), then claimed the audit bead with `bd update aerobeat-input-camera-tracking-ub6 --status in_progress --json`.

Independent audit checks and evidence:
- **Planned scope / diff check:** `git diff --stat 79eb485^ 1a03204` and targeted `git diff` showed source changes stayed limited to `src/input_provider.gd`, `src/providers/camera_tracking_provider.gd`, and the two focused unit test files, plus plan documentation. No vendor runtime, tool public-service, camera view, or autostart source behavior was broadened in this replay slice.
- **Truthful replay metadata through the provider layer:** source inspection of `src/input_provider.gd` confirms provider-session publication/debug state now derive replay truth from the active `CameraTracking` config via `_shared_session_source_kind()` / `_shared_session_source_identity()`, publishing `runtime_mode`, `source_kind`, `camera_source`, and `fixture_video_path` instead of hard-coding live-camera semantics.
- **Replay source identity correctness:** source inspection of `src/providers/camera_tracking_provider.gd` confirms `get_selected_camera_device_id()` returns `source.path` for `video_file`, `_build_tracking_config()` emits replay `source = { kind = video_file, path = ... }` when the configured source is a file path, and `set_selected_camera_device_id()` refuses mutation while the active source kind is replay/video-file.
- **Repo-local validation rerun:** reran `python3 scripts/refresh_testbed_workbench.py` ✅, `godot --headless --path .testbed --script addons/gut/gut_cmdln.gd -gtest=res://tests/unit/test_camera_tracking_provider.gd -gexit` ✅ (`5/5`, `25` asserts), and `godot --headless --path .testbed --script addons/gut/gut_cmdln.gd -gtest=res://tests/unit/test_input_provider_adapter.gd -gexit` ✅ (`12/12`, `78` asserts). The replay-focused unit coverage directly proves replay metadata publication, borrowability via replay metadata match, and live-mutation refusal.
- **Original QA failure / fix truth check:** `git show 1a03204` confirms the follow-up repair was narrowly the alias-mount compatibility seam in `src/providers/camera_tracking_provider.gd` (swap hard-coded canonical addon loads for mount-relative repo-root resolution via `_get_repo_src_root_path()` / `_load_repo_src_script()`), plus the minimal proving test `test_camera_tracking_provider_resolves_repo_owned_scripts_relative_to_its_mount()`.
- **Alias-only consumer rerun:** reran `godot --headless --path .temp/qa-replay-alias-only --import --quit-after 1000` ✅ and `godot --headless --path .temp/qa-replay-alias-only --script res://probe.gd` ✅. The probe printed decisive proof that the legacy alias-only consumer shape now works with only `addons/aerobeat-input-mediapipe-python` mounted: `QA_ALIAS_INPUT_PROVIDER_LOAD_OK=true`, `QA_ALIAS_CAMERA_TRACKING_PROVIDER_LOAD_OK=true`, `QA_ALIAS_CAMERA_VIEW_LOAD_OK=true`, `QA_ALIAS_AUTOSTART_LOAD_OK=true`, `QA_REPLAY_START_OK=true`, `QA_REQUEST_OK=true`, `QA_METADATA_RUNTIME=replay`, `QA_METADATA_SOURCE_KIND=video_file`, `QA_METADATA_CAMERA_SOURCE=res://assets/fixtures/replay/head_rotate_left_repeat_04_take_01.mp4`, `QA_METADATA_FIXTURE_VIDEO_PATH=res://assets/fixtures/replay/head_rotate_left_repeat_04_take_01.mp4`, `QA_METADATA_PROVIDER_LANE=camera_tracking`, `QA_METADATA_LEGACY_FALLBACK=false`, `QA_ACQUIRE_OK=true`, `QA_BORROWER_COUNT_AFTER_ACQUIRE=1`, `QA_SET_LIVE_MUTATION_OK=false`, `QA_SOURCE_AFTER_MUTATION=res://assets/fixtures/replay/head_rotate_left_repeat_04_take_01.mp4`, `QA_DEBUG_RUNTIME=replay`, `QA_DEBUG_SOURCE_KIND=video_file`, `QA_RELEASE_OK=true`, `QA_BORROWER_COUNT_AFTER_RELEASE=0`, `QA_REQUEST_AFTER_RELEASE_OK=true`, and `QA_REQUEST_AFTER_STOP_OK=false`.

Audit conclusion: the replay-capable adapter/provider layer now publishes truthful session metadata for replay, runtime/source identity stays coherent, live-camera mutation is refused during replay, publication/borrow/release/unpublish behavior remains coherent, and the alias-only consumer mount shape is repaired without reclaiming vendor/tool ownership. This slice is complete for its planned scope.

---

## Dependency Shape

- `aerobeat-input-camera-tracking-0fg` → coder implementation bead
- `aerobeat-input-camera-tracking-0bt` depends on `aerobeat-input-camera-tracking-0fg`
- `aerobeat-input-camera-tracking-ub6` depends on `aerobeat-input-camera-tracking-0bt`

Cross-repo coordination note: this replay input slice should begin after tool replay auditor bead `atct-mv8` closes.

---

## Final Results

**Status:** ✅ Complete

**What We Built:** `aerobeat-input-camera-tracking` now truthfully adapts replay-capable `CameraTracking` sessions through its assembly-facing provider layer. Replay sessions publish correct provider-session/debug metadata (`runtime_mode = replay`, `source_kind = video_file`, replay source identity in both `camera_source` and `fixture_video_path`), remain borrowable through the existing `provider_id/session_key = mediapipe_python` compatibility shell, refuse live-camera mutation while replay is active, and unpublish cleanly on stop. The repo also now resolves its provider-owned helper scripts relative to its mounted addon path, so downstream consumers can mount only `addons/aerobeat-input-mediapipe-python` without also mounting a parallel canonical `aerobeat-input-camera-tracking` alias.

**Reference Check:** Auditor rerun satisfied `REF-03`, `REF-04`, `REF-07`, `REF-08`, and `REF-09` with independent source review plus command reruns. `REF-04` now publishes truthful replay metadata/session facts through the provider-session compatibility shell; `REF-07` borrow/release/unpublish behavior remains coherent under replay; `REF-08` ownership boundaries remain strict because no tool public-service or vendor runtime behavior was reclaimed here; and `REF-09` continuity is preserved because the live-session adapter shell and reuse contract remain intact. `REF-05` and `REF-06` source files remain unchanged, which is consistent with the planned narrow scope.

**Commits:**
- `79eb485` - Add replay adapter compatibility metadata
- `1a03204` - Fix replay provider alias mount compatibility

**Lessons Learned:** The replay break was entirely about compatibility truth at the adapter seam, not new tracking behavior. Two details mattered: provider-session metadata must derive from the active `CameraTracking` source contract instead of assuming live camera, and provider-owned helper loads must resolve from the actual mounted addon path consumers use in practice.

---

*Prepared on 2026-05-22*
