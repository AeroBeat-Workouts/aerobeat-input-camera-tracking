# Adaptive EMA boxing validation — 2026-06-10

Repo: `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking`
Scene: `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.testbed/scenes/boxing_proving.tscn`
Profile: `boxing`
Replay fixture: `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.testbed/assets/fixtures/boxing/punch_left/boxing_guard->punch_left_repeat_04_take_01.mp4`
Baseline envelope: `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/docs/baselines/2026-06-10-boxing-smoothing-baseline.md`
Prior EMA experiment: `.plans/2026-06-10-lite-raw-smoothing-improvement.md`

## What changed

Implemented one new explicit pose smoothing style:

- `adaptive_exponential_moving_average`

This stays in the repo-owned post-pose smoothing path, keeps the vendor runtime in the same low-complexity / raw-filter lane as `lite_raw`, and adapts the EMA alpha from landmark motion magnitude:

- low motion → stronger smoothing (`alpha` floors at `0.18`)
- high motion → quick relaxation (`alpha` caps at `0.82`)
- motion estimate uses consecutive raw landmark deltas so punch onset can break out quickly instead of keying off an already-lagged smoothed sample

## Validation method

Focused validation covered:

- unit/runtime path tests for `LandmarkSmoother`, `PoseDetectorSubstrate`, and proving-harness config resolution
- replay captures for three modes using the existing boxing proving-scene fixture path:
  - `lite_raw`
  - `exponential_moving_average`
  - `adaptive_exponential_moving_average`

Artifact root:

- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.temp/adaptive-ema-validation-20260610-181511`

Each run directory contains:

- `report.json`
- `report.md`
- `time.txt`
- `stdout.log`
- `stderr.log`

## Focused automated validation

Passed:

- `godot --headless --path .testbed --script addons/aerobeat-vendor-godot-unit-test/gut_cmdln.gd -gtest=res://tests/unit/test_landmark_smoother.gd,res://tests/unit/test_pose_detector_substrate.gd,res://tests/unit/test_proving_harness_trails.gd,res://tests/unit/test_boxing_proving_harness_profiles_and_debug.gd -gexit`

## Replay capture summary

### Performance

Mean of two captures per mode:

- `lite_raw`
  - wall: `9.20s`
  - user CPU: `23.30s`
  - sys CPU: `7.55s`
  - max RSS: `471594 KB`
  - approx pose rate: `27.6 Hz`
- `exponential_moving_average`
  - wall: `9.17s`
  - user CPU: `23.34s`
  - sys CPU: `7.56s`
  - max RSS: `472878 KB`
  - approx pose rate: `27.6 Hz`
- `adaptive_exponential_moving_average`
  - wall: `9.23s`
  - user CPU: `23.33s`
  - sys CPU: `7.76s`
  - max RSS: `472218 KB`
  - approx pose rate: `27.5 Hz`

Read: adaptive EMA stayed essentially flat versus current `lite_raw` on the replay path. Relative to `lite_raw`, it was about `+0.04s` wall, `+0.03s` user CPU, `+0.21s` sys CPU, and `+624 KB` RSS. That stays inside the baseline cost envelope.

### First-hit responsiveness proxy

Using `provider_started -> first punch_left` from the captured event timeline:

- `lite_raw`: `635.0 ms`
- `exponential_moving_average`: `575.0 ms` (`-60.0 ms` vs raw)
- `adaptive_exponential_moving_average`: `611.5 ms` (`-23.5 ms` vs raw, `+36.5 ms` vs fresh EMA rerun)

Read: adaptive EMA stayed well inside the baseline lag envelope. In this rerun it was actually `23.5 ms` earlier than `lite_raw`, which is replay noise rather than evidence of “negative lag”, but the important part is that it did **not** drift into `lite_filtered`-class sluggishness. It also landed almost exactly on the prior EMA experiment’s single-run first-hit result (`~612 ms` in `.plans/2026-06-10-lite-raw-smoothing-improvement.md`).

### Guard-hold jitter proxy

Using guard-active samples from the captured state timeline (lower is better):

#### Wrist separation X stddev

- `lite_raw`: `0.010478`
- `exponential_moving_average`: `0.010230` (`-2.4%` vs raw)
- `adaptive_exponential_moving_average`: `0.010476` (`-0.0%` vs raw, `+2.4%` vs fresh EMA)

#### Wrist separation Y stddev

- `lite_raw`: `0.027667`
- `exponential_moving_average`: `0.027743` (`+0.3%` vs raw)
- `adaptive_exponential_moving_average`: `0.027037` (`-2.3%` vs raw, `-2.5%` vs fresh EMA)

#### Left wrist-to-nose distance stddev

- `lite_raw`: `0.018960`
- `exponential_moving_average`: `0.018929` (`-0.2%` vs raw)
- `adaptive_exponential_moving_average`: `0.018835` (`-0.7%` vs raw, `-0.5%` vs fresh EMA)

#### Right wrist-to-nose distance stddev

- `lite_raw`: `0.008232`
- `exponential_moving_average`: `0.008275` (`+0.5%` vs raw)
- `adaptive_exponential_moving_average`: `0.008389` (`+1.9%` vs raw, `+1.4%` vs fresh EMA)

Read: adaptive EMA did **not** produce the hoped-for ~15%+ visible jitter reduction. On this fixture rerun it was basically flat versus raw on the lateral separation metric (`~0.0%`), improved one metric modestly (`wrist separation Y` at `-2.3%`), barely improved left wrist-to-nose (`-0.7%`), and regressed right wrist-to-nose (`+1.9%`).

Compared with the fresh EMA rerun, adaptive EMA was mixed rather than better overall: it cleaned up `wrist separation Y` more, but it was worse on `wrist separation X`, slightly worse on left wrist-to-nose, and more noticeably worse on right wrist-to-nose.

Compared with the earlier EMA experiment note in `.plans/2026-06-10-lite-raw-smoothing-improvement.md`, adaptive EMA also fails the “material improvement” bar: the earlier EMA pass already showed only small jitter movement, and adaptive EMA still does not climb into the baseline target neighborhood of roughly `15%+` cleaner guard-hold jitter.

## Bottom line

`adaptive_exponential_moving_average` is correctly integrated, cheap, and boxing-safe on lag, but this capture pass does **not** support promoting it as the answer.

- **Performance:** acceptable / essentially flat versus `lite_raw`
- **Lag:** acceptable / stayed within the desired envelope and avoided `lite_filtered`-class sluggishness
- **Jitter:** **not** a material improvement versus `lite_raw`
- **Versus prior EMA experiment:** roughly the same onset timing class, but still not a meaningful jitter win

If Derrick wants to keep chasing boxing-friendly smoothing after this, the next slice probably needs a smarter low-cost scheme than “motion-adaptive scalar EMA alpha” alone — something that suppresses idle guard tremor more selectively without letting bilateral wrist-to-face geometry wander.
