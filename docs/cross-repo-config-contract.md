# Cross-Repo Camera Tracking + Gesture Config Contract

This document locks the current cross-repo config boundary between:

- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-tool-camera-tracking`

The active system is pose-driven gameplay built on calibrated pose landmarks. Prototype matcher, learned classifier, hand-tracking overlays, and retired hook/uppercut threshold tuning are not part of the approved public contract.

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

The input repo owns gameplay meaning and pose-threshold/grid tuning. The tool repo must not parse or validate gesture fields.

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

### Shared calibration

```yaml
schema: aerobeat/gesture_detection_config
version: 1
profile: boxing|flow
calibration:
  mode: t_pose_auto
  t_pose:
    hold_ms: number
    cooldown_ms: number
    grid_bounds_padding:
      top: number
      bottom: number
      left: number
      right: number
    camera_space_grid_height_offset: number
    thresholds:
      max_wrist_shoulder_y_ratio: number
      max_elbow_shoulder_y_ratio: number
      min_elbow_angle_deg: number
```

### Boxing profile additions

```yaml
profile: boxing
guard:
  backend: threshold
squat:
  backend: grid_avoidance
  grid_avoidance:
    obstacle:
      label: string
      mode: athlete_space_height_ratio
      blocked_from_edge: top
      blocked_height_ratio: number
grid_detection:
  subgrid:
    enabled: true|false
    columns_multiplier: number
    rows_multiplier: number
    visual:
      draw_dashed_overlay: true|false
weave:
  backend: grid_avoidance
  grid_avoidance:
    left_obstacle:
      label: string
      occupied_columns: [number, ...]
      occupied_cells: [number, ...]
    right_obstacle:
      label: string
      occupied_columns: [number, ...]
      occupied_cells: [number, ...]
straight_punch:
  backend: threshold
  threshold:
    evaluation:
      fresh_samples_only: true|false
      sample_window_size: number
      window_ms: number
    thresholds:
      min_velocity: number
      max_elbow_shoulder_xy_distance: number
      max_wrist_shoulder_xy_distance: number
      min_wrist_lateral_angle_from_elbow_vertical_deg: number
    timing:
      triggered_grace_ms: number
      allow_next_gesture_capture_during_grace: true|false
    rearm:
      pose_only_rearm_ms: number
    state_machine:
      lost_tracking_reacquire_stable_ms: number
hook:
  backend: grid_detection
  grid_detection:
    evaluation:
      grid_variant: grid|subgrid
      min_column_delta: number
      overflow_protection_enabled: true|false
    timing:
      triggered_grace_ms: number
      allow_next_gesture_capture_during_grace: true|false
    rearm:
      pose_only_rearm_ms: number
    state_machine:
      lost_tracking_reacquire_stable_ms: number
uppercut:
  backend: grid_detection
  grid_detection:
    evaluation:
      grid_variant: grid|subgrid
      min_row_delta: number
      overflow_protection_enabled: true|false
    timing:
      triggered_grace_ms: number
      allow_next_gesture_capture_during_grace: true|false
    rearm:
      pose_only_rearm_ms: number
    state_machine:
      lost_tracking_reacquire_stable_ms: number
```

### Flow profile additions

```yaml
profile: flow
# No authored boxing families.
# Flow currently uses only the shared calibration surface above.
```

## Locked runtime/debug contract by profile

### Boxing runtime/debug truth

Boxing consumers may legitimately expect boxing family truth:

- `gesture_debug.guard`
- `gesture_debug.squat`
- `gesture_debug.weave`
- `gesture_debug.punch_detection`
- `gesture_debug.straight_punch`
- `gesture_debug.hook`
- `gesture_debug.uppercut`
- `gesture_debug.depth_runtime`
- shared calibrated grid truth under `gesture_debug.flow`

### Flow runtime/debug truth

Flow consumers must only rely on flow/grid surfaces, not boxing families:

- `gesture_debug.ready`
- `gesture_debug.flow.grid`
- `gesture_debug.flow.tracked_landmarks.nose`
- `gesture_debug.flow.tracked_landmarks.left_wrist`
- `gesture_debug.flow.tracked_landmarks.right_wrist`
- `gesture_debug.flow.left`
- `gesture_debug.flow.right`
- flow events `flow_left_cell_entered` and `flow_right_cell_entered`

Flow profile config/docs/tests must not rely on `guard`, `squat`, `weave`, `straight_punch`, `hook`, `uppercut`, `punch_detection`, or `depth_runtime` surfaces.

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
- Boxing guard + straight remain pose-threshold driven. Boxing squat/weave use calibrated nose-grid obstacle avoidance. Boxing hook/uppercut are calibrated grid-detection families only; retired threshold/depth config for those families is no longer public contract.
- Flow is a profile selection plus shared calibration contract. Its authored config surface does not include boxing families or a dedicated `flow.backend` block.
- A local gameplay-anchor helper (`nose`, shoulders, elbows, wrists) is allowed for input-repo-owned gesture logic, but it does not change the cross-repo frame contract: this repo still depends on upstream full-pose landmarks for tracking validity, baseline capture, lower-body metrics, and published debug state.
- Any meaningful landmark-count performance reduction therefore belongs upstream in `aerobeat-tool-camera-tracking` (or the underlying vendor/runtime layer) where inference output can actually be reduced.
- If future flow-specific authored tuning is introduced, it should land as a new explicitly approved contract slice rather than as fallback boxing behavior or dead placeholder fields.
