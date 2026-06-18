# AeroBeat Learned Classifier Family-Specific Feature Branch

**Date:** 2026-06-18  
**Status:** Blocked  
**Last Updated:** 2026-06-18 10:36 EDT  
**Blocked Reason:** Awaiting design revision before QA/audit because the first family-specific benchmark still fed one shared feature vector to one shared classifier instead of truly isolating straight-family cues from hook/uppercut cues.  
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

## Final Results

**Status:** ⚠️ Partial / Design Review Hold

**What We Built:** We designed and ran a first family-specific benchmark branch and proved that the current implementation did not beat the baseline CNN. More importantly, Derrick’s review surfaced a material design mismatch: although the feature names were family-specific, the benchmark still fed one shared feature vector to one shared classifier. That means the branch is best treated as a design checkpoint, not a validated answer to the intended experiment.

**Reference Check:** `REF-02`/`REF-03` captured the candidate straight-specific elbow features and hook/uppercut wrist-direction features; `REF-05` documents the benchmark outcomes of that first attempt; the next slice should revisit the feature-family isolation idea before trusting those results as the definitive answer.

**Commits:**
- `c4386cf` - `Benchmark family-specific learned punch features`

**Lessons Learned:** The distinction between “adding family-specific feature groups to one shared classifier input” and “actually isolating family-specific information so unrelated cue groups do not compete” is material. The next branch should continue this same test by reviewing modifications that reduce unrelated per-family data being available at once, and should also revisit the proposed solutions for making the classifier less confused by mixed family signals.

---

*Completed on Pending*
