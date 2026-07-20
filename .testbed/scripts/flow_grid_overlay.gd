extends Control
## Shared calibrated 4x3 overlay drawer for proving-scene preview surfaces.

const GRID_STROKE_COLOR := Color(0.89, 0.97, 1.0, 0.76)
const GRID_STROKE_WIDTH := 1.3
const GRID_BORDER_COLOR := Color(0.42, 0.86, 1.0, 0.94)
const GRID_BORDER_WIDTH := 1.7

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
	return {
		"is_calibrated": bool(_grid_debug.get("is_calibrated", false)),
		"columns": int(_grid_debug.get("columns", 0)),
		"rows": int(_grid_debug.get("rows", 0)),
		"cell_size": float(_grid_debug.get("cell_size", 0.0)),
		"line_count": maxi(0, int(_grid_debug.get("columns", 0)) + 1) + maxi(0, int(_grid_debug.get("rows", 0)) + 1),
		"cell_count": cell_rects.size(),
		"left_boundary": float(_grid_debug.get("left_boundary", 0.0)),
		"top_boundary": float(_grid_debug.get("top_boundary", 0.0)),
	}

func _draw() -> void:
	if _grid_debug.is_empty() or not bool(_grid_debug.get("is_calibrated", false)):
		return
	var columns := int(_grid_debug.get("columns", 0))
	var rows := int(_grid_debug.get("rows", 0))
	var cell_size := float(_grid_debug.get("cell_size", 0.0))
	var left_boundary := float(_grid_debug.get("left_boundary", 0.0))
	var top_boundary := float(_grid_debug.get("top_boundary", 0.0))
	if columns <= 0 or rows <= 0 or cell_size <= 0.000001:
		return
	for column: int in range(columns + 1):
		var x := left_boundary + cell_size * float(column)
		var start := _map_normalized_point(Vector2(x, top_boundary))
		var finish := _map_normalized_point(Vector2(x, top_boundary - cell_size * float(rows)))
		var width := GRID_BORDER_WIDTH if column == 0 or column == columns else GRID_STROKE_WIDTH
		var color := GRID_BORDER_COLOR if column == 0 or column == columns else GRID_STROKE_COLOR
		draw_line(start, finish, color, width, true)
	for row: int in range(rows + 1):
		var y := top_boundary - cell_size * float(row)
		var start := _map_normalized_point(Vector2(left_boundary, y))
		var finish := _map_normalized_point(Vector2(left_boundary + cell_size * float(columns), y))
		var width := GRID_BORDER_WIDTH if row == 0 or row == rows else GRID_STROKE_WIDTH
		var color := GRID_BORDER_COLOR if row == 0 or row == rows else GRID_STROKE_COLOR
		draw_line(start, finish, color, width, true)

func _map_normalized_point(point: Vector2) -> Vector2:
	if _preview_presenter != null and is_instance_valid(_preview_presenter) and _preview_presenter.has_method("map_landmark_to_preview_position"):
		return _preview_presenter.map_landmark_to_preview_position({"x": point.x, "y": point.y})
	return Vector2(point.x * size.x, point.y * size.y)

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		queue_redraw()
