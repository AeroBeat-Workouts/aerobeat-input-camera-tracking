# AeroBeat Boxing Punch Classifier Feasibility — MLP Baseline Then 1D Temporal CNN

**Date:** 2026-06-16
**Status:** Complete
**Last Updated:** 2026-06-16 16:59 EDT
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
- `.temp/qa-boxing-punch-classifier-2026-06-16/`

**Files Created/Deleted/Modified:**
- `.plans/2026-06-16-boxing-punch-classifier-feasibility-mlp-then-temporal-cnn.md`
- QA rerun artifacts under `.temp/qa-boxing-punch-classifier-2026-06-16/`

**Status:** ✅ Complete

**Results:** QA verified that the harness is genuinely exporting punch/no-punch windows from the committed fixture YAML truth set and attaching threshold-detector predictions for those same exported capture windows. The committed artifact set is internally consistent: YAML punch windows account for all 24 positive samples (4 per punch class), `no_punch` contributes 36 derived negatives, deterministic per-label split counts are 45 train / 15 test, dataset shape is `8 frames x 16 features/frame`, and the saved MLP artifact matches the documented `8x16 -> flatten(128) -> hidden(12) -> logits(7)` baseline with the reported **0.867 accuracy / 0.887 macro-F1** against the threshold baseline’s **0.400 / 0.095** on the same committed windows. A fresh full recapture + retrain reproduced the harness flow and overall class/split structure, but not the exact committed metrics: small fixture-capture time-origin offset drift (~65 ms observed on straight-left recapture) changed some capture-aligned windows and shifted results to **0.733 / 0.587** for the MLP and **0.533 / 0.114** for threshold on that rerun. So the tooling direction is real and still strong enough to justify the immediate 1D temporal CNN follow-up, but the current benchmark should be read as a fixture-local directional signal with same-clip leakage and imperfect recapture determinism, not a stable generalization benchmark.

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
- `.plans/2026-06-16-boxing-punch-classifier-feasibility-mlp-then-temporal-cnn.md`
- `.temp/audit-mlp-rerun-committed/`
- `.temp/audit-mlp-rerun-committed-2/`
- `.temp/audit-mlp-rerun-committed-exact/`

**Status:** ✅ Complete

**Results:** Independent audit confirms the harness is useful enough to justify the immediate 1D temporal CNN follow-up, but only as a **scientifically weak, fixture-local comparison harness** rather than a trustworthy generalization benchmark. I verified directly that the committed artifact set is internally reproducible on the committed `dataset.json` when retrained with the exact recorded hyperparameters (`--hidden-dim 12 --epochs 300 --learning-rate 0.04 --weight-decay 0.001 --seed 42`), reproducing the documented **0.867 accuracy / 0.887 macro-F1** versus the threshold baseline’s **0.400 / 0.095** on the same 15 test windows. QA’s caveats hold up: the deterministic split is by window within the same fixture clips, not by held-out clip, so every punch class leaks from train into test (`3 train + 1 test` windows from the same source clip for each positive class), and 13 fixtures appear in both train and test overall. The harness also aligns fixture YAML windows to capture time by adding per-capture offsets (committed sample offsets span **928–990 ms**), so QA’s recapture-drift warning remains material when results are regenerated from fresh captures. Auditor recommendation: proceed with Task 4 now because the harness can still answer the narrow question “does a small temporal CNN beat the tiny temporal MLP and threshold baseline on this exact exported-window protocol?”, but read any CNN gain only as a same-harness directional improvement. Do **not** interpret the CNN result as proof of real-world punch generalization unless the next seam adds clip-held-out or session-held-out evaluation and tighter capture-time alignment/replay determinism.

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

**Status:** ✅ Complete

**Results:** Added `scripts/train_boxing_punch_temporal_cnn.py` as the first small 1D temporal-CNN follow-up in the exact same exported-window harness used by Task 1. The committed CNN artifact set lives under `docs/baselines/boxing-punch-classifier-temporal-cnn-baseline-2026-06-16/` and reuses the committed `dataset.json` / `mlp-result.json` for an apples-to-apples comparison rather than widening the protocol. The chosen model is intentionally small: **`8x16 -> conv1d(16->12, k=5, same) -> relu -> conv1d(12->8, k=5, same) -> relu -> flatten(64) -> logits(7)`** trained with **1000 epochs, lr 0.01, weight decay 0.0, seed 42**. On this exact fixture-local split it reached **0.667 accuracy / 0.492 macro-F1**, which is **better than the threshold baseline (0.400 / 0.095)** but **materially worse than the tiny temporal MLP baseline (0.867 / 0.887)**. That means the first disciplined CNN pass did not win the same-harness comparison. Carry forward the audit constraints explicitly: treat this only as a fixture-local directional comparison, do not claim real-world generalization, same-clip leakage still exists in the split policy, and recapture alignment drift still exists so comparisons should stay inside the committed export protocol.

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
- `.plans/2026-06-16-boxing-punch-classifier-feasibility-mlp-then-temporal-cnn.md`
- `.temp/qa-cnn-rerun-2026-06-16/`
- `.temp/qa-mlp-rerun-2026-06-16/`

**Status:** ✅ Complete

**Results:** QA verified that the CNN comparison is fair **inside the committed fixture-local harness**. The CNN script consumes the committed `docs/baselines/boxing-punch-classifier-mlp-baseline-2026-06-16/dataset.json` plus the committed `mlp-result.json`, so it reuses the exact same exported windows, label set, deterministic split, and threshold-baseline records rather than regenerating fresh captures. I also independently reran both training scripts on the committed dataset with the exact recorded hyperparameters and reproduced the committed artifacts bit-for-bit at the result level: the MLP stayed at **0.867 accuracy / 0.887 macro-F1**, and the CNN stayed at **0.667 accuracy / 0.492 macro-F1**, with matching loss curves and matching per-sample train/test predictions. The committed docs and artifacts are internally consistent: dataset shape is `8x16`, split counts remain `45 train / 15 test`, the CNN model JSON matches the documented **`8x16 -> conv1d(16->12, k=5, same) -> relu -> conv1d(12->8, k=5, same) -> relu -> flatten(64) -> logits(7)`** shape, and the reported threshold comparison remains **0.400 accuracy / 0.095 macro-F1** on those same windows. Truthful read: this first small CNN **did beat the threshold baseline**, but it **lost clearly to the tiny temporal MLP baseline**, so it does **not** currently justify replacing the MLP as the better next mainline model family. Keep the prior audit constraints in force: this is still only a same-harness, fixture-local directional result with same-clip leakage and no real-world generalization claim.

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

**Status:** ✅ Complete

**Results:** Independent audit agrees with QA’s narrow claim and tightens the product conclusion: **MLP wins for now, but don't overread it.** On the exact committed exported-window protocol, the tiny temporal MLP remains the best-performing classifier in this slice at **0.867 accuracy / 0.887 macro-F1**, ahead of the first small temporal CNN at **0.667 / 0.492** and the threshold baseline at **0.400 / 0.095**. I independently reran both training scripts on the committed `dataset.json` with the recorded hyperparameters and reproduced the same metrics. That is enough to make a same-harness model choice for the next branch: keep the hybrid boxing architecture and prefer the tiny temporal MLP over this first CNN as the current mainline punch-classifier candidate.

The limits matter. This harness is still too weak to support a broad model-family verdict beyond this first slice because train/test windows leak within the same source clips, the benchmark is fixture-local and directional rather than product-general, and fresh recaptures can move alignment enough to change outcomes outside the committed artifact comparison. So the right call is **not** “CNNs are bad for AeroBeat.” The right call is: this specific small CNN lost a fair apples-to-apples comparison on the current harness, so AeroBeat should **not** spend the next branch tuning CNNs first. The better next classifier branch is to keep the tiny temporal MLP as the punch-classifier baseline and invest the next seam in **evaluation/data hardening**: clip-held-out or session-held-out splits, more negative/transition coverage, and tighter capture-time alignment/replay determinism. Once that stronger benchmark exists, compare MLP against richer temporal families again if needed.

Strongest constraints before acting on this result: (1) do not claim real-world punch generalization from this slice; (2) do not replace threshold handling for non-punch boxing states, because the approved hybrid architecture still fits the evidence best; (3) do not interpret this as a permanent MLP-over-CNN theorem, only as the current same-harness winner; and (4) treat any future model comparison that regenerates captures as partially confounded unless capture alignment is tightened or the comparison stays on frozen exported windows. References validated: `REF-01`, `REF-03`, `REF-06`, `REF-07`.

---

## Final Results

**Status:** ✅ Complete

**What We Built:** A disciplined first feasibility slice for AeroBeat boxing punch classification: reusable fixture export/eval tooling, a tiny temporal-MLP baseline, a first same-harness 1D temporal-CNN comparison, QA verification of both artifact sets, and an independent audit conclusion on what AeroBeat should do next. The final audited recommendation is to continue down the hybrid classifier path for punches while keeping threshold logic for non-punch boxing state, with the **tiny temporal MLP as the current preferred classifier baseline** and **benchmark/data hardening** as the next branch rather than more CNN-first tuning.

**Reference Check:** `REF-01` and `REF-03` still hold: the hybrid boxing architecture remains the right mainline direction, with classifier work scoped to punch recognition and guard/recovery/transition left to pose/threshold logic. `REF-06` and `REF-07` were satisfied for this slice’s fixture-export/eval workflow, with explicit caveats carried forward about same-clip leakage, fixture-local scope, and recapture alignment drift.

**Commits:**
- `3cc4190` - Add boxing punch classifier export harness and MLP baseline
- `0d5142c` - Add temporal CNN punch classifier comparison

**Lessons Learned:** The tooling path is good enough to answer narrow within-harness questions quickly, but it is not yet a trustworthy generalization benchmark. Small temporal models can easily look decisively different on frozen exported windows, so the next high-value move is improving split discipline and capture determinism before reading too much into model-family outcomes.
