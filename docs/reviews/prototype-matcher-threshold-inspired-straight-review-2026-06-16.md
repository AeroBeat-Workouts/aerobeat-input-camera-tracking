# Prototype Matcher Threshold-Inspired Straight Review — 2026-06-16

- Straight-only library: `assets/prototype_libraries/boxing_side_aware_fixture_derived_v1_straight_only/library.json`
- Benchmark manifest: `.testbed/assets/benchmarks/prototype_matcher_boxing_fixture_derived_v1_straight_only.benchmark.json`
- Benchmark output: `docs/baselines/prototype-matcher-boxing-fixture-derived-v1-straight-only-2026-06-16/benchmark-results.json`
- Summary JSON: `docs/reviews/prototype-matcher-threshold-inspired-straight-review-2026-06-16.summary.json`

## Bottom line

Not yet viable.

The added threshold-inspired features **did** improve the straight-only prototype branch relative to the prior raw-XY pass, but not enough to trust it:

- straight-left moved from **12 expected / 17 wrong** to **17 expected / 14 wrong**
- straight-right moved from **24 expected / 12 wrong** to **27 expected / 9 wrong**
- run-in-place false positives moved from **29** to **28**

That is real directional progress, but it is still far too noisy. The negative control still hallucinates punches constantly, and both positive fixtures still cross-fire across left/right.

## Feature-space check

The regenerated straight-only library now uses these per-side features:

- `shoulder_x`
- `shoulder_y`
- `elbow_x`
- `elbow_y`
- `wrist_x`
- `wrist_y`
- `combined_elbow_wrist_velocity_xy_magnitude`
- `elbow_shoulder_xy_distance_over_shoulder_width`

The two new threshold-inspired signals are present in both the runtime matcher and the derived library artifacts.

## Benchmark truth

### Straight left fixture

- expected emits: **17**
- wrong emits: **14**
- strongest wrong emit: `punch_right` via `boxing_straight_right_window_04` at **0.921**

### Straight right fixture

- expected emits: **27**
- wrong emits: **9**
- strongest wrong emit: `punch_left` via `boxing_straight_left_window_04` at **0.888**

### Run-in-place negative control

- false-positive emits: **28**
- false-positive classes: `straight_left` x28
- strongest false positive: `punch_left` via `boxing_straight_left_window_01` at **0.973**

## Recommendation

Treat this as evidence that abstracting the features helps a bit, but the prototype matcher is still structurally weak for straight-punch truth in this dataset. I would not call this branch shippable or even QA-passable yet.
