class_name PrototypePunchMatcher
extends RefCounted

const PoseLandmarkIds = preload("res://addons/aerobeat-input-camera-tracking/src/detectors/pose_landmark_ids.gd")
const PoseMetrics = preload("res://addons/aerobeat-input-camera-tracking/src/detectors/pose_metrics.gd")

const BACKEND_DISABLED := "disabled"
const BACKEND_THRESHOLD_GATES := "threshold"
const BACKEND_PROTOTYPE_MATCHER := "prototype"
const BACKEND_CLASSIFIER := "classifier"
const PUNCH_FAMILIES := ["straight_punch", "hook", "uppercut"]
const FAMILY_EVENT_NAMES := {
	"straight_punch": ["punch_left", "punch_right"],
	"hook": ["hook_left", "hook_right"],
	"uppercut": ["uppercut_left", "uppercut_right"],
}
const OUTCOME_NO_PUNCH := "no_punch"
const DEFAULT_WINDOW_MS := 250
const DEFAULT_WINDOW_STEP_MS := 33
const DEFAULT_MATCH_SCORE_MIN := 0.70
const DEFAULT_EMIT_COOLDOWN_MS := 250
const DEFAULT_EMIT_HOLD_MS := 100
const DEFAULT_SHOW_SCORES := true
const DEFAULT_SHOW_EVENT_GATE_STATE := true
const DEFAULT_LIBRARY_ID := "boxing_side_aware_v1"
const DEFAULT_DISTANCE_SCALE := 0.45
const FEATURE_NAME_SHOULDER_X := "shoulder_x"
const FEATURE_NAME_SHOULDER_Y := "shoulder_y"
const FEATURE_NAME_ELBOW_X := "elbow_x"
const FEATURE_NAME_ELBOW_Y := "elbow_y"
const FEATURE_NAME_WRIST_X := "wrist_x"
const FEATURE_NAME_WRIST_Y := "wrist_y"
const FEATURE_NAME_COMBINED_ELBOW_WRIST_VELOCITY_XY_MAGNITUDE := "combined_elbow_wrist_velocity_xy_magnitude"
const FEATURE_NAME_ELBOW_SHOULDER_XY_DISTANCE_OVER_SHOULDER_WIDTH := "elbow_shoulder_xy_distance_over_shoulder_width"
const FEATURE_NAME_CAMERA_SIGNED_VX := "camera_signed_vx"
const FEATURE_NAME_CAMERA_SIGNED_VY := "camera_signed_vy"
const FEATURE_NAME_CAMERA_DIRECTION_NONE := "camera_direction_none"
const FEATURE_NAME_CAMERA_DIRECTION_UP := "camera_direction_up"
const FEATURE_NAME_CAMERA_DIRECTION_DOWN := "camera_direction_down"
const FEATURE_NAME_CAMERA_DIRECTION_LEFT := "camera_direction_left"
const FEATURE_NAME_CAMERA_DIRECTION_RIGHT := "camera_direction_right"
const FEATURE_NAME_BODY_SIGNED_VX := "body_signed_vx"
const FEATURE_NAME_BODY_SIGNED_VY := "body_signed_vy"
const FEATURE_NAME_BODY_DIRECTION_NONE := "body_direction_none"
const FEATURE_NAME_BODY_DIRECTION_UP := "body_direction_up"
const FEATURE_NAME_BODY_DIRECTION_DOWN := "body_direction_down"
const FEATURE_NAME_BODY_DIRECTION_LEFT := "body_direction_left"
const FEATURE_NAME_BODY_DIRECTION_RIGHT := "body_direction_right"
const FEATURE_NAME_ELBOW_X_FROM_SHOULDER_OVER_SHOULDER_WIDTH := "elbow_x_from_shoulder_over_shoulder_width"
const FEATURE_NAME_ELBOW_Y_FROM_SHOULDER_OVER_SHOULDER_WIDTH := "elbow_y_from_shoulder_over_shoulder_width"
const FEATURE_NAME_ELBOW_SHOULDER_RADIAL_VELOCITY_OVER_SHOULDER_WIDTH := "elbow_shoulder_radial_velocity_over_shoulder_width"
const FEATURE_NAME_WRIST_X_FROM_SHOULDER_OVER_SHOULDER_WIDTH := "wrist_x_from_shoulder_over_shoulder_width"
const FEATURE_NAME_WRIST_Y_FROM_SHOULDER_OVER_SHOULDER_WIDTH := "wrist_y_from_shoulder_over_shoulder_width"
const FEATURE_NAME_ELBOW_Z_FROM_SHOULDER := "elbow_z_from_shoulder"
const FEATURE_NAME_WRIST_Z_FROM_SHOULDER := "wrist_z_from_shoulder"
const SUPPORTED_CLASSES := [
	"straight_left",
	"straight_right",
	"hook_left",
	"hook_right",
	"uppercut_left",
	"uppercut_right",
]

var _config = null
var _sample_history: Array = []
var _library_id := DEFAULT_LIBRARY_ID
var _library: Dictionary = {}
var _library_path := ""
var _library_error := ""
var _last_debug_state := _build_debug_state()
var _last_eval_timestamp_ms := 0
var _last_emit_timestamp_ms := -1
var _last_emitted_class := OUTCOME_NO_PUNCH
var _emit_cooldown_until_ms := 0
var _emit_hold_until_ms := 0
var _latest_landmarks_by_id: Dictionary = {}

func _gesture_class_to_family(gesture_class: String) -> String:
	if gesture_class.begins_with("straight_"):
		return "straight_punch"
	if gesture_class.begins_with("hook_"):
		return "hook"
	if gesture_class.begins_with("uppercut_"):
		return "uppercut"
	return ""

func _get_same_family_blocking_class(candidate_class: String, timestamp_ms: int) -> String:
	if timestamp_ms >= _emit_hold_until_ms:
		return ""
	if candidate_class == OUTCOME_NO_PUNCH or _last_emitted_class == OUTCOME_NO_PUNCH:
		return ""
	if candidate_class == _last_emitted_class:
		return ""
	var candidate_family := _gesture_class_to_family(candidate_class)
	var blocking_family := _gesture_class_to_family(_last_emitted_class)
	if candidate_family == "" or candidate_family != blocking_family:
		return ""
	return _last_emitted_class

func configure(config) -> PrototypePunchMatcher:
	_config = config
	_load_library_if_needed()
	_last_debug_state = _build_debug_state()
	return self

func reset() -> void:
	_sample_history.clear()
	_last_eval_timestamp_ms = 0
	_last_emit_timestamp_ms = -1
	_last_emitted_class = OUTCOME_NO_PUNCH
	_emit_cooldown_until_ms = 0
	_emit_hold_until_ms = 0
	_last_debug_state = _build_debug_state()

func get_debug_state() -> Dictionary:
	var debug_state := _last_debug_state.duplicate(true)
	debug_state["enabled"] = _is_enabled_in_config()
	debug_state["selected_backend"] = _get_selected_backend()
	debug_state["selected_backend_enabled"] = _is_selected_backend_enabled()
	debug_state["active_backend"] = BACKEND_PROTOTYPE_MATCHER if _is_active_backend() else "none"
	debug_state["activation_reason"] = _get_activation_reason()
	debug_state["library_id"] = _library_id
	debug_state["library_path"] = _library_path
	debug_state["library_loaded"] = _library_error == "" and not _library.is_empty()
	debug_state["library_error"] = _library_error
	debug_state["window_ms"] = _get_window_ms()
	debug_state["window_step_ms"] = _get_window_step_ms()
	debug_state["match_score_min"] = _get_match_score_min()
	debug_state["emit_cooldown_ms"] = _get_emit_cooldown_ms()
	debug_state["emit_hold_ms"] = _get_emit_hold_ms()
	debug_state["cooldown_ms_remaining"] = max(0, _emit_cooldown_until_ms - int(debug_state.get("current_timestamp_ms", 0)))
	debug_state["hold_ms_remaining"] = max(0, _emit_hold_until_ms - int(debug_state.get("current_timestamp_ms", 0)))
	debug_state["show_scores"] = _get_show_scores()
	debug_state["show_event_gate_state"] = _get_show_event_gate_state()
	return debug_state

func process_window(landmarks_by_id: Dictionary, metrics: Dictionary, timestamp_ms: int) -> Array:
	_load_library_if_needed()
	var events: Array = []
	var debug_state := _build_debug_state()
	debug_state["current_timestamp_ms"] = timestamp_ms
	debug_state["selected_backend"] = _get_selected_backend()
	debug_state["selected_backend_enabled"] = _is_selected_backend_enabled()
	debug_state["active_backend"] = BACKEND_PROTOTYPE_MATCHER if _is_active_backend() else "none"
	debug_state["activation_reason"] = _get_activation_reason()
	debug_state["library_id"] = _library_id
	debug_state["library_path"] = _library_path
	debug_state["library_loaded"] = _library_error == "" and not _library.is_empty()
	debug_state["library_error"] = _library_error
	debug_state["window_ms"] = _get_window_ms()
	debug_state["window_step_ms"] = _get_window_step_ms()
	debug_state["match_score_min"] = _get_match_score_min()
	debug_state["emit_cooldown_ms"] = _get_emit_cooldown_ms()
	debug_state["emit_hold_ms"] = _get_emit_hold_ms()
	debug_state["show_scores"] = _get_show_scores()
	debug_state["show_event_gate_state"] = _get_show_event_gate_state()
	debug_state["result_class"] = OUTCOME_NO_PUNCH
	debug_state["reason"] = "inactive"
	debug_state["emitted"] = false
	debug_state["emitted_event_name"] = ""
	debug_state["cooldown_ms_remaining"] = max(0, _emit_cooldown_until_ms - timestamp_ms)
	debug_state["hold_ms_remaining"] = max(0, _emit_hold_until_ms - timestamp_ms)
	debug_state["active_event_class"] = _last_emitted_class if timestamp_ms < _emit_hold_until_ms else OUTCOME_NO_PUNCH
	debug_state["last_emit_timestamp_ms"] = _last_emit_timestamp_ms
	debug_state["class_scores"] = {}
	debug_state["best_class"] = OUTCOME_NO_PUNCH
	debug_state["best_score"] = 0.0
	debug_state["required_score"] = _get_match_score_min()

	if not _is_active_backend():
		_last_debug_state = debug_state
		return events
	if _library_error != "" or _library.is_empty():
		debug_state["reason"] = "library_unavailable"
		_last_debug_state = debug_state
		return events

	var sample := _extract_runtime_sample(landmarks_by_id, metrics, timestamp_ms)
	if sample.is_empty():
		debug_state["reason"] = "pose_invalid"
		_last_debug_state = debug_state
		return events
	var left_sample: Dictionary = sample.get("left", {}) if sample.get("left", {}) is Dictionary else {}
	var right_sample: Dictionary = sample.get("right", {}) if sample.get("right", {}) is Dictionary else {}
	_sample_history.append({
		"timestamp_ms": timestamp_ms,
		"left": {
			"features": (left_sample.get("features", []) as Array).duplicate(true),
			"elbow_position": left_sample.get("elbow_position", Vector2.ZERO),
		},
		"right": {
			"features": (right_sample.get("features", []) as Array).duplicate(true),
			"elbow_position": right_sample.get("elbow_position", Vector2.ZERO),
		},
		"left_signal_position": left_sample.get("signal_position", Vector2.ZERO),
		"right_signal_position": right_sample.get("signal_position", Vector2.ZERO),
	})
	_prune_sample_history(timestamp_ms)
	debug_state["window_sample_count"] = _sample_history.size()
	debug_state["window_span_ms"] = _resolve_window_span_ms(_sample_history)
	debug_state["window_ready_sample_count"] = _get_library_sample_count()
	if _sample_history.size() < _get_library_sample_count():
		debug_state["reason"] = "window_not_full"
		_last_debug_state = debug_state
		return events
	if _last_eval_timestamp_ms > 0 and timestamp_ms - _last_eval_timestamp_ms < _get_window_step_ms():
		debug_state["reason"] = "step_wait"
		_last_debug_state = debug_state
		return events

	_last_eval_timestamp_ms = timestamp_ms
	debug_state["last_eval_timestamp_ms"] = _last_eval_timestamp_ms
	var score_result := _score_current_window()
	debug_state["evaluated_window_sample_count"] = int(score_result.get("window_sample_count", _sample_history.size()))
	debug_state["evaluated_window_span_ms"] = int(score_result.get("window_span_ms", int(debug_state.get("window_span_ms", 0))))
	var class_scores: Dictionary = score_result.get("class_scores", {}) if score_result.get("class_scores", {}) is Dictionary else {}
	var best_class := String(score_result.get("best_class", OUTCOME_NO_PUNCH))
	var best_score := float(score_result.get("best_score", 0.0))
	var best_prototype_id := String(score_result.get("best_prototype_id", ""))
	var best_prototype_side := String(score_result.get("best_prototype_side", ""))
	var runner_up_class := String(score_result.get("runner_up_class", OUTCOME_NO_PUNCH))
	var runner_up_score := float(score_result.get("runner_up_score", 0.0))
	var runner_up_prototype_id := String(score_result.get("runner_up_prototype_id", ""))
	var best_class_margin := float(score_result.get("best_class_margin", 0.0))
	var class_winner_by_class: Dictionary = score_result.get("class_winner_by_class", {}) if score_result.get("class_winner_by_class", {}) is Dictionary else {}
	var top_matches: Array = score_result.get("top_matches", []) if score_result.get("top_matches", []) is Array else []
	debug_state["class_scores"] = class_scores.duplicate(true)
	debug_state["best_class"] = best_class
	debug_state["best_score"] = best_score
	debug_state["best_prototype_id"] = best_prototype_id
	debug_state["best_prototype_side"] = best_prototype_side
	debug_state["runner_up_class"] = runner_up_class
	debug_state["runner_up_score"] = runner_up_score
	debug_state["runner_up_prototype_id"] = runner_up_prototype_id
	debug_state["best_class_margin"] = best_class_margin
	debug_state["class_winner_by_class"] = class_winner_by_class.duplicate(true)
	debug_state["top_matches"] = top_matches.duplicate(true)
	debug_state["required_score"] = _get_match_score_min()
	if best_score + 0.000001 < _get_match_score_min() or best_class == OUTCOME_NO_PUNCH:
		debug_state["result_class"] = OUTCOME_NO_PUNCH
		debug_state["reason"] = "below_threshold"
		_last_debug_state = debug_state
		return events
	var same_family_blocking_class := _get_same_family_blocking_class(best_class, timestamp_ms)
	if same_family_blocking_class != "":
		debug_state["result_class"] = best_class
		debug_state["reason"] = "same_family_active"
		debug_state["same_family_blocked"] = true
		debug_state["blocking_family"] = _gesture_class_to_family(best_class)
		debug_state["blocking_class"] = same_family_blocking_class
		debug_state["active_event_class"] = same_family_blocking_class
		debug_state["hold_ms_remaining"] = _emit_hold_until_ms - timestamp_ms
		_last_debug_state = debug_state
		return events
	if timestamp_ms < _emit_hold_until_ms:
		debug_state["result_class"] = best_class
		debug_state["reason"] = "emit_hold_active"
		debug_state["hold_ms_remaining"] = _emit_hold_until_ms - timestamp_ms
		_last_debug_state = debug_state
		return events
	if timestamp_ms < _emit_cooldown_until_ms:
		debug_state["result_class"] = best_class
		debug_state["reason"] = "emit_cooldown_active"
		debug_state["cooldown_ms_remaining"] = _emit_cooldown_until_ms - timestamp_ms
		_last_debug_state = debug_state
		return events

	var event_name := _class_to_event_name(best_class)
	if event_name == "":
		debug_state["result_class"] = OUTCOME_NO_PUNCH
		debug_state["reason"] = "unsupported_class"
		_last_debug_state = debug_state
		return events
	_last_emit_timestamp_ms = timestamp_ms
	_last_emitted_class = best_class
	_emit_cooldown_until_ms = timestamp_ms + _get_emit_cooldown_ms()
	_emit_hold_until_ms = timestamp_ms + _get_emit_hold_ms()
	var power := clampf(best_score, 0.0, 1.0)
	events.append({
		"name": StringName(event_name),
		"power": power,
		"backend": BACKEND_PROTOTYPE_MATCHER,
		"prototype_match": {
			"class_name": best_class,
			"score": best_score,
			"prototype_id": best_prototype_id,
			"prototype_side": best_prototype_side,
			"runner_up_class": runner_up_class,
			"runner_up_score": runner_up_score,
			"runner_up_prototype_id": runner_up_prototype_id,
			"class_margin": best_class_margin,
			"library_id": _library_id,
			"threshold": _get_match_score_min(),
		},
	})
	debug_state["result_class"] = best_class
	debug_state["reason"] = "emitted"
	debug_state["emitted"] = true
	debug_state["emitted_event_name"] = event_name
	debug_state["cooldown_ms_remaining"] = _emit_cooldown_until_ms - timestamp_ms
	debug_state["hold_ms_remaining"] = _emit_hold_until_ms - timestamp_ms
	debug_state["active_event_class"] = best_class
	_last_debug_state = debug_state
	return events

func _build_debug_state() -> Dictionary:
	return {
		"enabled": _is_enabled_in_config(),
		"selected_backend": _get_selected_backend(),
		"selected_backend_enabled": _is_selected_backend_enabled(),
		"active_backend": BACKEND_PROTOTYPE_MATCHER if _is_active_backend() else "none",
		"activation_reason": _get_activation_reason(),
		"library_id": _library_id,
		"library_path": _library_path,
		"library_loaded": _library_error == "" and not _library.is_empty(),
		"library_error": _library_error,
		"window_ms": _get_window_ms(),
		"window_step_ms": _get_window_step_ms(),
		"match_score_min": _get_match_score_min(),
		"emit_cooldown_ms": _get_emit_cooldown_ms(),
		"emit_hold_ms": _get_emit_hold_ms(),
		"window_sample_count": 0,
		"window_span_ms": 0,
		"window_ready_sample_count": _get_library_sample_count(),
		"evaluated_window_sample_count": 0,
		"evaluated_window_span_ms": 0,
		"last_eval_timestamp_ms": _last_eval_timestamp_ms,
		"last_emit_timestamp_ms": _last_emit_timestamp_ms,
		"best_class": OUTCOME_NO_PUNCH,
		"best_score": 0.0,
		"best_prototype_id": "",
		"best_prototype_side": "",
		"runner_up_class": OUTCOME_NO_PUNCH,
		"runner_up_score": 0.0,
		"runner_up_prototype_id": "",
		"best_class_margin": 0.0,
		"class_winner_by_class": {},
		"top_matches": [],
		"required_score": _get_match_score_min(),
		"result_class": OUTCOME_NO_PUNCH,
		"reason": "idle",
		"class_scores": {},
		"same_family_blocked": false,
		"blocking_family": "",
		"blocking_class": "",
		"emitted": false,
		"emitted_event_name": "",
		"cooldown_ms_remaining": 0,
		"hold_ms_remaining": 0,
		"active_event_class": OUTCOME_NO_PUNCH,
		"current_timestamp_ms": 0,
		"show_scores": _get_show_scores(),
		"show_event_gate_state": _get_show_event_gate_state(),
	}

func _load_library_if_needed() -> void:
	var library_id := _get_library_id()
	if library_id == _library_id and not _library.is_empty() and _library_error == "":
		return
	_library_id = library_id
	_library.clear()
	_library_error = ""
	_library_path = _resolve_library_path(library_id)
	var file := FileAccess.open(_library_path, FileAccess.READ)
	if file == null:
		_library_error = "library_open_failed"
		return
	var raw_text := file.get_as_text()
	var json := JSON.new()
	var parse_error := json.parse(raw_text)
	if parse_error != OK:
		_library_error = "library_parse_failed"
		return
	var data: Variant = json.data
	if not data is Dictionary:
		_library_error = "library_invalid_root"
		return
	_library = (data as Dictionary).duplicate(true)
	if String(_library.get("library_id", "")) != library_id:
		_library_error = "library_id_mismatch"
		_library.clear()
		return
	var prototypes: Variant = _library.get("prototypes", [])
	if not prototypes is Array or (prototypes as Array).is_empty():
		_library_error = "library_missing_prototypes"
		_library.clear()

func _resolve_library_path(library_id: String) -> String:
	return _get_addon_root_path().path_join("assets/prototype_libraries/%s/library.json" % library_id)

func _get_addon_root_path() -> String:
	var script_path := String(get_script().resource_path)
	return script_path.get_base_dir().get_base_dir().get_base_dir()

func _prune_sample_history(timestamp_ms: int) -> void:
	var min_timestamp := timestamp_ms - _get_window_ms()
	while _sample_history.size() > 1 and int((_sample_history[1] as Dictionary).get("timestamp_ms", 0)) <= min_timestamp:
		_sample_history.remove_at(0)

func _resolve_window_span_ms(samples: Array = _sample_history) -> int:
	if samples.size() < 2:
		return 0
	return int((samples[samples.size() - 1] as Dictionary).get("timestamp_ms", 0)) - int((samples[0] as Dictionary).get("timestamp_ms", 0))

func _extract_runtime_sample(landmarks_by_id: Dictionary, metrics: Dictionary, timestamp_ms: int) -> Dictionary:
	_latest_landmarks_by_id = landmarks_by_id.duplicate(true)
	var measurements: Dictionary = metrics.get("measurements", {}) if metrics.get("measurements", {}) is Dictionary else {}
	var shoulder_width := maxf(float(measurements.get("shoulder_width", 0.0)), 0.000001)
	var left_shoulder := PoseMetrics.get_landmark(landmarks_by_id, PoseLandmarkIds.LEFT_SHOULDER)
	var right_shoulder := PoseMetrics.get_landmark(landmarks_by_id, PoseLandmarkIds.RIGHT_SHOULDER)
	var left_elbow := PoseMetrics.get_landmark(landmarks_by_id, PoseLandmarkIds.LEFT_ELBOW)
	var right_elbow := PoseMetrics.get_landmark(landmarks_by_id, PoseLandmarkIds.RIGHT_ELBOW)
	var left_wrist := PoseMetrics.get_landmark(landmarks_by_id, PoseLandmarkIds.LEFT_WRIST)
	var right_wrist := PoseMetrics.get_landmark(landmarks_by_id, PoseLandmarkIds.RIGHT_WRIST)
	if left_shoulder.is_empty() or right_shoulder.is_empty() or left_elbow.is_empty() or right_elbow.is_empty() or left_wrist.is_empty() or right_wrist.is_empty():
		return {}
	var min_visibility := minf(minf(float(left_shoulder.get("v", 0.0)), float(right_shoulder.get("v", 0.0))), minf(minf(float(left_elbow.get("v", 0.0)), float(right_elbow.get("v", 0.0))), minf(float(left_wrist.get("v", 0.0)), float(right_wrist.get("v", 0.0)))))
	if min_visibility < 0.5:
		return {}
	return {
		"left": _extract_side_features("left", left_shoulder, left_elbow, left_wrist, shoulder_width, timestamp_ms),
		"right": _extract_side_features("right", right_shoulder, right_elbow, right_wrist, shoulder_width, timestamp_ms),
	}

func _extract_side_features(side: String, shoulder: Dictionary, elbow: Dictionary, wrist: Dictionary, shoulder_width: float, timestamp_ms: int) -> Dictionary:
	var feature_names := _get_feature_names()
	var signal_position := _resolve_combined_elbow_wrist_signal_position(elbow, wrist)
	var average_velocity := _resolve_recent_combined_velocity_components(side, signal_position, timestamp_ms)
	var camera_signed_vx := float(average_velocity.x)
	var camera_signed_vy := -float(average_velocity.y)
	var left_shoulder := PoseMetrics.get_landmark(_latest_landmarks_by_id, PoseLandmarkIds.LEFT_SHOULDER)
	var right_shoulder := PoseMetrics.get_landmark(_latest_landmarks_by_id, PoseLandmarkIds.RIGHT_SHOULDER)
	var body_lateral_axis := _body_lateral_unit_vector(left_shoulder, right_shoulder)
	var body_signed_vx := (float(average_velocity.x) * body_lateral_axis.x) + (float(average_velocity.y) * body_lateral_axis.y)
	var body_signed_vy := camera_signed_vy
	var camera_direction := _coarse_direction_buckets(camera_signed_vx, camera_signed_vy)
	var body_direction := _coarse_direction_buckets(body_signed_vx, body_signed_vy)
	var combined_velocity_magnitude := average_velocity.length()
	var elbow_shoulder_xy_distance_over_shoulder_width := PoseMetrics.distance_2d(elbow, shoulder) / shoulder_width
	var elbow_velocity := _resolve_recent_joint_velocity_components(side, elbow, timestamp_ms, "elbow")
	var elbow_shoulder_radial_velocity_over_shoulder_width := _resolve_radial_velocity_over_shoulder_width(shoulder, elbow, elbow_velocity, shoulder_width)
	var features: Array = []
	for feature_name_variant in feature_names:
		var feature_name := String(feature_name_variant)
		features.append(_resolve_feature_value(feature_name, shoulder, elbow, wrist, shoulder_width, combined_velocity_magnitude, elbow_shoulder_xy_distance_over_shoulder_width, elbow_shoulder_radial_velocity_over_shoulder_width, camera_signed_vx, camera_signed_vy, body_signed_vx, body_signed_vy, camera_direction, body_direction))
	return {
		"features": features,
		"signal_position": signal_position,
		"elbow_position": Vector2(float(elbow.get("x", 0.0)), float(elbow.get("y", 0.0))),
	}

func _resolve_feature_value(feature_name: String, shoulder: Dictionary, elbow: Dictionary, wrist: Dictionary, shoulder_width: float, combined_velocity_magnitude: float, elbow_shoulder_xy_distance_over_shoulder_width: float, elbow_shoulder_radial_velocity_over_shoulder_width: float, camera_signed_vx: float, camera_signed_vy: float, body_signed_vx: float, body_signed_vy: float, camera_direction: Dictionary, body_direction: Dictionary) -> float:
	match feature_name:
		FEATURE_NAME_SHOULDER_X:
			return float(shoulder.get("x", 0.0))
		FEATURE_NAME_SHOULDER_Y:
			return float(shoulder.get("y", 0.0))
		FEATURE_NAME_ELBOW_X:
			return float(elbow.get("x", 0.0))
		FEATURE_NAME_ELBOW_Y:
			return float(elbow.get("y", 0.0))
		FEATURE_NAME_WRIST_X:
			return float(wrist.get("x", 0.0))
		FEATURE_NAME_WRIST_Y:
			return float(wrist.get("y", 0.0))
		FEATURE_NAME_COMBINED_ELBOW_WRIST_VELOCITY_XY_MAGNITUDE:
			return combined_velocity_magnitude
		FEATURE_NAME_ELBOW_SHOULDER_XY_DISTANCE_OVER_SHOULDER_WIDTH:
			return elbow_shoulder_xy_distance_over_shoulder_width
		FEATURE_NAME_CAMERA_SIGNED_VX:
			return camera_signed_vx
		FEATURE_NAME_CAMERA_SIGNED_VY:
			return camera_signed_vy
		FEATURE_NAME_CAMERA_DIRECTION_NONE:
			return float(camera_direction.get("none", 0.0))
		FEATURE_NAME_CAMERA_DIRECTION_UP:
			return float(camera_direction.get("up", 0.0))
		FEATURE_NAME_CAMERA_DIRECTION_DOWN:
			return float(camera_direction.get("down", 0.0))
		FEATURE_NAME_CAMERA_DIRECTION_LEFT:
			return float(camera_direction.get("left", 0.0))
		FEATURE_NAME_CAMERA_DIRECTION_RIGHT:
			return float(camera_direction.get("right", 0.0))
		FEATURE_NAME_BODY_SIGNED_VX:
			return body_signed_vx
		FEATURE_NAME_BODY_SIGNED_VY:
			return body_signed_vy
		FEATURE_NAME_BODY_DIRECTION_NONE:
			return float(body_direction.get("none", 0.0))
		FEATURE_NAME_BODY_DIRECTION_UP:
			return float(body_direction.get("up", 0.0))
		FEATURE_NAME_BODY_DIRECTION_DOWN:
			return float(body_direction.get("down", 0.0))
		FEATURE_NAME_BODY_DIRECTION_LEFT:
			return float(body_direction.get("left", 0.0))
		FEATURE_NAME_BODY_DIRECTION_RIGHT:
			return float(body_direction.get("right", 0.0))
		FEATURE_NAME_ELBOW_X_FROM_SHOULDER_OVER_SHOULDER_WIDTH:
			return (float(elbow.get("x", 0.0)) - float(shoulder.get("x", 0.0))) / shoulder_width
		FEATURE_NAME_ELBOW_Y_FROM_SHOULDER_OVER_SHOULDER_WIDTH:
			return (float(elbow.get("y", 0.0)) - float(shoulder.get("y", 0.0))) / shoulder_width
		FEATURE_NAME_ELBOW_SHOULDER_RADIAL_VELOCITY_OVER_SHOULDER_WIDTH:
			return elbow_shoulder_radial_velocity_over_shoulder_width
		FEATURE_NAME_WRIST_X_FROM_SHOULDER_OVER_SHOULDER_WIDTH:
			return (float(wrist.get("x", 0.0)) - float(shoulder.get("x", 0.0))) / shoulder_width
		FEATURE_NAME_WRIST_Y_FROM_SHOULDER_OVER_SHOULDER_WIDTH:
			return (float(wrist.get("y", 0.0)) - float(shoulder.get("y", 0.0))) / shoulder_width
		FEATURE_NAME_ELBOW_Z_FROM_SHOULDER:
			return float(elbow.get("z", 0.0)) - float(shoulder.get("z", 0.0))
		FEATURE_NAME_WRIST_Z_FROM_SHOULDER:
			return float(wrist.get("z", 0.0)) - float(shoulder.get("z", 0.0))
		_:
			return 0.0

func _resolve_combined_elbow_wrist_signal_position(elbow: Dictionary, wrist: Dictionary) -> Vector2:
	return Vector2(
		(float(elbow.get("x", 0.0)) + float(wrist.get("x", 0.0))) * 0.5,
		(float(elbow.get("y", 0.0)) + float(wrist.get("y", 0.0))) * 0.5
	)

func _resolve_recent_combined_velocity_components(side: String, signal_position: Vector2, timestamp_ms: int) -> Vector2:
	var previous_entries: Array = []
	for sample_variant in _sample_history:
		if not sample_variant is Dictionary:
			continue
		var sample: Dictionary = sample_variant
		var previous_signal := sample.get("%s_signal_position" % side, null)
		if previous_signal == null or not previous_signal is Vector2:
			continue
		previous_entries.append({
			"timestamp_ms": int(sample.get("timestamp_ms", timestamp_ms)),
			"signal_position": previous_signal,
		})
	previous_entries.append({
		"timestamp_ms": timestamp_ms,
		"signal_position": signal_position,
	})
	if previous_entries.size() < 2:
		return Vector2.ZERO
	var velocity_sum := Vector2.ZERO
	var velocity_sample_count := 0
	for index in range(1, previous_entries.size()):
		var previous_entry: Dictionary = previous_entries[index - 1] as Dictionary
		var current_entry: Dictionary = previous_entries[index] as Dictionary
		var previous_timestamp_ms := int(previous_entry.get("timestamp_ms", timestamp_ms))
		var current_timestamp_ms := int(current_entry.get("timestamp_ms", timestamp_ms))
		var segment_dt_ms := current_timestamp_ms - previous_timestamp_ms
		if segment_dt_ms <= 0:
			continue
		var previous_signal: Vector2 = previous_entry.get("signal_position", signal_position)
		var current_signal: Vector2 = current_entry.get("signal_position", signal_position)
		velocity_sum += (current_signal - previous_signal) / (float(segment_dt_ms) / 1000.0)
		velocity_sample_count += 1
	if velocity_sample_count <= 0:
		return Vector2.ZERO
	return velocity_sum / float(velocity_sample_count)

func _resolve_recent_combined_velocity_magnitude(side: String, signal_position: Vector2, timestamp_ms: int) -> float:
	return _resolve_recent_combined_velocity_components(side, signal_position, timestamp_ms).length()

func _resolve_recent_joint_velocity_components(side: String, joint: Dictionary, timestamp_ms: int, joint_key: String) -> Vector2:
	var current_position := Vector2(float(joint.get("x", 0.0)), float(joint.get("y", 0.0)))
	var previous_entries: Array = []
	for sample_variant in _sample_history:
		if not sample_variant is Dictionary:
			continue
		var sample: Dictionary = sample_variant
		var side_entry: Dictionary = sample.get(side, {}) if sample.get(side, {}) is Dictionary else {}
		var previous_position = side_entry.get("%s_position" % joint_key, null)
		if previous_position == null or not previous_position is Vector2:
			continue
		previous_entries.append({
			"timestamp_ms": int(sample.get("timestamp_ms", timestamp_ms)),
			"position": previous_position,
		})
	previous_entries.append({
		"timestamp_ms": timestamp_ms,
		"position": current_position,
	})
	if previous_entries.size() < 2:
		return Vector2.ZERO
	var velocity_sum := Vector2.ZERO
	var velocity_sample_count := 0
	for index in range(1, previous_entries.size()):
		var previous_entry: Dictionary = previous_entries[index - 1] as Dictionary
		var current_entry: Dictionary = previous_entries[index] as Dictionary
		var previous_timestamp_ms := int(previous_entry.get("timestamp_ms", timestamp_ms))
		var current_timestamp_ms := int(current_entry.get("timestamp_ms", timestamp_ms))
		var segment_dt_ms := current_timestamp_ms - previous_timestamp_ms
		if segment_dt_ms <= 0:
			continue
		var previous_position: Vector2 = previous_entry.get("position", current_position)
		var latest_position: Vector2 = current_entry.get("position", current_position)
		velocity_sum += (latest_position - previous_position) / (float(segment_dt_ms) / 1000.0)
		velocity_sample_count += 1
	if velocity_sample_count <= 0:
		return Vector2.ZERO
	return velocity_sum / float(velocity_sample_count)

func _resolve_radial_velocity_over_shoulder_width(shoulder: Dictionary, elbow: Dictionary, elbow_velocity: Vector2, shoulder_width: float) -> float:
	var radial := Vector2(
		float(elbow.get("x", 0.0)) - float(shoulder.get("x", 0.0)),
		float(elbow.get("y", 0.0)) - float(shoulder.get("y", 0.0))
	)
	var radial_length := radial.length()
	if radial_length <= 0.000001:
		return 0.0
	var radial_unit := radial / radial_length
	return elbow_velocity.dot(radial_unit) / shoulder_width

func _body_lateral_unit_vector(left_shoulder: Dictionary, right_shoulder: Dictionary) -> Vector2:
	var axis := Vector2(
		float(left_shoulder.get("x", 0.0)) - float(right_shoulder.get("x", 0.0)),
		float(left_shoulder.get("y", 0.0)) - float(right_shoulder.get("y", 0.0))
	)
	if axis.length() <= 0.000001:
		return Vector2.RIGHT
	return axis.normalized()

func _coarse_direction_buckets(signed_vx: float, signed_vy: float, min_speed: float = 0.000001) -> Dictionary:
	var speed := Vector2(signed_vx, signed_vy).length()
	var buckets := {
		"none": 0.0,
		"up": 0.0,
		"down": 0.0,
		"left": 0.0,
		"right": 0.0,
	}
	if speed <= min_speed:
		buckets["none"] = 1.0
		return buckets
	if absf(signed_vx) >= absf(signed_vy):
		buckets["right" if signed_vx >= 0.0 else "left"] = 1.0
	else:
		buckets["up" if signed_vy >= 0.0 else "down"] = 1.0
	return buckets

func _score_current_window() -> Dictionary:
	var prototypes: Array = (_library.get("prototypes", []) as Array).duplicate(true)
	var candidate_windows := _build_candidate_windows()
	var class_scores: Dictionary = {}
	var class_winner_by_class: Dictionary = {}
	for gesture_class in SUPPORTED_CLASSES:
		class_scores[String(gesture_class)] = 0.0
	var best_class := OUTCOME_NO_PUNCH
	var best_score := 0.0
	var best_prototype_id := ""
	var best_prototype_side := ""
	var best_window_sample_count := _sample_history.size()
	var best_window_span_ms := _resolve_window_span_ms(_sample_history)
	var top_matches: Array = []
	for candidate_variant in candidate_windows:
		if not candidate_variant is Dictionary:
			continue
		var candidate: Dictionary = candidate_variant
		var samples: Array = candidate.get("samples", []) if candidate.get("samples", []) is Array else []
		var runtime_by_side := {
			"left": _resample_side_window("left", _get_library_sample_count(), samples),
			"right": _resample_side_window("right", _get_library_sample_count(), samples),
		}
		for prototype_variant in prototypes:
			if not prototype_variant is Dictionary:
				continue
			var prototype: Dictionary = prototype_variant
			var gesture_class := String(prototype.get("class_name", ""))
			var side := String(prototype.get("side", ""))
			if not class_scores.has(gesture_class):
				continue
			var runtime_series: Array = runtime_by_side.get(side, []) if runtime_by_side.get(side, []) is Array else []
			var prototype_series: Array = prototype.get("samples", []) if prototype.get("samples", []) is Array else []
			if runtime_series.is_empty() or prototype_series.is_empty():
				continue
			var score := _score_series(runtime_series, prototype_series)
			var prototype_id := String(prototype.get("id", ""))
			class_scores[gesture_class] = maxf(float(class_scores.get(gesture_class, 0.0)), score)
			var class_winner: Dictionary = class_winner_by_class.get(gesture_class, {}) if class_winner_by_class.get(gesture_class, {}) is Dictionary else {}
			if class_winner.is_empty() or score > float(class_winner.get("score", 0.0)):
				class_winner_by_class[gesture_class] = {
					"class_name": gesture_class,
					"prototype_id": prototype_id,
					"prototype_side": side,
					"score": score,
					"window_sample_count": int(candidate.get("sample_count", samples.size())),
					"window_span_ms": int(candidate.get("span_ms", _resolve_window_span_ms(samples))),
				}
			_append_top_match(top_matches, {
				"class_name": gesture_class,
				"prototype_id": prototype_id,
				"prototype_side": side,
				"score": score,
				"window_sample_count": int(candidate.get("sample_count", samples.size())),
				"window_span_ms": int(candidate.get("span_ms", _resolve_window_span_ms(samples))),
			})
			if score > best_score:
				best_score = score
				best_class = gesture_class
				best_prototype_id = prototype_id
				best_prototype_side = side
				best_window_sample_count = int(candidate.get("sample_count", samples.size()))
				best_window_span_ms = int(candidate.get("span_ms", _resolve_window_span_ms(samples)))
	var runner_up_class := OUTCOME_NO_PUNCH
	var runner_up_score := 0.0
	var runner_up_prototype_id := ""
	for gesture_class in SUPPORTED_CLASSES:
		var class_winner: Dictionary = class_winner_by_class.get(gesture_class, {}) if class_winner_by_class.get(gesture_class, {}) is Dictionary else {}
		var class_score := float(class_winner.get("score", 0.0))
		if gesture_class == best_class:
			continue
		if class_score > runner_up_score:
			runner_up_class = gesture_class
			runner_up_score = class_score
			runner_up_prototype_id = String(class_winner.get("prototype_id", ""))
	return {
		"class_scores": class_scores,
		"best_class": best_class,
		"best_score": best_score,
		"best_prototype_id": best_prototype_id,
		"best_prototype_side": best_prototype_side,
		"runner_up_class": runner_up_class,
		"runner_up_score": runner_up_score,
		"runner_up_prototype_id": runner_up_prototype_id,
		"best_class_margin": maxf(0.0, best_score - runner_up_score),
		"class_winner_by_class": class_winner_by_class,
		"top_matches": top_matches,
		"window_sample_count": best_window_sample_count,
		"window_span_ms": best_window_span_ms,
	}

func _append_top_match(top_matches: Array, match: Dictionary, limit: int = 5) -> void:
	top_matches.append(match.duplicate(true))
	top_matches.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return float(a.get("score", 0.0)) > float(b.get("score", 0.0))
	)
	while top_matches.size() > limit:
		top_matches.pop_back()

func _score_series(runtime_series: Array, prototype_series: Array) -> float:
	var sample_count := mini(runtime_series.size(), prototype_series.size())
	if sample_count <= 0:
		return 0.0
	var total_distance := 0.0
	var compared := 0
	for idx in range(sample_count):
		var runtime_features: Array = runtime_series[idx] as Array
		var prototype_features: Array = prototype_series[idx] as Array
		var feature_count := mini(runtime_features.size(), prototype_features.size())
		if feature_count <= 0:
			continue
		var frame_distance := 0.0
		for feature_idx in range(feature_count):
			frame_distance += absf(float(runtime_features[feature_idx]) - float(prototype_features[feature_idx]))
		total_distance += frame_distance / float(feature_count)
		compared += 1
	if compared <= 0:
		return 0.0
	var average_distance := total_distance / float(compared)
	var score := 1.0 - (average_distance / _get_distance_scale())
	return clampf(score, 0.0, 1.0)

func _build_candidate_windows() -> Array:
	var minimum_sample_count := _get_library_sample_count()
	if _sample_history.size() <= minimum_sample_count:
		return [{
			"samples": _sample_history.duplicate(true),
			"sample_count": _sample_history.size(),
			"span_ms": _resolve_window_span_ms(_sample_history),
		}]
	var windows: Array = []
	for start_idx in range(0, _sample_history.size() - minimum_sample_count + 1):
		var samples := _sample_history.slice(start_idx, _sample_history.size())
		windows.append({
			"samples": samples,
			"sample_count": samples.size(),
			"span_ms": _resolve_window_span_ms(samples),
		})
	return windows

func _resample_side_window(side: String, target_count: int, samples: Array = _sample_history) -> Array:
	var series: Array = []
	for sample_variant in samples:
		if not sample_variant is Dictionary:
			continue
		var sample: Dictionary = sample_variant
		var side_value: Variant = sample.get(side, [])
		var features: Variant = []
		if side_value is Dictionary:
			features = (side_value as Dictionary).get("features", [])
		else:
			features = side_value
		if features is Array and (features as Array).size() == _get_feature_count():
			series.append((features as Array).duplicate(true))
	if series.is_empty() or target_count <= 0:
		return []
	if series.size() == target_count:
		return series
	var result: Array = []
	if target_count == 1:
		result.append((series[series.size() - 1] as Array).duplicate(true))
		return result
	for idx in range(target_count):
		var t := float(idx) / float(target_count - 1)
		var source_index := int(round(t * float(series.size() - 1)))
		source_index = clampi(source_index, 0, series.size() - 1)
		result.append((series[source_index] as Array).duplicate(true))
	return result

func _class_to_event_name(gesture_class: String) -> String:
	match gesture_class:
		"straight_left":
			return "punch_left"
		"straight_right":
			return "punch_right"
		"hook_left":
			return "hook_left"
		"hook_right":
			return "hook_right"
		"uppercut_left":
			return "uppercut_left"
		"uppercut_right":
			return "uppercut_right"
		_:
			return ""

func _get_gesture_profile_document() -> Dictionary:
	if _config == null:
		return {}
	var gesture_profile_document: Variant = _config.get("gesture_profile_document") if _config.has_method("get") else null
	return gesture_profile_document if gesture_profile_document is Dictionary else {}

func _get_selected_backend() -> String:
	return BACKEND_PROTOTYPE_MATCHER if _is_enabled_in_config() else ""

func _is_enabled_in_config() -> bool:
	return not _get_selected_families_for_backend(BACKEND_PROTOTYPE_MATCHER).is_empty()

func _is_selected_backend_enabled() -> bool:
	return _is_enabled_in_config()

func _is_active_backend() -> bool:
	return _is_enabled_in_config()

func _get_activation_reason() -> String:
	if _is_active_backend():
		return "active"
	return "backend_not_selected"

func _normalize_backend_name(backend_name: String) -> String:
	match backend_name.strip_edges().to_lower():
		BACKEND_DISABLED:
			return BACKEND_DISABLED
		BACKEND_THRESHOLD_GATES:
			return BACKEND_THRESHOLD_GATES
		BACKEND_PROTOTYPE_MATCHER:
			return BACKEND_PROTOTYPE_MATCHER
		BACKEND_CLASSIFIER:
			return BACKEND_CLASSIFIER
		_:
			return BACKEND_THRESHOLD_GATES

func _get_selected_families_for_backend(backend_name: String) -> Array[String]:
	var result: Array[String] = []
	for family_variant in PUNCH_FAMILIES:
		var family := String(family_variant)
		if _get_family_backend(family) == backend_name:
			result.append(family)
	return result

func _get_family_backend(family: String) -> String:
	var gesture_profile_document := _get_gesture_profile_document()
	var family_document: Dictionary = gesture_profile_document.get(family, {}) if gesture_profile_document.get(family, {}) is Dictionary else {}
	var backend := String(family_document.get("backend", "")).strip_edges()
	if backend == "":
		return BACKEND_THRESHOLD_GATES
	return _normalize_backend_name(backend)

func _get_family_backend_config(family: String, backend_name: String) -> Dictionary:
	var gesture_profile_document := _get_gesture_profile_document()
	var family_document: Dictionary = gesture_profile_document.get(family, {}) if gesture_profile_document.get(family, {}) is Dictionary else {}
	var backend_document: Dictionary = family_document.get(backend_name, {}) if family_document.get(backend_name, {}) is Dictionary else {}
	if not backend_document.is_empty():
		return backend_document
	return family_document

func _get_primary_family_backend_config(backend_name: String) -> Dictionary:
	var selected_families := _get_selected_families_for_backend(backend_name)
	for family in ["straight_punch", "hook", "uppercut"]:
		if selected_families.has(family):
			return _get_family_backend_config(family, backend_name)
	return _get_family_backend_config("straight_punch", backend_name)

func _get_library_id() -> String:
	var matcher := _get_primary_family_backend_config(BACKEND_PROTOTYPE_MATCHER)
	var prototype_library: Dictionary = matcher.get("prototype_library", {}) if matcher.get("prototype_library", {}) is Dictionary else {}
	var library_id := String(prototype_library.get("library_id", DEFAULT_LIBRARY_ID))
	return library_id if library_id != "" else DEFAULT_LIBRARY_ID

func _get_window_ms() -> int:
	var matcher := _get_primary_family_backend_config(BACKEND_PROTOTYPE_MATCHER)
	var evaluation: Dictionary = matcher.get("evaluation", {}) if matcher.get("evaluation", {}) is Dictionary else {}
	return max(1, int(evaluation.get("window_ms", DEFAULT_WINDOW_MS)))

func _get_window_step_ms() -> int:
	var matcher := _get_primary_family_backend_config(BACKEND_PROTOTYPE_MATCHER)
	var evaluation: Dictionary = matcher.get("evaluation", {}) if matcher.get("evaluation", {}) is Dictionary else {}
	return max(1, int(evaluation.get("window_step_ms", DEFAULT_WINDOW_STEP_MS)))

func _get_match_score_min() -> float:
	var matcher := _get_primary_family_backend_config(BACKEND_PROTOTYPE_MATCHER)
	var thresholds: Dictionary = matcher.get("thresholds", {}) if matcher.get("thresholds", {}) is Dictionary else {}
	return clampf(float(thresholds.get("match_score_min", DEFAULT_MATCH_SCORE_MIN)), 0.0, 1.0)

func _get_emit_cooldown_ms() -> int:
	var matcher := _get_primary_family_backend_config(BACKEND_PROTOTYPE_MATCHER)
	var timing: Dictionary = matcher.get("timing", {}) if matcher.get("timing", {}) is Dictionary else {}
	return max(0, int(timing.get("emit_cooldown_ms", DEFAULT_EMIT_COOLDOWN_MS)))

func _get_emit_hold_ms() -> int:
	var matcher := _get_primary_family_backend_config(BACKEND_PROTOTYPE_MATCHER)
	var timing: Dictionary = matcher.get("timing", {}) if matcher.get("timing", {}) is Dictionary else {}
	return max(0, int(timing.get("emit_hold_ms", DEFAULT_EMIT_HOLD_MS)))

func _get_show_scores() -> bool:
	var matcher_config := _get_primary_family_backend_config(BACKEND_PROTOTYPE_MATCHER)
	var debug_config: Dictionary = matcher_config.get("debug", {}) if matcher_config.get("debug", {}) is Dictionary else {}
	return bool(debug_config.get("show_scores", DEFAULT_SHOW_SCORES))

func _get_show_event_gate_state() -> bool:
	var matcher_config := _get_primary_family_backend_config(BACKEND_PROTOTYPE_MATCHER)
	var debug_config: Dictionary = matcher_config.get("debug", {}) if matcher_config.get("debug", {}) is Dictionary else {}
	return bool(debug_config.get("show_event_gate_state", DEFAULT_SHOW_EVENT_GATE_STATE))

func _get_feature_names() -> Array:
	var feature_names_variant: Variant = _library.get("feature_names", [])
	var feature_names: Array = feature_names_variant if feature_names_variant is Array else []
	var result: Array = []
	for feature_name_variant in feature_names:
		result.append(String(feature_name_variant))
	if result.is_empty():
		return [
			FEATURE_NAME_ELBOW_X_FROM_SHOULDER_OVER_SHOULDER_WIDTH,
			FEATURE_NAME_ELBOW_Y_FROM_SHOULDER_OVER_SHOULDER_WIDTH,
			FEATURE_NAME_WRIST_X_FROM_SHOULDER_OVER_SHOULDER_WIDTH,
			FEATURE_NAME_WRIST_Y_FROM_SHOULDER_OVER_SHOULDER_WIDTH,
		]
	return result

func _get_feature_count() -> int:
	return max(1, _get_feature_names().size())

func _get_library_sample_count() -> int:
	return max(1, int(_library.get("sample_count", 5)))

func _get_distance_scale() -> float:
	return maxf(0.000001, float(_library.get("distance_scale", DEFAULT_DISTANCE_SCALE)))
