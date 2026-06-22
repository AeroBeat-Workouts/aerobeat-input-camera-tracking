# AeroBeat generalize depth debug viewer

**Date:** 2026-06-21  
**Status:** Complete  
**Last Updated:** 2026-06-21 20:31 EDT  
**Blocked Reason:** None  
**Agent:** `pico`

---

## Goal

Extract the proving-scene depth texture debugger into a reusable depth debug viewer/control so future assembly-side adoption can reuse the runtime texture plumbing without re-implementing the UI from scratch.

---

## Overview

The current work split is now clear: the runtime depth-texture exposure is reusable core capability, while the thumbnail/swap/FPS/sample-overlay UX is still proving-scene-specific. Derrick wants the viewer generalized so future assembly builds can adopt it more easily.

The safest path is to separate reusable UI behavior from boxing-proving-specific orchestration. That likely means introducing a generic depth debug viewer control/script with explicit inputs for RGB preview texture, optional depth texture, sample geometry metadata, timing/FPS/debug strings, and toggle/config state. The boxing proving harness would then become one consumer of that viewer instead of owning all the rendering/swap logic directly.

This should reduce duplication and make future assembly integration cheaper, but only if the extracted component stays honest about what data it requires and what remains optional. The viewer must still behave truthfully when depth textures are unavailable, when only point-sample geometry exists, or when swap is disabled. It also needs to avoid baking boxing-only assumptions into the generic control.

---

## REFERENCES

| ID | Description | Path |
| --- | --- | --- |
| `REF-01` | Depth texture proving plan | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.plans/mediapipe-python/2026-06-21-expose-depth-map-texture-in-proving.md` |
| `REF-02` | Boxing proving harness | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.testbed/scripts/boxing_proving_harness.gd` |
| `REF-03` | Proving harness base script | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.testbed/scripts/proving_harness.gd` |
| `REF-04` | Depth sample debug overlay | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.testbed/scripts/depth_sample_debug_overlay.gd` |
| `REF-05` | Proving harness tests | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.testbed/tests/unit/test_boxing_proving_harness_profiles_and_debug.gd` |
| `REF-06` | Boxing proving YAML | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/assets/boxing.testbed_debug.yaml` |

---

## Tasks

### Task 1: Design reusable depth debug viewer contract

**Bead ID:** `aerobeat-input-camera-tracking-1bkd`  
**SubAgent:** `primary`  
**Role:** `research`  
**References:** `REF-02`, `REF-03`, `REF-04`, `REF-05`, `REF-06`  
**Prompt:** Design the lowest-risk reusable contract for a generic depth debug viewer/control. Specify its inputs, outputs, state model, what remains proving-specific versus reusable, and how boxing proving should consume it without losing truthful unavailable/depth-swap/sample-overlay behavior.

**Folders Created/Deleted/Modified:**
- `.plans/mediapipe-python/`

**Files Created/Deleted/Modified:**
- `.plans/mediapipe-python/2026-06-21-generalize-depth-debug-viewer.md`

**Status:** ✅ Complete

**Results:** Inspected the current seam in `REF-02`, `REF-03`, `REF-04`, `REF-05`, and `REF-06`. The current proving implementation already splits cleanly into two layers: (1) a reusable viewer surface driven by a prepared visual snapshot, and (2) boxing-specific orchestration that chooses a focus family and pulls runtime/debug dictionaries out of `gesture_debug`.

Recommended lowest-risk reusable contract:
- **Reusable component:** extract a dedicated `DepthDebugViewer` control responsible only for rendering a preview/depth relationship from already-prepared data. Keep `REF-04` as its helper child for truthful sample-marker drawing.
- **Inputs:**
  - `visual_config` dictionary: `enabled`, `thumbnail_visible`, `swap_click_enabled`, `hover_hint_visible`, `sampling_regions_visible`, `fps_visible`, `thumbnail_corner`, `thumbnail_width_px`, `thumbnail_margin_px`.
  - optional preview/presenter dependency exposing `get_overlay_layer`, `get_content_rect`, and `map_landmark_to_preview_position` so overlay markers remain aligned without boxing-specific assumptions.
  - `snapshot` dictionary prepared by the consumer with stable fields matching today’s runtime truth surface: `family`, `preview_texture`, `depth_texture`, `runtime_status`, `runtime_stage`, `active_model_summary`, `failure_code`, `failure_message`, `frame_size`, `depth_map_size`, `timing_ms`, `sample_every_n_frames`, `max_sample_age_ms`, `last_sample_age_ms`, `sample_metrics`, and `sample_geometry`.
  - `preview_fps` float supplied by the consumer; the viewer should not compute scene FPS itself.
- **Outputs/state:** internal transient UI state only — `thumbnail_hovered`, `swapped_to_depth`, and `last_texture_available` — plus an optional read-only signal such as `swap_state_changed(swapped_to_depth: bool)` for tests/debugging. The viewer should not mutate runtime config, gesture state, or selected family.
- **Truth rules the viewer must preserve:**
  - if `depth_texture == null`, show the current truthful unavailable placeholder/status text and never fabricate a texture.
  - if `sample_geometry` exists while `depth_texture == null`, still show overlay markers so the UI remains honest about sampled debug state.
  - if `swap_click_enabled == false` or no texture exists, force `swapped_to_depth = false`, hide the hover hint, and reject swap interaction.
  - if only point-sample geometry exists, render exactly those points and labels; do not synthesize ROI boxes or fake coverage regions.
- **Reusable responsibilities:** UI construction, thumbnail layout, swap gating/reset, placeholder/status text composition, FPS/timing label rendering, sample-overlay visibility rules, texture/image normalization handling, overlay parenting, and the truthful unavailable/sample-only semantics currently covered by `REF-05`.
- **Still proving-specific:** choosing which family to inspect (`straight_punch` / `hook` / `uppercut`), translating `gesture_debug.depth_runtime[family]` plus side-specific live state into the generic snapshot, smoothing/measuring preview FPS, YAML-to-runtime request plumbing from `REF-03`/`REF-06`, and all boxing hover-card / inspector / hand-debug-row text.
- **How boxing should consume it:** boxing keeps `_depth_debug_focus_family()`, `_current_depth_runtime_debug_state()`, and boxing-side live-debug extraction, but replaces `_ensure_depth_debug_ui`, `_refresh_depth_debug_visuals`, thumbnail/swap helpers, and overlay/FPS rendering with the reusable viewer. Boxing becomes a snapshot producer plus config provider.
- **Why extraction makes assembly adoption easier:** assembly would only need to emit the same snapshot contract and optional presenter methods, instead of copying boxing family-selection logic, YAML plumbing, or punch-specific debug dictionaries. That keeps the reuse seam narrow and low-risk.
- **Task 2 next step:** implement `DepthDebugViewer`, move current UI/overlay behavior into it, keep runtime `request_runtime_texture` plumbing where it already lives, add one snapshot-builder seam in boxing proving, and port existing thumbnail unavailable / swap-disable / sample-overlay expectations so behavior stays unchanged.

### Task 2: Implement generic depth debug viewer/control and refactor boxing proving to use it

**Bead ID:** `aerobeat-input-camera-tracking-bwj5`  
**SubAgent:** `primary`  
**Role:** `coder`  
**References:** `REF-02`, `REF-03`, `REF-04`, `REF-06`  
**Prompt:** Implement a reusable depth debug viewer/control, move the common thumbnail/swap/unavailable/FPS/sample-overlay behavior into it, and refactor boxing proving to use that component while preserving existing YAML-driven behavior and truthful runtime/UI semantics.

**Folders Created/Deleted/Modified:**
- `.testbed/scripts/`
- `.testbed/tests/`
- `.plans/mediapipe-python/`

**Files Created/Deleted/Modified:**
- `.testbed/scripts/depth_debug_viewer.gd`
- `.testbed/scripts/boxing_proving_harness.gd`
- `.testbed/tests/unit/test_boxing_proving_harness_profiles_and_debug.gd`
- `.plans/mediapipe-python/2026-06-21-generalize-depth-debug-viewer.md`

**Status:** ✅ Complete

**Results:** Implemented `res://scripts/depth_debug_viewer.gd` as the reusable boundary and refactored `REF-02` so boxing proving now acts as a snapshot producer/config provider instead of owning the viewer UI. The landed contract matches Task 1: boxing still chooses the focus family, builds the snapshot from `gesture_debug.depth_runtime`, preserves YAML `request_runtime_texture` plumbing in `REF-03`, and keeps hover-card / inspector / hand-debug text outside the viewer. The viewer now owns UI construction, overlay parenting, truthful unavailable/sample-only rendering, thumbnail swap/reset behavior, FPS/timing text, and sample-marker visibility via `REF-04`.

Concrete implementation details:
- Added `res://scripts/depth_debug_viewer.gd` with inputs for `visual_config`, optional preview/presenter adapter, prepared `snapshot`, and external `preview_fps`.
- Kept viewer-owned state minimal: `thumbnail_hovered`, `swapped_to_depth`, and `last_texture_available` (plus read-only node/state snapshots used by tests and the temporary boxing compatibility bridge).
- Replaced boxing’s inline depth-debug UI construction/refresh logic with viewer wiring helpers and a single `_build_depth_debug_visual_snapshot()` seam.
- Flattened the viewer snapshot to the approved prepared-truth fields (`family`, `preview_texture`, `depth_texture`, runtime status/failure fields, frame/depth sizes, timing, cadence/age, sample metrics, sample geometry) so future consumers can reuse the viewer without importing boxing-specific runtime dictionaries.
- Updated `REF-05` with a direct reusable-viewer test plus refreshed boxing integration expectations for hover-driven swap behavior.

Validation run by coder:
- `godot --headless --path .testbed --script addons/aerobeat-vendor-godot-unit-test/gut_cmdln.gd -gtest=res://tests/unit/test_boxing_proving_harness_profiles_and_debug.gd -gunit_test_name=depth_debug -gexit` → 4/4 passed.
- `godot --headless --path .testbed --script addons/aerobeat-vendor-godot-unit-test/gut_cmdln.gd -gtest=res://tests/unit/test_boxing_proving_harness_profiles_and_debug.gd -gunit_test_name=requests_depth_texture_from_testbed_yaml -gexit` → 1/1 passed.

References validated: `REF-02`, `REF-03`, `REF-04`, `REF-05`, and `REF-06`.

### Task 3: QA reusable depth debug viewer and boxing proving integration

**Bead ID:** `aerobeat-input-camera-tracking-lly3`  
**SubAgent:** `primary`  
**Role:** `qa`  
**References:** `REF-02`, `REF-04`, `REF-05`, `REF-06`  
**Prompt:** Independently verify that the generic depth debug viewer works as claimed, that boxing proving still behaves correctly through it, and that the component is actually reusable enough for future assembly-side adoption.

**Folders Created/Deleted/Modified:**
- `.testbed/`
- `.plans/mediapipe-python/`

**Files Created/Deleted/Modified:**
- tests / plan files touched by QA validation

**Status:** ✅ Complete

**Results:** Independently QA-verified commit `4e2ea94` as a real extraction, not a rename-only shuffle. Inspection of the landed diff showed `REF-02` dropped the inlined depth-debug UI construction/refresh implementation (about 300 lines removed from boxing proving) while new `res://scripts/depth_debug_viewer.gd` now owns the reusable behavior: UI construction, overlay parenting, thumbnail layout, hover/swap gating, truthful unavailable placeholder + status text, FPS/timing label, and sample-overlay rendering via `REF-04`. Boxing proving now limits itself to viewer wiring, focus-family choice, snapshot construction from `gesture_debug.depth_runtime`, preview-FPS measurement, YAML-driven `request_runtime_texture` config propagation, and boxing-specific inspector / hover-card / hand-debug text.

Focused QA validation passed against `REF-05`:
- `godot --headless --path .testbed --script addons/aerobeat-vendor-godot-unit-test/gut_cmdln.gd -gtest=res://tests/unit/test_boxing_proving_harness_profiles_and_debug.gd -gunit_test_name=depth_debug -gexit` → 4/4 passed.
- `godot --headless --path .testbed --script addons/aerobeat-vendor-godot-unit-test/gut_cmdln.gd -gtest=res://tests/unit/test_boxing_proving_harness_profiles_and_debug.gd -gunit_test_name=requests_depth_texture_from_testbed_yaml -gexit` → 1/1 passed.
- `godot --headless --path .testbed --script addons/aerobeat-vendor-godot-unit-test/gut_cmdln.gd -gtest=res://tests/unit/test_boxing_proving_harness_profiles_and_debug.gd -gunit_test_name=applies_boxing_testbed_debug_yaml_to_live_nodes -gexit` → 1/1 passed.

What was specifically verified:
- truthful unavailable behavior still shows the explicit placeholder/status text when no runtime depth texture exists, while still rendering sample markers when sample geometry is present;
- swap behavior still uses the real runtime depth texture when available;
- swap state still resets and hover hint hides when YAML disables thumbnail click-swap;
- `request_runtime_texture` remains YAML-driven and still lands in runtime config;
- the generic viewer reparents into the preview presenter overlay layer and renders prepared snapshot data without boxing-specific assumptions.

Caveat: boxing still mirrors viewer node refs/state into private harness vars as a compatibility bridge for existing tests, so the consumer is not completely oblivious to the viewer internals yet. That does not invalidate the extraction boundary, but Task 4 audit should check whether those compatibility hooks are an acceptable long-term reuse seam.

References validated: `REF-02`, `REF-04`, `REF-05`, and `REF-06`. Task 4 audit should proceed.

### Task 4: Audit reuse-readiness for future assembly integration

**Bead ID:** `aerobeat-input-camera-tracking-s855`  
**SubAgent:** `primary`  
**Role:** `auditor`  
**References:** `REF-02`, `REF-04`, `REF-05`, `REF-06`  
**Prompt:** Independently audit that the extracted depth debug viewer is genuinely reusable, that boxing proving integration remains truthful, and that future assembly-side adoption would now be materially easier without overstating current portability.

**Folders Created/Deleted/Modified:**
- `.testbed/`
- `.plans/mediapipe-python/`

**Files Created/Deleted/Modified:**
- tests / plan files touched by audit validation

**Status:** ✅ Complete

**Results:** Independent audit passes with a caveat explicitly recorded as acceptable technical debt for this plan.

What was audited:
- Re-read `REF-02`, the new `res://scripts/depth_debug_viewer.gd`, and `REF-05` to verify the seam is real and not a cosmetic rename.
- Re-ran focused validation from audit perspective:
  - `godot --headless --path .testbed --script addons/aerobeat-vendor-godot-unit-test/gut_cmdln.gd -gtest=res://tests/unit/test_boxing_proving_harness_profiles_and_debug.gd -gunit_test_name=depth_debug -gexit` → 4/4 passed.
  - `godot --headless --path .testbed --script addons/aerobeat-vendor-godot-unit-test/gut_cmdln.gd -gtest=res://tests/unit/test_boxing_proving_harness_profiles_and_debug.gd -gunit_test_name=requests_depth_texture_from_testbed_yaml -gexit` → 1/1 passed.
  - `godot --headless --path .testbed --script addons/aerobeat-vendor-godot-unit-test/gut_cmdln.gd -gtest=res://tests/unit/test_boxing_proving_harness_profiles_and_debug.gd -gunit_test_name=applies_boxing_testbed_debug_yaml_to_live_nodes -gexit` → 1/1 passed.
- Searched all `_depth_debug_*` mirror fields in `REF-02`/`REF-05` to determine whether boxing runtime logic still depends on the viewer internals.

Audit conclusion:
- The extraction is genuinely reuse-ready enough to call this plan complete and materially useful for future assembly adoption.
- Boxing proving now depends on the reusable viewer through a prepared snapshot + config seam for production behavior: boxing chooses the focus family, builds the snapshot, supplies preview FPS/presenter, and leaves thumbnail rendering, swap gating, truthful unavailable messaging, overlay parenting, FPS label, and sample geometry drawing to the viewer.
- Boxing proving integration remains truthful. When no runtime depth texture exists, the viewer still renders the explicit unavailable placeholder/status while preserving sample markers; when a real runtime depth texture exists, swap uses that real texture; when YAML disables swap, the viewer resets the swap state and hides the hint.
- The compatibility bridge is present but acceptable for this plan because it is not the production seam: the mirrored node refs/state in `REF-02` are only used as a harness/test bridge after viewer refresh/toggle calls, not as inputs that drive viewer behavior. The audit search found those mirrored vars are assigned/reset in the harness and then consumed by `REF-05` assertions; the runtime behavior itself still flows from the viewer instance plus snapshot/config, not from boxing mutating those private mirrors.

Remaining coupling concern:
- `get_node_refs()` / `get_state_snapshot()` plus the mirrored `_depth_debug_*` harness vars are still a consumer-visible compatibility crutch around tests. That means the extraction is not yet perfectly minimal/clean. Future cleanup should migrate tests toward direct viewer assertions or higher-level behavior checks so boxing can drop the mirrored internals entirely.
- That concern is not severe enough to fail this bead because the extracted runtime boundary is already honest and reusable for another consumer that does **not** adopt the boxing compatibility vars.

References validated: `REF-02`, `REF-04`, `REF-05`, and `REF-06`.

---

## Final Results

**Status:** ✅ Complete

**What We Built:** A reusable `DepthDebugViewer` now owns depth thumbnail/swap/unavailable/FPS/sample-overlay behavior while boxing proving has been reduced to a truthful snapshot producer/config consumer. Future assembly adoption can reuse the viewer by emitting the same prepared snapshot contract instead of re-implementing the proving-specific UI plumbing.

**Reference Check:** `REF-02`, `REF-04`, `REF-05`, and `REF-06` were satisfied. The only deliberate caveat is the temporary boxing-side mirror of viewer refs/state for legacy harness tests; audit judged that acceptable because it is not the runtime reuse seam.

**Commits:**
- `4e2ea94` - Extract reusable depth debug viewer

**Lessons Learned:** The useful reuse seam is the prepared snapshot contract, not just moving code into a new file. Test-compatibility mirrors can be tolerated temporarily, but only when they remain observational and do not become part of the production integration contract.

---

*Created on 2026-06-21*
