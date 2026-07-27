class_name PoseDetectorSubstrate
extends RefCounted

const DepthRuntimeManagerScript = preload("res://addons/aerobeat-input-camera-tracking/src/depth/depth_runtime_manager.gd")
const DepthSharedRuntimePoolScript = preload("res://addons/aerobeat-input-camera-tracking/src/depth/depth_shared_runtime_pool.gd")
const BACKEND_DISABLED := "disabled"
const BACKEND_THRESHOLD := "threshold"
const BACKEND_GRID_AVOIDANCE := "grid_avoidance"
const BACKEND_GRID_DETECTION := "grid_detection"
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
const GRID_DETECTION_DEFAULT_MIN_CELL_DELTA := 1
const GRID_DETECTION_DEFAULT_DIRECTION_DOMINANCE_RATIO := 0.55

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
const FLOW_DIRECTION_WINDOW_MAX_MS := 220
const FLOW_DIRECTION_WINDOW_MIN_MS := 70
const FLOW_DIRECTION_MIN_TRAVEL_CELL_RATIO := 0.35
const FLOW_GRID_COLUMNS := 4
const FLOW_GRID_ROWS := 3
const FLOW_GRID_SOURCE_ASPECT_RATIO := 16.0 / 9.0

const CALIBRATION_SESSION_IDLE := "idle"
const CALIBRATION_SESSION_WAITING := "waiting"
const CALIBRATION_SESSION_HOLDING := "holding"
const CALIBRATION_SESSION_COOLDOWN := "cooldown"
const CALIBRATION_SESSION_SUCCEEDED := "succeeded"
const CALIBRATION_SESSION_CANCELLED := "cancelled"
const CALIBRATION_MODE_T_POSE_AUTO := "t_pose_auto"
const CALIBRATION_DEFAULT_HOLD_MS := 750
const CALIBRATION_DEFAULT_COOLDOWN_MS := 1000
const CALIBRATION_DEFAULT_MAX_WRIST_SHOULDER_Y_RATIO := 0.18
const CALIBRATION_DEFAULT_MAX_ELBOW_SHOULDER_Y_RATIO := 0.18
const CALIBRATION_DEFAULT_MIN_ELBOW_ANGLE_DEG := 160.0
const CALIBRATION_DEFAULT_GRID_SIZE_MULTIPLIER := 1.0
const CALIBRATION_DEFAULT_CAMERA_SPACE_GRID_HEIGHT_OFFSET := 0.0

var _config = null
var _smoother: LandmarkSmoother = LandmarkSmoother.new()
var _latest_state: Dictionary = {}
var _baseline_accumulator := {
	"frames": 0,
	"shoulder_width": 0.0,
	"torso_height": 0.0,
	"athlete_height": 0.0,
	"shoulder_center_x": 0.0,
	"shoulder_center_y": 0.0,
	"left_shoulder_y": 0.0,
	"hip_center_y": 0.0,
	"nose_x": 0.0,
	"nose_y": 0.0,
	"left_wrist_x": 0.0,
	"right_wrist_x": 0.0,
	"wrist_midpoint_x": 0.0,
	"grid_width": 0.0,
	"grid_height": 0.0,
	"grid_content_aspect_ratio": 0.0,
	"horizontal_wrist_span": 0.0,
	"wrist_span": 0.0,
	"left_knee_y": 0.0,
	"right_knee_y": 0.0,
	"left_ankle_y": 0.0,
	"right_ankle_y": 0.0,
}
var _baseline: Dictionary = {
	"is_calibrated": false,
	"sample_frames": 0,
	"captured_at_ms": 0,
	"capture_source": "",
	"shoulder_width": 0.0,
	"torso_height": 0.0,
	"athlete_height": 0.0,
	"shoulder_center_x": 0.0,
	"shoulder_center_y": 0.0,
	"left_shoulder_y": 0.0,
	"hip_center_y": 0.0,
	"nose_x": 0.0,
	"nose_y": 0.0,
	"left_wrist_x": 0.0,
	"right_wrist_x": 0.0,
	"wrist_midpoint_x": 0.0,
	"grid_width": 0.0,
	"grid_height": 0.0,
	"grid_content_aspect_ratio": FLOW_GRID_SOURCE_ASPECT_RATIO,
	"horizontal_wrist_span": 0.0,
	"wrist_span": 0.0,
	"left_knee_y": 0.0,
	"right_knee_y": 0.0,
	"left_ankle_y": 0.0,
	"right_ankle_y": 0.0,
}
var _calibration_session: Dictionary = {}
var _previous_positions: Dictionary = {}
var _gesture_state := {}
var _consecutive_valid_frames := 0
var _consecutive_invalid_frames := 0
var _reacquire_frames_remaining := 0
var _last_processed_timestamp_ms := 0
var _last_session_source_timestamp_ms := 0
var _session_runtime_timestamp_ms := 0
var _last_session_runtime_step_ms := 0
var _frame_index := 0
var _depth_runtime_managers := {}
var _depth_shared_runtime_pool: RefCounted = DepthSharedRuntimePoolScript.new()

func _init() -> void:
	_smoother = LandmarkSmoother.new(_get_smoothing_window_size(), _get_pose_smoothing_style())
	_reset_calibration_session()
	_latest_state = _build_empty_state()
	_reset_gesture_state()
	_configure_depth_runtime_managers()

func configure(config) -> PoseDetectorSubstrate:
	_config = config
	_smoother = LandmarkSmoother.new(_get_smoothing_window_size(), _get_pose_smoothing_style())
	_configure_depth_runtime_managers()
	return self

func reset() -> void:
	_smoother = LandmarkSmoother.new(_get_smoothing_window_size(), _get_pose_smoothing_style())
	_previous_positions.clear()
	_consecutive_valid_frames = 0
	_consecutive_invalid_frames = 0
	_reacquire_frames_remaining = 0
	_last_processed_timestamp_ms = 0
	_last_session_source_timestamp_ms = 0
	_session_runtime_timestamp_ms = 0
	_last_session_runtime_step_ms = 0
	_frame_index = 0
	_reset_baseline_calibration()
	_reset_calibration_session()
	_reset_gesture_state()
	_latest_state = _build_empty_state()
	_configure_depth_runtime_managers()

func request_athlete_recalibration() -> void:
	_reset_baseline_calibration()
	_clear_transient_gesture_state()
	_reset_calibration_session()
	if _latest_state.is_empty():
		_latest_state = _build_empty_state()
		return
	_sync_calibration_state_into_latest_state()

func cancel_athlete_recalibration() -> void:
	_clear_transient_gesture_state()
	_reset_baseline_calibration()
	_calibration_session = _build_calibration_session(CALIBRATION_SESSION_CANCELLED)
	_calibration_session["failure_reason"] = "cancelled"
	_calibration_session["instruction_key"] = "hold_t_pose"
	_calibration_session["instruction_text"] = "Auto-calibration reset. Hold a T-pose again to capture a new baseline"
	_sync_calibration_state_into_latest_state()

func get_calibration_session() -> Dictionary:
	return _calibration_session.duplicate(true)

func _reset_calibration_session() -> void:
	var initial_state := CALIBRATION_SESSION_WAITING if _get_calibration_mode() == CALIBRATION_MODE_T_POSE_AUTO else CALIBRATION_SESSION_IDLE
	_calibration_session = _build_calibration_session(initial_state)

func _build_calibration_session(state_name: String) -> Dictionary:
	return {
		"state": state_name,
		"is_active": _is_calibration_session_active_state(state_name),
		"result": state_name if state_name != CALIBRATION_SESSION_IDLE else "idle",
		"mode": _get_calibration_mode(),
		"hold_ms": _get_calibration_hold_ms(),
		"cooldown_ms": _get_calibration_cooldown_ms(),
		"hold_started_at_ms": 0,
		"hold_progress_ms": 0,
		"hold_progress_ratio": 0.0,
		"last_fired_at_ms": 0,
		"next_fire_at_ms": 0,
		"cooldown_remaining_ms": 0,
		"captured_at_ms": 0,
		"captured_sample_frames": 0,
		"required_capture_frames": 1,
		"failure_reason": "",
		"instruction_key": "hold_t_pose",
		"instruction_text": "Hold a straight-arm T-pose to auto-calibrate",
		"readiness": _build_default_calibration_readiness(),
		"instructions": _build_calibration_instructions(_build_default_calibration_readiness()),
	}

func _build_default_calibration_readiness() -> Dictionary:
	return {
		"tracking_ready": false,
		"required_landmarks_ready": false,
		"horizontal_alignment_ready": false,
		"arm_extension_ready": false,
		"qualified": false,
		"hold_ready": false,
		"ready": false,
		"hold_ms": _get_calibration_hold_ms(),
		"hold_progress_ms": 0,
		"hold_progress_ratio": 0.0,
		"cooldown_ms": _get_calibration_cooldown_ms(),
		"cooldown_remaining_ms": 0,
		"failure_reason": "required_sample_landmarks_unavailable",
		"instruction_key": "show_sample_landmarks",
		"instruction_text": "Need tracking/reacquiring plus nose, shoulders, elbows, and wrists visible",
		"required_landmarks": {
			"nose": false,
			"left_shoulder": false,
			"right_shoulder": false,
			"left_elbow": false,
			"right_elbow": false,
			"left_wrist": false,
			"right_wrist": false,
		},
		"thresholds": {
			"max_wrist_shoulder_y_ratio": _get_calibration_threshold("max_wrist_shoulder_y_ratio", CALIBRATION_DEFAULT_MAX_WRIST_SHOULDER_Y_RATIO),
			"max_elbow_shoulder_y_ratio": _get_calibration_threshold("max_elbow_shoulder_y_ratio", CALIBRATION_DEFAULT_MAX_ELBOW_SHOULDER_Y_RATIO),
			"min_elbow_angle_deg": _get_calibration_threshold("min_elbow_angle_deg", CALIBRATION_DEFAULT_MIN_ELBOW_ANGLE_DEG),
		},
		"measurements": {
			"shoulder_width": 0.0,
			"left_wrist_shoulder_y_ratio": 0.0,
			"right_wrist_shoulder_y_ratio": 0.0,
			"left_elbow_shoulder_y_ratio": 0.0,
			"right_elbow_shoulder_y_ratio": 0.0,
			"left_arm_extension": 0.0,
			"right_arm_extension": 0.0,
			"left_elbow_bend_deg": 0.0,
			"right_elbow_bend_deg": 0.0,
			"calibration_width": 0.0,
			"calibration_height": 0.0,
		},
	}

func _build_calibration_instructions(readiness: Dictionary) -> Dictionary:
	return {
		"tracking_ready": {
			"key": "tracking_ready",
			"text": "Tracking state is tracking/reacquiring",
			"ready": bool(readiness.get("tracking_ready", false)),
		},
		"show_sample_landmarks": {
			"key": "show_sample_landmarks",
			"text": "Keep nose, shoulders, elbows, and wrists visible",
			"ready": bool(readiness.get("required_landmarks_ready", false)),
		},
		"align_arms_horizontal": {
			"key": "align_arms_horizontal",
			"text": "Keep both arms level with the shoulders",
			"ready": bool(readiness.get("horizontal_alignment_ready", false)),
		},
		"extend_arms": {
			"key": "extend_arms",
			"text": "Straighten and fully extend both arms",
			"ready": bool(readiness.get("arm_extension_ready", false)),
		},
		"hold_t_pose": {
			"key": "hold_t_pose",
			"text": "Hold the T-pose until auto-calibration fires",
			"ready": bool(readiness.get("hold_ready", false)),
		},
	}

func _is_calibration_session_active_state(state_name: String) -> bool:
	return state_name == CALIBRATION_SESSION_WAITING or state_name == CALIBRATION_SESSION_HOLDING or state_name == CALIBRATION_SESSION_COOLDOWN

func _get_calibration_document() -> Dictionary:
	var gesture_profile_document := _get_gesture_profile_document()
	return gesture_profile_document.get("calibration", {}) if gesture_profile_document.get("calibration", {}) is Dictionary else {}

func _get_calibration_t_pose_document() -> Dictionary:
	var calibration_document := _get_calibration_document()
	return calibration_document.get("t_pose", {}) if calibration_document.get("t_pose", {}) is Dictionary else {}

func _get_calibration_thresholds_document() -> Dictionary:
	var t_pose_document := _get_calibration_t_pose_document()
	return t_pose_document.get("thresholds", {}) if t_pose_document.get("thresholds", {}) is Dictionary else {}

func _get_calibration_mode() -> String:
	var calibration_document := _get_calibration_document()
	var mode := String(calibration_document.get("mode", CALIBRATION_MODE_T_POSE_AUTO)).strip_edges().to_lower()
	return CALIBRATION_MODE_T_POSE_AUTO if mode.is_empty() else mode

func _get_calibration_hold_ms() -> int:
	var t_pose_document := _get_calibration_t_pose_document()
	return maxi(int(t_pose_document.get("hold_ms", CALIBRATION_DEFAULT_HOLD_MS)), 0)

func _get_calibration_cooldown_ms() -> int:
	var t_pose_document := _get_calibration_t_pose_document()
	return maxi(int(t_pose_document.get("cooldown_ms", CALIBRATION_DEFAULT_COOLDOWN_MS)), 0)

func _get_calibration_threshold(key: String, fallback: float) -> float:
	var thresholds := _get_calibration_thresholds_document()
	return float(thresholds.get(key, fallback))

func _get_calibration_grid_size_multiplier() -> float:
	var t_pose_document := _get_calibration_t_pose_document()
	var multiplier := float(t_pose_document.get("grid_size_multiplier", CALIBRATION_DEFAULT_GRID_SIZE_MULTIPLIER))
	return multiplier if multiplier > 0.000001 else CALIBRATION_DEFAULT_GRID_SIZE_MULTIPLIER

func _get_calibration_camera_space_grid_height_offset() -> float:
	var t_pose_document := _get_calibration_t_pose_document()
	return float(t_pose_document.get("camera_space_grid_height_offset", CALIBRATION_DEFAULT_CAMERA_SPACE_GRID_HEIGHT_OFFSET))

func _sync_calibration_state_into_latest_state() -> void:
	if _latest_state.is_empty():
		_latest_state = _build_empty_state()
	var metrics: Dictionary = _latest_state.get("metrics", {})
	metrics["baseline"] = _baseline.duplicate(true)
	metrics["calibration_session"] = _calibration_session.duplicate(true)
	var measurements: Dictionary = metrics.get("measurements", {})
	measurements["height_ratio"] = 1.0 if not bool(_baseline.get("is_calibrated", false)) else float(measurements.get("height_ratio", 1.0))
	measurements["height_state"] = StringName("unknown") if not bool(_baseline.get("is_calibrated", false)) else measurements.get("height_state", StringName("unknown"))
	measurements["squat_depth"] = 0.0 if not bool(_baseline.get("is_calibrated", false)) else float(measurements.get("squat_depth", 0.0))
	metrics["measurements"] = measurements
	_latest_state["baseline"] = _baseline.duplicate(true)
	_latest_state["metrics"] = metrics
	_latest_state["calibration_session"] = _calibration_session.duplicate(true)
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
		"shoulder_center_y": 0.0,
		"left_shoulder_y": 0.0,
		"hip_center_y": 0.0,
		"nose_x": 0.0,
		"nose_y": 0.0,
		"left_wrist_x": 0.0,
		"right_wrist_x": 0.0,
		"wrist_midpoint_x": 0.0,
		"grid_width": 0.0,
		"grid_height": 0.0,
		"grid_content_aspect_ratio": 0.0,
		"horizontal_wrist_span": 0.0,
		"wrist_span": 0.0,
		"left_knee_y": 0.0,
		"right_knee_y": 0.0,
		"left_ankle_y": 0.0,
		"right_ankle_y": 0.0,
	}
	_baseline = {
		"is_calibrated": false,
		"sample_frames": 0,
		"captured_at_ms": 0,
		"capture_source": "",
		"shoulder_width": 0.0,
		"torso_height": 0.0,
		"athlete_height": 0.0,
		"shoulder_center_x": 0.0,
		"shoulder_center_y": 0.0,
		"left_shoulder_y": 0.0,
		"hip_center_y": 0.0,
		"nose_x": 0.0,
		"nose_y": 0.0,
		"left_wrist_x": 0.0,
		"right_wrist_x": 0.0,
		"wrist_midpoint_x": 0.0,
		"grid_width": 0.0,
		"grid_height": 0.0,
		"grid_content_aspect_ratio": FLOW_GRID_SOURCE_ASPECT_RATIO,
		"horizontal_wrist_span": 0.0,
		"wrist_span": 0.0,
		"left_knee_y": 0.0,
		"right_knee_y": 0.0,
		"left_ankle_y": 0.0,
		"right_ankle_y": 0.0,
	}

func process_landmarks(landmarks: Array, timestamp_ms: int = 0, tracking_frame: Dictionary = {}) -> Dictionary:
	if timestamp_ms <= 0:
		timestamp_ms = Time.get_ticks_msec()
	var source_timestamp_rewound := _last_processed_timestamp_ms > 0 and timestamp_ms < _last_processed_timestamp_ms
	if source_timestamp_rewound:
		_reset_temporal_runtime_state_for_timestamp_rewind()
	var runtime_timestamp_ms := _advance_session_runtime_timestamp(timestamp_ms, source_timestamp_rewound)
	_frame_index += 1
	var smoothed_landmarks: Dictionary = _smoother.push_landmarks(landmarks)
	var metrics: Dictionary = _build_metrics(smoothed_landmarks, timestamp_ms)
	var tracking_state: StringName = _update_tracking_state(smoothed_landmarks)
	var calibration_readiness := _evaluate_calibration_readiness(metrics, tracking_state, smoothed_landmarks, tracking_frame)
	_update_calibration_session(runtime_timestamp_ms, calibration_readiness)
	_update_baseline(metrics, tracking_state, smoothed_landmarks, runtime_timestamp_ms, tracking_frame)
	_update_flow_tracking_state(smoothed_landmarks, metrics, timestamp_ms)
	metrics["tracking_state"] = tracking_state
	metrics["runtime_timestamp_ms"] = runtime_timestamp_ms
	metrics["baseline"] = _baseline.duplicate(true)
	metrics["calibration_session"] = _calibration_session.duplicate(true)
	metrics["hand_tracking"] = tracking_frame.get("hand_tracking", {}).duplicate(true) if tracking_frame.get("hand_tracking", {}) is Dictionary else {}
	metrics["hands"] = tracking_frame.get("hands", {}).duplicate(true) if tracking_frame.get("hands", {}) is Dictionary else {}
	var events: Array = []
	if tracking_state == TRACKING_TRACKING or tracking_state == TRACKING_REACQUIRING:
		if _should_evaluate_gestures_this_frame():
			events = _detect_intent_events(smoothed_landmarks, metrics, timestamp_ms, tracking_frame)
	else:
		_clear_transient_gesture_state(true)
	_latest_state = {
		"frame_index": _frame_index,
		"timestamp_ms": timestamp_ms,
		"runtime_timestamp_ms": runtime_timestamp_ms,
		"tracking_state": tracking_state,
		"landmarks_by_id": smoothed_landmarks.duplicate(true),
		"baseline": _baseline.duplicate(true),
		"calibration_session": _calibration_session.duplicate(true),
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
	var readiness := _build_default_calibration_readiness()
	readiness["failure_reason"] = "tracking_lost"
	readiness["instruction_key"] = "tracking_ready"
	readiness["instruction_text"] = "Need tracking or reacquiring before calibration capture can start"
	_update_calibration_session(timestamp_ms, readiness)
	_latest_state["gesture_debug"] = _build_gesture_debug_state()
	var metrics: Dictionary = _latest_state.get("metrics", {})
	metrics["tracking_state"] = TRACKING_LOST
	metrics["calibration_session"] = _calibration_session.duplicate(true)
	_latest_state["metrics"] = metrics
	_latest_state["calibration_session"] = _calibration_session.duplicate(true)

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
		"runtime_timestamp_ms": _session_runtime_timestamp_ms,
		"tracking_state": TRACKING_LOST,
		"landmarks_by_id": {},
		"baseline": _baseline.duplicate(true),
		"calibration_session": _calibration_session.duplicate(true),
		"metrics": {
			"tracking_state": TRACKING_LOST,
			"confidences": {},
			"velocities": {},
			"directions": {},
			"measurements": {},
			"baseline": _baseline.duplicate(true),
			"calibration_session": _calibration_session.duplicate(true),
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

func _get_landmark_subset(landmarks_by_id: Dictionary, landmark_ids: Array) -> Dictionary:
	var subset := {}
	for landmark_id_variant: Variant in landmark_ids:
		var landmark_id := int(landmark_id_variant)
		subset[landmark_id] = PoseMetrics.get_landmark(landmarks_by_id, landmark_id)
	return subset

func _get_gameplay_anchor_landmarks(landmarks_by_id: Dictionary) -> Dictionary:
	# Narrow local reuse helper for gameplay-only logic paths; full-frame ingestion and
	# lower-body-dependent runtime/public state remain unchanged in this repo.
	return _get_landmark_subset(landmarks_by_id, PoseLandmarkIds.GAMEPLAY_ANCHOR_LANDMARKS)

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

func _update_baseline(metrics: Dictionary, tracking_state: StringName, landmarks_by_id: Dictionary, timestamp_ms: int, tracking_frame: Dictionary = {}) -> void:
	var calibration_ready := bool((_calibration_session.get("readiness", {}) as Dictionary).get("ready", false))
	if bool(_baseline.get("is_calibrated", false)) and not calibration_ready:
		return
	if tracking_state != TRACKING_TRACKING and tracking_state != TRACKING_REACQUIRING:
		return
	var measurements: Dictionary = metrics.get("measurements", {})
	if measurements.is_empty():
		return
	var shoulder_width := float(measurements.get("shoulder_width", 0.0))
	var torso_height := float(measurements.get("torso_height", 0.0))
	var athlete_height := float(measurements.get("athlete_height", 0.0))
	var gameplay_anchors := _get_gameplay_anchor_landmarks(landmarks_by_id)
	var nose: Dictionary = gameplay_anchors.get(PoseLandmarkIds.NOSE, {})
	var left_shoulder: Dictionary = gameplay_anchors.get(PoseLandmarkIds.LEFT_SHOULDER, {})
	var right_shoulder: Dictionary = gameplay_anchors.get(PoseLandmarkIds.RIGHT_SHOULDER, {})
	var left_elbow: Dictionary = gameplay_anchors.get(PoseLandmarkIds.LEFT_ELBOW, {})
	var right_elbow: Dictionary = gameplay_anchors.get(PoseLandmarkIds.RIGHT_ELBOW, {})
	var left_wrist: Dictionary = gameplay_anchors.get(PoseLandmarkIds.LEFT_WRIST, {})
	var right_wrist: Dictionary = gameplay_anchors.get(PoseLandmarkIds.RIGHT_WRIST, {})
	var wrist_span := PoseMetrics.distance_2d(left_wrist, right_wrist)
	var left_wrist_x := float(left_wrist.get("x", 0.0))
	var right_wrist_x := float(right_wrist.get("x", 0.0))
	var wrist_midpoint_x := (left_wrist_x + right_wrist_x) * 0.5
	var calibration_width := _compute_calibration_grid_width(left_wrist, right_wrist)
	var grid_content_aspect_ratio := _resolve_flow_grid_content_aspect_ratio(tracking_frame)
	var calibration_height := _compute_calibration_grid_height(calibration_width, grid_content_aspect_ratio)
	if shoulder_width <= 0.0 or torso_height <= 0.0 or calibration_width <= 0.0 or calibration_height <= 0.0 or nose.is_empty() or left_shoulder.is_empty() or right_shoulder.is_empty() or left_elbow.is_empty() or right_elbow.is_empty():
		return
	if calibration_ready:
		_reset_baseline_calibration()
	_baseline_accumulator["frames"] += 1
	_baseline_accumulator["shoulder_width"] += shoulder_width
	_baseline_accumulator["torso_height"] += torso_height
	_baseline_accumulator["athlete_height"] += athlete_height
	_baseline_accumulator["shoulder_center_x"] += float(measurements.get("body_centerline_x", 0.0))
	var shoulder_center: Variant = measurements.get("shoulder_center", Vector3.ZERO)
	if shoulder_center is Vector3:
		_baseline_accumulator["shoulder_center_y"] += shoulder_center.y
	_baseline_accumulator["left_shoulder_y"] += float(left_shoulder.get("y", 0.0))
	var hip_center: Variant = measurements.get("hip_center", Vector3.ZERO)
	if hip_center is Vector3:
		_baseline_accumulator["hip_center_y"] += hip_center.y
	_baseline_accumulator["nose_x"] += float(nose.get("x", 0.0))
	_baseline_accumulator["nose_y"] += float(nose.get("y", 0.0))
	_baseline_accumulator["left_wrist_x"] += left_wrist_x
	_baseline_accumulator["right_wrist_x"] += right_wrist_x
	_baseline_accumulator["wrist_midpoint_x"] += wrist_midpoint_x
	_baseline_accumulator["grid_width"] += calibration_width
	_baseline_accumulator["grid_height"] += calibration_height
	_baseline_accumulator["grid_content_aspect_ratio"] += grid_content_aspect_ratio
	_baseline_accumulator["horizontal_wrist_span"] += calibration_width
	_baseline_accumulator["wrist_span"] += wrist_span
	_baseline_accumulator["left_knee_y"] += float(PoseMetrics.get_landmark(landmarks_by_id, PoseLandmarkIds.LEFT_KNEE).get("y", 0.0))
	_baseline_accumulator["right_knee_y"] += float(PoseMetrics.get_landmark(landmarks_by_id, PoseLandmarkIds.RIGHT_KNEE).get("y", 0.0))
	_baseline_accumulator["left_ankle_y"] += float(PoseMetrics.get_landmark(landmarks_by_id, PoseLandmarkIds.LEFT_ANKLE).get("y", 0.0))
	_baseline_accumulator["right_ankle_y"] += float(PoseMetrics.get_landmark(landmarks_by_id, PoseLandmarkIds.RIGHT_ANKLE).get("y", 0.0))
	var frames: int = int(_baseline_accumulator["frames"])
	var required_frames := 1 if calibration_ready else 5
	if frames < required_frames:
		_calibration_session["captured_sample_frames"] = frames if calibration_ready else int(_calibration_session.get("captured_sample_frames", 0))
		return
	var capture_source := "calibration_session" if calibration_ready else "auto_bootstrap"
	_baseline = {
		"is_calibrated": true,
		"sample_frames": frames,
		"captured_at_ms": timestamp_ms,
		"capture_source": capture_source,
		"shoulder_width": float(_baseline_accumulator["shoulder_width"]) / float(frames),
		"torso_height": float(_baseline_accumulator["torso_height"]) / float(frames),
		"athlete_height": float(_baseline_accumulator["athlete_height"]) / float(frames),
		"shoulder_center_x": float(_baseline_accumulator["shoulder_center_x"]) / float(frames),
		"shoulder_center_y": float(_baseline_accumulator["shoulder_center_y"]) / float(frames),
		"left_shoulder_y": float(_baseline_accumulator["left_shoulder_y"]) / float(frames),
		"hip_center_y": float(_baseline_accumulator["hip_center_y"]) / float(frames),
		"nose_x": float(_baseline_accumulator["nose_x"]) / float(frames),
		"nose_y": float(_baseline_accumulator["nose_y"]) / float(frames),
		"left_wrist_x": float(_baseline_accumulator["left_wrist_x"]) / float(frames),
		"right_wrist_x": float(_baseline_accumulator["right_wrist_x"]) / float(frames),
		"wrist_midpoint_x": float(_baseline_accumulator["wrist_midpoint_x"]) / float(frames),
		"grid_width": float(_baseline_accumulator["grid_width"]) / float(frames),
		"grid_height": float(_baseline_accumulator["grid_height"]) / float(frames),
		"grid_content_aspect_ratio": float(_baseline_accumulator["grid_content_aspect_ratio"]) / float(frames),
		"horizontal_wrist_span": float(_baseline_accumulator["horizontal_wrist_span"]) / float(frames),
		"wrist_span": float(_baseline_accumulator["wrist_span"]) / float(frames),
		"left_knee_y": float(_baseline_accumulator["left_knee_y"]) / float(frames),
		"right_knee_y": float(_baseline_accumulator["right_knee_y"]) / float(frames),
		"left_ankle_y": float(_baseline_accumulator["left_ankle_y"]) / float(frames),
		"right_ankle_y": float(_baseline_accumulator["right_ankle_y"]) / float(frames),
	}
	if calibration_ready:
		_calibration_session["state"] = CALIBRATION_SESSION_SUCCEEDED
		_calibration_session["result"] = CALIBRATION_SESSION_SUCCEEDED
		_calibration_session["captured_at_ms"] = timestamp_ms
		_calibration_session["captured_sample_frames"] = frames
		_calibration_session["last_fired_at_ms"] = timestamp_ms
		_calibration_session["next_fire_at_ms"] = timestamp_ms + _get_calibration_cooldown_ms()
		_calibration_session["cooldown_remaining_ms"] = _get_calibration_cooldown_ms()
		_calibration_session["failure_reason"] = ""
		_calibration_session["instruction_key"] = "hold_t_pose"
		_calibration_session["instruction_text"] = "Auto-calibration captured. Hold the T-pose to re-fire after cooldown"

func _compute_calibration_grid_width(left_wrist: Dictionary, right_wrist: Dictionary) -> float:
	return _camera_space_axis_distance(left_wrist, right_wrist, "x") * _get_calibration_grid_size_multiplier()

func _compute_calibration_grid_height(calibration_width: float, grid_content_aspect_ratio: float = FLOW_GRID_SOURCE_ASPECT_RATIO) -> float:
	if calibration_width <= 0.0:
		return 0.0
	return calibration_width * _sanitize_flow_grid_content_aspect_ratio(grid_content_aspect_ratio) * float(FLOW_GRID_ROWS) / float(FLOW_GRID_COLUMNS)

func _camera_space_axis_distance(a: Dictionary, b: Dictionary, axis: String) -> float:
	if a.is_empty() or b.is_empty():
		return 0.0
	return absf(float(a.get(axis, 0.0)) - float(b.get(axis, 0.0)))

func _sanitize_flow_grid_content_aspect_ratio(value: float) -> float:
	return value if value > 0.000001 else FLOW_GRID_SOURCE_ASPECT_RATIO

func _resolve_flow_grid_content_aspect_ratio(tracking_frame: Dictionary = {}) -> float:
	var preview_descriptor: Dictionary = tracking_frame.get("preview_descriptor", {}) if tracking_frame.get("preview_descriptor", {}) is Dictionary else {}
	var aspect_ratio := _aspect_ratio_from_preview_descriptor(preview_descriptor)
	if aspect_ratio > 0.000001:
		return aspect_ratio
	var frame_size: Dictionary = tracking_frame.get("frame_size", {}) if tracking_frame.get("frame_size", {}) is Dictionary else {}
	aspect_ratio = _aspect_ratio_from_size(float(frame_size.get("x", 0.0)), float(frame_size.get("y", 0.0)))
	if aspect_ratio > 0.000001:
		return aspect_ratio
	return FLOW_GRID_SOURCE_ASPECT_RATIO

func _aspect_ratio_from_preview_descriptor(preview_descriptor: Dictionary) -> float:
	if preview_descriptor.is_empty():
		return 0.0
	var image_width := float(preview_descriptor.get("image_width", 0.0))
	var image_height := float(preview_descriptor.get("image_height", 0.0))
	var aspect_ratio := _aspect_ratio_from_size(image_width, image_height)
	if aspect_ratio > 0.000001:
		return aspect_ratio
	var preview_width := float(preview_descriptor.get("width", 0.0))
	var preview_height := float(preview_descriptor.get("height", 0.0))
	return _aspect_ratio_from_size(preview_width, preview_height)

func _aspect_ratio_from_size(width: float, height: float) -> float:
	if width <= 0.000001 or height <= 0.000001:
		return 0.0
	return width / height

func _estimate_height_state(height_ratio: float, hip_center_delta_y: float) -> StringName:
	if height_ratio <= 0.82 or hip_center_delta_y > 0.05:
		return &"lowered"
	if height_ratio >= 0.95:
		return &"standing"
	return &"transition"

func _update_calibration_session(timestamp_ms: int, readiness: Dictionary) -> void:
	if _calibration_session.is_empty():
		_reset_calibration_session()
	_calibration_session["mode"] = _get_calibration_mode()
	_calibration_session["hold_ms"] = _get_calibration_hold_ms()
	_calibration_session["cooldown_ms"] = _get_calibration_cooldown_ms()
	_calibration_session["readiness"] = readiness.duplicate(true)
	_calibration_session["instructions"] = _build_calibration_instructions(readiness)
	_calibration_session["is_active"] = _get_calibration_mode() == CALIBRATION_MODE_T_POSE_AUTO
	_calibration_session["hold_progress_ms"] = int(readiness.get("hold_progress_ms", 0))
	_calibration_session["hold_progress_ratio"] = float(readiness.get("hold_progress_ratio", 0.0))
	var cooldown_remaining_ms := int(readiness.get("cooldown_remaining_ms", -1))
	if cooldown_remaining_ms < 0:
		var last_fired_at_ms := int(_calibration_session.get("last_fired_at_ms", 0))
		cooldown_remaining_ms = maxi((last_fired_at_ms + _get_calibration_cooldown_ms()) - timestamp_ms, 0) if last_fired_at_ms > 0 else 0
	_calibration_session["cooldown_remaining_ms"] = cooldown_remaining_ms
	_calibration_session["instruction_key"] = String(readiness.get("instruction_key", "hold_t_pose"))
	_calibration_session["instruction_text"] = String(readiness.get("instruction_text", "Hold a straight-arm T-pose to auto-calibrate"))
	var hold_started_at_ms := int(readiness.get("hold_started_at_ms", 0))
	_calibration_session["hold_started_at_ms"] = hold_started_at_ms
	if _get_calibration_mode() != CALIBRATION_MODE_T_POSE_AUTO:
		_calibration_session["state"] = CALIBRATION_SESSION_IDLE
		_calibration_session["result"] = CALIBRATION_SESSION_IDLE
		return
	if cooldown_remaining_ms > 0:
		_calibration_session["state"] = CALIBRATION_SESSION_COOLDOWN
		_calibration_session["result"] = "pending"
		_calibration_session["failure_reason"] = "cooldown_active"
		_calibration_session["hold_started_at_ms"] = 0
		_calibration_session["hold_progress_ms"] = 0
		_calibration_session["hold_progress_ratio"] = 0.0
		_calibration_session["next_fire_at_ms"] = int(_calibration_session.get("last_fired_at_ms", 0)) + _get_calibration_cooldown_ms()
		return
	if bool(readiness.get("ready", false)):
		_calibration_session["state"] = CALIBRATION_SESSION_HOLDING
		_calibration_session["result"] = "pending"
		_calibration_session["failure_reason"] = ""
		return
	if bool(readiness.get("qualified", false)):
		_calibration_session["state"] = CALIBRATION_SESSION_HOLDING
		_calibration_session["result"] = "pending"
		_calibration_session["failure_reason"] = ""
		return
	_calibration_session["state"] = CALIBRATION_SESSION_WAITING
	_calibration_session["result"] = "pending"
	_calibration_session["failure_reason"] = String(readiness.get("failure_reason", "required_sample_landmarks_unavailable"))

func _evaluate_calibration_readiness(metrics: Dictionary, tracking_state: StringName, landmarks_by_id: Dictionary, tracking_frame: Dictionary = {}) -> Dictionary:
	var readiness := _build_default_calibration_readiness()
	var hold_ms := _get_calibration_hold_ms()
	var cooldown_ms := _get_calibration_cooldown_ms()
	readiness["hold_ms"] = hold_ms
	readiness["cooldown_ms"] = cooldown_ms
	var runtime_timestamp_ms := int(_session_runtime_timestamp_ms)
	if tracking_state != TRACKING_TRACKING and tracking_state != TRACKING_REACQUIRING:
		readiness["failure_reason"] = "tracking_lost"
		readiness["instruction_key"] = "tracking_ready"
		readiness["instruction_text"] = "Need tracking or reacquiring before T-pose auto-calibration can run"
		return readiness
	readiness["tracking_ready"] = true
	var gameplay_anchors := _get_gameplay_anchor_landmarks(landmarks_by_id)
	var nose: Dictionary = gameplay_anchors.get(PoseLandmarkIds.NOSE, {})
	var left_shoulder: Dictionary = gameplay_anchors.get(PoseLandmarkIds.LEFT_SHOULDER, {})
	var right_shoulder: Dictionary = gameplay_anchors.get(PoseLandmarkIds.RIGHT_SHOULDER, {})
	var left_elbow: Dictionary = gameplay_anchors.get(PoseLandmarkIds.LEFT_ELBOW, {})
	var right_elbow: Dictionary = gameplay_anchors.get(PoseLandmarkIds.RIGHT_ELBOW, {})
	var left_wrist: Dictionary = gameplay_anchors.get(PoseLandmarkIds.LEFT_WRIST, {})
	var right_wrist: Dictionary = gameplay_anchors.get(PoseLandmarkIds.RIGHT_WRIST, {})
	readiness["required_landmarks"] = {
		"nose": not nose.is_empty(),
		"left_shoulder": not left_shoulder.is_empty(),
		"right_shoulder": not right_shoulder.is_empty(),
		"left_elbow": not left_elbow.is_empty(),
		"right_elbow": not right_elbow.is_empty(),
		"left_wrist": not left_wrist.is_empty(),
		"right_wrist": not right_wrist.is_empty(),
	}
	if nose.is_empty() or left_shoulder.is_empty() or right_shoulder.is_empty() or left_elbow.is_empty() or right_elbow.is_empty() or left_wrist.is_empty() or right_wrist.is_empty():
		readiness["failure_reason"] = "required_sample_landmarks_unavailable"
		readiness["instruction_key"] = "show_sample_landmarks"
		readiness["instruction_text"] = "Need nose, shoulders, elbows, and wrists visible before T-pose auto-calibration can run"
		return readiness
	readiness["required_landmarks_ready"] = true
	var measurements: Dictionary = metrics.get("measurements", {})
	var shoulder_width := maxf(float(measurements.get("shoulder_width", 0.0)), 0.000001)
	var max_wrist_ratio := _get_calibration_threshold("max_wrist_shoulder_y_ratio", CALIBRATION_DEFAULT_MAX_WRIST_SHOULDER_Y_RATIO)
	var max_elbow_ratio := _get_calibration_threshold("max_elbow_shoulder_y_ratio", CALIBRATION_DEFAULT_MAX_ELBOW_SHOULDER_Y_RATIO)
	readiness["thresholds"] = {
		"max_wrist_shoulder_y_ratio": max_wrist_ratio,
		"max_elbow_shoulder_y_ratio": max_elbow_ratio,
		"min_elbow_angle_deg": _get_calibration_threshold("min_elbow_angle_deg", CALIBRATION_DEFAULT_MIN_ELBOW_ANGLE_DEG),
	}
	var left_wrist_shoulder_y_ratio := absf(float(left_wrist.get("y", 0.0)) - float(left_shoulder.get("y", 0.0))) / shoulder_width
	var right_wrist_shoulder_y_ratio := absf(float(right_wrist.get("y", 0.0)) - float(right_shoulder.get("y", 0.0))) / shoulder_width
	var left_elbow_shoulder_y_ratio := absf(float(left_elbow.get("y", 0.0)) - float(left_shoulder.get("y", 0.0))) / shoulder_width
	var right_elbow_shoulder_y_ratio := absf(float(right_elbow.get("y", 0.0)) - float(right_shoulder.get("y", 0.0))) / shoulder_width
	readiness["measurements"] = {
		"shoulder_width": shoulder_width,
		"left_wrist_shoulder_y_ratio": left_wrist_shoulder_y_ratio,
		"right_wrist_shoulder_y_ratio": right_wrist_shoulder_y_ratio,
		"left_elbow_shoulder_y_ratio": left_elbow_shoulder_y_ratio,
		"right_elbow_shoulder_y_ratio": right_elbow_shoulder_y_ratio,
		"left_arm_extension": float(measurements.get("left_arm_extension", 0.0)),
		"right_arm_extension": float(measurements.get("right_arm_extension", 0.0)),
		"left_elbow_bend_deg": float(measurements.get("left_elbow_bend_deg", 0.0)),
		"right_elbow_bend_deg": float(measurements.get("right_elbow_bend_deg", 0.0)),
		"calibration_width": 0.0,
		"calibration_height": 0.0,
	}
	var horizontal_ready := left_wrist_shoulder_y_ratio <= max_wrist_ratio and right_wrist_shoulder_y_ratio <= max_wrist_ratio and left_elbow_shoulder_y_ratio <= max_elbow_ratio and right_elbow_shoulder_y_ratio <= max_elbow_ratio
	readiness["horizontal_alignment_ready"] = horizontal_ready
	if not horizontal_ready:
		readiness["failure_reason"] = "arms_not_horizontal"
		readiness["instruction_key"] = "align_arms_horizontal"
		readiness["instruction_text"] = "Raise and level both arms into a T-pose"
		return readiness
	var min_elbow_angle_deg := _get_calibration_threshold("min_elbow_angle_deg", CALIBRATION_DEFAULT_MIN_ELBOW_ANGLE_DEG)
	var left_arm_extension := float(measurements.get("left_arm_extension", 0.0))
	var right_arm_extension := float(measurements.get("right_arm_extension", 0.0))
	var left_elbow_bend_deg := float(measurements.get("left_elbow_bend_deg", 0.0))
	var right_elbow_bend_deg := float(measurements.get("right_elbow_bend_deg", 0.0))
	var extension_ready := left_elbow_bend_deg >= min_elbow_angle_deg and right_elbow_bend_deg >= min_elbow_angle_deg
	readiness["arm_extension_ready"] = extension_ready
	if not extension_ready:
		readiness["failure_reason"] = "arms_not_extended"
		readiness["instruction_key"] = "extend_arms"
		readiness["instruction_text"] = "Straighten both elbows in the T-pose"
		return readiness
	readiness["qualified"] = true
	var last_fired_at_ms := int(_calibration_session.get("last_fired_at_ms", 0))
	var cooldown_remaining_ms := maxi((last_fired_at_ms + cooldown_ms) - runtime_timestamp_ms, 0) if last_fired_at_ms > 0 else 0
	readiness["cooldown_remaining_ms"] = cooldown_remaining_ms
	if cooldown_remaining_ms > 0:
		readiness["failure_reason"] = "cooldown_active"
		readiness["hold_started_at_ms"] = 0
		readiness["hold_progress_ms"] = 0
		readiness["hold_progress_ratio"] = 0.0
		readiness["instruction_key"] = "hold_t_pose"
		readiness["instruction_text"] = "Auto-calibration is cooling down — wait for unlock, then hold a fresh T-pose to re-fire"
		return readiness
	var hold_started_at_ms := int(_calibration_session.get("hold_started_at_ms", 0))
	if hold_started_at_ms <= 0 or (last_fired_at_ms > 0 and hold_started_at_ms <= last_fired_at_ms):
		hold_started_at_ms = runtime_timestamp_ms
	var hold_progress_ms := maxi(runtime_timestamp_ms - hold_started_at_ms, 0)
	readiness["hold_started_at_ms"] = hold_started_at_ms
	readiness["hold_progress_ms"] = hold_progress_ms
	readiness["hold_progress_ratio"] = clampf(float(hold_progress_ms) / maxf(float(hold_ms), 1.0), 0.0, 1.0)
	readiness["hold_ready"] = hold_progress_ms >= hold_ms
	if not bool(readiness.get("hold_ready", false)):
		readiness["instruction_key"] = "hold_t_pose"
		readiness["instruction_text"] = "Hold the T-pose steady to finish auto-calibration"
		return readiness
	var calibration_width := _compute_calibration_grid_width(left_wrist, right_wrist)
	var calibration_height := _compute_calibration_grid_height(calibration_width, _resolve_flow_grid_content_aspect_ratio(tracking_frame))
	var measurement_debug: Dictionary = readiness.get("measurements", {}) if readiness.get("measurements", {}) is Dictionary else {}
	measurement_debug["calibration_width"] = calibration_width
	measurement_debug["calibration_height"] = calibration_height
	readiness["measurements"] = measurement_debug
	if calibration_width <= 0.0 or calibration_height <= 0.0:
		readiness["failure_reason"] = "invalid_joint_chain_sample"
		readiness["instruction_key"] = "show_sample_landmarks"
		readiness["instruction_text"] = "Keep the full T-pose visible so the wrist span sample is measurable"
		return readiness
	readiness["ready"] = true
	readiness["failure_reason"] = ""
	readiness["instruction_key"] = "hold_t_pose"
	readiness["instruction_text"] = "T-pose hold satisfied — firing auto-calibration now"
	return readiness

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
	var debug_state := {
		"ready": _gesture_state.get("ready", {}).duplicate(true),
		"guard": _build_guard_debug_state(),
		"weave": _build_weave_debug_state(metrics),
		"punch_detection": _build_punch_detection_debug_state(),
		"straight_punch": _build_straight_punch_debug_state(metrics),
		"hook": _build_pose_strike_debug_state("hook", metrics),
		"uppercut": _build_pose_strike_debug_state("uppercut", metrics),
		"depth_runtime": _build_depth_runtime_debug_state(),
		"flow": _build_flow_debug_state(metrics),
	}
	if _supports_squat_surface():
		debug_state["squat"] = _build_squat_debug_state(metrics)
	return debug_state

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
		"threshold_enabled": _any_punch_family_uses_backend(BACKEND_THRESHOLD),
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

func _build_squat_debug_state(_metrics: Dictionary = {}) -> Dictionary:
	var squat_debug: Dictionary = (_gesture_state.get("squat_debug", {}) as Dictionary).duplicate(true)
	var squat_config := _get_squat_config()
	squat_debug["backend"] = _get_non_punch_backend_for_family("squat")
	squat_debug["state"] = bool(_get_state("squat"))
	squat_debug["enabled"] = bool(squat_config.get("enabled", true))
	squat_debug["calibration_ready"] = bool(_baseline.get("is_calibrated", false))
	squat_debug["calibration_sample_frames"] = int(_baseline.get("sample_frames", 0))
	return squat_debug

func _build_weave_debug_state(_metrics: Dictionary = {}) -> Dictionary:
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
	weave_debug["calibration_ready"] = bool(_baseline.get("is_calibrated", false))
	weave_debug["calibration_sample_frames"] = int(_baseline.get("sample_frames", 0))
	return weave_debug

func _truthful_straight_punch_debug_state_name(state: Dictionary, hand_tracking_enabled: bool, tracking_state: String) -> String:
	var state_name := String(state.get("phase", STRAIGHT_PUNCH_STATE_TRACKING_LOST))
	if hand_tracking_enabled:
		return state_name
	if state_name != STRAIGHT_PUNCH_STATE_TRACKING_LOST:
		return state_name
	if not bool(state.get("pose_tracking_valid", false)):
		return state_name
	return tracking_state if not tracking_state.is_empty() else state_name

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
	var hand_tracking_enabled := _straight_punch_uses_hand_tracking()
	var tracking_state := String(hand_payload.get("tracking_state", state.get("hand_tracking_state", "idle")))
	return {
		"backend": _get_punch_backend_for_family("straight_punch"),
		"phase": String(state.get("phase", STRAIGHT_PUNCH_STATE_TRACKING_LOST)),
		"state": String(state.get("phase", STRAIGHT_PUNCH_STATE_TRACKING_LOST)),
		"truthful_state": _truthful_straight_punch_debug_state_name(state, hand_tracking_enabled, tracking_state),
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
		"hand_tracking_enabled": hand_tracking_enabled,
		"pose_tracking_valid": bool(state.get("pose_tracking_valid", false)),
		"pose_reference_shoulder_width": float(state.get("pose_reference_shoulder_width", 0.0)),
		"pose_reference_shoulder_width_source": String(state.get("pose_reference_shoulder_width_source", "missing")),
		"fresh_sample": bool(state.get("last_sample_fresh", false)),
		"sample_source": String(hand_payload.get("sample_source", state.get("hand_sample_source", "none"))),
		"velocity_signal_source": String(state.get("velocity_signal_source", "wrist_only")),
		"tracking_valid": bool(hand_payload.get("tracking_valid", state.get("hand_tracking_valid", false))),
		"tracking_state": tracking_state,
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
		"pose_reference_shoulder_width": float(state.get("pose_reference_shoulder_width", 0.0)),
		"pose_reference_shoulder_width_source": String(state.get("pose_reference_shoulder_width_source", "missing")),
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
		"grid_transition_available": bool(state.get("grid_transition_available", false)),
		"grid_transition_fresh": bool(state.get("grid_transition_fresh", false)),
		"grid_previous_cell": int(state.get("grid_previous_cell", -1)),
		"grid_current_cell": int(state.get("grid_current_cell", -1)),
		"grid_previous_column": int(state.get("grid_previous_column", -1)),
		"grid_current_column": int(state.get("grid_current_column", -1)),
		"grid_previous_row": int(state.get("grid_previous_row", -1)),
		"grid_current_row": int(state.get("grid_current_row", -1)),
		"grid_column_delta": int(state.get("grid_column_delta", 0)),
		"grid_row_delta": int(state.get("grid_row_delta", 0)),
		"grid_direction_dominance_ratio": float(state.get("grid_direction_dominance_ratio", 0.0)),
		"grid_direction_gate_passed": bool(state.get("grid_direction_gate_passed", false)),
		"grid_cell_delta_gate_passed": bool(state.get("grid_cell_delta_gate_passed", false)),
	}
	if family == "hook":
		debug["outward_velocity"] = float(state.get("outward_velocity", 0.0))
		debug["outward_distance"] = float(state.get("outward_distance", 0.0))
		debug["wrist_angle_from_elbow_horizontal_deg"] = float(state.get("wrist_angle_from_elbow_horizontal_deg", 0.0))
		debug["max_wrist_angle_from_elbow_horizontal_deg"] = float(config.get("max_wrist_angle_from_elbow_horizontal_deg", HOOK_DEFAULT_MAX_WRIST_ANGLE_FROM_ELBOW_HORIZONTAL_DEG))
		debug["wrist_horizontal_angle_gate_passed"] = bool(state.get("wrist_horizontal_angle_gate_passed", false))
		debug["wrist_on_required_hook_side"] = bool(state.get("wrist_on_required_hook_side", false))
		debug["required_hook_side_label"] = _required_hook_side_label(side)
		if String(config.get("backend", BACKEND_THRESHOLD)) == BACKEND_GRID_DETECTION:
			debug["required_direction_label"] = "athlete_left" if side == "left" else "athlete_right"
			debug["direction_reference_frame"] = "athlete_space_columns"
		else:
			debug["required_direction_label"] = "rightward" if side == "left" else "leftward"
			debug["direction_reference_frame"] = "preview_space_horizontal"
	else:
		debug["upward_velocity"] = float(state.get("upward_velocity", 0.0))
		debug["wrist_angle_from_elbow_vertical_deg"] = float(state.get("wrist_angle_from_elbow_vertical_deg", 0.0))
		debug["max_wrist_angle_from_elbow_vertical_deg"] = float(config.get("max_wrist_angle_from_elbow_vertical_deg", UPPERCUT_DEFAULT_MAX_WRIST_ANGLE_FROM_ELBOW_VERTICAL_DEG))
		debug["wrist_vertical_angle_gate_passed"] = bool(state.get("wrist_vertical_angle_gate_passed", false))
		debug["wrist_above_elbow_gate_passed"] = bool(state.get("wrist_above_elbow_gate_passed", false))
		if String(config.get("backend", BACKEND_THRESHOLD)) == BACKEND_GRID_DETECTION:
			debug["required_direction_label"] = "athlete_up"
			debug["direction_reference_frame"] = "athlete_space_rows"
		else:
			debug["required_direction_label"] = "upward"
			debug["direction_reference_frame"] = "preview_space_vertical"
	return debug

func _build_flow_debug_state(_metrics: Dictionary = {}) -> Dictionary:
	return {
		"grid": _build_flow_grid_debug(),
		"tracked_landmarks": {
			"nose": _build_flow_nose_debug(),
			"left_wrist": _build_flow_side_debug("left"),
			"right_wrist": _build_flow_side_debug("right"),
		},
		"left": _build_flow_side_debug("left"),
		"right": _build_flow_side_debug("right"),
	}

func _build_flow_side_debug(side: String) -> Dictionary:
	var history_name := "%s_hand" % side
	var history: Array = _get_flow_history(history_name)
	var analysis := _analyze_flow_motion(side, FLOW_DIRECTION_WINDOW_MAX_MS)
	var latest_sample: Dictionary = history[history.size() - 1] if history.size() > 0 else {}
	var cell_meta: Dictionary = _get_flow_meta("flow_%s_cell" % side)
	var landmark_id := PoseLandmarkIds.LEFT_WRIST if side == "left" else PoseLandmarkIds.RIGHT_WRIST
	return _build_flow_landmark_debug(StringName("%s_wrist" % side), landmark_id, history, analysis, cell_meta, latest_sample)

func _build_flow_nose_debug() -> Dictionary:
	var history: Array = _get_flow_history("nose")
	var analysis := _analyze_flow_landmark_motion("nose", FLOW_DIRECTION_WINDOW_MAX_MS)
	var latest_sample: Dictionary = history[history.size() - 1] if history.size() > 0 else {}
	return _build_flow_landmark_debug(&"nose", PoseLandmarkIds.NOSE, history, analysis, {}, latest_sample)

func _build_flow_landmark_debug(landmark_key: StringName, landmark_id: int, history: Array, analysis: Dictionary, cell_meta: Dictionary = {}, latest_sample: Dictionary = {}) -> Dictionary:
	var grid_rect := _get_flow_grid_rect()
	return {
		"landmark_key": String(landmark_key),
		"landmark_id": landmark_id,
		"history_points": history.size(),
		"history_duration_ms": _flow_history_duration_ms(history),
		"latest_position": latest_sample.get("position", Vector2.ZERO),
		"latest_relative_position": latest_sample.get("relative_position", Vector2.ZERO),
		"latest_confidence": float(latest_sample.get("confidence", 0.0)),
		"current_cell": int(latest_sample.get("cell", -1)),
		"current_direction": int(analysis.get("direction", -1)),
		"grid_anchor": Vector2(float(grid_rect.get("anchor_x", 0.0)), float(grid_rect.get("anchor_y", 0.0))),
		"grid_cell_size": float(grid_rect.get("cell_width", 0.0)),
		"grid_cell_width": float(grid_rect.get("cell_width", 0.0)),
		"grid_cell_height": float(grid_rect.get("cell_height", 0.0)),
		"grid": _build_flow_grid_debug(),
		"direction_analysis": analysis.duplicate(true),
		"cell_meta": cell_meta.duplicate(true),
	}

func _build_flow_grid_debug() -> Dictionary:
	var grid_rect := _get_flow_grid_rect()
	var cell_width := float(grid_rect.get("cell_width", 0.0))
	var cell_height := float(grid_rect.get("cell_height", 0.0))
	var is_calibrated := bool(_baseline.get("is_calibrated", false)) and cell_width > 0.000001 and cell_height > 0.000001
	var columns := FLOW_GRID_COLUMNS
	var rows := FLOW_GRID_ROWS
	var left_boundary := float(grid_rect.get("left_boundary", 0.0))
	var top_boundary := float(grid_rect.get("top_boundary", 0.0))
	var right_boundary := float(grid_rect.get("right_boundary", 0.0))
	var bottom_boundary := float(grid_rect.get("bottom_boundary", 0.0))
	var anchor_x := float(grid_rect.get("anchor_x", 0.0))
	var anchor_y := float(grid_rect.get("anchor_y", 0.0))
	var cell_rects: Array = []
	if is_calibrated:
		for athlete_row: int in range(rows):
			var gameplay_row := (rows - 1) - athlete_row
			for preview_column: int in range(columns):
				var athlete_column := (columns - 1) - preview_column
				var cell_bottom := bottom_boundary + cell_height * float(gameplay_row)
				var cell_top := cell_bottom + cell_height
				cell_rects.append({
					"index": athlete_row * columns + athlete_column,
					"column": athlete_column,
					"preview_column": preview_column,
					"row": athlete_row,
					"gameplay_row": gameplay_row,
					"left": left_boundary + cell_width * float(preview_column),
					"right": left_boundary + cell_width * float(preview_column + 1),
					"top": cell_top,
					"bottom": cell_bottom,
				})
	return {
		"is_calibrated": is_calibrated,
		"columns": columns,
		"rows": rows,
		"cell_index_contract": "athlete_space_top_left",
		"coordinate_space": "gameplay_bottom_left",
		"anchor": Vector2(anchor_x, anchor_y),
		"cell_size": cell_width,
		"cell_width": cell_width,
		"cell_height": cell_height,
		"width": right_boundary - left_boundary,
		"height": top_boundary - bottom_boundary,
		"anchor_x": anchor_x,
		"wrist_midpoint_x": float(_baseline.get("wrist_midpoint_x", 0.0)),
		"anchor_y": anchor_y,
		"left_wrist_x": float(_baseline.get("left_wrist_x", 0.0)),
		"right_wrist_x": float(_baseline.get("right_wrist_x", 0.0)),
		"grid_width": float(_baseline.get("grid_width", _baseline.get("horizontal_wrist_span", 0.0))),
		"grid_height": float(_baseline.get("grid_height", 0.0)),
		"grid_content_aspect_ratio": float(_baseline.get("grid_content_aspect_ratio", FLOW_GRID_SOURCE_ASPECT_RATIO)),
		"horizontal_wrist_span": float(_baseline.get("horizontal_wrist_span", 0.0)),
		"left_boundary": left_boundary,
		"top_boundary": top_boundary,
		"right_boundary": right_boundary,
		"bottom_boundary": bottom_boundary,
		"cell_rects": cell_rects,
	}

func _get_flow_grid_rect() -> Dictionary:
	var cell_width := _get_flow_cell_width()
	var cell_height := _get_flow_cell_height(cell_width)
	var grid_width := float(_baseline.get("grid_width", _baseline.get("horizontal_wrist_span", 0.0)))
	var anchor_x := float(_baseline.get("nose_x", 0.0))
	var left_boundary := anchor_x - grid_width * 0.5
	var right_boundary := anchor_x + grid_width * 0.5
	var anchor_y := float(_baseline.get("left_shoulder_y", _baseline.get("shoulder_center_y", 0.0))) + _get_calibration_camera_space_grid_height_offset()
	var top_boundary := anchor_y + cell_height * 1.5
	var bottom_boundary := top_boundary - cell_height * float(FLOW_GRID_ROWS)
	return {
		"cell_width": cell_width,
		"cell_height": cell_height,
		"left_boundary": left_boundary,
		"right_boundary": right_boundary,
		"top_boundary": top_boundary,
		"bottom_boundary": bottom_boundary,
		"anchor_x": anchor_x,
		"anchor_y": anchor_y,
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
		},
		"ready": {
			"punch_left": false,
			"punch_right": false,
			"hook_left": true,
			"hook_right": true,
			"uppercut_left": true,
			"uppercut_right": true,
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
			"nose": [],
			"left_hand": [],
			"right_hand": [],
			"flow_left_cell": {"current_cell": -1, "last_emit_ms": 0, "direction": -1},
			"flow_right_cell": {"current_cell": -1, "last_emit_ms": 0, "direction": -1},
		},
	}

func _should_evaluate_gestures_this_frame() -> bool:
	var interval := 1
	if _config != null:
		interval = maxi(1, int(_config.gesture_eval_interval_frames))
	return _frame_index % interval == 0

func _clear_transient_gesture_state(preserve_flow: bool = false) -> void:
	var flow_state: Dictionary = {}
	if preserve_flow:
		flow_state = (_gesture_state.get("flow", {}) as Dictionary).duplicate(true)
	_reset_gesture_state()
	if preserve_flow:
		_gesture_state["flow"] = flow_state

func _advance_session_runtime_timestamp(timestamp_ms: int, source_timestamp_rewound: bool) -> int:
	if _session_runtime_timestamp_ms <= 0:
		_session_runtime_timestamp_ms = timestamp_ms
		_last_session_source_timestamp_ms = timestamp_ms
		_last_session_runtime_step_ms = 0
		return _session_runtime_timestamp_ms
	var runtime_step_ms := 0
	if not source_timestamp_rewound and _last_session_source_timestamp_ms > 0:
		var source_step_ms := timestamp_ms - _last_session_source_timestamp_ms
		if source_step_ms > 0:
			runtime_step_ms = source_step_ms
	if runtime_step_ms <= 0:
		runtime_step_ms = maxi(_last_session_runtime_step_ms, 16)
	_session_runtime_timestamp_ms += runtime_step_ms
	_last_session_source_timestamp_ms = timestamp_ms
	_last_session_runtime_step_ms = runtime_step_ms
	return _session_runtime_timestamp_ms

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
	var torso_confidence := float(confidences.get("torso", 0.0))
	var lower_body_confidence_gate := maxf(_get_min_visibility(), 0.5)

	_process_guard(events, nose, left_shoulder, right_shoulder, left_elbow, right_elbow, left_wrist, right_wrist, shoulder_width)
	if _supports_squat_surface() and torso_confidence >= lower_body_confidence_gate:
		_process_squat(events, nose)
	_process_weave(events, nose)
	if _get_punch_backend_for_family("straight_punch") == BACKEND_THRESHOLD:
		_process_straight_punch(events, "left", left_shoulder, left_elbow, left_wrist, measurements, shoulder_width, timestamp_ms, tracking_frame)
		_process_straight_punch(events, "right", right_shoulder, right_elbow, right_wrist, measurements, shoulder_width, timestamp_ms, tracking_frame)
	if _get_punch_backend_for_family("hook") != BACKEND_DISABLED:
		_process_hook(events, "left", left_shoulder, left_elbow, left_wrist, float(measurements.get("left_elbow_bend_deg", 0.0)), shoulder_width, timestamp_ms, tracking_frame)
		_process_hook(events, "right", right_shoulder, right_elbow, right_wrist, float(measurements.get("right_elbow_bend_deg", 0.0)), shoulder_width, timestamp_ms, tracking_frame)
	if _get_punch_backend_for_family("uppercut") != BACKEND_DISABLED:
		_process_uppercut(events, "left", left_shoulder, left_elbow, left_wrist, float(measurements.get("left_elbow_bend_deg", 0.0)), shoulder_width, timestamp_ms, tracking_frame)
		_process_uppercut(events, "right", right_shoulder, right_elbow, right_wrist, float(measurements.get("right_elbow_bend_deg", 0.0)), shoulder_width, timestamp_ms, tracking_frame)
	if not _has_any_event(events, ["punch_left", "hook_left", "uppercut_left"]):
		_process_flow_cell_entry(events, "left", timestamp_ms)
	if not _has_any_event(events, ["punch_right", "hook_right", "uppercut_right"]):
		_process_flow_cell_entry(events, "right", timestamp_ms)
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
	var pose_reference_shoulder_width := _resolve_pose_reference_shoulder_width(shoulder_width)
	var pose_tracking_valid := _is_pose_valid_for_straight_punch(shoulder, wrist, pose_reference_shoulder_width)
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
	state["pose_reference_shoulder_width"] = pose_reference_shoulder_width
	state["pose_reference_shoulder_width_source"] = _pose_reference_shoulder_width_source(shoulder_width, pose_reference_shoulder_width)
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
	var backend_name := String(config.get("backend", BACKEND_THRESHOLD))
	var pose_reference_shoulder_width := _resolve_pose_reference_shoulder_width(shoulder_width)
	var pose_tracking_valid := _is_pose_valid_for_pose_strike(shoulder, elbow, wrist, pose_reference_shoulder_width)
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
	var grid_transition := _build_pose_strike_grid_transition(side, timestamp_ms)
	var grid_transition_available := not grid_transition.is_empty()
	var grid_previous_cell := int(grid_transition.get("previous_cell", -1))
	var grid_current_cell := int(grid_transition.get("current_cell", -1))
	var grid_previous_column := int(grid_transition.get("previous_column", -1))
	var grid_current_column := int(grid_transition.get("current_column", -1))
	var grid_previous_row := int(grid_transition.get("previous_row", -1))
	var grid_current_row := int(grid_transition.get("current_row", -1))
	var grid_column_delta := int(grid_transition.get("column_delta", 0))
	var grid_row_delta := int(grid_transition.get("row_delta", 0))
	var grid_direction_dominance_ratio := _compute_direction_dominance_ratio(lateral_speed, vertical_speed) if family == "hook" else _compute_direction_dominance_ratio(vertical_speed, lateral_speed)
	state["last_wrist_velocity"] = speed
	state["last_wrist_velocity_vector"] = motion_window.get("averaged_velocity_vector", velocity_vector)
	state["last_lateral_velocity"] = lateral_speed
	state["last_vertical_velocity"] = vertical_speed
	state["last_sample_fresh"] = fresh_sample
	state["pose_tracking_valid"] = pose_tracking_valid
	state["pose_reference_shoulder_width"] = pose_reference_shoulder_width
	state["pose_reference_shoulder_width_source"] = _pose_reference_shoulder_width_source(shoulder_width, pose_reference_shoulder_width)
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
	state["grid_transition_available"] = grid_transition_available
	state["grid_transition_fresh"] = grid_transition_available
	state["grid_previous_cell"] = grid_previous_cell
	state["grid_current_cell"] = grid_current_cell
	state["grid_previous_column"] = grid_previous_column
	state["grid_current_column"] = grid_current_column
	state["grid_previous_row"] = grid_previous_row
	state["grid_current_row"] = grid_current_row
	state["grid_column_delta"] = grid_column_delta
	state["grid_row_delta"] = grid_row_delta
	state["grid_direction_dominance_ratio"] = grid_direction_dominance_ratio
	state["grid_direction_gate_passed"] = false
	state["grid_cell_delta_gate_passed"] = false
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
		if backend_name == BACKEND_GRID_DETECTION:
			var min_cell_delta := max(1, int(config.get("min_cell_delta", GRID_DETECTION_DEFAULT_MIN_CELL_DELTA)))
			var dominance_requirement := clampf(float(config.get("direction_dominance_ratio", GRID_DETECTION_DEFAULT_DIRECTION_DOMINANCE_RATIO)), 0.0, 1.0)
			state["grid_cell_delta_gate_passed"] = absi(grid_column_delta if family == "hook" else grid_row_delta) >= min_cell_delta
			state["grid_direction_gate_passed"] = grid_direction_dominance_ratio >= dominance_requirement
			if family == "hook":
				var direction_ok := grid_column_delta < 0 if side == "left" else grid_column_delta > 0
				ready_to_trigger = grid_transition_available and state["grid_cell_delta_gate_passed"] and state["grid_direction_gate_passed"] and direction_ok
			else:
				var direction_ok := grid_row_delta < 0
				ready_to_trigger = grid_transition_available and state["grid_cell_delta_gate_passed"] and state["grid_direction_gate_passed"] and direction_ok
		else:
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

func _process_flow_cell_entry(events: Array, side: String, timestamp_ms: int) -> void:
	var history: Array = _get_flow_history("%s_hand" % side)
	if history.is_empty():
		return
	var latest_sample: Dictionary = history[history.size() - 1]
	var current_cell := int(latest_sample.get("cell", -1))
	var meta_name := "flow_%s_cell" % side
	var flow_meta: Dictionary = _get_flow_meta(meta_name)
	var previous_cell := int(flow_meta.get("current_cell", -1))
	flow_meta["current_cell"] = current_cell
	if current_cell < 0:
		_set_flow_meta(meta_name, flow_meta)
		return
	if previous_cell < 0:
		flow_meta["entered_at_ms"] = timestamp_ms
		_set_flow_meta(meta_name, flow_meta)
		return
	if current_cell == previous_cell:
		_set_flow_meta(meta_name, flow_meta)
		return
	var analysis := _analyze_flow_motion(side, FLOW_DIRECTION_WINDOW_MAX_MS)
	var direction := int(analysis.get("direction", -1))
	flow_meta["previous_cell"] = previous_cell
	flow_meta["current_cell"] = current_cell
	flow_meta["last_emit_ms"] = timestamp_ms
	flow_meta["entered_at_ms"] = timestamp_ms
	flow_meta["direction"] = direction
	flow_meta["duration_ms"] = int(analysis.get("duration_ms", 0))
	flow_meta["net_distance"] = float(analysis.get("net_distance", 0.0))
	flow_meta["avg_confidence"] = float(analysis.get("avg_confidence", 0.0))
	_set_flow_meta(meta_name, flow_meta)
	_emit_flow_cell_event(events, side, current_cell, direction)

func _update_flow_tracking_state(landmarks_by_id: Dictionary, metrics: Dictionary, timestamp_ms: int) -> void:
	if not bool(_baseline.get("is_calibrated", false)):
		return
	var measurements: Dictionary = metrics.get("measurements", {})
	var shoulder_center_vec: Vector3 = measurements.get("shoulder_center", Vector3(float(_baseline.get("shoulder_center_x", 0.0)), 0.0, 0.0))
	var shoulder_center := Vector2(shoulder_center_vec.x, shoulder_center_vec.y)
	var confidences: Dictionary = metrics.get("confidences", {})
	var nose := PoseMetrics.get_landmark(landmarks_by_id, PoseLandmarkIds.NOSE)
	var left_shoulder := PoseMetrics.get_landmark(landmarks_by_id, PoseLandmarkIds.LEFT_SHOULDER)
	var right_shoulder := PoseMetrics.get_landmark(landmarks_by_id, PoseLandmarkIds.RIGHT_SHOULDER)
	var left_wrist := PoseMetrics.get_landmark(landmarks_by_id, PoseLandmarkIds.LEFT_WRIST)
	var right_wrist := PoseMetrics.get_landmark(landmarks_by_id, PoseLandmarkIds.RIGHT_WRIST)
	_update_flow_nose_history(nose, shoulder_center, float(confidences.get("head", 0.0)), timestamp_ms)
	_update_flow_hand_history("left", left_wrist, left_shoulder, float(confidences.get("left_hand", 0.0)), timestamp_ms)
	_update_flow_hand_history("right", right_wrist, right_shoulder, float(confidences.get("right_hand", 0.0)), timestamp_ms)

func _update_flow_nose_history(nose: Dictionary, _shoulder_center: Vector2, confidence: float, timestamp_ms: int) -> void:
	_update_flow_landmark_history("nose", nose, Vector2.ZERO, confidence, timestamp_ms)

func _update_flow_hand_history(side: String, wrist: Dictionary, shoulder: Dictionary, confidence: float, timestamp_ms: int) -> void:
	_update_flow_landmark_history("%s_hand" % side, wrist, PoseMetrics.to_vector2(shoulder), confidence, timestamp_ms)

func _update_flow_landmark_history(history_name: String, landmark: Dictionary, reference_position: Vector2, confidence: float, timestamp_ms: int) -> void:
	var history: Array = _get_flow_history(history_name)
	if landmark.is_empty() or confidence < 0.35:
		history.clear()
		_set_flow_history(history_name, history)
		return
	var position := PoseMetrics.to_vector2(landmark)
	var relative_position := position - reference_position
	history.append({
		"timestamp_ms": timestamp_ms,
		"position": position,
		"relative_position": relative_position,
		"confidence": confidence,
		"cell": _flow_cell_index_from_position(position),
	})
	while history.size() > 0 and timestamp_ms - int(history[0].get("timestamp_ms", timestamp_ms)) > FLOW_HISTORY_MAX_MS:
		history.remove_at(0)
	_set_flow_history(history_name, history)

func _analyze_flow_motion(side: String, max_window_ms: int) -> Dictionary:
	return _analyze_flow_landmark_motion("%s_hand" % side, max_window_ms)

func _analyze_flow_landmark_motion(history_name: String, max_window_ms: int) -> Dictionary:
	var history: Array = _get_flow_history(history_name)
	if history.size() < 2:
		return {}
	var latest_timestamp := int(history[history.size() - 1].get("timestamp_ms", 0))
	var samples: Array = []
	for sample_variant: Variant in history:
		if not sample_variant is Dictionary:
			continue
		var sample: Dictionary = sample_variant
		if latest_timestamp - int(sample.get("timestamp_ms", latest_timestamp)) <= max_window_ms:
			samples.append(sample)
	if samples.size() < 2:
		return {}
	var first: Dictionary = samples[0]
	var last: Dictionary = samples[samples.size() - 1]
	var first_pos: Vector2 = first.get("relative_position", Vector2.ZERO)
	var last_pos: Vector2 = last.get("relative_position", Vector2.ZERO)
	var net_delta := last_pos - first_pos
	var confidence_total := 0.0
	for sample_variant: Variant in samples:
		var sample: Dictionary = sample_variant
		confidence_total += float(sample.get("confidence", 0.0))
	var duration_ms := maxi(int(last.get("timestamp_ms", 0)) - int(first.get("timestamp_ms", 0)), 0)
	var direction := -1
	var cell_size := _get_flow_cell_size()
	if duration_ms >= FLOW_DIRECTION_WINDOW_MIN_MS and net_delta.length() >= cell_size * FLOW_DIRECTION_MIN_TRAVEL_CELL_RATIO:
		direction = _flow_direction_index_from_vector(net_delta)
	return {
		"duration_ms": duration_ms,
		"sample_count": samples.size(),
		"net_distance": net_delta.length(),
		"net_delta": net_delta,
		"avg_confidence": confidence_total / float(samples.size()),
		"direction": direction,
		"latest_position": last.get("position", Vector2.ZERO),
		"latest_relative_position": last_pos,
	}

func _get_flow_cell_width() -> float:
	var grid_width := float(_baseline.get("grid_width", _baseline.get("horizontal_wrist_span", 0.0)))
	if grid_width <= 0.0:
		return 0.0
	return grid_width / float(FLOW_GRID_COLUMNS)

func _get_flow_cell_height(cell_width: float = -1.0) -> float:
	if cell_width <= 0.0:
		cell_width = _get_flow_cell_width()
	if cell_width <= 0.0:
		return 0.0
	var stored_grid_height := float(_baseline.get("grid_height", 0.0))
	if stored_grid_height > 0.0:
		return stored_grid_height / float(FLOW_GRID_ROWS)
	var grid_content_aspect_ratio := float(_baseline.get("grid_content_aspect_ratio", FLOW_GRID_SOURCE_ASPECT_RATIO))
	return cell_width * _sanitize_flow_grid_content_aspect_ratio(grid_content_aspect_ratio)

func _get_flow_cell_size() -> float:
	return _get_flow_cell_width()

func _flow_cell_index_from_position(position: Vector2) -> int:
	var grid_rect := _get_flow_grid_rect()
	var cell_width := float(grid_rect.get("cell_width", 0.0))
	var cell_height := float(grid_rect.get("cell_height", 0.0))
	if cell_width <= 0.000001 or cell_height <= 0.000001:
		return -1
	var left_boundary := float(grid_rect.get("left_boundary", 0.0))
	var relative_x := position.x - left_boundary
	if relative_x < 0.0 or relative_x >= cell_width * float(FLOW_GRID_COLUMNS):
		return -1
	var bottom_boundary := float(grid_rect.get("bottom_boundary", 0.0))
	var relative_y := position.y - bottom_boundary
	if relative_y < 0.0 or relative_y >= cell_height * float(FLOW_GRID_ROWS):
		return -1
	var preview_column := int(floor(relative_x / cell_width))
	var gameplay_row := int(floor(relative_y / cell_height))
	if preview_column < 0 or preview_column >= FLOW_GRID_COLUMNS or gameplay_row < 0 or gameplay_row >= FLOW_GRID_ROWS:
		return -1
	var athlete_row := (FLOW_GRID_ROWS - 1) - gameplay_row
	var athlete_column := (FLOW_GRID_COLUMNS - 1) - preview_column
	return athlete_row * FLOW_GRID_COLUMNS + athlete_column

func _flow_direction_index_from_vector(vector: Vector2) -> int:
	if vector.length() <= 0.000001:
		return -1
	var angle_deg := fposmod(rad_to_deg(atan2(vector.y, vector.x)), 360.0)
	if angle_deg >= 67.5 and angle_deg < 112.5:
		return 0
	if angle_deg >= 247.5 and angle_deg < 292.5:
		return 1
	if angle_deg >= 157.5 and angle_deg < 202.5:
		return 2
	if angle_deg < 22.5 or angle_deg >= 337.5:
		return 3
	if angle_deg >= 112.5 and angle_deg < 157.5:
		return 4
	if angle_deg >= 22.5 and angle_deg < 67.5:
		return 5
	if angle_deg >= 202.5 and angle_deg < 247.5:
		return 6
	return 7

func _emit_flow_cell_event(events: Array, side: String, cell: int, direction: int) -> void:
	events.append({
		"name": StringName("flow_%s_cell_entered" % side),
		"cell": cell,
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

func _process_squat(events: Array, nose: Dictionary) -> void:
	var squat_config := _get_squat_config()
	var squat_debug := _build_grid_avoidance_debug_payload(nose, squat_config.get("obstacle", {}), "squat")
	squat_debug["state"] = bool(squat_debug.get("avoidance_clear", false))
	squat_debug["enabled"] = bool(squat_config.get("enabled", true))
	_gesture_state["squat_debug"] = squat_debug
	if not bool(squat_config.get("enabled", true)):
		_set_state_toggle(events, "squat", false)
		return
	_set_state_toggle(events, "squat", bool(squat_debug.get("avoidance_clear", false)))

func _process_weave(events: Array, nose: Dictionary) -> void:
	var weave_config := _get_weave_config()
	var left_debug := _build_grid_avoidance_debug_payload(nose, weave_config.get("left_obstacle", {}), "left")
	var right_debug := _build_grid_avoidance_debug_payload(nose, weave_config.get("right_obstacle", {}), "right")
	var current_cell := int(left_debug.get("current_cell", -1))
	var current_column := _flow_cell_column(current_cell)
	var nose_inside_grid := bool(left_debug.get("nose_tracked", false)) and bool(left_debug.get("grid_ready", false)) and current_column >= 0
	var weaving_left := nose_inside_grid and current_column <= 1
	var weaving_right := nose_inside_grid and current_column >= 2
	var weave_state := "inactive"
	if weaving_left:
		weave_state = "left"
	elif weaving_right:
		weave_state = "right"
	_gesture_state["weave_debug"] = {
		"state": weave_state,
		"enabled": bool(weave_config.get("enabled", true)),
		"current_cell": current_cell,
		"current_column": current_column,
		"current_direction": int(left_debug.get("current_direction", -1)),
		"nose_position": left_debug.get("nose_position", Vector2.ZERO),
		"nose_tracked": bool(left_debug.get("nose_tracked", false)),
		"nose_inside_grid": nose_inside_grid,
		"grid_ready": bool(left_debug.get("grid_ready", false)),
		"calibration_ready": bool(left_debug.get("calibration_ready", false)),
		"left_obstacle": left_debug,
		"right_obstacle": right_debug,
		"left_candidate": weaving_left,
		"right_candidate": weaving_right,
		"neutral_candidate": not nose_inside_grid,
		"left_avoidance_clear": bool(left_debug.get("avoidance_clear", false)),
		"right_avoidance_clear": bool(right_debug.get("avoidance_clear", false)),
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

func _set_state_toggle(events: Array, state_name: String, active: bool) -> void:
	if _get_state(state_name) == active:
		return
	_gesture_state["states"][state_name] = active
	var suffix := "start" if active else "end"
	events.append({"name": StringName("%s_%s" % [state_name, suffix])})

func _build_public_gesture_states() -> Dictionary:
	var public_states := (_gesture_state.get("states", {}) as Dictionary).duplicate(true)
	if not _supports_squat_surface():
		public_states.erase("squat")
	return public_states

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
	var sample_request := _build_depth_sample_request(family, side, timestamp_ms, shoulder, elbow, wrist, config, depth_config)
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

func _build_depth_sample_request(family: String, side: String, timestamp_ms: int, shoulder: Dictionary, elbow: Dictionary, wrist: Dictionary, config: Dictionary, depth_config: Dictionary) -> Dictionary:
	var request := {
		"family": family,
		"side": side,
		"timestamp_ms": timestamp_ms,
		"window_ms": int(config.get("window_ms", POSE_STRIKE_DEFAULT_WINDOW_MS)),
		"evaluation": (depth_config.get("evaluation", {}) as Dictionary).duplicate(true) if depth_config.get("evaluation", {}) is Dictionary else {},
		"shoulder": shoulder.duplicate(true),
		"elbow": elbow.duplicate(true),
		"wrist": wrist.duplicate(true),
	}
	if _depth_runtime_debug_texture_requested():
		request["debug_texture_requested"] = true
	return request

func _depth_runtime_debug_texture_requested() -> bool:
	if _config == null or not _config.has_method("get"):
		return false
	var runtime_config: Variant = _config.get("runtime")
	if not runtime_config is Dictionary:
		return false
	var depth_debug: Dictionary = (runtime_config as Dictionary).get("depth_debug", {}) if (runtime_config as Dictionary).get("depth_debug", {}) is Dictionary else {}
	return bool(depth_debug.get("request_runtime_texture", false))

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
		"pose_reference_shoulder_width": 0.0,
		"pose_reference_shoulder_width_source": "missing",
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
		"grid_transition_available": false,
		"grid_transition_fresh": false,
		"grid_previous_cell": -1,
		"grid_current_cell": -1,
		"grid_previous_column": -1,
		"grid_current_column": -1,
		"grid_previous_row": -1,
		"grid_current_row": -1,
		"grid_column_delta": 0,
		"grid_row_delta": 0,
		"grid_direction_dominance_ratio": 0.0,
		"grid_direction_gate_passed": false,
		"grid_cell_delta_gate_passed": false,
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

func _get_active_profile_id() -> String:
	if _config != null:
		if _config.has_method("get_selected_profile_id"):
			var selected_profile := String(_config.get_selected_profile_id()).strip_edges().to_lower()
			if selected_profile == "flow":
				return "flow"
		if _config.has_method("get"):
			var configured_profile := String(_config.get("profile")).strip_edges().to_lower()
			if configured_profile == "flow":
				return "flow"
	var gesture_profile_document := _get_gesture_profile_document()
	var gesture_profile := String(gesture_profile_document.get("profile", "")).strip_edges().to_lower()
	if gesture_profile == "flow":
		return "flow"
	return "boxing"

func _supports_squat_surface() -> bool:
	return _get_active_profile_id() != "flow"

func _get_non_punch_backend_for_family(family: String) -> String:
	var family_document := _get_family_document(family)
	var backend := String(family_document.get("backend", "")).strip_edges()
	if backend == "":
		return BACKEND_THRESHOLD
	return _normalize_non_punch_backend_name(backend)

func _threshold_gates_enabled() -> bool:
	return _any_punch_family_uses_backend(BACKEND_THRESHOLD)

func _selected_punch_detection_backend_enabled() -> bool:
	return _any_punch_family_uses_backend(BACKEND_THRESHOLD) or _any_punch_family_uses_backend(BACKEND_GRID_DETECTION)

func _any_punch_family_uses_backend(backend_name: String) -> bool:
	for family in PUNCH_FAMILIES:
		if _get_punch_backend_for_family(String(family)) == backend_name:
			return true
	return false

func _get_active_punch_detection_backend() -> String:
	return "per_family" if _selected_punch_detection_backend_enabled() else "none"

func _get_punch_backend_resolution_reason() -> String:
	return "per_family_active" if _selected_punch_detection_backend_enabled() else "no_active_family_backend"

func _normalize_punch_backend_name(backend_name: String) -> String:
	match backend_name.strip_edges().to_lower().replace("-", "_"):
		BACKEND_DISABLED:
			return BACKEND_DISABLED
		BACKEND_THRESHOLD:
			return BACKEND_THRESHOLD
		BACKEND_GRID_DETECTION:
			return BACKEND_GRID_DETECTION
		_:
			return BACKEND_THRESHOLD

func _normalize_non_punch_backend_name(backend_name: String) -> String:
	match backend_name.strip_edges().to_lower():
		BACKEND_DISABLED:
			return BACKEND_DISABLED
		BACKEND_THRESHOLD:
			return BACKEND_THRESHOLD
		BACKEND_GRID_AVOIDANCE:
			return BACKEND_GRID_AVOIDANCE
		_:
			return BACKEND_THRESHOLD

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
		"obstacle": _normalize_grid_avoidance_obstacle({
			"label": "top_row",
			"occupied_rows": [0],
			"occupied_cells": [0, 1, 2, 3],
		}),
	}
	if _config == null:
		return config
	var squat: Dictionary = _get_family_backend_document("squat", _get_non_punch_backend_for_family("squat"))
	config["enabled"] = _get_non_punch_backend_for_family("squat") != BACKEND_DISABLED and bool(squat.get("enabled", config.get("enabled", true)))
	var obstacle: Dictionary = squat.get("obstacle", {}) if squat.get("obstacle", {}) is Dictionary else {}
	config["obstacle"] = _normalize_grid_avoidance_obstacle(obstacle, config.get("obstacle", {}))
	return config

func _get_weave_config() -> Dictionary:
	var config := {
		"enabled": true,
		"left_obstacle": _normalize_grid_avoidance_obstacle({
			"label": "left_columns",
			"occupied_columns": [0, 1],
			"occupied_cells": [0, 1, 4, 5, 8, 9],
		}),
		"right_obstacle": _normalize_grid_avoidance_obstacle({
			"label": "right_columns",
			"occupied_columns": [2, 3],
			"occupied_cells": [2, 3, 6, 7, 10, 11],
		}),
	}
	if _config == null:
		return config
	var weave: Dictionary = _get_family_backend_document("weave", _get_non_punch_backend_for_family("weave"))
	config["enabled"] = _get_non_punch_backend_for_family("weave") != BACKEND_DISABLED and bool(weave.get("enabled", config.get("enabled", true)))
	var left_obstacle: Dictionary = weave.get("left_obstacle", {}) if weave.get("left_obstacle", {}) is Dictionary else {}
	var right_obstacle: Dictionary = weave.get("right_obstacle", {}) if weave.get("right_obstacle", {}) is Dictionary else {}
	config["left_obstacle"] = _normalize_grid_avoidance_obstacle(left_obstacle, config.get("left_obstacle", {}))
	config["right_obstacle"] = _normalize_grid_avoidance_obstacle(right_obstacle, config.get("right_obstacle", {}))
	return config

func _normalize_grid_avoidance_obstacle(obstacle: Dictionary, fallback: Dictionary = {}) -> Dictionary:
	var merged: Dictionary = fallback.duplicate(true)
	for key_variant: Variant in obstacle.keys():
		merged[key_variant] = obstacle[key_variant]
	var columns := _unique_sorted_int_array(merged.get("occupied_columns", []))
	var rows := _unique_sorted_int_array(merged.get("occupied_rows", []))
	var cells := _unique_sorted_int_array(merged.get("occupied_cells", []))
	if cells.is_empty():
		for row: int in rows:
			for column: int in range(FLOW_GRID_COLUMNS):
				if row >= 0 and row < FLOW_GRID_ROWS:
					cells.append(row * FLOW_GRID_COLUMNS + column)
		for column: int in columns:
			if column < 0 or column >= FLOW_GRID_COLUMNS:
				continue
			for row: int in range(FLOW_GRID_ROWS):
				cells.append(row * FLOW_GRID_COLUMNS + column)
		cells = _unique_sorted_int_array(cells)
	merged["label"] = String(merged.get("label", "grid_obstacle"))
	merged["occupied_columns"] = columns
	merged["occupied_rows"] = rows
	merged["occupied_cells"] = cells
	return merged

func _unique_sorted_int_array(values_variant: Variant) -> Array[int]:
	var unique := {}
	var ordered: Array[int] = []
	if values_variant is Array:
		for value_variant: Variant in values_variant:
			var value := int(value_variant)
			if unique.has(value):
				continue
			unique[value] = true
			ordered.append(value)
	ordered.sort()
	return ordered

func _build_grid_avoidance_debug_payload(nose: Dictionary, obstacle: Dictionary, state_label: String) -> Dictionary:
	var grid: Dictionary = _build_flow_grid_debug()
	var nose_position := Vector2(float(nose.get("x", 0.0)), float(nose.get("y", 0.0)))
	var current_cell := _flow_cell_index_from_position(nose_position) if not nose.is_empty() else -1
	var blocked_cells: Array[int] = _unique_sorted_int_array(obstacle.get("occupied_cells", []))
	var blocked_columns: Array[int] = _unique_sorted_int_array(obstacle.get("occupied_columns", []))
	var blocked_rows: Array[int] = _unique_sorted_int_array(obstacle.get("occupied_rows", []))
	var nose_in_blocked_region := false
	var cell_rects_variant: Variant = grid.get("cell_rects", [])
	if cell_rects_variant is Array and not nose.is_empty():
		for rect_variant: Variant in cell_rects_variant:
			var rect: Dictionary = rect_variant as Dictionary
			if not blocked_cells.has(int(rect.get("index", -1))):
				continue
			var left := float(rect.get("left", 0.0))
			var right := float(rect.get("right", 0.0))
			var top := float(rect.get("top", 0.0))
			var bottom := float(rect.get("bottom", 0.0))
			if nose_position.x >= left and nose_position.x < right and nose_position.y <= top and nose_position.y > bottom:
				nose_in_blocked_region = true
				break
	return {
		"backend": BACKEND_GRID_AVOIDANCE,
		"state_label": state_label,
		"label": String(obstacle.get("label", state_label)),
		"occupied_columns": blocked_columns,
		"occupied_rows": blocked_rows,
		"occupied_cells": blocked_cells,
		"nose_position": nose_position,
		"nose_tracked": not nose.is_empty(),
		"current_cell": current_cell,
		"current_direction": int(_build_flow_nose_debug().get("current_direction", -1)),
		"grid_ready": bool(grid.get("is_calibrated", false)),
		"calibration_ready": bool(_baseline.get("is_calibrated", false)),
		"nose_in_blocked_region": nose_in_blocked_region,
		"avoidance_clear": not nose.is_empty() and bool(grid.get("is_calibrated", false)) and not nose_in_blocked_region,
	}

func _flow_cell_row(cell: int) -> int:
	if cell < 0 or cell >= FLOW_GRID_COLUMNS * FLOW_GRID_ROWS:
		return -1
	return int(floor(cell / FLOW_GRID_COLUMNS))

func _flow_cell_column(cell: int) -> int:
	if cell < 0 or cell >= FLOW_GRID_COLUMNS * FLOW_GRID_ROWS:
		return -1
	return cell % FLOW_GRID_COLUMNS

func _build_pose_strike_grid_transition(side: String, timestamp_ms: int) -> Dictionary:
	var history: Array = _get_flow_history("%s_hand" % side)
	if history.size() < 2:
		return {}
	var latest: Dictionary = history[history.size() - 1]
	if int(latest.get("timestamp_ms", -1)) != timestamp_ms:
		return {}
	var previous: Dictionary = history[history.size() - 2]
	var previous_cell := int(previous.get("cell", -1))
	var current_cell := int(latest.get("cell", -1))
	if previous_cell < 0 or current_cell < 0 or previous_cell == current_cell:
		return {}
	var previous_column := _flow_cell_column(previous_cell)
	var current_column := _flow_cell_column(current_cell)
	var previous_row := _flow_cell_row(previous_cell)
	var current_row := _flow_cell_row(current_cell)
	if previous_column < 0 or current_column < 0 or previous_row < 0 or current_row < 0:
		return {}
	return {
		"previous_cell": previous_cell,
		"current_cell": current_cell,
		"previous_column": previous_column,
		"current_column": current_column,
		"previous_row": previous_row,
		"current_row": current_row,
		"column_delta": current_column - previous_column,
		"row_delta": current_row - previous_row,
	}

func _compute_direction_dominance_ratio(dominant_axis: float, other_axis: float) -> float:
	var dominant := absf(dominant_axis)
	var other := absf(other_axis)
	var total := dominant + other
	if total <= 0.000001:
		return 0.0
	return dominant / total

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
		"pose_reference_shoulder_width": 0.0,
		"pose_reference_shoulder_width_source": "missing",
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
		"grid_transition_available": false,
		"grid_transition_fresh": false,
		"grid_previous_cell": -1,
		"grid_current_cell": -1,
		"grid_previous_column": -1,
		"grid_current_column": -1,
		"grid_previous_row": -1,
		"grid_current_row": -1,
		"grid_column_delta": 0,
		"grid_row_delta": 0,
		"grid_direction_dominance_ratio": 0.0,
		"grid_direction_gate_passed": false,
		"grid_cell_delta_gate_passed": false,
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
		"backend": BACKEND_THRESHOLD,
		"window_ms": POSE_STRIKE_DEFAULT_WINDOW_MS,
		"min_velocity": POSE_STRIKE_DEFAULT_MIN_PUNCH_VELOCITY,
		"max_wrist_angle_from_elbow_horizontal_deg": HOOK_DEFAULT_MAX_WRIST_ANGLE_FROM_ELBOW_HORIZONTAL_DEG,
		"min_cell_delta": GRID_DETECTION_DEFAULT_MIN_CELL_DELTA,
		"direction_dominance_ratio": GRID_DETECTION_DEFAULT_DIRECTION_DOMINANCE_RATIO,
		"triggered_grace_ms": POSE_STRIKE_DEFAULT_TRIGGERED_GRACE_MS,
		"pose_only_rearm_ms": POSE_STRIKE_DEFAULT_POSE_ONLY_REARM_MS,
		"lost_tracking_reacquire_stable_ms": POSE_STRIKE_DEFAULT_REACQUIRE_STABLE_MS,
	}
	if _config == null:
		return config
	var backend_name := _get_punch_backend_for_family("hook")
	var hook: Dictionary = _get_family_backend_document("hook", backend_name)
	var evaluation: Dictionary = hook.get("evaluation", {}) if hook.get("evaluation", {}) is Dictionary else {}
	var thresholds: Dictionary = hook.get("thresholds", {}) if hook.get("thresholds", {}) is Dictionary else {}
	var timing: Dictionary = hook.get("timing", {}) if hook.get("timing", {}) is Dictionary else {}
	var rearm: Dictionary = hook.get("rearm", {}) if hook.get("rearm", {}) is Dictionary else {}
	var state_machine: Dictionary = hook.get("state_machine", {}) if hook.get("state_machine", {}) is Dictionary else {}
	config["enabled"] = backend_name != BACKEND_DISABLED
	config["backend"] = backend_name
	config["window_ms"] = max(1, int(evaluation.get("window_ms", config.get("window_ms", POSE_STRIKE_DEFAULT_WINDOW_MS))))
	config["min_velocity"] = maxf(0.0, float(thresholds.get("min_velocity", thresholds.get("min_punch_velocity", config.get("min_velocity", POSE_STRIKE_DEFAULT_MIN_PUNCH_VELOCITY)))))
	config["max_wrist_angle_from_elbow_horizontal_deg"] = clampf(float(thresholds.get("max_wrist_angle_from_elbow_horizontal_deg", config.get("max_wrist_angle_from_elbow_horizontal_deg", HOOK_DEFAULT_MAX_WRIST_ANGLE_FROM_ELBOW_HORIZONTAL_DEG))), 0.0, 90.0)
	config["min_cell_delta"] = max(1, int(evaluation.get("min_cell_delta", config.get("min_cell_delta", GRID_DETECTION_DEFAULT_MIN_CELL_DELTA))))
	config["direction_dominance_ratio"] = clampf(float(evaluation.get("direction_dominance_ratio", config.get("direction_dominance_ratio", GRID_DETECTION_DEFAULT_DIRECTION_DOMINANCE_RATIO))), 0.0, 1.0)
	config["triggered_grace_ms"] = max(0, int(timing.get("triggered_grace_ms", config.get("triggered_grace_ms", POSE_STRIKE_DEFAULT_TRIGGERED_GRACE_MS))))
	config["pose_only_rearm_ms"] = max(0, int(rearm.get("pose_only_rearm_ms", config.get("pose_only_rearm_ms", POSE_STRIKE_DEFAULT_POSE_ONLY_REARM_MS))))
	config["lost_tracking_reacquire_stable_ms"] = max(0, int(state_machine.get("lost_tracking_reacquire_stable_ms", config.get("lost_tracking_reacquire_stable_ms", POSE_STRIKE_DEFAULT_REACQUIRE_STABLE_MS))))
	return config

func _get_uppercut_config() -> Dictionary:
	var config := {
		"enabled": true,
		"backend": BACKEND_THRESHOLD,
		"window_ms": POSE_STRIKE_DEFAULT_WINDOW_MS,
		"min_velocity": POSE_STRIKE_DEFAULT_MIN_PUNCH_VELOCITY,
		"max_wrist_angle_from_elbow_vertical_deg": UPPERCUT_DEFAULT_MAX_WRIST_ANGLE_FROM_ELBOW_VERTICAL_DEG,
		"min_cell_delta": GRID_DETECTION_DEFAULT_MIN_CELL_DELTA,
		"direction_dominance_ratio": GRID_DETECTION_DEFAULT_DIRECTION_DOMINANCE_RATIO,
		"triggered_grace_ms": POSE_STRIKE_DEFAULT_TRIGGERED_GRACE_MS,
		"pose_only_rearm_ms": POSE_STRIKE_DEFAULT_POSE_ONLY_REARM_MS,
		"lost_tracking_reacquire_stable_ms": POSE_STRIKE_DEFAULT_REACQUIRE_STABLE_MS,
	}
	if _config == null:
		return config
	var backend_name := _get_punch_backend_for_family("uppercut")
	var uppercut: Dictionary = _get_family_backend_document("uppercut", backend_name)
	var evaluation: Dictionary = uppercut.get("evaluation", {}) if uppercut.get("evaluation", {}) is Dictionary else {}
	var thresholds: Dictionary = uppercut.get("thresholds", {}) if uppercut.get("thresholds", {}) is Dictionary else {}
	var timing: Dictionary = uppercut.get("timing", {}) if uppercut.get("timing", {}) is Dictionary else {}
	var rearm: Dictionary = uppercut.get("rearm", {}) if uppercut.get("rearm", {}) is Dictionary else {}
	var state_machine: Dictionary = uppercut.get("state_machine", {}) if uppercut.get("state_machine", {}) is Dictionary else {}
	config["enabled"] = backend_name != BACKEND_DISABLED
	config["backend"] = backend_name
	config["window_ms"] = max(1, int(evaluation.get("window_ms", config.get("window_ms", POSE_STRIKE_DEFAULT_WINDOW_MS))))
	config["min_velocity"] = maxf(0.0, float(thresholds.get("min_velocity", thresholds.get("min_punch_velocity", config.get("min_velocity", POSE_STRIKE_DEFAULT_MIN_PUNCH_VELOCITY)))))
	config["max_wrist_angle_from_elbow_vertical_deg"] = clampf(float(thresholds.get("max_wrist_angle_from_elbow_vertical_deg", config.get("max_wrist_angle_from_elbow_vertical_deg", UPPERCUT_DEFAULT_MAX_WRIST_ANGLE_FROM_ELBOW_VERTICAL_DEG))), 0.0, 90.0)
	config["min_cell_delta"] = max(1, int(evaluation.get("min_cell_delta", config.get("min_cell_delta", GRID_DETECTION_DEFAULT_MIN_CELL_DELTA))))
	config["direction_dominance_ratio"] = clampf(float(evaluation.get("direction_dominance_ratio", config.get("direction_dominance_ratio", GRID_DETECTION_DEFAULT_DIRECTION_DOMINANCE_RATIO))), 0.0, 1.0)
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
	return _tracker_profile_uses_hand_tracking(tracker_profile_document)

func _tracker_profile_uses_hand_tracking(tracker_profile_document: Dictionary) -> bool:
	var tracking: Dictionary = tracker_profile_document.get("tracking", {}) if tracker_profile_document.get("tracking", {}) is Dictionary else {}
	var hands: Dictionary = tracking.get("hands", {}) if tracking.get("hands", {}) is Dictionary else {}
	if not hands.is_empty() and hands.has("enabled"):
		return bool(hands.get("enabled", true))
	var profile_name := String(tracker_profile_document.get("profile", "")).strip_edges().to_lower()
	var pose: Dictionary = tracking.get("pose", {}) if tracking.get("pose", {}) is Dictionary else {}
	var pose_enabled := bool(pose.get("enabled", false))
	if profile_name == "boxing" and pose_enabled:
		return false
	return true

func _resolve_pose_reference_shoulder_width(shoulder_width: float) -> float:
	if shoulder_width > 0.0:
		return shoulder_width
	if bool(_baseline.get("is_calibrated", false)):
		return maxf(float(_baseline.get("shoulder_width", 0.0)), 0.0)
	return 0.0

func _pose_reference_shoulder_width_source(raw_shoulder_width: float, reference_shoulder_width: float) -> String:
	if raw_shoulder_width > 0.0:
		return "live"
	if reference_shoulder_width > 0.0:
		return "baseline"
	return "missing"

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
		"elbow_shoulder_xy_distance": float(state.get("elbow_shoulder_xy_distance", 0.0)),
		"max_elbow_shoulder_xy_distance": float(state.get("max_elbow_shoulder_xy_distance", STRAIGHT_PUNCH_DEFAULT_MAX_ELBOW_SHOULDER_XY_DISTANCE)),
		"elbow_shoulder_xy_gate_passed": bool(state.get("elbow_shoulder_xy_gate_passed", false)),
		"wrist_lateral_angle_from_elbow_vertical_deg": float(state.get("wrist_lateral_angle_from_elbow_vertical_deg", 0.0)),
		"min_wrist_lateral_angle_from_elbow_vertical_deg": float(state.get("min_wrist_lateral_angle_from_elbow_vertical_deg", STRAIGHT_PUNCH_DEFAULT_MIN_WRIST_LATERAL_ANGLE_FROM_ELBOW_VERTICAL_DEG)),
		"wrist_lateral_angle_gate_passed": bool(state.get("wrist_lateral_angle_gate_passed", false)),
		"grace_ms_remaining": int(state.get("grace_ms_remaining", 0)),
		"wrist_velocity": float(state.get("last_wrist_velocity", 0.0)),
		"recent_peak_wrist_velocity": float(state.get("recent_peak_wrist_velocity", 0.0)),
		"wrist_forward_velocity": float(state.get("last_wrist_forward_velocity", 0.0)),
		"forward_depth_spike": float(state.get("last_forward_depth_spike", 0.0)),
		"recent_peak_forward_depth_spike": float(state.get("recent_peak_forward_depth_spike", 0.0)),
		"fresh_sample": bool(state.get("last_sample_fresh", false)),
		"sample_source": String(state.get("hand_sample_source", "none")),
		"tracking_state": String(state.get("hand_tracking_state", "idle")),
		"tracking_valid": bool(state.get("hand_tracking_valid", false)),
		"pose_tracking_valid": bool(state.get("pose_tracking_valid", false)),
		"pose_reference_shoulder_width": float(state.get("pose_reference_shoulder_width", 0.0)),
		"pose_reference_shoulder_width_source": String(state.get("pose_reference_shoulder_width_source", "missing")),
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
