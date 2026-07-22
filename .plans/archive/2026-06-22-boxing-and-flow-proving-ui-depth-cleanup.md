# Aerobeat Input Camera Tracking - Boxing / Flow Proving UI + Depth Cleanup

**Date:** 2026-06-22
**Status:** Complete
**Last Updated:** 2026-07-19 22:30 EDT
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
| `REF-08` | Uploaded screenshot showing over-verbose failed depth thumbnail state overflowing thumbnail area | `/home/derrick/.openclaw/workspace/.temp/nerve-uploads/2026/06/23/image-592e6636.png` |
| `REF-09` | Uploaded screenshot showing over-verbose boxing gesture inspector depth section running off-screen | `/home/derrick/.openclaw/workspace/.temp/nerve-uploads/2026/06/23/image-44f36ef6.png` |
| `REF-10` | Uploaded screenshot showing residual depth viewer still visible in boxing proving replay | `/home/derrick/.openclaw/workspace/.temp/nerve-uploads/2026/07/20/image-b1c177b9.png` |
| `REF-11` | Boxing tuning/testbed config surfaces Derrick can edit | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/assets/boxing.gesture_detection.yaml`, `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/assets/boxing.testbed_debug.yaml`, `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/assets/boxing.camera_tracking.yaml` |

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

**Status:** ✅ Complete

**Results:** Auditor independently reviewed the actual `93b3b11` diff in `REF-01`/`REF-02`/`REF-03`, checked the bead dependency chain, re-read the uploaded screenshots in `REF-04`/`REF-05`, re-ran the QA probe script, and re-ran focused GUT coverage directly. Audit verdict: pass. Requirement-by-requirement: (1) in `REF-01`, `_refresh_playback_controls_state()` now forces `_playback_step_back_button.visible` and `_playback_step_forward_button.visible` false whenever prerecorded replay transport is active, matching the obsolete buttons shown in `REF-04`; independent rerun `test_playback_replay_step_buttons_are_hidden_in_timeline` passed (1/1, 8 asserts), and the fresh QA probe JSON again reported both boxing and flow `step_*_visible=false`; (2) in `REF-03`, `_refresh_fps_label()` now renders exactly `Preview %.1f FPS` with no family/timing second line, matching the removal target from `REF-05`; the fresh QA probe again showed `contains_straight=false`, `contains_hook=false`, `contains_uppercut=false`, and `contains_ms=false`; (3) in `REF-02`, `_sync_depth_debug_visual_config()` now gates thumbnail/swap/hover/sampling affordances behind `any_depth_family_enabled`, and independent rerun `test_boxing_depth_debug_hides_thumbnail_when_all_boxing_depth_families_are_disabled` passed (1/1, 4 asserts) with the fresh probe also showing `thumbnail_visible=false`; (4) in `REF-02`, `_build_depth_debug_visual_snapshot()` now sources `preview_texture` from the mounted presenter surface when available, and `_depth_debug_focus_family()` now prefers enabled families with real runtime textures/sample data instead of sticking to stale defaults. Independent reruns of `test_boxing_depth_debug_focus_family_prefers_enabled_family_with_runtime_texture` (1/1, 1 assert) and `test_boxing_depth_debug_swap_uses_real_runtime_texture_when_available` (1/1, 13 asserts) both passed, confirming the truthful visible preview path when runtime texture data exists. Residual risk: the headless QA probe still cannot capture final raster screenshots under the dummy renderer, and its synthetic depth-visible probe can race live harness/provider updates, so the strongest proof for requirement 4 is the code-path audit plus the focused GUT passes rather than the probe’s swapped-state JSON alone.

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

**Status:** ✅ Complete

**Results:** QA independently verified the depth UID ignore cleanup against `REF-06` and `REF-07` with direct git-path evidence. Exact verification steps: (1) inspected the active `.gitignore` rules and confirmed the change is limited to `.testbed/scripts/depth_*.gd.uid`, `.testbed/tests/unit/test_depth_*.gd.uid`, and `src/depth/**/*.gd.uid`; (2) ran `git ls-files --stage -- <all screenshot-targeted depth uid paths>` and confirmed none of the generated depth `.uid` paths from `REF-06` are tracked; (3) created temporary throwaway files at each screenshot-targeted path and ran `git check-ignore -v` to confirm each one is ignored by the new narrow rules on lines 60-62 of `REF-07`; (4) ran `git status --short --untracked-files=all -- <targeted depth paths plus control paths>` and confirmed the screenshot-targeted depth `.uid` files do not surface as commit candidates while out-of-scope controls still behave truthfully; (5) checked controls with `git ls-files --stage -- .testbed/scripts/proving_harness.gd.uid .testbed/scenes/boxing_proving.tscn assets/boxing.gesture_detection.yaml` and confirmed the intentional non-depth `.uid` control file remains tracked while the proving-scene and YAML edits remain separately tracked/out of scope; (6) created a control file at `src/other/unrelated_file.gd.uid` and confirmed it was **not** ignored and appeared as `??`, proving the rule does not blanket-ignore unrelated `.uid` files. Evidence: `git check-ignore -v` matched `.testbed/scripts/depth_debug_viewer.gd.uid` and `.testbed/scripts/depth_sample_debug_overlay.gd.uid` to `.gitignore:60`, the two unit-test `.uid` files to `.gitignore:61`, and all `src/depth/*.gd.uid` controls from the screenshot to `.gitignore:62`; `.testbed/scripts/proving_harness.gd.uid` returned `(not ignored)` and remained tracked; `src/other/unrelated_file.gd.uid` returned `(not ignored)` and surfaced as untracked until removed. QA verdict: pass. Residual risk is low and limited to future new depth-adjacent generated `.uid` locations outside the three currently targeted path patterns, which would need an explicit follow-up ignore rule rather than being silently swallowed.

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

**Status:** ✅ Complete

**Results:** Auditor independently truth-checked the ignore cleanup against `REF-06`, `REF-07`, the actual `e07c3dc` diff, and live git behavior. Audit verdict: pass. Evidence by requirement: (1) the screenshot-targeted generated depth `.uid` paths were re-probed directly by creating temporary files at `.testbed/scripts/depth_debug_viewer.gd.uid`, `.testbed/scripts/depth_sample_debug_overlay.gd.uid`, `.testbed/tests/unit/test_depth_python_runtime_bridge.gd.uid`, `.testbed/tests/unit/test_depth_runtime_manager.gd.uid`, and the `src/depth/**/*.gd.uid` examples from `REF-06`; `git check-ignore -v` matched them to `.gitignore` lines 60-62 and `git status --short --untracked-files=all -- <targeted paths>` showed none of them as commit candidates; (2) the rules are narrow rather than blanket because the actual diff in `e07c3dc` only added `.testbed/scripts/depth_*.gd.uid`, `.testbed/tests/unit/test_depth_*.gd.uid`, and `src/depth/**/*.gd.uid`, and an independent control file at `src/other/unrelated_file.gd.uid` stayed unignored and surfaced as `??`; (3) existing intentionally tracked non-depth `.uid` files remain unaffected because `.testbed/scripts/proving_harness.gd.uid` still appears in `git ls-files --stage`, is not matched by `git check-ignore`, and did not disappear from tracked state; (4) Derrick’s intentional `.testbed/scenes/boxing_proving.tscn` and `assets/boxing.gesture_detection.yaml` edits remained separately tracked in `git ls-files --stage` and were not swallowed by the ignore cleanup, keeping that scope boundary truthful. Residual risk is low and limited to future generated depth `.uid` files appearing in new locations outside these three explicit patterns, which would need a deliberate follow-up ignore rule rather than being silently over-ignored.

---

### Task 7: Compact failed depth thumbnail fallback UI

**Bead ID:** `aerobeat-input-camera-tracking-261r`
**SubAgent:** `primary` (for `coder`)
**Role:** `coder`
**References:** `REF-03`, `REF-08`
**Prompt:** In `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking`, claim bead `aerobeat-input-camera-tracking-261r` with `bd update aerobeat-input-camera-tracking-261r --status in_progress --json`. Replace the current over-verbose failed depth thumbnail placeholder with a compact failure state that stays inside the intended thumbnail footprint. Derrick explicitly wants the failed-not-loaded state to be obvious with a small warning / cross-style indicator rather than a multi-line diagnostic block extending below the video edge. Keep the real successful depth-preview path intact and do not reintroduce the removed FPS-corner text. Update the active plan with actual results, run relevant repo-local UI/logic validation, commit/push by default unless blocked, and close the bead with a concrete reason.

**Folders Created/Deleted/Modified:**
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.testbed/scripts/`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.plans/`

**Files Created/Deleted/Modified:**
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.testbed/scripts/depth_debug_viewer.gd`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.testbed/tests/unit/test_boxing_proving_harness_profiles_and_debug.gd`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.plans/2026-06-22-boxing-and-flow-proving-ui-depth-cleanup.md`

**Status:** ✅ Complete

**Results:** Implemented the compact failed-thumbnail fallback in `REF-03` without touching the successful texture path or the all-depth-disabled hiding logic. The thumbnail panel now clips its contents to the intended footprint, the failed placeholder body is reduced to a large centered `✕`, and the verbose runtime diagnostics were moved out of the thumbnail body into tooltip text on the panel/placeholder/status controls so the missing-depth state stays obvious without spilling below the thumbnail bounds. The status label is now hidden for the no-texture failure state, but remains active for successful thumbnail renders so the truthful debug path is preserved when a real texture exists. Focused validation: `godot --headless --path .testbed --script addons/aerobeat-vendor-godot-unit-test/gut_cmdln.gd -gtest=res://tests/unit/test_boxing_proving_harness_profiles_and_debug.gd -gunit_test_name=depth_debug -gexit` passed `9/9` tests (`91` asserts, `108.235s`). Test coverage was updated to assert the compact `✕` placeholder, hidden failure-state status label, preserved diagnostic tooltip text, matched placeholder/texture sizing, panel clipping, preserved successful runtime swap path, and preserved hidden-thumbnail-when-all-depth-disabled behavior. QA/audit still pending.

---

### Task 8: QA the compact failed thumbnail fallback

**Bead ID:** `aerobeat-input-camera-tracking-cxy6`
**SubAgent:** `primary` (for `qa`)
**Role:** `qa`
**References:** `REF-03`, `REF-08`
**Prompt:** After coder completion, claim bead `aerobeat-input-camera-tracking-cxy6` with `bd update aerobeat-input-camera-tracking-cxy6 --status in_progress --json`, then verify the failed depth thumbnail state is compact, obvious, and contained within the intended thumbnail area; confirm it no longer spills below the video edge or dumps a verbose diagnostic block into the thumbnail. Also confirm the successful depth-preview path still works and the no-depth-enabled hidden-thumbnail behavior still holds. Update the active plan with QA evidence and close the bead with a concrete reason when done.

**Folders Created/Deleted/Modified:**
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.plans/`

**Files Created/Deleted/Modified:**
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.plans/2026-06-22-boxing-and-flow-proving-ui-depth-cleanup.md`

**Status:** ✅ Complete

**Results:** QA claimed bead `aerobeat-input-camera-tracking-cxy6` and verified the compact failed-thumbnail fallback on coder commit `16ac872` with two independent checks: (1) a focused headless probe script at `/home/derrick/.openclaw/workspace/.temp/qa-aerobeat-cxy6-20260623/qa_probe.gd`, run via `godot --headless --path .testbed --script /home/derrick/.openclaw/workspace/.temp/qa-aerobeat-cxy6-20260623/qa_probe.gd -- /home/derrick/.openclaw/workspace/.temp/qa-aerobeat-cxy6-20260623`, producing JSON evidence at `/home/derrick/.openclaw/workspace/.temp/qa-aerobeat-cxy6-20260623/qa_probe_report.json`; and (2) the targeted depth-debug GUT subset via `godot --headless --path .testbed --script addons/aerobeat-vendor-godot-unit-test/gut_cmdln.gd -gtest=res://tests/unit/test_boxing_proving_harness_profiles_and_debug.gd -gunit_test_name=depth_debug -gexit`, which passed `9/9` tests with `91` asserts in `110.491s`.

Requirement-by-requirement evidence: (1) compact obvious failure state inside the thumbnail footprint passed — the probe reported `thumbnail_visible=true`, `placeholder_visible=true`, `placeholder_text="✕"`, matched placeholder/texture minimum sizes (`196x114`), `panel_clip_contents=true`, and fixed panel offsets (`left=-230 top=-204 right=-14 bottom=-14`) consistent with a bounded 190px-tall panel rather than the overflowing multiline block shown in `REF-08`; (2) no verbose multiline diagnostic block in the thumbnail body passed — `status_visible=false`, `status_text=""`, and the body content reduced to the centered `✕`, while diagnostics moved to tooltip text; (3) no overflow below the intended thumbnail/video area passed in node-state terms — the panel remained clipped and size-bounded, with the failure details no longer rendered as body text below the thumbnail region; (4) successful depth-preview path still works passed — the probe reported `focus_family="hook"`, `thumbnail_texture_visible=true`, `thumbnail_has_texture=true`, `thumbnail_placeholder_visible=false`, `last_texture_available_before_swap=true`, then after swap `main_texture_visible_after_swap=true` and `swapped_to_depth_after_swap=true`; (5) hidden-thumbnail-when-all-depth-disabled still works passed — the probe reported `thumbnail_visible=false` and visual config kept `swap_click_enabled=false`, `hover_hint_visible=false`, and `sampling_regions_visible=false` when all boxing depth families were disabled; (6) no removed FPS-corner text reintroduced passed — the probe reported `fps_text="Preview 59.4 FPS"` with `contains_straight=false`, `contains_hook=false`, `contains_uppercut=false`, and `contains_ms=false`. The targeted unit subset also explicitly covered `test_depth_debug_viewer_renders_prepared_snapshot_and_reparents_to_presenter_overlay`, `test_boxing_depth_debug_thumbnail_truthfully_reports_unavailable_depth_texture`, `test_boxing_depth_debug_swap_uses_real_runtime_texture_when_available`, `test_boxing_depth_debug_hides_thumbnail_when_all_boxing_depth_families_are_disabled`, and `test_boxing_depth_debug_focus_family_prefers_enabled_family_with_runtime_texture`.

Gap/risk note: under the headless dummy renderer, `root.get_texture()` returned null, so the probe could not save authoritative PNG screenshots; QA evidence is therefore JSON node-state output plus passing targeted GUT coverage rather than a live raster capture. QA verdict: pass, with low residual risk limited to desktop-rendered visual confirmation for exact pixels/spacing.

---

### Task 9: Audit the compact failed thumbnail fallback

**Bead ID:** `aerobeat-input-camera-tracking-41a5`
**SubAgent:** `primary` (for `auditor`)
**Role:** `auditor`
**References:** `REF-03`, `REF-08`
**Prompt:** After QA completion, claim bead `aerobeat-input-camera-tracking-41a5` with `bd update aerobeat-input-camera-tracking-41a5 --status in_progress --json`, then independently truth-check that the failed depth thumbnail state is now compact and bounded, while the live success path and hidden-when-disabled path remain correct. Use Derrick’s screenshot in `REF-08`, the diff, and QA evidence. Close the bead only if the behavior actually matches the requested cleanup.

**Folders Created/Deleted/Modified:**
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.plans/`

**Files Created/Deleted/Modified:**
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.plans/2026-06-22-boxing-and-flow-proving-ui-depth-cleanup.md`

**Status:** ✅ Complete

**Results:** Auditor independently truth-checked the compact failed-thumbnail fallback against the actual `16ac872` diff in `REF-03`, the bad overflowing screenshot in `REF-08`, the active worktree, the QA probe artifacts, and fresh direct validation runs. Audit verdict: pass. Requirement-by-requirement: (1) compact obvious failure state inside the thumbnail footprint passed — in `REF-03`, `_thumbnail_panel.clip_contents = true`, `_placeholder_text()` now returns only `✕`, and `_refresh_thumbnail()` forces the placeholder to reuse the texture rectangle size; the fresh QA probe again reported `thumbnail_visible=true`, `placeholder_visible=true`, `placeholder_text="✕"`, matched placeholder/texture minimum sizes (`196x114`), and bounded bottom-right panel offsets (`left=-230 top=-204 right=-14 bottom=-14`), which is materially different from the overflowing multiline body shown in `REF-08`; (2) no verbose multiline diagnostic block in the thumbnail body passed — the actual `16ac872` diff hides `_thumbnail_status_label` during failure (`failure_state := not thumbnail_has_texture`, `visible = not failure_state`) and moves the diagnostics into `_thumbnail_diagnostic_tooltip(...)`; the fresh probe again showed `status_visible=false`, `status_text=""`, with only the centered `✕` in the body while the tooltip still preserved truthful runtime diagnostics; (3) no overflow below the intended thumbnail/video area passed — the current viewer code hard-bounds the panel to a 190px-tall layout via `_apply_thumbnail_layout()`, clips contents, and no longer renders multiline placeholder/status body text that could spill below the video edge; the fresh probe values (`panel_custom_minimum_size=[216,0]`, clipped panel, fixed offsets) match that bounded layout; (4) successful depth-preview path still works passed — I re-ran the targeted `depth_debug` GUT subset directly and it passed `9/9` tests (`91` asserts, `107.426s`), including `test_boxing_depth_debug_swap_uses_real_runtime_texture_when_available` and `test_boxing_depth_debug_focus_family_prefers_enabled_family_with_runtime_texture`; the fresh probe also again showed `focus_family="hook"`, `thumbnail_has_texture=true`, `thumbnail_placeholder_visible=false`, and `main_texture_visible_after_swap=true`; (5) hidden-thumbnail-when-all-depth-disabled still works passed — the same fresh GUT run passed `test_boxing_depth_debug_hides_thumbnail_when_all_boxing_depth_families_are_disabled`, and the fresh probe again showed `thumbnail_visible=false` with `swap_click_enabled=false`, `hover_hint_visible=false`, and `sampling_regions_visible=false`; (6) no removed FPS-corner text is reintroduced passed — current `REF-03` still renders `_fps_label.text = "Preview %.1f FPS"`, the fresh GUT subset passed the viewer coverage that asserts that exact string, and the fresh probe again reported `fps_text="Preview 59.4 FPS"` with `contains_straight=false`, `contains_hook=false`, `contains_uppercut=false`, and `contains_ms=false`. Residual risk: low, but not zero — the headless dummy renderer still cannot produce authoritative framebuffer screenshots (`root.get_texture()` is null in the probe path), so the remaining uncertainty is limited to pixel-perfect live raster spacing on a desktop-rendered session rather than logic/layout truth in the scene tree.

---

### Task 10: Simplify boxing gesture inspector depth section

**Bead ID:** `aerobeat-input-camera-tracking-9pce`
**SubAgent:** `primary` (for `coder`)
**Role:** `coder`
**References:** `REF-02`, `REF-09`
**Prompt:** In `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking`, claim bead `aerobeat-input-camera-tracking-9pce` with `bd update aerobeat-input-camera-tracking-9pce --status in_progress --json`. Simplify the boxing gesture inspector popup’s depth section so it only shows what Derrick needs for fast threshold tuning: which backend is chosen (disabled or a short backend/depth label) and the relevant depth threshold value(s). Remove the extra runtime/loader/artifact/failure/metrics dump that currently runs off-screen. Keep the panel compact and readable, preserve truthful data, and keep the successful/failed thumbnail work intact. Update the active plan with actual results, run relevant repo-local validation, commit/push by default unless blocked, and close the bead with a concrete reason.

**Folders Created/Deleted/Modified:**
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.testbed/scripts/`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.plans/`

**Files Created/Deleted/Modified:**
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.testbed/scripts/boxing_proving_harness.gd`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.testbed/tests/unit/test_boxing_proving_harness_profiles_and_debug.gd`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.plans/2026-06-22-boxing-and-flow-proving-ui-depth-cleanup.md`

**Status:** ✅ Complete

**Results:** Claimed bead `aerobeat-input-camera-tracking-9pce` and simplified the boxing gesture inspector popup depth section in `/.testbed/scripts/boxing_proving_harness.gd` so the punch and pose-strike inspector models now keep only three compact depth rows: `Depth backend`, `Depth delta threshold`, and `Depth peak threshold` under a `Depth tuning` section. The backend row now stays truthful but short: it shows `disabled` when the family depth config is off, `backend / family` when runtime debug has a resolved backend, or `configured / <artifact-basename>` when the YAML enables depth but runtime resolution is not yet surfaced. The threshold rows now compress to `min <value>` for straight-punch depth gates and `max <value>` for hook/uppercut depth gates, instead of dumping runtime stage, loader truth, artifact path, failure reason, live metrics, ROI/window shapes, smoothing, or debug flags. Preserved behavior: the earlier depth thumbnail/fps cleanup code paths were not changed. Validation run: `godot --headless --path .testbed --script addons/aerobeat-vendor-godot-unit-test/gut_cmdln.gd -gtest=res://tests/unit/test_boxing_proving_harness_profiles_and_debug.gd -gunit_test_name=compact_depth_backend_and_thresholds -gexit` passed `1/1` tests with `15` asserts; the targeted depth-thumbnail subset `-gunit_test_name=depth_debug` also remained green at `9/9` tests with `91` asserts.

---

### Task 11: QA simplified boxing gesture inspector depth section

**Bead ID:** `aerobeat-input-camera-tracking-2gqf`
**SubAgent:** `primary` (for `qa`)
**Role:** `qa`
**References:** `REF-02`, `REF-09`
**Prompt:** After coder completion, claim bead `aerobeat-input-camera-tracking-2gqf` with `bd update aerobeat-input-camera-tracking-2gqf --status in_progress --json`, then verify the boxing gesture inspector depth section is compact and only shows the chosen backend plus relevant threshold value(s). Confirm the off-screen verbose runtime/config dump is gone, and that the remaining values are truthful for quick tune/retry loops. Update the active plan with QA evidence and close the bead with a concrete reason when done.

**Folders Created/Deleted/Modified:**
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.plans/`

**Files Created/Deleted/Modified:**
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.plans/2026-06-22-boxing-and-flow-proving-ui-depth-cleanup.md`

**Status:** ✅ Complete

**Results:** QA claimed bead `aerobeat-input-camera-tracking-2gqf` and verified coder commit `bc24933` against `REF-02` and `REF-09` with two independent checks plus direct source review. Exact verification steps: (1) re-ran the focused inspector unit coverage via `godot --headless --path .testbed --script addons/aerobeat-vendor-godot-unit-test/gut_cmdln.gd -gtest=res://tests/unit/test_boxing_proving_harness_profiles_and_debug.gd -gunit_test_name=compact_depth_backend_and_thresholds -gexit`, which passed `1/1` tests with `15` asserts in `0.942s`; (2) re-ran the depth-debug regression subset via `godot --headless --path .testbed --script addons/aerobeat-vendor-godot-unit-test/gut_cmdln.gd -gtest=res://tests/unit/test_boxing_proving_harness_profiles_and_debug.gd -gunit_test_name=depth_debug -gexit`, which passed `9/9` tests with `91` asserts in `110.635s`; (3) ran a lightweight headless probe script at `/home/derrick/.openclaw/workspace/.temp/qa-aerobeat-2gqf-20260623/qa_probe_simple.gd`, writing JSON evidence to `/home/derrick/.openclaw/workspace/.temp/qa-aerobeat-2gqf-20260623/qa_probe_report.json`; and (4) reviewed the live source in `REF-02` around the compact depth-row wiring (`depth_*` rows plus `_compact_depth_backend_label`, `_depth_threshold_compact_text`, `_build_depth_config_row`).

Evidence by requirement: (1) compact/no off-screen verbose dump passed — the probe JSON shows the inspector depth block reduced to exactly four lines (`Depth tuning`, backend, delta threshold, peak threshold) for runtime and configured cases, and none of the old verbose tokens from `REF-09` (`Depth runtime status / stage`, `Depth loader truth`, `Active depth artifact path`, `Depth failure reason`, `Active normalized depth metrics`, `Depth window slices`, `Depth ROI sizes`) appear in the inspector body; (2) only chosen backend plus relevant threshold values passed — the probe reported `onnx / depth_anything_v2_small_onnx` with `min 0.060` / `min 0.040` for straight punch, and `configured / openvino_midas_v21_small_256` with `max 0.030` / `max 0.060` for hook and uppercut; (3) backend labeling truthfulness passed — the direct helper probe returned `disabled` for a disabled family, runtime-resolved labels surfaced as `<backend> / <family>`, and YAML-only enabled families without surfaced runtime resolution reported `configured / <artifact-basename>`; (4) threshold direction truthfulness passed — straight-punch rows stayed `min ...`, while hook and uppercut rows stayed `max ...`; (5) thumbnail behavior and FPS-corner cleanup remained intact — the `depth_debug` subset still passed `test_depth_debug_viewer_renders_prepared_snapshot_and_reparents_to_presenter_overlay`, `test_boxing_depth_debug_thumbnail_truthfully_reports_unavailable_depth_texture`, `test_boxing_depth_debug_swap_uses_real_runtime_texture_when_available`, and `test_boxing_depth_debug_hides_thumbnail_when_all_boxing_depth_families_are_disabled`, confirming the earlier thumbnail and FPS-only viewer behaviors remained green after the inspector simplification.

QA verdict: pass. Residual risk is low and limited to live desktop/editor visual confirmation of exact popup fit on a rendered session; the content/label truth itself is strongly covered by direct inspector-body evidence, helper-path review, and passing regression tests.

---

### Task 12: Audit simplified boxing gesture inspector depth section

**Bead ID:** `aerobeat-input-camera-tracking-uz00`
**SubAgent:** `primary` (for `auditor`)
**Role:** `auditor`
**References:** `REF-02`, `REF-09`
**Prompt:** After QA completion, claim bead `aerobeat-input-camera-tracking-uz00` with `bd update aerobeat-input-camera-tracking-uz00 --status in_progress --json`, then independently truth-check that the boxing gesture inspector depth section now only shows the chosen backend and relevant threshold value(s), without the off-screen verbose dump. Use Derrick’s screenshot in `REF-09`, the diff, and QA evidence. Close the bead only if the compact inspector behavior actually matches the requested tuning workflow.

**Folders Created/Deleted/Modified:**
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.plans/`

**Files Created/Deleted/Modified:**
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.plans/2026-06-22-boxing-and-flow-proving-ui-depth-cleanup.md`

**Status:** ✅ Complete

**Results:** Auditor independently truth-checked the boxing gesture inspector simplification against the actual `bc24933` diff in `REF-02`, the current source, the uploaded overflowing inspector screenshot in `REF-09`, the QA probe artifacts (`/home/derrick/.openclaw/workspace/.temp/qa-aerobeat-2gqf-20260623/qa_probe_simple.gd` and `/home/derrick/.openclaw/workspace/.temp/qa-aerobeat-2gqf-20260623/qa_probe_report.json`), and fresh local reruns of both targeted GUT coverage and the QA probe. Audit verdict: pass. Requirement-by-requirement: (1) compact/off-screen cleanup passed — the `PUNCH_REQUIREMENT_ROWS` and `POSE_STRIKE_REQUIREMENT_ROWS` depth section in `REF-02` was reduced from the verbose runtime/config dump shown in `REF-09` to exactly `Depth tuning`, `Depth backend`, `Depth delta threshold`, and `Depth peak threshold`; the fresh probe JSON again showed only those four depth lines and none of the old verbose tokens (`Depth runtime status / stage`, `Depth loader truth`, `Active depth artifact path`, `Depth failure reason`, `Active normalized depth metrics`, `Depth window slices`, `Depth ROI sizes`); (2) only chosen backend plus relevant threshold values passed — `_build_depth_config_row()` now only emits `_compact_depth_backend_label(...)` and `_depth_threshold_compact_text(...)`, and the fresh probe again reported runtime `onnx / depth_anything_v2_small_onnx` plus `min 0.060` / `min 0.040`, and configured hook/uppercut `openvino / midas_openvino_v21_small_256` plus `max 0.030` / `max 0.060`; (3) backend labeling truthfulness passed — `_compact_depth_backend_label()` returns `disabled` when the family config is off, `%s / %s` when runtime `backend_id` and `family_id` are surfaced, and `configured / %s` with the model artifact basename when YAML is enabled but runtime resolution is absent; the fresh QA probe again captured the runtime-resolved and configured-without-runtime cases, and direct helper review confirmed the disabled branch; (4) threshold direction truthfulness passed — `_depth_threshold_direction_label()` returns `min` only for `straight_punch` and `max` for hook/uppercut, and `_depth_threshold_compact_text()` uses that direction with the correct threshold keys; the rerun `compact_depth_backend_and_thresholds` GUT subset passed `1/1` tests with `15` asserts, confirming `min` for straight punch and `max` for hook/uppercut; (5) thumbnail behavior and FPS-corner cleanup remained intact — independent rerun of the `depth_debug` GUT subset passed `9/9` tests with `91` asserts, covering the compact clipped thumbnail failure state, swap/live-texture path, hidden-thumbnail-when-all-depth-disabled gating, focus-family preference, and `Preview %.1f FPS`-only corner label. Residual risk: low and limited to live desktop-rendered popup fit/pixel spacing, because the strongest evidence remains source/diff review plus headless inspector/probe output rather than an authoritative framebuffer screenshot of the final popup.

---

### Task 13: Remove residual boxing depth thumbnail and prune non-pose-threshold residue

**Bead ID:** `aerobeat-input-camera-tracking-jgbf`
**SubAgent:** `primary` (for `coder`)
**Role:** `coder`
**References:** `REF-02`, `REF-03`, `REF-10`, `REF-11`
**Prompt:** In `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking`, claim bead `aerobeat-input-camera-tracking-jgbf` with `bd update aerobeat-input-camera-tracking-jgbf --status in_progress --json` when you start. Serve as the coder. Derrick reopened the same active plan with a new bug/cleanup slice. First, remove the residual boxing depth viewer/thumbnail from the proving replay surface so the extra bottom-right depth panel shown in `REF-10` no longer appears during the normal boxing replay/tuning flow unless there is still an explicitly intended truthful opt-in path documented in the current config; verify whether the remaining visibility comes from `assets/boxing.testbed_debug.yaml`, `/.testbed/scripts/boxing_proving_harness.gd`, `/.testbed/scripts/depth_debug_viewer.gd`, or other still-wired defaults, and fix the actual source rather than masking it. Second, do a quick root-level repo audit for scripts/configs/assets/docs that still belong to older non-pose-threshold tracking methods outside the current pose-threshold system, then remove only the clearly stale root-level residue that is no longer part of the approved active contract. Be conservative: if something is still plausibly active, document it instead of deleting it. Record the exact files audited, removed, kept, and why. Update this active plan with actual findings/results. Run the minimum relevant validation/tests you can execute. Commit and push to `main` by default unless blocked. Close the bead with a concrete reason when coder work is complete.

**Folders Created/Deleted/Modified:**
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/assets/`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.testbed/tests/unit/`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/scripts/`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.plans/`

**Files Created/Deleted/Modified:**
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/assets/boxing.testbed_debug.yaml`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/assets/flow.gesture_detection.yaml`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.testbed/tests/unit/test_boxing_proving_harness_profiles_and_debug.gd`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/scripts/freeze_boxing_punch_classifier_snapshot.py`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.plans/2026-06-22-boxing-and-flow-proving-ui-depth-cleanup.md`

**Status:** ✅ Complete

**Results:** Root-caused the residual boxing depth panel in `REF-10` to the live tuning config itself, not to a hidden viewer default: `REF-02` and `REF-03` already default `thumbnail_visible` false internally, but `assets/boxing.testbed_debug.yaml` in `REF-11` was still explicitly opting the bottom-right thumbnail on. Fixed the actual source by changing that config opt-in to `thumbnail_visible: false` and clarifying in the YAML comment that the thumbnail is an explicit truthful opt-in only. Updated `test_boxing_proving_scene_applies_boxing_testbed_debug_yaml_to_live_nodes` so the live-node assertion now matches the intended default-hidden replay/tuning path while preserving the separate depth-viewer tests that still cover the explicit opt-in path with `thumbnail_visible: true`.

Quick root-level non-pose-threshold residue audit (conservative): audited `assets/boxing.testbed_debug.yaml`, `assets/boxing.gesture_detection.yaml`, `assets/flow.gesture_detection.yaml`, `scripts/boxing_classifier_harness.py`, `scripts/derive_prototype_library_from_fixtures.py`, `scripts/export_boxing_punch_classifier_dataset.py`, `scripts/freeze_boxing_punch_classifier_snapshot.py`, `scripts/run_prototype_matcher_fixture_benchmark.py`, `scripts/train_boxing_punch_mlp_baseline.py`, `scripts/train_boxing_punch_temporal_cnn.py`, `assets/prototype_libraries/`, `docs/baselines/`, and `docs/reviews/`. Findings: kept `assets/boxing.gesture_detection.yaml` because it is the active pose-threshold boxing contract; kept the prototype/classifier benchmarking/training scripts, prototype libraries, and historical docs because they are still explicitly referenced by committed docs/baseline artifacts even though they are outside the active runtime contract; pruned the stale config residue in `assets/flow.gesture_detection.yaml` by removing the old `prototype`/`classifier` placeholder blocks and comments so the root-level flow config now states only the current threshold/disabled contract; removed `scripts/freeze_boxing_punch_classifier_snapshot.py` because it was an unreferenced classifier-era helper with no remaining callers or docs pointing at it.

Validation run: `godot --headless --path .testbed --script addons/aerobeat-vendor-godot-unit-test/gut_cmdln.gd -gtest=res://tests/unit/test_boxing_proving_harness_profiles_and_debug.gd -gunit_test_name=test_boxing_proving_scene_applies_boxing_testbed_debug_yaml_to_live_nodes -gexit` passed (1/1, 16 asserts); `godot --headless --path .testbed --script addons/aerobeat-vendor-godot-unit-test/gut_cmdln.gd -gtest=res://tests/unit/test_camera_tracking_config_profiles.gd -gunit_test_name=test_camera_tracking_config_switches_to_flow_profile_bundle -gexit` passed (1/1, 21 asserts); `godot --headless --path .testbed --script addons/aerobeat-vendor-godot-unit-test/gut_cmdln.gd -gtest=res://tests/unit/test_camera_tracking_config_profiles.gd -gunit_test_name=test_camera_tracking_config_loads_boxing_profile_bundle_from_canonical_paths -gexit` passed (1/1, 74 asserts). Commit: `9d7438a` (`Hide boxing depth thumbnail by default`).

---

### Task 14: QA residual depth-thumbnail removal and repo-residue prune

**Bead ID:** `aerobeat-input-camera-tracking-f7d1`
**SubAgent:** `primary` (for `qa`)
**Role:** `qa`
**References:** `REF-02`, `REF-03`, `REF-10`, `REF-11`
**Prompt:** In `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking`, wait until coder bead `aerobeat-input-camera-tracking-jgbf` is complete, then claim bead `aerobeat-input-camera-tracking-f7d1` with `bd update aerobeat-input-camera-tracking-f7d1 --status in_progress --json`. Serve as QA. Verify the residual boxing depth thumbnail/panel shown in `REF-10` is actually gone from the normal replay/tuning surface, and verify the root-level prune only removed clearly stale non-pose-threshold residue while preserving still-active pose-threshold contract files. Record exact verification steps, evidence, any remaining suspicious residue, and whether the tuning config locations in `REF-11` remain truthful. Update the active plan with QA results. Close the bead with a concrete reason when done.

**Folders Created/Deleted/Modified:**
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.plans/`

**Files Created/Deleted/Modified:**
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.plans/2026-06-22-boxing-and-flow-proving-ui-depth-cleanup.md`

**Status:** ✅ Complete

**Results:** QA claimed bead `aerobeat-input-camera-tracking-f7d1` after coder bead `aerobeat-input-camera-tracking-jgbf` closed, then independently verified both halves of the slice with direct config/diff inspection plus focused Godot coverage.

Exact verification steps:
1. Inspected the live config surfaces in `REF-11` (`assets/boxing.testbed_debug.yaml`, `assets/boxing.gesture_detection.yaml`, `assets/boxing.camera_tracking.yaml`) and the post-change test assertion in `.testbed/tests/unit/test_boxing_proving_harness_profiles_and_debug.gd`.
2. Reviewed the actual coder diff with `git diff 9d7438a^ 9d7438a -- assets/boxing.testbed_debug.yaml assets/flow.gesture_detection.yaml .testbed/tests/unit/test_boxing_proving_harness_profiles_and_debug.gd scripts/freeze_boxing_punch_classifier_snapshot.py` to confirm the default-hidden thumbnail change, the flow-config prune, the updated live-node assertion, and the deleted stale helper.
3. Re-ran `godot --headless --path .testbed --script addons/aerobeat-vendor-godot-unit-test/gut_cmdln.gd -gtest=res://tests/unit/test_boxing_proving_harness_profiles_and_debug.gd -gunit_test_name=test_boxing_proving_scene_applies_boxing_testbed_debug_yaml_to_live_nodes -gexit`, which passed `1/1` tests with `16` asserts in `12.724s`.
4. Re-ran `godot --headless --path .testbed --script addons/aerobeat-vendor-godot-unit-test/gut_cmdln.gd -gtest=res://tests/unit/test_camera_tracking_config_profiles.gd -gunit_test_name=test_camera_tracking_config_switches_to_flow_profile_bundle -gexit`, which passed `1/1` tests with `21` asserts in `0.427s`.
5. Re-ran `godot --headless --path .testbed --script addons/aerobeat-vendor-godot-unit-test/gut_cmdln.gd -gtest=res://tests/unit/test_camera_tracking_config_profiles.gd -gunit_test_name=test_camera_tracking_config_loads_boxing_profile_bundle_from_canonical_paths -gexit`, which passed `1/1` tests with `74` asserts in `0.382s`.
6. Verified the removed root-level helper is actually gone with `test ! -e scripts/freeze_boxing_punch_classifier_snapshot.py`, and checked for remaining direct references with `git grep -n "freeze_boxing_punch_classifier_snapshot" -- . ':!docs/baselines/**' ':!assets/prototype_libraries/**'`.

Evidence / verdict by requirement:
- Residual depth panel from `REF-10` is removed from the normal boxing replay/tuning default path: `assets/boxing.testbed_debug.yaml` now sets `visuals.depth_debug.thumbnail_visible: false`, and the live-node test now asserts `assert_false(bool(depth_debug_visuals.get("thumbnail_visible", true)))`. That means the screenshot state in `REF-10` is no longer the default replay/tuning surface even though the truthful depth-debug system remains available as an explicit opt-in.
- The root-level prune stayed conservative. `assets/flow.gesture_detection.yaml` now contains only the active flow contract (`squat` threshold backend and disabled `straight_punch`) with the stale `prototype` / `classifier` placeholder blocks removed. `scripts/freeze_boxing_punch_classifier_snapshot.py` is deleted and absent on disk. Meanwhile, still-active pose-threshold contract files were preserved and remain truthful: `assets/boxing.gesture_detection.yaml` still defines the active threshold-based boxing families plus their depth thresholds; `assets/boxing.camera_tracking.yaml` still points at the canonical boxing preview/tracking bundle; and `assets/boxing.testbed_debug.yaml` still truthfully enables depth debug while making the thumbnail a deliberate opt-in instead of a default surface element.
- Remaining suspicious residue: low-risk historical prototype/classifier materials still exist under `docs/baselines/`, `assets/prototype_libraries/`, `.testbed/assets/benchmarks/`, and some test fixtures/assertions that intentionally mention legacy `prototype` / `classifier` shapes. QA does **not** consider that a failure here because those artifacts are still referenced by committed docs/tests as history/coverage, but they remain the main places an auditor may want to truth-check for future cleanup boundaries.

QA verdict: pass. The default boxing replay/tuning config is now truthful to Derrick’s requested no-thumbnail surface, and the prune removed only clearly stale non-pose-threshold residue while preserving the active pose-threshold contract files and canonical config locations in `REF-11`. 

---

### Task 15: Audit residual depth-thumbnail removal and repo-residue prune

**Bead ID:** `aerobeat-input-camera-tracking-gqcf`
**SubAgent:** `primary` (for `auditor`)
**Role:** `auditor`
**References:** `REF-02`, `REF-03`, `REF-10`, `REF-11`
**Prompt:** In `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking`, wait until QA bead `aerobeat-input-camera-tracking-f7d1` is complete, then claim bead `aerobeat-input-camera-tracking-gqcf` with `bd update aerobeat-input-camera-tracking-gqcf --status in_progress --json`. Serve as auditor. Independently truth-check that the residual boxing depth thumbnail/panel in `REF-10` is removed from the normal replay/tuning experience and that any root-level cleanup only pruned clearly stale non-pose-threshold residue without harming the active pose-threshold system. Use the diff, config truth, coder/QA evidence, and current repo state. If the work passes, close the bead directly with a concrete reason; if not, leave clear gap notes. Update the active plan with the audit outcome.

**Folders Created/Deleted/Modified:**
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.plans/`

**Files Created/Deleted/Modified:**
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.plans/2026-06-22-boxing-and-flow-proving-ui-depth-cleanup.md`

**Status:** ✅ Complete

**Results:** Auditor independently truth-checked the residual-thumbnail/remnant-prune slice against the actual `9d7438a` diff, current config truth in `REF-11`, QA evidence, and fresh direct validation reruns. Audit verdict: pass. Requirement-by-requirement: (1) the residual bottom-right depth panel shown in `REF-10` is no longer part of the normal boxing replay/tuning surface because the live config source `assets/boxing.testbed_debug.yaml` now sets `visuals.depth_debug.thumbnail_visible: false` with an explicit opt-in comment, while depth debug itself remains truthfully enabled for the non-thumbnail paths; (2) the proving-scene live-node contract matches that config now that `test_boxing_proving_scene_applies_boxing_testbed_debug_yaml_to_live_nodes` asserts `thumbnail_visible` false, and I independently re-ran that test successfully (`1/1`, `16` asserts); (3) the root-level prune stayed conservative and did not harm the active pose-threshold system: `assets/flow.gesture_detection.yaml` only lost stale `prototype` / `classifier` placeholder residue, `scripts/freeze_boxing_punch_classifier_snapshot.py` is truly deleted/absent, and the active boxing/flow config bundle tests still pass on fresh reruns (`test_camera_tracking_config_switches_to_flow_profile_bundle` `1/1`, `21` asserts; `test_camera_tracking_config_loads_boxing_profile_bundle_from_canonical_paths` `1/1`, `74` asserts); (4) still-active pose-threshold config surfaces remain intact and truthful in current repo state, including `assets/boxing.gesture_detection.yaml` and `assets/boxing.camera_tracking.yaml`. Boundary note for the next seam Derrick identified: both `assets/boxing.gesture_detection.yaml` and `assets/boxing.testbed_debug.yaml` still contain punch-family/testbed depth sections that appear stale relative to the current pose-threshold boxing contract, but that is separate follow-on work tracked by pending bead `aerobeat-input-camera-tracking-wj48` and was not implemented in this audit. Residual risk is low and limited to live desktop-rendered visual confirmation of the now-hidden default thumbnail surface, since this audit’s strongest proof is config truth + live-node assertion + bundle tests rather than a fresh framebuffer capture.

---

### Task 16: Remove stale punch-family depth sections from boxing gesture detection config

**Bead ID:** `aerobeat-input-camera-tracking-wj48`
**SubAgent:** `primary` (for `coder`)
**Role:** `coder`
**References:** `REF-11`
**Prompt:** In `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking`, wait until audit bead `aerobeat-input-camera-tracking-gqcf` is complete, then claim bead `aerobeat-input-camera-tracking-wj48` with `bd update aerobeat-input-camera-tracking-wj48 --status in_progress --json`. Serve as the coder on the same active proving cleanup plan. Derrick identified that both `assets/boxing.gesture_detection.yaml` and `assets/boxing.testbed_debug.yaml` still carry depth sections that are no longer needed for the current pose-threshold Boxing contract. Remove the stale punch-family/testbed depth config blocks and any tightly coupled config/inspector/runtime assumptions that would become dead or misleading afterward, but keep the active pose-threshold tuning surfaces truthful. Be conservative about collateral cleanup: remove only what is now clearly stale because of that config removal, and document any related surfaces that should be cleaned later rather than widening scope silently. Update the active plan with actual findings/results. Run the minimum relevant validation/tests you can execute. Commit and push to `main` by default unless blocked. Close the bead with a concrete reason when coder work is complete.

**Folders Created/Deleted/Modified:**
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/assets/`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.testbed/scripts/`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.plans/`

**Files Created/Deleted/Modified:**
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/assets/boxing.gesture_detection.yaml`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/assets/boxing.testbed_debug.yaml`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.testbed/scripts/boxing_proving_harness.gd`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.plans/2026-06-22-boxing-and-flow-proving-ui-depth-cleanup.md`

**Status:** ✅ Complete

**Results:** Completed as part of the broader non-pose-threshold purge. Removed the stale punch-family depth sections from `assets/boxing.gesture_detection.yaml` and removed the stale boxing depth-debug block from `assets/boxing.testbed_debug.yaml`, leaving only the active pose-threshold tuning surface plus generic landmark/refresh proving settings. Tight collateral cleanup kept truthful scope: updated `.testbed/tests/unit/test_camera_tracking_config_profiles.gd` and `.testbed/tests/unit/test_boxing_proving_harness_profiles_and_debug.gd` so the live config/test expectations now assert the depth sections are absent and that the boxing proving scene no longer requests depth texture from the retired YAML path. Focused validation passed via `test_camera_tracking_config_loads_boxing_profile_bundle_from_canonical_paths`, `test_boxing_proving_scene_applies_boxing_testbed_debug_yaml_to_live_nodes`, and `test_boxing_proving_runtime_config_no_longer_requests_depth_texture_from_testbed_yaml`.

---

### Task 18: Purge obsolete non-pose-threshold tracking artifacts and reduce history to minimal note

**Bead ID:** `aerobeat-input-camera-tracking-z8mk`
**SubAgent:** `primary` (for `coder`)
**Role:** `coder`
**References:** `REF-11`
**Prompt:** In `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking`, wait until bead `aerobeat-input-camera-tracking-ij5g` is complete, then claim bead `aerobeat-input-camera-tracking-z8mk` with `bd update aerobeat-input-camera-tracking-z8mk --status in_progress --json`. Serve as the coder on the same active proving cleanup plan. Derrick explicitly changed policy: old classifier / prototype / hand-tracking / other non-pose-threshold tracking artifacts should no longer be preserved as historical noise throughout the repo. Audit the repo for obsolete non-pose-threshold tracking artifacts, fixtures, scripts, docs, benchmarks, libraries, proving overlays, tests, and config residue that are not needed for the live pose-threshold system. Remove them aggressively but truthfully. Do not keep the previously proposed historical-note pile unless something truly minimal is still required for repo orientation; Derrick explicitly said the old artifacts themselves are noise and do not need to survive as historical notes. Also treat the hand-tracking-only proving overlays/surfaces as deletion candidates when they are not part of the live pose-threshold system, including the current `.testbed/scripts/hand_*` overlay surfaces if they are only hand-tracking debug UI. Be careful not to delete anything still required by the active pose-threshold boxing/flow runtime, current tests, or current config contract. Update the active plan with exact removed/kept surfaces and why. Run the minimum relevant validation/tests you can execute. Commit and push to `main` by default unless blocked. Close the bead with a concrete reason when coder work is complete.

**Folders Created/Deleted/Modified:**
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/assets/`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.testbed/`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/docs/`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/scripts/`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.plans/`

**Files Created/Deleted/Modified:**
- `.testbed/scenes/boxing_proving.tscn`
- `.testbed/scenes/flow_proving.tscn`
- `.testbed/tests/unit/test_camera_tracking_provider.gd`
- `.testbed/tests/unit/test_camera_tracking_config_profiles.gd`
- `.testbed/tests/unit/test_boxing_proving_harness_profiles_and_debug.gd`
- deleted: `.testbed/scripts/hand_bbox_state_drawer.gd`, `.testbed/scripts/hand_trail_drawer.gd`, `.testbed/tests/unit/test_proving_harness_trails.gd`
- deleted: `src/detectors/learned_punch_classifier.gd`, `src/detectors/prototype_punch_matcher.gd`
- deleted: retired classifier/prototype scripts under `scripts/`
- deleted: `assets/prototype_libraries/`
- deleted: `.testbed/assets/benchmarks/boxing_punch_classifier_v1.benchmark.json`
- deleted: bulky prototype/classifier history under `docs/baselines/` and `docs/reviews/`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/assets/boxing.camera_tracking.yaml`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/assets/flow.camera_tracking.yaml`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/assets/flow.testbed_debug.yaml`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/docs/cross-repo-config-contract.md`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.plans/2026-06-22-boxing-and-flow-proving-ui-depth-cleanup.md`

**Status:** ✅ Complete

**Results:** Completed the aggressive repo-local purge Derrick requested. Removed committed hand-tracking-only proving overlays and dependent scene/test wiring (`hand_bbox_state_drawer`, `hand_trail_drawer`, `test_proving_harness_trails`, `TrailDrawer`, `HandBBoxDrawer`), removed dead non-runtime detector stubs in `src/detectors/`, removed the retired classifier/prototype script/tool chain in `scripts/`, deleted `assets/prototype_libraries/`, deleted the retired benchmark manifest `.testbed/assets/benchmarks/boxing_punch_classifier_v1.benchmark.json`, and deleted bulky classifier/prototype history/review artifacts under `docs/baselines/` and `docs/reviews/`. Also removed stale hand-overlay contract residue from `assets/boxing.camera_tracking.yaml`, `assets/flow.camera_tracking.yaml`, and `assets/flow.testbed_debug.yaml`, and rewrote `docs/cross-repo-config-contract.md` to threshold-only truth. Kept the live pose-threshold boxing/flow runtime/config files, the proving harnesses themselves, and the current pose detector substrate/tests because they still serve the active threshold path. Focused validation passed via `test_camera_tracking_config_switches_to_flow_profile_bundle`, `test_camera_tracking_provider_replay_start_forwards_boxing_pose_and_hand_profile_config`, `test_camera_tracking_provider_live_start_forwards_boxing_pose_and_hand_profile_config`, `test_boxing_proving_scene_applies_boxing_testbed_debug_yaml_to_live_nodes`, and `test_boxing_proving_profile_visual_config_keeps_pose_landmark_debug_truthful`.

---

## Final Results

**Status:** ✅ Complete

**What We Built:** The original boxing/flow proving UI cleanup remains landed, and this plan’s new continuation seam is now also implemented: the repo contract has been cut down to the live pose-threshold system only. Boxing depth config blocks are gone from `assets/boxing.gesture_detection.yaml` and `assets/boxing.testbed_debug.yaml`; committed hand-overlay contract residue is gone from the boxing/flow camera-tracking + flow testbed-debug YAMLs; the cross-repo contract doc now describes threshold-only truth; committed hand-tracking-only proving overlays/scenes/tests are gone; and the dead classifier/prototype detector/tool/history payload has been aggressively deleted from the repo.

**Reference Check:** `REF-01` through `REF-11` remain satisfied for the completed proving/UI slices, and the new purge continuation also resolves the follow-on seam previously called out under `REF-11`: stale boxing depth sections no longer remain in the active config surfaces. The active repo truth is now the pose-threshold contract only. Kept surfaces were limited to the live boxing/flow configs, proving harnesses, and current pose detector/runtime tests that still serve the threshold path. Residual risk is low and mostly about broader cross-repo follow-through, not this repo’s committed truth.

**Commits:**
- `93b3b11` - Clean up proving replay and depth preview UI
- `e07c3dc` - Ignore generated depth UID artifacts
- `3bb52e8` - Update plan with depth UID ignore results
- `16ac872` - Compact failed thumbnail fallback in proving UI
- `bc24933` - Compact boxing inspector depth tuning
- `9d7438a` - Hide boxing depth thumbnail by default
- `79c9e4f` - Purge non-pose threshold tracking artifacts

**Lessons Learned:** Once Derrick changed policy from “keep history around” to “history is noise,” the truthful cleanup boundary shifted from conservative documentation retention to aggressive removal of contract lies, dead overlays, and obsolete artifact piles. Focused `-gunit_test_name` validation was the safest way to prove the touched contract/proving surfaces still worked without getting blocked by unrelated long-running depth-runtime coverage.

---

*Completed on 2026-07-19 — later continuation seams were executed and the plan is now complete.*
