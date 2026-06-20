class_name DepthModelAdapter
extends RefCounted

const DepthRuntimeTypes = preload("res://addons/aerobeat-input-camera-tracking/src/depth/depth_runtime_types.gd")
const DepthPythonRuntimeBridgeScript = preload("res://addons/aerobeat-input-camera-tracking/src/depth/depth_python_runtime_bridge.gd")

var _model_spec: Dictionary = {}
var _debug_state: Dictionary = DepthRuntimeTypes.make_debug_state()
var _runtime_bridge: RefCounted = null

func load(model_spec: Dictionary) -> Dictionary:
	_initialize_model_state(model_spec)
	return {
		"ok": false,
		"status": String(_debug_state.get("runtime_status", DepthRuntimeTypes.STATUS_BLOCKED)),
		"failure_code": String(_debug_state.get("failure_code", "adapter_unimplemented")),
		"failure_message": String(_debug_state.get("failure_message", "")),
	}

func load_via_python_runtime(model_spec: Dictionary, backend_id: String) -> Dictionary:
	_initialize_model_state(model_spec)
	_runtime_bridge = DepthPythonRuntimeBridgeScript.new()
	_runtime_bridge.configure(_model_spec, backend_id)
	var probe_result: Dictionary = _runtime_bridge.probe_runtime()
	_debug_state = _runtime_bridge.get_debug_state()
	return probe_result

func _initialize_model_state(model_spec: Dictionary) -> void:
	_model_spec = model_spec.duplicate(true)
	_debug_state = DepthRuntimeTypes.make_debug_state()
	_debug_state["configured"] = true
	_debug_state["family"] = String(_model_spec.get("family", ""))
	_debug_state["depth_enabled"] = true
	_debug_state["artifact_path_res"] = String(_model_spec.get("artifact_path_res", ""))
	_debug_state["artifact_path_abs"] = String(_model_spec.get("artifact_path_abs", ""))
	_debug_state["artifact_exists"] = bool(_model_spec.get("artifact_exists", false))
	_debug_state["artifact_kind"] = String(_model_spec.get("artifact_kind", "missing"))
	_debug_state["family_id"] = String(_model_spec.get("family_id", "unknown"))
	_debug_state["backend_id"] = String(_model_spec.get("backend_id", "unknown"))
	_debug_state["runtime_key"] = String(_model_spec.get("runtime_key", ""))
	_debug_state["runtime_status"] = DepthRuntimeTypes.STATUS_BLOCKED
	_debug_state["runtime_stage"] = DepthRuntimeTypes.STAGE_ADAPTER_LOAD
	_debug_state["failure_code"] = "adapter_unimplemented"
	_debug_state["failure_message"] = "Depth adapter base class does not implement runtime loading."
	_debug_state["active_model_summary"] = "depth adapter base class is not executable"
	_runtime_bridge = null

func infer(_frame_payload: Dictionary, _request: Dictionary) -> Dictionary:
	var result := DepthRuntimeTypes.make_result(String(_debug_state.get("runtime_status", DepthRuntimeTypes.STATUS_BLOCKED)))
	result["backend_id"] = String(_debug_state.get("backend_id", "unknown"))
	result["family_id"] = String(_debug_state.get("family_id", "unknown"))
	result["artifact_path"] = String(_debug_state.get("artifact_path_res", ""))
	result["error_info"] = {
		"code": String(_debug_state.get("failure_code", "adapter_unimplemented")),
		"message": String(_debug_state.get("failure_message", "Depth adapter is not implemented.")),
	}
	return result

func infer_via_python_runtime(frame_payload: Dictionary, request: Dictionary) -> Dictionary:
	if _runtime_bridge == null:
		return infer(frame_payload, request)
	var result: Dictionary = _runtime_bridge.infer(frame_payload, request)
	_debug_state = _runtime_bridge.get_debug_state()
	return result

func get_debug_state() -> Dictionary:
	return _debug_state.duplicate(true)

func unload() -> void:
	_model_spec = {}
	_runtime_bridge = null
	_debug_state["runtime_status"] = DepthRuntimeTypes.STATUS_UNLOADED
	_debug_state["runtime_stage"] = DepthRuntimeTypes.STAGE_IDLE
	_debug_state["active_model_summary"] = "depth runtime unloaded"
