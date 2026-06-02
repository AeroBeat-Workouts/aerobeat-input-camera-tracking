# AeroBeat Input Camera Tracking Alignment

**Date:** 2026-06-01
**Status:** Complete
**Last Updated:** 2026-06-02 07:29 EDT
**Blocked Reason:** None
**Agent:** `main`

---

## Goal

Align `aerobeat-input-camera-tracking` so its `src/` interacts with the camera-tracking system only through `aerobeat-tool-camera-tracking`, while `aerobeat-vendor-mediapipe-python` remains the vendor-owned Python sidecar boundary.

---

## Overview

The audit showed the desired layering already exists in parts of the input repo, but a substantial amount of legacy behavior still bypasses the tool contract. The cleanup target is now explicit: `aerobeat-input-camera-tracking` should not know what MediaPipe is. It should only know that `aerobeat-tool-camera-tracking` is available and how to consume its contract. That means removing direct vendor composition, retiring local `python_mediapipe` runtime ownership, and eliminating direct localhost transport/process management from the input repo wherever those responsibilities should live behind the tool/vendor seam.

This plan treats the alignment as a staged migration with verification gates and a clean break from MediaPipe-aware input-repo code. First, we’ll map and lock the intended contract boundary. Then we’ll refactor composition paths in the input repo to use only the tool layer. After that, we’ll retire legacy runtime and transport paths, run QA against the intended behavior, and finally audit the repo again to confirm the layering is clean.

---

## REFERENCES

| ID | Description | Path |
| --- | --- | --- |
| `REF-01` | Input repo to align | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking` |
| `REF-02` | Tool contract repo | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-tool-camera-tracking` |
| `REF-03` | Vendor repo with Python sidecar at repo root | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-vendor-mediapipe-python` |
| `REF-04` | Audit report identifying current bypasses | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.plans/2026-06-01-camera-tracking-audit-report.md` |

---

## Tasks

### Task 1: Define the approved contract boundary and migration targets

**Bead ID:** `aerobeat-input-camera-tracking-roj`
**SubAgent:** `primary` (for `research` workflow role)
**Role:** `research`
**References:** `REF-01`, `REF-02`, `REF-03`, `REF-04`
**Prompt:** Review the audited repos and write a concise boundary memo describing which camera-tracking responsibilities belong in `aerobeat-input-camera-tracking`, which belong in `aerobeat-tool-camera-tracking`, and which belong in `aerobeat-vendor-mediapipe-python`. Treat this as a clean-break boundary: `aerobeat-input-camera-tracking` should not know what MediaPipe is, only that `aerobeat-tool-camera-tracking` is available and how to use its contract. Use the audit findings as input and identify the exact input-repo files that must stop doing direct vendor/runtime/transport/process work. Claim the bead on start and do not modify code.

**Folders Created/Deleted/Modified:**
- `.plans/`

**Files Created/Deleted/Modified:**
- `.plans/2026-06-01-input-camera-tracking-alignment.md`
- `.plans/2026-06-01-camera-tracking-audit-report.md`
- `.plans/2026-06-01-camera-tracking-boundary-memo.md`

**Status:** ✅ Complete

**Results:** Research completed the clean-break boundary memo at `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.plans/2026-06-01-camera-tracking-boundary-memo.md` and closed bead `aerobeat-input-camera-tracking-roj`. The memo confirms the target split: input repo owns gameplay interpretation only; tool repo owns the public camera-tracking contract; vendor repo owns all MediaPipe/Python/runtime specifics. It also names the exact input-repo files that must stop direct vendor/runtime/transport/process work and orders the migration so input can become truly MediaPipe-agnostic.

---

### Task 2: Refactor input repo composition to use only the tool contract

**Bead ID:** `aerobeat-input-camera-tracking-k6f`
**SubAgent:** `primary` (for `coder` workflow role)
**Role:** `coder`
**References:** `REF-01`, `REF-02`, `REF-03`, `REF-04`
**Prompt:** Implement the alignment plan in `aerobeat-input-camera-tracking` so consumer-facing `src/` code interacts with camera tracking only through `aerobeat-tool-camera-tracking`. Enforce the clean break: the input repo should not know what MediaPipe is, should not load vendor scripts directly, and should not locally compose vendor backends. Remove those concerns from the input repo where the approved boundary says they should not exist. Claim the bead on start, run relevant validation, commit, and push by default before handoff.

**Folders Created/Deleted/Modified:**
- `src/`
- `.testbed/tests/unit/`
- other repo-owned folders as needed

**Files Created/Deleted/Modified:**
- `src/input_provider.gd`
- `src/AeroCameraTracking.gd`
- `.testbed/tests/unit/test_input_provider_adapter.gd`
- `.testbed/tests/unit/test_aero_camera_tracking.gd`

**Status:** ✅ Complete

**Results:** Coder completed the first alignment pass and pushed commit `2770d54` (`Refactor camera tracking consumers to contract-only path`). `src/input_provider.gd` no longer locally composes `CameraTracking` plus vendor backend/runtime pieces, and `src/AeroCameraTracking.gd` no longer directly loads vendor scripts, registers vendor backend factories from this repo, shells out to `ffprobe`, or peeks into tool internals for replay/backend state. Focused contract tests passed, and a static grep check found no remaining direct vendor references in the two targeted consumer-facing files. One unrelated pre-existing failure remains in `.testbed/tests/unit/test_mediapipe_process.gd` around prepared runtime/path availability.

---

### Task 3: Retire legacy local sidecar/runtime/transport ownership from the input repo

**Bead ID:** `aerobeat-input-camera-tracking-tdl`
**SubAgent:** `primary` (for `coder` workflow role)
**Role:** `coder`
**References:** `REF-01`, `REF-02`, `REF-03`, `REF-04`
**Prompt:** Remove or isolate the remaining legacy `python_mediapipe`, direct localhost transport, and direct process-management paths from `aerobeat-input-camera-tracking` so the repo no longer owns vendor/runtime behavior that should live behind the tool/vendor boundary. Enforce the clean break: after this task, the input repo should not know what MediaPipe is and should only depend on the tool contract. Claim the bead on start, run relevant validation, commit, and push by default before handoff.

**Folders Created/Deleted/Modified:**
- `src/providers/`
- `src/process/`
- `src/runtime/`
- `src/server/`
- `src/strategies/`
- `.testbed/scripts/`
- `.testbed/tests/`
- `.testbed/tests/unit/`

**Files Created/Deleted/Modified:**
- `src/providers/mediapipe_provider.gd`
- `src/process/mediapipe_process.gd`
- `src/autostart_manager.gd`
- `src/runtime/desktop_sidecar_runtime.gd`
- `src/server/mediapipe_server.gd`
- `src/strategies/strategy_mediapipe.gd`
- `src/camera_view.gd`
- `src/AeroMediaPipeReplayPlaybackBackend.gd`
- `src/mediapipe_input_with_camera.gd`
- `src/config/camera_tracking_config.gd`
- `src/input_provider.gd`
- `src/AeroCameraTracking.gd`
- `src/config/mediapipe_config.gd`
- `README.md`
- `plugin.cfg`
- `.testbed/scripts/proving_harness.gd`
- `.testbed/tests/unit/test_input_provider_adapter.gd`
- `.testbed/tests/unit/test_proving_harness_trails.gd`
- retired legacy proving/tests files and `.uid` companions

**Status:** ✅ Complete

**Results:** Coder completed the legacy-retirement slice and pushed commits `2446686` (`Retire local MediaPipe runtime lane`) and `a878f7f` (`Track camera tracking config resource`). The sharable addon lane no longer owns the local provider/runtime/process/preview scripts that previously bypassed the tool/vendor boundary. The coder also fixed a real follow-up seam by changing `src/AeroCameraTracking.gd` to use repo-local `camera_tracking_config.gd` for runtime config coercion and by committing that new config resource so fresh clones stay functional. Validation reported passing focused tests for `test_input_provider_adapter.gd` and `test_proving_harness_trails.gd`, clean `git diff --cached --check`, and grep confirmation that the retired consumer-facing legacy paths were removed.

---

### Task 4: QA the aligned camera-tracking flow

**Bead ID:** `aerobeat-input-camera-tracking-qpa`
**SubAgent:** `primary` (for `qa` workflow role)
**Role:** `qa`
**References:** `REF-01`, `REF-02`, `REF-03`, `REF-04`
**Prompt:** Verify the aligned input-camera-tracking behavior end-to-end using the highest-fidelity repo-local validation available. Confirm the input repo no longer directly composes or owns camera-tracking vendor/runtime behavior in the audited paths, and that the intended flow still works. Claim the bead on start and document exact validation evidence.

**Folders Created/Deleted/Modified:**
- validation artifacts as needed

**Files Created/Deleted/Modified:**
- test or validation notes as needed

**Status:** ✅ Complete

**Results:** QA completed with a PASS verdict on the legacy-retirement slice covering commits `2446686` and `a878f7f`. Verification confirmed the local MediaPipe/runtime-owned sharable addon lane was removed from `src/`, the provisional fallback was removed from `src/input_provider.gd`, and no direct vendor/runtime composition patterns remain under the sharable `src/` path. Focused validation passed 52/52 across `test_input_provider_adapter.gd`, `test_aero_camera_tracking.gd`, `test_camera_tracking_provider.gd`, and `test_proving_harness_trails.gd`. QA also confirmed docs/config are truthful enough for the current state, while noting residual naming debt such as `mediapipe_python` provider IDs and MediaPipe-branded proving-only names under `.testbed/`.

---

### Task 5: Independently audit the final layering

**Bead ID:** `aerobeat-input-camera-tracking-b5k`
**SubAgent:** `primary` (for `auditor` workflow role)
**Role:** `auditor`
**References:** `REF-01`, `REF-02`, `REF-03`, `REF-04`
**Prompt:** Independently audit the final state of `aerobeat-input-camera-tracking`, `aerobeat-tool-camera-tracking`, and `aerobeat-vendor-mediapipe-python` to confirm whether the input repo’s `src/` now interacts with the camera-tracking system only through the tool repo and whether vendor ownership remains correctly isolated in the vendor repo. Claim the bead on start, produce evidence, and close the bead only if the audit is complete.

**Folders Created/Deleted/Modified:**
- `.plans/`

**Files Created/Deleted/Modified:**
- `.plans/2026-06-01-camera-tracking-final-audit-report.md`

**Status:** ✅ Complete

**Results:** Auditor completed the final layering audit and wrote `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.plans/2026-06-01-camera-tracking-final-audit-report.md`. Final verdict: PASS. The report confirms that `aerobeat-input-camera-tracking/src` now uses the `aerobeat-tool-camera-tracking` contract path for camera-tracking interactions, that `aerobeat-tool-camera-tracking/src` remains vendor-agnostic, and that `aerobeat-vendor-mediapipe-python` still owns the MediaPipe/Python/runtime boundary with repo-root sidecar assets. Remaining `mediapipe_*` identifiers, duplicate config resources, and proving-only names are documented as compatibility/naming debt rather than true layering violations.

---

## Final Results

**Status:** ✅ Complete

**What We Built:** Aligned `aerobeat-input-camera-tracking` to the intended camera-tracking layering by removing direct vendor/runtime/process/IPC ownership from the sharable input repo path, refactoring consumer-facing code to use only the `aerobeat-tool-camera-tracking` contract, retiring the local MediaPipe runtime lane, and independently re-auditing the final state.

**Reference Check:** `REF-01` is now aligned for the sharable `src/` surface: camera-tracking interactions go through the tool contract path. `REF-02` remains satisfied: the tool repo is vendor-agnostic in sharable `src/` and resolves backends via its registry/factory seam. `REF-03` remains satisfied: the vendor repo still owns the MediaPipe/Python/runtime boundary and repo-root sidecar assets. `REF-04` has been superseded by the final audit report, which records the transition from initial FAIL to final PASS.

**Commits:**
- `2770d54` - Refactor camera tracking consumers to contract-only path
- `2446686` - Retire local MediaPipe runtime lane
- `a878f7f` - Track camera tracking config resource

**Lessons Learned:** The cleanup needed two distinct implementation passes: first remove direct vendor composition from the consumer-facing files, then remove the entire local runtime lane and truth-update proving/tests/docs. Residual `mediapipe_*` names can survive as compatibility debt without being true architectural violations, but they should be treated explicitly as naming debt rather than ignored.

---

*Completed on 2026-06-01*
