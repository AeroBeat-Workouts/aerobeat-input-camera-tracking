extends SceneTree

const OUTPUT_DIR := "res://../.plans/mediapipe-python/artifacts/task10u-replay-transport-qa"
const OUTPUT_JSON := "boxing_replay_transport_playback_state_probe.json"
const OUTPUT_MD := "task10u-summary.md"
const OUTPUT_SUMMARY_JSON := "task10u-summary.json"
const SCENE_PATH := "res://scenes/boxing_proving.tscn"
const FIXTURE_PATH := "res://assets/fixtures/boxing/punch_left/boxing_guard->punch_left_repeat_04_take_01.mp4"
const STARTUP_MODE_GODOT_ONLY_DEBUG := 2
const PAUSE_SETTLE_MS := 700
const HOLD_SETTLE_MS := 900
const RESUME_SETTLE_MS := 900

var _scene_root: Control = null
var _harness: Node = null
var _result := {}

func _initialize() -> void:
	root.size = Vector2i(1280, 720)
	await _run()

func _run() -> void:
	var packed: PackedScene = load(SCENE_PATH)
	if packed == null:
		push_error("Failed to load %s" % SCENE_PATH)
		quit(2)
		return
	var node := packed.instantiate()
	if not node is Control:
		push_error("Scene root is not Control: %s" % SCENE_PATH)
		quit(3)
		return
	_scene_root = node
	_harness = node
	if _harness != null:
		_harness.set("startup_mode", STARTUP_MODE_GODOT_ONLY_DEBUG)
		_harness.set("prerecorded_video_source", FIXTURE_PATH)
	root.add_child(_scene_root)
	await process_frame
	await process_frame
	await _wait_ms(2200)
	await _collect_probe()

func _collect_probe() -> void:
	if _harness == null:
		quit(4)
		return
	_harness.call("_refresh_playback_status", true)
	await process_frame
	await process_frame

	var initial_controller: Dictionary = _dict(_harness.call("_get_playback_controller_state"))
	var initial_transport: Dictionary = _dict(_harness.get("_playback_transport_status"))
	var initial_capabilities: Dictionary = _dict(_harness.get("_playback_transport_capabilities"))
	var initial_ui: Dictionary = _ui_snapshot()
	var initial_status: Dictionary = _dict(_harness.get("_playback_status"))
	var step_attempt_result: Dictionary = _dict(_harness.call("_playback_controller_step_frames", 1))
	await process_frame
	await process_frame

	_harness.call("_on_playback_toggle_pressed")
	await _wait_ms(PAUSE_SETTLE_MS)
	_harness.call("_refresh_playback_status", true)
	await process_frame
	var paused_controller: Dictionary = _dict(_harness.call("_get_playback_controller_state"))
	var paused_transport: Dictionary = _dict(_harness.get("_playback_transport_status"))
	var paused_status: Dictionary = _dict(_harness.get("_playback_status"))
	var paused_ui: Dictionary = _ui_snapshot()

	await _wait_ms(HOLD_SETTLE_MS)
	_harness.call("_refresh_playback_status", true)
	await process_frame
	var held_controller: Dictionary = _dict(_harness.call("_get_playback_controller_state"))
	var held_transport: Dictionary = _dict(_harness.get("_playback_transport_status"))
	var held_status: Dictionary = _dict(_harness.get("_playback_status"))

	var seek_slider: HSlider = _harness.get("_playback_seek_slider") as HSlider
	if seek_slider != null:
		seek_slider.value = 0.70
	_harness.call("_on_playback_seek_drag_ended", true)
	await _wait_ms(PAUSE_SETTLE_MS)
	_harness.call("_refresh_playback_status", true)
	await process_frame
	var seek_controller: Dictionary = _dict(_harness.call("_get_playback_controller_state"))
	var seek_transport: Dictionary = _dict(_harness.get("_playback_transport_status"))
	var seek_status: Dictionary = _dict(_harness.get("_playback_status"))

	await _wait_ms(HOLD_SETTLE_MS)
	_harness.call("_refresh_playback_status", true)
	await process_frame
	var paused_after_seek_controller: Dictionary = _dict(_harness.call("_get_playback_controller_state"))
	var paused_after_seek_transport: Dictionary = _dict(_harness.get("_playback_transport_status"))
	var paused_after_seek_status: Dictionary = _dict(_harness.get("_playback_status"))

	_harness.call("_on_playback_toggle_pressed")
	await _wait_ms(RESUME_SETTLE_MS)
	_harness.call("_refresh_playback_status", true)
	await process_frame
	var resumed_controller: Dictionary = _dict(_harness.call("_get_playback_controller_state"))
	var resumed_transport: Dictionary = _dict(_harness.get("_playback_transport_status"))
	var resumed_status: Dictionary = _dict(_harness.get("_playback_status"))

	_result = {
		"captured_at": Time.get_datetime_string_from_system(true, true),
		"scene": SCENE_PATH,
		"fixture": FIXTURE_PATH,
		"transport_capabilities": initial_capabilities,
		"transport_status_initial": initial_transport,
		"ui_initial": initial_ui,
		"step_attempt_result": step_attempt_result,
		"controller_states": {
			"initial_state": initial_controller,
			"initial_playback_status": initial_status,
			"paused_state": paused_controller,
			"paused_playback_status": paused_status,
			"paused_transport_status": paused_transport,
			"paused_ui": paused_ui,
			"held_paused_state": held_controller,
			"held_paused_playback_status": held_status,
			"held_paused_transport_status": held_transport,
			"seek_state": seek_controller,
			"seek_playback_status": seek_status,
			"seek_transport_status": seek_transport,
			"paused_after_seek_state": paused_after_seek_controller,
			"paused_after_seek_playback_status": paused_after_seek_status,
			"paused_after_seek_transport_status": paused_after_seek_transport,
			"resumed_state": resumed_controller,
			"resumed_playback_status": resumed_status,
			"resumed_transport_status": resumed_transport,
		},
	}
	_result["qa_truth"] = _qa_truth(_result)
	_write_outputs()
	print(JSON.stringify(_result, "\t"))
	quit(0)

func _ui_snapshot() -> Dictionary:
	var status_label: Label = _harness.get("status_label") as Label
	var step_status_label: Label = _harness.get("_playback_step_status_label") as Label
	var step_back_button: Button = _harness.get("_playback_step_back_button") as Button
	var step_forward_button: Button = _harness.get("_playback_step_forward_button") as Button
	return {
		"status_label": status_label.text if status_label else "",
		"step_status_label": step_status_label.text if step_status_label else "",
		"step_back_disabled": step_back_button.disabled if step_back_button else true,
		"step_forward_disabled": step_forward_button.disabled if step_forward_button else true,
		"can_step_paused_playback": bool(_harness.call("_can_step_paused_playback")),
	}

func _qa_truth(data: Dictionary) -> Dictionary:
	var initial_ui: Dictionary = data.get("ui_initial", {})
	var initial_transport: Dictionary = data.get("transport_status_initial", {})
	var step_result: Dictionary = data.get("step_attempt_result", {})
	var states: Dictionary = data.get("controller_states", {})
	var paused_status: Dictionary = states.get("paused_playback_status", {})
	var held_status: Dictionary = states.get("held_paused_playback_status", {})
	var seek_status: Dictionary = states.get("seek_playback_status", {})
	var paused_after_seek_status: Dictionary = states.get("paused_after_seek_playback_status", {})
	var resumed_status: Dictionary = states.get("resumed_playback_status", {})
	return {
		"scene_consumes_transport_surface": String(initial_ui.get("step_status_label", "")).contains("approx_time_seek") and bool(initial_ui.get("step_back_disabled", false)) and bool(initial_ui.get("step_forward_disabled", false)),
		"exact_step_ui_truthful_for_shipped_path": String(step_result.get("code", "")) == "backend_transport_unsupported" and String(initial_transport.get("transport_mode", "")) == "approx_time_seek",
		"shipped_path_exact_support_proven_end_to_end": bool(initial_transport.get("can_seek_frame", false)) and bool(initial_transport.get("can_step_forward", false)) and bool(initial_transport.get("can_step_backward", false)),
		"observed_transport_mode": initial_transport.get("transport_mode", ""),
		"observed_limit_code": initial_transport.get("limitation_code", ""),
		"pause_persists_in_headless_boxing_probe": bool(paused_status.get("paused", false)) and bool(held_status.get("paused", false)) and _approx_eq(float(paused_status.get("current_time_sec", 0.0)), float(held_status.get("current_time_sec", 0.0)), 0.05),
		"seek_while_paused_preserves_pause": bool(seek_status.get("paused", false)) and bool(paused_after_seek_status.get("paused", false)) and _approx_eq(float(seek_status.get("current_time_sec", 0.0)), float(paused_after_seek_status.get("current_time_sec", 0.0)), 0.05),
		"resume_restores_playback": not bool(resumed_status.get("paused", true)) and float(resumed_status.get("current_time_sec", 0.0)) > float(paused_after_seek_status.get("current_time_sec", 0.0)),
	}

func _write_outputs() -> void:
	var abs_dir := ProjectSettings.globalize_path(OUTPUT_DIR)
	DirAccess.make_dir_recursive_absolute(abs_dir)
	_write_text(abs_dir.path_join(OUTPUT_JSON), JSON.stringify(_result, "\t"))
	var summary_json := {
		"fixture": FIXTURE_PATH,
		"scene": SCENE_PATH,
		"transport_capabilities": _result.get("transport_capabilities", {}),
		"transport_status_initial": _result.get("transport_status_initial", {}),
		"ui_initial": _result.get("ui_initial", {}),
		"step_attempt_result": _result.get("step_attempt_result", {}),
		"controller_states": _result.get("controller_states", {}),
		"qa_truth": _result.get("qa_truth", {}),
	}
	_write_text(abs_dir.path_join(OUTPUT_SUMMARY_JSON), JSON.stringify(summary_json, "\t"))
	_write_text(abs_dir.path_join(OUTPUT_MD), _build_summary_md(summary_json))

func _build_summary_md(summary: Dictionary) -> String:
	var transport: Dictionary = summary.get("transport_capabilities", {})
	var ui: Dictionary = summary.get("ui_initial", {})
	var step_result: Dictionary = summary.get("step_attempt_result", {})
	var states: Dictionary = summary.get("controller_states", {})
	var truth: Dictionary = summary.get("qa_truth", {})
	var lines := PackedStringArray([
		"# Task 10U QA Summary",
		"",
		"- Rerun: pause-hold seam repair verification after Task 10W",
		"- Scene: `%s`" % String(summary.get("scene", "")),
		"- Fixture: `%s`" % String(summary.get("fixture", "")),
		"",
		"## Observed replay transport truth",
		"",
		"- `transport_mode`: `%s`" % String(transport.get("transport_mode", "")),
		"- `can_step_forward`: `%s`" % str(bool(transport.get("can_step_forward", false))),
		"- `can_step_backward`: `%s`" % str(bool(transport.get("can_step_backward", false))),
		"- `can_seek_frame`: `%s`" % str(bool(transport.get("can_seek_frame", false))),
		"- `exactness_note`: `%s`" % String(transport.get("exactness_note", "")),
		"- `limitation_code`: `%s`" % String(transport.get("limitation_code", "")),
		"",
		"## Boxing proving UI evidence",
		"",
		"- Status label: `%s`" % String(ui.get("status_label", "")),
		"- Step status label: `%s`" % String(ui.get("step_status_label", "")),
		"- Step back disabled: `%s`" % str(bool(ui.get("step_back_disabled", false))),
		"- Step forward disabled: `%s`" % str(bool(ui.get("step_forward_disabled", false))),
		"- Can step paused playback: `%s`" % str(bool(ui.get("can_step_paused_playback", false))),
		"",
		"## Step attempt result",
		"",
		"```json",
		JSON.stringify(step_result, "\t"),
		"```",
		"",
		"## Playback controller observations",
		"",
		"- `initial_state`: state=`%s` position=`%s` paused=`%s`" % [_state_name(states, "initial_playback_status"), _state_time(states, "initial_playback_status"), str(bool((states.get("initial_playback_status", {}) as Dictionary).get("paused", false)))],
		"- `paused_state`: state=`%s` position=`%s` paused=`%s`" % [_state_name(states, "paused_state"), _state_time(states, "paused_playback_status"), str(bool((states.get("paused_playback_status", {}) as Dictionary).get("paused", false)))],
		"- `held_paused_state`: state=`%s` position=`%s` paused=`%s`" % [_state_name(states, "held_paused_state"), _state_time(states, "held_paused_playback_status"), str(bool((states.get("held_paused_playback_status", {}) as Dictionary).get("paused", false)))],
		"- `seek_state`: state=`%s` position=`%s` paused=`%s`" % [_state_name(states, "seek_state"), _state_time(states, "seek_playback_status"), str(bool((states.get("seek_playback_status", {}) as Dictionary).get("paused", false)))],
		"- `paused_after_seek_state`: state=`%s` position=`%s` paused=`%s`" % [_state_name(states, "paused_after_seek_state"), _state_time(states, "paused_after_seek_playback_status"), str(bool((states.get("paused_after_seek_playback_status", {}) as Dictionary).get("paused", false)))],
		"- `resumed_state`: state=`%s` position=`%s` paused=`%s`" % [_state_name(states, "resumed_state"), _state_time(states, "resumed_playback_status"), str(bool((states.get("resumed_playback_status", {}) as Dictionary).get("paused", false)))],
		"",
		"## QA truth",
		"",
		"- `scene_consumes_transport_surface`: `%s`" % str(bool(truth.get("scene_consumes_transport_surface", false))),
		"- `exact_step_ui_truthful_for_shipped_path`: `%s`" % str(bool(truth.get("exact_step_ui_truthful_for_shipped_path", false))),
		"- `shipped_path_exact_support_proven_end_to_end`: `%s`" % str(bool(truth.get("shipped_path_exact_support_proven_end_to_end", false))),
		"- `observed_transport_mode`: `%s`" % String(truth.get("observed_transport_mode", "")),
		"- `observed_limit_code`: `%s`" % String(truth.get("observed_limit_code", "")),
		"- `pause_persists_in_headless_boxing_probe`: `%s`" % str(bool(truth.get("pause_persists_in_headless_boxing_probe", false))),
		"- `seek_while_paused_preserves_pause`: `%s`" % str(bool(truth.get("seek_while_paused_preserves_pause", false))),
		"- `resume_restores_playback`: `%s`" % str(bool(truth.get("resume_restores_playback", false))),
	])
	return "\n".join(lines) + "\n"

func _state_name(states: Dictionary, key: String) -> String:
	var state: Dictionary = states.get(key, {})
	if state.is_empty() and key.ends_with("_playback_status"):
		state = states.get(key.replace("_playback_status", "_state"), {})
	return String(state.get("state", ""))

func _state_time(states: Dictionary, key: String) -> String:
	var state: Dictionary = states.get(key, {})
	var playback_status: Dictionary = states.get(key, {})
	if key.ends_with("_state"):
		playback_status = states.get(key.replace("_state", "_playback_status"), {})
	return str(playback_status.get("current_time_sec", state.get("position", 0.0)))

func _dict(value: Variant) -> Dictionary:
	if value is Dictionary:
		return (value as Dictionary).duplicate(true)
	return {}

func _dup(value: Variant) -> Variant:
	if value is Dictionary:
		return (value as Dictionary).duplicate(true)
	if value is Array:
		return (value as Array).duplicate(true)
	return value

func _write_text(path: String, content: String) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_error("Failed to write %s" % path)
		return
	file.store_string(content)
	file.close()

func _wait_ms(duration_ms: int) -> void:
	await create_timer(float(duration_ms) / 1000.0).timeout

func _approx_eq(a: float, b: float, tolerance: float) -> bool:
	return absf(a - b) <= tolerance
