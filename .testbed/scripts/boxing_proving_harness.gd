extends "res://scripts/proving_harness.gd"

const DepthDebugViewerScript = preload("res://scripts/depth_debug_viewer.gd")

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
	"guard": "res://assets/icons/boxing-guard-1.svg",
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
	"guard_start": "Guard Activated",
	"guard_end": "Guard Deactivated",
	"squat_start": "Squat Activated",
	"squat_end": "Squat Deactivated",
	"weave_left_start": "Weave Left",
	"weave_left_end": "Weave Left Ended",
	"weave_right_start": "Weave Right",
	"weave_right_end": "Weave Right Ended",
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
		"id": "guard",
		"label": "Guard",
		"icon": BOARD_ICON_PATHS["guard"],
		"mode": "state_center",
		"states": ["guard"],
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
		"id": "wrist_lateral_angle",
		"label": "Wrist lateral angle from elbow vertical >= {threshold}°",
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
		"label": "Alignment gate",
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
		"id": "current_cell",
		"label": "Nose occupied cell",
		"row_kind": "info",
	},
	{
		"id": "nose_tracked",
		"label": "Nose tracked",
		"row_kind": "info",
	},
	{
		"id": "obstacle_section",
		"label": "Top-row obstacle",
		"row_kind": "section",
	},
	{
		"id": "occupied_rows",
		"label": "Blocked rows",
		"row_kind": "info",
	},
	{
		"id": "occupied_cells",
		"label": "Blocked cells",
		"row_kind": "info",
	},
	{
		"id": "nose_in_blocked_region",
		"label": "Nose in blocked region",
		"row_kind": "info",
	},
	{
		"id": "avoidance_section",
		"label": "Avoidance truth",
		"row_kind": "section",
	},
	{
		"id": "avoidance_clear",
		"label": "Obstacle avoided",
		"row_kind": "info",
	},
	{
		"id": "calibration_ready",
		"label": "Calibration ready",
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
		"id": "current_cell",
		"label": "Nose occupied cell",
		"row_kind": "info",
	},
	{
		"id": "nose_tracked",
		"label": "Nose tracked",
		"row_kind": "info",
	},
	{
		"id": "left_section",
		"label": "Left-side obstacle",
		"row_kind": "section",
	},
	{
		"id": "left_occupied_columns",
		"label": "Blocked columns",
		"row_kind": "info",
	},
	{
		"id": "left_occupied_cells",
		"label": "Blocked cells",
		"row_kind": "info",
	},
	{
		"id": "left_avoidance_clear",
		"label": "Left obstacle avoided",
		"row_kind": "info",
	},
	{
		"id": "right_section",
		"label": "Right-side obstacle",
		"row_kind": "section",
	},
	{
		"id": "right_occupied_columns",
		"label": "Blocked columns",
		"row_kind": "info",
	},
	{
		"id": "right_occupied_cells",
		"label": "Blocked cells",
		"row_kind": "info",
	},
	{
		"id": "right_avoidance_clear",
		"label": "Right obstacle avoided",
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

@onready var hand_bbox_drawer: Control = find_child("HandBBoxDrawer", true, false) as Control

var _background_rect: TextureRect
var _header_icon: TextureRect
var _board_panel: PanelContainer
var _board_grid: GridContainer
var _shared_grid_card_panels: Array[PanelContainer] = []
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
var _depth_debug_viewer: Control
var _depth_debug_visual_config := {
	"enabled": false,
	"thumbnail_visible": false,
	"swap_click_enabled": false,
	"hover_hint_visible": false,
	"sampling_regions_visible": false,
	"fps_visible": false,
	"request_runtime_texture": false,
	"thumbnail_corner": "bottom_right",
	"thumbnail_width_px": 196,
	"thumbnail_margin_px": 14,
}
var _smoothed_preview_fps := 0.0

func _ready() -> void:
	_selected_profile_id = _default_profile_id()
	_resolve_boxing_shell_nodes()
	_build_tile_grid_if_needed()
	_apply_boxing_visual_shell()
	super._ready()
	_ensure_depth_debug_ui()
	_refresh_profile_controls()
	_refresh_debug_panels()

func _process(delta: float) -> void:
	if delta > 0.0:
		var instant_fps := 1.0 / delta
		_smoothed_preview_fps = instant_fps if _smoothed_preview_fps <= 0.0 else lerpf(_smoothed_preview_fps, instant_fps, 0.18)
	super._process(delta)

func _notification(what: int) -> void:
	super._notification(what)
	if what == NOTIFICATION_EXIT_TREE or what == NOTIFICATION_PREDELETE:
		_cleanup_depth_debug_ui()

func _cleanup_depth_debug_ui() -> void:
	if _depth_debug_viewer != null and is_instance_valid(_depth_debug_viewer):
		if _depth_debug_viewer.get_parent() != null:
			_depth_debug_viewer.reparent(self)
		_depth_debug_viewer.queue_free()
	_depth_debug_viewer = null

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
	_refresh_depth_debug_visuals()
	if live_status_label:
		live_status_label.text = _build_boxing_live_line()
	if quick_stats_label:
		quick_stats_label.text = _build_boxing_event_feed_text()
		if _boxing_event_feed_autoscroll_pending and quick_stats_label.has_method("scroll_to_line"):
			quick_stats_label.scroll_to_line(0)
		_boxing_event_feed_autoscroll_pending = false
	_refresh_shared_flow_grid_truth_surfaces()
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

func _ensure_depth_debug_ui() -> void:
	if _depth_debug_viewer != null:
		return
	_depth_debug_viewer = DepthDebugViewerScript.new()
	_depth_debug_viewer.name = "DepthDebugRoot"
	_depth_debug_viewer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_depth_debug_viewer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var initial_parent: Node = camera_display if camera_display != null else self
	initial_parent.add_child(_depth_debug_viewer)
	_sync_depth_debug_overlay_parent()
	_refresh_depth_debug_visuals()

func _sync_depth_debug_overlay_parent() -> void:
	if _depth_debug_viewer == null:
		return
	if _depth_debug_viewer.has_method("set_preview_presenter"):
		_depth_debug_viewer.set_preview_presenter(_preview_presenter)

func _toggle_depth_debug_swap() -> void:
	if _depth_debug_viewer == null or not _depth_debug_viewer.has_method("toggle_swap"):
		return
	_depth_debug_viewer.toggle_swap()

func _depth_debug_can_swap(texture_available: bool) -> bool:
	if _depth_debug_viewer == null or not _depth_debug_viewer.has_method("can_swap"):
		return false
	return bool(_depth_debug_viewer.can_swap(texture_available))

func _refresh_depth_debug_visuals() -> void:
	if _depth_debug_viewer == null:
		return
	_sync_depth_debug_overlay_parent()
	var snapshot := _build_depth_debug_visual_snapshot()
	if _depth_debug_viewer.has_method("configure"):
		_depth_debug_viewer.configure(_depth_debug_visual_config, snapshot, _smoothed_preview_fps, _preview_presenter)
	elif _depth_debug_viewer.has_method("set_visual_config"):
		_depth_debug_viewer.set_visual_config(_depth_debug_visual_config)
		_depth_debug_viewer.set_snapshot(snapshot)
		_depth_debug_viewer.set_preview_fps(_smoothed_preview_fps)
		_depth_debug_viewer.set_preview_presenter(_preview_presenter)
		_depth_debug_viewer.refresh()

func _build_depth_debug_visual_snapshot() -> Dictionary:
	var focus_family := _depth_debug_focus_family()
	var runtime_debug := _current_depth_runtime_debug_state(focus_family)
	var sample_metrics: Dictionary = runtime_debug.get("last_sample_metrics", {}) if runtime_debug.get("last_sample_metrics", {}) is Dictionary else {}
	var sample_geometry: Dictionary = sample_metrics.get("sample_geometry", {}) if sample_metrics.get("sample_geometry", {}) is Dictionary else {}
	return {
		"family": focus_family,
		"preview_texture": _depth_debug_preview_texture(),
		"depth_texture": _depth_texture_from_runtime_debug(runtime_debug),
		"runtime_status": String(runtime_debug.get("runtime_status", "unloaded")),
		"runtime_stage": String(runtime_debug.get("runtime_stage", "idle")),
		"active_model_summary": String(runtime_debug.get("active_model_summary", "")),
		"failure_code": String(runtime_debug.get("failure_code", "")),
		"failure_message": String(runtime_debug.get("failure_message", "")),
		"frame_size": runtime_debug.get("frame_size", Vector2i.ZERO),
		"depth_map_size": runtime_debug.get("depth_map_size", Vector2i.ZERO),
		"timing_ms": (runtime_debug.get("last_timing_ms", {}) as Dictionary).duplicate(true),
		"sample_every_n_frames": int(runtime_debug.get("sample_every_n_frames", 1)),
		"max_sample_age_ms": int(runtime_debug.get("max_sample_age_ms", 0)),
		"last_sample_age_ms": int(runtime_debug.get("last_sample_age_ms", -1)),
		"sample_metrics": sample_metrics,
		"sample_geometry": sample_geometry,
	}

func _depth_debug_preview_texture() -> Texture2D:
	if _preview_presenter != null and is_instance_valid(_preview_presenter) and _preview_presenter.has_method("get_preview_surface"):
		var preview_surface: Variant = _preview_presenter.get_preview_surface()
		if preview_surface is TextureRect and preview_surface.texture != null:
			return preview_surface.texture
	if camera_view != null:
		return camera_view.texture
	return null

func _depth_debug_focus_family() -> String:
	var enabled_families: Array = _depth_debug_enabled_families()
	var candidate_families: Array = enabled_families if not enabled_families.is_empty() else ["straight_punch", "hook", "uppercut"]
	var best_family := String(candidate_families[0])
	var best_score: Array[int] = [-1, -1, -1, -1]
	for family: String in candidate_families:
		var runtime_debug := _current_depth_runtime_debug_state(family)
		var sample_metrics: Dictionary = runtime_debug.get("last_sample_metrics", {}) if runtime_debug.get("last_sample_metrics", {}) is Dictionary else {}
		var score: Array[int] = [
			1 if _depth_runtime_debug_has_texture(runtime_debug) else 0,
			1 if not sample_metrics.is_empty() else 0,
			1 if String(runtime_debug.get("runtime_status", "unloaded")) == "ready" else 0,
			int(runtime_debug.get("last_sample_timestamp_ms", -1)),
		]
		if _depth_debug_family_score_beats(score, best_score):
			best_score = score
			best_family = family
	return best_family

func _depth_debug_family_score_beats(score: Array[int], best_score: Array[int]) -> bool:
	var compare_len := mini(score.size(), best_score.size())
	for index in range(compare_len):
		if score[index] == best_score[index]:
			continue
		return score[index] > best_score[index]
	return false

func _depth_runtime_debug_has_texture(runtime_debug: Dictionary) -> bool:
	return _depth_texture_from_runtime_debug(runtime_debug) != null

func _depth_texture_from_runtime_debug(runtime_debug: Dictionary) -> Texture2D:
	var source: Variant = runtime_debug.get("normalized_depth_map", null)
	if source is Texture2D:
		return source
	if source is Image:
		return ImageTexture.create_from_image(source)
	return null

func _depth_debug_enabled_families() -> Array:
	var families: Array = []
	for family: String in ["straight_punch", "hook", "uppercut"]:
		if bool(_punch_depth_profile_config(family).get("enabled", false)):
			families.append(family)
	return families

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
	_shared_grid_card_panels = []
	for node_name: String in ["NosePlacementCard", "LeftPlacementCard", "RightPlacementCard"]:
		var panel := find_child(node_name, true, false) as PanelContainer
		if panel != null:
			_shared_grid_card_panels.append(panel)

func _default_profile_id() -> String:
	return PROFILE_BOXING

func _refresh_profile_controls() -> void:
	var bundle := _current_profile_bundle()
	_sync_profile_visual_config(bundle)

func _sync_depth_debug_visual_config(visuals: Dictionary) -> void:
	var depth_debug: Dictionary = visuals.get("depth_debug", {}) if visuals.get("depth_debug", {}) is Dictionary else {}
	var any_depth_family_enabled := not _depth_debug_enabled_families().is_empty()
	_depth_debug_visual_config = {
		"enabled": bool(depth_debug.get("enabled", false)),
		"thumbnail_visible": bool(depth_debug.get("thumbnail_visible", false)) and any_depth_family_enabled,
		"swap_click_enabled": bool(depth_debug.get("swap_click_enabled", false)) and any_depth_family_enabled,
		"hover_hint_visible": bool(depth_debug.get("hover_hint_visible", false)) and any_depth_family_enabled,
		"sampling_regions_visible": bool(depth_debug.get("sampling_regions_visible", false)) and any_depth_family_enabled,
		"fps_visible": bool(depth_debug.get("fps_visible", false)),
		"request_runtime_texture": bool(depth_debug.get("request_runtime_texture", false)),
		"thumbnail_corner": String(depth_debug.get("thumbnail_corner", "bottom_right")).strip_edges().to_lower(),
		"thumbnail_width_px": maxi(120, int(depth_debug.get("thumbnail_width_px", 196))),
		"thumbnail_margin_px": maxi(0, int(depth_debug.get("thumbnail_margin_px", 14))),
	}
	_refresh_depth_debug_visuals()

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
	_sync_depth_debug_visual_config(visuals)

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

func _current_gesture_profile_document() -> Dictionary:
	var bundle := _current_profile_bundle()
	return bundle.get("gesture_detection", {}) if bundle.get("gesture_detection", {}) is Dictionary else {}

func _gesture_family_document(gesture_document: Dictionary, family: String) -> Dictionary:
	return gesture_document.get(family, {}) if gesture_document.get(family, {}) is Dictionary else {}

func _gesture_family_backend_document(gesture_document: Dictionary, family: String, backend_name: String) -> Dictionary:
	var family_document := _gesture_family_document(gesture_document, family)
	var backend_document: Dictionary = family_document.get(backend_name, {}) if family_document.get(backend_name, {}) is Dictionary else {}
	if not backend_document.is_empty():
		return backend_document
	return family_document

func _punch_threshold_profile_config(family: String) -> Dictionary:
	return _gesture_family_backend_document(_current_gesture_profile_document(), family, "threshold")

func _punch_depth_profile_config(family: String) -> Dictionary:
	var threshold_config := _punch_threshold_profile_config(family)
	return threshold_config.get("depth", {}) if threshold_config.get("depth", {}) is Dictionary else {}

func _depth_threshold_label(family: String, field_name: String) -> String:
	if family == "straight_punch":
		if field_name == "closeness_delta":
			return "min_closeness_delta"
		return "min_peak_closeness"
	if field_name == "closeness_delta":
		return "max_closeness_delta"
	return "max_peak_closeness"

func _depth_threshold_direction_label(family: String) -> String:
	return "min" if family == "straight_punch" else "max"

func _compact_depth_model_label(depth_config: Dictionary) -> String:
	var model_document: Dictionary = depth_config.get("model", {}) if depth_config.get("model", {}) is Dictionary else {}
	var configured_path := String(model_document.get("artifact_path", "")).strip_edges()
	if configured_path.is_empty():
		return "configured"
	var normalized_path := configured_path
	while normalized_path.ends_with("/"):
		normalized_path = normalized_path.left(normalized_path.length() - 1)
	var basename := normalized_path.get_file().strip_edges()
	if basename.is_empty():
		return "configured"
	return basename

func _compact_depth_backend_label(depth_config: Dictionary, runtime_debug: Dictionary) -> String:
	if depth_config.is_empty():
		return "missing"
	if not bool(depth_config.get("enabled", false)):
		return "disabled"
	var backend_id := String(runtime_debug.get("backend_id", "")).strip_edges()
	var family_id := String(runtime_debug.get("family_id", "")).strip_edges()
	if not backend_id.is_empty() and not family_id.is_empty():
		return "%s / %s" % [backend_id, family_id]
	if not family_id.is_empty():
		return family_id
	if not backend_id.is_empty():
		return backend_id
	return "configured / %s" % _compact_depth_model_label(depth_config)

func _depth_threshold_compact_text(family: String, field_name: String, thresholds: Dictionary) -> String:
	var key := _depth_threshold_label(family, field_name)
	if thresholds.is_empty() or not thresholds.has(key):
		return "missing"
	return "%s %s" % [_depth_threshold_direction_label(family), _fmt_float(thresholds.get(key, 0.0))]

func _depth_config_runtime_status_text(depth_config: Dictionary) -> String:
	if depth_config.is_empty():
		return "not present in selected gesture YAML"
	return "enabled in selected gesture YAML" if bool(depth_config.get("enabled", false)) else "disabled in selected gesture YAML"

func _current_depth_runtime_debug_state(family: String, live_depth_state: Dictionary = {}) -> Dictionary:
	var latest_state := _boxing_latest_state_snapshot()
	var gesture_debug: Dictionary = (latest_state.get("gesture_debug", {}) as Dictionary)
	var depth_runtime: Dictionary = (gesture_debug.get("depth_runtime", {}) as Dictionary)
	var family_runtime: Dictionary = (depth_runtime.get(family, {}) as Dictionary)
	if not family_runtime.is_empty():
		return family_runtime.duplicate(true)
	if live_depth_state.is_empty():
		return {}
	return {
		"depth_enabled": bool(live_depth_state.get("depth_enabled", false)),
		"artifact_path_res": String(live_depth_state.get("depth_artifact_path", "")),
		"backend_id": String(live_depth_state.get("depth_backend_id", "unknown")),
		"family_id": String(live_depth_state.get("depth_family_id", "unknown")),
		"runtime_status": String(live_depth_state.get("depth_runtime_status", "unloaded")),
		"runtime_stage": String(live_depth_state.get("depth_runtime_stage", "idle")),
		"failure_code": String(live_depth_state.get("depth_failure_code", "")),
		"failure_message": String(live_depth_state.get("depth_failure_message", "")),
		"active_model_summary": String(live_depth_state.get("depth_active_model_summary", "")),
		"last_sample_metrics": (live_depth_state.get("depth_sample_metrics", {}) as Dictionary).duplicate(true),
	}

func _family_side_depth_debug_state(family: String, side: String) -> Dictionary:
	var latest_state := _boxing_latest_state_snapshot()
	var gesture_debug: Dictionary = (latest_state.get("gesture_debug", {}) as Dictionary)
	var family_debug: Dictionary = (gesture_debug.get(family, {}) as Dictionary)
	return ((family_debug.get(side, {}) as Dictionary)).duplicate(true)

func _depth_loader_truth_text(depth_config: Dictionary, runtime_debug: Dictionary) -> String:
	if runtime_debug.is_empty():
		return _depth_config_runtime_status_text(depth_config)
	var summary := String(runtime_debug.get("active_model_summary", "")).strip_edges()
	if not summary.is_empty():
		return summary
	return "%s; runtime status is %s" % [
		_depth_config_runtime_status_text(depth_config),
		String(runtime_debug.get("runtime_status", "unloaded")),
	]

func _depth_artifact_path_text(depth_config: Dictionary, runtime_debug: Dictionary) -> String:
	var runtime_path := _pretty_resource_path(String(runtime_debug.get("artifact_path_res", "")).strip_edges())
	if not runtime_path.is_empty():
		return runtime_path
	var model_document: Dictionary = depth_config.get("model", {}) if depth_config.get("model", {}) is Dictionary else {}
	var configured_path := _pretty_resource_path(String(model_document.get("artifact_path", "")).strip_edges())
	if configured_path.is_empty():
		return "missing in selected gesture YAML"
	return "%s (configured; runtime unresolved)" % configured_path

func _depth_backend_family_text(runtime_debug: Dictionary) -> String:
	return "%s / %s" % [
		String(runtime_debug.get("backend_id", "unknown")),
		String(runtime_debug.get("family_id", "unknown")),
	]

func _depth_failure_reason_text(runtime_debug: Dictionary) -> String:
	var failure_code := String(runtime_debug.get("failure_code", "")).strip_edges()
	var failure_message := String(runtime_debug.get("failure_message", "")).strip_edges()
	if failure_code.is_empty() and failure_message.is_empty():
		return "none"
	if failure_code.is_empty():
		return failure_message
	if failure_message.is_empty():
		return failure_code
	return "%s - %s" % [failure_code, failure_message]

func _depth_live_metrics_text(live_depth_state: Dictionary) -> String:
	if live_depth_state.is_empty():
		return "no live family depth state yet"
	var sample_metrics: Dictionary = (live_depth_state.get("depth_sample_metrics", {}) as Dictionary)
	var sample_source := String(live_depth_state.get("depth_signal_source", sample_metrics.get("sample_source", "none"))).strip_edges()
	if sample_source.is_empty():
		sample_source = "none"
	var parts := [
		"available=%s" % _fmt_bool(bool(live_depth_state.get("depth_signal_available", false))),
		"fresh=%s" % _fmt_bool(bool(live_depth_state.get("depth_signal_fresh", false))),
		"source=%s" % sample_source,
		"closeness=%s" % _fmt_float(live_depth_state.get("last_depth_closeness", 0.0)),
		"delta=%s" % _fmt_float(live_depth_state.get("depth_closeness_delta", 0.0)),
		"peak=%s" % _fmt_float(live_depth_state.get("depth_peak_closeness", 0.0)),
		"early=%s" % _fmt_float(live_depth_state.get("depth_early_closeness", 0.0)),
		"late=%s" % _fmt_float(live_depth_state.get("depth_late_closeness", 0.0)),
		"span=%dms" % int(live_depth_state.get("depth_window_span_ms", 0)),
		"gate=%s/%s(%s)" % [
			_fmt_bool(bool(live_depth_state.get("depth_gate_applied", false))),
			_fmt_bool(bool(live_depth_state.get("depth_gate_passed", false))),
			String(live_depth_state.get("depth_gate_reason", "staged_or_unavailable")),
		],
	]
	if not sample_metrics.is_empty():
		parts.append("wrist_depth=%s" % _fmt_float(sample_metrics.get("wrist_depth", 0.0)))
		parts.append("torso_depth=%s" % _fmt_float(sample_metrics.get("torso_depth", 0.0)))
	return ", ".join(parts)

func _build_depth_config_row(row_spec: Dictionary, family: String, live_depth_state: Dictionary = {}) -> Dictionary:
	var row := row_spec.duplicate(true)
	var row_id := String(row.get("id", ""))
	var depth_config := _punch_depth_profile_config(family)
	var thresholds: Dictionary = depth_config.get("thresholds", {}) if depth_config.get("thresholds", {}) is Dictionary else {}
	var runtime_debug := _current_depth_runtime_debug_state(family, live_depth_state)
	var current_text := ""
	match row_id:
		"depth_section":
			current_text = ""
		"depth_backend_family":
			current_text = _compact_depth_backend_label(depth_config, runtime_debug)
		"depth_family_delta_threshold":
			current_text = _depth_threshold_compact_text(family, "closeness_delta", thresholds)
		"depth_family_peak_threshold":
			current_text = _depth_threshold_compact_text(family, "peak_closeness", thresholds)
		_:
			current_text = "pending"
	row["current_text"] = current_text
	row["passed"] = false
	return row

func _append_depth_config_summary_lines(lines: Array, family: String, depth_config: Dictionary) -> void:
	var runtime_debug := _current_depth_runtime_debug_state(family)
	var left_debug := _family_side_depth_debug_state(family, "left")
	var right_debug := _family_side_depth_debug_state(family, "right")
	lines.append("Depth loader truth: %s" % _depth_loader_truth_text(depth_config, runtime_debug))
	if not runtime_debug.is_empty():
		lines.append("Depth runtime status / stage: %s / %s" % [
			String(runtime_debug.get("runtime_status", "unloaded")),
			String(runtime_debug.get("runtime_stage", "idle")),
		])
		lines.append("Depth artifact path: %s" % _depth_artifact_path_text(depth_config, runtime_debug))
		lines.append("Depth backend/family: %s" % _depth_backend_family_text(runtime_debug))
		var failure_reason := _depth_failure_reason_text(runtime_debug)
		if failure_reason != "none":
			lines.append("Depth failure reason: %s" % failure_reason)
	lines.append("Depth enabled: %s" % _fmt_bool(bool(depth_config.get("enabled", false))))
	if not left_debug.is_empty():
		lines.append("Depth live metrics (L): %s" % _depth_live_metrics_text(left_debug))
	if not right_debug.is_empty():
		lines.append("Depth live metrics (R): %s" % _depth_live_metrics_text(right_debug))
	if depth_config.is_empty():
		return
	var evaluation: Dictionary = depth_config.get("evaluation", {}) if depth_config.get("evaluation", {}) is Dictionary else {}
	var thresholds: Dictionary = depth_config.get("thresholds", {}) if depth_config.get("thresholds", {}) is Dictionary else {}
	var debug_config: Dictionary = depth_config.get("debug", {}) if depth_config.get("debug", {}) is Dictionary else {}
	var delta_key := _depth_threshold_label(family, "closeness_delta")
	var peak_key := _depth_threshold_label(family, "peak_closeness")
	lines.append("Depth window slices / input: %s / %s @ %dpx" % [
		_fmt_float(evaluation.get("early_window_fraction", 0.0)),
		_fmt_float(evaluation.get("late_window_fraction", 0.0)),
		int(evaluation.get("model_input_size", 0)),
	])
	lines.append("Depth ROI sizes (wrist / extend / torso): %dpx / %dpx / %dpx" % [
		int(evaluation.get("wrist_roi_radius_px", 0)),
		int(evaluation.get("wrist_to_elbow_extension_px", 0)),
		int(evaluation.get("torso_roi_radius_px", 0)),
	])
	lines.append("Depth smoothing window samples: %d" % int(evaluation.get("smoothing_window_samples", 0)))
	lines.append("Depth thresholds: %s=%s, %s=%s" % [
		delta_key,
		_fmt_float(thresholds.get(delta_key, 0.0)),
		peak_key,
		_fmt_float(thresholds.get(peak_key, 0.0)),
	])
	lines.append("Depth debug flags: show_depth_signal=%s show_depth_window_analysis=%s" % [
		_fmt_bool(bool(debug_config.get("show_depth_signal", false))),
		_fmt_bool(bool(debug_config.get("show_depth_window_analysis", false))),
	])

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
	if grid_truth_label:
		grid_truth_label.add_theme_font_size_override("normal_font_size", 15)
		grid_truth_label.add_theme_color_override("default_color", Color(0.97, 0.98, 1.0, 1.0))
		grid_truth_label.scroll_active = false
		grid_truth_label.fit_content = true
	if grid_truth_label and grid_truth_label.get_parent() is PanelContainer:
		grid_truth_label.get_parent().custom_minimum_size = Vector2(0, 224)
		_apply_panel_style(grid_truth_label.get_parent(), Color(0.20, 0.21, 0.24, 0.90), Color(1.0, 1.0, 1.0, 0.08), 14, 1, 12)
	if _board_panel:
		_apply_panel_style(_board_panel, Color(0.25, 0.38, 0.53, 0.56), Color(1.0, 1.0, 1.0, 0.26), 28, 1, 18)
	if _board_grid:
		_board_grid.columns = 3
		_board_grid.add_theme_constant_override("h_separation", 10)
		_board_grid.add_theme_constant_override("v_separation", 10)
	for panel: PanelContainer in _shared_grid_card_panels:
		panel.custom_minimum_size = Vector2(132, 158)
		_apply_panel_style(panel, Color(0.22, 0.78, 0.88, 0.10), Color(0.60, 1.0, 1.0, 0.30), 18, 1, 0)
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
			return _build_punch_hover_card_model(spec, "left")
		"punch_right":
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

func _merged_punch_debug_state(side: String) -> Dictionary:
	var latest_state := _boxing_latest_state_snapshot()
	var gesture_debug: Dictionary = (latest_state.get("gesture_debug", {}) as Dictionary)
	var straight_punch_debug: Dictionary = (gesture_debug.get("straight_punch", {}) as Dictionary)
	var straight_side: Dictionary = ((straight_punch_debug.get(side, {}) as Dictionary)).duplicate(true)
	var transition_debug_source := _paused_straight_punch_transition_debug if _paused_boxing_state_active else _straight_punch_transition_debug
	var transition_debug: Dictionary = ((transition_debug_source.get(side, {}) as Dictionary)).duplicate(true)
	if straight_side.is_empty():
		return transition_debug
	for key_variant: Variant in transition_debug.keys():
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
		"footer": spec.get("footer", "Live values come from the calibrated nose-grid top-row avoidance detector."),
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
		"footer": spec.get("footer", "Live values come from the calibrated nose-grid side-obstacle avoidance detector."),
	}

func _boxing_reference_time_ms() -> int:
	return _paused_boxing_snapshot_time_ms if _paused_boxing_state_active else Time.get_ticks_msec()

func _build_squat_requirement_row(row_spec: Dictionary, squat_debug: Dictionary) -> Dictionary:
	var row := row_spec.duplicate(true)
	var row_id := String(row_spec.get("id", ""))
	var passed := false
	var current_text := ""
	match row_id:
		"state_section", "obstacle_section", "avoidance_section":
			current_text = ""
		"current_state":
			passed = bool(squat_debug.get("state", false))
			current_text = "active" if passed else "inactive"
		"current_cell":
			current_text = _fmt_flow_cell(int(squat_debug.get("current_cell", -1)))
			passed = int(squat_debug.get("current_cell", -1)) >= 0
		"nose_tracked":
			passed = bool(squat_debug.get("nose_tracked", false))
			current_text = _fmt_bool(passed)
		"occupied_rows":
			current_text = _fmt_int_list(squat_debug.get("occupied_rows", []))
			passed = true
		"occupied_cells":
			current_text = _fmt_int_list(squat_debug.get("occupied_cells", []))
			passed = true
		"nose_in_blocked_region":
			passed = not bool(squat_debug.get("nose_in_blocked_region", false))
			current_text = _fmt_bool(bool(squat_debug.get("nose_in_blocked_region", false)))
		"avoidance_clear":
			passed = bool(squat_debug.get("avoidance_clear", false))
			current_text = _fmt_bool(passed)
		"calibration_ready":
			passed = bool(squat_debug.get("calibration_ready", false))
			current_text = _fmt_bool(passed)
		_:
			current_text = String(squat_debug.get(row_id, ""))
	row["threshold_text"] = ""
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
	var left_obstacle := _weave_obstacle_debug(weave_debug, "left_obstacle")
	var right_obstacle := _weave_obstacle_debug(weave_debug, "right_obstacle")
	match row_id:
		"state_section", "left_section", "right_section":
			current_text = ""
		"current_state":
			current_text = String(weave_debug.get("state", "inactive"))
			passed = current_text != "inactive"
		"current_cell":
			current_text = _fmt_flow_cell(int(weave_debug.get("current_cell", -1)))
			passed = int(weave_debug.get("current_cell", -1)) >= 0
		"nose_tracked":
			passed = bool(weave_debug.get("nose_tracked", false))
			current_text = _fmt_bool(passed)
		"left_occupied_columns":
			current_text = _fmt_int_list(left_obstacle.get("occupied_columns", []))
			passed = true
		"left_occupied_cells":
			current_text = _fmt_int_list(left_obstacle.get("occupied_cells", []))
			passed = true
		"left_avoidance_clear":
			passed = bool(left_obstacle.get("avoidance_clear", false))
			current_text = _fmt_bool(passed)
		"right_occupied_columns":
			current_text = _fmt_int_list(right_obstacle.get("occupied_columns", []))
			passed = true
		"right_occupied_cells":
			current_text = _fmt_int_list(right_obstacle.get("occupied_cells", []))
			passed = true
		"right_avoidance_clear":
			passed = bool(right_obstacle.get("avoidance_clear", false))
			current_text = _fmt_bool(passed)
		_:
			current_text = "pending"
			passed = false
	row["label"] = label
	row["passed"] = passed
	row["threshold_text"] = ""
	row["current_text"] = current_text
	return row

func _weave_obstacle_debug(weave_debug: Dictionary, key: String) -> Dictionary:
	return weave_debug.get(key, {}) if weave_debug.get(key, {}) is Dictionary else {}

func _fmt_int_list(values_variant: Variant) -> String:
	if not values_variant is Array or (values_variant as Array).is_empty():
		return "-"
	var parts: Array[String] = []
	for value_variant: Variant in (values_variant as Array):
		parts.append(str(int(value_variant)))
	return ", ".join(parts)

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

func _build_punch_requirement_row(row_spec: Dictionary, straight_side: Dictionary, _side: String) -> Dictionary:
	var row_id := String(row_spec.get("id", ""))
	if row_id.begins_with("depth_"):
		return _build_depth_config_row(row_spec, "straight_punch", straight_side)
	var row := row_spec.duplicate(true)
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
	var elbow_shoulder_xy_distance := float(straight_side.get("elbow_shoulder_xy_distance", 0.0))
	var max_elbow_shoulder_xy_distance := float(straight_side.get("max_elbow_shoulder_xy_distance", 0.0))
	var elbow_shoulder_xy_gate_passed := bool(straight_side.get("elbow_shoulder_xy_gate_passed", false))
	var wrist_lateral_angle := float(straight_side.get("wrist_lateral_angle_from_elbow_vertical_deg", 0.0))
	var min_wrist_lateral_angle := float(straight_side.get("min_wrist_lateral_angle_from_elbow_vertical_deg", 0.0))
	var wrist_lateral_angle_gate_passed := bool(straight_side.get("wrist_lateral_angle_gate_passed", false))
	var pose_reference_shoulder_width := float(straight_side.get("pose_reference_shoulder_width", 0.0))
	var pose_reference_shoulder_width_source := String(straight_side.get("pose_reference_shoulder_width_source", "missing"))
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
	var pose_only_rearm_ms := int(straight_side.get("pose_only_rearm_ms", 0))
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
			else:
				current_text = "pose_valid=%s, tracking=%s, source=%s, shoulder_width=%s (%s)" % [
					_fmt_bool(pose_tracking_valid),
					tracking_state,
					sample_source,
					_fmt_float(pose_reference_shoulder_width),
					pose_reference_shoulder_width_source,
				]
			passed = pose_tracking_valid if not hand_tracking_enabled else tracking_valid
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
			current_text = "state=%s wrist=%s peak=%s xy=%s<=%s (%s) angle=%s>=%s (%s) fresh=%s source=%s grace=%dms pose_valid=%s" % [
				state_name,
				_fmt_float(wrist_velocity),
				_fmt_float(recent_peak_wrist_velocity),
				_fmt_float(elbow_shoulder_xy_distance),
				_fmt_float(max_elbow_shoulder_xy_distance),
				_fmt_bool(elbow_shoulder_xy_gate_passed),
				_fmt_float(wrist_lateral_angle),
				_fmt_float(min_wrist_lateral_angle),
				_fmt_bool(wrist_lateral_angle_gate_passed),
				_fmt_bool(fresh_sample),
				sample_source,
				grace_ms_remaining,
				_fmt_bool(pose_tracking_valid),
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
		"wrist_lateral_angle":
			threshold_text = _fmt_float(min_wrist_lateral_angle)
			passed = wrist_lateral_angle_gate_passed
			current_text = _fmt_threshold_comparison_value(wrist_lateral_angle, min_wrist_lateral_angle)
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
	var row_id := String(row_spec.get("id", ""))
	if row_id.begins_with("depth_"):
		return _build_depth_config_row(row_spec, family, side_debug)
	var row := row_spec.duplicate(true)
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
	var hook_alignment_angle := float(side_debug.get("wrist_angle_from_elbow_horizontal_deg", 0.0))
	var hook_max_alignment_angle := float(side_debug.get("max_wrist_angle_from_elbow_horizontal_deg", 0.0))
	var hook_side_gate_passed := bool(side_debug.get("wrist_on_required_hook_side", false))
	var uppercut_alignment_angle := float(side_debug.get("wrist_angle_from_elbow_vertical_deg", 0.0))
	var uppercut_max_alignment_angle := float(side_debug.get("max_wrist_angle_from_elbow_vertical_deg", 0.0))
	var uppercut_above_elbow_gate_passed := bool(side_debug.get("wrist_above_elbow_gate_passed", false))
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
			if family == "hook":
				threshold_text = _fmt_float(hook_max_alignment_angle)
				current_text = _fmt_float(hook_alignment_angle)
				passed = bool(side_debug.get("wrist_horizontal_angle_gate_passed", false))
				label = "Wrist angle from elbow horizontal ray <= {threshold}°"
			else:
				threshold_text = _fmt_float(uppercut_max_alignment_angle)
				current_text = _fmt_float(uppercut_alignment_angle)
				passed = bool(side_debug.get("wrist_vertical_angle_gate_passed", false))
				label = "Wrist angle from elbow vertical ray <= {threshold}°"
		"directionality_ratio":
			threshold_text = _fmt_bool(true)
			if family == "hook":
				var required_hook_side_label := String(side_debug.get("required_hook_side_label", ""))
				current_text = _fmt_bool(hook_side_gate_passed)
				if not required_hook_side_label.is_empty():
					current_text += " (%s)" % required_hook_side_label
				passed = hook_side_gate_passed
				label = "Preview-space wrist stays on required mirrored hook side"
			else:
				current_text = _fmt_bool(uppercut_above_elbow_gate_passed)
				passed = uppercut_above_elbow_gate_passed
				label = "Preview-space wrist stays above elbow"
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
	var straight_family: Dictionary = _gesture_family_document(gesture_document, "straight_punch")
	var straight_config: Dictionary = _gesture_family_backend_document(gesture_document, "straight_punch", "threshold")
	var straight_eval: Dictionary = straight_config.get("evaluation", {}) if straight_config.get("evaluation", {}) is Dictionary else {}
	var straight_thresholds: Dictionary = straight_config.get("thresholds", {}) if straight_config.get("thresholds", {}) is Dictionary else {}
	var straight_timing: Dictionary = straight_config.get("timing", {}) if straight_config.get("timing", {}) is Dictionary else {}
	var straight_rearm: Dictionary = straight_config.get("rearm", {}) if straight_config.get("rearm", {}) is Dictionary else {}
	var straight_state_machine: Dictionary = straight_config.get("state_machine", {}) if straight_config.get("state_machine", {}) is Dictionary else {}
	var straight_depth: Dictionary = straight_config.get("depth", {}) if straight_config.get("depth", {}) is Dictionary else {}
	var hook_family: Dictionary = _gesture_family_document(gesture_document, "hook")
	var hook_config: Dictionary = _gesture_family_backend_document(gesture_document, "hook", "threshold")
	var hook_eval: Dictionary = hook_config.get("evaluation", {}) if hook_config.get("evaluation", {}) is Dictionary else {}
	var hook_thresholds: Dictionary = hook_config.get("thresholds", {}) if hook_config.get("thresholds", {}) is Dictionary else {}
	var hook_timing: Dictionary = hook_config.get("timing", {}) if hook_config.get("timing", {}) is Dictionary else {}
	var hook_rearm: Dictionary = hook_config.get("rearm", {}) if hook_config.get("rearm", {}) is Dictionary else {}
	var hook_state_machine: Dictionary = hook_config.get("state_machine", {}) if hook_config.get("state_machine", {}) is Dictionary else {}
	var hook_depth: Dictionary = hook_config.get("depth", {}) if hook_config.get("depth", {}) is Dictionary else {}
	var uppercut_family: Dictionary = _gesture_family_document(gesture_document, "uppercut")
	var uppercut_config: Dictionary = _gesture_family_backend_document(gesture_document, "uppercut", "threshold")
	var uppercut_eval: Dictionary = uppercut_config.get("evaluation", {}) if uppercut_config.get("evaluation", {}) is Dictionary else {}
	var uppercut_thresholds: Dictionary = uppercut_config.get("thresholds", {}) if uppercut_config.get("thresholds", {}) is Dictionary else {}
	var uppercut_timing: Dictionary = uppercut_config.get("timing", {}) if uppercut_config.get("timing", {}) is Dictionary else {}
	var uppercut_rearm: Dictionary = uppercut_config.get("rearm", {}) if uppercut_config.get("rearm", {}) is Dictionary else {}
	var uppercut_state_machine: Dictionary = uppercut_config.get("state_machine", {}) if uppercut_config.get("state_machine", {}) is Dictionary else {}
	var uppercut_depth: Dictionary = uppercut_config.get("depth", {}) if uppercut_config.get("depth", {}) is Dictionary else {}

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
	lines.append("Threshold backend selected: %s" % _fmt_bool(String(straight_family.get("backend", "threshold")).strip_edges().to_lower() == "threshold"))
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
	_append_depth_config_summary_lines(lines, "straight_punch", straight_depth)

	lines.append("")
	lines.append("Hook tuning")
	lines.append("-----------")
	lines.append("Threshold backend selected: %s" % _fmt_bool(String(hook_family.get("backend", "threshold")).strip_edges().to_lower() == "threshold"))
	lines.append("Motion window: %dms" % int(hook_eval.get("window_ms", 0)))
	lines.append("Min velocity: %s" % _fmt_float(hook_thresholds.get("min_velocity", hook_thresholds.get("min_punch_velocity", 0.0))))
	lines.append("Max wrist angle from elbow horizontal ray: %s" % _fmt_float(hook_thresholds.get("max_wrist_angle_from_elbow_horizontal_deg", 0.0)))
	lines.append("Hook wrist must stay on mirrored preview-space side of elbow: left hook = left_of_elbow, right hook = right_of_elbow")
	lines.append("Hook grace / rearm / reacquire: %dms / %dms / %dms" % [
		int(hook_timing.get("triggered_grace_ms", 0)),
		int(hook_rearm.get("pose_only_rearm_ms", 0)),
		int(hook_state_machine.get("lost_tracking_reacquire_stable_ms", 0)),
	])
	_append_depth_config_summary_lines(lines, "hook", hook_depth)

	lines.append("")
	lines.append("Uppercut tuning")
	lines.append("---------------")
	lines.append("Threshold backend selected: %s" % _fmt_bool(String(uppercut_family.get("backend", "threshold")).strip_edges().to_lower() == "threshold"))
	lines.append("Motion window: %dms" % int(uppercut_eval.get("window_ms", 0)))
	lines.append("Min velocity: %s" % _fmt_float(uppercut_thresholds.get("min_velocity", uppercut_thresholds.get("min_punch_velocity", 0.0))))
	lines.append("Max wrist angle from elbow vertical ray: %s" % _fmt_float(uppercut_thresholds.get("max_wrist_angle_from_elbow_vertical_deg", 0.0)))
	lines.append("Uppercut wrist must stay above elbow in preview space: yes")
	lines.append("Uppercut grace / rearm / reacquire: %dms / %dms / %dms" % [
		int(uppercut_timing.get("triggered_grace_ms", 0)),
		int(uppercut_rearm.get("pose_only_rearm_ms", 0)),
		int(uppercut_state_machine.get("lost_tracking_reacquire_stable_ms", 0)),
	])
	_append_depth_config_summary_lines(lines, "uppercut", uppercut_depth)

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
	var squat_avoidance: Dictionary = squat_config.get("grid_avoidance", {}) if squat_config.get("grid_avoidance", {}) is Dictionary else {}
	var squat_obstacle: Dictionary = squat_avoidance.get("obstacle", {}) if squat_avoidance.get("obstacle", {}) is Dictionary else {}
	var squat_debug: Dictionary = (_latest_state.get("gesture_debug", {}) as Dictionary).get("squat", {}) if ((_latest_state.get("gesture_debug", {}) as Dictionary).get("squat", {}) is Dictionary) else {}
	lines.append("")
	lines.append("Squat avoidance")
	lines.append("---------------")
	lines.append("Enabled: %s" % _fmt_bool(bool(squat_config.get("enabled", true))))
	lines.append("Backend: %s" % String(squat_debug.get("backend", squat_config.get("backend", "grid_avoidance"))))
	lines.append("Blocked rows: %s" % _fmt_int_list(squat_obstacle.get("occupied_rows", squat_debug.get("occupied_rows", []))))
	lines.append("Blocked cells: %s" % _fmt_int_list(squat_obstacle.get("occupied_cells", squat_debug.get("occupied_cells", []))))
	lines.append("Current state: %s" % ("active" if bool(squat_debug.get("state", false)) else "inactive"))
	lines.append("Nose cell: %s" % _fmt_flow_cell(int(squat_debug.get("current_cell", -1))))
	lines.append("Nose in blocked region: %s" % _fmt_bool(bool(squat_debug.get("nose_in_blocked_region", false))))
	lines.append("Obstacle avoided: %s" % _fmt_bool(bool(squat_debug.get("avoidance_clear", false))))

	var weave_config: Dictionary = gesture_document.get("weave", {}) if gesture_document.get("weave", {}) is Dictionary else {}
	var weave_avoidance: Dictionary = weave_config.get("grid_avoidance", {}) if weave_config.get("grid_avoidance", {}) is Dictionary else {}
	var left_weave_obstacle: Dictionary = weave_avoidance.get("left_obstacle", {}) if weave_avoidance.get("left_obstacle", {}) is Dictionary else {}
	var right_weave_obstacle: Dictionary = weave_avoidance.get("right_obstacle", {}) if weave_avoidance.get("right_obstacle", {}) is Dictionary else {}
	var weave_debug: Dictionary = (_latest_state.get("gesture_debug", {}) as Dictionary).get("weave", {}) if ((_latest_state.get("gesture_debug", {}) as Dictionary).get("weave", {}) is Dictionary) else {}
	var left_live: Dictionary = _weave_obstacle_debug(weave_debug, "left_obstacle")
	var right_live: Dictionary = _weave_obstacle_debug(weave_debug, "right_obstacle")
	lines.append("")
	lines.append("Weave avoidance")
	lines.append("---------------")
	lines.append("Enabled: %s" % _fmt_bool(bool(weave_config.get("enabled", true))))
	lines.append("Backend: %s" % String(weave_debug.get("backend", weave_config.get("backend", "grid_avoidance"))))
	lines.append("Current state: %s" % String(weave_debug.get("state", "inactive")))
	lines.append("Nose cell: %s" % _fmt_flow_cell(int(weave_debug.get("current_cell", -1))))
	lines.append("Left obstacle columns / cells: %s / %s" % [_fmt_int_list(left_weave_obstacle.get("occupied_columns", left_live.get("occupied_columns", []))), _fmt_int_list(left_weave_obstacle.get("occupied_cells", left_live.get("occupied_cells", [])))])
	lines.append("Left obstacle avoided: %s" % _fmt_bool(bool(left_live.get("avoidance_clear", false))))
	lines.append("Right obstacle columns / cells: %s / %s" % [_fmt_int_list(right_weave_obstacle.get("occupied_columns", right_live.get("occupied_columns", []))), _fmt_int_list(right_weave_obstacle.get("occupied_cells", right_live.get("occupied_cells", [])))])
	lines.append("Right obstacle avoided: %s" % _fmt_bool(bool(right_live.get("avoidance_clear", false))))

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
