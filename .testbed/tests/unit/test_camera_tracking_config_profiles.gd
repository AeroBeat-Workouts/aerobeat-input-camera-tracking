extends "res://addons/aerobeat-vendor-godot-unit-test/test.gd"

const CameraTrackingConfigScript = preload("res://addons/aerobeat-input-camera-tracking/src/config/camera_tracking_config.gd")
const ProfileConfigLoaderScript = preload("res://addons/aerobeat-input-camera-tracking/src/config/profile_config_loader.gd")

func test_camera_tracking_config_loads_boxing_profile_bundle_from_canonical_paths() -> void:
	var config = CameraTrackingConfigScript.new()
	var bundle: Dictionary = config.get_selected_profile_bundle()

	assert_true(bool(bundle.get("ok", false)))
	assert_eq(String(bundle.get("profile", "")), "boxing")
	assert_true(String(bundle.get("camera_tracking_path", "")).ends_with("assets/boxing.camera_tracking.yaml"))
	assert_true(String(bundle.get("gesture_detection_path", "")).ends_with("assets/boxing.gesture_detection.yaml"))
	assert_true(String(bundle.get("testbed_debug_path", "")).ends_with("assets/boxing.testbed_debug.yaml"))
	assert_eq(String(bundle.get("camera_tracking", {}).get("schema", "")), ProfileConfigLoaderScript.CAMERA_TRACKING_SCHEMA)
	assert_eq(int(bundle.get("camera_tracking", {}).get("version", -1)), ProfileConfigLoaderScript.CONFIG_VERSION)
	assert_eq(String(bundle.get("camera_tracking", {}).get("profile", "")), "boxing")
	assert_eq(String(bundle.get("gesture_detection", {}).get("schema", "")), ProfileConfigLoaderScript.GESTURE_DETECTION_SCHEMA)
	assert_eq(int(bundle.get("gesture_detection", {}).get("version", -1)), ProfileConfigLoaderScript.CONFIG_VERSION)
	assert_eq(String(bundle.get("gesture_detection", {}).get("profile", "")), "boxing")
	assert_eq(String(bundle.get("testbed_debug", {}).get("schema", "")), ProfileConfigLoaderScript.TESTBED_DEBUG_SCHEMA)
	assert_eq(int(bundle.get("testbed_debug", {}).get("version", -1)), ProfileConfigLoaderScript.CONFIG_VERSION)
	assert_eq(String(bundle.get("testbed_debug", {}).get("profile", "")), "boxing")
	assert_eq(int(bundle.get("camera_tracking", {}).get("tracking", {}).get("max_fps", -1)), 30)
	assert_eq(int(bundle.get("camera_tracking", {}).get("tracking", {}).get("state_update_max_fps", -1)), 10)
	assert_true(bool(bundle.get("camera_tracking", {}).get("tracking", {}).get("pose", {}).get("enabled", false)))
	assert_eq(int(bundle.get("camera_tracking", {}).get("tracking", {}).get("pose", {}).get("inference_interval_frames", -1)), 1)
	assert_eq(String(bundle.get("camera_tracking", {}).get("preview", {}).get("surface_mode", "")), "attach")
	assert_true(bool(bundle.get("camera_tracking", {}).get("preview", {}).get("live", {}).get("enabled", false)))
	assert_true(bool(bundle.get("camera_tracking", {}).get("preview", {}).get("replay", {}).get("enabled", false)))
	assert_eq(int(bundle.get("camera_tracking", {}).get("preview", {}).get("live", {}).get("max_fps", -1)), 60)
	assert_eq(int(bundle.get("camera_tracking", {}).get("preview", {}).get("replay", {}).get("width", -1)), 960)
	assert_true(bool(bundle.get("camera_tracking", {}).get("preview", {}).get("overlays", {}).get("pose_skeleton_visible", false)))
	assert_eq(int(bundle.get("camera_tracking", {}).get("source", {}).get("live_camera", {}).get("requested_width", -1)), 960)
	assert_eq(int(bundle.get("camera_tracking", {}).get("source", {}).get("live_camera", {}).get("requested_height", -1)), 540)
	assert_eq(int(bundle.get("camera_tracking", {}).get("source", {}).get("live_camera", {}).get("requested_fps", -1)), 60)
	assert_eq(String(bundle.get("camera_tracking", {}).get("source", {}).get("replay", {}).get("input_kind", "")), "video_file")
	assert_eq(String(bundle.get("camera_tracking", {}).get("source", {}).get("replay", {}).get("video_input_path", "")), "")
	assert_eq(String(bundle.get("camera_tracking", {}).get("source", {}).get("replay", {}).get("session_manifest_path", "")), "")
	assert_true(bool(bundle.get("testbed_debug", {}).get("visuals", {}).get("show_landmarks", false)))
	assert_false(bool(bundle.get("testbed_debug", {}).get("visuals", {}).get("show_landmark_hit_targets", true)))
	assert_false(bool(bundle.get("testbed_debug", {}).get("visuals", {}).get("show_landmark_hit_target_labels", true)))
	assert_eq(int(bundle.get("testbed_debug", {}).get("refresh", {}).get("debug_panel_refresh_interval_ms", -1)), 160)
	assert_eq(int(bundle.get("testbed_debug", {}).get("refresh", {}).get("inspector_live_refresh_interval_ms", -1)), 120)
	assert_eq(String(bundle.get("gesture_detection", {}).get("guard", {}).get("backend", "")), "threshold")
	assert_eq(String(bundle.get("gesture_detection", {}).get("squat", {}).get("backend", "")), "threshold")
	assert_eq(String(bundle.get("gesture_detection", {}).get("weave", {}).get("backend", "")), "threshold")
	assert_eq(String(bundle.get("gesture_detection", {}).get("straight_punch", {}).get("backend", "")), "threshold")
	assert_eq(String(bundle.get("gesture_detection", {}).get("hook", {}).get("backend", "")), "threshold")
	assert_eq(String(bundle.get("gesture_detection", {}).get("uppercut", {}).get("backend", "")), "threshold")
	assert_eq(int(bundle.get("gesture_detection", {}).get("straight_punch", {}).get("threshold", {}).get("evaluation", {}).get("window_ms", -1)), 250)
	assert_false(bundle.get("gesture_detection", {}).get("straight_punch", {}).get("threshold", {}).get("evaluation", {}).has("wrist_velocity_window_ms"))
	assert_false(bundle.get("gesture_detection", {}).get("straight_punch", {}).get("threshold", {}).get("evaluation", {}).has("bbox_area_growth_window_ms"))
	assert_eq(int(bundle.get("gesture_detection", {}).get("hook", {}).get("threshold", {}).get("evaluation", {}).get("window_ms", -1)), 250)
	assert_false(bundle.get("gesture_detection", {}).get("hook", {}).get("threshold", {}).get("evaluation", {}).has("wrist_velocity_window_ms"))
	assert_eq(int(bundle.get("gesture_detection", {}).get("uppercut", {}).get("threshold", {}).get("evaluation", {}).get("window_ms", -1)), 250)
	assert_false(bundle.get("gesture_detection", {}).get("uppercut", {}).get("threshold", {}).get("evaluation", {}).has("wrist_velocity_window_ms"))
	assert_true(is_equal_approx(float(bundle.get("gesture_detection", {}).get("straight_punch", {}).get("threshold", {}).get("thresholds", {}).get("min_velocity", -1.0)), 0.5))
	assert_true(is_equal_approx(float(bundle.get("gesture_detection", {}).get("straight_punch", {}).get("threshold", {}).get("thresholds", {}).get("max_elbow_shoulder_xy_distance", -1.0)), 0.14))
	assert_true(is_equal_approx(float(bundle.get("gesture_detection", {}).get("straight_punch", {}).get("threshold", {}).get("thresholds", {}).get("min_wrist_lateral_angle_from_elbow_vertical_deg", -1.0)), 15.0))
	assert_false(bundle.get("gesture_detection", {}).get("straight_punch", {}).get("threshold", {}).get("thresholds", {}).has("min_forward_depth_spike"))
	assert_false(bundle.get("gesture_detection", {}).get("straight_punch", {}).get("threshold", {}).get("thresholds", {}).has("min_punch_velocity"))
	assert_false(bundle.get("gesture_detection", {}).get("straight_punch", {}).get("threshold", {}).has("depth"))
	assert_false(bundle.get("gesture_detection", {}).get("hook", {}).get("threshold", {}).has("depth"))
	assert_false(bundle.get("gesture_detection", {}).get("uppercut", {}).get("threshold", {}).has("depth"))
	assert_false(bundle.get("gesture_detection", {}).get("straight_punch", {}).get("threshold", {}).get("thresholds", {}).has("min_wrist_velocity"))
	assert_eq(int(bundle.get("gesture_detection", {}).get("straight_punch", {}).get("threshold", {}).get("rearm", {}).get("pose_only_rearm_ms", -1)), 10)
	assert_eq(int(bundle.get("gesture_detection", {}).get("straight_punch", {}).get("threshold", {}).get("state_machine", {}).get("lost_tracking_reacquire_stable_ms", -1)), 40)
	assert_false(bool(bundle.get("gesture_detection", {}).get("straight_punch", {}).has("prototype")))
	assert_false(bool(bundle.get("gesture_detection", {}).get("straight_punch", {}).has("classifier")))
	assert_false(bool(bundle.get("gesture_detection", {}).has("knee_strike")))
	assert_false(bool(bundle.get("gesture_detection", {}).has("leg_lift")))
	assert_false(bool(bundle.get("gesture_detection", {}).has("side_step")))

func test_camera_tracking_config_switches_to_flow_profile_bundle() -> void:
	var config = CameraTrackingConfigScript.new()
	var bundle: Dictionary = config.set_profile_id("flow")

	assert_true(bool(bundle.get("ok", false)))
	assert_eq(config.get_selected_profile_id(), "flow")
	assert_true(String(bundle.get("camera_tracking_path", "")).ends_with("assets/flow.camera_tracking.yaml"))
	assert_true(String(bundle.get("gesture_detection_path", "")).ends_with("assets/flow.gesture_detection.yaml"))
	assert_true(String(bundle.get("testbed_debug_path", "")).ends_with("assets/flow.testbed_debug.yaml"))
	assert_eq(String(bundle.get("camera_tracking", {}).get("profile", "")), "flow")
	assert_eq(String(bundle.get("gesture_detection", {}).get("profile", "")), "flow")
	assert_eq(String(bundle.get("testbed_debug", {}).get("profile", "")), "flow")
	assert_true(bool(bundle.get("testbed_debug", {}).get("visuals", {}).get("show_landmarks", false)))
	assert_false(bool(bundle.get("testbed_debug", {}).get("visuals", {}).get("show_landmark_hit_targets", true)))
	assert_false(bool(bundle.get("testbed_debug", {}).get("visuals", {}).get("show_landmark_hit_target_labels", true)))
	assert_eq(int(bundle.get("testbed_debug", {}).get("refresh", {}).get("debug_panel_refresh_interval_ms", -1)), 160)
	assert_eq(int(bundle.get("testbed_debug", {}).get("refresh", {}).get("inspector_live_refresh_interval_ms", -1)), 120)
	assert_eq(int(bundle.get("camera_tracking", {}).get("tracking", {}).get("max_fps", -1)), 30)
	assert_eq(int(bundle.get("camera_tracking", {}).get("tracking", {}).get("state_update_max_fps", -1)), 30)
	assert_true(bool(bundle.get("camera_tracking", {}).get("preview", {}).get("live", {}).get("enabled", false)))
	assert_true(bool(bundle.get("camera_tracking", {}).get("preview", {}).get("replay", {}).get("enabled", false)))
	assert_true(bool(bundle.get("camera_tracking", {}).get("preview", {}).get("overlays", {}).get("pose_skeleton_visible", false)))

func test_profile_config_loader_rejects_header_mismatches() -> void:
	var loader = ProfileConfigLoaderScript.new()
	var temp_path := "user://invalid.camera_tracking.yaml"
	var file := FileAccess.open(temp_path, FileAccess.WRITE)
	assert_not_null(file)
	file.store_string("schema: aerobeat/not_camera_tracking\nversion: 99\nprofile: boxing\n")
	file = null

	var result: Dictionary = loader.load_profile_document(
		temp_path,
		ProfileConfigLoaderScript.CAMERA_TRACKING_SCHEMA,
		ProfileConfigLoaderScript.CONFIG_VERSION,
		"boxing"
	)
	assert_false(bool(result.get("ok", true)))
	assert_eq(String(result.get("error_code", "")), "config_schema_mismatch")


func test_profile_config_loader_rejects_tab_indented_yaml() -> void:
	var loader = ProfileConfigLoaderScript.new()
	var temp_path := "user://tab_indented.camera_tracking.yaml"
	var file := FileAccess.open(temp_path, FileAccess.WRITE)
	assert_not_null(file)
	file.store_string("schema: aerobeat/camera_tracking_config\nversion: 1\nprofile: boxing\ntracking:\n  pose:\n\tenabled: true\n")
	file = null

	var result: Dictionary = loader.load_profile_document(
		temp_path,
		ProfileConfigLoaderScript.CAMERA_TRACKING_SCHEMA,
		ProfileConfigLoaderScript.CONFIG_VERSION,
		"boxing"
	)
	assert_false(bool(result.get("ok", true)))
	assert_eq(String(result.get("error_code", "")), "config_tab_indentation")
