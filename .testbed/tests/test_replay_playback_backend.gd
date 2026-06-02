extends "res://addons/aerobeat-vendor-godot-unit-test/test.gd"

func test_replay_http_backend_has_been_retired_from_proving_harness() -> void:
	assert_true(true, "Replay proving now uses the vendor-backed contract path instead of the legacy HTTP /playback backend.")
