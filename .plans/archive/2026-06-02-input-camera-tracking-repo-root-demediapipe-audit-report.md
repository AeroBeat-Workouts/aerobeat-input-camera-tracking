# Repo-Root `src/` De-MediaPipe Audit Report

**Date:** 2026-06-02 05:56 EDT
**Status:** Stale
**Repo:** `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking`
**Bead:** `aerobeat-input-camera-tracking-92i`

## Verdict

**PASS** for the repo-root `src/` boundary.

Sharable repo-root `src/` no longer encodes MediaPipe as its active public/provider/session/backend contract. The remaining MediaPipe knowledge is confined to:
- an allowed **repo-local compatibility shim** at `src/config/mediapipe_config.gd`
- the **tool-owned backend bridge** in sibling repo `../aerobeat-tool-camera-tracking`
- the **vendor implementation layer** in sibling repo `../aerobeat-vendor-mediapipe-python`
- the allowed **proving-only `.testbed` dependency mount** in `.testbed/addons.jsonc`

## Evidence

### 1) Public/provider/session identity in repo-root `src/` is neutral

- `src/input_provider.gd`
  - `PROVIDER_ID := "camera_tracking"`
  - `SHARED_SESSION_KEY := "camera_tracking"`
  - comments explicitly say this repo **does not** reclaim upstream runtime/backend ownership and **does not** compose local vendor/runtime implementations
- `src/providers/camera_tracking_provider.gd`
  - `_build_tracking_config()` emits `"backend": "camera_tracking_default"`
  - source payloads are generic `live_camera` / `video_file`
  - runtime/diagnostics/vendor dictionaries are passed through generically, not branded to MediaPipe
- `src/AeroCameraTracking.gd`
  - consumes only `res://addons/aerobeat-tool-camera-tracking/src/CameraTracking.gd`
  - comments explicitly say it consumes only the public CameraTracking contract and does not locally compose vendor backend/runtime objects

### 2) Direct MediaPipe naming inside repo-root `src/` is limited to one compatibility shim

`rg -n -i "mediapipe" src` returned only:
- `src/config/mediapipe_config.gd:2` → `class_name MediaPipeConfig`

That file is a thin compatibility alias:
- `src/config/mediapipe_config.gd`
  - extends `src/config/camera_tracking_config.gd`
  - comment: `Compatibility shim kept for consumers that still preload the legacy script path.`
  - comment: `Repo-local code now uses camera_tracking_config.gd as the neutral source of truth.`

This is residual compatibility surface, not active vendor ownership in the sharable contract path.

### 3) Backend/vendor resolution is owned outside this repo-root `src/`

- `../aerobeat-tool-camera-tracking/src/CameraTrackingConfig.gd`
  - `DEFAULT_BACKEND := "camera_tracking_default"`
  - `DEFAULT_BACKEND_IMPL := "mediapipe_python"`
  - `resolve_backend_id("")` and `resolve_backend_id("camera_tracking_default")` resolve inside the tool repo
- `../aerobeat-vendor-mediapipe-python/src/MediaPipePythonFrameMapper.gd`
  - keeps `backend_impl = mediapipe_python`
  - uses `backend_request = camera_tracking_default`

That is the intended post-migration ownership split: neutral request identity at the contract seam, vendor identity behind the tool/vendor boundary.

### 4) Allowed proving-only vendor wiring remains outside sharable repo-root `src/`

- `.testbed/addons.jsonc`
  - mounts `aerobeat-vendor-mediapipe-python`
  - comment explicitly limits it to `only for repo-local live CameraTracking proving`

This is allowed dependency wiring for proving and does not change the repo-root `src/` contract.

## Boundary judgment

Repo-root `src/` is still aware of a legacy MediaPipe config script name only through `src/config/mediapipe_config.gd`, but that file is a compatibility alias rather than an active provider/session/backend/config/runtime/env assumption. I found **no** repo-root `src/` evidence of:
- public `provider_id = mediapipe_python`
- shared session keys named `mediapipe_python`
- repo-root backend defaulting directly to `mediapipe_python`
- MediaPipe-specific runtime paths or env vars in repo-root `src/`
- repo-root comments claiming ownership of MediaPipe runtime behavior

## Conclusion

**PASS.** Repo-root `src/` is clean with respect to the intended de-MediaPipe boundary. The remaining MediaPipe knowledge is confined to allowed layers:
- compatibility aliasing in `src/config/mediapipe_config.gd`
- tool-owned backend bridging in `../aerobeat-tool-camera-tracking`
- vendor implementation internals in `../aerobeat-vendor-mediapipe-python`
- proving-only `.testbed` dependency wiring in `.testbed/addons.jsonc`
