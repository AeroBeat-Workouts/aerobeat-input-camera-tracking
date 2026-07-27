extends Control

signal pressed

const BORDER_WIDTH := 2.0
const SEGMENTS := 48
const FILL_TWEEN_DURATION_SEC := 0.12
const ICON_SIZE := Vector2(42.0, 42.0)
const IDLE_COLOR := Color(0.44, 0.46, 0.50, 0.58)
const COOLDOWN_COLOR := Color(0.44, 0.46, 0.50, 0.26)
const PROGRESS_COLOR := Color(0.18, 0.83, 0.34, 0.82)
const BORDER_COLOR := Color(1.0, 1.0, 1.0, 0.78)
const HOVER_BORDER_COLOR := Color(1.0, 1.0, 1.0, 0.96)
const ICON_TINT := Color(1.0, 1.0, 1.0, 0.96)
const COOLDOWN_ICON_TINT := Color(0.78, 0.80, 0.84, 0.52)

var fill_ratio := 0.0:
	set(value):
		fill_ratio = clampf(value, 0.0, 1.0)

var displayed_fill_ratio := 0.0:
	set(value):
		displayed_fill_ratio = clampf(value, 0.0, 1.0)
		queue_redraw()

var progress_active := false:
	set(value):
		progress_active = value
		queue_redraw()

var cooldown_active := false:
	set(value):
		cooldown_active = value
		_refresh_icon_tint()
		queue_redraw()

var _hovered := false
var _icon_rect: TextureRect = null
var _fill_ratio_tween: Tween = null

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
	var clamped_ratio := clampf(ratio, 0.0, 1.0)
	fill_ratio = clamped_ratio
	if not active:
		_stop_fill_ratio_tween()
		progress_active = false
		displayed_fill_ratio = 0.0
		return
	progress_active = true
	_animate_fill_ratio_to(clamped_ratio)

func set_cooldown_active(active: bool) -> void:
	cooldown_active = active

func get_badge_snapshot() -> Dictionary:
	return {
		"fill_ratio": fill_ratio,
		"displayed_fill_ratio": displayed_fill_ratio,
		"progress_active": progress_active,
		"cooldown_active": cooldown_active,
		"hovered": _hovered,
		"tween_active": _fill_ratio_tween != null,
		"size": size,
		"custom_minimum_size": custom_minimum_size,
		"icon_present": _icon_rect != null and _icon_rect.texture != null,
		"icon_modulate": _icon_rect.modulate if _icon_rect != null else Color.WHITE,
		"idle_color": COOLDOWN_COLOR if cooldown_active else IDLE_COLOR,
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
	_refresh_icon_tint()

func _gui_input(event: InputEvent) -> void:
	if not (event is InputEventMouseButton):
		return
	var mouse_event := event as InputEventMouseButton
	if mouse_event.button_index != MOUSE_BUTTON_LEFT or not mouse_event.pressed:
		return
	accept_event()
	emit_signal("pressed")

func _stop_fill_ratio_tween() -> void:
	if _fill_ratio_tween != null:
		_fill_ratio_tween.kill()
		_fill_ratio_tween = null

func _animate_fill_ratio_to(target_ratio: float) -> void:
	if is_equal_approx(displayed_fill_ratio, target_ratio):
		displayed_fill_ratio = target_ratio
		return
	_stop_fill_ratio_tween()
	_fill_ratio_tween = create_tween()
	_fill_ratio_tween.tween_property(self, "displayed_fill_ratio", target_ratio, FILL_TWEEN_DURATION_SEC).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_fill_ratio_tween.finished.connect(func() -> void:
		_fill_ratio_tween = null
	)

func _refresh_icon_tint() -> void:
	if _icon_rect == null:
		return
	_icon_rect.modulate = COOLDOWN_ICON_TINT if cooldown_active else ICON_TINT

func _notification(what: int) -> void:
	if what == NOTIFICATION_MOUSE_ENTER:
		_hovered = true
		queue_redraw()
	elif what == NOTIFICATION_MOUSE_EXIT:
		_hovered = false
		queue_redraw()
	elif what == NOTIFICATION_RESIZED and _icon_rect != null:
		_icon_rect.position = (size - _icon_rect.size) * 0.5
	elif what == NOTIFICATION_PREDELETE:
		_stop_fill_ratio_tween()

func _draw() -> void:
	var center := size * 0.5
	var radius := maxf(0.0, minf(size.x, size.y) * 0.5 - BORDER_WIDTH)
	draw_circle(center, radius, COOLDOWN_COLOR if cooldown_active else IDLE_COLOR)
	if progress_active and displayed_fill_ratio > 0.0:
		if displayed_fill_ratio >= 0.999:
			draw_circle(center, radius, PROGRESS_COLOR)
		else:
			var points := PackedVector2Array()
			points.append(center)
			var max_angle := -PI * 0.5 + TAU * displayed_fill_ratio
			for step in range(SEGMENTS + 1):
				var t := float(step) / float(SEGMENTS)
				var angle := lerpf(-PI * 0.5, max_angle, t)
				points.append(center + Vector2.RIGHT.rotated(angle) * radius)
			draw_colored_polygon(points, PROGRESS_COLOR)
	var border_color := HOVER_BORDER_COLOR if _hovered else BORDER_COLOR
	draw_arc(center, radius, 0.0, TAU, 72, border_color, BORDER_WIDTH, true)
