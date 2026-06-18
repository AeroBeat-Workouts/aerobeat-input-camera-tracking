# Hook/uppercut motion-shape benchmark (Variant C gated rerun, 2026-06-18)

Shared-vector hook/uppercut subset baseline test accuracy/macro-F1: 0.8889 / 0.5872

## What was rerun

- Refreshed retimed source export: `family_combined_directional_hook_motion_shape_v1`
- Refreshed retimed control: `hook_uppercut_family_mask_v1`
- New retimed cue-design candidate: `hook_uppercut_motion_shape_variant_c_v1`
- Reference only: prior retimed `hook_uppercut_motion_shape_variant_a_v1`
- Intentionally not rerun: `hook_uppercut_motion_shape_variant_b_v1`

## Source refresh note

- Attempted snapshot-anchored refresh from `.testbed/assets/benchmarks/boxing_punch_classifier_hardened_2026_06_16.snapshot.json`
- Snapshot verification now fails by design because the retimed fixture YAML hashes changed after the frozen snapshot was sealed
- Final refresh path: current retimed benchmark manifest + frozen hardened capture reports under `.temp/boxing-punch-classifier-export/hardened-captures-2026-06-16`

## Full source export inventory

- Feature set: `family_combined_directional_hook_motion_shape_v1`
- Sample count: 96
- Split counts: train `67`, test `29`
- Frame feature count: 72
- Per-side feature inventory: ['shoulder_x', 'shoulder_y', 'elbow_x', 'elbow_y', 'wrist_x', 'wrist_y', 'combined_elbow_wrist_velocity_xy_magnitude', 'elbow_shoulder_xy_distance_over_shoulder_width', 'elbow_x_from_shoulder_over_shoulder_width', 'elbow_y_from_shoulder_over_shoulder_width', 'elbow_shoulder_radial_velocity_over_shoulder_width', 'camera_wrist_signed_vx', 'camera_wrist_signed_vy', 'camera_wrist_direction_none', 'camera_wrist_direction_up', 'camera_wrist_direction_down', 'camera_wrist_direction_left', 'camera_wrist_direction_right', 'body_wrist_signed_vx', 'body_wrist_signed_vy', 'body_wrist_direction_none', 'body_wrist_direction_up', 'body_wrist_direction_down', 'body_wrist_direction_left', 'body_wrist_direction_right', 'wrist_x_from_elbow_over_shoulder_width', 'wrist_y_from_elbow_over_shoulder_width', 'forearm_unit_x', 'forearm_unit_y', 'wrist_elbow_radial_velocity_over_shoulder_width', 'wrist_elbow_tangential_velocity_over_shoulder_width', 'wrist_minus_elbow_velocity_x_over_shoulder_width', 'wrist_minus_elbow_velocity_y_over_shoulder_width', 'body_wrist_minus_elbow_velocity_lateral_over_shoulder_width', 'body_wrist_minus_elbow_velocity_vertical_over_shoulder_width', 'forearm_angular_velocity_rad_per_s']

## Exact active inventories

### Control (`hook_uppercut_family_mask_v1`)

- Feature count: 44
- Active side features: ['shoulder_x', 'shoulder_y', 'elbow_x', 'elbow_y', 'wrist_x', 'wrist_y', 'combined_elbow_wrist_velocity_xy_magnitude', 'elbow_shoulder_xy_distance_over_shoulder_width', 'camera_wrist_signed_vx', 'camera_wrist_signed_vy', 'camera_wrist_direction_none', 'camera_wrist_direction_up', 'camera_wrist_direction_down', 'camera_wrist_direction_left', 'camera_wrist_direction_right', 'body_wrist_signed_vx', 'body_wrist_signed_vy', 'body_wrist_direction_none', 'body_wrist_direction_up', 'body_wrist_direction_down', 'body_wrist_direction_left', 'body_wrist_direction_right']

### Variant C (`hook_uppercut_motion_shape_variant_c_v1`)

- Feature count: 62
- Active side features: ['shoulder_x', 'shoulder_y', 'elbow_x', 'elbow_y', 'wrist_x', 'wrist_y', 'combined_elbow_wrist_velocity_xy_magnitude', 'elbow_shoulder_xy_distance_over_shoulder_width', 'camera_wrist_signed_vx', 'camera_wrist_signed_vy', 'camera_wrist_direction_none', 'camera_wrist_direction_up', 'camera_wrist_direction_down', 'camera_wrist_direction_left', 'camera_wrist_direction_right', 'body_wrist_signed_vx', 'body_wrist_signed_vy', 'body_wrist_direction_none', 'body_wrist_direction_up', 'body_wrist_direction_down', 'body_wrist_direction_left', 'body_wrist_direction_right', 'wrist_x_from_elbow_over_shoulder_width', 'wrist_y_from_elbow_over_shoulder_width', 'forearm_unit_x', 'forearm_unit_y', 'wrist_elbow_radial_velocity_over_shoulder_width', 'wrist_elbow_tangential_velocity_over_shoulder_width', 'forearm_angular_velocity_rad_per_s', 'body_wrist_minus_elbow_velocity_lateral_over_shoulder_width', 'body_wrist_minus_elbow_velocity_vertical_over_shoulder_width']
- Added per-side variables vs Variant A: `forearm_angular_velocity_rad_per_s`, `body_wrist_minus_elbow_velocity_lateral_over_shoulder_width`, `body_wrist_minus_elbow_velocity_vertical_over_shoulder_width`

## Gated comparison

- Control MLP gate macro-F1: 0.3792
- Variant A reference MLP macro-F1: 0.4778
- Variant C MLP macro-F1: 0.4778
- Variant C beats control MLP gate: yes
- Variant C beats Variant A reference: no (tie at 0.4778)
- Variant C CNN run: yes

## Control (`hook_uppercut_family_mask_v1`)

- Class order: ['hook_left', 'hook_right', 'uppercut_left', 'uppercut_right', 'no_punch']
- Retimed MLP test accuracy/macro-F1: 0.7037 / 0.3792
- Retimed CNN test accuracy/macro-F1: 0.8519 / 0.5159
- Fair retimed shared-vector subset baseline accuracy/macro-F1: 0.8889 / 0.5872
- MLP delta vs fair retimed subset baseline accuracy/macro-F1: -0.1852 / -0.2080
- CNN delta vs fair retimed subset baseline accuracy/macro-F1: -0.0370 / -0.0713

## Variant A reference (`hook_uppercut_motion_shape_variant_a_v1`)

- Not rerun in this slice; values carried forward from the prior retimed motion-shape benchmark
- Feature count: 56
- Reference MLP test accuracy/macro-F1: 0.8148 / 0.4778
- Reference CNN test accuracy/macro-F1: 0.8148 / 0.3121

## Variant C (`hook_uppercut_motion_shape_variant_c_v1`)

- Class order: ['hook_left', 'hook_right', 'uppercut_left', 'uppercut_right', 'no_punch']
- Retimed MLP test accuracy/macro-F1: 0.8148 / 0.4778
- Retimed CNN test accuracy/macro-F1: 0.8519 / 0.5159
- Fair retimed shared-vector subset baseline accuracy/macro-F1: 0.8889 / 0.5872
- MLP delta vs retimed control accuracy/macro-F1: +0.1111 / +0.0986
- CNN delta vs retimed control accuracy/macro-F1: +0.0000 / +0.0000
- MLP delta vs fair retimed subset baseline accuracy/macro-F1: -0.0741 / -0.1095
- CNN delta vs fair retimed subset baseline accuracy/macro-F1: -0.0370 / -0.0713
- MLP delta vs Variant A reference accuracy/macro-F1: +0.0000 / +0.0000
- CNN delta vs Variant A reference accuracy/macro-F1: +0.0370 / +0.2039

## Conclusion

- Variant C does clear the narrow gating rule by beating the retimed control MLP (0.4778 vs 0.3792).
- Variant C does **not** beat the retimed Variant A MLP reference; it ties it exactly at 0.4778.
- Variant C CNN lands at 0.8519 / 0.5159, which exactly matches the retimed control CNN and still trails the fair shared-vector hook/uppercut subset baseline at 0.8889 / 0.5872.
- Net: this weakens the case that extra hook/uppercut-specific cue shaping is ready to justify runtime family specialization. Straight-family masking still looks like the stronger specialization story; hook/uppercut remains the weak branch.

## Artifact paths

- Source export: `docs/baselines/boxing-punch-classifier-family-masked-topology-hook-uppercut-motion-shape-benchmark-2026-06-18/family_combined_directional_hook_motion_shape_v1/export/`
- Control export / MLP / CNN: `docs/baselines/boxing-punch-classifier-family-masked-topology-hook-uppercut-motion-shape-benchmark-2026-06-18/hook_uppercut_family_mask_v1/`
- Variant C export / MLP / CNN: `docs/baselines/boxing-punch-classifier-family-masked-topology-hook-uppercut-motion-shape-benchmark-2026-06-18/hook_uppercut_motion_shape_variant_c_v1/`
- Variant A reference export / MLP / CNN: `docs/baselines/boxing-punch-classifier-family-masked-topology-hook-uppercut-motion-shape-benchmark-2026-06-18/hook_uppercut_motion_shape_variant_a_v1/`
- Benchmark summary: `docs/baselines/boxing-punch-classifier-family-masked-topology-hook-uppercut-motion-shape-benchmark-2026-06-18/summary.json`, `docs/baselines/boxing-punch-classifier-family-masked-topology-hook-uppercut-motion-shape-benchmark-2026-06-18/summary.md`
