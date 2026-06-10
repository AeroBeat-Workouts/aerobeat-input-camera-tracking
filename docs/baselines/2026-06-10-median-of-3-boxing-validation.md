# Median-of-3 boxing validation — 2026-06-10

Repo: `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking`
Scene: `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.testbed/scenes/boxing_proving.tscn`
Profile: `boxing`
Replay fixture: `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.testbed/assets/fixtures/boxing/punch_left/boxing_guard->punch_left_repeat_04_take_01.mp4`
Baseline reference: `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/docs/baselines/2026-06-10-boxing-smoothing-baseline.md`

## What changed

Implemented one new explicit pose smoothing style:

- `median_of_3`

It runs in the repo-owned post-pose smoothing path, keeps the vendor runtime in the same low-complexity / raw-filter lane as `lite_raw`, and uses a fixed 3-sample coordinate-wise median window after the first two warmup frames.

## Validation method

Focused validation covered:

- unit/runtime path tests for `LandmarkSmoother`, `PoseDetectorSubstrate`, and proving-harness config resolution
- fixture replay capture for three modes using the existing proving-scene capture script:
  - `lite_raw`
  - `exponential_moving_average`
  - `median_of_3`

Artifact root:

- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.temp/median-of-3-validation-20260610-172548/`

Each mode directory contains:

- `report.json`
- `report.md`
- `time.txt`
- `stdout.log`
- `stderr.log`

## Replay capture summary

### Performance

- `lite_raw`
  - wall: `8.74s`
  - user CPU: `23.36s`
  - sys CPU: `7.78s`
  - max RSS: `472008 KB`
- `exponential_moving_average`
  - wall: `9.36s`
  - user CPU: `24.13s`
  - sys CPU: `7.86s`
  - max RSS: `472760 KB`
- `median_of_3`
  - wall: `9.01s`
  - user CPU: `23.73s`
  - sys CPU: `7.51s`
  - max RSS: `472520 KB`

Read: `median_of_3` stayed close to the existing replay runtime envelope. It did not look materially expensive.

### First-hit responsiveness proxy

Using `provider_started -> first punch_left` from the captured event timeline:

- `lite_raw`: `688 ms`
- `exponential_moving_average`: `739 ms` (`+51 ms` vs raw)
- `median_of_3`: `786 ms` (`+98 ms` vs raw, `+47 ms` vs EMA)

Read: `median_of_3` landed much closer to the sluggish side of the allowed envelope than hoped. It was slower than the EMA experiment on this fixture.

### Guard-hold jitter proxy

Using guard-active samples from the captured state timeline:

#### Wrist separation X stddev

- `lite_raw`: `0.010932`
- `exponential_moving_average`: `0.010681` (`-2.3%` vs raw)
- `median_of_3`: `0.010875` (`-0.5%` vs raw, worse than EMA)

#### Wrist separation Y stddev

- `lite_raw`: `0.026051`
- `exponential_moving_average`: `0.026524` (`+1.8%` vs raw)
- `median_of_3`: `0.027021` (`+3.7%` vs raw, worse than EMA)

#### Left wrist-to-nose distance stddev

- `lite_raw`: `0.018269`
- `exponential_moving_average`: `0.018694` (`+2.3%` vs raw)
- `median_of_3`: `0.019023` (`+4.1%` vs raw, worse than EMA)

#### Right wrist-to-nose distance stddev

- `lite_raw`: `0.007049`
- `exponential_moving_average`: `0.007252` (`+2.9%` vs raw)
- `median_of_3`: `0.007357` (`+4.4%` vs raw, worse than EMA)

Read: on this replay, `median_of_3` did **not** deliver the target ~15%+ visible jitter reduction. It only slightly improved one lateral metric and regressed the others.

## Bottom line

`median_of_3` is correctly integrated and cheap enough to keep around as a selectable experiment, but this fixture pass does **not** support promoting it as the boxing answer.

- It did **not** materially improve jitter vs `lite_raw`.
- It did **not** beat the EMA experiment on either jitter or lag.
- It added roughly `~98 ms` to the first-hit proxy vs raw, which is outside the ideal lag target and close to the baseline’s “too sluggish for this slice” zone.

If Derrick wants to keep chasing boxing-friendly smoothing, the next experiment should probably be something that can reject single-frame spikes while preserving onset timing better than this fixed median window did.
