extends "res://addons/aerobeat-vendor-godot-unit-test/test.gd"

const LandmarkSmoother = preload("res://addons/aerobeat-input-camera-tracking/src/detectors/landmark_smoother.gd")

func test_lite_raw_keeps_existing_moving_average_behavior() -> void:
	var smoother := LandmarkSmoother.new(4, LandmarkSmoother.STYLE_LITE_RAW)
	smoother.push_landmarks([{"id": 1, "x": 0.0, "y": 0.0, "z": 0.0, "v": 1.0}])
	smoother.push_landmarks([{"id": 1, "x": 0.6, "y": 0.0, "z": 0.0, "v": 1.0}])
	var smoothed: Dictionary = smoother.push_landmarks([{"id": 1, "x": 0.3, "y": 0.0, "z": 0.0, "v": 1.0}])
	assert_true(is_equal_approx(float(smoothed.get(1, {}).get("x", -1.0)), 0.3))

func test_exponential_moving_average_reduces_jitter_without_drifting_to_full_average_lag() -> void:
	var smoother := LandmarkSmoother.new(1, LandmarkSmoother.STYLE_EXPONENTIAL_MOVING_AVERAGE)
	smoother.push_landmarks([{"id": 1, "x": 0.50, "y": 0.60, "z": 0.0, "v": 0.9}])
	smoother.push_landmarks([{"id": 1, "x": 0.60, "y": 0.70, "z": 0.0, "v": 0.9}])
	var smoothed: Dictionary = smoother.push_landmarks([{"id": 1, "x": 0.50, "y": 0.60, "z": 0.0, "v": 0.9}])
	var landmark: Dictionary = smoothed.get(1, {})
	assert_true(is_equal_approx(float(landmark.get("x", -1.0)), 0.52475))
	assert_true(is_equal_approx(float(landmark.get("y", -1.0)), 0.62475))
	assert_true(float(landmark.get("x", -1.0)) > 0.50)
	assert_true(float(landmark.get("x", -1.0)) < 0.5334)
	assert_eq(int(landmark.get("sample_count", 0)), 2)

func test_median_of_3_rejects_single_frame_spike_without_adding_average_lag() -> void:
	var smoother := LandmarkSmoother.new(9, LandmarkSmoother.STYLE_MEDIAN_OF_3)
	smoother.push_landmarks([{"id": 1, "x": 0.50, "y": 0.60, "z": 0.10, "v": 0.9}])
	var second: Dictionary = smoother.push_landmarks([{"id": 1, "x": 0.90, "y": 0.10, "z": 0.30, "v": 0.2}])
	assert_true(is_equal_approx(float(second.get(1, {}).get("x", -1.0)), 0.90))
	assert_eq(int(second.get(1, {}).get("sample_count", 0)), 2)

	var third: Dictionary = smoother.push_landmarks([{"id": 1, "x": 0.52, "y": 0.61, "z": 0.11, "v": 0.85}])
	var landmark: Dictionary = third.get(1, {})
	assert_true(is_equal_approx(float(landmark.get("x", -1.0)), 0.52))
	assert_true(is_equal_approx(float(landmark.get("y", -1.0)), 0.60))
	assert_true(is_equal_approx(float(landmark.get("z", -1.0)), 0.11))
	assert_true(is_equal_approx(float(landmark.get("v", -1.0)), 0.85))
	assert_eq(int(landmark.get("sample_count", 0)), 3)
