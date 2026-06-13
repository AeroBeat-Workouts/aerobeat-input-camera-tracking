# Cross-Repo Camera Tracking + Gesture Config Contract

This document locks the v1 config boundary between:

- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-tool-camera-tracking`

## Canonical config files

These four files are the only approved v1 profile config filenames and locations in the input repo:

- `assets/boxing.camera_tracking.yaml`
- `assets/flow.camera_tracking.yaml`
- `assets/boxing.gesture_detection.yaml`
- `assets/flow.gesture_detection.yaml`

The paths are repo-root relative within `aerobeat-input-camera-tracking`.

## Ownership split

### Tracker-facing config layer

- **Schema header:** `schema: aerobeat/camera_tracking_config`
- **Version:** `version: 1`
- **Profiles:** `profile: boxing` or `profile: flow`
- **Authoritative files:** `*.camera_tracking.yaml`
- **Parsing owner:** `aerobeat-tool-camera-tracking`
- **Validation owner:** `aerobeat-tool-camera-tracking`
- **Selection owner:** `aerobeat-input-camera-tracking`
- **Consumer boundary:** downstream repos may pass this config into the tool layer, but the tool layer owns field normalization and rejection of invalid tracker fields.

The input repo chooses which tracker profile file to load and pass downstream. The tool repo owns parsing, normalization, defaults, and schema enforcement for tracker behavior.

### Gesture/gameplay config layer

- **Schema header:** `schema: aerobeat/gesture_detection_config`
- **Version:** `version: 1`
- **Profiles:** `profile: boxing` or `profile: flow`
- **Authoritative files:** `*.gesture_detection.yaml`
- **Parsing owner:** `aerobeat-input-camera-tracking`
- **Validation owner:** `aerobeat-input-camera-tracking`
- **Consumer boundary:** gameplay interpretation only. `aerobeat-tool-camera-tracking` must not parse or validate gesture fields.

The input repo owns boxing/flow gameplay meaning, boxing straight-punch tuning, and any future non-tracker gesture interpretation rules.

## Locked v1 tracker schema

```yaml
schema: aerobeat/camera_tracking_config
version: 1
profile: boxing|flow
source:
  live_camera:
    requested_width: 960
    requested_height: 540
    requested_fps: 15
  replay:
    input_kind: video_file|session_manifest
    video_input_path: ""
    session_manifest_path: ""
preview:
  surface_mode: attach
  flip_horizontal: true
  live:
    enabled: true
    max_fps: 10
    width: 960
    height: 540
    quality: 75
  replay:
    enabled: true
    max_fps: 10
    width: 960
    height: 540
    quality: 75
  overlays:
    pose_skeleton_visible: true
    hand_bbox_visible: true|false
tracking:
  max_fps: 30
  # Requested cap for runtime state/debug publication. Replay/live preview publication follows preview.*.max_fps independently, subject to source/runtime limits.
  state_update_max_fps: 30
  pose:
    enabled: true
    inference_interval_frames: 1
    smoothing_style: lite_filtered
  hands:
    enabled: true|false
    landmark_mode: lite
    inference_interval_frames: 1
    bbox:
      enabled: true
    association:
      prefer_existing_pose_side_binding: true
      nearest_wrist_fallback: true
    validity:
      max_stale_ms: 80
      reacquire_stable_ms: 40
```

### Locked tracker field ownership

- `source.live_camera.*` = live camera request knobs owned by `aerobeat-tool-camera-tracking`
- `source.replay.input_kind` = public replay selector for direct video replay vs saved-session manifest replay, owned by `aerobeat-input-camera-tracking` and passed into the tool layer
- `source.replay.video_input_path` = public direct-video replay path owned by `aerobeat-input-camera-tracking` and passed into the tool layer
- `source.replay.session_manifest_path` = public saved-session manifest replay path owned by `aerobeat-input-camera-tracking` and passed into the tool layer
- `preview.live.*` = live preview feed knobs owned by `aerobeat-tool-camera-tracking`
- `preview.replay.*` = replay preview feed knobs owned by `aerobeat-tool-camera-tracking`
- `preview.overlays.pose_skeleton_visible` = public presentation intent consumed by the input proving surfaces
- `preview.overlays.hand_bbox_visible` = public presentation intent consumed by the input proving surfaces
- `tracking.pose.*` = tracker/runtime behavior owned by `aerobeat-tool-camera-tracking`
- `tracking.hands.*` = tracker/runtime behavior owned by `aerobeat-tool-camera-tracking`
- `tracking.hands.association.*` = hand-to-side binding behavior owned by `aerobeat-tool-camera-tracking`
- `tracking.hands.validity.*` = tracking freshness/reacquire rules owned by `aerobeat-tool-camera-tracking`

### Locked tracker defaults by profile

#### Boxing tracker defaults

- `tracking.max_fps: 30`
- `tracking.state_update_max_fps: 30`
- `tracking.pose.enabled: true`

`tracking.state_update_max_fps` is a state/debug publication cap, not a preview cadence cap. In the current tool/vendor path, replay/live preview publication is decoupled from state writes, so lowering `state_update_max_fps` no longer lowers visible preview cadence by itself; preview still follows `preview.live.max_fps` / `preview.replay.max_fps` and source/runtime limits.
- `tracking.pose.inference_interval_frames: 1`
- `tracking.pose.smoothing_style: lite_filtered`
- `tracking.hands.enabled: false`
- `tracking.hands.landmark_mode: lite`
- `tracking.hands.inference_interval_frames: 1`
- `tracking.hands.bbox.enabled: true`
- `tracking.hands.association.prefer_existing_pose_side_binding: true`
- `tracking.hands.association.nearest_wrist_fallback: true`
- `tracking.hands.validity.max_stale_ms: 1000`
- `tracking.hands.validity.reacquire_stable_ms: 40`
- `source.live_camera.requested_width: 960`
- `source.live_camera.requested_height: 540`
- `source.live_camera.requested_fps: 15`
- `source.replay.input_kind: video_file`
- `source.replay.video_input_path: ""`
- `source.replay.session_manifest_path: ""`
- `preview.live.enabled: true`
- `preview.live.max_fps: 10`
- `preview.replay.enabled: true`
- `preview.replay.max_fps: 10`
- `preview.overlays.pose_skeleton_visible: true`
- `preview.overlays.hand_bbox_visible: true`

#### Flow tracker defaults

Flow keeps the committed live-camera tracker surface only for now and may omit `source.replay.*` until that profile needs the public replay selector.

- `tracking.max_fps: 30`
- `tracking.state_update_max_fps: 30`
- `tracking.pose.enabled: true`
- `tracking.pose.inference_interval_frames: 1`
- `tracking.pose.smoothing_style: lite_filtered`
- `tracking.hands.enabled: false`
- `tracking.hands.landmark_mode: lite`
- `tracking.hands.inference_interval_frames: 1`
- `tracking.hands.bbox.enabled: true`
- `tracking.hands.association.prefer_existing_pose_side_binding: true`
- `tracking.hands.association.nearest_wrist_fallback: true`
- `tracking.hands.validity.max_stale_ms: 80`
- `tracking.hands.validity.reacquire_stable_ms: 40`
- `source.live_camera.requested_width: 960`
- `source.live_camera.requested_height: 540`
- `source.live_camera.requested_fps: 15`
- `preview.live.enabled: true`
- `preview.live.max_fps: 10`
- `preview.replay.enabled: true`
- `preview.replay.max_fps: 10`
- `preview.overlays.pose_skeleton_visible: true`
- `preview.overlays.hand_bbox_visible: false`

## Locked v1 gesture schema

```yaml
schema: aerobeat/gesture_detection_config
version: 1
profile: boxing|flow
punch_detection:
  backend: threshold_gates|prototype_matcher|learned_classifier
threshold_gates:
  enabled: true|false
straight_punch:
  enabled: true|false
  evaluation:
    fresh_samples_only: true
    sample_window_size: 4
    min_positive_growth_samples: 2
    window_ms: 250
  thresholds:
    min_velocity: 0.18
    min_bbox_area_growth: 0.006
  timing:
    triggered_grace_ms: 240
  rearm:
    bbox_area_retract_epsilon: 0.003
  state_machine:
    lost_tracking_reacquire_stable_ms: 40
prototype_matcher:
  enabled: true|false
  prototype_library:
    library_id: boxing_side_aware_v1
  evaluation:
    window_ms: 250
    window_step_ms: 33
  thresholds:
    match_score_min: 0.70
  timing:
    emit_cooldown_ms: 250
    emit_hold_ms: 100
  debug:
    show_scores: true|false
    show_event_gate_state: true|false
```

### Locked gesture field ownership

- `punch_detection.backend` = public boxing punch-backend selector owned by `aerobeat-input-camera-tracking`
- `threshold_gates.enabled` = public on/off wrapper for the legacy threshold backend owned by `aerobeat-input-camera-tracking`
- `straight_punch.*` = boxing gameplay interpretation owned by `aerobeat-input-camera-tracking`
- `straight_punch.evaluation.*` = event evaluation policy owned by `aerobeat-input-camera-tracking`
- `straight_punch.thresholds.*` = gameplay tuning owned by `aerobeat-input-camera-tracking`
- `straight_punch.timing.*` = gameplay timing owned by `aerobeat-input-camera-tracking`
- `straight_punch.rearm.*` = gameplay rearm policy owned by `aerobeat-input-camera-tracking`
- `straight_punch.state_machine.*` = gameplay state transition rules owned by `aerobeat-input-camera-tracking`
- `prototype_matcher.prototype_library.library_id` = public curated prototype-library selector owned by `aerobeat-input-camera-tracking`
- `prototype_matcher.evaluation.window_ms` = public prototype-matcher evaluation window owned by `aerobeat-input-camera-tracking`
- `prototype_matcher.evaluation.window_step_ms` = public prototype-matcher evaluation cadence owned by `aerobeat-input-camera-tracking`
- `prototype_matcher.thresholds.match_score_min` = public prototype-matcher rejection threshold owned by `aerobeat-input-camera-tracking`
- `prototype_matcher.timing.emit_cooldown_ms` = public duplicate-suppression cooldown owned by `aerobeat-input-camera-tracking`
- `prototype_matcher.timing.emit_hold_ms` = public event-hold gate owned by `aerobeat-input-camera-tracking`
- `prototype_matcher.debug.show_scores` = public proving/debug visibility flag owned by `aerobeat-input-camera-tracking`
- `prototype_matcher.debug.show_event_gate_state` = public proving/debug visibility flag owned by `aerobeat-input-camera-tracking`

### Locked gesture defaults by profile

#### Boxing gesture defaults

- `punch_detection.backend: threshold_gates`
- `threshold_gates.enabled: true`
- `straight_punch.enabled: true`
- `straight_punch.evaluation.fresh_samples_only: true`
- `straight_punch.evaluation.sample_window_size: 4`
- `straight_punch.evaluation.min_positive_growth_samples: 2`
- `straight_punch.evaluation.window_ms: 250`
- `straight_punch.thresholds.min_velocity: 0.18`
- `straight_punch.thresholds.min_bbox_area_growth: 0.006`
- `straight_punch.timing.triggered_grace_ms: 240`
- `straight_punch.rearm.bbox_area_retract_epsilon: 0.003`
- `straight_punch.state_machine.lost_tracking_reacquire_stable_ms: 40`
- `prototype_matcher.enabled: false`
- `prototype_matcher.prototype_library.library_id: boxing_side_aware_v1`
- `prototype_matcher.evaluation.window_ms: 250`
- `prototype_matcher.evaluation.window_step_ms: 33`
- `prototype_matcher.thresholds.match_score_min: 0.70`
- `prototype_matcher.timing.emit_cooldown_ms: 250`
- `prototype_matcher.timing.emit_hold_ms: 100`
- `prototype_matcher.debug.show_scores: true`
- `prototype_matcher.debug.show_event_gate_state: true`

#### Flow gesture defaults

Flow does not duplicate unused boxing threshold sections in v1. The flow gesture file is intentionally minimal and may omit `prototype_matcher.*` until that profile needs the public matcher selector surface:

- `straight_punch.enabled: false`

That keeps the filename and schema stable while making the boxing-only state machine opt-in by profile.

## Boundary rules

1. `aerobeat-tool-camera-tracking` must accept only `aerobeat/camera_tracking_config` tracker files.
2. `aerobeat-tool-camera-tracking` must not parse `aerobeat/gesture_detection_config` files.
3. `aerobeat-input-camera-tracking` must keep gameplay/gesture parsing local.
4. Profile selection happens in the input repo, not the tool repo.
5. Future fields may be added only through a schema version change or an explicitly documented backward-compatible extension to these docs.
6. The v1 contract locks filenames now so later implementation slices can target stable asset paths.

## Ambiguity resolved for this slice

The approved plan left open whether flow should keep hand tracking enabled by default. This contract resolves that ambiguity by setting `flow.camera_tracking.yaml` to `tracking.hands.enabled: false` because the paired v1 `flow.gesture_detection.yaml` disables straight-punch detection entirely. The schema still keeps the hand fields present so future flow profiles can re-enable them without renaming files or changing parser ownership.
