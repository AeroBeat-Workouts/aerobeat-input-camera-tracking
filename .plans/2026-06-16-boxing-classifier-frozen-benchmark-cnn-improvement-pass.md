# AeroBeat Boxing Classifier Frozen-Benchmark CNN Improvement Pass

**Date:** 2026-06-16
**Status:** Blocked
**Last Updated:** 2026-06-17 09:36 EDT
**Blocked Reason:** QA failed on an internal artifact-consistency issue: `tuning-summary.json` records the threshold baseline test macro-F1 as `0.25925925925925924`, while the frozen source/export artifacts and committed `best-cnn/cnn-result.json` agree on `0.2585034013605442`. Corrective follow-up moved to `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.plans/2026-06-17-boxing-classifier-frozen-benchmark-cnn-artifact-consistency-fix.md`.
**Agent:** `pico`

---

## Goal

Improve the current temporal CNN on the reproducible frozen boxing benchmark so it can widen its lead over the tiny temporal MLP and threshold baseline before any live/replay-facing testing branch begins.

---

## Overview

The frozen-benchmark comparison clarified the current model ranking: on the reproducible `--skip-captures` snapshot path, the temporal CNN now beats the MLP, but only modestly, and it remains very close to the threshold baseline on macro-F1. That means the right next move is not yet live or replay-based product testing on Chip. The CNN needs a focused improvement pass first, still on the frozen benchmark, so we can learn whether its lead is meaningful and expandable or merely a fragile edge.

This branch should stay narrow. We are not reopening broad model-family exploration and we are not mixing live-capture nondeterminism back into the evaluation. The purpose is to improve the existing CNN through disciplined frozen-benchmark work: architecture/hyperparameter tuning and, if needed, tightly scoped feature/export refinements that still preserve apples-to-apples comparison on the frozen snapshot. The boxing architecture remains hybrid: threshold/pose owns non-punch state like guard, while the classifier remains punch-only.

The success bar for this branch is not “CNN solved boxing.” The success bar is simpler: establish whether a targeted frozen-benchmark CNN pass can move the learned model from barely ahead of threshold to a more clearly useful punch-classifier baseline, while keeping the benchmark honest and reproducible.

---

## REFERENCES

| ID | Description | Path |
| --- | --- | --- |
| `REF-01` | Frozen-benchmark MLP vs CNN comparison plan/result | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.plans/2026-06-16-boxing-classifier-frozen-benchmark-mlp-vs-cnn.md` |
| `REF-02` | Frozen snapshot manifest | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.testbed/assets/benchmarks/boxing_punch_classifier_hardened_2026_06_16.snapshot.json` |
| `REF-03` | Current harness docs | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/docs/baselines/boxing-punch-classifier-harness.md` |
| `REF-04` | Current temporal CNN trainer | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/scripts/train_boxing_punch_temporal_cnn.py` |
| `REF-05` | Current MLP trainer | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/scripts/train_boxing_punch_mlp_baseline.py` |
| `REF-06` | Shared classifier harness/export helpers | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/scripts/boxing_classifier_harness.py` |
| `REF-07` | Latest frozen comparison artifact set | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/docs/baselines/boxing-punch-classifier-frozen-benchmark-mlp-vs-cnn-2026-06-16/` |

---

## Tasks

### Task 1: Improve the temporal CNN on the frozen benchmark and document the new comparison

**Bead ID:** `aerobeat-input-camera-tracking-w76n`
**SubAgent:** `primary` (for `coder`)
**Role:** `coder`
**References:** `REF-02`, `REF-03`, `REF-04`, `REF-05`, `REF-06`, `REF-07`
**Prompt:** Run a targeted improvement pass for the current temporal CNN using only the reproducible frozen benchmark snapshot. Keep the benchmark path frozen with `--skip-captures`. Focus on disciplined CNN improvement: architecture/hyperparameter tuning and, only if justified, narrowly scoped frozen-benchmark feature/export refinements that preserve fair comparison. Re-compare the improved CNN against the current frozen MLP and threshold baselines and document whether the CNN lead widened meaningfully.

**Folders Created/Deleted/Modified:**
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/scripts/`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/docs/`
- comparison artifact paths as needed

**Files Created/Deleted/Modified:**
- `docs/baselines/boxing-punch-classifier-frozen-benchmark-cnn-improvement-pass-2026-06-16/README.md`
- `docs/baselines/boxing-punch-classifier-frozen-benchmark-cnn-improvement-pass-2026-06-16/tuning-summary.json`
- `docs/baselines/boxing-punch-classifier-frozen-benchmark-cnn-improvement-pass-2026-06-16/best-cnn/cnn-result.json`
- `docs/baselines/boxing-punch-classifier-frozen-benchmark-cnn-improvement-pass-2026-06-16/best-cnn/cnn-result.md`
- `docs/baselines/boxing-punch-classifier-frozen-benchmark-cnn-improvement-pass-2026-06-16/best-cnn/cnn-model.json`

**Status:** ✅ Complete

**Results:** Reproduced the frozen export hashes exactly with `--skip-captures`, then ran a focused CNN-only tuning sweep on the frozen dataset. The best observed single run used `conv1=16`, `conv2=12`, `kernel=3`, `epochs=1000`, `learning_rate=0.01`, `weight_decay=0.0005`, `seed=42`, which moved CNN test accuracy from `0.724` to `0.759` but only moved macro-F1 from `0.264` to `0.265`. Alternate seeds for the same wider-`k=3` shape regressed materially, so the gain was seed-sensitive rather than robust. Truthful conclusion: the CNN still beats the frozen MLP on this frozen slice, but this pass did **not** widen the CNN lead meaningfully on macro-F1, so the tuned shape is documented as exploratory rather than promoted as a new default.

---

### Task 2: QA the improved frozen-benchmark CNN comparison

**Bead ID:** `aerobeat-input-camera-tracking-dum6`
**SubAgent:** `primary` (for `qa`)
**Role:** `qa`
**References:** `REF-02`, `REF-03`, `REF-04`, `REF-05`, `REF-06`, `REF-07`
**Prompt:** Verify that the improved CNN comparison still uses the frozen snapshot fairly, that the committed artifacts are internally consistent, and whether the CNN really improved enough to justify keeping it as the learned frontrunner.

**Folders Created/Deleted/Modified:**
- relevant owning repo paths

**Files Created/Deleted/Modified:**
- QA notes/artifacts as needed

**Status:** ❌ Failed

**Results:** QA confirmed the comparison stayed on the frozen snapshot contract: the pass used `--skip-captures`, reused one frozen export, and the committed export hashes in `tuning-summary.json` exactly match the anchors in `REF-02` (`dataset.json=90af58361b4fac04571beb340806415434748a2401df9462d3f425637b1a88ba`, `export-summary.json=8abc20a46396609144f7aeaa3d83de785f9e8174bcaefd1681bbe2d82a625b6c`, `threshold-baseline.json=a89539077c750103eb406c67364fed1bdf9c44cbf1a378028af5debc7de5198a`). QA also confirmed the tuned CNN’s headline claim is directionally honest but weak: best observed accuracy improved from `0.7241379310` to `0.7586206897`, while macro-F1 only moved from `0.2644376899` to `0.2653061224`, and alternate seeds (`7`, `99`) regressed materially. However, the committed artifact bundle is **not internally consistent**: `docs/baselines/boxing-punch-classifier-frozen-benchmark-cnn-improvement-pass-2026-06-16/tuning-summary.json` records the threshold baseline test macro-F1 as `0.25925925925925924`, but the frozen source artifact `REF-07`, the frozen export’s `threshold-baseline.json`, and the committed `best-cnn/cnn-result.json` all agree on `0.2585034013605442`. Because this pass’s acceptance criteria explicitly include artifact consistency, QA failed the bead pending correction of that mismatch and any dependent summary deltas.

---

### Task 3: Audit the improved CNN pass and recommend the next classifier/testing branch

**Bead ID:** `aerobeat-input-camera-tracking-obta`
**SubAgent:** `primary` (for `auditor`)
**Role:** `auditor`
**References:** `REF-02`, `REF-03`, `REF-04`, `REF-05`, `REF-06`, `REF-07`
**Prompt:** Independently audit the improved frozen-benchmark CNN pass. Decide whether the CNN is now strong enough to justify becoming the active classifier baseline for the next downstream testing branch, and recommend the next classifier or testing plan explicitly.

**Folders Created/Deleted/Modified:**
- relevant owning repo paths

**Files Created/Deleted/Modified:**
- audit notes/artifacts as needed

**Status:** ⏳ Pending

**Results:** Pending.

---

## Final Results

**Status:** ⚠️ Partial

**What We Built:** Built and documented a targeted frozen-benchmark CNN improvement sweep against the reproducible snapshot path, including a committed best-run artifact bundle and tuning summary. The pass confirmed the frozen benchmark still reproduces exactly and that the current CNN remains ahead of the frozen MLP on this slice, but the best observed improvement was mostly an accuracy nudge rather than a meaningful macro-F1 gain.

**Reference Check:** `REF-02` preserved; all comparison work stayed on the named frozen snapshot with `--skip-captures`. `REF-07` remains the comparison baseline the improvement pass was judged against.

**Commits:**
- `a065855ac747e6b09d4020c9dbe5a4c4af8c0fc1` - `docs: record frozen benchmark cnn improvement pass`

**Lessons Learned:** The frozen benchmark is finally stable enough to run disciplined CNN tuning, but this first sweep suggests the current small CNN is seed-sensitive and not obviously opening a strong margin over threshold. The next session should finish QA/audit on this pass before deciding whether to do more CNN tuning, adjust the feature set, or pivot the next testing branch.
