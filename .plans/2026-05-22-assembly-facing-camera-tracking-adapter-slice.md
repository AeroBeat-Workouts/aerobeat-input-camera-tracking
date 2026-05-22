# AeroBeat Input Camera Tracking — Assembly-Facing CameraTracking Adapter Slice

**Date:** 2026-05-22  
**Status:** Draft / execution ready  
**Agent:** Cookie 🍪

---

## Goal

Migrate the assembly-facing `src/input_provider.gd` path onto the new continuous `CameraTracking` contract as a **contract-first adapter**, while keeping runtime/vendor/lifecycle ownership upstream and retaining only narrow compatibility shims that are still honestly needed.

---

## Overview

The current repo truth has changed in two important ways. First, the upstream lane is now green enough to consume: `aerobeat-tool-camera-tracking` owns the continuous public `CameraTracking` service, repeated `tracking_updated(frame)` delivery, latest-frame reads through `get_tracking_frame()`, live-camera source switching, and the conservative public landmark payload `id/x/y/z/v`. Second, this repo already has the gameplay-consumption seam needed to ingest that contract: `src/providers/camera_tracking_provider.gd` plus `src/tracking_frame_adapter.gd` can already translate the upstream frame stream into the Boxing + Flow detector substrate.

What has **not** migrated yet is the actual assembly-facing addon entrypoint. `src/input_provider.gd` still directly instantiates `providers/mediapipe_provider.gd`, still owns local provider startup/stop semantics, and still publishes itself to the input-core provider-session registry as though the old local provider lane were the primary truth. That means the next honest slice is not “replace everything.” It is to make `input_provider.gd` act as a thin assembly-facing adapter that can prefer an existing `CameraTracking` session and route its public provider behavior through `CameraTrackingProvider`, while preserving a clearly provisional legacy fallback only where the assembly/runtime integration story is not yet settled.

This slice must stay strict on ownership boundaries. This repo may adapt, discover, attach to, and republish input-facing behavior. It should **not** recreate backend registration policy, vendor runtime startup, preview orchestration policy, replay semantics, or final session-discovery architecture that belongs upstream or in later assembly/core reconciliation. The narrow win is: assembly consumers stop being hard-wired to the legacy MediaPipe provider when a truthful `CameraTracking` session is already present.

---

## REFERENCES

| ID | Description | Path |
| --- | --- | --- |
| `REF-01` | Coordination plan for this wave | `/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.plans/2026-05-22-assembly-facing-input-migration.md` |
| `REF-02` | Prior proving-first contract consumer slice | `/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.plans/2026-05-22-first-continuous-contract-consumer-slice.md` |
| `REF-03` | Current assembly-facing addon entrypoint | `/workspace/projects/aerobeat/aerobeat-input-camera-tracking/src/input_provider.gd` |
| `REF-04` | Contract-driven provider seam | `/workspace/projects/aerobeat/aerobeat-input-camera-tracking/src/providers/camera_tracking_provider.gd` |
| `REF-05` | Tracking-frame adapter seam | `/workspace/projects/aerobeat/aerobeat-input-camera-tracking/src/tracking_frame_adapter.gd` |
| `REF-06` | Current assembly-facing adapter tests and registry expectations | `/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.testbed/tests/unit/test_input_provider_adapter.gd` |
| `REF-07` | Current contract-provider tests | `/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.testbed/tests/unit/test_camera_tracking_provider.gd` |
| `REF-08` | Input-core provider session registry contract | `/workspace/projects/aerobeat/aerobeat-input-core/src/runtime/provider_session_registry.gd` |
| `REF-09` | Upstream continuous public-state slice now green | `/workspace/projects/aerobeat/aerobeat-tool-camera-tracking/.plans/2026-05-22-continuous-tracking-public-state-slice.md` |
| `REF-10` | Upstream public service contract | `/workspace/projects/aerobeat/aerobeat-tool-camera-tracking/src/CameraTracking.gd` |
| `REF-11` | Repo README current truth and deferred notes | `/workspace/projects/aerobeat/aerobeat-input-camera-tracking/README.md` |

---

## Scope decisions from planning

### What can migrate now

1. **`input_provider.gd` can stop being hard-wired to `mediapipe_provider.gd`.**  
   It can instead become a contract-first adapter that routes through `CameraTrackingProvider` when a `CameraTracking` session is explicitly supplied or discoverable in-runtime (`REF-03`, `REF-04`, `REF-09`, `REF-10`).

2. **Assembly-facing provider semantics can be preserved on top of the contract lane.**  
   Signal re-emission, position/velocity getters, camera-device queries, tracking-confidence reads, and input-core session publication can stay at the `AeroInputProvider` layer while the underlying tracking truth comes from `CameraTrackingProvider` (`REF-03`, `REF-04`, `REF-06`, `REF-08`).

3. **Contract-first assembly verification can be added repo-locally now.**  
   The repo already has unit coverage for the detector-side provider seam; the next honest proving layer is unit/integration coverage that `input_provider.gd` can wrap that seam and still satisfy the assembly-facing interface and registry expectations (`REF-06`, `REF-07`).

### What must stay provisional in this slice

1. **Who creates/finally owns the `CameraTracking` session in product assembly.**  
   This slice may consume a session; it should not define the final product-wide session-discovery/ownership architecture (`REF-08`, `REF-10`, `REF-11`).

2. **Automatic backend registration/runtime startup from `input_provider.gd`.**  
   `CameraTracking.register_backend_factory(...)`, vendor bootstrapping, preview routing, and source-policy ownership remain upstream/proving concerns, not assembly-adapter ownership (`REF-09`, `REF-10`).

3. **Replay/video-file semantics and richer temporal semantics.**  
   `reacquiring`, replay lifecycle, richer body/head/confidence claims, multi-pose guarantees, and deeper `z` meaning remain deferred (`REF-09`, `REF-10`, `REF-11`).

4. **Removal of the old local provider lane.**  
   A legacy fallback may remain temporarily as a compatibility lane while assembly consumers are moved, but it must be explicitly documented as provisional and not treated as the migrated truth (`REF-03`, `REF-11`).

### Acceptable compatibility shims in this slice

1. **Keep `PROVIDER_ID == "mediapipe_python"` for now.**  
   This is acceptable as a compatibility identifier for input-core/session consumers while the product-facing naming/session reconciliation is deferred.

2. **Keep session publication through `AeroProviderSessionRegistry` in `input_provider.gd`.**  
   The published provider can still be the assembly-facing adapter itself, even if its internal source of truth becomes `CameraTrackingProvider`.

3. **Allow an explicit legacy fallback path when no `CameraTracking` session is available.**  
   This is acceptable only if contract-first preference is real and documented, and only if the fallback is clearly described as provisional assembly compatibility.

4. **Allow minimal session injection/autodiscovery helpers.**  
   Example: `set_tracking_session(session)` or a conservative in-tree discovery path for a mounted `CameraTracking` node. This is acceptable if it does not smuggle backend registration/runtime ownership into this repo.

### Strong enough expectations to rely on now

- continuous `CameraTracking.tracking_updated(frame)` updates while the service is running
- `CameraTracking.get_tracking_frame()` returns the latest normalized frame
- live-camera source truth via `get_active_config()` / `change(config)`
- public landmark payload limited to `landmarks[].id/x/y/z/v`
- preview/gameplay orientation truth upstream via `preview_transform.flip_horizontal` and `space = gameplay_normalized`
- contract-provider seam already proven to translate the upstream frame stream into detector events and landmark/velocity reads

### Still-provisional expectations that must not be overclaimed

- final meaning/handling of `reacquiring`
- replay/video-file session behavior
- richer public `confidence`, `head_position`, `head_velocity`, `head_orientation`, `skeleton`
- multi-pose gameplay guarantees
- final assembly-wide `CameraTracking` discovery/ownership pattern
- full removal of the legacy local provider/runtime lane

### What must be proven before claiming the assembly-facing path is migrated

Minimum honest proving bar for this slice:

1. `src/input_provider.gd` **prefers the contract path** when a `CameraTracking` session is supplied or discoverable.
2. Assembly-facing signals/getters/camera-selection/session-publication still behave correctly when the underlying implementation is `CameraTrackingProvider`.
3. Repo-local tests prove contract-mode start/stop/query behavior through `input_provider.gd`, not just through `CameraTrackingProvider` directly.
4. Any remaining legacy fallback is documented as provisional and exercised separately so the repo does not pretend the fallback is the migrated path.
5. No code in this slice reclaims backend registration, vendor runtime boot, replay policy, or preview ownership from upstream.

Important honesty rule: after this slice, it is fair to say **the assembly-facing adapter has a contract-first migrated lane**. It is **not** yet fair to say product assembly no longer depends on provisional fallback/runtime coordination.

---

## Tasks

### Task 1: Implement the assembly-facing CameraTracking adapter slice

**Bead ID:** `aerobeat-input-camera-tracking-0m8`  
**SubAgent:** `primary` (for `coder`)  
**Role:** `coder`  
**References:** `REF-03`, `REF-04`, `REF-05`, `REF-06`, `REF-07`, `REF-08`, `REF-09`, `REF-10`, `REF-11`  
**Prompt:** In `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking`, claim bead `aerobeat-input-camera-tracking-0m8` with `bd update aerobeat-input-camera-tracking-0m8 --status in_progress --json` when you start. Implement the narrowest honest assembly-facing migration slice from `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.plans/2026-05-22-assembly-facing-camera-tracking-adapter-slice.md`. Required scope: refactor `src/input_provider.gd` so the assembly-facing adapter can prefer and wrap `CameraTrackingProvider` when a `CameraTracking` session is explicitly supplied or conservatively discoverable, while preserving the existing `AeroInputProvider`-facing behavior (signals/getters/camera selection/session publication). Acceptable shims: keep `PROVIDER_ID` / shared session key compatibility, keep registry publication in `input_provider.gd`, and keep a clearly provisional legacy fallback when no `CameraTracking` session exists. Add/adjust repo-local tests so `input_provider.gd` itself is proven in contract mode. Do **not** broaden into backend registration ownership, vendor runtime bootstrapping, replay/video-file support, final assembly-wide session discovery architecture, or removal of the legacy lane.

**Folders Created/Deleted/Modified:**
- `/workspace/projects/aerobeat/aerobeat-input-camera-tracking/src/`
- `/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.testbed/tests/`
- `/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.plans/`

**Files Created/Deleted/Modified:**
- `/workspace/projects/aerobeat/aerobeat-input-camera-tracking/src/input_provider.gd`
- `/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.testbed/tests/unit/test_input_provider_adapter.gd`
- `/workspace/projects/aerobeat/aerobeat-input-camera-tracking/README.md`

**Status:** ✅ Complete

**Results:** Implemented the narrow contract-first assembly adapter slice in repo-owned sharable source and kept the compatibility shell intentionally narrow. `src/input_provider.gd` now prefers an explicitly supplied `CameraTracking` session or a conservatively discoverable in-tree `CameraTracking` node, and when one exists it instantiates `CameraTrackingProvider` as the underlying provider lane instead of hard-wiring `mediapipe_provider.gd`. The adapter still publishes itself through the input-core provider-session registry with `PROVIDER_ID == "mediapipe_python"` and shared session key compatibility preserved, but registry metadata now records whether the live lane is `camera_tracking` or the provisional `legacy_mediapipe` fallback.

Added the minimal adapter-side helper surface needed for this slice: `set_tracking_session(session)`, `clear_tracking_session()`, `get_tracking_session()`, `uses_camera_tracking_contract_path()`, and `is_using_legacy_fallback()`. Those helpers do not register backend factories, start upstream runtimes, own preview surfaces, or define final assembly-wide session-discovery architecture; they only let the assembly-facing adapter consume a session when one is already supplied or conservatively discoverable.

Updated `.testbed/tests/unit/test_input_provider_adapter.gd` so the assembly-facing adapter itself is now the primary proving surface for this migration claim. New coverage proves explicit session injection prefers the contract lane, conservative in-tree discovery prefers the contract lane before falling back, contract-mode getters/camera switching/session publication behave through `input_provider.gd`, and the legacy fallback is still available and explicitly marked in published metadata rather than being mistaken for the migrated truth. Updated `README.md` to describe the new adapter truth honestly.

Validation run from repo root:
- `python3 scripts/refresh_testbed_workbench.py` ✅ refreshed `.testbed`, ran `godotenv addons install`, and completed headless import successfully
- `godot --headless --path .testbed --script addons/gut/gut_cmdln.gd -gtest=res://tests/unit/test_input_provider_adapter.gd -gexit` ✅ 9/9 passed
- `godot --headless --path .testbed --script addons/gut/gut_cmdln.gd -gtest=res://tests/unit/test_camera_tracking_provider.gd -gexit` ✅ 4/4 passed
- `godot --headless --path .testbed --script addons/gut/gut_cmdln.gd -gdir=res://tests/unit -ginclude_subdirs -gexit` ⚠️ repo still has unrelated pre-existing failures outside this slice (`test_mediapipe_process.gd`, `test_mediapipe_provider.gd`, `test_proving_harness_trails.gd`); the new adapter tests and existing contract-provider tests passed

---

### Task 2: QA the assembly-facing CameraTracking adapter slice

**Bead ID:** `aerobeat-input-camera-tracking-bl3`  
**SubAgent:** `primary` (for `qa`)  
**Role:** `qa`  
**References:** `REF-03`, `REF-04`, `REF-06`, `REF-07`, `REF-08`, `REF-09`, `REF-10`, `REF-11`  
**Prompt:** In `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking`, wait until bead `aerobeat-input-camera-tracking-bl3` is unblocked, then claim it with `bd update aerobeat-input-camera-tracking-bl3 --status in_progress --json`. Independently QA the assembly-facing adapter slice from `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.plans/2026-05-22-assembly-facing-camera-tracking-adapter-slice.md`. At minimum: prove `src/input_provider.gd` itself prefers/uses the contract lane when a `CameraTracking` session is supplied, prove signals/getters/camera switching/session publication still work in that mode, verify any retained legacy fallback is clearly provisional rather than treated as the migrated path, and confirm the implementation did not reclaim backend registration/runtime/preview ownership or edit addon mirrors. Record exact commands/results/gaps and leave the auditor bead open.

**Folders Created/Deleted/Modified:**
- validation-only use of `/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.testbed/`
- `/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.plans/`

**Files Created/Deleted/Modified:**
- none required unless a minimal QA artifact becomes necessary

**Status:** ⏳ Pending

**Results:** Pending.

---

### Task 3: Audit the assembly-facing CameraTracking adapter slice

**Bead ID:** `aerobeat-input-camera-tracking-yup`  
**SubAgent:** `primary` (for `auditor`)  
**Role:** `auditor`  
**References:** `REF-03`, `REF-04`, `REF-06`, `REF-08`, `REF-09`, `REF-10`, `REF-11`  
**Prompt:** In `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking`, wait until bead `aerobeat-input-camera-tracking-yup` is unblocked, then claim it with `bd update aerobeat-input-camera-tracking-yup --status in_progress --json`. Independently audit the assembly-facing adapter slice against the plan, diff, coder evidence, and QA evidence. Verify that `src/input_provider.gd` now exposes a real contract-first migrated lane on top of `CameraTrackingProvider`, that compatibility shims stayed narrow and honest, that any legacy fallback remained explicitly provisional, and that the slice did not reclaim upstream runtime/lifecycle/vendor/preview ownership. Close the bead only if the migrated lane is genuinely proven at the assembly-facing adapter level.

**Folders Created/Deleted/Modified:**
- `/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.plans/`

**Files Created/Deleted/Modified:**
- audit notes only if needed

**Status:** ⏳ Pending

**Results:** Pending.

---

## Dependency shape

- `aerobeat-input-camera-tracking-0m8` → coder implementation bead
- `aerobeat-input-camera-tracking-bl3` depends on `aerobeat-input-camera-tracking-0m8`
- `aerobeat-input-camera-tracking-yup` depends on `aerobeat-input-camera-tracking-bl3`

---

## Blockers / provisional notes to preserve during execution

1. There is currently no finalized assembly-wide `CameraTracking` session discovery/ownership contract equivalent to the provider-session registry. This slice may add only minimal adapter-side injection/discovery shims, not invent the final architecture.
2. `input_provider.gd` currently publishes a provider session, not a `CameraTracking` session. That publication can remain as a compatibility shell, but it should wrap contract-driven behavior where available rather than pretending the old local provider is still the primary truth.
3. If contract-first adapter wiring reveals missing hooks in `input_provider.gd` for explicit session injection or conservative node discovery, adding those hooks is in scope; adding backend-factory registration and runtime boot policy is not.
4. The current test surface proves `CameraTrackingProvider` directly, but the assembly-facing truth gap is now in `test_input_provider_adapter.gd`. That file must become the primary proving surface for this slice.
5. Beads dependency writes produced a Dolt auto-push warning (`no common ancestor`). Treat that as repo-local Beads sync noise unless it blocks later coordination; the repo-local dependencies were still created successfully.

---

## Final Results

**Status:** ✅ Planning complete / execution ready

**What We Built:** Created the next repo-local execution plan for the assembly-facing migration step and a serialized coder → QA → auditor bead chain focused on turning `src/input_provider.gd` into a contract-first assembly adapter over `CameraTrackingProvider`, without reclaiming upstream runtime/vendor ownership.

**Reference Check:** Planning keeps the continuous upstream contract (`REF-09`, `REF-10`) and existing detector seam (`REF-04`, `REF-05`) as the new truth sources, while treating `src/input_provider.gd` (`REF-03`) and its current tests (`REF-06`) as the narrow migration target. Input-core registry expectations (`REF-08`) are preserved only as compatibility behavior.

**Commits:**
- None yet in this wave.

**Lessons Learned:** The right next move is smaller than “migrate assembly.” It is “migrate the assembly-facing adapter onto the contract-first provider seam, then prove that old input-core-facing behavior still works on top of it.” That keeps the slice honest and avoids re-owning upstream responsibilities.

---

*Prepared on 2026-05-22*