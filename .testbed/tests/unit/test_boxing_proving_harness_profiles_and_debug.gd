extends "res://addons/aerobeat-vendor-godot-unit-test/test.gd"

func _new_harness() -> Object:
	var harness_script: Script = load("res://scripts/boxing_proving_harness.gd") as Script
	return harness_script.new()

func test_boxing_proving_runtime_config_loads_selected_flow_profile_bundle() -> void:
	var harness = _new_harness()
	harness.set("_selected_profile_id", "flow")

	var config: Variant = harness._build_runtime_config()
	assert_not_null(config)
	assert_eq(String(config.get_selected_profile_id()), "flow")

	var bundle: Dictionary = config.get_selected_profile_bundle()
	assert_true(bool(bundle.get("ok", false)))
	assert_eq(String(bundle.get("profile", "")), "flow")
	assert_true(String(bundle.get("camera_tracking_path", "")).ends_with("assets/flow.camera_tracking.yaml"))
	assert_true(String(bundle.get("gesture_detection_path", "")).ends_with("assets/flow.gesture_detection.yaml"))

func test_boxing_proving_hand_debug_line_surfaces_bbox_state_metrics() -> void:
	var harness = _new_harness()
	harness.set("_latest_state", {
		"gesture_debug": {
			"straight_punch": {
				"left": {
					"state": "triggered",
					"wrist_velocity": 0.42,
					"bbox_area_growth": 0.015,
					"grace_frames_remaining": 2,
					"reacquire_valid_samples": 1,
				}
			}
		}
	})
	var hand_snapshot := {
		"hands": {
			"left": {
				"tracking_state": "tracked",
				"tracking_valid": true,
				"stale_frames": 0,
				"bbox": {
					"area": 0.055,
				}
			}
		}
	}

	var line := harness._build_hand_debug_line("left", hand_snapshot)
	assert_string_contains(line, "L: state=triggered")
	assert_string_contains(line, "tracking=tracked")
	assert_string_contains(line, "valid=true")
	assert_string_contains(line, "wrist_vel=0.420")
	assert_string_contains(line, "bbox_area=0.055")
	assert_string_contains(line, "bbox_growth=0.015")
	assert_string_contains(line, "grace=2")
	assert_string_contains(line, "reacquire=1")
