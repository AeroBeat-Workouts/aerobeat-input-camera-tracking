# AeroBeat MediaPipe Python - Boxing / Flow Landmark Inspector and Playback Controls

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

Derrick will manually test this on Cookie's terminal after implementation, so this plan treats repo-local validation as required but defers final manual QA truth-pass to Derrick.

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
**References:** `REF-01`-`REF-06`
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

### Task 3: Fix landmark inspector truth/readability and expose smoothing mode

**Bead ID:** `aerobeat-input-mediapipe-python-ph5`
**SubAgent:** `primary`
**Role:** `coder`
**References:** Task 1-2 output
**Prompt:** Claim bead `aerobeat-input-mediapipe-python-ph5` with `bd update aerobeat-input-mediapipe-python-ph5 --status in_progress --json`. Implement the next agreed debugging slice in the shared proving-scene inspector/playback system. Fix the landmark inspector so live normalized `x`/`y` values are truthful and no longer stuck at `0.500`; audit the current `tracking state` readout to determine what it is actually measuring and either fix it to represent meaningful truth or relabel/remove it if it is misleading. Polish the prerecorded playback button so it uses icon representation for play/pause while keeping a fixed button width between states. Expose the real MediaPipe Python tracking/smoothing style choices as a public enum on both Boxing and Flow proving scenes so Derrick can compare feel/jitter directly during QA. Improve landmark inspector readability so fast-changing values are more human-usable (for example via throttling and/or stronger rounding) without lying about what is being shown. Keep the patch focused, run targeted validation, update this plan with exact files changed and truth findings, commit/push to `main`, and close the bead.

**Folders Created/Deleted/Modified:**
- `.testbed/scenes/`
- `.testbed/scripts/`
- `src/`
- `.plans/`

**Files Created/Deleted/Modified:**
- `.testbed/scenes/boxing_proving.tscn`
- `.testbed/scenes/flow_proving.tscn`
- `.testbed/scripts/proving_harness.gd`
- `.testbed/scripts/boxing_proving_harness.gd` if needed
- `.testbed/scripts/landmark_drawer.gd` if needed
- any MediaPipe Python config/provider files needed to expose real smoothing/tracking styles truthfully
- `.plans/2026-05-21-boxing-flow-landmark-inspector-and-playback-controls.md`

**Status:** ✅ Complete

**Results:** Fixed the landmark inspector truth/readability slice with a focused shared-harness patch plus explicit scene exposure for the new tracking/smoothing enum. `.testbed/scripts/proving_harness.gd` now builds inspector snapshots from the latest raw live landmark sample first and only uses detector-state landmarks as the smoothed fallback/debug companion, which repairs the misleading `x`/`y` values that could sit at `0.500` when the inspector was effectively reading the wrong surface. The inspector body now labels those lines truthfully as `Position (norm, raw live)` and `Detector-smoothed position`, preserves last-known raw values when tracking drops, and throttles live inspector refresh to about `0.12s` with an explicit footer note so fast-changing numbers stay readable without pretending they are frozen or exact-per-frame.

Audited the old `tracking state` line: it was not per-landmark state at all. The underlying substrate computes a whole-pose lock state from visible key-landmark count plus average visibility/confidence across the tracking landmark set (`tracking`, `reacquiring`, `degraded`, `lost`). To stop implying landmark-local truth, the shared harness now relabels that readout to `Detector pose lock` in the inspector and in the broader harness summary/quick-status surfaces.

Polished prerecorded playback controls by switching the toggle button to fixed-width icon text (`▶` / `⏸`) so play/pause no longer causes width jitter. Exposed the real MediaPipe Python sidecar comparison surface as a public `TrackingSmoothingStyle` enum on the shared harness and explicitly on both proving scenes (`FULL_RAW` default). The enum truthfully maps to sidecar `model_complexity` plus One-Euro filter on/off, and the harness now applies that mapping to `AutoStartManager` before launch so Derrick can compare raw vs filtered jitter/feel from the scene inspector without editing code.

Exact files changed in this slice:
- `.testbed/scripts/proving_harness.gd`
- `.testbed/scenes/boxing_proving.tscn`
- `.testbed/scenes/flow_proving.tscn`
- `.plans/2026-05-21-boxing-flow-landmark-inspector-and-playback-controls.md`

Targeted validation run:
- `python3 -m py_compile python_mediapipe/*.py` ✅
- `~/.local/bin/godot --headless --path .testbed --quit-after 2` ✅ (default Boxing harness boot smoke)
- `~/.local/bin/godot --headless --path .testbed res://scenes/boxing_proving.tscn --quit-after 1` ✅
- `~/.local/bin/godot --headless --path .testbed res://scenes/flow_proving.tscn --quit-after 1` ✅

Truth findings captured by this task:
- The stuck `0.500` inspector values were not a trustworthy live-landmark readout; the inspector needed to read the latest raw landmark sample first.
- The prior `tracking state` label was misleading because it described overall detector pose-lock health, not the selected landmark's individual tracking state.
- The real MediaPipe Python comparison knobs currently exposed by the sidecar are `model_complexity` and One-Euro filter enabled/disabled; this slice exposes exactly that combination as the public scene enum.

Commit / push: `5570e82` (`Fix landmark inspector truth and expose smoothing style`) pushed to `main`.

---

### Task 4: Polish timeline layout and preserve inspector while using playback controls

**Bead ID:** `aerobeat-input-mediapipe-python-6ca`  
**SubAgent:** `primary`  
**Role:** `coder`  
**References:** Task 1-3 output  
**Prompt:** Claim bead `aerobeat-input-mediapipe-python-6ca` with `bd update aerobeat-input-mediapipe-python-6ca --status in_progress --json`. Apply Derrick's latest QA polish feedback to the shared prerecorded playback UI: move the seek bar to the vertical center of the timeline panel instead of hugging the top, and make timeline interaction (seek + play/pause) preserve the currently open info popup instead of dismissing it. Keep the patch focused and shared if possible, run targeted validation, update this plan with exact files changed and commit hash, commit/push to `main`, and close the bead.

**Folders Created/Deleted/Modified:**
- `.testbed/scripts/`
- `.plans/`

**Files Created/Deleted/Modified:**
- `.testbed/scripts/proving_harness.gd`
- `.plans/2026-05-21-boxing-flow-landmark-inspector-and-playback-controls.md`

**Status:** ✅ Complete

**Results:** Applied the playback polish as a focused shared-harness patch in `.testbed/scripts/proving_harness.gd`. The prerecorded timeline row now sits inside a `CenterContainer` with a fixed minimum height so the seek slider is visually centered within the playback panel instead of riding the top edge. The shared inspector click-away path in `_input()` now treats the visible playback controls as an allowed interaction zone, so play/pause presses and seek clicks/drags no longer dismiss the currently open info popup while real background clicks still close it.

Targeted validation run:
- `~/.local/bin/godot --headless --path .testbed --check-only --script scripts/proving_harness.gd` ✅
- `~/.local/bin/godot --headless --path .testbed res://scenes/boxing_proving.tscn --quit-after 1` ✅
- `~/.local/bin/godot --headless --path .testbed res://scenes/flow_proving.tscn --quit-after 1` ✅

Commit / push: `5ba130d` (`Polish playback timeline inspector behavior`) pushed to `main`.

---

### Task 5: Manual truth-pass on Cookie terminal

**Bead ID:** `Deferred to Derrick`  
**SubAgent:** `Deferred to Derrick`  
**Role:** `qa`  
**References:** Task 1-4 output  
**Prompt:** Derrick will manually test the new landmark inspector and prerecorded playback controls on Cookie’s terminal once the follow-up fixes are landed.

**Folders Created/Deleted/Modified:**
- none yet

**Files Created/Deleted/Modified:**
- `.plans/2026-05-21-boxing-flow-landmark-inspector-and-playback-controls.md`

**Status:** ⏳ Pending

**Results:** Deferred to Derrick after coder handoff.

---

## Final Results

**Status:** ⚠️ In Progress

**What We Built:** The Boxing and Flow proving harnesses now share one click-based inspector controller for gesture and landmark debugging, plus a prerecorded-only playback bar with truthful play/pause/seek integration against the Python sidecar. Boxing gesture badges now open the shared inspector instead of a hover-only card, landmark dots expose enlarged nearest-hit click targets, prerecorded seeking clears local/provider gesture-history state before pausing on the requested frame, and the click-away/width regressions found during manual testing are fixed. The landmark-truth slice then switched the inspector to show raw live normalized position first, relabeled the old `tracking state` line to the truthful `Detector pose lock`, throttled live inspector refresh for readability with an explicit note, polished the playback toggle to fixed-width play/pause icons, and exposed the real sidecar comparison surface as a public tracking/smoothing enum on both Boxing and Flow proving scenes. This final coder polish pass centers the seek row within the timeline panel and preserves the currently open inspector while the user interacts with play/pause or seek controls.

**Reference Check:** `REF-03` and `REF-04` now provide the shared inspector surface, working click-away dismissal, close-button dismissal, target-swap behavior, truthful landmark-vs-detector-smoothed readouts, fixed-width playback icon controls, preserved inspector state during playback-control interaction, vertically centered seek-row layout, and the public tracking/smoothing enum wiring. `REF-05` still provides enlarged landmark hit-testing with closest-target resolution. `REF-01` and `REF-02` were smoke-launched headlessly after the timeline-polish slice to confirm both proving scenes still boot with the shared playback/inspector updates intact. `REF-06`'s prior Boxing gesture requirement content remains preserved through the shared inspector body renderer instead of the previous hover-only card.

**Commits:**
- `2dbf324` - Add proving inspector and playback controls
- `3e72292` - Update plan with final commit hash
- `0e00839` - Fix proving inspector click-away and width
- `a34d853` - Update plan for inspector regression fix
- `5570e82` - Fix landmark inspector truth and expose smoothing style
- `9e0ac48` - Update plan for landmark truth slice
- `5ba130d` - Polish playback timeline inspector behavior

**Lessons Learned:** Reusing the existing MJPEG HTTP surface for playback control/status kept the Godot-side UI honest and lightweight. Immediate human testing on Cookie was valuable because it caught UX regressions and then exposed deeper debug-truth problems that headless smoke checks did not: first background click dismissal and practical readability width, then stuck `x/y`, misleading tracking-state behavior, jitter/smoothing concerns, and finally timeline-specific polish around panel affordances and allowed-click zones. The shared-harness architecture continues to hold up because these fixes remain localized instead of forcing scene-specific rewrites. The main UI lesson from this final slice is that click-away dismissal needs a clearly defined allowlist for interactive overlay surfaces, otherwise shared debug panels feel brittle even when the underlying state model is correct.

---

*Created on 2026-05-21*
