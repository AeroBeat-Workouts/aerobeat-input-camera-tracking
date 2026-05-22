# AeroBeat Assembly-Facing Input Migration

**Date:** 2026-05-22  
**Status:** Draft  
**Agent:** Cookie 🍪

---

## Goal

Extend `aerobeat-input-camera-tracking` beyond the `.testbed` proving path by migrating the assembly-facing consumer entry path onto the new continuous `CameraTracking` contract as safely and honestly as possible.

---

## Overview

The first downstream migration slice is now green for its scoped proving target: Boxing + Flow proving scenes in `.testbed` mount and consume the continuous `CameraTracking` contract through the contract-first seam. That was the right first move, because it kept runtime/vendor ownership upstream while proving that downstream consumer code can ingest the new frame/state contract.

The next step is the real product-facing seam: `src/input_provider.gd` and the assembly-facing path that still reflects older ownership and integration assumptions. This slice should stay narrow. It should move the repo toward the new contract without overclaiming replay support, final session-discovery architecture, or broader gameplay-perfect semantics. The goal is to make the assembly-facing path use the new contract honestly, preserve current Boxing/Flow behavior as far as the new contract truly supports it, and clearly document what remains provisional.

This wave must keep ownership boundaries strict. `tool-camera-tracking` still owns lifecycle/state/preview/source coordination and the normalized public tracking contract. `input-camera-tracking` still owns gesture/gameplay interpretation and input-side composition. This repo should consume upstream truth, not recreate it.

---

## REFERENCES

| ID | Description | Path |
| --- | --- | --- |
| `REF-01` | Prior input migration seam plan | `/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.plans/2026-05-21-input-camera-tracking-contract-migration.md` |
| `REF-02` | First continuous-contract consumer slice | `/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.plans/2026-05-22-first-continuous-contract-consumer-slice.md` |
| `REF-03` | Input migration coordination plan | `/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.plans/2026-05-22-input-migration-against-continuous-landmark-contract.md` |
| `REF-04` | Upstream continuous-tracking coordination plan | `/workspace/projects/openclaw-cookie/.plans/aerobeat-architecture/2026-05-22-continuous-tracking-slice.md` |
| `REF-05` | Tool continuous public-state slice | `/workspace/projects/aerobeat/aerobeat-tool-camera-tracking/.plans/2026-05-22-continuous-tracking-public-state-slice.md` |
| `REF-06` | Current assembly-facing input entry path | `/workspace/projects/aerobeat/aerobeat-input-camera-tracking/src/input_provider.gd` |
| `REF-07` | Contract-first detector seam | `/workspace/projects/aerobeat/aerobeat-input-camera-tracking/src/providers/camera_tracking_provider.gd` |
| `REF-08` | Tracking frame adapter | `/workspace/projects/aerobeat/aerobeat-input-camera-tracking/src/tracking_frame_adapter.gd` |

---

## Tasks

### Task 1: Plan the assembly-facing migration wave and create repo-local beads

**Bead ID:** `aerobeat-input-camera-tracking-g11`  
**SubAgent:** `primary` (for `research`)  
**Role:** `research`  
**References:** `REF-01`, `REF-02`, `REF-03`, `REF-04`, `REF-05`, `REF-06`, `REF-07`, `REF-08`  
**Prompt:** Inspect the current assembly-facing entry path in `src/input_provider.gd` and the now-green upstream continuous contract. Create the next repo-local execution plan and serialized coder → QA → auditor beads for the narrowest honest assembly-facing migration slice. Determine what can migrate now, what must stay provisional, what compatibility shims are acceptable, and what proving scope is required before claiming the assembly-facing path is migrated.

**Folders Created/Deleted/Modified:**
- repo-local `.plans/` folders as needed
- repo-local `.beads/` state as needed

**Files Created/Deleted/Modified:**
- repo-local plan files under `aerobeat-input-camera-tracking`
- repo-local Beads state/files as needed

**Status:** ✅ Complete

**Results:** Claimed `aerobeat-input-camera-tracking-g11` with `bd update aerobeat-input-camera-tracking-g11 --status in_progress --json`, re-inspected the current assembly-facing adapter in `src/input_provider.gd`, and re-checked the now-green upstream continuous `CameraTracking` contract. Inspection confirmed the core migration gap: the detector seam already exists through `src/providers/camera_tracking_provider.gd` + `src/tracking_frame_adapter.gd`, but the actual assembly-facing addon entrypoint still directly instantiates `providers/mediapipe_provider.gd`, owns local startup/publication semantics, and only publishes the legacy-shaped provider shell.

Created the next repo-local execution plan:
- `/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.plans/2026-05-22-assembly-facing-camera-tracking-adapter-slice.md`

Created the serialized repo-local bead chain:
- `aerobeat-input-camera-tracking-0m8` — coder
- `aerobeat-input-camera-tracking-bl3` — QA
- `aerobeat-input-camera-tracking-yup` — auditor

Created repo-local dependencies:
- `aerobeat-input-camera-tracking-bl3 -> aerobeat-input-camera-tracking-0m8`
- `aerobeat-input-camera-tracking-yup -> aerobeat-input-camera-tracking-bl3`

Scope decisions captured in the new plan:
- migratable now: `src/input_provider.gd` can become a contract-first assembly adapter over `CameraTrackingProvider` when a `CameraTracking` session is explicitly supplied or conservatively discoverable, while preserving the `AeroInputProvider`-facing shell and input-core session publication behavior;
- acceptable shims: keep `PROVIDER_ID` / shared session key compatibility, keep provider-session-registry publication in `input_provider.gd`, allow minimal session injection/discovery helpers, and retain a clearly provisional legacy fallback when no `CameraTracking` session exists;
- must stay provisional: final assembly-wide `CameraTracking` session discovery/ownership architecture, backend-factory registration/runtime boot policy, replay/video-file semantics, richer public body/head/confidence semantics, multi-pose guarantees, and full removal of the legacy local provider lane.

Required proof before claiming the assembly-facing path is migrated:
- `src/input_provider.gd` must prefer/use the contract lane when a `CameraTracking` session is present;
- assembly-facing signals/getters/camera switching/session publication must still work correctly on top of `CameraTrackingProvider`;
- repo-local tests must prove contract-mode behavior through `test_input_provider_adapter.gd`, not just through `test_camera_tracking_provider.gd`;
- any retained legacy fallback must remain explicitly provisional rather than being mistaken for the migrated path.

Blocker notes preserved:
- there is still no finalized assembly-wide `CameraTracking` session discovery/ownership contract equivalent to the input-core provider-session registry;
- `input_provider.gd` currently publishes a provider session, not a `CameraTracking` session, so compatibility publication remains a shell rather than the final architecture;
- the Beads dependency writes emitted a Dolt auto-push warning (`no common ancestor`), but the repo-local dependency edges were still created successfully.

---

### Task 2: Execute the assembly-facing migration slice through coder → QA → auditor

**Bead ID:** `aerobeat-input-camera-tracking-0m8` (coder), `aerobeat-input-camera-tracking-bl3` (QA), `aerobeat-input-camera-tracking-yup` (auditor)  
**SubAgent:** `primary` (for `coder` / `qa` / `auditor`)  
**Role:** `orchestrator`  
**References:** `REF-01`, `REF-02`, `REF-03`, `REF-05`, `REF-06`, `REF-07`, `REF-08`  
**Prompt:** Execute the newly planned assembly-facing migration slice using separate coder, QA, and auditor subagents. Keep the detector seam contract-first, preserve ownership boundaries, and avoid overclaiming replay support or broader runtime ownership.

**Folders Created/Deleted/Modified:**
- `aerobeat-input-camera-tracking/*` as implementation dictates

**Files Created/Deleted/Modified:**
- assembly-facing input adapter / docs / tests / proving paths as implementation dictates

**Status:** ⚠️ In Progress

**Results:** Claimed `aerobeat-input-camera-tracking-0m8`, implemented the assembly-facing contract-first adapter slice in `src/input_provider.gd`, and pushed commit `f4755c1230d356fcb4b11ff46372402c52c89e34` (`Prefer CameraTracking in input provider adapter`). The adapter now prefers `CameraTrackingProvider` when a `CameraTracking` session is explicitly injected or conservatively discoverable in-tree, while preserving `PROVIDER_ID == "mediapipe_python"`, provider-session-registry publication, and a clearly provisional legacy fallback when no session exists. Added narrow helper methods (`set_tracking_session`, `clear_tracking_session`, `get_tracking_session`, `uses_camera_tracking_contract_path`, `is_using_legacy_fallback`) and updated `test_input_provider_adapter.gd` so the assembly-facing adapter itself is the proving surface for contract-mode behavior. Targeted validation passed (`refresh_testbed_workbench.py`, `test_input_provider_adapter.gd` 9/9, `test_camera_tracking_provider.gd` 4/4), but broader repo-local baseline failures remain outside this slice. QA and auditor beads (`aerobeat-input-camera-tracking-bl3`, `aerobeat-input-camera-tracking-yup`) are created and unstarted at this stop point.

---

## Final Results

**Status:** ⚠️ Partial / coder complete, QA + audit pending

**What We Built:** Completed the planning pass and landed the first implementation pass for the next repo-local assembly-facing migration wave. `src/input_provider.gd` is now converted into a contract-first adapter over `CameraTrackingProvider` when a `CameraTracking` session is supplied or discoverable, while keeping narrow compatibility shims and a clearly provisional legacy fallback.

**Reference Check:** This wave still keeps the first proving slice intact and targets the next honest consumer seam rather than pretending the repo is fully migrated already. It preserves the upstream continuous contract as the new truth source while keeping input-core registry behavior only as a compatibility shell. QA and audit are still required before claiming the assembly-facing path itself is green.

**Commits:**
- `f4755c1230d356fcb4b11ff46372402c52c89e34` - Prefer CameraTracking in input provider adapter

**Lessons Learned:** The proving path is green, so the next risk is no longer “can downstream consume the contract at all?” It is “can the real assembly-facing entry path consume it without smuggling old ownership assumptions back in?” The narrow honest answer is to migrate the adapter before claiming the whole product path, and to judge that adapter with targeted proof instead of broad suite noise.

---

*Prepared on 2026-05-22*
