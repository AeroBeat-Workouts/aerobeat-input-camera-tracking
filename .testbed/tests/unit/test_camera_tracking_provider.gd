extends "res://addons/aerobeat-vendor-godot-unit-test/test.gd"

const CameraTrackingProviderScript = preload("res://addons/aerobeat-input-camera-tracking/src/providers/camera_tracking_provider.gd")
const CameraTrackingScript = preload("res://addons/aerobeat-tool-camera-tracking/src/CameraTracking.gd")
const CameraTrackingFakeBackendScript = preload("res://addons/aerobeat-tool-camera-tracking/src/CameraTrackingFakeBackend.gd")

class PollOnlyTrackingSession:
	extends Node

	signal tracking_updated(frame: Dictionary)
	signal state_changed(state: String, detail: Dictionary)

	var frame: Dictionary = {}

	func get_tracking_frame() -> Dictionary:
		return frame.duplicate(true)

	func get_active_config() -> Dictionary:
		return {"source": {"kind": "video_file", "path": "res://fixtures/replay/test.mp4"}}

class CapturingTrackingSession:
	extends Node

	signal tracking_updated(frame: Dictionary)
	signal state_changed(state: String, detail: Dictionary)

	var started_configs: Array = []
	var active_config: Dictionary = {}
	var state := "idle"

	func start(config: Dictionary) -> void:
		active_config = config.duplicate(true)
		started_configs.append(active_config.duplicate(true))
		state = "running"
		state_changed.emit(state, {})

	func stop() -> void:
		state = "idle"
		state_changed.emit(state, {})

	func get_tracking_frame() -> Dictionary:
		return {}

	func get_active_config() -> Dictionary:
		return active_config.duplicate(true)

	func get_state() -> Dictionary:
		return {"state": state}

func test_camera_tracking_provider_resolves_repo_owned_scripts_relative_to_its_mount() -> void:
	var provider = add_child_autoqfree(CameraTrackingProviderScript.new())
	assert_eq(provider._get_repo_src_root_path(), "res://addons/aerobeat-input-camera-tracking/src/")
	assert_not_null(provider._ensure_tracking_frame_adapter_script())
	assert_not_null(provider._ensure_config())

func test_camera_tracking_provider_consumes_normalized_tracking_frames() -> void:
	var tracker = add_child_autoqfree(CameraTrackingScript.new())
	var backend = CameraTrackingFakeBackendScript.new()
	tracker.set_backend(backend)
	tracker.start({
		"source": {"kind": "live_camera", "camera_id": "/dev/video7"},
		"preview": {"flip_horizontal": true},
	})

	var provider = add_child_autoqfree(CameraTrackingProviderScript.new())
	provider.set_tracking_session(tracker)
	assert_true(provider.start())

	var pose_calls: Array = []
	provider.pose_updated.connect(func(landmarks: Array) -> void:
		pose_calls.append(landmarks)
	)

	backend.emit_tracking_frame({
		"timestamp_ms": 123,
		"backend": "fake",
		"source_kind": "live_camera",
		"source_id": "/dev/video7",
		"tracking_state": "tracked",
		"confidence": 0.9,
		"preview_transform": {"flip_horizontal": true, "space": "gameplay_normalized"},
		"landmarks": [
			{"id": 0, "x": 0.50, "y": 0.15, "z": 0.0, "visibility": 0.95},
			{"id": 11, "x": 0.42, "y": 0.32, "z": 0.0, "visibility": 0.92},
			{"id": 12, "x": 0.58, "y": 0.32, "z": 0.0, "visibility": 0.92},
			{"id": 15, "x": 0.36, "y": 0.48, "z": 0.0, "visibility": 0.94},
			{"id": 16, "x": 0.64, "y": 0.48, "z": 0.0, "visibility": 0.94},
			{"id": 27, "x": 0.43, "y": 0.86, "z": 0.0, "visibility": 0.90},
			{"id": 28, "x": 0.57, "y": 0.86, "z": 0.0, "visibility": 0.90},
		],
	})

	assert_true(provider.is_tracking())
	assert_eq(provider.get_num_poses(), 1)
	assert_eq(pose_calls.size(), 1)
	assert_eq(provider.get_selected_camera_device_id(), "/dev/video7")
	assert_ne(provider.get_tracking_state(), &"lost")
	assert_eq(provider.get_all_poses().size(), 1)
	assert_ne(provider.get_detector_state().get("tracking_state", &""), &"lost")
	var pose_landmarks: Array = (provider.get_all_poses()[0] as Dictionary).get("landmarks", [])
	assert_true(is_equal_approx(float((pose_landmarks[3] as Dictionary).get("y", 0.0)), 0.48), "Stored pose snapshots should stay in preview-space for proving-scene overlays")

	var left_hand: Variant = provider.get_left_hand_position(provider.TrackingMode.MODE_2D)
	assert_true(left_hand is Vector2)
	assert_true(left_hand.x >= 0.0 and left_hand.x <= 1.0)
	assert_true(left_hand.y >= 0.0 and left_hand.y <= 1.0)
	var emitted_pose: Array = pose_calls[0]
	var emitted_left_hand := emitted_pose.filter(func(lm: Variant) -> bool:
		return lm is Dictionary and int((lm as Dictionary).get("id", -1)) == 15
	)
	assert_eq(emitted_left_hand.size(), 1)
	assert_true(is_equal_approx(float((emitted_left_hand[0] as Dictionary).get("x", 0.0)), 0.64))
	assert_true(is_equal_approx(float((emitted_left_hand[0] as Dictionary).get("y", 0.0)), 0.48), "Provider pose_updated overlays should stay in preview-space so skeletons and click targets match the presenter")
	assert_true(is_equal_approx(left_hand.y, 0.52), "Gameplay-facing hand getters should still expose bottom-left normalized y for detector/math consumers")

func test_camera_tracking_provider_attaches_preview_and_can_change_camera_id() -> void:
	var tracker = add_child_autoqfree(CameraTrackingScript.new())
	var backend = CameraTrackingFakeBackendScript.new([
		{"id": "/dev/video0", "label": "Default camera"},
		{"id": "/dev/video3", "label": "USB camera"},
	])
	tracker.set_backend(backend)
	tracker.start({
		"source": {"kind": "live_camera", "camera_id": "/dev/video0"},
	})

	var preview_slot: Control = add_child_autoqfree(Control.new())

	var provider = add_child_autoqfree(CameraTrackingProviderScript.new())
	provider.set_tracking_session(tracker)
	provider.set_preview_surface(preview_slot)
	assert_true(provider.start())

	assert_eq(provider.get_available_camera_devices().size(), 2)
	assert_true(provider.set_selected_camera_device_id("/dev/video3"))
	assert_eq(String(tracker.get_active_config().get("source", {}).get("camera_id", "")), "/dev/video3")
	assert_eq(String(tracker.get_active_config().get("source", {}).get("id", "")), "/dev/video3")

func test_camera_tracking_provider_reads_and_normalizes_legacy_live_camera_source_id_shape() -> void:
	var tracker = add_child_autoqfree(CameraTrackingScript.new())
	tracker.set_backend(CameraTrackingFakeBackendScript.new())
	tracker.start({
		"source": {"kind": "live_camera", "id": "/dev/video7"},
	})

	var provider = add_child_autoqfree(CameraTrackingProviderScript.new())
	provider.set_tracking_session(tracker)
	assert_eq(provider.get_selected_camera_device_id(), "/dev/video7")
	assert_true(provider.set_selected_camera_device_id("/dev/video9"))
	assert_eq(String(tracker.get_active_config().get("source", {}).get("camera_id", "")), "/dev/video9")
	assert_eq(String(tracker.get_active_config().get("source", {}).get("id", "")), "/dev/video9")

func test_camera_tracking_provider_emits_straight_punch_state_change_signal() -> void:
	var provider = add_child_autoqfree(CameraTrackingProviderScript.new())
	provider.config = provider._ensure_config()
	provider.config.load_selected_profile_bundle("boxing")

	var state_changes: Array = []
	provider.straight_punch_state_changed.connect(func(side: String, state: String, detail: Dictionary) -> void:
		state_changes.append({
			"side": side,
			"state": state,
			"detail": detail.duplicate(true),
		})
	)

	var frames := [
		{"ts": 1000, "z": 0.00, "area": 0.020},
		{"ts": 1080, "z": 0.00, "area": 0.020},
		{"ts": 1160, "z": 0.00, "area": 0.020},
		{"ts": 1240, "z": 0.00, "area": 0.020},
		{"ts": 1320, "z": 0.00, "area": 0.020},
		{"ts": 1400, "z": -0.04, "area": 0.021},
		{"ts": 1480, "z": -0.08, "area": 0.031},
		{"ts": 1560, "z": -0.12, "area": 0.043},
		{"ts": 1640, "z": -0.20, "area": 0.055},
	]
	for frame_data: Dictionary in frames:
		provider.ingest_tracking_frame({
			"timestamp_ms": int(frame_data.get("ts", 0)),
			"frame_index": int(frame_data.get("ts", 0)),
			"tracking_state": "tracked",
			"preview_transform": {"flip_horizontal": true, "space": "gameplay_normalized"},
			"landmarks": [
				{"id": 0, "x": 0.50, "y": 0.15, "z": 0.0, "visibility": 0.95},
				{"id": 11, "x": 0.42, "y": 0.32, "z": 0.0, "visibility": 0.92},
				{"id": 12, "x": 0.58, "y": 0.32, "z": 0.0, "visibility": 0.92},
				{"id": 13, "x": 0.36, "y": 0.40, "z": 0.0, "visibility": 0.94},
				{"id": 14, "x": 0.64, "y": 0.40, "z": 0.0, "visibility": 0.94},
				{"id": 15, "x": 0.36, "y": 0.48, "z": float(frame_data.get("z", 0.0)), "visibility": 0.94},
				{"id": 16, "x": 0.64, "y": 0.48, "z": 0.0, "visibility": 0.94},
				{"id": 23, "x": 0.45, "y": 0.56, "z": 0.0, "visibility": 0.90},
				{"id": 24, "x": 0.55, "y": 0.56, "z": 0.0, "visibility": 0.90},
				{"id": 25, "x": 0.45, "y": 0.70, "z": 0.0, "visibility": 0.90},
				{"id": 26, "x": 0.55, "y": 0.70, "z": 0.0, "visibility": 0.90},
				{"id": 27, "x": 0.45, "y": 0.84, "z": 0.0, "visibility": 0.90},
				{"id": 28, "x": 0.55, "y": 0.84, "z": 0.0, "visibility": 0.90},
			],
			"hand_tracking": {"enabled": true, "available": true},
			"hands": {
				"left": _normalized_hand_payload("left", float(frame_data.get("area", 0.0))),
				"right": _normalized_hand_payload("right", 0.020),
			},
		})

	var left_state_changes: Array = []
	for change: Dictionary in state_changes:
		if String(change.get("side", "")) == "left":
			left_state_changes.append(change)
	assert_eq(left_state_changes.size(), 2)
	assert_eq(left_state_changes[0]["state"], "ready")
	assert_eq(left_state_changes[1]["state"], "triggered")
	assert_eq(String(left_state_changes[1]["detail"].get("previous_state", "")), "ready")

func test_camera_tracking_provider_emits_tracking_edges_when_frame_state_changes() -> void:
	var provider = add_child_autoqfree(CameraTrackingProviderScript.new())

	var restored: Array = []
	var lost: Array = []
	provider.tracking_restored.connect(func() -> void:
		restored.append(true)
	)
	provider.tracking_lost.connect(func() -> void:
		lost.append(true)
	)

	provider.ingest_tracking_frame({
		"timestamp_ms": 10,
		"tracking_state": "lost",
		"preview_transform": {"flip_horizontal": true, "space": "gameplay_normalized"},
		"landmarks": [],
	})
	provider.ingest_tracking_frame({
		"timestamp_ms": 20,
		"tracking_state": "tracked",
		"preview_transform": {"flip_horizontal": true, "space": "gameplay_normalized"},
		"landmarks": [
			{"id": 0, "x": 0.5, "y": 0.2, "visibility": 0.9},
			{"id": 15, "x": 0.4, "y": 0.4, "visibility": 0.9},
			{"id": 16, "x": 0.6, "y": 0.4, "visibility": 0.9},
		],
	})
	provider.ingest_tracking_frame({
		"timestamp_ms": 30,
		"tracking_state": "lost",
		"preview_transform": {"flip_horizontal": true, "space": "gameplay_normalized"},
		"landmarks": [],
	})

	assert_eq(restored.size(), 1)
	assert_eq(lost.size(), 1)
	assert_false(provider.is_tracking())

func test_camera_tracking_provider_can_manage_minimal_session_lifecycle_for_proving() -> void:
	var tracker = add_child_autoqfree(CameraTrackingScript.new())
	var backend = CameraTrackingFakeBackendScript.new([
		{"id": "/dev/video0", "label": "Default camera"},
		{"id": "/dev/video5", "label": "USB camera"},
	])
	tracker.set_backend(backend)

	var provider = add_child_autoqfree(CameraTrackingProviderScript.new())
	provider.manage_tracking_session_lifecycle = true
	provider.config = provider._ensure_config()
	provider.config.set_selected_camera_device_id("/dev/video5")
	provider.set_tracking_session(tracker)

	assert_true(provider.start())
	assert_eq(String(tracker.get_state().get("state", "")), CameraTrackingScript.STATE_RUNNING)
	assert_eq(String(tracker.get_active_config().get("source", {}).get("camera_id", "")), "/dev/video5")
	assert_eq(provider.get_selected_camera_device_id(), "/dev/video5")

func test_camera_tracking_provider_forwards_runtime_filter_semantics_from_config() -> void:
	var provider = add_child_autoqfree(CameraTrackingProviderScript.new())
	provider.config = provider._ensure_config()
	provider.config.runtime = {
		"model_complexity": 2,
		"filter_enabled": false,
		"no_filter": true,
	}
	provider.config.gesture_eval_interval_frames = 3
	provider.config.min_visibility = 0.42
	provider.config.flip_horizontal = false

	var tracking_config: Dictionary = provider._build_tracking_config()
	assert_eq(int(tracking_config.get("runtime", {}).get("model_complexity", -1)), 2)
	assert_false(bool(tracking_config.get("runtime", {}).get("filter_enabled", true)))
	assert_true(bool(tracking_config.get("runtime", {}).get("no_filter", false)))
	assert_eq(int(tracking_config.get("tracking", {}).get("gesture_eval_interval_frames", -1)), 3)
	assert_eq(float(tracking_config.get("tracking", {}).get("min_visibility", 0.0)), 0.42)
	assert_false(bool(tracking_config.get("preview", {}).get("flip_horizontal", true)))

func test_camera_tracking_provider_replay_start_forwards_boxing_pose_and_hand_profile_config() -> void:
	var tracker = add_child_autoqfree(CapturingTrackingSession.new())
	var provider = add_child_autoqfree(CameraTrackingProviderScript.new())
	provider.manage_tracking_session_lifecycle = true
	provider.config = provider._ensure_config()
	provider.config.load_selected_profile_bundle("boxing")
	provider.config.set_selected_camera_device_id("res://fixtures/replay/test.mp4")
	provider.set_tracking_session(tracker)

	assert_true(provider.start())
	assert_eq(tracker.started_configs.size(), 1)
	var active_config: Dictionary = tracker.get_active_config()
	assert_eq(String(active_config.get("source", {}).get("kind", "")), "video_file")
	assert_eq(String(active_config.get("source", {}).get("path", "")), "res://fixtures/replay/test.mp4")
	assert_true(bool(active_config.get("tracking", {}).get("pose", {}).get("enabled", false)))
	assert_true(bool(active_config.get("tracking", {}).get("hands", {}).get("enabled", false)))
	assert_eq(String(active_config.get("tracking", {}).get("hands", {}).get("landmark_mode", "")), "lite")
	assert_true(bool(active_config.get("tracking", {}).get("hands", {}).get("bbox", {}).get("enabled", false)))

func test_camera_tracking_provider_live_start_forwards_boxing_pose_and_hand_profile_config() -> void:
	var tracker = add_child_autoqfree(CapturingTrackingSession.new())
	var provider = add_child_autoqfree(CameraTrackingProviderScript.new())
	provider.manage_tracking_session_lifecycle = true
	provider.config = provider._ensure_config()
	provider.config.load_selected_profile_bundle("boxing")
	provider.config.set_selected_camera_device_id("/dev/video5")
	provider.set_tracking_session(tracker)

	assert_true(provider.start())
	assert_eq(tracker.started_configs.size(), 1)
	var active_config: Dictionary = tracker.get_active_config()
	assert_eq(String(active_config.get("source", {}).get("kind", "")), "live_camera")
	assert_eq(String(active_config.get("source", {}).get("camera_id", "")), "/dev/video5")
	assert_true(bool(active_config.get("tracking", {}).get("pose", {}).get("enabled", false)))
	assert_true(bool(active_config.get("tracking", {}).get("hands", {}).get("enabled", false)))
	assert_eq(int(active_config.get("tracking", {}).get("hands", {}).get("inference_interval_frames", -1)), 1)
	assert_eq(int(active_config.get("tracking", {}).get("hands", {}).get("validity", {}).get("max_stale_ms", -1)), 80)
	assert_eq(int(active_config.get("tracking", {}).get("hands", {}).get("validity", {}).get("reacquire_stable_ms", -1)), 40)

func test_camera_tracking_provider_polls_tracking_session_frames_between_signals() -> void:
	var tracker = add_child_autoqfree(PollOnlyTrackingSession.new())
	var provider = add_child_autoqfree(CameraTrackingProviderScript.new())
	provider.set_tracking_session(tracker)

	tracker.frame = {
		"timestamp_ms": 100,
		"frame_index": 3,
		"tracking_state": "tracked",
		"preview_transform": {"flip_horizontal": true, "space": "gameplay_normalized"},
		"landmarks": [
			{"id": 0, "x": 0.50, "y": 0.15, "z": 0.0, "visibility": 0.95},
			{"id": 15, "x": 0.36, "y": 0.48, "z": 0.0, "visibility": 0.94},
			{"id": 16, "x": 0.64, "y": 0.48, "z": 0.0, "visibility": 0.94},
		],
	}
	provider._process(0.016)

	assert_true(provider.is_tracking())
	assert_eq(provider.get_num_poses(), 1)
	assert_eq(provider.get_all_poses().size(), 1)
	assert_ne(provider.get_detector_state().get("tracking_state", &""), &"lost")

func _normalized_hand_payload(side: String, bbox_area: float, tracking_state: String = "tracked", tracking_valid: bool = true, stale_frames: int = 0) -> Dictionary:
	var width := 0.10
	var height := bbox_area / width if width > 0.0 else 0.0
	var x := 0.18 if side == "left" else 0.72
	return {
		"tracking_valid": tracking_valid,
		"tracking_state": tracking_state,
		"frame_index": 1,
		"timestamp_seconds": 0.0,
		"stale_frames": stale_frames,
		"association": {
			"side": side,
			"assigned": true,
			"method": "pose_side_binding",
			"source_hand_index": 0 if side == "left" else 1,
			"source_label": side,
			"source_score": 0.95,
		},
		"landmarks": [],
		"bbox": {
			"x": x,
			"y": 0.40,
			"width": width,
			"height": height,
			"area": bbox_area,
			"area_unit": "normalized_frame_area",
		},
	}
