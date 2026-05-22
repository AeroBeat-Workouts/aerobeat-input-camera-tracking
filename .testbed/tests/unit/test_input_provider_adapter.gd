extends "res://addons/gut/test.gd"

const InputProviderAdapterScript = preload("res://addons/aerobeat-input-camera-tracking/src/input_provider.gd")
const RegistryScript = preload("res://addons/aerobeat-input-core/src/runtime/provider_session_registry.gd")

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
	var setup := _make_started_adapter()
	var adapter := setup["adapter"] as Node
	assert_true(bool(setup["started"]))

	var request: Dictionary = RegistryScript.request_session({"session_key": "mediapipe_python"})
	assert_true(bool(request.get("ok", false)), "Started adapter should publish a shared mediapipe session")
	var session: Dictionary = request.get("session", {}) if request.get("session", {}) is Dictionary else {}
	var metadata: Dictionary = session.get("metadata", {}) if session.get("metadata", {}) is Dictionary else {}
	assert_same(session.get("provider", null), adapter)
	assert_eq(String(session.get("provider_id", "")), "mediapipe_python")
	assert_eq(String(metadata.get("shared_reuse_scope", "")), "same_runtime_only")

	var acquire: Dictionary = RegistryScript.acquire_session("camera_gesture:testbed", {"session_key": "mediapipe_python"})
	assert_true(bool(acquire.get("ok", false)), "Published adapter session should be borrowable by downstream consumers")
	var acquired_session: Dictionary = acquire.get("session", {}) if acquire.get("session", {}) is Dictionary else {}
	assert_eq(int(acquired_session.get("borrower_count", -1)), 1)

func test_input_provider_adapter_unpublishes_owned_session_on_stop() -> void:
	var setup := _make_started_adapter()
	var adapter := setup["adapter"] as Node
	var backend := setup["backend"] as FakeProviderBackend

	adapter.stop()

	assert_false(bool(RegistryScript.request_session({"session_key": "mediapipe_python"}).get("ok", false)), "Stopping the owner adapter should unpublish its shared session")
	assert_eq(backend.stop_call_count, 1)

func test_input_provider_adapter_keeps_existing_owner_session_when_publication_collides() -> void:
	var first_setup := _make_started_adapter()
	var first_adapter := first_setup["adapter"] as Node
	var second_setup := _make_started_adapter()
	var second_adapter = second_setup["adapter"]
	var second_backend := second_setup["backend"] as FakeProviderBackend

	assert_true(bool(second_setup["started"]), "Publication collisions should not fail local provider startup")
	assert_eq(second_backend.start_call_count, 1)
	assert_eq(String(second_adapter._published_session_key), "")

	var request: Dictionary = RegistryScript.request_session({"session_key": "mediapipe_python"})
	assert_true(bool(request.get("ok", false)))
	var session: Dictionary = request.get("session", {}) if request.get("session", {}) is Dictionary else {}
	assert_same(session.get("provider", null), first_adapter, "The original owner should keep the canonical shared session")

func _make_started_adapter() -> Dictionary:
	var adapter = add_child_autoqfree(InputProviderAdapterScript.new())
	var backend = FakeProviderBackend.new()
	backend.name = "FakeProviderBackend"
	adapter._provider = backend
	adapter.add_child(backend)
	return {
		"adapter": adapter,
		"backend": backend,
		"started": adapter.start("{}"),
	}
