# Cross-Repo Camera Tracking + Gesture Config Contract

This document locks the current cross-repo config boundary between:

- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-tool-camera-tracking`

The active system is pose-driven threshold detection only. Prototype matcher, learned classifier, hand-tracking overlays, and boxing depth-tuning config are no longer part of the approved public contract in this repo.

## Canonical config files

These six files are the approved profile config surfaces in the input repo:

- `assets/boxing.camera_tracking.yaml`
- `assets/flow.camera_tracking.yaml`
- `assets/boxing.gesture_detection.yaml`
- `assets/flow.gesture_detection.yaml`
- `assets/boxing.testbed_debug.yaml`
- `assets/flow.testbed_debug.yaml`

All paths are repo-root relative within `aerobeat-input-camera-tracking`.

## Ownership split

### Tracker-facing config layer

- **Schema header:** `schema: aerobeat/camera_tracking_config`
- **Version:** `version: 1`
- **Profiles:** `profile: boxing` or `profile: flow`
- **Authoritative files:** `*.camera_tracking.yaml`
- **Parsing + validation owner:** `aerobeat-tool-camera-tracking`
- **Selection owner:** `aerobeat-input-camera-tracking`

The input repo chooses which tracker profile file to load and pass downstream. The tool repo owns parsing, normalization, defaults, and schema enforcement for tracker behavior.

### Gesture/gameplay config layer

- **Schema header:** `schema: aerobeat/gesture_detection_config`
- **Version:** `version: 1`
- **Profiles:** `profile: boxing` or `profile: flow`
- **Authoritative files:** `*.gesture_detection.yaml`
- **Parsing + validation owner:** `aerobeat-input-camera-tracking`

The input repo owns gameplay meaning and pose-threshold tuning. The tool repo must not parse or validate gesture fields.

### Proving/testbed debug layer

- **Schema header:** `schema: aerobeat/testbed_debug_config`
- **Version:** `version: 1`
- **Profiles:** `profile: boxing` or `profile: flow`
- **Authoritative files:** `*.testbed_debug.yaml`
- **Parsing + validation owner:** `aerobeat-input-camera-tracking`

The active proving contract only covers pose-landmark visibility plus refresh cadence for the live debug UI. Hand bbox/trail overlays and depth-debug toggles are retired from the committed contract.

## Locked tracker schema (active public fields)

```yaml
schema: aerobeat/camera_tracking_config
version: 1
profile: boxing|flow
source:
  live_camera:
    requested_width: 960
    requested_height: 540
    requested_fps: 15|60
  replay:
    input_kind: video_file|session_manifest
    video_input_path: ""
    session_manifest_path: ""
preview:
  surface_mode: attach
  flip_horizontal: true|false
  live:
    enabled: true
    max_fps: 10|60
    width: 960
    height: 540
    quality: 75
  replay:
    enabled: true
    max_fps: 10|60
    width: 960
    height: 540
    quality: 75
  overlays:
    pose_skeleton_visible: true
tracking:
  max_fps: 30
  state_update_max_fps: 10|30
  pose:
    enabled: true
    inference_interval_frames: 1
    smoothing_style: lite_filtered|lite_raw
```

Public tracker truth in this repo is pose-only. No hand-tracking fields are required by the active contract.

## Locked gesture schema (active public fields)

### Boxing

```yaml
schema: aerobeat/gesture_detection_config
version: 1
profile: boxing
guard:
  backend: threshold
squat:
  backend: grid_avoidance
  grid_avoidance:
    obstacle:
      label: top_row
      occupied_rows: [0]
      occupied_cells: [0, 1, 2, 3]
weave:
  backend: grid_avoidance
  grid_avoidance:
    left_obstacle:
      label: left_columns
      occupied_columns: [0, 1]
      occupied_cells: [0, 1, 4, 5, 8, 9]
    right_obstacle:
      label: right_columns
      occupied_columns: [2, 3]
      occupied_cells: [2, 3, 6, 7, 10, 11]
straight_punch:
  backend: threshold
  threshold:
    evaluation:
      fresh_samples_only: true
      sample_window_size: 4
      min_positive_growth_samples: 1
      window_ms: 250
    thresholds:
      min_velocity: number
      min_bbox_area_growth: number
      max_elbow_shoulder_xy_distance: number
      min_wrist_lateral_angle_from_elbow_vertical_deg: number
    timing:
      triggered_grace_ms: number
    rearm:
      bbox_area_retract_epsilon: number
      pose_only_rearm_ms: number
    state_machine:
      lost_tracking_reacquire_stable_ms: number
hook:
  backend: threshold
  threshold:
    evaluation:
      window_ms: 250
    thresholds:
      min_velocity: number
      max_wrist_angle_from_elbow_horizontal_deg: number
uppercut:
  backend: threshold
  threshold:
    evaluation:
      window_ms: 250
    thresholds:
      min_velocity: number
      max_wrist_angle_from_elbow_vertical_deg: number
```

### Flow

```yaml
schema: aerobeat/gesture_detection_config
version: 1
profile: flow
flow:
  backend: threshold
  threshold:
    stance:
      min_vertical_separation: number
    cell_transition:
      min_normalized_distance: number
      min_shoulder_width_ratio: number
    direction:
      min_axis_velocity: number
      min_stability_samples: number
```

## Locked testbed debug schema (active public fields)

```yaml
schema: aerobeat/testbed_debug_config
version: 1
profile: boxing|flow
visuals:
  show_landmarks: true|false
  show_landmark_hit_targets: true|false
  show_landmark_hit_target_labels: true|false
refresh:
  debug_panel_refresh_interval_ms: number
  inspector_live_refresh_interval_ms: number
```

## Contract notes

- `preview.overlays.pose_skeleton_visible` is the only committed overlay intent still carried in profile config.
- Boxing guard + punch families remain threshold-driven, but Boxing squat/weave now use calibrated nose-grid obstacle avoidance (`grid_avoidance`) instead of body-mechanics threshold tuning. Flow still exposes the calibrated 4x3 cell occupancy + direction contract under the `flow` family rather than a `squat` gesture surface.
- If depth proving or hand-tracking debug ever returns, it should land as a new explicitly approved contract slice rather than lingering as undocumented legacy fields.
