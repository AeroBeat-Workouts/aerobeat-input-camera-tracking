extends "res://addons/gut/test.gd"

const InputProviderAdapterScript = preload("res://addons/aerobeat-input-camera-tracking/src/input_provider.gd")
const RegistryScript = preload("res://addons/aerobeat-input-core/src/runtime/provider_session_registry.gd")
const CameraTrackingScript = preload("res://addons/aerobeat-tool-camera-tracking/src/CameraTracking.gd")
const CameraTrackingFakeBackendScript = preload("res://addons/aerobeat-tool-camera-tracking/src/CameraTrackingFakeBackend.gd")

func before_each() -> void:
	RegistryScript.clear_registry_for_testing()

func after_each() -> void:
	RegistryScript.clear_registry_for_testing()
	var singleton = get_tree().root.get_node_or_null("AeroCameraTracking")
	if singleton != null and singleton.has_method("stop"):
		singleton.stop()
	if singleton != null and singleton.has_method("set_tracking_session"):
		singleton.set_tracking_session(null)

func test_input_provider_adapter_reports_explicit_provider_id() -> void:
	var provider = add_child_autoqfree(InputProviderAdapterScript.new())
	assert_eq(provider.get_provider_id(), "camera_tracking")

func test_input_provider_adapter_reports_boxing_velocity_and_lower_body_capabilities() -> void:
	var provider = add_child_autoqfree(InputProviderAdapterScript.new())
	assert_true(provider.has_capability(provider.Capability.GESTURE_RECOGNITION))
	assert_true(provider.has_capability(provider.Capability.VELOCITY))
	assert_true(provider.has_capability(provider.Capability.LOWER_BODY))

func test_input_provider_adapter_reemits_flow_signals_from_provider() -> void:
	var adapter = _make_started_tracking_adapter()["adapter"] as Node
	var flow_calls: Array = []
	adapter.swing_left.connect(func(placement: int, direction: int) -> void:
		flow_calls.append([placement, direction])
	)
	adapter._provider.swing_left.emit(12, 5)
	assert_eq(flow_calls, [[12, 5]])

func test_input_provider_adapter_reemits_boxing_signals_from_provider() -> void:
	var adapter = _make_started_tracking_adapter()["adapter"] as Node
	var punch_calls: Array = []
	adapter.punch_left.connect(func(power: float) -> void:
		punch_calls.append(power)
	)
	adapter._provider.punch_left.emit(0.75)
	assert_eq(punch_calls, [0.75])

func test_input_provider_adapter_publishes_started_session_for_shared_reuse() -> void:
	var setup := _make_started_tracking_adapter({
		"source": {"kind": "live_camera", "camera_id": "/dev/video7"},
	})
	var adapter := setup["adapter"] as Node
	assert_true(bool(setup["started"]))

	var request: Dictionary = RegistryScript.request_session({"session_key": "camera_tracking"})
	assert_true(bool(request.get("ok", false)))
	var session: Dictionary = request.get("session", {}) if request.get("session", {}) is Dictionary else {}
	var metadata: Dictionary = session.get("metadata", {}) if session.get("metadata", {}) is Dictionary else {}
	assert_same(session.get("provider", null), adapter)
	assert_eq(String(session.get("provider_id", "")), "camera_tracking")
	assert_eq(String(metadata.get("shared_reuse_scope", "")), "same_runtime_only")
	assert_false(bool(metadata.get("legacy_fallback", true)))
	assert_eq(String(metadata.get("lane", "")), "camera_tracking")
	assert_eq(String(metadata.get("provider_lane", "")), "camera_tracking")
	assert_eq(String(metadata.get("runtime_mode", "")), "live")
	assert_eq(String(metadata.get("camera_source", "")), "/dev/video7")

	var acquire: Dictionary = adapter.acquire_shared_session("camera_gesture:testbed", {
		"provider_id": "camera_tracking",
		"metadata_match": {
			"runtime_mode": "live",
			"camera_source": "/dev/video7",
		},
	})
	assert_true(bool(acquire.get("ok", false)))
	var acquired_session: Dictionary = acquire.get("session", {}) if acquire.get("session", {}) is Dictionary else {}
	assert_eq(int(acquired_session.get("borrower_count", -1)), 1)

func test_input_provider_adapter_releases_borrower_counts_via_compatibility_helpers() -> void:
	var setup := _make_started_tracking_adapter()
	var adapter := setup["adapter"] as Node

	var acquire: Dictionary = adapter.acquire_shared_session("camera_gesture:testbed")
	assert_true(bool(acquire.get("ok", false)))
	var acquired_session: Dictionary = acquire.get("session", {}) if acquire.get("session", {}) is Dictionary else {}
	assert_eq(int(acquired_session.get("borrower_count", -1)), 1)

	var release: Dictionary = adapter.release_shared_session("camera_gesture:testbed")
	assert_true(bool(release.get("ok", false)))
	var released_session: Dictionary = release.get("session", {}) if release.get("session", {}) is Dictionary else {}
	assert_eq(int(released_session.get("borrower_count", -1)), 0)

func test_input_provider_adapter_reports_owned_shared_session_debug_state() -> void:
	var setup := _make_started_tracking_adapter({
		"source": {"kind": "live_camera", "camera_id": "/dev/video3"},
	})
	var adapter := setup["adapter"] as Node

	var debug_state: Dictionary = adapter.get_shared_session_debug_state()
	assert_eq(String(debug_state.get("session_role", "")), "owned")
	assert_eq(String(debug_state.get("session_key", "")), "camera_tracking")
	assert_eq(String(debug_state.get("provider_id", "")), "camera_tracking")
	assert_eq(String(debug_state.get("provider_lane", "")), "camera_tracking")
	assert_eq(String(debug_state.get("runtime_mode", "")), "live")
	assert_eq(String(debug_state.get("camera_source", "")), "/dev/video3")
	assert_false(bool(debug_state.get("borrowed", true)))
	assert_false(bool(debug_state.get("legacy_fallback", true)))

func test_input_provider_adapter_unpublishes_owned_session_on_stop() -> void:
	var setup := _make_started_tracking_adapter()
	var adapter := setup["adapter"] as Node

	adapter.stop()

	assert_false(bool(RegistryScript.request_session({"session_key": "camera_tracking"}).get("ok", false)))

func test_input_provider_adapter_keeps_existing_owner_session_when_publication_collides() -> void:
	var first_setup := _make_started_tracking_adapter({"source": {"kind": "live_camera", "camera_id": "/dev/video7"}})
	var first_adapter := first_setup["adapter"] as Node
	var second_setup := _make_started_tracking_adapter({"source": {"kind": "live_camera", "camera_id": "/dev/video3"}})
	var second_adapter := second_setup["adapter"] as Node

	assert_true(bool(second_setup["started"]))
	assert_eq(String(second_adapter._published_session_key), "")

	var request: Dictionary = RegistryScript.request_session({"session_key": "camera_tracking"})
	assert_true(bool(request.get("ok", false)))
	var session: Dictionary = request.get("session", {}) if request.get("session", {}) is Dictionary else {}
	assert_same(session.get("provider", null), first_adapter)

func test_input_provider_adapter_prefers_supplied_camera_tracking_session() -> void:
	var tracker_setup := _make_started_tracking_session()
	var tracker: Node = tracker_setup["tracker"]
	var backend: Variant = tracker_setup["backend"]
	var adapter = add_child_autoqfree(InputProviderAdapterScript.new())
	adapter.set_tracking_session(tracker)

	assert_true(adapter.start("{}"))
	assert_true(adapter.uses_camera_tracking_contract_path())
	assert_false(adapter.is_using_legacy_fallback())
	assert_eq(String(adapter._provider.name), "CameraTrackingProvider")
	assert_eq(adapter.get_selected_camera_device_id(), "/dev/video7")
	assert_eq(adapter.get_available_camera_devices().size(), 2)

	backend.emit_tracking_frame(_tracked_frame())
	assert_true(adapter.is_tracking())
	assert_ne(adapter.get_head_position(), Vector3.ZERO)
	assert_ne(adapter.get_left_hand_position(), Vector3.ZERO)

	assert_true(adapter.set_selected_camera_device_id("/dev/video3"))
	assert_eq(String(tracker.get_active_config().get("source", {}).get("camera_id", "")), "/dev/video3")

func test_input_provider_adapter_discovers_camera_tracking_session_before_start() -> void:
	var adapter = add_child_autoqfree(InputProviderAdapterScript.new())
	var tracker = CameraTrackingScript.new()
	tracker.name = "CameraTracking"
	var backend = CameraTrackingFakeBackendScript.new([
		{"id": "/dev/video7", "label": "Front camera"},
	])
	tracker.set_backend(backend)
	adapter.add_child(tracker)
	tracker.start({
		"source": {"kind": "live_camera", "camera_id": "/dev/video7"},
		"preview": {"flip_horizontal": true},
	})

	assert_true(adapter.start("{}"))
	assert_true(adapter.uses_camera_tracking_contract_path())
	assert_false(adapter.is_using_legacy_fallback())
	assert_not_null(adapter.get_tracking_session())

func test_input_provider_adapter_does_not_compose_a_local_session_when_none_is_discoverable() -> void:
	var adapter = add_child_autoqfree(InputProviderAdapterScript.new())
	adapter.clear_tracking_session()

	assert_null(adapter.get_tracking_session())
	assert_false(adapter.is_using_legacy_fallback())
	assert_false(adapter.uses_camera_tracking_contract_path())
	assert_false(adapter.start("{}"))

func test_input_provider_adapter_publishes_replay_metadata_from_camera_tracking_session() -> void:
	var fixture_path := "res://fixtures/replay/head_rotate_left_repeat_04_take_01.mp4"
	var tracker_setup := _make_started_tracking_session({
		"source": {"kind": "video_file", "path": fixture_path},
		"preview": {"flip_horizontal": false},
	})
	var tracker: Node = tracker_setup["tracker"]
	var adapter = add_child_autoqfree(InputProviderAdapterScript.new())
	adapter.set_tracking_session(tracker)

	assert_true(adapter.start("{}"))
	assert_true(adapter.uses_camera_tracking_contract_path())
	assert_false(adapter.is_using_legacy_fallback())
	assert_eq(adapter.get_selected_camera_device_id(), fixture_path)
	assert_false(adapter.set_selected_camera_device_id("/dev/video3"))

	var request: Dictionary = RegistryScript.request_session({"session_key": "camera_tracking"})
	assert_true(bool(request.get("ok", false)))
	var session: Dictionary = request.get("session", {}) if request.get("session", {}) is Dictionary else {}
	var metadata: Dictionary = session.get("metadata", {}) if session.get("metadata", {}) is Dictionary else {}
	assert_eq(String(metadata.get("runtime_mode", "")), "replay")
	assert_eq(String(metadata.get("source_kind", "")), "video_file")
	assert_eq(String(metadata.get("camera_source", "")), fixture_path)
	assert_eq(String(metadata.get("fixture_video_path", "")), fixture_path)
	assert_eq(String(metadata.get("lane", "")), "camera_tracking")
	assert_eq(String(metadata.get("provider_lane", "")), "camera_tracking")
	assert_false(bool(metadata.get("legacy_fallback", true)))

func test_input_provider_adapter_discovers_tracking_session_from_repo_singleton_when_ready() -> void:
	var singleton = get_tree().root.get_node_or_null("AeroCameraTracking")
	assert_not_null(singleton)
	var tracker_setup := _make_started_tracking_session({
		"source": {"kind": "live_camera", "camera_id": "/dev/video7"},
	})
	singleton.set_tracking_session(tracker_setup["tracker"])

	var adapter = add_child_autoqfree(InputProviderAdapterScript.new())
	assert_true(adapter.start("{}"))
	assert_true(adapter.uses_camera_tracking_contract_path())
	assert_same(adapter.get_tracking_session(), tracker_setup["tracker"])

func _make_started_tracking_adapter(config: Dictionary = {}) -> Dictionary:
	var tracker_setup := _make_started_tracking_session(config)
	var adapter = add_child_autoqfree(InputProviderAdapterScript.new())
	adapter.set_tracking_session(tracker_setup["tracker"])
	return {
		"adapter": adapter,
		"tracker": tracker_setup["tracker"],
		"backend": tracker_setup["backend"],
		"started": adapter.start("{}"),
	}

func _make_started_tracking_session(config: Dictionary = {}) -> Dictionary:
	var tracker = CameraTrackingScript.new()
	tracker.name = "CameraTracking"
	var backend = CameraTrackingFakeBackendScript.new([
		{"id": "/dev/video7", "label": "Front camera"},
		{"id": "/dev/video3", "label": "USB camera"},
	])
	tracker.set_backend(backend)
	add_child_autoqfree(tracker)
	var start_config := {
		"source": {"kind": "live_camera", "camera_id": "/dev/video7"},
		"preview": {"flip_horizontal": true},
	}
	for key in config.keys():
		start_config[key] = config[key]
	tracker.start(start_config)
	return {
		"tracker": tracker,
		"backend": backend,
	}

func _tracked_frame() -> Dictionary:
	return {
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
	}
