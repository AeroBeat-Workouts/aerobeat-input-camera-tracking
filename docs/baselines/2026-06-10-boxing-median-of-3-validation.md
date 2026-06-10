# Boxing median-of-3 validation — 2026-06-10

Repo: `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking`
Scene: `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.testbed/scenes/boxing_proving.tscn`
Profile: `boxing`
Replay fixture: `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.testbed/assets/fixtures/boxing/punch_left/boxing_guard->punch_left_repeat_04_take_01.mp4`
Reference baseline: `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/docs/baselines/2026-06-10-boxing-smoothing-baseline.md`

## What changed

Added a new explicit smoothing style, `median_of_3`, in the real pose smoothing path. It keeps the latest three landmark samples per point and returns the per-axis median once the window is warm; startup frames stay raw.

No existing smoothing mode was replaced.

## Validation method

Focused code-level validation:

- `test_landmark_smoother.gd`
- `test_pose_detector_substrate.gd`
- `test_proving_harness_trails.gd`

Replay validation used the same proving capture path as the baseline doc:

- `godot --headless --path .testbed --script res://scripts/capture_fixture_proving.gd -- ...`
- `AEROBEAT_FIXTURE_STATE_TIMELINE_MODE=full`

Artifacts:

- `/home/derrick/.openclaw/workspace/.temp/aerobeat-smoothing-median3/lite_raw-1/`
- `/home/derrick/.openclaw/workspace/.temp/aerobeat-smoothing-median3/lite_raw-2/`
- `/home/derrick/.openclaw/workspace/.temp/aerobeat-smoothing-median3/exponential_moving_average-1/`
- `/home/derrick/.openclaw/workspace/.temp/aerobeat-smoothing-median3/exponential_moving_average-2/`
- `/home/derrick/.openclaw/workspace/.temp/aerobeat-smoothing-median3/median_of_3-1/`
- `/home/derrick/.openclaw/workspace/.temp/aerobeat-smoothing-median3/median_of_3-2/`

## Replay results summary

Two captures per mode.

### Runtime cost

Mean wall / CPU / RSS stayed in the same noise-class across all three modes:

- `lite_raw`: **11.54s** wall, **31.28s** user, **9.87s** sys, **475,178 KB** RSS
- `exponential_moving_average`: **11.62s** wall, **30.72s** user, **10.40s** sys, **474,050 KB** RSS
- `median_of_3`: **11.46s** wall, **30.92s** user, **9.86s** sys, **475,292 KB** RSS

Practical read: `median_of_3` is cheap enough. Runtime cost was effectively flat.

### Responsiveness proxy

Using the same `provider_started -> first punch_left` proxy:

- `lite_raw`: **625.0 ms** mean
- `exponential_moving_average`: **647.5 ms** mean
- `median_of_3`: **674.0 ms** mean

Added lag versus `lite_raw`:

- `median_of_3`: **+49.0 ms** mean

Added lag versus EMA:

- `median_of_3`: **+26.5 ms** mean

That keeps `median_of_3` barely inside the baseline doc's ideal upper bound, but it is not faster than the EMA experiment.

### Guard jitter proxy

Using guard-active standard deviation from the captured state timeline:

#### Wrist separation X jitter

- `lite_raw`: **0.010417**
- `exponential_moving_average`: **0.010338**
- `median_of_3`: **0.010832**

Change:

- `median_of_3` vs raw: **+3.98%** worse
- `median_of_3` vs EMA: **+4.78%** worse

#### Wrist separation Y jitter

- `lite_raw`: **0.026135**
- `exponential_moving_average`: **0.025309**
- `median_of_3`: **0.025498**

Change:

- `median_of_3` vs raw: **-2.44%** better
- `median_of_3` vs EMA: **+0.75%** worse

#### Left wrist-to-nose distance jitter

- `lite_raw`: **0.018622**
- `exponential_moving_average`: **0.018591**
- `median_of_3`: **0.018662**

Change:

- `median_of_3` vs raw: **+0.22%** worse
- `median_of_3` vs EMA: **+0.38%** worse

#### Right wrist-to-nose distance jitter

- `lite_raw`: **0.007932**
- `exponential_moving_average`: **0.008031**
- `median_of_3`: **0.007940**

Change:

- `median_of_3` vs raw: **+0.10%** worse
- `median_of_3` vs EMA: **-1.14%** better

## Conclusion

`median_of_3` did **not** achieve the target envelope from the baseline note.

What it did accomplish:

- cost stayed effectively flat
- the implementation is simple and low-risk
- the mode is now available end-to-end for further experiments

What it did **not** accomplish:

- no ~15% class visible jitter reduction showed up in the replay guard metrics
- most guard jitter proxies were effectively flat or slightly worse than `lite_raw`
- it was also not better than the EMA experiment on jitter
- it added about **+49 ms** first-hit lag versus current `lite_raw`

Bottom line:

> `median_of_3` is cheap, but in this boxing replay it does **not** materially improve jitter relative to either `lite_raw` or the EMA experiment, and it introduces some added onset delay without earning that cost.
