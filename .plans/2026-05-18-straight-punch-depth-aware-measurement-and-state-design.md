# AeroBeat MediaPipe Python — Straight-Punch Depth-Aware Measurement and State Design

**Date:** 2026-05-18  
**Status:** Draft  
**Agent:** Pico 🐱‍🏍

---

## Goal

Design and implement the next truthful Boxing straight-punch detector slice so the guarded-left golden-truth fixture can recognize real forward punches without introducing spam, by treating depth-aware extension, truthful retraction/rearm, and left/right side disambiguation as one coupled problem.

---

## Overview

The previous punch-left investigation completed a full coder → QA → audit loop and reached a stable conclusion: the current failure is not mainly a missing forwarder, a stuck ready flag, or a simple threshold problem. The preserved instrumentation now shows that the fixture’s front-facing forward punches collapse under the current 2D straight-punch measurements even while temporary 3D comparison values show near-full extension and strong forward motion during the authored punch windows.

That means the next slice should not be another threshold nudge. Two narrow detector experiments already proved that a naive “switch straight punches to 3D” patch causes false positive spam and breaks truthful retraction behavior. So this next plan needs to treat three things together: how straight-punch extension is measured, how a punch returns to a ready/rearmed state, and how the detector distinguishes left/right straight punches from one another during forward motion.

This plan should stay Boxing-only and fixture-driven. The trimmed guarded-left golden-truth fixture remains the first proving target, and all decisions should be recorded both in the plan and in the living HTML experiment log. The outcome we want is not just “some `punch_left` events appear”; it is a truthful step forward that improves authored-window hits without masking new false positives or fake rearm behavior.

---

## REFERENCES

| ID | Description | Path |
| --- | --- | --- |
| `REF-01` | Previous punch-left instrumentation / stop-sign plan | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-mediapipe-python/.plans/2026-05-18-punch-left-golden-truth-detector-improvement.md` |
| `REF-02` | Living HTML experiment log | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-mediapipe-python/docs/punch-left-golden-truth-experiment-log.html` |
| `REF-03` | Detector substrate | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-mediapipe-python/src/detectors/pose_detector_substrate.gd` |
| `REF-04` | Pose metrics helpers | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-mediapipe-python/src/detectors/pose_metrics.gd` |
| `REF-05` | Proving harness with kept `boxing_debug` instrumentation | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-mediapipe-python/.testbed/scripts/proving_harness.gd` |
| `REF-06` | Guarded-left fixture YAML | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-mediapipe-python/.testbed/assets/fixtures/boxing/punch_left/boxing_punch_left_x4_while_guarding_take_01.yaml` |
| `REF-07` | Guarded-left fixture video | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-mediapipe-python/.testbed/assets/fixtures/boxing/punch_left/boxing_punch_left_x4_while_guarding_take_01.mp4` |
| `REF-08` | Strong instrumentation artifact pass | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-mediapipe-python/.testbed/test-results/runner-boxing/20260518-214702__boxing_punch_left_x4_while_guarding_take_01/20260518-214702__boxing_punch_left_x4_while_guarding_take_01/` |
| `REF-09` | Final kept rerun with instrumentation | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-mediapipe-python/.testbed/test-results/runner-boxing/20260518-215350__boxing_punch_left_x4_while_guarding_take_01/20260518-215350__boxing_punch_left_x4_while_guarding_take_01/` |

---

## Tasks

### Task 1: Design a truthful straight-punch state model from the preserved 2D/3D fixture evidence

**Bead ID:** `Pending`  
**SubAgent:** `primary`  
**Role:** `research`  
**References:** `REF-01`, `REF-02`, `REF-03`, `REF-04`, `REF-08`, `REF-09`  
**Prompt:** Starting from the kept instrumentation evidence, design a Boxing-only straight-punch model that treats extension, retraction/rearm, and left/right side disambiguation together. Be explicit about which existing measurements are still trustworthy, which are misleading on front-facing forward punches, and what the smallest plausible new detector state or metric surface should be before coding begins. Update both this plan and the HTML log with the design options, rejected shortcuts, and the narrow recommended coding slice.

**Folders Created/Deleted/Modified:**
- `.plans/`
- `docs/`

**Files Created/Deleted/Modified:**
- `.plans/2026-05-18-straight-punch-depth-aware-measurement-and-state-design.md`
- `docs/punch-left-golden-truth-experiment-log.html`

**Status:** ⏳ Pending

**Results:** Pending.

---

### Task 2: Implement the smallest depth-aware straight-punch measurement/state slice

**Bead ID:** `Pending`  
**SubAgent:** `primary`  
**Role:** `coder`  
**References:** `REF-03`, `REF-04`, `REF-05`, `REF-06`, `REF-07`, `REF-08`, `REF-09`  
**Prompt:** Implement only the smallest truthful detector slice justified by Task 1. Keep scope Boxing-only and fixture-driven. Use the kept `boxing_debug` surface to verify the new model. Update the HTML log before and after each real attempt, rerun the guarded-left fixture, preserve evidence, and stop immediately if the change creates spam or fake rearm behavior.

**Folders Created/Deleted/Modified:**
- `.plans/`
- `src/detectors/`
- `.testbed/scripts/`
- `.testbed/test-results/runner-boxing/`
- `docs/`

**Files Created/Deleted/Modified:**
- exact detector / harness / doc files required by the slice
- `.plans/2026-05-18-straight-punch-depth-aware-measurement-and-state-design.md`
- `docs/punch-left-golden-truth-experiment-log.html`

**Status:** ⏳ Pending

**Results:** Pending.

---

### Task 3: QA the new straight-punch model against the guarded-left golden-truth fixture

**Bead ID:** `Pending`  
**SubAgent:** `primary`  
**Role:** `qa`  
**References:** `REF-06`, `REF-07`, `REF-08`, `REF-09` plus fresh artifacts from Task 2  
**Prompt:** Independently verify whether the new straight-punch model truthfully improves the guarded-left fixture. Be explicit about authored-window hit counts, false positives, rearm behavior, and whether any apparent gain came from noise rather than better detection.

**Folders Created/Deleted/Modified:**
- `.plans/`

**Files Created/Deleted/Modified:**
- `.plans/2026-05-18-straight-punch-depth-aware-measurement-and-state-design.md`
- `docs/punch-left-golden-truth-experiment-log.html` if a QA note belongs in the shared log

**Status:** ⏳ Pending

**Results:** Pending.

---

### Task 4: Audit whether the new straight-punch model is truthful enough to keep

**Bead ID:** `Pending`  
**SubAgent:** `primary`  
**Role:** `auditor`  
**References:** all relevant source, plan, log, and fresh artifact references from Tasks 1-3  
**Prompt:** Independently audit the new straight-punch model. Decide whether the kept change truthfully improves Boxing straight-punch detection on the guarded-left fixture without masking new problems, and state whether the result should be kept, retried, or escalated again.

**Folders Created/Deleted/Modified:**
- `.plans/`

**Files Created/Deleted/Modified:**
- `.plans/2026-05-18-straight-punch-depth-aware-measurement-and-state-design.md`
- `docs/punch-left-golden-truth-experiment-log.html` if a final audit note belongs in the shared log

**Status:** ⏳ Pending

**Results:** Pending.

---

## Final Results

**Status:** ⚠️ Draft / not yet executed

**What We Built:**
- A next-phase plan for a deeper straight-punch detector design pass grounded in the preserved punch-left instrumentation evidence.

**Reference Check:**
- `REF-01` and `REF-02` capture the completed stop-sign investigation.
- `REF-08` and `REF-09` are the key preserved evidence inputs for the next slice.

**Commits:**
- None yet.

**Lessons Learned:**
- The next truthful fix has to treat depth-aware punch extension, retraction, and side disambiguation as one problem.
- The existing HTML log is now part of the working source of truth and should be carried forward rather than restarted.

---

*Created on 2026-05-18*
