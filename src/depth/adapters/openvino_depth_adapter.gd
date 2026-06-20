class_name OpenvinoDepthAdapter
extends "res://addons/aerobeat-input-camera-tracking/src/depth/depth_model_adapter.gd"


func load(model_spec: Dictionary) -> Dictionary:
	super.load(model_spec)
	_debug_state["backend_id"] = "openvino"
	_debug_state["runtime_status"] = DepthRuntimeTypes.STATUS_BLOCKED
	_debug_state["runtime_stage"] = DepthRuntimeTypes.STAGE_DEPENDENCY_CHECK
	_debug_state["failure_code"] = "adapter_unimplemented"
	_debug_state["failure_message"] = "OpenVINO depth execution is not wired in this repo yet. Artifact resolution works, but no runnable OpenVINO inference substrate exists here today."
	_debug_state["active_model_summary"] = "enabled; artifact resolved to %s via openvino but execution is not wired yet" % String(_debug_state.get("family_id", "unknown"))
	return {
		"ok": false,
		"status": DepthRuntimeTypes.STATUS_BLOCKED,
		"failure_code": String(_debug_state.get("failure_code", "adapter_unimplemented")),
		"failure_message": String(_debug_state.get("failure_message", "")),
	}
