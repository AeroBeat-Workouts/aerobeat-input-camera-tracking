# AeroBeat Boxing Classifier Frozen-Benchmark MLP vs CNN Comparison

**Date:** 2026-06-16
**Status:** In Progress
**Last Updated:** 2026-06-16 19:39 EDT
**Blocked Reason:** None.
**Agent:** `pico`

---

## Goal

Resume punch-classifier model comparison on the newly reproducible frozen benchmark so AeroBeat can truthfully compare the current tiny temporal MLP against the temporal CNN on a stable dataset path.

---

## Overview

The reproducibility branch succeeded: the named frozen snapshot now reproduces `dataset.json`, `export-summary.json`, and `threshold-baseline.json` byte-for-byte along the `--skip-captures` path. That means the project can finally return to model comparison without the benchmark shifting underneath it. The current architectural rules still apply: the boxing system remains hybrid, with threshold/pose handling non-punch state like guard and the classifier path focused on punch recognition only.

This branch should stay narrow and disciplined. The point is not to reopen broad model exploration all at once. First, re-establish the current MLP versus CNN comparison explicitly on the reproducible frozen benchmark path, verify whether the earlier relationship still holds there cleanly, and then decide whether the next move is to tune the CNN, enrich features, or keep the MLP as the active classifier baseline. All conclusions from this branch should be tied to the named frozen snapshot rather than fresh live-capture generation.

---

## REFERENCES

| ID | Description | Path |
| --- | --- | --- |
| `REF-01` | Reproducibility/data-freeze plan | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.plans/2026-06-16-boxing-classifier-benchmark-reproducibility-and-dataset-freeze.md` |
| `REF-02` | Frozen snapshot manifest | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.testbed/assets/benchmarks/boxing_punch_classifier_hardened_2026_06_16.snapshot.json` |
| `REF-03` | Classifier harness docs | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/docs/baselines/boxing-punch-classifier-harness.md` |
| `REF-04` | MLP trainer | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/scripts/train_boxing_punch_mlp_baseline.py` |
| `REF-05` | Temporal CNN trainer | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/scripts/train_boxing_punch_temporal_cnn.py` |
| `REF-06` | Shared classifier harness helpers/exporter | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/scripts/boxing_classifier_harness.py` |
| `REF-07` | Prior classifier feasibility plan/results | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.plans/2026-06-16-boxing-punch-classifier-feasibility-mlp-then-temporal-cnn.md` |

---

## Tasks

### Task 1: Re-run and document MLP vs CNN on the frozen benchmark snapshot

**Bead ID:** `aerobeat-input-camera-tracking-tr9s`
**SubAgent:** `primary` (for `coder`)
**Role:** `coder`
**References:** `REF-02`, `REF-03`, `REF-04`, `REF-05`, `REF-06`, `REF-07`
**Prompt:** Using the named frozen snapshot only, re-run the current tiny temporal MLP and the current temporal CNN in an explicitly apples-to-apples way and document the comparison. Keep the benchmark path frozen (`--skip-captures`) and be explicit that this is a frozen-benchmark comparison, not a live-capture generalization claim. If the CNN still loses, say so plainly. If anything changed meaningfully under the frozen benchmark, document why.

**Folders Created/Deleted/Modified:**
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/scripts/`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/docs/`
- comparison artifact paths as needed

**Files Created/Deleted/Modified:**
- `docs/baselines/boxing-punch-classifier-frozen-benchmark-mlp-vs-cnn-2026-06-16/`
- `docs/baselines/boxing-punch-classifier-harness.md`
- `scripts/train_boxing_punch_temporal_cnn.py`
- comparison artifacts/docs and minimally necessary support files

**Status:** ✅ Complete

**Results:** Re-ran the frozen snapshot export via `--skip-captures` and verified that `dataset.json`, `export-summary.json`, and `threshold-baseline.json` reproduced the exact frozen snapshot hashes from `REF-02`. Then re-ran the current hardened tiny temporal MLP (`8x16 -> flatten(128) -> hidden(24) -> logits(7)`) and the current temporal CNN (`8x16 -> conv1d(16->12, k=5, same) -> relu -> conv1d(12->8, k=5, same) -> relu -> flatten(64) -> logits(7)`) on that same exported dataset. The earlier relationship changed under the frozen hardened benchmark: the CNN now beats the MLP on the shared frozen test split (`0.724 / 0.264` vs `0.655 / 0.210` accuracy / macro-F1), while the threshold baseline remains close in macro-F1 (`0.621 / 0.259`). Added a committed artifact directory documenting commands, hash checks, model shapes, and the result shift; also corrected the CNN markdown generator so hardened runs describe the `chronological_holdout_v1` split truthfully.

---

### Task 2: QA the frozen-benchmark comparison

**Bead ID:** `aerobeat-input-camera-tracking-5yer`
**SubAgent:** `primary` (for `qa`)
**Role:** `qa`
**References:** `REF-02`, `REF-03`, `REF-04`, `REF-05`, `REF-06`
**Prompt:** Verify that the resumed MLP-vs-CNN comparison really uses the frozen snapshot path fairly, and confirm whether the reported winner/loser relationship holds under the reproducible benchmark. Call out any remaining caveats, but treat live-capture nondeterminism as out of scope unless it leaks into the frozen comparison.

**Folders Created/Deleted/Modified:**
- relevant owning repo paths

**Files Created/Deleted/Modified:**
- QA notes/artifacts as needed

**Status:** ⏳ Pending

**Results:** Pending.

---

### Task 3: Audit the frozen-benchmark comparison and recommend the next classifier branch

**Bead ID:** `aerobeat-input-camera-tracking-wea6`
**SubAgent:** `primary` (for `auditor`)
**Role:** `auditor`
**References:** `REF-02`, `REF-03`, `REF-04`, `REF-05`, `REF-06`, `REF-07`
**Prompt:** Independently audit the frozen-benchmark MLP-vs-CNN comparison and recommend the next classifier branch explicitly. Decide whether AeroBeat should keep the MLP as the current baseline, try a targeted CNN tuning pass, or shift to a different classifier seam next.

**Folders Created/Deleted/Modified:**
- relevant owning repo paths

**Files Created/Deleted/Modified:**
- audit notes/artifacts as needed

**Status:** ⏳ Pending

**Results:** Pending.

---

## Final Results

**Status:** ⚠️ Partial

**What We Built:** Completed the coder slice for the frozen-benchmark rerun: reproducible export verification plus a documented apples-to-apples MLP-vs-CNN comparison artifact set on the named frozen snapshot.

**Reference Check:** `REF-02` satisfied via exact export hash match on the rerun; `REF-03`/`REF-04`/`REF-05`/`REF-06` exercised by the export + training commands and updated artifact docs; `REF-07` comparison updated because the earlier winner/loser relationship changed on the hardened frozen benchmark.

**Commits:**
- Pending coder commit.

**Lessons Learned:** The frozen benchmark did not preserve the earlier first-pass ranking. On this reproducible hardened slice, the current small CNN modestly surpasses the hardened MLP, so future classifier decisions should reference the frozen benchmark rather than the earlier leakier same-harness baseline.
