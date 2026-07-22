extends "res://addons/aerobeat-vendor-godot-unit-test/test.gd"

const LandmarkDrawerScript = preload("res://scripts/landmark_drawer.gd")
const DepthDebugViewerScript = preload("res://scripts/depth_debug_viewer.gd")
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
		size = Vector2(520.0, 293.0)
		overlay_layer = Control.new()
		overlay_layer.name = "OverlayLayer"
		overlay_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		add_child(overlay_layer)

	func get_overlay_layer() -> Control:
		return overlay_layer

	func get_hand_debug_snapshot() -> Dictionary:
		return hand_snapshot.duplicate(true)

	func get_content_rect() -> Rect2:
		return Rect2(Vector2.ZERO, size)

	func map_landmark_to_preview_position(point: Dictionary) -> Vector2:
		return Vector2(float(point.get("x", 0.0)) * size.x, float(point.get("y", 0.0)) * size.y)

class PlaybackStateHarness:
	extends ProvingHarnessScript

	var state := {"media_loaded": true}

	func _get_playback_controller_state() -> Dictionary:
		return state

	func _is_prerecorded_source_active() -> bool:
		return true

class LiveCalibrationHarness:
	extends ProvingHarnessScript

	func _is_prerecorded_source_active() -> bool:
		return false

	func _get_effective_camera_source() -> String:
		return "/dev/video0"

class FakeAthleteRecalibrateProvider:
	extends Node

	var request_count := 0
	var cancel_count := 0
	var calibration_session := _make_session("idle")
	var baseline := {"is_calibrated": false, "sample_frames": 0}

	func start_athlete_calibration() -> bool:
		request_count += 1
		baseline = {"is_calibrated": false, "sample_frames": 0}
		calibration_session = _make_session("countdown", {"is_active": true, "seconds_remaining": 5})
		return true

	func request_athlete_recalibration() -> bool:
		return start_athlete_calibration()

	func cancel_athlete_calibration() -> bool:
		cancel_count += 1
		calibration_session = _make_session("cancelled", {"result": "cancelled", "failure_reason": "cancelled"})
		return true

	func get_calibration_session() -> Dictionary:
		return calibration_session.duplicate(true)

	func get_detector_state() -> Dictionary:
		return {
			"baseline": baseline.duplicate(true),
			"calibration_session": calibration_session.duplicate(true),
		}

	func _make_session(state_name: String, overrides: Dictionary = {}) -> Dictionary:
		var session := {
			"state": state_name,
			"is_active": state_name == "countdown" or state_name == "capture_pending" or state_name == "capturing",
			"result": state_name,
			"seconds_remaining": 0,
			"captured_sample_frames": 0,
			"required_capture_frames": 5,
			"failure_reason": "",
			"readiness": {
				"centered_in_camera": false,
				"t_pose_ready": false,
			},
			"instructions": {
				"stand_centered": {"text": "Stand centered in camera", "ready": false},
				"hold_t_pose": {"text": "Hold a T-pose", "ready": false},
			},
		}
		for key: Variant in overrides.keys():
			session[key] = overrides[key]
		return session

class AllDepthDisabledHarness:
	extends "res://scripts/boxing_proving_harness.gd"

	func _punch_depth_profile_config(_family: String) -> Dictionary:
		return {"enabled": false}

func _new_harness() -> Variant:
	var harness_script: Script = load("res://scripts/boxing_proving_harness.gd") as Script
	return add_child_autoqfree(harness_script.new())

func _new_base_harness() -> Variant:
	return add_child_autoqfree(ProvingHarnessScript.new())

func _new_depth_disabled_harness() -> Variant:
	return add_child_autoqfree(AllDepthDisabledHarness.new())

func _new_playback_harness() -> Variant:
	return add_child_autoqfree(PlaybackStateHarness.new())

func _new_live_calibration_harness() -> Variant:
	return add_child_autoqfree(LiveCalibrationHarness.new())

func _depth_runtime_debug_payload(summary: String, artifact_path: String, backend_id: String, family_id: String, runtime_status: String, runtime_stage: String, failure_code: String = "", failure_message: String = "") -> Dictionary:
	return {
		"active_model_summary": summary,
		"artifact_path_res": artifact_path,
		"backend_id": backend_id,
		"family_id": family_id,
		"runtime_status": runtime_status,
		"runtime_stage": runtime_stage,
		"failure_code": failure_code,
		"failure_message": failure_message,
	}

func _depth_live_debug_payload(closeness: float, delta: float, peak: float, sample_source: String = "placeholder") -> Dictionary:
	return {
		"depth_signal_available": true,
		"depth_signal_fresh": true,
		"depth_signal_source": sample_source,
		"last_depth_closeness": closeness,
		"depth_closeness_delta": delta,
		"depth_peak_closeness": peak,
		"depth_early_closeness": closeness * 0.5,
		"depth_late_closeness": closeness,
		"depth_window_span_ms": 120,
		"depth_gate_applied": true,
		"depth_gate_passed": true,
		"depth_gate_reason": "passed",
		"depth_runtime_status": "ready",
		"depth_runtime_stage": "sampling",
		"depth_backend_id": "onnx",
		"depth_family_id": "depth_anything_v2_small_onnx",
		"depth_enabled": true,
		"depth_failure_code": "",
		"depth_failure_message": "",
		"depth_active_model_summary": "enabled; runtime ready via onnx backend",
		"depth_artifact_path": "res://assets/depth_models/depth_anything_v2/depth_anything_v2_vits.onnx",
		"depth_sample_metrics": {
			"wrist_closeness": closeness,
			"wrist_depth": maxf(0.0, 1.0 - closeness),
			"torso_depth": 1.0,
			"sample_source": sample_source,
			"sample_fresh": true,
		},
	}

func _depth_sample_geometry_payload() -> Dictionary:
	return {
		"sampling_mode": "single_point",
		"actual_geometry_kind": "single_pixel_point",
		"depth_map_space": "frame_resized_normalized_depth",
		"actual_samples": {
			"shoulder": {
				"depth": 0.61,
				"normalized_point": {"x": 0.42, "y": 0.34},
				"pixel": {"x": 268, "y": 122},
			},
			"wrist": {
				"depth": 0.31,
				"normalized_point": {"x": 0.56, "y": 0.64},
				"pixel": {"x": 358, "y": 230},
			},
		},
		"aggregation": {
			"fallback_used": false,
			"fallback_reason": "",
		},
	}

func _depth_region_aware_sample_geometry_payload() -> Dictionary:
	return {
		"sampling_mode": "region_aware",
		"actual_geometry_kind": "landmark_region",
		"depth_map_space": "frame_resized_normalized_depth",
		"actual_samples": {
			"shoulder": {
				"depth": 0.61,
				"normalized_point": {"x": 0.42, "y": 0.34},
				"pixel": {"x": 268, "y": 122},
			},
			"wrist": {
				"depth": 0.31,
				"normalized_point": {"x": 0.56, "y": 0.64},
				"pixel": {"x": 358, "y": 230},
			},
		},
		"region_anchors": {
			"shoulder": {
				"depth": 0.61,
				"normalized_point": {"x": 0.42, "y": 0.34},
				"pixel": {"x": 268, "y": 122},
			},
			"elbow": {
				"depth": 0.43,
				"normalized_point": {"x": 0.50, "y": 0.50},
				"pixel": {"x": 320, "y": 180},
			},
			"wrist": {
				"depth": 0.31,
				"normalized_point": {"x": 0.56, "y": 0.64},
				"pixel": {"x": 358, "y": 230},
			},
		},
		"actual_regions": {
			"wrist": {
				"shape": "extended_capsule",
				"anchor_pixel": {"x": 358, "y": 230},
				"elbow_pixel": {"x": 320, "y": 180},
				"extension_endpoint_pixel": {"x": 376, "y": 254},
				"radius_px": 12,
				"extension_toward_elbow_px": 8,
				"bounds_px": {"min_x": 308, "min_y": 168, "max_x": 388, "max_y": 266},
				"sampled_pixel_count": 46,
				"valid_pixel_count": 3,
			},
			"torso": {
				"shape": "center_box",
				"anchor_pixel": {"x": 268, "y": 122},
				"torso_anchor": "shoulder_landmark",
				"half_width_px": 18,
				"half_height_px": 18,
				"bounds_px": {"min_x": 250, "min_y": 104, "max_x": 286, "max_y": 140},
				"sampled_pixel_count": 36,
				"valid_pixel_count": 36,
			},
		},
		"aggregation": {
			"fallback_used": true,
			"fallback_reason": "center_point_due_to_sparse_region",
			"applied": {
				"wrist": {
					"stat_applied": "center_point",
					"sample_count": 46,
					"valid_sample_count": 3,
					"fallback_used": true,
					"fallback_reason": "center_point_due_to_sparse_region",
				},
				"torso": {
					"stat_applied": "median",
					"sample_count": 36,
					"valid_sample_count": 36,
					"fallback_used": false,
					"fallback_reason": "",
				},
			},
		},
	}

func _depth_runtime_visual_state(texture: Variant = null, sample_geometry: Dictionary = {}) -> Dictionary:
	var resolved_sample_geometry := sample_geometry if not sample_geometry.is_empty() else _depth_sample_geometry_payload()
	return {
		"depth_enabled": true,
		"runtime_status": "ready",
		"runtime_stage": "sampling",
		"backend_id": "onnx",
		"family_id": "depth_anything_v2_small_onnx",
		"active_model_summary": "enabled; runtime ready via onnx backend",
		"artifact_path_res": "res://assets/depth_models/depth_anything_v2/depth_anything_v2_vits.onnx",
		"frame_size": Vector2i(640, 360),
		"depth_map_size": Vector2i(640, 360),
		"normalized_depth_map": texture,
		"sample_every_n_frames": 3,
		"max_sample_age_ms": 250,
		"last_sample_timestamp_ms": 123456,
		"last_sample_age_ms": 18,
		"last_timing_ms": {
			"preprocess": 1.0,
			"infer": 2.5,
			"postprocess": 1.2,
			"total": 4.7,
		},
		"last_sample_metrics": {
			"sample_source": "fresh_inference",
			"sample_fresh": true,
			"wrist_closeness": 0.30,
			"wrist_depth": 0.31,
			"torso_depth": 0.61,
			"sample_geometry": resolved_sample_geometry.duplicate(true),
		},
	}

func _depth_debug_viewer_snapshot(texture: Variant = null, sample_geometry: Dictionary = {}) -> Dictionary:
	var resolved_sample_geometry := sample_geometry if not sample_geometry.is_empty() else _depth_sample_geometry_payload()
	return {
		"family": "straight_punch",
		"preview_texture": _make_test_texture(Color(0.18, 0.34, 0.72, 1.0)),
		"depth_texture": texture,
		"runtime_status": "ready",
		"runtime_stage": "sampling",
		"active_model_summary": "enabled; runtime ready via onnx backend",
		"failure_code": "",
		"failure_message": "",
		"frame_size": Vector2i(640, 360),
		"depth_map_size": Vector2i(640, 360),
		"timing_ms": {
			"preprocess": 1.0,
			"infer": 2.5,
			"postprocess": 1.2,
			"total": 4.7,
		},
		"sample_every_n_frames": 3,
		"max_sample_age_ms": 250,
		"last_sample_age_ms": 18,
		"sample_metrics": {
			"sample_source": "fresh_inference",
			"sample_fresh": true,
			"wrist_closeness": 0.30,
			"wrist_depth": 0.31,
			"torso_depth": 0.61,
		},
		"sample_geometry": resolved_sample_geometry.duplicate(true),
	}

func _make_test_texture(color: Color = Color(0.7, 0.7, 0.7, 1.0)) -> Texture2D:
	var image := Image.create(4, 4, false, Image.FORMAT_RGBA8)
	image.fill(color)
	return ImageTexture.create_from_image(image)

func _boxing_depth_debug_viewer(harness: Object) -> Object:
	var viewer := harness.get("_depth_debug_viewer") as Object
	assert_not_null(viewer)
	return viewer

func _boxing_depth_debug_refs(harness: Object) -> Dictionary:
	var viewer := _boxing_depth_debug_viewer(harness)
	assert_true(viewer.has_method("get_node_refs"))
	return viewer.get_node_refs()

func _boxing_depth_debug_state(harness: Object) -> Dictionary:
	var viewer := _boxing_depth_debug_viewer(harness)
	assert_true(viewer.has_method("get_state_snapshot"))
	return viewer.get_state_snapshot()

func _enable_boxing_depth_debug(harness: Variant) -> void:
	harness.set("_depth_debug_visual_config", {
		"enabled": true,
		"thumbnail_visible": true,
		"swap_click_enabled": true,
		"hover_hint_visible": true,
		"sampling_regions_visible": true,
		"fps_visible": true,
		"request_runtime_texture": true,
		"thumbnail_corner": "bottom_right",
		"thumbnail_width_px": 196,
		"thumbnail_margin_px": 14,
	})

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
	assert_null(scene_root.find_child("TrackerConfigPath", true, false))
	assert_null(scene_root.find_child("GestureConfigPath", true, false))

func test_boxing_proving_scene_applies_boxing_testbed_debug_yaml_to_live_nodes() -> void:
	var scene_root: Control = add_child_autoqfree(BoxingProvingScene.instantiate()) as Control
	assert_not_null(scene_root)
	var harness := scene_root as Object
	var landmark_drawer := scene_root.find_child("LandmarkDrawer", true, false) as Control
	assert_not_null(landmark_drawer)
	assert_null(scene_root.find_child("TrailDrawer", true, false))
	assert_null(scene_root.find_child("HandBBoxDrawer", true, false))
	assert_eq(int(harness.get("debug_panel_refresh_interval_ms")), 160)
	assert_eq(int(harness.get("inspector_live_refresh_interval_ms")), 120)
	assert_true(bool(harness.get("show_landmarks")))
	assert_false(bool(landmark_drawer.get("show_debug_hit_targets")))
	assert_false(bool(landmark_drawer.get("show_debug_hit_target_labels")))
	var depth_debug_visuals: Dictionary = harness.get("_depth_debug_visual_config")
	assert_false(bool(depth_debug_visuals.get("enabled", false)))
	assert_false(bool(depth_debug_visuals.get("thumbnail_visible", false)))
	assert_false(bool(depth_debug_visuals.get("request_runtime_texture", false)))
	assert_false(bool(depth_debug_visuals.get("sampling_regions_visible", false)))
	assert_false(bool(depth_debug_visuals.get("fps_visible", false)))
	assert_null(scene_root.find_child("DepthDebugRoot", true, false))

func test_depth_debug_viewer_renders_prepared_snapshot_and_reparents_to_presenter_overlay() -> void:
	var presenter: FakePreviewPresenter = add_child_autoqfree(FakePreviewPresenter.new()) as FakePreviewPresenter
	var viewer: Variant = add_child_autoqfree(DepthDebugViewerScript.new())
	viewer.configure({
		"enabled": true,
		"thumbnail_visible": true,
		"swap_click_enabled": true,
		"hover_hint_visible": true,
		"sampling_regions_visible": true,
		"fps_visible": true,
		"thumbnail_corner": "bottom_right",
		"thumbnail_width_px": 196,
		"thumbnail_margin_px": 14,
	}, _depth_debug_viewer_snapshot(), 59.4, presenter)
	var refs: Dictionary = viewer.get_node_refs()
	assert_same(viewer.get_parent(), presenter.get_overlay_layer())
	assert_not_null(refs.get("thumbnail_panel", null))
	assert_true(bool((refs.get("thumbnail_panel", null) as PanelContainer).visible))
	assert_true(bool((refs.get("sample_overlay", null) as Control).visible))
	assert_eq(String((refs.get("fps_label", null) as Label).text), "Preview 59.4 FPS")
	var placeholder: Label = refs.get("thumbnail_placeholder_label", null) as Label
	var status: Label = refs.get("thumbnail_status_label", null) as Label
	assert_not_null(placeholder)
	assert_not_null(status)
	assert_true(placeholder.visible)
	assert_eq(String(placeholder.text), "✕")
	assert_false(status.visible)
	assert_string_contains(String((refs.get("thumbnail_panel", null) as PanelContainer).tooltip_text), "texture=false")
	var markers: Array = ((refs.get("sample_overlay", null) as Object).get_marker_snapshot() as Array)
	assert_eq(markers.size(), 2)

func test_depth_debug_viewer_uses_runtime_reported_point_samples_for_single_point_mode() -> void:
	var presenter: FakePreviewPresenter = add_child_autoqfree(FakePreviewPresenter.new()) as FakePreviewPresenter
	var viewer: Variant = add_child_autoqfree(DepthDebugViewerScript.new())
	viewer.configure({
		"enabled": true,
		"thumbnail_visible": true,
		"swap_click_enabled": true,
		"hover_hint_visible": true,
		"sampling_regions_visible": true,
		"fps_visible": true,
	}, _depth_debug_viewer_snapshot(null, _depth_sample_geometry_payload()), 59.4, presenter)
	var sample_overlay: Object = viewer.get_node_refs().get("sample_overlay", null) as Object
	assert_not_null(sample_overlay)
	var overlay_snapshot: Dictionary = sample_overlay.get_overlay_snapshot()
	assert_eq(String(overlay_snapshot.get("sampling_mode", "")), "single_point")
	assert_eq((overlay_snapshot.get("markers", []) as Array).size(), 2)
	assert_eq((overlay_snapshot.get("regions", []) as Array).size(), 0)
	var marker_names: Array[String] = []
	for marker_variant: Variant in overlay_snapshot.get("markers", []):
		var marker: Dictionary = marker_variant as Dictionary
		marker_names.append(String(marker.get("name", "")))
	assert_true(marker_names.has("shoulder"))
	assert_true(marker_names.has("wrist"))

func test_depth_debug_viewer_uses_runtime_region_metadata_for_region_aware_mode() -> void:
	var presenter: FakePreviewPresenter = add_child_autoqfree(FakePreviewPresenter.new()) as FakePreviewPresenter
	var viewer: Variant = add_child_autoqfree(DepthDebugViewerScript.new())
	viewer.configure({
		"enabled": true,
		"thumbnail_visible": true,
		"swap_click_enabled": true,
		"hover_hint_visible": true,
		"sampling_regions_visible": true,
		"fps_visible": true,
	}, _depth_debug_viewer_snapshot(null, _depth_region_aware_sample_geometry_payload()), 59.4, presenter)
	var sample_overlay: Object = viewer.get_node_refs().get("sample_overlay", null) as Object
	assert_not_null(sample_overlay)
	var overlay_snapshot: Dictionary = sample_overlay.get_overlay_snapshot()
	assert_eq(String(overlay_snapshot.get("sampling_mode", "")), "region_aware")
	assert_true(bool(overlay_snapshot.get("fallback_used", false)))
	assert_eq(String(overlay_snapshot.get("fallback_reason", "")), "center_point_due_to_sparse_region")
	var markers: Array = overlay_snapshot.get("markers", []) as Array
	assert_eq(markers.size(), 3)
	var marker_names: Array[String] = []
	for marker_variant: Variant in markers:
		var marker: Dictionary = marker_variant as Dictionary
		marker_names.append(String(marker.get("name", "")))
	assert_true(marker_names.has("shoulder"))
	assert_true(marker_names.has("elbow"))
	assert_true(marker_names.has("wrist"))
	var regions: Array = overlay_snapshot.get("regions", []) as Array
	assert_eq(regions.size(), 2)
	var wrist_region: Dictionary = regions[0] as Dictionary
	var torso_region: Dictionary = regions[1] as Dictionary
	assert_eq(String(wrist_region.get("name", "")), "wrist")
	assert_eq(String(wrist_region.get("shape", "")), "extended_capsule")
	assert_eq(int(wrist_region.get("sampled_pixel_count", 0)), 46)
	assert_eq(int(wrist_region.get("valid_pixel_count", 0)), 3)
	assert_eq(String(wrist_region.get("aggregation_label", "")), "center_point")
	assert_eq(String(wrist_region.get("fallback_label", "")), "fallback: center point due to sparse region")
	assert_eq(String(torso_region.get("name", "")), "torso")
	assert_eq(String(torso_region.get("shape", "")), "center_box")
	assert_eq(int(torso_region.get("sampled_pixel_count", 0)), 36)
	assert_eq(int(torso_region.get("valid_pixel_count", 0)), 36)
	assert_eq(String(torso_region.get("aggregation_label", "")), "median")
	assert_eq(String(torso_region.get("anchor_label", "")), "anchor: shoulder landmark")

func test_boxing_depth_debug_thumbnail_truthfully_reports_unavailable_depth_texture() -> void:
	var scene_root: Control = add_child_autoqfree(BoxingProvingScene.instantiate()) as Control
	var harness: Variant = scene_root
	var presenter: FakePreviewPresenter = add_child_autoqfree(FakePreviewPresenter.new()) as FakePreviewPresenter
	harness.set("_preview_presenter", presenter)
	harness.camera_view = TextureRect.new()
	harness.camera_view.texture = _make_test_texture(Color(0.18, 0.34, 0.72, 1.0))
	harness.set("_latest_state", {
		"gesture_debug": {
			"depth_runtime": {
				"straight_punch": _depth_runtime_visual_state(null),
			}
		}
	})
	harness._refresh_debug_panels()
	_enable_boxing_depth_debug(harness)
	harness._refresh_depth_debug_visuals()
	var refs := _boxing_depth_debug_refs(harness)
	var placeholder: Label = refs.get("thumbnail_placeholder_label", null) as Label
	var status: Label = refs.get("thumbnail_status_label", null) as Label
	var panel: PanelContainer = refs.get("thumbnail_panel", null) as PanelContainer
	var texture_rect: TextureRect = refs.get("thumbnail_texture", null) as TextureRect
	var sample_overlay: Variant = refs.get("sample_overlay", null)
	assert_not_null(placeholder)
	assert_not_null(status)
	assert_not_null(panel)
	assert_not_null(texture_rect)
	assert_not_null(sample_overlay)
	assert_true(placeholder.visible)
	assert_eq(String(placeholder.text), "✕")
	assert_false(status.visible)
	assert_true(panel.clip_contents)
	assert_eq(placeholder.custom_minimum_size, texture_rect.custom_minimum_size)
	assert_string_contains(String(placeholder.tooltip_text), "Depth texture unavailable")
	assert_string_contains(String(placeholder.tooltip_text), "texture=false")
	assert_true(sample_overlay.visible)
	var markers: Array = sample_overlay.get_marker_snapshot()
	assert_eq(markers.size(), 2)

func test_boxing_depth_debug_overlay_consumes_runtime_region_metadata_without_config_reconstruction() -> void:
	var scene_root: Control = add_child_autoqfree(BoxingProvingScene.instantiate()) as Control
	var harness: Variant = scene_root
	var presenter: FakePreviewPresenter = add_child_autoqfree(FakePreviewPresenter.new()) as FakePreviewPresenter
	harness.set("_preview_presenter", presenter)
	harness.camera_view = TextureRect.new()
	harness.camera_view.texture = _make_test_texture(Color(0.18, 0.34, 0.72, 1.0))
	harness.set("_latest_state", {
		"gesture_debug": {
			"depth_runtime": {
				"straight_punch": _depth_runtime_visual_state(null, _depth_region_aware_sample_geometry_payload()),
			}
		}
	})
	harness._refresh_debug_panels()
	_enable_boxing_depth_debug(harness)
	harness._refresh_depth_debug_visuals()
	var sample_overlay: Object = _boxing_depth_debug_refs(harness).get("sample_overlay", null) as Object
	assert_not_null(sample_overlay)
	var overlay_snapshot: Dictionary = sample_overlay.get_overlay_snapshot()
	assert_eq(String(overlay_snapshot.get("sampling_mode", "")), "region_aware")
	assert_eq((overlay_snapshot.get("regions", []) as Array).size(), 2)
	assert_eq((overlay_snapshot.get("markers", []) as Array).size(), 3)

func test_boxing_depth_debug_swap_uses_real_runtime_texture_when_available() -> void:
	var scene_root: Control = add_child_autoqfree(BoxingProvingScene.instantiate()) as Control
	var harness: Variant = scene_root
	var presenter: FakePreviewPresenter = add_child_autoqfree(FakePreviewPresenter.new()) as FakePreviewPresenter
	harness.set("_preview_presenter", presenter)
	var preview_texture := _make_test_texture(Color(0.22, 0.61, 0.38, 1.0))
	var depth_texture := _make_test_texture(Color(0.71, 0.71, 0.71, 1.0))
	harness.camera_view = TextureRect.new()
	harness.camera_view.texture = preview_texture
	harness.set("_latest_state", {
		"gesture_debug": {
			"depth_runtime": {
				"straight_punch": _depth_runtime_visual_state(depth_texture),
			}
		}
	})
	harness._refresh_debug_panels()
	_enable_boxing_depth_debug(harness)
	harness._refresh_depth_debug_visuals()
	var refs := _boxing_depth_debug_refs(harness)
	var main_texture: TextureRect = refs.get("main_texture", null) as TextureRect
	var thumbnail_texture: TextureRect = refs.get("thumbnail_texture", null) as TextureRect
	var hint_label: Label = refs.get("thumbnail_hint_label", null) as Label
	var thumbnail_panel: PanelContainer = refs.get("thumbnail_panel", null) as PanelContainer
	assert_not_null(thumbnail_panel)
	thumbnail_panel.emit_signal("mouse_entered")
	assert_not_null(main_texture)
	assert_not_null(thumbnail_texture)
	assert_not_null(hint_label)
	assert_false(main_texture.visible)
	assert_same(thumbnail_texture.texture, depth_texture)
	assert_true(hint_label.visible)
	harness._toggle_depth_debug_swap()
	assert_true(main_texture.visible)
	assert_same(main_texture.texture, depth_texture)
	assert_same(thumbnail_texture.texture, preview_texture)
	assert_string_contains(String(hint_label.text), "restore preview")

func test_boxing_depth_debug_swap_resets_when_yaml_disables_thumbnail_click_swap() -> void:
	var scene_root: Control = add_child_autoqfree(BoxingProvingScene.instantiate()) as Control
	var harness: Variant = scene_root
	var presenter: FakePreviewPresenter = add_child_autoqfree(FakePreviewPresenter.new()) as FakePreviewPresenter
	harness.set("_preview_presenter", presenter)
	harness.camera_view = TextureRect.new()
	harness.camera_view.texture = _make_test_texture(Color(0.22, 0.61, 0.38, 1.0))
	harness.set("_latest_state", {
		"gesture_debug": {
			"depth_runtime": {
				"straight_punch": _depth_runtime_visual_state(_make_test_texture(Color(0.71, 0.71, 0.71, 1.0))),
			}
		}
	})
	harness._refresh_debug_panels()
	_enable_boxing_depth_debug(harness)
	harness._refresh_depth_debug_visuals()
	harness._toggle_depth_debug_swap()
	assert_true(bool(_boxing_depth_debug_state(harness).get("swapped_to_depth", false)))
	harness._sync_depth_debug_visual_config({
		"depth_debug": {
			"enabled": true,
			"thumbnail_visible": true,
			"swap_click_enabled": false,
			"hover_hint_visible": true,
			"sampling_regions_visible": true,
			"fps_visible": true,
			"request_runtime_texture": true,
		}
	})
	var refs := _boxing_depth_debug_refs(harness)
	var main_texture: TextureRect = refs.get("main_texture", null) as TextureRect
	var hint_label: Label = refs.get("thumbnail_hint_label", null) as Label
	assert_false(bool(_boxing_depth_debug_state(harness).get("swapped_to_depth", false)))
	assert_not_null(main_texture)
	assert_false(main_texture.visible)
	assert_not_null(hint_label)
	assert_false(hint_label.visible)

func test_proving_harness_runtime_tuning_fields_are_hidden_from_editor_surface() -> void:
	var harness: Object = _new_base_harness()
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


func test_proving_runtime_config_uses_profile_yaml_pose_smoothing_over_hidden_scene_default() -> void:
	var harness: Variant = _new_base_harness()
	harness.set("harness_mode", int(ProvingHarnessScript.HarnessMode.BOXING))
	harness.set("tracking_smoothing_style", int(ProvingHarnessScript.TrackingSmoothingStyle.LITE_RAW))

	var config: Variant = harness._build_runtime_config()
	assert_not_null(config)
	var selected_style := String(config.get_selected_profile_bundle().get("camera_tracking", {}).get("tracking", {}).get("pose", {}).get("smoothing_style", "")).strip_edges().to_lower()
	assert_true(["lite_raw", "lite_filtered"].has(selected_style))
	var expects_filter_enabled := selected_style == "lite_filtered"
	assert_eq(bool(config.runtime.get("filter_enabled", false)), expects_filter_enabled)
	assert_eq(bool(config.runtime.get("no_filter", true)), not expects_filter_enabled)

func test_boxing_proving_runtime_config_no_longer_requests_depth_texture_from_testbed_yaml() -> void:
	var harness: Variant = _new_harness()
	var config: Variant = harness._build_runtime_config()
	assert_not_null(config)
	var depth_debug: Dictionary = config.runtime.get("depth_debug", {}) if config.runtime.get("depth_debug", {}) is Dictionary else {}
	assert_false(bool(depth_debug.get("request_runtime_texture", false)))

func test_flow_proving_runtime_config_does_not_request_depth_texture_without_yaml_flag() -> void:
	var harness: Variant = _new_base_harness()
	harness.set("harness_mode", int(ProvingHarnessScript.HarnessMode.FLOW))
	var config: Variant = harness._build_runtime_config()
	assert_not_null(config)
	var depth_debug: Dictionary = config.runtime.get("depth_debug", {}) if config.runtime.get("depth_debug", {}) is Dictionary else {}
	assert_false(bool(depth_debug.get("request_runtime_texture", false)))

func test_flow_proving_runtime_config_defaults_to_flow_profile_bundle() -> void:
	var harness: Variant = _new_base_harness()
	harness.set("harness_mode", int(ProvingHarnessScript.HarnessMode.FLOW))

	var config: Variant = harness._build_runtime_config()
	assert_not_null(config)
	assert_eq(String(config.get_selected_profile_id()), "flow")
	assert_eq(int(harness.get("debug_panel_refresh_interval_ms")), 160)
	assert_eq(int(harness.get("inspector_live_refresh_interval_ms")), 120)
	var bundle: Dictionary = config.get_selected_profile_bundle()
	assert_true(bool(bundle.get("ok", false)))
	assert_eq(String(bundle.get("profile", "")), "flow")

func test_boxing_proving_profile_visual_config_keeps_pose_landmark_debug_truthful() -> void:
	var harness: Variant = _new_harness()
	var landmark_drawer: Control = add_child_autoqfree(LandmarkDrawerScript.new())
	harness.set("landmark_drawer", landmark_drawer)

	harness.set("_selected_profile_id", "boxing")
	harness._sync_profile_visual_config()
	assert_eq(int(harness.get("debug_panel_refresh_interval_ms")), 160)
	assert_eq(int(harness.get("inspector_live_refresh_interval_ms")), 120)
	assert_true(bool(harness.get("show_landmarks")))
	assert_false(bool(landmark_drawer.get("show_debug_hit_targets")))
	assert_false(bool(landmark_drawer.get("show_debug_hit_target_labels")))

	harness.set("_selected_profile_id", "flow")
	harness._sync_profile_visual_config()
	assert_true(bool(harness.get("show_landmarks")))
	assert_false(bool(landmark_drawer.get("show_debug_hit_targets")))
	assert_false(bool(landmark_drawer.get("show_debug_hit_target_labels")))


func test_boxing_proving_hand_debug_line_surfaces_pose_threshold_metrics() -> void:
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
					"recent_peak_wrist_velocity": 0.46,
					"elbow_shoulder_xy_distance": 0.082,
					"max_elbow_shoulder_xy_distance": 0.090,
					"elbow_shoulder_xy_gate_passed": true,
					"wrist_lateral_angle_from_elbow_vertical_deg": 19.0,
					"min_wrist_lateral_angle_from_elbow_vertical_deg": 15.0,
					"wrist_lateral_angle_gate_passed": true,
					"pose_reference_shoulder_width": 0.31,
					"pose_reference_shoulder_width_source": "live",
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
	assert_string_contains(line, "peak_xyz_vel=0.460")
	assert_string_contains(line, "wrist_forward_vel=0.090")
	assert_string_contains(line, "depth_spike=0.140")
	assert_string_contains(line, "elbow_shoulder_xy=0.082<=0.090(true)")
	assert_string_contains(line, "wrist_angle=19.000>=15.000(true)")
	assert_string_contains(line, "shoulder_width=0.310(live)")
	assert_string_contains(line, "grace=160ms")
	assert_string_contains(line, "hand_grace=0ms")
	assert_string_contains(line, "hand_stable=80ms")
	assert_string_contains(line, "stale=0ms")

func test_boxing_punch_hover_card_uses_pose_threshold_state_machine_debug_fields() -> void:
	var harness = _new_harness()
	harness.set("_latest_state", {
		"gesture_debug": {
			"straight_punch": {
				"left": {
					"state": "not_ready",
					"pose_tracking_valid": true,
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
					"recent_peak_wrist_velocity": 0.455,
					"wrist_forward_velocity": 0.150,
					"forward_depth_spike": 0.090,
					"recent_peak_forward_depth_spike": 0.120,
					"min_velocity": 0.180,
					"elbow_shoulder_xy_distance": 0.082,
					"max_elbow_shoulder_xy_distance": 0.090,
					"elbow_shoulder_xy_gate_passed": true,
					"wrist_lateral_angle_from_elbow_vertical_deg": 18.0,
					"min_wrist_lateral_angle_from_elbow_vertical_deg": 15.0,
					"wrist_lateral_angle_gate_passed": true,
					"pose_reference_shoulder_width": 0.31,
					"pose_reference_shoulder_width_source": "live",
					"grace_ms_remaining": 0,
					"triggered_grace_ms": 240,
					"pose_only_rearm_ms": 250,
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
	assert_eq(String(rows[5].get("current_text", "")), "state=not_ready wrist=0.420 peak=0.455 xy=0.082<=0.090 (true) angle=18.000>=15.000 (true) fresh=true source=fresh_inference grace=0ms pose_valid=true")
	assert_eq(String(rows[7].get("threshold_text", "")), "0.180")
	assert_eq(String(rows[7].get("current_text", "")), "0.455")
	assert_eq(String(rows[8].get("threshold_text", "")), "0.090")
	assert_eq(String(rows[8].get("current_text", "")), "0.082")
	assert_eq(String(rows[9].get("threshold_text", "")), "15.000")
	assert_eq(String(rows[9].get("current_text", "")), "18.000")

func test_boxing_punch_inspector_body_calls_out_live_pose_inputs() -> void:
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
					"recent_peak_wrist_velocity": 0.365,
					"wrist_forward_velocity": 0.120,
					"forward_depth_spike": 0.080,
					"recent_peak_forward_depth_spike": 0.110,
					"min_velocity": 0.180,
					"elbow_shoulder_xy_distance": 0.076,
					"max_elbow_shoulder_xy_distance": 0.090,
					"elbow_shoulder_xy_gate_passed": true,
					"wrist_lateral_angle_from_elbow_vertical_deg": 18.0,
					"min_wrist_lateral_angle_from_elbow_vertical_deg": 15.0,
					"wrist_lateral_angle_gate_passed": true,
					"pose_reference_shoulder_width": 0.32,
					"pose_reference_shoulder_width_source": "live",
					"grace_ms_remaining": 160,
					"triggered_grace_ms": 240,
					"pose_only_rearm_ms": 250,
					"reacquire_stable_ms_required": 40,
				}
			}
		}
	})

	var inspector: Dictionary = harness._build_custom_inspector_model("gesture", "punch_right")
	var body := String(inspector.get("body", ""))
	assert_string_contains(body, "Current state - triggered")
	assert_string_contains(body, "Tracking status - tracked, valid=true, source=carried_forward, stale=0ms (0 frames), grace=0ms (0 frames), stable=160ms")
	assert_string_contains(body, "Fresh sample valid - false")
	assert_false(body.contains("Event payload snapshot"))
	assert_string_contains(body, "Recent punch velocity peak >= 0.180 - 0.365")
	assert_false(body.contains("Recent forward depth spike"))
	assert_string_contains(body, "Elbow-shoulder XY distance <= 0.090 - 0.076")
	assert_string_contains(body, "Wrist lateral angle from elbow vertical >= 15.000° - 18.000")
	assert_string_contains(body, "Grace timer - 160/240ms remaining (active)")
	assert_string_contains(body, "Pose-only rearm - waiting for pose-only rearm timer")

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
	assert_string_contains(body, "Wrist lateral angle from elbow vertical")
	assert_false(body.contains("Recent bbox area growth peak"))
	assert_false(body.contains("Positive growth samples"))

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
					"recent_peak_wrist_velocity": 0.47,
					"wrist_forward_velocity": 0.09,
					"wrist_lateral_angle_from_elbow_vertical_deg": 21.0,
					"min_wrist_lateral_angle_from_elbow_vertical_deg": 15.0,
					"wrist_lateral_angle_gate_passed": true,
					"pose_reference_shoulder_width": 0.30,
					"pose_reference_shoulder_width_source": "baseline",
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
	assert_string_contains(line, "peak_xyz_vel=0.470")
	assert_string_contains(line, "wrist_angle=21.000>=15.000(true)")
	assert_string_contains(line, "shoulder_width=0.300(baseline)")
	assert_string_contains(line, "hook=ready/0.310 dir=0.820")
	assert_string_contains(line, "uppercut=tracking_lost/0.000 dir=0.000")


func test_boxing_event_feed_text_lists_hook_uppercut_and_guard_tuning_sections() -> void:
	var harness = _new_harness()
	harness.set("_latest_state", {
		"gesture_debug": {
			"depth_runtime": {
				"hook": _depth_runtime_debug_payload(
					"enabled; artifact resolved to FastDepth/ONNX but adapter is still staged",
					"res://assets/depth_models/fastdepth/fastdepth_224.onnx",
					"onnx",
					"fastdepth_224_onnx",
					"blocked",
					"adapter_load",
					"adapter_unimplemented",
					"ONNX adapter is staged but not implemented yet"
				),
				"uppercut": _depth_runtime_debug_payload(
					"enabled; artifact resolved to MiDaS/OpenVINO but adapter is still staged",
					"res://assets/depth_models/midas/openvino_midas_v21_small_256/",
					"openvino",
					"midas_openvino_v21_small_256",
					"blocked",
					"adapter_load",
					"adapter_unimplemented",
					"OpenVINO adapter is staged but not implemented yet"
				),
			},
			"hook": {
				"left": _depth_live_debug_payload(0.020, 0.010, 0.020),
			},
			"uppercut": {
				"left": _depth_live_debug_payload(0.030, 0.010, 0.030),
			},
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
	assert_string_contains(text_body, "Max wrist angle from elbow horizontal ray")
	assert_string_contains(text_body, "Hook wrist must stay on mirrored preview-space side of elbow")
	assert_string_contains(text_body, "Depth loader truth: enabled; artifact resolved to FastDepth/ONNX but adapter is still staged")
	assert_string_contains(text_body, "Depth runtime status / stage: blocked / adapter_load")
	assert_string_contains(text_body, "Depth artifact path: res://assets/depth_models/fastdepth/fastdepth_224.onnx")
	assert_string_contains(text_body, "Depth backend/family: onnx / fastdepth_224_onnx")
	assert_string_contains(text_body, "Depth failure reason: adapter_unimplemented - ONNX adapter is staged but not implemented yet")
	assert_string_contains(text_body, "Depth live metrics (L): available=true, fresh=true, source=placeholder, closeness=0.020")
	assert_string_contains(text_body, "Depth thresholds: max_closeness_delta=0.030, max_peak_closeness=0.060")
	assert_string_contains(text_body, "Uppercut tuning")
	assert_string_contains(text_body, "Max wrist angle from elbow vertical ray")
	assert_string_contains(text_body, "Uppercut wrist must stay above elbow in preview space")
	assert_string_contains(text_body, "Depth artifact path: res://assets/depth_models/midas/openvino_midas_v21_small_256/")
	assert_string_contains(text_body, "Depth backend/family: openvino / midas_openvino_v21_small_256")
	assert_string_contains(text_body, "Guard tuning")
	assert_string_contains(text_body, "Wrist separation X <=")
	assert_string_contains(text_body, "Wrist separation Y <=")
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
					"wrist_angle_from_elbow_horizontal_deg": 18.0,
					"max_wrist_angle_from_elbow_horizontal_deg": 20.0,
					"wrist_horizontal_angle_gate_passed": true,
					"wrist_on_required_hook_side": true,
					"required_direction_label": "rightward",
					"required_hook_side_label": "left_of_elbow",
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
	assert_eq(String(rows[6].get("label", "")), "Wrist angle from elbow horizontal ray <= {threshold}°")
	assert_eq(String(rows[6].get("threshold_text", "")), "20.000")
	assert_eq(String(rows[6].get("current_text", "")), "18.000")
	assert_eq(String(rows[7].get("label", "")), "Preview-space wrist stays on required mirrored hook side")
	assert_eq(String(rows[7].get("threshold_text", "")), "true")
	assert_eq(String(rows[7].get("current_text", "")), "true (left_of_elbow)")
	assert_string_contains(String(rows[10].get("current_text", "")), "elapsed (pose-only timer)")
	assert_eq(String(rows[11].get("current_text", "")), "tracked / 40ms required")

	var inspector: Dictionary = harness._build_custom_inspector_model("gesture", "hook_left")
	var body := String(inspector.get("body", ""))
	assert_string_contains(body, "Motion window - 120ms configured, 118ms averaged span")
	assert_string_contains(body, "Averaged velocity >= 0.080 - 0.420")
	assert_string_contains(body, "Wrist angle from elbow horizontal ray <= 20.000° - 18.000")
	assert_string_contains(body, "Preview-space wrist stays on required mirrored hook side - true (left_of_elbow)")
	assert_string_contains(body, "Pose-only rearm - ")

func test_punch_family_inspectors_keep_only_compact_depth_backend_and_thresholds() -> void:
	var harness = _new_harness()
	harness.set("_latest_state", {
		"gesture_debug": {
			"depth_runtime": {
				"straight_punch": _depth_runtime_debug_payload(
					"enabled; runtime ready via onnx backend",
					"res://assets/depth_models/depth_anything_v2/depth_anything_v2_vits.onnx",
					"onnx",
					"depth_anything_v2_small_onnx",
					"ready",
					"sampling"
				),
			},
			"straight_punch": {
				"left": _depth_live_debug_payload(0.120, 0.080, 0.120),
			},
		}
	})

	var straight_inspector: Dictionary = harness._build_custom_inspector_model("gesture", "punch_left")
	var straight_body := String(straight_inspector.get("body", ""))
	assert_false(straight_body.contains("Depth tuning"))
	assert_false(straight_body.contains("Depth backend - onnx / depth_anything_v2_small_onnx"))
	assert_false(straight_body.contains("Depth delta threshold - min 0.060"))
	assert_false(straight_body.contains("Depth peak threshold - min 0.040"))
	assert_false(straight_body.contains("Depth runtime status / stage"))
	assert_false(straight_body.contains("Depth loader truth"))
	assert_false(straight_body.contains("Active depth artifact path"))
	assert_false(straight_body.contains("Depth failure reason"))
	assert_false(straight_body.contains("Active normalized depth metrics"))

	var hook_inspector: Dictionary = harness._build_custom_inspector_model("gesture", "hook_left")
	var hook_body := String(hook_inspector.get("body", ""))
	assert_false(hook_body.contains("Depth backend - configured / openvino_midas_v21_small_256"))
	assert_false(hook_body.contains("Depth delta threshold - max 0.030"))
	assert_false(hook_body.contains("Depth peak threshold - max 0.060"))

	var uppercut_inspector: Dictionary = harness._build_custom_inspector_model("gesture", "uppercut_left")
	var uppercut_body := String(uppercut_inspector.get("body", ""))
	assert_false(uppercut_body.contains("Depth backend - configured / openvino_midas_v21_small_256"))
	assert_false(uppercut_body.contains("Depth delta threshold - max 0.030"))
	assert_false(uppercut_body.contains("Depth peak threshold - max 0.060"))

func test_boxing_pose_only_punch_hover_card_and_inspector_report_skipped_hand_inputs_truthfully() -> void:
	var harness = _new_harness()
	harness.set("_latest_state", {
		"gesture_debug": {
			"straight_punch": {
				"left": {
					"state": "tracking_lost",
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
	assert_eq(String(rows[1].get("current_text", "")), "pose_tracked")
	assert_eq(String(rows[2].get("current_text", "")), "pose_valid=true, tracking=pose_tracked, source=pose, shoulder_width=0.000 (missing)")
	assert_eq(String(rows[8].get("threshold_text", "")), "0.090")
	assert_eq(String(rows[8].get("current_text", "")), "0.082")
	assert_eq(String(rows[10].get("current_text", "")), "waiting for pose-only rearm timer")

	var inspector: Dictionary = harness._build_custom_inspector_model("gesture", "punch_left")
	var body := String(inspector.get("body", ""))
	assert_string_contains(body, "Current state - pose_tracked")
	assert_string_contains(body, "Tracking status - pose_valid=true, tracking=pose_tracked, source=pose, shoulder_width=0.000 (missing)")
	assert_false(body.contains("Recent forward depth spike"))
	assert_string_contains(body, "Elbow-shoulder XY distance <= 0.090 - 0.082")
	assert_string_contains(body, "Wrist lateral angle from elbow vertical")
	assert_false(body.contains("BBox area - "))
	assert_false(body.contains("Recent bbox area growth peak"))
	assert_false(body.contains("Positive growth samples"))
	assert_string_contains(body, "Pose-only rearm - waiting for pose-only rearm timer")

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

func test_boxing_squat_hover_card_reports_grid_avoidance_truth() -> void:
	var harness = _new_harness()
	harness.set("_latest_state", {
		"gesture_debug": {
			"squat": {
				"state": true,
				"enabled": true,
				"current_cell": 6,
				"nose_tracked": true,
				"occupied_rows": [0],
				"occupied_cells": [0, 1, 2, 3],
				"nose_in_blocked_region": false,
				"avoidance_clear": true,
				"calibration_ready": true,
			}
		}
	})

	var model: Dictionary = harness._build_hover_card_model("squat")
	var rows: Array = model.get("rows", [])
	assert_eq(String(model.get("title", "")), "Squat")
	assert_eq(String(rows[1].get("current_text", "")), "active")
	assert_eq(String(rows[2].get("current_text", "")), "cell 6 [r1 c2]")
	assert_eq(String(rows[3].get("current_text", "")), "true")
	assert_eq(String(rows[5].get("current_text", "")), "0")
	assert_eq(String(rows[6].get("current_text", "")), "0, 1, 2, 3")
	assert_eq(String(rows[7].get("current_text", "")), "false")
	assert_eq(String(rows[9].get("current_text", "")), "true")

	var inspector: Dictionary = harness._build_custom_inspector_model("gesture", "squat")
	var body := String(inspector.get("body", ""))
	assert_string_contains(body, "Current state - active")
	assert_string_contains(body, "Blocked cells - 0, 1, 2, 3")
	assert_string_contains(body, "Nose occupied cell - cell 6 [r1 c2]")
	assert_string_contains(body, "Obstacle avoided - true")

func test_boxing_weave_hover_card_reports_grid_avoidance_truth() -> void:
	var harness = _new_harness()
	harness.set("_latest_state", {
		"gesture_debug": {
			"weave": {
				"state": "left",
				"enabled": true,
				"current_cell": 6,
				"nose_tracked": true,
				"left_obstacle": {
					"occupied_columns": [0, 1],
					"occupied_cells": [0, 1, 4, 5, 8, 9],
					"avoidance_clear": true,
				},
				"right_obstacle": {
					"occupied_columns": [2, 3],
					"occupied_cells": [2, 3, 6, 7, 10, 11],
					"avoidance_clear": false,
				},
				"left_candidate": true,
				"right_candidate": false,
				"neutral_candidate": false,
			}
		}
	})

	var model: Dictionary = harness._build_hover_card_model("weave")
	var rows: Array = model.get("rows", [])
	assert_eq(String(model.get("title", "")), "Weave")
	assert_eq(String(rows[1].get("current_text", "")), "left")
	assert_eq(String(rows[2].get("current_text", "")), "cell 6 [r1 c2]")
	assert_eq(String(rows[3].get("current_text", "")), "true")
	assert_eq(String(rows[5].get("current_text", "")), "0, 1")
	assert_eq(String(rows[6].get("current_text", "")), "0, 1, 4, 5, 8, 9")
	assert_eq(String(rows[7].get("current_text", "")), "true")
	assert_eq(String(rows[9].get("current_text", "")), "2, 3")
	assert_eq(String(rows[10].get("current_text", "")), "2, 3, 6, 7, 10, 11")
	assert_eq(String(rows[11].get("current_text", "")), "false")

	var inspector: Dictionary = harness._build_custom_inspector_model("gesture", "weave")
	var body := String(inspector.get("body", ""))
	assert_string_contains(body, "Current state - left")
	assert_string_contains(body, "Blocked columns - 0, 1")
	assert_string_contains(body, "Left obstacle avoided - true")
	assert_string_contains(body, "Right obstacle avoided - false")

func test_proving_harness_surfaces_shared_calibration_flow_and_routes_start_cancel_for_live_sources() -> void:
	var scene_root: Control = _new_live_calibration_harness() as Control
	assert_not_null(scene_root)
	var provider := FakeAthleteRecalibrateProvider.new()
	harness_set_provider(scene_root, provider)
	scene_root.set("_latest_state", provider.get_detector_state())
	scene_root.call("_refresh_calibration_flow_ui")

	var start_button := scene_root.find_child("AthleteRecalibrateButton", true, false) as Button
	var cancel_button := scene_root.find_child("AthleteCalibrationSecondaryButton", true, false) as Button
	var countdown_label := scene_root.find_child("CalibrationCountdownLabel", true, false) as Label
	var instruction_label := scene_root.find_child("CalibrationInstructionLabel", true, false) as Label
	var status_label := scene_root.find_child("CalibrationStatusLabel", true, false) as Label
	assert_not_null(start_button)
	assert_not_null(cancel_button)
	assert_not_null(countdown_label)
	assert_not_null(instruction_label)
	assert_not_null(status_label)
	assert_eq(start_button.text, "Calibrate Athlete")
	assert_eq(String(countdown_label.text), "")
	assert_false(countdown_label.visible)
	assert_eq(String(instruction_label.text), "")
	assert_false(instruction_label.visible)
	assert_eq(String(status_label.text), "")
	assert_false(status_label.visible)

	start_button.emit_signal("pressed")
	assert_eq(provider.request_count, 1)
	scene_root.call("_refresh_calibration_flow_ui")
	assert_eq(start_button.disabled, true)
	assert_eq(cancel_button.visible, true)
	assert_eq(String(countdown_label.text), "")
	assert_false(countdown_label.visible)
	assert_eq(String(instruction_label.text), "")
	assert_false(instruction_label.visible)
	assert_eq(String(status_label.text), "")
	assert_false(status_label.visible)

	provider.calibration_session = provider._make_session("capturing", {
		"is_active": true,
		"captured_sample_frames": 2,
		"readiness": {"ready": true},
	})
	scene_root.set("_latest_state", provider.get_detector_state())
	scene_root.call("_refresh_calibration_flow_ui")
	assert_eq(String(countdown_label.text), "")
	assert_false(countdown_label.visible)
	assert_eq(String(instruction_label.text), "")
	assert_false(instruction_label.visible)
	assert_eq(String(status_label.text), "")
	assert_false(status_label.visible)

	cancel_button.emit_signal("pressed")
	assert_eq(provider.cancel_count, 1)
	scene_root.call("_refresh_calibration_flow_ui")
	assert_eq(start_button.text, "Calibrate Athlete")
	assert_eq(String(status_label.text), "")
	assert_false(status_label.visible)

func test_proving_scenes_allow_shared_calibration_attempts_for_prerecorded_replays() -> void:
	for packed_scene_variant: Variant in [BoxingProvingScene, FlowProvingScene]:
		var packed_scene := packed_scene_variant as PackedScene
		var scene_root: Control = add_child_autoqfree(packed_scene.instantiate()) as Control
		assert_not_null(scene_root)
		var provider := FakeAthleteRecalibrateProvider.new()
		harness_set_provider(scene_root, provider)
		scene_root.set("_latest_state", provider.get_detector_state())
		scene_root.call("_refresh_calibration_flow_ui")

		var start_button := scene_root.find_child("AthleteRecalibrateButton", true, false) as Button
		var cancel_button := scene_root.find_child("AthleteCalibrationSecondaryButton", true, false) as Button
		var countdown_label := scene_root.find_child("CalibrationCountdownLabel", true, false) as Label
		var instruction_label := scene_root.find_child("CalibrationInstructionLabel", true, false) as Label
		var status_label := scene_root.find_child("CalibrationStatusLabel", true, false) as Label
		assert_not_null(start_button)
		assert_not_null(cancel_button)
		assert_not_null(countdown_label)
		assert_not_null(instruction_label)
		assert_not_null(status_label)
		assert_eq(start_button.disabled, false)
		assert_eq(start_button.text, "Calibrate Athlete")
		assert_eq(cancel_button.visible, false)
		assert_eq(String(countdown_label.text), "")
		assert_false(countdown_label.visible)
		assert_eq(String(instruction_label.text), "")
		assert_false(instruction_label.visible)
		assert_eq(String(status_label.text), "")
		assert_false(status_label.visible)

		start_button.emit_signal("pressed")
		assert_eq(provider.request_count, 1)
		scene_root.set("_latest_state", provider.get_detector_state())
		scene_root.call("_refresh_calibration_flow_ui")
		assert_eq(start_button.disabled, true)
		assert_eq(cancel_button.visible, true)
		assert_eq(String(countdown_label.text), "")
		assert_false(countdown_label.visible)
		assert_eq(String(instruction_label.text), "")
		assert_false(instruction_label.visible)

		provider.calibration_session = provider._make_session("capture_pending", {
			"is_active": true,
			"captured_sample_frames": 1,
			"failure_reason": "",
			"readiness": {"ready": true},
		})
		scene_root.set("_latest_state", provider.get_detector_state())
		scene_root.call("_refresh_calibration_flow_ui")
		assert_eq(String(countdown_label.text), "")
		assert_false(countdown_label.visible)
		assert_eq(String(instruction_label.text), "")
		assert_false(instruction_label.visible)
		assert_eq(String(status_label.text), "")
		assert_false(status_label.visible)
		assert_eq(start_button.text, "Capturing…")

func _shared_flow_grid_truth_state(capture_source: String = "calibration_session") -> Dictionary:
	return {
		"baseline": {
			"is_calibrated": true,
			"sample_frames": 5,
			"capture_source": capture_source,
		},
		"gesture_debug": {
			"flow": {
				"grid": {
					"is_calibrated": true,
					"columns": 4,
					"rows": 3,
					"cell_size": 0.08,
					"cell_width": 0.08,
					"cell_height": 0.08,
					"width": 0.32,
					"height": 0.24,
					"left_boundary": 0.34,
					"top_boundary": 0.84,
					"right_boundary": 0.66,
					"bottom_boundary": 0.60,
					"cell_rects": [
						{"index": 0}, {"index": 1}, {"index": 2}, {"index": 3},
						{"index": 4}, {"index": 5}, {"index": 6}, {"index": 7},
						{"index": 8}, {"index": 9}, {"index": 10}, {"index": 11},
					],
				},
				"tracked_landmarks": {
					"nose": {"current_cell": 5, "current_direction": 2, "latest_confidence": 0.98},
					"left_wrist": {"current_cell": 4, "current_direction": 0, "latest_confidence": 0.92},
					"right_wrist": {"current_cell": 7, "current_direction": 3, "latest_confidence": 0.93},
				},
				"left": {"current_cell": 4, "current_direction": 0},
				"right": {"current_cell": 7, "current_direction": 3},
			},
		},
	}

func test_proving_scenes_share_grid_truth_panel_and_preview_overlay() -> void:
	for packed_scene_variant: Variant in [BoxingProvingScene, FlowProvingScene]:
		var packed_scene := packed_scene_variant as PackedScene
		var scene_root: Control = add_child_autoqfree(packed_scene.instantiate()) as Control
		assert_not_null(scene_root)
		var presenter := add_child_autoqfree(FakePreviewPresenter.new()) as FakePreviewPresenter
		scene_root.set("_preview_presenter", presenter)
		scene_root.set("_latest_state", _shared_flow_grid_truth_state())
		scene_root.call("_sync_overlay_drawers_to_preview_presenter")
		scene_root.call("_refresh_debug_panels")

		var refs: Dictionary = scene_root.call("get_shared_flow_grid_truth_refs")
		var overlay := refs.get("flow_grid_overlay", null) as Object
		var truth_label := refs.get("grid_truth_label", null) as RichTextLabel
		var nose_chart := scene_root.find_child("NosePlacementChart", true, false) as Control
		var left_chart := scene_root.find_child("LeftPlacementChart", true, false) as Control
		var right_chart := scene_root.find_child("RightPlacementChart", true, false) as Control
		assert_not_null(overlay)
		assert_not_null(truth_label)
		assert_not_null(nose_chart)
		assert_not_null(left_chart)
		assert_not_null(right_chart)
		assert_same((overlay as Control).get_parent(), presenter.get_overlay_layer())
		assert_true(bool((overlay as Control).visible))
		var overlay_snapshot: Dictionary = overlay.call("get_overlay_snapshot")
		assert_eq(int(overlay_snapshot.get("columns", 0)), 4)
		assert_eq(int(overlay_snapshot.get("rows", 0)), 3)
		assert_eq(int(overlay_snapshot.get("cell_count", 0)), 12)
		assert_eq(float(overlay_snapshot.get("cell_width", 0.0)), 0.08)
		assert_eq(float(overlay_snapshot.get("cell_height", 0.0)), 0.08)
		assert_eq(int(nose_chart.get("active_index")), 5)
		assert_eq(int(left_chart.get("active_index")), 4)
		assert_eq(int(right_chart.get("active_index")), 7)
		assert_eq(String(truth_label.text), "")

func test_boxing_proving_scene_places_shared_grid_cards_inside_board_grid_with_boxing_shell_style() -> void:
	var scene_root: Control = add_child_autoqfree(BoxingProvingScene.instantiate()) as Control
	assert_not_null(scene_root)
	assert_null(scene_root.find_child("GridTruthPanel", true, false))
	var board_grid := scene_root.find_child("BoardGrid", true, false) as GridContainer
	var nose_card := scene_root.find_child("NosePlacementCard", true, false) as PanelContainer
	var left_card := scene_root.find_child("LeftPlacementCard", true, false) as PanelContainer
	var right_card := scene_root.find_child("RightPlacementCard", true, false) as PanelContainer
	assert_not_null(board_grid)
	assert_not_null(nose_card)
	assert_not_null(left_card)
	assert_not_null(right_card)
	assert_same(nose_card.get_parent(), board_grid)
	assert_same(left_card.get_parent(), board_grid)
	assert_same(right_card.get_parent(), board_grid)
	assert_eq(nose_card.custom_minimum_size, Vector2(132, 158))
	var style := nose_card.get_theme_stylebox("panel") as StyleBoxFlat
	assert_not_null(style)
	assert_gt(style.border_color.a, 0.0)
	assert_gt(style.bg_color.a, 0.0)

func test_proving_scenes_hide_replay_auto_bootstrap_grid_truth() -> void:
	for packed_scene_variant: Variant in [BoxingProvingScene, FlowProvingScene]:
		var packed_scene := packed_scene_variant as PackedScene
		var scene_root: Control = add_child_autoqfree(packed_scene.instantiate()) as Control
		assert_not_null(scene_root)
		var presenter := add_child_autoqfree(FakePreviewPresenter.new()) as FakePreviewPresenter
		scene_root.set("_preview_presenter", presenter)
		scene_root.set("_latest_state", _shared_flow_grid_truth_state("auto_bootstrap"))
		scene_root.call("_sync_overlay_drawers_to_preview_presenter")
		scene_root.call("_refresh_debug_panels")

		var refs: Dictionary = scene_root.call("get_shared_flow_grid_truth_refs")
		var overlay := refs.get("flow_grid_overlay", null) as Control
		var truth_label := refs.get("grid_truth_label", null) as RichTextLabel
		assert_not_null(overlay)
		assert_not_null(truth_label)
		assert_eq(overlay.visible, false)
		assert_eq(String(truth_label.text), "")
		if packed_scene == BoxingProvingScene:
			assert_null(scene_root.find_child("GridTruthPanel", true, false))

func harness_set_provider(scene_root: Control, provider: Node) -> void:
	scene_root.set("provider", provider)

func test_proving_harness_surfaces_shared_calibration_success_and_failure_truthfully_for_live_sources() -> void:
	var scene_root: Control = _new_live_calibration_harness() as Control
	assert_not_null(scene_root)
	var provider := FakeAthleteRecalibrateProvider.new()
	harness_set_provider(scene_root, provider)
	var start_button := scene_root.find_child("AthleteRecalibrateButton", true, false) as Button
	var countdown_label := scene_root.find_child("CalibrationCountdownLabel", true, false) as Label
	var instruction_label := scene_root.find_child("CalibrationInstructionLabel", true, false) as Label
	var status_label := scene_root.find_child("CalibrationStatusLabel", true, false) as Label
	assert_not_null(start_button)
	assert_not_null(countdown_label)
	assert_not_null(instruction_label)
	assert_not_null(status_label)

	provider.calibration_session = provider._make_session("failed", {
		"result": "failed",
		"failure_reason": "missing_wrist_landmarks",
	})
	scene_root.set("_latest_state", provider.get_detector_state())
	scene_root.call("_refresh_calibration_flow_ui")
	assert_eq(start_button.text, "Try Again")
	assert_eq(String(countdown_label.text), "")
	assert_false(countdown_label.visible)
	assert_eq(String(instruction_label.text), "")
	assert_false(instruction_label.visible)
	assert_eq(String(status_label.text), "")
	assert_false(status_label.visible)

	provider.baseline = {"is_calibrated": true, "sample_frames": 5}
	provider.calibration_session = provider._make_session("succeeded", {
		"result": "succeeded",
		"captured_sample_frames": 5,
		"readiness": {"ready": true},
	})
	scene_root.set("_latest_state", provider.get_detector_state())
	scene_root.call("_refresh_calibration_flow_ui")
	assert_eq(start_button.text, "Calibrate Athlete")
	assert_eq(String(countdown_label.text), "")
	assert_false(countdown_label.visible)
	assert_eq(String(instruction_label.text), "")
	assert_false(instruction_label.visible)
	assert_eq(String(status_label.text), "")
	assert_false(status_label.visible)

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

func test_boxing_depth_debug_hides_thumbnail_when_all_boxing_depth_families_are_disabled() -> void:
	var harness = _new_depth_disabled_harness()
	harness._sync_depth_debug_visual_config({
		"depth_debug": {
			"enabled": true,
			"thumbnail_visible": true,
			"swap_click_enabled": true,
			"hover_hint_visible": true,
			"sampling_regions_visible": true,
			"fps_visible": true,
			"request_runtime_texture": true,
		}
	})
	var depth_debug_visual_config: Dictionary = harness.get("_depth_debug_visual_config")
	assert_false(bool(depth_debug_visual_config.get("thumbnail_visible", true)))
	assert_false(bool(depth_debug_visual_config.get("swap_click_enabled", true)))
	assert_false(bool(depth_debug_visual_config.get("hover_hint_visible", true)))
	assert_false(bool(depth_debug_visual_config.get("sampling_regions_visible", true)))

func test_boxing_depth_debug_focus_family_prefers_enabled_family_with_runtime_texture() -> void:
	var harness = _new_harness()
	harness.set("_latest_state", {
		"gesture_debug": {
			"depth_runtime": {
				"straight_punch": {
					"depth_enabled": false,
					"runtime_status": "unloaded",
					"last_sample_timestamp_ms": -1,
				},
				"hook": _depth_runtime_visual_state(_make_test_texture(Color(0.71, 0.71, 0.71, 1.0))),
				"uppercut": {
					"depth_enabled": true,
					"runtime_status": "ready",
					"last_sample_timestamp_ms": 123455,
					"last_sample_metrics": {"sample_source": "fresh_inference"},
				},
			}
		}
	})
	assert_eq(String(harness._depth_debug_focus_family()), "hook")

func test_playback_replay_step_buttons_are_hidden_in_timeline() -> void:
	var harness: Variant = _new_playback_harness()
	harness.set("_playback_toggle_button", add_child_autoqfree(Button.new()))
	harness.set("_playback_seek_slider", add_child_autoqfree(HSlider.new()))
	harness.set("_playback_time_label", add_child_autoqfree(Label.new()))
	var step_back: Button = add_child_autoqfree(Button.new()) as Button
	var step_forward: Button = add_child_autoqfree(Button.new()) as Button
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
	harness.set("_playback_status", {"paused": true, "media_loaded": true, "current_time_sec": 1.0, "duration_sec": 2.0, "progress": 0.5})
	harness._refresh_playback_controls_state()
	assert_false(step_back.disabled)
	assert_false(step_forward.disabled)
	assert_false(step_back.visible)
	assert_false(step_forward.visible)

	harness.set("_playback_status", {"paused": false, "media_loaded": true, "current_time_sec": 1.0, "duration_sec": 2.0, "progress": 0.5})
	harness._refresh_playback_controls_state()
	assert_true(step_back.disabled)
	assert_true(step_forward.disabled)
	assert_false(step_back.visible)
	assert_false(step_forward.visible)

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
	assert_eq(String(rows[5].get("current_text", "")), "state=triggered wrist=0.280 xy=0.082<=0.090 (true) bbox=0.064 growth=0.011 fresh=true source=fresh_inference grace=240ms valid=true")
