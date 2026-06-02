# Camera Tracking Layering Audit

**Date:** 2026-06-01
**Auditor:** OpenClaw subagent (`auditor`)
**Repos Audited:**
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-tool-camera-tracking`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-vendor-mediapipe-python`

---

## Verdict

**FAIL**

- `aerobeat-input-camera-tracking/src` does **not** use `aerobeat-tool-camera-tracking` for all camera-tracking interactions.
- The input repo still contains multiple direct/runtime-owned camera paths, including direct process launch, direct UDP/TCP/HTTP IPC, direct file/path dependencies on `python_mediapipe`, and direct loading of vendor backend/runtime classes.
- `aerobeat-tool-camera-tracking` itself is **properly vendor-agnostic in `src/`** and relies on backend registration/factory seams rather than direct vendor imports.
- `aerobeat-vendor-mediapipe-python` does appear to be the intended vendor repo, and its Python sidecar is repo-root owned (`runtime/`, `models/`, `.venv`, `scripts/prepare_vendor_runtime.py`), but the consumer/input repo still bypasses that layering in several places.

---

## Scope Questions Answered

### 1) Does `/src` in `aerobeat-input-camera-tracking` use `aerobeat-tool-camera-tracking` for all camera-tracking interactions?

**No.**

It has a partial migration path through:
- `src/providers/camera_tracking_provider.gd`
- `src/input_provider.gd` (preferred lane)
- `src/AeroCameraTracking.gd` (contract-facing facade)

But it still contains many direct/bypass camera paths in `src/`:
- direct vendor script loading from `aerobeat-vendor-mediapipe-python`
- direct legacy Python sidecar launch paths under local `python_mediapipe`
- direct UDP server/client paths
- direct TCP/HTTP preview/replay paths to `127.0.0.1`
- direct runtime/path assumptions for local sidecar assets and runtimes

### 2) Does `aerobeat-tool-camera-tracking` rely on `aerobeat-vendor-mediapipe-python` as the vendor repo, with the Python sidecar at the vendor repo root?

**Yes, with an important nuance:**

- `aerobeat-tool-camera-tracking/src` is vendor-agnostic and does **not** directly import the vendor repo.
- The intended integration seam is backend registration/factory creation (`CameraTrackingBackendRegistry` / `CameraTracking.register_backend_factory(...)`).
- The actual MediaPipe vendor implementation lives in `aerobeat-vendor-mediapipe-python`.
- In that vendor repo, the Python sidecar is repo-root owned:
  - `runtime/mediapipe_runtime_probe.py`
  - `runtime/requirements.txt`
  - `models/pose_landmarker_lite.task`
  - `.venv/`
  - `scripts/prepare_vendor_runtime.py`
- The vendor bridge resolves relative paths against its own repo root via `_repo_root_path()` and defaults to `runtime/mediapipe_runtime_probe.py`.

### 3) Are there layering violations / bypasses?

**Yes. Multiple.**

Primary violations:
1. **Direct vendor imports from the input repo** instead of tool-only contract usage.
2. **Legacy local sidecar ownership in the input repo** via `python_mediapipe` runtime/process code.
3. **Direct IPC/network paths in the input repo** (`PacketPeerUDP`, `StreamPeerTCP`, `HTTPClient`, localhost URLs/ports).
4. **Direct process management in the input repo** (`OS.execute`, `OS.create_process`, `pkill`, `/bin/kill`, `taskkill`).
5. **Replay/probe logic in the input repo** that reaches around the tool contract.

---

## Evidence Summary by Repo

## A. `aerobeat-tool-camera-tracking`

### Pass evidence

#### `src/CameraTracking.gd`
- Uses registry/factory-based backend resolution:
  - `CameraTrackingBackendRegistry.has_factory(...)`
  - `CameraTrackingBackendRegistry.create_backend(...)`
  - `register_backend_factory(...)`
- No direct import of `aerobeat-vendor-mediapipe-python` in `src/CameraTracking.gd`.
- Default backend id is symbolic (`mediapipe_python`) rather than hard-wired class import.

#### `src/CameraTrackingConfig.gd`
- Declares `DEFAULT_BACKEND := "mediapipe_python"`.
- This is a backend identifier, not a direct vendor preload.

#### `README.md`
- Explicitly states the repo is vendor-agnostic.
- Explicitly says the backend-factory seam avoids hard-preloading vendor source from this package.

### Nuance / non-issue
- `.testbed/` in the tool repo **does** mount and test the vendor addon directly, but that is outside the contract repo's sharable `src/` boundary and matches the repo's README claims.

---

## B. `aerobeat-vendor-mediapipe-python`

### Pass evidence for vendor ownership and repo-root sidecar

#### `src/MediaPipePythonConfig.gd`
- `DEFAULT_RUNTIME_ENTRYPOINT := "runtime/mediapipe_runtime_probe.py"`
- Vendor runtime defaults include:
  - `python_executable`
  - `entrypoint`
  - `working_directory`
  - `pose_landmarker_model_path`

#### `src/MediaPipePythonRuntimeBridge.gd`
- Validates and resolves runtime entrypoint:
  - `_resolve_entrypoint_path(...)`
  - defaults to `runtime/mediapipe_runtime_probe.py`
- Resolves relative paths against vendor repo root:
  - `_repo_root_path()` returns parent of vendor `src/`
  - `_resolve_working_directory(...)` defaults to repo root
  - `_resolve_source_path(...)` resolves relative sources against repo root
- Launches Python runtime via:
  - `OS.create_process(python_executable, [entrypoint, "--request-file", ...])`
- Session files go under `user://mediapipe_python_runtime_bridge/...`

#### `scripts/prepare_vendor_runtime.py`
- `REPO_ROOT = Path(__file__).resolve().parent.parent`
- `DEFAULT_VENV_DIR = REPO_ROOT / ".venv"`
- `DEFAULT_ENTRYPOINT = REPO_ROOT / "runtime" / "mediapipe_runtime_probe.py"`
- `DEFAULT_REQUIREMENTS = REPO_ROOT / "runtime" / "requirements.txt"`
- `DEFAULT_MODEL = REPO_ROOT / "models" / "pose_landmarker_lite.task"`
- Returns runtime config with:
  - `python_executable`
  - `entrypoint`
  - `working_directory = REPO_ROOT`
  - `pose_landmarker_model_path = DEFAULT_MODEL`
- Canonical prep command:
  - `python3 scripts/prepare_vendor_runtime.py --json`

#### Repo file layout
- `runtime/mediapipe_runtime_probe.py`
- `runtime/requirements.txt`
- `models/pose_landmarker_lite.task`
- `.venv/pyvenv.cfg`

### Conclusion for vendor repo

This repo **does** look like the intended vendor boundary, and its Python sidecar is **repo-root owned**, not buried under a consumer repo.

---

## C. `aerobeat-input-camera-tracking` file-by-file audit

## Files using the intended tool contract path

### `src/providers/camera_tracking_provider.gd`
**Status:** Stale

Evidence:
- Consumes a supplied `_tracking_session`.
- Uses contract methods/signals rather than vendor/runtime internals:
  - `attach_preview_surface`
  - `detach_preview_surface`
  - `start`
  - `stop`
  - `get_active_config`
  - `change`
  - `list_cameras`
  - `get_tracking_frame`
  - `tracking_updated`
  - `state_changed`
- Performs gameplay interpretation over normalized tracking frames.

Conclusion:
- This file is the cleanest example of the desired layering.

### `src/tracking_frame_adapter.gd`
**Status:** Pass / aligned

Evidence:
- Purpose is local adaptation from normalized tracking-frame shape into detector landmark shape.
- No direct runtime/process/vendor interaction found in search results.

### `src/detectors/landmark_smoother.gd`
### `src/detectors/pose_detector_substrate.gd`
### `src/detectors/pose_landmark_ids.gd`
### `src/detectors/pose_metrics.gd`
**Status:** Pass / not part of the bypass

Evidence:
- No direct camera runtime/process/vendor coupling found in repo search output.
- These appear to stay within gameplay/detector interpretation concerns.

### `src/config/mediapipe_config.gd`
**Status:** Neutral / config carrier

Evidence:
- Used by both migrated and legacy paths.
- No direct process/network evidence surfaced in the audit search.

---

## Files that partially use the tool contract but still bypass it

### `src/input_provider.gd`
**Status:** Partial, with direct layering violations

Good evidence:
- Prefers a `CameraTracking` session and `camera_tracking_provider.gd`.
- Discovers tracking session via:
  - `CameraTracking` node name
  - `/root/AeroCameraTracking`
- Uses contract lane through `_ensure_camera_tracking_provider(...)`.

Violations:
- Hard vendor paths:
  - `VENDOR_BACKEND_SCRIPT_PATH := "res://addons/aerobeat-vendor-mediapipe-python/src/MediaPipePythonCameraTrackingBackend.gd"`
  - `VENDOR_RUNTIME_BRIDGE_SCRIPT_PATH := "res://addons/aerobeat-vendor-mediapipe-python/src/MediaPipePythonRuntimeBridge.gd"`
- Contract availability check requires vendor classes directly:
  - `_contract_lane_available()` returns true only if tool script **and** vendor backend/runtime bridge scripts exist.
- Direct vendor object construction:
  - loads `CameraTracking.gd`
  - loads vendor backend script
  - loads vendor runtime bridge script
  - `backend.set_runtime_bridge(runtime_bridge_script.new())`
  - `tracking_session.set_backend(backend, DEFAULT_BACKEND_ID)`
- Legacy fallback remains reachable:
  - `_ensure_legacy_mediapipe_provider()` loads `providers/mediapipe_provider.gd`

Conclusion:
- This is not tool-only usage; it directly composes the vendor backend from the consumer repo.

### `src/AeroCameraTracking.gd`
**Status:** Partial, with direct layering violations

Good evidence:
- Uses `CameraTracking.gd` and `camera_tracking_provider.gd`.
- Registers backend factory instead of embedding backend logic in provider code.

Violations:
- Hard vendor paths:
  - `VENDOR_BACKEND_SCRIPT_PATH := "res://addons/aerobeat-vendor-mediapipe-python/src/MediaPipePythonCameraTrackingBackend.gd"`
  - `VENDOR_RUNTIME_BRIDGE_SCRIPT_PATH := "res://addons/aerobeat-vendor-mediapipe-python/src/MediaPipePythonRuntimeBridge.gd"`
- Direct backend registration closure in consumer repo:
  - `register_backend_factory(DEFAULT_BACKEND_ID, func(_config: Dictionary): ... )`
  - inside closure: load vendor backend, load vendor runtime bridge, instantiate both, wire them together, return backend
- Direct external process probe for replay metadata:
  - `OS.execute("ffprobe", args, output, true)`

Conclusion:
- This file acts as a local composition root for the vendor backend, which is a layering bypass relative to a strict “input repo only talks to tool repo” rule.

---

## Files that clearly preserve direct legacy camera/runtime ownership

### `src/providers/mediapipe_provider.gd`
**Status:** Violation

Evidence:
- Legacy local MediaPipe-backed provider remains present and active as fallback.
- Search hit shows direct Python execution:
  - `OS.execute("python3", PackedStringArray(["-c", script]), output, true)`
- File is explicitly named and described as MediaPipe-backed provider.

Conclusion:
- This is a direct non-tool runtime path.

### `src/process/mediapipe_process.gd`
**Status:** Violation

Evidence:
- Local sidecar entrypoint assumption:
  - `@export var python_script_path: String = "python_mediapipe/main.py"`
- Direct UDP heartbeat:
  - `PacketPeerUDP`
  - destination `127.0.0.1`
- Direct command execution/import checks:
  - `OS.execute(cmd, ["--version"], ...)`
  - `OS.execute(python, ["-c", "import mediapipe; print('ok')"], ...)`
  - `OS.execute(python, ["-c", "import cv2; print('ok')"], ...)`
- Error text references local `python_mediapipe/assets/runtimes/...` and `python_mediapipe/requirements.txt`.

Conclusion:
- Strong direct ownership of local sidecar/runtime, bypassing tool + vendor separation.

### `src/autostart_manager.gd`
**Status:** Violation

Evidence:
- Direct process management / kill paths:
  - `OS.execute("pkill", ["-9", "-f", "--", "--sidecar-identity=..."], ...)`
  - python import checks via `OS.execute(...)`
- Direct local path assumption:
  - `ProjectSettings.globalize_path(_resolve_package_path("python_mediapipe/main.py"))`
- Error/help text references rebuilding local `python_mediapipe/requirements.txt`.

Conclusion:
- This file directly manages the old local sidecar lifecycle.

### `src/runtime/desktop_sidecar_runtime.gd`
**Status:** Violation

Evidence:
- Repo-local sidecar entrypoint constant:
  - `RUNTIME_ENTRYPOINT := "python_mediapipe/main.py"`
- Walks upward searching for local `python_mediapipe/main.py`.
- Direct asset/runtime paths:
  - `python_mediapipe/assets`
  - `python_mediapipe/assets/runtimes`
  - `python_mediapipe/requirements.txt`
  - `python_mediapipe/assets/models/...`
- Command hint hard-codes local prep path:
  - `python3 python_mediapipe/prepare_runtime.py --platform ... --mode ... --install-requirements --validate`

Conclusion:
- Strong local runtime/path ownership incompatible with the intended vendor repo boundary.

### `src/server/mediapipe_server.gd`
**Status:** Violation

Evidence:
- Direct UDP server binding:
  - `var _udp: PacketPeerUDP = PacketPeerUDP.new()`
  - `_udp.bind(port, "127.0.0.1")`

Conclusion:
- Direct IPC lane bypassing the tool contract.

### `src/strategies/strategy_mediapipe.gd`
**Status:** Violation

Evidence:
- Direct UDP listener:
  - `udp_listener = PacketPeerUDP.new()`

Conclusion:
- Legacy direct transport path remains in `src`.

### `src/camera_view.gd`
**Status:** Violation

Evidence:
- Direct TCP preview client:
  - `var _tcp: StreamPeerTCP`
  - host `127.0.0.1`
  - path `/camera`
- Manages socket connection state directly.

Conclusion:
- Direct preview transport bypasses the tool contract’s preview ownership.

### `src/AeroMediaPipeReplayPlaybackBackend.gd`
**Status:** Violation

Evidence:
- Direct HTTP client usage:
  - `HTTPClient.new()`
  - request path logic trims `/camera`
- Indicates direct localhost replay/playback/backend API assumptions.

Conclusion:
- Replay backend still reaches local HTTP surfaces directly rather than through `CameraTracking` abstractions.

### `src/mediapipe_input_with_camera.gd`
**Status:** Violation

Evidence:
- Header comment instructs configuring direct stream URL.
- Default stream URL:
  - `http://127.0.0.1:4243/camera`
- Creates local `MediaPipeProvider` and local `camera_view.gd` directly.

Conclusion:
- This file is a direct legacy composition path around the tool contract.

---

## Layering Violations Catalog

### Direct imports / script loads from consumer into vendor/tool internals
- `src/input_provider.gd`
  - loads tool `CameraTracking.gd`
  - loads vendor `MediaPipePythonCameraTrackingBackend.gd`
  - loads vendor `MediaPipePythonRuntimeBridge.gd`
- `src/AeroCameraTracking.gd`
  - loads tool `CameraTracking.gd`
  - loads vendor backend/runtime bridge
  - registers vendor backend factory locally

### Direct process launches / management in consumer repo
- `src/providers/mediapipe_provider.gd` → `OS.execute("python3", ...)`
- `src/process/mediapipe_process.gd` → multiple `OS.execute(...)`
- `src/autostart_manager.gd` → `OS.execute(...)`, `pkill`
- `src/process/desktop_sidecar_launcher.gd` → `OS.create_process(...)`, `/bin/kill`, `taskkill`
- `src/AeroCameraTracking.gd` → `OS.execute("ffprobe", ...)`

### Direct IPC / transport bypasses in consumer repo
- `src/server/mediapipe_server.gd` → UDP bind on `127.0.0.1`
- `src/strategies/strategy_mediapipe.gd` → UDP listener
- `src/camera_view.gd` → TCP connection to `127.0.0.1`
- `src/AeroMediaPipeReplayPlaybackBackend.gd` → HTTP client
- `src/process/mediapipe_process.gd` / `src/autostart_manager.gd` → UDP heartbeat

### File/path dependency bypasses in consumer repo
- `src/runtime/desktop_sidecar_runtime.gd`
  - `python_mediapipe/main.py`
  - `python_mediapipe/assets/...`
  - `python_mediapipe/requirements.txt`
- `src/process/mediapipe_process.gd`
  - references `python_mediapipe/assets/runtimes/...`
  - references `python_mediapipe/requirements.txt`
- `src/autostart_manager.gd`
  - resolves `python_mediapipe/main.py`

---

## Bottom Line

### What passes
- `aerobeat-tool-camera-tracking/src` is behaving like a vendor-agnostic contract shell.
- `aerobeat-vendor-mediapipe-python` is behaving like the vendor repo and owns the Python sidecar at repo root.
- `src/providers/camera_tracking_provider.gd` in the input repo is aligned with the intended contract path.

### What fails
- `aerobeat-input-camera-tracking/src` as a whole still contains substantial legacy direct camera/runtime ownership and direct vendor coupling.
- The input repo is not yet cleanly layered behind `aerobeat-tool-camera-tracking` for all camera tracking interactions.

### Final assessment
- **Scope 1:** FAIL
- **Scope 2:** PASS
- **Scope 3:** FAIL
- **Overall:** **FAIL**

---

## Recommended follow-up cleanup targets

1. Remove direct vendor loading from:
   - `src/input_provider.gd`
   - `src/AeroCameraTracking.gd`
2. Retire legacy local sidecar/runtime ownership in:
   - `src/providers/mediapipe_provider.gd`
   - `src/process/mediapipe_process.gd`
   - `src/autostart_manager.gd`
   - `src/runtime/desktop_sidecar_runtime.gd`
3. Retire direct localhost transport surfaces in:
   - `src/server/mediapipe_server.gd`
   - `src/strategies/strategy_mediapipe.gd`
   - `src/camera_view.gd`
   - `src/AeroMediaPipeReplayPlaybackBackend.gd`
   - `src/mediapipe_input_with_camera.gd`
4. Move vendor backend registration/composition fully out of the input repo, or define a single approved composition root if that indirection is intentionally allowed.
