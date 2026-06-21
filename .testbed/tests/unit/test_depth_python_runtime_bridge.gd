extends "res://addons/aerobeat-vendor-godot-unit-test/test.gd"

const DepthPythonRuntimeBridgeScript = preload("res://addons/aerobeat-input-camera-tracking/src/depth/depth_python_runtime_bridge.gd")

func test_decodes_normalized_depth_map_png_base64_into_runtime_texture() -> void:
	var bridge = DepthPythonRuntimeBridgeScript.new()
	var image := Image.create(3, 2, false, Image.FORMAT_L8)
	image.fill(Color(0.6, 0.6, 0.6, 1.0))
	var payload := {
		"ok": true,
		"normalized_depth_map_png_base64": Marshalls.raw_to_base64(image.save_png_to_buffer()),
	}
	var hydrated: Dictionary = bridge.call("_hydrate_depth_texture_response", payload)
	var texture: Variant = hydrated.get("normalized_depth_map", null)
	assert_true(texture is Texture2D)
	assert_eq((texture as Texture2D).get_width(), 3)
	assert_eq((texture as Texture2D).get_height(), 2)

func test_invalid_normalized_depth_map_png_payload_stays_truthfully_null() -> void:
	var bridge = DepthPythonRuntimeBridgeScript.new()
	var payload := {
		"ok": true,
		"normalized_depth_map_png_base64": Marshalls.raw_to_base64(PackedByteArray([1, 2, 3, 4])),
	}
	var hydrated: Dictionary = bridge.call("_hydrate_depth_texture_response", payload)
	assert_eq(hydrated.get("normalized_depth_map", null), null)
