extends "res://addons/gut/test.gd"

const AeroCameraTrackingScript = preload("res://addons/aerobeat-input-camera-tracking/src/AeroCameraTracking.gd")
const CameraTrackingScript = preload("res://addons/aerobeat-tool-camera-tracking/src/CameraTracking.gd")
const CameraTrackingFakeBackendScript = preload("res://addons/aerobeat-tool-camera-tracking/src/CameraTrackingFakeBackend.gd")
const CameraTrackingBackendRegistryScript = preload("res://addons/aerobeat-tool-camera-tracking/src/CameraTrackingBackendRegistry.gd")

func before_each() -> void:
	CameraTrackingBackendRegistryScript.clear()

func test_aero_camera_tracking_starts_live_camera_and_reemits_tracking_and_flow_updates() -> void:
	var singleton = add_child_autoqfree(AeroCameraTrackingScript.new())
	var tracker = CameraTrackingScript.new()
	tracker.set_backend(CameraTrackingFakeBackendScript.new([
		{"id": "/dev/video0", "label": "Default camera"},
		{"id": "/dev/video7", "label": "USB camera"},
	]))
	singleton.set_tracking_session(tracker)

	var tracking_frames: Array = []
	var pose_frames: Array = []
	var swing_events: Array = []
	singleton.tracking_updated.connect(func(frame: Dictionary) -> void:
		tracking_frames.append(frame)
	)
	singleton.pose_updated.connect(func(landmarks: Array) -> void:
		pose_frames.append(landmarks)
	)
	singleton.swing_left.connect(func(placement: int, direction: int) -> void:
		swing_events.append([placement, direction])
	)

	assert_true(singleton.start_live_camera("/dev/video7", {
		"min_visibility": 0.35,
		"tracking_overlay_mode": "optimized",
		"gesture_eval_interval_frames": 2,
		"model_complexity": 2,
	}))
	assert_eq(String(tracker.get_active_config().get("source", {}).get("camera_id", "")), "/dev/video7")
	assert_eq(singleton.get_available_camera_devices().size(), 2)

	var backend = tracker.get("_backend")
	backend.emit_tracking_frame({
		"timestamp_ms": 123,
		"backend": "fake",
		"source_kind": "live_camera",
		"source_id": "/dev/video7",
		"tracking_state": "tracked",
		"preview_transform": {"flip_horizontal": true, "space": "gameplay_normalized"},
		"landmarks": [
			{"id": 0, "x": 0.50, "y": 0.15, "z": 0.0, "visibility": 0.95},
			{"id": 11, "x": 0.42, "y": 0.32, "z": 0.0, "visibility": 0.92},
			{"id": 12, "x": 0.58, "y": 0.32, "z": 0.0, "visibility": 0.92},
			{"id": 15, "x": 0.15, "y": 0.52, "z": 0.0, "visibility": 0.94},
			{"id": 16, "x": 0.82, "y": 0.52, "z": 0.0, "visibility": 0.94},
		],
	})
	await get_tree().process_frame

	assert_true(tracking_frames.size() >= 1)
	assert_true(pose_frames.size() >= 1)
	assert_true(singleton.is_tracking())
	assert_eq(singleton.get_num_poses(), 1)
	assert_eq(singleton.get_all_poses().size(), 1)

	singleton.get_provider().swing_left.emit(9, 3)
	assert_eq(swing_events, [[9, 3]])

func test_aero_camera_tracking_starts_replay_sources_through_camera_tracking_contract() -> void:
	var singleton = add_child_autoqfree(AeroCameraTrackingScript.new())
	var tracker = CameraTrackingScript.new()
	tracker.set_backend(CameraTrackingFakeBackendScript.new())
	singleton.set_tracking_session(tracker)

	assert_true(singleton.start_replay("res://fixtures/replay/head_rotate_left_repeat_04_take_01.mp4", {
		"flip_horizontal": false,
		"tracking_overlay_mode": "full",
		"model_complexity": 1,
	}))

	var source: Dictionary = tracker.get_active_config().get("source", {})
	assert_eq(String(source.get("kind", "")), "video_file")
	assert_eq(String(source.get("path", "")), "res://fixtures/replay/head_rotate_left_repeat_04_take_01.mp4")

func test_aero_camera_tracking_does_not_register_vendor_backends_from_the_input_repo() -> void:
	var singleton = add_child_autoqfree(AeroCameraTrackingScript.new())
	var tracker = CameraTrackingScript.new()
	tracker.set_backend(CameraTrackingFakeBackendScript.new())
	singleton.set_tracking_session(tracker)

	assert_eq(CameraTrackingScript.get_registered_backend_ids(), [])
	assert_true(singleton.start_live_camera("/dev/video7", {}))
	assert_eq(CameraTrackingScript.get_registered_backend_ids(), [])

func test_aero_camera_tracking_owns_replay_playback_facade_for_vendor_backed_proving_consumers() -> void:
	var singleton = add_child_autoqfree(AeroCameraTrackingScript.new())
	var tracker = CameraTrackingScript.new()
	tracker.set_backend(CameraTrackingFakeBackendScript.new())
	singleton.set_tracking_session(tracker)

	var replay_path := ProjectSettings.globalize_path("res://fixtures/replay/head_rotate_left_repeat_04_take_01.mp4")
	assert_true(singleton.ensure_replay_playback_loaded(replay_path))
	assert_true(singleton.has_replay_playback_loaded())
	assert_eq(String(singleton.get_replay_playback_state().get("source", {}).get("path", "")), replay_path)
	assert_true(singleton.play_replay_playback())
	assert_eq(String(tracker.get_active_config().get("source", {}).get("path", "")), replay_path)
	assert_true(singleton.pause_replay_playback())
	assert_true(singleton.seek_replay_playback(4.0))
	assert_eq(String(tracker.get_active_config().get("source", {}).get("path", "")), replay_path)
	assert_true(float((tracker.get_active_config().get("vendor", {}) as Dictionary).get("source", {}).get("start_time_sec", 0.0)) >= 4.0)

	singleton.unload_replay_playback()
	assert_false(singleton.has_replay_playback_loaded())
