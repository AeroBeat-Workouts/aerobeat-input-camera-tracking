extends "res://addons/aerobeat-vendor-godot-unit-test/test.gd"

const LandmarkDrawerScript = preload("res://scripts/landmark_drawer.gd")
const HandBBoxDrawerScript = preload("res://scripts/hand_bbox_state_drawer.gd")
const ProvingHarnessScript = preload("res://scripts/proving_harness.gd")
const BoxingProvingScene = preload("res://scenes/boxing_proving.tscn")
const FlowProvingScene = preload("res://scenes/flow_proving.tscn")

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

class FakeAthleteRecalibrateProvider:
	extends Node

	var request_count := 0

	func request_athlete_recalibration() -> bool:
		request_count += 1
		return true

	func get_detector_state() -> Dictionary:
		return {
			"gesture_debug": {
				"squat": {
					"state": false,
					"calibration_ready": false,
					"calibration_sample_frames": 0,
				}
			}
		}

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

func test_hand_bbox_drawer_prefers_grace_tracking_state_over_gesture_state() -> void:
	var drawer = add_child_autoqfree(HandBBoxDrawerScript.new())
	drawer.update_snapshot({}, {
		"left": {
			"state": "triggered",
		}
	})
	var state_name: String = drawer._resolve_side_state("left", {
		"tracking_valid": true,
		"tracking_state": "grace",
	})
	assert_eq(String(state_name), "grace")
	assert_eq(drawer.STATE_COLORS["grace"], Color8(0xff, 0x4f, 0xd8, 0xff))

func test_hand_bbox_drawer_prefers_active_tracker_state_over_gesture_tracking_lost() -> void:
	var drawer = add_child_autoqfree(HandBBoxDrawerScript.new())
	drawer.update_snapshot({}, {
		"left": {
			"state": "tracking_lost",
		}
	})
	assert_eq(String(drawer._resolve_side_state("left", {
		"tracking_valid": false,
		"tracking_state": "reacquiring",
	})), "reacquiring")
	assert_eq(String(drawer._resolve_side_state("left", {
		"tracking_valid": true,
		"tracking_state": "tracked",
	})), "tracked")
	assert_eq(String(drawer._resolve_side_state("left", {
		"tracking_valid": true,
		"tracking_state": "stale",
	})), "stale")

func test_boxing_proving_scene_no_longer_has_in_scene_profile_picker_controls() -> void:
	var scene_root: Control = add_child_autoqfree(BoxingProvingScene.instantiate()) as Control
	assert_not_null(scene_root)
	assert_null(scene_root.find_child("ProfileLabel", true, false))
	assert_null(scene_root.find_child("ProfilePicker", true, false))
	assert_not_null(scene_root.find_child("TrackerConfigPath", true, false))
	assert_not_null(scene_root.find_child("GestureConfigPath", true, false))

func test_boxing_proving_scene_applies_boxing_testbed_debug_yaml_to_live_nodes() -> void:
	var scene_root: Control = add_child_autoqfree(BoxingProvingScene.instantiate()) as Control
	assert_not_null(scene_root)
	var harness := scene_root as Object
	var landmark_drawer := scene_root.find_child("LandmarkDrawer", true, false) as Control
	var trail_drawer := scene_root.find_child("TrailDrawer", true, false) as Control
	var hand_bbox_drawer := scene_root.find_child("HandBBoxDrawer", true, false) as Control
	assert_not_null(landmark_drawer)
	assert_not_null(trail_drawer)
	assert_not_null(hand_bbox_drawer)
	assert_eq(int(harness.get("debug_panel_refresh_interval_ms")), 160)
	assert_eq(int(harness.get("inspector_live_refresh_interval_ms")), 120)
	assert_true(bool(harness.get("show_landmarks")))
	assert_false(bool(harness.get("show_trails")))
	assert_false(bool(landmark_drawer.get("show_debug_hit_targets")))
	assert_false(bool(landmark_drawer.get("show_debug_hit_target_labels")))
	assert_true(hand_bbox_drawer.visible)

func test_proving_harness_runtime_tuning_fields_are_hidden_from_editor_surface() -> void:
	var harness: Object = ProvingHarnessScript.new()
	assert_true(_has_editor_exposed_property(harness, "scene_title"))
	assert_false(_has_editor_exposed_property(harness, "overlay_visibility_threshold"))
	assert_false(_has_editor_exposed_property(harness, "tracking_smoothing_style"))
	assert_false(_has_editor_exposed_property(harness, "gesture_eval_interval_frames"))
	assert_false(_has_editor_exposed_property(harness, "debug_panel_refresh_interval_ms"))
	assert_false(_has_editor_exposed_property(harness, "inspector_live_refresh_interval_ms"))
	assert_eq(int(harness.get("debug_panel_refresh_interval_ms")), 160)
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


func test_proving_runtime_config_uses_profile_yaml_pose_smoothing_over_hidden_scene_default() -> void:
	var harness: Variant = ProvingHarnessScript.new()
	harness.set("harness_mode", int(ProvingHarnessScript.HarnessMode.BOXING))
	harness.set("tracking_smoothing_style", int(ProvingHarnessScript.TrackingSmoothingStyle.LITE_RAW))

	var config: Variant = harness._build_runtime_config()
	assert_not_null(config)
	var selected_style := String(config.get_selected_profile_bundle().get("camera_tracking", {}).get("tracking", {}).get("pose", {}).get("smoothing_style", "")).strip_edges().to_lower()
	assert_true(["lite_raw", "lite_filtered"].has(selected_style))
	var expects_filter_enabled := selected_style == "lite_filtered"
	assert_eq(bool(config.runtime.get("filter_enabled", false)), expects_filter_enabled)
	assert_eq(bool(config.runtime.get("no_filter", true)), not expects_filter_enabled)

func test_flow_proving_runtime_config_defaults_to_flow_profile_bundle() -> void:
	var harness: Variant = ProvingHarnessScript.new()
	harness.set("harness_mode", int(ProvingHarnessScript.HarnessMode.FLOW))

	var config: Variant = harness._build_runtime_config()
	assert_not_null(config)
	assert_eq(String(config.get_selected_profile_id()), "flow")
	assert_eq(int(harness.get("debug_panel_refresh_interval_ms")), 160)
	assert_eq(int(harness.get("inspector_live_refresh_interval_ms")), 120)
	var bundle: Dictionary = config.get_selected_profile_bundle()
	assert_true(bool(bundle.get("ok", false)))
	assert_eq(String(bundle.get("profile", "")), "flow")

func test_proving_runtime_config_can_force_prototype_matcher_backend_for_fixture_benchmarks() -> void:
	var previous := OS.get_environment("AEROBEAT_PUNCH_BACKEND_OVERRIDE")
	OS.set_environment("AEROBEAT_PUNCH_BACKEND_OVERRIDE", "prototype_matcher")
	var harness: Variant = ProvingHarnessScript.new()
	var config: Variant = harness._build_runtime_config()
	OS.set_environment("AEROBEAT_PUNCH_BACKEND_OVERRIDE", previous)

	assert_not_null(config)
	var gesture_profile: Dictionary = config.gesture_profile_document
	assert_eq(String(gesture_profile.get("punch_detection", {}).get("backend", "")), "prototype_matcher")
	assert_true(bool(gesture_profile.get("prototype_matcher", {}).get("enabled", false)))
	assert_false(bool(gesture_profile.get("threshold_gates", {}).get("enabled", true)))

func test_proving_runtime_config_can_force_learned_classifier_backend_for_fixture_benchmarks() -> void:
	var previous := OS.get_environment("AEROBEAT_PUNCH_BACKEND_OVERRIDE")
	OS.set_environment("AEROBEAT_PUNCH_BACKEND_OVERRIDE", "learned_classifier")
	var harness: Variant = ProvingHarnessScript.new()
	var config: Variant = harness._build_runtime_config()
	OS.set_environment("AEROBEAT_PUNCH_BACKEND_OVERRIDE", previous)

	assert_not_null(config)
	var gesture_profile: Dictionary = config.gesture_profile_document
	assert_eq(String(gesture_profile.get("punch_detection", {}).get("backend", "")), "learned_classifier")
	assert_true(bool(gesture_profile.get("learned_classifier", {}).get("enabled", false)))
	assert_false(bool(gesture_profile.get("threshold_gates", {}).get("enabled", true)))

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
	assert_eq(int(harness.get("debug_panel_refresh_interval_ms")), 160)
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

func test_boxing_proving_profile_visual_config_uses_camera_tracking_preview_overlays_independently_from_debug_visuals() -> void:
	var harness: Variant = _new_harness()
	var landmark_drawer: Control = add_child_autoqfree(LandmarkDrawerScript.new())
	var trail_drawer: Control = add_child_autoqfree(Control.new())
	var hand_bbox_drawer: Control = add_child_autoqfree(Control.new())
	harness.set("landmark_drawer", landmark_drawer)
	harness.set("trail_drawer", trail_drawer)
	harness.set("hand_bbox_drawer", hand_bbox_drawer)

	harness._sync_profile_visual_config({
		"ok": true,
		"camera_tracking": {
			"preview": {
				"overlays": {
					"pose_skeleton_visible": false,
					"hand_bbox_visible": true,
				}
			}
		},
		"testbed_debug": {
			"visuals": {
				"show_landmarks": true,
				"show_trails": false,
				"show_hand_bbox_overlay": false,
			}
		}
	})

	assert_false(bool(harness.get("show_landmarks")))
	assert_true(hand_bbox_drawer.visible)
	assert_false(bool(trail_drawer.visible))

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
					"forward_depth_spike": 0.11,
					"recent_peak_forward_depth_spike": 0.14,
					"elbow_shoulder_xy_distance": 0.082,
					"max_elbow_shoulder_xy_distance": 0.090,
					"elbow_shoulder_xy_gate_passed": true,
					"bbox_area_growth": 0.015,
					"grace_ms_remaining": 160,
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
				"stale_ms": 0,
				"grace_ms": 0,
				"stable_ms": 80,
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
	assert_string_contains(line, "source=none")
	assert_string_contains(line, "wrist_xyz_vel=0.420")
	assert_string_contains(line, "wrist_forward_vel=0.090")
	assert_string_contains(line, "depth_spike=0.140")
	assert_string_contains(line, "elbow_shoulder_xy=0.082<=0.090(true)")
	assert_string_contains(line, "bbox_area=0.055")
	assert_string_contains(line, "bbox_growth=0.015")
	assert_string_contains(line, "grace=160ms")
	assert_string_contains(line, "hand_grace=0ms")
	assert_string_contains(line, "hand_stable=80ms")
	assert_string_contains(line, "stale=0ms")

func test_boxing_punch_hover_card_uses_bbox_state_machine_debug_fields() -> void:
	var harness = _new_harness()
	harness.set("_latest_state", {
		"gesture_debug": {
			"straight_punch": {
				"left": {
					"state": "not_ready",
					"tracking_state": "tracked",
					"sample_source": "fresh_inference",
					"tracking_valid": true,
					"stale_frames": 1,
					"stale_ms": 40,
					"grace_frames": 1,
					"grace_ms": 40,
					"stable_ms": 120,
					"fresh_sample": true,
					"wrist_velocity": 0.420,
					"wrist_forward_velocity": 0.150,
					"forward_depth_spike": 0.090,
					"recent_peak_forward_depth_spike": 0.120,
					"min_velocity": 0.180,
					"elbow_shoulder_xy_distance": 0.082,
					"max_elbow_shoulder_xy_distance": 0.090,
					"elbow_shoulder_xy_gate_passed": true,
					"bbox_area": 0.052,
					"bbox_area_growth": 0.015,
					"min_bbox_area_growth": 0.010,
					"positive_growth_samples": 3,
					"min_positive_growth_samples": 3,
					"sample_window_size": 4,
					"growth_window_areas": [0.020, 0.028, 0.041, 0.052],
					"grace_ms_remaining": 0,
					"triggered_grace_ms": 240,
					"trigger_bbox_area": 0.061,
					"bbox_area_retract_epsilon": 0.003,
					"reacquire_stable_ms_required": 40,
				}
			}
		}
	})

	var model: Dictionary = harness._build_hover_card_model("punch_left")
	var rows: Array = model.get("rows", [])
	assert_eq(String(model.get("title", "")), "Straight Punch L")
	assert_eq(String(rows[1].get("current_text", "")), "not_ready")
	assert_eq(String(rows[2].get("current_text", "")), "tracked, valid=true, source=fresh_inference, stale=40ms (1 frames), grace=40ms (1 frames), stable=120ms")
	assert_eq(String(rows[3].get("current_text", "")), "true")
	assert_eq(String(rows[4].get("current_text", "")), "waiting for first straight-punch state change")
	assert_eq(String(rows[5].get("current_text", "")), "state=not_ready wrist=0.420 depth=0.120 xy=0.082<=0.090 (true) bbox=0.052 growth=0.015 fresh=true source=fresh_inference grace=0ms valid=true")
	assert_eq(String(rows[7].get("threshold_text", "")), "0.180")
	assert_eq(String(rows[7].get("current_text", "")), "0.420")
	assert_eq(String(rows[8].get("threshold_text", "")), "0.090")
	assert_eq(String(rows[8].get("current_text", "")), "0.082")

func test_boxing_punch_inspector_body_calls_out_live_bbox_inputs() -> void:
	var harness = _new_harness()
	harness.set("_latest_state", {
		"gesture_debug": {
			"straight_punch": {
				"right": {
					"state": "triggered",
					"tracking_state": "tracked",
					"sample_source": "carried_forward",
					"tracking_valid": true,
					"stale_frames": 0,
					"stale_ms": 0,
					"grace_frames": 0,
					"grace_ms": 0,
					"stable_ms": 160,
					"fresh_sample": false,
					"wrist_velocity": 0.310,
					"wrist_forward_velocity": 0.120,
					"forward_depth_spike": 0.080,
					"recent_peak_forward_depth_spike": 0.110,
					"min_velocity": 0.180,
					"elbow_shoulder_xy_distance": 0.076,
					"max_elbow_shoulder_xy_distance": 0.090,
					"elbow_shoulder_xy_gate_passed": true,
					"bbox_area": 0.071,
					"bbox_area_growth": 0.012,
					"min_bbox_area_growth": 0.010,
					"positive_growth_samples": 3,
					"min_positive_growth_samples": 3,
					"sample_window_size": 4,
					"growth_window_areas": [0.020, 0.038, 0.055, 0.071],
					"grace_ms_remaining": 160,
					"triggered_grace_ms": 240,
					"trigger_bbox_area": 0.071,
					"bbox_area_retract_epsilon": 0.003,
					"reacquire_stable_ms_required": 40,
				}
			}
		}
	})

	var inspector: Dictionary = harness._build_custom_inspector_model("gesture", "punch_right")
	var body := String(inspector.get("body", ""))
	assert_string_contains(body, "Current state - triggered")
	assert_string_contains(body, "Hand tracking - tracked, valid=true, source=carried_forward, stale=0ms (0 frames), grace=0ms (0 frames), stable=160ms")
	assert_string_contains(body, "Fresh sample valid - false")
	assert_false(body.contains("Event payload snapshot"))
	assert_string_contains(body, "Recent punch velocity peak >= 0.180 - 0.310")
	assert_false(body.contains("Recent forward depth spike"))
	assert_string_contains(body, "Elbow-shoulder XY distance <= 0.090 - 0.076")
	assert_string_contains(body, "BBox area - 0.071")
	assert_string_contains(body, "Recent bbox area growth peak >= 0.010 - 0.012")
	assert_string_contains(body, "Positive growth samples >= 3/3 - 3/3")
	assert_string_contains(body, "Grace timer - 160/240ms remaining (active)")
	assert_string_contains(body, "Stored trigger bbox area - 0.071")
	assert_string_contains(body, "BBox retracted enough to rearm - 0.071 <= 0.068 (trigger 0.071 - eps 0.003)")

func test_boxing_prototype_matcher_hover_card_surfaces_backend_score_threshold_and_gate_truth() -> void:
	var harness = _new_harness()
	harness.set("_latest_state", {
		"gesture_debug": {
			"punch_detection": {
				"backend": "prototype_matcher",
			},
			"prototype_matcher": {
				"selected_backend": "prototype_matcher",
				"active_backend": "prototype_matcher",
				"library_id": "boxing_side_aware_v1",
				"library_loaded": true,
				"best_class": "straight_left",
				"best_score": 0.842,
				"required_score": 0.700,
				"result_class": "straight_left",
				"emitted_event_name": "punch_left",
				"show_scores": true,
				"show_event_gate_state": true,
				"class_scores": {
					"hook_left": 0.120,
					"straight_left": 0.842,
					"uppercut_left": 0.410,
				},
				"reason": "emit_cooldown_active",
				"hold_ms_remaining": 80,
				"cooldown_ms_remaining": 190,
				"active_event_class": "straight_left",
			}
		}
	})

	var model: Dictionary = harness._build_hover_card_model("punch_left")
	var rows: Array = model.get("rows", [])
	assert_eq(String(model.get("title", "")), "Straight Punch L (Prototype Matcher)")
	assert_eq(String(rows[1].get("current_text", "")), "prototype_matcher")
	assert_eq(String(rows[3].get("current_text", "")), "boxing_side_aware_v1")
	assert_eq(String(rows[6].get("current_text", "")), "straight_left")
	assert_eq(String(rows[7].get("current_text", "")), "0.842")
	assert_eq(String(rows[8].get("current_text", "")), "0.700")
	assert_eq(String(rows[9].get("current_text", "")), "straight_left")
	assert_eq(String(rows[10].get("current_text", "")), "punch_left")
	assert_eq(String(rows[11].get("current_text", "")), "true")
	assert_eq(String(rows[12].get("current_text", "")), "{hook_left=0.120, straight_left=0.842, uppercut_left=0.410}")
	assert_eq(String(rows[14].get("current_text", "")), "true")
	assert_eq(String(rows[15].get("current_text", "")), "emit_cooldown_active")
	assert_eq(String(rows[16].get("current_text", "")), "80ms")
	assert_eq(String(rows[17].get("current_text", "")), "190ms")
	assert_eq(String(rows[18].get("current_text", "")), "straight_left")

	var inspector: Dictionary = harness._build_custom_inspector_model("gesture", "punch_left")
	var body := String(inspector.get("body", ""))
	assert_string_contains(body, "Active backend - prototype_matcher")
	assert_string_contains(body, "Active prototype library ID - boxing_side_aware_v1")
	assert_string_contains(body, "Best class - straight_left")
	assert_string_contains(body, "Best score - 0.842")
	assert_string_contains(body, "Threshold required - 0.700")
	assert_string_contains(body, "Final emitted / result class - straight_left")
	assert_string_contains(body, "Emitted event name - punch_left")
	assert_string_contains(body, "Per-class scores - {hook_left=0.120, straight_left=0.842, uppercut_left=0.410}")
	assert_string_contains(body, "Gate / rejection reason - emit_cooldown_active")
	assert_string_contains(body, "Hold remaining - 80ms")
	assert_string_contains(body, "Cooldown remaining - 190ms")

func test_boxing_prototype_matcher_debug_visibility_flags_hide_scores_and_gate_state() -> void:
	var harness = _new_harness()
	harness.set("_latest_state", {
		"gesture_debug": {
			"punch_detection": {
				"backend": "prototype_matcher",
			},
			"prototype_matcher": {
				"selected_backend": "prototype_matcher",
				"active_backend": "prototype_matcher",
				"library_id": "boxing_side_aware_v1",
				"library_loaded": true,
				"best_class": "hook_right",
				"best_score": 0.610,
				"required_score": 0.700,
				"result_class": "no_punch",
				"emitted_event_name": "",
				"show_scores": false,
				"show_event_gate_state": false,
				"class_scores": {
					"hook_right": 0.610,
				},
				"reason": "below_threshold",
				"hold_ms_remaining": 55,
				"cooldown_ms_remaining": 144,
				"active_event_class": "hook_right",
			}
		}
	})

	var model: Dictionary = harness._build_hover_card_model("punch_right")
	var rows: Array = model.get("rows", [])
	assert_eq(String(model.get("title", "")), "Straight Punch R (Prototype Matcher)")
	assert_eq(String(rows[11].get("current_text", "")), "false")
	assert_eq(String(rows[12].get("current_text", "")), "hidden (show_scores=false)")
	assert_eq(String(rows[14].get("current_text", "")), "false")
	assert_eq(String(rows[15].get("current_text", "")), "hidden (show_event_gate_state=false)")
	assert_eq(String(rows[16].get("current_text", "")), "hidden (show_event_gate_state=false)")
	assert_eq(String(rows[17].get("current_text", "")), "hidden (show_event_gate_state=false)")
	assert_eq(String(rows[18].get("current_text", "")), "hidden (show_event_gate_state=false)")

	var text_body := String(harness._build_boxing_event_feed_text())
	assert_string_contains(text_body, "Prototype matcher truth")
	assert_string_contains(text_body, "Active backend: prototype_matcher")
	assert_string_contains(text_body, "Prototype library ID: boxing_side_aware_v1 (loaded=true)")
	assert_string_contains(text_body, "Best class / score / threshold: hook_right / 0.610 / 0.700")
	assert_string_contains(text_body, "Result class / emitted event: no_punch / none")
	assert_string_contains(text_body, "Debug flags: show_scores=false show_event_gate_state=false")
	assert_string_contains(text_body, "Class scores: hidden (show_scores=false)")
	assert_string_contains(text_body, "Gate reason / hold / cooldown / active event: hidden (show_event_gate_state=false)")

func test_boxing_learned_classifier_hover_card_and_event_feed_surface_truthful_backend_specific_fields() -> void:
	var harness = _new_harness()
	harness.set("_latest_state", {
		"gesture_debug": {
			"punch_detection": {
				"backend": "learned_classifier",
			},
			"learned_classifier": {
				"selected_backend": "learned_classifier",
				"active_backend": "learned_classifier",
				"model_path": "res://docs/models/test-mlp-result.json",
				"model_loaded": true,
				"best_class": "straight_left",
				"best_score": 0.932,
				"required_score": 0.700,
				"result_class": "straight_left",
				"emitted_event_name": "punch_left",
				"show_scores": true,
				"show_event_gate_state": true,
				"class_scores": {
					"straight_left": 0.932,
					"hook_left": 0.041,
					"no_punch": 0.015,
				},
				"reason": "emitted",
				"hold_ms_remaining": 100,
				"cooldown_ms_remaining": 250,
				"active_event_class": "straight_left",
			}
		}
	})

	var model: Dictionary = harness._build_hover_card_model("punch_left")
	var rows: Array = model.get("rows", [])
	assert_eq(String(model.get("title", "")), "Straight Punch L (Learned Classifier)")
	assert_eq(String(rows[3].get("label", "")), "Active learned model path")
	assert_eq(String(rows[3].get("current_text", "")), "res://docs/models/test-mlp-result.json")
	assert_eq(String(rows[4].get("label", "")), "Learned model loaded")
	assert_eq(String(rows[4].get("current_text", "")), "true")
	assert_eq(String(rows[6].get("current_text", "")), "straight_left")
	assert_eq(String(rows[7].get("current_text", "")), "0.932")
	assert_eq(String(rows[10].get("current_text", "")), "punch_left")

	var inspector: Dictionary = harness._build_custom_inspector_model("gesture", "punch_left")
	var body := String(inspector.get("body", ""))
	assert_string_contains(body, "Active learned model path - res://docs/models/test-mlp-result.json")
	assert_string_contains(body, "Best class - straight_left")
	assert_string_contains(body, "Per-class scores - {hook_left=0.041, no_punch=0.015, straight_left=0.932}")

	var text_body := String(harness._build_boxing_event_feed_text())
	assert_string_contains(text_body, "Learned classifier truth")
	assert_string_contains(text_body, "Active backend: learned_classifier")
	assert_string_contains(text_body, "Learned model path: res://docs/models/test-mlp-result.json (loaded=true)")
	assert_string_contains(text_body, "Best class / score / threshold: straight_left / 0.932 / 0.700")

func test_boxing_event_feed_makes_disabled_selected_backend_resolve_to_none_obvious() -> void:
	var harness = _new_harness()
	harness.set("_latest_state", {
		"gesture_debug": {
			"punch_detection": {
				"backend": "none",
				"active_backend": "none",
				"selected_backend": "learned_classifier",
				"selected_backend_enabled": false,
				"active_backend_resolution": "selected_backend_disabled",
				"threshold_gates_enabled": true,
			},
			"learned_classifier": {
				"selected_backend": "learned_classifier",
				"selected_backend_enabled": false,
				"active_backend": "none",
				"activation_reason": "selected_backend_disabled",
				"model_path": "res://docs/models/test-mlp-result.json",
				"model_loaded": false,
				"result_class": "no_punch",
				"best_class": "no_punch",
				"best_score": 0.0,
				"required_score": 0.700,
			},
		}
	})

	var text_body := String(harness._build_boxing_event_feed_text())
	assert_string_contains(text_body, "Learned classifier truth")
	assert_string_contains(text_body, "Active backend: none")
	assert_string_contains(text_body, "Selected backend: learned_classifier")
	assert_string_contains(text_body, "Selected backend enabled: false")
	assert_string_contains(text_body, "Backend resolution: selected_backend_disabled")
	assert_string_contains(text_body, "Learned model path: res://docs/models/test-mlp-result.json (loaded=false)")

func test_boxing_punch_hover_card_shows_extra_precision_when_rounding_would_fake_threshold_equality() -> void:
	var harness = _new_harness()
	harness.set("_latest_state", {
		"gesture_debug": {
			"straight_punch": {
				"left": {
					"state": "ready",
					"hand_tracking_enabled": true,
					"pose_tracking_valid": true,
					"tracking_state": "tracked",
					"tracking_valid": true,
					"sample_source": "fresh_inference",
					"fresh_sample": true,
					"wrist_velocity": 0.474,
					"recent_peak_wrist_velocity": 0.474,
					"forward_depth_spike": 0.00297168485325905,
					"recent_peak_forward_depth_spike": 0.00297168485325905,
					"min_velocity": 0.500,
					"elbow_shoulder_xy_distance": 0.040,
					"max_elbow_shoulder_xy_distance": 0.060,
					"elbow_shoulder_xy_gate_passed": true,
					"bbox_area": 0.007,
					"bbox_area_growth": 0.00297168485325905,
					"recent_peak_bbox_area_growth": 0.00297168485325905,
					"min_bbox_area_growth": 0.003,
					"positive_growth_samples": 4,
					"min_positive_growth_samples": 1,
					"sample_window_size": 17,
					"growth_window_areas": [0.005, 0.004, 0.004, 0.004, 0.004, 0.004, 0.005, 0.005, 0.010, 0.010, 0.008, 0.008, 0.012, 0.007, 0.007, 0.007, 0.007],
					"grace_ms_remaining": 0,
					"triggered_grace_ms": 240,
					"trigger_bbox_area": 0.0,
					"bbox_area_retract_epsilon": 0.003,
					"reacquire_stable_ms_required": 40,
				}
			}
		}
	})

	var model: Dictionary = harness._build_hover_card_model("punch_left")
	var rows: Array = model.get("rows", [])
	assert_eq(String(rows[8].get("threshold_text", "")), "0.060")
	assert_eq(String(rows[8].get("current_text", "")), "0.040")

	var inspector: Dictionary = harness._build_custom_inspector_model("gesture", "punch_left")
	var body := String(inspector.get("body", ""))
	assert_string_contains(body, "Recent punch velocity peak >= 0.500 - 0.474")
	assert_false(body.contains("Recent forward depth spike"))
	assert_string_contains(body, "Recent bbox area growth peak >= 0.003 - 0.002972")
	assert_string_contains(body, "Positive growth samples >= 1/16 - 4/16")

func test_boxing_pose_only_hand_debug_line_uses_pose_fallback_truth() -> void:
	var harness = _new_harness()
	harness.set("_latest_state", {
		"gesture_debug": {
			"straight_punch": {
				"left": {
					"state": "triggered",
					"hand_tracking_enabled": false,
					"pose_tracking_valid": true,
					"tracking_state": "pose_tracked",
					"tracking_valid": true,
					"sample_source": "pose",
					"wrist_velocity": 0.42,
					"wrist_forward_velocity": 0.09,
					"bbox_area_growth": 0.0,
					"grace_ms_remaining": 160,
				}
			},
			"hook": {
				"left": {
					"state": "ready",
					"horizontal_direction_velocity": 0.31,
					"directionality_ratio": 0.82,
				}
			},
			"uppercut": {
				"left": {
					"state": "tracking_lost",
					"upward_velocity": 0.00,
					"directionality_ratio": 0.00,
				}
			}
		}
	})

	var line: String = String(harness._build_hand_debug_line("left", {"hands": {"left": {}}}))
	assert_string_contains(line, "L: state=triggered")
	assert_string_contains(line, "tracking=pose_tracked")
	assert_string_contains(line, "valid=true")
	assert_string_contains(line, "source=pose")
	assert_string_contains(line, "bbox_area=0.000")
	assert_string_contains(line, "hook=ready/0.310 dir=0.820")
	assert_string_contains(line, "uppercut=tracking_lost/0.000 dir=0.000")


func test_boxing_event_feed_text_lists_hook_uppercut_and_guard_tuning_sections() -> void:
	var harness = _new_harness()
	harness.set("_latest_state", {
		"gesture_debug": {
			"guard": {
				"candidate": true,
				"wrist_separation_x": 0.180,
				"wrist_separation_y": 0.020,
				"left_wrist_above_elbow": true,
				"right_wrist_above_elbow": true,
			}
		}
	})
	var text_body := String(harness._build_boxing_event_feed_text())
	assert_string_contains(text_body, "Hook tuning")
	assert_string_contains(text_body, "Min velocity")
	assert_string_contains(text_body, "Min lateral dominance")
	assert_string_contains(text_body, "Min horizontal direction share of total motion")
	assert_string_contains(text_body, "Uppercut tuning")
	assert_string_contains(text_body, "Min vertical dominance")
	assert_string_contains(text_body, "Min upward direction share of total motion")
	assert_string_contains(text_body, "Guard tuning")
	assert_string_contains(text_body, "Wrist separation X <= 0.200")
	assert_string_contains(text_body, "Wrist separation Y <= 0.120")
	assert_string_contains(text_body, "Guard candidate: true")
	assert_string_contains(text_body, "Live wrist separation: x=0.180 y=0.020")

func test_hook_hover_card_reports_simplified_pose_trigger_contract() -> void:
	var harness = _new_harness()
	harness.set("_latest_state", {
		"gesture_debug": {
			"hook": {
				"left": {
					"state": "not_ready",
					"previous_state": "triggered",
					"timestamp_ms": Time.get_ticks_msec() - 260,
					"pose_tracking_valid": true,
					"tracking_state": "pose_tracked",
					"sample_source": "pose",
					"window_ms": 120,
					"window_span_ms": 118,
					"wrist_velocity": 0.420,
					"min_velocity": 0.080,
					"dominance_ratio": 0.740,
					"min_lateral_dominance_ratio": 0.500,
					"directionality_ratio": 0.830,
					"min_horizontal_direction_ratio": 0.550,
					"required_direction_label": "rightward",
					"direction_reference_frame": "preview_space_horizontal",
					"grace_ms_remaining": 0,
					"triggered_grace_ms": 240,
					"pose_only_rearm_ms": 250,
					"reacquire_stable_ms_required": 40,
				}
			}
		}
	})

	var model: Dictionary = harness._build_hover_card_model("hook_left")
	var rows: Array = model.get("rows", [])
	assert_eq(String(rows[2].get("current_text", "")), "pose_valid=true, tracking=pose_tracked, source=pose")
	assert_eq(String(rows[4].get("current_text", "")), "120ms configured, 118ms averaged span")
	assert_eq(String(rows[5].get("threshold_text", "")), "0.080")
	assert_eq(String(rows[5].get("current_text", "")), "0.420")
	assert_eq(String(rows[6].get("threshold_text", "")), "0.500")
	assert_eq(String(rows[6].get("current_text", "")), "0.740")
	assert_eq(String(rows[7].get("label", "")), "Preview-space Rightward share of total motion >= {threshold}")
	assert_eq(String(rows[7].get("threshold_text", "")), "0.550")
	assert_eq(String(rows[7].get("current_text", "")), "0.830")
	assert_string_contains(String(rows[10].get("current_text", "")), "elapsed (pose-only timer)")
	assert_eq(String(rows[11].get("current_text", "")), "tracked / 40ms required")

	var inspector: Dictionary = harness._build_custom_inspector_model("gesture", "hook_left")
	var body := String(inspector.get("body", ""))
	assert_string_contains(body, "Motion window - 120ms configured, 118ms averaged span")
	assert_string_contains(body, "Averaged velocity >= 0.080 - 0.420")
	assert_string_contains(body, "Dominance ratio >= 0.500 - 0.740")
	assert_string_contains(body, "Preview-space Rightward share of total motion >= 0.550 - 0.830")
	assert_string_contains(body, "Pose-only rearm - ")

func test_boxing_pose_only_punch_hover_card_and_inspector_report_skipped_hand_inputs_truthfully() -> void:
	var harness = _new_harness()
	harness.set("_latest_state", {
		"gesture_debug": {
			"straight_punch": {
				"left": {
					"state": "not_ready",
					"previous_state": "triggered",
					"timestamp_ms": Time.get_ticks_msec() - 260,
					"hand_tracking_enabled": false,
					"pose_tracking_valid": true,
					"tracking_state": "pose_tracked",
					"tracking_valid": true,
					"sample_source": "pose",
					"fresh_sample": true,
					"wrist_velocity": 0.420,
					"wrist_forward_velocity": 0.150,
					"forward_depth_spike": 0.090,
					"recent_peak_forward_depth_spike": 0.120,
					"min_velocity": 0.180,
					"elbow_shoulder_xy_distance": 0.082,
					"max_elbow_shoulder_xy_distance": 0.090,
					"elbow_shoulder_xy_gate_passed": true,
					"bbox_area": 0.0,
					"bbox_area_growth": 0.0,
					"min_bbox_area_growth": 0.010,
					"positive_growth_samples": 0,
					"min_positive_growth_samples": 3,
					"sample_window_size": 4,
					"growth_window_areas": [],
					"grace_ms_remaining": 0,
					"triggered_grace_ms": 240,
					"trigger_bbox_area": 0.0,
					"bbox_area_retract_epsilon": 0.003,
					"pose_only_rearm_ms": 250,
					"reacquire_stable_ms_required": 40,
				}
			}
		}
	})

	var model: Dictionary = harness._build_hover_card_model("punch_left")
	var rows: Array = model.get("rows", [])
	assert_eq(String(rows[2].get("current_text", "")), "pose-only fallback, pose_valid=true, tracking=pose_tracked, source=pose")
	assert_eq(String(rows[8].get("threshold_text", "")), "0.090")
	assert_eq(String(rows[8].get("current_text", "")), "0.082")
	assert_eq(String(rows[9].get("current_text", "")), "pose-only fallback (bbox skipped)")

	var inspector: Dictionary = harness._build_custom_inspector_model("gesture", "punch_left")
	var body := String(inspector.get("body", ""))
	assert_string_contains(body, "Hand tracking - pose-only fallback, pose_valid=true, tracking=pose_tracked, source=pose")
	assert_false(body.contains("Recent forward depth spike"))
	assert_string_contains(body, "Elbow-shoulder XY distance <= 0.090 - 0.082")
	assert_string_contains(body, "BBox area - pose-only fallback (bbox skipped)")
	assert_string_contains(body, "Recent bbox area growth peak >= skipped - pose-only fallback")
	assert_string_contains(body, "Positive growth samples >= skipped - pose-only fallback")
	assert_string_contains(body, "BBox retracted enough to rearm - ")
	assert_string_contains(body, "pose-only timer")

func test_guard_hover_card_reports_pose_only_thresholds_and_live_truth() -> void:
	var harness = _new_harness()
	harness.set("_latest_state", {
		"gesture_debug": {
			"guard": {
				"state": true,
				"candidate": true,
				"max_wrist_separation_x": 0.20,
				"max_wrist_separation_y": 0.12,
				"wrist_separation_x": 0.18,
				"wrist_separation_y": 0.02,
				"wrists_close_x": true,
				"wrists_close_y": true,
				"left_wrist_above_elbow": true,
				"right_wrist_above_elbow": true,
			}
		}
	})

	var model: Dictionary = harness._build_hover_card_model("guard")
	var rows: Array = model.get("rows", [])
	assert_eq(String(model.get("title", "")), "Guard")
	assert_eq(String(rows[1].get("current_text", "")), "active")
	assert_eq(String(rows[2].get("current_text", "")), "true")
	assert_eq(String(rows[4].get("threshold_text", "")), "0.200")
	assert_eq(String(rows[4].get("current_text", "")), "0.180")
	assert_eq(String(rows[5].get("threshold_text", "")), "0.120")
	assert_eq(String(rows[5].get("current_text", "")), "0.020")
	assert_eq(String(rows[6].get("current_text", "")), "true")
	assert_eq(String(rows[7].get("current_text", "")), "true")

	var inspector: Dictionary = harness._build_custom_inspector_model("gesture", "guard")
	var body := String(inspector.get("body", ""))
	assert_string_contains(body, "Current state - active")
	assert_string_contains(body, "Guard candidate - true")
	assert_string_contains(body, "Wrist separation X <= 0.200 - 0.180")
	assert_string_contains(body, "Wrist separation Y <= 0.120 - 0.020")
	assert_string_contains(body, "Left wrist above left elbow - true")
	assert_string_contains(body, "Right wrist above right elbow - true")

func test_boxing_squat_hover_card_reports_yaml_thresholds_and_live_truth() -> void:
	var harness = _new_harness()
	harness.set("_latest_state", {
		"gesture_debug": {
			"squat": {
				"state": true,
				"enabled": true,
				"enter_height_ratio_max": 0.82,
				"exit_height_ratio_min": 0.92,
				"height_ratio": 0.78,
				"height_state": "lowered",
				"squat_depth": 0.22,
				"torso_height": 0.234,
				"baseline_torso_height": 0.300,
				"calibration_ready": true,
				"calibration_sample_frames": 5,
			}
		}
	})

	var model: Dictionary = harness._build_hover_card_model("squat")
	var rows: Array = model.get("rows", [])
	assert_eq(String(model.get("title", "")), "Squat")
	assert_eq(String(rows[1].get("current_text", "")), "active")
	assert_eq(String(rows[2].get("current_text", "")), "true")
	assert_eq(String(rows[5].get("threshold_text", "")), "0.820")
	assert_eq(String(rows[5].get("current_text", "")), "0.780")
	assert_eq(String(rows[6].get("threshold_text", "")), "0.920")
	assert_eq(String(rows[8].get("current_text", "")), "0.780")
	assert_eq(String(rows[9].get("current_text", "")), "0.220")
	assert_eq(String(rows[10].get("current_text", "")), "lowered")
	assert_eq(String(rows[11].get("current_text", "")), "0.234 / 0.300")

	var inspector: Dictionary = harness._build_custom_inspector_model("gesture", "squat")
	var body := String(inspector.get("body", ""))
	assert_string_contains(body, "Current state - active")
	assert_string_contains(body, "Calibration ready - true")
	assert_string_contains(body, "Squat enter height ratio <= 0.820 - 0.780")
	assert_string_contains(body, "Squat exit height ratio >= 0.920 - 0.780")
	assert_string_contains(body, "Live torso / calibrated torso - 0.780")
	assert_string_contains(body, "Torso height (live / baseline) - 0.234 / 0.300")

func test_boxing_weave_hover_card_reports_yaml_thresholds_and_live_truth() -> void:
	var harness = _new_harness()
	harness.set("_latest_state", {
		"gesture_debug": {
			"weave": {
				"state": "left",
				"enabled": true,
				"enter_head_lateral_offset_min": 0.30,
				"enter_relative_head_hip_offset_min": 0.12,
				"enter_head_drop_ratio_min": 0.05,
				"exit_head_lateral_offset_max": 0.12,
				"exit_relative_head_hip_offset_max": 0.08,
				"head_lateral_offset": 0.31,
				"hip_lateral_offset": 0.04,
				"relative_head_hip_offset": 0.27,
				"head_drop_ratio": 0.06,
				"left_candidate": true,
				"right_candidate": false,
				"neutral_candidate": false,
				"head_offset_left_ready": true,
				"head_offset_right_ready": false,
				"relative_offset_left_ready": true,
				"relative_offset_right_ready": false,
				"head_drop_ready": true,
			}
		}
	})

	var model: Dictionary = harness._build_hover_card_model("weave")
	var rows: Array = model.get("rows", [])
	assert_eq(String(model.get("title", "")), "Weave")
	assert_eq(String(rows[1].get("current_text", "")), "left")
	assert_eq(String(rows[2].get("current_text", "")), "true")
	assert_eq(String(rows[3].get("current_text", "")), "false")
	assert_eq(String(rows[4].get("current_text", "")), "false")
	assert_eq(String(rows[6].get("threshold_text", "")), "0.300")
	assert_eq(String(rows[6].get("current_text", "")), "0.310")
	assert_eq(String(rows[7].get("threshold_text", "")), "0.120")
	assert_eq(String(rows[7].get("current_text", "")), "0.270")
	assert_eq(String(rows[8].get("threshold_text", "")), "0.050")
	assert_eq(String(rows[8].get("current_text", "")), "0.060")
	assert_eq(String(rows[9].get("threshold_text", "")), "0.120")
	assert_eq(String(rows[10].get("threshold_text", "")), "0.080")
	assert_eq(String(rows[12].get("current_text", "")), "0.310")
	assert_eq(String(rows[13].get("current_text", "")), "0.040")
	assert_eq(String(rows[14].get("current_text", "")), "0.270")
	assert_eq(String(rows[15].get("current_text", "")), "0.060")

	var inspector: Dictionary = harness._build_custom_inspector_model("gesture", "weave")
	var body := String(inspector.get("body", ""))
	assert_string_contains(body, "Current state - left")
	assert_string_contains(body, "Left weave candidate - true")
	assert_string_contains(body, "Right weave candidate - false")
	assert_string_contains(body, "Head lateral offset magnitude >= 0.300 - 0.310")
	assert_string_contains(body, "Head-vs-hip offset magnitude >= 0.120 - 0.270")
	assert_string_contains(body, "Head drop ratio >= 0.050 - 0.060")
	assert_string_contains(body, "Head lateral offset - 0.310")
	assert_string_contains(body, "Head-vs-hip lateral offset - 0.270")

func test_proving_scenes_surface_recalibrate_button_and_route_press_to_provider() -> void:
	for packed_scene_variant: Variant in [BoxingProvingScene, FlowProvingScene]:
		var packed_scene := packed_scene_variant as PackedScene
		var scene_root: Control = add_child_autoqfree(packed_scene.instantiate()) as Control
		assert_not_null(scene_root)
		var button := scene_root.find_child("AthleteRecalibrateButton", true, false) as Button
		assert_not_null(button)
		assert_eq(button.text, "Recalibrate Athlete")
		var provider := FakeAthleteRecalibrateProvider.new()
		harness_set_provider(scene_root, provider)
		button.emit_signal("pressed")
		assert_eq(provider.request_count, 1)

func harness_set_provider(scene_root: Control, provider: Node) -> void:
	scene_root.set("provider", provider)

func test_boxing_pose_only_punch_event_still_activates_left_tile_badge() -> void:
	var scene_root: Control = add_child_autoqfree(BoxingProvingScene.instantiate()) as Control
	var harness := scene_root as Object
	harness.set("_latest_state", {
		"gesture_debug": {
			"straight_punch": {
				"left": {
					"state": "triggered",
					"hand_tracking_enabled": false,
					"pose_tracking_valid": true,
					"tracking_state": "pose_tracked",
					"tracking_valid": true,
					"sample_source": "pose",
					"wrist_velocity": 0.42,
					"min_velocity": 0.18,
					"bbox_area": 0.0,
					"bbox_area_growth": 0.0,
					"pose_only_rearm_ms": 250,
				}
			}
		}
	})
	harness._on_straight_punch_state_changed("left", "triggered", {
		"state": "triggered",
		"previous_state": "ready",
		"tracking_state": "pose_tracked",
		"tracking_valid": true,
		"sample_source": "pose",
		"wrist_velocity": 0.42,
		"bbox_area": 0.0,
		"bbox_area_growth": 0.0,
	})
	harness._record_event("punch_left", {"power": 0.75})
	harness._update_tile_states()
	var punch_tile: Dictionary = harness.get("_tile_refs").get("punch", {})
	var left_badge: Dictionary = punch_tile.get("left", {})
	assert_eq(String(left_badge.get("style_key", "")), "active")
	assert_eq(harness._event_count("punch_left"), 1)

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
					"stale_ms": 0,
					"grace_frames": 0,
					"grace_ms": 0,
					"stable_ms": 160,
					"fresh_sample": true,
					"wrist_velocity": 0.310,
					"wrist_forward_velocity": 0.120,
					"forward_depth_spike": 0.080,
					"recent_peak_forward_depth_spike": 0.110,
					"min_velocity": 0.180,
					"bbox_area": 0.071,
					"bbox_area_growth": 0.012,
					"min_bbox_area_growth": 0.010,
					"positive_growth_samples": 3,
					"min_positive_growth_samples": 3,
					"sample_window_size": 4,
					"growth_window_areas": [0.020, 0.038, 0.055, 0.071],
					"grace_ms_remaining": 160,
					"triggered_grace_ms": 240,
					"trigger_bbox_area": 0.071,
					"bbox_area_retract_epsilon": 0.003,
					"reacquire_stable_ms_required": 40,
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
			"stale_ms": 0,
			"grace_frames": 0,
			"grace_ms": 0,
			"stable_ms": 160,
			"fresh_sample": true,
			"wrist_velocity": 0.310,
			"bbox_area": 0.071,
			"bbox_area_growth": 0.012,
			"grace_ms_remaining": 160,
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
					"stale_ms": 0,
					"grace_frames": 0,
					"grace_ms": 0,
					"stable_ms": 160,
					"fresh_sample": false,
					"wrist_velocity": 0.0,
					"min_velocity": 0.180,
					"bbox_area": 0.071,
					"bbox_area_growth": 0.0,
					"min_bbox_area_growth": 0.010,
					"positive_growth_samples": 0,
					"min_positive_growth_samples": 3,
					"sample_window_size": 4,
					"growth_window_areas": [0.071],
					"grace_ms_remaining": 0,
					"triggered_grace_ms": 240,
					"trigger_bbox_area": 0.071,
					"bbox_area_retract_epsilon": 0.003,
					"reacquire_stable_ms_required": 40,
				}
			}
		}
	})
	var still_frozen: Dictionary = harness._resolve_shared_inspector_model(true)
	var still_frozen_body := String(still_frozen.get("body", ""))

	assert_eq(still_frozen_body, frozen_body)
	assert_string_contains(still_frozen_body, "Latest state change - ready -> triggered")
	assert_string_contains(still_frozen_body, "Recent punch velocity peak >= 0.180 - 0.310")
	assert_false(still_frozen_body.contains("Recent forward depth spike"))
	assert_string_contains(still_frozen_body, "Recent bbox area growth peak >= 0.010 - 0.012")
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
			"sample_source": "fresh_inference",
			"tracking_valid": true,
			"stale_frames": 0,
			"stale_ms": 0,
			"grace_frames": 0,
			"grace_ms": 0,
			"stable_ms": 160,
			"fresh_sample": true,
			"wrist_velocity": 0.280,
			"forward_depth_spike": 0.100,
			"recent_peak_forward_depth_spike": 0.120,
			"elbow_shoulder_xy_distance": 0.082,
			"max_elbow_shoulder_xy_distance": 0.090,
			"elbow_shoulder_xy_gate_passed": true,
			"bbox_area": 0.064,
			"bbox_area_growth": 0.011,
			"grace_ms_remaining": 240,
		},
		"right": {},
	})

	var model: Dictionary = harness._build_hover_card_model("punch_left")
	var rows: Array = model.get("rows", [])
	assert_string_contains(String(rows[1].get("current_text", "")), "triggered")
	assert_string_contains(String(rows[4].get("current_text", "")), "ready -> triggered")
	assert_eq(String(rows[5].get("current_text", "")), "state=triggered wrist=0.280 depth=0.120 xy=0.082<=0.090 (true) bbox=0.064 growth=0.011 fresh=true source=fresh_inference grace=240ms valid=true")
