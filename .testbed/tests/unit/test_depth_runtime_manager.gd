extends "res://addons/aerobeat-vendor-godot-unit-test/test.gd"

const DepthRuntimeManagerScript = preload("res://addons/aerobeat-input-camera-tracking/src/depth/depth_runtime_manager.gd")
const DepthRuntimeTypes = preload("res://addons/aerobeat-input-camera-tracking/src/depth/depth_runtime_types.gd")
const DepthSharedRuntimePoolScript = preload("res://addons/aerobeat-input-camera-tracking/src/depth/depth_shared_runtime_pool.gd")

class FakeDepthSharedRuntimePool:
	extends RefCounted

	var infer_call_count := 0
	var runtime_debug := DepthRuntimeTypes.make_debug_state()
	var next_result: Dictionary = {}
	var last_request: Dictionary = {}

	func acquire(family: String, model_spec: Dictionary) -> Dictionary:
		runtime_debug = DepthRuntimeTypes.make_debug_state()
		runtime_debug["configured"] = true
		runtime_debug["family"] = family
		runtime_debug["depth_enabled"] = true
		runtime_debug["artifact_path_res"] = String(model_spec.get("artifact_path_res", ""))
		runtime_debug["artifact_path_abs"] = String(model_spec.get("artifact_path_abs", ""))
		runtime_debug["artifact_exists"] = bool(model_spec.get("artifact_exists", false))
		runtime_debug["artifact_kind"] = String(model_spec.get("artifact_kind", "file"))
		runtime_debug["family_id"] = String(model_spec.get("family_id", "fake_family"))
		runtime_debug["backend_id"] = String(model_spec.get("backend_id", "onnx"))
		runtime_debug["runtime_key"] = String(model_spec.get("runtime_key", "fake-runtime"))
		runtime_debug["runtime_status"] = DepthRuntimeTypes.STATUS_READY
		runtime_debug["runtime_stage"] = DepthRuntimeTypes.STAGE_SAMPLING
		runtime_debug["active_model_summary"] = "enabled; runtime ready via fake backend"
		return {"ok": true, "status": DepthRuntimeTypes.STATUS_READY}

	func infer(_runtime_key: String, _frame_payload: Dictionary, request: Dictionary) -> Dictionary:
		infer_call_count += 1
		last_request = request.duplicate(true)
		var result := next_result.duplicate(true)
		var sample_metrics: Dictionary = result.get("sample_metrics", {}) if result.get("sample_metrics", {}) is Dictionary else {}
		sample_metrics["fresh_inference_request_index"] = infer_call_count
		result["sample_metrics"] = sample_metrics
		runtime_debug["last_sample_metrics"] = sample_metrics.duplicate(true)
		runtime_debug["last_timing_ms"] = (result.get("timing_ms", {}) as Dictionary).duplicate(true)
		runtime_debug["frame_size"] = result.get("frame_size", Vector2i.ZERO)
		runtime_debug["depth_map_size"] = result.get("depth_map_size", Vector2i.ZERO)
		runtime_debug["normalized_depth_map"] = result.get("normalized_depth_map", null)
		runtime_debug["last_sample_timestamp_ms"] = int(request.get("timestamp_ms", -1))
		return result

	func get_runtime_debug(_runtime_key: String) -> Dictionary:
		return runtime_debug.duplicate(true)

	func release(_family: String, _runtime_key: String) -> Dictionary:
		return runtime_debug.duplicate(true)

func test_onnx_depth_runtime_executes_real_preview_inference() -> void:
	var manager = DepthRuntimeManagerScript.new()
	manager.configure_from_family("straight_punch", {
		"enabled": true,
		"model": {
			"artifact_path": "res://addons/aerobeat-input-camera-tracking/assets/depth_models/depth_anything_v2/depth_anything_v2_small/depth_anything_v2_small.onnx",
		}
	})
	var result: Dictionary = manager.infer_relative_depth(_preview_frame_payload(), _sample_request("straight_punch", "left"))
	assert_true(bool(result.get("ok", false)))
	assert_eq(String(result.get("status", "")), DepthRuntimeTypes.STATUS_READY)
	assert_eq(String(result.get("backend_id", "")), "onnx")
	assert_eq(String(result.get("family_id", "")), "depth_anything_v2_small_onnx")
	assert_eq(String(result.get("sample_metrics", {}).get("sample_source", "")), "fresh_inference")
	assert_true(result.get("sample_metrics", {}).has("wrist_closeness"))
	assert_true(result.get("frame_size", Vector2i.ZERO) is Vector2i)
	assert_true(result.get("depth_map_size", Vector2i.ZERO) is Vector2i)
	assert_true((result.get("frame_size", Vector2i.ZERO) as Vector2i).x > 0)
	assert_true((result.get("depth_map_size", Vector2i.ZERO) as Vector2i).y > 0)
	assert_eq(result.get("normalized_depth_map", null), null)
	var sample_geometry: Dictionary = result.get("sample_metrics", {}).get("sample_geometry", {}) if result.get("sample_metrics", {}).get("sample_geometry", {}) is Dictionary else {}
	assert_eq(String(sample_geometry.get("actual_geometry_kind", "")), "single_pixel_point")
	assert_eq(String(sample_geometry.get("depth_map_space", "")), "frame_resized_normalized_depth")
	assert_true(sample_geometry.get("actual_samples", {}).has("shoulder"))
	assert_true(sample_geometry.get("actual_samples", {}).has("wrist"))
	var debug_state: Dictionary = manager.get_debug_state()
	assert_eq(String(debug_state.get("worker_mode", "")), "persistent_tcp")
	assert_true(bool(debug_state.get("worker_alive", false)))
	assert_true(int(debug_state.get("worker_pid", 0)) > 0)
	assert_eq(debug_state.get("frame_size", Vector2i.ZERO), result.get("frame_size", Vector2i.ZERO))
	assert_eq(debug_state.get("depth_map_size", Vector2i.ZERO), result.get("depth_map_size", Vector2i.ZERO))
	assert_eq(debug_state.get("normalized_depth_map", null), null)

func test_openvino_depth_runtime_executes_real_preview_inference() -> void:
	var manager = DepthRuntimeManagerScript.new()
	manager.configure_from_family("uppercut", {
		"enabled": true,
		"model": {
			"artifact_path": "res://addons/aerobeat-input-camera-tracking/assets/depth_models/midas/openvino_midas_v21_small_256/",
		}
	})
	var result: Dictionary = manager.infer_relative_depth(_preview_frame_payload(), _sample_request("uppercut", "left"))
	assert_true(bool(result.get("ok", false)))
	assert_eq(String(result.get("status", "")), DepthRuntimeTypes.STATUS_READY)
	assert_eq(String(result.get("backend_id", "")), "openvino")
	assert_eq(String(result.get("family_id", "")), "midas_openvino_v21_small_256")
	assert_eq(String(result.get("sample_metrics", {}).get("sample_source", "")), "fresh_inference")
	assert_true(result.get("sample_metrics", {}).has("wrist_closeness"))

func test_model_swap_updates_runtime_debug_backend_and_family_truthfully() -> void:
	var manager = DepthRuntimeManagerScript.new()
	manager.configure_from_family("hook", {
		"enabled": true,
		"model": {
			"artifact_path": "res://addons/aerobeat-input-camera-tracking/assets/depth_models/fastdepth/fastdepth_224_onnx/fastdepth.onnx",
		}
	})
	var onnx_state: Dictionary = manager.ensure_runtime_ready()
	assert_eq(String(onnx_state.get("runtime_status", "")), DepthRuntimeTypes.STATUS_READY)
	assert_eq(String(onnx_state.get("backend_id", "")), "onnx")
	assert_eq(String(onnx_state.get("family_id", "")), "fastdepth_224_onnx")
	manager.configure_from_family("hook", {
		"enabled": true,
		"model": {
			"artifact_path": "res://addons/aerobeat-input-camera-tracking/assets/depth_models/midas/openvino_midas_v21_small_256/",
		}
	})
	var openvino_state: Dictionary = manager.ensure_runtime_ready()
	assert_eq(String(openvino_state.get("runtime_status", "")), DepthRuntimeTypes.STATUS_READY)
	assert_eq(String(openvino_state.get("backend_id", "")), "openvino")
	assert_eq(String(openvino_state.get("family_id", "")), "midas_openvino_v21_small_256")
	assert_false(String(openvino_state.get("active_model_summary", "")).contains("adapter_unimplemented"))
	assert_eq(String(openvino_state.get("worker_mode", "")), "persistent_tcp")
	assert_true(int(openvino_state.get("model_load_count", 0)) >= 1)

func test_repeated_inference_reuses_persistent_worker_session() -> void:
	var manager = DepthRuntimeManagerScript.new()
	manager.configure_from_family("straight_punch", {
		"enabled": true,
		"model": {
			"artifact_path": "res://addons/aerobeat-input-camera-tracking/assets/depth_models/fastdepth/fastdepth_224_onnx/fastdepth.onnx",
		}
	})
	var ready_state: Dictionary = manager.ensure_runtime_ready()
	var first_result: Dictionary = manager.infer_relative_depth(_preview_frame_payload(), _sample_request("straight_punch", "left"))
	var second_result: Dictionary = manager.infer_relative_depth(_preview_frame_payload(), _sample_request("straight_punch", "left"))
	assert_eq(String(ready_state.get("runtime_status", "")), DepthRuntimeTypes.STATUS_READY)
	assert_true(float(ready_state.get("last_timing_ms", {}).get("worker_load", 0.0)) > 0.0)
	assert_true(bool(first_result.get("ok", false)))
	assert_true(bool(second_result.get("ok", false)))
	assert_true(bool(first_result.get("timing_ms", {}).get("session_warm", false)))
	assert_true(bool(second_result.get("timing_ms", {}).get("session_warm", false)))
	var debug_state: Dictionary = manager.get_debug_state()
	assert_true(bool(debug_state.get("model_loaded", false)))
	assert_true(int(debug_state.get("model_load_count", 0)) >= 1)
	assert_eq(int(debug_state.get("model_reload_count", 0)), 0)

func test_requested_fresh_inference_surfaces_runtime_depth_texture() -> void:
	var shared_pool = FakeDepthSharedRuntimePool.new()
	var expected_texture := _make_test_texture()
	var depth_result := _fake_depth_result()
	depth_result["normalized_depth_map"] = expected_texture
	shared_pool.next_result = depth_result
	var manager = DepthRuntimeManagerScript.new()
	manager.set_shared_runtime_pool(shared_pool)
	manager.configure_from_family("straight_punch", {
		"enabled": true,
		"model": {
			"artifact_path": "res://addons/aerobeat-input-camera-tracking/assets/depth_models/fastdepth/fastdepth_224_onnx/fastdepth.onnx",
		},
	})
	var request := _sample_request("straight_punch", "left")
	request["debug_texture_requested"] = true
	var result: Dictionary = manager.infer_relative_depth(_preview_frame_payload(), request)
	assert_true(bool(result.get("ok", false)))
	assert_true(bool(shared_pool.last_request.get("debug_texture_requested", false)))
	assert_same(result.get("normalized_depth_map", null), expected_texture)
	var debug_state: Dictionary = manager.get_debug_state()
	assert_same(debug_state.get("normalized_depth_map", null), expected_texture)

func test_cached_reuse_preserves_last_runtime_depth_texture() -> void:
	var shared_pool = FakeDepthSharedRuntimePool.new()
	var expected_texture := _make_test_texture()
	var depth_result := _fake_depth_result()
	depth_result["normalized_depth_map"] = expected_texture
	shared_pool.next_result = depth_result
	var manager = DepthRuntimeManagerScript.new()
	manager.set_shared_runtime_pool(shared_pool)
	manager.configure_from_family("straight_punch", {
		"enabled": true,
		"model": {
			"artifact_path": "res://addons/aerobeat-input-camera-tracking/assets/depth_models/fastdepth/fastdepth_224_onnx/fastdepth.onnx",
		},
		"evaluation": {
			"sample_every_n_frames": 3,
			"max_sample_age_ms": 250,
		}
	})
	var first_request := _sample_request("straight_punch", "left")
	first_request["timestamp_ms"] = 1000
	first_request["debug_texture_requested"] = true
	var first_result: Dictionary = manager.infer_relative_depth(_preview_frame_payload(), first_request)
	var second_request := first_request.duplicate(true)
	second_request["timestamp_ms"] = 1033
	var second_result: Dictionary = manager.infer_relative_depth(_preview_frame_payload(), second_request)
	assert_true(bool(first_result.get("ok", false)))
	assert_true(bool(second_result.get("ok", false)))
	assert_eq(String(second_result.get("sample_metrics", {}).get("sample_source", "")), "cached_reuse")
	assert_same(first_result.get("normalized_depth_map", null), expected_texture)
	assert_same(second_result.get("normalized_depth_map", null), expected_texture)
	var debug_state: Dictionary = manager.get_debug_state()
	assert_same(debug_state.get("normalized_depth_map", null), expected_texture)

func test_non_requested_inference_keeps_runtime_depth_texture_truthfully_null() -> void:
	var shared_pool = FakeDepthSharedRuntimePool.new()
	shared_pool.next_result = _fake_depth_result()
	var manager = DepthRuntimeManagerScript.new()
	manager.set_shared_runtime_pool(shared_pool)
	manager.configure_from_family("straight_punch", {
		"enabled": true,
		"model": {
			"artifact_path": "res://addons/aerobeat-input-camera-tracking/assets/depth_models/fastdepth/fastdepth_224_onnx/fastdepth.onnx",
		},
	})
	var result: Dictionary = manager.infer_relative_depth(_preview_frame_payload(), _sample_request("straight_punch", "left"))
	assert_true(bool(result.get("ok", false)))
	assert_false(bool(shared_pool.last_request.get("debug_texture_requested", false)))
	assert_eq(result.get("normalized_depth_map", null), null)
	var debug_state: Dictionary = manager.get_debug_state()
	assert_eq(debug_state.get("normalized_depth_map", null), null)

func test_region_aware_sampling_request_and_runtime_metadata_round_trip_truthfully() -> void:
	var shared_pool = FakeDepthSharedRuntimePool.new()
	shared_pool.next_result = _fake_region_aware_depth_result()
	var manager = DepthRuntimeManagerScript.new()
	manager.set_shared_runtime_pool(shared_pool)
	manager.configure_from_family("straight_punch", {
		"enabled": true,
		"model": {
			"artifact_path": "res://addons/aerobeat-input-camera-tracking/assets/depth_models/fastdepth/fastdepth_224_onnx/fastdepth.onnx",
		},
	})
	var request := _sample_request("straight_punch", "left")
	request["evaluation"] = {
		"sampling_mode": "region_aware",
		"region_geometry": {
			"wrist_shape": "extended_capsule",
			"wrist_radius_px": 12,
			"wrist_extension_toward_elbow_px": 8,
			"torso_shape": "center_box",
			"torso_half_width_px": 18,
			"torso_half_height_px": 18,
			"torso_anchor": "shoulder_landmark",
		},
		"aggregation": {
			"wrist_depth_stat": "median",
			"torso_depth_stat": "median",
			"trim_fraction": 0.0,
			"min_valid_samples": 5,
		},
	}
	var result: Dictionary = manager.infer_relative_depth(_preview_frame_payload(), request)
	assert_true(bool(result.get("ok", false)))
	assert_eq(String(shared_pool.last_request.get("evaluation", {}).get("sampling_mode", "")), "region_aware")
	assert_eq(int(shared_pool.last_request.get("evaluation", {}).get("region_geometry", {}).get("wrist_radius_px", 0)), 12)
	assert_eq(String(result.get("sample_metrics", {}).get("sampling_mode", "")), "region_aware")
	var sample_geometry: Dictionary = result.get("sample_metrics", {}).get("sample_geometry", {}) if result.get("sample_metrics", {}).get("sample_geometry", {}) is Dictionary else {}
	assert_eq(String(sample_geometry.get("actual_geometry_kind", "")), "landmark_region")
	assert_true(bool(sample_geometry.get("aggregation", {}).get("fallback_used", false)))
	assert_eq(String(sample_geometry.get("aggregation", {}).get("fallback_reason", "")), "center_point_due_to_sparse_region")
	assert_eq(String(sample_geometry.get("requested_runtime_geometry", {}).get("region_geometry", {}).get("torso_anchor", "")), "shoulder_landmark")

func test_sample_every_n_frames_reuses_last_valid_depth_between_fresh_runs() -> void:
	var shared_pool = FakeDepthSharedRuntimePool.new()
	shared_pool.next_result = _fake_depth_result()
	var manager = DepthRuntimeManagerScript.new()
	manager.set_shared_runtime_pool(shared_pool)
	manager.configure_from_family("straight_punch", {
		"enabled": true,
		"model": {
			"artifact_path": "res://addons/aerobeat-input-camera-tracking/assets/depth_models/fastdepth/fastdepth_224_onnx/fastdepth.onnx",
		},
		"evaluation": {
			"sample_every_n_frames": 3,
			"max_sample_age_ms": 250,
		}
	})
	var first_request := _sample_request("straight_punch", "left")
	first_request["timestamp_ms"] = 1000
	var first_result: Dictionary = manager.infer_relative_depth(_preview_frame_payload(), first_request)
	var second_request := first_request.duplicate(true)
	second_request["timestamp_ms"] = 1033
	var second_result: Dictionary = manager.infer_relative_depth(_preview_frame_payload(), second_request)
	var third_request := first_request.duplicate(true)
	third_request["timestamp_ms"] = 1066
	var third_result: Dictionary = manager.infer_relative_depth(_preview_frame_payload(), third_request)
	var fourth_request := first_request.duplicate(true)
	fourth_request["timestamp_ms"] = 1100
	var fourth_result: Dictionary = manager.infer_relative_depth(_preview_frame_payload(), fourth_request)
	assert_eq(shared_pool.infer_call_count, 2)
	assert_true(bool(first_result.get("ok", false)))
	assert_eq(String(first_result.get("sample_metrics", {}).get("sample_source", "")), "fresh_inference")
	assert_true(bool(first_result.get("sample_metrics", {}).get("sample_fresh", false)))
	assert_true(bool(second_result.get("ok", false)))
	assert_eq(String(second_result.get("sample_metrics", {}).get("sample_source", "")), "cached_reuse")
	assert_false(bool(second_result.get("sample_metrics", {}).get("sample_fresh", true)))
	assert_eq(int(second_result.get("sample_metrics", {}).get("sample_age_ms", -1)), 33)
	assert_true(bool(third_result.get("ok", false)))
	assert_eq(String(third_result.get("sample_metrics", {}).get("sample_source", "")), "cached_reuse")
	assert_eq(int(third_result.get("sample_metrics", {}).get("sample_age_ms", -1)), 66)
	assert_true(bool(fourth_result.get("ok", false)))
	assert_eq(String(fourth_result.get("sample_metrics", {}).get("sample_source", "")), "fresh_inference")
	var debug_state: Dictionary = manager.get_debug_state()
	assert_eq(int(debug_state.get("sample_every_n_frames", 0)), 3)
	assert_eq(int(debug_state.get("max_sample_age_ms", -1)), 250)

func test_cached_depth_reuse_expires_when_max_sample_age_ms_is_exceeded() -> void:
	var shared_pool = FakeDepthSharedRuntimePool.new()
	shared_pool.next_result = _fake_depth_result()
	var manager = DepthRuntimeManagerScript.new()
	manager.set_shared_runtime_pool(shared_pool)
	manager.configure_from_family("straight_punch", {
		"enabled": true,
		"model": {
			"artifact_path": "res://addons/aerobeat-input-camera-tracking/assets/depth_models/fastdepth/fastdepth_224_onnx/fastdepth.onnx",
		},
		"evaluation": {
			"sample_every_n_frames": 4,
			"max_sample_age_ms": 50,
		}
	})
	var first_request := _sample_request("straight_punch", "left")
	first_request["timestamp_ms"] = 1000
	var first_result: Dictionary = manager.infer_relative_depth(_preview_frame_payload(), first_request)
	var stale_request := first_request.duplicate(true)
	stale_request["timestamp_ms"] = 1060
	var stale_result: Dictionary = manager.infer_relative_depth(_preview_frame_payload(), stale_request)
	assert_true(bool(first_result.get("ok", false)))
	assert_false(bool(stale_result.get("ok", false)))
	assert_eq(String(stale_result.get("error_info", {}).get("code", "")), "cached_sample_expired")
	assert_eq(shared_pool.infer_call_count, 1)
	var debug_state: Dictionary = manager.get_debug_state()
	assert_eq(int(debug_state.get("last_sample_age_ms", -1)), 60)
	assert_eq(String(debug_state.get("failure_code", "")), "cached_sample_expired")

func test_shutdown_clears_worker_and_model_debug_truth() -> void:
	var manager = DepthRuntimeManagerScript.new()
	manager.configure_from_family("straight_punch", {
		"enabled": true,
		"model": {
			"artifact_path": "res://addons/aerobeat-input-camera-tracking/assets/depth_models/fastdepth/fastdepth_224_onnx/fastdepth.onnx",
		}
	})
	var ready_state: Dictionary = manager.ensure_runtime_ready()
	assert_eq(String(ready_state.get("runtime_status", "")), DepthRuntimeTypes.STATUS_READY)
	assert_true(bool(ready_state.get("worker_alive", false)))
	assert_true(int(ready_state.get("worker_pid", 0)) > 0)
	assert_true(bool(ready_state.get("model_loaded", false)))
	manager.shutdown()
	var debug_state: Dictionary = manager.get_debug_state()
	assert_eq(String(debug_state.get("runtime_status", "")), DepthRuntimeTypes.STATUS_UNLOADED)
	assert_eq(String(debug_state.get("runtime_stage", "")), DepthRuntimeTypes.STAGE_IDLE)
	assert_false(bool(debug_state.get("worker_alive", false)))
	assert_eq(int(debug_state.get("worker_pid", 0)), 0)
	assert_false(bool(debug_state.get("model_loaded", false)))
	assert_eq(String(debug_state.get("model_runtime_key", "")), "")

func test_shutdown_clears_failure_residue_after_blocked_infer() -> void:
	var manager = DepthRuntimeManagerScript.new()
	manager.configure_from_family("straight_punch", {
		"enabled": true,
		"model": {
			"artifact_path": "res://addons/aerobeat-input-camera-tracking/assets/depth_models/fastdepth/fastdepth_224_onnx/fastdepth.onnx",
		}
	})
	var blocked_result: Dictionary = manager.infer_relative_depth({}, _sample_request("straight_punch", "left"))
	assert_false(bool(blocked_result.get("ok", false)))
	assert_eq(String(blocked_result.get("status", "")), DepthRuntimeTypes.STATUS_BLOCKED)
	assert_eq(String(blocked_result.get("error_info", {}).get("code", "")), "preview_image_missing")
	var blocked_debug: Dictionary = manager.get_debug_state()
	assert_eq(String(blocked_debug.get("failure_code", "")), "preview_image_missing")
	assert_string_contains(String(blocked_debug.get("failure_message", "")), "preview image path")
	manager.shutdown()
	var debug_state: Dictionary = manager.get_debug_state()
	assert_eq(String(debug_state.get("runtime_status", "")), DepthRuntimeTypes.STATUS_UNLOADED)
	assert_eq(String(debug_state.get("runtime_stage", "")), DepthRuntimeTypes.STAGE_IDLE)
	assert_eq(String(debug_state.get("failure_code", "")), "")
	assert_eq(String(debug_state.get("failure_message", "")), "")
	assert_false(bool(debug_state.get("worker_alive", false)))
	assert_eq(int(debug_state.get("worker_pid", 0)), 0)
	assert_false(bool(debug_state.get("model_loaded", false)))

func test_same_runtime_key_shares_one_live_worker_across_families() -> void:
	var shared_pool = DepthSharedRuntimePoolScript.new()
	var straight_manager = _make_shared_manager(shared_pool, "straight_punch", "res://addons/aerobeat-input-camera-tracking/assets/depth_models/fastdepth/fastdepth_224_onnx/fastdepth.onnx")
	var hook_manager = _make_shared_manager(shared_pool, "hook", "res://addons/aerobeat-input-camera-tracking/assets/depth_models/fastdepth/fastdepth_224_onnx/fastdepth.onnx")
	var straight_ready: Dictionary = straight_manager.ensure_runtime_ready()
	var hook_ready: Dictionary = hook_manager.ensure_runtime_ready()
	var straight_live: Dictionary = straight_manager.get_debug_state()
	var hook_live: Dictionary = hook_manager.get_debug_state()
	assert_eq(String(straight_ready.get("runtime_status", "")), DepthRuntimeTypes.STATUS_READY)
	assert_eq(String(hook_ready.get("runtime_status", "")), DepthRuntimeTypes.STATUS_READY)
	assert_true(int(straight_live.get("worker_pid", 0)) > 0)
	assert_eq(int(straight_live.get("worker_pid", 0)), int(hook_live.get("worker_pid", 0)))
	assert_eq(int(straight_live.get("shared_runtime_refcount", 0)), 2)
	assert_eq(int(hook_live.get("shared_runtime_refcount", 0)), 2)
	assert_eq(String(straight_live.get("family", "")), "straight_punch")
	assert_eq(String(hook_live.get("family", "")), "hook")
	assert_eq(String(straight_live.get("shared_runtime_key", "")), String(hook_live.get("shared_runtime_key", "")))
	assert_true((straight_live.get("shared_runtime_family_claims", []) as Array).has("straight_punch"))
	assert_true((straight_live.get("shared_runtime_family_claims", []) as Array).has("hook"))
	assert_true(bool(straight_live.get("shared_runtime_shared", false)))
	assert_true(bool(hook_live.get("shared_runtime_shared", false)))

func test_different_runtime_keys_do_not_share_workers() -> void:
	var shared_pool = DepthSharedRuntimePoolScript.new()
	var straight_manager = _make_shared_manager(shared_pool, "straight_punch", "res://addons/aerobeat-input-camera-tracking/assets/depth_models/fastdepth/fastdepth_224_onnx/fastdepth.onnx")
	var uppercut_manager = _make_shared_manager(shared_pool, "uppercut", "res://addons/aerobeat-input-camera-tracking/assets/depth_models/midas/openvino_midas_v21_small_256/")
	var straight_ready: Dictionary = straight_manager.ensure_runtime_ready()
	var uppercut_ready: Dictionary = uppercut_manager.ensure_runtime_ready()
	assert_eq(String(straight_ready.get("runtime_status", "")), DepthRuntimeTypes.STATUS_READY)
	assert_eq(String(uppercut_ready.get("runtime_status", "")), DepthRuntimeTypes.STATUS_READY)
	assert_true(int(straight_ready.get("worker_pid", 0)) > 0)
	assert_true(int(uppercut_ready.get("worker_pid", 0)) > 0)
	assert_ne(int(straight_ready.get("worker_pid", 0)), int(uppercut_ready.get("worker_pid", 0)))
	assert_ne(String(straight_ready.get("shared_runtime_key", "")), String(uppercut_ready.get("shared_runtime_key", "")))

func test_release_keeps_shared_worker_alive_until_last_family_shutdown() -> void:
	var shared_pool = DepthSharedRuntimePoolScript.new()
	var straight_manager = _make_shared_manager(shared_pool, "straight_punch", "res://addons/aerobeat-input-camera-tracking/assets/depth_models/fastdepth/fastdepth_224_onnx/fastdepth.onnx")
	var hook_manager = _make_shared_manager(shared_pool, "hook", "res://addons/aerobeat-input-camera-tracking/assets/depth_models/fastdepth/fastdepth_224_onnx/fastdepth.onnx")
	var straight_ready: Dictionary = straight_manager.ensure_runtime_ready()
	var hook_ready: Dictionary = hook_manager.ensure_runtime_ready()
	var shared_pid := int(straight_ready.get("worker_pid", 0))
	assert_eq(shared_pid, int(hook_ready.get("worker_pid", 0)))
	straight_manager.shutdown()
	var straight_after_shutdown: Dictionary = straight_manager.get_debug_state()
	var hook_after_peer_shutdown: Dictionary = hook_manager.ensure_runtime_ready()
	assert_false(bool(straight_after_shutdown.get("worker_alive", false)))
	assert_eq(int(straight_after_shutdown.get("shared_runtime_refcount", 0)), 0)
	assert_true(bool(hook_after_peer_shutdown.get("worker_alive", false)))
	assert_eq(int(hook_after_peer_shutdown.get("worker_pid", 0)), shared_pid)
	assert_eq(int(hook_after_peer_shutdown.get("shared_runtime_refcount", 0)), 1)
	assert_false(bool(hook_after_peer_shutdown.get("shared_runtime_shared", false)))
	assert_true((hook_after_peer_shutdown.get("shared_runtime_family_claims", []) as Array).has("hook"))
	assert_false((hook_after_peer_shutdown.get("shared_runtime_family_claims", []) as Array).has("straight_punch"))

func test_final_release_reacquires_same_cached_runtime_key_without_new_worker() -> void:
	var shared_pool = DepthSharedRuntimePoolScript.new()
	var straight_manager = _make_shared_manager(shared_pool, "straight_punch", "res://addons/aerobeat-input-camera-tracking/assets/depth_models/fastdepth/fastdepth_224_onnx/fastdepth.onnx")
	var initial_ready: Dictionary = straight_manager.ensure_runtime_ready()
	var initial_pid := int(initial_ready.get("worker_pid", 0))
	assert_true(initial_pid > 0)
	straight_manager.shutdown()
	var reacquired_manager = _make_shared_manager(shared_pool, "hook", "res://addons/aerobeat-input-camera-tracking/assets/depth_models/fastdepth/fastdepth_224_onnx/fastdepth.onnx")
	var reacquired_ready: Dictionary = reacquired_manager.ensure_runtime_ready()
	assert_eq(String(reacquired_ready.get("runtime_status", "")), DepthRuntimeTypes.STATUS_READY)
	assert_eq(int(reacquired_ready.get("worker_pid", 0)), initial_pid)
	assert_true(int(reacquired_ready.get("model_load_count", 0)) >= 2)
	assert_eq(int(reacquired_ready.get("model_reload_count", 0)), 0)

func _make_shared_manager(shared_pool: RefCounted, family: String, artifact_path: String):
	var manager = DepthRuntimeManagerScript.new()
	manager.set_shared_runtime_pool(shared_pool)
	manager.configure_from_family(family, {
		"enabled": true,
		"model": {
			"artifact_path": artifact_path,
		}
	})
	return manager

func _fake_depth_result() -> Dictionary:
	return {
		"ok": true,
		"status": DepthRuntimeTypes.STATUS_READY,
		"backend_id": "onnx",
		"family_id": "fastdepth_224_onnx",
		"artifact_path": "res://addons/aerobeat-input-camera-tracking/assets/depth_models/fastdepth/fastdepth_224_onnx/fastdepth.onnx",
		"frame_size": Vector2i(640, 360),
		"depth_map_size": Vector2i(640, 360),
		"normalized_depth_map": null,
		"sample_metrics": {
			"sampling_mode": "single_point",
			"wrist_closeness": 0.21,
			"wrist_depth": 0.31,
			"torso_depth": 0.52,
			"sample_source": "fresh_inference",
			"sample_fresh": true,
			"sample_geometry": {
				"sampling_mode": "single_point",
				"actual_geometry_kind": "single_pixel_point",
				"aggregation": {
					"fallback_used": false,
					"fallback_reason": "",
				},
			},
		},
		"timing_ms": {
			"preprocess": 1.0,
			"infer": 2.0,
			"postprocess": 3.0,
			"total": 6.0,
		},
	}

func _fake_region_aware_depth_result() -> Dictionary:
	return {
		"ok": true,
		"status": DepthRuntimeTypes.STATUS_READY,
		"backend_id": "onnx",
		"family_id": "fastdepth_224_onnx",
		"artifact_path": "res://addons/aerobeat-input-camera-tracking/assets/depth_models/fastdepth/fastdepth_224_onnx/fastdepth.onnx",
		"frame_size": Vector2i(640, 360),
		"depth_map_size": Vector2i(640, 360),
		"normalized_depth_map": null,
		"sample_metrics": {
			"sampling_mode": "region_aware",
			"wrist_closeness": 0.18,
			"wrist_depth": 0.34,
			"torso_depth": 0.52,
			"sample_source": "fresh_inference",
			"sample_fresh": true,
			"sample_geometry": {
				"sampling_mode": "region_aware",
				"actual_geometry_kind": "landmark_region",
				"requested_runtime_geometry": {
					"region_geometry": {
						"wrist_shape": "extended_capsule",
						"wrist_radius_px": 12,
						"wrist_extension_toward_elbow_px": 8,
						"torso_shape": "center_box",
						"torso_half_width_px": 18,
						"torso_half_height_px": 18,
						"torso_anchor": "shoulder_landmark",
					},
					"aggregation": {
						"wrist_depth_stat": "median",
						"torso_depth_stat": "median",
						"trim_fraction": 0.0,
						"min_valid_samples": 5,
					},
				},
				"aggregation": {
					"fallback_used": true,
					"fallback_reason": "center_point_due_to_sparse_region",
					"applied": {
						"wrist": {
							"stat_applied": "center_point",
							"valid_sample_count": 1,
						},
						"torso": {
							"stat_applied": "median",
							"valid_sample_count": 9,
						},
					},
				},
			},
		},
		"timing_ms": {
			"preprocess": 1.0,
			"infer": 2.0,
			"postprocess": 3.0,
			"total": 6.0,
		},
	}

func _make_test_texture() -> Texture2D:
	var image := Image.create(2, 2, false, Image.FORMAT_L8)
	image.fill(Color(0.75, 0.75, 0.75, 1.0))
	return ImageTexture.create_from_image(image)

func _preview_frame_payload() -> Dictionary:
	return {
		"preview_descriptor": {
			"image_path": ProjectSettings.globalize_path("res://addons/aerobeat-input-camera-tracking/.testbed/test-results/qa-fixture-captures/2026-06-03-task-aby/left-gui/proving.png"),
		}
	}

func _sample_request(family: String, side: String) -> Dictionary:
	return {
		"family": family,
		"side": side,
		"timestamp_ms": 1234,
		"shoulder": {"x": 0.45, "y": 0.42},
		"elbow": {"x": 0.48, "y": 0.55},
		"wrist": {"x": 0.56, "y": 0.66},
	}
