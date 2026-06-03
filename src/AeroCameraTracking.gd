extends Node
## Repo-owned camera-tracking singleton facade.
##
## Current truthful scope:
## - owns the high-level start/stop contract for live-camera and replay/video-file tracking
## - delegates normalized tracking + gesture interpretation through CameraTrackingProvider
## - re-emits tracking-session state plus Boxing/Flow detector signals for consumer scenes
## - consumes only the public CameraTracking contract from aerobeat-tool-camera-tracking
##   and does not locally compose vendor backend/runtime objects

const CAMERA_TRACKING_SCRIPT_PATH := "res://addons/aerobeat-tool-camera-tracking/src/CameraTracking.gd"
const CAMERA_TRACKING_PROVIDER_SCRIPT_PATH := "res://addons/aerobeat-input-camera-tracking/src/providers/camera_tracking_provider.gd"
const CAMERA_TRACKING_CONFIG_SCRIPT_PATH := "res://addons/aerobeat-input-camera-tracking/src/config/camera_tracking_config.gd"
const INTERNAL_TRACKING_NODE_NAME := "CameraTracking"
const INTERNAL_PROVIDER_NODE_NAME := "CameraTrackingProvider"
const _SHUTDOWN_TRACE_PREFIX := "[CameraShutdownTrace][AeroCameraTracking]"

signal state_changed(state: String, detail: Dictionary)
signal tracking_updated(frame: Dictionary)
signal preview_changed(descriptor: Dictionary)
signal cameras_changed(cameras: Array)
signal error_raised(error_info: Dictionary)

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

var _tracking_session: Node = null
var _provider: Node = null
var _preview_surface: Node = null
var _last_runtime_config = null
var _owns_tracking_session := false
var _owns_provider := false
var _runtime_teardown_in_progress := false
var _replay_source_path := ""
var _replay_duration_sec := 0.0
var _replay_position_sec := 0.0
var _replay_loaded := false
var _replay_playing := false
var _replay_started_at_msec := 0
var _replay_started_at_position_sec := 0.0

func has_tracking_contract() -> bool:
	return _tracking_session != null and is_instance_valid(_tracking_session)

func is_tracking_session_discoverable() -> bool:
	return has_tracking_contract()

func get_tracking_session_if_ready() -> Node:
	return _tracking_session if has_tracking_contract() else null

func get_tracking_session() -> Node:
	return _ensure_tracking_session()

func get_provider() -> Node:
	return _ensure_provider()

func start_live_camera(camera_id: String = "", config_variant: Variant = null) -> bool:
	var runtime_config = _coerce_runtime_config(config_variant)
	if runtime_config == null:
		return false
	var normalized_camera_id := camera_id.strip_edges()
	if not normalized_camera_id.is_empty() and runtime_config.has_method("set_selected_camera_device_id"):
		runtime_config.set_selected_camera_device_id(normalized_camera_id)
	return _start_with_config(runtime_config)

func start_replay(source_path: String, config_variant: Variant = null) -> bool:
	var normalized_source := source_path.strip_edges()
	if normalized_source.is_empty():
		push_warning("[AeroCameraTracking] Replay start requested without a source path")
		return false
	var runtime_config = _coerce_runtime_config(config_variant)
	if runtime_config == null:
		return false
	if runtime_config.has_method("set_selected_camera_device_id"):
		runtime_config.set_selected_camera_device_id(normalized_source)
	return _start_with_config(runtime_config)

func start(config_variant: Variant = null) -> bool:
	var runtime_config = _coerce_runtime_config(config_variant)
	if runtime_config == null:
		return false
	return _start_with_config(runtime_config)

func stop() -> void:
	_log_shutdown_trace("stop() requested", {
		"release_owned_nodes": true,
		"release_tracking_session": false,
	})
	_stop_runtime(true)

func _notification(what: int) -> void:
	if what == NOTIFICATION_EXIT_TREE or what == NOTIFICATION_PREDELETE:
		_log_shutdown_trace("notification teardown entry", {
			"what": what,
			"notification": _notification_name(what),
			"release_owned_nodes": true,
			"release_tracking_session": true,
		})
		_stop_runtime(true, true)

func attach_preview_surface(surface: Node) -> void:
	_preview_surface = surface
	var provider := _ensure_provider()
	if provider != null and provider.has_method("set_preview_surface"):
		provider.set_preview_surface(surface)
	elif has_tracking_contract() and _tracking_session.has_method("attach_preview_surface") and surface != null:
		_tracking_session.attach_preview_surface(surface)

func set_preview_surface(surface: Node) -> void:
	attach_preview_surface(surface)

func detach_preview_surface() -> void:
	_preview_surface = null
	if has_tracking_contract() and _tracking_session.has_method("detach_preview_surface"):
		_tracking_session.detach_preview_surface()

func get_state() -> Dictionary:
	if has_tracking_contract() and _tracking_session.has_method("get_state"):
		return _tracking_session.get_state()
	return {}

func get_active_config() -> Dictionary:
	if has_tracking_contract() and _tracking_session.has_method("get_active_config"):
		return _tracking_session.get_active_config()
	return {}

func get_tracking_frame() -> Dictionary:
	if has_tracking_contract() and _tracking_session.has_method("get_tracking_frame"):
		return _tracking_session.get_tracking_frame()
	return {}

func get_last_error() -> Dictionary:
	if has_tracking_contract() and _tracking_session.has_method("get_last_error"):
		return _tracking_session.get_last_error()
	return {}

func list_cameras() -> Array:
	if has_tracking_contract() and _tracking_session.has_method("list_cameras"):
		return _tracking_session.list_cameras()
	return []

func get_camera_options(camera_id: String = "") -> Dictionary:
	if has_tracking_contract() and _tracking_session.has_method("get_camera_options"):
		return _tracking_session.get_camera_options(camera_id)
	return {}

func get_available_camera_devices() -> Array:
	var provider := _ensure_provider()
	if provider != null and provider.has_method("get_available_camera_devices"):
		return provider.get_available_camera_devices()
	return list_cameras()

func get_selected_camera_device_id() -> String:
	var provider := _ensure_provider()
	if provider != null and provider.has_method("get_selected_camera_device_id"):
		return String(provider.get_selected_camera_device_id()).strip_edges()
	var source: Dictionary = get_active_config().get("source", {})
	if String(source.get("kind", "")).strip_edges() == "video_file":
		return String(source.get("path", "")).strip_edges()
	return _get_live_camera_source_id(source)

func set_selected_camera_device_id(device_id: String) -> bool:
	var provider := _ensure_provider()
	if provider == null or not provider.has_method("set_selected_camera_device_id"):
		return false
	return bool(provider.set_selected_camera_device_id(device_id))

func is_tracking() -> bool:
	var provider := _ensure_provider()
	return provider != null and provider.has_method("is_tracking") and bool(provider.is_tracking())

func get_detector_state() -> Dictionary:
	var provider := _ensure_provider()
	if provider != null and provider.has_method("get_detector_state"):
		return provider.get_detector_state()
	return {}

func get_body_measurements() -> Dictionary:
	var provider := _ensure_provider()
	if provider != null and provider.has_method("get_body_measurements"):
		return provider.get_body_measurements()
	return {}

func get_num_poses() -> int:
	var provider := _ensure_provider()
	if provider != null and provider.has_method("get_num_poses"):
		return int(provider.get_num_poses())
	return 0

func get_all_poses() -> Array:
	var provider := _ensure_provider()
	if provider != null and provider.has_method("get_all_poses"):
		return provider.get_all_poses()
	return []

func reset_runtime_state() -> void:
	var provider := _ensure_provider()
	if provider != null and provider.has_method("reset_runtime_state"):
		provider.reset_runtime_state()

func ensure_replay_playback_loaded(source_path: String) -> bool:
	var normalized_source := source_path.strip_edges()
	if normalized_source.is_empty():
		return false
	_replay_source_path = normalized_source
	_replay_loaded = true
	_replay_position_sec = clampf(_replay_position_sec, 0.0, _replay_duration_sec if _replay_duration_sec > 0.0 else _replay_position_sec)
	return true

func refresh_replay_playback_status() -> Dictionary:
	_refresh_replay_playback_state_from_tracking_session()
	return get_replay_playback_state()

func get_replay_playback_state() -> Dictionary:
	_refresh_replay_playback_state_from_tracking_session()
	var state_name := "idle"
	if _replay_loaded:
		state_name = "playing" if _replay_playing else "paused"
	return {
		"state": state_name,
		"position": _replay_position_sec,
		"duration": _replay_duration_sec,
		"media_loaded": _replay_loaded,
		"source": {
			"path": _replay_source_path,
			"kind": "file",
		},
		"status": {
			"current_time_sec": _replay_position_sec,
			"duration_sec": _replay_duration_sec,
			"progress": (_replay_position_sec / _replay_duration_sec) if _replay_duration_sec > 0.0 else 0.0,
			"paused": not _replay_playing,
			"is_file_source": true,
		},
	}

func get_replay_playback_status() -> Dictionary:
	return get_replay_playback_state().get("status", {}).duplicate(true)

func play_replay_playback() -> bool:
	if not _replay_loaded and _replay_source_path.is_empty():
		return false
	if _replay_source_path.is_empty():
		return false
	var config = _make_replay_runtime_config(_replay_source_path, _replay_position_sec)
	if config == null:
		return false
	_replay_playing = start_replay(_replay_source_path, config)
	if _replay_playing:
		_replay_started_at_position_sec = _replay_position_sec
		_replay_started_at_msec = Time.get_ticks_msec()
		_refresh_replay_playback_state_from_tracking_session()
	return _replay_playing

func pause_replay_playback() -> bool:
	_refresh_replay_playback_state_from_tracking_session()
	if _provider != null and is_instance_valid(_provider) and _provider.has_method("stop"):
		_provider.stop()
	_replay_playing = false
	_replay_started_at_position_sec = _replay_position_sec
	return true

func seek_replay_playback(seconds: float) -> bool:
	if not _replay_loaded and _replay_source_path.is_empty():
		return false
	_replay_position_sec = maxf(seconds, 0.0)
	return play_replay_playback()

func unload_replay_playback() -> void:
	if _provider != null and is_instance_valid(_provider) and _provider.has_method("stop"):
		_provider.stop()
	_replay_source_path = ""
	_replay_duration_sec = 0.0
	_replay_position_sec = 0.0
	_replay_loaded = false
	_replay_playing = false
	_replay_started_at_msec = 0
	_replay_started_at_position_sec = 0.0

func set_replay_playback_transport_request(_transport_request: Callable) -> void:
	pass

func get_replay_playback_backend():
	return null

func has_replay_playback_loaded() -> bool:
	return _replay_loaded

func set_tracking_session(session: Node) -> void:
	if _tracking_session == session:
		return
	var previous_tracking_session := _tracking_session
	var release_previous_owned_session := _owns_tracking_session and previous_tracking_session != null and previous_tracking_session != session
	_disconnect_tracking_session_signals()
	_tracking_session = session
	_owns_tracking_session = false
	if _tracking_session != null and _tracking_session.get_parent() == null:
		add_child(_tracking_session)
	_connect_tracking_session_signals()
	if _provider != null and is_instance_valid(_provider) and _provider.has_method("set_tracking_session"):
		_provider.set_tracking_session(_tracking_session)
	if release_previous_owned_session:
		_release_owned_runtime_node(previous_tracking_session)

func _start_with_config(runtime_config) -> bool:
	var session := _ensure_tracking_session()
	var provider := _ensure_provider()
	if session == null or provider == null:
		return false
	_last_runtime_config = runtime_config
	provider.config = runtime_config
	provider.manage_tracking_session_lifecycle = true
	provider.set_tracking_session(session)
	if _preview_surface != null and provider.has_method("set_preview_surface"):
		provider.set_preview_surface(_preview_surface)
	return bool(provider.start())

func _ensure_tracking_session() -> Node:
	if has_tracking_contract():
		return _tracking_session
	var camera_tracking_script: Variant = _load_script(CAMERA_TRACKING_SCRIPT_PATH)
	if camera_tracking_script == null:
		push_error("[AeroCameraTracking] CameraTracking contract addon is not mounted")
		return null
	_tracking_session = camera_tracking_script.new()
	_tracking_session.name = INTERNAL_TRACKING_NODE_NAME
	add_child(_tracking_session)
	_owns_tracking_session = true
	_connect_tracking_session_signals()
	return _tracking_session

func _ensure_provider() -> Node:
	if _provider != null and is_instance_valid(_provider):
		return _provider
	var provider_script: Variant = _load_script(CAMERA_TRACKING_PROVIDER_SCRIPT_PATH)
	if provider_script == null:
		push_error("[AeroCameraTracking] CameraTrackingProvider script is not available")
		return null
	_provider = provider_script.new()
	_provider.name = INTERNAL_PROVIDER_NODE_NAME
	_provider.manage_tracking_session_lifecycle = true
	if _tracking_session != null and is_instance_valid(_tracking_session) and _provider.has_method("set_tracking_session"):
		_provider.set_tracking_session(_tracking_session)
	if _preview_surface != null and _provider.has_method("set_preview_surface"):
		_provider.set_preview_surface(_preview_surface)
	add_child(_provider)
	_owns_provider = true
	_connect_provider_signals()
	return _provider

func get_current_preview_descriptor() -> Dictionary:
	if has_tracking_contract() and _tracking_session.has_method("get_preview_descriptor"):
		return _tracking_session.get_preview_descriptor()
	return {}

func get_current_playback_status() -> Dictionary:
	return get_replay_playback_status()

func _refresh_replay_playback_state_from_tracking_session() -> void:
	if _replay_loaded and _replay_playing:
		var elapsed_sec := maxf(float(Time.get_ticks_msec() - _replay_started_at_msec) / 1000.0, 0.0)
		var next_position := _replay_started_at_position_sec + elapsed_sec
		if _replay_duration_sec > 0.0:
			next_position = minf(next_position, _replay_duration_sec)
		_replay_position_sec = maxf(next_position, _replay_position_sec)
	var active_config := get_active_config()
	var source: Dictionary = active_config.get("source", {})
	var source_kind := String(source.get("kind", "")).strip_edges()
	if source_kind == "video_file":
		_replay_loaded = true
		_replay_source_path = String(source.get("path", _replay_source_path)).strip_edges()

func _get_live_camera_source_id(source: Dictionary) -> String:
	var camera_id := String(source.get("camera_id", "")).strip_edges()
	if not camera_id.is_empty():
		return camera_id
	var legacy_id := String(source.get("id", "")).strip_edges()
	if not legacy_id.is_empty():
		return legacy_id
	return String(source.get("path", "")).strip_edges()

func _make_replay_runtime_config(source_path: String, start_time_sec: float):
	var config = _coerce_runtime_config(_last_runtime_config if _last_runtime_config != null else {})
	if config == null:
		return null
	if config.has_method("set_selected_camera_device_id"):
		config.set_selected_camera_device_id(source_path)
	if config.get("vendor") is Dictionary:
		var vendor_config: Dictionary = config.vendor.duplicate(true)
		if not vendor_config.has("source") or not vendor_config["source"] is Dictionary:
			vendor_config["source"] = {}
		(vendor_config["source"] as Dictionary)["start_time_sec"] = maxf(start_time_sec, 0.0)
		config.vendor = vendor_config
	return config

func _coerce_runtime_config(config_variant: Variant):
	if typeof(config_variant) == TYPE_OBJECT and config_variant.has_method("get_camera_source"):
		return config_variant
	var config_script: Variant = _load_script(CAMERA_TRACKING_CONFIG_SCRIPT_PATH)
	if config_script == null:
		push_error("[AeroCameraTracking] CameraTracking config script is not available")
		return null
	var config = config_script.new()
	if config_variant is Dictionary:
		_apply_dictionary_config(config, config_variant)
	return config

func _apply_dictionary_config(config, values: Dictionary) -> void:
	if values.has("min_visibility"):
		config.min_visibility = float(values["min_visibility"])
	if values.has("tracking_confidence"):
		config.tracking_confidence = float(values["tracking_confidence"])
	if values.has("flip_horizontal"):
		config.flip_horizontal = bool(values["flip_horizontal"])
	if values.has("tracking_overlay_mode"):
		config.tracking_overlay_mode = String(values["tracking_overlay_mode"]).strip_edges().to_lower()
	if values.has("gesture_eval_interval_frames"):
		config.gesture_eval_interval_frames = maxi(1, int(values["gesture_eval_interval_frames"]))
	if values.has("model_complexity"):
		config.model_complexity = int(values["model_complexity"])
	if values.has("camera_source") and config.has_method("set_selected_camera_device_id"):
		config.set_selected_camera_device_id(String(values["camera_source"]))
	elif values.has("selected_camera_device_id") and config.has_method("set_selected_camera_device_id"):
		config.set_selected_camera_device_id(String(values["selected_camera_device_id"]))
	if values.has("runtime") and config.get("runtime") is Dictionary and values["runtime"] is Dictionary:
		config.runtime = (values["runtime"] as Dictionary).duplicate(true)
	if values.has("diagnostics") and config.get("diagnostics") is Dictionary and values["diagnostics"] is Dictionary:
		config.diagnostics = (values["diagnostics"] as Dictionary).duplicate(true)
	if values.has("vendor") and config.get("vendor") is Dictionary and values["vendor"] is Dictionary:
		config.vendor = (values["vendor"] as Dictionary).duplicate(true)

func _stop_runtime(release_owned_nodes: bool, release_tracking_session: bool = false) -> void:
	if _runtime_teardown_in_progress:
		_log_shutdown_trace("stop_runtime skipped reentry", {
			"release_owned_nodes": release_owned_nodes,
			"release_tracking_session": release_tracking_session,
		})
		return
	_log_shutdown_trace("stop_runtime begin", {
		"release_owned_nodes": release_owned_nodes,
		"release_tracking_session": release_tracking_session,
		"owns_provider": _owns_provider,
		"owns_tracking_session": _owns_tracking_session,
		"provider_valid": _provider != null and is_instance_valid(_provider),
		"tracking_session_valid": _tracking_session != null and is_instance_valid(_tracking_session),
	})
	_runtime_teardown_in_progress = true
	_preview_surface = null
	if _provider != null and is_instance_valid(_provider):
		if _provider.has_method("stop"):
			_log_shutdown_trace("provider.stop()", {})
			_provider.stop()
		if _provider.has_method("set_tracking_session"):
			_log_shutdown_trace("provider.set_tracking_session(null)", {})
			_provider.set_tracking_session(null)
		_log_shutdown_trace("disconnect_provider_signals", {})
		_disconnect_provider_signals()
		if release_owned_nodes and _owns_provider:
			var owned_provider := _provider
			_provider = null
			_owns_provider = false
			_log_shutdown_trace("release_owned_provider", {})
			_release_owned_runtime_node(owned_provider)
	if release_tracking_session:
		_log_shutdown_trace("teardown_tracking_session requested", {})
		_teardown_tracking_session()
	_reset_replay_state()
	_runtime_teardown_in_progress = false
	_log_shutdown_trace("stop_runtime end", {
		"provider_valid": _provider != null and is_instance_valid(_provider),
		"tracking_session_valid": _tracking_session != null and is_instance_valid(_tracking_session),
	})

func _teardown_tracking_session() -> void:
	if _tracking_session == null or not is_instance_valid(_tracking_session):
		_log_shutdown_trace("teardown_tracking_session no-op", {})
		_tracking_session = null
		_owns_tracking_session = false
		return
	if _tracking_session.has_method("detach_preview_surface"):
		_log_shutdown_trace("tracking_session.detach_preview_surface()", {})
		_tracking_session.detach_preview_surface()
	if _tracking_session.has_method("stop"):
		_log_shutdown_trace("tracking_session.stop()", {})
		_tracking_session.stop()
	_log_shutdown_trace("disconnect_tracking_session_signals", {})
	_disconnect_tracking_session_signals()
	var tracking_session := _tracking_session
	var release_owned_tracking_session := _owns_tracking_session
	_tracking_session = null
	_owns_tracking_session = false
	if release_owned_tracking_session:
		_log_shutdown_trace("release_owned_tracking_session", {})
		_release_owned_runtime_node(tracking_session)

func _release_owned_runtime_node(node: Node) -> void:
	if node == null or not is_instance_valid(node):
		return
	if node.get_parent() == self:
		remove_child(node)
	node.queue_free()

func _log_shutdown_trace(marker: String, detail: Dictionary = {}) -> void:
	print("%s %s %s" % [_SHUTDOWN_TRACE_PREFIX, marker, JSON.stringify(detail)])

func _notification_name(what: int) -> String:
	match what:
		NOTIFICATION_EXIT_TREE:
			return "NOTIFICATION_EXIT_TREE"
		NOTIFICATION_PREDELETE:
			return "NOTIFICATION_PREDELETE"
		_:
			return "UNKNOWN"

func _reset_replay_state() -> void:
	_replay_playing = false
	_replay_started_at_msec = 0
	_replay_started_at_position_sec = _replay_position_sec

func _connect_tracking_session_signals() -> void:
	if not has_tracking_contract():
		return
	if _tracking_session.has_signal("state_changed") and not _tracking_session.state_changed.is_connected(_on_tracking_session_state_changed):
		_tracking_session.state_changed.connect(_on_tracking_session_state_changed)
	if _tracking_session.has_signal("tracking_updated") and not _tracking_session.tracking_updated.is_connected(_on_tracking_session_tracking_updated):
		_tracking_session.tracking_updated.connect(_on_tracking_session_tracking_updated)
	if _tracking_session.has_signal("preview_changed") and not _tracking_session.preview_changed.is_connected(_on_tracking_session_preview_changed):
		_tracking_session.preview_changed.connect(_on_tracking_session_preview_changed)
	if _tracking_session.has_signal("cameras_changed") and not _tracking_session.cameras_changed.is_connected(_on_tracking_session_cameras_changed):
		_tracking_session.cameras_changed.connect(_on_tracking_session_cameras_changed)
	if _tracking_session.has_signal("error_raised") and not _tracking_session.error_raised.is_connected(_on_tracking_session_error_raised):
		_tracking_session.error_raised.connect(_on_tracking_session_error_raised)

func _disconnect_tracking_session_signals() -> void:
	if _tracking_session == null or not is_instance_valid(_tracking_session):
		return
	if _tracking_session.has_signal("state_changed") and _tracking_session.state_changed.is_connected(_on_tracking_session_state_changed):
		_tracking_session.state_changed.disconnect(_on_tracking_session_state_changed)
	if _tracking_session.has_signal("tracking_updated") and _tracking_session.tracking_updated.is_connected(_on_tracking_session_tracking_updated):
		_tracking_session.tracking_updated.disconnect(_on_tracking_session_tracking_updated)
	if _tracking_session.has_signal("preview_changed") and _tracking_session.preview_changed.is_connected(_on_tracking_session_preview_changed):
		_tracking_session.preview_changed.disconnect(_on_tracking_session_preview_changed)
	if _tracking_session.has_signal("cameras_changed") and _tracking_session.cameras_changed.is_connected(_on_tracking_session_cameras_changed):
		_tracking_session.cameras_changed.disconnect(_on_tracking_session_cameras_changed)
	if _tracking_session.has_signal("error_raised") and _tracking_session.error_raised.is_connected(_on_tracking_session_error_raised):
		_tracking_session.error_raised.disconnect(_on_tracking_session_error_raised)

func _connect_provider_signals() -> void:
	if _provider == null or not is_instance_valid(_provider):
		return
	_connect_provider_signal("pose_updated", _on_provider_pose_updated)
	_connect_provider_signal("multi_pose_updated", _on_provider_multi_pose_updated)
	_connect_provider_signal("tracking_lost", _on_provider_tracking_lost)
	_connect_provider_signal("tracking_restored", _on_provider_tracking_restored)
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

func _disconnect_provider_signals() -> void:
	if _provider == null or not is_instance_valid(_provider):
		return
	_disconnect_provider_signal("pose_updated", _on_provider_pose_updated)
	_disconnect_provider_signal("multi_pose_updated", _on_provider_multi_pose_updated)
	_disconnect_provider_signal("tracking_lost", _on_provider_tracking_lost)
	_disconnect_provider_signal("tracking_restored", _on_provider_tracking_restored)
	_disconnect_provider_signal("punch_left", _on_provider_punch_left)
	_disconnect_provider_signal("punch_right", _on_provider_punch_right)
	_disconnect_provider_signal("uppercut_left", _on_provider_uppercut_left)
	_disconnect_provider_signal("uppercut_right", _on_provider_uppercut_right)
	_disconnect_provider_signal("hook_left", _on_provider_hook_left)
	_disconnect_provider_signal("hook_right", _on_provider_hook_right)
	_disconnect_provider_signal("swing_left", _on_provider_swing_left)
	_disconnect_provider_signal("swing_right", _on_provider_swing_right)
	_disconnect_provider_signal("trail_left", _on_provider_trail_left)
	_disconnect_provider_signal("trail_right", _on_provider_trail_right)
	_disconnect_provider_signal("guard_start", _on_provider_guard_start)
	_disconnect_provider_signal("guard_end", _on_provider_guard_end)
	_disconnect_provider_signal("squat_start", _on_provider_squat_start)
	_disconnect_provider_signal("squat_end", _on_provider_squat_end)
	_disconnect_provider_signal("weave_left_start", _on_provider_weave_left_start)
	_disconnect_provider_signal("weave_left_end", _on_provider_weave_left_end)
	_disconnect_provider_signal("weave_right_start", _on_provider_weave_right_start)
	_disconnect_provider_signal("weave_right_end", _on_provider_weave_right_end)
	_disconnect_provider_signal("sidestep_left_start", _on_provider_sidestep_left_start)
	_disconnect_provider_signal("sidestep_left_end", _on_provider_sidestep_left_end)
	_disconnect_provider_signal("sidestep_right_start", _on_provider_sidestep_right_start)
	_disconnect_provider_signal("sidestep_right_end", _on_provider_sidestep_right_end)
	_disconnect_provider_signal("knee_left", _on_provider_knee_left)
	_disconnect_provider_signal("knee_right", _on_provider_knee_right)
	_disconnect_provider_signal("leg_lift_left_start", _on_provider_leg_lift_left_start)
	_disconnect_provider_signal("leg_lift_left_end", _on_provider_leg_lift_left_end)
	_disconnect_provider_signal("leg_lift_right_start", _on_provider_leg_lift_right_start)
	_disconnect_provider_signal("leg_lift_right_end", _on_provider_leg_lift_right_end)

func _connect_provider_signal(signal_name: String, callback: Callable) -> void:
	if _provider == null or not _provider.has_signal(signal_name):
		return
	var signal_variant: Variant = _provider.get(signal_name)
	if signal_variant is Signal and not signal_variant.is_connected(callback):
		signal_variant.connect(callback)

func _disconnect_provider_signal(signal_name: String, callback: Callable) -> void:
	if _provider == null or not _provider.has_signal(signal_name):
		return
	var signal_variant: Variant = _provider.get(signal_name)
	if signal_variant is Signal and signal_variant.is_connected(callback):
		signal_variant.disconnect(callback)

func _load_script(path: String) -> Variant:
	return load(path)

func _on_tracking_session_state_changed(state: String, detail: Dictionary) -> void:
	state_changed.emit(state, detail.duplicate(true))

func _on_tracking_session_tracking_updated(frame: Dictionary) -> void:
	tracking_updated.emit(frame.duplicate(true))

func _on_tracking_session_preview_changed(descriptor: Dictionary) -> void:
	preview_changed.emit(descriptor.duplicate(true))

func _on_tracking_session_cameras_changed(cameras: Array) -> void:
	cameras_changed.emit(cameras.duplicate(true))

func _on_tracking_session_error_raised(error_info: Dictionary) -> void:
	error_raised.emit(error_info.duplicate(true))

func _on_provider_pose_updated(landmarks: Array) -> void:
	pose_updated.emit(landmarks.duplicate(true))

func _on_provider_multi_pose_updated(poses: Array) -> void:
	multi_pose_updated.emit(poses.duplicate(true))

func _on_provider_tracking_lost() -> void:
	tracking_lost.emit()

func _on_provider_tracking_restored() -> void:
	tracking_restored.emit()

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
