class_name PrototypePunchMatcher
extends RefCounted

const PoseLandmarkIds = preload("res://addons/aerobeat-input-camera-tracking/src/detectors/pose_landmark_ids.gd")
const PoseMetrics = preload("res://addons/aerobeat-input-camera-tracking/src/detectors/pose_metrics.gd")

const BACKEND_THRESHOLD_GATES := "threshold_gates"
const BACKEND_PROTOTYPE_MATCHER := "prototype_matcher"
const OUTCOME_NO_PUNCH := "no_punch"
const DEFAULT_WINDOW_MS := 250
const DEFAULT_WINDOW_STEP_MS := 33
const DEFAULT_MATCH_SCORE_MIN := 0.70
const DEFAULT_EMIT_COOLDOWN_MS := 250
const DEFAULT_EMIT_HOLD_MS := 100
const DEFAULT_SHOW_SCORES := true
const DEFAULT_SHOW_EVENT_GATE_STATE := true
const DEFAULT_LIBRARY_ID := "boxing_side_aware_v1"
const FEATURE_COUNT := 6
const DEFAULT_DISTANCE_SCALE := 0.45
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
	debug_state["active_backend"] = BACKEND_PROTOTYPE_MATCHER if _is_active_backend() else "inactive"
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
	debug_state["active_backend"] = BACKEND_PROTOTYPE_MATCHER if _is_active_backend() else "inactive"
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

	var sample := _extract_runtime_sample(landmarks_by_id, metrics)
	if sample.is_empty():
		debug_state["reason"] = "pose_invalid"
		_last_debug_state = debug_state
		return events
	_sample_history.append({
		"timestamp_ms": timestamp_ms,
		"left": (sample.get("left", {}) as Array).duplicate(true),
		"right": (sample.get("right", {}) as Array).duplicate(true),
	})
	_prune_sample_history(timestamp_ms)
	debug_state["window_sample_count"] = _sample_history.size()
	debug_state["window_span_ms"] = _resolve_window_span_ms()
	if _sample_history.is_empty() or int(debug_state.get("window_span_ms", 0)) < _get_window_ms():
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
	var class_scores: Dictionary = score_result.get("class_scores", {}) if score_result.get("class_scores", {}) is Dictionary else {}
	var best_class := String(score_result.get("best_class", OUTCOME_NO_PUNCH))
	var best_score := float(score_result.get("best_score", 0.0))
	debug_state["class_scores"] = class_scores.duplicate(true)
	debug_state["best_class"] = best_class
	debug_state["best_score"] = best_score
	debug_state["required_score"] = _get_match_score_min()
	if best_score + 0.000001 < _get_match_score_min() or best_class == OUTCOME_NO_PUNCH:
		debug_state["result_class"] = OUTCOME_NO_PUNCH
		debug_state["reason"] = "below_threshold"
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
		"active_backend": BACKEND_PROTOTYPE_MATCHER if _is_active_backend() else "inactive",
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
		"last_eval_timestamp_ms": _last_eval_timestamp_ms,
		"last_emit_timestamp_ms": _last_emit_timestamp_ms,
		"best_class": OUTCOME_NO_PUNCH,
		"best_score": 0.0,
		"required_score": _get_match_score_min(),
		"result_class": OUTCOME_NO_PUNCH,
		"reason": "idle",
		"class_scores": {},
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

func _resolve_window_span_ms() -> int:
	if _sample_history.size() < 2:
		return 0
	return int((_sample_history[_sample_history.size() - 1] as Dictionary).get("timestamp_ms", 0)) - int((_sample_history[0] as Dictionary).get("timestamp_ms", 0))

func _extract_runtime_sample(landmarks_by_id: Dictionary, metrics: Dictionary) -> Dictionary:
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
		"left": _extract_side_features(left_shoulder, left_elbow, left_wrist, shoulder_width),
		"right": _extract_side_features(right_shoulder, right_elbow, right_wrist, shoulder_width),
	}

func _extract_side_features(shoulder: Dictionary, elbow: Dictionary, wrist: Dictionary, shoulder_width: float) -> Array:
	return [
		(float(elbow.get("x", 0.0)) - float(shoulder.get("x", 0.0))) / shoulder_width,
		(float(elbow.get("y", 0.0)) - float(shoulder.get("y", 0.0))) / shoulder_width,
		(float(wrist.get("x", 0.0)) - float(shoulder.get("x", 0.0))) / shoulder_width,
		(float(wrist.get("y", 0.0)) - float(shoulder.get("y", 0.0))) / shoulder_width,
		float(elbow.get("z", 0.0)) - float(shoulder.get("z", 0.0)),
		float(wrist.get("z", 0.0)) - float(shoulder.get("z", 0.0)),
	]

func _score_current_window() -> Dictionary:
	var prototypes: Array = (_library.get("prototypes", []) as Array).duplicate(true)
	var runtime_by_side := {
		"left": _resample_side_window("left", _get_library_sample_count()),
		"right": _resample_side_window("right", _get_library_sample_count()),
	}
	var class_scores: Dictionary = {}
	for gesture_class in SUPPORTED_CLASSES:
		class_scores[String(gesture_class)] = 0.0
	var best_class := OUTCOME_NO_PUNCH
	var best_score := 0.0
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
		class_scores[gesture_class] = maxf(float(class_scores.get(gesture_class, 0.0)), score)
		if score > best_score:
			best_score = score
			best_class = gesture_class
	return {
		"class_scores": class_scores,
		"best_class": best_class,
		"best_score": best_score,
	}

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

func _resample_side_window(side: String, target_count: int) -> Array:
	var series: Array = []
	for sample_variant in _sample_history:
		if not sample_variant is Dictionary:
			continue
		var sample: Dictionary = sample_variant
		var features: Variant = sample.get(side, [])
		if features is Array and (features as Array).size() == FEATURE_COUNT:
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
	var gesture_profile_document := _get_gesture_profile_document()
	var punch_detection: Dictionary = gesture_profile_document.get("punch_detection", {}) if gesture_profile_document.get("punch_detection", {}) is Dictionary else {}
	return String(punch_detection.get("backend", BACKEND_THRESHOLD_GATES))

func _is_enabled_in_config() -> bool:
	var gesture_profile_document := _get_gesture_profile_document()
	var matcher: Dictionary = gesture_profile_document.get("prototype_matcher", {}) if gesture_profile_document.get("prototype_matcher", {}) is Dictionary else {}
	return bool(matcher.get("enabled", false))

func _is_active_backend() -> bool:
	return _get_selected_backend() == BACKEND_PROTOTYPE_MATCHER and _is_enabled_in_config()

func _get_library_id() -> String:
	var gesture_profile_document := _get_gesture_profile_document()
	var matcher: Dictionary = gesture_profile_document.get("prototype_matcher", {}) if gesture_profile_document.get("prototype_matcher", {}) is Dictionary else {}
	var prototype_library: Dictionary = matcher.get("prototype_library", {}) if matcher.get("prototype_library", {}) is Dictionary else {}
	var library_id := String(prototype_library.get("library_id", DEFAULT_LIBRARY_ID))
	return library_id if library_id != "" else DEFAULT_LIBRARY_ID

func _get_window_ms() -> int:
	var gesture_profile_document := _get_gesture_profile_document()
	var matcher: Dictionary = gesture_profile_document.get("prototype_matcher", {}) if gesture_profile_document.get("prototype_matcher", {}) is Dictionary else {}
	var evaluation: Dictionary = matcher.get("evaluation", {}) if matcher.get("evaluation", {}) is Dictionary else {}
	return max(1, int(evaluation.get("window_ms", DEFAULT_WINDOW_MS)))

func _get_window_step_ms() -> int:
	var gesture_profile_document := _get_gesture_profile_document()
	var matcher: Dictionary = gesture_profile_document.get("prototype_matcher", {}) if gesture_profile_document.get("prototype_matcher", {}) is Dictionary else {}
	var evaluation: Dictionary = matcher.get("evaluation", {}) if matcher.get("evaluation", {}) is Dictionary else {}
	return max(1, int(evaluation.get("window_step_ms", DEFAULT_WINDOW_STEP_MS)))

func _get_match_score_min() -> float:
	var gesture_profile_document := _get_gesture_profile_document()
	var matcher: Dictionary = gesture_profile_document.get("prototype_matcher", {}) if gesture_profile_document.get("prototype_matcher", {}) is Dictionary else {}
	var thresholds: Dictionary = matcher.get("thresholds", {}) if matcher.get("thresholds", {}) is Dictionary else {}
	return clampf(float(thresholds.get("match_score_min", DEFAULT_MATCH_SCORE_MIN)), 0.0, 1.0)

func _get_emit_cooldown_ms() -> int:
	var gesture_profile_document := _get_gesture_profile_document()
	var matcher: Dictionary = gesture_profile_document.get("prototype_matcher", {}) if gesture_profile_document.get("prototype_matcher", {}) is Dictionary else {}
	var timing: Dictionary = matcher.get("timing", {}) if matcher.get("timing", {}) is Dictionary else {}
	return max(0, int(timing.get("emit_cooldown_ms", DEFAULT_EMIT_COOLDOWN_MS)))

func _get_emit_hold_ms() -> int:
	var gesture_profile_document := _get_gesture_profile_document()
	var matcher: Dictionary = gesture_profile_document.get("prototype_matcher", {}) if gesture_profile_document.get("prototype_matcher", {}) is Dictionary else {}
	var timing: Dictionary = matcher.get("timing", {}) if matcher.get("timing", {}) is Dictionary else {}
	return max(0, int(timing.get("emit_hold_ms", DEFAULT_EMIT_HOLD_MS)))

func _get_show_scores() -> bool:
	var gesture_profile_document := _get_gesture_profile_document()
	var matcher_config: Dictionary = gesture_profile_document.get("prototype_matcher", {}) if gesture_profile_document.get("prototype_matcher", {}) is Dictionary else {}
	var debug_config: Dictionary = matcher_config.get("debug", {}) if matcher_config.get("debug", {}) is Dictionary else {}
	return bool(debug_config.get("show_scores", DEFAULT_SHOW_SCORES))

func _get_show_event_gate_state() -> bool:
	var gesture_profile_document := _get_gesture_profile_document()
	var matcher_config: Dictionary = gesture_profile_document.get("prototype_matcher", {}) if gesture_profile_document.get("prototype_matcher", {}) is Dictionary else {}
	var debug_config: Dictionary = matcher_config.get("debug", {}) if matcher_config.get("debug", {}) is Dictionary else {}
	return bool(debug_config.get("show_event_gate_state", DEFAULT_SHOW_EVENT_GATE_STATE))

func _get_library_sample_count() -> int:
	return max(1, int(_library.get("sample_count", 5)))

func _get_distance_scale() -> float:
	return maxf(0.000001, float(_library.get("distance_scale", DEFAULT_DISTANCE_SCALE)))
