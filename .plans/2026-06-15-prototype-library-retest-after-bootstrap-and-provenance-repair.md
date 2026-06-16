# AeroBeat Prototype Library Retest After Bootstrap and Provenance Repair

**Date:** 2026-06-15  
**Status:** In Progress  
**Last Updated:** 2026-06-15 14:28 EDT  
**Blocked Reason:** None  
**Agent:** `pico`

---

## Goal

Re-run the prototype-library benchmark/review path after the sync, validation-bootstrap, naming, and provenance repairs to see whether the matcher produces the same substantive results as before.

---

## Overview

We now have the prerequisite trust repairs in place: the all-AeroBeat sync entrypoints are green, the proving-harness validation path is restored and fails fast truthfully when bootstrap state is missing, fixture/runtime vocabulary has been aligned, and the stale straight-right provenance gap in `boxing_side_aware_v1` has been corrected. That means we can finally retest the prototype-library system without the recent environment/provenance noise clouding interpretation.

This seam should answer one question cleanly: when we rerun the benchmark/review path now, do we reproduce the earlier substantive findings — especially the hook-left false-positive culprit pattern and the class-margin behavior — or do the results move enough to change the diagnosis? The seam should stay evidence-first and compare against the earlier review/attribution artifacts instead of guessing from memory.

---

## REFERENCES

| ID | Description | Path |
| --- | --- | --- |
| `REF-01` | Current retested derived library candidate | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/assets/prototype_libraries/boxing_side_aware_fixture_derived_v1/library.json` |
| `REF-02` | Prior attribution review | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/docs/reviews/prototype-matcher-attribution-review-2026-06-13.md` |
| `REF-03` | Prior attribution summary | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/docs/reviews/prototype-matcher-attribution-review-2026-06-13.summary.json` |
| `REF-04` | Benchmark runner | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/scripts/run_prototype_matcher_fixture_benchmark.py` |
| `REF-05` | Derivation script | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/scripts/derive_prototype_library_from_fixtures.py` |
| `REF-06` | Benchmark manifest | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.testbed/assets/benchmarks/prototype_matcher_boxing_fixture_derived_v1.benchmark.json` |
| `REF-07` | Validation-path repair plan | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.plans/2026-06-15-proving-harness-validation-path-breakage.md` |
| `REF-08` | Naming/provenance repair commits | `7e2f9db`, `9a36bf0`, `fc7e1ee` |

---

## Tasks

### Task 1: Re-run prototype-library derivation + benchmark and produce a fresh review packet

**Bead ID:** `aerobeat-input-camera-tracking-kw6k`  
**SubAgent:** `primary` (for `coder`)  
**Role:** `coder`  
**References:** `REF-01`, `REF-04`, `REF-05`, `REF-06`, `REF-07`, `REF-08`  
**Prompt:** Re-run the fixture-derived prototype-library path now that sync/bootstrap/provenance issues are repaired. Regenerate or verify the current derived library as needed, rerun the benchmark/review pipeline, and produce a fresh durable review packet comparing the new results against the earlier attribution evidence. Claim the bead on start, validate your artifacts, then commit/push by default if complete.

**Folders Created/Deleted/Modified:**
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/assets/prototype_libraries/`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/docs/baselines/`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/docs/reviews/`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.testbed/`

**Files Created/Deleted/Modified:**
- regenerated benchmark/review artifacts and any minimally necessary supporting files

**Status:** ✅ Complete

**Results:** Landed commit `7cf761b` (`Rerun prototype matcher attribution after trust repairs`) and pushed to `main`. Re-ran the repaired fixture-derived library flow, regenerated `boxing_side_aware_fixture_derived_v1`, reran the fixture benchmark, and wrote a fresh retest packet at `docs/reviews/prototype-matcher-attribution-retest-review-2026-06-15.md` plus `.summary.json`. Substantive result: the big findings reproduced overall — negative control is still dirty with `30` false-positive emits, hook-left still dominates, `boxing_hook_left_window_01` is still the main false-positive culprit (`24` emits), and very tight wrong-emit class margins remain. Narrower change: the earlier claim that the strongest legitimate hook-left winner was clearly different from the main false-positive culprit did not reproduce cleanly; fresh hook-left readout shifted to peak snapshot winner `boxing_hook_left_window_02` while strongest expected emit was `boxing_hook_left_window_01`. Bead `aerobeat-input-camera-tracking-kw6k` was closed.

---

### Task 2: QA the prototype-library retest

**Bead ID:** `aerobeat-input-camera-tracking-j76d`  
**SubAgent:** `primary` (for `qa`)  
**Role:** `qa`  
**References:** `REF-01`, `REF-02`, `REF-03`, `REF-04`, `REF-05`, `REF-06`  
**Prompt:** Verify the retest artifacts end to end. Confirm the rerun is based on the repaired validation/bootstrap/provenance state, confirm the new review packet matches the new benchmark evidence, and state clearly whether the earlier substantive findings reproduced or changed.

**Folders Created/Deleted/Modified:**
- relevant owning repo paths

**Files Created/Deleted/Modified:**
- QA notes/artifacts as needed

**Status:** ⏳ Pending

**Results:** Pending.

---

### Task 3: Audit the prototype-library retest and closure recommendation

**Bead ID:** `aerobeat-input-camera-tracking-h2d7`  
**SubAgent:** `primary` (for `auditor`)  
**Role:** `auditor`  
**References:** `REF-01`, `REF-02`, `REF-03`, `REF-04`, `REF-05`, `REF-06`  
**Prompt:** Independently audit the retest. Confirm whether the new rerun truthfully reproduces the earlier matcher findings or materially changes them, and recommend the next seam accordingly. Close the bead only if the retest packet is evidence-backed and the conclusion is calibrated.

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
