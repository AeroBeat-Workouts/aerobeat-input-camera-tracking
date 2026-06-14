# Prototype Matcher Derived-Library Review Packet

_Date: 2026-06-13_

## Top line

- Baseline compared: `docs/baselines/prototype-matcher-boxing-side-aware-v1/benchmark-results.json`
- Derived-library run: `docs/baselines/prototype-matcher-boxing-fixture-derived-v1/benchmark-results.json`
- Active truth source: `boxing_side_aware_fixture_derived_v1`
- Result: **huge recall jump, but very noisy.** Expected events appeared on **6/6** positive fixtures after the seed baseline's **0/6**, but every positive fixture also emitted wrong attacks and the negative control was polluted.
- Positive-fixture totals: **98 expected emits** and **74 wrong emits** across the six attack fixtures.
- Negative-control result: **0/1 clean**; the run-in-place fixture emitted **30** attack events.
- Read on the branch: the derived library clearly unlocked recognizer activity, but the current class boundaries are still overlapping badly enough that it cannot yet be treated as trustworthy runtime truth.

## Aggregate comparison vs seed baseline

- Positive fixtures with at least one expected emit: **0/6 -> 6/6**
- Positive fixtures with wrong emits: **0/6 -> 6/6**
- Negative controls with attack events: **0/1 -> 1/1**
- Positive expected emits total: **0 -> 98**
- Positive wrong emits total: **0 -> 74**
- Total wrong emits including negative control: **0 -> 104**

Interpretation: the seed library was effectively inert but safe. The derived library is the opposite: it is decisively alive, but overshoots hard enough that the next problem is no longer “how do we get any emits?” — it is “how do we separate the right class from nearby wrong ones and stop idle motion from looking punch-like?”

## Fixture-level readout

| Fixture | Expected event | Expected emits | Wrong emits | Dominant wrong pattern | Read |
| --- | --- | ---: | ---: | --- | --- |
| `straight_left_fixture` | `punch_left` | 10 | 19 | `uppercut_right` 7, `uppercut_left` 6, `hook_right` 6 | Left straight is recognized, but its decision region still overlaps uppercuts and right hook-like motion. |
| `straight_right_fixture` | `punch_right` | 27 | 6 | `uppercut_left` 6 | Best positive fixture by purity, but still drifts into left uppercut. |
| `hook_left_fixture` | `hook_left` | 10 | 17 | `hook_right` 9, `uppercut_left` 5 | Left hook is present, but side disambiguation is weak and some windows still tip upward. |
| `hook_right_fixture` | `hook_right` | 19 | 8 | `hook_left` 5 | Better than left hook, but still cross-fires side-to-side. |
| `uppercut_left_fixture` | `uppercut_left` | 18 | 11 | `hook_right` 7 | Left uppercut mostly works, but its strongest confusion is into the opposite-side hook family. |
| `uppercut_right_fixture` | `uppercut_right` | 14 | 13 | `hook_left` 9 | Right uppercut is nearly 1:1 with wrong emits; most confusion lands in opposite-side hook. |
| `run_in_place_negative_control` | none | 0 | 30 | `hook_left` 24 | Safety failure. Idle/running motion is being interpreted mostly as left-hook-like. |

## Main confusion patterns

1. **Hook side confusion remains the loudest side-specific issue.**
   - `hook_left_fixture`: **9** wrong `hook_right` emits
   - `hook_right_fixture`: **5** wrong `hook_left` emits

2. **Uppercuts collapse toward hooks, especially across sides.**
   - `uppercut_left_fixture`: **7** wrong `hook_right` emits
   - `uppercut_right_fixture`: **9** wrong `hook_left` emits

3. **The straight fixtures are no longer dead, but they are not cleanly straight-shaped yet.**
   - `straight_left_fixture` spreads wrong emits across `uppercut_left`, `uppercut_right`, and `hook_right`
   - `straight_right_fixture` still leaks **6** `uppercut_left` emits

4. **The negative control is dominated by hook-like false positives, not random noise.**
   - `run_in_place_negative_control`: **24** wrong `hook_left`, **2** wrong `hook_right`, **4** wrong `punch_left`
   - That concentration matters: it suggests a repeatable overlap between locomotion windows and the current hook prototypes rather than a fully chaotic classifier.

## What improved relative to the seed baseline

- The classifier is no longer inert.
- Every positive fixture now produces at least one expected emit.
- Expected-class peak scores are now high enough to cross threshold in all six positive fixtures.
- The derived library therefore looks meaningfully closer to the recorded fixture motion than the seed library did.

## What is still blocking truthfulness

- Every positive fixture still produces wrong emits.
- The negative control is completely unclean.
- Wrong emits are not evenly distributed; they cluster around **hook_left / hook_right** and some **uppercut_left** drift, which points to overlapping class shapes rather than just a slightly low threshold.
- Because the negative control is dirty, a simple “recall win” interpretation would be misleading. The library learned to fire, but it has not yet learned enough restraint.

## Most plausible next tuning branch (hypothesis, not certainty)

**Prototype-library class-separability and side-disambiguation tuning** is the best next branch to test first.

Why this is the strongest hypothesis from the data:

- The branch already solved the baseline's “no emits at all” failure, so total matcher starvation is no longer the main bottleneck.
- The dominant mistakes are structured, not random:
  - left/right hooks swap with each other
  - uppercuts drift into opposite-side hooks
  - run-in-place mostly looks like `hook_left`
- That pattern smells more like **prototype overlap / poor separability / side-normalization ambiguity** than a pure threshold issue.

Why this is only a hypothesis:

- Thresholds and emit gating still influence how often these overlaps become visible events.
- A small threshold or cooldown experiment could still change the picture at the margins.
- But with a 30-event negative-control failure, threshold-only tuning does not look like the highest-confidence first branch.

## Recommendation

Keep `boxing_side_aware_fixture_derived_v1` as the current evidence-bearing candidate, but do **not** treat it as production-truthful yet. The right next move is to branch into **hook/uppercut separability and side-aware prototype cleanup** first, then re-benchmark before spending much time on threshold-only polish.

## Artifacts

- Benchmark JSON: `docs/baselines/prototype-matcher-boxing-fixture-derived-v1/benchmark-results.json`
- Benchmark markdown: `docs/baselines/prototype-matcher-boxing-fixture-derived-v1/benchmark-results.md`
- Review packet: `docs/reviews/prototype-matcher-derived-library-review-2026-06-13.md`
- Structured summary: `docs/reviews/prototype-matcher-derived-library-review-2026-06-13.summary.json`
