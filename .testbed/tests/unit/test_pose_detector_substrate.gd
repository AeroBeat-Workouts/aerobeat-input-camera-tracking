extends "res://addons/aerobeat-vendor-godot-unit-test/test.gd"

const PoseDetectorSubstrate = preload("res://addons/aerobeat-input-camera-tracking/src/detectors/pose_detector_substrate.gd")
const CameraTrackingConfigScript = preload("res://addons/aerobeat-input-camera-tracking/src/config/camera_tracking_config.gd")
const PoseLandmarkIds = preload("res://addons/aerobeat-input-camera-tracking/src/detectors/pose_landmark_ids.gd")

var substrate: PoseDetectorSubstrate = null
var config = null

func before_each() -> void:
	config = CameraTrackingConfigScript.new()
	config.flip_horizontal = false
	config.min_visibility = 0.5
	config.tracking_confidence = 0.5
	config.smoothing_factor = 0.0
	substrate = PoseDetectorSubstrate.new().configure(config)

func test_builds_session_baseline_after_stable_frames() -> void:
	_calibrate_stance()
	var baseline: Dictionary = substrate.get_latest_state().get("baseline", {})
	assert_true(bool(baseline.get("is_calibrated", false)))
	assert_true(is_equal_approx(float(baseline.get("shoulder_width", 0.0)), 0.20))
	assert_true(is_equal_approx(float(baseline.get("torso_height", 0.0)), 0.30))

func test_profile_pose_smoothing_style_can_select_lite_filtered() -> void:
	config.smoothing_factor = 0.75
	config.tracker_profile_document = {
		"tracking": {
			"pose": {
				"smoothing_style": "lite_filtered",
			}
		}
	}
	substrate = PoseDetectorSubstrate.new().configure(config)

	substrate.process_landmarks(_make_pose_frame({
		PoseLandmarkIds.LEFT_WRIST: {"x": 0.0, "y": 0.60},
	}), 1000)
	substrate.process_landmarks(_make_pose_frame({
		PoseLandmarkIds.LEFT_WRIST: {"x": 0.6, "y": 0.60},
	}), 1100)
	var state := substrate.process_landmarks(_make_pose_frame({
		PoseLandmarkIds.LEFT_WRIST: {"x": 0.3, "y": 0.60},
	}), 1200)
	var smoothed_wrist: Dictionary = state.get("landmarks_by_id", {}).get(PoseLandmarkIds.LEFT_WRIST, {})
	assert_true(is_equal_approx(float(smoothed_wrist.get("x", -1.0)), 0.3))

func test_profile_pose_smoothing_style_falls_back_to_lite_raw_for_removed_values() -> void:
	config.smoothing_factor = 0.75
	config.tracker_profile_document = {
		"tracking": {
			"pose": {
				"smoothing_style": "median_of_3",
			}
		}
	}
	substrate = PoseDetectorSubstrate.new().configure(config)

	substrate.process_landmarks(_make_pose_frame({
		PoseLandmarkIds.LEFT_WRIST: {"x": 0.0, "y": 0.60},
	}), 1000)
	substrate.process_landmarks(_make_pose_frame({
		PoseLandmarkIds.LEFT_WRIST: {"x": 0.6, "y": 0.60},
	}), 1100)
	var state := substrate.process_landmarks(_make_pose_frame({
		PoseLandmarkIds.LEFT_WRIST: {"x": 0.3, "y": 0.60},
	}), 1200)
	var smoothed_wrist: Dictionary = state.get("landmarks_by_id", {}).get(PoseLandmarkIds.LEFT_WRIST, {})
	assert_true(is_equal_approx(float(smoothed_wrist.get("x", -1.0)), 0.3))

func test_reports_hand_velocity_and_direction_from_landmark_deltas() -> void:
	substrate.process_landmarks(_make_pose_frame(), 1000)
	var moving := _make_pose_frame({
		PoseLandmarkIds.LEFT_ELBOW: {"x": 0.36, "y": 0.66},
		PoseLandmarkIds.LEFT_WRIST: {"x": 0.36, "y": 0.60},
	})
	var state := substrate.process_landmarks(moving, 1100)
	var velocities: Dictionary = state.get("metrics", {}).get("velocities", {})
	var directions: Dictionary = state.get("metrics", {}).get("directions", {})
	var left_hand_velocity: Vector3 = velocities.get("left_hand", Vector3.ZERO)
	assert_true(left_hand_velocity.x > 0.20)
	assert_true(left_hand_velocity.y > -0.05 and left_hand_velocity.y < 0.80)
	var left_direction: Vector2 = directions.get("left_hand", Vector2.ZERO)
	assert_true(left_direction.x > 0.55)

func test_reports_arm_extension_centerline_offset_and_height_state() -> void:
	_calibrate_stance()
	var lowered := _make_pose_frame({}, 0.62, 0.50)
	lowered = _with_overrides(lowered, {
		PoseLandmarkIds.LEFT_ELBOW: {"x": 0.46, "y": 0.695},
		PoseLandmarkIds.RIGHT_ELBOW: {"x": 0.78, "y": 0.695},
		PoseLandmarkIds.LEFT_WRIST: {"x": 0.36, "y": 0.70},
		PoseLandmarkIds.RIGHT_WRIST: {"x": 0.88, "y": 0.70},
	})
	var state := substrate.process_landmarks(lowered, 1200)
	var measurements: Dictionary = state.get("metrics", {}).get("measurements", {})
	assert_true(float(measurements.get("left_arm_extension", 0.0)) > 0.95)
	assert_true(float(measurements.get("right_arm_extension", 0.0)) > 0.95)
	assert_true(float(measurements.get("lateral_offset", 0.0)) > 0.25)
	assert_eq(String(measurements.get("height_state", "unknown")), "lowered")
	assert_true(float(measurements.get("height_ratio", 1.0)) < 0.80)

func test_degrades_then_reacquires_tracking_when_confidence_drops() -> void:
	substrate.process_landmarks(_make_pose_frame(), 1000)
	var degraded := substrate.process_landmarks(_make_pose_frame({}, 0.50, 1.0, 0.2, 0.2), 1016)
	assert_eq(String(degraded["tracking_state"]), "degraded")
	var lost := substrate.process_landmarks(_make_pose_frame({}, 0.50, 1.0, 0.2, 0.2), 1032)
	lost = substrate.process_landmarks(_make_pose_frame({}, 0.50, 1.0, 0.2, 0.2), 1048)
	assert_eq(String(lost["tracking_state"]), "lost")
	var reacquiring := substrate.process_landmarks(_make_pose_frame(), 1064)
	assert_eq(String(reacquiring["tracking_state"]), "reacquiring")
	var tracking := substrate.process_landmarks(_make_pose_frame(), 1080)
	assert_eq(String(tracking["tracking_state"]), "tracking")

func test_detects_straight_punch_from_bbox_growth_and_emits_state_changes() -> void:
	_calibrate_stance()
	var tracking_frame := _make_tracking_frame(_tracked_hand_payload_physical("left", 0.020, "tracked", true, 0, 1, 0.0, null, "", 0), _tracked_hand_payload_physical("right", 0.020))
	var state := substrate.process_landmarks(_make_pose_frame(), 1100, tracking_frame)
	assert_eq(String(state.get("gesture_debug", {}).get("straight_punch", {}).get("left", {}).get("state", "")), "tracking_lost")

	tracking_frame = _make_tracking_frame(_tracked_hand_payload_physical("left", 0.021, "tracked", true, 0, 1, 0.0, null, "", 80), _tracked_hand_payload_physical("right", 0.020))
	state = substrate.process_landmarks(_make_pose_frame({
		PoseLandmarkIds.LEFT_WRIST: {"z": -0.04},
	}), 1180, tracking_frame)
	assert_eq(String(state.get("gesture_debug", {}).get("straight_punch", {}).get("left", {}).get("state", "")), "ready")
	assert_eq(_straight_punch_state_names(state.get("events", []), "left"), ["ready"])

	tracking_frame = _make_tracking_frame(_tracked_hand_payload_physical("left", 0.023), _tracked_hand_payload_physical("right", 0.020))
	state = substrate.process_landmarks(_make_pose_frame({
		PoseLandmarkIds.LEFT_WRIST: {"z": -0.08},
	}), 1260, tracking_frame)
	tracking_frame = _make_tracking_frame(_tracked_hand_payload_physical("left", 0.0225), _tracked_hand_payload_physical("right", 0.020))
	state = substrate.process_landmarks(_make_pose_frame({
		PoseLandmarkIds.LEFT_WRIST: {"z": -0.12},
	}), 1340, tracking_frame)
	tracking_frame = _make_tracking_frame(_tracked_hand_payload_physical("left", 0.0275), _tracked_hand_payload_physical("right", 0.020))
	state = substrate.process_landmarks(_make_pose_frame({
		PoseLandmarkIds.LEFT_WRIST: {"z": -0.20},
	}), 1420, tracking_frame)
	assert_true(_event_names(state.get("events", [])).has("punch_left"))
	assert_eq(_straight_punch_state_names(state.get("events", []), "left"), ["triggered"])
	var left_debug: Dictionary = state.get("gesture_debug", {}).get("straight_punch", {}).get("left", {})
	assert_eq(String(left_debug.get("state", "")), "triggered")
	assert_true(is_equal_approx(float(left_debug.get("trigger_bbox_area", 0.0)), 0.0275))
	assert_eq(int(left_debug.get("positive_growth_samples", 0)), 2)

	var lost_frame := _make_tracking_frame(_tracked_hand_payload_physical("left", 0.0275, "reacquiring", false, 0, 1, 0.0, true, "fresh_inference", 0), _tracked_hand_payload_physical("right", 0.020))
	state = substrate.process_landmarks(_make_pose_frame({
		PoseLandmarkIds.LEFT_WRIST: {"z": -0.20},
	}), 1500, lost_frame)
	left_debug = state.get("gesture_debug", {}).get("straight_punch", {}).get("left", {})
	assert_eq(_straight_punch_state_names(state.get("events", []), "left"), [])
	assert_eq(String(left_debug.get("state", "")), "triggered")
	assert_eq(String(left_debug.get("tracking_state", "")), "reacquiring")
	assert_false(bool(left_debug.get("tracking_valid", true)))
	assert_eq(int(left_debug.get("grace_ms_remaining", -1)), 160)
	assert_true(is_equal_approx(float(left_debug.get("trigger_bbox_area", 0.0)), 0.0275))

func test_straight_punch_debug_uses_live_metrics_hand_truth() -> void:
	_calibrate_stance()
	var tracking_frame := _make_tracking_frame(_tracked_hand_payload("left", 0.024), _tracked_hand_payload("right", 0.020))
	var state := substrate.process_landmarks(_make_pose_frame(), 1100, tracking_frame)
	var left_debug: Dictionary = state.get("gesture_debug", {}).get("straight_punch", {}).get("left", {})
	assert_true(bool(state.get("metrics", {}).get("hands", {}).get("left", {}).get("tracking_valid", false)))
	assert_true(bool(left_debug.get("tracking_valid", false)))
	assert_eq(String(left_debug.get("tracking_state", "")), "tracked")

func test_straight_punch_debug_uses_min_velocity_key() -> void:
	config.gesture_profile_document = {
		"straight_punch": {
			"thresholds": {
				"min_velocity": 0.33,
			}
		}
	}
	substrate = PoseDetectorSubstrate.new().configure(config)
	_calibrate_stance()
	var state := substrate.process_landmarks(_make_pose_frame(), 1100, _make_tracking_frame(_tracked_hand_payload("left", 0.020), _tracked_hand_payload("right", 0.020)))
	var left_debug: Dictionary = state.get("gesture_debug", {}).get("straight_punch", {}).get("left", {})
	assert_true(is_equal_approx(float(left_debug.get("min_velocity", 0.0)), 0.33))
	assert_false(left_debug.has("min_punch_velocity"))
	assert_false(left_debug.has("min_wrist_velocity"))

func test_straight_punch_uses_window_growth_with_subthreshold_step_deltas() -> void:
	_calibrate_stance()
	var state := substrate.process_landmarks(_make_pose_frame(), 1100, _make_tracking_frame(_tracked_hand_payload_physical("left", 0.020), _tracked_hand_payload_physical("right", 0.020)))
	state = substrate.process_landmarks(_make_pose_frame({PoseLandmarkIds.LEFT_WRIST: {"z": -0.02}}), 1180, _make_tracking_frame(_tracked_hand_payload_physical("left", 0.021), _tracked_hand_payload_physical("right", 0.020)))
	assert_eq(String(state.get("gesture_debug", {}).get("straight_punch", {}).get("left", {}).get("state", "")), "ready")

	state = substrate.process_landmarks(_make_pose_frame({PoseLandmarkIds.LEFT_WRIST: {"z": -0.05}}), 1260, _make_tracking_frame(_tracked_hand_payload_physical("left", 0.023), _tracked_hand_payload_physical("right", 0.020)))
	state = substrate.process_landmarks(_make_pose_frame({PoseLandmarkIds.LEFT_WRIST: {"z": -0.07}}), 1340, _make_tracking_frame(_tracked_hand_payload_physical("left", 0.0228), _tracked_hand_payload_physical("right", 0.020)))
	state = substrate.process_landmarks(_make_pose_frame({PoseLandmarkIds.LEFT_WRIST: {"z": -0.20}}), 1420, _make_tracking_frame(_tracked_hand_payload_physical("left", 0.0272), _tracked_hand_payload_physical("right", 0.020)))
	assert_true(_event_names(state.get("events", [])).has("punch_left"))
	var left_debug: Dictionary = state.get("gesture_debug", {}).get("straight_punch", {}).get("left", {})
	assert_eq(String(left_debug.get("state", "")), "triggered")
	assert_true(is_equal_approx(float(left_debug.get("bbox_area_growth", 0.0)), 0.0062))
	assert_eq(int(left_debug.get("positive_growth_samples", 0)), 2)
	assert_eq(int(left_debug.get("min_positive_growth_samples", 0)), 2)
	assert_true(is_equal_approx(float(left_debug.get("min_bbox_area_growth", 0.0)), 0.006))

func test_straight_punch_grace_hand_samples_remain_trigger_eligible() -> void:
	_calibrate_stance()
	var tracking_frame := _make_tracking_frame(_tracked_hand_payload_physical("left", 0.020, "tracked", true, 0, 1, 1.10), _tracked_hand_payload_physical("right", 0.020))
	substrate.process_landmarks(_make_pose_frame(), 1100, tracking_frame)
	tracking_frame = _make_tracking_frame(_tracked_hand_payload_physical("left", 0.021, "tracked", true, 0, 2, 1.18), _tracked_hand_payload_physical("right", 0.020))
	substrate.process_landmarks(_make_pose_frame({PoseLandmarkIds.LEFT_WRIST: {"z": -0.04}}), 1180, tracking_frame)
	tracking_frame = _make_tracking_frame(_tracked_hand_payload_physical("left", 0.023, "tracked", true, 0, 3, 1.26), _tracked_hand_payload_physical("right", 0.020))
	substrate.process_landmarks(_make_pose_frame({PoseLandmarkIds.LEFT_WRIST: {"z": -0.08}}), 1260, tracking_frame)
	tracking_frame = _make_tracking_frame(_tracked_hand_payload_physical("left", 0.0225, "tracked", true, 0, 4, 1.34), _tracked_hand_payload_physical("right", 0.020))
	var state := substrate.process_landmarks(_make_pose_frame({PoseLandmarkIds.LEFT_WRIST: {"z": -0.12}}), 1340, tracking_frame)
	assert_eq(String(state.get("gesture_debug", {}).get("straight_punch", {}).get("left", {}).get("state", "")), "ready")

	var grace_frame := _make_tracking_frame(_tracked_hand_payload_physical("left", 0.0275, "grace", true, 1, 5, 1.42), _tracked_hand_payload_physical("right", 0.020))
	state = substrate.process_landmarks(_make_pose_frame({PoseLandmarkIds.LEFT_WRIST: {"z": -0.20}}), 1420, grace_frame)
	assert_true(_event_names(state.get("events", [])).has("punch_left"))
	var left_debug: Dictionary = state.get("gesture_debug", {}).get("straight_punch", {}).get("left", {})
	assert_eq(String(left_debug.get("tracking_state", "")), "grace")
	assert_true(bool(left_debug.get("fresh_sample", false)))
	assert_eq(_straight_punch_state_names(state.get("events", []), "left"), ["triggered"])

func test_straight_punch_carried_forward_hand_samples_are_not_fresh() -> void:
	_calibrate_stance()
	var tracking_frame := _make_tracking_frame(_tracked_hand_payload("left", 0.020, "tracked", true, 0, 1, 1.10, true, "fresh_inference"), _tracked_hand_payload("right", 0.020))
	substrate.process_landmarks(_make_pose_frame(), 1100, tracking_frame)
	tracking_frame = _make_tracking_frame(_tracked_hand_payload("left", 0.021, "tracked", true, 0, 2, 1.18, true, "fresh_inference"), _tracked_hand_payload("right", 0.020))
	substrate.process_landmarks(_make_pose_frame({PoseLandmarkIds.LEFT_WRIST: {"z": -0.04}}), 1180, tracking_frame)
	tracking_frame = _make_tracking_frame(_tracked_hand_payload("left", 0.023, "tracked", true, 0, 3, 1.26, true, "fresh_inference"), _tracked_hand_payload("right", 0.020))
	substrate.process_landmarks(_make_pose_frame({PoseLandmarkIds.LEFT_WRIST: {"z": -0.08}}), 1260, tracking_frame)
	tracking_frame = _make_tracking_frame(_tracked_hand_payload("left", 0.0225, "tracked", true, 0, 4, 1.34, true, "fresh_inference"), _tracked_hand_payload("right", 0.020))
	var state := substrate.process_landmarks(_make_pose_frame({PoseLandmarkIds.LEFT_WRIST: {"z": -0.12}}), 1340, tracking_frame)
	assert_eq(String(state.get("gesture_debug", {}).get("straight_punch", {}).get("left", {}).get("state", "")), "ready")

	var carried_frame := _make_tracking_frame(_tracked_hand_payload("left", 0.0275, "tracked", true, 0, 5, 1.42, false, "carried_forward"), _tracked_hand_payload("right", 0.020))
	state = substrate.process_landmarks(_make_pose_frame({
		PoseLandmarkIds.LEFT_ELBOW: {"z": -0.20},
		PoseLandmarkIds.LEFT_WRIST: {"z": -0.13},
	}), 1420, carried_frame)
	var left_debug: Dictionary = state.get("gesture_debug", {}).get("straight_punch", {}).get("left", {})
	assert_eq(String(left_debug.get("sample_source", "")), "carried_forward")
	assert_false(bool(left_debug.get("fresh_sample", true)))
	assert_eq(String(left_debug.get("velocity_signal_source", "")), "elbow_plus_wrist")
	assert_true(float(state.get("metrics", {}).get("measurements", {}).get("left_wrist_velocity_magnitude", 0.0)) < float(left_debug.get("min_velocity", 0.0)))
	assert_true(float(left_debug.get("wrist_velocity", 0.0)) > float(left_debug.get("min_velocity", 0.0)))
	assert_false(_event_names(state.get("events", [])).has("punch_left"))

func test_straight_punch_ignores_stale_hand_samples_for_trigger_evaluation() -> void:
	_calibrate_stance()
	var tracking_frame := _make_tracking_frame(_tracked_hand_payload_physical("left", 0.020, "tracked", true, 0, 1, 1.10), _tracked_hand_payload_physical("right", 0.020, "tracked", true, 0, 1, 1.10))
	substrate.process_landmarks(_make_pose_frame(), 1100, tracking_frame)
	tracking_frame = _make_tracking_frame(_tracked_hand_payload_physical("left", 0.021, "tracked", true, 0, 2, 1.18), _tracked_hand_payload_physical("right", 0.020, "tracked", true, 0, 2, 1.18))
	substrate.process_landmarks(_make_pose_frame({PoseLandmarkIds.LEFT_WRIST: {"z": -0.04}}), 1180, tracking_frame)
	tracking_frame = _make_tracking_frame(_tracked_hand_payload_physical("left", 0.0220, "tracked", true, 0, 3, 1.26), _tracked_hand_payload_physical("right", 0.020, "tracked", true, 0, 3, 1.26))
	substrate.process_landmarks(_make_pose_frame({PoseLandmarkIds.LEFT_WRIST: {"z": -0.08}}), 1260, tracking_frame)
	tracking_frame = _make_tracking_frame(_tracked_hand_payload_physical("left", 0.0224, "tracked", true, 0, 4, 1.34), _tracked_hand_payload_physical("right", 0.020, "tracked", true, 0, 4, 1.34))
	var state := substrate.process_landmarks(_make_pose_frame({PoseLandmarkIds.LEFT_WRIST: {"z": -0.12}}), 1340, tracking_frame)
	assert_eq(String(state.get("gesture_debug", {}).get("straight_punch", {}).get("left", {}).get("state", "")), "ready")

	var stale_frame := _make_tracking_frame(_tracked_hand_payload_physical("left", 0.0275, "stale", true, 1, 5, 1.42), _tracked_hand_payload_physical("right", 0.020, "tracked", true, 0, 5, 1.42))
	state = substrate.process_landmarks(_make_pose_frame({PoseLandmarkIds.LEFT_WRIST: {"z": -0.20}}), 1420, stale_frame)
	assert_false(_event_names(state.get("events", [])).has("punch_left"))
	assert_eq(String(state.get("gesture_debug", {}).get("straight_punch", {}).get("left", {}).get("state", "")), "ready")

	tracking_frame = _make_tracking_frame(_tracked_hand_payload_physical("left", 0.0295, "tracked", true, 0, 6, 1.50), _tracked_hand_payload_physical("right", 0.020, "tracked", true, 0, 6, 1.50))
	state = substrate.process_landmarks(_make_pose_frame({PoseLandmarkIds.LEFT_WRIST: {"z": -0.28}}), 1500, tracking_frame)
	assert_true(_event_names(state.get("events", [])).has("punch_left"))
	assert_eq(_straight_punch_state_names(state.get("events", []), "left"), ["triggered"])

func test_straight_punch_uses_xyz_wrist_velocity_magnitude_for_trigger_gate() -> void:
	_calibrate_stance()
	var state := substrate.process_landmarks(_make_pose_frame(), 1100, _make_tracking_frame(_tracked_hand_payload_physical("left", 0.020), _tracked_hand_payload_physical("right", 0.020)))
	state = substrate.process_landmarks(
		_make_pose_frame({
			PoseLandmarkIds.LEFT_SHOULDER: {"x": 0.34, "y": 0.60, "z": 0.0},
			PoseLandmarkIds.LEFT_WRIST: {"x": 0.32, "y": 0.56, "z": -0.01},
			PoseLandmarkIds.LEFT_ELBOW: {"x": 0.33, "y": 0.62, "z": -0.005},
		}),
		1180,
		_make_tracking_frame(_tracked_hand_payload_physical("left", 0.021), _tracked_hand_payload_physical("right", 0.020))
	)
	assert_eq(String(state.get("gesture_debug", {}).get("straight_punch", {}).get("left", {}).get("state", "")), "ready")

	state = substrate.process_landmarks(
		_make_pose_frame({
			PoseLandmarkIds.LEFT_SHOULDER: {"x": 0.38, "y": 0.50, "z": 0.0},
			PoseLandmarkIds.LEFT_WRIST: {"x": 0.38, "y": 0.48, "z": -0.02},
			PoseLandmarkIds.LEFT_ELBOW: {"x": 0.37, "y": 0.56, "z": -0.010},
		}),
		1260,
		_make_tracking_frame(_tracked_hand_payload_physical("left", 0.023), _tracked_hand_payload_physical("right", 0.020))
	)
	state = substrate.process_landmarks(
		_make_pose_frame({
			PoseLandmarkIds.LEFT_SHOULDER: {"x": 0.41, "y": 0.44, "z": 0.0},
			PoseLandmarkIds.LEFT_WRIST: {"x": 0.42, "y": 0.42, "z": -0.03},
			PoseLandmarkIds.LEFT_ELBOW: {"x": 0.40, "y": 0.50, "z": -0.015},
		}),
		1340,
		_make_tracking_frame(_tracked_hand_payload_physical("left", 0.0275), _tracked_hand_payload_physical("right", 0.020))
	)
	assert_true(_event_names(state.get("events", [])).has("punch_left"))
	assert_eq(_straight_punch_state_names(state.get("events", []), "left"), ["triggered"])
	var left_debug: Dictionary = state.get("gesture_debug", {}).get("straight_punch", {}).get("left", {})
	assert_true(float(left_debug.get("wrist_velocity", 0.0)) > float(left_debug.get("min_velocity", 0.0)))
	assert_true(float(left_debug.get("wrist_forward_velocity", 0.0)) < float(left_debug.get("min_velocity", 0.0)))
	assert_true(float(state.get("metrics", {}).get("measurements", {}).get("left_wrist_velocity_magnitude", 0.0)) > float(state.get("metrics", {}).get("measurements", {}).get("left_forward_velocity", 0.0)))


func test_straight_punch_requires_elbow_shoulder_xy_gate_before_triggering() -> void:
	config.gesture_profile_document = {
		"straight_punch": {
			"thresholds": {
				"min_velocity": 0.18,
				"min_bbox_area_growth": 0.003,
				"max_elbow_shoulder_xy_distance": 0.05,
			},
		},
	}
	substrate = PoseDetectorSubstrate.new().configure(config)
	_calibrate_stance()
	var state := substrate.process_landmarks(_make_pose_frame(), 1100, _make_tracking_frame(_tracked_hand_payload_physical("left", 0.020), _tracked_hand_payload_physical("right", 0.020)))
	state = substrate.process_landmarks(_make_pose_frame({PoseLandmarkIds.LEFT_WRIST: {"z": -0.04}}), 1180, _make_tracking_frame(_tracked_hand_payload_physical("left", 0.021), _tracked_hand_payload_physical("right", 0.020)))
	state = substrate.process_landmarks(_make_pose_frame({PoseLandmarkIds.LEFT_WRIST: {"z": -0.12}}), 1260, _make_tracking_frame(_tracked_hand_payload_physical("left", 0.0240), _tracked_hand_payload_physical("right", 0.020)))
	state = substrate.process_landmarks(_make_pose_frame({PoseLandmarkIds.LEFT_WRIST: {"z": -0.20}}), 1340, _make_tracking_frame(_tracked_hand_payload_physical("left", 0.0272), _tracked_hand_payload_physical("right", 0.020)))
	assert_false(_event_names(state.get("events", [])).has("punch_left"))
	var left_debug: Dictionary = state.get("gesture_debug", {}).get("straight_punch", {}).get("left", {})
	assert_eq(String(left_debug.get("state", "")), "ready")
	assert_true(float(left_debug.get("wrist_velocity", 0.0)) >= float(left_debug.get("min_velocity", 0.0)))
	assert_true(float(left_debug.get("bbox_area_growth", 0.0)) >= float(left_debug.get("min_bbox_area_growth", 0.0)))
	assert_true(float(left_debug.get("elbow_shoulder_xy_distance", 0.0)) > float(left_debug.get("max_elbow_shoulder_xy_distance", 0.0)))
	assert_false(bool(left_debug.get("elbow_shoulder_xy_gate_passed", true)))

func test_straight_punch_ignores_deprecated_forward_depth_spike_threshold_config() -> void:
	config.gesture_profile_document = {
		"straight_punch": {
			"thresholds": {
				"min_velocity": 0.18,
				"min_bbox_area_growth": 0.003,
				"min_forward_depth_spike": 99.0,
			},
		},
	}
	substrate = PoseDetectorSubstrate.new().configure(config)
	_calibrate_stance()
	var state := substrate.process_landmarks(_make_pose_frame(), 1100, _make_tracking_frame(_tracked_hand_payload_physical("left", 0.020), _tracked_hand_payload_physical("right", 0.020)))
	state = substrate.process_landmarks(_make_pose_frame({PoseLandmarkIds.LEFT_WRIST: {"z": -0.04}}), 1180, _make_tracking_frame(_tracked_hand_payload_physical("left", 0.021), _tracked_hand_payload_physical("right", 0.020)))
	state = substrate.process_landmarks(_make_pose_frame({PoseLandmarkIds.LEFT_WRIST: {"z": -0.12}}), 1260, _make_tracking_frame(_tracked_hand_payload_physical("left", 0.0240), _tracked_hand_payload_physical("right", 0.020)))
	state = substrate.process_landmarks(_make_pose_frame({PoseLandmarkIds.LEFT_WRIST: {"z": -0.20}}), 1340, _make_tracking_frame(_tracked_hand_payload_physical("left", 0.0272), _tracked_hand_payload_physical("right", 0.020)))
	var left_debug: Dictionary = state.get("gesture_debug", {}).get("straight_punch", {}).get("left", {})
	assert_eq(String(left_debug.get("state", "")), "triggered")
	assert_true(float(left_debug.get("wrist_velocity", 0.0)) >= float(left_debug.get("min_velocity", 0.0)))
	assert_true(float(left_debug.get("bbox_area_growth", 0.0)) >= float(left_debug.get("min_bbox_area_growth", 0.0)))
	assert_true(bool(left_debug.get("elbow_shoulder_xy_gate_passed", false)))
	assert_true(is_equal_approx(float(left_debug.get("recent_peak_forward_depth_spike", 0.0)), 0.10))
	assert_false(left_debug.has("min_forward_depth_spike"))
	assert_false(left_debug.has("forward_depth_spike_gate_passed"))

func test_straight_punch_debug_surfaces_forward_depth_spike_metrics_without_gate_threshold() -> void:
	substrate = PoseDetectorSubstrate.new().configure(config)
	_calibrate_stance()
	var state := substrate.process_landmarks(_make_pose_frame(), 1100, _make_tracking_frame(_tracked_hand_payload_physical("left", 0.020), _tracked_hand_payload_physical("right", 0.020)))
	state = substrate.process_landmarks(_make_pose_frame({PoseLandmarkIds.LEFT_WRIST: {"z": -0.04}}), 1180, _make_tracking_frame(_tracked_hand_payload_physical("left", 0.021), _tracked_hand_payload_physical("right", 0.020)))
	state = substrate.process_landmarks(_make_pose_frame({PoseLandmarkIds.LEFT_WRIST: {"z": -0.12}}), 1260, _make_tracking_frame(_tracked_hand_payload_physical("left", 0.0240), _tracked_hand_payload_physical("right", 0.020)))
	state = substrate.process_landmarks(_make_pose_frame({PoseLandmarkIds.LEFT_WRIST: {"z": -0.20}}), 1340, _make_tracking_frame(_tracked_hand_payload_physical("left", 0.0272), _tracked_hand_payload_physical("right", 0.020)))
	assert_true(_event_names(state.get("events", [])).has("punch_left"))
	var left_debug: Dictionary = state.get("gesture_debug", {}).get("straight_punch", {}).get("left", {})
	assert_true(is_equal_approx(float(left_debug.get("forward_depth_spike", 0.0)), 0.10))
	assert_true(is_equal_approx(float(left_debug.get("recent_peak_forward_depth_spike", 0.0)), 0.10))
	assert_eq(int(left_debug.get("forward_depth_spike_window_span_ms", -1)), 240)
	assert_false(left_debug.has("min_forward_depth_spike"))
	assert_false(left_debug.has("forward_depth_spike_gate_passed"))

func test_straight_punch_debug_surfaces_elbow_shoulder_xy_gate_truth() -> void:
	_calibrate_stance()
	var state := substrate.process_landmarks(_make_pose_frame(), 1100, _make_tracking_frame(_tracked_hand_payload_physical("left", 0.020), _tracked_hand_payload_physical("right", 0.020)))
	state = substrate.process_landmarks(
		_make_pose_frame({
			PoseLandmarkIds.LEFT_SHOULDER: {"x": 0.35, "y": 0.60, "z": 0.0},
			PoseLandmarkIds.LEFT_ELBOW: {"x": 0.34, "y": 0.62, "z": -0.01},
			PoseLandmarkIds.LEFT_WRIST: {"x": 0.35, "y": 0.60, "z": -0.04},
		}),
		1180,
		_make_tracking_frame(_tracked_hand_payload_physical("left", 0.021), _tracked_hand_payload_physical("right", 0.020))
	)
	state = substrate.process_landmarks(
		_make_pose_frame({
			PoseLandmarkIds.LEFT_SHOULDER: {"x": 0.35, "y": 0.54, "z": 0.0},
			PoseLandmarkIds.LEFT_ELBOW: {"x": 0.34, "y": 0.56, "z": -0.02},
			PoseLandmarkIds.LEFT_WRIST: {"x": 0.35, "y": 0.54, "z": -0.12},
		}),
		1260,
		_make_tracking_frame(_tracked_hand_payload_physical("left", 0.0240), _tracked_hand_payload_physical("right", 0.020))
	)
	state = substrate.process_landmarks(
		_make_pose_frame({
			PoseLandmarkIds.LEFT_SHOULDER: {"x": 0.35, "y": 0.48, "z": 0.0},
			PoseLandmarkIds.LEFT_ELBOW: {"x": 0.34, "y": 0.50, "z": -0.03},
			PoseLandmarkIds.LEFT_WRIST: {"x": 0.35, "y": 0.48, "z": -0.20},
		}),
		1340,
		_make_tracking_frame(_tracked_hand_payload_physical("left", 0.0275), _tracked_hand_payload_physical("right", 0.020))
	)
	assert_true(_event_names(state.get("events", [])).has("punch_left"))
	var left_debug: Dictionary = state.get("gesture_debug", {}).get("straight_punch", {}).get("left", {})
	assert_true(is_equal_approx(float(left_debug.get("max_elbow_shoulder_xy_distance", 0.0)), 0.09))
	assert_true(is_equal_approx(float(left_debug.get("elbow_shoulder_xy_distance", 0.0)), sqrt(0.0005)))
	assert_true(bool(left_debug.get("elbow_shoulder_xy_gate_passed", false)))

func test_straight_punch_wrist_velocity_averages_all_samples_inside_configured_time_window() -> void:
	config.gesture_profile_document = {
		"straight_punch": {
			"evaluation": {
				"sample_window_size": 4,
				"min_positive_growth_samples": 1,
				"window_ms": 160,
			},
			"thresholds": {
				"min_velocity": 0.18,
				"min_bbox_area_growth": 0.00014,
			},
		},
	}
	substrate = PoseDetectorSubstrate.new().configure(config)
	_calibrate_stance()
	var state := substrate.process_landmarks(_make_pose_frame(), 1100, _make_tracking_frame(_tracked_hand_payload("left", 0.020), _tracked_hand_payload("right", 0.020)))
	state = substrate.process_landmarks(_make_pose_frame({
		PoseLandmarkIds.LEFT_ELBOW: {"z": -0.04},
		PoseLandmarkIds.LEFT_WRIST: {"z": -0.04},
	}), 1180, _make_tracking_frame(_tracked_hand_payload("left", 0.021), _tracked_hand_payload("right", 0.020)))
	state = substrate.process_landmarks(_make_pose_frame({
		PoseLandmarkIds.LEFT_ELBOW: {"z": -0.20},
		PoseLandmarkIds.LEFT_WRIST: {"z": -0.20},
	}), 1220, _make_tracking_frame(_tracked_hand_payload("left", 0.0240), _tracked_hand_payload("right", 0.020)))
	state = substrate.process_landmarks(_make_pose_frame({
		PoseLandmarkIds.LEFT_ELBOW: {"z": -0.205},
		PoseLandmarkIds.LEFT_WRIST: {"z": -0.205},
	}), 1340, _make_tracking_frame(_tracked_hand_payload("left", 0.0245), _tracked_hand_payload("right", 0.020)))
	var left_debug: Dictionary = state.get("gesture_debug", {}).get("straight_punch", {}).get("left", {})
	assert_eq(int(left_debug.get("window_ms", 0)), 160)
	assert_eq(int(left_debug.get("wrist_velocity_window_span_ms", 0)), 160)
	assert_true(is_equal_approx(float(left_debug.get("wrist_velocity", 0.0)), 2.0208333333333335))
	assert_true(is_equal_approx(float(left_debug.get("wrist_velocity", 0.0)), float(left_debug.get("wrist_forward_velocity", 0.0))))

func test_straight_punch_bbox_area_growth_uses_configured_time_window_instead_of_sample_count_only() -> void:
	config.gesture_profile_document = {
		"straight_punch": {
			"evaluation": {
				"sample_window_size": 4,
				"min_positive_growth_samples": 1,
				"window_ms": 160,
			},
			"thresholds": {
				"min_velocity": 99.0,
				"min_bbox_area_growth": 99.0,
			},
		},
	}
	substrate = PoseDetectorSubstrate.new().configure(config)
	_calibrate_stance()
	var state := substrate.process_landmarks(_make_pose_frame(), 1100, _make_tracking_frame(_tracked_hand_payload_physical("left", 0.020), _tracked_hand_payload_physical("right", 0.020)))
	state = substrate.process_landmarks(_make_pose_frame({
		PoseLandmarkIds.LEFT_ELBOW: {"z": -0.04},
		PoseLandmarkIds.LEFT_WRIST: {"z": -0.04},
	}), 1180, _make_tracking_frame(_tracked_hand_payload_physical("left", 0.021), _tracked_hand_payload_physical("right", 0.020)))
	state = substrate.process_landmarks(_make_pose_frame({PoseLandmarkIds.LEFT_WRIST: {"z": -0.12}}), 1260, _make_tracking_frame(_tracked_hand_payload_physical("left", 0.0240), _tracked_hand_payload_physical("right", 0.020)))
	state = substrate.process_landmarks(_make_pose_frame({PoseLandmarkIds.LEFT_WRIST: {"z": -0.18}}), 1340, _make_tracking_frame(_tracked_hand_payload_physical("left", 0.0245), _tracked_hand_payload_physical("right", 0.020)))
	var left_debug: Dictionary = state.get("gesture_debug", {}).get("straight_punch", {}).get("left", {})
	assert_eq(int(left_debug.get("window_ms", 0)), 160)
	assert_eq(int(left_debug.get("bbox_area_growth_window_span_ms", 0)), 160)
	assert_true(is_equal_approx(float(left_debug.get("bbox_area_growth", 0.0)), 0.0035))
	var growth_window_areas: Array = left_debug.get("growth_window_areas", [])
	assert_eq(growth_window_areas.size(), 3)
	assert_true(is_equal_approx(float(growth_window_areas[0]), 0.021))
	assert_true(is_equal_approx(float(growth_window_areas[1]), 0.024))
	assert_true(is_equal_approx(float(growth_window_areas[2]), 0.0245))

func test_straight_punch_bbox_area_growth_sums_adjacent_deltas_and_counts_only_strictly_positive_steps() -> void:
	config.gesture_profile_document = {
		"straight_punch": {
			"evaluation": {
				"sample_window_size": 9,
				"min_positive_growth_samples": 1,
				"window_ms": 1000,
			},
			"thresholds": {
				"min_velocity": 99.0,
				"min_bbox_area_growth": 99.0,
			},
		},
	}
	substrate = PoseDetectorSubstrate.new().configure(config)
	_calibrate_stance()
	var bbox_areas := [0.004, 0.004, 0.007, 0.007, 0.006, 0.010, 0.010, 0.007, 0.007]
	var timestamp_ms := 1100
	var state: Dictionary = {}
	for idx in range(bbox_areas.size()):
		state = substrate.process_landmarks(
			_make_pose_frame({PoseLandmarkIds.LEFT_WRIST: {"z": -0.04 * idx}}),
			timestamp_ms + idx * 40,
			_make_tracking_frame(_tracked_hand_payload_physical("left", float(bbox_areas[idx]), "tracked", true, 0, idx + 1, 1.10 + float(idx) * 0.04), _tracked_hand_payload_physical("right", 0.020))
		)
	var left_debug: Dictionary = state.get("gesture_debug", {}).get("straight_punch", {}).get("left", {})
	assert_eq(int(left_debug.get("bbox_area_growth_window_span_ms", 0)), 320)
	assert_true(is_equal_approx(float(left_debug.get("bbox_area_growth", 0.0)), 0.003))
	assert_eq(int(left_debug.get("positive_growth_samples", 0)), 2)
	var growth_window_areas: Array = left_debug.get("growth_window_areas", [])
	assert_eq(growth_window_areas.size(), 9)
	assert_true(is_equal_approx(float(growth_window_areas[0]), 0.004))
	assert_true(is_equal_approx(float(growth_window_areas[8]), 0.007))

func test_straight_punch_uses_recent_wrist_velocity_peak_when_growth_lands_on_next_hand_sample() -> void:
	config.gesture_profile_document = {
		"straight_punch": {
			"evaluation": {
				"sample_window_size": 4,
				"min_positive_growth_samples": 1,
				"window_ms": 80,
			},
			"thresholds": {
				"min_velocity": 0.18,
				"min_bbox_area_growth": 0.006,
			},
		},
	}
	substrate = PoseDetectorSubstrate.new().configure(config)
	_calibrate_stance()
	var state := substrate.process_landmarks(_make_pose_frame(), 1100, _make_tracking_frame(_tracked_hand_payload_physical("left", 0.020, "tracked", true, 0, 10, 1.0, null, "", 0), _tracked_hand_payload_physical("right", 0.020, "tracked", true, 0, 10, 1.0)))
	state = substrate.process_landmarks(_make_pose_frame({PoseLandmarkIds.LEFT_WRIST: {"z": -0.04}}), 1180, _make_tracking_frame(_tracked_hand_payload_physical("left", 0.021, "tracked", true, 0, 11, 1.1, null, "", 80), _tracked_hand_payload_physical("right", 0.020, "tracked", true, 0, 11, 1.1)))
	assert_eq(String(state.get("gesture_debug", {}).get("straight_punch", {}).get("left", {}).get("state", "")), "ready")

	state = substrate.process_landmarks(_make_pose_frame({PoseLandmarkIds.LEFT_WRIST: {"z": -0.08}}), 1260, _make_tracking_frame(_tracked_hand_payload_physical("left", 0.023, "tracked", true, 0, 12, 1.2), _tracked_hand_payload_physical("right", 0.020, "tracked", true, 0, 12, 1.2)))
	state = substrate.process_landmarks(_make_pose_frame({PoseLandmarkIds.LEFT_WRIST: {"z": -0.20}}), 1340, _make_tracking_frame(_tracked_hand_payload_physical("left", 0.0240, "tracked", true, 0, 13, 1.3), _tracked_hand_payload_physical("right", 0.020, "tracked", true, 0, 13, 1.3)))
	state = substrate.process_landmarks(_make_pose_frame({PoseLandmarkIds.LEFT_WRIST: {"z": -0.205}}), 1420, _make_tracking_frame(_tracked_hand_payload_physical("left", 0.0305, "tracked", true, 0, 14, 1.4), _tracked_hand_payload_physical("right", 0.020, "tracked", true, 0, 14, 1.4)))
	assert_true(_event_names(state.get("events", [])).has("punch_left"))
	assert_eq(_straight_punch_state_names(state.get("events", []), "left"), ["triggered"])
	var left_debug: Dictionary = state.get("gesture_debug", {}).get("straight_punch", {}).get("left", {})
	assert_true(float(left_debug.get("recent_peak_wrist_velocity", 0.0)) > float(left_debug.get("wrist_velocity", 0.0)))
	assert_true(float(left_debug.get("wrist_velocity", 0.0)) < float(left_debug.get("min_velocity", 0.0)))

func test_straight_punch_uses_recent_bbox_growth_peak_when_velocity_lands_on_next_hand_sample() -> void:
	config.gesture_profile_document = {
		"straight_punch": {
			"evaluation": {
				"sample_window_size": 4,
				"min_positive_growth_samples": 1,
			},
			"thresholds": {
				"min_velocity": 0.18,
				"min_bbox_area_growth": 0.00014,
			},
		},
	}
	substrate = PoseDetectorSubstrate.new().configure(config)
	_calibrate_stance()
	var state := substrate.process_landmarks(_make_pose_frame(), 1100, _make_tracking_frame(_tracked_hand_payload_physical("left", 0.020, "tracked", true, 0, 10, 1.0, null, "", 0), _tracked_hand_payload_physical("right", 0.020, "tracked", true, 0, 10, 1.0)))
	state = substrate.process_landmarks(_make_pose_frame({
		PoseLandmarkIds.LEFT_ELBOW: {"z": -0.01},
		PoseLandmarkIds.LEFT_WRIST: {"z": -0.01},
	}), 1180, _make_tracking_frame(_tracked_hand_payload_physical("left", 0.021, "tracked", true, 0, 11, 1.1, null, "", 80), _tracked_hand_payload_physical("right", 0.020, "tracked", true, 0, 11, 1.1)))
	assert_eq(String(state.get("gesture_debug", {}).get("straight_punch", {}).get("left", {}).get("state", "")), "ready")

	state = substrate.process_landmarks(_make_pose_frame({
		PoseLandmarkIds.LEFT_ELBOW: {"z": -0.01},
		PoseLandmarkIds.LEFT_WRIST: {"z": -0.01},
	}), 1260, _make_tracking_frame(_tracked_hand_payload_physical("left", 0.02125, "tracked", true, 0, 12, 1.2), _tracked_hand_payload_physical("right", 0.020, "tracked", true, 0, 12, 1.2)))
	assert_false(_event_names(state.get("events", [])).has("punch_left"))
	state = substrate.process_landmarks(_make_pose_frame({
		PoseLandmarkIds.LEFT_ELBOW: {"z": -0.021},
		PoseLandmarkIds.LEFT_WRIST: {"z": -0.021},
	}), 1340, _make_tracking_frame(_tracked_hand_payload_physical("left", 0.02110, "tracked", true, 0, 13, 1.3), _tracked_hand_payload_physical("right", 0.020, "tracked", true, 0, 13, 1.3)))
	assert_false(_event_names(state.get("events", [])).has("punch_left"))
	state = substrate.process_landmarks(_make_pose_frame({
		PoseLandmarkIds.LEFT_ELBOW: {"z": -0.20},
		PoseLandmarkIds.LEFT_WRIST: {"z": -0.20},
	}), 1420, _make_tracking_frame(_tracked_hand_payload_physical("left", 0.02112, "tracked", true, 0, 14, 1.4), _tracked_hand_payload_physical("right", 0.020, "tracked", true, 0, 14, 1.4)))
	assert_true(_event_names(state.get("events", [])).has("punch_left"))
	assert_eq(_straight_punch_state_names(state.get("events", []), "left"), ["triggered"])
	var left_debug: Dictionary = state.get("gesture_debug", {}).get("straight_punch", {}).get("left", {})
	assert_true(float(left_debug.get("recent_peak_bbox_area_growth", 0.0)) > float(left_debug.get("bbox_area_growth", 0.0)))
	assert_true(float(left_debug.get("bbox_area_growth", 0.0)) < float(left_debug.get("min_bbox_area_growth", 0.0)))

func test_straight_punch_keeps_recent_velocity_peak_across_non_fresh_replay_duplicates() -> void:
	config.gesture_profile_document = {
		"straight_punch": {
			"evaluation": {
				"window_ms": 250,
			},
		},
	}
	substrate = PoseDetectorSubstrate.new().configure(config)
	_calibrate_stance()
	var state := substrate.process_landmarks(_make_pose_frame(), 1100, _make_tracking_frame(_tracked_hand_payload_physical("left", 0.020, "tracked", true, 0, 10, 1.0, null, "", 0), _tracked_hand_payload_physical("right", 0.020, "tracked", true, 0, 10, 1.0)))
	state = substrate.process_landmarks(_make_pose_frame({PoseLandmarkIds.LEFT_WRIST: {"z": -0.04}}), 1180, _make_tracking_frame(_tracked_hand_payload_physical("left", 0.021, "tracked", true, 0, 11, 1.1, null, "", 80), _tracked_hand_payload_physical("right", 0.020, "tracked", true, 0, 11, 1.1)))
	assert_eq(String(state.get("gesture_debug", {}).get("straight_punch", {}).get("left", {}).get("state", "")), "ready")

	state = substrate.process_landmarks(_make_pose_frame({PoseLandmarkIds.LEFT_WRIST: {"z": -0.12}}), 1260, _make_tracking_frame(_tracked_hand_payload_physical("left", 0.023, "tracked", true, 0, 12, 1.2), _tracked_hand_payload_physical("right", 0.020, "tracked", true, 0, 12, 1.2)))
	assert_false(_event_names(state.get("events", [])).has("punch_left"))

	for duplicate_time in [1270, 1280, 1290, 1300, 1310]:
		state = substrate.process_landmarks(_make_pose_frame({PoseLandmarkIds.LEFT_WRIST: {"z": -0.121}}), duplicate_time, _make_tracking_frame(_tracked_hand_payload_physical("left", 0.023, "tracked", true, 0, 12, 1.2), _tracked_hand_payload_physical("right", 0.020, "tracked", true, 0, 12, 1.2)))
		assert_false(_event_names(state.get("events", [])).has("punch_left"))

	state = substrate.process_landmarks(_make_pose_frame({PoseLandmarkIds.LEFT_WRIST: {"z": -0.122}}), 1410, _make_tracking_frame(_tracked_hand_payload_physical("left", 0.0295, "tracked", true, 0, 13, 1.3), _tracked_hand_payload_physical("right", 0.020, "tracked", true, 0, 13, 1.3)))
	assert_true(_event_names(state.get("events", [])).has("punch_left"))
	assert_eq(_straight_punch_state_names(state.get("events", []), "left"), ["triggered"])
	var duplicate_debug: Dictionary = state.get("gesture_debug", {}).get("straight_punch", {}).get("left", {})
	assert_true(float(duplicate_debug.get("recent_peak_wrist_velocity", 0.0)) > float(duplicate_debug.get("wrist_velocity", 0.0)))
	assert_true(float(duplicate_debug.get("recent_peak_wrist_velocity", 0.0)) > float(duplicate_debug.get("min_velocity", 0.0)))

func test_straight_punch_dedupes_replayed_tracked_samples_until_hand_frame_advances() -> void:
	_calibrate_stance()
	var state := substrate.process_landmarks(
		_make_pose_frame(),
		1100,
		_make_tracking_frame(_tracked_hand_payload_physical("left", 0.020, "tracked", true, 0, 10, 1.0, null, "", 0), _tracked_hand_payload_physical("right", 0.020, "tracked", true, 0, 10, 1.0))
	)
	assert_eq(String(state.get("gesture_debug", {}).get("straight_punch", {}).get("left", {}).get("state", "")), "tracking_lost")

	state = substrate.process_landmarks(
		_make_pose_frame({PoseLandmarkIds.LEFT_WRIST: {"z": -0.04}}),
		1180,
		_make_tracking_frame(_tracked_hand_payload_physical("left", 0.021, "tracked", true, 0, 11, 1.1, null, "", 80), _tracked_hand_payload_physical("right", 0.020, "tracked", true, 0, 11, 1.1))
	)
	assert_eq(String(state.get("gesture_debug", {}).get("straight_punch", {}).get("left", {}).get("state", "")), "ready")

	state = substrate.process_landmarks(
		_make_pose_frame({PoseLandmarkIds.LEFT_WRIST: {"z": -0.08}}),
		1200,
		_make_tracking_frame(_tracked_hand_payload_physical("left", 0.023, "tracked", true, 0, 12, 1.2), _tracked_hand_payload_physical("right", 0.020, "tracked", true, 0, 12, 1.2))
	)
	state = substrate.process_landmarks(
		_make_pose_frame({PoseLandmarkIds.LEFT_WRIST: {"z": -0.12}}),
		1210,
		_make_tracking_frame(_tracked_hand_payload_physical("left", 0.023, "tracked", true, 0, 12, 1.2), _tracked_hand_payload_physical("right", 0.020, "tracked", true, 0, 12, 1.2))
	)
	var left_debug: Dictionary = state.get("gesture_debug", {}).get("straight_punch", {}).get("left", {})
	assert_true(is_equal_approx(float(left_debug.get("bbox_area_growth", 0.0)), 0.002))
	assert_eq(int(left_debug.get("positive_growth_samples", 0)), 1)

	state = substrate.process_landmarks(
		_make_pose_frame({PoseLandmarkIds.LEFT_WRIST: {"z": -0.20}}),
		1280,
		_make_tracking_frame(_tracked_hand_payload_physical("left", 0.0272, "tracked", true, 0, 13, 1.3), _tracked_hand_payload_physical("right", 0.020, "tracked", true, 0, 13, 1.3))
	)
	assert_true(_event_names(state.get("events", [])).has("punch_left"))
	assert_eq(_straight_punch_state_names(state.get("events", []), "left"), ["triggered"])

func test_straight_punch_grace_rearm_and_reacquire_transitions() -> void:
	_calibrate_stance()
	var frames := [
		{"ts": 1100, "z": 0.00, "area": 0.020},
		{"ts": 1180, "z": -0.04, "area": 0.021},
		{"ts": 1260, "z": -0.08, "area": 0.023},
		{"ts": 1340, "z": -0.12, "area": 0.0225},
		{"ts": 1420, "z": -0.20, "area": 0.0275},
	]
	var state: Dictionary = {}
	for frame_data: Dictionary in frames:
		state = substrate.process_landmarks(
			_make_pose_frame({PoseLandmarkIds.LEFT_WRIST: {"z": float(frame_data.get("z", 0.0))}}),
			int(frame_data.get("ts", 0)),
			_make_tracking_frame(_tracked_hand_payload_physical("left", float(frame_data.get("area", 0.0))), _tracked_hand_payload_physical("right", 0.020))
		)
	assert_eq(String(state.get("gesture_debug", {}).get("straight_punch", {}).get("left", {}).get("state", "")), "triggered")

	state = substrate.process_landmarks(_make_pose_frame({PoseLandmarkIds.LEFT_WRIST: {"z": -0.22}}), 1500, _make_tracking_frame(_tracked_hand_payload_physical("left", 0.0280), _tracked_hand_payload_physical("right", 0.020)))
	var left_debug: Dictionary = state.get("gesture_debug", {}).get("straight_punch", {}).get("left", {})
	assert_eq(String(left_debug.get("state", "")), "triggered")
	assert_eq(int(left_debug.get("grace_ms_remaining", -1)), 160)
	state = substrate.process_landmarks(_make_pose_frame({PoseLandmarkIds.LEFT_WRIST: {"z": -0.21}}), 1580, _make_tracking_frame(_tracked_hand_payload_physical("left", 0.0260), _tracked_hand_payload_physical("right", 0.020)))
	left_debug = state.get("gesture_debug", {}).get("straight_punch", {}).get("left", {})
	assert_eq(String(left_debug.get("state", "")), "triggered")
	assert_eq(int(left_debug.get("grace_ms_remaining", -1)), 80)
	state = substrate.process_landmarks(_make_pose_frame({PoseLandmarkIds.LEFT_WRIST: {"z": -0.18}}), 1660, _make_tracking_frame(_tracked_hand_payload_physical("left", 0.0240), _tracked_hand_payload_physical("right", 0.020)))
	left_debug = state.get("gesture_debug", {}).get("straight_punch", {}).get("left", {})
	assert_eq(_straight_punch_state_names(state.get("events", []), "left"), ["not_ready"])
	assert_eq(String(left_debug.get("state", "")), "not_ready")
	assert_eq(int(left_debug.get("grace_ms_remaining", -1)), 0)

	state = substrate.process_landmarks(_make_pose_frame({PoseLandmarkIds.LEFT_WRIST: {"z": -0.03}}), 1740, _make_tracking_frame(_tracked_hand_payload_physical("left", 0.0220), _tracked_hand_payload_physical("right", 0.020)))
	assert_eq(_straight_punch_state_names(state.get("events", []), "left"), ["ready"])
	assert_eq(String(state.get("gesture_debug", {}).get("straight_punch", {}).get("left", {}).get("state", "")), "ready")

	state = substrate.process_landmarks(_make_pose_frame({PoseLandmarkIds.LEFT_WRIST: {"z": -0.03}}), 1820, _make_tracking_frame(_tracked_hand_payload_physical("left", 0.040, "reacquiring", false, 0, 1, 0.0, true, "fresh_inference", 0), _tracked_hand_payload_physical("right", 0.020)))
	left_debug = state.get("gesture_debug", {}).get("straight_punch", {}).get("left", {})
	assert_eq(_straight_punch_state_names(state.get("events", []), "left"), [])
	assert_eq(String(left_debug.get("state", "")), "ready")
	assert_eq(String(left_debug.get("tracking_state", "")), "reacquiring")
	assert_false(bool(left_debug.get("tracking_valid", true)))
	assert_true(float(left_debug.get("bbox_area_growth", 0.0)) > 0.0)
	state = substrate.process_landmarks(_make_pose_frame({PoseLandmarkIds.LEFT_WRIST: {"z": -0.02}}), 1900, _make_tracking_frame(_tracked_hand_payload_physical("left", 0.022, "tracked", true, 0, 1, 0.0, true, "fresh_inference", 20), _tracked_hand_payload_physical("right", 0.020)))
	left_debug = state.get("gesture_debug", {}).get("straight_punch", {}).get("left", {})
	assert_eq(_straight_punch_state_names(state.get("events", []), "left"), [])
	assert_eq(String(left_debug.get("state", "")), "ready")
	assert_eq(int(left_debug.get("reacquire_stable_ms_required", -1)), 40)
	assert_eq(int(left_debug.get("stable_ms", -1)), 20)
	state = substrate.process_landmarks(_make_pose_frame({PoseLandmarkIds.LEFT_WRIST: {"z": -0.01}}), 1980, _make_tracking_frame(_tracked_hand_payload_physical("left", 0.023, "tracked", true, 0, 1, 0.0, true, "fresh_inference", 40), _tracked_hand_payload_physical("right", 0.020)))
	assert_eq(_straight_punch_state_names(state.get("events", []), "left"), ["triggered"])
	assert_true(_event_names(state.get("events", [])).has("punch_left"))
	left_debug = state.get("gesture_debug", {}).get("straight_punch", {}).get("left", {})
	assert_eq(String(left_debug.get("state", "")), "triggered")

func test_straight_punch_triggered_grace_uses_elapsed_milliseconds() -> void:
	config.gesture_profile_document = {
		"straight_punch": {
			"evaluation": {
				"sample_window_size": 4,
				"min_positive_growth_samples": 1,
			},
			"thresholds": {
				"min_velocity": 0.18,
				"min_bbox_area_growth": 0.00014,
			},
			"timing": {
				"triggered_grace_ms": 200,
			},
			"rearm": {
				"bbox_area_retract_epsilon": 0.0003,
			},
		}
	}
	substrate = PoseDetectorSubstrate.new().configure(config)
	_calibrate_stance()
	var state := substrate.process_landmarks(_make_pose_frame(), 1100, _make_tracking_frame(_tracked_hand_payload_physical("left", 0.00460, "tracked", true, 0, 1, 0.0, null, "", 0), _tracked_hand_payload_physical("right", 0.020)))
	state = substrate.process_landmarks(_make_pose_frame({PoseLandmarkIds.LEFT_WRIST: {"z": -0.04}}), 1180, _make_tracking_frame(_tracked_hand_payload_physical("left", 0.00476, "tracked", true, 0, 1, 0.0, null, "", 80), _tracked_hand_payload_physical("right", 0.020)))
	state = substrate.process_landmarks(_make_pose_frame({PoseLandmarkIds.LEFT_WRIST: {"z": -0.18}}), 1260, _make_tracking_frame(_tracked_hand_payload_physical("left", 0.00522), _tracked_hand_payload_physical("right", 0.020)))
	var left_debug: Dictionary = state.get("gesture_debug", {}).get("straight_punch", {}).get("left", {})
	assert_true(_event_names(state.get("events", [])).has("punch_left"))
	assert_eq(String(left_debug.get("state", "")), "triggered")
	assert_eq(int(left_debug.get("grace_ms_remaining", -1)), 200)

	state = substrate.process_landmarks(_make_pose_frame({PoseLandmarkIds.LEFT_WRIST: {"z": -0.17}}), 1330, _make_tracking_frame(_tracked_hand_payload_physical("left", 0.00518), _tracked_hand_payload_physical("right", 0.020)))
	left_debug = state.get("gesture_debug", {}).get("straight_punch", {}).get("left", {})
	assert_eq(String(left_debug.get("state", "")), "triggered")
	assert_eq(int(left_debug.get("grace_ms_remaining", -1)), 130)

	state = substrate.process_landmarks(_make_pose_frame({PoseLandmarkIds.LEFT_WRIST: {"z": -0.16}}), 1460, _make_tracking_frame(_tracked_hand_payload_physical("left", 0.00510), _tracked_hand_payload_physical("right", 0.020)))
	left_debug = state.get("gesture_debug", {}).get("straight_punch", {}).get("left", {})
	assert_eq(_straight_punch_state_names(state.get("events", []), "left"), ["not_ready"])
	assert_eq(String(left_debug.get("state", "")), "not_ready")
	assert_eq(int(left_debug.get("grace_ms_remaining", -1)), 0)

func test_straight_punch_rearms_between_tuned_fixture_scale_punches() -> void:
	config.gesture_profile_document = {
		"straight_punch": {
			"evaluation": {
				"sample_window_size": 4,
				"min_positive_growth_samples": 1,
			},
			"thresholds": {
				"min_velocity": 0.18,
				"min_bbox_area_growth": 0.00014,
			},
			"timing": {
				"triggered_grace_ms": 240,
			},
			"rearm": {
				"bbox_area_retract_epsilon": 0.0003,
			},
		}
	}
	substrate = PoseDetectorSubstrate.new().configure(config)
	_calibrate_stance()
	var state := substrate.process_landmarks(_make_pose_frame(), 1100, _make_tracking_frame(_tracked_hand_payload_physical("left", 0.00460, "tracked", true, 0, 1, 0.0, null, "", 0), _tracked_hand_payload_physical("right", 0.020)))
	state = substrate.process_landmarks(_make_pose_frame({PoseLandmarkIds.LEFT_WRIST: {"z": -0.04}}), 1180, _make_tracking_frame(_tracked_hand_payload_physical("left", 0.00476, "tracked", true, 0, 1, 0.0, null, "", 80), _tracked_hand_payload_physical("right", 0.020)))
	assert_eq(_straight_punch_state_names(state.get("events", []), "left"), ["ready"])
	state = substrate.process_landmarks(_make_pose_frame({PoseLandmarkIds.LEFT_WRIST: {"z": -0.18}}), 1260, _make_tracking_frame(_tracked_hand_payload_physical("left", 0.00522), _tracked_hand_payload_physical("right", 0.020)))
	assert_true(_event_names(state.get("events", [])).has("punch_left"))
	assert_eq(String(state.get("gesture_debug", {}).get("straight_punch", {}).get("left", {}).get("state", "")), "triggered")

	state = substrate.process_landmarks(_make_pose_frame({PoseLandmarkIds.LEFT_WRIST: {"z": -0.18}}), 1340, _make_tracking_frame(_tracked_hand_payload_physical("left", 0.00522), _tracked_hand_payload_physical("right", 0.020)))
	state = substrate.process_landmarks(_make_pose_frame({PoseLandmarkIds.LEFT_WRIST: {"z": -0.17}}), 1420, _make_tracking_frame(_tracked_hand_payload_physical("left", 0.00518), _tracked_hand_payload_physical("right", 0.020)))
	state = substrate.process_landmarks(_make_pose_frame({PoseLandmarkIds.LEFT_WRIST: {"z": -0.16}}), 1500, _make_tracking_frame(_tracked_hand_payload_physical("left", 0.00510), _tracked_hand_payload_physical("right", 0.020)))
	assert_eq(_straight_punch_state_names(state.get("events", []), "left"), ["not_ready"])
	state = substrate.process_landmarks(_make_pose_frame({PoseLandmarkIds.LEFT_WRIST: {"z": -0.06}}), 1580, _make_tracking_frame(_tracked_hand_payload_physical("left", 0.00482), _tracked_hand_payload_physical("right", 0.020)))
	assert_eq(_straight_punch_state_names(state.get("events", []), "left"), ["ready"])
	assert_eq(String(state.get("gesture_debug", {}).get("straight_punch", {}).get("left", {}).get("state", "")), "ready")

	state = substrate.process_landmarks(_make_pose_frame({PoseLandmarkIds.LEFT_WRIST: {"z": -0.20}}), 1660, _make_tracking_frame(_tracked_hand_payload_physical("left", 0.00536), _tracked_hand_payload_physical("right", 0.020)))
	assert_true(_event_names(state.get("events", [])).has("punch_left"))
	assert_eq(_straight_punch_state_names(state.get("events", []), "left"), ["triggered"])

func test_straight_punch_hands_enabled_still_requires_hand_growth_signal() -> void:
	_calibrate_stance()
	var state := substrate.process_landmarks(_make_pose_frame(), 1100, _make_tracking_frame(_tracked_hand_payload("left", 0.020), _tracked_hand_payload("right", 0.020)))
	assert_eq(String(state.get("gesture_debug", {}).get("straight_punch", {}).get("left", {}).get("state", "")), "ready")
	state = substrate.process_landmarks(_make_pose_frame({
		PoseLandmarkIds.LEFT_ELBOW: {"z": -0.09},
		PoseLandmarkIds.LEFT_WRIST: {"z": -0.01},
	}), 1180, _make_tracking_frame(_tracked_hand_payload("left", 0.020, "tracked", true, 0, 2, 0.08), _tracked_hand_payload("right", 0.020)))
	assert_false(_event_names(state.get("events", [])).has("punch_left"))
	var left_debug: Dictionary = state.get("gesture_debug", {}).get("straight_punch", {}).get("left", {})
	assert_true(bool(left_debug.get("hand_tracking_enabled", false)))
	assert_eq(String(left_debug.get("velocity_signal_source", "")), "elbow_plus_wrist")
	assert_true(float(state.get("metrics", {}).get("measurements", {}).get("left_wrist_velocity_magnitude", 0.0)) < float(left_debug.get("min_velocity", 0.0)))
	assert_true(float(left_debug.get("wrist_velocity", 0.0)) > float(left_debug.get("min_velocity", 0.0)))
	assert_eq(String(left_debug.get("state", "")), "ready")

func test_straight_punch_pose_only_mode_combines_elbow_and_wrist_velocity_signal() -> void:
	_disable_hand_tracking_for_straight_punch()
	_calibrate_stance()
	var state := substrate.process_landmarks(_make_pose_frame(), 1100)
	assert_eq(String(state.get("gesture_debug", {}).get("straight_punch", {}).get("left", {}).get("state", "")), "tracking_lost")
	state = substrate.process_landmarks(_make_pose_frame({
		PoseLandmarkIds.LEFT_ELBOW: {"z": -0.01},
		PoseLandmarkIds.LEFT_WRIST: {"z": -0.02},
	}), 1140)
	assert_eq(_straight_punch_state_names(state.get("events", []), "left"), ["ready"])
	state = substrate.process_landmarks(_make_pose_frame({
		PoseLandmarkIds.LEFT_ELBOW: {"z": -0.09},
		PoseLandmarkIds.LEFT_WRIST: {"z": -0.01},
	}), 1220)
	assert_true(_event_names(state.get("events", [])).has("punch_left"))
	var left_debug: Dictionary = state.get("gesture_debug", {}).get("straight_punch", {}).get("left", {})
	assert_eq(String(left_debug.get("velocity_signal_source", "")), "elbow_plus_wrist")
	assert_true(float(state.get("metrics", {}).get("measurements", {}).get("left_wrist_velocity_magnitude", 0.0)) < float(left_debug.get("min_velocity", 0.0)))
	assert_true(float(left_debug.get("wrist_velocity", 0.0)) > float(left_debug.get("min_velocity", 0.0)))
	assert_eq(String(left_debug.get("state", "")), "triggered")

func test_straight_punch_pose_only_mode_triggers_from_pose_velocity_without_hand_growth() -> void:
	_disable_hand_tracking_for_straight_punch()
	_calibrate_stance()
	var state := substrate.process_landmarks(_make_pose_frame(), 1100)
	assert_eq(String(state.get("gesture_debug", {}).get("straight_punch", {}).get("left", {}).get("state", "")), "tracking_lost")
	state = substrate.process_landmarks(_make_pose_frame({PoseLandmarkIds.LEFT_WRIST: {"z": -0.02}}), 1140)
	assert_eq(_straight_punch_state_names(state.get("events", []), "left"), ["ready"])
	state = substrate.process_landmarks(_make_pose_frame({PoseLandmarkIds.LEFT_WRIST: {"z": -0.18}}), 1220)
	assert_true(_event_names(state.get("events", [])).has("punch_left"))
	var left_debug: Dictionary = state.get("gesture_debug", {}).get("straight_punch", {}).get("left", {})
	assert_false(bool(left_debug.get("hand_tracking_enabled", true)))
	assert_true(bool(left_debug.get("pose_tracking_valid", false)))
	assert_eq(String(left_debug.get("sample_source", "")), "pose")
	assert_eq(String(left_debug.get("velocity_signal_source", "")), "elbow_plus_wrist")
	assert_eq(int(left_debug.get("positive_growth_samples", -1)), 0)
	assert_true(is_equal_approx(float(left_debug.get("bbox_area_growth", -1.0)), 0.0))
	assert_eq(String(left_debug.get("state", "")), "triggered")

func test_straight_punch_pose_only_mode_enters_tracking_lost_from_pose_loss() -> void:
	_disable_hand_tracking_for_straight_punch()
	_calibrate_stance()
	substrate.process_landmarks(_make_pose_frame(), 1100)
	var state := substrate.process_landmarks(_make_pose_frame({PoseLandmarkIds.LEFT_WRIST: {"z": -0.02}}), 1140)
	assert_eq(_straight_punch_state_names(state.get("events", []), "left"), ["ready"])
	state = substrate.process_landmarks(_make_pose_frame({PoseLandmarkIds.LEFT_WRIST: {"z": -0.18}}), 1220)
	assert_eq(_straight_punch_state_names(state.get("events", []), "left"), ["triggered"])
	state = substrate.process_landmarks(_make_pose_frame({
		PoseLandmarkIds.LEFT_WRIST: {"v": 0.2},
	}), 1300)
	assert_eq(_straight_punch_state_names(state.get("events", []), "left"), ["tracking_lost"])
	var left_debug: Dictionary = state.get("gesture_debug", {}).get("straight_punch", {}).get("left", {})
	assert_false(bool(left_debug.get("pose_tracking_valid", true)))
	assert_eq(String(left_debug.get("tracking_state", "")), "pose_missing")
	assert_eq(String(left_debug.get("state", "")), "tracking_lost")

func test_straight_punch_pose_only_mode_rearms_on_elapsed_timer() -> void:
	_disable_hand_tracking_for_straight_punch()
	_calibrate_stance()
	substrate.process_landmarks(_make_pose_frame(), 1100)
	var state := substrate.process_landmarks(_make_pose_frame({PoseLandmarkIds.LEFT_WRIST: {"z": -0.02}}), 1140)
	assert_eq(_straight_punch_state_names(state.get("events", []), "left"), ["ready"])
	state = substrate.process_landmarks(_make_pose_frame({PoseLandmarkIds.LEFT_WRIST: {"z": -0.18}}), 1220)
	assert_true(_event_names(state.get("events", [])).has("punch_left"))
	state = substrate.process_landmarks(_make_pose_frame({PoseLandmarkIds.LEFT_WRIST: {"z": -0.16}}), 1460)
	assert_eq(_straight_punch_state_names(state.get("events", []), "left"), ["not_ready"])
	var left_debug: Dictionary = state.get("gesture_debug", {}).get("straight_punch", {}).get("left", {})
	assert_eq(int(left_debug.get("pose_only_rearm_ms", -1)), 250)
	state = substrate.process_landmarks(_make_pose_frame({PoseLandmarkIds.LEFT_WRIST: {"z": -0.08}}), 1700)
	assert_eq(_straight_punch_state_names(state.get("events", []), "left"), [])
	assert_eq(String(state.get("gesture_debug", {}).get("straight_punch", {}).get("left", {}).get("state", "")), "not_ready")
	state = substrate.process_landmarks(_make_pose_frame({PoseLandmarkIds.LEFT_WRIST: {"z": -0.04}}), 1710)
	assert_eq(_straight_punch_state_names(state.get("events", []), "left"), ["ready"])
	assert_eq(String(state.get("gesture_debug", {}).get("straight_punch", {}).get("left", {}).get("state", "")), "ready")

func test_hook_uses_pose_primary_state_machine_and_debug_surfaces() -> void:
	_calibrate_stance()
	var state := substrate.process_landmarks(_make_pose_frame(), 1000)
	assert_eq(String(state.get("gesture_debug", {}).get("hook", {}).get("right", {}).get("state", "")), "tracking_lost")

	state = substrate.process_landmarks(_make_pose_frame(), 1160)
	assert_eq(_pose_strike_state_names(state.get("events", []), "hook", "right"), ["ready"])
	assert_eq(String(state.get("gesture_debug", {}).get("hook", {}).get("right", {}).get("state", "")), "ready")

	state = substrate.process_landmarks(_make_pose_frame({
		PoseLandmarkIds.RIGHT_ELBOW: {"x": 0.55, "y": 0.62},
		PoseLandmarkIds.RIGHT_WRIST: {"x": 0.46, "y": 0.60},
	}), 1320)
	assert_true(_event_names(state.get("events", [])).has("hook_right"))
	assert_eq(_pose_strike_state_names(state.get("events", []), "hook", "right"), ["triggered"])
	var right_debug: Dictionary = state.get("gesture_debug", {}).get("hook", {}).get("right", {})
	assert_eq(String(right_debug.get("state", "")), "triggered")
	assert_eq(int(right_debug.get("window_ms", 0)), 160)
	assert_true(float(right_debug.get("horizontal_direction_velocity", 0.0)) >= float(right_debug.get("min_velocity", 1.0)))
	assert_true(float(right_debug.get("dominance_ratio", 0.0)) >= float(right_debug.get("min_lateral_dominance_ratio", 99.0)))
	assert_true(absf(float(right_debug.get("outward_distance", 0.0))) >= 0.0)
	assert_true(float(right_debug.get("directionality_ratio", 0.0)) >= float(right_debug.get("min_horizontal_direction_ratio", 99.0)))
	assert_eq(String(right_debug.get("required_direction_label", "")), "leftward")
	assert_eq(String(right_debug.get("direction_reference_frame", "")), "preview_space_horizontal")
	assert_eq(String(right_debug.get("sample_source", "")), "pose")
	assert_eq(String(right_debug.get("tracking_state", "")), "pose_tracked")

	state = substrate.process_landmarks(_make_pose_frame({
		PoseLandmarkIds.RIGHT_ELBOW: {"x": 0.55, "y": 0.62},
		PoseLandmarkIds.RIGHT_WRIST: {"x": 0.46, "y": 0.60},
	}), 1568)
	assert_eq(_pose_strike_state_names(state.get("events", []), "hook", "right"), ["not_ready"])
	assert_eq(String(state.get("gesture_debug", {}).get("hook", {}).get("right", {}).get("state", "")), "not_ready")

	state = substrate.process_landmarks(_make_pose_frame({
		PoseLandmarkIds.RIGHT_ELBOW: {"x": 0.65, "y": 0.60},
		PoseLandmarkIds.RIGHT_WRIST: {"x": 0.76, "y": 0.58},
	}), 1828)
	assert_eq(_pose_strike_state_names(state.get("events", []), "hook", "right"), ["ready"])
	assert_eq(String(state.get("gesture_debug", {}).get("hook", {}).get("right", {}).get("state", "")), "ready")

func test_uppercut_uses_pose_primary_state_machine_and_tracking_loss_truth() -> void:
	_calibrate_stance()
	var state := substrate.process_landmarks(_make_pose_frame(), 2000)
	assert_true(["tracking_lost", "ready"].has(String(state.get("gesture_debug", {}).get("uppercut", {}).get("left", {}).get("state", ""))))

	state = substrate.process_landmarks(_make_pose_frame(), 2160)
	assert_eq(String(state.get("gesture_debug", {}).get("uppercut", {}).get("left", {}).get("state", "")), "ready")

	state = substrate.process_landmarks(_make_pose_frame({
		PoseLandmarkIds.LEFT_ELBOW: {"x": 0.34, "y": 0.62},
		PoseLandmarkIds.LEFT_WRIST: {"x": 0.33, "y": 0.76},
	}), 2320)
	assert_true(_event_names(state.get("events", [])).has("uppercut_left"))
	assert_eq(_pose_strike_state_names(state.get("events", []), "uppercut", "left"), ["triggered"])
	var left_debug: Dictionary = state.get("gesture_debug", {}).get("uppercut", {}).get("left", {})
	assert_eq(String(left_debug.get("state", "")), "triggered")
	assert_eq(int(left_debug.get("window_ms", 0)), 160)
	assert_true(float(left_debug.get("upward_velocity", 0.0)) >= float(left_debug.get("min_velocity", 1.0)))
	assert_true(float(left_debug.get("dominance_ratio", 0.0)) >= float(left_debug.get("min_vertical_dominance_ratio", 99.0)))
	assert_true(float(left_debug.get("directionality_ratio", 0.0)) >= float(left_debug.get("min_upward_direction_ratio", 99.0)))
	assert_eq(String(left_debug.get("required_direction_label", "")), "upward")
	assert_eq(String(left_debug.get("velocity_signal_source", "")), "elbow_plus_wrist")
	assert_eq(String(left_debug.get("sample_source", "")), "pose")

	state = substrate.process_landmarks(_make_pose_frame({
		PoseLandmarkIds.LEFT_ELBOW: {"v": 0.2},
		PoseLandmarkIds.LEFT_WRIST: {"v": 0.2},
	}), 2400)
	assert_eq(_pose_strike_state_names(state.get("events", []), "uppercut", "left"), ["tracking_lost"])
	left_debug = state.get("gesture_debug", {}).get("uppercut", {}).get("left", {})
	assert_eq(String(left_debug.get("state", "")), "tracking_lost")
	assert_eq(String(left_debug.get("tracking_state", "")), "pose_missing")

func test_guard_no_longer_suppresses_hook_and_uppercut_state_machine_progress() -> void:
	_calibrate_stance()
	var guard_pose := _make_pose_frame({
		PoseLandmarkIds.LEFT_ELBOW: {"x": 0.42, "y": 0.69},
		PoseLandmarkIds.RIGHT_ELBOW: {"x": 0.58, "y": 0.69},
		PoseLandmarkIds.LEFT_WRIST: {"x": 0.41, "y": 0.80},
		PoseLandmarkIds.RIGHT_WRIST: {"x": 0.59, "y": 0.80},
	})
	var state := substrate.process_landmarks(guard_pose, 1000)
	assert_true(_event_names(state.get("events", [])).has("guard_start"))
	assert_true(bool(state.get("gesture_states", {}).get("guard", false)))
	assert_eq(String(state.get("gesture_debug", {}).get("hook", {}).get("right", {}).get("state", "")), "tracking_lost")
	assert_true(["tracking_lost", "ready"].has(String(state.get("gesture_debug", {}).get("uppercut", {}).get("left", {}).get("state", ""))))

	state = substrate.process_landmarks(guard_pose, 1160)
	assert_true(bool(state.get("gesture_states", {}).get("guard", false)))
	assert_eq(_pose_strike_state_names(state.get("events", []), "hook", "right"), ["ready"])
	assert_eq(String(state.get("gesture_debug", {}).get("hook", {}).get("right", {}).get("state", "")), "ready")
	assert_eq(_pose_strike_state_names(state.get("events", []), "uppercut", "left"), ["ready"])
	assert_eq(String(state.get("gesture_debug", {}).get("uppercut", {}).get("left", {}).get("state", "")), "ready")

func test_replay_timestamp_rewind_resets_straight_punch_temporal_windows() -> void:
	_calibrate_stance()
	var state := substrate.process_landmarks(_make_pose_frame(), 1100, _make_tracking_frame(_tracked_hand_payload_physical("left", 0.020, "tracked", true, 0, 10, 1.10, null, "", 0), _tracked_hand_payload_physical("right", 0.020)))
	state = substrate.process_landmarks(_make_pose_frame({PoseLandmarkIds.LEFT_WRIST: {"z": -0.04}}), 1180, _make_tracking_frame(_tracked_hand_payload_physical("left", 0.021, "tracked", true, 0, 11, 1.18, null, "", 80), _tracked_hand_payload_physical("right", 0.020)))
	state = substrate.process_landmarks(_make_pose_frame({PoseLandmarkIds.LEFT_WRIST: {"z": -0.12}}), 1260, _make_tracking_frame(_tracked_hand_payload_physical("left", 0.023, "tracked", true, 0, 12, 1.26), _tracked_hand_payload_physical("right", 0.020)))
	state = substrate.process_landmarks(_make_pose_frame({PoseLandmarkIds.LEFT_WRIST: {"z": -0.20}}), 1340, _make_tracking_frame(_tracked_hand_payload_physical("left", 0.0272, "tracked", true, 0, 13, 1.34), _tracked_hand_payload_physical("right", 0.020)))
	assert_true(_event_names(state.get("events", [])).has("punch_left"))

	state = substrate.process_landmarks(_make_pose_frame(), 40, _make_tracking_frame(_tracked_hand_payload_physical("left", 0.020, "tracked", true, 0, 1, 0.04, null, "", 0), _tracked_hand_payload_physical("right", 0.020)))
	assert_false(_event_names(state.get("events", [])).has("punch_left"))
	var left_debug: Dictionary = state.get("gesture_debug", {}).get("straight_punch", {}).get("left", {})
	assert_eq(String(left_debug.get("state", "")), "tracking_lost")
	assert_eq(int(left_debug.get("wrist_velocity_window_span_ms", -1)), 0)
	assert_eq(int(left_debug.get("bbox_area_growth_window_span_ms", -1)), 0)
	assert_eq(left_debug.get("growth_window_areas", []), [0.02])

func test_replay_timestamp_rewind_resets_pose_strike_temporal_windows() -> void:
	_calibrate_stance()
	var state := substrate.process_landmarks(_make_pose_frame(), 1000)
	state = substrate.process_landmarks(_make_pose_frame(), 1160)
	state = substrate.process_landmarks(_make_pose_frame({
		PoseLandmarkIds.RIGHT_ELBOW: {"x": 0.55, "y": 0.62},
		PoseLandmarkIds.RIGHT_WRIST: {"x": 0.46, "y": 0.60},
	}), 1320)
	assert_true(_event_names(state.get("events", [])).has("hook_right"))

	state = substrate.process_landmarks(_make_pose_frame(), 40)
	assert_false(_event_names(state.get("events", [])).has("hook_right"))
	var right_debug: Dictionary = state.get("gesture_debug", {}).get("hook", {}).get("right", {})
	assert_eq(String(right_debug.get("state", "")), "tracking_lost")
	assert_eq(int(right_debug.get("window_span_ms", -1)), 0)
	assert_true(is_equal_approx(float(right_debug.get("wrist_velocity", -1.0)), 0.0))

func test_hook_requires_signed_horizontal_direction_for_side() -> void:
	_calibrate_stance()
	var state := substrate.process_landmarks(_make_pose_frame(), 1000)
	state = substrate.process_landmarks(_make_pose_frame(), 1160)
	assert_eq(String(state.get("gesture_debug", {}).get("hook", {}).get("left", {}).get("state", "")), "ready")

	state = substrate.process_landmarks(_make_pose_frame({
		PoseLandmarkIds.LEFT_ELBOW: {"x": 0.20, "y": 0.62},
		PoseLandmarkIds.LEFT_WRIST: {"x": 0.08, "y": 0.60},
	}), 1320)
	assert_false(_event_names(state.get("events", [])).has("hook_left"))
	var left_debug: Dictionary = state.get("gesture_debug", {}).get("hook", {}).get("left", {})
	assert_true(float(left_debug.get("dominance_ratio", 0.0)) >= float(left_debug.get("min_lateral_dominance_ratio", 99.0)))
	assert_true(float(left_debug.get("directionality_ratio", 1.0)) < float(left_debug.get("min_horizontal_direction_ratio", 0.0)))
	assert_eq(String(left_debug.get("state", "")), "ready")

func test_uppercut_requires_upward_signed_vertical_direction() -> void:
	_calibrate_stance()
	var state := substrate.process_landmarks(_make_pose_frame(), 2000)
	state = substrate.process_landmarks(_make_pose_frame(), 2160)
	assert_eq(String(state.get("gesture_debug", {}).get("uppercut", {}).get("left", {}).get("state", "")), "ready")

	state = substrate.process_landmarks(_make_pose_frame({
		PoseLandmarkIds.LEFT_ELBOW: {"x": 0.34, "y": 0.54},
		PoseLandmarkIds.LEFT_WRIST: {"x": 0.33, "y": 0.48},
	}), 2320)
	assert_false(_event_names(state.get("events", [])).has("uppercut_left"))
	var left_debug: Dictionary = state.get("gesture_debug", {}).get("uppercut", {}).get("left", {})
	assert_true(float(left_debug.get("dominance_ratio", 0.0)) >= float(left_debug.get("min_vertical_dominance_ratio", 99.0)))
	assert_true(float(left_debug.get("directionality_ratio", 1.0)) < float(left_debug.get("min_upward_direction_ratio", 0.0)))
	assert_eq(String(left_debug.get("state", "")), "ready")

func test_hook_directionality_ratio_uses_total_motion_share() -> void:
	_calibrate_stance()
	var state := substrate.process_landmarks(_make_pose_frame(), 3000)
	state = substrate.process_landmarks(_make_pose_frame(), 3160)
	assert_eq(String(state.get("gesture_debug", {}).get("hook", {}).get("left", {}).get("state", "")), "ready")

	state = substrate.process_landmarks(_make_pose_frame({
		PoseLandmarkIds.LEFT_ELBOW: {"x": 0.43, "y": 0.70},
		PoseLandmarkIds.LEFT_WRIST: {"x": 0.39, "y": 0.64},
	}), 3320)
	assert_true(_event_names(state.get("events", [])).has("hook_left"))
	var left_debug: Dictionary = state.get("gesture_debug", {}).get("hook", {}).get("left", {})
	assert_true(float(left_debug.get("directionality_ratio", 0.0)) >= float(left_debug.get("min_horizontal_direction_ratio", 99.0)))
	assert_true(float(left_debug.get("directionality_ratio", 0.0)) < 0.99)
	assert_true(float(left_debug.get("dominance_ratio", 0.0)) >= float(left_debug.get("min_lateral_dominance_ratio", 99.0)))

func test_uppercut_directionality_ratio_uses_total_motion_share() -> void:
	_calibrate_stance()
	var state := substrate.process_landmarks(_make_pose_frame(), 4000)
	state = substrate.process_landmarks(_make_pose_frame(), 4160)
	assert_eq(String(state.get("gesture_debug", {}).get("uppercut", {}).get("left", {}).get("state", "")), "ready")

	state = substrate.process_landmarks(_make_pose_frame({
		PoseLandmarkIds.LEFT_ELBOW: {"x": 0.38, "y": 0.74},
		PoseLandmarkIds.LEFT_WRIST: {"x": 0.33, "y": 0.72},
	}), 4320)
	assert_true(_event_names(state.get("events", [])).has("uppercut_left"))
	var left_debug: Dictionary = state.get("gesture_debug", {}).get("uppercut", {}).get("left", {})
	assert_true(float(left_debug.get("directionality_ratio", 0.0)) >= float(left_debug.get("min_upward_direction_ratio", 99.0)))
	assert_true(float(left_debug.get("directionality_ratio", 0.0)) < 0.99)
	assert_true(float(left_debug.get("dominance_ratio", 0.0)) >= float(left_debug.get("min_vertical_dominance_ratio", 99.0)))

func test_hook_windowed_dominance_ratio_counts_vertical_motion_across_the_whole_window() -> void:
	config.gesture_profile_document = {
		"hook": {
			"enabled": true,
			"evaluation": {
				"window_ms": 160,
			},
			"thresholds": {
				"min_velocity": 0.6,
				"min_lateral_dominance_ratio": 1.1,
				"min_horizontal_direction_ratio": 0.7,
			},
		},
	}
	substrate = PoseDetectorSubstrate.new().configure(config)
	_calibrate_stance()
	var state := substrate.process_landmarks(_make_pose_frame(), 1000)
	state = substrate.process_landmarks(_make_pose_frame(), 1160)
	assert_eq(String(state.get("gesture_debug", {}).get("hook", {}).get("left", {}).get("state", "")), "ready")

	state = substrate.process_landmarks(_make_pose_frame({
		PoseLandmarkIds.LEFT_ELBOW: {"x": 0.42, "y": 0.74},
		PoseLandmarkIds.LEFT_WRIST: {"x": 0.36, "y": 0.68},
	}), 1240)
	state = substrate.process_landmarks(_make_pose_frame({
		PoseLandmarkIds.LEFT_ELBOW: {"x": 0.50, "y": 0.66},
		PoseLandmarkIds.LEFT_WRIST: {"x": 0.44, "y": 0.60},
	}), 1320)
	assert_false(_event_names(state.get("events", [])).has("hook_left"))
	var left_debug: Dictionary = state.get("gesture_debug", {}).get("hook", {}).get("left", {})
	assert_eq(int(left_debug.get("window_ms", 0)), 160)
	assert_eq(int(left_debug.get("window_span_ms", 0)), 160)
	assert_true(is_equal_approx(float(left_debug.get("wrist_velocity", 0.0)), 1.0))
	assert_true(is_equal_approx(float(left_debug.get("dominance_ratio", 0.0)), 1.0))
	assert_true(float(left_debug.get("dominance_ratio", 0.0)) < float(left_debug.get("min_lateral_dominance_ratio", 0.0)))
	assert_true(is_equal_approx(float(left_debug.get("directionality_ratio", 0.0)), 0.7071067811865475))

func test_uppercut_windowed_direction_ratio_counts_downward_motion_across_the_whole_window() -> void:
	config.gesture_profile_document = {
		"uppercut": {
			"enabled": true,
			"evaluation": {
				"window_ms": 160,
			},
			"thresholds": {
				"min_velocity": 0.5,
				"min_vertical_dominance_ratio": 1.0,
				"min_upward_direction_ratio": 0.9,
			},
		},
	}
	substrate = PoseDetectorSubstrate.new().configure(config)
	_calibrate_stance()
	var state := substrate.process_landmarks(_make_pose_frame(), 2000)
	state = substrate.process_landmarks(_make_pose_frame(), 2160)
	assert_eq(String(state.get("gesture_debug", {}).get("uppercut", {}).get("left", {}).get("state", "")), "ready")

	state = substrate.process_landmarks(_make_pose_frame({
		PoseLandmarkIds.LEFT_ELBOW: {"x": 0.34, "y": 0.78},
		PoseLandmarkIds.LEFT_WRIST: {"x": 0.28, "y": 0.72},
	}), 2240)
	state = substrate.process_landmarks(_make_pose_frame({
		PoseLandmarkIds.LEFT_ELBOW: {"x": 0.34, "y": 0.74},
		PoseLandmarkIds.LEFT_WRIST: {"x": 0.28, "y": 0.68},
	}), 2320)
	assert_false(_event_names(state.get("events", [])).has("uppercut_left"))
	var left_debug: Dictionary = state.get("gesture_debug", {}).get("uppercut", {}).get("left", {})
	assert_eq(int(left_debug.get("window_ms", 0)), 160)
	assert_eq(int(left_debug.get("window_span_ms", 0)), 160)
	assert_true(is_equal_approx(float(left_debug.get("wrist_velocity", 0.0)), 0.5))
	assert_true(is_equal_approx(float(left_debug.get("directionality_ratio", 0.0)), 0.75))
	assert_true(float(left_debug.get("directionality_ratio", 0.0)) < float(left_debug.get("min_upward_direction_ratio", 0.0)))

func test_pose_strike_window_ms_no_longer_falls_back_to_legacy_wrist_velocity_window_ms() -> void:
	config.gesture_profile_document = {
		"hook": {
			"enabled": true,
			"evaluation": {
				"wrist_velocity_window_ms": 160,
			},
		},
		"uppercut": {
			"enabled": true,
			"evaluation": {
				"wrist_velocity_window_ms": 120,
			},
		},
	}
	substrate = PoseDetectorSubstrate.new().configure(config)

	var hook_config := substrate._get_hook_config()
	var uppercut_config := substrate._get_uppercut_config()
	assert_eq(int(hook_config.get("window_ms", 0)), 160)
	assert_eq(int(uppercut_config.get("window_ms", 0)), 160)

func test_quantizes_flow_direction_to_twelve_chart_slots() -> void:
	assert_eq(substrate._flow_ring_index_from_vector(Vector2(1.0, 0.0)), 2)
	assert_eq(substrate._flow_ring_index_from_vector(Vector2(0.0, 1.0)), 11)
	assert_eq(substrate._flow_ring_index_from_vector(Vector2(-1.0, 0.0)), 8)
	assert_eq(substrate._flow_ring_index_from_vector(Vector2(0.0, -1.0)), 5)

func test_quantizes_flow_placement_to_twelve_perimeter_slots_plus_center() -> void:
	assert_eq(substrate._flow_placement_index(Vector2(0.52, 0.69), Vector2(0.50, 0.70), 0.20), 12)
	assert_eq(substrate._flow_placement_index(Vector2(0.72, 0.70), Vector2(0.50, 0.70), 0.20), 2)
	assert_eq(substrate._flow_placement_index(Vector2(0.50, 0.92), Vector2(0.50, 0.70), 0.20), 11)

func test_detects_flow_swing_events_with_distinct_placement_and_direction() -> void:
	_calibrate_stance()
	substrate.process_landmarks(_make_pose_frame(), 1100)
	substrate.process_landmarks(_make_pose_frame({
		PoseLandmarkIds.LEFT_ELBOW: {"x": 0.28, "y": 0.66},
		PoseLandmarkIds.LEFT_WRIST: {"x": 0.18, "y": 0.62},
	}), 1180)
	var swing_state := substrate.process_landmarks(_make_pose_frame({
		PoseLandmarkIds.LEFT_ELBOW: {"x": 0.21, "y": 0.70},
		PoseLandmarkIds.LEFT_WRIST: {"x": 0.08, "y": 0.70},
	}), 1260)
	var flow_events := _flow_events(swing_state.get("events", []))
	assert_eq(flow_events.size(), 1)
	assert_eq(flow_events[0]["name"], "swing_left")
	assert_eq(flow_events[0]["placement"], 8)
	assert_eq(flow_events[0]["direction"], 9)

func test_exposes_flow_debug_candidates_and_last_emit_metadata() -> void:
	_calibrate_stance()
	substrate.process_landmarks(_make_pose_frame(), 1100)
	substrate.process_landmarks(_make_pose_frame({
		PoseLandmarkIds.LEFT_ELBOW: {"x": 0.28, "y": 0.66},
		PoseLandmarkIds.LEFT_WRIST: {"x": 0.18, "y": 0.62},
	}), 1180)
	var swing_state := substrate.process_landmarks(_make_pose_frame({
		PoseLandmarkIds.LEFT_ELBOW: {"x": 0.21, "y": 0.70},
		PoseLandmarkIds.LEFT_WRIST: {"x": 0.08, "y": 0.70},
	}), 1260)
	var gesture_debug: Dictionary = swing_state.get("gesture_debug", {})
	var flow_debug: Dictionary = gesture_debug.get("flow", {})
	var left_flow: Dictionary = flow_debug.get("left", {})
	var swing_meta: Dictionary = left_flow.get("swing_meta", {})
	var swing_analysis: Dictionary = left_flow.get("swing_analysis", {})
	assert_false(bool(gesture_debug.get("ready", {}).get("swing_left", true)))
	assert_eq(int(left_flow.get("placement_candidate", -1)), 8)
	assert_eq(int(left_flow.get("placement_candidate_ui_label", 0)), 9)
	assert_eq(int(left_flow.get("direction_candidate", -1)), 9)
	assert_eq(int(left_flow.get("direction_candidate_ui_label", 0)), 10)
	assert_true(int(left_flow.get("history_points", 0)) >= 3)
	assert_eq(int(swing_meta.get("placement", -1)), 8)
	assert_eq(int(swing_meta.get("placement_ui_label", 0)), 9)
	assert_eq(int(swing_meta.get("direction", -1)), 9)
	assert_eq(int(swing_meta.get("direction_ui_label", 0)), 10)
	assert_true(int(swing_meta.get("duration_ms", 0)) >= 120)
	assert_true(float(swing_analysis.get("arc_length", 0.0)) > 0.0)
	assert_true(float(swing_analysis.get("avg_confidence", 0.0)) >= 0.62)

func test_detects_flow_trail_as_continuation_motion() -> void:
	_calibrate_stance()
	substrate.process_landmarks(_make_pose_frame(), 2000)
	var timestamps := [2100, 2200, 2300, 2400]
	var wrist_positions := [
		{"x": 0.72, "y": 0.60},
		{"x": 0.72, "y": 0.70},
		{"x": 0.72, "y": 0.80},
		{"x": 0.72, "y": 0.90},
	]
	var emitted_events: Array = []
	for idx in range(timestamps.size()):
		var state := substrate.process_landmarks(_make_pose_frame({
			PoseLandmarkIds.RIGHT_ELBOW: {"x": 0.66, "y": wrist_positions[idx]["y"] - 0.04},
			PoseLandmarkIds.RIGHT_WRIST: wrist_positions[idx],
		}), timestamps[idx])
		emitted_events.append_array(_flow_events(state.get("events", [])))
	assert_true(bool(substrate.get_latest_state().get("gesture_states", {}).get("trail_right", false)))
	assert_true(emitted_events.size() >= 2)
	assert_eq(emitted_events[0]["name"], "trail_right")
	assert_eq(emitted_events[0]["placement"], 2)
	assert_eq(emitted_events[0]["direction"], 11)
	assert_eq(emitted_events[emitted_events.size() - 1]["name"], "trail_right")

func test_squat_uses_yaml_thresholds_and_surfaces_debug_truth() -> void:
	config.gesture_profile_document = {
		"squat": {
			"enabled": true,
			"thresholds": {
				"enter_height_ratio_max": 0.85,
				"exit_height_ratio_min": 0.95,
			}
		}
	}
	substrate = PoseDetectorSubstrate.new().configure(config)
	_calibrate_stance()

	var squat_start_state := substrate.process_landmarks(_make_pose_frame({}, 0.50, 0.84), 1200)
	assert_true(_event_names(squat_start_state.get("events", [])).has("squat_start"))
	var squat_debug: Dictionary = squat_start_state.get("gesture_debug", {}).get("squat", {})
	assert_true(bool(squat_debug.get("state", false)))
	assert_true(is_equal_approx(float(squat_debug.get("enter_height_ratio_max", 0.0)), 0.85))
	assert_true(is_equal_approx(float(squat_debug.get("exit_height_ratio_min", 0.0)), 0.95))
	assert_true(is_equal_approx(float(squat_debug.get("height_ratio", 0.0)), 0.84))
	assert_true(is_equal_approx(float(squat_debug.get("squat_depth", 0.0)), 0.16))
	assert_eq(String(squat_debug.get("height_state", "")), "transition")
	assert_true(bool(squat_debug.get("calibration_ready", false)))
	assert_eq(int(squat_debug.get("calibration_sample_frames", 0)), 5)

	var still_active_state := substrate.process_landmarks(_make_pose_frame({}, 0.50, 0.90), 1300)
	assert_eq(_event_names(still_active_state.get("events", [])), [])
	assert_true(bool(still_active_state.get("gesture_states", {}).get("squat", false)))

	var squat_end_state := substrate.process_landmarks(_make_pose_frame({}, 0.50, 0.96), 1400)
	assert_eq(_event_names(squat_end_state.get("events", [])), ["squat_end"])

func test_request_athlete_recalibration_clears_baseline_and_squat_truth_until_recalibrated() -> void:
	_calibrate_stance()
	var squat_start_state := substrate.process_landmarks(_make_pose_frame({}, 0.50, 0.78), 1200)
	assert_true(_event_names(squat_start_state.get("events", [])).has("squat_start"))
	substrate.request_athlete_recalibration()
	var recalibrated_state := substrate.get_latest_state()
	var baseline: Dictionary = recalibrated_state.get("baseline", {})
	var squat_debug: Dictionary = recalibrated_state.get("gesture_debug", {}).get("squat", {})
	assert_false(bool(baseline.get("is_calibrated", false)))
	assert_eq(int(baseline.get("sample_frames", -1)), 0)
	assert_false(bool(recalibrated_state.get("gesture_states", {}).get("squat", true)))
	assert_false(bool(squat_debug.get("calibration_ready", true)))
	assert_eq(int(squat_debug.get("calibration_sample_frames", -1)), 0)
	assert_eq(String(squat_debug.get("height_state", "")), "unknown")
	assert_true(is_equal_approx(float(squat_debug.get("squat_depth", -1.0)), 0.0))

func test_weave_uses_yaml_thresholds_and_surfaces_debug_truth() -> void:
	config.gesture_profile_document = {
		"weave": {
			"enabled": true,
			"thresholds": {
				"enter_head_lateral_offset_min": 0.28,
				"enter_relative_head_hip_offset_min": 0.10,
				"enter_head_drop_ratio_min": 0.04,
				"exit_head_lateral_offset_max": 0.10,
				"exit_relative_head_hip_offset_max": 0.06,
			}
		}
	}
	substrate = PoseDetectorSubstrate.new().configure(config)
	_calibrate_stance()

	var weave_left_state := substrate.process_landmarks(_make_pose_frame({
		PoseLandmarkIds.NOSE: {"x": 0.58, "y": 0.84},
		PoseLandmarkIds.LEFT_HIP: {"x": 0.42, "y": 0.46},
		PoseLandmarkIds.RIGHT_HIP: {"x": 0.58, "y": 0.46},
	}), 1200)
	assert_true(_event_names(weave_left_state.get("events", [])).has("weave_left_start"))
	var weave_debug: Dictionary = weave_left_state.get("gesture_debug", {}).get("weave", {})
	assert_eq(String(weave_debug.get("state", "")), "left")
	assert_true(is_equal_approx(float(weave_debug.get("enter_head_lateral_offset_min", 0.0)), 0.28))
	assert_true(is_equal_approx(float(weave_debug.get("enter_relative_head_hip_offset_min", 0.0)), 0.10))
	assert_true(is_equal_approx(float(weave_debug.get("enter_head_drop_ratio_min", 0.0)), 0.04))
	assert_true(is_equal_approx(float(weave_debug.get("exit_head_lateral_offset_max", 0.0)), 0.10))
	assert_true(is_equal_approx(float(weave_debug.get("exit_relative_head_hip_offset_max", 0.0)), 0.06))
	assert_true(float(weave_debug.get("head_lateral_offset", 0.0)) > 0.0)
	assert_true(absf(float(weave_debug.get("hip_lateral_offset", 0.0))) < float(weave_debug.get("enter_head_lateral_offset_min", 0.0)))
	assert_true(float(weave_debug.get("relative_head_hip_offset", 0.0)) > 0.0)
	assert_true(float(weave_debug.get("head_drop_ratio", 0.0)) >= float(weave_debug.get("enter_head_drop_ratio_min", 0.0)))
	assert_true(bool(weave_debug.get("left_candidate", false)))
	assert_false(bool(weave_debug.get("right_candidate", true)))
	assert_false(bool(weave_debug.get("neutral_candidate", true)))
	assert_true(bool(weave_debug.get("head_offset_left_ready", false)))
	assert_true(bool(weave_debug.get("relative_offset_left_ready", false)))
	assert_true(bool(weave_debug.get("head_drop_ready", false)))

	var weave_end_state := substrate.process_landmarks(_make_pose_frame({
		PoseLandmarkIds.NOSE: {"x": 0.49, "y": 0.80},
	}), 1300)
	assert_true(_event_names(weave_end_state.get("events", [])).has("weave_left_end"))
	weave_debug = weave_end_state.get("gesture_debug", {}).get("weave", {})
	assert_eq(String(weave_debug.get("state", "")), "inactive")
	assert_true(bool(weave_debug.get("neutral_candidate", false)))

func test_detects_guard_squat_weave_and_sidestep_state_events() -> void:
	_calibrate_stance()
	var guard_start_state := substrate.process_landmarks(_make_pose_frame({
		PoseLandmarkIds.LEFT_ELBOW: {"x": 0.42, "y": 0.69},
		PoseLandmarkIds.RIGHT_ELBOW: {"x": 0.58, "y": 0.69},
		PoseLandmarkIds.LEFT_WRIST: {"x": 0.41, "y": 0.80},
		PoseLandmarkIds.RIGHT_WRIST: {"x": 0.59, "y": 0.80},
	}), 1200)
	assert_true(_event_names(guard_start_state.get("events", [])).has("guard_start"))
	var guard_debug: Dictionary = guard_start_state.get("gesture_debug", {}).get("guard", {})
	assert_true(bool(guard_debug.get("candidate", false)))
	assert_true(bool(guard_debug.get("wrists_close_x", false)))
	assert_true(bool(guard_debug.get("wrists_close_y", false)))
	assert_true(bool(guard_debug.get("left_wrist_above_elbow", false)))
	assert_true(bool(guard_debug.get("right_wrist_above_elbow", false)))
	assert_true(bool(guard_debug.get("left_wrist_near_nose", false)))
	assert_true(bool(guard_debug.get("right_wrist_near_nose", false)))
	assert_true(is_equal_approx(float(guard_debug.get("max_wrist_separation_x", 0.0)), 0.20))
	assert_true(is_equal_approx(float(guard_debug.get("max_wrist_separation_y", 0.0)), 0.12))
	assert_true(is_equal_approx(float(guard_debug.get("max_wrist_nose_distance", 0.0)), 0.15))
	assert_true(float(guard_debug.get("left_wrist_nose_distance", 0.0)) <= float(guard_debug.get("max_wrist_nose_distance", 0.0)))
	assert_true(float(guard_debug.get("right_wrist_nose_distance", 0.0)) <= float(guard_debug.get("max_wrist_nose_distance", 0.0)))
	var guard_end_state := substrate.process_landmarks(_make_pose_frame(), 1300)
	assert_true(_event_names(guard_end_state.get("events", [])).has("guard_end"))

	var squat_start_state := substrate.process_landmarks(_make_pose_frame({}, 0.50, 0.78), 1400)
	assert_eq(_event_names(squat_start_state.get("events", [])), ["squat_start"])
	var squat_end_state := substrate.process_landmarks(_make_pose_frame(), 1500)
	assert_eq(_event_names(squat_end_state.get("events", [])), ["squat_end"])

	var weave_left_state := substrate.process_landmarks(_make_pose_frame({
		PoseLandmarkIds.NOSE: {"x": 0.57, "y": 0.85},
	}), 1600)
	assert_eq(_event_names(weave_left_state.get("events", [])), ["weave_left_start"])
	var weave_end_state := substrate.process_landmarks(_make_pose_frame(), 1700)
	assert_eq(_event_names(weave_end_state.get("events", [])), ["weave_left_end"])

	var sidestep_right_state := substrate.process_landmarks(_make_pose_frame({}, 0.60, 1.0), 1800)
	assert_true(_event_names(sidestep_right_state.get("events", [])).has("sidestep_right_start"))
	var sidestep_end_state := substrate.process_landmarks(_make_pose_frame(), 1900)
	assert_true(_event_names(sidestep_end_state.get("events", [])).has("sidestep_right_end"))

func test_guard_no_longer_uses_old_elbow_shoulder_head_composite_rule() -> void:
	_calibrate_stance()
	var old_rule_like_pose := substrate.process_landmarks(_make_pose_frame({
		PoseLandmarkIds.LEFT_ELBOW: {"x": 0.36, "y": 0.69},
		PoseLandmarkIds.RIGHT_ELBOW: {"x": 0.64, "y": 0.69},
		PoseLandmarkIds.LEFT_WRIST: {"x": 0.36, "y": 0.80},
		PoseLandmarkIds.RIGHT_WRIST: {"x": 0.64, "y": 0.80},
	}), 1200)
	assert_false(_event_names(old_rule_like_pose.get("events", [])).has("guard_start"))
	var guard_debug: Dictionary = old_rule_like_pose.get("gesture_debug", {}).get("guard", {})
	assert_false(bool(old_rule_like_pose.get("gesture_states", {}).get("guard", false)))
	assert_false(bool(guard_debug.get("candidate", true)))
	assert_false(bool(guard_debug.get("wrists_close_x", true)))
	assert_true(bool(guard_debug.get("left_wrist_above_elbow", false)))
	assert_true(bool(guard_debug.get("right_wrist_above_elbow", false)))

func test_guard_requires_both_wrists_to_stay_near_nose() -> void:
	_calibrate_stance()
	var guard_without_nose_proximity := substrate.process_landmarks(_make_pose_frame({
		PoseLandmarkIds.LEFT_ELBOW: {"x": 0.42, "y": 0.69},
		PoseLandmarkIds.RIGHT_ELBOW: {"x": 0.58, "y": 0.69},
		PoseLandmarkIds.LEFT_WRIST: {"x": 0.36, "y": 0.80},
		PoseLandmarkIds.RIGHT_WRIST: {"x": 0.54, "y": 0.80},
	}), 1200)
	assert_false(_event_names(guard_without_nose_proximity.get("events", [])).has("guard_start"))
	var guard_debug: Dictionary = guard_without_nose_proximity.get("gesture_debug", {}).get("guard", {})
	assert_true(bool(guard_debug.get("wrists_close_x", false)))
	assert_true(bool(guard_debug.get("wrists_close_y", false)))
	assert_true(bool(guard_debug.get("left_wrist_above_elbow", false)))
	assert_true(bool(guard_debug.get("right_wrist_above_elbow", false)))
	assert_false(bool(guard_debug.get("left_wrist_near_nose", true)))
	assert_true(bool(guard_debug.get("right_wrist_near_nose", false)))
	assert_false(bool(guard_debug.get("candidate", true)))
	assert_true(float(guard_debug.get("left_wrist_nose_distance", 0.0)) > float(guard_debug.get("max_wrist_nose_distance", 0.0)))

func test_weave_remains_active_only_while_live_weave_criteria_still_pass() -> void:
	_calibrate_stance()
	var weave_left_start_state := substrate.process_landmarks(_make_pose_frame({
		PoseLandmarkIds.NOSE: {"x": 0.57, "y": 0.85},
	}), 1200)
	assert_true(_event_names(weave_left_start_state.get("events", [])).has("weave_left_start"))
	var held_weave_state := substrate.process_landmarks(_make_pose_frame({
		PoseLandmarkIds.NOSE: {"x": 0.58, "y": 0.86},
	}), 1300)
	assert_false(_event_names(held_weave_state.get("events", [])).has("weave_left_start"))
	assert_false(_event_names(held_weave_state.get("events", [])).has("weave_left_end"))
	var held_weave_debug: Dictionary = held_weave_state.get("gesture_debug", {}).get("weave", {})
	assert_eq(String(held_weave_debug.get("state", "")), "left")
	assert_true(bool(held_weave_debug.get("left_candidate", false)))
	var weave_end_state := substrate.process_landmarks(_make_pose_frame({
		PoseLandmarkIds.NOSE: {"x": 0.53, "y": 0.80},
	}), 1400)
	assert_true(_event_names(weave_end_state.get("events", [])).has("weave_left_end"))

func test_detects_knee_and_leg_lift_events_with_reset_behavior() -> void:
	_calibrate_stance()
	var knee_state := substrate.process_landmarks(_make_pose_frame({
		PoseLandmarkIds.LEFT_KNEE: {"x": 0.44, "y": 0.34},
		PoseLandmarkIds.LEFT_ANKLE: {"x": 0.46, "y": 0.18},
	}), 1200)
	assert_true(_event_names(knee_state.get("events", [])).has("knee_left"))
	var no_refire_state := substrate.process_landmarks(_make_pose_frame({
		PoseLandmarkIds.LEFT_KNEE: {"x": 0.44, "y": 0.35},
		PoseLandmarkIds.LEFT_ANKLE: {"x": 0.46, "y": 0.19},
	}), 1300)
	assert_eq(_event_names(no_refire_state.get("events", [])), [])
	var knee_reset_state := substrate.process_landmarks(_make_pose_frame(), 1400)
	assert_eq(_event_names(knee_reset_state.get("events", [])), [])
	var knee_refire_state := substrate.process_landmarks(_make_pose_frame({
		PoseLandmarkIds.LEFT_KNEE: {"x": 0.44, "y": 0.34},
		PoseLandmarkIds.LEFT_ANKLE: {"x": 0.46, "y": 0.18},
	}), 1500)
	assert_eq(_event_names(knee_refire_state.get("events", [])), ["knee_left"])

	var leg_lift_start_state := substrate.process_landmarks(_make_pose_frame({
		PoseLandmarkIds.RIGHT_ANKLE: {"x": 0.73, "y": 0.20},
	}), 1600)
	assert_eq(_event_names(leg_lift_start_state.get("events", [])), ["leg_lift_right_start"])
	var leg_lift_end_state := substrate.process_landmarks(_make_pose_frame(), 1700)
	assert_eq(_event_names(leg_lift_end_state.get("events", [])), ["leg_lift_right_end"])

func test_prototype_matcher_backend_emits_side_aware_straight_and_surfaces_debug_state() -> void:
	_enable_prototype_matcher_backend({
		"match_score_min": 0.70,
		"emit_cooldown_ms": 250,
		"emit_hold_ms": 100,
	})
	_calibrate_stance()
	var timestamps := [1100, 1165, 1230, 1295, 1350]
	var left_sequence := [
		{"elbow_x": 0.34, "elbow_y": 0.66, "wrist_x": 0.28, "wrist_y": 0.60, "elbow_z": 0.00, "wrist_z": 0.00},
		{"elbow_x": 0.336, "elbow_y": 0.66, "wrist_x": 0.276, "wrist_y": 0.60, "elbow_z": -0.02, "wrist_z": -0.05},
		{"elbow_x": 0.328, "elbow_y": 0.656, "wrist_x": 0.268, "wrist_y": 0.60, "elbow_z": -0.04, "wrist_z": -0.10},
		{"elbow_x": 0.316, "elbow_y": 0.65, "wrist_x": 0.260, "wrist_y": 0.60, "elbow_z": -0.06, "wrist_z": -0.15},
		{"elbow_x": 0.308, "elbow_y": 0.644, "wrist_x": 0.252, "wrist_y": 0.60, "elbow_z": -0.08, "wrist_z": -0.20},
	]
	var state: Dictionary = {}
	var saw_emit := false
	for idx in range(timestamps.size()):
		state = substrate.process_landmarks(_prototype_pose_frame("left", left_sequence[idx]), int(timestamps[idx]))
		saw_emit = saw_emit or _event_names(state.get("events", [])).has("punch_left")
	assert_true(saw_emit)
	var gesture_debug: Dictionary = state.get("gesture_debug", {})
	assert_eq(String(gesture_debug.get("punch_detection", {}).get("backend", "")), "prototype_matcher")
	var matcher_debug: Dictionary = gesture_debug.get("prototype_matcher", {})
	assert_eq(String(matcher_debug.get("result_class", "")), "straight_left")
	assert_true(["emitted", "emit_hold_active"].has(String(matcher_debug.get("reason", ""))))
	assert_eq(String(matcher_debug.get("library_id", "")), "boxing_side_aware_v1")
	assert_true(float(matcher_debug.get("best_score", 0.0)) >= 0.70)
	if String(matcher_debug.get("reason", "")) == "emitted":
		assert_eq(String(matcher_debug.get("emitted_event_name", "")), "punch_left")
		assert_true(bool(matcher_debug.get("emitted", false)))
	else:
		assert_eq(String(matcher_debug.get("active_event_class", "")), "straight_left")

func test_prototype_matcher_backend_rejects_no_punch_when_threshold_is_not_met() -> void:
	_enable_prototype_matcher_backend({
		"match_score_min": 0.99,
		"emit_cooldown_ms": 250,
		"emit_hold_ms": 100,
	})
	_calibrate_stance()
	var timestamps := [1100, 1165, 1230, 1295, 1350]
	var left_sequence := [
		{"elbow_x": 0.344, "elbow_y": 0.664, "wrist_x": 0.286, "wrist_y": 0.620, "elbow_z": 0.00, "wrist_z": 0.00},
		{"elbow_x": 0.340, "elbow_y": 0.664, "wrist_x": 0.282, "wrist_y": 0.622, "elbow_z": -0.01, "wrist_z": -0.03},
		{"elbow_x": 0.334, "elbow_y": 0.660, "wrist_x": 0.276, "wrist_y": 0.624, "elbow_z": -0.02, "wrist_z": -0.05},
		{"elbow_x": 0.326, "elbow_y": 0.656, "wrist_x": 0.270, "wrist_y": 0.626, "elbow_z": -0.03, "wrist_z": -0.07},
		{"elbow_x": 0.320, "elbow_y": 0.652, "wrist_x": 0.264, "wrist_y": 0.628, "elbow_z": -0.04, "wrist_z": -0.09},
	]
	var state: Dictionary = {}
	for idx in range(timestamps.size()):
		state = substrate.process_landmarks(_prototype_pose_frame("left", left_sequence[idx]), int(timestamps[idx]))
	assert_false(_event_names(state.get("events", [])).has("punch_left"))
	var matcher_debug: Dictionary = state.get("gesture_debug", {}).get("prototype_matcher", {})
	assert_eq(String(matcher_debug.get("result_class", "")), "no_punch")
	assert_eq(String(matcher_debug.get("reason", "")), "below_threshold")
	assert_eq(String(matcher_debug.get("best_class", "")), "straight_left")
	assert_true(float(matcher_debug.get("best_score", 0.0)) < 0.99)

func test_prototype_matcher_backend_applies_emit_cooldown_and_hold_without_spam() -> void:
	_enable_prototype_matcher_backend({
		"match_score_min": 0.70,
		"emit_cooldown_ms": 250,
		"emit_hold_ms": 100,
	})
	_calibrate_stance()
	var timestamps := [1100, 1165, 1230, 1295, 1350]
	var left_sequence := [
		{"elbow_x": 0.34, "elbow_y": 0.66, "wrist_x": 0.28, "wrist_y": 0.60, "elbow_z": 0.00, "wrist_z": 0.00},
		{"elbow_x": 0.336, "elbow_y": 0.66, "wrist_x": 0.276, "wrist_y": 0.60, "elbow_z": -0.02, "wrist_z": -0.05},
		{"elbow_x": 0.328, "elbow_y": 0.656, "wrist_x": 0.268, "wrist_y": 0.60, "elbow_z": -0.04, "wrist_z": -0.10},
		{"elbow_x": 0.316, "elbow_y": 0.65, "wrist_x": 0.260, "wrist_y": 0.60, "elbow_z": -0.06, "wrist_z": -0.15},
		{"elbow_x": 0.308, "elbow_y": 0.644, "wrist_x": 0.252, "wrist_y": 0.60, "elbow_z": -0.08, "wrist_z": -0.20},
	]
	var state: Dictionary = {}
	var saw_initial_emit := false
	for idx in range(timestamps.size()):
		state = substrate.process_landmarks(_prototype_pose_frame("left", left_sequence[idx]), int(timestamps[idx]))
		saw_initial_emit = saw_initial_emit or _event_names(state.get("events", [])).has("punch_left")
	assert_true(saw_initial_emit)
	state = substrate.process_landmarks(_prototype_pose_frame("left", left_sequence[left_sequence.size() - 1]), 1420)
	assert_false(_event_names(state.get("events", [])).has("punch_left"))
	var matcher_debug: Dictionary = state.get("gesture_debug", {}).get("prototype_matcher", {})
	assert_true(["emit_hold_active", "emit_cooldown_active"].has(String(matcher_debug.get("reason", ""))))
	if String(matcher_debug.get("reason", "")) == "emit_hold_active":
		assert_true(int(matcher_debug.get("hold_ms_remaining", 0)) > 0)
	else:
		assert_true(int(matcher_debug.get("cooldown_ms_remaining", 0)) > 0)
	state = substrate.process_landmarks(_prototype_pose_frame("left", left_sequence[left_sequence.size() - 1]), 1490)
	assert_false(_event_names(state.get("events", [])).has("punch_left"))
	matcher_debug = state.get("gesture_debug", {}).get("prototype_matcher", {})
	assert_eq(String(matcher_debug.get("reason", "")), "emit_cooldown_active")
	assert_true(int(matcher_debug.get("cooldown_ms_remaining", 0)) > 0)
	var replay_times := [1660, 1725, 1790, 1855, 1910]
	var saw_replay_emit := false
	for idx in range(replay_times.size()):
		state = substrate.process_landmarks(_prototype_pose_frame("left", left_sequence[idx]), int(replay_times[idx]))
		saw_replay_emit = saw_replay_emit or _event_names(state.get("events", [])).has("punch_left")
	assert_true(saw_replay_emit)
	matcher_debug = state.get("gesture_debug", {}).get("prototype_matcher", {})
	assert_true(["emitted", "emit_hold_active"].has(String(matcher_debug.get("reason", ""))))

func test_learned_classifier_backend_emits_and_surfaces_truthful_debug_state() -> void:
	var model_path := _write_test_learned_classifier_model("straight_left", 10.0)
	_enable_learned_classifier_backend({
		"model_path": model_path,
		"match_score_min": 0.70,
		"emit_cooldown_ms": 250,
		"emit_hold_ms": 100,
	})
	_calibrate_stance()
	var state := substrate.process_landmarks(_prototype_pose_frame("left", {"elbow_x": 0.34, "elbow_y": 0.66, "wrist_x": 0.28, "wrist_y": 0.60, "elbow_z": 0.00, "wrist_z": 0.00}), 1400)
	assert_eq(_event_names(state.get("events", [])), ["punch_left"])
	var gesture_debug: Dictionary = state.get("gesture_debug", {})
	assert_eq(String(gesture_debug.get("punch_detection", {}).get("backend", "")), "learned_classifier")
	assert_true(bool(gesture_debug.get("punch_detection", {}).get("learned_classifier_enabled", false)))
	var learned_debug: Dictionary = gesture_debug.get("learned_classifier", {})
	assert_eq(String(learned_debug.get("selected_backend", "")), "learned_classifier")
	assert_eq(String(learned_debug.get("active_backend", "")), "learned_classifier")
	assert_eq(String(learned_debug.get("best_class", "")), "straight_left")
	assert_eq(String(learned_debug.get("result_class", "")), "straight_left")
	assert_eq(String(learned_debug.get("emitted_event_name", "")), "punch_left")
	assert_true(bool(learned_debug.get("model_loaded", false)))
	assert_eq(String(learned_debug.get("model_path", "")), model_path)
	assert_true(float(learned_debug.get("best_score", 0.0)) >= 0.70)

func test_learned_classifier_non_eval_frames_preserve_last_scored_debug_truth() -> void:
	var model_path := _write_test_learned_classifier_model("straight_left", 10.0, 2)
	_enable_learned_classifier_backend({
		"model_path": model_path,
		"match_score_min": 0.70,
		"emit_cooldown_ms": 250,
		"emit_hold_ms": 100,
	})
	_calibrate_stance()
	var state := substrate.process_landmarks(_prototype_pose_frame("left", {"elbow_x": 0.34, "elbow_y": 0.66, "wrist_x": 0.28, "wrist_y": 0.60, "elbow_z": 0.00, "wrist_z": 0.00}), 40)
	assert_eq(String(state.get("gesture_debug", {}).get("learned_classifier", {}).get("reason", "")), "window_not_full")
	state = substrate.process_landmarks(_prototype_pose_frame("left", {"elbow_x": 0.35, "elbow_y": 0.66, "wrist_x": 0.27, "wrist_y": 0.60, "elbow_z": 0.00, "wrist_z": 0.00}), 100)
	assert_eq(_event_names(state.get("events", [])), ["punch_left"])
	var learned_debug: Dictionary = state.get("gesture_debug", {}).get("learned_classifier", {})
	var emitted_class_scores: Dictionary = learned_debug.get("class_scores", {})
	assert_eq(String(learned_debug.get("best_class", "")), "straight_left")
	assert_eq(String(learned_debug.get("result_class", "")), "straight_left")
	assert_eq(String(learned_debug.get("emitted_event_name", "")), "punch_left")
	assert_true(float(learned_debug.get("best_score", 0.0)) >= 0.70)
	assert_false(emitted_class_scores.is_empty())

	state = substrate.process_landmarks(_prototype_pose_frame("left", {"elbow_x": 0.36, "elbow_y": 0.66, "wrist_x": 0.26, "wrist_y": 0.60, "elbow_z": 0.00, "wrist_z": 0.00}), 120)
	assert_eq(_event_names(state.get("events", [])), [])
	learned_debug = state.get("gesture_debug", {}).get("learned_classifier", {})
	assert_eq(String(learned_debug.get("reason", "")), "step_wait")
	assert_false(bool(learned_debug.get("emitted", true)))
	assert_eq(String(learned_debug.get("best_class", "")), "straight_left")
	assert_eq(String(learned_debug.get("result_class", "")), "straight_left")
	assert_eq(String(learned_debug.get("emitted_event_name", "")), "punch_left")
	assert_true(is_equal_approx(float(learned_debug.get("best_score", 0.0)), float(emitted_class_scores.get("straight_left", 0.0))))
	assert_eq(String(learned_debug.get("active_event_class", "")), "straight_left")
	assert_true(int(learned_debug.get("hold_ms_remaining", 0)) > 0)
	assert_true(int(learned_debug.get("cooldown_ms_remaining", 0)) > 0)
	var step_wait_scores: Dictionary = learned_debug.get("class_scores", {})
	assert_true(is_equal_approx(float(step_wait_scores.get("straight_left", 0.0)), float(emitted_class_scores.get("straight_left", 0.0))))

func test_learned_classifier_replay_timestamp_rewind_resets_temporal_gate_state() -> void:
	var model_path := _write_test_learned_classifier_model("straight_left", 10.0, 2)
	_enable_learned_classifier_backend({
		"model_path": model_path,
		"match_score_min": 0.70,
		"emit_cooldown_ms": 250,
		"emit_hold_ms": 100,
	})
	_calibrate_stance()
	var state := substrate.process_landmarks(_prototype_pose_frame("left", {"elbow_x": 0.34, "elbow_y": 0.66, "wrist_x": 0.28, "wrist_y": 0.60, "elbow_z": 0.00, "wrist_z": 0.00}), 40)
	var learned_debug: Dictionary = state.get("gesture_debug", {}).get("learned_classifier", {})
	assert_eq(String(learned_debug.get("reason", "")), "window_not_full")
	state = substrate.process_landmarks(_prototype_pose_frame("left", {"elbow_x": 0.35, "elbow_y": 0.66, "wrist_x": 0.27, "wrist_y": 0.60, "elbow_z": 0.00, "wrist_z": 0.00}), 100)
	assert_eq(_event_names(state.get("events", [])), ["punch_left"])
	learned_debug = state.get("gesture_debug", {}).get("learned_classifier", {})
	assert_true(int(learned_debug.get("last_eval_timestamp_ms", 0)) > 0)
	assert_true(int(learned_debug.get("hold_ms_remaining", 0)) > 0)
	assert_true(int(learned_debug.get("cooldown_ms_remaining", 0)) > 0)
	assert_eq(String(learned_debug.get("active_event_class", "")), "straight_left")

	state = substrate.process_landmarks(_prototype_pose_frame("left", {"elbow_x": 0.34, "elbow_y": 0.66, "wrist_x": 0.28, "wrist_y": 0.60, "elbow_z": 0.00, "wrist_z": 0.00}), 20)
	assert_eq(_event_names(state.get("events", [])), [])
	learned_debug = state.get("gesture_debug", {}).get("learned_classifier", {})
	assert_eq(int(learned_debug.get("window_sample_count", -1)), 1)
	assert_eq(int(learned_debug.get("last_eval_timestamp_ms", -1)), 0)
	assert_eq(int(learned_debug.get("hold_ms_remaining", -1)), 0)
	assert_eq(int(learned_debug.get("cooldown_ms_remaining", -1)), 0)
	assert_eq(String(learned_debug.get("active_event_class", "")), "no_punch")
	assert_eq(String(learned_debug.get("reason", "")), "window_not_full")

func test_learned_classifier_lost_tracking_cleanup_resets_temporal_gate_state() -> void:
	var model_path := _write_test_learned_classifier_model("straight_left", 10.0, 2)
	_enable_learned_classifier_backend({
		"model_path": model_path,
		"match_score_min": 0.70,
		"emit_cooldown_ms": 250,
		"emit_hold_ms": 100,
	})
	_calibrate_stance()
	var state := substrate.process_landmarks(_prototype_pose_frame("left", {"elbow_x": 0.34, "elbow_y": 0.66, "wrist_x": 0.28, "wrist_y": 0.60, "elbow_z": 0.00, "wrist_z": 0.00}), 40)
	state = substrate.process_landmarks(_prototype_pose_frame("left", {"elbow_x": 0.35, "elbow_y": 0.66, "wrist_x": 0.27, "wrist_y": 0.60, "elbow_z": 0.00, "wrist_z": 0.00}), 100)
	var learned_debug: Dictionary = state.get("gesture_debug", {}).get("learned_classifier", {})
	assert_eq(String(learned_debug.get("active_event_class", "")), "straight_left")
	assert_true(int(learned_debug.get("hold_ms_remaining", 0)) > 0)
	assert_true(int(learned_debug.get("cooldown_ms_remaining", 0)) > 0)

	state = substrate.process_landmarks(_make_pose_frame({}, 0.50, 1.0, 0.2, 0.2), 116)
	state = substrate.process_landmarks(_make_pose_frame({}, 0.50, 1.0, 0.2, 0.2), 132)
	state = substrate.process_landmarks(_make_pose_frame({}, 0.50, 1.0, 0.2, 0.2), 148)
	assert_eq(String(state.get("tracking_state", "")), "lost")
	learned_debug = state.get("gesture_debug", {}).get("learned_classifier", {})
	assert_eq(int(learned_debug.get("window_sample_count", -1)), 0)
	assert_eq(int(learned_debug.get("last_eval_timestamp_ms", -1)), 0)
	assert_eq(int(learned_debug.get("hold_ms_remaining", -1)), 0)
	assert_eq(int(learned_debug.get("cooldown_ms_remaining", -1)), 0)
	assert_eq(String(learned_debug.get("active_event_class", "")), "no_punch")
	assert_eq(String(learned_debug.get("reason", "")), "idle")

func test_learned_classifier_repo_root_docs_path_falls_back_to_addon_mount_in_testbed() -> void:
	_enable_learned_classifier_backend({
		"model_path": "res://docs/baselines/boxing-punch-classifier-frozen-benchmark-mlp-vs-cnn-2026-06-16/mlp/mlp-result.json",
	})
	_calibrate_stance()
	var state := substrate.process_landmarks(_make_pose_frame(), 1100)
	var learned_debug: Dictionary = state.get("gesture_debug", {}).get("learned_classifier", {})
	assert_true(bool(learned_debug.get("model_loaded", false)))
	assert_eq(String(learned_debug.get("model_error", "")), "")
	assert_eq(String(learned_debug.get("model_path", "")), "res://addons/aerobeat-input-camera-tracking/docs/baselines/boxing-punch-classifier-frozen-benchmark-mlp-vs-cnn-2026-06-16/mlp/mlp-result.json")
	assert_ne(String(learned_debug.get("reason", "")), "model_unavailable")

func test_mixed_family_backend_routes_straights_to_learned_classifier_and_surfaces_truth() -> void:
	var model_path := _write_test_learned_classifier_model("straight_left", 10.0, 2, [
		"left_elbow_shoulder_xy_distance_over_shoulder_width",
		"left_elbow_shoulder_radial_velocity_over_shoulder_width",
		"right_elbow_shoulder_xy_distance_over_shoulder_width",
		"right_elbow_shoulder_radial_velocity_over_shoulder_width",
	])
	_enable_mixed_family_backend({
		"model_path": model_path,
		"match_score_min": 0.70,
		"emit_cooldown_ms": 250,
		"emit_hold_ms": 100,
	})
	_calibrate_stance()
	var first_frame := _prototype_pose_frame("left", {"elbow_x": 0.42, "elbow_y": 0.67, "wrist_x": 0.32, "wrist_y": 0.62, "elbow_z": 0.00, "wrist_z": 0.00})
	var second_frame := _prototype_pose_frame("left", {"elbow_x": 0.34, "elbow_y": 0.66, "wrist_x": 0.28, "wrist_y": 0.60, "elbow_z": 0.00, "wrist_z": 0.00})
	var state := substrate.process_landmarks(first_frame, 40)
	assert_eq(String(state.get("gesture_debug", {}).get("learned_classifier", {}).get("reason", "")), "window_not_full")
	state = substrate.process_landmarks(second_frame, 100)
	var event_names := _event_names(state.get("events", []))
	assert_true(event_names.has("punch_left"))
	assert_false(event_names.has("hook_left"))
	var gesture_debug: Dictionary = state.get("gesture_debug", {})
	var punch_detection_debug: Dictionary = gesture_debug.get("punch_detection", {})
	assert_eq(String(punch_detection_debug.get("active_backend", "")), "mixed_family")
	assert_eq(String(punch_detection_debug.get("routing_mode", "")), "mixed_family")
	assert_eq(String(punch_detection_debug.get("straight_backend", "")), "learned_classifier")
	assert_eq(String(punch_detection_debug.get("hook_backend", "")), "threshold_gates")
	assert_eq(String(punch_detection_debug.get("uppercut_backend", "")), "threshold_gates")
	assert_eq(String(punch_detection_debug.get("straight_model_path", "")), model_path)
	assert_string_contains(String(punch_detection_debug.get("hook_uppercut_backend_note", "")), "hook/uppercut stay on threshold_gates")
	var learned_debug: Dictionary = gesture_debug.get("learned_classifier", {})
	assert_eq(String(learned_debug.get("selected_backend", "")), "mixed_family")
	assert_eq(String(learned_debug.get("active_backend", "")), "learned_classifier")
	assert_eq(String(learned_debug.get("emitted_event_name", "")), "punch_left")

func test_mixed_family_backend_filters_non_straight_learned_events() -> void:
	var model_path := _write_test_learned_classifier_model("hook_left", 10.0)
	_enable_mixed_family_backend({
		"model_path": model_path,
		"match_score_min": 0.70,
	})
	_calibrate_stance()
	var state := substrate.process_landmarks(_prototype_pose_frame("left", {"elbow_x": 0.34, "elbow_y": 0.66, "wrist_x": 0.28, "wrist_y": 0.60, "elbow_z": 0.00, "wrist_z": 0.00}), 1400)
	var event_names := _event_names(state.get("events", []))
	assert_false(event_names.has("hook_left"))
	assert_false(event_names.has("punch_left"))
	assert_eq(String(state.get("gesture_debug", {}).get("learned_classifier", {}).get("best_class", "")), "hook_left")

func test_learned_classifier_selection_does_not_fall_back_to_threshold_backend_when_disabled() -> void:
	config.tracker_profile_document = {
		"tracking": {
			"hands": {
				"enabled": false,
			},
		},
	}
	config.gesture_profile_document = {
		"punch_detection": {
			"backend": "learned_classifier",
		},
		"threshold_gates": {
			"enabled": true,
		},
		"learned_classifier": {
			"enabled": false,
		},
	}
	substrate = PoseDetectorSubstrate.new().configure(config)
	_calibrate_stance()
	var state := substrate.process_landmarks(_make_pose_frame(), 1100)
	var punch_detection_debug: Dictionary = state.get("gesture_debug", {}).get("punch_detection", {})
	assert_eq(String(punch_detection_debug.get("selected_backend", "")), "learned_classifier")
	assert_false(bool(punch_detection_debug.get("selected_backend_enabled", true)))
	assert_eq(String(punch_detection_debug.get("active_backend_resolution", "")), "selected_backend_disabled")
	assert_eq(String(punch_detection_debug.get("active_backend", "")), "none")
	assert_eq(String(punch_detection_debug.get("backend", "")), "none")

func test_threshold_gates_disabled_resolves_selected_backend_to_none_without_fallback() -> void:
	config.gesture_profile_document = {
		"punch_detection": {
			"backend": "threshold_gates",
		},
		"threshold_gates": {
			"enabled": false,
		},
	}
	substrate = PoseDetectorSubstrate.new().configure(config)
	_calibrate_stance()
	var state := substrate.process_landmarks(_make_pose_frame(), 1100)
	var punch_detection_debug: Dictionary = state.get("gesture_debug", {}).get("punch_detection", {})
	assert_eq(String(punch_detection_debug.get("selected_backend_raw", "")), "threshold_gates")
	assert_eq(String(punch_detection_debug.get("selected_backend", "")), "threshold_gates")
	assert_false(bool(punch_detection_debug.get("selected_backend_enabled", true)))
	assert_eq(String(punch_detection_debug.get("active_backend_resolution", "")), "selected_backend_disabled")
	assert_eq(String(punch_detection_debug.get("active_backend", "")), "none")

func _calibrate_stance() -> void:
	for idx in range(5):
		var state := substrate.process_landmarks(_make_pose_frame(), 1000 + idx * 16)
		assert_eq(String(state["tracking_state"]), "tracking")

func _flow_events(events: Array) -> Array:
	var flow_events: Array = []
	for event_variant: Variant in events:
		if not event_variant is Dictionary:
			continue
		var event_data: Dictionary = event_variant
		var event_name := String(event_data.get("name", ""))
		if not event_name.begins_with("swing_") and not event_name.begins_with("trail_"):
			continue
		flow_events.append({
			"name": event_name,
			"placement": int(event_data.get("placement", -1)),
			"direction": int(event_data.get("direction", -1)),
		})
	return flow_events

func _event_names(events: Array) -> Array:
	var names: Array = []
	for event_variant: Variant in events:
		if event_variant is Dictionary:
			names.append(String(event_variant.get("name", "")))
	return names

func _straight_punch_state_names(events: Array, side: String) -> Array:
	var states: Array = []
	for event_variant: Variant in events:
		if not event_variant is Dictionary:
			continue
		var event_data: Dictionary = event_variant
		if String(event_data.get("name", "")) != "straight_punch_state_changed":
			continue
		if String(event_data.get("side", "")) != side:
			continue
		states.append(String(event_data.get("state", "")))
	return states

func _pose_strike_state_names(events: Array, family: String, side: String) -> Array:
	var states: Array = []
	for event_variant: Variant in events:
		if not event_variant is Dictionary:
			continue
		var event_data: Dictionary = event_variant
		if String(event_data.get("name", "")) != "%s_state_changed" % family:
			continue
		if String(event_data.get("side", "")) != side:
			continue
		states.append(String(event_data.get("state", "")))
	return states

func _make_tracking_frame(left_hand: Dictionary = {}, right_hand: Dictionary = {}) -> Dictionary:
	return {
		"hand_tracking": {
			"enabled": true,
			"available": true,
		},
		"hands": {
			"left": left_hand.duplicate(true),
			"right": right_hand.duplicate(true),
		},
	}

func test_gesture_eval_interval_frames_skips_detector_updates_until_configured_frame() -> void:
	config.gesture_eval_interval_frames = 2
	substrate = PoseDetectorSubstrate.new().configure(config)
	_calibrate_stance()
	var first_tracking_frame := _make_tracking_frame(_tracked_hand_payload("left", 0.021, "tracked", true, 0, 1, 0.0, null, "", 0), _tracked_hand_payload("right", 0.020))
	var state := substrate.process_landmarks(_make_pose_frame({
		PoseLandmarkIds.LEFT_WRIST: {"z": -0.04},
	}), 1100, first_tracking_frame)
	assert_eq(_straight_punch_state_names(state.get("events", []), "left"), [])
	assert_eq(String(state.get("gesture_debug", {}).get("straight_punch", {}).get("left", {}).get("state", "")), "tracking_lost")

	var second_tracking_frame := _make_tracking_frame(_tracked_hand_payload("left", 0.022, "tracked", true, 0, 1, 0.0, null, "", 20), _tracked_hand_payload("right", 0.020))
	state = substrate.process_landmarks(_make_pose_frame({
		PoseLandmarkIds.LEFT_WRIST: {"z": -0.08},
	}), 1180, second_tracking_frame)
	assert_eq(_straight_punch_state_names(state.get("events", []), "left"), [])
	assert_eq(String(state.get("gesture_debug", {}).get("straight_punch", {}).get("left", {}).get("state", "")), "tracking_lost")

	var third_tracking_frame := _make_tracking_frame(_tracked_hand_payload("left", 0.023, "tracked", true, 0, 1, 0.0, null, "", 40), _tracked_hand_payload("right", 0.020))
	state = substrate.process_landmarks(_make_pose_frame({
		PoseLandmarkIds.LEFT_WRIST: {"z": -0.12},
	}), 1260, third_tracking_frame)
	assert_eq(_straight_punch_state_names(state.get("events", []), "left"), ["ready"])
	assert_eq(String(state.get("gesture_debug", {}).get("straight_punch", {}).get("left", {}).get("state", "")), "ready")

func _disable_hand_tracking_for_straight_punch() -> void:
	config.tracker_profile_document = {
		"tracking": {
			"hands": {
				"enabled": false,
			},
		},
	}
	config.gesture_profile_document = {
		"straight_punch": {
			"enabled": true,
			"thresholds": {
				"min_velocity": 0.18,
			},
			"timing": {
				"triggered_grace_ms": 240,
			},
		},
	}
	substrate = PoseDetectorSubstrate.new().configure(config)

func _enable_prototype_matcher_backend(options: Dictionary = {}) -> void:
	config.tracker_profile_document = {
		"tracking": {
			"hands": {
				"enabled": false,
			},
		},
	}
	config.gesture_profile_document = {
		"punch_detection": {
			"backend": "prototype_matcher",
		},
		"threshold_gates": {
			"enabled": true,
		},
		"prototype_matcher": {
			"enabled": true,
			"prototype_library": {
				"library_id": "boxing_side_aware_v1",
			},
			"evaluation": {
				"window_ms": int(options.get("window_ms", 250)),
				"window_step_ms": int(options.get("window_step_ms", 33)),
			},
			"thresholds": {
				"match_score_min": float(options.get("match_score_min", 0.70)),
			},
			"timing": {
				"emit_cooldown_ms": int(options.get("emit_cooldown_ms", 250)),
				"emit_hold_ms": int(options.get("emit_hold_ms", 100)),
			},
			"debug": {
				"show_scores": true,
				"show_event_gate_state": true,
			},
		},
	}
	substrate = PoseDetectorSubstrate.new().configure(config)

func _enable_mixed_family_backend(options: Dictionary = {}) -> void:
	config.tracker_profile_document = {
		"tracking": {
			"hands": {
				"enabled": false,
			},
		},
	}
	config.gesture_profile_document = {
		"punch_detection": {
			"backend": "mixed_family",
		},
		"threshold_gates": {
			"enabled": true,
		},
		"learned_classifier": {
			"enabled": true,
			"model": {
				"artifact_path": String(options.get("model_path", "")),
			},
			"thresholds": {
				"match_score_min": float(options.get("match_score_min", 0.70)),
			},
			"timing": {
				"emit_cooldown_ms": int(options.get("emit_cooldown_ms", 250)),
				"emit_hold_ms": int(options.get("emit_hold_ms", 100)),
			},
			"debug": {
				"show_scores": true,
				"show_event_gate_state": true,
			},
		},
	}
	substrate = PoseDetectorSubstrate.new().configure(config)

func _enable_learned_classifier_backend(options: Dictionary = {}) -> void:
	config.tracker_profile_document = {
		"tracking": {
			"hands": {
				"enabled": false,
			},
		},
	}
	config.gesture_profile_document = {
		"punch_detection": {
			"backend": "learned_classifier",
		},
		"threshold_gates": {
			"enabled": true,
		},
		"learned_classifier": {
			"enabled": true,
			"model": {
				"artifact_path": String(options.get("model_path", "")),
			},
			"thresholds": {
				"match_score_min": float(options.get("match_score_min", 0.70)),
			},
			"timing": {
				"emit_cooldown_ms": int(options.get("emit_cooldown_ms", 250)),
				"emit_hold_ms": int(options.get("emit_hold_ms", 100)),
			},
			"debug": {
				"show_scores": true,
				"show_event_gate_state": true,
			},
		},
	}
	substrate = PoseDetectorSubstrate.new().configure(config)

func _write_test_learned_classifier_model(winner_class: String = "straight_left", confidence_logit: float = 10.0, frame_count: int = 1, frame_feature_names: Array = []) -> String:
	var feature_slug := "default" if frame_feature_names.is_empty() else str(frame_feature_names.size())
	var path := "user://test-learned-classifier-%s-%d-%s.json" % [winner_class, frame_count, feature_slug]
	var class_order := ["straight_left", "straight_right", "hook_left", "hook_right", "uppercut_left", "uppercut_right", "no_punch"]
	var winner_index := class_order.find(winner_class)
	assert_true(winner_index >= 0)
	var means: Array = []
	var stds: Array = []
	var effective_frame_feature_names := frame_feature_names.duplicate(true)
	var effective_side_feature_names: Array = []
	if effective_frame_feature_names.is_empty():
		for feature_name in [
			"left_shoulder_x", "left_shoulder_y", "left_elbow_x", "left_elbow_y", "left_wrist_x", "left_wrist_y", "left_combined_elbow_wrist_velocity_xy_magnitude", "left_elbow_shoulder_xy_distance_over_shoulder_width",
			"right_shoulder_x", "right_shoulder_y", "right_elbow_x", "right_elbow_y", "right_wrist_x", "right_wrist_y", "right_combined_elbow_wrist_velocity_xy_magnitude", "right_elbow_shoulder_xy_distance_over_shoulder_width",
		]:
			effective_frame_feature_names.append(feature_name)
		effective_side_feature_names = [
			"shoulder_x", "shoulder_y", "elbow_x", "elbow_y", "wrist_x", "wrist_y", "combined_elbow_wrist_velocity_xy_magnitude", "elbow_shoulder_xy_distance_over_shoulder_width",
		]
	else:
		var seen_side_feature_names: Dictionary = {}
		for frame_feature_name_variant in effective_frame_feature_names:
			var frame_feature_name := String(frame_feature_name_variant)
			var side_feature_name := frame_feature_name
			if frame_feature_name.begins_with("left_"):
				side_feature_name = frame_feature_name.trim_prefix("left_")
			elif frame_feature_name.begins_with("right_"):
				side_feature_name = frame_feature_name.trim_prefix("right_")
			if not seen_side_feature_names.has(side_feature_name):
				seen_side_feature_names[side_feature_name] = true
				effective_side_feature_names.append(side_feature_name)
	for _idx in range(frame_count * effective_frame_feature_names.size()):
		means.append(0.0)
		stds.append(1.0)
	var logits_biases: Array = []
	for idx in range(class_order.size()):
		logits_biases.append(confidence_logit if idx == winner_index else 0.0)
	var input_dim := frame_count * effective_frame_feature_names.size()
	var hidden_weights: Array = []
	for _idx in range(input_dim):
		hidden_weights.append(0.0)
	var document := {
		"schema": "aerobeat.boxing_punch_classifier_mlp_result",
		"version": 1,
		"class_order": class_order,
		"dataset_window_shape": {
			"frame_count": frame_count,
			"frame_feature_count": effective_frame_feature_names.size(),
			"flattened_input_dim": input_dim,
		},
		"side_feature_names": effective_side_feature_names,
		"frame_feature_names": effective_frame_feature_names,
		"standardization": {
			"means": means,
			"stds": stds,
		},
		"model": {
			"input_dim": input_dim,
			"hidden_dim": 1,
			"output_dim": class_order.size(),
			"w1": [hidden_weights],
			"b1": [1.0],
			"w2": [[0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0]],
			"b2": logits_biases,
		},
	}
	var file := FileAccess.open(path, FileAccess.WRITE)
	assert_not_null(file)
	file.store_string(JSON.stringify(document))
	file.flush()
	file = null
	return path

func _tracked_hand_payload(side: String, bbox_area: float, tracking_state: String = "tracked", tracking_valid: bool = true, stale_frames: int = 0, frame_index: int = 1, timestamp_seconds: float = 0.0, fresh_sample: Variant = null, sample_source: String = "", stable_ms: int = -1) -> Dictionary:
	var physical_bbox_area := maxf(0.10 - bbox_area, 0.0)
	var width := 0.10
	var height := physical_bbox_area / width if width > 0.0 else 0.0
	var x := 0.18 if side == "left" else 0.72
	var payload := {
		"tracking_valid": tracking_valid,
		"tracking_state": tracking_state,
		"frame_index": frame_index,
		"timestamp_seconds": timestamp_seconds,
		"stale_frames": stale_frames,
		"association": {
			"side": side,
			"assigned": true,
			"method": "pose_side_binding",
			"source_hand_index": 0 if side == "left" else 1,
			"source_label": side,
			"source_score": 0.95,
		},
		"landmarks": [],
		"bbox": {
			"x": x,
			"y": 0.40,
			"width": width,
			"height": height,
			"area": physical_bbox_area,
			"area_unit": "normalized_frame_area",
		},
	}
	if stable_ms >= 0:
		payload["stable_ms"] = stable_ms
	if fresh_sample != null:
		payload["fresh_sample"] = bool(fresh_sample)
	if sample_source != "":
		payload["sample_source"] = sample_source
	return payload

func _tracked_hand_payload_physical(side: String, bbox_area: float, tracking_state: String = "tracked", tracking_valid: bool = true, stale_frames: int = 0, frame_index: int = 1, timestamp_seconds: float = 0.0, fresh_sample: Variant = null, sample_source: String = "", stable_ms: int = -1) -> Dictionary:
	var width := 0.10
	var height := bbox_area / width if width > 0.0 else 0.0
	var x := 0.18 if side == "left" else 0.72
	var payload := {
		"tracking_valid": tracking_valid,
		"tracking_state": tracking_state,
		"frame_index": frame_index,
		"timestamp_seconds": timestamp_seconds,
		"stale_frames": stale_frames,
		"association": {
			"side": side,
			"assigned": true,
			"method": "pose_side_binding",
			"source_hand_index": 0 if side == "left" else 1,
			"source_label": side,
			"source_score": 0.95,
		},
		"landmarks": [],
		"bbox": {
			"x": x,
			"y": 0.40,
			"width": width,
			"height": height,
			"area": bbox_area,
			"area_unit": "normalized_frame_area",
		},
	}
	if stable_ms >= 0:
		payload["stable_ms"] = stable_ms
	if fresh_sample != null:
		payload["fresh_sample"] = bool(fresh_sample)
	if sample_source != "":
		payload["sample_source"] = sample_source
	return payload

func _prototype_pose_frame(side: String, sample: Dictionary) -> Array:
	var overrides := {}
	var elbow_id := PoseLandmarkIds.LEFT_ELBOW if side == "left" else PoseLandmarkIds.RIGHT_ELBOW
	var wrist_id := PoseLandmarkIds.LEFT_WRIST if side == "left" else PoseLandmarkIds.RIGHT_WRIST
	overrides[elbow_id] = {
		"x": float(sample.get("elbow_x", 0.0)),
		"y": float(sample.get("elbow_y", 0.0)),
		"z": float(sample.get("elbow_z", 0.0)),
	}
	overrides[wrist_id] = {
		"x": float(sample.get("wrist_x", 0.0)),
		"y": float(sample.get("wrist_y", 0.0)),
		"z": float(sample.get("wrist_z", 0.0)),
	}
	return _make_pose_frame(overrides)

func _make_pose_frame(overrides: Dictionary = {}, center_x: float = 0.50, height_scale: float = 1.0, visibility: float = 0.99, knee_visibility: float = 0.99) -> Array:
	var shoulder_y := 0.70
	var hip_y := shoulder_y - 0.30 * height_scale
	var knee_y := hip_y - 0.18 * height_scale
	var ankle_y := hip_y - 0.36 * height_scale
	var nose_y := shoulder_y + 0.20 * height_scale
	var frame := [
		{"id": PoseLandmarkIds.NOSE, "x": center_x, "y": nose_y, "z": 0.0, "v": visibility},
		{"id": PoseLandmarkIds.LEFT_SHOULDER, "x": center_x - 0.10, "y": shoulder_y, "z": 0.0, "v": visibility},
		{"id": PoseLandmarkIds.RIGHT_SHOULDER, "x": center_x + 0.10, "y": shoulder_y, "z": 0.0, "v": visibility},
		{"id": PoseLandmarkIds.LEFT_ELBOW, "x": center_x - 0.16, "y": shoulder_y - 0.04, "z": 0.0, "v": visibility},
		{"id": PoseLandmarkIds.RIGHT_ELBOW, "x": center_x + 0.16, "y": shoulder_y - 0.04, "z": 0.0, "v": visibility},
		{"id": PoseLandmarkIds.LEFT_WRIST, "x": center_x - 0.22, "y": shoulder_y - 0.10, "z": 0.0, "v": visibility},
		{"id": PoseLandmarkIds.RIGHT_WRIST, "x": center_x + 0.22, "y": shoulder_y - 0.10, "z": 0.0, "v": visibility},
		{"id": PoseLandmarkIds.LEFT_HIP, "x": center_x - 0.08, "y": hip_y, "z": 0.0, "v": visibility},
		{"id": PoseLandmarkIds.RIGHT_HIP, "x": center_x + 0.08, "y": hip_y, "z": 0.0, "v": visibility},
		{"id": PoseLandmarkIds.LEFT_KNEE, "x": center_x - 0.06, "y": knee_y, "z": 0.0, "v": knee_visibility},
		{"id": PoseLandmarkIds.RIGHT_KNEE, "x": center_x + 0.06, "y": knee_y, "z": 0.0, "v": knee_visibility},
		{"id": PoseLandmarkIds.LEFT_ANKLE, "x": center_x - 0.04, "y": ankle_y, "z": 0.0, "v": visibility},
		{"id": PoseLandmarkIds.RIGHT_ANKLE, "x": center_x + 0.04, "y": ankle_y, "z": 0.0, "v": visibility},
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
