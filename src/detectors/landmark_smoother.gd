class_name LandmarkSmoother
extends RefCounted

const STYLE_LITE_RAW := "lite_raw"
const STYLE_LITE_FILTERED := "lite_filtered"
const STYLE_EXPONENTIAL_MOVING_AVERAGE := "exponential_moving_average"
const EXPONENTIAL_MOVING_AVERAGE_ALPHA := 0.45

var _window_size: int = 4
var _smoothing_style: String = STYLE_LITE_RAW
var _samples_by_id: Dictionary = {}
var _smoothed_samples_by_id: Dictionary = {}

func _init(window_size: int = 4, smoothing_style: String = STYLE_LITE_RAW) -> void:
	_smoothing_style = _normalize_smoothing_style(smoothing_style)
	_window_size = _resolve_window_size(window_size, _smoothing_style)

func clear() -> void:
	_samples_by_id.clear()
	_smoothed_samples_by_id.clear()

func push_landmarks(landmarks: Array) -> Dictionary:
	for landmark: Variant in landmarks:
		if not landmark is Dictionary:
			continue
		var landmark_dict: Dictionary = landmark.duplicate(true)
		var landmark_id: int = int(landmark_dict.get("id", -1))
		if landmark_id < 0:
			continue
		var history: Array = _samples_by_id.get(landmark_id, [])
		history.append(landmark_dict)
		while history.size() > _window_size:
			history.pop_front()
		_samples_by_id[landmark_id] = history
		_update_smoothed_landmark(landmark_id, landmark_dict, history)
	return get_smoothed_landmarks()

func get_smoothed_landmarks() -> Dictionary:
	var smoothed: Dictionary = {}
	for landmark_id_variant: Variant in _samples_by_id.keys():
		var history: Array = _samples_by_id.get(landmark_id_variant, [])
		if history.is_empty():
			continue
		var latest: Dictionary = history[history.size() - 1]
		var landmark_id: int = int(landmark_id_variant)
		var smoothed_landmark: Dictionary = _smoothed_samples_by_id.get(landmark_id, latest)
		smoothed[landmark_id] = {
			"id": landmark_id,
			"x": float(smoothed_landmark.get("x", 0.0)),
			"y": float(smoothed_landmark.get("y", 0.0)),
			"z": float(smoothed_landmark.get("z", 0.0)),
			"v": float(smoothed_landmark.get("v", 0.0)),
			"sample_count": history.size(),
			"latest_visibility": float(latest.get("v", 0.0)),
		}
	return smoothed

func _update_smoothed_landmark(landmark_id: int, current_sample: Dictionary, history: Array) -> void:
	if _smoothing_style == STYLE_EXPONENTIAL_MOVING_AVERAGE:
		_smoothed_samples_by_id[landmark_id] = _smooth_history_exponential_moving_average(landmark_id, current_sample)
		return
	_smoothed_samples_by_id[landmark_id] = _smooth_history_moving_average(history)

func _smooth_history_moving_average(history: Array) -> Dictionary:
	var sum_x := 0.0
	var sum_y := 0.0
	var sum_z := 0.0
	var sum_v := 0.0
	for sample_variant: Variant in history:
		if not sample_variant is Dictionary:
			continue
		var sample: Dictionary = sample_variant
		sum_x += float(sample.get("x", 0.0))
		sum_y += float(sample.get("y", 0.0))
		sum_z += float(sample.get("z", 0.0))
		sum_v += float(sample.get("v", 0.0))
	var count: float = float(history.size())
	return {
		"x": sum_x / count,
		"y": sum_y / count,
		"z": sum_z / count,
		"v": sum_v / count,
	}

func _smooth_history_exponential_moving_average(landmark_id: int, current_sample: Dictionary) -> Dictionary:
	var previous: Dictionary = _smoothed_samples_by_id.get(landmark_id, current_sample)
	return {
		"x": _ema_axis(previous, current_sample, "x"),
		"y": _ema_axis(previous, current_sample, "y"),
		"z": _ema_axis(previous, current_sample, "z"),
		"v": _ema_axis(previous, current_sample, "v"),
	}

func _ema_axis(previous: Dictionary, current_sample: Dictionary, key: String) -> float:
	var previous_value := float(previous.get(key, current_sample.get(key, 0.0)))
	var current_value := float(current_sample.get(key, 0.0))
	return previous_value + (current_value - previous_value) * EXPONENTIAL_MOVING_AVERAGE_ALPHA

func _normalize_smoothing_style(smoothing_style: String) -> String:
	var normalized := smoothing_style.strip_edges().to_lower()
	match normalized:
		STYLE_LITE_FILTERED, STYLE_EXPONENTIAL_MOVING_AVERAGE:
			return normalized
		_:
			return STYLE_LITE_RAW

func _resolve_window_size(window_size: int, smoothing_style: String) -> int:
	var normalized_window_size := maxi(window_size, 1)
	if smoothing_style == STYLE_EXPONENTIAL_MOVING_AVERAGE:
		return maxi(normalized_window_size, 2)
	return normalized_window_size
