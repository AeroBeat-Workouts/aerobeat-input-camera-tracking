class_name OpenvinoDepthAdapter
extends "res://addons/aerobeat-input-camera-tracking/src/depth/depth_model_adapter.gd"


func load(model_spec: Dictionary) -> Dictionary:
	return load_via_python_runtime(model_spec, "openvino")

func infer(frame_payload: Dictionary, request: Dictionary) -> Dictionary:
	return infer_via_python_runtime(frame_payload, request)
