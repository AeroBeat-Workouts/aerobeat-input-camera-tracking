extends Control
## Consumer-owned click/inspection layer for landmarks.
##
## Preview image loading, fit/crop behavior, mirroring, and rendered skeleton/landmark
## overlays now belong to the tool-owned CameraTrackingPreviewPresenter. This layer only
## keeps enlarged hit targets so the proving harness can still inspect landmarks.

signal landmark_clicked(landmark_id: int)

const LANDMARK_HIT_RADIUS: float = 18.0

var _landmarks: Array = []
var _min_visibility: float = 0.5
var _preview_presenter: Node = null

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_PASS

func set_preview_presenter(preview_presenter: Node) -> void:
	_preview_presenter = preview_presenter
	queue_redraw()

func update_landmarks(landmarks: Array, min_visibility: float = 0.5) -> void:
	_min_visibility = min_visibility
	_landmarks.clear()

	for landmark_variant: Variant in landmarks:
		if not landmark_variant is Dictionary:
			continue
		var lm: Dictionary = landmark_variant
		if float(lm.get("v", 0.0)) < _min_visibility:
			continue
		_landmarks.append({
			"id": int(lm.get("id", -1)),
			"x": float(lm.get("x", 0.0)),
			"y": float(lm.get("y", 0.0)),
			"z": float(lm.get("z", 0.0)),
			"v": float(lm.get("v", 0.0)),
		})

	queue_redraw()

func clear_landmarks() -> void:
	_landmarks.clear()
	queue_redraw()

func _gui_input(event: InputEvent) -> void:
	if not (event is InputEventMouseButton):
		return
	var mouse_event := event as InputEventMouseButton
	if not mouse_event.pressed or mouse_event.button_index != MOUSE_BUTTON_LEFT:
		return
	var landmark_id := _find_clicked_landmark(mouse_event.position)
	if landmark_id < 0:
		return
	accept_event()
	landmark_clicked.emit(landmark_id)

func _draw() -> void:
	# The presenter now owns visible landmark rendering; keep this layer invisible.
	pass

func _find_clicked_landmark(screen_position: Vector2) -> int:
	if _landmarks.is_empty():
		return -1
	var image_bounds := _get_displayed_image_bounds()
	var width := image_bounds.size.x
	var height := image_bounds.size.y
	var offset := image_bounds.position
	var closest_id := -1
	var closest_distance := INF
	for landmark: Dictionary in _landmarks:
		if not _is_landmark_in_bounds(landmark):
			continue
		var landmark_position := _landmark_to_screen(landmark, width, height, offset)
		var distance := landmark_position.distance_to(screen_position)
		if distance > LANDMARK_HIT_RADIUS:
			continue
		if distance < closest_distance:
			closest_distance = distance
			closest_id = int(landmark.get("id", -1))
	return closest_id

func _is_landmark_in_bounds(lm: Dictionary) -> bool:
	return float(lm.get("x", -1.0)) >= 0.0 \
		and float(lm.get("x", -1.0)) <= 1.0 \
		and float(lm.get("y", -1.0)) >= 0.0 \
		and float(lm.get("y", -1.0)) <= 1.0

func _landmark_to_screen(lm: Dictionary, width: float, height: float, offset: Vector2 = Vector2.ZERO) -> Vector2:
	if _preview_presenter != null and is_instance_valid(_preview_presenter) and _preview_presenter.has_method("map_landmark_to_preview_position"):
		return _preview_presenter.map_landmark_to_preview_position(lm)
	# Compatibility fallback for non-presenter tests/lanes.
	var x: float = offset.x + float(lm.get("x", 0.0)) * width
	var y: float = offset.y + (1.0 - float(lm.get("y", 0.0))) * height
	return Vector2(x, y)

func _get_displayed_image_bounds() -> Rect2:
	if _preview_presenter != null and is_instance_valid(_preview_presenter) and _preview_presenter.has_method("get_content_rect"):
		return _preview_presenter.get_content_rect()

	var parent: TextureRect = get_parent() as TextureRect
	if parent == null:
		return get_rect()

	var texture: Texture2D = parent.texture
	if texture == null:
		return get_rect()

	var tex_size: Vector2 = texture.get_size()
	if tex_size.x == 0 or tex_size.y == 0:
		return get_rect()

	var rect: Rect2 = get_rect()
	var container_size: Vector2 = rect.size
	var tex_aspect: float = tex_size.x / tex_size.y
	var container_aspect: float = container_size.x / container_size.y
	var displayed_size: Vector2

	match parent.stretch_mode:
		TextureRect.STRETCH_KEEP_ASPECT_CENTERED, TextureRect.STRETCH_KEEP_ASPECT_COVERED:
			if tex_aspect > container_aspect:
				displayed_size = Vector2(container_size.x, container_size.x / tex_aspect)
			else:
				displayed_size = Vector2(container_size.y * tex_aspect, container_size.y)
		TextureRect.STRETCH_KEEP:
			displayed_size = tex_size
		_:
			displayed_size = container_size

	var draw_offset: Vector2 = (container_size - displayed_size) / 2.0
	return Rect2(draw_offset, displayed_size)

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		queue_redraw()
