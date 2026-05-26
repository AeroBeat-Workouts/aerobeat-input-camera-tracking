class_name AeroMediaPipeReplayPlaybackBackend
extends "res://addons/aerobeat-tool-video-player/src/AeroVideoPlayerBackend.gd"

const ReplayContract := preload("res://addons/aerobeat-tool-core/globals/aero_video_playback_contract.gd")
const HTTP_TIMEOUT_MS := 1500
const HTTP_POLL_INTERVAL_USEC := 10_000

var _transport_request: Callable = Callable(self, "_default_transport_request")
var _base_url := ""
var _loaded_source: Dictionary = {}
var _cached_status: Dictionary = {}
var _last_error: Dictionary = {}
var _surface_attached := false
var _loop_enabled := false
var _rate := 1.0

func set_transport_request(transport_request: Callable) -> void:
	_transport_request = transport_request if transport_request.is_valid() else Callable(self, "_default_transport_request")

func load(source: Dictionary) -> Dictionary:
	var normalized := ReplayContract.normalize_source(source)
	var base_url := _normalize_base_url(String(normalized.get("path", "")))
	if base_url.is_empty():
		return _fail("backend_invalid_source", "Replay playback source must provide an HTTP base URL.", {"source": normalized.duplicate(true)})
	_base_url = base_url
	_loaded_source = normalized.duplicate(true)
	_loop_enabled = bool(normalized.get("loop", false))
	_rate = float(normalized.get("rate", 1.0))
	var status_result := refresh_status()
	if not bool(status_result.get("success", false)):
		return status_result
	return ReplayContract.ok({"base_url": _base_url, "status": _cached_status.duplicate(true)})

func play() -> Dictionary:
	return _command_request("/playback/play")

func pause() -> Dictionary:
	return _command_request("/playback/pause")

func stop() -> Dictionary:
	var pause_result := pause()
	if not bool(pause_result.get("success", false)):
		return pause_result
	return seek(0.0)

func seek(seconds: float) -> Dictionary:
	return _command_request("/playback/seek?seconds=%.6f" % maxf(seconds, 0.0))

func set_loop(enabled: bool) -> Dictionary:
	_loop_enabled = enabled
	if enabled:
		return _fail("backend_loop_unsupported", "Replay playback backend does not own loop policy updates.", {"loop": enabled})
	return ReplayContract.ok({"loop": enabled})

func set_rate(rate: float) -> Dictionary:
	_rate = rate
	if not is_equal_approx(rate, 1.0):
		return _fail("backend_rate_unsupported", "Replay playback backend does not own playback-rate updates.", {"rate": rate})
	return ReplayContract.ok({"rate": rate})

func get_state() -> Dictionary:
	var duration := float(_cached_status.get("duration_sec", _loaded_source.get("duration_hint", 0.0)))
	var position := float(_cached_status.get("current_time_sec", 0.0))
	var state_name := ReplayContract.STATE_IDLE
	if not _loaded_source.is_empty():
		state_name = ReplayContract.STATE_READY
		if bool(_cached_status.get("paused", false)):
			state_name = ReplayContract.STATE_PAUSED
		elif duration > 0.0 or not _cached_status.is_empty():
			state_name = ReplayContract.STATE_PLAYING
	if not _last_error.is_empty():
		state_name = ReplayContract.STATE_ERROR
	return ReplayContract.build_state_snapshot({
		"state": state_name,
		"position": position,
		"duration": duration,
		"loop": _loop_enabled,
		"rate": _rate,
		"surface_attached": _surface_attached,
		"backend": "mediapipe_replay_http",
		"source": _loaded_source.duplicate(true),
		"status": _cached_status.duplicate(true),
	})

func get_position() -> float:
	return float(_cached_status.get("current_time_sec", 0.0))

func get_duration() -> float:
	return float(_cached_status.get("duration_sec", _loaded_source.get("duration_hint", 0.0)))

func get_media_info() -> Dictionary:
	return {
		"path": _base_url,
		"kind": String(_loaded_source.get("kind", ReplayContract.SOURCE_KIND_URL)),
		"duration": get_duration(),
		"source": String(_cached_status.get("source", _loaded_source.get("path", ""))),
		"fps": float(_cached_status.get("fps", 0.0)),
		"is_file_source": bool(_cached_status.get("is_file_source", false)),
	}

func attach_surface(_node: Node) -> Dictionary:
	_surface_attached = true
	return ReplayContract.ok({"surface_attached": true})

func detach_surface() -> Dictionary:
	_surface_attached = false
	return ReplayContract.ok({"surface_attached": false})

func get_last_error() -> Dictionary:
	return _last_error.duplicate(true)

func refresh_status() -> Dictionary:
	if _base_url.is_empty():
		return _fail("backend_not_loaded", "Replay playback backend has not loaded a source yet.")
	var response := _request_json("%s/playback" % _base_url)
	if not bool(response.get("success", false)):
		return response
	_cached_status = response.get("body", {}).duplicate(true)
	_last_error = {}
	return ReplayContract.ok({"status": _cached_status.duplicate(true)})

func _command_request(path_suffix: String) -> Dictionary:
	if _base_url.is_empty():
		return _fail("backend_not_loaded", "Replay playback backend has not loaded a source yet.")
	var response := _request_json("%s%s" % [_base_url, path_suffix])
	if not bool(response.get("success", false)):
		return response
	_cached_status = response.get("body", {}).duplicate(true)
	_last_error = {}
	return ReplayContract.ok({"status": _cached_status.duplicate(true)})

func _request_json(url: String) -> Dictionary:
	var request_result: Variant = _transport_request.call(url)
	if typeof(request_result) != TYPE_DICTIONARY:
		return _fail("backend_transport_invalid", "Replay playback transport returned an invalid response shape.", {"url": url})
	var result: Dictionary = request_result
	if not bool(result.get("success", false)):
		return _fail(
			String(result.get("code", "backend_transport_failed")),
			String(result.get("message", "Replay playback request failed.")),
			result.get("detail", {"url": url})
		)
	var body_variant: Variant = result.get("body", {})
	if typeof(body_variant) != TYPE_DICTIONARY:
		return _fail("backend_invalid_response", "Replay playback endpoint did not return a JSON object.", {"url": url, "body": body_variant})
	return {
		"success": true,
		"url": url,
		"body": body_variant,
	}

func _default_transport_request(url: String) -> Dictionary:
	var parsed := _parse_http_url(url)
	if parsed.is_empty():
		return {
			"success": false,
			"code": "backend_invalid_url",
			"message": "Replay playback backend supports only HTTP URLs.",
			"detail": {"url": url},
		}
	var client := HTTPClient.new()
	var err := client.connect_to_host(String(parsed.get("host", "")), int(parsed.get("port", 80)))
	if err != OK:
		return {
			"success": false,
			"code": "backend_connect_failed",
			"message": "Unable to connect to replay playback host.",
			"detail": {"url": url, "error": err},
		}
	var wait_err := _wait_for_http_state(client, [HTTPClient.STATUS_CONNECTED])
	if wait_err != OK:
		client.close()
		return {
			"success": false,
			"code": "backend_connect_timeout",
			"message": "Timed out while connecting to replay playback host.",
			"detail": {"url": url, "error": wait_err},
		}
	var request_path := String(parsed.get("path", "/"))
	var request_err := client.request(HTTPClient.METHOD_GET, request_path, PackedStringArray(["Accept: application/json"]))
	if request_err != OK:
		client.close()
		return {
			"success": false,
			"code": "backend_request_failed",
			"message": "Unable to send replay playback request.",
			"detail": {"url": url, "error": request_err, "path": request_path},
		}
	var response_err := _wait_for_http_state(client, [HTTPClient.STATUS_BODY, HTTPClient.STATUS_CONNECTED])
	if response_err != OK:
		client.close()
		return {
			"success": false,
			"code": "backend_response_timeout",
			"message": "Timed out while waiting for replay playback response.",
			"detail": {"url": url, "error": response_err},
		}
	var response_code := client.get_response_code()
	var body_buffer := PackedByteArray()
	while client.get_status() == HTTPClient.STATUS_BODY:
		client.poll()
		var chunk := client.read_response_body_chunk()
		if not chunk.is_empty():
			body_buffer.append_array(chunk)
		OS.delay_usec(HTTP_POLL_INTERVAL_USEC)
	client.close()
	var body_text := body_buffer.get_string_from_utf8()
	var parsed_json: Variant = JSON.parse_string(body_text)
	if response_code < 200 or response_code >= 300:
		return {
			"success": false,
			"code": "backend_http_error",
			"message": "Replay playback endpoint returned HTTP %d." % response_code,
			"detail": {"url": url, "response_code": response_code, "body": parsed_json if parsed_json != null else body_text},
		}
		
	return {
		"success": true,
		"body": parsed_json if typeof(parsed_json) == TYPE_DICTIONARY else {},
		"response_code": response_code,
	}

func _wait_for_http_state(client: HTTPClient, accepted_statuses: Array[int]) -> int:
	var started_usec := Time.get_ticks_usec()
	while Time.get_ticks_usec() - started_usec < HTTP_TIMEOUT_MS * 1000:
		var poll_err := client.poll()
		if poll_err != OK and poll_err != ERR_BUSY:
			return poll_err
		if accepted_statuses.has(client.get_status()):
			return OK
		if client.get_status() == HTTPClient.STATUS_DISCONNECTED:
			return ERR_CONNECTION_ERROR
		OS.delay_usec(HTTP_POLL_INTERVAL_USEC)
	return ERR_TIMEOUT

func _normalize_base_url(path: String) -> String:
	var trimmed := path.strip_edges().trim_suffix("/")
	if trimmed.ends_with("/playback"):
		trimmed = trimmed.trim_suffix("/playback")
	if trimmed.ends_with("/camera"):
		trimmed = trimmed.trim_suffix("/camera")
	return trimmed

func _parse_http_url(url: String) -> Dictionary:
	var normalized := url.strip_edges()
	if not normalized.begins_with("http://"):
		return {}
	var remainder := normalized.trim_prefix("http://")
	var slash_index := remainder.find("/")
	var authority := remainder
	var path := "/"
	if slash_index >= 0:
		authority = remainder.substr(0, slash_index)
		path = remainder.substr(slash_index)
	if authority.is_empty():
		return {}
	var host := authority
	var port := 80
	var colon_index := authority.rfind(":")
	if colon_index > 0:
		host = authority.substr(0, colon_index)
		port = int(authority.substr(colon_index + 1))
	return {
		"host": host,
		"port": port,
		"path": path,
	}

func _fail(code: String, message: String, detail: Dictionary = {}) -> Dictionary:
	_last_error = ReplayContract.fail(code, message, detail)
	return _last_error.duplicate(true)
