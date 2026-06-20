class_name DepthRuntimeManager
extends RefCounted

const DepthRuntimeTypes = preload("res://addons/aerobeat-input-camera-tracking/src/depth/depth_runtime_types.gd")
const OpenvinoDepthAdapterScript = preload("res://addons/aerobeat-input-camera-tracking/src/depth/adapters/openvino_depth_adapter.gd")
const OnnxDepthAdapterScript = preload("res://addons/aerobeat-input-camera-tracking/src/depth/adapters/onnx_depth_adapter.gd")

var _family := ""
var _family_depth_config: Dictionary = {}
var _debug_state: Dictionary = DepthRuntimeTypes.make_debug_state()
var _active_runtime_key := ""
var _active_model_spec: Dictionary = {}
var _adapter: RefCounted = null

func configure_from_family(family: String, family_depth_config: Dictionary) -> void:
	_family = family
	_family_depth_config = family_depth_config.duplicate(true)
	_debug_state = DepthRuntimeTypes.make_debug_state()
	_debug_state["configured"] = true
	_debug_state["family"] = family
	_debug_state["depth_enabled"] = bool(_family_depth_config.get("enabled", false))
	_debug_state["runtime_status"] = DepthRuntimeTypes.STATUS_DISABLED if not bool(_debug_state.get("depth_enabled", false)) else DepthRuntimeTypes.STATUS_UNLOADED
	_debug_state["active_model_summary"] = "disabled in config" if not bool(_debug_state.get("depth_enabled", false)) else "depth runtime configured; waiting for artifact resolution"
	_active_runtime_key = ""
	_active_model_spec = {}
	if _adapter != null:
		_adapter.unload()
		_adapter = null

func ensure_runtime_ready() -> Dictionary:
	if _family.is_empty():
		_debug_state = DepthRuntimeTypes.make_debug_state()
		_debug_state["active_model_summary"] = "depth runtime not configured"
		return _debug_state.duplicate(true)
	if not bool(_family_depth_config.get("enabled", false)):
		_debug_state["configured"] = true
		_debug_state["family"] = _family
		_debug_state["depth_enabled"] = false
		_debug_state["runtime_status"] = DepthRuntimeTypes.STATUS_DISABLED
		_debug_state["runtime_stage"] = DepthRuntimeTypes.STAGE_IDLE
		_debug_state["failure_code"] = ""
		_debug_state["failure_message"] = ""
		_debug_state["active_model_summary"] = "disabled in config"
		return _debug_state.duplicate(true)

	_debug_state["runtime_stage"] = DepthRuntimeTypes.STAGE_ARTIFACT_RESOLUTION
	var model_spec := _resolve_model_spec()
	_apply_model_spec_to_debug(model_spec)
	if not bool(model_spec.get("artifact_exists", false)):
		_debug_state["runtime_status"] = DepthRuntimeTypes.STATUS_FAILED
		_debug_state["failure_code"] = "artifact_missing"
		_debug_state["failure_message"] = "Depth artifact path could not be resolved to an existing file or directory."
		_debug_state["active_model_summary"] = "enabled; depth artifact missing at %s" % String(model_spec.get("artifact_path_res", model_spec.get("artifact_path_abs", "")))
		_release_adapter()
		return _debug_state.duplicate(true)
	var backend_id := String(model_spec.get("backend_id", "unknown"))
	if backend_id == "unknown":
		_debug_state["runtime_status"] = DepthRuntimeTypes.STATUS_FAILED
		_debug_state["failure_code"] = "unsupported_artifact"
		_debug_state["failure_message"] = "Depth artifact exists, but its backend/family could not be inferred from the approved path/shape rules."
		_debug_state["active_model_summary"] = "enabled; artifact exists but backend could not be inferred"
		_release_adapter()
		return _debug_state.duplicate(true)
	var runtime_key := String(model_spec.get("runtime_key", ""))
	if runtime_key == _active_runtime_key and _adapter != null:
		_merge_adapter_debug()
		return _debug_state.duplicate(true)

	_release_adapter()
	_adapter = _create_adapter_for_backend(backend_id)
	_active_runtime_key = runtime_key
	_active_model_spec = model_spec.duplicate(true)
	_debug_state["runtime_key"] = runtime_key
	_debug_state["runtime_status"] = DepthRuntimeTypes.STATUS_LOADING
	_debug_state["runtime_stage"] = DepthRuntimeTypes.STAGE_ADAPTER_LOAD
	if _adapter == null:
		_debug_state["runtime_status"] = DepthRuntimeTypes.STATUS_FAILED
		_debug_state["failure_code"] = "unsupported_backend"
		_debug_state["failure_message"] = "No adapter is registered for backend '%s'." % backend_id
		_debug_state["active_model_summary"] = "enabled; artifact resolved but backend '%s' is unsupported" % backend_id
		return _debug_state.duplicate(true)
	var load_result: Dictionary = _adapter.load(model_spec)
	_merge_adapter_debug()
	if bool(load_result.get("ok", false)):
		_debug_state["runtime_status"] = DepthRuntimeTypes.STATUS_READY
		_debug_state["failure_code"] = ""
		_debug_state["failure_message"] = ""
		_debug_state["active_model_summary"] = "enabled; runtime ready via %s" % backend_id
		return _debug_state.duplicate(true)
	if String(_debug_state.get("runtime_status", "")) == DepthRuntimeTypes.STATUS_LOADING:
		_debug_state["runtime_status"] = String(load_result.get("status", DepthRuntimeTypes.STATUS_BLOCKED))
	_debug_state["failure_code"] = String(load_result.get("failure_code", _debug_state.get("failure_code", "adapter_unimplemented")))
	_debug_state["failure_message"] = String(load_result.get("failure_message", _debug_state.get("failure_message", "Depth runtime failed to load.")))
	if String(_debug_state.get("active_model_summary", "")).is_empty():
		_debug_state["active_model_summary"] = "enabled; runtime failed to load"
	return _debug_state.duplicate(true)

func infer_relative_depth(frame_payload: Dictionary, sample_request: Dictionary) -> Dictionary:
	var ready_state := ensure_runtime_ready()
	var runtime_status := String(ready_state.get("runtime_status", DepthRuntimeTypes.STATUS_UNLOADED))
	if runtime_status != DepthRuntimeTypes.STATUS_READY or _adapter == null:
		var blocked_result := DepthRuntimeTypes.make_result(runtime_status)
		blocked_result["backend_id"] = String(ready_state.get("backend_id", "unknown"))
		blocked_result["family_id"] = String(ready_state.get("family_id", "unknown"))
		blocked_result["artifact_path"] = String(ready_state.get("artifact_path_res", ""))
		blocked_result["sample_metrics"] = (ready_state.get("last_sample_metrics", {}) as Dictionary).duplicate(true)
		blocked_result["timing_ms"] = (ready_state.get("last_timing_ms", {}) as Dictionary).duplicate(true)
		blocked_result["error_info"] = {
			"code": String(ready_state.get("failure_code", "")),
			"message": String(ready_state.get("failure_message", "")),
		}
		return blocked_result
	_debug_state["runtime_stage"] = DepthRuntimeTypes.STAGE_INFERENCE
	var result: Dictionary = _adapter.infer(frame_payload, sample_request)
	_merge_adapter_debug()
	var sample_metrics: Dictionary = result.get("sample_metrics", {}) if result.get("sample_metrics", {}) is Dictionary else {}
	var timing_ms: Dictionary = result.get("timing_ms", {}) if result.get("timing_ms", {}) is Dictionary else {}
	_debug_state["last_sample_metrics"] = sample_metrics.duplicate(true)
	_debug_state["last_timing_ms"] = timing_ms.duplicate(true)
	if not bool(result.get("ok", false)):
		_debug_state["runtime_status"] = String(result.get("status", DepthRuntimeTypes.STATUS_FAILED))
		var error_info: Dictionary = result.get("error_info", {}) if result.get("error_info", {}) is Dictionary else {}
		_debug_state["failure_code"] = String(error_info.get("code", _debug_state.get("failure_code", "infer_failed")))
		_debug_state["failure_message"] = String(error_info.get("message", _debug_state.get("failure_message", "Depth inference failed.")))
		if String(_debug_state.get("active_model_summary", "")).is_empty():
			_debug_state["active_model_summary"] = "enabled; last inference failed: %s" % String(_debug_state.get("failure_code", "infer_failed"))
		return result
	_debug_state["runtime_status"] = DepthRuntimeTypes.STATUS_READY
	_debug_state["runtime_stage"] = DepthRuntimeTypes.STAGE_SAMPLING
	_debug_state["failure_code"] = ""
	_debug_state["failure_message"] = ""
	_debug_state["active_model_summary"] = "enabled; runtime ready via %s" % String(_debug_state.get("backend_id", "unknown"))
	return result

func get_debug_state() -> Dictionary:
	return _debug_state.duplicate(true)

func release_unused_runtime() -> void:
	if bool(_family_depth_config.get("enabled", false)):
		return
	shutdown()

func shutdown() -> void:
	_release_adapter()
	_active_runtime_key = ""
	_active_model_spec = {}
	if _family.is_empty():
		_debug_state = DepthRuntimeTypes.make_debug_state()
		return
	_debug_state["configured"] = true
	_debug_state["family"] = _family
	_debug_state["depth_enabled"] = bool(_family_depth_config.get("enabled", false))
	_debug_state["runtime_stage"] = DepthRuntimeTypes.STAGE_IDLE
	_debug_state["runtime_status"] = DepthRuntimeTypes.STATUS_DISABLED if not bool(_family_depth_config.get("enabled", false)) else DepthRuntimeTypes.STATUS_UNLOADED
	_debug_state["active_model_summary"] = "disabled in config" if not bool(_family_depth_config.get("enabled", false)) else "depth runtime unloaded"

func _resolve_model_spec() -> Dictionary:
	var model_document: Dictionary = _family_depth_config.get("model", {}) if _family_depth_config.get("model", {}) is Dictionary else {}
	var artifact_path_res := String(model_document.get("artifact_path", "")).strip_edges()
	var artifact_path_abs := ProjectSettings.globalize_path(artifact_path_res) if artifact_path_res.begins_with("res://") else artifact_path_res
	var artifact_exists := false
	var artifact_kind := "missing"
	if not artifact_path_abs.is_empty():
		if DirAccess.dir_exists_absolute(artifact_path_abs):
			artifact_exists = true
			artifact_kind = "directory"
		elif FileAccess.file_exists(artifact_path_abs):
			artifact_exists = true
			artifact_kind = "file"
	var family_id := "unknown"
	var backend_id := "unknown"
	if artifact_kind == "directory":
		if _directory_has_openvino_pair(artifact_path_abs):
			backend_id = "openvino"
			family_id = "midas_openvino_v21_small_256" if artifact_path_abs.contains("openvino_midas_v21_small_256") else "custom"
	elif artifact_kind == "file":
		var artifact_path_abs_lower := artifact_path_abs.to_lower()
		if artifact_path_abs_lower.ends_with(".onnx"):
			backend_id = "onnx"
			if artifact_path_abs_lower.contains("fastdepth"):
				family_id = "fastdepth_224_onnx"
			elif artifact_path_abs_lower.contains("depth_anything_v2") or artifact_path_abs_lower.contains("depth_anything_v2_small"):
				family_id = "depth_anything_v2_small_onnx"
			else:
				family_id = "custom"
	var runtime_key := "%s:%s:%s" % [backend_id, family_id, artifact_path_abs]
	return {
		"family": _family,
		"artifact_path_res": artifact_path_res,
		"artifact_path_abs": artifact_path_abs,
		"artifact_exists": artifact_exists,
		"artifact_kind": artifact_kind,
		"family_id": family_id,
		"backend_id": backend_id,
		"loader_key": "%s:%s" % [backend_id, family_id],
		"runtime_key": runtime_key,
		"evaluation": (_family_depth_config.get("evaluation", {}) as Dictionary).duplicate(true) if _family_depth_config.get("evaluation", {}) is Dictionary else {},
		"thresholds": (_family_depth_config.get("thresholds", {}) as Dictionary).duplicate(true) if _family_depth_config.get("thresholds", {}) is Dictionary else {},
		"debug": (_family_depth_config.get("debug", {}) as Dictionary).duplicate(true) if _family_depth_config.get("debug", {}) is Dictionary else {},
	}

func _directory_has_openvino_pair(path: String) -> bool:
	var files := DirAccess.get_files_at(path)
	var has_xml := false
	var has_bin := false
	for file_name in files:
		var file_name_string := String(file_name).to_lower()
		if file_name_string.ends_with(".xml"):
			has_xml = true
		elif file_name_string.ends_with(".bin"):
			has_bin = true
	return has_xml and has_bin

func _create_adapter_for_backend(backend_id: String) -> RefCounted:
	match backend_id:
		"openvino":
			return OpenvinoDepthAdapterScript.new()
		"onnx":
			return OnnxDepthAdapterScript.new()
		_:
			return null

func _apply_model_spec_to_debug(model_spec: Dictionary) -> void:
	_debug_state["configured"] = true
	_debug_state["family"] = _family
	_debug_state["depth_enabled"] = bool(_family_depth_config.get("enabled", false))
	_debug_state["artifact_path_res"] = String(model_spec.get("artifact_path_res", ""))
	_debug_state["artifact_path_abs"] = String(model_spec.get("artifact_path_abs", ""))
	_debug_state["artifact_exists"] = bool(model_spec.get("artifact_exists", false))
	_debug_state["artifact_kind"] = String(model_spec.get("artifact_kind", "missing"))
	_debug_state["family_id"] = String(model_spec.get("family_id", "unknown"))
	_debug_state["backend_id"] = String(model_spec.get("backend_id", "unknown"))
	_debug_state["runtime_key"] = String(model_spec.get("runtime_key", ""))

func _merge_adapter_debug() -> void:
	if _adapter == null:
		return
	var adapter_debug: Dictionary = _adapter.get_debug_state()
	for key in adapter_debug.keys():
		_debug_state[key] = adapter_debug[key]

func _release_adapter() -> void:
	if _adapter == null:
		return
	_adapter.unload()
	_adapter = null
