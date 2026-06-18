# Straight-family reduced masked topology benchmark (2026-06-18)

Shared-vector baseline CNN: **0.8621 accuracy / 0.4198 macro-F1** on the full 7-class test set.

## Straight family reduced Variant A (straight_family_reduced_variant_a_v1)

- Active side features: `["shoulder_x", "shoulder_y", "elbow_x", "elbow_y", "wrist_x", "wrist_y", "combined_elbow_wrist_velocity_xy_magnitude", "elbow_shoulder_xy_distance_over_shoulder_width", "elbow_shoulder_radial_velocity_over_shoulder_width"]`
- Frame feature count: **18**
- Sample count: **80**
- MLP: **0.9600 accuracy / 0.8815 macro-F1**
- CNN: **0.9600 accuracy / 0.8815 macro-F1**
- Shared-vector straight-family subset baseline: **1.0000 accuracy / 1.0000 macro-F1** on **25** test windows

## Straight family reduced Variant B (straight_family_reduced_variant_b_v1)

- Active side features: `["elbow_shoulder_xy_distance_over_shoulder_width", "elbow_shoulder_radial_velocity_over_shoulder_width"]`
- Frame feature count: **4**
- Sample count: **80**
- MLP: **0.8800 accuracy / 0.5333 macro-F1**
- CNN: **0.9200 accuracy / 0.5411 macro-F1**
- Shared-vector straight-family subset baseline: **1.0000 accuracy / 1.0000 macro-F1** on **25** test windows
