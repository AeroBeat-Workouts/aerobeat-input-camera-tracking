extends "res://addons/aerobeat-input-core/src/interfaces/boxing_input.gd"
## Assembly-facing AeroInputProvider adapter for this addon.
##
## This addon entrypoint is for consuming projects that mount this repo under
## the live assembly addon alias `res://addons/aerobeat-input-mediapipe/`
## alongside `aerobeat-input-core`.
##
## Current truthful scope:
## - prefers a supplied/discoverable CameraTracking session and routes gameplay-facing
##   behavior through CameraTrackingProvider when that contract lane is available
## - preserves provider-session-registry publication from this adapter for current
##   input-core compatibility
## - keeps a clearly provisional legacy MediaPipe fallback only when no CameraTracking
##   session is available yet
## - does not reclaim upstream runtime/backend/preview ownership in the contract lane

const PROVIDER_ID := "mediapipe_python"
const PROVIDER_SESSION_REGISTRY_PATH := "res://addons/aerobeat-input-core/src/runtime/provider_session_registry.gd"
const SHARED_SESSION_OWNER_PREFIX := "aerobeat-input-camera-tracking:input_provider"
const SHARED_SESSION_KEY := "mediapipe_python"
const TRACKING_SESSION_NODE_NAME := "CameraTracking"
const TRACKING_SINGLETON_NODE_NAME := "AeroCameraTracking"
const PROVIDER_LANE_CAMERA_TRACKING := "camera_tracking"
const PROVIDER_LANE_LEGACY_MEDIAPIPE := "legacy_mediapipe"

signal swing_left(placement: int, direction: int)
signal swing_right(placement: int, direction: int)
signal trail_left(placement: int, direction: int)
signal trail_right(placement: int, direction: int)
signal weave_left_start()
signal weave_left_end()
signal weave_right_start()
signal weave_right_end()

var _provider = null
var _config = null
var _tracking_session = null
var _provider_lane := ""
var _tracking_mode: TrackingMode = TrackingMode.MODE_2D
var _body_track_flags: int = BodyTrackFlags.ALL
var _published_session_key := ""
var _published_session_owner_id := ""
var _available_camera_devices: Array = []

func request_shared_session(request: Dictionary = {}) -> Dictionary:
	var registry = _load_provider_session_registry()
	if registry == null:
		return {}
	return registry.request_session(_with_default_shared_session_request(request))

func acquire_shared_session(consumer_id: String, request: Dictionary = {}) -> Dictionary:
	var registry = _load_provider_session_registry()
	if registry == null:
		return {}
	return registry.acquire_session(consumer_id, _with_default_shared_session_request(request))

func release_shared_session(consumer_id: String, session_key: String = "") -> Dictionary:
	var registry = _load_provider_session_registry()
	if registry == null:
		return {}
	var target_session_key := String(session_key).strip_edges()
	if target_session_key.is_empty():
		target_session_key = _published_session_key
	return registry.release_session(consumer_id, target_session_key)

func get_shared_session_debug_state() -> Dictionary:
	var session_role := "inactive"
	if not _published_session_key.is_empty():
		session_role = "owned"
	var source_identity := _shared_session_source_identity()
	var source_kind := _shared_session_source_kind()
	return {
		"registry_available": _provider_session_registry_available(),
		"session_role": session_role,
		"session_key": _published_session_key,
		"owner_id": _published_session_owner_id,
		"borrowed": false,
		"provider_live": _provider != null and is_instance_valid(_provider),
		"provider_id": PROVIDER_ID,
		"provider_lane": _provider_lane,
		"runtime_mode": _shared_session_runtime_mode(),
		"source_kind": source_kind,
		"camera_source": source_identity,
		"fixture_video_path": source_identity if source_kind == "video_file" else "",
		"min_visibility": _shared_session_min_visibility(),
		"tracking_overlay_mode": _shared_session_tracking_overlay_mode(),
		"gesture_eval_interval_frames": _shared_session_gesture_eval_interval_frames(),
	}

func _ready() -> void:
	_tracking_session = _resolve_tracking_session()
	_ensure_provider()

func set_tracking_session(session) -> void:
	_tracking_session = session
	_ensure_provider()
	if _provider != null and _provider.has_method("set_tracking_session"):
		_provider.set_tracking_session(session)
	_refresh_available_camera_devices()
	_republish_shared_session_if_needed()

func clear_tracking_session() -> void:
	set_tracking_session(null)

func get_tracking_session():
	return _resolve_tracking_session()

func uses_camera_tracking_contract_path() -> bool:
	return _provider_lane == PROVIDER_LANE_CAMERA_TRACKING

func is_using_legacy_fallback() -> bool:
	return _provider_lane == PROVIDER_LANE_LEGACY_MEDIAPIPE

func start(settings_json: String = "") -> bool:
	_ensure_provider()
	_apply_settings(settings_json)
	if _provider == null:
		failed.emit("Input provider could not resolve an implementation")
		return false
	var success: bool = bool(_provider.start())
	if success:
		_publish_shared_session_if_possible()
		_refresh_available_camera_devices()
		camera_devices_changed.emit(get_available_camera_devices(), get_selected_camera_device_id())
		started.emit()
	else:
		var failure_reason := "CameraTracking provider failed to start" if uses_camera_tracking_contract_path() else "MediaPipe provider failed to start"
		failed.emit(failure_reason)
	return success

func stop() -> void:
	_unpublish_shared_session_if_needed()
	if _provider == null:
		return
	_provider.stop()
	stopped.emit()

func is_tracking() -> bool:
	return _provider != null and _provider.is_tracking()

func get_provider_id() -> String:
	return PROVIDER_ID

func has_capability(capability: Capability) -> bool:
	match capability:
		Capability.GESTURE_RECOGNITION, Capability.LOWER_BODY, Capability.VELOCITY:
			return true
		_:
			return false

func trigger_haptic(_side: int, _intensity: float, _duration_ms: int) -> void:
	# No haptics in the Python/camera implementation.
	pass

func get_available_camera_devices() -> Array:
	return _available_camera_devices.duplicate(true)

func get_selected_camera_device_id() -> String:
	if _provider != null and _provider.has_method("get_selected_camera_device_id"):
		var selected := String(_provider.get_selected_camera_device_id()).strip_edges()
		if not selected.is_empty():
			return selected
	if _config == null:
		return ""
	return String(_config.get_camera_source()).strip_edges()

func set_selected_camera_device_id(device_id: String) -> bool:
	_ensure_provider()
	if _config == null:
		return false
	_config.set_selected_camera_device_id(device_id)
	var ok: bool = _provider != null and _provider.has_method("set_selected_camera_device_id") and bool(_provider.set_selected_camera_device_id(device_id))
	_refresh_available_camera_devices()
	_republish_shared_session_if_needed()
	camera_devices_changed.emit(get_available_camera_devices(), get_selected_camera_device_id())
	return ok

func get_head_position(mode: TrackingMode = TrackingMode.MODE_2D) -> Vector3:
	return _to_vector3(_provider.get_head_position(_to_provider_mode(mode))) if _provider != null else Vector3.ZERO

func get_left_hand_position(mode: TrackingMode = TrackingMode.MODE_2D) -> Vector3:
	return _to_vector3(_provider.get_left_hand_position(_to_provider_mode(mode))) if _provider != null else Vector3.ZERO

func get_right_hand_position(mode: TrackingMode = TrackingMode.MODE_2D) -> Vector3:
	return _to_vector3(_provider.get_right_hand_position(_to_provider_mode(mode))) if _provider != null else Vector3.ZERO

func get_left_foot_position(mode: TrackingMode = TrackingMode.MODE_2D) -> Vector3:
	return _to_vector3(_provider.get_left_foot_position(_to_provider_mode(mode))) if _provider != null else Vector3.ZERO

func get_right_foot_position(mode: TrackingMode = TrackingMode.MODE_2D) -> Vector3:
	return _to_vector3(_provider.get_right_foot_position(_to_provider_mode(mode))) if _provider != null else Vector3.ZERO

func get_head_velocity() -> Vector3:
	return _provider.get_landmark_velocity_for_body_part(&"head") if _provider != null else Vector3.ZERO

func get_left_hand_velocity() -> Vector3:
	return _provider.get_landmark_velocity_for_body_part(&"left_hand") if _provider != null else Vector3.ZERO

func get_right_hand_velocity() -> Vector3:
	return _provider.get_landmark_velocity_for_body_part(&"right_hand") if _provider != null else Vector3.ZERO

func get_left_foot_velocity() -> Vector3:
	return _provider.get_landmark_velocity_for_body_part(&"left_foot") if _provider != null else Vector3.ZERO

func get_right_foot_velocity() -> Vector3:
	return _provider.get_landmark_velocity_for_body_part(&"right_foot") if _provider != null else Vector3.ZERO

func get_head_rotation() -> Quaternion:
	return Quaternion.IDENTITY

func get_left_hand_rotation() -> Quaternion:
	return Quaternion.IDENTITY

func get_right_hand_rotation() -> Quaternion:
	return Quaternion.IDENTITY

func get_left_foot_rotation() -> Quaternion:
	return Quaternion.IDENTITY

func get_right_foot_rotation() -> Quaternion:
	return Quaternion.IDENTITY

func get_tracking_confidence(body_part: StringName) -> float:
	if _provider == null or not _provider.has_method("get_detector_state"):
		return 0.0
	return _provider.get_detector_state().get("metrics", {}).get("confidences", {}).get(String(body_part), 0.0)

func set_tracking_mode(mode: TrackingMode) -> void:
	_tracking_mode = mode
	if _provider != null and _provider.has_method("set_tracking_mode"):
		_provider.set_tracking_mode(_to_provider_mode(mode))

func set_body_track_flags(flags: int) -> void:
	_body_track_flags = flags

func _notification(what: int) -> void:
	if what == NOTIFICATION_EXIT_TREE:
		_unpublish_shared_session_if_needed()

func _provider_session_registry_available() -> bool:
	return ResourceLoader.exists(PROVIDER_SESSION_REGISTRY_PATH)

func _load_provider_session_registry():
	if not _provider_session_registry_available():
		return null
	return load(PROVIDER_SESSION_REGISTRY_PATH)

func _publish_shared_session_if_possible() -> Dictionary:
	var registry = _load_provider_session_registry()
	if registry == null:
		return {}

	var owner_id := _build_shared_session_owner_id()
	var publish: Dictionary = registry.publish_session(
		owner_id,
		self,
		{
			"session_key": SHARED_SESSION_KEY,
			"metadata": _build_shared_session_metadata(),
		}
	)
	if bool(publish.get("ok", false)):
		var session: Dictionary = publish.get("session", {}) if publish.get("session", {}) is Dictionary else {}
		_published_session_owner_id = owner_id
		_published_session_key = String(session.get("session_key", SHARED_SESSION_KEY)).strip_edges()
		return publish

	_published_session_owner_id = ""
	_published_session_key = ""
	var status := String(publish.get("status", "unknown"))
	if status != "owner_mismatch" and status != "session_exists":
		push_warning("MediaPipe input provider session was not published: %s" % status)
	return publish

func _unpublish_shared_session_if_needed() -> void:
	if _published_session_owner_id.is_empty() or _published_session_key.is_empty():
		return

	var owner_id := _published_session_owner_id
	var session_key := _published_session_key
	_published_session_owner_id = ""
	_published_session_key = ""

	var registry = _load_provider_session_registry()
	if registry == null:
		return
	registry.unpublish_session(owner_id, session_key)

func _build_shared_session_owner_id() -> String:
	var node_identity := "instance_%d" % get_instance_id()
	if is_inside_tree():
		var node_path := String(get_path()).strip_edges()
		if not node_path.is_empty():
			node_identity = node_path
	return "%s:%s" % [SHARED_SESSION_OWNER_PREFIX, node_identity]

func _build_shared_session_metadata() -> Dictionary:
	var source_identity := _shared_session_source_identity()
	var source_kind := _shared_session_source_kind()
	return {
		"lane": "input_provider",
		"entrypoint": "src/input_provider.gd",
		"node_path": String(get_path()) if is_inside_tree() else "",
		"shared_reuse_scope": "same_runtime_only",
		"provider_id": PROVIDER_ID,
		"provider_lane": _provider_lane,
		"legacy_fallback": is_using_legacy_fallback(),
		"runtime_mode": _shared_session_runtime_mode(),
		"source_kind": source_kind,
		"camera_source": source_identity,
		"fixture_video_path": source_identity if source_kind == "video_file" else "",
		"min_visibility": _shared_session_min_visibility(),
		"tracking_overlay_mode": _shared_session_tracking_overlay_mode(),
		"gesture_eval_interval_frames": _shared_session_gesture_eval_interval_frames(),
	}

func _ensure_provider() -> void:
	var resolved_tracking_session = _resolve_tracking_session()
	if resolved_tracking_session != null:
		_ensure_camera_tracking_provider(resolved_tracking_session)
	else:
		_ensure_legacy_mediapipe_provider()

	if _provider != null and _provider.has_method("set_tracking_mode"):
		_provider.set_tracking_mode(_to_provider_mode(_tracking_mode))
	_refresh_available_camera_devices()

func _ensure_camera_tracking_provider(tracking_session) -> void:
	if _provider != null and _provider_lane.is_empty():
		_provider_lane = _infer_provider_lane(_provider)
	if _provider != null and _provider_lane == PROVIDER_LANE_CAMERA_TRACKING:
		_provider.set_tracking_session(tracking_session)
		if _provider.get("config") == null:
			_provider.config = _ensure_config()
		_config = _provider.config
		return

	var provider_script: GDScript = _load_local_script("providers/camera_tracking_provider.gd")
	if provider_script == null:
		return
	var provider = provider_script.new()
	provider.name = "CameraTrackingProvider"
	provider.config = _ensure_config()
	provider.set_tracking_session(tracking_session)
	_replace_provider(provider, PROVIDER_LANE_CAMERA_TRACKING)

func _ensure_legacy_mediapipe_provider() -> void:
	if _provider != null and _provider_lane.is_empty():
		_provider_lane = _infer_provider_lane(_provider)
	if _provider != null and _provider_lane == PROVIDER_LANE_LEGACY_MEDIAPIPE:
		if _provider.get("config") == null:
			_provider.config = _ensure_config()
		_config = _provider.config
		_connect_provider_signals()
		_connect_provider_tracking_lost_signal()
		return

	var provider_script: GDScript = _load_local_script("providers/mediapipe_provider.gd")
	if provider_script == null:
		return
	var provider = provider_script.new()
	provider.name = "MediaPipeProvider"
	provider.config = _ensure_config()
	_replace_provider(provider, PROVIDER_LANE_LEGACY_MEDIAPIPE)

func _replace_provider(next_provider: Node, lane: String) -> void:
	var previous_provider = _provider
	if previous_provider == next_provider:
		_provider_lane = lane
		return

	_provider = next_provider
	_provider_lane = lane
	if _provider.get_parent() != self:
		add_child(_provider)
	if _provider.get("config") == null:
		_provider.config = _ensure_config()
	_config = _provider.config
	_connect_provider_tracking_lost_signal()
	_connect_provider_signals()

	if previous_provider != null and previous_provider != next_provider:
		if previous_provider.has_method("stop"):
			previous_provider.stop()
		if previous_provider.get_parent() == self:
			remove_child(previous_provider)
		previous_provider.queue_free()

func _infer_provider_lane(provider: Variant) -> String:
	if provider != null and provider.has_method("set_tracking_session"):
		return PROVIDER_LANE_CAMERA_TRACKING
	return PROVIDER_LANE_LEGACY_MEDIAPIPE

func _resolve_tracking_session():
	if _tracking_session != null:
		return _tracking_session
	return _discover_tracking_session()

func _discover_tracking_session():
	if not is_inside_tree():
		return null
	var singleton := get_node_or_null("/root/%s" % TRACKING_SINGLETON_NODE_NAME)
	if singleton != null and singleton.has_method("get_tracking_session_if_ready"):
		var session = singleton.get_tracking_session_if_ready()
		if session != null:
			return session
	return find_child(TRACKING_SESSION_NODE_NAME, true, false)

func _connect_provider_tracking_lost_signal() -> void:
	if _provider == null or not _provider.has_signal("tracking_lost"):
		return
	if not _provider.tracking_lost.is_connected(_on_provider_tracking_lost):
		_provider.tracking_lost.connect(_on_provider_tracking_lost)

func _connect_provider_signals() -> void:
	if _provider == null:
		return
	_connect_provider_signal("punch_left", _on_provider_punch_left)
	_connect_provider_signal("punch_right", _on_provider_punch_right)
	_connect_provider_signal("uppercut_left", _on_provider_uppercut_left)
	_connect_provider_signal("uppercut_right", _on_provider_uppercut_right)
	_connect_provider_signal("hook_left", _on_provider_hook_left)
	_connect_provider_signal("hook_right", _on_provider_hook_right)
	_connect_provider_signal("swing_left", _on_provider_swing_left)
	_connect_provider_signal("swing_right", _on_provider_swing_right)
	_connect_provider_signal("trail_left", _on_provider_trail_left)
	_connect_provider_signal("trail_right", _on_provider_trail_right)
	_connect_provider_signal("guard_start", _on_provider_guard_start)
	_connect_provider_signal("guard_end", _on_provider_guard_end)
	_connect_provider_signal("squat_start", _on_provider_squat_start)
	_connect_provider_signal("squat_end", _on_provider_squat_end)
	_connect_provider_signal("weave_left_start", _on_provider_weave_left_start)
	_connect_provider_signal("weave_left_end", _on_provider_weave_left_end)
	_connect_provider_signal("weave_right_start", _on_provider_weave_right_start)
	_connect_provider_signal("weave_right_end", _on_provider_weave_right_end)
	_connect_provider_signal("sidestep_left_start", _on_provider_sidestep_left_start)
	_connect_provider_signal("sidestep_left_end", _on_provider_sidestep_left_end)
	_connect_provider_signal("sidestep_right_start", _on_provider_sidestep_right_start)
	_connect_provider_signal("sidestep_right_end", _on_provider_sidestep_right_end)
	_connect_provider_signal("knee_left", _on_provider_knee_left)
	_connect_provider_signal("knee_right", _on_provider_knee_right)
	_connect_provider_signal("leg_lift_left_start", _on_provider_leg_lift_left_start)
	_connect_provider_signal("leg_lift_left_end", _on_provider_leg_lift_left_end)
	_connect_provider_signal("leg_lift_right_start", _on_provider_leg_lift_right_start)
	_connect_provider_signal("leg_lift_right_end", _on_provider_leg_lift_right_end)

func _connect_provider_signal(signal_name: StringName, callback: Callable) -> void:
	if _provider == null or not _provider.has_signal(String(signal_name)):
		return
	var signal_variant: Variant = _provider.get(String(signal_name))
	if signal_variant is Signal and not signal_variant.is_connected(callback):
		signal_variant.connect(callback)

func _refresh_available_camera_devices() -> void:
	if _provider == null or not _provider.has_method("get_available_camera_devices"):
		_available_camera_devices = []
		return
	_available_camera_devices = _provider.get_available_camera_devices()
	_republish_shared_session_if_needed()

func _republish_shared_session_if_needed() -> void:
	if _provider == null or not is_instance_valid(_provider):
		return
	if _published_session_owner_id.is_empty() or _published_session_key.is_empty():
		return
	_publish_shared_session_if_possible()

func _with_default_shared_session_request(request: Dictionary = {}) -> Dictionary:
	var normalized_request := request.duplicate(true)
	if not normalized_request.has("session_key"):
		normalized_request["session_key"] = SHARED_SESSION_KEY
	if not normalized_request.has("provider_id"):
		normalized_request["provider_id"] = PROVIDER_ID
	return normalized_request

func _shared_session_runtime_mode() -> String:
	var source_kind := _shared_session_source_kind()
	return "replay" if source_kind == "video_file" else "live"

func _shared_session_source_kind() -> String:
	var tracking_session = _resolve_tracking_session()
	if tracking_session != null and tracking_session.has_method("get_active_config"):
		var active_config: Variant = tracking_session.get_active_config()
		if active_config is Dictionary:
			var source: Variant = active_config.get("source", {})
			if source is Dictionary:
				var source_kind := String(source.get("kind", "")).strip_edges()
				if not source_kind.is_empty():
					return source_kind
	return "live_camera"

func _shared_session_source_identity() -> String:
	var tracking_session = _resolve_tracking_session()
	if tracking_session != null and tracking_session.has_method("get_active_config"):
		var active_config: Variant = tracking_session.get_active_config()
		if active_config is Dictionary:
			var source: Variant = active_config.get("source", {})
			if source is Dictionary:
				var source_kind := String(source.get("kind", "")).strip_edges()
				if source_kind == "video_file":
					return String(source.get("path", "")).strip_edges()
				var camera_id := String(source.get("camera_id", "")).strip_edges()
				if not camera_id.is_empty():
					return camera_id
	return get_selected_camera_device_id()

func _shared_session_min_visibility() -> float:
	return float(_config.min_visibility) if _config != null else 0.5

func _shared_session_tracking_overlay_mode() -> String:
	if _config == null:
		return "full"
	var mode := String(_config.tracking_overlay_mode).strip_edges().to_lower()
	return mode if not mode.is_empty() else "full"

func _shared_session_gesture_eval_interval_frames() -> int:
	return maxi(1, int(_config.gesture_eval_interval_frames)) if _config != null else 1

func _apply_settings(settings_json: String) -> void:
	if settings_json.is_empty():
		return
	var parsed: Variant = JSON.parse_string(settings_json)
	if !(parsed is Dictionary):
		return
	var settings: Dictionary = parsed
	_config = _ensure_config()
	if settings.has("udp_port"):
		_config.udp_port = int(settings["udp_port"])
	if settings.has("min_visibility"):
		_config.min_visibility = float(settings["min_visibility"])
	if settings.has("tracking_confidence"):
		_config.tracking_confidence = float(settings["tracking_confidence"])
	if settings.has("flip_horizontal"):
		_config.flip_horizontal = bool(settings["flip_horizontal"])
	var selected_camera_changed := false
	if settings.has("selected_camera_device_id"):
		_config.set_selected_camera_device_id(String(settings["selected_camera_device_id"]))
		selected_camera_changed = true
	elif settings.has("camera_source"):
		_config.set_selected_camera_device_id(String(settings["camera_source"]))
		selected_camera_changed = true
	if settings.has("tracking_overlay_mode"):
		_config.tracking_overlay_mode = String(settings["tracking_overlay_mode"]).strip_edges().to_lower()
	if settings.has("gesture_eval_interval_frames"):
		_config.gesture_eval_interval_frames = maxi(1, int(settings["gesture_eval_interval_frames"]))
	if _provider != null:
		_provider.config = _config
		if selected_camera_changed and _provider.has_method("set_selected_camera_device_id"):
			_provider.set_selected_camera_device_id(_config.get_camera_source())
	_refresh_available_camera_devices()
	camera_devices_changed.emit(get_available_camera_devices(), get_selected_camera_device_id())

func _ensure_config() -> Variant:
	if _config != null:
		return _config
	_config = _new_local_config()
	return _config

func _load_local_script(relative_path: String) -> GDScript:
	var script_path := _resolve_local_path(relative_path)
	var script: Variant = load(script_path)
	if script == null:
		push_error("Failed to load camera tracking addon script: %s" % script_path)
		return null
	return script

func _new_local_config() -> Variant:
	var config_script: GDScript = _load_local_script("config/mediapipe_config.gd")
	return config_script.new() if config_script != null else null

func _resolve_local_path(relative_path: String) -> String:
	return "%s/%s" % [get_script().resource_path.get_base_dir(), relative_path]

func _on_provider_tracking_lost() -> void:
	failed.emit("Tracking lost")

func _on_provider_punch_left(power: float) -> void:
	punch_left.emit(power)

func _on_provider_punch_right(power: float) -> void:
	punch_right.emit(power)

func _on_provider_uppercut_left(power: float) -> void:
	uppercut_left.emit(power)

func _on_provider_uppercut_right(power: float) -> void:
	uppercut_right.emit(power)

func _on_provider_hook_left(power: float) -> void:
	hook_left.emit(power)

func _on_provider_hook_right(power: float) -> void:
	hook_right.emit(power)

func _on_provider_swing_left(placement: int, direction: int) -> void:
	swing_left.emit(placement, direction)

func _on_provider_swing_right(placement: int, direction: int) -> void:
	swing_right.emit(placement, direction)

func _on_provider_trail_left(placement: int, direction: int) -> void:
	trail_left.emit(placement, direction)

func _on_provider_trail_right(placement: int, direction: int) -> void:
	trail_right.emit(placement, direction)

func _on_provider_guard_start() -> void:
	guard_start.emit()

func _on_provider_guard_end() -> void:
	guard_end.emit()

func _on_provider_squat_start() -> void:
	squat_start.emit()

func _on_provider_squat_end() -> void:
	squat_end.emit()

func _on_provider_weave_left_start() -> void:
	weave_left_start.emit()

func _on_provider_weave_left_end() -> void:
	weave_left_end.emit()

func _on_provider_weave_right_start() -> void:
	weave_right_start.emit()

func _on_provider_weave_right_end() -> void:
	weave_right_end.emit()

func _on_provider_sidestep_left_start() -> void:
	sidestep_left_start.emit()

func _on_provider_sidestep_left_end() -> void:
	sidestep_left_end.emit()

func _on_provider_sidestep_right_start() -> void:
	sidestep_right_start.emit()

func _on_provider_sidestep_right_end() -> void:
	sidestep_right_end.emit()

func _on_provider_knee_left(power: float) -> void:
	knee_left.emit(power)

func _on_provider_knee_right(power: float) -> void:
	knee_right.emit(power)

func _on_provider_leg_lift_left_start() -> void:
	leg_lift_left_start.emit()

func _on_provider_leg_lift_left_end() -> void:
	leg_lift_left_end.emit()

func _on_provider_leg_lift_right_start() -> void:
	leg_lift_right_start.emit()

func _on_provider_leg_lift_right_end() -> void:
	leg_lift_right_end.emit()

func _to_provider_mode(mode: TrackingMode) -> int:
	return 1 if mode == TrackingMode.MODE_3D else 0

func _to_vector3(value: Variant) -> Vector3:
	if value is Vector3:
		return value
	if value is Vector2:
		return Vector3(value.x, value.y, 0.0)
	return Vector3.ZERO
