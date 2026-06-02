# Camera Tracking De-MediaPipe Cleanup Memo

**Date:** 2026-06-01 21:45 EDT
**Status:** Stale
**Author:** OpenClaw subagent (`research`)
**Repo:** `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking`

---

## Bottom line

The architectural boundary is now clean enough to pass, but this repo still contains **explicit MediaPipe branding and MediaPipe-specific compatibility knowledge** in four places:

1. **sharable src compatibility seams** (`provider_id`, `session_key`, backend id, config class/file name, addon alias comment)
2. **README wording** that still explains the repo in relation to MediaPipe
3. **.testbed proving/workbench naming, messages, env vars, mocks, and runtime wiring**
4. **tests that assert MediaPipe-specific identifiers or preload MediaPipe-named resources**

If the target is strict — **this repo should not know or say MediaPipe at all, only that it communicates with `aerobeat-tool-camera-tracking`** — then the remaining debt is real cleanup debt, not just cosmetic wording.

The one explicit exception Derrick called out is valid:

- **Allowed, not cleanup debt:** `.testbed/addons.jsonc` mounting `aerobeat-vendor-mediapipe-python`

That mount is still needed so the hidden local proving/workbench can satisfy the sibling tool repo's backend/runtime dependency. The presence of that mount alone should **not** be treated as a violation.

---

## Scope rule used for this memo

Included as cleanup debt:
- any file/path/name/message/comment/env var/test assertion in this repo that says `MediaPipe` / `mediapipe`
- any input-repo-owned identifier that encodes MediaPipe knowledge instead of camera-tracking contract knowledge
- any proving/testbed file that directly names the MediaPipe vendor lane when a neutral tool-facing name should be sufficient

Excluded from cleanup debt:
- `.testbed/addons.jsonc` mounting `aerobeat-vendor-mediapipe-python`

---

## Remaining MediaPipe-branded or MediaPipe-knowledge-bearing surfaces

## A. Sharable `src/` surfaces

### 1) `src/input_provider.gd`

Remaining debt:
- comment still says consuming projects mount the repo as `res://addons/aerobeat-input-mediapipe/`
- `const PROVIDER_ID := "mediapipe_python"`
- `const SHARED_SESSION_KEY := "mediapipe_python"`
- `_new_local_config()` still loads `config/mediapipe_config.gd`

Why it matters:
- this is the public addon entrypoint, so these names leak MediaPipe directly into the repo’s outward identity and input-core compatibility surface

Recommended neutral replacements:
- addon alias comment: `res://addons/aerobeat-input-camera-tracking/`
- `PROVIDER_ID`: `camera_tracking`
- `SHARED_SESSION_KEY`: `camera_tracking`
- config load path: `config/camera_tracking_config.gd`

Compatibility risk:
- anything in `aerobeat-input-core`, consuming game assemblies, or tests that requests `mediapipe_python` sessions will break unless updated together or bridged temporarily

---

### 2) `src/providers/camera_tracking_provider.gd`

Remaining debt:
- `_build_tracking_config()` still sends `"backend": "mediapipe_python"`
- `_ensure_config()` still loads `config/mediapipe_config.gd`

Why it matters:
- this repo is still telling the tool layer which vendor backend to use by a MediaPipe-specific id
- that is stronger than branding; it is vendor knowledge embedded in the input repo

Recommended neutral replacements:
- preferred end state: do **not** hardcode vendor backend here at all; let `aerobeat-tool-camera-tracking` resolve the mounted/default backend
- if a backend selector is still required, rename it to a neutral tool-owned concept such as `camera_tracking_default` or move the defaulting logic into the tool repo
- load `config/camera_tracking_config.gd`

Compatibility risk:
- `aerobeat-tool-camera-tracking` and `aerobeat-vendor-mediapipe-python` currently still appear to revolve around the backend id `mediapipe_python`; that seam needs explicit handling before removing it here

---

### 3) `src/config/mediapipe_config.gd`

Remaining debt:
- filename: `mediapipe_config.gd`
- class name: `MediaPipeConfig`

Why it matters:
- this is the clearest remaining product-facing MediaPipe brand in sharable `src/`
- a neutral twin already exists (`src/config/camera_tracking_config.gd`), so the MediaPipe-named resource is now duplicate compatibility debt

Recommended neutral replacements:
- make `src/config/camera_tracking_config.gd` the only product-facing config resource
- if a class name is desired, use `class_name CameraTrackingConfig`
- either delete `mediapipe_config.gd` after downstream updates, or keep it only as a short-lived shim if serialized references require a staged removal

Compatibility risk:
- Godot preloads, serialized script references, and tests may still point directly at `mediapipe_config.gd` / `MediaPipeConfig`

---

## B. Root docs / plugin-facing wording

### 4) `README.md`

Remaining debt:
- describes the repo as no longer being the vendor-owned `"MediaPipe Python"` package
- says the adapter still publishes `provider_id = mediapipe_python`
- says `camera_tracking_provider.gd` consumes `CameraTracking` instead of raw `MediaPipe server` payloads

Why it matters:
- the README still teaches readers to think about this repo in MediaPipe terms
- the strict target is that the repo should know only the tool contract

Recommended neutral replacements:
- describe the old state generically: “no longer the vendor-owned runtime package”
- describe session publication generically: “publishes a camera-tracking provider/session for input-core compatibility”
- describe frame ingestion generically: “consumes normalized tracking frames from `CameraTracking`”

Compatibility risk:
- low technical risk, high truthfulness/value risk; docs are currently preserving migration history at the cost of the new target

---

### 5) `plugin.cfg`

Current state:
- **no MediaPipe-branded wording remains**

Recommendation:
- no de-MediaPipe change required here beyond making sure the description stays tool-contract-only

---

## C. `.testbed/` proving/workbench surfaces

These are the biggest remaining concentration of MediaPipe naming/knowledge.

### 6) `.testbed/project.godot`

Remaining debt:
- `config/name="AeroBeat MediaPipe Testbed"`

Recommended replacement:
- `AeroBeat Camera Tracking Testbed`
- or `AeroBeat Camera Tracking Proving`

Risk:
- very low; purely workbench naming

---

### 7) `.testbed/tests/mocks/mock_mediapipe_server.py`

Remaining debt:
- filename contains `mediapipe`
- docstring/messages say `Mock MediaPipe server`

Recommended replacement:
- rename to something contract-neutral such as `mock_tracking_server.py` or `mock_camera_tracking_stream.py`
- update text to `Mock tracking server` / `Mock camera tracking stream`

Risk:
- low, but any scripts/tests referencing the old path must be updated atomically

---

### 8) `.testbed/tests/landmark_drawer.gd`
### 9) `.testbed/scripts/landmark_drawer.gd`

Remaining debt:
- comments say `Draws MediaPipe pose landmarks`
- one file also says `MediaPipe Pose connections`
- comments say `MediaPipe coordinates are normalized [0, 1]`

Recommended replacement:
- `Draws normalized pose landmarks and skeleton`
- `Pose connections`
- `Tracking coordinates are normalized [0, 1]`

Risk:
- none beyond keeping comments truthful

---

### 10) `.testbed/scripts/install_progress.gd`

Remaining debt:
- method calls/messages still speak in MediaPipe terms:
  - `check_mediapipe_installed()`
  - `MediaPipe found! Starting server...`
  - `MediaPipe not found. Installing...`

Why it matters:
- even if this file is legacy/stale, it remains in the repo and expresses MediaPipe-specific runtime ownership from this repo’s workbench

Recommended replacement:
- either remove this file if obsolete
- or rename the seam/messages around a neutral runtime/tool concept, e.g. `check_tracking_runtime_installed()` and `Tracking runtime found`

Risk:
- medium if the file is still live somewhere; needs a usage check during implementation

---

### 11) `.testbed/scripts/proving_harness.gd`

Remaining debt:
- preloads `MediaPipeConfigScript`
- vendor constants point directly at MediaPipe vendor repo/runtime assets:
  - `VENDOR_REPO_ROOT := "res://addons/aerobeat-vendor-mediapipe-python"`
  - `VENDOR_RUNTIME_ENTRYPOINT := "runtime/mediapipe_runtime_probe.py"`
- signal names/messages still reference MediaPipe:
  - `mediapipe_not_found`
  - `_on_mediapipe_not_found()`
  - status text `MediaPipe runtime missing - installing`
- environment variable `AEROBEAT_MEDIAPIPE_CAMERA_SOURCE`

Why it matters:
- this file is currently the main proving surface, and it still knows the vendor lane in detail instead of only the tool contract

Recommended replacement:
- preload/use `CameraTrackingConfigScript`
- prefer a tool-owned replay/live source seam rather than vendor-root runtime assembly in the harness
- rename status/signal handling to neutral tracking-runtime language
- rename env var to something neutral such as `AEROBEAT_CAMERA_TRACKING_SOURCE`

Important nuance:
- because the allowed vendor mount remains, the proving harness may still need *some* runtime bridge for local proving. But the strict target says this repo should not know or say MediaPipe at all. That means any remaining vendor-specific wiring should be pushed behind the tool repo or a neutral helper seam if possible.

Risk:
- high. This is the most cross-repo-sensitive cleanup area because it touches local proving, vendor prep, and runtime startup semantics.

---

### 12) `.testbed/scripts/boxing_proving_harness.gd`

Remaining debt:
- rewrites message text containing `MediaPipe runtime missing - installing`

Recommended replacement:
- update the string rewrite to the neutral status text chosen for the proving harness

Risk:
- low, assuming message changes happen consistently with the harness rename

---

### 13) `.testbed/scripts/capture_fixture_proving.gd`

Remaining debt:
- uses env var `AEROBEAT_MEDIAPIPE_CAMERA_SOURCE`
- writes report field from that env var

Recommended replacement:
- rename env var to a neutral camera-tracking name

Risk:
- medium if external capture scripts or local workflows export the old variable name

---

### 14) `.testbed/assets/videos/test_videos.py`

Remaining debt:
- comments and path logic reference `python_mediapipe`
- helper text says it can serve as a utility for the Python sidecar
- `test_with_sidecar_integration()` imports `MediaPipeServer`
- explanatory text repeatedly says `MediaPipe Python sidecar`

Why it matters:
- this file encodes old repo topology and vendor ownership assumptions directly inside this repo

Recommended replacement:
- either retire it if obsolete
- or rewrite it as a neutral video-fixture helper for camera-tracking proving
- if sidecar integration remains necessary, make it target a neutral tool-facing interface rather than importing MediaPipe-specific modules by name

Risk:
- medium/high if anyone still uses this utility for local proving

---

### 15) `.testbed/docs/proving-scene-human-verification-checklist.md`

Remaining debt:
- instructs running `python3 python_mediapipe/prepare_runtime.py ...`

Why it matters:
- even as a proving-only doc, this explicitly teaches MediaPipe/runtime ownership from this repo

Recommended replacement:
- point to the sibling vendor/tool repo’s current prep flow in neutral terms
- or say “prepare the mounted camera-tracking backend runtime separately” without naming MediaPipe here

Risk:
- medium documentation/workflow risk; if no replacement instruction is provided, human proving may become harder

---

### 16) `.testbed/tests/unit/test_input_provider_adapter.gd`

Remaining debt:
- asserts `provider_id == "mediapipe_python"`
- requests sessions with `session_key: "mediapipe_python"`
- expects metadata/provider id values `mediapipe_python`

Why it matters:
- this test codifies the current MediaPipe compatibility identifiers as intentional API truth

Recommended replacement:
- update assertions to the neutral provider/session id chosen for the repo

Risk:
- high only because this test will fail the moment the ids are renamed; technically straightforward

---

### 17) `.testbed/tests/unit/test_pose_detector_substrate.gd`

Remaining debt:
- preloads `src/config/mediapipe_config.gd`
- uses `MediaPipeConfig`

Recommended replacement:
- preload/use `src/config/camera_tracking_config.gd`
- optionally add `class_name CameraTrackingConfig` first to make the swap clean

Risk:
- medium due to preload/class-name dependency, but local to repo tests

---

### 18) `.testbed/tests/unit/test_proving_harness_trails.gd`

Remaining debt:
- asserts vendor root path `res://addons/aerobeat-vendor-mediapipe-python`
- asserts runtime entrypoint `runtime/mediapipe_runtime_probe.py`

Why it matters:
- the allowed vendor mount is okay, but this test goes beyond the mount and codifies the MediaPipe vendor repo/runtime filenames as required truth inside this repo

Recommended replacement:
- if the proving harness is refactored to consume only tool-facing/runtime-neutral facts, update the test to assert those neutral facts instead
- if some vendor-root prep remains unavoidable for the hidden workbench, minimize assertions to the existence of a mounted backend runtime contract rather than MediaPipe-specific path names

Risk:
- high because this crosses the repo boundary into the vendor runtime asset layout

---

## D. Allowed exception that should stay out of scope

### 19) `.testbed/addons.jsonc`

Contains:
- mount for `aerobeat-vendor-mediapipe-python`

Disposition:
- **allowed exception — not cleanup debt**

Reason:
- Derrick explicitly said this mount remains intentionally allowed because the hidden proving/workbench still needs to satisfy the sibling tool repo’s backend/runtime dependency for local proving/tests

Important note:
- the mount itself is allowed
- files in this repo that *talk about* that mount in MediaPipe-specific terms can still be cleanup debt

---

## Recommended neutral naming set

Use one naming set consistently across the repo.

### Public/input-facing names
- provider id: `camera_tracking`
- shared session key: `camera_tracking`
- addon alias/reference: `aerobeat-input-camera-tracking`
- config file: `src/config/camera_tracking_config.gd`
- config class: `CameraTrackingConfig`

### Proving/workbench names
- testbed title: `AeroBeat Camera Tracking Testbed`
- mock server: `mock_tracking_server.py`
- env var: `AEROBEAT_CAMERA_TRACKING_SOURCE`
- status text: `Tracking runtime missing - installing`
  - or, better, if the runtime truly belongs upstream: `Camera tracking backend not ready`

### Tool/backend selection
Preferred:
- input repo does **not** set a vendor backend id at all

Fallback if the tool layer still requires an explicit backend selector during transition:
- move the selector contract to the tool repo under a neutral name, not `mediapipe_python`

---

## Recommended rename / implementation order

Do this in order to minimize breakage.

### Phase 1 — make neutral config the only local config truth
1. Add `class_name CameraTrackingConfig` to `src/config/camera_tracking_config.gd` if desired.
2. Switch local loads/preloads in this repo from `mediapipe_config.gd` to `camera_tracking_config.gd`.
3. Update repo-local tests accordingly.
4. Only then remove `src/config/mediapipe_config.gd` or keep it as a temporary shim if serialized references require a staged step.

Why first:
- this is mostly repo-local and reduces one of the most visible MediaPipe names immediately.

### Phase 2 — rename repo-local public identifiers
1. Rename `PROVIDER_ID` / `SHARED_SESSION_KEY` in `src/input_provider.gd`.
2. Update `test_input_provider_adapter.gd` and any repo-local proving helpers.
3. Update README wording to stop documenting `mediapipe_python` as current truth.

Why second:
- these are the repo’s clearest outward-facing MediaPipe identifiers.

### Phase 3 — remove vendor backend selection from sharable `src/`
1. Refactor `src/providers/camera_tracking_provider.gd` so it no longer hardcodes `"backend": "mediapipe_python"`.
2. Push backend defaulting/resolution into `aerobeat-tool-camera-tracking` if needed.
3. Verify mounted backend resolution still works in proving/tests.

Why third:
- this is the highest-value architectural cleanup left in `src/`, but it likely needs sibling repo coordination.

### Phase 4 — neutralize `.testbed/` names/messages first
1. Rename project title, mock filename, comments, strings, env vars.
2. Update tests and scripts that reference those names.

Why fourth:
- mostly local churn; easier once the public names are settled.

### Phase 5 — remove `.testbed/` vendor-runtime knowledge where possible
1. Refactor proving harness/runtime helper seams away from `MediaPipe` names.
2. Reduce or eliminate direct assertions on vendor repo root and `mediapipe_runtime_probe.py` from this repo.
3. Keep the allowed `.testbed/addons.jsonc` vendor mount intact.

Why last:
- this is where cross-repo/runtime coupling is strongest.

---

## Cross-repo compatibility risks that need explicit handling

## 1) `input-core` / session-registry compatibility risk

If any consumer still requests:
- `provider_id = mediapipe_python`
- `session_key = mediapipe_python`

then renaming these values in this repo will break session discovery/acquisition unless those callers are updated together or a temporary compatibility bridge is added.

This is the biggest immediate behavior risk from the de-MediaPipe cleanup.

---

## 2) tool/backend resolution risk

`src/providers/camera_tracking_provider.gd` currently still asks for backend `mediapipe_python`.

If that key disappears from this repo before `aerobeat-tool-camera-tracking` has a neutral default-selection story, live camera start/replay proving may stop resolving a backend.

Explicit handling needed:
- either tool repo chooses the mounted/default backend without input naming it
- or tool repo exposes a neutral backend selector owned by the tool contract

---

## 3) vendor repo/runtime asset path risk in proving

The current proving harness/tests still know about:
- `aerobeat-vendor-mediapipe-python`
- `runtime/mediapipe_runtime_probe.py`
- pose-landmarker model filenames
- MediaPipe-not-found status/signals

If these references are removed blindly, local proving on the hidden workbench may lose its runtime prep/start path.

Explicit handling needed:
- confirm whether the tool repo can expose enough neutral runtime facts for proving
- if not, decide whether a small neutral helper seam belongs in the tool repo specifically for proving/runtime prep

---

## 4) assembly/addon alias risk

The comment in `src/input_provider.gd` still references `res://addons/aerobeat-input-mediapipe/`.

If any real consuming project still mounts this repo under an old alias/folder name, neutralizing names may require coordinated manifest/package/mount updates outside this repo.

---

## 5) Godot preload / serialized script reference risk

Renaming or removing `mediapipe_config.gd` can break:
- repo-local tests
- scenes/resources that preload the old path
- any serialized `.tscn` / `.tres` references outside the obvious grep surface

Implementation should include a quick repo-wide path/reference validation after the rename.

---

## Suggested implementation boundary

Safe to treat as straightforward repo-local cleanup:
- `README.md`
- `src/config/*` name cleanup
- `src/input_provider.gd` comments/loads once compatibility ids are decided
- `.testbed/project.godot` title
- `.testbed/tests/mocks/mock_mediapipe_server.py` rename
- landmark drawer comments
- proving/test strings/env vars/tests after coordinated plan

Needs explicit sibling-repo coordination before implementation:
- removal/rename of `mediapipe_python` provider/session/backend ids
- removal of backend selection from `camera_tracking_provider.gd`
- proving-harness runtime seams that currently reach into vendor-root paths and entrypoints

---

## Practical cleanup checklist

### Repo-local sure things
- [ ] stop loading/preloading `src/config/mediapipe_config.gd`
- [ ] remove `MediaPipeConfig` naming from repo-local code/tests
- [ ] remove MediaPipe wording from README
- [ ] rename `.testbed` project title
- [ ] rename mock/server/test utility files and user-facing messages/comments
- [ ] rename `AEROBEAT_MEDIAPIPE_CAMERA_SOURCE`

### Coordination-required items
- [ ] replace `PROVIDER_ID = mediapipe_python`
- [ ] replace `SHARED_SESSION_KEY = mediapipe_python`
- [ ] stop emitting `backend = mediapipe_python` from sharable `src/`
- [ ] remove proving-harness assumptions about vendor repo/runtime entrypoint names where possible

---

## Final recommendation

Treat this cleanup as **two slices**, not one:

1. **Repo-local naming cleanup**: config names, README, `.testbed` titles/messages/comments/mock/env-var names, local test assertions.
2. **Compatibility seam cleanup**: provider/session/backend identifiers and proving-harness runtime indirection, coordinated with `aerobeat-tool-camera-tracking` and any input-core/assembly consumers.

That split keeps implementation honest:
- slice 1 is mostly local and low-risk
- slice 2 is where the real compatibility risk lives

Done correctly, the end state becomes simple:

- this repo speaks only in **camera-tracking** terms
- `aerobeat-tool-camera-tracking` owns the service contract and backend selection story
- `aerobeat-vendor-mediapipe-python` can continue to exist as the mounted backend/runtime implementation without this repo naming it
