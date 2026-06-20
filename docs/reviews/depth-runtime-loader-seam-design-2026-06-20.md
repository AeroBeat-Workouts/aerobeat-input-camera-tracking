# Depth runtime loader seam design

**Date:** 2026-06-20
**Status:** Proposed

## Goal

Define one shared runtime seam that can load approved monocular depth artifacts from `depth.model.artifact_path`, normalize them into one detector-facing contract, and keep boxing threshold logic backend-agnostic.

## Current-state truth

- `assets/boxing.gesture_detection.yaml` already carries per-family staged depth config under `straight_punch.threshold.depth`, `hook.threshold.depth`, and `uppercut.threshold.depth`, including `depth.model.artifact_path`.
- `scripts/depth-models.yaml` already records three approved artifact shapes:
  - MiDaS OpenVINO directory pair (`.xml` + `.bin`)
  - FastDepth ONNX file
  - Depth Anything V2 Small ONNX file
- `.testbed/scripts/boxing_proving_harness.gd` currently surfaces that config honestly as staged-only and explicitly says live threshold runtime does not consume depth yet.
- `src/detectors/pose_detector_substrate.gd` still owns all punch-family threshold logic and currently has no real depth-runtime adapter seam.
- The repo has no current OpenVINO or ONNX execution substrate inside `src/`, so Task 1 must stay architecture-truthful and should not pretend all backends are runnable yet.

## Recommended file layout in `src/`

Create a dedicated `src/depth/` namespace so depth loading does not leak into `src/detectors/`:

- `src/depth/depth_runtime_manager.gd`
  - main seam owner used by `pose_detector_substrate.gd`
  - owns config extraction, artifact resolution, adapter selection, cache/reload lifecycle, and normalized debug state
- `src/depth/depth_runtime_contract.gd`
  - shared constants / helper builders for normalized state dictionaries
  - avoids repeating debug/failure/status key names across adapters
- `src/depth/depth_runtime_resolver.gd`
  - resolves `artifact_path`, infers runtime family/backend, validates artifact shape, and returns a normalized runtime spec
- `src/depth/depth_frame_types.gd`
  - helper builders for normalized per-frame outputs, ROI summaries, and window-analysis payloads
- `src/depth/adapters/depth_model_adapter.gd`
  - abstract adapter contract / base class
- `src/depth/adapters/openvino_depth_adapter.gd`
  - MiDaS-first adapter path for directory-backed `.xml` + `.bin` artifacts
- `src/depth/adapters/onnx_depth_adapter.gd`
  - generic ONNX adapter path for FastDepth and Depth Anything V2 Small
- `src/depth/adapters/unavailable_depth_adapter.gd`
  - truthful placeholder adapter used when runtime family is recognized but execution support is not landed yet

This keeps detector logic dependent on one manager object instead of knowing about file suffixes, runtime families, or backend-specific error cases.

## Normalized detector-facing interface

`pose_detector_substrate.gd` should consume one manager method only:

- `evaluate_frame(frame_context: Dictionary) -> Dictionary`

Recommended returned shape:

```gdscript
{
  "ok": true,
  "status": "ready", # disabled | missing_config | loading | ready | failed | unsupported
  "family": "midas_v21_small",
  "runtime_backend": "openvino", # openvino | onnx | unavailable
  "artifact_path": "res://addons/...",
  "resolved_path": "res://addons/...",
  "cache_key": "openvino|midas_v21_small|res://addons/...|256",
  "input_size": 256,
  "timestamp_ms": 123456,
  "depth_map": {
    "width": 256,
    "height": 256,
    "values": PackedFloat32Array(),
    "normalization": "relative_inverse_depth_0_1",
  },
  "signal": {
    "left": {
      "wrist_depth": 0.41,
      "torso_depth": 0.57,
      "wrist_closeness": 0.16,
      "roi_valid": true,
    },
    "right": {
      "wrist_depth": 0.39,
      "torso_depth": 0.55,
      "wrist_closeness": 0.16,
      "roi_valid": true,
    },
  },
  "debug": {
    "load_state": "ready",
    "reload_reason": "artifact_changed",
    "model_declared_family": "",
    "model_inferred_family": "midas_v21_small",
    "adapter_name": "OpenVinoDepthAdapter",
    "artifact_shape": "openvino_directory_pair",
    "source_frame_size": Vector2i(1280, 720),
    "roi_summary": {},
    "window_analysis": {},
    "failure_code": "",
    "failure_detail": "",
  }
}
```

Important detector contract:
- detector code should only read normalized fields such as:
  - `status`
  - `signal.left/right.wrist_closeness`
  - `debug.window_analysis`
  - `debug.failure_code`
- detector code should never branch on `.xml`, `.onnx`, `OpenVINO`, `FastDepth`, or `Depth Anything` directly.

## Artifact-path resolution plan

Use the existing learned-classifier pattern as the baseline: accept `res://`, `user://`, absolute paths, and addon-relative paths.

Recommended resolver steps:

1. Read `family.threshold.depth.model.artifact_path`.
2. Normalize blank/missing path to `missing_config`.
3. Resolve path rules:
   - `res://...` -> keep as-is
   - `user://...` -> keep as-is
   - absolute filesystem path -> keep as-is
   - addon-relative path -> prefix with addon root (`res://addons/aerobeat-input-camera-tracking/...`)
4. Validate artifact shape:
   - if path ends in `.onnx`, treat as single-file ONNX candidate
   - if path is a directory, look for one `.xml` plus one matching `.bin` for OpenVINO
   - if path ends in `.xml`, infer paired `.bin` sibling
5. Build a normalized runtime spec:

```gdscript
{
  "ok": true,
  "artifact_path": original_path,
  "resolved_path": resolved_path,
  "artifact_kind": "directory" | "file",
  "artifact_shape": "openvino_directory_pair" | "openvino_xml_file" | "onnx_file" | "unknown",
  "runtime_backend": "openvino" | "onnx" | "unknown",
  "model_family": "midas_v21_small" | "fastdepth_224" | "depth_anything_v2_small" | "custom_unknown",
  "family_source": "declared" | "inferred",
  "validation_error": "",
}
```

The manager should cache by normalized runtime spec rather than just raw path string.

## Model-family inference vs explicit declaration

Recommendation: **support optional explicit declaration, but keep inference as the default first path.**

Suggested future config shape:

```yaml
depth:
  model:
    artifact_path: res://addons/...
    family: "" # optional override
```

Behavior:
- if `family` is present and non-empty, trust it after a compatibility check with artifact shape
- if `family` is empty, infer from artifact shape/path patterns

Why this recommendation fits current repo state:
- the approved artifacts are tightly named and easy to infer today
- forcing a new config field immediately would create churn before runtime exists
- keeping an optional override gives a clean escape hatch for future custom exports whose filenames are ambiguous

Inference rules for the approved set:
- path containing `openvino_midas_v21_small_256` -> `midas_v21_small`
- path containing `fastdepth` and ending `.onnx` -> `fastdepth_224`
- path containing `depth_anything_v2_small` and ending `.onnx` -> `depth_anything_v2_small`
- otherwise -> `custom_unknown`

If explicit `family` conflicts with detected artifact shape, fail fast and surface `family_shape_mismatch`.

## Load / unload / caching lifecycle

Use one manager instance owned by `pose_detector_substrate.gd`.

Recommended lifecycle:

1. Detector asks manager for the active family runtime config during config refresh / startup.
2. Manager resolves per-family depth specs once and computes a `cache_key` from:
   - backend
   - model family
   - resolved artifact path
   - input size
3. Manager lazily loads an adapter only when a depth-enabled family actually needs evaluation.
4. Manager keeps adapter instances cached by `cache_key` so straight/hook/uppercut can share the same runtime when they point to the same artifact.
5. If config path / family / input size changes, manager:
   - decrements or evicts the old cache entry
   - calls `unload()` on orphaned adapters
   - marks `reload_reason`
6. On detector teardown or config rebuild, manager unloads all cached adapters.

Important ownership rule:
- **manager owns adapter objects**
- punch-family state machines only own family-local time-window scoring histories
- family logic must not own model handles

Recommended cache shape:

```gdscript
{
  "cache_key": {
    "adapter": adapter,
    "ref_count": 2,
    "load_state": "ready",
    "last_used_ms": 123,
    "runtime_spec": {},
  }
}
```

## Debug-state and failure-state design

Proving surfaces need enough truth to answer:
- what family requested depth?
- what artifact did it resolve to?
- what backend was selected?
- did it actually load?
- if not, why not?
- which adapter handled it?
- which model swap caused a reload?

Recommended normalized debug/load state keys:

```gdscript
{
  "depth_runtime": {
    "status": "disabled|missing_config|loading|ready|failed|unsupported",
    "family": "midas_v21_small",
    "runtime_backend": "openvino",
    "artifact_path": "res://...",
    "resolved_path": "res://...",
    "artifact_shape": "openvino_directory_pair",
    "cache_key": "...",
    "adapter_name": "OpenVinoDepthAdapter",
    "load_state": "ready",
    "failure_code": "",
    "failure_detail": "",
    "reload_reason": "artifact_changed",
    "supports_live_inference": true,
    "window_analysis": {},
    "last_infer_ms": 0,
  }
}
```

Recommended failure codes:
- `depth_disabled`
- `depth_config_missing`
- `artifact_missing`
- `artifact_shape_unknown`
- `family_shape_mismatch`
- `backend_unavailable`
- `adapter_load_failed`
- `infer_failed`
- `roi_invalid`
- `window_not_ready`

Truthfulness rule:
- if ONNX runtime is not implemented yet, status should be `unsupported` or `failed` with `backend_unavailable`; never pretend the swap succeeded just because the path resolved.

## OpenVINO-vs-ONNX branching plan

Branching belongs in the resolver/manager layer only.

Recommended flow:

1. Resolver classifies artifact as OpenVINO or ONNX.
2. Manager chooses adapter:
   - OpenVINO artifact -> `OpenVinoDepthAdapter`
   - ONNX artifact -> `OnnxDepthAdapter`
   - recognized-but-not-implemented backend -> `UnavailableDepthAdapter`
3. Adapter returns the same normalized per-frame payload shape.
4. Detector reads normalized `signal` + `debug`, not adapter identity.

This keeps boxing logic backend-agnostic because the only backend branch is:
- **before** runtime loads
- **outside** punch-family scoring

Detector-family logic should only perform:
- window accumulation of `wrist_closeness`
- early/late slice comparisons
- threshold checks from family config

It should not perform:
- backend-specific preprocessing
- model-family-specific normalization
- backend-specific path parsing
- backend-specific failure handling beyond generic `status` / `failure_code`

## Recommended implementation slice ordering

### Slice 1 — resolver + manager seam only
- add `src/depth/` skeleton
- extract runtime config from gesture profile
- resolve artifact path / backend / family / cache key
- return truthful staged debug state even before live inference exists

Why first:
- unlocks proving-surface truth immediately
- keeps later runtime work from being wired ad hoc into the detector

### Slice 2 — detector integration for config and status only
- instantiate manager in `pose_detector_substrate.gd`
- family debug state exposes resolved depth runtime status
- no live inference yet

Why second:
- proves seam placement without taking dependency on external inference runtime

### Slice 3 — MiDaS OpenVINO runnable adapter
- land first real adapter for the only officially sourced/runtime-shaped artifact in current metadata
- keep ONNX adapters truthful stubs if runtime support is still absent

Why third:
- MiDaS OpenVINO is the most concrete first supported path from current repo truth

### Slice 4 — normalized ROI sampling + window metrics
- produce `wrist_depth`, `torso_depth`, `wrist_closeness`, `closeness_delta`, `peak_closeness`
- integrate family threshold gating through the normalized contract

### Slice 5 — ONNX runtime path
- land generic ONNX execution substrate once a real runtime choice exists
- enable FastDepth and Depth Anything V2 Small through the same manager path

### Slice 6 — proving-harness upgrade
- surface artifact path, backend, family, load/failure state, live signal, and reload reason

## Main risks

### 1. Runtime substrate gap
The repo currently has no in-tree OpenVINO or ONNX execution substrate, so the first implementation must avoid over-promising parity.

### 2. False symmetry risk
FastDepth and Depth Anything V2 Small share `.onnx`, but may still need different preprocessing/normalization later. Keep one ONNX adapter seam, but allow family-specific normalizers behind it if reality demands.

### 3. Detector leakage risk
If `pose_detector_substrate.gd` starts branching on model family directly, the seam has failed.

### 4. Shared-cache invalidation risk
Multiple punch families may point at the same artifact. Reference counting or central cache ownership is required to avoid duplicate loads or accidental unloads.

### 5. Debug honesty risk
The proving harness currently tells the truth. Any future implementation must keep that honesty and never collapse `resolved path exists` into `runtime works`.

## Short recommendation

- Put the loader seam in `src/depth/`, not `src/detectors/`.
- Make `DepthRuntimeManager` the only detector dependency.
- Infer model family by default from `artifact_path`, but allow optional explicit `depth.model.family` later.
- Cache by normalized runtime spec so shared artifacts load once.
- Treat MiDaS OpenVINO as the first runnable path.
- Keep ONNX truthfully staged until an actual runtime substrate exists.
- Surface all load/failure/swap state through normalized debug dictionaries so proving scenes can verify model swaps without reading code.
