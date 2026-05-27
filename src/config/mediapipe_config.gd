class_name MediaPipeConfig
extends Resource

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
