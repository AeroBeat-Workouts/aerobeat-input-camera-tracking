extends Control
class_name FlowRingChart

enum ChartMode {
	PLACEMENT_GRID,
	DIRECTION_COMPASS,
}

const GRID_COLUMNS := 4
const GRID_ROWS := 3
const MIN_CHART_SIZE := Vector2(176, 176)
const DIRECTION_ARROW_LABELS := {
	0: "↑",
	1: "↓",
	2: "←",
	3: "→",
	4: "↖",
	5: "↗",
	6: "↙",
	7: "↘",
}
const COMPASS_OFFSETS := {
	0: Vector2(0, -1),
	1: Vector2(0, 1),
	2: Vector2(-1, 0),
	3: Vector2(1, 0),
	4: Vector2(-1, -1),
	5: Vector2(1, -1),
	6: Vector2(-1, 1),
	7: Vector2(1, 1),
}

@export var chart_title := "Placement"
@export_multiline var chart_subtitle := ""
@export var chart_mode: ChartMode = ChartMode.PLACEMENT_GRID
@export var active_index := -1:
	set(value):
		if active_index == value:
			return
		active_index = value
		queue_redraw()

@export var line_color := Color(1.0, 1.0, 1.0, 0.75)
@export var inactive_fill_color := Color(1.0, 1.0, 1.0, 0.08)
@export var active_fill_color := Color(0.47, 0.82, 1.0, 0.95)
@export var label_color := Color(1.0, 1.0, 1.0, 1.0)
@export var title_color := Color(1.0, 1.0, 1.0, 1.0)
@export var subtitle_color := Color(1.0, 1.0, 1.0, 0.7)

func _ready() -> void:
	custom_minimum_size = MIN_CHART_SIZE
	queue_redraw()

func _draw() -> void:
	var rect := get_rect()
	var font := ThemeDB.fallback_font
	if font == null:
		return
	var min_axis := minf(rect.size.x, rect.size.y)
	var title_font_size := clampi(int(min_axis * 0.078), 13, 17)
	var subtitle_font_size := clampi(int(min_axis * 0.055), 10, 12)
	var body_font_size := clampi(int(min_axis * 0.08), 12, 18)
	var title_height := _draw_header(font, title_font_size, subtitle_font_size)
	var chart_rect := Rect2(
		Vector2(12.0, title_height + 8.0),
		Vector2(maxf(rect.size.x - 24.0, 72.0), maxf(rect.size.y - title_height - 20.0, 72.0))
	)
	if chart_mode == ChartMode.DIRECTION_COMPASS:
		_draw_direction_compass(chart_rect, font, body_font_size)
	else:
		_draw_placement_grid(chart_rect, font, body_font_size)

func _draw_header(font: Font, title_font_size: int, subtitle_font_size: int) -> float:
	var y := 18.0
	var title_size := font.get_string_size(chart_title, HORIZONTAL_ALIGNMENT_LEFT, -1, title_font_size)
	var title_position := Vector2((size.x - title_size.x) * 0.5, y)
	draw_string(font, title_position, chart_title, HORIZONTAL_ALIGNMENT_LEFT, -1, title_font_size, title_color)
	y += title_size.y + 6.0
	if not chart_subtitle.is_empty():
		var subtitle_size := font.get_multiline_string_size(chart_subtitle, HORIZONTAL_ALIGNMENT_CENTER, maxf(size.x - 24.0, 32.0), subtitle_font_size)
		var subtitle_position := Vector2(12.0, y)
		draw_multiline_string(font, subtitle_position, chart_subtitle, HORIZONTAL_ALIGNMENT_CENTER, maxf(size.x - 24.0, 32.0), subtitle_font_size, -1, subtitle_color)
		y += subtitle_size.y + 4.0
	return y

func _draw_placement_grid(chart_rect: Rect2, font: Font, font_size: int) -> void:
	var gap := 8.0
	var cell_width := (chart_rect.size.x - gap * float(GRID_COLUMNS - 1)) / float(GRID_COLUMNS)
	var cell_height := (chart_rect.size.y - gap * float(GRID_ROWS - 1)) / float(GRID_ROWS)
	var cell_size := minf(cell_width, cell_height)
	var board_size := Vector2(
		cell_size * float(GRID_COLUMNS) + gap * float(GRID_COLUMNS - 1),
		cell_size * float(GRID_ROWS) + gap * float(GRID_ROWS - 1)
	)
	var board_origin := chart_rect.position + (chart_rect.size - board_size) * 0.5
	var corner_radius := maxf(cell_size * 0.12, 9.0)
	var stroke_width := clampf(cell_size * 0.04, 1.3, 2.2)
	for visual_row: int in range(GRID_ROWS):
		for column: int in range(GRID_COLUMNS):
			var gameplay_cell_index := _gameplay_cell_index_for_visual_slot(visual_row, column)
			var athlete_space_cell_index := _athlete_space_cell_index_for_visual_slot(visual_row, column)
			var cell_rect := Rect2(
				board_origin + Vector2(column * (cell_size + gap), visual_row * (cell_size + gap)),
				Vector2(cell_size, cell_size)
			)
			var fill_color := active_fill_color if gameplay_cell_index == active_index else inactive_fill_color
			draw_rect(cell_rect, fill_color, true)
			draw_rect(cell_rect, line_color, false, stroke_width)
			_draw_cell_label(font, font_size, cell_rect, str(athlete_space_cell_index), corner_radius)

func _gameplay_cell_index_for_visual_slot(visual_row: int, column: int) -> int:
	if visual_row < 0 or visual_row >= GRID_ROWS or column < 0 or column >= GRID_COLUMNS:
		return -1
	var gameplay_row := (GRID_ROWS - 1) - visual_row
	return gameplay_row * GRID_COLUMNS + column

func _athlete_space_cell_index_for_visual_slot(visual_row: int, column: int) -> int:
	if visual_row < 0 or visual_row >= GRID_ROWS or column < 0 or column >= GRID_COLUMNS:
		return -1
	return visual_row * GRID_COLUMNS + column

func _draw_cell_label(font: Font, font_size: int, cell_rect: Rect2, label: String, _corner_radius: float) -> void:
	var text_size := font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
	var baseline := cell_rect.position + Vector2((cell_rect.size.x - text_size.x) * 0.5, cell_rect.size.y * 0.58)
	draw_string(font, baseline, label, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, label_color)

func _draw_direction_compass(chart_rect: Rect2, font: Font, font_size: int) -> void:
	var gap := 10.0
	var slot_size := minf(
		(chart_rect.size.x - gap * 2.0) / 3.0,
		(chart_rect.size.y - gap * 2.0) / 3.0
	)
	var board_size := Vector2(slot_size * 3.0 + gap * 2.0, slot_size * 3.0 + gap * 2.0)
	var origin := chart_rect.position + (chart_rect.size - board_size) * 0.5
	var stroke_width := clampf(slot_size * 0.05, 1.3, 2.2)
	var center_rect := Rect2(origin + Vector2(slot_size + gap, slot_size + gap), Vector2(slot_size, slot_size))
	draw_rect(center_rect, Color(1.0, 1.0, 1.0, 0.04), true)
	draw_rect(center_rect, line_color, false, stroke_width)
	for direction_index: int in COMPASS_OFFSETS.keys():
		var offset: Vector2 = COMPASS_OFFSETS[direction_index]
		var cell_origin := origin + Vector2((offset.x + 1.0) * (slot_size + gap), (offset.y + 1.0) * (slot_size + gap))
		var cell_rect := Rect2(cell_origin, Vector2(slot_size, slot_size))
		var fill_color := active_fill_color if direction_index == active_index else inactive_fill_color
		draw_rect(cell_rect, fill_color, true)
		draw_rect(cell_rect, line_color, false, stroke_width)
		var arrow := String(DIRECTION_ARROW_LABELS.get(direction_index, "?"))
		var arrow_font_size := clampi(font_size + 3, 14, 22)
		var arrow_size := font.get_string_size(arrow, HORIZONTAL_ALIGNMENT_LEFT, -1, arrow_font_size)
		var arrow_baseline := cell_rect.position + Vector2((cell_rect.size.x - arrow_size.x) * 0.5, cell_rect.size.y * 0.60)
		draw_string(font, arrow_baseline, arrow, HORIZONTAL_ALIGNMENT_LEFT, -1, arrow_font_size, label_color)
