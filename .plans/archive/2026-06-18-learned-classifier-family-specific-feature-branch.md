# AeroBeat Learned Classifier Family-Specific Feature Branch

**Date:** 2026-06-18  
**Status:** Complete  
**Last Updated:** 2026-06-19 22:29 EDT  
**Blocked Reason:** None  
**Agent:** `pico`

---

## Goal

Improve learned-classifier punch separation by splitting the next feature experiment into family-specific cues: straight-punch alignment/extension features versus hook/uppercut wrist-direction features.

---

## Overview

The directional-feature benchmark branch established an important truth: adding generic directional features was worth testing, but in its first form it did not beat the current baseline CNN. That result, plus Derrick’s motion observations, suggests the next experiment should stop treating all punch families as if they want the same signal source.

For straights, the most reliable cue appears to be structural: the elbow becomes more aligned with the shoulder as the arm extends, while the wrist’s apparent vertical motion may vary with camera height and may not be a stable primary signal. The straight family should therefore focus on elbow↔shoulder structure and elbow↔shoulder velocity alignment rather than wrist↔shoulder alignment. For hooks and uppercuts, the meaningful directional endpoint is more likely the wrist path itself, with hook behavior emphasizing lateral sweep and uppercut behavior emphasizing upward drive. Crucially, those wrist-direction cues must be benchmarked in both camera space and body/athlete space rather than assuming one shared interpretation: the pose data tracks camera-space motion, so a hook’s left/right sign reverses between athlete perspective and camera perspective. That means the next honest branch is not “more generic directional features,” but a family-specific feature experiment that compares straight-specific elbow alignment/velocity cues against wrist-led directional features for hook/uppercut separation across both camera-space and body-space interpretations.

This branch should stay benchmark-driven. We should avoid jumping straight to runtime heuristics or threshold-style post gates. First, define and benchmark the family-specific feature sets cleanly against the current best baseline CNN, then decide whether the resulting features are strong enough to justify promotion into the learned runtime path.

---

## REFERENCES

| ID | Description | Path |
| --- | --- | --- |
| `REF-01` | Directional feature benchmark checkpoint | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.plans/2026-06-18-learned-classifier-directional-feature-space-benchmark.md` |
| `REF-02` | Current learned classifier runtime | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/src/detectors/learned_punch_classifier.gd` |
| `REF-03` | Current feature extraction / benchmark harness | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/scripts/boxing_classifier_harness.py` |
| `REF-04` | Dataset/export path | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/scripts/export_boxing_punch_classifier_dataset.py` |
| `REF-05` | Directional benchmark artifacts | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/docs/baselines/boxing-punch-classifier-directional-feature-benchmark-2026-06-18/summary.json` |
| `REF-06` | Current benchmark manifest | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.testbed/assets/benchmarks/boxing_punch_classifier_v1.benchmark.json` |

---

## Tasks

### Task 1: Design family-specific feature sets and benchmark matrix

**Bead ID:** `aerobeat-input-camera-tracking-hw77`  
**SubAgent:** `primary` (for `research`)  
**Role:** `research`  
**References:** `REF-01`, `REF-02`, `REF-03`, `REF-04`, `REF-05`, `REF-06`  
**Prompt:** Design the next learned-classifier feature experiment around family-specific cues instead of one shared directional signal. Define straight-punch elbow↔shoulder alignment/extension features plus elbow↔shoulder velocity-alignment features, define hook/uppercut wrist-led directional features, and explicitly benchmark those wrist-direction features in both camera space and body/athlete space. Be precise about the sign reversal between athlete perspective and camera-space pose tracking for hooks. Specify a benchmark matrix that compares the variants fairly against the current baseline CNN and the prior generic directional-feature branch. Include exact code/data paths and the narrowest truthful implementation slice.

**Folders Created/Deleted/Modified:**
- relevant repo paths discovered during diagnosis

**Files Created/Deleted/Modified:**
- relevant repo files discovered during diagnosis

**Status:** ✅ Complete

**Results:** Research completed. The recommended family-specific plan keeps the shared baseline intact, adds a straight-specific elbow bundle (`elbow_x_from_shoulder_over_shoulder_width`, `elbow_y_from_shoulder_over_shoulder_width`, and an elbow↔shoulder radial velocity cue), and benchmarks hook/uppercut wrist-led directional bundles in both camera space and body/athlete space. The concept is sound, but later review with Derrick identified a material design concern: the first implementation still fed one shared feature vector to one shared classifier instead of truly isolating straight-family cues from hook/uppercut cues. That means the branch should be treated as a benchmark-design checkpoint rather than a completed family-specific answer.

---

### Task 2: Implement family-specific feature variants and rerun benchmark matrix

**Bead ID:** `aerobeat-input-camera-tracking-ho3s`  
**SubAgent:** `primary` (for `coder`)  
**Role:** `coder`  
**References:** `REF-02`, `REF-03`, `REF-04`, `REF-05`, `REF-06`  
**Prompt:** Implement the agreed family-specific feature variants for learned-classifier benchmarking: straight-specific elbow↔shoulder alignment/extension cues plus elbow↔shoulder velocity-alignment cues, and hook/uppercut wrist-led directional cues, with hook/uppercut wrist direction benchmarked in both camera space and body/athlete space. Rerun the benchmark matrix, preserve artifact metadata/schema validation, and report which variants materially improve the weak classes without regressing the current best baseline more than necessary.

**Folders Created/Deleted/Modified:**
- relevant repo paths discovered in Task 1

**Files Created/Deleted/Modified:**
- `scripts/boxing_classifier_harness.py`
- benchmark artifacts under `docs/baselines/boxing-punch-classifier-family-specific-feature-benchmark-2026-06-18/`

**Status:** ✅ Complete

**Results:** Coder implemented the family-specific benchmark in Python and pushed `c4386cf` (`Benchmark family-specific learned punch features`). The branch added a straight elbow bundle plus wrist-only directional bundles for camera-space and body-space hook/uppercut benchmarking, then reran the benchmark matrix. Result: the family-specific branch did not beat the current baseline CNN or the prior generic directional CNN branch. Best family CNN was `family_combined_directional_v1` at `0.8276 accuracy / 0.2717 macro-F1`, still below the baseline CNN (`0.8621 / 0.4198`) and below the prior directional CNN branch. This implementation also confirmed the material design concern raised afterward: despite the family-specific feature naming, the benchmark still fed one shared feature vector to one shared classifier, so the test did not truly isolate straight-family cues from hook/uppercut-family cues the way Derrick intended.

---

### Task 3: QA family-specific benchmark outputs and behavior deltas

**Bead ID:** `aerobeat-input-camera-tracking-2c42`  
**SubAgent:** `primary` (for `qa`)  
**Role:** `qa`  
**References:** `REF-02`, `REF-03`, `REF-04`, `REF-05`, `REF-06`  
**Prompt:** Verify that the family-specific benchmark outputs are reproducible enough for decision-making and summarize whether the straight-alignment and wrist-direction splits actually outperform the previous directional experiment and/or the current best baseline.

**Folders Created/Deleted/Modified:**
- relevant owning repo paths

**Files Created/Deleted/Modified:**
- QA notes/artifacts as needed

**Status:** ⚪ Not Started

**Results:** Intentionally not executed before land-the-plane. After Derrick reviewed the implementation logic, we recognized that the benchmark shape itself was materially different from his intended test: the branch still fed one shared feature vector to one shared classifier instead of truly isolating straight-family cues from hook/uppercut-family cues. The next session should continue this same branch by reviewing modifications to reduce unrelated family data being available at once before resuming QA.

---

### Task 4: Audit family-specific feature conclusions and recommend the next learned-model path

**Bead ID:** `aerobeat-input-camera-tracking-3yv6`  
**SubAgent:** `primary` (for `auditor`)  
**Role:** `auditor`  
**References:** `REF-01`, `REF-02`, `REF-03`, `REF-04`, `REF-05`, `REF-06`  
**Prompt:** Independently truth-check the family-specific feature benchmark results, confirm whether separating straight features from hook/uppercut features actually helps, and recommend whether the next learned-classifier path should promote any of those features or shift to more data first.

**Folders Created/Deleted/Modified:**
- relevant owning repo paths

**Files Created/Deleted/Modified:**
- audit notes/artifacts as needed

**Status:** ⚪ Not Started

**Results:** Intentionally not executed before land-the-plane for the same reason as QA: the benchmark implementation needs a design review first because it still mixed family-specific cues into one shared classifier input vector, which Derrick correctly identified as materially different from the intended test.

---

### Task 5: Review family-isolated classifier topology options before more benchmarking

**Bead ID:** `aerobeat-input-camera-tracking-hi8l`  
**SubAgent:** `primary` (for `research`)  
**Role:** `research`  
**References:** `REF-02`, `REF-03`, `REF-04`, `REF-05`, `REF-06`  
**Prompt:** Review the current learned classifier runtime and benchmark harness to answer the next design question truthfully: how can we prevent straight-family cues from competing with hook/uppercut-only cues? Compare at least three options: (1) keep the current classifier tech but mask features per family/head, (2) stage the decision path into punch-family routing plus family-specific classification, and (3) change model tech if the current flat shared-input setup cannot express that cleanly. Also judge whether collecting more videos and YAML truths should happen before or after the topology change. Cite exact repo paths and explain the narrowest honest next experiment. Claim bead `aerobeat-input-camera-tracking-hi8l` on start and close it when finished if the research is complete.

**Folders Created/Deleted/Modified:**
- relevant repo paths discovered during design review

**Files Created/Deleted/Modified:**
- plan updates and any research notes/artifacts if needed

**Status:** ✅ Complete

**Results:** Research completed. Current evidence says the repo’s first “family-specific” branch was still architecturally flat: `scripts/boxing_classifier_harness.py` exported one shared left+right feature vector per frame and both training paths consumed one shared multiclass label space, so irrelevant family cues were still available to every class. The narrowest honest next move is not “collect more of the same and hope”; it is a topology check inside the existing harness. Recommended order: first run one benchmark that keeps the current temporal CNN/MLP tech but physically removes irrelevant inputs by exporting family/head-specific datasets (for example, straight-vs-no-punch and hook/uppercut-vs-no-punch or straight/hook/uppercut family heads with per-head feature masks), then compare against the current shared-vector baseline. That tells us whether the present model family is being limited mainly by mixed-input noise or by data scarcity. More videos/YAML truth still matter, but because the current dataset is tiny (4 labeled positives per punch class in the hardened export) they should follow immediately after the topology experiment rather than be the first response; otherwise we risk scaling a known-confounded setup. Constraints discovered: the runtime loader in `src/detectors/learned_punch_classifier.gd` currently only accepts `aerobeat.boxing_punch_classifier_mlp_result` artifacts, and its feature extraction still depends on `src/detectors/prototype_punch_matcher.gd`, which does not resolve the newer wrist-only directional or elbow radial-velocity feature names used by the family benchmark. So the present family-specific feature branch is harness-only evidence unless runtime feature support is extended later.

---

### Task 6: Implement masked-family harness benchmark and report per-family variable usage

**Bead ID:** `aerobeat-input-camera-tracking-vzun`  
**SubAgent:** `primary` (for `coder`)  
**Role:** `coder`  
**References:** `REF-03`, `REF-04`, `REF-05`, `REF-06`  
**Prompt:** Implement the narrowest honest topology test in the existing benchmark/export harness: physically isolate family/head-specific inputs instead of feeding one family-mixed feature vector to one shared classifier. Keep this harness-only for now. Export/train/evaluate at least one straight-family masked setup and one hook/uppercut-family masked setup using the current hardened capture package, compare them against the current shared-vector baseline, and report exactly which variables/features each family/head received. If the masked setup still loses, produce a clear per-family variable inventory so Derrick can diagnose whether the chosen signals themselves are wrong. Claim bead `aerobeat-input-camera-tracking-vzun` on start, run relevant repo-local validation/benchmark commands, commit/push by default when done, and close the bead with a clear reason.

**Folders Created/Deleted/Modified:**
- `docs/baselines/boxing-punch-classifier-family-masked-topology-benchmark-2026-06-18/`
- benchmark/export/runtime-adjacent repo paths discovered during implementation

**Files Created/Deleted/Modified:**
- `scripts/boxing_classifier_harness.py`
- `scripts/export_boxing_punch_classifier_dataset.py`
- `scripts/train_boxing_punch_mlp_baseline.py`
- `scripts/train_boxing_punch_temporal_cnn.py`
- `docs/baselines/boxing-punch-classifier-family-masked-topology-benchmark-2026-06-18/summary.json`
- `docs/baselines/boxing-punch-classifier-family-masked-topology-benchmark-2026-06-18/summary.md`
- `docs/baselines/boxing-punch-classifier-family-masked-topology-benchmark-2026-06-18/straight_family_mask_v1/**`
- `docs/baselines/boxing-punch-classifier-family-masked-topology-benchmark-2026-06-18/hook_uppercut_family_mask_v1/**`
- plan updates / notes as needed

**Status:** ✅ Complete

**Results:** Added harness support for deriving masked family/head datasets directly from the hardened `family_combined_directional_v1` export, with explicit `mask_inventory` metadata and threshold-baseline remapping inside the reduced class space. `train_boxing_punch_mlp_baseline.py` and `train_boxing_punch_temporal_cnn.py` now honor dataset-provided `class_order`, so the same training stack can evaluate reduced family heads without runtime integration.

Generated `docs/baselines/boxing-punch-classifier-family-masked-topology-benchmark-2026-06-18/` with two harness-only variants: `straight_family_mask_v1` and `hook_uppercut_family_mask_v1`. Each variant includes `export/`, `mlp/`, and `cnn/` artifacts plus explicit active/masked feature inventories. I also wrote benchmark-level `summary.json` and `summary.md` that compare each masked head against the existing shared-vector CNN baseline both in full (`baseline_v1`) and on the matching subset of test samples.

Outcome: the masked topology did **not** beat the shared-vector baseline on the same head-local subsets. Straight-family masked CNN reached **0.9600 accuracy / 0.8815 macro-F1** on its 3-class test slice, but the projected shared-vector baseline was already **1.0000 / 1.0000** there. Hook/uppercut masked CNN reached **0.8148 / 0.1796**, while the projected shared-vector baseline was **0.8519 / 0.1878**; masked MLP matched **0.8148 accuracy** and improved macro-F1 to **0.3159**, but still did not produce a clean win over the shared-vector route. The per-family variable inventory is now explicit in `export/export-summary.json` for each variant and summarized in `docs/baselines/boxing-punch-classifier-family-masked-topology-benchmark-2026-06-18/summary.{json,md}` for Derrick’s diagnosis pass.

---

### Task 7: QA masked-family benchmark outputs and reproducibility

**Bead ID:** `aerobeat-input-camera-tracking-owve`  
**SubAgent:** `primary` (for `qa`)  
**Role:** `qa`  
**References:** `REF-03`, `REF-04`, `REF-05`, `REF-06`  
**Prompt:** Verify the masked-family harness benchmark runs truthfully and reproducibly enough for decision-making. Re-run the relevant commands if needed, confirm the compared baselines are fair, and summarize whether masked family isolation materially improved results or still underperformed. Include the per-family variable inventory in the QA summary so Derrick can inspect it easily.

**Folders Created/Deleted/Modified:**
- relevant repo paths used during QA
- `.temp/qa-masked-family-rerun-2026-06-18/`

**Files Created/Deleted/Modified:**
- `.temp/qa-masked-family-rerun-2026-06-18/**`
- plan updates only; no repo artifact files changed during QA

**Status:** ✅ Complete

**Results:** QA re-checked the refreshed checked-in masked benchmark artifacts under `docs/baselines/boxing-punch-classifier-family-masked-topology-benchmark-2026-06-18/` after the truthfulness fix/refresh commits (`18befd6`, `efc5f23`, `c4c75bd`, `05fe7e4`, `fc48d78`). The per-variant export summaries are now truthful for both branches: `straight_family_mask_v1` reports `sample_count: 80` with `split_counts: {train: 55, test: 25}`, and `hook_uppercut_family_mask_v1` reports `sample_count: 88` with `split_counts: {train: 61, test: 27}`. Derived sample-kind totals are also now correct in the checked-in export summaries (`8/20/48/4` for straight annotated/transition-before/no-punch/transition-after and `16/20/48/4` for hook-uppercut).

Variable inventory remains correct and explicit. `straight_family_mask_v1` still exposes only the elbow/shoulder straight-family cue bundle plus core joint coordinates/velocity context, while masking the wrist-direction features; `hook_uppercut_family_mask_v1` still exposes the wrist-direction bundle in both camera/body space plus core joint coordinates/velocity context, while masking the straight-only elbow radial/alignment trio. The benchmark-level `summary.{json,md}` remains internally consistent with each branch export’s `mask_inventory`.

Benchmark conclusion still stands unchanged: the masked-family topology did **not** beat the shared-vector subset baseline. Straight masked CNN remains `0.9600 accuracy / 0.8815 macro-F1` versus a `1.0000 / 1.0000` shared-vector subset baseline, and hook/uppercut masked CNN remains `0.8148 / 0.1796` versus a `0.8519 / 0.1878` shared-vector subset baseline (with masked MLP only improving hook/uppercut macro-F1 relative to the masked CNN, not enough to overturn the overall result). QA now passes on the refreshed artifacts, so audit is ready.

---

### Task 8: Audit masked-family conclusions and recommend next move

**Bead ID:** `aerobeat-input-camera-tracking-1vwg`  
**SubAgent:** `primary` (for `auditor`)  
**Role:** `auditor`  
**References:** `REF-03`, `REF-04`, `REF-05`, `REF-06`  
**Prompt:** Independently truth-check the masked-family benchmark conclusions. Confirm whether feature isolation helped enough to justify staged routing and more data collection, or whether the family-specific variable choices themselves still look weak. If the masked benchmark loses, make the per-family variable inventory explicit and recommend the next diagnosis path for Derrick. Claim bead `aerobeat-input-camera-tracking-1vwg` only when its dependency is ready, and close it only if the audit truly passes.

**Folders Created/Deleted/Modified:**
- relevant repo paths used during audit

**Files Created/Deleted/Modified:**
- audit notes/artifacts as needed

**Status:** ✅ Complete

**Results:** Audit reran the truth check against the refreshed checked-in artifacts rather than the stale pre-fix state. `docs/baselines/boxing-punch-classifier-family-masked-topology-benchmark-2026-06-18/summary.{json,md}` is internally consistent with each branch’s `export/export-summary.json`, `mlp/mlp-result.json`, and `cnn/cnn-result.json`. The refreshed exports are now truthful: `straight_family_mask_v1` reports `sample_count: 80`, `split_counts: {train: 55, test: 25}`, `sample_kind_counts: {annotated_punch_window: 8, transition_before_punch: 20, derived_no_punch_window: 48, transition_after_punch: 4}`, and `label_counts: {straight_left: 4, straight_right: 4, no_punch: 72}`; `hook_uppercut_family_mask_v1` reports `sample_count: 88`, `split_counts: {train: 61, test: 27}`, `sample_kind_counts: {annotated_punch_window: 16, transition_before_punch: 20, derived_no_punch_window: 48, transition_after_punch: 4}`, and `label_counts: {hook_left: 4, hook_right: 4, uppercut_left: 4, uppercut_right: 4, no_punch: 72}`.

The benchmark conclusion still holds after the refresh. Straight masked CNN remains below the shared-vector subset baseline (`0.9600 / 0.8815` vs `1.0000 / 1.0000`), and hook/uppercut masked CNN also remains below its shared-vector subset baseline (`0.8148 / 0.1796` vs `0.8519 / 0.1878`). The hook/uppercut masked MLP does raise macro-F1 over the masked CNN (`0.3159` vs `0.1796`), but it still does not beat the shared-vector subset baseline on either accuracy or the topology question Derrick asked. So the honest read is that feature isolation by itself did not rescue this branch.

The per-family variable inventory stays explicit for follow-up diagnosis. `straight_family_mask_v1` keeps the core shoulder/elbow/wrist coordinates plus the straight-only elbow bundle active (`elbow_x_from_shoulder_over_shoulder_width`, `elbow_y_from_shoulder_over_shoulder_width`, `elbow_shoulder_radial_velocity_over_shoulder_width`) while masking all wrist-direction features. `hook_uppercut_family_mask_v1` keeps the core shoulder/elbow/wrist coordinates plus the wrist-direction bundle active (`camera_wrist_signed_vx`, `camera_wrist_signed_vy`, `camera_wrist_direction_{none,up,down,left,right}`, `body_wrist_signed_vx`, `body_wrist_signed_vy`, `body_wrist_direction_{none,up,down,left,right}`) while masking the straight-only elbow alignment/radial trio. Final audit judgment: the current family-specific variable choices still look weak, especially for hook/uppercut separation, so this does not yet justify staged routing on its own. The next slice should be diagnosis-first: inspect the hook/uppercut confusion cases and engineer a stronger hook/uppercut cue family (for example forearm angle/orbit or wrist-vs-elbow path curvature features) before spending effort on broader data collection or runtime promotion.

---

### Task 9: Fix masked export summary metadata so benchmark artifacts stay truthful

**Bead ID:** `aerobeat-input-camera-tracking-wqy8`  
**SubAgent:** `primary` (for `coder`)  
**Role:** `coder`  
**References:** `REF-03`, `REF-04`, `REF-05`, `REF-06`  
**Prompt:** Fix the masked-family dataset/export summary metadata so derived export artifacts truthfully report their own sample counts, split counts, and related export-summary details instead of copied source-dataset totals. Re-run the masked-family export/train flow as needed, refresh the affected artifacts under `docs/baselines/boxing-punch-classifier-family-masked-topology-benchmark-2026-06-18/`, update the plan with actual results, and close bead `aerobeat-input-camera-tracking-wqy8` with a clear reason when complete.

**Folders Created/Deleted/Modified:**
- masked-family benchmark artifact paths

**Files Created/Deleted/Modified:**
- `scripts/boxing_classifier_harness.py`
- `scripts/export_boxing_punch_classifier_dataset.py`
- `docs/baselines/boxing-punch-classifier-family-masked-topology-benchmark-2026-06-18/straight_family_mask_v1/export/dataset.json`
- `docs/baselines/boxing-punch-classifier-family-masked-topology-benchmark-2026-06-18/straight_family_mask_v1/export/export-summary.json`
- `docs/baselines/boxing-punch-classifier-family-masked-topology-benchmark-2026-06-18/straight_family_mask_v1/export/export-summary.md`
- `docs/baselines/boxing-punch-classifier-family-masked-topology-benchmark-2026-06-18/straight_family_mask_v1/mlp/mlp-result.json`
- `docs/baselines/boxing-punch-classifier-family-masked-topology-benchmark-2026-06-18/straight_family_mask_v1/mlp/mlp-result.md`
- `docs/baselines/boxing-punch-classifier-family-masked-topology-benchmark-2026-06-18/straight_family_mask_v1/cnn/cnn-result.json`
- `docs/baselines/boxing-punch-classifier-family-masked-topology-benchmark-2026-06-18/straight_family_mask_v1/cnn/cnn-result.md`
- `docs/baselines/boxing-punch-classifier-family-masked-topology-benchmark-2026-06-18/hook_uppercut_family_mask_v1/export/dataset.json`
- `docs/baselines/boxing-punch-classifier-family-masked-topology-benchmark-2026-06-18/hook_uppercut_family_mask_v1/export/export-summary.json`
- `docs/baselines/boxing-punch-classifier-family-masked-topology-benchmark-2026-06-18/hook_uppercut_family_mask_v1/export/export-summary.md`
- `docs/baselines/boxing-punch-classifier-family-masked-topology-benchmark-2026-06-18/hook_uppercut_family_mask_v1/mlp/mlp-result.json`
- `docs/baselines/boxing-punch-classifier-family-masked-topology-benchmark-2026-06-18/hook_uppercut_family_mask_v1/mlp/mlp-result.md`
- `docs/baselines/boxing-punch-classifier-family-masked-topology-benchmark-2026-06-18/hook_uppercut_family_mask_v1/cnn/cnn-result.json`
- `docs/baselines/boxing-punch-classifier-family-masked-topology-benchmark-2026-06-18/hook_uppercut_family_mask_v1/cnn/cnn-result.md`

**Status:** ✅ Complete

**Results:** Fixed the derived masked-export truthfulness bug by recomputing masked dataset metadata from the derived sample set instead of inheriting source-dataset split/sample-kind counts. `scripts/boxing_classifier_harness.py` now rebuilds `split_counts`, `sample_kind_counts`, `negative_context_counts`, and `alignment_summary` for derived masked datasets, and `scripts/export_boxing_punch_classifier_dataset.py` no longer backfills those fields from the source export when writing derived artifacts.

Refreshed both checked-in masked benchmark variants under `docs/baselines/boxing-punch-classifier-family-masked-topology-benchmark-2026-06-18/` by rerunning export → MLP → CNN. Truthful derived counts now read `55 train / 25 test / 80 total` for `straight_family_mask_v1` and `61 train / 27 test / 88 total` for `hook_uppercut_family_mask_v1`, with derived sample-kind totals also updated (`8` straight annotated punches vs `16` hook/uppercut annotated punches, each plus `20` transition-before, `48` derived no-punch, `4` transition-after). Model metrics stayed unchanged from the prior benchmark conclusion: straight masked CNN remained `0.9600 / 0.8815`, hook/uppercut masked CNN remained `0.8148 / 0.1796`, and the masked topology still did not beat the shared-vector subset baselines. With the artifact metadata now truthful, QA’s reproduced rerun should be ready to hand back to audit.

---

### Task 10: Implement reduced straight-family minimal-variable benchmark variants

**Bead ID:** `aerobeat-input-camera-tracking-ijg3`  
**SubAgent:** `primary` (for `coder`)  
**Role:** `coder`  
**References:** `REF-03`, `REF-04`, `REF-05`, `REF-06`  
**Prompt:** Implement the next straight-family diagnosis benchmark as two narrow masked-family variants inside the existing harness/export flow. Variant A: remove `elbow_shoulder_xy_distance_over_shoulder_width` from the shared baseline pool, add it only to the straight-family head, remove `elbow_x_from_shoulder_over_shoulder_width` and `elbow_y_from_shoulder_over_shoulder_width`, and keep `elbow_shoulder_radial_velocity_over_shoulder_width` for the straight-family head. Variant B: same straight-family target, but strip away the remaining baseline family values too so the straight head sees only the two specialized values `elbow_shoulder_xy_distance_over_shoulder_width` and `elbow_shoulder_radial_velocity_over_shoulder_width`. Re-run the benchmark fairly against the same straight-family subset baseline and keep the variable inventory explicit in the artifacts.

**Folders Created/Deleted/Modified:**
- masked-family benchmark artifact paths for new straight-minimal variants

**Files Created/Deleted/Modified:**
- `scripts/boxing_classifier_harness.py`
- `scripts/export_boxing_punch_classifier_dataset.py`
- refreshed/new benchmark artifacts under a new dated baseline folder as needed
- plan updates / notes as needed

**Status:** ✅ Complete

**Results:** Added two new harness-only masked straight-family profiles in `scripts/boxing_classifier_harness.py` and exposed them through `scripts/export_boxing_punch_classifier_dataset.py`: `straight_family_reduced_variant_a_v1` and `straight_family_reduced_variant_b_v1`. Variant A keeps the baseline coordinate/velocity context plus `elbow_shoulder_xy_distance_over_shoulder_width` and `elbow_shoulder_radial_velocity_over_shoulder_width`, while explicitly removing `elbow_x_from_shoulder_over_shoulder_width` and `elbow_y_from_shoulder_over_shoulder_width`. Variant B strips the straight head down to only `elbow_shoulder_xy_distance_over_shoulder_width` and `elbow_shoulder_radial_velocity_over_shoulder_width` per side.

Generated fresh artifacts under `docs/baselines/boxing-punch-classifier-family-masked-topology-straight-reduced-benchmark-2026-06-18/` with `export/`, `mlp/`, and `cnn/` outputs for both variants plus benchmark-level `summary.{json,md}`. The artifact metadata keeps the exact variable inventory explicit in each variant `export/export-summary.json` and in the benchmark summary.

Result: neither reduced straight-family variant beat the same projected straight-family subset of the shared-vector baseline CNN (`1.0000 accuracy / 1.0000 macro-F1` on 25 test windows). Variant A matched the earlier straight-mask result at `0.9600 accuracy / 0.8815 macro-F1` for both MLP and CNN, so removing the elbow x/y offset terms did not improve the benchmark. Variant B degraded materially: MLP fell to `0.8800 / 0.5333`, and CNN reached only `0.9200 / 0.5411`, indicating that reducing the straight head to only extension-distance plus radial-velocity cues removes too much useful context even inside the masked-family harness.

---

### Task 11: QA reduced straight-family minimal-variable benchmark variants

**Bead ID:** `aerobeat-input-camera-tracking-eytr`  
**SubAgent:** `primary` (for `qa`)  
**Role:** `qa`  
**References:** `REF-03`, `REF-04`, `REF-05`, `REF-06`  
**Prompt:** Verify the reduced straight-family minimal-variable benchmark variants are reproducible and compared fairly against the same straight-family subset baseline. Confirm that Variant A and Variant B use the intended variable inventories exactly, and summarize whether aggressively removing baseline/shared values improves or worsens straight-family performance.

**Folders Created/Deleted/Modified:**
- relevant repo paths used during QA
- `.temp/qa-straight-reduced-rerun-2026-06-18/`

**Files Created/Deleted/Modified:**
- `.temp/qa-straight-reduced-rerun-2026-06-18/**`
- plan updates only; no checked-in benchmark artifacts changed during QA

**Status:** ✅ Complete

**Results:** QA reran the two reduced straight-family minimal-variable variants from the checked-in `family_combined_directional_v1` source dataset into `.temp/qa-straight-reduced-rerun-2026-06-18/` using the repo’s current export → MLP → CNN flow. Reproduction was exact for both variants: rerun export summaries matched the committed `export/export-summary.json` inventories and counts, rerun MLP/CNN test metrics matched the committed `mlp/mlp-result.json` and `cnn/cnn-result.json`, and the rerun CNN `test_records` sample IDs matched both the checked-in variant artifacts and the benchmark-level `shared_vector_subset_baseline.records` used for comparison.

The subset-baseline comparison is fair. Both reduced variants were derived from the same checked-in `docs/baselines/boxing-punch-classifier-family-specific-feature-benchmark-2026-06-18/family_combined_directional_v1/export/dataset.json` source, both preserve the same straight-family reduced class order and 55 train / 25 test split, and the projected shared-vector subset baseline uses the exact same 25 test window IDs as the reduced-head reruns. Variable inventories are also exactly as intended: Variant A keeps the baseline coordinate/velocity context plus `elbow_shoulder_xy_distance_over_shoulder_width` and `elbow_shoulder_radial_velocity_over_shoulder_width` while excluding `elbow_x_from_shoulder_over_shoulder_width` and `elbow_y_from_shoulder_over_shoulder_width`; Variant B keeps only those two specialized elbow↔shoulder values per side.

Benchmark conclusion remains unchanged after QA: neither reduced straight-family variant beats the projected shared-vector straight-family subset baseline (`1.0000 accuracy / 1.0000 macro-F1` on 25 test windows). Variant A exactly reproduces `0.9600 accuracy / 0.8815 macro-F1` for both MLP and CNN, so removing the elbow x/y relative offsets did not help. Variant B reproduces the sharper degradation (`MLP 0.8800 / 0.5333`, `CNN 0.9200 / 0.5411`), confirming that stripping the straight head down to only the two specialized values removes too much useful context. QA passes and audit is ready.

---

### Task 12: Audit reduced straight-family minimal-variable benchmark conclusions

**Bead ID:** `aerobeat-input-camera-tracking-ozoo`  
**SubAgent:** `primary` (for `auditor`)  
**Role:** `auditor`  
**References:** `REF-03`, `REF-04`, `REF-05`, `REF-06`  
**Prompt:** Independently truth-check the reduced straight-family minimal-variable benchmark variants. Confirm whether shrinking the straight-family head toward only extension-style cues improves the straight-family subset benchmark enough to justify further specialization, or whether straight performance degrades once shared baseline context is removed. Keep the exact straight-family variable inventory explicit in the audit summary.

**Folders Created/Deleted/Modified:**
- relevant repo paths used during audit

**Files Created/Deleted/Modified:**
- audit notes/artifacts as needed

**Status:** ✅ Complete

**Results:** Audit passed. I independently truth-checked the checked-in reduced straight-family artifacts under `docs/baselines/boxing-punch-classifier-family-masked-topology-straight-reduced-benchmark-2026-06-18/` against the source shared-vector baseline artifact at `docs/baselines/boxing-punch-classifier-family-specific-feature-benchmark-2026-06-18/baseline_v1/cnn/cnn-result.json`. The benchmark-level `summary.{json,md}` is internally consistent with each variant’s `export/export-summary.json`, `mlp/mlp-result.json`, and `cnn/cnn-result.json`, and the projected `shared_vector_subset_baseline.records` match the exact same 25 test-window sample IDs used by both reduced straight-family variants.

Variant A inventory is explicit and truthful: per side it keeps `shoulder_x`, `shoulder_y`, `elbow_x`, `elbow_y`, `wrist_x`, `wrist_y`, `combined_elbow_wrist_velocity_xy_magnitude`, `elbow_shoulder_xy_distance_over_shoulder_width`, and `elbow_shoulder_radial_velocity_over_shoulder_width`, while masking `elbow_x_from_shoulder_over_shoulder_width`, `elbow_y_from_shoulder_over_shoulder_width`, and the full camera/body wrist-direction bundle. Variant B inventory is also explicit and truthful: per side it keeps only `elbow_shoulder_xy_distance_over_shoulder_width` and `elbow_shoulder_radial_velocity_over_shoulder_width`, while masking the baseline coordinate/velocity context, the elbow x/y offset pair, and the full wrist-direction bundle.

The truthful result matches QA’s read. Variant A reproduces the earlier straight masked result instead of improving it: both MLP and CNN remain `0.9600 accuracy / 0.8815 macro-F1`, still below the projected shared-vector straight-family subset baseline of `1.0000 / 1.0000` on the same 25 test windows. Variant B degrades materially: MLP falls to `0.8800 / 0.5333`, and CNN reaches only `0.9200 / 0.5411`. The CNN error pattern confirms the loss of useful context: Variant A makes one false positive no-punch→straight-left mistake, while Variant B adds a missed true straight-left plus a false positive no-punch→straight-right mistake. Final audit judgment: shrinking the straight-family head toward only extension-style cues does **not** help; removing too much shared baseline context makes the straight-family head weaker, not stronger. The next honest slice is to diagnose stronger discriminative cues for the weak non-straight families—especially hook/uppercut confusion—rather than further stripping straight-family inputs.

---

### Task 13: Research stronger hook/uppercut motion-shape feature candidates

**Bead ID:** `aerobeat-input-camera-tracking-yzoj`  
**SubAgent:** `primary` (for `research`)  
**Role:** `research`  
**References:** `REF-02`, `REF-03`, `REF-04`, `REF-05`, `REF-06`  
**Prompt:** Research the next honest hook/uppercut diagnosis slice. The current masked-family results suggest wrist-direction alone is too weak to separate hook vs uppercut cleanly. Review the current harness/export flow and propose stronger hook/uppercut motion-shape feature candidates that still fit this repo’s benchmark architecture. Prioritize features like forearm angle/orbit, wrist-vs-elbow path curvature, relative elbow-to-wrist trajectory, punch-plane/arc cues, or other compact motion-shape signals that could distinguish lateral sweep from upward drive better than wrist direction alone. Recommend the narrowest benchmark matrix to test first, keeping variable inventories explicit.

**Folders Created/Deleted/Modified:**
- relevant repo paths discovered during research

**Files Created/Deleted/Modified:**
- plan updates / notes / research artifacts as needed

**Status:** ✅ Complete

**Results:** Reviewed the current classifier harness/export flow plus the 2026-06-18 family-masked/family-specific benchmark artifacts. Confirmed that the current hook/uppercut masked head uses a 44-feature/frame dataset derived from `family_combined_directional_v1`, with active per-side features limited to the 8-feature baseline bundle plus camera/body wrist-direction bundles (`camera_wrist_*`, `body_wrist_*`). The current masked hook/uppercut head still misses both hook test positives in both model families, while the threshold baseline remains better on macro-F1, which supports the diagnosis that wrist-direction-only cues are too weak and that hook/uppercut work now needs stronger motion-shape variables rather than more straight-family pruning. Recommended the next benchmark seam as compact elbow-relative/forearm-shape features first: (1) a forearm-orbit bundle centered on wrist-vs-elbow geometry and tangential/radial motion, (2) a relative wrist-vs-elbow trajectory bundle, (3) a small punch-plane/arc bundle, and only then (4) curvature-style follow-ups if the simpler orbit features fail. Also documented the main harness constraints: new features must be added to the full export feature inventory before masking can reuse them, the exporter resamples to fixed 8-frame windows so short-horizon scalars are a better fit than long-sequence descriptors, and the current benchmark path still reuses the hardened capture-report package rather than the stricter frozen snapshot because of the known `straight_right` hash drift.

---

### Task 14: Implement hook/uppercut motion-shape benchmark variants

**Bead ID:** `aerobeat-input-camera-tracking-qx6i`  
**SubAgent:** `primary` (for `coder`)  
**Role:** `coder`  
**References:** `REF-03`, `REF-04`, `REF-05`, `REF-06`  
**Prompt:** Implement the agreed hook/uppercut motion-shape benchmark variants from Task 13 inside the existing harness/export flow. Keep this harness-only, benchmark fairly against the same hook/uppercut subset baseline, and keep exact variable inventories explicit in the artifacts and summary.

**Folders Created/Deleted/Modified:**
- `docs/baselines/boxing-punch-classifier-family-masked-topology-hook-uppercut-motion-shape-benchmark-2026-06-18/`

**Files Created/Deleted/Modified:**
- `scripts/boxing_classifier_harness.py`
- `docs/baselines/boxing-punch-classifier-family-masked-topology-hook-uppercut-motion-shape-benchmark-2026-06-18/README.md`
- `docs/baselines/boxing-punch-classifier-family-masked-topology-hook-uppercut-motion-shape-benchmark-2026-06-18/summary.json`
- `docs/baselines/boxing-punch-classifier-family-masked-topology-hook-uppercut-motion-shape-benchmark-2026-06-18/summary.md`
- `docs/baselines/boxing-punch-classifier-family-masked-topology-hook-uppercut-motion-shape-benchmark-2026-06-18/family_combined_directional_hook_motion_shape_v1/export/**`
- `docs/baselines/boxing-punch-classifier-family-masked-topology-hook-uppercut-motion-shape-benchmark-2026-06-18/hook_uppercut_family_mask_v1/export/**`
- `docs/baselines/boxing-punch-classifier-family-masked-topology-hook-uppercut-motion-shape-benchmark-2026-06-18/hook_uppercut_family_mask_v1/mlp/**`
- `docs/baselines/boxing-punch-classifier-family-masked-topology-hook-uppercut-motion-shape-benchmark-2026-06-18/hook_uppercut_family_mask_v1/cnn/**`
- `docs/baselines/boxing-punch-classifier-family-masked-topology-hook-uppercut-motion-shape-benchmark-2026-06-18/hook_uppercut_motion_shape_variant_a_v1/export/**`
- `docs/baselines/boxing-punch-classifier-family-masked-topology-hook-uppercut-motion-shape-benchmark-2026-06-18/hook_uppercut_motion_shape_variant_a_v1/mlp/**`
- `docs/baselines/boxing-punch-classifier-family-masked-topology-hook-uppercut-motion-shape-benchmark-2026-06-18/hook_uppercut_motion_shape_variant_b_v1/export/**`
- `docs/baselines/boxing-punch-classifier-family-masked-topology-hook-uppercut-motion-shape-benchmark-2026-06-18/hook_uppercut_motion_shape_variant_b_v1/mlp/**`
- plan updates / notes as needed

**Status:** ✅ Complete

**Results:** Added a new full-export feature schema in `scripts/boxing_classifier_harness.py` for the narrow hook/uppercut motion-shape pass: `family_combined_directional_hook_motion_shape_v1` now extends the full per-side inventory with the agreed forearm-orbit bundle (`wrist_x_from_elbow_over_shoulder_width`, `wrist_y_from_elbow_over_shoulder_width`, `forearm_unit_x`, `forearm_unit_y`, `wrist_elbow_radial_velocity_over_shoulder_width`, `wrist_elbow_tangential_velocity_over_shoulder_width`) plus the relative elbow-to-wrist trajectory bundle (`wrist_minus_elbow_velocity_x_over_shoulder_width`, `wrist_minus_elbow_velocity_y_over_shoulder_width`, `body_wrist_minus_elbow_velocity_lateral_over_shoulder_width`, `body_wrist_minus_elbow_velocity_vertical_over_shoulder_width`). I also added two new masked hook/uppercut variants that reuse that full export inventory: `hook_uppercut_motion_shape_variant_a_v1` (control + forearm orbit) and `hook_uppercut_motion_shape_variant_b_v1` (Variant A + relative trajectory).

Generated a new artifact set at `docs/baselines/boxing-punch-classifier-family-masked-topology-hook-uppercut-motion-shape-benchmark-2026-06-18/` with the full source export, per-variant `export/` + `mlp/` artifacts for all three variants, control-only `cnn/` artifacts, and benchmark-level `README.md` + `summary.{json,md}`. The top-level summary keeps the full source export inventory explicit and records each variant’s active/masked side-feature inventory.

Outcome: the new motion-shape cues did **not** produce a clear hook/uppercut win in this first narrow pass. Control reproduced the prior masked-head behavior (`MLP 0.8148 accuracy / 0.3159 macro-F1`, `CNN 0.8148 / 0.1796`) against the same projected shared-vector hook/uppercut subset baseline (`0.8519 / 0.1878`). Variant A improved MLP accuracy to `0.8519`, matching the projected shared-vector subset baseline on accuracy, but its macro-F1 fell to `0.1840`, slightly below the subset baseline and well below the control MLP’s `0.3159`. Variant B regressed more sharply to `0.7407 / 0.1739`. Following the agreed narrow matrix, I ran CNN only for the control: no new motion-shape MLP variant improved macro-F1 over the control MLP, so the CNN gate stayed closed for Variants A/B. The honest read stays narrow: these compact forearm-orbit and elbow-relative trajectory cues were reusable and benchmarkable, but they did not yet beat the same hook/uppercut subset baseline or the existing masked control on the metric that matters for class separation.

---

### Task 15: QA hook/uppercut motion-shape benchmark variants

**Bead ID:** `aerobeat-input-camera-tracking-m9p2`  
**SubAgent:** `primary` (for `qa`)  
**Role:** `qa`  
**References:** `REF-03`, `REF-04`, `REF-05`, `REF-06`  
**Prompt:** Verify the hook/uppercut motion-shape benchmark variants are reproducible and compared fairly against the same hook/uppercut subset baseline. Confirm exact variable inventories and summarize whether the new motion-shape cues improve hook/uppercut separation.

**Folders Created/Deleted/Modified:**
- `.temp/qa-hook-uppercut-motion-shape-rerun-2026-06-18/`

**Files Created/Deleted/Modified:**
- `.plans/2026-06-18-learned-classifier-family-specific-feature-branch.md`

**Status:** ✅ Complete

**Results:** Re-ran the agreed narrow matrix from scratch into `.temp/qa-hook-uppercut-motion-shape-rerun-2026-06-18/`: full source export via `scripts/export_boxing_punch_classifier_dataset.py --manifest .testbed/assets/benchmarks/boxing_punch_classifier_v1.benchmark.json --captures-dir .temp/boxing-punch-classifier-export/hardened-captures-2026-06-16 --feature-set family_combined_directional_hook_motion_shape_v1 --skip-captures`, derived all three masked variants from that source dataset, re-trained MLPs for control/Variant A/Variant B, and re-ran the control CNN only. The rerun reproduced the checked-in metrics exactly: control MLP `0.8148148148148148 / 0.3159420289855072`, control CNN `0.8148148148148148 / 0.1795918367346939`, Variant A MLP `0.8518518518518519 / 0.184`, Variant B MLP `0.7407407407407407 / 0.17391304347826086`.

QA also confirmed the comparison is fair: the control/Variant A/Variant B exports use the exact same 27 held-out test sample IDs in the same order, and that list exactly matches the `baseline_v1` family-specific benchmark test split after dropping the two held-out straight positives. Re-projecting `docs/baselines/boxing-punch-classifier-family-specific-feature-benchmark-2026-06-18/baseline_v1/cnn/cnn-result.json` onto the same five-class hook/uppercut/no-punch subset reproduced the documented shared-vector subset baseline `0.8518518518518519 accuracy / 0.1877551020408163 macro-F1`, so the subset-baseline comparison is honest.

Variable inventories also matched the intended design exactly. Control keeps only baseline + camera/body wrist-direction features (22 per side / 44 frame features). Variant A adds only the forearm-orbit bundle (`wrist_x_from_elbow_over_shoulder_width`, `wrist_y_from_elbow_over_shoulder_width`, `forearm_unit_x`, `forearm_unit_y`, `wrist_elbow_radial_velocity_over_shoulder_width`, `wrist_elbow_tangential_velocity_over_shoulder_width`) for 28 per side / 56 frame features. Variant B adds only the relative elbow-to-wrist trajectory bundle on top of Variant A (`wrist_minus_elbow_velocity_x_over_shoulder_width`, `wrist_minus_elbow_velocity_y_over_shoulder_width`, `body_wrist_minus_elbow_velocity_lateral_over_shoulder_width`, `body_wrist_minus_elbow_velocity_vertical_over_shoulder_width`) for 32 per side / 64 frame features.

The CNN gate was followed truthfully. Variant A was the best new MLP at macro-F1 `0.184`, which is still below the control MLP macro-F1 `0.3159420289855072`, so the agreed rule did not trigger a new-variant CNN run. No discrepancies found beyond the already-documented caveat that this benchmark still relies on the hardened capture-report package rather than a fully frozen snapshot because of known `straight_right` fixture-YAML hash drift. Audit is ready.

---

### Task 16: Audit hook/uppercut motion-shape benchmark conclusions

**Bead ID:** `aerobeat-input-camera-tracking-qd77`  
**SubAgent:** `primary` (for `auditor`)  
**Role:** `auditor`  
**References:** `REF-03`, `REF-04`, `REF-05`, `REF-06`  
**Prompt:** Independently truth-check the hook/uppercut motion-shape benchmark conclusions. Confirm whether the new cues actually improve hook/uppercut separation enough to justify further specialization or more data collection, and keep the exact variable inventories explicit in the audit summary.

**Folders Created/Deleted/Modified:**
- relevant repo paths used during audit

**Files Created/Deleted/Modified:**
- audit notes/artifacts as needed

**Status:** ✅ Complete

**Results:** Audit passed. I independently truth-checked the checked-in hook/uppercut motion-shape artifacts under `docs/baselines/boxing-punch-classifier-family-masked-topology-hook-uppercut-motion-shape-benchmark-2026-06-18/` against the source family benchmark baseline at `docs/baselines/boxing-punch-classifier-family-specific-feature-benchmark-2026-06-18/baseline_v1/cnn/cnn-result.json`. The benchmark-level `summary.{json,md}` is internally consistent with each variant’s `export/export-summary.json`, `mlp/mlp-result.json`, and the control `cnn/cnn-result.json`. All three variants report the same truthful reduced hook/uppercut dataset shape (`sample_count: 88`, `split_counts: {train: 61, test: 27}`, `label_counts: {hook_left: 4, hook_right: 4, uppercut_left: 4, uppercut_right: 4, no_punch: 72}`, `sample_kind_counts: {annotated_punch_window: 16, transition_before_punch: 20, derived_no_punch_window: 48, transition_after_punch: 4}`), and each variant’s projected shared-vector subset baseline uses the same 27 held-out hook/uppercut/no-punch sample IDs.

The exact variable inventories are explicit and truthful. Control `hook_uppercut_family_mask_v1` keeps 22 active per-side features: `shoulder_x`, `shoulder_y`, `elbow_x`, `elbow_y`, `wrist_x`, `wrist_y`, `combined_elbow_wrist_velocity_xy_magnitude`, `elbow_shoulder_xy_distance_over_shoulder_width`, `camera_wrist_signed_vx`, `camera_wrist_signed_vy`, `camera_wrist_direction_{none,up,down,left,right}`, `body_wrist_signed_vx`, `body_wrist_signed_vy`, and `body_wrist_direction_{none,up,down,left,right}`. Variant A `hook_uppercut_motion_shape_variant_a_v1` adds the 6-feature forearm-orbit bundle per side: `wrist_x_from_elbow_over_shoulder_width`, `wrist_y_from_elbow_over_shoulder_width`, `forearm_unit_x`, `forearm_unit_y`, `wrist_elbow_radial_velocity_over_shoulder_width`, and `wrist_elbow_tangential_velocity_over_shoulder_width` (28 active per-side features total). Variant B `hook_uppercut_motion_shape_variant_b_v1` keeps all of Variant A and additionally adds the 4-feature relative elbow↔wrist trajectory bundle per side: `wrist_minus_elbow_velocity_x_over_shoulder_width`, `wrist_minus_elbow_velocity_y_over_shoulder_width`, `body_wrist_minus_elbow_velocity_lateral_over_shoulder_width`, and `body_wrist_minus_elbow_velocity_vertical_over_shoulder_width` (32 active per-side features total).

The benchmark conclusion holds. The projected shared-vector subset baseline stays `0.8518518518518519 accuracy / 0.1877551020408163 macro-F1` on the same 27 test windows. Control MLP is the best of the masked/motion-shape MLPs at `0.8148148148148148 / 0.3159420289855072`, while control CNN remains `0.8148148148148148 / 0.1795918367346939`. Variant A MLP matches the subset baseline on accuracy at `0.8518518518518519` but drops macro-F1 to `0.184`, because it collapses to predicting all 27 test windows as `no_punch`. Variant B regresses further to `0.7407407407407407 / 0.17391304347826086`. The CNN gate was handled truthfully: because neither new MLP variant beat the control MLP on macro-F1, no new-variant CNN run was warranted.

Final audit judgment: this first hook/uppercut motion-shape hypothesis was benchmarkable and clean, but it did not improve hook/uppercut separation enough to justify runtime specialization yet. The control MLP remaining best suggests the added motion-shape cues are not useless, but in their current form they are still weakly shaped and/or redundant with existing context rather than strongly discriminative for hook vs uppercut. The most important follow-up is diagnosis-first feature design: inspect the hook/uppercut misses and engineer a stronger next cue family (for example forearm angle/orbit phase, elbow-leading vs wrist-leading timing, or path-curvature / punch-plane features) before spending effort on broader staged routing or data expansion.

---

### Task 17: Rerun benchmark/export conclusions against retimed punch YAML truth windows

**Bead ID:** `aerobeat-input-camera-tracking-vf1s`  
**SubAgent:** `primary` (for `coder`)  
**Role:** `coder`  
**References:** `REF-03`, `REF-04`, `REF-05`, `REF-06`  
**Prompt:** Derrick retimed the punch fixture YAMLs so the punch-class windows now cover windup + punch and try to cut off before the recovery/return phase. Sync the latest repo state, verify the changed punch fixture YAMLs are the active truth inputs, then rerun the relevant learned-classifier export/benchmark slice(s) against this updated truth basis before drawing further conclusions about hook/uppercut or straight-family feature design. Keep the exact changed fixture paths and resulting sample-count/window-count deltas explicit in the artifacts and report.

**Folders Created/Deleted/Modified:**
- punch fixture YAML paths under `.testbed/assets/fixtures/boxing/`
- refreshed benchmark artifact paths as needed

**Files Created/Deleted/Modified:**
- changed punch fixture YAMLs pulled from `main`
- refreshed benchmark artifacts / summaries as needed
- plan updates / notes as needed

**Status:** ✅ Complete

**Results:** Verified the retimed punch fixtures from `3093907` are present locally and active via `.testbed/assets/benchmarks/boxing_punch_classifier_v1.benchmark.json`, which still points at the live boxing fixture YAMLs under `.testbed/assets/fixtures/boxing/`. The changed punch truth windows are now: `straight_left` take_01 `1150-1300/2150-2650/3333-3833/4833-5088 → 900-1200/1900-2400/3150-3650/4600-4900`, `straight_right` `625-825/1700-2000/3100-3400/5200-5450 → 50-400/1700-2000/2650-3150/4150-4400`, `hook_left` `1200-1450/2500-3000/4000-4600/5075-5225 → 900-1450/2800-3000/4000-4583/5583-6000`, `hook_right` `900-1400/2400-2900/4000-4500/5730-5860 → 900-1400/2600-2900/4000-4400/5700-5900`, `uppercut_left` `900-1200/2900-3200/4600-5400/6000-7000 → 650-1200/2650-3200/4600-5150/6000-7000`, and `uppercut_right` `900-1150/2000-3000/3900-4650/5175-5350 → 900-1150/2650-3100/3900-4650/5680-6250`. Guard windows were unchanged and were not used as positive truth.

Reran the narrowest honest learned-classifier slice that still covers the current conclusions: (1) the full `family_combined_directional_v1` export → MLP → CNN under `docs/baselines/boxing-punch-classifier-family-specific-feature-benchmark-2026-06-18/family_combined_directional_v1/`, then (2) the two family-masked heads derived from that refreshed source dataset under `docs/baselines/boxing-punch-classifier-family-masked-topology-benchmark-2026-06-18/{straight_family_mask_v1,hook_uppercut_family_mask_v1}/`, each with export → MLP → CNN rerun plus benchmark-level `summary.{json,md}` refresh. I did **not** rerun the older full branch matrix because the current decision seam is whether the refreshed family-specific source + family-masked heads change the straight-vs-hook/uppercut diagnosis; rerunning unrelated earlier variants would be redundant for that question.

Truth-window/sample-count outcome: total dataset counts did **not** change. The refreshed full export stayed at `sample_count 96`, `split_counts {train:67,test:29}`, `sample_kind_counts {annotated_punch_window:24, transition_before_punch:20, derived_no_punch_window:48, transition_after_punch:4}`, `label_counts {6 punch labels x4 each, no_punch:72}`. The masked exports also held constant: straight head `80` samples with `8 annotated punch / 72 no_punch`, hook/uppercut head `88` samples with `16 annotated punch / 72 no_punch`. What *did* change was which held-out windows landed in those buckets after the truth shift: e.g. the full-test no-punch/transition IDs changed from `hook_left::no_punch::017`, `hook_right::no_punch::014`, `straight_left::transition_before::{03,04}`, `straight_right::no_punch::018`, `uppercut_right::no_punch::012` to `hook_left::no_punch::019`, `hook_right::no_punch::016`, `straight_left::no_punch::009`, `straight_right::no_punch::011`, `uppercut_right::no_punch::014` while preserving the same bucket totals.

Metric movement was material. On the refreshed full family-specific source, `family_combined_directional_v1` moved from `MLP 0.7931 / 0.3631` to `0.8276 / 0.7215` and from `CNN 0.8276 / 0.2717` to `0.6897 / 0.3550` (accuracy / macro-F1). The MLP now correctly recovers `hook_left`, `hook_right`, and `uppercut_right`; the CNN now recovers both hook positives but still drops `straight_right` to `no_punch` and sends `straight_left` to `hook_right`. On the refreshed masked straight head, both MLP and CNN landed at `0.8800 / 0.6990`, versus the prior `0.9200 / 0.7626` MLP and `0.9600 / 0.8815` CNN. On the refreshed masked hook/uppercut head, the MLP moved from `0.8148 / 0.3159` to `0.7037 / 0.3792`, while the CNN improved from `0.8148 / 0.1796` to `0.8519 / 0.5159`. I also refreshed the masked benchmark subset baselines so they now project from the refreshed `family_combined_directional_v1` CNN rather than the stale pre-retime baseline: straight subset baseline is now `0.7600 / 0.2879`, hook/uppercut subset baseline `0.8889 / 0.5872`. Under that fairer comparison, the masked straight head now **beats** the shared-vector subset baseline by `+0.1200` accuracy and about `+0.4111` macro-F1, while the masked hook/uppercut CNN still trails the shared-vector subset baseline by `-0.0370` accuracy / `-0.0713` macro-F1.

Diagnosis shift: the retimed truth windows did **not** change total sample counts, but they *did* materially change the qualitative read. The refreshed full shared-vector `family_combined_directional_v1` models now recover hook positives much better than before, especially in the MLP, while the straight-family masked head remains the clearest beneficiary of isolation: on the retimed truth it now cleanly beats the refreshed shared-vector subset baseline. The hook/uppercut masked head improved in absolute CNN macro-F1 versus its own pre-retime artifact (`0.1796 → 0.5159`), but once compared against the refreshed shared-vector hook/uppercut subset baseline it is still a net loss. So the honest updated read is narrower than the pre-retime story: the retimed truth windows weaken the old blanket “masking is not helping” diagnosis, but only the straight-family masked path currently shows a fair apples-to-apples subset-baseline win; hook/uppercut still needs stronger cues.

QA follow-up on the closed rerun bead confirmed the refreshed checked-in artifacts reproduce cleanly enough for audit. I reran the same slice into `.temp/qa-retimed-yaml-rerun-2026-06-18/` with the current repo state: `python3 scripts/export_boxing_punch_classifier_dataset.py --manifest .testbed/assets/benchmarks/boxing_punch_classifier_v1.benchmark.json --captures-dir .temp/boxing-punch-classifier-export/hardened-captures-2026-06-16 --feature-set family_combined_directional_v1 --skip-captures --output-dir .temp/qa-retimed-yaml-rerun-2026-06-18/family_combined_directional_v1/export`, then `python3 scripts/train_boxing_punch_mlp_baseline.py --dataset .temp/qa-retimed-yaml-rerun-2026-06-18/family_combined_directional_v1/export/dataset.json --output-dir .temp/qa-retimed-yaml-rerun-2026-06-18/family_combined_directional_v1/mlp`, then `python3 scripts/train_boxing_punch_temporal_cnn.py --dataset .temp/qa-retimed-yaml-rerun-2026-06-18/family_combined_directional_v1/export/dataset.json --mlp-result .temp/qa-retimed-yaml-rerun-2026-06-18/family_combined_directional_v1/mlp/mlp-result.json --output-dir .temp/qa-retimed-yaml-rerun-2026-06-18/family_combined_directional_v1/cnn`, followed by the same export→MLP→CNN derivation for `straight_family_mask_v1` and `hook_uppercut_family_mask_v1` from that rerun source dataset. The rerun matched the checked-in test records exactly for the full family MLP/CNN plus both masked CNNs; JSON diffs are limited to expected non-semantic fields like timestamps/absolute output paths. The refreshed subset-baseline comparisons are fair: both masked heads derive from the same rerun `family_combined_directional_v1` source dataset, preserve the same held-out IDs as the checked-in artifacts (`25` straight test windows, `27` hook/uppercut test windows), and the benchmark summary’s projected subset baselines recompute exactly (`straight 0.7600 / 0.2879`, `hook/uppercut 0.8889 / 0.5872`). QA judgment: the straight-family masking win over the refreshed straight subset baseline is real (`0.8800 / 0.6990` vs `0.7600 / 0.2879`), the hook/uppercut masking loss relative to its refreshed subset baseline is also real (`0.8519 / 0.5159` vs `0.8889 / 0.5872`), and audit is ready. The retimed truth windows materially weaken prior blanket conclusions drawn from the pre-retime branch—especially any statement that family masking broadly failed or that hook-family recovery remained uniformly poor—while leaving the narrower hook/uppercut-specific “current cues still trail the fair subset baseline” conclusion intact.

---

### Task 18: Audit retimed-YAML rerun conclusions and refresh the branch judgment

**Bead ID:** `aerobeat-input-camera-tracking-vf1s`  
**SubAgent:** `primary` (for `auditor`)  
**Role:** `auditor`  
**References:** `REF-03`, `REF-04`, `REF-05`, `REF-06`  
**Prompt:** Independently truth-check the refreshed family-specific source benchmark plus the retimed-truth straight and hook/uppercut masked heads. Confirm which pre-retime conclusions are still trustworthy, which ones are invalidated or weakened by the retimed truth windows, and whether the straight-family masked result should now be treated as a real win on the fair refreshed subset comparison.

**Folders Created/Deleted/Modified:**
- relevant repo paths used during audit

**Files Created/Deleted/Modified:**
- `.plans/2026-06-18-learned-classifier-family-specific-feature-branch.md`

**Status:** ✅ Complete

**Results:** Audit passed. I independently truth-checked the checked-in retimed rerun artifacts from commit `05606b0` against the refreshed family-specific source benchmark and the refreshed masked benchmark summary. `docs/baselines/boxing-punch-classifier-family-specific-feature-benchmark-2026-06-18/family_combined_directional_v1/{export,mlp,cnn}` is internally consistent with the top-level family benchmark summary, and `docs/baselines/boxing-punch-classifier-family-masked-topology-benchmark-2026-06-18/summary.{json,md}` is internally consistent with each masked variant’s `export/export-summary.json`, `mlp/mlp-result.json`, and `cnn/cnn-result.json`.

The refreshed subset-baseline comparisons are fair and exact. For both masked heads, the benchmark summary’s `shared_vector_subset_baseline.records` match the exact masked-head CNN `test_records` sample IDs (`25` straight windows and `27` hook/uppercut windows respectively). The checked-in metrics reproduce the QA judgment exactly: refreshed full shared-vector `family_combined_directional_v1` is `MLP 0.8276 / 0.7215`, `CNN 0.6897 / 0.3550`; refreshed straight masked head is `MLP 0.8800 / 0.6990`, `CNN 0.8800 / 0.6990` against a refreshed straight subset baseline of `0.7600 / 0.2879`; refreshed hook/uppercut masked head is `MLP 0.7037 / 0.3792`, `CNN 0.8519 / 0.5159` against a refreshed hook/uppercut subset baseline of `0.8889 / 0.5872`.

Updated audit judgment: the old blanket conclusion that “family masking is not helping” is no longer trustworthy after the retimed truth shift. Straight-family masking should now be treated as a real apples-to-apples win on the refreshed fair subset comparison, because it beats the refreshed shared-vector subset baseline by `+0.1200` accuracy and `+0.4111` macro-F1. However, the hook/uppercut branch is still the weak branch even after retiming: its masked CNN improved materially in absolute terms versus the pre-retime artifact, but it still loses the fair subset comparison by `-0.0370` accuracy and `-0.0713` macro-F1. The pre-retime story that hook-family recovery was uniformly poor is also weakened, because the refreshed full-source MLP/CNN recover hook positives better than before; the narrower conclusion that current hook/uppercut-specific cues still trail the fair subset baseline remains trustworthy. Recommended next slice: before inventing brand-new hook/uppercut features, re-evaluate the older hook/uppercut-focused experiment artifacts and conclusions against the retimed truth basis so Derrick can separate “truth-window artifact” from “feature weakness,” then resume diagnosis on the still-losing hook/uppercut branch.

---

### Task 19: Research which prior hook/uppercut experiments must be re-evaluated under retimed punch truth

**Bead ID:** `aerobeat-input-camera-tracking-pa7m`  
**SubAgent:** `primary` (for `research`)  
**Role:** `research`  
**References:** `REF-03`, `REF-04`, `REF-05`, `REF-06`  
**Prompt:** Now that retimed punch YAML windows materially changed the learned-classifier conclusions, identify which prior hook/uppercut-focused experiment branches are most decision-relevant to rerun under the new truth basis before inventing more hook/uppercut features. Be pragmatic: rank the old experiments by how likely their conclusions were distorted by recovery-inclusive timing windows, and recommend the narrowest rerun set that will tell Derrick which old hook/uppercut conclusions survive retimed truth.

**Folders Created/Deleted/Modified:**
- relevant benchmark artifact paths / plans discovered during review

**Files Created/Deleted/Modified:**
- plan updates / research notes as needed

**Status:** ✅ Complete

**Results:** Reviewed the branch’s prior hook/uppercut-focused paths against the post-retime findings from Tasks 17–18. The key split is: some old conclusions are already re-evaluated under retimed truth, while others still exist only on the old recovery-inclusive timing basis. `family_combined_directional_v1` and the masked hook/uppercut control head `hook_uppercut_family_mask_v1` already have refreshed retimed-truth evidence, so they should not be rerun again as standalone tasks. The unresolved pre-retime-only conclusions are the older camera-vs-body family directional ablations and the hook/uppercut motion-shape variants.

Ranked rerun value:
1. `hook_uppercut_motion_shape_variant_a_v1` — highest-value old rerun. It was the strongest hook/uppercut-specific new-feature pass we tried (`0.8519` accuracy, `0.1840` macro-F1 on the old truth basis), and its forearm-orbit / tangential-motion cues are exactly the kind most likely to have been distorted by recovery-inclusive windows. If this variant improves materially under retimed truth, then part of the old “motion-shape still weak” conclusion was timing-noise, not just bad features.
2. `family_camera_directional_v1` — next most decision-relevant. The retimed truth already improved hook recovery inside `family_combined_directional_v1`, so this rerun would tell us whether camera-space wrist direction alone was unfairly penalized by the old recovery tail or whether it still collapses to `no_punch` under cleaner timing.
3. `family_body_directional_v1` — worth rerunning only after camera-space if Derrick wants to settle the camera-vs-body interpretation question before any new feature work. It tests the athlete-space sign hypothesis directly, but it is less likely than Variant A or camera-only to change the next coding decision.
4. `hook_uppercut_motion_shape_variant_b_v1` — lowest value / redundant for the first pass. It was already strictly worse than Variant A on the old truth basis, adds more elbow↔wrist trajectory features on top of Variant A, and is unlikely to reverse the story if Variant A still loses under retimed truth.

Skip as low-value or already answered for now:
- `hook_uppercut_family_mask_v1` as a standalone rerun, because Task 17 already refreshed it under retimed truth and Task 18 already audited the fair subset-baseline loss.
- `family_combined_directional_v1` as a standalone rerun, because Task 17 already refreshed it and showed hook recovery improved materially under retimed truth.
- Straight-only diagnosis variants (`straight_family_mask_v1`, straight reduced variants) because they do not answer the hook/uppercut question Derrick wants resolved before more feature invention.
- `hook_uppercut_motion_shape_variant_b_v1` in the first slice unless Variant A unexpectedly turns into a clear win.

Recommended narrowest first rerun set: rerun the old hook/uppercut motion-shape benchmark on retimed truth, but only the minimum honest subset: source export `family_combined_directional_hook_motion_shape_v1`, derived control `hook_uppercut_family_mask_v1`, and `hook_uppercut_motion_shape_variant_a_v1`. Keep the original CNN gate: only run a new CNN for Variant A if its retimed-truth MLP macro-F1 beats the retimed control MLP. This smallest set tells us whether the strongest old hook/uppercut-specific feature pass survives, weakens, or reverses under the new truth basis without spending time on the already-worse Variant B.

Why this is the right next step: it isolates the one old hook/uppercut experiment that was both closest to promising and most timing-sensitive, while reusing the already-established retimed control story instead of re-litigating straight-family wins or already-rerun masked control conclusions. If Variant A still loses cleanly, we can keep the current diagnosis that hook/uppercut needs genuinely stronger cues. If Variant A improves enough to beat the retimed control or fair subset baseline, then the old negative motion-shape read was partially a truth-window artifact and should be weakened before inventing a new cue family.

Coder readiness: yes. Task 20 is ready next with a narrow brief: retime/rerun the motion-shape benchmark’s control + Variant A only, compare against the fair retimed hook/uppercut subset baseline, and only expand to Variant B if Variant A produces an unexpected positive signal that changes the decision surface.

---

### Task 20: Rerun highest-value prior hook/uppercut experiments under retimed punch truth

**Bead ID:** `aerobeat-input-camera-tracking-f8nl`  
**SubAgent:** `primary` (for `coder`)  
**Role:** `coder`  
**References:** `REF-03`, `REF-04`, `REF-05`, `REF-06`  
**Prompt:** Rerun the highest-value prior hook/uppercut-focused learned-classifier experiment subset under the new retimed punch YAML truth, using the minimal set recommended by Task 19. Keep the comparison fair and explicit about which old conclusions survive, weaken, or reverse under the retimed windows.

**Folders Created/Deleted/Modified:**
- `docs/baselines/boxing-punch-classifier-family-masked-topology-hook-uppercut-motion-shape-benchmark-2026-06-18/`

**Files Created/Deleted/Modified:**
- `docs/baselines/boxing-punch-classifier-family-masked-topology-hook-uppercut-motion-shape-benchmark-2026-06-18/family_combined_directional_hook_motion_shape_v1/export/dataset.json`
- `docs/baselines/boxing-punch-classifier-family-masked-topology-hook-uppercut-motion-shape-benchmark-2026-06-18/family_combined_directional_hook_motion_shape_v1/export/export-summary.json`
- `docs/baselines/boxing-punch-classifier-family-masked-topology-hook-uppercut-motion-shape-benchmark-2026-06-18/family_combined_directional_hook_motion_shape_v1/export/export-summary.md`
- `docs/baselines/boxing-punch-classifier-family-masked-topology-hook-uppercut-motion-shape-benchmark-2026-06-18/family_combined_directional_hook_motion_shape_v1/export/threshold-baseline.json`
- `docs/baselines/boxing-punch-classifier-family-masked-topology-hook-uppercut-motion-shape-benchmark-2026-06-18/hook_uppercut_family_mask_v1/export/dataset.json`
- `docs/baselines/boxing-punch-classifier-family-masked-topology-hook-uppercut-motion-shape-benchmark-2026-06-18/hook_uppercut_family_mask_v1/export/export-summary.json`
- `docs/baselines/boxing-punch-classifier-family-masked-topology-hook-uppercut-motion-shape-benchmark-2026-06-18/hook_uppercut_family_mask_v1/export/export-summary.md`
- `docs/baselines/boxing-punch-classifier-family-masked-topology-hook-uppercut-motion-shape-benchmark-2026-06-18/hook_uppercut_family_mask_v1/export/threshold-baseline.json`
- `docs/baselines/boxing-punch-classifier-family-masked-topology-hook-uppercut-motion-shape-benchmark-2026-06-18/hook_uppercut_family_mask_v1/mlp/mlp-model.json`
- `docs/baselines/boxing-punch-classifier-family-masked-topology-hook-uppercut-motion-shape-benchmark-2026-06-18/hook_uppercut_family_mask_v1/mlp/mlp-result.json`
- `docs/baselines/boxing-punch-classifier-family-masked-topology-hook-uppercut-motion-shape-benchmark-2026-06-18/hook_uppercut_family_mask_v1/mlp/mlp-result.md`
- `docs/baselines/boxing-punch-classifier-family-masked-topology-hook-uppercut-motion-shape-benchmark-2026-06-18/hook_uppercut_family_mask_v1/cnn/cnn-model.json`
- `docs/baselines/boxing-punch-classifier-family-masked-topology-hook-uppercut-motion-shape-benchmark-2026-06-18/hook_uppercut_family_mask_v1/cnn/cnn-result.json`
- `docs/baselines/boxing-punch-classifier-family-masked-topology-hook-uppercut-motion-shape-benchmark-2026-06-18/hook_uppercut_family_mask_v1/cnn/cnn-result.md`
- `docs/baselines/boxing-punch-classifier-family-masked-topology-hook-uppercut-motion-shape-benchmark-2026-06-18/hook_uppercut_motion_shape_variant_a_v1/export/dataset.json`
- `docs/baselines/boxing-punch-classifier-family-masked-topology-hook-uppercut-motion-shape-benchmark-2026-06-18/hook_uppercut_motion_shape_variant_a_v1/export/export-summary.json`
- `docs/baselines/boxing-punch-classifier-family-masked-topology-hook-uppercut-motion-shape-benchmark-2026-06-18/hook_uppercut_motion_shape_variant_a_v1/export/export-summary.md`
- `docs/baselines/boxing-punch-classifier-family-masked-topology-hook-uppercut-motion-shape-benchmark-2026-06-18/hook_uppercut_motion_shape_variant_a_v1/export/threshold-baseline.json`
- `docs/baselines/boxing-punch-classifier-family-masked-topology-hook-uppercut-motion-shape-benchmark-2026-06-18/hook_uppercut_motion_shape_variant_a_v1/mlp/mlp-model.json`
- `docs/baselines/boxing-punch-classifier-family-masked-topology-hook-uppercut-motion-shape-benchmark-2026-06-18/hook_uppercut_motion_shape_variant_a_v1/mlp/mlp-result.json`
- `docs/baselines/boxing-punch-classifier-family-masked-topology-hook-uppercut-motion-shape-benchmark-2026-06-18/hook_uppercut_motion_shape_variant_a_v1/mlp/mlp-result.md`
- `docs/baselines/boxing-punch-classifier-family-masked-topology-hook-uppercut-motion-shape-benchmark-2026-06-18/hook_uppercut_motion_shape_variant_a_v1/cnn/cnn-model.json`
- `docs/baselines/boxing-punch-classifier-family-masked-topology-hook-uppercut-motion-shape-benchmark-2026-06-18/hook_uppercut_motion_shape_variant_a_v1/cnn/cnn-result.json`
- `docs/baselines/boxing-punch-classifier-family-masked-topology-hook-uppercut-motion-shape-benchmark-2026-06-18/hook_uppercut_motion_shape_variant_a_v1/cnn/cnn-result.md`
- `docs/baselines/boxing-punch-classifier-family-masked-topology-hook-uppercut-motion-shape-benchmark-2026-06-18/summary.json`
- `docs/baselines/boxing-punch-classifier-family-masked-topology-hook-uppercut-motion-shape-benchmark-2026-06-18/summary.md`
- `.plans/2026-06-18-learned-classifier-family-specific-feature-branch.md`

**Status:** ✅ Complete

**Results:** Reran exactly the narrow retimed-truth subset recommended by Task 19 and nothing broader: refreshed source export `family_combined_directional_hook_motion_shape_v1`, refreshed control `hook_uppercut_family_mask_v1`, refreshed `hook_uppercut_motion_shape_variant_a_v1`, then ran MLP for control + Variant A, ran the control CNN unconditionally, and ran the Variant A CNN only because the retimed Variant A MLP beat the retimed control MLP on macro-F1. `hook_uppercut_motion_shape_variant_b_v1` was intentionally not rerun in this slice.

Sample/window counts did **not** change versus the pre-retime motion-shape run. The source export stayed at `96` samples with `67 train / 29 test`; both the control and Variant A hook/uppercut masked datasets stayed at `88` samples with `61 train / 27 test`. The material change was the retimed punch-window truth itself and therefore which held-out windows / frame content landed in those fixed buckets, not the bucket totals.

The retimed control improved materially over its old pre-retime motion-shape result. Control MLP moved from `0.8148 accuracy / 0.3159 macro-F1` to `0.7037 / 0.3792` — a slight accuracy drop but a `+0.0632` macro-F1 gain. Control CNN improved much more sharply from `0.8148 / 0.1796` to `0.8519 / 0.5159`, which confirms the retimed truth windows materially changed the hook/uppercut story for the old control itself.

Variant A is where the old conclusion changed most. Pre-retime, Variant A MLP was `0.8519 / 0.1840` and lost badly enough on macro-F1 that the CNN gate stayed closed. Under retimed truth, Variant A MLP improved to `0.8148 / 0.4778`, beating the retimed control MLP by `+0.0986` macro-F1 and legitimately opening the old CNN gate. After running the now-allowed Variant A CNN, though, the broader decision still did **not** reverse: Variant A CNN landed at `0.8148 / 0.3121`, which is worse than the retimed control CNN `0.8519 / 0.5159` and still well below the fair retimed shared-vector hook/uppercut subset baseline `0.8889 / 0.5872`.

So the old negative motion-shape conclusion **weakens but does not reverse** under retimed truth. What no longer survives: the narrower pre-retime claim that no new motion-shape variant could beat the control MLP or justify a CNN run. What still survives: the current hook/uppercut motion-shape cue family is still not strong enough to beat the fair retimed hook/uppercut subset baseline or even the retimed control branch once the full gated comparison is run. QA is ready next on the refreshed checked-in artifacts.
---

### Task 21: QA retimed-truth re-evaluation of prior hook/uppercut experiments

**Bead ID:** `aerobeat-input-camera-tracking-qg1z`  
**SubAgent:** `primary` (for `qa`)  
**Role:** `qa`  
**References:** `REF-03`, `REF-04`, `REF-05`, `REF-06`  
**Prompt:** Verify the selected retimed-truth reruns of prior hook/uppercut experiments are reproducible and compared fairly. Confirm which old hook/uppercut conclusions remain valid versus which were artifacts of the old recovery-inclusive truth windows.

**Folders Created/Deleted/Modified:**
- `.temp/qa-retimed-hook-uppercut-motion-shape-rerun-2026-06-18/`
- `docs/baselines/boxing-punch-classifier-family-masked-topology-hook-uppercut-motion-shape-benchmark-2026-06-18/`

**Files Created/Deleted/Modified:**
- `.plans/2026-06-18-learned-classifier-family-specific-feature-branch.md`
- `.temp/qa-retimed-hook-uppercut-motion-shape-rerun-2026-06-18/family_combined_directional_hook_motion_shape_v1/{export,dataset,mlp,cnn}`
- `.temp/qa-retimed-hook-uppercut-motion-shape-rerun-2026-06-18/hook_uppercut_family_mask_v1/{export,dataset,mlp,cnn}`
- `.temp/qa-retimed-hook-uppercut-motion-shape-rerun-2026-06-18/hook_uppercut_motion_shape_variant_a_v1/{export,dataset,mlp,cnn}`

**Status:** ✅ Complete

**Results:** Re-ran the refreshed retimed-truth hook/uppercut motion-shape subset from scratch into `.temp/qa-retimed-hook-uppercut-motion-shape-rerun-2026-06-18/` using the live benchmark manifest and hardened capture package: (1) `python3 scripts/export_boxing_punch_classifier_dataset.py --manifest .testbed/assets/benchmarks/boxing_punch_classifier_v1.benchmark.json --captures-dir .temp/boxing-punch-classifier-export/hardened-captures-2026-06-16 --feature-set family_combined_directional_hook_motion_shape_v1 --skip-captures --output-dir .../family_combined_directional_hook_motion_shape_v1/export`, (2) `python3 scripts/train_boxing_punch_mlp_baseline.py --dataset .../family_combined_directional_hook_motion_shape_v1/export/dataset.json --output-dir .../family_combined_directional_hook_motion_shape_v1/mlp`, (3) `python3 scripts/train_boxing_punch_temporal_cnn.py --dataset .../family_combined_directional_hook_motion_shape_v1/export/dataset.json --mlp-result .../family_combined_directional_hook_motion_shape_v1/mlp/mlp-result.json --output-dir .../family_combined_directional_hook_motion_shape_v1/cnn`, then (4) derived `hook_uppercut_family_mask_v1` and `hook_uppercut_motion_shape_variant_a_v1` from that same source dataset with `scripts/export_boxing_punch_classifier_dataset.py --source-dataset ... --mask-profile <profile>`, followed by fresh MLP and CNN runs for each derived variant. The rerun reproduced the checked-in semantic outputs exactly for both selected retimed variants: control export `88 samples / 61 train / 27 test`, control MLP `0.7037 accuracy / 0.3792 macro-F1`, control CNN `0.8519 / 0.5159`; Variant A export `88 / 61 / 27`, Variant A MLP `0.8148 / 0.4778`, Variant A CNN `0.8148 / 0.3121`. Exact test-record sample IDs also matched between the rerun and the checked-in artifacts for control + Variant A; differences were limited to expected timestamp/output-path metadata.

The fair subset-baseline comparison remains truthful. For both selected variants, the benchmark summary’s projected shared-vector subset baseline uses the exact same 27 hook/uppercut/no-punch test sample IDs as the masked-head CNN test records, and the shared baseline still computes to `0.8889 accuracy / 0.5872 macro-F1` on that same held-out set. Under that apples-to-apples comparison, the conclusion shift is real but still not enough overall: Variant A genuinely improves relative to the retimed control at the MLP stage (`0.4778` vs `0.3792` macro-F1), which means the old pre-retime “gate stays closed” conclusion no longer survives, and the coder correctly opened the CNN gate for Variant A. But the broader branch judgment does not reverse after the gated CNN pass: Variant A CNN still loses to the retimed control CNN (`0.8148 / 0.3121` vs `0.8519 / 0.5159`) and both still trail the fair retimed shared-vector hook/uppercut subset baseline (`0.8889 / 0.5872`). QA therefore passes with one standing caveat already documented elsewhere in the branch: this benchmark still uses the hardened capture-report package rather than a fully frozen snapshot because of known `straight_right` fixture-YAML hash drift. Audit is ready.

---

### Task 22: Audit retimed-truth re-evaluation conclusions for hook/uppercut experiments

**Bead ID:** `aerobeat-input-camera-tracking-gnjw`  
**SubAgent:** `primary` (for `auditor`)  
**Role:** `auditor`  
**References:** `REF-03`, `REF-04`, `REF-05`, `REF-06`  
**Prompt:** Independently truth-check the retimed-truth reruns of prior hook/uppercut experiments and state which old conclusions should be kept, weakened, or discarded before any new hook/uppercut feature design work begins.

**Folders Created/Deleted/Modified:**
- relevant repo paths used during audit

**Files Created/Deleted/Modified:**
- audit notes/artifacts as needed

**Status:** ✅ Complete

**Results:** Audit passed. I independently truth-checked the checked-in retimed rerun artifacts from commit `d15e746` under `docs/baselines/boxing-punch-classifier-family-masked-topology-hook-uppercut-motion-shape-benchmark-2026-06-18/` against the underlying per-variant JSON artifacts and the refreshed shared-vector hook/uppercut subset baseline projected from `docs/baselines/boxing-punch-classifier-family-specific-feature-benchmark-2026-06-18/family_combined_directional_v1/cnn/cnn-result.json`. The benchmark-level `summary.{json,md}` is internally consistent with the source export plus the control/Variant A `export/export-summary.json`, `mlp/mlp-result.json`, and `cnn/cnn-result.json` files.

The refreshed retimed-truth comparison is fair and exact. Source export counts stayed `96 total / 67 train / 29 test`; both the control and Variant A hook/uppercut masked exports stayed `88 total / 61 train / 27 test`, with unchanged label/sample-kind totals and only the truth-timed window identities shifting. The projected shared-vector subset baseline still uses the exact same 27 held-out sample IDs as both retimed control and Variant A CNN test records, and it still computes to `0.8889 accuracy / 0.5872 macro-F1`.

QA’s key claims all hold under audit. Retimed control reproduces `MLP 0.7037 / 0.3792` and `CNN 0.8519 / 0.5159`. Retimed Variant A reproduces `MLP 0.8148 / 0.4778` and `CNN 0.8148 / 0.3121`. The old pre-retime claim that Variant A could not beat the control MLP or open the CNN gate is no longer trustworthy: under retimed truth, Variant A MLP really does beat the retimed control MLP on macro-F1 (`0.4778` vs `0.3792`), so the coder correctly ran the Variant A CNN. But the broader hook/uppercut branch judgment does **not** reverse: Variant A CNN still loses to the retimed control CNN (`0.8148 / 0.3121` vs `0.8519 / 0.5159`) and both still trail the fair retimed shared-vector subset baseline (`0.8889 / 0.5872`).

Final audit judgment: the old negative motion-shape conclusion is weakened but not reversed. Keep: current hook/uppercut-specific motion-shape cues still do not beat the fair retimed shared-vector hook/uppercut subset baseline, and Variant A is still only harness evidence rather than a runtime-promotion candidate. Discard/weaken: the pre-retime “gate stays closed / no variant beats control MLP” conclusion. No internal consistency discrepancies found beyond the already-documented branch caveat that these benchmarks still use the hardened capture-report package rather than a fully frozen snapshot because of known `straight_right` fixture-YAML hash drift. Recommended next step: do not promote hook/uppercut Variant A to runtime yet; use the updated retimed truth read to guide one more diagnosis-first benchmark slice for stronger hook/uppercut cues, while treating the separate straight-family masking win as the only part of this branch that is currently strong enough to inform any runtime-topology discussion.

---

### Task 23: Research the next stronger hook/uppercut cue-design benchmark after retimed Variant A

**Bead ID:** `aerobeat-input-camera-tracking-8260`  
**SubAgent:** `primary` (for `research`)  
**Role:** `research`  
**References:** `REF-03`, `REF-04`, `REF-05`, `REF-06`  
**Prompt:** Variant A became more promising under retimed punch truth, but it still lost at the final CNN and fair subset-baseline comparison. Research the next strongest hook/uppercut cue-design benchmark slice that is most likely to improve on retimed control and retimed Variant A. Prioritize compact signals around arc/phase/timing rather than generic extra width: forearm angle/orbit phase, elbow-leading vs wrist-leading timing, path curvature, punch-plane/arc cues, or similarly expressive motion-shape signals. Recommend the narrowest next matrix worth running and keep exact variable inventories explicit.

**Folders Created/Deleted/Modified:**
- relevant benchmark paths / notes discovered during research

**Files Created/Deleted/Modified:**
- plan updates / research notes as needed

**Status:** ✅ Complete

**Results:** Research completed against the retimed hook/uppercut control + Variant A artifacts. The key diagnostic read is now sharper: on the retimed fair hook/uppercut subset, the control CNN (`0.8519 / 0.5159`) and Variant A CNN (`0.8148 / 0.3121`) both still trail the shared-vector subset baseline (`0.8889 / 0.5872`), and both CNNs still miss both uppercut positives as `no_punch`. Variant A’s static forearm-orbit bundle *does* help at the MLP stage (`0.4778` macro-F1 vs control `0.3792`), but it does not survive the CNN gate; it also newly loses the held-out `hook_right` positive. That means the next honest cue-design slice should stop widening generic wrist-path geometry and instead add a compact phase/timing bundle that answers the unresolved question directly: is this motion an elbow-led upward drive or a wrist-led lateral sweep?

Ranked next cue bundles:
1. **Variant C: Variant A + compact orbit-phase / elbow-vs-wrist lead bundle** (best next slice). Add only per-side `forearm_angular_velocity_rad_per_s`, `body_wrist_minus_elbow_velocity_lateral_over_shoulder_width`, and `body_wrist_minus_elbow_velocity_vertical_over_shoulder_width` on top of the current Variant A inventory. Rationale: Variant A already supplies static forearm orientation + tangential/radial wrist motion around the elbow, but it does not expose *phase change* or whether the elbow or wrist is leading the action in the punch plane. Those three added signals are the narrowest expressive way to tell hook sweep from uppercut rise without repeating existing raw x/y trajectory width.
2. **Variant D: Variant C + elbow-arc / punch-plane cue** (runner-up only if Variant C shows a real MLP win). Add per-side `elbow_shoulder_tangential_velocity_over_shoulder_width` and `elbow_shoulder_vertical_velocity_over_shoulder_width`. Rationale: if Variant C still misses uppercuts as `no_punch`, the next likely missing signal is that uppercuts are elbow-led upward arcs while hooks keep stronger lateral elbow sweep. This is still compact, but it is a second step, not the first.
3. **Curvature-heavy follow-up** (do not run yet). Any bundle centered on second-derivative / multi-axis curvature terms should wait until the simpler phase/lead cues are tested; with only four positives per hook/uppercut class, higher-order curvature is more likely to amplify noise than resolve the current miss pattern.

Recommended narrowest next matrix:
- Keep the already-established retimed control `hook_uppercut_family_mask_v1` as the comparison baseline.
- Implement and run exactly **one** new benchmark variant first: `hook_uppercut_motion_shape_variant_c_v1 = Variant A + {forearm_angular_velocity_rad_per_s, body_wrist_minus_elbow_velocity_lateral_over_shoulder_width, body_wrist_minus_elbow_velocity_vertical_over_shoulder_width}`.
- Use the same gated policy as before: always run control CNN; run Variant C CNN only if Variant C MLP macro-F1 beats the retimed control MLP (`0.3792`) and ideally also beats retimed Variant A MLP (`0.4778`).
- Only if Variant C clears that gate and still misses the fair subset baseline should coder add Variant D as the sole expansion.

Exact variable inventories for the recommended next slice:
- **Retimed control active side features (22):** `shoulder_x`, `shoulder_y`, `elbow_x`, `elbow_y`, `wrist_x`, `wrist_y`, `combined_elbow_wrist_velocity_xy_magnitude`, `elbow_shoulder_xy_distance_over_shoulder_width`, `camera_wrist_signed_vx`, `camera_wrist_signed_vy`, `camera_wrist_direction_none`, `camera_wrist_direction_up`, `camera_wrist_direction_down`, `camera_wrist_direction_left`, `camera_wrist_direction_right`, `body_wrist_signed_vx`, `body_wrist_signed_vy`, `body_wrist_direction_none`, `body_wrist_direction_up`, `body_wrist_direction_down`, `body_wrist_direction_left`, `body_wrist_direction_right`.
- **Retimed Variant A incremental side features (6):** `wrist_x_from_elbow_over_shoulder_width`, `wrist_y_from_elbow_over_shoulder_width`, `forearm_unit_x`, `forearm_unit_y`, `wrist_elbow_radial_velocity_over_shoulder_width`, `wrist_elbow_tangential_velocity_over_shoulder_width`.
- **Recommended Variant C incremental side features (3 new only):** `forearm_angular_velocity_rad_per_s`, `body_wrist_minus_elbow_velocity_lateral_over_shoulder_width`, `body_wrist_minus_elbow_velocity_vertical_over_shoulder_width`.
- **Recommended Variant D incremental side features (2 add-on only, not first-pass):** `elbow_shoulder_tangential_velocity_over_shoulder_width`, `elbow_shoulder_vertical_velocity_over_shoulder_width`.

What to explicitly avoid because it is likely redundant/noisy:
- Do **not** add `forearm_angle` as a raw scalar if represented via `sin/cos`; current Variant A already carries the same static orientation information through `forearm_unit_x` and `forearm_unit_y`.
- Do **not** rerun Variant B as-is first; its extra raw relative x/y bundle widened the feature space without isolating the lead/phase question and already regressed pre-retime.
- Do **not** add camera-space and body-space duplicates of the same relative wrist↔elbow terms in the first pass; prefer the body-space lateral/vertical pair only.
- Do **not** jump to second-derivative curvature / acceleration bundles yet; they are the most likely to be unstable on this tiny hook/uppercut positive set.

Coder readiness: **yes**. The next coder brief is now narrow and explicit: add one new hook/uppercut benchmark variant centered on orbit-phase + elbow-vs-wrist lead timing, compare it against the retimed control and fair retimed hook/uppercut subset baseline, and only widen to the elbow-arc follow-up if that first compact bundle produces a real gated win.

---

### Task 24: Implement the next stronger hook/uppercut cue-design benchmark

**Bead ID:** `aerobeat-input-camera-tracking-g3wf`  
**SubAgent:** `primary` (for `coder`)  
**Role:** `coder`  
**References:** `REF-03`, `REF-04`, `REF-05`, `REF-06`  
**Prompt:** Implement the strongest next hook/uppercut cue-design benchmark recommended by Task 23, keeping scope narrow and benchmark-only. Compare fairly against retimed control and the retimed fair hook/uppercut subset baseline, and keep exact variable inventories explicit in the artifacts.

**Folders Created/Deleted/Modified:**
- refreshed hook/uppercut benchmark artifact paths for the next cue-design pass

**Files Created/Deleted/Modified:**
- harness/export files discovered in Task 23
- refreshed/new benchmark artifacts as needed
- plan updates / notes as needed

**Status:** ✅ Complete

**Results:** Added `forearm_angular_velocity_rad_per_s` to the full `family_combined_directional_hook_motion_shape_v1` source export, introduced the benchmark-only `hook_uppercut_motion_shape_variant_c_v1` mask profile, refreshed the source export from the current retimed benchmark manifest plus the frozen hardened capture reports (the older snapshot manifest now fails verification because the retimed fixture YAML hashes changed), reran the retimed control export/MLP/CNN, and ran the gated Variant C export/MLP/CNN. Exact active Variant C additions vs Variant A were kept explicit in the updated summary/artifacts: `forearm_angular_velocity_rad_per_s`, `body_wrist_minus_elbow_velocity_lateral_over_shoulder_width`, and `body_wrist_minus_elbow_velocity_vertical_over_shoulder_width`. Results: control MLP/CNN = `0.7037 / 0.3792` and `0.8519 / 0.5159`; Variant C MLP/CNN = `0.8148 / 0.4778` and `0.8519 / 0.5159`; fair retimed shared-vector hook/uppercut subset baseline remained `0.8889 / 0.5872`. Variant C beat the retimed control MLP gate but only tied the retimed Variant A MLP reference (`0.4778`), so the required Variant C CNN was run and it exactly matched the control CNN while still trailing the fair shared-vector subset baseline. Net: this weakens, rather than strengthens, the case that hook/uppercut-specific specialization is ready for runtime integration.

---

### Task 25: QA the next stronger hook/uppercut cue-design benchmark

**Bead ID:** `aerobeat-input-camera-tracking-s666`  
**SubAgent:** `primary` (for `qa`)  
**Role:** `qa`  
**References:** `REF-03`, `REF-04`, `REF-05`, `REF-06`  
**Prompt:** Verify the next hook/uppercut cue-design benchmark is reproducible and compared fairly against retimed control and the fair retimed hook/uppercut subset baseline. Confirm exact variable inventories and summarize whether the new cues finally improve hook/uppercut separation enough to matter.

**Folders Created/Deleted/Modified:**
- `.temp/qa-variant-c-rerun-2026-06-18/`
- relevant checked-in benchmark artifact paths under `docs/baselines/boxing-punch-classifier-family-masked-topology-hook-uppercut-motion-shape-benchmark-2026-06-18/`

**Files Created/Deleted/Modified:**
- `.plans/2026-06-18-learned-classifier-family-specific-feature-branch.md`
- `.temp/qa-variant-c-rerun-2026-06-18/family_combined_directional_hook_motion_shape_v1/{export,mlp,cnn}`
- `.temp/qa-variant-c-rerun-2026-06-18/hook_uppercut_family_mask_v1/{export,mlp,cnn}`
- `.temp/qa-variant-c-rerun-2026-06-18/hook_uppercut_motion_shape_variant_c_v1/{export,mlp,cnn}`

**Status:** ✅ Complete

**Results:** QA reran the narrow Variant C slice from scratch into `.temp/qa-variant-c-rerun-2026-06-18/` using the live retimed benchmark manifest plus the frozen hardened capture reports: `python3 scripts/export_boxing_punch_classifier_dataset.py --manifest .testbed/assets/benchmarks/boxing_punch_classifier_v1.benchmark.json --captures-dir .temp/boxing-punch-classifier-export/hardened-captures-2026-06-16 --feature-set family_combined_directional_hook_motion_shape_v1 --skip-captures --output-dir .../family_combined_directional_hook_motion_shape_v1/export`, then `python3 scripts/train_boxing_punch_mlp_baseline.py` and `python3 scripts/train_boxing_punch_temporal_cnn.py` for that source export, then derived `hook_uppercut_family_mask_v1` and `hook_uppercut_motion_shape_variant_c_v1` from the same source dataset with `scripts/export_boxing_punch_classifier_dataset.py --source-dataset ... --mask-profile <profile>` followed by fresh MLP/CNN runs for each. The rerun reproduced the checked-in semantic outputs exactly for control + Variant C: export counts/inventories matched, model class orders matched, test-record sample IDs matched, and metric values matched exactly (`control MLP 0.7037 / 0.3792`, `control CNN 0.8519 / 0.5159`, `Variant C MLP 0.8148 / 0.4778`, `Variant C CNN 0.8519 / 0.5159`).

QA also confirmed the fair subset-baseline comparison independently instead of trusting the summary. Re-projecting `docs/baselines/boxing-punch-classifier-family-specific-feature-benchmark-2026-06-18/family_combined_directional_v1/cnn/cnn-result.json` onto the exact same 27 held-out hook/uppercut/no-punch sample IDs used by the control/Variant C CNN test records reproduced the documented shared-vector subset baseline exactly: `0.8889 accuracy / 0.5872 macro-F1`. Variant C inventory is exactly as intended relative to Variant A: it keeps the Variant A control+orbit bundle and adds only `forearm_angular_velocity_rad_per_s`, `body_wrist_minus_elbow_velocity_lateral_over_shoulder_width`, and `body_wrist_minus_elbow_velocity_vertical_over_shoulder_width`, with no accidental removals. The gated MLP/CNN policy was followed correctly: Variant C really does beat the retimed control MLP gate (`0.4778 > 0.3792`), only ties the retimed Variant A MLP reference (`0.4778 == 0.4778`), and the resulting Variant C CNN exactly matches the retimed control CNN record-for-record while still trailing the fair shared-vector subset baseline. Standing caveat unchanged: this refresh still uses the hardened capture-report package rather than a fully frozen snapshot because the retimed fixture YAML hashes no longer verify against the older sealed snapshot manifest. QA passes and audit is ready.

---

### Task 26: Audit the next stronger hook/uppercut cue-design benchmark conclusions

**Bead ID:** `aerobeat-input-camera-tracking-1a4v`  
**SubAgent:** `primary` (for `auditor`)  
**Role:** `auditor`  
**References:** `REF-03`, `REF-04`, `REF-05`, `REF-06`  
**Prompt:** Independently truth-check the next hook/uppercut cue-design benchmark and state whether the new cues finally justify further specialization or still leave hook/uppercut as the weak branch. Keep exact variable inventories explicit in the audit summary.

**Folders Created/Deleted/Modified:**
- relevant repo paths used during audit

**Files Created/Deleted/Modified:**
- `.plans/2026-06-18-learned-classifier-family-specific-feature-branch.md`

**Status:** ✅ Complete

**Results:** Audit passed. I independently truth-checked commit `85d2d7b` and the checked-in Variant C artifacts under `docs/baselines/boxing-punch-classifier-family-masked-topology-hook-uppercut-motion-shape-benchmark-2026-06-18/` against the source family benchmark baseline at `docs/baselines/boxing-punch-classifier-family-specific-feature-benchmark-2026-06-18/family_combined_directional_v1/cnn/cnn-result.json`. The benchmark summary is internally consistent with each variant’s `export/export-summary.json`, `mlp/mlp-result.json`, and `cnn/cnn-result.json`.

The exact inventories and benchmark claims check out. Variant C is exactly Variant A plus the three approved per-side phase/lead cues: `forearm_angular_velocity_rad_per_s`, `body_wrist_minus_elbow_velocity_lateral_over_shoulder_width`, and `body_wrist_minus_elbow_velocity_vertical_over_shoulder_width` (62 total frame features vs Variant A’s 56). On the retimed hook/uppercut split, Variant C MLP exactly ties Variant A MLP at `0.8148 accuracy / 0.4778 macro-F1` and beats the retimed control MLP gate (`0.7037 / 0.3792`). Variant C CNN exactly matches the retimed control CNN record-for-record at `0.8519 / 0.5159`. The fair shared-vector hook/uppercut subset baseline remains stronger at `0.8889 / 0.5872` on the same 27 held-out sample IDs.

Final audit judgment: Variant C does not change the hook/uppercut story in any meaningful way beyond clearing the MLP gate back up to the old Variant A level. It does not create a new best result, does not move the CNN past control, and does not close the gap to the fair shared-vector subset baseline. That weakens rather than strengthens the case for a hook/uppercut-specific runtime branch: current specialization cues are still benchmark-only, still not runtime-ready, and still unproven relative to the shared-vector baseline. Best next step: stop widening the hook/uppercut feature bundle for now and instead do diagnosis-first error analysis on the still-losing uppercut misses / no-punch confusions before proposing another narrowly targeted cue family.

---

### Task 27: Research hook/uppercut miss patterns and propose one targeted cue family

**Bead ID:** `aerobeat-input-camera-tracking-5nx3`  
**SubAgent:** `primary` (for `research`)  
**Role:** `research`  
**References:** `REF-03`, `REF-04`, `REF-05`, `REF-06`  
**Prompt:** Stop broad hook/uppercut feature widening and do diagnosis-first analysis. Inspect the remaining hook/uppercut misses and no-punch confusions under the current retimed truth basis, identify the dominant failure pattern(s), and propose one narrowly targeted cue family that directly addresses those exact misses. Keep the recommendation compact and benchmark-friendly, with explicit variable inventory.

**Folders Created/Deleted/Modified:**
- relevant benchmark paths / notes discovered during miss analysis

**Files Created/Deleted/Modified:**
- plan updates / research notes as needed

**Status:** ✅ Complete

**Results:** Diagnosis-first review of the retimed hook/uppercut holdout confirms the remaining weakness is not broad hook confusion anymore; it is late-phase / compact uppercut windows collapsing into `no_punch`, with the final CNN misses concentrated on `uppercut_left_fixture::uppercut_left::04 -> no_punch` and `uppercut_right_fixture::uppercut_right::04 -> no_punch`, plus matching boundary false positives `hook_left_fixture::no_punch::019 -> hook_left` and `uppercut_left_fixture::transition_before::03 -> uppercut_left`. The strongest shared baseline still wins partly because the masked/specialized branch never learns a compact within-window phase cue for “uppercut still rising” versus “already-raised arm in adjacent no-punch context.”

I inspected the checked-in retimed QA / benchmark artifacts under `docs/baselines/boxing-punch-classifier-family-masked-topology-hook-uppercut-motion-shape-benchmark-2026-06-18/` and `.temp/qa-retimed-hook-uppercut-motion-shape-rerun-2026-06-18/`. The critical pattern is: left-side miss `uppercut_left::04` has a large wrist-from-elbow vertical excursion (`~1.71 shoulder-width units`) with matching elbow compaction/release inside the window, while the confusing `transition_before` / `no_punch` windows stay much flatter or rise without the same elbow-pocket change; right-side miss `uppercut_right::04` is subtler but still differs from `transition_after::04` mainly by a later in-window vertical peak and a small re-extension after compaction. That points to a narrow window-phase family rather than more raw per-frame velocity channels.

Recommended single next cue family: **uppercut pocket-exit phase cues** derived from existing relative wrist/elbow trajectories, added only per side. Exact variable inventory:
- `left_wrist_from_elbow_vertical_range_over_shoulder_width`
- `right_wrist_from_elbow_vertical_range_over_shoulder_width`
- `left_elbow_shoulder_distance_range_over_shoulder_width`
- `right_elbow_shoulder_distance_range_over_shoulder_width`
- `left_wrist_from_elbow_vertical_peak_phase`
- `right_wrist_from_elbow_vertical_peak_phase`

Narrowest next benchmark matrix: retimed fair hook/uppercut subset only, comparing (1) shared-vector retimed subset baseline, (2) current specialized control `hook_uppercut_family_mask_v1`, and (3) one new specialized variant = current best narrow specialized stack plus exactly the six pocket-exit phase variables above. Avoid broader width growth, duplicate restatements of signed velocity/direction, and generic acceleration / second-derivative additions; the misses point to missing within-window phase structure, not missing more instantaneous motion channels. Coder is ready.

---

### Task 28: Implement targeted hook/uppercut cue benchmark from miss analysis

**Bead ID:** `aerobeat-input-camera-tracking-6hxj`  
**SubAgent:** `primary` (for `coder`)  
**Role:** `coder`  
**References:** `REF-03`, `REF-04`, `REF-05`, `REF-06`  
**Prompt:** Implement the single targeted hook/uppercut cue family recommended by Task 27, keeping the benchmark narrow and directly tied to the diagnosed miss pattern. Compare fairly against retimed control and the fair retimed hook/uppercut subset baseline, with explicit variable inventories in the artifacts.

**Folders Created/Deleted/Modified:**
- refreshed hook/uppercut benchmark artifact paths for targeted cue pass

**Files Created/Deleted/Modified:**
- harness/export files discovered in Task 27
- refreshed/new benchmark artifacts as needed
- plan updates / notes as needed

**Status:** ✅ Complete

**Results:** Added a benchmark-only masked profile `hook_uppercut_pocket_exit_variant_v1` that keeps the current best narrow specialized stack and appends exactly six left/right pocket-exit cues via three new per-side derived variables: `wrist_from_elbow_vertical_range_over_shoulder_width`, `elbow_shoulder_distance_range_over_shoulder_width`, and `wrist_from_elbow_vertical_peak_phase` (materialized in frame inventories as left/right-prefixed variables). The rerun stayed narrow: fair shared-vector retimed subset baseline (reference only), rerun control `hook_uppercut_family_mask_v1` MLP/CNN, and rerun targeted variant MLP only. Actual result: the targeted MLP tied the retimed control exactly at **0.7037 accuracy / 0.3792 macro-F1**, so it did **not** beat the MLP gate and therefore no targeted CNN was run. The targeted pass also produced **zero** test prediction changes versus control, leaving the diagnosed failures unchanged (`uppercut_left_fixture::uppercut_left::04 -> no_punch`, `uppercut_right_fixture::uppercut_right::04 -> hook_left`). Artifacts were written under `docs/baselines/boxing-punch-classifier-family-masked-topology-hook-uppercut-pocket-exit-benchmark-2026-06-18/` with explicit inventories in `summary.md` / `summary.json`.

---

### Task 29: QA targeted hook/uppercut cue benchmark

**Bead ID:** `aerobeat-input-camera-tracking-nijd`  
**SubAgent:** `primary` (for `qa`)  
**Role:** `qa`  
**References:** `REF-03`, `REF-04`, `REF-05`, `REF-06`  
**Prompt:** Verify the targeted hook/uppercut cue benchmark is reproducible and compared fairly against retimed control and the fair retimed hook/uppercut subset baseline. Confirm exact variable inventory and summarize whether the targeted cue meaningfully improves the diagnosed failure mode.

**Folders Created/Deleted/Modified:**
- `.temp/qa-pocket-exit-rerun-2026-06-18/`
- relevant checked-in benchmark artifact paths under `docs/baselines/boxing-punch-classifier-family-masked-topology-hook-uppercut-pocket-exit-benchmark-2026-06-18/`

**Files Created/Deleted/Modified:**
- `.plans/2026-06-18-learned-classifier-family-specific-feature-branch.md`
- `.temp/qa-pocket-exit-rerun-2026-06-18/hook_uppercut_family_mask_v1/{export,mlp,cnn}`
- `.temp/qa-pocket-exit-rerun-2026-06-18/hook_uppercut_pocket_exit_variant_v1/{export,mlp}`

**Status:** ✅ Complete

**Results:** QA reran the narrow targeted pocket-exit slice from the checked-in retimed source dataset into `.temp/qa-pocket-exit-rerun-2026-06-18/`: `python3 scripts/export_boxing_punch_classifier_dataset.py --source-dataset docs/baselines/boxing-punch-classifier-family-masked-topology-hook-uppercut-motion-shape-benchmark-2026-06-18/family_combined_directional_hook_motion_shape_v1/export/dataset.json --mask-profile hook_uppercut_family_mask_v1 --output-dir .temp/qa-pocket-exit-rerun-2026-06-18/hook_uppercut_family_mask_v1/export`, `python3 scripts/train_boxing_punch_mlp_baseline.py --dataset .temp/qa-pocket-exit-rerun-2026-06-18/hook_uppercut_family_mask_v1/export/dataset.json --output-dir .temp/qa-pocket-exit-rerun-2026-06-18/hook_uppercut_family_mask_v1/mlp`, `python3 scripts/train_boxing_punch_temporal_cnn.py --dataset .temp/qa-pocket-exit-rerun-2026-06-18/hook_uppercut_family_mask_v1/export/dataset.json --mlp-result .temp/qa-pocket-exit-rerun-2026-06-18/hook_uppercut_family_mask_v1/mlp/mlp-result.json --output-dir .temp/qa-pocket-exit-rerun-2026-06-18/hook_uppercut_family_mask_v1/cnn`, then `python3 scripts/export_boxing_punch_classifier_dataset.py --source-dataset docs/baselines/boxing-punch-classifier-family-masked-topology-hook-uppercut-motion-shape-benchmark-2026-06-18/family_combined_directional_hook_motion_shape_v1/export/dataset.json --mask-profile hook_uppercut_pocket_exit_variant_v1 --output-dir .temp/qa-pocket-exit-rerun-2026-06-18/hook_uppercut_pocket_exit_variant_v1/export` and `python3 scripts/train_boxing_punch_mlp_baseline.py --dataset .temp/qa-pocket-exit-rerun-2026-06-18/hook_uppercut_pocket_exit_variant_v1/export/dataset.json --output-dir .temp/qa-pocket-exit-rerun-2026-06-18/hook_uppercut_pocket_exit_variant_v1/mlp`.

The rerun reproduced the checked-in semantic outputs exactly. Control export counts/inventories matched (`88` samples, `61 train / 27 test`), control MLP matched `0.7037 accuracy / 0.3792 macro-F1`, control CNN matched `0.8519 / 0.5159`, target export counts/inventories matched (`88 / 61 / 27`), and the target MLP matched `0.7037 / 0.3792`. Committed vs rerun `test_records` matched exactly for control MLP/CNN and target MLP, not just the headline metrics.

The exact targeted inventory is also truthful. Per side, `hook_uppercut_pocket_exit_variant_v1` keeps the retimed control bundle plus the prior Variant A/C motion-shape stack and adds only the three intended pocket-exit scalars: `wrist_from_elbow_vertical_range_over_shoulder_width`, `elbow_shoulder_distance_range_over_shoulder_width`, and `wrist_from_elbow_vertical_peak_phase` (materialized in the frame inventory as left/right-prefixed variables). No accidental feature drops or additions were found in the rerun export summaries.

The fair subset-baseline comparison remains truthful. The current control CNN uses the exact same 27 held-out hook/uppercut/no-punch sample IDs, in the same order, as the already-audited `shared_vector_subset_baseline.records` from `docs/baselines/boxing-punch-classifier-family-masked-topology-benchmark-2026-06-18/summary.json`, which still project to `0.8889 accuracy / 0.5872 macro-F1` from `docs/baselines/boxing-punch-classifier-family-specific-feature-benchmark-2026-06-18/family_combined_directional_v1/cnn/cnn-result.json`. So the comparison target did not drift between the retimed masked-control benchmark and this targeted rerun.

Gate behavior was followed correctly. The targeted MLP tied the retimed control MLP exactly at `0.7037 / 0.3792`, stayed below the retimed Variant A/C MLP reference `0.8148 / 0.4778`, and therefore did **not** earn a targeted CNN run. The diagnosed uppercut misses also remained unchanged: `uppercut_left_fixture::uppercut_left::04` stayed `uppercut_left -> no_punch`, `uppercut_right_fixture::uppercut_right::04` stayed `uppercut_right -> hook_left`, and the target MLP produced `0` test prediction changes versus the rerun control. QA passes and audit is ready.

---

### Task 30: Audit targeted hook/uppercut cue benchmark conclusions

**Bead ID:** `aerobeat-input-camera-tracking-ds8t`  
**SubAgent:** `primary` (for `auditor`)  
**Role:** `auditor`  
**References:** `REF-03`, `REF-04`, `REF-05`, `REF-06`  
**Prompt:** Independently truth-check the targeted hook/uppercut cue benchmark and state whether the new cue family improves the exact diagnosed misses enough to justify continuing specialization, or whether hook/uppercut still fails to beat the fair retimed subset baseline.

**Folders Created/Deleted/Modified:**
- relevant repo paths used during audit

**Files Created/Deleted/Modified:**
- audit notes/artifacts as needed

**Status:** ⏳ Pending

**Results:** Pending.

---

### Task 31: Research mixed per-family runtime topology for Godot proving

**Bead ID:** `aerobeat-input-camera-tracking-0r5q`  
**SubAgent:** `primary` (for `research`)  
**Role:** `research`  
**References:** `REF-02`, `REF-03`, `REF-05`, `REF-06`  
**Prompt:** Derrick wants to pause hook/uppercut feature tweaking and instead plan a mixed runtime path so Godot proving can use the best currently-supported classifier choice per punch family. Research the narrowest runtime topology change needed to let straights use the specialized learned winner while hook/uppercut stay on the best current path for now. Be explicit about whether this should be family-gated routing, multiple learned artifacts, hybrid learned+existing backend composition, or some simpler proving-only topology.

**Folders Created/Deleted/Modified:**
- relevant runtime / proving paths discovered during research

**Files Created/Deleted/Modified:**
- plan updates / research notes as needed

**Status:** ✅ Complete

**Results:** Research completed against the current runtime/proving code shape. Ranked topology options: **(1) recommended** proving-only mixed router inside `src/detectors/pose_detector_substrate.gd` that lets the learned classifier own only the straight family while existing threshold-gate runtime keeps hook/uppercut; **(2)** broader mixed router that supports per-family backend selection generically (straight/hook/uppercut each choose learned vs threshold/prototype) with config/debug plumbing for every family; **(3)** multi-artifact learned runtime (straight artifact + hook/uppercut artifact[s]) with one learned router owning multiple model loads; **(4)** learned-family gate followed by family-specialized learned heads. Option 1 is the smallest honest path because the current substrate already has separate straight/hook/uppercut threshold paths, the proving harness already exposes runtime backend overrides, and the current straight masked MLP artifact only needs one additional runtime feature (`elbow_shoulder_radial_velocity_over_shoulder_width`) beyond the feature names already resolved in `src/detectors/prototype_punch_matcher.gd`.

Key constraint discovered: the current learned runtime is **not** ready for the hook/uppercut specialized artifacts. `src/detectors/learned_punch_classifier.gd` can load alternate artifact paths, but it inherits feature extraction from `src/detectors/prototype_punch_matcher.gd`, whose resolver currently knows the baseline feature names plus some shoulder-relative offsets — not the hook/uppercut runtime-candidate names from the benchmark harness (for example `camera_wrist_signed_vx`, `body_wrist_signed_vx`, etc.). Unknown feature names currently fall back to `0.0`, so promoting the hook/uppercut specialized artifacts now would be misleading. By contrast, the straight masked winner at `docs/baselines/boxing-punch-classifier-family-masked-topology-benchmark-2026-06-18/straight_family_mask_v1/mlp/mlp-result.json` only adds one missing runtime feature on top of already-supported straight-side values, which makes it the only realistic near-term learned promotion.

Recommended narrow implementation path for Task 32: keep this **proving-only first**. Add a mixed punch-routing mode at the substrate/proving layer that (a) runs a straight-only learned classifier artifact for `straight_left`/`straight_right` → `punch_left`/`punch_right`, (b) keeps the current threshold-gate hook/uppercut runtime for `hook_*`/`uppercut_*`, and (c) surfaces explicit debug truth showing per-family routing plus the active learned model path. Likely files/components: `src/detectors/pose_detector_substrate.gd` for event routing + debug state, `src/detectors/learned_punch_classifier.gd` plus `src/detectors/prototype_punch_matcher.gd` for the one missing straight feature and straight-artifact loading, `assets/boxing.gesture_detection.yaml` and/or proving-only env override handling in `.testbed/scripts/proving_harness.gd`, and `.testbed/scripts/boxing_proving_harness.gd` so the proving UI/quick stats expose `routing_mode`, `straight_backend`, `hook_backend`, `uppercut_backend`, straight learned model path, and the fact that hook/uppercut still come from the existing backend. Coder readiness: **yes** — the next slice is narrow and implementable without claiming hook/uppercut learned specialization is runtime-ready yet.

---

### Task 32: Implement mixed per-family runtime punch-classifier path for Godot proving

**Bead ID:** `aerobeat-input-camera-tracking-zc8x`  
**SubAgent:** `primary` (for `coder`)  
**Role:** `coder`  
**References:** `REF-02`, `REF-03`, `REF-05`, `REF-06`  
**Prompt:** Implement the agreed mixed per-family runtime proving path so Derrick can test the best currently-supported choice per punch family in Godot replay/live proving. Keep the implementation as narrow as possible and make the active routing/debug truth explicit in proving surfaces.

**Folders Created/Deleted/Modified:**
- `src/detectors/`
- `.testbed/scripts/`
- `.testbed/tests/unit/`
- `.plans/`

**Files Created/Deleted/Modified:**
- `src/detectors/pose_detector_substrate.gd`
- `src/detectors/learned_punch_classifier.gd`
- `src/detectors/prototype_punch_matcher.gd`
- `.testbed/scripts/proving_harness.gd`
- `.testbed/scripts/boxing_proving_harness.gd`
- `.testbed/tests/unit/test_pose_detector_substrate.gd`
- `.testbed/tests/unit/test_boxing_proving_harness_profiles_and_debug.gd`
- `.plans/2026-06-18-learned-classifier-family-specific-feature-branch.md`

**Status:** ✅ Complete

**Results:** Added a proving-only `mixed_family` punch backend that routes straights through the learned classifier while keeping hook/uppercut on the existing threshold-gate runtime path. `pose_detector_substrate.gd` now surfaces explicit per-family routing/debug truth (`routing_mode`, `straight_backend`, `hook_backend`, `uppercut_backend`, `straight_model_path`, and a hook/uppercut note), and `boxing_proving_harness.gd` now exposes that truth in the event feed and uses per-family backend truth when choosing hover-card detail panels. `proving_harness.gd` gained a proving override path for `AEROBEAT_PUNCH_BACKEND_OVERRIDE=mixed_family`, defaulting straights to `docs/baselines/boxing-punch-classifier-family-masked-topology-benchmark-2026-06-18/straight_family_mask_v1/mlp/mlp-result.json` unless `AEROBEAT_LEARNED_CLASSIFIER_MODEL_PATH_OVERRIDE` is set. `prototype_punch_matcher.gd` gained runtime support for the missing straight-family feature `elbow_shoulder_radial_velocity_over_shoulder_width` plus backward-compatible sample-history handling so the learned classifier still works normally. Focused unit coverage was added for mixed routing truth and proving debug surfaces, and the focused GUT suites passed: `res://tests/unit/test_pose_detector_substrate.gd` and `res://tests/unit/test_boxing_proving_harness_profiles_and_debug.gd`.

---

### Task 33: QA mixed per-family runtime punch-classifier path in proving

**Bead ID:** `aerobeat-input-camera-tracking-9h1o`  
**SubAgent:** `primary` (for `qa`)  
**Role:** `qa`  
**References:** `REF-02`, `REF-03`, `REF-05`, `REF-06`  
**Prompt:** Verify the mixed per-family runtime proving path works truthfully in the highest-fidelity proving flow available and that the debug/proving surfaces make the active family routing explicit.

**Folders Created/Deleted/Modified:**
- `.testbed/tests/unit/`
- `.testbed/scripts/`
- `src/detectors/`

**Files Created/Deleted/Modified:**
- `.plans/2026-06-18-learned-classifier-family-specific-feature-branch.md`
- `.testbed/tests/unit/test_pose_detector_substrate.gd`
- `.testbed/tests/unit/test_boxing_proving_harness_profiles_and_debug.gd`
- `.testbed/scripts/boxing_proving_harness.gd`
- `.testbed/scripts/proving_harness.gd`
- `src/detectors/pose_detector_substrate.gd`
- `src/detectors/prototype_punch_matcher.gd`

**Status:** ✅ Complete

**Results:** Re-ran the focused mixed-family QA coverage on commit `0ba32df` with `godot --headless --path .testbed --script addons/aerobeat-vendor-godot-unit-test/gut_cmdln.gd -gtest=res://tests/unit/test_pose_detector_substrate.gd,res://tests/unit/test_boxing_proving_harness_profiles_and_debug.gd -gexit`. Output reproduced cleanly: `108/108` tests passed, including `test_mixed_family_backend_routes_straights_to_learned_classifier_and_surfaces_truth`, `test_mixed_family_backend_filters_non_straight_learned_events`, `test_proving_runtime_config_can_force_mixed_family_backend_for_fixture_benchmarks`, and `test_boxing_event_feed_reports_mixed_family_routing_truth`. QA confirmed the intended proving-only behavior is internally consistent: straights route to `learned_classifier`, hooks/uppercuts stay on `threshold_gates`, the substrate debug state exposes `routing_mode`, `straight_backend`, `hook_backend`, `uppercut_backend`, and `straight_model_path`, and the proving/event-feed surface makes the routing split explicit plus includes the hook/uppercut note and per-event backend truth. Caveat: the proving event-feed text for `mixed_family` does not appear to print the exact substrate field name `straight_model_path` directly; instead the proving UI exposes the active learned model path via learned-classifier labels/panels, while the explicit `straight_model_path` key remains available in substrate debug state. Also noted non-blocking pre-existing GUT orphan/leaked-RID warnings in the proving harness suite plus addon UID fallback warnings; they did not fail the run. QA pass and ready for audit.

---

### Task 34: Audit mixed per-family runtime punch-classifier path

**Bead ID:** `aerobeat-input-camera-tracking-4hpa`  
**SubAgent:** `primary` (for `auditor`)  
**Role:** `auditor`  
**References:** `REF-02`, `REF-03`, `REF-05`, `REF-06`  
**Prompt:** Independently truth-check the mixed per-family runtime proving path and confirm whether it is ready for Derrick’s replay/live testing feedback loop.

**Folders Created/Deleted/Modified:**
- relevant repo paths used during audit

**Files Created/Deleted/Modified:**
- `.plans/2026-06-18-learned-classifier-family-specific-feature-branch.md`

**Status:** ✅ Complete

**Results:** Audit independently re-checked commit `0ba32df` against the landed code, the focused proving/runtime tests, and the active plan claims. I reran `godot --headless --path .testbed --script addons/aerobeat-vendor-godot-unit-test/gut_cmdln.gd -gtest=res://tests/unit/test_pose_detector_substrate.gd,res://tests/unit/test_boxing_proving_harness_profiles_and_debug.gd -gexit`, and the focused suite reproduced cleanly at `108/108` passing. The checked-in routing is internally consistent with QA’s summary: in `src/detectors/pose_detector_substrate.gd`, `mixed_family` explicitly runs `LearnedPunchClassifier.process_window(...)`, filters those learned events down to `punch_left` / `punch_right` only, and then separately runs `_process_hook(...)` and `_process_uppercut(...)` from the threshold-gate path. That means the implementation is honest about using learned straights while keeping hook/uppercut on the existing threshold backend, and it also prevents non-straight learned outputs from leaking through in mixed mode. The proving/runtime surface is also truthful enough for replay/live debugging: the substrate debug state exposes `routing_mode`, `straight_backend`, `hook_backend`, `uppercut_backend`, `selected_backend[_enabled]`, `active_backend_resolution`, `hook_uppercut_backend_note`, and `straight_model_path`; the proving harness can force `mixed_family` through `AEROBEAT_PUNCH_BACKEND_OVERRIDE`; and the boxing proving event feed/hover-card routing now resolves per-event backend truth instead of pretending one backend owns every punch family. The added runtime feature support for `elbow_shoulder_radial_velocity_over_shoulder_width` is present in `src/detectors/prototype_punch_matcher.gd`, so the proving-only straight-family model path is supported by the shipped runtime extractor. Caveats remain non-blocking but worth remembering during Derrick’s replay/live loop: this is still a proving-only mixed route (wired through proving runtime override, not a broader product rollout), the default mixed straight model path points at the straight-family masked MLP artifact, the event-feed text does not print the literal `straight_model_path` field name even though the path is present in debug state / learned-classifier panels, and the focused GUT run still emits pre-existing orphan/leaked-RID plus addon UID fallback warnings that did not affect pass/fail. Audit passes, and the mixed-family path is ready for Derrick’s replay/live Godot testing feedback loop.

---

### Task 35: Research broader global mixed per-family punch backend rollout

**Bead ID:** `aerobeat-input-camera-tracking-ekp4`  
**SubAgent:** `primary` (for `research`)  
**Role:** `research`  
**References:** `REF-02`, `REF-03`, `REF-05`, `REF-06`  
**Prompt:** Derrick wants to use the current proving-only mixed-family success as a stepping stone toward a broader global rollout. Research the narrowest honest path to move from proving-only mixed routing to a broader runtime/config rollout without lying about hook/uppercut readiness. Be explicit about config shape, migration risk, compatibility with existing punch backend selection, and what should remain proving-only versus what can safely become general runtime behavior.

**Folders Created/Deleted/Modified:**
- relevant runtime/config/proving paths discovered during research

**Files Created/Deleted/Modified:**
- `.plans/2026-06-18-learned-classifier-family-specific-feature-branch.md`

**Status:** ✅ Complete

**Results:** Research completed. The runtime core is already closer than the proving-only label suggested: `src/detectors/pose_detector_substrate.gd` and `src/detectors/learned_punch_classifier.gd` already understand `mixed_family` as a real backend selection, route straights through learned classification, keep hook/uppercut on `threshold_gates`, and surface honest per-family debug truth (`routing_mode`, `straight_backend`, `hook_backend`, `uppercut_backend`, `hook_uppercut_backend_note`, `straight_model_path`). The part that is still proving-shaped is the config contract: today `mixed_family` is mainly injected by `.testbed/scripts/proving_harness.gd` through `AEROBEAT_PUNCH_BACKEND_OVERRIDE`, and the straight-family artifact path is also proving-defaulted there.

Ranked rollout options:
1. **Recommended / narrowest honest global path:** officially globalize `punch_detection.backend: mixed_family` in the normal gesture config, keep the existing single backend selector contract, and add one small backend-specific config section for the straight learned artifact path (for example `mixed_family.straight.model.artifact_path`, with optional fallback to `learned_classifier.model.artifact_path`). This preserves existing `threshold_gates` / `prototype_matcher` / `learned_classifier` behavior unchanged while making the already-landed mixed router selectable outside proving.
2. **Acceptable but broader:** add a generic per-family backend map (for example `punch_detection.family_backends.{straight,hook,uppercut}`) plus per-family model config. This is flexible, but it is more migration surface than the branch truth currently needs and weakens rollback simplicity.
3. **Not recommended yet:** promote a global multi-learned-artifact family system for hook/uppercut too. Current runtime feature extraction still does not honestly support the hook/uppercut specialized artifacts, so this would overstate readiness.

Recommended config shape for the smallest honest rollout:
- Keep `punch_detection.backend` as the top-level selector and officially allow `mixed_family` alongside `threshold_gates`, `prototype_matcher`, and `learned_classifier`.
- Add a narrow backend-owned subtree such as:
  - `mixed_family.enabled: true` (optional/redundant; could be omitted if backend selection alone is authoritative)
  - `mixed_family.straight.model.artifact_path: <straight masked MLP artifact>`
  - optional `mixed_family.debug.show_routing_truth: true` only if we want presentation-level control later, not required for the first slice.
- Leave `learned_classifier.model.artifact_path` owning the full learned backend so existing full-learned configs do not silently become straight-only configs.

Compatibility / migration judgment:
- This is highly compatible with the existing punch backend selection model because the substrate already expects one normalized backend string and already computes `selected_backend_enabled` / `active_backend_resolution` for `mixed_family`.
- The safest implementation is to teach `LearnedPunchClassifier` to resolve a mixed-family-specific straight artifact path when `punch_detection.backend == mixed_family`, then fall back cleanly to the current learned artifact behavior when that path is absent.
- Rollback stays trivial: switch `punch_detection.backend` back to `threshold_gates` or `learned_classifier`, or remove the new mixed-family config block entirely. No data migration is required.

What can safely become general runtime behavior now:
- official config/schema support for selecting `mixed_family`
- non-proving runtime/backend resolution for `mixed_family`
- substrate/global debug truth for per-family routing and the straight model path
- tests that validate global config loading, backend resolution, and truthful debug state outside proving overrides

What should stay proving-only or explicitly not be globalized yet:
- proving-harness environment override defaults (`AEROBEAT_PUNCH_BACKEND_OVERRIDE`, proving default straight artifact path) should remain a proving convenience, not the main product contract
- any claim that hook/uppercut have learned-specialized runtime support
- any generic family-backend matrix or hook/uppercut learned artifact config until runtime feature extraction honestly supports those benchmark artifacts
- any silent reuse of `learned_classifier.model.artifact_path` as the global mixed straight model without an explicit mixed-family config path or explicit documented fallback, because that would blur full-learned versus straight-only-learned intent

Likely files/components for the next coder slice: `assets/boxing.gesture_detection.yaml` for schema/commented config shape, `src/detectors/learned_punch_classifier.gd` for mixed-family-specific artifact-path resolution, `src/detectors/pose_detector_substrate.gd` for any wording cleanup from “proving mode” to honest general mixed-family routing, `.testbed/scripts/proving_harness.gd` to stop carrying more responsibility than necessary once the config contract is real, and unit coverage under `.testbed/tests/unit/` for config/profile loading plus substrate/proving debug truth. Coder readiness: **yes** — the narrow next move is a config-contract/global-selection pass, not another model/routing invention.

---

### Task 36: Implement broader global mixed per-family punch backend rollout

**Bead ID:** `aerobeat-input-camera-tracking-qfti`  
**SubAgent:** `primary` (for `coder`)  
**Role:** `coder`  
**References:** `REF-02`, `REF-03`, `REF-05`, `REF-06`  
**Prompt:** Implement the agreed broader global mixed per-family punch backend rollout with the smallest honest change set. Preserve truthful backend/debug state, keep hook/uppercut on the existing path until truly ready, and make the global config/runtime behavior explicit and safe.

**Folders Created/Deleted/Modified:**
- `assets/`
- `src/detectors/`
- `.testbed/scripts/`
- `.testbed/tests/unit/`
- `.plans/`

**Files Created/Deleted/Modified:**
- `assets/boxing.gesture_detection.yaml`
- `src/detectors/learned_punch_classifier.gd`
- `src/detectors/pose_detector_substrate.gd`
- `.testbed/scripts/proving_harness.gd`
- `.testbed/tests/unit/test_camera_tracking_config_profiles.gd`
- `.testbed/tests/unit/test_pose_detector_substrate.gd`
- `.testbed/tests/unit/test_boxing_proving_harness_profiles_and_debug.gd`
- `.plans/2026-06-18-learned-classifier-family-specific-feature-branch.md`

**Status:** ✅ Complete

**Results:** Implemented the narrow global mixed-family rollout without globalizing hook/uppercut learned specialization. The canonical boxing gesture profile now treats `mixed_family` as an official `punch_detection.backend` option, restores the default shipping backend contract to `threshold_gates`, and adds an explicit `mixed_family.straight.model.artifact_path` path for the straight learned artifact. Runtime model-path resolution in `learned_punch_classifier.gd` now prefers that mixed-family straight artifact only when `punch_detection.backend = mixed_family`, then falls back to the existing `learned_classifier.model.artifact_path` contract for normal learned-classifier selection and compatibility. `pose_detector_substrate.gd` keeps truthful global routing/debug fields (`routing_mode`, `straight_backend`, `hook_backend`, `uppercut_backend`, `straight_model_path`, `selected_backend`, `selected_backend_enabled`, `active_backend_resolution`) while updating the hook/uppercut note from proving-only wording to honest runtime wording. The proving harness mixed-family override now writes through the real mixed-family straight-artifact path instead of mutating the generic learned-classifier model slot. Added focused unit coverage for the new config shape plus a precedence test proving mixed-family uses its explicit straight artifact over the generic learned-classifier artifact. Validation run: `godot --headless --path .testbed --script addons/aerobeat-vendor-godot-unit-test/gut_cmdln.gd -gtest=res://tests/unit/test_camera_tracking_config_profiles.gd,res://tests/unit/test_pose_detector_substrate.gd,res://tests/unit/test_boxing_proving_harness_profiles_and_debug.gd -gexit` → **113/113 passed** (existing proving-harness orphan/leak warnings remained, exit code 0).

---

### Task 37: QA broader global mixed per-family punch backend rollout

**Bead ID:** `aerobeat-input-camera-tracking-xmj1`  
**SubAgent:** `primary` (for `qa`)  
**Role:** `qa`  
**References:** `REF-02`, `REF-03`, `REF-05`, `REF-06`  
**Prompt:** Verify the broader global mixed per-family punch backend rollout works truthfully, remains compatible with existing punch backend selection expectations, and exposes the correct backend/routing truth outside the proving-only path.

**Folders Created/Deleted/Modified:**
- relevant repo paths used during QA

**Files Created/Deleted/Modified:**
- QA notes/artifacts as needed

**Status:** ⏳ Pending

**Results:** Pending.

---

### Task 38: Audit broader global mixed per-family punch backend rollout

**Bead ID:** `aerobeat-input-camera-tracking-718u`  
**SubAgent:** `primary` (for `auditor`)  
**Role:** `auditor`  
**References:** `REF-02`, `REF-03`, `REF-05`, `REF-06`  
**Prompt:** Independently truth-check the broader global mixed per-family rollout and confirm whether it is safe, honest, and ready beyond proving-only use.

**Folders Created/Deleted/Modified:**
- relevant repo paths used during audit

**Files Created/Deleted/Modified:**
- audit notes/artifacts as needed

**Status:** ⏳ Pending

**Results:** Pending.

---

### Task 39: Clarify mixed-family YAML comments and config contract

**Bead ID:** `aerobeat-input-camera-tracking-x2t3`  
**SubAgent:** `primary` (for `coder`)  
**Role:** `coder`  
**References:** `REF-02`, `REF-03`, `REF-05`, `REF-06`  
**Prompt:** Tighten the YAML comments around the new mixed-family runtime rollout so the config contract is explicit, not just technically present. Clarify that `punch_detection.backend: mixed_family` routes straights through the learned straight artifact while hooks/uppercuts stay on threshold gates for now, and document the artifact-path resolution/fallback behavior well enough to avoid future confusion.

**Folders Created/Deleted/Modified:**
- config/comment paths in `assets/`

**Files Created/Deleted/Modified:**
- `assets/boxing.gesture_detection.yaml`
- plan updates / notes as needed

**Status:** ✅ Complete

**Results:** Tightened the boxing YAML comments so the mixed-family rollout contract is explicit at both the top-level backend selector and the `mixed_family` block. Documented that `punch_detection.backend: mixed_family` routes straights through `mixed_family.straight.model.artifact_path`, keeps hooks/uppercuts on `threshold_gates`, and falls back to `learned_classifier.model.artifact_path` and then the built-in default artifact when the mixed-family straight artifact path is blank or omitted. Commit: `ebe0b75` (`Clarify mixed-family config comments`).

---

### Task 40: QA mixed-family YAML comment/config-contract cleanup

**Bead ID:** `aerobeat-input-camera-tracking-lqyx`  
**SubAgent:** `primary` (for `qa`)  
**Role:** `qa`  
**References:** `REF-02`, `REF-03`, `REF-05`, `REF-06`  
**Prompt:** Verify the mixed-family YAML comments/config-contract cleanup is accurate, consistent with the landed runtime behavior, and explicit enough to prevent future misconfiguration.

**Folders Created/Deleted/Modified:**
- relevant repo paths used during QA

**Files Created/Deleted/Modified:**
- QA notes/artifacts as needed

**Status:** ⏳ Pending

**Results:** Pending.

---

### Task 41: Audit mixed-family YAML comment/config-contract cleanup

**Bead ID:** `aerobeat-input-camera-tracking-qnzy`  
**SubAgent:** `primary` (for `auditor`)  
**Role:** `auditor`  
**References:** `REF-02`, `REF-03`, `REF-05`, `REF-06`  
**Prompt:** Independently truth-check the mixed-family YAML comment/config-contract cleanup and confirm the docs/comments now honestly match the shipped runtime behavior.

**Folders Created/Deleted/Modified:**
- relevant repo paths used during audit

**Files Created/Deleted/Modified:**
- audit notes/artifacts as needed

**Status:** ⏳ Pending

**Results:** Pending.

---

### Task 42: Terminal-side mixed-family proving verification and bugfixes

**Bead ID:** `aerobeat-input-camera-tracking-erwp`  
**SubAgent:** `primary` (for `coder`)  
**Role:** `coder`  
**References:** `REF-02`, `REF-03`, `REF-05`, `REF-06`  
**Prompt:** Run a terminal-side verification pass against the mixed-family proving/runtime path to confirm backend/event truth is behaving as expected under replay/headless-friendly checks. If concrete bugs are found, fix them immediately, keep scope narrow, and document exactly what failed versus what was corrected.

**Folders Created/Deleted/Modified:**
- `.testbed/.temp/mixed-family-terminal-check/`
- proving/runtime/test paths used during verification

**Files Created/Deleted/Modified:**
- `.testbed/scripts/proving_harness.gd`
- `.testbed/scripts/boxing_proving_harness.gd`
- `.testbed/tests/unit/test_boxing_proving_harness_profiles_and_debug.gd`
- `.plans/2026-06-18-learned-classifier-family-specific-feature-branch.md`

**Status:** ✅ Complete

**Results:** Ran a terminal-side mixed-family verification pass using both focused repo-local unit coverage and real headless proving replays.

Checks run:
- `godot --headless --path .testbed --script addons/aerobeat-vendor-godot-unit-test/gut_cmdln.gd -gtest=res://tests/unit/test_boxing_proving_harness_profiles_and_debug.gd,res://tests/unit/test_pose_detector_substrate.gd -gexit`
- Headless replay captures via `res://scripts/capture_fixture_proving.gd` with `AEROBEAT_PUNCH_BACKEND_OVERRIDE=mixed_family` and `AEROBEAT_FIXTURE_STATE_TIMELINE_MODE=full` across the representative boxing fixtures from `.testbed/assets/benchmarks/prototype_matcher_boxing_v1.benchmark.json`.
- Replay summaries written under `.testbed/.temp/mixed-family-terminal-check/full/summary.json` for straight/hook/uppercut left+right plus the run-in-place negative control.

Concrete bug found and fixed:
- The proving harness attack-event payload truth used the top-level `punch_detection.backend` string instead of the per-family routing truth, so emitted mixed-family events dropped their actual backend metadata. In practice that meant threshold-routed hook/uppercut emits and learned-routed straight emits could show no `backend` payload even though `gesture_debug.punch_detection` already knew the correct routing.
- Fixed by teaching `.testbed/scripts/proving_harness.gd` to resolve event backend per signal family (`straight_backend` / `hook_backend` / `uppercut_backend`) and by returning explicit `threshold_gates` payload truth for threshold-routed mixed-family emits.
- Also corrected `.testbed/scripts/boxing_proving_harness.gd` so the mixed-family event-feed text no longer falls through to prototype-matcher truth; it now labels the section as mixed-family straight-classifier truth and surfaces the learned straight model path honestly.
- Added focused coverage in `.testbed/tests/unit/test_boxing_proving_harness_profiles_and_debug.gd` for both the mixed-family event-feed text and per-family backend payload resolution.

What the terminal-side pass proved:
- Mixed-family backend activation is real in runtime/proving: replay captures consistently reported `active_backend=mixed_family`, `routing_mode=mixed_family`, `straight_backend=learned_classifier`, and `hook_backend/uppercut_backend=threshold_gates`.
- After the bugfix, emitted replay attack events now truthfully carry their routed backend in payloads, so terminal-side event/backend truth surfaces are internally consistent.
- The underlying replay behavior is not yet clean enough for signoff: the straight-right replay did emit `punch_right` events from the learned path, but the straight-left replay missed learned straight emits entirely; multiple straight/hook/uppercut fixtures also still showed extra threshold hook/uppercut false positives, and even the run-in-place negative control produced threshold-routed attack events. This looks like a behavior-quality/runtime-tuning problem rather than the proving-truth-surface bug that was fixed here.

Bottom line: terminal-side truth plumbing is now more honest, but QA is **not** ready to pass the mixed-family rollout yet because the real replay behavior still shows misses/false positives that require follow-up validation and likely more code/runtime tuning before GUI/manual signoff.

---

### Task 43: QA terminal-side mixed-family proving verification

**Bead ID:** `aerobeat-input-camera-tracking-7qte`  
**SubAgent:** `primary` (for `qa`)  
**Role:** `qa`  
**References:** `REF-02`, `REF-03`, `REF-05`, `REF-06`  
**Prompt:** Verify the terminal-side mixed-family proving checks (and any bugfixes from Task 42) are reproducible, truthful, and explicit about what terminal-side validation can and cannot prove versus later manual GUI testing.

**Folders Created/Deleted/Modified:**
- `.temp/qa-mixed-family-terminal-rerun-2026-06-18/`
- relevant repo paths used during QA

**Files Created/Deleted/Modified:**
- `.plans/2026-06-18-learned-classifier-family-specific-feature-branch.md`
- `.temp/qa-mixed-family-terminal-rerun-2026-06-18/straight_right/{report.json,report.md,godot.log}`
- `.temp/qa-mixed-family-terminal-rerun-2026-06-18/run_in_place/{report.json,report.md,godot.log}`

**Status:** ✅ Complete

**Results:** QA reran the focused terminal-side verification from current repo state and reproduced the truth-surface fix cleanly. First, the focused runtime/proving unit coverage passed again with `godot --headless --path .testbed --script addons/aerobeat-vendor-godot-unit-test/gut_cmdln.gd -gtest=res://tests/unit/test_boxing_proving_harness_profiles_and_debug.gd,res://tests/unit/test_pose_detector_substrate.gd -gexit`, yielding `110/110` passing tests. That rerun specifically re-proved the new mixed-family truth-surface expectations added in commit `be4b0bf`: `test_boxing_event_feed_reports_mixed_family_routing_truth` and `test_mixed_family_classifier_match_payload_uses_per_family_backend_truth` both passed, alongside the substrate mixed-routing tests.

Then QA reran a small fresh proving replay subset into `.temp/qa-mixed-family-terminal-rerun-2026-06-18/` using the live mixed-family proving path rather than trusting the existing saved summary: `AEROBEAT_PUNCH_BACKEND_OVERRIDE=mixed_family AEROBEAT_FIXTURE_STATE_TIMELINE_MODE=full AEROBEAT_CAMERA_TRACKING_SOURCE="$PWD/.testbed/assets/fixtures/boxing/straight_right/boxing_guard->straight_right_repeat_04_take_01.mp4" godot --headless --path .testbed --script res://scripts/capture_fixture_proving.gd -- res://scenes/boxing_proving.tscn "$PWD/.testbed/assets/fixtures/boxing/straight_right" "$PWD/.temp/qa-mixed-family-terminal-rerun-2026-06-18/straight_right" 8000` and the matching run-in-place negative-control command against `/.testbed/assets/fixtures/boxing/run_in_place/boxing_guard->run_in_place_repeat_01_take_01.mp4`. Both captures exited successfully and reproduced the intended routing truth: `active_backend=mixed_family`, `routing_mode=mixed_family`, `straight_backend=learned_classifier`, `hook_backend=threshold_gates`, `uppercut_backend=threshold_gates`, and the straight learned model path resolved to the checked-in straight-family masked MLP artifact.

The truth-surface fix from `be4b0bf` is real. In the rerun `straight_right` replay, emitted `punch_right` events again carried `payload.backend=learned_classifier` with the expected learned-classifier payload block, while threshold-routed `hook_*` / `uppercut_*` events in the same replay carried `payload.backend=threshold_gates` instead of dropping backend truth. The negative control also stayed honest about provenance: its emitted false positives were all threshold-routed (`uppercut_left`, `uppercut_right`, `hook_left`), with no fabricated learned-classifier backend attribution.

What terminal-side QA now truly proves is narrower than rollout acceptance. It proves that mixed-family backend activation is real, that per-family routing truth surfaces are wired correctly in runtime/proving code, that emitted replay attack payloads now expose the routed backend truthfully after the bugfix, and that the proving/event-feed/unit-test surfaces are internally consistent. It does **not** prove that the mixed-family rollout is behaviorally ready. The same rerun still showed extra threshold hook/uppercut false positives during the positive straight replay and during the run-in-place negative control, while the saved full-summary evidence from Task 42 still shows the opposite straight replay (`straight_left_fixture`) failing to emit learned straight events at all. Those are behavior-quality/runtime-tuning problems, not disprovals of the truth-surface fix.

QA judgment: terminal-side verification passes as a truthfulness/reproducibility task, but only with the explicit caveat that it is **not** a final product acceptance pass. Derrick’s manual GUI replay/live test is still required for hover-card/visual-quality confirmation, for final acceptance of replay/live behavior, and for any decision that the broader mixed-family rollout is pass-ready. Audit is ready on that narrower claim.

---

### Task 44: Audit terminal-side mixed-family proving verification

**Bead ID:** `aerobeat-input-camera-tracking-n3c9`  
**SubAgent:** `primary` (for `auditor`)  
**Role:** `auditor`  
**References:** `REF-02`, `REF-03`, `REF-05`, `REF-06`  
**Prompt:** Independently truth-check the terminal-side mixed-family proving verification and any resulting fixes, and state what is now proven versus what still requires Derrick’s manual GUI replay/live test.

**Folders Created/Deleted/Modified:**
- `.temp/audit-mixed-family-terminal-rerun-2026-06-18/`
- relevant repo paths used during audit

**Files Created/Deleted/Modified:**
- `.plans/2026-06-18-learned-classifier-family-specific-feature-branch.md`
- `.temp/audit-mixed-family-terminal-rerun-2026-06-18/straight_right/report.json`
- `.temp/audit-mixed-family-terminal-rerun-2026-06-18/straight_right/report.md`
- `.temp/audit-mixed-family-terminal-rerun-2026-06-18/run_in_place/report.json`
- `.temp/audit-mixed-family-terminal-rerun-2026-06-18/run_in_place/report.md`

**Status:** ✅ Complete

**Results:** Audit passed for the narrow terminal-side claim. I independently reran the focused unit coverage that exercises the proving truth surfaces and substrate routing (`test_boxing_proving_harness_profiles_and_debug.gd` + `test_pose_detector_substrate.gd`), and all 110 tests passed under headless Godot. That includes the specific mixed-family assertions added around `be4b0bf`: mixed-family event-feed truth now labels the straight path as `Mixed-family straight-classifier truth`, exposes the straight learned model path, and keeps per-family backend resolution explicit; `_classifier_match_payload_for_signal()` now resolves backend truth per emitted family instead of trusting the coarse selected backend; and mixed-family emitted payloads now return `backend=learned_classifier` for straight punches while returning `backend=threshold_gates` with an empty classifier payload for hook/uppercut events routed through threshold gates.

I also reran a small fresh proving replay subset into `.temp/audit-mixed-family-terminal-rerun-2026-06-18/` using the live mixed-family path rather than trusting prior summaries. The positive `straight_right` replay again resolved `active_backend=mixed_family`, `routing_mode=mixed_family`, `straight_backend=learned_classifier`, `hook_backend=threshold_gates`, and `uppercut_backend=threshold_gates`; its emitted `punch_right` events carried `payload.backend=learned_classifier` plus the learned-classifier payload block with `class_name=straight_right`, while contemporaneous `hook_*` / `uppercut_*` events carried `payload.backend=threshold_gates`. The `run_in_place` negative-control replay stayed honest about provenance too: its false positives were still bad behaviorally, but they were all threshold-routed rather than being mislabeled as learned-classifier output.

So what is now proven: the terminal-side mixed-family activation/routing truth is real, the `be4b0bf` truth-surface fix is real, emitted replay payloads now report per-family backend provenance truthfully, and the event-feed / proving / unit-test surfaces are internally consistent for this narrow claim. What is **not** proven: behavioral quality, manual hover-card/GUI presentation quality, replay UX, live-camera performance, or rollout readiness. The reruns still show threshold hook/uppercut false positives during the straight replay and the run-in-place negative control, and prior saved branch evidence still leaves broader learned-family behavior questions open. Derrick still needs manual GUI replay/live testing next session before any broader pass-ready judgment.

---

### Task 45: Research mixed-family runtime bug, naming migration, and per-family config topology

**Bead ID:** `aerobeat-input-camera-tracking-aims`  
**SubAgent:** `primary` (for `research`)  
**Role:** `research`  
**References:** `REF-02`, `REF-03`, `REF-05`, `REF-06`  
**Prompt:** Derrick resumed the branch with concrete Cookie/Chip test feedback. Investigate why `punch_detection.backend = mixed_family` can still show straight learned routing in debug while failing to load the effective straight model, with the provided screenshot indicating `Selected backend = mixed_family`, `Active backend = learned_classifier`, `Learned model loaded = false`, and an older 2026-06-16 artifact path. Also review the current boxing gesture YAML and runtime contract against Derrick’s requested topology cleanup: rename `learned_classifier` → `single_classifier`, rename `mixed_family` → `multiple_classifiers`, expose parallel per-backend option sets without sharing YAML variables, and assess whether the config should evolve toward clearer per-family backend ownership while staying honest about threshold-only gestures like guard. Produce the narrowest truthful implementation slice and call out any migration risk. Claim bead `aerobeat-input-camera-tracking-aims` on start and close it when complete.

**Folders Created/Deleted/Modified:**
- relevant runtime/config/proving paths discovered during diagnosis

**Files Created/Deleted/Modified:**
- plan updates / notes as needed

**Status:** ✅ Complete

**Results:** Research completed. Most likely straight-model failure cause is the current shared fallback contract, not the mixed router itself. In `src/detectors/learned_punch_classifier.gd`, mixed mode resolves the straight artifact from `mixed_family.straight.model.artifact_path`, then falls back to `learned_classifier.model.artifact_path`, then to `DEFAULT_MODEL_ARTIFACT_PATH`. Derrick’s screenshot path `res://addons/aerobeat-input-camera-tracking/docs/baselines/boxing-punch-classifier-temporal-cnn-baseline-2026-06-16/mlp/mlp-result.json` does **not** exist in the repo/addon tree, while the current shipped frozen MLP path does. That makes the most likely bug a stale/dead learned-artifact path being reused through the shared fallback surface when mixed mode is selected. In other words: mixed routing can be active, but if the effective straight-model path is inherited from the old single learned slot and that slot still points at a deleted artifact, runtime truthfully reaches `model_unavailable (model_open_failed)` and straights never fire.

Two extra details matter for interpreting the screenshot honestly. First, the learned detector’s own debug state currently reports `active_backend = learned_classifier` whenever it is the concrete engine doing work, even if the top-level selected backend is `mixed_family`; that naming is confusing but not itself the load failure. Second, the current `assets/boxing.gesture_detection.yaml` no longer points at the dead temporal-CNN path; both `learned_classifier.model.artifact_path` and `mixed_family.straight.model.artifact_path` now point at the existing frozen MLP artifact. So if Derrick still sees the dead temporal path at runtime, the live `gesture_profile_document` is almost certainly coming from an older serialized/configured source (or a path injected elsewhere) rather than from the current checked-in YAML.

Independent YAML/runtime audit: the current topology is still half-global, half-family-specific. `mixed_family` already owns a family-local straight model path, but it still reuses the global `learned_classifier` node for fallback and enablement, which is exactly the kind of shared variable coupling Derrick wants removed. The clean long-term idea of “each gesture family owns its own backend” is directionally better for punch families, but it is **not** yet an honest repo-wide shape for `guard/squat/weave/knee_strike/leg_lift/side_step`; those gestures currently have one runtime detector each, so giving them fake backend matrices right now would mostly create empty config ceremony and overstate readiness.

Recommended narrowest truthful implementation slice for Task 46:
1. Rename config/runtime labels with compatibility aliases: `learned_classifier` → `single_classifier`, `mixed_family` → `multiple_classifiers`.
2. Stop sharing backend-owned model/config nodes in the new contract. `single_classifier` should own its own `enabled/model/thresholds/timing/debug` subtree; `multiple_classifiers` should own its own per-family subtrees and should not depend on `single_classifier.model.artifact_path` for normal operation.
3. For the initial `multiple_classifiers` slice, make only the punch families explicit: `straight`, `hook`, and `uppercut` each get their own backend selection surface. Keep `straight` able to choose `single_classifier` now; keep `hook`/`uppercut` defaulted to `threshold_gates` and document that their learned-specialized paths are not runtime-ready yet.
4. Keep legacy read compatibility for one migration window: accept old `learned_classifier` / `mixed_family` names and old fallback fields, but only as compatibility input. New comments/examples/debug should prefer the renamed nodes and should surface when a legacy fallback path was used.
5. Remove the current ambiguity in debug truth by distinguishing top-level selected mode (`multiple_classifiers`) from the concrete per-family engine (`single_classifier` for straight, `threshold_gates` for hook/uppercut).

Recommended config direction (honest first step, not full future overreach):
- `punch_detection.backend: single_classifier | multiple_classifiers | threshold_gates | prototype_matcher`
- `single_classifier:` owns the all-punch single-model path and its own thresholds/timing/debug block.
- `multiple_classifiers.straight:` owns `backend` plus a `single_classifier` subtree with its own model/tuning.
- `multiple_classifiers.hook:` owns `backend` plus parallel option subtrees, but comments should say the runtime-supported backend is still `threshold_gates` for now.
- `multiple_classifiers.uppercut:` same as hook.
This gives Derrick the naming/topology seam he wants without pretending hook/uppercut learned runtime support already exists.

Compatibility / migration risks:
- Existing saved configs, proving overrides, tests, and debug tooling likely still emit/read `learned_classifier` and `mixed_family`; alias support is required or old sessions will silently break.
- Any code/tests that assert exact backend strings (`mixed_family`, `learned_classifier`) will need deliberate update because the rename affects both config and debug truth.
- If Task 46 removes the old fallback too aggressively, older configs missing the new `multiple_classifiers.straight.single_classifier.model.artifact_path` could regress from “loads stale wrong file” to “loads no file at all.” The safe migration is explicit new path first, legacy fallback second, default artifact last, with a visible resolution reason.
- Broad per-gesture backend ownership beyond punches should wait; doing it now would add noisy config surface for gestures that still only have one real implementation path.

Bottom line: the most probable straight-fire regression is a stale dead artifact path surviving through the shared `mixed_family -> learned_classifier` fallback chain. The narrow honest fix identified in research was to rename and split the config contract so `multiple_classifiers` owns its own family-local model/config surfaces and to keep legacy aliases during migration. After this research pass, Derrick explicitly approved the broader readability-driven split: every gesture family should now own its own backend/config surface, with many families expected to remain threshold-backed until more runtime engines actually exist.

---

### Task 46: Implement mixed-family fix, backend renames, and per-family config expansion

**Bead ID:** `aerobeat-input-camera-tracking-vw0r`  
**SubAgent:** `primary` (for `coder`)  
**Role:** `coder`  
**References:** `REF-02`, `REF-03`, `REF-05`, `REF-06`  
**Prompt:** Implement the approved family-first runtime/config split from Task 45. Required goals: (1) fix the straight-family runtime path so the selected classifier path actually loads the intended straight model, (2) rename `learned_classifier` to `classifier`, (3) replace the old `mixed_family` concept with the new family-first contract instead of keeping a separate mixed-mode selector, (4) make **each boxing gesture family** (straight_punch, hook, uppercut, guard, squat, weave, knee_strike, leg_lift, side_step, and any other shipped boxing families) own a single `backend` selector with values exactly `threshold`, `prototype`, or `classifier`, and (5) under each family, define backend-specific variable groups named exactly `threshold`, `prototype`, and `classifier` without shared YAML variable nodes and without redundant enabled booleans—the selected `backend` is the activator. Preserve the repo’s existing YAML comment style while updating comments/debug truth so the shipped behavior stays explicit and readable. Keep the implementation honest: if a family does not have a real runtime implementation for a backend yet, keep that backend block present only as honest config/documentation shape or compatibility support and do not fake working runtime behavior. Preserve compatibility/migration safety where practical and keep per-family routing/debug truth explicit.

**Folders Created/Deleted/Modified:**
- `assets/`
- `src/detectors/`
- `.testbed/scripts/`
- `.testbed/tests/unit/`

**Files Created/Deleted/Modified:**
- `assets/boxing.gesture_detection.yaml`
- `assets/flow.gesture_detection.yaml`
- `src/detectors/pose_detector_substrate.gd`
- `src/detectors/prototype_punch_matcher.gd`
- `src/detectors/learned_punch_classifier.gd`
- `.testbed/scripts/proving_harness.gd`
- `.testbed/tests/unit/test_camera_tracking_config_profiles.gd`
- `.testbed/tests/unit/test_pose_detector_substrate.gd`
- `.testbed/tests/unit/test_boxing_proving_harness_profiles_and_debug.gd`
- `.plans/2026-06-18-learned-classifier-family-specific-feature-branch.md`

**Status:** ✅ Complete

**Results:** Implemented the approved family-first contract. The shipped boxing/flow YAML now uses per-family `backend` + `threshold`/`prototype`/`classifier` blocks with the existing comment style preserved, and `mixed_family` is no longer a user-facing mode in the canonical config. Runtime routing in `pose_detector_substrate.gd` is now per-family: punch families can mix threshold/prototype/classifier selections naturally, debug truth reports per-family routing explicitly, and non-punch families stay honest by only activating the real threshold runtime while leaving placeholder prototype/classifier blocks as documented shape. `prototype_punch_matcher.gd` and `learned_punch_classifier.gd` now resolve the renamed backend labels, preserve legacy aliases where practical, and the straight-family classifier path now prefers the intended straight-family config/artifact source instead of falling through stale shared learned paths. Proving-harness runtime overrides were updated to write the approved family-first shape, and the focused unit coverage was updated to validate the renamed contract plus the straight-path selection fix.

Validation run:
- `godot --headless --path .testbed --script addons/aerobeat-vendor-godot-unit-test/gut_cmdln.gd -gtest=res://tests/unit/test_camera_tracking_config_profiles.gd`
- `godot --headless --path .testbed --script addons/aerobeat-vendor-godot-unit-test/gut_cmdln.gd -gtest=res://tests/unit/test_pose_detector_substrate.gd -gunit_test_name=test_prototype_matcher_backend_emits_side_aware_straight_and_surfaces_debug_state`
- `godot --headless --path .testbed --script addons/aerobeat-vendor-godot-unit-test/gut_cmdln.gd -gtest=res://tests/unit/test_pose_detector_substrate.gd -gunit_test_name=test_learned_classifier_backend_emits_and_surfaces_truthful_debug_state`
- `godot --headless --path .testbed --script addons/aerobeat-vendor-godot-unit-test/gut_cmdln.gd -gtest=res://tests/unit/test_pose_detector_substrate.gd -gunit_test_name=test_mixed_family_backend_routes_straights_to_learned_classifier_and_surfaces_truth`
- `godot --headless --path .testbed --script addons/aerobeat-vendor-godot-unit-test/gut_cmdln.gd -gtest=res://tests/unit/test_pose_detector_substrate.gd -gunit_test_name=test_mixed_family_backend_prefers_explicit_straight_artifact_path_over_learned_classifier_model_path`
- `godot --headless --path .testbed --script addons/aerobeat-vendor-godot-unit-test/gut_cmdln.gd -gtest=res://tests/unit/test_boxing_proving_harness_profiles_and_debug.gd -gunit_test_name=test_proving_runtime_config_can_force_prototype_matcher_backend_for_fixture_benchmarks`
- `godot --headless --path .testbed --script addons/aerobeat-vendor-godot-unit-test/gut_cmdln.gd -gtest=res://tests/unit/test_boxing_proving_harness_profiles_and_debug.gd -gunit_test_name=test_proving_runtime_config_can_force_mixed_family_backend_for_fixture_benchmarks`
- `godot --headless --path .testbed --script addons/aerobeat-vendor-godot-unit-test/gut_cmdln.gd -gtest=res://tests/unit/test_boxing_proving_harness_profiles_and_debug.gd -gunit_test_name=test_proving_runtime_config_can_force_learned_classifier_backend_for_fixture_benchmarks`

---

### Task 47: QA mixed-family fix and renamed config contract

**Bead ID:** `aerobeat-input-camera-tracking-rx3t`  
**SubAgent:** `primary` (for `qa`)  
**Role:** `qa`  
**References:** `REF-02`, `REF-03`, `REF-05`, `REF-06`  
**Prompt:** Verify the multi-classifier bug fix, backend renames, and broader per-family config-contract cleanup in the highest-fidelity validation path available. Confirm the intended straight model path now loads under the renamed multi-classifier path, that each gesture family now owns its own readable backend/config surface, that families without multiple real engines still resolve honestly, and that the YAML comments match the actual runtime behavior.

**Folders Created/Deleted/Modified:**
- relevant repo/test/artifact paths used during QA

**Files Created/Deleted/Modified:**
- QA notes/artifacts as needed

**Status:** ⏳ Pending

**Results:** Pending.

---

### Task 48: Audit mixed-family fix and config/runtime contract

**Bead ID:** `aerobeat-input-camera-tracking-69v9`  
**SubAgent:** `primary` (for `auditor`)  
**Role:** `auditor`  
**References:** `REF-02`, `REF-03`, `REF-05`, `REF-06`  
**Prompt:** Independently truth-check the multi-classifier runtime bug fix plus the renamed per-family config/runtime contract. Confirm the final behavior is honest, that the comments/docs now match reality, that each gesture family’s backend/config ownership is explicit, and that any families still limited to threshold/runtime-singleton behavior are clearly called out instead of hidden by the new naming.

**Folders Created/Deleted/Modified:**
- relevant repo/test/artifact paths used during audit

**Files Created/Deleted/Modified:**
- audit notes/artifacts as needed

**Status:** ⏳ Pending

**Results:** Pending.

---

### Task 49: Remove legacy gesture-config compatibility, add disabled backend, and tighten proving inspector backend switching

**Bead ID:** `aerobeat-input-camera-tracking-3fws`  
**SubAgent:** `primary` (for `coder`)  
**Role:** `coder`  
**References:** `REF-02`, `REF-03`, `REF-05`, `REF-06`  
**Prompt:** Follow up immediately on the newly landed family-first backend contract with three targeted adjustments Derrick requested after review: (1) remove compatibility holdovers for the older YAML/config shape instead of keeping the legacy migration layer, (2) add a new per-family backend value `disabled` that cleanly prevents that gesture family from firing, and (3) make sure the boxing proving scene inspectors / gesture detail panels swap truthfully with the newly selected backend per family, so a family set to `threshold` does not show classifier info and a family set to `prototype` does not show threshold/classifier panels. Keep the repo’s comment style, preserve the new `threshold` / `prototype` / `classifier` naming, and keep runtime/debug truth explicit.

**Folders Created/Deleted/Modified:**
- `assets/`
- `src/detectors/`
- `.testbed/scripts/`
- `.testbed/tests/unit/`

**Files Created/Deleted/Modified:**
- `assets/boxing.gesture_detection.yaml`
- `assets/flow.gesture_detection.yaml`
- `src/detectors/pose_detector_substrate.gd`
- `src/detectors/prototype_punch_matcher.gd`
- `src/detectors/learned_punch_classifier.gd`
- `.testbed/scripts/proving_harness.gd`
- `.testbed/scripts/boxing_proving_harness.gd`
- `.testbed/tests/unit/test_pose_detector_substrate.gd`
- `.testbed/tests/unit/test_boxing_proving_harness_profiles_and_debug.gd`
- `.testbed/tests/unit/test_camera_tracking_config_profiles.gd`
- `.testbed/tests/unit/test_aero_camera_tracking.gd`
- `.testbed/tests/unit/test_camera_tracking_provider.gd`
- `.testbed/tests/unit/test_proving_harness_fixture_timeline.gd`
- `.plans/2026-06-18-learned-classifier-family-specific-feature-branch.md`

**Status:** ✅ Complete

**Results:** Removed old-shape `punch_detection` / legacy backend-name compatibility reads from the detector/runtime/proving paths, added canonical `backend: disabled` handling so disabled families do not emit, and tightened the boxing proving/event-detail routing so prototype/classifier panels only render for the selected family backend with threshold/per-family disabled states reported honestly. Updated focused unit coverage for disabled-family runtime suppression, family-specific classifier artifact selection, proving override/config loading, canonical proving timeline/debug payloads, and backend-specific boxing inspector/event-feed switching. Validation passed with `godot --headless --path .testbed --script addons/aerobeat-vendor-godot-unit-test/gut_cmdln.gd -gtest=res://tests/unit/test_pose_detector_substrate.gd -gtest=res://tests/unit/test_boxing_proving_harness_profiles_and_debug.gd -gtest=res://tests/unit/test_camera_tracking_config_profiles.gd -gtest=res://tests/unit/test_aero_camera_tracking.gd -gtest=res://tests/unit/test_proving_harness_fixture_timeline.gd -gtest=res://tests/unit/test_camera_tracking_provider.gd -gexit` (145/145 passed; existing GUT orphan warnings remained).

---

### Task 50: QA disabled backend and proving inspector backend switching

**Bead ID:** `aerobeat-input-camera-tracking-i1os`  
**SubAgent:** `primary` (for `qa`)  
**Role:** `qa`  
**References:** `REF-02`, `REF-03`, `REF-05`, `REF-06`  
**Prompt:** Verify the follow-up family-first contract patch in the highest-fidelity validation path available. Confirm old-shape compatibility has actually been removed, confirm `backend: disabled` prevents the relevant family from firing, and confirm the boxing proving inspectors swap cleanly with the selected backend per family so only the active backend’s panel/info is shown.

**Folders Created/Deleted/Modified:**
- `.temp/qa-task50/`

**Files Created/Deleted/Modified:**
- `.temp/qa-task50/gut-task50.log`
- `.plans/2026-06-18-learned-classifier-family-specific-feature-branch.md`

**Status:** ✅ Complete

**Results:** QA reran the highest-fidelity repo-local headless coverage on landed `main` at `831d9bc` with `godot --headless --path .testbed --script addons/aerobeat-vendor-godot-unit-test/gut_cmdln.gd -gtest=res://tests/unit/test_pose_detector_substrate.gd -gtest=res://tests/unit/test_boxing_proving_harness_profiles_and_debug.gd -gtest=res://tests/unit/test_camera_tracking_config_profiles.gd -gtest=res://tests/unit/test_aero_camera_tracking.gd -gexit` and captured the log at `.temp/qa-task50/gut-task50.log`. Result: **130/130 tests passed**.

Static QA scan plus the passing config/runtime tests support that the old flat/shared punch-backend config compatibility path is gone in the landed family-first contract: `src/config/camera_tracking_config.gd` now loads `result["gesture_detection"]` directly into `gesture_profile_document`, and `src/detectors/pose_detector_substrate.gd`, `src/detectors/prototype_punch_matcher.gd`, and `src/detectors/learned_punch_classifier.gd` resolve backends from per-family documents (`straight_punch` / `hook` / `uppercut`) instead of reading a legacy top-level shared punch backend selector. Automated QA cannot prove every historical caller is migrated, but within this repo’s landed runtime/testbed path I did not find a surviving old-shape fallback read.

Goal-by-goal evidence:
- **Old-shape compatibility removed:** covered by the static scan above plus `res://tests/unit/test_camera_tracking_config_profiles.gd` and the family-first runtime assertions in `res://tests/unit/test_pose_detector_substrate.gd`.
- **`backend: disabled` really prevents firing:** verified by passing `test_disabled_family_backend_prevents_any_punch_runtime_activation`, `test_disabled_straight_family_suppresses_punch_events_while_threshold_families_stay_live`, `test_proving_runtime_config_can_force_disabled_backend_for_fixture_benchmarks`, and `test_boxing_event_feed_makes_disabled_selected_backend_resolve_to_none_obvious`.
- **Boxing inspectors / gesture detail panels swap cleanly by active backend:** verified by passing `test_boxing_prototype_hover_card_surfaces_backend_score_threshold_and_gate_truth`, `test_boxing_classifier_hover_card_and_event_feed_surface_truthful_backend_specific_fields`, `test_boxing_classifier_hook_and_uppercut_cards_use_backend_truth_instead_of_pose_only_panels`, and `test_per_family_classifier_match_payload_uses_per_family_backend_truth`. These prove only the active backend’s truth/panel fields are surfaced for the relevant family in the headless proving UI contract.
- **Straight-family classifier path still resolves under family-first shape:** verified by passing `test_per_family_backend_routes_straights_to_classifier_and_surfaces_truth`, `test_per_family_backend_prefers_straight_family_classifier_artifact_path`, and `test_classifier_repo_root_docs_path_falls_back_to_addon_mount_in_testbed`.

Honest limit: this QA pass gives strong automated confidence in the landed repo-local config/runtime/proving contract, but it does **not** replace Derrick’s manual Cookie replay/live validation for real camera behavior quality, latency, or human-visible proving UX outside the headless harness contract.

---

### Task 51: Audit disabled backend and proving inspector backend switching

**Bead ID:** `aerobeat-input-camera-tracking-0hag`  
**SubAgent:** `primary` (for `auditor`)  
**Role:** `auditor`  
**References:** `REF-02`, `REF-03`, `REF-05`, `REF-06`  
**Prompt:** Independently truth-check the follow-up family-first contract patch. Confirm the legacy YAML compatibility layer is gone, confirm `disabled` is a real non-firing backend state rather than cosmetic config, and confirm proving inspector/backend detail surfaces now track the selected backend honestly per gesture family.

**Folders Created/Deleted/Modified:**
- `.temp/`
- `src/config/`
- `src/detectors/`
- `.testbed/scripts/`
- `.testbed/tests/unit/`
- `assets/`

**Files Created/Deleted/Modified:**
- `.temp/audit-task51-gut.log`
- `.plans/2026-06-18-learned-classifier-family-specific-feature-branch.md`
- `src/config/camera_tracking_config.gd`
- `src/config/profile_config_loader.gd`
- `src/detectors/pose_detector_substrate.gd`
- `src/detectors/prototype_punch_matcher.gd`
- `src/detectors/learned_punch_classifier.gd`
- `.testbed/scripts/boxing_proving_harness.gd`
- `.testbed/tests/unit/test_pose_detector_substrate.gd`
- `.testbed/tests/unit/test_boxing_proving_harness_profiles_and_debug.gd`
- `.testbed/tests/unit/test_camera_tracking_config_profiles.gd`
- `assets/boxing.gesture_detection.yaml`

**Status:** ✅ Complete

**Results:** Independent audit passed on landed `main` at `831d9bc` (`Tighten family backend config and proving routing`). I reran the same focused headless coverage the QA pass used and captured a fresh audit log at `.temp/audit-task51-gut.log` via `godot --headless --path .testbed --script addons/aerobeat-vendor-godot-unit-test/gut_cmdln.gd -gtest=res://tests/unit/test_pose_detector_substrate.gd -gtest=res://tests/unit/test_boxing_proving_harness_profiles_and_debug.gd -gtest=res://tests/unit/test_camera_tracking_config_profiles.gd -gtest=res://tests/unit/test_aero_camera_tracking.gd -gexit`; result: **130/130 tests passed**.

Audit findings by goal:
- **Legacy YAML/config compatibility layer gone from the landed runtime path:** confirmed by code inspection plus passing config/runtime tests. `src/config/camera_tracking_config.gd` now stores `result["gesture_detection"]` directly as the runtime `gesture_profile_document`, and the punch runtime reads family documents directly (`straight_punch` / `hook` / `uppercut`) instead of consulting a legacy top-level shared punch backend selector. `src/detectors/pose_detector_substrate.gd` resolves routing through `_get_family_document()` / `_get_punch_backend_for_family()`. `src/detectors/prototype_punch_matcher.gd` and `src/detectors/learned_punch_classifier.gd` both enumerate selected families with `_get_selected_families_for_backend()` and read backend blocks with `_get_family_backend_config()`. In the landed runtime/proving path I did **not** find a surviving fallback read of old punch-backend YAML shape.
- **`backend: disabled` is real, not cosmetic:** confirmed in runtime code and tests. `src/detectors/pose_detector_substrate.gd` only executes threshold/prototype/classifier work when a family actually selects those backends, and `_filter_events_for_backend()` only allows events for families mapped to that backend. When all punch families are `disabled`, `punch_detection` debug now reports `selected_backend_enabled=false`, `active_backend=none`, and `active_backend_resolution=no_active_family_backend`. Passing proof points: `test_disabled_family_backend_prevents_any_punch_runtime_activation`, `test_disabled_straight_family_suppresses_punch_events_while_threshold_families_stay_live`, `test_proving_runtime_config_can_force_disabled_backend_for_fixture_benchmarks`, and `test_boxing_event_feed_makes_disabled_selected_backend_resolve_to_none_obvious`.
- **Proving inspector/backend detail surfaces track the selected backend honestly per family:** confirmed by code inspection plus passing UI-contract tests. `.testbed/scripts/boxing_proving_harness.gd` now routes each punch card through `_punch_backend_for_event()` and selects threshold/prototype/classifier hover-card models per family/event instead of showing one shared punch panel. The event feed also prints per-family routing truth (`straight=%s hook=%s uppercut=%s`) plus `Selected backend enabled` and `Backend resolution`. Passing proof points: `test_boxing_prototype_hover_card_surfaces_backend_score_threshold_and_gate_truth`, `test_boxing_classifier_hover_card_and_event_feed_surface_truthful_backend_specific_fields`, `test_boxing_classifier_hook_and_uppercut_cards_use_backend_truth_instead_of_pose_only_panels`, `test_per_family_classifier_match_payload_uses_per_family_backend_truth`, and `test_boxing_event_feed_makes_disabled_selected_backend_resolve_to_none_obvious`.
- **Family-first contract is now honest about readiness / unsupported combinations:** `assets/boxing.gesture_detection.yaml` explicitly limits non-punch families to threshold as the only real runtime today, while punch families document threshold/prototype/classifier as real selectable runtime surfaces. That honesty matches the runtime: non-punch families still normalize to threshold by default, while punch families resolve per-family backends and expose truthful debug about whether any active backend exists. The config comments no longer claim an unavailable mixed/shared selector path. I do not see evidence of the landed contract overstating support for unsupported punch-family/backend combinations inside this repo path.

What is now proven vs. still manual:
- **Proven by code/tests in-repo:** the legacy punch-backend compatibility read is gone from the landed runtime/testbed path; `backend: disabled` suppresses punch runtime activation and makes the non-active state explicit in debug/proving surfaces; per-family proving cards/event text now follow the selected backend truthfully; straight-family classifier artifact selection still resolves correctly under the family-first shape.
- **Still requires Derrick’s manual Cookie validation:** real camera/replay behavior on Cookie, human-visible proving UX under live interaction, perceived latency/smoothness, and whether the selected family/backend behavior feels correct with real motion input outside the headless contract. The automated audit proves the shipped code path and UI truth contract, not the final subjective/live-device experience.

---

### Task 52: Fix proving_harness untyped iterator warning for family backend overrides

**Bead ID:** `aerobeat-input-camera-tracking-1pqo`  
**SubAgent:** `primary` (for `coder`)  
**Role:** `coder`  
**References:** `REF-02`, `REF-03`, `REF-05`, `REF-06`  
**Prompt:** Derrick reported a concrete warning when opening the boxing proving scene after the family-first backend rollout: `UNTYPED_DECLARATION` in `.testbed/scripts/proving_harness.gd` at the family-backend override loop (`for` iterator variable `family_name` has no static type). Fix that warning cleanly without regressing the new family-first backend override behavior. Update the active plan with exact files changed/results, run the narrowest truthful validation for this warning/regression, commit/push by default, and close bead `aerobeat-input-camera-tracking-1pqo` with a clear reason when done.

**Folders Created/Deleted/Modified:**
- `.testbed/scripts/`
- `.plans/`

**Files Created/Deleted/Modified:**
- `.testbed/scripts/proving_harness.gd`
- `.plans/2026-06-18-learned-classifier-family-specific-feature-branch.md`

**Status:** ✅ Complete

**Results:** Fixed the warning by introducing a typed shared family-name constant (`PROVING_GESTURE_FAMILY_NAMES: Array[String]`) and reusing it in both family override loops inside `_apply_runtime_gesture_backend_override()`. That removes the untyped inline-array iterator at the warning site without changing the family-first contract or the set of families affected by backend/library overrides. I deliberately did **not** widen scope or add new tests because existing targeted proving-harness coverage already asserts the relevant per-family override behavior.

Validation run:
- `godot --headless --path .testbed --script addons/aerobeat-vendor-godot-unit-test/gut_cmdln.gd -gtest=res://tests/unit/test_boxing_proving_harness_profiles_and_debug.gd -gexit`
- Result: **38/38 tests passed**.
- Warning check: grep of the captured output found no `UNTYPED_DECLARATION`, `family_name`, or `GDScript::reload` warning lines, which is the narrowest truthful automated proof I could gather for the reported reload/open warning in this repo-local path.

---

### Task 53: QA proving_harness warning fix

**Bead ID:** `aerobeat-input-camera-tracking-i09r`  
**SubAgent:** `primary` (for `qa`)  
**Role:** `qa`  
**References:** `REF-02`, `REF-03`, `REF-05`, `REF-06`  
**Prompt:** Verify the proving_harness untyped-iterator warning fix. Confirm the warning is gone on reload/open, confirm family-backend override behavior still works, and state clearly what was proven in automation.

**Folders Created/Deleted/Modified:**
- `.temp/qa-task53/`
- relevant repo/test/artifact paths used during QA

**Files Created/Deleted/Modified:**
- `.temp/qa-task53/gut-task53.log`
- `.plans/2026-06-18-learned-classifier-family-specific-feature-branch.md`

**Status:** ✅ Complete

**Results:** QA reran the narrowest truthful repo-local validation path for the reported warning on current `main` (`dadab1a`, with the fix itself at `a3bf13c`): `godot --headless --path .testbed --script addons/aerobeat-vendor-godot-unit-test/gut_cmdln.gd -gtest=res://tests/unit/test_boxing_proving_harness_profiles_and_debug.gd -gexit`, capturing the output at `.temp/qa-task53/gut-task53.log`. Result: **38/38 tests passed**.

The warning-producing proving-harness load/reload path now looks clean in automation. The landed code still contains the typed shared family-name constant at the original site (`.testbed/scripts/proving_harness.gd`: `PROVING_GESTURE_FAMILY_NAMES: Array[String] = ["straight_punch", "hook", "uppercut"]`), and a direct log scan of `.temp/qa-task53/gut-task53.log` found **no** `UNTYPED_DECLARATION`, `family_name`, `GDScript::reload`, or `.testbed/scripts/proving_harness.gd:` warning lines. The run did emit unrelated pre-existing addon UID / leaked-RID warnings, but none were the reported proving-harness iterator warning.

Family-backend override behavior still works after the typing fix. The same focused suite passed the three override tests `test_proving_runtime_config_can_force_prototype_backend_for_fixture_benchmarks`, `test_proving_runtime_config_can_force_disabled_backend_for_fixture_benchmarks`, and `test_proving_runtime_config_can_force_classifier_backend_for_fixture_benchmarks`, plus `test_boxing_event_feed_reports_per_family_routing_truth`, which is the narrowest existing automated proof in-repo that the family-first proving override path still mutates per-family backend selection correctly and that the proving/event-feed surface still reports the resulting routing truth.

What this automation **does** prove: the proving harness script reloads/executes cleanly in the focused headless path without reproducing the specific untyped-iterator warning signature, and the family-backend override contract covered by the focused proving-harness tests still passes after the typing change. What it **does not** prove: a literal interactive Godot editor open/reload click-path outside this headless script-load path. For repo-local automation, this is the narrowest truthful pass I could make without widening scope into manual GUI work.

---

### Task 54: Audit proving_harness warning fix

**Bead ID:** `aerobeat-input-camera-tracking-xron`  
**SubAgent:** `primary` (for `auditor`)  
**Role:** `auditor`  
**References:** `REF-02`, `REF-03`, `REF-05`, `REF-06`  
**Prompt:** Independently truth-check the proving_harness warning fix. Confirm the warning-producing code path is corrected, the family-backend override logic still behaves honestly, and no new ambiguity was introduced in the proving path.

**Folders Created/Deleted/Modified:**
- `.temp/audit-task54/`
- `.plans/`

**Files Created/Deleted/Modified:**
- `.temp/audit-task54/gut-task54.log`
- `.plans/2026-06-18-learned-classifier-family-specific-feature-branch.md`

**Status:** ✅ Complete

**Results:** Independent audit passed on current `main` at `dadab1a` against the landed fix commit `a3bf13c` (`Fix proving harness family override iterator typing`). I inspected the exact patch with `git show a3bf13c -- .testbed/scripts/proving_harness.gd` and confirmed the runtime code change is narrowly behavioral-neutral: the two warning-site loops in `_apply_runtime_gesture_backend_override()` now iterate over a typed shared constant, `PROVING_GESTURE_FAMILY_NAMES: Array[String] = ["straight_punch", "hook", "uppercut"]`, instead of an untyped inline array literal. The family set is unchanged, the loop bodies are unchanged, and `git diff a3bf13c..HEAD -- .testbed/scripts/proving_harness.gd` is empty, so the warning fix itself is still present on current `main` with no later proving-harness drift.

I then reran the focused proving-harness suite headlessly and captured the output at `.temp/audit-task54/gut-task54.log` via `godot --headless --path .testbed --script addons/aerobeat-vendor-godot-unit-test/gut_cmdln.gd -gtest=res://tests/unit/test_boxing_proving_harness_profiles_and_debug.gd -gexit`. Result: **38/38 tests passed**. That rerun re-proved the family-backend override contract that matters for this warning seam: `test_proving_runtime_config_can_force_prototype_backend_for_fixture_benchmarks`, `test_proving_runtime_config_can_force_disabled_backend_for_fixture_benchmarks`, and `test_proving_runtime_config_can_force_classifier_backend_for_fixture_benchmarks` all passed, confirming the proving override still writes the same backend choice across `straight_punch`, `hook`, and `uppercut` after the typing change. I also scanned the captured log for `UNTYPED_DECLARATION`, `family_name`, `GDScript::reload`, and `.testbed/scripts/proving_harness.gd:` warning lines and found none. The run still emits unrelated pre-existing addon UID warnings plus orphan/leaked-RID noise, but not the reported proving-harness iterator warning.

On ambiguity: I did not find any new ambiguity introduced by this patch in the proving path. The patch touches only `.testbed/scripts/proving_harness.gd`; it does not alter `boxing_proving_harness.gd`, substrate backend truth, or runtime routing behavior. The override path remains explicit and honest: `_apply_runtime_gesture_backend_override()` still applies one override value uniformly to the three punch families, still writes the straight-classifier artifact path only into `straight_punch.classifier.model.artifact_path`, and still applies prototype library overrides uniformly across the same typed family list.

What this audit **does prove**: the specific warning-producing untyped iterator site was removed in committed code; the focused script-load/test path no longer reproduces the warning signature; the family-backend override behavior covered by committed proving-harness tests still behaves the same after the typing fix; and no additional proving-path behavior changes were bundled into this patch. What this audit **does not prove**: a literal manual Godot editor open/reload click-path outside the headless repo-local load/test route, or broader UX clarity beyond the existing committed proving/debug surfaces.

---

### Task 55: Implement same-family mutual exclusion gate for boxing gesture families

**Bead ID:** `aerobeat-input-camera-tracking-zxmv`  
**SubAgent:** `primary` (for `coder`)  
**Role:** `coder`  
**References:** `REF-02`, `REF-03`, `REF-05`, `REF-06`  
**Prompt:** Derrick wants same-family mutual exclusion during firing: if one gesture in a family is actively firing (for example `straight_left`), the opposite-side gesture from that same family (`straight_right`) should not be allowed to fire simultaneously. Implement a narrow family-level exclusivity gate for boxing gesture families, starting with the concrete left/right family pairs where simultaneous co-fire is undesirable. Keep the behavior/debug truth explicit so proving surfaces can explain when a candidate was suppressed because another gesture in the same family was already firing.

**Folders Created/Deleted/Modified:**
- `src/detectors/`
- `.testbed/tests/unit/`
- `.plans/`

**Files Created/Deleted/Modified:**
- `src/detectors/prototype_punch_matcher.gd`
- `src/detectors/learned_punch_classifier.gd`
- `src/detectors/pose_detector_substrate.gd`
- `.testbed/tests/unit/test_pose_detector_substrate.gd`
- `.plans/2026-06-18-learned-classifier-family-specific-feature-branch.md`

**Status:** ✅ Complete

**Results:** Added a narrow same-family exclusivity gate for boxing left/right pairs in the active firing window. The prototype matcher and learned classifier now suppress opposite-side candidates from the same family while the current family hold window is active and report truthful debug reasons (`same_family_active`) plus blocking class/family metadata. The threshold straight/hook/uppercut state machines now carry matching same-family block metadata helpers so a suppressed threshold-side candidate can be explained honestly when another side in the same family is active. Focused unit coverage was added for prototype and classifier suppression plus threshold blocking truth metadata. Validation: `godot --headless --path .testbed --script addons/aerobeat-vendor-godot-unit-test/gut_cmdln.gd -gtest=res://tests/unit/test_pose_detector_substrate.gd -gexit` (75/75 passed).

---

### Task 56: QA same-family mutual exclusion gate

**Bead ID:** `aerobeat-input-camera-tracking-c90z`  
**SubAgent:** `primary` (for `qa`)  
**Role:** `qa`  
**References:** `REF-02`, `REF-03`, `REF-05`, `REF-06`  
**Prompt:** Verify the same-family mutual exclusion gate in the highest-fidelity repo-local path available. Confirm that when one side of a family is already firing, the opposite-side gesture from the same family is suppressed, and confirm proving/runtime truth surfaces explain that suppression honestly.

**Folders Created/Deleted/Modified:**
- `.temp/qa-task56/`
- `.plans/`

**Files Created/Deleted/Modified:**
- `.temp/qa-task56/gut-task56.log`
- `.temp/qa-task56/verify_same_family_gate.gd`
- `.temp/qa-task56/verify-same-family.log`
- `.plans/2026-06-18-learned-classifier-family-specific-feature-branch.md`

**Status:** ✅ Complete

**Results:** QA passed on the highest-fidelity repo-local/headless path currently available for this edge case: focused substrate/runtime unit coverage plus one disposable headless verifier for the last “unrelated families are not blocked by the new rule” gap. I reran `godot --headless --path .testbed --script addons/aerobeat-vendor-godot-unit-test/gut_cmdln.gd -gtest=res://tests/unit/test_pose_detector_substrate.gd -gexit` and saved the output to `.temp/qa-task56/gut-task56.log`; result: **75/75 tests passed** on commit `dadab1a`. That automated pass directly proves the three claimed supported paths from Task 55:
- **Prototype path:** `test_prototype_backend_blocks_opposite_side_same_family_candidate_during_hold` proves a `straight_right` prototype candidate is suppressed while `straight_left` is still active, with truthful matcher debug showing `reason=same_family_active`, `same_family_blocked=true`, `blocking_family=straight_punch`, `blocking_class=straight_left`, and `active_event_class=straight_left`.
- **Classifier path:** `test_classifier_backend_blocks_opposite_side_same_family_candidate_during_hold` proves the same suppression/truth contract for the learned classifier path, again surfacing `same_family_active`, the blocking family/class, and the active event class rather than silently swallowing the candidate.
- **Threshold path:** `test_hook_same_family_trigger_exposes_threshold_blocking_truth` proves the threshold-side family helper returns truthful suppression metadata (`blocking_family`, `blocking_side`, `blocking_event_name`, `blocking_phase`) when the opposite side of the same family is already in the triggered/grace window.

For goal (4), the focused committed suite did **not** include an explicit “unrelated family should not be marked same-family-blocked” assertion, so I added a disposable repo-local verifier at `.temp/qa-task56/verify_same_family_gate.gd` and ran it headlessly, saving output to `.temp/qa-task56/verify-same-family.log`. That verifier proved three narrower truths:
- `PrototypePunchMatcher._get_same_family_blocking_class("hook_right", 1200)` returns empty while `straight_left` is active, so the new prototype same-family gate itself does **not** mark unrelated hook candidates as blocked.
- `LearnedPunchClassifier._get_same_family_blocking_class("hook_right", 1200)` also returns empty while `straight_left` is active, and the resulting classifier debug does **not** report `reason=same_family_active` or populate `blocking_family` for that unrelated hook candidate. Important nuance: the classifier can still suppress that unrelated candidate for the older global `emit_hold_active` reason, so automation proves “not blocked by the new same-family rule,” not “guaranteed to emit during any existing global hold/cooldown gate.”
- `PoseDetectorSubstrate._get_same_family_threshold_blocking_state("hook", "left", 3320)` returns empty when only `straight_punch/right` is active, so the threshold helper also keeps the family boundary honest.

Truth-surface readout: runtime/proving code inspection plus the committed code paths show the suppression reason is exposed honestly where the patch claims support. `prototype_punch_matcher.gd` and `learned_punch_classifier.gd` both now stamp `same_family_active` plus `blocking_family` / `blocking_class` / `active_event_class` into debug state, `pose_detector_substrate.gd` carries matching threshold-side fields (`same_family_blocked`, `blocking_family`, `blocking_side`, `blocking_event_name`, `blocking_phase`), and `.testbed/scripts/boxing_proving_harness.gd` already surfaces gate reason / hold / cooldown / active event class in the classifier truth panels. I did **not** find an existing committed headless proving replay fixture that naturally creates simultaneous opposite-side same-family candidates, so the focused substrate path is the highest-fidelity automated route available in-repo for this particular co-fire edge case.

What automated QA proves vs. what still needs Derrick on Cookie:
- **Proven automatically now:** the new same-family gate suppresses opposite-side same-family candidates in the prototype and classifier paths; threshold-family runtime state exposes the suppression metadata truthfully; unrelated families are not mislabeled by the *new* same-family gate; and the debug/proving surfaces have the needed fields/reasons to explain the suppression instead of hiding it.
- **Still needs Derrick’s manual Cookie validation:** real replay/live-camera behavior under human motion, whether the proving UI exposes the suppression clearly enough during actual simultaneous-ish play, and whether the remaining older global timing gates (`emit_hold_active`, cooldowns, threshold grace windows) feel correct in practice once same-family suppression is layered on top.

---

### Task 57: Audit same-family mutual exclusion gate

**Bead ID:** `aerobeat-input-camera-tracking-6z5o`  
**SubAgent:** `primary` (for `auditor`)  
**Role:** `auditor`  
**References:** `REF-02`, `REF-03`, `REF-05`, `REF-06`  
**Prompt:** Independently truth-check the same-family mutual exclusion gate. Confirm the runtime no longer allows simultaneous same-family co-fire where blocked by the new rule, and confirm any suppression reasoning exposed in proving/debug surfaces matches the actual runtime behavior.

**Folders Created/Deleted/Modified:**
- `.temp/audit-task57/`
- relevant repo/test/artifact paths inspected during audit

**Files Created/Deleted/Modified:**
- `.temp/audit-task57/gut-task57.log`
- `.temp/audit-task57/verify_same_family_audit.gd`
- `.temp/audit-task57/verify-same-family-audit.log`
- `.plans/2026-06-18-learned-classifier-family-specific-feature-branch.md`

**Status:** ✅ Complete

**Results:** Audit passed on landed commit `dadab1a` after an independent code+rerun check. I reran `godot --headless --path .testbed --script addons/aerobeat-vendor-godot-unit-test/gut_cmdln.gd -gtest=res://tests/unit/test_pose_detector_substrate.gd -gexit` and captured the log at `.temp/audit-task57/gut-task57.log`; result: **75/75 tests passed**. That committed suite directly proves the positive support claims from Task 55: prototype and learned-classifier same-family suppression both prevent opposite-side straight co-fire during the active hold window and stamp honest debug truth (`reason = same_family_active`, `same_family_blocked = true`, `blocking_family = straight_punch`, `blocking_class = straight_left`, `active_event_class = straight_left`), while the threshold-family helper/state path exposes matching same-family metadata for hook-family blocking (`blocking_family`, `blocking_side`, `blocking_event_name`, `blocking_phase`).

I also added and ran a disposable independent verifier at `.temp/audit-task57/verify_same_family_audit.gd`, captured in `.temp/audit-task57/verify-same-family-audit.log` with result `AUDIT_TASK57_OK`. That verifier re-proved the same-family positive cases without trusting only the GUT assertions and closed the unrelated-family audit gap explicitly: prototype and classifier both suppress `straight_right` while `straight_left` is active and preserve truthful suppression metadata, the threshold hook helper/state metadata remain honest when `hook_right` is the active blocker, and unrelated families are **not** mislabeled by the new gate (`hook_right` is not same-family-blocked while `straight_left` is active in prototype/classifier, and `_get_same_family_threshold_blocking_state("hook", "left", ...)` stays empty while a `straight_punch` opposite side is active).

Important nuance from the independent negative check: the classifier can still refuse an unrelated-family candidate for the older global timing gates (`emit_hold_active` / cooldown) depending on runtime state. What this audit proves is narrower and honest: unrelated families are not being rejected **because of the new same-family rule** when the candidate family differs from the active family.

Code inspection matches the reruns. In `src/detectors/prototype_punch_matcher.gd` and `src/detectors/learned_punch_classifier.gd`, `_get_same_family_blocking_class(...)` only returns a blocker when the candidate class maps to the same gesture family as `_last_emitted_class` and the hold window is still active; both detectors then stamp `same_family_active`, `blocking_family`, `blocking_class`, and `active_event_class` into debug state. In `src/detectors/pose_detector_substrate.gd`, `_get_same_family_threshold_blocking_state(...)` only reports the opposite side inside the same family while that side is still in `triggered`, and `_apply_same_family_block(...)` copies that truth into threshold-side debug fields (`same_family_blocked`, `blocking_family`, `blocking_side`, `blocking_event_name`, `blocking_phase`). `.testbed/scripts/boxing_proving_harness.gd` already surfaces the classifier gate/hold/cooldown/active-event-class truth used for the learned path; threshold same-family metadata is present in substrate debug state but still primarily proven here via headless substrate inspection rather than a dedicated proving replay fixture.

What is proven now vs. what still needs Derrick on Cookie:
- **Proven automatically by code/tests/reruns:** same-family co-fire suppression is real for the shipped prototype and learned-classifier support paths; threshold-family block metadata is internally truthful; suppression/debug metadata is honest for the supported paths; unrelated families are not mislabeled by the new same-family rule.
- **Still requires Derrick’s manual Cookie validation:** whether real replay/live motion produces the intended suppression feel under human timing, whether the proving UI makes the suppression easy to understand during actual play, and whether the interaction between same-family suppression and the pre-existing global timing gates feels correct in practice on device.

---

### Task 58: Fix straight threshold same-family co-fire and add wrist-lateral-angle guard gate

**Bead ID:** `aerobeat-input-camera-tracking-6fhm`  
**SubAgent:** `primary` (for `coder`)  
**Role:** `coder`  
**References:** `REF-02`, `REF-03`, `REF-05`, `REF-06`  
**Prompt:** Derrick’s latest feedback surfaced two follow-up issues from live testing: (1) the same-family mutual exclusion gate did not fully block opposite-side straight punches in the straight-right threshold test video—the first punch activated `straight_left`, then `straight_right` fired right after during the same active window; (2) replace the earlier elbow-joint-angle idea with a new straight threshold variable exactly named `min_wrist_lateral_angle_from_elbow_vertical_deg`, where the runtime measures how far the wrist deflects left/right from an elbow-anchored vertical ray in 2D camera space and rejects near-vertical guard-raise style motion when the angle is below the minimum. Implement a narrow fix for the threshold straight-family co-fire path and add the new threshold variable with truthful comment/style integration, runtime usage, and proving/debug truth as needed.

**Folders Created/Deleted/Modified:**
- `assets/`
- `src/detectors/`
- `.testbed/tests/unit/`
- `.plans/`

**Files Created/Deleted/Modified:**
- `assets/boxing.gesture_detection.yaml`
- `src/detectors/pose_detector_substrate.gd`
- `.testbed/tests/unit/test_pose_detector_substrate.gd`
- `.testbed/tests/unit/test_camera_tracking_config_profiles.gd`
- `.plans/2026-06-18-learned-classifier-family-specific-feature-branch.md`

**Status:** ✅ Complete

**Results:** Fixed the threshold straight-family suppression path so opposite-side same-family straights stay blocked while the blocking straight remains in `triggered` or `not_ready`, closing the co-fire hole that could reopen once grace timing rolled forward but before rearm completed. Replaced the abandoned elbow-joint-angle concept with `min_wrist_lateral_angle_from_elbow_vertical_deg`, wired it into straight-threshold config parsing plus runtime gating, and surfaced the live angle/gate truth in straight debug/state-change payloads. Refreshed focused unit coverage to prove both behaviors honestly: same-family opposite-side straight suppression during the active window and rejection when wrist motion stays too close to the elbow-anchored vertical ray. Validation run: `godot --headless --path .testbed --script addons/aerobeat-vendor-godot-unit-test/gut_cmdln.gd -gtest=res://tests/unit/test_pose_detector_substrate.gd -gexit` (77/77 passed) and `godot --headless --path .testbed --script addons/aerobeat-vendor-godot-unit-test/gut_cmdln.gd -gtest=res://tests/unit/test_camera_tracking_config_profiles.gd -gexit` (4/4 passed).

---

### Task 59: QA straight threshold co-fire fix and wrist lateral-angle threshold

**Bead ID:** `aerobeat-input-camera-tracking-o7zp`  
**SubAgent:** `primary` (for `qa`)  
**Role:** `qa`  
**References:** `REF-02`, `REF-03`, `REF-05`, `REF-06`  
**Prompt:** Verify the straight-threshold same-family co-fire fix and the new `min_wrist_lateral_angle_from_elbow_vertical_deg` variable. Confirm opposite-side straight punches are suppressed during the active same-family window in the threshold path, confirm the new lateral-angle threshold truthfully participates in the straight-threshold decision path, and confirm the YAML comment/name/style landed as approved in the repo-local validation path.

**Folders Created/Deleted/Modified:**
- `.temp/`

**Files Created/Deleted/Modified:**
- `.plans/2026-06-18-learned-classifier-family-specific-feature-branch.md`
- `.temp/qa-task59-gut.log`
- `.temp/qa-task59-static-scan.txt`
- inspected runtime/config/test sources only: `src/detectors/pose_detector_substrate.gd`, `assets/boxing.gesture_detection.yaml`, `.testbed/tests/unit/test_pose_detector_substrate.gd`, `.testbed/tests/unit/test_camera_tracking_config_profiles.gd`

**Status:** ✅ Complete

**Results:** Focused threshold-path QA passed on landed commit `7a4cc60`. Highest-fidelity repo-local automation for this narrow patch was the focused headless Godot unit path plus static source/config inspection. I reran `godot --headless --path .testbed --script addons/aerobeat-vendor-godot-unit-test/gut_cmdln.gd -gtest=res://tests/unit/test_pose_detector_substrate.gd,res://tests/unit/test_camera_tracking_config_profiles.gd -gexit`, saving the log to `.temp/qa-task59-gut.log`.

Patch-specific proof points passed cleanly inside `test_pose_detector_substrate.gd` (`77/77` passing in that file):
- `test_straight_same_family_trigger_exposes_threshold_blocking_truth_while_blocking_side_is_not_ready` proves the threshold straight path now suppresses `punch_right` while the opposite-side straight family member is still active in `not_ready`, with truthful debug metadata (`same_family_blocked=true`, `blocking_family=straight_punch`, `blocking_side=left`, `blocking_event_name=punch_left`, `blocking_phase=not_ready`). This directly covers Derrick’s reported co-fire hole where the opposite-side straight could previously slip through during the active same-family window.
- `test_straight_punch_requires_wrist_lateral_angle_from_elbow_vertical_gate_before_triggering` proves the new `min_wrist_lateral_angle_from_elbow_vertical_deg` variable is not cosmetic: with velocity, bbox-growth, and elbow/shoulder distance already passing, the straight still does **not** emit because the measured `wrist_lateral_angle_from_elbow_vertical_deg` stays below the configured minimum and `wrist_lateral_angle_gate_passed=false`.

Static inspection captured in `.temp/qa-task59-static-scan.txt` confirmed the runtime wiring is honest, not just test-shaped. In `src/detectors/pose_detector_substrate.gd`, the threshold path reads `min_wrist_lateral_angle_from_elbow_vertical_deg`, compares it against the measured `wrist_lateral_angle_from_elbow_vertical_deg`, and folds `wrist_lateral_angle_gate_passed` into the trigger decision before a straight can fire. The same scan also confirms `_get_same_family_threshold_blocking_state(...)` now blocks straight-family opposite-side candidates while the blocker is in either `triggered` **or** `not_ready`, matching the intended fix.

YAML naming/comment/style for the new variable looks landed correctly in `assets/boxing.gesture_detection.yaml`: the shipped threshold field is named exactly `min_wrist_lateral_angle_from_elbow_vertical_deg`, and the nearby comment truthfully describes the elbow-anchored vertical-ray interpretation in camera-space XY. One adjacent broad-profile check did fail: `test_camera_tracking_config_loads_boxing_profile_bundle_from_canonical_paths` still expects `hook` and `uppercut` backends to equal `threshold`, but the current canonical boxing YAML sets both to `disabled`. That failure is visible in `.temp/qa-task59-gut.log` and appears to be a pre-existing/stale expectation unrelated to this straight-threshold patch itself.

What automation proves now: the threshold same-family straight suppression fix is real in the landed code/testbed path; the new lateral-angle variable is actually consumed by the straight-threshold decision path and can block an otherwise qualifying straight; and the shipped YAML field/comment for that variable are present and truthful. What still needs Derrick’s replay/live validation: whether the guard-raise rejection feels right on real replay/live camera footage, whether the chosen default angle threshold is tuned well enough in practice, and whether opposite-side straight suppression behaves correctly under real motion timing/noise rather than only the controlled repo-local test sequence.

---

### Task 60: Audit straight threshold co-fire fix and wrist lateral-angle threshold

**Bead ID:** `aerobeat-input-camera-tracking-hv4m`  
**SubAgent:** `primary` (for `auditor`)  
**Role:** `auditor`  
**References:** `REF-02`, `REF-03`, `REF-05`, `REF-06`  
**Prompt:** Independently truth-check the straight-threshold same-family co-fire fix and the new `min_wrist_lateral_angle_from_elbow_vertical_deg` threshold. Confirm the threshold path no longer allows opposite-side same-family straight co-fire during the active window, confirm the new lateral-angle gate is implemented/documented honestly, and separate what code/tests prove from what still needs Derrick replay/live validation.

**Folders Created/Deleted/Modified:**
- `.temp/audit-task60/`
- `.plans/`

**Files Created/Deleted/Modified:**
- `.temp/audit-task60/gut-task60.log`
- `.temp/audit-task60/static-scan-task60.txt`
- `.temp/audit-task60/verify_task60.gd`
- `.temp/audit-task60/verify-task60.log`
- `.plans/2026-06-18-learned-classifier-family-specific-feature-branch.md`

**Status:** ✅ Complete

**Results:** Audit passed on landed commit `7a4cc60` after an independent rerun plus direct code/static inspection. I reran `godot --headless --path .testbed --script addons/aerobeat-vendor-godot-unit-test/gut_cmdln.gd -gtest=res://tests/unit/test_pose_detector_substrate.gd,res://tests/unit/test_camera_tracking_config_profiles.gd -gexit` and saved the output to `.temp/audit-task60/gut-task60.log`. Result: `test_pose_detector_substrate.gd` passed **77/77**, including the two patch-specific checks; `test_camera_tracking_config_profiles.gd` passed **3/4** because its canonical-path expectation for `hook.backend` and `uppercut.backend` is stale (`threshold` expected, `disabled` actual), which is unrelated to this straight-threshold patch and reproduces the pre-existing QA note from Task 59.

Patch-specific proof points from the rerun and static scan (`.temp/audit-task60/static-scan-task60.txt`):
- `test_straight_same_family_trigger_exposes_threshold_blocking_truth_while_blocking_side_is_not_ready` proves the threshold straight path no longer allows opposite-side same-family co-fire while the blocker is still in the active post-trigger window. The right side stays non-emitting and truthfully reports `same_family_blocked=true`, `blocking_family=straight_punch`, `blocking_side=left`, `blocking_event_name=punch_left`, `blocking_phase=not_ready`.
- Code inspection confirms why that now holds: `src/detectors/pose_detector_substrate.gd` `_get_same_family_threshold_blocking_state(...)` now treats `straight_punch` as blocking in both `triggered` and `not_ready`, while hook/uppercut remain limited to `triggered` grace-window blocking.
- `test_straight_punch_requires_wrist_lateral_angle_from_elbow_vertical_gate_before_triggering` proves `min_wrist_lateral_angle_from_elbow_vertical_deg` is active in the trigger decision, not cosmetic. In the test, velocity, bbox growth, and elbow/shoulder distance all pass, but the straight still does not emit because measured `wrist_lateral_angle_from_elbow_vertical_deg` stays below the configured minimum and `wrist_lateral_angle_gate_passed=false`.
- Static inspection confirms the implementation/documentation is honest: `_compute_wrist_lateral_angle_from_elbow_vertical_deg(...)` measures the elbow→wrist 2D vector against an elbow-anchored vertical ray via `atan2(abs(x), abs(y))`; the parsed config value is folded into `ready_to_trigger`; and the measured angle, configured minimum, and pass/fail bit are surfaced in straight debug/state-change payloads.
- The shipped YAML landed in the approved shape as far as this repo shows: field name is exactly `min_wrist_lateral_angle_from_elbow_vertical_deg`, the comment describes left/right deflection away from the elbow-anchored vertical ray in camera-space XY, and the canonical boxing profile value is `15.0`.

I also ran an independent disposable verifier at `.temp/audit-task60/verify_task60.gd`, captured in `.temp/audit-task60/verify-task60.log` with result `AUDIT_TASK60_OK`. That direct helper-level check re-proved two critical truths without relying only on GUT assertions: (1) the straight-family threshold helper reports `blocking_phase=not_ready` for the opposite side, and (2) the new lateral-angle helper returns a small positive angle (`3.90049°` for the audit fixture pose), consistent with the guard-raise rejection story.

What is proven now vs. what still needs Derrick:
- **Proven by code/tests/audit artifacts:** opposite-side same-family straight threshold co-fire is blocked through the blocker’s `triggered` + `not_ready` active window in the landed repo-local path; `min_wrist_lateral_angle_from_elbow_vertical_deg` is parsed, measured, enforced, and exposed honestly in debug/state payloads; and the YAML field/comment/value are present in the expected shape.
- **Still needs Derrick replay/live validation:** whether `15.0°` is the right practical tuning on real replay/live camera footage, whether real guard raises are rejected without suppressing legitimate straights, and whether same-family straight suppression still feels correct under live timing/noise outside the controlled headless fixture sequence.

---

### Task 61: Make non-punch gesture families obey disabled backend

**Bead ID:** `aerobeat-input-camera-tracking-i26a`  
**SubAgent:** `primary` (for `coder`)  
**Role:** `coder`  
**References:** `REF-02`, `REF-03`, `REF-05`, `REF-06`  
**Prompt:** Derrick’s latest live testing found a contract violation: some non-punch gesture families still fire even when `backend: disabled`, specifically `leg_lift`, `knee_strike`, and `side_step`. Implement a narrow runtime fix so non-punch gesture families actually obey the approved family-first `disabled` setting, keeping runtime/debug/proving truth honest and preserving the existing comment/config contract.

**Folders Created/Deleted/Modified:**
- `src/detectors/`
- `.testbed/tests/unit/`
- `.plans/`

**Files Created/Deleted/Modified:**
- `src/detectors/pose_detector_substrate.gd`
- `.testbed/tests/unit/test_pose_detector_substrate.gd`
- `.plans/2026-06-18-learned-classifier-family-specific-feature-branch.md`

**Status:** ✅ Complete

**Results:** Fixed the runtime contract hole by making the non-punch threshold detectors for `side_step`, `knee_strike`, and `leg_lift` respect their per-family backend selection before they run, so `backend: disabled` now truly suppresses those families instead of letting the legacy threshold path emit anyway. Kept the proving/debug surface honest by adding explicit non-punch debug entries for `side_step`, `knee_strike`, and `leg_lift` that report each family’s backend, enabled state, and current live state/measurements rather than implying the family is active when it is disabled. Added focused substrate coverage that proves all three reported families stay silent under `backend: disabled` while their debug payloads report `backend="disabled"` and `enabled=false`. Validation run: `godot --headless --path .testbed --script addons/aerobeat-vendor-godot-unit-test/gut_cmdln.gd -gtest=res://tests/unit/test_pose_detector_substrate.gd -gexit` (78/78 passed) and `godot --headless --path .testbed --script addons/aerobeat-vendor-godot-unit-test/gut_cmdln.gd -gtest=res://tests/unit/test_boxing_proving_harness_profiles_and_debug.gd -gexit` (38/38 passed).

---

### Task 62: QA non-punch disabled backend obedience

**Bead ID:** `aerobeat-input-camera-tracking-u6ff`  
**SubAgent:** `primary` (for `qa`)  
**Role:** `qa`  
**References:** `REF-02`, `REF-03`, `REF-05`, `REF-06`  
**Prompt:** Verify that non-punch gesture families obey `backend: disabled`, with concrete coverage for at least `leg_lift`, `knee_strike`, and `side_step`. Confirm the family-first disabled contract now matches runtime behavior and that any proving/debug truth stays honest.

**Folders Created/Deleted/Modified:**
- `.testbed/test-results/task62-qa-20260619/`
- `.testbed/test-results/task62-qa-20260619/runtime-probe/`
- `.testbed/test-results/task62-qa-20260619/fixture-captures/`

**Files Created/Deleted/Modified:**
- `.plans/2026-06-18-learned-classifier-family-specific-feature-branch.md`
- `.testbed/test-results/task62-qa-20260619/gut-pose-detector-disabled.log`
- `.testbed/test-results/task62-qa-20260619/gut-proving-harness.log`
- `.testbed/test-results/task62-qa-20260619/runtime-probe.log`
- `.testbed/test-results/task62-qa-20260619/task62_disabled_backend_runtime_probe.gd`
- `.testbed/test-results/task62-qa-20260619/task62_disabled_backend_boxing_probe.gd`
- `.testbed/test-results/task62-qa-20260619/task62_disabled_backend_boxing_probe.tscn`
- `.testbed/test-results/task62-qa-20260619/runtime-probe/runtime_probe_results.json`
- `.testbed/test-results/task62-qa-20260619/runtime-probe/runtime_probe_summary.md`
- `.testbed/test-results/task62-qa-20260619/fixture-captures/knee_left/report.json`
- `.testbed/test-results/task62-qa-20260619/fixture-captures/knee_left/report.md`
- `.testbed/test-results/task62-qa-20260619/fixture-captures/sidestep_left/report.json`
- `.testbed/test-results/task62-qa-20260619/fixture-captures/sidestep_left/report.md`
- `.testbed/test-results/task62-qa-20260619/fixture-captures/leg_lift_left/report.json`
- `.testbed/test-results/task62-qa-20260619/fixture-captures/leg_lift_left/report.md`

**Status:** ✅ Complete

**Results:** QA passed for the landed `f67ddfe` non-punch disabled-backend fix.

- **Automated runtime-path proof:** `res://tests/unit/test_pose_detector_substrate.gd` passed (`78/78`), including `test_disabled_non_punch_families_suppress_knee_leg_lift_and_side_step_events`, which directly exercises the detector runtime path and confirms `knee_left`, `leg_lift_right_start`, and `sidestep_right_start` are suppressed while `gesture_debug` reports `backend=disabled` / `enabled=false` for `knee_strike`, `leg_lift`, and `side_step`.
- **Automated proving/debug proof:** `res://tests/unit/test_boxing_proving_harness_profiles_and_debug.gd` passed (`38/38`). That file does not add a family-specific replay oracle for these three non-punch families, so I added a QA-only proving-scene override (`task62_disabled_backend_boxing_probe.gd/.tscn`) and captured boxing fixture reports for representative `knee_left`, `sidestep_left`, and `leg_lift_left` clips through `capture_fixture_proving.gd`.
- **Fixture-capture findings:** across 357 tracking snapshots (`knee_left`), 721 tracking snapshots (`sidestep_left`), and 453 tracking snapshots (`leg_lift_left`), the custom proving timeline shows `knee_strike`, `leg_lift`, and `side_step` all settle to `backend=disabled` and `enabled=false` once tracking is live; no blocked-family events (`knee_*`, `leg_lift_*`, `sidestep_*`) appear in either the proving event timeline or the per-snapshot event lists; `side_step.state` stays `inactive`; `leg_lift.left_state/right_state` stay `false`.
- **Important debug nuance:** `knee_strike.left_ready/right_ready` still remain `true` in the proving timeline when the athlete pose satisfies the raw knee posture, even while the family is disabled. I am treating that as honest debug, not a regression, because the same snapshots also surface `backend=disabled` and `enabled=false`, and no knee events fire. The fix goal here was disabled-backend obedience plus truthful disabled routing, not zeroing every raw posture metric.
- **Runtime-path dead end documented:** the first QA-only direct `AeroCameraTracking` replay probe (`task62_disabled_backend_runtime_probe.gd`) fell back to an OpenCV replay path outside the proving harness contract and failed with `opencv_unavailable` (`No module named 'cv2'`). I kept that artifact/log for traceability, then switched to the higher-fidelity repo-local proving capture path that actually replays fixtures successfully in this repo.
- **Renderer caveat:** `capture_fixture_proving.gd` wrote the JSON/Markdown reports successfully, but dummy-renderer screenshot capture returned a null texture (`proving.png` warnings). That did not block the report JSON used for QA verdicts.
- **What automation proves vs. what still needs Derrick:** automation now proves repo-local disabled-backend obedience in detector runtime code plus proving-scene runtime/debug state for representative `knee_left`, `sidestep_left`, and `leg_lift_left` fixtures. Derrick should still do one live replay/manual check in the actual proving UI (or a real camera/live replay session) if he wants human confirmation that the visible hover-card/event-feed wording for these three families reads naturally end-to-end under his normal workflow, since this QA pass validated the underlying report/state truth rather than a screenshot-perfect UI oracle.

---

### Task 63: Audit non-punch disabled backend obedience

**Bead ID:** `aerobeat-input-camera-tracking-d4m9`  
**SubAgent:** `primary` (for `auditor`)  
**Role:** `auditor`  
**References:** `REF-02`, `REF-03`, `REF-05`, `REF-06`  
**Prompt:** Independently truth-check that non-punch gesture families now obey `backend: disabled`, with explicit attention to `leg_lift`, `knee_strike`, and `side_step`. Confirm the runtime no longer violates the approved disabled contract for those families.

**Folders Created/Deleted/Modified:**
- `.testbed/test-results/task63-audit-20260619/`

**Files Created/Deleted/Modified:**
- `.plans/2026-06-18-learned-classifier-family-specific-feature-branch.md`
- `.testbed/test-results/task63-audit-20260619/gut-pose-detector-disabled.log`
- `.testbed/test-results/task63-audit-20260619/gut-proving-harness.log`
- `.testbed/test-results/task63-audit-20260619/fixture-timeline-audit.json`
- `.testbed/test-results/task63-audit-20260619/fixture-timeline-audit.md`

**Status:** ✅ Complete

**Results:** Audit passed on landed commit `f67ddfe` after an independent code+artifact truth-check and targeted reruns. I reran `godot --headless --path .testbed --script addons/aerobeat-vendor-godot-unit-test/gut_cmdln.gd -gtest=res://tests/unit/test_pose_detector_substrate.gd -gexit` and `godot --headless --path .testbed --script addons/aerobeat-vendor-godot-unit-test/gut_cmdln.gd -gtest=res://tests/unit/test_boxing_proving_harness_profiles_and_debug.gd -gexit`; both passed cleanly and were captured at `.testbed/test-results/task63-audit-20260619/gut-pose-detector-disabled.log` (**78/78**) and `.testbed/test-results/task63-audit-20260619/gut-proving-harness.log` (**38/38**).

Code truth-check: `src/detectors/pose_detector_substrate.gd:2051-2056` now resolves non-punch family backend directly from the gesture-profile family document, `src/detectors/pose_detector_substrate.gd:1099-1110` only runs `_process_sidestep`, `_process_knee`, and `_process_leg_lift` when that family backend resolves to `threshold`, and `src/detectors/pose_detector_substrate.gd:698-739` stamps debug state for `side_step`, `knee_strike`, and `leg_lift` with the same backend plus `enabled = backend == BACKEND_THRESHOLD`. The focused substrate unit `test_disabled_non_punch_families_suppress_knee_leg_lift_and_side_step_events()` (`.testbed/tests/unit/test_pose_detector_substrate.gd:1965-1997`) directly proves the runtime contract: with `backend: disabled`, no `knee_left`, `leg_lift_right_start`, or `sidestep_right_start` events fire, and the corresponding debug dictionaries report `backend = disabled`, `enabled = false`, plus inactive state for side-step/leg-lift.

QA-artifact truth-check: I independently re-audited Task 62’s proving captures using `.testbed/test-results/task62-qa-20260619/fixture-captures/{knee_left,sidestep_left,leg_lift_left}/report.json` and wrote the extracted summary to `.testbed/test-results/task63-audit-20260619/fixture-timeline-audit.{json,md}`. Across all three captures, there are **zero blocked-family events** during tracking and **zero backend mismatches once tracking samples begin**; the only mismatches are three early frame-0 `tracking_state = lost` warm-up samples per capture where the proving harness snapshot still shows threshold defaults before the disabled config is reflected in tracked pose-updated samples. That means the landed fix is obeyed in the actual tracked runtime path, and the proving/debug surface is honest once the run is live.

Important debug nuance: `knee_strike.left_ready/right_ready` can still be `true` while the family backend is disabled, and the leg/offset metrics continue updating. I audited that as honest debug rather than a regression because the same snapshots simultaneously report `backend = disabled`, `enabled = false`, `side_step.state = inactive`, `leg_lift.left_state/right_state = false`, and no blocked-family events. What is proven by automation is runtime disabled-backend obedience plus truthful disabled routing/state surfacing after startup. What still needs Derrick is a manual replay/live proving-UI check for end-to-end wording/UX judgment and confirmation that the brief pre-tracking warm-up snapshots are not confusing in his normal workflow.

---

### Task 64: Replace hook/uppercut dominance thresholds with elbow-ray alignment thresholds

**Bead ID:** `aerobeat-input-camera-tracking-0x43`  
**SubAgent:** `primary` (for `coder`)  
**Role:** `coder`  
**References:** `REF-02`, `REF-03`, `REF-05`, `REF-06`  
**Prompt:** Replace the current threshold-only hook/uppercut directional ratio gates with simpler elbow-anchored camera-space alignment thresholds, while preserving `min_velocity`. For hook, add `max_wrist_angle_from_elbow_horizontal_deg` and require the wrist to stay within that many degrees of an elbow-anchored horizontal ray in 2D camera space. Also require hook threshold validity to keep the wrist on the correct camera-space side of the elbow (left hook wrist on one side, right hook wrist on the mirrored side, accounting for the camera-facing athlete view). For uppercut, add `max_wrist_angle_from_elbow_vertical_deg` and require the wrist to stay within that many degrees of an elbow-anchored vertical ray in 2D camera space, while also requiring the wrist to stay above the elbow in camera space. Remove the old threshold variables this new contract supersedes (`min_lateral_dominance_ratio`, `min_horizontal_direction_ratio`, `min_vertical_dominance_ratio`, `min_upward_direction_ratio`), update YAML comments in the existing style, and keep runtime/debug/proving truth explicit.

**Folders Created/Deleted/Modified:**
- `assets/`
- `src/detectors/`
- `.testbed/tests/unit/`
- `.testbed/scripts/` (if proving/debug truth needs updates)

**Files Created/Deleted/Modified:**
- `assets/boxing.gesture_detection.yaml`
- `src/detectors/pose_detector_substrate.gd`
- `.testbed/scripts/boxing_proving_harness.gd`
- `.testbed/tests/unit/test_pose_detector_substrate.gd`
- `.testbed/tests/unit/test_boxing_proving_harness_profiles_and_debug.gd`
- `.plans/2026-06-18-learned-classifier-family-specific-feature-branch.md`

**Status:** ✅ Complete

**Results:** Replaced the hook/uppercut threshold path’s old dominance/direction ratio gates with elbow-ray alignment gates while preserving `min_velocity`. `src/detectors/pose_detector_substrate.gd` now removes the superseded hook/uppercut config keys, adds `max_wrist_angle_from_elbow_horizontal_deg` + `max_wrist_angle_from_elbow_vertical_deg`, computes explicit elbow-anchored wrist angles in camera-space XY, and gates hook triggers on both horizontal-ray alignment and the mirrored wrist-vs-elbow side check while gating uppercuts on vertical-ray alignment plus wrist-above-elbow truth. The same file now also surfaces the new alignment truth in runtime/debug state and state-change payloads so proving/debug consumers can show the real active contract.

Updated the shipped YAML comments in `assets/boxing.gesture_detection.yaml` in the existing style, replacing the old ratio descriptions with the new angle-threshold descriptions and removing the dead threshold keys entirely. Updated `.testbed/scripts/boxing_proving_harness.gd` and `.testbed/tests/unit/test_boxing_proving_harness_profiles_and_debug.gd` so hook/uppercut hover cards and config text report the new elbow-ray alignment thresholds and gate truth instead of stale dominance/direction threshold copy.

Added focused threshold-contract tests in `.testbed/tests/unit/test_pose_detector_substrate.gd` that prove: valid hook/uppercut events pass when the new elbow-ray angle gates are satisfied, hooks fail when the wrist crosses to the wrong mirrored elbow side, uppercuts fail when the wrist is not above the elbow, and both families can still be blocked by the new angle gates even when `min_velocity` is satisfied. Validation run: `godot --headless --path .testbed --script addons/aerobeat-vendor-godot-unit-test/gut_cmdln.gd -gtest=res://tests/unit/test_pose_detector_substrate.gd,res://tests/unit/test_boxing_proving_harness_profiles_and_debug.gd -gexit` ✅. I also ran the full repo-local GUT suite once; it still has pre-existing unrelated failures in `test_aero_camera_tracking_coerce_runtime_config_preserves_preloaded_profile_overrides` and `test_camera_tracking_config_loads_boxing_profile_bundle_from_canonical_paths`, both expecting `hook/uppercut backend == threshold` while the current checked-in profile still says `backend: disabled`.

---

### Task 65: QA hook/uppercut elbow-ray alignment threshold contract

**Bead ID:** `aerobeat-input-camera-tracking-8qjs`  
**SubAgent:** `primary` (for `qa`)  
**Role:** `qa`  
**References:** `REF-02`, `REF-03`, `REF-05`, `REF-06`  
**Prompt:** Verify the new hook/uppercut elbow-ray alignment threshold contract after implementation. Confirm the old dominance/direction variables are gone, confirm the new alignment thresholds participate honestly in the threshold decision paths, and confirm the YAML/comment shape matches the approved contract.

**Folders Created/Deleted/Modified:**
- `.testbed/test-results/task65-qa-20260619/`
- `.plans/`

**Files Created/Deleted/Modified:**
- `.testbed/test-results/task65-qa-20260619/gut-hook-uppercut-threshold-contract.log`
- `.plans/2026-06-18-learned-classifier-family-specific-feature-branch.md`

**Status:** ✅ Complete

**Results:** QA ran against landed commit `6821df4` at repo `HEAD`. Static runtime inspection in `src/detectors/pose_detector_substrate.gd` verified the live hook threshold path now arms on `speed >= min_velocity and wrist_horizontal_angle_gate_passed and wrist_on_required_hook_side`, with `wrist_horizontal_angle_gate_passed` computed from `max_wrist_angle_from_elbow_horizontal_deg`; the live uppercut path now arms on `speed >= min_velocity and wrist_vertical_angle_gate_passed and wrist_above_elbow_gate_passed`, with `wrist_vertical_angle_gate_passed` computed from `max_wrist_angle_from_elbow_vertical_deg`. The superseded hook/uppercut dominance + direction threshold keys (`min_lateral_dominance_ratio`, `min_horizontal_direction_ratio`, `min_vertical_dominance_ratio`, `min_upward_direction_ratio`) do not appear anywhere under `src/`, `.testbed/tests/`, or the live YAML contract; remaining hits are confined to archived historical `test-results/` artifacts only, so they are no longer part of the live threshold decision path. Contract-shape QA on `assets/boxing.gesture_detection.yaml` confirmed the approved YAML/comment surface now exposes only the elbow-ray alignment threshold for hook and uppercut, with the matching explanatory comments for mirrored hook-side validity and uppercut wrist-above-elbow validity. Focused repo-local automation passed via headless Godot GUT after `godotenv-sync`: `res://tests/unit/test_pose_detector_substrate.gd` and `res://tests/unit/test_boxing_proving_harness_profiles_and_debug.gd` (116/116 passing; log at `.testbed/test-results/task65-qa-20260619/gut-hook-uppercut-threshold-contract.log`). The strongest direct proofs came from `test_hook_requires_wrist_on_correct_mirrored_elbow_side`, `test_uppercut_requires_wrist_above_elbow_in_camera_space`, `test_hook_alignment_angle_gate_participates_honestly`, `test_uppercut_alignment_angle_gate_participates_honestly`, `test_hook_alignment_angle_gate_blocks_even_when_velocity_is_high`, `test_uppercut_alignment_angle_gate_blocks_even_when_velocity_is_high`, plus proving-harness contract checks `test_boxing_event_feed_text_lists_hook_uppercut_and_guard_tuning_sections` and `test_hook_hover_card_reports_simplified_pose_trigger_contract`. Automation proves the shipped runtime/config/debug contract for this patch is wired honestly inside the repo-local detector + proving harness. It does not prove real camera replay feel, false-positive/false-negative balance on Derrick’s live movement, or whether the new angle windows are the final good gameplay values; Derrick still needs live replay/manual validation for those human-motion acceptance questions.

---

### Task 66: Audit hook/uppercut elbow-ray alignment threshold contract

**Bead ID:** `aerobeat-input-camera-tracking-v4qp`  
**SubAgent:** `primary` (for `auditor`)  
**Role:** `auditor`  
**References:** `REF-02`, `REF-03`, `REF-05`, `REF-06`  
**Prompt:** Independently truth-check the hook/uppercut elbow-ray alignment threshold contract. Confirm the runtime no longer depends on the superseded dominance/direction thresholds for hook/uppercut threshold routing, and confirm the new alignment variables are implemented and documented honestly.

**Folders Created/Deleted/Modified:**
- `.testbed/test-results/task66-audit-20260619/`
- `.plans/`

**Files Created/Deleted/Modified:**
- `.testbed/test-results/task66-audit-20260619/gut-hook-uppercut-threshold-contract-audit.log`
- `.plans/2026-06-18-learned-classifier-family-specific-feature-branch.md`

**Status:** ✅ Complete

**Results:** Independent audit passed against landed commit `6821df4` using fresh repo inspection plus a new targeted headless GUT rerun logged at `.testbed/test-results/task66-audit-20260619/gut-hook-uppercut-threshold-contract-audit.log` (`116/116` passing). Runtime truth-check in `src/detectors/pose_detector_substrate.gd` confirmed the live threshold-routing decision no longer depends on the superseded hook/uppercut dominance or direction thresholds: in `_process_pose_strike`, hook now arms only on `speed >= min_velocity and wrist_horizontal_angle_gate_passed and wrist_on_required_hook_side`, while uppercut now arms only on `speed >= min_velocity and wrist_vertical_angle_gate_passed and wrist_above_elbow_gate_passed`. The new angle gates are computed directly from `max_wrist_angle_from_elbow_horizontal_deg` / `max_wrist_angle_from_elbow_vertical_deg`, and the mirrored hook-side / wrist-above-elbow helpers are explicit in `_is_wrist_on_required_hook_side` and `_is_wrist_above_elbow_in_camera_space`.

Static search truth-checks also passed. The superseded live config/debug keys (`min_lateral_dominance_ratio`, `min_horizontal_direction_ratio`, `min_vertical_dominance_ratio`, `min_upward_direction_ratio`) no longer appear in the live runtime/config/test/proving surfaces under `src/`, `assets/`, `.testbed/scripts/`, or `.testbed/tests/`. Remaining hits in the repo are confined to older captured `docs/baselines/**/report.json` artifacts, which document historical runs but are not consulted by the live threshold-routing code path. YAML/comments in `assets/boxing.gesture_detection.yaml` match the approved contract: hook exposes only `max_wrist_angle_from_elbow_horizontal_deg` with horizontal-ray guidance, and uppercut exposes only `max_wrist_angle_from_elbow_vertical_deg` with vertical-ray guidance. Proving/debug surfaces also match the contract: `.testbed/scripts/boxing_proving_harness.gd` now renders the hover-card gate rows as elbow-ray angle + mirrored-side/above-elbow truth, and the event-feed tuning text reports the new angle thresholds plus the required spatial-validity rule for each family.

The strongest code/test proof points are: `test_hook_requires_wrist_on_correct_mirrored_elbow_side`, `test_uppercut_requires_wrist_above_elbow_in_camera_space`, `test_hook_alignment_angle_gate_participates_honestly`, `test_uppercut_alignment_angle_gate_participates_honestly`, `test_hook_alignment_angle_gate_blocks_even_when_velocity_is_high`, `test_uppercut_alignment_angle_gate_blocks_even_when_velocity_is_high`, `test_boxing_event_feed_text_lists_hook_uppercut_and_guard_tuning_sections`, and `test_hook_hover_card_reports_simplified_pose_trigger_contract`. What is proven: repo-local runtime routing, config comments, debug surfaces, and focused automation all agree on the new elbow-ray threshold contract. What is **not** proven by this audit: whether these angle windows feel best in real motion, how they behave on Derrick’s live replay set beyond the synthetic/unit fixtures, or whether the false-positive / false-negative tradeoff is now good enough for gameplay. Derrick still needs live replay/manual validation for that acceptance layer.

---

### Task 67: Diagnose and fix hook required-side / remaining threshold bug

**Bead ID:** `aerobeat-input-camera-tracking-zkl6`  
**SubAgent:** `primary` (for `coder`)  
**Role:** `coder`  
**References:** `REF-02`, `REF-03`, `REF-05`, `REF-06`  
**Prompt:** Derrick resumed the active boxing branch with concrete live-testing feedback on hook threshold behavior. Diagnose the current hook threshold path in `src/detectors/pose_detector_substrate.gd`, specifically the preview-space `wrist stays on required side` boolean and the last remaining threshold check now that velocity and wrist-angle-from-elbow-horizontal-ray were already validated as working. Walk the code path from the mirrored camera-space side check through the final trigger decision, explain exactly how left/right are currently interpreted relative to the athlete-facing webcam, fix any incorrect per-arm logic, and keep runtime/debug/proving truth explicit so Derrick can verify the corrected behavior. Claim bead `aerobeat-input-camera-tracking-zkl6` on start, run the narrowest truthful validation, commit/push by default, and close the bead with a clear reason when done.

**Folders Created/Deleted/Modified:**
- `src/detectors/`
- `.testbed/scripts/`
- `.testbed/tests/unit/`
- `.plans/`

**Files Created/Deleted/Modified:**
- `src/detectors/pose_detector_substrate.gd`
- `.testbed/scripts/boxing_proving_harness.gd`
- `.testbed/tests/unit/test_pose_detector_substrate.gd`
- `.testbed/tests/unit/test_boxing_proving_harness_profiles_and_debug.gd`
- `.plans/2026-06-18-learned-classifier-family-specific-feature-branch.md`

**Status:** ✅ Complete

**Results:** Root cause: the final hook side gate was mirrored backwards. `_is_wrist_on_required_hook_side` treated `hook_left` as valid only when the left wrist crossed to the preview-space **right** of the left elbow, and treated `hook_right` as valid only when the right wrist crossed to the preview-space **left** of the right elbow. That inverted the athlete-facing mirrored preview interpretation and made the final `ready_to_trigger = speed >= min_velocity and wrist_horizontal_angle_gate_passed and wrist_on_required_hook_side` contract reject the side that Derrick’s live test expected. The narrow fix flipped that per-arm side check to the honest mirrored preview contract: `hook_left` now requires `left_of_elbow`, `hook_right` now requires `right_of_elbow`, while leaving the already-validated velocity and elbow-horizontal-angle gates unchanged.

To keep proving truth explicit, runtime debug now surfaces the corrected `required_hook_side_label` from a single helper, and the boxing proving harness text now spells out the mirrored contract (`left hook = left_of_elbow`, `right hook = right_of_elbow`) plus includes the live required-side label in the hover-card / inspector row (`true (left_of_elbow)` style output). Focused test updates now cover both arms for the required-side gate, plus the positive hook trigger/replay-reset cases that depended on the old inverted interpretation.

Validation run (narrow + truthful):
- `godot --headless --path .testbed --script addons/aerobeat-vendor-godot-unit-test/gut_cmdln.gd -gtest=res://tests/unit/test_pose_detector_substrate.gd -gunit_test_name=hook_ -gexit` → `7/7` passing
- `godot --headless --path .testbed --script addons/aerobeat-vendor-godot-unit-test/gut_cmdln.gd -gtest=res://tests/unit/test_pose_detector_substrate.gd -gunit_test_name=replay_timestamp_rewind_resets_pose_strike_temporal_windows -gexit` → `1/1` passing
- `godot --headless --path .testbed --script addons/aerobeat-vendor-godot-unit-test/gut_cmdln.gd -gtest=res://tests/unit/test_boxing_proving_harness_profiles_and_debug.gd -gunit_test_name=hook_hover_card_reports_simplified_pose_trigger_contract -gexit` → `1/1` passing

I also ran a broader two-file GUT invocation during diagnosis; the hook/proving changes passed there after the fix, while the same pre-existing unrelated flow tests in `test_pose_detector_substrate.gd` still failed (`test_detects_flow_swing_events_with_distinct_placement_and_direction`, `test_exposes_flow_debug_candidates_and_last_emit_metadata`). No new failures were introduced in the hook path. Commit/push details to be appended once landed.

---

### Task 68: QA hook required-side / remaining threshold fix

**Bead ID:** `aerobeat-input-camera-tracking-je2y`  
**SubAgent:** `primary` (for `qa`)  
**Role:** `qa`  
**References:** `REF-02`, `REF-03`, `REF-05`, `REF-06`  
**Prompt:** Verify the hook threshold bug fix from Task 67. Confirm the preview-space required-side boolean now matches the intended mirrored webcam interpretation for both left and right hooks, confirm the remaining threshold gate participates honestly in the hook trigger path, and separate what repo-local automation proves from what still needs Derrick’s replay/live feel check.

**Folders Created/Deleted/Modified:**
- `.testbed/test-results/task68-qa-20260619/`

**Files Created/Deleted/Modified:**
- `.plans/2026-06-18-learned-classifier-family-specific-feature-branch.md`
- `.testbed/test-results/task68-qa-20260619/gut-hook-task68.log`
- `.testbed/test-results/task68-qa-20260619/gut-hook-rewind-task68.log`
- `.testbed/test-results/task68-qa-20260619/gut-hook-proving-task68.log`

**Status:** ✅ Complete

**Results:** QA passed on the narrowest truthful repo-local validation path for the Task 67 hook-side fix. I reran the exact focused checks the coder used and saved the logs under `.testbed/test-results/task68-qa-20260619/`:
- `godot --headless --path .testbed --script addons/aerobeat-vendor-godot-unit-test/gut_cmdln.gd -gtest=res://tests/unit/test_pose_detector_substrate.gd -gunit_test_name=hook_ -gexit` → **7/7 passed** (`gut-hook-task68.log`)
- `godot --headless --path .testbed --script addons/aerobeat-vendor-godot-unit-test/gut_cmdln.gd -gtest=res://tests/unit/test_pose_detector_substrate.gd -gunit_test_name=replay_timestamp_rewind_resets_pose_strike_temporal_windows -gexit` → **1/1 passed** (`gut-hook-rewind-task68.log`)
- `godot --headless --path .testbed --script addons/aerobeat-vendor-godot-unit-test/gut_cmdln.gd -gtest=res://tests/unit/test_boxing_proving_harness_profiles_and_debug.gd -gunit_test_name=hook_hover_card_reports_simplified_pose_trigger_contract -gexit` → **1/1 passed** (`gut-hook-proving-task68.log`; non-blocking pre-existing orphan/leaked-RID warning only)

Exact QA evidence for the side-label contract:
- Runtime code now defines the mirrored preview-space requirement in one place: `src/detectors/pose_detector_substrate.gd` `_required_hook_side_label(side)` returns `left_of_elbow` for left and `right_of_elbow` for right, and `_is_wrist_on_required_hook_side(...)` enforces `wrist_offset_x < 0` for left / `> 0` for right.
- The final live hook trigger remains `speed >= min_velocity and wrist_horizontal_angle_gate_passed and wrist_on_required_hook_side`, so the remaining threshold gate still participates honestly after the fix rather than being bypassed.
- Focused unit coverage proves both mirrored-side negatives and positives: `test_hook_requires_wrist_on_correct_mirrored_elbow_side`, `test_hook_requires_wrist_on_correct_mirrored_elbow_side_for_right_arm`, `test_hook_alignment_angle_gate_participates_honestly`, and `test_hook_uses_pose_primary_state_machine_and_debug_surfaces`.
- The proving/debug text now reflects the corrected side labels explicitly. `.testbed/scripts/boxing_proving_harness.gd` shows `Preview-space wrist stays on required mirrored hook side` with the live label appended (`true (left_of_elbow)` style), and the tuning summary text now says: `left hook = left_of_elbow, right hook = right_of_elbow`. The focused proving-harness test `test_hook_hover_card_reports_simplified_pose_trigger_contract` passed and asserts that exact `true (left_of_elbow)` row/body text.

What repo-local automation proves: the mirrored preview-space side boolean is now wired correctly for both hook arms, the hook trigger still honestly depends on velocity + horizontal-angle + required-side, the proving/debug surfaces expose the corrected contract clearly, and the hook temporal-window rewind path still resets cleanly after the change. What it does **not** prove: final replay/live feel, whether Derrick’s actual webcam mirroring intuition matches the on-screen proving UX in motion, or whether the corrected side gate plus the remaining threshold gates feel right on real hook footage. Derrick still needs replay/live manual validation for that acceptance layer.

---

### Task 69: Audit hook required-side / remaining threshold fix

**Bead ID:** `aerobeat-input-camera-tracking-zymj`  
**SubAgent:** `primary` (for `auditor`)  
**Role:** `auditor`  
**References:** `REF-02`, `REF-03`, `REF-05`, `REF-06`  
**Prompt:** Independently truth-check the hook threshold bug fix. Confirm the runtime no longer misinterprets the mirrored preview-space left/right side requirement for hooks, confirm the final threshold contract is implemented/documented honestly, and call out what still depends on Derrick’s real replay/live validation.

**Folders Created/Deleted/Modified:**
- `.testbed/test-results/task69-audit-20260619/`

**Files Created/Deleted/Modified:**
- `.testbed/test-results/task69-audit-20260619/gut-hook-task69-audit.log`
- `.testbed/test-results/task69-audit-20260619/gut-hook-rewind-task69-audit.log`
- `.testbed/test-results/task69-audit-20260619/gut-hook-proving-task69-audit.log`
- `.plans/2026-06-18-learned-classifier-family-specific-feature-branch.md`

**Status:** ✅ Complete

**Results:** Audit passed on `b193588` (`Fix mirrored hook required-side gate`) with no additional code changes needed. Independent truth-check confirmed `src/detectors/pose_detector_substrate.gd` now enforces the mirrored preview-space hook side contract honestly via `_required_hook_side_label(side)` + `_is_wrist_on_required_hook_side(...)`: `hook_left` requires `wrist_offset_x < 0` (`left_of_elbow`), and `hook_right` requires `wrist_offset_x > 0` (`right_of_elbow`). The final live hook threshold remains explicit and unchanged apart from that side fix: `speed >= min_velocity and wrist_horizontal_angle_gate_passed and wrist_on_required_hook_side`, so the remaining threshold contract is still velocity gate + horizontal-angle gate + required-side gate.

I reran the narrowest truthful repo-local audit validation and saved fresh logs under `.testbed/test-results/task69-audit-20260619/`: `godot --headless ... -gtest=res://tests/unit/test_pose_detector_substrate.gd -gunit_test_name=hook_ -gexit` (**7/7 passed**), `... -gunit_test_name=replay_timestamp_rewind_resets_pose_strike_temporal_windows -gexit` (**1/1 passed**), and `... -gtest=res://tests/unit/test_boxing_proving_harness_profiles_and_debug.gd -gunit_test_name=hook_hover_card_reports_simplified_pose_trigger_contract -gexit` (**1/1 passed**). Static audit also confirmed the proving/debug/documentation text now says `left hook = left_of_elbow, right hook = right_of_elbow` in `.testbed/scripts/boxing_proving_harness.gd`, and the hover-card row shows the live label (`true (left_of_elbow)` style) instead of vague boolean-only text.

What this audit proves: repo-local runtime logic, focused tests, rewind safety, and proving/debug text all agree on the corrected mirrored hook-side contract. What still depends on Derrick: real replay/live validation that the mirrored preview-space interpretation matches his webcam/proving intuition in motion and that the current hook false-positive/false-negative feel is acceptable in practice. Non-blocking caveat unchanged: the proving-harness audit run still emits pre-existing orphan / leaked-RID warnings, but the test itself passed and did not expose a hook-contract regression.

---

## Final Results

**Status:** ✅ Complete

**What We Built:** This branch progressed from the original flat shared-vector family-specific feature test into family-masked topology checks, reduced straight-family diagnosis, multiple hook/uppercut cue-design passes, retimed-truth reruns after Derrick corrected the punch YAML windows, and then a broader boxing runtime/config rewrite. The shipped state now uses a family-first gesture YAML contract (`disabled` / `threshold` / `prototype` / `classifier` per family), truthful proving/debug backend surfaces, real disabled-backend obedience for punch and non-punch families, same-family boxing co-fire suppression, a straight-punch lateral-angle guard-raise filter, new hook/uppercut elbow-ray alignment threshold gates, and the final mirrored hook required-side fix (`hook_left = left_of_elbow`, `hook_right = right_of_elbow`) that Derrick confirmed live.

**Reference Check:** `REF-02`/`REF-03` still anchor the runtime/harness implementation surface, and `REF-06` remains the fixture-manifest truth source. The trustworthy updated read after the retimed-YAML reruns is: straight-family masking wins fairly against the refreshed shared-vector straight subset baseline, hook/uppercut specialization still fails to beat the refreshed hook/uppercut subset baseline, and the later family-first runtime contract work stayed honest by keeping tuning/acceptance decisions gated on Derrick’s real replay/live review rather than pretending repo-local automation alone can sign off gameplay behavior. Derrick’s latest live review then validated the remaining hook-threshold bugfix directly, closing the active branch.

**Commits:**
- `05606b0` - `Refresh family benchmarks for retimed punch truth`
- `0ba32df` - `Add proving mixed-family punch routing`
- `44705f2` - `Globalize mixed-family straight artifact selection`
- `1049634` - `Clarify mixed-family config comments`
- `be4b0bf` - `Fix mixed-family proving backend truth surfaces`
- `6e4cd00` - `Implement family-first punch backend contract`
- `831d9bc` - `Tighten family backend config and proving routing`
- `dadab1a` - `Add same-family boxing gesture exclusion gate`
- `a3bf13c` - `Fix proving harness family override iterator typing`
- `7a4cc60` - `Fix straight threshold co-fire and lateral angle gate`
- `f67ddfe` - `Honor disabled non-punch gesture backends`
- `6821df4` - `Replace hook and uppercut ratio gates with elbow alignment`

**Lessons Learned:** Two things turned out to be separately material. First, “family-specific named features inside one shared classifier” is not the same thing as true family isolation. Second, truth-window definition itself was strong enough to change the benchmark story: pre-retime blanket conclusions about masking were too broad. After retiming, straight-family isolation looks genuinely promising on the fair subset comparison, while hook/uppercut remains the weak branch. Terminal-side verification then showed a separate truth-plumbing issue in mixed-family proving that was worth fixing, and Derrick’s final live review then closed the loop by catching a simple mirrored preview-space hook-side bug that was easy to prove and fix once isolated.

---

*Completed on 2026-06-19*
