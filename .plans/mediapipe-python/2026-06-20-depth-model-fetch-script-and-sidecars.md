# AeroBeat depth-model fetch script and sidecars

**Date:** 2026-06-20
**Status:** In Progress
**Last Updated:** 2026-06-20 11:54 EDT
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

**Results:** Claimed bead `aerobeat-input-camera-tracking-hxce` and independently QA'd the fetch workflow without modifying downloaded-artifact state in the repo. Verified that `scripts/depth-models.yaml` and `scripts/fetch-depth-models.sh` stay aligned on all three model ids, upstream URLs, and resolved destination paths by cross-checking the metadata against `--list` output and repo-root path resolution. Validation run: `bash -n scripts/fetch-depth-models.sh`; `scripts/fetch-depth-models.sh --help`; `scripts/fetch-depth-models.sh --list`; `scripts/fetch-depth-models.sh --dry-run`; `scripts/fetch-depth-models.sh --dry-run --model fastdepth-224-onnx`; `python3 -m json.tool scripts/depth-models.yaml`; `git check-ignore -v assets/depth_models/ ...`; and one constrained real fetch using `scripts/fetch-depth-models.sh --repo-root "$(mktemp -d)" --model fastdepth-224-onnx`, which downloaded a 5,775,869-byte ONNX file into a temporary repo root and then correctly skipped re-download on the second run. `.gitignore` truthfully ignores `assets/depth_models/` and `git ls-files assets/depth_models` returned no tracked artifacts. The workflow is honest about provenance/caveats: MiDaS is labeled `official_release_assets`, while FastDepth and Depth Anything V2 Small are explicitly labeled as community-sourced/runtime-export artifacts with notes that the canonical upstreams do not publish those exact ONNX/runtime files at the approved final paths. No QA fixes were required. Bead referenced: `aerobeat-input-camera-tracking-hxce`.

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

**Status:** ✅ Complete

**Results:** Auditor verified that `scripts/depth-models.yaml` and `scripts/fetch-depth-models.sh` align with the locked approved destination paths from `REF-01`, that the current boxing config points families at the MiDaS path and that path is present in the fetch metadata, that MiDaS is truthfully labeled as official while FastDepth and Depth Anything V2 Small are truthfully labeled as community/runtime-export artifacts, and that the ignored-download strategy is correctly implemented via `.gitignore` with no tracked artifacts under `assets/depth_models/`. No blocking issues were found and the bead was closed cleanly. Bead referenced: `aerobeat-input-camera-tracking-p2cr`.

---

### Task 4: Fetch the approved depth artifacts locally and widen ignore coverage

**Bead ID:** `aerobeat-input-camera-tracking-9moj`
**SubAgent:** `primary`
**Role:** `coder`
**References:** `REF-01`, `REF-02`, `REF-03`
**Prompt:** Claim bead `aerobeat-input-camera-tracking-9moj` on start with `bd update aerobeat-input-camera-tracking-9moj --status in_progress --json`. In `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking`, use the new fetch workflow to actually materialize the approved depth artifacts locally. Also widen the ignore coverage if needed so the higher-level downloaded-artifact folder is safely ignored and the strategy stays truthful. Verify the fetched files land at the approved paths, record actual sizes/results, update the active plan with what happened, commit and push any repo-file changes (script/config/gitignore/plan only - not downloaded model binaries), and close the bead with a concrete reason when done.

**Folders Created/Deleted/Modified:**
- `scripts/`
- `assets/depth_models/`
- `.plans/mediapipe-python/`

**Files Created/Deleted/Modified:**
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.gitignore`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.plans/mediapipe-python/2026-06-20-depth-model-fetch-script-and-sidecars.md`
- downloaded local model artifacts under `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/assets/depth_models/` (local-only, not committed)

**Status:** ✅ Complete

**Results:** Claimed bead `aerobeat-input-camera-tracking-9moj` and ran the real local materialization workflow with `scripts/fetch-depth-models.sh --force` from repo root. All configured models fetched successfully to the resolved approved local paths under `assets/depth_models/`: MiDaS landed as the expected OpenVINO directory pair at `assets/depth_models/midas/openvino_midas_v21_small_256/openvino_midas_v21_small_256.xml` (554,444 bytes) and `assets/depth_models/midas/openvino_midas_v21_small_256/openvino_midas_v21_small_256.bin` (33,127,892 bytes); FastDepth landed as `assets/depth_models/fastdepth/fastdepth_224_onnx/fastdepth.onnx` (5,775,869 bytes); and Depth Anything V2 Small landed as `assets/depth_models/depth_anything_v2/depth_anything_v2_small/depth_anything_v2_small.onnx` (99,373,606 bytes). No configured model failed and the artifact shapes matched the metadata: one directory-backed OpenVINO pair for MiDaS plus one ONNX file each for FastDepth and Depth Anything V2 Small. Ignore coverage did not need widening beyond the existing higher-level repo-local rule `assets/depth_models/`; validation confirmed that folder-level rule already ignores the entire downloaded-artifact tree Derrick asked about. Validation run: `scripts/fetch-depth-models.sh --force`; `find assets/depth_models -type f -printf '%P\t%s bytes\n' | sort`; `git check-ignore -v assets/depth_models assets/depth_models/midas/openvino_midas_v21_small_256/openvino_midas_v21_small_256.xml assets/depth_models/fastdepth/fastdepth_224_onnx/fastdepth.onnx assets/depth_models/depth_anything_v2/depth_anything_v2_small/depth_anything_v2_small.onnx`; and `git status --short --ignored assets/depth_models`, which reported `!! assets/depth_models/` and no tracked download artifacts. Only repo-file follow-up needed here was the plan update; downloaded binaries remain local-only and uncommitted. Bead referenced: `aerobeat-input-camera-tracking-9moj`.

---

### Task 5: QA fetched artifacts and ignore coverage

**Bead ID:** `aerobeat-input-camera-tracking-yzft`
**SubAgent:** `primary`
**Role:** `qa`
**References:** `REF-01`, `REF-02`, `REF-03`
**Prompt:** Claim bead `aerobeat-input-camera-tracking-yzft` on start with `bd update aerobeat-input-camera-tracking-yzft --status in_progress --json`. Independently QA the local depth-artifact fetch results and widened ignore coverage in `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking`. Verify the expected files exist at the approved paths, verify ignored-download behavior at the higher-level folder, and confirm the plan accurately records actual fetch results and any caveats. Update the plan with QA findings and close the bead with a concrete reason when done.

**Folders Created/Deleted/Modified:**
- `assets/depth_models/`
- `.plans/mediapipe-python/`

**Files Created/Deleted/Modified:**
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.gitignore`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.plans/mediapipe-python/2026-06-20-depth-model-fetch-script-and-sidecars.md`

**Status:** ⏳ Pending

**Results:** Pending.

---

### Task 6: Audit fetched artifacts and ignore coverage

**Bead ID:** `aerobeat-input-camera-tracking-qf1h`
**SubAgent:** `primary`
**Role:** `auditor`
**References:** `REF-01`, `REF-02`, `REF-03`
**Prompt:** Claim bead `aerobeat-input-camera-tracking-qf1h` on start with `bd update aerobeat-input-camera-tracking-qf1h --status in_progress --json`. Audit the local depth-artifact fetch result, higher-level ignore coverage, and plan truthfulness in `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking`. Confirm the fetched artifacts that are supposed to exist actually exist, confirm downloaded artifacts remain untracked, and confirm the plan tells the complete story. Close the bead if it passes or report the blocking gap if it fails.

**Folders Created/Deleted/Modified:**
- `assets/depth_models/`
- `.plans/mediapipe-python/`

**Files Created/Deleted/Modified:**
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.gitignore`
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
