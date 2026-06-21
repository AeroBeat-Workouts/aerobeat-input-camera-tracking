class_name PoseDetectorSubstrate
extends RefCounted

const PrototypePunchMatcher = preload("res://addons/aerobeat-input-camera-tracking/src/detectors/prototype_punch_matcher.gd")
const LearnedPunchClassifierScript = preload("res://addons/aerobeat-input-camera-tracking/src/detectors/learned_punch_classifier.gd")
const DepthRuntimeManagerScript = preload("res://addons/aerobeat-input-camera-tracking/src/depth/depth_runtime_manager.gd")
const DepthSharedRuntimePoolScript = preload("res://addons/aerobeat-input-camera-tracking/src/depth/depth_shared_runtime_pool.gd")
const BACKEND_DISABLED := "disabled"
const BACKEND_THRESHOLD := "threshold"
const BACKEND_PROTOTYPE := "prototype"
const BACKEND_CLASSIFIER := "classifier"
const PUNCH_FAMILIES := ["straight_punch", "hook", "uppercut"]
const PUNCH_FAMILY_EVENT_NAMES := {
	"straight_punch": ["punch_left", "punch_right"],
	"hook": ["hook_left", "hook_right"],
	"uppercut": ["uppercut_left", "uppercut_right"],
}

const TRACKING_TRACKING := &"tracking"
const TRACKING_DEGRADED := &"degraded"
const TRACKING_LOST := &"lost"
const TRACKING_REACQUIRING := &"reacquiring"

const STRAIGHT_PUNCH_STATE_READY := "ready"
const STRAIGHT_PUNCH_STATE_TRIGGERED := "triggered"
const STRAIGHT_PUNCH_STATE_NOT_READY := "not_ready"
const STRAIGHT_PUNCH_STATE_TRACKING_LOST := "tracking_lost"
const STRAIGHT_PUNCH_DEFAULT_FRESH_SAMPLES_ONLY := true
const STRAIGHT_PUNCH_DEFAULT_SAMPLE_WINDOW_SIZE := 4
const STRAIGHT_PUNCH_DEFAULT_MIN_POSITIVE_GROWTH_SAMPLES := 2
const STRAIGHT_PUNCH_DEFAULT_WRIST_VELOCITY_WINDOW_MS := 240
const STRAIGHT_PUNCH_DEFAULT_MIN_WRIST_VELOCITY := 0.18
const STRAIGHT_PUNCH_DEFAULT_MIN_BBOX_AREA_GROWTH := 0.006
const STRAIGHT_PUNCH_DEFAULT_MAX_ELBOW_SHOULDER_XY_DISTANCE := 0.09
const STRAIGHT_PUNCH_DEFAULT_MIN_WRIST_LATERAL_ANGLE_FROM_ELBOW_VERTICAL_DEG := 0.0
const STRAIGHT_PUNCH_DEFAULT_TRIGGERED_GRACE_MS := 240
const STRAIGHT_PUNCH_DEFAULT_BBOX_AREA_RETRACT_EPSILON := 0.003
const STRAIGHT_PUNCH_DEFAULT_REACQUIRE_STABLE_MS := 40
const STRAIGHT_PUNCH_DEFAULT_POSE_ONLY_REARM_MS := 250
const STRAIGHT_PUNCH_DEFAULT_REACQUIRE_STABLE_FRAMES := 2
const PUNCH_OWN_HALF_MARGIN_RATIO := 0.12

const POSE_STRIKE_STATE_READY := STRAIGHT_PUNCH_STATE_READY
const POSE_STRIKE_STATE_TRIGGERED := STRAIGHT_PUNCH_STATE_TRIGGERED
const POSE_STRIKE_STATE_NOT_READY := STRAIGHT_PUNCH_STATE_NOT_READY
const POSE_STRIKE_STATE_TRACKING_LOST := STRAIGHT_PUNCH_STATE_TRACKING_LOST
const POSE_STRIKE_DEFAULT_MIN_PUNCH_VELOCITY := STRAIGHT_PUNCH_DEFAULT_MIN_WRIST_VELOCITY
const POSE_STRIKE_DEFAULT_WINDOW_MS := 160
const POSE_STRIKE_DEFAULT_TRIGGERED_GRACE_MS := STRAIGHT_PUNCH_DEFAULT_TRIGGERED_GRACE_MS
const POSE_STRIKE_DEFAULT_POSE_ONLY_REARM_MS := STRAIGHT_PUNCH_DEFAULT_POSE_ONLY_REARM_MS
const POSE_STRIKE_DEFAULT_REACQUIRE_STABLE_MS := STRAIGHT_PUNCH_DEFAULT_REACQUIRE_STABLE_MS

const HOOK_DEFAULT_MAX_WRIST_ANGLE_FROM_ELBOW_HORIZONTAL_DEG := 25.0

const UPPERCUT_DEFAULT_MAX_WRIST_ANGLE_FROM_ELBOW_VERTICAL_DEG := 25.0

const GUARD_DEFAULT_MAX_WRIST_SEPARATION_X := 0.20
const GUARD_DEFAULT_MAX_WRIST_SEPARATION_Y := 0.12
const GUARD_DEFAULT_MAX_WRIST_NOSE_DISTANCE := 0.15
const SQUAT_DEFAULT_ENTER_HEIGHT_RATIO_MAX := 0.82
const SQUAT_DEFAULT_EXIT_HEIGHT_RATIO_MIN := 0.92
const WEAVE_DEFAULT_ENTER_HEAD_LATERAL_OFFSET_MIN := 0.30
const WEAVE_DEFAULT_ENTER_RELATIVE_HEAD_HIP_OFFSET_MIN := 0.12
const WEAVE_DEFAULT_ENTER_HEAD_DROP_RATIO_MIN := 0.05
const WEAVE_DEFAULT_EXIT_HEAD_LATERAL_OFFSET_MAX := 0.12
const WEAVE_DEFAULT_EXIT_RELATIVE_HEAD_HIP_OFFSET_MAX := 0.08

const FLOW_HISTORY_MAX_MS := 560
const FLOW_SWING_WINDOW_MIN_MS := 120
const FLOW_SWING_WINDOW_MAX_MS := 320
const FLOW_SWING_MIN_ARC_RATIO := 0.72
const FLOW_SWING_MIN_TRAVEL_RATIO := 0.42
const FLOW_SWING_MIN_SPEED_RATIO := 1.45
const FLOW_TRAIL_WINDOW_MIN_MS := 260
const FLOW_TRAIL_MIN_ARC_RATIO := 0.95
const FLOW_TRAIL_MIN_TRAVEL_RATIO := 0.34
const FLOW_TRAIL_MIN_SPEED_RATIO := 1.05
const FLOW_TRAIL_EMIT_INTERVAL_MS := 90
const FLOW_DIRECTION_RING_COUNT := 12
const FLOW_PLACEMENT_RING_COUNT := 13
const FLOW_PLACEMENT_CENTER_INDEX := FLOW_PLACEMENT_RING_COUNT - 1
const FLOW_PLACEMENT_CENTER_RADIUS_RATIO := 0.45
const FLOW_RING_SECTOR_DEGREES := 360.0 / float(FLOW_DIRECTION_RING_COUNT)
const FLOW_RING_START_ANGLE_DEGREES := 60.0

var _config = null
var _smoother: LandmarkSmoother = LandmarkSmoother.new()
var _prototype_punch_matcher: PrototypePunchMatcher = PrototypePunchMatcher.new()
var _learned_punch_classifier = LearnedPunchClassifierScript.new()
var _latest_state: Dictionary = {}
var _baseline_accumulator := {
	"frames": 0,
	"shoulder_width": 0.0,
	"torso_height": 0.0,
	"athlete_height": 0.0,
	"shoulder_center_x": 0.0,
	"hip_center_y": 0.0,
	"nose_y": 0.0,
	"left_knee_y": 0.0,
	"right_knee_y": 0.0,
	"left_ankle_y": 0.0,
	"right_ankle_y": 0.0,
}
var _baseline: Dictionary = {
	"is_calibrated": false,
	"sample_frames": 0,
	"shoulder_width": 0.0,
	"torso_height": 0.0,
	"athlete_height": 0.0,
	"shoulder_center_x": 0.0,
	"hip_center_y": 0.0,
	"nose_y": 0.0,
	"left_knee_y": 0.0,
	"right_knee_y": 0.0,
	"left_ankle_y": 0.0,
	"right_ankle_y": 0.0,
}
var _previous_positions: Dictionary = {}
var _gesture_state := {}
var _consecutive_valid_frames := 0
var _consecutive_invalid_frames := 0
var _reacquire_frames_remaining := 0
var _last_processed_timestamp_ms := 0
var _frame_index := 0
var _depth_runtime_managers := {}
var _depth_shared_runtime_pool: RefCounted = DepthSharedRuntimePoolScript.new()

func _init() -> void:
	_smoother = LandmarkSmoother.new(_get_smoothing_window_size(), _get_pose_smoothing_style())
	_prototype_punch_matcher = PrototypePunchMatcher.new()
	_learned_punch_classifier = LearnedPunchClassifierScript.new()
	_latest_state = _build_empty_state()
	_reset_gesture_state()
	_configure_depth_runtime_managers()

func configure(config) -> PoseDetectorSubstrate:
	_config = config
	_smoother = LandmarkSmoother.new(_get_smoothing_window_size(), _get_pose_smoothing_style())
	_prototype_punch_matcher.configure(config)
	_learned_punch_classifier.configure(config)
	_configure_depth_runtime_managers()
	return self

func reset() -> void:
	_smoother = LandmarkSmoother.new(_get_smoothing_window_size(), _get_pose_smoothing_style())
	_previous_positions.clear()
	_consecutive_valid_frames = 0
	_consecutive_invalid_frames = 0
	_reacquire_frames_remaining = 0
	_last_processed_timestamp_ms = 0
	_frame_index = 0
	_reset_baseline_calibration()
	_reset_gesture_state()
	_prototype_punch_matcher.reset()
	_learned_punch_classifier.reset()
	_latest_state = _build_empty_state()
	_configure_depth_runtime_managers()

func request_athlete_recalibration() -> void:
	_reset_baseline_calibration()
	_clear_transient_gesture_state()
	if _latest_state.is_empty():
		_latest_state = _build_empty_state()
		return

	var metrics: Dictionary = _latest_state.get("metrics", {})
	metrics["baseline"] = _baseline.duplicate(true)
	var measurements: Dictionary = metrics.get("measurements", {})
	measurements["height_ratio"] = 1.0
	measurements["height_state"] = StringName("unknown")
	measurements["squat_depth"] = 0.0
	metrics["measurements"] = measurements
	_latest_state["baseline"] = _baseline.duplicate(true)
	_latest_state["metrics"] = metrics
	_latest_state["events"] = []
	_latest_state["gesture_states"] = _build_public_gesture_states()
	_latest_state["gesture_debug"] = _build_gesture_debug_state(metrics)

func _reset_baseline_calibration() -> void:
	_baseline_accumulator = {
		"frames": 0,
		"shoulder_width": 0.0,
		"torso_height": 0.0,
		"athlete_height": 0.0,
		"shoulder_center_x": 0.0,
		"hip_center_y": 0.0,
		"nose_y": 0.0,
		"left_knee_y": 0.0,
		"right_knee_y": 0.0,
		"left_ankle_y": 0.0,
		"right_ankle_y": 0.0,
	}
	_baseline = {
		"is_calibrated": false,
		"sample_frames": 0,
		"shoulder_width": 0.0,
		"torso_height": 0.0,
		"athlete_height": 0.0,
		"shoulder_center_x": 0.0,
		"hip_center_y": 0.0,
		"nose_y": 0.0,
		"left_knee_y": 0.0,
		"right_knee_y": 0.0,
		"left_ankle_y": 0.0,
		"right_ankle_y": 0.0,
	}

func process_landmarks(landmarks: Array, timestamp_ms: int = 0, tracking_frame: Dictionary = {}) -> Dictionary:
	if timestamp_ms <= 0:
		timestamp_ms = Time.get_ticks_msec()
	if _last_processed_timestamp_ms > 0 and timestamp_ms < _last_processed_timestamp_ms:
		_reset_temporal_runtime_state_for_timestamp_rewind()
	_frame_index += 1
	var smoothed_landmarks: Dictionary = _smoother.push_landmarks(landmarks)
	var metrics: Dictionary = _build_metrics(smoothed_landmarks, timestamp_ms)
	var tracking_state: StringName = _update_tracking_state(smoothed_landmarks)
	_update_baseline(metrics, tracking_state, smoothed_landmarks)
	metrics["tracking_state"] = tracking_state
	metrics["baseline"] = _baseline.duplicate(true)
	metrics["hand_tracking"] = tracking_frame.get("hand_tracking", {}).duplicate(true) if tracking_frame.get("hand_tracking", {}) is Dictionary else {}
	metrics["hands"] = tracking_frame.get("hands", {}).duplicate(true) if tracking_frame.get("hands", {}) is Dictionary else {}
	var events: Array = []
	if tracking_state == TRACKING_TRACKING or tracking_state == TRACKING_REACQUIRING:
		if _should_evaluate_gestures_this_frame():
			events = _detect_intent_events(smoothed_landmarks, metrics, timestamp_ms, tracking_frame)
	else:
		_clear_transient_gesture_state()
	_latest_state = {
		"frame_index": _frame_index,
		"timestamp_ms": timestamp_ms,
		"tracking_state": tracking_state,
		"landmarks_by_id": smoothed_landmarks.duplicate(true),
		"baseline": _baseline.duplicate(true),
		"metrics": metrics,
		"events": events.duplicate(true),
		"gesture_states": _build_public_gesture_states(),
		"gesture_debug": _build_gesture_debug_state(metrics),
	}
	_last_processed_timestamp_ms = timestamp_ms
	return _latest_state

func mark_tracking_timeout(timestamp_ms: int) -> void:
	if _last_processed_timestamp_ms <= 0:
		return
	var timeout_ms := _get_tracking_timeout_ms()
	if timestamp_ms - _last_processed_timestamp_ms < timeout_ms:
		return
	_consecutive_valid_frames = 0
	_consecutive_invalid_frames = maxi(_consecutive_invalid_frames, 3)
	_reacquire_frames_remaining = _get_reacquire_window_frames()
	_clear_transient_gesture_state()
	if _latest_state.is_empty():
		_latest_state = _build_empty_state()
	_latest_state["tracking_state"] = TRACKING_LOST
	_latest_state["events"] = []
	_latest_state["gesture_states"] = _gesture_state.get("states", {}).duplicate(true)
	_latest_state["gesture_debug"] = _build_gesture_debug_state()
	var metrics: Dictionary = _latest_state.get("metrics", {})
	metrics["tracking_state"] = TRACKING_LOST
	_latest_state["metrics"] = metrics

func get_latest_state() -> Dictionary:
	return _latest_state.duplicate(true)

func get_landmark(landmark_id: int) -> Dictionary:
	var landmarks: Variant = _latest_state.get("landmarks_by_id", {})
	if landmarks is Dictionary:
		var landmark: Variant = landmarks.get(landmark_id, null)
		if landmark is Dictionary:
			return landmark
	return {}

func get_tracking_state() -> StringName:
	return StringName(_latest_state.get("tracking_state", TRACKING_LOST))

func get_velocity(body_part: StringName) -> Vector3:
	var velocities: Dictionary = _get_metric_dictionary("velocities")
	var velocity: Variant = velocities.get(String(body_part), Vector3.ZERO)
	if velocity is Vector3:
		return velocity
	return Vector3.ZERO

func get_tracking_confidence(body_part: StringName) -> float:
	var confidences: Dictionary = _get_metric_dictionary("confidences")
	return float(confidences.get(String(body_part), 0.0))

func get_measurements() -> Dictionary:
	return _get_metric_dictionary("measurements")

func _build_empty_state() -> Dictionary:
	return {
		"frame_index": 0,
		"timestamp_ms": 0,
		"tracking_state": TRACKING_LOST,
		"landmarks_by_id": {},
		"baseline": _baseline.duplicate(true),
		"metrics": {
			"tracking_state": TRACKING_LOST,
			"confidences": {},
			"velocities": {},
			"directions": {},
			"measurements": {},
			"baseline": _baseline.duplicate(true),
		},
		"events": [],
		"gesture_states": _build_public_gesture_states(),
		"gesture_debug": _build_gesture_debug_state(),
	}

func _build_metrics(landmarks_by_id: Dictionary, timestamp_ms: int) -> Dictionary:
	var nose := PoseMetrics.get_landmark(landmarks_by_id, PoseLandmarkIds.NOSE)
	var left_shoulder := PoseMetrics.get_landmark(landmarks_by_id, PoseLandmarkIds.LEFT_SHOULDER)
	var right_shoulder := PoseMetrics.get_landmark(landmarks_by_id, PoseLandmarkIds.RIGHT_SHOULDER)
	var left_elbow := PoseMetrics.get_landmark(landmarks_by_id, PoseLandmarkIds.LEFT_ELBOW)
	var right_elbow := PoseMetrics.get_landmark(landmarks_by_id, PoseLandmarkIds.RIGHT_ELBOW)
	var left_wrist := PoseMetrics.get_landmark(landmarks_by_id, PoseLandmarkIds.LEFT_WRIST)
	var right_wrist := PoseMetrics.get_landmark(landmarks_by_id, PoseLandmarkIds.RIGHT_WRIST)
	var left_hip := PoseMetrics.get_landmark(landmarks_by_id, PoseLandmarkIds.LEFT_HIP)
	var right_hip := PoseMetrics.get_landmark(landmarks_by_id, PoseLandmarkIds.RIGHT_HIP)
	var left_knee := PoseMetrics.get_landmark(landmarks_by_id, PoseLandmarkIds.LEFT_KNEE)
	var right_knee := PoseMetrics.get_landmark(landmarks_by_id, PoseLandmarkIds.RIGHT_KNEE)
	var left_ankle := PoseMetrics.get_landmark(landmarks_by_id, PoseLandmarkIds.LEFT_ANKLE)
	var right_ankle := PoseMetrics.get_landmark(landmarks_by_id, PoseLandmarkIds.RIGHT_ANKLE)
	var shoulder_center := PoseMetrics.midpoint(left_shoulder, right_shoulder)
	var hip_center := PoseMetrics.midpoint(left_hip, right_hip)
	var ankle_center := PoseMetrics.midpoint(left_ankle, right_ankle)

	var shoulder_width := PoseMetrics.distance_2d(left_shoulder, right_shoulder)
	var torso_height := PoseMetrics.distance_2d(shoulder_center, hip_center)
	var athlete_height := PoseMetrics.distance_2d(nose, ankle_center)
	var left_elbow_bend := PoseMetrics.angle_degrees(left_shoulder, left_elbow, left_wrist)
	var right_elbow_bend := PoseMetrics.angle_degrees(right_shoulder, right_elbow, right_wrist)
	var left_arm_length := PoseMetrics.distance_2d(left_shoulder, left_elbow) + PoseMetrics.distance_2d(left_elbow, left_wrist)
	var right_arm_length := PoseMetrics.distance_2d(right_shoulder, right_elbow) + PoseMetrics.distance_2d(right_elbow, right_wrist)
	var left_arm_extension := PoseMetrics.clamp01(PoseMetrics.normalized_ratio(PoseMetrics.distance_2d(left_shoulder, left_wrist), left_arm_length))
	var right_arm_extension := PoseMetrics.clamp01(PoseMetrics.normalized_ratio(PoseMetrics.distance_2d(right_shoulder, right_wrist), right_arm_length))
	var left_arm_length_3d := PoseMetrics.distance_3d(left_shoulder, left_elbow) + PoseMetrics.distance_3d(left_elbow, left_wrist)
	var right_arm_length_3d := PoseMetrics.distance_3d(right_shoulder, right_elbow) + PoseMetrics.distance_3d(right_elbow, right_wrist)
	var left_arm_extension_3d := PoseMetrics.clamp01(PoseMetrics.normalized_ratio(PoseMetrics.distance_3d(left_shoulder, left_wrist), left_arm_length_3d))
	var right_arm_extension_3d := PoseMetrics.clamp01(PoseMetrics.normalized_ratio(PoseMetrics.distance_3d(right_shoulder, right_wrist), right_arm_length_3d))
	var left_elbow_bend_3d := PoseMetrics.angle_degrees_3d(left_shoulder, left_elbow, left_wrist)
	var right_elbow_bend_3d := PoseMetrics.angle_degrees_3d(right_shoulder, right_elbow, right_wrist)

	var confidences := {
		"head": PoseMetrics.visibility(nose),
		"left_hand": PoseMetrics.visibility(left_wrist),
		"right_hand": PoseMetrics.visibility(right_wrist),
		"left_foot": PoseMetrics.visibility(left_ankle),
		"right_foot": PoseMetrics.visibility(right_ankle),
		"torso": PoseMetrics.average_visibility(landmarks_by_id, [PoseLandmarkIds.LEFT_SHOULDER, PoseLandmarkIds.RIGHT_SHOULDER, PoseLandmarkIds.LEFT_HIP, PoseLandmarkIds.RIGHT_HIP]),
	}
	var velocities := _compute_velocities(timestamp_ms, {
		"head": nose,
		"left_hand": left_wrist,
		"right_hand": right_wrist,
		"left_foot": left_ankle,
		"right_foot": right_ankle,
	})
	var directions := {
		"left_hand": _direction_from_velocity(velocities.get("left_hand", Vector3.ZERO)),
		"right_hand": _direction_from_velocity(velocities.get("right_hand", Vector3.ZERO)),
		"left_foot": _direction_from_velocity(velocities.get("left_foot", Vector3.ZERO)),
		"right_foot": _direction_from_velocity(velocities.get("right_foot", Vector3.ZERO)),
	}
	var left_forward_distance := float(left_shoulder.get("z", 0.0)) - float(left_wrist.get("z", 0.0))
	var right_forward_distance := float(right_shoulder.get("z", 0.0)) - float(right_wrist.get("z", 0.0))
	var left_wrist_velocity_vector: Vector3 = velocities.get("left_hand", Vector3.ZERO) as Vector3
	var right_wrist_velocity_vector: Vector3 = velocities.get("right_hand", Vector3.ZERO) as Vector3
	var left_forward_velocity := -float(left_wrist_velocity_vector.z)
	var right_forward_velocity := -float(right_wrist_velocity_vector.z)
	var left_wrist_velocity_magnitude := left_wrist_velocity_vector.length()
	var right_wrist_velocity_magnitude := right_wrist_velocity_vector.length()
	var left_outward_distance := float(left_shoulder.get("x", 0.0)) - float(left_wrist.get("x", 0.0))
	var right_outward_distance := float(right_wrist.get("x", 0.0)) - float(right_shoulder.get("x", 0.0))

	var shoulder_center_vec := PoseMetrics.to_vector3(shoulder_center)
	var hip_center_vec := PoseMetrics.to_vector3(hip_center)
	var nose_vec := PoseMetrics.to_vector3(nose)
	var body_centerline_x := _average_x([nose, shoulder_center, hip_center])
	var head_lateral_offset := 0.0
	var hip_lateral_offset := 0.0
	var shoulder_lateral_offset := 0.0
	var lateral_offset := 0.0
	var height_ratio := 1.0
	var height_state: StringName = StringName("unknown")
	var squat_depth := 0.0
	var head_drop_ratio := 0.0
	var left_knee_rise := 0.0
	var right_knee_rise := 0.0
	var left_foot_rise := 0.0
	var right_foot_rise := 0.0

	if bool(_baseline.get("is_calibrated", false)):
		var baseline_shoulder_width := maxf(float(_baseline.get("shoulder_width", 0.0)), 0.000001)
		var baseline_torso_height := maxf(float(_baseline.get("torso_height", 0.0)), 0.000001)
		var baseline_shoulder_x := float(_baseline.get("shoulder_center_x", body_centerline_x))
		var baseline_hip_y := float(_baseline.get("hip_center_y", hip_center_vec.y))
		var baseline_nose_y := float(_baseline.get("nose_y", nose_vec.y))
		lateral_offset = PoseMetrics.normalized_ratio(body_centerline_x - baseline_shoulder_x, baseline_shoulder_width)
		head_lateral_offset = PoseMetrics.normalized_ratio(nose_vec.x - baseline_shoulder_x, baseline_shoulder_width)
		hip_lateral_offset = PoseMetrics.normalized_ratio(hip_center_vec.x - baseline_shoulder_x, baseline_shoulder_width)
		shoulder_lateral_offset = PoseMetrics.normalized_ratio(shoulder_center_vec.x - baseline_shoulder_x, baseline_shoulder_width)
		height_ratio = PoseMetrics.normalized_ratio(torso_height, baseline_torso_height)
		height_state = _estimate_height_state(height_ratio, hip_center_vec.y - baseline_hip_y)
		squat_depth = maxf(0.0, 1.0 - height_ratio)
		head_drop_ratio = maxf(0.0, (baseline_nose_y - nose_vec.y) / baseline_torso_height)
		left_knee_rise = maxf(0.0, (float(left_knee.get("y", 0.0)) - float(_baseline.get("left_knee_y", left_knee.get("y", 0.0)))) / baseline_torso_height)
		right_knee_rise = maxf(0.0, (float(right_knee.get("y", 0.0)) - float(_baseline.get("right_knee_y", right_knee.get("y", 0.0)))) / baseline_torso_height)
		left_foot_rise = maxf(0.0, (float(left_ankle.get("y", 0.0)) - float(_baseline.get("left_ankle_y", left_ankle.get("y", 0.0)))) / baseline_torso_height)
		right_foot_rise = maxf(0.0, (float(right_ankle.get("y", 0.0)) - float(_baseline.get("right_ankle_y", right_ankle.get("y", 0.0)))) / baseline_torso_height)

	var left_lane_offset_ratio := PoseMetrics.normalized_ratio(body_centerline_x - float(left_wrist.get("x", body_centerline_x)), maxf(shoulder_width, 0.000001))
	var right_lane_offset_ratio := PoseMetrics.normalized_ratio(float(right_wrist.get("x", body_centerline_x)) - body_centerline_x, maxf(shoulder_width, 0.000001))
	var own_half_margin := shoulder_width * PUNCH_OWN_HALF_MARGIN_RATIO
	var left_own_half_lock := float(left_wrist.get("x", body_centerline_x)) <= body_centerline_x + own_half_margin and left_outward_distance >= -own_half_margin
	var right_own_half_lock := float(right_wrist.get("x", body_centerline_x)) >= body_centerline_x - own_half_margin and right_outward_distance >= -own_half_margin

	var measurements := {
		"shoulder_width": shoulder_width,
		"torso_height": torso_height,
		"athlete_height": athlete_height,
		"normalized_shoulder_width": PoseMetrics.normalized_ratio(shoulder_width, maxf(_baseline.get("shoulder_width", shoulder_width), 0.000001)),
		"normalized_torso_height": PoseMetrics.normalized_ratio(torso_height, maxf(_baseline.get("torso_height", torso_height), 0.000001)),
		"left_elbow_bend_deg": left_elbow_bend,
		"right_elbow_bend_deg": right_elbow_bend,
		"left_elbow_bend_deg_3d": left_elbow_bend_3d,
		"right_elbow_bend_deg_3d": right_elbow_bend_3d,
		"left_arm_extension": left_arm_extension,
		"right_arm_extension": right_arm_extension,
		"left_arm_extension_3d": left_arm_extension_3d,
		"right_arm_extension_3d": right_arm_extension_3d,
		"left_forward_distance": left_forward_distance,
		"right_forward_distance": right_forward_distance,
		"left_forward_velocity": left_forward_velocity,
		"right_forward_velocity": right_forward_velocity,
		"left_wrist_velocity_magnitude": left_wrist_velocity_magnitude,
		"right_wrist_velocity_magnitude": right_wrist_velocity_magnitude,
		"left_outward_distance": left_outward_distance,
		"right_outward_distance": right_outward_distance,
		"left_lane_offset_ratio": left_lane_offset_ratio,
		"right_lane_offset_ratio": right_lane_offset_ratio,
		"left_own_half_lock": left_own_half_lock,
		"right_own_half_lock": right_own_half_lock,
		"head_center": nose_vec,
		"shoulder_center": shoulder_center_vec,
		"hip_center": hip_center_vec,
		"body_centerline_x": body_centerline_x,
		"lateral_offset": lateral_offset,
		"head_lateral_offset": head_lateral_offset,
		"shoulder_lateral_offset": shoulder_lateral_offset,
		"hip_lateral_offset": hip_lateral_offset,
		"height_ratio": height_ratio,
		"height_state": height_state,
		"squat_depth": squat_depth,
		"head_drop_ratio": head_drop_ratio,
		"left_knee_rise": left_knee_rise,
		"right_knee_rise": right_knee_rise,
		"left_foot_rise": left_foot_rise,
		"right_foot_rise": right_foot_rise,
		"left_leg_angle_from_core_deg": _leg_angle_from_core_deg(left_hip, left_ankle),
		"right_leg_angle_from_core_deg": _leg_angle_from_core_deg(right_hip, right_ankle),
	}

	return {
		"confidences": confidences,
		"velocities": velocities,
		"directions": directions,
		"measurements": measurements,
	}

func _compute_velocities(timestamp_ms: int, tracked_landmarks: Dictionary) -> Dictionary:
	var velocities: Dictionary = {}
	for body_part_variant: Variant in tracked_landmarks.keys():
		var body_part: String = String(body_part_variant)
		var landmark_variant: Variant = tracked_landmarks[body_part_variant]
		if not landmark_variant is Dictionary or landmark_variant.is_empty():
			velocities[body_part] = Vector3.ZERO
			continue
		var landmark: Dictionary = landmark_variant
		var current_position := PoseMetrics.to_vector3(landmark)
		var previous: Variant = _previous_positions.get(body_part, null)
		if previous is Dictionary and _last_processed_timestamp_ms > 0:
			var dt_ms: int = maxi(timestamp_ms - _last_processed_timestamp_ms, 1)
			var previous_position: Vector3 = previous.get("position", current_position)
			velocities[body_part] = (current_position - previous_position) / (float(dt_ms) / 1000.0)
		else:
			velocities[body_part] = Vector3.ZERO
		_previous_positions[body_part] = {
			"position": current_position,
			"timestamp_ms": timestamp_ms,
		}
	return velocities

func _direction_from_velocity(velocity_variant: Variant) -> Vector2:
	if not velocity_variant is Vector3:
		return Vector2.ZERO
	var planar := Vector2(velocity_variant.x, velocity_variant.y)
	if planar.length() <= 0.000001:
		return Vector2.ZERO
	return planar.normalized()

func _update_tracking_state(landmarks_by_id: Dictionary) -> StringName:
	var min_visibility := _get_min_visibility()
	var confidence_gate := _get_tracking_confidence_gate()
	var visible_key_count := PoseMetrics.count_visible(landmarks_by_id, PoseLandmarkIds.TRACKING_KEY_LANDMARKS, min_visibility)
	var average_visibility := PoseMetrics.average_visibility(landmarks_by_id, PoseLandmarkIds.TRACKING_KEY_LANDMARKS)
	var valid_frame := visible_key_count >= 5 and average_visibility >= confidence_gate
	if valid_frame:
		_consecutive_valid_frames += 1
		_consecutive_invalid_frames = 0
		if _reacquire_frames_remaining > 0:
			_reacquire_frames_remaining -= 1
			if _reacquire_frames_remaining <= 0:
				return TRACKING_TRACKING
			return TRACKING_REACQUIRING
		return TRACKING_TRACKING

	_consecutive_invalid_frames += 1
	_consecutive_valid_frames = 0
	_reacquire_frames_remaining = _get_reacquire_window_frames()
	if _consecutive_invalid_frames >= 3:
		return TRACKING_LOST
	return TRACKING_DEGRADED

func _update_baseline(metrics: Dictionary, tracking_state: StringName, landmarks_by_id: Dictionary) -> void:
	if bool(_baseline.get("is_calibrated", false)):
		return
	if tracking_state != TRACKING_TRACKING and tracking_state != TRACKING_REACQUIRING:
		return
	var measurements: Dictionary = metrics.get("measurements", {})
	if measurements.is_empty():
		return
	var shoulder_width := float(measurements.get("shoulder_width", 0.0))
	var torso_height := float(measurements.get("torso_height", 0.0))
	var athlete_height := float(measurements.get("athlete_height", 0.0))
	if shoulder_width <= 0.0 or torso_height <= 0.0:
		return
	_baseline_accumulator["frames"] += 1
	_baseline_accumulator["shoulder_width"] += shoulder_width
	_baseline_accumulator["torso_height"] += torso_height
	_baseline_accumulator["athlete_height"] += athlete_height
	_baseline_accumulator["shoulder_center_x"] += float(measurements.get("body_centerline_x", 0.0))
	var hip_center: Variant = measurements.get("hip_center", Vector3.ZERO)
	if hip_center is Vector3:
		_baseline_accumulator["hip_center_y"] += hip_center.y
	var head_center: Variant = measurements.get("head_center", Vector3.ZERO)
	if head_center is Vector3:
		_baseline_accumulator["nose_y"] += head_center.y
	_baseline_accumulator["left_knee_y"] += float(PoseMetrics.get_landmark(landmarks_by_id, PoseLandmarkIds.LEFT_KNEE).get("y", 0.0))
	_baseline_accumulator["right_knee_y"] += float(PoseMetrics.get_landmark(landmarks_by_id, PoseLandmarkIds.RIGHT_KNEE).get("y", 0.0))
	_baseline_accumulator["left_ankle_y"] += float(PoseMetrics.get_landmark(landmarks_by_id, PoseLandmarkIds.LEFT_ANKLE).get("y", 0.0))
	_baseline_accumulator["right_ankle_y"] += float(PoseMetrics.get_landmark(landmarks_by_id, PoseLandmarkIds.RIGHT_ANKLE).get("y", 0.0))
	var frames: int = int(_baseline_accumulator["frames"])
	if frames < 5:
		return
	_baseline = {
		"is_calibrated": true,
		"sample_frames": frames,
		"shoulder_width": float(_baseline_accumulator["shoulder_width"]) / float(frames),
		"torso_height": float(_baseline_accumulator["torso_height"]) / float(frames),
		"athlete_height": float(_baseline_accumulator["athlete_height"]) / float(frames),
		"shoulder_center_x": float(_baseline_accumulator["shoulder_center_x"]) / float(frames),
		"hip_center_y": float(_baseline_accumulator["hip_center_y"]) / float(frames),
		"nose_y": float(_baseline_accumulator["nose_y"]) / float(frames),
		"left_knee_y": float(_baseline_accumulator["left_knee_y"]) / float(frames),
		"right_knee_y": float(_baseline_accumulator["right_knee_y"]) / float(frames),
		"left_ankle_y": float(_baseline_accumulator["left_ankle_y"]) / float(frames),
		"right_ankle_y": float(_baseline_accumulator["right_ankle_y"]) / float(frames),
	}

func _estimate_height_state(height_ratio: float, hip_center_delta_y: float) -> StringName:
	if height_ratio <= 0.82 or hip_center_delta_y > 0.05:
		return &"lowered"
	if height_ratio >= 0.95:
		return &"standing"
	return &"transition"

func _average_x(points: Array) -> float:
	var total := 0.0
	var count := 0
	for point_variant: Variant in points:
		if not point_variant is Dictionary or point_variant.is_empty():
			continue
		total += float(point_variant.get("x", 0.0))
		count += 1
	if count == 0:
		return 0.0
	return total / float(count)

func _get_metric_dictionary(key: String) -> Dictionary:
	var metrics: Variant = _latest_state.get("metrics", {})
	if metrics is Dictionary:
		var value: Variant = metrics.get(key, {})
		if value is Dictionary:
			return value
	return {}

func _build_gesture_debug_state(metrics: Dictionary = {}) -> Dictionary:
	return {
		"ready": _gesture_state.get("ready", {}).duplicate(true),
		"guard": _build_guard_debug_state(),
		"squat": _build_squat_debug_state(metrics),
		"weave": _build_weave_debug_state(metrics),
		"side_step": _build_side_step_debug_state(metrics),
		"knee_strike": _build_knee_strike_debug_state(metrics),
		"leg_lift": _build_leg_lift_debug_state(metrics),
		"punch_detection": _build_punch_detection_debug_state(),
		"straight_punch": _build_straight_punch_debug_state(metrics),
		"hook": _build_pose_strike_debug_state("hook", metrics),
		"uppercut": _build_pose_strike_debug_state("uppercut", metrics),
		"prototype": _prototype_punch_matcher.get_debug_state(),
		"classifier": _learned_punch_classifier.get_debug_state(),
		"prototype_matcher": _prototype_punch_matcher.get_debug_state(),
		"learned_classifier": _learned_punch_classifier.get_debug_state(),
		"depth_runtime": _build_depth_runtime_debug_state(),
		"flow": _build_flow_debug_state(metrics),
	}

func _build_punch_detection_debug_state() -> Dictionary:
	var family_backends := {
		"straight_punch": _get_punch_backend_for_family("straight_punch"),
		"hook": _get_punch_backend_for_family("hook"),
		"uppercut": _get_punch_backend_for_family("uppercut"),
	}
	var active_backends: Array[String] = []
	for family in PUNCH_FAMILIES:
		var backend := String(family_backends.get(family, BACKEND_DISABLED))
		if backend == BACKEND_DISABLED:
			continue
		if not active_backends.has(backend):
			active_backends.append(backend)
	var any_active_backend := not active_backends.is_empty()
	var depth_runtime := _build_depth_runtime_debug_state()
	return {
		"backend": "per_family",
		"active_backend": "per_family" if any_active_backend else "none",
		"selected_backend": "per_family",
		"selected_backend_raw": "per_family",
		"selected_backend_enabled": any_active_backend,
		"active_backend_resolution": _get_punch_backend_resolution_reason(),
		"routing_mode": "per_family",
		"active_backends": active_backends,
		"family_backends": family_backends,
		"straight_backend": String(family_backends.get("straight_punch", BACKEND_DISABLED)),
		"hook_backend": String(family_backends.get("hook", BACKEND_DISABLED)),
		"uppercut_backend": String(family_backends.get("uppercut", BACKEND_DISABLED)),
		"straight_model_path": String(_learned_punch_classifier.get_debug_state().get("model_path", "")) if String(family_backends.get("straight_punch", BACKEND_DISABLED)) == BACKEND_CLASSIFIER else "",
		"threshold_enabled": _any_punch_family_uses_backend(BACKEND_THRESHOLD),
		"prototype_enabled": _any_punch_family_uses_backend(BACKEND_PROTOTYPE),
		"classifier_enabled": _any_punch_family_uses_backend(BACKEND_CLASSIFIER),
		"depth_runtime": depth_runtime,
		"depth_runtime_statuses": {
			"straight_punch": String((depth_runtime.get("straight_punch", {}) as Dictionary).get("runtime_status", "unloaded")),
			"hook": String((depth_runtime.get("hook", {}) as Dictionary).get("runtime_status", "unloaded")),
			"uppercut": String((depth_runtime.get("uppercut", {}) as Dictionary).get("runtime_status", "unloaded")),
		},
	}

func _build_guard_debug_state() -> Dictionary:
	var guard_debug: Dictionary = (_gesture_state.get("guard_debug", {}) as Dictionary).duplicate(true)
	var guard_config := _get_guard_config()
	guard_debug["backend"] = _get_non_punch_backend_for_family("guard")
	guard_debug["state"] = bool(_get_state("guard"))
	guard_debug["enabled"] = bool(guard_config.get("enabled", true))
	guard_debug["max_wrist_separation_x"] = float(guard_config.get("max_wrist_separation_x", GUARD_DEFAULT_MAX_WRIST_SEPARATION_X))
	guard_debug["max_wrist_separation_y"] = float(guard_config.get("max_wrist_separation_y", GUARD_DEFAULT_MAX_WRIST_SEPARATION_Y))
	guard_debug["max_wrist_nose_distance"] = float(guard_config.get("max_wrist_nose_distance", GUARD_DEFAULT_MAX_WRIST_NOSE_DISTANCE))
	return guard_debug

func _build_squat_debug_state(metrics: Dictionary = {}) -> Dictionary:
	var measurements: Dictionary = metrics.get("measurements", {}) if not metrics.is_empty() else _latest_state.get("metrics", {}).get("measurements", {})
	var squat_config := _get_squat_config()
	return {
		"backend": _get_non_punch_backend_for_family("squat"),
		"state": bool(_get_state("squat")),
		"enabled": bool(squat_config.get("enabled", true)),
		"enter_height_ratio_max": float(squat_config.get("enter_height_ratio_max", SQUAT_DEFAULT_ENTER_HEIGHT_RATIO_MAX)),
		"exit_height_ratio_min": float(squat_config.get("exit_height_ratio_min", SQUAT_DEFAULT_EXIT_HEIGHT_RATIO_MIN)),
		"height_ratio": float(measurements.get("height_ratio", 1.0)),
		"height_state": String(measurements.get("height_state", "unknown")),
		"squat_depth": float(measurements.get("squat_depth", 0.0)),
		"torso_height": float(measurements.get("torso_height", 0.0)),
		"baseline_torso_height": float(_baseline.get("torso_height", 0.0)),
		"calibration_ready": bool(_baseline.get("is_calibrated", false)),
		"calibration_sample_frames": int(_baseline.get("sample_frames", 0)),
	}

func _build_weave_debug_state(metrics: Dictionary = {}) -> Dictionary:
	var measurements: Dictionary = metrics.get("measurements", {}) if not metrics.is_empty() else _latest_state.get("metrics", {}).get("measurements", {})
	var weave_debug: Dictionary = (_gesture_state.get("weave_debug", {}) as Dictionary).duplicate(true)
	var weave_config := _get_weave_config()
	var state_name := "inactive"
	if bool(_get_state("weave_left")):
		state_name = "left"
	elif bool(_get_state("weave_right")):
		state_name = "right"
	weave_debug["backend"] = _get_non_punch_backend_for_family("weave")
	weave_debug["state"] = state_name
	weave_debug["enabled"] = bool(weave_config.get("enabled", true))
	weave_debug["head_lateral_offset"] = float(measurements.get("head_lateral_offset", weave_debug.get("head_lateral_offset", 0.0)))
	weave_debug["hip_lateral_offset"] = float(measurements.get("hip_lateral_offset", weave_debug.get("hip_lateral_offset", 0.0)))
	weave_debug["relative_head_hip_offset"] = float(measurements.get("head_lateral_offset", 0.0)) - float(measurements.get("hip_lateral_offset", 0.0))
	weave_debug["head_drop_ratio"] = float(measurements.get("head_drop_ratio", weave_debug.get("head_drop_ratio", 0.0)))
	weave_debug["enter_head_lateral_offset_min"] = float(weave_config.get("enter_head_lateral_offset_min", WEAVE_DEFAULT_ENTER_HEAD_LATERAL_OFFSET_MIN))
	weave_debug["enter_relative_head_hip_offset_min"] = float(weave_config.get("enter_relative_head_hip_offset_min", WEAVE_DEFAULT_ENTER_RELATIVE_HEAD_HIP_OFFSET_MIN))
	weave_debug["enter_head_drop_ratio_min"] = float(weave_config.get("enter_head_drop_ratio_min", WEAVE_DEFAULT_ENTER_HEAD_DROP_RATIO_MIN))
	weave_debug["exit_head_lateral_offset_max"] = float(weave_config.get("exit_head_lateral_offset_max", WEAVE_DEFAULT_EXIT_HEAD_LATERAL_OFFSET_MAX))
	weave_debug["exit_relative_head_hip_offset_max"] = float(weave_config.get("exit_relative_head_hip_offset_max", WEAVE_DEFAULT_EXIT_RELATIVE_HEAD_HIP_OFFSET_MAX))
	return weave_debug

func _build_side_step_debug_state(metrics: Dictionary = {}) -> Dictionary:
	var measurements: Dictionary = metrics.get("measurements", {}) if not metrics.is_empty() else _latest_state.get("metrics", {}).get("measurements", {})
	var state_name := "inactive"
	if bool(_get_state("sidestep_left")):
		state_name = "left"
	elif bool(_get_state("sidestep_right")):
		state_name = "right"
	var backend := _get_non_punch_backend_for_family("side_step")
	return {
		"backend": backend,
		"enabled": backend == BACKEND_THRESHOLD,
		"state": state_name,
		"lateral_offset": float(measurements.get("lateral_offset", 0.0)),
		"head_lateral_offset": float(measurements.get("head_lateral_offset", 0.0)),
		"hip_lateral_offset": float(measurements.get("hip_lateral_offset", 0.0)),
	}

func _build_knee_strike_debug_state(metrics: Dictionary = {}) -> Dictionary:
	var measurements: Dictionary = metrics.get("measurements", {}) if not metrics.is_empty() else _latest_state.get("metrics", {}).get("measurements", {})
	var backend := _get_non_punch_backend_for_family("knee_strike")
	return {
		"backend": backend,
		"enabled": backend == BACKEND_THRESHOLD,
		"left_ready": _is_ready("knee_left"),
		"right_ready": _is_ready("knee_right"),
		"left_knee_rise": float(measurements.get("left_knee_rise", 0.0)),
		"right_knee_rise": float(measurements.get("right_knee_rise", 0.0)),
		"left_foot_rise": float(measurements.get("left_foot_rise", 0.0)),
		"right_foot_rise": float(measurements.get("right_foot_rise", 0.0)),
	}

func _build_leg_lift_debug_state(metrics: Dictionary = {}) -> Dictionary:
	var measurements: Dictionary = metrics.get("measurements", {}) if not metrics.is_empty() else _latest_state.get("metrics", {}).get("measurements", {})
	var backend := _get_non_punch_backend_for_family("leg_lift")
	return {
		"backend": backend,
		"enabled": backend == BACKEND_THRESHOLD,
		"left_state": bool(_get_state("leg_lift_left")),
		"right_state": bool(_get_state("leg_lift_right")),
		"left_leg_angle_from_core_deg": float(measurements.get("left_leg_angle_from_core_deg", 0.0)),
		"right_leg_angle_from_core_deg": float(measurements.get("right_leg_angle_from_core_deg", 0.0)),
	}

func _build_straight_punch_debug_state(metrics: Dictionary = {}) -> Dictionary:
	var measurements: Dictionary = metrics.get("measurements", {}) if not metrics.is_empty() else _latest_state.get("metrics", {}).get("measurements", {})
	var hands: Dictionary = metrics.get("hands", {}) if not metrics.is_empty() and metrics.get("hands", {}) is Dictionary else _latest_state.get("metrics", {}).get("hands", {})
	return {
		"left": _build_straight_punch_side_debug("left", measurements, hands),
		"right": _build_straight_punch_side_debug("right", measurements, hands),
	}

func _build_straight_punch_side_debug(side: String, _measurements: Dictionary, hands: Dictionary = {}) -> Dictionary:
	var state := _get_straight_punch_state(side)
	var straight_punch_config := _get_straight_punch_config()
	var depth_runtime_debug := _get_depth_runtime_debug_state("straight_punch")
	if hands.is_empty():
		hands = _latest_state.get("metrics", {}).get("hands", {})
	var hand_payload: Dictionary = hands.get(side, {}) if hands.get(side, {}) is Dictionary else {}
	var bbox: Dictionary = hand_payload.get("bbox", {}) if hand_payload.get("bbox", {}) is Dictionary else {}
	return {
		"backend": _get_punch_backend_for_family("straight_punch"),
		"phase": String(state.get("phase", STRAIGHT_PUNCH_STATE_TRACKING_LOST)),
		"state": String(state.get("phase", STRAIGHT_PUNCH_STATE_TRACKING_LOST)),
		"previous_state": String(state.get("previous_state", "")),
		"timestamp_ms": int(state.get("timestamp_ms", 0)),
		"wrist_velocity": float(state.get("last_wrist_velocity", 0.0)),
		"elbow_shoulder_xy_distance": float(state.get("elbow_shoulder_xy_distance", 0.0)),
		"max_elbow_shoulder_xy_distance": float(straight_punch_config.get("max_elbow_shoulder_xy_distance", STRAIGHT_PUNCH_DEFAULT_MAX_ELBOW_SHOULDER_XY_DISTANCE)),
		"elbow_shoulder_xy_gate_passed": bool(state.get("elbow_shoulder_xy_gate_passed", false)),
		"wrist_lateral_angle_from_elbow_vertical_deg": float(state.get("wrist_lateral_angle_from_elbow_vertical_deg", 0.0)),
		"min_wrist_lateral_angle_from_elbow_vertical_deg": float(straight_punch_config.get("min_wrist_lateral_angle_from_elbow_vertical_deg", STRAIGHT_PUNCH_DEFAULT_MIN_WRIST_LATERAL_ANGLE_FROM_ELBOW_VERTICAL_DEG)),
		"wrist_lateral_angle_gate_passed": bool(state.get("wrist_lateral_angle_gate_passed", false)),
		"wrist_forward_velocity": float(state.get("last_wrist_forward_velocity", 0.0)),
		"forward_depth_spike": float(state.get("last_forward_depth_spike", 0.0)),
		"recent_peak_forward_depth_spike": float(state.get("recent_peak_forward_depth_spike", 0.0)),
		"recent_peak_wrist_velocity": float(state.get("recent_peak_wrist_velocity", 0.0)),
		"min_velocity": float(straight_punch_config.get("min_velocity", STRAIGHT_PUNCH_DEFAULT_MIN_WRIST_VELOCITY)),
		"bbox_area": float(bbox.get("area", state.get("last_bbox_area", 0.0))),
		"bbox_area_growth": float(state.get("last_bbox_area_growth", 0.0)),
		"recent_peak_bbox_area_growth": float(state.get("recent_peak_bbox_area_growth", 0.0)),
		"growth_window_areas": _bbox_area_window_values(state.get("bbox_area_window_history", []) as Array),
		"positive_growth_samples": int(state.get("positive_growth_samples", 0)),
		"min_positive_growth_samples": int(straight_punch_config.get("min_positive_growth_samples", STRAIGHT_PUNCH_DEFAULT_MIN_POSITIVE_GROWTH_SAMPLES)),
		"sample_window_size": int(straight_punch_config.get("sample_window_size", STRAIGHT_PUNCH_DEFAULT_SAMPLE_WINDOW_SIZE)),
		"window_ms": int(straight_punch_config.get("window_ms", STRAIGHT_PUNCH_DEFAULT_WRIST_VELOCITY_WINDOW_MS)),
		"wrist_velocity_window_span_ms": int(state.get("last_wrist_velocity_window_span_ms", 0)),
		"forward_depth_spike_window_span_ms": int(state.get("last_forward_depth_spike_window_span_ms", 0)),
		"bbox_area_growth_window_span_ms": int(state.get("last_bbox_area_growth_window_span_ms", 0)),
		"min_bbox_area_growth": float(straight_punch_config.get("min_bbox_area_growth", STRAIGHT_PUNCH_DEFAULT_MIN_BBOX_AREA_GROWTH)),
		"trigger_bbox_area": float(state.get("trigger_bbox_area", 0.0)),
		"grace_ms_remaining": int(state.get("grace_ms_remaining", 0)),
		"triggered_grace_ms": int(straight_punch_config.get("triggered_grace_ms", STRAIGHT_PUNCH_DEFAULT_TRIGGERED_GRACE_MS)),
		"bbox_area_retract_epsilon": float(straight_punch_config.get("bbox_area_retract_epsilon", STRAIGHT_PUNCH_DEFAULT_BBOX_AREA_RETRACT_EPSILON)),
		"pose_only_rearm_ms": int(straight_punch_config.get("pose_only_rearm_ms", STRAIGHT_PUNCH_DEFAULT_POSE_ONLY_REARM_MS)),
		"reacquire_stable_ms_required": int(straight_punch_config.get("lost_tracking_reacquire_stable_ms", STRAIGHT_PUNCH_DEFAULT_REACQUIRE_STABLE_MS)),
		"hand_tracking_enabled": _straight_punch_uses_hand_tracking(),
		"pose_tracking_valid": bool(state.get("pose_tracking_valid", false)),
		"fresh_sample": bool(state.get("last_sample_fresh", false)),
		"sample_source": String(hand_payload.get("sample_source", state.get("hand_sample_source", "none"))),
		"velocity_signal_source": String(state.get("velocity_signal_source", "wrist_only")),
		"tracking_valid": bool(hand_payload.get("tracking_valid", state.get("hand_tracking_valid", false))),
		"tracking_state": String(hand_payload.get("tracking_state", state.get("hand_tracking_state", "idle"))),
		"stale_frames": int(hand_payload.get("stale_frames", state.get("stale_frames", 0))),
		"stale_ms": int(hand_payload.get("stale_ms", 0)),
		"grace_frames": int(hand_payload.get("grace_frames", 0)),
		"grace_ms": int(hand_payload.get("grace_ms", 0)),
		"stable_ms": int(hand_payload.get("stable_ms", 0)),
		"bbox": bbox.duplicate(true),
		"association": hand_payload.get("association", {}).duplicate(true) if hand_payload.get("association", {}) is Dictionary else {},
		"calibration_ready": bool(_baseline.get("is_calibrated", false)),
		"calibration_sample_frames": int(_baseline.get("sample_frames", 0)),
		"same_family_blocked": bool(state.get("same_family_blocked", false)),
		"blocking_family": String(state.get("blocking_family", "")),
		"blocking_side": String(state.get("blocking_side", "")),
		"blocking_event_name": String(state.get("blocking_event_name", "")),
		"blocking_phase": String(state.get("blocking_phase", "")),
		"depth_signal_available": bool(state.get("depth_signal_available", false)),
		"depth_signal_fresh": bool(state.get("depth_signal_fresh", false)),
		"depth_signal_source": String(state.get("depth_signal_source", "")),
		"last_depth_closeness": float(state.get("last_depth_closeness", 0.0)),
		"depth_closeness_delta": float(state.get("depth_closeness_delta", 0.0)),
		"depth_peak_closeness": float(state.get("depth_peak_closeness", 0.0)),
		"depth_early_closeness": float(state.get("depth_early_closeness", 0.0)),
		"depth_late_closeness": float(state.get("depth_late_closeness", 0.0)),
		"depth_window_span_ms": int(state.get("depth_window_span_ms", 0)),
		"depth_gate_applied": bool(state.get("depth_gate_applied", false)),
		"depth_gate_passed": bool(state.get("depth_gate_passed", false)),
		"depth_gate_reason": String(state.get("depth_gate_reason", "staged_or_unavailable")),
		"depth_gate_threshold_a": float(state.get("depth_gate_threshold_a", 0.0)),
		"depth_gate_threshold_b": float(state.get("depth_gate_threshold_b", 0.0)),
		"depth_runtime_status": String(depth_runtime_debug.get("runtime_status", state.get("depth_runtime_status", "unloaded"))),
		"depth_runtime_stage": String(depth_runtime_debug.get("runtime_stage", "idle")),
		"depth_backend_id": String(depth_runtime_debug.get("backend_id", "unknown")),
		"depth_family_id": String(depth_runtime_debug.get("family_id", "unknown")),
		"depth_enabled": bool(depth_runtime_debug.get("depth_enabled", false)),
		"depth_failure_code": String(depth_runtime_debug.get("failure_code", "")),
		"depth_failure_message": String(depth_runtime_debug.get("failure_message", "")),
		"depth_active_model_summary": String(depth_runtime_debug.get("active_model_summary", "")),
		"depth_artifact_path": String(depth_runtime_debug.get("artifact_path_res", "")),
		"depth_sample_metrics": (depth_runtime_debug.get("last_sample_metrics", {}) as Dictionary).duplicate(true),
	}

func _build_pose_strike_debug_state(family: String, metrics: Dictionary = {}) -> Dictionary:
	var measurements: Dictionary = metrics.get("measurements", {}) if not metrics.is_empty() else _latest_state.get("metrics", {}).get("measurements", {})
	return {
		"left": _build_pose_strike_side_debug(family, "left", measurements),
		"right": _build_pose_strike_side_debug(family, "right", measurements),
	}

func _build_pose_strike_side_debug(family: String, side: String, measurements: Dictionary) -> Dictionary:
	var state := _get_pose_strike_state(family, side)
	var config := _get_pose_strike_config(family)
	var depth_runtime_debug := _get_depth_runtime_debug_state(family)
	var lateral_speed := float(state.get("last_lateral_velocity", 0.0))
	var vertical_speed := float(state.get("last_vertical_velocity", 0.0))
	var debug := {
		"backend": _get_punch_backend_for_family(family),
		"phase": String(state.get("phase", POSE_STRIKE_STATE_TRACKING_LOST)),
		"state": String(state.get("phase", POSE_STRIKE_STATE_TRACKING_LOST)),
		"previous_state": String(state.get("previous_state", "")),
		"timestamp_ms": int(state.get("timestamp_ms", 0)),
		"wrist_velocity": float(state.get("last_wrist_velocity", 0.0)),
		"window_ms": int(config.get("window_ms", POSE_STRIKE_DEFAULT_WINDOW_MS)),
		"window_span_ms": int(state.get("last_wrist_velocity_window_span_ms", 0)),
		"min_velocity": float(config.get("min_velocity", config.get("min_punch_velocity", POSE_STRIKE_DEFAULT_MIN_PUNCH_VELOCITY))),
		"min_punch_velocity": float(config.get("min_velocity", config.get("min_punch_velocity", POSE_STRIKE_DEFAULT_MIN_PUNCH_VELOCITY))),
		"triggered_grace_ms": int(config.get("triggered_grace_ms", POSE_STRIKE_DEFAULT_TRIGGERED_GRACE_MS)),
		"grace_ms_remaining": int(state.get("grace_ms_remaining", 0)),
		"pose_only_rearm_ms": int(config.get("pose_only_rearm_ms", POSE_STRIKE_DEFAULT_POSE_ONLY_REARM_MS)),
		"reacquire_stable_ms_required": int(config.get("lost_tracking_reacquire_stable_ms", POSE_STRIKE_DEFAULT_REACQUIRE_STABLE_MS)),
		"pose_tracking_valid": bool(state.get("pose_tracking_valid", false)),
		"tracking_valid": bool(state.get("pose_tracking_valid", false)),
		"tracking_state": String(state.get("tracking_state", "pose_missing")),
		"fresh_sample": bool(state.get("last_sample_fresh", false)),
		"sample_source": "pose",
		"velocity_signal_source": String(state.get("velocity_signal_source", "wrist_only")),
		"elbow_bend_deg": float(state.get("elbow_bend_deg", 0.0)),
		"lateral_velocity": lateral_speed,
		"vertical_velocity": vertical_speed,
		"wrist_elbow_vertical_offset": float(state.get("wrist_elbow_vertical_offset", 0.0)),
		"wrist_elbow_horizontal_offset": float(state.get("wrist_elbow_horizontal_offset", 0.0)),
		"wrist_above_elbow_offset": float(state.get("wrist_above_elbow_offset", 0.0)),
		"horizontal_direction_velocity": float(state.get("horizontal_direction_velocity", 0.0)),
		"directionality_ratio": float(state.get("directionality_ratio", 0.0)),
		"calibration_ready": bool(_baseline.get("is_calibrated", false)),
		"calibration_sample_frames": int(_baseline.get("sample_frames", 0)),
		"depth_signal_available": bool(state.get("depth_signal_available", false)),
		"depth_signal_fresh": bool(state.get("depth_signal_fresh", false)),
		"depth_signal_source": String(state.get("depth_signal_source", "")),
		"last_depth_closeness": float(state.get("last_depth_closeness", 0.0)),
		"depth_closeness_delta": float(state.get("depth_closeness_delta", 0.0)),
		"depth_peak_closeness": float(state.get("depth_peak_closeness", 0.0)),
		"depth_early_closeness": float(state.get("depth_early_closeness", 0.0)),
		"depth_late_closeness": float(state.get("depth_late_closeness", 0.0)),
		"depth_window_span_ms": int(state.get("depth_window_span_ms", 0)),
		"depth_gate_applied": bool(state.get("depth_gate_applied", false)),
		"depth_gate_passed": bool(state.get("depth_gate_passed", false)),
		"depth_gate_reason": String(state.get("depth_gate_reason", "staged_or_unavailable")),
		"depth_gate_threshold_a": float(state.get("depth_gate_threshold_a", 0.0)),
		"depth_gate_threshold_b": float(state.get("depth_gate_threshold_b", 0.0)),
		"depth_runtime_status": String(depth_runtime_debug.get("runtime_status", state.get("depth_runtime_status", "unloaded"))),
		"depth_runtime_stage": String(depth_runtime_debug.get("runtime_stage", "idle")),
		"depth_backend_id": String(depth_runtime_debug.get("backend_id", "unknown")),
		"depth_family_id": String(depth_runtime_debug.get("family_id", "unknown")),
		"depth_enabled": bool(depth_runtime_debug.get("depth_enabled", false)),
		"depth_failure_code": String(depth_runtime_debug.get("failure_code", "")),
		"depth_failure_message": String(depth_runtime_debug.get("failure_message", "")),
		"depth_active_model_summary": String(depth_runtime_debug.get("active_model_summary", "")),
		"depth_artifact_path": String(depth_runtime_debug.get("artifact_path_res", "")),
		"depth_sample_metrics": (depth_runtime_debug.get("last_sample_metrics", {}) as Dictionary).duplicate(true),
	}
	if family == "hook":
		debug["outward_velocity"] = float(state.get("outward_velocity", 0.0))
		debug["outward_distance"] = float(state.get("outward_distance", 0.0))
		debug["wrist_angle_from_elbow_horizontal_deg"] = float(state.get("wrist_angle_from_elbow_horizontal_deg", 0.0))
		debug["max_wrist_angle_from_elbow_horizontal_deg"] = float(config.get("max_wrist_angle_from_elbow_horizontal_deg", HOOK_DEFAULT_MAX_WRIST_ANGLE_FROM_ELBOW_HORIZONTAL_DEG))
		debug["wrist_horizontal_angle_gate_passed"] = bool(state.get("wrist_horizontal_angle_gate_passed", false))
		debug["wrist_on_required_hook_side"] = bool(state.get("wrist_on_required_hook_side", false))
		debug["required_hook_side_label"] = _required_hook_side_label(side)
		debug["required_direction_label"] = "rightward" if side == "left" else "leftward"
		debug["direction_reference_frame"] = "preview_space_horizontal"
	else:
		debug["upward_velocity"] = float(state.get("upward_velocity", 0.0))
		debug["wrist_angle_from_elbow_vertical_deg"] = float(state.get("wrist_angle_from_elbow_vertical_deg", 0.0))
		debug["max_wrist_angle_from_elbow_vertical_deg"] = float(config.get("max_wrist_angle_from_elbow_vertical_deg", UPPERCUT_DEFAULT_MAX_WRIST_ANGLE_FROM_ELBOW_VERTICAL_DEG))
		debug["wrist_vertical_angle_gate_passed"] = bool(state.get("wrist_vertical_angle_gate_passed", false))
		debug["wrist_above_elbow_gate_passed"] = bool(state.get("wrist_above_elbow_gate_passed", false))
		debug["required_direction_label"] = "upward"
		debug["direction_reference_frame"] = "preview_space_vertical"
	return debug

func _build_flow_debug_state(metrics: Dictionary = {}) -> Dictionary:
	var measurements: Dictionary = metrics.get("measurements", {}) if not metrics.is_empty() else _latest_state.get("metrics", {}).get("measurements", {})
	var shoulder_width := maxf(float(_baseline.get("shoulder_width", measurements.get("shoulder_width", 0.0))), 0.000001)
	var shoulder_center_vec: Vector3 = measurements.get("shoulder_center", Vector3(float(_baseline.get("shoulder_center_x", 0.0)), 0.0, 0.0))
	var shoulder_center := Vector2(shoulder_center_vec.x, shoulder_center_vec.y)
	return {
		"left": _build_flow_side_debug("left", shoulder_width, shoulder_center),
		"right": _build_flow_side_debug("right", shoulder_width, shoulder_center),
	}

func _build_flow_side_debug(side: String, shoulder_width: float, shoulder_center: Vector2) -> Dictionary:
	var history: Array = _get_flow_history("%s_hand" % side)
	var current_analysis := _analyze_flow_motion(side, shoulder_width, shoulder_center, FLOW_HISTORY_MAX_MS)
	var swing_analysis := _analyze_flow_motion(side, shoulder_width, shoulder_center, FLOW_SWING_WINDOW_MAX_MS)
	var trail_meta: Dictionary = _get_flow_meta("trail_%s" % side)
	var swing_meta: Dictionary = _get_flow_meta("swing_%s" % side)
	var latest_sample: Dictionary = history[history.size() - 1] if history.size() > 0 else {}
	var placement_candidate := int(current_analysis.get("placement", swing_analysis.get("placement", -1)))
	var avg_x := float(current_analysis.get("avg_x", swing_analysis.get("avg_x", 0.0)))
	var center_offset_ratio := PoseMetrics.normalized_ratio(avg_x - shoulder_center.x, shoulder_width) if placement_candidate >= 0 else 0.0
	return {
		"history_points": history.size(),
		"history_duration_ms": _flow_history_duration_ms(history),
		"latest_position": latest_sample.get("position", Vector2.ZERO),
		"latest_confidence": float(latest_sample.get("confidence", 0.0)),
		"placement_candidate": placement_candidate,
		"placement_candidate_ui_label": int(current_analysis.get("placement_ui_label", swing_analysis.get("placement_ui_label", 0))),
		"direction_candidate": int(current_analysis.get("direction", swing_analysis.get("direction", -1))),
		"direction_candidate_ui_label": int(current_analysis.get("direction_ui_label", swing_analysis.get("direction_ui_label", 0))),
		"center_x": shoulder_center.x,
		"avg_x": avg_x,
		"center_offset_ratio": center_offset_ratio,
		"current_analysis": current_analysis.duplicate(true),
		"swing_analysis": swing_analysis.duplicate(true),
		"trail_analysis": current_analysis.duplicate(true),
		"trail_meta": trail_meta.duplicate(true),
		"swing_meta": swing_meta.duplicate(true),
	}

func _flow_history_duration_ms(history: Array) -> int:
	if history.size() < 2:
		return 0
	return maxi(int(history[history.size() - 1].get("timestamp_ms", 0)) - int(history[0].get("timestamp_ms", 0)), 0)

func _get_smoothing_window_size() -> int:
	if _config == null:
		return 4
	var smoothing_factor := clampf(float(_config.smoothing_factor), 0.0, 1.0)
	return maxi(int(round(1.0 + smoothing_factor * 4.0)), 1)

func _get_pose_smoothing_style() -> String:
	if _config == null:
		return LandmarkSmoother.STYLE_LITE_RAW
	var tracker_profile_document: Variant = _config.get("tracker_profile_document") if _config.has_method("get") else null
	if not tracker_profile_document is Dictionary:
		return LandmarkSmoother.STYLE_LITE_RAW
	var tracking: Dictionary = tracker_profile_document.get("tracking", {}) if tracker_profile_document.get("tracking", {}) is Dictionary else {}
	var pose: Dictionary = tracking.get("pose", {}) if tracking.get("pose", {}) is Dictionary else {}
	var smoothing_style := String(pose.get("smoothing_style", "")).strip_edges().to_lower()
	if smoothing_style == LandmarkSmoother.STYLE_LITE_FILTERED:
		return smoothing_style
	return LandmarkSmoother.STYLE_LITE_RAW

func _get_min_visibility() -> float:
	if _config == null:
		return 0.5
	return float(_config.min_visibility)

func _get_tracking_confidence_gate() -> float:
	if _config == null:
		return 0.5
	return float(_config.tracking_confidence)

func _get_tracking_timeout_ms() -> int:
	return 500

func _get_reacquire_window_frames() -> int:
	return 2

func _reset_gesture_state() -> void:
	_gesture_state = {
		"states": {
			"guard": false,
			"squat": false,
			"weave_left": false,
			"weave_right": false,
			"sidestep_left": false,
			"sidestep_right": false,
			"leg_lift_left": false,
			"leg_lift_right": false,
			"trail_left": false,
			"trail_right": false,
		},
		"ready": {
			"punch_left": false,
			"punch_right": false,
			"hook_left": true,
			"hook_right": true,
			"uppercut_left": true,
			"uppercut_right": true,
			"knee_left": true,
			"knee_right": true,
			"swing_left": true,
			"swing_right": true,
		},
		"straight_punch": {
			"left": _build_straight_punch_state(STRAIGHT_PUNCH_STATE_TRACKING_LOST),
			"right": _build_straight_punch_state(STRAIGHT_PUNCH_STATE_TRACKING_LOST),
		},
		"hook": {
			"left": _build_pose_strike_state(POSE_STRIKE_STATE_TRACKING_LOST),
			"right": _build_pose_strike_state(POSE_STRIKE_STATE_TRACKING_LOST),
		},
		"uppercut": {
			"left": _build_pose_strike_state(POSE_STRIKE_STATE_TRACKING_LOST),
			"right": _build_pose_strike_state(POSE_STRIKE_STATE_TRACKING_LOST),
		},
		"guard_debug": {
			"state": false,
			"enabled": true,
			"max_wrist_separation_x": GUARD_DEFAULT_MAX_WRIST_SEPARATION_X,
			"max_wrist_separation_y": GUARD_DEFAULT_MAX_WRIST_SEPARATION_Y,
			"max_wrist_nose_distance": GUARD_DEFAULT_MAX_WRIST_NOSE_DISTANCE,
			"wrist_separation_x": 0.0,
			"wrist_separation_y": 0.0,
			"left_wrist_nose_distance": 0.0,
			"right_wrist_nose_distance": 0.0,
			"wrists_close_x": false,
			"wrists_close_y": false,
			"left_wrist_above_elbow": false,
			"right_wrist_above_elbow": false,
			"left_wrist_near_nose": false,
			"right_wrist_near_nose": false,
			"candidate": false,
		},
		"weave_debug": {
			"state": "inactive",
			"enabled": true,
			"head_lateral_offset": 0.0,
			"hip_lateral_offset": 0.0,
			"relative_head_hip_offset": 0.0,
			"head_drop_ratio": 0.0,
			"enter_head_lateral_offset_min": WEAVE_DEFAULT_ENTER_HEAD_LATERAL_OFFSET_MIN,
			"enter_relative_head_hip_offset_min": WEAVE_DEFAULT_ENTER_RELATIVE_HEAD_HIP_OFFSET_MIN,
			"enter_head_drop_ratio_min": WEAVE_DEFAULT_ENTER_HEAD_DROP_RATIO_MIN,
			"exit_head_lateral_offset_max": WEAVE_DEFAULT_EXIT_HEAD_LATERAL_OFFSET_MAX,
			"exit_relative_head_hip_offset_max": WEAVE_DEFAULT_EXIT_RELATIVE_HEAD_HIP_OFFSET_MAX,
			"left_candidate": false,
			"right_candidate": false,
			"neutral_candidate": true,
			"head_offset_left_ready": false,
			"head_offset_right_ready": false,
			"relative_offset_left_ready": false,
			"relative_offset_right_ready": false,
			"head_drop_ready": false,
		},
		"flow": {
			"left_hand": [],
			"right_hand": [],
			"swing_left": {"last_emit_ms": 0},
			"swing_right": {"last_emit_ms": 0},
			"trail_left": {"last_emit_ms": 0},
			"trail_right": {"last_emit_ms": 0},
		},
	}

func _should_evaluate_gestures_this_frame() -> bool:
	var interval := 1
	if _config != null:
		interval = maxi(1, int(_config.gesture_eval_interval_frames))
	return _frame_index % interval == 0

func _clear_transient_gesture_state() -> void:
	_reset_gesture_state()
	_prototype_punch_matcher.reset()
	_learned_punch_classifier.reset()

func _reset_temporal_runtime_state_for_timestamp_rewind() -> void:
	_smoother = LandmarkSmoother.new(_get_smoothing_window_size(), _get_pose_smoothing_style())
	_previous_positions.clear()
	_consecutive_valid_frames = 0
	_consecutive_invalid_frames = 0
	_reacquire_frames_remaining = 0
	_last_processed_timestamp_ms = 0
	_clear_transient_gesture_state()

func _detect_intent_events(landmarks_by_id: Dictionary, metrics: Dictionary, timestamp_ms: int, tracking_frame: Dictionary = {}) -> Array:
	var events: Array = []
	var measurements: Dictionary = metrics.get("measurements", {})
	if not bool(_baseline.get("is_calibrated", false)):
		return events
	var shoulder_width := maxf(float(measurements.get("shoulder_width", float(_baseline.get("shoulder_width", 0.0)))), 0.000001)
	var shoulder_center_vec: Vector3 = measurements.get("shoulder_center", Vector3(float(_baseline.get("shoulder_center_x", 0.0)), 0.0, 0.0))
	var shoulder_center := Vector2(shoulder_center_vec.x, shoulder_center_vec.y)
	var torso_height := maxf(float(measurements.get("torso_height", float(_baseline.get("torso_height", 0.0)))), 0.000001)
	var nose := PoseMetrics.get_landmark(landmarks_by_id, PoseLandmarkIds.NOSE)
	var left_shoulder := PoseMetrics.get_landmark(landmarks_by_id, PoseLandmarkIds.LEFT_SHOULDER)
	var right_shoulder := PoseMetrics.get_landmark(landmarks_by_id, PoseLandmarkIds.RIGHT_SHOULDER)
	var left_elbow := PoseMetrics.get_landmark(landmarks_by_id, PoseLandmarkIds.LEFT_ELBOW)
	var right_elbow := PoseMetrics.get_landmark(landmarks_by_id, PoseLandmarkIds.RIGHT_ELBOW)
	var left_wrist := PoseMetrics.get_landmark(landmarks_by_id, PoseLandmarkIds.LEFT_WRIST)
	var right_wrist := PoseMetrics.get_landmark(landmarks_by_id, PoseLandmarkIds.RIGHT_WRIST)
	var left_hip := PoseMetrics.get_landmark(landmarks_by_id, PoseLandmarkIds.LEFT_HIP)
	var right_hip := PoseMetrics.get_landmark(landmarks_by_id, PoseLandmarkIds.RIGHT_HIP)
	var left_ankle := PoseMetrics.get_landmark(landmarks_by_id, PoseLandmarkIds.LEFT_ANKLE)
	var right_ankle := PoseMetrics.get_landmark(landmarks_by_id, PoseLandmarkIds.RIGHT_ANKLE)
	var velocities: Dictionary = metrics.get("velocities", {})
	var confidences: Dictionary = metrics.get("confidences", {})
	var left_hand_velocity: Vector3 = velocities.get("left_hand", Vector3.ZERO)
	var right_hand_velocity: Vector3 = velocities.get("right_hand", Vector3.ZERO)
	var left_hand_confidence := float(confidences.get("left_hand", 0.0))
	var right_hand_confidence := float(confidences.get("right_hand", 0.0))
	var left_foot_confidence := float(confidences.get("left_foot", 0.0))
	var right_foot_confidence := float(confidences.get("right_foot", 0.0))
	var torso_confidence := float(confidences.get("torso", 0.0))
	var lower_body_confidence_gate := maxf(_get_min_visibility(), 0.5)
	_update_flow_hand_history("left", left_wrist, left_hand_confidence, timestamp_ms)
	_update_flow_hand_history("right", right_wrist, right_hand_confidence, timestamp_ms)

	_process_guard(events, nose, left_shoulder, right_shoulder, left_elbow, right_elbow, left_wrist, right_wrist, shoulder_width)
	if torso_confidence >= lower_body_confidence_gate:
		_process_squat(events, float(measurements.get("height_ratio", 1.0)))
	_process_weave(events, float(measurements.get("head_lateral_offset", 0.0)), float(measurements.get("hip_lateral_offset", 0.0)), float(measurements.get("head_drop_ratio", 0.0)))
	if _get_non_punch_backend_for_family("side_step") == BACKEND_THRESHOLD:
		_process_sidestep(events, float(measurements.get("lateral_offset", 0.0)), float(measurements.get("head_lateral_offset", 0.0)), float(measurements.get("hip_lateral_offset", 0.0)))
	if _get_non_punch_backend_for_family("knee_strike") == BACKEND_THRESHOLD:
		if left_foot_confidence >= lower_body_confidence_gate:
			_process_knee(events, "left", float(measurements.get("left_knee_rise", 0.0)), float(measurements.get("left_foot_rise", 0.0)), float(measurements.get("right_knee_rise", 0.0)), left_hip, left_ankle, torso_height)
		if right_foot_confidence >= lower_body_confidence_gate:
			_process_knee(events, "right", float(measurements.get("right_knee_rise", 0.0)), float(measurements.get("right_foot_rise", 0.0)), float(measurements.get("left_knee_rise", 0.0)), right_hip, right_ankle, torso_height)
	if _get_non_punch_backend_for_family("leg_lift") == BACKEND_THRESHOLD:
		if left_foot_confidence >= lower_body_confidence_gate:
			_process_leg_lift(events, "left", float(measurements.get("left_leg_angle_from_core_deg", 0.0)), left_hip, left_ankle, torso_height)
		if right_foot_confidence >= lower_body_confidence_gate:
			_process_leg_lift(events, "right", float(measurements.get("right_leg_angle_from_core_deg", 0.0)), right_hip, right_ankle, torso_height)
	if _any_punch_family_uses_backend(BACKEND_PROTOTYPE):
		events.append_array(_filter_events_for_backend(_prototype_punch_matcher.process_window(landmarks_by_id, metrics, timestamp_ms), BACKEND_PROTOTYPE))
	if _any_punch_family_uses_backend(BACKEND_CLASSIFIER):
		events.append_array(_filter_events_for_backend(_learned_punch_classifier.process_window(landmarks_by_id, metrics, timestamp_ms), BACKEND_CLASSIFIER))
	if _get_punch_backend_for_family("straight_punch") == BACKEND_THRESHOLD:
		_process_straight_punch(events, "left", left_shoulder, left_elbow, left_wrist, measurements, shoulder_width, timestamp_ms, tracking_frame)
		_process_straight_punch(events, "right", right_shoulder, right_elbow, right_wrist, measurements, shoulder_width, timestamp_ms, tracking_frame)
	if _get_punch_backend_for_family("hook") == BACKEND_THRESHOLD:
		_process_hook(events, "left", left_shoulder, left_elbow, left_wrist, float(measurements.get("left_elbow_bend_deg", 0.0)), shoulder_width, timestamp_ms, tracking_frame)
		_process_hook(events, "right", right_shoulder, right_elbow, right_wrist, float(measurements.get("right_elbow_bend_deg", 0.0)), shoulder_width, timestamp_ms, tracking_frame)
	if _get_punch_backend_for_family("uppercut") == BACKEND_THRESHOLD:
		_process_uppercut(events, "left", left_shoulder, left_elbow, left_wrist, float(measurements.get("left_elbow_bend_deg", 0.0)), shoulder_width, timestamp_ms, tracking_frame)
		_process_uppercut(events, "right", right_shoulder, right_elbow, right_wrist, float(measurements.get("right_elbow_bend_deg", 0.0)), shoulder_width, timestamp_ms, tracking_frame)
	if not _has_any_event(events, ["punch_left", "hook_left", "uppercut_left"]):
		_process_flow_trail(events, "left", left_hand_velocity, shoulder_width, shoulder_center, timestamp_ms)
		_process_flow_swing(events, "left", left_hand_velocity, shoulder_width, shoulder_center, timestamp_ms)
	if not _has_any_event(events, ["punch_right", "hook_right", "uppercut_right"]):
		_process_flow_trail(events, "right", right_hand_velocity, shoulder_width, shoulder_center, timestamp_ms)
		_process_flow_swing(events, "right", right_hand_velocity, shoulder_width, shoulder_center, timestamp_ms)
	return events

func _process_straight_punch(events: Array, side: String, shoulder: Dictionary, elbow: Dictionary, wrist: Dictionary, measurements: Dictionary, shoulder_width: float, timestamp_ms: int, tracking_frame: Dictionary = {}) -> void:
	var straight_punch_config := _get_straight_punch_config()
	if not bool(straight_punch_config.get("enabled", true)):
		_set_straight_punch_state(side, _build_straight_punch_state(STRAIGHT_PUNCH_STATE_TRACKING_LOST))
		return
	var event_name := "punch_%s" % side
	var state := _get_straight_punch_state(side)
	_clear_same_family_block(state)
	var use_hand_tracking := _straight_punch_uses_hand_tracking()
	var pose_tracking_valid := _is_pose_valid_for_straight_punch(shoulder, wrist, shoulder_width)
	var hand_payload := _get_tracking_hand_payload(tracking_frame, side)
	var bbox: Dictionary = hand_payload.get("bbox", {}) if hand_payload.get("bbox", {}) is Dictionary else {}
	var bbox_area := maxf(float(bbox.get("area", 0.0)), 0.0)
	var hand_tracking_state := String(hand_payload.get("tracking_state", "idle")) if use_hand_tracking else ("pose_tracked" if pose_tracking_valid else "pose_missing")
	var hand_tracking_valid := bool(hand_payload.get("tracking_valid", false)) if use_hand_tracking else pose_tracking_valid
	var fresh_sample := _is_fresh_tracking_hand_sample(hand_payload, state) if use_hand_tracking else pose_tracking_valid
	var valid_sample := _is_valid_tracking_hand_sample(hand_payload) if use_hand_tracking else pose_tracking_valid
	var wrist_position := PoseMetrics.to_vector3(wrist)
	var elbow_shoulder_xy_distance := PoseMetrics.distance_2d(elbow, shoulder)
	var max_elbow_shoulder_xy_distance := maxf(float(straight_punch_config.get("max_elbow_shoulder_xy_distance", STRAIGHT_PUNCH_DEFAULT_MAX_ELBOW_SHOULDER_XY_DISTANCE)), 0.0)
	var elbow_shoulder_xy_gate_passed := elbow_shoulder_xy_distance <= max_elbow_shoulder_xy_distance + 0.000001
	var wrist_lateral_angle_from_elbow_vertical_deg := _compute_wrist_lateral_angle_from_elbow_vertical_deg(elbow, wrist)
	var min_wrist_lateral_angle_from_elbow_vertical_deg := maxf(float(straight_punch_config.get("min_wrist_lateral_angle_from_elbow_vertical_deg", STRAIGHT_PUNCH_DEFAULT_MIN_WRIST_LATERAL_ANGLE_FROM_ELBOW_VERTICAL_DEG)), 0.0)
	var wrist_lateral_angle_gate_passed := wrist_lateral_angle_from_elbow_vertical_deg + 0.000001 >= min_wrist_lateral_angle_from_elbow_vertical_deg
	var velocity_signal_position := _resolve_straight_punch_velocity_signal_position(state, elbow, wrist_position)
	var wrist_velocity_vector := _resolve_straight_punch_wrist_velocity(state, velocity_signal_position, timestamp_ms, fresh_sample, straight_punch_config)
	var forward_depth_spike := _resolve_straight_punch_forward_depth_spike(state, timestamp_ms, fresh_sample, straight_punch_config)
	var depth_analysis := _update_family_depth_signal("straight_punch", side, state, timestamp_ms, fresh_sample, tracking_frame, shoulder, elbow, wrist, straight_punch_config)
	var wrist_velocity := maxf(wrist_velocity_vector.length(), 0.0)
	var wrist_forward_velocity := maxf(-float(wrist_velocity_vector.z), 0.0)
	state["last_bbox_area"] = bbox_area
	state["last_wrist_velocity"] = wrist_velocity
	state["last_wrist_velocity_vector"] = wrist_velocity_vector
	state["last_wrist_forward_velocity"] = wrist_forward_velocity
	state["last_forward_depth_spike"] = forward_depth_spike
	state["last_sample_fresh"] = fresh_sample
	state["hand_tracking_state"] = hand_tracking_state
	state["hand_sample_source"] = String(hand_payload.get("sample_source", "none")) if use_hand_tracking else "pose"
	state["pose_tracking_valid"] = pose_tracking_valid
	state["elbow_shoulder_xy_distance"] = elbow_shoulder_xy_distance
	state["max_elbow_shoulder_xy_distance"] = max_elbow_shoulder_xy_distance
	state["elbow_shoulder_xy_gate_passed"] = elbow_shoulder_xy_gate_passed
	state["wrist_lateral_angle_from_elbow_vertical_deg"] = wrist_lateral_angle_from_elbow_vertical_deg
	state["min_wrist_lateral_angle_from_elbow_vertical_deg"] = min_wrist_lateral_angle_from_elbow_vertical_deg
	state["wrist_lateral_angle_gate_passed"] = wrist_lateral_angle_gate_passed
	_apply_depth_analysis_to_state(state, depth_analysis)
	var sample_window_size := max(2, int(straight_punch_config.get("sample_window_size", STRAIGHT_PUNCH_DEFAULT_SAMPLE_WINDOW_SIZE)))
	var wrist_velocity_history: Array = (state.get("wrist_velocity_history", []) as Array).duplicate(true)
	state["wrist_velocity_history"] = wrist_velocity_history
	state["recent_peak_wrist_velocity"] = _window_peak_float(wrist_velocity_history)
	var bbox_area_growth_history: Array = (state.get("bbox_area_growth_history", []) as Array).duplicate(true)
	state["bbox_area_growth_history"] = bbox_area_growth_history
	state["recent_peak_bbox_area_growth"] = _window_peak_float(bbox_area_growth_history)
	var forward_depth_spike_history: Array = (state.get("forward_depth_spike_history", []) as Array).duplicate(true)
	state["forward_depth_spike_history"] = forward_depth_spike_history
	state["recent_peak_forward_depth_spike"] = _window_peak_float(forward_depth_spike_history)
	var depth_closeness_history: Array = (state.get("depth_closeness_history", []) as Array).duplicate(true)
	state["depth_closeness_history"] = depth_closeness_history
	var bbox_area_window_history: Array = (state.get("bbox_area_window_history", []) as Array).duplicate(true)
	state["bbox_area_window_history"] = bbox_area_window_history
	state["hand_tracking_valid"] = hand_tracking_valid
	state["stale_frames"] = int(hand_payload.get("stale_frames", 0)) if use_hand_tracking else 0
	state["current_timestamp_ms"] = timestamp_ms
	if not pose_tracking_valid:
		valid_sample = false
		fresh_sample = false
		state["last_sample_fresh"] = false
		state["hand_tracking_state"] = "pose_missing"
		state["hand_tracking_valid"] = false
		state["pose_tracking_valid"] = false
	if not valid_sample:
		state["bbox_area_history"] = []
		state["wrist_velocity_history"] = []
		state["wrist_position_history"] = []
		state["recent_peak_wrist_velocity"] = 0.0
		state["last_wrist_velocity_vector"] = Vector3.ZERO
		state["last_lateral_velocity"] = 0.0
		state["last_vertical_velocity"] = 0.0
		state["last_wrist_velocity_window_span_ms"] = 0
		state["bbox_area_window_history"] = []
		state["bbox_area_growth_history"] = []
		state["recent_peak_bbox_area_growth"] = 0.0
		state["forward_depth_spike_history"] = []
		state["recent_peak_forward_depth_spike"] = 0.0
		state["depth_closeness_history"] = []
		_reset_depth_analysis_state(state)
		state["positive_growth_samples"] = 0
		state["grace_ms_remaining"] = 0
		state["grace_deadline_timestamp_ms"] = 0
		state["trigger_bbox_area"] = 0.0
		state["last_bbox_area_growth_window_span_ms"] = 0
		state["last_forward_depth_spike_window_span_ms"] = 0
		state["last_forward_depth_spike"] = 0.0
		state["last_bbox_area_growth"] = 0.0
		state["last_positive_bbox_growth_samples"] = 0
		state["reacquire_started_timestamp_ms"] = -1
		state["not_ready_started_timestamp_ms"] = -1
		_transition_straight_punch_state(events, side, state, STRAIGHT_PUNCH_STATE_TRACKING_LOST)
		_set_straight_punch_state(side, state)
		return

	var phase := String(state.get("phase", STRAIGHT_PUNCH_STATE_TRACKING_LOST))
	var history: Array = (state.get("bbox_area_history", []) as Array).duplicate(true)
	if fresh_sample:
		wrist_velocity_history.append(wrist_velocity)
		while wrist_velocity_history.size() > sample_window_size:
			wrist_velocity_history.remove_at(0)
		state["wrist_velocity_history"] = wrist_velocity_history
		state["recent_peak_wrist_velocity"] = _window_peak_float(wrist_velocity_history)
		history.append(bbox_area)
		while history.size() > sample_window_size:
			history.remove_at(0)
		state["bbox_area_history"] = history
		state["last_bbox_area_growth"] = _resolve_straight_punch_bbox_area_growth(state, bbox_area, timestamp_ms, straight_punch_config)
		state["positive_growth_samples"] = int(state.get("last_positive_bbox_growth_samples", 0))
		bbox_area_growth_history.append(float(state.get("last_bbox_area_growth", 0.0)))
		while bbox_area_growth_history.size() > sample_window_size:
			bbox_area_growth_history.remove_at(0)
		state["bbox_area_growth_history"] = bbox_area_growth_history
		state["recent_peak_bbox_area_growth"] = _window_peak_float(bbox_area_growth_history)
		forward_depth_spike_history.append(forward_depth_spike)
		while forward_depth_spike_history.size() > sample_window_size:
			forward_depth_spike_history.remove_at(0)
		state["forward_depth_spike_history"] = forward_depth_spike_history
		state["recent_peak_forward_depth_spike"] = _window_peak_float(forward_depth_spike_history)
		depth_closeness_history = (state.get("depth_closeness_history", []) as Array).duplicate(true)
		state["depth_closeness_history"] = depth_closeness_history
		state["reacquire_started_timestamp_ms"] = timestamp_ms if phase == STRAIGHT_PUNCH_STATE_TRACKING_LOST and int(state.get("reacquire_started_timestamp_ms", -1)) < 0 else int(state.get("reacquire_started_timestamp_ms", -1))
		if use_hand_tracking:
			state["last_observation_frame_index"] = int(hand_payload.get("frame_index", -1))
			state["last_observation_timestamp_seconds"] = float(hand_payload.get("timestamp_seconds", -1.0))
		else:
			state["last_observation_frame_index"] = -1
			state["last_observation_timestamp_seconds"] = float(timestamp_ms) / 1000.0
	else:
		state["bbox_area_history"] = history
		state["wrist_velocity_history"] = wrist_velocity_history
		state["bbox_area_window_history"] = bbox_area_window_history
		state["bbox_area_growth_history"] = bbox_area_growth_history
		state["forward_depth_spike_history"] = forward_depth_spike_history
		state["depth_closeness_history"] = depth_closeness_history

	if phase == STRAIGHT_PUNCH_STATE_TRACKING_LOST:
		if fresh_sample:
			var reacquire_stable_ms := max(0, int(straight_punch_config.get("lost_tracking_reacquire_stable_ms", STRAIGHT_PUNCH_DEFAULT_REACQUIRE_STABLE_MS)))
			var sample_stable_ms := max(0, int(hand_payload.get("stable_ms", reacquire_stable_ms))) if use_hand_tracking else max(0, timestamp_ms - int(state.get("reacquire_started_timestamp_ms", timestamp_ms)))
			if sample_stable_ms >= reacquire_stable_ms:
				state["bbox_area_history"] = [bbox_area]
				state["wrist_velocity_history"] = [wrist_velocity]
				state["wrist_position_history"] = [{"timestamp_ms": timestamp_ms, "position": velocity_signal_position}]
				state["recent_peak_wrist_velocity"] = wrist_velocity
				state["last_wrist_velocity_vector"] = Vector3.ZERO
				state["last_wrist_velocity_window_span_ms"] = 0
				state["bbox_area_window_history"] = [{"timestamp_ms": timestamp_ms, "area": bbox_area}]
				state["bbox_area_growth_history"] = []
				state["recent_peak_bbox_area_growth"] = 0.0
				state["forward_depth_spike_history"] = []
				state["recent_peak_forward_depth_spike"] = 0.0
				state["depth_closeness_history"] = []
				_reset_depth_analysis_state(state)
				state["positive_growth_samples"] = 0
				state["last_bbox_area_growth_window_span_ms"] = 0
				state["last_forward_depth_spike_window_span_ms"] = 0
				state["last_forward_depth_spike"] = 0.0
				state["last_bbox_area_growth"] = 0.0
				state["last_positive_bbox_growth_samples"] = 0
				state["not_ready_started_timestamp_ms"] = -1
				state["reacquire_started_timestamp_ms"] = -1
				_transition_straight_punch_state(events, side, state, STRAIGHT_PUNCH_STATE_READY)
		_set_straight_punch_state(side, state)
		return

	if phase == STRAIGHT_PUNCH_STATE_READY:
		if fresh_sample:
			var min_velocity := maxf(float(straight_punch_config.get("min_velocity", STRAIGHT_PUNCH_DEFAULT_MIN_WRIST_VELOCITY)), 0.0)
			var min_bbox_area_growth := maxf(float(straight_punch_config.get("min_bbox_area_growth", STRAIGHT_PUNCH_DEFAULT_MIN_BBOX_AREA_GROWTH)), 0.0)
			var min_positive_growth_samples := max(1, int(straight_punch_config.get("min_positive_growth_samples", STRAIGHT_PUNCH_DEFAULT_MIN_POSITIVE_GROWTH_SAMPLES)))
			var recent_peak_wrist_velocity := maxf(float(state.get("recent_peak_wrist_velocity", wrist_velocity)), wrist_velocity)
			var recent_peak_bbox_area_growth := maxf(float(state.get("recent_peak_bbox_area_growth", state.get("last_bbox_area_growth", 0.0))), float(state.get("last_bbox_area_growth", 0.0)))
			var ready_to_trigger := recent_peak_wrist_velocity >= min_velocity and elbow_shoulder_xy_gate_passed and wrist_lateral_angle_gate_passed
			if use_hand_tracking:
				ready_to_trigger = ready_to_trigger and recent_peak_bbox_area_growth + 0.000001 >= min_bbox_area_growth and int(state.get("positive_growth_samples", 0)) >= min_positive_growth_samples
			if bool(depth_analysis.get("gate_applied", false)):
				ready_to_trigger = ready_to_trigger and bool(depth_analysis.get("gate_passed", false))
			if ready_to_trigger:
				var blocking_state := _get_same_family_threshold_blocking_state("straight_punch", side, timestamp_ms)
				if not blocking_state.is_empty():
					_apply_same_family_block(state, blocking_state)
				else:
					state["trigger_bbox_area"] = bbox_area
					var triggered_grace_ms := max(0, int(straight_punch_config.get("triggered_grace_ms", STRAIGHT_PUNCH_DEFAULT_TRIGGERED_GRACE_MS)))
					state["grace_deadline_timestamp_ms"] = timestamp_ms + triggered_grace_ms
					state["grace_ms_remaining"] = triggered_grace_ms
					state["not_ready_started_timestamp_ms"] = -1
					_emit_power_event(events, event_name, _compute_straight_punch_power(recent_peak_wrist_velocity, bbox_area, state, straight_punch_config, recent_peak_bbox_area_growth))
					_transition_straight_punch_state(events, side, state, STRAIGHT_PUNCH_STATE_TRIGGERED)
		_set_straight_punch_state(side, state)
		return

	if phase == STRAIGHT_PUNCH_STATE_TRIGGERED:
		var grace_deadline_timestamp_ms := int(state.get("grace_deadline_timestamp_ms", 0))
		var grace_ms_remaining := max(0, grace_deadline_timestamp_ms - timestamp_ms)
		state["grace_ms_remaining"] = grace_ms_remaining
		if timestamp_ms >= grace_deadline_timestamp_ms:
			state["not_ready_started_timestamp_ms"] = timestamp_ms
			_transition_straight_punch_state(events, side, state, STRAIGHT_PUNCH_STATE_NOT_READY)
		_set_straight_punch_state(side, state)
		return

	if phase == STRAIGHT_PUNCH_STATE_NOT_READY and fresh_sample:
		if use_hand_tracking:
			var retract_epsilon := maxf(float(straight_punch_config.get("bbox_area_retract_epsilon", STRAIGHT_PUNCH_DEFAULT_BBOX_AREA_RETRACT_EPSILON)), 0.0)
			var trigger_bbox_area := maxf(float(state.get("trigger_bbox_area", 0.0)), 0.0)
			if bbox_area <= maxf(trigger_bbox_area - retract_epsilon, 0.0):
				state["trigger_bbox_area"] = 0.0
				state["grace_ms_remaining"] = 0
				state["grace_deadline_timestamp_ms"] = 0
				state["bbox_area_history"] = [bbox_area]
				state["wrist_velocity_history"] = [wrist_velocity]
				state["wrist_position_history"] = [{"timestamp_ms": timestamp_ms, "position": velocity_signal_position}]
				state["recent_peak_wrist_velocity"] = wrist_velocity
				state["last_wrist_velocity_vector"] = Vector3.ZERO
				state["last_wrist_velocity_window_span_ms"] = 0
				state["bbox_area_window_history"] = [{"timestamp_ms": timestamp_ms, "area": bbox_area}]
				state["bbox_area_growth_history"] = []
				state["recent_peak_bbox_area_growth"] = 0.0
				state["forward_depth_spike_history"] = []
				state["recent_peak_forward_depth_spike"] = 0.0
				state["depth_closeness_history"] = []
				_reset_depth_analysis_state(state)
				state["positive_growth_samples"] = 0
				state["last_bbox_area_growth_window_span_ms"] = 0
				state["last_forward_depth_spike_window_span_ms"] = 0
				state["last_forward_depth_spike"] = 0.0
				state["last_bbox_area_growth"] = 0.0
				state["not_ready_started_timestamp_ms"] = -1
				_transition_straight_punch_state(events, side, state, STRAIGHT_PUNCH_STATE_READY)
		else:
			var pose_only_rearm_ms := max(0, int(straight_punch_config.get("pose_only_rearm_ms", STRAIGHT_PUNCH_DEFAULT_POSE_ONLY_REARM_MS)))
			var not_ready_started_timestamp_ms := int(state.get("not_ready_started_timestamp_ms", timestamp_ms))
			if timestamp_ms - not_ready_started_timestamp_ms >= pose_only_rearm_ms:
				state["trigger_bbox_area"] = 0.0
				state["grace_ms_remaining"] = 0
				state["grace_deadline_timestamp_ms"] = 0
				state["bbox_area_history"] = [bbox_area]
				state["wrist_velocity_history"] = [wrist_velocity]
				state["wrist_position_history"] = [{"timestamp_ms": timestamp_ms, "position": velocity_signal_position}]
				state["recent_peak_wrist_velocity"] = wrist_velocity
				state["last_wrist_velocity_vector"] = Vector3.ZERO
				state["last_wrist_velocity_window_span_ms"] = 0
				state["bbox_area_window_history"] = [{"timestamp_ms": timestamp_ms, "area": bbox_area}]
				state["bbox_area_growth_history"] = []
				state["recent_peak_bbox_area_growth"] = 0.0
				state["forward_depth_spike_history"] = []
				state["recent_peak_forward_depth_spike"] = 0.0
				state["depth_closeness_history"] = []
				_reset_depth_analysis_state(state)
				state["positive_growth_samples"] = 0
				state["last_bbox_area_growth_window_span_ms"] = 0
				state["last_forward_depth_spike_window_span_ms"] = 0
				state["last_forward_depth_spike"] = 0.0
				state["last_bbox_area_growth"] = 0.0
				state["not_ready_started_timestamp_ms"] = -1
				_transition_straight_punch_state(events, side, state, STRAIGHT_PUNCH_STATE_READY)
	_set_straight_punch_state(side, state)

func _process_hook(events: Array, side: String, shoulder: Dictionary, elbow: Dictionary, wrist: Dictionary, elbow_bend_deg: float, shoulder_width: float, timestamp_ms: int, tracking_frame: Dictionary = {}) -> void:
	var config := _get_hook_config()
	_process_pose_strike(events, "hook", side, "hook_%s" % side, config, shoulder, elbow, wrist, elbow_bend_deg, shoulder_width, timestamp_ms, tracking_frame)

func _process_uppercut(events: Array, side: String, shoulder: Dictionary, elbow: Dictionary, wrist: Dictionary, elbow_bend_deg: float, shoulder_width: float, timestamp_ms: int, tracking_frame: Dictionary = {}) -> void:
	var config := _get_uppercut_config()
	_process_pose_strike(events, "uppercut", side, "uppercut_%s" % side, config, shoulder, elbow, wrist, elbow_bend_deg, shoulder_width, timestamp_ms, tracking_frame)

func _process_pose_strike(events: Array, family: String, side: String, event_name: String, config: Dictionary, shoulder: Dictionary, elbow: Dictionary, wrist: Dictionary, elbow_bend_deg: float, shoulder_width: float, timestamp_ms: int, tracking_frame: Dictionary = {}) -> void:
	if not bool(config.get("enabled", true)):
		_set_pose_strike_state(family, side, _build_pose_strike_state(POSE_STRIKE_STATE_TRACKING_LOST))
		return
	var state := _get_pose_strike_state(family, side)
	_clear_same_family_block(state)
	var pose_tracking_valid := _is_pose_valid_for_pose_strike(shoulder, elbow, wrist, shoulder_width)
	var fresh_sample := pose_tracking_valid
	var wrist_position := PoseMetrics.to_vector3(wrist)
	var velocity_signal_position := _resolve_straight_punch_velocity_signal_position(state, elbow, wrist_position)
	var velocity_vector := _resolve_straight_punch_wrist_velocity(state, velocity_signal_position, timestamp_ms, fresh_sample, config)
	var motion_window := _resolve_pose_strike_motion_window(state, side, velocity_vector, timestamp_ms)
	var depth_analysis := _update_family_depth_signal(family, side, state, timestamp_ms, fresh_sample, tracking_frame, shoulder, elbow, wrist, config)
	var speed := float(motion_window.get("wrist_velocity", 0.0))
	var lateral_speed := float(motion_window.get("lateral_velocity", 0.0))
	var vertical_speed := float(motion_window.get("vertical_velocity", 0.0))
	var outward_velocity := float(motion_window.get("outward_velocity", 0.0))
	var horizontal_direction_velocity := float(motion_window.get("horizontal_direction_velocity", 0.0))
	var upward_velocity := float(motion_window.get("upward_velocity", 0.0))
	var directionality_ratio := float(motion_window.get("directionality_ratio", 0.0))
	var outward_distance := float(shoulder.get("x", 0.0) - wrist.get("x", 0.0) if side == "left" else wrist.get("x", 0.0) - shoulder.get("x", 0.0))
	var wrist_elbow_vertical_offset := absf(float(wrist.get("y", 0.0)) - float(elbow.get("y", 0.0)))
	var wrist_elbow_horizontal_offset := absf(float(wrist.get("x", 0.0)) - float(elbow.get("x", 0.0)))
	var wrist_above_elbow_offset := float(wrist.get("y", 0.0)) - float(elbow.get("y", 0.0))
	var wrist_angle_from_elbow_horizontal_deg := _compute_wrist_angle_from_elbow_horizontal_deg(elbow, wrist)
	var wrist_angle_from_elbow_vertical_deg := _compute_wrist_angle_from_elbow_vertical_deg(elbow, wrist)
	var wrist_on_required_hook_side := _is_wrist_on_required_hook_side(side, elbow, wrist)
	var wrist_above_elbow_gate_passed := _is_wrist_above_elbow_in_camera_space(elbow, wrist)
	state["last_wrist_velocity"] = speed
	state["last_wrist_velocity_vector"] = motion_window.get("averaged_velocity_vector", velocity_vector)
	state["last_lateral_velocity"] = lateral_speed
	state["last_vertical_velocity"] = vertical_speed
	state["last_sample_fresh"] = fresh_sample
	state["pose_tracking_valid"] = pose_tracking_valid
	state["tracking_state"] = "pose_tracked" if pose_tracking_valid else "pose_missing"
	state["current_timestamp_ms"] = timestamp_ms
	_apply_depth_analysis_to_state(state, depth_analysis)
	state["elbow_bend_deg"] = elbow_bend_deg
	state["outward_velocity"] = outward_velocity
	state["upward_velocity"] = upward_velocity
	state["horizontal_direction_velocity"] = horizontal_direction_velocity
	state["directionality_ratio"] = directionality_ratio
	state["outward_distance"] = outward_distance
	state["wrist_elbow_vertical_offset"] = wrist_elbow_vertical_offset
	state["wrist_elbow_horizontal_offset"] = wrist_elbow_horizontal_offset
	state["wrist_above_elbow_offset"] = wrist_above_elbow_offset
	state["wrist_angle_from_elbow_horizontal_deg"] = wrist_angle_from_elbow_horizontal_deg
	state["wrist_angle_from_elbow_vertical_deg"] = wrist_angle_from_elbow_vertical_deg
	state["wrist_on_required_hook_side"] = wrist_on_required_hook_side
	state["wrist_above_elbow_gate_passed"] = wrist_above_elbow_gate_passed
	if family == "hook":
		var current_max_hook_angle_deg := clampf(float(config.get("max_wrist_angle_from_elbow_horizontal_deg", HOOK_DEFAULT_MAX_WRIST_ANGLE_FROM_ELBOW_HORIZONTAL_DEG)), 0.0, 90.0)
		state["wrist_horizontal_angle_gate_passed"] = wrist_angle_from_elbow_horizontal_deg <= current_max_hook_angle_deg + 0.000001
	else:
		var current_max_uppercut_angle_deg := clampf(float(config.get("max_wrist_angle_from_elbow_vertical_deg", UPPERCUT_DEFAULT_MAX_WRIST_ANGLE_FROM_ELBOW_VERTICAL_DEG)), 0.0, 90.0)
		state["wrist_vertical_angle_gate_passed"] = wrist_angle_from_elbow_vertical_deg <= current_max_uppercut_angle_deg + 0.000001
	state["dominance_ratio"] = float(motion_window.get("hook_dominance_ratio", 0.0)) if family == "hook" else float(motion_window.get("uppercut_dominance_ratio", 0.0))
	if not pose_tracking_valid:
		state["wrist_velocity_history"] = []
		state["wrist_position_history"] = []
		state["recent_peak_wrist_velocity"] = 0.0
		state["last_wrist_velocity_vector"] = Vector3.ZERO
		state["last_lateral_velocity"] = 0.0
		state["last_vertical_velocity"] = 0.0
		state["last_wrist_velocity_window_span_ms"] = 0
		state["depth_closeness_history"] = []
		_reset_depth_analysis_state(state)
		state["grace_ms_remaining"] = 0
		state["grace_deadline_timestamp_ms"] = 0
		state["reacquire_started_timestamp_ms"] = -1
		state["not_ready_started_timestamp_ms"] = -1
		_transition_pose_strike_state(events, family, side, state, POSE_STRIKE_STATE_TRACKING_LOST)
		_set_pose_strike_state(family, side, state)
		return
	var phase := String(state.get("phase", POSE_STRIKE_STATE_TRACKING_LOST))
	var sample_window_size := 4
	var wrist_velocity_history: Array = (state.get("wrist_velocity_history", []) as Array).duplicate(true)
	var depth_closeness_history: Array = (state.get("depth_closeness_history", []) as Array).duplicate(true)
	state["depth_closeness_history"] = depth_closeness_history
	if fresh_sample:
		wrist_velocity_history.append(speed)
		while wrist_velocity_history.size() > sample_window_size:
			wrist_velocity_history.remove_at(0)
		state["wrist_velocity_history"] = wrist_velocity_history
		state["recent_peak_wrist_velocity"] = _window_peak_float(wrist_velocity_history)
		state["reacquire_started_timestamp_ms"] = timestamp_ms if phase == POSE_STRIKE_STATE_TRACKING_LOST and int(state.get("reacquire_started_timestamp_ms", -1)) < 0 else int(state.get("reacquire_started_timestamp_ms", -1))
	else:
		state["wrist_velocity_history"] = wrist_velocity_history
	if phase == POSE_STRIKE_STATE_TRACKING_LOST:
		var reacquire_stable_ms := max(0, int(config.get("lost_tracking_reacquire_stable_ms", POSE_STRIKE_DEFAULT_REACQUIRE_STABLE_MS)))
		if timestamp_ms - int(state.get("reacquire_started_timestamp_ms", timestamp_ms)) >= reacquire_stable_ms:
			state["wrist_velocity_history"] = [speed]
			state["wrist_position_history"] = [{"timestamp_ms": timestamp_ms, "position": velocity_signal_position}]
			state["recent_peak_wrist_velocity"] = speed
			state["last_wrist_velocity_vector"] = Vector3.ZERO
			state["last_lateral_velocity"] = 0.0
			state["last_vertical_velocity"] = 0.0
			state["last_wrist_velocity_window_span_ms"] = 0
			state["depth_closeness_history"] = []
			_reset_depth_analysis_state(state)
			state["not_ready_started_timestamp_ms"] = -1
			state["reacquire_started_timestamp_ms"] = -1
			_transition_pose_strike_state(events, family, side, state, POSE_STRIKE_STATE_READY)
		_set_pose_strike_state(family, side, state)
		return
	if phase == POSE_STRIKE_STATE_READY:
		var ready_to_trigger := false
		var min_velocity := maxf(float(config.get("min_velocity", config.get("min_punch_velocity", POSE_STRIKE_DEFAULT_MIN_PUNCH_VELOCITY))), 0.0)
		if family == "hook":
			var max_wrist_angle_from_elbow_horizontal_deg := clampf(float(config.get("max_wrist_angle_from_elbow_horizontal_deg", HOOK_DEFAULT_MAX_WRIST_ANGLE_FROM_ELBOW_HORIZONTAL_DEG)), 0.0, 90.0)
			var wrist_horizontal_angle_gate_passed := wrist_angle_from_elbow_horizontal_deg <= max_wrist_angle_from_elbow_horizontal_deg + 0.000001
			state["wrist_horizontal_angle_gate_passed"] = wrist_horizontal_angle_gate_passed
			ready_to_trigger = speed >= min_velocity and wrist_horizontal_angle_gate_passed and wrist_on_required_hook_side
		else:
			var max_wrist_angle_from_elbow_vertical_deg := clampf(float(config.get("max_wrist_angle_from_elbow_vertical_deg", UPPERCUT_DEFAULT_MAX_WRIST_ANGLE_FROM_ELBOW_VERTICAL_DEG)), 0.0, 90.0)
			var wrist_vertical_angle_gate_passed := wrist_angle_from_elbow_vertical_deg <= max_wrist_angle_from_elbow_vertical_deg + 0.000001
			state["wrist_vertical_angle_gate_passed"] = wrist_vertical_angle_gate_passed
			ready_to_trigger = speed >= min_velocity and wrist_vertical_angle_gate_passed and wrist_above_elbow_gate_passed
		if bool(depth_analysis.get("gate_applied", false)):
			ready_to_trigger = ready_to_trigger and bool(depth_analysis.get("gate_passed", false))
		if ready_to_trigger:
			var blocking_state := _get_same_family_threshold_blocking_state(family, side, timestamp_ms)
			if not blocking_state.is_empty():
				_apply_same_family_block(state, blocking_state)
			else:
				var triggered_grace_ms := max(0, int(config.get("triggered_grace_ms", POSE_STRIKE_DEFAULT_TRIGGERED_GRACE_MS)))
				state["grace_deadline_timestamp_ms"] = timestamp_ms + triggered_grace_ms
				state["grace_ms_remaining"] = triggered_grace_ms
				state["not_ready_started_timestamp_ms"] = -1
				_emit_power_event(events, event_name, _compute_pose_strike_power(family, speed, horizontal_direction_velocity, upward_velocity, config))
				_transition_pose_strike_state(events, family, side, state, POSE_STRIKE_STATE_TRIGGERED)
		_set_pose_strike_state(family, side, state)
		return
	if phase == POSE_STRIKE_STATE_TRIGGERED:
		var grace_deadline_timestamp_ms := int(state.get("grace_deadline_timestamp_ms", 0))
		var grace_ms_remaining := max(0, grace_deadline_timestamp_ms - timestamp_ms)
		state["grace_ms_remaining"] = grace_ms_remaining
		if timestamp_ms >= grace_deadline_timestamp_ms:
			state["not_ready_started_timestamp_ms"] = timestamp_ms
			_transition_pose_strike_state(events, family, side, state, POSE_STRIKE_STATE_NOT_READY)
		_set_pose_strike_state(family, side, state)
		return
	if phase == POSE_STRIKE_STATE_NOT_READY:
		var pose_only_rearm_ms := max(0, int(config.get("pose_only_rearm_ms", POSE_STRIKE_DEFAULT_POSE_ONLY_REARM_MS)))
		var not_ready_started_timestamp_ms := int(state.get("not_ready_started_timestamp_ms", timestamp_ms))
		if timestamp_ms - not_ready_started_timestamp_ms >= pose_only_rearm_ms:
			state["grace_ms_remaining"] = 0
			state["grace_deadline_timestamp_ms"] = 0
			state["wrist_velocity_history"] = [speed]
			state["wrist_position_history"] = [{"timestamp_ms": timestamp_ms, "position": velocity_signal_position}]
			state["recent_peak_wrist_velocity"] = speed
			state["last_wrist_velocity_vector"] = Vector3.ZERO
			state["last_lateral_velocity"] = 0.0
			state["last_vertical_velocity"] = 0.0
			state["last_wrist_velocity_window_span_ms"] = 0
			state["depth_closeness_history"] = []
			_reset_depth_analysis_state(state)
			state["not_ready_started_timestamp_ms"] = -1
			_transition_pose_strike_state(events, family, side, state, POSE_STRIKE_STATE_READY)
		_set_pose_strike_state(family, side, state)
		return
	_set_pose_strike_state(family, side, state)

func _process_flow_swing(events: Array, side: String, hand_velocity: Vector3, shoulder_width: float, shoulder_center: Vector2, timestamp_ms: int) -> void:
	var event_name := "swing_%s" % side
	if hand_velocity.length() <= shoulder_width * 0.90:
		_set_ready(event_name, true)
	if not _is_ready(event_name):
		return
	if _get_state("trail_%s" % side):
		return
	var analysis := _analyze_flow_motion(side, shoulder_width, shoulder_center, FLOW_SWING_WINDOW_MAX_MS)
	if analysis.is_empty():
		return
	var duration_ms := int(analysis.get("duration_ms", 0))
	if duration_ms < FLOW_SWING_WINDOW_MIN_MS or duration_ms > FLOW_SWING_WINDOW_MAX_MS:
		return
	if float(analysis.get("avg_confidence", 0.0)) < 0.62:
		return
	if float(analysis.get("arc_length", 0.0)) < shoulder_width * FLOW_SWING_MIN_ARC_RATIO:
		return
	if float(analysis.get("net_distance", 0.0)) < shoulder_width * FLOW_SWING_MIN_TRAVEL_RATIO:
		return
	if float(analysis.get("directional_consistency", 0.0)) < 0.52:
		return
	if hand_velocity.length() < shoulder_width * FLOW_SWING_MIN_SPEED_RATIO:
		return
	var direction := int(analysis.get("direction", -1))
	if direction < 0:
		return
	var placement := int(analysis.get("placement", -1))
	if placement < 0:
		return
	var flow_meta := _get_flow_meta(event_name)
	flow_meta["last_emit_ms"] = timestamp_ms
	flow_meta["placement"] = placement
	flow_meta["placement_ui_label"] = int(analysis.get("placement_ui_label", 0))
	flow_meta["direction"] = direction
	flow_meta["direction_ui_label"] = int(analysis.get("direction_ui_label", 0))
	flow_meta["duration_ms"] = int(analysis.get("duration_ms", 0))
	flow_meta["arc_length"] = float(analysis.get("arc_length", 0.0))
	flow_meta["net_distance"] = float(analysis.get("net_distance", 0.0))
	flow_meta["directional_consistency"] = float(analysis.get("directional_consistency", 0.0))
	flow_meta["lane_spread"] = float(analysis.get("lane_spread", 0.0))
	flow_meta["avg_confidence"] = float(analysis.get("avg_confidence", 0.0))
	_set_flow_meta(event_name, flow_meta)
	_emit_flow_event(events, event_name, placement, direction)
	_set_ready(event_name, false)

func _process_flow_trail(events: Array, side: String, hand_velocity: Vector3, shoulder_width: float, shoulder_center: Vector2, timestamp_ms: int) -> void:
	var state_name := "trail_%s" % side
	var trail_meta: Dictionary = _get_flow_meta(state_name)
	var analysis := _analyze_flow_motion(side, shoulder_width, shoulder_center, FLOW_HISTORY_MAX_MS)
	var active := _get_state(state_name)
	if analysis.is_empty():
		if active:
			_gesture_state["states"][state_name] = false
		return
	var sustained := int(analysis.get("duration_ms", 0)) >= FLOW_TRAIL_WINDOW_MIN_MS
	sustained = sustained and float(analysis.get("avg_confidence", 0.0)) >= 0.60
	sustained = sustained and float(analysis.get("arc_length", 0.0)) >= shoulder_width * FLOW_TRAIL_MIN_ARC_RATIO
	sustained = sustained and float(analysis.get("net_distance", 0.0)) >= shoulder_width * FLOW_TRAIL_MIN_TRAVEL_RATIO
	sustained = sustained and float(analysis.get("directional_consistency", 0.0)) >= 0.76
	sustained = sustained and float(analysis.get("lane_spread", 0.0)) <= shoulder_width * 0.82
	sustained = sustained and hand_velocity.length() >= shoulder_width * FLOW_TRAIL_MIN_SPEED_RATIO
	if not sustained:
		if active and (hand_velocity.length() <= shoulder_width * 0.75 or float(analysis.get("directional_consistency", 0.0)) < 0.55):
			_gesture_state["states"][state_name] = false
		return
	var direction := int(analysis.get("direction", -1))
	if direction < 0:
		return
	var placement := int(analysis.get("placement", -1))
	if placement < 0:
		return
	if not active:
		_gesture_state["states"][state_name] = true
	var last_emit_ms := int(trail_meta.get("last_emit_ms", 0))
	if active and timestamp_ms - last_emit_ms < FLOW_TRAIL_EMIT_INTERVAL_MS and int(trail_meta.get("direction", -1)) == direction and int(trail_meta.get("placement", -1)) == placement:
		return
	trail_meta["last_emit_ms"] = timestamp_ms
	trail_meta["placement"] = placement
	trail_meta["placement_ui_label"] = int(analysis.get("placement_ui_label", 0))
	trail_meta["direction"] = direction
	trail_meta["direction_ui_label"] = int(analysis.get("direction_ui_label", 0))
	trail_meta["duration_ms"] = int(analysis.get("duration_ms", 0))
	trail_meta["arc_length"] = float(analysis.get("arc_length", 0.0))
	trail_meta["net_distance"] = float(analysis.get("net_distance", 0.0))
	trail_meta["directional_consistency"] = float(analysis.get("directional_consistency", 0.0))
	trail_meta["lane_spread"] = float(analysis.get("lane_spread", 0.0))
	trail_meta["avg_confidence"] = float(analysis.get("avg_confidence", 0.0))
	_set_flow_meta(state_name, trail_meta)
	_emit_flow_event(events, state_name, placement, direction)

func _update_flow_hand_history(side: String, wrist: Dictionary, confidence: float, timestamp_ms: int) -> void:
	var history_name := "%s_hand" % side
	var history: Array = _get_flow_history(history_name)
	if wrist.is_empty() or confidence < 0.35:
		history.clear()
		_set_flow_history(history_name, history)
		return
	history.append({
		"timestamp_ms": timestamp_ms,
		"position": PoseMetrics.to_vector2(wrist),
		"confidence": confidence,
	})
	while history.size() > 0 and timestamp_ms - int(history[0].get("timestamp_ms", timestamp_ms)) > FLOW_HISTORY_MAX_MS:
		history.remove_at(0)
	_set_flow_history(history_name, history)

func _analyze_flow_motion(side: String, shoulder_width: float, shoulder_center: Vector2, max_window_ms: int) -> Dictionary:
	var history: Array = _get_flow_history("%s_hand" % side)
	if history.size() < 3:
		return {}
	var latest_timestamp := int(history[history.size() - 1].get("timestamp_ms", 0))
	var samples: Array = []
	for sample_variant: Variant in history:
		if not sample_variant is Dictionary:
			continue
		var sample: Dictionary = sample_variant
		if latest_timestamp - int(sample.get("timestamp_ms", latest_timestamp)) <= max_window_ms:
			samples.append(sample)
	if samples.size() < 3:
		return {}
	var first: Dictionary = samples[0]
	var last: Dictionary = samples[samples.size() - 1]
	var first_pos: Vector2 = first.get("position", Vector2.ZERO)
	var last_pos: Vector2 = last.get("position", Vector2.ZERO)
	var arc_length := 0.0
	var confidence_total := 0.0
	var direction_sum := Vector2.ZERO
	var min_x := first_pos.x
	var max_x := first_pos.x
	var avg_position_total := Vector2.ZERO
	for idx in range(samples.size()):
		var sample: Dictionary = samples[idx]
		var position: Vector2 = sample.get("position", Vector2.ZERO)
		confidence_total += float(sample.get("confidence", 0.0))
		avg_position_total += position
		min_x = minf(min_x, position.x)
		max_x = maxf(max_x, position.x)
		if idx == 0:
			continue
		var previous: Dictionary = samples[idx - 1]
		var previous_position: Vector2 = previous.get("position", Vector2.ZERO)
		var delta := position - previous_position
		var segment_length := delta.length()
		arc_length += segment_length
		if segment_length > 0.000001:
			direction_sum += delta.normalized() * segment_length
	var net_delta := last_pos - first_pos
	var direction_index := _flow_ring_index_from_vector(net_delta)
	if direction_index < 0:
		return {}
	var avg_position := avg_position_total / float(samples.size())
	var placement_index := _flow_placement_index(avg_position, shoulder_center, shoulder_width)
	if placement_index < 0:
		return {}
	return {
		"duration_ms": maxi(int(last.get("timestamp_ms", 0)) - int(first.get("timestamp_ms", 0)), 0),
		"sample_count": samples.size(),
		"arc_length": arc_length,
		"net_distance": net_delta.length(),
		"net_delta": net_delta,
		"avg_confidence": confidence_total / float(samples.size()),
		"directional_consistency": direction_sum.length() / maxf(arc_length, 0.000001),
		"placement": placement_index,
		"placement_ui_label": placement_index + 1,
		"direction": direction_index,
		"direction_ui_label": direction_index + 1,
		"lane_spread": max_x - min_x,
		"avg_position": avg_position,
		"avg_x": avg_position.x,
		"avg_y": avg_position.y,
		"min_x": min_x,
		"max_x": max_x,
		"latest_position": last_pos,
	}

func _flow_ring_index_from_vector(vector: Vector2) -> int:
	if vector.length() <= 0.000001:
		return -1
	var angle_deg := rad_to_deg(atan2(vector.y, vector.x))
	var shifted_deg := fposmod(FLOW_RING_START_ANGLE_DEGREES + FLOW_RING_SECTOR_DEGREES * 0.5 - angle_deg, 360.0)
	return int(floor(shifted_deg / FLOW_RING_SECTOR_DEGREES)) % FLOW_DIRECTION_RING_COUNT

func _flow_placement_index(avg_position: Vector2, shoulder_center: Vector2, shoulder_width: float) -> int:
	var offset := avg_position - shoulder_center
	if offset.length() <= maxf(shoulder_width, 0.000001) * FLOW_PLACEMENT_CENTER_RADIUS_RATIO:
		return FLOW_PLACEMENT_CENTER_INDEX
	return _flow_ring_index_from_vector(offset)

func _emit_flow_event(events: Array, event_name: String, placement: int, direction: int) -> void:
	events.append({
		"name": StringName(event_name),
		"placement": placement,
		"direction": direction,
	})

func _has_any_event(events: Array, event_names: Array) -> bool:
	for event_variant: Variant in events:
		if not event_variant is Dictionary:
			continue
		var event_name := String(event_variant.get("name", ""))
		if event_names.has(event_name):
			return true
	return false

func _get_flow_history(history_name: String) -> Array:
	return (_gesture_state.get("flow", {}).get(history_name, []) as Array).duplicate(true)

func _set_flow_history(history_name: String, history: Array) -> void:
	var flow: Dictionary = _gesture_state.get("flow", {})
	flow[history_name] = history
	_gesture_state["flow"] = flow

func _get_flow_meta(state_name: String) -> Dictionary:
	return (_gesture_state.get("flow", {}).get(state_name, {}) as Dictionary).duplicate(true)

func _set_flow_meta(state_name: String, data: Dictionary) -> void:
	var flow: Dictionary = _gesture_state.get("flow", {})
	flow[state_name] = data
	_gesture_state["flow"] = flow

func _process_guard(events: Array, nose: Dictionary, left_shoulder: Dictionary, right_shoulder: Dictionary, left_elbow: Dictionary, right_elbow: Dictionary, left_wrist: Dictionary, right_wrist: Dictionary, _shoulder_width: float) -> void:
	var guard_config := _get_guard_config()
	var guard_debug := {
		"state": bool(_get_state("guard")),
		"enabled": bool(guard_config.get("enabled", true)),
		"max_wrist_separation_x": float(guard_config.get("max_wrist_separation_x", GUARD_DEFAULT_MAX_WRIST_SEPARATION_X)),
		"max_wrist_separation_y": float(guard_config.get("max_wrist_separation_y", GUARD_DEFAULT_MAX_WRIST_SEPARATION_Y)),
		"max_wrist_nose_distance": float(guard_config.get("max_wrist_nose_distance", GUARD_DEFAULT_MAX_WRIST_NOSE_DISTANCE)),
		"wrist_separation_x": 0.0,
		"wrist_separation_y": 0.0,
		"left_wrist_nose_distance": 0.0,
		"right_wrist_nose_distance": 0.0,
		"wrists_close_x": false,
		"wrists_close_y": false,
		"left_wrist_above_elbow": false,
		"right_wrist_above_elbow": false,
		"left_wrist_near_nose": false,
		"right_wrist_near_nose": false,
		"candidate": false,
	}
	if not bool(guard_config.get("enabled", true)):
		_gesture_state["guard_debug"] = guard_debug
		_set_state_toggle(events, "guard", false)
		return
	if nose.is_empty() or left_shoulder.is_empty() or right_shoulder.is_empty() or left_elbow.is_empty() or right_elbow.is_empty() or left_wrist.is_empty() or right_wrist.is_empty():
		_gesture_state["guard_debug"] = guard_debug
		_set_state_toggle(events, "guard", false)
		return
	var max_wrist_nose_distance := float(guard_config.get("max_wrist_nose_distance", GUARD_DEFAULT_MAX_WRIST_NOSE_DISTANCE))
	var wrist_separation_x := absf(float(left_wrist.get("x", 0.0)) - float(right_wrist.get("x", 0.0)))
	var wrist_separation_y := absf(float(left_wrist.get("y", 0.0)) - float(right_wrist.get("y", 0.0)))
	var left_wrist_nose_distance := PoseMetrics.distance_2d(left_wrist, nose)
	var right_wrist_nose_distance := PoseMetrics.distance_2d(right_wrist, nose)
	var wrists_close_x := wrist_separation_x <= float(guard_config.get("max_wrist_separation_x", GUARD_DEFAULT_MAX_WRIST_SEPARATION_X))
	var wrists_close_y := wrist_separation_y <= float(guard_config.get("max_wrist_separation_y", GUARD_DEFAULT_MAX_WRIST_SEPARATION_Y))
	var left_wrist_above_elbow := float(left_wrist.get("y", 0.0)) >= float(left_elbow.get("y", 0.0))
	var right_wrist_above_elbow := float(right_wrist.get("y", 0.0)) >= float(right_elbow.get("y", 0.0))
	var left_wrist_near_nose := left_wrist_nose_distance <= max_wrist_nose_distance
	var right_wrist_near_nose := right_wrist_nose_distance <= max_wrist_nose_distance
	var candidate := wrists_close_x and wrists_close_y and left_wrist_above_elbow and right_wrist_above_elbow and left_wrist_near_nose and right_wrist_near_nose
	guard_debug["wrist_separation_x"] = wrist_separation_x
	guard_debug["wrist_separation_y"] = wrist_separation_y
	guard_debug["left_wrist_nose_distance"] = left_wrist_nose_distance
	guard_debug["right_wrist_nose_distance"] = right_wrist_nose_distance
	guard_debug["wrists_close_x"] = wrists_close_x
	guard_debug["wrists_close_y"] = wrists_close_y
	guard_debug["left_wrist_above_elbow"] = left_wrist_above_elbow
	guard_debug["right_wrist_above_elbow"] = right_wrist_above_elbow
	guard_debug["left_wrist_near_nose"] = left_wrist_near_nose
	guard_debug["right_wrist_near_nose"] = right_wrist_near_nose
	guard_debug["candidate"] = candidate
	guard_debug["state"] = candidate
	_gesture_state["guard_debug"] = guard_debug
	_set_state_toggle(events, "guard", candidate)

func _process_squat(events: Array, height_ratio: float) -> void:
	var squat_config := _get_squat_config()
	if not bool(squat_config.get("enabled", true)):
		_set_state_toggle(events, "squat", false)
		return
	var active: bool = _get_state("squat")
	var enter_height_ratio_max := float(squat_config.get("enter_height_ratio_max", SQUAT_DEFAULT_ENTER_HEIGHT_RATIO_MAX))
	var exit_height_ratio_min := float(squat_config.get("exit_height_ratio_min", SQUAT_DEFAULT_EXIT_HEIGHT_RATIO_MIN))
	if not active and height_ratio <= enter_height_ratio_max:
		_set_state_toggle(events, "squat", true)
	elif active and height_ratio >= exit_height_ratio_min:
		_set_state_toggle(events, "squat", false)

func _process_weave(events: Array, head_offset: float, hip_offset: float, head_drop_ratio: float) -> void:
	var weave_config := _get_weave_config()
	var relative_offset := head_offset - hip_offset
	var left_head_ready := head_offset >= float(weave_config.get("enter_head_lateral_offset_min", WEAVE_DEFAULT_ENTER_HEAD_LATERAL_OFFSET_MIN))
	var right_head_ready := head_offset <= -float(weave_config.get("enter_head_lateral_offset_min", WEAVE_DEFAULT_ENTER_HEAD_LATERAL_OFFSET_MIN))
	var left_relative_ready := relative_offset >= float(weave_config.get("enter_relative_head_hip_offset_min", WEAVE_DEFAULT_ENTER_RELATIVE_HEAD_HIP_OFFSET_MIN))
	var right_relative_ready := relative_offset <= -float(weave_config.get("enter_relative_head_hip_offset_min", WEAVE_DEFAULT_ENTER_RELATIVE_HEAD_HIP_OFFSET_MIN))
	var head_drop_ready := head_drop_ratio >= float(weave_config.get("enter_head_drop_ratio_min", WEAVE_DEFAULT_ENTER_HEAD_DROP_RATIO_MIN))
	var weaving_left := left_head_ready and left_relative_ready and head_drop_ready
	var weaving_right := right_head_ready and right_relative_ready and head_drop_ready
	var neutral := absf(head_offset) <= float(weave_config.get("exit_head_lateral_offset_max", WEAVE_DEFAULT_EXIT_HEAD_LATERAL_OFFSET_MAX)) and absf(relative_offset) <= float(weave_config.get("exit_relative_head_hip_offset_max", WEAVE_DEFAULT_EXIT_RELATIVE_HEAD_HIP_OFFSET_MAX))
	var weave_state := "inactive"
	if weaving_left:
		weave_state = "left"
	elif weaving_right:
		weave_state = "right"
	_gesture_state["weave_debug"] = {
		"state": weave_state,
		"enabled": bool(weave_config.get("enabled", true)),
		"head_lateral_offset": head_offset,
		"hip_lateral_offset": hip_offset,
		"relative_head_hip_offset": relative_offset,
		"head_drop_ratio": head_drop_ratio,
		"enter_head_lateral_offset_min": float(weave_config.get("enter_head_lateral_offset_min", WEAVE_DEFAULT_ENTER_HEAD_LATERAL_OFFSET_MIN)),
		"enter_relative_head_hip_offset_min": float(weave_config.get("enter_relative_head_hip_offset_min", WEAVE_DEFAULT_ENTER_RELATIVE_HEAD_HIP_OFFSET_MIN)),
		"enter_head_drop_ratio_min": float(weave_config.get("enter_head_drop_ratio_min", WEAVE_DEFAULT_ENTER_HEAD_DROP_RATIO_MIN)),
		"exit_head_lateral_offset_max": float(weave_config.get("exit_head_lateral_offset_max", WEAVE_DEFAULT_EXIT_HEAD_LATERAL_OFFSET_MAX)),
		"exit_relative_head_hip_offset_max": float(weave_config.get("exit_relative_head_hip_offset_max", WEAVE_DEFAULT_EXIT_RELATIVE_HEAD_HIP_OFFSET_MAX)),
		"left_candidate": weaving_left,
		"right_candidate": weaving_right,
		"neutral_candidate": neutral,
		"head_offset_left_ready": left_head_ready,
		"head_offset_right_ready": right_head_ready,
		"relative_offset_left_ready": left_relative_ready,
		"relative_offset_right_ready": right_relative_ready,
		"head_drop_ready": head_drop_ready,
	}
	if not bool(weave_config.get("enabled", true)):
		_set_state_toggle(events, "weave_left", false)
		_set_state_toggle(events, "weave_right", false)
		return
	if weaving_left:
		_set_state_toggle(events, "weave_right", false)
		_set_state_toggle(events, "weave_left", true)
	elif weaving_right:
		_set_state_toggle(events, "weave_left", false)
		_set_state_toggle(events, "weave_right", true)
	else:
		_set_state_toggle(events, "weave_left", false)
		_set_state_toggle(events, "weave_right", false)

func _process_sidestep(events: Array, lateral_offset: float, head_offset: float, hip_offset: float) -> void:
	var body_aligned := absf(head_offset - hip_offset) <= 0.18
	if lateral_offset <= -0.45 and body_aligned:
		_set_state_toggle(events, "sidestep_right", false)
		_set_state_toggle(events, "sidestep_left", true)
	elif lateral_offset >= 0.45 and body_aligned:
		_set_state_toggle(events, "sidestep_left", false)
		_set_state_toggle(events, "sidestep_right", true)
	elif absf(lateral_offset) <= 0.14:
		_set_state_toggle(events, "sidestep_left", false)
		_set_state_toggle(events, "sidestep_right", false)

func _process_knee(events: Array, side: String, knee_rise: float, foot_rise: float, opposite_knee_rise: float, hip: Dictionary, ankle: Dictionary, torso_height: float) -> void:
	var event_name := "knee_%s" % side
	var lateral_offset := 0.0
	if not hip.is_empty() and not ankle.is_empty() and torso_height > 0.0:
		lateral_offset = absf(float(ankle.get("x", 0.0)) - float(hip.get("x", 0.0))) / torso_height
	var foot_fallback := foot_rise * 0.85 if lateral_offset <= 0.30 else 0.0
	var rise := maxf(knee_rise, foot_fallback)
	if rise <= 0.10:
		_set_ready(event_name, true)
	if not _is_ready(event_name):
		return
	if opposite_knee_rise >= 0.18 and absf(knee_rise - opposite_knee_rise) <= 0.08:
		return
	if rise < 0.22:
		return
	_emit_power_event(events, event_name, clampf((rise - 0.22) / 0.25 + 0.45, 0.0, 1.0))
	_set_ready(event_name, false)

func _process_leg_lift(events: Array, side: String, leg_angle_from_core_deg: float, hip: Dictionary, ankle: Dictionary, torso_height: float) -> void:
	var state_name := "leg_lift_%s" % side
	if hip.is_empty() or ankle.is_empty() or torso_height <= 0.0:
		_set_state_toggle(events, state_name, false)
		return
	var ankle_raise := maxf(0.0, (float(ankle.get("y", 0.0)) - float(hip.get("y", 0.0))) / torso_height + 1.0)
	var should_start := leg_angle_from_core_deg >= 32.0 and ankle_raise >= 0.32
	var should_end := leg_angle_from_core_deg <= 18.0 or ankle_raise <= 0.18
	if not _get_state(state_name) and should_start:
		_set_state_toggle(events, state_name, true)
	elif _get_state(state_name) and should_end:
		_set_state_toggle(events, state_name, false)

func _set_state_toggle(events: Array, state_name: String, active: bool) -> void:
	if _get_state(state_name) == active:
		return
	_gesture_state["states"][state_name] = active
	var suffix := "start" if active else "end"
	events.append({"name": StringName("%s_%s" % [state_name, suffix])})

func _build_public_gesture_states() -> Dictionary:
	return (_gesture_state.get("states", {}) as Dictionary).duplicate(true)

func _clear_same_family_block(state: Dictionary) -> void:
	state["same_family_blocked"] = false
	state["blocking_family"] = ""
	state["blocking_side"] = ""
	state["blocking_event_name"] = ""
	state["blocking_phase"] = ""

func _apply_same_family_block(state: Dictionary, blocking_state: Dictionary) -> void:
	state["same_family_blocked"] = true
	state["blocking_family"] = String(blocking_state.get("family", ""))
	state["blocking_side"] = String(blocking_state.get("blocking_side", ""))
	state["blocking_event_name"] = String(blocking_state.get("blocking_event_name", ""))
	state["blocking_phase"] = String(blocking_state.get("blocking_phase", ""))

func _family_side_to_event_name(family: String, side: String) -> String:
	if not PUNCH_FAMILY_EVENT_NAMES.has(family):
		return ""
	var family_events: Array = PUNCH_FAMILY_EVENT_NAMES.get(family, [])
	if family_events.size() < 2:
		return ""
	return String(family_events[0] if side == "left" else family_events[1])

func _get_same_family_threshold_blocking_state(family: String, side: String, timestamp_ms: int) -> Dictionary:
	var blocking_side := "right" if side == "left" else "left"
	var blocking_state := _get_straight_punch_state(blocking_side) if family == "straight_punch" else _get_pose_strike_state(family, blocking_side)
	var blocking_phase := String(blocking_state.get("phase", ""))
	if family == "straight_punch":
		if blocking_phase != STRAIGHT_PUNCH_STATE_TRIGGERED and blocking_phase != STRAIGHT_PUNCH_STATE_NOT_READY:
			return {}
	else:
		if blocking_phase != POSE_STRIKE_STATE_TRIGGERED:
			return {}
		var grace_deadline_timestamp_ms := int(blocking_state.get("grace_deadline_timestamp_ms", 0))
		if timestamp_ms >= grace_deadline_timestamp_ms:
			return {}
	return {
		"family": family,
		"blocking_side": blocking_side,
		"blocking_phase": String(blocking_state.get("phase", "")),
		"blocking_event_name": _family_side_to_event_name(family, blocking_side),
	}

func _reset_depth_analysis_state(state: Dictionary) -> void:
	state["depth_signal_available"] = false
	state["depth_signal_fresh"] = false
	state["depth_signal_source"] = ""
	state["last_depth_closeness"] = 0.0
	state["depth_closeness_delta"] = 0.0
	state["depth_peak_closeness"] = 0.0
	state["depth_early_closeness"] = 0.0
	state["depth_late_closeness"] = 0.0
	state["depth_window_span_ms"] = 0
	state["depth_gate_applied"] = false
	state["depth_gate_passed"] = false
	state["depth_gate_reason"] = "staged_or_unavailable"
	state["depth_gate_threshold_a"] = 0.0
	state["depth_gate_threshold_b"] = 0.0
	state["depth_runtime_status"] = "unloaded"
	state["depth_runtime_stage"] = "idle"
	state["depth_runtime_backend_id"] = "unknown"
	state["depth_runtime_family_id"] = "unknown"
	state["depth_runtime_failure_code"] = ""
	state["depth_runtime_failure_message"] = ""
	state["depth_sample_metrics"] = {}

func _apply_depth_analysis_to_state(state: Dictionary, depth_analysis: Dictionary) -> void:
	state["depth_signal_available"] = bool(depth_analysis.get("available", false))
	state["depth_signal_fresh"] = bool(depth_analysis.get("sample_fresh", false))
	state["depth_signal_source"] = String(depth_analysis.get("sample_source", ""))
	state["last_depth_closeness"] = float(depth_analysis.get("closeness", 0.0))
	state["depth_closeness_delta"] = float(depth_analysis.get("closeness_delta", 0.0))
	state["depth_peak_closeness"] = float(depth_analysis.get("peak_closeness", 0.0))
	state["depth_early_closeness"] = float(depth_analysis.get("early_closeness", 0.0))
	state["depth_late_closeness"] = float(depth_analysis.get("late_closeness", 0.0))
	state["depth_window_span_ms"] = int(depth_analysis.get("window_span_ms", 0))
	state["depth_gate_applied"] = bool(depth_analysis.get("gate_applied", false))
	state["depth_gate_passed"] = bool(depth_analysis.get("gate_passed", false))
	state["depth_gate_reason"] = String(depth_analysis.get("gate_reason", "staged_or_unavailable"))
	state["depth_gate_threshold_a"] = float(depth_analysis.get("threshold_a", 0.0))
	state["depth_gate_threshold_b"] = float(depth_analysis.get("threshold_b", 0.0))
	state["depth_runtime_status"] = String(depth_analysis.get("runtime_status", "unloaded"))
	state["depth_runtime_stage"] = String(depth_analysis.get("runtime_stage", "idle"))
	state["depth_runtime_backend_id"] = String(depth_analysis.get("backend_id", "unknown"))
	state["depth_runtime_family_id"] = String(depth_analysis.get("family_id", "unknown"))
	state["depth_runtime_failure_code"] = String(depth_analysis.get("failure_code", ""))
	state["depth_runtime_failure_message"] = String(depth_analysis.get("failure_message", ""))
	state["depth_sample_metrics"] = (depth_analysis.get("sample_metrics", {}) as Dictionary).duplicate(true)

func _update_family_depth_signal(family: String, side: String, state: Dictionary, timestamp_ms: int, fresh_sample: bool, tracking_frame: Dictionary, shoulder: Dictionary, elbow: Dictionary, wrist: Dictionary, config: Dictionary) -> Dictionary:
	var depth_config := _get_family_depth_config(family)
	var debug_state := _get_depth_runtime_debug_state(family)
	var analysis := {
		"available": false,
		"sample_fresh": false,
		"sample_source": "",
		"closeness": 0.0,
		"early_closeness": 0.0,
		"late_closeness": 0.0,
		"closeness_delta": 0.0,
		"peak_closeness": 0.0,
		"window_span_ms": 0,
		"gate_applied": false,
		"gate_passed": false,
		"gate_reason": "disabled_in_config" if not bool(depth_config.get("enabled", false)) else "staged_or_unavailable",
		"threshold_a": 0.0,
		"threshold_b": 0.0,
		"runtime_status": String(debug_state.get("runtime_status", "unloaded")),
		"runtime_stage": String(debug_state.get("runtime_stage", "idle")),
		"backend_id": String(debug_state.get("backend_id", "unknown")),
		"family_id": String(debug_state.get("family_id", "unknown")),
		"failure_code": String(debug_state.get("failure_code", "")),
		"failure_message": String(debug_state.get("failure_message", "")),
		"sample_metrics": (debug_state.get("last_sample_metrics", {}) as Dictionary).duplicate(true),
	}
	if not bool(depth_config.get("enabled", false)):
		return analysis
	var manager = _get_depth_runtime_manager(family)
	var sample_request := {
		"family": family,
		"side": side,
		"timestamp_ms": timestamp_ms,
		"window_ms": int(config.get("window_ms", POSE_STRIKE_DEFAULT_WINDOW_MS)),
		"evaluation": (depth_config.get("evaluation", {}) as Dictionary).duplicate(true) if depth_config.get("evaluation", {}) is Dictionary else {},
		"shoulder": shoulder.duplicate(true),
		"elbow": elbow.duplicate(true),
		"wrist": wrist.duplicate(true),
	}
	var result: Dictionary = manager.infer_relative_depth(tracking_frame, sample_request)
	var runtime_debug: Dictionary = manager.get_debug_state()
	var sample_metrics: Dictionary = result.get("sample_metrics", {}) if result.get("sample_metrics", {}) is Dictionary else {}
	var debug_sample_metrics: Dictionary = runtime_debug.get("last_sample_metrics", {}) if runtime_debug.get("last_sample_metrics", {}) is Dictionary else {}
	analysis["runtime_status"] = String(runtime_debug.get("runtime_status", result.get("status", analysis.get("runtime_status", "unloaded"))))
	analysis["runtime_stage"] = String(runtime_debug.get("runtime_stage", analysis.get("runtime_stage", "idle")))
	analysis["backend_id"] = String(runtime_debug.get("backend_id", result.get("backend_id", analysis.get("backend_id", "unknown"))))
	analysis["family_id"] = String(runtime_debug.get("family_id", result.get("family_id", analysis.get("family_id", "unknown"))))
	analysis["sample_metrics"] = debug_sample_metrics.duplicate(true) if not debug_sample_metrics.is_empty() or sample_metrics.is_empty() else sample_metrics.duplicate(true)
	if not bool(result.get("ok", false)):
		var error_info: Dictionary = result.get("error_info", {}) if result.get("error_info", {}) is Dictionary else {}
		analysis["failure_code"] = String(runtime_debug.get("failure_code", error_info.get("code", analysis.get("failure_code", ""))))
		analysis["failure_message"] = String(runtime_debug.get("failure_message", error_info.get("message", analysis.get("failure_message", ""))))
		return analysis
	var closeness := float(sample_metrics.get("wrist_closeness", sample_metrics.get("closeness", 0.0)))
	analysis["available"] = true
	analysis["sample_fresh"] = bool(sample_metrics.get("sample_fresh", fresh_sample))
	analysis["sample_source"] = String(sample_metrics.get("sample_source", "depth_runtime"))
	analysis["closeness"] = closeness
	var history: Array = (state.get("depth_closeness_history", []) as Array).duplicate(true)
	if fresh_sample and bool(analysis.get("sample_fresh", false)):
		history.append({"timestamp_ms": timestamp_ms, "closeness": closeness})
	var evaluation: Dictionary = depth_config.get("evaluation", {}) if depth_config.get("evaluation", {}) is Dictionary else {}
	var window_ms := max(1, int(config.get("window_ms", evaluation.get("window_ms", POSE_STRIKE_DEFAULT_WINDOW_MS))))
	while history.size() > 0 and timestamp_ms - int((history[0] as Dictionary).get("timestamp_ms", timestamp_ms)) > window_ms:
		history.remove_at(0)
	state["depth_closeness_history"] = history
	if history.is_empty():
		return analysis
	analysis["window_span_ms"] = maxi(timestamp_ms - int((history[0] as Dictionary).get("timestamp_ms", timestamp_ms)), 0)
	var closeness_values: Array = []
	for entry_variant: Variant in history:
		if not entry_variant is Dictionary:
			continue
		closeness_values.append(float((entry_variant as Dictionary).get("closeness", 0.0)))
	if closeness_values.is_empty():
		return analysis
	var smoothing_window := max(1, int(evaluation.get("smoothing_window_samples", 1)))
	var smoothed_values := _moving_average_float_window(closeness_values, smoothing_window)
	var early_fraction := clampf(float(evaluation.get("early_window_fraction", 0.35)), 0.0, 1.0)
	var late_fraction := clampf(float(evaluation.get("late_window_fraction", 0.35)), 0.0, 1.0)
	var early_count := clampi(int(ceil(float(smoothed_values.size()) * early_fraction)), 1, smoothed_values.size())
	var late_count := clampi(int(ceil(float(smoothed_values.size()) * late_fraction)), 1, smoothed_values.size())
	analysis["early_closeness"] = _mean_float_slice(smoothed_values, 0, early_count)
	analysis["late_closeness"] = _mean_float_slice(smoothed_values, smoothed_values.size() - late_count, late_count)
	analysis["closeness_delta"] = float(analysis.get("late_closeness", 0.0)) - float(analysis.get("early_closeness", 0.0))
	analysis["peak_closeness"] = _window_peak_float(smoothed_values)
	var thresholds: Dictionary = depth_config.get("thresholds", {}) if depth_config.get("thresholds", {}) is Dictionary else {}
	if family == "straight_punch":
		analysis["threshold_a"] = float(thresholds.get("min_closeness_delta", 0.0))
		analysis["threshold_b"] = float(thresholds.get("min_peak_closeness", 0.0))
		analysis["gate_applied"] = true
		analysis["gate_passed"] = float(analysis.get("closeness_delta", 0.0)) + 0.000001 >= float(analysis.get("threshold_a", 0.0)) and float(analysis.get("peak_closeness", 0.0)) + 0.000001 >= float(analysis.get("threshold_b", 0.0))
		analysis["gate_reason"] = "min_closeness_delta_and_min_peak_closeness"
	else:
		analysis["threshold_a"] = float(thresholds.get("max_closeness_delta", 0.0))
		analysis["threshold_b"] = float(thresholds.get("max_peak_closeness", 0.0))
		analysis["gate_applied"] = true
		analysis["gate_passed"] = float(analysis.get("closeness_delta", 0.0)) <= float(analysis.get("threshold_a", 0.0)) + 0.000001 and float(analysis.get("peak_closeness", 0.0)) <= float(analysis.get("threshold_b", 0.0)) + 0.000001
		analysis["gate_reason"] = "max_closeness_delta_and_max_peak_closeness"
	return analysis

func _moving_average_float_window(values: Array, window_size: int) -> Array:
	var smoothed: Array = []
	for index in range(values.size()):
		var start := maxi(index - window_size + 1, 0)
		var total := 0.0
		var count := 0
		for sample_index in range(start, index + 1):
			total += float(values[sample_index])
			count += 1
		smoothed.append(total / float(maxi(count, 1)))
	return smoothed

func _mean_float_slice(values: Array, start_index: int, count: int) -> float:
	if values.is_empty() or count <= 0:
		return 0.0
	var safe_start := clampi(start_index, 0, values.size() - 1)
	var safe_end := clampi(safe_start + count, safe_start + 1, values.size())
	var total := 0.0
	for index in range(safe_start, safe_end):
		total += float(values[index])
	return total / float(maxi(safe_end - safe_start, 1))

func _build_straight_punch_state(phase: String = STRAIGHT_PUNCH_STATE_TRACKING_LOST) -> Dictionary:
	return {
		"phase": phase,
		"bbox_area_history": [],
		"positive_growth_samples": 0,
		"trigger_bbox_area": 0.0,
		"grace_ms_remaining": 0,
		"grace_deadline_timestamp_ms": 0,
		"last_bbox_area": 0.0,
		"wrist_velocity_history": [],
		"wrist_position_history": [],
		"depth_closeness_history": [],
		"recent_peak_wrist_velocity": 0.0,
		"bbox_area_window_history": [],
		"bbox_area_growth_history": [],
		"recent_peak_bbox_area_growth": 0.0,
		"forward_depth_spike_history": [],
		"recent_peak_forward_depth_spike": 0.0,
		"last_forward_depth_spike": 0.0,
		"last_forward_depth_spike_window_span_ms": 0,
		"last_bbox_area_growth": 0.0,
		"last_positive_bbox_growth_samples": 0,
		"last_bbox_area_growth_window_span_ms": 0,
		"last_wrist_velocity": 0.0,
		"last_wrist_velocity_vector": Vector3.ZERO,
		"last_lateral_velocity": 0.0,
		"last_vertical_velocity": 0.0,
		"last_wrist_velocity_window_span_ms": 0,
		"last_wrist_forward_velocity": 0.0,
		"last_sample_fresh": false,
		"elbow_shoulder_xy_distance": 0.0,
		"max_elbow_shoulder_xy_distance": STRAIGHT_PUNCH_DEFAULT_MAX_ELBOW_SHOULDER_XY_DISTANCE,
		"elbow_shoulder_xy_gate_passed": false,
		"wrist_lateral_angle_from_elbow_vertical_deg": 0.0,
		"min_wrist_lateral_angle_from_elbow_vertical_deg": STRAIGHT_PUNCH_DEFAULT_MIN_WRIST_LATERAL_ANGLE_FROM_ELBOW_VERTICAL_DEG,
		"wrist_lateral_angle_gate_passed": false,
		"last_observation_frame_index": -1,
		"last_observation_timestamp_seconds": -1.0,
		"hand_tracking_state": "idle",
		"velocity_signal_source": "wrist_only",
		"hand_tracking_valid": false,
		"pose_tracking_valid": false,
		"stale_frames": 0,
		"reacquire_started_timestamp_ms": -1,
		"not_ready_started_timestamp_ms": -1,
		"same_family_blocked": false,
		"blocking_family": "",
		"blocking_side": "",
		"blocking_event_name": "",
		"blocking_phase": "",
		"depth_signal_available": false,
		"depth_signal_fresh": false,
		"depth_signal_source": "",
		"last_depth_closeness": 0.0,
		"depth_closeness_delta": 0.0,
		"depth_peak_closeness": 0.0,
		"depth_early_closeness": 0.0,
		"depth_late_closeness": 0.0,
		"depth_window_span_ms": 0,
		"depth_gate_applied": false,
		"depth_gate_passed": false,
		"depth_gate_reason": "staged_or_unavailable",
		"depth_gate_threshold_a": 0.0,
		"depth_gate_threshold_b": 0.0,
		"depth_runtime_status": "unloaded",
		"depth_runtime_stage": "idle",
		"depth_runtime_backend_id": "unknown",
		"depth_runtime_family_id": "unknown",
		"depth_runtime_failure_code": "",
		"depth_runtime_failure_message": "",
		"depth_sample_metrics": {},
	}

func _get_straight_punch_state(side: String) -> Dictionary:
	var straight_punch: Dictionary = _gesture_state.get("straight_punch", {})
	return (straight_punch.get(side, _build_straight_punch_state()) as Dictionary).duplicate(true)

func _set_straight_punch_state(side: String, state: Dictionary) -> void:
	var straight_punch: Dictionary = _gesture_state.get("straight_punch", {})
	straight_punch[side] = state.duplicate(true)
	_gesture_state["straight_punch"] = straight_punch
	_set_ready("punch_%s" % side, String(state.get("phase", STRAIGHT_PUNCH_STATE_TRACKING_LOST)) == STRAIGHT_PUNCH_STATE_READY)


func _configure_depth_runtime_managers() -> void:
	var families := ["straight_punch", "hook", "uppercut"]
	for family in families:
		var manager: Variant = _depth_runtime_managers.get(family, null)
		if manager == null:
			manager = DepthRuntimeManagerScript.new()
			_depth_runtime_managers[family] = manager
		if manager.has_method("set_shared_runtime_pool"):
			manager.set_shared_runtime_pool(_depth_shared_runtime_pool)
		var family_depth_config := _get_family_depth_config(family)
		manager.configure_from_family(family, family_depth_config)
		manager.ensure_runtime_ready()

func _get_family_depth_config(family: String) -> Dictionary:
	var family_document := _get_family_backend_document(family, BACKEND_THRESHOLD)
	return family_document.get("depth", {}) if family_document.get("depth", {}) is Dictionary else {}

func _get_depth_runtime_manager(family: String):
	var manager: Variant = _depth_runtime_managers.get(family, null)
	if manager == null:
		manager = DepthRuntimeManagerScript.new()
		_depth_runtime_managers[family] = manager
		if manager.has_method("set_shared_runtime_pool"):
			manager.set_shared_runtime_pool(_depth_shared_runtime_pool)
		manager.configure_from_family(family, _get_family_depth_config(family))
	return manager

func _get_depth_runtime_debug_state(family: String) -> Dictionary:
	var manager = _get_depth_runtime_manager(family)
	return manager.ensure_runtime_ready()

func _build_depth_runtime_debug_state() -> Dictionary:
	var families := {}
	for family in ["straight_punch", "hook", "uppercut"]:
		families[family] = _get_depth_runtime_debug_state(family)
	return families

func _get_selected_punch_detection_backend() -> String:
	return "per_family"

func _get_selected_punch_detection_backend_raw() -> String:
	return "per_family"

func _get_gesture_profile_document() -> Dictionary:
	if _config == null:
		return {}
	var gesture_profile_document: Variant = _config.get("gesture_profile_document") if _config.has_method("get") else null
	return gesture_profile_document if gesture_profile_document is Dictionary else {}

func _get_family_document(family: String) -> Dictionary:
	var gesture_profile_document := _get_gesture_profile_document()
	return gesture_profile_document.get(family, {}) if gesture_profile_document.get(family, {}) is Dictionary else {}

func _get_family_backend_document(family: String, backend_name: String) -> Dictionary:
	var family_document := _get_family_document(family)
	var backend_document: Dictionary = family_document.get(backend_name, {}) if family_document.get(backend_name, {}) is Dictionary else {}
	if not backend_document.is_empty():
		return backend_document
	return family_document

func _get_punch_backend_for_family(family: String) -> String:
	var family_document := _get_family_document(family)
	var backend := String(family_document.get("backend", "")).strip_edges()
	if backend == "":
		return BACKEND_THRESHOLD
	return _normalize_punch_backend_name(backend)

func _get_non_punch_backend_for_family(family: String) -> String:
	var family_document := _get_family_document(family)
	var backend := String(family_document.get("backend", "")).strip_edges()
	if backend == "":
		return BACKEND_THRESHOLD
	return _normalize_punch_backend_name(backend)

func _threshold_gates_enabled() -> bool:
	return _any_punch_family_uses_backend(BACKEND_THRESHOLD)

func _prototype_matcher_backend_enabled() -> bool:
	return _any_punch_family_uses_backend(BACKEND_PROTOTYPE)

func _learned_classifier_backend_enabled() -> bool:
	return _any_punch_family_uses_backend(BACKEND_CLASSIFIER)

func _any_punch_family_uses_backend(backend_name: String) -> bool:
	for family in PUNCH_FAMILIES:
		if _get_punch_backend_for_family(String(family)) == backend_name:
			return true
	return false

func _selected_punch_detection_backend_enabled() -> bool:
	return _threshold_gates_enabled() or _prototype_matcher_backend_enabled() or _learned_classifier_backend_enabled()

func _get_active_punch_detection_backend() -> String:
	return "per_family" if _selected_punch_detection_backend_enabled() else "none"

func _get_punch_backend_resolution_reason() -> String:
	return "per_family_active" if _selected_punch_detection_backend_enabled() else "no_active_family_backend"

func _normalize_punch_backend_name(backend_name: String) -> String:
	match backend_name.strip_edges().to_lower():
		BACKEND_DISABLED:
			return BACKEND_DISABLED
		BACKEND_THRESHOLD:
			return BACKEND_THRESHOLD
		BACKEND_PROTOTYPE:
			return BACKEND_PROTOTYPE
		BACKEND_CLASSIFIER:
			return BACKEND_CLASSIFIER
		_:
			return BACKEND_THRESHOLD

func _filter_events_by_names(events: Array, allowed_names: Array[String]) -> Array:
	var filtered: Array = []
	for event_variant in events:
		if not event_variant is Dictionary:
			continue
		var event: Dictionary = event_variant
		if allowed_names.has(String(event.get("name", ""))):
			filtered.append(event.duplicate(true))
	return filtered

func _filter_events_for_backend(events: Array, backend_name: String) -> Array:
	var allowed_names: Array[String] = []
	for family in PUNCH_FAMILIES:
		if _get_punch_backend_for_family(String(family)) == backend_name:
			allowed_names.append_array(PUNCH_FAMILY_EVENT_NAMES.get(String(family), []))
	return _filter_events_by_names(events, allowed_names)

func _get_guard_config() -> Dictionary:
	var config := {
		"enabled": true,
		"max_wrist_separation_x": GUARD_DEFAULT_MAX_WRIST_SEPARATION_X,
		"max_wrist_separation_y": GUARD_DEFAULT_MAX_WRIST_SEPARATION_Y,
		"max_wrist_nose_distance": GUARD_DEFAULT_MAX_WRIST_NOSE_DISTANCE,
	}
	if _config == null:
		return config
	var guard: Dictionary = _get_family_backend_document("guard", BACKEND_THRESHOLD)
	var thresholds: Dictionary = guard.get("thresholds", {}) if guard.get("thresholds", {}) is Dictionary else {}
	config["enabled"] = _get_non_punch_backend_for_family("guard") == BACKEND_THRESHOLD and bool(guard.get("enabled", config.get("enabled", true)))
	config["max_wrist_separation_x"] = maxf(0.0, float(thresholds.get("max_wrist_separation_x", config.get("max_wrist_separation_x", GUARD_DEFAULT_MAX_WRIST_SEPARATION_X))))
	config["max_wrist_separation_y"] = maxf(0.0, float(thresholds.get("max_wrist_separation_y", config.get("max_wrist_separation_y", GUARD_DEFAULT_MAX_WRIST_SEPARATION_Y))))
	config["max_wrist_nose_distance"] = maxf(0.0, float(thresholds.get("max_wrist_nose_distance", config.get("max_wrist_nose_distance", GUARD_DEFAULT_MAX_WRIST_NOSE_DISTANCE))))
	return config

func _get_squat_config() -> Dictionary:
	var config := {
		"enabled": true,
		"enter_height_ratio_max": SQUAT_DEFAULT_ENTER_HEIGHT_RATIO_MAX,
		"exit_height_ratio_min": SQUAT_DEFAULT_EXIT_HEIGHT_RATIO_MIN,
	}
	if _config == null:
		return config
	var squat: Dictionary = _get_family_backend_document("squat", BACKEND_THRESHOLD)
	var thresholds: Dictionary = squat.get("thresholds", {}) if squat.get("thresholds", {}) is Dictionary else {}
	config["enabled"] = _get_non_punch_backend_for_family("squat") == BACKEND_THRESHOLD and bool(squat.get("enabled", config.get("enabled", true)))
	config["enter_height_ratio_max"] = clampf(float(thresholds.get("enter_height_ratio_max", config.get("enter_height_ratio_max", SQUAT_DEFAULT_ENTER_HEIGHT_RATIO_MAX))), 0.0, 1.0)
	config["exit_height_ratio_min"] = clampf(float(thresholds.get("exit_height_ratio_min", config.get("exit_height_ratio_min", SQUAT_DEFAULT_EXIT_HEIGHT_RATIO_MIN))), 0.0, 1.0)
	if float(config["exit_height_ratio_min"]) < float(config["enter_height_ratio_max"]):
		config["exit_height_ratio_min"] = float(config["enter_height_ratio_max"])
	return config

func _get_weave_config() -> Dictionary:
	var config := {
		"enabled": true,
		"enter_head_lateral_offset_min": WEAVE_DEFAULT_ENTER_HEAD_LATERAL_OFFSET_MIN,
		"enter_relative_head_hip_offset_min": WEAVE_DEFAULT_ENTER_RELATIVE_HEAD_HIP_OFFSET_MIN,
		"enter_head_drop_ratio_min": WEAVE_DEFAULT_ENTER_HEAD_DROP_RATIO_MIN,
		"exit_head_lateral_offset_max": WEAVE_DEFAULT_EXIT_HEAD_LATERAL_OFFSET_MAX,
		"exit_relative_head_hip_offset_max": WEAVE_DEFAULT_EXIT_RELATIVE_HEAD_HIP_OFFSET_MAX,
	}
	if _config == null:
		return config
	var weave: Dictionary = _get_family_backend_document("weave", BACKEND_THRESHOLD)
	var thresholds: Dictionary = weave.get("thresholds", {}) if weave.get("thresholds", {}) is Dictionary else {}
	config["enabled"] = _get_non_punch_backend_for_family("weave") == BACKEND_THRESHOLD and bool(weave.get("enabled", config.get("enabled", true)))
	config["enter_head_lateral_offset_min"] = maxf(0.0, float(thresholds.get("enter_head_lateral_offset_min", config.get("enter_head_lateral_offset_min", WEAVE_DEFAULT_ENTER_HEAD_LATERAL_OFFSET_MIN))))
	config["enter_relative_head_hip_offset_min"] = maxf(0.0, float(thresholds.get("enter_relative_head_hip_offset_min", config.get("enter_relative_head_hip_offset_min", WEAVE_DEFAULT_ENTER_RELATIVE_HEAD_HIP_OFFSET_MIN))))
	config["enter_head_drop_ratio_min"] = maxf(0.0, float(thresholds.get("enter_head_drop_ratio_min", config.get("enter_head_drop_ratio_min", WEAVE_DEFAULT_ENTER_HEAD_DROP_RATIO_MIN))))
	config["exit_head_lateral_offset_max"] = maxf(0.0, float(thresholds.get("exit_head_lateral_offset_max", config.get("exit_head_lateral_offset_max", WEAVE_DEFAULT_EXIT_HEAD_LATERAL_OFFSET_MAX))))
	config["exit_relative_head_hip_offset_max"] = maxf(0.0, float(thresholds.get("exit_relative_head_hip_offset_max", config.get("exit_relative_head_hip_offset_max", WEAVE_DEFAULT_EXIT_RELATIVE_HEAD_HIP_OFFSET_MAX))))
	return config

func _get_straight_punch_config() -> Dictionary:
	var config := {
		"enabled": true,
		"fresh_samples_only": STRAIGHT_PUNCH_DEFAULT_FRESH_SAMPLES_ONLY,
		"sample_window_size": STRAIGHT_PUNCH_DEFAULT_SAMPLE_WINDOW_SIZE,
		"min_positive_growth_samples": STRAIGHT_PUNCH_DEFAULT_MIN_POSITIVE_GROWTH_SAMPLES,
		"window_ms": STRAIGHT_PUNCH_DEFAULT_WRIST_VELOCITY_WINDOW_MS,
		"min_velocity": STRAIGHT_PUNCH_DEFAULT_MIN_WRIST_VELOCITY,
		"min_bbox_area_growth": STRAIGHT_PUNCH_DEFAULT_MIN_BBOX_AREA_GROWTH,
		"max_elbow_shoulder_xy_distance": STRAIGHT_PUNCH_DEFAULT_MAX_ELBOW_SHOULDER_XY_DISTANCE,
		"min_wrist_lateral_angle_from_elbow_vertical_deg": STRAIGHT_PUNCH_DEFAULT_MIN_WRIST_LATERAL_ANGLE_FROM_ELBOW_VERTICAL_DEG,
		"triggered_grace_ms": STRAIGHT_PUNCH_DEFAULT_TRIGGERED_GRACE_MS,
		"bbox_area_retract_epsilon": STRAIGHT_PUNCH_DEFAULT_BBOX_AREA_RETRACT_EPSILON,
		"pose_only_rearm_ms": STRAIGHT_PUNCH_DEFAULT_POSE_ONLY_REARM_MS,
		"lost_tracking_reacquire_stable_ms": STRAIGHT_PUNCH_DEFAULT_REACQUIRE_STABLE_MS,
	}
	if _config == null:
		return config
	var straight_punch: Dictionary = _get_family_backend_document("straight_punch", BACKEND_THRESHOLD)
	var evaluation: Dictionary = straight_punch.get("evaluation", {}) if straight_punch.get("evaluation", {}) is Dictionary else {}
	var thresholds: Dictionary = straight_punch.get("thresholds", {}) if straight_punch.get("thresholds", {}) is Dictionary else {}
	var timing: Dictionary = straight_punch.get("timing", {}) if straight_punch.get("timing", {}) is Dictionary else {}
	var rearm: Dictionary = straight_punch.get("rearm", {}) if straight_punch.get("rearm", {}) is Dictionary else {}
	var state_machine: Dictionary = straight_punch.get("state_machine", {}) if straight_punch.get("state_machine", {}) is Dictionary else {}
	config["enabled"] = _get_punch_backend_for_family("straight_punch") == BACKEND_THRESHOLD
	config["fresh_samples_only"] = bool(evaluation.get("fresh_samples_only", config.get("fresh_samples_only", STRAIGHT_PUNCH_DEFAULT_FRESH_SAMPLES_ONLY)))
	config["sample_window_size"] = max(2, int(evaluation.get("sample_window_size", config.get("sample_window_size", STRAIGHT_PUNCH_DEFAULT_SAMPLE_WINDOW_SIZE))))
	config["min_positive_growth_samples"] = max(1, int(evaluation.get("min_positive_growth_samples", config.get("min_positive_growth_samples", STRAIGHT_PUNCH_DEFAULT_MIN_POSITIVE_GROWTH_SAMPLES))))
	config["window_ms"] = max(1, int(evaluation.get("window_ms", config.get("window_ms", STRAIGHT_PUNCH_DEFAULT_WRIST_VELOCITY_WINDOW_MS))))
	config["min_velocity"] = maxf(0.0, float(thresholds.get("min_velocity", config.get("min_velocity", STRAIGHT_PUNCH_DEFAULT_MIN_WRIST_VELOCITY))))
	config["min_bbox_area_growth"] = maxf(0.0, float(thresholds.get("min_bbox_area_growth", config.get("min_bbox_area_growth", STRAIGHT_PUNCH_DEFAULT_MIN_BBOX_AREA_GROWTH))))
	config["max_elbow_shoulder_xy_distance"] = maxf(0.0, float(thresholds.get("max_elbow_shoulder_xy_distance", config.get("max_elbow_shoulder_xy_distance", STRAIGHT_PUNCH_DEFAULT_MAX_ELBOW_SHOULDER_XY_DISTANCE))))
	config["min_wrist_lateral_angle_from_elbow_vertical_deg"] = maxf(0.0, float(thresholds.get("min_wrist_lateral_angle_from_elbow_vertical_deg", config.get("min_wrist_lateral_angle_from_elbow_vertical_deg", STRAIGHT_PUNCH_DEFAULT_MIN_WRIST_LATERAL_ANGLE_FROM_ELBOW_VERTICAL_DEG))))
	config["triggered_grace_ms"] = max(0, int(timing.get("triggered_grace_ms", config.get("triggered_grace_ms", STRAIGHT_PUNCH_DEFAULT_TRIGGERED_GRACE_MS))))
	config["bbox_area_retract_epsilon"] = maxf(0.0, float(rearm.get("bbox_area_retract_epsilon", config.get("bbox_area_retract_epsilon", STRAIGHT_PUNCH_DEFAULT_BBOX_AREA_RETRACT_EPSILON))))
	config["pose_only_rearm_ms"] = max(0, int(rearm.get("pose_only_rearm_ms", config.get("pose_only_rearm_ms", STRAIGHT_PUNCH_DEFAULT_POSE_ONLY_REARM_MS))))
	config["lost_tracking_reacquire_stable_ms"] = max(0, int(state_machine.get("lost_tracking_reacquire_stable_ms", config.get("lost_tracking_reacquire_stable_ms", STRAIGHT_PUNCH_DEFAULT_REACQUIRE_STABLE_MS))))
	return config

func _build_pose_strike_state(phase: String = POSE_STRIKE_STATE_TRACKING_LOST) -> Dictionary:
	return {
		"phase": phase,
		"wrist_velocity_history": [],
		"wrist_position_history": [],
		"recent_peak_wrist_velocity": 0.0,
		"grace_ms_remaining": 0,
		"grace_deadline_timestamp_ms": 0,
		"last_wrist_velocity": 0.0,
		"last_wrist_velocity_vector": Vector3.ZERO,
		"last_lateral_velocity": 0.0,
		"last_vertical_velocity": 0.0,
		"last_wrist_velocity_window_span_ms": 0,
		"last_sample_fresh": false,
		"velocity_signal_source": "wrist_only",
		"pose_tracking_valid": false,
		"tracking_state": "pose_missing",
		"reacquire_started_timestamp_ms": -1,
		"not_ready_started_timestamp_ms": -1,
		"elbow_bend_deg": 0.0,
		"outward_velocity": 0.0,
		"upward_velocity": 0.0,
		"horizontal_direction_velocity": 0.0,
		"directionality_ratio": 0.0,
		"outward_distance": 0.0,
		"wrist_elbow_vertical_offset": 0.0,
		"wrist_elbow_horizontal_offset": 0.0,
		"wrist_above_elbow_offset": 0.0,
		"wrist_angle_from_elbow_horizontal_deg": 0.0,
		"wrist_angle_from_elbow_vertical_deg": 0.0,
		"wrist_horizontal_angle_gate_passed": false,
		"wrist_vertical_angle_gate_passed": false,
		"wrist_on_required_hook_side": false,
		"wrist_above_elbow_gate_passed": false,
		"dominance_ratio": 0.0,
		"depth_signal_available": false,
		"depth_signal_fresh": false,
		"depth_signal_source": "",
		"last_depth_closeness": 0.0,
		"depth_closeness_delta": 0.0,
		"depth_peak_closeness": 0.0,
		"depth_early_closeness": 0.0,
		"depth_late_closeness": 0.0,
		"depth_window_span_ms": 0,
		"depth_gate_applied": false,
		"depth_gate_passed": false,
		"depth_gate_reason": "staged_or_unavailable",
		"depth_gate_threshold_a": 0.0,
		"depth_gate_threshold_b": 0.0,
		"depth_runtime_status": "unloaded",
		"depth_runtime_stage": "idle",
		"depth_runtime_backend_id": "unknown",
		"depth_runtime_family_id": "unknown",
		"depth_runtime_failure_code": "",
		"depth_runtime_failure_message": "",
		"depth_sample_metrics": {},
	}

func _get_pose_strike_state(family: String, side: String) -> Dictionary:
	var families: Dictionary = _gesture_state.get(family, {})
	return (families.get(side, _build_pose_strike_state()) as Dictionary).duplicate(true)

func _set_pose_strike_state(family: String, side: String, state: Dictionary) -> void:
	var families: Dictionary = _gesture_state.get(family, {})
	families[side] = state.duplicate(true)
	_gesture_state[family] = families
	_set_ready("%s_%s" % [family, side], String(state.get("phase", POSE_STRIKE_STATE_TRACKING_LOST)) == POSE_STRIKE_STATE_READY)

func _get_pose_strike_config(family: String) -> Dictionary:
	return _get_hook_config() if family == "hook" else _get_uppercut_config()

func _get_hook_config() -> Dictionary:
	var config := {
		"enabled": true,
		"window_ms": POSE_STRIKE_DEFAULT_WINDOW_MS,
		"min_velocity": POSE_STRIKE_DEFAULT_MIN_PUNCH_VELOCITY,
		"max_wrist_angle_from_elbow_horizontal_deg": HOOK_DEFAULT_MAX_WRIST_ANGLE_FROM_ELBOW_HORIZONTAL_DEG,
		"triggered_grace_ms": POSE_STRIKE_DEFAULT_TRIGGERED_GRACE_MS,
		"pose_only_rearm_ms": POSE_STRIKE_DEFAULT_POSE_ONLY_REARM_MS,
		"lost_tracking_reacquire_stable_ms": POSE_STRIKE_DEFAULT_REACQUIRE_STABLE_MS,
	}
	if _config == null:
		return config
	var hook: Dictionary = _get_family_backend_document("hook", BACKEND_THRESHOLD)
	var evaluation: Dictionary = hook.get("evaluation", {}) if hook.get("evaluation", {}) is Dictionary else {}
	var thresholds: Dictionary = hook.get("thresholds", {}) if hook.get("thresholds", {}) is Dictionary else {}
	var timing: Dictionary = hook.get("timing", {}) if hook.get("timing", {}) is Dictionary else {}
	var rearm: Dictionary = hook.get("rearm", {}) if hook.get("rearm", {}) is Dictionary else {}
	var state_machine: Dictionary = hook.get("state_machine", {}) if hook.get("state_machine", {}) is Dictionary else {}
	config["enabled"] = _get_punch_backend_for_family("hook") == BACKEND_THRESHOLD
	config["window_ms"] = max(1, int(evaluation.get("window_ms", config.get("window_ms", POSE_STRIKE_DEFAULT_WINDOW_MS))))
	config["min_velocity"] = maxf(0.0, float(thresholds.get("min_velocity", thresholds.get("min_punch_velocity", config.get("min_velocity", POSE_STRIKE_DEFAULT_MIN_PUNCH_VELOCITY)))))
	config["max_wrist_angle_from_elbow_horizontal_deg"] = clampf(float(thresholds.get("max_wrist_angle_from_elbow_horizontal_deg", config.get("max_wrist_angle_from_elbow_horizontal_deg", HOOK_DEFAULT_MAX_WRIST_ANGLE_FROM_ELBOW_HORIZONTAL_DEG))), 0.0, 90.0)
	config["triggered_grace_ms"] = max(0, int(timing.get("triggered_grace_ms", config.get("triggered_grace_ms", POSE_STRIKE_DEFAULT_TRIGGERED_GRACE_MS))))
	config["pose_only_rearm_ms"] = max(0, int(rearm.get("pose_only_rearm_ms", config.get("pose_only_rearm_ms", POSE_STRIKE_DEFAULT_POSE_ONLY_REARM_MS))))
	config["lost_tracking_reacquire_stable_ms"] = max(0, int(state_machine.get("lost_tracking_reacquire_stable_ms", config.get("lost_tracking_reacquire_stable_ms", POSE_STRIKE_DEFAULT_REACQUIRE_STABLE_MS))))
	return config

func _get_uppercut_config() -> Dictionary:
	var config := {
		"enabled": true,
		"window_ms": POSE_STRIKE_DEFAULT_WINDOW_MS,
		"min_velocity": POSE_STRIKE_DEFAULT_MIN_PUNCH_VELOCITY,
		"max_wrist_angle_from_elbow_vertical_deg": UPPERCUT_DEFAULT_MAX_WRIST_ANGLE_FROM_ELBOW_VERTICAL_DEG,
		"triggered_grace_ms": POSE_STRIKE_DEFAULT_TRIGGERED_GRACE_MS,
		"pose_only_rearm_ms": POSE_STRIKE_DEFAULT_POSE_ONLY_REARM_MS,
		"lost_tracking_reacquire_stable_ms": POSE_STRIKE_DEFAULT_REACQUIRE_STABLE_MS,
	}
	if _config == null:
		return config
	var uppercut: Dictionary = _get_family_backend_document("uppercut", BACKEND_THRESHOLD)
	var evaluation: Dictionary = uppercut.get("evaluation", {}) if uppercut.get("evaluation", {}) is Dictionary else {}
	var thresholds: Dictionary = uppercut.get("thresholds", {}) if uppercut.get("thresholds", {}) is Dictionary else {}
	var timing: Dictionary = uppercut.get("timing", {}) if uppercut.get("timing", {}) is Dictionary else {}
	var rearm: Dictionary = uppercut.get("rearm", {}) if uppercut.get("rearm", {}) is Dictionary else {}
	var state_machine: Dictionary = uppercut.get("state_machine", {}) if uppercut.get("state_machine", {}) is Dictionary else {}
	config["enabled"] = _get_punch_backend_for_family("uppercut") == BACKEND_THRESHOLD
	config["window_ms"] = max(1, int(evaluation.get("window_ms", config.get("window_ms", POSE_STRIKE_DEFAULT_WINDOW_MS))))
	config["min_velocity"] = maxf(0.0, float(thresholds.get("min_velocity", thresholds.get("min_punch_velocity", config.get("min_velocity", POSE_STRIKE_DEFAULT_MIN_PUNCH_VELOCITY)))))
	config["max_wrist_angle_from_elbow_vertical_deg"] = clampf(float(thresholds.get("max_wrist_angle_from_elbow_vertical_deg", config.get("max_wrist_angle_from_elbow_vertical_deg", UPPERCUT_DEFAULT_MAX_WRIST_ANGLE_FROM_ELBOW_VERTICAL_DEG))), 0.0, 90.0)
	config["triggered_grace_ms"] = max(0, int(timing.get("triggered_grace_ms", config.get("triggered_grace_ms", POSE_STRIKE_DEFAULT_TRIGGERED_GRACE_MS))))
	config["pose_only_rearm_ms"] = max(0, int(rearm.get("pose_only_rearm_ms", config.get("pose_only_rearm_ms", POSE_STRIKE_DEFAULT_POSE_ONLY_REARM_MS))))
	config["lost_tracking_reacquire_stable_ms"] = max(0, int(state_machine.get("lost_tracking_reacquire_stable_ms", config.get("lost_tracking_reacquire_stable_ms", POSE_STRIKE_DEFAULT_REACQUIRE_STABLE_MS))))
	return config

func _get_tracking_hand_payload(tracking_frame: Dictionary, side: String) -> Dictionary:
	var hands: Dictionary = tracking_frame.get("hands", {}) if tracking_frame.get("hands", {}) is Dictionary else {}
	return hands.get(side, {}) if hands.get(side, {}) is Dictionary else {}

func _straight_punch_uses_hand_tracking() -> bool:
	if _config == null:
		return true
	var tracker_profile_document: Variant = _config.get("tracker_profile_document") if _config.has_method("get") else null
	if not tracker_profile_document is Dictionary:
		return true
	var tracking: Dictionary = tracker_profile_document.get("tracking", {}) if tracker_profile_document.get("tracking", {}) is Dictionary else {}
	var hands: Dictionary = tracking.get("hands", {}) if tracking.get("hands", {}) is Dictionary else {}
	return bool(hands.get("enabled", true))

func _is_pose_valid_for_straight_punch(shoulder: Dictionary, wrist: Dictionary, shoulder_width: float) -> bool:
	if shoulder.is_empty() or wrist.is_empty() or shoulder_width <= 0.0:
		return false
	var min_visibility := _get_min_visibility()
	return float(shoulder.get("v", 0.0)) >= min_visibility and float(wrist.get("v", 0.0)) >= min_visibility

func _is_pose_valid_for_pose_strike(shoulder: Dictionary, elbow: Dictionary, wrist: Dictionary, shoulder_width: float) -> bool:
	if shoulder.is_empty() or elbow.is_empty() or wrist.is_empty() or shoulder_width <= 0.0:
		return false
	var min_visibility := _get_min_visibility()
	return float(shoulder.get("v", 0.0)) >= min_visibility and float(elbow.get("v", 0.0)) >= min_visibility and float(wrist.get("v", 0.0)) >= min_visibility

func _compute_wrist_lateral_angle_from_elbow_vertical_deg(elbow: Dictionary, wrist: Dictionary) -> float:
	return _compute_wrist_angle_from_elbow_vertical_deg(elbow, wrist)

func _compute_wrist_angle_from_elbow_horizontal_deg(elbow: Dictionary, wrist: Dictionary) -> float:
	if elbow.is_empty() or wrist.is_empty():
		return 0.0
	var elbow_to_wrist := PoseMetrics.to_vector2(wrist) - PoseMetrics.to_vector2(elbow)
	if elbow_to_wrist.length() <= 0.000001:
		return 0.0
	return rad_to_deg(atan2(absf(elbow_to_wrist.y), maxf(absf(elbow_to_wrist.x), 0.000001)))

func _compute_wrist_angle_from_elbow_vertical_deg(elbow: Dictionary, wrist: Dictionary) -> float:
	if elbow.is_empty() or wrist.is_empty():
		return 0.0
	var elbow_to_wrist := PoseMetrics.to_vector2(wrist) - PoseMetrics.to_vector2(elbow)
	if elbow_to_wrist.length() <= 0.000001:
		return 0.0
	return rad_to_deg(atan2(absf(elbow_to_wrist.x), maxf(absf(elbow_to_wrist.y), 0.000001)))

func _required_hook_side_label(side: String) -> String:
	return "left_of_elbow" if side == "left" else "right_of_elbow"

func _is_wrist_on_required_hook_side(side: String, elbow: Dictionary, wrist: Dictionary) -> bool:
	if elbow.is_empty() or wrist.is_empty():
		return false
	var wrist_offset_x := float(wrist.get("x", 0.0)) - float(elbow.get("x", 0.0))
	return wrist_offset_x < -0.000001 if side == "left" else wrist_offset_x > 0.000001

func _is_wrist_above_elbow_in_camera_space(elbow: Dictionary, wrist: Dictionary) -> bool:
	if elbow.is_empty() or wrist.is_empty():
		return false
	return float(wrist.get("y", 0.0)) > float(elbow.get("y", 0.0)) + 0.000001

func _resolve_straight_punch_velocity_signal_position(state: Dictionary, elbow: Dictionary, wrist_position: Vector3) -> Vector3:
	if elbow.is_empty() or float(elbow.get("v", 0.0)) < _get_min_visibility():
		state["velocity_signal_source"] = "wrist_only"
		return wrist_position
	var elbow_position := PoseMetrics.to_vector3(elbow)
	state["velocity_signal_source"] = "elbow_plus_wrist"
	return (elbow_position + wrist_position) * 0.5

func _is_valid_tracking_hand_sample(hand_payload: Dictionary) -> bool:
	if bool(hand_payload.get("tracking_valid", false)):
		return true
	var tracking_state := String(hand_payload.get("tracking_state", "")).strip_edges().to_lower()
	return tracking_state == "reacquiring"

func _is_fresh_tracking_hand_sample(hand_payload: Dictionary, state: Dictionary) -> bool:
	if hand_payload.has("fresh_sample"):
		return bool(hand_payload.get("fresh_sample", false))
	if not bool(hand_payload.get("tracking_valid", false)):
		return false
	var tracking_state := String(hand_payload.get("tracking_state", ""))
	if not ["tracked", "grace"].has(tracking_state):
		return false
	var frame_index := int(hand_payload.get("frame_index", -1))
	var timestamp_seconds := float(hand_payload.get("timestamp_seconds", -1.0))
	var last_frame_index := int(state.get("last_observation_frame_index", -1))
	var last_timestamp_seconds := float(state.get("last_observation_timestamp_seconds", -1.0))
	if frame_index >= 0 and frame_index != last_frame_index:
		return true
	if timestamp_seconds >= 0.0 and not is_equal_approx(timestamp_seconds, last_timestamp_seconds):
		return true
	var bbox: Dictionary = hand_payload.get("bbox", {}) if hand_payload.get("bbox", {}) is Dictionary else {}
	var bbox_area := maxf(float(bbox.get("area", 0.0)), 0.0)
	return absf(bbox_area - float(state.get("last_bbox_area", 0.0))) > 0.000001

func _resolve_straight_punch_wrist_velocity(state: Dictionary, wrist_position: Vector3, timestamp_ms: int, fresh_sample: bool, straight_punch_config: Dictionary) -> Vector3:
	var history: Array = (state.get("wrist_position_history", []) as Array).duplicate(true)
	var window_ms := max(1, int(straight_punch_config.get("window_ms", STRAIGHT_PUNCH_DEFAULT_WRIST_VELOCITY_WINDOW_MS)))
	if fresh_sample:
		history.append({
			"timestamp_ms": timestamp_ms,
			"position": wrist_position,
		})
		while history.size() > 0 and timestamp_ms - int((history[0] as Dictionary).get("timestamp_ms", timestamp_ms)) > window_ms:
			history.remove_at(0)
		state["wrist_position_history"] = history
	else:
		state["wrist_position_history"] = history
		return state.get("last_wrist_velocity_vector", Vector3.ZERO)
	if history.size() < 2:
		state["last_wrist_velocity_window_span_ms"] = 0
		return Vector3.ZERO
	var oldest: Dictionary = history[0]
	var newest: Dictionary = history[history.size() - 1]
	var dt_ms := maxi(int(newest.get("timestamp_ms", timestamp_ms)) - int(oldest.get("timestamp_ms", timestamp_ms)), 1)
	state["last_wrist_velocity_window_span_ms"] = dt_ms
	var velocity_sum := Vector3.ZERO
	var velocity_sample_count := 0
	for index in range(1, history.size()):
		var previous_entry: Dictionary = history[index - 1] as Dictionary
		var current_entry: Dictionary = history[index] as Dictionary
		var previous_timestamp_ms := int(previous_entry.get("timestamp_ms", timestamp_ms))
		var current_timestamp_ms := int(current_entry.get("timestamp_ms", timestamp_ms))
		var segment_dt_ms := current_timestamp_ms - previous_timestamp_ms
		if segment_dt_ms <= 0:
			continue
		var previous_position: Vector3 = previous_entry.get("position", wrist_position)
		var current_position: Vector3 = current_entry.get("position", wrist_position)
		velocity_sum += (current_position - previous_position) / (float(segment_dt_ms) / 1000.0)
		velocity_sample_count += 1
	if velocity_sample_count <= 0:
		return Vector3.ZERO
	return velocity_sum / float(velocity_sample_count)

func _resolve_straight_punch_forward_depth_spike(state: Dictionary, timestamp_ms: int, fresh_sample: bool, straight_punch_config: Dictionary) -> float:
	var history: Array = (state.get("wrist_position_history", []) as Array).duplicate(true)
	if not fresh_sample:
		state["last_forward_depth_spike_window_span_ms"] = int(state.get("last_forward_depth_spike_window_span_ms", 0))
		return float(state.get("last_forward_depth_spike", 0.0))
	var window_ms := max(1, int(straight_punch_config.get("window_ms", STRAIGHT_PUNCH_DEFAULT_WRIST_VELOCITY_WINDOW_MS)))
	while history.size() > 0 and timestamp_ms - int((history[0] as Dictionary).get("timestamp_ms", timestamp_ms)) > window_ms:
		history.remove_at(0)
	state["wrist_position_history"] = history
	if history.size() < 2:
		state["last_forward_depth_spike_window_span_ms"] = 0
		return 0.0
	var newest: Dictionary = history[history.size() - 1] as Dictionary
	var newest_position: Vector3 = newest.get("position", Vector3.ZERO)
	var newest_timestamp_ms := int(newest.get("timestamp_ms", timestamp_ms))
	var oldest_timestamp_ms := int((history[0] as Dictionary).get("timestamp_ms", timestamp_ms))
	var reference_z := float(newest_position.z)
	for entry_variant: Variant in history:
		var entry: Dictionary = entry_variant as Dictionary
		var position: Vector3 = entry.get("position", newest_position)
		reference_z = maxf(reference_z, float(position.z))
	state["last_forward_depth_spike_window_span_ms"] = maxi(newest_timestamp_ms - oldest_timestamp_ms, 0)
	return maxf(reference_z - float(newest_position.z), 0.0)

func _resolve_pose_strike_motion_window(state: Dictionary, side: String, fallback_velocity_vector: Vector3, timestamp_ms: int) -> Dictionary:
	var history: Array = (state.get("wrist_position_history", []) as Array).duplicate(true)
	if history.size() < 2:
		state["last_wrist_velocity_window_span_ms"] = 0
		return {
			"averaged_velocity_vector": fallback_velocity_vector,
			"wrist_velocity": 0.0,
			"total_motion_velocity": 0.0,
			"lateral_velocity": 0.0,
			"vertical_velocity": 0.0,
			"outward_velocity": 0.0,
			"horizontal_direction_velocity": 0.0,
			"upward_velocity": 0.0,
			"directionality_ratio": 0.0,
			"hook_dominance_ratio": 0.0,
			"uppercut_dominance_ratio": 0.0,
		}
	var oldest: Dictionary = history[0]
	var newest: Dictionary = history[history.size() - 1]
	var dt_ms := maxi(int(newest.get("timestamp_ms", timestamp_ms)) - int(oldest.get("timestamp_ms", timestamp_ms)), 1)
	state["last_wrist_velocity_window_span_ms"] = dt_ms
	var velocity_sum := Vector3.ZERO
	var average_total_motion := 0.0
	var average_lateral_velocity := 0.0
	var average_vertical_velocity := 0.0
	var average_outward_velocity := 0.0
	var average_horizontal_direction_velocity := 0.0
	var average_upward_velocity := 0.0
	var velocity_sample_count := 0
	for index in range(1, history.size()):
		var previous_entry: Dictionary = history[index - 1] as Dictionary
		var current_entry: Dictionary = history[index] as Dictionary
		var previous_timestamp_ms := int(previous_entry.get("timestamp_ms", timestamp_ms))
		var current_timestamp_ms := int(current_entry.get("timestamp_ms", timestamp_ms))
		var segment_dt_ms := current_timestamp_ms - previous_timestamp_ms
		if segment_dt_ms <= 0:
			continue
		var previous_position: Vector3 = previous_entry.get("position", Vector3.ZERO)
		var current_position: Vector3 = current_entry.get("position", Vector3.ZERO)
		var segment_velocity := (current_position - previous_position) / (float(segment_dt_ms) / 1000.0)
		velocity_sum += segment_velocity
		average_total_motion += segment_velocity.length()
		average_lateral_velocity += absf(float(segment_velocity.x))
		average_vertical_velocity += absf(float(segment_velocity.y))
		average_outward_velocity += maxf(float(segment_velocity.x), 0.0) if side == "right" else maxf(-float(segment_velocity.x), 0.0)
		average_horizontal_direction_velocity += maxf(float(segment_velocity.x), 0.0) if side == "left" else maxf(-float(segment_velocity.x), 0.0)
		average_upward_velocity += maxf(float(segment_velocity.y), 0.0)
		velocity_sample_count += 1
	if velocity_sample_count <= 0:
		return {
			"averaged_velocity_vector": fallback_velocity_vector,
			"wrist_velocity": 0.0,
			"total_motion_velocity": 0.0,
			"lateral_velocity": 0.0,
			"vertical_velocity": 0.0,
			"outward_velocity": 0.0,
			"horizontal_direction_velocity": 0.0,
			"upward_velocity": 0.0,
			"directionality_ratio": 0.0,
			"hook_dominance_ratio": 0.0,
			"uppercut_dominance_ratio": 0.0,
		}
	var sample_count := float(velocity_sample_count)
	var averaged_velocity_vector := velocity_sum / sample_count
	var total_motion_velocity := average_total_motion / sample_count
	var lateral_velocity := average_lateral_velocity / sample_count
	var vertical_velocity := average_vertical_velocity / sample_count
	var outward_velocity := average_outward_velocity / sample_count
	var horizontal_direction_velocity := average_horizontal_direction_velocity / sample_count
	var upward_velocity := average_upward_velocity / sample_count
	var directionality_ratio := 0.0
	if horizontal_direction_velocity > 0.0 or upward_velocity > 0.0:
		directionality_ratio = maxf(horizontal_direction_velocity, upward_velocity) / maxf(total_motion_velocity, 0.000001)
	return {
		"averaged_velocity_vector": averaged_velocity_vector,
		"wrist_velocity": averaged_velocity_vector.length(),
		"total_motion_velocity": total_motion_velocity,
		"lateral_velocity": lateral_velocity,
		"vertical_velocity": vertical_velocity,
		"outward_velocity": outward_velocity,
		"horizontal_direction_velocity": horizontal_direction_velocity,
		"upward_velocity": upward_velocity,
		"directionality_ratio": directionality_ratio,
		"hook_dominance_ratio": lateral_velocity / maxf(vertical_velocity, 0.000001) if lateral_velocity > 0.0 else 0.0,
		"uppercut_dominance_ratio": vertical_velocity / maxf(lateral_velocity, 0.000001) if vertical_velocity > 0.0 else 0.0,
	}

func _resolve_straight_punch_bbox_area_growth(state: Dictionary, bbox_area: float, timestamp_ms: int, straight_punch_config: Dictionary) -> float:
	var history: Array = (state.get("bbox_area_window_history", []) as Array).duplicate(true)
	var window_ms := max(1, int(straight_punch_config.get("window_ms", STRAIGHT_PUNCH_DEFAULT_WRIST_VELOCITY_WINDOW_MS)))
	history.append({
		"timestamp_ms": timestamp_ms,
		"area": bbox_area,
	})
	while history.size() > 0 and timestamp_ms - int((history[0] as Dictionary).get("timestamp_ms", timestamp_ms)) > window_ms:
		history.remove_at(0)
	state["bbox_area_window_history"] = history
	var growth_summary := _summarize_bbox_area_growth_window(history, bbox_area, timestamp_ms)
	state["last_bbox_area_growth_window_span_ms"] = int(growth_summary.get("window_span_ms", 0))
	state["last_positive_bbox_growth_samples"] = int(growth_summary.get("positive_growth_samples", 0))
	return float(growth_summary.get("net_growth", 0.0))

func _bbox_area_window_values(history: Array) -> Array:
	var values: Array = []
	for entry_variant: Variant in history:
		var entry: Dictionary = entry_variant as Dictionary
		if entry.is_empty():
			values.append(float(entry_variant))
		else:
			values.append(float(entry.get("area", 0.0)))
	return values

func _summarize_bbox_area_growth_window(history: Array, fallback_area: float = 0.0, fallback_timestamp_ms: int = 0) -> Dictionary:
	if history.size() < 2:
		return {
			"net_growth": 0.0,
			"positive_growth_samples": 0,
			"window_span_ms": 0,
		}
	var net_growth := 0.0
	var positive_growth_samples := 0
	for idx in range(1, history.size()):
		var previous_entry: Dictionary = history[idx - 1] as Dictionary
		var current_entry: Dictionary = history[idx] as Dictionary
		var previous_area := float(previous_entry.get("area", fallback_area)) if not previous_entry.is_empty() else float(history[idx - 1])
		var current_area := float(current_entry.get("area", fallback_area)) if not current_entry.is_empty() else float(history[idx])
		var growth := current_area - previous_area
		net_growth += growth
		if growth > 0.000001:
			positive_growth_samples += 1
	var oldest: Dictionary = history[0] as Dictionary
	var newest: Dictionary = history[history.size() - 1] as Dictionary
	var oldest_timestamp_ms := int(oldest.get("timestamp_ms", fallback_timestamp_ms)) if not oldest.is_empty() else fallback_timestamp_ms
	var newest_timestamp_ms := int(newest.get("timestamp_ms", fallback_timestamp_ms)) if not newest.is_empty() else fallback_timestamp_ms
	return {
		"net_growth": net_growth,
		"positive_growth_samples": positive_growth_samples,
		"window_span_ms": maxi(newest_timestamp_ms - oldest_timestamp_ms, 0),
	}

func _window_peak_float(history: Array) -> float:
	var peak := 0.0
	for value_variant: Variant in history:
		peak = maxf(peak, float(value_variant))
	return peak

func _compute_straight_punch_power(wrist_velocity: float, bbox_area: float, state: Dictionary, straight_punch_config: Dictionary, bbox_growth_override: float = -1.0) -> float:
	var velocity_floor := maxf(float(straight_punch_config.get("min_velocity", STRAIGHT_PUNCH_DEFAULT_MIN_WRIST_VELOCITY)), 0.000001)
	var growth_floor := maxf(float(straight_punch_config.get("min_bbox_area_growth", STRAIGHT_PUNCH_DEFAULT_MIN_BBOX_AREA_GROWTH)), 0.000001)
	var bbox_growth := maxf(bbox_growth_override if bbox_growth_override >= 0.0 else float(state.get("last_bbox_area_growth", 0.0)), 0.0)
	var velocity_power := wrist_velocity / (velocity_floor * 3.0)
	var growth_power := bbox_growth / (growth_floor * 2.0)
	var trigger_bbox_area := maxf(float(state.get("trigger_bbox_area", bbox_area)), 0.000001)
	var area_power := trigger_bbox_area / maxf(bbox_area, 0.000001)
	return clampf(0.35 + velocity_power * 0.35 + growth_power * 0.20 + area_power * 0.10, 0.0, 1.0)

func _compute_pose_strike_power(family: String, wrist_velocity: float, direction_velocity: float, upward_velocity: float, config: Dictionary) -> float:
	var velocity_floor := maxf(float(config.get("min_velocity", config.get("min_punch_velocity", POSE_STRIKE_DEFAULT_MIN_PUNCH_VELOCITY))), 0.000001)
	var dominant_velocity := maxf(direction_velocity if family == "hook" else upward_velocity, 0.0)
	var velocity_power := wrist_velocity / (velocity_floor * 3.0)
	var dominant_power := dominant_velocity / (velocity_floor * 2.0)
	return clampf(0.35 + velocity_power * 0.35 + dominant_power * 0.30, 0.0, 1.0)

func _transition_straight_punch_state(events: Array, side: String, state: Dictionary, next_phase: String) -> void:
	var previous_phase := String(state.get("phase", STRAIGHT_PUNCH_STATE_TRACKING_LOST))
	if previous_phase == next_phase:
		return
	state["phase"] = next_phase
	state["previous_state"] = previous_phase
	state["timestamp_ms"] = int(state.get("current_timestamp_ms", _last_processed_timestamp_ms))
	events.append({
		"name": StringName("straight_punch_state_changed"),
		"side": side,
		"state": next_phase,
		"previous_state": previous_phase,
		"trigger_bbox_area": float(state.get("trigger_bbox_area", 0.0)),
		"elbow_shoulder_xy_distance": float(state.get("elbow_shoulder_xy_distance", 0.0)),
		"max_elbow_shoulder_xy_distance": float(state.get("max_elbow_shoulder_xy_distance", STRAIGHT_PUNCH_DEFAULT_MAX_ELBOW_SHOULDER_XY_DISTANCE)),
		"elbow_shoulder_xy_gate_passed": bool(state.get("elbow_shoulder_xy_gate_passed", false)),
		"wrist_lateral_angle_from_elbow_vertical_deg": float(state.get("wrist_lateral_angle_from_elbow_vertical_deg", 0.0)),
		"min_wrist_lateral_angle_from_elbow_vertical_deg": float(state.get("min_wrist_lateral_angle_from_elbow_vertical_deg", STRAIGHT_PUNCH_DEFAULT_MIN_WRIST_LATERAL_ANGLE_FROM_ELBOW_VERTICAL_DEG)),
		"wrist_lateral_angle_gate_passed": bool(state.get("wrist_lateral_angle_gate_passed", false)),
		"grace_ms_remaining": int(state.get("grace_ms_remaining", 0)),
		"bbox_area": float(state.get("last_bbox_area", 0.0)),
		"bbox_area_growth": float(state.get("last_bbox_area_growth", 0.0)),
		"forward_depth_spike": float(state.get("last_forward_depth_spike", 0.0)),
		"recent_peak_forward_depth_spike": float(state.get("recent_peak_forward_depth_spike", 0.0)),
		"positive_growth_samples": int(state.get("positive_growth_samples", 0)),
		"wrist_velocity": float(state.get("last_wrist_velocity", 0.0)),
		"wrist_forward_velocity": float(state.get("last_wrist_forward_velocity", 0.0)),
		"fresh_sample": bool(state.get("last_sample_fresh", false)),
		"sample_source": String(state.get("hand_sample_source", "none")),
		"tracking_state": String(state.get("hand_tracking_state", "idle")),
		"tracking_valid": bool(state.get("hand_tracking_valid", false)),
	})

func _transition_pose_strike_state(events: Array, family: String, side: String, state: Dictionary, next_phase: String) -> void:
	var previous_phase := String(state.get("phase", POSE_STRIKE_STATE_TRACKING_LOST))
	if previous_phase == next_phase:
		return
	state["phase"] = next_phase
	state["previous_state"] = previous_phase
	state["timestamp_ms"] = int(state.get("current_timestamp_ms", _last_processed_timestamp_ms))
	events.append({
		"name": StringName("%s_state_changed" % family),
		"family": family,
		"side": side,
		"state": next_phase,
		"previous_state": previous_phase,
		"wrist_velocity": float(state.get("last_wrist_velocity", 0.0)),
		"outward_velocity": float(state.get("outward_velocity", 0.0)),
		"upward_velocity": float(state.get("upward_velocity", 0.0)),
		"horizontal_direction_velocity": float(state.get("horizontal_direction_velocity", 0.0)),
		"directionality_ratio": float(state.get("directionality_ratio", 0.0)),
		"dominance_ratio": float(state.get("dominance_ratio", 0.0)),
		"wrist_angle_from_elbow_horizontal_deg": float(state.get("wrist_angle_from_elbow_horizontal_deg", 0.0)),
		"wrist_angle_from_elbow_vertical_deg": float(state.get("wrist_angle_from_elbow_vertical_deg", 0.0)),
		"wrist_horizontal_angle_gate_passed": bool(state.get("wrist_horizontal_angle_gate_passed", false)),
		"wrist_vertical_angle_gate_passed": bool(state.get("wrist_vertical_angle_gate_passed", false)),
		"wrist_on_required_hook_side": bool(state.get("wrist_on_required_hook_side", false)),
		"wrist_above_elbow_gate_passed": bool(state.get("wrist_above_elbow_gate_passed", false)),
		"pose_tracking_valid": bool(state.get("pose_tracking_valid", false)),
		"tracking_state": String(state.get("tracking_state", "pose_missing")),
		"fresh_sample": bool(state.get("last_sample_fresh", false)),
		"sample_source": "pose",
		"grace_ms_remaining": int(state.get("grace_ms_remaining", 0)),
	})

func _emit_power_event(events: Array, event_name: String, power: float) -> void:
	events.append({
		"name": StringName(event_name),
		"power": clampf(power, 0.0, 1.0),
	})

func _get_state(state_name: String) -> bool:
	return bool(_gesture_state.get("states", {}).get(state_name, false))

func _set_ready(event_name: String, ready: bool) -> void:
	var ready_map: Dictionary = _gesture_state.get("ready", {})
	ready_map[event_name] = ready
	_gesture_state["ready"] = ready_map

func _is_ready(event_name: String) -> bool:
	return bool(_gesture_state.get("ready", {}).get(event_name, true))

func _leg_angle_from_core_deg(hip: Dictionary, ankle: Dictionary) -> float:
	if hip.is_empty() or ankle.is_empty():
		return 0.0
	var vector := PoseMetrics.to_vector2(ankle) - PoseMetrics.to_vector2(hip)
	if vector.length() <= 0.000001:
		return 0.0
	return absf(rad_to_deg(vector.angle_to(Vector2.UP)))
