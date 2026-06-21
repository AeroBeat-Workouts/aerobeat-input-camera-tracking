class_name DepthRuntimeManager
extends RefCounted

const DepthRuntimeTypes = preload("res://addons/aerobeat-input-camera-tracking/src/depth/depth_runtime_types.gd")
const DepthSharedRuntimePoolScript = preload("res://addons/aerobeat-input-camera-tracking/src/depth/depth_shared_runtime_pool.gd")

var _family := ""
var _family_depth_config: Dictionary = {}
var _debug_state: Dictionary = DepthRuntimeTypes.make_debug_state()
var _active_runtime_key := ""
var _active_model_spec: Dictionary = {}
var _shared_runtime_pool: RefCounted = DepthSharedRuntimePoolScript.new()
var _eligible_sample_request_count := 0
var _last_successful_result: Dictionary = {}

func set_shared_runtime_pool(shared_runtime_pool: RefCounted) -> void:
	if shared_runtime_pool == null:
		_shared_runtime_pool = DepthSharedRuntimePoolScript.new()
		return
	_shared_runtime_pool = shared_runtime_pool

func configure_from_family(family: String, family_depth_config: Dictionary) -> void:
	var previous_family := _family
	_release_shared_runtime(previous_family)
	_family = family
	_family_depth_config = family_depth_config.duplicate(true)
	_debug_state = DepthRuntimeTypes.make_debug_state()
	_debug_state["configured"] = true
	_debug_state["family"] = family
	_debug_state["depth_enabled"] = bool(_family_depth_config.get("enabled", false))
	_debug_state["runtime_status"] = DepthRuntimeTypes.STATUS_DISABLED if not bool(_debug_state.get("depth_enabled", false)) else DepthRuntimeTypes.STATUS_UNLOADED
	_debug_state["active_model_summary"] = "disabled in config" if not bool(_debug_state.get("depth_enabled", false)) else "depth runtime configured; waiting for artifact resolution"
	_apply_cadence_settings_from_request({})
	_active_runtime_key = ""
	_active_model_spec = {}
	_reset_sample_cache()

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
		_debug_state["shared_runtime_key"] = ""
		_debug_state["shared_runtime_refcount"] = 0
		_debug_state["shared_runtime_family_claims"] = []
		_debug_state["shared_runtime_claimed"] = false
		_debug_state["shared_runtime_shared"] = false
		return _debug_state.duplicate(true)

	_debug_state["runtime_stage"] = DepthRuntimeTypes.STAGE_ARTIFACT_RESOLUTION
	var model_spec := _resolve_model_spec()
	_apply_model_spec_to_debug(model_spec)
	if not bool(model_spec.get("artifact_exists", false)):
		_debug_state["runtime_status"] = DepthRuntimeTypes.STATUS_FAILED
		_debug_state["failure_code"] = "artifact_missing"
		_debug_state["failure_message"] = "Depth artifact path could not be resolved to an existing file or directory."
		_debug_state["active_model_summary"] = "enabled; depth artifact missing at %s" % String(model_spec.get("artifact_path_res", model_spec.get("artifact_path_abs", "")))
		_release_shared_runtime()
		return _debug_state.duplicate(true)
	var backend_id := String(model_spec.get("backend_id", "unknown"))
	if backend_id == "unknown":
		_debug_state["runtime_status"] = DepthRuntimeTypes.STATUS_FAILED
		_debug_state["failure_code"] = "unsupported_artifact"
		_debug_state["failure_message"] = "Depth artifact exists, but its backend/family could not be inferred from the approved path/shape rules."
		_debug_state["active_model_summary"] = "enabled; artifact exists but backend could not be inferred"
		_release_shared_runtime()
		return _debug_state.duplicate(true)

	var runtime_key := String(model_spec.get("runtime_key", ""))
	if runtime_key != _active_runtime_key:
		_release_shared_runtime()
		var acquire_result: Dictionary = _shared_runtime_pool.acquire(_family, model_spec)
		_active_runtime_key = runtime_key
		_active_model_spec = model_spec.duplicate(true)
		_merge_shared_runtime_debug(_shared_runtime_pool.get_runtime_debug(runtime_key), false)
		if bool(acquire_result.get("ok", false)):
			_debug_state["runtime_status"] = DepthRuntimeTypes.STATUS_READY
			_debug_state["runtime_stage"] = DepthRuntimeTypes.STAGE_SAMPLING
			_debug_state["failure_code"] = ""
			_debug_state["failure_message"] = ""
			_debug_state["active_model_summary"] = "enabled; runtime ready via %s" % backend_id
			return _debug_state.duplicate(true)
		if String(_debug_state.get("runtime_status", "")) == DepthRuntimeTypes.STATUS_LOADING:
			_debug_state["runtime_status"] = String(acquire_result.get("status", DepthRuntimeTypes.STATUS_BLOCKED))
		_debug_state["failure_code"] = String(acquire_result.get("failure_code", _debug_state.get("failure_code", "adapter_unimplemented")))
		_debug_state["failure_message"] = String(acquire_result.get("failure_message", _debug_state.get("failure_message", "Depth runtime failed to load.")))
		if String(_debug_state.get("active_model_summary", "")).is_empty():
			_debug_state["active_model_summary"] = "enabled; runtime failed to load"
		return _debug_state.duplicate(true)

	_merge_shared_runtime_debug(_shared_runtime_pool.get_runtime_debug(runtime_key), true)
	return _debug_state.duplicate(true)

func infer_relative_depth(frame_payload: Dictionary, sample_request: Dictionary) -> Dictionary:
	var ready_state := ensure_runtime_ready()
	_apply_cadence_settings_from_request(sample_request)
	var runtime_status := String(ready_state.get("runtime_status", DepthRuntimeTypes.STATUS_UNLOADED))
	var precomputed_result := _extract_precomputed_result(frame_payload, sample_request, runtime_status)
	if bool(precomputed_result.get("ok", false)):
		_sync_debug_from_result(precomputed_result, sample_request)
		return precomputed_result
	if runtime_status != DepthRuntimeTypes.STATUS_READY or _active_runtime_key.is_empty():
		var blocked_result := DepthRuntimeTypes.make_result(runtime_status)
		blocked_result["backend_id"] = String(ready_state.get("backend_id", "unknown"))
		blocked_result["family_id"] = String(ready_state.get("family_id", "unknown"))
		blocked_result["artifact_path"] = String(ready_state.get("artifact_path_res", ""))
		blocked_result["sample_metrics"] = (ready_state.get("last_sample_metrics", {}) as Dictionary).duplicate(true)
		blocked_result["timing_ms"] = (ready_state.get("last_timing_ms", {}) as Dictionary).duplicate(true)
		blocked_result["frame_size"] = ready_state.get("frame_size", Vector2i.ZERO)
		blocked_result["depth_map_size"] = ready_state.get("depth_map_size", Vector2i.ZERO)
		blocked_result["normalized_depth_map"] = ready_state.get("normalized_depth_map", null)
		blocked_result["error_info"] = {
			"code": String(ready_state.get("failure_code", "")),
			"message": String(ready_state.get("failure_message", "")),
		}
		return blocked_result

	_eligible_sample_request_count += 1
	if not _should_run_fresh_inference(sample_request):
		var cached_result := _build_cached_reuse_result(sample_request)
		if bool(cached_result.get("ok", false)):
			_sync_debug_from_result(cached_result, sample_request)
		else:
			_debug_state["runtime_status"] = DepthRuntimeTypes.STATUS_READY
			_debug_state["runtime_stage"] = DepthRuntimeTypes.STAGE_SAMPLING
			_debug_state["failure_code"] = String((cached_result.get("error_info", {}) as Dictionary).get("code", "cached_sample_unavailable"))
			_debug_state["failure_message"] = String((cached_result.get("error_info", {}) as Dictionary).get("message", "No valid cached depth sample was available for reuse."))
		return cached_result

	_debug_state["runtime_stage"] = DepthRuntimeTypes.STAGE_INFERENCE
	var result: Dictionary = _shared_runtime_pool.infer(_active_runtime_key, frame_payload, sample_request)
	_merge_shared_runtime_debug(_shared_runtime_pool.get_runtime_debug(_active_runtime_key), false)
	if not bool(result.get("ok", false)):
		var sample_metrics: Dictionary = result.get("sample_metrics", {}) if result.get("sample_metrics", {}) is Dictionary else {}
		var timing_ms: Dictionary = result.get("timing_ms", {}) if result.get("timing_ms", {}) is Dictionary else {}
		_debug_state["last_sample_metrics"] = sample_metrics.duplicate(true)
		_debug_state["last_timing_ms"] = timing_ms.duplicate(true)
		_debug_state["runtime_status"] = String(result.get("status", DepthRuntimeTypes.STATUS_FAILED))
		var error_info: Dictionary = result.get("error_info", {}) if result.get("error_info", {}) is Dictionary else {}
		_debug_state["failure_code"] = String(error_info.get("code", _debug_state.get("failure_code", "infer_failed")))
		_debug_state["failure_message"] = String(error_info.get("message", _debug_state.get("failure_message", "Depth inference failed.")))
		if String(_debug_state.get("active_model_summary", "")).is_empty():
			_debug_state["active_model_summary"] = "enabled; last inference failed: %s" % String(_debug_state.get("failure_code", "infer_failed"))
		return result
	_store_successful_result(result, sample_request)
	_sync_debug_from_result(result, sample_request)
	_debug_state["runtime_status"] = DepthRuntimeTypes.STATUS_READY
	_debug_state["runtime_stage"] = DepthRuntimeTypes.STAGE_SAMPLING
	_debug_state["failure_code"] = ""
	_debug_state["failure_message"] = ""
	_debug_state["active_model_summary"] = "enabled; runtime ready via %s" % String(_debug_state.get("backend_id", "unknown"))
	return result

func get_debug_state() -> Dictionary:
	if not _active_runtime_key.is_empty():
		_merge_shared_runtime_debug(_shared_runtime_pool.get_runtime_debug(_active_runtime_key), true)
	return _debug_state.duplicate(true)

func release_unused_runtime() -> void:
	if bool(_family_depth_config.get("enabled", false)):
		return
	shutdown()

func shutdown() -> void:
	_release_shared_runtime()
	if _family.is_empty():
		_debug_state = DepthRuntimeTypes.make_debug_state()
		return
	_debug_state["configured"] = true
	_debug_state["family"] = _family
	_debug_state["depth_enabled"] = bool(_family_depth_config.get("enabled", false))
	_debug_state["runtime_stage"] = DepthRuntimeTypes.STAGE_IDLE
	_debug_state["runtime_status"] = DepthRuntimeTypes.STATUS_DISABLED if not bool(_family_depth_config.get("enabled", false)) else DepthRuntimeTypes.STATUS_UNLOADED
	_debug_state["failure_code"] = ""
	_debug_state["failure_message"] = ""
	_debug_state["active_model_summary"] = "disabled in config" if not bool(_family_depth_config.get("enabled", false)) else "depth runtime unloaded"
	_debug_state["worker_alive"] = false
	_debug_state["worker_pid"] = 0
	_debug_state["worker_generation"] = 0
	_debug_state["worker_restart_count"] = 0
	_debug_state["worker_uptime_ms"] = 0.0
	_debug_state["worker_port"] = 0
	_debug_state["model_loaded"] = false
	_debug_state["model_runtime_key"] = ""
	_reset_sample_cache()
	_apply_cadence_settings_from_request({})

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
	_debug_state["shared_runtime_key"] = String(model_spec.get("runtime_key", ""))

func _merge_shared_runtime_debug(shared_debug: Dictionary, preserve_last_observation: bool) -> void:
	var previous_last_sample_metrics: Dictionary = (_debug_state.get("last_sample_metrics", {}) as Dictionary).duplicate(true)
	var previous_last_timing_ms: Dictionary = (_debug_state.get("last_timing_ms", {}) as Dictionary).duplicate(true)
	var previous_frame_size: Vector2i = _debug_state.get("frame_size", Vector2i.ZERO)
	var previous_depth_map_size: Vector2i = _debug_state.get("depth_map_size", Vector2i.ZERO)
	var previous_normalized_depth_map: Variant = _debug_state.get("normalized_depth_map", null)
	var previous_last_sample_timestamp_ms := int(_debug_state.get("last_sample_timestamp_ms", -1))
	var previous_last_sample_age_ms := int(_debug_state.get("last_sample_age_ms", -1))
	var previous_failure_code := String(_debug_state.get("failure_code", ""))
	var previous_failure_message := String(_debug_state.get("failure_message", ""))
	for key in shared_debug.keys():
		_debug_state[key] = shared_debug[key]
	_debug_state["family"] = _family
	_debug_state["depth_enabled"] = bool(_family_depth_config.get("enabled", false))
	_apply_cadence_settings_from_request({})
	if preserve_last_observation:
		_debug_state["last_sample_metrics"] = previous_last_sample_metrics
		_debug_state["last_timing_ms"] = previous_last_timing_ms
		_debug_state["frame_size"] = previous_frame_size
		_debug_state["depth_map_size"] = previous_depth_map_size
		_debug_state["normalized_depth_map"] = previous_normalized_depth_map
		_debug_state["last_sample_timestamp_ms"] = previous_last_sample_timestamp_ms
		_debug_state["last_sample_age_ms"] = previous_last_sample_age_ms
		_debug_state["failure_code"] = previous_failure_code
		_debug_state["failure_message"] = previous_failure_message

func _release_shared_runtime(claim_family: String = "") -> void:
	if _active_runtime_key.is_empty():
		return
	var family_claim := claim_family if not claim_family.is_empty() else _family
	var release_debug: Dictionary = _shared_runtime_pool.release(family_claim, _active_runtime_key)
	_merge_shared_runtime_debug(release_debug, false)
	_debug_state["shared_runtime_key"] = ""
	_debug_state["shared_runtime_refcount"] = 0
	_debug_state["shared_runtime_family_claims"] = []
	_debug_state["shared_runtime_claimed"] = false
	_debug_state["shared_runtime_shared"] = false
	_active_runtime_key = ""
	_active_model_spec = {}

func _extract_precomputed_result(frame_payload: Dictionary, sample_request: Dictionary, fallback_status: String) -> Dictionary:
	var family := String(sample_request.get("family", _family))
	var side := String(sample_request.get("side", "")).strip_edges()
	var family_candidates: Array = []
	var direct_depth := frame_payload.get("depth", {}) if frame_payload.get("depth", {}) is Dictionary else {}
	var direct_runtime := frame_payload.get("depth_runtime", {}) if frame_payload.get("depth_runtime", {}) is Dictionary else {}
	var family_depth_samples := frame_payload.get("depth_family_samples", {}) if frame_payload.get("depth_family_samples", {}) is Dictionary else {}
	var runtime_family_samples := frame_payload.get("depth_runtime_samples", {}) if frame_payload.get("depth_runtime_samples", {}) is Dictionary else {}
	family_candidates.append(family_depth_samples)
	family_candidates.append(runtime_family_samples)
	for container in [direct_depth, direct_runtime]:
		if container.is_empty():
			continue
		var families: Dictionary = container.get("families", {}) if container.get("families", {}) is Dictionary else {}
		family_candidates.append(families)
		family_candidates.append(container)
	for candidate_variant: Variant in family_candidates:
		if not candidate_variant is Dictionary:
			continue
		var candidate: Dictionary = candidate_variant
		var family_payload: Variant = candidate.get(family, null)
		if family_payload is Dictionary:
			var resolved := _normalize_precomputed_sample_result(family_payload, side, fallback_status)
			if bool(resolved.get("ok", false)):
				return resolved
	return DepthRuntimeTypes.make_result(fallback_status)

func _normalize_precomputed_sample_result(family_payload: Dictionary, side: String, fallback_status: String) -> Dictionary:
	var sample_payload: Dictionary = family_payload
	if not side.is_empty() and family_payload.get(side, null) is Dictionary:
		sample_payload = family_payload.get(side, {})
	var sample_metrics: Dictionary = sample_payload.get("sample_metrics", {}) if sample_payload.get("sample_metrics", {}) is Dictionary else sample_payload
	var closeness := _first_float(sample_metrics, ["wrist_closeness", "closeness", "normalized_closeness", "torso_minus_wrist_closeness"], NAN)
	if is_nan(closeness):
		return DepthRuntimeTypes.make_result(fallback_status)
	var result := DepthRuntimeTypes.make_result(String(sample_payload.get("status", DepthRuntimeTypes.STATUS_READY)))
	result["ok"] = true
	result["status"] = String(sample_payload.get("status", DepthRuntimeTypes.STATUS_READY))
	result["backend_id"] = String(sample_payload.get("backend_id", _debug_state.get("backend_id", "unknown")))
	result["family_id"] = String(sample_payload.get("family_id", _debug_state.get("family_id", "unknown")))
	result["artifact_path"] = String(sample_payload.get("artifact_path", _debug_state.get("artifact_path_res", "")))
	result["sample_metrics"] = {
		"wrist_closeness": closeness,
		"wrist_depth": _first_float(sample_metrics, ["wrist_depth", "wrist_depth_normalized"], 0.0),
		"torso_depth": _first_float(sample_metrics, ["torso_depth", "torso_depth_normalized"], 0.0),
		"sample_source": String(sample_metrics.get("sample_source", sample_payload.get("sample_source", "placeholder"))),
		"sample_fresh": bool(sample_metrics.get("sample_fresh", sample_payload.get("sample_fresh", true))),
	}
	result["timing_ms"] = (sample_payload.get("timing_ms", {}) as Dictionary).duplicate(true) if sample_payload.get("timing_ms", {}) is Dictionary else {
		"preprocess": 0.0,
		"infer": 0.0,
		"postprocess": 0.0,
		"total": 0.0,
	}
	return result

func _apply_cadence_settings_from_request(sample_request: Dictionary) -> void:
	var evaluation: Dictionary = {}
	if sample_request.get("evaluation", null) is Dictionary and not (sample_request.get("evaluation", {}) as Dictionary).is_empty():
		evaluation = (sample_request.get("evaluation", {}) as Dictionary).duplicate(true)
	elif _family_depth_config.get("evaluation", null) is Dictionary:
		evaluation = (_family_depth_config.get("evaluation", {}) as Dictionary).duplicate(true)
	var fallback_max_age_ms := int(sample_request.get("window_ms", evaluation.get("window_ms", 0)))
	_debug_state["sample_every_n_frames"] = max(1, int(evaluation.get("sample_every_n_frames", 1)))
	_debug_state["max_sample_age_ms"] = max(0, int(evaluation.get("max_sample_age_ms", fallback_max_age_ms)))

func _should_run_fresh_inference(_sample_request: Dictionary) -> bool:
	var sample_every_n_frames := max(1, int(_debug_state.get("sample_every_n_frames", 1)))
	if _eligible_sample_request_count <= 1:
		return true
	return ((_eligible_sample_request_count - 1) % sample_every_n_frames) == 0

func _build_cached_reuse_result(sample_request: Dictionary) -> Dictionary:
	var runtime_status := String(_debug_state.get("runtime_status", DepthRuntimeTypes.STATUS_READY))
	if _last_successful_result.is_empty():
		return _make_cache_miss_result(runtime_status, "cached_sample_missing", "No successful depth sample exists yet for cadence reuse.")
	var timestamp_ms := int(sample_request.get("timestamp_ms", -1))
	var last_sample_timestamp_ms := int(_debug_state.get("last_sample_timestamp_ms", -1))
	var sample_age_ms := maxi(timestamp_ms - last_sample_timestamp_ms, 0) if timestamp_ms >= 0 and last_sample_timestamp_ms >= 0 else -1
	var max_sample_age_ms := max(0, int(_debug_state.get("max_sample_age_ms", 0)))
	if max_sample_age_ms > 0 and sample_age_ms > max_sample_age_ms:
		_debug_state["last_sample_age_ms"] = sample_age_ms
		return _make_cache_miss_result(runtime_status, "cached_sample_expired", "Cached depth sample age %d ms exceeded max_sample_age_ms=%d before the next scheduled fresh inference." % [sample_age_ms, max_sample_age_ms])
	var result: Dictionary = _last_successful_result.duplicate(true)
	result["ok"] = true
	result["status"] = DepthRuntimeTypes.STATUS_READY
	var sample_metrics: Dictionary = result.get("sample_metrics", {}) if result.get("sample_metrics", {}) is Dictionary else {}
	sample_metrics["sample_source"] = "cached_reuse"
	sample_metrics["sample_fresh"] = false
	sample_metrics["sample_age_ms"] = sample_age_ms
	sample_metrics["fresh_inference_request_index"] = int(sample_metrics.get("fresh_inference_request_index", _eligible_sample_request_count))
	result["sample_metrics"] = sample_metrics
	return result

func _make_cache_miss_result(runtime_status: String, code: String, message: String) -> Dictionary:
	var result := DepthRuntimeTypes.make_result(runtime_status)
	result["backend_id"] = String(_debug_state.get("backend_id", "unknown"))
	result["family_id"] = String(_debug_state.get("family_id", "unknown"))
	result["artifact_path"] = String(_debug_state.get("artifact_path_res", ""))
	var last_sample_metrics: Dictionary = (_debug_state.get("last_sample_metrics", {}) as Dictionary).duplicate(true)
	var last_timing_ms: Dictionary = (_debug_state.get("last_timing_ms", {}) as Dictionary).duplicate(true)
	result["sample_metrics"] = last_sample_metrics
	result["timing_ms"] = last_timing_ms if not last_timing_ms.is_empty() else result.get("timing_ms", {})
	result["frame_size"] = _debug_state.get("frame_size", Vector2i.ZERO)
	result["depth_map_size"] = _debug_state.get("depth_map_size", Vector2i.ZERO)
	result["normalized_depth_map"] = _debug_state.get("normalized_depth_map", null)
	result["error_info"] = {
		"code": code,
		"message": message,
	}
	return result

func _store_successful_result(result: Dictionary, sample_request: Dictionary) -> void:
	_last_successful_result = result.duplicate(true)
	var sample_metrics: Dictionary = _last_successful_result.get("sample_metrics", {}) if _last_successful_result.get("sample_metrics", {}) is Dictionary else {}
	sample_metrics["sample_source"] = String(sample_metrics.get("sample_source", "fresh_inference"))
	sample_metrics["sample_fresh"] = true
	sample_metrics["sample_age_ms"] = 0
	sample_metrics["fresh_inference_request_index"] = _eligible_sample_request_count
	_last_successful_result["sample_metrics"] = sample_metrics
	_debug_state["last_sample_timestamp_ms"] = int(sample_request.get("timestamp_ms", -1))
	_debug_state["last_sample_age_ms"] = 0

func _sync_debug_from_result(result: Dictionary, sample_request: Dictionary) -> void:
	var sample_metrics: Dictionary = result.get("sample_metrics", {}) if result.get("sample_metrics", {}) is Dictionary else {}
	var timing_ms: Dictionary = result.get("timing_ms", {}) if result.get("timing_ms", {}) is Dictionary else {}
	_debug_state["last_sample_metrics"] = sample_metrics.duplicate(true)
	_debug_state["last_timing_ms"] = timing_ms.duplicate(true)
	_debug_state["frame_size"] = result.get("frame_size", Vector2i.ZERO)
	_debug_state["depth_map_size"] = result.get("depth_map_size", Vector2i.ZERO)
	_debug_state["normalized_depth_map"] = result.get("normalized_depth_map", null)
	if bool(sample_metrics.get("sample_fresh", false)):
		_debug_state["last_sample_timestamp_ms"] = int(sample_request.get("timestamp_ms", -1))
		_debug_state["last_sample_age_ms"] = 0
	else:
		_debug_state["last_sample_age_ms"] = int(sample_metrics.get("sample_age_ms", -1))

func _reset_sample_cache() -> void:
	_eligible_sample_request_count = 0
	_last_successful_result = {}
	_debug_state["last_sample_timestamp_ms"] = -1
	_debug_state["last_sample_age_ms"] = -1
	_debug_state["last_sample_metrics"] = {}
	_debug_state["last_timing_ms"] = {
		"preprocess": 0.0,
		"infer": 0.0,
		"postprocess": 0.0,
		"total": 0.0,
	}
	_debug_state["frame_size"] = Vector2i.ZERO
	_debug_state["depth_map_size"] = Vector2i.ZERO
	_debug_state["normalized_depth_map"] = null

func _first_float(document: Dictionary, keys: Array, default_value: float) -> float:
	for key_variant: Variant in keys:
		var key := String(key_variant)
		if document.has(key):
			return float(document.get(key, default_value))
	return default_value
