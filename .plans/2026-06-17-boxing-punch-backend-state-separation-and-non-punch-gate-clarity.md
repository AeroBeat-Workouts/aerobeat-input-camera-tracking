# AeroBeat Boxing Punch Backend State Separation and Non-Punch Gate Clarity

**Date:** 2026-06-17  
**Status:** Draft  
**Last Updated:** 2026-06-17 19:05 EDT  
**Blocked Reason:** Awaiting Derrick approval to execute  
**Agent:** `pico`

---

## Goal

Diagnose why learned/prototype punch backends are not emitting punch gestures in proving, then separate punch-backend selection from non-punch threshold gating so punch and non-punch gesture state stop stepping on each other.

---

## Overview

We resumed from the latest AeroBeat handoff, which said the selectable learned-classifier branch was complete and the next slice should begin only after Derrick did real replay/live feel-testing. Derrick has now provided that proving feedback: with `punch_detection.backend = learned_classifier`, punch gestures do not fire whether `threshold_gates.enabled` is `true` or `false`; guard and other non-punch gestures still fire; `prototype_matcher` also fails to emit punch gestures; and the legacy `threshold_gates` punch path still works when selected directly. That strongly suggests a state/routing confusion seam rather than a simple threshold miss.

The likely product shape is what Derrick proposed: non-punch gestures such as guard/weave/squat should continue to use their threshold-style logic independently, while punch detection should come only from the selected punch backend. In that design, the current `threshold_gates.enabled` name is misleading because it sounds global while behaving more like a mixed punch/non-punch control surface. The first job is to verify the exact seam of the confusion in runtime/config/debug surfaces; the second job is to land the narrowest truthful restructure, including a clearer config name such as `non_punch_threshold_gates`, only if the code audit confirms that direction.

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

**Bead ID:** `Pending`  
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

**Status:** ⏳ Pending

**Results:** Pending.

---

### Task 2: Implement punch-backend separation and config clarity

**Bead ID:** `Pending`  
**SubAgent:** `primary` (for `coder`)  
**Role:** `coder`  
**References:** `REF-02`, `REF-03`, `REF-04`, `REF-05`, `REF-06`, `REF-07`, `REF-08`  
**Prompt:** Implement the approved runtime/config fix so the selected punch backend (`threshold_gates`, `prototype_matcher`, or `learned_classifier`) owns punch emission cleanly, while non-punch threshold-based gestures remain independent. If diagnosis confirms Derrick’s naming concern, rename the mixed/global `threshold_gates` surface to a clearer non-punch-specific name such as `non_punch_threshold_gates`, and update config loading, docs, proving/debug UI, and tests truthfully. Preserve backward compatibility only if the plan/results explicitly require it. Claim the bead on start with `bd update <ID> --status in_progress --json`, run relevant repo-local validation, and commit/push before handoff unless blocked.

**Folders Created/Deleted/Modified:**
- relevant repo paths discovered in Task 1

**Files Created/Deleted/Modified:**
- relevant repo files discovered in Task 1

**Status:** ⏳ Pending

**Results:** Pending.

---

### Task 3: QA replay/proving behavior across punch and non-punch gesture flows

**Bead ID:** `Pending`  
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

**Bead ID:** `Pending`  
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
