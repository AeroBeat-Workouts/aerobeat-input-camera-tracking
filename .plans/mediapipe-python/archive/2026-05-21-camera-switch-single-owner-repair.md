# AeroBeat Input MediaPipe Python

**Date:** 2026-05-21  
**Status:** In Progress  
**Agent:** Cookie 🍪

---

## Goal

Refactor the live camera-switch path so one Godot-side owner fully serializes the switch lifecycle, reducing the GUI-crash risk caused by overlapping teardown/startup responsibilities.

---

## Overview

The completed investigation isolated the most likely fault surface to the proving-harness / autostart-manager camera-switch choreography. The proving flow is not running a stale copied addon snapshot; it is executing the live owner repo. Python is also not doing in-process hot camera switching. Instead, the actual switch behavior is implemented by restarting the sidecar with a new `--camera` argument while the proving harness independently tears down and rebuilds local provider/preview state.

That split ownership is the repair target. This pass should move camera switching toward a single-owner serialized lifecycle so the harness stops doing overlapping partial teardown around `restart_server()`. Derrick will handle manual QA because the failure mode can crash the Zorin OS GUI session on the main terminal. So this execution loop is intentionally **coder → auditor**, with human QA outside the agent loop.

---

## REFERENCES

| ID | Description | Path |
| --- | --- | --- |
| `REF-01` | Investigation summary: suspect Godot-side restart/switch logic | `.plans/mediapipe-python/2026-05-21-camera-switch-regression-trace.md` |
| `REF-02` | Current proving harness switch lifecycle | `.testbed/scripts/proving_harness.gd` |
| `REF-03` | Current autostart manager restart lifecycle | `src/autostart_manager.gd` |
| `REF-04` | Proving scene entry using the live addon mount | `.testbed/scenes/boxing_proving.tscn` |
| `REF-05` | Human instruction to skip agent QA and rely on manual terminal QA | chat instruction on 2026-05-21 |

---

## Tasks

### Task 1: Implement single-owner camera-switch lifecycle

**Bead ID:** `aerobeat-input-mediapipe-python-xt5`  
**SubAgent:** `primary` (for `coder` workflow role)  
**Role:** `coder`  
**References:** `REF-01`, `REF-02`, `REF-03`, `REF-04`, `REF-05`  
**Prompt:** Implement the smallest good repair for the live camera-switch GUI crash regression in `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-mediapipe-python`. Claim the assigned bead on start with `bd update <id> --status in_progress --json`. The repair target is the Godot-side switch choreography: make one owner serialize the camera-switch lifecycle so the proving harness stops doing overlapping partial teardown before/around `AutoStartManager.restart_server()`. Preserve feature behavior as much as possible. Run relevant repo-local validation you can perform safely without depending on risky live GUI camera-switch QA. Commit and push your changes to `main` by default unless blocked. When complete, close the bead with `bd close <id> --reason "Implemented single-owner camera-switch lifecycle repair" --json` and report exact files changed, validation performed, and commit hash.

**Folders Created/Deleted/Modified:**
- `.plans/mediapipe-python/`
- `.testbed/scripts/`
- `src/`

**Files Created/Deleted/Modified:**
- `.plans/mediapipe-python/2026-05-21-camera-switch-single-owner-repair.md`
- `.testbed/scripts/proving_harness.gd`
- `src/autostart_manager.gd`

**Status:** ✅ Complete

**Results:** Implemented the small Godot-side repair to remove overlapping pre-restart teardown from the proving harness. The harness now marks switch cleanup as pending and performs teardown on `server_stopped`, while `AutoStartManager` also waits out in-flight startup before stop/restart proceeds. Validation was limited to safe headless parse checks. Commit pushed: `ca0b7af` — `Serialize Godot camera switch lifecycle`.

---

### Task 2: Audit implementation against the repair target

**Bead ID:** `aerobeat-input-mediapipe-python-4ob`  
**SubAgent:** `primary` (for `auditor` workflow role)  
**Role:** `auditor`  
**References:** `REF-01`, `REF-02`, `REF-03`, `REF-05`  
**Prompt:** Audit the completed implementation bead in `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-mediapipe-python`. Claim the assigned bead with `bd update <id> --status in_progress --json`. Verify the change really centralizes or materially improves switch ownership/serialization on the Godot side, and confirm the coder did not quietly rely on stale-runtime or Python-side assumptions. Review the diff, the modified lifecycle, and the validation evidence. Derrick is explicitly handling manual crash QA, so do not fail the bead solely because full live terminal camera-switch testing was not performed by the agent. Close the bead if the implementation truthfully matches the repair goal using `bd close <id> --reason "Audited single-owner camera-switch lifecycle repair" --json`; otherwise report the gaps clearly.

**Folders Created/Deleted/Modified:**
- `.plans/mediapipe-python/`
- `.testbed/scripts/`
- `src/`

**Files Created/Deleted/Modified:**
- `.plans/mediapipe-python/2026-05-21-camera-switch-single-owner-repair.md`
- `.testbed/scripts/proving_harness.gd`
- `src/autostart_manager.gd`

**Status:** ✅ Complete

**Results:** Audit passed. Commit `ca0b7af` is tightly scoped to the Godot-side harness/autostart overlap and materially improves lifecycle ownership by moving harness cleanup behind confirmed `server_stopped` while strengthening `AutoStartManager` start/stop mutual exclusion. No Python-side theory drift or stale-runtime drift was introduced. Main caveat for manual QA: watch the normal switch path for repeated rapid camera changes, duplicate stop/start behavior, stale preview/provider state, and any edge case where cleanup pending depends on `server_stopped` being emitted.

---

## Final Results

**Status:** ✅ Complete

**What We Built:** Implemented and audited a scoped Godot-side repair for the live camera-switch crash regression by moving overlapping harness teardown out of the pre-restart path and tightening serialized start/stop ownership around `AutoStartManager`.

**Reference Check:** `REF-01` through `REF-04` were satisfied by the implementation focus on the proven harness/autostart lifecycle surface. `REF-05` was honored by explicitly skipping agent-run live crash QA and leaving final behavioral verification to Derrick’s manual terminal testing.

**Commits:**
- `ca0b7af` - Serialize Godot camera switch lifecycle

**Lessons Learned:** The right near-term fix was lifecycle ownership cleanup, not more runtime-sync chasing. Manual crash QA remains the truth source for whether this serialization pass fully removes the GUI crash on real camera switches.

---

*Last updated on 2026-05-21*
