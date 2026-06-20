class_name DepthPythonRuntimeBridge
extends RefCounted

const DepthRuntimeTypes = preload("res://addons/aerobeat-input-camera-tracking/src/depth/depth_runtime_types.gd")

var _model_spec: Dictionary = {}
var _backend_id := ""
var _family_id := "unknown"
var _python_executable := ""
var _bridge_script_path := ""
var _debug_state: Dictionary = DepthRuntimeTypes.make_debug_state()

func configure(model_spec: Dictionary, backend_id: String) -> void:
	_model_spec = model_spec.duplicate(true)
	_backend_id = backend_id
	_family_id = String(_model_spec.get("family_id", "unknown"))
	_bridge_script_path = ProjectSettings.globalize_path("res://addons/aerobeat-input-camera-tracking/scripts/depth_runtime_infer.py")
	_python_executable = _resolve_python_executable()
	_debug_state = DepthRuntimeTypes.make_debug_state()
	_debug_state["configured"] = true
	_debug_state["family"] = String(_model_spec.get("family", ""))
	_debug_state["depth_enabled"] = true
	_debug_state["artifact_path_res"] = String(_model_spec.get("artifact_path_res", ""))
	_debug_state["artifact_path_abs"] = String(_model_spec.get("artifact_path_abs", ""))
	_debug_state["artifact_exists"] = bool(_model_spec.get("artifact_exists", false))
	_debug_state["artifact_kind"] = String(_model_spec.get("artifact_kind", "missing"))
	_debug_state["family_id"] = _family_id
	_debug_state["backend_id"] = _backend_id
	_debug_state["runtime_key"] = String(_model_spec.get("runtime_key", ""))
	_debug_state["runtime_status"] = DepthRuntimeTypes.STATUS_LOADING
	_debug_state["runtime_stage"] = DepthRuntimeTypes.STAGE_DEPENDENCY_CHECK

func probe_runtime() -> Dictionary:
	if _python_executable.is_empty() or not FileAccess.file_exists(_python_executable):
		return _failed_probe("python_runtime_missing", "Depth runtime Python executable was not found at '%s'." % _python_executable)
	if not FileAccess.file_exists(_bridge_script_path):
		return _failed_probe("bridge_script_missing", "Depth runtime bridge script was not found at '%s'." % _bridge_script_path)
	var response := _run_request({
		"operation": "probe",
		"backend_id": _backend_id,
		"model_spec": _model_spec,
	})
	if not bool(response.get("ok", false)):
		_debug_state["runtime_status"] = String(response.get("status", DepthRuntimeTypes.STATUS_BLOCKED))
		_debug_state["runtime_stage"] = String(response.get("runtime_stage", DepthRuntimeTypes.STAGE_DEPENDENCY_CHECK))
		_debug_state["failure_code"] = String(response.get("failure_code", "probe_failed"))
		_debug_state["failure_message"] = String(response.get("failure_message", "Depth runtime probe failed."))
		_debug_state["active_model_summary"] = String(response.get("active_model_summary", "enabled; runtime probe failed via %s" % _backend_id))
		return {
			"ok": false,
			"status": String(_debug_state.get("runtime_status", DepthRuntimeTypes.STATUS_BLOCKED)),
			"failure_code": String(_debug_state.get("failure_code", "probe_failed")),
			"failure_message": String(_debug_state.get("failure_message", "Depth runtime probe failed.")),
		}
	_debug_state["runtime_status"] = DepthRuntimeTypes.STATUS_READY
	_debug_state["runtime_stage"] = DepthRuntimeTypes.STAGE_SAMPLING
	_debug_state["failure_code"] = ""
	_debug_state["failure_message"] = ""
	_debug_state["active_model_summary"] = String(response.get("active_model_summary", "enabled; runtime ready via %s backend" % _backend_id))
	if response.get("runtime_provider", null) != null:
		_debug_state["runtime_provider"] = response.get("runtime_provider")
	return {"ok": true, "status": DepthRuntimeTypes.STATUS_READY}

func infer(frame_payload: Dictionary, request: Dictionary) -> Dictionary:
	var result := DepthRuntimeTypes.make_result(String(_debug_state.get("runtime_status", DepthRuntimeTypes.STATUS_FAILED)))
	result["backend_id"] = _backend_id
	result["family_id"] = _family_id
	result["artifact_path"] = String(_model_spec.get("artifact_path_res", _model_spec.get("artifact_path_abs", "")))
	if _python_executable.is_empty() or not FileAccess.file_exists(_python_executable):
		result["status"] = DepthRuntimeTypes.STATUS_FAILED
		result["error_info"] = {
			"code": "python_runtime_missing",
			"message": "Depth runtime Python executable was not found at '%s'." % _python_executable,
		}
		return result
	var preview_image_path := _resolve_preview_image_path(frame_payload)
	if preview_image_path.is_empty():
		result["status"] = DepthRuntimeTypes.STATUS_BLOCKED
		result["error_info"] = {
			"code": "preview_image_missing",
			"message": "Tracking frame did not include a preview image path for live depth inference.",
		}
		return result
	var response := _run_request({
		"operation": "infer",
		"backend_id": _backend_id,
		"model_spec": _model_spec,
		"preview_image_path": preview_image_path,
		"sample_request": request.duplicate(true),
	})
	if not bool(response.get("ok", false)):
		result["status"] = String(response.get("status", DepthRuntimeTypes.STATUS_FAILED))
		result["sample_metrics"] = (response.get("sample_metrics", {}) as Dictionary).duplicate(true) if response.get("sample_metrics", {}) is Dictionary else {}
		result["timing_ms"] = (response.get("timing_ms", {}) as Dictionary).duplicate(true) if response.get("timing_ms", {}) is Dictionary else result.get("timing_ms", {})
		result["error_info"] = {
			"code": String(response.get("failure_code", "infer_failed")),
			"message": String(response.get("failure_message", "Depth inference failed.")),
		}
		_sync_debug_from_response(response)
		return result
	result["ok"] = true
	result["status"] = DepthRuntimeTypes.STATUS_READY
	result["sample_metrics"] = (response.get("sample_metrics", {}) as Dictionary).duplicate(true) if response.get("sample_metrics", {}) is Dictionary else {}
	result["timing_ms"] = (response.get("timing_ms", {}) as Dictionary).duplicate(true) if response.get("timing_ms", {}) is Dictionary else result.get("timing_ms", {})
	result["depth_orientation"] = String(response.get("depth_orientation", "smaller_is_closer"))
	result["frame_size"] = _vector2i_from_variant(response.get("frame_size", []))
	result["depth_map_size"] = _vector2i_from_variant(response.get("depth_map_size", []))
	result["normalized_depth_map"] = response.get("normalized_depth_map", null)
	_sync_debug_from_response(response)
	return result

func get_debug_state() -> Dictionary:
	return _debug_state.duplicate(true)

func _run_request(payload: Dictionary) -> Dictionary:
	var request_path := _temp_json_path("request")
	var response_path := _temp_json_path("response")
	var request_file := FileAccess.open(request_path, FileAccess.WRITE)
	if request_file == null:
		return {
			"ok": false,
			"status": DepthRuntimeTypes.STATUS_FAILED,
			"failure_code": "request_write_failed",
			"failure_message": "Failed to write depth runtime request file.",
			"runtime_stage": DepthRuntimeTypes.STAGE_DEPENDENCY_CHECK,
		}
	request_file.store_string(JSON.stringify(payload))
	request_file.close()
	var output: Array = []
	var exit_code := OS.execute(_python_executable, [_bridge_script_path, "--request-file", request_path, "--response-file", response_path], output, true)
	var response: Dictionary = {}
	if FileAccess.file_exists(response_path):
		var response_text := FileAccess.get_file_as_string(response_path)
		var parsed := JSON.parse_string(response_text)
		if parsed is Dictionary:
			response = parsed
	_cleanup_temp_file(request_path)
	_cleanup_temp_file(response_path)
	if exit_code != 0 and response.is_empty():
		return {
			"ok": false,
			"status": DepthRuntimeTypes.STATUS_FAILED,
			"failure_code": "bridge_exec_failed",
			"failure_message": "Depth runtime bridge exited with code %d. %s" % [exit_code, "\n".join(output)],
			"runtime_stage": DepthRuntimeTypes.STAGE_DEPENDENCY_CHECK,
		}
	if exit_code != 0 and not response.get("ok", false):
		response["failure_message"] = String(response.get("failure_message", "Depth runtime bridge failed."))
		if response["failure_message"].is_empty():
			response["failure_message"] = "Depth runtime bridge failed."
	return response

func _resolve_python_executable() -> String:
	var project_root := ProjectSettings.globalize_path("res://")
	var bridge_dir := _bridge_script_path.get_base_dir()
	var bridge_repo_root := bridge_dir.get_base_dir()
	var candidates := [
		bridge_repo_root.path_join("../aerobeat-vendor-mediapipe-python/.venv/bin/python"),
		bridge_repo_root.path_join("../../aerobeat-vendor-mediapipe-python/.venv/bin/python"),
		project_root.path_join("../aerobeat-vendor-mediapipe-python/.venv/bin/python"),
		project_root.path_join("../../aerobeat-vendor-mediapipe-python/.venv/bin/python"),
		bridge_repo_root.path_join("../aerobeat-vendor-mediapipe-python/venv/bin/python"),
		bridge_repo_root.path_join("../../aerobeat-vendor-mediapipe-python/venv/bin/python"),
		"/usr/bin/python3",
		"python3",
	]
	for candidate in candidates:
		if candidate == "python3":
			continue
		if FileAccess.file_exists(candidate):
			return candidate
	return "python3"

func _resolve_preview_image_path(frame_payload: Dictionary) -> String:
	var direct_candidates := [
		frame_payload.get("preview_image_path", ""),
		frame_payload.get("image_path", ""),
	]
	for candidate_variant: Variant in direct_candidates:
		var candidate := String(candidate_variant).strip_edges()
		if not candidate.is_empty() and FileAccess.file_exists(candidate):
			return candidate
	var preview_descriptor: Dictionary = frame_payload.get("preview_descriptor", {}) if frame_payload.get("preview_descriptor", {}) is Dictionary else {}
	var nested_candidate := String(preview_descriptor.get("image_path", "")).strip_edges()
	if not nested_candidate.is_empty() and FileAccess.file_exists(nested_candidate):
		return nested_candidate
	return ""

func _sync_debug_from_response(response: Dictionary) -> void:
	_debug_state["runtime_status"] = String(response.get("status", _debug_state.get("runtime_status", DepthRuntimeTypes.STATUS_READY)))
	_debug_state["runtime_stage"] = String(response.get("runtime_stage", DepthRuntimeTypes.STAGE_SAMPLING if bool(response.get("ok", false)) else DepthRuntimeTypes.STAGE_INFERENCE))
	_debug_state["failure_code"] = "" if bool(response.get("ok", false)) else String(response.get("failure_code", "infer_failed"))
	_debug_state["failure_message"] = "" if bool(response.get("ok", false)) else String(response.get("failure_message", "Depth inference failed."))
	_debug_state["active_model_summary"] = String(response.get("active_model_summary", _debug_state.get("active_model_summary", "enabled; runtime ready via %s" % _backend_id)))
	if response.get("sample_metrics", null) is Dictionary:
		_debug_state["last_sample_metrics"] = (response.get("sample_metrics", {}) as Dictionary).duplicate(true)
	if response.get("timing_ms", null) is Dictionary:
		_debug_state["last_timing_ms"] = (response.get("timing_ms", {}) as Dictionary).duplicate(true)
	if response.get("runtime_provider", null) != null:
		_debug_state["runtime_provider"] = response.get("runtime_provider")

func _failed_probe(code: String, message: String) -> Dictionary:
	_debug_state["runtime_status"] = DepthRuntimeTypes.STATUS_FAILED
	_debug_state["runtime_stage"] = DepthRuntimeTypes.STAGE_DEPENDENCY_CHECK
	_debug_state["failure_code"] = code
	_debug_state["failure_message"] = message
	_debug_state["active_model_summary"] = "enabled; runtime probe failed via %s" % _backend_id
	return {
		"ok": false,
		"status": DepthRuntimeTypes.STATUS_FAILED,
		"failure_code": code,
		"failure_message": message,
	}

func _temp_json_path(prefix: String) -> String:
	var temp_dir := ProjectSettings.globalize_path("user://depth-runtime")
	DirAccess.make_dir_recursive_absolute(temp_dir)
	return temp_dir.path_join("%s-%s-%s.json" % [prefix, str(OS.get_process_id()), str(Time.get_ticks_usec())])

func _cleanup_temp_file(path: String) -> void:
	if path.is_empty() or not FileAccess.file_exists(path):
		return
	DirAccess.remove_absolute(path)

func _vector2i_from_variant(value: Variant) -> Vector2i:
	if value is Array:
		var array_value: Array = value
		if array_value.size() >= 2:
			return Vector2i(int(array_value[0]), int(array_value[1]))
	return Vector2i.ZERO
