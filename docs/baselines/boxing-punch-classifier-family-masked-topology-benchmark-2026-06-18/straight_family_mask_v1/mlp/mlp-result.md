# Boxing Punch Classifier Temporal-MLP Baseline

- Trained at: `2026-06-18T15:27:01.332656+00:00`
- Dataset: `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/docs/baselines/boxing-punch-classifier-family-masked-topology-benchmark-2026-06-18/straight_family_mask_v1/export/dataset.json`
- Split strategy: `chronological_holdout_v1`
- Model shape: `8x22 -> flatten(176) -> hidden(24) -> logits(3)`
- Epochs: **450**
- Learning rate: **0.045**
- Weight decay: **0.0005**

## Test split comparison

- Temporal MLP accuracy: **0.920**
- Temporal MLP macro F1: **0.763**
- Threshold baseline accuracy: **0.840**
- Threshold baseline macro F1: **0.304**

## Temporal MLP confusion (test)

| actual \ predicted | straight_left | straight_right | no_punch |
| --- | --- | --- | --- |
| straight_left | 1 | 0 | 0 |
| straight_right | 0 | 1 | 0 |
| no_punch | 1 | 1 | 21 |

## Threshold confusion (test)

| actual \ predicted | straight_left | straight_right | no_punch |
| --- | --- | --- | --- |
| straight_left | 0 | 0 | 1 |
| straight_right | 0 | 0 | 1 |
| no_punch | 1 | 1 | 21 |

## Notes

- This benchmark is still small, but it now uses chronological holdout instead of interleaving nearby windows across train/test.
- The threshold comparison reuses the same exported windows and reads the threshold detector's emitted events from the capture reports attached to the dataset export.
