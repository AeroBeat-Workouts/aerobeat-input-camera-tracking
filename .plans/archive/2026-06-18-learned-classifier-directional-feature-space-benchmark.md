# AeroBeat Learned Classifier Directional Feature Space Benchmark

**Date:** 2026-06-18  
**Status:** Complete  
**Last Updated:** 2026-06-18 08:22 EDT  
**Blocked Reason:** None  
**Agent:** `pico`

---

## Goal

Benchmark and improve learned-classifier punch separation by adding directional-motion features and comparing camera-space, body-space, and combined feature variants against the current baseline.

---

## Overview

The prior learned-classifier proving branches fixed the runtime and observability stack: backend selection truth, model-path loading, replay-reset state cleanup, inspector parity, and the first fixture truth-window audit. Those fixes established that the learned backend now genuinely runs and that the remaining problems are mostly model/data behavior rather than plumbing.

The next logical branch is to enrich the learned feature representation rather than jumping straight to more threshold-style logic. Derrick’s core idea is to expose directionality to the model — effectively giving it more explicit information about horizontal versus vertical momentum over time, possibly as continuous directional features and/or coarse directional buckets. The key open design question is not whether direction matters, but which coordinate space produces the best punch separation: camera space, body space, or both together.

This branch should be benchmark-driven. We should keep the same underlying training/evaluation workflow and compare feature-space variants cleanly so we can answer whether camera-space features, body-space features, or combined features best improve difficult classes like left/right hook and uppercut while preserving the good noise resistance already observed in proving.

---

## REFERENCES

| ID | Description | Path |
| --- | --- | --- |
| `REF-01` | Completed left/right window-audit checkpoint plan | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.plans/2026-06-17-learned-classifier-left-right-punch-separation-tuning.md` |
| `REF-02` | Current learned-classifier config | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/assets/boxing.gesture_detection.yaml` |
| `REF-03` | Learned classifier runtime | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/src/detectors/learned_punch_classifier.gd` |
| `REF-04` | Dataset/export path | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/scripts/export_boxing_punch_classifier_dataset.py` |
| `REF-05` | Frozen MLP benchmark artifact | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/docs/baselines/boxing-punch-classifier-frozen-benchmark-mlp-vs-cnn-2026-06-16/mlp/mlp-result.json` |
| `REF-06` | Frozen CNN benchmark artifact | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/docs/baselines/boxing-punch-classifier-frozen-benchmark-mlp-vs-cnn-2026-06-16/cnn/cnn-result.json` |
| `REF-07` | Current benchmark manifest | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.testbed/assets/benchmarks/boxing_punch_classifier_v1.benchmark.json` |

---

## Tasks

### Task 1: Design directional feature variants and benchmark plan

**Bead ID:** `aerobeat-input-camera-tracking-pz7c`  
**SubAgent:** `primary` (for `research`)  
**Role:** `research`  
**References:** `REF-01`, `REF-03`, `REF-04`, `REF-05`, `REF-06`, `REF-07`  
**Prompt:** Audit the current learned-classifier feature vector and design a benchmark plan for directional feature enrichment. Determine exactly which new motion features should be added for camera-space, body-space, and combined variants; whether coarse direction buckets should accompany continuous directional features; and how to compare variants fairly against the current baseline. Include exact code/data paths and the minimum truthful implementation slice.

**Folders Created/Deleted/Modified:**
- relevant repo paths discovered during diagnosis

**Files Created/Deleted/Modified:**
- relevant repo files discovered during diagnosis

**Status:** ✅ Complete

**Results:** Research completed. The current learned model sees 8 baseline features per side: shoulder/elbow/wrist x/y, combined elbow+wrist velocity magnitude, and elbow↔shoulder distance normalized by shoulder width, for 16 features per frame and 128 flattened inputs per 8-frame window. It does not explicitly see signed horizontal/vertical momentum, camera/body-relative direction, or coarse direction buckets. The recommended benchmark plan is to keep those baseline features fixed and compare three new directional bundles against the current baseline: camera-space only, body-space only, and combined camera+body space. Each directional bundle adds signed velocity x/y plus a 5-way one-hot directional cue (`none/up/down/left/right`) derived from the same motion vector. Research also called out a key safety requirement: athlete/body-space semantics must stay distinct from camera-space semantics so screen-left/screen-right are never mistaken for anatomical left/right. Minimum truthful coder slice: make export/training/runtime feature extraction feature-set-aware, preserve feature metadata in artifacts, validate runtime feature schema against artifact metadata, and run the full benchmark matrix at least through the MLP path, ideally CNN too.

---

### Task 2: Implement feature-space variants and rerun benchmark matrix

**Bead ID:** `aerobeat-input-camera-tracking-uw14`  
**SubAgent:** `primary` (for `coder`)  
**Role:** `coder`  
**References:** `REF-03`, `REF-04`, `REF-05`, `REF-06`, `REF-07`  
**Prompt:** Implement the agreed directional feature variants for learned-classifier benchmarking: camera-space only, body-space only, and combined. Rerun the benchmark matrix and capture per-class results, especially for straight/hook/uppercut left/right. Preserve the current proving/runtime fixes and avoid slipping into threshold-gate fallback logic.

**Folders Created/Deleted/Modified:**
- relevant repo paths discovered in Task 1

**Files Created/Deleted/Modified:**
- `scripts/boxing_classifier_harness.py`
- `scripts/export_boxing_punch_classifier_dataset.py`
- `scripts/train_boxing_punch_mlp_baseline.py`
- `scripts/train_boxing_punch_temporal_cnn.py`
- `src/detectors/prototype_punch_matcher.gd`
- `src/detectors/learned_punch_classifier.gd`
- benchmark artifacts under `docs/baselines/boxing-punch-classifier-directional-feature-benchmark-2026-06-18/`

**Status:** ✅ Complete

**Results:** Implemented feature-set-aware learned-classifier benchmarking for `baseline_v1`, `camera_directional_v1`, `body_directional_v1`, and `combined_directional_v1`. Baseline 8 features per side stayed unchanged; the new variants add directional bundles with signed continuous velocities plus coarse one-hot direction buckets while keeping camera-space and body-space semantics explicitly separate. Preserved feature metadata (`feature_set`, `side_feature_names`, `frame_feature_names`) through export and training artifacts, mirrored the feature math into runtime extraction, and added runtime artifact/schema validation so feature-order mismatches fail load instead of silently drifting. Ran the full benchmark matrix through both MLP and CNN. Best overall result remained the existing baseline CNN (`0.8621 accuracy / 0.4198 macro-F1`). Directional variants did not beat baseline overall: camera-directional CNN `0.7586 / 0.3623`, body-directional CNN `0.6897 / 0.3577`, combined CNN `0.7931 / 0.3631`. Some class-level gains appeared (for example uppercut-left improved in some directional CNN variants), but hook-left/hook-right still failed across all variants and combined features looked overfit-prone on the tiny dataset. Commit pushed: `485b942` (`Add directional learned-classifier feature benchmarks`).

---

### Task 3: QA benchmark outputs and learned-classifier behavior deltas

**Bead ID:** `aerobeat-input-camera-tracking-55ag`  
**SubAgent:** `primary` (for `qa`)  
**Role:** `qa`  
**References:** `REF-03`, `REF-04`, `REF-05`, `REF-06`, `REF-07`  
**Prompt:** Verify that the new feature-space benchmark outputs are reproducible enough for decision-making and summarize which variant actually improves the weak punch classes without regressing noise resistance or the recent proving/runtime fixes.

**Folders Created/Deleted/Modified:**
- relevant owning repo paths

**Files Created/Deleted/Modified:**
- QA notes/artifacts as needed

**Status:** ✅ Complete

**Results:** QA PASS with caveats for directional-feature benchmark commit `485b942`. Full 4-variant matrix rerun from the same hardened capture-report package reproduced the committed benchmark outputs after normalizing timestamp/path metadata, so the branch is reproducible enough for decision-making on that local capture package. Baseline CNN remains the truthful overall winner (`0.8621 accuracy / 0.4198 macro-F1`) and no directional variant beats it. The directional variants did produce real localized effects — most notably `uppercut_left` recovery in both camera-directional and body-directional CNN variants — but those gains came with regressions elsewhere and were not strong enough to outperform the baseline. QA also confirmed that export/training schema validation is real via negative metadata/order/feature-set mismatch tests, and direct code inspection showed athlete-space and camera-space semantics are kept distinct rather than conflated. Main caveats: reproducibility currently depends on the local hardened capture-report package rather than a frozen snapshot manifest, and the richer directional variants are likely overfit-prone on the tiny dataset, especially the combined feature set.

---

### Task 4: Audit feature-space conclusions and recommend the next learned-model path

**Bead ID:** `aerobeat-input-camera-tracking-wbnv`  
**SubAgent:** `primary` (for `auditor`)  
**Role:** `auditor`  
**References:** `REF-01`, `REF-03`, `REF-04`, `REF-05`, `REF-06`, `REF-07`  
**Prompt:** Independently truth-check the directional feature-space benchmark results, confirm which variant actually wins, and recommend whether the next learned-classifier path should be camera-space, body-space, combined, or further data work before more feature expansion.

**Folders Created/Deleted/Modified:**
- relevant owning repo paths

**Files Created/Deleted/Modified:**
- audit notes/artifacts as needed

**Status:** ✅ Complete

**Results:** Audit PASS. This branch is a good benchmark checkpoint, not a promotion-ready learned-model improvement. Independent audit confirmed that the baseline CNN remains the truthful overall winner (`0.8621 accuracy / 0.4198 macro-F1`) and that none of the directional variants beat it overall. The directional variants are still worth preserving as benchmark artifacts because they produced localized effects — especially some `uppercut_left` recovery — but they also regress elsewhere, leave `hook_left` / `hook_right` unsolved, and show overfit signals in the richer combined feature set. Audit also confirmed that athlete-space and camera-space semantics remained distinct in implementation, schema-validation hardening is real and meaningful, and the branch’s reproducibility claim must stay narrow: reproducible enough from the hardened capture-report package, but not a frozen-snapshot-manifest story. Recommended next path: more data before more feature expansion, with camera-space as the first directional family to revisit later if the dataset improves.

---

## Final Results

**Status:** ✅ Complete (Checkpoint)

**What We Built:** We completed a directional-feature benchmark checkpoint for the learned classifier by adding camera-space, body-space, and combined directional feature variants on top of the current baseline pose features, carrying feature metadata end-to-end through export/training/runtime, and benchmarking the full matrix across MLP and CNN. The branch answered the main design question: directional-motion enrichment is interesting, but in this v1 form it does not outperform the existing baseline CNN.

**Reference Check:** `REF-03` and `REF-04` now support feature-set-aware extraction and artifact validation; `REF-05` and `REF-06` remain the prior frozen benchmark references; `REF-07` benchmark workflow remains the basis of the reruns, though current reproducibility depends on the hardened capture-report package rather than a frozen snapshot manifest.

**Commits:**
- `485b942` - `Add directional learned-classifier feature benchmarks`

**Lessons Learned:** Adding explicit direction features can produce real local class effects without producing a net overall win. On this tiny dataset, richer feature sets especially the combined bundle increased dimensionality faster than they improved generalization, so more data is the right next move before more feature expansion. The branch still delivered a durable engineering improvement: learned-model artifacts now carry and validate feature schema more strictly, reducing the risk of silent runtime/export mismatch.

---

*Completed on 2026-06-18*
