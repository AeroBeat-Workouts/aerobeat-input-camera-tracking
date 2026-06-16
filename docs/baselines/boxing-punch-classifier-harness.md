# Boxing Punch Classifier Harness

This repo now has a reusable export/dataset/eval harness for classifier-style boxing punch experiments.

## Why it exists

The boxing branch is moving toward a hybrid architecture:

- pose/threshold logic keeps owning non-punch boxing state like guard
- classifier experiments focus on punch recognition only

The harness is intentionally model-agnostic so the first temporal-MLP baseline and the immediate follow-up 1D temporal CNN can compare on the exact same exported windows and splits.

## Inputs

- Manifest: `.testbed/assets/benchmarks/boxing_punch_classifier_v1.benchmark.json`
- Fixture YAML truth windows + videos under `.testbed/assets/fixtures/boxing/`
- Headless proving capture path via `res://scripts/capture_fixture_proving.gd`

## Export behavior

The exporter:

- replays committed boxing fixtures through the proving scene
- retains full pose timelines from capture reports
- extracts per-frame left+right punch features
- builds punch-class windows directly from verified YAML punch windows
- builds `no_punch` windows from non-punch intervals in the same fixtures
- keeps guard / weave / squat / sidestep / knee / stance-transition context as metadata instead of primary classifier labels
- assigns deterministic train/test splits so later models can compare fairly
- records what the current threshold detector predicted on each exported window

## Scripts

Export dataset:

```bash
python3 scripts/export_boxing_punch_classifier_dataset.py \
  --output-dir .temp/boxing-punch-classifier-export/run-YYYY-MM-DD \
  --captures-dir .temp/boxing-punch-classifier-export/captures
```

Train the tiny temporal MLP baseline:

```bash
python3 scripts/train_boxing_punch_mlp_baseline.py \
  --dataset .temp/boxing-punch-classifier-export/run-YYYY-MM-DD/dataset.json \
  --output-dir .temp/boxing-punch-classifier-export/run-YYYY-MM-DD/mlp
```

## Output contract

The export script writes:

- `dataset.json` — samples, labels, windows, splits, metadata, threshold predictions
- `export-summary.json` / `.md` — counts and fixture summary
- `threshold-baseline.json` — threshold comparison on exported windows

The MLP script writes:

- `mlp-result.json` / `.md` — metrics and confusion matrices
- `mlp-model.json` — saved baseline weights and standardization parameters

## Current first-pass artifact set

- `docs/baselines/boxing-punch-classifier-mlp-baseline-2026-06-16/`

That directory is the committed audit trail for the first feasibility push.
