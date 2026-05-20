extends "res://scripts/proving_harness.gd"

const BACKGROUND_TEXTURE_PATH := "res://assets/backgrounds/perfect-hue-may-08-2026-hd.png"
const HEADER_ICON_PATH := "res://assets/icons/boxing-glove-1.svg"
const TILE_PULSE_MS := 420
const MAX_BOXING_FEED_ROWS := 8
const ACTIVE_PILL_FILL := Color8(0x3d, 0xdc, 0xdc, 0xff)
const ACTIVE_PILL_TEXT := Color8(0x05, 0x22, 0x28, 0xff)
const HOVER_CARD_TITLE := "What Gesture Requirements Are Met Right Now?"
const HOVER_CARD_MAX_WIDTH := 360.0
const HOVER_CARD_MARGIN := 14.0
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
const HOVER_REQUIREMENT_SPECS := {
	"punch": {
		"title": "Punch-L",
		"subtitle": "Live Punch-L detector/debug values from the current proving-scene state.",
		"rows": [
			{
				"id": "left_phase_armed",
				"label": "L-Punch phase is armed",
				"group": "phase",
			},
			{
				"id": "left_side_of_screen",
				"label": "L-Hand is on left side of screen",
				"group": "lane",
			},
			{
				"id": "left_arm_extension",
				"label": "L-Arm extension is >= 0.95",
				"group": "shape",
			},
			{
				"id": "left_elbow_bend",
				"label": "L-Elbow bend is >= 145°",
				"group": "shape",
			},
			{
				"id": "left_forward_velocity",
				"label": "L-Forward velocity >= {threshold}",
				"group": "speed",
			},
			{
				"id": "left_forward_distance",
				"label": "L-Forward distance >= {threshold}",
				"group": "distance",
			},
		],
		"footer": "",
	},
}

var _background_rect: TextureRect
var _header_icon: TextureRect
var _board_panel: PanelContainer
var _board_grid: GridContainer
var _boxing_event_feed: Array[String] = []
var _boxing_event_sequence := 0
var _tile_refs := {}
var _hovered_tile_id := ""
var _hover_card_panel: PanelContainer
var _hover_card_gesture_label: Label
var _hover_card_subtitle_label: Label
var _hover_card_rows: VBoxContainer
var _hover_card_footer_label: Label

func _ready() -> void:
	_resolve_boxing_shell_nodes()
	_build_tile_grid_if_needed()
	_ensure_hover_card()
	_apply_boxing_visual_shell()
	super._ready()
	_refresh_debug_panels()

func _refresh_debug_panels() -> void:
	if harness_mode != HarnessMode.BOXING:
		super._refresh_debug_panels()
		return
	if title_label:
		title_label.text = scene_title if not scene_title.is_empty() else "BOXING GESTURE DETECTION"
	if notes_label:
		notes_label.visible = false
	if live_status_label:
		live_status_label.text = _build_boxing_live_line()
	if quick_stats_label:
		quick_stats_label.text = _build_boxing_event_feed_text()
		if quick_stats_label.has_method("scroll_to_line"):
			quick_stats_label.scroll_to_line(max(quick_stats_label.get_line_count() - 1, 0))
	_update_tile_states()
	_refresh_hover_card()

func _record_event(event_name: String, payload: Dictionary) -> void:
	if harness_mode == HarnessMode.BOXING:
		if UI_EVENT_LABELS.has(event_name):
			_boxing_event_sequence += 1
			_boxing_event_feed.append("%04d: %s" % [_boxing_event_sequence, String(UI_EVENT_LABELS[event_name])])
			while _boxing_event_feed.size() > MAX_BOXING_FEED_ROWS:
				_boxing_event_feed.remove_at(0)
	super._record_event(event_name, payload)

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
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_top", 14)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_bottom", 14)
	_hover_card_panel.add_child(margin)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 8)
	margin.add_child(column)

	var title := Label.new()
	title.text = HOVER_CARD_TITLE
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title.add_theme_font_size_override("font_size", 15)
	title.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 1.0))
	column.add_child(title)

	_hover_card_gesture_label = Label.new()
	_hover_card_gesture_label.add_theme_font_size_override("font_size", 13)
	_hover_card_gesture_label.add_theme_color_override("font_color", Color(0.80, 0.90, 1.0, 0.92))
	column.add_child(_hover_card_gesture_label)

	_hover_card_subtitle_label = Label.new()
	_hover_card_subtitle_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_hover_card_subtitle_label.add_theme_font_size_override("font_size", 11)
	_hover_card_subtitle_label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 0.72))
	column.add_child(_hover_card_subtitle_label)

	_hover_card_rows = VBoxContainer.new()
	_hover_card_rows.add_theme_constant_override("separation", 6)
	column.add_child(_hover_card_rows)

	_hover_card_footer_label = Label.new()
	_hover_card_footer_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_hover_card_footer_label.add_theme_font_size_override("font_size", 10)
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
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	_apply_panel_style(panel, Color(1.0, 1.0, 1.0, 0.0), Color(1.0, 1.0, 1.0, 0.0), 0, 0, 0)

	var tile_id := String(config.get("id", ""))
	if tile_id != "":
		panel.mouse_entered.connect(_on_tile_mouse_entered.bind(tile_id))
		panel.mouse_exited.connect(_on_tile_mouse_exited.bind(tile_id))

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

	var mode := String(config.get("mode", "pulse_lr"))
	center_badge["panel"].visible = mode == "state_center"
	left_badge["panel"].visible = mode != "state_center"
	right_badge["panel"].visible = mode != "state_center"

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
	}

func _create_badge(text: String, wide: bool = false) -> Dictionary:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(68 if wide else 34, 34)
	_apply_panel_style(panel, Color(0.16, 0.20, 0.28, 0.20), Color(1.0, 1.0, 1.0, 0.70), 18, 1, 0)
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 13 if wide else 14)
	label.add_theme_color_override("font_color", Color(0.96, 0.97, 1.0, 1.0))
	panel.add_child(label)
	return {"panel": panel, "label": label}

func _refresh_hover_card() -> void:
	if _hovered_tile_id.is_empty():
		if _hover_card_panel:
			_hover_card_panel.visible = false
		return
	if _hover_card_panel == null:
		return
	var model := _build_hover_card_model(_hovered_tile_id)
	_hover_card_panel.visible = not model.is_empty()
	if model.is_empty():
		return
	_hover_card_gesture_label.text = String(model.get("title", String(_hovered_tile_id).capitalize()))
	_hover_card_subtitle_label.text = String(model.get("subtitle", ""))
	_hover_card_subtitle_label.visible = not _hover_card_subtitle_label.text.is_empty()
	_hover_card_footer_label.text = String(model.get("footer", ""))
	_hover_card_footer_label.visible = not _hover_card_footer_label.text.is_empty()
	_rebuild_hover_card_rows(model.get("rows", []))
	_position_hover_card(_hovered_tile_id)

func _build_hover_card_model(tile_id: String) -> Dictionary:
	var spec: Dictionary = HOVER_REQUIREMENT_SPECS.get(tile_id, {})
	if spec.is_empty():
		return {
			"title": String(tile_id).capitalize(),
			"subtitle": "Reusable hover-card shell is ready for this gesture.",
			"rows": [
				{
					"id": "%s_pending" % tile_id,
					"label": "Requirement list pending",
					"passed": false,
					"current_text": "Task 3 hookup still needed",
				},
			],
		}
	match tile_id:
		"punch":
			return _build_punch_hover_card_model(spec)
		_:
			return spec.duplicate(true)

func _build_punch_hover_card_model(spec: Dictionary) -> Dictionary:
	var gesture_debug: Dictionary = (_latest_state.get("gesture_debug", {}) as Dictionary)
	var straight_punch_debug: Dictionary = (gesture_debug.get("straight_punch", {}) as Dictionary)
	var left_straight: Dictionary = (straight_punch_debug.get("left", {}) as Dictionary)
	var rows: Array[Dictionary] = []
	for row_spec_variant: Variant in spec.get("rows", []):
		var row_spec: Dictionary = row_spec_variant
		rows.append(_build_punch_left_requirement_row(row_spec, left_straight))
	return {
		"title": spec.get("title", "Punch-L"),
		"subtitle": spec.get("subtitle", ""),
		"rows": rows,
		"footer": spec.get("footer", ""),
	}

func _build_punch_left_requirement_row(row_spec: Dictionary, left_straight: Dictionary) -> Dictionary:
	var row := row_spec.duplicate(true)
	var row_id := String(row_spec.get("id", ""))
	var label := String(row_spec.get("label", ""))
	var passed := false
	var current_text := ""
	var threshold_text := ""
	var suspect_text := ""
	match row_id:
		"left_phase_armed":
			current_text = String(left_straight.get("phase", "recovering"))
			passed = current_text == "armed"
		"left_side_of_screen":
			var own_half_lock := bool(left_straight.get("own_half_lock", false))
			current_text = _fmt_bool(own_half_lock)
			passed = own_half_lock
		"left_arm_extension":
			var arm_extension := float(left_straight.get("arm_extension_3d", 0.0))
			current_text = _fmt_float(arm_extension)
			passed = arm_extension >= float(left_straight.get("arm_extension_min", 0.95))
		"left_elbow_bend":
			var elbow_bend := float(left_straight.get("elbow_bend_deg_3d", 0.0))
			current_text = _fmt_degrees_int(elbow_bend)
			passed = elbow_bend >= float(left_straight.get("elbow_bend_deg_min", 145.0))
		"left_forward_velocity":
			var velocity_threshold := float(left_straight.get("forward_velocity_min", 0.0))
			var forward_velocity := float(left_straight.get("forward_velocity", 0.0))
			threshold_text = _fmt_float(velocity_threshold)
			current_text = _fmt_float(forward_velocity)
			passed = forward_velocity > velocity_threshold
		"left_forward_distance":
			var distance_threshold := float(left_straight.get("forward_distance_min", 0.0))
			var forward_distance := float(left_straight.get("forward_distance", 0.0))
			threshold_text = _fmt_float(distance_threshold)
			current_text = _fmt_float(forward_distance)
			passed = forward_distance >= distance_threshold
		_:
			current_text = "pending"
			passed = false
	row["label"] = label
	row["passed"] = passed
	row["threshold_text"] = threshold_text
	row["current_text"] = current_text
	row["suspect_text"] = suspect_text
	return row

func _rebuild_hover_card_rows(rows_variant: Variant) -> void:
	if _hover_card_rows == null:
		return
	for child: Node in _hover_card_rows.get_children():
		child.queue_free()
	var rows: Array = rows_variant if rows_variant is Array else []
	for row_variant: Variant in rows:
		var row: Dictionary = row_variant
		_hover_card_rows.add_child(_create_requirement_row(row))

func _create_requirement_row(row: Dictionary) -> Control:
	var container := VBoxContainer.new()
	container.add_theme_constant_override("separation", 3)

	var line := HBoxContainer.new()
	line.add_theme_constant_override("separation", 8)
	container.add_child(line)

	var checkbox := Label.new()
	checkbox.text = "🗹" if bool(row.get("passed", false)) else "☐"
	checkbox.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	checkbox.add_theme_font_size_override("font_size", 15)
	checkbox.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 1.0))
	line.add_child(checkbox)

	var text_column := VBoxContainer.new()
	text_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_column.add_theme_constant_override("separation", 2)
	line.add_child(text_column)

	var text_label := Label.new()
	text_label.text = _build_requirement_row_text(row)
	text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_label.add_theme_font_size_override("font_size", 12)
	text_label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 1.0))
	text_column.add_child(text_label)

	var suspect_text := String(row.get("suspect_text", ""))
	if not suspect_text.is_empty():
		var suspect_label := Label.new()
		suspect_label.text = suspect_text
		suspect_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		suspect_label.add_theme_font_size_override("font_size", 10)
		suspect_label.add_theme_color_override("font_color", Color(1.0, 0.82, 0.46, 0.96))
		text_column.add_child(suspect_label)
	return container

func _build_requirement_row_text(row: Dictionary) -> String:
	var label := String(row.get("label", ""))
	var threshold_text := String(row.get("threshold_text", ""))
	if not threshold_text.is_empty():
		label = label.replace("{threshold}", threshold_text)
	var current_text := String(row.get("current_text", ""))
	if current_text.is_empty():
		return label
	return "%s - %s" % [label, current_text]

func _position_hover_card(tile_id: String) -> void:
	if _hover_card_panel == null:
		return
	var tile: Dictionary = _tile_refs.get(tile_id, {})
	var panel := tile.get("panel") as Control
	if panel == null:
		return
	var tile_rect := panel.get_global_rect()
	var popup_size := _hover_card_panel.get_combined_minimum_size()
	var viewport_size := get_viewport_rect().size
	var x := tile_rect.end.x + HOVER_CARD_MARGIN
	var y := tile_rect.position.y
	if x + popup_size.x > viewport_size.x - HOVER_CARD_MARGIN:
		x = tile_rect.position.x - popup_size.x - HOVER_CARD_MARGIN
	if x < HOVER_CARD_MARGIN:
		x = HOVER_CARD_MARGIN
	if y + popup_size.y > viewport_size.y - HOVER_CARD_MARGIN:
		y = maxf(HOVER_CARD_MARGIN, viewport_size.y - popup_size.y - HOVER_CARD_MARGIN)
	_hover_card_panel.position = Vector2(x, y)

func _on_tile_mouse_entered(tile_id: String) -> void:
	_hovered_tile_id = tile_id
	_refresh_hover_card()

func _on_tile_mouse_exited(tile_id: String) -> void:
	if _hovered_tile_id != tile_id:
		return
	_hovered_tile_id = ""
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
	return "\n".join(lines)

func _build_boxing_live_line() -> String:
	var state: Dictionary = _latest_state
	var pose_count := int(provider.get_num_poses()) if provider != null else 0
	var last_event_name := _latest_event_name()
	return "%s • %s • poses %d • last %s" % [
		_camera_source_summary_text(),
		_tracking_status_text(state),
		pose_count,
		String(UI_EVENT_LABELS.get(last_event_name, last_event_name if last_event_name != "" else "none")),
	]

func _compact_status_text(text: String) -> String:
	var compact := text.strip_edges()
	compact = compact.replace("Preview-only debug mode active (provider disabled)", "Preview only")
	compact = compact.replace("Python server started", "Server started")
	compact = compact.replace("MediaPipe runtime missing - installing", "Installing runtime")
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
