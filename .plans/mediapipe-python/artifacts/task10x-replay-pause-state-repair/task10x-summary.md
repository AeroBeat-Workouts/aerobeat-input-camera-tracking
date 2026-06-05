# Task 10X QA Summary

- Rerun: pause-state reporting seam repair verification after Task 10W
- Scene: `res://scenes/boxing_proving.tscn`
- Fixture: `res://assets/fixtures/boxing/punch_left/boxing_guard->punch_left_repeat_04_take_01.mp4`

## Observed replay transport truth

- `transport_mode`: `approx_time_seek`
- `can_step_forward`: `false`
- `can_step_backward`: `false`
- `can_seek_frame`: `false`
- `exactness_note`: `This backend exposes replay time/paused status for video-file sessions but does not prove exact frame-addressed stepping.`
- `limitation_code`: `backend_transport_unsupported`

## Boxing proving UI evidence

- Status label: `Boxing harness live`
- Step status label: `Frame step unavailable (approx_time_seek). This backend exposes replay time/paused status for video-file sessions but does not prove exact frame-addressed stepping.`
- Step back disabled: `true`
- Step forward disabled: `true`
- Can step paused playback: `false`

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

- `initial_state`: state=`` position=`1.36666666666667` paused=`false`
- `paused_state`: state=`paused` position=`1.43333333333333` paused=`true`
- `held_paused_state`: state=`paused` position=`1.43333333333333` paused=`true`
- `seek_state`: state=`playing` position=`4.86666666666667` paused=`false`
- `paused_after_seek_state`: state=`playing` position=`5.26666666666667` paused=`false`
- `resumed_state`: state=`paused` position=`5.3` paused=`true`

## QA truth

- `scene_consumes_transport_surface`: `true`
- `exact_step_ui_truthful_for_shipped_path`: `true`
- `shipped_path_exact_support_proven_end_to_end`: `false`
- `observed_transport_mode`: `approx_time_seek`
- `observed_limit_code`: `backend_transport_unsupported`
- `pause_persists_in_headless_boxing_probe`: `true`
- `seek_while_paused_preserves_pause`: `false`
- `resume_restores_playback`: `false`
