extends Control
## Shared calibrated 4x3 overlay drawer for proving-scene preview surfaces.

const GRID_STROKE_COLOR := Color(0.89, 0.97, 1.0, 0.76)
const GRID_STROKE_WIDTH := 1.3
const GRID_BORDER_COLOR := Color(0.42, 0.86, 1.0, 0.94)
const GRID_BORDER_WIDTH := 1.7
const GRID_COORDINATE_SPACE_GAMEPLAY_BOTTOM_LEFT := "gameplay_bottom_left"

var _preview_presenter: Node = null
var _grid_debug: Dictionary = {}

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func set_preview_presenter(preview_presenter: Node) -> void:
	_preview_presenter = preview_presenter
	queue_redraw()

func update_grid_debug(grid_debug: Dictionary) -> void:
	_grid_debug = grid_debug.duplicate(true)
	visible = not _grid_debug.is_empty() and bool(_grid_debug.get("is_calibrated", false))
	queue_redraw()

func clear_grid_debug() -> void:
	_grid_debug = {}
	visible = false
	queue_redraw()

func get_overlay_snapshot() -> Dictionary:
	var cell_rects: Array = _grid_debug.get("cell_rects", []) as Array
	var render_snapshot := _build_render_snapshot()
	return {
		"is_calibrated": bool(_grid_debug.get("is_calibrated", false)),
		"columns": int(_grid_debug.get("columns", 0)),
		"rows": int(_grid_debug.get("rows", 0)),
		"coordinate_space": String(_grid_debug.get("coordinate_space", GRID_COORDINATE_SPACE_GAMEPLAY_BOTTOM_LEFT)),
		"cell_size": float(_grid_debug.get("cell_size", 0.0)),
		"cell_width": float(_grid_debug.get("cell_width", _grid_debug.get("cell_size", 0.0))),
		"cell_height": float(_grid_debug.get("cell_height", _grid_debug.get("cell_size", 0.0))),
		"width": float(_grid_debug.get("width", 0.0)),
		"height": float(_grid_debug.get("height", 0.0)),
		"line_count": maxi(0, int(_grid_debug.get("columns", 0)) + 1) + maxi(0, int(_grid_debug.get("rows", 0)) + 1),
		"cell_count": cell_rects.size(),
		"left_boundary": float(_grid_debug.get("left_boundary", 0.0)),
		"top_boundary": float(_grid_debug.get("top_boundary", 0.0)),
		"right_boundary": float(_grid_debug.get("right_boundary", 0.0)),
		"bottom_boundary": float(_grid_debug.get("bottom_boundary", 0.0)),
		"render_top_left": render_snapshot.get("top_left", Vector2.ZERO),
		"render_bottom_right": render_snapshot.get("bottom_right", Vector2.ZERO),
		"render_cell_width_px": float(render_snapshot.get("cell_width_px", 0.0)),
		"render_cell_height_px": float(render_snapshot.get("cell_height_px", 0.0)),
		"render_width_px": float(render_snapshot.get("width_px", 0.0)),
		"render_height_px": float(render_snapshot.get("height_px", 0.0)),
		"visible_top_left": render_snapshot.get("visible_top_left", Vector2.ZERO),
		"visible_bottom_right": render_snapshot.get("visible_bottom_right", Vector2.ZERO),
		"visible_width_px": float(render_snapshot.get("visible_width_px", 0.0)),
		"visible_height_px": float(render_snapshot.get("visible_height_px", 0.0)),
		"visible_clipped": bool(render_snapshot.get("visible_clipped", false)),
		"content_rect": render_snapshot.get("content_rect", Rect2()),
	}

func _draw() -> void:
	var render_snapshot := _build_render_snapshot()
	if not bool(render_snapshot.get("draw_ready", false)):
		return
	var columns := int(render_snapshot.get("columns", 0))
	var rows := int(render_snapshot.get("rows", 0))
	var top_left: Vector2 = render_snapshot.get("top_left", Vector2.ZERO)
	var cell_width_px := float(render_snapshot.get("cell_width_px", 0.0))
	var cell_height_px := float(render_snapshot.get("cell_height_px", 0.0))
	for column: int in range(columns + 1):
		var x := top_left.x + cell_width_px * float(column)
		var start := Vector2(x, top_left.y)
		var finish := Vector2(x, top_left.y + cell_height_px * float(rows))
		var width := GRID_BORDER_WIDTH if column == 0 or column == columns else GRID_STROKE_WIDTH
		var color := GRID_BORDER_COLOR if column == 0 or column == columns else GRID_STROKE_COLOR
		draw_line(start, finish, color, width, true)
	for row: int in range(rows + 1):
		var y := top_left.y + cell_height_px * float(row)
		var start := Vector2(top_left.x, y)
		var finish := Vector2(top_left.x + cell_width_px * float(columns), y)
		var width := GRID_BORDER_WIDTH if row == 0 or row == rows else GRID_STROKE_WIDTH
		var color := GRID_BORDER_COLOR if row == 0 or row == rows else GRID_STROKE_COLOR
		draw_line(start, finish, color, width, true)

func _build_render_snapshot() -> Dictionary:
	if _grid_debug.is_empty() or not bool(_grid_debug.get("is_calibrated", false)):
		return {"draw_ready": false}
	var columns := int(_grid_debug.get("columns", 0))
	var rows := int(_grid_debug.get("rows", 0))
	var cell_width := float(_grid_debug.get("cell_width", _grid_debug.get("cell_size", 0.0)))
	var cell_height := float(_grid_debug.get("cell_height", _grid_debug.get("cell_size", 0.0)))
	var left_boundary := float(_grid_debug.get("left_boundary", 0.0))
	var top_boundary := float(_grid_debug.get("top_boundary", 0.0))
	if columns <= 0 or rows <= 0 or cell_width <= 0.000001 or cell_height <= 0.000001:
		return {"draw_ready": false}
	var content_rect := _resolve_preview_content_rect()
	var top_left_normalized := _to_preview_coordinate_space(Vector2(left_boundary, top_boundary))
	var top_left := _map_preview_space_point(top_left_normalized, false, content_rect)
	var next_column := _map_preview_space_point(top_left_normalized + Vector2(cell_width, 0.0), false, content_rect)
	var next_row := _map_preview_space_point(top_left_normalized + Vector2(0.0, cell_height), false, content_rect)
	var cell_width_px := absf(next_column.x - top_left.x)
	var cell_height_px := absf(next_row.y - top_left.y)
	var bottom_right := Vector2(top_left.x + cell_width_px * float(columns), top_left.y + cell_height_px * float(rows))
	var visible_rect := _clip_rect_to_overlay(Rect2(top_left, bottom_right - top_left))
	return {
		"draw_ready": cell_width_px > 0.000001 and cell_height_px > 0.000001,
		"columns": columns,
		"rows": rows,
		"top_left": top_left,
		"bottom_right": bottom_right,
		"cell_width_px": cell_width_px,
		"cell_height_px": cell_height_px,
		"width_px": cell_width_px * float(columns),
		"height_px": cell_height_px * float(rows),
		"visible_top_left": visible_rect.position,
		"visible_bottom_right": visible_rect.end,
		"visible_width_px": visible_rect.size.x,
		"visible_height_px": visible_rect.size.y,
		"visible_clipped": not visible_rect.is_equal_approx(Rect2(top_left, bottom_right - top_left)),
		"content_rect": content_rect,
	}

func _to_preview_coordinate_space(point: Vector2) -> Vector2:
	var coordinate_space := String(_grid_debug.get("coordinate_space", GRID_COORDINATE_SPACE_GAMEPLAY_BOTTOM_LEFT)).strip_edges().to_lower()
	if coordinate_space == GRID_COORDINATE_SPACE_GAMEPLAY_BOTTOM_LEFT:
		return Vector2(point.x, 1.0 - point.y)
	return point

func _resolve_preview_content_rect() -> Rect2:
	if _preview_presenter != null and is_instance_valid(_preview_presenter) and _preview_presenter.has_method("get_content_rect"):
		var presenter_rect: Variant = _preview_presenter.get_content_rect()
		if presenter_rect is Rect2:
			return presenter_rect
	return Rect2(Vector2.ZERO, size)

func _map_preview_space_point(point: Vector2, clamp_to_content: bool = true, content_rect_override: Variant = null) -> Vector2:
	var content_rect: Rect2 = content_rect_override if content_rect_override is Rect2 else _resolve_preview_content_rect()
	var mapped: Vector2 = point
	if clamp_to_content:
		mapped = Vector2(clampf(point.x, 0.0, 1.0), clampf(point.y, 0.0, 1.0))
	return Vector2(
		content_rect.position.x + mapped.x * content_rect.size.x,
		content_rect.position.y + mapped.y * content_rect.size.y
	)

func _clip_rect_to_overlay(rect: Rect2) -> Rect2:
	var overlay_rect := Rect2(Vector2.ZERO, size)
	var normalized := rect.abs()
	var clipped := normalized.intersection(overlay_rect)
	if clipped.size.x < 0.0 or clipped.size.y < 0.0:
		return Rect2(normalized.position, Vector2.ZERO)
	return clipped

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		queue_redraw()
