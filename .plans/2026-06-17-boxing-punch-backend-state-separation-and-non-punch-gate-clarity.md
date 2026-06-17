# AeroBeat Boxing Punch Backend State Separation and Non-Punch Gate Clarity

**Date:** 2026-06-17  
**Status:** In Progress  
**Last Updated:** 2026-06-17 19:10 EDT  
**Blocked Reason:** None  
**Agent:** `pico`

---

## Goal

Diagnose why learned/prototype punch backends are not emitting punch gestures in proving, then separate punch-backend selection from non-punch threshold gating so punch and non-punch gesture state stop stepping on each other.

---

## Overview

We resumed from the latest AeroBeat handoff, which said the selectable learned-classifier branch was complete and the next slice should begin only after Derrick did real replay/live feel-testing. Derrick has now provided that proving feedback: with `punch_detection.backend = learned_classifier`, punch gestures do not fire whether `threshold_gates.enabled` is `true` or `false`; guard and other non-punch gestures still fire; `prototype_matcher` also fails to emit punch gestures; and the legacy `threshold_gates` punch path still works when selected directly. That strongly suggests a state/routing confusion seam rather than a simple threshold miss.

The likely product shape is what Derrick proposed at first: non-punch gestures such as guard/weave/squat should continue to use their threshold-style logic independently, while punch detection should come only from the selected punch backend. Research confirmed the architecture already mostly works that way, and Derrick then clarified that no config rename is needed now that the YAML meaning is understood. So the implementation focus is narrower: verify/fix the selector-vs-enabled confusion seam, improve debug truth, and preserve the existing `threshold_gates` naming unless implementation evidence forces a stronger reason to change it.

This plan should stay product-truthful. We are not doing another benchmark branch. We are fixing proving/runtime behavior so selecting `learned_classifier` or `prototype_matcher` can actually own punch emission while non-punch gesture detection remains stable and clearly configured.

---

## REFERENCES

| ID | Description | Path |
| --- | --- | --- |
| `REF-01` | Latest AeroBeat classifier proving handoff | `/home/derrick/.openclaw/workspace/projects/openclaw-pico/handoffs/handoff-2026-06-17T16-56-00-04-00.md` |
| `REF-02` | Current public boxing config contract | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/docs/cross-repo-config-contract.md` |
| `REF-03` | Current boxing gesture config YAML | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/assets/boxing.gesture_detection.yaml` |
| `REF-04` | Runtime gesture backend routing substrate | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/src/detectors/pose_detector_substrate.gd` |
| `REF-05` | Learned punch backend implementation seam | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/src/detectors/learned_punch_classifier.gd` |
| `REF-06` | Prototype punch backend implementation seam | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/src/detectors/prototype_punch_matcher.gd` |
| `REF-07` | Boxing proving runtime/debug UI surface | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.testbed/scripts/boxing_proving_harness.gd` |
| `REF-08` | Prior selectable learned-backend integration plan/results | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.plans/archive/2026-06-17-boxing-hybrid-classifier-yaml-selectable-proving-branch.md` |
| `REF-09` | Derrick’s proving screenshot / config context | `/home/derrick/.openclaw/workspace/.temp/nerve-uploads/2026/06/17/image-91edd872.png` |

---

## Tasks

### Task 1: Diagnose the punch/non-punch state confusion seam

**Bead ID:** `aerobeat-input-camera-tracking-l84a`  
**SubAgent:** `primary` (for `research`)  
**Role:** `research`  
**References:** `REF-01`, `REF-02`, `REF-03`, `REF-04`, `REF-05`, `REF-06`, `REF-07`, `REF-08`, `REF-09`  
**Prompt:** Inspect the boxing config/runtime/proving path to identify exactly why `learned_classifier` and `prototype_matcher` are not emitting punch gestures while non-punch gestures still fire. Determine whether `threshold_gates.enabled` is currently acting as a mixed global gate, whether punch routing is being shadowed by non-punch state, and what the minimum truthful separation/refactor should be. Include exact files, config keys, runtime branches, and validation expectations. Claim the bead on start with `bd update <ID> --status in_progress --json` and leave clear notes/results for the implementation handoff.

**Folders Created/Deleted/Modified:**
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/assets/`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/src/`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.testbed/`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.plans/`

**Files Created/Deleted/Modified:**
- `assets/boxing.gesture_detection.yaml`
- `docs/cross-repo-config-contract.md`
- `src/detectors/pose_detector_substrate.gd`
- `src/detectors/learned_punch_classifier.gd`
- `src/detectors/prototype_punch_matcher.gd`
- `.testbed/scripts/boxing_proving_harness.gd`
- relevant focused tests under `.testbed/tests/unit/`

**Status:** ✅ Complete

**Results:** Research diagnosis complete. The reported proving failure is not caused by guard/weave/squat or other non-punch detectors shadowing punch routing. In `src/detectors/pose_detector_substrate.gd`, non-punch gestures are processed independently before the punch-backend branch, and punch routing is selected afterward based on `punch_detection.backend` plus the backend-specific `enabled` flag. The actual failure seam is selector/enable-state confusion: when `punch_detection.backend` is switched to `learned_classifier` or `prototype_matcher` but that backend’s own `enabled` key remains `false`, the active punch backend resolves to `none`, so no punches emit while non-punch gestures continue normally. Existing unit coverage already proves that disabled selected backends do not fall back to threshold mode. The misleading piece is naming: `threshold_gates.enabled` is not a global threshold/non-punch switch; it is only the enable flag for the legacy threshold punch backend. Recommended implementation slice: keep the architecture where the selected punch backend owns punch emission and non-punch gestures remain independently threshold-driven, rename the legacy `threshold_gates` surface to something punch-specific such as `threshold_punch_backend` or `legacy_threshold_punch_backend`, preserve backward compatibility by reading the new key first and falling back to `threshold_gates`, and clarify debug output so selected-vs-enabled-vs-active backend truth is obvious.

---

### Task 2: Implement punch-backend separation and config clarity

**Bead ID:** `aerobeat-input-camera-tracking-l7es`  
**SubAgent:** `primary` (for `coder`)  
**Role:** `coder`  
**References:** `REF-02`, `REF-03`, `REF-04`, `REF-05`, `REF-06`, `REF-07`, `REF-08`  
**Prompt:** Implement the approved runtime/config fix so the selected punch backend (`threshold_gates`, `prototype_matcher`, or `learned_classifier`) owns punch emission cleanly, while non-punch threshold-based gestures remain independent. Research showed the main issue is selector-vs-enabled confusion rather than non-punch shadowing, and Derrick has clarified that no config rename is needed now that the YAML meaning is understood. Keep the existing `threshold_gates` naming unless code-level evidence reveals a stronger reason to change it. Update config loading, docs, proving/debug UI, and tests truthfully around selected-vs-enabled-vs-active backend state. Preserve backward compatibility where needed. Claim the bead on start with `bd update <ID> --status in_progress --json`, run relevant repo-local validation, and commit/push before handoff unless blocked.

**Folders Created/Deleted/Modified:**
- relevant repo paths discovered in Task 1

**Files Created/Deleted/Modified:**
- `docs/cross-repo-config-contract.md`
- `assets/boxing.gesture_detection.yaml`
- `src/detectors/pose_detector_substrate.gd`
- `src/detectors/learned_punch_classifier.gd`
- `src/detectors/prototype_punch_matcher.gd`
- `.testbed/scripts/proving_harness.gd`
- `.testbed/scripts/boxing_proving_harness.gd`
- `.testbed/tests/unit/test_pose_detector_substrate.gd`
- `.testbed/tests/unit/test_boxing_proving_harness_profiles_and_debug.gd`

**Status:** ✅ Complete

**Results:** Narrowed the slice per Derrick to keep `threshold_gates` named as-is and focus purely on selector/enable-state truth. Updated runtime/debug reporting so punch debug now exposes `selected_backend`, `selected_backend_enabled`, `active_backend`, and `active_backend_resolution`, making it explicit when a selected backend is disabled and therefore resolves to `none` rather than silently falling back. Kept non-punch gesture processing untouched and independent. Updated proving runtime override handling plus boxing proving/event-feed text so selected-vs-active backend state is visible during bench/debug work. Tightened docs/YAML comments to state that `threshold_gates.enabled` only controls the threshold-gated punch backend. Added focused unit coverage for disabled selected backends and proving/event-feed truth. Focused validation passed via `godot --headless --path .testbed --script addons/aerobeat-vendor-godot-unit-test/gut_cmdln.gd -gtest=res://tests/unit/test_pose_detector_substrate.gd,res://tests/unit/test_boxing_proving_harness_profiles_and_debug.gd,res://tests/unit/test_camera_tracking_config_profiles.gd,res://tests/unit/test_aero_camera_tracking.gd -gexit` (118/118 passing).

---

### Task 3: QA replay/proving behavior across punch and non-punch gesture flows

**Bead ID:** `aerobeat-input-camera-tracking-j8x8`  
**SubAgent:** `primary` (for `qa`)  
**Role:** `qa`  
**References:** `REF-03`, `REF-04`, `REF-05`, `REF-06`, `REF-07`  
**Prompt:** Verify end-to-end that `learned_classifier` and `prototype_matcher` can actually emit punch gestures in the proving flow after the fix, that `threshold_gates` still works when selected for punches, and that guard/weave/squat or other non-punch gestures continue to function independently under the clarified non-punch threshold configuration. Validate both focused tests and the highest-fidelity proving path available. Claim the bead on start with `bd update <ID> --status in_progress --json` and leave concrete evidence for audit.

**Folders Created/Deleted/Modified:**
- relevant owning repo paths

**Files Created/Deleted/Modified:**
- QA notes/artifacts as needed

**Status:** ⏳ Pending

**Results:** Pending.

---

### Task 4: Audit the final behavior and config truth

**Bead ID:** `aerobeat-input-camera-tracking-h9tn`  
**SubAgent:** `primary` (for `auditor`)  
**Role:** `auditor`  
**References:** `REF-02`, `REF-03`, `REF-04`, `REF-05`, `REF-06`, `REF-07`, `REF-08`  
**Prompt:** Independently truth-check that punch-backend selection and non-punch threshold gating are now properly separated, that config/docs/debug surfaces accurately describe the behavior, and that the fix addresses Derrick’s reported proving failure rather than masking it. Confirm whether the rename/config contract is clear enough for future tuning work. Claim the bead on start with `bd update <ID> --status in_progress --json` and close the bead only if the work is truly complete.

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
- Pending

**Lessons Learned:** Pending.

---

*Completed on Pending*
