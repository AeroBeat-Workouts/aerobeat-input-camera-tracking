# AeroBeat remove depth debug viewer test glue

**Date:** 2026-06-21  
**Status:** In Progress  
**Last Updated:** 2026-06-21 21:01 EDT  
**Blocked Reason:** None  
**Agent:** `pico`

---

## Goal

Remove the boxing-side depth debug viewer test-compatibility glue so the generalized viewer remains genuinely reusable without private harness state mirroring.

---

## Overview

The generalized depth debug viewer extraction passed audit, but one explicit debt remained: `boxing_proving_harness.gd` still mirrors viewer refs/state into private `_depth_debug_*` harness vars via compatibility helpers used by tests. Audit judged that acceptable for the extraction plan, but Derrick now wants that glue removed.

This slice should finish the extraction cleanly by moving tests off those boxing-harness private mirrors and onto either the viewer directly or higher-level behavior assertions. The goal is not to weaken coverage; it is to stop tests from depending on boxing-owned mirrored internals when the viewer is now the real owner of that UI behavior.

The safest path is to first identify exactly which tests still rely on the mirrored refs/state, then update them to assert against the reusable viewer seam or public behavior, remove the mirror path from `boxing_proving_harness.gd`, and re-run focused proving tests plus the generalized viewer coverage. If removing the mirrors reveals any genuine missing public seam in the viewer, add the narrowest reusable inspection seam there instead of reintroducing boxing-private coupling.

---

## REFERENCES

| ID | Description | Path |
| --- | --- | --- |
| `REF-01` | Generalized depth debug viewer plan | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.plans/mediapipe-python/2026-06-21-generalize-depth-debug-viewer.md` |
| `REF-02` | Boxing proving harness | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.testbed/scripts/boxing_proving_harness.gd` |
| `REF-03` | Reusable depth debug viewer | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.testbed/scripts/depth_debug_viewer.gd` |
| `REF-04` | Proving harness tests | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.testbed/tests/unit/test_boxing_proving_harness_profiles_and_debug.gd` |

---

## Tasks

### Task 1: Remove boxing-side test compatibility glue and retarget tests

**Bead ID:** `aerobeat-input-camera-tracking-ukr1`  
**SubAgent:** `primary`  
**Role:** `coder`  
**References:** `REF-02`, `REF-03`, `REF-04`  
**Prompt:** Remove the boxing-side `_depth_debug_*` compatibility glue used only for tests, retarget the affected tests onto the reusable depth debug viewer seam or higher-level behavior, preserve truthful viewer behavior, and run focused validation. If a minimal reusable inspection seam is needed in the viewer, add it there rather than keeping boxing-private mirroring.

**Folders Created/Deleted/Modified:**
- `.testbed/scripts/`
- `.testbed/tests/`
- `.plans/mediapipe-python/`

**Files Created/Deleted/Modified:**
- boxing proving / depth debug viewer / tests / plan files touched by implementation

**Status:** ✅ Complete

**Results:** Removed the boxing-harness mirror seam from `REF-02` by deleting the private `_depth_debug_*` ref/state compatibility vars plus the `_sync_depth_debug_viewer_refs()` / `_sync_depth_debug_viewer_state()` helpers. Retargeted the affected `REF-04` tests to assert through the real viewer seam (`_depth_debug_viewer.get_node_refs()` / `get_state_snapshot()`) via local test helpers instead of boxing-owned mirrored fields. No new viewer seam was needed in `REF-03`; the existing reusable viewer inspection API remains the single source of truth. Focused validation passed for prepared snapshot + overlay parenting, unavailable-depth thumbnail truth, runtime swap behavior, swap-disabled reset behavior, and debug YAML application.

### Task 2: QA removal of test compatibility glue

**Bead ID:** `aerobeat-input-camera-tracking-j5o0`  
**SubAgent:** `primary`  
**Role:** `qa`  
**References:** `REF-02`, `REF-03`, `REF-04`  
**Prompt:** Independently verify the boxing-side compatibility glue is actually gone, tests no longer rely on the mirrored `_depth_debug_*` harness state, and the reusable depth debug viewer plus boxing proving behavior still pass.

**Folders Created/Deleted/Modified:**
- `.testbed/`
- `.plans/mediapipe-python/`

**Files Created/Deleted/Modified:**
- tests / plan files touched by QA validation

**Status:** ⏳ Pending

**Results:** Pending.

### Task 3: Audit final cleanup of viewer extraction

**Bead ID:** `aerobeat-input-camera-tracking-oxll`  
**SubAgent:** `primary`  
**Role:** `auditor`  
**References:** `REF-02`, `REF-03`, `REF-04`  
**Prompt:** Independently audit that the boxing-side test compatibility glue is removed cleanly, no boxing-private mirrored state remains as the assertion seam, and the depth debug viewer extraction is now cleaner for future assembly adoption.

**Folders Created/Deleted/Modified:**
- `.testbed/`
- `.plans/mediapipe-python/`

**Files Created/Deleted/Modified:**
- tests / plan files touched by audit validation

**Status:** ⏳ Pending

**Results:** Pending.

---

## Final Results

**Status:** ⚠️ Partial

**What We Built:** Pending.

**Reference Check:** Pending.

**Commits:**
- Pending.

**Lessons Learned:** Pending.

---

*Created on 2026-06-21*
