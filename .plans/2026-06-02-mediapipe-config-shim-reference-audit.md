# MediaPipe Config Shim Reference Audit

**Date:** 2026-06-02 06:08 EDT
**Repo:** `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking`
**Bead:** `aerobeat-input-camera-tracking-lwk`

## Scope

Searched AeroBeat sibling repos for live `MediaPipeConfig` / `mediapipe_config.gd` references, excluding `.git`, `.godot`, generated temp logs, and plan/docs history when determining runtime retirement risk.

## Exact live / tests-only hits

### 1) Live compatibility shim in owning repo
- **Repo:** `aerobeat-input-camera-tracking`
- **Path:** `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/src/config/mediapipe_config.gd`
- **Classification:** **live code/runtime/resource dependency**
- **Why:** this file is the compatibility bridge itself and still defines `class_name MediaPipeConfig` for any consumer preloading the legacy path/class.
- **Neutral replacement:** `res://addons/aerobeat-input-camera-tracking/src/config/camera_tracking_config.gd` / `CameraTrackingConfig`
- **Retirement note:** removable only after all downstream consumers stop preloading or typing against the legacy script/class.

### 2) Tests-only consumer in sibling repo
- **Repo:** `aerobeat-assembly-community`
- **Path:** `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-assembly-community/src/mediapipe_provider_test.gd`
- **Classification:** **tests-only dependency**
- **Exact refs:**
  - line 5 preload: `res://addons/aerobeat-input-mediapipe/src/config/mediapipe_config.gd`
  - line 17 typed export: `@export var config: MediaPipeConfig`
  - line 34 instantiation: `MediaPipeConfig.new()`
- **Why:** this is a standalone validation script, not a shipped runtime provider contract, but it will break immediately if the shim path/class disappears.
- **Neutral replacement:** `res://addons/aerobeat-input-mediapipe/src/config/camera_tracking_config.gd` / `CameraTrackingConfig` (keeping the existing assembly addon mount alias, unless that alias is being changed in a separate slice).

## Docs/history-only references

These do not block shim retirement:
- repo plans/history under `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.plans/`
- assembly historical plans under `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-assembly-community/.plans/`
- UI kit note packet under `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-ui-kit-community/docs/notes/2026-05-23-class-name-guardrail-packet.md`
- temp replay/live logs under `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-tool-camera-gesture-control/.temp/probe-logs/`

## Verdict

`/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/src/config/mediapipe_config.gd` is **not removable yet**.

The concrete blocker found in the current AeroBeat workspace is the tests-only consumer at:
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-assembly-community/src/mediapipe_provider_test.gd`

## Recommended next implementation seam

1. Update `aerobeat-assembly-community/src/mediapipe_provider_test.gd` to preload/type/instantiate `camera_tracking_config.gd` / `CameraTrackingConfig` instead of the legacy shim.
2. Re-run the cross-repo search for `MediaPipeConfig` / `mediapipe_config.gd` excluding plan/docs/temp history.
3. If that search is clean, remove `src/config/mediapipe_config.gd` from `aerobeat-input-camera-tracking` in the follow-up coder slice.
