# AeroBeat Straight-Punch Depth-Spike Threshold Experiment

**Date:** 2026-06-12  
**Status:** In Progress  
**Last Updated:** 2026-06-12 16:20 EDT  
**Blocked Reason:** None  
**Agent:** `pico`

---

## Goal

Try a new straight-punch detection idea in `aerobeat-input-camera-tracking`: expose a public YAML tuning variable for a forward depth-spike threshold and test whether a short rolling-window Z-change signal can improve straight-punch detection without making the detector too noisy or too brittle.

---

## Overview

Derrick wants to pause the broader boxing milestone execution for a bit and explore a more direct threshold-system idea inside the existing runtime detector. The observation is that elbow depth (`z`) is noisy frame-to-frame, but during a real straight punch it appears to dip briefly in a useful way. That suggests we may be able to add a small rolling-window forward-depth-spike check as an additional gate for straight punches rather than relying only on the current velocity, bbox-growth, and elbow/shoulder XY checks.

The plan should stay narrow. This is not a broader punch-classifier redesign, not a new saved-session substrate slice, and not a reopening of the learned-classifier milestone planning. It is a focused runtime experiment in the current threshold system of `aerobeat-input-camera-tracking`, aimed specifically at straight punches.

My recommendation is to keep the first pass minimal and public-config friendly:
- add exactly one new public YAML threshold for the new gate,
- reuse the existing straight-punch `evaluation.window_ms` as the rolling-window span if that is sufficient,
- only add a second public tuning knob if implementation proves the shared window is not workable,
- surface the new signal clearly in straight-punch debug state so replay/live tuning stays honest.

This keeps the experiment cheap to compare and easy to back out if the Z-depth signal turns out to be too noisy to trust.

---

## REFERENCES

| ID | Description | Path |
| --- | --- | --- |
| `REF-01` | Current straight-punch public gesture config | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/assets/boxing.gesture_detection.yaml` |
| `REF-02` | Straight-punch detector/runtime implementation | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/src/detectors/pose_detector_substrate.gd` |
| `REF-03` | Current straight-punch unit coverage | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.testbed/tests/unit/test_pose_detector_substrate.gd` |
| `REF-04` | Public signal surface for punch events/debug relays | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/src/AeroCameraTracking.gd` |
| `REF-05` | Boxing proving scene / fixtures | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.testbed` |
| `REF-06` | Existing smoothing experiment plan paused during this redirect | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.plans/2026-06-10-lite-raw-smoothing-improvement.md` |

---

## Recommended First-Pass Shape

### Proposed public YAML seam

Recommendation: add one new threshold under:
- `straight_punch.thresholds.min_forward_depth_spike`

Intent:
- this threshold represents the minimum short-window forward depth change signal needed for the new straight-punch gate to pass
- the exact internal metric can be finalized during implementation, but it must be documented plainly in the YAML comments and surfaced in debug output

### Proposed windowing rule

Recommendation: first reuse:
- `straight_punch.evaluation.window_ms`

Why:
- it keeps the first experiment simple
- it avoids immediately adding multiple new tuning knobs
- it keeps the new gate aligned with the existing straight-punch motion window

Only introduce a separate public depth-spike window knob if implementation demonstrates that the shared window is too coarse or too coupled to the existing velocity/bbox-growth checks.

### Proposed runtime behavior

Recommendation: the new depth-spike signal should be an **additional trigger gate** for straight punches, not a replacement for the existing detector.

That means the first-pass detector should still preserve:
- current straight-punch state machine behavior
- current public punch events
- current rearm / grace behavior
- existing config keys and default behavior when the new threshold is absent or neutralized

### Proposed debug surfacing

The first pass should expose enough debug state to answer:
- what forward depth metric was measured this frame/window?
- what was the recent peak depth-spike value?
- what threshold was required?
- did the new gate pass or fail?
- was a missed/triggered punch decided by the new gate or by the prior gates?

Without that, the experiment will be too hard to tune honestly.

---

## Tasks

### Task 1: Implement the public straight-punch depth-spike threshold experiment

**Bead ID:** `aerobeat-input-camera-tracking-51r`  
**SubAgent:** `primary` (for `coder` workflow role)  
**Role:** `coder`  
**References:** `REF-01`, `REF-02`, `REF-03`, `REF-04`, `REF-05`  
**Prompt:** Pending approval. In `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking`, implement a narrow straight-punch threshold experiment. Add one new public YAML threshold for a forward depth-spike gate on straight punches, ideally `straight_punch.thresholds.min_forward_depth_spike`. Reuse the existing `straight_punch.evaluation.window_ms` as the rolling-window span unless implementation proves a separate public knob is required. Treat the new signal as an additional trigger gate rather than a replacement for the current velocity/bbox-growth/XY logic. Surface the new metric and gate truth in straight-punch debug output, add/update focused unit coverage, run the most relevant validation available, and commit/push by default.

**Folders Created/Deleted/Modified:**
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/assets`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/src/detectors`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.testbed/tests/unit`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.testbed`

**Files Created/Deleted/Modified:**
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/assets/boxing.gesture_detection.yaml`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/src/detectors/pose_detector_substrate.gd`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.testbed/tests/unit/test_pose_detector_substrate.gd`
- any narrowly related proving/debug harness files if needed

**Status:** ✅ Complete

**Results:** Implemented the experiment in `REF-01`/`REF-02`/`REF-03`/`REF-05` and kept the scope narrow. Added the new public YAML key `straight_punch.thresholds.min_forward_depth_spike` with a plain comment in `REF-01`, set to `0.08` in the boxing profile. In runtime, the new gate reuses `straight_punch.evaluation.window_ms` and measures **forward depth spike** as the current rolling-window drop in the straight-punch velocity-signal position's `z` value: `max(window_z) - latest_z`, clamped at `>= 0`. With hand tracking disabled, that velocity-signal position is the existing elbow+wrist midpoint already used by the pose-only straight-punch path; with hand tracking enabled it stays aligned with the existing straight-punch signal source. The detector now surfaces `forward_depth_spike`, `recent_peak_forward_depth_spike`, `min_forward_depth_spike`, `forward_depth_spike_gate_passed`, and `forward_depth_spike_window_span_ms` in straight-punch debug state and transition snapshots, and requires the new gate in addition to the current velocity/bbox-growth/XY gates before triggering.

For proving/debug visibility, `REF-05` now exposes the signal in the boxing proving scene's existing straight-punch surfaces: the live hand debug line, the punch hover-card trigger rows, the custom inspector body, the state-change payload snapshot, and the straight-punch tuning summary all show the recent forward depth spike and threshold/gate truth so Derrick can inspect it during replay/live proving.

Focused validation passed with:
- `godot --headless --path .testbed --script addons/aerobeat-vendor-godot-unit-test/gut_cmdln.gd -gtest=res://tests/unit/test_pose_detector_substrate.gd,res://tests/unit/test_boxing_proving_harness_profiles_and_debug.gd,res://tests/unit/test_camera_tracking_config_profiles.gd -gexit`

Coder handoff status: ready for QA after commit/push. Commit hash: `2a25b36` (coder handoff commit).

---

### Task 2: QA the straight-punch depth-spike threshold experiment

**Bead ID:** `aerobeat-input-camera-tracking-me2`  
**SubAgent:** `primary` (for `qa` workflow role)  
**Role:** `qa`  
**References:** `REF-01`, `REF-02`, `REF-03`, `REF-05`  
**Prompt:** Pending coder handoff. Validate the straight-punch depth-spike experiment against the current straight-punch behavior using focused unit tests plus the best replay/proving-scene checks available. Confirm the new YAML threshold is public and documented, the debug state exposes the new signal honestly, and judge whether the added gate improves straight-punch behavior without introducing obvious misses, duplicates, or new false positives.

**Folders Created/Deleted/Modified:**
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/assets`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/src/detectors`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.testbed`

**Files Created/Deleted/Modified:**
- coder-touched files plus QA artifacts as needed

**Status:** ⏳ Pending

**Results:** Implemented the experiment in `REF-01`/`REF-02`/`REF-03`/`REF-05` and kept the scope narrow. Added the new public YAML key `straight_punch.thresholds.min_forward_depth_spike` with a plain comment in `REF-01`, set to `0.08` in the boxing profile. In runtime, the new gate reuses `straight_punch.evaluation.window_ms` and measures **forward depth spike** as the current rolling-window drop in the straight-punch velocity-signal position's `z` value: `max(window_z) - latest_z`, clamped at `>= 0`. With hand tracking disabled, that velocity-signal position is the existing elbow+wrist midpoint already used by the pose-only straight-punch path; with hand tracking enabled it stays aligned with the existing straight-punch signal source. The detector now surfaces `forward_depth_spike`, `recent_peak_forward_depth_spike`, `min_forward_depth_spike`, `forward_depth_spike_gate_passed`, and `forward_depth_spike_window_span_ms` in straight-punch debug state and transition snapshots, and requires the new gate in addition to the current velocity/bbox-growth/XY gates before triggering.

For proving/debug visibility, `REF-05` now exposes the signal in the boxing proving scene's existing straight-punch surfaces: the live hand debug line, the punch hover-card trigger rows, the custom inspector body, the state-change payload snapshot, and the straight-punch tuning summary all show the recent forward depth spike and threshold/gate truth so Derrick can inspect it during replay/live proving.

Focused validation passed with:
- `godot --headless --path .testbed --script addons/aerobeat-vendor-godot-unit-test/gut_cmdln.gd -gtest=res://tests/unit/test_pose_detector_substrate.gd,res://tests/unit/test_boxing_proving_harness_profiles_and_debug.gd,res://tests/unit/test_camera_tracking_config_profiles.gd -gexit`

Coder handoff status: ready for QA after commit/push. Commit hash: `2a25b36` (coder handoff commit).

---

### Task 3: Audit the straight-punch depth-spike threshold experiment

**Bead ID:** `aerobeat-input-camera-tracking-uwg`  
**SubAgent:** `primary` (for `auditor` workflow role)  
**Role:** `auditor`  
**References:** `REF-01`, `REF-02`, `REF-03`, `REF-05`  
**Prompt:** Pending QA handoff. Audit the straight-punch depth-spike experiment independently. Confirm the plan stayed narrow, the public YAML/config seam is appropriate, the detector/debug behavior matches the implementation truth, and the validation evidence actually supports keeping or rejecting the new threshold gate.

**Folders Created/Deleted/Modified:**
- Pending

**Files Created/Deleted/Modified:**
- Pending

**Status:** ⏳ Pending

**Results:** Implemented the experiment in `REF-01`/`REF-02`/`REF-03`/`REF-05` and kept the scope narrow. Added the new public YAML key `straight_punch.thresholds.min_forward_depth_spike` with a plain comment in `REF-01`, set to `0.08` in the boxing profile. In runtime, the new gate reuses `straight_punch.evaluation.window_ms` and measures **forward depth spike** as the current rolling-window drop in the straight-punch velocity-signal position's `z` value: `max(window_z) - latest_z`, clamped at `>= 0`. With hand tracking disabled, that velocity-signal position is the existing elbow+wrist midpoint already used by the pose-only straight-punch path; with hand tracking enabled it stays aligned with the existing straight-punch signal source. The detector now surfaces `forward_depth_spike`, `recent_peak_forward_depth_spike`, `min_forward_depth_spike`, `forward_depth_spike_gate_passed`, and `forward_depth_spike_window_span_ms` in straight-punch debug state and transition snapshots, and requires the new gate in addition to the current velocity/bbox-growth/XY gates before triggering.

For proving/debug visibility, `REF-05` now exposes the signal in the boxing proving scene's existing straight-punch surfaces: the live hand debug line, the punch hover-card trigger rows, the custom inspector body, the state-change payload snapshot, and the straight-punch tuning summary all show the recent forward depth spike and threshold/gate truth so Derrick can inspect it during replay/live proving.

Focused validation passed with:
- `godot --headless --path .testbed --script addons/aerobeat-vendor-godot-unit-test/gut_cmdln.gd -gtest=res://tests/unit/test_pose_detector_substrate.gd,res://tests/unit/test_boxing_proving_harness_profiles_and_debug.gd,res://tests/unit/test_camera_tracking_config_profiles.gd -gexit`

Coder handoff status: ready for QA after commit/push. Commit hash: `2a25b36` (coder handoff commit).

---

## Final Results

**Status:** ⚠️ Partial

**What We Built:** A narrow straight-punch depth-spike experiment in the live threshold detector: one new public YAML threshold, one reused rolling motion window, one added trigger gate in the straight-punch state machine, and matching proving-scene/debug surfaces plus focused test coverage.

**Reference Check:** `REF-01` through `REF-05` were updated/validated. The runtime now exposes the new forward-depth metric honestly through the detector debug state and the boxing proving scene without reopening the paused smoothing work in `REF-06`.

**Commits:**
- `2a25b36` - Add straight punch forward depth spike gate

**Lessons Learned:** The first pass should stay narrow: one new public threshold, one existing window if possible, honest debug surfacing, and no broader classifier redesign hidden inside a tuning experiment.

---

*Drafted on 2026-06-12*
