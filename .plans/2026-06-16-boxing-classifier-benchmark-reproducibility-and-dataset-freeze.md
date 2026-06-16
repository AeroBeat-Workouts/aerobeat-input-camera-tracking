# AeroBeat Boxing Classifier Benchmark Reproducibility and Dataset Freeze

**Date:** 2026-06-16
**Status:** In Progress
**Last Updated:** 2026-06-16 19:24 EDT
**Blocked Reason:** None.
**Agent:** `pico`

---

## Goal

Make the boxing punch-classifier benchmark reproducible enough that future model-family comparisons are trustworthy by freezing export inputs, locking capture-report provenance, and stabilizing replay/dataset regeneration around a named dataset snapshot.

---

## Overview

The last hardening slice did useful work: it made the benchmark harder and exposed that the earlier temporal-MLP advantage was not robust. But the latest audit also made the current blocker explicit: the archived hardened dataset is the real reproducibility anchor, while fresh exporter reruns do not yet byte-reproduce that dataset or its threshold metrics. That means the system can currently answer questions about one frozen artifact set, but not yet regenerate the same benchmark on demand with enough confidence to support another model-family comparison.

This branch should attack that exact bottleneck. The work is not about picking MLP versus CNN again yet. It is about making the benchmark machinery boring and reliable: the exact source fixtures, truth files, capture-report artifacts, export settings, split strategy, and alignment basis should be explicitly frozen; the exporter should record provenance clearly enough that a dataset can be traced back to a single known source package; and rerunning the export path from the frozen source set should either reproduce the same dataset or produce a sharply explained mismatch. Only after that should the repo trust another model-family comparison.

This stays inside the current hybrid boxing architecture. Threshold/pose continues owning non-punch state like guard, and the classifier path remains punch-only. The objective here is benchmark trust, not runtime architecture change.

---

## REFERENCES

| ID | Description | Path |
| --- | --- | --- |
| `REF-01` | Completed eval/data hardening plan and audit result | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.plans/2026-06-16-boxing-classifier-eval-and-data-hardening.md` |
| `REF-02` | Current classifier harness docs | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/docs/baselines/boxing-punch-classifier-harness.md` |
| `REF-03` | Current harness/export script | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/scripts/export_boxing_punch_classifier_dataset.py` |
| `REF-04` | Current shared classifier harness helpers | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/scripts/boxing_classifier_harness.py` |
| `REF-05` | Archived hardened reproducibility anchor | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.temp/boxing-punch-classifier-export/hardened-2026-06-16/` |
| `REF-06` | Current fixture videos and YAML truth windows | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.testbed/assets/fixtures/boxing/` |
| `REF-07` | Prior replay substrate freeze memory | `memory/2026-06-12.md#L1-L11` |
| `REF-08` | Prior classifier architecture freeze memory | `memory/2026-06-11.md#L1-L10` |

---

## Tasks

### Task 1: Freeze export inputs and lock capture-report provenance for a named benchmark snapshot

**Bead ID:** `aerobeat-input-camera-tracking-8y3l`
**SubAgent:** `primary` (for `coder`)
**Role:** `coder`
**References:** `REF-01`, `REF-02`, `REF-03`, `REF-04`, `REF-05`, `REF-06`, `REF-07`, `REF-08`
**Prompt:** Materialize a named benchmark snapshot for the boxing punch-classifier harness. Freeze the exact export inputs (fixtures, truth windows, capture-report source set, export parameters, split strategy, negative-sampling policy) and lock capture-report provenance so the generated dataset can be traced back to an explicit source package. Update the exporter/docs/artifacts so a future rerun knows exactly which source set it is supposed to recreate.

**Folders Created/Deleted/Modified:**
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/scripts/`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/docs/`
- benchmark snapshot / manifest paths as needed

**Files Created/Deleted/Modified:**
- exporter/provenance/docs/manifest artifacts and minimally necessary support files

**Status:** ✅ Complete

**Results:** Added a named frozen snapshot manifest at `.testbed/assets/benchmarks/boxing_punch_classifier_hardened_2026_06_16.snapshot.json` plus companion `.md`, generated from the archived hardened capture-report package and dataset anchor in `REF-05`. The snapshot now freezes exact fixture YAML/video hashes, full truth-window listings, per-fixture capture-report hashes and time-origin offsets, export parameters, split strategy, negative-sampling policy, and the archived dataset/export-summary/threshold-baseline SHA-256 anchors. `scripts/export_boxing_punch_classifier_dataset.py` now accepts `--snapshot-manifest`, verifies the manifest/fixture/video/report hashes before export, and records the resolved frozen snapshot provenance into `dataset.json` / `export-summary.{json,md}` so future reruns know exactly which source package they are targeting. Added `scripts/freeze_boxing_punch_classifier_snapshot.py` to materialize this manifest shape from an archived capture package, and updated `docs/baselines/boxing-punch-classifier-harness.md` with the named snapshot + rerun command. Targeted validation showed that exporting from the frozen snapshot with `--skip-captures` reproduces the archived threshold baseline byte-for-byte and reproduces the archived dataset content after normalizing the newly added provenance/version/export timestamp fields; the archived `dataset.json` itself is not byte-identical yet because this push intentionally adds new snapshot provenance metadata.

---

### Task 2: Validate stable replay / dataset regeneration against the frozen snapshot

**Bead ID:** `aerobeat-input-camera-tracking-cvkt`
**SubAgent:** `primary` (for `coder`)
**Role:** `coder`
**References:** `REF-01`, `REF-03`, `REF-04`, `REF-05`
**Prompt:** Using the named frozen benchmark snapshot, test whether dataset regeneration is now stable enough. If the rerun reproduces byte-for-byte, document that. If it still diverges, narrow the source of divergence and harden the replay/export path until the mismatch is either eliminated or sharply diagnosed. Keep this focused on reproducibility, not new model experiments.

**Folders Created/Deleted/Modified:**
- relevant owning repo paths

**Files Created/Deleted/Modified:**
- replay/export/docs artifacts as needed

**Status:** ⏳ Pending

**Results:** Pending.

---

### Task 3: QA the frozen snapshot and regeneration behavior

**Bead ID:** `aerobeat-input-camera-tracking-ybgk`
**SubAgent:** `primary` (for `qa`)
**Role:** `qa`
**References:** `REF-01`, `REF-02`, `REF-03`, `REF-04`, `REF-05`
**Prompt:** Verify the named benchmark snapshot really freezes export inputs and capture-report provenance clearly enough, and verify whether regeneration from that snapshot is stable or at least sharply diagnosable. Confirm whether the benchmark is now trustworthy enough to support future model-family comparisons.

**Folders Created/Deleted/Modified:**
- relevant owning repo paths

**Files Created/Deleted/Modified:**
- QA notes/artifacts as needed

**Status:** ⏳ Pending

**Results:** Pending.

---

### Task 4: Audit reproducibility readiness and recommend when model comparisons may resume

**Bead ID:** `aerobeat-input-camera-tracking-jd8d`
**SubAgent:** `primary` (for `auditor`)
**Role:** `auditor`
**References:** `REF-01`, `REF-02`, `REF-03`, `REF-04`, `REF-05`
**Prompt:** Independently audit the new snapshot/provenance/regeneration path. Decide whether the benchmark is now reproducible enough to resume model-family comparisons, or whether another reproducibility slice is still required. Recommend the exact next classifier branch accordingly.

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
