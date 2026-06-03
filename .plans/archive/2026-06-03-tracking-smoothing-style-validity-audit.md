# AeroBeat Tracking Smoothing Style Validity Audit

**Date:** 2026-06-03  
**Status:** Complete  
**Last Updated:** 2026-06-03 15:35 EDT  
**Blocked Reason:** None  
**Agent:** `cookie`

---

## Goal

Audit and fix the remaining `Tracking Smoothing Style` validity bug so all exposed style values either load truthfully or are removed from the proving-scene GUI.

---

## Overview

After the recent proving-scene config cleanup, Derrick manually verified that only `Lite Filtered` and `Lite Raw` produce valid project loads. That means the smoothing-style surface is still not truthfully supported across the full set of exposed values, even though the earlier wiring fix restored part of the contract.

This slice should stay narrow: identify exactly why the non-lite values fail to load, determine whether the issue is invalid config propagation, unsupported model-complexity/runtime combinations, or stale GUI values, and then either fix the wiring or remove unsupported styles from the proving-scene GUI.

---

## REFERENCES

| ID | Description | Path |
| --- | --- | --- |
| `REF-01` | Proving-scene config audit and cleanup plan | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.plans/2026-06-03-proving-scene-config-audit-and-cleanup.md` |
| `REF-02` | User validation result | Only `Lite Filtered` and `Lite Raw` produce valid project loads |

---

## Tasks

### Task 1: Audit smoothing-style validity across all exposed values

**Bead ID:** `aerobeat-input-camera-tracking-6qp`  
**SubAgent:** `primary`  
**Role:** `auditor`  
**References:** `REF-01`, `REF-02`  
**Prompt:** Audit all currently exposed `Tracking Smoothing Style` values and determine why only `Lite Filtered` and `Lite Raw` load validly. Identify which values are truly supported by the current stack, which fail due to wiring/runtime constraints, and whether unsupported values should be removed from the proving-scene GUI.

**Folders Created/Deleted/Modified:**
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.plans/`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/`

**Files Created/Deleted/Modified:**
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.plans/2026-06-03-tracking-smoothing-style-validity-audit.md`

**Status:** ✅ Complete

**Results:** Audited the exposed smoothing-style set and confirmed that only `LITE_RAW` and `LITE_FILTERED` are truthfully supported today. The invalid values were all `FULL_*` and `HEAVY_*`, which fail honestly because the vendor repo only ships `pose_landmarker_lite.task` and does not ship `pose_landmarker_full.task` or `pose_landmarker_heavy.task`. The problem was stale GUI exposure of unsupported model-complexity options, not bad raw/filtered wiring.

---

### Task 2: Fix or prune invalid smoothing-style options

**Bead ID:** `aerobeat-input-camera-tracking-hxp`  
**SubAgent:** `primary`  
**Role:** `coder`  
**References:** `REF-01`, `REF-02`  
**Prompt:** After the audit identifies the truthful supported set, either fix the remaining smoothing-style options so they load correctly or remove unsupported values from the proving-scene GUI. Keep scope narrow and preserve only truthfully supported scene options.

**Folders Created/Deleted/Modified:**
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking`

**Files Created/Deleted/Modified:**
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.testbed/scripts/proving_harness.gd`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.testbed/scenes/boxing_proving.tscn`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.testbed/scenes/flow_proving.tscn`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.testbed/tests/unit/test_proving_harness_trails.gd`

**Status:** ✅ Complete

**Results:** Pruned the proving-harness `Tracking Smoothing Style` exposure down to the only truthfully supported values: `LITE_RAW` and `LITE_FILTERED`. Kept the default on `LITE_FILTERED` and updated both proving scenes so their serialized inspector state matches. Replaced the stale full/heavy coverage with a guard that every exposed smoothing style must map to an existing vendor model asset. Full repo-local suite passed `84/84`, and commit `1f689f2` (`Prune unsupported tracking smoothing styles`) was pushed.

---

## Final Results

**Status:** ✅ Complete

**What We Built:** Audited the proving-scene smoothing-style surface and pruned it to the only truthfully supported options backed by existing vendor model assets.

**Reference Check:** `REF-01` and `REF-02` were used. The fix stayed narrow and removed stale GUI exposure instead of pretending unsupported model variants were valid.

**Commits:**
- `1f689f2` - Prune unsupported tracking smoothing styles

**Lessons Learned:** A scene option set is only honest if every exposed value is actually bootable on the current stack. When assets for full/heavy variants are absent, pruning those values is better than leaving a false choice in the GUI.
