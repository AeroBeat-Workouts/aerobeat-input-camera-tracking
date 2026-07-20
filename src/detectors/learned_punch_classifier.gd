class_name LearnedPunchClassifier
extends "res://addons/aerobeat-input-camera-tracking/src/detectors/prototype_punch_matcher.gd"

const BACKEND_LEARNED_CLASSIFIER := "classifier"

func configure(config) -> LearnedPunchClassifier:
	_config = config
	return self

func get_debug_state() -> Dictionary:
	return {
		"enabled": false,
		"selected_backend": BACKEND_DISABLED,
		"selected_backend_enabled": false,
		"active_backend": "none",
		"activation_reason": "classifier_runtime_removed",
		"model_path": "",
		"model_loaded": false,
		"model_error": "classifier_runtime_removed",
		"class_order": [],
		"frame_count": 0,
		"frame_feature_count": 0,
	}

func process_window(_landmarks_by_id: Dictionary, _metrics: Dictionary, _timestamp_ms: int) -> Array:
	return []
