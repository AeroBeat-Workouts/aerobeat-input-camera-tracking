class_name LandmarkSmoother
extends RefCounted

const STYLE_LITE_RAW := "lite_raw"
const STYLE_LITE_FILTERED := "lite_filtered"
const STYLE_EXPONENTIAL_MOVING_AVERAGE := "exponential_moving_average"
const STYLE_ADAPTIVE_EXPONENTIAL_MOVING_AVERAGE := "adaptive_exponential_moving_average"
const STYLE_MEDIAN_OF_3 := "median_of_3"
const STYLE_MICRO_DEADBAND_ADAPTIVE := "micro_deadband_adaptive"
const EXPONENTIAL_MOVING_AVERAGE_ALPHA := 0.45
const ADAPTIVE_EXPONENTIAL_MOVING_AVERAGE_MIN_ALPHA := 0.18
const ADAPTIVE_EXPONENTIAL_MOVING_AVERAGE_MAX_ALPHA := 0.82
const ADAPTIVE_EXPONENTIAL_MOVING_AVERAGE_LOW_MOTION_DISTANCE := 0.01
const ADAPTIVE_EXPONENTIAL_MOVING_AVERAGE_HIGH_MOTION_DISTANCE := 0.08
const MEDIAN_OF_3_WINDOW_SIZE := 3
const MICRO_DEADBAND_ADAPTIVE_MAX_DISTANCE := 0.0100
const MICRO_DEADBAND_ADAPTIVE_MIN_DISTANCE := 0.0020
const MICRO_DEADBAND_ADAPTIVE_LOW_MOTION_DISTANCE := 0.0040
const MICRO_DEADBAND_ADAPTIVE_HIGH_MOTION_DISTANCE := 0.050

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
	if _smoothing_style == STYLE_ADAPTIVE_EXPONENTIAL_MOVING_AVERAGE:
		_smoothed_samples_by_id[landmark_id] = _smooth_history_adaptive_exponential_moving_average(landmark_id, current_sample, history)
		return
	if _smoothing_style == STYLE_MEDIAN_OF_3:
		_smoothed_samples_by_id[landmark_id] = _smooth_history_median_of_3(current_sample, history)
		return
	if _smoothing_style == STYLE_MICRO_DEADBAND_ADAPTIVE:
		_smoothed_samples_by_id[landmark_id] = _smooth_history_micro_deadband_adaptive(landmark_id, current_sample, history)
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
		"x": _ema_axis(previous, current_sample, "x", EXPONENTIAL_MOVING_AVERAGE_ALPHA),
		"y": _ema_axis(previous, current_sample, "y", EXPONENTIAL_MOVING_AVERAGE_ALPHA),
		"z": _ema_axis(previous, current_sample, "z", EXPONENTIAL_MOVING_AVERAGE_ALPHA),
		"v": _ema_axis(previous, current_sample, "v", EXPONENTIAL_MOVING_AVERAGE_ALPHA),
	}

func _smooth_history_adaptive_exponential_moving_average(landmark_id: int, current_sample: Dictionary, history: Array) -> Dictionary:
	if history.size() < 2:
		return {
			"x": float(current_sample.get("x", 0.0)),
			"y": float(current_sample.get("y", 0.0)),
			"z": float(current_sample.get("z", 0.0)),
			"v": float(current_sample.get("v", 0.0)),
		}
	var previous_smoothed: Dictionary = _smoothed_samples_by_id.get(landmark_id, history[history.size() - 2])
	var previous_raw: Dictionary = history[history.size() - 2]
	var alpha := _adaptive_exponential_moving_average_alpha(previous_raw, current_sample)
	return {
		"x": _ema_axis(previous_smoothed, current_sample, "x", alpha),
		"y": _ema_axis(previous_smoothed, current_sample, "y", alpha),
		"z": _ema_axis(previous_smoothed, current_sample, "z", alpha),
		"v": _ema_axis(previous_smoothed, current_sample, "v", alpha),
	}

func _smooth_history_median_of_3(current_sample: Dictionary, history: Array) -> Dictionary:
	if history.size() < MEDIAN_OF_3_WINDOW_SIZE:
		return {
			"x": float(current_sample.get("x", 0.0)),
			"y": float(current_sample.get("y", 0.0)),
			"z": float(current_sample.get("z", 0.0)),
			"v": float(current_sample.get("v", 0.0)),
		}
	return {
		"x": _history_axis_median(history, "x"),
		"y": _history_axis_median(history, "y"),
		"z": _history_axis_median(history, "z"),
		"v": _history_axis_median(history, "v"),
	}

func _smooth_history_micro_deadband_adaptive(landmark_id: int, current_sample: Dictionary, history: Array) -> Dictionary:
	if history.size() < 2:
		return {
			"x": float(current_sample.get("x", 0.0)),
			"y": float(current_sample.get("y", 0.0)),
			"z": float(current_sample.get("z", 0.0)),
			"v": float(current_sample.get("v", 0.0)),
		}
	var previous_raw: Dictionary = history[history.size() - 2]
	var previous_smoothed: Dictionary = _smoothed_samples_by_id.get(landmark_id, previous_raw)
	var deadband_distance := _micro_deadband_adaptive_distance(previous_raw, current_sample)
	return {
		"x": _adaptive_deadband_axis(previous_smoothed, current_sample, "x", deadband_distance),
		"y": _adaptive_deadband_axis(previous_smoothed, current_sample, "y", deadband_distance),
		"z": float(current_sample.get("z", previous_smoothed.get("z", 0.0))),
		"v": float(current_sample.get("v", previous_smoothed.get("v", 0.0))),
	}

func _history_axis_median(history: Array, key: String) -> float:
	var values: Array = []
	for sample_variant: Variant in history:
		if not sample_variant is Dictionary:
			continue
		values.append(float((sample_variant as Dictionary).get(key, 0.0)))
	if values.is_empty():
		return 0.0
	values.sort()
	return float(values[values.size() / 2])

func _adaptive_exponential_moving_average_alpha(previous_sample: Dictionary, current_sample: Dictionary) -> float:
	var motion_distance := _sample_motion_distance(previous_sample, current_sample)
	if motion_distance <= ADAPTIVE_EXPONENTIAL_MOVING_AVERAGE_LOW_MOTION_DISTANCE:
		return ADAPTIVE_EXPONENTIAL_MOVING_AVERAGE_MIN_ALPHA
	if motion_distance >= ADAPTIVE_EXPONENTIAL_MOVING_AVERAGE_HIGH_MOTION_DISTANCE:
		return ADAPTIVE_EXPONENTIAL_MOVING_AVERAGE_MAX_ALPHA
	var motion_span := ADAPTIVE_EXPONENTIAL_MOVING_AVERAGE_HIGH_MOTION_DISTANCE - ADAPTIVE_EXPONENTIAL_MOVING_AVERAGE_LOW_MOTION_DISTANCE
	if motion_span <= 0.0:
		return ADAPTIVE_EXPONENTIAL_MOVING_AVERAGE_MAX_ALPHA
	var ratio := (motion_distance - ADAPTIVE_EXPONENTIAL_MOVING_AVERAGE_LOW_MOTION_DISTANCE) / motion_span
	return lerpf(ADAPTIVE_EXPONENTIAL_MOVING_AVERAGE_MIN_ALPHA, ADAPTIVE_EXPONENTIAL_MOVING_AVERAGE_MAX_ALPHA, clampf(ratio, 0.0, 1.0))

func _sample_motion_distance(previous_sample: Dictionary, current_sample: Dictionary) -> float:
	var dx := float(current_sample.get("x", 0.0)) - float(previous_sample.get("x", 0.0))
	var dy := float(current_sample.get("y", 0.0)) - float(previous_sample.get("y", 0.0))
	var dz := float(current_sample.get("z", 0.0)) - float(previous_sample.get("z", 0.0))
	return sqrt(dx * dx + dy * dy + dz * dz)

func _micro_deadband_adaptive_distance(previous_sample: Dictionary, current_sample: Dictionary) -> float:
	var motion_distance := _sample_motion_distance(previous_sample, current_sample)
	if motion_distance <= MICRO_DEADBAND_ADAPTIVE_LOW_MOTION_DISTANCE:
		return MICRO_DEADBAND_ADAPTIVE_MAX_DISTANCE
	if motion_distance >= MICRO_DEADBAND_ADAPTIVE_HIGH_MOTION_DISTANCE:
		return MICRO_DEADBAND_ADAPTIVE_MIN_DISTANCE
	var motion_span := MICRO_DEADBAND_ADAPTIVE_HIGH_MOTION_DISTANCE - MICRO_DEADBAND_ADAPTIVE_LOW_MOTION_DISTANCE
	if motion_span <= 0.0:
		return MICRO_DEADBAND_ADAPTIVE_MIN_DISTANCE
	var ratio := (motion_distance - MICRO_DEADBAND_ADAPTIVE_LOW_MOTION_DISTANCE) / motion_span
	return lerpf(MICRO_DEADBAND_ADAPTIVE_MAX_DISTANCE, MICRO_DEADBAND_ADAPTIVE_MIN_DISTANCE, clampf(ratio, 0.0, 1.0))

func _adaptive_deadband_axis(previous: Dictionary, current_sample: Dictionary, key: String, deadband_distance: float) -> float:
	var previous_value := float(previous.get(key, current_sample.get(key, 0.0)))
	var current_value := float(current_sample.get(key, 0.0))
	var delta := current_value - previous_value
	var absolute_delta := absf(delta)
	if absolute_delta <= deadband_distance:
		return previous_value
	var direction := -1.0 if delta < 0.0 else 1.0
	return current_value - direction * deadband_distance

func _ema_axis(previous: Dictionary, current_sample: Dictionary, key: String, alpha: float) -> float:
	var previous_value := float(previous.get(key, current_sample.get(key, 0.0)))
	var current_value := float(current_sample.get(key, 0.0))
	return previous_value + (current_value - previous_value) * alpha

func _normalize_smoothing_style(smoothing_style: String) -> String:
	var normalized := smoothing_style.strip_edges().to_lower()
	match normalized:
		STYLE_LITE_FILTERED, STYLE_EXPONENTIAL_MOVING_AVERAGE, STYLE_ADAPTIVE_EXPONENTIAL_MOVING_AVERAGE, STYLE_MEDIAN_OF_3, STYLE_MICRO_DEADBAND_ADAPTIVE:
			return normalized
		_:
			return STYLE_LITE_RAW

func _resolve_window_size(window_size: int, smoothing_style: String) -> int:
	var normalized_window_size := maxi(window_size, 1)
	if smoothing_style == STYLE_EXPONENTIAL_MOVING_AVERAGE or smoothing_style == STYLE_ADAPTIVE_EXPONENTIAL_MOVING_AVERAGE or smoothing_style == STYLE_MICRO_DEADBAND_ADAPTIVE:
		return maxi(normalized_window_size, 2)
	if smoothing_style == STYLE_MEDIAN_OF_3:
		return MEDIAN_OF_3_WINDOW_SIZE
	return normalized_window_size
