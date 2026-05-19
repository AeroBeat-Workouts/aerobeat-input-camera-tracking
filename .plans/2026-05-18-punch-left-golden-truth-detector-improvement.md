# AeroBeat MediaPipe Python — Punch-Left Golden Truth Detector Improvement

**Date:** 2026-05-18  
**Status:** In Progress  
**Agent:** Pico 🐱‍🏍

---

## Goal

Improve Boxing gesture detection for the punch-left golden-truth fixture, starting with the trimmed guarded-left clip, so the validator moves materially closer to truthful `punch_left` detection without hiding remaining false positives.

---

## Overview

We already have the fixture system in a usable state, the timing basis has been rebased to provider readiness, and the trimmed `boxing_punch_left_x4_while_guarding_take_01` fixture is now a trustworthy golden-truth input. The current failure is no longer fixture-contract drift; it is detector/runtime truth. Prior work showed the clip still emits zero `punch_left` events while surfacing false positives like `uppercut_right` and `squat_start`, and the saved provider-anchored evidence points at a brittle straight-punch gate stack rather than a rearm bug.

This slice should stay narrow. The target is the Boxing detector path in `pose_detector_substrate.gd`, specifically the smallest truthful change that improves `punch_left` accuracy on the guarded-left fixture. We should avoid broad detector redesign unless the narrow path clearly fails. QA and audit must judge the result against the existing fixture artifacts and a fresh rerun of the same trimmed clip, so we can distinguish “better punch-left truth” from merely shifting mistakes into sibling gesture families.

Per Derrick’s recommendation, this work should also maintain a living HTML experiment log in the repo so each attempted idea, assumption check, code change, and rerun outcome is visible at a glance. Before the coder changes thresholds or motion logic, the first pass should explicitly audit base-level assumptions: whether the left-punch path is even reachable under current booleans/state gates, whether any readiness or guard/state interactions are silently suppressing it, and whether the underlying geometry/math feeding left-punch detection is obviously inconsistent with the intended gesture.

---

## REFERENCES

| ID | Description | Path |
| --- | --- | --- |
| `REF-01` | Active long-running Boxing fixture-system plan | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-mediapipe-python/.plans/2026-05-13-boxing-fixture-system-truth-and-schema.md` |
| `REF-02` | Detector substrate | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-mediapipe-python/src/detectors/pose_detector_substrate.gd` |
| `REF-03` | Pose metrics helpers | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-mediapipe-python/src/detectors/pose_metrics.gd` |
| `REF-04` | Trimmed punch-left golden-truth fixture YAML | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-mediapipe-python/.testbed/assets/fixtures/boxing/punch_left/boxing_punch_left_x4_while_guarding_take_01.yaml` |
| `REF-05` | Trimmed punch-left fixture video | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-mediapipe-python/.testbed/assets/fixtures/boxing/punch_left/boxing_punch_left_x4_while_guarding_take_01.mp4` |
| `REF-06` | Provider-anchored fixture artifacts for the trimmed clip | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-mediapipe-python/.testbed/test-results/fixtures/20260514-214817__boxing_punch_left_x4_while_guarding_take_01/` |
| `REF-07` | Punch-left detector accuracy audit | `/home/derrick/.openclaw/workspace/memory/2026-05-14.md` |
| `REF-08` | Today's wrap-up / latest repo context | `/home/derrick/.openclaw/workspace/memory/2026-05-18.md` |

---

## Tasks

### Task 1: Build the living experiment log and audit base-level left-punch assumptions

**Bead ID:** `aerobeat-input-mediapipe-python-edk`  
**SubAgent:** `primary`  
**Role:** `research`  
**References:** `REF-01`, `REF-02`, `REF-03`, `REF-04`, `REF-06`, `REF-07`  
**Prompt:** Create and maintain a living HTML experiment log for this punch-left golden-truth task inside the repo. Then re-read the current punch-left fixture evidence and source, starting with base-level assumption checks before proposing fixes: verify the left-punch path is actually reachable under current booleans, readiness flags, guard/state gates, cooldown/rearm logic, and event wiring; inspect whether the underlying geometry/math for left straight punches is obviously inconsistent with the intended guarded-left motion; and record each checked assumption plus whether it passed or failed in the HTML log. End by producing a narrow implementation recommendation for the smallest truthful `punch_left` accuracy improvement slice, including exact gates/thresholds/shape checks to change, what must stay out of scope, and what fresh validation evidence should prove the change helped.

**Folders Created/Deleted/Modified:**
- `.plans/`
- `docs/` or another repo-owned path chosen for the living experiment log

**Files Created/Deleted/Modified:**
- `.plans/2026-05-18-punch-left-golden-truth-detector-improvement.md`
- `docs/punch-left-golden-truth-experiment-log.html`

**Status:** ✅ Complete

**Results:**
- Built the living HTML experiment log at `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-mediapipe-python/docs/punch-left-golden-truth-experiment-log.html`.
- Re-audited the current source and the latest available proving artifact for `boxing_punch_left_x4_while_guarding_take_01`. The plan’s older `REF-06` path was not present in this checkout, so the audit used the current available equivalent artifact folder at `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-mediapipe-python/.testbed/test-results/runner-boxing/20260518-183350__boxing_punch_left_x4_while_guarding_take_01/` and recorded that discrepancy in the HTML log.
- Confirmed the left straight-punch path is reachable in `src/detectors/pose_detector_substrate.gd`, `ready.punch_left` is not obviously stuck false, and provider event wiring/forwarding for `punch_left` is intact.
- Confirmed guard only suppresses hook/uppercut evaluation, not straight punches, so guard-state gating is not the direct reason `punch_left` never fires.
- Strongest evidence points lower in the measurement/geometry stack: the same artifact that misses all four `punch_left` windows also shows a false `squat_start`, short/missing guard windows, and implausible latest posture metrics (`height_ratio` ~ `0.256`, `squat_depth` ~ `0.744`) for a mostly upright guarded-punch clip.
- Ranked recommendation for the coder:
  1. Add temporary per-frame capture/debug for the exact straight-punch inputs (`left_arm_extension`, `left_elbow_bend_deg`, `outward_velocity`, `outward_distance`, and guard-state inputs) on this fixture before changing thresholds.
  2. If those inputs are not believable, fix the smallest underlying landmark/measurement truth issue first instead of loosening punch thresholds blindly.
  3. Only if the inputs are already plausible-but-tight, tune the smallest straight-punch gate in `src/detectors/pose_detector_substrate.gd:640-663`; keep Flow and sibling-family redesign out of scope unless new evidence forces it.

---

### Task 2: Implement the smallest truthful punch-left detector improvement slice

**Bead ID:** `aerobeat-input-mediapipe-python-44x`  
**SubAgent:** `primary`  
**Role:** `coder`  
**References:** `REF-02`, `REF-03`, `REF-04`, `REF-05`, `REF-06`  
**Prompt:** Implement only the smallest truthful `punch_left` detector improvement justified by Task 1. Update the living HTML experiment log before and after each attempted idea so Derrick can visually inspect what was tried, what changed, and whether each attempt moved the fixture outcome in the right direction. Re-run the trimmed punch-left fixture, preserve evidence, and keep scope tight: do not broaden into unrelated Boxing families unless a tiny inseparable sibling-disambiguation adjustment is required.

**Folders Created/Deleted/Modified:**
- `.plans/`
- `.testbed/scripts/`
- `docs/`
- `.testbed/test-results/runner-boxing/`

**Files Created/Deleted/Modified:**
- `.testbed/scripts/proving_harness.gd`
- `docs/punch-left-golden-truth-experiment-log.html`
- `.plans/2026-05-18-punch-left-golden-truth-detector-improvement.md`

**Status:** ✅ Complete

**Results:**
- Added the smallest useful per-frame debug surface to fixture capture only: `.testbed/scripts/proving_harness.gd` now records a `boxing_debug` snapshot into each `state_timeline` entry with the exact requested left straight-punch inputs (`left_arm_extension`, `left_elbow_bend_deg`, outward velocity, outward distance), directly relevant guard-state inputs, plus temporary 3D comparison values (`arm_extension_3d`, `elbow_bend_deg_3d`, forward velocity, forward distance) so the geometry-truth hypothesis could be tested without permanently broadening detector logic.
- Preserved fresh evidence artifacts from the instrumentation pass and the reverted final pass:
  - `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-mediapipe-python/.testbed/test-results/runner-boxing/20260518-214702__boxing_punch_left_x4_while_guarding_take_01/20260518-214702__boxing_punch_left_x4_while_guarding_take_01/`
  - `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-mediapipe-python/.testbed/test-results/runner-boxing/20260518-215350__boxing_punch_left_x4_while_guarding_take_01/20260518-215350__boxing_punch_left_x4_while_guarding_take_01/`
- The preserved final evidence shows the core truth gap clearly on the authored punch windows:
  - window 1 peak around `timestamp_ms 1287`: `2D extension 0.237`, `2D elbow 0.0`, but `3D extension 0.987`, `3D elbow 161.5`, `forward_velocity 8.04`, `forward_distance 0.364`
  - window 2 peak around `timestamp_ms 2631`: `2D extension 0.105`, `2D elbow 0.0`, but `3D extension 0.972`, `3D elbow 152.7`, `forward_velocity 18.36`, `forward_distance 0.370`
  - window 3 peak around `timestamp_ms 3467`: `2D extension 0.429`, `2D elbow 0.0`, but `3D extension 0.981`, `3D elbow 157.8`, `forward_velocity 13.89`, `forward_distance 0.362`
  - window 4 remained directionally ambiguous in this pass (`forward_velocity -0.12`) but still showed the same 2D-vs-3D collapse (`2D extension 0.326` vs `3D extension 0.974`; `2D elbow 8.9` vs `3D elbow 153.8`).
- This proves the current detector’s 2D straight-punch inputs are not merely "tight"; they are structurally misleading for this front-facing forward-punch clip.
- I ran two narrow real detector experiments after the instrumentation pass (one 3D straight-punch gate swap and one hybrid 2D-rearm/3D-fire attempt). Both regressed badly by producing many false `punch_left`/`punch_right` events and/or breaking truthful rearm behavior. Both experiments were fully reverted.
- Final truthful outcome for this coder slice: keep the instrumentation and preserved evidence, revert the regressing detector logic, and stop. Threshold-only tuning from the current 2D inputs would be dishonest; a real fix now wants a deeper forward-punch measurement/retraction/side-disambiguation design pass.

---

### Task 3: QA the trimmed punch-left golden-truth fixture after the detector change

**Bead ID:** `aerobeat-input-mediapipe-python-77n`  
**SubAgent:** `primary`  
**Role:** `qa`  
**References:** `REF-04`, `REF-05`, `REF-06` plus fresh artifacts from Task 2  
**Prompt:** Independently verify whether the new detector behavior improved `punch_left` truth on the trimmed guarded-left fixture. Be explicit about event counts, window hits/misses, remaining false positives, and whether the slice improved truth versus merely moving errors around.

**Folders Created/Deleted/Modified:**
- `.plans/`

**Files Created/Deleted/Modified:**
- `.plans/2026-05-18-punch-left-golden-truth-detector-improvement.md`

**Status:** ⏳ Pending

**Results:** Pending.

---

### Task 4: Audit whether the punch-left slice is truthful enough to keep or needs another retry

**Bead ID:** `aerobeat-input-mediapipe-python-470`  
**SubAgent:** `primary`  
**Role:** `auditor`  
**References:** all relevant source, plan, and fresh artifact references from Tasks 1-3  
**Prompt:** Independently audit the punch-left detector slice. Decide whether the change truthfully improves the guarded-left golden-truth fixture without masking remaining issues, and state whether the next step should be keep/iterate/escalate.

**Folders Created/Deleted/Modified:**
- `.plans/`

**Files Created/Deleted/Modified:**
- `.plans/2026-05-18-punch-left-golden-truth-detector-improvement.md`

**Status:** ⏳ Pending

**Results:** Pending.

---

## Final Results

**Status:** ⚠️ Partial / truthful stop sign

**What We Built:**
- A focused execution plan plus a repo-owned living experiment log for the punch-left golden-truth investigation at `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-mediapipe-python/docs/punch-left-golden-truth-experiment-log.html`.
- A completed coder evidence pass that adds per-frame straight-punch/guard instrumentation to fixture capture and preserves fresh proving artifacts Derrick can inspect directly.
- A documented conclusion that the current `punch_left` miss is driven by measurement/geometry truth failure on front-facing forward punches, not by missing provider wiring or a simple threshold-tight gate.

**Reference Check:**
- `REF-01` remains the broader fixture/timing foundation.
- `REF-02` and `REF-03` were rechecked during the failed real-logic experiments, which were then reverted.
- `REF-04` and `REF-05` remained the sole truth input during all reruns.
- The plan’s original `REF-06` artifact path is stale in this checkout; the preserved fresh evidence for this coder slice is now under:
  - `.testbed/test-results/runner-boxing/20260518-214702__boxing_punch_left_x4_while_guarding_take_01/20260518-214702__boxing_punch_left_x4_while_guarding_take_01/`
  - `.testbed/test-results/runner-boxing/20260518-215350__boxing_punch_left_x4_while_guarding_take_01/20260518-215350__boxing_punch_left_x4_while_guarding_take_01/`

**Commits:**
- `5f6d9b0` - `Add punch-left fixture instrumentation evidence`

**Lessons Learned:**
- The hard part now is detector truth, not fixture plumbing.
- On this clip, 2D straight-punch inputs are not merely conservative; they are misleading because the punch projects strongly in depth.
- A quick 3D gate swap is not enough: retraction truth and side disambiguation are coupled, and naive fixes quickly create false positive spam.

---

*Created on 2026-05-18*
