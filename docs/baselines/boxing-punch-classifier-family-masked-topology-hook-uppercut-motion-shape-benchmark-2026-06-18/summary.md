# Hook/uppercut motion-shape benchmark (2026-06-18)

Shared-vector baseline full test accuracy/macro-F1: 0.8621 / 0.4198

## Full source export inventory

- Feature set: `family_combined_directional_hook_motion_shape_v1`
- Sample count: 96
- Frame feature count: 70
- Per-side feature inventory: ['shoulder_x', 'shoulder_y', 'elbow_x', 'elbow_y', 'wrist_x', 'wrist_y', 'combined_elbow_wrist_velocity_xy_magnitude', 'elbow_shoulder_xy_distance_over_shoulder_width', 'elbow_x_from_shoulder_over_shoulder_width', 'elbow_y_from_shoulder_over_shoulder_width', 'elbow_shoulder_radial_velocity_over_shoulder_width', 'camera_wrist_signed_vx', 'camera_wrist_signed_vy', 'camera_wrist_direction_none', 'camera_wrist_direction_up', 'camera_wrist_direction_down', 'camera_wrist_direction_left', 'camera_wrist_direction_right', 'body_wrist_signed_vx', 'body_wrist_signed_vy', 'body_wrist_direction_none', 'body_wrist_direction_up', 'body_wrist_direction_down', 'body_wrist_direction_left', 'body_wrist_direction_right', 'wrist_x_from_elbow_over_shoulder_width', 'wrist_y_from_elbow_over_shoulder_width', 'forearm_unit_x', 'forearm_unit_y', 'wrist_elbow_radial_velocity_over_shoulder_width', 'wrist_elbow_tangential_velocity_over_shoulder_width', 'wrist_minus_elbow_velocity_x_over_shoulder_width', 'wrist_minus_elbow_velocity_y_over_shoulder_width', 'body_wrist_minus_elbow_velocity_lateral_over_shoulder_width', 'body_wrist_minus_elbow_velocity_vertical_over_shoulder_width']

## CNN gate

- Rule: Run CNN on control and on the best new MLP variant only if that new variant improves hook/uppercut macro-F1 over the control MLP.
- Control MLP macro-F1: 0.3159
- Best new variant by MLP macro-F1: `hook_uppercut_motion_shape_variant_a_v1` at 0.1840
- Gate triggered: no

## Control (hook_uppercut_family_mask_v1)

- Class order: ['hook_left', 'hook_right', 'uppercut_left', 'uppercut_right', 'no_punch']
- Feature count: 44
- MLP test accuracy/macro-F1: 0.8148 / 0.3159
- CNN test accuracy/macro-F1: 0.8148 / 0.1796
- Shared-vector subset baseline accuracy/macro-F1: 0.8519 / 0.1878
- CNN delta vs subset baseline accuracy/macro-F1: -0.0370 / -0.0082
- MLP delta vs subset baseline accuracy/macro-F1: -0.0370 / +0.1282
- Active side features: ['shoulder_x', 'shoulder_y', 'elbow_x', 'elbow_y', 'wrist_x', 'wrist_y', 'combined_elbow_wrist_velocity_xy_magnitude', 'elbow_shoulder_xy_distance_over_shoulder_width', 'camera_wrist_signed_vx', 'camera_wrist_signed_vy', 'camera_wrist_direction_none', 'camera_wrist_direction_up', 'camera_wrist_direction_down', 'camera_wrist_direction_left', 'camera_wrist_direction_right', 'body_wrist_signed_vx', 'body_wrist_signed_vy', 'body_wrist_direction_none', 'body_wrist_direction_up', 'body_wrist_direction_down', 'body_wrist_direction_left', 'body_wrist_direction_right']
- Masked side features: ['elbow_x_from_shoulder_over_shoulder_width', 'elbow_y_from_shoulder_over_shoulder_width', 'elbow_shoulder_radial_velocity_over_shoulder_width', 'wrist_x_from_elbow_over_shoulder_width', 'wrist_y_from_elbow_over_shoulder_width', 'forearm_unit_x', 'forearm_unit_y', 'wrist_elbow_radial_velocity_over_shoulder_width', 'wrist_elbow_tangential_velocity_over_shoulder_width', 'wrist_minus_elbow_velocity_x_over_shoulder_width', 'wrist_minus_elbow_velocity_y_over_shoulder_width', 'body_wrist_minus_elbow_velocity_lateral_over_shoulder_width', 'body_wrist_minus_elbow_velocity_vertical_over_shoulder_width']

## Variant A (hook_uppercut_motion_shape_variant_a_v1)

- Class order: ['hook_left', 'hook_right', 'uppercut_left', 'uppercut_right', 'no_punch']
- Feature count: 56
- MLP test accuracy/macro-F1: 0.8519 / 0.1840
- CNN: not run (Skipped by narrow-matrix gate: no new motion-shape MLP variant improved macro-F1 over the control MLP.)
- Shared-vector subset baseline accuracy/macro-F1: 0.8519 / 0.1878
- MLP delta vs subset baseline accuracy/macro-F1: +0.0000 / -0.0038
- Active side features: ['shoulder_x', 'shoulder_y', 'elbow_x', 'elbow_y', 'wrist_x', 'wrist_y', 'combined_elbow_wrist_velocity_xy_magnitude', 'elbow_shoulder_xy_distance_over_shoulder_width', 'camera_wrist_signed_vx', 'camera_wrist_signed_vy', 'camera_wrist_direction_none', 'camera_wrist_direction_up', 'camera_wrist_direction_down', 'camera_wrist_direction_left', 'camera_wrist_direction_right', 'body_wrist_signed_vx', 'body_wrist_signed_vy', 'body_wrist_direction_none', 'body_wrist_direction_up', 'body_wrist_direction_down', 'body_wrist_direction_left', 'body_wrist_direction_right', 'wrist_x_from_elbow_over_shoulder_width', 'wrist_y_from_elbow_over_shoulder_width', 'forearm_unit_x', 'forearm_unit_y', 'wrist_elbow_radial_velocity_over_shoulder_width', 'wrist_elbow_tangential_velocity_over_shoulder_width']
- Masked side features: ['elbow_x_from_shoulder_over_shoulder_width', 'elbow_y_from_shoulder_over_shoulder_width', 'elbow_shoulder_radial_velocity_over_shoulder_width', 'wrist_minus_elbow_velocity_x_over_shoulder_width', 'wrist_minus_elbow_velocity_y_over_shoulder_width', 'body_wrist_minus_elbow_velocity_lateral_over_shoulder_width', 'body_wrist_minus_elbow_velocity_vertical_over_shoulder_width']

## Variant B (hook_uppercut_motion_shape_variant_b_v1)

- Class order: ['hook_left', 'hook_right', 'uppercut_left', 'uppercut_right', 'no_punch']
- Feature count: 64
- MLP test accuracy/macro-F1: 0.7407 / 0.1739
- CNN: not run (Skipped by narrow-matrix gate: no new motion-shape MLP variant improved macro-F1 over the control MLP.)
- Shared-vector subset baseline accuracy/macro-F1: 0.8519 / 0.1878
- MLP delta vs subset baseline accuracy/macro-F1: -0.1111 / -0.0138
- Active side features: ['shoulder_x', 'shoulder_y', 'elbow_x', 'elbow_y', 'wrist_x', 'wrist_y', 'combined_elbow_wrist_velocity_xy_magnitude', 'elbow_shoulder_xy_distance_over_shoulder_width', 'camera_wrist_signed_vx', 'camera_wrist_signed_vy', 'camera_wrist_direction_none', 'camera_wrist_direction_up', 'camera_wrist_direction_down', 'camera_wrist_direction_left', 'camera_wrist_direction_right', 'body_wrist_signed_vx', 'body_wrist_signed_vy', 'body_wrist_direction_none', 'body_wrist_direction_up', 'body_wrist_direction_down', 'body_wrist_direction_left', 'body_wrist_direction_right', 'wrist_x_from_elbow_over_shoulder_width', 'wrist_y_from_elbow_over_shoulder_width', 'forearm_unit_x', 'forearm_unit_y', 'wrist_elbow_radial_velocity_over_shoulder_width', 'wrist_elbow_tangential_velocity_over_shoulder_width', 'wrist_minus_elbow_velocity_x_over_shoulder_width', 'wrist_minus_elbow_velocity_y_over_shoulder_width', 'body_wrist_minus_elbow_velocity_lateral_over_shoulder_width', 'body_wrist_minus_elbow_velocity_vertical_over_shoulder_width']
- Masked side features: ['elbow_x_from_shoulder_over_shoulder_width', 'elbow_y_from_shoulder_over_shoulder_width', 'elbow_shoulder_radial_velocity_over_shoulder_width']
