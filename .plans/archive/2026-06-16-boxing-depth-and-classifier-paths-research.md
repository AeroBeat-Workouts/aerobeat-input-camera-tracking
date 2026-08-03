# AeroBeat Boxing Depth and Classifier Paths Research

**Date:** 2026-06-16
**Status:** Stale
**Last Updated:** 2026-06-16 13:39 EDT
**Blocked Reason:** None.

**Stale Archive Note:** Marked stale and archived on 2026-08-03 during Byte workspace cleanup; newer AeroBeat work remains with Pico.
**Agent:** `pico`

---

## Goal

Research the best next-path options for straight-punch detection after prototype matching failed, with special focus on monocular depth approaches for wrist-forward depth estimation and how they compare to classifier-training and pose-threshold-only paths.

---

## Overview

The latest audited prototype-matcher branch improved straight-punch results slightly but still failed strategically because run-in-place remained a strong false-positive source and left/right separation stayed too noisy. Derrick has now narrowed the decision space to three practical branches: continue with pose-only threshold tuning and accept its limitations, train a supervised classifier from recorded boxing videos plus exported pose/truth labels, or add a lightweight monocular depth estimator aimed specifically at recovering usable forward wrist-depth motion for straight punches.

This plan should produce a decision-quality comparison rather than vague brainstorming. The research needs to compare FastDepth / HoloFastDepth against other monocular depth candidates in the context that actually matters here: low-end-device viability, rapid-motion robustness, integration complexity, expected latency, whether depth can be localized strongly enough around the wrist/hand region, and whether the result would likely outperform the current pose-only threshold system enough to justify the engineering cost.

Derrick clarified an important product constraint before execution: co-firing can still be acceptable if the game is designed around it, but depth would be especially valuable if it enables athletes to throw rapid same-side straight punches in succession more reliably. Current pose-threshold straight detection mostly works at a rough ~75% level, but its visible weakness is rapid same-side straights. By contrast, current hook and uppercut failures are not expected to be solved by depth alone; those gestures likely need a re-examination or replacement of their current threshold logic. The research should therefore explicitly separate:
- whether monocular depth is a worthwhile straight-punch booster,
- whether classifier training is a better all-around replacement path,
- and whether hook/uppercut quality likely demands a different detector redesign regardless of straight-punch depth improvements.

The output should explicitly separate “good research-paper depth” from “good-enough real-time wrist-depth signal for AeroBeat.” It should also compare that monocular-depth path against the classifier path and the threshold-only path in terms of implementation risk, data requirements, runtime cost, and likelihood of yielding a materially better straight-punch detector.

---

## REFERENCES

| ID | Description | Path |
| --- | --- | --- |
| `REF-01` | Threshold-inspired straight prototype plan/result | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.plans/2026-06-16-prototype-matcher-threshold-inspired-straight-features.md` |
| `REF-02` | Medium article Derrick cited | `https://medium.com/xrpractices/monocular-depth-sensing-point-cloud-from-webcam-feed-using-unity-barracuda-d9f1496b5932` |
| `REF-03` | HoloFastDepth repo Derrick cited | `https://github.com/miso3/HoloFastDepth` |
| `REF-04` | Current straight-punch threshold concepts | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/assets/boxing.gesture_detection.yaml` |
| `REF-05` | Current pose substrate / available measurements | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/src/detectors/pose_detector_substrate.gd` |
| `REF-06` | Durable prior finding: pose-only wrist depth is weak, elbow motion helped more | `memory/2026-06-06.md#L19-L28` |
| `REF-07` | Durable prior gameplay tolerance: co-firing/noise can be acceptable if beat hits are reliable | `memory/2026-06-08.md#L6-L9` |

---

## Tasks

### Task 1: Research the three decision paths and produce a comparison brief

**Bead ID:** `aerobeat-input-camera-tracking-fslt`
**SubAgent:** `primary` (for `research`)
**Role:** `research`
**References:** `REF-01`, `REF-02`, `REF-03`, `REF-04`, `REF-05`, `REF-06`, `REF-07`
**Prompt:** Compare the three next-path options for AeroBeat straight-punch detection: (1) stay pose-threshold-only and keep tuning, (2) train a supervised classifier from recorded boxing videos + exported pose + truth YAMLs, and (3) add a lightweight monocular depth estimator primarily to recover wrist forward-depth motion for straight punches. Research FastDepth / HoloFastDepth versus other realistic monocular depth options, especially for low-end-device real-time use. Focus on runtime cost, integration complexity, motion robustness, wrist-local depth usefulness, expected false-positive/false-negative impact, and likely engineering ROI. Produce a decision brief with a ranked recommendation and explicit tradeoffs.

**Folders Created/Deleted/Modified:**
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.plans/`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/docs/`

**Files Created/Deleted/Modified:**
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/docs/reviews/boxing-depth-vs-classifier-decision-brief-2026-06-16.md`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.plans/2026-06-16-boxing-depth-and-classifier-paths-research.md`

**Status:** ✅ Complete

**Results:** Wrote the decision brief at `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/docs/reviews/boxing-depth-vs-classifier-decision-brief-2026-06-16.md` after grounding it in the current threshold detector config/runtime (`REF-04`/`REF-05`), the recent straight-only prototype dead-end (`REF-01`), the repo's existing boxing fixtures and truth-window YAMLs, and the cited monocular-depth references (`REF-02`/`REF-03`) plus realistic comparison points (FastDepth, MiDaS mobile/small variants, Depth Anything V2 Small). The brief makes a concrete ranked recommendation: **(1) pursue a small supervised pose-sequence classifier next, (2) keep threshold-only tuning as the short-term maintenance baseline, (3) treat monocular depth as later optional R&D rather than the next mainline branch.**

The main decision logic captured in the brief is: monocular depth is technically plausible on low-end hardware, especially with FastDepth-class models, but its likely AeroBeat value is only as a noisy auxiliary straight-punch feature and not a strong primary answer for rapid same-side straights, side ownership, or hook/uppercut quality. By contrast, a pose-sequence classifier better matches the repo's current assets — recorded boxing fixtures, YAML truth windows, and rich per-frame capture reports — while also offering a believable path to improve straights, hooks, and uppercuts under one reusable modeling approach.

---

### Task 2: QA the research brief for factual support and decision usefulness

**Bead ID:** `aerobeat-input-camera-tracking-uhl9`
**SubAgent:** `primary` (for `qa`)
**Role:** `qa`
**References:** `REF-01`, `REF-02`, `REF-03`, `REF-04`, `REF-05`, `REF-06`, `REF-07`
**Prompt:** Verify that the research brief accurately represents the current AeroBeat detector state, faithfully summarizes the cited monocular depth options and alternatives, and gives Derrick a useful decision-quality comparison rather than generic pros/cons. Check that major claims are supported and that the recommendation matches the evidence.

**Folders Created/Deleted/Modified:**
- relevant owning repo paths

**Files Created/Deleted/Modified:**
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.plans/2026-06-16-boxing-depth-and-classifier-paths-research.md`

**Status:** ✅ Complete

**Results:** QA reviewed the brief against the current repo state, the committed prototype-matcher review packet, the active threshold-detector config/runtime, and the cited external monocular-depth options. Verdict: the brief is **decision-useful and mostly support-wise solid**, and its ranked recommendation still holds: classifier first, threshold-only as the short-term baseline, monocular depth later as optional R&D.

What checked out:
- The brief accurately treats the **prototype matcher as a dead end for the next straight-punch branch**. That conclusion is well supported by `REF-01` and its linked review packet: even after the threshold-inspired feature pass, positive-fixture totals improved only modestly while left/right cross-fire and negative-control hallucinations remained materially unsafe.
- The brief accurately reflects the **current main detector architecture** as threshold-gate based, not prototype-matcher based. `REF-04`/`REF-05` still show `punch_detection.backend: threshold_gates`, with prototype matcher available as an alternate subsystem rather than the active shipping path.
- The monocular-depth section is fair in direction. The cited options do support the brief’s broad claims that lightweight monocular depth is technically plausible on constrained hardware (FastDepth/HoloFastDepth, MiDaS small/mobile variants), while newer general-purpose models like Depth Anything V2 Small are materially larger / heavier. The brief also makes the right product distinction between "convincing depth map" and "stable wrist-local rapid-punch depth truth," which the cited sources do **not** directly prove.
- The recommendation is decision-useful rather than generic: it explicitly maps the repo’s existing fixtures, YAML truth windows, and capture/report tooling to a small pose-sequence classifier path, and it correctly notes that this path has broader upside for hooks/uppercuts than monocular depth alone.

Important QA caveats for the orchestrator/auditor:
- One sentence in the brief is slightly stale / under-supported against current HEAD: it says the 2026-06-12 forward-depth-spike experiment "added a narrow z-spike gate." In the current repo state, the straight-punch runtime still computes and surfaces `forward_depth_spike`, but the active trigger path in `REF-05` does **not** currently gate straight-punch firing on a public `min_forward_depth_spike` threshold. So the historical experiment may have done that at one point, but the brief should not be read as describing the current live trigger logic.
- The brief’s "current straight detection is already somewhat usable" / rough `~75%` framing is plan-context-credible, but it is not strongly demonstrated inside the brief itself with a repo-local benchmark citation. That weakens confidence slightly, but not enough to overturn the recommendation.
- The main missing assumption worth keeping explicit: a pose-sequence classifier only wins cleanly if the pose tracker remains stable enough across Derrick’s real camera/framing conditions. The brief implies this, but does not foreground it as a first-order dependency.

Net QA conclusion: keep the recommendation, but carry forward the caveat that the depth-spike paragraph is partly historical/stale relative to current HEAD and that the current-straights-usability claim could use a harder repo-local citation if this brief becomes a longer-lived decision artifact.

---

### Task 3: Audit the recommendation and decide whether to execute the chosen branch next

**Bead ID:** `aerobeat-input-camera-tracking-illg`
**SubAgent:** `primary` (for `auditor`)
**Role:** `auditor`
**References:** `REF-01`, `REF-02`, `REF-03`, `REF-04`, `REF-05`, `REF-06`, `REF-07`
**Prompt:** Independently audit the research brief and recommendation. Confirm whether the evidence supports the proposed next path for AeroBeat straight-punch detection, and call out any hidden costs, missing assumptions, or overconfidence. If the brief is strong enough, recommend whether Derrick should execute the selected branch next.

**Folders Created/Deleted/Modified:**
- relevant owning repo paths

**Files Created/Deleted/Modified:**
- audit notes/artifacts as needed

**Status:** ✅ Complete

**Results:** Independent audit agrees with the research brief's ranked direction, but with stricter framing than the brief currently uses. The repo evidence strongly supports **not** choosing another prototype-matcher pass and **not** choosing monocular depth as the next mainline branch. `REF-01` shows the latest alternative detector path still fails strategically: even after the threshold-inspired feature pass, positive totals improved only modestly while left/right cross-fire and run-in-place false positives remained unacceptable. `REF-04`/`REF-05` show the live system is still a threshold-gate detector with explicit straight/hook/uppercut heuristics, which means the current architecture is cheap and debuggable but still fundamentally hand-authored.

The brief's core monocular-depth conclusion holds up: lightweight monocular depth is plausible on constrained hardware, but nothing in the cited material or current repo evidence shows that dense relative depth would become a trustworthy **wrist-local, low-latency, repeatable** truth signal for AeroBeat's actual pain point — rapid same-side straights with clean rearm/side separation. The current runtime still computes and surfaces `forward_depth_spike`, but current HEAD no longer publicly gates straight firing on `min_forward_depth_spike`; that makes one sentence in the brief historically stale, not directionally wrong. The more important audit point is strategic: even if depth works somewhat for straights, it still has weak expected payoff for hooks/uppercuts and adds a whole new dense-vision subsystem just to maybe contribute one more noisy feature.

Audit recommendation: **execute the classifier path next, but only as a disciplined pose-sequence classifier feasibility slice, not a vague "do ML" branch.** The recommendation is strong enough to proceed because the repo already has the right seed assets for that path — verified boxing fixture videos, YAML truth windows, and capture/report tooling that can be repurposed into dataset export/evaluation — and because a small temporal pose classifier is the only listed option that plausibly improves straights while also opening a reusable path for hooks/uppercuts. However, Derrick should treat the following as prerequisites/risks, not footnotes: (1) prove pose stability is good enough under the real camera/framing conditions to support supervised learning, (2) build a reproducible window export + train/validation split + baseline-comparison harness before trusting any classifier win, (3) include hard negatives / transitions / same-side repeat cases explicitly so the model does not simply memorize the tiny fixture set, and (4) keep the current threshold detector as the live fallback and comparison baseline during rollout. With those caveats, QA's conclusion holds up and the brief is strong enough to recommend classifier-first next.

---

## Final Results

**Status:** ✅ Complete

**What We Built:** A decision-quality research packet comparing threshold-only tuning, pose-sequence classifier training, and monocular depth for AeroBeat boxing detection, followed by QA and independent audit. Final recommendation: pursue a small supervised pose-sequence classifier next; keep the current threshold detector as the maintenance/shipping fallback; treat monocular depth as later optional R&D or as a possible future auxiliary feature only.

**Reference Check:** `REF-01`, `REF-04`, and `REF-05` were checked directly in audit against current HEAD, and the monocular-depth recommendation was cross-checked against the brief's cited external sources (`REF-02`/`REF-03`) plus the repo's recent threshold/prototype history. Deliberate caveat carried forward: the brief's sentence about the 2026-06-12 depth-spike gate is slightly stale versus current HEAD, and the rough "current straights are somewhat usable / ~75%" framing remains lightly repo-cited rather than hard-benchmarked in this artifact.

**Commits:**
- `b8470b7` - Add boxing detector path decision brief

**Lessons Learned:** The important split is not "classic rules vs ML" in the abstract; it is whether the next branch directly attacks AeroBeat's real failure mode. Here, monocular depth is plausible but narrow, while a pose-sequence classifier better matches the existing repo assets and is the only option on the table with believable upside for straights plus hooks/uppercuts — provided the work starts with disciplined export/eval infrastructure rather than a hand-wavy training pass.
