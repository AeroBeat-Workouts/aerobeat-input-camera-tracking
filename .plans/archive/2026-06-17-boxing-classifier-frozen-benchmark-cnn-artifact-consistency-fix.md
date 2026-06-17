# AeroBeat Boxing Classifier Frozen-Benchmark CNN Artifact Consistency Fix

**Date:** 2026-06-17  
**Status:** Complete  
**Last Updated:** 2026-06-17 16:55 EDT  
**Blocked Reason:** None  
**Agent:** `pico`

---

## Goal

Repair the frozen-benchmark CNN improvement artifact packet so every committed summary and delta matches the frozen source artifacts exactly, then rerun QA and audit before choosing the next classifier branch.

---

## Overview

QA found that the improvement pass was directionally honest but not artifact-clean: the frozen export, the prior frozen reference, and the committed `best-cnn/cnn-result.json` all agree on the threshold baseline test macro-F1, but `tuning-summary.json` does not. Before we make any branch decision about the CNN, the packet needs to become internally consistent again.

The evidence so far points to a summary-layer transcription problem rather than a model-training or frozen-snapshot problem. The trainer script computes threshold metrics directly from the dataset records, and the committed `best-cnn/cnn-result.json` plus the frozen export agree on `0.2585034013605442`. Only the hand-curated comparison summary records `0.25925925925925924`. This fix branch should stay narrow: correct the artifact mismatch, regenerate or repair any dependent summary deltas/readme text, rerun QA, then audit whether the CNN branch is still the right next move.

---

## REFERENCES

| ID | Description | Path |
| --- | --- | --- |
| `REF-01` | Prior improvement-pass plan with QA failure details | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.plans/2026-06-16-boxing-classifier-frozen-benchmark-cnn-improvement-pass.md` |
| `REF-02` | Frozen snapshot manifest | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.testbed/assets/benchmarks/boxing_punch_classifier_hardened_2026_06_16.snapshot.json` |
| `REF-03` | Improvement-pass tuning summary with the mismatch | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/docs/baselines/boxing-punch-classifier-frozen-benchmark-cnn-improvement-pass-2026-06-16/tuning-summary.json` |
| `REF-04` | Improvement-pass best CNN result | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/docs/baselines/boxing-punch-classifier-frozen-benchmark-cnn-improvement-pass-2026-06-16/best-cnn/cnn-result.json` |
| `REF-05` | Frozen comparison baseline artifact set | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/docs/baselines/boxing-punch-classifier-frozen-benchmark-mlp-vs-cnn-2026-06-16/` |
| `REF-06` | Temporal CNN trainer that computes threshold metrics from dataset records | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/scripts/train_boxing_punch_temporal_cnn.py` |

---

## Tasks

### Task 1: Repair the inconsistent summary artifact and explain the root cause

**Bead ID:** `aerobeat-input-camera-tracking-70yp`  
**SubAgent:** `primary` (for `coder`)  
**Role:** `coder`  
**References:** `REF-01`, `REF-02`, `REF-03`, `REF-04`, `REF-05`, `REF-06`  
**Prompt:** Investigate the threshold-baseline macro-F1 mismatch in the frozen-benchmark CNN improvement packet. Claim bead `aerobeat-input-camera-tracking-70yp` on start. Determine whether the mismatch came from summary transcription, stale derivation logic, or another artifact-assembly seam. Repair the committed packet so every referenced threshold-baseline metric and dependent delta matches the frozen source artifacts exactly. Keep scope narrow: do not retune the model or widen the benchmark branch. Update the active plan with what actually caused the mismatch, what files changed, and commit/push the fix by default.

**Folders Created/Deleted/Modified:**
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/docs/`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.plans/`

**Files Created/Deleted/Modified:**
- `docs/baselines/boxing-punch-classifier-frozen-benchmark-cnn-improvement-pass-2026-06-16/tuning-summary.json`
- this plan file

**Status:** ✅ Complete

**Results:** Investigated the inconsistency against `REF-03`, `REF-04`, `REF-05`, and `REF-06`. The real root cause was summary-layer transcription drift introduced when `tuning-summary.json` was hand-authored in commit `a065855`; there is no generator path in the trainer/export pipeline for this file, and the incorrect exact macro-F1 appears only in `REF-03` while the trainer-produced/frozen artifacts already agreed elsewhere. Repaired `threshold_baseline.test_macro_f1` from `0.25925925925925924` to `0.2585034013605442`, and updated the dependent `best_observed.delta_vs_threshold.macro_f1` from `0.006046863189720356` to `0.006802721088435382`. Validation compared the repaired summary against `best-cnn/cnn-result.json`, the prior frozen `mlp/mlp-result.json`, and the frozen export `threshold-baseline.json`; all threshold-baseline values now agree exactly. Commit/push completed on `main`.

---

### Task 2: QA the repaired artifact packet

**Bead ID:** `aerobeat-input-camera-tracking-qv1h`  
**SubAgent:** `primary` (for `qa`)  
**Role:** `qa`  
**References:** `REF-02`, `REF-03`, `REF-04`, `REF-05`, `REF-06`  
**Prompt:** Claim bead `aerobeat-input-camera-tracking-qv1h` on start. Verify that the repaired improvement packet is internally consistent and still anchored to the same frozen benchmark snapshot. Confirm the threshold-baseline metrics and all dependent deltas/readouts are exact, not approximate, and decide whether QA now passes.

**Folders Created/Deleted/Modified:**
- relevant owning repo paths

**Files Created/Deleted/Modified:**
- QA notes/artifacts as needed

**Status:** ✅ Complete

**Results:** QA verified commit `ad7a076` remained a summary-layer repair only: `git show --name-only --stat ad7a076` touched just `tuning-summary.json` plus this plan file, with no frozen export or benchmark-anchor artifact edits. Confirmed `REF-03` still points at the exact same snapshot manifest path (`.testbed/assets/benchmarks/boxing_punch_classifier_hardened_2026_06_16.snapshot.json`) and that its recorded export hashes still match the frozen export files byte-for-byte (`dataset.json`, `export-summary.json`, `threshold-baseline.json`). Verified exact threshold-baseline equality across the repaired summary, `best-cnn/cnn-result.json`, the prior frozen `mlp/mlp-result.json`, and the frozen export `threshold-baseline.json`: test accuracy `0.6206896551724138`, test macro-F1 `0.2585034013605442`. Recomputed dependent deltas from the summary values and confirmed exact agreement, including `best_observed.delta_vs_threshold.macro_f1 = 0.006802721088435382`. QA verdict: pass; packet is internally consistent and ready for auditor bead `aerobeat-input-camera-tracking-8cvo`.

---

### Task 3: Audit the repaired packet and recommend the next branch

**Bead ID:** `aerobeat-input-camera-tracking-8cvo`  
**SubAgent:** `primary` (for `auditor`)  
**Role:** `auditor`  
**References:** `REF-01`, `REF-02`, `REF-03`, `REF-04`, `REF-05`, `REF-06`  
**Prompt:** Claim bead `aerobeat-input-camera-tracking-8cvo` on start. Independently audit the repaired frozen-benchmark CNN packet, verify that the inconsistency is actually resolved, and then recommend the next classifier/testing branch from the corrected evidence.

**Folders Created/Deleted/Modified:**
- relevant owning repo paths

**Files Created/Deleted/Modified:**
- audit notes/artifacts as needed

**Status:** ✅ Complete

**Results:** Independent audit passed. Re-verified that the inconsistency was actually eliminated rather than merely re-described: `REF-03` now records the same threshold-baseline test accuracy (`0.6206896551724138`) and test macro-F1 (`0.2585034013605442`) as `REF-04`, the prior frozen `REF-05` MLP artifact, and the frozen export anchored by `REF-02`; the export hashes in the packet still match the frozen source files byte-for-byte. Recomputed the repaired dependent deltas from `REF-03` and confirmed they are internally exact, including `best_observed.delta_vs_threshold.macro_f1 = 0.006802721088435382` and `best_observed.delta_vs_prior_cnn.macro_f1 ≈ 0.0008684324793747` (rounding-only difference at the final decimal place versus raw subtraction). Audit conclusion from the corrected evidence: the repair is real and the packet is now artifact-clean, but the tuned wider-`k=3` CNN is not justified as a new default baseline because its macro-F1 gain over the prior frozen CNN is effectively negligible and the README-documented alternate seeds regress sharply. Recommendation: keep the prior frozen CNN result as the stable baseline/reference, keep the tuned `k=3`/wider CNN as exploratory evidence only, and make the next branch a robustness/repeatability branch (multi-seed or similarly stability-focused validation) rather than promoting this tuned run or reverting to the MLP.

---

## Final Results

**Status:** ✅ Complete

**What We Built:** Narrow artifact-consistency repair only: the frozen-benchmark CNN improvement packet now carries the exact threshold-baseline macro-F1 and dependent delta from the frozen source artifacts, with the implementation scope intentionally limited to the committed summary layer. QA and audit both confirmed the repaired packet stays anchored to the same frozen export and is internally consistent again.

**Reference Check:** `REF-03` now matches `REF-04` and `REF-05` exactly for threshold-baseline accuracy/macro-F1, the frozen snapshot/export anchors in `REF-02` still match byte-for-byte, and the trainer logic in `REF-06` still supports the conclusion that the mismatch was not caused by model training or export generation.

**Commits:**
- `ad7a076` - `docs: fix frozen benchmark cnn summary threshold metrics`

**Lessons Learned:** When a packet mixes generated result files with hand-curated summaries, exact benchmark values should be copied from the generated JSON artifacts or re-derived mechanically rather than transcribed by hand. Also, a repaired artifact packet can pass truth-checking while still failing to justify promotion of an exploratory tuned model to the new default baseline.
