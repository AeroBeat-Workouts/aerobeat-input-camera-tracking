# AeroBeat Boxing Depth and Classifier Paths Research

**Date:** 2026-06-16
**Status:** In Progress
**Last Updated:** 2026-06-16 13:32 EDT
**Blocked Reason:** None.
**Agent:** `pico`

---

## Goal

Research the best next-path options for straight-punch detection after prototype matching failed, with special focus on monocular depth approaches for wrist-forward depth estimation and how they compare to classifier-training and pose-threshold-only paths.

---

## Overview

The latest audited prototype-matcher branch improved straight-punch results slightly but still failed strategically because run-in-place remained a strong false-positive source and left/right separation stayed too noisy. Derrick has now narrowed the decision space to three practical branches: continue with pose-only threshold tuning and accept its limitations, train a supervised classifier from recorded boxing videos plus exported pose/truth labels, or add a lightweight monocular depth estimator aimed specifically at recovering usable forward wrist-depth motion for straight punches.

This plan should produce a decision-quality comparison rather than vague brainstorming. The research needs to compare FastDepth / HoloFastDepth against other monocular depth candidates in the context that actually matters here: low-end-device viability, rapid-motion robustness, integration complexity, expected latency, whether depth can be localized strongly enough around the wrist/hand region, and whether the result would likely outperform the current pose-only threshold system enough to justify the engineering cost.

Derrick clarified an important product constraint before execution: co-firing can still be acceptable if the game is designed around it, but depth would be especially valuable if it enables athletes to throw rapid same-side straight punches in succession more reliably. Current pose-threshold straight detection mostly works at a rough ~75% level, but its visible weakness is rapid same-side straights. By contrast, current hook and uppercut failures are not expected to be solved by depth alone; those gestures likely need a re-examination or replacement of their current threshold logic. The research should therefore explicitly separate:
- whether monocular depth is a worthwhile straight-punch booster,
- whether classifier training is a better all-around replacement path,
- and whether hook/uppercut quality likely demands a different detector redesign regardless of straight-punch depth improvements.

The output should explicitly separate “good research-paper depth” from “good-enough real-time wrist-depth signal for AeroBeat.” It should also compare that monocular-depth path against the classifier path and the threshold-only path in terms of implementation risk, data requirements, runtime cost, and likelihood of yielding a materially better straight-punch detector.

---

## REFERENCES

| ID | Description | Path |
| --- | --- | --- |
| `REF-01` | Threshold-inspired straight prototype plan/result | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.plans/2026-06-16-prototype-matcher-threshold-inspired-straight-features.md` |
| `REF-02` | Medium article Derrick cited | `https://medium.com/xrpractices/monocular-depth-sensing-point-cloud-from-webcam-feed-using-unity-barracuda-d9f1496b5932` |
| `REF-03` | HoloFastDepth repo Derrick cited | `https://github.com/miso3/HoloFastDepth` |
| `REF-04` | Current straight-punch threshold concepts | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/assets/boxing.gesture_detection.yaml` |
| `REF-05` | Current pose substrate / available measurements | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/src/detectors/pose_detector_substrate.gd` |
| `REF-06` | Durable prior finding: pose-only wrist depth is weak, elbow motion helped more | `memory/2026-06-06.md#L19-L28` |
| `REF-07` | Durable prior gameplay tolerance: co-firing/noise can be acceptable if beat hits are reliable | `memory/2026-06-08.md#L6-L9` |

---

## Tasks

### Task 1: Research the three decision paths and produce a comparison brief

**Bead ID:** `aerobeat-input-camera-tracking-fslt`
**SubAgent:** `primary` (for `research`)
**Role:** `research`
**References:** `REF-01`, `REF-02`, `REF-03`, `REF-04`, `REF-05`, `REF-06`, `REF-07`
**Prompt:** Compare the three next-path options for AeroBeat straight-punch detection: (1) stay pose-threshold-only and keep tuning, (2) train a supervised classifier from recorded boxing videos + exported pose + truth YAMLs, and (3) add a lightweight monocular depth estimator primarily to recover wrist forward-depth motion for straight punches. Research FastDepth / HoloFastDepth versus other realistic monocular depth options, especially for low-end-device real-time use. Focus on runtime cost, integration complexity, motion robustness, wrist-local depth usefulness, expected false-positive/false-negative impact, and likely engineering ROI. Produce a decision brief with a ranked recommendation and explicit tradeoffs.

**Folders Created/Deleted/Modified:**
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.plans/`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/docs/`

**Files Created/Deleted/Modified:**
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/docs/reviews/boxing-depth-vs-classifier-decision-brief-2026-06-16.md`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.plans/2026-06-16-boxing-depth-and-classifier-paths-research.md`

**Status:** ✅ Complete

**Results:** Wrote the decision brief at `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/docs/reviews/boxing-depth-vs-classifier-decision-brief-2026-06-16.md` after grounding it in the current threshold detector config/runtime (`REF-04`/`REF-05`), the recent straight-only prototype dead-end (`REF-01`), the repo's existing boxing fixtures and truth-window YAMLs, and the cited monocular-depth references (`REF-02`/`REF-03`) plus realistic comparison points (FastDepth, MiDaS mobile/small variants, Depth Anything V2 Small). The brief makes a concrete ranked recommendation: **(1) pursue a small supervised pose-sequence classifier next, (2) keep threshold-only tuning as the short-term maintenance baseline, (3) treat monocular depth as later optional R&D rather than the next mainline branch.**

The main decision logic captured in the brief is: monocular depth is technically plausible on low-end hardware, especially with FastDepth-class models, but its likely AeroBeat value is only as a noisy auxiliary straight-punch feature and not a strong primary answer for rapid same-side straights, side ownership, or hook/uppercut quality. By contrast, a pose-sequence classifier better matches the repo's current assets — recorded boxing fixtures, YAML truth windows, and rich per-frame capture reports — while also offering a believable path to improve straights, hooks, and uppercuts under one reusable modeling approach.

---

### Task 2: QA the research brief for factual support and decision usefulness

**Bead ID:** `aerobeat-input-camera-tracking-uhl9`
**SubAgent:** `primary` (for `qa`)
**Role:** `qa`
**References:** `REF-01`, `REF-02`, `REF-03`, `REF-04`, `REF-05`, `REF-06`, `REF-07`
**Prompt:** Verify that the research brief accurately represents the current AeroBeat detector state, faithfully summarizes the cited monocular depth options and alternatives, and gives Derrick a useful decision-quality comparison rather than generic pros/cons. Check that major claims are supported and that the recommendation matches the evidence.

**Folders Created/Deleted/Modified:**
- relevant owning repo paths

**Files Created/Deleted/Modified:**
- QA notes/artifacts as needed

**Status:** ⏳ Pending

**Results:** Pending.

---

### Task 3: Audit the recommendation and decide whether to execute the chosen branch next

**Bead ID:** `aerobeat-input-camera-tracking-illg`
**SubAgent:** `primary` (for `auditor`)
**Role:** `auditor`
**References:** `REF-01`, `REF-02`, `REF-03`, `REF-04`, `REF-05`, `REF-06`, `REF-07`
**Prompt:** Independently audit the research brief and recommendation. Confirm whether the evidence supports the proposed next path for AeroBeat straight-punch detection, and call out any hidden costs, missing assumptions, or overconfidence. If the brief is strong enough, recommend whether Derrick should execute the selected branch next.

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
