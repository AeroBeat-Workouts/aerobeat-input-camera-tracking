# AeroBeat Boxing Punch Classifier Feasibility — MLP Baseline Then 1D Temporal CNN

**Date:** 2026-06-16
**Status:** In Progress
**Last Updated:** 2026-06-16 16:16 EDT
**Blocked Reason:** None.
**Agent:** `pico`

---

## Goal

Build a first boxing punch-classifier feasibility slice that uses a hybrid architecture: pose/threshold logic remains responsible for non-punch boxing state like guard, while a new classifier path is evaluated for punch recognition, first with a tiny temporal-MLP baseline and then with a 1D temporal CNN in the same harness.

---

## Overview

Derrick approved the classifier-first direction after the depth/classifier research pass, with an important architecture constraint: AeroBeat only needs the classifier path for punches, while pose/threshold logic should continue handling non-punch boxing gestures such as guard. That makes the target architecture a hybrid boxing backend rather than a full replacement of every boxing rule. Flow remains on its simpler pose/threshold path because it does not need the boxing punch-classifier complexity.

This execution slice should stay disciplined. We are not trying to build a final production boxing ML stack in one pass. The point is to prove the tooling and training/evaluation path with a very small baseline first, then immediately test whether a 1D temporal CNN gives a better result on the same exported data and harness. The tiny MLP exists primarily as a sanity/diagnostic baseline: if it cannot beat or at least meaningfully engage the threshold baseline, that tells us something important about feature quality, labels, or data preparation before we over-read a stronger model.

The first-pass runtime shape should stay aligned with the prior classifier planning work: punch classes only (`straight_left/right`, `hook_left/right`, `uppercut_left/right`, `no_punch`), guard/recovery/transition as metadata rather than primary runtime classes, and a swappable boxing detector family where `classifier` can become a new boxing backend alongside existing threshold/prototype-style backends. Source context for that earlier freeze: `memory/2026-06-11.md#L1-L10`.

---

## REFERENCES

| ID | Description | Path |
| --- | --- | --- |
| `REF-01` | Classifier-vs-depth decision brief | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/docs/reviews/boxing-depth-vs-classifier-decision-brief-2026-06-16.md` |
| `REF-02` | Research plan that selected classifier-first | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.plans/2026-06-16-boxing-depth-and-classifier-paths-research.md` |
| `REF-03` | Prior classifier architecture freeze memory | `memory/2026-06-11.md#L1-L10` |
| `REF-04` | Current boxing gesture config | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/assets/boxing.gesture_detection.yaml` |
| `REF-05` | Current pose substrate / available features | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/src/detectors/pose_detector_substrate.gd` |
| `REF-06` | Boxing fixture assets and YAML truth windows | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.testbed/assets/fixtures/boxing/` |
| `REF-07` | Prototype benchmark / capture tooling patterns | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/scripts/` |

---

## Tasks

### Task 1: Build classifier export/eval harness plus tiny temporal-MLP baseline

**Bead ID:** `aerobeat-input-camera-tracking-e9fc`
**SubAgent:** `primary` (for `coder`)
**Role:** `coder`
**References:** `REF-01`, `REF-03`, `REF-04`, `REF-05`, `REF-06`, `REF-07`
**Prompt:** Implement the first feasibility slice for boxing punch classification in this repo. Keep pose/threshold handling for guard/non-punch state as-is, and build the classifier work for punch classes only. In the same seam, add the minimum export/dataset/eval tooling needed to train and score a tiny temporal-MLP baseline over stacked pose-feature windows against the boxing fixture/truth data. Make the harness reusable for the follow-up 1D temporal CNN pass, and compare baseline results against the current threshold detector where practical. Keep the seam narrow and infrastructure-first.

**Folders Created/Deleted/Modified:**
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.testbed/assets/benchmarks/`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/scripts/`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/docs/baselines/`
- temp export/train outputs used to generate committed artifacts

**Files Created/Deleted/Modified:**
- `.testbed/assets/benchmarks/boxing_punch_classifier_v1.benchmark.json`
- `scripts/boxing_classifier_harness.py`
- `scripts/export_boxing_punch_classifier_dataset.py`
- `scripts/train_boxing_punch_mlp_baseline.py`
- `docs/baselines/boxing-punch-classifier-harness.md`
- `docs/baselines/boxing-punch-classifier-mlp-baseline-2026-06-16/*`

**Status:** ✅ Complete

**Results:** Added a reusable fixture-capture/export/dataset/eval harness for boxing punch-classifier experiments. The export path replays committed boxing fixtures, aligns YAML truth windows to capture time, extracts 8-frame windows with 16 pose-derived features/frame (left+right shoulder/elbow/wrist XY plus derived velocity and extension features), builds punch-class and `no_punch` samples, records deterministic train/test splits, and logs what the current threshold backend predicted on each exported window. The first tiny temporal-MLP baseline uses `flatten(8x16=128) -> hidden(12) -> logits(7)` and its committed artifact set lives under `docs/baselines/boxing-punch-classifier-mlp-baseline-2026-06-16/`. On the tiny clip-local test split it reached **0.867 accuracy / 0.887 macro-F1** versus the threshold baseline's **0.400 accuracy / 0.095 macro-F1** on the exact same exported windows. This is a promising signal for the classifier path, but still a tooling-and-data-path proof with obvious same-clip leakage limits rather than a production-ready generalization claim.

---

### Task 2: QA the harness and temporal-MLP baseline

**Bead ID:** `aerobeat-input-camera-tracking-bzj2`
**SubAgent:** `primary` (for `qa`)
**Role:** `qa`
**References:** `REF-01`, `REF-04`, `REF-05`, `REF-06`, `REF-07`
**Prompt:** Verify the classifier export/eval harness and tiny temporal-MLP baseline. Confirm the tooling is trustworthy enough to compare models, confirm the class/window setup matches the approved boxing classifier direction, and judge whether the baseline gives a meaningful enough signal to justify the follow-up 1D temporal CNN push.

**Folders Created/Deleted/Modified:**
- relevant owning repo paths

**Files Created/Deleted/Modified:**
- QA notes/artifacts as needed

**Status:** ⏳ Pending

**Results:** Pending.

---

### Task 3: Audit the baseline and greenlight the 1D temporal CNN follow-up

**Bead ID:** `aerobeat-input-camera-tracking-wmi5`
**SubAgent:** `primary` (for `auditor`)
**Role:** `auditor`
**References:** `REF-01`, `REF-03`, `REF-06`, `REF-07`
**Prompt:** Independently audit the harness and temporal-MLP baseline result. Decide whether the setup is disciplined enough and informative enough to justify the immediate follow-up 1D temporal CNN pass, and call out any data/export/eval weaknesses that must be respected when reading the result.

**Folders Created/Deleted/Modified:**
- relevant owning repo paths

**Files Created/Deleted/Modified:**
- audit notes/artifacts as needed

**Status:** ⏳ Pending

**Results:** Pending.

---

### Task 4: Implement the 1D temporal CNN in the same harness and compare it against the MLP baseline

**Bead ID:** `aerobeat-input-camera-tracking-qprf`
**SubAgent:** `primary` (for `coder`)
**Role:** `coder`
**References:** `REF-01`, `REF-04`, `REF-05`, `REF-06`, `REF-07`
**Prompt:** Using the exact same export/eval harness from the baseline slice, implement the first 1D temporal CNN boxing punch classifier and compare it against the temporal-MLP baseline and current threshold behavior. Keep the model small and disciplined. The purpose is not maximal ML complexity; it is to learn whether short-window temporal convolutions materially improve the punch-classification signal on this dataset.

**Folders Created/Deleted/Modified:**
- relevant owning repo paths

**Files Created/Deleted/Modified:**
- model/training/eval/docs artifacts as needed

**Status:** ⏳ Pending

**Results:** Pending.

---

### Task 5: QA the 1D temporal CNN pass

**Bead ID:** `aerobeat-input-camera-tracking-gmbh`
**SubAgent:** `primary` (for `qa`)
**Role:** `qa`
**References:** `REF-01`, `REF-04`, `REF-05`, `REF-06`, `REF-07`
**Prompt:** Verify the first 1D temporal CNN pass in the shared harness. Confirm the comparison against the MLP baseline is fair, the results are reproducible enough to trust directionally, and whether the CNN is actually a better next mainline model family for AeroBeat boxing punches.

**Folders Created/Deleted/Modified:**
- relevant owning repo paths

**Files Created/Deleted/Modified:**
- QA notes/artifacts as needed

**Status:** ⏳ Pending

**Results:** Pending.

---

### Task 6: Audit the CNN result and recommend the next classifier branch

**Bead ID:** `aerobeat-input-camera-tracking-u0ij`
**SubAgent:** `primary` (for `auditor`)
**Role:** `auditor`
**References:** `REF-01`, `REF-03`, `REF-06`, `REF-07`
**Prompt:** Independently audit the first 1D temporal CNN result against the MLP baseline and the threshold baseline. Recommend whether AeroBeat should continue down the classifier path, what the next dataset/model seam should be, and whether the hybrid boxing architecture still looks like the right mainline direction.

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
