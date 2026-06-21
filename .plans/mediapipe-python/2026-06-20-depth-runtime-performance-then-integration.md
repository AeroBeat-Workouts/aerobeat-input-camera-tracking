# AeroBeat depth runtime performance then integration

**Date:** 2026-06-20  
**Status:** In Progress  
**Last Updated:** 2026-06-20 20:52 EDT  
**Blocked Reason:** None. Task 3.6 QA passed; awaiting Task 3.7 audit, with cross-family shared runtime/session pooling still approved as the next implementation follow-up after audit.  
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
- `src/depth/`
- `scripts/`
- `.testbed/tests/unit/`
- `.plans/mediapipe-python/`

**Files Created/Deleted/Modified:**
- `src/depth/depth_python_runtime_bridge.gd`
- `src/depth/depth_model_adapter.gd`
- `src/depth/depth_runtime_types.gd`
- `scripts/depth_runtime_infer.py`
- `.testbed/tests/unit/test_depth_runtime_manager.gd`
- `.plans/mediapipe-python/2026-06-20-depth-runtime-performance-then-integration.md`

**Status:** ✅ Complete

**Results:** Implemented the performance-first runtime improvement entirely behind the existing shared seam from `REF-02` / `REF-03` / `REF-04`. The worker shape changed slightly from the Task 1 design note: instead of stdio, the live path now uses a local authenticated persistent TCP worker because that is the lowest-risk fit for Godot 4.6's built-in process + socket primitives while still keeping the worker private to the host process and avoiding detector-level architecture leakage.

Concrete implementation details:
- `scripts/depth_runtime_infer.py` now supports both modes: the legacy single-shot `--request-file/--response-file` path still works, and a new `--tcp-worker` mode hosts one persistent in-process runtime session that caches the active backend/model by `runtime_key`.
- The Python worker now keeps the heavy backend session alive across requests, tracks `model_load_count` / `model_reload_count`, returns truthful worker/session metadata, and reports `timing_ms.worker_load` plus `timing_ms.session_warm` so cold-vs-warm behavior is visible.
- `src/depth/depth_python_runtime_bridge.gd` now lazily spawns that worker, waits on a ready file, sends newline-delimited JSON over localhost TCP, measures bridge transport timing, restarts once on transport/protocol failure, and reports truthful worker/debug state (`worker_mode`, `worker_pid`, `worker_generation`, `worker_restart_count`, `worker_uptime_ms`, `model_loaded`, `model_runtime_key`, `model_load_count`, `model_reload_count`, `last_request_id`, `last_worker_error`).
- `DepthRuntimeManager` still owns artifact-path/runtime-key truth. No backend/model selection logic was moved into detector code; the detector-facing seam stayed unchanged.
- `src/depth/depth_model_adapter.gd` now calls bridge shutdown during unload so worker teardown follows the existing adapter/runtime lifecycle and model swaps remain clean/truthful.
- `src/depth/depth_runtime_types.gd` now seeds the new worker/debug fields, and `.testbed/tests/unit/test_depth_runtime_manager.gd` now verifies the persistent worker mode, truthful worker state, and warm-session reuse behavior.

Real timing evidence recorded on this machine with the repo vendor Python runtime and the real `fastdepth_224_onnx` model over the same preview frame:
- Legacy single-shot path: 5 end-to-end wall-clock runs averaged **222.65 ms** per inference.
- Legacy single-shot runtime internals: those same runs averaged **102.10 ms** of model/session load time and **63.68 ms** of in-worker infer total time, confirming process/model bring-up dominated wall time.
- Persistent worker cold probe/load: first load cost **105.85 ms** wall / **103.68 ms** `worker_load`, matching the old cold-load cost but paying it once.
- Persistent worker warm inference: 5 end-to-end warm requests averaged **33.98 ms** wall overall, with the last 3 requests averaging **21.15 ms** wall; worker-reported infer totals averaged **33.43 ms** and all warm requests reported `session_warm=true`.
- Steady-state speedup versus the legacy one-process-per-inference wall time was **6.55x** on the measured run.

Validation run:
- `godot --headless --path .testbed --script addons/aerobeat-vendor-godot-unit-test/gut_cmdln.gd -gtest=res://tests/unit/test_depth_runtime_manager.gd -gexit`
- Result: **4/4 passed**.

Caveats / remaining truth notes:
- The live speed win is for repeated requests on the same runtime key; first load still pays the real backend/model load cost once, now surfaced explicitly through `worker_load` and `session_warm`.
- The manager still unloads/recreates the adapter on model swap, so swapping models remains truthful and clean, but cross-model swaps are not optimized into a shared multi-model resident cache in this slice.
- The legacy file-based single-shot path remains available inside the Python entrypoint for compatibility and benchmarking, but the live Godot bridge now defaults to the persistent worker path.

---

### Task 3: QA depth runtime performance improvement

**Bead ID:** `Pending`  
**SubAgent:** `primary`  
**Role:** `qa`  
**References:** `REF-02`, `REF-03`, `REF-04`, `REF-05`, `REF-06`  
**Prompt:** Independently verify the performance-first runtime improvement. Confirm the shared seam still swaps models truthfully, that the worker/runtime lifecycle is stable, and that before/after timing claims are supported by real measurements on this machine.

**Folders Created/Deleted/Modified:**
- `.plans/mediapipe-python/`

**Files Created/Deleted/Modified:**
- `.plans/mediapipe-python/2026-06-20-depth-runtime-performance-then-integration.md`

**Status:** ❌ Failed

**Results:** Independently QA-validated the performance claim and the model/backend seam with real runs on this machine, then found one truthfulness/lifecycle bug that keeps this task from passing yet.

Validation runs executed:
- `godot --headless --path .testbed --script addons/aerobeat-vendor-godot-unit-test/gut_cmdln.gd -gtest=res://tests/unit/test_depth_runtime_manager.gd -gexit`
- `python3 /tmp/qa_depth_runtime_benchmark.py` (real wall-clock benchmark against legacy single-shot bridge vs persistent worker)
- `godot --headless --path .testbed --script /tmp/qa_depth_runtime_lifecycle.gd` (real seam/swap/shutdown debug-state probe)

What QA confirmed as true:
- The performance win is real for repeated requests on the same runtime key. FastDepth ONNX legacy single-shot averaged **223.23 ms wall** across 5 runs, while the persistent worker averaged **29.11 ms wall** across 5 warm runs, with the last 3 warm runs averaging **21.65 ms wall**.
- The cold-load cost still exists and is now honestly surfaced. FastDepth persistent `probe` measured **107.12 ms wall** with **104.22 ms** reported as `worker_load`, which matches the same-order cost seen in the legacy single-shot path (**105.92 ms** average `worker_load`).
- Warm-session reuse is real and truthfully reported for repeated requests on the same runtime key: all measured warm FastDepth requests and all measured warm Depth Anything V2 Small requests reported `session_warm=true`.
- The shared seam still swaps models/backend truthfully at the manager/debug level. A FastDepth ONNX run reported `backend_id=onnx`, `family_id=fastdepth_224_onnx`, then a reconfigured OpenVINO run reported `backend_id=openvino`, `family_id=midas_openvino_v21_small_256`, with different worker PIDs showing the manager currently unloads the old adapter/worker and starts a fresh worker for the new model rather than hot-reloading one persistent worker across model swaps.
- Warm behavior is model-dependent and should stay documented honestly. On this host, Depth Anything V2 Small persistent warm inference averaged **338.38 ms wall** across 3 runs after a **453.23 ms** cold probe/load, so the persistent worker removes bridge/process/model-reload churn but does **not** make the heavier model cheap.

Issue found:
- `DepthModelAdapter.unload()` / `DepthRuntimeManager.shutdown()` leaves stale worker truth in the debug state after shutdown. In the headless lifecycle probe, the actual worker exited successfully (`exited_after_shutdown=true` in the direct Python worker benchmark), but `manager.get_debug_state()` after `shutdown()` still reported `worker_alive=true`, `worker_pid` still populated, and `model_loaded=true`. So the runtime lifecycle itself appears stable, but the shared debug surface is currently **not truthful after shutdown/unload**. That means this QA task fails until the shutdown path clears or refreshes those worker/model fields.

QA conclusion:
- Performance improvement claim: **verified**.
- Shared model/backend seam truth during ready/infer/swap: **verified**.
- Worker/runtime lifecycle stability: **mostly verified operationally**, but **fails truthfulness on shutdown state reporting**.

---

### Task 3.5: Fix shutdown-state debug truth for persistent worker runtime

**Bead ID:** `aerobeat-input-camera-tracking-7iso`  
**SubAgent:** `primary`  
**Role:** `coder`  
**References:** `REF-02`, `REF-03`, `REF-04`, `REF-06`  
**Prompt:** Fix the shutdown/unload debug truth gap in the persistent-worker runtime seam. After `DepthRuntimeManager.shutdown()` / adapter unload, shared debug state must no longer report stale worker/model fields like `worker_alive=true`, populated `worker_pid`, or `model_loaded=true` once the worker has actually exited. Keep the fix inside the runtime bridge / manager debug seam, preserve truthful swap behavior, update the active plan with actual results, run relevant validation, commit/push repo-file changes by default, and close the bead with a concrete reason when done.

**Folders Created/Deleted/Modified:**
- `src/depth/`
- `.testbed/tests/unit/`
- `.plans/mediapipe-python/`

**Files Created/Deleted/Modified:**
- `src/depth/depth_model_adapter.gd`
- `src/depth/depth_runtime_manager.gd`
- `.testbed/tests/unit/test_depth_runtime_manager.gd`
- `.plans/mediapipe-python/2026-06-20-depth-runtime-performance-then-integration.md`

**Status:** ✅ Complete

**Results:** Fixed the shutdown/unload truth gap entirely inside the runtime bridge / manager debug seam from `REF-02` / `REF-06`, without touching detector-facing runtime usage or the measured performance path.

Concrete implementation details:
- `src/depth/depth_model_adapter.gd` now snapshots the bridge debug state immediately after `_runtime_bridge.shutdown()`, so adapter-level debug state preserves the bridge's cleared post-shutdown worker/model truth instead of retaining the last pre-shutdown ready state.
- `src/depth/depth_runtime_manager.gd` now routes reconfiguration teardown through `_release_adapter()` and merges the adapter's post-unload debug state before nulling the adapter, so manager-level shared debug output also reflects the cleared worker/model fields after shutdown/config reload.
- No transport/protocol/inference-path behavior changed. The persistent worker still serves warm requests the same way, and model/backend swap behavior stays truthful because the manager still recreates adapters per runtime-key/model change.

Truth fix outcome:
- After `DepthRuntimeManager.shutdown()`, shared debug state now reports `worker_alive=false`, `worker_pid=0`, `model_loaded=false`, and `model_runtime_key=""` instead of leaving stale ready-state values behind after the worker has already exited.
- This also covers the adapter unload path used during manager reconfiguration, so teardown no longer overstates worker/model readiness between configurations.

Validation run:
- `godot --headless --path .testbed --script addons/aerobeat-vendor-godot-unit-test/gut_cmdln.gd -gtest=res://tests/unit/test_depth_runtime_manager.gd -gexit`
- Result: **5/5 passed**.

Test coverage added:
- `.testbed/tests/unit/test_depth_runtime_manager.gd` now includes `test_shutdown_clears_worker_and_model_debug_truth()`, which proves a real ready worker/model becomes truthfully cleared after `manager.shutdown()`.

---

### Task 3.6: QA shutdown-state debug truth fix

**Bead ID:** `aerobeat-input-camera-tracking-49bk`  
**SubAgent:** `primary`  
**Role:** `qa`  
**References:** `REF-02`, `REF-03`, `REF-04`, `REF-06`  
**Prompt:** Independently verify the shutdown-state debug truth fix. Confirm the worker can still shut down cleanly, that post-shutdown debug state no longer overstates readiness/aliveness/model-loaded fields, and that performance/swap behavior did not regress. Update the active plan with actual QA findings and close the bead with a concrete reason when done.

**Folders Created/Deleted/Modified:**
- `src/depth/`
- `.testbed/tests/unit/`
- `.plans/mediapipe-python/`

**Files Created/Deleted/Modified:**
- runtime / tests / plan files touched by implementation

**Status:** ✅ Complete

**Results:** Independently QA-validated the shutdown-state truth fix, worker exit behavior, model/backend swap behavior, and current performance on this machine.

Validation runs executed:
- `godot --headless --path .testbed --script addons/aerobeat-vendor-godot-unit-test/gut_cmdln.gd -gtest=res://tests/unit/test_depth_runtime_manager.gd -gexit`
- `godot --headless --path .testbed --script /tmp/qa_depth_runtime_shutdown_and_swap.gd`
- `python3 /tmp/qa_depth_runtime_legacy_benchmark.py`
- Shell PID verification immediately after the lifecycle probe: `ps -p <fastdepth_pid>` and `ps -p <openvino_pid>`

What QA confirmed as true:
- The shutdown truth fix holds at the shared manager/debug surface. After a real ready OpenVINO runtime was shut down, `manager.get_debug_state()` reported `runtime_status=unloaded`, `runtime_stage=idle`, `worker_alive=false`, `worker_pid=0`, `model_loaded=false`, and `model_runtime_key=""` instead of retaining stale ready-state fields.
- The worker still shuts down cleanly. In the live lifecycle probe, FastDepth used worker PID `3368021` and the swapped OpenVINO runtime used worker PID `3368074`; both PIDs were confirmed exited immediately after the headless run completed.
- Model/backend swap behavior did not regress. A FastDepth ready state still reported `backend_id=onnx` / `family_id=fastdepth_224_onnx`, then a reconfigured OpenVINO ready state reported `backend_id=openvino` / `family_id=midas_openvino_v21_small_256`, with a distinct worker PID for the swapped runtime.
- FastDepth persistent-worker performance remains in the same verified range as the prior QA pass. This run measured a cold FastDepth `ensure_runtime_ready()` at **168.86 ms wall** with **112.59 ms** reported `worker_load`, then three warm inferences at **74.36 ms**, **30.67 ms**, and **30.84 ms** wall, with the last warm request reporting **20.03 ms** worker `total`. The first warm request was slower than the steady-state requests, but the stable warm range remained ~30 ms wall / ~20-24 ms worker total.
- The legacy single-shot benchmark still shows the persistent path has not regressed back toward cold-per-request costs. Five direct legacy runs averaged **222.06 ms wall**, **57.44 ms** worker `total`, and **107.98 ms** `worker_load`, so the current warm persistent path remains materially faster in steady state.

QA conclusion:
- Shutdown-state debug truth fix: **verified**.
- Clean worker shutdown after the fix: **verified**.
- Swap truth/performance regression check: **verified**.
- Issues found: **none blocking** in this QA slice.

---

### Task 3.7: Audit shutdown-state debug truth fix

**Bead ID:** `aerobeat-input-camera-tracking-zjnh`  
**SubAgent:** `primary`  
**Role:** `auditor`  
**References:** `REF-02`, `REF-03`, `REF-04`, `REF-06`  
**Prompt:** Independently audit that the shutdown-state debug truth gap is actually fixed, that the plan/debug surfaces now tell the truth after unload/shutdown, and that the persistent-worker seam remains architecture-clean and truthful. Close the bead if it passes or report the blocking gap if it fails.

**Folders Created/Deleted/Modified:**
- `src/depth/`
- `.testbed/tests/unit/`
- `.plans/mediapipe-python/`

**Files Created/Deleted/Modified:**
- runtime / tests / plan files touched by implementation

**Status:** ⏳ Pending

**Results:** Pending.

---

### Task 3.8: Design cross-family shared runtime/session pooling by runtime key

**Bead ID:** `aerobeat-input-camera-tracking-o3k0`  
**SubAgent:** `primary`  
**Role:** `research`  
**References:** `REF-02`, `REF-03`, `REF-05`, `REF-06`  
**Prompt:** Design the lowest-risk way to share one live depth runtime/backend instance across straight_punch, hook, and uppercut when they resolve to the same runtime key. The design must preserve family-specific threshold semantics while consolidating identical backend/model/artifact work, keep truthful debug/proving visibility per family, and avoid leaking backend-specific behavior into detector code.

**Folders Created/Deleted/Modified:**
- `src/depth/`
- `src/detectors/`
- `.plans/mediapipe-python/`

**Files Created/Deleted/Modified:**
- performance design notes / plan updates
- `.plans/mediapipe-python/2026-06-20-depth-runtime-performance-then-integration.md`

**Status:** ⏳ Pending

**Results:** Pending.

---

### Task 3.9: Implement cross-family shared runtime/session pooling

**Bead ID:** `aerobeat-input-camera-tracking-q8oi`  
**SubAgent:** `primary`  
**Role:** `coder`  
**References:** `REF-02`, `REF-03`, `REF-05`, `REF-06`  
**Prompt:** Implement cross-family shared runtime/session pooling by runtime key so identical depth backends/models/artifacts are not duplicated just because multiple punch families use depth. Preserve family-specific threshold logic, truthful per-family debug state, clean shutdown/release behavior, and the existing shared seam boundaries.

**Folders Created/Deleted/Modified:**
- `src/depth/`
- `src/detectors/`
- `.testbed/tests/`
- `.plans/mediapipe-python/`

**Files Created/Deleted/Modified:**
- runtime manager / bridge / detector / tests / plan files touched by implementation

**Status:** ⏳ Pending

**Results:** Pending.

---

### Task 3.10: QA cross-family shared runtime/session pooling

**Bead ID:** `aerobeat-input-camera-tracking-j08l`  
**SubAgent:** `primary`  
**Role:** `qa`  
**References:** `REF-02`, `REF-03`, `REF-05`, `REF-06`  
**Prompt:** Independently verify that identical runtime keys across punch families now share one backend/session instance, that per-family semantics/debug state remain truthful, and that performance/lifecycle behavior remains stable.

**Folders Created/Deleted/Modified:**
- runtime / detector / tests / plan files touched by implementation

**Files Created/Deleted/Modified:**
- runtime / detector / tests / plan files touched by implementation

**Status:** ⏳ Pending

**Results:** Pending.

---

### Task 3.11: Audit cross-family shared runtime/session pooling

**Bead ID:** `aerobeat-input-camera-tracking-yv9o`  
**SubAgent:** `primary`  
**Role:** `auditor`  
**References:** `REF-02`, `REF-03`, `REF-05`, `REF-06`  
**Prompt:** Independently audit that cross-family pooling is genuinely sharing one runtime/backend instance for identical runtime keys, that family-local threshold semantics remain clean, and that plan/debug surfaces still tell the truth about what is shared vs family-specific.

**Folders Created/Deleted/Modified:**
- runtime / detector / tests / plan files touched by implementation

**Files Created/Deleted/Modified:**
- runtime / detector / tests / plan files touched by implementation

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

**What We Built:** Tasks 1-2 landed a persistent authenticated localhost TCP depth worker behind the existing `DepthRuntimeManager` seam. Task 3 QA first found a shutdown-state truth gap, Task 3.5 fixed it inside the runtime bridge/manager debug seam, and Task 3.6 then re-verified truthful shutdown, clean worker exit, swap behavior, and the previously claimed FastDepth steady-state performance win.

**Reference Check:** `REF-02` / `REF-03` / `REF-04` still hold the architecture boundary: runtime-key ownership and model-path truth remain in `DepthRuntimeManager`, the transport/worker lifecycle stays inside `DepthPythonRuntimeBridge`, and no backend/model logic was pushed up into `REF-05`. `REF-06` is now truthful for this shutdown slice as well: after unload/shutdown, the surfaced worker/model fields no longer overstate readiness or aliveness.

**Commits:**
- Pending.

**Lessons Learned:** The big win really was below the seam. Warm repeated inference got dramatically faster once process start + model/session reconstruction moved out of the steady-state path. The follow-up QA also proved that truthful lifecycle reporting needs explicit teardown-state propagation, not just a clean runtime exit underneath.

---

*Updated on 2026-06-20*
