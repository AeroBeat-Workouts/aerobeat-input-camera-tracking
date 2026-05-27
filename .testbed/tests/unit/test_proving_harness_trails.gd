extends "res://addons/gut/test.gd"

const ProvingHarness = preload("res://scripts/proving_harness.gd")
const CameraTrackingScript = preload("res://addons/aerobeat-tool-camera-tracking/src/CameraTracking.gd")
const CameraTrackingFakeBackendScript = preload("res://addons/aerobeat-tool-camera-tracking/src/CameraTrackingFakeBackend.gd")
const MediaPipeCameraViewScript = preload("res://addons/aerobeat-input-camera-tracking/src/camera_view.gd")

class TestProvingHarness:
	extends "res://scripts/proving_harness.gd"

	func _ready() -> void:
		pass

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
	var drift_node := Node.new()
	drift_node.name = "MediaPipeProvider"
	harness.add_child(drift_node)
	harness._audit_preview_only_surface()
	assert_eq(harness._preview_only_invalid_reason, "provider node active in preview-only rung")
	assert_eq(harness._event_count("preview_only_invalid"), 1)

func test_effective_camera_source_prefers_camera_tracking_session_config_when_present() -> void:
	var tracker = CameraTrackingScript.new()
	tracker.name = "CameraTracking"
	harness.add_child(tracker)
	tracker.set_backend(CameraTrackingFakeBackendScript.new())
	tracker.start({
		"source": {"kind": "live_camera", "camera_id": "/dev/video9"},
	})

	assert_true(harness._uses_camera_tracking_contract_path())
	assert_eq(harness._get_effective_camera_source(), "/dev/video9")

func test_replay_proving_prefers_singleton_playback_controller() -> void:
	var singleton = get_tree().root.get_node_or_null("AeroCameraTracking")
	assert_not_null(singleton)
	singleton.set_replay_playback_transport_request(Callable(self, "_fake_replay_transport_request"))
	_replay_responses["http://127.0.0.1:4243/playback"] = {
		"success": true,
		"body": {"paused": true, "current_time_sec": 2.0, "duration_sec": 8.0, "progress": 0.25},
	}

	harness.prerecorded_video_source = "res://fixtures/replay/head_rotate_left_repeat_04_take_01.mp4"
	harness.startup_mode = harness.StartupMode.GODOT_ONLY_DEBUG
	harness.camera_view = MediaPipeCameraViewScript.new()
	harness.camera_view.stream_url = "http://127.0.0.1:4243/camera"
	harness.add_child(harness.camera_view)
	add_child(harness)

	assert_true(harness._playback_controller_uses_singleton())
	assert_true(harness._load_playback_source_if_needed())
	harness._refresh_playback_status(true)
	assert_eq(harness._fallback_playback_manager, null)
	assert_true(singleton.has_replay_playback_loaded())
	assert_eq(float(harness._playback_status.get("current_time_sec", 0.0)), 2.0)
	assert_eq(["http://127.0.0.1:4243/playback", "http://127.0.0.1:4243/playback"], _replay_requests)

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
