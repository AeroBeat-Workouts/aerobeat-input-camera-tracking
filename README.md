# AeroBeat Input Camera Tracking

Gameplay-interpretation layer for AeroBeat camera input.

This repo is no longer described as the product's vendor-owned "MediaPipe Python" package. Its job is to preserve and evolve AeroBeat's **Boxing + Flow gameplay interpretation** while the platform moves camera lifecycle, preview ownership, and normalized frame production into the upstream `aerobeat-tool-camera-tracking` contract.

Current truthful status for this migration wave:

- `src/input_provider.gd` now prefers a supplied or conservatively discoverable `CameraTracking` session and routes the assembly-facing adapter through `src/providers/camera_tracking_provider.gd` when that contract lane exists
- this repo still contains the existing MediaPipe-backed implementation as a **clearly provisional legacy fallback** when no `CameraTracking` session is available yet
- the adapter still publishes itself through the input-core provider-session registry with `provider_id = mediapipe_python` for current compatibility
- the repo contains a **tracking-frame ingestion seam** that consumes normalized `CameraTracking` frames without re-owning vendor payload shape
- `.testbed/` Boxing + Flow proving now prefer a live `CameraTracking` session for the continuous contract path
- `.testbed/` mounts the upstream `aerobeat-tool-camera-tracking` contract shell plus the paired vendor backend only for repo-local proving/tests
- real sharable addon code stays at the repo root; `.testbed/` remains the proving surface only
- direct preview/lifecycle/runtime ownership is still provisional in the legacy lane and is **not** reclaimed by this repo for the contract path

## First migration-slice architecture

### What this repo owns

- Boxing detector truth
- Flow detector truth
- landmark smoothing / normalization substrate used by gameplay interpretation
- adapter logic that translates normalized `CameraTracking` frames into the landmark payload the existing detectors expect
- repo-local proving and regression tests

### What is moving upstream

- camera source selection lifecycle
- backend start/stop/change ownership
- preview attachment ownership
- normalized tracking-frame contract
- future live vs replay coordination

### New contract seam in this slice

New sharable files at the repo root:

- `src/tracking_frame_adapter.gd` — translates vendor-neutral `CameraTracking` frames into the local landmark array shape consumed by detector code
- `src/providers/camera_tracking_provider.gd` — detector provider that consumes `CameraTracking.tracking_updated(frame)` instead of raw MediaPipe server payloads

This keeps the existing detector truth mostly intact while reducing how much this repo must know about vendor/runtime details.

## Repo layout

- `src/input_provider.gd` — current assembly-facing addon entrypoint
- `src/providers/mediapipe_provider.gd` — legacy/local MediaPipe-backed provider path still kept for provisional assembly/runtime compatibility
- `src/providers/camera_tracking_provider.gd` — first contract-driven provider seam for normalized tracking-frame consumption
- `src/tracking_frame_adapter.gd` — vendor-neutral tracking-frame translator for existing detectors
- `src/detectors/` — Boxing + Flow interpretation substrate and helpers
- `python_mediapipe/` — current sidecar/runtime implementation still present in this repo during migration
- `.testbed/` — hidden Godot proving project and tests

## GodotEnv development flow

This repo uses the AeroBeat GodotEnv package convention for the local workbench.

- Canonical dev/test manifest: `.testbed/addons.jsonc`
- Installed dev/test addons: `.testbed/addons/`
- GodotEnv cache: `.testbed/.addons/`
- Hidden workbench project: `.testbed/project.godot`
- Repo-local tests: `.testbed/tests/`

Restore dependencies from the repo root:

```bash
/home/derrick/.openclaw/workspace/scripts/godotenv-sync --repo /home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking
python3 scripts/refresh_testbed_workbench.py
```

`refresh_testbed_workbench.py` is the truthful repo-local refresh path after addon-identity changes: it runs `godotenv addons install`, prunes stale generated `.testbed/addons/*` entries that are no longer declared in `.testbed/addons.jsonc`, clears the relevant Godot script/index caches, and re-imports `.testbed` so headless validation does not keep resolving removed addon identities.

Do not patch `.testbed/addons/` mirrors directly.

## Validation

Import smoke check:

```bash
python3 scripts/refresh_testbed_workbench.py
```

Run repo-local tests:

```bash
godot --headless --path .testbed --script addons/gut/gut_cmdln.gd \
  -gdir=res://tests \
  -ginclude_subdirs \
  -gexit
```

## Deferred truth for later slices

Still intentionally deferred after this first continuous consumer slice:

- final addon/session discovery pattern for runtime consumers outside proving/tests
- shrinking or replacing the old assembly-facing `src/input_provider.gd` seam once input-core reconciliation is decided
- replay/video-file semantics through the upstream contract
- richer public body/head/confidence semantics beyond the current minimal landmark contract
- any broader removal of the legacy local runtime lane outside the narrow proving path

## License

Mozilla Public License 2.0 (MPL 2.0)
