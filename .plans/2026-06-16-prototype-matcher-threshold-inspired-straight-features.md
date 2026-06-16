# AeroBeat Prototype Matcher Threshold-Inspired Straight Features

**Date:** 2026-06-16
**Status:** In Progress
**Last Updated:** 2026-06-16 10:43 EDT
**Blocked Reason:** None.
**Agent:** `pico`

---

## Goal

Test whether the prototype matcher becomes more useful for straight punches if we add threshold-inspired per-side features for combined elbow+wrist velocity and elbow-to-shoulder proximity, while keeping the comparison disciplined against the existing straight-only sanity benchmark and the run-in-place negative control.

---

## Overview

The latest handoff says the raw-XY shoulder/elbow/wrist prototype pass still failed the straight-left/right versus no-punch sanity test, and it failed badly enough that the prior branch was blocked pending QA/audit plus a strategic decision. Derrick's new direction is to try a more abstract representation that borrows from the threshold detector: (1) combine elbow and wrist motion into a shared velocity signal over time, and (2) include an elbow-versus-shoulder proximity signal because the elbow tends to line up toward the shoulder during a straight compared to guard.

This plan keeps that experiment narrow. We are not trying to fully hybridize the threshold detector into the prototype matcher or solve every gesture at once. We are adding only the specific signals Derrick identified, regenerating the prototype artifacts, and rerunning the same straight-only benchmark so we can compare the result against the earlier raw-XY and XY-only prototype passes. The negative control remains important because run-in-place arm swing may still satisfy some of these signals; if so, that is useful truth rather than a failure of process.

If this pass still fails, we should treat it as stronger evidence that the prototype matcher is structurally the wrong shape for straight-punch truth in this data, rather than continuing to pile on ad hoc features without a clear gain.

---

## REFERENCES

| ID | Description | Path |
| --- | --- | --- |
| `REF-01` | Current prototype matcher implementation | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/src/detectors/prototype_punch_matcher.gd` |
| `REF-02` | Straight-only raw-XY sanity-test plan from prior session | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.plans/2026-06-15-raw-xy-shoulder-elbow-wrist-straight-sanity-test.md` |
| `REF-03` | Current boxing threshold config with straight-punch velocity and elbow/shoulder proximity concepts | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/assets/boxing.gesture_detection.yaml` |
| `REF-04` | Pose substrate measurements and available landmark/velocity context | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/src/detectors/pose_detector_substrate.gd` |
| `REF-05` | Camera tracking provider velocity accessors | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/src/providers/camera_tracking_provider.gd` |
| `REF-06` | Prototype library derivation script | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/scripts/derive_prototype_library_from_fixtures.py` |
| `REF-07` | Prototype benchmark runner | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/scripts/run_prototype_matcher_fixture_benchmark.py` |
| `REF-08` | Straight-only benchmark manifest | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.testbed/assets/benchmarks/prototype_matcher_boxing_fixture_derived_v1_straight_only.benchmark.json` |
| `REF-09` | Current straight-only prototype library artifact | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/assets/prototype_libraries/boxing_side_aware_fixture_derived_v1_straight_only/library.json` |

---

## Tasks

### Task 1: QA and audit the prior raw-XY branch for closure truth

**Bead ID:** `aerobeat-input-camera-tracking-xe9y` then `aerobeat-input-camera-tracking-2e2r`
**SubAgent:** `primary` (for `qa` then `auditor`)
**Role:** `qa` then `auditor`
**References:** `REF-01`, `REF-02`, `REF-07`, `REF-08`, `REF-09`
**Prompt:** First finish the pending QA and audit on the prior raw-XY branch so the branch recommendation is explicit and documented. QA should claim bead `aerobeat-input-camera-tracking-xe9y`, verify the raw-XY straight-only artifacts, and close it if the packet is internally consistent. Auditor should then claim bead `aerobeat-input-camera-tracking-2e2r`, truth-check the viability conclusion, and close it with a branch recommendation.

**Folders Created/Deleted/Modified:**
- relevant owning repo paths for QA/audit notes

**Files Created/Deleted/Modified:**
- `.plans/2026-06-15-raw-xy-shoulder-elbow-wrist-straight-sanity-test.md`
- QA temp rerun artifacts under `.temp/qa-rawxy-benchmark-*`

**Status:** ✅ Complete

**Results:** Completed the carry-over closure work on the prior raw-XY branch. QA verified the matcher/library wiring really uses raw `shoulder_x/y`, `elbow_x/y`, `wrist_x/y` features, confirmed the saved packet is internally consistent, and reran the straight-only benchmark for confidence. The rerun showed slight numeric jitter but the same outcome pattern. Independent audit agreed the QA conclusion holds and that the raw-XY branch is still decisively non-viable: heavy left/right cross-fire remains, the run-in-place negative control still hallucinates punches at high scores, and the representation is not separating classes robustly. Audit recommendation: do not spend another pass on raw-coordinate variants; proceed with the threshold-inspired abstract-feature experiment next.

---

### Task 2: Implement threshold-inspired straight-only prototype features and rerun sanity test

**Bead ID:** `aerobeat-input-camera-tracking-kbwz`
**SubAgent:** `primary` (for `coder`)
**Role:** `coder`
**References:** `REF-01`, `REF-03`, `REF-04`, `REF-05`, `REF-06`, `REF-07`, `REF-08`, `REF-09`
**Prompt:** Add only the threshold-inspired prototype signals Derrick requested for straights: a per-side elbow+wrist combined velocity feature over time, plus elbow-to-shoulder proximity/alignment information that can help distinguish guard from straight. Regenerate the relevant prototype artifacts and rerun the same straight-only benchmark and negative-control review packet. Keep the seam narrow and record whether the added features materially reduce false matches and improve straight-left/right truth.

**Folders Created/Deleted/Modified:**
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/src/detectors/`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/assets/prototype_libraries/`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/docs/reviews/`
- scratch/temp artifact paths as needed

**Files Created/Deleted/Modified:**
- matcher / library / benchmark / review artifacts and any minimally necessary support files

**Status:** ✅ Complete

**Results:** Added exactly two new threshold-inspired per-side prototype features while keeping the matcher architecture intact: `combined_elbow_wrist_velocity_xy_magnitude` and `elbow_shoulder_xy_distance_over_shoulder_width`. Runtime extraction in `prototype_punch_matcher.gd` now computes a rolling combined elbow+wrist 2D velocity signal from recent sample history and a normalized elbow-to-shoulder proximity scalar; `derive_prototype_library_from_fixtures.py` now emits the same feature space into regenerated library artifacts. Regenerated `boxing_side_aware_fixture_derived_v1` and the filtered `boxing_side_aware_fixture_derived_v1_straight_only` library, reran the straight-only benchmark, and wrote a new review packet at `docs/reviews/prototype-matcher-threshold-inspired-straight-review-2026-06-16.{md,summary.json}`. Outcome versus the prior raw-XY branch: positive fixtures improved from 36 expected / 29 wrong to 44 expected / 23 wrong, and run-in-place false positives improved slightly from 29 to 28, but the branch is still not viable because left/right cross-fire remains high and the negative control still hallucinates punches at high scores.

---

### Task 3: QA the threshold-inspired prototype pass

**Bead ID:** `aerobeat-input-camera-tracking-ewim`
**SubAgent:** `primary` (for `qa`)
**Role:** `qa`
**References:** `REF-01`, `REF-03`, `REF-07`, `REF-08`, `REF-09`
**Prompt:** Verify the threshold-inspired prototype pass. Confirm the matcher/library artifacts really incorporate the new elbow+wrist velocity and elbow-to-shoulder proximity features, confirm benchmark/review consistency, and state whether the result is now viable enough to justify further prototype work.

**Folders Created/Deleted/Modified:**
- relevant owning repo paths

**Files Created/Deleted/Modified:**
- QA notes/artifacts as needed

**Status:** ⏳ Pending

**Results:** Pending.

---

### Task 4: Audit the threshold-inspired result and decide prototype fate

**Bead ID:** `aerobeat-input-camera-tracking-fhzb`
**SubAgent:** `primary` (for `auditor`)
**Role:** `auditor`
**References:** `REF-01`, `REF-02`, `REF-03`, `REF-07`, `REF-08`, `REF-09`
**Prompt:** Independently audit the threshold-inspired straight-only prototype pass against the prior raw-XY branch. Decide whether the added features produced a meaningful enough improvement to justify another prototype iteration, or whether the prototype matcher should be considered structurally unfit for straight-punch detection in this dataset.

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
