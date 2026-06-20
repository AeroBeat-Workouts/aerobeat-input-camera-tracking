# AeroBeat depth-model fetch script and sidecars

**Date:** 2026-06-20  
**Status:** In Progress  
**Last Updated:** 2026-06-20 11:24 EDT  
**Blocked Reason:** None  
**Agent:** `pico`

---

## Goal

Create a repo-root `scripts/` download script plus repo-owned YAML metadata sidecar(s) so AeroBeat can sync code/config and fetch the approved monocular depth artifacts locally instead of committing the binaries to git.

---

## Overview

Derrick approved the explicit repo-local depth artifact paths for MiDaS, FastDepth, and Depth Anything V2 Small, but asked to avoid committing the model binaries themselves. The next slice is therefore to create a durable fetch workflow owned by `aerobeat-input-camera-tracking`: a script in `scripts/` that downloads the three approved artifacts into the locked repo-local paths, and a YAML sidecar in the same folder that records the model ids, source URLs, and destination paths.

The script should be designed for sync-first use: after pulling the repo, Derrick should be able to run one command locally to materialize the depth-model assets. The metadata file should be human-readable and future-proof enough to update URLs or swap artifact families without rewriting the script logic. The implementation should prefer simple shell tooling already common on this host, create parent directories as needed, avoid re-downloading when the target already exists unless explicitly forced, and truthfully document any export/manual-step caveats for models whose upstream distribution does not provide the exact final runtime artifact in one direct file.

---

## REFERENCES

| ID | Description | Path |
| --- | --- | --- |
| `REF-01` | Active depth research note with locked artifact-path recommendation | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.plans/mediapipe-python/2026-06-19-depth-model-research-note.md` |
| `REF-02` | Shipped boxing depth config that now includes `depth.model.artifact_path` | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/assets/boxing.gesture_detection.yaml` |
| `REF-03` | Repo root / owning implementation location | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/` |

---

## Tasks

### Task 1: Implement fetch script and YAML sidecar

**Bead ID:** `aerobeat-input-camera-tracking-x9w1`  
**SubAgent:** `primary`  
**Role:** `coder`  
**References:** `REF-01`, `REF-02`, `REF-03`  
**Prompt:** Claim bead `aerobeat-input-camera-tracking-x9w1` on start with `bd update aerobeat-input-camera-tracking-x9w1 --status in_progress --json`. In `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking`, create a repo-root `scripts/` folder if needed and implement a fetch workflow for the approved monocular depth artifacts. Add a YAML sidecar in that same folder that lists the model names/ids, upstream URLs, and exact repo-local destination paths approved in the active depth plan. Then implement a script that reads or faithfully mirrors that metadata, creates parent directories, downloads the artifacts to those paths, skips already-present files unless forced, and documents any manual/export caveats honestly. Prefer simple repo-native shell tooling. Update the active plan with what you actually built, include the bead id in the results, run relevant repo-local validation (shellcheck if available, at minimum `bash -n` and a non-destructive help/dry-run path), commit and push by default, and close the bead with a concrete reason when done.

**Folders Created/Deleted/Modified:**
- `scripts/`
- `.plans/mediapipe-python/`
- `assets/` (gitignore coverage only; no model binaries committed)

**Files Created/Deleted/Modified:**
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/scripts/fetch-depth-models.sh`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/scripts/depth-models.yaml`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.gitignore`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.plans/mediapipe-python/2026-06-20-depth-model-fetch-script-and-sidecars.md`

**Status:** ✅ Complete

**Results:** Claimed bead `aerobeat-input-camera-tracking-x9w1`, then added a dependency-free `scripts/fetch-depth-models.sh` bash wrapper with embedded `python3` logic plus a JSON-compatible YAML sidecar at `scripts/depth-models.yaml`. The script resolves the approved `res://addons/aerobeat-input-camera-tracking/...` destinations back into repo-local filesystem paths, creates parent directories, skips existing targets unless `--force` is passed, supports `--help`, `--list`, `--model`, and non-destructive `--dry-run`, and prints provenance/truthfulness notes per model. The metadata records exact approved destination paths plus source URLs for MiDaS OpenVINO small, FastDepth ONNX, and Depth Anything V2 Small ONNX. To stay truthful about artifact provenance, the sidecar and script explicitly note that MiDaS uses official release assets, while FastDepth and Depth Anything V2 Small rely on community-distributed ONNX artifacts because the canonical upstreams do not publish those exact runtime files at the approved final paths. Validation run so far: `bash -n scripts/fetch-depth-models.sh`, `scripts/fetch-depth-models.sh --help`, `scripts/fetch-depth-models.sh --list`, `scripts/fetch-depth-models.sh --dry-run`, `python3 -m json.tool scripts/depth-models.yaml`, and HEAD checks against every configured source URL (all returned HTTP 200). Bead referenced: `aerobeat-input-camera-tracking-x9w1`.

---

### Task 2: QA the fetch workflow

**Bead ID:** `aerobeat-input-camera-tracking-hxce`  
**SubAgent:** `primary`  
**Role:** `qa`  
**References:** `REF-01`, `REF-02`, `REF-03`  
**Prompt:** Claim bead `aerobeat-input-camera-tracking-hxce` on start with `bd update aerobeat-input-camera-tracking-hxce --status in_progress --json`. Independently QA the new depth-model fetch workflow in `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking`. Verify the YAML sidecar and script agree on the model ids, URLs, and destination paths; verify the script syntax/help/dry-run behavior; and verify the workflow is truthful about any artifact caveats instead of pretending unavailable files can be fetched directly. Use the highest-fidelity safe validation available without unnecessary large downloads unless needed. Update the active plan with actual QA findings, commit/push if you make any required fixes in your own branch flow, and close the bead with a concrete reason when done.

**Folders Created/Deleted/Modified:**
- `scripts/`
- `.plans/mediapipe-python/`

**Files Created/Deleted/Modified:**
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/scripts/<new fetch script>`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/scripts/<new yaml sidecar>`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.plans/mediapipe-python/2026-06-20-depth-model-fetch-script-and-sidecars.md`

**Status:** ✅ Complete

**Results:** Claimed bead `aerobeat-input-camera-tracking-hxce` and independently QA’d the fetch workflow without modifying downloaded-artifact state in the repo. Verified that `scripts/depth-models.yaml` and `scripts/fetch-depth-models.sh` stay aligned on all three model ids, upstream URLs, and resolved destination paths by cross-checking the metadata against `--list` output and repo-root path resolution. Validation run: `bash -n scripts/fetch-depth-models.sh`; `scripts/fetch-depth-models.sh --help`; `scripts/fetch-depth-models.sh --list`; `scripts/fetch-depth-models.sh --dry-run`; `scripts/fetch-depth-models.sh --dry-run --model fastdepth-224-onnx`; `python3 -m json.tool scripts/depth-models.yaml`; `git check-ignore -v assets/depth_models/ ...`; and one constrained real fetch using `scripts/fetch-depth-models.sh --repo-root "$(mktemp -d)" --model fastdepth-224-onnx`, which downloaded a 5,775,869-byte ONNX file into a temporary repo root and then correctly skipped re-download on the second run. `.gitignore` truthfully ignores `assets/depth_models/` and `git ls-files assets/depth_models` returned no tracked artifacts. The workflow is honest about provenance/caveats: MiDaS is labeled `official_release_assets`, while FastDepth and Depth Anything V2 Small are explicitly labeled as community-sourced/runtime-export artifacts with notes that the canonical upstreams do not publish those exact ONNX/runtime files at the approved final paths. No QA fixes were required. Bead referenced: `aerobeat-input-camera-tracking-hxce`.

---

### Task 3: Audit the fetch workflow and truthfulness

**Bead ID:** `aerobeat-input-camera-tracking-p2cr`  
**SubAgent:** `primary`  
**Role:** `auditor`  
**References:** `REF-01`, `REF-02`, `REF-03`  
**Prompt:** Claim bead `aerobeat-input-camera-tracking-p2cr` on start with `bd update aerobeat-input-camera-tracking-p2cr --status in_progress --json`. Audit the completed depth-model fetch workflow in `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking` against the active plan, the locked artifact paths, and the QA evidence. Confirm the script and YAML sidecar are truthful, repo-owned, aligned to the approved paths, and do not silently promise more than they can fetch. Confirm the plan reflects reality. If it passes, close the bead directly with a concrete reason; if it fails, leave the bead open and describe the gap clearly.

**Folders Created/Deleted/Modified:**
- `scripts/`
- `.plans/mediapipe-python/`

**Files Created/Deleted/Modified:**
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/scripts/<new fetch script>`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/scripts/<new yaml sidecar>`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.plans/mediapipe-python/2026-06-20-depth-model-fetch-script-and-sidecars.md`

**Status:** ⏳ Pending

**Results:** Pending.

---

## Final Results

**Status:** ⏳ In Progress

**What We Built:** Pending.

**Reference Check:** Pending.

**Commits:**
- Pending.

**Lessons Learned:** Pending.
