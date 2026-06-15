# Proving Fixture Capture

- Fixture: `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.testbed/assets/fixtures/boxing/uppercut_left/boxing_guard->uppercut_left_repeat_04_take_01.yaml`
- Video: `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.testbed/assets/fixtures/boxing/uppercut_left/boxing_guard->uppercut_left_repeat_04_take_01.mp4`
- Scene: `res://scenes/boxing_proving.tscn`
- Captured: `2026-06-15 19:44:34`
- Elapsed: `13557ms`
- Screenshot: `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/docs/baselines/prototype-matcher-boxing-fixture-derived-v1-hook-left-window-01-tighten-2026-06-15/captures/uppercut_left_fixture/proving.png`

## Status

- Title: BOXING GESTURE DETECTION
- Status label: Boxing harness live
- Live status: 
- Camera streaming: true
- Camera has texture: true
- Server PID: -1
- Provider present: true

## Quick Stats

```text
Detected events

0022: Right Hook
0023: Left Uppercut
0024: Left Uppercut
0025: Left Uppercut
0026: Right Uppercut
0027: Guard Deactivated
0028: Squat Activated
0029: Left Punch

Profile bundle
--------------
Profile: boxing
Tracker YAML: res://assets/boxing.camera_tracking.yaml
Gesture YAML: res://assets/boxing.gesture_detection.yaml

Tracker tuning
--------------
Pose smoothing: lite_raw
Pose cadence: every 1 frame(s)
Hand cadence: every 1 frame(s)
Hand tracking enabled: false
Hand reacquire stable window: 40ms
Hand grace/stale window: 2000ms

Straight-punch tuning
---------------------
Enabled: true
Fresh samples only: true
Sample window size: 4
Motion window: 250ms
Positive growth samples: 1
Min velocity: 0.500
Min bbox area growth: 0.003
Max elbow-shoulder XY distance: 0.140
Triggered grace: 10ms
BBox retract epsilon: 0.000
Pose-only rearm timer: 10ms
Straight-punch lost reacquire stable window: 40ms

Hook tuning
-----------
Enabled: true
Motion window: 250ms
Min velocity: 0.400
Min lateral dominance: 0.250
Min horizontal direction share of total motion: 0.150
Hook grace / rearm / reacquire: 500ms / 50ms / 40ms

Uppercut tuning
---------------
Enabled: true
Motion window: 250ms
Min velocity: 0.500
Min vertical dominance: 0.250
Min upward direction share of total motion: 0.150
Uppercut grace / rearm / reacquire: 500ms / 50ms / 40ms

Prototype matcher truth
-----------------------
Active backend: prototype_matcher
Selected backend: prototype_matcher
Prototype library ID: boxing_side_aware_fixture_derived_v1 (loaded=true)
Best class / score / threshold: hook_right / 0.737 / 0.700
Result class / emitted event: hook_right / none
Debug flags: show_scores=true show_event_gate_state=true
Class scores: {hook_left=0.734, hook_right=0.737, straight_left=0.586, straight_right=0.516, uppercut_left=0.668, uppercut_right=0.728}
Gate reason / hold / cooldown / active event: emit_cooldown_active / 0ms / 50ms / no_punch

Guard tuning
------------
Enabled: true
Wrist separation X <= 0.200
Wrist separation Y <= 0.120
Wrist nose distance <= 0.200
Guard candidate: false
Live wrist separation: x=0.159 y=0.219
Wrists above elbows: L=false R=true
Wrist-to-nose distances: L=0.395 R=0.171

Squat tuning
------------
Enabled: true
Enter height ratio <= 0.820
Exit height ratio >= 0.920
Current state: active
Calibration ready / frames: true / 5
Live height ratio: 0.849 (transition)
Squat depth: 0.151
Torso height live / baseline: 0.311 / 0.366

Weave tuning
------------
Enabled: true
Enter head lateral offset >= 0.300
Enter head-vs-hip offset >= 0.120
Enter head drop ratio >= 0.050
Exit head lateral offset <= 0.120
Exit head-vs-hip offset <= 0.080
Current state: inactive
Candidates: left=false right=false neutral=true
Live offsets: head=0.041 hip=0.049 relative=-0.008
Head drop ratio: 0.623 (ready=true)

Tracker hand truth
------------------
Frame: 2126  source=video_file  playback=paused 0:00/0:08
L: state=tracking_lost tracking=disabled valid=false source=none wrist_xyz_vel=0.000 wrist_forward_vel=0.000 depth_spike=0.000 elbow_shoulder_xy=0.000<=0.140(false) bbox_area=0.000 bbox_growth=0.000 grace=0ms hook=tracking_lost/0.000 dir=0.000 uppercut=tracking_lost/0.000 dir=0.000 hand_grace=0ms hand_stable=0ms stale=0ms
R: state=tracking_lost tracking=disabled valid=false source=none wrist_xyz_vel=0.000 wrist_forward_vel=0.000 depth_spike=0.000 elbow_shoulder_xy=0.000<=0.140(false) bbox_area=0.000 bbox_growth=0.000 grace=0ms hook=tracking_lost/0.000 dir=0.000 uppercut=tracking_lost/0.000 dir=0.000 hand_grace=0ms hand_stable=0ms stale=0ms
```

## Summary

```text

```

## Signal Status

```text

```

## Metrics

```text

```

## Events

```text

```
