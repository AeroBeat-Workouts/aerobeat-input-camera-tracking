# AeroBeat Input MediaPipe Python Boxing Proving Harness Video Failure

**Date:** 2026-05-18  
**Status:** Draft  
**Agent:** Pico 🐱‍🏍

---

## Goal

Diagnose and fix the Boxing proving-harness failure when launched against its prerecorded test video source.

---

## Overview

This looks related to the Flow fixture issue, but the first quick inspection says the Boxing proving scene is already serialized to a real-looking `.mp4` fixture path under `.testbed/assets/fixtures/boxing/punch_left/`. So unlike the Flow scene, this may not be a stale path typo.

That means the next pass should verify whether the Boxing scene’s default prerecorded source actually exists and opens on this host, then trace the Godot-to-sidecar handoff and reproduce the failure. Only after that should we decide whether the fix belongs in the scene data, fixture asset layout, AutoStart preflight, or the sidecar logic for Boxing-specific playback.

---

## REFERENCES

| ID | Description | Path |
| --- | --- | --- |
| `REF-01` | Boxing proving scene serialized source | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-mediapipe-python/.testbed/scenes/boxing_proving.tscn` |
| `REF-02` | Shared proving harness source override and startup path | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-mediapipe-python/.testbed/scripts/proving_harness.gd` |
| `REF-03` | AutoStart prerecorded source validation and launch path | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-mediapipe-python/src/autostart_manager.gd` |
| `REF-04` | Boxing fixture asset tree | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-mediapipe-python/.testbed/assets/fixtures/boxing/` |

---

## Tasks

### Task 1: Diagnose the Boxing prerecorded source failure

**Bead ID:** `aerobeat-input-mediapipe-python-spi`  
**SubAgent:** `primary` (for `research`)  
**Role:** `research`  
**References:** `REF-01`, `REF-02`, `REF-03`, `REF-04`  
**Prompt:** Claim the assigned bead on start. Reproduce or inspect the Boxing proving-scene prerecorded-source failure on this host. Verify whether the serialized source path exists, whether OpenCV can open it directly, and whether the failure belongs to scene data, source handoff, preflight validation, fixture layout, or sidecar logic. Ground the diagnosis in direct repo inspection and host-level reproduction. Do not implement the fix yet.

**Folders Created/Deleted/Modified:**
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-mediapipe-python/.testbed/`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-mediapipe-python/python_mediapipe/`

**Files Created/Deleted/Modified:**
- `.testbed/scenes/boxing_proving.tscn` (owner of the stale serialized Boxing source value)

**Status:** ✅ Complete

**Results:** Verified that `.testbed/scenes/boxing_proving.tscn` serializes a nonexistent prerecorded source (`res://assets/fixtures/boxing/punch_left/boxing__punch_left__positive__guard_start_end__take_01.mp4`). The real existing Boxing fixture on this host is `res://assets/fixtures/boxing/punch_left/boxing_punch_left_x4_while_guarding_take_01.mp4` with sibling YAML `boxing_punch_left_x4_while_guarding_take_01.yaml`. OpenCV confirms the stale path does not open and the real `.mp4` does. Godot now fails early in `AutoStartManager` with the truthful missing-file preflight message, which means handoff, preflight, and sidecar logic are behaving correctly; the remaining bug is stale Boxing scene data. Recommended fix: update `boxing_proving.tscn` to the real existing fixture path and re-run the default Boxing harness flow. References validated: `REF-01`, `REF-03`, `REF-04`.

---

### Task 2: Implement the smallest robust Boxing fix

**Bead ID:** `aerobeat-input-mediapipe-python-eg4`  
**SubAgent:** `primary` (for `coder`)  
**Role:** `coder`  
**References:** `REF-01`, `REF-02`, `REF-03`, `REF-04`  
**Prompt:** Claim the assigned bead on start. Implement the smallest robust fix for the diagnosed Boxing prerecorded-source failure, keeping scope tight. Validate against the real Boxing proving harness or direct sidecar reproduction on this host. Commit and push by default unless blocked.

**Folders Created/Deleted/Modified:**
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-mediapipe-python/.testbed/`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-mediapipe-python/python_mediapipe/`

**Files Created/Deleted/Modified:**
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-mediapipe-python/.testbed/scenes/boxing_proving.tscn`

**Status:** ✅ Complete

**Results:** Updated the stale serialized Boxing prerecorded source in `.testbed/scenes/boxing_proving.tscn` from the nonexistent `boxing__punch_left__positive__guard_start_end__take_01.mp4` path to the real existing `boxing_punch_left_x4_while_guarding_take_01.mp4` fixture. Validation passed via Godot scene/script parse check, testbed import smoke, and a Boxing scene launch probe that instantiated `boxing_proving.tscn` with its saved/default properties and observed `Initializing`, `Python server started`, and `Boxing harness live` using the corrected source with no stale-path or missing-file errors. Commit landed as `0b79600` (`Fix boxing proving scene fixture path`). References validated: `REF-01`, `REF-04`.

---

### Task 3: Audit Boxing proving-harness playback end-to-end

**Bead ID:** `aerobeat-input-mediapipe-python-rkl`  
**SubAgent:** `primary` (for `auditor`)  
**Role:** `auditor`  
**References:** `REF-01`, `REF-02`, `REF-03`, `REF-04`  
**Prompt:** Claim the assigned bead on start. Independently verify the fix using the real Boxing proving harness flow on this host. Confirm the prerecorded source opens successfully, the sidecar stays up, and the original user-facing failure is gone. Close only if the actual behavior is fixed.

**Folders Created/Deleted/Modified:**
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-mediapipe-python/.testbed/`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-mediapipe-python/python_mediapipe/`

**Files Created/Deleted/Modified:**
- none expected beyond runtime/test artifacts

**Status:** ⏳ Pending

**Results:** Pending.

---

## Final Results

**Status:** ⏳ Pending

**What We Built:** Pending.

**Reference Check:** Pending.

**Commits:**
- Pending.

**Lessons Learned:** Pending.

---

*Completed on Pending*
