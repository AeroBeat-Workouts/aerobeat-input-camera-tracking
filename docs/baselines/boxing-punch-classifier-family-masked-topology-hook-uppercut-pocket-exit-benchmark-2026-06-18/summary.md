# Hook/uppercut pocket-exit benchmark (targeted miss-analysis rerun, 2026-06-18)

Shared-vector hook/uppercut subset baseline test accuracy/macro-F1: 0.8889 / 0.5872

## What was rerun

- Refreshed retimed control: `hook_uppercut_family_mask_v1`
- New targeted specialized candidate: `hook_uppercut_pocket_exit_variant_v1`
- Reference gate only: prior retimed Variant A/C MLP macro-F1 `0.4778`
- Source export reused: `family_combined_directional_hook_motion_shape_v1/export/dataset.json`

## Exact active inventories

### Control (`hook_uppercut_family_mask_v1`)
- Feature count: 44
- Active side features: ['shoulder_x', 'shoulder_y', 'elbow_x', 'elbow_y', 'wrist_x', 'wrist_y', 'combined_elbow_wrist_velocity_xy_magnitude', 'elbow_shoulder_xy_distance_over_shoulder_width', 'camera_wrist_signed_vx', 'camera_wrist_signed_vy', 'camera_wrist_direction_none', 'camera_wrist_direction_up', 'camera_wrist_direction_down', 'camera_wrist_direction_left', 'camera_wrist_direction_right', 'body_wrist_signed_vx', 'body_wrist_signed_vy', 'body_wrist_direction_none', 'body_wrist_direction_up', 'body_wrist_direction_down', 'body_wrist_direction_left', 'body_wrist_direction_right']

### Target (`hook_uppercut_pocket_exit_variant_v1`)
- Feature count: 68
- Active side features: ['shoulder_x', 'shoulder_y', 'elbow_x', 'elbow_y', 'wrist_x', 'wrist_y', 'combined_elbow_wrist_velocity_xy_magnitude', 'elbow_shoulder_xy_distance_over_shoulder_width', 'camera_wrist_signed_vx', 'camera_wrist_signed_vy', 'camera_wrist_direction_none', 'camera_wrist_direction_up', 'camera_wrist_direction_down', 'camera_wrist_direction_left', 'camera_wrist_direction_right', 'body_wrist_signed_vx', 'body_wrist_signed_vy', 'body_wrist_direction_none', 'body_wrist_direction_up', 'body_wrist_direction_down', 'body_wrist_direction_left', 'body_wrist_direction_right', 'wrist_x_from_elbow_over_shoulder_width', 'wrist_y_from_elbow_over_shoulder_width', 'forearm_unit_x', 'forearm_unit_y', 'wrist_elbow_radial_velocity_over_shoulder_width', 'wrist_elbow_tangential_velocity_over_shoulder_width', 'forearm_angular_velocity_rad_per_s', 'body_wrist_minus_elbow_velocity_lateral_over_shoulder_width', 'body_wrist_minus_elbow_velocity_vertical_over_shoulder_width', 'wrist_from_elbow_vertical_range_over_shoulder_width', 'elbow_shoulder_distance_range_over_shoulder_width', 'wrist_from_elbow_vertical_peak_phase']
- Added per-side variables vs Variant C: ['wrist_from_elbow_vertical_range_over_shoulder_width', 'elbow_shoulder_distance_range_over_shoulder_width', 'wrist_from_elbow_vertical_peak_phase']
- Exact added frame variables: `left_wrist_from_elbow_vertical_range_over_shoulder_width`, `right_wrist_from_elbow_vertical_range_over_shoulder_width`, `left_elbow_shoulder_distance_range_over_shoulder_width`, `right_elbow_shoulder_distance_range_over_shoulder_width`, `left_wrist_from_elbow_vertical_peak_phase`, `right_wrist_from_elbow_vertical_peak_phase`
- Derived cue semantics: per-window pocket-exit scalars repeated across frames for left/right vertical wrist-from-elbow range, elbow-shoulder distance range, and vertical peak phase.

## Gated comparison

- Control MLP gate macro-F1: 0.3792
- Variant A/C reference MLP macro-F1: 0.4778
- Target MLP macro-F1: 0.3792
- Target MLP beats control gate: no
- Target MLP ties control gate: yes
- Target MLP beats/ties Variant A/C reference: no
- Target CNN run: no

## Control (`hook_uppercut_family_mask_v1`)

- Retimed MLP test accuracy/macro-F1: 0.7037 / 0.3792
- Retimed CNN test accuracy/macro-F1: 0.8519 / 0.5159
- Fair retimed shared-vector subset baseline accuracy/macro-F1: 0.8889 / 0.5872

## Target (`hook_uppercut_pocket_exit_variant_v1`)

- Retimed MLP test accuracy/macro-F1: 0.7037 / 0.3792
- MLP delta vs retimed control accuracy/macro-F1: +0.0000 / +0.0000
- MLP delta vs fair retimed subset baseline accuracy/macro-F1: -0.1852 / -0.2080
- MLP delta vs Variant A/C reference accuracy/macro-F1: -0.1111 / -0.0986

## Diagnosed uppercut-boundary check

- `uppercut_left_fixture::uppercut_left::04`: control `uppercut_left -> no_punch`; target `uppercut_left -> no_punch`
- `uppercut_right_fixture::uppercut_right::04`: control `uppercut_right -> hook_left`; target `uppercut_right -> hook_left`
- Test prediction changes vs control: 0
- Net: the targeted pocket-exit cue family did **not** improve the diagnosed uppercut/no_punch compact-boundary failure.

## Artifact paths

- Control export / MLP / CNN: `docs/baselines/boxing-punch-classifier-family-masked-topology-hook-uppercut-pocket-exit-benchmark-2026-06-18/hook_uppercut_family_mask_v1/`
- Target export / MLP: `docs/baselines/boxing-punch-classifier-family-masked-topology-hook-uppercut-pocket-exit-benchmark-2026-06-18/hook_uppercut_pocket_exit_variant_v1/`
- Benchmark summary: `docs/baselines/boxing-punch-classifier-family-masked-topology-hook-uppercut-pocket-exit-benchmark-2026-06-18/summary.json`, `docs/baselines/boxing-punch-classifier-family-masked-topology-hook-uppercut-pocket-exit-benchmark-2026-06-18/summary.md`

## Conclusion

- The targeted pocket-exit variant did not improve the narrow retimed hook/uppercut subset.
- It tied the control MLP exactly at **0.3792** macro-F1, so the CNN gate did not open.
- It stayed below both the fair shared-vector subset baseline (**0.5872**) and the prior Variant A/C retimed reference (**0.4778**).
- Straight-family specialization still looks stronger; hook/uppercut specialization remains unproven.
