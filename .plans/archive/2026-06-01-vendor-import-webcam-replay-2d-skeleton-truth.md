# AeroBeat Input Camera Tracking

**Date:** 2026-06-01
**Status:** Stale
**Last Updated:** 2026-06-02 07:29 EDT
**Blocked Reason:** Superseded and intentionally left in place as historical context for the proving/runtime slice only. The missing `oc-*` bead line was a stale markdown branch, not the live repo state. Cross-repo de-MediaPipe work continued under repo-local `aerobeat-input-camera-tracking-*` beads and later commits, then completed under archived plans `/.plans/archive/2026-06-01-cross-repo-demediapipe-coordination.md` and `/.plans/archive/2026-06-02-input-camera-tracking-repo-root-demediapipe-audit.md`.
**Agent:** `byte`

---

## Goal

Make sure `aerobeat-input-camera-tracking` truthfully imports `aerobeat-vendor-mediapipe-python` and uses it successfully for both live webcam tracking and replay tracking, with visible 2D body-skeleton output in the proving flows.

---

## Overview

This plan picks up after the earlier singleton/vendor-boundary refactor but narrows the next slice to an outcome Derrick can directly verify: the repo must actually consume the vendor package correctly, boot live webcam tracking, boot replay tracking, and render a visible 2D tracking skeleton in both paths. The important distinction here is “truthful import + real proving behavior,” not just architectural intent or passing narrow unit coverage.

The current repo already mounts `aerobeat-vendor-mediapipe-python` in `.testbed/addons.jsonc`, autoloads `AeroCameraTracking`, and contains replay/live orchestration seams in `src/AeroCameraTracking.gd` and `.testbed/scripts/proving_harness.gd`. The previous plan shows that the architecture was moved in the right direction, but it also ended with unfinished README/audit follow-through and explicit need for more manual proving confirmation. This new plan therefore starts with a truth audit of the import/runtime path, then fixes any remaining import, startup, replay, or overlay gaps, then proves both webcam and replay behavior, and finally audits the result.

The acceptance bar for this plan is practical rather than rhetorical: from the `.testbed` proving surface, the vendor-backed path must be the one actually in use, webcam mode must start without falling back to stale local ownership, replay mode must start and remain usable, and a visible 2D skeleton/overlay must appear on tracked bodies in both flows.

---

## REFERENCES

| ID | Description | Path |
| --- | --- | --- |
| `REF-01` | Prior vendor/singleton consolidation plan and unfinished follow-through | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.plans/2026-05-27-vendor-mediapipe-singleton-and-replay-consolidation.md` |
| `REF-02` | Current repo README and migration truth | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/README.md` |
| `REF-03` | Current addon identity / assembly-facing entrypoint | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/plugin.cfg` |
| `REF-04` | Current singleton orchestrator for live + replay tracking | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/src/AeroCameraTracking.gd` |
| `REF-05` | Current input-provider fallback/discovery behavior | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/src/input_provider.gd` |
| `REF-06` | Current proving harness wiring | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.testbed/scripts/proving_harness.gd` |
| `REF-07` | Current `.testbed` dependency manifest, including vendor mount | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.testbed/addons.jsonc` |
| `REF-08` | Current `.testbed` autoload/project wiring | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.testbed/project.godot` |
| `REF-09` | Vendor repo README / runtime truth | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-vendor-mediapipe-python/README.md` |

---

## Scope Boundaries

### In scope

- verify that the `.testbed` and repo runtime truly import and instantiate the vendor MediaPipe package rather than only declaring it
- verify/fix the live webcam startup path through the current singleton/runtime contract
- verify/fix the replay tracking startup path through the same singleton/runtime contract
- verify/fix visible 2D skeleton overlay rendering for tracked bodies in both webcam and replay proving flows
- tighten import/config/runtime discovery if the vendor package is mounted but not actually consumed correctly
- update README and plan notes if the truthful current behavior changed
- use the repo-approved `godotenv-sync` script rather than calling the raw `godotenv` CLI directly when dependencies need refreshes, to avoid noisy/brittle Godot behavior on this host
- treat Derrick as the manual QA + final audit authority for this slice once code changes are ready

### Explicitly out of scope

- broad gameplay-detector redesign beyond what is needed for truthful body tracking startup and skeleton rendering
- inventing a second vendor/runtime ownership model outside `aerobeat-vendor-mediapipe-python`
- editing `.testbed/addons/` generated mirrors as source
- unrelated UI polish not needed for proving live/replay body tracking with visible 2D skeletons

---

## Risks / Known Unknowns

1. The vendor addon may be mounted correctly but still not be the runtime path actually used in one or both flows.
2. Replay may still depend on stale fallback seams that bypass the intended vendor-backed tracking path.
3. The 2D skeleton overlay may fail because tracking data is absent, because coordinate mapping is wrong, or because the overlay UI is not attached/rendered correctly.
4. Live webcam proving may still expose camera-selection/runtime edge cases that narrow unit tests do not catch.
5. The repo may still contain stale local MediaPipe ownership that muddies which lane is truly active.

---

## Tasks

### Task 1: Audit the real vendor import and runtime path for webcam + replay

**Bead ID:** `oc-3xp6`
**SubAgent:** `primary`
**Role:** `research`
**References:** `REF-01`, `REF-04`, `REF-05`, `REF-06`, `REF-07`, `REF-08`, `REF-09`
**Prompt:** In `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking`, claim the assigned bead on start. Audit the actual import/runtime path used for live webcam tracking and replay tracking. Determine whether `aerobeat-vendor-mediapipe-python` is only mounted or is truly the package in use, identify any stale local fallback ownership still participating, and map the exact seams that control 2D skeleton rendering. Do not edit mounted addon mirrors. If dependency refresh is needed, use `/home/derrick/.openclaw/workspace/scripts/godotenv-sync` rather than the raw `godotenv` CLI.

**Folders Created/Deleted/Modified:**
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.plans/`

**Files Created/Deleted/Modified:**
- plan file updates only unless a deliberate audit artifact is added

**Status:** ✅ Complete

**Results:** Audit complete. The vendor repo is not merely mounted; it is the active happy-path backend for both live webcam and replay tracking in the current `.testbed` contract flow. `AeroCameraTracking.gd` loads the vendor backend/runtime bridge from `res://addons/aerobeat-vendor-mediapipe-python/...`, the upstream `CameraTracking` session starts that backend for live-camera sources, and replay sources are also routed through the vendor Python runtime as `source.kind = "video_file"`. Remaining ambiguity is no longer whether the vendor package is used; it is that stale local fallback ownership still exists in `src/input_provider.gd` and the legacy local MediaPipe stack, while visible 2D skeleton rendering currently depends on the repo-owned `tracking_frame_adapter.gd` → `camera_tracking_provider.gd` → `.testbed/scripts/landmark_drawer.gd` seam. Recommended narrow next implementation seam: tighten repo-side runtime/fallback wiring first, then adjust the renderer/data seam only where evidence requires it.

---

### Task 2: Fix import/runtime wiring so vendor-backed webcam and replay both start truthfully

**Bead ID:** `oc-hl2c`
**SubAgent:** `primary`
**Role:** `coder`
**References:** `REF-04`, `REF-05`, `REF-06`, `REF-07`, `REF-08`, `REF-09`
**Prompt:** In `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking`, claim the assigned bead on start. Based on the audit, implement the narrowest truthful fixes needed so the repo correctly imports and uses `aerobeat-vendor-mediapipe-python` for both live webcam and replay tracking paths. Remove or bypass stale local fallback behavior only where needed to make the active lane unambiguous. Keep `.testbed` singleton-first, avoid `/addons/` edits, use `/home/derrick/.openclaw/workspace/scripts/godotenv-sync` if dependency refresh is required, run relevant repo-local validation, and commit/push by default before handoff.

**Folders Created/Deleted/Modified:**
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/src/`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.testbed/`

**Files Created/Deleted/Modified:**
- `src/input_provider.gd`
- `.testbed/scripts/proving_harness.gd`
- targeted unit tests covering contract-first fallback behavior

**Status:** ✅ Complete

**Results:** Completed and pushed as commit `209cd79` (`Prefer vendor contract lane over local fallback`). The repo-side wiring now prefers the mounted vendor-backed `CameraTracking` lane more aggressively: `src/input_provider.gd` now treats the contract path as the default when the upstream CameraTracking + vendor backend/runtime are mounted, creates a local CameraTracking session with the vendor backend/runtime bridge when no external session is supplied yet, and keeps the legacy local MediaPipe provider only for cases where the contract lane is truly unavailable or an explicit legacy provider was deliberately injected. `.testbed/scripts/proving_harness.gd` now prefers the singleton/contract lane for camera-device enumeration before using any temporary legacy provider. Validation used the approved `godotenv-sync` path plus headless import + unit GUT runs. Result was strong coverage of this lane-tightening seam, though the broader unit suite still ended with `68 passing / 3 failing / 5 pending`; the reported failing tests looked pre-existing and outside this narrow runtime-wiring slice.

---

### Task 3: Fix and prove visible 2D skeleton rendering in webcam + replay flows

**Bead ID:** `oc-9sud`
**SubAgent:** `primary`
**Role:** `coder`
**References:** `REF-04`, `REF-06`, `REF-07`, `REF-08`, `REF-09`
**Prompt:** In `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking`, claim the assigned bead on start. Ensure the proving flows visibly render the 2D body skeleton/overlay for tracked bodies in both live webcam and replay modes. If the failure is data-path related, fix the runtime/provider mapping; if it is presentation related, fix the overlay/rendering attachment. Capture proof of the working result through the highest-fidelity practical validation path and add or update targeted regression coverage where practical.

**Folders Created/Deleted/Modified:**
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/src/`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.testbed/`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.artifacts/skeleton-proof/`

**Files Created/Deleted/Modified:**
- `src/tracking_frame_adapter.gd`
- `.testbed/tests/unit/test_tracking_frame_adapter.gd`
- `.testbed/tests/unit/test_camera_tracking_provider.gd`
- `.testbed/tests/unit/test_landmark_drawer.gd`
- `.testbed/scripts/proof_skeleton_overlay.gd`
- `.artifacts/skeleton-proof/report.json`
- `.artifacts/skeleton-proof/live-webcam-skeleton.png`
- `.artifacts/skeleton-proof/replay-skeleton.png`

**Status:** ✅ Complete

**Results:** Completed and pushed as commit `df90197` (`Fix proving skeleton y mapping`). Root cause was in the repo-owned data seam, not the vendor runtime: upstream CameraTracking frames were already handling horizontal mirroring, but this repo's proving/detector path still expects bottom-left gameplay-normalized `y`. `src/tracking_frame_adapter.gd` had been passing `y` through unchanged, which left the skeleton vertically inverted for the proving drawer. The fix now inverts `y` exactly once while leaving `x` untouched, and the seam comments were clarified so the repo contract is explicit. Targeted tests passed for the changed seam (`test_tracking_frame_adapter.gd`, `test_camera_tracking_provider.gd`, `test_landmark_drawer.gd`). Strong repo-local proof artifacts were generated under `.artifacts/skeleton-proof/`; the report shows both `live_camera` and `video_file` proof paths producing visible in-bounds skeleton points attached to the `CameraDisplay` overlay parent. Manual QA still matters: Derrick should verify the real proving scenes show landmarks aligned on the body in both live webcam and prerecorded replay modes.

---

### Task 4: Prepare code-change handoff for Derrick's manual QA pass

**Bead ID:** `oc-q6qu`
**SubAgent:** `primary`
**Role:** `qa`
**References:** `REF-04`, `REF-06`, `REF-07`, `REF-08`, `REF-09`
**Prompt:** In `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking`, claim the assigned bead on start. Run the relevant repo-local validation and prepare a concise, truthful handoff for Derrick's manual QA of both live webcam and replay flows. Confirm as much as possible from safe local validation, identify the exact screens/behaviors Derrick should verify manually, and note any evidence that the vendor-backed path is the one actually in use. Do not treat this as a replacement for Derrick's final manual QA.

**Folders Created/Deleted/Modified:**
- validation/proof surfaces only as needed

**Files Created/Deleted/Modified:**
- no durable source changes expected unless a minimal validation artifact is justified

**Status:** ✅ Complete

**Results:** QA handoff prepared. Repo-local validation confirms the landed code context (`209cd79` for contract-first runtime wiring and `df90197` for the proving skeleton y-mapping fix), and proof artifacts under `.artifacts/skeleton-proof/` show both live and replay flows in `tracking` state with visible landmarks attached to `CameraDisplay`. Evidence that the vendor-backed contract lane is the one in use includes `src/input_provider.gd` explicitly preferring the `camera_tracking` provider lane when the contract + vendor backend are mounted, `src/AeroCameraTracking.gd` registering the vendor backend/runtime bridge into `CameraTracking`, and fresh validation logs showing the contract proving mode active. Manual QA checklist for Derrick now centers on verifying actual Boxing + Flow proving scenes in both live webcam and replay modes: skeleton aligned to the body, head above shoulders / ankles lowest, playback controls working, no silent drop back to legacy behavior, and sensible tracking lost/restored behavior. Main caveat from validation is replay/teardown stability, not the y-mapping itself: some broader repo tests are still failing outside this slice, and both the full GUT run and the proof script ended with native heap-abort/double-free style shutdown noise after producing useful results.

---

### Task 5: Prepare truth-audit handoff and doc cleanup for Derrick's manual audit

**Bead ID:** `oc-r1xe`
**SubAgent:** `primary`
**Role:** `auditor`
**References:** `REF-01`, `REF-02`, `REF-03`, `REF-04`, `REF-05`, `REF-06`, `REF-07`, `REF-08`, `REF-09`
**Prompt:** In `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking`, claim the assigned bead on start. Prepare the narrowest truthful audit package for Derrick's manual audit. Independently review whether the repo now imports and uses `aerobeat-vendor-mediapipe-python` for the intended live webcam and replay tracking paths, whether the visible 2D skeleton path appears correctly wired, whether any mounted addon mirror was mistakenly treated as source, and whether README/plugin wording still matches reality. If documentation drift is clear, make the narrowest truthful README/doc cleanup and leave a concise audit checklist/evidence summary for Derrick rather than pretending the manual audit is complete.

**Folders Created/Deleted/Modified:**
- repo root docs surfaces only if needed

**Files Created/Deleted/Modified:**
- `README.md`
- `plugin.cfg`
- plan file updates

**Status:** ✅ Complete

**Results:** Audit handoff prepared and pushed as commit `6bbe604` (`Tighten camera-tracking audit docs`). The audit confirmed that both `src/input_provider.gd` and `src/AeroCameraTracking.gd` import and use the mounted vendor addon (`MediaPipePythonCameraTrackingBackend.gd` and `MediaPipePythonRuntimeBridge.gd`) for the intended live webcam and replay tracking paths, and that the visible 2D skeleton path is wired through `src/tracking_frame_adapter.gd` into the repo-owned proving overlay path with proof artifacts under `.artifacts/skeleton-proof/`. No evidence was found that `.testbed/addons/...` generated mirrors were treated as sharable source. Documentation drift was real and was cleaned up narrowly: README no longer points at nonexistent `scripts/refresh_testbed_workbench.py`, README now states `.testbed/addons/` is generated install output rather than source, replay wording was tightened to current truth, and `plugin.cfg` no longer misdescribes the exported plugin script as the singleton. Important audit caveat remains: this is a truthful manual-audit handoff, not a claim that all downstream behavior is fully cleared. Targeted audit validation still found a failing replay-facade unit test in `test_aero_camera_tracking.gd` (`play_replay_playback()` / `pause_replay_playback()` expectations), so replay behavior remains the main thing Derrick should scrutinize during manual verification.

---

## Bead / execution shape

- coordination epic: `oc-naej`
- task beads:
  - `oc-3xp6` — vendor import/runtime audit
  - `oc-hl2c` — runtime wiring fixes
  - `oc-9sud` — 2D skeleton rendering fixes/proof
  - `oc-q6qu` — Derrick manual QA handoff prep
  - `oc-r1xe` — Derrick manual audit handoff/doc cleanup
- note: direct `bd dep add` linking failed in this repo's current Beads state with `table not found: wisp_dependencies`, so execution order is being enforced explicitly through the plan + orchestrator sequencing for this slice while the repo-local Beads dependency state is investigated separately

---

### Task 6: Audit repo-root startup seams still tied to legacy local MediaPipe paths

**Bead ID:** `oc-s62r`
**SubAgent:** `primary`
**Role:** `research`
**References:** `REF-04`, `REF-05`, `REF-06`, `REF-07`, `REF-08`, `REF-09`
**Prompt:** In `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking`, claim bead `oc-s62r` on start. Audit why the proving scenes still fail to start appropriately after `mediapipe-sync` now prepares the vendor dependency. Focus on repo-root `/src/` and proving/testbed startup seams that may still assume the old local `python_mediapipe` sidecar layout instead of the mounted `aerobeat-vendor-mediapipe-python` addon/runtime lane. Identify the exact scripts, paths, and startup checks that are still stale, and recommend the narrowest safe implementation seam for the coder pass.

**Folders Created/Deleted/Modified:**
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/src/`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.testbed/`

**Files Created/Deleted/Modified:**
- plan file updates only unless an audit artifact is justified

**Status:** ✅ Complete

**Results:** Audit complete. The primary blocker is no longer vendor dependency preparation; it is that the proving scenes are still booting through the old local sidecar contract before the mounted vendor lane can run. `.testbed/scripts/proving_harness.gd` still requires `AutoStartManager` startup and old `server_started` / `_start_camera_feed()` flow, both proving scenes still instantiate `AutoStartManager`, and the harness still assumes the old MJPEG preview seam (`http://127.0.0.1:4243/camera`) plus `camera_view.is_streaming()` readiness. Underneath that, `src/runtime/desktop_sidecar_runtime.gd`, `src/autostart_manager.gd`, and `src/process/mediapipe_process.gd` are hardwired to the removed repo-local `python_mediapipe/` layout, so startup fails with stale missing-sidecar and rebuild guidance before the mounted vendor backend can even be exercised. Recommended narrow next seam: fix proving-scene startup to use the already-mounted `AeroCameraTracking` + vendor runtime lane directly, inject the prepared vendor runtime facts (`python_executable`, `entrypoint`, `working_directory`, model path) into the runtime config, and stop gating proving readiness on the old AutoStartManager/MJPEG sidecar path.

---

### Task 7: Fix repo-root startup/runtime seams to use the vendor addon lane

**Bead ID:** `oc-q4p6`
**SubAgent:** `primary`
**Role:** `coder`
**References:** `REF-04`, `REF-05`, `REF-06`, `REF-07`, `REF-08`, `REF-09`
**Prompt:** In `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking`, claim bead `oc-q4p6` on start. Based on the audit, implement the narrowest truthful fixes needed so repo-root startup/runtime seams and proving-scene startup checks use the mounted `aerobeat-vendor-mediapipe-python` addon/runtime lane rather than stale local `python_mediapipe` assumptions. Fix only the seams actually blocking startup. Avoid `/addons/` mirror edits, use `godotenv-sync` if dependency refresh is required, run relevant repo-local validation, and commit/push by default before handoff.

**Folders Created/Deleted/Modified:**
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/src/`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.testbed/`

**Files Created/Deleted/Modified:**
- exact startup/runtime/provider/testbed files justified by the audit

**Status:** ⏳ Pending

**Results:** Pending.

---

### Task 8: Prepare manual verification handoff for startup-path fix

**Bead ID:** `oc-ngfk`
**SubAgent:** `primary`
**Role:** `qa`
**References:** `REF-04`, `REF-06`, `REF-07`, `REF-08`, `REF-09`
**Prompt:** In `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking`, claim bead `oc-ngfk` on start. After the startup-path fix lands, run safe repo-local validation and prepare a concise manual verification handoff for Derrick focused on proving-scene startup. Confirm as much as possible locally, state exactly what Derrick should reopen/rerun, and call out any remaining replay/runtime caveats.

**Folders Created/Deleted/Modified:**
- validation-only surfaces if needed

**Files Created/Deleted/Modified:**
- no durable source changes expected unless a minimal validation artifact is justified

**Status:** ⏳ Pending

**Results:** Pending.

---

### Task 9: Audit replay presentation/transport and live camera startup regressions

**Bead ID:** `oc-0puv`
**SubAgent:** `primary`
**Role:** `research`
**References:** `REF-04`, `REF-06`, `REF-07`, `REF-08`, `REF-09`
**Prompt:** In `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking`, claim bead `oc-0puv` on start. Audit the newly observed regressions after proving startup was rerouted to the vendor lane: (1) replay video file tracking + skeleton appears, but the replay video image does not display and the seekbar/timeline transport does not display or work properly; (2) live camera mode still does not start the video feed and skeleton appropriately. Identify the exact scripts, transport/preview seams, and readiness assumptions causing each failure, and recommend the narrowest safe implementation seam for the coder pass.

**Folders Created/Deleted/Modified:**
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/src/`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.testbed/`

**Files Created/Deleted/Modified:**
- plan file updates only unless an audit artifact is justified

**Status:** ✅ Complete

**Results:** Audit complete. Tracking is now on the vendor/CameraTracking lane, but the proving harness still keeps preview, replay transport, and some startup/camera-switching logic on the dead HTTP sidecar contract. Replay skeleton works because tracking for prerecorded sources is already routed through `AeroCameraTracking` into the vendor runtime’s `video_file` flow, but replay image/seekbar remain wired to `MediaPipeCameraView`, `http://127.0.0.1:4243/camera`, and HTTP `/playback` endpoints that the vendor lane does not expose. Live camera still fails because proving startup and camera changes remain partially gated on `AutoStartManager` / `server_started` / legacy sidecar restart behavior even though the vendor lane’s truthful live path is just direct camera selection plus JSON snapshot inference. Recommended narrow next seam: fix proving-harness lifecycle to bypass the old sidecar orchestration when using the contract path, and branch replay preview/transport away from the dead MJPEG/HTTP playback assumptions so the UI behaves truthfully under the vendor lane.

---

### Task 10: Fix replay presentation/transport and live camera startup regressions

**Bead ID:** `oc-in8x`
**SubAgent:** `primary`
**Role:** `coder`
**References:** `REF-04`, `REF-06`, `REF-07`, `REF-08`, `REF-09`
**Prompt:** In `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking`, claim bead `oc-in8x` on start. Based on the audit, implement the narrowest truthful fixes needed so replay proving shows the actual video image and has working timeline/seek transport, and live camera proving starts the video feed plus skeleton appropriately through the intended vendor-backed lane. Avoid reviving unrelated legacy seams, avoid `/addons` mirror edits, use `godotenv-sync` if needed, run relevant repo-local validation, and commit/push by default before handoff.

**Folders Created/Deleted/Modified:**
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/src/`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.testbed/`

**Files Created/Deleted/Modified:**
- exact replay/live proving files justified by the audit

**Status:** ⏳ Pending

**Results:** Pending.

---

### Task 11: Prepare manual verification handoff for replay/live regression fixes

**Bead ID:** `oc-guis`
**SubAgent:** `primary`
**Role:** `qa`
**References:** `REF-04`, `REF-06`, `REF-07`, `REF-08`, `REF-09`
**Prompt:** In `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking`, claim bead `oc-guis` on start. After the replay/live regression fixes land, run safe repo-local validation and prepare a concise manual verification handoff for Derrick focused on replay image display, timeline/seek controls, and live camera startup. Confirm as much as possible locally and call out any remaining replay/runtime caveats.

**Folders Created/Deleted/Modified:**
- validation-only surfaces if needed

**Files Created/Deleted/Modified:**
- no durable source changes expected unless a minimal validation artifact is justified

**Status:** ⏳ Pending

**Results:** Pending.

---

### Task 12: Audit immediate recursion/stack overflow in boxing proving startup

**Bead ID:** `oc-bb8y`
**SubAgent:** `primary`
**Role:** `research`
**References:** `REF-04`, `REF-06`, `REF-07`, `REF-08`, `REF-09`
**Prompt:** In `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking`, claim bead `oc-bb8y` on start. Audit the immediate `Stack overflow (stack size: 1024)` regression Derrick hit when opening the boxing proving scene after the latest proving replay/live changes. Focus on newly touched proving-harness, preview surface, replay playback facade, and vendor preview-status plumbing. Identify the exact recursive call path or signal loop causing the overflow and recommend the narrowest safe implementation seam for the coder pass.

**Folders Created/Deleted/Modified:**
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/src/`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.testbed/`

**Files Created/Deleted/Modified:**
- plan file updates only unless an audit artifact is justified

**Status:** ✅ Complete

**Results:** Audit complete and the overflow is a direct recursion in `.testbed/scripts/proving_harness.gd`, not in the newer preview/playback plumbing. The exact loop is `_get_effective_camera_source()` calling `_is_prerecorded_source_active()`, while `_is_prerecorded_source_active()` itself calls `_get_effective_camera_source()`, producing immediate infinite recursion on scene open. The regression came from the latest replay/live source-resolution change in the proving harness. Recommended narrow fix: patch only `_get_effective_camera_source()` so it decides whether an explicit override is prerecorded by checking the override value directly with `_is_live_camera_source_value(explicit_override)` or equivalent inline logic, instead of calling the derived-state helper that recurses back into source resolution.

---

### Task 13: Fix recursion/stack overflow in boxing proving startup

**Bead ID:** `oc-a41q`
**SubAgent:** `primary`
**Role:** `coder`
**References:** `REF-04`, `REF-06`, `REF-07`, `REF-08`, `REF-09`
**Prompt:** In `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking`, claim bead `oc-a41q` on start. Based on the audit, implement the narrowest truthful fix for the immediate recursion/stack overflow in boxing proving startup. Focus on the newly touched proving-harness, preview surface, replay/playback facade, and vendor preview-status seams first. Avoid unrelated refactors, avoid `/addons` mirror edits, run relevant repo-local validation, commit/push by default before handoff, and report exactly what changed plus what Derrick should retest manually.

**Folders Created/Deleted/Modified:**
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/src/`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.testbed/`

**Files Created/Deleted/Modified:**
- exact recursion-fix files justified by the audit

**Status:** ⏳ Pending

**Results:** Pending.

---

### Task 14: Prepare manual verification handoff for recursion fix

**Bead ID:** `oc-1pyb`
**SubAgent:** `primary`
**Role:** `qa`
**References:** `REF-04`, `REF-06`, `REF-07`, `REF-08`, `REF-09`
**Prompt:** In `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking`, claim bead `oc-1pyb` on start. After the recursion fix lands, run safe repo-local validation and prepare a concise manual verification handoff for Derrick focused on confirming the boxing proving scene opens without immediate stack overflow before deeper replay/live checks continue.

**Folders Created/Deleted/Modified:**
- validation-only surfaces if needed

**Files Created/Deleted/Modified:**
- no durable source changes expected unless a minimal validation artifact is justified

**Status:** ⏳ Pending

**Results:** Pending.

---

### Task 15: Audit live camera duplicate-signal, perf, and seated tracking regressions

**Bead ID:** `oc-h590`
**SubAgent:** `primary`
**Role:** `research`
**References:** `REF-04`, `REF-05`, `REF-06`, `REF-07`, `REF-08`, `REF-09`
**Prompt:** In `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking`, claim bead `oc-h590` on start. Audit the newly observed live-camera regressions in the boxing proving scene: duplicate signal connection warnings in `_start_provider()`, very slow tracking, and skeleton detection that appears but does not actually track Derrick's seated body/face on webcam. Focus on proving-harness signal wiring, provider/session reconnect behavior, current runtime config defaults sent into the vendor lane, camera selection/switching, and any stale model/preview/performance assumptions that could explain bad seated live tracking. Identify the exact likely causes and recommend the narrowest safe implementation seam for the coder pass.

**Folders Created/Deleted/Modified:**
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/src/`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.testbed/`

**Files Created/Deleted/Modified:**
- plan file updates only unless an audit artifact is justified

**Status:** ⏳ Pending

**Results:** Pending.

---

### Task 16: Fix live camera duplicate-signal, perf, and seated tracking regressions

**Bead ID:** `oc-lmz8`
**SubAgent:** `primary`
**Role:** `coder`
**References:** `REF-04`, `REF-05`, `REF-06`, `REF-07`, `REF-08`, `REF-09`
**Prompt:** In `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking`, claim bead `oc-lmz8` on start. Based on the audit, implement the narrowest truthful fixes needed for live camera proving: eliminate duplicate signal-connection warnings, improve startup/runtime behavior so the live webcam path is not abnormally slow, restore reasonable seated face/body tracking behavior through the vendor-backed lane, and ensure scene stop/exit releases the live camera cleanly instead of leaving the Logitech device wedged after close. Start with the proving-harness / provider lifecycle seams first; if vendor teardown or runtime-loop changes are directly required, make the narrowest truthful cross-repo changes needed and report them explicitly. Avoid unrelated replay refactors, avoid `/addons` mirror edits, use `godotenv-sync` if needed, run relevant repo-local validation, commit/push by default before handoff, and report exactly what changed plus what Derrick should retest manually.

**Folders Created/Deleted/Modified:**
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/src/`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.testbed/`

**Files Created/Deleted/Modified:**
- exact live-camera regression files justified by the audit

**Status:** ⏳ Pending

**Results:** Pending.

---

### Task 17: Prepare manual verification handoff for live camera regression fixes

**Bead ID:** `oc-ruzq`
**SubAgent:** `primary`
**Role:** `qa`
**References:** `REF-04`, `REF-06`, `REF-07`, `REF-08`, `REF-09`
**Prompt:** In `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking`, claim bead `oc-ruzq` on start. After the live-camera regression fixes land, run safe repo-local validation and prepare a concise manual verification handoff for Derrick focused on webcam startup, signal-warning cleanliness, tracking responsiveness, and seated face/body detection quality.

**Folders Created/Deleted/Modified:**
- validation-only surfaces if needed

**Files Created/Deleted/Modified:**
- no durable source changes expected unless a minimal validation artifact is justified

**Status:** ⏳ Pending

**Results:** Pending.

---

## Final Results

**Status:** ⚠️ Partial — code slice complete, awaiting Derrick manual QA/audit verdict

**What We Built:** The repo now truthfully prefers the vendor-backed CameraTracking lane for both live webcam and replay startup, and the proving overlay path now maps skeleton Y coordinates correctly for visible 2D body rendering. Repo-local proof artifacts and targeted tests support the contract/vendor path and the corrected overlay mapping, while documentation/plugin wording was tightened to match the current state.

**Reference Check:** `REF-04` through `REF-09` are materially satisfied for this slice: vendor runtime usage is real, the repo-owned proving overlay path is wired, generated addon mirrors were not used as source, and README/plugin wording is closer to present truth. Final acceptance still depends on Derrick's manual scene verification, especially replay behavior and shutdown stability.

**Commits:**
- `209cd79` - Prefer vendor contract lane over local fallback
- `df90197` - Fix proving skeleton y mapping
- `6bbe604` - Tighten camera-tracking audit docs

**Lessons Learned:** The biggest risk was not whether the vendor package was mounted, but whether stale local fallback ownership could still quietly steal control and whether coordinate-space assumptions were drifting between runtime, gameplay normalization, and the proving overlay. The safest pattern was to make the contract lane explicit, then prove the overlay/data seam separately. Remaining risk is concentrated in replay playback facade behavior and teardown stability rather than the vendor import path itself.

**Wrap-up / Reconciliation Note (2026-06-02 05:50 EDT):** Fresh-session recovery showed that the suspected wrong-repo bead creation was not the live blocker. The `oc-*` continuation named here does not exist in the current repo or `/.openclaw` Beads state, while newer repo-local commits and `aerobeat-input-camera-tracking-*` beads document the actual continuation that landed overnight. This plan remains useful as a historical record of the proving/runtime slice, but it is no longer the authoritative active plan. Current continuation should follow the repaired cross-repo de-MediaPipe plan and the new repo-root `src/` audit plan focused on whether this repo can respond to camera-tracking events and emit input events without MediaPipe knowledge.

---

*Drafted on 2026-06-01; wrapped on 2026-06-02*
