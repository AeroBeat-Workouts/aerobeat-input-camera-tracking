# AeroBeat Input MediaPipe Python Runtime Pip Bootstrap Fix

**Date:** 2026-05-18  
**Status:** Draft  
**Agent:** Pico 🐱‍🏍

---

## Goal

Fix the `prepare_runtime.py --install-requirements` failure on fresh Zorin so the repo-local MediaPipe sidecar runtime can bootstrap and install Python requirements successfully.

---

## Overview

The current failure is not a generic missing-Python problem. The runtime-local venv exists at `python_mediapipe/assets/runtimes/linux-x64/venv/`, and its interpreter runs, but `python -m pip` fails with `No module named pip`. That means the venv was created or left behind in a partially bootstrapped state: the interpreter is present, but pip was not actually installed into that venv.

A quick probe shows that both the host Python and the runtime venv can access `ensurepip`, which strongly suggests the fastest safe fix is to make runtime prep robust against a pip-less venv instead of assuming pip is always present. The execution path should diagnose whether the venv is stale/corrupt, decide whether to recreate it or self-heal it with `ensurepip`, then validate the fix by rerunning the real runtime prep flow on this machine.

---

## REFERENCES

| ID | Description | Path |
| --- | --- | --- |
| `REF-01` | Runtime prep entrypoint and current install flow | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-mediapipe-python/python_mediapipe/prepare_runtime.py` |
| `REF-02` | Existing runtime root and venv location under the repo | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-mediapipe-python/python_mediapipe/assets/runtimes/linux-x64/venv/` |
| `REF-03` | Current observed failure from Derrick's shell | `python_mediapipe/assets/runtimes/linux-x64/venv/bin/python -m pip` -> `No module named pip` |

---

## Tasks

### Task 1: Diagnose the pip-less runtime venv state

**Bead ID:** `aerobeat-input-mediapipe-python-alz`  
**SubAgent:** `primary` (for `research`)  
**Role:** `research`  
**References:** `REF-01`, `REF-02`, `REF-03`  
**Prompt:** Inspect the runtime-local venv and `prepare_runtime.py` flow for bead `<id>`. Claim the bead on start. Determine whether the failure is best fixed by recreating the venv, bootstrapping pip into an existing venv with `ensurepip`, or changing the script to self-heal automatically. Summarize the root cause and recommend the smallest robust fix.

**Folders Created/Deleted/Modified:**
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-mediapipe-python/python_mediapipe/assets/runtimes/linux-x64/venv/`

**Files Created/Deleted/Modified:**
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-mediapipe-python/python_mediapipe/prepare_runtime.py`

**Status:** ✅ Complete

**Results:** Confirmed the runtime-local venv is real but incomplete: the interpreter and `pyvenv.cfg` exist, `site-packages` is effectively empty, `python -m pip` fails, and `python -m ensurepip --version` works. A fresh control venv on this same host creates pip correctly, so the root cause is not host Python but `prepare_runtime.py` reusing an existing runtime venv without validating that pip bootstrap completed. Recommended fix: before requirement installation, probe `python -m pip --version`, auto-repair with `python -m ensurepip --upgrade` if missing, re-check, and only fail hard if pip still cannot be restored. Reference validated: `REF-01`, `REF-03`.

---

### Task 2: Implement the runtime bootstrap fix

**Bead ID:** `aerobeat-input-mediapipe-python-4tc`  
**SubAgent:** `primary` (for `coder`)  
**Role:** `coder`  
**References:** `REF-01`, `REF-02`, `REF-03`  
**Prompt:** Implement the approved fix for bead `<id>`. Claim the bead on start. Update the runtime prep flow so a fresh-machine or partially bootstrapped venv can successfully reach requirement installation. Keep the change minimal, robust, and grounded in the repo’s current runtime contract. Run repo-local validation for the touched flow and commit the change if the repo workflow allows it.

**Folders Created/Deleted/Modified:**
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-mediapipe-python/python_mediapipe/assets/runtimes/linux-x64/venv/`

**Files Created/Deleted/Modified:**
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-mediapipe-python/python_mediapipe/prepare_runtime.py`

**Status:** ✅ Complete

**Results:** Implemented the minimal self-heal in `prepare_runtime.py` so the runtime install path now probes `python -m pip --version` inside the reused runtime venv, repairs missing pip via `python -m ensurepip --upgrade`, re-checks pip, and fails clearly only if pip still cannot be restored. Validation passed on the real host flow: `python3 -m py_compile python_mediapipe/*.py`, `python3 python_mediapipe/prepare_runtime.py --platform linux-x64 --mode dev --install-requirements --validate --json`, `venv/bin/python -m pip --version`, and `venv/bin/python -c 'import mediapipe, cv2, numpy; print("imports ok")'`. Commit landed as `5937478` (`Repair reused runtime venv pip bootstrap`). References validated: `REF-01`, `REF-03`.

---

### Task 3: Verify end-to-end runtime prep on this host

**Bead ID:** `aerobeat-input-mediapipe-python-qmq`  
**SubAgent:** `primary` (for `auditor`)  
**Role:** `auditor`  
**References:** `REF-01`, `REF-02`, `REF-03`  
**Prompt:** Independently verify bead `<id>`. Claim the bead on start. Re-run the relevant runtime prep command(s) on this host and confirm the venv can reach pip and install requirements without the previous error. Report the exact validation command and outcome. Close the bead only if the original failure is truly resolved.

**Folders Created/Deleted/Modified:**
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-mediapipe-python/python_mediapipe/assets/runtimes/linux-x64/venv/`

**Files Created/Deleted/Modified:**
- none expected beyond runtime artifacts

**Status:** ⏳ Pending

**Results:** Pending.

---

## Final Results

**Status:** ⏳ Pending

**What We Built:** Pending.

**Reference Check:** Pending.

**Commits:**
- Pending.

**Lessons Learned:** Pending.

---

*Completed on Pending*
