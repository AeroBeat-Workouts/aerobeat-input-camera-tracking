# Boxing Punch Classifier 1D Temporal CNN Baseline

- Trained at: `2026-06-18T16:17:49.954921+00:00`
- Dataset: `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/docs/baselines/boxing-punch-classifier-family-masked-topology-straight-reduced-benchmark-2026-06-18/straight_family_reduced_variant_b_v1/export/dataset.json`
- MLP baseline: `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/docs/baselines/boxing-punch-classifier-family-masked-topology-straight-reduced-benchmark-2026-06-18/straight_family_reduced_variant_b_v1/mlp/mlp-result.json`
- Split strategy: `chronological_holdout_v1`
- Model shape: `8x4 -> conv1d(4->12, k=3, same) -> relu -> conv1d(12->12, k=3, same) -> relu -> flatten(96) -> logits(3)`
- Epochs: **500**
- Learning rate: **0.02**
- Weight decay: **0.0005**

## Test split comparison

- Temporal CNN accuracy: **0.920**
- Temporal CNN macro F1: **0.541**
- Temporal MLP accuracy: **0.880**
- Temporal MLP macro F1: **0.533**
- Threshold baseline accuracy: **0.840**
- Threshold baseline macro F1: **0.304**

## Temporal CNN confusion (test)

| actual \ predicted | straight_left | straight_right | no_punch |
| --- | --- | --- | --- |
| straight_left | 0 | 0 | 1 |
| straight_right | 0 | 1 | 0 |
| no_punch | 0 | 1 | 22 |

## Temporal MLP confusion (test)

| actual \ predicted | straight_left | straight_right | no_punch |
| --- | --- | --- | --- |
| straight_left | 0 | 0 | 1 |
| straight_right | 0 | 1 | 0 |
| no_punch | 1 | 1 | 21 |

## Threshold confusion (test)

| actual \ predicted | straight_left | straight_right | no_punch |
| --- | --- | --- | --- |
| straight_left | 0 | 0 | 1 |
| straight_right | 0 | 0 | 1 |
| no_punch | 1 | 1 | 21 |

## Notes

- This is only a fixture-local same-harness directional comparison. Do not read it as real-world punch generalization.
- This run uses the hardened `chronological_holdout_v1` split rather than the earlier same-clip interleaved split.
- Compare models fairly inside the committed export protocol used for this dataset/snapshot.
