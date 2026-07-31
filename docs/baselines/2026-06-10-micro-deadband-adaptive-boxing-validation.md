# Micro-deadband adaptive boxing validation — 2026-06-10

Repo: `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking`
Scene: `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.testbed/scenes/boxing_proving.tscn`
Profile: `boxing`
Replay fixture: `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.testbed/assets/fixtures/boxing/straight_left/boxing_guard->straight_left_repeat_04_take_01.mp4`
Baseline envelope: `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/docs/baselines/2026-06-10-boxing-smoothing-baseline.md`
Fresh comparison captures: `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.temp/adaptive-ema-validation-20260610-181511`
Micro-deadband captures: `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.temp/micro-deadband-validation-20260610-185717`

## What changed

Implemented one new explicit pose smoothing style:

- `micro_deadband_adaptive`

This stays in the repo-owned post-pose smoothing path and keeps the vendor runtime in the same low-complexity / raw-filter lane as `lite_raw`.

The filter is intentionally cheap:

- use a motion-adaptive micro deadband on `x` / `y`
- fully hold tiny lateral guard wobble inside the deadband
- when motion exceeds the deadband, pass motion through immediately minus only the deadband shave
- leave `z` raw so punch onset does not inherit extra forward-axis lag

In plain English: it tries to kill tiny always-on sideways tremor without turning punch breakout into syrup.

## Focused automated validation

Passed:

- `godot --headless --path .testbed --script addons/aerobeat-vendor-godot-unit-test/gut_cmdln.gd -gtest=res://tests/unit/test_landmark_smoother.gd,res://tests/unit/test_pose_detector_substrate.gd,res://tests/unit/test_proving_harness_trails.gd,res://tests/unit/test_boxing_proving_harness_profiles_and_debug.gd -gexit`

## Replay capture summary

Mean of two captures per mode:

### Performance

- `lite_raw`
  - wall: `9.20s`
  - user CPU: `23.30s`
  - sys CPU: `7.55s`
  - max RSS: `471594 KB`
- `exponential_moving_average`
  - wall: `9.17s`
  - user CPU: `23.34s`
  - sys CPU: `7.56s`
  - max RSS: `472878 KB`
- `adaptive_exponential_moving_average`
  - wall: `9.23s`
  - user CPU: `23.33s`
  - sys CPU: `7.76s`
  - max RSS: `472218 KB`
- `micro_deadband_adaptive`
  - wall: `9.06s`
  - user CPU: `23.27s`
  - sys CPU: `7.62s`
  - max RSS: `472184 KB`

Read: `micro_deadband_adaptive` stayed essentially flat versus `lite_raw` on replay cost. There is no sign of a meaningful runtime regression.

### First-hit responsiveness proxy

Using `provider_started -> first straight_left` from the captured event timeline:

- `lite_raw`: `635.0 ms`
- `exponential_moving_average`: `575.0 ms` (`-60.0 ms` vs raw)
- `adaptive_exponential_moving_average`: `611.5 ms` (`-23.5 ms` vs raw)
- `micro_deadband_adaptive`: `598.0 ms` (`-37.0 ms` vs raw, `-13.5 ms` vs adaptive EMA)

Read: this style stayed comfortably inside the lag envelope. It did **not** drift into `lite_filtered`-class sluggishness.

### Guard-hold jitter proxy

Using guard-active samples from the captured state timeline (lower is better):

#### Wrist separation X stddev

- `lite_raw`: `0.010478`
- `exponential_moving_average`: `0.010230` (`-2.4%` vs raw)
- `adaptive_exponential_moving_average`: `0.010476` (`-0.0%` vs raw)
- `micro_deadband_adaptive`: `0.010402` (`-0.7%` vs raw, `-0.6%` vs adaptive EMA)

#### Wrist separation Y stddev

- `lite_raw`: `0.027667`
- `exponential_moving_average`: `0.027743` (`+0.3%` vs raw)
- `adaptive_exponential_moving_average`: `0.027037` (`-2.3%` vs raw)
- `micro_deadband_adaptive`: `0.027273` (`-1.4%` vs raw, `+0.9%` vs adaptive EMA)

#### Left wrist-to-nose distance stddev

- `lite_raw`: `0.018960`
- `exponential_moving_average`: `0.018929` (`-0.2%` vs raw)
- `adaptive_exponential_moving_average`: `0.018835` (`-0.7%` vs raw)
- `micro_deadband_adaptive`: `0.018992` (`+0.2%` vs raw, `+0.8%` vs adaptive EMA)

#### Right wrist-to-nose distance stddev

- `lite_raw`: `0.008232`
- `exponential_moving_average`: `0.008275` (`+0.5%` vs raw)
- `adaptive_exponential_moving_average`: `0.008389` (`+1.9%` vs raw)
- `micro_deadband_adaptive`: `0.008362` (`+1.6%` vs raw, `-0.3%` vs adaptive EMA)

## Bottom line

`micro_deadband_adaptive` is correctly integrated, cheap, and boxing-safe on lag, but this replay pass does **not** support calling it a successful jitter answer.

- **Performance:** acceptable / essentially flat versus `lite_raw`
- **Lag:** acceptable / stayed well within the desired envelope
- **Jitter:** **not** a material improvement versus `lite_raw`
- **Versus fresh EMA/adaptive-EMA experiments:** mixed and still small; no metric came close to the target neighborhood of roughly `15%+` cleaner guard-hold jitter

Best metric movement was only about:

- `-0.7%` on wrist separation X versus raw
- `-1.4%` on wrist separation Y versus raw

Those are real numbers, but they are nowhere near the “visibly cleaner” bar captured in the baseline. So this experiment is a safe low-latency option mechanically, but not a promotion candidate for the boxing profile.
