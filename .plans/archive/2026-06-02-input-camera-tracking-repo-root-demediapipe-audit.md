# AeroBeat Input Camera Tracking Repo-Root De-MediaPipe Audit

**Date:** 2026-06-02
**Status:** Complete
**Last Updated:** 2026-06-02 07:29 EDT
**Blocked Reason:** None
**Agent:** `main`

---

## Goal

Verify that `aerobeat-input-camera-tracking` repo-root `src/` can respond to camera-tracking events and emit input events without relying on or knowing about MediaPipe, while its `.testbed` dependency graph continues to satisfy the hidden vendor implementation through sibling repos.

---

## Overview

The stale proving/runtime plan drift has now been reconciled: the real cross-repo seam migration already landed under the repo-local `aerobeat-input-camera-tracking-*` bead line and was independently audited as a PASS at the repo-boundary level. What remains is a sharper question Derrick asked for this morning: not merely whether public naming is neutral, but whether repo-root `src/` still contains residual MediaPipe knowledge or dependency on vendor-specific behavior that would violate the intended ownership split.

This plan therefore treats the next slice as an audit-first truth pass. The audit must inspect repo-root `src/` and its direct sibling dependency assumptions against the current `.testbed` dependency graph (`aerobeat-input-core`, `aerobeat-tool-camera-tracking`, and `aerobeat-vendor-mediapipe-python`). The acceptance bar is precise: the input repo may consume camera-tracking events and create input events, but the knowledge of MediaPipe should live in the tool/vendor layers or in proving-only dependency wiring rather than in sharable repo-root `src/` behavior.

If the audit finds only allowed proving-only dependency wiring or compatibility breadcrumbs outside sharable `src/`, that is a PASS with exact evidence. If it finds repo-root `src/` still encoding MediaPipe-specific provider IDs, backend assumptions, config/resource names, runtime paths, env vars, or comments that materially express vendor knowledge, the audit should identify the exact files and recommend the narrowest next implementation seam.

---

## REFERENCES

| ID | Description | Path |
| --- | --- | --- |
| `REF-01` | Completed cross-repo coordination plan | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.plans/archive/2026-06-01-cross-repo-demediapipe-coordination.md` |
| `REF-02` | Final cross-repo audit | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.plans/2026-06-02-cross-repo-demediapipe-final-audit.md` |
| `REF-03` | Current repo-root source boundary under audit | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/src` |
| `REF-04` | Current testbed dependency manifest | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.testbed/addons.jsonc` |
| `REF-05` | Sibling neutral consumer registry | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-core` |
| `REF-06` | Tool boundary that should own backend/defaulting knowledge | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-tool-camera-tracking` |
| `REF-07` | Vendor implementation boundary that may remain mounted only behind the tool seam | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-vendor-mediapipe-python` |

---

## Tasks

### Task 1: Audit repo-root `src/` for residual MediaPipe knowledge or reliance

**Bead ID:** `aerobeat-input-camera-tracking-92i`
**SubAgent:** `primary` (for `research` workflow role)
**Role:** `research`
**References:** `REF-01`, `REF-02`, `REF-03`, `REF-04`, `REF-05`, `REF-06`, `REF-07`
**Prompt:** In `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking`, claim bead `aerobeat-input-camera-tracking-92i` on start. Audit whether repo-root `src/` still relies on or is knowledgeable of MediaPipe after the cross-repo seam migration. Focus on provider/session IDs, backend IDs, config/resource names, runtime paths, env vars, comments, and any direct vendor assumptions in sharable `src/` code. Distinguish carefully between forbidden repo-root `src/` vendor knowledge and allowed proving-only `.testbed` dependency wiring through `aerobeat-tool-camera-tracking` and `aerobeat-vendor-mediapipe-python`. Do not modify application code. Produce a concise evidence-backed memo that states PASS/FAIL for the repo-root `src/` boundary and, if anything fails, names the narrowest next implementation seam.

**Folders Created/Deleted/Modified:**
- `.plans/`
- `src/` (read-only audit target)
- `.testbed/` (read-only dependency-context target)

**Files Created/Deleted/Modified:**
- `.plans/2026-06-02-input-camera-tracking-repo-root-demediapipe-audit.md`
- `.plans/2026-06-02-input-camera-tracking-repo-root-demediapipe-audit-report.md`

**Status:** ✅ Complete

**Results:** Audit completed and memo written at `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.plans/2026-06-02-input-camera-tracking-repo-root-demediapipe-audit-report.md`. Verdict: **PASS** for the repo-root `src/` boundary. Evidence confirmed that `src/input_provider.gd` now publishes neutral `camera_tracking` provider/session identity, `src/providers/camera_tracking_provider.gd` emits neutral `camera_tracking_default` backend requests, and `src/AeroCameraTracking.gd` consumes only the public tool contract rather than composing vendor runtime objects. Direct `mediapipe` naming inside repo-root `src/` was reduced to a single compatibility shim at `src/config/mediapipe_config.gd`, which extends the neutral `camera_tracking_config.gd` and documents itself as legacy-path compatibility only. The remaining concrete MediaPipe knowledge stays in allowed layers: tool-owned backend resolution in `../aerobeat-tool-camera-tracking/src/CameraTrackingConfig.gd`, vendor implementation internals in `../aerobeat-vendor-mediapipe-python`, and proving-only vendor mount wiring in `.testbed/addons.jsonc`.

---

## Final Results

**Status:** ✅ Complete

**What We Built:** Completed a focused repo-root `src/` audit to verify that `aerobeat-input-camera-tracking` no longer relies on or meaningfully knows about MediaPipe in its sharable source boundary. The audit memo records a PASS verdict and explains why the remaining MediaPipe knowledge is confined to allowed compatibility, tool, vendor, and proving-only layers.

**Reference Check:** `REF-01` through `REF-07` satisfied. Repo-root `src/` uses neutral `camera_tracking` provider/session identity and `camera_tracking_default` backend request identity; tool-owned backend resolution remains in `aerobeat-tool-camera-tracking`; vendor-specific implementation details remain in `aerobeat-vendor-mediapipe-python`; and `.testbed/addons.jsonc` remains proving-only dependency wiring.

**Commits:**
- None (audit/docs only; no commit requested)

**Lessons Learned:** The meaningful test for this slice was not merely whether the repo still contained the string `mediapipe`, but whether repo-root `src/` still owned vendor semantics. A single compatibility alias file can remain acceptable when provider/session/backend/runtime ownership has already been pushed behind the tool and vendor seams.

---

*Completed on 2026-06-02*
