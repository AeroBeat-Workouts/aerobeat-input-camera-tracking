# Hook/uppercut pocket-exit benchmark (2026-06-18)

This artifact set benchmarks one narrow harness-only follow-up for the weak retimed `hook_uppercut_family_mask_v1` head.

- Control: `hook_uppercut_family_mask_v1`
- Targeted variant: `hook_uppercut_pocket_exit_variant_v1`
- New per-side cues: `wrist_from_elbow_vertical_range_over_shoulder_width`, `elbow_shoulder_distance_range_over_shoulder_width`, `wrist_from_elbow_vertical_peak_phase`
- Exact added frame variables: `left_wrist_from_elbow_vertical_range_over_shoulder_width`, `right_wrist_from_elbow_vertical_range_over_shoulder_width`, `left_elbow_shoulder_distance_range_over_shoulder_width`, `right_elbow_shoulder_distance_range_over_shoulder_width`, `left_wrist_from_elbow_vertical_peak_phase`, `right_wrist_from_elbow_vertical_peak_phase`
- Rule used: always rerun control MLP/CNN, rerun target MLP, and only run target CNN if the target MLP beats the retimed control MLP gate.

Result: the targeted pocket-exit MLP tied the control exactly at **0.3792** macro-F1, so the target CNN was intentionally not run. The diagnosed uppercut compact-boundary failures did not improve.

See `summary.md` and `summary.json` for the exact inventories, metrics, and artifact paths.
