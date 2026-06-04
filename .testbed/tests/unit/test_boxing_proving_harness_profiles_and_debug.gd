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

	var line: String = String(harness._build_hand_debug_line("left", hand_snapshot))
	assert_string_contains(line, "L: state=triggered")
	assert_string_contains(line, "tracking=tracked")
	assert_string_contains(line, "valid=true")
	assert_string_contains(line, "wrist_vel=0.420")
	assert_string_contains(line, "bbox_area=0.055")
	assert_string_contains(line, "bbox_growth=0.015")
	assert_string_contains(line, "grace=2")
	assert_string_contains(line, "reacquire=1")

func test_boxing_punch_hover_card_uses_bbox_state_machine_debug_fields() -> void:
	var harness = _new_harness()
	harness.set("_latest_state", {
		"gesture_debug": {
			"straight_punch": {
				"left": {
					"state": "not_ready",
					"tracking_state": "tracked",
					"tracking_valid": true,
					"stale_frames": 1,
					"fresh_sample": true,
					"wrist_velocity": 0.420,
					"min_wrist_velocity": 0.180,
					"bbox_area": 0.052,
					"bbox_area_growth": 0.015,
					"min_bbox_area_growth": 0.010,
					"positive_growth_samples": 3,
					"min_positive_growth_samples": 3,
					"sample_window_size": 4,
					"growth_window_areas": [0.020, 0.028, 0.041, 0.052],
					"grace_frames_remaining": 0,
					"triggered_grace_frames": 3,
					"trigger_bbox_area": 0.061,
					"bbox_area_retract_epsilon": 0.003,
					"reacquire_valid_samples": 1,
					"reacquire_stable_frames_required": 2,
				}
			}
		}
	})

	var model: Dictionary = harness._build_hover_card_model("punch_left")
	var rows: Array = model.get("rows", [])
	assert_eq(String(model.get("title", "")), "Straight Punch L")
	assert_eq(String(rows[1].get("current_text", "")), "not_ready")
	assert_eq(String(rows[2].get("current_text", "")), "tracked, valid=true, stale_frames=1")
	assert_eq(String(rows[3].get("current_text", "")), "true")
	assert_eq(String(rows[5].get("threshold_text", "")), "0.180")
	assert_eq(String(rows[5].get("current_text", "")), "0.420")
	assert_eq(String(rows[7].get("threshold_text", "")), "0.010")
	assert_eq(String(rows[8].get("current_text", "")), "3/4")
	assert_eq(String(rows[12].get("current_text", "")), "0.061")
	assert_eq(String(rows[13].get("current_text", "")), "0.052 <= 0.058 (trigger 0.061 - eps 0.003)")

func test_boxing_punch_inspector_body_calls_out_live_bbox_inputs() -> void:
	var harness = _new_harness()
	harness.set("_latest_state", {
		"gesture_debug": {
			"straight_punch": {
				"right": {
					"state": "triggered",
					"tracking_state": "tracked",
					"tracking_valid": true,
					"stale_frames": 0,
					"fresh_sample": false,
					"wrist_velocity": 0.310,
					"min_wrist_velocity": 0.180,
					"bbox_area": 0.071,
					"bbox_area_growth": 0.012,
					"min_bbox_area_growth": 0.010,
					"positive_growth_samples": 4,
					"min_positive_growth_samples": 3,
					"sample_window_size": 4,
					"growth_window_areas": [0.020, 0.038, 0.055, 0.071],
					"grace_frames_remaining": 2,
					"triggered_grace_frames": 3,
					"trigger_bbox_area": 0.071,
					"bbox_area_retract_epsilon": 0.003,
					"reacquire_valid_samples": 0,
					"reacquire_stable_frames_required": 2,
				}
			}
		}
	})

	var inspector: Dictionary = harness._build_custom_inspector_model("gesture", "punch_right")
	var body := String(inspector.get("body", ""))
	assert_string_contains(body, "Current state - triggered")
	assert_string_contains(body, "Hand tracking - tracked, valid=true, stale_frames=0")
	assert_string_contains(body, "Fresh sample valid - false")
	assert_string_contains(body, "Wrist velocity >= 0.180 - 0.310")
	assert_string_contains(body, "BBox area - 0.071")
	assert_string_contains(body, "BBox area growth >= 0.010 - 0.012")
	assert_string_contains(body, "Positive growth samples >= 3/4 - 4/4")
	assert_string_contains(body, "Grace timer - 2/3 remaining (active)")
	assert_string_contains(body, "Stored trigger bbox area - 0.071")
	assert_string_contains(body, "BBox retracted enough to rearm - 0.071 <= 0.068 (trigger 0.071 - eps 0.003)")
