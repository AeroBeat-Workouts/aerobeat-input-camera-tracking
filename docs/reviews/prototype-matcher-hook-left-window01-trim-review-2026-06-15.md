# Prototype Matcher Hook-Left Window 01 Trim Review — 2026-06-15

## Scope
- Single-window intervention only: `boxing_hook_left_window_01`
- Kept trim: `1200-1450ms`
- Comparison baseline: `docs/baselines/prototype-matcher-boxing-fixture-derived-v1-retest-2026-06-15/benchmark-results.json`
- Final rerun: `docs/baselines/prototype-matcher-boxing-fixture-derived-v1-hook-left-window01-trim-2026-06-15/benchmark-results.json`

## Narrow trial results
- `1150-1450`: negative total `29`, negative `hook_left` `25`, negative `window_01` `10`, positive hook-left expected `10`, positive hook-left wrong `13`.
- `1200-1450` (trial pass): negative total `25`, negative `hook_left` `2`, negative `window_01` `1`, positive hook-left expected `8`, positive hook-left wrong `14`.
- `1150-1400`: negative total `29`, negative `hook_left` `24`, negative `window_01` `24`, positive hook-left expected `9`, positive hook-left wrong `12`.
- `1200-1400`: negative total `29`, negative `hook_left` `23`, negative `window_01` `0`, positive hook-left expected `13`, positive hook-left wrong `16`.

## Final rerun vs current retest baseline
- Negative-control total false positives: `30` → `29` (`-1`)
- Negative-control `hook_left` false positives: `24` → `23` (`-1`)
- Negative-control `boxing_hook_left_window_01` attributions: `24` → `23` (`-1`)
- Positive hook-left expected events: `10` → `13` (`+3`)
- Positive hook-left wrong events: `18` → `14` (`-4`)
- Positive-suite expected events total: `91` → `98` (`+7`)
- Positive-suite wrong events total: `83` → `73` (`-10`)

## Attribution notes
- Baseline negative-control top prototype: `boxing_hook_left_window_01` = `24`.
- Final negative-control top prototype: `boxing_hook_left_window_01` = `23`.
- Baseline strongest expected hook-left emit: `boxing_hook_left_window_01` at `0.935237`.
- Final strongest expected hook-left emit: `boxing_hook_left_window_01` at `0.992153`.

## Verdict
The surgical trim **helped somewhat but not enough**.

Why:
- The final rerun only reduced negative-control `boxing_hook_left_window_01` attributions by **1** (`24 → 23`), so the original false-positive failure mode still dominates.
- Legitimate hook-left behavior did not collapse; it improved on the final rerun (`10 → 13` expected events, `18 → 14` wrong events). That means the trim is not obviously destructive to the positive fixture.
- However, the final comparison against the current retest baseline does **not** produce a decisive enough false-positive reduction to justify calling the intervention successful.
