# Task 10U QA Summary

- Scene: `res://scenes/boxing_proving.tscn`
- Fixture: `res://assets/fixtures/boxing/punch_left/boxing_guard->punch_left_repeat_04_take_01.mp4`

## Observed replay transport truth

- `transport_mode`: `approx_time_seek`
- `can_step_forward`: `False`
- `can_step_backward`: `False`
- `can_seek_frame`: `False`
- `exactness_note`: `This backend exposes replay time/paused status for video-file sessions but does not prove exact frame-addressed stepping.`
- `limitation_code`: `backend_transport_unsupported`

## Boxing proving UI evidence

- Status label: `Boxing harness live`
- Step status label: `Frame step unavailable (approx_time_seek). This backend exposes replay time/paused status for video-file sessions but does not prove exact frame-addressed stepping.`
- Step back disabled: `True`
- Step forward disabled: `True`
- Can step paused playback: `False`

## Step attempt result

```json
{
  "code": "backend_transport_unsupported",
  "detail": {
    "capabilities": {
      "can_seek_frame": false,
      "can_step_backward": false,
      "can_step_forward": false,
      "exactness_note": "This backend exposes replay time/paused status for video-file sessions but does not prove exact frame-addressed stepping.",
      "frame_duration_sec": null,
      "limitation_code": "backend_transport_unsupported",
      "nominal_fps": null,
      "transport_mode": "approx_time_seek"
    },
    "method": "step_replay_frames",
    "transport_mode": "approx_time_seek"
  },
  "message": "step_replay_frames requires exact frame-addressed replay transport, but this backend only supports approx_time_seek.",
  "success": false
}
```

## Playback controller observations

- `initial_state`: state=`playing` position=`2.53333333333333` paused=`False`
- `paused_state`: state=`playing` position=`2.53333333333333` paused=`False`
- `seek_state`: state=`playing` position=`4.26666666666667` paused=`False`
- `paused_after_seek_state`: state=`playing` position=`4.3` paused=`False`
- `resumed_state`: state=`playing` position=`5.13333333333333` paused=`False`

## QA truth

- `scene_consumes_transport_surface`: `True`
- `exact_step_ui_truthful_for_shipped_path`: `True`
- `shipped_path_exact_support_proven_end_to_end`: `False`
- `observed_transport_mode`: `approx_time_seek`
- `observed_limit_code`: `backend_transport_unsupported`
- `normal_seek_proven`: `True`
- `pause_persists_in_headless_boxing_probe`: `False`
