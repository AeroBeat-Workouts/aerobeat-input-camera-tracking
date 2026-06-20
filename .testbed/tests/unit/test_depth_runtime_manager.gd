extends "res://addons/aerobeat-vendor-godot-unit-test/test.gd"

const DepthRuntimeManagerScript = preload("res://addons/aerobeat-input-camera-tracking/src/depth/depth_runtime_manager.gd")
const DepthRuntimeTypes = preload("res://addons/aerobeat-input-camera-tracking/src/depth/depth_runtime_types.gd")

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
