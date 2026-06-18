# AeroBeat Learned Classifier Left/Right Punch Separation Tuning

**Date:** 2026-06-17  
**Status:** In Progress  
**Last Updated:** 2026-06-17 21:51 EDT  
**Blocked Reason:** None  
**Agent:** `pico`

---

## Goal

Diagnose and improve learned-classifier class separation for boxing punches, with immediate focus on left-side straight/hook/uppercut confusion and the newly reported straight-right no-fire behavior.

---

## Overview

We closed the previous learned-classifier proving branch after fixing four layers of product/runtime truth: backend selection visibility, model-path loading in `.testbed`, replay-restart temporal reset leakage, and inspector/debug parity. At this point the learned backend is genuinely running, model loading is stable, proving inspectors are materially truthful, and straight-left fixture proving now emits punches in repo-side QA/audit.

Derrick’s latest human testing shows the next branch is now squarely about model behavior rather than plumbing. On the left side, learned-classifier punches do fire, but left straight can still misclassify as left uppercut and hook-left behavior is not yet cleanly separated. On the right side, Derrick reports a fresh seam: the straight-right replay produced no learned punch emissions, and the inspector stayed at `no_punch` / `0.000` with `window_not_full` in the screenshot. That means the tuning branch should not assume perfect right-side parity with the left; instead it should inspect class distribution, feature windows, frame counts/timing, fixture parity, and any side-specific data or label imbalance.

This branch should stay evidence-driven and fixture-based. We already know the UI is telling the truth much better now, so the next job is to determine whether the right-side no-fire is caused by fixture/runtime timing, window-filling behavior, feature extraction asymmetry, or genuine model weakness. Then we can implement the narrowest truthful tuning or data/contract fix while preserving the good noise resistance Derrick observed compared with the threshold system.

---

## REFERENCES

| ID | Description | Path |
| --- | --- | --- |
| `REF-01` | Completed learned-classifier proving branch plan/results | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.plans/2026-06-17-learned-classifier-enabled-but-still-no-punches.md` |
| `REF-02` | Current boxing learned-classifier config | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/assets/boxing.gesture_detection.yaml` |
| `REF-03` | Learned classifier runtime | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/src/detectors/learned_punch_classifier.gd` |
| `REF-04` | Backend routing / gesture debug substrate | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/src/detectors/pose_detector_substrate.gd` |
| `REF-05` | Boxing proving harness UI/debug routing | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.testbed/scripts/boxing_proving_harness.gd` |
| `REF-06` | Learned classifier baseline artifact | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/docs/baselines/boxing-punch-classifier-frozen-benchmark-mlp-vs-cnn-2026-06-16/mlp/mlp-result.json` |
| `REF-07` | Derrick screenshot of straight-right learned no-fire state | `/home/derrick/.openclaw/workspace/.temp/nerve-uploads/2026/06/18/image-8604b541.png` |

---

## Tasks

### Task 1: Diagnose learned-classifier left/right punch separation failures

**Bead ID:** `aerobeat-input-camera-tracking-kek8`  
**SubAgent:** `primary` (for `research`)  
**Role:** `research`  
**References:** `REF-01`, `REF-02`, `REF-03`, `REF-04`, `REF-05`, `REF-06`, `REF-07`  
**Prompt:** Diagnose the remaining learned-classifier behavior issues after the proving/runtime fixes. Focus on two seams: (a) left-side confusion between straight/hook/uppercut classes, and (b) straight-right replay producing no punch emissions while inspector truth shows `no_punch` / `0.000` / `window_not_full`. Determine whether the right-side no-fire is a fixture/window/timing issue, a feature asymmetry, a class/data imbalance, or a model separability problem. Include exact file/function/config/fixture references and the minimum truthful implementation slice.

**Folders Created/Deleted/Modified:**
- relevant repo paths discovered during diagnosis

**Files Created/Deleted/Modified:**
- relevant repo files discovered during diagnosis

**Status:** ✅ Complete

**Results:** Research diagnosis complete. The straight-right `window_not_full` screenshot is a real moment-in-time state, but it does not mean straight-right is globally broken. Full repo-side proving replay with the learned backend emits `punch_right` on the straight-right fixture, so total straight-right failure is not reproducible as a whole-fixture failure. The deeper problem is a mix of early-window/startup fragility on some replays plus genuine model/data separability weakness, especially on right-side late windows and on hook/uppercut classes. The learned classifier correctly refuses to score until its 8-frame history window is full, which explains early `window_not_full` states, but offline inference against the frozen benchmark/model shows that some valid right-side windows still collapse to `no_punch` even with adequate pose samples and duration. Repo-side evidence also shows left-side issues are mostly punch-class confusion (straight/hook vs uppercut), while right-side issues are more severe `no_punch` collapse, especially for hook-right and uppercut-right. Feature extraction code appears side-symmetric, so this does not look like a runtime left/right bug. Minimum truthful next slice is fixture/data-window audit first: inspect and likely adjust the exported truth windows for the hardest samples (`straight_right::01`, `straight_right::04`, `hook_left::04`, `hook_right::04`, `uppercut_right::04`), rerun export plus the frozen benchmark, and only then move to model/data tuning if those audited windows still fail.

---

### Task 2: Implement learned-classifier class-separation tuning or fixture/runtime fix

**Bead ID:** `aerobeat-input-camera-tracking-9zit`  
**SubAgent:** `primary` (for `coder`)  
**Role:** `coder`  
**References:** `REF-02`, `REF-03`, `REF-04`, `REF-05`, `REF-06`  
**Prompt:** Implement the narrowest truthful fix for the diagnosed learned-classifier class-separation issue. This may be fixture/runtime window handling, feature/config tuning, label/contract fixes, or model-side tuning depending on Task 1 results. Preserve the recent proving/runtime/debug fixes and avoid regressing the improved noise resistance Derrick observed.

**Folders Created/Deleted/Modified:**
- relevant repo paths discovered in Task 1

**Files Created/Deleted/Modified:**
- relevant repo files discovered in Task 1

**Status:** ⏳ Pending

**Results:** Pending.

---

### Task 3: QA learned-classifier left/right punch behavior after tuning

**Bead ID:** `aerobeat-input-camera-tracking-z03w`  
**SubAgent:** `primary` (for `qa`)  
**Role:** `qa`  
**References:** `REF-02`, `REF-03`, `REF-05`, `REF-06`  
**Prompt:** Verify learned-classifier behavior on left/right straight, hook, and uppercut proving fixtures after the fix. Confirm that right-side straight no longer gets stuck at `no_punch` if that is fixable in scope, and that left-side confusion is either improved or truthfully characterized.

**Folders Created/Deleted/Modified:**
- relevant owning repo paths

**Files Created/Deleted/Modified:**
- QA notes/artifacts as needed

**Status:** ⏳ Pending

**Results:** Pending.

---

### Task 4: Audit learned-classifier tuning conclusions and residual gaps

**Bead ID:** `aerobeat-input-camera-tracking-8d44`  
**SubAgent:** `primary` (for `auditor`)  
**Role:** `auditor`  
**References:** `REF-01`, `REF-02`, `REF-03`, `REF-05`, `REF-06`, `REF-07`  
**Prompt:** Independently truth-check the learned-classifier tuning branch, confirm what improved for left/right punches, and record any residual model limitations that remain after the implementation slice.

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

---

*Completed on Pending*
