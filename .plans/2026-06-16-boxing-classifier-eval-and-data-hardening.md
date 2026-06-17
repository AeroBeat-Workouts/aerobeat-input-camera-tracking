# AeroBeat Boxing Classifier Eval and Data Hardening

**Date:** 2026-06-16
**Status:** In Progress
**Last Updated:** 2026-06-16 18:00 EDT
**Blocked Reason:** None.
**Agent:** `pico`

---

## Goal

Harden the boxing punch-classifier evaluation path around the current tiny temporal-MLP baseline so future model-family comparisons are less vulnerable to same-clip leakage, weak negative coverage, and replay/capture alignment drift.

---

## Overview

The first classifier feasibility slice proved something useful but limited: inside the current frozen fixture-local harness, a tiny temporal MLP beat both the threshold baseline and the first small temporal CNN. Audit called the honest conclusion `MLP wins for now, but don't overread it.` The reason not to overread it is structural rather than mysterious: the current split leaks the same fixture clips across train and test, the dataset is small, negative/transition coverage is thin, and recapture alignment drift can perturb exported windows outside frozen-artifact comparisons.

Derrick explicitly approved executing the hardening plan next. This branch should therefore avoid premature model-family tuning and instead strengthen the benchmark itself. The target outcome is a more trustworthy classifier harness that can answer better questions: whether the MLP still wins under clip-held-out or session-held-out evaluation, whether added negatives/transitions change the apparent quality gap, and whether alignment/replay determinism is tight enough that repeated exports produce comparable windows. The hybrid boxing architecture stays intact: threshold/pose continues owning non-punch boxing state like guard, while the classifier path remains punch-only.

This should stay disciplined. We are not trying to solve all classifier architecture questions in one seam. First make the evaluation harder and more honest around the current MLP baseline; only then should follow-up classifier/model comparisons be trusted.

---

## REFERENCES

| ID | Description | Path |
| --- | --- | --- |
| `REF-01` | Completed classifier feasibility plan and audit outcome | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.plans/2026-06-16-boxing-punch-classifier-feasibility-mlp-then-temporal-cnn.md` |
| `REF-02` | Classifier-first recommendation brief | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/docs/reviews/boxing-depth-vs-classifier-decision-brief-2026-06-16.md` |
| `REF-03` | Current classifier harness docs | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/docs/baselines/boxing-punch-classifier-harness.md` |
| `REF-04` | Current dataset/export harness scripts | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/scripts/boxing_classifier_harness.py` |
| `REF-05` | Current MLP trainer | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/scripts/train_boxing_punch_mlp_baseline.py` |
| `REF-06` | Current fixture videos and YAML truth windows | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.testbed/assets/fixtures/boxing/` |
| `REF-07` | Prior classifier architecture freeze memory | `memory/2026-06-11.md#L1-L10` |

---

## Tasks

### Task 1: Harden export/eval protocol around the MLP baseline

**Bead ID:** `aerobeat-input-camera-tracking-jfwu`
**SubAgent:** `primary` (for `coder`)
**Role:** `coder`
**References:** `REF-01`, `REF-03`, `REF-04`, `REF-05`, `REF-06`, `REF-07`
**Prompt:** Strengthen the current boxing punch-classifier harness around the tiny temporal-MLP baseline. Focus on three things: (1) stronger split discipline such as clip-held-out or session-held-out evaluation, (2) better negative/transition coverage, and (3) tighter replay/capture alignment or at least clearer deterministic handling/reporting of alignment offsets. Keep the hybrid boxing architecture intact and do not widen into a new model-family experiment yet. Re-run the MLP baseline in the hardened harness and document how the benchmark changed.

**Folders Created/Deleted/Modified:**
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/scripts/`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/docs/`
- test/data/export paths as needed

**Files Created/Deleted/Modified:**
- harness/export/eval/docs artifacts and minimally necessary support files

**Status:** ✅ Complete

**Results:** Implemented the first benchmark-hardening push in `scripts/boxing_classifier_harness.py`, `scripts/export_boxing_punch_classifier_dataset.py`, and `scripts/train_boxing_punch_mlp_baseline.py`, then committed the hardened artifact set under `docs/baselines/boxing-punch-classifier-mlp-hardened-baseline-2026-06-16/`. The exporter now uses chronological holdout splits instead of the old interleaved same-clip split, expands `no_punch` coverage from 36 to 72 samples with explicit transition negatives, and records per-sample / per-fixture alignment error plus capture offset summaries. On the hardened harness, the same tiny temporal MLP dropped from **0.867 accuracy / 0.887 macro F1** to **0.655 accuracy / 0.210 macro F1** on test, while the threshold baseline landed at **0.621 accuracy / 0.259 macro F1**. This is a materially harder and more honest benchmark, and the MLP advantage mostly disappeared under it.

---

### Task 2: QA the hardened harness and MLP rerun

**Bead ID:** `aerobeat-input-camera-tracking-bylk`
**SubAgent:** `primary` (for `qa`)
**Role:** `qa`
**References:** `REF-01`, `REF-03`, `REF-04`, `REF-05`, `REF-06`
**Prompt:** Verify the hardened evaluation protocol and the rerun MLP baseline. Confirm the benchmark is genuinely harder/more honest than before, confirm the MLP rerun is internally consistent, and call out exactly what improved and what is still weak.

**Folders Created/Deleted/Modified:**
- relevant owning repo paths

**Files Created/Deleted/Modified:**
- `.plans/2026-06-16-boxing-classifier-eval-and-data-hardening.md`

**Status:** ✅ Complete

**Results:** QA verified all three claimed hardening changes in code and artifacts: samples are now assigned via `chronological_holdout_v1`, `no_punch` coverage expanded to 72 with explicit transition-before/after negatives, and export summaries now include per-sample plus aggregated alignment-error reporting. The committed hardened artifact set is internally consistent: `dataset.json`, `export-summary.json`, `threshold-baseline.json`, and `mlp-result.json` agree on **96** samples, **67/29** train/test split, and the reported hardened metrics (**MLP 0.655 accuracy / 0.210 macro F1**, **threshold 0.621 accuracy / 0.259 macro F1**). QA also confirmed that rerunning the trainer on the committed hardened dataset reproduces the same headline MLP metrics. One caveat: a fresh exporter rerun against the current default capture-report location (`--skip-captures`) did **not** byte-reproduce the archived hardened dataset or threshold metrics, which suggests the exact capture-report set matters and that the archived `.temp/boxing-punch-classifier-export/hardened-2026-06-16/` inputs should be treated as the reproducibility anchor for this benchmark snapshot. Honest read: the hardened comparison is fairer than the original, materially harder, and the prior apparent MLP edge mostly disappeared; the MLP is now near-threshold on accuracy and worse than threshold on macro-F1.

---

### Task 3: Audit the hardened benchmark and recommend the next classifier/model branch

**Bead ID:** `aerobeat-input-camera-tracking-5drw`
**SubAgent:** `primary` (for `auditor`)
**Role:** `auditor`
**References:** `REF-01`, `REF-02`, `REF-03`, `REF-04`, `REF-05`, `REF-06`
**Prompt:** Independently audit the hardened benchmark and the rerun MLP baseline. Decide whether the benchmark is now trustworthy enough to support another model-family comparison, and recommend the next classifier branch explicitly based on the hardened result.

**Folders Created/Deleted/Modified:**
- relevant owning repo paths

**Files Created/Deleted/Modified:**
- `.plans/2026-06-16-boxing-classifier-eval-and-data-hardening.md`

**Status:** ✅ Complete

**Results:** Audit agrees with QA on the core facts and tightens the decision. The hardened artifact set is materially fairer than the original benchmark: it really does use `chronological_holdout_v1`, expands negatives to **72 no-punch** windows with transition examples, and exposes alignment summaries instead of hiding replay drift. On that frozen hardened dataset, the tiny MLP reproduces exactly at **0.655 accuracy / 0.210 macro-F1** and the threshold baseline is **0.621 accuracy / 0.259 macro-F1**, which means the earlier apparent MLP win mostly collapsed under a harder split and stronger negatives. The strict audit conclusion is that this slice is trustworthy enough to say **the first classifier advantage was not robust**, but **not yet trustworthy enough to justify another model-family comparison from fresh exports** because the current exporter path does not byte-reproduce the archived hardened dataset or threshold metrics when rerun with the present default capture-report location and `--skip-captures`. For now, the archived `.temp/boxing-punch-classifier-export/hardened-2026-06-16/` capture/report set is the reproducibility anchor. Recommended next branch: stay on the classifier line, but make the next branch a **benchmark reproducibility / dataset-freeze hardening branch**, not a temporal-CNN-vs-MLP (or depth) branch yet. Only after export inputs and capture-report provenance are explicitly frozen and re-runnable should another model-family comparison be treated as roadmap-shaping evidence.

---

## Final Results

**Status:** ⚠️ Partial

**What We Built:** Pending.

**Reference Check:** Pending.

**Commits:**
- Pending.

**Lessons Learned:** Pending.
