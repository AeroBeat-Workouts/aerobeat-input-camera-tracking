# AeroBeat Input Camera Tracking — Boxing Testbed Live/Replay/Timeline Audit

**Date:** 2026-06-02  
**Status:** In Progress  
**Last Updated:** 2026-06-02 12:09 EDT  
**Blocked Reason:** None  
**Agent:** Cookie 🍪

---

## Goal

Audit `aerobeat-input-camera-tracking` to determine why the `.testbed` Boxing testing scene no longer starts live webcam mode, why video replay also no longer starts, and why the replay timeline seek bar becomes vertically squashed.

---

## Overview

Derrick reported three likely-related regressions in the `.testbed` Boxing testing scene after recent refactoring: live camera does not start, video replay also does not start, and the replay timeline/seekbar UI becomes squashed when the controls are vertically aligned. The current ask is forensic: identify why these failures happen and report the likely root causes rather than immediately patching them.

This audit will inspect recent camera-tracking refactor history, the current `.testbed` Boxing scene wiring, the runtime/testbed path used to start live and replay sessions, and the replay UI layout structure. The screenshot should be treated as corroborating evidence for the seekbar layout issue, but the main source of truth will be the current repo state and any reproducible runtime/log evidence available through the testbed.

---

## REFERENCES

| ID | Description | Path |
| --- | --- | --- |
| `REF-01` | Repo under audit | `/workspace/projects/aerobeat/aerobeat-input-camera-tracking` |
| `REF-02` | Current `.testbed` addon manifest and proving project | `/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.testbed/` |
| `REF-03` | Recent archived camera-tracking / replay / boxing plans in this repo | `/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.plans/archive/` |
| `REF-04` | User-provided screenshot showing the squashed replay seekbar | `/home/derrick/.openclaw/workspace/.temp/nerve-uploads/2026/06/02/image-7549d988.png` |

---

## Tasks

### Task 1: Research current Boxing testbed wiring and likely regression points

**Bead ID:** `aerobeat-input-camera-tracking-m0w`  
**SubAgent:** `primary`  
**Role:** `research`  
**References:** `REF-01`, `REF-02`, `REF-03`, `REF-04`  
**Prompt:** In `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking`, claim the assigned bead when you start. Audit the current `.testbed` Boxing testing scene and the recent camera-tracking/refactor surfaces to determine why live webcam no longer starts, why video replay also no longer starts, and why the replay timeline seek bar is vertically squashed. Use repo files, archived plans, and any safe local validation/log inspection needed to produce likely root causes with concrete evidence. Treat this as a forensic audit, not a fix pass. Do not modify the repo. Close the bead with an honest reason when done.

**Folders Created/Deleted/Modified:**
- none expected

**Files Created/Deleted/Modified:**
- none expected

**Status:** ✅ Complete

**Results:** Research pass found one shared runtime regression and one separate UI regression. For both live webcam and video replay startup, the most likely primary root cause is the Jun 1 contract-only refactor in commit `2770d54` removing the backend-registration seam from `src/AeroCameraTracking.gd` while the provider still requests `backend = camera_tracking_default`, which resolves through the tool contract to `mediapipe_python`. Current `src/AeroCameraTracking.gd` no longer registers that vendor backend before startup, and headless probing in the `.testbed` showed both live and replay sessions end in `state=error` with `last_error.code = backend_unregistered` and message `No camera tracking backend factory is registered for 'mediapipe_python'`. The provider code in `src/providers/camera_tracking_provider.gd` still routes both live and replay through that same backend request. The research pass also noted a likely secondary replay-specific weakness: the same refactor removed older replay duration/status plumbing from `AeroCameraTracking.gd`, so replay transport/status may still need additional repair after backend registration is restored. Separately, the replay timeline squashing is a UI layout issue in `.testbed/scripts/proving_harness.gd`: the `HSlider` is placed inside a `CenterContainer`, and a headless layout probe showed the row has width available while the slider itself collapses to an 8-pixel width. That matches the screenshot and points to the centering container as the immediate cause of the broken seekbar layout.

---

### Task 2: Independently audit the findings

**Bead ID:** `aerobeat-input-camera-tracking-lau`  
**SubAgent:** `primary`  
**Role:** `auditor`  
**References:** `REF-01`, `REF-02`, `REF-03`, `REF-04`  
**Prompt:** In `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking`, independently verify the forensic findings for the Boxing `.testbed` live/replay/timeline regressions. Re-check the reported root causes against the current repo state and any available validation/log evidence. Do not modify the repo. Close the bead with an honest reason when done.

**Folders Created/Deleted/Modified:**
- none expected

**Files Created/Deleted/Modified:**
- none expected

**Status:** ⏳ Pending

**Results:** Pending.

---

## Final Results

**Status:** ⏳ Pending

**What We Built:** Pending audit.

**Reference Check:** Pending.

**Commits:**
- None; audit-only.

**Lessons Learned:** Pending.

---

*Drafted on 2026-06-02*
