class_name DepthRuntimeTypes
extends RefCounted

const STATUS_DISABLED := "disabled"
const STATUS_UNLOADED := "unloaded"
const STATUS_LOADING := "loading"
const STATUS_READY := "ready"
const STATUS_BLOCKED := "blocked"
const STATUS_FAILED := "failed"

const STAGE_IDLE := "idle"
const STAGE_ARTIFACT_RESOLUTION := "artifact_resolution"
const STAGE_DEPENDENCY_CHECK := "dependency_check"
const STAGE_ADAPTER_LOAD := "adapter_load"
const STAGE_INFERENCE := "inference"
const STAGE_SAMPLING := "sampling"

static func make_debug_state() -> Dictionary:
	return {
		"configured": false,
		"family": "",
		"depth_enabled": false,
		"artifact_path_res": "",
		"artifact_path_abs": "",
		"artifact_exists": false,
		"artifact_kind": "missing",
		"family_id": "unknown",
		"backend_id": "unknown",
		"runtime_key": "",
		"runtime_status": STATUS_UNLOADED,
		"runtime_stage": STAGE_IDLE,
		"failure_code": "",
		"failure_message": "",
		"active_model_summary": "depth runtime not configured",
		"worker_mode": "persistent_tcp",
		"worker_alive": false,
		"worker_pid": 0,
		"worker_generation": 0,
		"worker_restart_count": 0,
		"worker_uptime_ms": 0.0,
		"worker_port": 0,
		"model_loaded": false,
		"model_runtime_key": "",
		"model_load_count": 0,
		"model_reload_count": 0,
		"last_request_id": "",
		"last_worker_error": "",
		"shared_runtime_key": "",
		"shared_runtime_refcount": 0,
		"shared_runtime_family_claims": [],
		"shared_runtime_claimed": false,
		"shared_runtime_shared": false,
		"last_timing_ms": {
			"preprocess": 0.0,
			"infer": 0.0,
			"postprocess": 0.0,
			"total": 0.0,
		},
		"last_sample_metrics": {},
	}

static func make_result(status: String = STATUS_UNLOADED) -> Dictionary:
	return {
		"ok": false,
		"status": status,
		"backend_id": "unknown",
		"family_id": "unknown",
		"artifact_path": "",
		"frame_size": Vector2i.ZERO,
		"depth_map_size": Vector2i.ZERO,
		"depth_orientation": "larger_is_farther",
		"normalized_depth_map": null,
		"sample_metrics": {},
		"timing_ms": {
			"preprocess": 0.0,
			"infer": 0.0,
			"postprocess": 0.0,
			"total": 0.0,
		},
		"error_info": {},
	}

static func describe_model(spec: Dictionary) -> String:
	var family_id := String(spec.get("family_id", "unknown"))
	var backend_id := String(spec.get("backend_id", "unknown"))
	var artifact_path := String(spec.get("artifact_path_res", ""))
	if artifact_path.is_empty():
		artifact_path = String(spec.get("artifact_path_abs", ""))
	return "%s via %s (%s)" % [family_id, backend_id, artifact_path]
