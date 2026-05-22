extends "res://addons/gut/test.gd"

const InputProviderAdapterScript = preload("res://addons/aerobeat-input-camera-tracking/src/input_provider.gd")
const RegistryScript = preload("res://addons/aerobeat-input-core/src/runtime/provider_session_registry.gd")
const CameraTrackingScript = preload("res://addons/aerobeat-tool-camera-tracking/src/CameraTracking.gd")
const CameraTrackingFakeBackendScript = preload("res://addons/aerobeat-tool-camera-tracking/src/CameraTrackingFakeBackend.gd")

class FakeProviderBackend:
	extends Node

	var config = null
	var start_call_count := 0
	var stop_call_count := 0

	func start() -> bool:
		start_call_count += 1
		return true

	func stop() -> void:
		stop_call_count += 1

func before_each() -> void:
	RegistryScript.clear_registry_for_testing()

func after_each() -> void:
	RegistryScript.clear_registry_for_testing()

func test_input_provider_adapter_reports_explicit_provider_id() -> void:
	var provider = add_child_autoqfree(InputProviderAdapterScript.new())
	assert_eq(provider.get_provider_id(), "mediapipe_python")

func test_input_provider_adapter_reports_boxing_velocity_and_lower_body_capabilities() -> void:
	var provider = add_child_autoqfree(InputProviderAdapterScript.new())
	assert_true(provider.has_capability(provider.Capability.GESTURE_RECOGNITION))
	assert_true(provider.has_capability(provider.Capability.VELOCITY))
	assert_true(provider.has_capability(provider.Capability.LOWER_BODY))

func test_input_provider_adapter_reemits_flow_signals_from_provider() -> void:
	var adapter = add_child_autoqfree(InputProviderAdapterScript.new())
	adapter._ensure_provider()
	var flow_calls: Array = []
	adapter.swing_left.connect(func(placement: int, direction: int) -> void:
		flow_calls.append([placement, direction])
	)
	adapter._provider.swing_left.emit(12, 5)
	assert_eq(flow_calls, [[12, 5]])

func test_input_provider_adapter_reemits_boxing_signals_from_provider() -> void:
	var adapter = add_child_autoqfree(InputProviderAdapterScript.new())
	adapter._ensure_provider()
	var punch_calls: Array = []
	adapter.punch_left.connect(func(power: float) -> void:
		punch_calls.append(power)
	)
	adapter._provider.punch_left.emit(0.75)
	assert_eq(punch_calls, [0.75])

func test_input_provider_adapter_publishes_started_session_for_shared_reuse() -> void:
	var setup := _make_started_legacy_adapter()
	var adapter := setup["adapter"] as Node
	assert_true(bool(setup["started"]))

	var request: Dictionary = RegistryScript.request_session({"session_key": "mediapipe_python"})
	assert_true(bool(request.get("ok", false)), "Started adapter should publish a shared mediapipe session")
	var session: Dictionary = request.get("session", {}) if request.get("session", {}) is Dictionary else {}
	var metadata: Dictionary = session.get("metadata", {}) if session.get("metadata", {}) is Dictionary else {}
	assert_same(session.get("provider", null), adapter)
	assert_eq(String(session.get("provider_id", "")), "mediapipe_python")
	assert_eq(String(metadata.get("shared_reuse_scope", "")), "same_runtime_only")
	assert_true(bool(metadata.get("legacy_fallback", false)))
	assert_eq(String(metadata.get("provider_lane", "")), "legacy_mediapipe")

	var acquire: Dictionary = RegistryScript.acquire_session("camera_gesture:testbed", {"session_key": "mediapipe_python"})
	assert_true(bool(acquire.get("ok", false)), "Published adapter session should be borrowable by downstream consumers")
	var acquired_session: Dictionary = acquire.get("session", {}) if acquire.get("session", {}) is Dictionary else {}
	assert_eq(int(acquired_session.get("borrower_count", -1)), 1)

func test_input_provider_adapter_unpublishes_owned_session_on_stop() -> void:
	var setup := _make_started_legacy_adapter()
	var adapter := setup["adapter"] as Node
	var backend := setup["backend"] as FakeProviderBackend

	adapter.stop()

	assert_false(bool(RegistryScript.request_session({"session_key": "mediapipe_python"}).get("ok", false)), "Stopping the owner adapter should unpublish its shared session")
	assert_eq(backend.stop_call_count, 1)

func test_input_provider_adapter_keeps_existing_owner_session_when_publication_collides() -> void:
	var first_setup := _make_started_legacy_adapter()
	var first_adapter := first_setup["adapter"] as Node
	var second_setup := _make_started_legacy_adapter()
	var second_adapter = second_setup["adapter"]
	var second_backend := second_setup["backend"] as FakeProviderBackend

	assert_true(bool(second_setup["started"]), "Publication collisions should not fail local provider startup")
	assert_eq(second_backend.start_call_count, 1)
	assert_eq(String(second_adapter._published_session_key), "")

	var request: Dictionary = RegistryScript.request_session({"session_key": "mediapipe_python"})
	assert_true(bool(request.get("ok", false)))
	var session: Dictionary = request.get("session", {}) if request.get("session", {}) is Dictionary else {}
	assert_same(session.get("provider", null), first_adapter, "The original owner should keep the canonical shared session")

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

	var request: Dictionary = RegistryScript.request_session({"session_key": "mediapipe_python"})
	assert_true(bool(request.get("ok", false)))
	var session: Dictionary = request.get("session", {}) if request.get("session", {}) is Dictionary else {}
	var metadata: Dictionary = session.get("metadata", {}) if session.get("metadata", {}) is Dictionary else {}
	assert_same(session.get("provider", null), adapter)
	assert_eq(String(metadata.get("provider_lane", "")), "camera_tracking")
	assert_false(bool(metadata.get("legacy_fallback", true)))

func test_input_provider_adapter_discovers_camera_tracking_session_before_falling_back() -> void:
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
	assert_same(adapter.get_tracking_session(), tracker)

func _make_started_legacy_adapter() -> Dictionary:
	var adapter = add_child_autoqfree(InputProviderAdapterScript.new())
	var backend = FakeProviderBackend.new()
	backend.name = "FakeProviderBackend"
	adapter._provider = backend
	adapter._provider_lane = "legacy_mediapipe"
	adapter._config = adapter._new_local_config()
	backend.config = adapter._config
	adapter.add_child(backend)
	return {
		"adapter": adapter,
		"backend": backend,
		"started": adapter.start("{}"),
	}

func _make_started_tracking_session() -> Dictionary:
	var tracker = CameraTrackingScript.new()
	tracker.name = "CameraTracking"
	var backend = CameraTrackingFakeBackendScript.new([
		{"id": "/dev/video7", "label": "Front camera"},
		{"id": "/dev/video3", "label": "USB camera"},
	])
	tracker.set_backend(backend)
	add_child_autoqfree(tracker)
	tracker.start({
		"source": {"kind": "live_camera", "camera_id": "/dev/video7"},
		"preview": {"flip_horizontal": true},
	})
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
