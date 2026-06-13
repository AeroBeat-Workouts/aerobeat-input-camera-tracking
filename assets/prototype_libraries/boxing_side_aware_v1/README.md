# boxing_side_aware_v1

First runtime seed library for the pose-only side-aware prototype matcher.

## Classes

- `straight_left`
- `straight_right`
- `hook_left`
- `hook_right`
- `uppercut_left`
- `uppercut_right`

`no_punch` is not stored as a large negative library in v1. The matcher returns `no_punch` by threshold rejection when no positive class clears `prototype_matcher.thresholds.match_score_min`.

## Payload shape

`library.json` stores:

- `sample_count`: fixed resampled window length used for runtime comparison
- `distance_scale`: score normalization divisor for mean per-frame feature distance
- `feature_names`: ordered pose-derived feature vector fields
- `prototypes[]`: curated positive examples with `id`, `class_name`, `side`, `source_ref`, and `samples`

Each sample row is:

1. elbow x from same-side shoulder / shoulder width
2. elbow y from same-side shoulder / shoulder width
3. wrist x from same-side shoulder / shoulder width
4. wrist y from same-side shoulder / shoulder width
5. elbow z from same-side shoulder
6. wrist z from same-side shoulder

## Provenance notes

This is the repo-owned bootstrap matcher library for the first runtime slice. The `source_ref` fields anchor each prototype family to the existing boxing fixture/timing asset family already tracked in this repo.

The library is intentionally small and inspectable so QA can answer:

- which library was active
- which class won
- which score cleared or missed the threshold
- which exact prototype family/version was used

Future library revisions can replace these seed prototypes with saved-session-derived windows without changing the public `library_id` selection contract.
