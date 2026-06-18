class_name LearnedPunchClassifier
extends "res://addons/aerobeat-input-camera-tracking/src/detectors/prototype_punch_matcher.gd"

const BACKEND_LEARNED_CLASSIFIER := "learned_classifier"
const LEARNED_DEFAULT_WINDOW_MS := 250
const LEARNED_DEFAULT_WINDOW_STEP_MS := 33
const LEARNED_DEFAULT_MATCH_SCORE_MIN := 0.70
const LEARNED_DEFAULT_EMIT_COOLDOWN_MS := 250
const LEARNED_DEFAULT_EMIT_HOLD_MS := 100
const LEARNED_DEFAULT_SHOW_SCORES := true
const LEARNED_DEFAULT_SHOW_EVENT_GATE_STATE := true
const ADDON_ROOT_PATH := "res://addons/aerobeat-input-camera-tracking"
const REPO_ROOT_DOCS_PREFIX := "res://docs/"
const ADDON_ROOT_DOCS_PREFIX := "res://addons/aerobeat-input-camera-tracking/docs/"
const DEFAULT_MODEL_ARTIFACT_PATH := "res://addons/aerobeat-input-camera-tracking/docs/baselines/boxing-punch-classifier-frozen-benchmark-mlp-vs-cnn-2026-06-16/mlp/mlp-result.json"
const EXPECTED_SCHEMA := "aerobeat.boxing_punch_classifier_mlp_result"
const DEFAULT_CLASS_ORDER := [
	"straight_left",
	"straight_right",
	"hook_left",
	"hook_right",
	"uppercut_left",
	"uppercut_right",
	"no_punch",
]
const DEFAULT_FEATURE_NAMES := [
	FEATURE_NAME_SHOULDER_X,
	FEATURE_NAME_SHOULDER_Y,
	FEATURE_NAME_ELBOW_X,
	FEATURE_NAME_ELBOW_Y,
	FEATURE_NAME_WRIST_X,
	FEATURE_NAME_WRIST_Y,
	FEATURE_NAME_COMBINED_ELBOW_WRIST_VELOCITY_XY_MAGNITUDE,
	FEATURE_NAME_ELBOW_SHOULDER_XY_DISTANCE_OVER_SHOULDER_WIDTH,
]
const DEFAULT_FRAME_FEATURE_NAMES := [
	"left_shoulder_x",
	"left_shoulder_y",
	"left_elbow_x",
	"left_elbow_y",
	"left_wrist_x",
	"left_wrist_y",
	"left_combined_elbow_wrist_velocity_xy_magnitude",
	"left_elbow_shoulder_xy_distance_over_shoulder_width",
	"right_shoulder_x",
	"right_shoulder_y",
	"right_elbow_x",
	"right_elbow_y",
	"right_wrist_x",
	"right_wrist_y",
	"right_combined_elbow_wrist_velocity_xy_magnitude",
	"right_elbow_shoulder_xy_distance_over_shoulder_width",
]

var _model_document: Dictionary = {}
var _model_path := ""
var _model_error := ""
var _resolved_class_order: Array = DEFAULT_CLASS_ORDER.duplicate(true)
var _resolved_feature_set := "baseline_v1"
var _resolved_side_feature_names: Array = DEFAULT_FEATURE_NAMES.duplicate(true)
var _resolved_frame_feature_names: Array = DEFAULT_FRAME_FEATURE_NAMES.duplicate(true)
var _resolved_frame_count := 8
var _resolved_frame_feature_count := 16
var _last_scored_best_class := OUTCOME_NO_PUNCH
var _last_scored_best_score := 0.0
var _last_scored_runner_up_class := OUTCOME_NO_PUNCH
var _last_scored_runner_up_score := 0.0
var _last_scored_result_class := OUTCOME_NO_PUNCH
var _last_scored_emitted_event_name := ""
var _last_scored_class_scores: Dictionary = {}
var _last_scored_evaluated_window_sample_count := 0
var _last_scored_evaluated_window_span_ms := 0

func configure(config) -> LearnedPunchClassifier:
	_config = config
	_load_model_if_needed()
	_last_debug_state = _build_debug_state()
	return self

func reset() -> void:
	_sample_history.clear()
	_last_eval_timestamp_ms = 0
	_last_emit_timestamp_ms = -1
	_last_emitted_class = OUTCOME_NO_PUNCH
	_emit_cooldown_until_ms = 0
	_emit_hold_until_ms = 0
	_last_scored_best_class = OUTCOME_NO_PUNCH
	_last_scored_best_score = 0.0
	_last_scored_runner_up_class = OUTCOME_NO_PUNCH
	_last_scored_runner_up_score = 0.0
	_last_scored_result_class = OUTCOME_NO_PUNCH
	_last_scored_emitted_event_name = ""
	_last_scored_class_scores = {}
	_last_scored_evaluated_window_sample_count = 0
	_last_scored_evaluated_window_span_ms = 0
	_last_debug_state = _build_debug_state()

func get_debug_state() -> Dictionary:
	var debug_state := _last_debug_state.duplicate(true)
	debug_state["enabled"] = _is_enabled_in_config()
	debug_state["selected_backend"] = _get_selected_backend()
	debug_state["selected_backend_enabled"] = _is_selected_backend_enabled()
	debug_state["active_backend"] = BACKEND_LEARNED_CLASSIFIER if _is_active_backend() else "none"
	debug_state["activation_reason"] = _get_activation_reason()
	debug_state["model_path"] = _model_path
	debug_state["model_loaded"] = _model_error == "" and not _model_document.is_empty()
	debug_state["model_error"] = _model_error
	debug_state["model_schema"] = String(_model_document.get("schema", ""))
	debug_state["match_score_min"] = _get_match_score_min()
	debug_state["emit_cooldown_ms"] = _get_emit_cooldown_ms()
	debug_state["emit_hold_ms"] = _get_emit_hold_ms()
	debug_state["cooldown_ms_remaining"] = max(0, _emit_cooldown_until_ms - int(debug_state.get("current_timestamp_ms", 0)))
	debug_state["hold_ms_remaining"] = max(0, _emit_hold_until_ms - int(debug_state.get("current_timestamp_ms", 0)))
	debug_state["show_scores"] = _get_show_scores()
	debug_state["show_event_gate_state"] = _get_show_event_gate_state()
	debug_state["frame_count"] = _get_frame_count()
	debug_state["frame_feature_count"] = _get_frame_feature_count()
	debug_state["class_order"] = _resolved_class_order.duplicate(true)
	debug_state["feature_set"] = _resolved_feature_set
	debug_state["side_feature_names"] = _resolved_side_feature_names.duplicate(true)
	debug_state["frame_feature_names"] = _resolved_frame_feature_names.duplicate(true)
	return debug_state

func process_window(landmarks_by_id: Dictionary, metrics: Dictionary, timestamp_ms: int) -> Array:
	_load_model_if_needed()
	var events: Array = []
	var debug_state := _build_debug_state()
	_apply_persisted_classifier_truth(debug_state)
	debug_state["current_timestamp_ms"] = timestamp_ms
	debug_state["selected_backend"] = _get_selected_backend()
	debug_state["selected_backend_enabled"] = _is_selected_backend_enabled()
	debug_state["active_backend"] = BACKEND_LEARNED_CLASSIFIER if _is_active_backend() else "none"
	debug_state["activation_reason"] = _get_activation_reason()
	debug_state["model_path"] = _model_path
	debug_state["model_loaded"] = _model_error == "" and not _model_document.is_empty()
	debug_state["model_error"] = _model_error
	debug_state["model_schema"] = String(_model_document.get("schema", ""))
	debug_state["frame_count"] = _get_frame_count()
	debug_state["frame_feature_count"] = _get_frame_feature_count()
	debug_state["class_order"] = _resolved_class_order.duplicate(true)
	debug_state["feature_set"] = _resolved_feature_set
	debug_state["side_feature_names"] = _resolved_side_feature_names.duplicate(true)
	debug_state["frame_feature_names"] = _resolved_frame_feature_names.duplicate(true)
	debug_state["match_score_min"] = _get_match_score_min()
	debug_state["emit_cooldown_ms"] = _get_emit_cooldown_ms()
	debug_state["emit_hold_ms"] = _get_emit_hold_ms()
	debug_state["show_scores"] = _get_show_scores()
	debug_state["show_event_gate_state"] = _get_show_event_gate_state()
	debug_state["reason"] = "inactive"
	debug_state["emitted"] = false
	debug_state["cooldown_ms_remaining"] = max(0, _emit_cooldown_until_ms - timestamp_ms)
	debug_state["hold_ms_remaining"] = max(0, _emit_hold_until_ms - timestamp_ms)
	debug_state["active_event_class"] = _last_emitted_class if timestamp_ms < _emit_hold_until_ms else OUTCOME_NO_PUNCH
	debug_state["last_emit_timestamp_ms"] = _last_emit_timestamp_ms
	debug_state["required_score"] = _get_match_score_min()

	if not _is_active_backend():
		_last_debug_state = debug_state
		return events
	if _model_error != "" or _model_document.is_empty():
		debug_state["reason"] = "model_unavailable"
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
		"left": (left_sample.get("features", []) as Array).duplicate(true),
		"right": (right_sample.get("features", []) as Array).duplicate(true),
		"left_signal_position": left_sample.get("signal_position", Vector2.ZERO),
		"right_signal_position": right_sample.get("signal_position", Vector2.ZERO),
	})
	_prune_sample_history(timestamp_ms)
	debug_state["window_sample_count"] = _sample_history.size()
	debug_state["window_span_ms"] = _resolve_window_span_ms(_sample_history)
	debug_state["window_ready_sample_count"] = _get_frame_count()
	if _sample_history.size() < _get_frame_count():
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
	var runner_up_class := String(score_result.get("runner_up_class", OUTCOME_NO_PUNCH))
	var runner_up_score := float(score_result.get("runner_up_score", 0.0))
	debug_state["class_scores"] = class_scores.duplicate(true)
	debug_state["best_class"] = best_class
	debug_state["best_score"] = best_score
	debug_state["runner_up_class"] = runner_up_class
	debug_state["runner_up_score"] = runner_up_score
	debug_state["required_score"] = _get_match_score_min()
	if best_score + 0.000001 < _get_match_score_min() or best_class == OUTCOME_NO_PUNCH:
		debug_state["result_class"] = OUTCOME_NO_PUNCH
		_persist_scored_classifier_truth(
			best_class,
			best_score,
			runner_up_class,
			runner_up_score,
			class_scores,
			OUTCOME_NO_PUNCH,
			"",
			int(debug_state.get("evaluated_window_sample_count", 0)),
			int(debug_state.get("evaluated_window_span_ms", 0))
		)
		debug_state["reason"] = "below_threshold" if best_class != OUTCOME_NO_PUNCH else "no_punch"
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
		"backend": BACKEND_LEARNED_CLASSIFIER,
		"learned_classifier": {
			"class_name": best_class,
			"score": best_score,
			"runner_up_class": runner_up_class,
			"runner_up_score": runner_up_score,
			"threshold": _get_match_score_min(),
			"model_path": _model_path,
		},
	})
	debug_state["result_class"] = best_class
	debug_state["reason"] = "emitted"
	debug_state["emitted"] = true
	debug_state["emitted_event_name"] = event_name
	_persist_scored_classifier_truth(
		best_class,
		best_score,
		runner_up_class,
		runner_up_score,
		class_scores,
		best_class,
		event_name,
		int(debug_state.get("evaluated_window_sample_count", 0)),
		int(debug_state.get("evaluated_window_span_ms", 0))
	)
	debug_state["cooldown_ms_remaining"] = _emit_cooldown_until_ms - timestamp_ms
	debug_state["hold_ms_remaining"] = _emit_hold_until_ms - timestamp_ms
	debug_state["active_event_class"] = best_class
	_last_debug_state = debug_state
	return events

func _apply_persisted_classifier_truth(debug_state: Dictionary) -> void:
	debug_state["best_class"] = _last_scored_best_class
	debug_state["best_score"] = _last_scored_best_score
	debug_state["runner_up_class"] = _last_scored_runner_up_class
	debug_state["runner_up_score"] = _last_scored_runner_up_score
	debug_state["required_score"] = _get_match_score_min()
	debug_state["result_class"] = _last_scored_result_class
	debug_state["emitted_event_name"] = _last_scored_emitted_event_name
	debug_state["class_scores"] = _last_scored_class_scores.duplicate(true)
	debug_state["evaluated_window_sample_count"] = _last_scored_evaluated_window_sample_count
	debug_state["evaluated_window_span_ms"] = _last_scored_evaluated_window_span_ms

func _persist_scored_classifier_truth(
	best_class: String,
	best_score: float,
	runner_up_class: String,
	runner_up_score: float,
	class_scores: Dictionary,
	result_class: String,
	emitted_event_name: String,
	evaluated_window_sample_count: int,
	evaluated_window_span_ms: int
) -> void:
	_last_scored_best_class = best_class
	_last_scored_best_score = best_score
	_last_scored_runner_up_class = runner_up_class
	_last_scored_runner_up_score = runner_up_score
	_last_scored_result_class = result_class
	_last_scored_emitted_event_name = emitted_event_name
	_last_scored_class_scores = class_scores.duplicate(true)
	_last_scored_evaluated_window_sample_count = evaluated_window_sample_count
	_last_scored_evaluated_window_span_ms = evaluated_window_span_ms

func _build_debug_state() -> Dictionary:
	var model_document: Dictionary = _model_document if _model_document is Dictionary else {}
	var model_path := String(_model_path) if typeof(_model_path) == TYPE_STRING else ""
	var model_error := String(_model_error) if typeof(_model_error) == TYPE_STRING else ""
	var class_order := _resolved_class_order.duplicate(true) if _resolved_class_order is Array else DEFAULT_CLASS_ORDER.duplicate(true)
	return {
		"enabled": _is_enabled_in_config(),
		"selected_backend": _get_selected_backend(),
		"selected_backend_enabled": _is_selected_backend_enabled(),
		"active_backend": BACKEND_LEARNED_CLASSIFIER if _is_active_backend() else "none",
		"activation_reason": _get_activation_reason(),
		"model_path": model_path,
		"model_loaded": model_error == "" and not model_document.is_empty(),
		"model_error": model_error,
		"model_schema": String(model_document.get("schema", "")),
		"frame_count": _get_frame_count(),
		"frame_feature_count": _get_frame_feature_count(),
		"class_order": class_order,
		"match_score_min": _get_match_score_min(),
		"emit_cooldown_ms": _get_emit_cooldown_ms(),
		"emit_hold_ms": _get_emit_hold_ms(),
		"window_sample_count": 0,
		"window_span_ms": 0,
		"window_ready_sample_count": _get_frame_count(),
		"evaluated_window_sample_count": 0,
		"evaluated_window_span_ms": 0,
		"last_eval_timestamp_ms": _last_eval_timestamp_ms,
		"last_emit_timestamp_ms": _last_emit_timestamp_ms,
		"current_timestamp_ms": 0,
		"cooldown_ms_remaining": 0,
		"hold_ms_remaining": 0,
		"best_class": OUTCOME_NO_PUNCH,
		"best_score": 0.0,
		"runner_up_class": OUTCOME_NO_PUNCH,
		"runner_up_score": 0.0,
		"required_score": _get_match_score_min(),
		"result_class": OUTCOME_NO_PUNCH,
		"reason": "idle",
		"emitted": false,
		"emitted_event_name": "",
		"active_event_class": OUTCOME_NO_PUNCH,
		"class_scores": {},
		"show_scores": _get_show_scores(),
		"show_event_gate_state": _get_show_event_gate_state(),
	}

func _load_model_if_needed() -> void:
	var model_path := _resolve_model_path(_get_model_artifact_path())
	if model_path == _model_path and not _model_document.is_empty() and _model_error == "":
		return
	_model_path = model_path
	_model_document.clear()
	_model_error = ""
	_resolved_class_order = DEFAULT_CLASS_ORDER.duplicate(true)
	_resolved_feature_set = "baseline_v1"
	_resolved_side_feature_names = DEFAULT_FEATURE_NAMES.duplicate(true)
	_resolved_frame_feature_names = DEFAULT_FRAME_FEATURE_NAMES.duplicate(true)
	_resolved_frame_count = 8
	_resolved_frame_feature_count = 16
	var file := FileAccess.open(_model_path, FileAccess.READ)
	if file == null:
		_model_error = "model_open_failed"
		return
	var raw_text := file.get_as_text()
	var json := JSON.new()
	var parse_error := json.parse(raw_text)
	if parse_error != OK:
		_model_error = "model_parse_failed"
		return
	var data: Variant = json.data
	if not data is Dictionary:
		_model_error = "model_invalid_root"
		return
	_model_document = (data as Dictionary).duplicate(true)
	if String(_model_document.get("schema", "")) != EXPECTED_SCHEMA:
		_model_error = "model_schema_unsupported"
		_model_document.clear()
		return
	var class_order_variant: Variant = _model_document.get("class_order", [])
	if not class_order_variant is Array or (class_order_variant as Array).is_empty():
		_model_error = "model_missing_class_order"
		_model_document.clear()
		return
	_resolved_class_order = []
	for class_name_variant in (class_order_variant as Array):
		_resolved_class_order.append(String(class_name_variant))
	var window_shape: Dictionary = _model_document.get("dataset_window_shape", {}) if _model_document.get("dataset_window_shape", {}) is Dictionary else {}
	_resolved_frame_count = max(1, int(window_shape.get("frame_count", 8)))
	_resolved_frame_feature_count = max(1, int(window_shape.get("frame_feature_count", 16)))
	_resolved_feature_set = String(_model_document.get("feature_set", _resolved_feature_set))
	var side_feature_names_variant: Variant = _model_document.get("side_feature_names", [])
	var frame_feature_names_variant: Variant = _model_document.get("frame_feature_names", [])
	if side_feature_names_variant is Array and not (side_feature_names_variant as Array).is_empty():
		_resolved_side_feature_names = []
		for feature_name_variant in (side_feature_names_variant as Array):
			_resolved_side_feature_names.append(String(feature_name_variant))
	else:
		_resolved_side_feature_names = DEFAULT_FEATURE_NAMES.duplicate(true)
	if frame_feature_names_variant is Array and not (frame_feature_names_variant as Array).is_empty():
		_resolved_frame_feature_names = []
		for feature_name_variant in (frame_feature_names_variant as Array):
			_resolved_frame_feature_names.append(String(feature_name_variant))
	else:
		_resolved_frame_feature_names = _build_frame_feature_names(_resolved_side_feature_names)
	if _resolved_side_feature_names.size() * 2 != _resolved_frame_feature_count:
		_model_error = "model_side_feature_shape_mismatch"
		_model_document.clear()
		return
	if _resolved_frame_feature_names.size() != _resolved_frame_feature_count:
		_model_error = "model_frame_feature_shape_mismatch"
		_model_document.clear()
		return
	var expected_frame_feature_names := _build_frame_feature_names(_resolved_side_feature_names)
	if expected_frame_feature_names.size() != _resolved_frame_feature_names.size():
		_model_error = "model_frame_feature_names_missing"
		_model_document.clear()
		return
	for idx in range(expected_frame_feature_names.size()):
		if String(expected_frame_feature_names[idx]) != String(_resolved_frame_feature_names[idx]):
			_model_error = "model_feature_name_order_mismatch"
			_model_document.clear()
			return
	var standardization: Dictionary = _model_document.get("standardization", {}) if _model_document.get("standardization", {}) is Dictionary else {}
	var means: Variant = standardization.get("means", [])
	var stds: Variant = standardization.get("stds", [])
	var model: Dictionary = _model_document.get("model", {}) if _model_document.get("model", {}) is Dictionary else {}
	var expected_input_dim := _resolved_frame_count * _resolved_frame_feature_count
	if not means is Array or not stds is Array or (means as Array).size() != expected_input_dim or (stds as Array).size() != expected_input_dim:
		_model_error = "model_standardization_shape_mismatch"
		_model_document.clear()
		return
	if int(model.get("input_dim", -1)) != expected_input_dim:
		_model_error = "model_input_dim_mismatch"
		_model_document.clear()
		return
	if int(model.get("output_dim", -1)) != _resolved_class_order.size():
		_model_error = "model_output_dim_mismatch"
		_model_document.clear()
		return

func _score_current_window() -> Dictionary:
	var flattened := _build_flattened_input_vector()
	if flattened.is_empty():
		return {
			"class_scores": {},
			"best_class": OUTCOME_NO_PUNCH,
			"best_score": 0.0,
			"runner_up_class": OUTCOME_NO_PUNCH,
			"runner_up_score": 0.0,
			"window_sample_count": _sample_history.size(),
			"window_span_ms": _resolve_window_span_ms(_sample_history),
		}
	var standardized := _standardize_vector(flattened)
	var hidden := _dense_relu(standardized)
	var probabilities := _dense_softmax(hidden)
	var class_scores: Dictionary = {}
	var best_index := -1
	var best_score := -1.0
	var runner_up_index := -1
	var runner_up_score := -1.0
	for idx in range(mini(_resolved_class_order.size(), probabilities.size())):
		var resolved_class_name := String(_resolved_class_order[idx])
		var score := float(probabilities[idx])
		class_scores[resolved_class_name] = score
		if score > best_score:
			runner_up_index = best_index
			runner_up_score = best_score
			best_index = idx
			best_score = score
		elif score > runner_up_score:
			runner_up_index = idx
			runner_up_score = score
	return {
		"class_scores": class_scores,
		"best_class": String(_resolved_class_order[best_index]) if best_index >= 0 else OUTCOME_NO_PUNCH,
		"best_score": maxf(best_score, 0.0),
		"runner_up_class": String(_resolved_class_order[runner_up_index]) if runner_up_index >= 0 else OUTCOME_NO_PUNCH,
		"runner_up_score": maxf(runner_up_score, 0.0),
		"window_sample_count": _sample_history.size(),
		"window_span_ms": _resolve_window_span_ms(_sample_history),
	}

func _build_flattened_input_vector() -> Array:
	var left_series := _resample_side_window("left", _get_frame_count(), _sample_history)
	var right_series := _resample_side_window("right", _get_frame_count(), _sample_history)
	if left_series.size() != _get_frame_count() or right_series.size() != _get_frame_count():
		return []
	var flattened: Array = []
	for idx in range(_get_frame_count()):
		var left_features: Array = left_series[idx] as Array
		var right_features: Array = right_series[idx] as Array
		flattened.append_array(left_features)
		flattened.append_array(right_features)
	if flattened.size() != _get_frame_count() * _get_frame_feature_count():
		return []
	return flattened

func _standardize_vector(flattened: Array) -> Array:
	var result: Array = []
	var standardization: Dictionary = _model_document.get("standardization", {}) if _model_document.get("standardization", {}) is Dictionary else {}
	var means: Array = standardization.get("means", []) as Array
	var stds: Array = standardization.get("stds", []) as Array
	for idx in range(flattened.size()):
		var mean := float(means[idx])
		var std := maxf(absf(float(stds[idx])), 0.000001)
		result.append((float(flattened[idx]) - mean) / std)
	return result

func _dense_relu(inputs: Array) -> Array:
	var result: Array = []
	var model: Dictionary = _model_document.get("model", {}) if _model_document.get("model", {}) is Dictionary else {}
	var w1: Array = model.get("w1", []) as Array
	var b1: Array = model.get("b1", []) as Array
	for row_idx in range(w1.size()):
		var row_weights: Array = w1[row_idx] as Array
		var value := float(b1[row_idx]) if row_idx < b1.size() else 0.0
		for input_idx in range(mini(inputs.size(), row_weights.size())):
			value += float(row_weights[input_idx]) * float(inputs[input_idx])
		result.append(maxf(0.0, value))
	return result

func _dense_softmax(hidden: Array) -> Array:
	var logits: Array = []
	var model: Dictionary = _model_document.get("model", {}) if _model_document.get("model", {}) is Dictionary else {}
	var w2: Array = model.get("w2", []) as Array
	var b2: Array = model.get("b2", []) as Array
	for row_idx in range(w2.size()):
		var row_weights: Array = w2[row_idx] as Array
		var value := float(b2[row_idx]) if row_idx < b2.size() else 0.0
		for hidden_idx in range(mini(hidden.size(), row_weights.size())):
			value += float(row_weights[hidden_idx]) * float(hidden[hidden_idx])
		logits.append(value)
	if logits.is_empty():
		return []
	var max_logit := float(logits[0])
	for value_variant in logits:
		max_logit = maxf(max_logit, float(value_variant))
	var sum_exp := 0.0
	var exp_logits: Array = []
	for value_variant in logits:
		var exp_value := exp(float(value_variant) - max_logit)
		exp_logits.append(exp_value)
		sum_exp += exp_value
	var probabilities: Array = []
	for exp_value_variant in exp_logits:
		probabilities.append(float(exp_value_variant) / maxf(sum_exp, 0.000001))
	return probabilities

func _resolve_model_path(path: String) -> String:
	var resolved_path := path
	if not (resolved_path.begins_with("res://") or resolved_path.begins_with("user://") or resolved_path.is_absolute_path()):
		resolved_path = _get_addon_root_path().path_join(resolved_path)
	if resolved_path.begins_with(REPO_ROOT_DOCS_PREFIX) and not FileAccess.file_exists(resolved_path):
		var addon_relative_docs_path := resolved_path.substr(REPO_ROOT_DOCS_PREFIX.length())
		var addon_docs_candidate := ADDON_ROOT_DOCS_PREFIX + addon_relative_docs_path
		if FileAccess.file_exists(addon_docs_candidate):
			return addon_docs_candidate
	return resolved_path

func _get_gesture_profile_document() -> Dictionary:
	if _config == null:
		return {}
	var gesture_profile_document: Variant = _config.get("gesture_profile_document") if _config.has_method("get") else null
	return gesture_profile_document if gesture_profile_document is Dictionary else {}

func _get_selected_backend() -> String:
	var gesture_profile_document := _get_gesture_profile_document()
	var punch_detection: Dictionary = gesture_profile_document.get("punch_detection", {}) if gesture_profile_document.get("punch_detection", {}) is Dictionary else {}
	return _normalize_backend_name(String(punch_detection.get("backend", BACKEND_THRESHOLD_GATES)))

func _is_enabled_in_config() -> bool:
	var gesture_profile_document := _get_gesture_profile_document()
	var learned: Dictionary = gesture_profile_document.get("learned_classifier", {}) if gesture_profile_document.get("learned_classifier", {}) is Dictionary else {}
	return bool(learned.get("enabled", false))

func _is_selected_backend_enabled() -> bool:
	var selected_backend := _get_selected_backend()
	var gesture_profile_document := _get_gesture_profile_document()
	if selected_backend == BACKEND_LEARNED_CLASSIFIER:
		return _is_enabled_in_config()
	if selected_backend == BACKEND_PROTOTYPE_MATCHER:
		var matcher: Dictionary = gesture_profile_document.get("prototype_matcher", {}) if gesture_profile_document.get("prototype_matcher", {}) is Dictionary else {}
		return bool(matcher.get("enabled", false))
	if selected_backend == BACKEND_THRESHOLD_GATES:
		var threshold_backend: Dictionary = gesture_profile_document.get(BACKEND_THRESHOLD_GATES, {}) if gesture_profile_document.get(BACKEND_THRESHOLD_GATES, {}) is Dictionary else {}
		return bool(threshold_backend.get("enabled", true))
	return false

func _is_active_backend() -> bool:
	return _get_selected_backend() == BACKEND_LEARNED_CLASSIFIER and _is_enabled_in_config()

func _get_activation_reason() -> String:
	if _is_active_backend():
		return "active"
	if _get_selected_backend() != BACKEND_LEARNED_CLASSIFIER:
		return "backend_not_selected"
	return "selected_backend_disabled"

func _normalize_backend_name(backend_name: String) -> String:
	if backend_name == BACKEND_THRESHOLD_GATES:
		return BACKEND_THRESHOLD_GATES
	return backend_name

func _get_model_artifact_path() -> String:
	var gesture_profile_document := _get_gesture_profile_document()
	var learned: Dictionary = gesture_profile_document.get("learned_classifier", {}) if gesture_profile_document.get("learned_classifier", {}) is Dictionary else {}
	var model: Dictionary = learned.get("model", {}) if learned.get("model", {}) is Dictionary else {}
	var path := String(model.get("artifact_path", DEFAULT_MODEL_ARTIFACT_PATH))
	return path if not path.is_empty() else DEFAULT_MODEL_ARTIFACT_PATH

func _get_window_ms() -> int:
	return LEARNED_DEFAULT_WINDOW_MS

func _get_window_step_ms() -> int:
	return LEARNED_DEFAULT_WINDOW_STEP_MS

func _get_match_score_min() -> float:
	var gesture_profile_document := _get_gesture_profile_document()
	var learned: Dictionary = gesture_profile_document.get("learned_classifier", {}) if gesture_profile_document.get("learned_classifier", {}) is Dictionary else {}
	var thresholds: Dictionary = learned.get("thresholds", {}) if learned.get("thresholds", {}) is Dictionary else {}
	return clampf(float(thresholds.get("match_score_min", LEARNED_DEFAULT_MATCH_SCORE_MIN)), 0.0, 1.0)

func _get_emit_cooldown_ms() -> int:
	var gesture_profile_document := _get_gesture_profile_document()
	var learned: Dictionary = gesture_profile_document.get("learned_classifier", {}) if gesture_profile_document.get("learned_classifier", {}) is Dictionary else {}
	var timing: Dictionary = learned.get("timing", {}) if learned.get("timing", {}) is Dictionary else {}
	return max(0, int(timing.get("emit_cooldown_ms", LEARNED_DEFAULT_EMIT_COOLDOWN_MS)))

func _get_emit_hold_ms() -> int:
	var gesture_profile_document := _get_gesture_profile_document()
	var learned: Dictionary = gesture_profile_document.get("learned_classifier", {}) if gesture_profile_document.get("learned_classifier", {}) is Dictionary else {}
	var timing: Dictionary = learned.get("timing", {}) if learned.get("timing", {}) is Dictionary else {}
	return max(0, int(timing.get("emit_hold_ms", LEARNED_DEFAULT_EMIT_HOLD_MS)))

func _get_show_scores() -> bool:
	var gesture_profile_document := _get_gesture_profile_document()
	var learned: Dictionary = gesture_profile_document.get("learned_classifier", {}) if gesture_profile_document.get("learned_classifier", {}) is Dictionary else {}
	var debug_config: Dictionary = learned.get("debug", {}) if learned.get("debug", {}) is Dictionary else {}
	return _get_debug_bool(debug_config, "show_scores", LEARNED_DEFAULT_SHOW_SCORES)

func _get_show_event_gate_state() -> bool:
	var gesture_profile_document := _get_gesture_profile_document()
	var learned: Dictionary = gesture_profile_document.get("learned_classifier", {}) if gesture_profile_document.get("learned_classifier", {}) is Dictionary else {}
	var debug_config: Dictionary = learned.get("debug", {}) if learned.get("debug", {}) is Dictionary else {}
	return _get_debug_bool(debug_config, "show_event_gate_state", LEARNED_DEFAULT_SHOW_EVENT_GATE_STATE)

func _get_debug_bool(debug_config: Dictionary, key: String, default_value: bool) -> bool:
	var raw_value = debug_config.get(key, default_value)
	return raw_value if raw_value is bool else default_value

func _build_frame_feature_names(side_feature_names: Array) -> Array:
	var result: Array = []
	for feature_name_variant in side_feature_names:
		result.append("left_%s" % String(feature_name_variant))
	for feature_name_variant in side_feature_names:
		result.append("right_%s" % String(feature_name_variant))
	return result

func _get_feature_names() -> Array:
	return _resolved_side_feature_names.duplicate(true)

func _get_feature_count() -> int:
	return _resolved_side_feature_names.size()

func _get_frame_count() -> int:
	return max(1, int(_resolved_frame_count) if typeof(_resolved_frame_count) == TYPE_INT else 8)

func _get_frame_feature_count() -> int:
	return max(1, int(_resolved_frame_feature_count) if typeof(_resolved_frame_feature_count) == TYPE_INT else 16)

func _get_library_sample_count() -> int:
	return _get_frame_count()
