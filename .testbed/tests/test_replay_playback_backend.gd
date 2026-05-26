extends "res://addons/gut/test.gd"

const BackendScript := preload("res://addons/aerobeat-input-camera-tracking/src/AeroMediaPipeReplayPlaybackBackend.gd")

var _requests: Array[String] = []
var _responses: Dictionary = {}

func before_each() -> void:
	_requests.clear()
	_responses.clear()

func test_load_normalizes_camera_stream_base_url_and_primes_status() -> void:
	_responses["http://127.0.0.1:4243/playback"] = {
		"success": true,
		"body": {
			"paused": true,
			"current_time_sec": 3.5,
			"duration_sec": 12.0,
			"progress": 3.5 / 12.0,
			"is_file_source": true,
		},
	}
	var backend = _make_backend()
	var result: Dictionary = backend.load({
		"path": "http://127.0.0.1:4243/camera",
		"kind": "url",
	})
	assert_true(bool(result.get("success", false)), "load should succeed against replay status endpoint")
	assert_eq(["http://127.0.0.1:4243/playback"], _requests, "load should poll the replay playback status endpoint")
	assert_eq(3.5, backend.get_position())
	assert_eq(12.0, backend.get_duration())
	assert_eq("paused", String(backend.get_state().get("state", "")))

func test_play_pause_seek_and_stop_delegate_through_transport_facade() -> void:
	_responses["http://127.0.0.1:4243/playback"] = {
		"success": true,
		"body": {"paused": true, "current_time_sec": 0.0, "duration_sec": 10.0, "progress": 0.0},
	}
	_responses["http://127.0.0.1:4243/playback/play"] = {
		"success": true,
		"body": {"paused": false, "current_time_sec": 0.0, "duration_sec": 10.0, "progress": 0.0},
	}
	_responses["http://127.0.0.1:4243/playback/pause"] = {
		"success": true,
		"body": {"paused": true, "current_time_sec": 0.0, "duration_sec": 10.0, "progress": 0.0},
	}
	_responses["http://127.0.0.1:4243/playback/seek?seconds=5.000000"] = {
		"success": true,
		"body": {"paused": true, "current_time_sec": 5.0, "duration_sec": 10.0, "progress": 0.5},
	}
	_responses["http://127.0.0.1:4243/playback/seek?seconds=0.000000"] = {
		"success": true,
		"body": {"paused": true, "current_time_sec": 0.0, "duration_sec": 10.0, "progress": 0.0},
	}
	var backend = _make_backend()
	backend.load({"path": "http://127.0.0.1:4243", "kind": "url"})

	assert_true(bool(backend.play().get("success", false)))
	assert_eq("playing", String(backend.get_state().get("state", "")))
	assert_true(bool(backend.pause().get("success", false)))
	assert_eq("paused", String(backend.get_state().get("state", "")))
	assert_true(bool(backend.seek(5.0).get("success", false)))
	assert_eq(5.0, backend.get_position())
	assert_true(bool(backend.stop().get("success", false)))
	assert_eq(0.0, backend.get_position())
	assert_eq([
		"http://127.0.0.1:4243/playback",
		"http://127.0.0.1:4243/playback/play",
		"http://127.0.0.1:4243/playback/pause",
		"http://127.0.0.1:4243/playback/seek?seconds=5.000000",
		"http://127.0.0.1:4243/playback/pause",
		"http://127.0.0.1:4243/playback/seek?seconds=0.000000",
	], _requests)

func test_backend_rejects_loop_and_non_default_rate_updates() -> void:
	var backend = _make_backend()
	var loop_result: Dictionary = backend.set_loop(true)
	var rate_result: Dictionary = backend.set_rate(1.25)
	assert_false(bool(loop_result.get("success", true)), "loop enable should be rejected because backend does not own that policy")
	assert_false(bool(rate_result.get("success", true)), "rate changes should be rejected because backend does not own that policy")

func _make_backend():
	var backend = BackendScript.new()
	backend.set_transport_request(Callable(self, "_fake_transport_request"))
	return backend

func _fake_transport_request(url: String) -> Dictionary:
	_requests.append(url)
	if _responses.has(url):
		return _responses[url]
	return {
		"success": false,
		"code": "missing_stub",
		"message": "No stubbed response for %s" % url,
		"detail": {"url": url},
	}
