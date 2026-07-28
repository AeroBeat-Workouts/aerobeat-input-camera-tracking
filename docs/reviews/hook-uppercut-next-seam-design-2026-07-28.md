# Hook / Uppercut Next Seam Design — 2026-07-28

## Scope

Design the next **narrow** boxing hook/uppercut detector improvement seam in `aerobeat-input-camera-tracking` before gameplay-repo work begins.

This is design only. No gameplay-repo work and no detector implementation landed here.

## Latest validated boxing state

Current lane truth from the active coordination plan:
- Flow is in a good spot; only small YAML iteration remains.
- Boxing `straight_punch`, `guard`, `squat`, and `weave` are in a good spot.
- Boxing gameplay is now frozen around **beat-local event acceptance**, not detector exclusivity. If the expected boxing gesture event happens inside the beat window, gameplay should accept it and ignore other same-punch co-events.
- Hook and uppercut already use the `grid_detection` backend by default in `assets/boxing.gesture_detection.yaml`.
- The current default boxing tuning is:
  - `hook.grid_detection.evaluation.grid_variant: strike_subgrid`
  - `hook.grid_detection.evaluation.min_column_delta: 2`
  - `hook.grid_detection.evaluation.overflow_protection_enabled: true`
  - `uppercut.grid_detection.evaluation.grid_variant: strike_subgrid`
  - `uppercut.grid_detection.evaluation.min_row_delta: 2`
  - `uppercut.grid_detection.evaluation.overflow_protection_enabled: true`
- The current runtime already preserves:
  - triggered grace / rearm / tracking-loss shell
  - buffered repeat-transition handling
  - optional overflow protection while active
  - truthful debug surfaces for grid progress

## Current runtime truth

The remaining weak spot is the **pre-trigger progress model** in `src/detectors/pose_detector_substrate.gd`.

`_update_pose_strike_grid_progress(...)` currently:
1. keeps a recent history of strike-subgrid transitions inside `window_ms`
2. appends new transitions when they differ from the last history key
3. computes `grid_accumulated_progress` by summing only positive in-family deltas across the entire in-window history

That means:
- hook counts every positive side-correct column advance in the current window
- uppercut counts every upward row advance in the current window
- orthogonal motion is ignored, which is good
- **but reversal / rebound / oscillation does not clear the earlier credit**

So a sequence like:
- left hook: `+1`, then `-1`, then `+1`
- uppercut: `up 1`, then `down 1`, then `up 1`

still leaves accumulated progress from both positive bursts if they all remain inside `window_ms`.

That is visible in the current unit-test truth: `test_hook_grid_detection_does_not_fire_when_signed_progress_stays_below_threshold()` proves the detector can still report `grid_accumulated_progress == 2` after a three-transition reversal sequence; it only avoids firing there because the test threshold is `3`, not because reversal reset the run.

## Why this is the next best seam

Because gameplay no longer depends on perfect detector exclusivity, the next detector improvement should optimize for:
- better live feel
- fewer hook/uppercut false fires from jitter or rebound
- preserving organic curved punches
- minimal risk to the already-good state machine shell

A pure YAML retune is too blunt for this seam:
- raising `min_column_delta` / `min_row_delta` further will reduce responsiveness
- lowering `window_ms` further may hurt slower real punches
- toggling overflow protection only affects the **active** protected window, not this **pre-trigger accumulation** weakness

So the next narrow seam should target the actual remaining logic issue: **credit survives family-axis reversal before trigger**.

## Options compared

### Option A — YAML-only retune

Examples:
- raise `min_column_delta` / `min_row_delta`
- shrink `window_ms`
- tune overflow defaults again

Pros:
- tiny implementation surface

Cons:
- does not fix reversal double-counting
- likely trades away responsiveness to get less noise
- pushes hook and uppercut feel around without addressing the real logic flaw

Verdict: not the next best slice.

### Option B — net displacement only (oldest cell to newest cell)

Compute progress only as net in-family displacement from oldest kept transition/sample to newest.

Pros:
- naturally cancels reversal
- simple to explain

Cons:
- too harsh for real curved punches that drift orthogonally and briefly settle
- risks undercounting a punch that made the needed move but had a small late settle before evaluation
- less aligned with Derrick’s already-approved desire to keep orthogonal motion from invalidating a candidate

Verdict: cleaner than current behavior, but probably too lossy for organic punches.

### Option C — directional run / excursion anchor inside the window **(chosen)**

Keep the current windowed strike-subgrid architecture, but only score the **current monotonic in-family run** instead of summing all positive bursts inside the window.

Pros:
- preserves curved punches with orthogonal drift
- drops stale credit after family-axis reversal
- keeps current YAML and state-machine shell intact
- easy to debug live: “what is the current active hook/uppercut run, and how far has it gone?”
- minimal code surface compared with a broader rewrite

Cons:
- slightly more state/debug plumbing than raw accumulation
- may still need later YAML retune after live playtest

Verdict: best next narrow seam.

## Frozen design for the next implementation slice

### Behavioral contract

Replace the current pre-trigger hook/uppercut grid-progress scoring with **directional-run excursion scoring**:

- Keep using the configured `grid_variant`, `window_ms`, and `min_column_delta` / `min_row_delta`.
- Keep ignoring orthogonal travel for trigger credit.
- Keep existing grace / rearm / buffered-repeat / same-family blocking / tracking-loss behavior unchanged.
- Keep `overflow_protection_enabled` semantics unchanged.

#### Hook

For hook `grid_detection`:
- left hook only cares about athlete-space positive column travel
- right hook only cares about athlete-space negative column travel
- score only the **currently active horizontal hook-direction run** inside the active window
- any opposite horizontal motion in the family axis resets the run anchor instead of preserving earlier hook credit
- row-only drift does not reset the run and does not add credit

#### Uppercut

For uppercut `grid_detection`:
- only upward athlete-space row travel contributes
- score only the **currently active upward run** inside the active window
- any downward row motion resets the run anchor instead of preserving earlier upward credit
- column-only drift does not reset the run and does not add credit

### Practical scoring model

The easiest honest implementation is to derive progress from a run anchor rather than from a sum of all positive bursts:

- maintain recent transition history as today
- scan the kept in-window transitions in order
- track the current run anchor after the most recent family-axis reversal
- compute progress from that anchor to the furthest valid same-direction excursion in the active run

That means the detector still tolerates:
- curved punches
- diagonal/orthogonal drift
- multi-step same-direction travel across several strike subcells

But it stops counting:
- `+1, -1, +1` as equivalent to one clean `+2` hook run
- `up 1, down 1, up 1` as equivalent to one clean `up 2` uppercut run

## Debug / inspector truth to expose

Do not hide the new logic behind the old names alone.

Keep existing debug fields for compatibility, but add or repurpose truthful fields so the live inspector can explain the new scoring:
- `grid_accumulated_progress` may remain as the surfaced progress field if renamed semantics are documented honestly
- add explicit run-truth fields such as:
  - `grid_progress_mode: directional_run_excursion`
  - `grid_run_transition_count`
  - `grid_run_anchor_cell`
  - `grid_run_anchor_column` / `grid_run_anchor_row`
  - `grid_run_reset_reason` (empty / reversal / expired / tracking_lost)

If naming churn is undesirable, at minimum the comments/tests/debug text must clearly state that the surfaced progress is now **current run excursion**, not raw cumulative positive sum.

## Minimum implementation slice worth assigning

### Narrow coder slice

Modify only the hook/uppercut `grid_detection` pre-trigger progress path in `aerobeat-input-camera-tracking`:
- update `_update_pose_strike_grid_progress(...)` and directly coupled helper logic in `src/detectors/pose_detector_substrate.gd`
- preserve current YAML shape; do **not** add a new config variable for the first pass
- preserve current grace/rearm/buffering/overflow behavior
- update directly coupled debug state/comments only as needed for truthful inspector output
- add targeted unit coverage only for the new scoring truth

### Required tests

1. **Hook reversal does not preserve stale credit**
   - a `+1, -1, +1` style left-hook sequence inside `window_ms` must not satisfy a `min_column_delta: 2` trigger unless the active run itself reaches `2`
2. **Uppercut reversal does not preserve stale credit**
   - an `up 1, down 1, up 1` sequence inside `window_ms` must not satisfy `min_row_delta: 2` unless the active upward run itself reaches `2`
3. **Curved hook still passes**
   - a same-direction hook with row drift still fires when horizontal excursion reaches threshold
4. **Curved uppercut still passes**
   - an upward uppercut with column drift still fires when upward excursion reaches threshold
5. **Buffered repeat behavior still works**
   - existing fast-repeat coverage must remain green under the new pre-trigger scoring model
6. **Overflow-protection behavior still works**
   - existing protected-window freeze coverage must remain green

## Why this seam is safely narrow

It does **not**:
- widen into gameplay-repo work
- try to solve detector exclusivity
- change straight punch / guard / squat / weave
- rewrite calibration or grid architecture
- add a new public YAML contract unless playtest proves it necessary later

It only changes how hook/uppercut decide whether the current recent motion constitutes one qualifying directional run before trigger.

## Follow-up if this lands but still needs tuning

Only after this logic seam lands and Derrick manually retests should we consider a second pass such as:
- per-family YAML retune (`min_column_delta`, `min_row_delta`, `window_ms`)
- asymmetric hook vs uppercut defaults
- optional explicit anti-jitter guardrails if live testing still proves necessary

That keeps the first next slice honest: **fix the reversal-credit flaw first, then retune only if needed**.
