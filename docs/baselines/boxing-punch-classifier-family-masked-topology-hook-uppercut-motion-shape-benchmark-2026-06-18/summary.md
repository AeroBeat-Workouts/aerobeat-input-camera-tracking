# Hook/uppercut motion-shape benchmark (retimed rerun subset, 2026-06-18)

Shared-vector hook/uppercut subset baseline test accuracy/macro-F1: 0.8889 / 0.5872

## What was rerun

- Refreshed retimed source export: `family_combined_directional_hook_motion_shape_v1`
- Refreshed retimed control: `hook_uppercut_family_mask_v1`
- Refreshed retimed motion-shape candidate: `hook_uppercut_motion_shape_variant_a_v1`
- Intentionally **not** rerun: `hook_uppercut_motion_shape_variant_b_v1` (lower-value redundant follow-up per Task 19)

## Sample / window count deltas vs pre-retime run

- Source export sample count: `96 -> 96` (delta `0`)
- Source export split counts: `train 67 -> 67`, `test 29 -> 29`
- Control sample count: `88 -> 88` (delta `0`)
- Control split counts: `train 61 -> 61`, `test 27 -> 27`
- Variant A sample count: `88 -> 88` (delta `0`)
- Variant A split counts: `train 61 -> 61`, `test 27 -> 27`
- Material change: window timing / held-out window identity under the retimed punch YAML truth, not bucket totals

## Full source export inventory

- Feature set: `family_combined_directional_hook_motion_shape_v1`
- Sample count: 96
- Frame feature count: 70
- Per-side feature inventory: ['shoulder_x', 'shoulder_y', 'elbow_x', 'elbow_y', 'wrist_x', 'wrist_y', 'combined_elbow_wrist_velocity_xy_magnitude', 'elbow_shoulder_xy_distance_over_shoulder_width', 'elbow_x_from_shoulder_over_shoulder_width', 'elbow_y_from_shoulder_over_shoulder_width', 'elbow_shoulder_radial_velocity_over_shoulder_width', 'camera_wrist_signed_vx', 'camera_wrist_signed_vy', 'camera_wrist_direction_none', 'camera_wrist_direction_up', 'camera_wrist_direction_down', 'camera_wrist_direction_left', 'camera_wrist_direction_right', 'body_wrist_signed_vx', 'body_wrist_signed_vy', 'body_wrist_direction_none', 'body_wrist_direction_up', 'body_wrist_direction_down', 'body_wrist_direction_left', 'body_wrist_direction_right', 'wrist_x_from_elbow_over_shoulder_width', 'wrist_y_from_elbow_over_shoulder_width', 'forearm_unit_x', 'forearm_unit_y', 'wrist_elbow_radial_velocity_over_shoulder_width', 'wrist_elbow_tangential_velocity_over_shoulder_width', 'wrist_minus_elbow_velocity_x_over_shoulder_width', 'wrist_minus_elbow_velocity_y_over_shoulder_width', 'body_wrist_minus_elbow_velocity_lateral_over_shoulder_width', 'body_wrist_minus_elbow_velocity_vertical_over_shoulder_width']

## CNN gate

- Rule: run control CNN, and run Variant A CNN only if Variant A MLP macro-F1 beats the retimed control MLP macro-F1
- Retimed control MLP macro-F1: 0.3792
- Retimed best new variant by MLP macro-F1: `hook_uppercut_motion_shape_variant_a_v1` at 0.4778
- Gate triggered: yes

## Control (hook_uppercut_family_mask_v1)

- Class order: ['hook_left', 'hook_right', 'uppercut_left', 'uppercut_right', 'no_punch']
- Feature count: 44
- Retimed MLP test accuracy/macro-F1: 0.7037 / 0.3792
- Retimed CNN test accuracy/macro-F1: 0.8519 / 0.5159
- Fair retimed shared-vector subset baseline accuracy/macro-F1: 0.8889 / 0.5872
- MLP delta vs fair retimed subset baseline accuracy/macro-F1: -0.1852 / -0.2080
- CNN delta vs fair retimed subset baseline accuracy/macro-F1: -0.0370 / -0.0713
- Retimed delta vs pre-retime MLP accuracy/macro-F1: -0.1111 / +0.0632
- Retimed delta vs pre-retime CNN accuracy/macro-F1: +0.0370 / +0.3364
- Active side features: ['shoulder_x', 'shoulder_y', 'elbow_x', 'elbow_y', 'wrist_x', 'wrist_y', 'combined_elbow_wrist_velocity_xy_magnitude', 'elbow_shoulder_xy_distance_over_shoulder_width', 'camera_wrist_signed_vx', 'camera_wrist_signed_vy', 'camera_wrist_direction_none', 'camera_wrist_direction_up', 'camera_wrist_direction_down', 'camera_wrist_direction_left', 'camera_wrist_direction_right', 'body_wrist_signed_vx', 'body_wrist_signed_vy', 'body_wrist_direction_none', 'body_wrist_direction_up', 'body_wrist_direction_down', 'body_wrist_direction_left', 'body_wrist_direction_right']
- Masked side features: ['elbow_x_from_shoulder_over_shoulder_width', 'elbow_y_from_shoulder_over_shoulder_width', 'elbow_shoulder_radial_velocity_over_shoulder_width', 'wrist_x_from_elbow_over_shoulder_width', 'wrist_y_from_elbow_over_shoulder_width', 'forearm_unit_x', 'forearm_unit_y', 'wrist_elbow_radial_velocity_over_shoulder_width', 'wrist_elbow_tangential_velocity_over_shoulder_width', 'wrist_minus_elbow_velocity_x_over_shoulder_width', 'wrist_minus_elbow_velocity_y_over_shoulder_width', 'body_wrist_minus_elbow_velocity_lateral_over_shoulder_width', 'body_wrist_minus_elbow_velocity_vertical_over_shoulder_width']

## Variant A (hook_uppercut_motion_shape_variant_a_v1)

- Class order: ['hook_left', 'hook_right', 'uppercut_left', 'uppercut_right', 'no_punch']
- Feature count: 56
- Retimed MLP test accuracy/macro-F1: 0.8148 / 0.4778
- Retimed CNN test accuracy/macro-F1: 0.8148 / 0.3121
- Fair retimed shared-vector subset baseline accuracy/macro-F1: 0.8889 / 0.5872
- MLP delta vs fair retimed subset baseline accuracy/macro-F1: -0.0741 / -0.1095
- CNN delta vs fair retimed subset baseline accuracy/macro-F1: -0.0741 / -0.2752
- Delta vs retimed control MLP accuracy/macro-F1: +0.1111 / +0.0986
- Delta vs retimed control CNN accuracy/macro-F1: -0.0370 / -0.2039
- Retimed delta vs pre-retime MLP accuracy/macro-F1: -0.0370 / +0.2938
- Active side features: ['shoulder_x', 'shoulder_y', 'elbow_x', 'elbow_y', 'wrist_x', 'wrist_y', 'combined_elbow_wrist_velocity_xy_magnitude', 'elbow_shoulder_xy_distance_over_shoulder_width', 'camera_wrist_signed_vx', 'camera_wrist_signed_vy', 'camera_wrist_direction_none', 'camera_wrist_direction_up', 'camera_wrist_direction_down', 'camera_wrist_direction_left', 'camera_wrist_direction_right', 'body_wrist_signed_vx', 'body_wrist_signed_vy', 'body_wrist_direction_none', 'body_wrist_direction_up', 'body_wrist_direction_down', 'body_wrist_direction_left', 'body_wrist_direction_right', 'wrist_x_from_elbow_over_shoulder_width', 'wrist_y_from_elbow_over_shoulder_width', 'forearm_unit_x', 'forearm_unit_y', 'wrist_elbow_radial_velocity_over_shoulder_width', 'wrist_elbow_tangential_velocity_over_shoulder_width']
- Masked side features: ['elbow_x_from_shoulder_over_shoulder_width', 'elbow_y_from_shoulder_over_shoulder_width', 'elbow_shoulder_radial_velocity_over_shoulder_width', 'wrist_minus_elbow_velocity_x_over_shoulder_width', 'wrist_minus_elbow_velocity_y_over_shoulder_width', 'body_wrist_minus_elbow_velocity_lateral_over_shoulder_width', 'body_wrist_minus_elbow_velocity_vertical_over_shoulder_width']

## Variant B

- Not rerun under retimed truth in this slice.
- Reason: Task 19 ranked it lowest-value and redundant unless Variant A produced a strong enough positive signal to justify expanding the matrix. Variant A improved enough to open the CNN gate, but its retimed CNN still underperformed both the retimed control CNN and the fair retimed shared-vector subset baseline, so rerunning Variant B would not have changed the decision.

## Conclusion shift under retimed truth

- **Survives:** the old broad conclusion that the current hook/uppercut motion-shape cue family is still not good enough to beat the fair shared-vector hook/uppercut subset baseline.
- **Weakens:** the old narrower conclusion that no new motion-shape variant could even beat the control MLP. Under retimed truth, Variant A MLP now beats the retimed control MLP on macro-F1 (0.4778 vs 0.3792) and therefore legitimately opened the CNN gate.
- **Does not reverse overall:** once run through the full gated comparison, Variant A still fails to win the decision that matters. Its retimed CNN lands at 0.8148 / 0.3121, below both the retimed control CNN (0.8519 / 0.5159) and the fair retimed shared-vector subset baseline (0.8889 / 0.5872).

## Artifact paths

- Source export: `docs/baselines/boxing-punch-classifier-family-masked-topology-hook-uppercut-motion-shape-benchmark-2026-06-18/family_combined_directional_hook_motion_shape_v1/export/`
- Control export / MLP / CNN: `docs/baselines/boxing-punch-classifier-family-masked-topology-hook-uppercut-motion-shape-benchmark-2026-06-18/hook_uppercut_family_mask_v1/`
- Variant A export / MLP / CNN: `docs/baselines/boxing-punch-classifier-family-masked-topology-hook-uppercut-motion-shape-benchmark-2026-06-18/hook_uppercut_motion_shape_variant_a_v1/`
- Benchmark summary: `docs/baselines/boxing-punch-classifier-family-masked-topology-hook-uppercut-motion-shape-benchmark-2026-06-18/summary.json`, `docs/baselines/boxing-punch-classifier-family-masked-topology-hook-uppercut-motion-shape-benchmark-2026-06-18/summary.md`
