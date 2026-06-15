# Prototype matcher hook-left window 01 surgical review — 2026-06-15

## Scope

Single intervention only:
- fixture: `.testbed/assets/fixtures/boxing/hook_left/boxing_guard->hook_left_repeat_04_take_01.yaml`
- prototype target: `boxing_hook_left_window_01`
- old window: `1000–1600 ms`
- new window: `1200–1400 ms`
- no matcher retune, no pruning pass, no same-bounds re-derive, no class-margin gating

## Compared artifacts

- Baseline retest benchmark: `docs/baselines/prototype-matcher-boxing-fixture-derived-v1-retest-2026-06-15/benchmark-results.json`
- Candidate benchmark: `docs/baselines/prototype-matcher-boxing-fixture-derived-v1-hook-left-window-01-tighten-2026-06-15/benchmark-results.json`
- Structured summary: `docs/reviews/prototype-matcher-hook-left-window-01-surgical-review-2026-06-15.summary.json`

## Headline result

This single-window tightening **does help** the exact problem seam.

### Run-in-place negative control

- Total wrong events: **30 → 23** (`-7`)
- `hook_left` false-positive emits: **24 → 19**
- `boxing_hook_left_window_01` false-positive emits: **24 → 9**
- `boxing_hook_left_window_01` best-snapshot wins: **71 → 27**

So the negative control still misfires, but less often, and the original window is much less dominant.

### Legitimate hook-left fixture

- Expected hook-left events: **10 → 9** (`-1`)
- Wrong events on the hook-left fixture: **18 → 14** (`-4`)
- `boxing_hook_left_window_01` emits on the hook-left fixture: **6 → 5**

The real hook-left lane loses only one expected emit here, so this does **not** look like a collapse.

## Broader library movement

- Total expected events across all fixtures: **91 → 85**
- Total wrong events across all fixtures: **113 → 96**

Per-fixture expected/wrong deltas:

| Fixture | Expected | Wrong |
| --- | ---: | ---: |
| `straight_left_fixture` | `7 → 11` | `22 → 18` |
| `straight_right_fixture` | `27 → 28` | `6 → 9` |
| `hook_left_fixture` | `10 → 9` | `18 → 14` |
| `hook_right_fixture` | `17 → 14` | `10 → 9` |
| `uppercut_left_fixture` | `15 → 12` | `14 → 11` |
| `uppercut_right_fixture` | `15 → 11` | `13 → 12` |
| `run_in_place_negative_control` | `0 → 0` | `30 → 23` |


This is still not a pure isolated win: some other classes shift too, so the result should be treated as evidence first.

## Verdict

**Answer to the primary question:**
- **Did run-in-place false positives drop materially?** Yes.
- **Did that happen without unacceptable legit hook-left loss?** Yes, narrowly.

But the safest full reading is:
- **narrow answer:** yes, this helps;
- **broader answer:** still mixed enough that more hook-left cleanup is warranted before treating it as the final library state.
