extends "res://addons/aerobeat-vendor-godot-unit-test/test.gd"

const LandmarkDrawerScript = preload("res://scripts/landmark_drawer.gd")

class FakePreviewPresenter:
	extends Node

	func map_landmark_to_preview_position(landmark: Dictionary) -> Vector2:
		return Vector2(float(landmark.get("x", 0.0)) * 640.0, float(landmark.get("y", 0.0)) * 480.0)

	func get_content_rect() -> Rect2:
		return Rect2(Vector2.ZERO, Vector2(640.0, 480.0))

var host: TextureRect = null
var drawer = null
var clicked_landmark_id := -1

func before_each() -> void:
	host = TextureRect.new()
	host.custom_minimum_size = Vector2(640, 480)
	host.size = Vector2(640, 480)
	host.stretch_mode = TextureRect.STRETCH_SCALE
	var image := Image.create(640, 480, false, Image.FORMAT_RGBA8)
	image.fill(Color.BLACK)
	host.texture = ImageTexture.create_from_image(image)
	add_child_autofree(host)

	drawer = LandmarkDrawerScript.new()
	drawer.size = Vector2(640, 480)
	host.add_child(drawer)
	clicked_landmark_id = -1
	drawer.landmark_clicked.connect(func(landmark_id: int) -> void:
		clicked_landmark_id = landmark_id
	)

func test_click_prefers_closest_landmark_when_hit_targets_overlap() -> void:
	drawer.update_landmarks([
		{"id": 15, "x": 0.500, "y": 0.500, "v": 0.99},
		{"id": 16, "x": 0.516, "y": 0.500, "v": 0.99},
	], 0.2)
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	click.position = Vector2(328.0, 240.0)
	drawer._gui_input(click)
	assert_eq(clicked_landmark_id, 16)

func test_click_ignores_empty_space_outside_hit_radius() -> void:
	drawer.update_landmarks([
		{"id": 15, "x": 0.250, "y": 0.500, "v": 0.99},
	], 0.2)
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	click.position = Vector2(400.0, 240.0)
	drawer._gui_input(click)
	assert_eq(clicked_landmark_id, -1)

func test_top_left_normalized_landmark_space_maps_directly_to_screen_space() -> void:
	var lower_body_point := {"id": 0, "x": 0.50, "y": 0.85, "v": 0.99}
	var screen_point: Vector2 = drawer._landmark_to_screen(lower_body_point, 640.0, 480.0)
	assert_true(is_equal_approx(screen_point.x, 320.0))
	assert_true(is_equal_approx(screen_point.y, 408.0))

func test_hit_target_snapshot_reports_screen_center_and_radius() -> void:
	drawer.update_landmarks([
		{"id": 7, "x": 0.25, "y": 0.75, "v": 0.99},
	], 0.2)
	var hit_targets: Array[Dictionary] = drawer.get_hit_target_snapshot()
	assert_eq(hit_targets.size(), 1)
	assert_eq(int(hit_targets[0].get("id", -1)), 7)
	assert_true(is_equal_approx(float(hit_targets[0].get("radius", 0.0)), drawer.LANDMARK_HIT_RADIUS))
	var center: Vector2 = hit_targets[0].get("center", Vector2.ZERO)
	assert_true(is_equal_approx(center.x, 160.0))
	assert_true(is_equal_approx(center.y, 360.0))

func test_hit_target_snapshot_uses_presenter_coordinate_mapping_when_available() -> void:
	var presenter := FakePreviewPresenter.new()
	add_child_autofree(presenter)
	drawer.set_preview_presenter(presenter)
	drawer.update_landmarks([
		{"id": 15, "x": 0.250, "y": 0.850, "v": 0.99},
	], 0.2)
	var hit_targets: Array[Dictionary] = drawer.get_hit_target_snapshot()
	assert_eq(hit_targets.size(), 1)
	var center: Vector2 = hit_targets[0].get("center", Vector2.ZERO)
	assert_true(is_equal_approx(center.x, 160.0))
	assert_true(is_equal_approx(center.y, 408.0))

func test_click_uses_presenter_coordinate_mapping_when_available() -> void:
	var presenter := FakePreviewPresenter.new()
	add_child_autofree(presenter)
	drawer.set_preview_presenter(presenter)
	drawer.update_landmarks([
		{"id": 15, "x": 0.250, "y": 0.850, "v": 0.99},
	], 0.2)
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	click.position = Vector2(160.0, 408.0)
	drawer._gui_input(click)
	assert_eq(clicked_landmark_id, 15)
