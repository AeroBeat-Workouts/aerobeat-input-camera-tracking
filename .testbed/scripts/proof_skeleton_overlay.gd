extends SceneTree

const BOXING_SCENE := preload("res://scenes/boxing_proving.tscn")
const CameraTrackingScript = preload("res://addons/aerobeat-tool-camera-tracking/src/CameraTracking.gd")
const CameraTrackingFakeBackendScript = preload("res://addons/aerobeat-tool-camera-tracking/src/CameraTrackingFakeBackend.gd")

const OUTPUT_DIR := "res://../.artifacts/skeleton-proof"
const VIEWPORT_SIZE := Vector2i(1280, 720)
const LIVE_OUTPUT_NAME := "live-webcam-skeleton.png"
const REPLAY_OUTPUT_NAME := "replay-skeleton.png"
const REPORT_OUTPUT_NAME := "report.json"
const PREVIEW_IMAGE_WIDTH := 640
const PREVIEW_IMAGE_HEIGHT := 360
const PREVIEW_IMAGE_PATH := "user://proof-skeleton-overlay-preview.png"

var _harness: Control = null
var _tracking_session: Node = null
var _backend = null
var _presenter: Control = null
var _report := {}

func _initialize() -> void:
	root.size = VIEWPORT_SIZE
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))
	_write_preview_image_fixture()
	_harness = BOXING_SCENE.instantiate() as Control
	if _harness == null:
		push_error("Failed to instantiate boxing proving scene")
		quit(2)
		return
	_harness.set("startup_mode", 2) # GODOT_ONLY_DEBUG
	root.add_child(_harness)
	call_deferred("_run")

func _run() -> void:
	await process_frame
	await process_frame
	_prepare_preview_presenter()
	if _presenter == null:
		quit(3)
		return

	var live_frame := {
		"timestamp_ms": 100,
		"backend": "proof",
		"source_kind": "live_camera",
		"source_id": "/dev/video7",
		"tracking_state": "tracked",
		"preview_transform": {"flip_horizontal": true, "space": "gameplay_normalized"},
		"frame_size": {"x": PREVIEW_IMAGE_WIDTH, "y": PREVIEW_IMAGE_HEIGHT},
		"landmarks": _sample_landmarks(),
	}
	var replay_frame := {
		"timestamp_ms": 200,
		"backend": "proof",
		"source_kind": "video_file",
		"source_id": "res://assets/fixtures/boxing/punch_left/boxing_guard->punch_left_repeat_04_take_01.mp4",
		"tracking_state": "tracked",
		"preview_transform": {"flip_horizontal": false, "space": "gameplay_normalized"},
		"frame_size": {"x": PREVIEW_IMAGE_WIDTH, "y": PREVIEW_IMAGE_HEIGHT},
		"landmarks": _sample_landmarks(),
	}

	await _capture_frame("live_webcam", live_frame, true, LIVE_OUTPUT_NAME)
	await _capture_frame("replay", replay_frame, false, REPLAY_OUTPUT_NAME)
	_write_report()
	quit(0)

func _prepare_preview_presenter() -> void:
	var camera_host := _harness.get_node_or_null("Margin/VSplit/Content/LeftColumn/CameraPanel/CameraDisplay") as Control
	if camera_host == null:
		push_error("CameraDisplay not found in proving scene")
		return
	_tracking_session = CameraTrackingScript.new()
	_backend = CameraTrackingFakeBackendScript.new()
	_tracking_session.set_backend(_backend, "fake")
	root.add_child(_tracking_session)
	_tracking_session.start({
		"source": {"kind": "live_camera", "camera_id": "/dev/video7"},
		"preview": {"enabled": true, "flip_horizontal": true},
	})
	_presenter = _tracking_session.mount_preview_presenter(camera_host, {
		"fit_mode": "cover",
		"overlay_visible": true,
		"min_visibility": 0.2,
	})
	if _presenter != null:
		_presenter.name = "CameraTrackingPreviewPresenter"

func _capture_frame(label: String, frame: Dictionary, flip_horizontal: bool, output_name: String) -> void:
	var descriptor := {
		"backend": "proof",
		"enabled": true,
		"image_path": ProjectSettings.globalize_path(PREVIEW_IMAGE_PATH),
		"image_revision": 1 if flip_horizontal else 2,
		"image_width": PREVIEW_IMAGE_WIDTH,
		"image_height": PREVIEW_IMAGE_HEIGHT,
		"width": PREVIEW_IMAGE_WIDTH,
		"height": PREVIEW_IMAGE_HEIGHT,
		"flip_horizontal": flip_horizontal,
		"space": "gameplay_normalized",
	}
	_backend.emit_preview_descriptor(descriptor)
	_backend.emit_tracking_frame(frame)
	await process_frame
	await process_frame

	var content_rect: Rect2 = _presenter.get_content_rect()
	var presenter_frame: Dictionary = _presenter.get_tracking_frame_snapshot()
	var screen_landmarks: Array = []
	for landmark_variant: Variant in presenter_frame.get("landmarks", []):
		if not landmark_variant is Dictionary:
			continue
		var landmark: Dictionary = landmark_variant
		var position: Vector2 = _presenter.map_landmark_to_preview_position(landmark)
		screen_landmarks.append({
			"id": int(landmark.get("id", -1)),
			"x": float(landmark.get("x", 0.0)),
			"y": float(landmark.get("y", 0.0)),
			"screen_x": position.x,
			"screen_y": position.y,
		})
	var output_path := ProjectSettings.globalize_path(OUTPUT_DIR.path_join(output_name))
	_report[label] = {
		"output_path": output_path,
		"tracking_state": String(presenter_frame.get("tracking_state", "")),
		"visible_landmarks": presenter_frame.get("landmarks", []).size(),
		"source_kind": String(frame.get("source_kind", "")),
		"overlay_parent": String(_presenter.name),
		"image_bounds": {
			"x": content_rect.position.x,
			"y": content_rect.position.y,
			"width": content_rect.size.x,
			"height": content_rect.size.y,
		},
		"screen_landmarks": screen_landmarks,
	}

func _write_report() -> void:
	var output_path := ProjectSettings.globalize_path(OUTPUT_DIR.path_join(REPORT_OUTPUT_NAME))
	var file := FileAccess.open(output_path, FileAccess.WRITE)
	if file == null:
		push_error("Failed to open report output: %s" % output_path)
		quit(6)
		return
	file.store_string(JSON.stringify(_report, "\t"))
	file.close()
	print("[SkeletonProof] report=%s" % output_path)

func _write_preview_image_fixture() -> void:
	var image := Image.create(PREVIEW_IMAGE_WIDTH, PREVIEW_IMAGE_HEIGHT, false, Image.FORMAT_RGBA8)
	for y: int in range(PREVIEW_IMAGE_HEIGHT):
		for x: int in range(PREVIEW_IMAGE_WIDTH):
			var horizontal := float(x) / float(max(PREVIEW_IMAGE_WIDTH - 1, 1))
			var vertical := float(y) / float(max(PREVIEW_IMAGE_HEIGHT - 1, 1))
			image.set_pixel(x, y, Color(horizontal, vertical, 0.18, 1.0))
	var save_err := image.save_png(ProjectSettings.globalize_path(PREVIEW_IMAGE_PATH))
	if save_err != OK:
		push_error("Failed to save preview image fixture (err=%d)" % save_err)

func _sample_landmarks() -> Array:
	return [
		{"id": 0, "x": 0.50, "y": 0.15, "z": 0.0, "visibility": 0.95},
		{"id": 11, "x": 0.42, "y": 0.32, "z": 0.0, "visibility": 0.92},
		{"id": 12, "x": 0.58, "y": 0.32, "z": 0.0, "visibility": 0.92},
		{"id": 13, "x": 0.38, "y": 0.42, "z": 0.0, "visibility": 0.90},
		{"id": 14, "x": 0.62, "y": 0.42, "z": 0.0, "visibility": 0.90},
		{"id": 15, "x": 0.36, "y": 0.48, "z": 0.0, "visibility": 0.94},
		{"id": 16, "x": 0.64, "y": 0.48, "z": 0.0, "visibility": 0.94},
		{"id": 23, "x": 0.45, "y": 0.56, "z": 0.0, "visibility": 0.91},
		{"id": 24, "x": 0.55, "y": 0.56, "z": 0.0, "visibility": 0.91},
		{"id": 25, "x": 0.44, "y": 0.72, "z": 0.0, "visibility": 0.88},
		{"id": 26, "x": 0.56, "y": 0.72, "z": 0.0, "visibility": 0.88},
		{"id": 27, "x": 0.43, "y": 0.86, "z": 0.0, "visibility": 0.90},
		{"id": 28, "x": 0.57, "y": 0.86, "z": 0.0, "visibility": 0.90},
	]
