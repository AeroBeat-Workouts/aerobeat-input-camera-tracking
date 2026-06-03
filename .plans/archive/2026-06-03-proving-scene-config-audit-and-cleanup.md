# AeroBeat Proving Scene Config Audit And Cleanup

**Date:** 2026-06-03  
**Status:** Complete  
**Last Updated:** 2026-06-03 15:01 EDT  
**Blocked Reason:** None  
**Agent:** `cookie`

---

## Goal

Audit the proving-scene configuration surface and fix or remove stale variables so the scene only exposes controls that truthfully flow into the camera-tracking stack.

---

## Overview

Derrick found four likely regressions/questions in the proving harness configuration surface:

1. `Tracking Overlay Mode` values (`full`, `lite`, `none`) do not appear to propagate into `aerobeat-tool-camera-tracking` or the vendor layer.
2. `Tracking Smoothing Style` also does not seem to propagate correctly, and switching away from `Lite Filtered` appears to break startup, suggesting invalid or stale config values.
3. `Overlay Visibility Threshold` may no longer be wired to anything meaningful and may be safe to remove.
4. `Gesture Eval Interval Frames` may no longer be connected after refactors, or may still be intended only for input-side gesture evaluation cadence.

This slice should begin with a truth audit of the proving-harness variable surface versus the current config contract across `aerobeat-input-camera-tracking`, `aerobeat-tool-camera-tracking`, and `aerobeat-vendor-mediapipe-python`. Then we should either wire the values through correctly or delete stale scene variables that no longer map to a real supported contract.

---

## REFERENCES

| ID | Description | Path |
| --- | --- | --- |
| `REF-01` | User bug list for proving scene config surface | Current chat message on 2026-06-03 14:22 EDT |
| `REF-02` | Current proving harness script | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.testbed/scripts/proving_harness.gd` |
| `REF-03` | Input repo config/adapter seams | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/src/` |
| `REF-04` | Tool repo tracking config contract | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-tool-camera-tracking/src/` |
| `REF-05` | Vendor runtime/config contract | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-vendor-mediapipe-python/src/` and `/runtime/` |

---

## Tasks

### Task 1: Audit proving-scene variable truth

**Bead ID:** `aerobeat-input-camera-tracking-nx0`  
**SubAgent:** `primary`  
**Role:** `auditor`  
**References:** `REF-01`, `REF-02`, `REF-03`, `REF-04`, `REF-05`  
**Prompt:** Audit the proving harness variables `Tracking Overlay Mode`, `Tracking Smoothing Style`, `Overlay Visibility Threshold`, and `Gesture Eval Interval Frames`. Determine which ones still map to real supported config fields, which are stale/disconnected, and which are using invalid values after the recent refactors.

**Folders Created/Deleted/Modified:**
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.plans/`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/`

**Files Created/Deleted/Modified:**
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.plans/2026-06-03-proving-scene-config-audit-and-cleanup.md`

**Status:** ✅ Complete

**Results:** Audited the four proving-scene variables. `Tracking Smoothing Style` is partially wired and needs raw/filtered propagation repair on the active contract path. `Overlay Visibility Threshold` is still wired and meaningful. `Gesture Eval Interval Frames` is still wired and truthfully controls input-side gesture evaluation cadence. `Tracking Overlay Mode` is semantically stale/misleading in its current GUI form: `full`/`optimized` still influence vendor tracking semantics, but the setting no longer truthfully controls overlay visibility, and unsupported/stale values should not remain exposed in the scene GUI.

---

### Task 2: Wire through valid supported config

**Bead ID:** `aerobeat-input-camera-tracking-gut`  
**SubAgent:** `primary`  
**Role:** `coder`  
**References:** `REF-02`, `REF-03`, `REF-04`, `REF-05`  
**Prompt:** For proving-scene variables that still correspond to real supported camera-tracking or vendor config, wire them through truthfully using currently valid contract values.

**Folders Created/Deleted/Modified:**
- `/home/derrick/.openclaw/workspace/projects/aerobeat/`

**Files Created/Deleted/Modified:**
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.testbed/scripts/proving_harness.gd`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.testbed/tests/unit/test_camera_tracking_provider.gd`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.testbed/tests/unit/test_proving_harness_trails.gd`

**Status:** ✅ Complete

**Results:** Kept `Tracking Smoothing Style` and repaired its truthful propagation on the active contract path. The harness now forwards vendor runtime filter flags (`runtime.filter_enabled` and `runtime.no_filter`) in addition to model complexity, so raw vs filtered semantics are no longer collapsed. `Overlay Visibility Threshold` and `Gesture Eval Interval Frames` remain preserved as real supported settings. Full repo-local test suite passed, and the changes were included in commit `43dd07a` (`Fix proving config wiring truth`).

---

### Task 3: Remove stale or disconnected scene variables

**Bead ID:** `aerobeat-input-camera-tracking-j71`  
**SubAgent:** `primary`  
**Role:** `coder`  
**References:** `REF-01`, `REF-02`  
**Prompt:** Remove proving-scene variables that are stale, disconnected, or no longer part of the supported tracking contract, while preserving any legitimate input-side evaluation settings that still matter.

**Folders Created/Deleted/Modified:**
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking`

**Files Created/Deleted/Modified:**
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.testbed/scripts/proving_harness.gd`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.testbed/scenes/boxing_proving.tscn`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.testbed/scenes/flow_proving.tscn`

**Status:** ✅ Complete

**Results:** Removed the misleading proving-scene GUI surface for `Tracking Overlay Mode` and deleted its saved scene-facing entries from `boxing_proving.tscn` and `flow_proving.tscn`. The harness now pins overlay mode internally to the stable supported default `optimized` rather than exposing a control that no longer truthfully maps to active overlay visibility behavior. Full repo-local test suite passed, and the changes were included in commit `43dd07a` (`Fix proving config wiring truth`).

---

## Final Results

**Status:** ✅ Complete

**What We Built:** Audited and cleaned up the proving-scene config surface so only truthfully supported variables remain exposed, while valid smoothing/filter semantics are now correctly wired through the active contract path.

**Reference Check:** `REF-01` through `REF-05` were used. The cleanup removed misleading GUI surface area and preserved the still-real scene variables.

**Commits:**
- `43dd07a` - Fix proving config wiring truth

**Lessons Learned:** Inspector surfaces drift quickly after contract refactors. If a variable no longer maps truthfully to active behavior, removing it is better than leaving a misleading control in the scene GUI.
