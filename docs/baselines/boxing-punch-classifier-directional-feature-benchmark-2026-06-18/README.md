# Boxing Punch Classifier Directional Feature Benchmark — 2026-06-18

This compares four feature schemas on the existing hardened capture reports without re-capturing fixtures.

- Capture reports: `.temp/boxing-punch-classifier-export/hardened-captures-2026-06-16/`
- Manifest: `.testbed/assets/benchmarks/boxing_punch_classifier_v1.benchmark.json`
- Threshold reference on the same exported windows: accuracy **0.655**, macro F1 **0.341**
- Important semantic split: camera-space left/right and body-space left/right are kept as separate feature families, not merged.

## Matrix

| Variant | Feature count / frame | MLP acc | MLP macro F1 | CNN acc | CNN macro F1 |
| --- | ---: | ---: | ---: | ---: | ---: |
| `baseline_v1` | 16 | 0.759 | 0.362 | 0.862 | 0.420 |
| `camera_directional_v1` | 30 | 0.690 | 0.355 | 0.759 | 0.362 |
| `body_directional_v1` | 30 | 0.690 | 0.355 | 0.690 | 0.358 |
| `combined_directional_v1` | 44 | 0.690 | 0.256 | 0.793 | 0.363 |

## Focused per-class test outcomes

Each focused positive class has exactly one held-out positive example in this hardened split, so this section is literally the held-out winner/loser list rather than a smoothed average.

### `baseline_v1`
- Shape: **16 features/frame** (baseline only (8/side, 16/frame))
- MLP focused predictions:
  - `hook_left` → `no_punch`
  - `hook_right` → `no_punch`
  - `uppercut_left` → `uppercut_right`
  - `uppercut_right` → `no_punch`
  - `straight_right` → `straight_right`
- CNN focused predictions:
  - `hook_left` → `no_punch`
  - `hook_right` → `no_punch`
  - `uppercut_left` → `no_punch`
  - `uppercut_right` → `hook_left`
  - `straight_right` → `straight_right`

### `camera_directional_v1`
- Shape: **30 features/frame** (baseline + camera directional bundle (15/side, 30/frame))
- MLP focused predictions:
  - `hook_left` → `no_punch`
  - `hook_right` → `no_punch`
  - `uppercut_left` → `uppercut_right`
  - `uppercut_right` → `no_punch`
  - `straight_right` → `straight_right`
- CNN focused predictions:
  - `hook_left` → `no_punch`
  - `hook_right` → `no_punch`
  - `uppercut_left` → `uppercut_left`
  - `uppercut_right` → `no_punch`
  - `straight_right` → `straight_right`

### `body_directional_v1`
- Shape: **30 features/frame** (baseline + body directional bundle (15/side, 30/frame))
- MLP focused predictions:
  - `hook_left` → `no_punch`
  - `hook_right` → `no_punch`
  - `uppercut_left` → `uppercut_right`
  - `uppercut_right` → `no_punch`
  - `straight_right` → `straight_right`
- CNN focused predictions:
  - `hook_left` → `straight_left`
  - `hook_right` → `no_punch`
  - `uppercut_left` → `uppercut_left`
  - `uppercut_right` → `no_punch`
  - `straight_right` → `straight_right`

### `combined_directional_v1`
- Shape: **44 features/frame** (baseline + camera + body bundles (22/side, 44/frame))
- MLP focused predictions:
  - `hook_left` → `no_punch`
  - `hook_right` → `no_punch`
  - `uppercut_left` → `uppercut_right`
  - `uppercut_right` → `uppercut_right`
  - `straight_right` → `straight_right`
- CNN focused predictions:
  - `hook_left` → `no_punch`
  - `hook_right` → `no_punch`
  - `uppercut_left` → `no_punch`
  - `uppercut_right` → `no_punch`
  - `straight_right` → `straight_right`

## Takeaways

- Best overall result in this slice is still the **baseline CNN** at accuracy **0.862** / macro F1 **0.420**.
- None of the directional feature variants fixed the held-out hook-left / hook-right failures in either model family.
- Camera/body directional features did help a little on **uppercut_left** for the CNN (`camera_directional_v1` and `body_directional_v1` both recovered that held-out sample), but that lift did not beat the baseline CNN overall.
- `combined_directional_v1` made the feature space widest (44/frame) and appears most overfit-prone here: the MLP macro F1 dropped to **0.256** while still failing both hook classes.

## Artifacts

- Each variant directory contains `export/`, `mlp/`, and `cnn/` subfolders with the full dataset + model artifacts.
