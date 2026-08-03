# AeroBeat Input Camera Tracking — Boxing Live/Replay Repair

**Date:** 2026-06-02  
**Status:** Stale
**Last Updated:** 2026-06-02 12:49 EDT  
**Blocked Reason:** None  

**Stale Archive Note:** Marked stale and archived on 2026-08-03 during Byte workspace cleanup; newer AeroBeat work remains with Pico.
**Agent:** Cookie 🍪

---

## Goal

Restore Boxing `.testbed` live webcam startup and video replay startup through the correct lower-level camera-tracking ownership boundary, fix the local replay seekbar layout regression, and verify the repaired flow end to end.

---

## Overview

The completed audit established two categories of failure. First, both live webcam and replay startup are failing before meaningful runtime work begins because `aerobeat-input-camera-tracking` still requests the default camera-tracking backend while the lower-level camera-tracking stack no longer has the expected backend registration seam in place. Per Derrick’s boundary rule, that repair must happen in the true owner repo(s) — most likely `aerobeat-tool-camera-tracking`, and possibly `aerobeat-vendor-mediapipe-python` if the registration seam now belongs there.

Second, the replay seekbar squash is a local `.testbed` UI regression inside `aerobeat-input-camera-tracking`. That repair belongs here because it is proving-harness layout code, not shared camera-tracking ownership.

Testing must respect the Zorin/MediaPipe shutdown constraint: subagents should not kill the test project/process directly. For any headless test path that needs an orderly in-engine shutdown, use the `aerobeat-tool-headless-manager` singleton / sentinel workflow rather than ad-hoc process termination.

---

## REFERENCES

| ID | Description | Path |
| --- | --- | --- |
| `REF-01` | Forensic audit of current Boxing live/replay/timeline regressions | `/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.plans/2026-06-02-boxing-testbed-live-replay-timeline-audit.md` |
| `REF-02` | Input consumer repo under repair | `/workspace/projects/aerobeat/aerobeat-input-camera-tracking` |
| `REF-03` | Likely lower-level camera-tracking owner repo | `/workspace/projects/aerobeat/aerobeat-tool-camera-tracking` |
| `REF-04` | Likely vendor/runtime owner repo | `/workspace/projects/aerobeat/aerobeat-vendor-mediapipe-python` |
| `REF-05` | Headless manager repo / singleton for orderly shutdown | `/workspace/projects/aerobeat/aerobeat-tool-headless-manager` |
| `REF-06` | User-provided screenshot showing squashed replay seekbar | `/home/derrick/.openclaw/workspace/.temp/nerve-uploads/2026/06/02/image-7549d988.png` |

---

## Tasks

### Task 1: Repair lower-level backend registration / startup ownership in the correct repo(s)

**Bead ID:** `aerobeat-input-camera-tracking-tck`  
**SubAgent:** `primary`  
**Role:** `coder`  
**References:** `REF-01`, `REF-03`, `REF-04`, `REF-05`  
**Prompt:** Determine and implement the correct lower-level fix for the Boxing live/replay startup regression. Start from the findings in REF-01: `aerobeat-input-camera-tracking` still requests the default camera-tracking backend, but lower-level startup now fails with `backend_unregistered` for `mediapipe_python`. Repair that in the true owner repo(s) — likely `aerobeat-tool-camera-tracking`, and only involve `aerobeat-vendor-mediapipe-python` if the registration seam belongs there. Do not patch `aerobeat-input-camera-tracking/src/` just to paper over lower-level ownership. After the lower-level fix lands, refresh the consumer with the canonical `godotenv-sync` workflow. For any headless validation shutdown, use `aerobeat-tool-headless-manager` / the in-engine orderly quit path instead of killing the process. Run relevant validation, commit/push in touched owner repo(s), and close the bead honestly.

**Folders Created/Deleted/Modified:**
- `/workspace/projects/aerobeat/aerobeat-tool-camera-tracking/`
- consumer refresh use of `/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.testbed/`

**Files Created/Deleted/Modified:**
- `/workspace/projects/aerobeat/aerobeat-tool-camera-tracking/src/CameraTracking.gd`
- `/workspace/projects/aerobeat/aerobeat-tool-camera-tracking/.testbed/tests/test_CameraTracking.gd`
- `/workspace/projects/aerobeat/aerobeat-tool-camera-tracking/README.md`

**Status:** ✅ Complete

**Results:** The lower-level startup repair landed in the correct owner repo: `aerobeat-tool-camera-tracking`. No patch was made to `aerobeat-input-camera-tracking/src/`, and no vendor-repo changes were needed. The coder added a lazy auto-registration seam in `CameraTracking.gd` so that when the default backend alias resolves to `mediapipe_python` and no factory is registered yet, the mounted vendor backend can self-register at the tool boundary. This restores truthful startup for contract-only consumers without moving vendor bootstrap logic back into the input consumer repo. The tool repo validation passed `16/16`, the consumer `.testbed` was refreshed via `/home/derrick/.openclaw/workspace/scripts/godotenv-sync --repo .testbed`, and targeted `aerobeat-input-camera-tracking` unit validation passed `70/70`. The lower-level fix was committed and pushed in `aerobeat-tool-camera-tracking` as `ce3aad0` (`Auto-register default mediapipe backend`).

---

### Task 2: Repair local Boxing replay seekbar layout in the proving harness

**Bead ID:** `aerobeat-input-camera-tracking-tu9`  
**SubAgent:** `primary`  
**Role:** `coder`  
**References:** `REF-01`, `REF-02`, `REF-06`  
**Prompt:** In `aerobeat-input-camera-tracking`, repair the local `.testbed` Boxing replay seekbar layout regression identified in REF-01/REF-06. Keep the fix local to the proving harness UI and preserve the desired vertical alignment without collapsing the slider width. Validate the corrected layout in the highest-fidelity safe way available, commit/push by default, and close the bead honestly.

**Folders Created/Deleted/Modified:**
- `/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.testbed/`

**Files Created/Deleted/Modified:**
- `/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.testbed/scripts/proving_harness.gd`
- `/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.testbed/tests/unit/test_proving_harness_trails.gd`

**Status:** ✅ Complete

**Results:** The local proving-harness coder pass is complete. It repaired the replay seekbar layout by replacing the width-collapsing `CenterContainer` wrapper with an expanding `Control`, then anchoring the `HSlider` to fill that host so the slider keeps usable width while staying vertically aligned with the play button and time label. It also added a focused headless regression test for slider width and vertical alignment. Validation passed: targeted `test_proving_harness_trails.gd` ran `28/28` passing, and the full repo-local `.testbed` headless suite ran `71/71` passing. The local UI fix was committed and pushed as `a27b46b` (`Fix proving harness replay seekbar layout`).

---

### Task 3: QA end-to-end Boxing live webcam + replay + seekbar behavior after repairs

**Bead ID:** `aerobeat-input-camera-tracking-12e`  
**SubAgent:** `primary`  
**Role:** `qa`  
**References:** `REF-01`, `REF-02`, `REF-03`, `REF-04`, `REF-05`, `REF-06`  
**Prompt:** After repair tasks complete and dependencies are refreshed, verify the Boxing `.testbed` flow end to end. Confirm live webcam starts, confirm video replay starts, confirm the replay seekbar no longer squashes, and record exact validation behavior/results. Use orderly shutdown via `aerobeat-tool-headless-manager` / in-engine quit flow for any headless run that needs teardown; do not kill the process. Close the bead honestly.

**Folders Created/Deleted/Modified:**
- validation-only use of relevant `.testbed` project(s)

**Files Created/Deleted/Modified:**
- none expected

**Status:** ✅ Complete

**Results:** QA passed the main bead scope after refreshing the consumer with `/home/derrick/.openclaw/workspace/scripts/godotenv-sync --repo /home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking`. It confirmed both repair beads were closed, reviewed commits `ce3aad0` in `aerobeat-tool-camera-tracking` and `a27b46b` in `aerobeat-input-camera-tracking`, and verified that the refreshed `.testbed` addon path points at the repaired tool repo state. End-to-end results: live webcam startup passed, replay startup passed, and the replay seekbar no longer squashes. Captured live state showed `started: true`, `tracking_state.state: running`, `backend/source/preview/tracking_ready: true`, and a live camera texture present. Captured replay state showed `started: true`, `tracking_state.state: running`, `tracking_frame.source_kind: video_file`, `playback_state.media_loaded: true`, `playback_state.state: playing`, and a displayed replay texture. Seekbar measurements showed width `338.0` with vertical alignment matching the toggle and time label, and the focused regression test `test_proving_harness_trails.gd` passed `28/28`. Important caveat recorded for follow-up outside this bead: although orderly in-engine shutdown was used, post-success headless teardown still showed MediaPipe/EGL cleanup instability (`SIGABRT` / allocator corruption messages) after output was written and shutdown summary logged.

---

### Task 4: Audit final ownership boundaries and repaired behavior

**Bead ID:** `aerobeat-input-camera-tracking-cq3`  
**SubAgent:** `primary`  
**Role:** `auditor`  
**References:** `REF-01`, `REF-02`, `REF-03`, `REF-04`, `REF-05`, `REF-06`  
**Prompt:** Independently audit the final repair. Confirm the startup fix landed in the correct lower-level owner repo(s), not as an ownership-violating paper-over in `aerobeat-input-camera-tracking/src/`. Confirm the local seekbar fix stays local to the proving harness UI. Confirm the consumer refresh path used `godotenv-sync`, and confirm validation results for live webcam, replay startup, and seekbar layout. Close the bead honestly if it passes, or report the exact ownership/behavior gap if it fails.

**Folders Created/Deleted/Modified:**
- none expected

**Files Created/Deleted/Modified:**
- none expected

**Status:** ✅ Complete

**Results:** Independent audit passed and bead `aerobeat-input-camera-tracking-cq3` was closed. It confirmed the startup ownership fix landed in `aerobeat-tool-camera-tracking` commit `ce3aad0` without any paper-over changes under `aerobeat-input-camera-tracking/src/`, confirmed the seekbar fix stayed local to `.testbed/scripts/proving_harness.gd` and `.testbed/tests/unit/test_proving_harness_trails.gd` in commit `a27b46b`, confirmed the consumer refresh path used `/home/derrick/.openclaw/workspace/scripts/godotenv-sync`, and independently reran targeted validations showing tool repo `test_CameraTracking.gd` passing `14/14` and input repo `test_proving_harness_trails.gd` passing `28/28`. The auditor agreed with QA that the post-success MediaPipe/EGL teardown instability is real but should remain a separate follow-up rather than blocking this scoped repair bead.

---

## Final Results

**Status:** ✅ Complete

**What We Built:** Restored Boxing `.testbed` live webcam startup and video replay startup by repairing the missing backend-registration seam in the lower-level owner repo `aerobeat-tool-camera-tracking`, refreshed the consumer via `godotenv-sync`, and repaired the local proving-harness replay seekbar layout in `aerobeat-input-camera-tracking`.

**Reference Check:** `REF-01` through `REF-06` were satisfied. Ownership boundaries were preserved: startup/backend repair landed in `aerobeat-tool-camera-tracking`, no startup paper-over was added to `aerobeat-input-camera-tracking/src/`, and the seekbar layout fix stayed local to the `.testbed` UI.

**Commits:**
- `ce3aad0` - Auto-register default mediapipe backend
- `a27b46b` - Fix proving harness replay seekbar layout

**Lessons Learned:** The contract-only consumer refactor was directionally correct, but the default-backend registration seam still needed to live at the lower-level tool boundary for truthful startup. Separately, proving-harness alignment tweaks should avoid centering containers around width-sensitive controls like sliders. Headless orderly shutdown improved correctness, but MediaPipe/EGL teardown instability remains a separate follow-up concern after successful runs.

---

*Drafted on 2026-06-02*
