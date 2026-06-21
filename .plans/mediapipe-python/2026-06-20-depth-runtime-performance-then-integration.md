# AeroBeat depth runtime performance then integration

**Date:** 2026-06-20  
**Status:** In Progress  
**Last Updated:** 2026-06-21 08:10 EDT  
**Blocked Reason:** None — Task 7 exposed a real config/profile blocker, and follow-up Tasks 8-10 now materialize the approved next seam to enable threshold-backed punch-family depth in the shipped boxing profile and re-verify playtest readiness.  
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
| `REF-08` | Shipped boxing gesture profile contract | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/assets/boxing.gesture_detection.yaml` |
| `REF-09` | Boxing profile/config truth test | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.testbed/tests/unit/test_camera_tracking_config_profiles.gd` |

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

**Status:** ❌ Failed

**Results:** Independently audited the cross-family pooling seam with a fresh repro instead of trusting the prior QA note, and the audit agrees with QA on both the good news and the blocking lifecycle gap.

Audit validation runs executed:
- `godot --headless --path .testbed --script addons/aerobeat-vendor-godot-unit-test/gut_cmdln.gd -gtest=res://tests/unit/test_depth_runtime_manager.gd -gexit`
- `godot --headless --path .testbed --script /tmp/audit_cross_family_pooling.gd`
- External hold-open OS-level repro: `godot --headless --path .testbed --script /tmp/audit_zombie_hold.gd` plus shell `ps --ppid <godot_pid> -o pid=,stat=,comm=` checks while the parent Godot process stayed alive.

What the audit verified as true:
- Same-key sharing is genuine. `straight_punch` and `hook` on the same FastDepth ONNX artifact resolved to the same `shared_runtime_key`, reported the same worker PID, and exposed `shared_runtime_refcount=2` with both families listed in `shared_runtime_family_claims`.
- Different-key separation is genuine. `uppercut` on the OpenVINO artifact resolved to a different `shared_runtime_key` and a different worker PID, so pooling is not collapsing unlike runtime keys together.
- Family-local truth remains clean while sharing. Each manager still reported its own `family` and its own `last_sample_metrics` / timing overlay, so the shared runtime facts did not overwrite family-local observation truth.
- The plan/debug surfaces are telling the truth about what is shared versus family-specific. Shared facts (`shared_runtime_key`, refcount, family claims, shared/not-shared state, worker PID) matched the live repro, while manager-local family fields still differed appropriately between `straight_punch`, `hook`, and `uppercut`.
- Partial release behavior is correct. Releasing one claimant left the same worker alive for the remaining same-key family and truthfully dropped the refcount/claims to one family.

Blocking audit finding:
- The zombie-worker report is a real blocker, not an acceptable transient. The independent hold-open repro left the Godot parent alive for 15 seconds after three same-key acquire/release cycles, and shell `ps` checks showed three separate unreaped child workers still attached to that live parent as zombies:
  - `3379548 Zs python`
  - `3379571 Zs python`
  - `3379594 Zs python`
- That means final release is not merely showing a momentary exit race; repeated live-session churn accumulates zombie children until the parent Godot process exits. The manager/debug surface is truthful about logical shutdown, but the OS-level lifecycle is not actually cleaned up.

Audit conclusion:
- Same-key pooling: **passed**.
- Different-key separation: **passed**.
- Family-local threshold/debug semantics: **passed**.
- Truthfulness of shared-vs-family debug surfaces: **passed**.
- Final-release worker lifecycle / reaping: **failed**, and this is a real blocker for advancing to the next integration seam.

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

**Status:** ✅ Complete

**Results:** Reviewed `REF-02`, `REF-03`, and `REF-05` together and confirmed the duplication problem sits at the family-manager layer, not inside detector threshold logic. Right now `pose_detector_substrate.gd` owns one `DepthRuntimeManager` per family (`_depth_runtime_managers[family]`), and each manager resolves a `runtime_key`, loads an adapter, and lets `DepthPythonRuntimeBridge` own its own persistent worker/session. That means `straight_punch`, `hook`, and `uppercut` can all truthfully ask for the same artifact/backend/runtime key and still spin up duplicate live runtimes because sharing stops at the per-family manager boundary. The family-specific semantics are still clean today because thresholds/evaluation windows stay in detector-side family state, but the backend/model/artifact work is duplicated.

Lowest-risk pooling design: keep `DepthRuntimeManager` as the family-facing facade, but move actual live runtime ownership into a new shared depth-layer pool keyed by the existing `runtime_key` from `REF-02`. Concretely, add a `DepthSharedRuntimePool` (or similarly named depth-layer helper) that owns one live adapter/bridge lease per runtime key, plus lightweight pooled entry records containing the resolved `model_spec`, adapter instance, refcount/claimers, and the last shared runtime debug snapshot. Each family manager still does its own `_resolve_model_spec()` and still exposes `ensure_runtime_ready()`, `infer_relative_depth()`, and family debug state, but instead of constructing/unloading its own adapter directly it acquires/releases a shared runtime entry from the pool. This preserves the clean detector seam because detector code continues talking only to `DepthRuntimeManager`; backend-specific behavior still lives below that seam in the depth layer.

Recommended ownership split:
- `DepthRuntimeManager` keeps family config, artifact resolution, family-local summary/debug overlay, and detector-facing inference contract.
- New pooled runtime object (for example `DepthRuntimeLease` or `DepthSharedRuntimeEntry`) owns the actual adapter instance and backend lifecycle for one `runtime_key`.
- `DepthPythonRuntimeBridge` stays per live runtime instance, not per family. If three families resolve to the same key, they should all land on the same bridge/worker/session through the shared entry.
- `pose_detector_substrate.gd` should keep one manager per family for truthful family-local semantics/debug, but those managers should be constructed with or bound to one shared pool instance instead of being fully isolated runtime owners.

Critical semantic rule: family thresholds must remain outside the pool. `sample_request.evaluation`, detector-side motion windows, grace/rearm timers, and emitted gate results remain family/state specific in `pose_detector_substrate.gd`. The pooled runtime only returns backend-normalized sample truth (`sample_metrics`, timing, runtime status, provider/load state, artifact/runtime identity). Each family then applies its own threshold semantics to that shared sample stream. This keeps straight-punch forward-depth spike gating separate from hook/uppercut closeness-delta gating even when the same runtime produced the underlying depth sample.

Debug/proving design: preserve one truthful per-family debug state, but split it into shared-runtime truth plus family overlay truth. Each `DepthRuntimeManager.get_debug_state()` should continue returning a family-shaped dictionary so proving surfaces in `REF-06` do not lose per-family visibility. Add a nested shared block or mirrored fields that make reuse obvious, for example: `shared_runtime_key`, `shared_runtime_owner_id`, `shared_runtime_refcount`, `shared_runtime_family_claims`, `shared_worker_pid`, `shared_worker_generation`, and `shared_model_runtime_key`. Then keep the existing family-local fields (`family`, `depth_enabled`, family failure summary, last sample metrics/timing as observed by that family request) truthful per manager. That way hook and uppercut can honestly show that they are sharing one worker/session while still exposing their own gate outcomes and latest per-family sample interpretation. Avoid storing one global `last_sample_metrics` blindly on the shared entry as the only truth source, because that would make the most recent family request overwrite proving visibility for the others.

Recommended implementation approach for Task 3.9:
1. Add a new depth-layer pool file, e.g. `src/depth/depth_shared_runtime_pool.gd`, with acquire/release/get_debug helpers keyed by `runtime_key`.
2. Refactor `DepthRuntimeManager` so `_active_runtime_key`/`_adapter` become a reference to a pooled entry/lease rather than direct ownership of the adapter.
3. Keep `_resolve_model_spec()` and `_apply_model_spec_to_debug()` in `DepthRuntimeManager`; they are still the right architecture boundary for family config → runtime key resolution.
4. Update `_configure_depth_runtime_managers()` / `_get_depth_runtime_manager()` in `pose_detector_substrate.gd` so all family managers share one pool instance for the substrate lifetime.
5. Make shutdown/reconfigure release the family claim; only unload the underlying adapter/worker when the last family using that runtime key releases it or when the runtime key changes.
6. Add unit coverage for: same-key families share one entry, different keys do not share, refcount drops correctly on reconfigure/shutdown, and per-family debug still reports truthful family plus shared-runtime fields.

Risk notes for implementation: the biggest correctness risk is lifecycle churn during `configure()`, `reset()`, and family runtime-key changes, because `pose_detector_substrate.gd` currently reconfigures all managers eagerly and `DepthRuntimeManager.configure_from_family()` immediately releases its owned adapter. The pooling implementation should therefore use explicit acquire/release semantics and only destroy the shared runtime when the last claimant is gone. The biggest truth risk is accidentally turning per-family debug into one shared mutable blob; fix that by treating shared worker/runtime facts as pooled state and family gating/sample summaries as manager-local overlays. The lowest-risk bridge boundary is unchanged: do not let detector code know whether the runtime came from a pool or a dedicated instance, and do not move threshold semantics into `DepthPythonRuntimeBridge` or the Python worker.

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
- `src/depth/depth_shared_runtime_pool.gd`
- `src/depth/depth_runtime_manager.gd`
- `src/depth/depth_runtime_types.gd`
- `src/detectors/pose_detector_substrate.gd`
- `.testbed/tests/unit/test_depth_runtime_manager.gd`
- `.plans/mediapipe-python/2026-06-20-depth-runtime-performance-then-integration.md`

**Status:** ✅ Complete

**Results:** Added `src/depth/depth_shared_runtime_pool.gd` and refactored `src/depth/depth_runtime_manager.gd` so family managers now acquire/release pooled shared runtimes by `runtime_key` while keeping family-local debug overlays and detector-facing semantics intact. `src/detectors/pose_detector_substrate.gd` now binds all family managers to one substrate-lifetime shared pool, and `src/depth/depth_runtime_types.gd` exposes shared-runtime debug fields (`shared_runtime_key`, refcount, family claim list, claimed/shared flags). Extended `.testbed/tests/unit/test_depth_runtime_manager.gd` to cover same-key sharing, different-key isolation, and last-claimer shutdown; `godot --headless --path .testbed --script addons/aerobeat-vendor-godot-unit-test/gut_cmdln.gd -gtest=res://tests/unit/test_depth_runtime_manager.gd -gexit` passed 8/8 tests. Implementation intentionally kept threshold/evaluation logic above the depth seam; pooling only shares backend/model/artifact runtime ownership and worker/session lifecycle.

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

**Status:** ❌ Failed

**Results:** Independently QA-validated the new cross-family pooling seam with real runtime calls, then found one blocking lifecycle bug that keeps this slice from passing yet.

Validation runs executed:
- `godot --headless --path .testbed --script addons/aerobeat-vendor-godot-unit-test/gut_cmdln.gd -gtest=res://tests/unit/test_depth_runtime_manager.gd -gexit`
- `godot --headless --path .testbed --script /tmp/qa_cross_family_pooling.gd`
- Direct process-state checks from the headless probe via `ps -p <pid> -o stat=`.

What QA confirmed as true:
- Same-key sharing is real. `straight_punch` and `hook` configured to the same FastDepth ONNX artifact both resolved to the same `shared_runtime_key`, reported the same worker PID (`3376672` in the probe run), and showed `shared_runtime_refcount=2` with both families listed in `shared_runtime_family_claims`.
- Different-key separation is real. `uppercut` configured to the OpenVINO artifact resolved to a distinct `shared_runtime_key` and a different worker PID (`3376695`), so pooling did not collapse unlike backends/models together.
- Per-family debug overlays stayed truthful while sharing one backend/session. `straight_punch` debug still reported `family=straight_punch` with its own last sample metrics (`wrist_closeness=-0.615728...`), while `hook` still reported `family=hook` with a different last sample (`wrist_closeness=-0.245138...`). Sharing the runtime did not overwrite the family-local observation fields in either manager.
- Same-key pooling avoided duplicate loads. Both same-key families reported `model_load_count=1` and `model_reload_count=0`, which matches a single backend/session instance being loaded once and then reused.
- Warm performance remained in the previously validated range on the shared worker. After the initial FastDepth load (`worker_load=114.00 ms`, `bridge_roundtrip=123.84 ms`), the shared-session warm inferences landed at `23.93 ms` worker total / `30.31 ms` bridge roundtrip for `hook`, with the peer `straight_punch` request also warm (`session_warm=true`).
- Partial release behavior is correct. After `straight_punch.shutdown()`, `hook.ensure_runtime_ready()` still reported the same worker PID (`3376672`), `shared_runtime_refcount=1`, `shared_runtime_shared=false`, and only `hook` remaining in `shared_runtime_family_claims`. A mid-share release does not tear down the runtime out from under the remaining family.

Blocking issue found:
- Final-release worker cleanup is not actually complete while the parent Godot process is still alive. After the last claimant released the shared FastDepth runtime, and after `uppercut` later released its own separate runtime, both worker PIDs remained present in `ps` for the full 5-second wait window. Their `ps` state was `Zs`, which means the workers had exited but were left behind as zombie child processes until the parent headless Godot process terminated. The manager/debug surface reported shutdown truthfully, but the OS-level lifecycle did not fully clean up/reap the child processes during the live session.

QA conclusion:
- Same-key pooling: **verified**.
- Different-key separation: **verified**.
- Per-family semantics/debug truth: **verified**.
- Release behavior when one family lets go and another still claims the shared runtime: **verified**.
- Final-release lifecycle stability: **failed** due to unreaped zombie worker processes after shutdown.

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

### Task 3.12: Fix zombie-worker reaping on final pooled runtime release

**Bead ID:** `aerobeat-input-camera-tracking-xnxx`  
**SubAgent:** `primary`  
**Role:** `coder`  
**References:** `REF-02`, `REF-03`, `REF-04`, `REF-06`  
**Prompt:** Fix the final-release worker cleanup bug in the persistent/pooling runtime seam. After the last claimant releases a pooled runtime, the Python worker must not remain as an unreaped zombie child under the live Godot parent. Keep the fix inside the runtime bridge / shared pool / runtime-management layer, preserve truthful debug state and clean family semantics, update the active plan with actual results, run relevant validation, commit/push repo-file changes by default, and close the bead with a concrete reason when done.

**Folders Created/Deleted/Modified:**
- `src/depth/`
- `.testbed/tests/unit/`
- `.plans/mediapipe-python/`

**Files Created/Deleted/Modified:**
- runtime bridge / shared pool / tests / plan files touched by implementation

**Status:** ✅ Complete

**Results:** Implemented the final-release fix inside the runtime-management seam instead of the family/model layers. The shared runtime pool now retains the bridge entry when refcount falls to zero, calls a new bridge-level `unload` request so the Python process stays alive but drops its active model session, and reuses that same cached bridge on the next same-key acquire. This avoids letting the Godot-owned child process exit on the last pooled release, which removes the unreaped-zombie failure while preserving same-key pooling and family claim/refcount semantics. The Python worker now also arms Linux `PR_SET_PDEATHSIG` so retained bridge workers die with the parent process instead of lingering if Godot exits unexpectedly. Added a regression unit test proving the final claimant can release and later reacquire the same cached runtime key without spawning a new worker PID. Local validation passed with `python3 -m py_compile scripts/depth_runtime_infer.py`, `godot --headless --path .testbed --script addons/aerobeat-vendor-godot-unit-test/gut_cmdln.gd -gtest=res://tests/unit/test_depth_runtime_manager.gd -gexit`, and a live hold-open repro (`/tmp/task312_zombie_hold.gd` plus host-side `ps --ppid <godot_pid>`) that showed only a live `Ssl python` child and no `Z*` zombie child after repeated final releases. Landed in commit `42e763d` (`Fix pooled depth worker zombie cleanup`).

---

### Task 3.13: QA zombie-worker reaping fix

**Bead ID:** `aerobeat-input-camera-tracking-27qd`  
**SubAgent:** `primary`  
**Role:** `qa`  
**References:** `REF-02`, `REF-03`, `REF-04`, `REF-06`  
**Prompt:** Independently verify the zombie-worker reaping fix. Confirm same-key pooling still works, final-release cleanup no longer leaves zombie Python children under a live Godot parent, and performance/debug truth did not regress. Update the active plan with actual QA findings and close the bead with a concrete reason when done.

**Folders Created/Deleted/Modified:**
- `src/depth/`
- `.testbed/tests/unit/`
- `.plans/mediapipe-python/`

**Files Created/Deleted/Modified:**
- runtime / tests / plan files touched by implementation

**Status:** ✅ Complete

**Results:** Independently QA-validated the zombie-worker reaping fix with real same-key pooling, final-release, and live-process inspection runs on this machine.

Validation runs executed:
- `godot --headless --path .testbed --script addons/aerobeat-vendor-godot-unit-test/gut_cmdln.gd -gtest=res://tests/unit/test_depth_runtime_manager.gd -gexit`
- `godot --headless --path .testbed --script /tmp/task313_holdopen.gd`
- Host-side process inspection while the Godot parent stayed alive: `ps --ppid 3389290 -o pid=,stat=,comm=`
- Post-exit cleanup check: `ps -p 3389312,3389335 -o pid=,stat=,comm=`

What QA confirmed as true:
- Same-key pooling still works. `straight_punch` and `hook` on the same FastDepth artifact both resolved to worker PID `3389312`, reported `shared_runtime_refcount=2`, and kept that same PID after peer release (`hook_pid_after_peer_shutdown=3389312`).
- Final-release same-key reuse still works. After both same-key claimants released, a fresh reacquire of the same runtime key reused the same cached worker PID (`reacquired_pid=3389312`) rather than spawning a new Python worker.
- Different-key separation still works. `uppercut` on the OpenVINO artifact used a different worker PID (`3389335`), so pooling still stays scoped to identical runtime keys.
- The zombie-worker failure is fixed in the live hold-open repro. While the Godot parent `3389290` remained alive after final releases, host-side `ps` showed only live sleeping Python children (`3389312 Ssl python`, `3389335 Ssl python`) and no `Z*` zombie entries. After the Godot parent exited, `ps -p 3389312,3389335` returned nothing, so the retained idle workers also did not outlive the parent.
- Released family-manager debug truth did not regress. After final release, both released managers reported `runtime_status=unloaded`, `runtime_stage=idle`, `worker_alive=false`, `worker_pid=0`, and `model_loaded=false`, which stays consistent with the family-facing seam even though the shared pool intentionally retains idle bridge workers under the hood.
- Performance truth did not regress. In the live same-key pooled run, all three warm FastDepth inference requests reported `session_warm=true`; the last two warm requests averaged **26.53 ms** bridge roundtrip and **21.19 ms** worker `total`, which is still in the previously verified ~20-30 ms steady-state range. The first warm request in the sequence was slower (**103.54 ms** bridge / **102.31 ms** worker total), but subsequent steady-state requests returned to the expected range.
- Unit coverage still passes after the fix. `test_depth_runtime_manager.gd` passed **9/9**.

QA conclusion:
- Same-key pooling after the fix: **verified**.
- Final-release zombie cleanup under a live Godot parent: **verified**.
- Released debug-state truth: **verified**.
- Performance/debug regression check: **verified**.
- Issues found: **none blocking** in this QA slice.

---

### Task 3.14: Audit zombie-worker reaping fix

**Bead ID:** `aerobeat-input-camera-tracking-dwdi`  
**SubAgent:** `primary`  
**Role:** `auditor`  
**References:** `REF-02`, `REF-03`, `REF-04`, `REF-06`  
**Prompt:** Independently audit that the zombie-worker reaping issue is actually fixed, that cross-family pooling remains architecture-clean and truthful, and that plan/debug surfaces still tell the truth about shutdown/release behavior. Close the bead if it passes or report the blocking gap if it fails.

**Folders Created/Deleted/Modified:**
- `src/depth/`
- `.testbed/tests/unit/`
- `.plans/mediapipe-python/`

**Files Created/Deleted/Modified:**
- runtime / tests / plan files touched by implementation

**Status:** ✅ Complete

**Results:** Independently audited the zombie-worker reaping fix with fresh runtime/unit/process checks instead of trusting the prior QA pass, and this audit passes.

Audit validation runs executed:
- `godot --headless --path .testbed --script addons/aerobeat-vendor-godot-unit-test/gut_cmdln.gd -gtest=res://tests/unit/test_depth_runtime_manager.gd -gexit`
- `godot --headless --path .testbed --script /tmp/task314_audit_holdopen.gd`
- Host-side live-process inspection while the Godot parent stayed alive: `ps --ppid 3391319 -o pid=,ppid=,stat=,comm=` and `ps -p 3391342,3391365 -o pid=,ppid=,stat=,comm=`
- Post-exit cleanup check after the hold-open parent finished: `ps -p 3391319,3391342,3391365 -o pid=,ppid=,stat=,comm=`

What the audit verified as true:
- Same-key pooling still works. `straight_punch` and `hook` on the FastDepth ONNX artifact both resolved to worker PID `3391342`, and the shared-manager debug state reported `shared_runtime_refcount=2` with both families claimed.
- Cross-family pooling remains architecture-clean and truthful. `uppercut` on the OpenVINO artifact resolved to a different runtime key and worker PID (`3391365`), so pooling is still scoped strictly by `runtime_key` rather than collapsing unlike backend/model families together.
- Released-family debug truth remains honest even with retained idle workers under the hood. After `straight_punch.shutdown()`, that released manager reported `runtime_status=unloaded`, `runtime_stage=idle`, `worker_alive=false`, `worker_pid=0`, `model_loaded=false`, and `shared_runtime_refcount=0`, while the still-claiming `hook` manager truthfully continued to report the live shared worker with refcount `1`.
- Final release no longer accumulates zombies under a live Godot parent. In the live hold-open repro, after final release of the same-key FastDepth families and separate release of the OpenVINO family, host-side `ps` showed only live sleeping Python children (`3391342 Ssl python`, `3391365 Ssl python`) under the still-running Godot parent and no `Z*` zombie children.
- Retained-worker behavior remains honest. A fresh reacquire of the released FastDepth runtime key reused the same worker PID (`3391342`), reported `model_load_count=2`, surfaced a truthful reacquire load (`worker_load=16.27 ms`, `session_warm=false` on ready), and then returned to normal warm behavior on the next inference (`session_warm=true`, `bridge_roundtrip=30.34 ms`, `total=22.90 ms`).
- Parent-exit cleanup still holds. After the hold-open Godot parent exited, `ps -p 3391319,3391342,3391365` returned nothing, so the retained workers did not outlive the parent.

Audit conclusion:
- Same-key pooling: **verified**.
- Different-key separation: **verified**.
- Released-family debug truth: **verified**.
- Final-release zombie-worker cleanup under a live parent: **verified**.
- Retained-worker/reacquire truthfulness: **verified**.
- Issues found: **none blocking** in this audit slice.

---

### Task 4: Audit performance-first seam truthfulness

**Bead ID:** `aerobeat-input-camera-tracking-j5s9`  
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

### Task 4.1: Fix stale shutdown failure residue in performance seam debug state

**Bead ID:** `aerobeat-input-camera-tracking-amn7`  
**SubAgent:** `primary`  
**Role:** `coder`  
**References:** `REF-02`, `REF-03`, `REF-04`, `REF-06`  
**Prompt:** Fix the remaining shutdown/release truth gap in the performance-first runtime seam. After a blocked infer (for example missing `preview_image_path`), a later `DepthRuntimeManager.shutdown()` / release must not leave stale `failure_code` or `failure_message` residue once runtime state has been reset to unloaded/idle. Keep the fix inside the runtime bridge / manager / shared-pool debug seam, preserve current performance and pooling behavior, update the active plan with actual results, run relevant validation, commit/push repo-file changes by default, and close the bead with a concrete reason when done.

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

**Results:** Fixed the remaining blocked-infer shutdown/release truth gap entirely inside the runtime-management seam from `REF-02` / `REF-03` / `REF-06`, without changing transport, inference, pooling, or detector-facing behavior.

Concrete implementation details:
- `src/depth/depth_model_adapter.gd` now explicitly clears `failure_code` and `failure_message` when adapter unload completes, so the pooled-release seam cannot keep reporting a stale blocked-infer error after the runtime has been unloaded to idle.
- `src/depth/depth_runtime_manager.gd` now also clears `failure_code` and `failure_message` during `shutdown()` after shared-runtime release, so the family-facing debug surface no longer preserves residue from an earlier blocked infer once the manager reports `runtime_status=unloaded` / `runtime_stage=idle`.
- No worker lifecycle, pooling, runtime-key sharing, or warm-path performance behavior changed; this was a debug-truth cleanup only.

Truth fix outcome:
- Repro sequence covered by the new regression: call `infer_relative_depth({}, ...)` so the bridge reports `preview_image_missing`, then call `manager.shutdown()`. After shutdown, `manager.get_debug_state()` now reports `failure_code=""` and `failure_message=""` alongside the existing unloaded/idle truth, instead of leaving the stale blocked-infer residue behind.
- This also hardens the pooled release path because release-time adapter debug snapshots are now residue-free when the runtime is no longer loaded.

Validation run:
- `godot --headless --path .testbed --script addons/aerobeat-vendor-godot-unit-test/gut_cmdln.gd -gtest=res://tests/unit/test_depth_runtime_manager.gd -gexit`
- Result: **10/10 passed**.

Test coverage added:
- `.testbed/tests/unit/test_depth_runtime_manager.gd` now includes `test_shutdown_clears_failure_residue_after_blocked_infer()`, which proves a real blocked infer (`preview_image_missing`) is visible before shutdown and truthfully cleared after shutdown.

---

### Task 4.2: QA stale shutdown failure residue fix

**Bead ID:** `aerobeat-input-camera-tracking-5361`  
**SubAgent:** `primary`  
**Role:** `qa`  
**References:** `REF-02`, `REF-03`, `REF-04`, `REF-06`  
**Prompt:** Independently verify the stale shutdown failure-residue fix. Confirm that after a blocked infer followed by shutdown/release, runtime debug state no longer carries stale failure residue, and that performance, pooling, and shutdown truth did not regress. Update the active plan with actual QA findings and close the bead with a concrete reason when done.

**Folders Created/Deleted/Modified:**
- `src/depth/`
- `.testbed/tests/unit/`
- `.plans/mediapipe-python/`

**Files Created/Deleted/Modified:**
- runtime / tests / plan files touched by implementation

**Status:** ✅ Complete

**Results:** Independently QA-validated the stale shutdown failure-residue fix with both the repo unit suite and a fresh headless lifecycle/pooling regression probe on this machine.

Validation runs executed:
- `godot --headless --path .testbed --script addons/aerobeat-vendor-godot-unit-test/gut_cmdln.gd -gtest=res://tests/unit/test_depth_runtime_manager.gd -gexit`
- `godot --headless --path .testbed --script /tmp/task42_qa_residue_and_regression.gd`

What QA confirmed as true:
- The stale blocked-infer residue fix holds. In the fresh repro, `infer_relative_depth({}, ...)` truthfully failed with `status=blocked` and `error_code=preview_image_missing`, and `manager.get_debug_state()` before shutdown still exposed `failure_code=preview_image_missing` with the expected preview-image-path message.
- After `manager.shutdown()`, the same manager truthfully cleared the stale residue: `failure_code=""`, `failure_message=""`, `runtime_status=unloaded`, `runtime_stage=idle`, `worker_alive=false`, `worker_pid=0`, and `model_loaded=false`.
- Unit coverage still passes after the fix. `test_depth_runtime_manager.gd` passed **10/10** and includes the explicit regression `test_shutdown_clears_failure_residue_after_blocked_infer()`.
- Same-key pooling did not regress. In the fresh shared-pool probe, `hook` and a peer `straight_punch` manager on the same FastDepth artifact both resolved to worker PID `3408599`, while `uppercut` on the OpenVINO artifact resolved to a different worker PID `3408629`.
- Partial-release shutdown truth did not regress. After the peer same-key manager shut down, the remaining `hook` manager still reported the same worker PID `3408599` with `shared_runtime_refcount=1`, confirming the shared runtime stayed alive for the last claimant.
- Released-manager shutdown truth did not regress. After final shutdown, both released managers reported `runtime_status=unloaded`, `runtime_stage=idle`, `worker_alive=false`, `worker_pid=0`, and `model_loaded=false`.
- Warm performance remained in the previously validated range. In the fresh FastDepth warm sequence, end-to-end wall times were **61.98 ms**, **33.70 ms**, and **31.02 ms**, with worker `total` times of **56.54 ms**, **26.50 ms**, and **20.12 ms**. The last warm request reported `session_warm=true`, `bridge_roundtrip=30.36 ms`, and worker `total=20.12 ms`, which stays aligned with the prior steady-state ~20-30 ms warm behavior.

QA conclusion:
- Stale shutdown failure residue after blocked infer: **verified fixed**.
- Pooling regression check: **verified**.
- Shutdown/debug truth regression check: **verified**.
- Performance regression check: **verified**.
- Issues found: **none blocking** in this QA slice.

---

### Task 4.3: Audit stale shutdown failure residue fix

**Bead ID:** `aerobeat-input-camera-tracking-8xsm`  
**SubAgent:** `primary`  
**Role:** `auditor`  
**References:** `REF-02`, `REF-03`, `REF-04`, `REF-06`  
**Prompt:** Independently audit that the stale shutdown failure-residue issue is actually fixed, that plan/debug surfaces now tell the truth after blocked-infer then shutdown/release sequences, and that the performance-first seam is ready to pass its broader audit. Close the bead if it passes or report the blocking gap if it fails.

**Folders Created/Deleted/Modified:**
- `src/depth/`
- `.testbed/tests/unit/`
- `.plans/mediapipe-python/`

**Files Created/Deleted/Modified:**
- runtime / tests / plan files touched by implementation

**Status:** ✅ Complete

**Results:** Independently audited the stale blocked-infer shutdown/release truth fix with fresh repo-unit and headless lifecycle/pooling checks instead of trusting the prior QA pass, and this audit passes.

Audit validation runs executed:
- `godot --headless --path .testbed --script addons/aerobeat-vendor-godot-unit-test/gut_cmdln.gd -gtest=res://tests/unit/test_depth_runtime_manager.gd -gexit`
- `godot --headless --path .testbed --script /tmp/task43_audit_residue_and_readiness.gd`

What the audit verified as true:
- The exact blocked-infer sequence now tells the truth. In a fresh same-key pooled repro, `hook.infer_relative_depth({}, ...)` returned `status=blocked` with `error_code=preview_image_missing`, and `hook.get_debug_state()` before shutdown still exposed that same failure residue while the shared FastDepth worker stayed live (`worker_pid=3414465`, `shared_runtime_refcount=2`).
- The shutdown/release path now clears that residue truthfully. After `hook.shutdown()` on the blocked manager, its family-facing debug state reported `runtime_status=unloaded`, `runtime_stage=idle`, `failure_code=""`, `failure_message=""`, `worker_alive=false`, `worker_pid=0`, `model_loaded=false`, and `shared_runtime_refcount=0` instead of retaining the blocked-infer residue.
- Partial pooled release did not regress. The peer same-key `straight_punch` manager remained attached to the same live worker PID `3414465` after `hook.shutdown()`, and its refreshed debug state truthfully dropped to `shared_runtime_refcount=1` with only `straight_punch` still claimed.
- Different-key isolation did not regress. A fresh `uppercut` OpenVINO manager used worker PID `3414495`, distinct from the FastDepth same-key pair, so release/failure cleanup did not collapse unlike runtime keys together.
- Warm performance truth did not regress. In the same fresh audit run, two repeated FastDepth inferences after ready both reported `session_warm=true`, `model_load_count=1`, and `model_reload_count=0`; their wall-visible bridge timings were `72.38 ms` then `30.36 ms`, with worker `total` timings `67.13 ms` then `23.93 ms`, which stays consistent with the previously established warm-session seam instead of falling back to cold-per-request behavior.
- Repo regression coverage still passes. `test_depth_runtime_manager.gd` passed **10/10**, including the explicit blocked-infer residue regression plus the pooling/shutdown truth checks added in prior slices.

Audit conclusion:
- Blocked-infer → shutdown/release failure-residue truth: **verified fixed**.
- Pooling/shutdown truth regression check: **verified**.
- Warm performance truth regression check: **verified**.
- Broader performance-first seam readiness: **ready to proceed to Task 4 broader audit**.
- Issues found: **none blocking** in this audit slice.

---

### Task 5: Deepen live runtime integration after performance work

**Bead ID:** `aerobeat-input-camera-tracking-vpms`  
**SubAgent:** `primary`  
**Role:** `coder`  
**References:** `REF-01`, `REF-02`, `REF-05`, `REF-06`  
**Prompt:** After performance work is verified, deepen live runtime integration of the real depth signal into boxing replay/live flows. Prefer incremental, truthful live usage over broad speculative wiring. Keep backend-specific logic behind the shared seam.

**Folders Created/Deleted/Modified:**
- `src/`
- `.testbed/`
- `.plans/mediapipe-python/`

**Files Created/Deleted/Modified:**
- `src/providers/camera_tracking_provider.gd`
- `.testbed/tests/unit/test_camera_tracking_provider.gd`
- `.plans/mediapipe-python/2026-06-20-depth-runtime-performance-then-integration.md`

**Status:** ✅ Complete

**Results:** Task 5 is now landed as an incremental shared-seam integration slice. `CameraTrackingProvider` now augments provider-owned tracking frames with the tracking session’s current `preview_descriptor`, mirrors `preview_image_path` / `image_path` onto the frame context that downstream depth consumers already understand, and subscribes to `preview_changed` so replay/live preview swaps force a re-poll even when the landmark signature is otherwise stable. That keeps backend-specific preview sourcing inside the shared provider seam while letting existing boxing depth-runtime consumers receive truthful preview-backed frame context in both live-camera and replay polling flows. I also updated provider unit coverage for live-frame preview merging, replay-frame preview merging, and preview-change re-poll behavior, and validated the seam with a targeted headless provider-plumbing script plus the existing depth runtime manager suite (`test_depth_runtime_manager.gd`). QA and audit remain pending as separate Tasks 6-7.

---

### Task 6: QA deeper runtime integration

**Bead ID:** `aerobeat-input-camera-tracking-fr76`  
**SubAgent:** `primary`  
**Role:** `qa`  
**References:** `REF-05`, `REF-06`  
**Prompt:** Independently verify the deeper live runtime integration after the performance seam lands. Confirm the live depth signal is actually used where claimed, that boxing debug/proving surfaces stay truthful, and that there are no regressions in model swapping or blocked-state reporting.

**Folders Created/Deleted/Modified:**
- detector / proving / tests / plan files touched by implementation

**Files Created/Deleted/Modified:**
- detector / proving / tests / plan files touched by implementation

**Status:** ✅ Complete

**Results:** Independently QA-validated the Task 5 provider seam and the downstream boxing/depth consumers on this machine. Code review confirmed the implementation matches the intended seam in `src/providers/camera_tracking_provider.gd`: frames are enriched through `_augment_tracking_frame_runtime_context()` before processing, preview-path data participates in the frame signature (`preview_image_path` / preview revision), and `preview_changed` forces a re-poll so live/replay preview swaps propagate even when landmark signatures stay stable (`src/providers/camera_tracking_provider.gd:245-309, 624-626`). Exact Task 5 unit coverage in `.testbed/tests/unit/test_camera_tracking_provider.gd` also matches those claims: live preview merge, replay preview merge, forced re-poll on preview swap, and boxing live/replay config forwarding (`.testbed/tests/unit/test_camera_tracking_provider.gd:124-199, 378-435`).

Strongest relevant validation run:
- `godot --headless --path .testbed --script addons/aerobeat-vendor-godot-unit-test/gut_cmdln.gd -gdir=res://tests/unit -ginclude_subdirs -gselect test_camera_tracking_provider.gd -gexit` → 14/14 passed.
- `... -gselect test_pose_detector_substrate.gd -gunit_test_name depth_gate -gexit` → 4/4 passed, confirming preview-image-backed depth gating and placeholder closeness truth remain live.
- `... -gselect test_pose_detector_substrate.gd -gunit_test_name same_family -gexit` → 4/4 passed, confirming threshold-blocked reporting remains truthful.
- `... -gselect test_pose_detector_substrate.gd -gunit_test_name per_family_backend -gexit` → 3/3 passed, confirming per-family backend/model routing stays truthful.
- `... -gselect test_boxing_proving_harness_profiles_and_debug.gd -gunit_test_name live_depth_loader -gexit` → 1/1 passed, confirming punch-family inspectors surface live depth loader truth/metrics.
- `... -gselect test_boxing_proving_harness_profiles_and_debug.gd -gunit_test_name per_family -gexit` → 2/2 passed, confirming boxing event-feed and classifier payload surfaces stay truthful under per-family routing.
- `... -gselect test_boxing_proving_harness_profiles_and_debug.gd -gunit_test_name model_open_error -gexit` → 1/1 passed, confirming blocked/model-unavailable UI reporting remains honest.
- `... -gselect test_boxing_proving_harness_profiles_and_debug.gd -gunit_test_name force_ -gexit` → 3/3 passed, confirming proving runtime backend swapping across prototype/disabled/classifier modes still works.
- `... -gselect test_depth_runtime_manager.gd -gexit` → 10/10 passed, including real preview inference plus truthful model/backend swap and blocked-shutdown state coverage.

Net QA result: pass for Task 6 scope. The live depth signal is still consumed where claimed, boxing debug/proving surfaces remain truthful, and no Task 5 regression showed up in model swapping or blocked-state reporting. I also noted two unrelated repo-level red signals outside this slice while probing broader suites (`test_pose_detector_substrate.gd` still has two failing flow tests when run unfiltered, and a broad all-unit attempt surfaced an existing unrelated recursion/stack-overflow path in proving-harness coverage), but those did not reproduce in the targeted Task 5/Task 6 coverage above and are not blockers for this bead. Task 7 audit should proceed.

---

### Task 7: Audit deeper runtime integration

**Bead ID:** `aerobeat-input-camera-tracking-rok8`  
**SubAgent:** `primary`  
**Role:** `auditor`  
**References:** `REF-05`, `REF-06`  
**Prompt:** Independently audit that the deeper runtime integration is genuinely live where claimed, that it still respects the shared seam architecture, and that the plan/debug surfaces remain honest about limitations and fallback behavior.

**Folders Created/Deleted/Modified:**
- detector / proving / tests / plan files touched by implementation

**Files Created/Deleted/Modified:**
- detector / proving / tests / plan files touched by implementation

**Status:** ❌ Failed

**Results:** Independent audit found the Task 5 provider/runtime seam itself is genuinely live, but the broader Task 7 bar is not yet met because the shipped boxing profile still does not enable threshold-backed punch-family depth the way the proving/config contract claims. Code review confirmed the shared seam architecture remains intact: preview-path enrichment stays isolated to `src/providers/camera_tracking_provider.gd` (`_augment_tracking_frame_runtime_context()`, preview-aware frame signatures, and `preview_changed` forced re-poll), while backend/model/depth ownership still lives under `src/detectors/pose_detector_substrate.gd` + `src/depth/depth_runtime_manager.gd` rather than leaking upward into the provider seam.

Strongest relevant validation run on this machine:
- `godot --headless --path .testbed --script addons/aerobeat-vendor-godot-unit-test/gut_cmdln.gd -gtest=res://tests/unit/test_camera_tracking_provider.gd -gexit` → 14/14 passed. Confirms live/replay preview descriptors are merged into tracking frames, preview changes force re-polls, and the provider seam is live where claimed.
- `godot --headless --path .testbed --script addons/aerobeat-vendor-godot-unit-test/gut_cmdln.gd -gtest=res://tests/unit/test_pose_detector_substrate.gd -gunit_test_name=depth_gate -gexit` → 4/4 passed. Confirms the threshold-runtime depth gate logic exists and works when family depth is enabled in substrate coverage.
- `godot --headless --path .testbed --script addons/aerobeat-vendor-godot-unit-test/gut_cmdln.gd -gtest=res://tests/unit/test_boxing_proving_harness_profiles_and_debug.gd -gunit_test_name=live_depth_loader -gexit` → 1/1 passed. Confirms the proving inspector text can surface truthful depth-loader state/metrics, but this is synthetic coverage, not proof that the boxing profile currently enables those paths.
- `godot --headless --path .testbed --script addons/aerobeat-vendor-godot-unit-test/gut_cmdln.gd -gtest=res://tests/unit/test_camera_tracking_config_profiles.gd -gexit` → 3/4 passed, 1 failed. `test_camera_tracking_config_loads_boxing_profile_bundle_from_canonical_paths` fails because the loaded boxing gesture profile returns `hook.backend == "disabled"` and `uppercut.backend == "disabled"`, while the test contract expects both to be `"threshold"` (`.testbed/tests/unit/test_camera_tracking_config_profiles.gd:55-57`).

Direct config audit of `assets/boxing.gesture_detection.yaml` explains the failure and blocks playtest-ready status:
- `straight_punch.backend` is `threshold`, but `straight_punch.threshold.depth.enabled` is still `false`.
- `hook.backend` is still `disabled`, and `hook.threshold.depth.enabled` is also `false`.
- `uppercut.backend` is still `disabled`, and `uppercut.threshold.depth.enabled` is also `false`.
- The proving-harness inspector coverage is honest about these limitations today: its live-depth-loader test explicitly expects straight-punch depth truth only, while hook/uppercut inspector text still says `disabled in selected gesture YAML` (`.testbed/tests/unit/test_boxing_proving_harness_profiles_and_debug.gd:1126-1169`). So the debug/proving surfaces are truthful, but they are truthfully reporting that hook/uppercut threshold-depth is not enabled yet.

Net audit result: fail / blocked for Task 7 scope. The deeper provider/runtime integration is real and the shared seam architecture remains clean, but the boxing profile has not yet been advanced to threshold-backed punch-family depth across the proving-scene-related seams. Precise blocking gap: update the boxing profile/runtime contract so hook + uppercut actually load as `backend: threshold` and enable their family depth blocks (and, if intended, enable straight-punch depth too), then re-run the config-profile + proving/runtime audit. Until that lands, this plan is not ready to call playtest-ready.

### Task 8: Enable shipped boxing punch-family threshold depth profile

**Bead ID:** `aerobeat-input-camera-tracking-qe1u`  
**SubAgent:** `primary`  
**Role:** `coder`  
**References:** `REF-05`, `REF-06`, `REF-08`, `REF-09`  
**Prompt:** Update the shipped boxing gesture profile/runtime contract so boxing punch families are actually configured for threshold-backed depth where the proving/runtime contract now expects it. At minimum, move `hook` and `uppercut` onto `backend: threshold` and enable their `threshold.depth` blocks; also resolve whether `straight_punch.threshold.depth.enabled` should now be true for playtest-ready depth-backed boxing. Keep the architecture seam clean, update or add truthful tests, run the strongest repo-local validation for this slice, update the active plan with actual results, and commit/push repo changes by default.

**Folders Created/Deleted/Modified:**
- `assets/`
- `.testbed/tests/unit/`
- `.plans/mediapipe-python/`

**Files Created/Deleted/Modified:**
- `assets/boxing.gesture_detection.yaml`
- `.testbed/tests/unit/test_camera_tracking_config_profiles.gd`
- proving/runtime tests as needed for truthful contract coverage
- `.plans/mediapipe-python/2026-06-20-depth-runtime-performance-then-integration.md`

**Status:** ✅ Complete

**Results:** Updated the shipped boxing profile contract in `REF-08` so the threshold-backed punch families now agree with the runtime/proving expectations instead of shipping contradictory half-enabled depth state. Chosen contract: `straight_punch`, `hook`, and `uppercut` all ship on `backend: threshold`, and all three families now set `threshold.depth.enabled: true` so the threshold runtime truthfully owns punch-family depth gating for playtest-ready boxing. No provider/backend seam changes were needed; this was a config + contract-truth fix, with tests updated to assert the shipped truth instead of the old disabled state.

Strengthened repo-local coverage in `REF-09` by asserting all three families load with threshold depth enabled, and updated the proving-harness inspector truth test so hook/uppercut now report `enabled in selected gesture YAML` when no runtime debug payload overrides the config truth. Targeted validation on this machine passed:
- `godot --headless --path .testbed --script addons/aerobeat-vendor-godot-unit-test/gut_cmdln.gd -gtest=res://tests/unit/test_camera_tracking_config_profiles.gd -gexit`
- `godot --headless --path .testbed --script addons/aerobeat-vendor-godot-unit-test/gut_cmdln.gd -gtest=res://tests/unit/test_boxing_proving_harness_profiles_and_debug.gd -gunit_test_name=test_punch_family_inspectors_surface_live_depth_loader_truth_and_metrics -gexit`

A broader combined proving-harness sweep was intentionally not used as final evidence for this slice after it re-entered the known scene-backed proving loop / deep callback stack unrelated to the contract assertions under test; the focused inspector/config coverage above exercised the exact changed seam cleanly.

### Task 9: QA shipped boxing punch-family threshold depth profile

**Bead ID:** `aerobeat-input-camera-tracking-hxu4`  
**SubAgent:** `primary`  
**Role:** `qa`  
**References:** `REF-05`, `REF-06`, `REF-08`, `REF-09`  
**Prompt:** Independently verify that the shipped boxing profile now actually enables threshold-backed depth for the intended punch families, that the proving/runtime/config surfaces tell the truth about that enablement, and that blocked/model-swap/runtime behavior did not regress. Run the strongest targeted validation available on this machine, update the active plan with actual QA findings, and close the bead with a concrete reason when done.

**Folders Created/Deleted/Modified:**
- `assets/`
- `.testbed/tests/unit/`
- `.plans/mediapipe-python/`

**Files Created/Deleted/Modified:**
- config / proving / runtime / plan files touched by implementation

**Status:** ⏳ Pending

**Results:** Pending.

### Task 10: Audit shipped boxing punch-family threshold depth profile

**Bead ID:** `aerobeat-input-camera-tracking-t9jq`  
**SubAgent:** `primary`  
**Role:** `auditor`  
**References:** `REF-05`, `REF-06`, `REF-08`, `REF-09`  
**Prompt:** Independently audit that threshold-backed depth is genuinely enabled in the shipped boxing profile for the intended punch families, that proving/runtime/config surfaces remain honest, and that the boxing proving-scene-related seams are ready to call playtest-ready only if the configuration and tests now actually support that claim. Update the active plan with actual audit findings, close the bead if it passes, or record the precise remaining blocker if it fails.

**Folders Created/Deleted/Modified:**
- `assets/`
- `.testbed/tests/unit/`
- `.plans/mediapipe-python/`

**Files Created/Deleted/Modified:**
- config / proving / runtime / plan files touched by implementation

**Status:** ⏳ Pending

**Results:** Pending.

---

## Final Results

**Status:** ⚠️ Partial

**What We Built:** Tasks 1-2 landed a persistent authenticated localhost TCP depth worker behind the existing `DepthRuntimeManager` seam. Task 3 QA first found a shutdown-state truth gap, Task 3.5 fixed it inside the runtime bridge/manager debug seam, and Task 3.6 then re-verified truthful shutdown, clean worker exit, swap behavior, and the previously claimed FastDepth steady-state performance win. Task 3.9 then added runtime-key pooling across punch families, Task 3.10 QA verified that pooling while exposing the final-release zombie-child seam, Task 3.11 audit confirmed the blocker, Task 3.12 fixed that seam by retaining pooled bridge workers and unloading model state instead of letting the Godot-owned child exit, Task 3.13 QA re-verified same-key pooling / no live-session zombies / truthful released-manager debug state, and Task 3.14 audit independently confirmed those same claims with fresh unit, runtime, and host-process checks. Task 4.1 also clears stale blocked-infer `failure_code` / `failure_message` residue during shutdown/release so unloaded/idle runtime truth no longer overstates an old failure, Task 4.2 QA independently verified that residue fix while also reconfirming pooling, shutdown truth, and warm-path performance, and Task 4.3 audit independently confirmed that exact blocked-infer → shutdown/release sequence with a fresh pooled repro. Task 5 then made the provider seam carry live/replay preview image paths into downstream depth consumers, and Task 6 QA verified that integration. Task 7 audit, however, found the plan is still blocked before playtest-ready: the live/shared seam work is real, but the shipped boxing profile still leaves `straight_punch.threshold.depth.enabled = false`, `hook.backend = disabled`, `hook.threshold.depth.enabled = false`, `uppercut.backend = disabled`, and `uppercut.threshold.depth.enabled = false`, so threshold-backed punch-family depth is not yet actually enabled across the boxing proving/runtime contract.

**Reference Check:** `REF-02` / `REF-03` / `REF-04` still hold the architecture boundary: runtime-key ownership and model-path truth remain in `DepthRuntimeManager`, the transport/worker lifecycle stays inside `DepthPythonRuntimeBridge`, and no backend/model logic was pushed up into `REF-05`. After Task 3.14, `REF-06` is aligned again at both the family-facing debug layer and the host-process layer: released managers report truthful unloaded state, the shared runtime pool keeps same-key reuse intact, retained idle workers remain honest under live-parent inspection, and host-side `ps` inspection no longer shows unreaped zombie Python children under a live Godot parent.

**Commits:**
- `42e763d` - Fix pooled depth worker zombie cleanup

**Lessons Learned:** The big win really was below the seam. Warm repeated inference got dramatically faster once process start + model/session reconstruction moved out of the steady-state path. The follow-up QA also proved that truthful lifecycle reporting needs explicit teardown-state propagation, not just a clean runtime exit underneath.

---

*Updated on 2026-06-20*
