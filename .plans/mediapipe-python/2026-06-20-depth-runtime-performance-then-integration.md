# AeroBeat depth runtime performance then integration

**Date:** 2026-06-20  
**Status:** In Progress  
**Last Updated:** 2026-06-20 18:54 EDT  
**Blocked Reason:** None.  
**Agent:** `pico`

---

## Goal

First eliminate the biggest depth-runtime performance bottleneck, then deepen live runtime integration of the real depth signal into boxing flows.

---

## Overview

The prior seam is now complete: artifact-path resolution, model swapping, real backend execution, and truth-first proving/debug surfaces are all live and audited. The current dominant weakness is performance. Each inference still goes through a fresh Python bridge invocation, which is functionally correct but too expensive for serious live boxing use, especially for Depth Anything V2 Small.

So the next seam should be ordered exactly the way Derrick requested: performance first, runtime integration second. That means the first implementation work should focus on replacing the one-process-per-inference path with a persistent depth worker or similarly low-overhead execution model while preserving the existing shared seam and truthful debug surfaces. Only after that should we spend effort pushing deeper live runtime integration into more boxing replay/live paths, because otherwise we would be integrating a path that is still too slow to trust in real use.

The current code makes the bottleneck very clear. `DepthRuntimeManager` already gives the rest of the detector stack a clean backend-agnostic seam, and `DepthPythonRuntimeBridge` already centralizes the Python boundary. But `_run_request()` still writes temp JSON request/response files and then calls `OS.execute(...)` for every probe and every inference. On the Python side, `scripts/depth_runtime_infer.py` re-imports dependencies, rebuilds the runtime session, reloads the model, re-reads the preview image, and recompiles or recreates the backend session on each request. That is the highest-overhead part of the pipeline and the lowest-risk place to attack first, because it can be changed without rewriting the detector-facing seam.

---

## REFERENCES

| ID | Description | Path |
| --- | --- | --- |
| `REF-01` | Completed depth runtime seam / execution / truth-gap plan | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.plans/mediapipe-python/2026-06-20-depth-runtime-loader-and-model-swap-seam.md` |
| `REF-02` | Shared depth runtime manager | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/src/depth/depth_runtime_manager.gd` |
| `REF-03` | Shared Python runtime bridge | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/src/depth/depth_python_runtime_bridge.gd` |
| `REF-04` | Current Python inference entrypoint | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/scripts/depth_runtime_infer.py` |
| `REF-05` | Boxing detector runtime consumer | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/src/detectors/pose_detector_substrate.gd` |
| `REF-06` | Proving/debug surface | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.testbed/scripts/boxing_proving_harness.gd` |
| `REF-07` | Vendor Python runtime dependency set | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-vendor-mediapipe-python/runtime/requirements.txt` |

---

## Tasks

### Task 1: Design persistent-worker performance plan

**Bead ID:** `aerobeat-input-camera-tracking-4u6o`  
**SubAgent:** `primary`  
**Role:** `research`  
**References:** `REF-01`, `REF-02`, `REF-03`, `REF-04`, `REF-07`  
**Prompt:** Design the lowest-risk performance improvement path for the live depth runtime. Focus on replacing the one-process-per-inference bridge with a persistent worker or similarly low-overhead execution model while preserving the shared seam, truthful debug state, and model swapping. Specify transport choice, lifecycle, cache/reload behavior, failure recovery, and what timing/debug fields should be added so performance work stays observable.

**Folders Created/Deleted/Modified:**
- `.plans/mediapipe-python/`

**Files Created/Deleted/Modified:**
- `.plans/mediapipe-python/2026-06-20-depth-runtime-performance-then-integration.md`

**Status:** ✅ Complete

**Results:** Reviewed the current runtime seam and confirmed the dominant cost sits entirely inside the existing Godot↔Python bridge, not in the detector-facing shared seam. `DepthRuntimeManager` in `REF-02` already preserves the right architecture boundary: model-path resolution, backend/family selection, cache keying, detector-facing normalized output, and shared debug state are centralized there. `DepthPythonRuntimeBridge` in `REF-03` is also already the correct choke point for the performance change, because `_run_request()` currently does three expensive things per call: (1) writes request/response temp JSON files, (2) starts a new Python process with `OS.execute(...)`, and (3) waits for that process to cold-load its runtime. On the Python side, `REF-04` repeats the heavy work on every call: import stack, backend session construction, model load, and per-request backend setup.

Lowest-risk design decision: keep the existing shared seam exactly where it is and replace only the transport/execution model beneath `DepthPythonRuntimeBridge` with a long-lived worker process. Concretely, keep `DepthRuntimeManager`, the backend adapters, the detector contract, model-swap semantics, and proving/debug surfaces intact. Add a persistent Python worker mode to `scripts/depth_runtime_infer.py` and a matching session client inside `depth_python_runtime_bridge.gd`. Use newline-delimited JSON over stdin/stdout for the live control channel rather than temp files, sockets, or HTTP. Why: it preserves the existing single-child-process trust boundary, avoids new network/security/configuration surface area, works cross-platform from Godot with ordinary pipes, keeps request/response framing simple, and removes both file I/O churn and process startup/model reload overhead.

The worker should be single-session and single-request-at-a-time. That matches the current usage pattern and is the lowest-risk replacement for the synchronous `OS.execute(...)` bridge. The worker owns one active loaded runtime at a time, keyed by the existing `runtime_key` / artifact path semantics from `REF-02`. `probe` should become `ensure_loaded(model_spec)` inside the worker. `infer` should reuse the already loaded session when the runtime key matches. When the runtime key changes because Derrick swaps models or a family selects a different artifact, the worker should unload the current backend session and then load the new one before servicing the next inference. This preserves the existing shared seam and swap behavior exactly: model swapping still happens by changing `depth.model.artifact_path`; `DepthRuntimeManager` still resolves the key and decides whether the active runtime changed; only the implementation behind the bridge becomes persistent.

Transport/protocol choice: line-delimited JSON messages with one request and one response per line. Required request types: `hello`, `probe`, `infer`, `reload`, `shutdown`, and optionally `ping`. Required response fields should continue the current truth-first contract (`ok`, `status`, `runtime_stage`, `failure_code`, `failure_message`, `active_model_summary`, `sample_metrics`, `timing_ms`) and add worker observability fields (`worker_pid`, `worker_generation`, `request_id`, `worker_uptime_ms`, `model_loaded`, `model_runtime_key`, `model_reload_count`). This gives us a stable protocol with no temp files and minimal new moving parts.

Worker lifecycle design:
- Bridge startup: lazily start the worker on first `probe_runtime()` or `infer()` call, not at Godot boot.
- Handshake: worker emits a `hello` response with version/capabilities after spawn so the bridge can fail fast if protocol mismatches.
- Load/reuse: the worker loads the backend session the first time a runtime key is requested; repeated inferences with the same key reuse the session.
- Reload: if `model_spec.runtime_key` changes, the worker unloads the old session and loads the new one inside the same process.
- Shutdown: `DepthRuntimeManager.shutdown()` → adapter unload → bridge sends `shutdown` best-effort, then kills the process only if graceful exit times out.
- Idle handling: no extra idle reaper in the first implementation. Keep the worker alive until explicit unload/shutdown to maximize performance and minimize state transitions.

Error recovery / restart behavior:
- If the worker crashes, exits, deadlocks, or returns malformed JSON, the bridge should mark runtime status `failed` or `blocked` truthfully, capture bridge-level failure codes such as `worker_spawn_failed`, `worker_protocol_failed`, `worker_exited`, `worker_timeout`, or `worker_bad_response`, and then clear the session handle.
- On the next request, the bridge should automatically spawn a fresh worker once. If that second attempt also fails, return the failure up through the existing seam without looping forever.
- If a load/reload fails for a new model, the old session should already be considered invalid for the new runtime key; report the failure honestly rather than silently falling back to the prior model.
- If per-frame inference fails after a successful load, keep the worker alive unless the failure proves the session is poisoned. First implementation can treat backend exceptions during inference as request failures, not automatic process-kill triggers, unless repeated failures show the session is unusable.

Timing/debug fields needed so the performance work stays observable:
- Preserve current `timing_ms.preprocess`, `infer`, `postprocess`, `total` from `REF-04`.
- Add `timing_ms.bridge_roundtrip` in Godot.
- Add `timing_ms.transport_write`, `transport_read`, and `queue_wait` if measurable cheaply.
- Add `timing_ms.worker_load` for first load or reload paths.
- Add `timing_ms.session_reused` as a bool or `session_warm` field.
- Add worker/debug state fields: `worker_mode` (`process_per_request` vs `persistent_stdio`), `worker_pid`, `worker_generation`, `worker_uptime_ms`, `worker_alive`, `worker_restart_count`, `model_runtime_key`, `model_loaded`, `model_load_count`, `model_reload_count`, `last_request_id`, `last_worker_error`.
- Surface these fields through `DepthPythonRuntimeBridge.get_debug_state()` and therefore through `DepthRuntimeManager` into `gesture_debug.depth_runtime` so `REF-06` can keep telling the truth.

Recommended implementation order and risk notes:
1. Add the protocol and worker loop to `scripts/depth_runtime_infer.py` without removing the current file-based single-shot mode. Keep backward compatibility first.
2. Extend `DepthPythonRuntimeBridge` with a persistent-session path behind a toggle/default, but leave the current single-shot path available as an immediate fallback.
3. Route current adapters through the persistent path, preserving current result/debug shapes.
4. Add targeted tests for startup, reuse, reload-on-runtime-key-change, graceful shutdown, and crash/restart behavior.
5. Measure before/after on the same preview frame and same three approved models; record warm vs cold timings distinctly.
6. Only after that, simplify or remove the one-process-per-request path if the persistent path proves stable.

Risk notes:
- Biggest implementation risk is pipe management / non-blocking I/O from Godot, not model logic. Keep the request pattern strictly synchronous and one-at-a-time to avoid turning this into a concurrency project.
- Do not move model-selection logic out of `DepthRuntimeManager`; that would widen scope and risk architecture drift.
- Do not introduce sockets first. They add more failure modes than value for a local single-child worker.
- Do not add multi-model residency or parallel inferences in the first slice. One loaded model at a time is enough to kill the dominant overhead.
- Preserve the current truth surface by explicitly reporting whether timings came from a cold load, reload, or warm reused session.

Explicit preservation note: this design preserves the existing shared seam and swap behavior because `DepthRuntimeManager`, the detector contract, and the backend adapters stay the public architecture. The only change is that `DepthPythonRuntimeBridge` stops paying process startup + model load costs on every call. Model swapping still flows through the current artifact-path/runtime-key seam, and the proving/debug surfaces continue to read one centralized truth source instead of backend-specific ad hoc state.

---

### Task 2: Implement persistent worker / reduced-overhead runtime path

**Bead ID:** `Pending`  
**SubAgent:** `primary`  
**Role:** `coder`  
**References:** `REF-02`, `REF-03`, `REF-04`, `REF-07`  
**Prompt:** Implement the performance-first runtime improvement behind the existing shared seam. Replace or augment the current one-process-per-inference bridge with a persistent worker or similarly reduced-overhead path. Preserve truthful status/debug reporting, model swap behavior, and clean shutdown/restart handling. Record real before/after timing evidence.

**Folders Created/Deleted/Modified:**
- `src/`
- `scripts/`
- `.testbed/tests/`
- `.plans/mediapipe-python/`
- `../aerobeat-vendor-mediapipe-python/runtime/`

**Files Created/Deleted/Modified:**
- runtime bridge / worker / tests / plan files touched by implementation

**Status:** ⏳ Pending

**Results:** Pending.

---

### Task 3: QA depth runtime performance improvement

**Bead ID:** `Pending`  
**SubAgent:** `primary`  
**Role:** `qa`  
**References:** `REF-02`, `REF-03`, `REF-04`, `REF-05`, `REF-06`  
**Prompt:** Independently verify the performance-first runtime improvement. Confirm the shared seam still swaps models truthfully, that the worker/runtime lifecycle is stable, and that before/after timing claims are supported by real measurements on this machine.

**Folders Created/Deleted/Modified:**
- runtime / tests / plan files touched by implementation

**Files Created/Deleted/Modified:**
- runtime / tests / plan files touched by implementation

**Status:** ⏳ Pending

**Results:** Pending.

---

### Task 4: Audit performance-first seam truthfulness

**Bead ID:** `Pending`  
**SubAgent:** `primary`  
**Role:** `auditor`  
**References:** `REF-01`, `REF-02`, `REF-03`, `REF-04`, `REF-05`, `REF-06`  
**Prompt:** Independently audit that the claimed performance improvements are real, that the shared seam remains architecture-clean, and that the plan/debug surfaces honestly represent latency, worker state, fallback behavior, and remaining bottlenecks.

**Folders Created/Deleted/Modified:**
- runtime / tests / plan files touched by implementation

**Files Created/Deleted/Modified:**
- runtime / tests / plan files touched by implementation

**Status:** ⏳ Pending

**Results:** Pending.

---

### Task 5: Deepen live runtime integration after performance work

**Bead ID:** `Pending`  
**SubAgent:** `primary`  
**Role:** `coder`  
**References:** `REF-01`, `REF-02`, `REF-05`, `REF-06`  
**Prompt:** After performance work is verified, deepen live runtime integration of the real depth signal into boxing replay/live flows. Prefer incremental, truthful live usage over broad speculative wiring. Keep backend-specific logic behind the shared seam.

**Folders Created/Deleted/Modified:**
- `src/`
- `.testbed/`
- `.plans/mediapipe-python/`

**Files Created/Deleted/Modified:**
- detector / proving / tests / plan files touched by implementation

**Status:** ⏳ Pending

**Results:** Pending.

---

### Task 6: QA deeper runtime integration

**Bead ID:** `Pending`  
**SubAgent:** `primary`  
**Role:** `qa`  
**References:** `REF-05`, `REF-06`  
**Prompt:** Independently verify the deeper live runtime integration after the performance seam lands. Confirm the live depth signal is actually used where claimed, that boxing debug/proving surfaces stay truthful, and that there are no regressions in model swapping or blocked-state reporting.

**Folders Created/Deleted/Modified:**
- detector / proving / tests / plan files touched by implementation

**Files Created/Deleted/Modified:**
- detector / proving / tests / plan files touched by implementation

**Status:** ⏳ Pending

**Results:** Pending.

---

### Task 7: Audit deeper runtime integration

**Bead ID:** `Pending`  
**SubAgent:** `primary`  
**Role:** `auditor`  
**References:** `REF-05`, `REF-06`  
**Prompt:** Independently audit that the deeper runtime integration is genuinely live where claimed, that it still respects the shared seam architecture, and that the plan/debug surfaces remain honest about limitations and fallback behavior.

**Folders Created/Deleted/Modified:**
- detector / proving / tests / plan files touched by implementation

**Files Created/Deleted/Modified:**
- detector / proving / tests / plan files touched by implementation

**Status:** ⏳ Pending

**Results:** Pending.

---

## Final Results

**Status:** ⚠️ Partial

**What We Built:** Task 1 only so far: a concrete lowest-risk performance design centered on replacing the per-inference Python subprocess with a persistent stdio worker while preserving the current shared seam, model swap behavior, and truth-first debug/proving surfaces.

**Reference Check:** `REF-02` / `REF-03` / `REF-04` were directly reviewed and the design keeps their current architecture boundary intact. `REF-06` is explicitly preserved as the truth surface for runtime-worker state and latency evidence.

**Commits:**
- Pending.

**Lessons Learned:** The cleanest win is below the seam, not above it. The manager/adapter/detector boundary is already the right shape; the expensive part is paying process startup, temp-file I/O, and model/session reconstruction on every request.

---

*Updated on 2026-06-20*
