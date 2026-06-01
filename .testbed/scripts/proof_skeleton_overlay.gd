extends SceneTree

const BOXING_SCENE := preload("res://scenes/boxing_proving.tscn")
const CameraTrackingProviderScript = preload("res://addons/aerobeat-input-camera-tracking/src/providers/camera_tracking_provider.gd")

const OUTPUT_DIR := "res://../.artifacts/skeleton-proof"
const VIEWPORT_SIZE := Vector2i(1280, 720)
const LIVE_OUTPUT_NAME := "live-webcam-skeleton.png"
const REPLAY_OUTPUT_NAME := "replay-skeleton.png"
const REPORT_OUTPUT_NAME := "report.json"

var _harness: Control = null
var _provider: Node = null
var _report := {}

func _initialize() -> void:
	root.size = VIEWPORT_SIZE
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))
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
	_prepare_preview_surface()
	_provider = CameraTrackingProviderScript.new()
	root.add_child(_provider)
	_provider.pose_updated.connect(Callable(_harness, "_on_pose_updated"))
	_provider.tracking_lost.connect(Callable(_harness, "_on_tracking_lost"))
	_provider.tracking_restored.connect(Callable(_harness, "_on_tracking_restored"))
	_harness.set("provider", _provider)
	if _harness.has_method("_ensure_overlay_drawers_ready"):
		_harness.call("_ensure_overlay_drawers_ready")

	var live_frame := {
		"timestamp_ms": 100,
		"backend": "proof",
		"source_kind": "live_camera",
		"source_id": "/dev/video7",
		"tracking_state": "tracked",
		"preview_transform": {"flip_horizontal": true, "space": "gameplay_normalized"},
		"landmarks": _sample_landmarks(),
	}
	var replay_frame := {
		"timestamp_ms": 200,
		"backend": "proof",
		"source_kind": "video_file",
		"source_id": "res://assets/fixtures/boxing/punch_left/boxing_guard->punch_left_repeat_04_take_01.mp4",
		"tracking_state": "tracked",
		"preview_transform": {"flip_horizontal": false, "space": "gameplay_normalized"},
		"landmarks": _sample_landmarks(),
	}

	await _capture_frame("live_webcam", live_frame, LIVE_OUTPUT_NAME)
	await _capture_frame("replay", replay_frame, REPLAY_OUTPUT_NAME)
	_write_report()
	quit(0)

func _prepare_preview_surface() -> void:
	var camera_display := _harness.get_node_or_null("Margin/VSplit/Content/LeftColumn/CameraPanel/CameraDisplay") as TextureRect
	if camera_display == null:
		push_error("CameraDisplay not found in proving scene")
		quit(3)
		return
	var image := Image.create(VIEWPORT_SIZE.x / 2, VIEWPORT_SIZE.y / 2, false, Image.FORMAT_RGBA8)
	image.fill(Color(0.08, 0.08, 0.08, 1.0))
	camera_display.texture = ImageTexture.create_from_image(image)
	camera_display.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	camera_display.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED

func _capture_frame(label: String, frame: Dictionary, output_name: String) -> void:
	_provider.call("ingest_tracking_frame", frame)
	await process_frame
	await process_frame
	var latest_state: Dictionary = _provider.call("get_detector_state")
	var landmark_drawer: Control = _harness.get("landmark_drawer") as Control
	if landmark_drawer == null:
		push_error("LandmarkDrawer missing for %s" % label)
		quit(4)
		return
	var image_bounds: Rect2 = landmark_drawer.call("_get_displayed_image_bounds")
	var screen_landmarks: Array = []
	for landmark_variant: Variant in landmark_drawer.get("_landmarks"):
		if not landmark_variant is Dictionary:
			continue
		var landmark: Dictionary = landmark_variant
		var position: Vector2 = landmark_drawer.call("_landmark_to_screen", landmark, image_bounds.size.x, image_bounds.size.y, image_bounds.position)
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
		"tracking_state": String(latest_state.get("tracking_state", "")),
		"visible_landmarks": int((latest_state.get("landmarks_by_id", {}) as Dictionary).size()),
		"source_kind": String(frame.get("source_kind", "")),
		"overlay_parent": String(landmark_drawer.get_parent().name) if landmark_drawer.get_parent() != null else "",
		"image_bounds": {
			"x": image_bounds.position.x,
			"y": image_bounds.position.y,
			"width": image_bounds.size.x,
			"height": image_bounds.size.y,
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
