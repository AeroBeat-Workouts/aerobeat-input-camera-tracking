# Task 17 Camera-Tracking Contract Packet

Date: 2026-07-24
Repo: `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking`
Scope: Research/design only. No runtime implementation landed here.

## Summary

This packet translates Derrick’s latest playtest notes into a narrow implementation contract for the next camera-tracking slice.

Core conclusions:
- The missing flow-scene inspector element should be a **nose-direction chart** placed in the existing sixth `BoardGrid` slot beside the current nose/left/right placement and left/right direction cards.
- Manual calibration should be replaced by **automatic T-pose-triggered calibration** driven by a new commented `calibration:` block in the active gesture-profile YAML surface, not the tracker/tool YAML surface.
- Weave truth should become a **continuous inside-grid side state** based on the current nose cell’s athlete-space half, not a looser obstacle-avoidance interpretation.
- Hook/uppercut should gain a YAML-swappable **`grid_detection` backend** that consumes the existing flow wrist-history + cell-entry seam while reusing the current punch-family timing/rearm state machine where it still fits.
- Upstream pose tracking cannot safely be reduced to only wrists/elbows/shoulders/nose yet without breaking current runtime assumptions, and even if filtered locally it would not produce meaningful inference-cost savings with the current provider/tool boundary.

---

## 1) Nose-direction inspector contract

### Current repo truth
- `flow_proving.tscn` defines a 3-column `BoardGrid` with only 5 cards populated:
  - `NosePlacementCard`
  - `LeftPlacementCard`
  - `RightPlacementCard`
  - `LeftDirectionCard`
  - `RightDirectionCard`
- This leaves one empty visual slot.
- `proving_harness.gd` already publishes `flow.gesture_debug.tracked_landmarks.nose.current_direction`, but the UI only renders nose placement, not nose direction.

### Contract
- Add a new `NoseDirectionCard` + `NoseDirectionChart` in the empty sixth slot of `flow_proving.tscn`.
- Reuse `FlowRingChart` in `DIRECTION_COMPASS` mode.
- Title: `Nose Direction`.
- Source of truth: `gesture_debug.flow.tracked_landmarks.nose.current_direction`.
- Behavior parity with left/right wrist direction charts:
  - `-1` means no active direction highlight.
  - Uses the same direction index contract already exposed by `_flow_direction_index_from_vector()`.
- No new popup/hover inspector contract is required for this slice; the missing requirement is satisfied by the board element itself.

### Narrowest implementation seam
- `.testbed/scenes/flow_proving.tscn`
- `.testbed/scripts/proving_harness.gd`
- No detector/runtime behavior changes required for this sub-slice.

---

## 2) Automatic T-pose-triggered calibration contract

## Ownership and YAML placement

### Recommended owner
Place the new config under the **gesture/gameplay config layer** in:
- `assets/boxing.gesture_detection.yaml`
- `assets/flow.gesture_detection.yaml`

### Why not `*.camera_tracking.yaml`
- Tracker config is explicitly owned by the tool repo per `docs/cross-repo-config-contract.md`.
- T-pose calibration is not vendor tracker behavior; it is input-repo runtime/gameplay meaning built in `pose_detector_substrate.gd`.
- Putting it in `*.camera_tracking.yaml` would create cross-repo ownership drift.

### Commenting-convention fit
Use the same short inline comments already present in the profile YAMLs: plain-language purpose statements, then ownership hints like `input.` or `input/runtime.`. Keep comments on the config block itself, not in code-only docs.

### Proposed YAML shape
Use snake_case to match existing backend/config naming conventions (`grid_avoidance`, `state_machine`, etc.).

```yaml
calibration:
  # Auto-capture the shared athlete baseline from a held T-pose. input/runtime.
  mode: t_pose_auto
  t_pose:
    # Fire calibration immediately when this continuous hold duration is satisfied. input/runtime.
    hold_ms: 750
    thresholds:
      # Require both arms to stay roughly horizontal relative to the shoulders. input/runtime.
      max_wrist_shoulder_y_ratio: 0.18
      max_elbow_shoulder_y_ratio: 0.18
      # Require genuinely extended arms, not just wide hands. input/runtime.
      min_arm_extension_ratio: 0.92
      min_elbow_angle_deg: 160.0
```

If Derrick wants a single authoritative profile file instead of mirrored blocks, the narrowest fallback is: keep the block in both profile gesture YAMLs with the same values for now. That avoids hidden profile asymmetry.

## Runtime behavior contract

### Replace the old manual flow
- The proving scenes should no longer depend on pressing `AthleteRecalibrateButton` to begin the baseline flow.
- Runtime continuously evaluates T-pose readiness whenever tracking is `tracking` or `reacquiring`.
- There is **no countdown** and **no extra post-hold delay**.
- Calibration fires on the exact frame where the monotonic hold duration first reaches `hold_ms`.

### Required landmarks
Calibration readiness requires visible:
- nose
- left/right shoulders
- left/right elbows
- left/right wrists

### T-pose qualification rules
A frame is T-pose-qualified only if **all** of the following are true:
1. Tracking state is `tracking` or `reacquiring`.
2. Required landmarks are visible above the existing visibility gate.
3. Both arms are horizontally-enough aligned:
   - `abs(left_wrist.y - left_shoulder.y) / shoulder_width <= max_wrist_shoulder_y_ratio`
   - `abs(right_wrist.y - right_shoulder.y) / shoulder_width <= max_wrist_shoulder_y_ratio`
   - `abs(left_elbow.y - left_shoulder.y) / shoulder_width <= max_elbow_shoulder_y_ratio`
   - `abs(right_elbow.y - right_shoulder.y) / shoulder_width <= max_elbow_shoulder_y_ratio`
4. Both arms are extended enough:
   - `left_arm_extension >= min_arm_extension_ratio`
   - `right_arm_extension >= min_arm_extension_ratio`
   - `left_elbow_bend_deg >= min_elbow_angle_deg`
   - `right_elbow_bend_deg >= min_elbow_angle_deg`

Using both extension ratio and elbow angle matches Derrick’s explicit clarification that horizontal-enough alignment alone is not enough.

### Hold + re-fire rules
- Hold time is measured using the existing monotonic runtime timestamp seam, not raw source timestamps.
- While the frame remains T-pose-qualified, accumulate continuous hold time.
- If qualification breaks, reset the hold timer.
- When `hold_ms` is satisfied, calibration fires immediately and consumes that continuous hold epoch.
- Calibration may fire again later, but only after qualification breaks and a **new** qualifying hold reaches `hold_ms`.
- Do **not** repeatedly re-fire every frame while the same unbroken T-pose continues.

This is the narrowest interpretation that matches “re-fire any time the T-pose hold requirement is met after fulfilling the requirements” without creating frame-by-frame spam.

### Baseline capture semantics
When the trigger fires, reuse the existing baseline capture truth:
- grid width from wrist-span X distance
- square-cell height from stored aspect math
- anchor from `nose_x` and `left_shoulder_y`
- same shared baseline object used by boxing + flow

### UI contract after the change
The calibration panel should become a **status/instructions panel**, not a start button flow.
Recommended panel behavior:
- Primary text describes auto-calibration state (`Waiting for T-pose`, `Holding…`, `Calibrated`, `Tracking lost`, etc.).
- Optional secondary dev affordance may remain only if explicitly desired:
  - either remove manual buttons entirely
  - or keep a narrow `Clear Baseline` / `Reset` utility for debugging
- If coder keeps any manual dev-only affordance, it should not be the primary user flow and should not contradict the automatic contract.

## Narrowest runtime seam
Primary runtime owner:
- `src/detectors/pose_detector_substrate.gd`

Likely UI seam:
- `.testbed/scripts/proving_harness.gd`
- `.testbed/scenes/boxing_proving.tscn`
- `.testbed/scenes/flow_proving.tscn`

Probably no required public API seam:
- `src/providers/camera_tracking_provider.gd`
- `src/AeroCameraTracking.gd`

These wrappers can stay source-compatible unless the coder decides to explicitly retire unused manual-start/cancel plumbing.

---

## 3) Weave truth contract

### Current repo truth
Current weave uses `grid_avoidance` with two obstacle definitions and toggles `weave_left` / `weave_right` based on `avoidance_clear`.

### Required contract change
While the nose remains inside the calibrated 4x3 grid:
- athlete-space columns `0` or `1` imply `weave_left = true`, `weave_right = false`
- athlete-space columns `2` or `3` imply `weave_right = true`, `weave_left = false`
- there is no neutral inside-grid state

When the nose leaves the grid or required tracking drops out:
- `weave_left = false`
- `weave_right = false`

### Event semantics
- Entering the left half emits `weave_left_enabled` and ends `weave_right` if needed.
- Entering the right half emits `weave_right_enabled` and ends `weave_left` if needed.
- Exiting the grid ends whichever weave state is active.
- Remaining in the same half does not retrigger start spam.

### Config consequence
Keep the `weave` family YAML-controlled, but restate its meaning from “obstacle avoidance” to “inside-grid side occupancy.”

Narrowest path:
- keep `backend: grid_avoidance` for weave if Derrick wants the public YAML name preserved
- reinterpret the left/right obstacle defaults to map cleanly to athlete-left vs athlete-right halves

Cleaner but slightly wider path:
- introduce an explicit `grid_side_state` backend for weave

Recommendation: **do not widen the public backend surface for weave in this slice**. Just make `grid_avoidance` truthful to the approved side-state contract.

---

## 4) Boxing hook/uppercut `grid_detection` backend contract

## Public contract
Each punch family keeps per-family backend selection:
- `disabled`
- `threshold`
- `grid_detection`

Recommendation: store the backend string as `grid_detection` in YAML/code to match existing snake_case backend ids. If Derrick wants the prose label “grid-detection,” loader normalization can alias the hyphenated spelling, but the narrowest code path is snake_case.

## Proposed YAML shape
```yaml
hook:
  backend: grid_detection
  grid_detection:
    evaluation:
      window_ms: 250
      min_cell_delta: 1
      direction_dominance_ratio: 0.55
    timing:
      triggered_grace_ms: 500
    rearm:
      pose_only_rearm_ms: 50
    state_machine:
      lost_tracking_reacquire_stable_ms: 40

uppercut:
  backend: grid_detection
  grid_detection:
    evaluation:
      window_ms: 250
      min_cell_delta: 1
      direction_dominance_ratio: 0.55
    timing:
      triggered_grace_ms: 500
    rearm:
      pose_only_rearm_ms: 50
    state_machine:
      lost_tracking_reacquire_stable_ms: 40
```

## Detection rules
Build this backend on top of the existing flow wrist-history/cell-entry seam already owned by `pose_detector_substrate.gd`.

### Shared prerequisites
A candidate strike only evaluates when:
- baseline/grid is calibrated
- same-side wrist tracking is valid
- current sample has a new cell entry (not same-cell dwell)
- motion analysis for that wrist over `window_ms` yields a usable direction vector

### Hook rules
- Trigger source: same-side wrist enters a new cell with an **outward horizontal** athlete-space transition.
- Left hook:
  - driven by left wrist
  - qualifying cell motion moves toward athlete-left (toward lower athlete-space column index)
- Right hook:
  - driven by right wrist
  - qualifying cell motion moves toward athlete-right (toward higher athlete-space column index)
- Horizontal magnitude must dominate vertical magnitude by at least `direction_dominance_ratio`.
- `min_cell_delta` counts the absolute athlete-space column change between the previous cell and the entered cell.

### Uppercut rules
- Trigger source: same-side wrist enters a new cell with an **upward vertical** athlete-space transition.
- Left/right uppercut both require the same athlete-space row rule, just with the matching wrist.
- Qualifying cell motion moves upward (toward lower athlete-space row index because row `0` is the top row in the public contract).
- Vertical magnitude must dominate horizontal magnitude by at least `direction_dominance_ratio`.
- `min_cell_delta` counts the absolute athlete-space row change between the previous cell and the entered cell.

## State-machine reuse
Reuse the current pose-strike timing/rearm shell where it still fits:
- `triggered_grace_ms`
- `pose_only_rearm_ms`
- `lost_tracking_reacquire_stable_ms`

Do **not** force old elbow-angle threshold semantics into the new backend. Those belong to the current threshold backend. The new backend should use cell-entry direction truth first.

## Recommended detector structure
- Keep the current threshold backend untouched.
- Add a parallel `grid_detection` path for hook/uppercut only.
- Centralize shared hook/uppercut state-machine logic so both threshold and grid backends can reuse the same armed/triggered/rearm transitions.

## Likely runtime seams
- `src/detectors/pose_detector_substrate.gd`
- `src/config/profile_config_loader.gd` (sanitization must allow `grid_detection` for hook/uppercut)
- `assets/boxing.gesture_detection.yaml`
- `.testbed/tests/unit/test_pose_detector_substrate.gd`

---

## 5) Reduced-anchor pose tracking investigation

## Current repo truth
A true upstream reduction to only `wrists/elbows/shoulders/nose` is **not safe today**.

### Why it is not safe yet
Current runtime assumptions still depend on lower-body/torso landmarks:
- tracking validity uses `TRACKING_KEY_LANDMARKS = nose + shoulders + hips + wrists`
- baseline/measurement math still reads hips, knees, and ankles
- `height_state`, `athlete_height`, `torso_height`, foot confidences, and foot directions still exist in the published state/debug model
- public APIs and tests still expose ankle-based positions/confidences and lower-body metrics
- many unit tests build full-body frames and assert lower-body-derived measurements

### Compute-savings reality check
Even if this repo filtered down to the seven gameplay anchors after inference, that would only reduce downstream bookkeeping a bit. It would **not** materially reduce pose inference cost unless the tool/vendor layer can request or compute fewer landmarks, which is not part of the current approved contract.

## Recommendation
For the next coder slice:
- **Do not** attempt upstream landmark-count reduction as part of the main implementation seam.
- If desired, take only the narrow safe cleanup step: introduce an internal “gameplay anchor subset” helper for the new T-pose and grid-detection code paths while still ingesting the full provider landmark set.
- Treat real compute optimization as a separate future investigation requiring tool/provider contract work.

## Safe conclusion
- **Approved for this slice:** use only the relevant anchors in the new logic paths.
- **Not approved for this slice:** changing provider/runtime assumptions so the system no longer depends on hips/knees/ankles globally.

---

## Exact files likely affected in the next coder slice

### Config / contract
- `assets/boxing.gesture_detection.yaml`
- `assets/flow.gesture_detection.yaml`
- `docs/cross-repo-config-contract.md`

### Runtime / detector
- `src/detectors/pose_detector_substrate.gd`
- `src/config/profile_config_loader.gd`
- `src/detectors/pose_landmark_ids.gd` (only if the coder touches key-landmark grouping helpers; not required for the narrowest path)

### Provider / wrapper compatibility
- `src/providers/camera_tracking_provider.gd` (likely no-op or minimal, if any)
- `src/AeroCameraTracking.gd` (likely no-op or minimal, if any)

### Testbed UI
- `.testbed/scenes/flow_proving.tscn`
- `.testbed/scenes/boxing_proving.tscn`
- `.testbed/scripts/proving_harness.gd`
- `.testbed/scripts/flow_ring_chart.gd` (probably unchanged unless title/subtitle polish is needed)

### Tests
- `.testbed/tests/unit/test_pose_detector_substrate.gd`
- `.testbed/tests/unit/test_boxing_proving_harness_profiles_and_debug.gd`

---

## Hidden coupling / risks

1. **Calibration copy drift across profiles**
   - If `calibration:` lands in only one gesture YAML, boxing vs flow can silently diverge.
   - Recommendation: mirror the block in both profile gesture YAMLs unless Derrick explicitly wants asymmetry.

2. **Shared calibration API naming should stay generic**
   - The runtime/provider wrappers now expose `start_calibration()`, `cancel_calibration()`, `get_calibration_session()`, and `calibration_session_updated(session)`.
   - Keep the shared lane generic rather than re-introducing athlete-specific verbs.
   - Recommendation: future calibration UI work should continue using this shared naming.

3. **Weave backend naming vs meaning drift**
   - Keeping `grid_avoidance` while changing meaning to continuous side occupancy is slightly conceptually awkward.
   - Recommendation: accept the name mismatch for the narrow slice rather than widening public config surface.

4. **Grid-detection orientation bugs**
   - Hook/uppercut based on cell-entry deltas can be confused by preview-space vs athlete-space orientation.
   - Recommendation: define all new strike rules in athlete-space cell coordinates, not preview X/Y labels.

5. **T-pose refire spam risk**
   - If coder interprets “re-fire any time the hold requirement is met” literally per-frame, calibration could thrash.
   - Recommendation: require hold-break-then-rehold before the next fire.

6. **Reduced-anchor optimization may promise more than it delivers**
   - Filtering after inference does not equal inference compute savings.
   - Recommendation: keep optimization claims narrow and truthful.

---

## Recommended execution order

1. **Config + detector contract first**
   - add `calibration:` config parsing
   - allow `grid_detection` backend normalization for hook/uppercut
   - implement T-pose auto-calibration state machine in the detector

2. **Weave truth update second**
   - switch weave side truth to direct inside-grid half occupancy
   - keep existing event surface names

3. **Hook/uppercut grid-detection backend third**
   - add backend routing + config parsing
   - reuse existing state-machine timing shell
   - keep threshold backend intact for fallback comparison

4. **Flow proving UI fourth**
   - add nose-direction card
   - convert calibration panel copy from manual-start UX to automatic-status UX

5. **Validation last**
   - detector unit coverage for T-pose hold/refire, weave side truth, and grid-detection strikes
   - harness/UI tests for the new nose-direction card and auto-calibration copy

---

## Exact next slices I recommend

### Next coder slice
Implement only the approved narrow contract above:
- add commented `calibration:` block(s) in gesture YAML
- add T-pose auto-calibration in `pose_detector_substrate.gd`
- restate weave to continuous inside-grid left/right truth
- add hook/uppercut `grid_detection` backend support without removing threshold backend
- add the missing flow-scene `NoseDirectionChart`
- update proving calibration panel wording from manual-start flow to auto-status flow
- keep reduced-anchor work limited to helper-level local reuse, not provider/runtime contract shrinkage

### Next QA slice
Verify:
- nose direction chart highlights the same direction index the detector publishes
- T-pose must satisfy both horizontal alignment and arm extension gates
- calibration fires immediately at hold completion, not after extra delay
- calibration can fire again after the T-pose is broken and re-held
- weave remains left/right continuously while the nose stays inside the grid and drops out only on grid exit/tracking loss
- hook/uppercut `grid_detection` events respect athlete-space direction and do not regress threshold-backend behavior when switched back

### Next auditor slice
Truth-check:
- YAML ownership stayed in input-repo gesture config, not tool-owned tracker config
- no hidden public contract drift beyond the approved `calibration:` and `grid_detection` additions
- no false compute-savings claims from the reduced-anchor investigation
- boxing/flow profile parity is explicit and intentional
- tests actually cover refire semantics, athlete-space orientation, and UI status truth

---

## Files inspected for this packet

- `/home/derrick/.openclaw/workspace/projects/aerobeat/.plans/2026-07-22-aerobeat-camera-tracking-and-beatsaver-feedback-wave.md`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/assets/boxing.gesture_detection.yaml`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/assets/flow.gesture_detection.yaml`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/assets/boxing.camera_tracking.yaml`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/assets/flow.camera_tracking.yaml`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/docs/cross-repo-config-contract.md`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/src/config/profile_config_loader.gd`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/src/config/camera_tracking_config.gd`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/src/detectors/pose_landmark_ids.gd`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/src/detectors/pose_detector_substrate.gd`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/src/providers/camera_tracking_provider.gd`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/src/AeroCameraTracking.gd`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.testbed/scenes/flow_proving.tscn`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.testbed/scenes/boxing_proving.tscn`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.testbed/scripts/proving_harness.gd`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.testbed/scripts/flow_ring_chart.gd`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.testbed/tests/unit/test_pose_detector_substrate.gd`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.testbed/tests/unit/test_boxing_proving_harness_profiles_and_debug.gd`
