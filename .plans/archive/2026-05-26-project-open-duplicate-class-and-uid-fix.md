# AeroBeat Input Camera Tracking — Project Open Duplicate Class and UID Fix

**Date:** 2026-05-26  
**Status:** Stale  
**Last Updated:** 2026-05-26 11:50 EDT  
**Blocked Reason:** None  
**Agent:** `cookie`

---

## Goal

Fix the project-opening/import-time collision issues in `aerobeat-input-camera-tracking` so the Boxing testing scene and related project surfaces can open cleanly without duplicate class/UID conflicts between mounted addon copies.

---

## Overview

The current failure appears during Godot project import/open, before meaningful scene execution. The screenshot shows duplicate UID warnings and then parse failures caused by global class collisions between `res://addons/aerobeat-input-mediapipe-python/...` and `res://addons/aerobeat-input-camera-tracking/src/...`. The immediate risk is not runtime gesture logic yet; it is addon boundary/import hygiene.

This needs to be treated as an ownership/boundary problem first. The likely seam is that `aerobeat-input-camera-tracking` still exposes source files or `class_name` surfaces that collide with the mounted `aerobeat-input-mediapipe-python` addon copy. The right next move is to inspect the source repo, mounted addon state, and class-name collision surface before changing code. Generated `/addons/` copies remain non-owning consumer state; durable fixes belong in the owning source repo(s) plus canonical addon refresh flow.

---

## REFERENCES

| ID | Description | Path |
| --- | --- | --- |
| `REF-01` | Current issue evidence from Godot import/open phase | user-provided screenshot + console text in current chat |
| `REF-02` | Godot skill duplicate-class scanner guidance | `/home/derrick/.openclaw/workspace/skills/godot/SKILL.md` |
| `REF-03` | Current repo/source root | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking` |

---

## Tasks

### Task 1: Audit duplicate-class and duplicate-UID collision surface

**Bead ID:** `Pending`  
**SubAgent:** `primary`  
**Role:** `research`  
**References:** `REF-01`, `REF-02`, `REF-03`  
**Prompt:** Inspect the current `aerobeat-input-camera-tracking` repo and mounted addon/runtime surfaces. Run the Godot class-name collision scanner and identify the exact owning-source vs mounted-addon overlap that explains the project-open parse failures and duplicate UID warnings. Do not implement fixes yet.

**Folders Created/Deleted/Modified:**
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.plans/`

**Files Created/Deleted/Modified:**
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.plans/2026-05-26-project-open-duplicate-class-and-uid-fix.md`

**Status:** ⏳ Pending

**Results:** Pending.

---

## Final Results

**Status:** ⏳ Draft

**What We Built:** Pending.

**Reference Check:** Pending.

**Commits:**
- Pending.

**Lessons Learned:** Pending.
