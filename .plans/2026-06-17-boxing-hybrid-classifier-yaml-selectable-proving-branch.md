# AeroBeat Boxing Hybrid Classifier YAML-Selectable Proving Branch

**Date:** 2026-06-17  
**Status:** In Progress  
**Last Updated:** 2026-06-17 11:31 EDT  
**Blocked Reason:** None  
**Agent:** `pico`

---

## Goal

Make the new hybrid threshold-plus-classifier punch system a selectable boxing YAML backend in `aerobeat-input-camera-tracking`, then verify it can actually be exercised in the `/.testbed/` boxing proving scene for replay videos and live gameplay.

---

## Overview

The current state already supports public boxing backend selection between `threshold_gates` and `prototype_matcher`, and earlier work explicitly reserved `learned_classifier` as a future backend in the shared config contract. Memory also records that we intentionally froze the YAML/config contract so the same boxing config home could swap detector families over time instead of inventing a new surface later. Source: `memory/2026-06-12.md#L10-L19`.

The next branch should be product-facing rather than benchmark-facing. We are not trying to crown a new classifier today. We are trying to wire the hybrid classifier path into the real runtime as a user-selectable boxing option so Derrick can judge how it feels in actual replay videos and live proving-scene gameplay. That means the core work is configuration/routing truth, runtime integration, and testbed usability — not more frozen-benchmark tuning.

This branch should stay narrow and honest. The audit on the repaired CNN packet said the tuned wider-`k=3` CNN is exploratory only and should not be promoted as the new default. So this plan assumes the stable reference remains the prior frozen CNN line, and the implementation goal is to surface the hybrid classifier backend as an explicit selectable option for proving-scene evaluation without silently replacing the current threshold default.

---

## REFERENCES

| ID | Description | Path |
| --- | --- | --- |
| `REF-01` | Public boxing config contract showing backend selector reserved for `learned_classifier` | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/docs/cross-repo-config-contract.md` |
| `REF-02` | Current boxing gesture YAML with threshold/prototype backend surfaces | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/assets/boxing.gesture_detection.yaml` |
| `REF-03` | Runtime backend selection logic in pose detector substrate | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/src/detectors/pose_detector_substrate.gd` |
| `REF-04` | Boxing proving harness runtime config / backend display path | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.testbed/scripts/boxing_proving_harness.gd` |
| `REF-05` | Boxing proving harness/unit tests around profiles/debug/backend selection | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.testbed/tests/unit/test_boxing_proving_harness_profiles_and_debug.gd` |
| `REF-06` | Classifier evaluation/data hardening context | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.plans/2026-06-16-boxing-classifier-eval-and-data-hardening.md` |
| `REF-07` | Corrected CNN artifact/audit result establishing current classifier status | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.plans/2026-06-17-boxing-classifier-frozen-benchmark-cnn-artifact-consistency-fix.md` |

---

## Tasks

### Task 1: Design the YAML/backend integration seam for the hybrid classifier path

**Bead ID:** `aerobeat-input-camera-tracking-nsd9`  
**SubAgent:** `primary` (for `research`)  
**Role:** `research`  
**References:** `REF-01`, `REF-02`, `REF-03`, `REF-04`, `REF-05`, `REF-07`  
**Prompt:** Inspect the existing boxing backend selector contract and runtime routing. Determine the minimum truthful implementation seam needed to add the hybrid classifier path as a selectable backend in YAML and the proving runtime without breaking threshold/prototype selection. Identify exact config keys, loader/routing points, proving-scene display surfaces, and validation expectations.

**Folders Created/Deleted/Modified:**
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/assets/`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/src/`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.testbed/`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.plans/`

**Files Created/Deleted/Modified:**
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/assets/boxing.gesture_detection.yaml`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/docs/cross-repo-config-contract.md`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/src/detectors/pose_detector_substrate.gd`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/src/detectors/learned_punch_classifier.gd` (new likely runtime seam)
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.testbed/scripts/proving_harness.gd`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.testbed/scripts/boxing_proving_harness.gd`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.testbed/tests/unit/test_camera_tracking_config_profiles.gd`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.testbed/tests/unit/test_aero_camera_tracking.gd`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.testbed/tests/unit/test_boxing_proving_harness_profiles_and_debug.gd`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.testbed/tests/unit/test_proving_harness_fixture_timeline.gd`

**Status:** ✅ Complete

**Results:** Research pass complete. The current selector seam is real but only two-way: boxing YAML and bundle loading already preserve `punch_detection.backend`, yet runtime routing in `pose_detector_substrate.gd` only activates `prototype_matcher` or falls back to `threshold_gates`, and the proving runtime override in `.testbed/scripts/proving_harness.gd` only knows `prototype_matcher`. Minimum truthful implementation slice: add a first-class `learned_classifier` config section (at least `enabled`, model/artifact locator, score threshold, emit timing, and debug visibility flags), wire a new learned-classifier runtime object through `PoseDetectorSubstrate.configure/reset/process`, extend the selector/debug helpers so selected/active backend truth can report `learned_classifier`, and add proving-scene override/hover-card/inspector surfaces so punch cards stop pretending threshold state when the learned backend is active. Keep guard/weave/squat and the existing threshold/prototype behavior unchanged; the new backend only needs to own punch event generation. Focused tests should prove bundle truth, runtime selector truth, proving override truth, hover/inspector truth, and fixture timeline truth for `learned_classifier` without regressing the current threshold/prototype paths.

---

### Task 2: Implement the selectable hybrid classifier backend and proving-scene wiring

**Bead ID:** `aerobeat-input-camera-tracking-rl8t`  
**SubAgent:** `primary` (for `coder`)  
**Role:** `coder`  
**References:** `REF-01`, `REF-02`, `REF-03`, `REF-04`, `REF-05`, `REF-06`, `REF-07`  
**Prompt:** Implement the approved minimum slice to make the hybrid classifier/threshold system a selectable boxing backend in YAML and runtime. Keep threshold_gates as the safe default unless the plan is updated otherwise. Ensure the proving scene can load the backend truthfully for replay and live evaluation, and update/add focused tests so config selection, runtime routing, and debug presentation all stay honest.

**Folders Created/Deleted/Modified:**
- relevant repo paths discovered in Task 1

**Files Created/Deleted/Modified:**
- `assets/boxing.gesture_detection.yaml`
- `docs/cross-repo-config-contract.md`
- `src/detectors/pose_detector_substrate.gd`
- `src/detectors/learned_punch_classifier.gd`
- `.testbed/scripts/proving_harness.gd`
- `.testbed/scripts/boxing_proving_harness.gd`
- `.testbed/tests/unit/test_camera_tracking_config_profiles.gd`
- `.testbed/tests/unit/test_pose_detector_substrate.gd`
- `.testbed/tests/unit/test_boxing_proving_harness_profiles_and_debug.gd`
- `.testbed/tests/unit/test_proving_harness_fixture_timeline.gd`

**Status:** ✅ Complete

**Results:** Added a selectable `learned_classifier` backend end-to-end for the boxing config/runtime seam without changing the default `threshold_gates` selection. Wired `pose_detector_substrate.gd` to resolve threshold/prototype/learned backends truthfully, added `src/detectors/learned_punch_classifier.gd` as the minimum runtime MLP-backed classifier path using exported model artifacts, extended proving-harness override/timeline/event payload plumbing to recognize `learned_classifier`, and updated boxing proving hover/debug/event-feed surfaces so learned truth no longer falls back to threshold fiction. Added focused config/routing/proving/timeline tests plus a substrate unit test that injects a tiny deterministic learned-model artifact to exercise learned-backend emission honestly. Validation run: `godot --headless --path .testbed --script addons/aerobeat-vendor-godot-unit-test/gut_cmdln.gd -gtest=res://tests/unit/test_camera_tracking_config_profiles.gd,res://tests/unit/test_pose_detector_substrate.gd,res://tests/unit/test_boxing_proving_harness_profiles_and_debug.gd,res://tests/unit/test_proving_harness_fixture_timeline.gd -gexit` (104/104 passed; existing GUT orphan/invalid-UID warnings remain in touched proving-harness tests/vendor assets).

---

### Task 3: QA the new selectable hybrid backend in replay/live-facing proving flows

**Bead ID:** `aerobeat-input-camera-tracking-m5dm`  
**SubAgent:** `primary` (for `qa`)  
**Role:** `qa`  
**References:** `REF-02`, `REF-03`, `REF-04`, `REF-05`, `REF-06`, `REF-07`  
**Prompt:** Verify the new backend is actually selectable from the boxing YAML/config path, that the proving scene surfaces the selected/active backend truthfully, and that at least one replay-facing and one live-facing validation path can exercise the classifier backend without breaking existing threshold behavior.

**Folders Created/Deleted/Modified:**
- relevant owning repo paths

**Files Created/Deleted/Modified:**
- QA notes/artifacts as needed

**Status:** ⏳ Pending

**Results:** Pending.

---

### Task 4: Audit the selectable hybrid backend branch and recommend the next proving/tuning slice

**Bead ID:** `aerobeat-input-camera-tracking-3450`  
**SubAgent:** `primary` (for `auditor`)  
**Role:** `auditor`  
**References:** `REF-01`, `REF-02`, `REF-03`, `REF-04`, `REF-05`, `REF-06`, `REF-07`  
**Prompt:** Independently truth-check that the hybrid classifier backend is selectable, that the proving-scene/runtime wiring is honest, and that the branch actually leaves Derrick with a usable path for replay/live feel-testing. Recommend the next slice explicitly: tuning, UX/debugging, fixture capture, or rollback.

**Folders Created/Deleted/Modified:**
- relevant owning repo paths

**Files Created/Deleted/Modified:**
- audit notes/artifacts as needed

**Status:** ⏳ Pending

**Results:** Pending.

---

## Final Results

**Status:** ⚠️ Partial

**What We Built:** Draft plan only so far.

**Reference Check:** Planning assumes the config contract already reserved `learned_classifier` as a backend surface (`REF-01`) and that current classifier audit status remains “usable for exploration, not promoted as default” (`REF-07`).

**Commits:**
- Pending.

**Lessons Learned:** If this branch works, the important win is not benchmark bragging rights; it is getting the classifier into the same truthful proving/testbed surfaces as the other boxing backends so feel-testing can drive the next decisions.

---

*Completed on 2026-06-17*