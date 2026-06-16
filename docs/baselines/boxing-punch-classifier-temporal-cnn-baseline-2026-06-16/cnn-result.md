# Boxing Punch Classifier 1D Temporal CNN Baseline

- Trained at: `2026-06-16T20:48:01.042660+00:00`
- Dataset: `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/docs/baselines/boxing-punch-classifier-mlp-baseline-2026-06-16/dataset.json`
- MLP baseline: `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/docs/baselines/boxing-punch-classifier-mlp-baseline-2026-06-16/mlp-result.json`
- Model shape: `8x16 -> conv1d(16->12, k=5, same) -> relu -> conv1d(12->8, k=5, same) -> relu -> flatten(64) -> logits(7)`
- Epochs: **1000**
- Learning rate: **0.01**
- Weight decay: **0.0**

## Test split comparison

- Temporal CNN accuracy: **0.667**
- Temporal CNN macro F1: **0.492**
- Temporal MLP accuracy: **0.867**
- Temporal MLP macro F1: **0.887**
- Threshold baseline accuracy: **0.400**
- Threshold baseline macro F1: **0.095**

## Temporal CNN confusion (test)

| actual \ predicted | straight_left | straight_right | hook_left | hook_right | uppercut_left | uppercut_right | no_punch |
| --- | --- | --- | --- | --- | --- | --- | --- |
| straight_left | 0 | 0 | 0 | 0 | 0 | 0 | 1 |
| straight_right | 0 | 1 | 0 | 0 | 0 | 0 | 0 |
| hook_left | 0 | 0 | 1 | 0 | 0 | 0 | 0 |
| hook_right | 0 | 0 | 1 | 0 | 0 | 0 | 0 |
| uppercut_left | 0 | 0 | 0 | 0 | 1 | 0 | 0 |
| uppercut_right | 0 | 0 | 0 | 0 | 0 | 0 | 1 |
| no_punch | 1 | 0 | 0 | 1 | 0 | 0 | 7 |

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

- This is only a fixture-local same-harness directional comparison. Do not read it as real-world punch generalization.
- The current split policy still has same-clip leakage between train and test windows.
- Capture/window alignment can drift on recapture, so compare models fairly inside this committed export protocol.
