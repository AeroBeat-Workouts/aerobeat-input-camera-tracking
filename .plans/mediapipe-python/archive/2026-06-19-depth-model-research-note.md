# AeroBeat depth model research note

**Date:** 2026-06-19  
**Scope:** Confirm current hook/uppercut 2D threshold gate truth, then rank the top speed-first pretrained monocular depth candidates for wrist-depth trend detection.

## 1) Exact current hook / uppercut threshold gate truth

### Runtime coordinate truth
- The detector substrate consumes **gameplay landmarks with Y flipped into bottom-left gameplay space**, not preview-space top-left MediaPipe Y.
- Evidence:
  - `src/tracking_frame_adapter.gd:9-13` says preview overlays use top-left normalized Y, but the legacy detector consumes **bottom-left gameplay-normalized y**.
  - `src/tracking_frame_adapter.gd:23-24, 48-55` shows gameplay landmarks are created with `flip_y=true`, so detector-facing `y = 1.0 - raw_y`.
  - `src/providers/camera_tracking_provider.gd:251-255` shows `_process_primary_landmarks(...)` is fed `gameplay_landmarks`.

### Hook gate truth
- Hook threshold gating is currently:
  1. averaged motion-window speed must meet `min_velocity`
  2. wrist angle from an elbow-anchored **horizontal** ray must be within `max_wrist_angle_from_elbow_horizontal_deg`
  3. wrist must be on the required side of the elbow
- Exact code:
  - `src/detectors/pose_detector_substrate.gd:1490-1494`
  - required side helper at `src/detectors/pose_detector_substrate.gd:2375-2379`
- Side contract in code:
  - left hook: `wrist.x < elbow.x`
  - right hook: `wrist.x > elbow.x`
- Current threshold config values:
  - `assets/boxing.gesture_detection.yaml:134-142`
  - `window_ms: 250`, `min_velocity: 0.4`, `max_wrist_angle_from_elbow_horizontal_deg: 25.0`

### Uppercut gate truth
- Uppercut threshold gating is currently:
  1. averaged motion-window speed must meet `min_velocity`
  2. wrist angle from an elbow-anchored **vertical** ray must be within `max_wrist_angle_from_elbow_vertical_deg`
  3. wrist must pass the wrist-vs-elbow vertical gate
- Exact code:
  - `src/detectors/pose_detector_substrate.gd:1495-1499`
  - vertical helper at `src/detectors/pose_detector_substrate.gd:2381-2384`
- Exact predicate in code:
  - `wrist.y > elbow.y + 0.000001`
- Because the detector runs on flipped gameplay Y, that predicate really does mean **wrist above elbow in gameplay 2D space**, so Derrick's current uppercut 2D contract already matches the code path.
- Current threshold config values:
  - `assets/boxing.gesture_detection.yaml:199-209`
  - `window_ms: 250`, `min_velocity: 0.5`, `max_wrist_angle_from_elbow_vertical_deg: 25.0`

### Important runtime caveat
- Hook and uppercut both currently declare `backend: disabled` in the shipped boxing gesture profile:
  - `assets/boxing.gesture_detection.yaml:127-130`
  - `assets/boxing.gesture_detection.yaml:194-197`
- The threshold gate code above is still the exact contract **when those families are routed to `threshold`**, but the present boxing YAML does not currently enable those families.

## 2) Top 3 monocular depth candidates for this use case

### Rank 1 — MiDaS v2.1 Small 256 / OpenVINO small path
**Why it ranks #1 for AeroBeat:** best overall balance of speed, pretrained availability, and practical Intel-laptop deployment.

- Why:
  - official small pretrained model
  - official OpenVINO path for Intel CPU inference
  - official live-camera path already documented
  - official README includes a test configuration on **11th Gen Intel Core i7-1185G7** with `openvino_midas_v21_small_256` at **22 FPS**, which is highly relevant to Surface Pro 8 class hardware
- Source notes:
  - MiDaS README recommends embedded-device variants and the OpenVINO small legacy model
  - the README also lists `midas_v21_small_256` at 256 inference height and an OpenVINO version
- Why not #2 or #3:
  - not the absolute lightest raw architecture
  - weaker depth quality than larger modern models
  - still dense per-pixel inference, so it is heavier than a pose-only feature path
- Recommendation for this repo:
  - if one model gets tried first for real integration on low-end Intel hardware, this is the safest first bet

### Rank 2 — FastDepth (224x224 ONNX-style path)
**Why it ranks #2:** probably the best raw-speed candidate, but less attractive than MiDaS-small for current practical deployment confidence.

- Why:
  - explicitly designed for embedded real-time depth
  - MIT reports **178 FPS on Jetson TX2 GPU** and **27 FPS on TX2 CPU**
  - very small compute footprint: **0.37 GMACs at 224x224**
  - prior AeroBeat research already identified it as the strongest pure speed argument
- Why it is not #1:
  - older and coarser
  - weaker confidence that wrist-local rapid-punch depth is stable enough for boxing decisions
  - fewer repo-adjacent signs of clean Intel CPU deployment than MiDaS + OpenVINO
- Best use if chosen:
  - the "can we get any useful wrist-depth trend at all with minimal cost?" experiment
  - especially if the model is only used as a low-res auxiliary signal and not as the main punch classifier

### Rank 3 — Depth Anything V2 Small
**Why it ranks #3:** best robustness / detail option in this shortlist, but the least speed-efficient for the stated goal.

- Why:
  - much more modern and generally more robust than old lightweight depth models
  - easy pretrained access through official checkpoints / Transformers / Core ML ecosystem
  - likely the strongest candidate if the first two models are too noisy around the wrist/forearm boundary
- Why it ranks below the others:
  - **24.8M parameters** even for the Small model
  - default inference is built around a much heavier setup than 224-256 lightweight legacy models
  - overkill if the only product question is "did the wrist move materially closer during this punch window?"
- Best use if chosen:
  - fallback experiment only if MiDaS-small and FastDepth both fail on stability, and only with aggressive downscaling / accelerator help

## 3) Why this ranking fits AeroBeat specifically

This is not a generic "best depth model" ranking. It is ranked for:
- **speed first**
- **relative wrist depth trend**, not photorealistic depth maps
- **low-end Intel tablet/laptop hardware** like Surface Pro 8
- **practical repo integration**, not benchmark bragging rights

That pushes the ranking toward:
1. Intel-friendly small pretrained models with existing deployment paths
2. then ultra-light legacy speed monsters
3. then heavier but more robust modern models

## 4) Recommended wrist-depth signal formulation

Treat depth as an **auxiliary temporal feature**, not as a standalone punch detector.

### Per-frame signal
For each side and each frame in the punch window:
1. run monocular depth on a small input size (224-256 class)
2. sample a small wrist-centered ROI, optionally expanded toward the forearm using the wrist→elbow vector
3. sample a torso reference ROI from chest / shoulder-center space
4. compute a **relative wrist closeness score**:
   - `wrist_closeness_t = torso_depth_t - wrist_depth_t` after choosing the sign convention so **larger means wrist is closer to camera**
5. smooth with a short EMA or 3-frame median

### Window feature
For each detection window, compute:
- `early_closeness = median(first 30-40% of window)`
- `late_closeness = median(last 30-40% of window)`
- `closeness_delta = late_closeness - early_closeness`

### Family expectation
- **straight punch:** `closeness_delta` should be clearly positive
- **hook:** `closeness_delta` should stay near zero or modest
- **uppercut:** `closeness_delta` should also stay near zero or modest

### Practical decision form
Use depth only after the existing 2D family candidate is already plausible.

Recommended pattern:
- straight candidate gets a **positive depth confirm**: `closeness_delta >= min_straight_depth_delta`
- hook / uppercut candidates get a **depth non-forward veto**: `closeness_delta <= max_non_straight_depth_delta`

That matches the requested product behavior better than using raw instantaneous depth.

## 5) Surface Pro 8 class constraints / risks

- **CPU-only risk is real.** Dense depth every frame can steal too much frame budget from MediaPipe / camera tracking / gameplay.
- **Thermal throttling risk.** A tablet-class Intel device may look fine for a short run, then sag after a few minutes.
- **Relative depth only.** These models do not give trustworthy metric wrist distance; they only give a scene-relative depth ordering / trend.
- **Wrist ROI is tiny.** The hand can occupy very few pixels during guard or fast motion, especially at laptop-camera distances.
- **Motion blur + self-occlusion.** Straights can smear into torso overlap; hooks and uppercuts can fold forearm and glove regions into ambiguous shapes.
- **Resolution tradeoff.** 224-256 input is good for speed but reduces wrist-local fidelity.
- **Pipeline complexity.** This repo currently has no existing ONNX/OpenVINO/torch inference path, so any depth branch adds packaging, runtime, and validation overhead.

## 6) Existing YAML comment/style inspection

### Style traits observed in shipped config files
From `assets/boxing.gesture_detection.yaml`, `assets/boxing.camera_tracking.yaml`, and `assets/boxing.testbed_debug.yaml`:

- comments are **full-sentence, imperative/explanatory**, usually one line per field
- comments sit **directly above** the field they describe
- comments often describe:
  - what the variable means
  - when it applies
  - whether it is input / tool / vendor / debug facing
- nested sections are stable and semantic, e.g.:
  - `evaluation:` for windowing / sampling behavior
  - `thresholds:` for numeric gates
  - `timing:` for post-trigger timing
  - `rearm:` for rearm logic
  - `state_machine:` for reacquire / state transitions
  - `debug:` for proving-scene / inspector visibility
- option enums are documented inline like:
  - `# [disabled, threshold, prototype, classifier] Pick which backend owns ...`
- explanatory mini-bullets are used only when a threshold needs interpretation, e.g. angle docs in hook / uppercut config
- the repo prefers **plain descriptive names** over short abbreviations

### Implication for new depth config
The cleanest fit is to add a new nested section under each threshold-backed punch family instead of inventing a separate top-level document. That keeps the contract close to the existing per-family threshold config and preserves the repo's current comment grammar.

## 7) Proposed depth-related YAML schema

### Recommended placement
Add this block under:
- `straight_punch.threshold`
- `hook.threshold`
- `uppercut.threshold`

Recommended new section name:
- `depth:`

Recommended subsection names:
- `evaluation:` for ROI/window shaping
- `thresholds:` for family-specific depth gates
- `debug:` for proving/debug visibility

### Exact proposed schema text

```yaml
straight_punch:
  backend: threshold
  threshold:
    evaluation:
      fresh_samples_only: true
      sample_window_size: 4
      min_positive_growth_samples: 1
      window_ms: 250
    thresholds:
      min_velocity: 0.5
      min_bbox_area_growth: 0.003
      max_elbow_shoulder_xy_distance: 0.140
      min_wrist_lateral_angle_from_elbow_vertical_deg: 15.0
    depth:
      # Turn straight-punch depth trend checks on or off inside the threshold runtime. input.
      enabled: false
      evaluation:
        # Run monocular depth inference at this square input size when depth is enabled. input -> tool.
        model_input_size: 256
        # Sample this many wrist-centered depth pixels on each side of the wrist ROI center. input -> tool.
        wrist_roi_radius_px: 12
        # Extend the wrist ROI this far toward the elbow direction to stabilize forearm-adjacent depth reads. input -> tool.
        wrist_to_elbow_extension_px: 8
        # Sample this many torso-centered depth pixels on each side of the torso ROI center for the body reference depth. input -> tool.
        torso_roi_radius_px: 18
        # Smooth the per-frame wrist-vs-torso depth signal across this many recent frames before window scoring. input -> tool.
        smoothing_window_samples: 3
        # Use this much of the window from the front as the early depth baseline slice. input -> tool.
        early_window_fraction: 0.35
        # Use this much of the window from the back as the late depth comparison slice. input -> tool.
        late_window_fraction: 0.35
      thresholds:
        # Straight punches must increase wrist closeness by at least this much from the early slice to the late slice. input.
        min_closeness_delta: 0.06
        # Straight punches must reach at least this peak wrist closeness during the window relative to the torso reference. input.
        min_peak_closeness: 0.04
      debug:
        # Show the live wrist depth, torso depth, and closeness values in proving/debug views. input presentation.
        show_depth_signal: true
        # Show the early/late window depth slices and closeness delta in proving/debug views. input presentation.
        show_depth_window_analysis: true

hook:
  backend: disabled
  threshold:
    evaluation:
      window_ms: 250
    thresholds:
      min_velocity: 0.4
      max_wrist_angle_from_elbow_horizontal_deg: 25.0
    depth:
      # Turn hook depth trend checks on or off inside the threshold runtime. input.
      enabled: false
      evaluation:
        # Run monocular depth inference at this square input size when depth is enabled. input -> tool.
        model_input_size: 256
        # Sample this many wrist-centered depth pixels on each side of the wrist ROI center. input -> tool.
        wrist_roi_radius_px: 12
        # Extend the wrist ROI this far toward the elbow direction to stabilize forearm-adjacent depth reads. input -> tool.
        wrist_to_elbow_extension_px: 8
        # Sample this many torso-centered depth pixels on each side of the torso ROI center for the body reference depth. input -> tool.
        torso_roi_radius_px: 18
        # Smooth the per-frame wrist-vs-torso depth signal across this many recent frames before window scoring. input -> tool.
        smoothing_window_samples: 3
        # Use this much of the window from the front as the early depth baseline slice. input -> tool.
        early_window_fraction: 0.35
        # Use this much of the window from the back as the late depth comparison slice. input -> tool.
        late_window_fraction: 0.35
      thresholds:
        # Hooks must keep wrist closeness growth at or below this value so strong forward straights do not pass as hooks. input.
        max_closeness_delta: 0.03
        # Hooks must keep peak wrist closeness at or below this value so they remain mostly lateral in depth. input.
        max_peak_closeness: 0.06
      debug:
        # Show the live wrist depth, torso depth, and closeness values in proving/debug views. input presentation.
        show_depth_signal: true
        # Show the early/late window depth slices and closeness delta in proving/debug views. input presentation.
        show_depth_window_analysis: true

uppercut:
  backend: disabled
  threshold:
    evaluation:
      window_ms: 250
    thresholds:
      min_velocity: 0.5
      max_wrist_angle_from_elbow_vertical_deg: 25.0
    depth:
      # Turn uppercut depth trend checks on or off inside the threshold runtime. input.
      enabled: false
      evaluation:
        # Run monocular depth inference at this square input size when depth is enabled. input -> tool.
        model_input_size: 256
        # Sample this many wrist-centered depth pixels on each side of the wrist ROI center. input -> tool.
        wrist_roi_radius_px: 12
        # Extend the wrist ROI this far toward the elbow direction to stabilize forearm-adjacent depth reads. input -> tool.
        wrist_to_elbow_extension_px: 8
        # Sample this many torso-centered depth pixels on each side of the torso ROI center for the body reference depth. input -> tool.
        torso_roi_radius_px: 18
        # Smooth the per-frame wrist-vs-torso depth signal across this many recent frames before window scoring. input -> tool.
        smoothing_window_samples: 3
        # Use this much of the window from the front as the early depth baseline slice. input -> tool.
        early_window_fraction: 0.35
        # Use this much of the window from the back as the late depth comparison slice. input -> tool.
        late_window_fraction: 0.35
      thresholds:
        # Uppercuts must keep wrist closeness growth at or below this value so strong forward straights do not pass as uppercuts. input.
        max_closeness_delta: 0.03
        # Uppercuts must keep peak wrist closeness at or below this value so they remain mostly vertical in camera space rather than strongly forward in depth. input.
        max_peak_closeness: 0.06
      debug:
        # Show the live wrist depth, torso depth, and closeness values in proving/debug views. input presentation.
        show_depth_signal: true
        # Show the early/late window depth slices and closeness delta in proving/debug views. input presentation.
        show_depth_window_analysis: true
```

### Why this schema shape fits the repo
- keeps depth near the existing threshold backend that would consume it
- matches existing `evaluation` / `thresholds` / `debug` nesting
- keeps family-specific tuning explicit instead of hiding it in a shared global block
- lets Derrick enable depth per family without changing backend ownership semantics

## 8) Variable-to-behavior mapping

### Shared derived signal
The proposed config assumes one normalized derived signal per frame:
- `closeness = torso_depth - wrist_depth`
- choose implementation sign so **larger closeness means wrist is closer to camera than torso baseline**

Then derive, per detection window:
- `early_closeness`
- `late_closeness`
- `closeness_delta = late_closeness - early_closeness`
- `peak_closeness`

### Straight punch mapping
Use:
- `straight_punch.threshold.depth.thresholds.min_closeness_delta`
- `straight_punch.threshold.depth.thresholds.min_peak_closeness`

Meaning:
- the wrist must get materially closer over the window
- and it should reach a meaningful forward peak at some point during the punch

Product behavior target:
- real straights pass more often
- lateral-only arm motion is less likely to pass as straight

### Hook mapping
Use:
- `hook.threshold.depth.thresholds.max_closeness_delta`
- `hook.threshold.depth.thresholds.max_peak_closeness`

Meaning:
- hook windows should not show a strong forward wrist advance
- if the wrist surges toward camera like a straight, fail or down-rank the hook candidate

Product behavior target:
- keep hooks mostly lateral in depth
- reduce straight-vs-hook confusion when 2D XY alone is ambiguous

### Uppercut mapping
Use:
- `uppercut.threshold.depth.thresholds.max_closeness_delta`
- `uppercut.threshold.depth.thresholds.max_peak_closeness`

Meaning:
- uppercuts can move vertically fast in 2D but should not look strongly forward like a straight
- depth acts as a non-forward check, not as the primary uppercut trigger

Product behavior target:
- preserve the existing uppercut 2D contract
- stop very forward punches from being mistaken for uppercuts when the arm shape momentarily looks vertical-ish

## 9) Recommended defaults and contract notes

Recommended first-pass defaults:
- `enabled: false` everywhere until runtime validation exists
- `model_input_size: 256` as the likely best first Surface Pro 8 class compromise
- identical ROI/smoothing defaults across families for simplicity
- family-specific thresholds only for the actual pass/fail semantics

Important contract note:
- these values should be treated as **config-contract placeholders for the first implementation seam**, not claimed-tuned production truth
- the names and comment style look repo-native already; the numeric defaults still need empirical tuning after implementation

## 10) Recommendation

If AeroBeat experiments with monocular depth at all, the best first try is:
1. **MiDaS v2.1 Small 256 / OpenVINO small path** for the first practical Surface Pro 8 test
2. **FastDepth** as the fastest backup experiment if MiDaS is still too heavy
3. **Depth Anything V2 Small** only if the lightweight options are too unstable to be useful

And the model should only be used to produce a **wrist depth trend over time** that helps separate:
- straights = wrist gets closer
- hooks / uppercuts = wrist does not get much closer

Not as a replacement for the existing 2D threshold logic.