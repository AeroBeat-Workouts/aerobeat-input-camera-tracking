# Prototype Matcher Attribution Review

- Date: 2026-06-13
- Library reviewed: `assets/prototype_libraries/boxing_side_aware_fixture_derived_v1/library.json`
- Benchmark artifact: `docs/baselines/prototype-matcher-boxing-fixture-derived-v1/benchmark-results.json`
- Benchmark markdown: `docs/baselines/prototype-matcher-boxing-fixture-derived-v1/benchmark-results.md`

## Why this exists

The class-separation passes told us the derived library was still noisy, but not **which exact prototypes** were doing the damage. This review uses the new attribution seam to answer four questions:

1. Which exact prototype IDs are winning when the intended class does win?
2. Which runner-up classes / prototypes stay close behind those winners?
3. Which prototypes dominate the negative-control false positives?
4. What is the next most plausible tuning move based on that evidence?

## Headline takeaways

- Legitimate winners are not spread evenly across each class. A small set of prototype IDs keeps surfacing as the strongest emitted match:
  - `boxing_straight_left_window_03`
  - `boxing_straight_right_window_01`
  - `boxing_hook_left_window_04`
  - `boxing_hook_right_window_01`
  - `boxing_uppercut_left_window_01`
  - `boxing_uppercut_right_window_01`
- The negative control is not failing because of broad random churn. It is dominated by **specific hook-left prototypes**, especially:
  - `boxing_hook_left_window_01` → **21 / 30** false-positive emits
  - `boxing_hook_left_window_03` → **4 / 30** false-positive emits
- The strongest positive-hook winner and the strongest negative-control culprit are **not the same prototype**:
  - strongest expected hook-left emit: `boxing_hook_left_window_04`
  - dominant negative-control culprit: `boxing_hook_left_window_01`
- Several wrong emits inside the positive fixtures happen on **very tight margins**, which keeps the class-margin-gate hypothesis alive, but the negative-control concentration points more strongly at targeted prototype cleanup first.

## Per-class winning prototype readout

### Straight left

- Peak snapshot winner: `boxing_straight_left_window_01` at **0.986**
- Strongest expected emit: `boxing_straight_left_window_03` at **0.976**
- Closest runner-up during strongest expected emit:
  - class: `uppercut_right`
  - prototype: `boxing_uppercut_right_window_04`
  - score: **0.903**
  - margin: **0.073**
- Strongest wrong emit:
  - event/class: `hook_right`
  - prototype: `boxing_hook_right_window_01`
  - score: **0.941**
  - runner-up expected-class score: **0.926**
  - margin: **0.014**

### Straight right

- Peak snapshot winner: `boxing_straight_right_window_01` at **0.982**
- Strongest expected emit: `boxing_straight_right_window_01` at **0.982**
- Closest runner-up during strongest expected emit:
  - class: `uppercut_right`
  - prototype: `boxing_uppercut_right_window_01`
  - score: **0.823**
  - margin: **0.158**
- Strongest wrong emit:
  - event/class: `uppercut_left`
  - prototype: `boxing_uppercut_left_window_02`
  - score: **0.829**
  - runner-up expected-class score: **0.783**
  - margin: **0.046**

### Hook left

- Peak snapshot winner: `boxing_hook_left_window_04` at **0.980**
- Strongest expected emit: `boxing_hook_left_window_04` at **0.961**
- Closest runner-up during strongest expected emit:
  - class: `straight_left`
  - prototype: `boxing_straight_left_window_03`
  - score: **0.889**
  - margin: **0.072**
- Strongest wrong emit:
  - event/class: `uppercut_right`
  - prototype: `boxing_uppercut_right_window_01`
  - score: **0.920**
  - runner-up uppercut-left score: **0.895**
  - margin: **0.025**

### Hook right

- Peak snapshot winner: `boxing_hook_right_window_01` at **0.975**
- Strongest expected emit: `boxing_hook_right_window_01` at **0.972**
- Closest runner-up during strongest expected emit:
  - class: `uppercut_right`
  - prototype: `boxing_uppercut_right_window_04`
  - score: **0.906**
  - margin: **0.066**
- Strongest wrong emit:
  - event/class: `uppercut_right`
  - prototype: `boxing_uppercut_right_window_01`
  - score: **0.887**
  - runner-up expected-class score: **0.880**
  - margin: **0.007**

### Uppercut left

- Peak snapshot winner: `boxing_uppercut_left_window_02` at **0.993**
- Strongest expected emit: `boxing_uppercut_left_window_01` at **0.992**
- Closest runner-up during strongest expected emit:
  - class: `uppercut_right`
  - prototype: `boxing_uppercut_right_window_04`
  - score: **0.903**
  - margin: **0.089**
- Strongest wrong emit:
  - event/class: `uppercut_right`
  - prototype: `boxing_uppercut_right_window_04`
  - score: **0.915**
  - runner-up expected-class score: **0.914**
  - margin: **0.00018**

### Uppercut right

- Peak snapshot winner: `boxing_uppercut_right_window_01` at **1.000**
- Strongest expected emit: `boxing_uppercut_right_window_01` at **1.000**
- Closest runner-up during strongest expected emit:
  - class: `straight_right`
  - prototype: `boxing_straight_right_window_01`
  - score: **0.859**
  - margin: **0.141**
- Strongest wrong emit:
  - event/class: `hook_right`
  - prototype: `boxing_hook_right_window_01`
  - score: **0.919**
  - runner-up expected-class score: **0.904**
  - margin: **0.015**

## Negative-control culprit readout

Fixture: `run_in_place_negative_control`

- Total false-positive emits: **30**
- False-positive classes:
  - `hook_left` → **25**
  - `straight_left` → **3**
  - `hook_right` → **2**
- False-positive prototypes:
  - `boxing_hook_left_window_01` → **21**
  - `boxing_hook_left_window_03` → **4**
  - `boxing_hook_right_window_03` → **2**
  - `boxing_straight_left_window_01` → **2**
  - `boxing_straight_left_window_02` → **1**
- Strongest false positive:
  - event/class: `hook_left`
  - prototype: `boxing_hook_left_window_01`
  - score: **0.907**
  - runner-up class/prototype: `straight_left` / `boxing_straight_left_window_03`
  - runner-up score: **0.850**
  - margin: **0.058**

## What the attribution implies

Two patterns stand out.

First, the negative-control problem is **prototype-localized**, not evenly distributed across the whole hook/straight library. The run-in-place clip is overwhelmingly won by `boxing_hook_left_window_01`, with some spill from `boxing_hook_left_window_03`. That matters because the strongest legitimate hook-left emits are coming from `boxing_hook_left_window_04`, not from the dominant culprit window.

Second, several cross-class wrong emits inside the positive fixtures are close-margin wins rather than landslides. The most obvious examples are:

- straight-left fixture wrong `hook_right` emit: margin **0.014**
- hook-right fixture wrong `uppercut_right` emit: margin **0.007**
- uppercut-left fixture wrong `uppercut_right` emit: margin **0.00018**
- uppercut-right fixture wrong `hook_right` emit: margin **0.015**

That means class-margin gating is still a plausible secondary branch. But the prototype-localized negative-control evidence is more targeted and higher-confidence.

## Next likely tuning move (hypothesis, not certainty)

**Most likely next move:** branch into **targeted pruning or re-segmentation of the early hook-left prototypes** — especially `boxing_hook_left_window_01`, then `boxing_hook_left_window_03` — before trying broader class-wide edits.

Why this looks like the best next experiment:

- those two prototype IDs dominate the negative-control false positives
- the strongest legitimate hook-left emits are anchored on `boxing_hook_left_window_04`, which suggests the false-positive culprit is not the only useful hook-left shape in the library
- this is a narrower intervention than global hook/uppercut class surgery, so it should give a cleaner read on whether the false-positive burden is coming from bad prototype windows vs. class overlap in general

**Secondary hypothesis if that branch is inconclusive:** add or test a **minimum winner-vs-runner-up class margin** for prototype emits, because several wrong emits are only barely beating the runner-up class.

## Bottom line

The new attribution seam did its job: we now know the derived library's negative-control problem is concentrated in specific prototype IDs, and we know the exact runner-up margins that keep some cross-class false emits alive. That is enough evidence to stop guessing and move to a targeted next seam.
