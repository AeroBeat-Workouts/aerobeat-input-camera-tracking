extends "res://addons/aerobeat-vendor-godot-unit-test/test.gd"

const ProvingHarnessScript = preload("res://scripts/proving_harness.gd")

class CameraSelectionPersistenceHarness:
	extends ProvingHarnessScript

	var cache_path := "user://testbed/test_proving_harness_camera_selection_persistence.cfg"
	var stub_devices: Array = []
	var apply_live_camera_source_result := true

	func _camera_selection_cache_path() -> String:
		return cache_path

	func _load_available_camera_devices() -> Array:
		return stub_devices.duplicate(true)

	func _apply_live_camera_source(device_id: String) -> bool:
		_selected_live_camera_device_id = _normalize_live_camera_device_id(device_id)
		return apply_live_camera_source_result

	func _update_status(_text: String, _color: Color) -> void:
		pass

var harness: CameraSelectionPersistenceHarness = null

func before_each() -> void:
	harness = add_child_autoqfree(CameraSelectionPersistenceHarness.new())
	var camera_source_controls := Control.new()
	var camera_source_picker := OptionButton.new()
	harness.add_child(camera_source_controls)
	harness.add_child(camera_source_picker)
	harness.set("camera_source_controls", camera_source_controls)
	harness.set("camera_source_picker", camera_source_picker)
	_clear_cache_file(harness.cache_path)

func after_each() -> void:
	if harness != null:
		_clear_cache_file(harness.cache_path)
		harness = null

func test_refresh_camera_source_controls_restores_cached_device_when_available() -> void:
	harness.stub_devices = [
		{"id": "/dev/video0", "label": "Built-in"},
		{"id": "/dev/video4", "label": "USB Cam"},
	]
	_write_cached_device(harness.cache_path, "/dev/video4")

	harness._refresh_camera_source_controls()

	assert_eq(harness.get("_selected_live_camera_device_id"), "/dev/video4")

func test_refresh_camera_source_controls_ignores_cached_device_when_missing() -> void:
	harness.stub_devices = [
		{"id": "/dev/video0", "label": "Built-in"},
		{"id": "/dev/video4", "label": "USB Cam"},
	]
	_write_cached_device(harness.cache_path, "/dev/video7")

	harness._refresh_camera_source_controls()

	assert_eq(harness.get("_selected_live_camera_device_id"), "/dev/video0")

func test_refresh_camera_source_controls_preserves_cached_device_during_placeholder_prestart_inventory() -> void:
	harness.stub_devices = [
		{"id": "/dev/video0", "label": "Default camera", "placeholder": true},
	]
	_write_cached_device(harness.cache_path, "/dev/video4")

	harness._refresh_camera_source_controls()

	assert_eq(harness.get("_selected_live_camera_device_id"), "/dev/video4")
	var picker := harness.get("camera_source_picker") as OptionButton
	assert_not_null(picker)
	assert_eq(picker.item_count, 2)
	assert_eq(String(picker.get_item_metadata(1)), "/dev/video4")
	assert_string_contains(picker.get_item_text(1), "waiting for inventory")
	assert_eq(picker.selected, 1)

func test_switch_live_camera_source_persists_successful_selection() -> void:
	harness.stub_devices = [
		{"id": "/dev/video0", "label": "Built-in"},
		{"id": "/dev/video4", "label": "USB Cam"},
	]
	harness.set("_selected_live_camera_device_id", "/dev/video0")

	await harness._switch_live_camera_source("4")

	assert_eq(harness.get("_selected_live_camera_device_id"), "/dev/video4")
	assert_eq(_read_cached_device(harness.cache_path), "/dev/video4")

func _write_cached_device(cache_path: String, device_id: String) -> void:
	var cache_dir := ProjectSettings.globalize_path(cache_path.get_base_dir())
	DirAccess.make_dir_recursive_absolute(cache_dir)
	var cache := ConfigFile.new()
	cache.set_value(ProvingHarnessScript.TESTBED_CAMERA_CACHE_SECTION, ProvingHarnessScript.TESTBED_CAMERA_CACHE_KEY_LIVE_DEVICE_ID, device_id)
	assert_eq(cache.save(cache_path), OK)

func _read_cached_device(cache_path: String) -> String:
	var cache := ConfigFile.new()
	assert_eq(cache.load(cache_path), OK)
	return String(cache.get_value(ProvingHarnessScript.TESTBED_CAMERA_CACHE_SECTION, ProvingHarnessScript.TESTBED_CAMERA_CACHE_KEY_LIVE_DEVICE_ID, "")).strip_edges()

func _clear_cache_file(cache_path: String) -> void:
	var absolute_path := ProjectSettings.globalize_path(cache_path)
	if FileAccess.file_exists(cache_path):
		DirAccess.remove_absolute(absolute_path)
