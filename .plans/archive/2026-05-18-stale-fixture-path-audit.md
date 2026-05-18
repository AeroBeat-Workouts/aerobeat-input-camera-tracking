# AeroBeat Input MediaPipe Python Stale Fixture Path Audit

**Date:** 2026-05-18  
**Status:** Draft  
**Agent:** Pico 🐱‍🏍

---

## Goal

Audit the repo for remaining bad prerecorded file path references and fix the ones that are still live/product-facing.

---

## Overview

We already fixed the two highest-impact user-facing failures: the Flow and Boxing proving scenes each had stale serialized prerecorded video paths. A first sweep now shows several other path references across the repo, but they are not all equal. Some are expected historical evidence in archived plans or prior test output, while others may still be active docs, fixture templates, helper scripts, or runtime-owned artifacts.

So this audit should separate references into three buckets: (1) active product/runtime surfaces that must be fixed now, (2) docs/templates/examples that should be updated to stay truthful, and (3) historical artifacts such as prior reports or archived plans that should usually be preserved rather than rewritten. The implementation pass should only touch the first two buckets unless Derrick explicitly wants history rewritten.

---

## REFERENCES

| ID | Description | Path |
| --- | --- | --- |
| `REF-01` | Testbed proving scenes | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-mediapipe-python/.testbed/scenes/` |
| `REF-02` | Fixture asset tree and sidecars | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-mediapipe-python/.testbed/assets/fixtures/` |
| `REF-03` | Shared proving-harness and AutoStart launch path | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-mediapipe-python/.testbed/scripts/` and `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-mediapipe-python/src/autostart_manager.gd` |
| `REF-04` | Fixture docs/templates that may still name stale sample files | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-mediapipe-python/docs/` |
| `REF-05` | Existing repo-local evidence of stale references from initial grep sweep | `grep results from 2026-05-18 audit kickoff` |

---

## Tasks

### Task 1: Inventory and classify remaining stale path references

**Bead ID:** `aerobeat-input-mediapipe-python-bvc`  
**SubAgent:** `primary` (for `research`)  
**Role:** `research`  
**References:** `REF-01`, `REF-02`, `REF-03`, `REF-04`, `REF-05`  
**Prompt:** Claim the assigned bead on start. Audit the repo for remaining bad prerecorded file path references. Classify each hit as active/runtime, docs/template/example, or historical artifact/test output. For active/docs hits, verify whether the referenced file exists. Produce a concrete fix list and explicitly separate what should be changed now from what should remain as historical evidence.

**Folders Created/Deleted/Modified:**
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-mediapipe-python/`

**Files Created/Deleted/Modified:**
- none during diagnosis

**Status:** ✅ Complete

**Results:** Audited repo-owned prerecorded asset references and classified the remaining stale-looking hits. Active/runtime/product surfaces are clean: both proving scenes point at real existing `.mp4` fixtures and all Boxing `.fixture.yaml` sidecars currently resolve to existing sibling `.mp4`s. The remaining non-historical stale references are docs/examples: `README.md` points at a nonexistent example sidecar, and `docs/proving-scene-video-fixtures.md`, `docs/proving-scene-video-fixtures-plain-language.md`, and `docs/proving-scene-video-fixture-template.fixture.yaml` still show the old `boxing__punch_left__positive__guard_start_end__take_01` basename that no longer exists as presented. Historical artifacts that should remain untouched include `.plans/**`, prior repro/test-result folders, and legacy provenance notes inside fixture YAML comments. Recommended next step: fix only the docs/example surfaces to point at a real current sample. References validated: `REF-01` through `REF-05`.

---

### Task 2: Fix remaining live/truthful stale references

**Bead ID:** `aerobeat-input-mediapipe-python-bx4`  
**SubAgent:** `primary` (for `coder`)  
**Role:** `coder`  
**References:** `REF-01`, `REF-02`, `REF-03`, `REF-04`, `REF-05`  
**Prompt:** Claim the assigned bead on start. Apply the smallest truthful fixes for the non-historical stale path references identified by the audit. Prioritize active runtime/product surfaces first, then docs/templates/examples that are misleading today. Do not rewrite archived plans or historical test output unless explicitly instructed. Validate the changed references and commit/push by default.

**Folders Created/Deleted/Modified:**
- whichever repo-owned active/docs surfaces need correction

**Files Created/Deleted/Modified:**
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-mediapipe-python/README.md`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-mediapipe-python/docs/proving-scene-video-fixtures.md`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-mediapipe-python/docs/proving-scene-video-fixtures-plain-language.md`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-mediapipe-python/docs/proving-scene-video-fixture-template.fixture.yaml`

**Status:** ✅ Complete

**Results:** Updated only the live docs/example surfaces that were still misleading. Repointed the stale old punch-left basenames to the real current sample `boxing_punch_left_x4_while_guarding_take_01` in `README.md`, `docs/proving-scene-video-fixtures.md`, `docs/proving-scene-video-fixtures-plain-language.md`, and `docs/proving-scene-video-fixture-template.fixture.yaml`. Validation confirmed the referenced `.yaml` and `.mp4` sample files exist and the targeted stale example strings are gone from those four files. Historical artifacts such as `.plans/**`, repro/test-result folders, and provenance comments were left untouched. Commit landed as `a0d0362` (`docs: fix stale proving fixture example paths`). References validated: `REF-02`, `REF-04`, `REF-05`.

---

### Task 3: Audit the final remaining-reference state

**Bead ID:** `aerobeat-input-mediapipe-python-08g`  
**SubAgent:** `primary` (for `auditor`)  
**Role:** `auditor`  
**References:** `REF-01`, `REF-02`, `REF-03`, `REF-04`, `REF-05`  
**Prompt:** Claim the assigned bead on start. Independently verify that the repo no longer contains bad prerecorded file path references in active runtime/product surfaces, and that any remaining stale-looking references are intentionally historical or otherwise justified. Summarize what remains and why.

**Folders Created/Deleted/Modified:**
- whichever repo-owned surfaces were touched

**Files Created/Deleted/Modified:**
- none expected beyond validation artifacts

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
