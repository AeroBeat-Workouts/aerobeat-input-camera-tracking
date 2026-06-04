extends Control
## Draws tracker-owned hand bbox rectangles with boxing state colors on top of the preview presenter.

const STATE_COLORS := {
	"ready": Color8(0xff, 0xd6, 0x00, 0xff),
	"triggered": Color8(0x32, 0xd7, 0x4b, 0xff),
	"not_ready": Color8(0xff, 0x45, 0x45, 0xff),
	"tracking_lost": Color8(0x7f, 0x10, 0x10, 0xff),
}
const FALLBACK_COLOR := Color8(0xc0, 0xc7, 0xd1, 0xff)
const LABEL_FONT_SIZE := 13
const LABEL_BG := Color(0.02, 0.03, 0.05, 0.82)
const LABEL_TEXT := Color(1.0, 1.0, 1.0, 0.98)
const STROKE_WIDTH := 3.0

var _preview_presenter: Node = null
var _hand_snapshot: Dictionary = {}
var _straight_punch_debug: Dictionary = {}

func set_preview_presenter(preview_presenter: Node) -> void:
	_preview_presenter = preview_presenter
	queue_redraw()

func update_snapshot(hand_snapshot: Dictionary, straight_punch_debug: Dictionary) -> void:
	_hand_snapshot = hand_snapshot.duplicate(true)
	_straight_punch_debug = straight_punch_debug.duplicate(true)
	queue_redraw()

func clear_snapshot() -> void:
	_hand_snapshot.clear()
	_straight_punch_debug.clear()
	queue_redraw()

func _draw() -> void:
	if _hand_snapshot.is_empty():
		return
	var hands: Dictionary = _hand_snapshot.get("hands", {}) if _hand_snapshot.get("hands", {}) is Dictionary else {}
	for side in ["left", "right"]:
		var hand: Dictionary = hands.get(side, {}) if hands.get(side, {}) is Dictionary else {}
		if not bool(hand.get("has_bbox", false)):
			continue
		var bbox: Dictionary = hand.get("bbox", {}) if hand.get("bbox", {}) is Dictionary else {}
		var rect := _map_bbox_to_preview_rect(bbox)
		if rect.size.x <= 0.0 or rect.size.y <= 0.0:
			continue
		var state_name := _resolve_side_state(side, hand)
		var color := _color_for_state(state_name)
		draw_rect(rect, color, false, STROKE_WIDTH)
		_draw_label(rect, "%s %s" % ["L" if side == "left" else "R", state_name], color)

func _resolve_side_state(side: String, hand: Dictionary) -> String:
	var side_debug: Dictionary = _straight_punch_debug.get(side, {}) if _straight_punch_debug.get(side, {}) is Dictionary else {}
	var state_name := String(side_debug.get("state", side_debug.get("phase", ""))).strip_edges().to_lower()
	if state_name.is_empty():
		state_name = String(hand.get("tracking_state", "tracking_lost")).strip_edges().to_lower()
	if STATE_COLORS.has(state_name):
		return state_name
	if not bool(hand.get("tracking_valid", false)):
		return "tracking_lost"
	return "not_ready"

func _color_for_state(state_name: String) -> Color:
	return STATE_COLORS.get(state_name, FALLBACK_COLOR)

func _map_bbox_to_preview_rect(bbox: Dictionary) -> Rect2:
	if _preview_presenter != null and is_instance_valid(_preview_presenter) and _preview_presenter.has_method("map_bbox_to_preview_rect"):
		return _preview_presenter.map_bbox_to_preview_rect(bbox)
	var content_rect := _get_content_rect()
	var x := clampf(float(bbox.get("x", 0.0)), 0.0, 1.0)
	var y := clampf(float(bbox.get("y", 0.0)), 0.0, 1.0)
	var width := clampf(float(bbox.get("width", 0.0)), 0.0, 1.0)
	var height := clampf(float(bbox.get("height", 0.0)), 0.0, 1.0)
	return Rect2(
		content_rect.position + Vector2(x * content_rect.size.x, y * content_rect.size.y),
		Vector2(width * content_rect.size.x, height * content_rect.size.y)
	)

func _get_content_rect() -> Rect2:
	if _preview_presenter != null and is_instance_valid(_preview_presenter) and _preview_presenter.has_method("get_content_rect"):
		return _preview_presenter.get_content_rect()
	return get_rect()

func _draw_label(rect: Rect2, text: String, color: Color) -> void:
	var font := ThemeDB.fallback_font
	if font == null:
		return
	var font_size := LABEL_FONT_SIZE
	var text_size := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
	var padding := Vector2(6.0, 4.0)
	var label_rect := Rect2(
		rect.position + Vector2(0.0, -text_size.y - (padding.y * 2.0) - 4.0),
		Vector2(text_size.x + (padding.x * 2.0), text_size.y + (padding.y * 2.0))
	)
	if label_rect.position.y < 0.0:
		label_rect.position.y = rect.position.y + 4.0
	draw_rect(label_rect, LABEL_BG, true)
	draw_rect(label_rect, color, false, 1.5)
	draw_string(font, label_rect.position + Vector2(padding.x, label_rect.size.y - padding.y - 2.0), text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, LABEL_TEXT)
