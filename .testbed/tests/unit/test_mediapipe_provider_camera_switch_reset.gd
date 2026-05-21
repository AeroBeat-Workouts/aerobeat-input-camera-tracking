extends "res://addons/gut/test.gd"

const MediaPipeProvider = preload("res://addons/aerobeat-input-mediapipe-python/src/providers/mediapipe_provider.gd")
const MediaPipeConfig = preload("res://addons/aerobeat-input-mediapipe-python/src/config/mediapipe_config.gd")
const PoseLandmarkIds = preload("res://addons/aerobeat-input-mediapipe-python/src/detectors/pose_landmark_ids.gd")

var provider: MediaPipeProvider = null

func before_each() -> void:
	provider = add_child_autoqfree(MediaPipeProvider.new())
	provider.config = MediaPipeConfig.new()
	provider.config.flip_horizontal = false
	provider.config.smoothing_factor = 0.0

func test_switching_selected_camera_resets_detector_and_cached_pose_state() -> void:
	for idx in range(5):
		provider._process_primary_landmarks(_make_pose_frame(), false, true, 1000 + idx * 16)
	assert_true(bool(provider.get_detector_state().get("baseline", {}).get("is_calibrated", false)))
	assert_true(provider._all_poses.size() > 0)
	assert_true(provider._last_update_time_ms > 0)
	provider._was_tracking = true

	assert_true(provider.set_selected_camera_device_id("/dev/video9"))

	assert_false(provider._was_tracking, "Camera switches should clear stale tracking truth until new landmarks arrive")
	assert_eq(provider._all_poses.size(), 0, "Camera switches should drop cached pose payloads from the previous device")
	assert_eq(provider._last_update_time_ms, 0, "Camera switches should reset the detector timestamp baseline")
	assert_false(bool(provider.get_detector_state().get("baseline", {}).get("is_calibrated", true)), "Camera switches should force detector recalibration for the new device")

func _make_pose_frame(overrides: Dictionary = {}, center_x: float = 0.50, height_scale: float = 1.0, visibility: float = 0.99) -> Array:
	var shoulder_y := 0.30
	var hip_y := shoulder_y + 0.30 * height_scale
	var knee_y := hip_y + 0.18 * height_scale
	var ankle_y := hip_y + 0.36 * height_scale
	var nose_y := shoulder_y - 0.20 * height_scale
	var frame := [
		{"id": provider.LANDMARK_NOSE, "x": center_x, "y": nose_y, "z": 0.0, "v": visibility},
		{"id": 11, "x": center_x - 0.10, "y": shoulder_y, "z": 0.0, "v": visibility},
		{"id": 12, "x": center_x + 0.10, "y": shoulder_y, "z": 0.0, "v": visibility},
		{"id": 13, "x": center_x - 0.16, "y": shoulder_y + 0.04, "z": 0.0, "v": visibility},
		{"id": 14, "x": center_x + 0.16, "y": shoulder_y + 0.04, "z": 0.0, "v": visibility},
		{"id": provider.LANDMARK_LEFT_WRIST, "x": center_x - 0.22, "y": shoulder_y + 0.10, "z": 0.0, "v": visibility},
		{"id": provider.LANDMARK_RIGHT_WRIST, "x": center_x + 0.22, "y": shoulder_y + 0.10, "z": 0.0, "v": visibility},
		{"id": 23, "x": center_x - 0.08, "y": hip_y, "z": 0.0, "v": visibility},
		{"id": 24, "x": center_x + 0.08, "y": hip_y, "z": 0.0, "v": visibility},
		{"id": 25, "x": center_x - 0.06, "y": knee_y, "z": 0.0, "v": visibility},
		{"id": 26, "x": center_x + 0.06, "y": knee_y, "z": 0.0, "v": visibility},
		{"id": provider.LANDMARK_LEFT_ANKLE, "x": center_x - 0.04, "y": ankle_y, "z": 0.0, "v": visibility},
		{"id": provider.LANDMARK_RIGHT_ANKLE, "x": center_x + 0.04, "y": ankle_y, "z": 0.0, "v": visibility},
	]
	return _with_overrides(frame, overrides)

func _with_overrides(frame: Array, overrides: Dictionary) -> Array:
	if overrides.is_empty():
		return frame
	var updated: Array = []
	for landmark_variant: Variant in frame:
		var landmark: Dictionary = (landmark_variant as Dictionary).duplicate(true)
		var landmark_id: int = int(landmark.get("id", -1))
		if overrides.has(landmark_id):
			var override_variant: Variant = overrides[landmark_id]
			if override_variant is Dictionary:
				for key_variant: Variant in override_variant.keys():
					landmark[key_variant] = override_variant[key_variant]
		updated.append(landmark)
	return updated
