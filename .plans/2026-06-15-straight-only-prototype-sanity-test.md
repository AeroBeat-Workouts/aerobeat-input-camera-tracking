# AeroBeat Straight-Only Prototype Sanity Test

**Date:** 2026-06-15  
**Status:** In Progress  
**Last Updated:** 2026-06-15 18:49 EDT  
**Blocked Reason:** None  
**Agent:** `pico`

---

## Goal

Test whether the prototype system can accurately distinguish straight-left and straight-right punches from no-punch conditions when hook and uppercut prototype classes are disabled.

---

## Overview

The previous prototype-local hook-left investigation showed that trimming `boxing_hook_left_window_01` helped only slightly and did not materially clean the negative control. Rather than pushing further immediately on hook-local surgery, Derrick proposed a different sanity-test seam: temporarily narrow the prototype system to straights only and ask a simpler question.

This seam should not retune the matcher yet. It should create a controlled straight-only evaluation mode by disabling hook and uppercut detection in the prototype path, then rerun the benchmark/review flow to measure whether the system can cleanly detect straight-left and straight-right versus no-punch. The output should make it obvious whether the core prototype machinery is viable for straight punches in isolation or whether the confusion is more fundamental than the hook/uppercut class overlap.

---

## REFERENCES

| ID | Description | Path |
| --- | --- | --- |
| `REF-01` | Latest full retest review packet | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/docs/reviews/prototype-matcher-attribution-retest-review-2026-06-15.md` |
| `REF-02` | Latest full retest summary | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/docs/reviews/prototype-matcher-attribution-retest-review-2026-06-15.summary.json` |
| `REF-03` | Current derived library | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/assets/prototype_libraries/boxing_side_aware_fixture_derived_v1/library.json` |
| `REF-04` | Benchmark runner | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/scripts/run_prototype_matcher_fixture_benchmark.py` |
| `REF-05` | Derivation script | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/scripts/derive_prototype_library_from_fixtures.py` |
| `REF-06` | Benchmark manifest | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.testbed/assets/benchmarks/prototype_matcher_boxing_fixture_derived_v1.benchmark.json` |
| `REF-07` | Straight-left fixture YAML | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.testbed/assets/fixtures/boxing/straight_left/boxing_guard->straight_left_repeat_04_take_01.yaml` |
| `REF-08` | Straight-right fixture YAML | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.testbed/assets/fixtures/boxing/straight_right/boxing_guard->straight_right_repeat_04_take_01.yaml` |
| `REF-09` | Negative-control fixture YAML | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.testbed/assets/fixtures/boxing/run_in_place/boxing_guard->run_in_place_repeat_01_take_01.yaml` |

---

## Tasks

### Task 1: Design the straight-only prototype test mode

**Bead ID:** `Pending`  
**SubAgent:** `primary` (for `coder`)  
**Role:** `coder`  
**References:** `REF-01`, `REF-03`, `REF-04`, `REF-06`  
**Prompt:** Define the narrowest truthful way to disable hook and uppercut prototype detection for a straight-only sanity test without retuning the matcher. Claim the bead on start. Document whether this should be done by filtered library generation, filtered benchmark mode, or another minimally invasive test harness path.

**Folders Created/Deleted/Modified:**
- relevant owning repo paths

**Files Created/Deleted/Modified:**
- investigation notes / minimal support files as needed

**Status:** ⏳ Pending

**Results:** Pending.

---

### Task 2: Run the straight-only benchmark + review packet

**Bead ID:** `aerobeat-input-camera-tracking-vyz8`  
**SubAgent:** `primary` (for `coder`)  
**Role:** `coder`  
**References:** `REF-03`, `REF-04`, `REF-05`, `REF-06`, `REF-07`, `REF-08`, `REF-09`  
**Prompt:** Implement the chosen straight-only test mode, rerun the relevant prototype benchmark/review flow, and produce a durable packet that answers whether straight-left and straight-right can be distinguished from no-punch when hook and uppercut prototype classes are disabled. Keep the slice test-focused; do not widen into tuning.

**Folders Created/Deleted/Modified:**
- relevant owning repo paths

**Files Created/Deleted/Modified:**
- straight-only benchmark/review artifacts and minimal support files as needed

**Status:** ⏳ Pending

**Results:** Pending.

---

### Task 3: QA the straight-only sanity test

**Bead ID:** `aerobeat-input-camera-tracking-xs4v`  
**SubAgent:** `primary` (for `qa`)  
**Role:** `qa`  
**References:** `REF-01`, `REF-03`, `REF-04`, `REF-06`, `REF-07`, `REF-08`, `REF-09`  
**Prompt:** Verify the straight-only prototype sanity-test packet. Confirm the test really disabled hook/uppercut prototype detection, confirm the benchmark/review artifacts are internally consistent, and state whether straight-left/right versus no-punch is working accurately enough to justify deeper straight-only exploration.

**Folders Created/Deleted/Modified:**
- relevant owning repo paths

**Files Created/Deleted/Modified:**
- QA notes/artifacts as needed

**Status:** ⏳ Pending

**Results:** Pending.

---

### Task 4: Audit the straight-only result and recommend next branch

**Bead ID:** `aerobeat-input-camera-tracking-nxh7`  
**SubAgent:** `primary` (for `auditor`)  
**Role:** `auditor`  
**References:** `REF-01`, `REF-03`, `REF-04`, `REF-06`, `REF-07`, `REF-08`, `REF-09`  
**Prompt:** Independently audit the straight-only prototype sanity test. Confirm whether the result truthfully demonstrates viable straight-left/right-vs-no-punch discrimination or whether the prototype system is still too noisy even in this simplified mode. Recommend the next branch accordingly.

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
