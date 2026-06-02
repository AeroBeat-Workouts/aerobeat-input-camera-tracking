# AeroBeat Input Camera Tracking Dependency Audit

**Date:** 2026-06-01
**Status:** Complete
**Last Updated:** 2026-06-02 07:29 EDT
**Blocked Reason:** None
**Agent:** `main`

---

## Goal

Audit `aerobeat-input-camera-tracking` to verify that its `/src/` interacts with the camera tracking system only through `aerobeat-tool-camera-tracking`, and that `aerobeat-tool-camera-tracking` in turn relies on `aerobeat-vendor-mediapipe-python` as the vendor repo containing the Python sidecar at repo root.

---

## Overview

This audit will trace camera-tracking-related imports, process launches, IPC paths, and vendor references across the three repos. The core question is whether the dependency layering is clean: input repo → tool repo → vendor repo.

I’ll document any direct bypasses, partial compliance, or missing integrations, then summarize the exact files and call paths involved. If the current state is not aligned with the intended layering, the audit will clearly identify each violation and where it occurs.

---

## REFERENCES

| ID | Description | Path |
| --- | --- | --- |
| `REF-01` | Repo under audit | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking` |
| `REF-02` | Expected camera tracking tool abstraction layer | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-tool-camera-tracking` |
| `REF-03` | Expected vendor repo containing Python sidecar at repo root | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-vendor-mediapipe-python` |

---

## Tasks

### Task 1: Audit dependency layering across the three camera tracking repos

**Bead ID:** `aerobeat-input-camera-tracking-0kt`
**SubAgent:** `primary` (for `auditor` workflow role)
**Role:** `auditor`
**References:** `REF-01`, `REF-02`, `REF-03`
**Prompt:** Inspect `REF-01`, `REF-02`, and `REF-03`. Claim the bead on start once assigned. Verify whether `/src/` in `aerobeat-input-camera-tracking` uses `aerobeat-tool-camera-tracking` for all camera-tracking interactions, and whether `aerobeat-tool-camera-tracking` relies on `aerobeat-vendor-mediapipe-python` as the vendor repo containing the Python sidecar in repo root. Produce a file-by-file audit with evidence for compliant paths, bypasses, and ambiguities. Do not modify code. Close the bead only if audit evidence is complete.

**Folders Created/Deleted/Modified:**
- `.plans/`

**Files Created/Deleted/Modified:**
- `.plans/2026-06-01-camera-tracking-audit.md`

**Status:** ✅ Complete

**Results:** Auditor completed the file-by-file dependency layering audit and wrote `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.plans/2026-06-01-camera-tracking-audit-report.md`. Overall verdict: FAIL. Findings: `aerobeat-tool-camera-tracking/src` is vendor-agnostic and `aerobeat-vendor-mediapipe-python` appears to correctly own the repo-root Python sidecar, but `aerobeat-input-camera-tracking/src` still contains multiple bypasses including direct vendor script loading, legacy local `python_mediapipe` ownership, direct process management, and direct localhost UDP/TCP/HTTP IPC paths.

---

## Final Results

**Status:** ✅ Complete

**What We Built:** Completed a file-by-file audit of the camera-tracking dependency layering across `aerobeat-input-camera-tracking`, `aerobeat-tool-camera-tracking`, and `aerobeat-vendor-mediapipe-python`.

**Reference Check:** `REF-02` and `REF-03` are satisfied in the audited seams: the tool repo is vendor-agnostic in `src/`, and the vendor repo owns the Python sidecar at repo root. `REF-01` is not fully aligned because the input repo still bypasses the tool layer in several `src/` files.

**Commits:**
- None.

**Lessons Learned:** The migration is partial: the contract path exists and is usable, but legacy direct runtime, transport, and vendor-composition paths remain in the input repo.

---

*Completed on 2026-06-01*
