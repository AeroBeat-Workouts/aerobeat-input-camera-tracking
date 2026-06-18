# Boxing Punch Classifier 1D Temporal CNN Baseline

- Trained at: `2026-06-18T19:46:08.303846+00:00`
- Dataset: `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/docs/baselines/boxing-punch-classifier-family-masked-topology-hook-uppercut-motion-shape-benchmark-2026-06-18/hook_uppercut_motion_shape_variant_c_v1/export/dataset.json`
- MLP baseline: `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/docs/baselines/boxing-punch-classifier-family-masked-topology-hook-uppercut-motion-shape-benchmark-2026-06-18/hook_uppercut_motion_shape_variant_c_v1/mlp/mlp-result.json`
- Split strategy: `chronological_holdout_v1`
- Model shape: `8x62 -> conv1d(62->12, k=3, same) -> relu -> conv1d(12->12, k=3, same) -> relu -> flatten(96) -> logits(5)`
- Epochs: **500**
- Learning rate: **0.02**
- Weight decay: **0.0005**

## Test split comparison

- Temporal CNN accuracy: **0.852**
- Temporal CNN macro F1: **0.516**
- Temporal MLP accuracy: **0.815**
- Temporal MLP macro F1: **0.478**
- Threshold baseline accuracy: **0.704**
- Threshold baseline macro F1: **0.399**

## Temporal CNN confusion (test)

| actual \ predicted | hook_left | hook_right | uppercut_left | uppercut_right | no_punch |
| --- | --- | --- | --- | --- | --- |
| hook_left | 1 | 0 | 0 | 0 | 0 |
| hook_right | 0 | 1 | 0 | 0 | 0 |
| uppercut_left | 0 | 0 | 0 | 0 | 1 |
| uppercut_right | 0 | 0 | 0 | 0 | 1 |
| no_punch | 1 | 0 | 1 | 0 | 21 |

## Temporal MLP confusion (test)

| actual \ predicted | hook_left | hook_right | uppercut_left | uppercut_right | no_punch |
| --- | --- | --- | --- | --- | --- |
| hook_left | 1 | 0 | 0 | 0 | 0 |
| hook_right | 0 | 1 | 0 | 0 | 0 |
| uppercut_left | 0 | 0 | 0 | 0 | 1 |
| uppercut_right | 0 | 0 | 0 | 0 | 1 |
| no_punch | 2 | 0 | 1 | 0 | 20 |

## Threshold confusion (test)

| actual \ predicted | hook_left | hook_right | uppercut_left | uppercut_right | no_punch |
| --- | --- | --- | --- | --- | --- |
| hook_left | 0 | 0 | 0 | 1 | 0 |
| hook_right | 0 | 1 | 0 | 0 | 0 |
| uppercut_left | 0 | 0 | 1 | 0 | 0 |
| uppercut_right | 0 | 0 | 0 | 0 | 1 |
| no_punch | 2 | 1 | 2 | 1 | 17 |

## Notes

- This is only a fixture-local same-harness directional comparison. Do not read it as real-world punch generalization.
- This run uses the hardened `chronological_holdout_v1` split rather than the earlier same-clip interleaved split.
- Compare models fairly inside the committed export protocol used for this dataset/snapshot.
