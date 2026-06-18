# Family-masked topology benchmark (2026-06-18)

Shared-vector baseline full test accuracy/macro-F1: 0.8621 / 0.4198

## Straight family head (straight_family_mask_v1)

- Class order: ['straight_left', 'straight_right', 'no_punch']
- Feature count: 22
- CNN test accuracy/macro-F1: 0.9600 / 0.8815
- MLP test accuracy/macro-F1: 0.9200 / 0.7626
- Shared-vector subset baseline accuracy/macro-F1: 1.0000 / 1.0000
- CNN delta vs subset baseline accuracy/macro-F1: -0.0400 / -0.1185
- MLP delta vs subset baseline accuracy/macro-F1: -0.0800 / -0.2374
- Active side features: ['shoulder_x', 'shoulder_y', 'elbow_x', 'elbow_y', 'wrist_x', 'wrist_y', 'combined_elbow_wrist_velocity_xy_magnitude', 'elbow_shoulder_xy_distance_over_shoulder_width', 'elbow_x_from_shoulder_over_shoulder_width', 'elbow_y_from_shoulder_over_shoulder_width', 'elbow_shoulder_radial_velocity_over_shoulder_width']
- Masked side features: ['camera_wrist_signed_vx', 'camera_wrist_signed_vy', 'camera_wrist_direction_none', 'camera_wrist_direction_up', 'camera_wrist_direction_down', 'camera_wrist_direction_left', 'camera_wrist_direction_right', 'body_wrist_signed_vx', 'body_wrist_signed_vy', 'body_wrist_direction_none', 'body_wrist_direction_up', 'body_wrist_direction_down', 'body_wrist_direction_left', 'body_wrist_direction_right']

## Hook/uppercut family head (hook_uppercut_family_mask_v1)

- Class order: ['hook_left', 'hook_right', 'uppercut_left', 'uppercut_right', 'no_punch']
- Feature count: 44
- CNN test accuracy/macro-F1: 0.8148 / 0.1796
- MLP test accuracy/macro-F1: 0.8148 / 0.3159
- Shared-vector subset baseline accuracy/macro-F1: 0.8519 / 0.1878
- CNN delta vs subset baseline accuracy/macro-F1: -0.0370 / -0.0082
- MLP delta vs subset baseline accuracy/macro-F1: -0.0370 / +0.1282
- Active side features: ['shoulder_x', 'shoulder_y', 'elbow_x', 'elbow_y', 'wrist_x', 'wrist_y', 'combined_elbow_wrist_velocity_xy_magnitude', 'elbow_shoulder_xy_distance_over_shoulder_width', 'camera_wrist_signed_vx', 'camera_wrist_signed_vy', 'camera_wrist_direction_none', 'camera_wrist_direction_up', 'camera_wrist_direction_down', 'camera_wrist_direction_left', 'camera_wrist_direction_right', 'body_wrist_signed_vx', 'body_wrist_signed_vy', 'body_wrist_direction_none', 'body_wrist_direction_up', 'body_wrist_direction_down', 'body_wrist_direction_left', 'body_wrist_direction_right']
- Masked side features: ['elbow_x_from_shoulder_over_shoulder_width', 'elbow_y_from_shoulder_over_shoulder_width', 'elbow_shoulder_radial_velocity_over_shoulder_width']

