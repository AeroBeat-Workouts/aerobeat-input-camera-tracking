class_name PrototypePunchMatcher
extends RefCounted

const BACKEND_DISABLED := "disabled"
const BACKEND_PROTOTYPE_MATCHER := "prototype"

var _config = null

func configure(config) -> PrototypePunchMatcher:
	_config = config
	return self

func reset() -> void:
	pass

func get_debug_state() -> Dictionary:
	return {
		"enabled": false,
		"selected_backend": BACKEND_DISABLED,
		"selected_backend_enabled": false,
		"active_backend": "none",
		"activation_reason": "prototype_runtime_removed",
		"library_id": "",
		"library_path": "",
		"library_loaded": false,
		"library_error": "prototype_runtime_removed",
		"sample_history_size": 0,
	}

func process_window(_landmarks_by_id: Dictionary, _metrics: Dictionary, _timestamp_ms: int) -> Array:
	return []
