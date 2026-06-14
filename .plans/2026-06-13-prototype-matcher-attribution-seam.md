# Prototype Matcher Attribution Seam

**Date:** 2026-06-13  
**Status:** In Progress  
**Last Updated:** 2026-06-13 22:10 EDT  
**Blocked Reason:** Session stopped for handoff after coder completed attribution slice; QA/audit not yet run on the new attribution artifacts.  
**Agent:** `pico`

---

## Goal

Add enough matcher attribution/instrumentation to identify which exact prototypes and class margins are driving correct emits, wrong emits, and negative-control false positives, so the next tuning step is targeted instead of blind.

---

## Overview

The first class-separation pass did not improve the derived-library benchmark. Naive pruning and centroid-style prototype replacement both regressed expected emits while failing to clean up the negative control. That means the next highest-value seam is not more blind prototype editing; it is instrumentation.

We need to know which exact prototype IDs are winning, which runner-up classes are close behind, how large the winner-vs-runner-up margin is, and which specific prototypes are responsible for the run-in-place false positives. With that attribution, the next branch can be chosen deliberately: targeted prototype removal/resegmentation, per-class margin gating, or negative-control-aware suppression. Without it, we are still guessing.

This slice should stay narrow: add attribution to the matcher/benchmark outputs and generate a first readable attribution artifact from the existing derived-library benchmark path.

---

## REFERENCES

| ID | Description | Path |
| --- | --- | --- |
| `REF-01` | Current derived library candidate | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/assets/prototype_libraries/boxing_side_aware_fixture_derived_v1/library.json` |
| `REF-02` | Derived-library review packet | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/docs/reviews/prototype-matcher-derived-library-review-2026-06-13.md` |
| `REF-03` | Failed class-separation experiment artifacts | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/docs/baselines/prototype-matcher-boxing-fixture-derived-v1-class-separation-pass1/` |
| `REF-04` | Matcher runtime implementation | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/src/detectors/prototype_punch_matcher.gd` |
| `REF-05` | Benchmark runner | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/scripts/run_prototype_matcher_fixture_benchmark.py` |

---

## Tasks

### Task 1: Add attribution to matcher benchmark outputs

**Bead ID:** `aerobeat-input-camera-tracking-rce4`  
**SubAgent:** `primary` (for `coder`)  
**Role:** `coder`  
**References:** `REF-01`, `REF-02`, `REF-04`, `REF-05`  
**Prompt:** Add prototype-matcher attribution/instrumentation so the benchmark can show winning prototype IDs, runner-up classes/prototypes, score margins, and which prototypes are responsible for negative-control false positives. Claim the bead on start. Keep the slice narrow and evidence-first, produce a readable attribution artifact from the existing derived-library benchmark path, and commit/push by default if complete.

**Folders Created/Deleted/Modified:**
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking`

**Files Created/Deleted/Modified:**
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/src/detectors/prototype_punch_matcher.gd`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.testbed/scripts/proving_harness.gd`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/scripts/run_prototype_matcher_fixture_benchmark.py`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/docs/baselines/prototype-matcher-boxing-fixture-derived-v1/benchmark-results.json`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/docs/baselines/prototype-matcher-boxing-fixture-derived-v1/benchmark-results.md`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/docs/reviews/prototype-matcher-attribution-review-2026-06-13.md`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/docs/reviews/prototype-matcher-attribution-review-2026-06-13.summary.json`

**Status:** ✅ Complete

**Results:** Landed and pushed commit `7e7a6cc`, adding attribution to the matcher/benchmark path. The matcher now exposes winning `best_prototype_id`, runner-up class/prototype/score, winner-vs-runner-up margin, per-class winning prototype maps, top overall prototype matches, emitted prototype counts, and negative-control culprit prototype counts. Durable review artifacts were created at `docs/reviews/prototype-matcher-attribution-review-2026-06-13.md` and `.summary.json`. The strongest negative-control culprit was identified as `hook_left_hook_left_fixture_window_01` (21 of 30 false positives on run-in-place), with `hook_left_hook_left_fixture_window_03` as a smaller secondary culprit; strongest legitimate hook-left emits were instead anchored on `hook_left_hook_left_fixture_window_04`. Recommended next branch from this evidence: a surgical prune/re-segmentation pass on those specific hook-left prototypes before broader threshold work.

---

### Task 2: QA the attribution seam

**Bead ID:** `aerobeat-input-camera-tracking-60bb`  
**SubAgent:** `primary` (for `qa`)  
**Role:** `qa`  
**References:** `REF-01`, `REF-04`, `REF-05`  
**Prompt:** Verify the attribution seam. Confirm the new benchmark outputs really expose useful winning-prototype / runner-up / margin data and that the review artifact matches the underlying instrumented evidence.

**Folders Created/Deleted/Modified:**
- relevant owning repo paths

**Files Created/Deleted/Modified:**
- QA notes/artifacts as needed

**Status:** ⏳ Pending

**Results:** Pending.

---

### Task 3: Audit the attribution seam and state the next likely tuning move

**Bead ID:** `aerobeat-input-camera-tracking-8lv8`  
**SubAgent:** `primary` (for `auditor`)  
**Role:** `auditor`  
**References:** `REF-01`, `REF-02`, `REF-04`, `REF-05`  
**Prompt:** Independently audit the attribution seam. Confirm the attribution is truthful and decision-useful, and state the next likely tuning move based on the newly exposed winners/margins without overclaiming certainty.

**Folders Created/Deleted/Modified:**
- relevant owning repo paths

**Files Created/Deleted/Modified:**
- audit notes/artifacts as needed

**Status:** ⏳ Pending

**Results:** Pending.

---

## Final Results

**Status:** ⚠️ Partial

**What We Built:** Prototype matcher attribution seam in progress.

**Reference Check:** Pending.

**Commits:**
- Pending.

**Lessons Learned:** Pending.
