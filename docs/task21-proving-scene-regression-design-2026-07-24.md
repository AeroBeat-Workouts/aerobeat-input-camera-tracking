# Task 21 — Proving-scene regression design packet

Date: 2026-07-24
Repo: `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking`
Scope: research/design only; no code changes landed

## Investigated files

- `.testbed/scripts/proving_harness.gd`
- `.testbed/scripts/boxing_proving_harness.gd`
- `.testbed/scenes/boxing_proving.tscn`
- `.testbed/scenes/flow_proving.tscn`
- `src/AeroCameraTracking.gd`
- `src/providers/camera_tracking_provider.gd`
- `src/input_provider.gd`
- `.testbed/tests/unit/test_boxing_proving_harness_profiles_and_debug.gd`
- upstream reference: `../aerobeat-tool-camera-tracking/src/CameraTracking.gd`
- upstream reference: `../aerobeat-tool-camera-tracking/src/CameraTrackingPreviewPresenter.gd`
- upstream reference: `../aerobeat-vendor-mediapipe-python/src/MediaPipePythonCameraTrackingBackend.gd`

## 1) Stale auto-calibration panel: remove outright vs move/repurpose

### What is actually on screen

The visible stale element is not a dead leftover node. It is the actively used `AthleteCalibrationPanel` surface from the proving scenes:

- scene-authored in `.testbed/scenes/boxing_proving.tscn`
- scene-authored in `.testbed/scenes/flow_proving.tscn`
- built/normalized/repositioned by `.testbed/scripts/proving_harness.gd`
- reparented from the old left-column button slot into the preview overlay by `_sync_calibration_overlay_parent()`

The recent T-pose auto-calibration change hid the old manual buttons but left the panel itself always alive and text-populated, because `_refresh_calibration_flow_ui()` now emits non-empty idle/cooldown/baseline strings. That is why the old footprint still appears as a large right-side overlay even though manual button-driven calibration is gone.

### Design conclusion

Do **not** remove the calibration surface outright.

Reason:
- the panel is still the only dedicated place that surfaces T-pose hold/cooldown/success/cancelled feedback
- unit coverage in `.testbed/tests/unit/test_boxing_proving_harness_profiles_and_debug.gd` already expects this information path to exist
- outright deletion would silently remove the only live user-facing explanation for auto-calibration state

### Narrowest product/UI fix

Repurpose it into a **contextual/transient status surface** instead of a persistent overlay.

Recommended contract:
- hidden when idle and no immediate operator action is needed
- visible during `holding`, `cooldown`, and for a short-lived success/cancelled message window
- not rendered as a permanent preview-obscuring panel while simply waiting for the first baseline or while a baseline is already active

Narrow seam:
- keep the existing `AthleteCalibrationPanel` ownership in `proving_harness.gd`
- add a small helper that decides panel visibility from calibration state
- reuse existing label text helpers where they are still useful
- do **not** spread this UI into unrelated systems

Secondary cleanup option if Derrick wants a harder cleanup:
- remove the authored `AthleteCalibrationPanel` nodes from both `.tscn` files and let `proving_harness.gd` create the panel only when needed
- this is a little wider than necessary and not required for the behavior fix

## 2) UNUSED_PARAMETER warning at `proving_harness.gd:608`

### Root cause

Current signature:
- `_calibration_status_text(state_name: String, session: Dictionary, has_baseline: bool) -> String`

Inside the current implementation, `session` is no longer read. The warning is real and local.

### Narrowest fix seam

Keep the call shape stable and rename the parameter to `_session`.

Why this is the narrowest seam:
- fixes the warning without widening into callsite churn
- preserves test and grep stability around the helper signature
- avoids unnecessary refactor noise in a file already carrying multiple active regressions

Alternative seam:
- remove the parameter entirely and update callsites
- functionally fine, but wider than needed for a warning-only cleanup

## 3) Live-preview startup regression

### What I could rule out

I did **not** find any code path where calibration state gates preview startup.

The preview path lives in:
- `_start_provider()`
- `_ensure_contract_preview_surface()`
- the `AeroCameraTracking` singleton session/provider path
- upstream `CameraTrackingPreviewPresenter`

The calibration UI/status helpers do not control preview start.

### Most relevant owning seams

#### Seam A — preview mount/start lifecycle in the proving harness

`_start_provider()` in `.testbed/scripts/proving_harness.gd` mounts/binds the preview presenter around the contract singleton start path.

#### Seam B — contract runtime readiness lies about being ready

`_await_live_camera_runtime_ready()` delegates to `_is_live_camera_runtime_ready()`.

For the contract path, `_is_live_camera_runtime_ready()` currently returns true when:
- `provider != null`
- `_resolve_camera_tracking_singleton() != null`

That does **not** prove any of the following:
- tracking session is running
- preview presenter is bound
- preview descriptor is populated
- preview texture is visible

So the harness currently treats the live camera runtime as ready much earlier than the preview is actually proven alive.

### Design conclusion

The evidence does **not** support Derrick’s calibration-gating suspicion.

The narrow, real preview-start seam is the proving harness’ contract readiness/mount truth, not the T-pose auto-calibration state machine.

### Recommended implementation path

Tighten contract-path readiness to require preview truth rather than wrapper existence.

Recommended readiness contract for the proving scenes:
- contract singleton exists
- tracking session exists
- preview presenter exists and is bound
- preview descriptor is no longer detached/empty, or the preview surface has a texture / non-empty image path

Best narrow seam:
- update `.testbed/scripts/proving_harness.gd` only
- strengthen `_is_live_camera_runtime_ready()` for the contract path
- optionally add a tiny local helper like `_is_contract_preview_ready()` rather than changing shared runtime contracts yet

Why keep it local first:
- the reported regression is proving-scene-specific
- this keeps the investigation from widening into upstream tool/vendor changes before the proving harness contract is validated

## 4) Shutdown/lifecycle regression: camera keeps running after leaving proving scenes

### Exact root cause

This seam is concrete.

When proving scenes stop/leave, they currently call generic provider-stop paths in `proving_harness.gd`:
- `_clear_live_camera_runtime_state()`
- `_stop_everything()`

In the contract path, `provider` is the `AeroCameraTracking` singleton wrapper, not the old direct provider.

The wrapper’s public `stop()` method calls:
- `AeroCameraTracking.stop()` -> `_stop_runtime(true)`

But `_stop_runtime(true)` intentionally **does not** release the owned tracking session unless `release_tracking_session` is explicitly true.

That means:
- wrapper/provider stop runs
- the underlying `CameraTracking` session can remain alive
- MediaPipe runtime ownership remains active
- the physical USB camera can stay on until external cleanup (`./kill-cameras.py`)

### Why this regressed

The proving harness teardown still assumes `provider.stop()` is enough, which was true for the older direct-provider lifecycle. After the wrapper/singleton migration, that assumption is no longer valid.

### Narrowest fix seam

Do **not** change the semantics of `AeroCameraTracking.stop()` globally.

Reason:
- current stop semantics appear intentionally reusable for other flows
- changing `stop()` to always release the tracking session would widen risk into other consumers

Instead, add/use an explicit full-teardown path for proving-scene exit.

Recommended implementation choices, in order:
1. Add a dedicated public method on `src/AeroCameraTracking.gd` for full scene teardown, e.g. `shutdown_runtime()` / `stop_and_release_tracking_session()` that calls `_stop_runtime(true, true)`.
2. In `.testbed/scripts/proving_harness.gd`, call that explicit full-release method from `_clear_live_camera_runtime_state()` and `_stop_everything()` when the provider is the contract singleton.
3. Keep generic `stop()` behavior untouched for non-proving consumers.

This is the cleanest narrow seam because it fixes the proving-scene lifecycle bug without redefining the wrapper’s general stop contract.

## Directly coupled validation before/with implementation

### Coder validation

1. Unit coverage around the proving harness calibration panel contract
   - panel hidden in idle/baseline-active states if the transient contract is chosen
   - panel visible with truthful text during `holding`, `cooldown`, and success/cancelled states

2. Warning cleanup proof
   - rerun the relevant headless test path and confirm `UNUSED_PARAMETER` is gone

3. Preview startup proof
   - add/adjust a proving-harness-focused test that fails unless the contract path reports ready only after preview truth is present
   - if unit-only proof is insufficient, add a tiny debug probe that asserts non-detached preview descriptor after scene start

4. Full teardown proof
   - prove that proving-scene exit now calls the explicit full-release singleton path
   - validate that the underlying tracking session is stopped/released, not just the wrapper/provider

### QA slice

Manual/high-fidelity QA in both:
- boxing proving scene
- flow proving scene

Checks:
- entering the scene starts live preview immediately without waiting for T-pose calibration
- no persistent stale panel obscures the preview at idle
- active T-pose hold/cooldown feedback still appears when relevant
- leaving the scene turns off the USB camera without requiring `./kill-cameras.py`
- re-entering the scene starts from a clean camera session state

### Auditor slice

Independent audit should verify:
- the fix stayed inside proving harness + explicit singleton teardown seam
- no global stop-contract drift was introduced accidentally
- preview-start evidence is real runtime truth, not just status text changes
- camera shutdown is proven by actual lifecycle behavior, not just absence of warnings

## Recommended next slices

### Next coder slice

Implement the narrow proving-scene contract:
- make calibration panel contextual/transient instead of persistent
- rename `session` -> `_session` in `_calibration_status_text`
- add a local contract-preview readiness helper in `proving_harness.gd`
- add an explicit full-release method in `src/AeroCameraTracking.gd`
- switch proving-harness teardown to that explicit full-release path when stopping the singleton

### Next QA slice

Run boxing/flow proving scenes end-to-end with a real USB camera and verify:
- preview appears on scene entry
- T-pose status appears only when relevant
- camera shuts off on scene exit and re-entry remains clean

### Next auditor slice

Truth-check the landed seam against:
- this design packet
- the final diff
- unit/runtime evidence
- actual stop-contract behavior in `AeroCameraTracking.gd`
