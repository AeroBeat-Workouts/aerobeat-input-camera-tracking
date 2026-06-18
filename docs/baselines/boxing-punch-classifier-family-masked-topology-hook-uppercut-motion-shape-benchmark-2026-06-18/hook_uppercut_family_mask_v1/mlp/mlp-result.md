# Boxing Punch Classifier Temporal-MLP Baseline

- Trained at: `2026-06-18T18:20:49.011893+00:00`
- Dataset: `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/docs/baselines/boxing-punch-classifier-family-masked-topology-hook-uppercut-motion-shape-benchmark-2026-06-18/hook_uppercut_family_mask_v1/export/dataset.json`
- Split strategy: `chronological_holdout_v1`
- Model shape: `8x44 -> flatten(352) -> hidden(24) -> logits(5)`
- Epochs: **450**
- Learning rate: **0.045**
- Weight decay: **0.0005**

## Test split comparison

- Temporal MLP accuracy: **0.704**
- Temporal MLP macro F1: **0.379**
- Threshold baseline accuracy: **0.704**
- Threshold baseline macro F1: **0.399**

## Temporal MLP confusion (test)

| actual \ predicted | hook_left | hook_right | uppercut_left | uppercut_right | no_punch |
| --- | --- | --- | --- | --- | --- |
| hook_left | 1 | 0 | 0 | 0 | 0 |
| hook_right | 0 | 1 | 0 | 0 | 0 |
| uppercut_left | 0 | 0 | 0 | 0 | 1 |
| uppercut_right | 1 | 0 | 0 | 0 | 0 |
| no_punch | 2 | 1 | 1 | 2 | 17 |

## Threshold confusion (test)

| actual \ predicted | hook_left | hook_right | uppercut_left | uppercut_right | no_punch |
| --- | --- | --- | --- | --- | --- |
| hook_left | 0 | 0 | 0 | 1 | 0 |
| hook_right | 0 | 1 | 0 | 0 | 0 |
| uppercut_left | 0 | 0 | 1 | 0 | 0 |
| uppercut_right | 0 | 0 | 0 | 0 | 1 |
| no_punch | 2 | 1 | 2 | 1 | 17 |

## Notes

- This benchmark is still small, but it now uses chronological holdout instead of interleaving nearby windows across train/test.
- The threshold comparison reuses the same exported windows and reads the threshold detector's emitted events from the capture reports attached to the dataset export.
