# Prototype Matcher Straight-Only Sanity Test Review

- Date: 2026-06-15
- Filtered library: `assets/prototype_libraries/boxing_side_aware_fixture_derived_v1_straight_only/library.json`
- Benchmark manifest: `.testbed/assets/benchmarks/prototype_matcher_boxing_fixture_derived_v1_straight_only.benchmark.json`
- Benchmark artifact: `docs/baselines/prototype-matcher-boxing-fixture-derived-v1-straight-only-2026-06-15/benchmark-results.json`
- Benchmark markdown: `docs/baselines/prototype-matcher-boxing-fixture-derived-v1-straight-only-2026-06-15/benchmark-results.md`
- Design note: `docs/reviews/prototype-matcher-straight-only-sanity-test-design-2026-06-15.md`

## Why this exists

This is the narrow sanity-test run requested after the hook-left investigation. The goal is not to tune the matcher. The goal is to ask a smaller truth question: if hook and uppercut prototypes are removed entirely, can the current straight prototypes separate `straight_left` and `straight_right` from the existing no-punch rejection path well enough to look viable?

## Bottom line

**No. The straight-only mode is not viable in its current form.**

What improved:

- hook and uppercut competition really was removed
- the straight-right fixture stayed class-clean on this pass

What failed:

- the straight-left fixture still cross-fired into **`punch_right` 11 times**
- the negative control remained completely dirty with **30 false-positive `punch_left` emits**
- those false positives were not near-threshold edge flickers; they climbed as high as **0.885** with class margins up to **0.456**

That means disabling hook/uppercut classes does **not** rescue the current prototype system enough to count as a viable straight-only lane.

## What was isolated

The test seam stayed data-only as designed:

- created a filtered library containing only `straight_left` and `straight_right`
- preserved the committed straight prototypes exactly as-is
- ran a 3-fixture manifest: straight-left, straight-right, and run-in-place negative control
- left matcher logic, thresholds, cooldowns, and hold timing unchanged

Validation that the isolation really happened:

- filtered library classes: `straight_left`, `straight_right`
- filtered library prototype count: **8** total (**4** per straight class)
- benchmark telemetry showed disabled classes staying at **0.0** throughout fixture summaries

## Aggregate readout

Across the two positive fixtures, the straight-only rerun produced:

- **47** expected emits
- **11** wrong emits

Negative control (`run_in_place_negative_control`):

- **30** false-positive emits
- false-positive classes:
  - `straight_left` -> **30**
- false-positive prototypes:
  - `boxing_straight_left_window_03` -> **22**
  - `boxing_straight_left_window_01` -> **3**
  - `boxing_straight_left_window_04` -> **3**
  - `boxing_straight_left_window_02` -> **2**

## Fixture-by-fixture readout

### straight_left_fixture

This fixture was **not** class-clean even after removing hook and uppercut prototypes.

- expected `punch_left` emits: **16**
- wrong `punch_right` emits: **11**
- strongest expected emit: `boxing_straight_left_window_04` at **1.000**
- strongest wrong emit: `boxing_straight_right_window_01` at **0.819** over left runner-up **0.718** (margin **0.101**)

Interpretation:

- the matcher can still recognize straight-left strongly at times
- but it also flips into the opposite straight class often enough that the lane is not trustworthy
- removing hook/uppercut competition did not solve the left-vs-right ambiguity for this fixture

### straight_right_fixture

This fixture was the one bright spot.

- expected `punch_right` emits: **31**
- wrong emits: **0**
- strongest expected emit: `boxing_straight_right_window_01` at **1.000**

Interpretation:

- straight-right can be recognized cleanly in isolation on this capture
- but that success is one-sided; it does not offset the failures on straight-left and no-punch

### run_in_place_negative_control

This is the decisive failure.

- false-positive emits: **30**
- all false positives were `punch_left` / `straight_left`
- dominant culprit: `boxing_straight_left_window_03` with **22** emits
- strongest false positive: `boxing_straight_left_window_01` at **0.885** over straight-right runner-up **0.645** (margin **0.240**)

Interpretation:

- the no-punch rejection path is still not truthful in this straight-only slice
- the system is not merely confused between straight-left and straight-right; it is also confidently hallucinating straight-left while the subject is only running in place
- because the negative control remains fully unsafe, the current straight-only mode cannot be treated as deployable or even “good enough for deeper tuning later” without a more explicit caveat

## Answer to the primary question

**With hook and uppercut prototype classes disabled, can the current prototype system distinguish straight-left and straight-right from no-punch accurately enough to count as viable?**

**No.**

The test shows that hook/uppercut competition was not the main blocker. Straight-right isolates cleanly, but straight-left still misclassifies as straight-right on its own positive fixture, and the no-punch negative control still produces 30 confident straight-left false positives. That is not accurate enough to count as a viable straight-only prototype mode.

## Recommended interpretation for the next seam

Treat this run as evidence against the optimistic branch “straights become basically fine once hook/uppercut classes are removed.”

If work continues, the next investigation should assume the remaining problem is inside the straight prototypes / straight thresholds / temporal gating themselves, especially the straight-left family, rather than primarily class competition from hook and uppercut prototypes.
