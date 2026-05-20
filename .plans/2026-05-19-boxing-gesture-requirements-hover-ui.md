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

## Final Results

**Status:** Draft / in progress

**What We Built:**
- A plan to turn Boxing gesture requirements into a live hoverable debugging UI, starting with Punch-L.
- Current handoff state: the Punch-L popup is now cleaned for manual UI review next session — the live rows/values remain wired, and the extra warning/helper text has been removed without rewriting the approved main row wording.

**Reference Check:**
- `REF-01` / `REF-02` explain why debugging visibility is now more important than more blind threshold tweaking.
- `REF-04` / `REF-05` identify the proving-scene surface that should expose the requirements.
- `REF-06` / `REF-07` identify the detector/metric truth source that the UI must reflect.

**Commits:**
- None yet.

**Lessons Learned:**
- A debugging UI is only useful if each displayed line maps to a real detector gate.
- The wording needs to be plain enough for human review, not just technically correct.
- Spatial left/right assumptions need explicit scrutiny when the camera view and athlete perspective may not match.

---

*Created on 2026-05-19*