extends Control

const DepthSampleDebugOverlayScript = preload("res://scripts/depth_sample_debug_overlay.gd")

signal swap_state_changed(swapped_to_depth: bool)

var visual_config := {
	"enabled": false,
	"thumbnail_visible": false,
	"swap_click_enabled": false,
	"hover_hint_visible": false,
	"sampling_regions_visible": false,
	"fps_visible": false,
	"thumbnail_corner": "bottom_right",
	"thumbnail_width_px": 196,
	"thumbnail_margin_px": 14,
}
var preview_fps := 0.0
var snapshot: Dictionary = {}

var _preview_presenter: Node = null
var _main_texture: TextureRect
var _thumbnail_panel: PanelContainer
var _thumbnail_title_label: Label
var _thumbnail_texture: TextureRect
var _thumbnail_placeholder_label: Label
var _thumbnail_status_label: Label
var _thumbnail_hint_label: Label
var _fps_label: Label
var _sample_overlay: Control

var _thumbnail_hovered := false
var _swapped_to_depth := false
var _last_texture_available := false

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build_ui()
	_refresh_visuals()

func configure(visuals: Dictionary, viewer_snapshot: Dictionary, viewer_preview_fps: float, preview_presenter: Node = null) -> void:
	set_visual_config(visuals)
	set_snapshot(viewer_snapshot)
	set_preview_fps(viewer_preview_fps)
	set_preview_presenter(preview_presenter)
	_refresh_visuals()

func set_visual_config(visuals: Dictionary) -> void:
	visual_config = {
		"enabled": bool(visuals.get("enabled", false)),
		"thumbnail_visible": bool(visuals.get("thumbnail_visible", false)),
		"swap_click_enabled": bool(visuals.get("swap_click_enabled", false)),
		"hover_hint_visible": bool(visuals.get("hover_hint_visible", false)),
		"sampling_regions_visible": bool(visuals.get("sampling_regions_visible", false)),
		"fps_visible": bool(visuals.get("fps_visible", false)),
		"thumbnail_corner": String(visuals.get("thumbnail_corner", "bottom_right")).strip_edges().to_lower(),
		"thumbnail_width_px": maxi(120, int(visuals.get("thumbnail_width_px", 196))),
		"thumbnail_margin_px": maxi(0, int(visuals.get("thumbnail_margin_px", 14))),
	}
	if not _can_swap(_last_texture_available):
		_set_swapped_to_depth(false)
		_thumbnail_hovered = false

func set_snapshot(viewer_snapshot: Dictionary) -> void:
	snapshot = viewer_snapshot.duplicate(true)

func clear_snapshot() -> void:
	snapshot.clear()
	_refresh_visuals()

func set_preview_fps(value: float) -> void:
	preview_fps = maxf(value, 0.0)

func set_preview_presenter(preview_presenter: Node) -> void:
	_preview_presenter = preview_presenter
	_sync_overlay_parent()
	if _sample_overlay != null and _sample_overlay.has_method("set_preview_presenter"):
		_sample_overlay.set_preview_presenter(_preview_presenter)
	queue_redraw()

func refresh() -> void:
	_refresh_visuals()

func toggle_swap() -> void:
	if not _can_swap(_last_texture_available):
		_set_swapped_to_depth(false)
		return
	_set_swapped_to_depth(not _swapped_to_depth)
	_refresh_visuals()

func can_swap(texture_available: bool = _last_texture_available) -> bool:
	return _can_swap(texture_available)

func get_state_snapshot() -> Dictionary:
	return {
		"thumbnail_hovered": _thumbnail_hovered,
		"swapped_to_depth": _swapped_to_depth,
		"last_texture_available": _last_texture_available,
	}

func get_node_refs() -> Dictionary:
	return {
		"root": self,
		"main_texture": _main_texture,
		"thumbnail_panel": _thumbnail_panel,
		"thumbnail_title_label": _thumbnail_title_label,
		"thumbnail_texture": _thumbnail_texture,
		"thumbnail_placeholder_label": _thumbnail_placeholder_label,
		"thumbnail_status_label": _thumbnail_status_label,
		"thumbnail_hint_label": _thumbnail_hint_label,
		"fps_label": _fps_label,
		"sample_overlay": _sample_overlay,
	}

func _build_ui() -> void:
	if _main_texture != null:
		return

	_main_texture = TextureRect.new()
	_main_texture.name = "DepthDebugMainTexture"
	_main_texture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_main_texture.visible = false
	_main_texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_main_texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_main_texture.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_main_texture)

	_sample_overlay = DepthSampleDebugOverlayScript.new()
	_sample_overlay.name = "DepthDebugSampleOverlay"
	_sample_overlay.visible = false
	_sample_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_sample_overlay)

	_fps_label = Label.new()
	_fps_label.name = "DepthDebugFpsLabel"
	_fps_label.visible = false
	_fps_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fps_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_fps_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	_fps_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	_fps_label.add_theme_font_size_override("font_size", 13)
	_fps_label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 0.96))
	_fps_label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.72))
	_fps_label.add_theme_constant_override("shadow_offset_x", 1)
	_fps_label.add_theme_constant_override("shadow_offset_y", 1)
	_fps_label.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	_fps_label.offset_left = -240.0
	_fps_label.offset_top = 10.0
	_fps_label.offset_right = -14.0
	_fps_label.offset_bottom = 56.0
	add_child(_fps_label)

	_thumbnail_panel = PanelContainer.new()
	_thumbnail_panel.name = "DepthDebugThumbnailPanel"
	_thumbnail_panel.visible = false
	_thumbnail_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	_thumbnail_panel.clip_contents = true
	_thumbnail_panel.custom_minimum_size = Vector2(196.0, 172.0)
	_thumbnail_panel.mouse_entered.connect(func() -> void:
		_thumbnail_hovered = true
		_refresh_visuals()
	)
	_thumbnail_panel.mouse_exited.connect(func() -> void:
		_thumbnail_hovered = false
		_refresh_visuals()
	)
	_thumbnail_panel.gui_input.connect(_on_thumbnail_gui_input)
	_apply_panel_style(_thumbnail_panel, Color(0.03, 0.05, 0.08, 0.92), Color(1.0, 1.0, 1.0, 0.18), 16, 1, 0)
	add_child(_thumbnail_panel)

	var margin := MarginContainer.new()
	margin.name = "DepthDebugThumbnailMargin"
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	_thumbnail_panel.add_child(margin)

	var column := VBoxContainer.new()
	column.name = "DepthDebugThumbnailColumn"
	column.add_theme_constant_override("separation", 6)
	margin.add_child(column)

	_thumbnail_title_label = Label.new()
	_thumbnail_title_label.name = "DepthDebugThumbnailTitle"
	_thumbnail_title_label.add_theme_font_size_override("font_size", 13)
	_thumbnail_title_label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 0.96))
	column.add_child(_thumbnail_title_label)

	_thumbnail_texture = TextureRect.new()
	_thumbnail_texture.name = "DepthDebugThumbnailTexture"
	_thumbnail_texture.visible = false
	_thumbnail_texture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_thumbnail_texture.custom_minimum_size = Vector2(196.0, 112.0)
	_thumbnail_texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_thumbnail_texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	column.add_child(_thumbnail_texture)

	_thumbnail_placeholder_label = Label.new()
	_thumbnail_placeholder_label.name = "DepthDebugThumbnailPlaceholder"
	_thumbnail_placeholder_label.visible = false
	_thumbnail_placeholder_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_thumbnail_placeholder_label.custom_minimum_size = Vector2(196.0, 112.0)
	_thumbnail_placeholder_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_thumbnail_placeholder_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_thumbnail_placeholder_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	_thumbnail_placeholder_label.add_theme_font_size_override("font_size", 46)
	_thumbnail_placeholder_label.add_theme_color_override("font_color", Color(1.0, 0.72, 0.72, 0.94))
	column.add_child(_thumbnail_placeholder_label)

	_thumbnail_status_label = Label.new()
	_thumbnail_status_label.name = "DepthDebugThumbnailStatus"
	_thumbnail_status_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_thumbnail_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_thumbnail_status_label.visible = false
	_thumbnail_status_label.add_theme_font_size_override("font_size", 11)
	_thumbnail_status_label.add_theme_color_override("font_color", Color(0.87, 0.92, 0.98, 0.88))
	column.add_child(_thumbnail_status_label)

	_thumbnail_hint_label = Label.new()
	_thumbnail_hint_label.name = "DepthDebugThumbnailHint"
	_thumbnail_hint_label.visible = false
	_thumbnail_hint_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_thumbnail_hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_thumbnail_hint_label.add_theme_font_size_override("font_size", 11)
	_thumbnail_hint_label.add_theme_color_override("font_color", Color(1.0, 0.97, 0.76, 0.96))
	column.add_child(_thumbnail_hint_label)

func _sync_overlay_parent() -> void:
	var overlay_parent := _resolve_overlay_parent()
	if overlay_parent == null:
		return
	var current_parent := get_parent()
	if current_parent != overlay_parent:
		if current_parent != null:
			reparent(overlay_parent)
		else:
			overlay_parent.add_child(self)
		set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

func _resolve_overlay_parent() -> Node:
	if _preview_presenter != null and is_instance_valid(_preview_presenter):
		if _preview_presenter.has_method("get_overlay_layer"):
			var overlay_layer: Variant = _preview_presenter.get_overlay_layer()
			if overlay_layer is Node and is_instance_valid(overlay_layer):
				return overlay_layer
		return _preview_presenter
	return get_parent()

func _on_thumbnail_gui_input(event: InputEvent) -> void:
	if not (event is InputEventMouseButton):
		return
	var mouse_event := event as InputEventMouseButton
	if not mouse_event.pressed or mouse_event.button_index != MOUSE_BUTTON_LEFT:
		return
	if not _can_swap(_last_texture_available):
		return
	accept_event()
	toggle_swap()

func _refresh_visuals() -> void:
	if _main_texture == null:
		return
	_sync_overlay_parent()
	var enabled := bool(visual_config.get("enabled", false))
	visible = enabled
	if not enabled:
		_main_texture.visible = false
		_sample_overlay.visible = false
		_fps_label.visible = false
		_thumbnail_panel.visible = false
		return

	var depth_texture: Texture2D = snapshot.get("depth_texture", null)
	var preview_texture: Texture2D = snapshot.get("preview_texture", null)
	_last_texture_available = depth_texture != null
	if not _can_swap(_last_texture_available):
		_set_swapped_to_depth(false)
	_main_texture.texture = depth_texture
	_main_texture.visible = _swapped_to_depth and _can_swap(_last_texture_available)
	_refresh_sample_overlay()
	_refresh_fps_label()
	_refresh_thumbnail(preview_texture, depth_texture)

func _refresh_sample_overlay() -> void:
	if _sample_overlay == null:
		return
	var show_overlay := bool(visual_config.get("sampling_regions_visible", false))
	var sample_geometry: Dictionary = snapshot.get("sample_geometry", {}) if snapshot.get("sample_geometry", {}) is Dictionary else {}
	_sample_overlay.visible = show_overlay and not sample_geometry.is_empty()
	if not _sample_overlay.visible:
		if _sample_overlay.has_method("clear_sample_geometry"):
			_sample_overlay.clear_sample_geometry()
		return
	if _sample_overlay.has_method("update_sample_geometry"):
		_sample_overlay.update_sample_geometry(sample_geometry, snapshot.get("depth_map_size", Vector2i.ZERO) as Vector2i)

func _refresh_fps_label() -> void:
	if _fps_label == null:
		return
	var show_fps := bool(visual_config.get("fps_visible", false)) and bool(visual_config.get("enabled", false))
	_fps_label.visible = show_fps
	if not show_fps:
		return
	_fps_label.text = "Preview %.1f FPS" % preview_fps

func _refresh_thumbnail(preview_texture: Texture2D, depth_texture: Texture2D) -> void:
	if _thumbnail_panel == null:
		return
	var show_thumbnail := bool(visual_config.get("thumbnail_visible", false)) and bool(visual_config.get("enabled", false))
	_thumbnail_panel.visible = show_thumbnail
	if not show_thumbnail:
		return
	_apply_thumbnail_layout()
	var focus_family := String(snapshot.get("family", "straight_punch")).replace("_", " ")
	var family_title := focus_family.capitalize()
	var texture_available := depth_texture != null
	var main_is_depth := _swapped_to_depth and texture_available
	var thumbnail_texture: Texture2D = preview_texture if main_is_depth else depth_texture
	var thumbnail_has_texture := thumbnail_texture != null
	_thumbnail_title_label.text = "%s · %s" % ["Preview" if main_is_depth else "Depth", family_title]
	_thumbnail_texture.visible = thumbnail_has_texture
	_thumbnail_texture.texture = thumbnail_texture
	var preferred_width := float(int(visual_config.get("thumbnail_width_px", 196)))
	_thumbnail_texture.custom_minimum_size = Vector2(preferred_width, roundf(preferred_width * 0.58))
	_thumbnail_placeholder_label.visible = not thumbnail_has_texture
	_thumbnail_placeholder_label.custom_minimum_size = _thumbnail_texture.custom_minimum_size
	_thumbnail_placeholder_label.text = _placeholder_text()
	var failure_state := not thumbnail_has_texture
	_thumbnail_status_label.visible = not failure_state
	_thumbnail_status_label.text = "" if failure_state else _status_text(texture_available)
	var diagnostic_tooltip := _thumbnail_diagnostic_tooltip(texture_available)
	_thumbnail_panel.tooltip_text = diagnostic_tooltip
	_thumbnail_placeholder_label.tooltip_text = diagnostic_tooltip
	_thumbnail_status_label.tooltip_text = diagnostic_tooltip
	var show_hint := bool(visual_config.get("hover_hint_visible", false)) and _can_swap(texture_available) and _thumbnail_hovered
	_thumbnail_hint_label.visible = show_hint
	_thumbnail_hint_label.text = "Click to restore preview" if main_is_depth else "Click to inspect depth"

func _apply_thumbnail_layout() -> void:
	if _thumbnail_panel == null:
		return
	var preferred_width := float(int(visual_config.get("thumbnail_width_px", 196)))
	var margin := float(int(visual_config.get("thumbnail_margin_px", 14)))
	var panel_width := preferred_width + 20.0
	var panel_height := 190.0
	var corner := String(visual_config.get("thumbnail_corner", "bottom_right")).strip_edges().to_lower()
	_thumbnail_panel.custom_minimum_size = Vector2(panel_width, 0.0)
	match corner:
		"top_left":
			_thumbnail_panel.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
			_thumbnail_panel.offset_left = margin
			_thumbnail_panel.offset_top = margin
			_thumbnail_panel.offset_right = panel_width + margin
			_thumbnail_panel.offset_bottom = panel_height + margin
		"top_right":
			_thumbnail_panel.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
			_thumbnail_panel.offset_left = -(panel_width + margin)
			_thumbnail_panel.offset_top = margin
			_thumbnail_panel.offset_right = -margin
			_thumbnail_panel.offset_bottom = panel_height + margin
		"bottom_left":
			_thumbnail_panel.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
			_thumbnail_panel.offset_left = margin
			_thumbnail_panel.offset_top = -(panel_height + margin)
			_thumbnail_panel.offset_right = panel_width + margin
			_thumbnail_panel.offset_bottom = -margin
		_:
			_thumbnail_panel.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
			_thumbnail_panel.offset_left = -(panel_width + margin)
			_thumbnail_panel.offset_top = -(panel_height + margin)
			_thumbnail_panel.offset_right = -margin
			_thumbnail_panel.offset_bottom = -margin

func _placeholder_text() -> String:
	return "✕"

func _thumbnail_diagnostic_tooltip(texture_available: bool) -> String:
	var status_parts := [
		"Depth texture %s" % ("available" if texture_available else "unavailable"),
		"Runtime %s / %s" % [
			String(snapshot.get("runtime_status", "unloaded")),
			String(snapshot.get("runtime_stage", "idle")),
		],
	]
	var failure_code := String(snapshot.get("failure_code", "")).strip_edges()
	var failure_message := String(snapshot.get("failure_message", "")).strip_edges()
	if not failure_code.is_empty() or not failure_message.is_empty():
		status_parts.append("Failure %s" % _join_non_empty(" - ", [failure_code, failure_message]))
	status_parts.append(_status_text(texture_available))
	return "\n".join(status_parts)

func _status_text(texture_available: bool) -> String:
	var sample_metrics: Dictionary = snapshot.get("sample_metrics", {}) if snapshot.get("sample_metrics", {}) is Dictionary else {}
	var frame_size: Vector2i = snapshot.get("frame_size", Vector2i.ZERO)
	var depth_map_size: Vector2i = snapshot.get("depth_map_size", Vector2i.ZERO)
	var timing: Dictionary = snapshot.get("timing_ms", {}) if snapshot.get("timing_ms", {}) is Dictionary else {}
	var status_parts := [
		"texture=%s" % _fmt_bool(texture_available),
		"source=%s" % String(sample_metrics.get("sample_source", "none")),
		"fresh=%s" % _fmt_bool(bool(sample_metrics.get("sample_fresh", false))),
		"age=%dms" % int(snapshot.get("last_sample_age_ms", -1)),
		"cadence=%d/%dms" % [
			int(snapshot.get("sample_every_n_frames", 1)),
			int(snapshot.get("max_sample_age_ms", 0)),
		],
		"frame=%dx%d" % [frame_size.x, frame_size.y],
		"depth=%dx%d" % [depth_map_size.x, depth_map_size.y],
		"total=%.1fms" % float(timing.get("total", 0.0)),
	]
	return ", ".join(status_parts)

func _can_swap(texture_available: bool) -> bool:
	return texture_available \
		and bool(visual_config.get("enabled", false)) \
		and bool(visual_config.get("thumbnail_visible", false)) \
		and bool(visual_config.get("swap_click_enabled", false))

func _set_swapped_to_depth(value: bool) -> void:
	if _swapped_to_depth == value:
		return
	_swapped_to_depth = value
	swap_state_changed.emit(_swapped_to_depth)

func _fmt_bool(value: bool) -> String:
	return "true" if value else "false"

func _join_non_empty(separator: String, parts: Array[String]) -> String:
	var filtered: Array[String] = []
	for part: String in parts:
		if part.is_empty():
			continue
		filtered.append(part)
	return separator.join(filtered)

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
