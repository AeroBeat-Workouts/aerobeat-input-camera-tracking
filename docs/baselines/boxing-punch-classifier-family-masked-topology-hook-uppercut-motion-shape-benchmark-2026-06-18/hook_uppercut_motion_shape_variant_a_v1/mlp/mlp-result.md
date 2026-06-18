# Boxing Punch Classifier Temporal-MLP Baseline

- Trained at: `2026-06-18T16:44:27.691322+00:00`
- Dataset: `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/docs/baselines/boxing-punch-classifier-family-masked-topology-hook-uppercut-motion-shape-benchmark-2026-06-18/hook_uppercut_motion_shape_variant_a_v1/export/dataset.json`
- Split strategy: `chronological_holdout_v1`
- Model shape: `8x56 -> flatten(448) -> hidden(24) -> logits(5)`
- Epochs: **450**
- Learning rate: **0.045**
- Weight decay: **0.0005**

## Test split comparison

- Temporal MLP accuracy: **0.852**
- Temporal MLP macro F1: **0.184**
- Threshold baseline accuracy: **0.778**
- Threshold baseline macro F1: **0.509**

## Temporal MLP confusion (test)

| actual \ predicted | hook_left | hook_right | uppercut_left | uppercut_right | no_punch |
| --- | --- | --- | --- | --- | --- |
| hook_left | 0 | 0 | 0 | 0 | 1 |
| hook_right | 0 | 0 | 0 | 0 | 1 |
| uppercut_left | 0 | 0 | 0 | 0 | 1 |
| uppercut_right | 0 | 0 | 0 | 0 | 1 |
| no_punch | 0 | 0 | 0 | 0 | 23 |

## Threshold confusion (test)

| actual \ predicted | hook_left | hook_right | uppercut_left | uppercut_right | no_punch |
| --- | --- | --- | --- | --- | --- |
| hook_left | 1 | 0 | 0 | 0 | 0 |
| hook_right | 0 | 1 | 0 | 0 | 0 |
| uppercut_left | 0 | 0 | 1 | 0 | 0 |
| uppercut_right | 0 | 1 | 0 | 0 | 0 |
| no_punch | 1 | 1 | 2 | 1 | 18 |

## Notes

- This benchmark is still small, but it now uses chronological holdout instead of interleaving nearby windows across train/test.
- The threshold comparison reuses the same exported windows and reads the threshold detector's emitted events from the capture reports attached to the dataset export.
