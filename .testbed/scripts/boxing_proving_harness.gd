extends "res://scripts/proving_harness.gd"

const BACKGROUND_TEXTURE_PATH := "res://assets/backgrounds/perfect-hue-may-08-2026-hd.png"
const HEADER_ICON_PATH := "res://assets/icons/boxing-glove-1.svg"
const TILE_PULSE_MS := 420
const MAX_BOXING_FEED_ROWS := 8
const ACTIVE_PILL_FILL := Color8(0x3d, 0xdc, 0xdc, 0xff)
const ACTIVE_PILL_TEXT := Color8(0x05, 0x22, 0x28, 0xff)
const HOVER_CARD_TITLE := "Gesture Detection"
const HOVER_CARD_MAX_WIDTH := 700.0
const HOVER_CARD_MARGIN := 14.0
const HOVER_CARD_BODY_FONT_SIZE := 14
const HOVER_CARD_TITLE_FONT_SIZE := 18
const HOVER_CARD_GESTURE_FONT_SIZE := 16
const BBOX_DRAWER_Z_INDEX := 21
const PROFILE_BOXING := "boxing"
const PROFILE_FLOW := "flow"
const BOARD_ICON_PATHS := {
	"punch": "res://assets/icons/boxing-punch-1.svg",
	"hook": "res://assets/icons/boxing-hook-1.svg",
	"uppercut": "res://assets/icons/boxing-uppercut-1.svg",
	"knee": "res://assets/icons/boxing-knee-strike-1.svg",
	"guard": "res://assets/icons/boxing-guard-1.svg",
	"leg_lift": "res://assets/icons/boxing-leg-lift-1.svg",
	"sidestep": "res://assets/icons/boxing-sidestep-1.svg",
	"squat": "res://assets/icons/boxing-squat-1.svg",
	"weave": "res://assets/icons/boxing-weave-1.svg",
}
const UI_EVENT_LABELS := {
	"punch_left": "Left Punch",
	"punch_right": "Right Punch",
	"hook_left": "Left Hook",
	"hook_right": "Right Hook",
	"uppercut_left": "Left Uppercut",
	"uppercut_right": "Right Uppercut",
	"knee_left": "Left Knee Strike",
	"knee_right": "Right Knee Strike",
	"guard_start": "Guard Activated",
	"guard_end": "Guard Deactivated",
	"squat_start": "Squat Activated",
	"squat_end": "Squat Deactivated",
	"weave_left_start": "Weave Left",
	"weave_left_end": "Weave Left Ended",
	"weave_right_start": "Weave Right",
	"weave_right_end": "Weave Right Ended",
	"sidestep_left_start": "Side Step Left",
	"sidestep_left_end": "Side Step Left Ended",
	"sidestep_right_start": "Side Step Right",
	"sidestep_right_end": "Side Step Right Ended",
	"leg_lift_left_start": "Left Leg Lift",
	"leg_lift_left_end": "Left Leg Lift Ended",
	"leg_lift_right_start": "Right Leg Lift",
	"leg_lift_right_end": "Right Leg Lift Ended",
}
const TILE_CONFIGS := [
	{
		"id": "punch",
		"label": "Punch",
		"icon": BOARD_ICON_PATHS["punch"],
		"mode": "pulse_lr",
		"left_events": ["punch_left"],
		"right_events": ["punch_right"],
	},
	{
		"id": "hook",
		"label": "Hook",
		"icon": BOARD_ICON_PATHS["hook"],
		"mode": "pulse_lr",
		"left_events": ["hook_left"],
		"right_events": ["hook_right"],
	},
	{
		"id": "uppercut",
		"label": "Uppercut",
		"icon": BOARD_ICON_PATHS["uppercut"],
		"mode": "pulse_lr",
		"left_events": ["uppercut_left"],
		"right_events": ["uppercut_right"],
	},
	{
		"id": "knee",
		"label": "Knee Strike",
		"icon": BOARD_ICON_PATHS["knee"],
		"mode": "pulse_lr",
		"left_events": ["knee_left"],
		"right_events": ["knee_right"],
	},
	{
		"id": "guard",
		"label": "Guard",
		"icon": BOARD_ICON_PATHS["guard"],
		"mode": "state_center",
		"states": ["guard"],
	},
	{
		"id": "leg_lift",
		"label": "Leg Lift",
		"icon": BOARD_ICON_PATHS["leg_lift"],
		"mode": "pulse_lr",
		"left_events": ["leg_lift_left_start"],
		"right_events": ["leg_lift_right_start"],
	},
	{
		"id": "sidestep",
		"label": "Side Step",
		"icon": BOARD_ICON_PATHS["sidestep"],
		"mode": "pulse_lr",
		"left_events": ["sidestep_left_start"],
		"right_events": ["sidestep_right_start"],
	},
	{
		"id": "squat",
		"label": "Squat",
		"icon": BOARD_ICON_PATHS["squat"],
		"mode": "state_center",
		"states": ["squat"],
	},
	{
		"id": "weave",
		"label": "Weave",
		"icon": BOARD_ICON_PATHS["weave"],
		"mode": "pulse_lr",
		"left_events": ["weave_left_start"],
		"right_events": ["weave_right_start"],
	},
]
const PUNCH_REQUIREMENT_ROWS := [
	{
		"id": "state_section",
		"label": "Live state",
		"row_kind": "section",
	},
	{
		"id": "current_state",
		"label": "Current state",
		"row_kind": "info",
	},
	{
		"id": "tracking_status",
		"label": "Hand tracking",
		"row_kind": "info",
	},
	{
		"id": "fresh_sample",
		"label": "Fresh sample valid",
		"row_kind": "info",
	},
	{
		"id": "state_change_event",
		"label": "Latest state change",
		"row_kind": "info",
	},
	{
		"id": "state_change_payload",
		"label": "Event payload snapshot",
		"row_kind": "info",
	},
	{
		"id": "trigger_section",
		"label": "Trigger inputs",
		"row_kind": "section",
	},
	{
		"id": "wrist_velocity",
		"label": "Wrist velocity >= {threshold}",
	},
	{
		"id": "bbox_area",
		"label": "BBox area",
		"row_kind": "info",
	},
	{
		"id": "bbox_area_growth",
		"label": "BBox area growth >= {threshold}",
	},
	{
		"id": "positive_growth_samples",
		"label": "Positive growth samples >= {threshold}",
	},
	{
		"id": "growth_window_areas",
		"label": "Growth window bbox areas",
		"row_kind": "info",
	},
	{
		"id": "rearm_section",
		"label": "Hold / rearm",
		"row_kind": "section",
	},
	{
		"id": "grace_timer",
		"label": "Grace timer",
		"row_kind": "info",
	},
	{
		"id": "trigger_bbox_area",
		"label": "Stored trigger bbox area",
		"row_kind": "info",
	},
	{
		"id": "rearm_status",
		"label": "BBox retracted enough to rearm",
	},
	{
		"id": "reacquire_progress",
		"label": "Reacquire progress",
		"row_kind": "info",
	},
]
const HOVER_REQUIREMENT_SPECS := {
	"punch_left": {
		"title": "Straight Punch L",
		"rows": PUNCH_REQUIREMENT_ROWS,
	},
	"punch_right": {
		"title": "Straight Punch R",
		"rows": PUNCH_REQUIREMENT_ROWS,
	},
}

@onready var profile_picker: OptionButton = find_child("ProfilePicker", true, false) as OptionButton
@onready var tracker_config_path_field: LineEdit = find_child("TrackerConfigPath", true, false) as LineEdit
@onready var gesture_config_path_field: LineEdit = find_child("GestureConfigPath", true, false) as LineEdit
@onready var hand_bbox_drawer: Control = find_child("HandBBoxDrawer", true, false) as Control

var _background_rect: TextureRect
var _header_icon: TextureRect
var _board_panel: PanelContainer
var _board_grid: GridContainer
var _boxing_event_feed: Array[String] = []
var _boxing_event_sequence := 0
var _tile_refs := {}
var _hovered_card_key := ""
var _hover_card_panel: PanelContainer
var _hover_card_gesture_label: Label
var _hover_card_rows: VBoxContainer
var _hover_card_footer_label: Label
var _hover_card_row_nodes := {}
var _hover_card_row_order: Array[String] = []
var _hover_card_signature := ""
var _selected_profile_id := PROFILE_BOXING
var _profile_switch_in_progress := false
var _straight_punch_transition_debug := {
	"left": {},
	"right": {},
}

func _ready() -> void:
	_selected_profile_id = _default_profile_id()
	_resolve_boxing_shell_nodes()
	_build_tile_grid_if_needed()
	_apply_boxing_visual_shell()
	_configure_profile_controls()
	super._ready()
	_refresh_profile_controls()
	_sync_profile_visual_config()
	_refresh_debug_panels()

func _connect_mode_signals() -> void:
	super._connect_mode_signals()
	if harness_mode != HarnessMode.BOXING:
		return
	if provider == null or not provider.has_signal("straight_punch_state_changed"):
		return
	if _provider_mode_signal_relays.has("straight_punch_state_changed"):
		return
	var relay := func(side: String, state: String, detail: Dictionary) -> void:
		_on_straight_punch_state_changed(side, state, detail)
	_remember_mode_signal_relay("straight_punch_state_changed", relay)

func _on_straight_punch_state_changed(side: String, state: String, detail: Dictionary) -> void:
	var side_key := side.to_lower()
	if not ["left", "right"].has(side_key):
		return
	var transition := detail.duplicate(true)
	transition["state"] = state
	transition["previous_state"] = String(detail.get("previous_state", ""))
	transition["timestamp_ms"] = Time.get_ticks_msec()
	_straight_punch_transition_debug[side_key] = transition
	if provider != null:
		_latest_state = provider.get_detector_state()
	var card_key := "punch_%s" % side_key
	if _hovered_card_key == card_key:
		_hover_card_signature = ""
		_refresh_hover_card()
	if _shared_inspector_target_type == "gesture" and _shared_inspector_target_key == card_key:
		_shared_inspector_live_model = {}
		_shared_inspector_live_refresh_due_ms = 0
		_refresh_shared_inspector(true)

func _refresh_debug_panels() -> void:
	if harness_mode != HarnessMode.BOXING:
		super._refresh_debug_panels()
		return
	if title_label:
		title_label.text = scene_title if not scene_title.is_empty() else "BOXING GESTURE DETECTION"
	if notes_label:
		notes_label.visible = false
	_refresh_profile_controls()
	_sync_hand_bbox_drawer()
	if live_status_label:
		live_status_label.text = _build_boxing_live_line()
	if quick_stats_label:
		quick_stats_label.text = _build_boxing_event_feed_text()
		if quick_stats_label.has_method("scroll_to_line"):
			quick_stats_label.scroll_to_line(0)
	_update_tile_states()

func _sync_hand_bbox_drawer() -> void:
	if hand_bbox_drawer == null:
		return
	_configure_overlay_drawer(hand_bbox_drawer, BBOX_DRAWER_Z_INDEX)
	if _preview_presenter != null and is_instance_valid(_preview_presenter):
		if hand_bbox_drawer.get_parent() != _preview_presenter:
			hand_bbox_drawer.reparent(_preview_presenter)
		if hand_bbox_drawer.has_method("set_preview_presenter"):
			hand_bbox_drawer.set_preview_presenter(_preview_presenter)
	if not hand_bbox_drawer.visible:
		if hand_bbox_drawer.has_method("clear_snapshot"):
			hand_bbox_drawer.clear_snapshot()
		return
	var hand_snapshot := _tracker_hand_debug_snapshot()
	var gesture_debug: Dictionary = (_latest_state.get("gesture_debug", {}) as Dictionary)
	var straight_punch_debug: Dictionary = (gesture_debug.get("straight_punch", {}) as Dictionary)
	if hand_snapshot.is_empty():
		if hand_bbox_drawer.has_method("clear_snapshot"):
			hand_bbox_drawer.clear_snapshot()
		return
	if hand_bbox_drawer.has_method("update_snapshot"):
		hand_bbox_drawer.update_snapshot(hand_snapshot, straight_punch_debug)

func _record_event(event_name: String, payload: Dictionary) -> void:
	if harness_mode == HarnessMode.BOXING:
		if UI_EVENT_LABELS.has(event_name):
			_boxing_event_sequence += 1
			_boxing_event_feed.append("%04d: %s" % [_boxing_event_sequence, String(UI_EVENT_LABELS[event_name])])
			while _boxing_event_feed.size() > MAX_BOXING_FEED_ROWS:
				_boxing_event_feed.remove_at(0)
	super._record_event(event_name, payload)

func _clear_straight_punch_transition_debug() -> void:
	_straight_punch_transition_debug = {
		"left": {},
		"right": {},
	}

func _reset_runtime_debug_state_for_seek() -> void:
	super._reset_runtime_debug_state_for_seek()
	_boxing_event_feed = []
	_boxing_event_sequence = 0
	_clear_straight_punch_transition_debug()

func _update_status(text: String, color: Color) -> void:
	if harness_mode != HarnessMode.BOXING:
		super._update_status(text, color)
		return
	if status_label:
		status_label.text = _compact_status_text(text)
		status_label.modulate = color
	print("[ProvingHarness][%s] %s%s" % [_mode_name(), text, " | src=%s" % _camera_source_compact_text()])

func _resolve_boxing_shell_nodes() -> void:
	_background_rect = get_node_or_null("Background") as TextureRect
	_header_icon = find_child("HeaderIcon", true, false) as TextureRect
	_board_panel = get_node_or_null("Margin/VSplit/Content/RightPanelScroll/RightColumn/BoardPanel") as PanelContainer
	_board_grid = get_node_or_null("Margin/VSplit/Content/RightPanelScroll/RightColumn/BoardPanel/BoardMargin/BoardGrid") as GridContainer

func _default_profile_id() -> String:
	return PROFILE_BOXING if harness_mode == HarnessMode.BOXING else PROFILE_FLOW

func _configure_profile_controls() -> void:
	if profile_picker == null:
		return
	if not profile_picker.item_selected.is_connected(_on_profile_picker_selected):
		profile_picker.item_selected.connect(_on_profile_picker_selected)
	profile_picker.clear()
	profile_picker.add_item("Boxing")
	profile_picker.set_item_metadata(profile_picker.item_count - 1, PROFILE_BOXING)
	profile_picker.add_item("Flow")
	profile_picker.set_item_metadata(profile_picker.item_count - 1, PROFILE_FLOW)
	_refresh_profile_controls()

func _refresh_profile_controls() -> void:
	if profile_picker != null:
		var selected_index := 0 if _selected_profile_id == PROFILE_BOXING else 1
		profile_picker.select(selected_index)
		profile_picker.disabled = _profile_switch_in_progress
	var bundle := _current_profile_bundle()
	if tracker_config_path_field != null:
		tracker_config_path_field.text = _pretty_resource_path(String(bundle.get("camera_tracking_path", "")))
		tracker_config_path_field.tooltip_text = String(bundle.get("camera_tracking_path", ""))
	if gesture_config_path_field != null:
		gesture_config_path_field.text = _pretty_resource_path(String(bundle.get("gesture_detection_path", "")))
		gesture_config_path_field.tooltip_text = String(bundle.get("gesture_detection_path", ""))
	_sync_profile_visual_config(bundle)

func _sync_profile_visual_config(bundle: Dictionary = {}) -> void:
	var resolved_bundle := bundle if not bundle.is_empty() else _current_profile_bundle()
	var testbed_debug: Dictionary = resolved_bundle.get("testbed_debug", {}) if resolved_bundle.get("testbed_debug", {}) is Dictionary else {}
	var visuals: Dictionary = testbed_debug.get("visuals", {}) if testbed_debug.get("visuals", {}) is Dictionary else {}
	if visuals.is_empty():
		return
	show_landmarks = bool(visuals.get("show_landmarks", show_landmarks))
	show_trails = bool(visuals.get("show_trails", show_trails))
	if landmark_drawer != null:
		landmark_drawer.set("show_debug_hit_targets", bool(visuals.get("show_landmark_hit_targets", landmark_drawer.get("show_debug_hit_targets"))))
		landmark_drawer.set("show_debug_hit_target_labels", bool(visuals.get("show_landmark_hit_target_labels", landmark_drawer.get("show_debug_hit_target_labels"))))
		landmark_drawer.visible = show_landmarks or bool(landmark_drawer.get("show_debug_hit_targets"))
		landmark_drawer.queue_redraw()
	if trail_drawer != null:
		trail_drawer.visible = show_trails
		trail_drawer.queue_redraw()
	if hand_bbox_drawer != null:
		var show_hand_bbox_overlay := bool(visuals.get("show_hand_bbox_overlay", hand_bbox_drawer.visible))
		hand_bbox_drawer.visible = show_hand_bbox_overlay
		if not show_hand_bbox_overlay and hand_bbox_drawer.has_method("clear_snapshot"):
			hand_bbox_drawer.clear_snapshot()
		else:
			hand_bbox_drawer.queue_redraw()

func _on_profile_picker_selected(index: int) -> void:
	if profile_picker == null or _profile_switch_in_progress or index < 0 or index >= profile_picker.item_count:
		return
	var next_profile := String(profile_picker.get_item_metadata(index)).strip_edges().to_lower()
	if next_profile.is_empty() or next_profile == _selected_profile_id:
		return
	_profile_switch_in_progress = true
	_selected_profile_id = next_profile
	_clear_straight_punch_transition_debug()
	_refresh_profile_controls()
	_update_status("Switching tracking profile...", Color.YELLOW)
	_apply_selected_profile.call_deferred()

func _apply_selected_profile() -> void:
	var success := await _restart_provider_with_selected_profile()
	_profile_switch_in_progress = false
	_refresh_profile_controls()
	_refresh_debug_panels()
	if success:
		_record_event("profile_switched", {"profile": _selected_profile_id})
		_update_status("Tracking profile switched", Color.GREEN)
	else:
		_update_status("Tracking profile switch failed", Color.RED)

func _restart_provider_with_selected_profile() -> bool:
	_clear_live_camera_runtime_state()
	await get_tree().process_frame
	_start_provider()
	await get_tree().process_frame
	var tracking_singleton := _resolve_camera_tracking_singleton()
	if tracking_singleton == null:
		return false
	var active_profile := String(tracking_singleton.get_selected_profile_id()).strip_edges().to_lower() if tracking_singleton.has_method("get_selected_profile_id") else ""
	if active_profile.is_empty():
		active_profile = _selected_profile_id
	return active_profile == _selected_profile_id

func _current_profile_bundle() -> Dictionary:
	var tracking_singleton := _resolve_camera_tracking_singleton()
	if tracking_singleton != null and tracking_singleton.has_method("get_selected_profile_bundle"):
		var runtime_bundle: Variant = tracking_singleton.get_selected_profile_bundle()
		if runtime_bundle is Dictionary and bool(runtime_bundle.get("ok", false)):
			var runtime_profile := String(runtime_bundle.get("profile", "")).strip_edges().to_lower()
			if runtime_profile.is_empty() or runtime_profile == _selected_profile_id:
				return runtime_bundle.duplicate(true)
	var config := CameraTrackingConfigScript.new()
	var bundle: Variant = config.load_selected_profile_bundle(_selected_profile_id)
	if bundle is Dictionary and bool(bundle.get("ok", false)):
		return bundle.duplicate(true)
	return {
		"ok": false,
		"profile": _selected_profile_id,
	}

func _pretty_resource_path(path: String) -> String:
	if path.begins_with("res://addons/aerobeat-input-camera-tracking/"):
		return path.replace("res://addons/aerobeat-input-camera-tracking/", "res://")
	return path

func _build_tile_grid_if_needed() -> void:
	if _board_grid == null or not _tile_refs.is_empty():
		return
	for config_variant: Variant in TILE_CONFIGS:
		var config: Dictionary = config_variant
		var tile := _create_tile(config)
		_board_grid.add_child(tile["panel"])
		_tile_refs[String(config["id"])] = tile

func _ensure_hover_card() -> void:
	if _hover_card_panel != null:
		return
	_hover_card_panel = PanelContainer.new()
	_hover_card_panel.name = "GestureRequirementsHoverCard"
	_hover_card_panel.visible = false
	_hover_card_panel.top_level = true
	_hover_card_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hover_card_panel.custom_minimum_size = Vector2(HOVER_CARD_MAX_WIDTH, 0.0)
	add_child(_hover_card_panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_bottom", 16)
	_hover_card_panel.add_child(margin)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 10)
	margin.add_child(column)

	var title := Label.new()
	title.text = HOVER_CARD_TITLE
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title.add_theme_font_size_override("font_size", HOVER_CARD_TITLE_FONT_SIZE)
	title.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 1.0))
	column.add_child(title)

	_hover_card_gesture_label = Label.new()
	_hover_card_gesture_label.add_theme_font_size_override("font_size", HOVER_CARD_GESTURE_FONT_SIZE)
	_hover_card_gesture_label.add_theme_color_override("font_color", Color(0.80, 0.90, 1.0, 0.96))
	column.add_child(_hover_card_gesture_label)

	_hover_card_rows = VBoxContainer.new()
	_hover_card_rows.add_theme_constant_override("separation", 8)
	column.add_child(_hover_card_rows)

	_hover_card_footer_label = Label.new()
	_hover_card_footer_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_hover_card_footer_label.add_theme_font_size_override("font_size", 11)
	_hover_card_footer_label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 0.56))
	column.add_child(_hover_card_footer_label)

func _apply_boxing_visual_shell() -> void:
	if _background_rect:
		_background_rect.texture = load(BACKGROUND_TEXTURE_PATH)
	if _header_icon:
		_header_icon.texture = load(HEADER_ICON_PATH)
		_header_icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		_header_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	if title_label:
		title_label.add_theme_font_size_override("font_size", 24)
		title_label.add_theme_color_override("font_color", Color(0.97, 0.98, 1.0, 1.0))
	if status_label:
		status_label.add_theme_font_size_override("font_size", 12)
		status_label.add_theme_color_override("font_color", Color(0.84, 0.91, 0.98, 1.0))
	if live_status_label:
		live_status_label.add_theme_font_size_override("normal_font_size", 11)
		live_status_label.add_theme_color_override("default_color", Color(0.88, 0.93, 0.98, 0.86))
		live_status_label.fit_content = true
		live_status_label.scroll_active = false
	if quick_stats_label:
		quick_stats_label.add_theme_font_size_override("normal_font_size", 15)
		quick_stats_label.add_theme_color_override("default_color", Color(0.97, 0.98, 1.0, 1.0))
		quick_stats_label.scroll_active = true
		quick_stats_label.fit_content = false
		quick_stats_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	if notes_label:
		notes_label.visible = false
	if camera_display:
		camera_display.custom_minimum_size = Vector2(520, 293)
	if camera_display and camera_display.get_parent() is PanelContainer:
		_apply_panel_style(camera_display.get_parent(), Color(1.0, 1.0, 1.0, 0.01), Color(1.0, 1.0, 1.0, 0.12), 4, 1, 0)
	if quick_stats_label and quick_stats_label.get_parent() is PanelContainer:
		quick_stats_label.get_parent().custom_minimum_size = Vector2(0, 210)
		_apply_panel_style(quick_stats_label.get_parent(), Color(0.20, 0.21, 0.24, 0.90), Color(1.0, 1.0, 1.0, 0.08), 14, 1, 12)
	if _board_panel:
		_apply_panel_style(_board_panel, Color(0.25, 0.38, 0.53, 0.56), Color(1.0, 1.0, 1.0, 0.26), 28, 1, 18)
	if _board_grid:
		_board_grid.columns = 3
		_board_grid.add_theme_constant_override("h_separation", 10)
		_board_grid.add_theme_constant_override("v_separation", 10)
	if _hover_card_panel:
		_apply_panel_style(_hover_card_panel, Color(0.0, 0.0, 0.0, 0.82), Color(1.0, 1.0, 1.0, 0.14), 16, 1, 0)
	if summary_label and summary_label.get_parent() is Control:
		summary_label.get_parent().visible = false
	if signal_status_label and signal_status_label.get_parent() is Control:
		signal_status_label.get_parent().visible = false
	if metrics_label and metrics_label.get_parent() is Control:
		metrics_label.get_parent().visible = false
	if events_label and events_label.get_parent() is Control:
		events_label.get_parent().visible = false

func _create_tile(config: Dictionary) -> Dictionary:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(132, 158)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.size_flags_vertical = 0
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_apply_panel_style(panel, Color(1.0, 1.0, 1.0, 0.0), Color(1.0, 1.0, 1.0, 0.0), 0, 0, 0)

	var tile_id := String(config.get("id", ""))
	var mode := String(config.get("mode", "pulse_lr"))

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 6)
	margin.add_theme_constant_override("margin_top", 4)
	margin.add_theme_constant_override("margin_right", 6)
	margin.add_theme_constant_override("margin_bottom", 4)
	panel.add_child(margin)

	var column := VBoxContainer.new()
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_theme_constant_override("separation", 4)
	margin.add_child(column)

	var title := Label.new()
	title.text = String(config["label"])
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 14)
	title.add_theme_color_override("font_color", Color(0.97, 0.98, 1.0, 1.0))
	column.add_child(title)

	var icon := TextureRect.new()
	icon.texture = load(String(config["icon"]))
	icon.custom_minimum_size = Vector2(88, 54)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.modulate = Color(1.0, 1.0, 1.0, 1.0)
	column.add_child(icon)

	var badges := HBoxContainer.new()
	badges.alignment = BoxContainer.ALIGNMENT_CENTER
	badges.add_theme_constant_override("separation", 6)
	column.add_child(badges)

	var left_badge := _create_badge("L")
	var center_badge := _create_badge("Active", true)
	var right_badge := _create_badge("R")
	badges.add_child(left_badge["panel"])
	badges.add_child(center_badge["panel"])
	badges.add_child(right_badge["panel"])

	center_badge["panel"].visible = mode == "state_center"
	left_badge["panel"].visible = mode != "state_center"
	right_badge["panel"].visible = mode != "state_center"

	if tile_id != "":
		_connect_hover_target(left_badge, _card_key_for_target(tile_id, "left"))
		_connect_hover_target(right_badge, _card_key_for_target(tile_id, "right"))
		_connect_hover_target(center_badge, _card_key_for_target(tile_id, "center"))

	return {
		"panel": panel,
		"mode": mode,
		"left_events": config.get("left_events", []),
		"right_events": config.get("right_events", []),
		"left_states": config.get("left_states", []),
		"right_states": config.get("right_states", []),
		"states": config.get("states", []),
		"left": left_badge,
		"center": center_badge,
		"right": right_badge,
		"shell_active": false,
	}

func _create_badge(text: String, wide: bool = false) -> Dictionary:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(68 if wide else 34, 34)
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	_apply_panel_style(panel, Color(0.16, 0.20, 0.28, 0.20), Color(1.0, 1.0, 1.0, 0.70), 18, 1, 0)
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size", 13 if wide else 14)
	label.add_theme_color_override("font_color", Color(0.96, 0.97, 1.0, 1.0))
	panel.add_child(label)
	return {"panel": panel, "label": label, "active": false, "style_key": "idle"}

func _connect_hover_target(badge: Dictionary, card_key: String) -> void:
	var panel := badge.get("panel") as PanelContainer
	if panel == null or card_key.is_empty():
		if panel != null:
			panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
		return
	panel.gui_input.connect(_on_inspector_target_gui_input.bind(card_key))

func _card_key_for_target(tile_id: String, target: String) -> String:
	var tile: Dictionary = _find_tile_config(tile_id)
	if tile.is_empty():
		return ""
	var mode := String(tile.get("mode", "pulse_lr"))
	match mode:
		"state_center":
			return tile_id if target == "center" else ""
		"state_lr", "pulse_lr":
			if target == "left":
				return "%s_left" % tile_id
			if target == "right":
				return "%s_right" % tile_id
	return ""

func _find_tile_config(tile_id: String) -> Dictionary:
	for config_variant: Variant in TILE_CONFIGS:
		var config: Dictionary = config_variant
		if String(config.get("id", "")) == tile_id:
			return config
	return {}

func _refresh_hover_card() -> void:
	if _hovered_card_key.is_empty():
		if _hover_card_panel:
			_hover_card_panel.visible = false
			_hover_card_signature = ""
		return
	if _hover_card_panel == null:
		return
	var model := _build_hover_card_model(_hovered_card_key)
	_hover_card_panel.visible = not model.is_empty()
	if model.is_empty():
		_hover_card_signature = ""
		return
	var signature := JSON.stringify(model)
	if signature == _hover_card_signature:
		return
	_hover_card_signature = signature
	_hover_card_gesture_label.text = String(model.get("title", _display_name_for_card_key(_hovered_card_key)))
	_hover_card_footer_label.text = String(model.get("footer", ""))
	_hover_card_footer_label.visible = not _hover_card_footer_label.text.is_empty()
	_sync_hover_card_rows(model.get("rows", []))
	_resize_and_reposition_hover_card(_hovered_card_key)

func _on_inspector_target_gui_input(event: InputEvent, card_key: String) -> void:
	if not (event is InputEventMouseButton):
		return
	var mouse_event := event as InputEventMouseButton
	if not mouse_event.pressed or mouse_event.button_index != MOUSE_BUTTON_LEFT:
		return
	accept_event()
	_open_shared_inspector("gesture", card_key)

func _build_custom_inspector_model(target_type: String, target_key: String) -> Dictionary:
	if target_type != "gesture":
		return {}
	var hover_model := _build_hover_card_model(target_key)
	return {
		"title": HOVER_CARD_TITLE,
		"subtitle": String(hover_model.get("title", _display_name_for_card_key(target_key))),
		"body": _build_gesture_inspector_body(hover_model),
		"footer": INSPECTOR_FOOTER_TEXT,
	}

func _build_gesture_inspector_body(model: Dictionary) -> String:
	var body_lines: Array[String] = []
	for row_variant: Variant in model.get("rows", []):
		if not row_variant is Dictionary:
			continue
		var row: Dictionary = row_variant
		var row_kind := String(row.get("row_kind", "requirement"))
		match row_kind:
			"section":
				if not body_lines.is_empty():
					body_lines.append("")
				body_lines.append(String(row.get("label", "")))
			"info":
				body_lines.append("• %s" % _build_requirement_row_text(row))
			_:
				body_lines.append("[%s] %s" % ["x" if bool(row.get("passed", false)) else " ", _build_requirement_row_text(row)])
				var suspect_text := String(row.get("suspect_text", ""))
				if not suspect_text.is_empty():
					body_lines.append("    %s" % suspect_text)
	var footer := String(model.get("footer", ""))
	if not footer.is_empty():
		body_lines.append("")
		body_lines.append(footer)
	return "\n".join(body_lines)

func _build_hover_card_model(card_key: String) -> Dictionary:
	var spec: Dictionary = HOVER_REQUIREMENT_SPECS.get(card_key, {})
	if spec.is_empty():
		return {
			"title": _display_name_for_card_key(card_key),
			"rows": [
				{
					"id": "%s_pending" % card_key,
					"label": "Requirement list pending",
					"passed": false,
					"current_text": "Live hookup still needed",
				},
			],
		}
	match card_key:
		"punch_left":
			return _build_punch_hover_card_model(spec, "left")
		"punch_right":
			return _build_punch_hover_card_model(spec, "right")
		_:
			return spec.duplicate(true)

func _merged_punch_debug_state(side: String) -> Dictionary:
	var gesture_debug: Dictionary = (_latest_state.get("gesture_debug", {}) as Dictionary)
	var straight_punch_debug: Dictionary = (gesture_debug.get("straight_punch", {}) as Dictionary)
	var straight_side: Dictionary = ((straight_punch_debug.get(side, {}) as Dictionary)).duplicate(true)
	var transition_debug: Dictionary = (_straight_punch_transition_debug.get(side, {}) as Dictionary)
	if straight_side.is_empty():
		return transition_debug.duplicate(true)
	for key_variant: Variant in transition_debug.keys():
		if straight_side.has(key_variant):
			continue
		straight_side[key_variant] = transition_debug[key_variant]
	return straight_side

func _build_punch_hover_card_model(spec: Dictionary, side: String) -> Dictionary:
	var straight_side := _merged_punch_debug_state(side)
	var rows: Array[Dictionary] = []
	for row_spec_variant: Variant in spec.get("rows", []):
		var row_spec: Dictionary = row_spec_variant
		rows.append(_build_punch_requirement_row(row_spec, straight_side, side))
	return {
		"title": spec.get("title", _display_name_for_card_key("punch_%s" % side)),
		"rows": rows,
		"footer": spec.get("footer", "Live values come from the straight-punch state machine."),
	}

func _build_punch_requirement_row(row_spec: Dictionary, straight_side: Dictionary, _side: String) -> Dictionary:
	var row := row_spec.duplicate(true)
	var row_id := String(row_spec.get("id", ""))
	var label := String(row_spec.get("label", ""))
	var passed := false
	var current_text := ""
	var threshold_text := ""
	var state_name := String(straight_side.get("state", straight_side.get("phase", "tracking_lost")))
	var wrist_velocity := float(straight_side.get("wrist_velocity", 0.0))
	var min_wrist_velocity := float(straight_side.get("min_wrist_velocity", 0.0))
	var bbox_area := float(straight_side.get("bbox_area", 0.0))
	var bbox_area_growth := float(straight_side.get("bbox_area_growth", 0.0))
	var min_bbox_area_growth := float(straight_side.get("min_bbox_area_growth", 0.0))
	var positive_growth_samples := int(straight_side.get("positive_growth_samples", 0))
	var min_positive_growth_samples := int(straight_side.get("min_positive_growth_samples", 0))
	var sample_window_size := int(straight_side.get("sample_window_size", 0))
	var growth_window_areas: Array = straight_side.get("growth_window_areas", []) as Array
	var fresh_sample := bool(straight_side.get("fresh_sample", false))
	var tracking_valid := bool(straight_side.get("tracking_valid", false))
	var tracking_state := String(straight_side.get("tracking_state", "idle"))
	var stale_frames := int(straight_side.get("stale_frames", 0))
	var transition_timestamp_ms := int(straight_side.get("timestamp_ms", 0))
	var previous_state := String(straight_side.get("previous_state", ""))
	var grace_frames_remaining := int(straight_side.get("grace_frames_remaining", 0))
	var triggered_grace_frames := int(straight_side.get("triggered_grace_frames", 0))
	var trigger_bbox_area := float(straight_side.get("trigger_bbox_area", 0.0))
	var bbox_area_retract_epsilon := float(straight_side.get("bbox_area_retract_epsilon", 0.0))
	var rearm_threshold := maxf(trigger_bbox_area - bbox_area_retract_epsilon, 0.0)
	var rearm_ready := trigger_bbox_area > 0.0 and bbox_area <= rearm_threshold
	var reacquire_valid_samples := int(straight_side.get("reacquire_valid_samples", 0))
	var reacquire_stable_frames_required := int(straight_side.get("reacquire_stable_frames_required", 0))
	match row_id:
		"state_section", "trigger_section", "rearm_section":
			current_text = ""
			passed = false
		"current_state":
			current_text = state_name
			passed = state_name != "tracking_lost"
		"tracking_status":
			current_text = "%s, valid=%s, stale_frames=%d" % [tracking_state, _fmt_bool(tracking_valid), stale_frames]
			passed = tracking_valid
		"fresh_sample":
			current_text = _fmt_bool(fresh_sample)
			passed = fresh_sample
		"state_change_event":
			if previous_state.is_empty() and transition_timestamp_ms <= 0:
				current_text = "waiting for first straight-punch state change"
				passed = false
			else:
				var transition_summary := state_name
				if not previous_state.is_empty():
					transition_summary = "%s -> %s" % [previous_state, state_name]
				current_text = transition_summary
				if transition_timestamp_ms > 0:
					current_text += " (%s ago)" % _fmt_age_ms(Time.get_ticks_msec() - transition_timestamp_ms)
				passed = true
		"state_change_payload":
			current_text = "state=%s wrist=%s bbox=%s growth=%s fresh=%s grace=%d valid=%s" % [
				state_name,
				_fmt_float(wrist_velocity),
				_fmt_float(bbox_area),
				_fmt_float(bbox_area_growth),
				_fmt_bool(fresh_sample),
				grace_frames_remaining,
				_fmt_bool(tracking_valid),
			]
			passed = transition_timestamp_ms > 0 or not straight_side.is_empty()
		"wrist_velocity":
			threshold_text = _fmt_float(min_wrist_velocity)
			current_text = _fmt_float(wrist_velocity)
			passed = wrist_velocity >= min_wrist_velocity
		"bbox_area":
			current_text = _fmt_float(bbox_area)
			passed = bbox_area > 0.0
		"bbox_area_growth":
			threshold_text = _fmt_float(min_bbox_area_growth)
			current_text = _fmt_float(bbox_area_growth)
			passed = bbox_area_growth >= min_bbox_area_growth
		"positive_growth_samples":
			threshold_text = "%d/%d" % [min_positive_growth_samples, sample_window_size]
			current_text = "%d/%d" % [positive_growth_samples, sample_window_size]
			passed = positive_growth_samples >= min_positive_growth_samples
		"growth_window_areas":
			var area_values: Array[String] = []
			for area_variant: Variant in growth_window_areas:
				area_values.append(_fmt_float(area_variant))
			current_text = "[" + ", ".join(area_values) + "]" if not area_values.is_empty() else "[]"
			passed = not area_values.is_empty()
		"grace_timer":
			current_text = "%d/%d remaining" % [grace_frames_remaining, triggered_grace_frames]
			if state_name == "triggered":
				current_text += " (active)"
			elif grace_frames_remaining > 0:
				current_text += " (counting down)"
			else:
				current_text += " (idle)"
			passed = state_name != "triggered" or grace_frames_remaining > 0
		"trigger_bbox_area":
			current_text = _fmt_float(trigger_bbox_area)
			if trigger_bbox_area <= 0.0:
				current_text += " (no stored trigger)"
			passed = trigger_bbox_area > 0.0
		"rearm_status":
			if trigger_bbox_area <= 0.0:
				current_text = "waiting for a trigger bbox snapshot"
				passed = state_name == "ready"
			else:
				current_text = "%s <= %s (trigger %s - eps %s)" % [
					_fmt_float(bbox_area),
					_fmt_float(rearm_threshold),
					_fmt_float(trigger_bbox_area),
					_fmt_float(bbox_area_retract_epsilon),
				]
				passed = rearm_ready
		"reacquire_progress":
			current_text = "%d/%d valid samples" % [reacquire_valid_samples, reacquire_stable_frames_required]
			passed = reacquire_valid_samples >= reacquire_stable_frames_required
		_:
			current_text = "pending"
			passed = false
	row["label"] = label
	row["passed"] = passed
	row["threshold_text"] = threshold_text
	row["current_text"] = current_text
	return row

func _sync_hover_card_rows(rows_variant: Variant) -> void:
	if _hover_card_rows == null:
		return
	var rows: Array = rows_variant if rows_variant is Array else []
	var next_order: Array[String] = []
	var row_dicts := {}
	for row_variant: Variant in rows:
		var row: Dictionary = row_variant
		var row_id := String(row.get("id", ""))
		if row_id.is_empty():
			row_id = "row_%d" % next_order.size()
			row["id"] = row_id
		next_order.append(row_id)
		row_dicts[row_id] = row
	var next_lookup := {}
	for row_id: String in next_order:
		next_lookup[row_id] = true
	for existing_id_variant: Variant in _hover_card_row_nodes.keys():
		var existing_id := String(existing_id_variant)
		if next_lookup.has(existing_id):
			continue
		var stale_row: Dictionary = _hover_card_row_nodes.get(existing_id, {})
		var stale_container := stale_row.get("container") as Control
		if stale_container != null and stale_container.get_parent() == _hover_card_rows:
			_hover_card_rows.remove_child(stale_container)
			stale_container.free()
		_hover_card_row_nodes.erase(existing_id)
	for row_id: String in next_order:
		if not _hover_card_row_nodes.has(row_id):
			var row_node := _create_requirement_row(row_dicts[row_id])
			_hover_card_row_nodes[row_id] = row_node
			_hover_card_rows.add_child(row_node["container"])
	for idx in range(next_order.size()):
		var ordered_row: Dictionary = _hover_card_row_nodes.get(next_order[idx], {})
		var ordered_container := ordered_row.get("container") as Control
		if ordered_container != null and ordered_container.get_parent() == _hover_card_rows:
			_hover_card_rows.move_child(ordered_container, idx)
			_update_requirement_row(ordered_row, row_dicts[next_order[idx]])
	_hover_card_row_order = next_order.duplicate()

func _create_requirement_row(row: Dictionary) -> Dictionary:
	var container := VBoxContainer.new()
	container.add_theme_constant_override("separation", 3)

	var separator := HSeparator.new()
	separator.visible = false
	separator.modulate = Color(1.0, 1.0, 1.0, 0.18)
	container.add_child(separator)

	var line := HBoxContainer.new()
	line.add_theme_constant_override("separation", 8)
	container.add_child(line)

	var checkbox := Label.new()
	checkbox.text = "[ ]"
	checkbox.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	checkbox.add_theme_font_size_override("font_size", HOVER_CARD_BODY_FONT_SIZE)
	checkbox.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 0.92))
	line.add_child(checkbox)

	var text_label := Label.new()
	text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_label.add_theme_font_size_override("font_size", HOVER_CARD_BODY_FONT_SIZE)
	text_label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 1.0))
	line.add_child(text_label)

	var footer := Label.new()
	footer.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	footer.visible = false
	footer.add_theme_font_size_override("font_size", 11)
	footer.add_theme_color_override("font_color", Color(1.0, 0.82, 0.46, 0.96))
	container.add_child(footer)

	var row_node := {
		"container": container,
		"separator": separator,
		"checkbox": checkbox,
		"text_label": text_label,
		"footer": footer,
	}
	_update_requirement_row(row_node, row)
	return row_node

func _update_requirement_row(row_node: Dictionary, row: Dictionary) -> void:
	var row_kind := String(row.get("row_kind", "requirement"))
	var passed := bool(row.get("passed", false))
	var separator := row_node.get("separator") as HSeparator
	var checkbox := row_node.get("checkbox") as Label
	var text_label := row_node.get("text_label") as Label
	var footer := row_node.get("footer") as Label
	if separator != null:
		separator.visible = row_kind == "section"
	if checkbox != null:
		checkbox.visible = row_kind == "requirement"
		checkbox.text = "[x]" if passed else "[ ]"
		checkbox.add_theme_color_override("font_color", Color(0.70, 1.0, 0.82, 0.96) if passed else Color(1.0, 1.0, 1.0, 0.88))
	if text_label != null:
		text_label.text = _build_requirement_row_text(row)
		if row_kind == "section":
			text_label.add_theme_font_size_override("font_size", 12)
			text_label.add_theme_color_override("font_color", Color(0.82, 0.90, 1.0, 0.88))
		elif row_kind == "info":
			text_label.add_theme_font_size_override("font_size", 12)
			text_label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 0.78))
		else:
			text_label.add_theme_font_size_override("font_size", HOVER_CARD_BODY_FONT_SIZE)
			text_label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 1.0))
	if footer != null:
		var suspect_text := String(row.get("suspect_text", ""))
		footer.text = suspect_text
		footer.visible = row_kind == "requirement" and not suspect_text.is_empty()

func _build_requirement_row_text(row: Dictionary) -> String:
	var label := String(row.get("label", ""))
	var threshold_text := String(row.get("threshold_text", ""))
	if not threshold_text.is_empty():
		label = label.replace("{threshold}", threshold_text)
	var current_text := String(row.get("current_text", ""))
	if current_text.is_empty():
		return label
	return "%s - %s" % [label, current_text]

func _display_name_for_card_key(card_key: String) -> String:
	return card_key.replace("_", " ").capitalize()

func _split_card_key(card_key: String) -> Dictionary:
	var parts := card_key.split("_")
	if parts.size() >= 2:
		var target := String(parts[parts.size() - 1])
		if target == "left" or target == "right" or target == "center":
			parts.remove_at(parts.size() - 1)
			return {
				"tile_id": "_".join(parts),
				"target": target,
			}
	return {
		"tile_id": card_key,
		"target": "center",
	}

func _position_hover_card(card_key: String) -> void:
	if _hover_card_panel == null:
		return
	var card_parts := _split_card_key(card_key)
	var tile_id := String(card_parts.get("tile_id", card_key))
	var target := String(card_parts.get("target", "center"))
	var tile: Dictionary = _tile_refs.get(tile_id, {})
	var badge: Dictionary = tile.get(target, {})
	var anchor := badge.get("panel") as Control
	if anchor == null:
		anchor = tile.get("panel") as Control
	if anchor == null:
		return
	var anchor_rect := anchor.get_global_rect()
	var popup_size := _hover_card_panel.size
	var viewport_size := get_viewport_rect().size
	var x := anchor_rect.end.x + HOVER_CARD_MARGIN
	var y := anchor_rect.position.y - 8.0
	if x + popup_size.x > viewport_size.x - HOVER_CARD_MARGIN:
		x = anchor_rect.position.x - popup_size.x - HOVER_CARD_MARGIN
	if x < HOVER_CARD_MARGIN:
		x = HOVER_CARD_MARGIN
	if y + popup_size.y > viewport_size.y - HOVER_CARD_MARGIN:
		y = maxf(HOVER_CARD_MARGIN, viewport_size.y - popup_size.y - HOVER_CARD_MARGIN)
	_hover_card_panel.position = Vector2(x, maxf(HOVER_CARD_MARGIN, y))

func _resize_and_reposition_hover_card(card_key: String) -> void:
	if _hover_card_panel == null:
		return
	_apply_hover_card_rect(card_key)
	call_deferred("_apply_hover_card_rect", card_key)

func _apply_hover_card_rect(card_key: String) -> void:
	if _hover_card_panel == null:
		return
	_hover_card_panel.custom_minimum_size = Vector2(HOVER_CARD_MAX_WIDTH, 0.0)
	if _hover_card_rows != null:
		_hover_card_rows.queue_sort()
		_hover_card_rows.update_minimum_size()
	_hover_card_panel.update_minimum_size()
	_hover_card_panel.reset_size()
	var popup_size := _hover_card_panel.get_combined_minimum_size()
	_hover_card_panel.size = popup_size
	_position_hover_card(card_key)

func _on_hover_target_entered(card_key: String) -> void:
	_hovered_card_key = card_key
	_hover_card_signature = ""
	_refresh_hover_card()

func _on_hover_target_exited(card_key: String) -> void:
	if _hovered_card_key != card_key:
		return
	_hovered_card_key = ""
	_hover_card_signature = ""
	if _hover_card_panel:
		_hover_card_panel.visible = false

func _update_tile_states() -> void:
	for tile_id_variant: Variant in _tile_refs.keys():
		var tile: Dictionary = _tile_refs[tile_id_variant]
		var mode := String(tile.get("mode", "pulse_lr"))
		match mode:
			"state_center":
				var center_active := _any_state_active(tile.get("states", []))
				_update_center_badge(tile, center_active)
				_update_tile_shell(tile, center_active)
			"state_lr":
				var left_active := _any_state_active(tile.get("left_states", []))
				var right_active := _any_state_active(tile.get("right_states", []))
				_update_lr_badges(tile, left_active, right_active)
				_update_tile_shell(tile, left_active or right_active)
			_:
				var left_pulse := _any_recent_event(tile.get("left_events", []))
				var right_pulse := _any_recent_event(tile.get("right_events", []))
				_update_lr_badges(tile, left_pulse, right_pulse)
				_update_tile_shell(tile, left_pulse or right_pulse)

func _update_lr_badges(tile: Dictionary, left_active: bool, right_active: bool) -> void:
	_update_badge(tile.get("left", {}), "L", left_active)
	_update_badge(tile.get("right", {}), "R", right_active)

func _update_center_badge(tile: Dictionary, active: bool) -> void:
	var badge: Dictionary = tile.get("center", {})
	var panel := badge.get("panel") as PanelContainer
	if panel != null:
		panel.visible = true
	_update_badge(badge, "active" if active else "inactive", active)

func _update_badge(badge: Dictionary, text: String, active: bool) -> void:
	var panel := badge.get("panel") as PanelContainer
	var label := badge.get("label") as Label
	if panel == null or label == null:
		return
	label.text = text
	var style_key := "active" if active else "idle"
	if String(badge.get("style_key", "")) == style_key:
		return
	badge["style_key"] = style_key
	if active:
		_apply_panel_style(panel, ACTIVE_PILL_FILL, ACTIVE_PILL_FILL, 18, 1, 0)
		label.add_theme_color_override("font_color", ACTIVE_PILL_TEXT)
	else:
		_apply_panel_style(panel, Color(0.16, 0.20, 0.28, 0.14), Color(1.0, 1.0, 1.0, 0.66), 18, 1, 0)
		label.add_theme_color_override("font_color", Color(0.96, 0.97, 1.0, 1.0))

func _update_tile_shell(tile: Dictionary, active: bool) -> void:
	var panel := tile.get("panel") as PanelContainer
	if panel == null:
		return
	if bool(tile.get("shell_active", false)) == active:
		return
	tile["shell_active"] = active
	if active:
		_apply_panel_style(panel, Color(0.22, 0.78, 0.88, 0.14), Color(0.60, 1.0, 1.0, 0.38), 12, 1, 0)
	else:
		_apply_panel_style(panel, Color(1.0, 1.0, 1.0, 0.0), Color(1.0, 1.0, 1.0, 0.0), 0, 0, 0)

func _build_boxing_event_feed_text() -> String:
	var lines := ["Detected events"]
	if _boxing_event_feed.is_empty():
		lines.append("")
		lines.append("Waiting for boxing gestures...")
	else:
		lines.append("")
		lines.append_array(_boxing_event_feed)

	var bundle := _current_profile_bundle()
	var hand_snapshot := _tracker_hand_debug_snapshot()
	var playback: Dictionary = hand_snapshot.get("playback", {}) if hand_snapshot.get("playback", {}) is Dictionary else {}
	var tracker_document: Dictionary = bundle.get("camera_tracking", {}) if bundle.get("camera_tracking", {}) is Dictionary else {}
	var gesture_document: Dictionary = bundle.get("gesture_detection", {}) if bundle.get("gesture_detection", {}) is Dictionary else {}
	var tracking: Dictionary = tracker_document.get("tracking", {}) if tracker_document.get("tracking", {}) is Dictionary else {}
	var pose_config: Dictionary = tracking.get("pose", {}) if tracking.get("pose", {}) is Dictionary else {}
	var hands_config: Dictionary = tracking.get("hands", {}) if tracking.get("hands", {}) is Dictionary else {}
	var hand_validity: Dictionary = hands_config.get("validity", {}) if hands_config.get("validity", {}) is Dictionary else {}
	var straight_config: Dictionary = gesture_document.get("straight_punch", {}) if gesture_document.get("straight_punch", {}) is Dictionary else {}
	var straight_eval: Dictionary = straight_config.get("evaluation", {}) if straight_config.get("evaluation", {}) is Dictionary else {}
	var straight_thresholds: Dictionary = straight_config.get("thresholds", {}) if straight_config.get("thresholds", {}) is Dictionary else {}
	var straight_timing: Dictionary = straight_config.get("timing", {}) if straight_config.get("timing", {}) is Dictionary else {}
	var straight_rearm: Dictionary = straight_config.get("rearm", {}) if straight_config.get("rearm", {}) is Dictionary else {}
	var straight_state_machine: Dictionary = straight_config.get("state_machine", {}) if straight_config.get("state_machine", {}) is Dictionary else {}

	lines.append("")
	lines.append("Profile bundle")
	lines.append("--------------")
	lines.append("Profile: %s" % String(bundle.get("profile", _selected_profile_id)))
	lines.append("Tracker YAML: %s" % _pretty_resource_path(String(bundle.get("camera_tracking_path", ""))))
	lines.append("Gesture YAML: %s" % _pretty_resource_path(String(bundle.get("gesture_detection_path", ""))))

	lines.append("")
	lines.append("Tracker tuning")
	lines.append("--------------")
	lines.append("Pose smoothing: %s" % String(pose_config.get("smoothing_style", _tracking_smoothing_style_spec().get("label", "unknown"))))
	lines.append("Pose cadence: every %s frame(s)" % str(int(pose_config.get("inference_interval_frames", 1))))
	lines.append("Hand cadence: every %s frame(s)" % str(int(hands_config.get("inference_interval_frames", 1))))
	lines.append("BBox recompute cadence: every %s frame(s)" % str(int(hands_config.get("bbox_recompute_interval_frames", 1))))
	lines.append("Hand tracking enabled: %s" % _fmt_bool(bool(hands_config.get("enabled", false))))
	lines.append("Hand reacquire stable frames: %d" % int(hand_validity.get("reacquire_stable_frames", 0)))
	lines.append("Hand max stale frames: %d" % int(hand_validity.get("max_stale_frames", 0)))

	lines.append("")
	lines.append("Straight-punch tuning")
	lines.append("---------------------")
	lines.append("Enabled: %s" % _fmt_bool(bool(straight_config.get("enabled", false))))
	lines.append("Fresh samples only: %s" % _fmt_bool(bool(straight_eval.get("fresh_samples_only", true))))
	lines.append("Sample window size: %d" % int(straight_eval.get("sample_window_size", 0)))
	lines.append("Positive growth samples: %d" % int(straight_eval.get("min_positive_growth_samples", 0)))
	lines.append("Min wrist velocity: %s" % _fmt_float(straight_thresholds.get("min_wrist_velocity", 0.0)))
	lines.append("Min bbox area growth: %s" % _fmt_float(straight_thresholds.get("min_bbox_area_growth", 0.0)))
	lines.append("Triggered grace frames: %d" % int(straight_timing.get("triggered_grace_frames", 0)))
	lines.append("BBox retract epsilon: %s" % _fmt_float(straight_rearm.get("bbox_area_retract_epsilon", 0.0)))
	lines.append("Lost reacquire stable frames: %d" % int(straight_state_machine.get("lost_tracking_reacquire_stable_frames", 0)))

	lines.append("")
	lines.append("Tracker hand truth")
	lines.append("------------------")
	lines.append("Frame: %d  source=%s  playback=%s" % [
		int(hand_snapshot.get("frame_index", 0)),
		String(hand_snapshot.get("source_kind", _camera_source_compact_text())),
		_fmt_playback_status(playback),
	])
	lines.append(_build_hand_debug_line("left", hand_snapshot))
	lines.append(_build_hand_debug_line("right", hand_snapshot))
	return "\n".join(lines)

func _build_boxing_live_line() -> String:
	var state: Dictionary = _latest_state
	var pose_count := int(provider.get_num_poses()) if provider != null else 0
	var last_event_name := _latest_event_name()
	var bundle := _current_profile_bundle()
	return "%s • profile %s • %s • poses %d • last %s" % [
		_camera_source_summary_text(),
		String(bundle.get("profile", _selected_profile_id)),
		_tracking_status_text(state),
		pose_count,
		String(UI_EVENT_LABELS.get(last_event_name, last_event_name if last_event_name != "" else "none")),
	]

func _build_runtime_config() -> Variant:
	var config: Variant = super._build_runtime_config()
	if config == null:
		return null
	if config.has_method("set_profile_id"):
		var result: Variant = config.set_profile_id(_selected_profile_id)
		if result is Dictionary and not bool(result.get("ok", false)):
			push_warning("[BoxingProvingHarness] Failed to load selected profile bundle for %s" % _selected_profile_id)
	return config

func _tracker_hand_debug_snapshot() -> Dictionary:
	if _preview_presenter != null and is_instance_valid(_preview_presenter) and _preview_presenter.has_method("get_hand_debug_snapshot"):
		var snapshot: Variant = _preview_presenter.get_hand_debug_snapshot()
		return snapshot.duplicate(true) if snapshot is Dictionary else {}
	var tracking_singleton := _resolve_camera_tracking_singleton()
	if tracking_singleton != null and tracking_singleton.has_method("get_tracking_frame"):
		var frame: Dictionary = tracking_singleton.get_tracking_frame()
		var playback: Variant = tracking_singleton.get_playback_status() if tracking_singleton.has_method("get_playback_status") else {}
		return {
			"frame_index": int(frame.get("frame_index", 0)),
			"source_kind": String(frame.get("source_kind", "")),
			"tracking_state": String(frame.get("tracking_state", "idle")),
			"hand_tracking": frame.get("hand_tracking", {}).duplicate(true) if frame.get("hand_tracking", {}) is Dictionary else {},
			"hands": frame.get("hands", {}).duplicate(true) if frame.get("hands", {}) is Dictionary else {},
			"playback": playback.duplicate(true) if playback is Dictionary else {},
		}
	return {}

func _build_hand_debug_line(side: String, hand_snapshot: Dictionary) -> String:
	var hands: Dictionary = hand_snapshot.get("hands", {}) if hand_snapshot.get("hands", {}) is Dictionary else {}
	var hand: Dictionary = hands.get(side, {}) if hands.get(side, {}) is Dictionary else {}
	var gesture_debug: Dictionary = (_latest_state.get("gesture_debug", {}) as Dictionary)
	var straight_punch_debug: Dictionary = (gesture_debug.get("straight_punch", {}) as Dictionary)
	var side_debug: Dictionary = (straight_punch_debug.get(side, {}) as Dictionary)
	var state_name := String(side_debug.get("state", side_debug.get("phase", hand.get("tracking_state", "tracking_lost"))))
	var bbox: Dictionary = hand.get("bbox", {}) if hand.get("bbox", {}) is Dictionary else {}
	return "%s: state=%s tracking=%s valid=%s wrist_vel=%s bbox_area=%s bbox_growth=%s grace=%d reacquire=%d stale=%d" % [
		"L" if side == "left" else "R",
		state_name,
		String(hand.get("tracking_state", "idle")),
		_fmt_bool(bool(hand.get("tracking_valid", false))),
		_fmt_float(side_debug.get("wrist_velocity", 0.0)),
		_fmt_float(bbox.get("area", side_debug.get("bbox_area", 0.0))),
		_fmt_float(side_debug.get("bbox_area_growth", 0.0)),
		int(side_debug.get("grace_frames_remaining", 0)),
		int(side_debug.get("reacquire_valid_samples", 0)),
		int(hand.get("stale_frames", 0)),
	]

func _fmt_playback_status(playback: Dictionary) -> String:
	if playback.is_empty():
		return "live"
	var playing := bool(playback.get("playing", false))
	var position := float(playback.get("position_seconds", playback.get("position_sec", 0.0)))
	var duration := float(playback.get("duration_seconds", playback.get("duration_sec", 0.0)))
	return "%s %s/%s" % [
		"playing" if playing else "paused",
		_fmt_duration(position),
		_fmt_duration(duration),
	]

func _compact_status_text(text: String) -> String:
	var compact := text.strip_edges()
	compact = compact.replace("Preview-only debug mode active (provider disabled)", "Preview only")
	compact = compact.replace("Python server started", "Server started")
	compact = compact.replace("Tracking runtime missing - installing", "Installing runtime")
	compact = compact.replace("Auto-start failed:", "Auto-start failed")
	return compact

func _any_state_active(names_variant: Variant) -> bool:
	var names: Array = names_variant if names_variant is Array else []
	var gesture_states: Dictionary = _latest_state.get("gesture_states", {})
	for name_variant: Variant in names:
		var state_name := String(name_variant)
		if bool(gesture_states.get(state_name, false)):
			return true
	return false

func _any_recent_event(names_variant: Variant) -> bool:
	var names: Array = names_variant if names_variant is Array else []
	for name_variant: Variant in names:
		var event_name := String(name_variant)
		var timestamp_ms := int(_last_event_timestamps_ms.get(event_name, 0))
		if timestamp_ms > 0 and Time.get_ticks_msec() - timestamp_ms <= TILE_PULSE_MS:
			return true
	return false

func _fmt_bool(value: bool) -> String:
	return "true" if value else "false"

func _fmt_degrees_int(value: float) -> String:
	return "%d°" % int(round(value))

func _apply_panel_style(panel: PanelContainer, bg: Color, border: Color, radius: int, border_width: int, expand_margin: int) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.set_corner_radius_all(radius)
	style.set_border_width_all(border_width)
	style.content_margin_left = expand_margin
	style.content_margin_top = expand_margin
	style.content_margin_right = expand_margin
	style.content_margin_bottom = expand_margin
	panel.add_theme_stylebox_override("panel", style)
