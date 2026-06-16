# Boxing Punch Classifier Temporal-MLP Baseline

- Trained at: `2026-06-16T20:08:49.483233+00:00`
- Dataset: `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.temp/boxing-punch-classifier-export/run-2026-06-16/dataset.json`
- Model shape: `8x16 -> flatten(128) -> hidden(12) -> logits(7)`
- Epochs: **300**
- Learning rate: **0.04**
- Weight decay: **0.001**

## Test split comparison

- Temporal MLP accuracy: **0.867**
- Temporal MLP macro F1: **0.887**
- Threshold baseline accuracy: **0.400**
- Threshold baseline macro F1: **0.095**

## Temporal MLP confusion (test)

| actual \ predicted | straight_left | straight_right | hook_left | hook_right | uppercut_left | uppercut_right | no_punch |
| --- | --- | --- | --- | --- | --- | --- | --- |
| straight_left | 1 | 0 | 0 | 0 | 0 | 0 | 0 |
| straight_right | 0 | 1 | 0 | 0 | 0 | 0 | 0 |
| hook_left | 0 | 0 | 1 | 0 | 0 | 0 | 0 |
| hook_right | 0 | 0 | 0 | 1 | 0 | 0 | 0 |
| uppercut_left | 0 | 0 | 0 | 0 | 1 | 0 | 0 |
| uppercut_right | 0 | 0 | 0 | 0 | 0 | 1 | 0 |
| no_punch | 1 | 0 | 0 | 1 | 0 | 0 | 7 |

## Threshold confusion (test)

| actual \ predicted | straight_left | straight_right | hook_left | hook_right | uppercut_left | uppercut_right | no_punch |
| --- | --- | --- | --- | --- | --- | --- | --- |
| straight_left | 0 | 0 | 0 | 0 | 0 | 0 | 1 |
| straight_right | 0 | 0 | 0 | 0 | 0 | 0 | 1 |
| hook_left | 0 | 0 | 0 | 0 | 0 | 0 | 1 |
| hook_right | 0 | 0 | 1 | 0 | 0 | 0 | 0 |
| uppercut_left | 1 | 0 | 0 | 0 | 0 | 0 | 0 |
| uppercut_right | 0 | 0 | 0 | 0 | 1 | 0 | 0 |
| no_punch | 0 | 0 | 1 | 2 | 0 | 0 | 6 |

## Notes

- This split is intentionally tiny and clip-local; it is useful for sanity-checking the export/training/eval path, not for claiming production-ready generalization.
- The threshold comparison reuses the same exported windows and reads the threshold detector's emitted events from the capture reports attached to the dataset export.
