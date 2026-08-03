# Prototype Library Class-Separation Seam

**Date:** 2026-06-13  
**Status:** Stale
**Last Updated:** 2026-06-13 21:06 EDT  
**Blocked Reason:** Two library-only class-separation experiments regressed the benchmark; next move requires attribution-guided tuning rather than further blind prototype surgery.  

**Stale Archive Note:** Marked stale and archived on 2026-08-03 during Byte workspace cleanup; newer AeroBeat work remains with Pico.
**Agent:** `pico`

---

## Goal

Improve class separability in the derived boxing prototype library — especially hook/uppercut overlap and left-vs-right disambiguation — and re-benchmark to see whether wrong emits and negative-control pollution fall without killing the newly recovered expected emits.

---

## Overview

The derived-library benchmark was the first genuinely meaningful quality readout for the new system. It solved the dead-matcher problem from the seed library: all 6 positive fixtures now emit expected events. But it also revealed the next real failure mode: structured overlap and confusion. Hooks cross-fire into each other, uppercuts drift into opposite-side hooks, straights still leak into other classes, and the negative control now emits many false positives.

That makes the next seam clear. This is no longer primarily a provenance problem or a dead-threshold problem; it is a class-separability problem inside the prototype truth source and its immediate scoring context. The next useful move is to tune the prototype library itself — likely selection, pruning, normalization, or class-shape refinement around left/right and hook/uppercut distinctions — before reaching for broad threshold strangling. The benchmark harness we already have remains the arbiter.

This slice should stay narrow and evidence-driven: improve class separation in the derived library and then benchmark again to see whether expected emits survive while wrong emits / negative-control pollution drop.

---

## REFERENCES

| ID | Description | Path |
| --- | --- | --- |
| `REF-01` | Derived library candidate | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/assets/prototype_libraries/boxing_side_aware_fixture_derived_v1/library.json` |
| `REF-02` | Derived-library provenance report | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/assets/prototype_libraries/boxing_side_aware_fixture_derived_v1/derivation_report.json` |
| `REF-03` | Derived-library benchmark review packet | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/docs/reviews/prototype-matcher-derived-library-review-2026-06-13.md` |
| `REF-04` | Derived-library benchmark results | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/docs/baselines/prototype-matcher-boxing-fixture-derived-v1/benchmark-results.json` |
| `REF-05` | Benchmark runner | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/scripts/run_prototype_matcher_fixture_benchmark.py` |

---

## Tasks

### Task 1: Tune derived prototype library class separation

**Bead ID:** `aerobeat-input-camera-tracking-dauo`  
**SubAgent:** `primary` (for `coder`)  
**Role:** `coder`  
**References:** `REF-01`, `REF-02`, `REF-03`, `REF-04`, `REF-05`  
**Prompt:** Implement the next narrow prototype-matcher slice in `aerobeat-input-camera-tracking`: improve class separability in the derived library, especially hook/uppercut overlap and left-vs-right disambiguation, then rerun the benchmark. Claim the bead on start. Keep the work evidence-driven, avoid broad threshold strangling as the first move, and commit/push by default if the slice is complete.

**Folders Created/Deleted/Modified:**
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking`

**Files Created/Deleted/Modified:**
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/docs/baselines/prototype-matcher-boxing-fixture-derived-v1-class-separation-pass1/benchmark-results.json`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/docs/baselines/prototype-matcher-boxing-fixture-derived-v1-class-separation-pass1/benchmark-results.md`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/docs/baselines/prototype-matcher-boxing-fixture-derived-v1-class-separation-pass2/benchmark-results.json`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/docs/baselines/prototype-matcher-boxing-fixture-derived-v1-class-separation-pass2/benchmark-results.md`
- `assets/prototype_libraries/boxing_side_aware_fixture_derived_v1/library.json` (experimented on, then reverted)
- `assets/prototype_libraries/boxing_side_aware_fixture_derived_v1/derivation_report.json` (experimented on, then reverted)

**Status:** ❌ Failed

**Results:** Two evidence-driven library-only class-separation experiments were run against `boxing_side_aware_fixture_derived_v1`, then reverted because both made the benchmark worse. Pass 1 pruned overlap/outlier prototypes with poor own-vs-other separation margins; pass 2 used centroid-style representative prototypes for noisy hook/uppercut families while leaving straights raw. Baseline derived-library readout before the experiments: `98` positive expected emits, `74` positive wrong emits, `30` negative-control wrong emits. Pass 1 regressed to `89` expected, `82` wrong, `30` negative-control wrong; pass 2 regressed further to `79` expected, `88` wrong, `30` negative-control wrong. Negative-control pollution did not improve meaningfully, and expected emits were harmed. No commit was made, and the library was restored to its original derived state. Correct next move from this failed slice: stop blind prototype surgery and move to matcher attribution / winning-prototype instrumentation first.

---

### Task 2: QA the class-separation slice

**Bead ID:** `aerobeat-input-camera-tracking-0v97`  
**SubAgent:** `primary` (for `qa`)  
**Role:** `qa`  
**References:** `REF-01`, `REF-03`, `REF-04`, `REF-05`  
**Prompt:** Verify the class-separation slice. Confirm the benchmark artifacts are real, the expected/wrong/negative-control deltas are stated truthfully, and the library changes really target overlap rather than just hiding problems.

**Folders Created/Deleted/Modified:**
- relevant owning repo paths

**Files Created/Deleted/Modified:**
- QA notes/artifacts as needed

**Status:** ⏳ Pending

**Results:** Pending.

---

### Task 3: Audit the class-separation slice and decide next branch

**Bead ID:** `aerobeat-input-camera-tracking-nbzy`  
**SubAgent:** `primary` (for `auditor`)  
**Role:** `auditor`  
**References:** `REF-01`, `REF-03`, `REF-04`, `REF-05`  
**Prompt:** Independently audit the class-separation slice. Confirm the benchmark changes are real, preserve the right caveats, and state whether the next branch should continue prototype tuning or switch to threshold/gating based on the new evidence.

**Folders Created/Deleted/Modified:**
- relevant owning repo paths

**Files Created/Deleted/Modified:**
- audit notes/artifacts as needed

**Status:** ⏳ Pending

**Results:** Pending.

---

## Final Results

**Status:** ❌ Blocked

**What We Built:** Two measured class-separation experiments plus durable benchmark artifacts showing that naive pruning and centroid-style replacement did not improve the derived-library confusion pattern.

**Reference Check:** `REF-01` through `REF-05` satisfied for the attempted slice. The work stayed library-focused and benchmark-driven.

**Commits:**
- None; no improved candidate was found, so the library was reverted to its original derived state.

**Lessons Learned:** Attribution matters. Even evidence-driven prototype pruning can still be too blind if we do not know which exact prototypes are winning on wrong emits and negative-control pollution.
