# AeroBeat Input MediaPipe Python

**Date:** 2026-05-21  
**Status:** In Progress  
**Agent:** Cookie 🍪

---

## Goal

Trace the current camera-switch GUI crash regression in the MediaPipe Python proving flow, identify the most likely culprit in the recent commit window, and determine whether the active `.testbed` / godotenv-installed runtime is stale relative to the owner repo.

---

## Overview

Derrick confirmed that camera switching is still reproducibly crashing the Zorin OS GUI session on the main terminal even after the recent hardening pass. The last known repair (`375491c`) serialized the restart lifecycle and cleaned up proving-harness state, but the regression remains in live human testing. That means we need a truth pass over the recent commit stack rather than assuming the newest fix is sufficient.

The investigation scope is the recent change window from `6e3b7f7` through `375491c`, which includes camera selection, live camera picker, camera-device typing, live source handling, overlay propagation, and the restart hardening pass. We also need to explicitly check whether the `.testbed` runtime that Godot is using is current with the owner repo or whether a stale installed addon/runtime path is masking or reintroducing the bug.

No implementation work should begin until the suspect path is narrowed. The output of this pass should be a ranked culprit list, evidence for whether the issue lives in the Godot-side restart/switch orchestration vs the Python sidecar/runtime sync path, and a concrete recommended repair target.

---

## REFERENCES

| ID | Description | Path |
| --- | --- | --- |
| `REF-01` | Owner-repo restart lifecycle implementation | `src/autostart_manager.gd` |
| `REF-02` | Proving harness camera-switch/UI lifecycle | `.testbed/scripts/proving_harness.gd` |
| `REF-03` | Recent suspect commit window | `git log: 6e3b7f7..375491c` |
| `REF-04` | Testbed proving scene using the active runtime | `.testbed/scenes/boxing_proving.tscn` |
| `REF-05` | Python sidecar entry/config touched in suspect window | `python_mediapipe/main.py`, `python_mediapipe/args.py` |

Use these IDs in the task notes and final results so the investigation stays anchored to the actual code paths and commit window.

---

## Tasks

### Task 1: Commit-window regression analysis

**Bead ID:** `aerobeat-input-mediapipe-python-0eb`  
**SubAgent:** `primary` (for `research` workflow role)  
**Role:** `research`  
**References:** `REF-01`, `REF-02`, `REF-03`, `REF-05`  
**Prompt:** Review commits from `6e3b7f7` through `375491c` in `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-mediapipe-python`. Claim the assigned bead on start with `bd update <id> --status in_progress --json`. Produce a ranked analysis of which changes are most likely to explain the still-reproducible GUI crash during live camera switching, with special attention to restart ordering, device enumeration/selection, preview/overlay behavior, and any Godot ↔ sidecar interactions. Do not implement fixes. Close the bead only if the requested investigation output is complete, with `bd close <id> --reason "Commit-window regression analysis complete" --json`.

**Folders Created/Deleted/Modified:**
- `.plans/mediapipe-python/`

**Files Created/Deleted/Modified:**
- `.plans/mediapipe-python/2026-05-21-camera-switch-regression-trace.md`

**Status:** ✅ Complete

**Results:** Research pass completed. Ranked likely culprits put `7d4653d` (live camera picker / proving-scene switch path) first, `375491c` (restart hardening pass) second, and `2332514` (live source handling / enumeration) third. The strongest evidence points to Godot-side async teardown/rebuild orchestration in the proving harness + autostart lifecycle rather than overlay logic or a primarily Python-side pose-processing failure.

---

### Task 2: Testbed/runtime sync truth pass

**Bead ID:** `aerobeat-input-mediapipe-python-54z`  
**SubAgent:** `primary` (for `research` workflow role)  
**Role:** `research`  
**References:** `REF-01`, `REF-02`, `REF-04`, `REF-05`  
**Prompt:** In `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-mediapipe-python`, verify whether the runtime used by `.testbed` is stale relative to the owner repo. Claim the assigned bead on start with `bd update <id> --status in_progress --json`. Compare the active testbed/addon/runtime path and any godotenv-installed copies against the owner-repo sources, especially for camera switching, restart flow, and Python sidecar entry/config. Report exactly which code path the proving scene is executing and whether stale installed content could explain the regression. Do not implement fixes. Close the bead only if the requested sync-truth output is complete, with `bd close <id> --reason "Testbed/runtime sync truth pass complete" --json`.

**Folders Created/Deleted/Modified:**
- `.plans/mediapipe-python/`

**Files Created/Deleted/Modified:**
- `.plans/mediapipe-python/2026-05-21-camera-switch-regression-trace.md`

**Status:** ✅ Complete

**Results:** Runtime-truth pass completed. `.testbed/addons/aerobeat-input-mediapipe-python` is a symlink to the owner repo root, so the proving scene is using live owner-repo GDScript and Python entrypoint content rather than a stale copied addon snapshot. The sidecar entrypoint resolves to the same owner-repo `python_mediapipe/main.py`, and no divergent self-addon copy was found. Conclusion: stale `.testbed` / godotenv-installed content is not the likely explanation for the current regression.

---

### Task 3: Synthesis and recommended repair target

**Bead ID:** `aerobeat-input-mediapipe-python-8dw`  
**SubAgent:** `primary` (for `auditor` workflow role)  
**Role:** `auditor`  
**References:** `REF-01`, `REF-02`, `REF-03`, `REF-04`, `REF-05`  
**Prompt:** After Tasks 1 and 2 are complete, claim the assigned bead with `bd update <id> --status in_progress --json`. Independently review their findings in `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-mediapipe-python` and determine the most defensible next repair target: owner-repo Godot restart/switch logic, stale `.testbed` runtime sync, Python sidecar behavior, or another path. Call out unsupported claims, missing evidence, and the minimum next change to try. Do not implement fixes. Close the bead when the recommendation and audit are complete using `bd close <id> --reason "Regression synthesis and repair recommendation complete" --json`.

**Folders Created/Deleted/Modified:**
- `.plans/mediapipe-python/`

**Files Created/Deleted/Modified:**
- `.plans/mediapipe-python/2026-05-21-camera-switch-regression-trace.md`

**Status:** ✅ Complete

**Results:** Independent audit confirmed the proving scene is running live owner-repo code through the symlinked addon mount rather than a stale copied runtime snapshot. The most defensible repair target is the owner-repo Godot-side camera-switch choreography centered on `.testbed/scripts/proving_harness.gd` and `src/autostart_manager.gd`, especially the split ownership where the harness partially tears down runtime state before/around `restart_server()`. Recommended minimum next change: centralize the switch lifecycle under one serial owner instead of letting both the harness and autostart manager coordinate overlapping teardown/startup responsibilities.

---

## Final Results

**Status:** ✅ Complete

**What We Built:** Completed an investigation pass for the live camera-switch GUI crash regression. The work produced: (1) a ranked suspect commit window analysis, (2) a runtime-truth check proving `.testbed` is executing live owner-repo code rather than a stale copied addon snapshot, and (3) an audited recommendation for the next repair target.

**Reference Check:** `REF-01` and `REF-02` were validated as the primary restart/switch implementation surface. `REF-03` was narrowed to `7d4653d` as the initial live-switch introduction, `375491c` as a partial hardening pass, and `2332514` as a secondary source-handling contributor rather than the primary crash surface. `REF-04` and `REF-05` were checked to verify the proving scene/runtime path and sidecar entrypoint are live owner-repo content.

**Commits:**
- None yet.

**Lessons Learned:** The stale-runtime theory does not hold up under repo/runtime-path inspection here. The next repair should target single-owner serialized camera-switch lifecycle management on the Godot side rather than spending another pass on GodotEnv sync or Python-side live camera logic.

---

*Last updated on 2026-05-21*
