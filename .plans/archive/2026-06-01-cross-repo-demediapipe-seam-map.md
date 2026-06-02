# Cross-Repo de-MediaPipe Seam Map

**Date:** 2026-06-01
**Status:** Stale
**Prepared For:** neutral-contract definition step
**Scope:**
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-tool-camera-tracking`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-vendor-mediapipe-python`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-core`

---

## Goal

Map the remaining cross-repo dependencies that still rely on MediaPipe-specific identifiers or otherwise leak paired-vendor knowledge across the current camera-tracking lane.

---

## Executive summary

The codebase is much cleaner than the earlier local-sidecar shape, but the current cross-repo contract is still anchored on the vendor-specific identifier `mediapipe_python`. That identifier is doing too much work at once:

- it is the **input-provider id**,
- the **shared-session default key**,
- the **tool backend id/default backend**,
- the **vendor backend id embedded in runtime payloads**, and
- the **example/default id documented in input-core**.

That means the current repo split is structurally cleaner, but the runtime contract is still effectively “the MediaPipe Python lane” rather than a vendor-neutral “camera tracking lane with pluggable backends”.

The next neutral-contract step should therefore treat `mediapipe_python` as the main seam to split apart, while also addressing the remaining vendor-bearing paths/class names and proving-only runtime wiring. The `.testbed/addons.jsonc` mount of `aerobeat-vendor-mediapipe-python` is an allowed proving exception and is **not** listed here as cleanup debt.

---

## Allowed proving-only exception

This is intentionally **not** cleanup debt:

- `aerobeat-input-camera-tracking/.testbed/addons.jsonc`
  - mounts `aerobeat-vendor-mediapipe-python` under addon key `aerobeat-vendor-mediapipe-python`
  - comment already says it is mounted **only for repo-local live CameraTracking proving**

That exception is acceptable because it is explicitly testbed/workbench wiring, not product/runtime ownership.

---

## Seam inventory

| # | Seam | Owning repo | Current consumer(s) | What breaks if it changes today |
| --- | --- | --- | --- | --- |
| 1 | Provider/backend id `mediapipe_python` used as the shared public identity | `aerobeat-input-camera-tracking`, `aerobeat-tool-camera-tracking`, `aerobeat-vendor-mediapipe-python`, `aerobeat-input-core` docs/runtime policy | input adapter, camera-tracking provider, tool backend resolution, vendor config/runtime health payloads, input-core request/acquire examples and priority docs | shared-session lookup misses, backend resolution fails, runtime payload/backend labeling diverges, docs/examples become wrong |
| 2 | Session key default `mediapipe_python` and MediaPipe-shaped session key examples | `aerobeat-input-camera-tracking`, `aerobeat-input-core` | current input-provider publication/reuse path and any consumer following input-core docs | consumers requesting default/current key stop seeing published sessions |
| 3 | Tool default backend = `mediapipe_python` | `aerobeat-tool-camera-tracking` | any `CameraTracking` caller that omits `config.backend`; current camera-tracking provider indirectly depends on this shape matching its own emitted config | `backend_unregistered` or wrong backend selection if no matching registrar exists |
| 4 | Product/provider config still emits vendor-specific backend field | `aerobeat-input-camera-tracking` | `AeroCameraTracking` -> `CameraTrackingProvider` -> tool `CameraTracking` | start/change flows stop resolving the paired vendor backend unless neutral mapping exists |
| 5 | Compatibility config class/path `MediaPipeConfig` / `src/config/mediapipe_config.gd` still preserved | `aerobeat-input-camera-tracking` | legacy serialized refs, direct preloads, older assembly consumers, any code still expecting the old script/class name | preload failures, serialized resource breakage, stale docs/tests/assembly references |
| 6 | Addon alias/path expectations under `res://addons/...` | `aerobeat-input-camera-tracking`, `aerobeat-vendor-mediapipe-python` | assembly mounts, input-core path loads, tool contract loads, proving harness/tests | script loads fail even if logic is otherwise correct |
| 7 | Vendor runtime entrypoint/config class names and repo-root relative paths are hard-wired across repos | `aerobeat-vendor-mediapipe-python`, proving code in `aerobeat-input-camera-tracking` | proving harness, vendor runtime bridge, vendor config translation | live/replay proving and vendor runtime launch fail |
| 8 | Vendor runtime session storage path `user://mediapipe_python_runtime_bridge` encodes vendor name | `aerobeat-vendor-mediapipe-python` | vendor runtime bridge/session lifecycle only | state/session artifacts move; running sessions, cleanup assumptions, and any path-based diagnostics break |
| 9 | MediaPipe-specific env/model overrides | `aerobeat-vendor-mediapipe-python`, proving code in `aerobeat-input-camera-tracking` | host/runtime prep, direct runtime probe execution, proving harness-driven launches | runtime loses camera/model discovery overrides and starts failing honestly with missing camera/model/runtime errors |
| 10 | Input-core runtime policy/docs still name MediaPipe lanes as first-class canonical ids | `aerobeat-input-core` | current consumer guidance and priority ordering | docs drift, consumer lookups continue encoding vendor ids even after contract neutralization |
| 11 | Vendor implementation depends on tool contract class names from `aerobeat-tool-camera-tracking` | `aerobeat-vendor-mediapipe-python` | vendor backend shell + frame mapper | vendor package no longer loads against the tool contract if class names/paths move without adapter/shim |
| 12 | Proving harness knows the sibling vendor repo shape directly | `aerobeat-input-camera-tracking` | repo-local proving only | proving harness loses its prepared-python/runtime/model path wiring |

---

## Detailed seam notes

### 1) `mediapipe_python` is still the shared identity across the lane

### Where it lives

- `aerobeat-input-camera-tracking/src/input_provider.gd`
  - `const PROVIDER_ID := "mediapipe_python"`
  - `const SHARED_SESSION_KEY := "mediapipe_python"`
- `aerobeat-input-camera-tracking/src/providers/camera_tracking_provider.gd`
  - emits `{"backend": "mediapipe_python", ...}` into tool config
- `aerobeat-tool-camera-tracking/src/CameraTrackingConfig.gd`
  - `const DEFAULT_BACKEND := "mediapipe_python"`
- `aerobeat-vendor-mediapipe-python/src/MediaPipePythonConfig.gd`
  - `const BACKEND_ID := "mediapipe_python"`
  - all normalized public/vendor configs force that backend id
- `aerobeat-vendor-mediapipe-python/runtime/mediapipe_runtime_probe.py`
  - returns `"backend": "mediapipe_python"` in runtime payloads
- `aerobeat-input-core/src/input_manager.gd`
  - `input_priority` starts with `mediapipe_python`, then `mediapipe_native`
- `aerobeat-input-core/docs/provider-session-registry-v1.md`
  - examples publish/request/acquire via `provider_id = "mediapipe_python"`

### Why this is still vendor knowledge

The nominally shared lane is not keyed as `camera_tracking`, `desktop_camera_tracking`, `pose_tracking`, etc. It is keyed as the paired vendor implementation.

### Breakage if changed today

If `mediapipe_python` changes without a coordinated neutralization layer:

- `input_provider.gd` publishes sessions under the wrong id/key for existing consumers
- `camera_tracking_provider.gd` asks the tool layer for a backend id that may no longer exist
- `CameraTracking` default backend resolution fails with `backend_unregistered`
- vendor runtime snapshots stop matching upstream expectations for `backend`
- input-core consumer examples remain wrong and will teach stale lookup patterns

### Neutral-contract implication

This is the **primary seam** to split. The neutral contract needs distinct concepts for:

1. public provider lane id,
2. public backend selection id,
3. vendor implementation id,
4. optional session-key naming policy.

---

### 2) Default session publication/reuse still depends on MediaPipe naming

### Where it lives

- `aerobeat-input-camera-tracking/src/input_provider.gd`
  - publishes with `session_key = SHARED_SESSION_KEY`
  - defaults request normalization to:
    - `session_key = "mediapipe_python"`
    - `provider_id = "mediapipe_python"`
- `aerobeat-input-core/docs/provider-session-registry-v1.md`
  - example session keys:
    - `mediapipe_python/desktop_main`
    - `mediapipe_python/camera0`

### Why this matters

The session registry logic itself is string-based and generic, but the current producer + docs teach a MediaPipe-specific identity as the canonical reusable session namespace.

### Breakage if changed today

- existing/default consumer requests miss the published session
- any caller relying on `_with_default_shared_session_request()` stops reusing the current provider
- borrowed-session paths silently fall back to “no session found” behavior

### Neutral-contract implication

Session key policy should likely move to neutral forms like:

- `camera_tracking/desktop_main`
- `camera_tracking/<device>`
- or separate lane + device metadata with no vendor in the key

---

### 3) Tool backend defaulting still points directly at the MediaPipe backend

### Where it lives

- `aerobeat-tool-camera-tracking/src/CameraTrackingConfig.gd`
  - `DEFAULT_BACKEND := "mediapipe_python"`
- `aerobeat-tool-camera-tracking/src/CameraTracking.gd`
  - resolves `config.backend` or `CameraTrackingConfig.DEFAULT_BACKEND`
  - errors with `backend_unregistered` if no factory is registered for that id

### Why this matters

The tool repo is supposed to be the vendor-agnostic contract shell, but its default is still bound to a specific vendor backend id.

### Breakage if changed today

- any `CameraTracking` consumer that omits backend selection changes behavior immediately
- unless a neutral backend id is also registered, startup fails at backend resolution

### Neutral-contract implication

The tool contract needs either:

- a neutral default backend id, or
- no implicit vendor default at all.

---

### 4) The input-camera-tracking provider still emits the vendor backend id directly

### Where it lives

- `aerobeat-input-camera-tracking/src/providers/camera_tracking_provider.gd`
  - builds tracking config with `"backend": "mediapipe_python"`

### Why this matters

This repo is product/input-facing now, but it still hardcodes the paired vendor backend in the config it hands to the tool layer.

### Breakage if changed today

- `AeroCameraTracking` startup/change flows cannot resolve the current backend unless the new id is recognized by the tool registry and the vendor package matches it

### Neutral-contract implication

The product/input layer should emit a neutral lane/backend request, not the vendor backend id itself.

---

### 5) Legacy compatibility path/class still leaks MediaPipe naming

### Where it lives

- `aerobeat-input-camera-tracking/src/config/mediapipe_config.gd`
  - compatibility shim
  - `class_name MediaPipeConfig`
  - extends neutral `src/config/camera_tracking_config.gd`
- repo-local code has mostly moved to `camera_tracking_config.gd`, but the shim remains

### Who still consumes it

- any serialized `.tscn` / `.tres` / preload path outside the inspected repos that still references `mediapipe_config.gd`
- any assembly consumer still expecting `MediaPipeConfig`
- older docs/tests or human workflows that preload the old script directly

### Breakage if removed/renamed today

- preload failures
- deserialization/class-cache failures
- assembly/editor breakage if older content still points at the old path/class

### Neutral-contract implication

Keep this as a staged migration seam. Do not remove it until assembly-facing path usage has been audited or shimmable.

---

### 6) Addon alias and script-path expectations are still explicit cross-repo coupling

### Where it lives

- `aerobeat-input-camera-tracking/src/input_provider.gd`
  - extends `res://addons/aerobeat-input-core/src/interfaces/boxing_input.gd`
  - loads `res://addons/aerobeat-input-core/src/runtime/provider_session_registry.gd`
  - comments require assembly mount alias `res://addons/aerobeat-input-camera-tracking/`
- `aerobeat-input-camera-tracking/src/AeroCameraTracking.gd`
  - loads `res://addons/aerobeat-tool-camera-tracking/src/CameraTracking.gd`
  - loads repo-local provider/config under `res://addons/aerobeat-input-camera-tracking/...`
- `aerobeat-vendor-mediapipe-python/src/MediaPipePythonCameraTrackingBackend.gd`
  - extends/loads multiple classes from `res://addons/aerobeat-tool-camera-tracking/src/...`
- proving tests/scripts in both repos also preload these same addon paths

### Why this matters

This is normal package coupling, but it is still a hard seam for the neutral-contract step because path/alias changes are consumer-visible.

### Breakage if changed today

Any renamed addon key or moved script path causes immediate load failures before runtime logic even starts.

### Neutral-contract implication

If the contract is renamed or split, keep compatibility aliases/shims at the addon path level until consumers are migrated.

---

### 7) Vendor runtime launch wiring is still known outside the vendor repo

### Where it lives

- `aerobeat-vendor-mediapipe-python/src/MediaPipePythonConfig.gd`
  - `DEFAULT_RUNTIME_ENTRYPOINT := "runtime/mediapipe_runtime_probe.py"`
- `aerobeat-vendor-mediapipe-python/src/MediaPipePythonRuntimeBridge.gd`
  - validates/launches the runtime entrypoint from config
- `aerobeat-input-camera-tracking/.testbed/scripts/proving_harness.gd`
  - knows sibling vendor repo root via `VENDOR_REPO_ROOT := "res://addons/aerobeat-vendor-mediapipe-python"`
  - builds runtime config with explicit vendor python executable, entrypoint, working directory, model path

### Why this matters

The proving layer still knows the vendor repo’s internal runtime layout. That is acceptable for proving, but it is still a seam to account for.

### Breakage if changed today

- proving harness cannot launch the prepared vendor runtime
- vendor bridge fails with `runtime_entrypoint_missing` or python/path errors

### Neutral-contract implication

Either keep this knowledge fully vendor-owned, or introduce a vendor-prep descriptor artifact instead of path-by-convention wiring.

---

### 8) Vendor runtime session storage path still carries the vendor name

### Where it lives

- `aerobeat-vendor-mediapipe-python/src/MediaPipePythonRuntimeBridge.gd`
  - writes under `user://mediapipe_python_runtime_bridge`
  - session dir base `user://mediapipe_python_runtime_bridge/sessions`

### Why this matters

This is not a public contract by itself, but it is a durable runtime seam that bakes the vendor id into persistent artifacts and diagnostics.

### Breakage if changed today

- in-flight sessions/cleanup assumptions move
- any tooling or debugging flow that expects the current path stops seeing session files

### Neutral-contract implication

If the runtime session lane becomes neutral/shared, its artifact naming should neutralize too.

---

### 9) MediaPipe-specific env/model seams remain active in the vendor lane

### Where it lives

In `aerobeat-vendor-mediapipe-python/runtime/mediapipe_runtime_probe.py`:

- `AEROBEAT_CAMERA_ROOT`
- `AEROBEAT_CAMERA_PATTERN`
- `AEROBEAT_CAMERA_SAMPLE_FIXTURES_JSON`
- `AEROBEAT_MEDIAPIPE_POSE_LANDMARKER_MODEL_PATH`
- host env fallback `MEDIAPIPE_POSE_LANDMARKER_MODEL_PATH`

In `aerobeat-input-camera-tracking/.testbed/scripts/proving_harness.gd`:

- `AEROBEAT_CAMERA_TRACKING_SOURCE` selects live source override for proving/input startup

### Why this matters

These are real runtime seams. The camera-root/pattern vars are fairly generic, but the pose-landmarker model override is explicitly MediaPipe-branded.

### Breakage if changed today

- direct host/runtime inspection commands stop finding cameras or fixtures
- tasks-era MediaPipe model lookup fails, leading to honest `mediapipe_model_missing`
- proving harness source override stops selecting the expected camera/video source

### Neutral-contract implication

The next contract should decide which env vars are:

- vendor-owned and intentionally branded,
- neutral runtime knobs,
- or temporary proving-only helpers.

---

### 10) Input-core still teaches MediaPipe-first lookup policy

### Where it lives

- `aerobeat-input-core/src/input_manager.gd`
  - `input_priority` begins with:
    - `mediapipe_python`
    - `mediapipe_native`
- `aerobeat-input-core/docs/provider-session-registry-v1.md`
  - examples for owner/session/provider ids still use MediaPipe names
  - suggested adoption path explicitly says to request `provider_id = "mediapipe_python"`

### Why this matters

Even though input-core’s registry logic is generic, its policy and docs still encode MediaPipe provider ids as the default camera-gameplay path.

### Breakage if changed today

- runtime policy changes if ids are renamed without updating priority lists
- future consumers copy stale docs and keep reintroducing MediaPipe-specific lookups

### Neutral-contract implication

Input-core needs a doc/policy pass as part of neutralization, not just repo-local code edits elsewhere.

---

### 11) Vendor package depends on tool contract class names and locations

### Where it lives

- `aerobeat-vendor-mediapipe-python/src/MediaPipePythonCameraTrackingBackend.gd`
  - extends `res://addons/aerobeat-tool-camera-tracking/src/CameraTrackingBackend.gd`
  - preloads `CameraTracking`, `CameraTrackingConfig`, `CameraTrackingPreview`
- `aerobeat-vendor-mediapipe-python/src/MediaPipePythonFrameMapper.gd`
  - preloads `CameraTrackingFrame`

### Why this matters

This is expected dependency direction, but it is still a sharp seam: the vendor repo is coupled to the current tool contract filenames/class roles.

### Breakage if changed today

Any moved/renamed tool contract class breaks the vendor package load path immediately.

### Neutral-contract implication

If the tool contract is renamed or split for neutrality, the vendor repo will need either direct migration or compatibility shims.

---

### 12) Proving harness still knows the sibling vendor repo shape directly

### Where it lives

- `aerobeat-input-camera-tracking/.testbed/scripts/proving_harness.gd`
  - resolves vendor root from addon alias
  - constructs vendor runtime config itself
  - picks vendor model filename by model complexity
- `aerobeat-input-camera-tracking/.testbed/tests/unit/test_proving_harness_trails.gd`
  - asserts vendor-root-based runtime/model path behavior

### Why this matters

This is repo-local proving, not product code, but it is still deliberate cross-repo knowledge the neutral-contract step should keep isolated.

### Breakage if changed today

Proving harness live/replay verification stops finding the prepared vendor runtime layout.

### Neutral-contract implication

Keep this proving-only unless/until a formal neutral vendor-prep descriptor exists.

---

## What I did **not** find

A few important non-findings:

- I did **not** find current production code in `aerobeat-input-camera-tracking` auto-registering vendor backend factories from the input repo. That boundary looks intentionally preserved.
- I did **not** treat `.testbed/addons.jsonc` mounting of `aerobeat-vendor-mediapipe-python` as cleanup debt; it is an explicit proving exception.
- I did **not** inspect a separate assembly repo in this pass, so assembly-consumer breakage is inferred from addon-path comments, compatibility shims, and input-core-facing usage patterns inside the inspected repos.

---

## Recommended neutral-contract order

1. **Split the identity seam first**
   - define neutral public lane/provider/backend ids
   - decide whether `mediapipe_python` remains as a vendor implementation id only

2. **Define session-key policy second**
   - stop using the vendor id as the default published/reused session key namespace

3. **Neutralize tool defaults next**
   - remove or replace `CameraTrackingConfig.DEFAULT_BACKEND := "mediapipe_python"`

4. **Add compatibility mapping/shims**
   - preserve current `mediapipe_python` lookups temporarily where needed
   - keep `MediaPipeConfig` shim until assembly/path migration is complete

5. **Only then clean up branded proving/runtime names**
   - env vars, session-dir names, and proving-only runtime wiring can follow after the public contract is stable

---

## Ready-for-next-step conclusion

The repo set is ready for the **neutral-contract definition** step.

The most important fact for that step is simple:

> the cross-repo boundary is no longer a local MediaPipe sidecar implementation boundary, but it is still a **MediaPipe-named contract boundary**.

That means the next slice should focus on **identity and contract neutralization**, not another round of local implementation cleanup.
