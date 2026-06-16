# Boxing Punch Classifier 1D Temporal CNN Baseline — 2026-06-16

This artifact set captures the first same-harness temporal-CNN follow-up for AeroBeat boxing punches.

## Scope

- Reuses the exact committed export window set and deterministic split from `docs/baselines/boxing-punch-classifier-mlp-baseline-2026-06-16/dataset.json`
- Compares the first small 1D temporal CNN directly against:
  - the committed tiny temporal MLP baseline
  - the current threshold-gates behavior recorded on those same exported windows
- Keeps the claim narrow: fixture-local directional comparison only

## Commands used

```bash
python3 scripts/train_boxing_punch_temporal_cnn.py \
  --dataset docs/baselines/boxing-punch-classifier-mlp-baseline-2026-06-16/dataset.json \
  --mlp-result docs/baselines/boxing-punch-classifier-mlp-baseline-2026-06-16/mlp-result.json \
  --output-dir docs/baselines/boxing-punch-classifier-temporal-cnn-baseline-2026-06-16 \
  --conv1-channels 12 \
  --conv2-channels 8 \
  --kernel-size 5 \
  --epochs 1000 \
  --learning-rate 0.01 \
  --weight-decay 0.0
```

## Model shape

- `8x16 -> conv1d(16->12, k=5, same) -> relu -> conv1d(12->8, k=5, same) -> relu -> flatten(64) -> logits(7)`

## Artifact map

- `cnn-result.json` / `cnn-result.md` — temporal CNN metrics, confusion matrices, and direct comparison versus MLP + threshold baselines
- `cnn-model.json` — saved CNN weights plus standardization parameters

## Directional read

On the exact same committed exported-window protocol:

- Temporal CNN: **0.667 accuracy / 0.492 macro-F1**
- Temporal MLP: **0.867 accuracy / 0.887 macro-F1**
- Threshold baseline: **0.400 accuracy / 0.095 macro-F1**

Truthful takeaway:

- this first small CNN **does beat the threshold baseline** on the shared harness
- it **does not beat the tiny temporal MLP baseline** on this fixture-local split
- this pass should be read only as a same-harness directional comparison
- do **not** claim real-world punch generalization from this artifact set
- the current split still has same-clip leakage, and fresh recaptures can shift alignment enough to move results
