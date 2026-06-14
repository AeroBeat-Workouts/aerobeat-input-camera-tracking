# Benchmark Derived Prototype Library Candidate

**Date:** 2026-06-13  
**Status:** Complete  
**Last Updated:** 2026-06-13 20:44 EDT  
**Blocked Reason:** None  
**Agent:** `pico`

---

## Goal

Run the prototype matcher against the new derived library candidate and summarize the resulting expected/wrong/negative-control behavior so the next tuning branch can be chosen from real confusion evidence.

---

## Overview

The provenance side is now in much better shape: fixture videos, verified YAML timing windows, generated pose data, and alignment/provenance handling are all wired up truthfully. That means the next benchmark against the derived library candidate should be the first truly meaningful classifier-quality readout for this branch.

The immediate goal is not to tune yet, but to benchmark and interpret. We need a clean artifact that answers whether the new derived truth source improves expected emits, worsens wrong emits, pollutes the negative control, or simply changes the confusion pattern. Once that evidence exists, the next implementation branch can be selected deliberately — likely threshold tuning, prototype-library cleanup/selection, or state/emit logic tuning.

---

## REFERENCES

| ID | Description | Path |
| --- | --- | --- |
| `REF-01` | Derived prototype library candidate | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/assets/prototype_libraries/boxing_side_aware_fixture_derived_v1/library.json` |
| `REF-02` | Derived-library provenance report | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/assets/prototype_libraries/boxing_side_aware_fixture_derived_v1/derivation_report.json` |
| `REF-03` | Existing benchmark runner | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/scripts/run_prototype_matcher_fixture_benchmark.py` |
| `REF-04` | Existing seed-library benchmark baseline | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/docs/baselines/prototype-matcher-boxing-side-aware-v1/benchmark-results.json` |
| `REF-05` | Alignment-fix plan/results | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.plans/2026-06-13-fix-derived-prototype-window-alignment.md` |

---

## Tasks

### Task 1: Benchmark the derived library candidate and summarize confusion

**Bead ID:** `aerobeat-input-camera-tracking-kl2l`  
**SubAgent:** `primary` (for `coder`)  
**Role:** `coder`  
**References:** `REF-01`, `REF-02`, `REF-03`, `REF-04`, `REF-05`  
**Prompt:** Run the prototype matcher benchmark using the derived library candidate, then summarize the resulting expected emits, wrong emits, negative-control behavior, and main confusion patterns. Claim the bead on start. Keep this slice evidence-first: produce the benchmark artifacts and a concise summary that points at the most plausible next tuning branch without overclaiming certainty. Commit/push by default if complete.

**Folders Created/Deleted/Modified:**
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking`

**Files Created/Deleted/Modified:**
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/docs/baselines/prototype-matcher-boxing-fixture-derived-v1/benchmark-results.json`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/docs/baselines/prototype-matcher-boxing-fixture-derived-v1/benchmark-results.md`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/docs/reviews/prototype-matcher-derived-library-review-2026-06-13.md`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/docs/reviews/prototype-matcher-derived-library-review-2026-06-13.summary.json`

**Status:** ✅ Complete

**Results:** Landed and pushed commit `0439c05`, rerunning the matcher against `boxing_side_aware_fixture_derived_v1` and writing a durable review packet. The derived library solved the dead-matcher problem from the seed baseline: all 6 positive fixtures now emitted expected events. But it also exposed the next real failure mode: heavy structured confusion and dirty negative-control behavior. Summary: seed baseline had `0/6` positives with expected emits and clean negative control; derived candidate had `6/6` positives with expected emits, `98` total expected emits on positives, `74` total wrong emits on positives, and `30` attack events on the run-in-place negative control. Main confusion pattern: left/right hooks cross-fire into each other, uppercuts drift into opposite-side hooks, and straights still leak into other classes. Recommended next branch from that evidence: prototype-library class-separability / side-disambiguation tuning before broad threshold strangling.

---

### Task 2: QA the derived-library benchmark readout

**Bead ID:** `aerobeat-input-camera-tracking-tfex`  
**SubAgent:** `primary` (for `qa`)  
**Role:** `qa`  
**References:** `REF-01`, `REF-02`, `REF-03`, `REF-04`  
**Prompt:** Verify the derived-library benchmark readout. Confirm the artifacts are real, the summary matches them, and the identified confusion pattern is stated truthfully.

**Folders Created/Deleted/Modified:**
- relevant owning repo paths

**Files Created/Deleted/Modified:**
- QA notes/artifacts as needed

**Status:** ⏳ Pending

**Results:** Pending.

---

### Task 3: Audit the benchmark readout and recommend next tuning branch

**Bead ID:** `aerobeat-input-camera-tracking-x62m`  
**SubAgent:** `primary` (for `auditor`)  
**Role:** `auditor`  
**References:** `REF-01`, `REF-02`, `REF-03`, `REF-04`, `REF-05`  
**Prompt:** Independently audit the derived-library benchmark readout. Confirm the summary is truthful and that the recommended next tuning branch is evidence-based rather than speculative.

**Folders Created/Deleted/Modified:**
- relevant owning repo paths

**Files Created/Deleted/Modified:**
- audit notes/artifacts as needed

**Status:** ⏳ Pending

**Results:** Pending.

---

## Final Results

**Status:** ✅ Complete

**What We Built:** A durable benchmark and review packet for the first truthful derived prototype library candidate, establishing that the matcher is alive on all 6 positive fixtures but still heavily confused and negative-control-dirty.

**Reference Check:** `REF-01` through `REF-05` satisfied. The slice stayed focused on benchmarking the derived candidate, summarizing the confusion pattern, and selecting the next tuning branch from evidence.

**Commits:**
- `0439c05` - Add derived prototype library benchmark review

**Lessons Learned:** Fixing provenance and deriving truthful prototypes can wake a dead matcher up immediately, but that can expose a deeper classification/confusion problem that needs class-separation work rather than more provenance work.
