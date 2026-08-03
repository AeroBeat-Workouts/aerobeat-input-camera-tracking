# AeroBeat XY-Only Prototype Feature Space Straight Sanity Test

**Date:** 2026-06-15  
**Status:** Stale
**Last Updated:** 2026-06-15 20:13 EDT  
**Blocked Reason:** None  

**Stale Archive Note:** Marked stale and archived on 2026-08-03 during Byte workspace cleanup; newer AeroBeat work remains with Pico.
**Agent:** `pico`

---

## Goal

Replace the prototype matcher's current per-side XY+Z feature space with XY-only shoulder/elbow/wrist features, then rerun the same straight-left/right versus no-punch sanity test.

---

## Overview

Derrick explicitly called out that MediaPipe pose Z/depth is not merely noisy but inaccurate enough to be unusable for this task. That changes the prototype feature-space assumption itself, not just the benchmark branch. The next honest seam is therefore to remove Z from prototype comparison and replace the current six per-side features with shoulder/elbow/wrist XY-only features for each side, then rerun the already-defined straight-only sanity test.

This is a materially different approach from the prior straight-only run, so it gets its own plan. The goal is not to tune thresholds yet. It is to test whether the current prototype approach becomes viable when the comparison space stops depending on MediaPipe pose depth. We should keep the evaluation discipline the same: change the feature representation, rerun the straight-only benchmark/review packet, then QA and audit whether straight-left/right versus no-punch becomes accurate enough to justify deeper work on this system.

---

## REFERENCES

| ID | Description | Path |
| --- | --- | --- |
| `REF-01` | Current matcher implementation | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/src/detectors/prototype_punch_matcher.gd` |
| `REF-02` | Current straight-only plan | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.plans/2026-06-15-straight-only-prototype-sanity-test.md` |
| `REF-03` | Current full derived library | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/assets/prototype_libraries/boxing_side_aware_fixture_derived_v1/library.json` |
| `REF-04` | Current straight-only library | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/assets/prototype_libraries/boxing_side_aware_fixture_derived_v1_straight_only/library.json` |
| `REF-05` | Benchmark runner | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/scripts/run_prototype_matcher_fixture_benchmark.py` |
| `REF-06` | Derivation script | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/scripts/derive_prototype_library_from_fixtures.py` |
| `REF-07` | Straight-only benchmark manifest | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.testbed/assets/benchmarks/prototype_matcher_boxing_fixture_derived_v1_straight_only.benchmark.json` |
| `REF-08` | Straight-only sanity-test review | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/docs/reviews/prototype-matcher-straight-only-sanity-test-review-2026-06-15.md` |

---

## Tasks

### Task 1: Implement XY-only shoulder/elbow/wrist prototype features and rerun straight-only sanity test

**Bead ID:** `aerobeat-input-camera-tracking-rspx`  
**SubAgent:** `primary` (for `coder`)  
**Role:** `coder`  
**References:** `REF-01`, `REF-03`, `REF-04`, `REF-05`, `REF-06`, `REF-07`, `REF-08`  
**Prompt:** Change the prototype feature representation so each side uses XY-only shoulder/elbow/wrist features instead of the current XY+Z elbow/wrist-relative-to-shoulder representation, then regenerate the relevant library artifacts and rerun the same straight-only sanity test. Keep the seam focused on feature-space change plus retest; do not widen into threshold tuning.

**Folders Created/Deleted/Modified:**
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/src/detectors/`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/assets/prototype_libraries/`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/docs/baselines/`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/docs/reviews/`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.testbed/assets/benchmarks/`

**Files Created/Deleted/Modified:**
- matcher / library / benchmark / review artifacts and any minimally necessary support files

**Status:** ✅ Complete

**Results:** Landed commit `1ddc963` (`Switch prototype matcher straight test to XY-only features`) and closed bead `aerobeat-input-camera-tracking-rspx`. The matcher feature space was changed from 6D XY+Z elbow/wrist-relative-to-shoulder to 4D XY-only shoulder/elbow/wrist features per side, the full derived library was regenerated, the straight-only filtered library was rebuilt, and the same straight-only sanity benchmark was rerun. Direct result: still not viable. `straight_right_fixture` remained clean (`29` expected `punch_right`, `0` wrong), but `straight_left_fixture` still cross-fired heavily (`12` expected `punch_left`, `12` wrong `punch_right`), and `run_in_place_negative_control` still emitted `27` false-positive `punch_left` events. Compared with the prior straight-only pass, false positives dropped only slightly (`30 -> 27`) while the overall system remained too noisy to count as viable.

---

### Task 2: QA the XY-only straight-only sanity test

**Bead ID:** `aerobeat-input-camera-tracking-mm91`  
**SubAgent:** `primary` (for `qa`)  
**Role:** `qa`  
**References:** `REF-01`, `REF-04`, `REF-05`, `REF-07`, `REF-08`  
**Prompt:** Verify the XY-only feature-space straight-only sanity-test packet. Confirm the matcher is really using the new XY-only shoulder/elbow/wrist features, confirm the rerun artifacts are internally consistent, and state whether straight-left/right versus no-punch is now accurate enough to count as viable.

**Folders Created/Deleted/Modified:**
- relevant owning repo paths

**Files Created/Deleted/Modified:**
- QA notes/artifacts as needed

**Status:** ⏳ Pending

**Results:** Pending.

---

### Task 3: Audit the XY-only result and recommend next branch

**Bead ID:** `aerobeat-input-camera-tracking-hf5i`  
**SubAgent:** `primary` (for `auditor`)  
**Role:** `auditor`  
**References:** `REF-01`, `REF-04`, `REF-05`, `REF-07`, `REF-08`  
**Prompt:** Independently audit the XY-only straight-only sanity test. Confirm whether the result truthfully demonstrates viable straight-left/right-vs-no-punch discrimination or whether the prototype approach is still too noisy even with depth removed. Recommend the next branch accordingly.

**Folders Created/Deleted/Modified:**
- relevant owning repo paths

**Files Created/Deleted/Modified:**
- audit notes/artifacts as needed

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
