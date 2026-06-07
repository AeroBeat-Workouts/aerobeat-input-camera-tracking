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
	var tracking_frame := _make_tracking_frame(_tracked_hand_payload("left", 0.020, "tracked", true, 0, 1, 0.0, null, "", 0), _tracked_hand_payload("right", 0.020))
	var state := substrate.process_landmarks(_make_pose_frame(), 1100, tracking_frame)
	assert_eq(String(state.get("gesture_debug", {}).get("straight_punch", {}).get("left", {}).get("state", "")), "tracking_lost")

	tracking_frame = _make_tracking_frame(_tracked_hand_payload("left", 0.021, "tracked", true, 0, 1, 0.0, null, "", 80), _tracked_hand_payload("right", 0.020))
	state = substrate.process_landmarks(_make_pose_frame({
		PoseLandmarkIds.LEFT_WRIST: {"z": -0.04},
	}), 1180, tracking_frame)
	assert_eq(String(state.get("gesture_debug", {}).get("straight_punch", {}).get("left", {}).get("state", "")), "ready")
	assert_eq(_straight_punch_state_names(state.get("events", []), "left"), ["ready"])

	tracking_frame = _make_tracking_frame(_tracked_hand_payload("left", 0.023), _tracked_hand_payload("right", 0.020))
	state = substrate.process_landmarks(_make_pose_frame({
		PoseLandmarkIds.LEFT_WRIST: {"z": -0.08},
	}), 1260, tracking_frame)
	tracking_frame = _make_tracking_frame(_tracked_hand_payload("left", 0.0225), _tracked_hand_payload("right", 0.020))
	state = substrate.process_landmarks(_make_pose_frame({
		PoseLandmarkIds.LEFT_WRIST: {"z": -0.12},
	}), 1340, tracking_frame)
	tracking_frame = _make_tracking_frame(_tracked_hand_payload("left", 0.0275), _tracked_hand_payload("right", 0.020))
	state = substrate.process_landmarks(_make_pose_frame({
		PoseLandmarkIds.LEFT_WRIST: {"z": -0.20},
	}), 1420, tracking_frame)
	assert_true(_event_names(state.get("events", [])).has("punch_left"))
	assert_eq(_straight_punch_state_names(state.get("events", []), "left"), ["triggered"])
	var left_debug: Dictionary = state.get("gesture_debug", {}).get("straight_punch", {}).get("left", {})
	assert_eq(String(left_debug.get("state", "")), "triggered")
	assert_true(is_equal_approx(float(left_debug.get("trigger_bbox_area", 0.0)), 0.0275))
	assert_eq(int(left_debug.get("positive_growth_samples", 0)), 2)

	var lost_frame := _make_tracking_frame(_tracked_hand_payload("left", 0.0275, "reacquiring", false), _tracked_hand_payload("right", 0.020))
	state = substrate.process_landmarks(_make_pose_frame({
		PoseLandmarkIds.LEFT_WRIST: {"z": -0.20},
	}), 1500, lost_frame)
	left_debug = state.get("gesture_debug", {}).get("straight_punch", {}).get("left", {})
	assert_eq(_straight_punch_state_names(state.get("events", []), "left"), ["tracking_lost"])
	assert_eq(String(left_debug.get("state", "")), "tracking_lost")
	assert_eq(int(left_debug.get("grace_ms_remaining", -1)), 0)
	assert_true(is_equal_approx(float(left_debug.get("trigger_bbox_area", 1.0)), 0.0))

func test_straight_punch_debug_uses_live_metrics_hand_truth() -> void:
	_calibrate_stance()
	var tracking_frame := _make_tracking_frame(_tracked_hand_payload("left", 0.024), _tracked_hand_payload("right", 0.020))
	var state := substrate.process_landmarks(_make_pose_frame(), 1100, tracking_frame)
	var left_debug: Dictionary = state.get("gesture_debug", {}).get("straight_punch", {}).get("left", {})
	assert_true(bool(state.get("metrics", {}).get("hands", {}).get("left", {}).get("tracking_valid", false)))
	assert_true(bool(left_debug.get("tracking_valid", false)))
	assert_eq(String(left_debug.get("tracking_state", "")), "tracked")

func test_straight_punch_threshold_aliases_old_min_wrist_velocity_key() -> void:
	config.gesture_profile_document = {
		"straight_punch": {
			"thresholds": {
				"min_wrist_velocity": 0.33,
			}
		}
	}
	substrate = PoseDetectorSubstrate.new().configure(config)
	_calibrate_stance()
	var state := substrate.process_landmarks(_make_pose_frame(), 1100, _make_tracking_frame(_tracked_hand_payload("left", 0.020), _tracked_hand_payload("right", 0.020)))
	var left_debug: Dictionary = state.get("gesture_debug", {}).get("straight_punch", {}).get("left", {})
	assert_true(is_equal_approx(float(left_debug.get("min_punch_velocity", 0.0)), 0.33))
	assert_false(left_debug.has("min_wrist_velocity"))

func test_straight_punch_uses_window_growth_with_subthreshold_step_deltas() -> void:
	_calibrate_stance()
	var state := substrate.process_landmarks(_make_pose_frame(), 1100, _make_tracking_frame(_tracked_hand_payload("left", 0.020), _tracked_hand_payload("right", 0.020)))
	state = substrate.process_landmarks(_make_pose_frame({PoseLandmarkIds.LEFT_WRIST: {"z": -0.02}}), 1180, _make_tracking_frame(_tracked_hand_payload("left", 0.021), _tracked_hand_payload("right", 0.020)))
	assert_eq(String(state.get("gesture_debug", {}).get("straight_punch", {}).get("left", {}).get("state", "")), "ready")

	state = substrate.process_landmarks(_make_pose_frame({PoseLandmarkIds.LEFT_WRIST: {"z": -0.05}}), 1260, _make_tracking_frame(_tracked_hand_payload("left", 0.023), _tracked_hand_payload("right", 0.020)))
	state = substrate.process_landmarks(_make_pose_frame({PoseLandmarkIds.LEFT_WRIST: {"z": -0.07}}), 1340, _make_tracking_frame(_tracked_hand_payload("left", 0.0228), _tracked_hand_payload("right", 0.020)))
	state = substrate.process_landmarks(_make_pose_frame({PoseLandmarkIds.LEFT_WRIST: {"z": -0.20}}), 1420, _make_tracking_frame(_tracked_hand_payload("left", 0.0272), _tracked_hand_payload("right", 0.020)))
	assert_true(_event_names(state.get("events", [])).has("punch_left"))
	var left_debug: Dictionary = state.get("gesture_debug", {}).get("straight_punch", {}).get("left", {})
	assert_eq(String(left_debug.get("state", "")), "triggered")
	assert_true(is_equal_approx(float(left_debug.get("bbox_area_growth", 0.0)), 0.0062))
	assert_eq(int(left_debug.get("positive_growth_samples", 0)), 2)
	assert_eq(int(left_debug.get("min_positive_growth_samples", 0)), 2)
	assert_true(is_equal_approx(float(left_debug.get("min_bbox_area_growth", 0.0)), 0.006))

func test_straight_punch_grace_hand_samples_remain_trigger_eligible() -> void:
	_calibrate_stance()
	var tracking_frame := _make_tracking_frame(_tracked_hand_payload("left", 0.020, "tracked", true, 0, 1, 1.10), _tracked_hand_payload("right", 0.020))
	substrate.process_landmarks(_make_pose_frame(), 1100, tracking_frame)
	tracking_frame = _make_tracking_frame(_tracked_hand_payload("left", 0.021, "tracked", true, 0, 2, 1.18), _tracked_hand_payload("right", 0.020))
	substrate.process_landmarks(_make_pose_frame({PoseLandmarkIds.LEFT_WRIST: {"z": -0.04}}), 1180, tracking_frame)
	tracking_frame = _make_tracking_frame(_tracked_hand_payload("left", 0.023, "tracked", true, 0, 3, 1.26), _tracked_hand_payload("right", 0.020))
	substrate.process_landmarks(_make_pose_frame({PoseLandmarkIds.LEFT_WRIST: {"z": -0.08}}), 1260, tracking_frame)
	tracking_frame = _make_tracking_frame(_tracked_hand_payload("left", 0.0225, "tracked", true, 0, 4, 1.34), _tracked_hand_payload("right", 0.020))
	var state := substrate.process_landmarks(_make_pose_frame({PoseLandmarkIds.LEFT_WRIST: {"z": -0.12}}), 1340, tracking_frame)
	assert_eq(String(state.get("gesture_debug", {}).get("straight_punch", {}).get("left", {}).get("state", "")), "ready")

	var grace_frame := _make_tracking_frame(_tracked_hand_payload("left", 0.0275, "grace", true, 1, 5, 1.42), _tracked_hand_payload("right", 0.020))
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
	assert_true(float(state.get("metrics", {}).get("measurements", {}).get("left_wrist_velocity_magnitude", 0.0)) < float(left_debug.get("min_punch_velocity", 0.0)))
	assert_true(float(left_debug.get("wrist_velocity", 0.0)) > float(left_debug.get("min_punch_velocity", 0.0)))
	assert_false(_event_names(state.get("events", [])).has("punch_left"))

func test_straight_punch_ignores_stale_hand_samples_for_trigger_evaluation() -> void:
	_calibrate_stance()
	var tracking_frame := _make_tracking_frame(_tracked_hand_payload("left", 0.020), _tracked_hand_payload("right", 0.020))
	substrate.process_landmarks(_make_pose_frame(), 1100, tracking_frame)
	tracking_frame = _make_tracking_frame(_tracked_hand_payload("left", 0.021), _tracked_hand_payload("right", 0.020))
	substrate.process_landmarks(_make_pose_frame({PoseLandmarkIds.LEFT_WRIST: {"z": -0.04}}), 1180, tracking_frame)
	tracking_frame = _make_tracking_frame(_tracked_hand_payload("left", 0.023), _tracked_hand_payload("right", 0.020))
	substrate.process_landmarks(_make_pose_frame({PoseLandmarkIds.LEFT_WRIST: {"z": -0.08}}), 1260, tracking_frame)
	tracking_frame = _make_tracking_frame(_tracked_hand_payload("left", 0.0225), _tracked_hand_payload("right", 0.020))
	var state := substrate.process_landmarks(_make_pose_frame({PoseLandmarkIds.LEFT_WRIST: {"z": -0.12}}), 1340, tracking_frame)
	assert_eq(String(state.get("gesture_debug", {}).get("straight_punch", {}).get("left", {}).get("state", "")), "ready")

	var stale_frame := _make_tracking_frame(_tracked_hand_payload("left", 0.0275, "stale", true, 1), _tracked_hand_payload("right", 0.020))
	state = substrate.process_landmarks(_make_pose_frame({PoseLandmarkIds.LEFT_WRIST: {"z": -0.20}}), 1420, stale_frame)
	assert_false(_event_names(state.get("events", [])).has("punch_left"))
	assert_eq(String(state.get("gesture_debug", {}).get("straight_punch", {}).get("left", {}).get("state", "")), "ready")

	tracking_frame = _make_tracking_frame(_tracked_hand_payload("left", 0.0295), _tracked_hand_payload("right", 0.020))
	state = substrate.process_landmarks(_make_pose_frame({PoseLandmarkIds.LEFT_WRIST: {"z": -0.28}}), 1500, tracking_frame)
	assert_true(_event_names(state.get("events", [])).has("punch_left"))
	assert_eq(_straight_punch_state_names(state.get("events", []), "left"), ["triggered"])

func test_straight_punch_uses_xyz_wrist_velocity_magnitude_for_trigger_gate() -> void:
	_calibrate_stance()
	var state := substrate.process_landmarks(_make_pose_frame(), 1100, _make_tracking_frame(_tracked_hand_payload("left", 0.020), _tracked_hand_payload("right", 0.020)))
	state = substrate.process_landmarks(
		_make_pose_frame({
			PoseLandmarkIds.LEFT_WRIST: {"x": 0.32, "y": 0.56, "z": -0.01},
			PoseLandmarkIds.LEFT_ELBOW: {"x": 0.33, "y": 0.62, "z": -0.005},
		}),
		1180,
		_make_tracking_frame(_tracked_hand_payload("left", 0.021), _tracked_hand_payload("right", 0.020))
	)
	assert_eq(String(state.get("gesture_debug", {}).get("straight_punch", {}).get("left", {}).get("state", "")), "ready")

	state = substrate.process_landmarks(
		_make_pose_frame({
			PoseLandmarkIds.LEFT_WRIST: {"x": 0.38, "y": 0.48, "z": -0.02},
			PoseLandmarkIds.LEFT_ELBOW: {"x": 0.37, "y": 0.56, "z": -0.010},
		}),
		1260,
		_make_tracking_frame(_tracked_hand_payload("left", 0.023), _tracked_hand_payload("right", 0.020))
	)
	state = substrate.process_landmarks(
		_make_pose_frame({
			PoseLandmarkIds.LEFT_WRIST: {"x": 0.42, "y": 0.42, "z": -0.03},
			PoseLandmarkIds.LEFT_ELBOW: {"x": 0.40, "y": 0.50, "z": -0.015},
		}),
		1340,
		_make_tracking_frame(_tracked_hand_payload("left", 0.0275), _tracked_hand_payload("right", 0.020))
	)
	assert_true(_event_names(state.get("events", [])).has("punch_left"))
	assert_eq(_straight_punch_state_names(state.get("events", []), "left"), ["triggered"])
	var left_debug: Dictionary = state.get("gesture_debug", {}).get("straight_punch", {}).get("left", {})
	assert_true(float(left_debug.get("wrist_velocity", 0.0)) > float(left_debug.get("min_punch_velocity", 0.0)))
	assert_true(float(left_debug.get("wrist_forward_velocity", 0.0)) < float(left_debug.get("min_punch_velocity", 0.0)))
	assert_true(float(state.get("metrics", {}).get("measurements", {}).get("left_wrist_velocity_magnitude", 0.0)) > float(state.get("metrics", {}).get("measurements", {}).get("left_forward_velocity", 0.0)))


func test_straight_punch_wrist_velocity_uses_configured_time_window_instead_of_last_step_only() -> void:
	config.gesture_profile_document = {
		"straight_punch": {
			"evaluation": {
				"sample_window_size": 4,
				"min_positive_growth_samples": 1,
				"wrist_velocity_window_ms": 160,
			},
			"thresholds": {
				"min_punch_velocity": 0.18,
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
	}), 1260, _make_tracking_frame(_tracked_hand_payload("left", 0.0240), _tracked_hand_payload("right", 0.020)))
	state = substrate.process_landmarks(_make_pose_frame({
		PoseLandmarkIds.LEFT_ELBOW: {"z": -0.205},
		PoseLandmarkIds.LEFT_WRIST: {"z": -0.205},
	}), 1340, _make_tracking_frame(_tracked_hand_payload("left", 0.0245), _tracked_hand_payload("right", 0.020)))
	var left_debug: Dictionary = state.get("gesture_debug", {}).get("straight_punch", {}).get("left", {})
	assert_eq(int(left_debug.get("wrist_velocity_window_ms", 0)), 160)
	assert_eq(int(left_debug.get("wrist_velocity_window_span_ms", 0)), 160)
	assert_true(float(left_debug.get("wrist_velocity", 0.0)) > 0.9)
	assert_true(is_equal_approx(float(left_debug.get("wrist_velocity", 0.0)), float(left_debug.get("wrist_forward_velocity", 0.0))))

func test_straight_punch_bbox_area_growth_uses_configured_time_window_instead_of_sample_count_only() -> void:
	config.gesture_profile_document = {
		"straight_punch": {
			"evaluation": {
				"sample_window_size": 4,
				"min_positive_growth_samples": 1,
				"bbox_area_growth_window_ms": 160,
			},
			"thresholds": {
				"min_punch_velocity": 99.0,
				"min_bbox_area_growth": 99.0,
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
	state = substrate.process_landmarks(_make_pose_frame({PoseLandmarkIds.LEFT_WRIST: {"z": -0.12}}), 1260, _make_tracking_frame(_tracked_hand_payload("left", 0.0240), _tracked_hand_payload("right", 0.020)))
	state = substrate.process_landmarks(_make_pose_frame({PoseLandmarkIds.LEFT_WRIST: {"z": -0.18}}), 1340, _make_tracking_frame(_tracked_hand_payload("left", 0.0245), _tracked_hand_payload("right", 0.020)))
	var left_debug: Dictionary = state.get("gesture_debug", {}).get("straight_punch", {}).get("left", {})
	assert_eq(int(left_debug.get("bbox_area_growth_window_ms", 0)), 160)
	assert_eq(int(left_debug.get("bbox_area_growth_window_span_ms", 0)), 160)
	assert_true(is_equal_approx(float(left_debug.get("bbox_area_growth", 0.0)), 0.0035))
	assert_eq(left_debug.get("growth_window_areas", []), [0.021, 0.024, 0.0245])

func test_straight_punch_uses_recent_wrist_velocity_peak_when_growth_lands_on_next_hand_sample() -> void:
	config.gesture_profile_document = {
		"straight_punch": {
			"evaluation": {
				"sample_window_size": 4,
				"min_positive_growth_samples": 1,
				"wrist_velocity_window_ms": 80,
			},
			"thresholds": {
				"min_punch_velocity": 0.18,
				"min_bbox_area_growth": 0.006,
			},
		},
	}
	substrate = PoseDetectorSubstrate.new().configure(config)
	_calibrate_stance()
	var state := substrate.process_landmarks(_make_pose_frame(), 1100, _make_tracking_frame(_tracked_hand_payload("left", 0.020, "tracked", true, 0, 10, 1.0, null, "", 0), _tracked_hand_payload("right", 0.020, "tracked", true, 0, 10, 1.0)))
	state = substrate.process_landmarks(_make_pose_frame({PoseLandmarkIds.LEFT_WRIST: {"z": -0.04}}), 1180, _make_tracking_frame(_tracked_hand_payload("left", 0.021, "tracked", true, 0, 11, 1.1, null, "", 80), _tracked_hand_payload("right", 0.020, "tracked", true, 0, 11, 1.1)))
	assert_eq(String(state.get("gesture_debug", {}).get("straight_punch", {}).get("left", {}).get("state", "")), "ready")

	state = substrate.process_landmarks(_make_pose_frame({PoseLandmarkIds.LEFT_WRIST: {"z": -0.08}}), 1260, _make_tracking_frame(_tracked_hand_payload("left", 0.023, "tracked", true, 0, 12, 1.2), _tracked_hand_payload("right", 0.020, "tracked", true, 0, 12, 1.2)))
	state = substrate.process_landmarks(_make_pose_frame({PoseLandmarkIds.LEFT_WRIST: {"z": -0.20}}), 1340, _make_tracking_frame(_tracked_hand_payload("left", 0.0240, "tracked", true, 0, 13, 1.3), _tracked_hand_payload("right", 0.020, "tracked", true, 0, 13, 1.3)))
	state = substrate.process_landmarks(_make_pose_frame({PoseLandmarkIds.LEFT_WRIST: {"z": -0.205}}), 1420, _make_tracking_frame(_tracked_hand_payload("left", 0.0272, "tracked", true, 0, 14, 1.4), _tracked_hand_payload("right", 0.020, "tracked", true, 0, 14, 1.4)))
	assert_true(_event_names(state.get("events", [])).has("punch_left"))
	assert_eq(_straight_punch_state_names(state.get("events", []), "left"), ["triggered"])
	var left_debug: Dictionary = state.get("gesture_debug", {}).get("straight_punch", {}).get("left", {})
	assert_true(float(left_debug.get("recent_peak_wrist_velocity", 0.0)) > float(left_debug.get("wrist_velocity", 0.0)))
	assert_true(float(left_debug.get("wrist_velocity", 0.0)) < float(left_debug.get("min_punch_velocity", 0.0)))

func test_straight_punch_uses_recent_bbox_growth_peak_when_velocity_lands_on_next_hand_sample() -> void:
	config.gesture_profile_document = {
		"straight_punch": {
			"evaluation": {
				"sample_window_size": 4,
				"min_positive_growth_samples": 1,
			},
			"thresholds": {
				"min_punch_velocity": 0.18,
				"min_bbox_area_growth": 0.00014,
			},
		},
	}
	substrate = PoseDetectorSubstrate.new().configure(config)
	_calibrate_stance()
	var state := substrate.process_landmarks(_make_pose_frame(), 1100, _make_tracking_frame(_tracked_hand_payload("left", 0.020, "tracked", true, 0, 10, 1.0, null, "", 0), _tracked_hand_payload("right", 0.020, "tracked", true, 0, 10, 1.0)))
	state = substrate.process_landmarks(_make_pose_frame({
		PoseLandmarkIds.LEFT_ELBOW: {"z": -0.01},
		PoseLandmarkIds.LEFT_WRIST: {"z": -0.01},
	}), 1180, _make_tracking_frame(_tracked_hand_payload("left", 0.021, "tracked", true, 0, 11, 1.1, null, "", 80), _tracked_hand_payload("right", 0.020, "tracked", true, 0, 11, 1.1)))
	assert_eq(String(state.get("gesture_debug", {}).get("straight_punch", {}).get("left", {}).get("state", "")), "ready")

	state = substrate.process_landmarks(_make_pose_frame({
		PoseLandmarkIds.LEFT_ELBOW: {"z": -0.01},
		PoseLandmarkIds.LEFT_WRIST: {"z": -0.01},
	}), 1260, _make_tracking_frame(_tracked_hand_payload("left", 0.02125, "tracked", true, 0, 12, 1.2), _tracked_hand_payload("right", 0.020, "tracked", true, 0, 12, 1.2)))
	assert_false(_event_names(state.get("events", [])).has("punch_left"))
	state = substrate.process_landmarks(_make_pose_frame({
		PoseLandmarkIds.LEFT_ELBOW: {"z": -0.021},
		PoseLandmarkIds.LEFT_WRIST: {"z": -0.021},
	}), 1340, _make_tracking_frame(_tracked_hand_payload("left", 0.02110, "tracked", true, 0, 13, 1.3), _tracked_hand_payload("right", 0.020, "tracked", true, 0, 13, 1.3)))
	assert_false(_event_names(state.get("events", [])).has("punch_left"))
	state = substrate.process_landmarks(_make_pose_frame({
		PoseLandmarkIds.LEFT_ELBOW: {"z": -0.20},
		PoseLandmarkIds.LEFT_WRIST: {"z": -0.20},
	}), 1420, _make_tracking_frame(_tracked_hand_payload("left", 0.02112, "tracked", true, 0, 14, 1.4), _tracked_hand_payload("right", 0.020, "tracked", true, 0, 14, 1.4)))
	assert_true(_event_names(state.get("events", [])).has("punch_left"))
	assert_eq(_straight_punch_state_names(state.get("events", []), "left"), ["triggered"])
	var left_debug: Dictionary = state.get("gesture_debug", {}).get("straight_punch", {}).get("left", {})
	assert_true(float(left_debug.get("recent_peak_bbox_area_growth", 0.0)) > float(left_debug.get("bbox_area_growth", 0.0)))
	assert_true(float(left_debug.get("bbox_area_growth", 0.0)) < float(left_debug.get("min_bbox_area_growth", 0.0)))

func test_straight_punch_keeps_recent_velocity_peak_across_non_fresh_replay_duplicates() -> void:
	_calibrate_stance()
	var state := substrate.process_landmarks(_make_pose_frame(), 1100, _make_tracking_frame(_tracked_hand_payload("left", 0.020, "tracked", true, 0, 10, 1.0, null, "", 0), _tracked_hand_payload("right", 0.020, "tracked", true, 0, 10, 1.0)))
	state = substrate.process_landmarks(_make_pose_frame({PoseLandmarkIds.LEFT_WRIST: {"z": -0.04}}), 1180, _make_tracking_frame(_tracked_hand_payload("left", 0.021, "tracked", true, 0, 11, 1.1, null, "", 80), _tracked_hand_payload("right", 0.020, "tracked", true, 0, 11, 1.1)))
	assert_eq(String(state.get("gesture_debug", {}).get("straight_punch", {}).get("left", {}).get("state", "")), "ready")

	state = substrate.process_landmarks(_make_pose_frame({PoseLandmarkIds.LEFT_WRIST: {"z": -0.12}}), 1260, _make_tracking_frame(_tracked_hand_payload("left", 0.023, "tracked", true, 0, 12, 1.2), _tracked_hand_payload("right", 0.020, "tracked", true, 0, 12, 1.2)))
	assert_false(_event_names(state.get("events", [])).has("punch_left"))

	for duplicate_time in [1270, 1280, 1290, 1300, 1310]:
		state = substrate.process_landmarks(_make_pose_frame({PoseLandmarkIds.LEFT_WRIST: {"z": -0.121}}), duplicate_time, _make_tracking_frame(_tracked_hand_payload("left", 0.023, "tracked", true, 0, 12, 1.2), _tracked_hand_payload("right", 0.020, "tracked", true, 0, 12, 1.2)))
		assert_false(_event_names(state.get("events", [])).has("punch_left"))

	state = substrate.process_landmarks(_make_pose_frame({PoseLandmarkIds.LEFT_WRIST: {"z": -0.122}}), 1420, _make_tracking_frame(_tracked_hand_payload("left", 0.0272, "tracked", true, 0, 13, 1.3), _tracked_hand_payload("right", 0.020, "tracked", true, 0, 13, 1.3)))
	assert_true(_event_names(state.get("events", [])).has("punch_left"))
	assert_eq(_straight_punch_state_names(state.get("events", []), "left"), ["triggered"])
	var duplicate_debug: Dictionary = state.get("gesture_debug", {}).get("straight_punch", {}).get("left", {})
	assert_true(float(duplicate_debug.get("recent_peak_wrist_velocity", 0.0)) > float(duplicate_debug.get("wrist_velocity", 0.0)))
	assert_true(float(duplicate_debug.get("wrist_velocity", 0.0)) < float(duplicate_debug.get("min_punch_velocity", 0.0)))

func test_straight_punch_dedupes_replayed_tracked_samples_until_hand_frame_advances() -> void:
	_calibrate_stance()
	var state := substrate.process_landmarks(
		_make_pose_frame(),
		1100,
		_make_tracking_frame(_tracked_hand_payload("left", 0.020, "tracked", true, 0, 10, 1.0, null, "", 0), _tracked_hand_payload("right", 0.020, "tracked", true, 0, 10, 1.0))
	)
	assert_eq(String(state.get("gesture_debug", {}).get("straight_punch", {}).get("left", {}).get("state", "")), "tracking_lost")

	state = substrate.process_landmarks(
		_make_pose_frame({PoseLandmarkIds.LEFT_WRIST: {"z": -0.04}}),
		1180,
		_make_tracking_frame(_tracked_hand_payload("left", 0.021, "tracked", true, 0, 11, 1.1, null, "", 80), _tracked_hand_payload("right", 0.020, "tracked", true, 0, 11, 1.1))
	)
	assert_eq(String(state.get("gesture_debug", {}).get("straight_punch", {}).get("left", {}).get("state", "")), "ready")

	state = substrate.process_landmarks(
		_make_pose_frame({PoseLandmarkIds.LEFT_WRIST: {"z": -0.08}}),
		1200,
		_make_tracking_frame(_tracked_hand_payload("left", 0.023, "tracked", true, 0, 12, 1.2), _tracked_hand_payload("right", 0.020, "tracked", true, 0, 12, 1.2))
	)
	state = substrate.process_landmarks(
		_make_pose_frame({PoseLandmarkIds.LEFT_WRIST: {"z": -0.12}}),
		1210,
		_make_tracking_frame(_tracked_hand_payload("left", 0.023, "tracked", true, 0, 12, 1.2), _tracked_hand_payload("right", 0.020, "tracked", true, 0, 12, 1.2))
	)
	var left_debug: Dictionary = state.get("gesture_debug", {}).get("straight_punch", {}).get("left", {})
	assert_true(is_equal_approx(float(left_debug.get("bbox_area_growth", 0.0)), 0.002))
	assert_eq(int(left_debug.get("positive_growth_samples", 0)), 1)

	state = substrate.process_landmarks(
		_make_pose_frame({PoseLandmarkIds.LEFT_WRIST: {"z": -0.20}}),
		1280,
		_make_tracking_frame(_tracked_hand_payload("left", 0.0272, "tracked", true, 0, 13, 1.3), _tracked_hand_payload("right", 0.020, "tracked", true, 0, 13, 1.3))
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
			_make_tracking_frame(_tracked_hand_payload("left", float(frame_data.get("area", 0.0))), _tracked_hand_payload("right", 0.020))
		)
	assert_eq(String(state.get("gesture_debug", {}).get("straight_punch", {}).get("left", {}).get("state", "")), "triggered")

	state = substrate.process_landmarks(_make_pose_frame({PoseLandmarkIds.LEFT_WRIST: {"z": -0.22}}), 1500, _make_tracking_frame(_tracked_hand_payload("left", 0.0280), _tracked_hand_payload("right", 0.020)))
	var left_debug: Dictionary = state.get("gesture_debug", {}).get("straight_punch", {}).get("left", {})
	assert_eq(String(left_debug.get("state", "")), "triggered")
	assert_eq(int(left_debug.get("grace_ms_remaining", -1)), 160)
	state = substrate.process_landmarks(_make_pose_frame({PoseLandmarkIds.LEFT_WRIST: {"z": -0.21}}), 1580, _make_tracking_frame(_tracked_hand_payload("left", 0.0260), _tracked_hand_payload("right", 0.020)))
	left_debug = state.get("gesture_debug", {}).get("straight_punch", {}).get("left", {})
	assert_eq(String(left_debug.get("state", "")), "triggered")
	assert_eq(int(left_debug.get("grace_ms_remaining", -1)), 80)
	state = substrate.process_landmarks(_make_pose_frame({PoseLandmarkIds.LEFT_WRIST: {"z": -0.18}}), 1660, _make_tracking_frame(_tracked_hand_payload("left", 0.0240), _tracked_hand_payload("right", 0.020)))
	left_debug = state.get("gesture_debug", {}).get("straight_punch", {}).get("left", {})
	assert_eq(_straight_punch_state_names(state.get("events", []), "left"), ["not_ready"])
	assert_eq(String(left_debug.get("state", "")), "not_ready")
	assert_eq(int(left_debug.get("grace_ms_remaining", -1)), 0)

	state = substrate.process_landmarks(_make_pose_frame({PoseLandmarkIds.LEFT_WRIST: {"z": -0.03}}), 1740, _make_tracking_frame(_tracked_hand_payload("left", 0.0220), _tracked_hand_payload("right", 0.020)))
	assert_eq(_straight_punch_state_names(state.get("events", []), "left"), ["ready"])
	assert_eq(String(state.get("gesture_debug", {}).get("straight_punch", {}).get("left", {}).get("state", "")), "ready")

	state = substrate.process_landmarks(_make_pose_frame({PoseLandmarkIds.LEFT_WRIST: {"z": -0.03}}), 1820, _make_tracking_frame(_tracked_hand_payload("left", 0.040, "reacquiring", false, 0, 1, 0.0, null, "", 0), _tracked_hand_payload("right", 0.020)))
	assert_eq(_straight_punch_state_names(state.get("events", []), "left"), ["tracking_lost"])
	state = substrate.process_landmarks(_make_pose_frame({PoseLandmarkIds.LEFT_WRIST: {"z": -0.02}}), 1900, _make_tracking_frame(_tracked_hand_payload("left", 0.022, "tracked", true, 0, 1, 0.0, null, "", 20), _tracked_hand_payload("right", 0.020)))
	left_debug = state.get("gesture_debug", {}).get("straight_punch", {}).get("left", {})
	assert_eq(String(left_debug.get("state", "")), "tracking_lost")
	assert_eq(int(left_debug.get("reacquire_stable_ms_required", -1)), 40)
	assert_eq(int(left_debug.get("stable_ms", -1)), 20)
	state = substrate.process_landmarks(_make_pose_frame({PoseLandmarkIds.LEFT_WRIST: {"z": -0.01}}), 1980, _make_tracking_frame(_tracked_hand_payload("left", 0.023, "tracked", true, 0, 1, 0.0, null, "", 40), _tracked_hand_payload("right", 0.020)))
	assert_eq(_straight_punch_state_names(state.get("events", []), "left"), ["ready"])
	left_debug = state.get("gesture_debug", {}).get("straight_punch", {}).get("left", {})
	assert_eq(String(left_debug.get("state", "")), "ready")

func test_straight_punch_triggered_grace_uses_elapsed_milliseconds() -> void:
	config.gesture_profile_document = {
		"straight_punch": {
			"evaluation": {
				"sample_window_size": 4,
				"min_positive_growth_samples": 1,
			},
			"thresholds": {
				"min_punch_velocity": 0.18,
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
	var state := substrate.process_landmarks(_make_pose_frame(), 1100, _make_tracking_frame(_tracked_hand_payload("left", 0.00460, "tracked", true, 0, 1, 0.0, null, "", 0), _tracked_hand_payload("right", 0.020)))
	state = substrate.process_landmarks(_make_pose_frame({PoseLandmarkIds.LEFT_WRIST: {"z": -0.04}}), 1180, _make_tracking_frame(_tracked_hand_payload("left", 0.00476, "tracked", true, 0, 1, 0.0, null, "", 80), _tracked_hand_payload("right", 0.020)))
	state = substrate.process_landmarks(_make_pose_frame({PoseLandmarkIds.LEFT_WRIST: {"z": -0.18}}), 1260, _make_tracking_frame(_tracked_hand_payload("left", 0.00522), _tracked_hand_payload("right", 0.020)))
	var left_debug: Dictionary = state.get("gesture_debug", {}).get("straight_punch", {}).get("left", {})
	assert_true(_event_names(state.get("events", [])).has("punch_left"))
	assert_eq(String(left_debug.get("state", "")), "triggered")
	assert_eq(int(left_debug.get("grace_ms_remaining", -1)), 200)

	state = substrate.process_landmarks(_make_pose_frame({PoseLandmarkIds.LEFT_WRIST: {"z": -0.17}}), 1330, _make_tracking_frame(_tracked_hand_payload("left", 0.00518), _tracked_hand_payload("right", 0.020)))
	left_debug = state.get("gesture_debug", {}).get("straight_punch", {}).get("left", {})
	assert_eq(String(left_debug.get("state", "")), "triggered")
	assert_eq(int(left_debug.get("grace_ms_remaining", -1)), 130)

	state = substrate.process_landmarks(_make_pose_frame({PoseLandmarkIds.LEFT_WRIST: {"z": -0.16}}), 1460, _make_tracking_frame(_tracked_hand_payload("left", 0.00510), _tracked_hand_payload("right", 0.020)))
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
				"min_punch_velocity": 0.18,
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
	var state := substrate.process_landmarks(_make_pose_frame(), 1100, _make_tracking_frame(_tracked_hand_payload("left", 0.00460, "tracked", true, 0, 1, 0.0, null, "", 0), _tracked_hand_payload("right", 0.020)))
	state = substrate.process_landmarks(_make_pose_frame({PoseLandmarkIds.LEFT_WRIST: {"z": -0.04}}), 1180, _make_tracking_frame(_tracked_hand_payload("left", 0.00476, "tracked", true, 0, 1, 0.0, null, "", 80), _tracked_hand_payload("right", 0.020)))
	assert_eq(_straight_punch_state_names(state.get("events", []), "left"), ["ready"])
	state = substrate.process_landmarks(_make_pose_frame({PoseLandmarkIds.LEFT_WRIST: {"z": -0.18}}), 1260, _make_tracking_frame(_tracked_hand_payload("left", 0.00522), _tracked_hand_payload("right", 0.020)))
	assert_true(_event_names(state.get("events", [])).has("punch_left"))
	assert_eq(String(state.get("gesture_debug", {}).get("straight_punch", {}).get("left", {}).get("state", "")), "triggered")

	state = substrate.process_landmarks(_make_pose_frame({PoseLandmarkIds.LEFT_WRIST: {"z": -0.18}}), 1340, _make_tracking_frame(_tracked_hand_payload("left", 0.00522), _tracked_hand_payload("right", 0.020)))
	state = substrate.process_landmarks(_make_pose_frame({PoseLandmarkIds.LEFT_WRIST: {"z": -0.17}}), 1420, _make_tracking_frame(_tracked_hand_payload("left", 0.00518), _tracked_hand_payload("right", 0.020)))
	state = substrate.process_landmarks(_make_pose_frame({PoseLandmarkIds.LEFT_WRIST: {"z": -0.16}}), 1500, _make_tracking_frame(_tracked_hand_payload("left", 0.00510), _tracked_hand_payload("right", 0.020)))
	assert_eq(_straight_punch_state_names(state.get("events", []), "left"), ["not_ready"])
	state = substrate.process_landmarks(_make_pose_frame({PoseLandmarkIds.LEFT_WRIST: {"z": -0.06}}), 1580, _make_tracking_frame(_tracked_hand_payload("left", 0.00482), _tracked_hand_payload("right", 0.020)))
	assert_eq(_straight_punch_state_names(state.get("events", []), "left"), ["ready"])
	assert_eq(String(state.get("gesture_debug", {}).get("straight_punch", {}).get("left", {}).get("state", "")), "ready")

	state = substrate.process_landmarks(_make_pose_frame({PoseLandmarkIds.LEFT_WRIST: {"z": -0.20}}), 1660, _make_tracking_frame(_tracked_hand_payload("left", 0.00536), _tracked_hand_payload("right", 0.020)))
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
	assert_true(float(state.get("metrics", {}).get("measurements", {}).get("left_wrist_velocity_magnitude", 0.0)) < float(left_debug.get("min_punch_velocity", 0.0)))
	assert_true(float(left_debug.get("wrist_velocity", 0.0)) > float(left_debug.get("min_punch_velocity", 0.0)))
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
	assert_true(float(state.get("metrics", {}).get("measurements", {}).get("left_wrist_velocity_magnitude", 0.0)) < float(left_debug.get("min_punch_velocity", 0.0)))
	assert_true(float(left_debug.get("wrist_velocity", 0.0)) > float(left_debug.get("min_punch_velocity", 0.0)))
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

func test_detects_hook_and_uppercut_events_truthfully() -> void:
	_calibrate_stance()
	substrate.process_landmarks(_make_pose_frame(), 1620)
	var hook_state := substrate.process_landmarks(_make_pose_frame({
		PoseLandmarkIds.RIGHT_ELBOW: {"x": 0.68, "y": 0.62},
		PoseLandmarkIds.RIGHT_WRIST: {"x": 0.84, "y": 0.60},
	}), 1720)
	assert_eq(_event_names(hook_state.get("events", [])), ["hook_right"])

	substrate.process_landmarks(_make_pose_frame(), 1820)
	var uppercut_state := substrate.process_landmarks(_make_pose_frame({
		PoseLandmarkIds.LEFT_ELBOW: {"x": 0.34, "y": 0.62},
		PoseLandmarkIds.LEFT_WRIST: {"x": 0.33, "y": 0.76},
	}), 1920)
	assert_eq(_event_names(uppercut_state.get("events", [])), ["uppercut_left"])

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

func test_detects_guard_squat_weave_and_sidestep_state_events() -> void:
	_calibrate_stance()
	var guard_start_state := substrate.process_landmarks(_make_pose_frame({
		PoseLandmarkIds.LEFT_ELBOW: {"x": 0.42, "y": 0.69},
		PoseLandmarkIds.RIGHT_ELBOW: {"x": 0.58, "y": 0.69},
		PoseLandmarkIds.LEFT_WRIST: {"x": 0.41, "y": 0.80},
		PoseLandmarkIds.RIGHT_WRIST: {"x": 0.59, "y": 0.80},
	}), 1200)
	assert_eq(_event_names(guard_start_state.get("events", [])), ["guard_start"])
	var guard_end_state := substrate.process_landmarks(_make_pose_frame(), 1300)
	assert_eq(_event_names(guard_end_state.get("events", [])), ["guard_end"])

	var squat_start_state := substrate.process_landmarks(_make_pose_frame({}, 0.50, 0.78), 1400)
	assert_eq(_event_names(squat_start_state.get("events", [])), ["squat_start"])
	var squat_end_state := substrate.process_landmarks(_make_pose_frame(), 1500)
	assert_eq(_event_names(squat_end_state.get("events", [])), ["squat_end"])

	var weave_left_state := substrate.process_landmarks(_make_pose_frame({
		PoseLandmarkIds.NOSE: {"x": 0.43, "y": 0.85},
	}), 1600)
	assert_eq(_event_names(weave_left_state.get("events", [])), ["weave_left_start"])
	var weave_end_state := substrate.process_landmarks(_make_pose_frame(), 1700)
	assert_eq(_event_names(weave_end_state.get("events", [])), ["weave_left_end"])

	var sidestep_right_state := substrate.process_landmarks(_make_pose_frame({}, 0.60, 1.0), 1800)
	assert_eq(_event_names(sidestep_right_state.get("events", [])), ["sidestep_right_start"])
	var sidestep_end_state := substrate.process_landmarks(_make_pose_frame(), 1900)
	assert_eq(_event_names(sidestep_end_state.get("events", [])), ["sidestep_right_end"])

func test_detects_knee_and_leg_lift_events_with_reset_behavior() -> void:
	_calibrate_stance()
	var knee_state := substrate.process_landmarks(_make_pose_frame({
		PoseLandmarkIds.LEFT_KNEE: {"x": 0.44, "y": 0.34},
		PoseLandmarkIds.LEFT_ANKLE: {"x": 0.46, "y": 0.18},
	}), 1200)
	assert_eq(_event_names(knee_state.get("events", [])), ["knee_left"])
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
				"min_punch_velocity": 0.18,
			},
			"timing": {
				"triggered_grace_ms": 240,
			},
		},
	}
	substrate = PoseDetectorSubstrate.new().configure(config)

func _tracked_hand_payload(side: String, bbox_area: float, tracking_state: String = "tracked", tracking_valid: bool = true, stale_frames: int = 0, frame_index: int = 1, timestamp_seconds: float = 0.0, fresh_sample: Variant = null, sample_source: String = "", stable_ms: int = -1) -> Dictionary:
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
