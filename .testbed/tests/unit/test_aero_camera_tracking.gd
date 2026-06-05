extends "res://addons/aerobeat-vendor-godot-unit-test/test.gd"

const AeroCameraTrackingScript = preload("res://addons/aerobeat-input-camera-tracking/src/AeroCameraTracking.gd")
const CameraTrackingScript = preload("res://addons/aerobeat-tool-camera-tracking/src/CameraTracking.gd")
const CameraTrackingFakeBackendScript = preload("res://addons/aerobeat-tool-camera-tracking/src/CameraTrackingFakeBackend.gd")
const CameraTrackingBackendRegistryScript = preload("res://addons/aerobeat-tool-camera-tracking/src/CameraTrackingBackendRegistry.gd")

class CameraOptionsFakeBackend extends CameraTrackingFakeBackendScript:
	var camera_options_response: Dictionary = {}
	var requested_camera_ids: Array = []

	func get_camera_options(camera_id: String = "") -> Dictionary:
		requested_camera_ids.append(camera_id)
		return camera_options_response.duplicate(true)

class PlaybackStatusFakeBackend extends CameraTrackingFakeBackendScript:
	func set_playback_status(current_time_sec: float, duration_sec: float, paused: bool = false, state_name: String = "playing") -> void:
		var safe_duration := maxf(duration_sec, 0.0)
		var safe_position := maxf(current_time_sec, 0.0)
		var progress := 0.0
		if safe_duration > 0.0:
			progress = minf(maxf(safe_position / safe_duration, 0.0), 1.0)
		playback_status = {
			"source": str(last_config.get("source", {}).get("path", "")),
			"state": state_name,
			"paused": paused,
			"current_time_sec": safe_position,
			"duration_sec": safe_duration,
			"progress": progress,
			"is_file_source": true,
		}

class TeardownTrackingSession extends CameraTrackingScript:
	static var total_stop_calls := 0

	func stop() -> void:
		total_stop_calls += 1
		super.stop()

class OwnedSessionAeroCameraTracking extends AeroCameraTrackingScript:
	func _load_script(path: String) -> Variant:
		if path == CAMERA_TRACKING_SCRIPT_PATH:
			return TeardownTrackingSession
		return super._load_script(path)

class PausePreservingTrackingSession extends CameraTrackingScript:
	var stop_preserving_calls := 0

	func prime_replay_snapshot(source_path: String, current_time_sec: float, tracking_frame: Dictionary, preview_descriptor: Dictionary = {}) -> void:
		_active_config = {
			"source": {
				"kind": "video_file",
				"path": source_path,
			},
		}
		_tracking_frame = tracking_frame.duplicate(true)
		_preview_descriptor = preview_descriptor.duplicate(true)
		_playback_status = {
			"source": source_path,
			"state": "playing",
			"paused": false,
			"current_time_sec": current_time_sec,
			"duration_sec": 30.0,
			"progress": current_time_sec / 30.0,
			"is_file_source": true,
		}
		_state = STATE_RUNNING

	func stop_preserving_runtime_state() -> void:
		stop_preserving_calls += 1
		_playback_status["paused"] = true
		_playback_status["state"] = "paused"
		_state = STATE_IDLE
		state_changed.emit(_state, {})

class StalePlaybackStatusTrackingSession extends CameraTrackingScript:
	var stop_preserving_calls := 0
	var transport_status: Dictionary = {
		"transport_mode": "approx_time_seek",
		"can_step_forward": false,
		"can_step_backward": false,
		"can_seek_frame": false,
		"frame_index": null,
		"frame_count": null,
		"nominal_fps": null,
		"frame_duration_sec": null,
		"paused": false,
		"position_sec": 0.0,
		"duration_sec": 30.0,
		"exactness_note": "Approximate time seek only.",
		"limitation_code": "backend_transport_unsupported",
	}

	func prime_replay_snapshot(source_path: String, current_time_sec: float, tracking_frame: Dictionary, preview_descriptor: Dictionary = {}) -> void:
		_active_config = {
			"source": {
				"kind": "video_file",
				"path": source_path,
			},
		}
		_tracking_frame = tracking_frame.duplicate(true)
		_preview_descriptor = preview_descriptor.duplicate(true)
		_playback_status = {
			"source": source_path,
			"state": "playing",
			"paused": false,
			"current_time_sec": current_time_sec,
			"duration_sec": 30.0,
			"progress": current_time_sec / 30.0,
			"is_file_source": true,
		}
		transport_status["paused"] = false
		transport_status["position_sec"] = current_time_sec
		transport_status["duration_sec"] = 30.0
		_state = STATE_RUNNING

	func stop_preserving_runtime_state() -> void:
		stop_preserving_calls += 1
		_state = STATE_IDLE
		state_changed.emit(_state, {})

	func get_replay_transport_capabilities() -> Dictionary:
		return {
			"transport_mode": transport_status.get("transport_mode", "approx_time_seek"),
			"can_step_forward": transport_status.get("can_step_forward", false),
			"can_step_backward": transport_status.get("can_step_backward", false),
			"can_seek_frame": transport_status.get("can_seek_frame", false),
			"nominal_fps": transport_status.get("nominal_fps", null),
			"frame_duration_sec": transport_status.get("frame_duration_sec", null),
			"exactness_note": transport_status.get("exactness_note", ""),
			"limitation_code": transport_status.get("limitation_code", "backend_transport_unsupported"),
		}

	func get_replay_transport_status() -> Dictionary:
		return transport_status.duplicate(true)

func before_each() -> void:
	CameraTrackingBackendRegistryScript.clear()
	TeardownTrackingSession.total_stop_calls = 0

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

func test_aero_camera_tracking_loads_selected_flow_profile_bundle_during_start() -> void:
	var singleton = add_child_autoqfree(AeroCameraTrackingScript.new())
	var tracker = CameraTrackingScript.new()
	tracker.set_backend(CameraTrackingFakeBackendScript.new())
	singleton.set_tracking_session(tracker)

	assert_true(singleton.start_live_camera("/dev/video7", {
		"profile": "flow",
	}))
	var bundle: Dictionary = singleton.get_selected_profile_bundle()
	assert_eq(singleton.get_selected_profile_id(), "flow")
	assert_true(bool(bundle.get("ok", false)))
	assert_eq(String(bundle.get("camera_tracking", {}).get("profile", "")), "flow")
	assert_eq(String(bundle.get("gesture_detection", {}).get("profile", "")), "flow")

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

	var active_config: Dictionary = tracker.get_active_config()
	var source: Dictionary = active_config.get("source", {})
	var vendor_source: Dictionary = (active_config.get("vendor", {}) as Dictionary).get("source", {})
	assert_eq(String(source.get("kind", "")), "video_file")
	assert_eq(String(source.get("path", "")), "res://fixtures/replay/head_rotate_left_repeat_04_take_01.mp4")
	assert_true(bool(vendor_source.get("loop", false)))

func test_aero_camera_tracking_replay_loop_override_is_respected() -> void:
	var singleton = add_child_autoqfree(AeroCameraTrackingScript.new())
	var tracker = CameraTrackingScript.new()
	tracker.set_backend(CameraTrackingFakeBackendScript.new())
	singleton.set_tracking_session(tracker)

	assert_true(singleton.start_replay("res://fixtures/replay/head_rotate_left_repeat_04_take_01.mp4", {
		"vendor": {
			"source": {
				"loop": false,
			},
		},
	}))

	var vendor_source: Dictionary = (tracker.get_active_config().get("vendor", {}) as Dictionary).get("source", {})
	assert_false(bool(vendor_source.get("loop", true)))

func test_aero_camera_tracking_delegates_get_camera_options_through_public_wrapper() -> void:
	var singleton = add_child_autoqfree(AeroCameraTrackingScript.new())
	var tracker = CameraTrackingScript.new()
	var backend := CameraOptionsFakeBackend.new()
	backend.camera_options_response = {
		"state": "running",
		"source": "live_camera",
		"camera_options": {
			"requested": {
				"camera_id": "/dev/video7",
			},
			"selected": {
				"camera_id": "/dev/video7",
				"fps": 30.0,
			},
		},
	}
	tracker.set_backend(backend)
	singleton.set_tracking_session(tracker)
	assert_true(singleton.start_live_camera("/dev/video7", {}))

	var expected: Dictionary = tracker.get_camera_options("/dev/video7")
	var camera_options: Dictionary = singleton.get_camera_options("/dev/video7")
	assert_true(backend.requested_camera_ids.has("/dev/video7"))
	assert_eq(camera_options, expected)
	camera_options["mutated"] = true
	assert_false(tracker.get_camera_options("/dev/video7").has("mutated"))

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

func test_aero_camera_tracking_prefers_public_tracking_session_playback_truth_for_replay_status() -> void:
	var singleton = add_child_autoqfree(AeroCameraTrackingScript.new())
	var tracker = CameraTrackingScript.new()
	var backend := PlaybackStatusFakeBackend.new()
	tracker.set_backend(backend)
	singleton.set_tracking_session(tracker)

	var replay_path := ProjectSettings.globalize_path("res://fixtures/replay/head_rotate_left_repeat_04_take_01.mp4")
	assert_true(singleton.start_replay(replay_path, {}))
	backend.set_playback_status(7.5, 30.0, false, "playing")

	var status: Dictionary = singleton.get_replay_playback_status()
	assert_eq(status.get("current_time_sec"), 7.5)
	assert_eq(status.get("duration_sec"), 30.0)
	assert_eq(status.get("progress"), 0.25)
	assert_false(bool(status.get("paused", true)))
	assert_eq(String(singleton.get_replay_playback_state().get("source", {}).get("path", "")), replay_path)
	assert_eq(float(singleton.get_replay_playback_state().get("duration", -1.0)), 30.0)
	assert_eq(float(singleton.get_replay_playback_state().get("position", -1.0)), 7.5)

func test_aero_camera_tracking_pause_preserves_visible_tracking_state_as_paused() -> void:
	var singleton = add_child_autoqfree(AeroCameraTrackingScript.new())
	var tracker := PausePreservingTrackingSession.new()
	var replay_path := ProjectSettings.globalize_path("res://fixtures/replay/head_rotate_left_repeat_04_take_01.mp4")
	var frame := {
		"timestamp_ms": 123,
		"source_id": replay_path,
		"tracking_state": "tracked",
		"preview_transform": {"flip_horizontal": true, "space": "gameplay_normalized"},
		"landmarks": [
			{"id": 0, "x": 0.5, "y": 0.15, "z": 0.0, "visibility": 0.95},
		],
	}
	var preview_descriptor := {"attached": true, "width": 640, "height": 360}
	tracker.prime_replay_snapshot(replay_path, 7.5, frame, preview_descriptor)
	singleton.set_tracking_session(tracker)
	singleton.set("_replay_source_path", replay_path)
	singleton.set("_replay_loaded", true)
	singleton.set("_replay_playing", true)
	singleton.set("_replay_position_sec", 7.5)

	var paused_head_position = singleton.get_provider().get_head_position()
	assert_true(singleton.pause_replay_playback())
	assert_eq(tracker.stop_preserving_calls, 1)
	assert_eq(singleton.get_provider().get_head_position(), paused_head_position)
	assert_eq(singleton.get_current_preview_descriptor(), preview_descriptor)
	var paused_status: Dictionary = singleton.get_replay_playback_status()
	assert_true(bool(paused_status.get("paused", false)))
	assert_eq(String(singleton.get_replay_playback_state().get("state", "")), "paused")
	assert_eq(float(paused_status.get("current_time_sec", -1.0)), 7.5)

func test_aero_camera_tracking_pause_preserves_paused_public_state_when_tracking_session_status_stays_stale_playing() -> void:
	var singleton = add_child_autoqfree(AeroCameraTrackingScript.new())
	var tracker := StalePlaybackStatusTrackingSession.new()
	var replay_path := ProjectSettings.globalize_path("res://fixtures/replay/head_rotate_left_repeat_04_take_01.mp4")
	var frame := {
		"timestamp_ms": 123,
		"source_id": replay_path,
		"tracking_state": "tracked",
		"preview_transform": {"flip_horizontal": true, "space": "gameplay_normalized"},
		"landmarks": [
			{"id": 0, "x": 0.5, "y": 0.15, "z": 0.0, "visibility": 0.95},
		],
	}
	tracker.prime_replay_snapshot(replay_path, 7.5, frame)
	singleton.set_tracking_session(tracker)
	singleton.set("_replay_source_path", replay_path)
	singleton.set("_replay_loaded", true)
	singleton.set("_replay_playing", true)
	singleton.set("_replay_position_sec", 7.5)
	var paused_head_position = singleton.get_provider().get_head_position()

	assert_true(singleton.pause_replay_playback())
	assert_eq(singleton.get_provider().get_head_position(), paused_head_position)
	assert_eq(tracker.stop_preserving_calls, 1)
	var paused_state: Dictionary = singleton.get_replay_playback_state()
	assert_eq(String(paused_state.get("state", "")), "paused")
	assert_true(bool((paused_state.get("status", {}) as Dictionary).get("paused", false)))
	assert_eq(float((paused_state.get("status", {}) as Dictionary).get("current_time_sec", -1.0)), 7.5)
	var transport_status: Dictionary = singleton.get_replay_transport_status()
	assert_true(bool(transport_status.get("paused", false)))
	assert_eq(float(transport_status.get("position_sec", -1.0)), 7.5)
	assert_eq(String(transport_status.get("transport_mode", "")), "approx_time_seek")
	assert_eq(String(transport_status.get("limitation_code", "")), "backend_transport_unsupported")

func test_aero_camera_tracking_resume_preserves_replay_loop_origin() -> void:
	var singleton = add_child_autoqfree(AeroCameraTrackingScript.new())
	var tracker = CameraTrackingScript.new()
	tracker.set_backend(CameraTrackingFakeBackendScript.new())
	singleton.set_tracking_session(tracker)

	var replay_path := ProjectSettings.globalize_path("res://fixtures/replay/head_rotate_left_repeat_04_take_01.mp4")
	assert_true(singleton.ensure_replay_playback_loaded(replay_path))
	singleton.set("_replay_position_sec", 7.5)
	singleton.set("_replay_loop_origin_sec", 1.25)

	assert_true(singleton.play_replay_playback())
	var vendor_source: Dictionary = (tracker.get_active_config().get("vendor", {}) as Dictionary).get("source", {})
	assert_eq(float(vendor_source.get("start_time_sec", -1.0)), 7.5)
	assert_eq(float(vendor_source.get("loop_start_time_sec", -1.0)), 1.25)

func test_aero_camera_tracking_stop_releases_wrapper_owned_provider_and_keeps_owned_session_reusable() -> void:
	var singleton = add_child_autoqfree(AeroCameraTrackingScript.new())
	var tracker = singleton.get_tracking_session()
	tracker.set_backend(CameraTrackingFakeBackendScript.new())

	assert_true(singleton.start_live_camera("/dev/video7", {}))
	var provider = singleton.get_provider()
	assert_same(provider.get_parent(), singleton)
	assert_same(tracker.get_parent(), singleton)

	singleton.stop()
	await get_tree().process_frame

	assert_null(singleton.get_node_or_null("CameraTrackingProvider"))
	assert_same(singleton.get_node_or_null("CameraTracking"), tracker)
	assert_false(is_instance_valid(provider))
	assert_true(is_instance_valid(tracker))
	assert_true(singleton.has_tracking_contract())
	assert_eq(singleton.get_replay_playback_state().get("state", ""), "idle")
	assert_true(singleton.start_live_camera("/dev/video3", {}))
	assert_eq(String(tracker.get_active_config().get("source", {}).get("camera_id", "")), "/dev/video3")

func test_aero_camera_tracking_stop_does_not_free_external_tracking_session() -> void:
	var singleton = add_child_autoqfree(AeroCameraTrackingScript.new())
	var tracker = CameraTrackingScript.new()
	tracker.set_backend(CameraTrackingFakeBackendScript.new())
	singleton.set_tracking_session(tracker)

	assert_true(singleton.start_live_camera("/dev/video7", {}))
	var provider = singleton.get_provider()

	singleton.stop()
	await get_tree().process_frame

	assert_false(is_instance_valid(provider))
	assert_true(is_instance_valid(tracker))
	assert_same(singleton.get_tracking_session_if_ready(), tracker)
	assert_true(singleton.start_live_camera("/dev/video3", {}))
	assert_eq(String(tracker.get_active_config().get("source", {}).get("camera_id", "")), "/dev/video3")

func test_aero_camera_tracking_scene_teardown_stops_and_releases_wrapper_owned_tracking_session() -> void:
	var singleton = add_child_autoqfree(OwnedSessionAeroCameraTracking.new())
	var tracker = singleton.get_tracking_session() as TeardownTrackingSession
	tracker.set_backend(CameraTrackingFakeBackendScript.new())

	assert_true(singleton.start_live_camera("/dev/video7", {}))
	var provider = singleton.get_provider()

	singleton.queue_free()
	await get_tree().process_frame

	assert_eq(TeardownTrackingSession.total_stop_calls, 2)
	assert_false(is_instance_valid(provider))
	assert_false(is_instance_valid(tracker))
