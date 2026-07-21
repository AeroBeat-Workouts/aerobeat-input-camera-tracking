# AeroBeat Camera Tracking Calibration UI and Grid Inspector Simplification

**Date:** 2026-07-21  
**Status:** Complete  
**Last Updated:** 2026-07-21 08:58 EDT  
**Blocked Reason:** None  
**Agent:** `pico`

---

## Goal

Simplify athlete calibration UX and inspector/proving-scene grid presentation in the input-camera-tracking testbed so the UI shows less instructional clutter and more direct state.

---

## Overview

Derrick provided a new UI-focused follow-up seam for `aerobeat-input-camera-tracking/.testbed/` and explicitly approved sending a subagent in parallel while the current BeatSaver preview-audio seam continues elsewhere. This repo owns the change because the calibration workflow, Flow/Boxing test scenes, and proving-scene grid/debug UI all live in the camera-tracking repo and its `.testbed/` project.

The requested direction is to simplify rather than add more safeguards. Athlete calibration should stop requiring center-of-screen and visible T-pose checks as preconditions in the instructional UI. The calibration action should instead communicate state through button text, failing only when wrist data is not available at capture completion. On the inspector/proving side, the bulky `Grid truth` textual section should be removed and replaced by the compact visual cell widgets Derrick already likes, keeping nose/left-wrist/right-wrist occupancy visible and simplifying wrist-direction rendering down to arrow-only cells. The Boxing proving scene should gain the same compact visual grid preview treatment for nose and wrists instead of its current textual truth block.

Execution will follow the normal loop inside this repo: coder implements the UI behavior and scene changes, then QA verifies the scene/testbed behavior, then an auditor truth-checks the slice before the bead closes.

---

## REFERENCES

| ID | Description | Path |
| --- | --- | --- |
| `REF-01` | Derrick request for calibration button states and inspector/proving-scene cleanup | This chat message on 2026-07-21 08:17 EDT |
| `REF-02` | Uploaded screenshot showing current calibration failure copy and retry button | `/home/derrick/.openclaw/workspace/.temp/nerve-uploads/2026/07/21/image-5eef3488.png` |
| `REF-03` | Uploaded screenshot showing current `Grid truth` textual block | `/home/derrick/.openclaw/workspace/.temp/nerve-uploads/2026/07/21/image-43cf5bfd.png` |
| `REF-04` | Uploaded screenshot showing preferred compact cell display pattern | `/home/derrick/.openclaw/workspace/.temp/nerve-uploads/2026/07/21/image-419db5c7.png` |

---

## Tasks

### Task 1: Implement calibration button-state UX and compact grid inspector/proving panels

**Bead ID:** `aerobeat-input-camera-tracking-aebc`  
**SubAgent:** `primary` (for `coder`)  
**Role:** `coder`  
**References:** `REF-01`, `REF-02`, `REF-03`, `REF-04`  
**Prompt:** In `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking`, implement Derrick’s requested `.testbed/` UI simplification slice. Claim the bead on start with `bd update <id> --status in_progress --json`. Required changes: (1) simplify athlete calibration by removing the center-of-screen/T-pose safeguard messaging and using button text to communicate state: `Calibrate Athlete`, `Hold T-Pose... 5s`, `Calibrate Athlete` after success, and `Error, Press To Try Again` on failure; the calibration should fail only when the required wrist data is unavailable at countdown completion. (2) Remove the `Grid Truth` text sections from the Flow and Boxing testing/proving right panels. (3) Keep/show compact visual grid-cell widgets for Nose, Left Wrist, and Right Wrist occupancy, including adding Nose where missing in the Flow inspector. (4) Remove the `Calibrated 4x3 athlete-relative grid` explanatory text from those widgets. (5) Simplify wrist-direction cells to arrow-only presentation with no extra text. (6) In the boxing proving scene, replace the textual truth block with the same compact visual grid preview style for nose and wrists. Keep scope bounded to this repo/testbed/UI seam, run the strongest available repo-local validation, commit, and push to `main` before handoff. Do not close the bead; leave it ready for QA with exact evidence.

**Folders Created/Deleted/Modified:**
- `.testbed/`
- `src/`
- scene/ui folders as needed

**Files Created/Deleted/Modified:**
- `.testbed/scripts/proving_harness.gd`
- `.testbed/scripts/flow_ring_chart.gd`
- `.testbed/scenes/flow_proving.tscn`
- `.testbed/scenes/boxing_proving.tscn`
- `src/detectors/pose_detector_substrate.gd`
- `.testbed/tests/unit/test_pose_detector_substrate.gd`
- `.testbed/tests/unit/test_boxing_proving_harness_profiles_and_debug.gd`

**Status:** ✅ Complete

**Results:** Coder implemented the `.testbed/` UI simplification slice and pushed commit `ed4834b` (`Simplify calibration and grid truth testbed UI`). Athlete calibration no longer exposes centered-in-camera/checklist-style T-pose guidance in the visible UI, and button states now map to `Calibrate Athlete`, `Hold T-Pose... 5s`, `Calibrate Athlete` after success, and `Error, Press To Try Again` on failure. Calibration failure behavior was tightened so the session now fails on missing wrist data at countdown completion instead of center/T-pose gating, and readiness logic no longer blocks on centered/T-pose requirements. The bulky `Grid truth` textual sections were removed from Flow + Boxing right panels, compact occupancy widgets for Nose/Left Wrist/Right Wrist were kept or added, the explanatory `Calibrated 4x3 athlete-relative grid` subtitle text was removed, wrist-direction widgets were simplified to arrow-only rendering, and the Boxing proving scene now uses the same compact grid-preview style instead of the old textual truth block. Repo-local validation passed via targeted GUT runs: `test_pose_detector_substrate.gd` (74/74), `test_boxing_proving_harness_profiles_and_debug.gd -gunit_test_name=shared_calibration` (3/3), and `test_boxing_proving_harness_profiles_and_debug.gd -gunit_test_name=grid_truth` (2/2). Honest remaining gap: manual scene-level visual QA is still needed in Godot for final spacing/card sizing, boxing right-panel compact previews against live/replay data, and calibration button/state feel during real countdown/capture timing. The coder did not chase unrelated depth-debug failures from a broader full test run to avoid scope drift.

---

### Task 2: QA calibration UX and grid inspector/proving simplification

**Bead ID:** `aerobeat-input-camera-tracking-xiyr`  
**SubAgent:** `primary` (for `qa`)  
**Role:** `qa`  
**References:** `REF-01`, `REF-02`, `REF-03`, `REF-04`  
**Prompt:** Verify at the highest-fidelity repo-local level available that the calibration button-state UX and compact grid inspector/proving UI are truthful and bounded. Confirm the calibration states/copy, removal of the old `Grid truth` sections, presence of compact occupancy widgets for Nose/Left Wrist/Right Wrist, removal of the explanatory grid text, and arrow-only wrist direction presentation. Re-run the strongest relevant validation and inspect scene output as needed. Do not self-implement missing work; report exact evidence and whether the slice is ready for audit.

**Folders Created/Deleted/Modified:**
- verification-only if needed

**Files Created/Deleted/Modified:**
- verification notes only if needed

**Status:** ✅ Complete

**Results:** QA completed on commit `ed4834b` and marked the slice ready for audit. Targeted proving-harness and substrate tests passed, including the shared calibration flow/cancel routes, prerecorded replay calibration attempts, shared grid-preview panel behavior, replay auto-bootstrap truth hiding, shared calibration success/failure truth, readiness requiring only live left/right wrist data, countdown completion committing the baseline only after capture window, and failure when countdown finishes without wrist data. Acceptance checks passed for the requested seam: button-state copy matches the requested states; visible center-of-screen / checklist-style T-pose gating is gone; failure now flows from wrist-data-unavailable at countdown completion; `Grid truth` text sections are removed from the visible Flow + Boxing right panels; compact Nose/Left Wrist/Right Wrist occupancy widgets exist including Nose in Flow; the `Calibrated 4x3 athlete-relative grid` subtitle is absent from the active widgets; wrist-direction widgets are arrow-only; and Boxing uses the compact visual grid-preview style instead of the old textual truth block. Honest caveats: `flow_proving.tscn` still contains dormant hidden placeholder `Grid truth` source text even though runtime empties/hides it, and a manual in-editor visual pass is still advisable for final spacing/sizing, live/replay panel look, and calibration countdown/capture feel. Broader unrelated depth-debug copy assertions remain failing outside this seam and were correctly treated as non-slice noise.

---

### Task 3: Audit calibration UX and grid inspector/proving simplification

**Bead ID:** `aerobeat-input-camera-tracking-nthx`  
**SubAgent:** `primary` (for `auditor`)  
**Role:** `auditor`  
**References:** `REF-01`, `REF-02`, `REF-03`, `REF-04`  
**Prompt:** Independently audit the calibration UX and compact grid inspector/proving UI slice against the request, screenshots, diffs, validation evidence, and scene output. Confirm the slice stayed bounded to the requested `.testbed/` UI/behavior cleanup and close the relevant bead(s) if it passes. If it fails, leave the bead open and report the exact gap.

**Folders Created/Deleted/Modified:**
- audit-only if needed

**Files Created/Deleted/Modified:**
- audit notes only if needed

**Status:** ✅ Complete

**Results:** Auditor passed the `.testbed/` calibration UI + compact grid inspector/proving simplification seam on commit `ed4834b` and closed bead `aerobeat-input-camera-tracking-nthx`. The audit re-ran the strongest relevant targeted validation (`test_pose_detector_substrate.gd`, shared-calibration proving-harness tests, and grid-truth proving-harness tests), inspected the scene/script/test changes, and confirmed the requested visible behavior is in place: requested button-state copy, no active center/T-pose checklist gating in the visible UI, failure on missing wrist data at countdown completion, visible `Grid truth` text removed from active Flow + Boxing panels, compact Nose/Left Wrist/Right Wrist occupancy widgets including Nose in Flow, no active `Calibrated 4x3 athlete-relative grid` subtitle, arrow-only wrist-direction widgets, and Boxing using the compact visual grid-preview panel instead of the old textual truth block. The audit agreed with QA that the remaining manual in-editor visual pass is a real but non-blocking presentation caveat, and that the dormant hidden `Grid truth` placeholder text still present in `flow_proving.tscn` is not a blocker because runtime empties/hides it. The implementation bead `aerobeat-input-camera-tracking-aebc` can be treated as complete for this seam, and the remaining QA bead was closed during orchestrator cleanup.

---

## Final Results

**Status:** ✅ Complete

**What We Built:** Simplified the input-camera-tracking `.testbed/` athlete-calibration and proving-scene debug UX. Calibration now communicates state primarily through the button text and fails on missing wrist data at capture completion instead of visible center/T-pose checklist gating. Flow + Boxing proving/test panels now favor compact occupancy widgets for Nose/Left Wrist/Right Wrist, arrow-only wrist-direction displays, and the compact visual grid-preview pattern instead of the old bulky `Grid truth` text blocks.

**Reference Check:** `REF-01`..`REF-04` satisfied. The implementation matches Derrick’s requested calibration button states and compact panel direction, while keeping one honest non-blocking caveat that final in-editor visual presentation should still be manually checked.

**Commits:**
- `ed4834b` - Simplify calibration and grid truth testbed UI

**Lessons Learned:** For this proving/testbed UX, compact visual occupancy widgets communicated the important information much better than verbose textual truth blocks. Also, targeted repo-local tests were strong enough to validate the behavior slice without widening into unrelated depth-debug assertion failures.

---

*Started on 2026-07-21*
