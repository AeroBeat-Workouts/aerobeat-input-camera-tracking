# Camera Tracking Contract Boundary Memo

**Date:** 2026-06-01
**Status:** Stale
**Author:** OpenClaw subagent (`research`)
**Inputs Reviewed:**
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-tool-camera-tracking`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-vendor-mediapipe-python`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.plans/2026-06-01-camera-tracking-audit-report.md`

---

## Bottom line

The clean boundary should be:

- **`aerobeat-input-camera-tracking`** owns **gameplay interpretation only**: Boxing/Flow detectors, tracking-frame adaptation into legacy detector shape, input-facing session metadata, and consumer-facing signals built from the normalized tool contract.
- **`aerobeat-tool-camera-tracking`** owns the **public camera-tracking contract**: lifecycle/state machine, backend registration/resolution, preview attachment semantics, camera/source config shape, normalized frame payload, and the single service API consumers call.
- **`aerobeat-vendor-mediapipe-python`** owns **all MediaPipe/Python/runtime specifics**: backend implementation, runtime bridge, subprocess/session orchestration, vendor config translation, camera enumeration, runtime health, raw vendor-frame capture, and model/runtime preparation.

If we enforce that split strictly, then **`aerobeat-input-camera-tracking` must stop knowing what MediaPipe is**. It should know only:

1. a `CameraTracking` service exists,
2. what config/state/frame contract that service exposes,
3. how to attach/detach preview surfaces through that service when needed,
4. how to interpret normalized frames into gameplay events.

---

## Contract boundary by repo

## 1) `aerobeat-input-camera-tracking` responsibilities

This repo should own only product/input concerns:

- Boxing + Flow detector logic
- landmark smoothing and local detector substrate
- adaptation from normalized `CameraTracking` frame payloads into the landmark shape expected by existing detector code
- consumer-facing input adapter behavior for AeroBeat/input-core compatibility
- scene/node wiring that consumes an already-available `CameraTracking` session
- session metadata publication to input-core if that remains required
- replay/playback UI state only if it can be derived from the tool contract without direct transport/process access

This repo should **not** own or directly perform:

- MediaPipe backend selection logic
- vendor backend registration closures
- runtime bridge construction
- Python entrypoint discovery
- runtime prep/install hints
- model path resolution
- subprocess launch/kill/pid/group management
- localhost UDP/TCP/HTTP transport
- direct vendor repo script loads
- direct ffprobe/runtime probing unless that probe is elevated into tool/vendor ownership

### Input repo files that remain conceptually in-bounds

These are aligned or close to aligned with the clean contract split:

- `src/providers/camera_tracking_provider.gd`
- `src/tracking_frame_adapter.gd`
- `src/detectors/landmark_smoother.gd`
- `src/detectors/pose_detector_substrate.gd`
- `src/detectors/pose_landmark_ids.gd`
- `src/detectors/pose_metrics.gd`
- `src/config/mediapipe_config.gd` **only if renamed/reframed as product-facing camera-tracking config rather than MediaPipe-specific config**

## 2) `aerobeat-tool-camera-tracking` responsibilities

This repo should be the only public contract consumers depend on.

It should own:

- `CameraTracking` singleton/service contract
- backend registration/resolution policy by backend id
- public lifecycle methods: start/stop/change/list/query
- public state/detail semantics
- preview attachment ownership model
- public camera/source config shape
- normalized tracking-frame payload shape
- public replay/live source coordination semantics
- public playback status contract if replay is supported
- any tool-level helper APIs needed so consumers never instantiate vendor objects directly

This repo should **not** own:

- MediaPipe implementation details
- Python runtime/session management details
- model prep/install behavior
- vendor-specific raw payload schema beyond what is normalized into the public frame

### Required new or strengthened tool-side seam

The main missing boundary is a **tool-owned composition/registration seam** that lets the vendor package register `mediapipe_python` without the input repo loading vendor scripts directly.

At minimum, one of these must become the approved pattern:

- vendor repo self-registers its backend factory when mounted, or
- tool repo exposes an explicit `register_backend_factory` entrypoint that the vendor repo calls from its own package, or
- tool repo exposes a higher-level `ensure_backend_available("mediapipe_python")` contract whose implementation stays outside the input repo.

The key rule is: **input must not create `MediaPipePythonCameraTrackingBackend` or `MediaPipePythonRuntimeBridge` itself.**

## 3) `aerobeat-vendor-mediapipe-python` responsibilities

This repo should own everything specific to the MediaPipe Python lane:

- `MediaPipePythonCameraTrackingBackend.gd`
- `MediaPipePythonRuntimeBridge.gd`
- `MediaPipePythonConfig.gd`
- `MediaPipePythonCameraInventory.gd`
- `MediaPipePythonRuntimeHealth.gd`
- `MediaPipePythonFrameMapper.gd`
- `runtime/mediapipe_runtime_probe.py`
- `runtime/requirements.txt`
- `models/*.task`
- `scripts/prepare_vendor_runtime.py`

It should also remain the home for:

- runtime bootstrap/reconfigure/shutdown behavior
- process/session file ownership
- camera enumeration against vendor/runtime reality
- runtime health/error reporting
- vendor-source-specific replay/live source rules
- vendor-specific environment/model path rules
- any direct Python/MediaPipe/OpenCV imports or diagnostics

---

## Exact input-repo files that must stop direct vendor/runtime/transport/process work

These are the exact files in `aerobeat-input-camera-tracking` that violate the clean break and should stop doing that work.

### A. Direct vendor composition / vendor awareness

1. `src/input_provider.gd`
   - must stop loading:
     - `res://addons/aerobeat-vendor-mediapipe-python/src/MediaPipePythonCameraTrackingBackend.gd`
     - `res://addons/aerobeat-vendor-mediapipe-python/src/MediaPipePythonRuntimeBridge.gd`
   - must stop requiring vendor script existence in `_contract_lane_available()`
   - must stop creating backend/runtime instances in `_ensure_local_tracking_session()`
   - should only discover/use a `CameraTracking` session or fall back via an explicitly temporary migration seam

2. `src/AeroCameraTracking.gd`
   - must stop loading vendor backend/runtime scripts
   - must stop registering the `mediapipe_python` backend factory locally
   - must stop acting as the vendor composition root
   - should consume a ready `CameraTracking` service and re-emit product signals only

### B. Direct runtime/process ownership

3. `src/providers/mediapipe_provider.gd`
   - legacy direct runtime path; should be retired from the sharable contract lane

4. `src/process/mediapipe_process.gd`
   - direct sidecar launch/heartbeat/import checks tied to `python_mediapipe`
   - ownership belongs in vendor repo, not input repo

5. `src/process/desktop_sidecar_launcher.gd`
   - direct detached process launch/kill/group management
   - if still needed for desktop runtime behavior, it belongs under vendor runtime ownership or a deeper shared ops/runtime utility, not input

6. `src/autostart_manager.gd`
   - direct process lifecycle, `pkill`, runtime import checks, model checks, and sidecar startup
   - should be removed from input-layer ownership

7. `src/runtime/desktop_sidecar_runtime.gd`
   - direct `python_mediapipe` path discovery, asset/runtime/model ownership, and prep hints
   - belongs entirely outside input

### C. Direct transport ownership

8. `src/server/mediapipe_server.gd`
   - direct UDP server ownership; should not remain in input

9. `src/strategies/strategy_mediapipe.gd`
   - direct UDP listener ownership; should not remain in input

10. `src/camera_view.gd`
   - direct TCP/localhost preview transport ownership; should not remain in input
   - if preview is needed, input should attach a surface to the tool service and let tool/vendor own the preview transport path

11. `src/AeroMediaPipeReplayPlaybackBackend.gd`
   - direct HTTP replay transport ownership; should not remain in input
   - replay backend/transport must be exposed through tool contract instead

12. `src/mediapipe_input_with_camera.gd`
   - direct legacy composition wrapper around `MediaPipeProvider` + `camera_view`
   - should not remain the active contract path

### D. Direct out-of-band probe work

13. `src/AeroCameraTracking.gd`
   - the `ffprobe` duration probe is also a boundary violation
   - replay metadata probing should move to tool contract ownership or vendor/runtime ownership so input only consumes playback facts

---

## Migration targets in dependency order

This is the implementation order that keeps the break clean and minimizes thrash.

### 1. Lock the public tool contract first

**Target repo:** `aerobeat-tool-camera-tracking`

Define or finalize the public contract that input is allowed to depend on:

- backend registration story
- session discovery/creation story
- lifecycle API
- preview API
- replay/live source config shape
- playback status/query API
- normalized frame shape
- camera inventory/state/error semantics

**Why first:** input cannot become vendor-agnostic until the tool contract fully covers the behavior it currently reaches around.

### 2. Move vendor registration/composition fully out of input

**Target repo:** mostly `aerobeat-vendor-mediapipe-python`, possibly small seam additions in `aerobeat-tool-camera-tracking`

Deliver a mounting/registration pattern where the vendor package wires `mediapipe_python` into the tool contract without any input-repo vendor loads.

**Required outcome:** `input_provider.gd` and `AeroCameraTracking.gd` no longer instantiate vendor backend/runtime classes.

### 3. Promote replay and preview facts into the tool contract

**Target repo:** `aerobeat-tool-camera-tracking` contract, implemented by `aerobeat-vendor-mediapipe-python`

Move these concepts behind the public service seam:

- preview descriptor ownership
- playback status/duration/current-time facts
- replay source handling
- any needed replay metadata probe

**Required outcome:** input no longer talks TCP/HTTP/ffprobe for preview/replay.

### 4. Move all subprocess/runtime ownership into vendor repo

**Target repo:** `aerobeat-vendor-mediapipe-python`

Everything tied to Python runtime/session management should land here or be called from here:

- sidecar launch/reconfigure/stop
- pid/group kill logic
- heartbeat/session files
- runtime import checks
- model existence checks
- prepare/install hints
- local runtime path resolution

**Required outcome:** input no longer owns `mediapipe_process`, `desktop_sidecar_launcher`, `autostart_manager`, or `desktop_sidecar_runtime` behavior.

### 5. Remove direct transport surfaces from input

**Target repo:** replace with tool/vendor-owned equivalents or retire outright

Retire input-side UDP/TCP/HTTP transport files:

- `server/mediapipe_server.gd`
- `strategies/strategy_mediapipe.gd`
- `camera_view.gd`
- `AeroMediaPipeReplayPlaybackBackend.gd`
- `mediapipe_input_with_camera.gd`

**Required outcome:** the only preview/tracking path visible to input is the `CameraTracking` API.

### 6. Collapse input onto the contract-only provider path

**Target repo:** `aerobeat-input-camera-tracking`

Once the tool/vendor layers cover the missing seams, simplify input to:

- `input_provider.gd` as input-core adapter/session metadata publisher
- `AeroCameraTracking.gd` as optional product-facing facade that consumes tool contract only
- `camera_tracking_provider.gd` + detector files as the gameplay interpretation path
- `tracking_frame_adapter.gd` as the shape bridge

**Required outcome:** the legacy MediaPipe provider path becomes removable or clearly archived.

### 7. Rename product-facing config away from vendor naming

**Target repo:** `aerobeat-input-camera-tracking` after the above seams are stable

`src/config/mediapipe_config.gd` still leaks vendor naming into the product layer. After the contract is stable, it should become a product-facing camera-tracking config object or adapter, not a MediaPipe-branded config surface.

**Why last:** this is cleanup after the behavioral boundary is fixed.

---

## Recommended steady-state architecture

### Input repo should depend on these tool-facing facts only

- `CameraTracking` lifecycle methods
- `CameraTracking` signals
- `CameraTracking` camera enumeration
- `CameraTracking` preview attach/detach methods
- normalized tracking frame payload
- public playback/replay status payload if replay remains supported

### Input repo should never again depend on

- `MediaPipePython*` classes
- `python_mediapipe/*`
- localhost ports/URLs/protocols
- subprocess ids or kill commands
- runtime requirements/model paths
- MediaPipe/OpenCV import success

---

## File-level end state for the input repo

### Keep and evolve

- `src/providers/camera_tracking_provider.gd`
- `src/tracking_frame_adapter.gd`
- `src/detectors/*`
- `src/input_provider.gd` (contract-only adapter)
- `src/AeroCameraTracking.gd` (contract-only facade, if still needed)
- `src/config/mediapipe_config.gd` only as an interim compatibility wrapper

### Remove, retire, or quarantine from the sharable runtime lane

- `src/providers/mediapipe_provider.gd`
- `src/process/mediapipe_process.gd`
- `src/process/desktop_sidecar_launcher.gd`
- `src/autostart_manager.gd`
- `src/runtime/desktop_sidecar_runtime.gd`
- `src/server/mediapipe_server.gd`
- `src/strategies/strategy_mediapipe.gd`
- `src/camera_view.gd`
- `src/AeroMediaPipeReplayPlaybackBackend.gd`
- `src/mediapipe_input_with_camera.gd`

---

## Decision rule for future changes

When touching camera tracking, use this rule:

- If the change is about **gameplay meaning** of landmarks/frames, it belongs in **input**.
- If the change is about **public camera service behavior**, it belongs in **tool**.
- If the change is about **MediaPipe/Python/runtime/process/model/vendor behavior**, it belongs in **vendor**.

That rule matches the current tool/vendor repo design and is the cleanest path to making `aerobeat-input-camera-tracking` genuinely MediaPipe-agnostic.
