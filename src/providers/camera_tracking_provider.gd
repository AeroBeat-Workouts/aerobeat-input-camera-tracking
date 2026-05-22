class_name CameraTrackingProvider
extends Node
## Contract-driven detector provider that consumes normalized CameraTracking frames.
##
## First migration-slice scope:
## - owns Boxing + Flow interpretation only
## - consumes upstream tracking frames instead of vendor/server payloads
## - can attach/detach preview surfaces through CameraTracking when a session is supplied
## - does not require this repo to own the camera runtime lifecycle

const TrackingFrameAdapterScript = preload("res://addons/aerobeat-input-camera-tracking/src/tracking_frame_adapter.gd")

signal pose_updated(landmarks: Array)
signal multi_pose_updated(poses: Array)
signal tracking_lost()
signal tracking_restored()

signal punch_left(power: float)
signal punch_right(power: float)
signal uppercut_left(power: float)
signal uppercut_right(power: float)
signal hook_left(power: float)
signal hook_right(power: float)
signal swing_left(placement: int, direction: int)
signal swing_right(placement: int, direction: int)
signal trail_left(placement: int, direction: int)
signal trail_right(placement: int, direction: int)
signal guard_start()
signal guard_end()
signal squat_start()
signal squat_end()
signal weave_left_start()
signal weave_left_end()
signal weave_right_start()
signal weave_right_end()
signal sidestep_left_start()
signal sidestep_left_end()
signal sidestep_right_start()
signal sidestep_right_end()
signal knee_left(power: float)
signal knee_right(power: float)
signal leg_lift_left_start()
signal leg_lift_left_end()
signal leg_lift_right_start()
signal leg_lift_right_end()

@export var config = null
@export var manage_tracking_session_lifecycle := false

var _tracking_session = null
var _preview_surface: Node = null
var _detector_substrate: PoseDetectorSubstrate = null
var _landmarks: Dictionary = {}
var _all_poses: Array = []
var _last_tracking_frame: Dictionary = {}
var _was_tracking := false

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

func set_tracking_session(session) -> void:
	if _tracking_session == session:
		return
	_disconnect_tracking_session()
	_tracking_session = session
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

func stop() -> void:
	if _tracking_session != null and _tracking_session.has_method("detach_preview_surface"):
		_tracking_session.detach_preview_surface()
	if manage_tracking_session_lifecycle and _tracking_session != null and _tracking_session.has_method("stop"):
		_tracking_session.stop()
	reset_runtime_state()

func reset_runtime_state() -> void:
	_landmarks.clear()
	_all_poses.clear()
	_last_tracking_frame = {}
	_was_tracking = false
	if _detector_substrate != null:
		_detector_substrate.reset()

func get_num_poses() -> int:
	return _all_poses.size()

func get_all_poses() -> Array:
	return _all_poses.duplicate(true)

func get_detector_state() -> Dictionary:
	if _detector_substrate == null:
		return {}
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
	if _tracking_session == null or not _tracking_session.has_method("get_active_config"):
		return ""
	var active_config: Variant = _tracking_session.get_active_config()
	if not active_config is Dictionary:
		return ""
	var source: Dictionary = active_config.get("source", {})
	return String(source.get("camera_id", "")).strip_edges()

func set_selected_camera_device_id(device_id: String) -> bool:
	if _tracking_session == null or not _tracking_session.has_method("get_active_config") or not _tracking_session.has_method("change"):
		return false
	var active_config: Variant = _tracking_session.get_active_config()
	if not active_config is Dictionary:
		return false
	var next_config: Dictionary = (active_config as Dictionary).duplicate(true)
	if not next_config.has("source") or not next_config["source"] is Dictionary:
		next_config["source"] = {}
	(next_config["source"] as Dictionary)["kind"] = "live_camera"
	(next_config["source"] as Dictionary)["camera_id"] = device_id
	_tracking_session.change(next_config)
	return true

func is_tracking() -> bool:
	return TrackingFrameAdapterScript.tracking_state_is_active(_last_tracking_frame)

func is_tracking_player(player_idx: int) -> bool:
	return player_idx >= 0 and player_idx < _all_poses.size() and not (_all_poses[player_idx] as Dictionary).get("landmarks", []).is_empty()

func ingest_tracking_frame(frame: Dictionary) -> void:
	_last_tracking_frame = frame.duplicate(true)
	var active := TrackingFrameAdapterScript.tracking_state_is_active(frame)
	var normalized_landmarks: Array = TrackingFrameAdapterScript.landmarks_from_tracking_frame(frame)
	if active and not normalized_landmarks.is_empty():
		_process_primary_landmarks(normalized_landmarks, true, true, TrackingFrameAdapterScript.get_timestamp_ms(frame))
	else:
		_clear_tracking_runtime_state(active)
	_multi_pose_from_current_landmarks(normalized_landmarks)
	_emit_tracking_edge_signals(active)

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

func _disconnect_tracking_session() -> void:
	if _tracking_session == null:
		return
	if _tracking_session.has_signal("tracking_updated") and _tracking_session.tracking_updated.is_connected(_on_tracking_session_tracking_updated):
		_tracking_session.tracking_updated.disconnect(_on_tracking_session_tracking_updated)
	if _tracking_session.has_signal("state_changed") and _tracking_session.state_changed.is_connected(_on_tracking_session_state_changed):
		_tracking_session.state_changed.disconnect(_on_tracking_session_state_changed)

func _sync_from_tracking_session() -> void:
	if _tracking_session == null or not _tracking_session.has_method("get_tracking_frame"):
		return
	var frame: Variant = _tracking_session.get_tracking_frame()
	if frame is Dictionary:
		ingest_tracking_frame(frame)

func _build_tracking_config() -> Dictionary:
	var active_config = _ensure_config()
	var source_id := String(active_config.get_camera_source()).strip_edges() if active_config != null and active_config.has_method("get_camera_source") else ""
	return {
		"backend": "mediapipe_python",
		"source": {
			"kind": "live_camera",
			"camera_id": source_id,
		},
		"tracking": {
			"overlay_mode": String(active_config.tracking_overlay_mode).strip_edges() if active_config != null else "optimized",
			"gesture_eval_interval_frames": int(active_config.gesture_eval_interval_frames) if active_config != null else 1,
			"min_visibility": float(active_config.min_visibility) if active_config != null else 0.35,
		},
		"preview": {
			"enabled": true,
			"surface_mode": "attach",
			"flip_horizontal": bool(active_config.flip_horizontal) if active_config != null else true,
		}
	}

func _ensure_detector_substrate() -> void:
	if _detector_substrate != null:
		return
	_detector_substrate = PoseDetectorSubstrate.new().configure(_ensure_config())

func _ensure_config() -> Variant:
	if config != null:
		return config
	var config_script: Variant = load("res://addons/aerobeat-input-camera-tracking/src/config/mediapipe_config.gd")
	if config_script == null:
		return null
	config = config_script.new()
	return config

func _process_primary_landmarks(landmarks: Array, emit_signal_flag: bool, overwrite_all_poses: bool, timestamp_ms: int = 0) -> void:
	_ensure_detector_substrate()
	var state: Dictionary = {}
	if _detector_substrate != null:
		state = _detector_substrate.process_landmarks(landmarks, timestamp_ms)
		_landmarks = state.get("landmarks_by_id", {}).duplicate(true)
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
			"punch_left":
				punch_left.emit(float(event_data.get("power", 0.0)))
			"punch_right":
				punch_right.emit(float(event_data.get("power", 0.0)))
			"uppercut_left":
				uppercut_left.emit(float(event_data.get("power", 0.0)))
			"uppercut_right":
				uppercut_right.emit(float(event_data.get("power", 0.0)))
			"hook_left":
				hook_left.emit(float(event_data.get("power", 0.0)))
			"hook_right":
				hook_right.emit(float(event_data.get("power", 0.0)))
			"swing_left":
				swing_left.emit(int(event_data.get("placement", -1)), int(event_data.get("direction", -1)))
			"swing_right":
				swing_right.emit(int(event_data.get("placement", -1)), int(event_data.get("direction", -1)))
			"trail_left":
				trail_left.emit(int(event_data.get("placement", -1)), int(event_data.get("direction", -1)))
			"trail_right":
				trail_right.emit(int(event_data.get("placement", -1)), int(event_data.get("direction", -1)))
			"guard_start":
				guard_start.emit()
			"guard_end":
				guard_end.emit()
			"squat_start":
				squat_start.emit()
			"squat_end":
				squat_end.emit()
			"weave_left_start":
				weave_left_start.emit()
			"weave_left_end":
				weave_left_end.emit()
			"weave_right_start":
				weave_right_start.emit()
			"weave_right_end":
				weave_right_end.emit()
			"sidestep_left_start":
				sidestep_left_start.emit()
			"sidestep_left_end":
				sidestep_left_end.emit()
			"sidestep_right_start":
				sidestep_right_start.emit()
			"sidestep_right_end":
				sidestep_right_end.emit()
			"knee_left":
				knee_left.emit(float(event_data.get("power", 0.0)))
			"knee_right":
				knee_right.emit(float(event_data.get("power", 0.0)))
			"leg_lift_left_start":
				leg_lift_left_start.emit()
			"leg_lift_left_end":
				leg_lift_left_end.emit()
			"leg_lift_right_start":
				leg_lift_right_start.emit()
			"leg_lift_right_end":
				leg_lift_right_end.emit()

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
