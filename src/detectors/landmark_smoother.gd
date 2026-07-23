class_name LandmarkSmoother
extends RefCounted

const STYLE_LITE_RAW := "lite_raw"
const STYLE_LITE_FILTERED := "lite_filtered"

var _window_size: int = 4
var _smoothing_style: String = STYLE_LITE_RAW
var _samples_by_id: Dictionary = {}
var _smoothed_samples_by_id: Dictionary = {}

func _init(window_size: int = 4, smoothing_style: String = STYLE_LITE_RAW) -> void:
	_smoothing_style = _normalize_smoothing_style(smoothing_style)
	_window_size = _resolve_window_size(window_size)

func clear() -> void:
	_samples_by_id.clear()
	_smoothed_samples_by_id.clear()

func push_landmarks(landmarks: Array) -> Dictionary:
	var seen_ids := {}
	for landmark: Variant in landmarks:
		if not landmark is Dictionary:
			continue
		var landmark_dict: Dictionary = landmark.duplicate(true)
		var landmark_id: int = int(landmark_dict.get("id", -1))
		if landmark_id < 0:
			continue
		seen_ids[landmark_id] = true
		var history: Array = _samples_by_id.get(landmark_id, [])
		history.append(landmark_dict)
		while history.size() > _window_size:
			history.pop_front()
		_samples_by_id[landmark_id] = history
		_smoothed_samples_by_id[landmark_id] = _smooth_history_moving_average(history)
	for landmark_id_variant: Variant in _samples_by_id.keys():
		var landmark_id := int(landmark_id_variant)
		if seen_ids.has(landmark_id):
			continue
		var history: Array = _samples_by_id.get(landmark_id, [])
		if history.is_empty():
			continue
		var missing_sample: Dictionary = (history[history.size() - 1] as Dictionary).duplicate(true)
		missing_sample["v"] = 0.0
		history.append(missing_sample)
		while history.size() > _window_size:
			history.pop_front()
		_samples_by_id[landmark_id] = history
		_smoothed_samples_by_id[landmark_id] = _smooth_history_moving_average(history)
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

func _normalize_smoothing_style(smoothing_style: String) -> String:
	var normalized := smoothing_style.strip_edges().to_lower()
	if normalized == STYLE_LITE_FILTERED:
		return normalized
	return STYLE_LITE_RAW

func _resolve_window_size(window_size: int) -> int:
	return maxi(window_size, 1)
