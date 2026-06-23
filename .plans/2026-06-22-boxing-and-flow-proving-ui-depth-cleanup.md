# Aerobeat Input Camera Tracking - Boxing / Flow Proving UI + Depth Cleanup

**Date:** 2026-06-22
**Status:** In Progress
**Last Updated:** 2026-06-22 21:53 EDT
**Blocked Reason:** None
**Agent:** `pico`

---

## Goal

Clean up stale proving-scene UI and make the boxing depth debug viewer truthful: no replay step buttons, no stray family timing text in the FPS corner, no thumbnail when all boxing depth checks are disabled, and a visible depth preview when depth is enabled and the runtime is actually producing one.

---

## Overview

Derrick asked to reset the Aerobeat Pico plan slate first, so all previously open Aerobeat Pico plans were marked stale and archived before starting this new slice. This plan now owns the current boxing / flow proving cleanup work.

The likely change surface is concentrated in the shared proving harness replay transport UI plus the boxing-specific depth debug overlay. The replay step buttons appear to come from the shared `.testbed/scripts/proving_harness.gd` playback control row, while the family timing label and RGB/depth thumbnail behavior live in `.testbed/scripts/depth_debug_viewer.gd` and its boxing harness integration in `.testbed/scripts/boxing_proving_harness.gd`.

Execution will follow the normal coder → QA → auditor loop. The coder will implement the UI/runtime fixes and run repo-local validation, QA will verify the proving scenes and the enabled/disabled depth states, and the auditor will independently truth-check that the cleanup matches Derrick's requested behavior exactly.

---

## REFERENCES

| ID | Description | Path |
| --- | --- | --- |
| `REF-01` | Shared replay playback proving UI | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.testbed/scripts/proving_harness.gd` |
| `REF-02` | Boxing proving harness depth debug integration | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.testbed/scripts/boxing_proving_harness.gd` |
| `REF-03` | Depth debug viewer UI | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.testbed/scripts/depth_debug_viewer.gd` |
| `REF-04` | Uploaded screenshot showing obsolete replay step buttons | `/home/derrick/.openclaw/workspace/.temp/nerve-uploads/2026/06/23/image-6a2b7983.png` |
| `REF-05` | Uploaded screenshot showing unwanted family timing text under FPS | `/home/derrick/.openclaw/workspace/.temp/nerve-uploads/2026/06/23/image-aa81dc08.png` |
| `REF-06` | Uploaded screenshot showing generated depth-related `.uid` files surfacing in git UI | `/home/derrick/.openclaw/workspace/.temp/nerve-uploads/2026/06/23/image-afd905f9.png` |
| `REF-07` | Repo ignore policy baseline | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.gitignore` |

---

## Tasks

### Task 1: Implement replay/depth proving cleanup

**Bead ID:** `aerobeat-input-camera-tracking-j2ql`
**SubAgent:** `primary` (for `coder`)
**Role:** `coder`
**References:** `REF-01`, `REF-02`, `REF-03`, `REF-04`, `REF-05`
**Prompt:** In `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking`, claim bead `aerobeat-input-camera-tracking-j2ql` with `bd update aerobeat-input-camera-tracking-j2ql --status in_progress --json` when you start. Serve as the coder. Implement exactly these fixes in the boxing and flow proving scenes / harnesses: (1) when a replay video is chosen for testing, remove the left/right replay step buttons from the timeline UI because they are obsolete; (2) when boxing depth checks are disabled for all three punch families, hide the depth thumbnail because it is irrelevant/not loaded; (3) when boxing depth checks are enabled and runtime data exists, make the RGB/depth preview actually show visually instead of only updating inspector values; diagnose whether the current issue is missing texture requests, wrong visibility gating, wrong focus family, or wrong texture plumbing, and fix it truthfully rather than faking it; (4) remove the extra top-left text that says `Straight Punch` / `Hook` / `Uppercut` with timing under the FPS so that corner only shows FPS. Prefer the owning source files, not generated mirrors. Run relevant repo-local validation/tests you can execute. Update the active plan with what changed and results. Commit and push to `main` by default unless blocked. Close the bead with a concrete reason when coder work is complete.

**Folders Created/Deleted/Modified:**
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.testbed/scripts/`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.plans/`

**Files Created/Deleted/Modified:**
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.testbed/scripts/proving_harness.gd`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.testbed/scripts/boxing_proving_harness.gd`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.testbed/scripts/depth_debug_viewer.gd`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.plans/2026-06-22-boxing-and-flow-proving-ui-depth-cleanup.md`

**Status:** ✅ Complete

**Results:** Implemented the shared replay-timeline cleanup in `REF-01` by hiding the obsolete left/right frame-step buttons whenever the prerecorded replay transport is active, so the testing timeline no longer shows the stale controls Derrick flagged in `REF-04`. In `REF-02` and `REF-03`, removed the extra family timing line from the FPS corner, gated the boxing depth thumbnail/swap/hover/region affordances off whenever all three boxing punch-family depth configs are disabled, and fixed the real visual-preview issue by preferring an enabled family that actually has surfaced runtime texture/sample data instead of defaulting to a stale family with no depth texture. The boxing harness now also pulls the preview texture from the mounted preview presenter when available, so the RGB/depth viewer uses the live proving surface rather than a possibly-null fallback. Added/updated unit coverage for the FPS text, hidden replay buttons, disabled-depth thumbnail gating, and focus-family selection. Validation run: targeted Godot/GUT unit passes for `test_depth_debug_viewer_renders_prepared_snapshot_and_reparents_to_presenter_overlay`, `test_boxing_depth_debug_swap_uses_real_runtime_texture_when_available`, `test_boxing_depth_debug_hides_thumbnail_when_all_boxing_depth_families_are_disabled`, `test_boxing_depth_debug_focus_family_prefers_enabled_family_with_runtime_texture`, `test_playback_replay_step_buttons_are_hidden_in_timeline`, `test_replay_step_controls_report_approximate_transport_truthfully`, and `test_replay_step_controls_delegate_exact_transport_steps`.

---

### Task 2: QA the boxing/flow proving cleanup

**Bead ID:** `aerobeat-input-camera-tracking-78hu`
**SubAgent:** `primary` (for `qa`)  
**Role:** `qa`  
**References:** `REF-01`, `REF-02`, `REF-03`, `REF-04`, `REF-05`  
**Prompt:** In `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking`, wait until coder bead `aerobeat-input-camera-tracking-j2ql` is complete, then claim bead `aerobeat-input-camera-tracking-78hu` with `bd update aerobeat-input-camera-tracking-78hu --status in_progress --json`. Serve as QA. Independently verify the implemented behavior in the proving scenes / highest-fidelity testbed available: confirm the replay timeline no longer shows the obsolete left/right step buttons, confirm the top-left corner shows FPS only, confirm the depth thumbnail stays hidden when straight/hook/uppercut depth checks are all disabled, and confirm a visible depth preview appears when depth checks are enabled and runtime texture data is actually available. Record exact verification steps, evidence, any gaps, and whether behavior is truthful. Update the active plan with QA results. Close the QA bead with a concrete reason when done.

**Folders Created/Deleted/Modified:**
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.plans/`

**Files Created/Deleted/Modified:**
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.plans/2026-06-22-boxing-and-flow-proving-ui-depth-cleanup.md`

**Status:** ✅ Complete

**Results:** QA claimed bead `aerobeat-input-camera-tracking-78hu` and verified the cleanup in the highest-fidelity noninteractive environment available: real Godot `.testbed` headless runs plus targeted GUT assertions and a custom node-state probe against instantiated proving scenes/harnesses. Exact verification steps: (1) ran a custom headless probe script at `/home/derrick/.openclaw/workspace/.temp/qa-aerobeat-78hu-20260623/qa_probe.gd` with `godot --headless --path .testbed --script /home/derrick/.openclaw/workspace/.temp/qa-aerobeat-78hu-20260623/qa_probe.gd -- /home/derrick/.openclaw/workspace/.temp/qa-aerobeat-78hu-20260623`, producing JSON evidence at `/home/derrick/.openclaw/workspace/.temp/qa-aerobeat-78hu-20260623/qa_probe_report.json`; (2) ran targeted GUT checks for `test_playback_replay_step_buttons_are_hidden_in_timeline` (1/1 passing, 8 asserts), `test_depth_debug_viewer_renders_prepared_snapshot_and_reparents_to_presenter_overlay` (1/1 passing, 7 asserts), `test_boxing_depth_debug_hides_thumbnail_when_all_boxing_depth_families_are_disabled` (1/1 passing, 4 asserts), `test_boxing_depth_debug_thumbnail_truthfully_reports_unavailable_depth_texture` (1/1 passing, 10 asserts), and `test_boxing_depth_debug_swap_uses_real_runtime_texture_when_available` (1/1 passing, 13 asserts). Evidence by requirement: replay step buttons were hidden in both boxing and flow proving in the probe JSON (`replay_buttons.boxing.*.step_*_visible=false`, `replay_buttons.flow.*.step_*_visible=false`), satisfying the cleanup requested by `REF-04`; the FPS corner text read only `Preview 36.9 FPS` / `Preview 59.4 FPS` with no `Straight`, `Hook`, `Uppercut`, or family-timing `ms` text in the FPS label evidence, satisfying the cleanup requested by `REF-05`; when all boxing depth families were disabled, the probe JSON showed `thumbnail_visible=false` and the targeted harness test confirmed `_depth_debug_visual_config.thumbnail_visible=false`; when runtime texture data was available, the targeted runtime-texture test passed and the probe JSON reported `last_texture_available=true` with the live depth viewer path still enabled. Gap/risk note: framebuffer screenshots could not be captured under the headless dummy renderer (`root.get_texture()` returned null), so QA could not attach a pixel screenshot of the final preview state; validation instead relied on real scene/harness instantiation, node-state evidence, and targeted GUT coverage. QA verdict: pass, with low residual risk limited to visual raster confirmation on a live rendered desktop/editor session.

---

### Task 3: Audit the boxing/flow proving cleanup

**Bead ID:** `aerobeat-input-camera-tracking-0qys`
**SubAgent:** `primary` (for `auditor`)
**Role:** `auditor`
**References:** `REF-01`, `REF-02`, `REF-03`, `REF-04`, `REF-05`
**Prompt:** In `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking`, wait until QA bead `aerobeat-input-camera-tracking-78hu` is complete, then claim bead `aerobeat-input-camera-tracking-0qys` with `bd update aerobeat-input-camera-tracking-0qys --status in_progress --json`. Serve as auditor. Independently truth-check the cleanup against Derrick's request, the screenshots, the plan, the bead chain, the diff, and the coder/QA evidence. Verify that the obsolete replay step buttons are actually gone, the top-left family timing text is gone, the depth thumbnail is hidden when all boxing depth checks are off, and the visible preview path is correct when depth is on. If the work passes, close the audit bead directly with a concrete reason; if it fails, leave clear gap notes and do not close it as done. Update the active plan with the audit outcome.

**Folders Created/Deleted/Modified:**
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.plans/`

**Files Created/Deleted/Modified:**
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.plans/2026-06-22-boxing-and-flow-proving-ui-depth-cleanup.md`

**Status:** ⏳ Pending

**Results:** Pending.

---

### Task 4: Ignore generated depth UID artifacts

**Bead ID:** `aerobeat-input-camera-tracking-fbw3`
**SubAgent:** `primary` (for `coder`)
**Role:** `coder`
**References:** `REF-06`, `REF-07`
**Prompt:** In `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking`, claim bead `aerobeat-input-camera-tracking-fbw3` with `bd update aerobeat-input-camera-tracking-fbw3 --status in_progress --json`. Serve as the coder. Investigate the generated depth-related Godot `.uid` files surfaced by Derrick in `REF-06`, then update `.gitignore` and any necessary tracked file state so these generated depth `.uid` files do not keep surfacing as commit candidates. Keep Derrick's intentional proving-scene and YAML edits out of scope; this slice is only for generated depth-related files / ignore rules / cleanup needed to make git truthful. Prefer the narrowest correct ignore rules rather than blanket ignores that would conflict with intentionally tracked non-depth `.uid` files already in the repo. Update the active plan with what changed and results. Run relevant repo-local validation (at minimum git-status/tracked-file checks for the targeted paths). Commit and push to `main` by default unless blocked. Close the bead with a concrete reason when coder work is complete.

**Folders Created/Deleted/Modified:**
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.plans/`

**Files Created/Deleted/Modified:**
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.gitignore`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.plans/2026-06-22-boxing-and-flow-proving-ui-depth-cleanup.md`

**Status:** ✅ Complete

**Results:** Added the narrowest repo-local ignore rules needed for the generated depth-only Godot UID sidecars in `REF-06` without touching the existing intentionally tracked non-depth `.uid` files elsewhere in the repo. Exact rules added in `REF-07`: `.testbed/scripts/depth_*.gd.uid`, `.testbed/tests/unit/test_depth_*.gd.uid`, and `src/depth/**/*.gd.uid`. Validation/evidence: `git ls-files --stage -- <target>` returned no tracked entries for the surfaced depth UID paths; temporary throwaway files created at each surfaced path were all matched by `git check-ignore -v` against those new rules; `git status --short --untracked-files=all -- <targeted paths>` returned no output while those throwaway files existed; and the control path `.testbed/scripts/proving_harness.gd.uid` remained tracked and was not ignored. Intentional proving-scene / YAML edits stayed out of scope and were not included in this slice. Commit: `e07c3dc` (`Ignore generated depth UID artifacts`).

---

### Task 5: QA the depth UID ignore cleanup

**Bead ID:** `aerobeat-input-camera-tracking-wafs`
**SubAgent:** `primary` (for `qa`)
**Role:** `qa`
**References:** `REF-06`, `REF-07`
**Prompt:** In `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking`, wait until coder bead `aerobeat-input-camera-tracking-fbw3` is complete, then claim bead `aerobeat-input-camera-tracking-wafs` with `bd update aerobeat-input-camera-tracking-wafs --status in_progress --json`. Serve as QA. Verify that the generated depth-related `.uid` files shown by Derrick no longer surface as commit candidates, while intentional proving-scene / YAML edits remain out of scope and existing intentionally tracked non-depth `.uid` files are not accidentally broken by the ignore change. Record exact verification steps and evidence, update the active plan, and close the bead with a concrete reason when done.

**Folders Created/Deleted/Modified:**
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.plans/`

**Files Created/Deleted/Modified:**
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.plans/2026-06-22-boxing-and-flow-proving-ui-depth-cleanup.md`

**Status:** ⏳ Pending

**Results:** Pending.

---

### Task 6: Audit the depth UID ignore cleanup

**Bead ID:** `aerobeat-input-camera-tracking-82wx`
**SubAgent:** `primary` (for `auditor`)
**Role:** `auditor`
**References:** `REF-06`, `REF-07`
**Prompt:** In `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking`, wait until QA bead `aerobeat-input-camera-tracking-wafs` is complete, then claim bead `aerobeat-input-camera-tracking-82wx` with `bd update aerobeat-input-camera-tracking-82wx --status in_progress --json`. Serve as auditor. Independently truth-check the ignore cleanup against Derrick's screenshot, the diff, git status behavior, and the plan. Confirm the generated depth `.uid` files are handled cleanly without over-ignoring unrelated intentionally tracked `.uid` files. Update the plan and close the bead only if the cleanup actually passes.

**Folders Created/Deleted/Modified:**
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.plans/`

**Files Created/Deleted/Modified:**
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.plans/2026-06-22-boxing-and-flow-proving-ui-depth-cleanup.md`

**Status:** ⏳ Pending

**Results:** Pending.

---

## Final Results

**Status:** ⚠️ Partial

**What We Built:** Coder + QA slices complete. The replay timeline now hides the obsolete frame-step buttons during prerecorded proving, the boxing depth viewer now shows FPS-only corner text, all-depth-disabled boxing profiles suppress the depth thumbnail/swap affordances, and enabled depth previews now prefer real surfaced runtime texture/sample data from an enabled family while sourcing the RGB preview from the mounted presenter when available.

**Reference Check:** `REF-01`, `REF-02`, and `REF-03` were updated to satisfy the requested cleanup; `REF-04` and `REF-05` were used as exact UI cleanup targets. QA validated behavior against those references via headless scene/harness probing plus targeted GUT coverage. Auditor verification is still pending.

**Commits:**
- `e07c3dc` - Ignore generated depth UID artifacts

**Lessons Learned:** The missing visual preview was not a fake-texture problem; it was primarily a focus/texture-plumbing issue where the overlay could stick to a stale family with no surfaced depth map and could miss the mounted preview-presenter texture path.

---

*Completed on Pending*
