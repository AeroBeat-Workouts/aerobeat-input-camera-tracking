# Family-masked topology benchmark (2026-06-18)

Shared-vector family-specific full test accuracy/macro-F1: 0.6897 / 0.3550

## Straight family head (straight_family_mask_v1)

- Class order: ['straight_left', 'straight_right', 'no_punch']
- Feature count: 22
- CNN test accuracy/macro-F1: 0.8800 / 0.6990
- MLP test accuracy/macro-F1: 0.8800 / 0.6990
- Shared-vector subset baseline accuracy/macro-F1: 0.7600 / 0.2879
- CNN delta vs subset baseline accuracy/macro-F1: +0.1200 / +0.4111
- MLP delta vs subset baseline accuracy/macro-F1: +0.1200 / +0.4111
- Active side features: ['shoulder_x', 'shoulder_y', 'elbow_x', 'elbow_y', 'wrist_x', 'wrist_y', 'combined_elbow_wrist_velocity_xy_magnitude', 'elbow_shoulder_xy_distance_over_shoulder_width', 'elbow_x_from_shoulder_over_shoulder_width', 'elbow_y_from_shoulder_over_shoulder_width', 'elbow_shoulder_radial_velocity_over_shoulder_width']
- Masked side features: ['camera_wrist_signed_vx', 'camera_wrist_signed_vy', 'camera_wrist_direction_none', 'camera_wrist_direction_up', 'camera_wrist_direction_down', 'camera_wrist_direction_left', 'camera_wrist_direction_right', 'body_wrist_signed_vx', 'body_wrist_signed_vy', 'body_wrist_direction_none', 'body_wrist_direction_up', 'body_wrist_direction_down', 'body_wrist_direction_left', 'body_wrist_direction_right']

## Hook/uppercut family head (hook_uppercut_family_mask_v1)

- Class order: ['hook_left', 'hook_right', 'uppercut_left', 'uppercut_right', 'no_punch']
- Feature count: 44
- CNN test accuracy/macro-F1: 0.8519 / 0.5159
- MLP test accuracy/macro-F1: 0.7037 / 0.3792
- Shared-vector subset baseline accuracy/macro-F1: 0.8889 / 0.5872
- CNN delta vs subset baseline accuracy/macro-F1: -0.0370 / -0.0713
- MLP delta vs subset baseline accuracy/macro-F1: -0.1852 / -0.2080
- Active side features: ['shoulder_x', 'shoulder_y', 'elbow_x', 'elbow_y', 'wrist_x', 'wrist_y', 'combined_elbow_wrist_velocity_xy_magnitude', 'elbow_shoulder_xy_distance_over_shoulder_width', 'camera_wrist_signed_vx', 'camera_wrist_signed_vy', 'camera_wrist_direction_none', 'camera_wrist_direction_up', 'camera_wrist_direction_down', 'camera_wrist_direction_left', 'camera_wrist_direction_right', 'body_wrist_signed_vx', 'body_wrist_signed_vy', 'body_wrist_direction_none', 'body_wrist_direction_up', 'body_wrist_direction_down', 'body_wrist_direction_left', 'body_wrist_direction_right']
- Masked side features: ['elbow_x_from_shoulder_over_shoulder_width', 'elbow_y_from_shoulder_over_shoulder_width', 'elbow_shoulder_radial_velocity_over_shoulder_width']
