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
	assert_true(bool(bundle.get("camera_tracking", {}).get("tracking", {}).get("pose", {}).get("enabled", false)))
	assert_eq(int(bundle.get("camera_tracking", {}).get("tracking", {}).get("pose", {}).get("inference_interval_frames", -1)), 1)
	assert_true(bool(bundle.get("camera_tracking", {}).get("tracking", {}).get("hands", {}).get("enabled", false)))
	assert_eq(int(bundle.get("camera_tracking", {}).get("tracking", {}).get("hands", {}).get("inference_interval_frames", -1)), 1)
	assert_eq(String(bundle.get("camera_tracking", {}).get("tracking", {}).get("hands", {}).get("landmark_mode", "")), "lite")
	assert_true(bool(bundle.get("camera_tracking", {}).get("tracking", {}).get("hands", {}).get("bbox", {}).get("enabled", false)))
	assert_true(bool(bundle.get("camera_tracking", {}).get("tracking", {}).get("hands", {}).get("grace", {}).get("enabled", false)))
	assert_true(is_equal_approx(float(bundle.get("camera_tracking", {}).get("tracking", {}).get("hands", {}).get("grace", {}).get("position_decay", 0.0)), 1.0))
	assert_true(is_equal_approx(float(bundle.get("camera_tracking", {}).get("tracking", {}).get("hands", {}).get("grace", {}).get("size_decay", 0.0)), 1.0))
	assert_true(bool(bundle.get("testbed_debug", {}).get("visuals", {}).get("show_landmarks", false)))
	assert_false(bool(bundle.get("testbed_debug", {}).get("visuals", {}).get("show_trails", true)))
	assert_true(bool(bundle.get("testbed_debug", {}).get("visuals", {}).get("show_hand_bbox_overlay", false)))
	assert_false(bool(bundle.get("testbed_debug", {}).get("visuals", {}).get("show_landmark_hit_targets", true)))
	assert_false(bool(bundle.get("testbed_debug", {}).get("visuals", {}).get("show_landmark_hit_target_labels", true)))
	assert_eq(int(bundle.get("testbed_debug", {}).get("refresh", {}).get("debug_panel_refresh_interval_ms", -1)), 160)
	assert_eq(int(bundle.get("testbed_debug", {}).get("refresh", {}).get("inspector_live_refresh_interval_ms", -1)), 120)
	assert_eq(int(bundle.get("gesture_detection", {}).get("straight_punch", {}).get("evaluation", {}).get("bbox_area_growth_window_ms", -1)), 1000)
	assert_eq(int(bundle.get("gesture_detection", {}).get("straight_punch", {}).get("rearm", {}).get("pose_only_rearm_ms", -1)), 250)
	assert_eq(int(bundle.get("gesture_detection", {}).get("straight_punch", {}).get("state_machine", {}).get("lost_tracking_reacquire_stable_ms", -1)), 40)

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
	assert_true(bool(bundle.get("testbed_debug", {}).get("visuals", {}).get("show_trails", false)))
	assert_false(bool(bundle.get("testbed_debug", {}).get("visuals", {}).get("show_hand_bbox_overlay", true)))
	assert_false(bool(bundle.get("testbed_debug", {}).get("visuals", {}).get("show_landmark_hit_targets", true)))
	assert_false(bool(bundle.get("testbed_debug", {}).get("visuals", {}).get("show_landmark_hit_target_labels", true)))
	assert_eq(int(bundle.get("testbed_debug", {}).get("refresh", {}).get("debug_panel_refresh_interval_ms", -1)), 160)
	assert_eq(int(bundle.get("testbed_debug", {}).get("refresh", {}).get("inspector_live_refresh_interval_ms", -1)), 120)

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
