# Prototype Matcher Attribution Retest Review

- Date: 2026-06-15
- Retested library: `assets/prototype_libraries/boxing_side_aware_fixture_derived_v1/library.json`
- Fresh derivation report: `assets/prototype_libraries/boxing_side_aware_fixture_derived_v1/derivation_report.json`
- Fresh benchmark artifact: `docs/baselines/prototype-matcher-boxing-fixture-derived-v1-retest-2026-06-15/benchmark-results.json`
- Fresh benchmark markdown: `docs/baselines/prototype-matcher-boxing-fixture-derived-v1-retest-2026-06-15/benchmark-results.md`
- Prior attribution review: `docs/reviews/prototype-matcher-attribution-review-2026-06-13.md`
- Prior attribution summary: `docs/reviews/prototype-matcher-attribution-review-2026-06-13.summary.json`

## Why this exists

This is the post-repair retest after the sync/bootstrap/provenance fixes (`7e2f9db`, `9a36bf0`, `fc7e1ee`). The question is not whether we can tune the matcher yet. The question is whether the earlier attribution findings still hold once the derivation/benchmark path is re-run from a repaired, trustworthy state.

## Bottom line

**Mostly yes: the substantive diagnosis reproduces.**

The fresh rerun still shows:

- a dirty negative control with **30** false-positive emits
- false positives still dominated by the **hook-left family**
- the dominant negative-control culprit still concentrated on **`boxing_hook_left_window_01`**
- several wrong emits still winning on **very tight class margins**

What changed is narrower than the overall diagnosis:

- the exact hook-left **positive-side winning prototype identity did not reproduce exactly**
- in the fresh run, the hook-left fixture's strongest expected emit came from **`boxing_hook_left_window_01`**, not the earlier review's **`boxing_hook_left_window_04`**
- so the earlier sub-claim that the strongest legitimate hook-left winner and the dominant false-positive culprit are cleanly different prototypes **did not reproduce cleanly on this retest**

That means the big picture stayed the same, but one finer-grained attribution detail softened.

## Fresh aggregate readout

Across the six positive fixtures, the fresh rerun produced:

- **91** expected emits
- **83** wrong emits

Negative control (`run_in_place_negative_control`):

- **30** false-positive emits
- false-positive classes:
  - `hook_left` -> **24**
  - `straight_left` -> **4**
  - `hook_right` -> **2**
- false-positive prototypes:
  - `boxing_hook_left_window_01` -> **24**
  - `boxing_hook_right_window_03` -> **2**
  - `boxing_straight_left_window_03` -> **2**
  - `boxing_straight_left_window_01` -> **1**
  - `boxing_straight_left_window_02` -> **1**

## Comparison against the earlier attribution evidence

### 1) Hook-left false-positive culprit pattern

This part **reproduced clearly**.

Earlier attribution summary (`2026-06-13`):

- negative-control false positives: **30**
- dominant class: `hook_left` with **25**
- dominant prototype: `boxing_hook_left_window_01` with **21**
- secondary prototype: `boxing_hook_left_window_03` with **4**

Fresh retest (`2026-06-15`):

- negative-control false positives: **30**
- dominant class: `hook_left` with **24**
- dominant prototype: `boxing_hook_left_window_01` with **24**
- secondary prototype counts dropped away from that earlier exact pattern; remaining spill is much smaller and mixed

Interpretation:

- The **same family of failure** is still present.
- The negative control is still overwhelmingly interpreted as **hook-left-like motion**.
- `boxing_hook_left_window_01` is still the main culprit, and in the fresh run it is even **more concentrated** than before.

So if the question is "did the hook-left false-positive culprit pattern survive the trust repairs?" the answer is **yes**.

### 2) Class-margin behavior

This part also **reproduced clearly**.

Earlier attribution summary highlighted the closest wrong-emit margins at roughly:

- `0.00018` (`uppercut_left_fixture` -> wrong `uppercut_right`)
- `0.00748` (`hook_right_fixture` -> wrong `uppercut_right`)
- `0.01450` (`straight_left_fixture` -> wrong `hook_right`)
- `0.01532` (`uppercut_right_fixture` -> wrong `hook_right`)

Fresh retest closest wrong-emit margins were:

- `0.00132` (`hook_right_fixture` -> wrong `uppercut_right` via `boxing_uppercut_right_window_04`)
- `0.01007` (`straight_left_fixture` -> wrong `hook_right` via `boxing_hook_right_window_01`)
- `0.01023` (`uppercut_left_fixture` -> wrong `uppercut_right` via `boxing_uppercut_right_window_04`)
- `0.01782` (`uppercut_right_fixture` -> wrong `hook_right` via `boxing_hook_right_window_01`)
- `0.02553` (`hook_left_fixture` -> wrong `uppercut_right` via `boxing_uppercut_right_window_01`)

Interpretation:

- The exact smallest margin moved a bit, but the matcher is still producing **near-tie wrong emits**.
- That preserves the earlier conclusion that **class-margin behavior remains a real part of the problem**, not a one-off artifact from the broken validation path.

### 3) Positive-fixture winner identities

This is the main place where the retest moved.

Stable reproductions:

- `straight_left`: peak snapshot and strongest expected emit still align with the earlier review (`boxing_straight_left_window_01` / `boxing_straight_left_window_03`)
- `straight_right`: unchanged (`boxing_straight_right_window_01`)
- `hook_right`: unchanged (`boxing_hook_right_window_01`)
- `uppercut_left`: unchanged (`boxing_uppercut_left_window_02` peak, `boxing_uppercut_left_window_01` strongest expected emit)
- `uppercut_right`: unchanged (`boxing_uppercut_right_window_01`)

Changed readout:

- `hook_left` no longer reproduced the earlier "window_04 is the strongest legitimate winner" detail
- fresh run:
  - peak snapshot winner: `boxing_hook_left_window_02`
  - strongest expected emit: `boxing_hook_left_window_01`

Interpretation:

- The **macro failure mode** still points at hook-left trouble.
- But the **micro-level winner identity within the hook-left class is less stable than the earlier review implied**.
- That weakens the earlier narrow claim that the legitimate hook-left winner and the false-positive culprit are cleanly separated prototypes.

## What the retest says after the trust repairs

The repaired derivation/benchmark path does **not** overturn the earlier matcher diagnosis.

It still says:

1. the derived library is active, not inert
2. the negative control is still unsafe
3. hook-left-like prototypes still dominate that unsafe behavior
4. class-separation margins are still tight enough to keep cross-class false emits alive

What it does change is the confidence of one narrower statement: the hook-left class no longer cleanly demonstrates that the strongest legitimate winner is a different prototype than the main false-positive culprit.

## Regeneration notes

The library was freshly regenerated and remains structurally the same in the ways that matter most for this seam:

- library id unchanged: `boxing_side_aware_fixture_derived_v1`
- prototype count unchanged: **24**
- distance scale unchanged: **0.45**

Durable provenance improved:

- `README.md` now points at the correct benchmark manifest: `prototype_matcher_boxing_fixture_derived_v1.benchmark.json`
- `derivation_report.json` now records the repaired manifest path and capture delay (`9000` ms)

The regenerated library is **not byte-identical** to the earlier committed artifact because pose-window capture alignment shifts slightly across reruns, but those shifts did **not** change the high-level diagnosis.

## Answer to the primary question

**Do we reproduce the earlier substantive findings?**

- **Yes, in substance.**
- The hook-left false-positive problem still reproduces strongly.
- The class-margin problem still reproduces strongly.
- **No, not every sub-detail reproduced exactly.** The earlier fine-grained claim that the strongest legitimate hook-left winner was clearly different from the dominant false-positive culprit did **not** reproduce cleanly on this fresh run.

## Recommended interpretation for the next seam

Do **not** treat the trust repairs as having invalidated the earlier direction of travel. They did not. The retest still supports a future tuning seam focused on:

- hook-left false-positive cleanup / prototype-local investigation first
- class-margin gating as a still-plausible secondary branch

But when describing the evidence, be more precise than the 2026-06-13 packet was:

- the **culprit pattern** is stable
- the **tight-margin pattern** is stable
- the **exact hook-left positive winner identity** is less stable than previously claimed
