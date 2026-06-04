class_name TrackingFrameAdapter
extends RefCounted
## Adapts vendor-neutral CameraTracking frames into the legacy landmark payload shape
## consumed by this repo's existing Boxing + Flow detector substrate.
##
## Important seam truth:
## - upstream CameraTracking frames already own horizontal mirroring, so this
##   adapter must not apply another x flip
## - preview/testbed overlay consumers need MediaPipe-style top-left normalized
##   y so visible skeletons, presenter overlays, and click targets agree
## - this repo's legacy detector math still consumes bottom-left gameplay-normalized
##   y, so gameplay-landmark conversion is kept explicit instead of being hidden
##   inside the shared preview-path payload
## - landmark payload details remain intentionally conservative until the upstream
##   contract locks richer skeleton/body-part schemas

const TRACKING_STATE_TRACKED := "tracked"
const TRACKING_STATE_REACQUIRING := "reacquiring"

static func landmarks_from_tracking_frame(frame: Dictionary) -> Array:
	return _normalize_landmark_array(frame, false)

static func gameplay_landmarks_from_tracking_frame(frame: Dictionary) -> Array:
	return _normalize_landmark_array(frame, true)

static func _normalize_landmark_array(frame: Dictionary, flip_y: bool) -> Array:
	var raw_landmarks: Variant = frame.get("landmarks", [])
	if not raw_landmarks is Array:
		return []

	var normalized: Array = []
	for landmark_variant: Variant in raw_landmarks:
		if not landmark_variant is Dictionary:
			continue
		var landmark: Dictionary = landmark_variant
		if not landmark.has("id"):
			continue
		normalized.append(_normalize_landmark(landmark, flip_y))
	return normalized

static func tracking_state_is_active(frame: Dictionary) -> bool:
	var tracking_state := String(frame.get("tracking_state", "")).strip_edges().to_lower()
	return tracking_state == TRACKING_STATE_TRACKED or tracking_state == TRACKING_STATE_REACQUIRING

static func get_timestamp_ms(frame: Dictionary) -> int:
	return maxi(int(frame.get("timestamp_ms", 0)), 0)

static func _normalize_landmark(landmark: Dictionary, flip_y: bool = false) -> Dictionary:
	var normalized := landmark.duplicate(true)
	normalized["id"] = int(landmark.get("id", -1))
	normalized["x"] = float(landmark.get("x", 0.0))
	var y := float(landmark.get("y", 0.0))
	normalized["y"] = 1.0 - y if flip_y else y
	normalized["z"] = float(landmark.get("z", 0.0))
	normalized["v"] = _resolve_visibility(landmark)
	return normalized

static func _resolve_visibility(landmark: Dictionary) -> float:
	if landmark.has("v"):
		return float(landmark.get("v", 0.0))
	if landmark.has("visibility"):
		return float(landmark.get("visibility", 0.0))
	return 1.0
