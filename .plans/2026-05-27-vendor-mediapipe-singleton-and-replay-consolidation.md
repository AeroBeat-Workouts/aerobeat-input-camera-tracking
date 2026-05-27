# AeroBeat Input Camera Tracking

**Date:** 2026-05-27  
**Status:** In Progress  
**Last Updated:** 2026-05-27 12:54 EDT  
**Blocked Reason:** None  
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

**Status:** ⏳ Pending

**Results:** Active next slice. The singleton migration, replay proving migration, fallback removal, stale legacy test retirement, and singleton-first proving-harness test repair are all landed. This bead should now run automated validation on the current truth, refresh dependencies/workbench via the approved sync path if needed, and prepare Derrick's exact manual `.testbed` Boxing/Flow MediaPipe QA handoff.

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

**Status:** ⏳ Pending

**Results:** Pending.

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

**Status:** ⏳ Pending

**Results:** Pending.

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

**Status:** ⚠️ Planned / awaiting approval

**What We Built:** A repo-local execution plan for consolidating MediaPipe vendor ownership into `aerobeat-vendor-mediapipe-python`, introducing `src/AeroCameraTracking.gd` as the public tracking singleton in `aerobeat-input-camera-tracking`, and rewiring `.testbed` replay/live flows to depend on GodotEnv-managed packages and singleton-owned coordination instead of direct local sidecar/video-player ownership.

**Reference Check:** The plan matches the previously approved split boundaries in `REF-01` and `REF-02`, reflects the current mixed-state truth in `REF-03` through `REF-06`, and uses the current upstream singleton/video-player/vendor surfaces in `REF-07` through `REF-10` as the concrete comparison points.

**Commits:**
- Pending.

**Lessons Learned:** The current bug is probably not “one broken function.” It looks more like duplicated ownership: local sidecar residue, vendor-sidecar incompleteness, and proving scenes still bypassing the intended singleton boundary.

---

*Prepared on 2026-05-27*