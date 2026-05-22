# AeroBeat Input Camera Tracking — First Continuous Contract Consumer Slice

**Date:** 2026-05-22  
**Status:** In progress — coder slice complete; QA/audit pending  
**Agent:** Cookie 🍪

---

## Goal

Move the first honest downstream consumer path in `aerobeat-input-camera-tracking` onto the now-green continuous `CameraTracking` landmark contract without reclaiming upstream runtime, lifecycle, preview, or vendor ownership.

---

## Overview

Repo inspection shows the migration seam exists but is not yet the real proving default. `src/tracking_frame_adapter.gd` and `src/providers/camera_tracking_provider.gd` already let this repo consume normalized `CameraTracking` frames, and `.testbed/tests/unit/test_camera_tracking_provider.gd` proves that the detector substrate can read continuous upstream frames through a fake backend. But the main repo entrypoint (`src/input_provider.gd`) still instantiates the legacy local `mediapipe_provider.gd`, the proving scenes still mount `AutoStartManager`, and `.testbed/scripts/proving_harness.gd` only uses the contract path if a `CameraTracking` node already exists in-scene.

That means the narrowest honest next wave is **not** "port the whole repo." The next wave is to migrate the repo-local proving/consumer path so Boxing + Flow can actually run against a live `CameraTracking` session and the continuous public landmark contract, while intentionally leaving the assembly-facing provider adapter and old sidecar/runtime ownership provisional. This keeps ownership clean: `aerobeat-tool-camera-tracking` stays responsible for source/lifecycle/preview/state truth, and this repo stays responsible for gameplay interpretation of the normalized frames.

The first safe proving scope is therefore **live-camera continuous contract consumption only**. Replay/video-file proving is still out of scope because the upstream contract still defers truthful replay semantics. Multi-pose, rich confidence/body/head/skeleton guarantees, and final `reacquiring` behavior also remain provisional. The migration wave should focus on turning the existing seam into the real `.testbed` proving lane, documenting the boundaries honestly, and adding validation that guards the contract-first path.

---

## REFERENCES

| ID | Description | Path |
| --- | --- | --- |
| `REF-01` | Current coordination plan for this wave | `/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.plans/2026-05-22-input-migration-against-continuous-landmark-contract.md` |
| `REF-02` | Prior repo-local seam/migration plan | `/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.plans/2026-05-21-input-camera-tracking-contract-migration.md` |
| `REF-03` | Current input repo README truth | `/workspace/projects/aerobeat/aerobeat-input-camera-tracking/README.md` |
| `REF-04` | Assembly-facing provider adapter still on legacy provider ownership | `/workspace/projects/aerobeat/aerobeat-input-camera-tracking/src/input_provider.gd` |
| `REF-05` | Contract-driven provider seam | `/workspace/projects/aerobeat/aerobeat-input-camera-tracking/src/providers/camera_tracking_provider.gd` |
| `REF-06` | Tracking-frame adapter seam | `/workspace/projects/aerobeat/aerobeat-input-camera-tracking/src/tracking_frame_adapter.gd` |
| `REF-07` | Current proving harness with conditional contract path | `/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.testbed/scripts/proving_harness.gd` |
| `REF-08` | Current Boxing proving scene still wired around local autostart ownership | `/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.testbed/scenes/boxing_proving.tscn` |
| `REF-09` | Current Flow proving scene still wired around local autostart ownership and prerecorded defaults | `/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.testbed/scenes/flow_proving.tscn` |
| `REF-10` | Repo-local unit proof that the contract provider can consume normalized tracking frames | `/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.testbed/tests/unit/test_camera_tracking_provider.gd` |
| `REF-11` | Upstream continuous public-state slice plan now green enough to consume | `/workspace/projects/aerobeat/aerobeat-tool-camera-tracking/.plans/2026-05-22-continuous-tracking-public-state-slice.md` |
| `REF-12` | Upstream public API and frame contract | `/workspace/projects/aerobeat/aerobeat-tool-camera-tracking/src/CameraTracking.gd` |
| `REF-13` | Upstream current README truth for public continuous semantics | `/workspace/projects/aerobeat/aerobeat-tool-camera-tracking/README.md` |

---

## Scope decisions from planning

### Consumer paths that can migrate now

1. **`CameraTracking` frame ingestion into gameplay detectors**  
   Already viable through `src/tracking_frame_adapter.gd` + `src/providers/camera_tracking_provider.gd` (`REF-05`, `REF-06`, `REF-10`).

2. **Repo-local `.testbed` proving against a live `CameraTracking` session**  
   Viable once the proving scenes/harness instantiate and prefer the upstream session path instead of relying on the local autostart-owned stack (`REF-07`, `REF-08`, `REF-09`, `REF-11`, `REF-12`).

3. **Detector-side Boxing + Flow consumption of normalized landmark arrays**  
   Viable because the detector substrate still consumes the same local landmark shape once adapted from the upstream frame contract (`REF-05`, `REF-06`, `REF-10`).

### Consumer paths that should remain provisional in this wave

1. **`src/input_provider.gd` assembly-facing addon entrypoint**  
   Still owns legacy local provider startup/publication semantics and should not be force-swapped in this slice (`REF-04`).

2. **Legacy local sidecar/runtime/preview ownership**  
   `AutoStartManager`, `camera_view.gd`, and the repo-local sidecar path are still present and should not be broadly removed or re-owned here unless needed only for narrow proving cleanup.

3. **Replay / prerecorded video proving**  
   `flow_proving.tscn` currently defaults to a prerecorded source, but upstream replay semantics are still explicitly deferred, so contract-first proving must stay live-camera only in this wave (`REF-09`, `REF-13`).

4. **Shared-session / assembly-core reconciliation**  
   The provider-session-registry path can remain unchanged for now; this slice is about consumer proving, not final input-core product integration (`REF-04`).

### What Boxing / Flow currently expect from the input substrate

- a continuous stream of normalized gameplay-space landmarks using local landmark dictionaries with `id/x/y/z/v`
- stable left/right wrist, nose, and ankle visibility/position enough for Boxing + Flow event detection
- repeated frames over time so the detector substrate can derive velocities, gesture windows, trail continuity, and guard/body states
- a coarse tracking-active truth that distinguishes usable tracking from lost/idle
- camera source changes and preview attachment only insofar as the upstream session already owns them

### Stronger upstream semantics now safe to rely on

- repeated continuous `tracking_updated(frame)` delivery while `CameraTracking` remains running
- `get_tracking_frame()` exposing the latest normalized frame
- truthful live-camera source identity and camera switching through `get_active_config()` / `change(config)`
- public landmark payload limited to `landmarks[].id/x/y/z/v`
- `preview_transform.flip_horizontal` with `space = gameplay_normalized`
- `detail.tracking_ready` meaning the continuous public lane is active, not just a one-shot startup sample
- public frame-level `tracking_state` only to the conservative level the tool repo currently claims (`tracked` when landmarks exist, otherwise `idle`)

### Semantics that must still remain provisional

- `reacquiring` meaning and detector behavior against it
- multi-pose truth beyond the local single-pose fallback
- gameplay-grade guarantees for aggregate `confidence`, `head_position`, `head_velocity`, `head_orientation`, and `skeleton`
- replay/video-file lifecycle semantics
- deeper physical meaning of landmark `z`
- final product-facing assembly/session discovery pattern outside repo-local proving

### First safe proving scope

**Safe proving scope for execution:**
- `.testbed` Boxing + Flow scenes consume a live `CameraTracking` session for continuous landmark input
- repo-local tests cover the contract-first provider/harness path and guard the live-camera-only boundaries
- docs/scenes stop implying truthful replay support through the contract path
- `src/input_provider.gd` and the legacy local provider path remain in place and explicitly provisional

**Not in this slice:**
- replay/video-file proving through `CameraTracking`
- final removal of legacy local sidecar/runtime code
- assembly-facing product integration onto `CameraTracking`
- richer public body/head/confidence semantics

---

## Tasks

### Task 1: Implement the first continuous contract-consumer proving slice

**Bead ID:** `aerobeat-input-camera-tracking-lab`  
**SubAgent:** `primary` (for `coder`)  
**Role:** `coder`  
**References:** `REF-03`, `REF-05`, `REF-06`, `REF-07`, `REF-08`, `REF-09`, `REF-10`, `REF-11`, `REF-12`, `REF-13`  
**Prompt:** In `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking`, claim bead `aerobeat-input-camera-tracking-lab` with `bd update aerobeat-input-camera-tracking-lab --status in_progress --json` when you start. Implement the narrowest honest downstream migration wave described in `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.plans/2026-05-22-first-continuous-contract-consumer-slice.md`. Required scope: make repo-local proving/consumer paths actually run through the upstream continuous `CameraTracking` contract for **live-camera** use; preserve `tracking_frame_adapter.gd` + `camera_tracking_provider.gd` as the detector seam; update proving scenes/harness/tests/docs so they truthfully prefer/use the upstream session path and stop overclaiming replay/file-backed support in this wave; keep `src/input_provider.gd`, provider-session-registry publication, and legacy local runtime ownership provisional unless a tiny compatibility touch is strictly required for the proving path. Do not broaden into replay, vendor/runtime ownership, final assembly integration, or richer public body/head/confidence semantics.

**Folders Created/Deleted/Modified:**
- `/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.testbed/`
- `/workspace/projects/aerobeat/aerobeat-input-camera-tracking/src/`
- `/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.plans/`

**Files Created/Deleted/Modified:**
- `/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.testbed/addons.jsonc`
- `/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.testbed/scripts/proving_harness.gd`
- `/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.testbed/scenes/boxing_proving.tscn`
- `/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.testbed/scenes/flow_proving.tscn`
- `/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.testbed/tests/unit/test_camera_tracking_provider.gd`
- `/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.testbed/tests/unit/test_proving_harness_trails.gd`
- `/workspace/projects/aerobeat/aerobeat-input-camera-tracking/README.md`

**Status:** ✅ Complete

**Results:** Claimed `aerobeat-input-camera-tracking-lab` with `bd update aerobeat-input-camera-tracking-lab --status in_progress --json` and implemented the narrow live-camera proving migration without broadening assembly ownership. `.testbed/scenes/boxing_proving.tscn` and `.testbed/scenes/flow_proving.tscn` now mount a `CameraTracking` node and run in `GODOT_ONLY_DEBUG` so the proving surface prefers the upstream continuous contract instead of the legacy local autostart lane. `flow_proving.tscn` no longer defaults to a prerecorded fixture path in this contract slice.

`.testbed/scripts/proving_harness.gd` now recognizes the mounted `CameraTracking` proving lane, registers the paired `mediapipe_python` backend factory through the upstream contract when needed, lets `CameraTrackingProvider` own the minimal proving-session lifecycle handshake, and reports camera-source truth from the active upstream session config. This keeps the detector seam contract-first through `tracking_frame_adapter.gd` + `camera_tracking_provider.gd` while avoiding broader vendor/runtime/lifecycle reclamation in repo-root sharable code.

Repo-local proving/test updates stayed inside `.testbed/`: `.testbed/addons.jsonc` now mounts `aerobeat-vendor-mediapipe-python` for repo-local live-session proving, `.testbed/tests/unit/test_camera_tracking_provider.gd` adds minimal lifecycle coverage for the provider/session proving handshake, and `.testbed/tests/unit/test_proving_harness_trails.gd` adds a harness assertion that effective source reporting prefers the mounted `CameraTracking` session.

Validation actually run in this repo:
- `python3 scripts/refresh_testbed_workbench.py --json` ✅ addon install + cache clear + headless import succeeded
- `godot --headless --path .testbed --script addons/gut/gut_cmdln.gd -gtest=res://tests/unit/test_camera_tracking_provider.gd -gexit` ✅ `4/4` tests passed
- `godot --headless --path .testbed --script addons/gut/gut_cmdln.gd -gtest=res://tests/unit/test_proving_harness_trails.gd -gexit` ⚠️ repo baseline remains `11/12` because pre-existing `test_resolves_trail_hand_point_by_clamping_near_edge_jitter` still fails; the new harness assertion passed
- `godot --headless --path .testbed --script addons/gut/gut_cmdln.gd -gdir=res://tests -ginclude_subdirs -gexit` ⚠️ broader repo suite still has unrelated pre-existing failures in legacy tests (`test_input_provider_adapter`, `test_mediapipe_process`, `test_mediapipe_provider`, plus the existing harness clamp case); no new failure was introduced in the targeted contract-provider coverage

Commit: pending until coder handoff commit is created.

---

### Task 2: QA the first continuous contract-consumer proving slice

**Bead ID:** `aerobeat-input-camera-tracking-ivf`  
**SubAgent:** `primary` (for `qa`)  
**Role:** `qa`  
**References:** `REF-03`, `REF-05`, `REF-07`, `REF-08`, `REF-09`, `REF-10`, `REF-11`, `REF-12`, `REF-13`  
**Prompt:** In `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking`, claim bead `aerobeat-input-camera-tracking-ivf` with `bd update aerobeat-input-camera-tracking-ivf --status in_progress --json` after the coder bead is ready. Independently verify the first continuous `CameraTracking` consumer proving slice. Confirm the repo-local proving scenes and tests now exercise the contract-first live-camera path honestly, confirm replay/file-backed behavior is not overclaimed, and confirm the implementation did not reclaim upstream runtime/lifecycle/preview/vendor ownership.

**Folders Created/Deleted/Modified:**
- `/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.testbed/`
- `/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.plans/`

**Files Created/Deleted/Modified:**
- validation notes only if needed

**Status:** ⏳ Pending

**Results:** Pending.

---

### Task 3: Audit the first continuous contract-consumer proving slice

**Bead ID:** `aerobeat-input-camera-tracking-l1k`  
**SubAgent:** `primary` (for `auditor`)  
**Role:** `auditor`  
**References:** `REF-03`, `REF-04`, `REF-05`, `REF-06`, `REF-07`, `REF-10`, `REF-11`, `REF-12`, `REF-13`  
**Prompt:** In `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking`, claim bead `aerobeat-input-camera-tracking-l1k` with `bd update aerobeat-input-camera-tracking-l1k --status in_progress --json` after QA completes. Independently audit the first continuous `CameraTracking` consumer proving slice against the plan, diff, QA evidence, and ownership boundaries. Close the bead only if the repo truly migrated the narrow live-camera proving/consumer path onto the upstream contract without overclaiming replay semantics or reclaiming lifecycle/vendor ownership.

**Folders Created/Deleted/Modified:**
- `/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.plans/`

**Files Created/Deleted/Modified:**
- audit notes only if needed

**Status:** ⏳ Pending

**Results:** Pending.

---

## Blockers / provisional notes to preserve during execution

1. `src/input_provider.gd` is still the legacy assembly-facing provider lane and should not be silently upgraded into the final contract consumer without a separate input-core reconciliation slice.
2. The proving scenes still currently instantiate `AutoStartManager` and do not mount a `CameraTracking` node by default; that is the core local migration gap this slice should close.
3. `flow_proving.tscn` currently defaults to a prerecorded fixture path, which is incompatible with the honest live-camera-only contract scope and must be corrected or clearly isolated.
4. Upstream replay/video-file semantics remain deferred; any preserved local file-backed path must stay clearly legacy/provisional.
5. `TrackingFrameAdapter.tracking_state_is_active()` already treats `reacquiring` as active, but the upstream continuous public contract still does not claim final `reacquiring` behavior, so no gameplay guarantees should be invented around it in this wave.

---

## Final Results

**Status:** ⚠️ Partial — coder slice complete; QA + audit still pending

**What We Built:** The coder slice migrated the repo-local Boxing + Flow proving surfaces onto a live `CameraTracking` session for the first honest continuous-contract consumer path. The `.testbed` scenes now mount `CameraTracking` directly, the proving harness can register and start the paired upstream/vendor backend through `CameraTrackingProvider`, and the Flow proving scene no longer overclaims prerecorded replay support in this contract-first wave.

**Reference Check:** `REF-05`, `REF-06`, `REF-07`, `REF-08`, `REF-09`, `REF-10`, `REF-11`, `REF-12`, and `REF-13` are now reflected in the coder implementation. `REF-04` remains intentionally provisional because `src/input_provider.gd` was not reclaimed in this slice.

**Commits:**
- Pending coder handoff commit.

**Lessons Learned:** The seam was already present; the real migration work was making proving consume it honestly while keeping runtime/vendor ownership upstream. Repo-local validation also confirmed this repo still carries unrelated legacy test failures, so QA/audit should judge the new contract path against the targeted proofs rather than assume a clean full-suite baseline.

---

*Prepared on 2026-05-22*
