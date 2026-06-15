# Hook-left window 01 tighten review (2026-06-15)

- Intervention fixture: `.testbed/assets/fixtures/boxing/hook_left/boxing_guard->hook_left_repeat_04_take_01.yaml`
- Window change: `boxing_hook_left_window_01` from `1000-1600 ms` to `1100-1500 ms`
- Baseline benchmark: `docs/baselines/prototype-matcher-boxing-fixture-derived-v1-retest-2026-06-15/benchmark-results.json`
- Candidate benchmark: `docs/baselines/prototype-matcher-boxing-fixture-derived-v1-hook-left-window-01-tighten-2026-06-15/benchmark-results.json`
- Structured summary: `docs/reviews/prototype-matcher-hook-left-window-01-tighten-review-2026-06-15.summary.json`

## Direct answer

Yes — tightening only `boxing_hook_left_window_01` to `1100-1500 ms` **materially reduced** run-in-place false positives **without unacceptable legit hook-left loss**.

## Negative-control comparison

- Total false-positive emits: `30` → `20` (`-10`)
- `hook_left` false-positive emits: `24` → `4`
- `boxing_hook_left_window_01` false-positive emits: `24` → `1`
- `boxing_hook_left_window_01` best-snapshot wins on the negative control: `71` → `3`

The targeted prototype stopped being the dominant negative-control winner. After the trim, the remaining hook-left false positives were led by `boxing_hook_left_window_04` instead of `boxing_hook_left_window_01`.

## Legit hook-left comparison

- Expected `hook_left` emits on the real hook-left fixture: `10` → `8`
- Wrong emits on the real hook-left fixture: `18` → `13`
- `boxing_hook_left_window_01` emits on the real hook-left fixture: `6` → `2`
- Strongest expected emit before: `boxing_hook_left_window_01` at `0.935`
- Strongest expected emit after: `boxing_hook_left_window_04` at `0.974`

So the intervention did **not** collapse legitimate hook-left behavior. The positive fixture does lose 2 expected hook-left emits (`10` → `8`), but it avoids a collapse and still sheds 5 wrong-event emits (`18` → `13`).

## Important tradeoff

This is not a full cure. The false-positive burden dropped, but some of it shifted to `boxing_hook_left_window_04`:

- Negative-control top false-positive prototypes after the change:
  - `boxing_straight_left_window_04`: 8
  - `boxing_straight_left_window_03`: 5
  - `boxing_hook_left_window_04`: 3
  - `boxing_hook_right_window_04`: 3
  - `boxing_hook_left_window_01`: 1

That means the single-window intervention answers the narrow question positively, but it also confirms the broader hook-left family still has remaining ambiguity outside window 01.

## Cross-fixture notes

- `straight_left_fixture` expected events: 7 → 8; wrong events: 22 → 12
- `straight_right_fixture` expected events: 27 → 20; wrong events: 6 → 9
- `hook_left_fixture` expected events: 10 → 8; wrong events: 18 → 13
- `hook_right_fixture` expected events: 17 → 15; wrong events: 10 → 6
- `uppercut_left_fixture` expected events: 15 → 9; wrong events: 14 → 11
- `uppercut_right_fixture` expected events: 15 → 10; wrong events: 13 → 10
- `run_in_place_negative_control` expected events: 0 → 0; wrong events: 30 → 20
