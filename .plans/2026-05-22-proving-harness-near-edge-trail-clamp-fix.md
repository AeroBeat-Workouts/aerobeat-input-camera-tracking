# AeroBeat Input Camera Tracking

**Date:** 2026-05-22  
**Status:** Draft  
**Agent:** Cookie 🍪

---

## Goal

Fix the proving-harness near-edge trail fallback regression so `test_resolves_trail_hand_point_by_clamping_near_edge_jitter` passes without broadening ownership beyond this repo.

---

## Overview

The failing behavior is local to the proving harness trail fallback path in this repo. The current harness correctly rejects truly out-of-bounds direct trail points in `_append_trail_point()`, but its fallback hand-point synthesis is stricter than the intended near-edge behavior: `_resolve_trail_hand_point()` gathers fallback finger landmarks, `_trail_landmark_is_candidate()` rejects any candidate whose raw point is even slightly outside normalized bounds, and `_synthesize_trail_hand_point()` then returns `{}` when too few candidates survive.

That means the test case with slight right-edge jitter (`x=1.02`, `x=1.03`) never reaches a synthesized/clamped result even though the cluster is coherent and the expected behavior is to preserve continuity at the normalized boundary. The narrowest honest fix is to keep direct out-of-bounds trail points invalid, but make fallback synthesis tolerant to tiny near-edge overshoot by clamping candidate coordinates into normalized bounds during fallback resolution before spread/blend validation. That preserves continuity semantics without weakening the separate out-of-bounds clear behavior tested in `_append_trail_point()`.

---

## REFERENCES

| ID | Description | Path |
| --- | --- | --- |
| `REF-01` | Proving harness implementation | `/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.testbed/scripts/proving_harness.gd` |
| `REF-02` | Failing proving harness trail unit test | `/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.testbed/tests/unit/test_proving_harness_trails.gd` |
| `REF-03` | Coordination blocker-fix plan that needs exact handoff IDs | `/workspace/projects/openclaw-cookie/.plans/aerobeat-architecture/2026-05-22-human-testing-blocker-fixes.md` |

---

## Tasks

### Task 1: Implement near-edge fallback clamp in proving harness trail synthesis

**Bead ID:** `aerobeat-input-camera-tracking-caw`  
**SubAgent:** `primary`  
**Role:** `coder`  
**References:** `REF-01`, `REF-02`  
**Prompt:** Claim the bead, then implement the narrowest repo-owned fix for the proving harness near-edge trail fallback regression in `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking`. Keep ownership inside `.testbed/scripts/proving_harness.gd` unless a tiny adjacent test touch is required. Preserve the existing direct out-of-bounds trail clear behavior in `_append_trail_point()`. Make fallback trail-hand resolution tolerate slight near-edge overshoot by clamping candidate coordinates only inside the fallback synthesis path, then validate with `godot --headless --path .testbed --script addons/gut/gut_cmdln.gd -gtest=res://tests/unit/test_proving_harness_trails.gd -gexit`. Commit and push if the repo workflow expects it.

**Folders Created/Deleted/Modified:**
- `/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.testbed/scripts/`
- `/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.testbed/tests/unit/`

**Files Created/Deleted/Modified:**
- `/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.testbed/scripts/proving_harness.gd`
- `/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.testbed/tests/unit/test_proving_harness_trails.gd`

**Status:** ✅ Complete

**Results:** Implemented the narrowest proving-harness-owned fix in `REF-01` by leaving `_append_trail_point()` unchanged and clamping only fallback candidate coordinates that are still within a small near-edge overshoot tolerance before the existing spread/blend synthesis checks run. Added a focused guardrail in `REF-02` proving large overshoot still fails fallback synthesis, so the distinction between strict direct points and tolerant synthesized fallback points stayed intact. Validation passed with `godot --headless --path .testbed --script addons/gut/gut_cmdln.gd -gtest=res://tests/unit/test_proving_harness_trails.gd -gexit` (`13/13`). Ready for QA.

---

### Task 2: QA the proving harness trail clamp fix at repo-local fidelity

**Bead ID:** `aerobeat-input-camera-tracking-lo2`  
**SubAgent:** `primary`  
**Role:** `qa`  
**References:** `REF-01`, `REF-02`  
**Prompt:** Claim the bead, then independently verify the near-edge trail clamp fix in `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking`. Re-run `godot --headless --path .testbed --script addons/gut/gut_cmdln.gd -gtest=res://tests/unit/test_proving_harness_trails.gd -gexit`, confirm the target regression is green, and confirm `test_out_of_bounds_point_still_clears_trail` still passes so direct out-of-bounds clearing did not regress.

**Folders Created/Deleted/Modified:**
- none expected

**Files Created/Deleted/Modified:**
- none expected

**Status:** ⏳ Pending

**Results:** Pending.

---

### Task 3: Audit that the fix stayed narrow and repo-owned

**Bead ID:** `aerobeat-input-camera-tracking-2se`  
**SubAgent:** `primary`  
**Role:** `auditor`  
**References:** `REF-01`, `REF-02`, `REF-03`  
**Prompt:** Claim the bead, then independently audit the completed near-edge trail clamp fix in `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking`. Verify the diff stayed inside the proving-harness-owned path, the target test now passes, the direct out-of-bounds clear behavior remains intact, and the change did not shift ownership into `aerobeat-tool-camera-tracking` or vendor/runtime repos. Close the bead only if the slice is actually complete.

**Folders Created/Deleted/Modified:**
- none expected

**Files Created/Deleted/Modified:**
- none expected

**Status:** ⏳ Pending

**Results:** Pending.

---

## Final Results

**Status:** ⏳ In Progress

**What We Built:** Planning only so far; execution beads created next.

**Reference Check:** The intended fix is scoped to the proving-harness-owned fallback trail synthesis path in `REF-01`, with acceptance anchored by `REF-02`.

**Commits:**
- None yet.

**Lessons Learned:** The bug is not a broad camera-tracking contract problem; it is a local proving-harness continuity rule mismatch between direct trail point validation and fallback hand-point synthesis near normalized edges.

---

*Prepared on 2026-05-22*