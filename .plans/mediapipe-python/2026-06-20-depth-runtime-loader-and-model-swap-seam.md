# AeroBeat depth runtime loader and model-swap seam

**Date:** 2026-06-20
**Status:** In Progress
**Last Updated:** 2026-06-20 12:44 EDT
**Blocked Reason:** None
**Agent:** `pico`

---

## Goal

Wire the boxing depth path so AeroBeat can load the approved monocular depth artifacts through one shared runtime seam and swap models cleanly without rewriting family-level punch logic.

---

## Overview

The repo already has the config-side prerequisites for depth experiments: the staged `depth:` contract in `assets/boxing.gesture_detection.yaml`, the approved `depth.model.artifact_path` locations, and a repo-owned fetch workflow that materializes MiDaS, FastDepth, and Depth Anything V2 Small under `assets/depth_models/`. What is still missing is the runtime seam that can take one of those artifact paths, load the correct inference backend, and expose a stable normalized depth signal to the punch-family threshold logic.

The architecture needs to stay truth-first. Today the shipped detector does **not** consume monocular depth yet. `pose_detector_substrate.gd` still computes `forward_depth_spike` from landmark/camera-space `z` history, and the boxing proving harness explicitly reports that the `depth:` blocks are "config only; live threshold runtime does not consume depth yet." Also, the only already-wired external inference substrate is the existing Python subprocess lane used for MediaPipe pose/hands via the sibling vendor runtime. There is no current ONNX runtime or OpenVINO runtime implementation in this repo, and the vendor Python runtime currently depends only on `mediapipe`, `opencv-python`, and `numpy`.

So the first design goal is not "pretend all three models are live." It is: introduce one honest seam that can centralize artifact resolution, model-family/backend selection, debug state, and normalized depth output. That seam can go live first with artifact resolution + truthful blocked states, then later gain actual ONNX and/or OpenVINO adapters without leaking model-specific conditionals into straight/hook/uppercut threshold code.

---

## REFERENCES

| ID | Description | Path |
| --- | --- | --- |
| `REF-01` | Active depth research note with approved depth contract and artifact paths | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.plans/mediapipe-python/2026-06-19-depth-model-research-note.md` |
| `REF-02` | Active fetch-workflow plan with fetched local artifacts and ignore strategy | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.plans/mediapipe-python/2026-06-20-depth-model-fetch-script-and-sidecars.md` |
| `REF-03` | Shipped boxing depth config with per-family `depth.model.artifact_path` | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/assets/boxing.gesture_detection.yaml` |
| `REF-04` | Current boxing detector runtime owner | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/src/detectors/pose_detector_substrate.gd` |
| `REF-05` | Current proving / inspector surface for boxing depth config | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.testbed/scripts/boxing_proving_harness.gd` |
| `REF-06` | Local fetch metadata for available depth artifacts | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/scripts/depth-models.yaml` |
| `REF-07` | Existing Python tracking runtime substrate currently used by the proving harness | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-vendor-mediapipe-python/runtime/mediapipe_runtime_probe.py` |
| `REF-08` | Current vendor runtime dependency set | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-vendor-mediapipe-python/runtime/requirements.txt` |

---

## Tasks

### Task 1: Design the shared depth runtime seam

**Bead ID:** `aerobeat-input-camera-tracking-kabf`
**SubAgent:** `primary`
**Role:** `research`
**References:** `REF-01`, `REF-03`, `REF-04`, `REF-05`, `REF-06`, `REF-07`, `REF-08`
**Prompt:** Review the current detector/config/fetch state and produce the concrete runtime design for loading interchangeable monocular depth artifacts behind one shared seam. The design must specify: where the loader lives in `src/`, what the normalized adapter interface is, how artifact-path resolution works, how model type is inferred or declared, how load/unload/caching works, and how the detector consumes model-agnostic depth output. Include explicit notes on OpenVINO-vs-ONNX branching so the boxing detector itself stays backend-agnostic.

**Folders Created/Deleted/Modified:**
- `.plans/mediapipe-python/`

**Files Created/Deleted/Modified:**
- `.plans/mediapipe-python/2026-06-20-depth-runtime-loader-and-model-swap-seam.md`

**Status:** ✅ Complete

**Results:** Claimed bead `aerobeat-input-camera-tracking-kabf`, reviewed the detector/config/fetch/proving surfaces plus the existing Python vendor runtime, and updated this plan with a concrete architecture. Main truth findings: (1) `assets/boxing.gesture_detection.yaml` already carries the intended per-family `depth.model.artifact_path` contract from `REF-01`; (2) `scripts/depth-models.yaml` truthfully enumerates one OpenVINO directory-backed MiDaS artifact and two ONNX file-backed alternates; (3) `pose_detector_substrate.gd` does not yet consume monocular depth and still derives `forward_depth_spike` from landmark `z`; (4) `boxing_proving_harness.gd` currently advertises depth as config-only; and (5) the only existing external inference substrate is the sibling MediaPipe Python runtime from `REF-07`, whose current deps in `REF-08` do not include `openvino` or `onnxruntime`. Based on that repo truth, the concrete design keeps backend/model branching inside a shared depth runtime manager plus adapters, marks actual ONNX/OpenVINO execution as staged until a real backend lands, and defines the detector-facing normalized contract/debug contract up front so later loader work does not leak into punch-family logic.

---

### Task 2: Implement model-loader abstraction and artifact resolution

**Bead ID:** `aerobeat-input-camera-tracking-q0t9`
**SubAgent:** `primary`
**Role:** `coder`
**References:** `REF-03`, `REF-04`, `REF-06`, `REF-07`, `REF-08`
**Prompt:** Implement the shared depth runtime seam. Land loader/adapter code that can resolve `depth.model.artifact_path`, identify the active model family, and expose one normalized per-frame depth interface to consumers. Keep model-specific branching inside adapters. Add clean failure states and debug metadata so the proving harness can show whether a model loaded, which backend family it resolved to, and why it failed if it did.

**Folders Created/Deleted/Modified:**
- `src/`
- `.testbed/scripts/`
- `.plans/mediapipe-python/`

**Files Created/Deleted/Modified:**
- `src/<new depth runtime files>`
- `src/detectors/pose_detector_substrate.gd`
- `.plans/mediapipe-python/2026-06-20-depth-runtime-loader-and-model-swap-seam.md`

**Status:** ✅ Complete

**Results:** Claimed bead `aerobeat-input-camera-tracking-q0t9` and landed the shared runtime seam under `src/depth/` with `DepthRuntimeManager`, a base `DepthModelAdapter`, and backend-specific OpenVINO/ONNX adapter stubs. The live part of this seam is now honest artifact resolution from `depth.model.artifact_path`, backend/model-family inference (`openvino` + `midas_openvino_v21_small_256`, `onnx` + `fastdepth_224_onnx`, `onnx` + `depth_anything_v2_small_onnx`, or `custom`), normalized detector-facing result/debug dictionaries, and per-family runtime status wiring into `pose_detector_substrate.gd`. The detector now exposes `depth_runtime` debug state plus family-local runtime status/failure metadata without pushing model-specific branching into punch-family logic. Actual depth inference remains deliberately staged: both adapters truthfully report `adapter_unimplemented` because this repo still has no runnable OpenVINO or ONNX execution substrate. Validation: `godot --headless --path .testbed --quit` now passes script compilation and boots the boxing proving harness without new depth-runtime script errors.

---

### Task 3: Integrate depth inference into boxing threshold flow without model-specific leakage

**Bead ID:** `aerobeat-input-camera-tracking-ms3x`
**SubAgent:** `primary`
**Role:** `coder`
**References:** `REF-01`, `REF-03`, `REF-04`
**Prompt:** Wire the boxing threshold/runtime path so straight/hook/uppercut depth logic consumes the shared normalized depth signal and the existing `depth:` config values. Preserve the existing per-family threshold semantics (`min_closeness_delta`, `max_closeness_delta`, etc.) while keeping the punch-family code unaware of the underlying model family. If any part must remain staged rather than live, make that explicit in comments/debug rather than implying completion.

**Folders Created/Deleted/Modified:**
- `src/`
- `.plans/mediapipe-python/`
- `.testbed/tests/`

**Files Created/Deleted/Modified:**
- `src/detectors/pose_detector_substrate.gd`
- `src/depth/depth_runtime_manager.gd`
- `.testbed/tests/unit/test_pose_detector_substrate.gd`
- `.plans/mediapipe-python/2026-06-20-depth-runtime-loader-and-model-swap-seam.md`

**Status:** ✅ Complete

**Results:** Claimed bead `aerobeat-input-camera-tracking-ms3x` and wired the threshold detector to consume one shared normalized depth seam without leaking backend/model-family branches into straight/hook/uppercut logic. `pose_detector_substrate.gd` now asks the shared depth runtime for normalized wrist-closeness samples, maintains per-family rolling closeness windows, and applies the existing config semantics truthfully: straight punches use `min_closeness_delta` + `min_peak_closeness`, while hook/uppercut use `max_closeness_delta` + `max_peak_closeness`. `depth_runtime_manager.gd` now also accepts precomputed/placeholder normalized depth samples from the tracking frame so the detector can already consume staged runtime slots cleanly even though live OpenVINO/ONNX execution is still blocked. Live today: truthful runtime/debug/status propagation, shared normalized-signal consumption, and gating when placeholder/precomputed normalized depth samples are present. Still staged: actual monocular inference adapters remain blocked/unimplemented, so when no normalized depth sample is available the detector reports `staged_or_unavailable` and does **not** fake live depth gating. Validation: `godot --headless --path .testbed --quit` passes, and `godot --headless --path .testbed --script addons/aerobeat-vendor-godot-unit-test/gut_cmdln.gd -gtest=res://tests/unit/test_pose_detector_substrate.gd -gexit` finished with 81/83 passing; the two remaining failures were unrelated flow-swing tests (`test_detects_flow_swing_events_with_distinct_placement_and_direction`, `test_exposes_flow_debug_candidates_and_last_emit_metadata`).

---

### Task 4: Extend proving/debug surfaces for loader truth and swap visibility

**Bead ID:** `aerobeat-input-camera-tracking-8i6n`
**SubAgent:** `primary`
**Role:** `coder`
**References:** `REF-03`, `REF-05`, `REF-06`
**Prompt:** Update the boxing proving harness / inspector surfaces so Derrick can see the active depth artifact path, resolved backend family, load status, failure reason if any, and the currently active normalized depth metrics. Make model swaps observable and honest so changing config paths/models is easy to verify without reading code.

**Folders Created/Deleted/Modified:**
- `.testbed/scripts/`
- `.testbed/tests/`
- `.plans/mediapipe-python/`

**Files Created/Deleted/Modified:**
- `.testbed/scripts/boxing_proving_harness.gd`
- `.testbed/tests/unit/test_boxing_proving_harness_profiles_and_debug.gd`
- `.plans/mediapipe-python/2026-06-20-depth-runtime-loader-and-model-swap-seam.md`

**Status:** ✅ Complete

**Results:** Updated `.testbed/scripts/boxing_proving_harness.gd` so the boxing inspectors/event feed now surface live depth loader truth instead of stale “config only” messaging: runtime status/stage, active artifact path, resolved backend/family, failure reason, and active normalized depth metrics (including gate/source truth) all render directly from `gesture_debug.depth_runtime` + family side debug state, with truthful fallbacks when runtime state is still unresolved. Added/updated proving tests in `.testbed/tests/unit/test_boxing_proving_harness_profiles_and_debug.gd` to cover live-ready straight-punch depth runtime truth plus blocked hook/uppercut swap visibility in the event feed. Validation: `godot --headless --path .testbed --script addons/aerobeat-vendor-godot-unit-test/gut_cmdln.gd -gdir=res://tests/unit -ginclude_subdirs -gselect=test_boxing_proving_harness_profiles_and_debug.gd -gexit` (pass).

---

### Task 5: QA runtime loading and model swapping

**Bead ID:** `aerobeat-input-camera-tracking-uizc`
**SubAgent:** `primary`
**Role:** `qa`
**References:** `REF-03`, `REF-04`, `REF-05`, `REF-06`
**Prompt:** Independently verify that the shared runtime seam loads the configured depth artifact, that swapping between the approved model paths is observable and mostly painless, and that the proving/debug surfaces report truthful loader status and normalized depth metrics. Use the highest-fidelity safe validation available, including real model-path swaps where feasible.

**Folders Created/Deleted/Modified:**
- `src/`
- `.testbed/scripts/`
- `.testbed/tests/`
- `.plans/mediapipe-python/`

**Files Created/Deleted/Modified:**
- runtime / proving files touched by implementation
- `.plans/mediapipe-python/2026-06-20-depth-runtime-loader-and-model-swap-seam.md`

**Status:** ✅ Complete

**Results:** QA verified the seam with two layers of validation. (1) Real artifact-swap probe: `godot --headless --path .testbed --script /tmp/depth_runtime_qa_2026_06_20.gd` exercised the three approved depth model paths from `scripts/depth-models.yaml` / `assets/boxing.gesture_detection.yaml` and confirmed each configured artifact resolves truthfully through the shared seam: MiDaS OpenVINO directory → `backend_id=openvino`, `family_id=midas_openvino_v21_small_256`; FastDepth ONNX file → `backend_id=onnx`, `family_id=fastdepth_224_onnx`; Depth Anything V2 Small ONNX file → `backend_id=onnx`, `family_id=depth_anything_v2_small_onnx`. Repeated `ensure_runtime_ready()` calls stayed stable per artifact, swapping paths changed the reported runtime key/backend/family cleanly, and a missing-path probe failed honestly with `runtime_status=failed`, `runtime_stage=artifact_resolution`, `failure_code=artifact_missing`. (2) Detector/proving truth checks: `godot --headless --path .testbed --script addons/aerobeat-vendor-godot-unit-test/gut_cmdln.gd -gdir=res://tests/unit -ginclude_subdirs -gselect=test_pose_detector_substrate.gd -gunit_test_name=depth_gate -gexit -ghide_orphans` (pass) and `godot --headless --path .testbed --script addons/aerobeat-vendor-godot-unit-test/gut_cmdln.gd -gdir=res://tests/unit -ginclude_subdirs -gselect=test_boxing_proving_harness_profiles_and_debug.gd -gexit` (pass) confirmed the detector/debug/proving layers surface truthful staged-vs-live depth state plus normalized wrist/torso/closeness metrics. Honest QA finding: artifact loading/resolution and swap visibility are live now, but ONNX/OpenVINO execution remains intentionally staged/blocked, so the seam truthfully reports `adapter_unimplemented` while still passing through normalized placeholder/sample metrics for debug surfaces.

---

### Task 6: Audit architecture truthfulness and completion

**Bead ID:** `aerobeat-input-camera-tracking-6vmf`
**SubAgent:** `primary`
**Role:** `auditor`
**References:** `REF-01`, `REF-03`, `REF-04`, `REF-05`, `REF-06`, `REF-07`, `REF-08`
**Prompt:** Independently audit that the implementation truly centralizes model-specific logic behind a shared seam, that swapping models does not leak backend-specific branching across the detector/proving path, and that the plan and debug surfaces tell the truth about what is live versus staged.

**Folders Created/Deleted/Modified:**
- `src/`
- `.testbed/scripts/`
- `.testbed/tests/`
- `.plans/mediapipe-python/`

**Files Created/Deleted/Modified:**
- runtime / proving files touched by implementation
- `.plans/mediapipe-python/2026-06-20-depth-runtime-loader-and-model-swap-seam.md`

**Status:** ⏳ Pending

**Results:** Pending.

---

## Concrete runtime design

### 1) Shared loader/manager location in `src/`

Add a new depth-runtime cluster under the addon source tree rather than embedding depth-specific logic into the detector:

- `src/depth/depth_runtime_manager.gd`
- `src/depth/depth_model_adapter.gd`
- `src/depth/depth_runtime_types.gd` (constants / helper constructors if needed)
- staged adapters as separate files:
  - `src/depth/adapters/openvino_depth_adapter.gd`
  - `src/depth/adapters/onnx_depth_adapter.gd`
  - optionally `src/depth/adapters/blocked_depth_adapter.gd`

`pose_detector_substrate.gd` should only talk to `DepthRuntimeManager`, not to backend-specific adapters and not directly to artifact-path heuristics.

### 2) Detector-facing normalized adapter interface

The detector should consume one tiny interface shape from `DepthRuntimeManager`:

- `configure_from_family(family: String, family_depth_config: Dictionary) -> void`
- `ensure_runtime_ready() -> Dictionary`
- `infer_relative_depth(frame_payload: Dictionary, sample_request: Dictionary) -> Dictionary`
- `get_debug_state() -> Dictionary`
- `release_unused_runtime() -> void`
- `shutdown() -> void`

The adapter seam behind that manager should expose the same core lifecycle:

- `load(model_spec: Dictionary) -> Dictionary`
- `infer(frame_payload: Dictionary, request: Dictionary) -> Dictionary`
- `get_debug_state() -> Dictionary`
- `unload() -> void`

Important boundary: the detector asks for a normalized relative-depth sample, not "run MiDaS/OpenVINO" or "run ONNX."

### 3) `depth.model.artifact_path` resolution to family/backend

`depth.model.artifact_path` remains the config source of truth.

Resolution rules inside `DepthRuntimeManager`:

1. Read the family-local `depth.model.artifact_path` string from `REF-03`.
2. Resolve `res://...` to an absolute filesystem path with `ProjectSettings.globalize_path(...)`.
3. Normalize the path into a `model_spec` dictionary:
   - `artifact_path_res`
   - `artifact_path_abs`
   - `artifact_exists`
   - `artifact_kind` = `directory` or `file`
   - `family_id` = inferred from known approved paths in `REF-06`
   - `backend_id` = inferred from artifact shape/path today
   - `loader_key` = `[backend_id]:[family_id]`
4. Use deterministic inference first:
   - directory containing `*.xml` + `*.bin` pair -> `backend_id = openvino`, `family_id = midas_openvino_v21_small_256`
   - `.onnx` file under approved FastDepth path -> `backend_id = onnx`, `family_id = fastdepth_224_onnx`
   - `.onnx` file under approved Depth Anything V2 Small path -> `backend_id = onnx`, `family_id = depth_anything_v2_small_onnx`
5. If an artifact path is unknown but still clearly shaped like a supported format, keep `backend_id` inference but set `family_id = custom` and surface that in debug.
6. Only add explicit `depth.model.family` or `depth.model.backend` config fields later if artifact-path inference becomes ambiguous in real usage. They are not required for the first seam.

This keeps model selection a data concern and prevents punch-family logic from caring about file extensions or vendor naming.

### 4) Load / unload / caching lifecycle

`DepthRuntimeManager` should own a per-artifact cache keyed by resolved absolute artifact path plus input size / backend options.

Lifecycle:

- on family config change or first use, build a `runtime_key`
- if the active key matches and the runtime is loaded, reuse it
- if the key differs, unload the old adapter and load the new one
- if multiple families point at the same artifact path, share one loaded runtime instance
- if all depth-enabled families are disabled or inactive, allow explicit `shutdown()` to release subprocess/resources

First realistic implementation target:

- one active loaded depth runtime at a time for boxing is sufficient
- caching can still use a dictionary, but eviction can be simple: keep current, unload previous

Truthful staging:

- do not claim hot multi-runtime pooling until a real need exists
- do not preload all three depth models by default on startup
- do not instantiate a runtime merely because the YAML contains an artifact path while `depth.enabled` is false

### 5) Normalized output contract for detector use

The detector should receive a normalized output dictionary shaped around **relative** depth, not metric distance:

```gdscript
{
  "ok": true,
  "status": "ready",
  "backend_id": "openvino",
  "family_id": "midas_openvino_v21_small_256",
  "artifact_path": "res://...",
  "frame_size": Vector2i(...),
  "depth_map_size": Vector2i(...),
  "depth_orientation": "larger_is_farther",
  "normalized_depth_map": Image, # or staged equivalent transport object
  "sample_metrics": {
    "wrist_depth": 0.41,
    "torso_depth": 0.55,
    "wrist_closeness": 0.14,
    "roi_valid": true
  },
  "timing_ms": {
    "preprocess": 0.0,
    "infer": 0.0,
    "postprocess": 0.0,
    "total": 0.0
  },
  "error_info": {}
}
```

Normalized detector contract rules:

- adapters must sign-normalize so the manager exports one invariant: `wrist_closeness = torso_depth - wrist_depth`, where larger means wrist is closer to camera than torso
- output values are relative / scene-normalized only, never implied metric meters
- ROI sampling details live in shared helpers or manager code, not in punch-family-specific branches
- if the initial implementation cannot cheaply move full depth maps back into Godot, the first live interface can instead return ROI-sampled normalized metrics plus adapter metadata. That is acceptable as long as the contract stays the same at the detector boundary: detector consumes normalized `wrist_depth`, `torso_depth`, `wrist_closeness`, and window-analysis inputs, not backend-native tensors

### 6) Failure/debug state contract for proving surfaces

`get_debug_state()` from the manager should be rich enough for `boxing_proving_harness.gd` to tell the truth without reading code.

Required debug fields:

- `configured`: bool
- `depth_enabled`: bool
- `artifact_path_res`: string
- `artifact_path_abs`: string
- `artifact_exists`: bool
- `artifact_kind`: `directory` / `file` / `missing`
- `family_id`: inferred model family
- `backend_id`: `openvino` / `onnx` / `unknown`
- `runtime_status`: `disabled`, `ready`, `blocked`, `loading`, `failed`, `unloaded`
- `runtime_stage`: `artifact_resolution`, `dependency_check`, `adapter_load`, `inference`, `sampling`
- `failure_code`: short stable code such as `artifact_missing`, `backend_not_installed`, `adapter_unimplemented`, `infer_failed`
- `failure_message`: human-readable reason
- `active_model_summary`: one-line truth string for inspector rows
- `last_timing_ms`
- `last_sample_metrics`

That lets the proving surface replace the current config-only status text with something honest like:

- `disabled in config`
- `enabled; artifact resolved to MiDaS/OpenVINO but backend not installed yet`
- `enabled; runtime ready via onnx backend`
- `enabled; last inference failed: infer_failed`

### 7) Keep model-specific branching out of punch-family logic

The punch-family threshold code should stay responsible only for family semantics:

- straight uses depth as a positive forward confirmation
- hook uses depth as a non-forward veto
- uppercut uses depth as a non-forward veto

It should **not** branch on:

- MiDaS vs FastDepth vs Depth Anything
- OpenVINO vs ONNX
- `.xml/.bin` vs `.onnx`
- backend-specific preprocessing details
- output polarity differences

Those differences belong in:

- artifact resolution helpers
- backend adapters
- shared normalization helpers
- shared ROI sampling helpers

A good implementation smell test: the family-level methods in `pose_detector_substrate.gd` should never need `if backend_id == ...`.

### 8) Current runtime-support truth audit

- `src/detectors/pose_detector_substrate.gd` currently has no monocular-depth loader, no ONNX runtime hook, and no OpenVINO runtime hook. Its current `forward_depth_spike` logic is still landmark-`z`-derived state from the tracked wrist history.
- `.testbed/scripts/boxing_proving_harness.gd` currently surfaces the YAML `depth:` contract as config-only and does not report a live depth backend.
- `scripts/depth-models.yaml` defines approved artifact locations and provenance, but it is metadata only; it is not itself a runtime registry/loader.
- The only already-integrated cross-language inference substrate available to this addon today is the sibling MediaPipe Python subprocess lane referenced by the proving harness.
- That Python lane currently declares only `mediapipe`, `opencv-python`, and `numpy` in `aerobeat-vendor-mediapipe-python/runtime/requirements.txt`, so neither ONNX nor OpenVINO execution is present there yet.

### 9) What can realistically be live first vs staged/blocked

#### Live first, realistically

1. `DepthRuntimeManager` class and adapter seam in `src/depth/`
2. artifact-path resolution from `depth.model.artifact_path`
3. approved-path family/backend inference from `scripts/depth-models.yaml`-aligned shapes
4. truthful debug state surfaced into the proving harness
5. detector integration that consumes a normalized depth-result contract when available and otherwise cleanly falls back / reports blocked state

#### Staged or blocked today

1. **Actual OpenVINO execution path**: not currently implemented in this repo or the sibling Python runtime; would require a real runtime lane and dependency packaging
2. **Actual ONNX execution path**: same story; no current `onnxruntime` substrate is present
3. **Claiming all three models are swappable at runtime today**: blocked until at least one actual depth backend exists
4. **Performance/truth claims on Surface Pro 8 class hardware**: blocked until real inference timings exist under the chosen backend

#### Most realistic first real backend

The best first real execution route is to extend the already-existing Python subprocess runtime lane from `REF-07` with a dedicated depth entrypoint or depth mode, because that substrate already exists and is already launched from Godot. That does **not** mean OpenVINO or ONNX support exists today. It only means the process boundary, Python environment ownership, and Godot↔Python integration seam already exist. Actual depth backend support would still need to be added deliberately to that lane.

---

## Implementation guidance for the next slice

- Task 2 should land the manager + artifact resolver + debug contract first, even if adapters return `adapter_unimplemented`.
- If the coder chooses to use the existing Python vendor runtime seam, the new depth runtime should still be isolated behind its own manager/adapter API so detector code does not care whether inference happens in-process, out-of-process, via ONNX, or via OpenVINO.
- The first detector integration should replace the current fake `forward_depth_spike` naming/story only when real normalized depth samples actually exist. Until then, debug must distinguish landmark-Z-derived values from monocular-depth-derived values.

---

## Final Results

**Status:** ⚠️ Partial

**What We Built:** Updated the active plan with the concrete shared-depth-runtime design, then implemented Task 2’s repo-side seam: artifact-path resolution, backend/family inference, normalized detector/debug contracts, and truthful blocked adapter states for the currently unwired OpenVINO/ONNX execution paths.

**Reference Check:** `REF-01`/`REF-03`/`REF-06` confirm the approved family-local depth config and artifact paths; `REF-04`/`REF-05` confirm the current detector/proving surfaces still do not run monocular depth; `REF-07`/`REF-08` confirm the only existing execution substrate already wired here is the MediaPipe Python subprocess lane and that it currently lacks ONNX/OpenVINO dependencies.

**Commits:**
- Pending.

**Lessons Learned:** The repo is ready for a clean seam, but not for honest claims of real model swapping yet. The right next step is to centralize resolution/debug first, then add a real backend behind that seam instead of leaking backend assumptions into boxing threshold code.
