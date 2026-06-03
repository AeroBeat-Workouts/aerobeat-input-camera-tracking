extends Resource

const ProfileConfigLoader = preload("res://addons/aerobeat-input-camera-tracking/src/config/profile_config_loader.gd")
const PROFILE_BOXING := "boxing"
const PROFILE_FLOW := "flow"

@export var camera_id: int = 0
@export var camera_source: String = "0"
@export var udp_port: int = 4242
@export var detection_confidence: float = 0.5
@export var tracking_confidence: float = 0.5
@export var model_complexity: int = 1
@export var flip_horizontal: bool = true
@export var smoothing_factor: float = 0.3
@export var min_visibility: float = 0.5
@export_enum("full", "optimized", "off") var tracking_overlay_mode: String = "full"
@export_range(1, 6, 1) var gesture_eval_interval_frames: int = 1
@export var track_head: bool = true
@export var track_left_hand: bool = true
@export var track_right_hand: bool = true
@export var track_left_foot: bool = false
@export var track_right_foot: bool = false
@export_enum("boxing", "flow") var profile: String = PROFILE_BOXING
@export var tracker_profile_path: String = ""
@export var gesture_profile_path: String = ""
@export var tracker_profile_document: Dictionary = {}
@export var gesture_profile_document: Dictionary = {}
@export var runtime: Dictionary = {}
@export var diagnostics: Dictionary = {}
@export var vendor: Dictionary = {}

func get_camera_source() -> String:
	var source := String(camera_source).strip_edges()
	if source.is_empty():
		return str(camera_id)
	return source

func get_camera_argument() -> Variant:
	var source := get_camera_source()
	if source.is_valid_int():
		return int(source)
	return source

func set_selected_camera_device_id(device_id: String) -> void:
	camera_source = String(device_id).strip_edges()
	if camera_source.is_valid_int():
		camera_id = int(camera_source)

func get_selected_profile_id() -> String:
	return _normalize_profile_name(profile)

func set_profile_id(profile_name: String, reload_defaults: bool = true) -> Dictionary:
	profile = _normalize_profile_name(profile_name)
	if not reload_defaults:
		return {"ok": true, "profile": profile}
	return load_selected_profile_bundle(profile)

func resolve_selected_profile_bundle_paths(profile_name: String = "") -> Dictionary:
	return ProfileConfigLoader.new().resolve_profile_bundle_paths(_normalize_profile_name(profile_name if not profile_name.is_empty() else profile))

func load_selected_profile_bundle(profile_name: String = "") -> Dictionary:
	var normalized_profile := _normalize_profile_name(profile_name if not profile_name.is_empty() else profile)
	var result := ProfileConfigLoader.new().load_profile_bundle(normalized_profile)
	if not bool(result.get("ok", false)):
		push_error("[CameraTrackingConfig] %s" % String(result.get("error", "Profile config load failed.")))
		return result
	profile = normalized_profile
	tracker_profile_path = String(result.get("camera_tracking_path", ""))
	gesture_profile_path = String(result.get("gesture_detection_path", ""))
	tracker_profile_document = (result.get("camera_tracking", {}) as Dictionary).duplicate(true)
	gesture_profile_document = (result.get("gesture_detection", {}) as Dictionary).duplicate(true)
	return get_selected_profile_bundle()

func get_selected_profile_bundle() -> Dictionary:
	if tracker_profile_document.is_empty() or gesture_profile_document.is_empty():
		return load_selected_profile_bundle(profile)
	return {
		"ok": true,
		"profile": get_selected_profile_id(),
		"camera_tracking_path": tracker_profile_path,
		"gesture_detection_path": gesture_profile_path,
		"camera_tracking": tracker_profile_document.duplicate(true),
		"gesture_detection": gesture_profile_document.duplicate(true),
	}

func _normalize_profile_name(profile_name: String) -> String:
	var normalized := profile_name.strip_edges().to_lower()
	if normalized == PROFILE_FLOW:
		return PROFILE_FLOW
	return PROFILE_BOXING
