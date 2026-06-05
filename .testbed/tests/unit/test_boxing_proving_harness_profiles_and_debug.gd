extends "res://addons/aerobeat-vendor-godot-unit-test/test.gd"

const LandmarkDrawerScript = preload("res://scripts/landmark_drawer.gd")
const HandBBoxDrawerScript = preload("res://scripts/hand_bbox_state_drawer.gd")
const ProvingHarnessScript = preload("res://scripts/proving_harness.gd")
const BoxingProvingScene = preload("res://scenes/boxing_proving.tscn")

class FakePreviewPresenter:
	extends Control

	var overlay_layer: Control
	var hand_snapshot := {
		"hands": {
			"left": {
				"has_bbox": true,
				"tracking_valid": true,
				"tracking_state": "tracked",
				"bbox": {
					"x": 0.10,
					"y": 0.20,
					"width": 0.30,
					"height": 0.40,
					"area": 0.12,
				},
			},
			"right": {},
		}
	}

	func _init() -> void:
		overlay_layer = Control.new()
		overlay_layer.name = "OverlayLayer"
		overlay_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		add_child(overlay_layer)

	func get_overlay_layer() -> Control:
		return overlay_layer

	func get_hand_debug_snapshot() -> Dictionary:
		return hand_snapshot.duplicate(true)

class PlaybackStateHarness:
	extends ProvingHarnessScript

	var state := {"media_loaded": true}

	func _get_playback_controller_state() -> Dictionary:
		return state

	func _is_prerecorded_source_active() -> bool:
		return true

func _new_harness() -> Object:
	var harness_script: Script = load("res://scripts/boxing_proving_harness.gd") as Script
	return harness_script.new()

func _has_editor_exposed_property(subject: Object, property_name: String) -> bool:
	for property_info_variant: Variant in subject.get_property_list():
		if not property_info_variant is Dictionary:
			continue
		var property_info: Dictionary = property_info_variant
		if String(property_info.get("name", "")) != property_name:
			continue
		return (int(property_info.get("usage", 0)) & PROPERTY_USAGE_EDITOR) != 0
	return false

func test_boxing_proving_scene_no_longer_has_in_scene_profile_picker_controls() -> void:
	var scene_root: Control = add_child_autoqfree(BoxingProvingScene.instantiate()) as Control
	assert_not_null(scene_root)
	assert_null(scene_root.find_child("ProfileLabel", true, false))
	assert_null(scene_root.find_child("ProfilePicker", true, false))
	assert_not_null(scene_root.find_child("TrackerConfigPath", true, false))
	assert_not_null(scene_root.find_child("GestureConfigPath", true, false))

func test_proving_harness_runtime_tuning_fields_are_hidden_from_editor_surface() -> void:
	var harness: Object = ProvingHarnessScript.new()
	assert_true(_has_editor_exposed_property(harness, "scene_title"))
	assert_false(_has_editor_exposed_property(harness, "overlay_visibility_threshold"))
	assert_false(_has_editor_exposed_property(harness, "tracking_smoothing_style"))
	assert_false(_has_editor_exposed_property(harness, "gesture_eval_interval_frames"))
	assert_false(_has_editor_exposed_property(harness, "debug_panel_refresh_interval_frames"))
	assert_false(_has_editor_exposed_property(harness, "inspector_live_refresh_interval_ms"))
	assert_eq(int(harness.get("debug_panel_refresh_interval_frames")), 10)
	assert_eq(int(harness.get("inspector_live_refresh_interval_ms")), 120)

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
	assert_true(String(bundle.get("testbed_debug_path", "")).ends_with("assets/flow.testbed_debug.yaml"))
	assert_false(bool(bundle.get("camera_tracking", {}).get("tracking", {}).get("hands", {}).get("enabled", true)))


func test_flow_proving_runtime_config_defaults_to_flow_profile_bundle() -> void:
	var harness: Variant = ProvingHarnessScript.new()
	harness.set("harness_mode", int(ProvingHarnessScript.HarnessMode.FLOW))

	var config: Variant = harness._build_runtime_config()
	assert_not_null(config)
	assert_eq(String(config.get_selected_profile_id()), "flow")
	assert_eq(int(harness.get("debug_panel_refresh_interval_frames")), 10)
	assert_eq(int(harness.get("inspector_live_refresh_interval_ms")), 120)
	var bundle: Dictionary = config.get_selected_profile_bundle()
	assert_true(bool(bundle.get("ok", false)))
	assert_eq(String(bundle.get("profile", "")), "flow")

func test_boxing_proving_profile_visual_config_drives_overlay_toggles() -> void:
	var harness: Variant = _new_harness()
	var landmark_drawer: Control = add_child_autoqfree(LandmarkDrawerScript.new())
	var trail_drawer: Control = add_child_autoqfree(Control.new())
	var hand_bbox_drawer: Control = add_child_autoqfree(Control.new())
	harness.set("landmark_drawer", landmark_drawer)
	harness.set("trail_drawer", trail_drawer)
	harness.set("hand_bbox_drawer", hand_bbox_drawer)

	harness.set("_selected_profile_id", "boxing")
	harness._sync_profile_visual_config()
	assert_eq(int(harness.get("debug_panel_refresh_interval_frames")), 10)
	assert_eq(int(harness.get("inspector_live_refresh_interval_ms")), 120)
	assert_true(bool(harness.get("show_landmarks")))
	assert_false(bool(harness.get("show_trails")))
	assert_false(bool(landmark_drawer.get("show_debug_hit_targets")))
	assert_false(bool(landmark_drawer.get("show_debug_hit_target_labels")))
	assert_true(hand_bbox_drawer.visible)

	harness.set("_selected_profile_id", "flow")
	harness._sync_profile_visual_config()
	assert_true(bool(harness.get("show_landmarks")))
	assert_true(bool(harness.get("show_trails")))
	assert_false(bool(landmark_drawer.get("show_debug_hit_targets")))
	assert_false(bool(landmark_drawer.get("show_debug_hit_target_labels")))
	assert_false(hand_bbox_drawer.visible)

func test_boxing_proving_bbox_overlay_reparents_into_preview_overlay_layer_and_receives_snapshot() -> void:
	var harness: Variant = _new_harness()
	var presenter: FakePreviewPresenter = add_child_autoqfree(FakePreviewPresenter.new())
	var hand_bbox_drawer: Control = add_child_autoqfree(HandBBoxDrawerScript.new())
	hand_bbox_drawer.name = "HandBBoxDrawer"
	harness.set("_preview_presenter", presenter)
	harness.set("hand_bbox_drawer", hand_bbox_drawer)
	harness.set("_latest_state", {
		"gesture_debug": {
			"straight_punch": {
				"left": {"state": "ready"}
			}
		}
	})

	harness._sync_hand_bbox_drawer()

	assert_same(hand_bbox_drawer.get_parent(), presenter.get_overlay_layer())
	assert_same(hand_bbox_drawer.get("_preview_presenter"), presenter)
	assert_false((hand_bbox_drawer.get("_hand_snapshot") as Dictionary).is_empty())
	assert_eq(hand_bbox_drawer.anchor_right, 1.0)
	assert_eq(hand_bbox_drawer.anchor_bottom, 1.0)
	assert_eq(hand_bbox_drawer.offset_left, 0.0)
	assert_eq(hand_bbox_drawer.offset_bottom, 0.0)

func test_boxing_proving_hand_debug_line_surfaces_bbox_state_metrics() -> void:
	var harness = _new_harness()
	harness.set("_latest_state", {
		"gesture_debug": {
			"straight_punch": {
				"left": {
					"state": "triggered",
					"wrist_velocity": 0.42,
					"wrist_forward_velocity": 0.09,
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
	assert_string_contains(line, "wrist_xyz_vel=0.420")
	assert_string_contains(line, "wrist_forward_vel=0.090")
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
					"wrist_forward_velocity": 0.150,
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
	assert_eq(String(rows[4].get("current_text", "")), "waiting for first straight-punch state change")
	assert_eq(String(rows[5].get("current_text", "")), "state=not_ready wrist=0.420 bbox=0.052 growth=0.015 fresh=true grace=0 valid=true")
	assert_eq(String(rows[7].get("threshold_text", "")), "0.180")
	assert_eq(String(rows[7].get("current_text", "")), "0.420")
	assert_eq(String(rows[9].get("threshold_text", "")), "0.010")
	assert_eq(String(rows[10].get("current_text", "")), "3/4")
	assert_eq(String(rows[14].get("current_text", "")), "0.061")
	assert_eq(String(rows[15].get("current_text", "")), "0.052 <= 0.058 (trigger 0.061 - eps 0.003)")

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
					"wrist_forward_velocity": 0.120,
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
	assert_false(body.contains("Event payload snapshot"))
	assert_string_contains(body, "Wrist xyz velocity >= 0.180 - 0.310")
	assert_string_contains(body, "BBox area - 0.071")
	assert_string_contains(body, "BBox area growth >= 0.010 - 0.012")
	assert_string_contains(body, "Positive growth samples >= 3/4 - 4/4")
	assert_string_contains(body, "Grace timer - 2/3 remaining (active)")
	assert_string_contains(body, "Stored trigger bbox area - 0.071")
	assert_string_contains(body, "BBox retracted enough to rearm - 0.071 <= 0.068 (trigger 0.071 - eps 0.003)")

func test_boxing_punch_inspector_freezes_paused_values_for_gesture_popups() -> void:
	var harness = _new_harness()
	harness.set("_playback_status", {"paused": true})
	harness.set("_latest_state", {
		"gesture_debug": {
			"straight_punch": {
				"right": {
					"state": "triggered",
					"tracking_state": "tracked",
					"tracking_valid": true,
					"stale_frames": 0,
					"fresh_sample": true,
					"wrist_velocity": 0.310,
					"wrist_forward_velocity": 0.120,
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
	harness.set("_straight_punch_transition_debug", {
		"left": {},
		"right": {
			"state": "triggered",
			"previous_state": "ready",
			"timestamp_ms": Time.get_ticks_msec() - 80,
			"tracking_state": "tracked",
			"tracking_valid": true,
			"stale_frames": 0,
			"fresh_sample": true,
			"wrist_velocity": 0.310,
			"bbox_area": 0.071,
			"bbox_area_growth": 0.012,
			"grace_frames_remaining": 2,
		}
	})

	harness._capture_paused_boxing_snapshot()
	harness._open_shared_inspector("gesture", "punch_right")
	var frozen_model: Dictionary = harness._resolve_shared_inspector_model(true)
	var frozen_body := String(frozen_model.get("body", ""))

	harness.set("_latest_state", {
		"gesture_debug": {
			"straight_punch": {
				"right": {
					"state": "ready",
					"tracking_state": "tracked",
					"tracking_valid": true,
					"stale_frames": 0,
					"fresh_sample": false,
					"wrist_velocity": 0.0,
					"min_wrist_velocity": 0.180,
					"bbox_area": 0.071,
					"bbox_area_growth": 0.0,
					"min_bbox_area_growth": 0.010,
					"positive_growth_samples": 0,
					"min_positive_growth_samples": 3,
					"sample_window_size": 4,
					"growth_window_areas": [0.071],
					"grace_frames_remaining": 0,
					"triggered_grace_frames": 3,
					"trigger_bbox_area": 0.071,
					"bbox_area_retract_epsilon": 0.003,
					"reacquire_valid_samples": 0,
					"reacquire_stable_frames_required": 2,
				}
			}
		}
	})
	var still_frozen: Dictionary = harness._resolve_shared_inspector_model(true)
	var still_frozen_body := String(still_frozen.get("body", ""))

	assert_eq(still_frozen_body, frozen_body)
	assert_string_contains(still_frozen_body, "Latest state change - ready -> triggered")
	assert_string_contains(still_frozen_body, "Wrist xyz velocity >= 0.180 - 0.310")
	assert_string_contains(still_frozen_body, "BBox area growth >= 0.010 - 0.012")
	assert_false(still_frozen_body.contains("Event payload snapshot"))

func test_playback_step_buttons_only_enable_while_paused() -> void:
	var harness: Variant = PlaybackStateHarness.new()
	harness.set("_playback_toggle_button", Button.new())
	harness.set("_playback_seek_slider", HSlider.new())
	harness.set("_playback_time_label", Label.new())
	var step_back := Button.new()
	var step_forward := Button.new()
	harness.set("_playback_step_back_button", step_back)
	harness.set("_playback_step_forward_button", step_forward)
	harness.set("camera_source", "res://fixtures/replay/head_rotate_left_repeat_04_take_01.mp4")
	harness.set("_playback_transport_capabilities", {
		"transport_mode": "exact_owned_frame_index",
		"can_step_forward": true,
		"can_step_backward": true,
	})
	harness.set("_playback_transport_status", {
		"transport_mode": "exact_owned_frame_index",
		"can_step_forward": true,
		"can_step_backward": true,
		"paused": true,
	})
	harness.set("_playback_status", {"paused": true, "current_time_sec": 1.0, "duration_sec": 2.0, "progress": 0.5})
	harness._refresh_playback_controls_state()
	assert_false(step_back.disabled)
	assert_false(step_forward.disabled)

	harness.set("_playback_status", {"paused": false, "current_time_sec": 1.0, "duration_sec": 2.0, "progress": 0.5})
	harness._refresh_playback_controls_state()
	assert_true(step_back.disabled)
	assert_true(step_forward.disabled)

func test_boxing_punch_hover_card_merges_latest_state_change_signal_snapshot() -> void:
	var harness = _new_harness()
	harness.set("_straight_punch_transition_debug", {
		"left": {
			"state": "triggered",
			"previous_state": "ready",
			"timestamp_ms": Time.get_ticks_msec() - 80,
			"tracking_state": "tracked",
			"tracking_valid": true,
			"stale_frames": 0,
			"fresh_sample": true,
			"wrist_velocity": 0.280,
			"bbox_area": 0.064,
			"bbox_area_growth": 0.011,
			"grace_frames_remaining": 3,
		},
		"right": {},
	})

	var model: Dictionary = harness._build_hover_card_model("punch_left")
	var rows: Array = model.get("rows", [])
	assert_string_contains(String(rows[1].get("current_text", "")), "triggered")
	assert_string_contains(String(rows[4].get("current_text", "")), "ready -> triggered")
	assert_eq(String(rows[5].get("current_text", "")), "state=triggered wrist=0.280 bbox=0.064 growth=0.011 fresh=true grace=3 valid=true")
