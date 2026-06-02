# AeroBeat Input Camera Tracking

Gameplay-interpretation layer for AeroBeat camera input.

This repo preserves and evolves AeroBeat's **Boxing + Flow gameplay interpretation** while camera lifecycle, preview ownership, and normalized frame production live in the upstream `aerobeat-tool-camera-tracking` contract.

Current truthful status for this migration wave:

- `src/input_provider.gd` now requires a supplied or conservatively discoverable `CameraTracking` session and routes the assembly-facing adapter through `src/providers/camera_tracking_provider.gd`
- the adapter still publishes itself through the input-core provider-session registry for current compatibility, but the sharable addon no longer owns a local runtime fallback path
- the repo contains a **tracking-frame ingestion seam** that consumes normalized `CameraTracking` frames without re-owning vendor payload shape
- `.testbed/` Boxing + Flow proving uses the upstream `aerobeat-tool-camera-tracking` contract shell plus the paired vendor backend only for repo-local proving/tests
- real sharable addon code stays at the repo root; `.testbed/` remains the proving surface only
- direct preview/lifecycle/runtime ownership is not reclaimed by this repo

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
- `src/providers/camera_tracking_provider.gd` — detector provider that consumes `CameraTracking.tracking_updated(frame)` instead of raw backend payloads

This keeps the existing detector truth mostly intact while reducing how much this repo must know about vendor/runtime details.

## Repo layout

- `src/input_provider.gd` — current assembly-facing addon entrypoint
- `src/providers/camera_tracking_provider.gd` — contract-driven provider seam for normalized tracking-frame consumption
- `src/tracking_frame_adapter.gd` — vendor-neutral tracking-frame translator for existing detectors
- `src/detectors/` — Boxing + Flow interpretation substrate and helpers
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
```

This checkout currently does **not** ship a repo-local `scripts/refresh_testbed_workbench.py` helper. Treat `.testbed/addons/` as generated install output from `.testbed/addons.jsonc`, not as sharable source.

Do not patch `.testbed/addons/` mirrors directly.

## Validation

Dependency/workbench refresh:

```bash
/home/derrick/.openclaw/workspace/scripts/godotenv-sync --repo /home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking
```

Run repo-local tests:

```bash
godot --headless --path .testbed --script addons/aerobeat-vendor-godot-unit-test/gut_cmdln.gd \
  -gdir=res://tests \
  -ginclude_subdirs \
  -gexit
```

## Deferred truth for later slices

Still intentionally deferred after this first continuous consumer slice:

- final addon/session discovery pattern for runtime consumers outside proving/tests
- shrinking or replacing the old assembly-facing `src/input_provider.gd` seam once input-core reconciliation is decided
- broader replay/video-file ergonomics outside the current `AeroCameraTracking` proving/manual-audit path
- richer public body/head/confidence semantics beyond the current minimal landmark contract
- any broader removal of the legacy local runtime lane outside the narrow proving path

## License

Mozilla Public License 2.0 (MPL 2.0)
