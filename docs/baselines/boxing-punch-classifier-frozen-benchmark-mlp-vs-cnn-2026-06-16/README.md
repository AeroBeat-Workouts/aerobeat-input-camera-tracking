# Boxing Punch Classifier Frozen-Benchmark MLP vs CNN — 2026-06-16

This artifact set re-runs the current tiny temporal MLP and the current temporal CNN on the reproducible frozen hardened benchmark snapshot.

## Scope

- Uses only the frozen snapshot manifest:
  - `.testbed/assets/benchmarks/boxing_punch_classifier_hardened_2026_06_16.snapshot.json`
- Keeps the export path frozen with `--skip-captures`
- Reuses one exported dataset for both models so the comparison is apples-to-apples
- Stays narrow: this is a frozen-benchmark comparison, not a fresh live-capture claim and not a production-generalization claim

## Commands used

```bash
python3 scripts/export_boxing_punch_classifier_dataset.py \
  --snapshot-manifest .testbed/assets/benchmarks/boxing_punch_classifier_hardened_2026_06_16.snapshot.json \
  --skip-captures \
  --output-dir .temp/boxing-punch-classifier-export/frozen-mlp-vs-cnn-2026-06-16/export

python3 scripts/train_boxing_punch_mlp_baseline.py \
  --dataset .temp/boxing-punch-classifier-export/frozen-mlp-vs-cnn-2026-06-16/export/dataset.json \
  --output-dir docs/baselines/boxing-punch-classifier-frozen-benchmark-mlp-vs-cnn-2026-06-16/mlp \
  --hidden-dim 24 \
  --epochs 450 \
  --learning-rate 0.045 \
  --weight-decay 0.0005

python3 scripts/train_boxing_punch_temporal_cnn.py \
  --dataset .temp/boxing-punch-classifier-export/frozen-mlp-vs-cnn-2026-06-16/export/dataset.json \
  --mlp-result docs/baselines/boxing-punch-classifier-frozen-benchmark-mlp-vs-cnn-2026-06-16/mlp/mlp-result.json \
  --output-dir docs/baselines/boxing-punch-classifier-frozen-benchmark-mlp-vs-cnn-2026-06-16/cnn \
  --conv1-channels 12 \
  --conv2-channels 8 \
  --kernel-size 5 \
  --epochs 1000 \
  --learning-rate 0.01 \
  --weight-decay 0.0
```

## Frozen export reproducibility check

The rerun export matched the frozen snapshot hashes exactly:

- `dataset.json` sha256=`90af58361b4fac04571beb340806415434748a2401df9462d3f425637b1a88ba`
- `export-summary.json` sha256=`8abc20a46396609144f7aeaa3d83de785f9e8174bcaefd1681bbe2d82a625b6c`
- `threshold-baseline.json` sha256=`a89539077c750103eb406c67364fed1bdf9c44cbf1a378028af5debc7de5198a`

That means this comparison really did run on the frozen benchmark slice, not a shifted recapture/export.

## Model shapes

- MLP: `8x16 -> flatten(128) -> hidden(24) -> logits(7)`
- CNN: `8x16 -> conv1d(16->12, k=5, same) -> relu -> conv1d(12->8, k=5, same) -> relu -> flatten(64) -> logits(7)`

## Test results on the frozen benchmark

- Temporal MLP: **0.655 accuracy / 0.210 macro-F1**
- Temporal CNN: **0.724 accuracy / 0.264 macro-F1**
- Threshold baseline: **0.621 accuracy / 0.259 macro-F1**

## Honest read

The earlier relationship changed on the hardened frozen benchmark.

- On the earlier first-pass same-harness baseline, the MLP beat the CNN.
- On this frozen hardened benchmark rerun, the CNN now beats the MLP.
- The CNN edge is modest, but it is real on this frozen slice:
  - accuracy: `0.724 > 0.655`
  - macro-F1: `0.264 > 0.210`
- The threshold baseline still remains close in macro-F1 (`0.259`), so none of these numbers justify overclaiming classifier maturity.

The practical takeaway is not “CNN solved it.” The truthful takeaway is:

- the hardened benchmark changed the ranking versus the earlier first-pass comparison
- the current small CNN is now the better of the two learned models on this frozen reproducible slice
- the result is still fixture-local and small, so the next step should be targeted improvement and verification, not broad generalization claims

## Artifact map

- `mlp/mlp-result.json` / `mlp/mlp-result.md` — frozen-benchmark MLP metrics and confusion matrix
- `mlp/mlp-model.json` — frozen-benchmark MLP weights and standardization parameters
- `cnn/cnn-result.json` / `cnn/cnn-result.md` — frozen-benchmark CNN metrics and direct comparison versus MLP + threshold
- `cnn/cnn-model.json` — frozen-benchmark CNN weights and standardization parameters
