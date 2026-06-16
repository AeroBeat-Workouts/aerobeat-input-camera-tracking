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
- Optional frozen snapshot manifest: `.testbed/assets/benchmarks/boxing_punch_classifier_hardened_2026_06_16.snapshot.json`

## Export behavior

The exporter:

- replays committed boxing fixtures through the proving scene
- retains full pose timelines from capture reports
- extracts per-frame left+right punch features
- builds punch-class windows directly from verified YAML punch windows
- builds `no_punch` windows from both background non-punch intervals and explicit pre/post-punch transition windows
- keeps guard / weave / squat / sidestep / knee / stance-transition context as metadata instead of primary classifier labels
- assigns chronological holdout train/test splits so later models compare on a harder, less leaky seam than the original interleaved same-clip split
- records what the current threshold detector predicted on each exported window
- reports capture time-origin offsets plus observed pose/window alignment error so replay/capture drift is visible instead of implicit

## Scripts

Export dataset:

```bash
python3 scripts/export_boxing_punch_classifier_dataset.py \
  --output-dir .temp/boxing-punch-classifier-export/run-YYYY-MM-DD \
  --captures-dir .temp/boxing-punch-classifier-export/captures
```

Recreate the frozen hardened snapshot exactly from its archived capture-report package:

```bash
python3 scripts/export_boxing_punch_classifier_dataset.py \
  --snapshot-manifest .testbed/assets/benchmarks/boxing_punch_classifier_hardened_2026_06_16.snapshot.json \
  --skip-captures \
  --output-dir .temp/boxing-punch-classifier-export/boxing-punch-classifier-hardened-2026-06-16-rerun
```

Train the tiny temporal MLP baseline:

```bash
python3 scripts/train_boxing_punch_mlp_baseline.py \
  --dataset .temp/boxing-punch-classifier-export/run-YYYY-MM-DD/dataset.json \
  --output-dir .temp/boxing-punch-classifier-export/run-YYYY-MM-DD/mlp
```

Train the first tiny 1D temporal CNN comparison model:

```bash
python3 scripts/train_boxing_punch_temporal_cnn.py \
  --dataset docs/baselines/boxing-punch-classifier-mlp-baseline-2026-06-16/dataset.json \
  --mlp-result docs/baselines/boxing-punch-classifier-mlp-baseline-2026-06-16/mlp-result.json \
  --output-dir .temp/boxing-punch-classifier-export/run-YYYY-MM-DD/cnn
```

## Output contract

The export script writes:

- `dataset.json` — samples, labels, windows, chronological splits, metadata, threshold predictions, alignment fields, and frozen snapshot provenance when a snapshot manifest is supplied
- `export-summary.json` / `.md` — counts, fixture summary, no-punch context mix, alignment summary, and frozen snapshot provenance when applicable
- `threshold-baseline.json` — threshold comparison on exported windows

The MLP script writes:

- `mlp-result.json` / `.md` — metrics and confusion matrices
- `mlp-model.json` — saved baseline weights and standardization parameters

The CNN script writes:

- `cnn-result.json` / `.md` — metrics, confusion matrices, and direct comparison versus the MLP and threshold baselines
- `cnn-model.json` — saved CNN weights and standardization parameters

## Current artifact sets

- `docs/baselines/boxing-punch-classifier-mlp-baseline-2026-06-16/`
- `docs/baselines/boxing-punch-classifier-temporal-cnn-baseline-2026-06-16/`
- `docs/baselines/boxing-punch-classifier-mlp-hardened-baseline-2026-06-16/`

Those directories are the committed audit trail for the first feasibility push, the immediate same-harness CNN follow-up, and the first benchmark-hardening rerun around the MLP baseline.

The named reproducibility anchor for the hardened benchmark snapshot is:

- `.testbed/assets/benchmarks/boxing_punch_classifier_hardened_2026_06_16.snapshot.json`
- `.testbed/assets/benchmarks/boxing_punch_classifier_hardened_2026_06_16.snapshot.md`

That snapshot freezes the exact fixture/truth/capture/export inputs for the archived hardened dataset and tells future reruns which capture-report package and export settings they are expected to recreate.
