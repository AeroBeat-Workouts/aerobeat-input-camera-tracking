# Prototype Matcher Straight-Only Sanity Test Review

- Date: 2026-06-15
- Filtered library: `assets/prototype_libraries/boxing_side_aware_fixture_derived_v1_straight_only/library.json`
- Benchmark manifest: `.testbed/assets/benchmarks/prototype_matcher_boxing_fixture_derived_v1_straight_only.benchmark.json`
- Benchmark artifact: `docs/baselines/prototype-matcher-boxing-fixture-derived-v1-straight-only-raw-xy-2026-06-15/benchmark-results.json`
- Benchmark markdown: `docs/baselines/prototype-matcher-boxing-fixture-derived-v1-straight-only-raw-xy-2026-06-15/benchmark-results.md`
- Design note: `docs/reviews/prototype-matcher-straight-only-sanity-test-design-2026-06-15.md`

## Why this exists

This rerun answers Derrick's follow-up question after the prior straight-only and XY-only passes: if each side uses raw XY shoulder/elbow/wrist pose features directly, with Z/depth excluded entirely, does the straight-only branch become viable without any threshold tuning?

The seam stayed intentionally narrow:

- changed the prototype feature representation to raw per-side shoulder/elbow/wrist XY
- excluded pose Z/depth from the regenerated straight-only experiment
- regenerated the fixture-derived prototype libraries in the new raw-XY feature space
- rebuilt the straight-only filtered library from those regenerated prototypes
- reran the same 3-fixture straight-only benchmark manifest unchanged

## Bottom line

**No. The raw-XY straight-only mode is not viable.**

This branch got worse than the prior XY-only rerun and worse than the original straight-only pass:

- the positive fixtures collapsed to **36 expected emits** and **29 wrong emits**
- `straight_left_fixture` stayed bad with **12 expected `punch_left` emits** and **17 wrong `punch_right` emits**
- `straight_right_fixture` also lost class cleanliness, now producing **24 expected `punch_right` emits** and **12 wrong `punch_left` emits**
- the no-punch negative control remained unsafe with **29 false-positive emits**: **28 `punch_left`** and **1 `punch_right`**

So raw XY shoulder/elbow/wrist did not rescue left/right-vs-no-punch discrimination. It broadened overlap enough that even the previously clean straight-right lane started cross-firing.

## What was isolated

The test seam stayed feature-space-only as planned:

- matcher/runtime feature extraction now follows library-declared feature names and the regenerated libraries declare raw XY features only
- regenerated `boxing_side_aware_fixture_derived_v1` in the raw-XY representation
- rebuilt `boxing_side_aware_fixture_derived_v1_straight_only` from that regenerated library
- reran the existing straight-only manifest unchanged
- left matcher thresholds, cooldowns, and hold timing unchanged

Validation that the isolation really happened:

- filtered library classes: `straight_left`, `straight_right`
- filtered library prototype count: **8** total (**4** per straight class)
- regenerated libraries now expose **6** feature names per side sample:
  - `shoulder_x`
  - `shoulder_y`
  - `elbow_x`
  - `elbow_y`
  - `wrist_x`
  - `wrist_y`
- the regenerated raw-XY libraries contain no pose-`z` feature names

## Comparison against the prior two straight-only results

Original straight-only pass (pre-XY-only, same manifest, previous feature space):

- positive fixtures: **47 expected emits**, **11 wrong emits**
- negative control: **30 false-positive emits**
- straight-left fixture: **16 expected**, **11 wrong**
- straight-right fixture: **31 expected**, **0 wrong**

XY-only rerun:

- positive fixtures: **41 expected emits**, **12 wrong emits**
- negative control: **27 false-positive emits**
- straight-left fixture: **12 expected**, **12 wrong**
- straight-right fixture: **29 expected**, **0 wrong**

Raw-XY shoulder/elbow/wrist rerun:

- positive fixtures: **36 expected emits**, **29 wrong emits**
- negative control: **29 false-positive emits**
- straight-left fixture: **12 expected**, **17 wrong**
- straight-right fixture: **24 expected**, **12 wrong**

Interpretation:

- raw XY did **not** improve the no-punch rejection problem in a meaningful way
- straight-left remained non-viable and became even more right-confused
- straight-right lost the one clean lane the earlier passes still had
- overall viability got worse, not better

## Aggregate readout

Across the two positive fixtures, the raw-XY rerun produced:

- **36** expected emits
- **29** wrong emits

Negative control (`run_in_place_negative_control`):

- **29** false-positive emits
- false-positive classes:
  - `straight_left` -> **28**
  - `straight_right` -> **1**
- false-positive prototypes:
  - `boxing_straight_left_window_02` -> **21**
  - `boxing_straight_left_window_03` -> **4**
  - `boxing_straight_left_window_01` -> **3**
  - `boxing_straight_right_window_01` -> **1**

## Fixture-by-fixture readout

### straight_left_fixture

This fixture is still **not** class-clean under raw XY features.

- expected `punch_left` emits: **12**
- wrong `punch_right` emits: **17**
- strongest expected emit: `boxing_straight_left_window_01` at **0.994**
- strongest wrong emit: `boxing_straight_right_window_01` at **0.978** over left runner-up **0.969** (margin **0.009**)

Interpretation:

- the matcher still finds true left-like windows strongly
- but right-side straight prototypes win even more often than the correct class
- left-vs-right separation is not trustworthy in this feature space

### straight_right_fixture

This fixture is now also **not** class-clean under raw XY features.

- expected `punch_right` emits: **24**
- wrong `punch_left` emits: **12**
- strongest expected emit: `boxing_straight_right_window_01` at **1.000**
- strongest wrong emit: `boxing_straight_left_window_01` at **0.979** over right runner-up **0.976** (margin **0.003**)

Interpretation:

- raw XY removed the earlier one-sided clean lane
- the matcher now flips right straights into left as well
- this is a regression relative to both prior straight-only passes

### run_in_place_negative_control

This remains a decisive blocker.

- false-positive emits: **29**
- false positives were mostly `punch_left` / `straight_left`, with **1** `punch_right`
- dominant culprit: `boxing_straight_left_window_02` with **21** emits
- strongest false positive emit: `boxing_straight_left_window_02` at **0.971** over straight-right runner-up **0.901** (margin **0.070**)
- peak snapshot winner: `straight_left` at **0.973** over `straight_right` **0.938** (margin **0.035**)

Interpretation:

- the no-punch rejection path is still not truthful in this raw-XY slice
- the matcher is still confidently hallucinating straight attacks during running-in-place motion
- because the negative control remains unsafe and both positive classes cross-fire, the current straight-only mode cannot be treated as viable

## Answer to the primary question

**Under raw-XY shoulder/elbow/wrist features with no depth, can the current prototype system distinguish straight-left and straight-right from no-punch accurately enough to count as viable?**

**No.**

Raw XY shoulder/elbow/wrist is not viable for the current straight-only prototype matcher. It keeps the no-punch false-positive problem and makes left/right separation worse, including breaking the previously clean straight-right lane.

## Recommended interpretation for the next seam

Treat this rerun as evidence that moving to literal raw XY shoulder/elbow/wrist coordinates is not the fix.

If work continues, the next branch should assume the remaining problem is in prototype family separability or decision policy rather than in depth removal alone or in simply making the coordinates more literal. Raw XY increased overlap instead of reducing it.
