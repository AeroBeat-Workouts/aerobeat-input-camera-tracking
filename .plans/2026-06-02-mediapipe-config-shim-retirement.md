# AeroBeat MediaPipe Config Shim Retirement

**Date:** 2026-06-02  
**Status:** In Progress  
**Last Updated:** 2026-06-02 06:07 EDT  
**Blocked Reason:** None  
**Agent:** `main`

---

## Goal

Remove or neutralize the remaining `MediaPipeConfig` / `mediapipe_config.gd` compatibility references so `aerobeat-input-camera-tracking` and affected consumers can stay on the neutral camera-tracking contract without hidden legacy path dependence.

---

## Overview

The repo-root `src/` audit passed, but it identified one deliberate legacy bridge: `src/config/mediapipe_config.gd` in `aerobeat-input-camera-tracking`. Derrick has now asked to check whether anything still depends on that bridge and then remove or fix those references. This is a small but cross-repo-sensitive cleanup, because the shim itself lives in `aerobeat-input-camera-tracking` while older references may survive in sibling consumers, testbeds, scenes, or docs.

The work therefore starts with a reference inventory rather than deleting the shim blind. The acceptance bar is precise: either prove the shim is no longer needed and safely retire it, or convert every live code/resource reference to the neutral `camera_tracking_config.gd` / `CameraTrackingConfig` path first and only then remove the shim. Documentation-only references can be updated separately as hygiene and should not block the functional cleanup.

---

## REFERENCES

| ID | Description | Path |
| --- | --- | --- |
| `REF-01` | Repo-root de-MediaPipe audit plan | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.plans/2026-06-02-input-camera-tracking-repo-root-demediapipe-audit.md` |
| `REF-02` | Repo-root de-MediaPipe audit report | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.plans/2026-06-02-input-camera-tracking-repo-root-demediapipe-audit-report.md` |
| `REF-03` | Legacy shim to retire | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/src/config/mediapipe_config.gd` |
| `REF-04` | Neutral source-of-truth config | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/src/config/camera_tracking_config.gd` |
| `REF-05` | Current cross-repo neutral contract spec | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.plans/2026-06-01-cross-repo-demediapipe-neutral-contract.md` |
| `REF-06` | Known sibling consumer currently referencing the legacy shim | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-assembly-community/src/mediapipe_provider_test.gd` |

---

## Tasks

### Task 1: Inventory live `MediaPipeConfig` / `mediapipe_config.gd` references and classify removal risk

**Bead ID:** `aerobeat-input-camera-tracking-lwk`  
**SubAgent:** `primary` (for `research` workflow role)  
**Role:** `research`  
**References:** `REF-01`, `REF-02`, `REF-03`, `REF-04`, `REF-05`, `REF-06`  
**Prompt:** In `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking`, audit all live references to `MediaPipeConfig` and `mediapipe_config.gd` across the relevant AeroBeat repos. Classify each hit as code/runtime/resource-critical vs docs-only, identify the owning repo, and state whether the neutral replacement should be `CameraTrackingConfig` / `camera_tracking_config.gd` or a different fix. Recommend whether the shim can be removed immediately or only after specific consumer updates. Claim the bead on start, do not modify application code, and update this plan with exact findings.

**Folders Created/Deleted/Modified:**
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.plans/`
- relevant sibling repos as read-only audit targets

**Files Created/Deleted/Modified:**
- this plan file
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.plans/2026-06-02-mediapipe-config-shim-reference-audit.md`

**Status:** ✅ Complete

**Results:** Inventory completed across AeroBeat repos with live-code, tests-only, and docs/history separation. Exact non-history hits were limited to: (1) the owning-repo compatibility shim at `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/src/config/mediapipe_config.gd`, which remains a live compatibility resource because it still defines `class_name MediaPipeConfig`; and (2) a tests-only sibling consumer at `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-assembly-community/src/mediapipe_provider_test.gd`, which still preloads `res://addons/aerobeat-input-mediapipe/src/config/mediapipe_config.gd`, types `@export var config: MediaPipeConfig`, and instantiates `MediaPipeConfig.new()`. No other non-plan, non-doc, non-temp hits were found under `/home/derrick/.openclaw/workspace/projects/aerobeat`. Neutral replacement for the live/tests-only seam is `camera_tracking_config.gd` / `CameraTrackingConfig` while preserving the current assembly addon mount alias unless that alias changes in a separate slice. Verdict: the shim at `REF-03` is **not removable yet** because the assembly test script in `REF-06` still depends on it. Audit memo written at `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.plans/2026-06-02-mediapipe-config-shim-reference-audit.md`. References validated: `REF-03`, `REF-04`, `REF-05`, `REF-06`.

---

### Task 2: Remove or replace live legacy config references in owning repos

**Bead ID:** `aerobeat-input-camera-tracking-xkg`  
**SubAgent:** `primary` (for `coder` workflow role)  
**Role:** `coder`  
**References:** `REF-03`, `REF-04`, `REF-05`, `REF-06`  
**Prompt:** Implement the narrowest truthful fix for every live code/resource dependency on `MediaPipeConfig` / `mediapipe_config.gd`. Prefer converting consumers to the neutral `CameraTrackingConfig` / `camera_tracking_config.gd` path. Only remove the shim once those live references are gone. Update docs-only references opportunistically if they are in touched repos, run repo-local validation in each affected repo, and commit/push by default before handoff.

**Folders Created/Deleted/Modified:**
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-assembly-community/src/`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/src/config/`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.plans/`

**Files Created/Deleted/Modified:**
- removed `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-assembly-community/src/mediapipe_provider_test.gd`
- removed `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-assembly-community/src/mediapipe_provider_test.gd.uid`
- removed `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/src/config/mediapipe_config.gd`
- removed `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/src/config/mediapipe_config.gd.uid`
- modified this plan file

**Status:** ✅ Complete

**Results:** Derrick confirmed `REF-06` was temporary, so the assembly consumer was retired instead of migrated. Removed `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-assembly-community/src/mediapipe_provider_test.gd` plus its `.uid`, then reran `rg -n "mediapipe_config\\.gd|MediaPipeConfig" /home/derrick/.openclaw/workspace/projects/aerobeat --glob '!**/.git/**'`. After those deletions, the only remaining hits under `/home/derrick/.openclaw/workspace/projects/aerobeat` were documentation notes in `aerobeat-ui-kit-community`; no live or tests-only code/resource references remained. That made `REF-03` safe to retire, so `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/src/config/mediapipe_config.gd` plus its `.uid` were removed. Focused validation run: `git diff --check` in both touched repos (passed in `aerobeat-assembly-community`; in `aerobeat-input-camera-tracking` it surfaced only pre-existing trailing whitespace in unrelated `.plans/2026-06-01-vendor-import-webcam-replay-2d-skeleton-truth.md`), plus post-change `rg` scans in both touched repos and the top-level AeroBeat workspace confirming no live/test hits remain. References validated: `REF-03`, `REF-06`. Shim removed: yes.

---

### Task 3: QA the shim-retirement slice

**Bead ID:** `aerobeat-input-camera-tracking-eoe`  
**SubAgent:** `primary` (for `qa` workflow role)  
**Role:** `qa`  
**References:** `REF-03`, `REF-04`, `REF-06`  
**Prompt:** Verify that the legacy config shim was either safely removed or correctly retained only where still justified, and that affected consumers now use the neutral camera-tracking config path without regression. Run focused validation in each touched repo and document exact evidence.

**Folders Created/Deleted/Modified:**
- validation artifacts as needed

**Files Created/Deleted/Modified:**
- none expected unless a minimal validation note is justified

**Status:** ⏳ Pending

**Results:** Pending.

---

### Task 4: Independently audit final truthfulness of shim retirement

**Bead ID:** `aerobeat-input-camera-tracking-okb`  
**SubAgent:** `primary` (for `auditor` workflow role)  
**Role:** `auditor`  
**References:** `REF-03`, `REF-04`, `REF-05`, `REF-06`  
**Prompt:** Independently verify that all live `MediaPipeConfig` / `mediapipe_config.gd` references were either removed or truthfully justified, that neutral replacements are correct, and that no hidden runtime/resource dependency was broken. Produce a concise evidence-backed audit.

**Folders Created/Deleted/Modified:**
- `.plans/`

**Files Created/Deleted/Modified:**
- final audit note path to be assigned if needed

**Status:** ⏳ Pending

**Results:** Pending.

---

## Final Results

**Status:** ⚠️ Partial

**What We Built:** Completed the coder slice for shim retirement by deleting the temporary assembly test consumer and then removing the now-unused `MediaPipeConfig` compatibility shim from `aerobeat-input-camera-tracking`.

**Reference Check:** `REF-03` and `REF-06` were validated directly; no live/tests-only `mediapipe_config.gd` / `MediaPipeConfig` hits remained after the deletions.

**Commits:**
- Pending coder commit/push

**Lessons Learned:** Even a tiny compatibility shim needs a cross-repo search before removal, but once the last consumer is explicitly temporary, deleting the consumer is cleaner than migrating dead test code.

---

*Completed on Pending*
