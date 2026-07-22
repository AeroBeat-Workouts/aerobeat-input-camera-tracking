# AeroBeat Input Camera Tracking - Boxing/Flow Proving Follow-ups

**Date:** 2026-07-21  
**Status:** In Progress  
**Last Updated:** 2026-07-21 21:36 EDT  
**Blocked Reason:** None  
**Agent:** `pico`

---

## Goal

Fix the reported boxing/flow proving-scene regressions so the startup warning is gone, the boxing inspector reflects pose-only truth, stale debug UI is removed, and replay/live athlete calibration behaves truthfully instead of oscillating or acting disconnected from visible pose tracking.

---

## Overview

This lane belongs in `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking`. Derrick reported six concrete issues across the boxing/flow proving scenes: a `CONFUSABLE_LOCAL_DECLARATION` warning in `proving_harness.gd`, a straight-left inspector that still claims `tracking_lost` while visible replay pose tracking is clearly active, stale hand-tracking references that should be removed from the inspector, unwanted calibration helper text under the `Calibrate Athlete` button, a calibration loop that appears to count down, bottom out, rise, and repeat, and a leftover `Depth - Straight Punch` window that should no longer exist in the pose-threshold-only architecture.

Earlier repo memory and archived plans make this look like a mixed seam, not six unrelated paper cuts. On 2026-06-08 we already fixed one straight-punch overlay truth bug where the boxing overlay showed gesture `tracking_lost` even while tracker-owned states were visible (`memory/2026-06-08.md#L9-L11`). More recently, the archived 2026-07-20 calibration regression plan documented that replay calibration and proving-scene truth had already drifted apart, including a calibration loop/disappearing-grid seam and a separate straight-punch state-publication seam. So the first execution step should be an audit that checks whether today’s bad straight-left state label and broken calibration loop are re-opened versions of those earlier truths or a new shared regression deeper in the current state plumbing.

The plan keeps the work narrow and staged. First reproduce and map the exact current truth in the owning source and testbed scenes. Then land one bounded implementation slice for stale warning/UI cleanup, followed by a second bounded slice for the straight-punch/calibration state-path bug if the audit confirms a deeper shared cause. Then run QA and independent audit before calling it done.

---

## REFERENCES

| ID | Description | Path |
| --- | --- | --- |
| `REF-01` | Derrick’s current bug report and screenshots for boxing/flow proving scenes | `/home/derrick/.openclaw/workspace/.temp/nerve-uploads/2026/07/22/image-eb668cba.png`, `/home/derrick/.openclaw/workspace/.temp/nerve-uploads/2026/07/22/image-f419b065.png` |
| `REF-02` | Earlier durable diagnosis: straight-punch overlay showed `tracking_lost` even when tracker-owned states were visible | `/home/derrick/.openclaw/workspace/memory/2026-06-08.md#L9-L11` |
| `REF-03` | Recent archived plan for calibration loop / straight-punch regression seam | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.plans/archive/2026-07-20-calibration-loop-grid-overlay-and-straight-punch-regressions.md` |
| `REF-04` | Recent archived proving-scene UI simplification plan | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.plans/archive/2026-07-21-calibration-ui-and-grid-inspector-simplification.md` |
| `REF-05` | Current shared proving harness script with the startup warning and calibration panel logic | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.testbed/scripts/proving_harness.gd` |
| `REF-06` | Current boxing proving harness inspector/debug surface | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.testbed/scripts/boxing_proving_harness.gd` |
| `REF-07` | Current detector/calibration/state plumbing | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/src/detectors/pose_detector_substrate.gd` |
| `REF-08` | Current Boxing proving scene | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.testbed/scenes/boxing_proving.tscn` |
| `REF-09` | Current Flow proving scene | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.testbed/scenes/flow_proving.tscn` |

---

## Tasks

### Task 1: Audit the current proving-scene warning, stale UI, and calibration/state-truth regressions

**Bead ID:** `aerobeat-input-camera-tracking-uutq`  
**SubAgent:** `primary` (for `research`)  
**Role:** `research`  
**References:** `REF-01`, `REF-02`, `REF-03`, `REF-04`, `REF-05`, `REF-06`, `REF-07`, `REF-08`, `REF-09`  
**Prompt:** In `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking`, claim bead `aerobeat-input-camera-tracking-uutq` with `bd update aerobeat-input-camera-tracking-uutq --status in_progress --json`. Reproduce and classify Derrick’s six current proving-scene complaints: (1) the `button_row` startup warning in `proving_harness.gd`, (2) Straight Punch L inspector wrongly showing `tracking_lost` despite visible replay pose tracking, (3) stale hand-tracking references near the top of the inspector, (4) unwanted diagnostic text beneath `Calibrate Athlete`, (5) the calibration countdown/capture loop that drops, rises, and repeats, and (6) the leftover `Depth - Straight Punch` window in the boxing scene. Check whether items 2 and 5 are separate or a shared state-path regression by tracing current proving-harness + substrate truth against the earlier diagnosis in `REF-02` and the archived calibration regression plan in `REF-03`. Update this plan with exact files/lines, root-cause map, and the narrowest truthful next implementation split. Do not implement fixes yet unless a tiny inseparable code correction is required to complete reproduction. Close the bead with `bd close aerobeat-input-camera-tracking-uutq --reason "Audited current proving-scene regressions" --json` when done.

**Folders Created/Deleted/Modified:**
- `.plans/`
- testbed/runtime surfaces only if needed for investigation artifacts

**Files Created/Deleted/Modified:**
- `.plans/2026-07-21-boxing-flow-proving-followups.md`

**Status:** ✅ Complete

**Results:** Audit complete. Repo-local source review plus headless proving-scene/unit validation says the six complaints split into one parser-warning cleanup seam, three stale UI/debug-surface seams, and one deeper calibration/runtime seam. Exact map:
- **(1) `CONFUSABLE_LOCAL_DECLARATION` warning:** `/.testbed/scripts/proving_harness.gd:357` declares `var button_row := HBoxContainer.new()` inside the creation branch, then `/.testbed/scripts/proving_harness.gd:374` redeclares `var button_row := ...` in the outer scope before later reuse at lines 396-402. That same-name shadow/redeclaration pattern is the precise warning source map.
- **(2) Straight Punch L inspector shows `tracking_lost` while replay pose tracking is visibly active:** in `/.testbed/scripts/boxing_proving_harness.gd`, `PUNCH_REQUIREMENT_ROWS` still frames the top truth row as hand-tracking (`lines 101-105`), and `_build_punch_requirement_row()` derives `current_state` from `straight_side.state` alone (`lines 1761, 1794-1796`) while the separate tracking row already knows the pose-only truth (`lines 1797-1808`). In pose-only replay mode, that makes it possible for the top state row to stay `tracking_lost` even when the next row says `pose_valid=true, tracking=pose_tracked, source=pose...`. This matches the older `REF-02` “UI truth bug, not actual tracker loss” pattern.
- **(3) Exact stale UI surfaces near the top of the inspector:** the top requirement-row label is still literally `Hand tracking` at `/.testbed/scripts/boxing_proving_harness.gd:101-105`, and the inspector body still renders `Hand tracking - ...` even in pose-only fallback cases because it reuses that row label. The compact live debug line in `_build_boxing_straight_punch_debug_line()` (`lines 2505-2520`) also still carries hand-specific fields (`hand_grace`, `hand_stable`, `stale`) even after it swaps to pose fallback truth.
- **(4) Extra diagnostic text under `Calibrate Athlete`:** `/.testbed/scripts/proving_harness.gd` always builds and updates three subordinate labels directly under the button — `CalibrationCountdownLabel` (`lines 348-350`), `CalibrationInstructionLabel` (`351-353`), and `CalibrationStatusLabel` (`354-356`) — and `_refresh_calibration_flow_ui()` keeps them visible whenever their helper text is non-empty (`lines 542-550`). Idle/default copy comes from `_calibration_countdown_text()` returning `5-second countdown, then 5 valid capture frames` (`line 604`) and `_calibration_status_text()` returning `Calibration ready.` / `No shared baseline captured yet.` (`lines 648-652`). Those are the exact unwanted diagnostic surfaces.
- **(5) Calibration loop/countdown oscillation:** I could not honestly reproduce the live visual `count down -> bottom out -> rise again` loop headlessly, but the strongest repo-local source + test evidence says this is a **separate seam from item 2**, not the same root cause. `src/detectors/pose_detector_substrate.gd:_update_calibration_session()` (`lines 736-766`) and `_evaluate_calibration_readiness()` (`768-790`) still pass the focused calibration-session tests, including boundary-blip/dropout cases. Headless validation (`test_pose_detector_substrate.gd` calibration-session group and proving-harness `shared_calibration` group) passed, so the oscillation is most likely in proving-scene/runtime interaction or clip-specific readiness churn rather than the straight-punch inspector truth path.
- **(6) Leftover `Depth - Straight Punch` window:** the boxing proving harness still always constructs the depth debug overlay in `_ready()` via `_ensure_depth_debug_ui()` (`/.testbed/scripts/boxing_proving_harness.gd:472-476, 615-623`), and `_effective_depth_debug_visual_config()` force-enables it whenever any depth runtime/debug truth exists (`lines 700-719`), even if the configured visuals say depth debug is disabled. That explains why a depth viewer can still appear in the current pose-threshold-first architecture.
- **Shared vs separate root-cause finding:** items **(2)** and **(5)** do **not** collapse into the same cause. Item **(2)** is an inspector truth/composition bug inside `boxing_proving_harness.gd` and matches the earlier `REF-02` stale-overlay pattern. Item **(5)** currently looks like a proving-scene/session/runtime seam that is *not* reproduced by the detector-level calibration state machine tests.
- **Strongest repo-local validation run:**
  - `godot --headless --path .testbed --script addons/aerobeat-vendor-godot-unit-test/gut_cmdln.gd -gtest=res://tests/unit/test_pose_detector_substrate.gd -gunit_test_name=calibration_session -gexit` ✅ passed (4/4)
  - `godot --headless --path .testbed --script addons/aerobeat-vendor-godot-unit-test/gut_cmdln.gd -gtest=res://tests/unit/test_boxing_proving_harness_profiles_and_debug.gd -gunit_test_name=shared_calibration -gexit` ✅ passed (3/3)
  - `godot --headless --path .testbed --script addons/aerobeat-vendor-godot-unit-test/gut_cmdln.gd -gtest=res://tests/unit/test_boxing_proving_harness_profiles_and_debug.gd -gunit_test_name=punch -gexit` ✅ passed (8/8)
- **Narrowest truthful implementation order:**
  1. `/.testbed/scripts/proving_harness.gd`: remove the `button_row` redeclaration/shadow warning and collapse/hide the countdown/instruction/status helper labels so only the intended button-centric calibration UI remains.
  2. `/.testbed/scripts/boxing_proving_harness.gd`: rename/remove stale hand-tracking copy at the top of the straight-punch inspector and make the top `Current state` row derive truthful pose-only replay state instead of blindly repeating stale `tracking_lost` state-machine text.
  3. `/.testbed/scripts/boxing_proving_harness.gd` plus `/.testbed/scripts/depth_debug_viewer.gd` as needed: stop auto-forcing the depth debug viewer on for straight-punch runtime truth in this proving scene.
  4. Only after the UI-cleanup slice lands, do a separate pass on the calibration oscillation seam if it still reproduces interactively; likely touch `src/detectors/pose_detector_substrate.gd`, `/.testbed/scripts/proving_harness.gd`, and whichever proving-scene replay/live state plumbing proves guilty under a higher-fidelity repro.
- **Likely files/tests to touch next:**
  - Code: `/.testbed/scripts/proving_harness.gd`, `/.testbed/scripts/boxing_proving_harness.gd`, possibly `/.testbed/scripts/depth_debug_viewer.gd`, and only if the separate calibration seam is confirmed, `src/detectors/pose_detector_substrate.gd`.
  - Tests: `/.testbed/tests/unit/test_boxing_proving_harness_profiles_and_debug.gd` for inspector/calibration/depth-viewer expectations, and potentially `/.testbed/tests/unit/test_pose_detector_substrate.gd` only if calibration-session behavior itself changes.

---

### Task 2: Clean startup warning and remove stale proving-scene debug UI

**Bead ID:** `aerobeat-input-camera-tracking-259p`  
**SubAgent:** `primary` (for `coder`)  
**Role:** `coder`  
**References:** `REF-01`, `REF-04`, `REF-05`, `REF-06`, `REF-08`, `REF-09`  
**Prompt:** In `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking`, claim bead `aerobeat-input-camera-tracking-259p` with `bd update aerobeat-input-camera-tracking-259p --status in_progress --json`. Fix the low-risk proving-scene cleanup slice after the audit: remove the `button_row` warning, remove stale hand-tracking references from the straight-punch inspector, remove the extra calibration helper text under `Calibrate Athlete`, and remove the leftover `Depth - Straight Punch` window from the boxing proving scene. Keep the slice narrow and truthful to the current pose-threshold-only architecture. Update this plan with exact files changed, validation run, and commit hash, commit/push to `main` by default when ready for QA, and close the bead with `bd close aerobeat-input-camera-tracking-259p --reason "Implemented proving-scene stale UI cleanup" --json`.

**Folders Created/Deleted/Modified:**
- `.testbed/`
- `.plans/`

**Files Created/Deleted/Modified:**
- `.testbed/scripts/proving_harness.gd`
- `.testbed/scripts/boxing_proving_harness.gd`
- `.testbed/tests/unit/test_boxing_proving_harness_profiles_and_debug.gd`
- `.plans/2026-07-21-boxing-flow-proving-followups.md`

**Status:** ✅ Complete

**Results:** Implemented the narrow stale-UI cleanup slice without broadening into the unresolved calibration oscillation seam. Exact changes:
- `/.testbed/scripts/proving_harness.gd`: renamed the inner calibration button-row local to eliminate the `CONFUSABLE_LOCAL_DECLARATION` warning, and stopped surfacing the countdown/instruction/status helper labels so the shared athlete-calibration panel stays button-centric.
- `/.testbed/scripts/boxing_proving_harness.gd`: renamed the straight-punch top inspector row from `Hand tracking` to `Tracking status`, added truthful pose-only fallback for the top `Current state` row when stale `tracking_lost` text conflicts with valid pose tracking, and stopped auto-creating/force-enabling the straight-punch depth debug viewer unless depth visuals are explicitly enabled.
- `/.testbed/tests/unit/test_boxing_proving_harness_profiles_and_debug.gd`: updated the calibration/UI expectations to the button-centric presentation, added coverage for truthful pose-only straight-punch state text, asserted the boxing proving scene no longer builds `DepthDebugRoot` by default, and kept explicit opt-in coverage for the depth-debug viewer behavior.
- Strongest repo-local validation: `godot --headless --path .testbed --script addons/aerobeat-vendor-godot-unit-test/gut_cmdln.gd -gtest=res://tests/unit/test_boxing_proving_harness_profiles_and_debug.gd -gexit` ✅ passed (40/40, 491 asserts).
- Commit hash: `74f9fe1` (`Clean up boxing proving stale UI`).
- Scope note: this resolves audited items 1-4 and 6. The separate calibration oscillation seam from item 5 was intentionally left untouched for a later slice unless QA disproves the audit.

---

### Task 3: Fix straight-punch state truth and athlete calibration state-path bug

**Bead ID:** `aerobeat-input-camera-tracking-ws2l`  
**SubAgent:** `primary` (for `coder`)  
**Role:** `coder`  
**References:** `REF-01`, `REF-02`, `REF-03`, `REF-05`, `REF-06`, `REF-07`, `REF-08`, `REF-09`  
**Prompt:** In `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking`, claim bead `aerobeat-input-camera-tracking-ws2l` with `bd update aerobeat-input-camera-tracking-ws2l --status in_progress --json`. After the audit and stale-UI cleanup, fix the deeper proving-scene state bug if confirmed: the boxing straight-left inspector should reflect truthful pose-only tracking state during replay/live pose tracking, and the athlete calibration flow should no longer oscillate/restart in a loop. Use the earlier 2026-06-08 overlay truth diagnosis and the 2026-07-20 calibration regression plan as source truth first, then repair the current underlying state path rather than papering over symptoms in labels alone. Keep the slice bounded to the current shared cause if one exists; if the audit proves separate causes, implement only the explicit audited split and document it. Update this plan with exact files changed, validation run, commit hash, and any remaining caveat; commit/push to `main` by default when ready for QA; close the bead with `bd close aerobeat-input-camera-tracking-ws2l --reason "Implemented proving-scene state truth and calibration fix" --json`.

**Folders Created/Deleted/Modified:**
- `.testbed/`
- `src/`
- `.plans/`

**Files Created/Deleted/Modified:**
- `.testbed/scripts/boxing_proving_harness.gd`
- `.testbed/tests/unit/test_pose_detector_substrate.gd`
- `src/detectors/pose_detector_substrate.gd`
- `.plans/2026-07-21-boxing-flow-proving-followups.md`

**Status:** ✅ Complete

**Results:**
- **Reproduced/found:** the remaining deeper seams still split cleanly rather than collapsing into one root cause.
  - **Straight-punch runtime truth:** after the stale UI cleanup, the proving harness was still deriving pose-only `pose_tracked` truth locally in `boxing_proving_harness.gd`, but the substrate debug payload itself still exposed only raw straight-punch state-machine `state=tracking_lost`. That meant the top inspector row looked better, but the underlying runtime payload was still making the harness paper over pose-only truth instead of receiving it directly.
  - **Calibration oscillation/restart seam:** the substrate still timed calibration countdown/capture windows off the incoming frame `timestamp_ms`. On replay clips, when playback timestamps rewound at loop boundaries, calibration session time could jump backward/upward and effectively restart or stretch the countdown instead of progressing monotonically with the visible replay session. This is the honest deeper runtime seam behind the reported proving-scene calibration loop.
- **Exact implementation route:**
  - `src/detectors/pose_detector_substrate.gd`
    - added a monotonic session runtime clock (`runtime_timestamp_ms`) that advances with forward timestamps but does **not** jump backward on replay timestamp rewind.
    - switched calibration-session start/update/baseline capture timing to that monotonic runtime clock while leaving the raw source `timestamp_ms` intact for the rest of the replay/debug surfaces.
    - added straight-punch debug field `truthful_state` so pose-only replay/live consumers receive truthful runtime state directly from the substrate instead of reconstructing it only in UI code.
  - `/.testbed/scripts/boxing_proving_harness.gd`
    - updated `_truthful_punch_state_name()` to prefer substrate-provided `truthful_state` first, falling back to the prior local interpretation only when older payloads omit it.
  - `/.testbed/tests/unit/test_pose_detector_substrate.gd`
    - added regression coverage proving pose-only straight-punch debug now exposes `truthful_state = pose_tracked` while raw state remains `tracking_lost` until actual trigger-state transitions occur.
    - added a replay-loop calibration regression proving a countdown started near the end of a replay clip no longer jumps upward after timestamp rewind and can still complete successfully across the wrap.
- **Strongest repo-local validation:**
  - `godot --headless --path .testbed --script addons/aerobeat-vendor-godot-unit-test/gut_cmdln.gd -gtest=res://tests/unit/test_pose_detector_substrate.gd -gexit` ✅ passed (**79/79 tests, 909 asserts**).
  - `godot --headless --path .testbed --script addons/aerobeat-vendor-godot-unit-test/gut_cmdln.gd -gtest=res://tests/unit/test_boxing_proving_harness_profiles_and_debug.gd -gunit_test_name=shared_calibration -gexit` ✅ passed (**3/3 tests, 109 asserts**).
  - `godot --headless --path .testbed --script addons/aerobeat-vendor-godot-unit-test/gut_cmdln.gd -gtest=res://tests/unit/test_boxing_proving_harness_profiles_and_debug.gd -gunit_test_name=punch -gexit` ✅ passed (**8/8 tests, 69 asserts**).
- **Commit hash:** `5ed93ed` (`Fix proving calibration replay timing truth`)
- **Remaining honesty boundary:** I reproduced the calibration bug truthfully at the repo-local runtime/state-machine level by simulating replay timestamp rewind and fixed that underlying timing seam. I did **not** run an interactive GUI/manual proving scene to claim the exact on-screen oscillation is visually gone in every transport scenario yet; QA should still verify the highest-fidelity proving run path.

---

### Task 4: QA the boxing/flow proving-scene fixes at repo-local highest fidelity

**Bead ID:** `aerobeat-input-camera-tracking-3qh8`  
**SubAgent:** `primary` (for `qa`)  
**Role:** `qa`  
**References:** `REF-01`, `REF-05`, `REF-06`, `REF-07`, `REF-08`, `REF-09`  
**Prompt:** In `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking`, claim bead `aerobeat-input-camera-tracking-3qh8` with `bd update aerobeat-input-camera-tracking-3qh8 --status in_progress --json`. Independently verify that the startup warning is gone, the boxing straight-left inspector no longer lies about `tracking_lost` while pose tracking is visibly active, stale hand/depth UI is gone, the calibration panel is simplified to the intended button-centric presentation, and the calibration flow no longer loops/restarts for the audited cause. Re-run the strongest repo-local validation available, including proving-scene tests and, if supported truthfully, the highest-fidelity scene run path. Be honest about any live/manual boundary you cannot reproduce. Update this plan with exact commands, findings, and verdict. Close the bead with `bd close aerobeat-input-camera-tracking-3qh8 --reason "QA passed for boxing/flow proving follow-ups" --json` only if it truly passes.

**Folders Created/Deleted/Modified:**
- verification-only as needed

**Files Created/Deleted/Modified:**
- `.plans/2026-07-21-boxing-flow-proving-followups.md`

**Status:** ⏳ Pending

**Results:** Pending.

---

### Task 5: Audit final proving-scene truth and closure readiness

**Bead ID:** `aerobeat-input-camera-tracking-ndr6`  
**SubAgent:** `primary` (for `auditor`)  
**Role:** `auditor`  
**References:** `REF-01`, `REF-02`, `REF-03`, `REF-04`, `REF-05`, `REF-06`, `REF-07`, `REF-08`, `REF-09`  
**Prompt:** In `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking`, claim bead `aerobeat-input-camera-tracking-ndr6` with `bd update aerobeat-input-camera-tracking-ndr6 --status in_progress --json`. Independently audit the final state against Derrick’s report, the earlier overlay-truth diagnosis, and the recent calibration-regression archive. Confirm this work is a truthful fix rather than UI-only suppression, confirm git/commit/push truth, and decide whether the bead closes or needs retry. Update this plan’s Task 5 and Final Results with evidence and verdict, then close the bead with `bd close aerobeat-input-camera-tracking-ndr6 --reason "Audited boxing/flow proving follow-ups" --json` only if it truly passes.

**Folders Created/Deleted/Modified:**
- audit-only as needed

**Files Created/Deleted/Modified:**
- `.plans/2026-07-21-boxing-flow-proving-followups.md`

**Status:** ⏳ Pending

**Results:** Pending.

---

## Final Results

**Status:** ⚠️ Draft

**What We Built:** Pending.

**Reference Check:** Pending.

**Commits:**
- Pending.

**Lessons Learned:** Pending.

---

*Started on 2026-07-21*
