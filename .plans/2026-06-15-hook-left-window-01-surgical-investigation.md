# AeroBeat Hook-Left Window 01 Surgical Investigation

**Date:** 2026-06-15  
**Status:** In Progress  
**Last Updated:** 2026-06-15 15:07 EDT  
**Blocked Reason:** None  
**Agent:** `pico`

---

## Goal

Isolate and surgically test `boxing_hook_left_window_01` as the dominant bulk false-positive culprit before attempting broader class-wide tuning.

---

## Overview

The repaired retest packet confirmed the same substantive matcher diagnosis after sync/bootstrap/provenance repairs: the dirty negative control still produces 30 false-positive emits, `hook_left` still dominates that noise, and `boxing_hook_left_window_01` remains the true bulk culprit with 24 false-positive emits. That means the next honest move is not broad threshold strangling or class-wide edits; it is a prototype-local investigation.

This seam should treat `boxing_hook_left_window_01` like a contaminated specimen. First, inspect its exact lineage and compare it against the other hook-left windows to understand whether the problem is timing breadth, transition contamination, pose shape, normalization/resampling, or simple similarity to run-in-place motion. Then run the narrowest intervention — prune, tighten, or re-derive only that prototype — and immediately rerun attribution to see whether the negative-control burden drops without collapsing legitimate hook-left detection. Only if that fails materially should we move to the secondary branch of class-margin gating.

---

## REFERENCES

| ID | Description | Path |
| --- | --- | --- |
| `REF-01` | Fresh retest review packet | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/docs/reviews/prototype-matcher-attribution-retest-review-2026-06-15.md` |
| `REF-02` | Fresh retest summary | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/docs/reviews/prototype-matcher-attribution-retest-review-2026-06-15.summary.json` |
| `REF-03` | Fresh retest benchmark JSON | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/docs/baselines/prototype-matcher-boxing-fixture-derived-v1-retest-2026-06-15/benchmark-results.json` |
| `REF-04` | Current derived library | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/assets/prototype_libraries/boxing_side_aware_fixture_derived_v1/library.json` |
| `REF-05` | Current derivation report | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/assets/prototype_libraries/boxing_side_aware_fixture_derived_v1/derivation_report.json` |
| `REF-06` | Derivation script | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/scripts/derive_prototype_library_from_fixtures.py` |
| `REF-07` | Benchmark runner | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/scripts/run_prototype_matcher_fixture_benchmark.py` |
| `REF-08` | Hook-left fixture YAML | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.testbed/assets/fixtures/boxing/hook_left/boxing_guard->hook_left_repeat_04_take_01.yaml` |

---

## Tasks

### Task 1: Inspect `boxing_hook_left_window_01` lineage and choose the narrowest intervention

**Bead ID:** `aerobeat-input-camera-tracking-95ff`  
**SubAgent:** `primary` (for `coder`)  
**Role:** `coder`  
**References:** `REF-01`, `REF-02`, `REF-03`, `REF-04`, `REF-05`, `REF-08`  
**Prompt:** Inspect `boxing_hook_left_window_01` in detail against the other hook-left windows and the fresh retest evidence. Determine whether the narrowest credible intervention should be pruning, tighter re-segmentation, or single-window re-derivation. Claim the bead on start. Keep this evidence-first and document the exact reason for the chosen intervention.

**Folders Created/Deleted/Modified:**
- relevant owning repo paths

**Files Created/Deleted/Modified:**
- investigation notes/artifacts as needed

**Status:** ⏳ Pending

**Results:** Pending.

---

### Task 2: Apply the single-window intervention and rerun attribution

**Bead ID:** `aerobeat-input-camera-tracking-k6mf`  
**SubAgent:** `primary` (for `coder`)  
**Role:** `coder`  
**References:** `REF-03`, `REF-04`, `REF-05`, `REF-06`, `REF-07`, `REF-08`  
**Prompt:** Apply only the chosen `boxing_hook_left_window_01` intervention, rerun derivation/benchmark/attribution, and produce a comparison packet against the current retest baseline. Claim the bead on start. Do not widen into other class edits or margin gating.

**Folders Created/Deleted/Modified:**
- relevant owning repo paths

**Files Created/Deleted/Modified:**
- prototype library / benchmark / review artifacts and minimal supporting files as needed

**Status:** ✅ Complete

**Results:** Landed commit `c3e25af` (`Record hook-left window 01 trim rerun`) and closed bead `aerobeat-input-camera-tracking-k6mf`. Kept a tighter `boxing_hook_left_window_01` trim of `1200-1450ms`, regenerated the derived library, reran the benchmark, and wrote a comparison packet at `docs/reviews/prototype-matcher-hook-left-window01-trim-review-2026-06-15.md` plus `.summary.json`. Final committed rerun outcome: only a small negative-control improvement remained (`30 -> 29` total false positives, `24 -> 23` hook-left false positives, `24 -> 23` `boxing_hook_left_window_01` attributions). Legitimate hook-left behavior did not collapse (`10 -> 13` expected hook-left events on the hook-left fixture; wrong events there improved `18 -> 14`). Direct conclusion: the single-window trim helped a bit but not enough to count as a successful fix.

---

### Task 3: QA the single-window intervention

**Bead ID:** `aerobeat-input-camera-tracking-cwf0`  
**SubAgent:** `primary` (for `qa`)  
**Role:** `qa`  
**References:** `REF-01`, `REF-02`, `REF-03`, `REF-04`, `REF-07`  
**Prompt:** Verify the single-window intervention end to end. Confirm whether run-in-place false positives dropped, whether legitimate hook-left behavior remained acceptable, and whether any new culprit replaced `boxing_hook_left_window_01`.

**Folders Created/Deleted/Modified:**
- relevant owning repo paths

**Files Created/Deleted/Modified:**
- QA notes/artifacts as needed

**Status:** ⏳ Pending

**Results:** Pending.

---

### Task 4: Audit the single-window intervention and recommend branch 2

**Bead ID:** `aerobeat-input-camera-tracking-zxzv`  
**SubAgent:** `primary` (for `auditor`)  
**Role:** `auditor`  
**References:** `REF-01`, `REF-02`, `REF-03`, `REF-04`, `REF-07`  
**Prompt:** Independently audit the single-window intervention. Confirm whether it materially helped and recommend the next branch: continue prototype-local surgery (possibly `boxing_hook_left_window_03`) or switch to class-margin gating.

**Folders Created/Deleted/Modified:**
- relevant owning repo paths

**Files Created/Deleted/Modified:**
- audit notes/artifacts as needed

**Status:** ⏳ Pending

**Results:** Pending.

---

## Final Results

**Status:** ⚠️ Partial

**What We Built:** Pending.

**Reference Check:** Pending.

**Commits:**
- Pending.

**Lessons Learned:** Pending.
