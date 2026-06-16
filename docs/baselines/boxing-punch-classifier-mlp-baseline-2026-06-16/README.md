# Boxing Punch Classifier MLP Baseline — 2026-06-16

This artifact set captures the first classifier-first feasibility push for AeroBeat boxing punches.

## Scope

- Shared reusable export/dataset/eval harness for boxing punch classification
- Tiny temporal MLP baseline over stacked per-frame pose features
- Threshold-gates comparison on the exact same exported windows
- Punch classes only for the classifier path: `straight_left`, `straight_right`, `hook_left`, `hook_right`, `uppercut_left`, `uppercut_right`, `no_punch`
- Non-punch boxing states such as guard/weave/squat/etc remain metadata and no-punch training windows, not primary classifier classes

## Commands used

```bash
python3 scripts/export_boxing_punch_classifier_dataset.py \
  --output-dir .temp/boxing-punch-classifier-export/run-2026-06-16 \
  --captures-dir .temp/boxing-punch-classifier-export/captures

python3 scripts/train_boxing_punch_mlp_baseline.py \
  --dataset .temp/boxing-punch-classifier-export/run-2026-06-16/dataset.json \
  --output-dir .temp/boxing-punch-classifier-export/run-2026-06-16/mlp \
  --hidden-dim 12 \
  --epochs 300 \
  --learning-rate 0.04 \
  --weight-decay 0.001
```

## Artifact map

- `dataset.json` — exact exported windows, labels, splits, per-window threshold predictions, and metadata
- `export-summary.json` / `export-summary.md` — export counts, fixture coverage, threshold baseline summary on exported windows
- `threshold-baseline.json` — raw threshold comparison payload and per-split metrics
- `mlp-result.json` / `mlp-result.md` — temporal MLP metrics, confusion matrices, and notes
- `mlp-model.json` — saved baseline weights plus standardization parameters

## Directional read

This baseline is useful as tooling proof and an early signal, not as a production-readiness claim. The split is intentionally tiny and clip-local, so the strongest truthful take is:

- the harness works end to end
- the tiny temporal MLP can separate these exported punch windows much better than the current threshold detector on this exact windowed comparison
- the data is still too small and too fixture-local to overclaim generalization
- the follow-up 1D temporal CNN can now use the exact same dataset/split/eval path
