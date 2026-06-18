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
		"label": "Recent punch velocity peak >= {threshold}",
	},
	{
		"id": "elbow_shoulder_xy_distance",
		"label": "Elbow-shoulder XY distance <= {threshold}",
	},
	{
		"id": "bbox_area",
		"label": "BBox area",
		"row_kind": "info",
	},
	{
		"id": "bbox_area_growth",
		"label": "Recent bbox area growth peak >= {threshold}",
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
const PROTOTYPE_MATCHER_REQUIREMENT_ROWS := [
	{
		"id": "backend_section",
		"label": "Active backend",
		"row_kind": "section",
	},
	{
		"id": "active_backend",
		"label": "Active backend",
		"row_kind": "info",
	},
	{
		"id": "selected_backend",
		"label": "Selected backend",
		"row_kind": "info",
	},
	{
		"id": "library_id",
		"label": "Active prototype library ID",
		"row_kind": "info",
	},
	{
		"id": "library_loaded",
		"label": "Prototype library loaded",
		"row_kind": "info",
	},
	{
		"id": "score_section",
		"label": "Matcher result",
		"row_kind": "section",
	},
	{
		"id": "best_class",
		"label": "Best class",
		"row_kind": "info",
	},
	{
		"id": "best_score",
		"label": "Best score",
		"row_kind": "info",
	},
	{
		"id": "required_score",
		"label": "Threshold required",
		"row_kind": "info",
	},
	{
		"id": "result_class",
		"label": "Final emitted / result class",
		"row_kind": "info",
	},
	{
		"id": "emitted_event_name",
		"label": "Emitted event name",
		"row_kind": "info",
	},
	{
		"id": "show_scores",
		"label": "show_scores flag",
		"row_kind": "info",
	},
	{
		"id": "class_scores",
		"label": "Per-class scores",
		"row_kind": "info",
	},
	{
		"id": "gate_section",
		"label": "Hold / cooldown gate",
		"row_kind": "section",
	},
	{
		"id": "show_event_gate_state",
		"label": "show_event_gate_state flag",
		"row_kind": "info",
	},
	{
		"id": "gate_reason",
		"label": "Gate / rejection reason",
		"row_kind": "info",
	},
	{
		"id": "hold_ms_remaining",
		"label": "Hold remaining",
		"row_kind": "info",
	},
	{
		"id": "cooldown_ms_remaining",
		"label": "Cooldown remaining",
		"row_kind": "info",
	},
	{
		"id": "active_event_class",
		"label": "Active held event class",
		"row_kind": "info",
	},
]
const POSE_STRIKE_REQUIREMENT_ROWS := [
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
		"label": "Pose tracking",
		"row_kind": "info",
	},
	{
		"id": "trigger_section",
		"label": "Trigger inputs",
		"row_kind": "section",
	},
	{
		"id": "velocity_window",
		"label": "Motion window",
		"row_kind": "info",
	},
	{
		"id": "averaged_velocity",
		"label": "Averaged velocity >= {threshold}",
	},
	{
		"id": "dominance_ratio",
		"label": "Dominance ratio >= {threshold}",
	},
	{
		"id": "directionality_ratio",
		"label": "Signed direction share >= {threshold}",
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
		"id": "rearm_status",
		"label": "Pose-only rearm",
		"row_kind": "info",
	},
	{
		"id": "reacquire_progress",
		"label": "Reacquire progress",
		"row_kind": "info",
	},
]
const GUARD_REQUIREMENT_ROWS := [
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
		"id": "candidate",
		"label": "Guard candidate",
		"row_kind": "info",
	},
	{
		"id": "threshold_section",
		"label": "Pose-only thresholds",
		"row_kind": "section",
	},
	{
		"id": "wrist_separation_x",
		"label": "Wrist separation X <= {threshold}",
	},
	{
		"id": "wrist_separation_y",
		"label": "Wrist separation Y <= {threshold}",
	},
	{
		"id": "left_wrist_above_elbow",
		"label": "Left wrist above left elbow",
	},
	{
		"id": "right_wrist_above_elbow",
		"label": "Right wrist above right elbow",
	},
	{
		"id": "left_wrist_nose_distance",
		"label": "Left wrist nose distance <= {threshold}",
	},
	{
		"id": "right_wrist_nose_distance",
		"label": "Right wrist nose distance <= {threshold}",
	},
]
const SQUAT_REQUIREMENT_ROWS := [
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
		"id": "calibration_ready",
		"label": "Calibration ready",
		"row_kind": "info",
	},
	{
		"id": "calibration_sample_frames",
		"label": "Calibration sample frames",
		"row_kind": "info",
	},
	{
		"id": "threshold_section",
		"label": "Calibrated torso-height thresholds",
		"row_kind": "section",
	},
	{
		"id": "enter_height_ratio_max",
		"label": "Squat enter height ratio <= {threshold}",
	},
	{
		"id": "exit_height_ratio_min",
		"label": "Squat exit height ratio >= {threshold}",
	},
	{
		"id": "live_section",
		"label": "Live measurements",
		"row_kind": "section",
	},
	{
		"id": "height_ratio",
		"label": "Live torso / calibrated torso",
		"row_kind": "info",
	},
	{
		"id": "squat_depth",
		"label": "Squat depth",
		"row_kind": "info",
	},
	{
		"id": "height_state",
		"label": "Height state",
		"row_kind": "info",
	},
	{
		"id": "torso_height_pair",
		"label": "Torso height (live / baseline)",
		"row_kind": "info",
	},
]
const WEAVE_REQUIREMENT_ROWS := [
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
		"id": "left_candidate",
		"label": "Left weave candidate",
		"row_kind": "info",
	},
	{
		"id": "right_candidate",
		"label": "Right weave candidate",
		"row_kind": "info",
	},
	{
		"id": "neutral_candidate",
		"label": "Neutral release candidate",
		"row_kind": "info",
	},
	{
		"id": "threshold_section",
		"label": "Pose-only thresholds",
		"row_kind": "section",
	},
	{
		"id": "enter_head_lateral_offset_min",
		"label": "Head lateral offset magnitude >= {threshold}",
	},
	{
		"id": "enter_relative_head_hip_offset_min",
		"label": "Head-vs-hip offset magnitude >= {threshold}",
	},
	{
		"id": "enter_head_drop_ratio_min",
		"label": "Head drop ratio >= {threshold}",
	},
	{
		"id": "exit_head_lateral_offset_max",
		"label": "Neutral head lateral offset magnitude <= {threshold}",
	},
	{
		"id": "exit_relative_head_hip_offset_max",
		"label": "Neutral head-vs-hip offset magnitude <= {threshold}",
	},
	{
		"id": "live_section",
		"label": "Live measurements",
		"row_kind": "section",
	},
	{
		"id": "head_lateral_offset",
		"label": "Head lateral offset",
		"row_kind": "info",
	},
	{
		"id": "hip_lateral_offset",
		"label": "Hip lateral offset",
		"row_kind": "info",
	},
	{
		"id": "relative_head_hip_offset",
		"label": "Head-vs-hip lateral offset",
		"row_kind": "info",
	},
	{
		"id": "head_drop_ratio",
		"label": "Head drop ratio",
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
	"hook_left": {
		"title": "Hook L",
		"rows": POSE_STRIKE_REQUIREMENT_ROWS,
		"family": "hook",
	},
	"hook_right": {
		"title": "Hook R",
		"rows": POSE_STRIKE_REQUIREMENT_ROWS,
		"family": "hook",
	},
	"uppercut_left": {
		"title": "Uppercut L",
		"rows": POSE_STRIKE_REQUIREMENT_ROWS,
		"family": "uppercut",
	},
	"uppercut_right": {
		"title": "Uppercut R",
		"rows": POSE_STRIKE_REQUIREMENT_ROWS,
		"family": "uppercut",
	},
	"guard": {
		"title": "Guard",
		"rows": GUARD_REQUIREMENT_ROWS,
	},
	"squat": {
		"title": "Squat",
		"rows": SQUAT_REQUIREMENT_ROWS,
	},
	"weave": {
		"title": "Weave",
		"rows": WEAVE_REQUIREMENT_ROWS,
	},
}

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
var _boxing_event_feed_autoscroll_pending := false
var _paused_boxing_state_active := false
var _paused_boxing_snapshot_time_ms := 0
var _paused_boxing_latest_state: Dictionary = {}
var _paused_straight_punch_transition_debug := {
	"left": {},
	"right": {},
}
var _straight_punch_transition_debug := {
	"left": {},
	"right": {},
}

func _ready() -> void:
	_selected_profile_id = _default_profile_id()
	_resolve_boxing_shell_nodes()
	_build_tile_grid_if_needed()
	_apply_boxing_visual_shell()
	super._ready()
	_refresh_profile_controls()
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
	if _paused_boxing_state_active:
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
		if _boxing_event_feed_autoscroll_pending and quick_stats_label.has_method("scroll_to_line"):
			quick_stats_label.scroll_to_line(0)
		_boxing_event_feed_autoscroll_pending = false
	_update_tile_states()

func _sync_playback_status_from_manager() -> void:
	var was_paused := bool(_playback_status.get("paused", false))
	super._sync_playback_status_from_manager()
	if harness_mode != HarnessMode.BOXING:
		return
	var paused := bool(_playback_status.get("paused", false))
	if paused:
		if not was_paused or not _paused_boxing_state_active:
			_capture_paused_boxing_snapshot()
	else:
		_clear_paused_boxing_snapshot()

func _capture_paused_boxing_snapshot() -> void:
	_paused_boxing_state_active = true
	_paused_boxing_snapshot_time_ms = Time.get_ticks_msec()
	_paused_boxing_latest_state = _latest_state.duplicate(true)
	_paused_straight_punch_transition_debug = _straight_punch_transition_debug.duplicate(true)

func _clear_paused_boxing_snapshot() -> void:
	_paused_boxing_state_active = false
	_paused_boxing_snapshot_time_ms = 0
	_paused_boxing_latest_state = {}
	_paused_straight_punch_transition_debug = {
		"left": {},
		"right": {},
	}

func _sync_hand_bbox_drawer() -> void:
	if hand_bbox_drawer == null:
		return
	var overlay_parent: Node = _resolve_hand_bbox_overlay_parent()
	if overlay_parent != null and hand_bbox_drawer.get_parent() != overlay_parent:
		hand_bbox_drawer.reparent(overlay_parent)
	_configure_overlay_drawer(hand_bbox_drawer, BBOX_DRAWER_Z_INDEX)
	if _preview_presenter != null and is_instance_valid(_preview_presenter) and hand_bbox_drawer.has_method("set_preview_presenter"):
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

func _resolve_hand_bbox_overlay_parent() -> Node:
	if _preview_presenter == null or not is_instance_valid(_preview_presenter):
		return hand_bbox_drawer.get_parent()
	if _preview_presenter.has_method("get_overlay_layer"):
		var overlay_layer: Variant = _preview_presenter.get_overlay_layer()
		if overlay_layer is Node and is_instance_valid(overlay_layer):
			return overlay_layer
	return _preview_presenter

func _record_event(event_name: String, payload: Dictionary) -> void:
	if harness_mode == HarnessMode.BOXING:
		if UI_EVENT_LABELS.has(event_name):
			_boxing_event_sequence += 1
			_boxing_event_feed.append("%04d: %s" % [_boxing_event_sequence, String(UI_EVENT_LABELS[event_name])])
			while _boxing_event_feed.size() > MAX_BOXING_FEED_ROWS:
				_boxing_event_feed.remove_at(0)
			_boxing_event_feed_autoscroll_pending = true
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
	_boxing_event_feed_autoscroll_pending = false
	_clear_paused_boxing_snapshot()
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
	return PROFILE_BOXING

func _refresh_profile_controls() -> void:
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
	_apply_testbed_debug_profile_bundle(resolved_bundle)
	var camera_tracking: Dictionary = resolved_bundle.get("camera_tracking", {}) if resolved_bundle.get("camera_tracking", {}) is Dictionary else {}
	var preview: Dictionary = camera_tracking.get("preview", {}) if camera_tracking.get("preview", {}) is Dictionary else {}
	var preview_overlays: Dictionary = preview.get("overlays", {}) if preview.get("overlays", {}) is Dictionary else {}
	var testbed_debug: Dictionary = resolved_bundle.get("testbed_debug", {}) if resolved_bundle.get("testbed_debug", {}) is Dictionary else {}
	var visuals: Dictionary = testbed_debug.get("visuals", {}) if testbed_debug.get("visuals", {}) is Dictionary else {}
	show_landmarks = bool(preview_overlays.get("pose_skeleton_visible", visuals.get("show_landmarks", show_landmarks)))
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
		var show_hand_bbox_overlay := bool(preview_overlays.get("hand_bbox_visible", visuals.get("show_hand_bbox_overlay", hand_bbox_drawer.visible)))
		hand_bbox_drawer.visible = show_hand_bbox_overlay
		if not show_hand_bbox_overlay and hand_bbox_drawer.has_method("clear_snapshot"):
			hand_bbox_drawer.clear_snapshot()
		else:
			hand_bbox_drawer.queue_redraw()

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
		if String(row.get("id", "")) == "state_change_payload":
			continue
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
			if _active_punch_detection_backend() == "prototype_matcher":
				return _build_prototype_matcher_hover_card_model(spec, "left")
			if _active_punch_detection_backend() == "learned_classifier":
				return _build_learned_classifier_hover_card_model(spec, "left")
			return _build_punch_hover_card_model(spec, "left")
		"punch_right":
			if _active_punch_detection_backend() == "prototype_matcher":
				return _build_prototype_matcher_hover_card_model(spec, "right")
			if _active_punch_detection_backend() == "learned_classifier":
				return _build_learned_classifier_hover_card_model(spec, "right")
			return _build_punch_hover_card_model(spec, "right")
		"hook_left":
			return _build_pose_strike_hover_card_model(spec, "hook", "left")
		"hook_right":
			return _build_pose_strike_hover_card_model(spec, "hook", "right")
		"uppercut_left":
			return _build_pose_strike_hover_card_model(spec, "uppercut", "left")
		"uppercut_right":
			return _build_pose_strike_hover_card_model(spec, "uppercut", "right")
		"guard":
			return _build_guard_hover_card_model(spec)
		"squat":
			return _build_squat_hover_card_model(spec)
		"weave":
			return _build_weave_hover_card_model(spec)
		_:
			return spec.duplicate(true)

func _boxing_latest_state_snapshot() -> Dictionary:
	return _paused_boxing_latest_state if _paused_boxing_state_active else _latest_state

func _active_punch_detection_backend() -> String:
	var latest_state := _boxing_latest_state_snapshot()
	var gesture_debug: Dictionary = (latest_state.get("gesture_debug", {}) as Dictionary)
	var punch_detection: Dictionary = (gesture_debug.get("punch_detection", {}) as Dictionary)
	return String(punch_detection.get("active_backend", punch_detection.get("backend", "threshold_gates")))

func _prototype_matcher_debug_state() -> Dictionary:
	var latest_state := _boxing_latest_state_snapshot()
	var gesture_debug: Dictionary = (latest_state.get("gesture_debug", {}) as Dictionary)
	return ((gesture_debug.get("prototype_matcher", {}) as Dictionary)).duplicate(true)

func _learned_classifier_debug_state() -> Dictionary:
	var latest_state := _boxing_latest_state_snapshot()
	var gesture_debug: Dictionary = (latest_state.get("gesture_debug", {}) as Dictionary)
	return ((gesture_debug.get("learned_classifier", {}) as Dictionary)).duplicate(true)

func _merged_punch_debug_state(side: String) -> Dictionary:
	var latest_state := _boxing_latest_state_snapshot()
	var gesture_debug: Dictionary = (latest_state.get("gesture_debug", {}) as Dictionary)
	var straight_punch_debug: Dictionary = (gesture_debug.get("straight_punch", {}) as Dictionary)
	var straight_side: Dictionary = ((straight_punch_debug.get(side, {}) as Dictionary)).duplicate(true)
	var transition_debug_source := _paused_straight_punch_transition_debug if _paused_boxing_state_active else _straight_punch_transition_debug
	var transition_debug: Dictionary = (transition_debug_source.get(side, {}) as Dictionary)
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

func _build_prototype_matcher_hover_card_model(spec: Dictionary, side: String) -> Dictionary:
	return _build_classifier_hover_card_model(spec, side, "prototype_matcher", _prototype_matcher_debug_state())

func _build_learned_classifier_hover_card_model(spec: Dictionary, side: String) -> Dictionary:
	return _build_classifier_hover_card_model(spec, side, "learned_classifier", _learned_classifier_debug_state())

func _build_classifier_hover_card_model(spec: Dictionary, side: String, backend: String, classifier_debug: Dictionary) -> Dictionary:
	var rows: Array[Dictionary] = []
	for row_spec_variant: Variant in _classifier_requirement_rows_for_backend(backend):
		var row_spec: Dictionary = row_spec_variant
		rows.append(_build_classifier_requirement_row(row_spec, classifier_debug, backend, side))
	var title_suffix := "Prototype Matcher" if backend == "prototype_matcher" else "Learned Classifier"
	var footer_source := "gesture_debug.prototype_matcher" if backend == "prototype_matcher" else "gesture_debug.learned_classifier"
	return {
		"title": "%s (%s)" % [String(spec.get("title", _display_name_for_card_key("punch_%s" % side))), title_suffix],
		"rows": rows,
		"footer": "Live values come from %s for the active punch backend." % footer_source,
	}

func _build_pose_strike_hover_card_model(spec: Dictionary, family: String, side: String) -> Dictionary:
	var latest_state := _paused_boxing_latest_state if _paused_boxing_state_active else _latest_state
	var gesture_debug: Dictionary = (latest_state.get("gesture_debug", {}) as Dictionary)
	var family_debug: Dictionary = (gesture_debug.get(family, {}) as Dictionary)
	var side_debug: Dictionary = ((family_debug.get(side, {}) as Dictionary)).duplicate(true)
	var rows: Array[Dictionary] = []
	for row_spec_variant: Variant in spec.get("rows", []):
		var row_spec: Dictionary = row_spec_variant
		rows.append(_build_pose_strike_requirement_row(row_spec, side_debug, family, side))
	return {
		"title": spec.get("title", _display_name_for_card_key("%s_%s" % [family, side])),
		"rows": rows,
		"footer": spec.get("footer", "Live values come from the pose-primary %s state machine." % family),
	}

func _build_guard_hover_card_model(spec: Dictionary) -> Dictionary:
	var latest_state := _paused_boxing_latest_state if _paused_boxing_state_active else _latest_state
	var gesture_debug: Dictionary = (latest_state.get("gesture_debug", {}) as Dictionary)
	var guard_debug: Dictionary = ((gesture_debug.get("guard", {}) as Dictionary)).duplicate(true)
	var rows: Array[Dictionary] = []
	for row_spec_variant: Variant in spec.get("rows", []):
		var row_spec: Dictionary = row_spec_variant
		rows.append(_build_guard_requirement_row(row_spec, guard_debug))
	return {
		"title": spec.get("title", "Guard"),
		"rows": rows,
		"footer": spec.get("footer", "Live values come from the pose-only guard detector."),
	}

func _build_squat_hover_card_model(spec: Dictionary) -> Dictionary:
	var latest_state := _paused_boxing_latest_state if _paused_boxing_state_active else _latest_state
	var gesture_debug: Dictionary = (latest_state.get("gesture_debug", {}) as Dictionary)
	var squat_debug: Dictionary = ((gesture_debug.get("squat", {}) as Dictionary)).duplicate(true)
	var rows: Array[Dictionary] = []
	for row_spec_variant: Variant in spec.get("rows", []):
		var row_spec: Dictionary = row_spec_variant
		rows.append(_build_squat_requirement_row(row_spec, squat_debug))
	return {
		"title": spec.get("title", "Squat"),
		"rows": rows,
		"footer": spec.get("footer", "Live values come from the calibrated torso-height squat detector."),
	}

func _build_weave_hover_card_model(spec: Dictionary) -> Dictionary:
	var latest_state := _paused_boxing_latest_state if _paused_boxing_state_active else _latest_state
	var gesture_debug: Dictionary = (latest_state.get("gesture_debug", {}) as Dictionary)
	var weave_debug: Dictionary = ((gesture_debug.get("weave", {}) as Dictionary)).duplicate(true)
	var rows: Array[Dictionary] = []
	for row_spec_variant: Variant in spec.get("rows", []):
		var row_spec: Dictionary = row_spec_variant
		rows.append(_build_weave_requirement_row(row_spec, weave_debug))
	return {
		"title": spec.get("title", "Weave"),
		"rows": rows,
		"footer": spec.get("footer", "Live values come from the pose-only weave detector."),
	}

func _boxing_reference_time_ms() -> int:
	return _paused_boxing_snapshot_time_ms if _paused_boxing_state_active else Time.get_ticks_msec()

func _build_squat_requirement_row(row_spec: Dictionary, squat_debug: Dictionary) -> Dictionary:
	var row := row_spec.duplicate(true)
	var row_id := String(row_spec.get("id", ""))
	var passed := false
	var current_text := ""
	var threshold_text := ""
	var state_active := bool(squat_debug.get("state", false))
	var height_ratio := float(squat_debug.get("height_ratio", 1.0))
	match row_id:
		"state_section", "threshold_section", "live_section":
			current_text = ""
			passed = false
		"current_state":
			current_text = "active" if state_active else "inactive"
			passed = state_active
		"calibration_ready":
			current_text = _fmt_bool(bool(squat_debug.get("calibration_ready", false)))
			passed = bool(squat_debug.get("calibration_ready", false))
		"calibration_sample_frames":
			current_text = str(int(squat_debug.get("calibration_sample_frames", 0)))
			passed = int(squat_debug.get("calibration_sample_frames", 0)) > 0
		"enter_height_ratio_max":
			threshold_text = _fmt_float(squat_debug.get("enter_height_ratio_max", 0.0))
			current_text = _fmt_float(height_ratio)
			passed = height_ratio <= float(squat_debug.get("enter_height_ratio_max", 0.0))
		"exit_height_ratio_min":
			threshold_text = _fmt_float(squat_debug.get("exit_height_ratio_min", 0.0))
			current_text = _fmt_float(height_ratio)
			passed = height_ratio >= float(squat_debug.get("exit_height_ratio_min", 0.0))
		"height_ratio":
			current_text = _fmt_float(height_ratio)
			passed = state_active
		"squat_depth":
			current_text = _fmt_float(squat_debug.get("squat_depth", 0.0))
			passed = float(squat_debug.get("squat_depth", 0.0)) > 0.0
		"height_state":
			current_text = String(squat_debug.get("height_state", "unknown"))
			passed = current_text == "lowered"
		"torso_height_pair":
			current_text = "%s / %s" % [_fmt_float(squat_debug.get("torso_height", 0.0)), _fmt_float(squat_debug.get("baseline_torso_height", 0.0))]
			passed = float(squat_debug.get("baseline_torso_height", 0.0)) > 0.0
		_:
			current_text = String(squat_debug.get(row_id, ""))
	row["threshold_text"] = threshold_text
	row["current_text"] = current_text
	row["passed"] = passed
	return row

func _build_guard_requirement_row(row_spec: Dictionary, guard_debug: Dictionary) -> Dictionary:
	var row := row_spec.duplicate(true)
	var row_id := String(row_spec.get("id", ""))
	var label := String(row_spec.get("label", ""))
	var passed := false
	var current_text := ""
	var threshold_text := ""
	var state_active := bool(guard_debug.get("state", false))
	var candidate := bool(guard_debug.get("candidate", false))
	match row_id:
		"state_section", "threshold_section":
			current_text = ""
			passed = false
		"current_state":
			current_text = "active" if state_active else "inactive"
			passed = state_active
		"candidate":
			current_text = _fmt_bool(candidate)
			passed = candidate
		"wrist_separation_x":
			threshold_text = _fmt_float(guard_debug.get("max_wrist_separation_x", 0.0))
			current_text = _fmt_float(guard_debug.get("wrist_separation_x", 0.0))
			passed = bool(guard_debug.get("wrists_close_x", false))
		"wrist_separation_y":
			threshold_text = _fmt_float(guard_debug.get("max_wrist_separation_y", 0.0))
			current_text = _fmt_float(guard_debug.get("wrist_separation_y", 0.0))
			passed = bool(guard_debug.get("wrists_close_y", false))
		"left_wrist_above_elbow":
			current_text = _fmt_bool(bool(guard_debug.get("left_wrist_above_elbow", false)))
			passed = bool(guard_debug.get("left_wrist_above_elbow", false))
		"right_wrist_above_elbow":
			current_text = _fmt_bool(bool(guard_debug.get("right_wrist_above_elbow", false)))
			passed = bool(guard_debug.get("right_wrist_above_elbow", false))
		"left_wrist_nose_distance":
			threshold_text = _fmt_float(guard_debug.get("max_wrist_nose_distance", 0.0))
			current_text = _fmt_float(guard_debug.get("left_wrist_nose_distance", 0.0))
			passed = bool(guard_debug.get("left_wrist_near_nose", false))
		"right_wrist_nose_distance":
			threshold_text = _fmt_float(guard_debug.get("max_wrist_nose_distance", 0.0))
			current_text = _fmt_float(guard_debug.get("right_wrist_nose_distance", 0.0))
			passed = bool(guard_debug.get("right_wrist_near_nose", false))
		_:
			current_text = "pending"
			passed = false
	row["label"] = label
	row["passed"] = passed
	row["threshold_text"] = threshold_text
	row["current_text"] = current_text
	return row

func _build_weave_requirement_row(row_spec: Dictionary, weave_debug: Dictionary) -> Dictionary:
	var row := row_spec.duplicate(true)
	var row_id := String(row_spec.get("id", ""))
	var label := String(row_spec.get("label", ""))
	var passed := false
	var current_text := ""
	var threshold_text := ""
	var state_name := String(weave_debug.get("state", "inactive"))
	var head_offset := float(weave_debug.get("head_lateral_offset", 0.0))
	var hip_offset := float(weave_debug.get("hip_lateral_offset", 0.0))
	var relative_offset := float(weave_debug.get("relative_head_hip_offset", 0.0))
	var head_drop_ratio := float(weave_debug.get("head_drop_ratio", 0.0))
	match row_id:
		"state_section", "threshold_section", "live_section":
			current_text = ""
			passed = false
		"current_state":
			current_text = state_name
			passed = state_name != "inactive"
		"left_candidate":
			current_text = _fmt_bool(bool(weave_debug.get("left_candidate", false)))
			passed = bool(weave_debug.get("left_candidate", false))
		"right_candidate":
			current_text = _fmt_bool(bool(weave_debug.get("right_candidate", false)))
			passed = bool(weave_debug.get("right_candidate", false))
		"neutral_candidate":
			current_text = _fmt_bool(bool(weave_debug.get("neutral_candidate", false)))
			passed = bool(weave_debug.get("neutral_candidate", false))
		"enter_head_lateral_offset_min":
			threshold_text = _fmt_float(weave_debug.get("enter_head_lateral_offset_min", 0.0))
			current_text = _fmt_float(absf(head_offset))
			passed = bool(weave_debug.get("head_offset_left_ready", false)) or bool(weave_debug.get("head_offset_right_ready", false))
		"enter_relative_head_hip_offset_min":
			threshold_text = _fmt_float(weave_debug.get("enter_relative_head_hip_offset_min", 0.0))
			current_text = _fmt_float(absf(relative_offset))
			passed = bool(weave_debug.get("relative_offset_left_ready", false)) or bool(weave_debug.get("relative_offset_right_ready", false))
		"enter_head_drop_ratio_min":
			threshold_text = _fmt_float(weave_debug.get("enter_head_drop_ratio_min", 0.0))
			current_text = _fmt_float(head_drop_ratio)
			passed = bool(weave_debug.get("head_drop_ready", false))
		"exit_head_lateral_offset_max":
			threshold_text = _fmt_float(weave_debug.get("exit_head_lateral_offset_max", 0.0))
			current_text = _fmt_float(absf(head_offset))
			passed = absf(head_offset) <= float(weave_debug.get("exit_head_lateral_offset_max", 0.0))
		"exit_relative_head_hip_offset_max":
			threshold_text = _fmt_float(weave_debug.get("exit_relative_head_hip_offset_max", 0.0))
			current_text = _fmt_float(absf(relative_offset))
			passed = absf(relative_offset) <= float(weave_debug.get("exit_relative_head_hip_offset_max", 0.0))
		"head_lateral_offset":
			current_text = _fmt_float(head_offset)
			passed = state_name == "left" or state_name == "right"
		"hip_lateral_offset":
			current_text = _fmt_float(hip_offset)
			passed = absf(hip_offset) > 0.0
		"relative_head_hip_offset":
			current_text = _fmt_float(relative_offset)
			passed = state_name == "left" or state_name == "right"
		"head_drop_ratio":
			current_text = _fmt_float(head_drop_ratio)
			passed = head_drop_ratio > 0.0
		_:
			current_text = "pending"
			passed = false
	row["label"] = label
	row["passed"] = passed
	row["threshold_text"] = threshold_text
	row["current_text"] = current_text
	return row

func _fmt_matcher_class_scores(class_scores: Dictionary) -> String:
	if class_scores.is_empty():
		return "{}"
	var ordered_keys: Array[String] = []
	for key_variant: Variant in class_scores.keys():
		ordered_keys.append(String(key_variant))
	ordered_keys.sort()
	var pairs: Array[String] = []
	for key: String in ordered_keys:
		pairs.append("%s=%s" % [key, _fmt_float(class_scores.get(key, 0.0))])
	return "{" + ", ".join(pairs) + "}"

func _classifier_requirement_rows_for_backend(backend: String) -> Array:
	var rows: Array = PROTOTYPE_MATCHER_REQUIREMENT_ROWS.duplicate(true)
	if backend == "prototype_matcher":
		return rows
	for row_variant: Variant in rows:
		if not row_variant is Dictionary:
			continue
		var row: Dictionary = row_variant
		match String(row.get("id", "")):
			"library_id":
				row["label"] = "Active learned model path"
			"library_loaded":
				row["label"] = "Learned model loaded"
	return rows

func _build_classifier_requirement_row(row_spec: Dictionary, classifier_debug: Dictionary, backend: String, _side: String) -> Dictionary:
	var row := row_spec.duplicate(true)
	var row_id := String(row_spec.get("id", ""))
	var passed := false
	var current_text := ""
	match row_id:
		"backend_section", "score_section", "gate_section":
			current_text = ""
		"active_backend":
			current_text = String(classifier_debug.get("active_backend", "inactive"))
			passed = current_text == backend
		"selected_backend":
			current_text = String(classifier_debug.get("selected_backend", ""))
			passed = current_text == backend
		"library_id":
			current_text = String(classifier_debug.get("library_id", classifier_debug.get("model_path", "")))
			passed = not current_text.is_empty()
		"library_loaded":
			current_text = _fmt_bool(bool(classifier_debug.get("library_loaded", classifier_debug.get("model_loaded", false))))
			passed = bool(classifier_debug.get("library_loaded", classifier_debug.get("model_loaded", false)))
		"best_class":
			current_text = String(classifier_debug.get("best_class", "no_punch"))
			passed = not current_text.is_empty()
		"best_score":
			current_text = _fmt_float(classifier_debug.get("best_score", 0.0))
			passed = true
		"required_score":
			current_text = _fmt_float(classifier_debug.get("required_score", classifier_debug.get("match_score_min", 0.0)))
			passed = true
		"result_class":
			current_text = String(classifier_debug.get("result_class", "no_punch"))
			passed = not current_text.is_empty()
		"emitted_event_name":
			current_text = String(classifier_debug.get("emitted_event_name", ""))
			if current_text.is_empty():
				current_text = "none"
			passed = true
		"show_scores":
			current_text = _fmt_bool(bool(classifier_debug.get("show_scores", false)))
			passed = true
		"class_scores":
			if bool(classifier_debug.get("show_scores", false)):
				current_text = _fmt_matcher_class_scores(classifier_debug.get("class_scores", {}) as Dictionary)
			else:
				current_text = "hidden (show_scores=false)"
			passed = true
		"show_event_gate_state":
			current_text = _fmt_bool(bool(classifier_debug.get("show_event_gate_state", false)))
			passed = true
		"gate_reason":
			if bool(classifier_debug.get("show_event_gate_state", false)):
				current_text = String(classifier_debug.get("reason", "idle"))
				var model_error := String(classifier_debug.get("model_error", ""))
				if backend == "learned_classifier" and not model_error.is_empty():
					current_text += " (%s)" % model_error
			else:
				current_text = "hidden (show_event_gate_state=false)"
			passed = true
		"hold_ms_remaining":
			if bool(classifier_debug.get("show_event_gate_state", false)):
				current_text = "%dms" % int(classifier_debug.get("hold_ms_remaining", 0))
			else:
				current_text = "hidden (show_event_gate_state=false)"
			passed = true
		"cooldown_ms_remaining":
			if bool(classifier_debug.get("show_event_gate_state", false)):
				current_text = "%dms" % int(classifier_debug.get("cooldown_ms_remaining", 0))
			else:
				current_text = "hidden (show_event_gate_state=false)"
			passed = true
		"active_event_class":
			if bool(classifier_debug.get("show_event_gate_state", false)):
				current_text = String(classifier_debug.get("active_event_class", "no_punch"))
			else:
				current_text = "hidden (show_event_gate_state=false)"
			passed = true
		_:
			current_text = "pending"
	row["current_text"] = current_text
	row["passed"] = passed
	return row

func _build_punch_requirement_row(row_spec: Dictionary, straight_side: Dictionary, _side: String) -> Dictionary:
	var row := row_spec.duplicate(true)
	var row_id := String(row_spec.get("id", ""))
	var label := String(row_spec.get("label", ""))
	var passed := false
	var current_text := ""
	var threshold_text := ""
	var hand_tracking_enabled := bool(straight_side.get("hand_tracking_enabled", true))
	var pose_tracking_valid := bool(straight_side.get("pose_tracking_valid", false))
	var state_name := String(straight_side.get("state", straight_side.get("phase", "tracking_lost")))
	var wrist_velocity := float(straight_side.get("wrist_velocity", 0.0))
	var recent_peak_wrist_velocity := float(straight_side.get("recent_peak_wrist_velocity", wrist_velocity))
	var min_velocity := float(straight_side.get("min_velocity", 0.0))
	var forward_depth_spike := float(straight_side.get("forward_depth_spike", 0.0))
	var recent_peak_forward_depth_spike := float(straight_side.get("recent_peak_forward_depth_spike", forward_depth_spike))
	var bbox_area := float(straight_side.get("bbox_area", 0.0))
	var elbow_shoulder_xy_distance := float(straight_side.get("elbow_shoulder_xy_distance", 0.0))
	var max_elbow_shoulder_xy_distance := float(straight_side.get("max_elbow_shoulder_xy_distance", 0.0))
	var elbow_shoulder_xy_gate_passed := bool(straight_side.get("elbow_shoulder_xy_gate_passed", false))
	var bbox_area_growth := float(straight_side.get("bbox_area_growth", 0.0))
	var recent_peak_bbox_area_growth := float(straight_side.get("recent_peak_bbox_area_growth", bbox_area_growth))
	var min_bbox_area_growth := float(straight_side.get("min_bbox_area_growth", 0.0))
	var positive_growth_samples := int(straight_side.get("positive_growth_samples", 0))
	var min_positive_growth_samples := int(straight_side.get("min_positive_growth_samples", 0))
	var sample_window_size := int(straight_side.get("sample_window_size", 0))
	var growth_window_areas: Array = straight_side.get("growth_window_areas", []) as Array
	var positive_growth_sample_slots := maxi(growth_window_areas.size() - 1, 0)
	if positive_growth_sample_slots <= 0:
		positive_growth_sample_slots = maxi(sample_window_size - 1, 0)
	var fresh_sample := bool(straight_side.get("fresh_sample", false))
	var tracking_valid := bool(straight_side.get("tracking_valid", false))
	var tracking_state := String(straight_side.get("tracking_state", "idle"))
	var sample_source := String(straight_side.get("sample_source", "none"))
	var stale_frames := int(straight_side.get("stale_frames", 0))
	var stale_ms := int(straight_side.get("stale_ms", 0))
	var grace_frames := int(straight_side.get("grace_frames", 0))
	var grace_ms := int(straight_side.get("grace_ms", 0))
	var hand_stable_ms := int(straight_side.get("stable_ms", 0))
	var transition_timestamp_ms := int(straight_side.get("timestamp_ms", 0))
	var previous_state := String(straight_side.get("previous_state", ""))
	var grace_ms_remaining := int(straight_side.get("grace_ms_remaining", 0))
	var triggered_grace_ms := int(straight_side.get("triggered_grace_ms", 0))
	var trigger_bbox_area := float(straight_side.get("trigger_bbox_area", 0.0))
	var bbox_area_retract_epsilon := float(straight_side.get("bbox_area_retract_epsilon", 0.0))
	var pose_only_rearm_ms := int(straight_side.get("pose_only_rearm_ms", 0))
	var rearm_threshold := maxf(trigger_bbox_area - bbox_area_retract_epsilon, 0.0)
	var rearm_ready := trigger_bbox_area > 0.0 and bbox_area <= rearm_threshold
	var reacquire_stable_ms_required := int(straight_side.get("reacquire_stable_ms_required", 0))
	var reference_time_ms: int = _boxing_reference_time_ms()
	var transition_age_ms: int = max(0, reference_time_ms - transition_timestamp_ms) if transition_timestamp_ms > 0 else 0
	match row_id:
		"state_section", "trigger_section", "rearm_section":
			current_text = ""
			passed = false
		"current_state":
			current_text = state_name
			passed = state_name != "tracking_lost"
		"tracking_status":
			if hand_tracking_enabled:
				current_text = "%s, valid=%s, source=%s, stale=%dms (%d frames), grace=%dms (%d frames), stable=%dms" % [tracking_state, _fmt_bool(tracking_valid), sample_source, stale_ms, stale_frames, grace_ms, grace_frames, hand_stable_ms]
				passed = tracking_valid
			else:
				current_text = "pose-only fallback, pose_valid=%s, tracking=%s, source=%s" % [_fmt_bool(pose_tracking_valid), tracking_state, sample_source]
				passed = pose_tracking_valid
		"fresh_sample":
			current_text = _fmt_bool(fresh_sample)
			if not hand_tracking_enabled:
				current_text += " (pose frame)"
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
					current_text += " (%s ago)" % _fmt_age_ms(_boxing_reference_time_ms() - transition_timestamp_ms)
				passed = true
		"state_change_payload":
			current_text = "state=%s wrist=%s depth=%s xy=%s<=%s (%s) bbox=%s growth=%s fresh=%s source=%s grace=%dms valid=%s" % [
				state_name,
				_fmt_float(wrist_velocity),
				_fmt_float(recent_peak_forward_depth_spike),
				_fmt_float(elbow_shoulder_xy_distance),
				_fmt_float(max_elbow_shoulder_xy_distance),
				_fmt_bool(elbow_shoulder_xy_gate_passed),
				_fmt_float(bbox_area),
				_fmt_float(bbox_area_growth),
				_fmt_bool(fresh_sample),
				sample_source,
				grace_ms_remaining,
				_fmt_bool(tracking_valid),
			]
			passed = transition_timestamp_ms > 0 or not straight_side.is_empty()
		"wrist_velocity":
			threshold_text = _fmt_float(min_velocity)
			passed = recent_peak_wrist_velocity >= min_velocity
			current_text = _fmt_threshold_comparison_value(recent_peak_wrist_velocity, min_velocity)
		"elbow_shoulder_xy_distance":
			threshold_text = _fmt_float(max_elbow_shoulder_xy_distance)
			passed = elbow_shoulder_xy_gate_passed
			current_text = _fmt_threshold_comparison_value(elbow_shoulder_xy_distance, max_elbow_shoulder_xy_distance, true)
		"bbox_area":
			if hand_tracking_enabled:
				current_text = _fmt_float(bbox_area)
				passed = bbox_area > 0.0
			else:
				current_text = "pose-only fallback (bbox skipped)"
				passed = pose_tracking_valid
		"bbox_area_growth":
			if hand_tracking_enabled:
				threshold_text = _fmt_float(min_bbox_area_growth)
				passed = recent_peak_bbox_area_growth + 0.000001 >= min_bbox_area_growth
				current_text = _fmt_threshold_comparison_value(recent_peak_bbox_area_growth, min_bbox_area_growth)
			else:
				threshold_text = "skipped"
				current_text = "pose-only fallback"
				passed = pose_tracking_valid
		"positive_growth_samples":
			if hand_tracking_enabled:
				threshold_text = "%d/%d" % [min_positive_growth_samples, positive_growth_sample_slots]
				current_text = "%d/%d" % [positive_growth_samples, positive_growth_sample_slots]
				passed = positive_growth_samples >= min_positive_growth_samples
			else:
				threshold_text = "skipped"
				current_text = "pose-only fallback"
				passed = pose_tracking_valid
		"growth_window_areas":
			if hand_tracking_enabled:
				var area_values: Array[String] = []
				for area_variant: Variant in growth_window_areas:
					area_values.append(_fmt_float(area_variant))
				current_text = "[" + ", ".join(area_values) + "]" if not area_values.is_empty() else "[]"
				passed = not area_values.is_empty()
			else:
				current_text = "pose-only fallback"
				passed = pose_tracking_valid
		"grace_timer":
			current_text = "%d/%dms remaining" % [grace_ms_remaining, triggered_grace_ms]
			if state_name == "triggered":
				current_text += " (active)"
			elif grace_ms_remaining > 0:
				current_text += " (counting down)"
			else:
				current_text += " (idle)"
			passed = state_name != "triggered" or grace_ms_remaining > 0
		"trigger_bbox_area":
			if hand_tracking_enabled:
				current_text = _fmt_float(trigger_bbox_area)
				if trigger_bbox_area <= 0.0:
					current_text += " (no stored trigger)"
				passed = trigger_bbox_area > 0.0
			else:
				current_text = "pose-only fallback (no bbox snapshot)"
				passed = true
		"rearm_status":
			if hand_tracking_enabled:
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
			else:
				if state_name == "not_ready":
					current_text = "%d/%dms elapsed (pose-only timer)" % [transition_age_ms, pose_only_rearm_ms]
					passed = transition_age_ms >= pose_only_rearm_ms
				elif state_name == "ready":
					current_text = "pose-only timer satisfied -> ready"
					passed = true
				else:
					current_text = "waiting for pose-only rearm timer"
					passed = state_name == "tracking_lost" or state_name == "triggered"
		"reacquire_progress":
			if hand_tracking_enabled:
				current_text = "%d/%dms hand stable" % [hand_stable_ms, reacquire_stable_ms_required]
				passed = hand_stable_ms >= reacquire_stable_ms_required
			else:
				current_text = "%s pose stable for straight-punch gating" % ["tracked" if pose_tracking_valid else "waiting"]
				passed = pose_tracking_valid
		_:
			current_text = "pending"
			passed = false
	row["label"] = label
	row["passed"] = passed
	row["threshold_text"] = threshold_text
	row["current_text"] = current_text
	return row

func _build_pose_strike_requirement_row(row_spec: Dictionary, side_debug: Dictionary, family: String, _side: String) -> Dictionary:
	var row := row_spec.duplicate(true)
	var row_id := String(row_spec.get("id", ""))
	var label := String(row_spec.get("label", ""))
	var passed := false
	var current_text := ""
	var threshold_text := ""
	var state_name := String(side_debug.get("state", side_debug.get("phase", "tracking_lost")))
	var tracking_state := String(side_debug.get("tracking_state", "pose_missing"))
	var pose_tracking_valid := bool(side_debug.get("pose_tracking_valid", false))
	var sample_source := String(side_debug.get("sample_source", "pose"))
	var window_ms := int(side_debug.get("window_ms", 0))
	var window_span_ms := int(side_debug.get("window_span_ms", 0))
	var averaged_velocity := float(side_debug.get("wrist_velocity", 0.0))
	var min_velocity := float(side_debug.get("min_velocity", side_debug.get("min_punch_velocity", 0.0)))
	var dominance_ratio := float(side_debug.get("dominance_ratio", 0.0))
	var required_dominance := float(side_debug.get("min_lateral_dominance_ratio", side_debug.get("min_vertical_dominance_ratio", 0.0)))
	var directionality_ratio := float(side_debug.get("directionality_ratio", 0.0))
	var required_directionality := float(side_debug.get("min_horizontal_direction_ratio", side_debug.get("min_upward_direction_ratio", 0.0)))
	var grace_ms_remaining := int(side_debug.get("grace_ms_remaining", 0))
	var triggered_grace_ms := int(side_debug.get("triggered_grace_ms", 0))
	var pose_only_rearm_ms := int(side_debug.get("pose_only_rearm_ms", 0))
	var reacquire_stable_ms_required := int(side_debug.get("reacquire_stable_ms_required", 0))
	var reference_time_ms: int = _boxing_reference_time_ms()
	var state_timestamp_ms := int(side_debug.get("timestamp_ms", 0))
	var transition_age_ms: int = max(0, reference_time_ms - state_timestamp_ms) if state_timestamp_ms > 0 else 0
	match row_id:
		"state_section", "trigger_section", "rearm_section":
			current_text = ""
			passed = false
		"current_state":
			current_text = state_name
			passed = state_name != "tracking_lost"
		"tracking_status":
			current_text = "pose_valid=%s, tracking=%s, source=%s" % [_fmt_bool(pose_tracking_valid), tracking_state, sample_source]
			passed = pose_tracking_valid
		"velocity_window":
			current_text = "%dms configured, %dms averaged span" % [window_ms, window_span_ms]
			passed = window_ms > 0
		"averaged_velocity":
			threshold_text = _fmt_float(min_velocity)
			current_text = _fmt_float(averaged_velocity)
			passed = averaged_velocity >= min_velocity
		"dominance_ratio":
			threshold_text = _fmt_float(required_dominance)
			current_text = _fmt_float(dominance_ratio)
			passed = dominance_ratio >= required_dominance
		"directionality_ratio":
			threshold_text = _fmt_float(required_directionality)
			current_text = _fmt_float(directionality_ratio)
			passed = directionality_ratio >= required_directionality
			if family == "hook":
				var direction_label := String(side_debug.get("required_direction_label", "signed direction")).capitalize()
				label = "Preview-space %s share of total motion >= {threshold}" % direction_label
			else:
				label = "%s share of total motion >= {threshold}" % String(side_debug.get("required_direction_label", "upward")).capitalize()
		"grace_timer":
			current_text = "%d/%dms remaining" % [grace_ms_remaining, triggered_grace_ms]
			if state_name == "triggered":
				current_text += " (active)"
			elif grace_ms_remaining > 0:
				current_text += " (counting down)"
			else:
				current_text += " (idle)"
			passed = state_name != "triggered" or grace_ms_remaining > 0
		"rearm_status":
			if state_name == "not_ready":
				current_text = "%d/%dms elapsed (pose-only timer)" % [transition_age_ms, pose_only_rearm_ms]
				passed = transition_age_ms >= pose_only_rearm_ms
			elif state_name == "ready":
				current_text = "pose-only timer satisfied -> ready"
				passed = true
			else:
				current_text = "waiting for pose-only rearm timer"
				passed = state_name == "tracking_lost" or state_name == "triggered"
		"reacquire_progress":
			current_text = "%s / %dms required" % ["tracked" if pose_tracking_valid else "waiting", reacquire_stable_ms_required]
			passed = pose_tracking_valid
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
	var hook_config: Dictionary = gesture_document.get("hook", {}) if gesture_document.get("hook", {}) is Dictionary else {}
	var hook_eval: Dictionary = hook_config.get("evaluation", {}) if hook_config.get("evaluation", {}) is Dictionary else {}
	var hook_thresholds: Dictionary = hook_config.get("thresholds", {}) if hook_config.get("thresholds", {}) is Dictionary else {}
	var hook_timing: Dictionary = hook_config.get("timing", {}) if hook_config.get("timing", {}) is Dictionary else {}
	var hook_rearm: Dictionary = hook_config.get("rearm", {}) if hook_config.get("rearm", {}) is Dictionary else {}
	var hook_state_machine: Dictionary = hook_config.get("state_machine", {}) if hook_config.get("state_machine", {}) is Dictionary else {}
	var uppercut_config: Dictionary = gesture_document.get("uppercut", {}) if gesture_document.get("uppercut", {}) is Dictionary else {}
	var uppercut_eval: Dictionary = uppercut_config.get("evaluation", {}) if uppercut_config.get("evaluation", {}) is Dictionary else {}
	var uppercut_thresholds: Dictionary = uppercut_config.get("thresholds", {}) if uppercut_config.get("thresholds", {}) is Dictionary else {}
	var uppercut_timing: Dictionary = uppercut_config.get("timing", {}) if uppercut_config.get("timing", {}) is Dictionary else {}
	var uppercut_rearm: Dictionary = uppercut_config.get("rearm", {}) if uppercut_config.get("rearm", {}) is Dictionary else {}
	var uppercut_state_machine: Dictionary = uppercut_config.get("state_machine", {}) if uppercut_config.get("state_machine", {}) is Dictionary else {}

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
	lines.append("Hand tracking enabled: %s" % _fmt_bool(bool(hands_config.get("enabled", false))))
	lines.append("Hand reacquire stable window: %dms" % int(hand_validity.get("reacquire_stable_ms", 0)))
	lines.append("Hand grace/stale window: %dms" % int(hand_validity.get("max_stale_ms", 0)))

	lines.append("")
	lines.append("Straight-punch tuning")
	lines.append("---------------------")
	lines.append("Enabled: %s" % _fmt_bool(bool(straight_config.get("enabled", false))))
	lines.append("Fresh samples only: %s" % _fmt_bool(bool(straight_eval.get("fresh_samples_only", true))))
	lines.append("Sample window size: %d" % int(straight_eval.get("sample_window_size", 0)))
	lines.append("Motion window: %dms" % int(straight_eval.get("window_ms", 0)))
	lines.append("Positive growth samples: %d" % int(straight_eval.get("min_positive_growth_samples", 0)))
	lines.append("Min velocity: %s" % _fmt_float(straight_thresholds.get("min_velocity", 0.0)))
	lines.append("Min bbox area growth: %s" % _fmt_float(straight_thresholds.get("min_bbox_area_growth", 0.0)))
	lines.append("Max elbow-shoulder XY distance: %s" % _fmt_float(straight_thresholds.get("max_elbow_shoulder_xy_distance", 0.0)))
	lines.append("Triggered grace: %dms" % int(straight_timing.get("triggered_grace_ms", 0)))
	lines.append("BBox retract epsilon: %s" % _fmt_float(straight_rearm.get("bbox_area_retract_epsilon", 0.0)))
	lines.append("Pose-only rearm timer: %dms" % int(straight_rearm.get("pose_only_rearm_ms", 0)))
	lines.append("Straight-punch lost reacquire stable window: %dms" % int(straight_state_machine.get("lost_tracking_reacquire_stable_ms", 0)))

	lines.append("")
	lines.append("Hook tuning")
	lines.append("-----------")
	lines.append("Enabled: %s" % _fmt_bool(bool(hook_config.get("enabled", false))))
	lines.append("Motion window: %dms" % int(hook_eval.get("window_ms", 0)))
	lines.append("Min velocity: %s" % _fmt_float(hook_thresholds.get("min_velocity", hook_thresholds.get("min_punch_velocity", 0.0))))
	lines.append("Min lateral dominance: %s" % _fmt_float(hook_thresholds.get("min_lateral_dominance_ratio", 0.0)))
	lines.append("Min horizontal direction share of total motion: %s" % _fmt_float(hook_thresholds.get("min_horizontal_direction_ratio", 0.0)))
	lines.append("Hook grace / rearm / reacquire: %dms / %dms / %dms" % [
		int(hook_timing.get("triggered_grace_ms", 0)),
		int(hook_rearm.get("pose_only_rearm_ms", 0)),
		int(hook_state_machine.get("lost_tracking_reacquire_stable_ms", 0)),
	])

	lines.append("")
	lines.append("Uppercut tuning")
	lines.append("---------------")
	lines.append("Enabled: %s" % _fmt_bool(bool(uppercut_config.get("enabled", false))))
	lines.append("Motion window: %dms" % int(uppercut_eval.get("window_ms", 0)))
	lines.append("Min velocity: %s" % _fmt_float(uppercut_thresholds.get("min_velocity", uppercut_thresholds.get("min_punch_velocity", 0.0))))
	lines.append("Min vertical dominance: %s" % _fmt_float(uppercut_thresholds.get("min_vertical_dominance_ratio", 0.0)))
	lines.append("Min upward direction share of total motion: %s" % _fmt_float(uppercut_thresholds.get("min_upward_direction_ratio", 0.0)))
	lines.append("Uppercut grace / rearm / reacquire: %dms / %dms / %dms" % [
		int(uppercut_timing.get("triggered_grace_ms", 0)),
		int(uppercut_rearm.get("pose_only_rearm_ms", 0)),
		int(uppercut_state_machine.get("lost_tracking_reacquire_stable_ms", 0)),
	])

	var punch_detection_debug: Dictionary = (_latest_state.get("gesture_debug", {}) as Dictionary).get("punch_detection", {}) if ((_latest_state.get("gesture_debug", {}) as Dictionary).get("punch_detection", {}) is Dictionary) else {}
	var prototype_matcher_debug: Dictionary = (_latest_state.get("gesture_debug", {}) as Dictionary).get("prototype_matcher", {}) if ((_latest_state.get("gesture_debug", {}) as Dictionary).get("prototype_matcher", {}) is Dictionary) else {}
	var learned_classifier_debug: Dictionary = (_latest_state.get("gesture_debug", {}) as Dictionary).get("learned_classifier", {}) if ((_latest_state.get("gesture_debug", {}) as Dictionary).get("learned_classifier", {}) is Dictionary) else {}
	var active_backend := String(punch_detection_debug.get("active_backend", punch_detection_debug.get("backend", "threshold_gates")))
	var selected_backend := String(punch_detection_debug.get("selected_backend", "threshold_gates"))
	var classifier_backend := active_backend if active_backend != "none" else selected_backend
	var classifier_debug := prototype_matcher_debug
	var classifier_title := "Prototype matcher truth"
	var classifier_loaded_label := "Prototype library ID"
	if classifier_backend == "learned_classifier":
		classifier_debug = learned_classifier_debug
		classifier_title = "Learned classifier truth"
		classifier_loaded_label = "Learned model path"
	elif classifier_backend == "threshold_gates":
		classifier_debug = {}
		classifier_title = "Threshold gates truth"
		classifier_loaded_label = "Threshold gates"
	lines.append("")
	lines.append(classifier_title)
	lines.append("-----------------------")
	lines.append("Active backend: %s" % active_backend)
	lines.append("Selected backend: %s" % selected_backend)
	lines.append("Selected backend enabled: %s" % _fmt_bool(bool(punch_detection_debug.get("selected_backend_enabled", active_backend != "none"))))
	lines.append("Backend resolution: %s" % String(punch_detection_debug.get("active_backend_resolution", "selected_backend_active")))
	if classifier_backend != "threshold_gates":
		lines.append("%s: %s (loaded=%s)" % [
			classifier_loaded_label,
			String(classifier_debug.get("library_id", classifier_debug.get("model_path", ""))),
			_fmt_bool(bool(classifier_debug.get("library_loaded", classifier_debug.get("model_loaded", false)))),
		])
	else:
		lines.append("%s: enabled=%s" % [
			classifier_loaded_label,
			_fmt_bool(bool(punch_detection_debug.get("threshold_gates_enabled", true))),
		])
	lines.append("Best class / score / threshold: %s / %s / %s" % [
		String(classifier_debug.get("best_class", "no_punch")),
		_fmt_float(classifier_debug.get("best_score", 0.0)),
		_fmt_float(classifier_debug.get("required_score", classifier_debug.get("match_score_min", 0.0))),
	])
	lines.append("Result class / emitted event: %s / %s" % [
		String(classifier_debug.get("result_class", "no_punch")),
		String(classifier_debug.get("emitted_event_name", "none")) if not String(classifier_debug.get("emitted_event_name", "")).is_empty() else "none",
	])
	lines.append("Debug flags: show_scores=%s show_event_gate_state=%s" % [
		_fmt_bool(bool(classifier_debug.get("show_scores", false))),
		_fmt_bool(bool(classifier_debug.get("show_event_gate_state", false))),
	])
	if bool(classifier_debug.get("show_scores", false)):
		lines.append("Class scores: %s" % _fmt_matcher_class_scores(classifier_debug.get("class_scores", {}) as Dictionary))
	else:
		lines.append("Class scores: hidden (show_scores=false)")
	if bool(classifier_debug.get("show_event_gate_state", false)):
		var gate_reason := String(classifier_debug.get("reason", "idle"))
		var model_error := String(classifier_debug.get("model_error", ""))
		if classifier_backend == "learned_classifier" and not model_error.is_empty():
			gate_reason += " (%s)" % model_error
		lines.append("Gate reason / hold / cooldown / active event: %s / %dms / %dms / %s" % [
			gate_reason,
			int(classifier_debug.get("hold_ms_remaining", 0)),
			int(classifier_debug.get("cooldown_ms_remaining", 0)),
			String(classifier_debug.get("active_event_class", "no_punch")),
		])
	else:
		lines.append("Gate reason / hold / cooldown / active event: hidden (show_event_gate_state=false)")

	var guard_config: Dictionary = gesture_document.get("guard", {}) if gesture_document.get("guard", {}) is Dictionary else {}
	var guard_thresholds: Dictionary = guard_config.get("thresholds", {}) if guard_config.get("thresholds", {}) is Dictionary else {}
	var guard_debug: Dictionary = (_latest_state.get("gesture_debug", {}) as Dictionary).get("guard", {}) if ((_latest_state.get("gesture_debug", {}) as Dictionary).get("guard", {}) is Dictionary) else {}
	lines.append("")
	lines.append("Guard tuning")
	lines.append("------------")
	lines.append("Enabled: %s" % _fmt_bool(bool(guard_config.get("enabled", true))))
	lines.append("Wrist separation X <= %s" % _fmt_float(guard_thresholds.get("max_wrist_separation_x", 0.0)))
	lines.append("Wrist separation Y <= %s" % _fmt_float(guard_thresholds.get("max_wrist_separation_y", 0.0)))
	lines.append("Wrist nose distance <= %s" % _fmt_float(guard_thresholds.get("max_wrist_nose_distance", 0.0)))
	lines.append("Guard candidate: %s" % _fmt_bool(bool(guard_debug.get("candidate", false))))
	lines.append("Live wrist separation: x=%s y=%s" % [_fmt_float(guard_debug.get("wrist_separation_x", 0.0)), _fmt_float(guard_debug.get("wrist_separation_y", 0.0))])
	lines.append("Wrists above elbows: L=%s R=%s" % [_fmt_bool(bool(guard_debug.get("left_wrist_above_elbow", false))), _fmt_bool(bool(guard_debug.get("right_wrist_above_elbow", false)))])
	lines.append("Wrist-to-nose distances: L=%s R=%s" % [_fmt_float(guard_debug.get("left_wrist_nose_distance", 0.0)), _fmt_float(guard_debug.get("right_wrist_nose_distance", 0.0))])

	var squat_config: Dictionary = gesture_document.get("squat", {}) if gesture_document.get("squat", {}) is Dictionary else {}
	var squat_thresholds: Dictionary = squat_config.get("thresholds", {}) if squat_config.get("thresholds", {}) is Dictionary else {}
	var squat_debug: Dictionary = (_latest_state.get("gesture_debug", {}) as Dictionary).get("squat", {}) if ((_latest_state.get("gesture_debug", {}) as Dictionary).get("squat", {}) is Dictionary) else {}
	lines.append("")
	lines.append("Squat tuning")
	lines.append("------------")
	lines.append("Enabled: %s" % _fmt_bool(bool(squat_config.get("enabled", true))))
	lines.append("Enter height ratio <= %s" % _fmt_float(squat_thresholds.get("enter_height_ratio_max", 0.0)))
	lines.append("Exit height ratio >= %s" % _fmt_float(squat_thresholds.get("exit_height_ratio_min", 0.0)))
	lines.append("Current state: %s" % ("active" if bool(squat_debug.get("state", false)) else "inactive"))
	lines.append("Calibration ready / frames: %s / %d" % [_fmt_bool(bool(squat_debug.get("calibration_ready", false))), int(squat_debug.get("calibration_sample_frames", 0))])
	lines.append("Live height ratio: %s (%s)" % [_fmt_float(squat_debug.get("height_ratio", 1.0)), String(squat_debug.get("height_state", "unknown"))])
	lines.append("Squat depth: %s" % _fmt_float(squat_debug.get("squat_depth", 0.0)))
	lines.append("Torso height live / baseline: %s / %s" % [_fmt_float(squat_debug.get("torso_height", 0.0)), _fmt_float(squat_debug.get("baseline_torso_height", 0.0))])

	var weave_config: Dictionary = gesture_document.get("weave", {}) if gesture_document.get("weave", {}) is Dictionary else {}
	var weave_thresholds: Dictionary = weave_config.get("thresholds", {}) if weave_config.get("thresholds", {}) is Dictionary else {}
	var weave_debug: Dictionary = (_latest_state.get("gesture_debug", {}) as Dictionary).get("weave", {}) if ((_latest_state.get("gesture_debug", {}) as Dictionary).get("weave", {}) is Dictionary) else {}
	lines.append("")
	lines.append("Weave tuning")
	lines.append("------------")
	lines.append("Enabled: %s" % _fmt_bool(bool(weave_config.get("enabled", true))))
	lines.append("Enter head lateral offset >= %s" % _fmt_float(weave_thresholds.get("enter_head_lateral_offset_min", 0.0)))
	lines.append("Enter head-vs-hip offset >= %s" % _fmt_float(weave_thresholds.get("enter_relative_head_hip_offset_min", 0.0)))
	lines.append("Enter head drop ratio >= %s" % _fmt_float(weave_thresholds.get("enter_head_drop_ratio_min", 0.0)))
	lines.append("Exit head lateral offset <= %s" % _fmt_float(weave_thresholds.get("exit_head_lateral_offset_max", 0.0)))
	lines.append("Exit head-vs-hip offset <= %s" % _fmt_float(weave_thresholds.get("exit_relative_head_hip_offset_max", 0.0)))
	lines.append("Current state: %s" % String(weave_debug.get("state", "inactive")))
	lines.append("Candidates: left=%s right=%s neutral=%s" % [
		_fmt_bool(bool(weave_debug.get("left_candidate", false))),
		_fmt_bool(bool(weave_debug.get("right_candidate", false))),
		_fmt_bool(bool(weave_debug.get("neutral_candidate", false))),
	])
	lines.append("Live offsets: head=%s hip=%s relative=%s" % [
		_fmt_float(weave_debug.get("head_lateral_offset", 0.0)),
		_fmt_float(weave_debug.get("hip_lateral_offset", 0.0)),
		_fmt_float(weave_debug.get("relative_head_hip_offset", 0.0)),
	])
	lines.append("Head drop ratio: %s (ready=%s)" % [
		_fmt_float(weave_debug.get("head_drop_ratio", 0.0)),
		_fmt_bool(bool(weave_debug.get("head_drop_ready", false))),
	])

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
	_apply_runtime_gesture_backend_override(config)
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
	var hook_debug: Dictionary = (gesture_debug.get("hook", {}) as Dictionary)
	var uppercut_debug: Dictionary = (gesture_debug.get("uppercut", {}) as Dictionary)
	var side_debug: Dictionary = (straight_punch_debug.get(side, {}) as Dictionary)
	var hook_side_debug: Dictionary = (hook_debug.get(side, {}) as Dictionary)
	var uppercut_side_debug: Dictionary = (uppercut_debug.get(side, {}) as Dictionary)
	var hand_tracking_enabled := bool(side_debug.get("hand_tracking_enabled", true))
	var state_name := String(side_debug.get("state", side_debug.get("phase", hand.get("tracking_state", "tracking_lost"))))
	var bbox: Dictionary = hand.get("bbox", {}) if hand.get("bbox", {}) is Dictionary else {}
	var tracking_state := String(hand.get("tracking_state", side_debug.get("tracking_state", "idle")))
	var tracking_valid := bool(hand.get("tracking_valid", side_debug.get("tracking_valid", false)))
	var sample_source := String(hand.get("sample_source", side_debug.get("sample_source", "none")))
	var hand_grace_ms := int(hand.get("grace_ms", 0))
	var hand_stable_ms := int(hand.get("stable_ms", 0))
	var stale_ms := int(hand.get("stale_ms", 0))
	if not hand_tracking_enabled:
		tracking_state = String(side_debug.get("tracking_state", tracking_state))
		tracking_valid = bool(side_debug.get("pose_tracking_valid", tracking_valid))
		sample_source = String(side_debug.get("sample_source", "pose"))
		bbox = {}
		hand_grace_ms = 0
		hand_stable_ms = 0
		stale_ms = 0
	return "%s: state=%s tracking=%s valid=%s source=%s wrist_xyz_vel=%s wrist_forward_vel=%s depth_spike=%s elbow_shoulder_xy=%s<=%s(%s) bbox_area=%s bbox_growth=%s grace=%dms hook=%s/%s dir=%s uppercut=%s/%s dir=%s hand_grace=%dms hand_stable=%dms stale=%dms" % [
		"L" if side == "left" else "R",
		state_name,
		tracking_state,
		_fmt_bool(tracking_valid),
		sample_source,
		_fmt_float(side_debug.get("wrist_velocity", 0.0)),
		_fmt_float(side_debug.get("wrist_forward_velocity", 0.0)),
		_fmt_float(side_debug.get("recent_peak_forward_depth_spike", side_debug.get("forward_depth_spike", 0.0))),
		_fmt_float(side_debug.get("elbow_shoulder_xy_distance", 0.0)),
		_fmt_float(side_debug.get("max_elbow_shoulder_xy_distance", 0.0)),
		_fmt_bool(bool(side_debug.get("elbow_shoulder_xy_gate_passed", false))),
		_fmt_float(bbox.get("area", side_debug.get("bbox_area", 0.0))),
		_fmt_float(side_debug.get("bbox_area_growth", 0.0)),
		int(side_debug.get("grace_ms_remaining", 0)),
		String(hook_side_debug.get("state", "tracking_lost")),
		_fmt_float(hook_side_debug.get("horizontal_direction_velocity", hook_side_debug.get("outward_velocity", 0.0))),
		_fmt_float(hook_side_debug.get("directionality_ratio", 0.0)),
		String(uppercut_side_debug.get("state", "tracking_lost")),
		_fmt_float(uppercut_side_debug.get("upward_velocity", 0.0)),
		_fmt_float(uppercut_side_debug.get("directionality_ratio", 0.0)),
		hand_grace_ms,
		hand_stable_ms,
		stale_ms,
	]

func _fmt_playback_status(playback: Dictionary) -> String:
	if playback.is_empty():
		return "live"
	var playing := bool(playback.get("playing", false))
	var playback_position := float(playback.get("position_seconds", playback.get("position_sec", 0.0)))
	var duration := float(playback.get("duration_seconds", playback.get("duration_sec", 0.0)))
	return "%s %s/%s" % [
		"playing" if playing else "paused",
		_fmt_duration(playback_position),
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

func _fmt_threshold_comparison_value(value: float, threshold: float, _at_most: bool = false) -> String:
	var rounded_value := _fmt_float(value)
	if rounded_value == _fmt_float(threshold) and not is_equal_approx(value, threshold):
		return "%.6f" % value
	return rounded_value

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
