# AeroBeat Boxing Classifier Frozen-Benchmark MLP vs CNN Comparison

**Date:** 2026-06-16
**Status:** Stale
**Last Updated:** 2026-06-16 19:56 EDT
**Blocked Reason:** None.

**Stale Archive Note:** Marked stale and archived on 2026-08-03 during Byte workspace cleanup; newer AeroBeat work remains with Pico.
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

**Status:** ✅ Complete

**Results:** QA re-ran the exact frozen export + MLP + CNN commands against `REF-02` into fresh QA-only temp outputs and got the same export hashes and the same committed test metrics/records. The rerun confirmed the comparison is fair on a shared frozen `dataset.json` generated with `--skip-captures`, both learned models use the same `chronological_holdout_v1` split, and the committed artifact set is internally consistent (`cnn-result.json` links back to the matching MLP result and both report the same frozen dataset path shape/metrics). Truthful QA read: on this hardened frozen benchmark slice, the CNN really does beat the MLP modestly but clearly (`0.724/0.264` vs `0.655/0.210` accuracy/macro-F1), while the threshold baseline remains close in macro-F1 (`0.621/0.259`). Caveat retained: this is still a small frozen fixture benchmark, so the result supports the frozen-slice ranking claim only, not a broad live/generalization claim.

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

**Status:** ✅ Complete

**Results:** Independent audit agrees with QA and the committed artifact set. The frozen comparison really is apples-to-apples on `REF-02`: both learned models were evaluated from the same `--skip-captures` export path and the same `chronological_holdout_v1` split, and the committed JSON/markdown artifacts report the same numbers consistently. Strict read: **CNN wins on the frozen benchmark for now, but do not overgeneralize beyond that path.** On this slice, the current temporal CNN beats the current temporal MLP by `+0.06897` accuracy and `+0.05491` macro-F1 (`0.72414/0.26444` vs `0.65517/0.20952`). It also edges the threshold baseline in accuracy and only barely in macro-F1 (`0.62069/0.25850`), which means the learned-model win is real but still modest and the benchmark remains small/hard enough that branch decisions should stay conservative. Audit recommendation: prefer the temporal CNN over the MLP as the **frozen-benchmark baseline** going forward, and make the next classifier branch a **targeted CNN-on-frozen-benchmark improvement pass** rather than reopening broad classifier exploration or reverting to the MLP. Strongest constraints before acting: this result is tied to `REF-02` only, the margin over threshold on macro-F1 is tiny, and the branch does not yet justify a broad claim about live-capture/general production superiority.

---

## Final Results

**Status:** ✅ Complete

**What We Built:** Completed the full frozen-benchmark MLP-vs-CNN loop: coder reran and documented the reproducible comparison on the named frozen snapshot, QA independently reproduced the same hashes/metrics, and audit concluded that the current temporal CNN is the better learned-model baseline on this frozen path.

**Reference Check:** `REF-02` satisfied via exact frozen-snapshot export reuse and matching committed metrics; `REF-03`/`REF-04`/`REF-05`/`REF-06` exercised by the shared harness plus both trainer outputs; `REF-07` updated because the hardened frozen benchmark reverses the earlier winner/loser relationship.

**Commits:**
- `7a66f24` - Document frozen boxing classifier MLP vs CNN rerun

**Lessons Learned:** The hardened frozen benchmark changed the truthful ranking. On this reproducible slice, the CNN beats the MLP modestly but clearly, yet its macro-F1 lead over the threshold baseline is still tiny. That makes the right next move a narrow CNN-focused follow-up on the frozen path, not a broad generalization claim or a premature declaration that the classifier problem is solved.
