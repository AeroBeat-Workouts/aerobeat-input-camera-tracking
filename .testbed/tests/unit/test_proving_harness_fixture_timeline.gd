extends "res://addons/aerobeat-vendor-godot-unit-test/test.gd"

const ProvingHarness = preload("res://scripts/proving_harness.gd")

class TestProvingHarness:
	extends ProvingHarness

	func _ready() -> void:
		pass

var harness: TestProvingHarness = null

func before_each() -> void:
	harness = TestProvingHarness.new()

func after_each() -> void:
	if harness != null:
		harness.free()
		harness = null

func test_fixture_state_timeline_bounds_pose_snapshots_but_keeps_event_snapshots() -> void:
	harness.fixture_state_timeline_mode = harness.FIXTURE_STATE_TIMELINE_MODE_BOUNDED
	harness.fixture_pose_state_timeline_limit = 3
	harness._reset_event_tracking()

	harness._record_fixture_state_snapshot("ready")
	for _index: int in range(5):
		harness._record_fixture_state_snapshot("pose_updated")
	harness._record_fixture_state_snapshot("tracking_lost")

	var timeline: Array = harness._fixture_state_timeline
	assert_eq(timeline.size(), 5)
	assert_eq(int(harness._fixture_pose_state_snapshots_seen), 5)
	assert_eq(int(harness._fixture_pose_state_snapshots_retained), 3)
	assert_eq(int(harness._fixture_pose_state_snapshots_dropped), 2)
	assert_eq(String((timeline[0] as Dictionary).get("reason", "")), "ready")
	assert_eq(String((timeline[timeline.size() - 1] as Dictionary).get("reason", "")), "tracking_lost")
	var pose_reasons: int = 0
	for entry_variant: Variant in timeline:
		if not entry_variant is Dictionary:
			continue
		if String((entry_variant as Dictionary).get("reason", "")) == "pose_updated":
			pose_reasons += 1
	assert_eq(pose_reasons, 3)
	var report: Dictionary = harness.get_fixture_capture_report()
	var capture_state: Dictionary = report.get("state_timeline_capture", {})
	assert_eq(String(capture_state.get("mode", "")), harness.FIXTURE_STATE_TIMELINE_MODE_BOUNDED)
	assert_eq(int(capture_state.get("pose_snapshots_retained", -1)), 3)
	assert_eq(int(capture_state.get("pose_snapshots_dropped", -1)), 2)

func test_fixture_state_timeline_full_mode_keeps_all_pose_snapshots_explicitly() -> void:
	harness.fixture_state_timeline_mode = harness.FIXTURE_STATE_TIMELINE_MODE_FULL
	harness.fixture_pose_state_timeline_limit = -1
	harness._reset_event_tracking()

	for _index: int in range(5):
		harness._record_fixture_state_snapshot("pose_updated")

	assert_eq(harness._fixture_state_timeline.size(), 5)
	assert_eq(int(harness._fixture_pose_state_snapshots_seen), 5)
	assert_eq(int(harness._fixture_pose_state_snapshots_retained), 5)
	assert_eq(int(harness._fixture_pose_state_snapshots_dropped), 0)
	var report: Dictionary = harness.get_fixture_capture_report()
	var capture_state: Dictionary = report.get("state_timeline_capture", {})
	assert_eq(String(capture_state.get("mode", "")), harness.FIXTURE_STATE_TIMELINE_MODE_FULL)

func test_fixture_state_timeline_captures_prototype_matcher_debug_truth() -> void:
	harness.fixture_state_timeline_mode = harness.FIXTURE_STATE_TIMELINE_MODE_FULL
	harness._latest_state = {
		"gesture_debug": {
			"punch_detection": {"backend": "prototype_matcher"},
			"prototype_matcher": {
				"best_class": "straight_left",
				"best_score": 0.84,
				"reason": "emitted",
				"emitted_event_name": "punch_left"
			}
		}
	}

	harness._record_fixture_state_snapshot("pose_updated")
	var timeline: Array = harness._fixture_state_timeline
	assert_eq(timeline.size(), 1)
	var entry: Dictionary = timeline[0]
	assert_eq(String(entry.get("punch_detection", {}).get("backend", "")), "prototype_matcher")
	assert_eq(String(entry.get("prototype_matcher", {}).get("best_class", "")), "straight_left")
	assert_true(is_equal_approx(float(entry.get("prototype_matcher", {}).get("best_score", 0.0)), 0.84))
