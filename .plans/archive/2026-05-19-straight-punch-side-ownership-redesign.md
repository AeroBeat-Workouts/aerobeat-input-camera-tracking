# AeroBeat MediaPipe Python — Straight-Punch Side-Ownership Redesign

**Date:** 2026-05-19  
**Status:** Stale  
**Agent:** Pico 🐱‍🏍

---

## Goal

Redesign the Boxing straight-punch side-ownership / side-lock model so guarded forward left punches can be recognized truthfully without unlocking the false-positive spam seen in the narrow own-half relaxation experiment.

---

## Overview

The resumed straight-punch coder pass closed the current narrow slice with a truthful stop sign. The preserved WIP coupled model still produced `0/4` authored-window hits on the guarded-left fixture because `boxing_debug.left_straight.own_half_lock` never went true during the real punches. The smallest relaxation we tried recovered only `1/4`, and it did so by creating `6` false positives plus fake rearm spam. That is useful evidence: the core problem is no longer “forward depth truth exists or not,” but that the current side-ownership gate is structurally wrong for these front-facing forward punches.

So the next slice should stop pretending that a tiny threshold change will solve this. We need a Boxing-only redesign focused on *how a forward straight remains attributable to the left hand* when the wrist crosses or compresses in image-plane geometry during depth motion. The likely answer is some combination of hand-to-shoulder ownership, elbow-chain ownership, guard-baseline ownership, and temporal continuity — but the exact model should be chosen from the preserved fixture evidence rather than from intuition.

This plan should stay narrow and truthful. We are not redesigning all Boxing gestures or all body-state logic. We are isolating the side-ownership failure in the guarded-left straight-punch path, proposing a better ownership model, implementing the smallest viable version, and then re-running the same guarded-left fixture with explicit QA and audit gates.

---

## REFERENCES

| ID | Description | Path |
| --- | --- | --- |
| `REF-01` | Active interrupted straight-punch plan + preserved WIP evidence | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-mediapipe-python/.plans/2026-05-18-straight-punch-depth-aware-measurement-and-state-design.md` |
| `REF-02` | Living HTML experiment log | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-mediapipe-python/docs/punch-left-golden-truth-experiment-log.html` |
| `REF-03` | Detector substrate | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-mediapipe-python/src/detectors/pose_detector_substrate.gd` |
| `REF-04` | Pose metrics helpers | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-mediapipe-python/src/detectors/pose_metrics.gd` |
| `REF-05` | Proving harness / boxing debug surface | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-mediapipe-python/.testbed/scripts/proving_harness.gd` |
| `REF-06` | Guarded-left fixture YAML | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-mediapipe-python/.testbed/assets/fixtures/boxing/punch_left/boxing_punch_left_x4_while_guarding_take_01.yaml` |
| `REF-07` | Guarded-left fixture video | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-mediapipe-python/.testbed/assets/fixtures/boxing/punch_left/boxing_punch_left_x4_while_guarding_take_01.mp4` |
| `REF-08` | Preserved WIP rerun: `0/4`, no spam | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-mediapipe-python/.testbed/test-results/runner-boxing/20260519-201255__boxing_punch_left_x4_while_guarding_take_01/` |
| `REF-09` | Own-half relaxation rerun: `1/4`, `6` false positives | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-mediapipe-python/.testbed/test-results/runner-boxing/20260519-201931__boxing_punch_left_x4_while_guarding_take_01/` |
| `REF-10` | Truncated resumed rerun evidence | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-mediapipe-python/.testbed/test-results/runner-boxing/20260519-201201__boxing_punch_left_x4_while_guarding_take_01/` |

---

## Tasks

### Task 1: Diagnose why current side-lock truth fails on real guarded left punches

**Bead ID:** `Pending`  
**SubAgent:** `primary`  
**Role:** `research`  
**References:** `REF-01`–`REF-10`  
**Prompt:** Analyze the preserved reruns and debug metrics specifically to explain why `own_half_lock` stays false on the authored left punches and why the narrow relaxation causes spam. Compare candidate ownership models grounded in actual landmark behavior: hand-vs-own-shoulder horizontal relation, elbow-chain ownership, shoulder-relative baseline capture, signed lateral offset over time, temporal continuity from guard, and any mirrored right-side checks that help falsify bad models. Update the plan and HTML log with the exact failure mode, rejected ownership shortcuts, and the smallest recommended redesign.

**Folders Created/Deleted/Modified:**
- `.plans/`
- `docs/`
- maybe fresh analysis notes under `.testbed/test-results/` only if needed

**Files Created/Deleted/Modified:**
- `.plans/2026-05-19-straight-punch-side-ownership-redesign.md`
- `docs/punch-left-golden-truth-experiment-log.html`

**Status:** ⏳ Pending

**Results:** Pending.

---

### Task 2: Implement the smallest side-ownership redesign that still respects the depth-aware straight-punch state model

**Bead ID:** `Pending`  
**SubAgent:** `primary`  
**Role:** `coder`  
**References:** `REF-03`–`REF-10` plus Task 1 conclusions  
**Prompt:** Implement only the smallest Boxing-only redesign needed to replace the failing own-half gate with a more truthful side-ownership model for front-facing forward straights. Keep the existing depth-aware extension/rearm state where it remains valid. Update the shared log before and after each real attempt, rerun the guarded-left fixture, preserve evidence, and stop immediately if the redesign recovers hits by creating spam or fake rearm behavior.

**Folders Created/Deleted/Modified:**
- `src/detectors/`
- `.testbed/scripts/`
- `.testbed/test-results/runner-boxing/`
- `.plans/`
- `docs/`

**Files Created/Deleted/Modified:**
- exact detector / harness / test files required by the redesign
- `.plans/2026-05-19-straight-punch-side-ownership-redesign.md`
- `docs/punch-left-golden-truth-experiment-log.html`

**Status:** ⏳ Pending

**Results:** Pending.

---

### Task 3: QA the redesigned side-ownership model against the guarded-left fixture

**Bead ID:** `Pending`  
**SubAgent:** `primary`  
**Role:** `qa`  
**References:** `REF-06`–`REF-10` plus fresh Task 2 artifacts  
**Prompt:** Independently verify whether the redesigned side-ownership model truthfully improves guarded-left straight-punch detection. Be explicit about authored-window hit counts, false positives, rearm behavior, and whether any recovered hits come from actual ownership truth versus widened ambiguity.

**Folders Created/Deleted/Modified:**
- `.plans/`
- maybe `docs/` if a QA note belongs in the shared log

**Files Created/Deleted/Modified:**
- `.plans/2026-05-19-straight-punch-side-ownership-redesign.md`
- `docs/punch-left-golden-truth-experiment-log.html` if needed

**Status:** ⏳ Pending

**Results:** Pending.

---

### Task 4: Audit whether the redesigned straight-punch model is truthful enough to keep

**Bead ID:** `Pending`  
**SubAgent:** `primary`  
**Role:** `auditor`  
**References:** all relevant source, plan, log, and fresh artifacts from Tasks 1-3  
**Prompt:** Audit the redesigned side-ownership slice. Decide whether the change truthfully improves guarded-left straight-punch detection without masking ambiguity or creating new spam/rearm lies. If not, say exactly what deeper redesign remains.

**Folders Created/Deleted/Modified:**
- `.plans/`
- maybe `docs/` if a final audit note belongs in the shared log

**Files Created/Deleted/Modified:**
- `.plans/2026-05-19-straight-punch-side-ownership-redesign.md`
- `docs/punch-left-golden-truth-experiment-log.html` if needed

**Status:** ⏳ Pending

**Results:** Pending.

---

## Final Results

**Status:** ⚠️ Draft / not yet executed

**What We Built:**
- A follow-on plan focused on the newly exposed real blocker: straight-punch side ownership truth, not just depth extension or rearm state.

**Reference Check:**
- `REF-08` proves the preserved WIP is too strict (`0/4`).
- `REF-09` proves the narrow own-half relaxation is too loose (`1/4` with `6` false positives).
- Together they justify a deeper side-ownership redesign rather than more threshold nudging.

**Commits:**
- None yet.

**Lessons Learned:**
- The next truthful question is “how does the detector know this is still the left hand’s straight?” not “is the arm forward enough?”
- A useful redesign must recover authored hits without paying for them with fake ownership drift and spam.

---

*Created on 2026-05-19*