# AeroBeat Input Camera Tracking

**Date:** 2026-05-27  
**Status:** Stale  
**Last Updated:** 2026-05-27 19:24 EDT  
**Blocked Reason:** Session wrap-up while awaiting Derrick's next manual `.testbed` verification pass on the latest proving-scene fixes  
**Agent:** `cookie`

---

## Goal

Finish the split so `aerobeat-input-camera-tracking` consumes a truthful vendor-owned MediaPipe sidecar from `aerobeat-vendor-mediapipe-python`, replaces its remaining repo-root MediaPipe ownership with a repo-owned `AeroCameraTracking.gd` singleton, and routes live + replay proving through that singleton with GodotEnv-managed dependencies in `.testbed/`.

---

## Overview

This plan treats the current repo as mid-refactor rather than cleanly migrated. Prior work established the platform direction: vendor runtime truth belongs in `aerobeat-vendor-mediapipe-python`, lifecycle/public tracking contract belongs upstream, and `aerobeat-input-camera-tracking` should consume tracking frames and expose gameplay-facing Boxing + Flow interpretation. Memory check confirms the split repos were created for exactly that boundary, and also confirms that donor-sidecar parity in the vendor repo was intentionally left as an acceptance gate rather than assumed finished. Source: `memory/2026-05-21.md#L2-L6`, `memory/2026-05-22.md#L1-L10`.

The likely regression Derrick reported fits that history: this repo still contains `python_mediapipe/` at the repo root while `.testbed/` also mounts `aerobeat-vendor-mediapipe-python`, so runtime ownership may be split or partially duplicated. The proving harness also still constructs `AeroVideoPlayerManager` directly and still contains local MediaPipe-oriented bootstrapping seams, which conflicts with the target architecture where replay/live coordination should flow through a repo-owned singleton surface.

A second important truth from Derrick: the public Boxing/Flow gesture events and public tracking-update events are still immature and not yet accuracy-complete. This plan should therefore treat event surfacing and singleton wiring as the priority, while keeping detection correctness scoped to truthful current behavior rather than pretending the gesture layer is already production-accurate.

This plan therefore proceeds in five layers: first audit vendor parity vs the old local sidecar; second redesign this repo around a singleton named `src/AeroCameraTracking.gd`; third rewire `.testbed/` to consume only GodotEnv-managed dependencies and route replay/live through that singleton; fourth keep all fixture-heavy proving/testing apparatus under `.testbed/` rather than repo-root addon surfaces; fifth run coder validation, README cleanup, and a narrowed audit, with Derrick explicitly handling any live MediaPipe scene QA that risks the Zorin shutdown/playback crash path.

---

## REFERENCES

| ID | Description | Path |
| --- | --- | --- |
| `REF-01` | Prior repo boundary decisions for the platform split | `memory/2026-05-21.md#L2-L6` |
| `REF-02` | Prior downstream status + explicit donor-sidecar parity gate | `memory/2026-05-22.md#L1-L10` |
| `REF-03` | Current repo README and truthful migration status | `/home/derrick/Documents/projects/aerobeat/aerobeat-input-camera-tracking/README.md` |
| `REF-04` | Current proving harness still mixing local MediaPipe, CameraTracking, and direct video-player ownership | `/home/derrick/Documents/projects/aerobeat/aerobeat-input-camera-tracking/.testbed/scripts/proving_harness.gd` |
| `REF-05` | Current `.testbed` dependency manifest | `/home/derrick/Documents/projects/aerobeat/aerobeat-input-camera-tracking/.testbed/addons.jsonc` |
| `REF-06` | Current `.testbed` autoloads/project config | `/home/derrick/Documents/projects/aerobeat/aerobeat-input-camera-tracking/.testbed/project.godot` |
| `REF-07` | Upstream `CameraTracking` singleton contract | `/home/derrick/Documents/projects/aerobeat/aerobeat-tool-camera-tracking/src/CameraTracking.gd` |
| `REF-08` | Tool video-player public manager surface | `/home/derrick/Documents/projects/aerobeat/aerobeat-tool-video-player/src/AeroVideoPlayerManager.gd` |
| `REF-09` | Vendor repo current sidecar/runtime scope | `/home/derrick/Documents/projects/aerobeat/aerobeat-vendor-mediapipe-python/README.md` |
| `REF-10` | Prior replay adapter plan in this repo | `/home/derrick/Documents/projects/aerobeat/aerobeat-input-camera-tracking/.plans/2026-05-22-gesture-testbed-replay-adapter-compat-slice.md` |

---

## Scope Boundaries

### In scope

- verify whether `aerobeat-vendor-mediapipe-python` contains the sidecar/runtime pieces this repo still depends on
- identify and remove remaining repo-root `python_mediapipe/` ownership from `aerobeat-input-camera-tracking` once vendor parity is truly present
- add a repo-owned singleton `src/AeroCameraTracking.gd` that is the single public control surface for live-camera and replay tracking in this repo
- expose listener/signal surfaces from `AeroCameraTracking.gd` for tracking updates, Boxing events, and Flow events, with truthful current behavior even if detection accuracy is still incomplete
- make `.testbed/` consume `tool-video-player` and other dependencies through GodotEnv-managed addon mounts only
- refactor proving scenes/harnesses so replay uses the singleton surface instead of directly constructing `AeroVideoPlayerManager`
- keep fixture videos, fixture YAMLs, and related proving/testing apparatus inside `.testbed/` so repo-root addon consumers do not import them into future assembly builds
- update the repo README as an explicit final task once the refactor state is truthful
- use `godotenv-sync` when dependency refreshes are needed; never treat `/addons/` as an editing surface

### Explicitly out of scope

- editing generated/mounted dependency mirrors in `.testbed/addons/`
- inventing a second vendor-side MediaPipe lifecycle outside `aerobeat-vendor-mediapipe-python`
- broad gameplay detector redesign beyond what is necessary to route through the singleton
- risky/destructive live-scene QA automation for MediaPipe shutdown paths that Derrick explicitly wants to handle manually

---

## Risks / Known Unknowns

1. `aerobeat-vendor-mediapipe-python` may still be missing donor-sidecar pieces from the old local `python_mediapipe/` tree.
2. This repo may currently depend on local sidecar files in hidden ways beyond the obvious proving harness references.
3. Replay ownership may currently be split between this repo’s `AeroMediaPipeReplayPlaybackBackend.gd`, `AeroVideoPlayerManager`, and `CameraTracking` session config.
4. Public Boxing/Flow event surfacing may need to be created or normalized before the singleton can present a stable outward-facing API, even though gesture accuracy itself remains intentionally provisional.
5. `.testbed/project.godot` currently does not autoload a repo-owned tracking singleton, so scene/runtime wiring needs a contract decision.
6. Live MediaPipe QA remains partially human-gated because normal shutdown paths can still tickle Zorin/Godot crash bugs if playback is not stopped carefully.

---

## Tasks

### Task 1: Audit vendor-sidecar parity and map removal seams

**Bead ID:** `aerobeat-input-camera-tracking-9ec`  
**SubAgent:** `primary`  
**Role:** `research`  
**References:** `REF-02`, `REF-03`, `REF-04`, `REF-05`, `REF-09`, `REF-10`  
**Prompt:** In `/home/derrick/Documents/projects/aerobeat/aerobeat-input-camera-tracking`, and cross-checking `/home/derrick/Documents/projects/aerobeat/aerobeat-vendor-mediapipe-python`, claim the bead on start. Produce a truth-based parity inventory between this repo’s remaining local MediaPipe sidecar/runtime ownership and the vendor repo’s current implementation. Identify exactly which files/functions/config/runtime assets still block removing `python_mediapipe/` from this repo, and identify all places in this repo that still depend on that local ownership. Do not edit `/addons/`. If dependency refresh is needed, use `/home/derrick/.openclaw/workspace/scripts/godotenv-sync` plus repo-local refresh scripts rather than direct addon edits.

**Folders Created/Deleted/Modified:**
- `/home/derrick/Documents/projects/aerobeat/aerobeat-input-camera-tracking/.plans/`
- possible notes under repo-local temp/docs if needed

**Files Created/Deleted/Modified:**
- plan file updates only unless a parity inventory artifact is intentionally added

**Status:** ✅ Complete

**Results:** Completed via research subagent. Audit verdict: this repo is not yet safe to delete local `python_mediapipe/`. The contract/vendor lane is real in `camera_tracking_provider.gd`, `tracking_frame_adapter.gd`, and the proving harness’s backend registration, but a live local legacy lane still remains through `src/input_provider.gd` fallback behavior, local runtime/process/server/autostart ownership, local MJPEG preview assumptions, `.testbed` AutoStartManager seams, direct fixture/test imports from repo-local `python_mediapipe`, and tests that still assert local-sidecar behavior. The vendor repo already covers a meaningful backend/runtime bridge lane, but it does not yet replace the legacy provider surface, prepared-runtime packaging flow, local preview HTTP/MJPEG transport, model-complexity parity, or local autostart/install UX. That means vendor parity must be tightened first, then input-camera-tracking can remove fallback/local ownership safely behind `AeroCameraTracking.gd`.
---

### Task 2: Implement missing vendor-sidecar parity in `aerobeat-vendor-mediapipe-python`

**Bead ID:** `avmp-14a`  
**SubAgent:** `primary`  
**Role:** `coder`  
**References:** `REF-02`, `REF-09`  
**Prompt:** In `/home/derrick/Documents/projects/aerobeat/aerobeat-vendor-mediapipe-python`, claim the bead on start. Based on the parity inventory, implement the narrowest truthful vendor-sidecar/runtime additions needed so `aerobeat-input-camera-tracking` no longer needs to own the old local `python_mediapipe/` stack. Keep lifecycle/public-service ownership boundaries strict: vendor repo owns vendor/runtime/sidecar truth, not the higher-level gameplay singleton. Run repo-local validation, commit, and push before handoff unless blocked.

**Folders Created/Deleted/Modified:**
- `/home/derrick/Documents/projects/aerobeat/aerobeat-vendor-mediapipe-python/src/`
- `/home/derrick/Documents/projects/aerobeat/aerobeat-vendor-mediapipe-python/runtime/`
- other vendor-owned runtime folders only if truly needed

**Files Created/Deleted/Modified:**
- vendor runtime/bridge/config files as required by parity inventory
- plan file updates if the input repo tracks cross-repo outcome notes

**Status:** ✅ Complete

**Results:** Completed in `aerobeat-vendor-mediapipe-python` and pushed as commit `adc5175` (`Add model complexity parity to vendor runtime`). The vendor runtime/config lane now truthfully supports `runtime.model_complexity` with explicit lite/full/heavy model filename mapping, clamps/normalizes complexity values, respects complexity-specific default model lookup, and no longer silently falls back from requested full/heavy defaults to lite. Validation passed in both Python runtime-probe tests and vendor GUT coverage. Important caveat: this adds config/runtime parity, but does not supply missing full/heavy `.task` assets; downstream must either provide those assets or use explicit override paths when requesting complexity `1` or `2`.

---

### Task 3: Add `src/AeroCameraTracking.gd` singleton and remove local sidecar ownership from this repo

**Bead ID:** `aerobeat-input-camera-tracking-0b4`  
**SubAgent:** `primary`  
**Role:** `coder`  
**References:** `REF-03`, `REF-04`, `REF-05`, `REF-06`, `REF-07`, `REF-08`, `REF-10`  
**Prompt:** In `/home/derrick/Documents/projects/aerobeat/aerobeat-input-camera-tracking`, claim the bead on start. Implement a repo-owned singleton at `src/AeroCameraTracking.gd` as the single surface used by this repo/testbed to start and stop live or replay tracking. It must expose listener/signal surfaces for tracking updates and for Boxing/Flow gesture events, but it should do so truthfully for the repo’s current state rather than pretending gesture detection is already accurate/finished. Coordinate the required upstream services instead of the proving scenes instantiating them directly. Once vendor parity exists, remove the old repo-root local MediaPipe sidecar ownership from this repo. Keep dependency consumption via GodotEnv-managed mounts in `.testbed/`, never by editing `.testbed/addons/` mirrors.

**Folders Created/Deleted/Modified:**
- `/home/derrick/Documents/projects/aerobeat/aerobeat-input-camera-tracking/src/`
- `/home/derrick/Documents/projects/aerobeat/aerobeat-input-camera-tracking/.testbed/`
- `/home/derrick/Documents/projects/aerobeat/aerobeat-input-camera-tracking/scripts/`

**Files Created/Deleted/Modified:**
- `/home/derrick/Documents/projects/aerobeat/aerobeat-input-camera-tracking/src/AeroCameraTracking.gd`
- `/home/derrick/Documents/projects/aerobeat/aerobeat-input-camera-tracking/.testbed/project.godot`
- `/home/derrick/Documents/projects/aerobeat/aerobeat-input-camera-tracking/.testbed/scripts/proving_harness.gd`
- boxing/flow proving scene scripts as needed
- legacy local sidecar files/directories once removal is truly safe

**Status:** ✅ Complete

**Results:** Completed in `aerobeat-input-camera-tracking` and pushed as commit `6144e84` (`Add repo-owned AeroCameraTracking singleton`). Added `src/AeroCameraTracking.gd` as the repo-owned high-level start/stop surface for live webcam and replay/video-file tracking, with truthful re-emitted tracking/session/detector signals including Boxing + Flow gesture events. `.testbed/project.godot` now autoloads the singleton, `boxing_proving.tscn` and `flow_proving.tscn` no longer own scene-local `CameraTracking` nodes, and `.testbed/scripts/proving_harness.gd` now uses the singleton for orchestration. `src/input_provider.gd` was tightened to prefer `/root/AeroCameraTracking` session discovery before falling back to older local discovery. Targeted impacted tests passed, while the full suite still reports one pre-existing failure outside this slice in `test_mediapipe_provider.gd`. Local legacy ownership still remains in `src/providers/mediapipe_provider.gd`, `python_mediapipe/`, and replay/preview-era seams such as `autostart_manager.gd`, `camera_view.gd`, and `AeroMediaPipeReplayPlaybackBackend.gd`.
---

### Task 4: Rewire `.testbed` replay/live proving to consume the singleton and GodotEnv dependencies only

**Bead ID:** `aerobeat-input-camera-tracking-hy8`  
**SubAgent:** `primary`  
**Role:** `coder`  
**References:** `REF-04`, `REF-05`, `REF-06`, `REF-07`, `REF-08`, `REF-10`  
**Prompt:** In `/home/derrick/Documents/projects/aerobeat/aerobeat-input-camera-tracking`, claim the bead on start. Update `.testbed` so the Boxing + Flow proving scenes use `AeroCameraTracking.gd` for both live and replay flows. Replay should not independently create its own `AeroVideoPlayerManager`; it should use the singleton’s exposed replay functionality. Keep the fixture-heavy proving/testing apparatus under `.testbed/` only: fixture videos, fixture YAMLs, and related harness/test assets should stay out of repo-root addon surfaces so future assembly consumers do not import them. Ensure dependencies remain declared in `.testbed/addons.jsonc` and refreshed via `/home/derrick/.openclaw/workspace/scripts/godotenv-sync` plus repo-local sync/refresh scripts instead of direct addon edits.

**Folders Created/Deleted/Modified:**
- `/home/derrick/Documents/projects/aerobeat/aerobeat-input-camera-tracking/.testbed/`

**Files Created/Deleted/Modified:**
- `.testbed/addons.jsonc`
- `.testbed/project.godot`
- `.testbed/scenes/boxing_proving.tscn`
- `.testbed/scenes/flow_proving.tscn`
- `.testbed/scripts/proving_harness.gd`
- `.testbed/assets/fixtures/`
- related tests

**Status:** ⏳ Pending

**Results:** Completed in `aerobeat-input-camera-tracking` and pushed as commit `10b8dfb` (singleton-first replay/live `.testbed` proving migration). `AeroCameraTracking.gd` now owns replay playback facade methods, and `.testbed/scripts/proving_harness.gd` now delegates replay control through the singleton in the normal autoload path. Targeted replay/singleton proving tests passed. A narrow fallback playback manager/backend remained only for non-autoload compatibility, but Derrick later explicitly approved removing that fallback entirely in a follow-on bead.

---

### Task 4b: Remove `proving_harness.gd` fallback replay/video-player ownership

**Bead ID:** `aerobeat-input-camera-tracking-2p5`  
**SubAgent:** `primary`  
**Role:** `coder`  
**References:** `REF-04`, `REF-05`, `REF-06`, `REF-08`  
**Prompt:** In `/home/derrick/Documents/projects/aerobeat/aerobeat-input-camera-tracking`, claim bead `aerobeat-input-camera-tracking-2p5` on start. Derrick explicitly approved removing the remaining fallback replay/video-player ownership from `.testbed/scripts/proving_harness.gd`; the `.testbed` project no longer needs a backup path for missing singleton/autoload contexts. Make the proving harness singleton-required for the normal `.testbed` flow, remove fallback playback manager/backend ownership, update affected tests, run relevant repo-local validation, and commit/push by default.

**Folders Created/Deleted/Modified:**
- `/home/derrick/Documents/projects/aerobeat/aerobeat-input-camera-tracking/.testbed/`

**Files Created/Deleted/Modified:**
- `.testbed/scripts/proving_harness.gd`
- affected tests under `.testbed/tests/`

**Status:** ✅ Complete

**Results:** Completed in `aerobeat-input-camera-tracking` and pushed as commit `d65bba7` (`Require proving harness singleton playback contract`). `.testbed/scripts/proving_harness.gd` no longer owns a local fallback replay playback manager/backend, replay control is now singleton-only through `AeroCameraTracking`, `_resolve_camera_tracking_session()` is singleton-only, and provider startup now fails fast with a clear error if the singleton is missing instead of creating a local fallback lane. Targeted import + GUT validation passed for the affected harness/singleton tests, with the known separate Godot/GUT shutdown abort still occurring after passing assertions.
---

### Task 4c: Examine `test_mediapipe_provider.gd` and repair or retire it based on singleton relevance

**Bead ID:** `aerobeat-input-camera-tracking-bur`  
**SubAgent:** `primary`  
**Role:** `coder`  
**References:** `REF-03`, `REF-04`, `REF-07`  
**Prompt:** In `/home/derrick/Documents/projects/aerobeat/aerobeat-input-camera-tracking`, claim bead `aerobeat-input-camera-tracking-bur` on start. Inspect `.testbed/tests/unit/test_mediapipe_provider.gd` and determine whether its testing logic is uniquely valuable and still appropriate for this repo after the singleton migration. Only repair/adapt it to singleton-backed behavior if the test covers behavior this repo should still own. If the test is stale legacy-lane coverage that should not survive the migration, retire or replace it truthfully instead of forcing it through the singleton. Run relevant validation and commit/push by default.

**Folders Created/Deleted/Modified:**
- `/home/derrick/Documents/projects/aerobeat/aerobeat-input-camera-tracking/.testbed/`

**Files Created/Deleted/Modified:**
- `.testbed/tests/unit/test_mediapipe_provider.gd`
- related tests/files only if justified by the evaluation

**Status:** ⏳ Pending

**Results:** Completed in `aerobeat-input-camera-tracking` and pushed as commit `8c5ef4c` (`Retire stale legacy MediaPipe provider test`). Verdict: `.testbed/tests/unit/test_mediapipe_provider.gd` was stale legacy-lane coverage and should not survive the singleton-first migration. It was retired rather than adapted because its useful assertions are now more truthfully covered by `test_pose_detector_substrate.gd`, `test_camera_tracking_provider.gd`, `test_aero_camera_tracking.gd`, and `test_input_provider_adapter.gd`. `test_mediapipe_provider_camera_switch_reset.gd` was intentionally retained because it still covers a real provisional local fallback seam. Follow-on test fix commit `7b1a61f` then repaired `test_proving_harness_trails.gd` to use a singleton-first fake-backed camera session, eliminating dependency on real camera hardware or startup timing for that assertion.

---

### Task 5: Automated validation + Derrick-run MediaPipe scene QA gate

**Bead ID:** `aerobeat-input-camera-tracking-x4a`  
**SubAgent:** `primary` for automated validation; Derrick for live-scene MediaPipe QA  
**Role:** `qa`  
**References:** `REF-03`, `REF-04`, `REF-05`, `REF-06`, `REF-09`, `REF-10`  
**Prompt:** For the automated portion, in `/home/derrick/Documents/projects/aerobeat/aerobeat-input-camera-tracking`, claim the bead on start and run repo-local validation that does not require risky live MediaPipe scene shutdown behavior. Refresh dependencies via `godotenv-sync` and the repo’s workbench refresh path, then run targeted/unit/headless checks for singleton wiring, replay routing, and vendor-backed startup assumptions. Record the exact manual QA handoff Derrick needs to perform for live MediaPipe scenes, and do not automate the dangerous final stop/playback sequence Derrick explicitly reserved.

**Folders Created/Deleted/Modified:**
- validation-only surfaces as needed

**Files Created/Deleted/Modified:**
- no durable source changes expected unless a minimal test/handoff artifact is needed

**Status:** ✅ Complete

**Results:** Automated validation completed cleanly: repo-local workbench refresh used the approved `godotenv-sync` + `refresh_testbed_workbench.py` path, and the full `.testbed` GUT suite passed `75/75` tests / `369` asserts before the known ignorable Godot 4.6 shutdown-abort noise. Derrick then ran the manual `.testbed` QA gate and reported three real product issues: (1) Boxing replay loads but does not autoplay, even though that scene should autoplay replay clips; (2) the visible replay timeline bar is not vertically centered with the other playback controls; and (3) tracking landmarks/overlay dots+lines are not showing in either replay or live camera proving. Those findings unblock the plan from 'waiting for QA' and create a new approved bug-fix seam inside the same plan.

---

### Task 5b: Fix QA-found replay autoplay, playback-bar alignment, and missing landmark overlays

**Bead ID:** `aerobeat-input-camera-tracking-uvt`  
**SubAgent:** `primary`  
**Role:** `coder`  
**References:** `REF-04`, `REF-05`, `REF-06`, `REF-07`, `REF-08`, `REF-10`  
**Prompt:** In `/home/derrick/Documents/projects/aerobeat/aerobeat-input-camera-tracking`, claim bead `aerobeat-input-camera-tracking-uvt` on start. Derrick's manual `.testbed` QA surfaced three concrete issues to fix within the approved plan: (1) Boxing replay loads but does not autoplay, even though the proving replay scene should autoplay; (2) the visible replay timeline/playback bar is not vertically centered with the other playback controls; and (3) tracking landmarks/overlay dots+lines do not appear in either replay or live camera proving. Fix those product issues in the narrowest truthful way, keep `.testbed` singleton-first, avoid `/addons/` edits, run relevant validation, and commit/push by default.

**Folders Created/Deleted/Modified:**
- `/home/derrick/Documents/projects/aerobeat/aerobeat-input-camera-tracking/.testbed/`
- `/home/derrick/Documents/projects/aerobeat/aerobeat-input-camera-tracking/src/`

**Files Created/Deleted/Modified:**
- `.testbed/scripts/proving_harness.gd`
- `.testbed/scenes/boxing_proving.tscn`
- `.testbed/scenes/flow_proving.tscn`
- `src/AeroCameraTracking.gd`
- related overlay/playback tests as needed

**Status:** ✅ Complete

**Results:** Completed in `aerobeat-input-camera-tracking` and pushed as commit `9927b62` (`Fix proving replay autoplay and overlays`). Root causes/fixes: (1) boxing replay was loading the singleton playback source with `autoplay: false`, so the proving replay never started on first load; `src/AeroCameraTracking.gd` now loads replay playback with `autoplay: true`; (2) the playback bar row host used a shorter fixed height than the control row, which left the visible timeline slightly off-center; `.testbed/scripts/proving_harness.gd` now centers the row using a matched control-row height constant; (3) landmark/trail overlays were not being re-established robustly as full-rect visible overlay controls in the proving harness runtime, so live/replay dots+lines could disappear after the camera surface swap path; the harness now explicitly reconfigures overlay drawers as full-rect top overlays and added regression coverage around that setup. The follow-on live-camera switch spam about missing replay playback controller was also fixed in the same seam by making live-camera visibility teardown stop calling the singleton-required replay unload path. Validation: targeted GUT runs for `test_proving_harness_trails.gd` and `test_aero_camera_tracking.gd` passed; the known Godot/GUT shutdown-abort noise still appears after passing assertions. Subsequent manual QA showed this seam was not fully done: warnings still appear in the proving scenes, landmarks/trails still are not visibly rendering in the real scenes, Boxing proving remains stuck at `Waiting for Boxing Gestures`, one-shot singleton/camera-switch failure is still visible, the playback row became horizontally squashed even though vertical centering improved, and prerecorded replay can spam `Python server died` on first load.

---

### Task 5c: Fix remaining proving-scene QA bugs with desktop-control screenshot proof

**Bead ID:** `aerobeat-input-camera-tracking-xko`  
**SubAgent:** `primary`  
**Role:** `coder`  
**References:** `REF-04`, `REF-05`, `REF-06`, `REF-07`, `REF-08`, `REF-10`  
**Prompt:** In `/home/derrick/Documents/projects/aerobeat/aerobeat-input-camera-tracking`, claim bead `aerobeat-input-camera-tracking-xko` on start. Continue the same approved proving-scene fix seam using Derrick's latest manual QA feedback and prove any visual fixes with desktop-control screenshots captured from the actual running scene. Current bugs to fix: (1) Boxing proving scene warnings visible in-editor/log UI, likely mirrored in Flow; (2) landmarks/trails still do not visibly render in real replay/live proving and the next attempt must be proven with a screenshot showing replay overlays actually visible; (3) Boxing proving never leaves `Waiting for Boxing Gestures`; (4) live-camera switching still shows a one-shot `[ProvingHarness] AeroCameraTracking singleton is required for .testbed proving flows` and in-game `Live camera switch failed`; (5) the playback row is now horizontally squashed even though vertically centered; and (6) prerecorded playback can spam `[ProvingHarness][Boxing] Python server died | src=...` on first load. Important QA constraint: if you use desktop-control / Godot scene QA for proof, close scenes/editor through the aero-tool-headless-manager singleton / safe Godot scene-exit path rather than ad-hoc termination so MediaPipe exits safely. Avoid `/addons/` edits, keep `.testbed` singleton-first, add/update targeted tests where practical, run relevant validation, and commit/push by default.

**Folders Created/Deleted/Modified:**
- `/home/derrick/Documents/projects/aerobeat/aerobeat-input-camera-tracking/.testbed/`
- `/home/derrick/Documents/projects/aerobeat/aerobeat-input-camera-tracking/src/`

**Files Created/Deleted/Modified:**
- `.testbed/scripts/proving_harness.gd`
- `.testbed/scenes/boxing_proving.tscn`
- `.testbed/scenes/flow_proving.tscn`
- `src/AeroCameraTracking.gd`
- targeted tests and proof artifacts as needed

**Status:** ✅ Complete

**Results:** Completed in `aerobeat-input-camera-tracking` and pushed as commit `2be2119` (`Fix proving-scene singleton replay and overlay wiring`). Root causes/fixes: (1) visible proving warnings came from repo-owned GDScript warning sites and were cleaned up with typed/renamed locals and minor script hygiene; (2) overlays were still absent in real proving because singleton replay runtime was starting without a valid `pose_landmarker_model_path`, provider ingestion only reacted to backend signals instead of polling between updates, and the proving scenes still had trails disabled; the fix propagated the resolved model asset path, added provider polling, enabled trails, and added singleton pose passthrough helpers; (3) Boxing proving stayed at `Waiting for Boxing Gestures` because tracked replay frames/events were not actually making it through the singleton/provider path, which the runtime/model-path + polling fix restored; (4) live-camera switching still showed a one-shot singleton failure because `_clear_live_camera_runtime_state()` queue-freed the `AeroCameraTracking` autoload during teardown, so the next switch saw a missing singleton; the fix preserves the singleton instance during teardown; (5) the playback row was horizontally squashed because it sat inside a `CenterContainer` that collapsed width to minimum size, so the row now fills width directly; and (6) prerecorded playback was still polling sidecar health as if replay were a live-camera sidecar failure, which caused the first-load `Python server died` spam, so sidecar-health polling is now limited to actual live-camera flows. Validation: full unit GUT suite passed `75/75`; the fix pass also confirmed headless boxing replay state `running`, replay state `playing`, `TRACKING_FRAME` populated, and `LANDMARKS=33`. Desktop-control screenshot proof was obtained at `/home/derrick/.openclaw/workspace/.temp/proof/boxing-proof-window-4.png`, showing replay overlays visible and boxing events detected. Remaining manual QA: Derrick should still verify live-camera switching on actual hardware and run a focused Flow proving pass, though both now share the repaired harness/provider/runtime path.

---

### Task 6: Update the repo README to reflect the truthful post-refactor state

**Bead ID:** `aerobeat-input-camera-tracking-cqo`  
**SubAgent:** `primary`  
**Role:** `coder`  
**References:** `REF-03`, `REF-04`, `REF-05`, `REF-06`, `REF-07`, `REF-08`, `REF-09`, `REF-10`  
**Prompt:** In `/home/derrick/Documents/projects/aerobeat/aerobeat-input-camera-tracking`, claim the bead on start. Update `README.md` as an explicit final documentation task after the implementation shape is truthful. It should explain the repo-owned `AeroCameraTracking.gd` singleton, the current status of tracking-update and Boxing/Flow public event surfacing, the fact that gesture detection accuracy is still provisional, the vendor/runtime ownership boundary, and that fixture-heavy proving assets live under `.testbed/` rather than the repo-root addon surface.

**Folders Created/Deleted/Modified:**
- `/home/derrick/Documents/projects/aerobeat/aerobeat-input-camera-tracking/`

**Files Created/Deleted/Modified:**
- `README.md`

**Status:** ⏸️ Deferred

**Results:** Deferred for the next session. The implementation seam moved faster than the documentation/audit follow-through, and Derrick asked to land the plane after the latest proving-scene fix pass. README still needs a truthful update once Derrick completes the next manual `.testbed` verification pass on the latest fixes so the docs can reflect the settled real scene behavior rather than a moving target.

---

### Task 7: Independent audit of repo boundaries and final removal truth

**Bead ID:** `aerobeat-input-camera-tracking-2yi`  
**SubAgent:** `primary`  
**Role:** `auditor`  
**References:** `REF-01`, `REF-02`, `REF-03`, `REF-04`, `REF-05`, `REF-07`, `REF-08`, `REF-09`, `REF-10`  
**Prompt:** In `/home/derrick/Documents/projects/aerobeat/aerobeat-input-camera-tracking` and the vendor repo as needed, claim the bead on start. Independently verify that sidecar/runtime ownership really moved to `aerobeat-vendor-mediapipe-python`, that this repo now exposes a truthful `AeroCameraTracking.gd` singleton, that `.testbed` replay/live proving uses that singleton instead of directly creating replay/video-player ownership, that the README now tells the truth about the current state, and that no mounted dependency mirror under `/addons/` was treated as source. Leave the work open if the removal of local `python_mediapipe/` is not yet fully justified by evidence.

**Folders Created/Deleted/Modified:**
- audit notes only if needed

**Files Created/Deleted/Modified:**
- none required unless a minimal audit artifact is necessary

**Status:** ⏸️ Deferred

**Results:** Deferred for the next session. Final audit should happen only after Derrick's next manual `.testbed` verification pass and the README update, because the remaining question is no longer core implementation churn but truth-checking the latest real-scene behavior and deciding whether local `python_mediapipe` ownership can be reduced further.

---

## Bead / execution shape

- coordination epic in `aerobeat-input-camera-tracking`: `aerobeat-input-camera-tracking-uc4`
- input repo child beads created:
  - `aerobeat-input-camera-tracking-9ec` parity audit
  - `aerobeat-input-camera-tracking-0b4` singleton + local-sidecar removal
  - `aerobeat-input-camera-tracking-hy8` `.testbed` rewiring
  - `aerobeat-input-camera-tracking-x4a` automated validation + Derrick QA handoff
  - `aerobeat-input-camera-tracking-cqo` README update
  - `aerobeat-input-camera-tracking-2yi` final audit
- vendor repo child bead created:
  - `avmp-14a` vendor-sidecar parity implementation
- dependency chain now gates singleton/removal work on vendor parity truth, gates README work after the implementation shape settles, and gates final audit on Derrick’s manual live-scene QA note
- note: Beads reported Dolt auto-push warnings (`no common ancestor`) while adding dependencies; local dependency state was still created, but Dolt sync health should be checked later if cross-clone Bead sharing matters during this slice

---

## Final Results

**Status:** ⚠️ Partial / blocked on follow-up manual verification

**What We Built:** The vendor/runtime split is materially in place and the repo boundary moved to a truthful `AeroCameraTracking.gd` singleton. `aerobeat-vendor-mediapipe-python` now owns model-complexity-aware runtime truth (`adc5175`), while `aerobeat-input-camera-tracking` now owns the repo-level live/replay tracking surface (`6144e84`), singleton-first `.testbed` replay/live proving migration (`10b8dfb`, `d65bba7`, `7b1a61f`), automated validation cleanup and stale legacy-test retirement (`8c5ef4c`), replay/autoplay/alignment follow-up (`9927b62`, `5c07d70`), and the latest proving-scene singleton replay/overlay/runtime wiring fixes with screenshot proof (`2be2119`). Full automated validation later reached `75/75` passing tests / `369` asserts, ignoring the known Godot 4.6 shutdown-abort noise.

**Reference Check:** `REF-01` and `REF-02` are materially satisfied at the architecture level: vendor-side runtime truth now lives in `aerobeat-vendor-mediapipe-python`, and this repo now exposes a repo-owned singleton boundary instead of letting proving scenes own the top-level contract directly. `REF-03` through `REF-10` are only partially closed because the README and final independent audit were intentionally deferred at wrap-up, and Derrick still needs one more manual `.testbed` verification pass on the latest proving-scene fixes—especially live-camera switching on real hardware and a focused Flow proving pass—before the final documentation/audit can honestly call the slice done.

**Commits:**
- `adc5175` - Add model complexity parity to vendor runtime
- `6144e84` - Add repo-owned AeroCameraTracking singleton
- `10b8dfb` - singleton-first replay/live proving migration slice
- `d65bba7` - Require proving harness singleton playback contract
- `8c5ef4c` - Retire stale legacy MediaPipe provider test
- `7b1a61f` - Repair singleton-first proving-harness camera-source test
- `9927b62` - Fix proving replay autoplay and overlays
- `5c07d70` - Fix proving harness replay visibility and autoplay
- `2be2119` - Fix proving-scene singleton replay and overlay wiring

**Lessons Learned:** The main failure mode was duplicated ownership and mid-refactor truth drift, not one isolated defect. Every time the proving scenes still directly owned lifecycle/playback/runtime assumptions, new bugs appeared. The winning pattern was to keep pushing behavior through the repo-owned singleton boundary, then verify with repo tests and finally real-scene proof. Also: `git-sync` assumes correct remotes but does not auto-repair HTTPS GitHub Desktop clones, and the Godot 4.6 shutdown abort after green tests is noise on this host rather than a trustworthy failure signal.

---

*Updated at wrap-up on 2026-05-27*