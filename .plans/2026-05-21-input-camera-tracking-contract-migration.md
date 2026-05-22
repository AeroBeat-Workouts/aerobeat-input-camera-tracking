# AeroBeat Input Camera Tracking — First Contract Migration Plan

**Date:** 2026-05-21  
**Status:** In Progress  
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

**Status:** ⏳ Pending

**Results:** Pending. This task is execution-ready but partially externally gated by upstream contract stabilization. It should proceed only within the stable slice boundaries listed below.

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

**Status:** ⏳ Pending (depends on `aerobeat-input-camera-tracking-ane`)

**Results:** Pending.

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

**Status:** ⏳ Pending (depends on `aerobeat-input-camera-tracking-3gz`)

**Results:** Pending.

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

**Status:** ⚠️ Planned / ready for execution

**What We Built:** A repo-local first migration plan plus executable coder → QA → auditor Beads for `aerobeat-input-camera-tracking`, with stable slice boundaries and explicit upstream blockers.

**Reference Check:** The plan aligns this repo to the approved platform split in `REF-01` through `REF-03` while grounding migration work in the repo’s current MediaPipe-specific reality from `REF-06` through `REF-09`.

**Commits:**
- Pending.

**Lessons Learned:** The first meaningful move here is not “port code.” It is “stop this repo from pretending it still owns the vendor/runtime stack.” Once that seam is honest, the actual detector logic can survive the platform split with much less churn.

---

*Last updated on 2026-05-21*
