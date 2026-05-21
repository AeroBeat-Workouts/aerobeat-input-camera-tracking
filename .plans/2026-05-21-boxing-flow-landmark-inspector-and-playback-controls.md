# AeroBeat MediaPipe Python — Boxing / Flow Landmark Inspector and Playback Controls

**Date:** 2026-05-21  
**Status:** In Progress  
**Agent:** Byte 🐈‍⬛

---

## Goal

Add a shared click-based info panel system plus prerecorded-video playback controls to the MediaPipe Python Boxing and Flow proving scenes.

---

## Overview

Derrick wants the proving scenes to become a stronger visual debugging surface rather than a one-off gesture popup. The new shared info panel system should support both existing gesture colliders and new MediaPipe landmark colliders. Clicking a gesture target or landmark target should open one fixed-position panel at a time, with swap-mode behavior, click-away dismissal, and an explicit `X` close button. Landmark cards should surface landmark identity, position, tracking confidence, and stable debugging values that can later expand into richer motion/relationship diagnostics.

The same implementation slice should add prerecorded-video playback controls to both proving scenes. The controls should only appear when the scene is running against a prerecorded file, not a live camera source. Playback must support play, pause, and seek. Seeking is intentionally lossy for gesture-debugging purposes: it should reset gesture/history buffers, jump to the requested point, and leave playback paused until the user presses play again.

Derrick will manually test this on Cookie’s terminal after implementation, so this plan treats repo-local validation as required but defers final manual QA truth-pass to Derrick.

---

## REFERENCES

| ID | Description | Path |
| --- | --- | --- |
| `REF-01` | Boxing proving scene owner | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-mediapipe-python/.testbed/scenes/boxing_proving.tscn` |
| `REF-02` | Flow proving scene owner | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-mediapipe-python/.testbed/scenes/flow_proving.tscn` |
| `REF-03` | Boxing proving harness | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-mediapipe-python/.testbed/scripts/boxing_proving_harness.gd` |
| `REF-04` | Shared proving harness | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-mediapipe-python/.testbed/scripts/proving_harness.gd` |
| `REF-05` | Landmark overlay renderer | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-mediapipe-python/.testbed/scripts/landmark_drawer.gd` |
| `REF-06` | Prior Boxing gesture overlay plan / existing popup system truth | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-mediapipe-python/.plans/2026-05-19-boxing-gesture-requirements-hover-ui.md` |

---

## Tasks

### Task 1: Implement shared click-based info panel and prerecorded playback controls in Boxing / Flow proving scenes

**Bead ID:** `aerobeat-input-mediapipe-python-w7o`  
**SubAgent:** `primary`  
**Role:** `coder`  
**References:** `REF-01`–`REF-06`  
**Prompt:** Claim bead `aerobeat-input-mediapipe-python-w7o` with `bd update aerobeat-input-mediapipe-python-w7o --status in_progress --json` before editing. Implement Derrick's approved spec across the Boxing and Flow proving scenes. Reuse/unify the existing gesture info popup system into a shared click-based inspector controller that supports both gesture colliders and new MediaPipe landmark colliders. Rules: only one popup at a time; clicking a new gesture/landmark swaps the popup; clicking away closes it; clicking inside the panel does not close it; `X` button closes it; fixed panel location; enlarged invisible click targets for landmarks; closest target wins when overlap is ambiguous; panel UI gets first click priority. Landmark cards must show landmark name, position, tracking confidence percentage, and useful stable debugging values if easy/truthful to add now. While paused, landmark values freeze to the clicked frame; while playing they live-update for the selected landmark, showing `not currently tracked` while retaining last known values if tracking drops. Add prerecorded-video controls to both scenes at the bottom of the video feed area: play/pause and seek, visible only for prerecorded video sources and hidden for live camera sources. On seek, reset gesture/history buffers, jump to the requested point, and leave playback paused. Keep the implementation reusable for later richer MediaPipe debugging. Run relevant repo-local validation (at minimum headless scene/script smoke checks covering Boxing and Flow if feasible), commit, and push to `main` by default. Update this plan with exact files changed, validation run, and commit hash.

**Folders Created/Deleted/Modified:**
- `.testbed/scripts/`
- `.testbed/tests/unit/`
- `python_mediapipe/`
- `src/providers/`
- `.plans/`

**Files Created/Deleted/Modified:**
- `.testbed/scripts/boxing_proving_harness.gd`
- `.testbed/scripts/proving_harness.gd`
- `.testbed/scripts/landmark_drawer.gd`
- `.testbed/tests/unit/test_landmark_drawer.gd`
- `python_mediapipe/camera_streamer.py`
- `python_mediapipe/main.py`
- `src/providers/mediapipe_provider.gd`
- `.plans/2026-05-21-boxing-flow-landmark-inspector-and-playback-controls.md`

**Status:** ✅ Complete

**Results:** Implemented the shared fixed-position click inspector in `REF-04`, wired Boxing gesture badges in `REF-03` into that shared controller, and upgraded `REF-05` with enlarged nearest-hit landmark click targets so both Boxing and Flow can inspect landmarks through one panel surface. The panel now enforces single-open behavior, swaps targets on new clicks, ignores clicks inside the panel, supports click-away dismissal, and exposes an explicit `X` close button. Landmark cards now report landmark name/id, normalized position, tracking confidence percentage, tracking state, body-role hints, and stable velocity/direction debug values when the selected landmark maps to an existing semantic body-part surface.

Added prerecorded playback control/status support by extending the existing MJPEG HTTP sidecar surface in `python_mediapipe/camera_streamer.py` and `python_mediapipe/main.py` with truthful file-source pause/play/seek commands plus JSON playback status. `REF-04` now renders a bottom-of-feed playback bar for prerecorded sources only, polls status, toggles play/pause, and seeks by progress. Seeking explicitly clears local trail/event state, calls the provider reset surface in `src/providers/mediapipe_provider.gd`, jumps the Python capture to the requested point, and leaves playback paused. While paused on prerecorded sources, landmark inspector values freeze to the clicked frame; while playing, selected landmark values live-refresh and fall back to `not currently tracked` while preserving last known values when tracking drops.

Repo-local validation run:
- `python3 -m py_compile python_mediapipe/main.py python_mediapipe/camera_streamer.py` ✅
- `~/.local/bin/godot --headless --path .testbed --check-only --script scripts/proving_harness.gd` ✅
- `~/.local/bin/godot --headless --path .testbed --check-only --script scripts/boxing_proving_harness.gd` ✅
- `~/.local/bin/godot --headless --path .testbed --check-only --script scripts/landmark_drawer.gd` ✅
- `~/.local/bin/godot --headless --path .testbed res://scenes/boxing_proving.tscn --quit-after 1` ✅
- `~/.local/bin/godot --headless --path .testbed res://scenes/flow_proving.tscn --quit-after 1` ✅
- `~/.local/bin/godot --headless --path .testbed --script addons/gut/gut_cmdln.gd -gtest=res://tests/unit/test_landmark_drawer.gd -gexit` ✅ (`2/2`)
- `~/.local/bin/godot --headless --path .testbed --script addons/gut/gut_cmdln.gd -gtest=res://tests/unit/test_proving_harness_trails.gd -gexit` ⚠️ existing unrelated failure remains in `test_resolves_trail_hand_point_by_clamping_near_edge_jitter` (`10/11` passed); this coder slice did not modify the trail-hand-point logic under test.

---

### Task 2: Fix post-handoff inspector regressions from Derrick's manual Cookie test

**Bead ID:** `aerobeat-input-mediapipe-python-al0`  
**SubAgent:** `primary`  
**Role:** `coder`  
**References:** Task 1 output  
**Prompt:** Claim bead `aerobeat-input-mediapipe-python-al0` with `bd update aerobeat-input-mediapipe-python-al0 --status in_progress --json`. Fix the two regressions Derrick reported during manual Cookie testing of the new proving-scene inspector: (1) click-away dismissal does not currently close the open info panel, and (2) the shared panel width is too narrow, causing Punch-L gesture text to wrap onto two lines unnecessarily. Keep the existing shared inspector architecture, fix click-away behavior without breaking panel clicks or target swaps, widen the panel enough for the current Punch rows to read comfortably, run targeted validation, update this plan with exact changes and validation, then commit/push to `main` and close the bead.

**Folders Created/Deleted/Modified:**
- `.testbed/scripts/`
- `.plans/`

**Files Created/Deleted/Modified:**
- `.testbed/scripts/proving_harness.gd`
- `.plans/2026-05-21-boxing-flow-landmark-inspector-and-playback-controls.md`

**Status:** ✅ Complete

**Results:** Fixed both regressions with a focused shared-harness patch in `.testbed/scripts/proving_harness.gd`. Click-away dismissal now runs from `_input()` instead of `_unhandled_input()`, which lets background/control clicks close the open inspector even when other UI consumes the event later, while still preserving panel clicks, the `X` close button, and click-to-swap target behavior because clicks inside the panel early-return and new target clicks still reopen/swap after the close. Increased `INSPECTOR_PANEL_WIDTH` from `420.0` to `520.0` so current Punch inspector rows fit without the unnecessary wrap Derrick reported.

Targeted validation run:
- `~/.local/bin/godot --headless --path .testbed --check-only --script scripts/proving_harness.gd` ✅
- `~/.local/bin/godot --headless --path .testbed --check-only --script scripts/boxing_proving_harness.gd` ✅
- `~/.local/bin/godot --headless --path .testbed res://scenes/boxing_proving.tscn --quit-after 1` ✅

Commit / push: `0e00839` (`Fix proving inspector click-away and width`) pushed to `main`.

---

### Task 3: Manual truth-pass on Cookie terminal

**Bead ID:** `Deferred to Derrick`  
**SubAgent:** `Deferred to Derrick`  
**Role:** `qa`  
**References:** Task 1-2 output  
**Prompt:** Derrick will manually test the new landmark inspector and prerecorded playback controls on Cookie’s terminal once the follow-up fixes are landed.

**Folders Created/Deleted/Modified:**
- none yet

**Files Created/Deleted/Modified:**
- `.plans/2026-05-21-boxing-flow-landmark-inspector-and-playback-controls.md`

**Status:** ⏳ Pending

**Results:** Deferred to Derrick after coder handoff.

---

## Final Results

**Status:** ⚠️ Pending Derrick Manual QA

**What We Built:** The Boxing and Flow proving harnesses now share one click-based inspector controller for gesture and landmark debugging, plus a prerecorded-only playback bar with truthful play/pause/seek integration against the Python sidecar. Boxing gesture badges now open the shared inspector instead of a hover-only card, landmark dots now expose enlarged nearest-hit click targets, and prerecorded seeking clears local/provider gesture-history state before pausing on the requested frame. Follow-up manual Cookie testing surfaced two inspector UX regressions, and Task 2 repaired both with a focused shared-harness patch: background click-away dismissal now closes the open panel again, and the shared panel is wider so current Punch rows read on one line.

**Reference Check:** `REF-03` and `REF-04` now provide the shared inspector surface, working click-away dismissal, close-button dismissal, and target-swap behavior through the shared controller; `REF-05` still provides enlarged landmark hit-testing with closest-target resolution; `REF-01` was smoke-launched headlessly after the follow-up fix to confirm the Boxing proving scene still boots; `REF-06`'s prior Boxing gesture requirement content remains preserved through the shared inspector body renderer instead of the previous hover-only card.

**Commits:**
- `2dbf324` - Add proving inspector and playback controls
- `3e72292` - Update plan with final commit hash
- `0e00839` - Fix proving inspector click-away and width

**Lessons Learned:** Reusing the existing MJPEG HTTP surface for playback control/status kept the Godot-side UI honest and lightweight. Immediate human testing on Cookie was valuable because it caught two UX regressions that headless smoke checks did not: background click dismissal and practical readability width. The shared-harness architecture held up well here because both fixes stayed localized to one controller file instead of needing scene-specific rewrites. The pre-existing unrelated caveat remains that `test_proving_harness_trails.gd` still has a failure in `test_resolves_trail_hand_point_by_clamping_near_edge_jitter`, so manual QA should focus on the inspector/playback slice rather than treating that older failure as a regression from this work.

---

*Created on 2026-05-21*