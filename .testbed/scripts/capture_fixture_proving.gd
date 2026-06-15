extends SceneTree

const DEFAULT_CAPTURE_DELAY_MS := 5000
const DEFAULT_VIEWPORT_SIZE := Vector2i(1280, 720)
const BOOTSTRAP_EXIT_ADDONS := 6
const BOOTSTRAP_EXIT_IMPORTS := 7
const TESTBED_ADDONS_MANIFEST_PATH := "res://addons.jsonc"
const TESTBED_PROJECT_CONFIG_PATH := "res://project.godot"
const TESTBED_IMPORTED_CACHE_PATH := "res://.godot/imported"
const REMAPPED_RESOURCE_TYPES := {
	"Texture2D": true,
	"CompressedTexture2D": true,
}

var _scene_path := ""
var _fixture_path := ""
var _output_dir := ""
var _capture_delay_ms := DEFAULT_CAPTURE_DELAY_MS
var _scene_root: Control = null
var _started_at_ms := 0
var _captured := false

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() < 3:
		push_error("usage: <scene_path> <fixture_path> <output_dir> [capture_delay_ms]")
		quit(2)
		return

	_scene_path = args[0]
	_fixture_path = args[1]
	_output_dir = args[2]
	if args.size() >= 4 and String(args[3]).is_valid_int():
		_capture_delay_ms = max(int(args[3]), 1000)

	DirAccess.make_dir_recursive_absolute(_output_dir)
	root.size = DEFAULT_VIEWPORT_SIZE
	_started_at_ms = Time.get_ticks_msec()

	var bootstrap_report := _verify_capture_bootstrap(_scene_path)
	if not bool(bootstrap_report.get("ok", false)):
		_write_bootstrap_failure_artifacts(bootstrap_report)
		_report_bootstrap_failures(bootstrap_report)
		quit(int(bootstrap_report.get("exit_code", BOOTSTRAP_EXIT_ADDONS)))
		return

	var packed: PackedScene = load(_scene_path)
	if packed == null:
		push_error("failed to load scene: %s" % _scene_path)
		quit(3)
		return

	var node := packed.instantiate()
	if not node is Control:
		push_error("scene root is not a Control: %s" % _scene_path)
		quit(4)
		return

	_scene_root = node
	_force_fixture_runtime_settings(_scene_root)
	root.add_child(_scene_root)
	call_deferred("_run_capture_sequence")

func _verify_capture_bootstrap(scene_path: String) -> Dictionary:
	var addon_failures: Array[String] = []
	var import_failures: Array[String] = []
	var warnings: Array[String] = []
	_verify_addon_installation(addon_failures)
	_verify_import_bootstrap(scene_path, import_failures, warnings)
	var failures: Array[String] = []
	failures.append_array(addon_failures)
	failures.append_array(import_failures)
	var exit_code := 0
	if not addon_failures.is_empty():
		exit_code = BOOTSTRAP_EXIT_ADDONS
	elif not import_failures.is_empty():
		exit_code = BOOTSTRAP_EXIT_IMPORTS
	return {
		"ok": failures.is_empty(),
		"exit_code": exit_code,
		"failures": failures,
		"warnings": warnings,
		"checks": {
			"addons": {
				"ok": addon_failures.is_empty(),
				"failures": addon_failures,
			},
			"imports": {
				"ok": import_failures.is_empty(),
				"failures": import_failures,
				"checked_resources": _collect_remapped_resource_paths(scene_path),
			},
		},
	}

func _verify_addon_installation(failures: Array[String]) -> void:
	var manifest_path := ProjectSettings.globalize_path(TESTBED_ADDONS_MANIFEST_PATH)
	if not FileAccess.file_exists(manifest_path):
		failures.append("Missing testbed addon manifest: %s" % manifest_path)
		return
	var manifest_text := FileAccess.get_file_as_string(manifest_path)
	var manifest_variant: Variant = JSON.parse_string(manifest_text)
	if not manifest_variant is Dictionary:
		failures.append("Failed to parse testbed addon manifest as JSON: %s" % manifest_path)
		return
	var manifest: Dictionary = manifest_variant
	var addons: Dictionary = manifest.get("addons", {}) if manifest.get("addons", {}) is Dictionary else {}
	if addons.is_empty():
		failures.append("Testbed addon manifest did not declare any addons: %s" % manifest_path)
		return
	for addon_name_variant: Variant in addons.keys():
		var addon_name := String(addon_name_variant).strip_edges()
		if addon_name.is_empty():
			continue
		var addon_dir := ProjectSettings.globalize_path("res://addons/%s" % addon_name)
		if not DirAccess.dir_exists_absolute(addon_dir):
			failures.append("Missing installed addon directory: %s (run godotenv-sync to restore .testbed/addons)" % addon_dir)
	var project_config := ConfigFile.new()
	var project_err := project_config.load(ProjectSettings.globalize_path(TESTBED_PROJECT_CONFIG_PATH))
	if project_err != OK:
		failures.append("Failed to load testbed project config: %s (err=%d)" % [ProjectSettings.globalize_path(TESTBED_PROJECT_CONFIG_PATH), project_err])
		return
	for autoload_name: String in project_config.get_section_keys("autoload"):
		var autoload_path := String(project_config.get_value("autoload", autoload_name, "")).trim_prefix("*").strip_edges()
		if autoload_path.is_empty():
			failures.append("Autoload '%s' is empty in %s" % [autoload_name, TESTBED_PROJECT_CONFIG_PATH])
			continue
		var autoload_abs := ProjectSettings.globalize_path(autoload_path)
		if not FileAccess.file_exists(autoload_abs):
			failures.append("Missing autoload script for '%s': %s" % [autoload_name, autoload_abs])

func _verify_import_bootstrap(scene_path: String, failures: Array[String], warnings: Array[String]) -> void:
	var imported_cache_dir := ProjectSettings.globalize_path(TESTBED_IMPORTED_CACHE_PATH)
	if not DirAccess.dir_exists_absolute(imported_cache_dir):
		failures.append("Missing imported cache directory: %s (open/import the .testbed project before capture)" % imported_cache_dir)
		return
	var resource_paths := _collect_remapped_resource_paths(scene_path)
	if resource_paths.is_empty():
		warnings.append("No remapped scene resources were discovered for import preflight: %s" % scene_path)
	for resource_path: String in resource_paths:
		var import_sidecar := ProjectSettings.globalize_path("%s.import" % resource_path)
		if not FileAccess.file_exists(import_sidecar):
			failures.append("Missing import remap sidecar for %s: %s" % [resource_path, import_sidecar])
			continue
		var import_config := ConfigFile.new()
		var import_err := import_config.load(import_sidecar)
		if import_err != OK:
			failures.append("Failed to read import remap sidecar for %s: %s (err=%d)" % [resource_path, import_sidecar, import_err])
			continue
		var dest_files_variant: Variant = import_config.get_value("deps", "dest_files", PackedStringArray())
		var dest_files: Array[String] = []
		if dest_files_variant is PackedStringArray:
			for dest_path_variant: Variant in dest_files_variant:
				dest_files.append(String(dest_path_variant))
		elif dest_files_variant is Array:
			for dest_path_variant: Variant in dest_files_variant:
				dest_files.append(String(dest_path_variant))
		if dest_files.is_empty():
			failures.append("Import remap sidecar for %s did not declare any destination files: %s" % [resource_path, import_sidecar])
			continue
		for dest_path: String in dest_files:
			var dest_abs := ProjectSettings.globalize_path(dest_path)
			if not FileAccess.file_exists(dest_abs):
				failures.append("Missing imported asset for %s: %s" % [resource_path, dest_abs])

func _collect_remapped_resource_paths(scene_path: String) -> Array[String]:
	var resources: Array[String] = []
	var project_config := ConfigFile.new()
	if project_config.load(ProjectSettings.globalize_path(TESTBED_PROJECT_CONFIG_PATH)) == OK:
		var project_icon := String(project_config.get_value("config", "icon", "")).strip_edges()
		if not project_icon.is_empty() and not resources.has(project_icon):
			resources.append(project_icon)
	var scene_file_path := ProjectSettings.globalize_path(scene_path)
	if not FileAccess.file_exists(scene_file_path):
		return resources
	var scene_text := FileAccess.get_file_as_string(scene_file_path)
	var path_regex := RegEx.new()
	var compile_err := path_regex.compile('path="([^"]+)"')
	if compile_err != OK:
		return resources
	for raw_line: String in scene_text.split("\n"):
		var line := raw_line.strip_edges()
		if not line.begins_with("[ext_resource"):
			continue
		var type_name := _extract_scene_ext_resource_type(line)
		if not REMAPPED_RESOURCE_TYPES.has(type_name):
			continue
		var match := path_regex.search(line)
		if match == null:
			continue
		var resource_path := String(match.get_string(1)).strip_edges()
		if resource_path.is_empty() or resources.has(resource_path):
			continue
		resources.append(resource_path)
	return resources

func _extract_scene_ext_resource_type(line: String) -> String:
	var marker := 'type="'
	var marker_index := line.find(marker)
	if marker_index < 0:
		return ""
	var value_start := marker_index + marker.length()
	var value_end := line.find('"', value_start)
	if value_end < 0:
		return ""
	return line.substr(value_start, value_end - value_start)

func _write_bootstrap_failure_artifacts(bootstrap_report: Dictionary) -> void:
	var elapsed_ms := Time.get_ticks_msec() - _started_at_ms
	var report_json_path := _output_dir.path_join("report.json")
	var report_md_path := _output_dir.path_join("report.md")
	var report := {
		"fixture_path": ProjectSettings.globalize_path(_fixture_path),
		"video_path": OS.get_environment("AEROBEAT_CAMERA_TRACKING_SOURCE"),
		"scene_path": _scene_path,
		"captured_at": Time.get_datetime_string_from_system(true, true),
		"elapsed_ms": elapsed_ms,
		"screenshot_path": "",
		"viewport_size": {"width": root.size.x, "height": root.size.y},
		"status": {
			"title": "",
			"status_label": "Bootstrap preflight failed",
			"live_status": "",
			"notes": "",
			"camera_streaming": false,
			"camera_has_texture": false,
			"server_pid": -1,
			"provider_present": false,
		},
		"surfaces": {},
		"fixture_capture": {},
		"bootstrap": bootstrap_report,
	}
	_write_text_file(report_json_path, JSON.stringify(report, "\t"))
	_write_text_file(report_md_path, _build_markdown_report(report))
	print("[FixtureCapture] bootstrap_report_json=%s report_md=%s" % [report_json_path, report_md_path])

func _report_bootstrap_failures(bootstrap_report: Dictionary) -> void:
	for failure: String in bootstrap_report.get("failures", []):
		push_error("[FixtureCapture][Bootstrap] %s" % failure)
	for warning: String in bootstrap_report.get("warnings", []):
		push_warning("[FixtureCapture][Bootstrap] %s" % warning)

func _force_fixture_runtime_settings(node: Node) -> void:
	for property_variant: Variant in node.get_property_list():
		var property_info: Dictionary = property_variant if property_variant is Dictionary else {}
		var property_name := String(property_info.get("name", ""))
		if property_name == "startup_mode":
			node.set("startup_mode", 0)
		elif property_name == "prerecorded_video_source":
			var video_source := OS.get_environment("AEROBEAT_CAMERA_TRACKING_SOURCE")
			if not video_source.is_empty():
				node.set("prerecorded_video_source", video_source)

func _run_capture_sequence() -> void:
	if _captured or _scene_root == null:
		quit(5)
		return
	await create_timer(float(_capture_delay_ms) / 1000.0).timeout
	if _captured or _scene_root == null:
		quit(5)
		return
	var elapsed_ms := Time.get_ticks_msec() - _started_at_ms
	_captured = true
	await process_frame
	await process_frame
	await _capture_outputs(elapsed_ms)
	quit(0)

func _capture_outputs(elapsed_ms: int) -> void:
	var screenshot_path := _output_dir.path_join("proving.png")
	var report_json_path := _output_dir.path_join("report.json")
	var report_md_path := _output_dir.path_join("report.md")

	var root_texture := root.get_texture()
	if root_texture != null:
		var image := root_texture.get_image()
		if image != null:
			var save_err := image.save_png(screenshot_path)
			if save_err != OK:
				push_warning("failed to save screenshot to %s (err=%d)" % [screenshot_path, save_err])
		else:
			push_warning("failed to capture screenshot image for %s" % screenshot_path)
	else:
		push_warning("failed to capture screenshot texture for %s" % screenshot_path)

	var harness_report := _collect_harness_report(elapsed_ms, screenshot_path)
	_write_text_file(report_json_path, JSON.stringify(harness_report, "\t"))
	_write_text_file(report_md_path, _build_markdown_report(harness_report))
	print("[FixtureCapture] screenshot=%s report_json=%s report_md=%s" % [screenshot_path, report_json_path, report_md_path])

func _collect_harness_report(elapsed_ms: int, screenshot_path: String) -> Dictionary:
	var report := {
		"fixture_path": ProjectSettings.globalize_path(_fixture_path),
		"video_path": OS.get_environment("AEROBEAT_CAMERA_TRACKING_SOURCE"),
		"scene_path": _scene_path,
		"captured_at": Time.get_datetime_string_from_system(true, true),
		"elapsed_ms": elapsed_ms,
		"screenshot_path": screenshot_path,
		"viewport_size": {"width": root.size.x, "height": root.size.y},
		"status": {},
		"surfaces": {},
		"fixture_capture": {},
	}

	var status_label := _scene_root.get_node_or_null("Margin/VSplit/Header/StatusLabel") as Label
	var live_status_label := _scene_root.get_node_or_null("Margin/VSplit/Header/LiveStatusLabel") as RichTextLabel
	var title_label := _scene_root.find_child("TitleLabel", true, false) as Label
	var notes_label := _scene_root.get_node_or_null("Margin/VSplit/Header/NotesLabel") as Label
	var quick_stats_label := _scene_root.get_node_or_null("Margin/VSplit/Content/LeftColumn/QuickStatsPanel/QuickStats") as RichTextLabel
	var summary_label := _scene_root.get_node_or_null("Margin/VSplit/Content/RightPanelScroll/RightColumn/SummaryPanel/Summary") as RichTextLabel
	var signal_status_label := _scene_root.get_node_or_null("Margin/VSplit/Content/RightPanelScroll/RightColumn/SignalPanel/SignalStatus") as RichTextLabel
	var metrics_label := _scene_root.get_node_or_null("Margin/VSplit/Content/RightPanelScroll/RightColumn/MetricsPanel/Metrics") as RichTextLabel
	var events_label := _scene_root.get_node_or_null("Margin/VSplit/Content/RightPanelScroll/RightColumn/EventsPanel/Events") as RichTextLabel
	var camera_display := _scene_root.get_node_or_null("Margin/VSplit/Content/LeftColumn/CameraPanel/CameraView") as TextureRect
	if camera_display == null:
		camera_display = _scene_root.find_child("PreviewSurface", true, false) as TextureRect
	if camera_display == null:
		camera_display = _scene_root.get_node_or_null("Margin/VSplit/Content/LeftColumn/CameraPanel/CameraDisplay") as TextureRect
	var auto_start := _scene_root.get_node_or_null("AutoStartManager")
	var provider: Variant = _scene_root.get("provider") if _scene_root != null else null

	report["status"] = {
		"title": title_label.text if title_label else "",
		"status_label": status_label.text if status_label else "",
		"live_status": live_status_label.text if live_status_label else "",
		"notes": notes_label.text if notes_label else "",
		"camera_streaming": camera_display.visible if camera_display else false,
		"camera_has_texture": camera_display.texture != null if camera_display else false,
		"server_pid": int(auto_start.get("server_pid")) if auto_start != null else -1,
		"provider_present": provider != null,
	}

	report["surfaces"] = {
		"quick_stats": _node_text(quick_stats_label),
		"summary": _node_text(summary_label),
		"signal_status": _node_text(signal_status_label),
		"metrics": _node_text(metrics_label),
		"events": _node_text(events_label),
	}
	if _scene_root != null and _scene_root.has_method("get_fixture_capture_report"):
		report["fixture_capture"] = _scene_root.call("get_fixture_capture_report")
	return report

func _node_text(node: Node) -> String:
	if node == null:
		return ""
	if node is RichTextLabel:
		return (node as RichTextLabel).text
	if node is Label:
		return (node as Label).text
	return ""

func _write_text_file(path: String, content: String) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_warning("failed to open output file: %s" % path)
		return
	file.store_string(content)
	file.close()

func _build_markdown_report(report: Dictionary) -> String:
	var status: Dictionary = report.get("status", {})
	var surfaces: Dictionary = report.get("surfaces", {})
	var bootstrap: Dictionary = report.get("bootstrap", {}) if report.get("bootstrap", {}) is Dictionary else {}
	var lines := PackedStringArray([
		"# Proving Fixture Capture",
		"",
		"- Fixture: `%s`" % String(report.get("fixture_path", "")),
		"- Video: `%s`" % String(report.get("video_path", "")),
		"- Scene: `%s`" % String(report.get("scene_path", "")),
		"- Captured: `%s`" % String(report.get("captured_at", "")),
		"- Elapsed: `%dms`" % int(report.get("elapsed_ms", 0)),
		"- Screenshot: `%s`" % String(report.get("screenshot_path", "")),
		"",
		"## Status",
		"",
		"- Title: %s" % String(status.get("title", "")),
		"- Status label: %s" % String(status.get("status_label", "")),
		"- Live status: %s" % String(status.get("live_status", "")),
		"- Camera streaming: %s" % str(bool(status.get("camera_streaming", false))),
		"- Camera has texture: %s" % str(bool(status.get("camera_has_texture", false))),
		"- Server PID: %d" % int(status.get("server_pid", -1)),
		"- Provider present: %s" % str(bool(status.get("provider_present", false))),
		"",
	])

	if not bootstrap.is_empty():
		lines.append("## Bootstrap preflight")
		lines.append("")
		lines.append("- OK: %s" % str(bool(bootstrap.get("ok", false))))
		lines.append("- Exit code: %d" % int(bootstrap.get("exit_code", 0)))
		for failure_variant: Variant in bootstrap.get("failures", []):
			lines.append("- Failure: %s" % String(failure_variant))
		for warning_variant: Variant in bootstrap.get("warnings", []):
			lines.append("- Warning: %s" % String(warning_variant))
		lines.append("")

	for section_name in ["quick_stats", "summary", "signal_status", "metrics", "events"]:
		lines.append("## %s" % String(section_name).replace("_", " ").capitalize())
		lines.append("")
		lines.append("```text")
		lines.append(String(surfaces.get(section_name, "")))
		lines.append("```")
		lines.append("")

	return "\n".join(lines)
