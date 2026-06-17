# Boxing Punch Classifier Frozen-Benchmark CNN Improvement Pass — 2026-06-16

This artifact set records a narrow follow-up pass on the current temporal CNN using the same frozen hardened boxing snapshot as the prior MLP-vs-CNN comparison.

## Scope

- Uses only the frozen snapshot manifest:
  - `.testbed/assets/benchmarks/boxing_punch_classifier_hardened_2026_06_16.snapshot.json`
- Keeps the export path frozen with `--skip-captures`
- Reuses one exported dataset for all CNN tuning attempts
- Stays narrow: targeted CNN architecture/hyperparameter tuning only

## Frozen export reproducibility check

The export matched the committed frozen snapshot hashes exactly:

- `dataset.json` sha256=`90af58361b4fac04571beb340806415434748a2401df9462d3f425637b1a88ba`
- `export-summary.json` sha256=`8abc20a46396609144f7aeaa3d83de785f9e8174bcaefd1681bbe2d82a625b6c`
- `threshold-baseline.json` sha256=`a89539077c750103eb406c67364fed1bdf9c44cbf1a378028af5debc7de5198a`

So this pass stayed on the exact same frozen benchmark slice.

## Commands run

```bash
python3 scripts/export_boxing_punch_classifier_dataset.py \
  --snapshot-manifest .testbed/assets/benchmarks/boxing_punch_classifier_hardened_2026_06_16.snapshot.json \
  --skip-captures \
  --output-dir .temp/boxing-punch-classifier-export/cnn-improvement-pass-2026-06-16/export

python3 scripts/train_boxing_punch_temporal_cnn.py \
  --dataset .temp/boxing-punch-classifier-export/cnn-improvement-pass-2026-06-16/export/dataset.json \
  --mlp-result docs/baselines/boxing-punch-classifier-frozen-benchmark-mlp-vs-cnn-2026-06-16/mlp/mlp-result.json \
  --output-dir .temp/single-cnn-run \
  --conv1-channels 12 \
  --conv2-channels 8 \
  --kernel-size 5 \
  --epochs 1000 \
  --learning-rate 0.01 \
  --weight-decay 0.0

python3 scripts/train_boxing_punch_temporal_cnn.py \
  --dataset .temp/boxing-punch-classifier-export/cnn-improvement-pass-2026-06-16/export/dataset.json \
  --mlp-result docs/baselines/boxing-punch-classifier-frozen-benchmark-mlp-vs-cnn-2026-06-16/mlp/mlp-result.json \
  --output-dir .temp/focused-cnn-sweep/wd_0005 \
  --conv1-channels 12 \
  --conv2-channels 8 \
  --kernel-size 5 \
  --epochs 1000 \
  --learning-rate 0.01 \
  --weight-decay 0.0005 \
  --seed 42

python3 scripts/train_boxing_punch_temporal_cnn.py \
  --dataset .temp/boxing-punch-classifier-export/cnn-improvement-pass-2026-06-16/export/dataset.json \
  --mlp-result docs/baselines/boxing-punch-classifier-frozen-benchmark-mlp-vs-cnn-2026-06-16/mlp/mlp-result.json \
  --output-dir .temp/focused-cnn-sweep/wider_16_12 \
  --conv1-channels 16 \
  --conv2-channels 12 \
  --kernel-size 5 \
  --epochs 1000 \
  --learning-rate 0.01 \
  --weight-decay 0.0005 \
  --seed 42

python3 scripts/train_boxing_punch_temporal_cnn.py \
  --dataset .temp/boxing-punch-classifier-export/cnn-improvement-pass-2026-06-16/export/dataset.json \
  --mlp-result docs/baselines/boxing-punch-classifier-frozen-benchmark-mlp-vs-cnn-2026-06-16/mlp/mlp-result.json \
  --output-dir .temp/focused-cnn-sweep/lower_lr \
  --conv1-channels 12 \
  --conv2-channels 8 \
  --kernel-size 5 \
  --epochs 1500 \
  --learning-rate 0.005 \
  --weight-decay 0.0005 \
  --seed 42

python3 scripts/train_boxing_punch_temporal_cnn.py \
  --dataset .temp/boxing-punch-classifier-export/cnn-improvement-pass-2026-06-16/export/dataset.json \
  --mlp-result docs/baselines/boxing-punch-classifier-frozen-benchmark-mlp-vs-cnn-2026-06-16/mlp/mlp-result.json \
  --output-dir .temp/focused-cnn-sweep/k3_wider \
  --conv1-channels 16 \
  --conv2-channels 12 \
  --kernel-size 3 \
  --epochs 1500 \
  --learning-rate 0.005 \
  --weight-decay 0.0005 \
  --seed 42

python3 scripts/train_boxing_punch_temporal_cnn.py \
  --dataset .temp/boxing-punch-classifier-export/cnn-improvement-pass-2026-06-16/export/dataset.json \
  --mlp-result docs/baselines/boxing-punch-classifier-frozen-benchmark-mlp-vs-cnn-2026-06-16/mlp/mlp-result.json \
  --output-dir .temp/focused-cnn-sweep/k7_wider \
  --conv1-channels 16 \
  --conv2-channels 12 \
  --kernel-size 7 \
  --epochs 1500 \
  --learning-rate 0.005 \
  --weight-decay 0.0005 \
  --seed 42

python3 scripts/train_boxing_punch_temporal_cnn.py \
  --dataset .temp/boxing-punch-classifier-export/cnn-improvement-pass-2026-06-16/export/dataset.json \
  --mlp-result docs/baselines/boxing-punch-classifier-frozen-benchmark-mlp-vs-cnn-2026-06-16/mlp/mlp-result.json \
  --output-dir .temp/focused-cnn-sweep-2/k3_nowd \
  --conv1-channels 16 \
  --conv2-channels 12 \
  --kernel-size 3 \
  --epochs 1500 \
  --learning-rate 0.005 \
  --weight-decay 0.0 \
  --seed 42

python3 scripts/train_boxing_punch_temporal_cnn.py \
  --dataset .temp/boxing-punch-classifier-export/cnn-improvement-pass-2026-06-16/export/dataset.json \
  --mlp-result docs/baselines/boxing-punch-classifier-frozen-benchmark-mlp-vs-cnn-2026-06-16/mlp/mlp-result.json \
  --output-dir .temp/focused-cnn-sweep-2/k3_seed7 \
  --conv1-channels 16 \
  --conv2-channels 12 \
  --kernel-size 3 \
  --epochs 1500 \
  --learning-rate 0.005 \
  --weight-decay 0.0005 \
  --seed 7

python3 scripts/train_boxing_punch_temporal_cnn.py \
  --dataset .temp/boxing-punch-classifier-export/cnn-improvement-pass-2026-06-16/export/dataset.json \
  --mlp-result docs/baselines/boxing-punch-classifier-frozen-benchmark-mlp-vs-cnn-2026-06-16/mlp/mlp-result.json \
  --output-dir .temp/focused-cnn-sweep-2/k3_seed99 \
  --conv1-channels 16 \
  --conv2-channels 12 \
  --kernel-size 3 \
  --epochs 1500 \
  --learning-rate 0.005 \
  --weight-decay 0.0005 \
  --seed 99

python3 scripts/train_boxing_punch_temporal_cnn.py \
  --dataset .temp/boxing-punch-classifier-export/cnn-improvement-pass-2026-06-16/export/dataset.json \
  --mlp-result docs/baselines/boxing-punch-classifier-frozen-benchmark-mlp-vs-cnn-2026-06-16/mlp/mlp-result.json \
  --output-dir .temp/focused-cnn-sweep-2/k3_ep1000_lr01 \
  --conv1-channels 16 \
  --conv2-channels 12 \
  --kernel-size 3 \
  --epochs 1000 \
  --learning-rate 0.01 \
  --weight-decay 0.0005 \
  --seed 42

python3 scripts/train_boxing_punch_temporal_cnn.py \
  --dataset .temp/boxing-punch-classifier-export/cnn-improvement-pass-2026-06-16/export/dataset.json \
  --mlp-result docs/baselines/boxing-punch-classifier-frozen-benchmark-mlp-vs-cnn-2026-06-16/mlp/mlp-result.json \
  --output-dir .temp/focused-cnn-sweep-2/k3_narrow \
  --conv1-channels 12 \
  --conv2-channels 8 \
  --kernel-size 3 \
  --epochs 1500 \
  --learning-rate 0.005 \
  --weight-decay 0.0005 \
  --seed 42
```

## Prior frozen benchmark reference

From the earlier frozen comparison:

- Prior CNN: **0.724 accuracy / 0.264 macro-F1**
- Frozen MLP: **0.655 accuracy / 0.210 macro-F1**
- Threshold baseline: **0.621 accuracy / 0.259 macro-F1**

## Focused tuning results

| config | shape | accuracy | macro-F1 | read |
| --- | --- | ---: | ---: | --- |
| prior CNN baseline | `8x16 -> conv1d(16->12, k=5) -> conv1d(12->8, k=5) -> flatten(64) -> logits(7)` | 0.724 | 0.264 | prior reference |
| `wd_0005` | `8x16 -> conv1d(16->12, k=5) -> conv1d(12->8, k=5) -> flatten(64) -> logits(7)` | 0.724 | 0.264 | identical to prior |
| `wider_16_12` | `8x16 -> conv1d(16->16, k=5) -> conv1d(16->12, k=5) -> flatten(96) -> logits(7)` | 0.724 | 0.217 | worse |
| `lower_lr` | `8x16 -> conv1d(16->12, k=5) -> conv1d(12->8, k=5) -> flatten(64) -> logits(7)` | 0.690 | 0.119 | much worse |
| `k3_wider` | `8x16 -> conv1d(16->16, k=3) -> conv1d(16->12, k=3) -> flatten(96) -> logits(7)` | 0.759 | 0.265 | best observed seed-42 run |
| `k7_wider` | `8x16 -> conv1d(16->16, k=7) -> conv1d(16->12, k=7) -> flatten(96) -> logits(7)` | 0.690 | 0.211 | worse |
| `k3_nowd` | `8x16 -> conv1d(16->16, k=3) -> conv1d(16->12, k=3) -> flatten(96) -> logits(7)` | 0.759 | 0.265 | same as `k3_wider` on seed 42 |
| `k3_seed7` | `8x16 -> conv1d(16->16, k=3) -> conv1d(16->12, k=3) -> flatten(96) -> logits(7)` | 0.724 | 0.122 | seed-sensitive drop |
| `k3_seed99` | `8x16 -> conv1d(16->16, k=3) -> conv1d(16->12, k=3) -> flatten(96) -> logits(7)` | 0.690 | 0.213 | seed-sensitive drop |
| `k3_ep1000_lr01` | `8x16 -> conv1d(16->16, k=3) -> conv1d(16->12, k=3) -> flatten(96) -> logits(7)` | 0.759 | 0.265 | same best observed metrics |
| `k3_narrow` | `8x16 -> conv1d(16->12, k=3) -> conv1d(12->8, k=3) -> flatten(64) -> logits(7)` | 0.724 | 0.264 | no gain |

## Best observed tuned CNN vs baselines

Best observed single run:

- Config: `conv1=16`, `conv2=12`, `kernel=3`, `epochs=1000`, `lr=0.01`, `weight_decay=0.0005`, `seed=42`
- Shape: `8x16 -> conv1d(16->16, k=3, same) -> relu -> conv1d(16->12, k=3, same) -> relu -> flatten(96) -> logits(7)`
- CNN accuracy: **0.759**
- CNN macro-F1: **0.265**
- MLP accuracy / macro-F1: **0.655 / 0.210**
- Threshold accuracy / macro-F1: **0.621 / 0.259**

Delta versus the prior frozen CNN:

- accuracy: **+0.035**
- macro-F1: **+0.001**

## Honest read

This pass did **not** meaningfully widen the CNN lead.

What happened:

- A narrower temporal kernel with a slightly wider channel stack produced the best observed single-run accuracy.
- But the macro-F1 lift was effectively flat: `0.264 -> 0.265`.
- The tuned shape was also seed-sensitive; alternate seeds dropped back to roughly prior-or-worse macro-F1.
- The best tuned run improved `no_punch` handling more than it improved broad per-class punch separability.

So the truthful takeaway is:

- the CNN still beats the frozen MLP on this frozen benchmark slice
- the targeted tuning pass found only a **tiny** macro-F1 change
- the CNN lead over threshold on macro-F1 is still extremely small
- this was not a strong enough result to overclaim a materially better learned baseline

## Recommendation for the next branch

Leave the prior frozen-CNN result as the stable reference point for now, treat the wider-`k=3` run as an exploratory note rather than a new default, and only promote a new CNN baseline after a change improves macro-F1 more clearly and survives seed variation.

## Artifact map

- `tuning-summary.json` — machine-readable summary of configs and deltas
- `best-cnn/cnn-result.json` — best observed tuned CNN result
- `best-cnn/cnn-model.json` — best observed tuned CNN weights
- `best-cnn/cnn-result.md` — markdown export from the trainer for the best observed run
