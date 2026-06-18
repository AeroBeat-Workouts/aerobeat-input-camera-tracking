# Boxing Punch Classifier 1D Temporal CNN Baseline

- Trained at: `2026-06-18T10:34:37.492829+00:00`
- Dataset: `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/docs/baselines/boxing-punch-classifier-directional-feature-benchmark-2026-06-18/camera_directional_v1/export/dataset.json`
- MLP baseline: `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/docs/baselines/boxing-punch-classifier-directional-feature-benchmark-2026-06-18/camera_directional_v1/mlp/mlp-result.json`
- Split strategy: `chronological_holdout_v1`
- Model shape: `8x30 -> conv1d(30->12, k=3, same) -> relu -> conv1d(12->12, k=3, same) -> relu -> flatten(96) -> logits(7)`
- Epochs: **500**
- Learning rate: **0.02**
- Weight decay: **0.0005**

## Test split comparison

- Temporal CNN accuracy: **0.759**
- Temporal CNN macro F1: **0.362**
- Temporal MLP accuracy: **0.690**
- Temporal MLP macro F1: **0.355**
- Threshold baseline accuracy: **0.655**
- Threshold baseline macro F1: **0.341**

## Temporal CNN confusion (test)

| actual \ predicted | straight_left | straight_right | hook_left | hook_right | uppercut_left | uppercut_right | no_punch |
| --- | --- | --- | --- | --- | --- | --- | --- |
| straight_left | 0 | 0 | 0 | 0 | 0 | 1 | 0 |
| straight_right | 0 | 1 | 0 | 0 | 0 | 0 | 0 |
| hook_left | 0 | 0 | 0 | 0 | 0 | 0 | 1 |
| hook_right | 0 | 0 | 0 | 0 | 0 | 0 | 1 |
| uppercut_left | 0 | 0 | 0 | 0 | 1 | 0 | 0 |
| uppercut_right | 0 | 0 | 0 | 0 | 0 | 0 | 1 |
| no_punch | 0 | 0 | 0 | 2 | 1 | 0 | 20 |

## Temporal MLP confusion (test)

| actual \ predicted | straight_left | straight_right | hook_left | hook_right | uppercut_left | uppercut_right | no_punch |
| --- | --- | --- | --- | --- | --- | --- | --- |
| straight_left | 1 | 0 | 0 | 0 | 0 | 0 | 0 |
| straight_right | 0 | 1 | 0 | 0 | 0 | 0 | 0 |
| hook_left | 0 | 0 | 0 | 0 | 0 | 0 | 1 |
| hook_right | 0 | 0 | 0 | 0 | 0 | 0 | 1 |
| uppercut_left | 0 | 0 | 0 | 0 | 0 | 1 | 0 |
| uppercut_right | 0 | 0 | 0 | 0 | 0 | 0 | 1 |
| no_punch | 1 | 0 | 1 | 0 | 1 | 2 | 18 |

## Threshold confusion (test)

| actual \ predicted | straight_left | straight_right | hook_left | hook_right | uppercut_left | uppercut_right | no_punch |
| --- | --- | --- | --- | --- | --- | --- | --- |
| straight_left | 0 | 0 | 0 | 1 | 0 | 0 | 0 |
| straight_right | 0 | 0 | 0 | 0 | 0 | 1 | 0 |
| hook_left | 0 | 0 | 1 | 0 | 0 | 0 | 0 |
| hook_right | 0 | 0 | 0 | 1 | 0 | 0 | 0 |
| uppercut_left | 0 | 0 | 0 | 0 | 1 | 0 | 0 |
| uppercut_right | 0 | 0 | 0 | 1 | 0 | 0 | 0 |
| no_punch | 1 | 1 | 1 | 1 | 2 | 1 | 16 |

## Notes

- This is only a fixture-local same-harness directional comparison. Do not read it as real-world punch generalization.
- This run uses the hardened `chronological_holdout_v1` split rather than the earlier same-clip interleaved split.
- Compare models fairly inside the committed export protocol used for this dataset/snapshot.
