extends "res://addons/gut/test.gd"

const TrackingFrameAdapter = preload("res://addons/aerobeat-input-camera-tracking/src/tracking_frame_adapter.gd")

func test_tracking_frame_adapter_normalizes_visibility_keys_without_reflipping_coordinates() -> void:
	var landmarks := TrackingFrameAdapter.landmarks_from_tracking_frame({
		"tracking_state": "tracked",
		"preview_transform": {
			"flip_horizontal": true,
			"space": "gameplay_normalized",
		},
		"landmarks": [
			{"id": 15, "x": 0.25, "y": 0.75, "z": -0.10, "visibility": 0.82},
			{"id": 16, "x": 0.70, "y": 0.35, "z": 0.05, "v": 0.91},
		],
	})
	assert_eq(landmarks.size(), 2)
	assert_eq(int(landmarks[0].get("id", -1)), 15)
	assert_true(is_equal_approx(float(landmarks[0].get("x", 0.0)), 0.25))
	assert_true(is_equal_approx(float(landmarks[0].get("y", 0.0)), 0.75))
	assert_true(is_equal_approx(float(landmarks[0].get("v", 0.0)), 0.82))
	assert_true(is_equal_approx(float(landmarks[1].get("v", 0.0)), 0.91))

func test_tracking_frame_adapter_treats_reacquiring_frames_as_active() -> void:
	assert_true(TrackingFrameAdapter.tracking_state_is_active({"tracking_state": "tracked"}))
	assert_true(TrackingFrameAdapter.tracking_state_is_active({"tracking_state": "reacquiring"}))
	assert_false(TrackingFrameAdapter.tracking_state_is_active({"tracking_state": "lost"}))
	assert_false(TrackingFrameAdapter.tracking_state_is_active({"tracking_state": "idle"}))
