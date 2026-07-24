extends RefCounted

const PROFILE_BOXING := "boxing"
const PROFILE_FLOW := "flow"
const CAMERA_TRACKING_SCHEMA := "aerobeat/camera_tracking_config"
const GESTURE_DETECTION_SCHEMA := "aerobeat/gesture_detection_config"
const TESTBED_DEBUG_SCHEMA := "aerobeat/testbed_debug_config"
const CONFIG_VERSION := 1
const SCRIPT_PATH_SUFFIX := "/src/config/profile_config_loader.gd"

const PROFILE_FILE_MAP := {
	PROFILE_BOXING: {
		"camera_tracking": "assets/boxing.camera_tracking.yaml",
		"gesture_detection": "assets/boxing.gesture_detection.yaml",
		"testbed_debug": "assets/boxing.testbed_debug.yaml",
	},
	PROFILE_FLOW: {
		"camera_tracking": "assets/flow.camera_tracking.yaml",
		"gesture_detection": "assets/flow.gesture_detection.yaml",
		"testbed_debug": "assets/flow.testbed_debug.yaml",
	},
}

func resolve_profile_bundle_paths(profile_name: String) -> Dictionary:
	var normalized_profile := _normalize_profile_name(profile_name)
	var paths: Dictionary = PROFILE_FILE_MAP.get(normalized_profile, PROFILE_FILE_MAP[PROFILE_BOXING])
	return {
		"ok": true,
		"profile": normalized_profile,
		"camera_tracking_path": _get_addon_root_path().path_join(String(paths.get("camera_tracking", ""))),
		"gesture_detection_path": _get_addon_root_path().path_join(String(paths.get("gesture_detection", ""))),
		"testbed_debug_path": _get_addon_root_path().path_join(String(paths.get("testbed_debug", ""))),
	}

func load_profile_bundle(profile_name: String) -> Dictionary:
	var paths := resolve_profile_bundle_paths(profile_name)
	var normalized_profile := String(paths.get("profile", PROFILE_BOXING))
	var camera_tracking := load_profile_document(
		String(paths.get("camera_tracking_path", "")),
		CAMERA_TRACKING_SCHEMA,
		CONFIG_VERSION,
		normalized_profile
	)
	if not bool(camera_tracking.get("ok", false)):
		return camera_tracking
	var gesture_detection := load_profile_document(
		String(paths.get("gesture_detection_path", "")),
		GESTURE_DETECTION_SCHEMA,
		CONFIG_VERSION,
		normalized_profile
	)
	if not bool(gesture_detection.get("ok", false)):
		return gesture_detection
	var testbed_debug := load_profile_document(
		String(paths.get("testbed_debug_path", "")),
		TESTBED_DEBUG_SCHEMA,
		CONFIG_VERSION,
		normalized_profile
	)
	if not bool(testbed_debug.get("ok", false)):
		return testbed_debug
	return {
		"ok": true,
		"profile": normalized_profile,
		"camera_tracking_path": String(paths.get("camera_tracking_path", "")),
		"gesture_detection_path": String(paths.get("gesture_detection_path", "")),
		"testbed_debug_path": String(paths.get("testbed_debug_path", "")),
		"camera_tracking": (camera_tracking.get("document", {}) as Dictionary).duplicate(true),
		"gesture_detection": (gesture_detection.get("document", {}) as Dictionary).duplicate(true),
		"testbed_debug": (testbed_debug.get("document", {}) as Dictionary).duplicate(true),
	}

func load_profile_document(path: String, expected_schema: String, expected_version: int, expected_profile: String) -> Dictionary:
	var normalized_path := path.strip_edges()
	if normalized_path.is_empty():
		return _error("config_path_missing", "Profile config path is required.", normalized_path)
	if not FileAccess.file_exists(normalized_path):
		return _error("config_missing", "Profile config file does not exist: %s" % normalized_path, normalized_path)
	var file := FileAccess.open(normalized_path, FileAccess.READ)
	if file == null:
		return _error("config_open_failed", "Profile config file could not be opened: %s" % normalized_path, normalized_path)
	var parse_result := _parse_yaml_text(file.get_as_text())
	if not bool(parse_result.get("ok", false)):
		return _error(String(parse_result.get("error_code", "config_parse_failed")), String(parse_result.get("error", "Profile config parse failed.")), normalized_path)
	var document: Variant = parse_result.get("data", {})
	if not (document is Dictionary):
		return _error("config_invalid_root", "Profile config root must be a dictionary: %s" % normalized_path, normalized_path)
	return validate_profile_document(document, expected_schema, expected_version, expected_profile, normalized_path)

func validate_profile_document(document: Dictionary, expected_schema: String, expected_version: int, expected_profile: String, source_path: String = "") -> Dictionary:
	var schema := String(document.get("schema", "")).strip_edges()
	if schema != expected_schema:
		return _error(
			"config_schema_mismatch",
			"Profile config schema mismatch for %s: expected %s, got %s" % [source_path, expected_schema, schema],
			source_path
		)
	var version := int(document.get("version", -1))
	if version != expected_version:
		return _error(
			"config_version_mismatch",
			"Profile config version mismatch for %s: expected %d, got %d" % [source_path, expected_version, version],
			source_path
		)
	var profile := _normalize_profile_name(String(document.get("profile", "")))
	if profile != _normalize_profile_name(expected_profile):
		return _error(
			"config_profile_mismatch",
			"Profile config profile mismatch for %s: expected %s, got %s" % [source_path, _normalize_profile_name(expected_profile), profile],
			source_path
		)
	var sanitized_document := document.duplicate(true)
	if expected_schema == GESTURE_DETECTION_SCHEMA:
		sanitized_document = _sanitize_gesture_detection_document(sanitized_document)
	return {
		"ok": true,
		"path": source_path,
		"document": sanitized_document,
	}

func _sanitize_gesture_detection_document(document: Dictionary) -> Dictionary:
	var sanitized := document.duplicate(true)
	for family_name in ["guard", "squat", "weave", "straight_punch", "hook", "uppercut"]:
		var family: Dictionary = sanitized.get(family_name, {}) if sanitized.get(family_name, {}) is Dictionary else {}
		if family.is_empty():
			continue
			
		family.erase("prototype")
		family.erase("classifier")
		var backend := String(family.get("backend", "threshold")).strip_edges().to_lower().replace("-", "_")
		if backend == "disabled":
			family["backend"] = "disabled"
		elif family_name == "squat" or family_name == "weave":
			family["backend"] = "grid_avoidance" if backend == "grid_avoidance" else "threshold"
		elif family_name == "hook" or family_name == "uppercut":
			family["backend"] = "grid_detection" if backend == "grid_detection" else "threshold"
		else:
			family["backend"] = "threshold"
		sanitized[family_name] = family
	for stale_family in ["knee_strike", "leg_lift", "side_step"]:
		sanitized.erase(stale_family)
	return sanitized

func _normalize_profile_name(profile_name: String) -> String:
	var normalized := profile_name.strip_edges().to_lower()
	if normalized == PROFILE_FLOW:
		return PROFILE_FLOW
	return PROFILE_BOXING

func _get_addon_root_path() -> String:
	var script_resource: Variant = get_script()
	if script_resource == null:
		return "res://addons/aerobeat-input-camera-tracking"
	var resource_path := String(script_resource.resource_path)
	if resource_path.ends_with(SCRIPT_PATH_SUFFIX):
		return resource_path.trim_suffix(SCRIPT_PATH_SUFFIX)
	return resource_path.get_base_dir().get_base_dir().get_base_dir()

func _parse_yaml_text(text: String) -> Dictionary:
	var lines: Array = []
	var line_number := 0
	for raw_line in text.split("\n"):
		line_number += 1
		var normalized_line: String = String(raw_line).rstrip("\r")
		var stripped_line: String = normalized_line.strip_edges()
		if stripped_line.is_empty() or stripped_line.begins_with("#"):
			continue
		var trimmed_left: String = normalized_line.lstrip(" \t")
		var indent_prefix := normalized_line.substr(0, normalized_line.length() - trimmed_left.length())
		if indent_prefix.contains("\t"):
			return {
				"ok": false,
				"data": {},
				"error": "Tabs are not allowed in YAML indentation (line %d)." % line_number,
				"error_code": "config_tab_indentation",
			}
		var indent: int = indent_prefix.length()
		lines.append({"indent": indent, "text": trimmed_left.rstrip(" \t")})
	if lines.is_empty():
		return {"ok": true, "data": {}, "error": "", "error_code": ""}
	var state := {"lines": lines, "index": 0}
	var data: Variant = _parse_yaml_node(state, int(lines[0].get("indent", 0)))
	return {"ok": true, "data": data, "error": "", "error_code": ""}

func _parse_yaml_node(state: Dictionary, indent: int) -> Variant:
	if int(state.get("index", 0)) >= state.get("lines", []).size():
		return {}
	var line: Dictionary = state.get("lines", [])[int(state.get("index", 0))]
	var text: String = String(line.get("text", ""))
	if text.begins_with("- "):
		return _parse_yaml_sequence(state, indent)
	return _parse_yaml_mapping(state, indent)

func _parse_yaml_mapping(state: Dictionary, indent: int) -> Dictionary:
	var result: Dictionary = {}
	while int(state.get("index", 0)) < state.get("lines", []).size():
		var line: Dictionary = state.get("lines", [])[int(state.get("index", 0))]
		var line_indent: int = int(line.get("indent", 0))
		var text: String = String(line.get("text", ""))
		if line_indent < indent:
			break
		if line_indent > indent:
			state["index"] = int(state.get("index", 0)) + 1
			continue
		if text.begins_with("- "):
			break
		var parts: Array = _split_mapping_entry(text)
		var key: String = String(parts[0])
		var remainder: String = String(parts[1])
		state["index"] = int(state.get("index", 0)) + 1
		if remainder.is_empty():
			if int(state.get("index", 0)) < state.get("lines", []).size() and int(state.get("lines", [])[int(state.get("index", 0))].get("indent", 0)) > indent:
				result[key] = _parse_yaml_node(state, int(state.get("lines", [])[int(state.get("index", 0))].get("indent", 0)))
			else:
				result[key] = null
		elif remainder == ">" or remainder == ">-" or remainder == "|" or remainder == "|-":
			result[key] = _parse_yaml_block_scalar(state, indent, remainder)
		else:
			result[key] = _parse_yaml_scalar(remainder)
	return result

func _parse_yaml_sequence(state: Dictionary, indent: int) -> Array:
	var result: Array = []
	while int(state.get("index", 0)) < state.get("lines", []).size():
		var line: Dictionary = state.get("lines", [])[int(state.get("index", 0))]
		var line_indent: int = int(line.get("indent", 0))
		var text: String = String(line.get("text", ""))
		if line_indent < indent or line_indent != indent or not text.begins_with("- "):
			break
		var item_text: String = text.substr(2)
		state["index"] = int(state.get("index", 0)) + 1
		if item_text.is_empty():
			if int(state.get("index", 0)) < state.get("lines", []).size() and int(state.get("lines", [])[int(state.get("index", 0))].get("indent", 0)) > indent:
				result.append(_parse_yaml_node(state, int(state.get("lines", [])[int(state.get("index", 0))].get("indent", 0))))
			else:
				result.append(null)
			continue
		if _looks_like_mapping_entry(item_text):
			var parts: Array = _split_mapping_entry(item_text)
			var entry: Dictionary = {}
			var key: String = String(parts[0])
			var remainder: String = String(parts[1])
			if remainder.is_empty():
				if int(state.get("index", 0)) < state.get("lines", []).size() and int(state.get("lines", [])[int(state.get("index", 0))].get("indent", 0)) > indent:
					entry[key] = _parse_yaml_node(state, int(state.get("lines", [])[int(state.get("index", 0))].get("indent", 0)))
				else:
					entry[key] = null
			elif remainder == ">" or remainder == ">-" or remainder == "|" or remainder == "|-":
				entry[key] = _parse_yaml_block_scalar(state, indent, remainder)
			else:
				entry[key] = _parse_yaml_scalar(remainder)
			if int(state.get("index", 0)) < state.get("lines", []).size() and int(state.get("lines", [])[int(state.get("index", 0))].get("indent", 0)) > indent:
				var continuation: Variant = _parse_yaml_node(state, int(state.get("lines", [])[int(state.get("index", 0))].get("indent", 0)))
				if continuation is Dictionary:
					for continuation_key in continuation.keys():
						entry[continuation_key] = continuation.get(continuation_key)
			result.append(entry)
		else:
			result.append(_parse_yaml_scalar(item_text))
	return result

func _parse_yaml_block_scalar(state: Dictionary, indent: int, style: String) -> String:
	var parts: Array[String] = []
	while int(state.get("index", 0)) < state.get("lines", []).size():
		var line: Dictionary = state.get("lines", [])[int(state.get("index", 0))]
		var line_indent: int = int(line.get("indent", 0))
		if line_indent <= indent:
			break
		parts.append(String(line.get("text", "")).strip_edges())
		state["index"] = int(state.get("index", 0)) + 1
	if style.begins_with(">"):
		return " ".join(parts)
	return "\n".join(parts)

func _parse_yaml_scalar(value: String) -> Variant:
	var trimmed: String = value.strip_edges()
	if trimmed.is_empty():
		return ""
	if trimmed == "true":
		return true
	if trimmed == "false":
		return false
	if trimmed == "null" or trimmed == "~":
		return null
	if (trimmed.begins_with("\"") and trimmed.ends_with("\"")) or (trimmed.begins_with("'") and trimmed.ends_with("'")):
		return trimmed.substr(1, trimmed.length() - 2)
	if trimmed.begins_with("[") and trimmed.ends_with("]"):
		return _parse_flow_array(trimmed)
	if _is_integer_literal(trimmed):
		return int(trimmed)
	if _is_float_literal(trimmed):
		return float(trimmed)
	return trimmed

func _parse_flow_array(value: String) -> Array:
	var inner: String = value.substr(1, value.length() - 2).strip_edges()
	if inner.is_empty():
		return []
	var parts: Array = inner.split(",", false)
	var result: Array = []
	for part in parts:
		result.append(_parse_yaml_scalar(String(part).strip_edges()))
	return result

func _split_mapping_entry(text: String) -> Array:
	var delimiter_index: int = text.find(":")
	if delimiter_index == -1:
		return [text.strip_edges(), ""]
	var key: String = text.substr(0, delimiter_index).strip_edges()
	var remainder: String = text.substr(delimiter_index + 1).strip_edges()
	return [key, remainder]

func _looks_like_mapping_entry(text: String) -> bool:
	return text.find(":") > 0

func _is_integer_literal(text: String) -> bool:
	if text.is_empty():
		return false
	var body := text
	if body.begins_with("-") or body.begins_with("+"):
		body = body.substr(1)
	return not body.is_empty() and body.is_valid_int()

func _is_float_literal(text: String) -> bool:
	if text.is_empty():
		return false
	var body := text
	if body.begins_with("-") or body.begins_with("+"):
		body = body.substr(1)
	if body.is_empty() or body.find(".") == -1:
		return false
	return body.is_valid_float()

func _error(code: String, message: String, path: String = "") -> Dictionary:
	return {
		"ok": false,
		"error_code": code,
		"error": message,
		"path": path,
	}
