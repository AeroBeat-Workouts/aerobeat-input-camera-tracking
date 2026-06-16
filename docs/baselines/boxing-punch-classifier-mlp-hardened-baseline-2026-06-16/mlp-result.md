# Boxing Punch Classifier Temporal-MLP Baseline

- Trained at: `2026-06-16T21:40:39.465438+00:00`
- Dataset: `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.temp/boxing-punch-classifier-export/hardened-2026-06-16/dataset.json`
- Split strategy: `chronological_holdout_v1`
- Model shape: `8x16 -> flatten(128) -> hidden(24) -> logits(7)`
- Epochs: **450**
- Learning rate: **0.045**
- Weight decay: **0.0005**

## Test split comparison

- Temporal MLP accuracy: **0.655**
- Temporal MLP macro F1: **0.210**
- Threshold baseline accuracy: **0.621**
- Threshold baseline macro F1: **0.259**

## Temporal MLP confusion (test)

| actual \ predicted | straight_left | straight_right | hook_left | hook_right | uppercut_left | uppercut_right | no_punch |
| --- | --- | --- | --- | --- | --- | --- | --- |
| straight_left | 1 | 0 | 0 | 0 | 0 | 0 | 0 |
| straight_right | 0 | 0 | 0 | 0 | 0 | 0 | 1 |
| hook_left | 0 | 0 | 0 | 0 | 0 | 0 | 1 |
| hook_right | 0 | 0 | 0 | 0 | 0 | 0 | 1 |
| uppercut_left | 0 | 0 | 0 | 0 | 0 | 1 | 0 |
| uppercut_right | 0 | 0 | 0 | 0 | 0 | 0 | 1 |
| no_punch | 1 | 2 | 0 | 1 | 1 | 0 | 18 |

## Threshold confusion (test)

| actual \ predicted | straight_left | straight_right | hook_left | hook_right | uppercut_left | uppercut_right | no_punch |
| --- | --- | --- | --- | --- | --- | --- | --- |
| straight_left | 0 | 0 | 0 | 1 | 0 | 0 | 0 |
| straight_right | 0 | 0 | 0 | 0 | 0 | 0 | 1 |
| hook_left | 1 | 0 | 0 | 0 | 0 | 0 | 0 |
| hook_right | 0 | 0 | 1 | 0 | 0 | 0 | 0 |
| uppercut_left | 0 | 0 | 0 | 0 | 1 | 0 | 0 |
| uppercut_right | 0 | 0 | 0 | 0 | 0 | 0 | 1 |
| no_punch | 1 | 2 | 0 | 2 | 0 | 1 | 17 |

## Notes

- This benchmark is still small, but it now uses chronological holdout instead of interleaving nearby windows across train/test.
- The threshold comparison reuses the same exported windows and reads the threshold detector's emitted events from the capture reports attached to the dataset export.
