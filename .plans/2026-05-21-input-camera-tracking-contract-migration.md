# AeroBeat Input Camera Tracking — First Contract Migration Plan

**Date:** 2026-05-21  
**Status:** Blocked  
**Last Updated:** 2026-05-28 23:37 EDT  
**Blocked Reason:** QA found repo-local validation gaps: full-suite MediaPipe runtime test failure, Godot/GUT abort on exit, and fixture-runner dependency gap; Beads DB also unavailable in this repo  
**Agent:** Cookie 🍪

---

## Goal

Create the first execution-ready migration slice that moves this repo from direct MediaPipe/provider ownership toward vendor-neutral `CameraTracking` frame consumption while preserving Boxing + Flow gameplay interpretation truth.

---

## Overview

Fresh repo inspection showed that `aerobeat-input-camera-tracking` is still effectively the old MediaPipe-specific package: the repo README and plugin metadata still say “AeroBeat MediaPipe Python,” the addon entrypoint is `src/input_provider.gd`, and the `.testbed/` proving harness currently instantiates `src/providers/mediapipe_provider.gd` and `src/camera_view.gd` directly. That means the first migration slice is not a full feature rewrite. It is an ownership correction: establish a seam where this repo consumes the upstream `aerobeat-tool-camera-tracking` contract instead of continuing to own vendor lifecycle, preview, and source management details.

The locked platform direction is that `aerobeat-tool-camera-tracking` owns lifecycle, preview attachment, live/replay coordination, and the normalized tracking-frame contract, while this repo owns gesture/gameplay interpretation plus proving. That means the safest first slice here is: preserve the existing Boxing + Flow interpretation logic, introduce a tracking-frame ingestion seam, update repo identity/docs/testbed assumptions where the contract is already stable, and defer anything that would force us to invent upstream contract details.

The repo also arrived in a truly fresh/rough state on this machine: the local checkout was missing and had to be recloned, and the clone initially landed sparsely before being expanded. That is recorded here because later coder/QA lanes should treat any missing dependency state as environment bootstrap work, not as product truth.

---

## REFERENCES

| ID | Description | Path |
| --- | --- | --- |
| `REF-01` | Upstream first-pass `CameraTracking` singleton API and normalized frame assumptions | `/workspace/projects/aerobeat/aerobeat-tool-camera-tracking/.plans/bootstrap-architecture/CAMERA-TRACKING-API.md` |
| `REF-02` | Platform repo boundaries and ownership assumptions | `/workspace/projects/aerobeat/aerobeat-docs/.plans/bootstrap-architecture/BOUNDARIES-AND-ASSUMPTIONS.md` |
| `REF-03` | Recommended implementation phases for tool/vendor/input split | `/workspace/projects/aerobeat/aerobeat-docs/.plans/bootstrap-architecture/IMPLEMENTATION-PHASES.md` |
| `REF-04` | Current input-core provider contract this repo previously targeted | `/workspace/projects/aerobeat/aerobeat-input-core/src/interfaces/input_provider.gd` |
| `REF-05` | Current active-provider manager expectations in input-core | `/workspace/projects/aerobeat/aerobeat-input-core/src/input_manager.gd` |
| `REF-06` | Current repo entrypoint still tied to MediaPipe/provider-owned lifecycle | `/workspace/projects/aerobeat/aerobeat-input-camera-tracking/src/input_provider.gd` |
| `REF-07` | Current proving harness directly owns provider + camera view lifecycle | `/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.testbed/scripts/proving_harness.gd` |
| `REF-08` | Current repo identity/docs still describe the pre-split MediaPipe package | `/workspace/projects/aerobeat/aerobeat-input-camera-tracking/README.md` |
| `REF-09` | Current plugin metadata still advertises the MediaPipe Python addon | `/workspace/projects/aerobeat/aerobeat-input-camera-tracking/plugin.cfg` |

---

## Tasks

### Task 1: Implement the first contract-driven migration slice

**Bead ID:** `aerobeat-input-camera-tracking-ane`  
**SubAgent:** `primary` (for `coder`)  
**Role:** `coder`  
**References:** `REF-01`, `REF-02`, `REF-03`, `REF-04`, `REF-05`, `REF-06`, `REF-07`, `REF-08`, `REF-09`  
**Prompt:** In `/workspace/projects/aerobeat/aerobeat-input-camera-tracking`, claim `aerobeat-input-camera-tracking-ane` on start and implement the first migration slice from direct MediaPipe/provider ownership to vendor-neutral `CameraTracking` frame consumption. Keep sharable code/assets at repo root, keep `.testbed/` as the proving Godot project, and never edit `/addons/` mirrors. Preserve Boxing + Flow interpretation truth, but move lifecycle/preview/source assumptions behind a new seam driven by the upstream `aerobeat-tool-camera-tracking` contract. If dependency restore/sync is needed, note or use `/home/derrick/.openclaw/workspace/scripts/godotenv-sync` or normal GodotEnv restore flows instead of mirror edits. Run relevant repo-local validation, document any upstream blockers/deferred items you hit, and do not close the bead if the slice is still blocked on unresolved upstream contract details.

**Folders Created/Deleted/Modified:**
- `/workspace/projects/aerobeat/aerobeat-input-camera-tracking/src/`
- `/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.testbed/`
- `/workspace/projects/aerobeat/aerobeat-input-camera-tracking/docs/`
- `/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.plans/`

**Files Created/Deleted/Modified:**
- `/workspace/projects/aerobeat/aerobeat-input-camera-tracking/README.md`
- `/workspace/projects/aerobeat/aerobeat-input-camera-tracking/plugin.cfg`
- `/workspace/projects/aerobeat/aerobeat-input-camera-tracking/src/input_provider.gd`
- `/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.testbed/scripts/proving_harness.gd`
- additional adapter/seam files as needed under `src/`
- any test files required under `.testbed/tests/`

**Status:** ✅ Complete

**Results:** The first contract-driven slice was already largely present in repo state when this coder pass began: the repo-root tracking-frame seam (`src/tracking_frame_adapter.gd`), the contract-driven provider (`src/providers/camera_tracking_provider.gd`), the updated repo identity/docs, and the `.testbed/` proving path that prefers the upstream `CameraTracking` contract were all in place and aligned with `REF-01` through `REF-09`. This coder pass finished the slice by fixing two contract-path regressions uncovered by repo-local validation: (1) `src/input_provider.gd` was redeclaring `camera_devices_changed`, which now already exists upstream in the input-core parent contract, causing the assembly-facing adapter tests to fail to compile; and (2) `src/AeroMediaPipeReplayPlaybackBackend.gd` did not implement `set_cover_mode` / `set_audio_level`, which pushed replay playback through the singleton into an error state even though the transport-backed contract path itself was otherwise working. After removing the duplicate signal redeclaration and making those replay-surface config hooks explicit no-op successes for the HTTP replay backend, the focused contract-path test coverage passed again. Bead claim was attempted but could not be recorded because `bd update aerobeat-input-camera-tracking-ane --status in_progress --json` failed with `Error: no beads database found`; this repo currently has a `.beads` directory but no initialized Beads database, so no bead state was invented or closed. Upstream/deferred items from the plan remain honest deferrals rather than coder blockers for this slice: final contract schema details, preview semantics, replay semantics beyond the current proving seam, and broader input-core reconciliation still need future slices.

---

### Task 2: QA the first contract-driven migration slice

**Bead ID:** `aerobeat-input-camera-tracking-3gz`  
**SubAgent:** `primary` (for `qa`)  
**Role:** `qa`  
**References:** `REF-01`, `REF-02`, `REF-03`, `REF-07`, `REF-08`, `REF-09`  
**Prompt:** In `/workspace/projects/aerobeat/aerobeat-input-camera-tracking`, claim `aerobeat-input-camera-tracking-3gz` after the coder bead is ready. Verify the `.testbed/` proving flow, repo-local validation, and any fixture/test evidence for the first `CameraTracking` migration slice. Confirm that dependency restore guidance points to `/home/derrick/.openclaw/workspace/scripts/godotenv-sync` or normal GodotEnv flows instead of `/addons/` edits, and verify that Boxing + Flow proving still makes sense under the new seam. Record concrete pass/fail evidence and leave the bead open if QA finds gaps.

**Folders Created/Deleted/Modified:**
- `/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.testbed/`
- `/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.plans/`

**Files Created/Deleted/Modified:**
- validation notes only if needed

**Status:** ❌ Failed

**Results:** QA attempted to claim `aerobeat-input-camera-tracking-3gz`, but `bd update aerobeat-input-camera-tracking-3gz --status in_progress --json` failed with `Error: no beads database found`, so no Beads state was recorded or closed. Repo-local restore guidance is correctly pointed at `/home/derrick/.openclaw/workspace/scripts/godotenv-sync` plus `python3 scripts/refresh_testbed_workbench.py`, and the README explicitly says not to patch `.testbed/addons/` mirrors directly. That refresh path succeeded on this host and reported a clean `.testbed` re-import. Slice-specific contract-path validation is good: focused headless GUT coverage passed for `test_replay_playback_backend.gd` (3/3), `test_aero_camera_tracking.gd` (3/3), `test_camera_tracking_provider.gd` (6/6), `test_input_provider_adapter.gd` (13/13), `test_tracking_frame_adapter.gd` (2/2), and the proving-harness trail/contract coverage inside `test_proving_harness_trails.gd` already passed during the full-suite run (21/21). Those tests are concrete evidence that the first migration slice still routes Boxing + Flow proving through the new seam: replay starts via the `CameraTracking` contract, the provider consumes normalized tracking frames, the input-provider adapter prefers or discovers the tracking session before falling back, and the proving harness prefers the `AeroCameraTracking` singleton for replay/live flows. The `.testbed` proving surface itself is wired consistently with that seam: `.testbed/addons.jsonc` mounts `aerobeat-tool-camera-tracking` as the contract shell and the MediaPipe vendor backend only for repo-local proving, `.testbed/scripts/proving_harness.gd` now requires the `AeroCameraTracking` singleton for proving flows, and the Boxing/Flow proving scenes still point at prerecorded fixture assets. However, QA did not clear the repo as audit-ready because broad repo-local validation still fails outside the migration slice: the full `godot --headless --path .testbed --script addons/gut/gut_cmdln.gd -gdir=res://tests -ginclude_subdirs -gexit` run finished with 83 tests, 77 passing tests, 1 failing test, and 5 pending/risky tests. The failing test is `res://tests/unit/test_mediapipe_process.gd::test_find_python_returns_prepared_runtime_path`, which asserts that `_find_python()` returns a non-empty path but currently gets `""`; the other MediaPipe process lifecycle checks then downgrade to pending because the prepared runtime is unavailable on this host. After the GUT summary, Godot aborted with `malloc(): mismatching next->prev_size (unsorted)` / signal 6; a focused rerun of migration-slice tests also reproduced an exit abort (`corrupted size vs. prev_size in fastbins`) after otherwise passing assertions, so the Godot/GUT abort still reproduces in repo-local QA. Fixture/test evidence is only partial in this checkout: fixture YAML/MP4 assets exist for Boxing and Flow and the scenes reference them, but `.testbed/test-results/` was absent, so there was no fresh saved proving artifact directory to inspect here. Attempting to invoke the fixture-runner entrypoint (`python3 scripts/proving_fixture_runner.py --help`) also failed immediately with `ModuleNotFoundError: No module named 'yaml'`, which means the scripted fixture-capture path is not presently self-validating on this host without extra Python deps. Net: the migration seam itself looks sound and Boxing + Flow proving still makes architectural sense under it, but QA found enough whole-repo validation and proving-tooling gaps that this task must stay failed/open for follow-up before audit.

---

### Task 3: Audit the first contract-driven migration slice

**Bead ID:** `aerobeat-input-camera-tracking-d41`  
**SubAgent:** `primary` (for `auditor`)  
**Role:** `auditor`  
**References:** `REF-01`, `REF-02`, `REF-03`, `REF-06`, `REF-07`, `REF-08`, `REF-09`  
**Prompt:** In `/workspace/projects/aerobeat/aerobeat-input-camera-tracking`, claim `aerobeat-input-camera-tracking-d41` after QA completes. Independently audit the first migration slice against this plan, the upstream `CameraTracking` contract assumptions, the diff, and QA evidence. Confirm that the repo is moving toward vendor-neutral tracking-frame consumption instead of re-embedding vendor lifecycle truth, that blockers/deferred items are documented honestly, and that no `/addons/` mirror edits were used. Close the bead only if the work truly satisfies the planned slice.

**Folders Created/Deleted/Modified:**
- `/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.plans/`

**Files Created/Deleted/Modified:**
- audit notes only if needed

**Status:** ⏳ Pending (blocked by QA gaps on `aerobeat-input-camera-tracking-3gz`)

**Results:** Audit is not ready yet. QA found that the first contract-migration slice passes its focused seam/proving tests, but the repo still has a broader failing MediaPipe runtime-path test, a reproducible Godot/GUT abort on exit, no fresh `.testbed/test-results/` artifacts in this checkout, and a fixture-runner dependency gap (`yaml` missing) that blocks stronger fixture-capture evidence on this host.

---

## First Slice Boundaries That Can Proceed Once Upstream Contract Stabilizes

1. **Identity + documentation correction**
   - rename repo-facing truth away from “MediaPipe Python” where the package is now an input layer rather than a vendor repo
   - document that this repo consumes `CameraTracking` instead of owning source/preview/lifecycle truth

2. **Tracking-frame ingestion seam**
   - add a local adapter/translator that converts the upstream normalized tracking frame into the data shape the existing Boxing + Flow detectors need
   - preserve current gameplay interpretation as much as possible while decoupling it from vendor startup/shutdown ownership

3. **Proving/testbed migration**
   - update `.testbed/` proving scenes/harnesses to use the upstream `CameraTracking` singleton path for lifecycle + frame access
   - keep `.testbed/` as the proving environment; do not move sharable package truth into it

4. **Validation refresh**
   - update repo-local tests/fixtures to assert the new seam and document any still-vendor-specific truth that has not yet been removed

---

## Explicit Upstream Blockers / Deferred Items

These items should be treated as blocked or deferred until `aerobeat-tool-camera-tracking` stabilizes them:

1. **Final tracking-frame field names and schema details** (`REF-01`)
   - exact landmark payload shape
   - final `tracking_state` enum strings
   - whether body-part confidence, skeleton structure, and optional velocities are guaranteed in v1

2. **Coordinate-space truth** (`REF-01`)
   - exact normalized frame orientation
   - mirrored vs non-mirrored gameplay space expectations
   - how `preview_transform.flip_horizontal` and `space = gameplay_normalized` should be consumed in detectors

3. **Preview ownership semantics** (`REF-01`, `REF-02`)
   - this repo should stop owning preview bind/restart logic, but it needs the stable upstream preview descriptor + attachment model before that code can be removed cleanly

4. **Replay/video-file semantics** (`REF-01`, `REF-03`)
   - proving scenes that depend on prerecorded video should wait for stable upstream `source.kind = "video_file"` behavior and any `tool-video-player` coordination rules

5. **Stable package/runtime path for the upstream singleton**
   - final addon key/path and consumer import pattern for `aerobeat-tool-camera-tracking`
   - whether tests should instantiate fake backends directly or consume the singleton only

6. **Input-core contract reconciliation** (`REF-04`, `REF-05`)
   - whether this repo continues to expose an `AeroInputProvider` adapter on top of `CameraTracking`, or whether some of the old provider-facing seams should shrink or move

---

## Execution Notes

- Real sharable code/assets live at repo root.
- `.testbed/` is the proving Godot project.
- If dependency sync is needed, note or use `/home/derrick/.openclaw/workspace/scripts/godotenv-sync`.
- Never treat `/addons/` as an editing surface.
- The repo was missing locally at task start and had to be cloned; initial checkout also needed sparse-state recovery before inspection.

---

## Final Results

**Status:** ⚠️ Partial — coder slice is validated at the seam level, but QA found blocking repo-local validation gaps before audit

**What We Built:** The repo now has a first-pass contract-consumer lane that keeps Boxing + Flow interpretation rooted here while consuming normalized `CameraTracking` frames through the upstream seam. QA confirmed the seam-level pieces work together under focused coverage: the assembly-facing adapter compiles against the current input-core parent signal surface, replay playback delegates through the singleton-backed contract path, the provider consumes normalized tracking frames, and `.testbed` proving is wired around `AeroCameraTracking` rather than re-owning runtime truth directly.

**Reference Check:** `REF-01` and `REF-02` are still honored by keeping vendor/runtime ownership out of the detector lane and consuming the upstream tracking/replay contracts instead. `REF-04` through `REF-07` remain satisfied for the current compatibility slice because the repo still exposes the input-core-facing adapter while routing the preferred proving/runtime path through `CameraTracking`. `REF-08` and `REF-09` were already aligned in repo state when this coder pass started. QA also confirmed that dependency restore guidance now points to `/home/derrick/.openclaw/workspace/scripts/godotenv-sync` / normal GodotEnv flows instead of direct `/addons/` edits.

**Commits:**
- Pending.

**Lessons Learned:** The migration slice was mostly landed already; the real value in coder+QA was truth-checking the seam under executable coverage and separating slice-specific health from repo-wide health. Right now those are different stories: the contract seam itself looks good, but the broader repo still carries a failing MediaPipe runtime-path test, the headless Godot/GUT path can abort on exit even after passing targeted assertions, fixture-capture tooling is missing a Python `yaml` dependency on this host, and this repo’s Beads state is not actually initialized, so orchestration status has to stay in the plan until the repo gets a real Beads database again.

---

*Last updated on 2026-05-28 23:37 EDT*
