class_name DepthSharedRuntimePool
extends RefCounted

const DepthRuntimeTypes = preload("res://addons/aerobeat-input-camera-tracking/src/depth/depth_runtime_types.gd")
const OpenvinoDepthAdapterScript = preload("res://addons/aerobeat-input-camera-tracking/src/depth/adapters/openvino_depth_adapter.gd")
const OnnxDepthAdapterScript = preload("res://addons/aerobeat-input-camera-tracking/src/depth/adapters/onnx_depth_adapter.gd")

var _entries := {}

func acquire(family: String, model_spec: Dictionary) -> Dictionary:
	var runtime_key := String(model_spec.get("runtime_key", ""))
	if runtime_key.is_empty():
		return {
			"ok": false,
			"status": DepthRuntimeTypes.STATUS_FAILED,
			"failure_code": "runtime_key_missing",
			"failure_message": "Depth runtime key was empty during shared runtime acquire.",
		}
	var entry: Dictionary = _entries.get(runtime_key, {}) if _entries.get(runtime_key, {}) is Dictionary else {}
	if entry.is_empty():
		entry = _create_entry(model_spec)
	_claim_family(entry, family)
	_store_entry(runtime_key, entry)
	var debug_state: Dictionary = _entry_debug(entry)
	return {
		"ok": String(debug_state.get("runtime_status", DepthRuntimeTypes.STATUS_UNLOADED)) == DepthRuntimeTypes.STATUS_READY,
		"status": String(debug_state.get("runtime_status", DepthRuntimeTypes.STATUS_UNLOADED)),
		"failure_code": String(debug_state.get("failure_code", "")),
		"failure_message": String(debug_state.get("failure_message", "")),
	}

func infer(runtime_key: String, frame_payload: Dictionary, request: Dictionary) -> Dictionary:
	var entry: Dictionary = _entries.get(runtime_key, {}) if _entries.get(runtime_key, {}) is Dictionary else {}
	if entry.is_empty():
		return DepthRuntimeTypes.make_result(DepthRuntimeTypes.STATUS_UNLOADED)
	var adapter: Variant = entry.get("adapter", null)
	if adapter == null:
		return DepthRuntimeTypes.make_result(DepthRuntimeTypes.STATUS_UNLOADED)
	var result: Dictionary = adapter.infer(frame_payload, request)
	entry["last_debug_state"] = adapter.get_debug_state()
	_store_entry(runtime_key, entry)
	return result

func get_runtime_debug(runtime_key: String) -> Dictionary:
	var entry: Dictionary = _entries.get(runtime_key, {}) if _entries.get(runtime_key, {}) is Dictionary else {}
	if entry.is_empty():
		return _make_unclaimed_debug_state(runtime_key)
	return _entry_debug(entry)

func release(family: String, runtime_key: String) -> Dictionary:
	if runtime_key.is_empty():
		return _make_unclaimed_debug_state(runtime_key)
	var entry: Dictionary = _entries.get(runtime_key, {}) if _entries.get(runtime_key, {}) is Dictionary else {}
	if entry.is_empty():
		return _make_unclaimed_debug_state(runtime_key)
	_unclaim_family(entry, family)
	if int(entry.get("refcount", 0)) <= 0:
		var adapter: Variant = entry.get("adapter", null)
		if adapter != null and adapter.has_method("unload"):
			adapter.unload()
			entry["last_debug_state"] = adapter.get_debug_state()
		var release_debug := _entry_debug(entry)
		release_debug["shared_runtime_refcount"] = 0
		release_debug["shared_runtime_family_claims"] = []
		release_debug["shared_runtime_claimed"] = false
		release_debug["shared_runtime_shared"] = false
		_entries.erase(runtime_key)
		return release_debug
	_store_entry(runtime_key, entry)
	return _entry_debug(entry)

func _create_entry(model_spec: Dictionary) -> Dictionary:
	var backend_id := String(model_spec.get("backend_id", "unknown"))
	var adapter := _create_adapter_for_backend(backend_id)
	var load_result := {
		"ok": false,
		"status": DepthRuntimeTypes.STATUS_FAILED,
		"failure_code": "unsupported_backend",
		"failure_message": "No adapter is registered for backend '%s'." % backend_id,
	}
	var debug_state := DepthRuntimeTypes.make_debug_state()
	debug_state["configured"] = true
	debug_state["family"] = String(model_spec.get("family", ""))
	debug_state["depth_enabled"] = true
	debug_state["artifact_path_res"] = String(model_spec.get("artifact_path_res", ""))
	debug_state["artifact_path_abs"] = String(model_spec.get("artifact_path_abs", ""))
	debug_state["artifact_exists"] = bool(model_spec.get("artifact_exists", false))
	debug_state["artifact_kind"] = String(model_spec.get("artifact_kind", "missing"))
	debug_state["family_id"] = String(model_spec.get("family_id", "unknown"))
	debug_state["backend_id"] = backend_id
	debug_state["runtime_key"] = String(model_spec.get("runtime_key", ""))
	if adapter != null:
		load_result = adapter.load(model_spec)
		debug_state = adapter.get_debug_state()
	else:
		debug_state["runtime_status"] = DepthRuntimeTypes.STATUS_FAILED
		debug_state["runtime_stage"] = DepthRuntimeTypes.STAGE_ADAPTER_LOAD
		debug_state["failure_code"] = "unsupported_backend"
		debug_state["failure_message"] = "No adapter is registered for backend '%s'." % backend_id
		debug_state["active_model_summary"] = "enabled; artifact resolved but backend '%s' is unsupported" % backend_id
	return {
		"runtime_key": String(model_spec.get("runtime_key", "")),
		"model_spec": model_spec.duplicate(true),
		"adapter": adapter,
		"last_load_result": load_result.duplicate(true),
		"last_debug_state": debug_state.duplicate(true),
		"family_claims": {},
		"refcount": 0,
	}

func _create_adapter_for_backend(backend_id: String) -> RefCounted:
	match backend_id:
		"openvino":
			return OpenvinoDepthAdapterScript.new()
		"onnx":
			return OnnxDepthAdapterScript.new()
		_:
			return null

func _claim_family(entry: Dictionary, family: String) -> void:
	var claims: Dictionary = entry.get("family_claims", {}) if entry.get("family_claims", {}) is Dictionary else {}
	if not family.is_empty():
		claims[family] = true
	entry["family_claims"] = claims
	entry["refcount"] = claims.size()

func _unclaim_family(entry: Dictionary, family: String) -> void:
	var claims: Dictionary = entry.get("family_claims", {}) if entry.get("family_claims", {}) is Dictionary else {}
	claims.erase(family)
	entry["family_claims"] = claims
	entry["refcount"] = claims.size()

func _store_entry(runtime_key: String, entry: Dictionary) -> void:
	_entries[runtime_key] = entry

func _entry_debug(entry: Dictionary) -> Dictionary:
	var debug_state: Dictionary = (entry.get("last_debug_state", {}) as Dictionary).duplicate(true)
	if debug_state.is_empty():
		debug_state = DepthRuntimeTypes.make_debug_state()
	debug_state["shared_runtime_key"] = String(entry.get("runtime_key", debug_state.get("runtime_key", "")))
	debug_state["shared_runtime_refcount"] = int(entry.get("refcount", 0))
	debug_state["shared_runtime_family_claims"] = _sorted_family_claims(entry)
	debug_state["shared_runtime_claimed"] = int(entry.get("refcount", 0)) > 0
	debug_state["shared_runtime_shared"] = int(entry.get("refcount", 0)) > 1
	return debug_state

func _sorted_family_claims(entry: Dictionary) -> Array:
	var claims: Dictionary = entry.get("family_claims", {}) if entry.get("family_claims", {}) is Dictionary else {}
	var families: Array = claims.keys()
	families.sort()
	return families

func _make_unclaimed_debug_state(runtime_key: String) -> Dictionary:
	var debug_state := DepthRuntimeTypes.make_debug_state()
	debug_state["runtime_key"] = runtime_key
	debug_state["shared_runtime_key"] = runtime_key
	debug_state["shared_runtime_refcount"] = 0
	debug_state["shared_runtime_family_claims"] = []
	debug_state["shared_runtime_claimed"] = false
	debug_state["shared_runtime_shared"] = false
	return debug_state
