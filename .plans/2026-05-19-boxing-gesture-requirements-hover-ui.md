# AeroBeat MediaPipe Python — Boxing Gesture Requirements Hover UI

**Date:** 2026-05-19  
**Status:** In Progress  
**Agent:** Pico 🐱‍🏍

---

## Goal

Add a hoverable Boxing proving-scene UI that exposes the live true/false requirements behind each gesture icon so we can debug gesture gates visually and rewrite confusing or physically wrong assumptions before continuing detector tuning.

---

## Overview

The straight-punch detector is currently blocked less by raw forward-motion visibility and more by uncertainty about which gate is actually failing frame-to-frame. Right now, those checks mostly live in code and debug artifacts, which makes it too hard to glance at the Boxing proving scene and answer the practical question: “Which gesture requirements are satisfied right now?” The proposed fix is to surface each gesture’s requirements directly in the proving UI as a hover card tied to the existing gesture icons.

This should be treated as a reusable testing/debug pattern, not a one-off Punch-L patch. Each supported Boxing gesture should be able to declare a concise list of verifiable true/false requirements. The hover card should show the gesture name, each requirement as a checkbox row, the threshold being tested, and the current live value. This will let us see whether the detector is failing because a threshold is too strict, the wrong body-side assumption is being used, or the rule itself is conceptually wrong.

Derrick also called out an important design correction: the current “hand must be on its own side of the screen” idea is a dangerous assumption and may be physically or spatially wrong, especially with a non-mirrored front-facing webcam feed. So this plan should explicitly separate two things: (1) shipping the hover UI pattern, and (2) revisiting side-of-screen/ownership wording and logic. The UI text must stay short, plain-English, and human-verifiable. Before we lock final wording for each gesture’s requirement list, we should bring the proposed text back for Derrick to review.

---

## REFERENCES

| ID | Description | Path |
| --- | --- | --- |
| `REF-01` | Active straight-punch redesign plan | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-mediapipe-python/.plans/2026-05-19-straight-punch-side-ownership-redesign.md` |
| `REF-02` | Prior straight-punch depth/state plan | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-mediapipe-python/.plans/2026-05-18-straight-punch-depth-aware-measurement-and-state-design.md` |
| `REF-03` | Boxing proving-scene experiment log | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-mediapipe-python/docs/punch-left-golden-truth-experiment-log.html` |
| `REF-04` | Boxing proving scene/UI owner | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-mediapipe-python/.testbed/scenes/boxing_proving.tscn` |
| `REF-05` | Boxing proving scene script(s) | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-mediapipe-python/.testbed/` |
| `REF-06` | Detector substrate / live gesture state source | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-mediapipe-python/src/detectors/pose_detector_substrate.gd` |
| `REF-07` | Pose metrics helpers | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-mediapipe-python/src/detectors/pose_metrics.gd` |

---

## Tasks

### Task 1: Inventory Boxing gesture gate inputs and draft plain-English requirement text

**Bead ID:** `aerobeat-input-mediapipe-python-ahc`  
**SubAgent:** `primary`  
**Role:** `research`  
**References:** `REF-01`–`REF-07`  
**Prompt:** Inspect the current Boxing proving UI and detector/debug surfaces, then inventory the actual true/false gate checks behind each Boxing gesture icon. Draft concise hover-card requirement text for each supported Boxing gesture using plain English, not detector jargon. Each line must map to a verifiable boolean and show the threshold/current-value structure needed by the checkbox UI. Call out any current gate wording or logic that appears physically wrong or camera-orientation-sensitive, especially left/right side-of-screen assumptions.

**Folders Created/Deleted/Modified:**
- `.plans/`
- maybe `.testbed/` notes/UI files if a tiny reference stub is needed

**Files Created/Deleted/Modified:**
- `.plans/2026-05-19-boxing-gesture-requirements-hover-ui.md`
- optional notes file only if it helps review

**Status:** ✅ Complete

**Results:**
- Claimed `aerobeat-input-mediapipe-python-ahc` and inspected the current Boxing proving surface in `.testbed/scenes/boxing_proving.tscn` plus `.testbed/scripts/boxing_proving_harness.gd` / `proving_harness.gd`.
- Confirmed the visible Boxing icon board currently shows 9 gesture tiles, all defined in `TILE_CONFIGS`: Punch, Hook, Uppercut, Knee Strike, Guard, Leg Lift, Side Step, Squat, and Weave. Important UI truth: Punch / Hook / Uppercut / Knee / Leg Lift / Side Step / Weave are **event-pulse** tiles, while Guard and Squat are **state** tiles. So the hover-card work should explain the detector conditions behind the event or state that actually drives each tile, not an invented generic gesture summary.
- Confirmed the current detector/debug surfaces already expose enough live data to start truthful hover cards: `gesture_states`, `gesture_debug.ready`, `gesture_debug.straight_punch`, `metrics.measurements`, and the Boxing-specific `boxing_debug` snapshot built by `proving_harness.gd`.
- Inventoried the real current gate families behind the Boxing board:
  - **Punch L/R:** per-side straight-punch mini-state. Fire only from `phase == armed` when own-half lock is true, arm is straight enough in 3D (`arm_extension_3d >= 0.95` and `elbow_bend_deg_3d >= 145°`), forward velocity exceeds `shoulder_width * 8.0`, and forward distance exceeds the armed baseline by `shoulder_width * 0.08`. Rearm requires retreat from peak by `shoulder_width * 0.12`, return near ready reach within `shoulder_width * 0.09`, and own-half lock again.
  - **Hook L/R:** ready resets when lateral hand speed falls to `<= shoulder_width * 1.10`; fire requires elbow bend `55°..145°`, wrist/elbow vertical gap `<= shoulder_width * 0.40`, outward velocity `> shoulder_width * 1.50`, lateral speed dominating vertical speed by `> 1.6x`, and outward distance `> shoulder_width * 0.45`. Hooks are skipped entirely while Guard state is active.
  - **Uppercut L/R:** ready resets when vertical hand speed falls to `<= shoulder_width * 1.10`; fire requires elbow bend `35°..125°`, wrist/elbow horizontal gap `<= shoulder_width * 0.28`, upward velocity `> shoulder_width * 1.40`, and upward speed dominating lateral speed by `> 1.2x`. Uppercuts are also skipped while Guard state is active.
  - **Knee Strike L/R:** only evaluated when that foot confidence is at least `max(min_visibility, 0.5)`. Ready resets when the chosen rise metric is `<= 0.10`; fire requires the opposite knee not rising almost the same amount (`opposite >= 0.18` and delta `<= 0.08` blocks it) and effective rise `>= 0.22`, where effective rise is `max(knee_rise, foot_rise * 0.85)` when the ankle stays within `0.30 torso heights` laterally of the hip.
  - **Guard:** active only when both sides satisfy all three checks: wrist/elbow x alignment `<= shoulder_width * 0.32`, wrist height at or above `shoulder_y - shoulder_width * 0.10`, and wrist staying near the shoulder/head laterally `<= shoulder_width * 0.55`.
  - **Leg Lift L/R:** state starts when leg angle from core is `>= 32°` and ankle raise is `>= 0.32`; state ends when leg angle drops to `<= 18°` or ankle raise drops to `<= 0.18`. The icon pulses off the `_start` event, not the persistent state.
  - **Side Step L/R:** state starts when body lateral offset reaches `<= -0.45` for left or `>= 0.45` for right while head/hip alignment stays within `0.18`; returns to neutral only when `abs(lateral_offset) <= 0.14`. The icon pulses off the `_start` event.
  - **Squat:** state starts when `height_ratio <= 0.82` and ends when `height_ratio >= 0.92`. It only runs when torso confidence is at least `max(min_visibility, 0.5)`.
  - **Weave L/R:** left starts when `head_offset <= -0.30`, relative head-vs-hip offset `<= -0.12`, and head drop `>= 0.05`; right mirrors the signs (`>= 0.30`, `>= 0.12`, `>= 0.05`). Neutral clears both when `abs(head_offset) <= 0.12` and `abs(relative_offset) <= 0.08`. The icon pulses off the `_start` event.
- Drafted truthful Punch-L hover-card rows from the exact fire path instead of detector-jargon paraphrase:
  - `Punch is armed` — phase must be `armed` (current: `recovering` / `armed` / `extending`).
  - `Left hand still passes the current own-half lane check` — current code requires `left_own_half_lock == true`.
  - `Left arm extension in 3D is high enough` — `arm_extension_3d >= 0.95`.
  - `Left elbow looks straight enough in 3D` — `elbow_bend_deg_3d >= 145°`.
  - `Left hand is moving forward fast enough` — `forward_velocity > shoulder_width * 8.0`.
  - `Left hand moved forward far enough from its armed baseline` — `forward_distance >= armed_forward_distance + shoulder_width * 0.08`.
- Flagged the main suspect assumption explicitly instead of normalizing it away: Punch uses `left_own_half_lock` / `right_own_half_lock`, which are image-plane body-centerline checks (`wrist.x` against centerline ± `0.12 shoulder widths`, plus outward-distance sign). That is exactly the camera-orientation-sensitive side-ownership idea Derrick distrusted, and the 2026-05-19 straight-punch plan already records that it stays false during real guarded left punches. The hover UI should present this row as an **under review / image-space ownership check**, not as a settled truth about the athlete's real left/right intent.
- Additional suspect naming to surface later: Weave and Side Step are also currently labeled from signed screen/baseline offsets, not from a validated physical left/right movement model. Task 2 should keep the reusable row schema flexible enough to mark those requirements as `suspect` too when their hover cards are added.
- Recommendation for Task 2 data shape: each hover row should be declarative and reusable, e.g. `{ id, label, passed, current_text, threshold_text, metric_key?, source_path?, suspect_reason? }`, with optional grouping like `phase` / `lane` / `shape` / `speed` / `distance`. That lets Punch-L show truthful current-vs-threshold text now, while also letting suspect image-space rows render a warning badge instead of pretending they are equally trustworthy.

---

### Task 2: Implement the reusable hover-card UI pattern in the Boxing proving scene

**Bead ID:** `aerobeat-input-mediapipe-python-e1x`  
**SubAgent:** `primary`  
**Role:** `coder`  
**References:** `REF-04`–`REF-07` plus Task 1 wording draft  
**Prompt:** Implement the hover UI for Boxing gesture icons in the proving scene. On mouse hover, show a mostly transparent black rounded-corner popup with white text. For the hovered gesture, display a concise checklist of live requirements, where each row has a checkbox state, brief label, threshold value, and current value. Keep the implementation reusable for additional Boxing/Flow gestures later. Do not silently invent final wording; wire the UI so the requirement text can be reviewed and revised.

**Folders Created/Deleted/Modified:**
- `.testbed/scenes/`
- `.testbed/scripts/`
- `.plans/`

**Files Created/Deleted/Modified:**
- exact Boxing proving scene/script/UI files needed by the hover pattern
- `.plans/2026-05-19-boxing-gesture-requirements-hover-ui.md`

**Status:** ✅ Complete

**Results:**
- Implemented the reusable hover-card shell directly in `.testbed/scripts/boxing_proving_harness.gd` without broad detector changes or scene churn.
- Added per-tile mouse hover handling on the existing Boxing icon board so a popup appears when any Boxing gesture tile is hovered.
- Styled the popup to match the approved shell direction: mostly transparent black background, rounded corners, white text, and checkbox rows using `🗹` / `☐`.
- Added a reusable row/card data model (`title`, `subtitle`, `rows`, optional `footer`; per row `id`, `label`, `passed`, `threshold_text`, `current_text`, optional `group` / `suspect_text`) so later Boxing and Flow gestures can plug into the same renderer.
- Wired the approved initial Punch-L wording contract into the shell with live shell-local values sourced from the proving harness snapshot that already exists today:
  1. `L-Punch phase is armed - <phase>`
  2. `L-Hand is on left side of screen - <boolean>`
  3. `L-Arm extension is >= 0.95 - <float>`
  4. `L-Elbow bend is >= 145° - <int>°`
  5. `L-Forward velocity >= ??? - <float>`
  6. `L-Forward distance >= ??? - <float>`
- For rows 5 and 6, the shell now supports dynamic threshold substitution via `{threshold}` plus live current-value text, so Task 3 can keep the same renderer while tightening the final truth hookup.
- Non-Punch tiles currently use the same popup shell with a truthful placeholder row instead of fake detector wording, keeping the implementation reviewable and reusable.
- Validation so far: `~/.local/bin/godot --headless --path .testbed res://scenes/boxing_proving.tscn --quit-after 1` successfully ran the Boxing scene script path with no GDScript parse/runtime errors from the new hover-card code; the only reported issue was an existing missing imported weave icon texture, unrelated to this shell task.
- Remaining for Task 3: move the Punch-L row values off the shell-local snapshot builder and onto the final shared live debug source Derrick wants to trust, then extend the same data model to additional Boxing gestures.

---

### Task 3: Hook Punch-L to the new requirement UI with truthful live values

**Bead ID:** `aerobeat-input-mediapipe-python-bzd`  
**SubAgent:** `primary`  
**Role:** `coder`  
**References:** `REF-01`, `REF-04`–`REF-07` plus Task 1 wording approval  
**Prompt:** Connect the new hover-card pattern to Punch-L first and feed it truthful live data from the current detector/debug state. If the current side-of-screen / side-ownership assumption is still exposed anywhere in the displayed requirements, either remove it or clearly flag it as under review rather than presenting it as trustworthy truth. Keep the displayed conditions aligned with what the detector actually checks right now.

**Folders Created/Deleted/Modified:**
- `.testbed/scenes/`
- `.testbed/scripts/`
- `src/detectors/` only if a tiny debug-surface addition is required
- `.plans/`
- `docs/`

**Files Created/Deleted/Modified:**
- exact UI/debug files needed for Punch-L hookup
- `.plans/2026-05-19-boxing-gesture-requirements-hover-ui.md`
- `docs/punch-left-golden-truth-experiment-log.html` if a note belongs there

**Status:** ✅ Complete

**Results:**
- Rewired the Punch-L hover card to read from the actual live detector/debug state instead of the shell-local placeholder builder. `boxing_proving_harness.gd` now pulls row values from `_latest_state.gesture_debug.straight_punch.left`, which is populated by the same proving-scene detector state used for live Boxing playback.
- Narrowly extended `src/detectors/pose_detector_substrate.gd` so `gesture_debug.straight_punch.left/right` exposes the current live Punch straight-punch values the UI actually needs: `phase`, `own_half_lock`, `arm_extension_3d`, `elbow_bend_deg_3d`, `forward_velocity`, `forward_distance`, plus the dynamically computed threshold values `forward_velocity_min` and `forward_distance_min` and the fixed 3D straightness mins.
- Preserved the approved row wording contract exactly in the displayed line text:
  1. `L-Punch phase is armed - <phase>`
  2. `L-Hand is on left side of screen - <boolean>`
  3. `L-Arm extension is >= 0.95 - <float>`
  4. `L-Elbow bend is >= 145° - <int>°`
  5. `L-Forward velocity >= ??? - <float>`
  6. `L-Forward distance >= ??? - <float>`
- Replaced the row 5 and row 6 `???` placeholders at render time with the real live threshold values currently being used by the detector (`shoulder_width * 8.0` and `armed_forward_distance + shoulder_width * 0.08`, respectively) from the detector debug feed rather than recomputing them inside the shell.
- Preserved the approved left-side-of-screen row wording and kept it live, but removed the extra under-review/helper copy from the popup so Derrick can do a cleaner manual UI review next session without changing the detector-backed row itself.
- Validation: `~/.local/bin/godot --headless --path .testbed res://scenes/boxing_proving.tscn --quit-after 1` completed with the same pre-existing missing `boxing-weave-1.svg` import warning seen in Task 2, and no new GDScript parse/runtime errors from the Punch-L hookup.
- Manual-review handoff for next session: hover popup is now the clean version (live rows and values intact, warning/helper text removed) and should be visually rechecked by Derrick in the live Punch tile.

---

### Task 4: QA the hover UI and proposed requirement wording with Derrick review points captured

**Bead ID:** `aerobeat-input-mediapipe-python-lv4`  
**SubAgent:** `primary`  
**Role:** `qa`  
**References:** outputs from Tasks 1-3  
**Prompt:** Verify that the hover UI appears on icon hover, that the visual styling matches the requested pattern closely enough, that checkbox truth updates live, and that the requirement wording is short and glanceable. Capture the exact proposed Punch-L wording for Derrick review rather than assuming it is final.

**Folders Created/Deleted/Modified:**
- `.plans/`
- maybe `.temp/` or evidence folders if screenshots/logs are useful

**Files Created/Deleted/Modified:**
- `.plans/2026-05-19-boxing-gesture-requirements-hover-ui.md`
- optional evidence notes/screenshots paths if collected

**Status:** ✅ Complete

**Results:** QA verified the live Punch-L hover card in the actual Boxing proving scene via headless proving-scene capture evidence at `.temp/qa-hover-capture/hover.png` and `.temp/qa-hover-capture/report.json`.
- Hover behavior: emitting the Punch tile hover in the live scene made the popup visible, and exit hid it again (`initial=false`, `after_hover=true`, `after_exit=false`).
- Styling verdict: close to requested. Captured panel style was mostly transparent black (`#000000d1`), rounded corners (`16px` radius), white/light text, and a subtle light border. Screenshot confirms the intended look.
- Exact displayed Punch-L wording captured for Derrick review:
  1. `L-Punch phase is armed - <phase>`
  2. `L-Hand is on left side of screen - <boolean>`
     - warning subline: `Under review: this is the current detector own-half/image-space check, not settled physical truth.`
  3. `L-Arm extension is >= 0.95 - <float>`
  4. `L-Elbow bend is >= 145° - <int>°`
  5. `L-Forward velocity >= <threshold> - <float>`
  6. `L-Forward distance >= <threshold> - <float>`
- Captured live example shown in the screenshot:
  1. `L-Punch phase is armed - armed`
  2. `L-Hand is on left side of screen - false`
  3. `L-Arm extension is >= 0.95 - 0.928`
  4. `L-Elbow bend is >= 145° - 136°`
  5. `L-Forward velocity >= 1.177 - -0.043`
  6. `L-Forward distance >= 0.348 - 0.304`
- Truth/live verdict: rows 3-6 and their checkbox states are genuinely live, not stale shell text. Across captured samples, the values and pass/fail checkboxes changed frame-to-frame from `_latest_state.gesture_debug.straight_punch.left`, including threshold numbers on rows 5 and 6 instead of `???`.
- Row 2 truthfulness at the time of QA capture: main wording stayed as approved, and the UI then still showed the under-review helper copy. That capture evidence is now stale for visual review because the helper/warning text has since been removed for a cleaner manual handoff while keeping the live row itself intact.
- Row 1 phase verification: QA observed the row display `recovering` in one live pass and `armed` in another. This confirms the UI can render live phase text rather than a hardcoded value. QA did **not** capture an `extending` display from this saved Punch-L fixture, so that phase remains unverified here.
- Known unrelated issue still present during capture: the pre-existing missing `boxing-weave-1.svg` import warning appeared again, but it did not block Punch-L hover verification.
- Manual-review note: current next-session check should focus on the cleaner popup presentation with the same live rows/values, since the older capture/report still reflects the pre-cleanup helper text.

---

### Task 5: Audit whether this UI is truthful enough to use as the next debugging surface

**Bead ID:** `aerobeat-input-mediapipe-python-0ks`  
**SubAgent:** `primary`  
**Role:** `auditor`  
**References:** all outputs from Tasks 1-4  
**Prompt:** Audit whether the new hover-card UI is a truthful debugging tool rather than a misleading explainer. Confirm that the displayed requirements really match detector checks, call out any still-dangerous left/right ownership assumptions, and say whether the Punch-L wording is ready for Derrick review or needs revision first.

**Folders Created/Deleted/Modified:**
- `.plans/`
- maybe `docs/` if a final audit note belongs there

**Files Created/Deleted/Modified:**
- `.plans/2026-05-19-boxing-gesture-requirements-hover-ui.md`
- optional note files if needed

**Status:** ⏳ Pending

**Results:** Pending.

---

### Task 5: Apply Derrick's overlay review changes

**Bead ID:** `aerobeat-input-mediapipe-python-dr8`  
**SubAgent:** `primary`  
**Role:** `coder`  
**References:** `REF-04`–`REF-07` plus Derrick review notes from 2026-05-20  
**Prompt:** Update the Boxing/Flow gesture info overlay pattern based on Derrick's manual review. Change the title to `Gesture Detection`, remove the descriptive subtitle/body text under the title, size the panel height to its actual content with a small margin, widen the panel and increase font size for readability, replace the broken checkbox glyphs with a rendering-safe solution, and move hover activation to the specific sub-gesture target (`L`, `R`, or equivalent state label) instead of the whole gesture tile. Keep the interaction pattern reusable across Boxing and Flow, including single-state gestures like Squat. Investigate and fix the hover-time framerate drop, avoiding expensive per-frame UI rebuild work if possible. Update the plan with what changed and any performance root cause found.

**Folders Created/Deleted/Modified:**
- `.testbed/scenes/`
- `.testbed/scripts/`
- `.plans/`

**Files Created/Deleted/Modified:**
- `.testbed/scripts/boxing_proving_harness.gd`
- `.plans/2026-05-19-boxing-gesture-requirements-hover-ui.md`

**Status:** ✅ Complete

**Results:**
- Updated the reusable overlay shell in `.testbed/scripts/boxing_proving_harness.gd` to match Derrick's review notes: the header now reads `Gesture Detection`, the old descriptive subtitle line was removed, the card width increased from `360` to `440`, and the title/gesture/body font sizes were bumped for readability.
- Kept the panel height content-driven instead of forcing a tall fixed card. The hover card now rebuilds its minimum size from content after row updates, so the panel hugs the active checklist with only the intended margin container padding.
- Moved hover activation off the full gesture tile and onto the specific interactive sub-targets instead: `L` and `R` badges for left/right gestures, and the center `Active` badge for single-state gestures like Guard and Squat. This keeps the interaction pattern reusable for Boxing today and Flow later without requiring a Punch-only special case.
- Extended the overlay model from a tile-level key to a card-level key (`punch_left`, `punch_right`, `guard`, `squat`, etc.). That preserves the reusable pattern while letting each sub-gesture/state own its own popup content and hover target.
- Added live right-side Punch support while doing the badge-target refactor, so both `Punch-L` and `Punch-R` now use the same detector-backed row renderer instead of leaving the right badge disconnected.
- Replaced the broken Unicode checkbox/checkmark rendering with ASCII-safe `[x]` / `[ ]` markers plus pass/fail tinting, which avoids font fallback issues while keeping the checklist scan pattern obvious.
- Investigated the hover-time framerate tank and found two main sources of avoidable churn in the previous implementation:
  1. the hovered popup rows were fully freed/recreated on every boxing UI refresh, which forced repeated layout/tree churn while hovering;
  2. badge/tile styles were being recreated every refresh even when their active state had not changed.
- Fixed that performance issue by caching hover-row controls and only updating their text/state when the model changes, plus short-circuiting badge/tile style reapplication unless the active/inactive state actually flips. The popup is still live-updating, but no longer does full per-frame row rebuilds or redundant stylebox swaps just because the cursor is resting on a hover target.
- Validation performed:
  - `~/.local/bin/godot --headless --path .testbed res://scenes/boxing_proving.tscn --quit-after 1`
  - `~/.local/bin/godot --headless --path .testbed --script ../.temp/validate_hover.gd` during development to force the new badge hover path and confirm the popup became visible on `punch_left` with 6 rendered rows before the temp validation script was removed.
- Committed and pushed to `main`: `6d27149` — `Polish gesture detection hover overlay`
- The same pre-existing missing `boxing-weave-1.svg` import warning still appears during headless runs and is unrelated to this overlay pass.

---

### Task 6: Re-QA the overlay behavior after Derrick's review fixes

**Bead ID:** `aerobeat-input-mediapipe-python-gmr`  
**SubAgent:** `primary`  
**Role:** `qa`  
**References:** outputs from Tasks 1-5  
**Prompt:** Re-verify the gesture info overlay after the review-driven polish pass. Confirm the title is `Gesture Detection`, the subtitle/description is gone, the panel sizes to content cleanly, the wider panel plus larger text improves readability, the hover target is now the specific sub-gesture label (`L`, `R`, or equivalent state label), and the checkbox visuals render correctly. Specifically test whether hover interaction still causes a framerate drop and capture whether the performance issue is resolved or meaningfully improved.

**Folders Created/Deleted/Modified:**
- `.plans/`
- `.temp/qa-hover-polish/`

**Files Created/Deleted/Modified:**
- `.plans/2026-05-19-boxing-gesture-requirements-hover-ui.md`
- `.temp/qa-hover-polish/report.json`
- `.temp/qa-hover-polish/punch-clean.json`
- `.temp/qa-hover-polish/guard-clean.json`
- `.temp/qa-hover-polish.gd`
- `.temp/qa-hover-punch-clean.gd`
- `.temp/qa-hover-guard-clean.gd`

**Status:** ✅ Complete

**Results:** QA re-verified the polished overlay in the actual Boxing proving scene via fresh headless Godot runs against `res://scenes/boxing_proving.tscn` with scripted hover activation on the real badge controls. Evidence lives at `.temp/qa-hover-polish/report.json`, `.temp/qa-hover-polish/punch-clean.json`, and `.temp/qa-hover-polish/guard-clean.json`.
- Title/subtitle cleanup: confirmed the static overlay header text is exactly `Gesture Detection` (`head.static_title`, `punch-clean.static_title`), and there is no subtitle/body copy under the title anymore. The only remaining top copy is the gesture-specific second line like `Punch-L`; footer/helper text is empty and hidden (`footer_visible=false`, `footer_text=""`).
- Hover target change: confirmed hover no longer activates from the whole Punch tile. In `report.json`, `targets.punch_tile.after_visible=false` with tile `mouse_filter=2` (`IGNORE`), while `targets.punch_left_badge.after_visible=true`, `targets.punch_right_badge.after_visible=true`, `targets.guard_center_badge.after_visible=true`, and `targets.squat_center_badge.after_visible=true`. That directly verifies the new per-badge hover path for both sided and single-state gestures.
- Checkbox rendering: confirmed the live rows render with ASCII-safe `[x]` / `[ ]` markers rather than broken Unicode glyphs (`punch-clean.rows[*].checkbox`, `guard-clean.rows[0].checkbox`). Pass/fail tinting is still applied in the runtime capture metadata (`report.json`).
- Content sizing / card shape: the hover panel still uses fixed width but content-driven height (`panel_custom_minimum_size=[440, 0]` in both `punch-clean.json` and `guard-clean.json`). A fresh Punch-L hover produced 6 rendered rows, while a fresh Guard hover produced 1 rendered row, which confirms the card height is driven by active content instead of a forced tall shell. The headless dummy renderer reported obviously inflated pixel heights, so QA treats the row-count + zero-Y-min-size evidence as trustworthy and the absolute pixel heights as not trustworthy in this environment.
- Readability improvements: verified directly from the live script/runtime configuration that the width/font polish landed: width `440`, body font `14`, gesture font `16`, title font `18` in `.testbed/scripts/boxing_proving_harness.gd`, with the runtime confirming the gesture title font size (`gesture_font_size=16`). This is materially wider/larger than the prior Task 5 shell and matches Derrick’s readability request.
- Performance / hover churn: precise framerate truth is hard to prove headlessly, but the obvious hover-path churn is gone in the current implementation. With the Punch-L card hovered, repeated `_refresh_hover_card()` calls kept the exact same row node instance IDs and signature (`row_ids_stable_after_refresh=true`, `signature_stable_after_refresh=true`), and repeated `_refresh_debug_panels()` calls also kept the same row node IDs (`row_ids_stable_after_debug=true`). The measured scripted refresh overhead was small in this headless run (`60` direct hover refreshes in `2037µs`, `20` debug panel refreshes in `1408µs`), which is consistent with the intended cache/no-rebuild fix even though it is not a substitute for desktop FPS measurement.
- Caveats: headless capture still hits the pre-existing missing `boxing-weave-1.svg` import warning, unchanged from prior tasks and unrelated to this overlay QA pass. Also, because the proving scene was exercised under headless dummy rendering, QA did not produce a trustworthy visual screenshot this round; the evidence is therefore structured runtime data rather than a usable image.

---

### Task 7: Audit whether this UI is truthful and performant enough to use as the next debugging surface

**Bead ID:** `aerobeat-input-mediapipe-python-pav`  
**SubAgent:** `primary`  
**Role:** `auditor`  
**References:** all outputs from Tasks 1-6  
**Prompt:** Audit whether the updated hover-card UI is truthful, readable, and performant enough to use as the next debugging surface. Confirm the displayed requirements still match detector checks, note any still-dangerous left/right ownership assumptions, and verify the new per-subgesture hover pattern and checkbox rendering are acceptable. Call out any remaining performance risks or readability problems before the UI is used to drive the next straight-punch redesign pass.

**Folders Created/Deleted/Modified:**
- `.plans/`
- maybe `docs/` if a final audit note belongs there

**Files Created/Deleted/Modified:**
- `.plans/2026-05-19-boxing-gesture-requirements-hover-ui.md`
- optional note files if needed

**Status:** ✅ Complete (accepted with Derrick override)

**Results:** Auditor reviewed the active plan, implementation commit `6d27149`, the live overlay code in `.testbed/scripts/boxing_proving_harness.gd`, the detector/debug source in `src/detectors/pose_detector_substrate.gd`, and the fresh QA evidence in `.temp/qa-hover-polish/`.
- **Truth check — mostly good, with one known temporary mismatch.** Punch-L and Punch-R rows 1, 3, 4, 5, and 6 do map to the real straight-punch fire checks and are populated from `gesture_debug.straight_punch.left/right`, which in turn exposes the same phase/state/threshold values used by `_process_straight_punch()`. Row 2 (`L-Hand is on left side of screen` / `R-Hand is on right side of screen`) still does **not** fully describe the real `own_half_lock` detector check, which is a compound image-space/body-centerline heuristic plus an outward-distance margin check.
- **Original auditor concern:** row 2 wording can mislead the straight-punch side-ownership redesign because it presents a simplified image-space ownership rule as if it were settled truth.
- **Derrick decision on 2026-05-20:** this row-2 wording mismatch is acceptable for now because that gate/wording is likely to change during the upcoming redesign and does not need to be treated as stable product truth yet.
- **Per-subgesture hover targeting passes.** QA evidence confirms hover now activates from the specific `L` / `R` / `Active` badges instead of the whole tile (`report.json > targets.*`), which is the intended reusable interaction model.
- **Readability passes for debugging use.** The title/subtitle cleanup, wider panel, larger fonts, content-driven height, and ASCII `[x]` / `[ ]` markers are acceptable for continued debugging use. `punch-clean.json` and `guard-clean.json` remain the cleaner evidence artifacts.
- **Performance looks improved enough for this stage, but exact FPS is still unproven.** QA proved that hover refreshes no longer rebuild row nodes or churn style state every update (`row_ids_stable_after_refresh=true`, `row_ids_stable_after_debug=true`, small scripted refresh timings). That is good evidence that the main hover-time churn bug was fixed, even though it is not a literal desktop FPS benchmark.
- **Final orchestrator decision after Derrick review:** treat this overlay as **provisionally acceptable** for the next straight-punch side-ownership redesign pass, with the explicit understanding that row 2 is temporary/debug-only wording and not final gate truth.

---

### Task 8: Investigate overlay height carry-over bug and re-audit Punch-L live debug truth

**Bead ID:** `aerobeat-input-mediapipe-python-3z9`  
**SubAgent:** `primary`  
**Role:** `research`  
**References:** `REF-01`–`REF-07` plus Derrick review notes from 2026-05-20  
**Prompt:** Investigate two new truth gaps from Derrick's manual review. First, reproduce and explain the info-popup sizing bug where moving directly from one gesture status badge to another can reset the popup into an extremely tall broken state until hover is reset through a non-status target; do not assume this is simply the previous card height carrying over. Second, audit the current Punch-L live rows against observed runtime behavior and detector intent: phase appears stuck on `armed`, the left/right own-half row is not useful and should be removed entirely, and the displayed extension, elbow bend, forward velocity, and forward distance values do not appear to track the actual punch motion truthfully. Determine which rows are conceptually wrong, which measurements are mislabeled, and whether the unstable shoulder-width-based thresholds are being recomputed frame-to-frame instead of frozen from a calibration/baseline. Update the plan with concrete root-cause findings and recommended replacement/debug rows.

**Folders Created/Deleted/Modified:**
- `.testbed/scripts/`
- `src/detectors/`
- `.plans/`
- maybe `.temp/` if evidence scripts/artifacts are needed

**Files Created/Deleted/Modified:**
- exact proving-scene and detector/debug files inspected
- `.plans/2026-05-19-boxing-gesture-requirements-hover-ui.md`
- optional evidence scripts or notes if needed

**Status:** ✅ Complete

**Results:** Investigated with code review plus runtime artifacts at `.temp/qa-hover-polish/report.json` and `.temp/task8-capture/report.json`. Root cause of the tall popup bug is row-node accumulation, not mere stale height: `_sync_hover_card_rows()` in `.testbed/scripts/boxing_proving_harness.gd` clears old rows with `queue_free()` and immediately adds new rows in the same frame when switching badge→badge. Because `queue_free()` is deferred, direct transitions temporarily leave old children alive under `_hover_card_rows`, so the next card appends onto stale rows before frees land. The existing QA artifact already shows this exact failure signature: Punch-L captured with 14 rows, Guard with 15, Squat with 16, and panel heights around `10908`–`13011`, while the single-card clean capture in `.temp/qa-hover-polish/punch-clean.json` shows the intended 6-row Punch-L card with panel height `4681`. The bad cards also contain duplicated/stale rows from prior gestures, which matches Derrick’s “extremely tall broken state” report and explains why a non-status hover reset clears it.

Punch debug audit: the current overlay row labels do not match the actual detector/debug payload cleanly. `arm_extension` and `elbow_bend` are currently fed from `arm_extension_3d` and `elbow_bend_deg_3d` in `src/detectors/pose_detector_substrate.gd`, so the current labels are at best incomplete and at worst misleading (`elbow_bend >= 145°` really means a straighter 3D elbow angle, not “more bend”). The own-half row is driven by `own_half_lock` and should be removed entirely per Derrick’s review. Forward velocity and forward distance are real detector values, but poor human-review rows in their current form: the fixture capture shows very noisy signed z-velocity spikes (for example left/right ranges of roughly `-191..136` and `-128..142`) and forward distance moves independently of an obvious punch event; the same capture emitted `guard`, `squat`, and `uppercut_right` events but no `punch_left` events, while straight-punch `phase` stayed `recovering` for all 408 captured left/right snapshots. Threshold drift is real in code: `_process_straight_punch()` and `_build_straight_punch_side_debug()` both derive `forward_velocity_min`, `forward_distance_min`, rearm margins, and own-half margins from the live per-frame `measurements.shoulder_width`, not a frozen calibration width. That makes the displayed thresholds move frame-to-frame with pose jitter/foreshortening.

Recommended next implementation slice: fix hover-row teardown so row containers are removed synchronously/reused instead of deferred-append stacking; remove the own-half row entirely; relabel any kept shape rows explicitly as 3D metrics (`3D arm reach ratio`, `3D elbow angle/straightness`). Replace the current thresholded speed/distance rows with more truthful debug rows centered on state + baselines, e.g. `phase`, `armed_forward_distance`, `current_forward_distance`, `forward_delta_from_armed`, `peak_forward_distance`, plus frozen thresholds computed from baseline shoulder width (or a shoulder width snapped at arm/rearm time, but not recomputed every frame). If a velocity row remains, it should either be smoothed/windowed and clearly labeled as raw z velocity, or be replaced with a less noisy derived delta row for human review.

---

### Task 9: Fix overlay height bug and realign Punch debugging rows with truthful detector signals

**Bead ID:** `aerobeat-input-mediapipe-python-dxi`  
**SubAgent:** `primary`  
**Role:** `coder`  
**References:** outputs from Task 8 plus `REF-04`–`REF-07`  
**Prompt:** Implement the next overlay/debugging pass based on the investigation. Fix the popup bug where moving directly between gesture status badges can reset the overlay into an extremely tall broken state. Remove the left/right own-half row entirely; do not keep it around as archival/debug wording. Rework the Punch rows so the overlay reflects detector signals that are actually truthful and stable for manual review; if current extension/elbow/velocity/distance values are mislabeled or structurally wrong, either relabel them accurately or replace them with better debug rows. If shoulder-width-derived thresholds are currently drifting frame-to-frame, move them to a frozen calibration/baseline source or otherwise stabilize them so the overlay comparisons are meaningful during a punch. Keep the overlay reusable and update the plan with the exact new truth model.

**Folders Created/Deleted/Modified:**
- `.testbed/scripts/`
- `src/detectors/`
- `.plans/`
- maybe `docs/` if a debug note belongs there

**Files Created/Deleted/Modified:**
- exact proving-scene and detector/debug files needed for the fixes
- `.plans/2026-05-19-boxing-gesture-requirements-hover-ui.md`
- optional notes/evidence files if needed

**Status:** ✅ Complete

**Results:** Implemented the next punch-overlay pass in `.testbed/scripts/boxing_proving_harness.gd` and `src/detectors/pose_detector_substrate.gd`, with two linked fixes: the popup row lifecycle now tears down/reuses row controls synchronously instead of mixing `queue_free()` with same-frame re-adds, and the Punch detector/debug payload now exposes frozen threshold/baseline values for the hover card instead of recomputing the displayed comparisons from live shoulder-width jitter.
- **Tall popup fix:** `_sync_hover_card_rows()` no longer clears children with deferred `queue_free()` before immediately adding replacement rows. It now diffs row IDs, removes stale row containers from `_hover_card_rows` synchronously, frees them immediately, reuses surviving row nodes, and reorders them in place. That removes the direct badge→badge accumulation path Task 8 identified.
- **Removed row entirely:** the old own-half/image-space row (`L-Hand is on left side of screen` / `R-Hand is on right side of screen`) is gone from the Punch cards and is no longer rendered anywhere in the overlay model.
- **Relabeled truthful 3D shape rows:** the old `Arm extension is >= 0.95` row is now `3D arm reach ratio is >= 0.95`, and the old `Elbow bend is >= 145°` row is now `3D elbow angle is >= 145°`, matching the actual `arm_extension_3d` and `elbow_bend_deg_3d` payload fields and avoiding the misleading “more bend” wording.
- **Replaced poor speed/distance rows with a new punch truth model:** instead of the old live-threshold `Forward velocity` and `Forward distance` rows, Punch now shows `Armed forward distance snapshot is latched`, `Forward delta from armed is >= <frozen Δ threshold>` with armed/current values inline, `Peak forward distance is tracked` with current value inline, `Raw forward z velocity is > <frozen vz threshold>`, and `Frozen threshold shoulder width is latched` with the snapped width plus derived Δ/vz thresholds. This keeps the overlay reusable while making the displayed values line up with how the detector actually reasons about a punch.
- **Threshold stabilization:** straight-punch state now carries `threshold_shoulder_width`, snapped when the side enters `armed` (initial arming or rearm). `_process_straight_punch()` uses that frozen width for fire delta, fire velocity, rearm retreat margin, rearm ready margin, and the extending→recovering own-half margin instead of live per-frame shoulder width. `_build_straight_punch_side_debug()` reads the same frozen width to expose coherent debug rows (`forward_delta_min`, `forward_velocity_min`, `threshold_shoulder_width`, etc.), so the overlay and detector share one stable threshold source through the punch cycle.
- Validation performed:
  - `~/.local/bin/godot --headless --path .testbed res://scenes/boxing_proving.tscn --quit-after 1`
  - `~/.local/bin/godot --headless --path .testbed --script ../.temp/qa-hover-polish.gd`
- Validation notes: both runs still report the pre-existing missing `boxing-weave-1.svg` import warning, unchanged from earlier tasks. The structured hover report now shows stable non-accumulating row counts across direct badge changes (`Punch-L` row_count `8`, `Punch-R` `8`, `Guard` `1`, `Squat` `1`) plus stable row instance IDs across repeated refreshes, which is the expected evidence that the tall popup bug is fixed in this pass.

---

### Task 10: QA and audit the corrected Punch overlay/debug truth before using it for redesign work

**Bead ID:** `aerobeat-input-mediapipe-python-q0r`  
**SubAgent:** `primary`  
**Role:** `qa` / `auditor`  
**References:** outputs from Tasks 8-9  
**Prompt:** First QA the corrected overlay behavior and Punch rows in the proving scene, then independently audit whether the new rows now match the actual detector/debug truth closely enough to drive the straight-punch redesign. Explicitly verify the popup height bug is gone, the phase no longer appears falsely stuck, removed rows are truly gone, and any stabilized threshold/baseline values behave coherently during punch review.

**Folders Created/Deleted/Modified:**
- `.plans/`
- `.temp/qa-task10-overlay/`

**Files Created/Deleted/Modified:**
- `.plans/2026-05-19-boxing-gesture-requirements-hover-ui.md`
- `.temp/qa-task10-overlay.gd`
- `.temp/qa-task10-overlay/report.json`
- `.temp/qa-task10-overlay/scene-smoke.log`
- `.temp/qa-task10-overlay/sampler.log`

**Status:** ❌ Failed (QA complete; auditor still needed)

**Results:** QA re-verified the corrected overlay and Punch rows with fresh runtime evidence from two sources: `.temp/qa-task10-overlay/report.json` (new fixture-backed headless sampling against `boxing_punch_left_x4_while_guarding_take_01.mp4`) plus `.temp/qa-task10-overlay/scene-smoke.log` / `.temp/qa-task10-overlay/sampler.log` for command logs. This pass also cross-checked the direct badge-transition behavior through the live scene root rather than relying only on code review.
- **Popup stability bug appears fixed.** Repeated direct badge transitions now stayed sane with no tall accumulation state: `Punch-L` row count `8`, `Punch-R` `8`, `Guard` `1`, `Squat` `1`, then back to `Punch-L` `8` / `Punch-R` `8` / `Guard` `1` / `Squat` `1` / `Punch-L` `8` in the fresh runtime capture (`report.json > transitions[*].row_count`). That directly covers the previously broken badge→badge path Derrick reported.
- **Own-half / side-of-screen row is fully gone from Punch-L and Punch-R.** Fresh Punch card rows are now: phase, 3D arm reach ratio, 3D elbow angle, armed forward-distance snapshot, forward delta from armed, peak forward distance, raw forward z velocity, and frozen threshold shoulder width. No `own_half`, `side of screen`, or equivalent row appeared anywhere in the live `Punch-L` / `Punch-R` card captures (`report.json > punch_left_card.rows`, `punch_right_card.rows`, and `transitions[0/1].rows`).
- **New truth-model rows do render and are more readable.** The live overlay text now matches the intended rework from Task 9: `3D arm reach ratio`, `3D elbow angle`, `Armed forward distance snapshot`, `Forward delta from armed`, `Peak forward distance`, `Raw forward z velocity`, and `Frozen threshold shoulder width` all render in the live card output (`transitions[0].rows`, `transitions[1].rows`). The old mislabeled 2D/own-half rows are not present.
- **Phase row no longer appears falsely stuck on `armed`, but this fixture did not exercise a full good punch cycle.** Across 72 fresh runtime samples from the guarded left-punch video, both sides stayed in `recovering`, not `armed` (`report.json > samples.samples[*].left.phase/right.phase`). That is good evidence the old “looks permanently armed” problem is gone, but this specific fixture still did not produce a runtime sample showing `armed`→`extending` transitions or any `punch_left` events, so QA could not positively verify the full phase-cycle readability here.
- **Row counts stay sane under repeated direct transitions.** No row accumulation reappeared in the fresh transition sequence, and the Punch cards consistently rendered exactly 8 rows each instead of growing across hovers.
- **Remaining QA blocker: the frozen-threshold row is still not truthful/coherent enough in this runtime.** In the fresh fixture-backed sample set, both left and right `threshold_shoulder_width` values changed every sample in lockstep with live `shoulder_width` (`72` threshold changes across `72` shoulder-width changes for both sides), while both sides remained in `recovering` the whole time. So the overlay row labeled `Frozen threshold shoulder width is latched` was still effectively following live shoulder width in this runtime capture rather than presenting a clearly frozen value. That means Goal 5 is not convincingly satisfied yet, at least outside a successfully armed/extending punch cycle.
- **No new parse/runtime regressions were introduced by the Punch overlay truth patch itself.** Fresh smoke run `~/.local/bin/godot --headless --path .testbed res://scenes/boxing_proving.tscn --quit-after 1` completed without new Punch-overlay parse errors; the only recurring issues were the same pre-existing missing `boxing-weave-1.svg` import warning and the usual abrupt-quit shutdown/resource-noise seen in prior headless smoke runs (`scene-smoke.log`). The fixture-backed sampler also ran cleanly after removing screenshot capture attempts from the temp QA script (`sampler.log`).
- **QA verdict:** fail for now, specifically because the `Frozen threshold shoulder width is latched` debug row still behaved like a live shoulder-width follower in the captured runtime instead of an obviously frozen baseline/latched value. Popup stability, row removal, row rendering, and non-accumulating transitions all passed.
- **Audit handoff concern:** auditor should verify whether the current fallback path in `src/detectors/pose_detector_substrate.gd` / debug builder is intentionally exposing live shoulder width whenever the punch side never reaches `armed`, and whether the overlay wording/state should distinguish `not latched yet` from `latched` instead of always presenting the row as frozen truth.

---

### Task 11: Investigate remaining live-review regressions (popup bug, phase stickiness, calibration section)

**Bead ID:** `aerobeat-input-mediapipe-python-hww`  
**SubAgent:** `primary`  
**Role:** `research`  
**References:** outputs from Tasks 8-10 plus Derrick review notes from 2026-05-20  
**Prompt:** Investigate the remaining live-review regressions in the Boxing proving scene. Reproduce and explain why the gesture info popup bug is still present in live review even after the earlier row-accumulation fix. Determine whether `L-punch phase` is supposed to transition away from `armed` in the current detector state machine and why Derrick still observes it stuck at `armed` in the live scene. Also determine what calibration/baseline values are actually latched today and which of them should be displayed in a visually separated calibration section at the bottom of the popup. Do not investigate the separate Chip `python server died` issue in this slice; defer that to later work.

**Folders Created/Deleted/Modified:**
- `.testbed/scripts/`
- `src/detectors/`
- `.plans/`
- maybe `.temp/` if evidence artifacts or logs are needed

**Files Created/Deleted/Modified:**
- exact proving-scene, detector, and runtime files inspected
- `.plans/2026-05-19-boxing-gesture-requirements-hover-ui.md`
- optional evidence/log files if needed

**Status:** ✅ Complete

**Results:** Investigated the remaining live-review regressions with code review plus the existing runtime evidence in `.temp/qa-task10-overlay/report.json` and `.temp/qa-hover-polish/report.json`.
- **Popup bug root cause after the row-accumulation fix:** the remaining bug is no longer child-row stacking; it is stale popup **panel size** when switching from a taller card to a shorter one. Current code in `.testbed/scripts/boxing_proving_harness.gd` now removes stale row containers synchronously in `_sync_hover_card_rows()` (`594-632`), so the old accumulation path is genuinely fixed. But `_refresh_hover_card()` only calls `_hover_card_panel.reset_size()` after swapping content (`466-487`), and the hover card itself is a `top_level` `PanelContainer` (`251-260`), not a layout-managed child. Runtime evidence shows the content shrinks correctly while the actual panel size does not: in `.temp/qa-task10-overlay/report.json`, `guard` and `squat` transitions both have `row_count: 1` and `panel_min_size: [440, 121]`, yet `panel_size` stays `[440, 1133]`; the same pattern appears in `.temp/qa-hover-polish/report.json` where single-row placeholder cards still report huge panel sizes (`1597`) despite only one row. So Derrick’s live popup bug is best explained by **size carry-over on the top-level panel after content shrink**, not by more hidden row duplication.
- **`L-punch phase` transition truth:** yes, `armed` is absolutely supposed to transition away in the current state machine — specifically `armed -> extending` on a successful fire, then `extending -> recovering` when the hand stops advancing / leaves lane / falls back from peak. The relevant code is `_process_straight_punch()` in `src/detectors/pose_detector_substrate.gd` (`723-789`). `recovering -> armed` happens when the side is lane-locked and not yet straight enough (`748-750` or `755-759`). `armed -> extending` only happens when **all** fire gates pass at once: `lane_locked`, `straight_enough`, `forward_velocity > forward_velocity_min`, and `forward_distance >= armed_forward_distance + forward_delta_min` (`771-781`). The important behavior gap is that the `phase == "armed"` branch has **no non-fire exit path at all**: if those fire gates never all go true on the same frame, the code just writes the state back and returns (`783-784`). Even losing lane lock while armed does not demote the phase. So Derrick seeing `L-punch phase` sit at `armed` in live review is consistent with the current detector semantics, not obviously a stale UI read. It likely means the side entered `armed` successfully, then never simultaneously satisfied the extension + elbow + velocity + delta gates strongly enough to fire, and the current state machine provides no timeout/disarm path back out of `armed`.
- **Calibration / baseline values actually latched today:** there are two real latch layers in current code, plus one misleading debug fallback:
  1. **Global detector baseline** (`_baseline`) is latched once after 5 valid tracking/reacquiring frames in `_update_baseline()` (`437-481`). The truly frozen values are: `is_calibrated`, `sample_frames`, `shoulder_width`, `torso_height`, `athlete_height`, `shoulder_center_x`, `hip_center_y`, `nose_y`, `left_knee_y`, `right_knee_y`, `left_ankle_y`, and `right_ankle_y`.
  2. **Per-side straight-punch baseline/state** lives in `_gesture_state.straight_punch.<side>` and currently stores `phase`, `armed_forward_distance`, `peak_forward_distance`, and `threshold_shoulder_width` (`1144-1148`). Of those, the truly latched baseline-style values are `armed_forward_distance` and `threshold_shoulder_width`, both snapped when the side enters `armed` / rearms (`745-750`, `755-759`, `766-770`). `peak_forward_distance` is not calibration; it is a live running peak after arming.
  3. **Derived thresholds** shown in debug (`forward_delta_min`, `forward_velocity_min`, `rearm_retreat_min`, `rearm_ready_margin`) are not independently latched; they are recomputed from the per-side frozen `threshold_shoulder_width` in `_build_straight_punch_side_debug()` (`524-554`).
  4. **Misleading fallback still present:** when `state.threshold_shoulder_width` is still zero, `_get_straight_punch_threshold_shoulder_width()` falls back to the live current shoulder width (`1161-1165`), so the overlay can currently claim a value is `frozen` even when the side has not actually latched one yet.
- **Recommended calibration section for the popup bottom:** only show values that are truly frozen or are directly derived from those frozen values, and visually separate them from the live pass/fail rows. Best bottom section contents for Punch are:
  - `Calibration ready` / `Not calibrated yet` from `_baseline.is_calibrated`
  - `Calibration sample frames` from `_baseline.sample_frames`
  - `Baseline shoulder width` from `_baseline.shoulder_width`
  - `Baseline torso height` from `_baseline.torso_height`
  - optional `Baseline athlete height` from `_baseline.athlete_height` if there is room
  - `Armed forward distance snapshot` from side state `armed_forward_distance`
  - `Frozen threshold shoulder width` from side state `threshold_shoulder_width`, but shown as `not latched yet` when the underlying state value is still `0.0`
  - derived `Forward delta min` and `Forward velocity min`, explicitly labeled as derived from the frozen threshold width
- **What the coder should implement next:**
  1. Fix the remaining popup bug by explicitly resizing the top-level hover panel to its new combined minimum size after row/content changes, rather than relying on `reset_size()` alone, and then reposition it using the new size.
  2. Stop labeling threshold rows as frozen when they are coming from the live-width fallback. Expose an explicit boolean like `threshold_shoulder_width_latched` (or equivalent) from detector debug so the UI can say `not latched yet` honestly.
  3. Add a visually separated calibration/baseline section at the bottom of Punch cards for the real frozen values listed above.
  4. Decide whether to change the detector state machine or just the overlay wording: if `armed` should not sit forever, add a real de-arm / timeout / lost-lane escape path in `_process_straight_punch()`; if it is allowed to sit forever for now, make the overlay wording reflect that `armed` means `waiting for fire gates` rather than implying a punch is actively progressing.

---

### Task 12: Fix live popup regression, add calibration section, and correct phase/runtime truth surfacing

**Bead ID:** `aerobeat-input-mediapipe-python-sf9`  
**SubAgent:** `primary`  
**Role:** `coder`  
**References:** outputs from Task 11 plus `REF-04`–`REF-07`  
**Prompt:** Implement the next proving-scene overlay/debugging pass based on the live-review investigation. Fix the remaining live popup bug, add a visually separated calibration section below the main Punch debug rows that shows the currently latched calibration/baseline values, and correct the phase/runtime truth surfacing so the overlay honestly reflects whether Punch is armed, extending, recovering, or not latched yet. Do not expand scope into the separate Chip `python server died` issue in this slice. Keep the overlay reusable and update the plan with the exact new truth model.

**Folders Created/Deleted/Modified:**
- `.testbed/scripts/`
- `src/detectors/`
- `.plans/`
- `.temp/task12-overlay/`

**Files Created/Deleted/Modified:**
- `.testbed/scripts/boxing_proving_harness.gd`
- `src/detectors/pose_detector_substrate.gd`
- `.plans/2026-05-19-boxing-gesture-requirements-hover-ui.md`
- `.temp/task12-overlay.gd`
- `.temp/task12-overlay/report.json`

**Status:** ✅ Complete

**Results:** Implemented the next live-review punch overlay pass in `.testbed/scripts/boxing_proving_harness.gd` and `src/detectors/pose_detector_substrate.gd`.
- **Remaining popup bug fixed for the real root cause:** the row-accumulation fix from Task 9 stayed intact, but the actual live regression was stale size on the top-level hover popup after switching from a taller card to a shorter one. The fix now explicitly reapplies the popup rect after content changes instead of trusting `reset_size()` alone: `_refresh_hover_card()` now calls `_resize_and_reposition_hover_card()`, which recomputes the combined minimum size, assigns that exact `size` to the top-level panel, then repositions it against the hovered badge. It also repeats the rect application in a deferred pass so the top-level `PanelContainer` shrinks correctly after layout settles.
- **Reusable calibration section added at the bottom of Punch cards:** Punch-L and Punch-R now append a visually separated `Calibration / Baselines` section after the main truth rows. This uses reusable row kinds (`requirement`, `section`, `info`) rather than a Punch-only hardcoded footer layout.
- **Calibration section truth model now shows only honest baseline/latch data:**
  - `Calibration status` (`ready` / `not ready`)
  - `Calibration sample frames`
  - `Baseline shoulder width`
  - `Baseline torso height`
  - `Baseline athlete height`
  - `Armed forward distance snapshot`
  - `Frozen threshold shoulder width` or `not latched yet (live <width>)`
  - `Derived forward delta min`
  - `Derived forward velocity min`
- **Latch truth surfaced explicitly:** `pose_detector_substrate.gd` now exposes `threshold_shoulder_width_latched`, `latched_threshold_shoulder_width`, and `live_shoulder_width` in the straight-punch debug payload, alongside baseline/calibration values. The overlay now uses that boolean so neither the main threshold row nor the calibration section falsely claims a frozen width when the detector is still falling back to live shoulder width.
- **Phase truth is surfaced more honestly without inventing detector behavior:** the detector state machine was left intact in this slice. The phase row still truthfully checks `phase == armed`, but the displayed phase text now reflects the actual runtime state (`recovering`, `extending`, or `armed (waiting for fire gates)`) so the overlay does not imply a punch is progressing when the detector is merely sitting in `armed` waiting for all fire gates to line up.
- **New Punch overlay truth model after this task:**
  1. main checkbox rows remain detector-fire/debug rows (`phase`, `3D arm reach ratio`, `3D elbow angle`, armed snapshot, forward delta, peak distance, raw forward velocity, threshold-width latch state)
  2. calibration/baseline values are shown separately in a bottom section and do not pretend to be gate checks
  3. frozen-threshold claims are now conditional on the explicit detector latch boolean rather than inferred from fallback values
- **Validation performed:**
  - `~/.local/bin/godot --headless --path .testbed res://scenes/boxing_proving.tscn --quit-after 1`
  - `~/.local/bin/godot --headless --path .testbed --script ../.temp/task12-overlay.gd`
- **Validation evidence:** `.temp/task12-overlay/report.json` now shows the tall→short popup path shrinking correctly again (`Punch-L` `panel_size=[440,643]` then `Guard` / `Squat` `panel_size=[440,121]`, matching `panel_min_size`), and shows the new latch-truth text on the calibration row (`Frozen threshold shoulder width - not latched yet (live ...)`).
- **Known unrelated issue still present:** the pre-existing missing `boxing-weave-1.svg` import warning still appears during headless validation and is unrelated to this slice.

---

### Task 13: QA and audit the live-reviewed Punch overlay/runtime truth

**Bead ID:** `aerobeat-input-mediapipe-python-dcj`  
**SubAgent:** `primary`  
**Role:** `qa` / `auditor`  
**References:** outputs from Tasks 11-12  
**Prompt:** First QA the updated overlay/runtime behavior against the specific live-review regressions, then independently audit whether the popup bug is actually gone in real use, whether the calibration section is truthful and readable, and whether the phase display now matches detector/runtime truth. Do not include the separate Chip `python server died` issue in this slice.

**Folders Created/Deleted/Modified:**
- `.plans/`
- `.temp/task13-overlay/`

**Files Created/Deleted/Modified:**
- `.plans/2026-05-19-boxing-gesture-requirements-hover-ui.md`
- `.temp/task13-overlay.gd`
- `.temp/task13-overlay/report.json`

**Status:** ✅ Complete

**Results:** QA + audit completed against commit `d911c49` with fresh runtime evidence from both punch fixtures plus targeted substrate unit coverage.
- **Popup shrink regression:** passed. Fresh headless transition captures in `.temp/task13-overlay/report.json` show the tall→short path shrinking correctly on direct badge-to-badge moves for both fixtures: Punch cards render at `panel_size == panel_min_size == [440,643]`, then Guard/Squat immediately shrink to `panel_size == panel_min_size == [440,121]`, then expand back to Punch without stale carry-over.
- **Calibration section presence/readability:** passed. Both `punch_left_card` and `punch_right_card` now contain 18 rows with `calibration_section_index == 8`, placing a clearly separated `Calibration / Baselines` section below the 8 main Punch requirement rows. The bottom section truthfully shows `Calibration status`, `Calibration sample frames`, baseline dimensions, armed snapshot, threshold width, and derived Δ/vz mins.
- **Latch truth honesty:** passed for the live fallback path; partially unproven for the true-latched branch. Across 90 sampled frames per fixture/side, `threshold_shoulder_width_latched` stayed `false` and the overlay consistently said `not latched yet (live ...)` in both the main threshold row and the calibration row instead of falsely claiming a frozen width. These fixtures did not produce a runtime sample where the threshold width became latched, so the positive `latched` wording branch was not directly witnessed in live runtime during this QA pass.
- **Phase truth honesty:** passed for observed runtime states; partially unproven for the `armed` display branch. Across both fresh fixture passes, all sampled left/right phases stayed `recovering`, and the phase row/card text matched that runtime truth instead of appearing falsely stuck on `armed`. The detector/UI branch that renders `armed (waiting for fire gates)` is wired in code and consistent with Task 11’s state-machine analysis, but these fixtures did not naturally enter `armed` or `extending`, so that exact live wording branch remains unobserved here.
- **Parse/runtime issues:** no new task-slice failures found. Validation commands run: `~/.local/bin/godot --headless --path .testbed res://scenes/boxing_proving.tscn --quit-after 1`, `~/.local/bin/godot --headless --path .testbed --script ../.temp/task13-overlay.gd`, and `~/.local/bin/godot --headless --path .testbed --script addons/gut/gut_cmdln.gd -gtest=res://tests/unit/test_pose_detector_substrate.gd -gexit` (`12/12 passed`). The only runtime issue observed was the pre-existing missing `boxing-weave-1.svg` import/load warning, unchanged from earlier tasks.
- **Audit conclusion:** good enough for continued debugging use. The popup sizing bug is fixed, the calibration/baseline split is readable, and the overlay no longer lies about frozen threshold width when the detector is still on live fallback. Remaining uncertainty is mostly branch coverage / detector-behavior proof (`armed`, `extending`, true threshold latching) rather than a discovered new overlay-truth regression.

---

## Final Results

**Status:** ⚠️ Provisionally complete

**What We Built:**
- A reusable Boxing proving-scene gesture detection overlay with live requirement rows, starting with detector-backed Punch-L and Punch-R cards.
- Per-subgesture hover activation on the specific `L` / `R` / state badges instead of whole gesture tiles.
- A readability/performance polish pass that widened the panel, increased font sizes, switched to font-safe ASCII checkboxes, and removed the worst hover-time UI rebuild churn.
- Final accepted handoff state: the overlay is approved for **provisional debugging use** in the next straight-punch side-ownership redesign pass, with the explicit caveat that row 2 ownership wording is temporary and likely to change along with the gate itself.

**Reference Check:**
- `REF-01` / `REF-02` explain why debugging visibility is now more important than more blind threshold tweaking.
- `REF-04` / `REF-05` identify the proving-scene surface that should expose the requirements.
- `REF-06` / `REF-07` identify the detector/metric truth source that the UI must reflect.

**Commits:**
- `0abb9b1` - Implement boxing gesture hover card shell
- `f1b026b` - Hook Punch-L hover card to live debug state
- `d0c5ce8` - Clean Punch-L hover helper text
- `6d27149` - Polish gesture detection hover overlay

**Lessons Learned:**
- A debugging UI is only useful if each displayed line maps to a real detector gate.
- The wording needs to be plain enough for human review, not just technically correct.
- Spatial left/right assumptions need explicit scrutiny when the camera view and athlete perspective may not match.

---

*Created on 2026-05-19*