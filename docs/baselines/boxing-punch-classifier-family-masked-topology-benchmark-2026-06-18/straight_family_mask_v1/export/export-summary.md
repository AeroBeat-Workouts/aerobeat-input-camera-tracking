# Boxing Punch Classifier Export

- Exported at: `2026-06-18T13:52:29.743444+00:00`
- Manifest: `.testbed/assets/benchmarks/boxing_punch_classifier_v1.benchmark.json`
- Capture dir: `.temp/boxing-punch-classifier-export/hardened-captures-2026-06-16`
- Snapshot ID: `none`
- Snapshot manifest: `none`
- Class order: `straight_left, straight_right, no_punch`
- Split strategy: `chronological_holdout_v1`
- Window shape: `8 frames x 22 features/frame`
- Samples: **80**
- Label counts: `{"no_punch": 72, "straight_left": 4, "straight_right": 4}`
- Split counts: `{"test": 29, "train": 67}`
- Sample kinds: `{"annotated_punch_window": 24, "derived_no_punch_window": 48, "transition_after_punch": 4, "transition_before_punch": 20}`
- No-punch contexts: `{"non_punch_fixture_background": 35, "punch_fixture_background": 13, "transition_after_punch": 4, "transition_before_punch": 20}`
- Mask profile: `straight_family_mask_v1`
- Active side features: `["shoulder_x", "shoulder_y", "elbow_x", "elbow_y", "wrist_x", "wrist_y", "combined_elbow_wrist_velocity_xy_magnitude", "elbow_shoulder_xy_distance_over_shoulder_width", "elbow_x_from_shoulder_over_shoulder_width", "elbow_y_from_shoulder_over_shoulder_width", "elbow_shoulder_radial_velocity_over_shoulder_width"]`
- Masked side features: `["camera_wrist_signed_vx", "camera_wrist_signed_vy", "camera_wrist_direction_none", "camera_wrist_direction_up", "camera_wrist_direction_down", "camera_wrist_direction_left", "camera_wrist_direction_right", "body_wrist_signed_vx", "body_wrist_signed_vy", "body_wrist_direction_none", "body_wrist_direction_up", "body_wrist_direction_down", "body_wrist_direction_left", "body_wrist_direction_right"]`
- Derived from feature set: `family_combined_directional_v1`
- Derived from frame feature count: **50**
- Derived from sample count: **96**

## Frozen source snapshot

- No explicit frozen snapshot manifest supplied.

## Alignment summary

- Capture time-origin offset ms (min/mean/max): **1056 / 1107.0 / 1136**
- Window start alignment error ms (min/mean/max): **0 / 18.5 / 59**
- Window end alignment error ms (min/mean/max): **0 / 18.6 / 149**

- `hook_left_fixture` offset=1080ms start_err=18.8ms end_err=16.1ms samples=10
- `hook_right_fixture` offset=1131ms start_err=11.1ms end_err=21.2ms samples=10
- `knee_left_fixture` offset=1133ms start_err=24.7ms end_err=12.3ms samples=3
- `knee_right_fixture` offset=1130ms start_err=22.7ms end_err=26.3ms samples=3
- `leg_lift_left_fixture` offset=1081ms start_err=32.0ms end_err=12.3ms samples=3
- `leg_lift_right_fixture` offset=1082ms start_err=24.3ms end_err=6.3ms samples=3
- `run_in_place_fixture` offset=1129ms start_err=14.5ms end_err=7.5ms samples=2
- `sidestep_left_fixture` offset=1083ms start_err=16.7ms end_err=9.7ms samples=3
- `sidestep_right_fixture` offset=1087ms start_err=22.0ms end_err=48.0ms samples=4
- `squat_fixture` offset=1079ms start_err=18.3ms end_err=15.0ms samples=3
- `stance_transition_fixture` offset=1133ms start_err=16.8ms end_err=5.2ms samples=4
- `straight_left_fixture` offset=1056ms start_err=18.8ms end_err=14.1ms samples=10
- `straight_right_fixture` offset=1131ms start_err=14.5ms end_err=19.0ms samples=11
- `uppercut_left_fixture` offset=1136ms start_err=24.9ms end_err=19.7ms samples=10
- `uppercut_right_fixture` offset=1130ms start_err=16.8ms end_err=29.2ms samples=10
- `weave_left_fixture` offset=1088ms start_err=15.3ms end_err=12.0ms samples=3
- `weave_right_fixture` offset=1084ms start_err=17.8ms end_err=15.8ms samples=4

## Fixture export summary

### straight_left_fixture
- Fixture YAML: `.testbed/assets/fixtures/boxing/straight_left/boxing_guard->straight_left_repeat_04_take_01.yaml`
- Source video: `.testbed/assets/fixtures/boxing/straight_left/boxing_guard->straight_left_repeat_04_take_01.mp4`
- Retained feature snapshots: **235**
- Annotated punch windows: **4**
- Background no-punch candidates: **16**
- Transition no-punch candidates: **8**

### straight_right_fixture
- Fixture YAML: `.testbed/assets/fixtures/boxing/straight_right/boxing_guard->straight_right_repeat_04_take_01.yaml`
- Source video: `.testbed/assets/fixtures/boxing/straight_right/boxing_guard->straight_right_repeat_04_take_01.mp4`
- Retained feature snapshots: **237**
- Annotated punch windows: **4**
- Background no-punch candidates: **18**
- Transition no-punch candidates: **8**

### hook_left_fixture
- Fixture YAML: `.testbed/assets/fixtures/boxing/hook_left/boxing_guard->hook_left_repeat_04_take_01.yaml`
- Source video: `.testbed/assets/fixtures/boxing/hook_left/boxing_guard->hook_left_repeat_04_take_01.mp4`
- Retained feature snapshots: **217**
- Annotated punch windows: **4**
- Background no-punch candidates: **20**
- Transition no-punch candidates: **8**

### hook_right_fixture
- Fixture YAML: `.testbed/assets/fixtures/boxing/hook_right/boxing_guard->hook_right_repeat_04_take_01.yaml`
- Source video: `.testbed/assets/fixtures/boxing/hook_right/boxing_guard->hook_right_repeat_04_take_01.mp4`
- Retained feature snapshots: **218**
- Annotated punch windows: **4**
- Background no-punch candidates: **19**
- Transition no-punch candidates: **8**

### uppercut_left_fixture
- Fixture YAML: `.testbed/assets/fixtures/boxing/uppercut_left/boxing_guard->uppercut_left_repeat_04_take_01.yaml`
- Source video: `.testbed/assets/fixtures/boxing/uppercut_left/boxing_guard->uppercut_left_repeat_04_take_01.mp4`
- Retained feature snapshots: **222**
- Annotated punch windows: **4**
- Background no-punch candidates: **16**
- Transition no-punch candidates: **7**

### uppercut_right_fixture
- Fixture YAML: `.testbed/assets/fixtures/boxing/uppercut_right/boxing_guard->uppercut_right_repeat_04_take_01.yaml`
- Source video: `.testbed/assets/fixtures/boxing/uppercut_right/boxing_guard->uppercut_right_repeat_04_take_01.mp4`
- Retained feature snapshots: **217**
- Annotated punch windows: **4**
- Background no-punch candidates: **15**
- Transition no-punch candidates: **8**

### run_in_place_fixture
- Fixture YAML: `.testbed/assets/fixtures/boxing/run_in_place/boxing_guard->run_in_place_repeat_01_take_01.yaml`
- Source video: `.testbed/assets/fixtures/boxing/run_in_place/boxing_guard->run_in_place_repeat_01_take_01.mp4`
- Retained feature snapshots: **234**
- Annotated punch windows: **0**
- Background no-punch candidates: **18**
- Transition no-punch candidates: **0**

### weave_left_fixture
- Fixture YAML: `.testbed/assets/fixtures/boxing/weave_left/boxing_guard->weave_left_repeat_04_take_01.yaml`
- Source video: `.testbed/assets/fixtures/boxing/weave_left/boxing_guard->weave_left_repeat_04_take_01.mp4`
- Retained feature snapshots: **224**
- Annotated punch windows: **0**
- Background no-punch candidates: **28**
- Transition no-punch candidates: **0**

### weave_right_fixture
- Fixture YAML: `.testbed/assets/fixtures/boxing/weave_right/boxing_guard->weave_right_repeat_04_take_01.yaml`
- Source video: `.testbed/assets/fixtures/boxing/weave_right/boxing_guard->weave_right_repeat_04_take_01.mp4`
- Retained feature snapshots: **225**
- Annotated punch windows: **0**
- Background no-punch candidates: **26**
- Transition no-punch candidates: **0**

### squat_fixture
- Fixture YAML: `.testbed/assets/fixtures/boxing/squat/boxing_guard->squat_repeat_04_take_01.yaml`
- Source video: `.testbed/assets/fixtures/boxing/squat/boxing_guard->squat_repeat_04_take_01.mp4`
- Retained feature snapshots: **229**
- Annotated punch windows: **0**
- Background no-punch candidates: **28**
- Transition no-punch candidates: **0**

### sidestep_left_fixture
- Fixture YAML: `.testbed/assets/fixtures/boxing/sidestep_left/boxing_guard->sidestep_left_repeat_04_take_01.yaml`
- Source video: `.testbed/assets/fixtures/boxing/sidestep_left/boxing_guard->sidestep_left_repeat_04_take_01.mp4`
- Retained feature snapshots: **228**
- Annotated punch windows: **0**
- Background no-punch candidates: **28**
- Transition no-punch candidates: **0**

### sidestep_right_fixture
- Fixture YAML: `.testbed/assets/fixtures/boxing/sidestep_right/boxing_guard->sidestep_right_repeat_03_take_01.yaml`
- Source video: `.testbed/assets/fixtures/boxing/sidestep_right/boxing_guard->sidestep_right_repeat_03_take_01.mp4`
- Retained feature snapshots: **222**
- Annotated punch windows: **0**
- Background no-punch candidates: **28**
- Transition no-punch candidates: **0**

### leg_lift_left_fixture
- Fixture YAML: `.testbed/assets/fixtures/boxing/leg_lift_left/boxing_guard->leg_lift_left_repeat_04_take_01.yaml`
- Source video: `.testbed/assets/fixtures/boxing/leg_lift_left/boxing_guard->leg_lift_left_repeat_04_take_01.mp4`
- Retained feature snapshots: **230**
- Annotated punch windows: **0**
- Background no-punch candidates: **28**
- Transition no-punch candidates: **0**

### leg_lift_right_fixture
- Fixture YAML: `.testbed/assets/fixtures/boxing/leg_lift_right/boxing_guard->leg_lift_right_repeat_04_take_01.yaml`
- Source video: `.testbed/assets/fixtures/boxing/leg_lift_right/boxing_guard->leg_lift_right_repeat_04_take_01.mp4`
- Retained feature snapshots: **226**
- Annotated punch windows: **0**
- Background no-punch candidates: **28**
- Transition no-punch candidates: **0**

### knee_left_fixture
- Fixture YAML: `.testbed/assets/fixtures/boxing/knee_left/boxing_guard->knee_left_repeat_04_take_01.yaml`
- Source video: `.testbed/assets/fixtures/boxing/knee_left/boxing_guard->knee_left_repeat_04_take_01.mp4`
- Retained feature snapshots: **222**
- Annotated punch windows: **0**
- Background no-punch candidates: **24**
- Transition no-punch candidates: **0**

### knee_right_fixture
- Fixture YAML: `.testbed/assets/fixtures/boxing/knee_right/boxing_guard->knee_right_repeat_04_take_01.yaml`
- Source video: `.testbed/assets/fixtures/boxing/knee_right/boxing_guard->knee_right_repeat_04_take_01.mp4`
- Retained feature snapshots: **221**
- Annotated punch windows: **0**
- Background no-punch candidates: **26**
- Transition no-punch candidates: **0**

### stance_transition_fixture
- Fixture YAML: `.testbed/assets/fixtures/boxing/stance_transition/boxing_guard->orthodox->center->southpaw_repeat_04_take_01.yaml`
- Source video: `.testbed/assets/fixtures/boxing/stance_transition/boxing_guard->orthodox->center->southpaw_repeat_04_take_01.mp4`
- Retained feature snapshots: **229**
- Annotated punch windows: **0**
- Background no-punch candidates: **27**
- Transition no-punch candidates: **0**

## Threshold baseline on exported windows

### train
- Accuracy: **0.782**
- Macro F1: **0.293**
- Macro precision: **0.293**
- Macro recall: **0.293**

| actual \ predicted | straight_left | straight_right | no_punch |
| --- | --- | --- | --- |
| straight_left | 0 | 0 | 3 |
| straight_right | 0 | 0 | 3 |
| no_punch | 5 | 1 | 43 |

### test
- Accuracy: **0.840**
- Macro F1: **0.304**
- Macro precision: **0.304**
- Macro recall: **0.304**

| actual \ predicted | straight_left | straight_right | no_punch |
| --- | --- | --- | --- |
| straight_left | 0 | 0 | 1 |
| straight_right | 0 | 0 | 1 |
| no_punch | 1 | 1 | 21 |
