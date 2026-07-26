extends Control

signal pressed

const BORDER_WIDTH := 2.0
const SEGMENTS := 48
const ICON_SIZE := Vector2(42.0, 42.0)
const IDLE_COLOR := Color(0.44, 0.46, 0.50, 0.58)
const PROGRESS_COLOR := Color(0.18, 0.83, 0.34, 0.82)
const BORDER_COLOR := Color(1.0, 1.0, 1.0, 0.78)
const HOVER_BORDER_COLOR := Color(1.0, 1.0, 1.0, 0.96)
const ICON_TINT := Color(1.0, 1.0, 1.0, 0.96)

var fill_ratio := 0.0:
	set(value):
		fill_ratio = clampf(value, 0.0, 1.0)
		queue_redraw()

var progress_active := false:
	set(value):
		progress_active = value
		queue_redraw()

var _hovered := false
var _icon_rect: TextureRect = null

func _ready() -> void:
	name = "TPoseCalibrationBadge"
	custom_minimum_size = Vector2(75.0, 75.0)
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	focus_mode = Control.FOCUS_NONE
	_ensure_icon()
	queue_redraw()

func set_icon(texture: Texture2D) -> void:
	_ensure_icon()
	if _icon_rect != null:
		_icon_rect.texture = texture

func set_progress(active: bool, ratio: float) -> void:
	progress_active = active
	fill_ratio = ratio

func get_badge_snapshot() -> Dictionary:
	return {
		"fill_ratio": fill_ratio,
		"progress_active": progress_active,
		"hovered": _hovered,
		"size": size,
		"custom_minimum_size": custom_minimum_size,
		"icon_present": _icon_rect != null and _icon_rect.texture != null,
	}

func _ensure_icon() -> void:
	if _icon_rect != null:
		return
	_icon_rect = TextureRect.new()
	_icon_rect.name = "Icon"
	_icon_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_icon_rect.custom_minimum_size = ICON_SIZE
	_icon_rect.size = ICON_SIZE
	_icon_rect.position = (custom_minimum_size - ICON_SIZE) * 0.5
	_icon_rect.modulate = ICON_TINT
	add_child(_icon_rect)

func _gui_input(event: InputEvent) -> void:
	if not (event is InputEventMouseButton):
		return
	var mouse_event := event as InputEventMouseButton
	if mouse_event.button_index != MOUSE_BUTTON_LEFT or not mouse_event.pressed:
		return
	accept_event()
	emit_signal("pressed")

func _notification(what: int) -> void:
	if what == NOTIFICATION_MOUSE_ENTER:
		_hovered = true
		queue_redraw()
	elif what == NOTIFICATION_MOUSE_EXIT:
		_hovered = false
		queue_redraw()
	elif what == NOTIFICATION_RESIZED and _icon_rect != null:
		_icon_rect.position = (size - _icon_rect.size) * 0.5

func _draw() -> void:
	var center := size * 0.5
	var radius := maxf(0.0, minf(size.x, size.y) * 0.5 - BORDER_WIDTH)
	draw_circle(center, radius, IDLE_COLOR)
	if progress_active and fill_ratio > 0.0:
		if fill_ratio >= 0.999:
			draw_circle(center, radius, PROGRESS_COLOR)
		else:
			var points := PackedVector2Array()
			points.append(center)
			var max_angle := -PI * 0.5 + TAU * fill_ratio
			for step in range(SEGMENTS + 1):
				var t := float(step) / float(SEGMENTS)
				var angle := lerpf(-PI * 0.5, max_angle, t)
				points.append(center + Vector2.RIGHT.rotated(angle) * radius)
			draw_colored_polygon(points, PROGRESS_COLOR)
	var border_color := HOVER_BORDER_COLOR if _hovered else BORDER_COLOR
	draw_arc(center, radius, 0.0, TAU, 72, border_color, BORDER_WIDTH, true)
