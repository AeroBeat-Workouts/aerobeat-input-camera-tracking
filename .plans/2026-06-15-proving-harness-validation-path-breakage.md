# AeroBeat Proving Harness Validation Path Breakage

**Date:** 2026-06-15  
**Status:** In Progress  
**Last Updated:** 2026-06-15 13:35 EDT  
**Blocked Reason:** None  
**Agent:** `pico`

---

## Goal

Diagnose and fix the proving-harness validation path breakage uncovered by naming-seam QA so the derive/capture validation path becomes trustworthy again.

---

## Overview

The naming/vocabulary coder pass landed successfully in commit `7e2f9db`, but QA could not truthfully clear the seam because the proving/capture validation path failed before it could validate the rename cleanly. The failure looked like environment/bootstrap/path breakage rather than a bad prototype-ID rename: missing autoload scripts under `res://addons/...`, a parse/load failure in `res://scripts/boxing_proving_harness.gd`, and a missing imported background texture caused the scene to stay at `Initializing...` with no provider present and no screenshotable proof output.

This seam should stay narrow. We are not retuning matcher behavior here. We need to determine whether the failure is caused by `git-sync` / `godotenv-sync` state, broken addon/project wiring in the isolated QA environment, a script-class/path regression in the proving harness, or missing imported/runtime assets. Once the path is trustworthy again, we can rerun the naming/vocabulary QA against commit `7e2f9db` and only then continue to the naming audit.

---

## REFERENCES

| ID | Description | Path |
| --- | --- | --- |
| `REF-01` | Naming/vocabulary alignment plan | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.plans/2026-06-15-prototype-id-and-fixture-vocabulary-alignment.md` |
| `REF-02` | Naming/vocabulary coder commit under verification | `git commit 7e2f9db` |
| `REF-03` | QA failure report from naming seam | subagent result in current session (2026-06-15 12:28 EDT) |
| `REF-04` | Proving capture script | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/scripts/capture_fixture_proving.gd` |
| `REF-05` | Boxing proving harness wrapper | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/scripts/boxing_proving_harness.gd` |
| `REF-06` | Base proving harness | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/scripts/proving_harness.gd` |
| `REF-07` | Boxing proving scene | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/scenes/boxing_proving.tscn` |
| `REF-08` | Sync-health plan proving recent workspace sync truth | `/home/derrick/.openclaw/.plans/2026-06-15-all-aerobeat-sync-health.md` |

---

## Tasks

### Task 1: Reproduce and isolate the proving-harness validation-path failure

**Bead ID:** `aerobeat-input-camera-tracking-kadr`  
**SubAgent:** `primary` (for `coder`)  
**Role:** `coder`  
**References:** `REF-01`, `REF-03`, `REF-04`, `REF-05`, `REF-06`, `REF-07`, `REF-08`  
**Prompt:** Reproduce the naming-QA proving/capture failure against commit `7e2f9db`, determine whether the breakage comes from addon wiring, script parse/class resolution, imported asset state, or validation-environment bootstrap assumptions, and document the exact root cause before fixing anything. Claim the bead on start.

**Folders Created/Deleted/Modified:**
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking`

**Files Created/Deleted/Modified:**
- diagnostic notes/artifacts as needed

**Status:** ✅ Complete

**Results:** Root cause isolated without landing fixes. Commit `7e2f9db` is not the primary breakage. In the real synced `.testbed`, headless capture reached a healthy live state; the failure signature reproduced only when the validation environment was missing bootstrap state. Primary root cause: missing `.testbed/addons` mounts/autoloads, which causes the exact prior QA pattern of missing `res://addons/...` scripts, `boxing_proving_harness.gd` parse/load failure, `Initializing...`, and `provider_present: false`. Secondary root cause: missing `.testbed/.godot` imported asset cache, which reproduces the missing texture/import family but yields a different failure shape (`provider_present: true`, `Provider failed to start`). Separate capture weakness: headless screenshot output is not currently trustworthy even in healthy runs, while `report.json` remains usable. Durable repro artifacts were written under `/home/derrick/.openclaw/workspace/.temp/kadr-*`. Bead `aerobeat-input-camera-tracking-kadr` was closed.

---

### Task 2: Land the narrowest fix for the validation path

**Bead ID:** `aerobeat-input-camera-tracking-t7m2`  
**SubAgent:** `primary` (for `coder`)  
**Role:** `coder`  
**References:** `REF-03`, `REF-04`, `REF-05`, `REF-06`, `REF-07`, `REF-08`  
**Prompt:** Fix the proving-harness validation path breakage with the narrowest truthful change set, preserving real failure reporting and avoiding matcher retuning or unrelated naming churn. Claim the bead on start, validate the fix, then commit/push by default if complete.

**Folders Created/Deleted/Modified:**
- relevant owning repo paths

**Files Created/Deleted/Modified:**
- scripts/scenes/assets/config/docs as required by the root cause

**Status:** ✅ Complete

**Results:** Landed commit `9a36bf0` (`Fail fast when proving bootstrap state is missing`) and closed bead `aerobeat-input-camera-tracking-t7m2`. The fix adds a bootstrap preflight to `.testbed/scripts/capture_fixture_proving.gd` before scene load: it verifies `.testbed/addons` installation from `addons.jsonc`, verifies autoload script targets from `.testbed/project.godot`, verifies `.testbed/.godot/imported` exists, checks remapped imported assets needed by the project icon and target scene resources, writes `report.json` / `report.md` with explicit bootstrap diagnostics on failure, and exits non-zero with distinct codes for missing addons vs missing import cache. Healthy capture still succeeds; unbootstrapped copies now fail fast truthfully instead of stumbling into misleading harness parse/startup symptoms.

---

### Task 3: QA the restored validation path and naming seam

**Bead ID:** `aerobeat-input-camera-tracking-8pfq`  
**SubAgent:** `primary` (for `qa`)  
**Role:** `qa`  
**References:** `REF-01`, `REF-02`, `REF-03`, `REF-04`, `REF-05`, `REF-06`, `REF-07`  
**Prompt:** Re-run the proving/derive validation path after the fix, then verify the naming/vocabulary seam against commit `7e2f9db` plus the validation-path fix. Confirm the path is trustworthy and the naming seam can now be cleared or report the remaining blocker truthfully.

**Folders Created/Deleted/Modified:**
- relevant owning repo paths

**Files Created/Deleted/Modified:**
- QA notes/artifacts as needed

**Status:** ✅ Complete

**Results:** QA passed. Healthy synced `.testbed` captures succeeded after `9a36bf0`, missing bootstrap state now fails fast with explicit diagnostics instead of misleading harness startup breakage, and a full derive-path rerun succeeded end-to-end (`prototype_count=24`, `fixture_count=6`, `skipped_window_count=0`). The naming/vocabulary seam from `7e2f9db` also held under QA: canonical derived IDs, intact provenance/source refs, and consistent `straight_left` / `straight_right` vocabulary across fixtures, library, derivation report, and benchmark manifest. Bead `aerobeat-input-camera-tracking-8pfq` was closed.

---

### Task 4: Audit the validation-path fix and final naming-seam truth

**Bead ID:** `aerobeat-input-camera-tracking-89v3`  
**SubAgent:** `primary` (for `auditor`)  
**Role:** `auditor`  
**References:** `REF-01`, `REF-02`, `REF-03`, `REF-04`, `REF-05`, `REF-06`, `REF-07`  
**Prompt:** Independently audit the validation-path fix and confirm whether the naming/vocabulary seam is now truthfully complete. Claim the bead on start. Close the relevant bead only if both the validation path and naming-seam claims are actually supported.

**Folders Created/Deleted/Modified:**
- relevant owning repo paths

**Files Created/Deleted/Modified:**
- audit notes/artifacts as needed

**Status:** ❌ Failed

**Results:** Audit did not clear the combined seam. The validation-path fix around `9a36bf0` passed: healthy synced `.testbed` capture is usable again, and missing bootstrap state now fails fast with explicit diagnostics. But the naming/vocabulary seam from `7e2f9db` is not truthfully complete because provenance is still wrong in `assets/prototype_libraries/boxing_side_aware_v1/library.json`: `straight_right_seed_01` and `straight_right_seed_02` still point their `source_ref` at the `straight_left` fixture YAML. Bead `aerobeat-input-camera-tracking-89v3` was left blocked rather than closed.

Follow-up seam opened immediately after audit failure:
- `aerobeat-input-camera-tracking-it73` — coder: fix stale straight-right provenance in `boxing_side_aware_v1`
- `aerobeat-input-camera-tracking-l3co` — QA
- `aerobeat-input-camera-tracking-pq09` — audit
This follow-up is intentionally surgical and limited to the stale provenance truth gap.

Coder follow-up result: commit `fc7e1ee` (`Fix straight-right prototype provenance`) corrected the stale `source_ref` values for `straight_right_seed_01` and `straight_right_seed_02` in `assets/prototype_libraries/boxing_side_aware_v1/library.json`, changing them from the old `straight_left` fixture YAML to the canonical `straight_right` fixture YAML. No matcher behavior or sample data changed, and bead `aerobeat-input-camera-tracking-it73` was closed.

---

## Final Results

**Status:** ⚠️ Partial

**What We Built:** Pending.

**Reference Check:** Pending.

**Commits:**
- Pending.

**Lessons Learned:** Pending.
