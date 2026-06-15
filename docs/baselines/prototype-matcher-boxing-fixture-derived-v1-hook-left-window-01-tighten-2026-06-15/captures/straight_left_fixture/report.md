# Proving Fixture Capture

- Fixture: `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.testbed/assets/fixtures/boxing/straight_left/boxing_guard->straight_left_repeat_04_take_01.yaml`
- Video: `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.testbed/assets/fixtures/boxing/straight_left/boxing_guard->straight_left_repeat_04_take_01.mp4`
- Scene: `res://scenes/boxing_proving.tscn`
- Captured: `2026-06-15 19:43:32`
- Elapsed: `13202ms`
- Screenshot: `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/docs/baselines/prototype-matcher-boxing-fixture-derived-v1-hook-left-window-01-tighten-2026-06-15/captures/straight_left_fixture/proving.png`

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

0023: Right Hook
0024: Guard Activated
0025: Right Hook
0026: Right Hook
0027: Right Hook
0028: Guard Activated
0029: Left Uppercut
0030: Left Uppercut

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
Best class / score / threshold: uppercut_left / 0.902 / 0.700
Result class / emitted event: uppercut_left / none
Debug flags: show_scores=true show_event_gate_state=true
Class scores: {hook_left=0.547, hook_right=0.844, straight_left=0.813, straight_right=0.813, uppercut_left=0.902, uppercut_right=0.865}
Gate reason / hold / cooldown / active event: emit_cooldown_active / 0ms / 50ms / no_punch

Guard tuning
------------
Enabled: true
Wrist separation X <= 0.200
Wrist separation Y <= 0.120
Wrist nose distance <= 0.200
Guard candidate: true
Live wrist separation: x=0.115 y=0.004
Wrists above elbows: L=true R=true
Wrist-to-nose distances: L=0.078 R=0.078

Squat tuning
------------
Enabled: true
Enter height ratio <= 0.820
Exit height ratio >= 0.920
Current state: inactive
Calibration ready / frames: true / 5
Live height ratio: 1.028 (standing)
Squat depth: 0.000
Torso height live / baseline: 0.384 / 0.374

Weave tuning
------------
Enabled: true
Enter head lateral offset >= 0.300
Enter head-vs-hip offset >= 0.120
Enter head drop ratio >= 0.050
Exit head lateral offset <= 0.120
Exit head-vs-hip offset <= 0.080
Current state: inactive
Candidates: left=false right=false neutral=false
Live offsets: head=0.006 hip=0.118 relative=-0.112
Head drop ratio: 0.000 (ready=false)

Tracker hand truth
------------------
Frame: 2056  source=video_file  playback=paused 0:00/0:06
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
