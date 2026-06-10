extends "res://addons/aerobeat-vendor-godot-unit-test/test.gd"

const ProvingHarness = preload("res://scripts/proving_harness.gd")
const LandmarkDrawerScript = preload("res://scripts/landmark_drawer.gd")
const CameraTrackingScript = preload("res://addons/aerobeat-tool-camera-tracking/src/CameraTracking.gd")
const CameraTrackingFakeBackendScript = preload("res://addons/aerobeat-tool-camera-tracking/src/CameraTrackingFakeBackend.gd")

class TestProvingHarness:
	extends "res://scripts/proving_harness.gd"

	var last_status_message := ""

	func _ready() -> void:
		pass

	func _update_status(text: String, color: Color) -> void:
		last_status_message = text
		super._update_status(text, color)

class PlaybackTrackingHarness:
	extends TestProvingHarness

	var unload_calls := 0

	func _playback_controller_unload() -> void:
		unload_calls += 1
		super._playback_controller_unload()

class FakeOverlayDrawer:
	extends Control

	var update_calls: Array = []
	var clear_calls := 0

	func update_landmarks(landmarks: Array, min_visibility: float = 0.5) -> void:
		update_calls.append({"landmarks": landmarks.duplicate(true), "min_visibility": min_visibility})

	func update_trails(left_points: Array, right_points: Array) -> void:
		update_calls.append({
			"left_points": left_points.duplicate(true),
			"right_points": right_points.duplicate(true),
		})

	func clear_landmarks() -> void:
		clear_calls += 1

	func clear_trails() -> void:
		clear_calls += 1

class FakeAutoStartManager:
	extends Node

	var server_pid := 1234
	var running := false
	var model_asset_path := "/tmp/test-pose.task"

	func is_server_running() -> bool:
		return running

	func get_model_asset_path() -> String:
		return model_asset_path

class FakeProfileBundleTrackingSingleton:
	extends Node

	var bundle: Dictionary = {}

	func get_selected_profile_bundle() -> Dictionary:
		return bundle.duplicate(true)

class FakeSignalProvider:
	extends Node

	signal punch_left(power: float)
	signal preview_changed(descriptor: Dictionary)
	signal pose_updated(landmarks: Array)
	signal tracking_lost()
	signal tracking_restored()

class FakePreviewPresenter:
	extends Control

	var tracking_frame := {}
	var content_rect := Rect2(Vector2.ZERO, Vector2(640.0, 360.0))

	func get_tracking_frame_snapshot() -> Dictionary:
		return tracking_frame.duplicate(true)

	func map_landmark_to_preview_position(landmark: Dictionary) -> Vector2:
		return Vector2(
			float(landmark.get("x", 0.0)) * content_rect.size.x,
			float(landmark.get("y", 0.0)) * content_rect.size.y
		)

	func get_content_rect() -> Rect2:
		return content_rect

class ContractAwareHarness:
	extends TestProvingHarness

	var fake_singleton: Node = null

	func _resolve_camera_tracking_singleton() -> Node:
		return fake_singleton

class FakeTrackingSingleton:
	extends Node

	var selected_camera_device_id := "/dev/video0"
	var set_selected_calls := 0
	var stop_calls := 0

	func set_selected_camera_device_id(device_id: String) -> bool:
		set_selected_calls += 1
		selected_camera_device_id = device_id
		return true

	func get_selected_camera_device_id() -> String:
		return selected_camera_device_id

	func stop() -> void:
		stop_calls += 1

class FakeTrackingContractSingleton:
	extends Node

	var tracking_session: Node = null

	func get_tracking_session_if_ready() -> Node:
		return tracking_session

class FakeLiveTrackingContractSingleton:
	extends FakeTrackingContractSingleton

	var start_live_calls := 0

	func start_live_camera(_camera_id: String, _config_variant: Variant = null) -> bool:
		start_live_calls += 1
		if tracking_session == null:
			tracking_session = CameraTrackingScript.new()
			tracking_session.set_backend(CameraTrackingFakeBackendScript.new(), "fake")
			add_child(tracking_session)
		tracking_session.start({
			"source": {"kind": "live_camera", "camera_id": "/dev/video0"},
			"preview": {"enabled": true, "flip_horizontal": true},
		})
		return true

class FakeReplayTransportSingleton:
	extends Node

	var replay_state := {
		"state": "paused",
		"position": 4.0,
		"duration": 12.0,
		"media_loaded": true,
		"source": {"path": "res://fixtures/replay/example.mp4", "kind": "file"},
	}
	var transport_capabilities := {
		"transport_mode": "approx_time_seek",
		"can_step_forward": false,
		"can_step_backward": false,
		"can_seek_frame": false,
		"nominal_fps": null,
		"frame_duration_sec": null,
		"exactness_note": "Approximate time seek only.",
		"limitation_code": "transport_unsupported",
	}
	var transport_status := {
		"transport_mode": "approx_time_seek",
		"can_step_forward": false,
		"can_step_backward": false,
		"can_seek_frame": false,
		"frame_index": null,
		"frame_count": null,
		"nominal_fps": null,
		"frame_duration_sec": null,
		"paused": true,
		"position_sec": 4.0,
		"duration_sec": 12.0,
		"exactness_note": "Approximate time seek only.",
		"limitation_code": "transport_unsupported",
	}
	var step_calls: Array[int] = []

	func ensure_replay_playback_loaded(source_path: String) -> bool:
		replay_state["media_loaded"] = true
		replay_state["source"] = {"path": source_path, "kind": "file"}
		return true

	func get_replay_playback_state() -> Dictionary:
		var state := replay_state.duplicate(true)
		state["status"] = {
			"current_time_sec": float(state.get("position", 0.0)),
			"duration_sec": float(state.get("duration", 0.0)),
			"progress": float(state.get("position", 0.0)) / float(state.get("duration", 1.0)) if float(state.get("duration", 0.0)) > 0.0 else 0.0,
			"paused": String(state.get("state", "idle")) != "playing",
			"is_file_source": true,
		}
		return state

	func refresh_replay_playback_status() -> Dictionary:
		return get_replay_playback_state()

	func play_replay_playback() -> bool:
		replay_state["state"] = "playing"
		transport_status["paused"] = false
		return true

	func pause_replay_playback() -> bool:
		replay_state["state"] = "paused"
		transport_status["paused"] = true
		return true

	func seek_replay_playback(seconds: float) -> bool:
		replay_state["position"] = seconds
		transport_status["position_sec"] = seconds
		return true

	func unload_replay_playback() -> void:
		replay_state["media_loaded"] = false

	func get_replay_transport_capabilities() -> Dictionary:
		return transport_capabilities.duplicate(true)

	func get_replay_transport_status() -> Dictionary:
		return transport_status.duplicate(true)

	func step_replay_frames(delta_frames: int) -> Dictionary:
		step_calls.append(delta_frames)
		var frame_index := int(transport_status.get("frame_index", 0)) + delta_frames
		transport_status["frame_index"] = frame_index
		var frame_duration := float(transport_status.get("frame_duration_sec", 0.0))
		if frame_duration > 0.0:
			var next_position := maxf(float(transport_status.get("position_sec", replay_state.get("position", 0.0))) + (frame_duration * delta_frames), 0.0)
			transport_status["position_sec"] = next_position
			replay_state["position"] = next_position
		replay_state["state"] = "paused"
		transport_status["paused"] = true
		return {
			"success": true,
			"code": "ok",
			"message": "stepped",
			"detail": {"delta_frames": delta_frames, "frame_index": frame_index},
		}

var harness: ProvingHarness = null
var _replay_requests: Array[String] = []
var _replay_responses: Dictionary = {}

func before_each() -> void:
	_replay_requests.clear()
	_replay_responses.clear()
	harness = TestProvingHarness.new()
	harness.overlay_visibility_threshold = 0.35
	harness._reset_last_flow_events()
	harness._reset_event_tracking()
	harness._left_trail_debug = harness._make_trail_debug_state("left")
	harness._right_trail_debug = harness._make_trail_debug_state("right")

func _debug_state(side: String = "test") -> Dictionary:
	return harness._make_trail_debug_state(side)

func after_each() -> void:
	var singleton = get_tree().root.get_node_or_null("AeroCameraTracking")
	if singleton != null and singleton.has_method("unload_replay_playback"):
		singleton.unload_replay_playback()
	if harness != null:
		harness.free()
		harness = null

func test_appends_contiguous_in_bounds_wrist_samples() -> void:
	var trail: Array = []
	var debug_state := _debug_state()
	harness._append_trail_point(trail, {"x": 0.30, "y": 0.40, "v": 0.99}, 1000, debug_state)
	harness._append_trail_point(trail, {"x": 0.38, "y": 0.44, "v": 0.99}, 1033, debug_state)
	assert_eq(trail.size(), 2)
	assert_true(is_equal_approx(float(trail[1].get("x", 0.0)), 0.38))
	assert_true(is_equal_approx(float(trail[1].get("y", 0.0)), 0.44))
	assert_eq(int(debug_state.get("reseeds", 0)), 1)
	assert_eq(int(debug_state.get("continuity_breaks", 0)), 0)

func test_breaks_then_reseeds_trail_on_implausible_in_bounds_jump() -> void:
	var trail: Array = []
	var debug_state := _debug_state()
	harness._append_trail_point(trail, {"x": 0.24, "y": 0.28, "v": 0.99}, 1000, debug_state)
	harness._append_trail_point(trail, {"x": 0.82, "y": 0.86, "v": 0.99}, 1033, debug_state)
	assert_eq(trail.size(), 3)
	assert_true(is_equal_approx(float(trail[0].get("x", 0.0)), 0.24))
	assert_true(is_equal_approx(float(trail[0].get("y", 0.0)), 0.28))
	assert_true(float(trail[1].get("x", 0.0)) < 0.0)
	assert_true(float(trail[1].get("y", 0.0)) < 0.0)
	assert_true(is_equal_approx(float(trail[2].get("x", 0.0)), 0.82))
	assert_true(is_equal_approx(float(trail[2].get("y", 0.0)), 0.86))
	assert_eq(int(debug_state.get("continuity_breaks", 0)), 1)
	assert_eq(int(debug_state.get("reseeds", 0)), 2)
	assert_gt(float(debug_state.get("last_jump_distance", 0.0)), 0.28)

func test_preserves_shorter_boxing_jump_as_contiguous_motion() -> void:
	var trail: Array = []
	var debug_state := _debug_state()
	harness._append_trail_point(trail, {"x": 0.30, "y": 0.40, "v": 0.99}, 1000, debug_state)
	harness._append_trail_point(trail, {"x": 0.47, "y": 0.52, "v": 0.99}, 1033, debug_state)
	assert_eq(trail.size(), 2)
	assert_true(is_equal_approx(float(trail[1].get("x", 0.0)), 0.47))
	assert_true(is_equal_approx(float(trail[1].get("y", 0.0)), 0.52))
	assert_eq(int(debug_state.get("continuity_breaks", 0)), 0)
	assert_lt(float(debug_state.get("last_jump_distance", 0.0)), 0.28)

func test_resolves_trail_hand_point_from_visible_finger_landmarks_when_wrist_is_low_visibility() -> void:
	var resolved := harness._resolve_trail_hand_point([
		{"id": 15, "x": 0.25, "y": 0.40, "v": 0.10},
		{"id": 19, "x": 0.31, "y": 0.46, "v": 0.62},
		{"id": 17, "x": 0.29, "y": 0.44, "v": 0.58},
		{"id": 21, "x": 0.33, "y": 0.42, "v": 0.54},
	], harness.LEFT_WRIST_ID, [harness.LEFT_INDEX_ID, harness.LEFT_PINKY_ID, harness.LEFT_THUMB_ID])
	assert_false(resolved.is_empty())
	assert_true(float(resolved.get("v", 0.0)) >= 0.54)
	assert_true(float(resolved.get("x", 0.0)) > 0.29 and float(resolved.get("x", 0.0)) < 0.32)
	assert_true(float(resolved.get("y", 0.0)) > 0.43 and float(resolved.get("y", 0.0)) < 0.45)

func test_resolves_trail_hand_point_by_clamping_near_edge_jitter() -> void:
	var resolved := harness._resolve_trail_hand_point([
		{"id": 16, "x": 1.03, "y": 0.41, "v": 0.44},
		{"id": 20, "x": 0.99, "y": 0.43, "v": 0.61},
		{"id": 18, "x": 1.02, "y": 0.39, "v": 0.57},
	], harness.RIGHT_WRIST_ID, [harness.RIGHT_INDEX_ID, harness.RIGHT_PINKY_ID, harness.RIGHT_THUMB_ID])
	assert_false(resolved.is_empty())
	assert_true(float(resolved.get("x", 0.0)) >= 0.98 and float(resolved.get("x", 0.0)) <= 1.0)
	assert_true(float(resolved.get("y", 0.0)) >= 0.39 and float(resolved.get("y", 0.0)) <= 0.43)

func test_resolves_trail_hand_point_from_raw_tracking_frame_visibility_field() -> void:
	var resolved := harness._resolve_trail_hand_point([
		{"id": 15, "x": 0.24, "y": 0.18, "visibility": 0.93},
	], harness.LEFT_WRIST_ID, [harness.LEFT_INDEX_ID, harness.LEFT_PINKY_ID, harness.LEFT_THUMB_ID])
	assert_false(resolved.is_empty())
	assert_true(is_equal_approx(float(resolved.get("x", 0.0)), 0.24))
	assert_true(is_equal_approx(float(resolved.get("y", 0.0)), 0.18))

func test_fallback_clamp_still_rejects_large_out_of_bounds_overshoot() -> void:
	var resolved := harness._resolve_trail_hand_point([
		{"id": 16, "x": 1.20, "y": 0.41, "v": 0.10},
		{"id": 20, "x": 0.99, "y": 0.43, "v": 0.61},
		{"id": 18, "x": 1.12, "y": 0.39, "v": 0.57},
	], harness.RIGHT_WRIST_ID, [harness.RIGHT_INDEX_ID, harness.RIGHT_PINKY_ID, harness.RIGHT_THUMB_ID])
	assert_true(resolved.is_empty())

func test_low_visibility_gap_breaks_existing_trail_before_reseed() -> void:
	var trail: Array = []
	var debug_state := _debug_state()
	harness._append_trail_point(trail, {"x": 0.40, "y": 0.45, "v": 0.99}, 1000, debug_state)
	harness._append_trail_point(trail, {"x": 0.42, "y": 0.47, "v": 0.05}, 1033, debug_state)
	assert_eq(trail.size(), 2)
	assert_true(float(trail[1].get("x", 0.0)) < 0.0)
	assert_true(float(trail[1].get("y", 0.0)) < 0.0)
	assert_eq(int(debug_state.get("continuity_breaks", 0)), 1)
	assert_eq(String(debug_state.get("last_action", "")), "break_low_visibility")
	harness._append_trail_point(trail, {"x": 0.46, "y": 0.48, "v": 0.99}, 1066, debug_state)
	assert_eq(trail.size(), 3)
	assert_true(is_equal_approx(float(trail[2].get("x", 0.0)), 0.46))
	assert_true(is_equal_approx(float(trail[2].get("y", 0.0)), 0.48))
	assert_eq(int(debug_state.get("reseeds", 0)), 2)

func test_missing_gap_breaks_existing_trail_once() -> void:
	var trail: Array = []
	var debug_state := _debug_state()
	harness._append_trail_point(trail, {"x": 0.35, "y": 0.44, "v": 0.99}, 1000, debug_state)
	harness._append_trail_point(trail, {}, 1033, debug_state)
	harness._append_trail_point(trail, {}, 1066, debug_state)
	assert_eq(trail.size(), 2)
	assert_true(float(trail[1].get("x", 0.0)) < 0.0)
	assert_true(float(trail[1].get("y", 0.0)) < 0.0)
	assert_eq(int(debug_state.get("continuity_breaks", 0)), 1)
	assert_eq(int(debug_state.get("missing_skips", 0)), 2)
	assert_eq(String(debug_state.get("last_action", "")), "missing")

func test_out_of_bounds_point_still_clears_trail() -> void:
	var trail: Array = []
	var debug_state := _debug_state()
	harness._append_trail_point(trail, {"x": 0.40, "y": 0.45, "v": 0.99}, 1000, debug_state)
	harness._append_trail_point(trail, {"x": 1.10, "y": 0.45, "v": 0.99}, 1033, debug_state)
	assert_eq(trail.size(), 0)
	assert_eq(int(debug_state.get("out_of_bounds_clears", 0)), 1)
	assert_eq(String(debug_state.get("last_action", "")), "clear_oob")

func test_preview_only_audit_defaults_to_provider_disabled() -> void:
	harness.startup_mode = harness.StartupMode.PREVIEW_ONLY_DEBUG
	assert_eq(harness._preview_only_audit_text(), "provider=disabled (expected)")
	assert_true(harness._build_live_status_text().contains("audit=provider=disabled (expected)"))

func test_preview_only_pose_activity_invalidates_surface_and_clears_overlay_state() -> void:
	harness.startup_mode = harness.StartupMode.PREVIEW_ONLY_DEBUG
	harness._latest_landmarks = [{"id": 15, "x": 0.25, "y": 0.40, "v": 0.99}]
	harness._left_trail = [{"x": 0.25, "y": 0.40, "v": 0.99, "timestamp_ms": 1000}]
	harness._right_trail = [{"x": 0.75, "y": 0.40, "v": 0.99, "timestamp_ms": 1000}]
	harness._on_pose_updated([{"id": 16, "x": 0.75, "y": 0.40, "v": 0.99}])
	assert_eq(harness._preview_only_invalid_reason, "pose/provider activity reached preview-only rung")
	assert_eq(harness._event_count("preview_only_invalid"), 1)
	assert_eq(harness._latest_landmarks.size(), 0)
	assert_eq(harness._left_trail.size(), 0)
	assert_eq(harness._right_trail.size(), 0)
	assert_true(harness._preview_only_audit_text().contains("INVALID:"))

func test_preview_only_provider_node_drift_invalidates_surface() -> void:
	harness.startup_mode = harness.StartupMode.PREVIEW_ONLY_DEBUG
	harness.provider = add_child_autoqfree(Node.new())
	harness._audit_preview_only_surface()
	assert_eq(harness._preview_only_invalid_reason, "provider node active in preview-only rung")
	assert_eq(harness._event_count("preview_only_invalid"), 1)

func test_effective_camera_source_prefers_repo_singleton_tracking_session_config_when_present() -> void:
	var singleton = get_tree().root.get_node_or_null("AeroCameraTracking")
	assert_not_null(singleton)

	var tracker = CameraTrackingScript.new()
	tracker.set_backend(CameraTrackingFakeBackendScript.new([
		{"id": "/dev/video0", "label": "Default camera"},
		{"id": "/dev/video9", "label": "USB camera"},
	]))
	singleton.set_tracking_session(tracker)

	add_child(harness)
	assert_true(harness._uses_camera_tracking_contract_path())

	tracker.start({
		"source": {"kind": "live_camera", "camera_id": "/dev/video9"},
	})

	assert_eq(harness._get_effective_camera_source(), "/dev/video9")
	singleton.stop()

func test_load_available_camera_devices_prefers_repo_singleton_contract_lane() -> void:
	var singleton = get_tree().root.get_node_or_null("AeroCameraTracking")
	assert_not_null(singleton)

	var tracker = CameraTrackingScript.new()
	tracker.set_backend(CameraTrackingFakeBackendScript.new([
		{"id": "/dev/video7", "label": "Front camera"},
		{"id": "/dev/video3", "label": "USB camera"},
	]))
	singleton.set_tracking_session(tracker)
	tracker.start({
		"source": {"kind": "live_camera", "camera_id": "/dev/video7"},
	})
	add_child(harness)

	var singleton_devices: Array = singleton.get_available_camera_devices()
	var harness_devices: Array = harness._load_available_camera_devices()
	assert_eq(harness_devices, singleton_devices)
	singleton.stop()

func test_replay_proving_prefers_singleton_playback_controller() -> void:
	var singleton = get_tree().root.get_node_or_null("AeroCameraTracking")
	assert_not_null(singleton)

	harness.prerecorded_video_source = "res://fixtures/replay/head_rotate_left_repeat_04_take_01.mp4"
	harness.startup_mode = harness.StartupMode.GODOT_ONLY_DEBUG
	harness.camera_view = TextureRect.new()
	harness.add_child(harness.camera_view)
	add_child(harness)

	assert_true(harness._playback_controller_uses_singleton())
	assert_true(harness._load_playback_source_if_needed())
	harness._refresh_playback_status(true)
	assert_true(singleton.has_replay_playback_loaded())
	assert_eq(String(singleton.get_replay_playback_state().get("source", {}).get("path", "")), ProjectSettings.globalize_path(harness.prerecorded_video_source))
	assert_eq([], _replay_requests)
	assert_false(bool(harness._playback_status.get("paused", true)))

func test_replay_proving_autoplays_when_same_source_is_already_loaded_but_paused() -> void:
	var singleton = get_tree().root.get_node_or_null("AeroCameraTracking")
	assert_not_null(singleton)
	var replay_path := ProjectSettings.globalize_path("res://fixtures/replay/head_rotate_left_repeat_04_take_01.mp4")
	assert_true(singleton.ensure_replay_playback_loaded(replay_path))
	assert_true(singleton.has_replay_playback_loaded())

	harness.prerecorded_video_source = "res://fixtures/replay/head_rotate_left_repeat_04_take_01.mp4"
	harness.startup_mode = harness.StartupMode.GODOT_ONLY_DEBUG
	harness.camera_view = TextureRect.new()
	harness.add_child(harness.camera_view)
	add_child(harness)

	assert_true(harness._load_playback_source_if_needed())
	assert_eq([], _replay_requests)
	assert_false(harness._playback_autoplay_pending)

func test_replay_pause_hold_blocks_refresh_autoplay_after_user_pause() -> void:
	var fake_singleton := add_child_autoqfree(FakeReplayTransportSingleton.new()) as FakeReplayTransportSingleton
	harness = ContractAwareHarness.new()
	harness.fake_singleton = fake_singleton
	harness.prerecorded_video_source = "res://fixtures/replay/example.mp4"
	harness.startup_mode = harness.StartupMode.GODOT_ONLY_DEBUG
	harness.camera_view = TextureRect.new()
	harness.add_child(harness.camera_view)
	add_child(harness)

	fake_singleton.replay_state["state"] = "playing"
	fake_singleton.transport_status["paused"] = false
	harness._playback_autoplay_pending = true
	harness._sync_playback_status_from_manager()
	assert_false(bool(harness._playback_status.get("paused", true)))

	harness._on_playback_toggle_pressed()
	harness._playback_autoplay_pending = true
	harness._refresh_playback_status(true)

	assert_true(bool(harness._playback_status.get("paused", false)))
	assert_eq(String(fake_singleton.replay_state.get("state", "")), "paused")
	assert_true(harness._playback_pause_hold)
	assert_true(harness._playback_autoplay_pending)

func test_prerecorded_visibility_refresh_stays_active_in_godot_only_replay_mode() -> void:
	harness.prerecorded_video_source = "res://fixtures/replay/head_rotate_left_repeat_04_take_01.mp4"
	harness.startup_mode = harness.StartupMode.GODOT_ONLY_DEBUG
	harness._refresh_playback_controls_visibility()
	assert_true(harness._playback_visibility_active)
	assert_true(harness._playback_autoplay_pending)

func test_live_camera_visibility_refresh_does_not_unload_playback_controller() -> void:
	if harness != null:
		harness.free()
	harness = PlaybackTrackingHarness.new()
	harness.startup_mode = harness.StartupMode.TRACKING
	harness._refresh_playback_controls_visibility()
	assert_eq(harness.unload_calls, 0)
	assert_false(harness._playback_visibility_active)

func test_overlay_drawers_are_forced_full_rect_and_receive_pose_updates() -> void:
	var landmark_drawer := FakeOverlayDrawer.new()
	landmark_drawer.name = "LandmarkDrawer"
	var trail_drawer := FakeOverlayDrawer.new()
	trail_drawer.name = "TrailDrawer"
	var camera_host := TextureRect.new()
	camera_host.name = "CameraDisplay"
	camera_host.size = Vector2(640, 360)
	camera_host.custom_minimum_size = camera_host.size
	camera_host.add_child(landmark_drawer)
	camera_host.add_child(trail_drawer)
	harness.add_child(camera_host)
	add_child(harness)

	harness._ensure_overlay_drawers_ready()
	assert_eq(landmark_drawer.anchor_right, 1.0)
	assert_eq(landmark_drawer.anchor_bottom, 1.0)
	assert_eq(landmark_drawer.offset_left, 0.0)
	assert_eq(landmark_drawer.offset_bottom, 0.0)
	assert_eq(landmark_drawer.z_index, harness.LANDMARK_DRAWER_Z_INDEX)
	assert_eq(trail_drawer.z_index, harness.TRAIL_DRAWER_Z_INDEX)

	harness._on_pose_updated([
		{"id": 15, "x": 0.25, "y": 0.40, "v": 0.95},
		{"id": 16, "x": 0.75, "y": 0.42, "v": 0.97},
	])
	assert_eq(landmark_drawer.update_calls.size(), 1)
	assert_eq(float(landmark_drawer.update_calls[0].get("min_visibility", 0.0)), harness.overlay_visibility_threshold)
	assert_eq(trail_drawer.update_calls.size(), 1)

func test_motion_trails_prefer_presenter_tracking_frame_landmarks_when_available() -> void:
	var presenter := FakePreviewPresenter.new()
	presenter.tracking_frame = {
		"landmarks": [
			{"id": 15, "x": 0.22, "y": 0.18, "visibility": 0.94},
			{"id": 16, "x": 0.78, "y": 0.26, "visibility": 0.91},
		],
	}
	add_child(presenter)
	harness.set("_preview_presenter", presenter)

	harness._update_motion_trails([
		{"id": 15, "x": 0.22, "y": 0.82, "v": 0.94},
		{"id": 16, "x": 0.78, "y": 0.74, "v": 0.91},
	])

	assert_eq(harness._left_trail.size(), 1)
	assert_eq(harness._right_trail.size(), 1)
	assert_true(is_equal_approx(float(harness._left_trail[0].get("y", -1.0)), 0.18))
	assert_true(is_equal_approx(float(harness._right_trail[0].get("y", -1.0)), 0.26))

func test_pose_updates_feed_preview_space_landmarks_into_boxing_scene_hit_targets() -> void:
	var presenter := FakePreviewPresenter.new()
	add_child(presenter)
	harness.set("_preview_presenter", presenter)

	var landmark_drawer: Control = add_child_autoqfree(LandmarkDrawerScript.new())
	landmark_drawer.size = presenter.content_rect.size
	landmark_drawer.set_preview_presenter(presenter)
	harness.landmark_drawer = landmark_drawer
	harness.show_landmarks = true

	harness._on_pose_updated([
		{"id": 15, "x": 0.64, "y": 0.48, "v": 0.94},
		{"id": 16, "x": 0.36, "y": 0.48, "v": 0.94},
	])

	var hit_targets: Array[Dictionary] = landmark_drawer.get_hit_target_snapshot()
	assert_eq(hit_targets.size(), 2)
	var left_hit_target: Dictionary = hit_targets[0]
	var right_hit_target: Dictionary = hit_targets[1]
	assert_true(is_equal_approx((left_hit_target.get("center", Vector2.ZERO) as Vector2).x, 409.6))
	assert_true(is_equal_approx((left_hit_target.get("center", Vector2.ZERO) as Vector2).y, 172.8))
	assert_true(is_equal_approx((right_hit_target.get("center", Vector2.ZERO) as Vector2).x, 230.4))
	assert_true(is_equal_approx((right_hit_target.get("center", Vector2.ZERO) as Vector2).y, 172.8))

func test_contract_preview_surface_mounts_tool_owned_presenter_and_reparents_overlay_layers() -> void:
	if harness != null:
		harness.free()
	harness = ContractAwareHarness.new()
	var tracking_session := CameraTrackingScript.new()
	var backend = CameraTrackingFakeBackendScript.new()
	tracking_session.set_backend(backend, "fake")
	tracking_session.start({
		"source": {"kind": "live_camera", "camera_id": "/dev/video0"},
		"preview": {"enabled": true, "flip_horizontal": true},
	})
	add_child_autofree(tracking_session)

	var fake_singleton := add_child_autoqfree(FakeTrackingContractSingleton.new()) as FakeTrackingContractSingleton
	fake_singleton.tracking_session = tracking_session
	harness.fake_singleton = fake_singleton

	var camera_host := TextureRect.new()
	camera_host.name = "CameraDisplay"
	camera_host.size = Vector2(640, 360)
	camera_host.custom_minimum_size = camera_host.size
	var landmark_drawer := FakeOverlayDrawer.new()
	landmark_drawer.name = "LandmarkDrawer"
	var trail_drawer := FakeOverlayDrawer.new()
	trail_drawer.name = "TrailDrawer"
	camera_host.add_child(landmark_drawer)
	camera_host.add_child(trail_drawer)
	harness.add_child(camera_host)
	add_child(harness)

	harness.camera_display = camera_host
	harness.landmark_drawer = landmark_drawer
	harness.trail_drawer = trail_drawer
	harness._ensure_contract_preview_surface()

	assert_not_null(harness.get("_preview_presenter"))
	assert_same(landmark_drawer.get_parent(), harness.get("_preview_presenter"))
	assert_same(trail_drawer.get_parent(), harness.get("_preview_presenter"))
	assert_not_null(harness.camera_view)

func test_start_provider_mounts_contract_preview_presenter_after_live_session_starts() -> void:
	if harness != null:
		harness.free()
	harness = ContractAwareHarness.new()
	var fake_singleton := add_child_autoqfree(FakeLiveTrackingContractSingleton.new()) as FakeLiveTrackingContractSingleton
	harness.fake_singleton = fake_singleton

	var camera_host := TextureRect.new()
	camera_host.name = "CameraDisplay"
	camera_host.size = Vector2(640, 360)
	camera_host.custom_minimum_size = camera_host.size
	harness.add_child(camera_host)
	add_child(harness)

	harness.startup_mode = harness.StartupMode.TRACKING
	harness.camera_display = camera_host
	harness._start_provider()

	assert_eq(fake_singleton.start_live_calls, 1)
	assert_not_null(harness.get("_preview_presenter"))
	assert_not_null(harness.camera_view)
	assert_not_null(fake_singleton.tracking_session)
	assert_true(fake_singleton.tracking_session.get_preview_descriptor().get("attached"))
	assert_eq(int(fake_singleton.tracking_session.get_preview_descriptor().get("attached_surface_count", 0)), 1)

func test_clearing_live_runtime_state_keeps_repo_singleton_alive() -> void:
	var singleton = get_tree().root.get_node_or_null("AeroCameraTracking")
	assert_not_null(singleton)
	harness.provider = singleton
	add_child(harness)

	harness._clear_live_camera_runtime_state()
	assert_null(harness.provider)
	assert_same(get_tree().root.get_node_or_null("AeroCameraTracking"), singleton)
	assert_true(is_instance_valid(singleton))

func test_singleton_runtime_config_includes_prepared_vendor_runtime_facts() -> void:
	var auto_start_manager: FakeAutoStartManager = add_child_autoqfree(FakeAutoStartManager.new()) as FakeAutoStartManager
	harness.auto_start_manager = auto_start_manager
	add_child(harness)

	var runtime_config = harness._build_runtime_config()
	assert_true(runtime_config is Resource)
	var runtime: Dictionary = (runtime_config as Resource).get("runtime")
	var vendor_root := ProjectSettings.globalize_path("res://addons/aerobeat-vendor-mediapipe-python")
	assert_eq(runtime.get("python_executable", ""), vendor_root.path_join(".venv/bin/python"))
	assert_eq(runtime.get("entrypoint", ""), vendor_root.path_join("runtime/mediapipe_runtime_probe.py"))
	assert_eq(runtime.get("working_directory", ""), vendor_root)
	assert_eq(runtime.get("pose_landmarker_model_path", ""), vendor_root.path_join("models/pose_landmarker_lite.task"))
	assert_eq(int(runtime.get("model_complexity", -1)), 0)
	var selected_style := String((runtime_config as Resource).get_selected_profile_bundle().get("camera_tracking", {}).get("tracking", {}).get("pose", {}).get("smoothing_style", "")).strip_edges().to_lower()
	var expects_filter_enabled := selected_style == "lite_filtered"
	assert_eq(bool(runtime.get("filter_enabled", false)), expects_filter_enabled)
	assert_eq(bool(runtime.get("no_filter", true)), not expects_filter_enabled)

func test_exposed_tracking_smoothing_styles_stay_backed_by_existing_vendor_assets() -> void:
	add_child(harness)
	var exposed_styles := [
		{"value": harness.TrackingSmoothingStyle.LITE_RAW, "label": "LITE_RAW", "filter_enabled": false},
		{"value": harness.TrackingSmoothingStyle.LITE_FILTERED, "label": "LITE_FILTERED", "filter_enabled": true},
	]
	assert_eq(harness.TrackingSmoothingStyle.size(), exposed_styles.size())
	assert_true(harness.TrackingSmoothingStyle.has("LITE_RAW"))
	assert_true(harness.TrackingSmoothingStyle.has("LITE_FILTERED"))

	for style in exposed_styles:
		harness.tracking_smoothing_style = int(style.get("value", -1))
		var config := harness._build_runtime_config() as Resource
		var runtime: Dictionary = config.get("runtime")
		var model_path := String(runtime.get("pose_landmarker_model_path", ""))
		var selected_style := String(config.get_selected_profile_bundle().get("camera_tracking", {}).get("tracking", {}).get("pose", {}).get("smoothing_style", "")).strip_edges().to_lower()
		var expects_filter_enabled := selected_style == "lite_filtered"
		assert_true(FileAccess.file_exists(model_path), "%s should map to an existing vendor model asset" % String(style.get("label", "unknown")))
		assert_eq(int(runtime.get("model_complexity", -1)), 0)
		assert_eq(bool(runtime.get("filter_enabled", false)), expects_filter_enabled)
		assert_eq(bool(runtime.get("no_filter", true)), not expects_filter_enabled)
		assert_eq(String(config.get("tracking_overlay_mode")), "optimized")

func test_profile_declared_median_of_3_reports_raw_runtime_spec() -> void:
	harness.free()
	harness = ContractAwareHarness.new()
	add_child(harness)
	var tracking_singleton := FakeProfileBundleTrackingSingleton.new()
	tracking_singleton.bundle = {
		"ok": true,
		"camera_tracking": {
			"tracking": {
				"pose": {
					"smoothing_style": "median_of_3",
				}
			}
		}
	}
	harness.fake_singleton = tracking_singleton
	var spec := harness._tracking_smoothing_style_spec()
	assert_eq(String(spec.get("label", "")), "Median-of-3 + raw")
	assert_true(bool(spec.get("no_filter", false)))
	assert_false(spec.has("filter_enabled"))

func test_profile_declared_adaptive_exponential_moving_average_reports_raw_runtime_spec() -> void:
	harness.free()
	harness = ContractAwareHarness.new()
	add_child(harness)
	var tracking_singleton := FakeProfileBundleTrackingSingleton.new()
	tracking_singleton.bundle = {
		"ok": true,
		"camera_tracking": {
			"tracking": {
				"pose": {
					"smoothing_style": "adaptive_exponential_moving_average",
				}
			}
		}
	}
	harness.fake_singleton = tracking_singleton
	var spec := harness._tracking_smoothing_style_spec()
	assert_eq(String(spec.get("label", "")), "Adaptive EMA + raw")
	assert_true(bool(spec.get("no_filter", false)))
	assert_false(spec.has("filter_enabled"))

func test_profile_declared_micro_deadband_adaptive_reports_raw_runtime_spec() -> void:
	harness.free()
	harness = ContractAwareHarness.new()
	add_child(harness)
	var tracking_singleton := FakeProfileBundleTrackingSingleton.new()
	tracking_singleton.bundle = {
		"ok": true,
		"camera_tracking": {
			"tracking": {
				"pose": {
					"smoothing_style": "micro_deadband_adaptive",
				}
			}
		}
	}
	harness.fake_singleton = tracking_singleton
	var spec := harness._tracking_smoothing_style_spec()
	assert_eq(String(spec.get("label", "")), "Micro-deadband adaptive + raw")
	assert_true(bool(spec.get("no_filter", false)))
	assert_false(spec.has("filter_enabled"))

func test_camera_picker_accepts_camera_id_only_device_entries() -> void:
	harness._camera_devices = [
		{"camera_id": "/dev/video7", "label": "USB camera"},
		{"camera_id": "/dev/video9", "label": "Second USB camera"},
	]
	assert_eq(harness._first_camera_device_id(harness._camera_devices), "/dev/video7")
	assert_true(harness._device_list_has_id(harness._camera_devices, "/dev/video9"))
	assert_eq(harness._camera_device_label(harness._camera_devices[0]), "USB camera (/dev/video7)")

func test_connect_mode_signals_does_not_stack_boxing_relays() -> void:
	var signal_provider := add_child_autoqfree(FakeSignalProvider.new()) as FakeSignalProvider
	harness.provider = signal_provider
	harness.harness_mode = harness.HarnessMode.BOXING
	harness._connect_mode_signals()
	harness._connect_mode_signals()
	signal_provider.punch_left.emit(0.75)
	assert_eq(harness._event_count("punch_left"), 1)

func test_contract_camera_switch_uses_in_session_change_seam_without_restart_churn() -> void:
	if harness != null:
		harness.free()
	harness = ContractAwareHarness.new()
	var fake_singleton := FakeTrackingSingleton.new()
	harness.fake_singleton = fake_singleton
	harness.provider = fake_singleton
	harness._selected_live_camera_device_id = "/dev/video0"
	add_child(harness)
	harness.add_child(fake_singleton)
	var controls := Control.new()
	var picker := OptionButton.new()
	harness.add_child(controls)
	harness.add_child(picker)
	harness.camera_source_controls = controls
	harness.camera_source_picker = picker

	assert_true(await harness._apply_live_camera_source("/dev/video7"))
	assert_eq(fake_singleton.set_selected_calls, 1)
	assert_eq(fake_singleton.stop_calls, 0)
	assert_eq(harness._selected_live_camera_device_id, "/dev/video7")

func test_live_runtime_ready_uses_singleton_lane_without_sidecar_preview_stream() -> void:
	add_child(harness)
	harness.provider = add_child_autoqfree(Node.new())
	harness._server_ready = false
	harness.camera_view = null
	assert_true(harness._is_live_camera_runtime_ready())
	assert_false(harness._should_poll_sidecar_runtime_health())

func test_prerecorded_replay_does_not_poll_sidecar_health_as_live_camera_failure() -> void:
	if harness != null:
		harness.free()
	harness = TestProvingHarness.new()
	harness.prerecorded_video_source = "res://fixtures/replay/example.mp4"
	harness.startup_mode = harness.StartupMode.TRACKING
	var auto_start_manager: FakeAutoStartManager = add_child_autoqfree(FakeAutoStartManager.new()) as FakeAutoStartManager
	auto_start_manager.running = false
	harness.auto_start_manager = auto_start_manager
	add_child(harness)

	assert_false(harness._should_poll_sidecar_runtime_health())
	harness._frame_count = 59
	harness._process(0.016)
	assert_false(harness.last_status_message.to_lower().contains("python server died"))

func test_playback_seek_slider_expands_without_losing_vertical_alignment() -> void:
	if harness != null:
		harness.free()
	harness = TestProvingHarness.new()
	var camera_panel := Control.new()
	camera_panel.custom_minimum_size = Vector2(640.0, 360.0)
	camera_panel.size = Vector2(640.0, 360.0)
	add_child(camera_panel)
	camera_panel.add_child(harness)
	var display := TextureRect.new()
	display.name = "CameraDisplay"
	display.set_anchors_preset(Control.PRESET_FULL_RECT)
	camera_panel.add_child(display)
	harness.camera_display = display

	harness._ensure_playback_controls()
	assert_not_null(harness._playback_bar_panel)
	harness._playback_bar_panel.visible = true
	await get_tree().process_frame

	var toggle_rect := harness._playback_toggle_button.get_global_rect()
	var slider_rect := harness._playback_seek_slider.get_global_rect()
	var time_rect := harness._playback_time_label.get_global_rect()

	assert_gt(slider_rect.size.x, 300.0)
	assert_almost_eq(slider_rect.get_center().y, toggle_rect.get_center().y, 1.0)
	assert_almost_eq(slider_rect.get_center().y, time_rect.get_center().y, 1.0)

func test_replay_step_controls_report_approximate_transport_truthfully() -> void:
	if harness != null:
		harness.free()
	harness = ContractAwareHarness.new()
	var fake_singleton := add_child_autoqfree(FakeReplayTransportSingleton.new()) as FakeReplayTransportSingleton
	fake_singleton.transport_capabilities = {
		"transport_mode": "approx_time_seek",
		"can_step_forward": false,
		"can_step_backward": false,
		"can_seek_frame": false,
		"nominal_fps": 30.0,
		"frame_duration_sec": 1.0 / 30.0,
		"exactness_note": "Only approximate time seek is available on this replay path.",
		"limitation_code": "transport_unsupported",
	}
	fake_singleton.transport_status = {
		"transport_mode": "approx_time_seek",
		"can_step_forward": false,
		"can_step_backward": false,
		"can_seek_frame": false,
		"frame_index": null,
		"frame_count": null,
		"nominal_fps": 30.0,
		"frame_duration_sec": 1.0 / 30.0,
		"paused": true,
		"position_sec": 4.0,
		"duration_sec": 12.0,
		"exactness_note": "Only approximate time seek is available on this replay path.",
		"limitation_code": "transport_unsupported",
	}
	harness.fake_singleton = fake_singleton
	harness.prerecorded_video_source = "res://fixtures/replay/example.mp4"
	var camera_panel := Control.new()
	camera_panel.custom_minimum_size = Vector2(640.0, 360.0)
	camera_panel.size = Vector2(640.0, 360.0)
	add_child(camera_panel)
	camera_panel.add_child(harness)
	var display := TextureRect.new()
	display.name = "CameraDisplay"
	display.set_anchors_preset(Control.PRESET_FULL_RECT)
	camera_panel.add_child(display)
	harness.camera_display = display
	harness._ensure_playback_controls()
	harness._playback_autoplay_base_url = harness._playback_base_url()
	harness._playback_autoplay_pending = false
	harness._refresh_playback_status(true)

	assert_true(harness._playback_step_back_button.disabled)
	assert_true(harness._playback_step_forward_button.disabled)
	assert_false(harness._can_step_paused_playback())
	assert_true(String(harness._playback_step_status_label.text).contains("approx_time_seek"))
	assert_true(String(harness._playback_step_back_button.tooltip_text).contains("Frame step unavailable"))
	assert_false(harness._playback_step_status_label.visible)
	harness._request_playback_frame_step(1)
	assert_eq(fake_singleton.step_calls, [])

func test_replay_step_controls_delegate_exact_transport_steps() -> void:
	if harness != null:
		harness.free()
	harness = ContractAwareHarness.new()
	var fake_singleton := add_child_autoqfree(FakeReplayTransportSingleton.new()) as FakeReplayTransportSingleton
	fake_singleton.transport_capabilities = {
		"transport_mode": "exact_owned_frame_index",
		"can_step_forward": true,
		"can_step_backward": true,
		"can_seek_frame": true,
		"nominal_fps": 30.0,
		"frame_duration_sec": 1.0 / 30.0,
		"exactness_note": "Owned frame index stepping is exact on this fake transport.",
		"limitation_code": "",
	}
	fake_singleton.transport_status = {
		"transport_mode": "exact_owned_frame_index",
		"can_step_forward": true,
		"can_step_backward": true,
		"can_seek_frame": true,
		"frame_index": 120,
		"frame_count": 360,
		"nominal_fps": 30.0,
		"frame_duration_sec": 1.0 / 30.0,
		"paused": true,
		"position_sec": 4.0,
		"duration_sec": 12.0,
		"exactness_note": "Owned frame index stepping is exact on this fake transport.",
		"limitation_code": "",
	}
	harness.fake_singleton = fake_singleton
	harness.prerecorded_video_source = "res://fixtures/replay/example.mp4"
	var camera_panel := Control.new()
	camera_panel.custom_minimum_size = Vector2(640.0, 360.0)
	camera_panel.size = Vector2(640.0, 360.0)
	add_child(camera_panel)
	camera_panel.add_child(harness)
	var display := TextureRect.new()
	display.name = "CameraDisplay"
	display.set_anchors_preset(Control.PRESET_FULL_RECT)
	camera_panel.add_child(display)
	harness.camera_display = display
	harness._ensure_playback_controls()
	harness._playback_autoplay_base_url = harness._playback_base_url()
	harness._playback_autoplay_pending = false
	harness._refresh_playback_status(true)

	assert_false(harness._playback_step_back_button.disabled)
	assert_false(harness._playback_step_forward_button.disabled)
	assert_true(harness._can_step_paused_playback())
	assert_eq(String(harness._playback_step_status_label.text), "Exact frame stepping available for this replay source.")
	assert_true(harness._playback_step_status_label.visible)
	harness._request_playback_frame_step(1)
	assert_eq(fake_singleton.step_calls, [1])
	assert_eq(int(fake_singleton.transport_status.get("frame_index", -1)), 121)
	assert_almost_eq(float(harness._playback_status.get("current_time_sec", -1.0)), float(fake_singleton.replay_state.get("position", -1.0)), 0.0001)

func _fake_replay_transport_request(url: String) -> Dictionary:
	_replay_requests.append(url)
	if _replay_responses.has(url):
		return _replay_responses[url]
	return {
		"success": false,
		"code": "missing_stub",
		"message": "No stubbed response for %s" % url,
		"detail": {"url": url},
	}
