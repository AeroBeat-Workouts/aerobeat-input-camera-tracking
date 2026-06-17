# AeroBeat Boxing Hybrid Classifier YAML-Selectable Proving Branch

**Date:** 2026-06-17  
**Status:** Complete  
**Last Updated:** 2026-06-17 16:55 EDT  
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

**Status:** ✅ Complete

**Results:** QA PASS. Verified the boxing YAML keeps `punch_detection.backend: threshold_gates` as the default while exposing a first-class `learned_classifier` section with truthful defaults (`enabled: false`, exported model path, score/timing/debug keys) matching the public contract in `docs/cross-repo-config-contract.md`. Verified runtime selector truth in `pose_detector_substrate.gd`: `prototype_matcher` and `learned_classifier` only activate when both selected and enabled, disabled selector cases resolve to `none` instead of silently falling back to threshold gates, and threshold mode still remains the default active path when selected/enabled. Verified proving override truth in `.testbed/scripts/proving_harness.gd` for `AEROBEAT_PUNCH_BACKEND_OVERRIDE=learned_classifier`, including forced selector mutation, threshold disablement, learned enablement, and learned-specific event payload/timeline capture. Verified proving-scene surfaces in `.testbed/scripts/boxing_proving_harness.gd` now branch on `gesture_debug.punch_detection.backend` and show learned-classifier hover card / inspector / event-feed truth instead of threshold fallback fiction. Re-ran the focused suite with `godot --headless --path .testbed --script addons/aerobeat-vendor-godot-unit-test/gut_cmdln.gd -gtest=res://tests/unit/test_camera_tracking_config_profiles.gd -gtest=res://tests/unit/test_pose_detector_substrate.gd -gtest=res://tests/unit/test_boxing_proving_harness_profiles_and_debug.gd -gtest=res://tests/unit/test_proving_harness_fixture_timeline.gd -gexit` and got 104/104 passing, exit code 0. Observed existing non-failing GUT/vendor warnings only (invalid UID warnings, orphan counts in proving-harness tests, and leak warnings on shutdown); no learned-backend regression or truth gap found in scope.

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

**Status:** ✅ Complete

**Results:** Audit PASS. Independently verified the selector path from public contract/YAML through runtime and proving surfaces: `docs/cross-repo-config-contract.md` and `assets/boxing.gesture_detection.yaml` now expose `punch_detection.backend: threshold_gates|prototype_matcher|learned_classifier` with `learned_classifier.enabled`, model artifact path, threshold, timing, and debug keys; `pose_detector_substrate.gd` truthfully resolves active backend to `threshold_gates`, `prototype_matcher`, `learned_classifier`, or `none` based on the selected backend plus that backend’s enable flag; and `.testbed/scripts/proving_harness.gd` plus `.testbed/scripts/boxing_proving_harness.gd` now preserve learned-backend truth in runtime override, event payloads, hover cards, inspector text, and event-feed/timeline snapshots instead of silently falling back to threshold fiction. Independently reran the focused verification suite with `godot --headless --path .testbed --script addons/aerobeat-vendor-godot-unit-test/gut_cmdln.gd -gtest=res://tests/unit/test_camera_tracking_config_profiles.gd -gtest=res://tests/unit/test_pose_detector_substrate.gd -gtest=res://tests/unit/test_boxing_proving_harness_profiles_and_debug.gd -gtest=res://tests/unit/test_proving_harness_fixture_timeline.gd -gexit` and got 104/104 passing, exit code 0. That rerun included threshold defaults, prototype matcher behavior, learned-classifier routing, proving override truth, and fixture timeline capture, so QA evidence is credible and no selector-shape regression surfaced for the existing threshold/prototype paths. Practical verdict: this slice is usable for proving evaluation now — Derrick has a real path to replay/live feel-testing by selecting `learned_classifier` in boxing config or forcing `AEROBEAT_PUNCH_BACKEND_OVERRIDE=learned_classifier` in the proving harness — but it is only a proving/evaluation lane, not evidence that the learned backend is tuned enough to replace the default. The next slice should therefore be proving-time feel evaluation and threshold/timing calibration against replay and live sessions, not more wiring.

---

## Final Results

**Status:** ✅ Complete

**What We Built:** Added a truthful, selectable `learned_classifier` boxing backend path from config contract and boxing YAML through runtime selection and proving-scene truth surfaces, while preserving `threshold_gates` as the default and leaving `prototype_matcher` intact as another explicit proving option. The proving harness can now exercise the learned backend for replay/live evaluation via config selection or `AEROBEAT_PUNCH_BACKEND_OVERRIDE=learned_classifier`, and the boxing proving UI/event/timeline surfaces report learned-backend-specific truth instead of threshold fallback fiction.

**Reference Check:** `REF-01` and `REF-02` are satisfied by the new public selector/config surface and defaults; `REF-03` now routes threshold/prototype/learned backends truthfully and reports `none` instead of silently falling back when a selected non-threshold backend is disabled; `REF-04` and `REF-05` now surface learned-classifier runtime/debug truth in proving overrides, event payloads, hover cards, inspector text, and timeline capture; `REF-07` remains honored because the learned backend is surfaced as an explicit proving option only and does not replace the threshold default.

**Commits:**
- `8010c09` - Add selectable learned boxing classifier backend

**Lessons Learned:** The key success condition for this slice was honest runtime/proving wiring, not model promotion. This branch clears the wiring gate and gives Derrick a real feel-testing path now; the next decision should come from replay/live proving evidence and calibration, not from more contract plumbing.

---

*Completed on 2026-06-17*