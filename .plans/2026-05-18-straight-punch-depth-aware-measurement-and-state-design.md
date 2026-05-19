# AeroBeat MediaPipe Python — Straight-Punch Depth-Aware Measurement and State Design

**Date:** 2026-05-18  
**Status:** In Progress  
**Agent:** Pico 🐱‍🏍

---

## Goal

Design and implement the next truthful Boxing straight-punch detector slice so the guarded-left golden-truth fixture can recognize real forward punches without introducing spam, by treating depth-aware extension, truthful retraction/rearm, and left/right side disambiguation as one coupled problem.

---

## Overview

The previous punch-left investigation completed a full coder → QA → audit loop and reached a stable conclusion: the current failure is not mainly a missing forwarder, a stuck ready flag, or a simple threshold problem. The preserved instrumentation now shows that the fixture’s front-facing forward punches collapse under the current 2D straight-punch measurements even while temporary 3D comparison values show near-full extension and strong forward motion during the authored punch windows.

That means the next slice should not be another threshold nudge. Two narrow detector experiments already proved that a naive “switch straight punches to 3D” patch causes false positive spam and breaks truthful retraction behavior. So this next plan needs to treat three things together: how straight-punch extension is measured, how a punch returns to a ready/rearmed state, and how the detector distinguishes left/right straight punches from one another during forward motion.

This plan should stay Boxing-only and fixture-driven. The trimmed guarded-left golden-truth fixture remains the first proving target, and all decisions should be recorded both in the plan and in the living HTML experiment log. The outcome we want is not just “some `punch_left` events appear”; it is a truthful step forward that improves authored-window hits without masking new false positives or fake rearm behavior.

---

## REFERENCES

| ID | Description | Path |
| --- | --- | --- |
| `REF-01` | Previous punch-left instrumentation / stop-sign plan | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-mediapipe-python/.plans/2026-05-18-punch-left-golden-truth-detector-improvement.md` |
| `REF-02` | Living HTML experiment log | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-mediapipe-python/docs/punch-left-golden-truth-experiment-log.html` |
| `REF-03` | Detector substrate | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-mediapipe-python/src/detectors/pose_detector_substrate.gd` |
| `REF-04` | Pose metrics helpers | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-mediapipe-python/src/detectors/pose_metrics.gd` |
| `REF-05` | Proving harness with kept `boxing_debug` instrumentation | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-mediapipe-python/.testbed/scripts/proving_harness.gd` |
| `REF-06` | Guarded-left fixture YAML | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-mediapipe-python/.testbed/assets/fixtures/boxing/punch_left/boxing_punch_left_x4_while_guarding_take_01.yaml` |
| `REF-07` | Guarded-left fixture video | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-mediapipe-python/.testbed/assets/fixtures/boxing/punch_left/boxing_punch_left_x4_while_guarding_take_01.mp4` |
| `REF-08` | Strong instrumentation artifact pass | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-mediapipe-python/.testbed/test-results/runner-boxing/20260518-214702__boxing_punch_left_x4_while_guarding_take_01/20260518-214702__boxing_punch_left_x4_while_guarding_take_01/` |
| `REF-09` | Final kept rerun with instrumentation | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-mediapipe-python/.testbed/test-results/runner-boxing/20260518-215350__boxing_punch_left_x4_while_guarding_take_01/20260518-215350__boxing_punch_left_x4_while_guarding_take_01/` |

---

## Research design conclusions

### What the preserved evidence now supports

The preserved `boxing_debug` evidence says the straight-punch problem is a coupled-model problem, not a missing threshold tweak. On the authored left-punch windows in `REF-09`, the current 2D fire inputs collapse even while temporary 3D comparison values show a mostly straight, depth-extending arm:

- window 1 peak near `1287 ms`: `arm_extension 0.237` vs `arm_extension_3d 0.987`; `elbow_bend_deg 0.0` vs `elbow_bend_deg_3d 161.5`; `forward_velocity 8.04`
- window 2 peak near `2631 ms`: `arm_extension 0.105` vs `arm_extension_3d 0.972`; `elbow_bend_deg 0.0` vs `elbow_bend_deg_3d 152.7`; `forward_velocity 18.36`
- window 3 peak near `3467 ms`: `arm_extension 0.429` vs `arm_extension_3d 0.981`; `elbow_bend_deg 0.0` vs `elbow_bend_deg_3d 157.8`; `forward_velocity 13.89`
- window 4 peak near `4888 ms`: the same 2D-vs-3D collapse remains, but the forward burst is directionally weak (`forward_velocity -0.12`), so that authored punch is currently the least well-explained window

The same preserved run also shows why the naive 3D patches spammed: clip-wide `arm_extension_3d >= 0.92` for `131 / 176` captured samples in `REF-09`. So 3D extension is useful as “the arm is truly long/straight in depth,” but not truthful as a standalone fire gate or standalone rearm gate.

### Existing measurements that are still trustworthy enough to keep using

- `shoulder_width` normalization from `REF-03` / `REF-04` is still useful for per-athlete ratios. Nothing in the evidence suggests the detector lost basic scale normalization.
- Handed landmark identity itself still looks usable enough for Boxing-side ownership. The baseline failure did **not** emit stray `punch_right` events in the reverted kept run, which argues against a primary left/right landmark swap bug.
- 2D `outward_distance` and the sign of horizontal hand placement relative to the owning shoulder are still useful as **side-lane / ownership** clues. They are weak extension measures for forward punches, but they remain useful for “is this still the left hand working on the left side?”
- 2D/3D hand velocity remain useful as transient motion evidence, but only when interpreted as bursts / transitions rather than absolute truths. In particular, positive `forward_velocity` spikes in windows 1-3 align with the authored forward punches much better than the old lateral-only straight-punch gates do.
- The existing ready/rearm concept in `REF-03` is still the right overall shape: straight punches need a one-shot fire and an explicit return condition before rearming. What failed was the metric feeding that state, not the need for the state itself.

### Existing measurements that are misleading on front-facing forward punches

- 2D `left_arm_extension` / `right_arm_extension` from shoulder-to-wrist distance in image space are misleading as primary straight-punch extension truth for front-facing punches. The arm moves toward camera depth while image-plane shoulder/wrist distance stays tiny.
- 2D `left_elbow_bend_deg` / `right_elbow_bend_deg` are likewise misleading for the same projection reason. The authored punch windows repeatedly look almost fully bent in 2D while the temporary 3D elbow measurement says the arm is mostly straight.
- 2D `outward_distance` is misleading as a fire threshold for forward straights. In `REF-03` it currently acts like a lateral reach requirement, which is exactly what a front-facing jab/cross does not strongly satisfy.
- Absolute `forward_distance` by itself is also misleading as a punch/not-punch threshold. In `REF-09`, forward distance stays elevated across wide parts of the clip, so an absolute threshold would not give truthful retraction timing.
- `forward_velocity` alone is too noisy to own the detector. The preserved run contains large depth-velocity swings outside authored windows too, so using velocity without per-side state or extension truth will create spam.
- Naive 3D straightness (`arm_extension_3d` / `elbow_bend_deg_3d`) alone is misleading for rearm. The rejected experiments already proved that “arm still straight in 3D” is not the same thing as “new punch may fire again now.”

### Design options considered

1. **Retune the existing 2D straight-punch thresholds only.**
   - **Rejected.** The kept evidence now shows the 2D straight-punch inputs are structurally lying on the authored forward punches. Lowering thresholds would just tune around a projection failure.

2. **Replace straight-punch fire truth with 3D extension + 3D elbow + forward velocity, leaving the rest alone.**
   - **Rejected.** This was the A2 experiment recorded in `REF-02`. It produced stray `punch_left` / `punch_right` events and broke truthful retraction because the arm stayed “extended” in 3D for too much of the clip.

3. **Hybrid patch: keep old 2D rearm behavior, but let fire-time use 3D arm truth + forward burst.**
   - **Rejected.** This was the A3 experiment recorded in `REF-02`. It still spammed repeated false positives, which means fire-time truth and rearm truth cannot be split that cheaply.

4. **Smallest plausible Boxing-only coupled model: depth-aware fire truth plus explicit retraction state plus side lock.**
   - **Recommended.** The detector should treat extension, retraction, and left/right disambiguation as one per-side straight-punch model instead of trying to patch any one of them in isolation.

### Smallest plausible new detector state / metric surface before coding

Keep the scope Boxing-only and per-side. The smallest honest addition is:

- **New reusable per-side metrics** (computed in substrate or `PoseMetrics`, then surfaced for both left and right):
  - `arm_extension_3d`
  - `elbow_bend_deg_3d`
  - `forward_distance` (shoulder `z` minus wrist `z`)
  - `forward_velocity` (negative wrist `z` velocity)
  - `lane_offset_ratio` or equivalent reuse of current signed `outward_distance` / own-half placement, explicitly treated as a **side lock**, not as extension truth

- **New per-side straight-punch state**:
  - `phase`: `armed` → `extending` → `recovering`
  - `armed_forward_distance`: baseline forward reach captured when the hand is back in its ready/guard lane
  - `peak_forward_distance`: highest forward reach seen during the current extension

That is the minimum state that makes the three coupled questions explicit:

- **extension truth:** use 3D arm length/straightness plus positive forward travel
- **side truth:** lock the active side with own-lane placement instead of asking forward depth to decide left vs right
- **rearm truth:** require measurable retreat from the extension peak before the side can arm again

### Narrow recommended next coding slice

Implement only the following slice before any broader tuning:

1. Promote the currently temporary left-only debug quantities into real mirrored left/right Boxing metrics, but do **not** change hook/uppercut/flow families.
2. Add a per-side straight-punch mini-state in `pose_detector_substrate.gd` with `armed`, `extending`, and `recovering` phases plus `armed_forward_distance` / `peak_forward_distance`.
3. Enter `extending` only when all of these are true on the candidate side:
   - 3D arm truth says the arm is sufficiently long/straight (`arm_extension_3d`, `elbow_bend_deg_3d`)
   - forward travel is increasing relative to the armed baseline, not merely high in absolute terms
   - the wrist is still in its owning side lane / own half, so the detector knows this is still left versus right
4. Fire `punch_left` / `punch_right` only once per extension phase.
5. Rearm only after both conditions are met:
   - forward reach has retreated meaningfully from `peak_forward_distance`
   - the hand has returned near its ready lane / ready reach, so recovery is visible in both depth and side placement

### Hidden follow-up work discovered during research

- The next implementation slice should mirror the debug surface for the right side so left/right disambiguation can be truth-checked symmetrically. That is still part of the Boxing-only straight-punch slice, not a new family redesign.
- The fourth authored punch window remains less well explained than the first three because its preserved `forward_velocity` does not show the same clean positive burst. The next coding slice should be truthful about that and should not promise a clean 4/4 fixture pass before the new state model is rerun.
- Guard and squat truth are still shaky in this clip. That is evidence of broader geometry tension, but this slice should only touch those areas if the straight-punch rearm model cannot be made truthful without a tiny supporting adjustment.

---

## Tasks

### Task 1: Design a truthful straight-punch state model from the preserved 2D/3D fixture evidence

**Bead ID:** `aerobeat-input-mediapipe-python-x12`  
**SubAgent:** `primary`  
**Role:** `research`  
**References:** `REF-01`, `REF-02`, `REF-03`, `REF-04`, `REF-08`, `REF-09`  
**Prompt:** Starting from the kept instrumentation evidence, design a Boxing-only straight-punch model that treats extension, retraction/rearm, and left/right side disambiguation together. Be explicit about which existing measurements are still trustworthy, which are misleading on front-facing forward punches, and what the smallest plausible new detector state or metric surface should be before coding begins. Update both this plan and the HTML log with the design options, rejected shortcuts, and the narrow recommended coding slice.

**Folders Created/Deleted/Modified:**
- `.plans/`
- `docs/`

**Files Created/Deleted/Modified:**
- `.plans/2026-05-18-straight-punch-depth-aware-measurement-and-state-design.md`
- `docs/punch-left-golden-truth-experiment-log.html`

**Status:** ✅ Complete

**Results:**
- Re-read the archived punch-left stop-sign plan (`REF-01`), the living HTML log (`REF-02`), the current substrate/metrics code (`REF-03`, `REF-04`), and the two preserved instrumentation artifact folders (`REF-08`, `REF-09`).
- Confirmed the preserved evidence now supports a coupled Boxing-only straight-punch model: 2D extension/straightness is misleading on front-facing forward punches, but naive 3D fire truth also lies unless retraction/rearm and side ownership are redesigned at the same time.
- Recorded the trustworthy versus misleading measurements directly in this plan and in the shared HTML log. The most important new hard fact is that `arm_extension_3d >= 0.92` for `131 / 176` captured samples in `REF-09`, which explains why the naive 3D experiments spammed and why rearm cannot rely on 3D extension alone.
- Rejected three shortcuts explicitly: (1) threshold-only tuning on the current 2D gates, (2) a direct 3D straight-punch gate swap, and (3) a split hybrid where fire uses 3D but rearm stays on old 2D logic.
- Narrow recommended coding slice: promote mirrored left/right depth-aware straight-punch metrics, add a tiny per-side `armed -> extending -> recovering` straight-punch state with stored forward-distance baseline/peak, fire once on 3D-straight + forward-increase + side-lock, and rearm only after visible retreat plus lane return.
- Hidden follow-up noted truthfully instead of silently expanding scope: the fourth authored punch window is less well explained than the first three, so the next coding slice should not promise an honest 4/4 fix until the new state model is rerun.

---

### Task 2: Implement the smallest depth-aware straight-punch measurement/state slice

**Bead ID:** `aerobeat-input-mediapipe-python-asf`  
**SubAgent:** `primary`  
**Role:** `coder`  
**References:** `REF-03`, `REF-04`, `REF-05`, `REF-06`, `REF-07`, `REF-08`, `REF-09`  
**Prompt:** Implement only the smallest truthful detector slice justified by Task 1. Keep scope Boxing-only and fixture-driven. Use the kept `boxing_debug` surface to verify the new model. Update the HTML log before and after each real attempt, rerun the guarded-left fixture, preserve evidence, and stop immediately if the change creates spam or fake rearm behavior.

**Folders Created/Deleted/Modified:**
- `.plans/`
- `src/detectors/`
- `.testbed/scripts/`
- `.testbed/test-results/runner-boxing/`
- `docs/`

**Files Created/Deleted/Modified:**
- exact detector / harness / doc files required by the slice
- `.plans/2026-05-18-straight-punch-depth-aware-measurement-and-state-design.md`
- `docs/punch-left-golden-truth-experiment-log.html`

**Status:** ⚠️ Interrupted / preserved for resumption

**Results:**
- Task 1 completed and the implementation slice was actively in progress on the recommended Boxing-only coupled model: mirrored 3D straight-punch metrics, per-side `armed → extending → recovering` state, `armed_forward_distance` / `peak_forward_distance`, and proving-harness debug surfacing for the new measurements/state.
- The current WIP code changes in `src/detectors/pose_detector_substrate.gd`, `src/detectors/pose_metrics.gd`, and `.testbed/scripts/proving_harness.gd` were preserved exactly as-is after the coding slice was interrupted by a host GUI/login reset during harness validation.
- Validation did **not** complete during the interrupted coding slice. No truthful claim is being made yet about authored-window hit counts, false-positive counts, rearm quality, or any successful guarded-left rerun result from this WIP slice itself.
- Follow-up QA on 2026-05-19 retried the same Boxing proving path under the updated generic Godot workflow guardrails and confirmed the human-equivalent editor route can complete cleanly on this host: deliberate `.testbed` editor open, switch to `boxing_proving.tscn`, `Play Current Scene` (`F6`), `Stop Running Project` (`F8`), then separate graceful editor close (`Ctrl+Q`). That retry reached Boxing harness live state and exited without reproducing the GUI/login reset, but it was a close-path workflow check, **not** a resumed truth-validation pass for the preserved straight-punch WIP.
- The next step is still to resume from this preserved checkpoint and rerun the guarded-left fixture for actual detector truth from fresh artifacts when ready.
- Additional close-path validation note from 2026-05-19: a separate QA proof of the new headless-manager route succeeded on the integrated `.testbed` by requesting shutdown only through `.testbed/.headless/quit.request`, and both headless Godot plus the MediaPipe helper disappeared afterward without a GUI/login reset. That gives future close-sensitive *headless* validation a narrower in-engine stop option than external termination, but it is **not** a substitute for the normal editor `Stop Running Project` path for human-visible Boxing truth work. The proof also exposed that the tracked `flow_proving.tscn` prerecorded fixture path was stale; QA had to provide that missing testbed-only file path locally to reach the live sidecar path at all.
- Narrow cleanup landed immediately afterward: `.testbed/scenes/flow_proving.tscn` now points at the real tracked Flow same-direction fixture `res://assets/fixtures/flow/swings/left-and-right-hands/same-direction/lr3->lr9/flow_swing_lr3->lr9_repeat_04_take_01.mp4` instead of the nonexistent `res://assets/fixtures/flow/left_3_right_3_to_left_6_right_6/flow_swing_left_3_right_3_to_left_6_right_6_x4.mp4`. Minimal revalidation on the tracked scene path was a plain `godot --headless --path .testbed` run with no video override and shutdown only through `.testbed/.headless/quit.request`; that rerun reached `Flow harness live`, started the Python sidecar normally, and exited cleanly with the helper gone afterward, so the temporary local symlink workaround is no longer needed.

---

### Task 3: QA the new straight-punch model against the guarded-left golden-truth fixture

**Bead ID:** `aerobeat-input-mediapipe-python-87v`  
**SubAgent:** `primary`  
**Role:** `qa`  
**References:** `REF-06`, `REF-07`, `REF-08`, `REF-09` plus fresh artifacts from Task 2  
**Prompt:** Independently verify whether the new straight-punch model truthfully improves the guarded-left fixture. Be explicit about authored-window hit counts, false positives, rearm behavior, and whether any apparent gain came from noise rather than better detection.

**Folders Created/Deleted/Modified:**
- `.plans/`

**Files Created/Deleted/Modified:**
- `.plans/2026-05-18-straight-punch-depth-aware-measurement-and-state-design.md`
- `docs/punch-left-golden-truth-experiment-log.html` if a QA note belongs in the shared log

**Status:** ⏳ Pending

**Results:** Pending.

---

### Task 4: Audit whether the new straight-punch model is truthful enough to keep

**Bead ID:** `aerobeat-input-mediapipe-python-bhh`  
**SubAgent:** `primary`  
**Role:** `auditor`  
**References:** all relevant source, plan, log, and fresh artifact references from Tasks 1-3  
**Prompt:** Independently audit the new straight-punch model. Decide whether the kept change truthfully improves Boxing straight-punch detection on the guarded-left fixture without masking new problems, and state whether the result should be kept, retried, or escalated again.

**Folders Created/Deleted/Modified:**
- `.plans/`

**Files Created/Deleted/Modified:**
- `.plans/2026-05-18-straight-punch-depth-aware-measurement-and-state-design.md`
- `docs/punch-left-golden-truth-experiment-log.html` if a final audit note belongs in the shared log

**Status:** ⏳ Pending

**Results:** Pending.

---

## Final Results

**Status:** ⚠️ Interrupted / WIP preserved

**What We Built:**
- A Boxing-only straight-punch design brief grounded in the preserved `boxing_debug` evidence, covering which current measurements remain usable, which ones lie on front-facing forward punches, and what the minimum new per-side state should be before coding.
- A preserved WIP implementation slice across the detector substrate, pose metrics helpers, and proving harness for mirrored left/right depth-aware metrics plus a tiny per-side `armed -> extending -> recovering` straight-punch state.
- A truthful handoff record that the harness-validation pass was interrupted by a host GUI/login reset before results could be completed or trusted.

**Reference Check:**
- `REF-01` and `REF-02` still capture the stop-sign investigation and rejected shortcuts.
- `REF-03` and `REF-04` explain why the current detector conflates extension truth with lateral reach and now also contain the preserved WIP metric/state additions.
- `REF-05` contains the preserved proving-harness debug surface for later resumption.
- `REF-08` and `REF-09` remain the preserved evidence inputs, especially the window peaks and the clip-wide `arm_extension_3d` persistence that invalidated the naive 3D patches.

**Commits:**
- Pending preservation checkpoint commit.

**Lessons Learned:**
- The next truthful fix has to treat depth-aware punch extension, retraction, and side disambiguation as one problem.
- Absolute 3D straightness is useful for fire truth but dishonest for rearm truth.
- Interrupted validation must be recorded explicitly; no authored-window or rerun-success claim is honest until the guarded-left fixture is rerun from a stable host session.
- The fourth authored window is currently less explained than the first three, so the next coding slice should stay narrow and evidence-led rather than promising a blanket 4/4 win up front.

---

*Created on 2026-05-18*
