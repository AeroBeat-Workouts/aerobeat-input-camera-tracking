class_name CameraTrackingProvider
extends Node
## Contract-driven detector provider that consumes normalized CameraTracking frames.
##
## First migration-slice scope:
## - owns Boxing + Flow interpretation only
## - consumes upstream tracking frames instead of vendor/server payloads
## - can attach/detach preview surfaces through CameraTracking when a session is supplied
## - does not require this repo to own the camera runtime lifecycle

const PROVIDER_SCRIPT_PATH_SUFFIX := "/src/providers/camera_tracking_provider.gd"

var _tracking_frame_adapter_script: Variant = null

signal pose_updated(landmarks: Array)
signal multi_pose_updated(poses: Array)
signal tracking_lost()
signal tracking_restored()

signal straight_left(power: float)
signal straight_right(power: float)
signal straight_state_changed(side: String, state: String, detail: Dictionary)
signal hook_state_changed(side: String, state: String, detail: Dictionary)
signal uppercut_state_changed(side: String, state: String, detail: Dictionary)
signal uppercut_left(power: float)
signal uppercut_right(power: float)
signal hook_left(power: float)
signal hook_right(power: float)
signal left_wrist_cell_entered(cell: int, direction: int)
signal right_wrist_cell_entered(cell: int, direction: int)
signal nose_cell_entered(cell: int, direction: int)
signal calibration_session_updated(session: Dictionary)
signal body_grid_nose_updated(anchor: Dictionary)
signal body_grid_left_wrist_updated(anchor: Dictionary)
signal body_grid_right_wrist_updated(anchor: Dictionary)
signal body_grid_calibration_started(event: Dictionary)
signal body_grid_calibration_succeeded(event: Dictionary)
signal body_grid_calibration_failed(event: Dictionary)
signal body_grid_calibration_canceled(event: Dictionary)
signal guard_enabled()
signal guard_disabled()
signal squat_enabled()
signal squat_disabled()
signal weave_left_enabled()
signal weave_left_disabled()
signal weave_right_enabled()
signal weave_right_disabled()

@export var config = null
@export var manage_tracking_session_lifecycle := false

var _tracking_session = null
var _preview_surface: Node = null
var _detector_substrate: PoseDetectorSubstrate = null
var _landmarks: Dictionary = {}
var _all_poses: Array = []
var _last_tracking_frame: Dictionary = {}
var _last_tracking_frame_signature := ""
var _was_tracking := false
var _last_preview_descriptor: Dictionary = {}
var _body_grid_calibration_id: Variant = null
var _body_grid_calibration_sequence := 0
var _body_grid_calibration_state: Dictionary = {}
var _body_grid_anchors: Dictionary = {}
var _last_calibration_session_state := ""
var _last_success_captured_at_ms := 0

enum TrackingMode {
	MODE_2D,
	MODE_3D
}

const LANDMARK_LEFT_WRIST = PoseLandmarkIds.LEFT_WRIST
const LANDMARK_RIGHT_WRIST = PoseLandmarkIds.RIGHT_WRIST
const LANDMARK_NOSE = PoseLandmarkIds.NOSE
const LANDMARK_LEFT_ANKLE = PoseLandmarkIds.LEFT_ANKLE
const LANDMARK_RIGHT_ANKLE = PoseLandmarkIds.RIGHT_ANKLE

func _ready() -> void:
	config = _ensure_config()
	_ensure_detector_substrate()
	_reset_body_grid_runtime_cache(false)
	set_process(true)

func set_tracking_session(session) -> void:
	if _tracking_session == session:
		return
	_disconnect_tracking_session()
	_tracking_session = session
	_last_preview_descriptor = {}
	_connect_tracking_session()
	_sync_from_tracking_session()

func set_preview_surface(surface: Node) -> void:
	_preview_surface = surface
	if _tracking_session != null and _preview_surface != null and _tracking_session.has_method("attach_preview_surface"):
		_tracking_session.attach_preview_surface(_preview_surface)

func start() -> bool:
	if _tracking_session == null:
		return false
	if _preview_surface != null and _tracking_session.has_method("attach_preview_surface"):
		_tracking_session.attach_preview_surface(_preview_surface)
	if manage_tracking_session_lifecycle and _tracking_session.has_method("start"):
		_tracking_session.start(_build_tracking_config())
	_sync_from_tracking_session()
	return true

func stop(preserve_runtime_state: bool = false) -> void:
	if not preserve_runtime_state and _tracking_session != null and _tracking_session.has_method("detach_preview_surface"):
		_tracking_session.detach_preview_surface()
	if manage_tracking_session_lifecycle:
		_stop_tracking_session(preserve_runtime_state)
	if preserve_runtime_state:
		_sync_from_tracking_session()
		return
	reset_runtime_state()

func reset_runtime_state() -> void:
	_landmarks.clear()
	_all_poses.clear()
	_last_tracking_frame = {}
	_last_tracking_frame_signature = ""
	_last_preview_descriptor = {}
	_was_tracking = false
	if _detector_substrate != null:
		_detector_substrate.reset()
	_reset_body_grid_runtime_cache(true)

func start_calibration() -> bool:
	if _detector_substrate == null or not _detector_substrate.has_method("start_calibration"):
		return false
	_detector_substrate.start_calibration()
	_emit_body_grid_invalid_anchors()
	_emit_body_grid_calibration_event("started", get_calibration_session())
	_emit_calibration_session_updated()
	return true

func cancel_calibration() -> bool:
	if _detector_substrate == null or not _detector_substrate.has_method("cancel_calibration"):
		return false
	_detector_substrate.cancel_calibration()
	_emit_body_grid_invalid_anchors()
	_emit_body_grid_calibration_event("canceled", get_calibration_session())
	_emit_calibration_session_updated()
	return true

func get_calibration_session() -> Dictionary:
	if _detector_substrate == null or not _detector_substrate.has_method("get_calibration_session"):
		return {}
	return _detector_substrate.get_calibration_session()

func get_body_grid_nose() -> Dictionary:
	return (_body_grid_anchors.get("nose", _make_invalid_body_grid_anchor("nose")) as Dictionary).duplicate(true)

func get_body_grid_left_wrist() -> Dictionary:
	return (_body_grid_anchors.get("left_wrist", _make_invalid_body_grid_anchor("left_wrist")) as Dictionary).duplicate(true)

func get_body_grid_right_wrist() -> Dictionary:
	return (_body_grid_anchors.get("right_wrist", _make_invalid_body_grid_anchor("right_wrist")) as Dictionary).duplicate(true)

func get_body_grid_calibration_state() -> Dictionary:
	if _body_grid_calibration_state.is_empty():
		_body_grid_calibration_state = _make_body_grid_calibration_event("none", {})
	return _body_grid_calibration_state.duplicate(true)

func _emit_calibration_session_updated() -> void:
	calibration_session_updated.emit(get_calibration_session().duplicate(true))

func get_num_poses() -> int:
	return _all_poses.size()

func get_all_poses() -> Array:
	return _all_poses.duplicate(true)

func get_detector_state() -> Dictionary:
	if _detector_substrate == null:
		return {}
	return _detector_substrate.get_latest_state()

func get_detector_state_view() -> Dictionary:
	if _detector_substrate == null:
		return {}
	if _detector_substrate.has_method("get_latest_state_view"):
		return _detector_substrate.get_latest_state_view()
	return _detector_substrate.get_latest_state()

func get_body_measurements() -> Dictionary:
	if _detector_substrate == null:
		return {}
	return _detector_substrate.get_measurements()

func get_tracking_state() -> StringName:
	if _detector_substrate == null:
		return &"lost"
	return _detector_substrate.get_tracking_state()

func get_landmark_velocity_for_body_part(body_part: StringName) -> Vector3:
	if _detector_substrate == null:
		return Vector3.ZERO
	return _detector_substrate.get_velocity(body_part)

func get_landmark_position_for_pose(pose_idx: int, landmark_id: int, mode: TrackingMode = TrackingMode.MODE_2D) -> Variant:
	if pose_idx < 0 or pose_idx >= _all_poses.size():
		return null
	if pose_idx == 0:
		var primary_landmark := _landmarks.get(landmark_id, null)
		if primary_landmark is Dictionary and _passes_visibility_threshold(primary_landmark):
			return _convert_landmark_to_position(primary_landmark, mode)
	var pose_data: Variant = _all_poses[pose_idx]
	if not pose_data is Dictionary:
		return null
	var landmarks: Variant = pose_data.get("landmarks", [])
	if not landmarks is Array:
		return null
	for lm: Variant in landmarks:
		if lm is Dictionary and int(lm.get("id", -1)) == landmark_id and _passes_visibility_threshold(lm):
			return _convert_landmark_to_position(lm, mode)
	return null

func get_left_hand_position(mode: TrackingMode = TrackingMode.MODE_2D) -> Variant:
	return get_landmark_position_for_pose(0, LANDMARK_LEFT_WRIST, mode)

func get_right_hand_position(mode: TrackingMode = TrackingMode.MODE_2D) -> Variant:
	return get_landmark_position_for_pose(0, LANDMARK_RIGHT_WRIST, mode)

func get_head_position(mode: TrackingMode = TrackingMode.MODE_2D) -> Variant:
	return get_landmark_position_for_pose(0, LANDMARK_NOSE, mode)

func get_left_foot_position(mode: TrackingMode = TrackingMode.MODE_2D) -> Variant:
	return get_landmark_position_for_pose(0, LANDMARK_LEFT_ANKLE, mode)

func get_right_foot_position(mode: TrackingMode = TrackingMode.MODE_2D) -> Variant:
	return get_landmark_position_for_pose(0, LANDMARK_RIGHT_ANKLE, mode)

func get_player_left_hand(player_idx: int, mode: TrackingMode = TrackingMode.MODE_2D) -> Variant:
	return get_landmark_position_for_pose(player_idx, LANDMARK_LEFT_WRIST, mode)

func get_player_right_hand(player_idx: int, mode: TrackingMode = TrackingMode.MODE_2D) -> Variant:
	return get_landmark_position_for_pose(player_idx, LANDMARK_RIGHT_WRIST, mode)

func get_player_head(player_idx: int, mode: TrackingMode = TrackingMode.MODE_2D) -> Variant:
	return get_landmark_position_for_pose(player_idx, LANDMARK_NOSE, mode)

func set_tracking_mode(_mode: TrackingMode) -> void:
	pass

func get_available_camera_devices() -> Array:
	if _tracking_session == null or not _tracking_session.has_method("list_cameras"):
		return []
	var devices: Variant = _tracking_session.list_cameras()
	return devices.duplicate(true) if devices is Array else []

func get_selected_camera_device_id() -> String:
	var source := _get_tracking_source_config()
	if source.is_empty():
		return ""
	var source_kind := String(source.get("kind", "")).strip_edges()
	if source_kind == "video_file":
		return String(source.get("path", "")).strip_edges()
	return _get_live_camera_source_id(source)

func set_selected_camera_device_id(device_id: String) -> bool:
	if _tracking_session == null or not _tracking_session.has_method("get_active_config") or not _tracking_session.has_method("change"):
		return false
	var active_config: Variant = _tracking_session.get_active_config()
	if not active_config is Dictionary:
		return false
	var next_config: Dictionary = (active_config as Dictionary).duplicate(true)
	if not next_config.has("source") or not next_config["source"] is Dictionary:
		next_config["source"] = {}
	var source := next_config["source"] as Dictionary
	var source_kind := String(source.get("kind", "live_camera")).strip_edges()
	if source_kind == "video_file":
		return false
	source["kind"] = "live_camera"
	source["camera_id"] = device_id
	source["id"] = device_id
	_tracking_session.change(next_config)
	return true

func is_tracking() -> bool:
	var adapter_script := _ensure_tracking_frame_adapter_script()
	if adapter_script == null:
		return false
	return adapter_script.tracking_state_is_active(_last_tracking_frame)

func is_tracking_player(player_idx: int) -> bool:
	return player_idx >= 0 and player_idx < _all_poses.size() and not (_all_poses[player_idx] as Dictionary).get("landmarks", []).is_empty()

func ingest_tracking_frame(frame: Dictionary) -> void:
	var enriched_frame := _augment_tracking_frame_runtime_context(frame)
	_last_tracking_frame = enriched_frame.duplicate(true)
	var adapter_script := _ensure_tracking_frame_adapter_script()
	var frame_for_processing := _last_tracking_frame
	if adapter_script == null:
		_clear_tracking_runtime_state(false)
		_multi_pose_from_current_landmarks([])
		_emit_tracking_edge_signals(false)
		return
	var active: bool = bool(adapter_script.tracking_state_is_active(frame_for_processing))
	var preview_landmarks: Array = adapter_script.landmarks_from_tracking_frame(frame_for_processing)
	var gameplay_landmarks: Array = adapter_script.gameplay_landmarks_from_tracking_frame(frame_for_processing)
	if active and not gameplay_landmarks.is_empty():
		_process_primary_landmarks(gameplay_landmarks, false, false, adapter_script.get_timestamp_ms(frame_for_processing))
		_multi_pose_from_current_landmarks(preview_landmarks)
		pose_updated.emit(preview_landmarks.duplicate(true))
	else:
		_clear_tracking_runtime_state(active)
		_multi_pose_from_current_landmarks([])
	_emit_calibration_session_updated()
	_emit_tracking_edge_signals(active)

func _process(_delta: float) -> void:
	_poll_tracking_session_frame()

func _notification(what: int) -> void:
	if what == NOTIFICATION_EXIT_TREE:
		stop()
		_disconnect_tracking_session()

func _connect_tracking_session() -> void:
	if _tracking_session == null:
		return
	if _tracking_session.has_signal("tracking_updated") and not _tracking_session.tracking_updated.is_connected(_on_tracking_session_tracking_updated):
		_tracking_session.tracking_updated.connect(_on_tracking_session_tracking_updated)
	if _tracking_session.has_signal("state_changed") and not _tracking_session.state_changed.is_connected(_on_tracking_session_state_changed):
		_tracking_session.state_changed.connect(_on_tracking_session_state_changed)
	if _tracking_session.has_signal("preview_changed") and not _tracking_session.preview_changed.is_connected(_on_tracking_session_preview_changed):
		_tracking_session.preview_changed.connect(_on_tracking_session_preview_changed)

func _disconnect_tracking_session() -> void:
	if _tracking_session == null:
		return
	if _tracking_session.has_signal("tracking_updated") and _tracking_session.tracking_updated.is_connected(_on_tracking_session_tracking_updated):
		_tracking_session.tracking_updated.disconnect(_on_tracking_session_tracking_updated)
	if _tracking_session.has_signal("state_changed") and _tracking_session.state_changed.is_connected(_on_tracking_session_state_changed):
		_tracking_session.state_changed.disconnect(_on_tracking_session_state_changed)
	if _tracking_session.has_signal("preview_changed") and _tracking_session.preview_changed.is_connected(_on_tracking_session_preview_changed):
		_tracking_session.preview_changed.disconnect(_on_tracking_session_preview_changed)

func _sync_from_tracking_session() -> void:
	_poll_tracking_session_frame(true)

func _poll_tracking_session_frame(force: bool = false) -> void:
	if _tracking_session == null or not _tracking_session.has_method("get_tracking_frame"):
		return
	var frame: Variant = _tracking_session.get_tracking_frame()
	if not frame is Dictionary:
		return
	var frame_dict: Dictionary = _augment_tracking_frame_runtime_context(frame)
	var signature := _build_tracking_frame_signature(frame_dict)
	if not force and signature == _last_tracking_frame_signature:
		return
	_last_tracking_frame_signature = signature
	ingest_tracking_frame(frame_dict)

func _build_tracking_frame_signature(frame: Dictionary) -> String:
	var raw_landmarks: Variant = frame.get("landmarks", [])
	var landmark_count: int = raw_landmarks.size() if raw_landmarks is Array else 0
	var preview_descriptor: Dictionary = frame.get("preview_descriptor", {}) if frame.get("preview_descriptor", {}) is Dictionary else {}
	return "%s|%s|%s|%d|%s|%s|%s" % [
		str(frame.get("timestamp_ms", "")),
		str(frame.get("frame_index", "")),
		str(frame.get("tracking_state", "")),
		landmark_count,
		str(frame.get("source_id", "")),
		str(frame.get("preview_image_path", preview_descriptor.get("image_path", ""))),
		str(preview_descriptor.get("image_revision", "")),
	]

func _build_tracking_config() -> Dictionary:
	var active_config = _ensure_config()
	var source_id := String(active_config.get_camera_source()).strip_edges() if active_config != null and active_config.has_method("get_camera_source") else ""
	var source_kind := "live_camera"
	var source_payload: Dictionary = {
		"kind": source_kind,
		"camera_id": source_id,
	}
	if not source_id.is_empty() and not source_id.is_valid_int() and not source_id.begins_with("/dev/video"):
		source_kind = "video_file"
		source_payload = {
			"kind": source_kind,
			"path": source_id,
		}
	var tracking_fields := {
		"overlay_mode": String(active_config.tracking_overlay_mode).strip_edges() if active_config != null else "optimized",
		"gesture_eval_interval_frames": int(active_config.gesture_eval_interval_frames) if active_config != null else 1,
		"min_visibility": float(active_config.min_visibility) if active_config != null else 0.35,
	}
	var preview_fields: Dictionary = {
		"surface_mode": "attach",
		"flip_horizontal": bool(active_config.flip_horizontal) if active_config != null else true,
	}
	if active_config != null and active_config.has_method("get_selected_profile_bundle"):
		var profile_bundle: Variant = active_config.get_selected_profile_bundle()
		if profile_bundle is Dictionary and bool(profile_bundle.get("ok", false)):
			var tracker_profile: Variant = profile_bundle.get("camera_tracking", {})
			if tracker_profile is Dictionary:
				var tracker_source: Variant = (tracker_profile as Dictionary).get("source", {})
				if tracker_source is Dictionary:
					var live_camera_source: Variant = (tracker_source as Dictionary).get("live_camera", {})
					if live_camera_source is Dictionary and not live_camera_source.is_empty():
						source_payload["live_camera"] = (live_camera_source as Dictionary).duplicate(true)
				var tracker_tracking: Variant = (tracker_profile as Dictionary).get("tracking", {})
				if tracker_tracking is Dictionary:
					if (tracker_tracking as Dictionary).has("max_fps"):
						tracking_fields["max_fps"] = int((tracker_tracking as Dictionary).get("max_fps", 0))
					if (tracker_tracking as Dictionary).has("state_update_max_fps"):
						tracking_fields["state_update_max_fps"] = int((tracker_tracking as Dictionary).get("state_update_max_fps", 0))
					var pose_config: Variant = (tracker_tracking as Dictionary).get("pose", {})
					if pose_config is Dictionary and not pose_config.is_empty():
						tracking_fields["pose"] = (pose_config as Dictionary).duplicate(true)
					var hands_config: Variant = (tracker_tracking as Dictionary).get("hands", {})
					if hands_config is Dictionary and not hands_config.is_empty():
						tracking_fields["hands"] = (hands_config as Dictionary).duplicate(true)
				var tracker_preview: Variant = (tracker_profile as Dictionary).get("preview", {})
				if tracker_preview is Dictionary and not tracker_preview.is_empty():
					preview_fields = (tracker_preview as Dictionary).duplicate(true)
					if not preview_fields.has("surface_mode"):
						preview_fields["surface_mode"] = "attach"
					if not preview_fields.has("flip_horizontal"):
						preview_fields["flip_horizontal"] = bool(active_config.flip_horizontal) if active_config != null else true
	var tracking_config := {
		"backend": "camera_tracking_default",
		"source": source_payload,
		"tracking": tracking_fields,
		"preview": preview_fields,
	}
	if active_config != null:
		var runtime_config: Variant = active_config.get("runtime")
		if runtime_config is Dictionary and not runtime_config.is_empty():
			tracking_config["runtime"] = (runtime_config as Dictionary).duplicate(true)
		var diagnostics_config: Variant = active_config.get("diagnostics")
		if diagnostics_config is Dictionary and not diagnostics_config.is_empty():
			tracking_config["diagnostics"] = (diagnostics_config as Dictionary).duplicate(true)
		var vendor_config: Variant = active_config.get("vendor")
		if vendor_config is Dictionary and not vendor_config.is_empty():
			tracking_config["vendor"] = (vendor_config as Dictionary).duplicate(true)
	return tracking_config

func _get_tracking_source_config() -> Dictionary:
	if _tracking_session == null or not _tracking_session.has_method("get_active_config"):
		return {}
	var active_config: Variant = _tracking_session.get_active_config()
	if not active_config is Dictionary:
		return {}
	var source: Variant = active_config.get("source", {})
	return source.duplicate(true) if source is Dictionary else {}

func _stop_tracking_session(preserve_runtime_state: bool) -> void:
	if _tracking_session == null:
		return
	if preserve_runtime_state:
		if _tracking_session.has_method("stop_preserving_runtime_state"):
			_tracking_session.stop_preserving_runtime_state()
			return
		var backend: Variant = _tracking_session.get("_backend") if _tracking_session.has_method("get") else null
		if backend != null and is_instance_valid(backend) and backend.has_method("stop_preserving_runtime_state"):
			backend.stop_preserving_runtime_state()
			return
	if _tracking_session.has_method("stop"):
		_tracking_session.stop()

func _get_live_camera_source_id(source: Dictionary) -> String:
	var camera_id := String(source.get("camera_id", "")).strip_edges()
	if not camera_id.is_empty():
		return camera_id
	var legacy_id := String(source.get("id", "")).strip_edges()
	if not legacy_id.is_empty():
		return legacy_id
	return String(source.get("path", "")).strip_edges()

func _ensure_detector_substrate() -> void:
	var active_config: Variant = _ensure_config()
	if _detector_substrate != null:
		_detector_substrate.configure(active_config)
		return
	_detector_substrate = PoseDetectorSubstrate.new().configure(active_config)

func _ensure_tracking_frame_adapter_script() -> Variant:
	if _tracking_frame_adapter_script != null:
		return _tracking_frame_adapter_script
	_tracking_frame_adapter_script = _load_repo_src_script("tracking_frame_adapter.gd")
	return _tracking_frame_adapter_script

func _ensure_config() -> Variant:
	if config != null:
		return config
	var config_script: Variant = _load_repo_src_script("config/camera_tracking_config.gd")
	if config_script == null:
		return null
	config = config_script.new()
	return config

func _load_repo_src_script(relative_path: String) -> Variant:
	var script_path := _get_repo_src_root_path().path_join(relative_path)
	return load(script_path)

func _get_repo_src_root_path() -> String:
	var script_resource: Variant = get_script()
	if script_resource == null:
		return "res://src"
	var resource_path := String(script_resource.resource_path)
	if resource_path.ends_with(PROVIDER_SCRIPT_PATH_SUFFIX):
		return resource_path.substr(0, resource_path.length() - "providers/camera_tracking_provider.gd".length())
	var parent_dir := resource_path.get_base_dir()
	return parent_dir.get_base_dir()

func _process_primary_landmarks(landmarks: Array, emit_signal_flag: bool, overwrite_all_poses: bool, timestamp_ms: int = 0) -> void:
	_ensure_detector_substrate()
	var state: Dictionary = {}
	if _detector_substrate != null:
		state = _detector_substrate.process_landmarks(landmarks, timestamp_ms, _last_tracking_frame)
		_landmarks = state.get("landmarks_by_id", {}).duplicate(true)
		_sync_body_grid_calibration_lifecycle(state.get("calibration_session", {}))
		_emit_body_grid_anchors_from_substrate(int(state.get("timestamp_ms", timestamp_ms)))
		_emit_detector_events(state.get("events", []))
	else:
		_landmarks.clear()
		for landmark: Variant in landmarks:
			if landmark is Dictionary:
				_landmarks[int(landmark.get("id", 0))] = landmark.duplicate(true)
	if overwrite_all_poses:
		_all_poses = [{
			"pose_id": 0,
			"landmarks": landmarks.duplicate(true),
		}]
	if emit_signal_flag:
		pose_updated.emit(landmarks.duplicate(true))

func _multi_pose_from_current_landmarks(landmarks: Array) -> void:
	if landmarks.is_empty():
		_all_poses = []
	else:
		_all_poses = [{
			"pose_id": 0,
			"landmarks": landmarks.duplicate(true),
		}]
	multi_pose_updated.emit(_all_poses.duplicate(true))

func _clear_tracking_runtime_state(active: bool) -> void:
	_landmarks.clear()
	if _detector_substrate != null and not active:
		_detector_substrate.mark_tracking_timeout(Time.get_ticks_msec() + 1000)
		_emit_body_grid_invalid_anchors()
		var session := _detector_substrate.get_calibration_session()
		if bool(session.get("is_active", false)):
			_emit_body_grid_calibration_event("failed", session)
	pose_updated.emit([])

func _emit_tracking_edge_signals(active: bool) -> void:
	if active and not _was_tracking:
		tracking_restored.emit()
	elif not active and _was_tracking:
		tracking_lost.emit()
	_was_tracking = active

func _emit_detector_events(events: Array) -> void:
	for event_variant: Variant in events:
		if not event_variant is Dictionary:
			continue
		var event_data: Dictionary = event_variant
		var event_name := StringName(event_data.get("name", StringName()))
		if event_name == StringName():
			continue
		match String(event_name):
			"straight_left":
				straight_left.emit(float(event_data.get("power", 0.0)))
			"straight_right":
				straight_right.emit(float(event_data.get("power", 0.0)))
			"straight_state_changed":
				var detail := event_data.duplicate(true)
				detail.erase("name")
				straight_state_changed.emit(String(event_data.get("side", "")), String(event_data.get("state", "")), detail)
			"hook_state_changed":
				var hook_detail := event_data.duplicate(true)
				hook_detail.erase("name")
				hook_state_changed.emit(String(event_data.get("side", "")), String(event_data.get("state", "")), hook_detail)
			"uppercut_state_changed":
				var uppercut_detail := event_data.duplicate(true)
				uppercut_detail.erase("name")
				uppercut_state_changed.emit(String(event_data.get("side", "")), String(event_data.get("state", "")), uppercut_detail)
			"uppercut_left":
				uppercut_left.emit(float(event_data.get("power", 0.0)))
			"uppercut_right":
				uppercut_right.emit(float(event_data.get("power", 0.0)))
			"hook_left":
				hook_left.emit(float(event_data.get("power", 0.0)))
			"hook_right":
				hook_right.emit(float(event_data.get("power", 0.0)))
			"left_wrist_cell_entered":
				left_wrist_cell_entered.emit(int(event_data.get("cell", -1)), int(event_data.get("direction", -1)))
			"right_wrist_cell_entered":
				right_wrist_cell_entered.emit(int(event_data.get("cell", -1)), int(event_data.get("direction", -1)))
			"nose_cell_entered":
				nose_cell_entered.emit(int(event_data.get("cell", -1)), int(event_data.get("direction", -1)))
			"guard_enabled":
				guard_enabled.emit()
			"guard_disabled":
				guard_disabled.emit()
			"squat_enabled":
				squat_enabled.emit()
			"squat_disabled":
				squat_disabled.emit()
			"weave_left_enabled":
				weave_left_enabled.emit()
			"weave_left_disabled":
				weave_left_disabled.emit()
			"weave_right_enabled":
				weave_right_enabled.emit()
			"weave_right_disabled":
				weave_right_disabled.emit()

func _reset_body_grid_runtime_cache(emit_invalid: bool) -> void:
	_body_grid_calibration_state = _make_body_grid_calibration_event("none", {})
	_last_calibration_session_state = ""
	_last_success_captured_at_ms = 0
	_body_grid_anchors = {
		"nose": _make_invalid_body_grid_anchor("nose"),
		"left_wrist": _make_invalid_body_grid_anchor("left_wrist"),
		"right_wrist": _make_invalid_body_grid_anchor("right_wrist"),
	}
	if emit_invalid:
		_emit_body_grid_invalid_anchors()

func _emit_body_grid_anchors_from_substrate(timestamp_ms: int) -> void:
	if _detector_substrate == null or not _detector_substrate.has_method("get_body_grid_anchors"):
		_emit_body_grid_invalid_anchors(timestamp_ms)
		return
	var anchors: Dictionary = _detector_substrate.get_body_grid_anchors(_body_grid_calibration_id, timestamp_ms)
	_store_and_emit_body_grid_anchor("nose", anchors.get("nose", _make_invalid_body_grid_anchor("nose", timestamp_ms)))
	_store_and_emit_body_grid_anchor("left_wrist", anchors.get("left_wrist", _make_invalid_body_grid_anchor("left_wrist", timestamp_ms)))
	_store_and_emit_body_grid_anchor("right_wrist", anchors.get("right_wrist", _make_invalid_body_grid_anchor("right_wrist", timestamp_ms)))

func _emit_body_grid_invalid_anchors(timestamp_ms: int = 0) -> void:
	_store_and_emit_body_grid_anchor("nose", _make_invalid_body_grid_anchor("nose", timestamp_ms))
	_store_and_emit_body_grid_anchor("left_wrist", _make_invalid_body_grid_anchor("left_wrist", timestamp_ms))
	_store_and_emit_body_grid_anchor("right_wrist", _make_invalid_body_grid_anchor("right_wrist", timestamp_ms))

func _store_and_emit_body_grid_anchor(anchor_name: String, anchor_variant: Variant) -> void:
	var anchor: Dictionary = anchor_variant.duplicate(true) if anchor_variant is Dictionary else _make_invalid_body_grid_anchor(anchor_name)
	_body_grid_anchors[anchor_name] = anchor.duplicate(true)
	match anchor_name:
		"nose":
			body_grid_nose_updated.emit(anchor.duplicate(true))
		"left_wrist":
			body_grid_left_wrist_updated.emit(anchor.duplicate(true))
		"right_wrist":
			body_grid_right_wrist_updated.emit(anchor.duplicate(true))

func _sync_body_grid_calibration_lifecycle(session_variant: Variant) -> void:
	if not session_variant is Dictionary:
		return
	var session: Dictionary = session_variant
	var state_name := String(session.get("state", "")).strip_edges().to_lower()
	var captured_at_ms := int(session.get("captured_at_ms", 0))
	if state_name == "succeeded" and captured_at_ms > 0 and captured_at_ms != _last_success_captured_at_ms:
		_body_grid_calibration_sequence += 1
		_body_grid_calibration_id = "camera_tracking:%d:%d" % [captured_at_ms, _body_grid_calibration_sequence]
		_last_success_captured_at_ms = captured_at_ms
		_emit_body_grid_calibration_event("succeeded", session)
	elif state_name == "cancelled" and _last_calibration_session_state != "cancelled":
		_emit_body_grid_calibration_event("canceled", session)
	_last_calibration_session_state = state_name

func _emit_body_grid_calibration_event(state_name: String, session: Dictionary = {}) -> void:
	var event := _make_body_grid_calibration_event(state_name, session)
	_body_grid_calibration_state = event.duplicate(true)
	if state_name == "canceled":
		_last_calibration_session_state = "cancelled"
	elif state_name == "failed":
		_last_calibration_session_state = "failed"
	elif state_name == "started":
		_last_calibration_session_state = String(session.get("state", "waiting")).strip_edges().to_lower()
	match state_name:
		"started":
			body_grid_calibration_started.emit(event.duplicate(true))
		"succeeded":
			body_grid_calibration_succeeded.emit(event.duplicate(true))
		"failed":
			body_grid_calibration_failed.emit(event.duplicate(true))
		"canceled":
			body_grid_calibration_canceled.emit(event.duplicate(true))

func _make_body_grid() -> Dictionary:
	return {
		"columns": 4,
		"rows": 3,
		"origin": "top_left",
		"indexing": "row_major",
	}

func _make_invalid_body_grid_anchor(anchor_name: String, timestamp_ms: int = 0) -> Dictionary:
	return {
		"schema": "aerobeat/body_grid_anchor",
		"version": 1,
		"anchor": anchor_name,
		"valid": false,
		"calibration_id": _body_grid_calibration_id,
		"timestamp_ms": timestamp_ms,
		"grid": _make_body_grid(),
		"raw_x": null,
		"raw_y": null,
		"x": null,
		"y": null,
		"cell": null,
		"row": null,
		"column": null,
	}

func _make_body_grid_calibration_event(state_name: String, session: Dictionary = {}) -> Dictionary:
	return {
		"schema": "aerobeat/body_grid_calibration_event",
		"version": 1,
		"state": state_name,
		"calibration_id": _body_grid_calibration_id,
		"captured_at_ms": int(session.get("captured_at_ms", 0)) if int(session.get("captured_at_ms", 0)) > 0 else null,
		"grid": _make_body_grid(),
		"session": session.duplicate(true),
	}

func _augment_tracking_frame_runtime_context(frame: Dictionary) -> Dictionary:
	var enriched := frame.duplicate(true)
	var preview_descriptor := _get_tracking_session_preview_descriptor()
	if not preview_descriptor.is_empty():
		enriched["preview_descriptor"] = preview_descriptor.duplicate(true)
		var preview_image_path := String(preview_descriptor.get("image_path", "")).strip_edges()
		if not preview_image_path.is_empty():
			enriched["preview_image_path"] = preview_image_path
			if String(enriched.get("image_path", "")).strip_edges().is_empty():
				enriched["image_path"] = preview_image_path
	return enriched

func _get_tracking_session_preview_descriptor() -> Dictionary:
	if _tracking_session == null or not _tracking_session.has_method("get_preview_descriptor"):
		return _last_preview_descriptor.duplicate(true)
	var descriptor: Variant = _tracking_session.get_preview_descriptor()
	if descriptor is Dictionary:
		_last_preview_descriptor = (descriptor as Dictionary).duplicate(true)
	return _last_preview_descriptor.duplicate(true)

func _passes_visibility_threshold(landmark: Dictionary) -> bool:
	var active_config := _ensure_config()
	if active_config == null:
		return true
	return float(landmark.get("v", 1.0)) >= float(active_config.min_visibility)

func _convert_landmark_to_position(lm: Dictionary, mode: TrackingMode) -> Variant:
	var x := float(lm.get("x", 0.0))
	var y := float(lm.get("y", 0.0))
	var z := float(lm.get("z", 0.0))
	if mode == TrackingMode.MODE_2D:
		return Vector2(x, y)
	return Vector3(x, y, z)

func _on_tracking_session_tracking_updated(frame: Dictionary) -> void:
	ingest_tracking_frame(frame)

func _on_tracking_session_state_changed(_state: String, _detail: Dictionary) -> void:
	_sync_from_tracking_session()

func _on_tracking_session_preview_changed(descriptor: Dictionary) -> void:
	_last_preview_descriptor = descriptor.duplicate(true)
	_poll_tracking_session_frame(true)
