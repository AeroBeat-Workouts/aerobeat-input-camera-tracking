extends Control
## Truthful proving-scene overlay for runtime-reported depth sample geometry.
##
## This layer only draws what the runtime actually surfaced in sample_geometry.
## It intentionally does not invent ROI boxes or a synthetic depth-map texture.

const SAMPLE_COLORS := {
	"shoulder": Color8(0x68, 0xd3, 0xff, 0xff),
	"torso": Color8(0x68, 0xd3, 0xff, 0xff),
	"elbow": Color8(0xa9, 0x95, 0xff, 0xff),
	"wrist": Color8(0xff, 0xc8, 0x3d, 0xff),
}
const FALLBACK_SAMPLE_COLOR := Color8(0xd7, 0xde, 0xe7, 0xff)
const SAMPLE_FILL_ALPHA := 0.15
const SAMPLE_RADIUS := 16.0
const SAMPLE_CENTER_RADIUS := 4.0
const SAMPLE_STROKE_WIDTH := 2.0
const REGION_STROKE_WIDTH := 2.0
const ANCHOR_RADIUS := 5.0
const ANCHOR_LINE_WIDTH := 2.0
const LABEL_FONT_SIZE := 12
const LABEL_BG := Color(0.02, 0.04, 0.07, 0.84)
const LABEL_TEXT := Color(1.0, 1.0, 1.0, 0.98)

var _preview_presenter: Node = null
var _sample_geometry: Dictionary = {}
var _depth_map_size := Vector2i.ZERO

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func set_preview_presenter(preview_presenter: Node) -> void:
	_preview_presenter = preview_presenter
	queue_redraw()

func update_sample_geometry(sample_geometry: Dictionary, depth_map_size: Vector2i = Vector2i.ZERO) -> void:
	_sample_geometry = sample_geometry.duplicate(true)
	_depth_map_size = depth_map_size
	queue_redraw()

func clear_sample_geometry() -> void:
	_sample_geometry.clear()
	_depth_map_size = Vector2i.ZERO
	queue_redraw()

func get_marker_snapshot() -> Array[Dictionary]:
	var markers: Array[Dictionary] = []
	if _sample_geometry.is_empty():
		return markers
	var sampling_mode := _sampling_mode()
	if sampling_mode == "region_aware":
		var region_anchors: Dictionary = _sample_geometry.get("region_anchors", {}) if _sample_geometry.get("region_anchors", {}) is Dictionary else {}
		for anchor_name_variant: Variant in region_anchors.keys():
			var anchor_name := String(anchor_name_variant)
			var anchor: Dictionary = region_anchors.get(anchor_name, {}) if region_anchors.get(anchor_name, {}) is Dictionary else {}
			var marker := _marker_from_sample(anchor_name, anchor)
			if not marker.is_empty():
				markers.append(marker)
		return markers
	var actual_samples: Dictionary = _sample_geometry.get("actual_samples", {}) if _sample_geometry.get("actual_samples", {}) is Dictionary else {}
	for sample_name_variant: Variant in actual_samples.keys():
		var sample_name := String(sample_name_variant)
		var sample: Dictionary = actual_samples.get(sample_name, {}) if actual_samples.get(sample_name, {}) is Dictionary else {}
		var marker := _marker_from_sample(sample_name, sample)
		if not marker.is_empty():
			markers.append(marker)
	return markers

func get_region_snapshot() -> Array[Dictionary]:
	var regions: Array[Dictionary] = []
	if _sample_geometry.is_empty() or _sampling_mode() != "region_aware":
		return regions
	var actual_regions: Dictionary = _sample_geometry.get("actual_regions", {}) if _sample_geometry.get("actual_regions", {}) is Dictionary else {}
	if actual_regions.is_empty():
		return regions
	var aggregation: Dictionary = _sample_geometry.get("aggregation", {}) if _sample_geometry.get("aggregation", {}) is Dictionary else {}
	var applied: Dictionary = aggregation.get("applied", {}) if aggregation.get("applied", {}) is Dictionary else {}
	var region_names: Array[String] = ["wrist", "torso"]
	for region_name: String in region_names:
		var region: Dictionary = actual_regions.get(region_name, {}) if actual_regions.get(region_name, {}) is Dictionary else {}
		if region.is_empty():
			continue
		var applied_region: Dictionary = applied.get(region_name, {}) if applied.get(region_name, {}) is Dictionary else {}
		var bounds_rect := _bounds_rect_from_pixels(region.get("bounds_px", {}) if region.get("bounds_px", {}) is Dictionary else {})
		var anchor_point := _map_pixel_to_preview_position(region.get("anchor_pixel", {}) if region.get("anchor_pixel", {}) is Dictionary else {})
		var overlay_region := {
			"name": region_name,
			"shape": String(region.get("shape", "")),
			"bounds_rect": bounds_rect,
			"anchor_point": anchor_point,
			"sampled_pixel_count": int(region.get("sampled_pixel_count", applied_region.get("sample_count", 0))),
			"valid_pixel_count": int(region.get("valid_pixel_count", applied_region.get("valid_sample_count", 0))),
			"aggregation_label": _aggregation_label(applied_region),
			"fallback_label": _fallback_label(applied_region),
			"anchor_label": _anchor_label(region_name, region),
		}
		if region_name == "wrist":
			overlay_region["elbow_point"] = _map_pixel_to_preview_position(region.get("elbow_pixel", {}) if region.get("elbow_pixel", {}) is Dictionary else {})
			overlay_region["extension_endpoint"] = _map_pixel_to_preview_position(region.get("extension_endpoint_pixel", {}) if region.get("extension_endpoint_pixel", {}) is Dictionary else {})
			overlay_region["radius_px"] = int(region.get("radius_px", 0))
			overlay_region["extension_toward_elbow_px"] = int(region.get("extension_toward_elbow_px", 0))
		else:
			overlay_region["half_width_px"] = int(region.get("half_width_px", 0))
			overlay_region["half_height_px"] = int(region.get("half_height_px", 0))
			overlay_region["torso_anchor"] = String(region.get("torso_anchor", ""))
		regions.append(overlay_region)
	return regions

func get_overlay_snapshot() -> Dictionary:
	return {
		"sampling_mode": _sampling_mode(),
		"markers": get_marker_snapshot(),
		"regions": get_region_snapshot(),
		"fallback_used": bool(_sample_geometry.get("aggregation", {}).get("fallback_used", false)),
		"fallback_reason": String(_sample_geometry.get("aggregation", {}).get("fallback_reason", "")),
	}

func _draw() -> void:
	if _sample_geometry.is_empty():
		return
	var font: Font = ThemeDB.fallback_font
	if _sampling_mode() == "region_aware":
		_draw_region_aware(font)
		return
	_draw_point_markers(font, get_marker_snapshot())

func _draw_point_markers(font: Font, markers: Array[Dictionary]) -> void:
	if markers.is_empty():
		return
	for marker: Dictionary in markers:
		var sample_name: String = String(marker.get("name", "sample"))
		var center: Vector2 = marker.get("center", Vector2.ZERO)
		var color: Color = SAMPLE_COLORS.get(sample_name, FALLBACK_SAMPLE_COLOR)
		draw_circle(center, SAMPLE_RADIUS, Color(color.r, color.g, color.b, SAMPLE_FILL_ALPHA))
		draw_arc(center, SAMPLE_RADIUS, 0.0, TAU, 48, color, SAMPLE_STROKE_WIDTH)
		draw_circle(center, SAMPLE_CENTER_RADIUS, color)
		if font != null:
			_draw_marker_label(font, marker, sample_name, center, color)

func _draw_region_aware(font: Font) -> void:
	var regions := get_region_snapshot()
	var markers := get_marker_snapshot()
	for region: Dictionary in regions:
		_draw_region_geometry(region)
		if font != null:
			_draw_region_label(font, region)
	for marker: Dictionary in markers:
		_draw_anchor_marker(font, marker)

func _draw_region_geometry(region: Dictionary) -> void:
	var region_name := String(region.get("name", "region"))
	var color: Color = SAMPLE_COLORS.get(region_name, FALLBACK_SAMPLE_COLOR)
	var bounds_rect: Rect2 = region.get("bounds_rect", Rect2())
	if bounds_rect.size.x > 0.0 and bounds_rect.size.y > 0.0:
		draw_rect(bounds_rect, Color(color.r, color.g, color.b, SAMPLE_FILL_ALPHA), true)
		draw_rect(bounds_rect, color, false, REGION_STROKE_WIDTH)
	var anchor_point: Vector2 = region.get("anchor_point", Vector2.ZERO)
	draw_circle(anchor_point, ANCHOR_RADIUS, color)
	if region_name == "wrist":
		var elbow_point: Vector2 = region.get("elbow_point", anchor_point)
		var extension_endpoint: Vector2 = region.get("extension_endpoint", anchor_point)
		if elbow_point != anchor_point:
			draw_line(anchor_point, elbow_point, SAMPLE_COLORS.get("elbow", FALLBACK_SAMPLE_COLOR), ANCHOR_LINE_WIDTH)
			draw_circle(elbow_point, ANCHOR_RADIUS - 1.0, SAMPLE_COLORS.get("elbow", FALLBACK_SAMPLE_COLOR))
		if extension_endpoint != anchor_point:
			draw_line(anchor_point, extension_endpoint, color, ANCHOR_LINE_WIDTH)
			draw_circle(extension_endpoint, ANCHOR_RADIUS - 1.0, color)

func _draw_anchor_marker(font: Font, marker: Dictionary) -> void:
	var anchor_name: String = String(marker.get("name", "anchor"))
	var center: Vector2 = marker.get("center", Vector2.ZERO)
	var color: Color = SAMPLE_COLORS.get(anchor_name, FALLBACK_SAMPLE_COLOR)
	draw_circle(center, ANCHOR_RADIUS, color)
	if font == null:
		return
	var text := "%s" % _display_name(anchor_name)
	var text_size := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, LABEL_FONT_SIZE)
	var text_position := center + Vector2(8.0, -8.0)
	if text_position.x + text_size.x > size.x:
		text_position.x = center.x - text_size.x - 8.0
	if text_position.y < text_size.y:
		text_position.y = center.y + text_size.y + 4.0
	draw_string(font, text_position, text, HORIZONTAL_ALIGNMENT_LEFT, -1, LABEL_FONT_SIZE, color)

func _draw_marker_label(font: Font, marker: Dictionary, sample_name: String, center: Vector2, color: Color) -> void:
	var pixel: Dictionary = marker.get("pixel", {}) if marker.get("pixel", {}) is Dictionary else {}
	var text := "%s · px(%d,%d)" % [_display_name(sample_name), int(pixel.get("x", -1)), int(pixel.get("y", -1))]
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

func _draw_region_label(font: Font, region: Dictionary) -> void:
	var region_name := String(region.get("name", "region"))
	var color: Color = SAMPLE_COLORS.get(region_name, FALLBACK_SAMPLE_COLOR)
	var lines := PackedStringArray([
		"%s · %s" % [_display_name(region_name), String(region.get("shape", "region"))],
		"%d sampled · %d valid · %s" % [
			int(region.get("sampled_pixel_count", 0)),
			int(region.get("valid_pixel_count", 0)),
			String(region.get("aggregation_label", "n/a")),
		],
	])
	var anchor_label := String(region.get("anchor_label", ""))
	if not anchor_label.is_empty():
		lines.append(anchor_label)
	var fallback_label := String(region.get("fallback_label", ""))
	if not fallback_label.is_empty():
		lines.append(fallback_label)
	var max_width := 0.0
	var total_height := 0.0
	for line: String in lines:
		var line_size := font.get_string_size(line, HORIZONTAL_ALIGNMENT_LEFT, -1, LABEL_FONT_SIZE)
		max_width = maxf(max_width, line_size.x)
		total_height += line_size.y
	var padding := Vector2(6.0, 4.0)
	var spacing := 2.0
	var label_size := Vector2(max_width + padding.x * 2.0, total_height + padding.y * 2.0 + spacing * float(max(lines.size() - 1, 0)))
	var bounds_rect: Rect2 = region.get("bounds_rect", Rect2())
	var label_position := bounds_rect.position + Vector2(bounds_rect.size.x + 8.0, 0.0)
	if label_position.x + label_size.x > size.x:
		label_position.x = maxf(0.0, bounds_rect.position.x - label_size.x - 8.0)
	if label_position.y + label_size.y > size.y:
		label_position.y = maxf(0.0, size.y - label_size.y)
	var label_rect := Rect2(label_position, label_size)
	draw_rect(label_rect, LABEL_BG, true)
	draw_rect(label_rect, color, false, 1.0)
	var baseline_y := label_rect.position.y + padding.y + font.get_ascent(LABEL_FONT_SIZE)
	for line: String in lines:
		draw_string(font, Vector2(label_rect.position.x + padding.x, baseline_y), line, HORIZONTAL_ALIGNMENT_LEFT, -1, LABEL_FONT_SIZE, LABEL_TEXT)
		baseline_y += font.get_string_size(line, HORIZONTAL_ALIGNMENT_LEFT, -1, LABEL_FONT_SIZE).y + spacing

func _marker_from_sample(sample_name: String, sample: Dictionary) -> Dictionary:
	if sample.is_empty():
		return {}
	var center := Vector2.INF
	var pixel: Dictionary = sample.get("pixel", {}) if sample.get("pixel", {}) is Dictionary else {}
	if not pixel.is_empty() and _has_depth_map_size():
		center = _map_pixel_to_preview_position(pixel)
	else:
		var normalized_point: Dictionary = sample.get("normalized_point", {}) if sample.get("normalized_point", {}) is Dictionary else {}
		if normalized_point.is_empty():
			return {}
		center = _map_normalized_point_to_preview_position(normalized_point)
	return {
		"name": sample_name,
		"center": center,
		"pixel": pixel.duplicate(true),
		"depth": float(sample.get("depth", 0.0)),
	}

func _sampling_mode() -> String:
	return String(_sample_geometry.get("sampling_mode", "single_point")).strip_edges().to_lower()

func _aggregation_label(applied_region: Dictionary) -> String:
	if applied_region.is_empty():
		return "n/a"
	var stat_applied := String(applied_region.get("stat_applied", applied_region.get("stat_requested", "n/a"))).strip_edges()
	if stat_applied.is_empty():
		stat_applied = "n/a"
	var trim_fraction := float(applied_region.get("trim_fraction", 0.0))
	if stat_applied == "trimmed_mean" and trim_fraction > 0.0:
		return "%s (trim %.2f)" % [stat_applied, trim_fraction]
	return stat_applied

func _fallback_label(applied_region: Dictionary) -> String:
	if applied_region.is_empty() or not bool(applied_region.get("fallback_used", false)):
		return ""
	var reason := String(applied_region.get("fallback_reason", "")).replace("_", " ")
	if reason.is_empty():
		return "fallback used"
	return "fallback: %s" % reason

func _anchor_label(region_name: String, region: Dictionary) -> String:
	if region_name == "torso":
		var torso_anchor := String(region.get("torso_anchor", "")).replace("_", " ")
		return "anchor: %s" % (torso_anchor if not torso_anchor.is_empty() else "torso")
	return "anchor: wrist → elbow"

func _display_name(sample_name: String) -> String:
	match sample_name:
		"shoulder":
			return "Shoulder"
		"torso":
			return "Torso"
		"wrist":
			return "Wrist"
		"elbow":
			return "Elbow"
		_:
			return sample_name.capitalize()

func _map_normalized_point_to_preview_position(point: Dictionary) -> Vector2:
	if _preview_presenter != null and is_instance_valid(_preview_presenter) and _preview_presenter.has_method("map_landmark_to_preview_position"):
		return _preview_presenter.map_landmark_to_preview_position(point)
	var content_rect := _get_content_rect()
	var x := clampf(float(point.get("x", 0.0)), 0.0, 1.0)
	var y := clampf(float(point.get("y", 0.0)), 0.0, 1.0)
	return content_rect.position + Vector2(x * content_rect.size.x, y * content_rect.size.y)

func _map_pixel_to_preview_position(pixel: Dictionary) -> Vector2:
	if pixel.is_empty() or not _has_depth_map_size():
		return Vector2.ZERO
	var content_rect := _get_content_rect()
	var width := maxf(float(_depth_map_size.x - 1), 1.0)
	var height := maxf(float(_depth_map_size.y - 1), 1.0)
	var x := clampf(float(pixel.get("x", 0.0)), 0.0, width) / width
	var y := clampf(float(pixel.get("y", 0.0)), 0.0, height) / height
	return content_rect.position + Vector2(x * content_rect.size.x, y * content_rect.size.y)

func _bounds_rect_from_pixels(bounds_px: Dictionary) -> Rect2:
	if bounds_px.is_empty() or not _has_depth_map_size():
		return Rect2()
	var min_point := _map_pixel_to_preview_position({
		"x": int(bounds_px.get("min_x", 0)),
		"y": int(bounds_px.get("min_y", 0)),
	})
	var max_point := _map_pixel_to_preview_position({
		"x": int(bounds_px.get("max_x", 0)),
		"y": int(bounds_px.get("max_y", 0)),
	})
	var size_vector := max_point - min_point
	return Rect2(min_point, Vector2(maxf(size_vector.x, 0.0), maxf(size_vector.y, 0.0)))

func _has_depth_map_size() -> bool:
	return _depth_map_size.x > 0 and _depth_map_size.y > 0

func _get_content_rect() -> Rect2:
	if _preview_presenter != null and is_instance_valid(_preview_presenter) and _preview_presenter.has_method("get_content_rect"):
		return _preview_presenter.get_content_rect()
	return get_rect()

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		queue_redraw()
