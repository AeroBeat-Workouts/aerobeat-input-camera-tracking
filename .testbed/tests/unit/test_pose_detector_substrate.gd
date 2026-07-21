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

func test_boxing_profile_bundle_keeps_guard_threshold_and_grid_avoidance_surfaces_active() -> void:
	var bundle: Dictionary = config.get_selected_profile_bundle()
	assert_true(bool(bundle.get("ok", false)))
	config.gesture_profile_document = bundle.get("gesture_detection", {})
	substrate = PoseDetectorSubstrate.new().configure(config)
	var state := substrate.process_landmarks(_make_pose_frame(), 1000)
	var gesture_debug: Dictionary = state.get("gesture_debug", {})
	assert_eq(String(gesture_debug.get("guard", {}).get("backend", "")), "threshold")
	assert_true(bool(gesture_debug.get("guard", {}).get("enabled", false)))
	assert_eq(String(gesture_debug.get("squat", {}).get("backend", "")), "grid_avoidance")
	assert_true(bool(gesture_debug.get("squat", {}).get("enabled", false)))
	assert_eq(String(gesture_debug.get("weave", {}).get("backend", "")), "grid_avoidance")
	assert_true(bool(gesture_debug.get("weave", {}).get("enabled", false)))

func test_boxing_profile_bundle_keeps_straight_punch_trigger_truth_visible_at_published_replay_cadence() -> void:
	var bundle: Dictionary = config.get_selected_profile_bundle()
	assert_true(bool(bundle.get("ok", false)))

	var tracker_profile: Dictionary = (bundle.get("camera_tracking", {}) as Dictionary).duplicate(true)
	tracker_profile["tracking"] = (tracker_profile.get("tracking", {}) as Dictionary).duplicate(true)
	tracker_profile["tracking"]["hands"] = {"enabled": false}
	config.tracker_profile_document = tracker_profile

	var straight_threshold: Dictionary = (((bundle.get("gesture_detection", {}) as Dictionary).get("straight_punch", {}) as Dictionary).get("threshold", {}) as Dictionary)
	config.gesture_profile_document = {
		"straight_punch": {
			"backend": "threshold",
			"threshold": {
				"evaluation": {
					"window_ms": 250,
				},
				"thresholds": {
					"min_velocity": 0.18,
					"max_elbow_shoulder_xy_distance": 0.140,
					"min_wrist_lateral_angle_from_elbow_vertical_deg": 15.0,
				},
				"timing": {
					"triggered_grace_ms": int((((straight_threshold.get("timing", {}) as Dictionary)).get("triggered_grace_ms", 0))),
				},
				"rearm": {
					"pose_only_rearm_ms": int((((straight_threshold.get("rearm", {}) as Dictionary)).get("pose_only_rearm_ms", 0))),
				},
				"state_machine": {
					"lost_tracking_reacquire_stable_ms": 40,
				},
			},
		},
	}
	substrate = PoseDetectorSubstrate.new().configure(config)
	_calibrate_stance()

	var state_update_max_fps := int(bundle.get("camera_tracking", {}).get("tracking", {}).get("state_update_max_fps", 0))
	assert_eq(state_update_max_fps, 10)
	var published_state_interval_ms := int(round(1000.0 / float(state_update_max_fps)))
	assert_eq(published_state_interval_ms, 100)

	var state := substrate.process_landmarks(_make_pose_frame(), 1100)
	assert_eq(String(state.get("gesture_debug", {}).get("straight_punch", {}).get("left", {}).get("state", "")), "tracking_lost")
	state = substrate.process_landmarks(_make_pose_frame({PoseLandmarkIds.LEFT_WRIST: {"z": -0.02}}), 1140)
	assert_eq(_straight_punch_state_names(state.get("events", []), "left"), ["ready"])
	assert_eq(String(state.get("gesture_debug", {}).get("straight_punch", {}).get("left", {}).get("state", "")), "ready")

	var trigger_timestamp_ms := 1220
	state = substrate.process_landmarks(_make_pose_frame({PoseLandmarkIds.LEFT_WRIST: {"z": -0.18}}), trigger_timestamp_ms)
	assert_true(_event_names(state.get("events", [])).has("punch_left"))
	assert_eq(_straight_punch_state_names(state.get("events", []), "left"), ["triggered"])
	assert_eq(String(state.get("gesture_debug", {}).get("straight_punch", {}).get("left", {}).get("state", "")), "triggered")

	var published_snapshot := substrate.process_landmarks(
		_make_pose_frame({PoseLandmarkIds.LEFT_WRIST: {"z": -0.17}}),
		trigger_timestamp_ms + published_state_interval_ms
	)
	var left_debug: Dictionary = published_snapshot.get("gesture_debug", {}).get("straight_punch", {}).get("left", {})
	assert_eq(_straight_punch_state_names(published_snapshot.get("events", []), "left"), [])
	assert_false(_event_names(published_snapshot.get("events", [])).has("punch_left"))
	assert_eq(String(left_debug.get("state", "")), "triggered")
	assert_eq(int(left_debug.get("grace_ms_remaining", -1)), 140)
	assert_eq(int(left_debug.get("triggered_grace_ms", -1)), 240)
	assert_eq(int(left_debug.get("pose_only_rearm_ms", -1)), 250)

func test_flow_profile_bundle_removes_squat_public_surfaces() -> void:
	var bundle: Dictionary = config.set_profile_id("flow")
	assert_true(bool(bundle.get("ok", false)))
	substrate = PoseDetectorSubstrate.new().configure(config)
	_calibrate_stance()
	var state := substrate.process_landmarks(_make_pose_frame({}, 0.50, 0.78), 1200)
	var gesture_debug: Dictionary = state.get("gesture_debug", {})
	assert_false(bool(gesture_debug.has("squat")))
	assert_false(bool(state.get("gesture_states", {}).has("squat")))
	assert_false(_event_names(state.get("events", [])).has("squat_start"))
	assert_eq(String(gesture_debug.get("flow", {}).get("tracked_landmarks", {}).get("nose", {}).get("landmark_key", "")), "nose")

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

func test_straight_punch_requires_wrist_lateral_angle_from_elbow_vertical_gate_before_triggering() -> void:
	config.gesture_profile_document = {
		"straight_punch": {
			"thresholds": {
				"min_velocity": 0.18,
				"min_bbox_area_growth": 0.003,
				"max_elbow_shoulder_xy_distance": 0.09,
				"min_wrist_lateral_angle_from_elbow_vertical_deg": 20.0,
			},
		},
	}
	substrate = PoseDetectorSubstrate.new().configure(config)
	_calibrate_stance()
	var state := substrate.process_landmarks(_make_pose_frame(), 1100, _make_tracking_frame(_tracked_hand_payload_physical("left", 0.020), _tracked_hand_payload_physical("right", 0.020)))
	state = substrate.process_landmarks(_make_pose_frame({
		PoseLandmarkIds.LEFT_SHOULDER: {"x": 0.40, "y": 0.70, "z": 0.0},
		PoseLandmarkIds.LEFT_ELBOW: {"x": 0.36, "y": 0.64, "z": -0.01},
		PoseLandmarkIds.LEFT_WRIST: {"x": 0.365, "y": 0.54, "z": -0.04},
	}), 1180, _make_tracking_frame(_tracked_hand_payload_physical("left", 0.021), _tracked_hand_payload_physical("right", 0.020)))
	state = substrate.process_landmarks(_make_pose_frame({
		PoseLandmarkIds.LEFT_SHOULDER: {"x": 0.40, "y": 0.70, "z": 0.0},
		PoseLandmarkIds.LEFT_ELBOW: {"x": 0.36, "y": 0.64, "z": -0.02},
		PoseLandmarkIds.LEFT_WRIST: {"x": 0.370, "y": 0.50, "z": -0.12},
	}), 1260, _make_tracking_frame(_tracked_hand_payload_physical("left", 0.0240), _tracked_hand_payload_physical("right", 0.020)))
	state = substrate.process_landmarks(_make_pose_frame({
		PoseLandmarkIds.LEFT_SHOULDER: {"x": 0.40, "y": 0.70, "z": 0.0},
		PoseLandmarkIds.LEFT_ELBOW: {"x": 0.36, "y": 0.64, "z": -0.03},
		PoseLandmarkIds.LEFT_WRIST: {"x": 0.375, "y": 0.42, "z": -0.20},
	}), 1340, _make_tracking_frame(_tracked_hand_payload_physical("left", 0.0272), _tracked_hand_payload_physical("right", 0.020)))
	assert_false(_event_names(state.get("events", [])).has("punch_left"))
	var left_debug: Dictionary = state.get("gesture_debug", {}).get("straight_punch", {}).get("left", {})
	assert_eq(String(left_debug.get("state", "")), "ready")
	assert_true(float(left_debug.get("wrist_velocity", 0.0)) >= float(left_debug.get("min_velocity", 0.0)))
	assert_true(float(left_debug.get("bbox_area_growth", 0.0)) >= float(left_debug.get("min_bbox_area_growth", 0.0)))
	assert_true(bool(left_debug.get("elbow_shoulder_xy_gate_passed", false)))
	assert_true(float(left_debug.get("wrist_lateral_angle_from_elbow_vertical_deg", 0.0)) < float(left_debug.get("min_wrist_lateral_angle_from_elbow_vertical_deg", 0.0)))
	assert_false(bool(left_debug.get("wrist_lateral_angle_gate_passed", true)))

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

func test_depth_runtime_request_plumbing_marks_debug_texture_request_from_runtime_config() -> void:
	config.runtime = {
		"depth_debug": {
			"request_runtime_texture": true,
		}
	}
	substrate = PoseDetectorSubstrate.new().configure(config)
	var request: Dictionary = substrate.call(
		"_build_depth_sample_request",
		"straight_punch",
		"left",
		1234,
		{"x": 0.45, "y": 0.42},
		{"x": 0.48, "y": 0.55},
		{"x": 0.56, "y": 0.66},
		{"window_ms": 180},
		{
			"evaluation": {
				"sample_every_n_frames": 3,
				"sampling_mode": "region_aware",
				"region_geometry": {
					"wrist_shape": "extended_capsule",
					"wrist_radius_px": 12,
					"wrist_extension_toward_elbow_px": 8,
					"torso_shape": "center_box",
					"torso_half_width_px": 18,
					"torso_half_height_px": 14,
					"torso_anchor": "shoulder_landmark",
				},
				"aggregation": {
					"wrist_depth_stat": "median",
					"torso_depth_stat": "trimmed_mean",
					"trim_fraction": 0.2,
					"min_valid_samples": 5,
				},
			}
		}
	)
	assert_true(bool(request.get("debug_texture_requested", false)))
	assert_eq(int(request.get("window_ms", 0)), 180)
	assert_eq(int(request.get("evaluation", {}).get("sample_every_n_frames", 0)), 3)
	assert_eq(String(request.get("evaluation", {}).get("sampling_mode", "")), "region_aware")
	assert_eq(int(request.get("evaluation", {}).get("region_geometry", {}).get("wrist_radius_px", 0)), 12)
	assert_eq(String(request.get("evaluation", {}).get("aggregation", {}).get("torso_depth_stat", "")), "trimmed_mean")

func test_straight_punch_depth_gate_reports_preview_image_block_truthfully() -> void:
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
			"depth": {
				"enabled": true,
				"model": {
					"artifact_path": "res://addons/aerobeat-input-camera-tracking/assets/depth_models/midas/openvino_midas_v21_small_256/",
				},
				"evaluation": {
					"window_ms": 250,
					"early_window_fraction": 0.5,
					"late_window_fraction": 0.5,
				},
				"thresholds": {
					"min_closeness_delta": 0.06,
					"min_peak_closeness": 0.08,
				},
			},
		},
	}
	substrate = PoseDetectorSubstrate.new().configure(config)
	_calibrate_stance()
	var state := substrate.process_landmarks(_make_pose_frame(), 1100)
	assert_eq(String(state.get("gesture_debug", {}).get("straight_punch", {}).get("left", {}).get("state", "")), "tracking_lost")
	state = substrate.process_landmarks(_make_pose_frame({PoseLandmarkIds.LEFT_WRIST: {"z": -0.02}}), 1140)
	assert_eq(_straight_punch_state_names(state.get("events", []), "left"), ["ready"])
	state = substrate.process_landmarks(_make_pose_frame({PoseLandmarkIds.LEFT_WRIST: {"z": -0.18}}), 1220)
	assert_true(_event_names(state.get("events", [])).has("punch_left"))
	var left_debug: Dictionary = state.get("gesture_debug", {}).get("straight_punch", {}).get("left", {})
	assert_false(bool(left_debug.get("depth_gate_applied", true)))
	assert_eq(String(left_debug.get("depth_gate_reason", "")), "staged_or_unavailable")
	assert_eq(String(left_debug.get("depth_runtime_status", "")), "blocked")
	assert_eq(String(left_debug.get("depth_runtime_stage", "")), "inference")
	assert_eq(String(left_debug.get("depth_failure_code", "")), "preview_image_missing")
	assert_string_contains(String(left_debug.get("depth_failure_message", "")), "preview image path")

func test_straight_punch_depth_gate_uses_placeholder_closeness_signal() -> void:
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
			"depth": {
				"enabled": true,
				"model": {
					"artifact_path": "res://addons/aerobeat-input-camera-tracking/assets/depth_models/midas/openvino_midas_v21_small_256/",
				},
				"evaluation": {
					"window_ms": 250,
					"early_window_fraction": 0.5,
					"late_window_fraction": 0.5,
				},
				"thresholds": {
					"min_closeness_delta": 0.06,
					"min_peak_closeness": 0.08,
				},
			},
		},
	}
	substrate = PoseDetectorSubstrate.new().configure(config)
	_calibrate_stance()
	var state := substrate.process_landmarks(_make_pose_frame(), 1100, _make_tracking_frame({}, {}, _depth_tracking_frame_extras("straight_punch", "left", 0.01)))
	state = substrate.process_landmarks(_make_pose_frame({PoseLandmarkIds.LEFT_WRIST: {"z": -0.02}}), 1140, _make_tracking_frame({}, {}, _depth_tracking_frame_extras("straight_punch", "left", 0.02)))
	assert_eq(_straight_punch_state_names(state.get("events", []), "left"), ["ready"])
	state = substrate.process_landmarks(_make_pose_frame({PoseLandmarkIds.LEFT_WRIST: {"z": -0.05}}), 1180, _make_tracking_frame({}, {}, _depth_tracking_frame_extras("straight_punch", "left", 0.02)))
	assert_false(_event_names(state.get("events", [])).has("punch_left"))
	state = substrate.process_landmarks(_make_pose_frame({PoseLandmarkIds.LEFT_WRIST: {"z": -0.18}}), 1260, _make_tracking_frame({}, {}, _depth_tracking_frame_extras("straight_punch", "left", 0.12)))
	assert_true(_event_names(state.get("events", [])).has("punch_left"))
	var left_debug: Dictionary = state.get("gesture_debug", {}).get("straight_punch", {}).get("left", {})
	assert_true(bool(left_debug.get("depth_gate_applied", false)))
	assert_true(bool(left_debug.get("depth_gate_passed", false)))
	assert_eq(String(left_debug.get("depth_signal_source", "")), "placeholder")
	assert_true(float(left_debug.get("depth_closeness_delta", 0.0)) >= 0.06)
	assert_true(float(left_debug.get("depth_peak_closeness", 0.0)) >= 0.12)

func test_hook_depth_gate_blocks_excessive_forward_closeness() -> void:
	var hook_threshold := _default_hook_threshold_block()
	hook_threshold["depth"] = {
		"enabled": true,
		"evaluation": {
			"window_ms": 160,
			"early_window_fraction": 0.5,
			"late_window_fraction": 0.5,
		},
		"thresholds": {
			"max_closeness_delta": 0.03,
			"max_peak_closeness": 0.06,
		},
	}
	config.gesture_profile_document = {
		"hook": {
			"backend": "threshold",
			"threshold": hook_threshold,
		},
	}
	substrate = PoseDetectorSubstrate.new().configure(config)
	_calibrate_stance()
	var state := substrate.process_landmarks(_make_pose_frame(), 1000, _make_tracking_frame({}, {}, _depth_tracking_frame_extras("hook", "right", 0.01)))
	state = substrate.process_landmarks(_make_pose_frame(), 1160, _make_tracking_frame({}, {}, _depth_tracking_frame_extras("hook", "right", 0.02)))
	state = substrate.process_landmarks(_make_pose_frame({
		PoseLandmarkIds.RIGHT_ELBOW: {"x": 0.55, "y": 0.62},
		PoseLandmarkIds.RIGHT_WRIST: {"x": 0.64, "y": 0.60},
	}), 1320, _make_tracking_frame({}, {}, _depth_tracking_frame_extras("hook", "right", 0.10)))
	assert_false(_event_names(state.get("events", [])).has("hook_right"))
	var right_debug: Dictionary = state.get("gesture_debug", {}).get("hook", {}).get("right", {})
	assert_true(bool(right_debug.get("depth_gate_applied", false)))
	assert_false(bool(right_debug.get("depth_gate_passed", true)))
	assert_eq(String(right_debug.get("state", "")), "ready")

func test_uppercut_depth_gate_allows_placeholder_signal_inside_family_thresholds() -> void:
	var uppercut_threshold := {
		"evaluation": {"window_ms": 160},
		"thresholds": {
			"min_velocity": 0.40,
			"max_wrist_angle_from_elbow_vertical_deg": 70.0,
		},
		"timing": {"triggered_grace_ms": 300},
		"rearm": {"pose_only_rearm_ms": 120},
		"state_machine": {"lost_tracking_reacquire_stable_ms": 32},
		"depth": {
			"enabled": true,
			"evaluation": {
				"window_ms": 160,
				"early_window_fraction": 0.5,
				"late_window_fraction": 0.5,
			},
			"thresholds": {
				"max_closeness_delta": 0.03,
				"max_peak_closeness": 0.06,
			},
		},
	}
	config.gesture_profile_document = {
		"uppercut": {
			"backend": "threshold",
			"threshold": uppercut_threshold,
		},
	}
	substrate = PoseDetectorSubstrate.new().configure(config)
	_calibrate_stance()
	var state := substrate.process_landmarks(_make_pose_frame(), 2000, _make_tracking_frame({}, {}, _depth_tracking_frame_extras("uppercut", "left", 0.01)))
	state = substrate.process_landmarks(_make_pose_frame(), 2160, _make_tracking_frame({}, {}, _depth_tracking_frame_extras("uppercut", "left", 0.02)))
	state = substrate.process_landmarks(_make_pose_frame({
		PoseLandmarkIds.LEFT_ELBOW: {"x": 0.34, "y": 0.62},
		PoseLandmarkIds.LEFT_WRIST: {"x": 0.33, "y": 0.76},
	}), 2320, _make_tracking_frame({}, {}, _depth_tracking_frame_extras("uppercut", "left", 0.03)))
	assert_true(_event_names(state.get("events", [])).has("uppercut_left"))
	var left_debug: Dictionary = state.get("gesture_debug", {}).get("uppercut", {}).get("left", {})
	assert_true(bool(left_debug.get("depth_gate_applied", false)))
	assert_true(bool(left_debug.get("depth_gate_passed", false)))
	assert_true(float(left_debug.get("depth_peak_closeness", 0.0)) <= 0.06)

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
	assert_true(float(left_debug.get("recent_peak_wrist_velocity", 0.0)) >= float(left_debug.get("wrist_velocity", 0.0)))
	assert_eq(String(left_debug.get("state", "")), "triggered")

func test_straight_punch_pose_only_mode_uses_calibrated_shoulder_width_when_live_width_is_missing() -> void:
	_disable_hand_tracking_for_straight_punch()
	_calibrate_stance()
	substrate.process_landmarks(_make_pose_frame(), 1100)
	var state := substrate.process_landmarks(_make_pose_frame({
		PoseLandmarkIds.RIGHT_SHOULDER: {"x": 0.40, "v": 0.2},
		PoseLandmarkIds.LEFT_SHOULDER: {"x": 0.40},
		PoseLandmarkIds.LEFT_WRIST: {"z": -0.02},
	}), 1140)
	var left_debug: Dictionary = state.get("gesture_debug", {}).get("straight_punch", {}).get("left", {})
	assert_eq(_straight_punch_state_names(state.get("events", []), "left"), ["ready"])
	assert_true(bool(left_debug.get("pose_tracking_valid", false)))
	assert_ne(String(left_debug.get("pose_reference_shoulder_width_source", "")), "missing")
	assert_true(float(left_debug.get("pose_reference_shoulder_width", 0.0)) > 0.0)

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
		PoseLandmarkIds.RIGHT_WRIST: {"x": 0.64, "y": 0.60},
	}), 1320)
	assert_true(_event_names(state.get("events", [])).has("hook_right"))
	assert_eq(_pose_strike_state_names(state.get("events", []), "hook", "right"), ["triggered"])
	var right_debug: Dictionary = state.get("gesture_debug", {}).get("hook", {}).get("right", {})
	assert_eq(String(right_debug.get("state", "")), "triggered")
	assert_eq(int(right_debug.get("window_ms", 0)), 160)
	assert_true(float(right_debug.get("horizontal_direction_velocity", 0.0)) >= float(right_debug.get("min_velocity", 1.0)))
	assert_true(float(right_debug.get("wrist_angle_from_elbow_horizontal_deg", 99.0)) <= float(right_debug.get("max_wrist_angle_from_elbow_horizontal_deg", 0.0)))
	assert_true(bool(right_debug.get("wrist_horizontal_angle_gate_passed", false)))
	assert_true(bool(right_debug.get("wrist_on_required_hook_side", false)))
	assert_eq(String(right_debug.get("required_hook_side_label", "")), "right_of_elbow")
	assert_true(absf(float(right_debug.get("outward_distance", 0.0))) >= 0.0)
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
	assert_true(float(left_debug.get("wrist_angle_from_elbow_vertical_deg", 99.0)) <= float(left_debug.get("max_wrist_angle_from_elbow_vertical_deg", 0.0)))
	assert_true(bool(left_debug.get("wrist_vertical_angle_gate_passed", false)))
	assert_true(bool(left_debug.get("wrist_above_elbow_gate_passed", false)))
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
		PoseLandmarkIds.RIGHT_WRIST: {"x": 0.64, "y": 0.60},
	}), 1320)
	assert_true(_event_names(state.get("events", [])).has("hook_right"))

	state = substrate.process_landmarks(_make_pose_frame(), 40)
	assert_false(_event_names(state.get("events", [])).has("hook_right"))
	var right_debug: Dictionary = state.get("gesture_debug", {}).get("hook", {}).get("right", {})
	assert_eq(String(right_debug.get("state", "")), "tracking_lost")
	assert_eq(int(right_debug.get("window_span_ms", -1)), 0)
	assert_true(is_equal_approx(float(right_debug.get("wrist_velocity", -1.0)), 0.0))

func test_hook_requires_wrist_on_correct_mirrored_elbow_side() -> void:
	_calibrate_stance()
	var state := substrate.process_landmarks(_make_pose_frame(), 1000)
	state = substrate.process_landmarks(_make_pose_frame(), 1160)
	assert_eq(String(state.get("gesture_debug", {}).get("hook", {}).get("left", {}).get("state", "")), "ready")

	state = substrate.process_landmarks(_make_pose_frame({
		PoseLandmarkIds.LEFT_ELBOW: {"x": 0.20, "y": 0.62},
		PoseLandmarkIds.LEFT_WRIST: {"x": 0.32, "y": 0.60},
	}), 1320)
	assert_false(_event_names(state.get("events", [])).has("hook_left"))
	var left_debug: Dictionary = state.get("gesture_debug", {}).get("hook", {}).get("left", {})
	assert_true(bool(left_debug.get("wrist_horizontal_angle_gate_passed", false)))
	assert_false(bool(left_debug.get("wrist_on_required_hook_side", true)))
	assert_eq(String(left_debug.get("required_hook_side_label", "")), "left_of_elbow")
	assert_eq(String(left_debug.get("state", "")), "ready")

func test_hook_requires_wrist_on_correct_mirrored_elbow_side_for_right_arm() -> void:
	_calibrate_stance()
	var state := substrate.process_landmarks(_make_pose_frame(), 2000)
	state = substrate.process_landmarks(_make_pose_frame(), 2160)
	assert_eq(String(state.get("gesture_debug", {}).get("hook", {}).get("right", {}).get("state", "")), "ready")

	state = substrate.process_landmarks(_make_pose_frame({
		PoseLandmarkIds.RIGHT_ELBOW: {"x": 0.80, "y": 0.62},
		PoseLandmarkIds.RIGHT_WRIST: {"x": 0.68, "y": 0.60},
	}), 2320)
	assert_false(_event_names(state.get("events", [])).has("hook_right"))
	var right_debug: Dictionary = state.get("gesture_debug", {}).get("hook", {}).get("right", {})
	assert_true(bool(right_debug.get("wrist_horizontal_angle_gate_passed", false)))
	assert_false(bool(right_debug.get("wrist_on_required_hook_side", true)))
	assert_eq(String(right_debug.get("required_hook_side_label", "")), "right_of_elbow")
	assert_eq(String(right_debug.get("state", "")), "ready")

func test_uppercut_requires_wrist_above_elbow_in_camera_space() -> void:
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
	assert_true(bool(left_debug.get("wrist_vertical_angle_gate_passed", false)))
	assert_false(bool(left_debug.get("wrist_above_elbow_gate_passed", true)))
	assert_eq(String(left_debug.get("state", "")), "ready")

func test_hook_alignment_angle_gate_participates_honestly() -> void:
	config.gesture_profile_document = {
		"hook": {
			"enabled": true,
			"evaluation": {
				"window_ms": 160,
			},
			"thresholds": {
				"min_velocity": 0.6,
				"max_wrist_angle_from_elbow_horizontal_deg": 20.0,
			},
		},
	}
	substrate = PoseDetectorSubstrate.new().configure(config)
	_calibrate_stance()
	var state := substrate.process_landmarks(_make_pose_frame(), 3000)
	state = substrate.process_landmarks(_make_pose_frame(), 3160)
	assert_eq(String(state.get("gesture_debug", {}).get("hook", {}).get("left", {}).get("state", "")), "ready")

	state = substrate.process_landmarks(_make_pose_frame({
		PoseLandmarkIds.LEFT_ELBOW: {"x": 0.43, "y": 0.70},
		PoseLandmarkIds.LEFT_WRIST: {"x": 0.31, "y": 0.73},
	}), 3320)
	assert_true(_event_names(state.get("events", [])).has("hook_left"))
	var left_debug: Dictionary = state.get("gesture_debug", {}).get("hook", {}).get("left", {})
	assert_true(float(left_debug.get("wrist_angle_from_elbow_horizontal_deg", 99.0)) <= float(left_debug.get("max_wrist_angle_from_elbow_horizontal_deg", 0.0)))
	assert_true(bool(left_debug.get("wrist_horizontal_angle_gate_passed", false)))
	assert_true(bool(left_debug.get("wrist_on_required_hook_side", false)))
	assert_eq(String(left_debug.get("required_hook_side_label", "")), "left_of_elbow")

func test_uppercut_alignment_angle_gate_participates_honestly() -> void:
	config.gesture_profile_document = {
		"uppercut": {
			"enabled": true,
			"evaluation": {
				"window_ms": 160,
			},
			"thresholds": {
				"min_velocity": 0.5,
				"max_wrist_angle_from_elbow_vertical_deg": 20.0,
			},
		},
	}
	substrate = PoseDetectorSubstrate.new().configure(config)
	_calibrate_stance()
	var state := substrate.process_landmarks(_make_pose_frame(), 4000)
	state = substrate.process_landmarks(_make_pose_frame(), 4160)
	assert_eq(String(state.get("gesture_debug", {}).get("uppercut", {}).get("left", {}).get("state", "")), "ready")

	state = substrate.process_landmarks(_make_pose_frame({
		PoseLandmarkIds.LEFT_ELBOW: {"x": 0.38, "y": 0.74},
		PoseLandmarkIds.LEFT_WRIST: {"x": 0.35, "y": 0.84},
	}), 4320)
	assert_true(_event_names(state.get("events", [])).has("uppercut_left"))
	var left_debug: Dictionary = state.get("gesture_debug", {}).get("uppercut", {}).get("left", {})
	assert_true(float(left_debug.get("wrist_angle_from_elbow_vertical_deg", 99.0)) <= float(left_debug.get("max_wrist_angle_from_elbow_vertical_deg", 0.0)))
	assert_true(bool(left_debug.get("wrist_vertical_angle_gate_passed", false)))
	assert_true(bool(left_debug.get("wrist_above_elbow_gate_passed", false)))

func test_hook_alignment_angle_gate_blocks_even_when_velocity_is_high() -> void:
	config.gesture_profile_document = {
		"hook": {
			"enabled": true,
			"evaluation": {
				"window_ms": 160,
			},
			"thresholds": {
				"min_velocity": 0.6,
				"max_wrist_angle_from_elbow_horizontal_deg": 20.0,
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
		PoseLandmarkIds.LEFT_WRIST: {"x": 0.36, "y": 0.80},
	}), 1320)
	assert_false(_event_names(state.get("events", [])).has("hook_left"))
	var left_debug: Dictionary = state.get("gesture_debug", {}).get("hook", {}).get("left", {})
	assert_eq(int(left_debug.get("window_ms", 0)), 160)
	assert_eq(int(left_debug.get("window_span_ms", 0)), 160)
	assert_true(float(left_debug.get("wrist_velocity", 0.0)) >= float(left_debug.get("min_velocity", 0.0)))
	assert_true(float(left_debug.get("wrist_angle_from_elbow_horizontal_deg", 0.0)) > float(left_debug.get("max_wrist_angle_from_elbow_horizontal_deg", 99.0)))
	assert_false(bool(left_debug.get("wrist_horizontal_angle_gate_passed", true)))
	assert_true(bool(left_debug.get("wrist_on_required_hook_side", false)))

func test_uppercut_alignment_angle_gate_blocks_even_when_velocity_is_high() -> void:
	config.gesture_profile_document = {
		"uppercut": {
			"enabled": true,
			"evaluation": {
				"window_ms": 160,
			},
			"thresholds": {
				"min_velocity": 0.5,
				"max_wrist_angle_from_elbow_vertical_deg": 20.0,
			},
		},
	}
	substrate = PoseDetectorSubstrate.new().configure(config)
	_calibrate_stance()
	var state := substrate.process_landmarks(_make_pose_frame(), 2000)
	state = substrate.process_landmarks(_make_pose_frame(), 2160)
	assert_eq(String(state.get("gesture_debug", {}).get("uppercut", {}).get("left", {}).get("state", "")), "ready")

	state = substrate.process_landmarks(_make_pose_frame({
		PoseLandmarkIds.LEFT_ELBOW: {"x": 0.34, "y": 0.74},
		PoseLandmarkIds.LEFT_WRIST: {"x": 0.40, "y": 0.80},
	}), 2320)
	assert_false(_event_names(state.get("events", [])).has("uppercut_left"))
	var left_debug: Dictionary = state.get("gesture_debug", {}).get("uppercut", {}).get("left", {})
	assert_eq(int(left_debug.get("window_ms", 0)), 160)
	assert_eq(int(left_debug.get("window_span_ms", 0)), 160)
	assert_true(float(left_debug.get("wrist_velocity", 0.0)) >= float(left_debug.get("min_velocity", 0.0)))
	assert_true(float(left_debug.get("wrist_angle_from_elbow_vertical_deg", 0.0)) > float(left_debug.get("max_wrist_angle_from_elbow_vertical_deg", 99.0)))
	assert_false(bool(left_debug.get("wrist_vertical_angle_gate_passed", true)))
	assert_true(bool(left_debug.get("wrist_above_elbow_gate_passed", false)))

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

func test_quantizes_flow_direction_to_eight_direction_slots() -> void:
	assert_eq(substrate._flow_direction_index_from_vector(Vector2(0.0, 1.0)), 0)
	assert_eq(substrate._flow_direction_index_from_vector(Vector2(0.0, -1.0)), 1)
	assert_eq(substrate._flow_direction_index_from_vector(Vector2(-1.0, 0.0)), 2)
	assert_eq(substrate._flow_direction_index_from_vector(Vector2(1.0, 0.0)), 3)

func test_quantizes_flow_cells_from_nose_anchored_grid() -> void:
	_calibrate_stance()
	var first_cell := substrate._flow_cell_index_from_position(Vector2(0.40, 0.72))
	var second_cell := substrate._flow_cell_index_from_position(Vector2(0.48, 0.72))
	var third_cell := substrate._flow_cell_index_from_position(Vector2(0.56, 0.72))
	var fourth_cell := substrate._flow_cell_index_from_position(Vector2(0.64, 0.72))
	assert_true(first_cell >= 0)
	assert_true(second_cell >= first_cell)
	assert_true(third_cell >= second_cell)
	assert_true(fourth_cell >= third_cell)
	assert_true(first_cell != fourth_cell)

func test_detects_flow_cell_entry_events_and_surfaces_debug_truth() -> void:
	_calibrate_stance()
	substrate.process_landmarks(_make_pose_frame({
		PoseLandmarkIds.LEFT_WRIST: {"x": 0.48, "y": 0.72},
	}), 1100)
	var flow_state := substrate.process_landmarks(_make_pose_frame({
		PoseLandmarkIds.LEFT_WRIST: {"x": 0.39, "y": 0.72},
	}), 1200)
	var flow_events := _flow_events(flow_state.get("events", []))
	assert_eq(flow_events.size(), 1)
	assert_eq(flow_events[0]["name"], "flow_left_cell_entered")
	assert_eq(int(flow_events[0]["cell"]), 4)
	var emitted_direction := int(flow_events[0]["direction"])
	assert_true(emitted_direction >= 0)
	var left_flow: Dictionary = flow_state.get("gesture_debug", {}).get("flow", {}).get("left", {})
	assert_eq(int(left_flow.get("current_cell", -1)), 4)
	assert_true(int(left_flow.get("history_points", 0)) >= 2)
	assert_eq(int(left_flow.get("cell_meta", {}).get("previous_cell", -1)), 5)
	assert_eq(int(left_flow.get("cell_meta", {}).get("current_cell", -1)), 4)
	assert_eq(int(left_flow.get("cell_meta", {}).get("direction", -1)), emitted_direction)

func test_flow_debug_surfaces_shared_grid_and_nose_wrist_truth() -> void:
	_calibrate_stance()
	var state := substrate.process_landmarks(_make_pose_frame({
		PoseLandmarkIds.NOSE: {"x": 0.58, "y": 0.80},
		PoseLandmarkIds.LEFT_WRIST: {"x": 0.39, "y": 0.72},
		PoseLandmarkIds.RIGHT_WRIST: {"x": 0.65, "y": 0.72},
	}), 1200)
	var flow_debug: Dictionary = state.get("gesture_debug", {}).get("flow", {})
	var grid_debug: Dictionary = flow_debug.get("grid", {})
	assert_true(bool(grid_debug.get("is_calibrated", false)))
	assert_eq(int(grid_debug.get("columns", 0)), 4)
	assert_eq(int(grid_debug.get("rows", 0)), 3)
	assert_eq((grid_debug.get("cell_rects", []) as Array).size(), 12)
	var tracked_landmarks: Dictionary = flow_debug.get("tracked_landmarks", {})
	var nose_debug: Dictionary = tracked_landmarks.get("nose", {})
	var left_wrist_debug: Dictionary = tracked_landmarks.get("left_wrist", {})
	var right_wrist_debug: Dictionary = tracked_landmarks.get("right_wrist", {})
	assert_eq(String(nose_debug.get("landmark_key", "")), "nose")
	assert_eq(String(left_wrist_debug.get("landmark_key", "")), "left_wrist")
	assert_eq(String(right_wrist_debug.get("landmark_key", "")), "right_wrist")
	assert_true(int(nose_debug.get("current_cell", -1)) >= 0)
	assert_true(int(left_wrist_debug.get("current_cell", -1)) >= 0)
	assert_true(int(right_wrist_debug.get("current_cell", -1)) >= 0)

func test_request_athlete_recalibration_starts_shared_countdown_session() -> void:
	_calibrate_stance()
	substrate.request_athlete_recalibration()
	var state := substrate.get_latest_state()
	var session: Dictionary = state.get("calibration_session", {})
	assert_eq(String(session.get("state", "")), "countdown")
	assert_true(bool(session.get("is_active", false)))
	assert_eq(int(session.get("seconds_remaining", 0)), 5)
	assert_false(bool(state.get("baseline", {}).get("is_calibrated", true)))
	assert_true(state.get("metrics", {}).has("calibration_session"))
	assert_eq(String(session.get("readiness", {}).get("instruction_text", "")), "Need tracking/reacquiring plus both wrists visible")
	assert_eq(String(session.get("instructions", {}).get("show_both_wrists", {}).get("text", "")), "Both wrists stay visible")
	assert_eq(String(session.get("instructions", {}).get("capture_frames", {}).get("text", "")), "Capture 5 valid frames during the live window")

func test_calibration_readiness_only_requires_live_left_and_right_wrist_data() -> void:
	_calibrate_stance()
	substrate.request_athlete_recalibration()
	var state := substrate.process_landmarks(_make_pose_frame({}, 0.70), 6100)
	var session: Dictionary = state.get("calibration_session", {})
	var readiness: Dictionary = session.get("readiness", {})
	assert_eq(String(session.get("state", "")), "capturing")
	assert_true(bool(readiness.get("ready", false)))
	assert_true(bool(readiness.get("centered_in_camera", false)))
	assert_true(bool(readiness.get("t_pose_ready", false)))
	assert_eq(String(readiness.get("instruction_text", "")), "Capture window is live — keep both wrists visible for 5 valid frames")

	var missing_wrist_readiness: Dictionary = substrate.call("_evaluate_calibration_readiness", {}, StringName("tracking"), {})
	assert_false(bool(missing_wrist_readiness.get("ready", true)))
	assert_eq(String(missing_wrist_readiness.get("failure_reason", "")), "missing_wrist_landmarks")
	assert_eq(String(missing_wrist_readiness.get("instruction_text", "")), "Need both wrists visible before capture can start")

	var missing_tracking_readiness: Dictionary = substrate.call("_evaluate_calibration_readiness", {}, StringName("lost"), {})
	assert_false(bool(missing_tracking_readiness.get("ready", true)))
	assert_eq(String(missing_tracking_readiness.get("failure_reason", "")), "tracking_lost")
	assert_eq(String(missing_tracking_readiness.get("instruction_text", "")), "Need tracking or reacquiring before capture can start")

func test_calibration_session_commits_baseline_only_after_countdown_and_capture_window() -> void:
	_calibrate_stance()
	substrate.request_athlete_recalibration()
	var state := substrate.process_landmarks(_make_pose_frame({}, 0.70), 6100)
	assert_eq(String(state.get("calibration_session", {}).get("state", "")), "capturing")
	for idx in range(5):
		state = substrate.process_landmarks(_make_pose_frame(), 6120 + idx * 16)
	var baseline: Dictionary = state.get("baseline", {})
	var session: Dictionary = state.get("calibration_session", {})
	assert_true(bool(baseline.get("is_calibrated", false)))
	assert_eq(String(baseline.get("capture_source", "")), "calibration_session")
	assert_eq(int(baseline.get("sample_frames", 0)), 5)
	assert_eq(String(session.get("state", "")), "succeeded")
	assert_eq(int(session.get("captured_sample_frames", 0)), 5)

func test_calibration_session_waits_through_boundary_blip_before_capture() -> void:
	_calibrate_stance()
	substrate.request_athlete_recalibration()
	substrate.call("_update_calibration_session", 6100, {
		"ready": false,
		"failure_reason": "missing_wrist_landmarks",
	})
	var session: Dictionary = substrate.get_calibration_session()
	assert_eq(String(session.get("state", "")), "capture_pending")
	assert_true(bool(session.get("is_active", false)))
	assert_eq(String(session.get("failure_reason", "")), "missing_wrist_landmarks")
	var state := substrate.get_latest_state()
	for idx in range(5):
		state = substrate.process_landmarks(_make_pose_frame(), 6120 + idx * 16)
	var baseline: Dictionary = state.get("baseline", {})
	session = state.get("calibration_session", {})
	assert_true(bool(baseline.get("is_calibrated", false)))
	assert_eq(String(session.get("state", "")), "succeeded")

func test_calibration_session_tolerates_brief_live_capture_dropout_within_window() -> void:
	_calibrate_stance()
	substrate.request_athlete_recalibration()
	var state := substrate.process_landmarks(_make_pose_frame({}, 0.70), 6100)
	assert_eq(String(state.get("calibration_session", {}).get("state", "")), "capturing")
	state = substrate.process_landmarks(_make_pose_frame(), 6120)
	substrate.call("_update_calibration_session", 6136, {
		"ready": false,
		"failure_reason": "missing_wrist_landmarks",
	})
	var pending_session: Dictionary = substrate.get_calibration_session()
	assert_eq(String(pending_session.get("state", "")), "capture_pending")
	assert_true(bool(pending_session.get("is_active", false)))
	for idx in range(3):
		state = substrate.process_landmarks(_make_pose_frame(), 6152 + idx * 16)
	var baseline: Dictionary = state.get("baseline", {})
	var session: Dictionary = state.get("calibration_session", {})
	assert_true(bool(baseline.get("is_calibrated", false)))
	assert_eq(String(session.get("state", "")), "succeeded")

func test_calibration_session_fails_when_countdown_finishes_without_wrist_data() -> void:
	_calibrate_stance()
	substrate.request_athlete_recalibration()
	substrate.call("_update_calibration_session", 6100, {
		"ready": false,
		"failure_reason": "required_wrist_data_unavailable",
	})
	var session: Dictionary = substrate.get_calibration_session()
	var state := substrate.get_latest_state()
	assert_eq(String(session.get("state", "")), "capture_pending")
	assert_true(bool(session.get("is_active", false)))
	assert_false(bool(state.get("baseline", {}).get("is_calibrated", true)))
	assert_eq(String(session.get("failure_reason", "")), "required_wrist_data_unavailable")
	substrate.call("_update_calibration_session", 9201, {
		"ready": false,
		"failure_reason": "required_wrist_data_unavailable",
	})
	session = substrate.get_calibration_session()
	assert_eq(String(session.get("state", "")), "failed")
	assert_eq(String(session.get("failure_reason", "")), "required_wrist_data_unavailable")

func test_cancel_athlete_recalibration_keeps_runtime_uncalibrated_until_retry() -> void:
	_calibrate_stance()
	substrate.request_athlete_recalibration()
	substrate.cancel_athlete_recalibration()
	var state := substrate.get_latest_state()
	assert_eq(String(state.get("calibration_session", {}).get("state", "")), "cancelled")
	for idx in range(5):
		state = substrate.process_landmarks(_make_pose_frame(), 6100 + idx * 16)
	assert_false(bool(state.get("baseline", {}).get("is_calibrated", true)))

func test_squat_uses_nose_grid_avoidance_and_surfaces_debug_truth() -> void:
	config.gesture_profile_document = {
		"squat": {
			"backend": "grid_avoidance",
			"grid_avoidance": {
				"obstacle": {
					"label": "top_row",
					"occupied_rows": [0],
					"occupied_cells": [0, 1, 2, 3],
				}
			}
		}
	}
	substrate = PoseDetectorSubstrate.new().configure(config)
	_calibrate_stance()

	var blocked_state := substrate.process_landmarks(_make_pose_frame({
		PoseLandmarkIds.NOSE: {"x": 0.50, "y": 0.84},
	}), 1200)
	assert_false(_event_names(blocked_state.get("events", [])).has("squat_start"))
	var squat_debug: Dictionary = blocked_state.get("gesture_debug", {}).get("squat", {})
	assert_eq(String(squat_debug.get("backend", "")), "grid_avoidance")
	assert_false(bool(squat_debug.get("state", true)))
	assert_eq(int(squat_debug.get("current_cell", -1)), 2)
	assert_eq(squat_debug.get("occupied_cells", []), [0, 1, 2, 3])
	assert_true(bool(squat_debug.get("nose_in_blocked_region", false)))
	assert_false(bool(squat_debug.get("avoidance_clear", true)))

	var clear_state := substrate.process_landmarks(_make_pose_frame({
		PoseLandmarkIds.NOSE: {"x": 0.50, "y": 0.72},
	}), 1300)
	assert_true(_event_names(clear_state.get("events", [])).has("squat_start"))
	squat_debug = clear_state.get("gesture_debug", {}).get("squat", {})
	assert_true(bool(squat_debug.get("state", false)))
	assert_eq(int(squat_debug.get("current_cell", -1)), 6)
	assert_false(bool(squat_debug.get("nose_in_blocked_region", true)))
	assert_true(bool(squat_debug.get("avoidance_clear", false)))

func test_weave_uses_nose_grid_avoidance_and_surfaces_debug_truth() -> void:
	config.gesture_profile_document = {
		"weave": {
			"backend": "grid_avoidance",
			"grid_avoidance": {
				"left_obstacle": {
					"label": "left_columns",
					"occupied_columns": [0, 1],
					"occupied_cells": [0, 1, 4, 5, 8, 9],
				},
				"right_obstacle": {
					"label": "right_columns",
					"occupied_columns": [2, 3],
					"occupied_cells": [2, 3, 6, 7, 10, 11],
				},
			}
		}
	}
	substrate = PoseDetectorSubstrate.new().configure(config)
	_calibrate_stance()

	var blocked_left_state := substrate.process_landmarks(_make_pose_frame({
		PoseLandmarkIds.NOSE: {"x": 0.45, "y": 0.72},
	}), 1100)
	assert_false(_event_names(blocked_left_state.get("events", [])).has("weave_left_start"))
	var weave_left_state := substrate.process_landmarks(_make_pose_frame({
		PoseLandmarkIds.NOSE: {"x": 0.56, "y": 0.72},
	}), 1200)
	assert_true(_event_names(weave_left_state.get("events", [])).has("weave_left_start"))
	var weave_debug: Dictionary = weave_left_state.get("gesture_debug", {}).get("weave", {})
	assert_eq(String(weave_debug.get("backend", "")), "grid_avoidance")
	assert_eq(String(weave_debug.get("state", "")), "left")
	assert_eq(int(weave_debug.get("current_cell", -1)), 6)
	assert_true(bool(weave_debug.get("left_candidate", false)))
	assert_false(bool(weave_debug.get("right_candidate", true)))
	assert_false(bool(weave_debug.get("neutral_candidate", true)))
	assert_eq(_weave_obstacle_cells(weave_debug, "left_obstacle"), [0, 1, 4, 5, 8, 9])
	assert_true(bool(_weave_obstacle_debug(weave_debug, "left_obstacle").get("avoidance_clear", false)))
	assert_true(bool(_weave_obstacle_debug(weave_debug, "right_obstacle").get("nose_in_blocked_region", false)))

	var weave_end_state := substrate.process_landmarks(_make_pose_frame({
		PoseLandmarkIds.NOSE: {"x": 0.45, "y": 0.72},
	}), 1300)
	assert_true(_event_names(weave_end_state.get("events", [])).has("weave_left_end"))
	weave_debug = weave_end_state.get("gesture_debug", {}).get("weave", {})
	assert_eq(String(weave_debug.get("state", "")), "right")
	assert_false(bool(weave_debug.get("neutral_candidate", true)))

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

func test_weave_remains_active_only_while_nose_stays_outside_the_blocked_columns() -> void:
	_calibrate_stance()
	var blocked_left_state := substrate.process_landmarks(_make_pose_frame({
		PoseLandmarkIds.NOSE: {"x": 0.45, "y": 0.72},
	}), 1100)
	assert_false(_event_names(blocked_left_state.get("events", [])).has("weave_left_start"))
	var weave_left_start_state := substrate.process_landmarks(_make_pose_frame({
		PoseLandmarkIds.NOSE: {"x": 0.56, "y": 0.72},
	}), 1200)
	assert_true(_event_names(weave_left_start_state.get("events", [])).has("weave_left_start"))
	var held_weave_state := substrate.process_landmarks(_make_pose_frame({
		PoseLandmarkIds.NOSE: {"x": 0.60, "y": 0.72},
	}), 1300)
	assert_false(_event_names(held_weave_state.get("events", [])).has("weave_left_start"))
	assert_false(_event_names(held_weave_state.get("events", [])).has("weave_left_end"))
	var held_weave_debug: Dictionary = held_weave_state.get("gesture_debug", {}).get("weave", {})
	assert_eq(String(held_weave_debug.get("state", "")), "left")
	assert_true(bool(held_weave_debug.get("left_candidate", false)))
	var weave_end_state := substrate.process_landmarks(_make_pose_frame({
		PoseLandmarkIds.NOSE: {"x": 0.45, "y": 0.72},
	}), 1400)
	assert_true(_event_names(weave_end_state.get("events", [])).has("weave_left_end"))

func test_straight_same_family_trigger_exposes_threshold_blocking_truth_while_blocking_side_is_not_ready() -> void:
	_calibrate_stance()
	var state := substrate.process_landmarks(_make_pose_frame(), 1100, _make_tracking_frame(_tracked_hand_payload_physical("left", 0.020), _tracked_hand_payload_physical("right", 0.020)))
	state = substrate.process_landmarks(_make_pose_frame({
		PoseLandmarkIds.RIGHT_WRIST: {"z": -0.04},
	}), 1180, _make_tracking_frame(_tracked_hand_payload_physical("left", 0.020), _tracked_hand_payload_physical("right", 0.021, "tracked", true, 0, 1, 0.0, null, "", 80)))
	assert_eq(String(state.get("gesture_debug", {}).get("straight_punch", {}).get("right", {}).get("state", "")), "ready")

	var left_state: Dictionary = substrate.call("_build_straight_punch_state", PoseDetectorSubstrate.STRAIGHT_PUNCH_STATE_NOT_READY)
	left_state["not_ready_started_timestamp_ms"] = 1200
	left_state["trigger_bbox_area"] = 0.0275
	left_state["current_timestamp_ms"] = 1200
	substrate.call("_set_straight_punch_state", "left", left_state)

	state = substrate.process_landmarks(_make_pose_frame({
		PoseLandmarkIds.RIGHT_WRIST: {"z": -0.12},
	}), 1260, _make_tracking_frame(_tracked_hand_payload_physical("left", 0.0275), _tracked_hand_payload_physical("right", 0.0240)))
	state = substrate.process_landmarks(_make_pose_frame({
		PoseLandmarkIds.RIGHT_WRIST: {"z": -0.20},
	}), 1340, _make_tracking_frame(_tracked_hand_payload_physical("left", 0.0275), _tracked_hand_payload_physical("right", 0.0272)))
	assert_false(_event_names(state.get("events", [])).has("punch_right"))
	var right_debug: Dictionary = state.get("gesture_debug", {}).get("straight_punch", {}).get("right", {})
	assert_eq(String(right_debug.get("state", "")), "ready")
	assert_true(bool(right_debug.get("same_family_blocked", false)))
	assert_eq(String(right_debug.get("blocking_family", "")), "straight_punch")
	assert_eq(String(right_debug.get("blocking_side", "")), "left")
	assert_eq(String(right_debug.get("blocking_event_name", "")), "punch_left")
	assert_eq(String(right_debug.get("blocking_phase", "")), "not_ready")

func test_hook_same_family_trigger_exposes_threshold_blocking_truth() -> void:
	_calibrate_stance()
	substrate.process_landmarks(_make_pose_frame(), 3000)
	substrate.process_landmarks(_make_pose_frame(), 3160)
	var right_state: Dictionary = substrate.call("_build_pose_strike_state", PoseDetectorSubstrate.POSE_STRIKE_STATE_TRIGGERED)
	right_state["grace_deadline_timestamp_ms"] = 3400
	right_state["grace_ms_remaining"] = 80
	right_state["timestamp_ms"] = 3200
	substrate.call("_set_pose_strike_state", "hook", "right", right_state)

	var blocking_state: Dictionary = substrate.call("_get_same_family_threshold_blocking_state", "hook", "left", 3320)
	assert_eq(String(blocking_state.get("family", "")), "hook")
	assert_eq(String(blocking_state.get("blocking_side", "")), "right")
	assert_eq(String(blocking_state.get("blocking_event_name", "")), "hook_right")
	assert_eq(String(blocking_state.get("blocking_phase", "")), "triggered")

	var left_state: Dictionary = substrate.call("_build_pose_strike_state", PoseDetectorSubstrate.POSE_STRIKE_STATE_READY)
	substrate.call("_apply_same_family_block", left_state, blocking_state)
	assert_true(bool(left_state.get("same_family_blocked", false)))
	assert_eq(String(left_state.get("blocking_family", "")), "hook")
	assert_eq(String(left_state.get("blocking_side", "")), "right")
	assert_eq(String(left_state.get("blocking_event_name", "")), "hook_right")
	assert_eq(String(left_state.get("blocking_phase", "")), "triggered")

func test_disabled_family_backend_prevents_any_punch_runtime_activation() -> void:
	config.tracker_profile_document = {
		"tracking": {
			"hands": {
				"enabled": false,
			},
		},
	}
	config.gesture_profile_document = {
		"straight_punch": {"backend": "disabled"},
		"hook": {"backend": "disabled"},
		"uppercut": {"backend": "disabled"},
	}
	substrate = PoseDetectorSubstrate.new().configure(config)
	_calibrate_stance()
	var state := substrate.process_landmarks(_make_pose_frame(), 1100)
	var punch_detection_debug: Dictionary = state.get("gesture_debug", {}).get("punch_detection", {})
	assert_eq(String(punch_detection_debug.get("selected_backend", "")), "per_family")
	assert_false(bool(punch_detection_debug.get("selected_backend_enabled", true)))
	assert_eq(String(punch_detection_debug.get("active_backend_resolution", "")), "no_active_family_backend")
	assert_eq(String(punch_detection_debug.get("active_backend", "")), "none")
	assert_eq(String(punch_detection_debug.get("straight_backend", "")), "disabled")
	assert_eq(String(punch_detection_debug.get("hook_backend", "")), "disabled")
	assert_eq(String(punch_detection_debug.get("uppercut_backend", "")), "disabled")

func test_disabled_straight_family_suppresses_punch_events_while_threshold_families_stay_live() -> void:
	config.gesture_profile_document = {
		"straight_punch": {"backend": "disabled"},
		"hook": {"backend": "threshold", "threshold": _default_hook_threshold_block()},
		"uppercut": {"backend": "threshold", "threshold": _default_uppercut_threshold_block()},
	}
	substrate = PoseDetectorSubstrate.new().configure(config)
	_calibrate_stance()
	var state := substrate.process_landmarks(_make_pose_frame({
		PoseLandmarkIds.LEFT_ELBOW: {"x": 0.34, "y": 0.66, "z": 0.0},
		PoseLandmarkIds.LEFT_WRIST: {"x": 0.28, "y": 0.60, "z": 0.0},
	}), 1400)
	assert_false(_event_names(state.get("events", [])).has("punch_left"))
	var punch_detection_debug: Dictionary = state.get("gesture_debug", {}).get("punch_detection", {})
	assert_eq(String(punch_detection_debug.get("straight_backend", "")), "disabled")
	assert_true(bool(punch_detection_debug.get("threshold_enabled", false)))

func _weave_obstacle_debug(weave_debug: Dictionary, key: String) -> Dictionary:
	return weave_debug.get(key, {}) if weave_debug.get(key, {}) is Dictionary else {}

func _weave_obstacle_cells(weave_debug: Dictionary, key: String) -> Array:
	return _weave_obstacle_debug(weave_debug, key).get("occupied_cells", []) as Array

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
		if not event_name.begins_with("flow_"):
			continue
		flow_events.append({
			"name": event_name,
			"cell": int(event_data.get("cell", -1)),
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

func _make_tracking_frame(left_hand: Dictionary = {}, right_hand: Dictionary = {}, extras: Dictionary = {}) -> Dictionary:
	var frame := {
		"hand_tracking": {
			"enabled": true,
			"available": true,
		},
		"hands": {
			"left": left_hand.duplicate(true),
			"right": right_hand.duplicate(true),
		},
	}
	for key_variant: Variant in extras.keys():
		var key := String(key_variant)
		frame[key] = extras.get(key_variant)
	return frame

func _depth_tracking_frame_extras(family: String, side: String, closeness: float, sample_source: String = "placeholder") -> Dictionary:
	return {
		"depth_runtime": {
			"families": {
				family: {
					side: {
						"status": "ready",
						"sample_metrics": {
							"wrist_closeness": closeness,
							"wrist_depth": maxf(0.0, 1.0 - closeness),
							"torso_depth": 1.0,
							"sample_source": sample_source,
							"sample_fresh": true,
						},
					},
				},
			},
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

func _default_hook_threshold_block() -> Dictionary:
	return {
		"evaluation": {"window_ms": 250},
		"thresholds": {
			"min_velocity": 0.4,
			"max_wrist_angle_from_elbow_horizontal_deg": 25.0,
		},
		"timing": {"triggered_grace_ms": 500},
		"rearm": {"pose_only_rearm_ms": 50},
		"state_machine": {"lost_tracking_reacquire_stable_ms": 40},
	}

func _default_uppercut_threshold_block() -> Dictionary:
	return {
		"evaluation": {"window_ms": 250},
		"thresholds": {
			"min_velocity": 0.5,
			"max_wrist_angle_from_elbow_vertical_deg": 25.0,
		},
		"timing": {"triggered_grace_ms": 500},
		"rearm": {"pose_only_rearm_ms": 50},
		"state_machine": {"lost_tracking_reacquire_stable_ms": 40},
	}

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
