# AeroBeat uppercut gate and monocular depth research

**Date:** 2026-06-19  
**Status:** Complete  
**Last Updated:** 2026-06-19 23:31 EDT  
**Blocked Reason:** None.  
**Agent:** `pico`

---

## Goal

Confirm the current boxing punch-family threshold gate truth, lock the approved depth YAML contract, then implement the new depth threshold config exposure in the punch-family gesture inspectors so Derrick can sync and play test once the full coder → QA → auditor loop is complete.

---

## Overview

This plan started as uppercut-gate and monocular-depth research, then expanded—still within the same approved boxing-threshold seam—into the first implementation slice Derrick actually wants next: land the approved depth threshold YAML contract and expose those new variables anywhere the punch-family gesture inspectors already surface comparable threshold values.

The research portion is now materially done. We confirmed the exact current hook and uppercut 2D threshold contracts, ranked the top practical speed-first monocular depth candidates, and distilled the final repo-style YAML contract plus exact patch-ready insertion blocks for `assets/boxing.gesture_detection.yaml`. The new executable work is therefore narrower and cleaner than the original open-ended research question: wire the approved config into the shipped YAML, plumb it into the punch-family inspector surfaces, verify the inspector output truthfully reflects the new values, and stop only when the repo is genuinely ready for Derrick to sync and play test.

Per Derrick's instructions, once execution is approved for this plan update we should keep moving without further routine confirmation until one of two end states: (1) the change is complete, truth-checked, and ready for sync/play test, at which point we land the plane; or (2) we get genuinely stuck and cannot advance after a few heartbeats, at which point we also land the plane with a clear blocker handoff.

---

## REFERENCES

| ID | Description | Path |
| --- | --- | --- |
| `REF-01` | Latest AeroBeat Pico handoff showing prior boxing threshold/runtime plan is complete and archived | `/home/derrick/.openclaw/workspace/projects/openclaw-pico/handoffs/handoff-2026-06-19T22-29-00-04-00.md` |
| `REF-02` | Current threshold boxing detector implementation | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/src/detectors/pose_detector_substrate.gd` |
| `REF-03` | Research note capturing practical monocular depth ranking and integration constraints | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.plans/mediapipe-python/2026-06-19-depth-model-research-note.md` |
| `REF-04` | Current shipped boxing gesture config that will receive the approved depth blocks | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/assets/boxing.gesture_detection.yaml` |
| `REF-05` | Punch-family proving / gesture inspector implementation surface | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.testbed/scripts/boxing_proving_harness.gd` |

---

## Tasks

### Task 1: Inspect current threshold backend uppercut and hook gates

**Bead ID:** `aerobeat-input-camera-tracking-cyiy`  
**SubAgent:** `primary`  
**Role:** `research`  
**References:** `REF-01`, `REF-02`  
**Prompt:** Inspect `REF-02` for the threshold boxing gesture backend. Confirm whether uppercuts already require wrist-above-elbow in 2D camera space, how hooks enforce side-of-elbow gating, and whether the present behavior exactly matches Derrick’s requested contract. Claim the bead on start and report precise source locations.

**Folders Created/Deleted/Modified:**
- `src/detectors/`

**Files Created/Deleted/Modified:**
- `src/detectors/pose_detector_substrate.gd`

**Status:** ✅ Complete

**Results:** Confirmed the detector consumes gameplay-space landmarks with flipped Y, so the current uppercut gate already means wrist-above-elbow in gameplay 2D space. Also confirmed hooks use a horizontal alignment gate plus side-of-elbow check. Exact source locations and shipped boxing config references were recorded in `REF-03`.

---

### Task 2: Research fastest practical monocular depth option for AeroBeat punch discrimination

**Bead ID:** `aerobeat-input-camera-tracking-8ivj`  
**SubAgent:** `primary`  
**Role:** `research`  
**References:** `REF-02`, `REF-03`  
**Prompt:** Research the fastest practical real-time pretrained monocular depth model for this AeroBeat camera-tracking stack, with emphasis on CPU-friendly or lightweight inference. Compare likely candidates for straight-vs-hook/uppercut relative-depth trend detection, note tradeoffs, and recommend one model plus integration constraints.

**Folders Created/Deleted/Modified:**
- `assets/`
- `scripts/`
- `src/`

**Files Created/Deleted/Modified:**
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.plans/mediapipe-python/2026-06-19-depth-model-research-note.md`

**Status:** ✅ Complete

**Results:** Ranked MiDaS v2.1 Small 256 / OpenVINO small as the safest first practical option, FastDepth as the speed-first backup, and Depth Anything V2 Small as the heavier robustness fallback. Also documented the recommended wrist-vs-torso closeness signal, window scoring shape, and Surface Pro 8 class risks in `REF-03`.

---

### Task 3: Define YAML contract, comments, asset placement, and implementation seam

**Bead ID:** `aerobeat-input-camera-tracking-2wxx`  
**SubAgent:** `primary`  
**Role:** `auditor`  
**References:** `REF-03`, `REF-04`  
**Prompt:** Before code execution, inspect the existing YAML files and comment style, then recommend the exact new YAML variables, defaults, nesting, and comments needed for depth-based punch-family gating. Also recommend the best owning repo and storage location for a pretrained depth model. Evaluate Derrick’s proposed `aerobeat-input-camera-tracking/assets/` assumption against packaging, runtime loading, and maintenance concerns. Claim the bead on start and provide a concrete recommendation.

**Folders Created/Deleted/Modified:**
- `assets/`

**Files Created/Deleted/Modified:**
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.plans/mediapipe-python/2026-06-19-depth-model-research-note.md`

**Status:** ✅ Complete

**Results:** The repo-style depth contract was approved: `depth:` nested under each punch family's `threshold:` block with `evaluation`, `thresholds`, and `debug` subsections; conservative defaults remain disabled everywhere; and exact insertion guidance for `REF-04` was documented in `REF-03`.

---

### Task 4: Define depth YAML variable names and comment style before implementation

**Bead ID:** `aerobeat-input-camera-tracking-hpgi`  
**SubAgent:** `primary`  
**Role:** `research`  
**References:** `REF-03`, `REF-04`  
**Prompt:** Inspect the shipped YAML configuration files in this repo and derive the existing comment/documentation style. Propose the exact YAML variable names, placement, defaults, and inline comments for the new depth-based boxing-gating controls before any implementation begins. The proposal should explicitly cover straight-punch positive depth-change behavior and hook/uppercut low-depth-change behavior.

**Folders Created/Deleted/Modified:**
- `assets/`

**Files Created/Deleted/Modified:**
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.plans/mediapipe-python/2026-06-19-depth-model-research-note.md`

**Status:** ✅ Complete

**Results:** Finalized the exact approved variable names, defaults, comments, and minimal patch-ready insertion blocks for `straight_punch.threshold.depth`, `hook.threshold.depth`, and `uppercut.threshold.depth`. Derrick approved using those YAML decisions as the implementation contract.

---

### Task 5: Land approved depth YAML contract and expose new variables in punch-family gesture inspectors

**Bead ID:** `aerobeat-input-camera-tracking-2dsg`  
**SubAgent:** `primary`  
**Role:** `coder`  
**References:** `REF-03`, `REF-04`, `REF-05`  
**Prompt:** Implement the approved boxing depth-config contract. Claim bead `aerobeat-input-camera-tracking-2dsg` on start with `bd update aerobeat-input-camera-tracking-2dsg --status in_progress --json`. Land the approved `depth:` blocks in `assets/boxing.gesture_detection.yaml`, then expose the new threshold variables in the same punch-family gesture inspector surfaces that already show other threshold values. Keep the behavior honest: if a value is config-only and not yet runtime-active, present it clearly rather than implying live depth inference exists. Run all relevant repo-local validation you can for this slice, commit and push by default, then close the bead with a concrete reason when done.

**Folders Created/Deleted/Modified:**
- `assets/`
- `.testbed/scripts/`
- `.testbed/tests/unit/`

**Files Created/Deleted/Modified:**
- `assets/boxing.gesture_detection.yaml`
- `.testbed/scripts/boxing_proving_harness.gd`
- `.testbed/tests/unit/test_boxing_proving_harness_profiles_and_debug.gd`

**Status:** ✅ Complete

**Results:** Landed the approved `depth:` blocks under `straight_punch.threshold`, `hook.threshold`, and `uppercut.threshold` in `REF-04`; exposed the staged depth variables in the boxing punch-family inspector surfaces and event-feed tuning text via `REF-05`; and kept the UI honest by explicitly presenting the depth contract as config-only rather than implying live runtime depth inference. Added harness-side config-reading glue so nested `threshold.depth` values display truthfully, and added unit coverage for the new staged inspector output. Validation passed with `godot --headless --path .testbed --script addons/aerobeat-vendor-godot-unit-test/gut_cmdln.gd -gtest=res://tests/unit/test_boxing_proving_harness_profiles_and_debug.gd -gexit`. Commit: `8749e17` (`Add staged boxing depth config contract`). Bead `aerobeat-input-camera-tracking-2dsg` was closed.
---

### Task 6: QA punch-family inspector exposure for the new depth threshold variables

**Bead ID:** `aerobeat-input-camera-tracking-nkey`  
**SubAgent:** `primary`  
**Role:** `qa`  
**References:** `REF-04`, `REF-05`  
**Prompt:** Claim bead `aerobeat-input-camera-tracking-nkey` on start with `bd update aerobeat-input-camera-tracking-nkey --status in_progress --json`. Verify the new depth threshold variables appear in the same punch-family gesture inspectors as comparable threshold values, with correct labels and threshold/current presentation semantics. Use the highest-fidelity validation path available in this repo, including proving-harness / served-app checks if practical. Record what was actually verified, then close the bead only if the inspector truth matches the landed config.

**Folders Created/Deleted/Modified:**
- `.testbed/scripts/`
- `.testbed/`
- `.temp/qa-depth-2026-06-19/fixture-captures/`

**Files Created/Deleted/Modified:**
- `.temp/qa-depth-2026-06-19/fixture-captures/hook_left/report.md`
- `.temp/qa-depth-2026-06-19/fixture-captures/uppercut_left/report.md`
- `.temp/qa-depth-2026-06-19/fixture-captures/*/report.json`

**Status:** ✅ Complete

**Results:** QA passed on commit `8749e1769034`. Verified the approved depth config contract exists in `REF-04` for straight, hook, and uppercut with the expected family-specific threshold keys and values; verified the same punch-family inspector surfaces in `REF-05` expose those staged depth rows alongside comparable threshold rows; verified family-aware label semantics (`min_*` for straight and `max_*` for hook/uppercut); and verified the inspector explicitly says depth is disabled in config only and not consumed by the live threshold runtime yet. Targeted unit coverage for the staged-depth strings passed in `.testbed/tests/unit/test_boxing_proving_harness_profiles_and_debug.gd`, and headless proving-harness fixture captures for hook-left and uppercut-left produced report artifacts showing the same honest staged-depth text in live Quick Stats. Known limitations: the repo-referenced `scripts/refresh_testbed_workbench.py` path was absent in this checkout, the full unit suite is not globally green outside this bead's scope, and headless captures emitted null-texture screenshot warnings while still producing usable text artifacts. Bead `aerobeat-input-camera-tracking-nkey` was closed.
---

### Task 7: Audit the YAML contract landing and inspector truth

**Bead ID:** `aerobeat-input-camera-tracking-tdrv`  
**SubAgent:** `primary`  
**Role:** `auditor`  
**References:** `REF-03`, `REF-04`, `REF-05`  
**Prompt:** Claim bead `aerobeat-input-camera-tracking-tdrv` on start with `bd update aerobeat-input-camera-tracking-tdrv --status in_progress --json`. Independently truth-check the coder + QA work against the approved YAML contract, the live inspector surfaces, the diff, and the recorded validation evidence. If it passes, close the bead with a precise reason. If it fails, report the exact gap and leave the bead active for retry/escalation.

**Folders Created/Deleted/Modified:**
- `assets/`
- `.testbed/scripts/`
- `.testbed/tests/unit/`
- `.temp/qa-depth-2026-06-19/fixture-captures/`

**Files Created/Deleted/Modified:**
- `assets/boxing.gesture_detection.yaml`
- `.testbed/scripts/boxing_proving_harness.gd`
- `.testbed/tests/unit/test_boxing_proving_harness_profiles_and_debug.gd`
- `.temp/qa-depth-2026-06-19/fixture-captures/hook_left/report.md`
- `.temp/qa-depth-2026-06-19/fixture-captures/uppercut_left/report.md`
- `.temp/qa-depth-2026-06-19/fixture-captures/*/report.json`

**Status:** ✅ Complete

**Results:** Audit passed on commit `8749e1769034`. Confirmed the approved `depth:` blocks exist exactly at `straight_punch.threshold.depth`, `hook.threshold.depth`, and `uppercut.threshold.depth` in `REF-04`; confirmed the proving/inspector surfaces in `REF-05` map straight depth thresholds to `min_*` labels and hook/uppercut depth thresholds to `max_*` labels; confirmed the wording explicitly states the live threshold runtime does not consume depth yet; and confirmed there is no hidden runtime consumer in `src/`, so the implementation truthfully stays within the staged-contract scope. Reviewed the coder diff, reviewed QA fixture-capture reports, and re-ran the targeted harness unit test command with a passing `39/39` result. Caveats remained limited to pre-existing warning/orphan noise on test exit and the expected config-only status for hook/uppercut depth display. Bead `aerobeat-input-camera-tracking-tdrv` was closed.

---

## Final Results

**Status:** ✅ Complete

**What We Built:** Confirmed the current hook/uppercut 2D threshold gate truth, captured the practical speed-first monocular-depth research, landed the approved staged `depth:` YAML contract for straight/hook/uppercut in `assets/boxing.gesture_detection.yaml`, and exposed those new family-specific depth thresholds throughout the boxing punch-family inspector/proving surfaces with honest config-only wording. The implementation now gives Derrick the exact staged variables in config and inspector tooling needed for the next sync-and-play-test loop without pretending live depth inference already exists.

**Reference Check:** `REF-02` gate truth was verified and summarized in `REF-03`; `REF-04` now contains the approved staged depth blocks; and `REF-05` truthfully reflects those staged values and their non-runtime-consumed status.

**Commits:**
- `8749e17` - Add staged boxing depth config contract

**Lessons Learned:** Locking the config contract first made the execution slice straightforward. For inspector-heavy staged features, being explicit that values are config-only prevented false confidence about runtime support while still giving play-test tooling the right knobs and visibility.

---

*Completed on 2026-06-19*
