# AeroBeat Remove Stale Proving Debug Controls

**Date:** 2026-06-03  
**Status:** Complete  
**Last Updated:** 2026-06-03 13:50 EDT  
**Blocked Reason:** None  
**Agent:** `cookie`

---

## Goal

Remove the old debug variables/controls shown in Derrick's screenshot from the Boxing and Flow proving harness UI.

---

## Overview

The proving harness has accumulated a set of temporary debug toggles that were useful during shutdown/trail debugging but are no longer needed. Derrick specifically wants the stale controls visible in the screenshot removed from the Boxing and Flow proving harness scenes.

This should stay a tight cleanup slice in `aerobeat-input-camera-tracking`: identify the exported variables and UI wiring behind those controls, remove them from the harness cleanly, keep any real non-debug functionality intact, and run the relevant repo-local validation so we don't regress the testbed.

---

## REFERENCES

| ID | Description | Path |
| --- | --- | --- |
| `REF-01` | User screenshot of stale proving-harness debug controls | `/home/derrick/.openclaw/workspace/.temp/nerve-uploads/2026/06/03/image-901ebf02.png` |
| `REF-02` | Hand-trail / presenter cleanup context | `/home/derrick/.openclaw/workspace/projects/openclaw-cookie/.plans/aerobeat-architecture/2026-06-03-hand-trail-vertical-alignment-audit.md` |

---

## Tasks

### Task 1: Remove stale proving-harness debug controls

**Bead ID:** `aerobeat-input-camera-tracking-9hd`  
**SubAgent:** `primary`  
**Role:** `coder`  
**References:** `REF-01`, `REF-02`  
**Prompt:** Remove the stale debug variables/controls shown in the screenshot from the Boxing and Flow proving harness in `aerobeat-input-camera-tracking`. Claim the bead on start. Keep scope narrow: remove only the obsolete debug toggles/exports/UI wiring, preserve real harness functionality, run relevant repo-local validation, commit and push by default unless blocked, and report files changed, validations, commit(s), and short manual QA notes for Derrick.

**Folders Created/Deleted/Modified:**
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking`

**Files Created/Deleted/Modified:**
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.testbed/scripts/proving_harness.gd`

**Status:** ✅ Complete

**Results:** Removed the stale proving-harness debug exports and their dead debug-only branches from `.testbed/scripts/proving_harness.gd`. Specifically removed obsolete controls for trail logging, steady-state/shutdown console debug, and the old sidecar-close skip toggles. Left unrelated local scene edits in `boxing_proving.tscn` and `flow_proving.tscn` untouched on purpose. Repo-local test suite passed `83/83`, and commit `074c3e5` (`Remove stale proving harness debug controls`) was pushed to `origin/main`. 

---

## Final Results

**Status:** ✅ Complete

**What We Built:** Removed the stale proving-harness debug controls from the Boxing and Flow harness root export surface, along with their obsolete debug-only code paths.

**Reference Check:** `REF-01` and `REF-02` were used. Cleanup stayed narrowly focused on obsolete debug controls and preserved real harness behavior.

**Commits:**
- `074c3e5` - Remove stale proving harness debug controls

**Lessons Learned:** Temporary debug exports linger easily in proving harnesses after firefights. Keeping cleanup as a tight follow-up slice worked well and avoided touching unrelated scene-local edits.
