# Prototype Matcher Straight-Only Sanity Test Review

- Date: 2026-06-15
- Filtered library: `assets/prototype_libraries/boxing_side_aware_fixture_derived_v1_straight_only/library.json`
- Benchmark manifest: `.testbed/assets/benchmarks/prototype_matcher_boxing_fixture_derived_v1_straight_only.benchmark.json`
- Benchmark artifact: `docs/baselines/prototype-matcher-boxing-fixture-derived-v1-straight-only-xy-only-2026-06-15/benchmark-results.json`
- Benchmark markdown: `docs/baselines/prototype-matcher-boxing-fixture-derived-v1-straight-only-xy-only-2026-06-15/benchmark-results.md`
- Design note: `docs/reviews/prototype-matcher-straight-only-sanity-test-design-2026-06-15.md`

## Why this exists

This rerun answers Derrick's follow-up question after the first straight-only pass: if MediaPipe pose Z/depth is removed entirely and the prototype feature space is reduced to XY-only shoulder/elbow/wrist features per side, does the straight-only branch become viable without any threshold tuning?

The seam stayed intentionally narrow:

- removed Z/depth from the matcher feature extractor
- regenerated the fixture-derived prototype libraries in the new XY-only feature space
- rebuilt the straight-only filtered library from those regenerated prototypes
- reran the same 3-fixture straight-only benchmark manifest unchanged

## Bottom line

**No. The XY-only straight-only mode is still not viable.**

What improved a little:

- the negative control false positives dropped slightly from **30** to **27**
- hook and uppercut competition remained fully absent because the straight-only library still contains only `straight_left` and `straight_right`

What still failed:

- the straight-left fixture remained split down the middle with **12 expected `punch_left` emits** and **12 wrong `punch_right` emits**
- the straight-right fixture stayed clean, but produced slightly fewer expected emits (**29** vs **31** previously)
- the negative control stayed badly unsafe with **27 false-positive `punch_left` emits** scoring as high as **0.873** at emission time and **0.880** at peak snapshot

Removing depth did not fix the core truth problem: the system still hallucinates straight-left during no-punch motion and still cannot keep straight-left class-clean against straight-right.

## What was isolated

The test seam stayed feature-space-only as planned:

- matcher runtime features changed from 6 values per side to 4 values per side:
  - kept: shoulder-relative elbow/wrist XY normalized by shoulder width
  - removed: elbow/wrist shoulder-relative Z
- regenerated `boxing_side_aware_fixture_derived_v1` in the new XY-only representation
- rebuilt `boxing_side_aware_fixture_derived_v1_straight_only` from that regenerated library
- reran the existing straight-only manifest unchanged
- left matcher thresholds, cooldowns, and hold timing unchanged

Validation that the isolation really happened:

- filtered library classes: `straight_left`, `straight_right`
- filtered library prototype count: **8** total (**4** per straight class)
- regenerated libraries now expose only **4** feature names:
  - `elbow_x_from_shoulder_over_shoulder_width`
  - `elbow_y_from_shoulder_over_shoulder_width`
  - `wrist_x_from_shoulder_over_shoulder_width`
  - `wrist_y_from_shoulder_over_shoulder_width`
- matcher runtime extraction no longer reads or compares pose `z`

## Comparison against the prior straight-only result

Prior non-XY-only straight-only pass (same manifest, previous feature space):

- positive fixtures: **47 expected emits**, **11 wrong emits**
- negative control: **30 false-positive emits**
- straight-left fixture: **16 expected**, **11 wrong**
- straight-right fixture: **31 expected**, **0 wrong**

XY-only rerun:

- positive fixtures: **41 expected emits**, **12 wrong emits**
- negative control: **27 false-positive emits**
- straight-left fixture: **12 expected**, **12 wrong**
- straight-right fixture: **29 expected**, **0 wrong**

Interpretation:

- removing depth helped the negative control only marginally
- straight-left got worse, not better, on expected-hit volume and cross-fire balance
- straight-right remained the one clean lane
- overall viability did **not** improve enough to change the conclusion

## Aggregate readout

Across the two positive fixtures, the XY-only rerun produced:

- **41** expected emits
- **12** wrong emits

Negative control (`run_in_place_negative_control`):

- **27** false-positive emits
- false-positive classes:
  - `straight_left` -> **27**
- false-positive prototypes:
  - `boxing_straight_left_window_03` -> **21**
  - `boxing_straight_left_window_01` -> **4**
  - `boxing_straight_left_window_02` -> **1**
  - `boxing_straight_left_window_04` -> **1**

## Fixture-by-fixture readout

### straight_left_fixture

This fixture is still **not** class-clean under XY-only features.

- expected `punch_left` emits: **12**
- wrong `punch_right` emits: **12**
- strongest expected emit: `boxing_straight_left_window_01` at **0.947**
- strongest wrong emit: `boxing_straight_right_window_01` at **0.838** over left runner-up **0.586** (margin **0.252**)

Interpretation:

- the matcher can still recognize straight-left strongly at times
- but it now cross-fires into `punch_right` just as often as it emits the correct class
- removing depth did not rescue left-vs-right separation

### straight_right_fixture

This fixture remained the clean side of the pair.

- expected `punch_right` emits: **29**
- wrong emits: **0**
- strongest expected emit: `boxing_straight_right_window_01` at **1.000**

Interpretation:

- straight-right still isolates cleanly on this capture
- but the lane is only one-sided; that is not enough to claim straight-only viability overall

### run_in_place_negative_control

This remains the decisive blocker.

- false-positive emits: **27**
- all false positives were `punch_left` / `straight_left`
- dominant culprit: `boxing_straight_left_window_03` with **21** emits
- strongest false positive emit: `boxing_straight_left_window_01` at **0.873** over straight-right runner-up **0.557** (margin **0.316**)
- peak snapshot winner: `straight_left` at **0.880** over `straight_right` **0.577** (margin **0.303**)

Interpretation:

- the no-punch rejection path is still not truthful in this XY-only slice
- the system is still confidently hallucinating straight-left during running-in-place motion
- because the negative control remains unsafe, the current straight-only mode cannot be treated as viable

## Answer to the primary question

**After removing depth and using XY-only shoulder/elbow/wrist features, can the current prototype system distinguish straight-left and straight-right from no-punch accurately enough to count as viable?**

**No.**

Depth removal did not solve the core failures. Straight-right remains clean, but straight-left still flips into straight-right frequently and the no-punch negative control still produces 27 confident straight-left false positives. That is not accurate enough to count as a viable straight-only prototype mode.

## Recommended interpretation for the next seam

Treat this rerun as evidence that MediaPipe pose Z was not the main blocker by itself.

If work continues, the next branch should assume the remaining problem is in the straight prototype family itself — prototype selection, temporal representation, or threshold/gating strategy around straight-left in particular — rather than in depth usage alone.
