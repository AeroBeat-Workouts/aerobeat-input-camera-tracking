# Boxing Punch Classifier MLP Hardened Baseline — 2026-06-16

This artifact set records the first benchmark-hardening rerun around the existing tiny temporal MLP.

## What changed vs the first-pass baseline

- Train/test split changed from interleaved same-clip windows to `chronological_holdout_v1`.
- `no_punch` coverage expanded from 36 to 72 samples.
- Added explicit transition negatives around punch boundaries, not just background windows.
- Export now reports capture time-origin offsets and observed pose/window alignment error.

## Result change

- First-pass MLP test accuracy / macro F1: `0.867 / 0.887`
- Hardened-harness MLP test accuracy / macro F1: `0.655 / 0.210`
- Hardened-harness threshold test accuracy / macro F1: `0.621 / 0.259`

## Honest read

The benchmark got materially harder, and the current MLP got materially worse under that harder benchmark. That is useful truth, not a regression to hide.
