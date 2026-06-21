extends Control
## Truthful proving-scene overlay for runtime-reported depth sample geometry.
##
## This layer only draws what the runtime actually surfaced in sample_geometry.
## It intentionally does not invent ROI boxes or a synthetic depth-map texture.

const SAMPLE_COLORS := {
	"shoulder": Color8(0x68, 0xd3, 0xff, 0xff),
	"wrist": Color8(0xff, 0xc8, 0x3d, 0xff),
}
const FALLBACK_SAMPLE_COLOR := Color8(0xd7, 0xde, 0xe7, 0xff)
const SAMPLE_FILL_ALPHA := 0.15
const SAMPLE_RADIUS := 16.0
const SAMPLE_CENTER_RADIUS := 4.0
const SAMPLE_STROKE_WIDTH := 2.0
const LABEL_FONT_SIZE := 12
const LABEL_BG := Color(0.02, 0.04, 0.07, 0.84)
const LABEL_TEXT := Color(1.0, 1.0, 1.0, 0.98)

var _preview_presenter: Node = null
var _sample_geometry: Dictionary = {}

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func set_preview_presenter(preview_presenter: Node) -> void:
	_preview_presenter = preview_presenter
	queue_redraw()

func update_sample_geometry(sample_geometry: Dictionary) -> void:
	_sample_geometry = sample_geometry.duplicate(true)
	queue_redraw()

func clear_sample_geometry() -> void:
	_sample_geometry.clear()
	queue_redraw()

func get_marker_snapshot() -> Array[Dictionary]:
	var markers: Array[Dictionary] = []
	if _sample_geometry.is_empty():
		return markers
	var actual_samples: Dictionary = _sample_geometry.get("actual_samples", {}) if _sample_geometry.get("actual_samples", {}) is Dictionary else {}
	for sample_name_variant: Variant in actual_samples.keys():
		var sample_name := String(sample_name_variant)
		var sample: Dictionary = actual_samples.get(sample_name, {}) if actual_samples.get(sample_name, {}) is Dictionary else {}
		var normalized_point: Dictionary = sample.get("normalized_point", {}) if sample.get("normalized_point", {}) is Dictionary else {}
		if normalized_point.is_empty():
			continue
		var center := _map_normalized_point_to_preview_position(normalized_point)
		markers.append({
			"name": sample_name,
			"center": center,
			"pixel": (sample.get("pixel", {}) as Dictionary).duplicate(true),
			"depth": float(sample.get("depth", 0.0)),
		})
	return markers

func _draw() -> void:
	var markers: Array[Dictionary] = get_marker_snapshot()
	if markers.is_empty():
		return
	var font: Font = ThemeDB.fallback_font
	for marker: Dictionary in markers:
		var sample_name: String = String(marker.get("name", "sample"))
		var center: Vector2 = marker.get("center", Vector2.ZERO)
		var color: Color = SAMPLE_COLORS.get(sample_name, FALLBACK_SAMPLE_COLOR)
		draw_circle(center, SAMPLE_RADIUS, Color(color.r, color.g, color.b, SAMPLE_FILL_ALPHA))
		draw_arc(center, SAMPLE_RADIUS, 0.0, TAU, 48, color, SAMPLE_STROKE_WIDTH)
		draw_circle(center, SAMPLE_CENTER_RADIUS, color)
		if font != null:
			_draw_marker_label(font, marker, sample_name, center, color)

func _draw_marker_label(font: Font, marker: Dictionary, sample_name: String, center: Vector2, color: Color) -> void:
	var pixel: Dictionary = marker.get("pixel", {}) if marker.get("pixel", {}) is Dictionary else {}
	var text := "%s · px(%d,%d)" % [sample_name.capitalize(), int(pixel.get("x", -1)), int(pixel.get("y", -1))]
	var text_size := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, LABEL_FONT_SIZE)
	var padding := Vector2(6.0, 4.0)
	var label_size := Vector2(text_size.x + padding.x * 2.0, text_size.y + padding.y * 2.0)
	var label_position := center + Vector2(SAMPLE_RADIUS + 6.0, -SAMPLE_RADIUS - label_size.y * 0.5)
	if label_position.x + label_size.x > size.x:
		label_position.x = center.x - SAMPLE_RADIUS - 6.0 - label_size.x
	if label_position.y < 0.0:
		label_position.y = center.y + SAMPLE_RADIUS + 6.0
	var label_rect := Rect2(label_position, label_size)
	draw_rect(label_rect, LABEL_BG, true)
	draw_rect(label_rect, color, false, 1.0)
	draw_string(font, label_rect.position + Vector2(padding.x, label_rect.size.y - padding.y - 1.0), text, HORIZONTAL_ALIGNMENT_LEFT, -1, LABEL_FONT_SIZE, LABEL_TEXT)

func _map_normalized_point_to_preview_position(point: Dictionary) -> Vector2:
	if _preview_presenter != null and is_instance_valid(_preview_presenter) and _preview_presenter.has_method("map_landmark_to_preview_position"):
		return _preview_presenter.map_landmark_to_preview_position(point)
	var content_rect := _get_content_rect()
	var x := clampf(float(point.get("x", 0.0)), 0.0, 1.0)
	var y := clampf(float(point.get("y", 0.0)), 0.0, 1.0)
	return content_rect.position + Vector2(x * content_rect.size.x, y * content_rect.size.y)

func _get_content_rect() -> Rect2:
	if _preview_presenter != null and is_instance_valid(_preview_presenter) and _preview_presenter.has_method("get_content_rect"):
		return _preview_presenter.get_content_rect()
	return get_rect()

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		queue_redraw()
