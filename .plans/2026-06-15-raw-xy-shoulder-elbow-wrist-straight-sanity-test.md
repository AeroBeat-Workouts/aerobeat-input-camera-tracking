# AeroBeat Raw-XY Shoulder/Elbow/Wrist Straight Sanity Test

**Date:** 2026-06-15  
**Status:** Blocked  
**Last Updated:** 2026-06-15 21:58 EDT  
**Blocked Reason:** Session stopping for handoff before QA/audit on the raw-XY sanity test and before choosing whether to modify the prototype approach further or move to the next overall system.  
**Agent:** `pico`

---

## Goal

Test whether the prototype system becomes viable for straight-left/right versus no-punch when each side uses raw XY shoulder/elbow/wrist pose features, with Z/depth still excluded.

---

## Overview

The previous XY-only seam removed MediaPipe pose depth but still used shoulder-relative elbow/wrist features only. Derrick clarified that the intended next test is different: use raw XY for shoulder, elbow, and wrist directly. That makes this a distinct feature-space experiment rather than a rerun of the previous one.

This seam should stay disciplined. We are not tuning thresholds yet. We are changing the prototype representation to raw XY shoulder/elbow/wrist per side, regenerating the relevant library artifacts, and rerunning the same straight-only sanity test so we can compare three states cleanly:
- prior straight-only with XY+Z relative elbow/wrist features
- XY-only shoulder-relative elbow/wrist features
- raw XY shoulder/elbow/wrist features

The output should tell us whether the prototype approach has a viable straight-punch signal under this representation, or whether even this more literal feature space still fails the fundamental straight-left/right versus no-punch truth test.

---

## REFERENCES

| ID | Description | Path |
| --- | --- | --- |
| `REF-01` | Current matcher implementation | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/src/detectors/prototype_punch_matcher.gd` |
| `REF-02` | XY-only feature-space plan | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.plans/2026-06-15-xy-only-prototype-feature-space-straight-sanity-test.md` |
| `REF-03` | Current full derived library | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/assets/prototype_libraries/boxing_side_aware_fixture_derived_v1/library.json` |
| `REF-04` | Current straight-only library | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/assets/prototype_libraries/boxing_side_aware_fixture_derived_v1_straight_only/library.json` |
| `REF-05` | Benchmark runner | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/scripts/run_prototype_matcher_fixture_benchmark.py` |
| `REF-06` | Derivation script | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/scripts/derive_prototype_library_from_fixtures.py` |
| `REF-07` | Straight-only benchmark manifest | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.testbed/assets/benchmarks/prototype_matcher_boxing_fixture_derived_v1_straight_only.benchmark.json` |
| `REF-08` | Latest straight-only review packet | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/docs/reviews/prototype-matcher-straight-only-sanity-test-review-2026-06-15.md` |

---

## Tasks

### Task 1: Implement raw-XY shoulder/elbow/wrist features and rerun straight-only sanity test

**Bead ID:** `aerobeat-input-camera-tracking-ue97`  
**SubAgent:** `primary` (for `coder`)  
**Role:** `coder`  
**References:** `REF-01`, `REF-03`, `REF-04`, `REF-05`, `REF-06`, `REF-07`, `REF-08`  
**Prompt:** Change the prototype feature representation so each side uses raw XY shoulder/elbow/wrist pose features, with Z/depth excluded, then regenerate the relevant library artifacts and rerun the same straight-only sanity test. Keep the seam focused on feature-space change plus retest; do not widen into threshold tuning.

**Folders Created/Deleted/Modified:**
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/src/detectors/`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/assets/prototype_libraries/`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/docs/baselines/`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/docs/reviews/`

**Files Created/Deleted/Modified:**
- matcher / library / benchmark / review artifacts and any minimally necessary support files

**Status:** ✅ Complete

**Results:** Landed commit `429d98d` (`Test raw XY shoulder/elbow/wrist straight matcher`) and closed bead `aerobeat-input-camera-tracking-ue97`. The matcher was updated to use raw per-side `shoulder_x`, `shoulder_y`, `elbow_x`, `elbow_y`, `wrist_x`, `wrist_y` features with no depth, the full derived library was regenerated, the straight-only filtered library was rebuilt, and the same straight-only benchmark/review packet was rerun. Direct result: still not viable, and worse than the prior XY-only pass. `straight_left_fixture` emitted `12` expected and `17` wrong events, `straight_right_fixture` emitted `24` expected and `12` wrong events, and `run_in_place_negative_control` still emitted `29` false-positive `punch_left` events.

---

### Task 2: QA the raw-XY straight-only sanity test

**Bead ID:** `aerobeat-input-camera-tracking-xe9y`  
**SubAgent:** `primary` (for `qa`)  
**Role:** `qa`  
**References:** `REF-01`, `REF-04`, `REF-05`, `REF-07`, `REF-08`  
**Prompt:** Verify the raw-XY feature-space straight-only sanity-test packet. Confirm the matcher is really using raw XY shoulder/elbow/wrist features, confirm the rerun artifacts are internally consistent, and state whether straight-left/right versus no-punch is now accurate enough to count as viable.

**Folders Created/Deleted/Modified:**
- relevant owning repo paths

**Files Created/Deleted/Modified:**
- QA notes/artifacts as needed

**Status:** ⏳ Pending

**Results:** Pending.

---

### Task 3: Audit the raw-XY result and recommend next branch

**Bead ID:** `aerobeat-input-camera-tracking-2e2r`  
**SubAgent:** `primary` (for `auditor`)  
**Role:** `auditor`  
**References:** `REF-01`, `REF-04`, `REF-05`, `REF-07`, `REF-08`  
**Prompt:** Independently audit the raw-XY straight-only sanity test. Confirm whether the result truthfully demonstrates viable straight-left/right-vs-no-punch discrimination or whether the prototype approach is still too noisy even under raw XY shoulder/elbow/wrist features. Recommend the next branch accordingly.

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
