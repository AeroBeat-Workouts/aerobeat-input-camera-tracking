# AeroBeat Learned Classifier Family-Specific Feature Branch

**Date:** 2026-06-18  
**Status:** In Progress  
**Last Updated:** 2026-06-18 12:26 EDT  
**Blocked Reason:** None; Task 12 audit passed on the reduced straight-family variants and the next slice is ready to plan.  
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
