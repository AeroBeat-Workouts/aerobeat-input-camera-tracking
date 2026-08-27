# Repair Proving Camera Preview And Teardown

**Date:** 2026-08-27
**Status:** Planned / Deferred Behind Mobile Worker Test
**Agent:** cookie
**Umbrella Bead:** `oc-zfpu`
**Diagnostic Bead:** `oc-zfpu.1`
**Preview Repair Bead:** `oc-zfpu.2`
**Teardown Repair Bead:** `oc-zfpu.3`
**Real-Camera QA Bead:** `oc-zfpu.4`
**Final Audit Bead:** `oc-zfpu.5`
**Related Existing Beads:** `oc-in8x`, `oc-7pc`, `aerobeat-input-camera-tracking-r7m`
**Approval / Ordering:** Derrick requested the plan and Beads now, but explicitly selected the mobile web worker test as the next implementation slice.

## Goal

Restore truthful live webcam presentation and clean normal-editor teardown in the AeroBeat Input Camera Tracking Boxing and Flow proving scenes. The Python MediaPipe sidecar must feed visible preview frames while running and release its process and `/dev/video*` ownership during normal scene stop without requiring `kill-cameras.py`.

## Scope And Ownership

The user-facing reproduction lives in `aerobeat-input-camera-tracking/.testbed`, but durable fixes must land in the smallest actual owners:

- `aerobeat-input-camera-tracking`: proving harness, singleton facade, scene lifecycle and focused tests.
- `aerobeat-tool-camera-tracking`: vendor-neutral session/preview presenter only if attachment or descriptor consumption is faulty there.
- `aerobeat-vendor-mediapipe-python`: bridge/backend stop or preview descriptor only if runtime evidence proves the lower seam is faulty.

Do not patch generated `.testbed/addons/` mounts. Republish/restore with `~/.dsh/scripts/godotenv-sync` after owning-source changes.

Out of scope:

- gameplay detector tuning, web CV, model changes, replay transport unrelated to the live-camera failure, broad camera architecture rewrites, and documentation-only path replacement presented as a runtime fix.

## Debugging Report

### Exact Observed Failure

Derrick opened an AeroBeat input testbed scene in Godot and played it:

- no immediate startup error was visible;
- live webcam video did not appear;
- stopping scene playback did not stop webcam use;
- `kill-cameras.py` was invoked afterward, so absence of a surviving process after the fact is not clean-shutdown evidence.

### Expected Behavior

- Starting Boxing or Flow proving immediately displays the live camera once the sidecar publishes a valid preview.
- Presenter/readiness truth reflects actual attachment and visible texture/image state.
- Normal editor stop performs exactly one full scene-owned shutdown, stops the sidecar, releases `/dev/video*`, cleans the session, and permits a clean restart.

### Execution Path

1. Proving harness `_start_provider()` resolves the `AeroCameraTracking` singleton.
2. It ensures the tracking session and preview surface, then calls `start_live_camera()`.
3. `AeroCameraTracking` starts the vendor-neutral `CameraTracking` session/provider.
4. `MediaPipePythonCameraTrackingBackend.start()` invokes `MediaPipePythonRuntimeBridge.startup()`.
5. The Python runtime acquires V4L2, writes `preview_frame.jpg`, and updates `runtime_snapshot.json`.
6. `CameraTrackingPreviewPresenter` and proving harness are expected to bind the descriptor/image to the visible preview surface.
7. On scene exit, harness `_stop_everything()` calls `_clear_live_camera_runtime_state()`; singleton `shutdown_runtime()` should call `_stop_runtime(true, true)`, backend `stop()`, and bridge `shutdown()`.
8. Bridge shutdown writes a `stop` file, waits for exit, escalates only if necessary, and removes session files.

### Most Likely Root Causes

#### Preview

Recent saved testbed snapshots prove:

- sidecar startup succeeded;
- `/dev/video0` was acquired through CAP_V4L2;
- actual camera mode was MJPG 960×540 at roughly 15fps;
- `preview_frame.jpg` existed with advancing `image_revision`;
- descriptor was `enabled: true` but `attached: false`.

Leading cause: the presenter/session/surface binding or descriptor consumption path did not turn a healthy file-backed preview into a visible texture. This is not a Python camera-start failure.

#### Teardown

Recent saved sessions survived with no stop marker and final notes including:

- `Continuous MediaPipe runtime session exited because its owner process disappeared unexpectedly.`
- one run exited after `signal_15`, consistent with `kill-cameras.py`.

Clean bridge shutdown would create the stop marker and remove the session directory. Leading cause: normal editor scene teardown did not complete the bridge shutdown path, or entered it but aborted before the bridge handled the session.

### Alternative Hypotheses

1. **Lower bridge shutdown defect:** current blocked Bead `aerobeat-input-camera-tracking-r7m` records real-backend stop/SIGABRT behavior. Even a correct harness call may fail below it.
2. **Partial-start ownership mismatch:** harness `provider` may not reference the object that ultimately owns the active bridge during failure/exit.
3. **Notification timing/reentrancy:** `EXIT_TREE`/`PREDELETE` can call `_stop_everything()` repeatedly while nodes are disappearing, preventing a complete ordered shutdown.
4. **Image loader/presenter polling defect:** descriptor is valid but revision/path updates may never reach or refresh the texture.
5. **Old workspace paths:** low likelihood. Static search finds `~/.openclaw/workspace` in docs/README references, not active input/tool/vendor runtime logic. Vendor entrypoint and working directory derive from its mounted `res://` script path.

### Why Previous Fixes Failed

Commit `66db707` added:

- explicit `shutdown_runtime()` calling `_stop_runtime(true, true)`;
- harness use of that method for the singleton;
- contract preview readiness checks;
- preview presenter disconnect/free cleanup.

The fresh reproduction and saved artifacts show those changes did not guarantee actual attachment or a completed clean bridge shutdown. The earlier fix established intended calls and readiness shape but did not prove the real editor execution path and lower sidecar lifecycle end to end.

### Unknowns

- Whether `_is_contract_preview_ready()` ever becomes true in the failed run.
- Whether presenter session identity equals the actual active tracking session.
- Whether image revision polling reaches the presenter and texture assignment.
- Whether `_stop_everything()`, `shutdown_runtime()`, backend `stop()`, and bridge `shutdown()` execute, and in what order/count.
- Whether teardown aborts before or during bridge shutdown.
- Exact `/dev/video0` holder lifetime after normal stop without the kill helper.

### Minimal Reproduction

1. Restore the Camera Tracking testbed with the supported DSH GodotEnv helper.
2. Open the root `.testbed/project.godot` in Godot 4.6.2.
3. Play Boxing proving, observe blank preview while webcam activates.
4. Stop through the editor’s normal stop control.
5. Observe webcam ownership/sidecar state before invoking any cleanup helper.
6. Repeat Flow after the first causal fix to prove shared behavior.

### Proposed Verification

Before changing code, capture a single correlated timeline containing:

- harness provider/singleton/session/presenter instance IDs;
- descriptor `attached`, image path and revision;
- presenter bound-session identity and visible-surface texture state;
- sidecar PID and `/dev/video*` holder;
- entry/exit of each teardown function with invocation count;
- stop marker, final runtime snapshot note, process exit, directory cleanup, and camera release.

This distinguishes missed attachment from image production, and missed teardown dispatch from a lower bridge failure.

### Recommended Fix

Implement only after the diagnostic timeline identifies the failing seam:

- Preview: bind the presenter to the actual active session and make valid descriptor image revisions produce/refresh the preview texture; readiness must require that concrete truth.
- Teardown: make normal scene exit invoke one idempotent full-release path before ownership disappears; ensure backend/bridge shutdown completes and preserve the reusable generic `stop()` contract.
- If the lower bridge abort is causal, fix it in `aerobeat-vendor-mediapipe-python` rather than masking it in the harness.

### Debugging Record

```text
Problem: Godot proving camera captures but preview is blank and normal stop does not cleanly release the sidecar/camera.
Observed symptom: Valid preview JPEGs with attached=false; surviving sessions exit owner-disappeared or signal_15, not clean stop.
Root cause: Not yet final; leading seams are presenter/session attachment and incomplete normal-editor bridge shutdown.
Evidence: Recent app_userdata runtime snapshots, camera mode/preview revisions, no stop markers, source lifecycle tracing, prior 66db707 fix.
Failed approaches: Prior call-shape/readiness fix without real-editor end-to-end proof; old-workspace-path suspicion does not match active runtime source.
Corrective action: Instrument one correlated editor play/stop timeline, then repair only the proven presenter and teardown owners.
Verification test: Boxing + Flow visible live preview; normal stop releases /dev/video and sidecar, cleans session through stop marker, and restarts cleanly.
Related files/components: proving_harness.gd, AeroCameraTracking.gd, CameraTrackingPreviewPresenter, MediaPipePythonCameraTrackingBackend.gd, MediaPipePythonRuntimeBridge.gd.
Remaining uncertainty: Exact missed/aborted call and presenter refresh point.
```

## Tasks

### 1. Capture Execution Truth

**Bead:** `oc-zfpu.1`
**Status:** Ready after mobile worker work

Use the NPGameDev Godot MCP lifecycle when exposed; otherwise use normal editor controls plus screenshot/process/device evidence. Do not kill Godot or the sidecar as normal teardown. Add narrowly scoped temporary diagnostics or test hooks only when necessary and remove/noise-gate them before landing.

### 2. Repair Preview Attachment

**Bead:** `oc-zfpu.2`
**Status:** Blocked by diagnostic

- Fix the smallest proven owner.
- Add focused tests for session identity, descriptor/revision handling, texture attachment, truthful readiness, and missing/stale image behavior.
- Prove both Boxing and Flow display live video.

### 3. Repair Normal Scene Teardown

**Bead:** `oc-zfpu.3`
**Status:** Blocked by diagnostic

- Establish one idempotent scene-owned full shutdown.
- Prove stop reaches backend/bridge exactly once and survives repeated exit notifications.
- Verify stop marker/process exit/session cleanup/device release and clean re-entry.
- Preserve generic reusable `stop()` semantics outside scene teardown.

### 4. Real-Camera QA

**Bead:** `oc-zfpu.4`
**Status:** Blocked by both repairs

Run Boxing and Flow through start, visible preview/landmarks, normal stop, camera release, and re-entry. Capture console, screenshots, process/device holders, and session artifact truth. `kill-cameras.py` is recovery only and invalidates a normal-shutdown proof.

### 5. Independent Audit And Landing

**Bead:** `oc-zfpu.5`
**Status:** Blocked by QA

Audit owning-source edits, generated-addon hygiene, focused/full tests, real-camera proof, existing related Beads, commits/pushes, and final plan results. Close or supersede prior overlapping Beads only when their acceptance is genuinely satisfied.

## Validation

- Supported `~/.dsh/scripts/godotenv-sync --repo aerobeat-input-camera-tracking` convergence.
- Repo GUT suite from `.testbed` plus focused lifecycle/presenter tests.
- `godot --headless --path .testbed --import`/parse checks where safe, recognizing real-camera proof requires the editor.
- Normal editor `game_start`/`game_stop` through MCP when available; otherwise normal editor buttons with desktop proof.
- Source and all GodotEnv consumer repos clean after generated-state validation.
- Beads/Dolt and every touched Git repo pushed and clean.

## Results

Planning and definitive artifact diagnosis complete. Implementation intentionally deferred until the mobile MediaPipe worker test is planned and executed.
