# Prototype Matcher Straight-Only Sanity Test Design

- Date: 2026-06-15
- Base library: `assets/prototype_libraries/boxing_side_aware_fixture_derived_v1/library.json`
- Base benchmark manifest: `.testbed/assets/benchmarks/prototype_matcher_boxing_fixture_derived_v1.benchmark.json`
- Scope: design only; no benchmark rerun in this note

## Question

What is the least invasive truthful way to ask:

> can the current prototype matcher distinguish `straight_left` and `straight_right` from `no_punch` when hook and uppercut classes are excluded?

## Decision

Use a **filtered-library override plus a narrow benchmark manifest**.

### Why this is the narrowest truthful seam

This repo already has a proving-only library selection seam:

- `scripts/run_prototype_matcher_fixture_benchmark.py` passes `manifest.library_id` into `AEROBEAT_PROTOTYPE_LIBRARY_ID_OVERRIDE`
- `.testbed/scripts/proving_harness.gd` applies that override at runtime
- `src/detectors/prototype_punch_matcher.gd` scores whatever prototypes are present in the selected library file

That means we can disable hook/uppercut detection for the sanity test **without changing matcher logic** and **without retuning thresholds** by supplying a library whose prototypes only contain:

- `straight_left`
- `straight_right`

Because `PrototypePunchMatcher` initializes scores for all supported classes but only scores classes that have prototypes in the loaded library, omitted hook/uppercut classes stay at `0.0` and cannot win. `no_punch` remains the threshold-rejection path exactly as before.

## Why the alternatives are worse

### 1) Filtered benchmark mode alone

Not sufficient.

A benchmark manifest that only runs straight-left, straight-right, and negative-control fixtures would reduce the fixture set, but it would **not** disable hook/uppercut detection if the loaded library still contains hook/uppercut prototypes. The matcher could still emit those classes during the negative control or straight fixtures, so that would not truthfully answer the isolation question.

### 2) Fresh straight-only library derivation from fixtures

Possible, but not the narrowest seam.

Using `scripts/derive_prototype_library_from_fixtures.py` with a straight-only manifest would regenerate straight prototypes from fresh capture reports. That adds rerun jitter and changes the prototype content at the same time that classes are being excluded. For this sanity-test question, the cleaner comparison is to keep the current committed straight prototypes exactly as they are and only remove non-straight classes from consideration.

### 3) Code-level matcher allowlist / class filter

More invasive than needed.

Adding a runtime class allowlist to `PrototypePunchMatcher` would introduce new behavior in the detector code just to support this benchmark seam. The existing library override path already provides a data-only isolation mechanism, so code changes are unnecessary for the first pass.

## Recommended implementation shape for the next bead

### A. Create a filtered library artifact

Create a new library id, for example:

- `boxing_side_aware_fixture_derived_v1_straight_only`

Materialize it under:

- `assets/prototype_libraries/boxing_side_aware_fixture_derived_v1_straight_only/library.json`
- optional but recommended: matching `README.md`

Filter the current committed library as follows:

- keep top-level metadata unchanged where possible:
  - `schema`
  - `version`
  - `sample_count`
  - `distance_scale`
  - `feature_names`
- set `library_id` to the new id
- set `classes` to:
  - `straight_left`
  - `straight_right`
- keep only prototypes where `class_name` is one of those two classes
- preserve the existing straight prototype payloads byte-for-byte aside from the enclosing filtered document

Expected prototype count from the current library:

- `straight_left`: 4
- `straight_right`: 4
- total: 8

### B. Create a narrow benchmark manifest

Create a dedicated manifest, for example:

- `.testbed/assets/benchmarks/prototype_matcher_boxing_fixture_derived_v1_straight_only.benchmark.json`

It should point to the filtered library id and include only:

- `straight_left_fixture`
- `straight_right_fixture`
- `run_in_place_negative_control`

This keeps the run focused on the actual question instead of re-benchmarking unrelated positive classes.

### C. Run the existing benchmark runner unchanged

Use the existing runner:

```bash
python3 scripts/run_prototype_matcher_fixture_benchmark.py \
  --manifest .testbed/assets/benchmarks/prototype_matcher_boxing_fixture_derived_v1_straight_only.benchmark.json \
  --output-dir docs/baselines/prototype-matcher-boxing-fixture-derived-v1-straight-only-2026-06-15
```

No matcher retuning.
No detector logic edits.
No broad class tuning.

## Truth claim this mode supports

This mode truthfully answers a narrow question:

- with the **current straight prototypes** and the **current threshold/cooldown/hold logic**, does the matcher separate straight-left and straight-right from no-punch when hook/uppercut prototype competition is removed?

It does **not** answer broader questions such as:

- whether a freshly re-derived straight-only library would do better
- whether code-level class gating should exist in product/runtime
- whether hook/uppercut confusion should be solved by tuning, pruning, or threshold changes

## Recommendation

Proceed with the next run bead using the **filtered-library override + narrow manifest** path.

That is the least invasive design because it is:

- data-only
- reversible
- benchmark-local
- faithful to the current straight prototype content
- sufficient to remove hook/uppercut competition from the matcher
