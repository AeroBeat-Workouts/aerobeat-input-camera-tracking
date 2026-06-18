# Boxing Punch Classifier Family-Specific Feature Benchmark — 2026-06-18

This compares family-specific learned-classifier feature schemas on the same hardened capture-report package used by the prior directional benchmark.

- Capture reports: `.temp/boxing-punch-classifier-export/hardened-captures-2026-06-16/`
- Manifest: `.testbed/assets/benchmarks/boxing_punch_classifier_v1.benchmark.json`
- Prior directional reference: `docs/baselines/boxing-punch-classifier-directional-feature-benchmark-2026-06-18/summary.json`
- Frozen snapshot note: the stricter `boxing_punch_classifier_hardened_2026_06_16.snapshot.json` path is currently blocked by fixture-YAML hash drift on `straight_right`, so this rerun uses the same hardened capture-report package as the prior directional branch rather than claiming full frozen-snapshot reproduction.

## Family-specific bundles

Per side, the new family branch adds:

- Straight bundle: `elbow_x_from_shoulder_over_shoulder_width`, `elbow_y_from_shoulder_over_shoulder_width`, `elbow_shoulder_radial_velocity_over_shoulder_width`
- Hook/uppercut camera-space bundle: wrist-only signed velocity + coarse direction buckets in camera space
- Hook/uppercut body-space bundle: wrist-only signed velocity + coarse direction buckets in athlete/body lateral space

The straight velocity cue is intentionally **radial**: it is the elbow velocity projected onto the shoulder→elbow axis, normalized by shoulder width. That keeps the implementation explicit about elbow↔shoulder extension speed instead of pretending it is just a generic wrist-direction signal.

## Matrix

| Variant | Feature count / frame | MLP acc | MLP macro F1 | CNN acc | CNN macro F1 |
| --- | ---: | ---: | ---: | ---: | ---: |
| `baseline_v1` | 16 | 0.759 | 0.362 | 0.862 | 0.420 |
| `camera_directional_v1` | 30 | 0.690 | 0.355 | 0.759 | 0.362 |
| `body_directional_v1` | 30 | 0.690 | 0.355 | 0.690 | 0.358 |
| `combined_directional_v1` | 44 | 0.690 | 0.256 | 0.793 | 0.363 |
| `family_camera_directional_v1` | 36 | 0.793 | 0.366 | 0.793 | 0.126 |
| `family_body_directional_v1` | 36 | 0.690 | 0.307 | 0.793 | 0.269 |
| `family_combined_directional_v1` | 50 | 0.793 | 0.363 | 0.828 | 0.272 |

## Focused per-class test outcomes

Each positive class still has exactly one held-out positive example in this tiny hardened split, so this section is a literal held-out winner/loser list, not a smoothed estimate.

### `baseline_v1`
- Shape: **16 features/frame** (baseline only (8/side, 16/frame))
- MLP focused predictions:
  - `straight_left` → `straight_left`
  - `straight_right` → `straight_right`
  - `hook_left` → `no_punch`
  - `hook_right` → `no_punch`
  - `uppercut_left` → `uppercut_right`
  - `uppercut_right` → `no_punch`
- CNN focused predictions:
  - `straight_left` → `straight_left`
  - `straight_right` → `straight_right`
  - `hook_left` → `no_punch`
  - `hook_right` → `no_punch`
  - `uppercut_left` → `no_punch`
  - `uppercut_right` → `hook_left`

### `family_camera_directional_v1`
- Shape: **36 features/frame** (baseline + straight elbow bundle + camera-space wrist directional bundle (18/side, 36/frame))
- MLP focused predictions:
  - `straight_left` → `straight_left`
  - `straight_right` → `straight_right`
  - `hook_left` → `no_punch`
  - `hook_right` → `no_punch`
  - `uppercut_left` → `uppercut_right`
  - `uppercut_right` → `no_punch`
- CNN focused predictions:
  - `straight_left` → `no_punch`
  - `straight_right` → `no_punch`
  - `hook_left` → `no_punch`
  - `hook_right` → `no_punch`
  - `uppercut_left` → `no_punch`
  - `uppercut_right` → `no_punch`

### `family_body_directional_v1`
- Shape: **36 features/frame** (baseline + straight elbow bundle + body-space wrist directional bundle (18/side, 36/frame))
- MLP focused predictions:
  - `straight_left` → `straight_left`
  - `straight_right` → `straight_right`
  - `hook_left` → `no_punch`
  - `hook_right` → `no_punch`
  - `uppercut_left` → `uppercut_right`
  - `uppercut_right` → `no_punch`
- CNN focused predictions:
  - `straight_left` → `no_punch`
  - `straight_right` → `straight_right`
  - `hook_left` → `no_punch`
  - `hook_right` → `no_punch`
  - `uppercut_left` → `no_punch`
  - `uppercut_right` → `no_punch`

### `family_combined_directional_v1`
- Shape: **50 features/frame** (baseline + straight elbow bundle + camera + body wrist directional bundles (25/side, 50/frame))
- MLP focused predictions:
  - `straight_left` → `straight_left`
  - `straight_right` → `straight_right`
  - `hook_left` → `no_punch`
  - `hook_right` → `no_punch`
  - `uppercut_left` → `no_punch`
  - `uppercut_right` → `no_punch`
- CNN focused predictions:
  - `straight_left` → `no_punch`
  - `straight_right` → `no_punch`
  - `hook_left` → `no_punch`
  - `hook_right` → `hook_right`
  - `uppercut_left` → `no_punch`
  - `uppercut_right` → `no_punch`

## Takeaways

- Best overall result is still the **baseline CNN** at accuracy **0.862** / macro F1 **0.420**.
- None of the family-specific variants beat the baseline CNN overall, and none beat the prior directional CNN variants either. Best family CNN was `family_combined_directional_v1` at **0.828** / **0.272**, still below prior `combined_directional_v1` CNN macro F1 **0.363** and below prior `camera_directional_v1` CNN macro F1 **0.362**.
- The family split did help the **MLP** a little versus the prior directional branch: `family_camera_directional_v1` reached **0.793** / **0.366**, beating prior `camera_directional_v1` MLP **0.690** / **0.355** and prior `body_directional_v1` MLP **0.690** / **0.355**, but that lift was not enough to matter more than the CNN regressions.
- Hook-left remains unsolved across every family-specific variant in both model families.
- The only new CNN positive-class recovery in this branch was `hook_right` under `family_combined_directional_v1`, but it came with both straight classes collapsing to `no_punch`, so it is not a promotion-worthy trade.
- The straight elbow bundle did **not** preserve the prior baseline CNN straight performance once paired with the wrist-direction family bundles; the camera/body family CNN variants became overly `no_punch`-heavy on held-out positives.

## Artifacts

- Each variant directory contains `export/`, `mlp/`, and `cnn/` subfolders with full dataset + model artifacts.
