extends "res://addons/aerobeat-vendor-godot-unit-test/test.gd"

const LandmarkDrawerScript = preload("res://scripts/landmark_drawer.gd")
const DepthDebugViewerScript = preload("res://scripts/depth_debug_viewer.gd")
const ProvingHarnessScript = preload("res://scripts/proving_harness.gd")
const FlowRingChartScript = preload("res://scripts/flow_ring_chart.gd")
const BoxingProvingScene = preload("res://scenes/boxing_proving.tscn")
const FlowProvingScene = preload("res://scenes/flow_proving.tscn")
const AeroCameraTrackingScript = preload("res://addons/aerobeat-input-camera-tracking/src/AeroCameraTracking.gd")
const CameraTrackingFakeBackendScript = preload("res://addons/aerobeat-tool-camera-tracking/src/CameraTrackingFakeBackend.gd")

class FakePreviewPresenter:
	extends Control

	var overlay_layer: Control
	var preview_surface: TextureRect
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
		preview_surface = TextureRect.new()
		preview_surface.name = "PreviewSurface"
		preview_surface.mouse_filter = Control.MOUSE_FILTER_IGNORE
		preview_surface.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		add_child(preview_surface)
		overlay_layer = Control.new()
		overlay_layer.name = "OverlayLayer"
		overlay_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
		overlay_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		add_child(overlay_layer)

	func get_overlay_layer() -> Control:
		return overlay_layer

	func get_preview_surface() -> TextureRect:
		return preview_surface

	func set_preview_texture(texture: Texture2D) -> void:
		preview_surface.texture = texture

	func get_hand_debug_snapshot() -> Dictionary:
		return hand_snapshot.duplicate(true)

	func get_content_rect() -> Rect2:
		return Rect2(Vector2.ZERO, size)

	func map_landmark_to_preview_position(point: Dictionary) -> Vector2:
		return Vector2(float(point.get("x", 0.0)) * size.x, float(point.get("y", 0.0)) * size.y)

class FakeCoverPreviewPresenter:
	extends Control

	var overlay_layer: Control
	var content_rect := Rect2(Vector2(-200.0, 0.0), Vector2(1000.0, 293.0))

	func _init() -> void:
		size = Vector2(520.0, 293.0)
		overlay_layer = Control.new()
		overlay_layer.name = "OverlayLayer"
		overlay_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		add_child(overlay_layer)

	func get_overlay_layer() -> Control:
		return overlay_layer

	func get_content_rect() -> Rect2:
		return content_rect

	func map_landmark_to_preview_position(point: Dictionary) -> Vector2:
		return Vector2(
			content_rect.position.x + clampf(float(point.get("x", 0.0)), 0.0, 1.0) * content_rect.size.x,
			content_rect.position.y + clampf(float(point.get("y", 0.0)), 0.0, 1.0) * content_rect.size.y
		)

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

class ConsoleCaptureHarness:
	extends ProvingHarnessScript

	var console_lines: Array[String] = []

	func _emit_console_log_line(line: String) -> void:
		console_lines.append(line)

class FakeAthleteRecalibrateProvider:
	extends Node

	var request_count := 0
	var cancel_count := 0
	var calibration_session := _make_session("waiting")
	var baseline := {"is_calibrated": false, "sample_frames": 0}

	func start_athlete_calibration() -> bool:
		request_count += 1
		baseline = {"is_calibrated": false, "sample_frames": 0}
		calibration_session = _make_session("holding", {
			"is_active": true,
			"hold_progress_ms": 320,
			"instruction_text": "Hold the T-pose steady to finish auto-calibration",
		})
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
			"is_active": state_name == "waiting" or state_name == "holding" or state_name == "cooldown",
			"result": "pending" if state_name == "waiting" or state_name == "holding" or state_name == "cooldown" else state_name,
			"hold_ms": 750,
			"hold_progress_ms": 0,
			"hold_progress_ratio": 0.0,
			"hold_started_at_ms": 0,
			"last_fired_at_ms": 0,
			"next_fire_at_ms": 0,
			"cooldown_ms": 1000,
			"cooldown_remaining_ms": 0,
			"captured_sample_frames": 0,
			"required_capture_frames": 1,
			"failure_reason": "required_sample_landmarks_unavailable",
			"instruction_text": "Show nose, shoulders, elbows, and wrists, then hold a straight-arm T-pose.",
			"readiness": {
				"tracking_ready": false,
				"required_landmarks_ready": false,
				"horizontal_alignment_ready": false,
				"arm_extension_ready": false,
				"qualified": false,
				"hold_ready": false,
				"ready": false,
				"hold_ms": 750,
				"hold_progress_ms": 0,
				"hold_progress_ratio": 0.0,
				"cooldown_ms": 1000,
				"cooldown_remaining_ms": 0,
				"instruction_text": "Show nose, shoulders, elbows, and wrists, then hold a straight-arm T-pose.",
				"required_landmarks": {
					"nose": false,
					"left_shoulder": false,
					"right_shoulder": false,
					"left_elbow": false,
					"right_elbow": false,
					"left_wrist": false,
					"right_wrist": false,
				},
				"thresholds": {
					"max_wrist_shoulder_y_ratio": 0.12,
					"max_elbow_shoulder_y_ratio": 0.10,
					"min_elbow_angle_deg": 165.0,
				},
				"measurements": {
					"shoulder_width": 0.36,
					"left_wrist_shoulder_y_ratio": 0.0,
					"right_wrist_shoulder_y_ratio": 0.0,
					"left_elbow_shoulder_y_ratio": 0.0,
					"right_elbow_shoulder_y_ratio": 0.0,
					"left_arm_extension": 0.0,
					"right_arm_extension": 0.0,
					"left_elbow_bend_deg": 0.0,
					"right_elbow_bend_deg": 0.0,
					"calibration_width": 0.0,
					"calibration_height": 0.0,
				},
			},
			"instructions": {
				"show_sample_landmarks": {"text": "Keep nose, shoulders, elbows, and wrists visible", "ready": false},
			},
		}
		for key: Variant in overrides.keys():
			session[key] = overrides[key]
		return session

class DetectorStateViewProvider:
	extends Node

	var get_detector_state_calls := 0
	var get_detector_state_view_calls := 0
	var shared_nested := {"value": 7}

	func get_detector_state() -> Dictionary:
		get_detector_state_calls += 1
		return {"tracking_state": "deep_copy_path", "nested": {"value": -1}}

	func get_detector_state_view() -> Dictionary:
		get_detector_state_view_calls += 1
		return {
			"tracking_state": "view_path",
			"nested": shared_nested,
		}

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

func _install_root_camera_tracking_singleton() -> Variant:
	var singleton := get_tree().root.get_node_or_null("AeroCameraTracking")
	if singleton == null:
		singleton = AeroCameraTrackingScript.new()
		singleton.name = "AeroCameraTracking"
		get_tree().root.add_child(singleton)
	if singleton.has_method("shutdown_runtime"):
		singleton.shutdown_runtime()
	var tracker: Variant = singleton.get_tracking_session()
	tracker.set_backend(CameraTrackingFakeBackendScript.new())
	return singleton

func _new_console_capture_harness() -> Variant:
	return add_child_autoqfree(ConsoleCaptureHarness.new())

func _make_test_calibration_session(state_name: String, overrides: Dictionary = {}) -> Dictionary:
	var provider := FakeAthleteRecalibrateProvider.new()
	var session := provider._make_session(state_name, overrides)
	provider.free()
	return session

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


func test_sync_latest_detector_state_prefers_shallow_view_export_when_available() -> void:
	var harness: Variant = _new_base_harness()
	var provider := DetectorStateViewProvider.new()
	add_child_autoqfree(provider)
	harness.provider = provider

	harness._sync_latest_detector_state()

	assert_eq(provider.get_detector_state_view_calls, 1)
	assert_eq(provider.get_detector_state_calls, 0)
	assert_eq(harness.get("_latest_state").get("tracking_state", ""), "view_path")
	assert_true(harness.get("_latest_state").get("nested") == provider.shared_nested)


func test_live_proving_pose_updates_skip_fixture_pose_snapshot_capture_by_default() -> void:
	var harness: Variant = _new_base_harness()
	harness._reset_event_tracking()
	harness.set("_latest_state", {
		"frame_index": 12,
		"timestamp_ms": 345,
		"tracking_state": "tracking",
		"landmarks_by_id": {0: {"x": 0.5, "y": 0.5}},
		"metrics": {"fps": 60.0},
	})

	harness._record_fixture_state_snapshot("pose_updated")

	var report: Dictionary = harness.get_fixture_capture_report()
	var capture: Dictionary = report.get("state_timeline_capture", {})
	assert_eq(int(capture.get("pose_snapshots_seen", 0)), 1)
	assert_eq(int(capture.get("pose_snapshots_retained", 0)), 0)
	assert_eq(int(capture.get("pose_snapshots_dropped", 0)), 1)
	assert_true((report.get("state_timeline", []) as Array).is_empty())


func test_prerecorded_pose_updates_still_capture_fixture_pose_snapshots() -> void:
	var harness: Variant = _new_playback_harness()
	harness._reset_event_tracking()
	harness.set("_latest_state", {
		"frame_index": 7,
		"timestamp_ms": 890,
		"tracking_state": "tracking",
		"landmarks_by_id": {0: {"x": 0.25, "y": 0.75}},
		"metrics": {"fps": 30.0},
	})

	harness._record_fixture_state_snapshot("pose_updated")

	var report: Dictionary = harness.get_fixture_capture_report()
	var capture: Dictionary = report.get("state_timeline_capture", {})
	assert_eq(int(capture.get("pose_snapshots_seen", 0)), 1)
	assert_eq(int(capture.get("pose_snapshots_retained", 0)), 1)
	assert_eq(int(capture.get("pose_snapshots_dropped", 0)), 0)
	var timeline: Array = report.get("state_timeline", []) as Array
	assert_eq(timeline.size(), 1)
	var entry: Dictionary = timeline[0] as Dictionary
	assert_eq(String(entry.get("reason", "")), "pose_updated")
	assert_true(entry.has("pose_snapshot"))


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
	presenter.set_preview_texture(_make_test_texture(Color(0.18, 0.34, 0.72, 1.0)))
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
	presenter.set_preview_texture(_make_test_texture(Color(0.18, 0.34, 0.72, 1.0)))
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
	presenter.set_preview_texture(preview_texture)
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
	presenter.set_preview_texture(_make_test_texture(Color(0.22, 0.61, 0.38, 1.0)))
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
					"wrist_shoulder_xy_distance": 0.108,
					"max_wrist_shoulder_xy_distance": 0.180,
					"wrist_shoulder_xy_gate_passed": true,
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
	assert_string_contains(line, "wrist_shoulder_xy=0.108<=0.180(true)")
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
					"wrist_shoulder_xy_distance": 0.118,
					"max_wrist_shoulder_xy_distance": 0.180,
					"wrist_shoulder_xy_gate_passed": true,
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
	assert_eq(String(rows[5].get("current_text", "")), "waiting for first straight-punch state change payload")
	assert_eq(String(rows[7].get("threshold_text", "")), "0.180")
	assert_eq(String(rows[7].get("current_text", "")), "0.455")
	assert_eq(String(rows[8].get("threshold_text", "")), "0.090")
	assert_eq(String(rows[8].get("current_text", "")), "0.082")
	assert_eq(String(rows[9].get("threshold_text", "")), "0.180")
	assert_eq(String(rows[9].get("current_text", "")), "0.118")
	assert_eq(String(rows[10].get("threshold_text", "")), "15.000")
	assert_eq(String(rows[10].get("current_text", "")), "18.000")

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
					"wrist_shoulder_xy_distance": 0.112,
					"max_wrist_shoulder_xy_distance": 0.180,
					"wrist_shoulder_xy_gate_passed": true,
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
	assert_string_contains(body, "Wrist-shoulder XY distance <= 0.180 - 0.112")
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
	assert_string_contains(text_body, "Straight-punch tuning")
	assert_string_contains(text_body, "Max wrist-shoulder XY distance: 0.100")
	assert_string_contains(text_body, "Hook tuning")
	assert_string_contains(text_body, "Grid variant: strike_subgrid")
	assert_string_contains(text_body, "Minimum horizontal column travel: 1 subcells")
	assert_string_contains(text_body, "Hook direction reference: athlete-space horizontal columns (left hook = athlete_right with positive signed delta, right hook = athlete_left with negative signed delta)")
	assert_string_contains(text_body, "Depth loader truth: enabled; artifact resolved to FastDepth/ONNX but adapter is still staged")
	assert_string_contains(text_body, "Depth runtime status / stage: blocked / adapter_load")
	assert_string_contains(text_body, "Depth artifact path: res://assets/depth_models/fastdepth/fastdepth_224.onnx")
	assert_string_contains(text_body, "Depth backend/family: onnx / fastdepth_224_onnx")
	assert_string_contains(text_body, "Depth failure reason: adapter_unimplemented - ONNX adapter is staged but not implemented yet")
	assert_string_contains(text_body, "Depth live metrics (L): available=true, fresh=true, source=placeholder, closeness=0.020")
	assert_string_contains(text_body, "Depth thresholds: max_closeness_delta=0.030, max_peak_closeness=0.060")
	assert_string_contains(text_body, "Uppercut tuning")
	assert_string_contains(text_body, "Minimum upward row travel: 1 subcells")
	assert_string_contains(text_body, "Uppercut direction reference: athlete-space upward rows (negative signed delta)")
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

func test_pose_strike_grid_hover_card_and_inspector_surface_buffered_progress_and_overflow_truth() -> void:
	var harness = _new_harness()
	harness.set("_latest_state", {
		"gesture_debug": {
			"hook": {
				"left": {
					"backend": "grid_detection",
					"state": "not_ready",
					"previous_state": "triggered",
					"timestamp_ms": Time.get_ticks_msec() - 260,
					"pose_tracking_valid": true,
					"tracking_state": "pose_tracked",
					"sample_source": "pose",
					"window_ms": 250,
					"window_span_ms": 180,
					"grid_variant": "strike_subgrid",
					"direction_reference_frame": "athlete_space_columns",
					"grid_transition_available": true,
					"grid_previous_cell": 16,
					"grid_current_cell": 18,
					"grid_column_delta": 2,
					"grid_row_delta": 0,
					"grid_cell_delta_gate_passed": true,
					"grid_direction_gate_passed": true,
					"grid_accumulated_progress": 2,
					"grid_progress_threshold": 1,
					"grid_progress_ready": true,
					"grid_progress_mode": "directional_run_excursion",
					"grid_progress_transition_count": 3,
					"grid_run_transition_count": 1,
					"grid_run_reset_reason": "reversal",
					"grid_overflow_protection_enabled": true,
					"grid_overflow_accumulation_frozen": true,
					"buffered_grid_transition_available": true,
					"buffered_grid_previous_cell": 18,
					"buffered_grid_current_cell": 20,
					"buffered_grid_column_delta": 2,
					"buffered_grid_row_delta": 0,
					"buffered_grid_accumulated_progress": 2,
					"grace_ms_remaining": 0,
					"triggered_grace_ms": 250,
					"pose_only_rearm_ms": 1,
					"reacquire_stable_ms_required": 40,
				},
			},
		}
	})

	var model: Dictionary = harness._build_hover_card_model("hook_left")
	var rows: Array = model.get("rows", [])
	assert_eq(String(rows[8].get("label", "")), "Grid progress")
	assert_eq(String(rows[8].get("current_text", "")), "2/1 subcells, ready=true, history=3, run=1, mode=directional_run_excursion, reset=reversal")
	assert_eq(String(rows[9].get("label", "")), "Buffered repeat transition")
	assert_eq(String(rows[9].get("current_text", "")), "cell 18 [r4 c2] -> cell 20 [r5 c0], Δcol +2, Δrow 0, progress 2")
	assert_eq(String(rows[10].get("label", "")), "Overflow protection")
	assert_eq(String(rows[10].get("current_text", "")), "enabled, frozen=true")

	var inspector: Dictionary = harness._build_custom_inspector_model("gesture", "hook_left")
	var body := String(inspector.get("body", ""))
	assert_string_contains(body, "Grid progress - 2/1 subcells, ready=true, history=3, run=1, mode=directional_run_excursion, reset=reversal")
	assert_string_contains(body, "Buffered repeat transition - cell 18 [r4 c2] -> cell 20 [r5 c0], Δcol +2, Δrow 0, progress 2")
	assert_string_contains(body, "Overflow protection - enabled, frozen=true")

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
					"wrist_shoulder_xy_distance": 0.140,
					"max_wrist_shoulder_xy_distance": 0.180,
					"wrist_shoulder_xy_gate_passed": true,
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
	assert_eq(String(rows[9].get("threshold_text", "")), "0.180")
	assert_eq(String(rows[9].get("current_text", "")), "0.140")
	assert_eq(String(rows[11].get("current_text", "")), "waiting for pose-only rearm timer")

	var inspector: Dictionary = harness._build_custom_inspector_model("gesture", "punch_left")
	var body := String(inspector.get("body", ""))
	assert_string_contains(body, "Current state - pose_tracked")
	assert_string_contains(body, "Tracking status - pose_valid=true, tracking=pose_tracked, source=pose, shoulder_width=0.000 (missing)")
	assert_false(body.contains("Recent forward depth spike"))
	assert_string_contains(body, "Elbow-shoulder XY distance <= 0.090 - 0.082")
	assert_string_contains(body, "Wrist-shoulder XY distance <= 0.180 - 0.140")
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
				"current_cell": 5,
				"nose_tracked": true,
				"blocked_from_edge": "top",
				"blocked_height_ratio": 0.60,
				"threshold_line_active": true,
				"threshold_line_y": 0.58,
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
	assert_eq(String(rows[2].get("current_text", "")), "cell 5 [r1 c1]")
	assert_eq(String(rows[3].get("current_text", "")), "true")
	assert_eq(String(rows[5].get("current_text", "")), "top")
	assert_eq(String(rows[6].get("current_text", "")), "0.600")
	assert_eq(String(rows[7].get("current_text", "")), "0.580")
	assert_eq(String(rows[8].get("current_text", "")), "false")
	assert_eq(String(rows[10].get("current_text", "")), "true")

	var inspector: Dictionary = harness._build_custom_inspector_model("gesture", "squat")
	var body := String(inspector.get("body", ""))
	assert_string_contains(body, "Current state - active")
	assert_string_contains(body, "Blocked height ratio - 0.600")
	assert_string_contains(body, "Threshold line Y - 0.580")
	assert_string_contains(body, "Nose occupied cell - cell 5 [r1 c1]")
	assert_string_contains(body, "Obstacle avoided - true")

func test_boxing_weave_hover_card_reports_grid_avoidance_truth() -> void:
	var harness = _new_harness()
	harness.set("_latest_state", {
		"gesture_debug": {
			"weave": {
				"state": "left",
				"enabled": true,
				"current_cell": 5,
				"nose_tracked": true,
				"left_obstacle": {
					"occupied_columns": [0, 1],
					"occupied_cells": [2, 3, 6, 7, 10, 11],
					"avoidance_clear": true,
				},
				"right_obstacle": {
					"occupied_columns": [2, 3],
					"occupied_cells": [0, 1, 4, 5, 8, 9],
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
	assert_eq(String(rows[2].get("current_text", "")), "cell 5 [r1 c1]")
	assert_eq(String(rows[3].get("current_text", "")), "true")
	assert_eq(String(rows[5].get("current_text", "")), "0, 1")
	assert_eq(String(rows[6].get("current_text", "")), "2, 3, 6, 7, 10, 11")
	assert_eq(String(rows[7].get("current_text", "")), "true")
	assert_eq(String(rows[9].get("current_text", "")), "2, 3")
	assert_eq(String(rows[10].get("current_text", "")), "0, 1, 4, 5, 8, 9")
	assert_eq(String(rows[11].get("current_text", "")), "false")

	var inspector: Dictionary = harness._build_custom_inspector_model("gesture", "weave")
	var body := String(inspector.get("body", ""))
	assert_string_contains(body, "Current state - left")
	assert_string_contains(body, "Blocked columns - 0, 1")
	assert_string_contains(body, "Left obstacle avoided - true")
	assert_string_contains(body, "Right obstacle avoided - false")

func test_proving_harness_removes_stale_calibration_overlay_but_keeps_calibration_event_truth_for_live_sources() -> void:
	var scene_root: Control = _new_live_calibration_harness() as Control
	assert_not_null(scene_root)
	var provider := FakeAthleteRecalibrateProvider.new()
	harness_set_provider(scene_root, provider)
	scene_root.set("_latest_state", provider.get_detector_state())
	scene_root.call("_refresh_calibration_flow_ui")

	assert_null(scene_root.find_child("AthleteCalibrationPanel", true, false))
	assert_null(scene_root.find_child("AthleteRecalibrateButton", true, false))
	assert_null(scene_root.find_child("AthleteCalibrationSecondaryButton", true, false))
	assert_null(scene_root.find_child("CalibrationCountdownLabel", true, false))
	assert_null(scene_root.find_child("CalibrationInstructionLabel", true, false))
	assert_null(scene_root.find_child("CalibrationStatusLabel", true, false))

	provider.start_athlete_calibration()
	assert_eq(provider.request_count, 1)
	scene_root.set("_latest_state", provider.get_detector_state())
	scene_root.call("_refresh_calibration_flow_ui")
	assert_eq(scene_root.call("_event_count", "athlete_calibration_started"), 1)

	provider.cancel_athlete_calibration()
	assert_eq(provider.cancel_count, 1)
	scene_root.set("_latest_state", provider.get_detector_state())
	scene_root.call("_refresh_calibration_flow_ui")
	assert_eq(scene_root.call("_event_count", "athlete_calibration_cancelled"), 1)

func test_proving_scenes_remove_stale_calibration_overlay_for_prerecorded_replays() -> void:
	for packed_scene_variant: Variant in [BoxingProvingScene, FlowProvingScene]:
		var packed_scene := packed_scene_variant as PackedScene
		var scene_root: Control = add_child_autoqfree(packed_scene.instantiate()) as Control
		assert_not_null(scene_root)
		var provider := FakeAthleteRecalibrateProvider.new()
		harness_set_provider(scene_root, provider)
		scene_root.set("_latest_state", provider.get_detector_state())
		scene_root.call("_refresh_calibration_flow_ui")
		assert_null(scene_root.find_child("AthleteCalibrationPanel", true, false))
		assert_null(scene_root.find_child("AthleteRecalibrateButton", true, false))
		assert_null(scene_root.find_child("AthleteCalibrationSecondaryButton", true, false))
		assert_null(scene_root.find_child("CalibrationCountdownLabel", true, false))
		assert_null(scene_root.find_child("CalibrationInstructionLabel", true, false))
		assert_null(scene_root.find_child("CalibrationStatusLabel", true, false))

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
					"coordinate_space": "gameplay_bottom_left",
					"cell_size": 0.08,
					"cell_width": 0.08,
					"cell_height": 0.14197952218430035,
					"width": 0.32,
					"height": 0.42593856655290104,
					"left_boundary": 0.34,
					"top_boundary": 0.84,
					"right_boundary": 0.66,
					"bottom_boundary": 0.414061433447099,
					"strike_subgrid": {
						"enabled": true,
						"variant": "strike_subgrid",
						"columns": 8,
						"rows": 6,
						"columns_multiplier": 2,
						"rows_multiplier": 2,
						"draw_dashed_overlay": true,
					},
					"cell_rects": [
						{"index": 0}, {"index": 1}, {"index": 2}, {"index": 3},
						{"index": 4}, {"index": 5}, {"index": 6}, {"index": 7},
						{"index": 8}, {"index": 9}, {"index": 10}, {"index": 11},
					],
				},
				"tracked_landmarks": {
					"nose": {"current_cell": 6, "current_direction": 2, "latest_confidence": 0.98},
					"left_wrist": {"current_cell": 7, "current_direction": 0, "latest_confidence": 0.92},
					"right_wrist": {"current_cell": 4, "current_direction": 3, "latest_confidence": 0.93},
				},
				"left": {"current_cell": 7, "current_direction": 0},
				"right": {"current_cell": 4, "current_direction": 3},
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
		var nose_direction_chart := scene_root.find_child("NoseDirectionChart", true, false) as Control
		var left_chart := scene_root.find_child("LeftPlacementChart", true, false) as Control
		var right_chart := scene_root.find_child("RightPlacementChart", true, false) as Control
		assert_not_null(overlay)
		assert_not_null(truth_label)
		assert_not_null(nose_chart)
		if packed_scene == FlowProvingScene:
			assert_not_null(nose_direction_chart)
		assert_not_null(left_chart)
		assert_not_null(right_chart)
		assert_same((overlay as Control).get_parent(), presenter.get_overlay_layer())
		assert_true(bool((overlay as Control).visible))
		var overlay_snapshot: Dictionary = overlay.call("get_overlay_snapshot")
		assert_eq(int(overlay_snapshot.get("columns", 0)), 4)
		assert_eq(int(overlay_snapshot.get("rows", 0)), 3)
		assert_eq(int(overlay_snapshot.get("cell_count", 0)), 12)
		assert_eq(float(overlay_snapshot.get("cell_width", 0.0)), 0.08)
		assert_eq(float(overlay_snapshot.get("cell_height", 0.0)), 0.14197952218430035)
		assert_eq(int(overlay_snapshot.get("dashed_line_count", 0)), 7)
		assert_eq(int(overlay_snapshot.get("strike_subgrid", {}).get("columns", 0)), 8)
		assert_eq(int(overlay_snapshot.get("strike_subgrid", {}).get("rows", 0)), 6)
		assert_eq(int(nose_chart.get("active_index")), 6)
		if packed_scene == FlowProvingScene:
			assert_eq(int(nose_direction_chart.get("active_index")), 2)
		assert_eq(int(left_chart.get("active_index")), 7)
		assert_eq(int(right_chart.get("active_index")), 4)
		assert_eq(String(truth_label.text), "")

func test_flow_proving_scene_placement_cards_mirror_columns_only_for_preview() -> void:
	var scene_root: Control = add_child_autoqfree(FlowProvingScene.instantiate()) as Control
	assert_not_null(scene_root)
	for chart_name: String in ["NosePlacementChart", "LeftPlacementChart", "RightPlacementChart"]:
		var chart := scene_root.find_child(chart_name, true, false) as Control
		assert_not_null(chart)
		assert_eq(bool(chart.get("mirror_placement_columns_for_preview")), true)
		assert_eq(int(chart.call("_gameplay_cell_index_for_visual_slot", 0, 0)), 3)
		assert_eq(int(chart.call("_gameplay_cell_index_for_visual_slot", 0, 3)), 0)
		assert_eq(int(chart.call("_gameplay_cell_index_for_visual_slot", 2, 0)), 11)
		assert_eq(int(chart.call("_gameplay_cell_index_for_visual_slot", 2, 3)), 8)

func test_flow_proving_scene_nose_direction_chart_updates_live_with_successive_debug_truth() -> void:
	var scene_root: Control = add_child_autoqfree(FlowProvingScene.instantiate()) as Control
	assert_not_null(scene_root)
	var nose_direction_chart := scene_root.find_child("NoseDirectionChart", true, false) as Control
	assert_not_null(nose_direction_chart)
	scene_root.set("_latest_state", _shared_flow_grid_truth_state())
	scene_root.call("_refresh_debug_panels")
	assert_eq(int(nose_direction_chart.get("active_index")), 2)

	var updated_state := _shared_flow_grid_truth_state().duplicate(true)
	var gesture_debug: Dictionary = updated_state.get("gesture_debug", {})
	var flow_debug: Dictionary = gesture_debug.get("flow", {})
	var tracked_landmarks: Dictionary = flow_debug.get("tracked_landmarks", {})
	var nose_debug: Dictionary = tracked_landmarks.get("nose", {})
	nose_debug["current_direction"] = 3
	tracked_landmarks["nose"] = nose_debug
	flow_debug["tracked_landmarks"] = tracked_landmarks
	gesture_debug["flow"] = flow_debug
	updated_state["gesture_debug"] = gesture_debug
	scene_root.set("_latest_state", updated_state)
	scene_root.call("_refresh_debug_panels")
	assert_eq(int(nose_direction_chart.get("active_index")), 3)

func test_flow_proving_scene_text_describes_previous_cell_entry_truth_for_nose_and_wrists() -> void:
	var scene_root: Control = add_child_autoqfree(FlowProvingScene.instantiate()) as Control
	assert_not_null(scene_root)
	var state := _shared_flow_grid_truth_state()
	var gesture_debug: Dictionary = state.get("gesture_debug", {})
	var flow_debug: Dictionary = gesture_debug.get("flow", {})
	var tracked_landmarks: Dictionary = flow_debug.get("tracked_landmarks", {})
	var nose_debug: Dictionary = tracked_landmarks.get("nose", {})
	nose_debug["cell_meta"] = {
		"previous_cell": 5,
		"current_cell": 6,
		"direction": 2,
		"direction_source": "previous_cell_entry",
	}
	tracked_landmarks["nose"] = nose_debug
	flow_debug["tracked_landmarks"] = tracked_landmarks
	var left_flow: Dictionary = flow_debug.get("left", {})
	left_flow["cell_meta"] = {
		"previous_cell": 6,
		"current_cell": 7,
		"direction": 0,
		"direction_source": "previous_cell_entry",
	}
	flow_debug["left"] = left_flow
	var right_flow: Dictionary = flow_debug.get("right", {})
	right_flow["cell_meta"] = {
		"previous_cell": 5,
		"current_cell": 4,
		"direction": 3,
		"direction_source": "previous_cell_entry",
	}
	flow_debug["right"] = right_flow
	gesture_debug["flow"] = flow_debug
	state["gesture_debug"] = gesture_debug
	scene_root.set("_latest_state", state)
	var signal_text := String(scene_root.call("_build_flow_signal_text"))
	var metrics_text := String(scene_root.call("_build_metrics_text"))
	assert_string_contains(signal_text, "previous entered cell -> current entered cell direction on nose and wrists")
	assert_string_contains(signal_text, "Nose")
	assert_string_contains(signal_text, "entry truth: cell 5 [r1 c1] -> cell 6 [r1 c2]")
	assert_string_contains(metrics_text, "Flow direction truth for nose and wrists is previous entered cell -> current entered cell")
	assert_string_contains(metrics_text, "Nose")

func test_flow_grid_overlay_flips_gameplay_y_and_renders_calibrated_cell_dimensions_in_preview_space() -> void:
	var scene_root: Control = add_child_autoqfree(BoxingProvingScene.instantiate()) as Control
	assert_not_null(scene_root)
	var presenter := add_child_autoqfree(FakePreviewPresenter.new()) as FakePreviewPresenter
	scene_root.set("_preview_presenter", presenter)
	scene_root.set("_latest_state", _shared_flow_grid_truth_state())
	scene_root.call("_sync_overlay_drawers_to_preview_presenter")
	scene_root.call("_refresh_debug_panels")

	var refs: Dictionary = scene_root.call("get_shared_flow_grid_truth_refs")
	var overlay := refs.get("flow_grid_overlay", null) as Object
	assert_not_null(overlay)
	var overlay_snapshot: Dictionary = overlay.call("get_overlay_snapshot")
	var render_top_left: Vector2 = overlay_snapshot.get("render_top_left", Vector2.ZERO)
	assert_true(is_equal_approx(render_top_left.x, 176.8))
	assert_true(is_equal_approx(render_top_left.y, 46.88))
	assert_true(is_equal_approx(float(overlay_snapshot.get("render_cell_width_px", 0.0)), 41.6))
	assert_true(is_equal_approx(float(overlay_snapshot.get("render_cell_height_px", 0.0)), 41.6))
	assert_true(is_equal_approx(float(overlay_snapshot.get("render_width_px", 0.0)), 166.4))
	assert_true(is_equal_approx(float(overlay_snapshot.get("render_height_px", 0.0)), 124.8))

func test_flow_grid_overlay_preserves_unclamped_render_truth_when_cover_crops_the_preview() -> void:
	var overlay := add_child_autoqfree(load("res://scripts/flow_grid_overlay.gd").new()) as Control
	assert_not_null(overlay)
	overlay.size = Vector2(520.0, 293.0)
	var presenter := add_child_autoqfree(FakeCoverPreviewPresenter.new()) as FakeCoverPreviewPresenter
	overlay.call("set_preview_presenter", presenter)
	overlay.call("update_grid_debug", {
		"is_calibrated": true,
		"columns": 4,
		"rows": 3,
		"coordinate_space": "gameplay_bottom_left",
		"cell_width": 0.13784825,
		"cell_height": 0.16699933,
		"width": 0.551393,
		"height": 0.500998,
		"left_boundary": 0.225,
		"top_boundary": 1.0,
		"right_boundary": 0.776393,
		"bottom_boundary": 0.499002,
	})
	var snapshot: Dictionary = overlay.call("get_overlay_snapshot")
	assert_true(is_equal_approx(float(snapshot.get("render_width_px", 0.0)), 551.393))
	assert_true(is_equal_approx(float(snapshot.get("render_height_px", 0.0)), 146.792414))
	assert_true(is_equal_approx(float(snapshot.get("visible_width_px", 0.0)), 495.0))
	assert_true(is_equal_approx(float(snapshot.get("visible_height_px", 0.0)), 146.792414))
	assert_eq(bool(snapshot.get("visible_clipped", false)), true)
	var render_top_left: Vector2 = snapshot.get("render_top_left", Vector2.ZERO)
	assert_true(is_equal_approx(render_top_left.x, 25.0))
	assert_true(is_equal_approx(render_top_left.y, 0.0))
	var visible_top_left: Vector2 = snapshot.get("visible_top_left", Vector2.ZERO)
	assert_true(is_equal_approx(visible_top_left.x, 25.0))
	assert_true(is_equal_approx(visible_top_left.y, 0.0))

func test_flow_ring_chart_defaults_to_direct_athlete_space_visual_slots() -> void:
	var chart := add_child_autoqfree(FlowRingChartScript.new()) as Control
	assert_not_null(chart)
	assert_eq(bool(chart.get("mirror_placement_columns_for_preview")), false)
	assert_eq(int(chart.call("_gameplay_cell_index_for_visual_slot", 0, 0)), 0)
	assert_eq(int(chart.call("_gameplay_cell_index_for_visual_slot", 0, 3)), 3)
	assert_eq(int(chart.call("_gameplay_cell_index_for_visual_slot", 1, 0)), 4)
	assert_eq(int(chart.call("_gameplay_cell_index_for_visual_slot", 1, 3)), 7)
	assert_eq(int(chart.call("_gameplay_cell_index_for_visual_slot", 2, 0)), 8)
	assert_eq(int(chart.call("_gameplay_cell_index_for_visual_slot", 2, 3)), 11)
	assert_eq(int(chart.call("_athlete_space_cell_index_for_visual_slot", 0, 0)), 0)
	assert_eq(int(chart.call("_athlete_space_cell_index_for_visual_slot", 2, 3)), 11)

func test_flow_ring_chart_can_mirror_columns_for_preview_space() -> void:
	var chart := add_child_autoqfree(FlowRingChartScript.new()) as Control
	assert_not_null(chart)
	chart.set("mirror_placement_columns_for_preview", true)
	assert_eq(int(chart.call("_gameplay_cell_index_for_visual_slot", 0, 0)), 3)
	assert_eq(int(chart.call("_gameplay_cell_index_for_visual_slot", 0, 3)), 0)
	assert_eq(int(chart.call("_gameplay_cell_index_for_visual_slot", 1, 0)), 7)
	assert_eq(int(chart.call("_gameplay_cell_index_for_visual_slot", 1, 3)), 4)
	assert_eq(int(chart.call("_gameplay_cell_index_for_visual_slot", 2, 0)), 11)
	assert_eq(int(chart.call("_gameplay_cell_index_for_visual_slot", 2, 3)), 8)
	assert_eq(int(chart.call("_athlete_space_cell_index_for_visual_slot", 0, 0)), 3)
	assert_eq(int(chart.call("_athlete_space_cell_index_for_visual_slot", 2, 3)), 8)

func test_proving_harness_formats_flow_cells_in_athlete_space_row_and_column_order() -> void:
	var scene_root: Control = add_child_autoqfree(BoxingProvingScene.instantiate()) as Control
	assert_not_null(scene_root)
	assert_eq(String(scene_root.call("_fmt_flow_cell", 0)), "cell 0 [r0 c0]")
	assert_eq(String(scene_root.call("_fmt_flow_cell", 4)), "cell 4 [r1 c0]")
	assert_eq(String(scene_root.call("_fmt_flow_cell", 8)), "cell 8 [r2 c0]")
	assert_eq(String(scene_root.call("_fmt_flow_cell", 11)), "cell 11 [r2 c3]")

func test_boxing_proving_scene_places_shared_grid_cards_inside_board_grid_with_boxing_shell_style() -> void:
	var scene_root: Control = add_child_autoqfree(BoxingProvingScene.instantiate()) as Control
	assert_not_null(scene_root)
	assert_null(scene_root.find_child("GridTruthPanel", true, false))
	var board_grid := scene_root.find_child("BoardGrid", true, false) as GridContainer
	var nose_card := scene_root.find_child("NosePlacementCard", true, false) as PanelContainer
	var left_card := scene_root.find_child("LeftPlacementCard", true, false) as PanelContainer
	var right_card := scene_root.find_child("RightPlacementCard", true, false) as PanelContainer
	var nose_chart := scene_root.find_child("NosePlacementChart", true, false) as Control
	assert_not_null(board_grid)
	assert_not_null(nose_card)
	assert_not_null(left_card)
	assert_not_null(right_card)
	assert_not_null(nose_chart)
	assert_eq(bool(nose_chart.get("mirror_placement_columns_for_preview")), false)
	assert_eq(int(nose_chart.call("_gameplay_cell_index_for_visual_slot", 0, 0)), 0)
	assert_eq(int(nose_chart.call("_gameplay_cell_index_for_visual_slot", 0, 3)), 3)
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
		scene_root.prerecorded_video_source = "res://fixtures/replay-auto-bootstrap.mp4"
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

func test_proving_scenes_start_contract_preview_immediately_and_release_singleton_runtime_on_exit() -> void:
	var singleton: Variant = _install_root_camera_tracking_singleton()
	assert_not_null(singleton)
	var scene_root: Control = add_child_autoqfree(BoxingProvingScene.instantiate()) as Control
	assert_not_null(scene_root)
	await get_tree().process_frame
	await get_tree().process_frame
	assert_not_null(scene_root.get("_preview_presenter"))
	assert_true(bool(singleton.get_current_preview_descriptor().get("attached", false)))
	assert_true(bool(scene_root.call("_is_live_camera_runtime_ready")))
	assert_not_null(singleton.get_tracking_session_if_ready())

	scene_root.queue_free()
	await get_tree().process_frame
	await get_tree().process_frame
	assert_null(singleton.get_tracking_session_if_ready())
	assert_null(singleton.get_node_or_null("CameraTracking"))
	assert_null(singleton.get_node_or_null("CameraTrackingProvider"))

func harness_set_provider(scene_root: Control, provider: Node) -> void:
	add_child_autoqfree(provider)
	scene_root.set("provider", provider)

func test_proving_harness_surfaces_shared_auto_calibration_success_truthfully_for_live_sources() -> void:
	var scene_root: Control = _new_live_calibration_harness() as Control
	assert_not_null(scene_root)
	var provider := FakeAthleteRecalibrateProvider.new()
	harness_set_provider(scene_root, provider)
	assert_null(scene_root.find_child("AthleteCalibrationPanel", true, false))

	provider.baseline = {
		"is_calibrated": true,
		"sample_frames": 1,
		"grid_width": 0.520000,
		"grid_height": 0.520000,
	}
	provider.calibration_session = provider._make_session("succeeded", {
		"result": "succeeded",
		"captured_sample_frames": 1,
		"captured_at_ms": 2500,
		"instruction_text": "T-pose auto-calibration is live. Hold the pose again after cooldown to re-sample.",
	})
	scene_root.set("_latest_state", provider.get_detector_state())
	scene_root.call("_refresh_calibration_flow_ui")
	assert_eq(scene_root.call("_event_count", "athlete_calibration_succeeded"), 1)
	var event_lines: Array = scene_root.get("_event_lines")
	assert_true(String(event_lines[event_lines.size() - 1]).ends_with("calibrated_grid width=0.520000 height=0.520000"))

func test_calibration_success_echoes_copy_paste_grid_line_to_console() -> void:
	var harness: ConsoleCaptureHarness = _new_console_capture_harness()
	harness._append_event_feed_lines("athlete_calibration_succeeded", {
		"grid_width": 0.520000,
		"grid_height": 0.520000,
	})
	assert_eq_deep(harness.console_lines, ["calibrated_grid width=0.520000 height=0.520000"])
	var event_lines: Array = harness.get("_event_lines")
	assert_true(String(event_lines[event_lines.size() - 1]).ends_with("calibrated_grid width=0.520000 height=0.520000"))

func test_proving_scenes_mount_t_pose_badge_in_preview_overlay_and_show_live_hold_progress() -> void:
	for packed_scene_variant: Variant in [BoxingProvingScene, FlowProvingScene]:
		var packed_scene := packed_scene_variant as PackedScene
		var scene_root: Control = add_child_autoqfree(packed_scene.instantiate()) as Control
		assert_not_null(scene_root)
		var presenter := add_child_autoqfree(FakePreviewPresenter.new()) as FakePreviewPresenter
		scene_root.set("_preview_presenter", presenter)
		scene_root.call("_sync_overlay_drawers_to_preview_presenter")
		scene_root.set("_latest_state", {
			"baseline": {"is_calibrated": true, "capture_source": "calibration_session", "sample_frames": 1},
			"calibration_session": _make_test_calibration_session("holding", {
				"hold_progress_ms": 375,
				"hold_progress_ratio": 0.5,
				"hold_started_at_ms": 2222,
				"readiness": {
					"tracking_ready": true,
					"required_landmarks_ready": true,
					"horizontal_alignment_ready": true,
					"arm_extension_ready": true,
					"qualified": true,
					"hold_ready": false,
					"ready": false,
					"hold_ms": 750,
					"hold_progress_ms": 375,
					"hold_progress_ratio": 0.5,
					"cooldown_ms": 1000,
					"cooldown_remaining_ms": 0,
					"required_landmarks": {
						"nose": true,
						"left_shoulder": true,
						"right_shoulder": true,
						"left_elbow": true,
						"right_elbow": true,
						"left_wrist": true,
						"right_wrist": true,
					},
					"thresholds": {
						"max_wrist_shoulder_y_ratio": 0.12,
						"max_elbow_shoulder_y_ratio": 0.10,
						"min_elbow_angle_deg": 165.0,
					},
					"measurements": {
						"shoulder_width": 0.36,
						"left_wrist_shoulder_y_ratio": 0.04,
						"right_wrist_shoulder_y_ratio": 0.03,
						"left_elbow_shoulder_y_ratio": 0.02,
						"right_elbow_shoulder_y_ratio": 0.02,
						"left_arm_extension": 0.98,
						"right_arm_extension": 0.97,
						"left_elbow_bend_deg": 176.0,
						"right_elbow_bend_deg": 174.0,
						"calibration_width": 0.52,
						"calibration_height": 0.52,
					},
				},
			}),
		})
		scene_root.call("_refresh_calibration_flow_ui")
		var badge := presenter.get_overlay_layer().get_node_or_null("TPoseCalibrationBadge") as Control
		assert_not_null(badge)
		assert_same(badge.get_parent(), presenter.get_overlay_layer())
		var badge_snapshot: Dictionary = scene_root.call("get_t_pose_badge_snapshot")
		assert_true(bool(badge_snapshot.get("progress_active", false)))
		assert_true(is_equal_approx(float(badge_snapshot.get("fill_ratio", 0.0)), 0.5))
		assert_true(is_equal_approx(float(badge_snapshot.get("displayed_fill_ratio", 0.0)), 0.0))
		assert_true(bool(badge_snapshot.get("tween_active", false)))
		await get_tree().process_frame
		badge_snapshot = scene_root.call("get_t_pose_badge_snapshot")
		assert_true(float(badge_snapshot.get("displayed_fill_ratio", 0.0)) <= float(badge_snapshot.get("fill_ratio", 0.0)))
		assert_eq(badge.custom_minimum_size, Vector2(75.0, 75.0))

		scene_root.set("_latest_state", {
			"baseline": {"is_calibrated": true, "capture_source": "calibration_session", "sample_frames": 1},
			"calibration_session": _make_test_calibration_session("cooldown", {
				"hold_progress_ms": 0,
				"hold_progress_ratio": 0.0,
				"cooldown_remaining_ms": 640,
				"failure_reason": "cooldown_active",
				"instruction_text": "Auto-calibration is cooling down — wait for unlock, then hold a fresh T-pose to re-fire",
			}),
		})
		scene_root.call("_refresh_calibration_flow_ui")
		badge_snapshot = scene_root.call("get_t_pose_badge_snapshot")
		assert_false(bool(badge_snapshot.get("progress_active", true)))
		assert_true(bool(badge_snapshot.get("cooldown_active", false)))
		assert_true(is_equal_approx(float(badge_snapshot.get("fill_ratio", 1.0)), 0.0))
		var idle_color: Color = badge_snapshot.get("idle_color", Color.WHITE)
		assert_true(idle_color.a < 0.58)
		var icon_modulate: Color = badge_snapshot.get("icon_modulate", Color.WHITE)
		assert_true(icon_modulate.a < 0.96)

func test_clicking_t_pose_badge_opens_live_calibration_inspector_truth() -> void:
	var scene_root: Control = add_child_autoqfree(BoxingProvingScene.instantiate()) as Control
	assert_not_null(scene_root)
	var presenter := add_child_autoqfree(FakePreviewPresenter.new()) as FakePreviewPresenter
	scene_root.set("_preview_presenter", presenter)
	scene_root.call("_sync_overlay_drawers_to_preview_presenter")
	scene_root.set("_latest_state", {
		"tracking_state": "tracking",
		"baseline": {"is_calibrated": true, "capture_source": "calibration_session", "sample_frames": 1},
		"calibration_session": _make_test_calibration_session("holding", {
			"hold_progress_ms": 375,
			"hold_progress_ratio": 0.5,
			"hold_started_at_ms": 2222,
			"instruction_text": "Hold the T-pose steady to finish auto-calibration",
			"readiness": {
				"tracking_ready": true,
				"required_landmarks_ready": true,
				"horizontal_alignment_ready": false,
				"arm_extension_ready": true,
				"qualified": false,
				"hold_ready": false,
				"ready": false,
				"hold_ms": 750,
				"hold_progress_ms": 375,
				"hold_progress_ratio": 0.5,
				"cooldown_ms": 1000,
				"cooldown_remaining_ms": 0,
				"failure_reason": "arms_not_horizontal",
				"required_landmarks": {
					"nose": true,
					"left_shoulder": true,
					"right_shoulder": true,
					"left_elbow": true,
					"right_elbow": true,
					"left_wrist": true,
					"right_wrist": true,
				},
				"thresholds": {
					"max_wrist_shoulder_y_ratio": 0.12,
					"max_elbow_shoulder_y_ratio": 0.10,
					"min_elbow_angle_deg": 165.0,
				},
				"measurements": {
					"shoulder_width": 0.36,
					"left_wrist_shoulder_y_ratio": 0.18,
					"right_wrist_shoulder_y_ratio": 0.03,
					"left_elbow_shoulder_y_ratio": 0.11,
					"right_elbow_shoulder_y_ratio": 0.02,
					"left_arm_extension": 0.98,
					"right_arm_extension": 0.97,
					"left_elbow_bend_deg": 176.0,
					"right_elbow_bend_deg": 174.0,
					"calibration_width": 0.52,
					"calibration_height": 0.52,
				},
			},
		}),
	})
	scene_root.call("_refresh_calibration_flow_ui")
	var badge := presenter.get_overlay_layer().get_node_or_null("TPoseCalibrationBadge") as Control
	assert_not_null(badge)
	badge.emit_signal("pressed")
	var inspector := scene_root.get("_shared_inspector_panel") as Control
	assert_not_null(inspector)
	assert_true(bool(inspector.visible))
	assert_eq(String(scene_root.get("_shared_inspector_target_type")), "calibration")
	assert_eq(String(scene_root.get("_shared_inspector_target_key")), "t_pose_auto")
	var body_label := scene_root.get("_shared_inspector_body_label") as RichTextLabel
	assert_not_null(body_label)
	assert_string_contains(body_label.text, "Requirement truth")
	assert_string_contains(body_label.text, "[ ] Arms are horizontal enough")
	assert_string_contains(body_label.text, "Elbows are straight enough")
	assert_false(body_label.text.contains("min_arm_extension_ratio"))
	assert_string_contains(body_label.text, "current=375 ms, needed=750 ms")
	assert_false(body_label.text.contains("T-pose auto-calibration live truth"))
	assert_false(body_label.text.contains("Hold progress:"))
	assert_false(body_label.text.contains("max_wrist_shoulder_y_ratio=0.120"))

func test_boxing_punch_tile_uses_live_triggered_state_instead_of_event_pulse() -> void:
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
	harness._update_tile_states()
	var punch_tile: Dictionary = harness.get("_tile_refs").get("punch", {})
	var left_badge: Dictionary = punch_tile.get("left", {})
	assert_eq(String(left_badge.get("style_key", "")), "active")

func test_boxing_punch_tile_does_not_linger_on_old_event_once_live_state_is_not_ready() -> void:
	var scene_root: Control = add_child_autoqfree(BoxingProvingScene.instantiate()) as Control
	var harness := scene_root as Object
	harness.set("_latest_state", {
		"gesture_debug": {
			"straight_punch": {
				"left": {
					"state": "not_ready",
					"hand_tracking_enabled": false,
					"pose_tracking_valid": true,
					"tracking_state": "pose_tracked",
					"tracking_valid": true,
					"sample_source": "pose",
				}
			}
		}
	})
	harness._record_event("punch_left", {"power": 0.75})
	harness._update_tile_states()
	var punch_tile: Dictionary = harness.get("_tile_refs").get("punch", {})
	var left_badge: Dictionary = punch_tile.get("left", {})
	assert_eq(String(left_badge.get("style_key", "")), "idle")
	assert_eq(harness._event_count("punch_left"), 1)

func test_boxing_hook_tile_uses_live_triggered_state_instead_of_event_pulse() -> void:
	var scene_root: Control = add_child_autoqfree(BoxingProvingScene.instantiate()) as Control
	var harness := scene_root as Object
	harness.set("_latest_state", {
		"gesture_debug": {
			"hook": {
				"right": {
					"state": "triggered",
					"pose_tracking_valid": true,
					"tracking_state": "pose_tracked",
					"tracking_valid": true,
					"sample_source": "pose",
				}
			}
		}
	})
	harness._record_event("hook_right", {"power": 0.80})
	harness._update_tile_states()
	var hook_tile: Dictionary = harness.get("_tile_refs").get("hook", {})
	var right_badge: Dictionary = hook_tile.get("right", {})
	assert_eq(String(right_badge.get("style_key", "")), "active")

func test_boxing_uppercut_tile_uses_live_triggered_state_instead_of_event_pulse() -> void:
	var scene_root: Control = add_child_autoqfree(BoxingProvingScene.instantiate()) as Control
	var harness := scene_root as Object
	harness.set("_latest_state", {
		"gesture_debug": {
			"uppercut": {
				"left": {
					"state": "triggered",
					"pose_tracking_valid": true,
					"tracking_state": "pose_tracked",
					"tracking_valid": true,
					"sample_source": "pose",
				}
			}
		}
	})
	harness._record_event("uppercut_left", {"power": 0.78})
	harness._update_tile_states()
	var uppercut_tile: Dictionary = harness.get("_tile_refs").get("uppercut", {})
	var left_badge: Dictionary = uppercut_tile.get("left", {})
	assert_eq(String(left_badge.get("style_key", "")), "active")

func test_boxing_weave_tile_uses_held_state_instead_of_entry_pulse() -> void:
	var scene_root: Control = add_child_autoqfree(BoxingProvingScene.instantiate()) as Control
	var harness := scene_root as Object
	harness.set("_latest_state", {
		"gesture_states": {
			"weave_left": true,
			"weave_right": false,
		}
	})
	harness._update_tile_states()
	var weave_tile: Dictionary = harness.get("_tile_refs").get("weave", {})
	var left_badge: Dictionary = weave_tile.get("left", {})
	var right_badge: Dictionary = weave_tile.get("right", {})
	assert_eq(String(left_badge.get("style_key", "")), "active")
	assert_eq(String(right_badge.get("style_key", "")), "idle")

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

func test_boxing_punch_hover_card_keeps_live_rows_fresh_while_preserving_latest_state_change_snapshot() -> void:
	var harness = _new_harness()
	harness.set("_latest_state", {
		"gesture_debug": {
			"straight_punch": {
				"left": {
					"state": "ready",
					"hand_tracking_enabled": false,
					"pose_tracking_valid": true,
					"tracking_state": "pose_tracked",
					"tracking_valid": true,
					"sample_source": "pose",
					"fresh_sample": false,
					"wrist_velocity": 0.0,
					"recent_peak_wrist_velocity": 0.0,
					"min_velocity": 0.180,
					"elbow_shoulder_xy_distance": 0.010,
					"max_elbow_shoulder_xy_distance": 0.090,
					"elbow_shoulder_xy_gate_passed": true,
					"wrist_lateral_angle_from_elbow_vertical_deg": 18.0,
					"min_wrist_lateral_angle_from_elbow_vertical_deg": 15.0,
					"wrist_lateral_angle_gate_passed": true,
					"grace_ms_remaining": 0,
					"triggered_grace_ms": 240,
					"pose_only_rearm_ms": 250,
					"reacquire_stable_ms_required": 40,
				},
			}
		}
	})
	harness.set("_straight_punch_transition_debug", {
		"left": {
			"state": "triggered",
			"previous_state": "ready",
			"timestamp_ms": Time.get_ticks_msec() - 80,
			"hand_tracking_enabled": false,
			"pose_tracking_valid": true,
			"tracking_state": "pose_tracked",
			"sample_source": "pose",
			"tracking_valid": true,
			"fresh_sample": true,
			"wrist_velocity": 0.280,
			"recent_peak_wrist_velocity": 0.280,
			"elbow_shoulder_xy_distance": 0.082,
			"max_elbow_shoulder_xy_distance": 0.090,
			"elbow_shoulder_xy_gate_passed": true,
			"wrist_shoulder_xy_distance": 0.124,
			"max_wrist_shoulder_xy_distance": 0.180,
			"wrist_shoulder_xy_gate_passed": true,
			"wrist_lateral_angle_from_elbow_vertical_deg": 0.0,
			"min_wrist_lateral_angle_from_elbow_vertical_deg": 15.0,
			"wrist_lateral_angle_gate_passed": false,
			"grace_ms_remaining": 240,
		},
		"right": {},
	})

	var model: Dictionary = harness._build_hover_card_model("punch_left")
	var rows: Array = model.get("rows", [])
	assert_string_contains(String(rows[1].get("current_text", "")), "ready")
	assert_string_contains(String(rows[2].get("current_text", "")), "pose_valid=true, tracking=pose_tracked, source=pose")
	assert_string_contains(String(rows[4].get("current_text", "")), "ready -> triggered")
	assert_eq(String(rows[5].get("current_text", "")), "state=triggered wrist=0.280 peak=0.280 elbow_xy=0.082<=0.090 (true) wrist_xy=0.124<=0.180 (true) angle=0.000>=15.000 (false) fresh=true source=pose grace=240ms pose_valid=true")
