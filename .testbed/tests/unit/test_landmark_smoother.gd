extends "res://addons/aerobeat-vendor-godot-unit-test/test.gd"

const LandmarkSmoother = preload("res://addons/aerobeat-input-camera-tracking/src/detectors/landmark_smoother.gd")

func test_lite_raw_keeps_existing_moving_average_behavior() -> void:
	var smoother := LandmarkSmoother.new(4, LandmarkSmoother.STYLE_LITE_RAW)
	smoother.push_landmarks([{"id": 1, "x": 0.0, "y": 0.0, "z": 0.0, "v": 1.0}])
	smoother.push_landmarks([{"id": 1, "x": 0.6, "y": 0.0, "z": 0.0, "v": 1.0}])
	var smoothed: Dictionary = smoother.push_landmarks([{"id": 1, "x": 0.3, "y": 0.0, "z": 0.0, "v": 1.0}])
	assert_true(is_equal_approx(float(smoothed.get(1, {}).get("x", -1.0)), 0.3))

func test_lite_filtered_keeps_existing_moving_average_behavior() -> void:
	var smoother := LandmarkSmoother.new(4, LandmarkSmoother.STYLE_LITE_FILTERED)
	smoother.push_landmarks([{"id": 1, "x": 0.0, "y": 0.0, "z": 0.0, "v": 1.0}])
	smoother.push_landmarks([{"id": 1, "x": 0.6, "y": 0.0, "z": 0.0, "v": 1.0}])
	var smoothed: Dictionary = smoother.push_landmarks([{"id": 1, "x": 0.3, "y": 0.0, "z": 0.0, "v": 1.0}])
	assert_true(is_equal_approx(float(smoothed.get(1, {}).get("x", -1.0)), 0.3))

func test_unknown_smoothing_style_falls_back_to_lite_raw_behavior() -> void:
	var smoother := LandmarkSmoother.new(4, "median_of_3")
	smoother.push_landmarks([{"id": 1, "x": 0.0, "y": 0.0, "z": 0.0, "v": 1.0}])
	smoother.push_landmarks([{"id": 1, "x": 0.6, "y": 0.0, "z": 0.0, "v": 1.0}])
	var smoothed: Dictionary = smoother.push_landmarks([{"id": 1, "x": 0.3, "y": 0.0, "z": 0.0, "v": 1.0}])
	assert_true(is_equal_approx(float(smoothed.get(1, {}).get("x", -1.0)), 0.3))
