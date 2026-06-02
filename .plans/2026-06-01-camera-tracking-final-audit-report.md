# Camera Tracking Final Layering Audit

**Date:** 2026-06-01 20:51 EDT
**Auditor:** OpenClaw subagent (`auditor`)
**Repos Audited:**
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-tool-camera-tracking`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-vendor-mediapipe-python`

**Inputs Reviewed:**
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.plans/2026-06-01-camera-tracking-audit-report.md`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.plans/2026-06-01-camera-tracking-boundary-memo.md`
- alignment commits: `2770d54`, `2446686`, `a878f7f`

---

## Verdict

**PASS**

The current repo state now matches the intended layering closely enough to pass the final audit:

- `aerobeat-input-camera-tracking/src` uses the `aerobeat-tool-camera-tracking` contract for camera-tracking interactions and no longer directly imports vendor runtime/backend code or launches camera/runtime processes.
- `aerobeat-tool-camera-tracking` remains vendor-agnostic in `src/` and resolves backends through its registry/factory seam.
- `aerobeat-vendor-mediapipe-python` remains the MediaPipe/Python vendor boundary, with the Python sidecar and runtime-prep assets owned at the vendor repo root.
- Remaining `mediapipe_*` names and compatibility identifiers in the input repo are **residual naming / compatibility debt**, not true layering violations.

---

## What changed relative to the earlier FAIL audit

The earlier audit report is now superseded by the current tree state.

The cited alignment commits materially changed the boundary:

- `2446686` removed the old local runtime lane from `aerobeat-input-camera-tracking`, including former direct process/runtime/server/provider files such as `src/providers/mediapipe_provider.gd`, `src/process/mediapipe_process.gd`, `src/process/desktop_sidecar_launcher.gd`, `src/runtime/desktop_sidecar_runtime.gd`, `src/server/mediapipe_server.gd`, `src/strategies/strategy_mediapipe.gd`, `src/camera_view.gd`, `src/mediapipe_input_with_camera.gd`, and `src/AeroMediaPipeReplayPlaybackBackend.gd`.
- `2770d54` refactored the remaining consumers so `src/AeroCameraTracking.gd` and `src/input_provider.gd` use the tool contract path rather than composing vendor/runtime objects.
- `a878f7f` added `src/config/camera_tracking_config.gd`, giving the repo a neutral config resource alongside the older compatibility-named config.

---

## Scope questions answered

### 1) Does `/src` in `aerobeat-input-camera-tracking` now use `aerobeat-tool-camera-tracking` for all camera-tracking interactions?

**Yes, for the current sharable `src/` surface.**

### Pass evidence

#### `src/AeroCameraTracking.gd`
- Declares its scope as consuming only the public contract and not composing vendor runtime objects: `/src/AeroCameraTracking.gd:4-9`
- Loads only the tool contract shell, not vendor code: `/src/AeroCameraTracking.gd:11-13`
  - `res://addons/aerobeat-tool-camera-tracking/src/CameraTracking.gd`
  - local provider/config scripts only
- Starts/stops through the tracking session/provider seam rather than process/network code: `/src/AeroCameraTracking.gd:84-113`
- Replay-related config mutation stays inside config dictionaries and contract-facing session behavior, not direct ffprobe/process/HTTP seams: `/src/AeroCameraTracking.gd:384-432`

#### `src/input_provider.gd`
- Declares the truthful scope as contract-only and explicitly says it does not reclaim runtime/backend/preview ownership: `/src/input_provider.gd:8-14`
- Uses only the camera-tracking provider lane and reports no legacy fallback: `/src/input_provider.gd:22`, `/src/input_provider.gd:114-118`
- Creates the local provider by loading `providers/camera_tracking_provider.gd`, not vendor repo scripts: `/src/input_provider.gd:338-358`
- Loads its local config resource only: `/src/input_provider.gd:553-569`

#### `src/providers/camera_tracking_provider.gd`
- Declares its role as contract-driven detector interpretation, not vendor/runtime ownership: `/src/providers/camera_tracking_provider.gd:3-9`
- Attaches preview and starts/stops only through the supplied `_tracking_session`: `/src/providers/camera_tracking_provider.gd:77-105`
- Builds a public tracking config dictionary and sends it to the tool service: `/src/providers/camera_tracking_provider.gd:298-336`

#### Supporting sharable files in `src/`
Current `src/` contents are limited to:
- `src/AeroCameraTracking.gd`
- `src/input_provider.gd`
- `src/providers/camera_tracking_provider.gd`
- `src/tracking_frame_adapter.gd`
- detector helper files under `src/detectors/`
- config resources under `src/config/`

No former local runtime/process/server transport files remain in `src/`.

### Negative evidence: bypasses not found in input `src/`

Repo searches across `aerobeat-input-camera-tracking/src` for these bypass patterns returned no active sharable-code hits:
- vendor addon paths such as `res://addons/aerobeat-vendor-mediapipe-python/...`
- `OS.create_process`
- `OS.execute`
- `PacketPeerUDP`
- `StreamPeerTCP`
- `HTTPClient`
- `127.0.0.1`
- `mediapipe_runtime_probe.py`
- `prepare_vendor_runtime.py`
- `pkill`, `taskkill`, `/bin/kill`

The only repo-external script path hit in sharable `src/` was the intended tool contract path in `/src/AeroCameraTracking.gd:11`.

### Residual debt that is not a layering violation

- `PROVIDER_ID := "mediapipe_python"` and `SHARED_SESSION_KEY := "mediapipe_python"` remain in `/src/input_provider.gd:16-19` for input-core/session-registry compatibility.
- `CameraTrackingProvider._build_tracking_config()` still sets `"backend": "mediapipe_python"` in the public config payload: `/src/providers/camera_tracking_provider.gd:312-335`.
- `src/config/mediapipe_config.gd` still exists and is still the config file instantiated by `input_provider.gd`: `/src/input_provider.gd:567-569`, `/src/config/mediapipe_config.gd:1-39`.
- `src/config/camera_tracking_config.gd` is the neutral twin resource used by `AeroCameraTracking.gd`: `/src/AeroCameraTracking.gd:13`, `/src/config/camera_tracking_config.gd:1-38`.

These are naming/compatibility seams, not direct vendor/runtime ownership.

---

### 2) Does `aerobeat-tool-camera-tracking` still rely on `aerobeat-vendor-mediapipe-python` as the vendor repo boundary with the Python sidecar at repo root?

**Yes.**

### Tool repo pass evidence

#### `aerobeat-tool-camera-tracking/src/CameraTracking.gd`
- Exposes the public backend-factory seam:
  - `register_backend_factory(...)`: `/src/CameraTracking.gd:56-57`
  - `unregister_backend_factory(...)`: `/src/CameraTracking.gd:59-60`
  - `clear_backend_factories(...)`: `/src/CameraTracking.gd:62-63`
- Resolves backends through the registry rather than direct vendor imports: `/src/CameraTracking.gd:154-178`
- No vendor addon paths or MediaPipe runtime classes were found in tool `src/`.

This is the intended contract ownership: tool owns public service + backend resolution policy, not MediaPipe implementation details.

### Vendor repo pass evidence

#### `aerobeat-vendor-mediapipe-python/src/MediaPipePythonCameraTrackingBackend.gd`
- Extends the tool contract backend interface: `/src/MediaPipePythonCameraTrackingBackend.gd:1`
- Imports tool contract classes from `aerobeat-tool-camera-tracking`: `/src/MediaPipePythonCameraTrackingBackend.gd:3-5`
- Owns vendor-specific runtime config/bridge usage locally: `/src/MediaPipePythonCameraTrackingBackend.gd:6-17`, `/src/MediaPipePythonCameraTrackingBackend.gd:39-56`

#### `aerobeat-vendor-mediapipe-python/src/MediaPipePythonConfig.gd`
- Declares the vendor backend id and vendor runtime defaults: `/src/MediaPipePythonConfig.gd:3-15`, `/src/MediaPipePythonConfig.gd:38-73`
- Keeps runtime-specific fields under the vendor lane, including:
  - `python_executable`
  - `entrypoint`
  - `working_directory`
  - `pose_landmarker_model_path`

#### `aerobeat-vendor-mediapipe-python/src/MediaPipePythonRuntimeBridge.gd`
- Launches the Python sidecar itself via `OS.create_process`: `/src/MediaPipePythonRuntimeBridge.gd:203-208`
- Validates and resolves the vendor runtime entrypoint and source paths: `/src/MediaPipePythonRuntimeBridge.gd:324-363`
- Writes request payloads and runs blocking/nonblocking vendor runtime commands locally: `/src/MediaPipePythonRuntimeBridge.gd:376-413`
- Resolves relative runtime/source paths against the vendor repo root via `_repo_root_path()`: `/src/MediaPipePythonRuntimeBridge.gd:490-518`
- Performs termination of the vendor subprocess locally via `/bin/kill`: `/src/MediaPipePythonRuntimeBridge.gd:69-76`

#### `aerobeat-vendor-mediapipe-python/scripts/prepare_vendor_runtime.py`
- Declares repo-root ownership explicitly:
  - `REPO_ROOT = Path(__file__).resolve().parent.parent`: `/scripts/prepare_vendor_runtime.py:13`
  - `DEFAULT_VENV_DIR = REPO_ROOT / ".venv"`: `/scripts/prepare_vendor_runtime.py:14`
  - `DEFAULT_ENTRYPOINT = REPO_ROOT / "runtime" / "mediapipe_runtime_probe.py"`: `/scripts/prepare_vendor_runtime.py:15`
  - `DEFAULT_REQUIREMENTS = REPO_ROOT / "runtime" / "requirements.txt"`: `/scripts/prepare_vendor_runtime.py:16`
  - `DEFAULT_MODEL = REPO_ROOT / "models" / "pose_landmarker_lite.task"`: `/scripts/prepare_vendor_runtime.py:17`
- Returns runtime config that points back to vendor-repo-owned assets: `/scripts/prepare_vendor_runtime.py:121-142`
  - `python_executable`
  - `entrypoint`
  - `working_directory = REPO_ROOT`
  - `pose_landmarker_model_path = DEFAULT_MODEL`
  - canonical prep command `python3 scripts/prepare_vendor_runtime.py --json`

### Conclusion

The dependency direction is clean:
- input repo -> tool contract
- vendor repo -> tool contract
- vendor repo owns MediaPipe/Python/runtime specifics
- tool repo stays vendor-agnostic in sharable `src/`

---

### 3) Remaining direct imports, process launches, IPC calls, file/path dependencies, or bypasses that violate the intended final layering

**No remaining true layering violations were found in the current sharable code path.**

### True violations found

None in the current audited `src/` surfaces.

### Important seams that remain, but are valid

#### A. Backend selection by symbolic id
- `mediapipe_python` still appears as a symbolic backend id in:
  - `/src/input_provider.gd:16-19`
  - `/src/providers/camera_tracking_provider.gd:312-335`
  - `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-tool-camera-tracking/src/CameraTracking.gd:154-178`
  - `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-vendor-mediapipe-python/src/MediaPipePythonConfig.gd:3`

This is acceptable. Naming a backend id is not the same thing as directly composing vendor code.

#### B. Product-facing config still carries runtime/vendor dictionaries
- Input config resources still expose `runtime`, `diagnostics`, and `vendor` dictionaries:
  - `/src/config/camera_tracking_config.gd:19-21`
  - `/src/config/mediapipe_config.gd:20-22`
- `CameraTrackingProvider` forwards those dictionaries into the tool contract config payload: `/src/providers/camera_tracking_provider.gd:326-335`

This is acceptable for now because the input repo is passing opaque config through the contract, not resolving repo-root paths or launching vendor runtime itself.

#### C. Testbed dependency seams
- Input repo `.testbed/addons.jsonc` mounts both the tool contract repo and vendor repo for repo-local proving only: `/.testbed/addons.jsonc:16-27`
- Input repo README explicitly describes this as repo-local proving/tests rather than sharable source ownership: `/README.md:9-14`

This is not a sharable `src/` layering violation.

---

### 4) Distinguish true layering violations from residual naming/compatibility debt

## Residual naming / compatibility debt only

1. **`mediapipe` naming in input-facing files**
   - `src/config/mediapipe_config.gd`
   - `PROVIDER_ID := "mediapipe_python"`
   - `SHARED_SESSION_KEY := "mediapipe_python"`

   This is compatibility and migration debt, not a boundary failure.

2. **Dual config resources**
   - `src/config/camera_tracking_config.gd`
   - `src/config/mediapipe_config.gd`

   These two files currently duplicate the same fields/behavior. That is cleanup debt, but neither file directly violates layering.

3. **README/plugin compatibility wording**
   - The input README still references current migration status and mentions `.testbed/` vendor-backed proving: `/README.md:7-14`
   - The plugin description still says the addon does not own local vendor/runtime fallback behavior: `/plugin.cfg:3-7`

   This is documentation/positioning debt only if the team wants to further neutralize names.

## What would have been a true violation, but is no longer present

These classes of violations were removed by the alignment commits and are no longer present in current sharable `src/`:
- direct vendor script loads from `aerobeat-input-camera-tracking/src`
- direct backend/runtime object construction in the input repo
- local process launch/kill for Python runtime from the input repo
- direct UDP/TCP/HTTP localhost transport ownership from the input repo
- direct repo-root file/path ownership of `runtime/`, `models/`, or `.venv` from the input repo

---

## Final conclusion

The intended final layering is now effectively in place for the audited slice.

- `aerobeat-input-camera-tracking` owns gameplay interpretation and contract consumption.
- `aerobeat-tool-camera-tracking` owns the public camera-tracking service contract and backend registry seam.
- `aerobeat-vendor-mediapipe-python` owns MediaPipe/Python runtime implementation details, including the repo-root sidecar, runtime prep, model assets, and subprocess/session bridge.

The remaining issues are naming/compatibility cleanup items, not architectural bypasses.

---

## Concise verdict

**PASS**

No remaining true layering violations were found in the current sharable `src/` code path. Remaining `mediapipe_*` identifiers and duplicated config resources are residual migration debt only.
