extends "res://addons/gut/test.gd"

const MediaPipeCameraView = preload("res://addons/aerobeat-input-camera-tracking/src/camera_view.gd")

func test_stop_stream_clears_stale_preview_state() -> void:
	var camera_view = add_child_autoqfree(MediaPipeCameraView.new())
	camera_view._mjpeg_buffer = PackedByteArray([1, 2, 3, 4])
	camera_view._overlay_landmarks = [{"id": 0, "x": 0.5, "y": 0.5}]
	camera_view._decoded_frame_count = 8
	camera_view._unique_frame_count = 3
	camera_view._repeat_signature_run = 2
	camera_view._last_frame_signature = 12345
	camera_view._is_streaming = true
	camera_view.visible = true

	camera_view.stop_stream()

	assert_eq(camera_view._mjpeg_buffer.size(), 0, "Stopping the stream should discard stale MJPEG bytes before the next restart")
	assert_eq(camera_view._overlay_landmarks.size(), 0, "Stopping the stream should clear stale overlay landmarks from the previous feed")
	assert_eq(camera_view._decoded_frame_count, 0)
	assert_eq(camera_view._unique_frame_count, 0)
	assert_eq(camera_view._repeat_signature_run, 0)
	assert_eq(camera_view._last_frame_signature, 0)
	assert_false(camera_view.visible)

func test_reset_preview_surface_reinitializes_blank_texture() -> void:
	var camera_view = add_child_autoqfree(MediaPipeCameraView.new())
	camera_view._current_frame = Image.create(8, 8, false, Image.FORMAT_RGBA8)
	camera_view._frame_texture = ImageTexture.create_from_image(camera_view._current_frame)

	camera_view._reset_preview_surface()

	assert_eq(camera_view._current_frame.get_width(), 640, "Preview reset should rebuild the blank frame at the canonical stream dimensions")
	assert_eq(camera_view._current_frame.get_height(), 480, "Preview reset should rebuild the blank frame at the canonical stream dimensions")
	assert_true(camera_view._frame_texture != null, "Preview reset should keep a valid texture bound for the next stream start")
	assert_eq(camera_view._frame_texture.get_width(), 640)
	assert_eq(camera_view._frame_texture.get_height(), 480)
