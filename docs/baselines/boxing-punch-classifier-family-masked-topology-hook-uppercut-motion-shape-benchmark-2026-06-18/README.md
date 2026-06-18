# Hook/uppercut motion-shape benchmark (2026-06-18)

This artifact set benchmarks a narrow harness-only follow-up for the weak `hook_uppercut_family_mask_v1` head.

## Goal

Keep the current hook/uppercut masked head as the control, then test whether compact elbow-relative motion-shape features help separate hook vs uppercut better than wrist direction alone.

## Matrix

- Control: `hook_uppercut_family_mask_v1`
- Variant A: control + forearm orbit bundle
- Variant B: Variant A + relative elbow-to-wrist trajectory bundle

## Source export

- Manifest: `.testbed/assets/benchmarks/boxing_punch_classifier_v1.benchmark.json`
- Capture reports: `.temp/boxing-punch-classifier-export/hardened-captures-2026-06-16/`
- Full feature export: `family_combined_directional_hook_motion_shape_v1/export/`

## Narrow-matrix rule used

- Export all 3 variants once
- Run MLP on all 3
- Run CNN on control and on the best new MLP variant only if that new variant improves hook/uppercut macro-F1 over the control MLP

In this pass, no new motion-shape MLP variant improved macro-F1 over the control MLP, so CNN remained control-only.

## Results

See:

- `summary.md`
- `summary.json`

Short version:

- Control MLP remained best on hook/uppercut macro-F1: **0.3159**
- Variant A matched the shared-vector subset baseline on accuracy (**0.8519**) but stayed slightly below it on macro-F1 (**0.1840** vs **0.1878**)
- Variant B regressed on both accuracy and macro-F1
- No motion-shape variant earned a CNN follow-up in this narrow first pass
