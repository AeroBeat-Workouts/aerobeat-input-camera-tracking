# Prototype Matcher Fixture Benchmark

- Benchmark ID: `prototype_matcher_boxing_side_aware_v1_fixture_baseline`
- Library ID: `boxing_side_aware_v1`
- Profile: `boxing`
- Generated At: `2026-06-13T13:23:07-04:00`
- Runner: `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/scripts/run_prototype_matcher_fixture_benchmark.py`

## Aggregate

- Fixture count: **7**
- Negative controls clean: **1 / 1**

## Per Fixture

### Straight left fixture

- Fixture: `.testbed/assets/fixtures/boxing/punch_left/boxing_guard->punch_left_repeat_04_take_01.yaml`
- Source: `.testbed/assets/fixtures/boxing/punch_left/boxing_guard->punch_left_repeat_04_take_01.mp4`
- Expected event: `punch_left`
- Expected class: `straight_left`
- Attack events emitted: **0**
- did not emit expected punch_left
- peak expected-class score 0.000
- latest matcher reason step_wait

### Straight right fixture

- Fixture: `.testbed/assets/fixtures/boxing/punch_right/boxing_guard->punch_right_repeat_04_take_01.yaml`
- Source: `.testbed/assets/fixtures/boxing/punch_right/boxing_guard->punch_right_repeat_04_take_01.mp4`
- Expected event: `punch_right`
- Expected class: `straight_right`
- Attack events emitted: **0**
- did not emit expected punch_right
- peak expected-class score 0.000
- latest matcher reason step_wait

### Hook left fixture

- Fixture: `.testbed/assets/fixtures/boxing/hook_left/boxing_guard->hook_left_repeat_04_take_01.yaml`
- Source: `.testbed/assets/fixtures/boxing/hook_left/boxing_guard->hook_left_repeat_04_take_01.mp4`
- Expected event: `hook_left`
- Expected class: `hook_left`
- Attack events emitted: **0**
- did not emit expected hook_left
- peak expected-class score 0.106
- latest matcher reason window_not_full

### Hook right fixture

- Fixture: `.testbed/assets/fixtures/boxing/hook_right/boxing_guard->hook_right_repeat_04_take_01.yaml`
- Source: `.testbed/assets/fixtures/boxing/hook_right/boxing_guard->hook_right_repeat_04_take_01.mp4`
- Expected event: `hook_right`
- Expected class: `hook_right`
- Attack events emitted: **0**
- did not emit expected hook_right
- peak expected-class score 0.107
- latest matcher reason below_threshold

### Uppercut left fixture

- Fixture: `.testbed/assets/fixtures/boxing/uppercut_left/boxing_guard->uppercut_left_repeat_04_take_01.yaml`
- Source: `.testbed/assets/fixtures/boxing/uppercut_left/boxing_guard->uppercut_left_repeat_04_take_01.mp4`
- Expected event: `uppercut_left`
- Expected class: `uppercut_left`
- Attack events emitted: **0**
- did not emit expected uppercut_left
- peak expected-class score 0.000
- latest matcher reason below_threshold

### Uppercut right fixture

- Fixture: `.testbed/assets/fixtures/boxing/uppercut_right/boxing_guard->uppercut_right_repeat_04_take_01.yaml`
- Source: `.testbed/assets/fixtures/boxing/uppercut_right/boxing_guard->uppercut_right_repeat_04_take_01.mp4`
- Expected event: `uppercut_right`
- Expected class: `uppercut_right`
- Attack events emitted: **0**
- did not emit expected uppercut_right
- peak expected-class score 0.000
- latest matcher reason step_wait

### Run-in-place negative control

- Fixture: `.testbed/assets/fixtures/boxing/run_in_place/boxing_guard->run_in_place_repeat_01_take_01.yaml`
- Source: `.testbed/assets/fixtures/boxing/run_in_place/boxing_guard->run_in_place_repeat_01_take_01.mp4`
- Expected event: `None`
- Expected class: `None`
- Attack events emitted: **0**
- negative control emitted no attack events
- latest matcher reason below_threshold
