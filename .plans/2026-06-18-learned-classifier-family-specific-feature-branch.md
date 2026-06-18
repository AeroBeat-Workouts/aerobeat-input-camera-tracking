# AeroBeat Learned Classifier Family-Specific Feature Branch

**Date:** 2026-06-18  
**Status:** In Progress  
**Last Updated:** 2026-06-18 11:42 EDT  
**Blocked Reason:** None; Task 7 QA rerun passed on the refreshed masked-family artifacts and audit is ready to proceed.  
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

**Files Created/Deleted/Modified:**
- QA notes/artifacts as needed

**Status:** ⏳ Pending

**Results:** Pending.

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

**Status:** ⏳ Pending

**Results:** Pending.

---

## Final Results

**Status:** ⚠️ Partial / Design Review Hold

**What We Built:** We designed and ran a first family-specific benchmark branch and proved that the current implementation did not beat the baseline CNN. More importantly, Derrick’s review surfaced a material design mismatch: although the feature names were family-specific, the benchmark still fed one shared feature vector to one shared classifier. That means the branch is best treated as a design checkpoint, not a validated answer to the intended experiment.

**Reference Check:** `REF-02`/`REF-03` captured the candidate straight-specific elbow features and hook/uppercut wrist-direction features; `REF-05` documents the benchmark outcomes of that first attempt; the next slice should revisit the feature-family isolation idea before trusting those results as the definitive answer.

**Commits:**
- `c4386cf` - `Benchmark family-specific learned punch features`

**Lessons Learned:** The distinction between “adding family-specific feature groups to one shared classifier input” and “actually isolating family-specific information so unrelated cue groups do not compete” is material. The next branch should continue this same test by reviewing modifications that reduce unrelated per-family data being available at once, and should also revisit the proposed solutions for making the classifier less confused by mixed family signals.

---

*Completed on Pending*
