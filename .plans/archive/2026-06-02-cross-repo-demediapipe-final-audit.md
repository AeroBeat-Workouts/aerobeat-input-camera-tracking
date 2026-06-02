# Cross-Repo De-MediaPipe Final Audit

**Date:** 2026-06-02 01:12 EDT
**Status:** Stale
**Auditor:** OpenClaw subagent (`auditor`)
**Coordination Bead:** `aerobeat-input-camera-tracking-l9g`

---

## Verdict

**PASS** for the repo-side cross-repo de-MediaPipe boundary audit.

The landed state matches the intended split:
- `aerobeat-input-camera-tracking` now presents a neutral public/provider/session seam as `camera_tracking`
- `aerobeat-input-core` no longer preserves stale public lookup compatibility for `mediapipe_python`
- `aerobeat-tool-camera-tracking` now owns the backend defaulting/bridge story
- `aerobeat-vendor-mediapipe-python` remains the concrete vendor implementation behind the tool boundary
- the remaining vendor mount in `.testbed/addons.jsonc` is proving-only dependency wiring, not public contract leakage

A later **human verification pass is still required** for live-webcam/product acceptance.

---

## Audit method

### Repo-side evidence reviewed
- coordination plan: `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.plans/archive/2026-06-01-cross-repo-demediapipe-coordination.md`
- seam map: `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.plans/2026-06-01-cross-repo-demediapipe-seam-map.md`
- neutral contract: `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.plans/2026-06-01-cross-repo-demediapipe-neutral-contract.md`
- landed commits inspected:
  - tool: `620cbc2`, `ba24cb4`
  - input-core: `1271f9c`, `d7c37d9`
  - input-camera-tracking: `565655d`, `f17ab68`
  - vendor: `07ae093`, `5051b45`

### Independent spot validation rerun performed in this audit
- `aerobeat-tool-camera-tracking`: `res://tests/test_CameraTracking.gd` → **13/13 passed**
- `aerobeat-input-core`: `res://tests/unit/test_input_manager_provider_identity.gd` → **4/4 passed**
- `aerobeat-input-camera-tracking`: `res://tests/unit/test_input_provider_adapter.gd` → **14/14 passed**
- `aerobeat-vendor-mediapipe-python`: `res://tests/test_mediapipe_python_backend.gd` → **3/3 passed**

These reruns confirm the contract split at the repo/test seam level. They do **not** replace later live-hardware acceptance.

---

## Findings by verification target

### 1) `aerobeat-input-camera-tracking` no longer contains MediaPipe-specific public knowledge in active sharable seams

**PASS**

Observed source-of-truth evidence:
- `src/input_provider.gd`
  - `PROVIDER_ID := "camera_tracking"`
  - `SHARED_SESSION_KEY := "camera_tracking"`
  - public lane metadata is `camera_tracking`
- `src/providers/camera_tracking_provider.gd`
  - emits `"backend": "camera_tracking_default"`
  - resolves repo-local config from `config/camera_tracking_config.gd`
- sharable `src/` grep no longer shows active `mediapipe_python` usage

Remaining naming remnant:
- `src/config/mediapipe_config.gd`
  - thin shim extending `camera_tracking_config.gd`
  - `class_name MediaPipeConfig`
  - comment explicitly marks it as compatibility-only

Audit conclusion:
- this shim is a **leftover compatibility alias**, not an active public boundary violation
- the active sharable seam now speaks in neutral `camera_tracking` terms

---

### 2) `aerobeat-input-core` public/provider/session identity is cleanly `camera_tracking` and legacy public lookup compatibility is gone

**PASS**

Observed source-of-truth evidence:
- `src/input_manager.gd`
  - priority list starts with `"camera_tracking"`
  - no `mediapipe_python` public provider priority remains for the desktop lane
- `docs/provider-session-registry-v1.md`
  - examples now use `camera_tracking`
  - session keys use `camera_tracking/...`
- `src/runtime/provider_session_registry.gd`
  - generic registry behavior remains, without special legacy `mediapipe_python` fallback logic

Independent anti-compatibility proof:
- `res://tests/unit/test_input_manager_provider_identity.gd`
  - `test_registry_does_not_resolve_legacy_mediapipe_provider_lookup_after_clean_break`
  - explicitly verifies `provider_id = "mediapipe_python"` and `session_key = "mediapipe_python/shared"` now return `STATUS_MISSING`
  - reran in this audit: **4/4 passed**

Audit conclusion:
- legacy public lookup compatibility is intentionally removed, not merely undocumented

---

### 3) `aerobeat-tool-camera-tracking` owns the shared seam/defaulting story and neutral bridge behavior

**PASS**

Observed source-of-truth evidence:
- `src/CameraTrackingConfig.gd`
  - `DEFAULT_BACKEND := "camera_tracking_default"`
  - `DEFAULT_BACKEND_IMPL := "mediapipe_python"`
  - `resolve_backend_id("") -> mediapipe_python`
  - `resolve_backend_id("camera_tracking_default") -> mediapipe_python`
- `src/CameraTracking.gd`
  - backend selection and fallback resolution live in the tool contract
  - structured error surfaces include `backend_request` and `backend_impl`
- `src/CameraTrackingFrame.gd`
  - neutral/requested vs resolved/implementation identity is separated

Independent validation rerun:
- `res://tests/test_CameraTracking.gd` → **13/13 passed**
- includes assertions that:
  - the default request is `camera_tracking_default`
  - omitted backend resolves to `mediapipe_python`
  - explicit `mediapipe_python` still works as the implementation id

Audit conclusion:
- defaulting/bridge ownership has moved to the correct repo boundary
- `mediapipe_python` remains accepted as an implementation/backend id, but the public default request identity is tool-owned and neutral

---

### 4) `aerobeat-vendor-mediapipe-python` remains behind the correct boundary as the vendor implementation

**PASS**

Observed source-of-truth evidence:
- vendor repo still owns:
  - `MediaPipePythonConfig.gd`
  - `MediaPipePythonRuntimeBridge.gd`
  - runtime entrypoint `runtime/mediapipe_runtime_probe.py`
  - MediaPipe-branded runtime/session/env naming
- `src/MediaPipePythonFrameMapper.gd`
  - now exposes `backend_request` and `backend_impl`
  - keeps `backend_impl = mediapipe_python`
  - defaults request-side shaping to `camera_tracking_default`

Independent validation rerun:
- `res://tests/test_mediapipe_python_backend.gd` → **3/3 passed**
- confirms vendor runtime config translation and frame mapping preserve the expected tool/vendor split

Audit conclusion:
- vendor naming still exists, but in the correct place: the vendor implementation boundary
- this is not public seam leakage

---

### 5) Remaining `.testbed/addons.jsonc` vendor mount is proving-only dependency wiring rather than public contract leakage

**PASS**

Observed source-of-truth evidence:
- `aerobeat-input-camera-tracking/.testbed/addons.jsonc` mounts `aerobeat-vendor-mediapipe-python`
- the file comment explicitly limits that mount to:
  - `only for repo-local live CameraTracking proving`
- the input repo’s active sharable `src/` no longer uses that mount to define public provider/session/backend identity

Important distinction:
- `.testbed/addons.jsonc` is workbench/testbed dependency wiring
- it is **not** the public product contract
- mounted copies/symlinks under `.testbed/addons/` may lag or differ from repo-root source truth; they are proving artifacts, not the audited public seam definition

Audit conclusion:
- allowed exception remains within the proving boundary and does not reintroduce public MediaPipe contract ownership into `aerobeat-input-camera-tracking`

---

### 6) Leftover compatibility shims or naming remnants vs real boundary violations

**Compatibility remnants that are acceptable right now**
- `aerobeat-input-camera-tracking/src/config/mediapipe_config.gd`
  - compatibility shim only
- vendor-internal names like:
  - `MediaPipePythonConfig`
  - `MediaPipePythonRuntimeBridge`
  - `runtime/mediapipe_runtime_probe.py`
  - `user://mediapipe_python_runtime_bridge`
- tool/vendor test assertions that still validate `backend_impl = mediapipe_python`

**Not violations** because they stay inside:
- compatibility aliasing
- vendor implementation internals
- tool-owned resolved backend diagnostics
- proving-only testbed wiring

**Real violations I looked for but did not find**
- `aerobeat-input-camera-tracking/src/` still publishing `provider_id = mediapipe_python`
- `aerobeat-input-camera-tracking/src/` still defaulting shared sessions to `mediapipe_python`
- `aerobeat-input-camera-tracking/src/` still selecting vendor backend directly
- `aerobeat-input-core` still resolving stale public `mediapipe_python` lookups
- tool repo still using `mediapipe_python` as the public default request id

---

## Automated repo-side truth vs later human verification

### Automated repo-side truth established now
- neutral public/provider/session identity is `camera_tracking`
- stale public lookup compatibility for `mediapipe_python` is removed from input-core
- tool repo owns the neutral backend default/bridge seam
- vendor repo remains behind the tool boundary as the concrete implementation
- proving-only vendor mount remains a proving seam, not a public contract seam
- focused independent reruns passed on all four repos

### Still required later human verification
- live webcam behavior in a real machine/product session
- final product acceptance in the intended runtime assembly
- any UX/product expectations around preview, tracking recovery, and camera-device behavior that exceed repo-local automated coverage

---

## Final conclusion

**PASS**

The coordinated de-MediaPipe split is truthfully landed at the repo boundary level. The public seam is now neutralized around `camera_tracking`, while `mediapipe_python` has been pushed back to the correct compatibility/vendor-implementation layers.

The work is ready for final human verification, with no repo-side blocker found in this audit.
