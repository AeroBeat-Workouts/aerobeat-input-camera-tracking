extends Control
## Shared proving harness for live Boxing / Flow detector tuning.

const MediaPipeProviderScript = preload("res://addons/aerobeat-input-camera-tracking/src/providers/mediapipe_provider.gd")
const MediaPipeCameraViewScript = preload("res://addons/aerobeat-input-camera-tracking/src/camera_view.gd")
const MediaPipeConfigScript = preload("res://addons/aerobeat-input-camera-tracking/src/config/mediapipe_config.gd")
const TRACKING_SINGLETON_NODE_NAME := "AeroCameraTracking"

const LEFT_WRIST_ID := 15
const RIGHT_WRIST_ID := 16
const LEFT_PINKY_ID := 17
const RIGHT_PINKY_ID := 18
const LEFT_INDEX_ID := 19
const RIGHT_INDEX_ID := 20
const LEFT_THUMB_ID := 21
const RIGHT_THUMB_ID := 22
const MAX_EVENT_LINES := 22
const MAX_TRAIL_POINTS := 36
const MAX_TRAIL_AGE_MS := 1800
const MAX_TRAIL_FRAME_JUMP := 0.28
const TRAIL_VISIBILITY_THRESHOLD_FLOOR := 0.18
const MAX_TRAIL_FALLBACK_SPREAD := 0.18
const MAX_TRAIL_FALLBACK_EDGE_CLAMP_OVERSHOOT := 0.05
const PLAYBACK_STATUS_POLL_INTERVAL_MS := 250
const PLAYBACK_TOGGLE_BUTTON_WIDTH := 52.0
const PLAYBACK_CONTROL_ROW_HEIGHT := 32.0
const PLAYBACK_ICON_PLAY := "▶"
const PLAYBACK_ICON_PAUSE := "⏸"
const LANDMARK_DRAWER_Z_INDEX := 20
const TRAIL_DRAWER_Z_INDEX := 19
const INSPECTOR_LIVE_REFRESH_INTERVAL_MS := 120
const INSPECTOR_PANEL_WIDTH := 520.0
const INSPECTOR_PANEL_MARGIN := 20.0
const INSPECTOR_CLOSE_BUTTON_WIDTH := 32.0
const INSPECTOR_FOOTER_TEXT := "Click away to close"
const LANDMARK_NAMES := [
	"Nose",
	"Left Eye Inner",
	"Left Eye",
	"Left Eye Outer",
	"Right Eye Inner",
	"Right Eye",
	"Right Eye Outer",
	"Left Ear",
	"Right Ear",
	"Mouth Left",
	"Mouth Right",
	"Left Shoulder",
	"Right Shoulder",
	"Left Elbow",
	"Right Elbow",
	"Left Wrist",
	"Right Wrist",
	"Left Pinky",
	"Right Pinky",
	"Left Index",
	"Right Index",
	"Left Thumb",
	"Right Thumb",
	"Left Hip",
	"Right Hip",
	"Left Knee",
	"Right Knee",
	"Left Ankle",
	"Right Ankle",
	"Left Heel",
	"Right Heel",
	"Left Foot Index",
	"Right Foot Index",
]
const LANDMARK_BODY_PART_HINTS := {
	11: &"left_shoulder",
	12: &"right_shoulder",
	13: &"left_elbow",
	14: &"right_elbow",
	15: &"left_hand",
	16: &"right_hand",
	23: &"left_hip",
	24: &"right_hip",
	27: &"left_foot",
	28: &"right_foot",
	0: &"head",
}

const BOXING_EVENT_ORDER := [
	"punch_left",
	"punch_right",
	"hook_left",
	"hook_right",
	"uppercut_left",
	"uppercut_right",
	"guard_start",
	"guard_end",
	"squat_start",
	"squat_end",
	"weave_left_start",
	"weave_left_end",
	"weave_right_start",
	"weave_right_end",
	"sidestep_left_start",
	"sidestep_left_end",
	"sidestep_right_start",
	"sidestep_right_end",
	"knee_left",
	"knee_right",
	"leg_lift_left_start",
	"leg_lift_left_end",
	"leg_lift_right_start",
	"leg_lift_right_end",
]

const FLOW_EVENT_ORDER := [
	"swing_left",
	"swing_right",
	"trail_left",
	"trail_right",
]

const BOXING_ATTACK_EVENTS := [
	"punch_left",
	"punch_right",
	"hook_left",
	"hook_right",
	"uppercut_left",
	"uppercut_right",
]

const BOXING_KNEE_EVENTS := [
	"knee_left",
	"knee_right",
]

const BOXING_STATE_ROWS := [
	{"label": "guard", "state": "guard", "start": "guard_start", "end": "guard_end"},
	{"label": "squat", "state": "squat", "start": "squat_start", "end": "squat_end"},
	{"label": "weave_left", "state": "weave_left", "start": "weave_left_start", "end": "weave_left_end"},
	{"label": "weave_right", "state": "weave_right", "start": "weave_right_start", "end": "weave_right_end"},
	{"label": "sidestep_left", "state": "sidestep_left", "start": "sidestep_left_start", "end": "sidestep_left_end"},
	{"label": "sidestep_right", "state": "sidestep_right", "start": "sidestep_right_start", "end": "sidestep_right_end"},
]

enum HarnessMode {
	BOXING,
	FLOW,
}

enum StartupMode {
	TRACKING,
	PREVIEW_ONLY_DEBUG,
	GODOT_ONLY_DEBUG,
}

enum TrackingSmoothingStyle {
	LITE_RAW,
	FULL_RAW,
	HEAVY_RAW,
	LITE_FILTERED,
	FULL_FILTERED,
	HEAVY_FILTERED,
}

@export var harness_mode: HarnessMode = HarnessMode.BOXING
@export var startup_mode: StartupMode = StartupMode.TRACKING
@export_file("*.mp4", "*.mov", "*.avi", "*.mkv", "*.webm") var prerecorded_video_source := ""
@export var scene_title := "Detector Proving Harness"
@export_multiline var scene_notes := ""
@export var overlay_visibility_threshold := 0.35
@export_enum("full", "optimized", "off") var tracking_overlay_mode := "full"
@export var tracking_smoothing_style: TrackingSmoothingStyle = TrackingSmoothingStyle.FULL_RAW
@export_range(1, 6, 1) var gesture_eval_interval_frames := 1
@export var show_landmarks := true
@export var show_trails := true
@export var trail_debug_logging := false
@export var steady_state_console_debug := false
@export var shutdown_console_debug := false
@export var skip_sidecar_stop_on_close_debug := false
@export var skip_sidecar_terminate_sync_on_close_debug := false
@export var skip_sidecar_terminate_kill_escalation_on_close_debug := false
@export var skip_linux_pkill_main_py_on_close_debug := false
@export var skip_linux_video0_fuser_cleanup_on_close_debug := false

@onready var status_label: Label = get_node_or_null("Margin/VSplit/Header/StatusLabel") as Label
@onready var live_status_label: RichTextLabel = get_node_or_null("Margin/VSplit/Header/LiveStatusLabel") as RichTextLabel
@onready var title_label: Label = find_child("TitleLabel", true, false) as Label
@onready var notes_label: Label = get_node_or_null("Margin/VSplit/Header/NotesLabel") as Label
@onready var camera_source_controls: Control = get_node_or_null("Margin/VSplit/Content/LeftColumn/CameraSourceControls") as Control
@onready var camera_source_picker: OptionButton = find_child("CameraSourcePicker", true, false) as OptionButton
@onready var camera_display: TextureRect = get_node_or_null("Margin/VSplit/Content/LeftColumn/CameraPanel/CameraDisplay") as TextureRect
@onready var landmark_drawer: Control = find_child("LandmarkDrawer", true, false) as Control
@onready var trail_drawer: Control = find_child("TrailDrawer", true, false) as Control
@onready var quick_stats_label: RichTextLabel = find_child("QuickStats", true, false) as RichTextLabel
@onready var summary_label: RichTextLabel = find_child("Summary", true, false) as RichTextLabel
@onready var signal_status_label: RichTextLabel = find_child("SignalStatus", true, false) as RichTextLabel
@onready var metrics_label: RichTextLabel = find_child("Metrics", true, false) as RichTextLabel
@onready var events_label: RichTextLabel = find_child("Events", true, false) as RichTextLabel
@onready var left_placement_chart: Control = find_child("LeftPlacementChart", true, false) as Control
@onready var right_placement_chart: Control = find_child("RightPlacementChart", true, false) as Control
@onready var left_direction_chart: Control = find_child("LeftDirectionChart", true, false) as Control
@onready var right_direction_chart: Control = find_child("RightDirectionChart", true, false) as Control

var provider: Node = null
var auto_start_manager: Node = null
var camera_view: MediaPipeCameraView = null
var _frame_count := 0
var _server_ready := false
var _latest_landmarks: Array = []
var _latest_state: Dictionary = {}
var _event_lines: Array[String] = []
var _left_trail: Array = []
var _right_trail: Array = []
var _left_trail_debug := {}
var _right_trail_debug := {}
var _last_flow_events := {}
var _event_counts: Dictionary = {}
var _last_event_payloads: Dictionary = {}
var _last_event_timestamps_ms: Dictionary = {}
var _event_sequence := 0
var _fixture_capture_started_at_ms := 0
var _fixture_time_origin_ms := 0
var _fixture_time_origin_reason := "scene_ready"
var _fixture_time_origin_locked := false
var _fixture_event_timeline: Array[Dictionary] = []
var _fixture_state_timeline: Array[Dictionary] = []
var _fixture_state_sequence := 0
var _last_console_snapshot := ""
var _preview_only_invalid_reason := ""
var _preview_only_invalid_logged := false
var _shutdown_summary_logged := false
var _camera_devices: Array = []
var _selected_live_camera_device_id := ""
var _suppress_camera_picker_signal := false
var _camera_switch_in_progress := false
var _camera_switch_cleanup_pending := false
var _shared_inspector_panel: PanelContainer = null
var _shared_inspector_title_label: Label = null
var _shared_inspector_subtitle_label: Label = null
var _shared_inspector_body_label: RichTextLabel = null
var _shared_inspector_footer_label: Label = null
var _shared_inspector_target_type := ""
var _shared_inspector_target_key := ""
var _shared_inspector_frozen_model: Dictionary = {}
var _shared_inspector_live_model: Dictionary = {}
var _shared_inspector_live_refresh_due_ms := 0
var _shared_inspector_landmark_last_known := {}
var _playback_overlay_root: Control = null
var _playback_bar_panel: PanelContainer = null
var _playback_toggle_button: Button = null
var _playback_seek_slider: HSlider = null
var _playback_time_label: Label = null
var _playback_status := {}
var _playback_status_poll_due_ms := 0
var _playback_slider_drag_active := false

func _enter_tree() -> void:
	if startup_mode != StartupMode.GODOT_ONLY_DEBUG:
		return
	var auto_start_node := get_node_or_null("AutoStartManager")
	if auto_start_node != null:
		remove_child(auto_start_node)
		auto_start_node.queue_free()

func _ready() -> void:
	if title_label:
		title_label.text = scene_title
	if notes_label:
		notes_label.text = scene_notes
	for label_variant: Variant in [live_status_label, quick_stats_label, summary_label, signal_status_label, metrics_label, events_label]:
		if label_variant is RichTextLabel:
			label_variant.bbcode_enabled = false
	if live_status_label:
		live_status_label.scroll_active = false
	_ensure_shared_inspector_ui()
	_ensure_playback_controls()
	_ensure_overlay_drawers_ready()
	_ensure_landmark_interactions()
	_configure_camera_source_controls()
	_left_trail_debug = _make_trail_debug_state("left")
	_right_trail_debug = _make_trail_debug_state("right")
	_reset_last_flow_events()
	_reset_event_tracking()
	_fixture_capture_started_at_ms = Time.get_ticks_msec()
	_fixture_time_origin_ms = _fixture_capture_started_at_ms
	_fixture_time_origin_reason = "scene_ready"
	_fixture_time_origin_locked = false
	_record_fixture_state_snapshot("ready")
	_update_status("Initializing...", Color.WHITE)
	if startup_mode == StartupMode.GODOT_ONLY_DEBUG:
		_server_ready = true
		if _uses_camera_tracking_contract_path():
			_update_status("CameraTracking contract proving mode active", Color.GREEN)
			_start_provider()
		else:
			_update_status("Godot-only debug mode active", Color.GREEN)
	else:
		_setup_auto_start()
	_refresh_debug_panels()

func _ensure_shared_inspector_ui() -> void:
	if _shared_inspector_panel != null:
		return
	_shared_inspector_panel = PanelContainer.new()
	_shared_inspector_panel.name = "SharedInspectorPanel"
	_shared_inspector_panel.visible = false
	_shared_inspector_panel.top_level = true
	_shared_inspector_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	_shared_inspector_panel.custom_minimum_size = Vector2(INSPECTOR_PANEL_WIDTH, 0.0)
	add_child(_shared_inspector_panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_top", 14)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_bottom", 14)
	_shared_inspector_panel.add_child(margin)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 10)
	margin.add_child(column)

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 8)
	column.add_child(header)

	var title_column := VBoxContainer.new()
	title_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_column.add_theme_constant_override("separation", 4)
	header.add_child(title_column)

	_shared_inspector_title_label = Label.new()
	_shared_inspector_title_label.add_theme_font_size_override("font_size", 18)
	_shared_inspector_title_label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 1.0))
	title_column.add_child(_shared_inspector_title_label)

	_shared_inspector_subtitle_label = Label.new()
	_shared_inspector_subtitle_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_shared_inspector_subtitle_label.add_theme_font_size_override("font_size", 14)
	_shared_inspector_subtitle_label.add_theme_color_override("font_color", Color(0.84, 0.92, 1.0, 0.92))
	title_column.add_child(_shared_inspector_subtitle_label)

	var close_button := Button.new()
	close_button.text = "X"
	close_button.custom_minimum_size = Vector2(INSPECTOR_CLOSE_BUTTON_WIDTH, INSPECTOR_CLOSE_BUTTON_WIDTH)
	close_button.pressed.connect(_close_shared_inspector)
	header.add_child(close_button)

	_shared_inspector_body_label = RichTextLabel.new()
	_shared_inspector_body_label.bbcode_enabled = false
	_shared_inspector_body_label.fit_content = true
	_shared_inspector_body_label.scroll_active = false
	_shared_inspector_body_label.custom_minimum_size = Vector2(INSPECTOR_PANEL_WIDTH - 32.0, 0.0)
	_shared_inspector_body_label.add_theme_font_size_override("normal_font_size", 13)
	_shared_inspector_body_label.add_theme_color_override("default_color", Color(1.0, 1.0, 1.0, 0.95))
	column.add_child(_shared_inspector_body_label)

	_shared_inspector_footer_label = Label.new()
	_shared_inspector_footer_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_shared_inspector_footer_label.add_theme_font_size_override("font_size", 11)
	_shared_inspector_footer_label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 0.58))
	column.add_child(_shared_inspector_footer_label)

	_apply_panel_style(_shared_inspector_panel, Color(0.0, 0.0, 0.0, 0.84), Color(1.0, 1.0, 1.0, 0.16), 18, 1, 0)
	_reposition_shared_inspector()

func _ensure_playback_controls() -> void:
	if _playback_overlay_root != null or camera_display == null:
		return
	var camera_panel := camera_display.get_parent() as Control
	if camera_panel == null:
		return
	_playback_overlay_root = Control.new()
	_playback_overlay_root.name = "PlaybackOverlayRoot"
	_playback_overlay_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_playback_overlay_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	camera_panel.add_child(_playback_overlay_root)

	_playback_bar_panel = PanelContainer.new()
	_playback_bar_panel.name = "PlaybackControls"
	_playback_bar_panel.anchor_left = 0.0
	_playback_bar_panel.anchor_top = 1.0
	_playback_bar_panel.anchor_right = 1.0
	_playback_bar_panel.anchor_bottom = 1.0
	_playback_bar_panel.offset_left = 12.0
	_playback_bar_panel.offset_top = -48.0
	_playback_bar_panel.offset_right = -12.0
	_playback_bar_panel.offset_bottom = -12.0
	_playback_bar_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	_playback_bar_panel.visible = false
	_playback_overlay_root.add_child(_playback_bar_panel)
	_apply_panel_style(_playback_bar_panel, Color(0.0, 0.0, 0.0, 0.76), Color(1.0, 1.0, 1.0, 0.14), 16, 1, 0)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_bottom", 8)
	_playback_bar_panel.add_child(margin)

	var timeline_row_host := CenterContainer.new()
	timeline_row_host.custom_minimum_size = Vector2(0.0, PLAYBACK_CONTROL_ROW_HEIGHT)
	timeline_row_host.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.add_child(timeline_row_host)

	var row := HBoxContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_theme_constant_override("separation", 10)
	timeline_row_host.add_child(row)

	_playback_toggle_button = Button.new()
	_playback_toggle_button.custom_minimum_size = Vector2(PLAYBACK_TOGGLE_BUTTON_WIDTH, PLAYBACK_CONTROL_ROW_HEIGHT)
	_playback_toggle_button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_playback_toggle_button.vertical_icon_alignment = VERTICAL_ALIGNMENT_CENTER
	_playback_toggle_button.text = PLAYBACK_ICON_PAUSE
	_playback_toggle_button.pressed.connect(_on_playback_toggle_pressed)
	row.add_child(_playback_toggle_button)

	_playback_seek_slider = HSlider.new()
	_playback_seek_slider.custom_minimum_size = Vector2(0.0, PLAYBACK_CONTROL_ROW_HEIGHT)
	_playback_seek_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_playback_seek_slider.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_playback_seek_slider.min_value = 0.0
	_playback_seek_slider.max_value = 1.0
	_playback_seek_slider.step = 0.001
	_playback_seek_slider.drag_ended.connect(_on_playback_seek_drag_ended)
	_playback_seek_slider.drag_started.connect(func() -> void:
		_playback_slider_drag_active = true
	)
	row.add_child(_playback_seek_slider)

	_playback_time_label = Label.new()
	_playback_time_label.custom_minimum_size = Vector2(124.0, PLAYBACK_CONTROL_ROW_HEIGHT)
	_playback_time_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_playback_time_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_playback_time_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_playback_time_label.text = "0:00 / 0:00"
	row.add_child(_playback_time_label)

func _resolve_playback_controller() -> Node:
	var tracking_singleton := _resolve_camera_tracking_singleton()
	if tracking_singleton != null and tracking_singleton.has_method("ensure_replay_playback_loaded"):
		return tracking_singleton
	if is_inside_tree():
		push_error("[ProvingHarness] Replay playback requires the AeroCameraTracking singleton")
	return null

func _playback_controller_uses_singleton() -> bool:
	return _resolve_playback_controller() != null

func _get_playback_controller_state() -> Dictionary:
	var tracking_singleton := _resolve_playback_controller()
	if tracking_singleton != null and tracking_singleton.has_method("get_replay_playback_state"):
		return tracking_singleton.get_replay_playback_state()
	return {}

func _playback_controller_has_loaded_media() -> bool:
	return bool(_get_playback_controller_state().get("media_loaded", false))

func _playback_controller_ensure_loaded(base_url: String) -> bool:
	var tracking_singleton := _resolve_playback_controller()
	return tracking_singleton != null and tracking_singleton.has_method("ensure_replay_playback_loaded") and bool(tracking_singleton.ensure_replay_playback_loaded(base_url))

func _playback_controller_refresh_status() -> Dictionary:
	var tracking_singleton := _resolve_playback_controller()
	if tracking_singleton != null and tracking_singleton.has_method("refresh_replay_playback_status"):
		return tracking_singleton.refresh_replay_playback_status()
	return {}

func _playback_controller_play() -> void:
	var tracking_singleton := _resolve_playback_controller()
	if tracking_singleton != null and tracking_singleton.has_method("play_replay_playback"):
		tracking_singleton.play_replay_playback()

func _playback_controller_pause() -> void:
	var tracking_singleton := _resolve_playback_controller()
	if tracking_singleton != null and tracking_singleton.has_method("pause_replay_playback"):
		tracking_singleton.pause_replay_playback()

func _playback_controller_seek(seconds: float) -> void:
	var tracking_singleton := _resolve_playback_controller()
	if tracking_singleton != null and tracking_singleton.has_method("seek_replay_playback"):
		tracking_singleton.seek_replay_playback(seconds)

func _playback_controller_unload() -> void:
	var tracking_singleton := _resolve_playback_controller()
	if tracking_singleton != null and tracking_singleton.has_method("unload_replay_playback"):
		tracking_singleton.unload_replay_playback()

func _ensure_overlay_drawers_ready() -> void:
	_configure_overlay_drawer(landmark_drawer, LANDMARK_DRAWER_Z_INDEX)
	_configure_overlay_drawer(trail_drawer, TRAIL_DRAWER_Z_INDEX)

func _configure_overlay_drawer(drawer: Control, z_index_value: int) -> void:
	if drawer == null:
		return
	drawer.set_anchors_preset(Control.PRESET_FULL_RECT)
	drawer.offset_left = 0.0
	drawer.offset_top = 0.0
	drawer.offset_right = 0.0
	drawer.offset_bottom = 0.0
	drawer.grow_horizontal = Control.GROW_DIRECTION_BOTH
	drawer.grow_vertical = Control.GROW_DIRECTION_BOTH
	drawer.mouse_filter = Control.MOUSE_FILTER_PASS if drawer == landmark_drawer else Control.MOUSE_FILTER_IGNORE
	drawer.z_as_relative = true
	drawer.z_index = z_index_value
	drawer.visible = true
	if drawer.get_parent() != null:
		drawer.queue_redraw()

func _ensure_landmark_interactions() -> void:
	if landmark_drawer == null or not landmark_drawer.has_signal("landmark_clicked"):
		return
	if not landmark_drawer.landmark_clicked.is_connected(_on_landmark_clicked):
		landmark_drawer.landmark_clicked.connect(_on_landmark_clicked)

func _apply_panel_style(panel: PanelContainer, bg: Color, border: Color, radius: int, border_width: int, expand_margin: int) -> void:
	if panel == null:
		return
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(radius)
	style.set_expand_margin_all(expand_margin)
	panel.add_theme_stylebox_override("panel", style)

func _configure_camera_source_controls() -> void:
	if camera_source_picker and not camera_source_picker.item_selected.is_connected(_on_camera_source_picker_selected):
		camera_source_picker.item_selected.connect(_on_camera_source_picker_selected)
	_refresh_camera_source_controls()

func _refresh_camera_source_controls() -> void:
	var show_controls := _should_show_camera_source_controls()
	if camera_source_controls:
		camera_source_controls.visible = show_controls
	if camera_source_picker == null:
		return
	camera_source_picker.disabled = _camera_switch_in_progress
	if not show_controls:
		return
	_camera_devices = _load_available_camera_devices()
	if _selected_live_camera_device_id.strip_edges().is_empty():
		_selected_live_camera_device_id = _resolve_default_live_camera_device_id(_camera_devices)
	_populate_camera_source_picker()

func _should_show_camera_source_controls() -> bool:
	return startup_mode != StartupMode.GODOT_ONLY_DEBUG and _get_scene_camera_source_override().is_empty()

func _load_available_camera_devices() -> Array:
	var temp_provider: Variant = MediaPipeProviderScript.new()
	var devices: Array = []
	if temp_provider != null and temp_provider.has_method("get_available_camera_devices"):
		devices = temp_provider.get_available_camera_devices()
	if temp_provider is Node and is_instance_valid(temp_provider):
		temp_provider.free()
	if devices.is_empty():
		devices.append({
			"id": "/dev/video0",
			"label": "Default camera",
			"path": "/dev/video0",
			"provider": "mediapipe_python",
		})
	return devices

func _resolve_default_live_camera_device_id(devices: Array) -> String:
	var source := _get_effective_camera_source()
	if not _is_live_camera_source_value(source):
		return _first_camera_device_id(devices)
	var normalized := _normalize_live_camera_device_id(source)
	if _device_list_has_id(devices, normalized):
		return normalized
	if source == "0" and _device_list_has_id(devices, "/dev/video0"):
		return "/dev/video0"
	if not normalized.is_empty():
		return normalized
	return _first_camera_device_id(devices)

func _first_camera_device_id(devices: Array) -> String:
	for device_variant: Variant in devices:
		if not device_variant is Dictionary:
			continue
		var device: Dictionary = device_variant
		var device_id := String(device.get("id", "")).strip_edges()
		if not device_id.is_empty():
			return device_id
	return ""

func _device_list_has_id(devices: Array, device_id: String) -> bool:
	for device_variant: Variant in devices:
		if not device_variant is Dictionary:
			continue
		if String((device_variant as Dictionary).get("id", "")).strip_edges() == device_id:
			return true
	return false

func _populate_camera_source_picker() -> void:
	if camera_source_picker == null:
		return
	_suppress_camera_picker_signal = true
	camera_source_picker.clear()
	var selected_index := -1
	for index: int in range(_camera_devices.size()):
		var device_variant: Variant = _camera_devices[index]
		if not device_variant is Dictionary:
			continue
		var device: Dictionary = device_variant
		var device_id := String(device.get("id", "")).strip_edges()
		var label := _camera_device_label(device)
		camera_source_picker.add_item(label)
		var item_index := camera_source_picker.item_count - 1
		camera_source_picker.set_item_metadata(item_index, device_id)
		camera_source_picker.set_item_tooltip(item_index, device_id)
		if device_id == _selected_live_camera_device_id:
			selected_index = item_index
	if selected_index == -1 and camera_source_picker.item_count > 0:
		selected_index = 0
		_selected_live_camera_device_id = String(camera_source_picker.get_item_metadata(0)).strip_edges()
	if selected_index >= 0:
		camera_source_picker.select(selected_index)
	_suppress_camera_picker_signal = false

func _camera_device_label(device: Dictionary) -> String:
	var label := String(device.get("label", "")).strip_edges()
	var device_id := String(device.get("id", "")).strip_edges()
	if label.is_empty():
		label = device_id
	if label == device_id or device_id.is_empty():
		return label
	return "%s (%s)" % [label, device_id]

func _on_camera_source_picker_selected(index: int) -> void:
	if _suppress_camera_picker_signal or camera_source_picker == null or index < 0 or index >= camera_source_picker.item_count:
		return
	var device_id := String(camera_source_picker.get_item_metadata(index)).strip_edges()
	if device_id.is_empty() or device_id == _selected_live_camera_device_id or _camera_switch_in_progress:
		return
	_camera_switch_in_progress = true
	_selected_live_camera_device_id = _normalize_live_camera_device_id(device_id)
	_refresh_camera_source_controls()
	_update_status("Switching live camera...", Color.YELLOW)
	_switch_live_camera_source.call_deferred(device_id)

func _switch_live_camera_source(device_id: String) -> void:
	var success := await _apply_live_camera_source(device_id)
	_camera_switch_in_progress = false
	_refresh_camera_source_controls()
	if success:
		_record_event("camera_source_switched", {"device_id": _selected_live_camera_device_id})
		_update_status("Live camera switched", Color.GREEN)
	elif _should_show_camera_source_controls():
		_update_status("Live camera switch failed", Color.RED)

func _apply_live_camera_source(device_id: String) -> bool:
	if device_id.strip_edges().is_empty() or not _should_show_camera_source_controls():
		return false
	_selected_live_camera_device_id = _normalize_live_camera_device_id(device_id)
	_server_ready = false
	if auto_start_manager == null:
		return false
	_camera_switch_cleanup_pending = true
	var camera_source_override := _get_autostart_camera_source_override()
	var restart_ok := false
	if auto_start_manager.has_method("restart_server"):
		restart_ok = bool(await auto_start_manager.restart_server(camera_source_override))
	else:
		auto_start_manager.camera_source_override = camera_source_override
		await auto_start_manager.stop_server()
		restart_ok = bool(await auto_start_manager.start_server())
	if not restart_ok:
		_camera_switch_cleanup_pending = false
		return false
	return await _await_live_camera_runtime_ready()

func _clear_live_camera_runtime_state() -> void:
	_latest_landmarks.clear()
	_latest_state.clear()
	_left_trail.clear()
	_right_trail.clear()
	if landmark_drawer:
		landmark_drawer.clear_landmarks()
	if trail_drawer:
		trail_drawer.clear_trails()
	if provider != null:
		provider.stop()
		if is_instance_valid(provider):
			provider.queue_free()
		provider = null
	if camera_view != null and camera_view.is_streaming():
		camera_view.stop_stream()

func _await_live_camera_runtime_ready(timeout_ms: int = 8000) -> bool:
	var deadline_ms := Time.get_ticks_msec() + timeout_ms
	while Time.get_ticks_msec() < deadline_ms:
		if _is_live_camera_runtime_ready():
			return true
		await get_tree().process_frame
	return _is_live_camera_runtime_ready()

func _is_live_camera_runtime_ready() -> bool:
	if startup_mode == StartupMode.GODOT_ONLY_DEBUG:
		if _uses_camera_tracking_contract_path():
			return provider != null
		return true
	if not _server_ready:
		return false
	if camera_view == null or not camera_view.is_streaming():
		return false
	if startup_mode == StartupMode.PREVIEW_ONLY_DEBUG:
		return true
	return provider != null

func _setup_auto_start() -> void:
	auto_start_manager = get_node_or_null("AutoStartManager")
	if auto_start_manager == null:
		push_error("[ProvingHarness] AutoStartManager node not found in scene")
		_update_status("AutoStartManager missing", Color.RED)
		return

	auto_start_manager.camera_source_override = _get_autostart_camera_source_override()
	_apply_tracking_smoothing_style_to_autostart_manager()
	auto_start_manager.tracking_overlay_mode = tracking_overlay_mode
	auto_start_manager.debug_logging = steady_state_console_debug or shutdown_console_debug
	auto_start_manager.skip_sidecar_stop_on_close_debug = skip_sidecar_stop_on_close_debug
	auto_start_manager.skip_sidecar_terminate_sync_on_close_debug = skip_sidecar_terminate_sync_on_close_debug
	auto_start_manager.skip_sidecar_terminate_kill_escalation_on_close_debug = skip_sidecar_terminate_kill_escalation_on_close_debug
	auto_start_manager.skip_linux_pkill_main_py_on_close_debug = skip_linux_pkill_main_py_on_close_debug
	auto_start_manager.skip_linux_video0_fuser_cleanup_on_close_debug = skip_linux_video0_fuser_cleanup_on_close_debug
	if skip_sidecar_stop_on_close_debug:
		print("[ProvingHarness][%s] Close-path isolation enabled: AutoStartManager will skip normal sidecar stop on close/scene teardown; heartbeat timeout should stop it after exit" % _mode_name())
	elif skip_sidecar_terminate_sync_on_close_debug \
		or skip_sidecar_terminate_kill_escalation_on_close_debug \
		or skip_linux_pkill_main_py_on_close_debug \
		or skip_linux_video0_fuser_cleanup_on_close_debug:
		print("[ProvingHarness][%s] Narrow close-path debug enabled: stop_mode=%s" % [_mode_name(), _get_close_path_stop_mode_label()])

	auto_start_manager.server_started.connect(_on_server_started)
	auto_start_manager.server_failed.connect(_on_server_failed)
	auto_start_manager.server_stopped.connect(_on_server_stopped)
	auto_start_manager.python_not_found.connect(_on_python_not_found)
	auto_start_manager.mediapipe_not_found.connect(_on_mediapipe_not_found)
	auto_start_manager.check_progress.connect(_on_check_progress)
	auto_start_manager.installation_progress.connect(_on_install_progress)
	auto_start_manager.installation_complete.connect(_on_install_complete)

	if not auto_start_manager.auto_start:
		await auto_start_manager.start_server()

func _process(_delta: float) -> void:
	_frame_count += 1

	if _is_preview_only_mode():
		_audit_preview_only_surface()

	if _frame_count % 60 == 0 and auto_start_manager and auto_start_manager.server_pid > 0:
		if not auto_start_manager.is_server_running():
			_update_status("Python server died", Color.RED)
			_server_ready = false

	if _frame_count % 10 == 0:
		if provider != null:
			_latest_state = provider.get_detector_state()
		_refresh_debug_panels()

	_refresh_playback_polling()
	_refresh_shared_inspector()

	if steady_state_console_debug and _frame_count % 30 == 0:
		_emit_console_snapshot_if_changed()

func _input(event: InputEvent) -> void:
	if _shared_inspector_panel == null or not _shared_inspector_panel.visible:
		return
	if not (event is InputEventMouseButton):
		return
	var mouse_event := event as InputEventMouseButton
	if not mouse_event.pressed or mouse_event.button_index != MOUSE_BUTTON_LEFT:
		return
	if _shared_inspector_panel.get_global_rect().has_point(mouse_event.position):
		return
	if _playback_bar_panel != null and _playback_bar_panel.visible and _playback_bar_panel.get_global_rect().has_point(mouse_event.position):
		return
	_close_shared_inspector()

func _on_check_progress(percentage: int, message: String) -> void:
	_update_status("%d%% - %s" % [percentage, message], Color.YELLOW)

func _on_install_progress(percentage: int, message: String) -> void:
	_update_status("Installing: %d%% - %s" % [percentage, message], Color.ORANGE)

func _on_install_complete(success: bool) -> void:
	if success:
		_update_status("Installation complete. Starting server...", Color.GREEN)
	else:
		_update_status("Installation failed", Color.RED)

func _on_python_not_found() -> void:
	_update_status("Python 3 not found", Color.RED)

func _on_mediapipe_not_found() -> void:
	_update_status("MediaPipe runtime missing - installing", Color.YELLOW)

func _on_server_started(pid: int) -> void:
	_update_status("Python server started (PID %d)" % pid, Color.GREEN)
	await get_tree().create_timer(1.5).timeout
	await _start_camera_feed()

	if startup_mode == StartupMode.PREVIEW_ONLY_DEBUG:
		_server_ready = true
		_preview_only_invalid_reason = ""
		_preview_only_invalid_logged = false
		_clear_preview_only_overlay_state()
		_record_event("preview_only_provider_disabled", {"mode": _mode_name(), "source": _camera_source_compact_text()})
		_update_status("Preview-only debug mode active (provider disabled)", Color.GREEN)
		return

	_start_provider()

func _on_server_failed(error: String) -> void:
	_update_status("Auto-start failed: %s" % error, Color.RED)
	_record_event("server_failed", {"detail": error})

func _on_server_stopped() -> void:
	_server_ready = false
	if _camera_switch_cleanup_pending:
		_clear_live_camera_runtime_state()
		_camera_switch_cleanup_pending = false
	_update_status("Server stopped", Color.ORANGE)

func _start_provider() -> void:
	if provider != null:
		return

	var runtime_config := _build_runtime_config()
	var tracking_singleton := _resolve_camera_tracking_singleton()
	if tracking_singleton == null:
		push_error("[ProvingHarness] AeroCameraTracking singleton is required for .testbed proving flows")
		_update_status("AeroCameraTracking singleton missing", Color.RED)
		return
	provider = tracking_singleton
	if provider.has_method("attach_preview_surface"):
		provider.attach_preview_surface(camera_display)

	provider.pose_updated.connect(_on_pose_updated)
	provider.tracking_lost.connect(_on_tracking_lost)
	provider.tracking_restored.connect(_on_tracking_restored)
	_connect_mode_signals()

	var success := false
	if tracking_singleton != null:
		if _is_prerecorded_source_active() and provider.has_method("start_replay"):
			success = bool(provider.start_replay(_get_scene_camera_source_override(), runtime_config))
		elif provider.has_method("start_live_camera"):
			success = bool(provider.start_live_camera(_get_configured_live_camera_source(), runtime_config))
	else:
		success = bool(provider.call("start"))
	if success:
		_server_ready = true
		_refresh_camera_source_controls()
		_record_event("provider_started", {"mode": _mode_name(), "provider": provider.name})
		_record_fixture_state_snapshot("provider_started")
		_update_status("%s harness live" % _mode_name(), Color.GREEN)
	else:
		_update_status("Provider failed to start", Color.RED)

func _build_runtime_config() -> MediaPipeConfig:
	var config := MediaPipeConfigScript.new()
	config.min_visibility = overlay_visibility_threshold
	config.track_left_foot = true
	config.track_right_foot = true
	config.flip_horizontal = _should_flip_horizontal_preview()
	var live_camera_source := _get_configured_live_camera_source()
	if not live_camera_source.is_empty() and live_camera_source != "0":
		config.set_selected_camera_device_id(live_camera_source)
	config.tracking_overlay_mode = tracking_overlay_mode
	config.gesture_eval_interval_frames = maxi(1, gesture_eval_interval_frames)
	var tracking_style := _tracking_smoothing_style_spec()
	config.model_complexity = int(tracking_style.get("model_complexity", config.model_complexity))
	return config

func _resolve_camera_tracking_singleton() -> Node:
	if not is_inside_tree():
		return null
	return get_tree().root.get_node_or_null(TRACKING_SINGLETON_NODE_NAME) as Node

func _resolve_camera_tracking_session() -> Node:
	var tracking_singleton := _resolve_camera_tracking_singleton()
	if tracking_singleton != null and tracking_singleton.has_method("get_tracking_session_if_ready"):
		var session = tracking_singleton.get_tracking_session_if_ready()
		if session != null:
			return session as Node
	return null

func _uses_camera_tracking_contract_path() -> bool:
	return _resolve_camera_tracking_singleton() != null

func _connect_mode_signals() -> void:
	if harness_mode == HarnessMode.BOXING:
		for signal_name: String in ["punch_left", "punch_right", "hook_left", "hook_right", "uppercut_left", "uppercut_right", "knee_left", "knee_right"]:
			_connect_power_signal(signal_name)
		for signal_name: String in ["guard_start", "guard_end", "squat_start", "squat_end", "weave_left_start", "weave_left_end", "weave_right_start", "weave_right_end", "sidestep_left_start", "sidestep_left_end", "sidestep_right_start", "sidestep_right_end", "leg_lift_left_start", "leg_lift_left_end", "leg_lift_right_start", "leg_lift_right_end"]:
			_connect_simple_signal(signal_name)
	else:
		for signal_name: String in ["swing_left", "swing_right", "trail_left", "trail_right"]:
			_connect_flow_signal(signal_name)

func _connect_simple_signal(signal_name: String) -> void:
	if provider == null or not provider.has_signal(signal_name):
		return
	provider.connect(signal_name, func() -> void:
		_record_event(signal_name, {})
	)

func _connect_power_signal(signal_name: String) -> void:
	if provider == null or not provider.has_signal(signal_name):
		return
	provider.connect(signal_name, func(power: float) -> void:
		_record_event(signal_name, {"power": power})
	)

func _connect_flow_signal(signal_name: String) -> void:
	if provider == null or not provider.has_signal(signal_name):
		return
	provider.connect(signal_name, func(placement: int, direction: int) -> void:
		_last_flow_events[signal_name] = {
			"placement": placement,
			"direction": direction,
			"timestamp_ms": Time.get_ticks_msec(),
		}
		_record_event(signal_name, {"placement": placement, "direction": direction})
	)

func _on_pose_updated(landmarks: Array) -> void:
	if _is_preview_only_mode():
		_invalidate_preview_only_surface("pose/provider activity reached preview-only rung")
		return

	_latest_landmarks = landmarks.duplicate(true)
	_latest_state = provider.get_detector_state() if provider != null else {}
	_maybe_anchor_fixture_time_origin_to_provider_ready()
	_record_fixture_state_snapshot("pose_updated")

	if show_landmarks and landmark_drawer:
		landmark_drawer.update_landmarks(landmarks, overlay_visibility_threshold)
	elif landmark_drawer:
		landmark_drawer.clear_landmarks()

	_update_motion_trails(landmarks)
	_refresh_debug_panels()

func _update_motion_trails(landmarks: Array) -> void:
	var timestamp_ms := Time.get_ticks_msec()
	var left_wrist := _resolve_trail_hand_point(landmarks, LEFT_WRIST_ID, [LEFT_INDEX_ID, LEFT_PINKY_ID, LEFT_THUMB_ID])
	var right_wrist := _resolve_trail_hand_point(landmarks, RIGHT_WRIST_ID, [RIGHT_INDEX_ID, RIGHT_PINKY_ID, RIGHT_THUMB_ID])
	_append_trail_point(_left_trail, left_wrist, timestamp_ms, _left_trail_debug)
	_append_trail_point(_right_trail, right_wrist, timestamp_ms, _right_trail_debug)
	_prune_trail(_left_trail, timestamp_ms)
	_prune_trail(_right_trail, timestamp_ms)
	_update_trail_debug_state(_left_trail, _left_trail_debug, timestamp_ms)
	_update_trail_debug_state(_right_trail, _right_trail_debug, timestamp_ms)
	if show_trails and trail_drawer:
		trail_drawer.update_trails(_left_trail, _right_trail)
	elif trail_drawer:
		trail_drawer.clear_trails()

func _append_trail_point(trail: Array, landmark: Dictionary, timestamp_ms: int, debug_state: Dictionary) -> void:
	debug_state["frame_samples"] = int(debug_state.get("frame_samples", 0)) + 1
	if landmark.is_empty():
		_note_trail_debug_skip(debug_state, "missing")
		_break_trail_for_gap(trail, timestamp_ms, debug_state, "missing")
		return
	var visibility := float(landmark.get("v", 0.0))
	var trail_visibility_threshold := _trail_visibility_threshold()
	if visibility < trail_visibility_threshold:
		_note_trail_debug_skip(debug_state, "low_visibility")
		debug_state["last_visibility"] = visibility
		_break_trail_for_gap(trail, timestamp_ms, debug_state, "low_visibility")
		return
	var point := Vector2(float(landmark.get("x", 0.0)), float(landmark.get("y", 0.0)))
	debug_state["last_visibility"] = visibility
	debug_state["last_point"] = point
	if not _is_normalized_point_in_bounds(point):
		trail.clear()
		debug_state["out_of_bounds_clears"] = int(debug_state.get("out_of_bounds_clears", 0)) + 1
		debug_state["last_action"] = "clear_oob"
		return
	var jump_distance := _trail_jump_distance(trail, point)
	debug_state["last_jump_distance"] = jump_distance
	if jump_distance > MAX_TRAIL_FRAME_JUMP:
		_append_trail_break(trail, timestamp_ms)
		debug_state["continuity_breaks"] = int(debug_state.get("continuity_breaks", 0)) + 1
		debug_state["last_action"] = "break_reseed"
	else:
		debug_state["last_action"] = "append"
	if _trail_needs_reseed(trail):
		debug_state["reseeds"] = int(debug_state.get("reseeds", 0)) + 1
		if debug_state["last_action"] == "append":
			debug_state["last_action"] = "seed"
	trail.append(_make_trail_point(point, visibility, timestamp_ms))
	debug_state["appends"] = int(debug_state.get("appends", 0)) + 1
	while trail.size() > MAX_TRAIL_POINTS:
		trail.remove_at(0)

func _resolve_trail_hand_point(landmarks: Array, wrist_id: int, fallback_ids: Array[int]) -> Dictionary:
	var wrist := _find_landmark(landmarks, wrist_id)
	var trail_visibility_threshold := _trail_visibility_threshold()
	if _trail_landmark_is_directly_usable(wrist, trail_visibility_threshold):
		return wrist

	var candidates: Array[Dictionary] = []
	for landmark_id: int in fallback_ids:
		var candidate := _trail_clamp_candidate_for_fallback(_find_landmark(landmarks, landmark_id))
		if not candidate.is_empty():
			candidates.append(candidate)
	if candidates.is_empty():
		return wrist
	return _synthesize_trail_hand_point(candidates)

func _trail_visibility_threshold() -> float:
	return minf(overlay_visibility_threshold, TRAIL_VISIBILITY_THRESHOLD_FLOOR)

func _trail_landmark_is_directly_usable(landmark: Dictionary, min_visibility: float) -> bool:
	if landmark.is_empty():
		return false
	if float(landmark.get("v", 0.0)) < min_visibility:
		return false
	var point := Vector2(float(landmark.get("x", 0.0)), float(landmark.get("y", 0.0)))
	return _is_normalized_point_in_bounds(point)

func _trail_landmark_is_candidate(landmark: Dictionary) -> bool:
	if landmark.is_empty():
		return false
	if float(landmark.get("v", 0.0)) < _trail_visibility_threshold():
		return false
	var point := Vector2(float(landmark.get("x", 0.0)), float(landmark.get("y", 0.0)))
	return _is_normalized_point_in_bounds(point)

func _trail_clamp_candidate_for_fallback(landmark: Dictionary) -> Dictionary:
	if not _trail_landmark_is_fallback_usable(landmark):
		return {}
	var candidate := landmark.duplicate(true)
	candidate["x"] = clampf(float(candidate.get("x", 0.0)), 0.0, 1.0)
	candidate["y"] = clampf(float(candidate.get("y", 0.0)), 0.0, 1.0)
	return candidate

func _trail_landmark_is_fallback_usable(landmark: Dictionary) -> bool:
	if landmark.is_empty():
		return false
	if float(landmark.get("v", 0.0)) < _trail_visibility_threshold():
		return false
	var point := Vector2(float(landmark.get("x", 0.0)), float(landmark.get("y", 0.0)))
	return _is_normalized_point_in_bounds(point) or _is_trail_fallback_point_near_normalized_bounds(point)

func _is_trail_fallback_point_near_normalized_bounds(point: Vector2) -> bool:
	return point.x >= -MAX_TRAIL_FALLBACK_EDGE_CLAMP_OVERSHOOT \
		and point.x <= 1.0 + MAX_TRAIL_FALLBACK_EDGE_CLAMP_OVERSHOOT \
		and point.y >= -MAX_TRAIL_FALLBACK_EDGE_CLAMP_OVERSHOOT \
		and point.y <= 1.0 + MAX_TRAIL_FALLBACK_EDGE_CLAMP_OVERSHOOT

func _synthesize_trail_hand_point(candidates: Array[Dictionary]) -> Dictionary:
	if candidates.size() < 2:
		return {}
	var total_weight := 0.0
	var blended_point := Vector2.ZERO
	var best_visibility := 0.0
	var points: Array[Vector2] = []
	for candidate: Dictionary in candidates:
		var visibility := float(candidate.get("v", 0.0))
		var point := Vector2(float(candidate.get("x", 0.0)), float(candidate.get("y", 0.0)))
		points.append(point)
		blended_point += point * visibility
		total_weight += visibility
		best_visibility = maxf(best_visibility, visibility)
	if total_weight <= 0.000001:
		return {}
	if _max_point_spread(points) > MAX_TRAIL_FALLBACK_SPREAD:
		return {}
	var synthesized_point := blended_point / total_weight
	if not _is_normalized_point_in_bounds(synthesized_point):
		return {}
	return _make_trail_point(synthesized_point, best_visibility, Time.get_ticks_msec())

func _max_point_spread(points: Array[Vector2]) -> float:
	var max_spread := 0.0
	for i: int in range(points.size()):
		for j: int in range(i + 1, points.size()):
			max_spread = maxf(max_spread, points[i].distance_to(points[j]))
	return max_spread

func _trail_jump_distance(trail: Array, point: Vector2) -> float:
	if trail.is_empty():
		return 0.0
	for index: int in range(trail.size() - 1, -1, -1):
		var point_variant: Variant = trail[index]
		if not point_variant is Dictionary:
			continue
		var trail_point: Dictionary = point_variant
		if not trail_point.has("x") or not trail_point.has("y"):
			continue
		var previous := Vector2(float(trail_point.get("x", 0.0)), float(trail_point.get("y", 0.0)))
		if not _is_normalized_point_in_bounds(previous):
			continue
		return previous.distance_to(point)
	return 0.0

func _append_trail_break(trail: Array, timestamp_ms: int) -> void:
	if trail.is_empty():
		return
	var last_point_variant: Variant = trail[trail.size() - 1]
	if last_point_variant is Dictionary:
		var last_point: Dictionary = last_point_variant
		var last_break_point := Vector2(float(last_point.get("x", 0.0)), float(last_point.get("y", 0.0)))
		if not _is_normalized_point_in_bounds(last_break_point):
			return
	trail.append({
		"x": -1.0,
		"y": -1.0,
		"v": 0.0,
		"timestamp_ms": timestamp_ms,
	})

func _break_trail_for_gap(trail: Array, timestamp_ms: int, debug_state: Dictionary, reason: String) -> void:
	if trail.is_empty() or _trail_needs_reseed(trail):
		return
	_append_trail_break(trail, timestamp_ms)
	debug_state["continuity_breaks"] = int(debug_state.get("continuity_breaks", 0)) + 1
	debug_state["last_action"] = "break_%s" % reason

func _trail_needs_reseed(trail: Array) -> bool:
	if trail.is_empty():
		return true
	var last_point_variant: Variant = trail[trail.size() - 1]
	if not last_point_variant is Dictionary:
		return false
	var last_point: Dictionary = last_point_variant
	if not last_point.has("x") or not last_point.has("y"):
		return false
	return not _is_normalized_point_in_bounds(Vector2(float(last_point.get("x", 0.0)), float(last_point.get("y", 0.0))))

func _make_trail_debug_state(side: String) -> Dictionary:
	return {
		"side": side,
		"frame_samples": 0,
		"appends": 0,
		"reseeds": 0,
		"continuity_breaks": 0,
		"out_of_bounds_clears": 0,
		"missing_skips": 0,
		"low_visibility_skips": 0,
		"last_action": "idle",
		"last_jump_distance": 0.0,
		"last_visibility": 0.0,
		"last_live_points": 0,
		"last_break_markers": 0,
		"last_drawable_segments": 0,
		"last_segment_points": 0,
		"last_duration_ms": 0,
	}

func _note_trail_debug_skip(debug_state: Dictionary, reason: String) -> void:
	match reason:
		"missing":
			debug_state["missing_skips"] = int(debug_state.get("missing_skips", 0)) + 1
		"low_visibility":
			debug_state["low_visibility_skips"] = int(debug_state.get("low_visibility_skips", 0)) + 1
	debug_state["last_action"] = reason
	debug_state["last_jump_distance"] = 0.0

func _update_trail_debug_state(trail: Array, debug_state: Dictionary, timestamp_ms: int) -> void:
	var live_points := 0
	var break_markers := 0
	var drawable_segments := 0
	var current_segment_points := 0
	for point_variant: Variant in trail:
		if not point_variant is Dictionary:
			continue
		var trail_point: Dictionary = point_variant
		if not trail_point.has("x") or not trail_point.has("y"):
			continue
		var point := Vector2(float(trail_point.get("x", 0.0)), float(trail_point.get("y", 0.0)))
		if not _is_normalized_point_in_bounds(point):
			break_markers += 1
			if current_segment_points >= 2:
				drawable_segments += 1
			current_segment_points = 0
			continue
		live_points += 1
		current_segment_points += 1
	if current_segment_points >= 2:
		drawable_segments += 1
	debug_state["last_live_points"] = live_points
	debug_state["last_break_markers"] = break_markers
	debug_state["last_drawable_segments"] = drawable_segments
	debug_state["last_segment_points"] = current_segment_points
	debug_state["last_duration_ms"] = _trail_duration_ms(trail)
	debug_state["last_age_ms"] = timestamp_ms

func _format_trail_debug_line(debug_state: Dictionary) -> String:
	return "%s trail | pts=%d segs=%d tail=%d breaks=%d reseeds=%d clears=%d miss=%d low=%d jump=%s action=%s dur=%dms" % [
		String(debug_state.get("side", "?")),
		int(debug_state.get("last_live_points", 0)),
		int(debug_state.get("last_drawable_segments", 0)),
		int(debug_state.get("last_segment_points", 0)),
		int(debug_state.get("continuity_breaks", 0)),
		int(debug_state.get("reseeds", 0)),
		int(debug_state.get("out_of_bounds_clears", 0)),
		int(debug_state.get("missing_skips", 0)),
		int(debug_state.get("low_visibility_skips", 0)),
		_fmt_float(debug_state.get("last_jump_distance", 0.0)),
		String(debug_state.get("last_action", "idle")),
		int(debug_state.get("last_duration_ms", 0)),
	]

func _make_trail_point(point: Vector2, visibility: float, timestamp_ms: int) -> Dictionary:
	return {
		"x": point.x,
		"y": point.y,
		"v": visibility,
		"timestamp_ms": timestamp_ms,
	}

func _is_normalized_point_in_bounds(point: Vector2) -> bool:
	return point.x >= 0.0 and point.x <= 1.0 and point.y >= 0.0 and point.y <= 1.0

func _prune_trail(trail: Array, timestamp_ms: int) -> void:
	while trail.size() > 0 and timestamp_ms - int(trail[0].get("timestamp_ms", timestamp_ms)) > MAX_TRAIL_AGE_MS:
		trail.remove_at(0)

func _find_landmark(landmarks: Array, landmark_id: int) -> Dictionary:
	for landmark_variant: Variant in landmarks:
		if not landmark_variant is Dictionary:
			continue
		var landmark: Dictionary = landmark_variant
		if int(landmark.get("id", -1)) == landmark_id:
			return landmark
	return {}

func _on_tracking_lost() -> void:
	if _is_preview_only_mode():
		_invalidate_preview_only_surface("tracking_lost signal reached preview-only rung")
		return

	_update_status("Tracking lost", Color.ORANGE)
	_record_event("tracking_lost", {})
	_record_fixture_state_snapshot("tracking_lost")
	_left_trail.clear()
	_right_trail.clear()
	if landmark_drawer:
		landmark_drawer.clear_landmarks()
	if trail_drawer:
		trail_drawer.clear_trails()

func _on_tracking_restored() -> void:
	if _is_preview_only_mode():
		_invalidate_preview_only_surface("tracking_restored signal reached preview-only rung")
		return

	_update_status("Tracking restored", Color.GREEN)
	_record_event("tracking_restored", {})
	_record_fixture_state_snapshot("tracking_restored")

func _start_camera_feed() -> void:
	camera_view = MediaPipeCameraViewScript.new()
	camera_view.name = "CameraView"
	camera_view.stream_url = "http://127.0.0.1:4243/camera"
	camera_view.debug_logging = steady_state_console_debug
	camera_view.flip_horizontal = _should_flip_horizontal_preview()
	camera_view.show_overlay = false

	var previous_display := camera_display
	if previous_display:
		camera_view.custom_minimum_size = previous_display.custom_minimum_size
		camera_view.layout_mode = previous_display.layout_mode
		camera_view.size_flags_horizontal = previous_display.size_flags_horizontal
		camera_view.size_flags_vertical = previous_display.size_flags_vertical
		camera_view.size_flags_stretch_ratio = previous_display.size_flags_stretch_ratio
		camera_view.expand_mode = previous_display.expand_mode
		camera_view.stretch_mode = previous_display.stretch_mode
	else:
		camera_view.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		camera_view.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	previous_display.replace_by(camera_view)
	camera_display = camera_view
	if landmark_drawer:
		landmark_drawer.reparent(camera_display)
	if trail_drawer:
		trail_drawer.reparent(camera_display)
	_ensure_overlay_drawers_ready()
	if previous_display and previous_display != camera_view:
		previous_display.queue_free()

	await get_tree().process_frame
	var stream_started := await camera_view.start_stream()
	if not stream_started:
		_record_event("camera_stream_failed", {})

func _on_landmark_clicked(landmark_id: int) -> void:
	_open_shared_inspector("landmark", str(landmark_id))

func _open_shared_inspector(target_type: String, target_key: String) -> void:
	_shared_inspector_target_type = target_type
	_shared_inspector_target_key = target_key
	_shared_inspector_frozen_model = {}
	_shared_inspector_live_model = {}
	_shared_inspector_live_refresh_due_ms = 0
	if _should_freeze_landmark_inspector():
		_shared_inspector_frozen_model = _build_shared_inspector_model(target_type, target_key)
	_refresh_shared_inspector(true)

func _close_shared_inspector() -> void:
	_shared_inspector_target_type = ""
	_shared_inspector_target_key = ""
	_shared_inspector_frozen_model = {}
	_shared_inspector_live_model = {}
	_shared_inspector_live_refresh_due_ms = 0
	if _shared_inspector_panel != null:
		_shared_inspector_panel.visible = false

func _refresh_shared_inspector(force: bool = false) -> void:
	if _shared_inspector_panel == null:
		return
	if _shared_inspector_target_type.is_empty() or _shared_inspector_target_key.is_empty():
		_shared_inspector_panel.visible = false
		return
	var model := _resolve_shared_inspector_model(force)
	if model.is_empty():
		_shared_inspector_panel.visible = false
		return
	_shared_inspector_title_label.text = String(model.get("title", "Inspector"))
	_shared_inspector_subtitle_label.text = String(model.get("subtitle", ""))
	_shared_inspector_subtitle_label.visible = not _shared_inspector_subtitle_label.text.is_empty()
	_shared_inspector_body_label.text = String(model.get("body", ""))
	_shared_inspector_footer_label.text = String(model.get("footer", INSPECTOR_FOOTER_TEXT))
	_shared_inspector_footer_label.visible = not _shared_inspector_footer_label.text.is_empty()
	_shared_inspector_panel.visible = true
	_reposition_shared_inspector()

func _resolve_shared_inspector_model(force: bool = false) -> Dictionary:
	if _should_use_frozen_landmark_inspector():
		return _shared_inspector_frozen_model
	if _shared_inspector_target_type == "landmark":
		var now_ms := Time.get_ticks_msec()
		if not force and not _shared_inspector_live_model.is_empty() and now_ms < _shared_inspector_live_refresh_due_ms:
			return _shared_inspector_live_model
		_shared_inspector_live_model = _build_shared_inspector_model(_shared_inspector_target_type, _shared_inspector_target_key)
		_shared_inspector_live_refresh_due_ms = now_ms + INSPECTOR_LIVE_REFRESH_INTERVAL_MS
		return _shared_inspector_live_model
	return _build_shared_inspector_model(_shared_inspector_target_type, _shared_inspector_target_key)

func _build_shared_inspector_model(target_type: String, target_key: String) -> Dictionary:
	if target_type == "landmark":
		return _build_landmark_inspector_model(int(target_key.to_int()))
	return _build_custom_inspector_model(target_type, target_key)

func _build_custom_inspector_model(_target_type: String, _target_key: String) -> Dictionary:
	return {}

func _build_landmark_inspector_model(landmark_id: int) -> Dictionary:
	var snapshot := _capture_landmark_snapshot(landmark_id)
	var name := _landmark_name(landmark_id)
	var subtitle := "%s (#%d)" % [name, landmark_id]
	var lines: Array[String] = []
	if bool(snapshot.get("tracked", false)):
		_shared_inspector_landmark_last_known[str(landmark_id)] = snapshot.duplicate(true)
		lines.append("Status: tracked now")
		lines.append("Confidence: %s" % _fmt_percent(snapshot.get("visibility", 0.0)))
		lines.append("Position (norm, raw live): x=%s  y=%s  z=%s" % [
			_fmt_inspector_float(snapshot.get("x", 0.0)),
			_fmt_inspector_float(snapshot.get("y", 0.0)),
			_fmt_inspector_float(snapshot.get("z", 0.0)),
		])
		if bool(snapshot.get("has_smoothed_position", false)):
			lines.append("Detector-smoothed position: x=%s  y=%s  z=%s" % [
				_fmt_inspector_float(snapshot.get("smoothed_x", 0.0)),
				_fmt_inspector_float(snapshot.get("smoothed_y", 0.0)),
				_fmt_inspector_float(snapshot.get("smoothed_z", 0.0)),
			])
	else:
		lines.append("Status: not currently tracked")
		var last_known: Dictionary = _shared_inspector_landmark_last_known.get(str(landmark_id), {})
		if not last_known.is_empty():
			lines.append("Last known confidence: %s" % _fmt_percent(last_known.get("visibility", 0.0)))
			lines.append("Last known raw position: x=%s  y=%s  z=%s" % [
				_fmt_inspector_float(last_known.get("x", 0.0)),
				_fmt_inspector_float(last_known.get("y", 0.0)),
				_fmt_inspector_float(last_known.get("z", 0.0)),
			])
	var body_part: StringName = snapshot.get("body_part", &"")
	if body_part != StringName():
		lines.append("Body role: %s" % String(body_part))
	var velocity: Variant = snapshot.get("velocity", null)
	if velocity is Vector3 and body_part != StringName():
		lines.append("Velocity: %s" % _fmt_vec3(velocity))
	var direction: Variant = snapshot.get("direction", null)
	if direction is Vector2 and body_part != StringName():
		lines.append("Direction: %s" % _fmt_vec2(direction))
	lines.append("Detector pose lock: %s" % _tracking_status_text(_latest_state))
	var footer := INSPECTOR_FOOTER_TEXT
	if _shared_inspector_target_type == "landmark" and not _should_use_frozen_landmark_inspector():
		footer = "Live values refresh about every %.2fs for readability. %s" % [float(INSPECTOR_LIVE_REFRESH_INTERVAL_MS) / 1000.0, INSPECTOR_FOOTER_TEXT]
	return {
		"title": "Landmark Inspector",
		"subtitle": subtitle,
		"body": "\n".join(lines),
		"footer": footer,
	}

func _capture_landmark_snapshot(landmark_id: int) -> Dictionary:
	var state: Dictionary = _latest_state
	var state_landmarks: Dictionary = state.get("landmarks_by_id", {})
	var raw_landmark := _find_landmark(_latest_landmarks, landmark_id)
	var smoothed_landmark: Dictionary = state_landmarks.get(landmark_id, {}) if state_landmarks is Dictionary else {}
	var landmark := raw_landmark if not raw_landmark.is_empty() else smoothed_landmark
	var tracked := not landmark.is_empty()
	var body_part: StringName = LANDMARK_BODY_PART_HINTS.get(landmark_id, &"")
	var velocity: Variant = null
	var direction: Variant = null
	if body_part != StringName():
		var metrics: Dictionary = state.get("metrics", {})
		velocity = (metrics.get("velocities", {}) as Dictionary).get(String(body_part), null)
		direction = (metrics.get("directions", {}) as Dictionary).get(String(body_part), null)
	return {
		"tracked": tracked,
		"id": landmark_id,
		"name": _landmark_name(landmark_id),
		"x": float(landmark.get("x", 0.0)),
		"y": float(landmark.get("y", 0.0)),
		"z": float(landmark.get("z", 0.0)),
		"visibility": float(landmark.get("v", landmark.get("visibility", 0.0))),
		"has_smoothed_position": not smoothed_landmark.is_empty(),
		"smoothed_x": float(smoothed_landmark.get("x", 0.0)),
		"smoothed_y": float(smoothed_landmark.get("y", 0.0)),
		"smoothed_z": float(smoothed_landmark.get("z", 0.0)),
		"body_part": body_part,
		"velocity": velocity,
		"direction": direction,
	}

func _landmark_name(landmark_id: int) -> String:
	if landmark_id >= 0 and landmark_id < LANDMARK_NAMES.size():
		return String(LANDMARK_NAMES[landmark_id])
	return "Landmark %d" % landmark_id

func _should_freeze_landmark_inspector() -> bool:
	return _shared_inspector_target_type == "landmark" and _is_prerecorded_source_active() and bool(_playback_status.get("paused", false))

func _should_use_frozen_landmark_inspector() -> bool:
	return _shared_inspector_target_type == "landmark" and _is_prerecorded_source_active() and bool(_playback_status.get("paused", false)) and not _shared_inspector_frozen_model.is_empty()

func _reposition_shared_inspector() -> void:
	if _shared_inspector_panel == null:
		return
	_shared_inspector_panel.reset_size()
	var popup_size := _shared_inspector_panel.get_combined_minimum_size()
	_shared_inspector_panel.size = popup_size
	var viewport_size := get_viewport_rect().size
	_shared_inspector_panel.position = Vector2(
		maxf(INSPECTOR_PANEL_MARGIN, viewport_size.x - popup_size.x - INSPECTOR_PANEL_MARGIN),
		INSPECTOR_PANEL_MARGIN
	)

func _refresh_playback_polling() -> void:
	_refresh_playback_controls_visibility()
	if not _is_prerecorded_source_active():
		return
	var now_ms := Time.get_ticks_msec()
	if now_ms < _playback_status_poll_due_ms:
		return
	_refresh_playback_status()

func _refresh_playback_status(force: bool = false) -> void:
	var controller := _resolve_playback_controller()
	if controller == null:
		return
	if not force and not _is_prerecorded_source_active():
		return
	if not _load_playback_source_if_needed():
		return
	_playback_controller_refresh_status()
	_sync_playback_status_from_manager()
	_playback_status_poll_due_ms = Time.get_ticks_msec() + PLAYBACK_STATUS_POLL_INTERVAL_MS

func _load_playback_source_if_needed() -> bool:
	var controller := _resolve_playback_controller()
	if controller == null:
		return false
	var playback_base_url := _playback_base_url()
	if playback_base_url.is_empty():
		return false
	var was_loaded := _playback_controller_has_loaded_media()
	var loaded := _playback_controller_ensure_loaded(playback_base_url)
	if loaded and not was_loaded:
		_playback_controller_play()
	return loaded

func _playback_base_url() -> String:
	var source_url := camera_view.stream_url if camera_view != null else "http://127.0.0.1:4243/camera"
	var slash_index := source_url.rfind("/")
	if slash_index <= 0:
		return source_url.strip_edges()
	return source_url.substr(0, slash_index)

func _refresh_playback_controls_visibility() -> void:
	var visible := _is_prerecorded_source_active() and startup_mode != StartupMode.GODOT_ONLY_DEBUG
	if _playback_bar_panel != null:
		_playback_bar_panel.visible = visible
	if not visible:
		_playback_controller_unload()
		_playback_status = {}
	_refresh_playback_controls_state()

func _sync_playback_status_from_manager() -> void:
	var state: Dictionary = _get_playback_controller_state()
	if state.is_empty():
		return
	var duration := float(state.get("duration", 0.0))
	var position := float(state.get("position", 0.0))
	var normalized := 0.0
	if duration > 0.0:
		normalized = clampf(position / duration, 0.0, 1.0)
	_playback_status = {
		"paused": String(state.get("state", "idle")) != "playing",
		"current_time_sec": position,
		"duration_sec": duration,
		"progress": normalized,
	}
	var backend_state: Variant = state.get("status", {})
	if backend_state is Dictionary:
		for key in backend_state.keys():
			_playback_status[key] = backend_state[key]
	if not bool(_playback_status.get("paused", false)):
		_shared_inspector_frozen_model = {}
		_shared_inspector_live_model = {}
		_shared_inspector_live_refresh_due_ms = 0
	_refresh_playback_controls_state()

func _refresh_playback_controls_state() -> void:
	if _playback_toggle_button == null or _playback_seek_slider == null or _playback_time_label == null:
		return
	var paused := bool(_playback_status.get("paused", true))
	_playback_toggle_button.text = PLAYBACK_ICON_PLAY if paused else PLAYBACK_ICON_PAUSE
	var controls_enabled := _is_prerecorded_source_active() and _playback_controller_has_loaded_media()
	_playback_toggle_button.disabled = not controls_enabled
	_playback_seek_slider.editable = controls_enabled
	if not _playback_slider_drag_active:
		_playback_seek_slider.value = float(_playback_status.get("progress", 0.0))
	_playback_time_label.text = "%s / %s" % [
		_fmt_duration(float(_playback_status.get("current_time_sec", 0.0))),
		_fmt_duration(float(_playback_status.get("duration_sec", 0.0))),
	]

func _on_playback_toggle_pressed() -> void:
	if not _load_playback_source_if_needed():
		return
	if bool(_playback_status.get("paused", true)):
		_playback_controller_play()
	else:
		_playback_controller_pause()
	_sync_playback_status_from_manager()
	_refresh_playback_status(true)

func _on_playback_seek_drag_ended(value_changed: bool) -> void:
	_playback_slider_drag_active = false
	if not value_changed:
		_refresh_playback_controls_state()
		return
	if not _load_playback_source_if_needed():
		return
	var duration := float(_playback_status.get("duration_sec", 0.0))
	var progress := clampf(float(_playback_seek_slider.value), 0.0, 1.0)
	var seconds := duration * progress
	_reset_runtime_debug_state_for_seek()
	_shared_inspector_frozen_model = {}
	_shared_inspector_live_model = {}
	_shared_inspector_live_refresh_due_ms = 0
	_playback_controller_seek(seconds)
	_sync_playback_status_from_manager()
	_refresh_playback_status(true)

func _reset_runtime_debug_state_for_seek() -> void:
	_latest_landmarks.clear()
	_latest_state.clear()
	_left_trail.clear()
	_right_trail.clear()
	_left_trail_debug = _make_trail_debug_state("left")
	_right_trail_debug = _make_trail_debug_state("right")
	_reset_last_flow_events()
	_reset_event_tracking()
	_fixture_capture_started_at_ms = Time.get_ticks_msec()
	_fixture_time_origin_ms = _fixture_capture_started_at_ms
	_fixture_time_origin_reason = "seek"
	_fixture_time_origin_locked = false
	if provider != null and provider.has_method("reset_runtime_state"):
		provider.reset_runtime_state()
	if landmark_drawer:
		landmark_drawer.clear_landmarks()
	if trail_drawer:
		trail_drawer.clear_trails()
	_record_fixture_state_snapshot("seek_reset")
	_refresh_debug_panels()

func _is_prerecorded_source_active() -> bool:
	return not _is_live_camera_source_value(_get_effective_camera_source())

func _fmt_percent(value: Variant) -> String:
	return "%d%%" % int(round(clampf(float(value if value != null else 0.0), 0.0, 1.0) * 100.0))

func _fmt_duration(seconds: float) -> String:
	var total_seconds: int = maxi(int(round(seconds)), 0)
	var minutes: int = int(total_seconds / 60)
	var remaining_seconds: int = total_seconds % 60
	return "%d:%02d" % [minutes, remaining_seconds]

func _refresh_debug_panels() -> void:
	if live_status_label:
		live_status_label.text = _build_live_status_text()
	if quick_stats_label:
		quick_stats_label.text = _build_quick_stats_text()
	if summary_label:
		summary_label.text = _build_summary_text()
	if signal_status_label:
		signal_status_label.text = _build_signal_text()
	if metrics_label:
		metrics_label.text = _build_metrics_text()
	if events_label:
		events_label.text = _build_events_text()
	_refresh_flow_ring_board()
	_refresh_playback_controls_state()

func _build_live_status_text() -> String:
	var state: Dictionary = _latest_state
	var tracking_state := _tracking_status_text(state)
	var pose_count := int(provider.get_num_poses()) if provider != null else 0
	var last_event_name := _latest_event_name()
	var last_event_age := _last_seen_text(last_event_name) if last_event_name != "" else "never"
	return "Live | mode=%s srv=%s cam=%s src=%s pose_lock=%s poses=%d audit=%s last=%s %s" % [
		_get_startup_mode_label(),
		_server_status_text(),
		_camera_status_text("on", "off"),
		_camera_source_compact_text(),
		tracking_state,
		pose_count,
		_preview_only_audit_text(),
		(last_event_name if last_event_name != "" else "none"),
		last_event_age,
	]

func _build_quick_stats_text() -> String:
	var state: Dictionary = _latest_state
	var metrics: Dictionary = state.get("metrics", {})
	var measurements: Dictionary = metrics.get("measurements", {})
	var confidences: Dictionary = metrics.get("confidences", {})
	var gesture_states: Dictionary = state.get("gesture_states", {})
	var gesture_debug: Dictionary = state.get("gesture_debug", {})
	var ready_map: Dictionary = gesture_debug.get("ready", {})
	var flow_debug: Dictionary = gesture_debug.get("flow", {})
	var left_flow: Dictionary = flow_debug.get("left", {})
	var right_flow: Dictionary = flow_debug.get("right", {})
	var pose_count := int(provider.get_num_poses()) if provider != null else 0
	var visible_landmarks := int((state.get("landmarks_by_id", {}) as Dictionary).size())
	var lines := [
		"Quick stats",
		"==========",
		"Mode: %s" % _mode_name(),
		"Startup: %s" % _get_startup_mode_label(),
		"Server: %s" % _server_status_text(),
		"Camera: %s" % _camera_status_text("streaming", "offline"),
		"Source: %s" % _camera_source_summary_text(),
		"Detector pose lock: %s" % _tracking_status_text(state),
		"Tracking style: %s" % String(_tracking_smoothing_style_spec().get("label", "unknown")),
		"Poses: %d" % pose_count,
		"Preview audit: %s" % _preview_only_audit_text(),
		"Visible landmarks: %d" % visible_landmarks,
		"Head confidence: %s" % _fmt_float(confidences.get("head", 0.0)),
		"L hand confidence: %s" % _fmt_float(confidences.get("left_hand", 0.0)),
		"R hand confidence: %s" % _fmt_float(confidences.get("right_hand", 0.0)),
	]
	if harness_mode == HarnessMode.BOXING:
		var armed_count := 0
		for event_name: String in BOXING_ATTACK_EVENTS + BOXING_KNEE_EVENTS:
			if bool(ready_map.get(event_name, true)):
				armed_count += 1
		lines.append("Height state: %s" % String(measurements.get("height_state", &"unknown")))
		lines.append("Guard active: %s" % str(bool(gesture_states.get("guard", false))))
		lines.append("Attack gates armed: %d / %d" % [armed_count, BOXING_ATTACK_EVENTS.size() + BOXING_KNEE_EVENTS.size()])
		if trail_debug_logging:
			lines.append(_format_trail_debug_line(_left_trail_debug))
			lines.append(_format_trail_debug_line(_right_trail_debug))
	else:
		var swing_ready := int(bool(ready_map.get("swing_left", true))) + int(bool(ready_map.get("swing_right", true)))
		var active_trails := int(bool(gesture_states.get("trail_left", false))) + int(bool(gesture_states.get("trail_right", false)))
		lines.append("Swing gates armed: %d / 2" % swing_ready)
		lines.append("Active trails: %d / 2" % active_trails)
		lines.append("Flow candidate L: %s / %s" % [_fmt_flow_candidate(left_flow), _fmt_flow_direction_candidate(left_flow)])
		lines.append("Flow candidate R: %s / %s" % [_fmt_flow_candidate(right_flow), _fmt_flow_direction_candidate(right_flow)])
		lines.append("Trail L points/duration: %d / %dms" % [_left_trail.size(), _trail_duration_ms(_left_trail)])
		lines.append("Trail R points/duration: %d / %dms" % [_right_trail.size(), _trail_duration_ms(_right_trail)])
	return "\n".join(lines)

func _build_summary_text() -> String:
	var state: Dictionary = _latest_state
	var metrics: Dictionary = state.get("metrics", {})
	var measurements: Dictionary = metrics.get("measurements", {})
	var gesture_states: Dictionary = state.get("gesture_states", {})
	var baseline: Dictionary = state.get("baseline", {})
	var lines := [
		"Overview",
		"========",
		"Harness: %s" % scene_title,
		"Startup: %s" % _get_startup_mode_label(),
		"Video source: %s" % _camera_source_summary_text(),
		"Detector pose lock: %s" % _tracking_status_text(state),
		"Tracking style: %s" % String(_tracking_smoothing_style_spec().get("label", "unknown")),
		"Preview audit: %s" % _preview_only_audit_text(),
		"Baseline calibrated: %s" % str(bool(baseline.get("is_calibrated", false))),
		"Baseline frames: %d" % int(baseline.get("sample_frames", 0)),
		"Shoulder width: %s" % _fmt_float(measurements.get("shoulder_width", 0.0)),
		"Torso height: %s" % _fmt_float(measurements.get("torso_height", 0.0)),
	]
	if harness_mode == HarnessMode.BOXING:
		lines.append("")
		lines.append("Body states")
		lines.append("-----------")
		lines.append("guard=%s squat=%s" % [str(bool(gesture_states.get("guard", false))), str(bool(gesture_states.get("squat", false)))])
		lines.append("weave_left=%s weave_right=%s" % [str(bool(gesture_states.get("weave_left", false))), str(bool(gesture_states.get("weave_right", false)))])
		lines.append("sidestep_left=%s sidestep_right=%s" % [str(bool(gesture_states.get("sidestep_left", false))), str(bool(gesture_states.get("sidestep_right", false)))])
		lines.append("leg_lift_left=%s leg_lift_right=%s" % [str(bool(gesture_states.get("leg_lift_left", false))), str(bool(gesture_states.get("leg_lift_right", false)))])
		lines.append("height=%s ratio=%s squat_depth=%s" % [String(measurements.get("height_state", &"unknown")), _fmt_float(measurements.get("height_ratio", 0.0)), _fmt_float(measurements.get("squat_depth", 0.0))])
		lines.append("head/hip lateral=%s / %s" % [_fmt_float(measurements.get("head_lateral_offset", 0.0)), _fmt_float(measurements.get("hip_lateral_offset", 0.0))])
		if trail_debug_logging:
			lines.append("")
			lines.append("Trail continuity")
			lines.append("----------------")
			lines.append(_format_trail_debug_line(_left_trail_debug))
			lines.append(_format_trail_debug_line(_right_trail_debug))
	else:
		var gesture_debug: Dictionary = state.get("gesture_debug", {})
		var ready_map: Dictionary = gesture_debug.get("ready", {})
		var flow_debug: Dictionary = gesture_debug.get("flow", {})
		var left_flow: Dictionary = flow_debug.get("left", {})
		var right_flow: Dictionary = flow_debug.get("right", {})
		lines.append("")
		lines.append("Flow event summary")
		lines.append("------------------")
		for key: String in ["swing_left", "swing_right", "trail_left", "trail_right"]:
			lines.append("%s: %s" % [key, _describe_last_flow_event(key)])
		lines.append("swing_ready L/R=%s / %s" % [str(bool(ready_map.get("swing_left", true))), str(bool(ready_map.get("swing_right", true)))])
		lines.append("trail_active L/R=%s / %s" % [str(bool(gesture_states.get("trail_left", false))), str(bool(gesture_states.get("trail_right", false)))])
		lines.append("placement vs direction L=%s / %s" % [_fmt_flow_candidate(left_flow), _fmt_flow_direction_candidate(left_flow)])
		lines.append("placement vs direction R=%s / %s" % [_fmt_flow_candidate(right_flow), _fmt_flow_direction_candidate(right_flow)])
		lines.append("Mirrored-hand sanity")
		lines.append("-------------------")
		lines.append(_format_flow_sanity_line("left", left_flow))
		lines.append(_format_flow_sanity_line("right", right_flow))
		lines.append("Local continuity: L=%d pts (%dms), R=%d pts (%dms)" % [_left_trail.size(), _trail_duration_ms(_left_trail), _right_trail.size(), _trail_duration_ms(_right_trail)])
	return "\n".join(lines)

func _build_signal_text() -> String:
	if harness_mode == HarnessMode.BOXING:
		return _build_boxing_signal_text()
	return _build_flow_signal_text()

func _build_boxing_signal_text() -> String:
	var state: Dictionary = _latest_state
	var metrics: Dictionary = state.get("metrics", {})
	var measurements: Dictionary = metrics.get("measurements", {})
	var gesture_states: Dictionary = state.get("gesture_states", {})
	var gesture_debug: Dictionary = state.get("gesture_debug", {})
	var ready_map: Dictionary = gesture_debug.get("ready", {})
	var guard_active := bool(gesture_states.get("guard", false))
	var lines := [
		"Boxing signal board",
		"===================",
		"Persistent status/counters for the supported Boxing surface.",
		"guard suppression: %s" % ("ON" if guard_active else "OFF"),
		"",
		"Punch / hook / uppercut families",
		"-----------------------------",
	]
	for event_name: String in BOXING_ATTACK_EVENTS:
		lines.append(_format_attack_signal_row(event_name, ready_map, guard_active))
	lines.append("")
	lines.append("Guard + body-state transitions")
	lines.append("-----------------------------")
	for row_variant: Variant in BOXING_STATE_ROWS:
		var row: Dictionary = row_variant
		lines.append(_format_state_signal_row(String(row.get("label", "")), String(row.get("state", "")), String(row.get("start", "")), String(row.get("end", "")), gesture_states))
	lines.append("")
	lines.append("Knees / leg lifts")
	lines.append("-----------------")
	for event_name: String in BOXING_KNEE_EVENTS:
		lines.append(_format_attack_signal_row(event_name, ready_map, false))
	lines.append(_format_state_signal_row("leg_lift_left", "leg_lift_left", "leg_lift_left_start", "leg_lift_left_end", gesture_states))
	lines.append(_format_state_signal_row("leg_lift_right", "leg_lift_right", "leg_lift_right_start", "leg_lift_right_end", gesture_states))
	lines.append("")
	lines.append("Current detector inputs")
	lines.append("----------------------")
	lines.append("L extension=%s  elbow=%s°  3D=%s / %s°  fwd=%s / %s" % [_fmt_float(measurements.get("left_arm_extension", 0.0)), _fmt_float(measurements.get("left_elbow_bend_deg", 0.0)), _fmt_float(measurements.get("left_arm_extension_3d", 0.0)), _fmt_float(measurements.get("left_elbow_bend_deg_3d", 0.0)), _fmt_float(measurements.get("left_forward_distance", 0.0)), _fmt_float(measurements.get("left_forward_velocity", 0.0))])
	lines.append("R extension=%s  elbow=%s°  3D=%s / %s°  fwd=%s / %s" % [_fmt_float(measurements.get("right_arm_extension", 0.0)), _fmt_float(measurements.get("right_elbow_bend_deg", 0.0)), _fmt_float(measurements.get("right_arm_extension_3d", 0.0)), _fmt_float(measurements.get("right_elbow_bend_deg_3d", 0.0)), _fmt_float(measurements.get("right_forward_distance", 0.0)), _fmt_float(measurements.get("right_forward_velocity", 0.0))])
	lines.append("squat depth=%s  head drop=%s" % [_fmt_float(measurements.get("squat_depth", 0.0)), _fmt_float(measurements.get("head_drop_ratio", 0.0))])
	lines.append("lateral body/head/hip=%s / %s / %s" % [_fmt_float(measurements.get("lateral_offset", 0.0)), _fmt_float(measurements.get("head_lateral_offset", 0.0)), _fmt_float(measurements.get("hip_lateral_offset", 0.0))])
	lines.append("L knee/foot rise=%s / %s" % [_fmt_float(measurements.get("left_knee_rise", 0.0)), _fmt_float(measurements.get("left_foot_rise", 0.0))])
	lines.append("R knee/foot rise=%s / %s" % [_fmt_float(measurements.get("right_knee_rise", 0.0)), _fmt_float(measurements.get("right_foot_rise", 0.0))])
	return "\n".join(lines)

func _build_flow_signal_text() -> String:
	var state: Dictionary = _latest_state
	var gesture_states: Dictionary = state.get("gesture_states", {})
	var gesture_debug: Dictionary = state.get("gesture_debug", {})
	var ready_map: Dictionary = gesture_debug.get("ready", {})
	var flow_debug: Dictionary = gesture_debug.get("flow", {})
	var left_flow: Dictionary = flow_debug.get("left", {})
	var right_flow: Dictionary = flow_debug.get("right", {})
	var lines := [
		"Flow signal board",
		"=================",
		"Persistent status/counters for swings, trails, readiness, and candidate truth.",
		"",
		"Left hand surface",
		"-----------------",
		_format_flow_event_row("swing_left", left_flow, ready_map, false),
		_format_flow_event_row("trail_left", left_flow, ready_map, bool(gesture_states.get("trail_left", false))),
		_format_flow_candidate_row("left", left_flow),
		"",
		"Right hand surface",
		"------------------",
		_format_flow_event_row("swing_right", right_flow, ready_map, false),
		_format_flow_event_row("trail_right", right_flow, ready_map, bool(gesture_states.get("trail_right", false))),
		_format_flow_candidate_row("right", right_flow),
	]
	return "\n".join(lines)

func _build_metrics_text() -> String:
	var state: Dictionary = _latest_state
	var metrics: Dictionary = state.get("metrics", {})
	var measurements: Dictionary = metrics.get("measurements", {})
	var confidences: Dictionary = metrics.get("confidences", {})
	var velocities: Dictionary = metrics.get("velocities", {})
	var directions: Dictionary = metrics.get("directions", {})
	var lines := [
		"Detector metrics",
		"================",
		"Confidences: head=%s torso=%s" % [_fmt_float(confidences.get("head", 0.0)), _fmt_float(confidences.get("torso", 0.0))],
		"             left_hand=%s right_hand=%s" % [_fmt_float(confidences.get("left_hand", 0.0)), _fmt_float(confidences.get("right_hand", 0.0))],
		"             left_foot=%s right_foot=%s" % [_fmt_float(confidences.get("left_foot", 0.0)), _fmt_float(confidences.get("right_foot", 0.0))],
		"Velocities:  L hand=%s" % _fmt_vec3(velocities.get("left_hand", Vector3.ZERO)),
		"             R hand=%s" % _fmt_vec3(velocities.get("right_hand", Vector3.ZERO)),
		"             L foot=%s" % _fmt_vec3(velocities.get("left_foot", Vector3.ZERO)),
		"             R foot=%s" % _fmt_vec3(velocities.get("right_foot", Vector3.ZERO)),
		"Directions:  L hand=%s R hand=%s" % [_fmt_vec2(directions.get("left_hand", Vector2.ZERO)), _fmt_vec2(directions.get("right_hand", Vector2.ZERO))],
	]
	if harness_mode == HarnessMode.BOXING:
		lines.append("")
		lines.append("Boxing threshold readouts")
		lines.append("------------------------")
		lines.append("L arm ext=%s elbow=%s° | 3D ext=%s elbow=%s°" % [_fmt_float(measurements.get("left_arm_extension", 0.0)), _fmt_float(measurements.get("left_elbow_bend_deg", 0.0)), _fmt_float(measurements.get("left_arm_extension_3d", 0.0)), _fmt_float(measurements.get("left_elbow_bend_deg_3d", 0.0))])
		lines.append("R arm ext=%s elbow=%s° | 3D ext=%s elbow=%s°" % [_fmt_float(measurements.get("right_arm_extension", 0.0)), _fmt_float(measurements.get("right_elbow_bend_deg", 0.0)), _fmt_float(measurements.get("right_arm_extension_3d", 0.0)), _fmt_float(measurements.get("right_elbow_bend_deg_3d", 0.0))])
		lines.append("L fwd dist/vel=%s / %s lock=%s lane=%s" % [_fmt_float(measurements.get("left_forward_distance", 0.0)), _fmt_float(measurements.get("left_forward_velocity", 0.0)), str(bool(measurements.get("left_own_half_lock", false))), _fmt_float(measurements.get("left_lane_offset_ratio", 0.0))])
		lines.append("R fwd dist/vel=%s / %s lock=%s lane=%s" % [_fmt_float(measurements.get("right_forward_distance", 0.0)), _fmt_float(measurements.get("right_forward_velocity", 0.0)), str(bool(measurements.get("right_own_half_lock", false))), _fmt_float(measurements.get("right_lane_offset_ratio", 0.0))])
		lines.append("height_ratio=%s head_drop=%s" % [_fmt_float(measurements.get("height_ratio", 0.0)), _fmt_float(measurements.get("head_drop_ratio", 0.0))])
		lines.append("lateral body/head/hip=%s / %s / %s" % [_fmt_float(measurements.get("lateral_offset", 0.0)), _fmt_float(measurements.get("head_lateral_offset", 0.0)), _fmt_float(measurements.get("hip_lateral_offset", 0.0))])
		lines.append("L knee/foot rise=%s / %s" % [_fmt_float(measurements.get("left_knee_rise", 0.0)), _fmt_float(measurements.get("left_foot_rise", 0.0))])
		lines.append("R knee/foot rise=%s / %s" % [_fmt_float(measurements.get("right_knee_rise", 0.0)), _fmt_float(measurements.get("right_foot_rise", 0.0))])
		lines.append("L leg angle=%s°  R leg angle=%s°" % [_fmt_float(measurements.get("left_leg_angle_from_core_deg", 0.0)), _fmt_float(measurements.get("right_leg_angle_from_core_deg", 0.0))])
	else:
		var gesture_debug: Dictionary = state.get("gesture_debug", {})
		var flow_debug: Dictionary = gesture_debug.get("flow", {})
		var left_flow: Dictionary = flow_debug.get("left", {})
		var right_flow: Dictionary = flow_debug.get("right", {})
		lines.append("")
		lines.append("Flow / continuity readouts")
		lines.append("-------------------------")
		lines.append("Left hand")
		lines.append(_format_flow_analysis_line("swing window", left_flow.get("swing_analysis", {})))
		lines.append(_format_flow_analysis_line("trail window", left_flow.get("trail_analysis", {})))
		lines.append("latest pos=%s conf=%s avg_x=%s offset=%s" % [_fmt_vec2(left_flow.get("latest_position", Vector2.ZERO)), _fmt_float(left_flow.get("latest_confidence", 0.0)), _fmt_float(left_flow.get("avg_x", 0.0)), _fmt_float(left_flow.get("center_offset_ratio", 0.0))])
		lines.append("vel=%s dir=%s" % [_fmt_vec3(velocities.get("left_hand", Vector3.ZERO)), _fmt_vec2(directions.get("left_hand", Vector2.ZERO))])
		lines.append("")
		lines.append("Right hand")
		lines.append(_format_flow_analysis_line("swing window", right_flow.get("swing_analysis", {})))
		lines.append(_format_flow_analysis_line("trail window", right_flow.get("trail_analysis", {})))
		lines.append("latest pos=%s conf=%s avg_x=%s offset=%s" % [_fmt_vec2(right_flow.get("latest_position", Vector2.ZERO)), _fmt_float(right_flow.get("latest_confidence", 0.0)), _fmt_float(right_flow.get("avg_x", 0.0)), _fmt_float(right_flow.get("center_offset_ratio", 0.0))])
		lines.append("vel=%s dir=%s" % [_fmt_vec3(velocities.get("right_hand", Vector3.ZERO)), _fmt_vec2(directions.get("right_hand", Vector2.ZERO))])
		lines.append("")
		lines.append("Placement is detector-emitted; local trail durations remain on-screen for continuity sanity only.")
	return "\n".join(lines)

func _format_flow_event_row(event_name: String, hand_debug: Dictionary, ready_map: Dictionary, active: bool) -> String:
	var event_kind := "swing" if event_name.begins_with("swing_") else "trail"
	var analysis: Dictionary = hand_debug.get("swing_analysis", {}) if event_kind == "swing" else hand_debug.get("trail_analysis", {})
	var meta: Dictionary = hand_debug.get("swing_meta", {}) if event_kind == "swing" else hand_debug.get("trail_meta", {})
	var status := "ACTIVE" if event_kind == "trail" and active else ("READY" if bool(ready_map.get(event_name, true)) else "RESET")
	if event_kind == "trail" and not active:
		status = "IDLE"
	return "%s  status=%s  count=%d  last=%s  emitted=%s/%s  cand=%s/%s  dur=%dms  arc=%s  net=%s  cons=%s  lane=%s  conf=%s" % [
		event_name,
		status,
		_event_count(event_name),
		_last_seen_text(event_name),
		_fmt_flow_index(meta.get("placement", -1), meta.get("placement_ui_label", 0), true),
		_fmt_flow_index(meta.get("direction", -1), meta.get("direction_ui_label", 0), false),
		_fmt_flow_candidate(hand_debug),
		_fmt_flow_direction_candidate(hand_debug),
		int(analysis.get("duration_ms", 0)),
		_fmt_float(analysis.get("arc_length", 0.0)),
		_fmt_float(analysis.get("net_distance", 0.0)),
		_fmt_float(analysis.get("directional_consistency", 0.0)),
		_fmt_float(analysis.get("lane_spread", 0.0)),
		_fmt_float(analysis.get("avg_confidence", 0.0)),
	]

func _format_flow_candidate_row(side: String, hand_debug: Dictionary) -> String:
	return "%s hand  history=%d pts / %dms  latest=%s  avg_x=%s  center_offset=%s  placement=%s  direction=%s" % [
		side,
		int(hand_debug.get("history_points", 0)),
		int(hand_debug.get("history_duration_ms", 0)),
		_fmt_vec2(hand_debug.get("latest_position", Vector2.ZERO)),
		_fmt_float(hand_debug.get("avg_x", 0.0)),
		_fmt_float(hand_debug.get("center_offset_ratio", 0.0)),
		_fmt_flow_candidate(hand_debug),
		_fmt_flow_direction_candidate(hand_debug),
	]

func _format_flow_analysis_line(label: String, analysis_variant: Variant) -> String:
	var analysis: Dictionary = analysis_variant if analysis_variant is Dictionary else {}
	if analysis.is_empty():
		return "%s: no candidate yet" % label
	return "%s: samples=%d dur=%dms arc=%s net=%s cons=%s lane=%s conf=%s placement=%s direction=%s" % [
		label,
		int(analysis.get("sample_count", 0)),
		int(analysis.get("duration_ms", 0)),
		_fmt_float(analysis.get("arc_length", 0.0)),
		_fmt_float(analysis.get("net_distance", 0.0)),
		_fmt_float(analysis.get("directional_consistency", 0.0)),
		_fmt_float(analysis.get("lane_spread", 0.0)),
		_fmt_float(analysis.get("avg_confidence", 0.0)),
		_fmt_flow_index(analysis.get("placement", -1), analysis.get("placement_ui_label", 0), true),
		_fmt_flow_index(analysis.get("direction", -1), analysis.get("direction_ui_label", 0), false),
	]

func _format_flow_sanity_line(side: String, hand_debug: Dictionary) -> String:
	return "%s hand: latest=%s avg_x=%s offset=%s placement=%s direction=%s" % [
		side,
		_fmt_vec2(hand_debug.get("latest_position", Vector2.ZERO)),
		_fmt_float(hand_debug.get("avg_x", 0.0)),
		_fmt_float(hand_debug.get("center_offset_ratio", 0.0)),
		_fmt_flow_candidate(hand_debug),
		_fmt_flow_direction_candidate(hand_debug),
	]

func _fmt_flow_candidate(hand_debug: Dictionary) -> String:
	return _fmt_flow_index(hand_debug.get("placement_candidate", -1), hand_debug.get("placement_candidate_ui_label", 0), true)

func _fmt_flow_direction_candidate(hand_debug: Dictionary) -> String:
	return _fmt_flow_index(hand_debug.get("direction_candidate", -1), hand_debug.get("direction_candidate_ui_label", 0), false)

func _fmt_flow_index(value_variant: Variant, ui_label_variant: Variant, is_placement: bool) -> String:
	var value := int(value_variant)
	if value < 0:
		return "-"
	var ui_label := int(ui_label_variant)
	var suffix := ""
	if is_placement and value == 12:
		suffix = " center"
	return "%d[u%d]%s" % [value, ui_label, suffix]

func _build_events_text() -> String:
	if harness_mode == HarnessMode.FLOW:
		if _event_lines.is_empty():
			return "Waiting for events..."
		return "\n".join(_event_lines)
	var lines := ["Live events", "==========="]
	if _event_lines.is_empty():
		lines.append("(waiting for detector activity)")
	else:
		lines.append_array(_event_lines)
	return "\n".join(lines)

func _refresh_flow_ring_board() -> void:
	if harness_mode != HarnessMode.FLOW:
		return
	var flow_debug: Dictionary = (_latest_state.get("gesture_debug", {}) as Dictionary).get("flow", {})
	var left_flow: Dictionary = flow_debug.get("left", {})
	var right_flow: Dictionary = flow_debug.get("right", {})
	_set_flow_chart_active_index(left_placement_chart, _resolve_flow_board_index(left_flow, true, false))
	_set_flow_chart_active_index(right_placement_chart, _resolve_flow_board_index(right_flow, true, false))
	_set_flow_chart_active_index(left_direction_chart, _resolve_flow_board_index(left_flow, false, false))
	_set_flow_chart_active_index(right_direction_chart, _resolve_flow_board_index(right_flow, false, false))

func _resolve_flow_board_index(hand_debug: Dictionary, is_placement: bool, prefer_last_emitted: bool) -> int:
	var candidate_key := "placement_candidate" if is_placement else "direction_candidate"
	var emitted_meta_key := "trail_meta"
	if prefer_last_emitted and hand_debug.has(emitted_meta_key):
		var emitted_meta: Dictionary = hand_debug.get(emitted_meta_key, {})
		var emitted_index := int(emitted_meta.get("placement" if is_placement else "direction", -1))
		if emitted_index >= 0:
			return emitted_index
	return int(hand_debug.get(candidate_key, -1))

func _set_flow_chart_active_index(chart: Control, active_index: int) -> void:
	if chart == null or not is_instance_valid(chart):
		return
	chart.set("active_index", active_index)

func _record_event(event_name: String, payload: Dictionary) -> void:
	var timestamp_ms := Time.get_ticks_msec()
	_event_counts[event_name] = int(_event_counts.get(event_name, 0)) + 1
	_last_event_payloads[event_name] = payload.duplicate(true)
	_last_event_timestamps_ms[event_name] = timestamp_ms
	_fixture_event_timeline.append({
		"sequence": _fixture_event_timeline.size() + 1,
		"name": event_name,
		"timestamp_ms": _fixture_relative_ms(timestamp_ms),
		"payload": payload.duplicate(true),
		"count": int(_event_counts.get(event_name, 0)),
		"mode": _mode_name().to_lower(),
	})
	_append_event_feed_lines(event_name, payload)
	if _should_log_event_to_console(event_name):
		print("[ProvingHarness][%s] %s%s" % [_mode_name(), event_name, _format_event_payload(payload)])
	_refresh_debug_panels()
	if steady_state_console_debug:
		_emit_console_snapshot_if_changed()

func _append_event_feed_lines(event_name: String, payload: Dictionary) -> void:
	var lines := _build_event_feed_lines(event_name, payload)
	for line: String in lines:
		_event_sequence += 1
		_event_lines.append("%04d: %s" % [_event_sequence, line])
	while _event_lines.size() > MAX_EVENT_LINES:
		_event_lines.remove_at(0)

func _build_event_feed_lines(event_name: String, payload: Dictionary) -> Array[String]:
	if harness_mode == HarnessMode.FLOW and payload.has("placement") and payload.has("direction"):
		var side_label := "Left Bat" if event_name.ends_with("_left") else "Right Bat"
		return [
			"%s Placement - %d" % [side_label, _flow_ui_label_from_value(int(payload.get("placement", -1)), true)],
			"%s Direction - %d" % [side_label, _flow_ui_label_from_value(int(payload.get("direction", -1)), false)],
		]
	return [event_name + _format_event_payload(payload)]

func _flow_ui_label_from_value(value: int, is_placement: bool) -> int:
	if value < 0:
		return 0
	if is_placement and value == 12:
		return 13
	return value + 1

func _should_log_event_to_console(event_name: String) -> bool:
	if steady_state_console_debug:
		return true
	return event_name in ["server_failed", "camera_stream_failed", "preview_only_invalid"]

func _format_event_payload(payload: Dictionary) -> String:
	if payload.is_empty():
		return ""
	var parts: Array[String] = []
	for key_variant: Variant in payload.keys():
		var key := String(key_variant)
		var value: Variant = payload[key_variant]
		if value is float:
			parts.append("%s=%.3f" % [key, value])
		else:
			parts.append("%s=%s" % [key, str(value)])
	return "  [" + ", ".join(parts) + "]"

func _describe_last_flow_event(event_name: String) -> String:
	var event_data: Dictionary = _last_flow_events.get(event_name, {})
	if event_data.is_empty():
		return "none"
	var age_ms := Time.get_ticks_msec() - int(event_data.get("timestamp_ms", 0))
	return "%s / %s (%dms ago)" % [_fmt_flow_index(event_data.get("placement", -1), int(event_data.get("placement", -1)) + 1, true), _fmt_flow_index(event_data.get("direction", -1), int(event_data.get("direction", -1)) + 1, false), age_ms]

func _trail_duration_ms(trail: Array) -> int:
	if trail.size() < 2:
		return 0
	return max(int(trail[trail.size() - 1].get("timestamp_ms", 0)) - int(trail[0].get("timestamp_ms", 0)), 0)

func _reset_last_flow_events() -> void:
	_last_flow_events = {
		"swing_left": {},
		"swing_right": {},
		"trail_left": {},
		"trail_right": {},
	}

func _reset_event_tracking() -> void:
	_event_lines = []
	_event_counts = {}
	_last_event_payloads = {}
	_last_event_timestamps_ms = {}
	_event_sequence = 0
	_fixture_event_timeline = []
	_fixture_state_timeline = []
	_fixture_state_sequence = 0
	for event_name: String in BOXING_EVENT_ORDER + FLOW_EVENT_ORDER + ["provider_started", "tracking_lost", "tracking_restored", "camera_stream_failed", "server_failed", "preview_only_provider_disabled", "preview_only_invalid"]:
		_event_counts[event_name] = 0

func _maybe_anchor_fixture_time_origin_to_provider_ready() -> void:
	if _fixture_time_origin_locked:
		return
	if String(_latest_state.get("tracking_state", &"")) != "tracking":
		return
	var ready_timestamp_ms := Time.get_ticks_msec()
	_rebase_fixture_capture_timeline(ready_timestamp_ms - _fixture_time_origin_ms)
	_fixture_time_origin_ms = ready_timestamp_ms
	_fixture_time_origin_reason = "first_tracking_pose"
	_fixture_time_origin_locked = true

func _rebase_fixture_capture_timeline(delta_ms: int) -> void:
	if delta_ms == 0:
		return
	for event_entry: Dictionary in _fixture_event_timeline:
		event_entry["timestamp_ms"] = max(int(event_entry.get("timestamp_ms", 0)) - delta_ms, 0)
	for state_entry: Dictionary in _fixture_state_timeline:
		state_entry["timestamp_ms"] = max(int(state_entry.get("timestamp_ms", 0)) - delta_ms, 0)

func _fixture_relative_ms(timestamp_ms: int = -1) -> int:
	var effective_timestamp := timestamp_ms if timestamp_ms >= 0 else Time.get_ticks_msec()
	if _fixture_time_origin_ms <= 0:
		return 0
	return max(effective_timestamp - _fixture_time_origin_ms, 0)

func _build_fixture_boxing_debug_snapshot() -> Dictionary:
	var state: Dictionary = _latest_state
	var metrics: Dictionary = state.get("metrics", {})
	var measurements: Dictionary = metrics.get("measurements", {})
	var velocities: Dictionary = metrics.get("velocities", {})
	var gesture_debug: Dictionary = state.get("gesture_debug", {})
	var ready_map: Dictionary = (gesture_debug.get("ready", {}) as Dictionary)
	var straight_punch_debug: Dictionary = (gesture_debug.get("straight_punch", {}) as Dictionary)
	var landmarks: Dictionary = state.get("landmarks_by_id", {})
	var left_shoulder: Dictionary = landmarks.get(PoseLandmarkIds.LEFT_SHOULDER, {})
	var right_shoulder: Dictionary = landmarks.get(PoseLandmarkIds.RIGHT_SHOULDER, {})
	var left_elbow: Dictionary = landmarks.get(PoseLandmarkIds.LEFT_ELBOW, {})
	var right_elbow: Dictionary = landmarks.get(PoseLandmarkIds.RIGHT_ELBOW, {})
	var left_wrist: Dictionary = landmarks.get(PoseLandmarkIds.LEFT_WRIST, {})
	var right_wrist: Dictionary = landmarks.get(PoseLandmarkIds.RIGHT_WRIST, {})
	var shoulder_width := maxf(float(measurements.get("shoulder_width", 0.0)), 0.000001)
	var left_hand_velocity: Vector3 = velocities.get("left_hand", Vector3.ZERO)
	var right_hand_velocity: Vector3 = velocities.get("right_hand", Vector3.ZERO)
	var guard_aligned_left := false
	var guard_aligned_right := false
	var guard_raised_left := false
	var guard_raised_right := false
	var guard_wrist_near_head_left := false
	var guard_wrist_near_head_right := false
	if not left_wrist.is_empty() and not left_elbow.is_empty():
		guard_aligned_left = absf(float(left_wrist.get("x", 0.0)) - float(left_elbow.get("x", 0.0))) <= shoulder_width * 0.32
	if not right_wrist.is_empty() and not right_elbow.is_empty():
		guard_aligned_right = absf(float(right_wrist.get("x", 0.0)) - float(right_elbow.get("x", 0.0))) <= shoulder_width * 0.32
	if not left_wrist.is_empty() and not left_shoulder.is_empty():
		guard_raised_left = float(left_wrist.get("y", 0.0)) >= float(left_shoulder.get("y", 0.0)) - shoulder_width * 0.10
		guard_wrist_near_head_left = absf(float(left_wrist.get("x", 0.0)) - float(left_shoulder.get("x", 0.0))) <= shoulder_width * 0.55
	if not right_wrist.is_empty() and not right_shoulder.is_empty():
		guard_raised_right = float(right_wrist.get("y", 0.0)) >= float(right_shoulder.get("y", 0.0)) - shoulder_width * 0.10
		guard_wrist_near_head_right = absf(float(right_wrist.get("x", 0.0)) - float(right_shoulder.get("x", 0.0))) <= shoulder_width * 0.55
	return {
		"left_straight": {
			"arm_extension": float(measurements.get("left_arm_extension", 0.0)),
			"arm_extension_3d": float(measurements.get("left_arm_extension_3d", 0.0)),
			"elbow_bend_deg": float(measurements.get("left_elbow_bend_deg", 0.0)),
			"elbow_bend_deg_3d": float(measurements.get("left_elbow_bend_deg_3d", 0.0)),
			"outward_velocity": -left_hand_velocity.x,
			"forward_velocity": float(measurements.get("left_forward_velocity", 0.0)),
			"outward_distance": float(measurements.get("left_outward_distance", 0.0)),
			"forward_distance": float(measurements.get("left_forward_distance", 0.0)),
			"lane_offset_ratio": float(measurements.get("left_lane_offset_ratio", 0.0)),
			"own_half_lock": bool(measurements.get("left_own_half_lock", false)),
			"lateral_speed": absf(left_hand_velocity.x),
			"vertical_speed": absf(left_hand_velocity.y),
			"ready": bool(ready_map.get("punch_left", false)),
			"phase": String((straight_punch_debug.get("left", {}) as Dictionary).get("phase", "recovering")),
			"armed_forward_distance": float((straight_punch_debug.get("left", {}) as Dictionary).get("armed_forward_distance", 0.0)),
			"peak_forward_distance": float((straight_punch_debug.get("left", {}) as Dictionary).get("peak_forward_distance", 0.0)),
		},
		"right_straight": {
			"arm_extension": float(measurements.get("right_arm_extension", 0.0)),
			"arm_extension_3d": float(measurements.get("right_arm_extension_3d", 0.0)),
			"elbow_bend_deg": float(measurements.get("right_elbow_bend_deg", 0.0)),
			"elbow_bend_deg_3d": float(measurements.get("right_elbow_bend_deg_3d", 0.0)),
			"outward_velocity": right_hand_velocity.x,
			"forward_velocity": float(measurements.get("right_forward_velocity", 0.0)),
			"outward_distance": float(measurements.get("right_outward_distance", 0.0)),
			"forward_distance": float(measurements.get("right_forward_distance", 0.0)),
			"lane_offset_ratio": float(measurements.get("right_lane_offset_ratio", 0.0)),
			"own_half_lock": bool(measurements.get("right_own_half_lock", false)),
			"lateral_speed": absf(right_hand_velocity.x),
			"vertical_speed": absf(right_hand_velocity.y),
			"ready": bool(ready_map.get("punch_right", false)),
			"phase": String((straight_punch_debug.get("right", {}) as Dictionary).get("phase", "recovering")),
			"armed_forward_distance": float((straight_punch_debug.get("right", {}) as Dictionary).get("armed_forward_distance", 0.0)),
			"peak_forward_distance": float((straight_punch_debug.get("right", {}) as Dictionary).get("peak_forward_distance", 0.0)),
		},
		"guard": {
			"state": bool((state.get("gesture_states", {}) as Dictionary).get("guard", false)),
			"aligned_left": guard_aligned_left,
			"aligned_right": guard_aligned_right,
			"raised_left": guard_raised_left,
			"raised_right": guard_raised_right,
			"wrist_near_head_left": guard_wrist_near_head_left,
			"wrist_near_head_right": guard_wrist_near_head_right,
			"candidate": guard_aligned_left and guard_aligned_right and guard_raised_left and guard_raised_right and guard_wrist_near_head_left and guard_wrist_near_head_right,
		},
	}

func _record_fixture_state_snapshot(reason: String) -> void:
	_fixture_state_sequence += 1
	_fixture_state_timeline.append({
		"sequence": _fixture_state_sequence,
		"timestamp_ms": _fixture_relative_ms(),
		"reason": reason,
		"tracking_state": _tracking_status_text(_latest_state),
		"gesture_states": (_latest_state.get("gesture_states", {}) as Dictionary).duplicate(true),
		"ready": ((_latest_state.get("gesture_debug", {}) as Dictionary).get("ready", {}) as Dictionary).duplicate(true),
		"flow": ((_latest_state.get("gesture_debug", {}) as Dictionary).get("flow", {}) as Dictionary).duplicate(true),
		"boxing_debug": _build_fixture_boxing_debug_snapshot(),
		"latest_event": _latest_event_name(),
	})

func get_fixture_capture_report() -> Dictionary:
	return {
		"time_basis": "provider_tracking_ms_since_first_pose",
		"time_origin_reason": _fixture_time_origin_reason,
		"time_origin_offset_ms": max(_fixture_time_origin_ms - _fixture_capture_started_at_ms, 0),
		"harness_mode": _mode_name().to_lower(),
		"startup_mode": _get_startup_mode_label(),
		"camera_source": _get_effective_camera_source(),
		"event_timeline": _fixture_event_timeline.duplicate(true),
		"state_timeline": _fixture_state_timeline.duplicate(true),
		"latest_state": _latest_state.duplicate(true),
	}

func _format_attack_signal_row(event_name: String, ready_map: Dictionary, guard_suppressed: bool) -> String:
	var status := "READY" if bool(ready_map.get(event_name, true)) else "RESET"
	if guard_suppressed and BOXING_ATTACK_EVENTS.has(event_name):
		status = "SUPPRESSED"
	var power_text := ""
	var payload: Dictionary = _last_event_payloads.get(event_name, {})
	if payload.has("power"):
		power_text = " power=%s" % _fmt_float(payload.get("power", 0.0))
	return "%s  status=%s  count=%d  last=%s%s" % [event_name, status, _event_count(event_name), _last_seen_text(event_name), power_text]

func _format_state_signal_row(label: String, state_name: String, start_event: String, end_event: String, gesture_states: Dictionary) -> String:
	var active := bool(gesture_states.get(state_name, false))
	return "%s  active=%s  start/end=%d/%d  last=%s" % [label, str(active), _event_count(start_event), _event_count(end_event), _last_transition_text(start_event, end_event)]

func _event_count(event_name: String) -> int:
	return int(_event_counts.get(event_name, 0))

func _last_seen_text(event_name: String) -> String:
	var timestamp_ms := int(_last_event_timestamps_ms.get(event_name, 0))
	if timestamp_ms <= 0:
		return "never"
	return _fmt_age_ms(Time.get_ticks_msec() - timestamp_ms)

func _last_transition_text(start_event: String, end_event: String) -> String:
	var start_ts := int(_last_event_timestamps_ms.get(start_event, 0))
	var end_ts := int(_last_event_timestamps_ms.get(end_event, 0))
	if start_ts <= 0 and end_ts <= 0:
		return "never"
	if start_ts >= end_ts:
		return "%s %s ago" % [start_event, _fmt_age_ms(Time.get_ticks_msec() - start_ts)]
	return "%s %s ago" % [end_event, _fmt_age_ms(Time.get_ticks_msec() - end_ts)]

func _fmt_age_ms(age_ms: int) -> String:
	if age_ms < 1000:
		return "%dms" % age_ms
	return "%.1fs" % (float(age_ms) / 1000.0)

func _latest_event_name() -> String:
	var latest_name := ""
	var latest_timestamp := -1
	for event_name_variant: Variant in _last_event_timestamps_ms.keys():
		var event_name := String(event_name_variant)
		var timestamp_ms := int(_last_event_timestamps_ms.get(event_name_variant, 0))
		if timestamp_ms > latest_timestamp:
			latest_timestamp = timestamp_ms
			latest_name = event_name
	return latest_name

func _build_console_snapshot() -> String:
	var state: Dictionary = _latest_state
	var metrics: Dictionary = state.get("metrics", {})
	var measurements: Dictionary = metrics.get("measurements", {})
	var gesture_states: Dictionary = state.get("gesture_states", {})
	var base := "[ProvingHarness][%s] mode=%s status=%s server=%s camera=%s source=%s poses=%d preview=%s" % [
		_mode_name(),
		_get_startup_mode_label(),
		_tracking_status_text(state),
		_server_status_text(),
		_camera_status_text("streaming", "offline"),
		_camera_source_compact_text(),
		(int(provider.get_num_poses()) if provider != null else 0),
		_preview_only_audit_text(),
	]
	if harness_mode == HarnessMode.BOXING:
		if trail_debug_logging:
			return "%s guard=%s squat=%s height=%s latest=%s | %s | %s" % [
				base,
				str(bool(gesture_states.get("guard", false))),
				str(bool(gesture_states.get("squat", false))),
				String(measurements.get("height_state", &"unknown")),
				(_latest_event_name() if _latest_event_name() != "" else "none"),
				_format_trail_debug_line(_left_trail_debug),
				_format_trail_debug_line(_right_trail_debug),
			]
		return "%s guard=%s squat=%s height=%s latest=%s" % [
			base,
			str(bool(gesture_states.get("guard", false))),
			str(bool(gesture_states.get("squat", false))),
			String(measurements.get("height_state", &"unknown")),
			(_latest_event_name() if _latest_event_name() != "" else "none"),
		]
	var flow_debug: Dictionary = (state.get("gesture_debug", {}) as Dictionary).get("flow", {})
	var left_flow: Dictionary = flow_debug.get("left", {})
	var right_flow: Dictionary = flow_debug.get("right", {})
	return "%s trail_left=%s trail_right=%s cand_left=%s/%s cand_right=%s/%s latest=%s" % [
		base,
		str(bool(gesture_states.get("trail_left", false))),
		str(bool(gesture_states.get("trail_right", false))),
		_fmt_flow_candidate(left_flow),
		_fmt_flow_direction_candidate(left_flow),
		_fmt_flow_candidate(right_flow),
		_fmt_flow_direction_candidate(right_flow),
		(_latest_event_name() if _latest_event_name() != "" else "none"),
	]

func _emit_console_snapshot_if_changed(force: bool = false) -> void:
	var snapshot := _build_console_snapshot()
	if not force and snapshot == _last_console_snapshot:
		return
	_last_console_snapshot = snapshot
	print(snapshot)

func _get_scene_camera_source_override() -> String:
	return prerecorded_video_source.strip_edges()

func _get_autostart_camera_source_override() -> String:
	var explicit_override := _get_scene_camera_source_override()
	if not explicit_override.is_empty():
		return explicit_override
	return _get_configured_live_camera_source()

func _get_configured_live_camera_source() -> String:
	if not _selected_live_camera_device_id.strip_edges().is_empty():
		return _selected_live_camera_device_id.strip_edges()
	var env_override := OS.get_environment("AEROBEAT_MEDIAPIPE_CAMERA_SOURCE").strip_edges()
	if not env_override.is_empty():
		return _normalize_live_camera_device_id(env_override)
	return "0"

func _get_effective_camera_source() -> String:
	var tracking_session := _resolve_camera_tracking_session()
	if tracking_session != null and tracking_session.has_method("get_active_config"):
		var active_config_variant: Variant = tracking_session.get_active_config()
		if active_config_variant is Dictionary:
			var source: Dictionary = (active_config_variant as Dictionary).get("source", {})
			var camera_id := String(source.get("camera_id", "")).strip_edges()
			if not camera_id.is_empty():
				return camera_id
	if auto_start_manager != null and auto_start_manager.has_method("get_active_camera_source"):
		return String(auto_start_manager.get_active_camera_source())
	var explicit_override := _get_scene_camera_source_override()
	if not explicit_override.is_empty():
		return ProjectSettings.globalize_path(explicit_override) if not explicit_override.is_valid_int() else explicit_override
	return _get_configured_live_camera_source()

func _is_live_camera_source_value(source: String) -> bool:
	var trimmed := source.strip_edges()
	return trimmed.is_empty() or trimmed == "0" or trimmed.is_valid_int() or trimmed.begins_with("/dev/video")

func _normalize_live_camera_device_id(source: String) -> String:
	var trimmed := source.strip_edges()
	if trimmed.is_empty() or trimmed == "0":
		return "/dev/video0"
	if trimmed.is_valid_int():
		return "/dev/video%s" % trimmed
	return trimmed

func _camera_label_for_device_id(device_id: String) -> String:
	var normalized := _normalize_live_camera_device_id(device_id)
	for device_variant: Variant in _camera_devices:
		if not device_variant is Dictionary:
			continue
		var device: Dictionary = device_variant
		if String(device.get("id", "")).strip_edges() == normalized:
			return _camera_device_label(device)
	return normalized.get_file() if normalized.get_file() != "" else normalized

func _camera_source_summary_text() -> String:
	var source := _get_effective_camera_source()
	if _is_live_camera_source_value(source):
		if source == "0" or source.strip_edges().is_empty():
			return "live camera (default)"
		return "live camera (%s)" % _camera_label_for_device_id(source)
	var scene_override := _get_scene_camera_source_override()
	if not scene_override.is_empty():
		return "scene override: %s" % scene_override
	return source

func _camera_source_compact_text() -> String:
	var source := _get_effective_camera_source()
	if _is_live_camera_source_value(source):
		return _normalize_live_camera_device_id(source).get_file()
	return source.get_file() if source.get_file() != "" else source

func _should_flip_horizontal_preview() -> bool:
	return _is_live_camera_source_value(_get_effective_camera_source())

func _mode_name() -> String:
	return "Boxing" if harness_mode == HarnessMode.BOXING else "Flow"

func _fmt_float(value: Variant) -> String:
	return "%.3f" % float(value if value != null else 0.0)

func _fmt_inspector_float(value: Variant) -> String:
	return "%.3f" % float(value if value != null else 0.0)

func _fmt_vec2(value: Variant) -> String:
	if value is Vector2:
		return "(%.3f, %.3f)" % [value.x, value.y]
	return "(0.000, 0.000)"

func _fmt_vec3(value: Variant) -> String:
	if value is Vector3:
		return "(%.3f, %.3f, %.3f)" % [value.x, value.y, value.z]
	return "(0.000, 0.000, 0.000)"

func _get_startup_mode_label() -> String:
	match startup_mode:
		StartupMode.PREVIEW_ONLY_DEBUG:
			return "Preview-only debug"
		StartupMode.GODOT_ONLY_DEBUG:
			return "Godot-only debug"
		_:
			return "Tracking"

func _server_status_text() -> String:
	if startup_mode == StartupMode.GODOT_ONLY_DEBUG:
		return "disabled"
	return "ready" if _server_ready else "starting"

func _camera_status_text(active_label: String, inactive_label: String) -> String:
	if startup_mode == StartupMode.GODOT_ONLY_DEBUG:
		return "disabled"
	return active_label if camera_view and camera_view.is_streaming() else inactive_label

func _tracking_status_text(state: Dictionary) -> String:
	if startup_mode == StartupMode.GODOT_ONLY_DEBUG:
		return "disabled"
	if startup_mode == StartupMode.PREVIEW_ONLY_DEBUG:
		return "invalid" if not _preview_only_invalid_reason.is_empty() else "preview_only"
	return String(state.get("tracking_state", &"lost"))

func _tracking_smoothing_style_spec() -> Dictionary:
	match tracking_smoothing_style:
		TrackingSmoothingStyle.LITE_RAW:
			return {"label": "Lite + raw", "model_complexity": 0, "no_filter": true}
		TrackingSmoothingStyle.HEAVY_RAW:
			return {"label": "Heavy + raw", "model_complexity": 2, "no_filter": true}
		TrackingSmoothingStyle.LITE_FILTERED:
			return {"label": "Lite + One-Euro", "model_complexity": 0, "no_filter": false}
		TrackingSmoothingStyle.FULL_FILTERED:
			return {"label": "Full + One-Euro", "model_complexity": 1, "no_filter": false}
		TrackingSmoothingStyle.HEAVY_FILTERED:
			return {"label": "Heavy + One-Euro", "model_complexity": 2, "no_filter": false}
		_:
			return {"label": "Full + raw", "model_complexity": 1, "no_filter": true}

func _apply_tracking_smoothing_style_to_autostart_manager() -> void:
	if auto_start_manager == null:
		return
	var spec := _tracking_smoothing_style_spec()
	auto_start_manager.model_complexity = int(spec.get("model_complexity", auto_start_manager.model_complexity))
	auto_start_manager.no_filter = bool(spec.get("no_filter", auto_start_manager.no_filter))

func _update_status(text: String, color: Color) -> void:
	var source_suffix := " | src=%s" % _camera_source_compact_text()
	if status_label:
		status_label.text = text + source_suffix
		status_label.modulate = color
	print("[ProvingHarness][%s] %s%s" % [_mode_name(), text, source_suffix])

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		_stop_everything("window_close_request")
		get_tree().quit()
	elif what == NOTIFICATION_EXIT_TREE:
		_stop_everything("exit_tree")
	elif what == NOTIFICATION_PREDELETE:
		_stop_everything("predelete")

func _is_preview_only_mode() -> bool:
	return startup_mode == StartupMode.PREVIEW_ONLY_DEBUG

func _preview_only_audit_text() -> String:
	if not _is_preview_only_mode():
		return "n/a"
	if not _preview_only_invalid_reason.is_empty():
		return "INVALID: %s" % _preview_only_invalid_reason
	return "provider=disabled (expected)"

func _audit_preview_only_surface() -> void:
	if not _is_preview_only_mode():
		return
	_clear_preview_only_overlay_state()
	if provider != null or get_node_or_null("MediaPipeProvider") != null:
		_invalidate_preview_only_surface("provider node active in preview-only rung")

func _invalidate_preview_only_surface(reason: String) -> void:
	if not _is_preview_only_mode():
		return
	var normalized_reason := reason.strip_edges()
	if normalized_reason.is_empty():
		normalized_reason = "provider activity detected"
	_preview_only_invalid_reason = normalized_reason
	_clear_preview_only_overlay_state()
	if not _preview_only_invalid_logged:
		_preview_only_invalid_logged = true
		_record_event("preview_only_invalid", {"reason": normalized_reason})
	_update_status("INVALID preview-only debug: %s" % normalized_reason, Color.RED)

func _clear_preview_only_overlay_state() -> void:
	_latest_landmarks = []
	_left_trail.clear()
	_right_trail.clear()
	if landmark_drawer:
		landmark_drawer.clear_landmarks()
	if trail_drawer:
		trail_drawer.clear_trails()

func _get_close_path_stop_mode_label() -> String:
	if skip_sidecar_stop_on_close_debug:
		return "heartbeat_only"
	var parts: PackedStringArray = ["normal_stop"]
	if skip_sidecar_terminate_sync_on_close_debug:
		parts.append("skip_terminate_sync")
	elif skip_sidecar_terminate_kill_escalation_on_close_debug:
		parts.append("skip_terminate_kill_escalation")
	if skip_linux_pkill_main_py_on_close_debug:
		parts.append("skip_linux_sidecar_identity_pkill")
	if skip_linux_video0_fuser_cleanup_on_close_debug:
		parts.append("legacy_skip_linux_video0_fuser_noop")
	return "+".join(parts)

func _log_shutdown_summary_once(reason: String) -> void:
	if _shutdown_summary_logged:
		if shutdown_console_debug:
			print("[ProvingHarness][%s] Duplicate shutdown notification ignored (%s)" % [_mode_name(), reason])
		return
	_shutdown_summary_logged = true
	var stop_mode := _get_close_path_stop_mode_label()
	print("[ProvingHarness][%s] Shutdown summary: reason=%s stop_mode=%s server=%s camera=%s preview=%s" % [
		_mode_name(),
		reason,
		stop_mode,
		_server_status_text(),
		_camera_status_text("streaming", "offline"),
		_preview_only_audit_text(),
	])

func _stop_everything(reason: String = "unknown") -> void:
	_log_shutdown_summary_once(reason)
	_playback_controller_unload()
	if camera_view and camera_view.is_streaming():
		camera_view.stop_stream()
	if camera_view and is_instance_valid(camera_view):
		camera_view.queue_free()
	camera_view = null

	if provider:
		provider.stop()
		var tracking_singleton := _resolve_camera_tracking_singleton()
		if is_instance_valid(provider) and provider != tracking_singleton:
			provider.queue_free()
		provider = null

	auto_start_manager = null
	_server_ready = false
