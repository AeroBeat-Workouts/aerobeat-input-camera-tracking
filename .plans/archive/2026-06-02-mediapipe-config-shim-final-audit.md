# MediaPipe Config Shim Retirement Final Audit

**Date:** 2026-06-02 07:10 EDT
**Status:** Stale
**Auditor:** OpenClaw subagent (`auditor`)
**Plan:** `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.plans/archive/2026-06-02-mediapipe-config-shim-retirement.md`

## Verdict

**PASS** — after the assembly manifest pin update and `godotenv-sync --refresh-caches --install`, the remaining `mediapipe_config.gd` / `MediaPipeConfig` hits are limited to history, logs, and cache/index surfaces. I found no remaining live or tests-only dependency truth in current repo source or generated addon source/test surfaces.

## Evidence checked

### Source-of-truth repo state
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/src/config/camera_tracking_config.gd`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/src/input_provider.gd`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/src/providers/camera_tracking_provider.gd`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/src/AeroCameraTracking.gd`
- Confirmed absent on disk: `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/src/config/mediapipe_config.gd`
- Confirmed absent on disk: `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/src/config/mediapipe_config.gd.uid`

### Consumer manifest + generated mirrors
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-assembly-community/addons.jsonc`
  - alias key remains `aerobeat-input-mediapipe`
  - repo URL points to `git@github.com:AeroBeat-Workouts/aerobeat-input-camera-tracking.git`
  - checkout now pinned to `4f63ccd2d131d4192e9675fd6a78572780a7ec0f`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-assembly-community/.addons/aerobeat-input-mediapipe/`
  - nested repo HEAD resolves to `4f63ccd2d131d4192e9675fd6a78572780a7ec0f`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-assembly-community/addons/aerobeat-input-mediapipe/`
  - treated as generated install artifact, not edited as source

### Search results classification
Current `rg -uu -n 'mediapipe_config\.gd|MediaPipeConfig'` hits in the two target repos are limited to:
- plan/history content under `.plans/**`
- QA/export logs under `.qa-logs/**`
- Godot cache/index files under `.godot/**` and `.testbed/.godot/**`
- bead interaction history under `.beads/interactions.jsonl`

No live hits remain under:
- `aerobeat-input-camera-tracking/src/**`
- `aerobeat-assembly-community/addons/aerobeat-input-mediapipe/src/**`
- `aerobeat-assembly-community/.addons/aerobeat-input-mediapipe/src/**`
- `aerobeat-assembly-community/addons/aerobeat-input-mediapipe/.testbed/**`
- `aerobeat-assembly-community/.addons/aerobeat-input-mediapipe/.testbed/**`

## Conclusion

The neutral replacement state is correct: active code paths now resolve `camera_tracking_config.gd` / `CameraTrackingConfig`, the legacy shim file is gone from source, and the assembly consumer pin/cache state matches the retired-shim commit. Generated addon mirrors were validated as mirrors only, not treated as source of truth.

## Caveats

- Historical plan/log/cache files still mention `MediaPipeConfig`; that is expected and non-blocking.
- `aerobeat-input-camera-tracking` still has unrelated plan-worktree noise and a pre-existing trailing-whitespace issue in `.plans/2026-06-01-vendor-import-webcam-replay-2d-skeleton-truth.md`; neither affects this audit verdict.
