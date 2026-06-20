class_name DepthPythonRuntimeBridge
extends RefCounted

const DepthRuntimeTypes = preload("res://addons/aerobeat-input-camera-tracking/src/depth/depth_runtime_types.gd")

const _WORKER_READY_TIMEOUT_MS := 5000
const _WORKER_REQUEST_TIMEOUT_MS := 120000
const _WORKER_CONNECT_TIMEOUT_MS := 2000
const _WORKER_MODE_PERSISTENT := "persistent_tcp"
const _WORKER_MODE_LEGACY := "process_per_request"

var _model_spec: Dictionary = {}
var _backend_id := ""
var _family_id := "unknown"
var _python_executable := ""
var _bridge_script_path := ""
var _debug_state: Dictionary = DepthRuntimeTypes.make_debug_state()
var _worker_ready_file := ""
var _worker_token := ""
var _worker_port := -1
var _worker_pid := -1
var _worker_generation := 0
var _worker_restart_count := 0
var _worker_last_error := ""
var _request_serial := 0

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
	_debug_state["worker_mode"] = _WORKER_MODE_PERSISTENT
	_debug_state["worker_alive"] = false
	_debug_state["worker_pid"] = 0
	_debug_state["worker_generation"] = 0
	_debug_state["worker_restart_count"] = 0
	_debug_state["worker_uptime_ms"] = 0.0
	_debug_state["worker_port"] = 0
	_debug_state["model_loaded"] = false
	_debug_state["model_runtime_key"] = ""
	_debug_state["model_load_count"] = 0
	_debug_state["model_reload_count"] = 0
	_debug_state["last_request_id"] = ""
	_debug_state["last_worker_error"] = ""
	_worker_ready_file = ""
	_worker_token = ""
	_worker_port = -1
	_worker_pid = -1
	_worker_generation = 0
	_worker_last_error = ""
	_request_serial = 0

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
	_sync_debug_from_response(response)
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
		var python_missing_message := "Depth runtime Python executable was not found at '%s'." % _python_executable
		result["status"] = DepthRuntimeTypes.STATUS_FAILED
		result["error_info"] = {
			"code": "python_runtime_missing",
			"message": python_missing_message,
		}
		_sync_terminal_debug_state(
			DepthRuntimeTypes.STATUS_FAILED,
			DepthRuntimeTypes.STAGE_DEPENDENCY_CHECK,
			"python_runtime_missing",
			python_missing_message,
			"enabled; depth runtime python executable missing for %s" % _backend_id
		)
		return result
	var preview_image_path := _resolve_preview_image_path(frame_payload)
	if preview_image_path.is_empty():
		var preview_missing_message := "Tracking frame did not include a preview image path for live depth inference."
		result["status"] = DepthRuntimeTypes.STATUS_BLOCKED
		result["error_info"] = {
			"code": "preview_image_missing",
			"message": preview_missing_message,
		}
		_sync_terminal_debug_state(
			DepthRuntimeTypes.STATUS_BLOCKED,
			DepthRuntimeTypes.STAGE_INFERENCE,
			"preview_image_missing",
			preview_missing_message,
			"enabled; per-frame depth sample blocked: preview image missing"
		)
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

func shutdown() -> void:
	if _worker_port > 0:
		var response := _send_worker_request({"operation": "shutdown"}, false)
		if not bool(response.get("ok", false)):
			_worker_last_error = String(response.get("failure_message", "Depth runtime worker shutdown failed."))
		_debug_state["last_worker_error"] = _worker_last_error
	_cleanup_worker_state()

func _run_request(payload: Dictionary) -> Dictionary:
	var request_id := _next_request_id()
	var attempts := 0
	while attempts < 2:
		attempts += 1
		if not _ensure_worker():
			return {
				"ok": false,
				"status": DepthRuntimeTypes.STATUS_FAILED,
				"failure_code": "worker_spawn_failed",
				"failure_message": _worker_last_error if not _worker_last_error.is_empty() else "Depth runtime worker failed to start.",
				"runtime_stage": DepthRuntimeTypes.STAGE_DEPENDENCY_CHECK,
			}
		var request_payload := payload.duplicate(true)
		request_payload["request_id"] = request_id
		var response := _send_worker_request(request_payload)
		if bool(response.get("ok", false)) or not _should_restart_after_response(response):
			return response
		_restart_worker(String(response.get("failure_code", "worker_request_failed")), String(response.get("failure_message", "Depth runtime worker request failed.")))
	return {
		"ok": false,
		"status": DepthRuntimeTypes.STATUS_FAILED,
		"failure_code": "worker_request_failed",
		"failure_message": _worker_last_error if not _worker_last_error.is_empty() else "Depth runtime worker request failed twice.",
		"runtime_stage": DepthRuntimeTypes.STAGE_INFERENCE,
	}

func _ensure_worker() -> bool:
	if _worker_port > 0 and not _worker_token.is_empty():
		_debug_state["worker_alive"] = true
		return true
	if _python_executable.is_empty() or not FileAccess.file_exists(_python_executable):
		_worker_last_error = "Depth runtime Python executable was not found at '%s'." % _python_executable
		_debug_state["last_worker_error"] = _worker_last_error
		return false
	if not FileAccess.file_exists(_bridge_script_path):
		_worker_last_error = "Depth runtime bridge script was not found at '%s'." % _bridge_script_path
		_debug_state["last_worker_error"] = _worker_last_error
		return false
	_worker_ready_file = _temp_json_path("worker-ready")
	_worker_token = _random_token()
	var args := [_bridge_script_path, "--tcp-worker", "--ready-file", _worker_ready_file, "--token", _worker_token]
	var pid := OS.create_process(_python_executable, args, false)
	if pid <= 0:
		_worker_last_error = "Depth runtime worker process failed to spawn."
		_debug_state["last_worker_error"] = _worker_last_error
		return false
	_worker_pid = pid
	var started_at := Time.get_ticks_msec()
	while Time.get_ticks_msec() - started_at < _WORKER_READY_TIMEOUT_MS:
		if FileAccess.file_exists(_worker_ready_file):
			var parsed := JSON.parse_string(FileAccess.get_file_as_string(_worker_ready_file))
			if parsed is Dictionary:
				var ready_payload: Dictionary = parsed
				if bool(ready_payload.get("ok", false)):
					_worker_port = int(ready_payload.get("port", 0))
					_worker_generation = int(ready_payload.get("worker_generation", 0))
					if _worker_port > 0:
						_debug_state["worker_mode"] = _WORKER_MODE_PERSISTENT
						_debug_state["worker_alive"] = true
						_debug_state["worker_pid"] = _worker_pid
						_debug_state["worker_generation"] = _worker_generation
						_debug_state["worker_restart_count"] = _worker_restart_count
						_debug_state["worker_port"] = _worker_port
						_cleanup_temp_file(_worker_ready_file)
						return true
		OS.delay_msec(25)
	_worker_last_error = "Depth runtime worker did not become ready within %d ms." % _WORKER_READY_TIMEOUT_MS
	_debug_state["last_worker_error"] = _worker_last_error
	_cleanup_temp_file(_worker_ready_file)
	return false

func _send_worker_request(payload: Dictionary, measure_roundtrip: bool = true) -> Dictionary:
	var request_payload := payload.duplicate(true)
	request_payload["token"] = _worker_token
	var peer := StreamPeerTCP.new()
	var connect_error := peer.connect_to_host("127.0.0.1", _worker_port)
	if connect_error != OK:
		return _worker_transport_failure("worker_connect_failed", "Depth runtime worker connect failed with code %d." % connect_error, DepthRuntimeTypes.STAGE_DEPENDENCY_CHECK)
	var connected := _wait_for_connection(peer)
	if not connected:
		return _worker_transport_failure("worker_connect_timeout", "Depth runtime worker connect timed out.", DepthRuntimeTypes.STAGE_DEPENDENCY_CHECK)
	var transport_write_started := Time.get_ticks_usec()
	var put_error := peer.put_data((JSON.stringify(request_payload) + "\n").to_utf8_buffer())
	var transport_write_ms := float(Time.get_ticks_usec() - transport_write_started) / 1000.0
	if put_error != OK:
		peer.disconnect_from_host()
		return _worker_transport_failure("worker_write_failed", "Depth runtime worker write failed with code %d." % put_error, DepthRuntimeTypes.STAGE_INFERENCE)
	var read_started := Time.get_ticks_usec()
	var line := _read_peer_line(peer, _WORKER_REQUEST_TIMEOUT_MS)
	var transport_read_ms := float(Time.get_ticks_usec() - read_started) / 1000.0
	peer.disconnect_from_host()
	if line.is_empty():
		return _worker_transport_failure("worker_read_timeout", "Depth runtime worker response timed out.", DepthRuntimeTypes.STAGE_INFERENCE)
	var parsed := JSON.parse_string(line)
	if not (parsed is Dictionary):
		return _worker_transport_failure("worker_bad_response", "Depth runtime worker returned malformed JSON.", DepthRuntimeTypes.STAGE_INFERENCE)
	var response: Dictionary = parsed
	var timing_ms: Dictionary = response.get("timing_ms", {}) if response.get("timing_ms", {}) is Dictionary else {}
	if measure_roundtrip:
		timing_ms["transport_write"] = transport_write_ms
		timing_ms["transport_read"] = transport_read_ms
		timing_ms["bridge_roundtrip"] = transport_write_ms + transport_read_ms
		response["timing_ms"] = timing_ms
	return response

func _wait_for_connection(peer: StreamPeerTCP) -> bool:
	var started_at := Time.get_ticks_msec()
	while Time.get_ticks_msec() - started_at < _WORKER_CONNECT_TIMEOUT_MS:
		peer.poll()
		if peer.get_status() == StreamPeerTCP.STATUS_CONNECTED:
			return true
		if peer.get_status() == StreamPeerTCP.STATUS_ERROR or peer.get_status() == StreamPeerTCP.STATUS_NONE:
			return false
		OS.delay_msec(10)
	return false

func _read_peer_line(peer: StreamPeerTCP, timeout_ms: int) -> String:
	var started_at := Time.get_ticks_msec()
	var buffer := PackedByteArray()
	while Time.get_ticks_msec() - started_at < timeout_ms:
		peer.poll()
		var available := peer.get_available_bytes()
		if available > 0:
			var read_result := peer.get_data(available)
			if int(read_result[0]) != OK:
				return ""
			buffer.append_array(read_result[1])
			var text := buffer.get_string_from_utf8()
			var newline_index := text.find("\n")
			if newline_index >= 0:
				return text.substr(0, newline_index)
		if peer.get_status() == StreamPeerTCP.STATUS_NONE:
			break
		OS.delay_msec(10)
	return ""

func _should_restart_after_response(response: Dictionary) -> bool:
	var failure_code := String(response.get("failure_code", ""))
	return failure_code in [
		"worker_connect_failed",
		"worker_connect_timeout",
		"worker_write_failed",
		"worker_read_timeout",
		"worker_bad_response",
	]

func _restart_worker(code: String, message: String) -> void:
	_worker_restart_count += 1
	_worker_last_error = "%s: %s" % [code, message]
	_debug_state["last_worker_error"] = _worker_last_error
	_debug_state["worker_restart_count"] = _worker_restart_count
	shutdown()

func _worker_transport_failure(code: String, message: String, stage: String) -> Dictionary:
	_worker_last_error = message
	_debug_state["last_worker_error"] = _worker_last_error
	return {
		"ok": false,
		"status": DepthRuntimeTypes.STATUS_FAILED,
		"failure_code": code,
		"failure_message": message,
		"runtime_stage": stage,
	}

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
	_debug_state["worker_mode"] = String(response.get("worker_mode", _debug_state.get("worker_mode", _WORKER_MODE_PERSISTENT)))
	_debug_state["worker_alive"] = int(response.get("worker_pid", 0)) > 0
	_debug_state["worker_pid"] = int(response.get("worker_pid", _worker_pid))
	_debug_state["worker_generation"] = int(response.get("worker_generation", _worker_generation))
	_debug_state["worker_restart_count"] = _worker_restart_count
	_debug_state["worker_uptime_ms"] = float(response.get("worker_uptime_ms", 0.0))
	_debug_state["worker_port"] = _worker_port
	_debug_state["model_runtime_key"] = String(response.get("model_runtime_key", _debug_state.get("runtime_key", "")))
	_debug_state["model_loaded"] = bool(response.get("model_loaded", false))
	_debug_state["model_load_count"] = int(response.get("model_load_count", 0))
	_debug_state["model_reload_count"] = int(response.get("model_reload_count", 0))
	_debug_state["last_request_id"] = String(response.get("request_id", ""))
	_debug_state["last_worker_error"] = "" if bool(response.get("ok", false)) else String(response.get("failure_message", _worker_last_error))


func _sync_terminal_debug_state(status: String, stage: String, code: String, message: String, summary: String) -> void:
	_debug_state["runtime_status"] = status
	_debug_state["runtime_stage"] = stage
	_debug_state["failure_code"] = code
	_debug_state["failure_message"] = message
	_debug_state["active_model_summary"] = summary
	_debug_state["last_sample_metrics"] = {}
	_debug_state["last_timing_ms"] = {
		"preprocess": 0.0,
		"infer": 0.0,
		"postprocess": 0.0,
		"total": 0.0,
	}

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

func _cleanup_worker_state() -> void:
	_cleanup_temp_file(_worker_ready_file)
	_worker_ready_file = ""
	_worker_token = ""
	_worker_port = -1
	_worker_pid = -1
	_worker_generation = 0
	_debug_state["worker_alive"] = false
	_debug_state["worker_pid"] = 0
	_debug_state["worker_generation"] = 0
	_debug_state["worker_port"] = 0
	_debug_state["worker_uptime_ms"] = 0.0
	_debug_state["model_loaded"] = false
	_debug_state["model_runtime_key"] = ""

func _next_request_id() -> String:
	_request_serial += 1
	return "%s-%s-%d" % [_backend_id, str(OS.get_process_id()), _request_serial]

func _random_token() -> String:
	return "%s-%s-%s" % [str(OS.get_process_id()), str(Time.get_ticks_usec()), str(randi())]

func _vector2i_from_variant(value: Variant) -> Vector2i:
	if value is Array:
		var array_value: Array = value
		if array_value.size() >= 2:
			return Vector2i(int(array_value[0]), int(array_value[1]))
	return Vector2i.ZERO
