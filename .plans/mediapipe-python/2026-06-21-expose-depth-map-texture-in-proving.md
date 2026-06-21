# AeroBeat expose depth map texture in proving

**Date:** 2026-06-21  
**Status:** In Progress  
**Last Updated:** 2026-06-21 17:58 EDT  
**Blocked Reason:** None  
**Agent:** `pico`

---

## Goal

Expose a truthful depth-map texture through the boxing proving-scene thumbnail/swap UI, controlled by boxing proving YAML, so Derrick can directly inspect the depth output during evaluation.

---

## Overview

The previous plan intentionally stopped short of pretending a depth texture existed when the runtime still surfaced `normalized_depth_map = null`. Derrick now wants to push past that limit and actually expose the depth-map texture through the proving scene’s thumbnail swapping system. That means this slice is no longer just proving UI polish; it reaches into the runtime/debug payload boundary and must stay honest about what the runtime can really produce.

The safest path is to first design and verify the texture contract end to end: where the normalized depth image is generated, how it is transported into the Godot runtime/debug state, what format/size/lifetime it has, and how the boxing proving scene should consume it. Only after that contract is clear should implementation land in the runtime bridge/manager and then the proving harness. The YAML toggle remains the source of truth for whether the thumbnail/swap depth view is enabled.

A key constraint is performance. Surfacing the texture must not silently become a massive extra cost on top of inference, especially for Chip and lower-end targets. The implementation should make it clear whether the texture is always emitted, emitted only when proving debug requests it, or derived from already-computed runtime artifacts. The proving scene must also remain truthful if the texture is unavailable for any reason.

---

## REFERENCES

| ID | Description | Path |
| --- | --- | --- |
| `REF-01` | Depth knobs and proving visual debug plan | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.plans/mediapipe-python/2026-06-21-depth-knobs-and-proving-visual-debug.md` |
| `REF-02` | Boxing proving harness script | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.testbed/scripts/boxing_proving_harness.gd` |
| `REF-03` | Depth sample debug overlay | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.testbed/scripts/depth_sample_debug_overlay.gd` |
| `REF-04` | Proving harness tests | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.testbed/tests/unit/test_boxing_proving_harness_profiles_and_debug.gd` |
| `REF-05` | Boxing proving YAML | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/assets/boxing.testbed_debug.yaml` |
| `REF-06` | Depth runtime manager | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/src/depth/depth_runtime_manager.gd` |
| `REF-07` | Depth Python bridge | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/src/depth/depth_python_runtime_bridge.gd` |
| `REF-08` | Python depth inference script | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/scripts/depth_runtime_infer.py` |

---

## Tasks

### Task 1: Design truthful depth-texture exposure contract

**Bead ID:** `aerobeat-input-camera-tracking-117z`  
**SubAgent:** `primary`  
**Role:** `research`  
**References:** `REF-02`, `REF-05`, `REF-06`, `REF-07`, `REF-08`  
**Prompt:** Design the lowest-risk truthful contract for exposing a real depth-map texture from the runtime into the boxing proving-scene thumbnail/swap system. Specify where the texture is generated, what normalized format/size it uses, whether it is always emitted or only when debug requests it, how proving YAML toggles control it, and what performance/caching caveats apply for Chip and lower-end devices.

**Folders Created/Deleted/Modified:**
- `.plans/mediapipe-python/`

**Files Created/Deleted/Modified:**
- `.plans/mediapipe-python/2026-06-21-expose-depth-map-texture-in-proving.md`

**Status:** ✅ Complete

**Results:** Inspected the full seam in `REF-06`, `REF-07`, `REF-08`, `REF-02`, and `REF-05`. Current truth: the contract already reserves `normalized_depth_map` all the way from `DepthRuntimeTypes` → `DepthRuntimeManager` → `gesture_debug.depth_runtime[family]` → boxing proving `_depth_texture_from_runtime_debug()`, and cached reuse already preserves that field, but the Python worker still returns `normalized_depth_map: null` on every successful inference. Recommended lowest-risk contract: generate the debug texture in `scripts/depth_runtime_infer.py` immediately after the existing full-frame `normalized_depth` array is produced for sampling; keep the authoritative internal map as the same `frame_resized_normalized_depth` data the sample geometry already references (`depth_map_size == frame_size`, single-channel normalized 0..1, larger/brighter means nearer after the current sign normalization); expose it to Godot only as an explicitly requested proving/debug artifact, not as an always-on runtime payload; transport it as an 8-bit grayscale PNG encoded to base64 in the worker response, with the bridge decoding that into `Image`/`ImageTexture` and storing the resulting `Texture2D` back into `normalized_depth_map`; and drive the request from boxing proving YAML by adding a proving-only toggle under `visuals.depth_debug` (for example `request_runtime_texture: true/false`) that the harness copies into `config.runtime.depth_debug` before startup so the substrate/manager can include a `debug_texture_requested` flag in the sample request. This keeps the proving UI truthful, lets cached cadence reuse keep reusing the last texture when `sample_every_n_frames` skips inference, and avoids paying PNG/base64 transport cost on normal gameplay or non-proving runs. Main caveat for Chip/lower-end devices: full-frame PNG+base64 adds non-trivial postprocess/transport cost and memory churn on every fresh depth inference, so the first implementation should keep the request opt-in, reuse the last emitted texture for cached samples, and never silently fabricate or backfill a texture when the debug request is off or transport fails.

### Task 2: Implement runtime depth-texture exposure

**Bead ID:** `aerobeat-input-camera-tracking-590i`  
**SubAgent:** `primary`  
**Role:** `coder`  
**References:** `REF-06`, `REF-07`, `REF-08`  
**Prompt:** Implement the truthful runtime/debug payload support needed to expose a real depth-map texture to the proving scene. Preserve current threshold behavior, keep the payload honest, and be explicit about the performance behavior of generating/surfacing the texture.

**Folders Created/Deleted/Modified:**
- `src/depth/`
- `scripts/`
- `.testbed/tests/`
- `.plans/mediapipe-python/`

**Files Created/Deleted/Modified:**
- runtime / bridge / inference / tests / plan files touched by implementation

**Status:** ✅ Complete

**Results:** Implemented the proving-only depth-texture transport across `REF-06`/`REF-07`/`REF-08` without adding a second inference pass. `src/detectors/pose_detector_substrate.gd` now builds depth sample requests through a helper that preserves the existing evaluation/cadence payload and adds `debug_texture_requested: true` only when `config.runtime.depth_debug.request_runtime_texture` is enabled. `scripts/depth_runtime_infer.py` now encodes the already-resized authoritative `normalized_depth` map into an 8-bit grayscale PNG base64 payload only when that request flag is present, while still using the same full-frame normalized depth array for the actual shoulder/wrist sampling math. `src/depth/depth_python_runtime_bridge.gd` hydrates that optional worker payload back into a real `ImageTexture` and stores it in `normalized_depth_map`; absent, null, invalid-base64, or non-PNG payloads remain truthfully `null` instead of fabricating fallback textures. Cached cadence reuse in `DepthRuntimeManager` continues to duplicate/reuse the last successful `normalized_depth_map`, so skipped fresh inference frames keep the most recent texture when one was previously requested and produced. Added unit coverage for requested fresh inference texture surfacing, cached reuse texture preservation, non-requested null behavior, invalid-payload null behavior, and runtime-config request plumbing. Validation run: targeted GUT passes for `test_depth_runtime_manager.gd`, `test_depth_python_runtime_bridge.gd`, and the specific substrate request-plumbing test; Python worker also passes `python3 -m py_compile scripts/depth_runtime_infer.py`.

### Task 3: Implement proving-scene depth thumbnail swap on real texture

**Bead ID:** `aerobeat-input-camera-tracking-bc2c`  
**SubAgent:** `primary`  
**Role:** `coder`  
**References:** `REF-02`, `REF-03`, `REF-04`, `REF-05`, `REF-06`  
**Prompt:** Implement the boxing proving-scene thumbnail/swap behavior for a real depth-map texture, controlled by boxing proving YAML. Keep the unavailable state truthful when the texture is missing, preserve sample-point overlays, and ensure click-to-swap behaves cleanly between RGB preview and depth texture.

**Folders Created/Deleted/Modified:**
- `.testbed/`
- `assets/`
- `.plans/mediapipe-python/`

**Files Created/Deleted/Modified:**
- proving scripts / tests / config / plan files touched by implementation

**Status:** ✅ Complete

**Results:** Wired the boxing proving YAML into the runtime request seam so `assets/boxing.testbed_debug.yaml` now explicitly controls `visuals.depth_debug.request_runtime_texture`, and `_build_runtime_config()` copies that into `config.runtime.depth_debug.request_runtime_texture` before startup. The proving UI keeps its truthful unavailable path when that runtime texture is absent, but when the runtime does surface a real `normalized_depth_map` texture the thumbnail now uses that texture directly and click-to-swap cleanly flips the main preview between RGB and depth. Swap state now resets automatically if YAML disables the thumbnail or click-swap path, so the behavior stays YAML-driven instead of leaving the scene stuck on a depth view after config changes. Sample-point overlays and FPS/timing surfaces remain independent and continue to render from the same runtime debug snapshot whether or not a texture is available. Also tightened the thumbnail layout so the configured `thumbnail_corner` value is now actually honored instead of being silently treated as bottom-right only. Added focused GUT coverage for the new runtime-config request flag, the no-request flow profile default, and the YAML-disabled swap reset path; also re-ran the existing substrate request-plumbing test to confirm the new proving config still reaches the lower runtime request contract in `REF-06`.

### Task 4: QA depth-texture proving flow

**Bead ID:** `aerobeat-input-camera-tracking-wnp0`  
**SubAgent:** `primary`  
**Role:** `qa`  
**References:** `REF-02`, `REF-04`, `REF-05`, `REF-06`  
**Prompt:** Independently verify that the real depth-map texture is exposed truthfully, that the proving YAML toggles control the thumbnail/swap flow correctly, that the unavailable state still behaves honestly when needed, and that threshold-depth behavior/regressions remain clean.

**Folders Created/Deleted/Modified:**
- proving / runtime / tests / plan files touched by implementation

**Files Created/Deleted/Modified:**
- proving / runtime / tests / plan files touched by implementation

**Status:** ⏳ Pending

**Results:** Pending.

### Task 5: Audit depth-texture readiness for Chip evaluation

**Bead ID:** `aerobeat-input-camera-tracking-s71a`  
**SubAgent:** `primary`  
**Role:** `auditor`  
**References:** `REF-02`, `REF-04`, `REF-05`, `REF-06`, `REF-08`  
**Prompt:** Independently audit that the proving scene now exposes a real depth-map texture truthfully, that the thumbnail/swap YAML path is clean, and that the result is useful for Chip evaluation without overstating performance or portability.

**Folders Created/Deleted/Modified:**
- proving / runtime / tests / plan files touched by implementation

**Files Created/Deleted/Modified:**
- proving / runtime / tests / plan files touched by implementation

**Status:** ⏳ Pending

**Results:** Pending.

---

## Final Results

**Status:** ⚠️ Partial

**What We Built:** Pending.

**Reference Check:** Pending.

**Commits:**
- Pending.

**Lessons Learned:** Pending.

---

*Created on 2026-06-21*
