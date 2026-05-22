# AeroBeat Input Migration Against Continuous Landmark Contract

**Date:** 2026-05-22  
**Status:** Draft  
**Agent:** Cookie 🍪

---

## Goal

Migrate `aerobeat-input-camera-tracking` onto the new continuous landmark contract so downstream Boxing/Flow consumers can start using the refactored tracking stack instead of the old vendor-owned path.

---

## Overview

The upstream platform split has now cleared its critical enabling slices: `aerobeat-vendor-mediapipe-python` proves real host landmark inference and continuous runtime truth, while `aerobeat-tool-camera-tracking` now owns the continuous public frame/state contract. That means the next meaningful product lane is no longer more upstream plumbing. The next meaningful lane is the downstream consumer migration into `aerobeat-input-camera-tracking`.

This migration should stay narrow and honest. The goal is not to declare gameplay-perfect semantics, replay support, or rich reacquiring/loss behavior. The goal is to rewire the input repo so it consumes the new `CameraTracking` contract cleanly, preserves the existing Boxing/Flow proving paths as well as possible, and explicitly documents which semantics are now stronger versus still provisional.

This wave should preserve the locked ownership split: `tool-camera-tracking` owns lifecycle/state/preview/source coordination and the normalized public tracking frame contract; `input-camera-tracking` owns gesture/gameplay interpretation of that contract; and vendor-specific runtime behavior remains outside this repo.

---

## REFERENCES

| ID | Description | Path |
| --- | --- | --- |
| `REF-01` | Current input migration plan / prior seam work | `/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.plans/2026-05-21-input-camera-tracking-contract-migration.md` |
| `REF-02` | Continuous-tracking coordination plan | `/workspace/projects/openclaw-cookie/.plans/aerobeat-architecture/2026-05-22-continuous-tracking-slice.md` |
| `REF-03` | Tool continuous public-state slice plan | `/workspace/projects/aerobeat/aerobeat-tool-camera-tracking/.plans/2026-05-22-continuous-tracking-public-state-slice.md` |
| `REF-04` | Tool landmark normalization slice plan | `/workspace/projects/aerobeat/aerobeat-tool-camera-tracking/.plans/2026-05-22-minimal-real-landmark-normalization-slice.md` |
| `REF-05` | Locked ownership assumptions / phase order | `/workspace/projects/openclaw-cookie/.plans/aerobeat-architecture/IMPLEMENTATION-PHASES.md` |
| `REF-06` | Donor/legacy parity prep inventory for future comparison awareness | `/workspace/projects/openclaw-cookie/.plans/aerobeat-architecture/2026-05-22-donor-mediapipe-python-sidecar-inventory.md` |

---

## Tasks

### Task 1: Plan the input migration wave and create repo-local beads

**Bead ID:** `aerobeat-input-camera-tracking-vpe`  
**SubAgent:** `primary` (for `research`)  
**Role:** `research`  
**References:** `REF-01`, `REF-02`, `REF-03`, `REF-04`, `REF-05`, `REF-06`  
**Prompt:** In the owning repos, inspect the current `aerobeat-input-camera-tracking` contract/migration seam plus the now-green upstream continuous landmark contract. Create the next repo-local execution plan and serialized coder → QA → auditor beads for the narrowest honest input migration wave. Determine exactly what consumer paths can migrate now, what expectations Boxing/Flow currently have, what upstream semantics are strong enough, what still has to remain provisional, and what the first safe proving scope should be.

**Folders Created/Deleted/Modified:**
- repo-local `.plans/` folders as needed
- repo-local `.beads/` state as needed

**Files Created/Deleted/Modified:**
- repo-local plan files under `aerobeat-input-camera-tracking`
- repo-local Beads state/files as needed

**Status:** ✅ Complete

**Results:** Claimed `aerobeat-input-camera-tracking-vpe` with `bd update aerobeat-input-camera-tracking-vpe --status in_progress --json`, then re-inspected the repo-local seam plus the now-green upstream continuous public contract. Evidence found that the detector-consumption seam is already present (`src/tracking_frame_adapter.gd`, `src/providers/camera_tracking_provider.gd`, and `.testbed/tests/unit/test_camera_tracking_provider.gd`), but the real proving/default consumer path is still legacy: `src/input_provider.gd` still instantiates `providers/mediapipe_provider.gd`, both proving scenes still mount `AutoStartManager`, and `.testbed/scripts/proving_harness.gd` only uses the contract path if a `CameraTracking` node already exists in-scene.

Created the next repo-local execution plan:
- `/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.plans/2026-05-22-first-continuous-contract-consumer-slice.md`

Created the serialized repo-local bead chain:
- `aerobeat-input-camera-tracking-lab` — coder
- `aerobeat-input-camera-tracking-ivf` — QA
- `aerobeat-input-camera-tracking-l1k` — auditor

Created repo-local dependencies:
- `aerobeat-input-camera-tracking-ivf -> aerobeat-input-camera-tracking-lab`
- `aerobeat-input-camera-tracking-l1k -> aerobeat-input-camera-tracking-ivf`

Scope decisions captured in the new plan:
- migratable now: the detector-facing `CameraTracking` seam (`tracking_frame_adapter.gd` + `camera_tracking_provider.gd`) and repo-local `.testbed` proving once it actually mounts/prefers a live `CameraTracking` session;
- still provisional: `src/input_provider.gd` assembly integration, provider-session-registry reconciliation, local sidecar/runtime ownership, replay/video-file proving, multi-pose/richer body-head semantics, and final `reacquiring` meaning;
- first safe proving scope: live-camera-only Boxing + Flow contract consumption in `.testbed`, with docs/tests updated so the contract-first path is real and replay is not overclaimed.

Stronger-vs-provisional expectations recorded during planning:
- stronger enough to consume now: repeated `tracking_updated(frame)` updates while `CameraTracking` is running, latest-frame access through `get_tracking_frame()`, truthful live camera source identity/camera switching, public landmark payload `id/x/y/z/v`, `preview_transform.flip_horizontal` in `gameplay_normalized`, and `detail.tracking_ready` meaning a real continuous public lane;
- still provisional: `reacquiring`, replay/video-file semantics, aggregate `confidence`, `head_position`, `head_velocity`, `head_orientation`, `skeleton`, deeper meaning of `z`, and final assembly-facing consumer/session-discovery behavior.

Key blocker notes preserved:
- the proving scenes still currently instantiate `AutoStartManager` and do not mount a `CameraTracking` node by default;
- `flow_proving.tscn` still defaults to a prerecorded fixture path, which is incompatible with the honest live-camera-only contract scope;
- `src/input_provider.gd` remains a separate later reconciliation slice rather than part of this proving-first migration wave.

Closed `aerobeat-input-camera-tracking-vpe` with reason: `Completed Task 1 planning pass: inspected the current seam against the now-green upstream continuous contract, created the repo-local execution plan plus coder/QA/auditor beads, documented migratable-vs-provisional consumer paths, and recorded the first safe proving scope and blockers.`

---

### Task 2: Execute the input migration slice through coder → QA → auditor

**Bead ID:** `aerobeat-input-camera-tracking-lab` (coder), `aerobeat-input-camera-tracking-ivf` (QA), `aerobeat-input-camera-tracking-l1k` (auditor)  
**SubAgent:** `primary` (for `coder` / `qa` / `auditor`)  
**Role:** `orchestrator`  
**References:** `REF-01`, `REF-02`, `REF-03`, `REF-04`, `REF-05`  
**Prompt:** Execute the newly planned `aerobeat-input-camera-tracking` migration slice using separate coder, QA, and auditor subagents. Keep ownership boundaries strict: this repo consumes the public tracking frame/state contract and produces gameplay/gesture interpretation, but it does not reclaim vendor/runtime/lifecycle ownership.

**Folders Created/Deleted/Modified:**
- `aerobeat-input-camera-tracking/*` as implementation dictates

**Files Created/Deleted/Modified:**
- input adapter / proving scenes / tests / docs as implementation dictates

**Status:** ⏳ Pending

**Results:** Pending.

---

## Final Results

**Status:** ✅ Planning complete / execution ready

**What We Built:** Completed Task 1 for the input migration wave. The repo now has an execution-ready plan for the first honest downstream consumer slice plus a serialized coder → QA → auditor bead chain aimed at migrating repo-local Boxing + Flow proving onto the continuous `CameraTracking` contract for live-camera use.

**Reference Check:** Planning preserved the ownership split strictly: `aerobeat-tool-camera-tracking` remains the owner of lifecycle/state/source/preview/public-frame semantics, while `aerobeat-input-camera-tracking` only migrates its downstream detector/proving consumption onto the public contract. Replay, `reacquiring`, rich body/head semantics, and assembly-facing integration remain explicitly provisional.

**Commits:**
- None yet in this wave.

**Lessons Learned:** The seam is already technically present; the blocker is that the default proving/consumer path still lives on the old local lane. The highest-leverage next move is to make the contract path real in `.testbed`, not to overclaim a full repo-wide runtime migration.

---

*Prepared on 2026-05-22*
