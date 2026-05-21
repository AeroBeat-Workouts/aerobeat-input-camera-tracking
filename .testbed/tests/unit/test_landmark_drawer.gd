extends "res://addons/gut/test.gd"

const LandmarkDrawerScript = preload("res://scripts/landmark_drawer.gd")

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
