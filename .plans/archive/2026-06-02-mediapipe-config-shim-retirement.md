# AeroBeat MediaPipe Config Shim Retirement

**Date:** 2026-06-02
**Status:** Complete
**Last Updated:** 2026-06-02 07:29 EDT
**Blocked Reason:** None.
**Agent:** `main`

---

## Goal

Remove or neutralize the remaining `MediaPipeConfig` / `mediapipe_config.gd` compatibility references so `aerobeat-input-camera-tracking` and affected consumers can stay on the neutral camera-tracking contract without hidden legacy path dependence.

---

## Overview

The repo-root `src/` audit passed, but it identified one deliberate legacy bridge: `src/config/mediapipe_config.gd` in `aerobeat-input-camera-tracking`. Derrick has now asked to check whether anything still depends on that bridge and then remove or fix those references. This is a small but cross-repo-sensitive cleanup, because the shim itself lives in `aerobeat-input-camera-tracking` while older references may survive in sibling consumers, testbeds, scenes, or docs.

The work therefore starts with a reference inventory rather than deleting the shim blind. The acceptance bar is precise: either prove the shim is no longer needed and safely retire it, or convert every live code/resource reference to the neutral `camera_tracking_config.gd` / `CameraTrackingConfig` path first and only then remove the shim. Documentation-only references can be updated separately as hygiene and should not block the functional cleanup.

---

## REFERENCES

| ID | Description | Path |
| --- | --- | --- |
| `REF-01` | Repo-root de-MediaPipe audit plan | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.plans/archive/2026-06-02-input-camera-tracking-repo-root-demediapipe-audit.md` |
| `REF-02` | Repo-root de-MediaPipe audit report | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.plans/2026-06-02-input-camera-tracking-repo-root-demediapipe-audit-report.md` |
| `REF-03` | Legacy shim to retire | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/src/config/mediapipe_config.gd` |
| `REF-04` | Neutral source-of-truth config | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/src/config/camera_tracking_config.gd` |
| `REF-05` | Current cross-repo neutral contract spec | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.plans/2026-06-01-cross-repo-demediapipe-neutral-contract.md` |
| `REF-06` | Known sibling consumer currently referencing the legacy shim | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-assembly-community/src/mediapipe_provider_test.gd` |

---

## Tasks

### Task 1: Inventory live `MediaPipeConfig` / `mediapipe_config.gd` references and classify removal risk

**Bead ID:** `aerobeat-input-camera-tracking-lwk`
**SubAgent:** `primary` (for `research` workflow role)
**Role:** `research`
**References:** `REF-01`, `REF-02`, `REF-03`, `REF-04`, `REF-05`, `REF-06`
**Prompt:** In `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking`, audit all live references to `MediaPipeConfig` and `mediapipe_config.gd` across the relevant AeroBeat repos. Classify each hit as code/runtime/resource-critical vs docs-only, identify the owning repo, and state whether the neutral replacement should be `CameraTrackingConfig` / `camera_tracking_config.gd` or a different fix. Recommend whether the shim can be removed immediately or only after specific consumer updates. Claim the bead on start, do not modify application code, and update this plan with exact findings.

**Folders Created/Deleted/Modified:**
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.plans/`
- relevant sibling repos as read-only audit targets

**Files Created/Deleted/Modified:**
- this plan file
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.plans/2026-06-02-mediapipe-config-shim-reference-audit.md`

**Status:** ✅ Complete

**Results:** Inventory completed across AeroBeat repos with live-code, tests-only, and docs/history separation. Exact non-history hits were limited to: (1) the owning-repo compatibility shim at `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/src/config/mediapipe_config.gd`, which remains a live compatibility resource because it still defines `class_name MediaPipeConfig`; and (2) a tests-only sibling consumer at `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-assembly-community/src/mediapipe_provider_test.gd`, which still preloads `res://addons/aerobeat-input-mediapipe/src/config/mediapipe_config.gd`, types `@export var config: MediaPipeConfig`, and instantiates `MediaPipeConfig.new()`. No other non-plan, non-doc, non-temp hits were found under `/home/derrick/.openclaw/workspace/projects/aerobeat`. Neutral replacement for the live/tests-only seam is `camera_tracking_config.gd` / `CameraTrackingConfig` while preserving the current assembly addon mount alias unless that alias changes in a separate slice. Verdict: the shim at `REF-03` is **not removable yet** because the assembly test script in `REF-06` still depends on it. Audit memo written at `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.plans/2026-06-02-mediapipe-config-shim-reference-audit.md`. References validated: `REF-03`, `REF-04`, `REF-05`, `REF-06`.

---

### Task 2: Remove or replace live legacy config references in owning repos

**Bead ID:** `aerobeat-input-camera-tracking-xkg`
**SubAgent:** `primary` (for `coder` workflow role)
**Role:** `coder`
**References:** `REF-03`, `REF-04`, `REF-05`, `REF-06`
**Prompt:** Implement the narrowest truthful fix for every live code/resource dependency on `MediaPipeConfig` / `mediapipe_config.gd`. Prefer converting consumers to the neutral `CameraTrackingConfig` / `camera_tracking_config.gd` path. Only remove the shim once those live references are gone. Update docs-only references opportunistically if they are in touched repos, run repo-local validation in each affected repo, and commit/push by default before handoff.

**Folders Created/Deleted/Modified:**
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-assembly-community/src/`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/src/config/`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.plans/`

**Files Created/Deleted/Modified:**
- removed `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-assembly-community/src/mediapipe_provider_test.gd`
- removed `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-assembly-community/src/mediapipe_provider_test.gd.uid`
- removed `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/src/config/mediapipe_config.gd`
- removed `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/src/config/mediapipe_config.gd.uid`
- modified this plan file

**Status:** ✅ Complete

**Results:** Derrick confirmed `REF-06` was temporary, so the assembly consumer was retired instead of migrated. Removed `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-assembly-community/src/mediapipe_provider_test.gd` plus its `.uid`, then reran `rg -n "mediapipe_config\\.gd|MediaPipeConfig" /home/derrick/.openclaw/workspace/projects/aerobeat --glob '!**/.git/**'`. After those deletions, the only remaining hits under `/home/derrick/.openclaw/workspace/projects/aerobeat` were documentation notes in `aerobeat-ui-kit-community`; no live or tests-only code/resource references remained. That made `REF-03` safe to retire, so `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/src/config/mediapipe_config.gd` plus its `.uid` were removed. Focused validation run: `git diff --check` in both touched repos (passed in `aerobeat-assembly-community`; in `aerobeat-input-camera-tracking` it surfaced only pre-existing trailing whitespace in unrelated `.plans/2026-06-01-vendor-import-webcam-replay-2d-skeleton-truth.md`), plus post-change `rg` scans in both touched repos and the top-level AeroBeat workspace confirming no live/test hits remain. References validated: `REF-03`, `REF-06`. Shim removed: yes.

---

### Task 3: QA the shim-retirement slice

**Bead ID:** `aerobeat-input-camera-tracking-eoe`
**SubAgent:** `primary` (for `qa` workflow role)
**Role:** `qa`
**References:** `REF-03`, `REF-04`, `REF-06`
**Prompt:** Verify that the legacy config shim was either safely removed or correctly retained only where still justified, and that affected consumers now use the neutral camera-tracking config path without regression. Run focused validation in each touched repo and document exact evidence.

**Folders Created/Deleted/Modified:**
- validation artifacts as needed

**Files Created/Deleted/Modified:**
- none expected unless a minimal validation note is justified

**Status:** ❌ Failed

**Results:** QA reran focused hygiene and reference checks across both relevant repos and found that the slice is **not yet truthful as written**. The direct temporary assembly script removal was real (`/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-assembly-community/src/mediapipe_provider_test.gd` and `.uid` are no longer tracked) and the owning-repo shim deletion was also real (`/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/src/config/mediapipe_config.gd` and `.uid` are no longer tracked). However, a code/resource-only search excluding `.plans` still found remaining `mediapipe_config.gd` / `MediaPipeConfig` hits in the assembly repo’s **ignored but live restored addon copies** under `addons/aerobeat-input-mediapipe/` and `.addons/aerobeat-input-mediapipe/`. Key remaining hits include: `addons/aerobeat-input-mediapipe/src/config/mediapipe_config.gd:1`, `addons/aerobeat-input-mediapipe/src/input_provider.gd:569`, `addons/aerobeat-input-mediapipe/src/AeroCameraTracking.gd:13`, `addons/aerobeat-input-mediapipe/src/providers/camera_tracking_provider.gd:360`, `addons/aerobeat-input-mediapipe/src/providers/mediapipe_provider.gd:412`, `addons/aerobeat-input-mediapipe/src/mediapipe_input_with_camera.gd:167,174`, plus tests/proving files under `addons/aerobeat-input-mediapipe/.testbed/...`; the same families also remain under `.addons/aerobeat-input-mediapipe/...`. `git check-ignore -v` confirmed these paths are ignored by assembly-community (`addons/*` and `.addons/`), but `addons.jsonc` still declares the live assembly dependency key `aerobeat-input-mediapipe` from `git@github.com:AeroBeat-Workouts/aerobeat-input-camera-tracking.git`, so these are not just markdown/docs history. Validation run: `git status --short`, `git diff --check`, `git ls-files --error-unmatch` on the deleted shim/test files, repo-local `rg -n 'mediapipe_config\.gd|MediaPipeConfig'` scans, a non-`.plans` Python content sweep across both repos, `git check-ignore -v` on the remaining addon hits, and spot-check reads of `aerobeat-assembly-community/addons.jsonc` plus remaining addon source files. Verdict: the narrow deletions themselves were real, but the broader claim that no live/tests-only code references remain across the relevant repos is currently false until the assembly repo’s restored addon surfaces are refreshed/realigned or explicitly scoped out.

---

### Task 4: Refresh assembly addon state via `godotenv-sync` after shim retirement

**Bead ID:** `aerobeat-input-camera-tracking-j57`
**SubAgent:** `primary` (for `coder` workflow role)
**Role:** `coder`
**References:** `REF-03`, `REF-04`, `REF-05`, `REF-06`
**Prompt:** In `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-assembly-community`, refresh the restored addon/dependency state with the approved `godotenv-sync` flow so the consumer worktree stops carrying stale `mediapipe_config.gd` / `MediaPipeConfig` payloads from the old addon snapshot. Do not patch `addons/` or `.addons/` mirrors by hand and do not use raw GodotEnv CLI mutation as the repair path. After refresh, rerun the focused `mediapipe_config\.gd|MediaPipeConfig` search and document whether the restored assembly dependency surface now matches the retired shim state. Commit/push only repo-owned changes if any durable repo-owned files change; do not fabricate source edits inside generated addon mirrors.

**Folders Created/Deleted/Modified:**
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-assembly-community/`
- generated addon/dependency surfaces refreshed via `godotenv-sync`

**Files Created/Deleted/Modified:**
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.plans/2026-06-02-mediapipe-config-shim-retirement.md`

**Status:** ✅ Complete

**Results:** Ran the approved refresh path exactly as `/home/derrick/.openclaw/workspace/scripts/godotenv-sync --repo /home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-assembly-community` from the assembly repo. `godotenv-sync` completed successfully with exit 0 and reported `scrub-uids: 106 untracked removed/selected, 56 tracked kept`, `restore-deleted-tracked-uids: restored 106 file(s) across 15 nested repo(s)`, and `install: ok`. After the refresh, reran `rg -n "mediapipe_config\\.gd|MediaPipeConfig" . --glob '!**/.git/**'` in `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-assembly-community`; it returned no matches, so the stale restored addon surfaces no longer carry those legacy hits. `git status --short` in the assembly repo remained clean, so no durable repo-owned files changed there. This unblocks a truthful QA rerun against the refreshed assembly dependency surface.

---

### Task 5: Re-QA shim retirement after `godotenv-sync` refresh

**Bead ID:** `aerobeat-input-camera-tracking-t59`
**SubAgent:** `primary` (for `qa` workflow role)
**Role:** `qa`
**References:** `REF-03`, `REF-04`, `REF-05`, `REF-06`
**Prompt:** Re-run the shim-retirement QA after the assembly dependency surfaces have been refreshed with `godotenv-sync`. Verify whether any remaining `mediapipe_config.gd` / `MediaPipeConfig` hits are still live/tests-only dependency truth or have been reduced to docs/history only. Use focused searches, safe repo-local validation, and exact evidence. Do not modify application code.

**Folders Created/Deleted/Modified:**
- validation-only surfaces as needed

**Files Created/Deleted/Modified:**
- plan updates only unless a minimal QA note is justified

**Status:** ❌ Failed

**Results:** QA reran the post-`godotenv-sync` sweep and the slice is still **not safe to pass**. The earlier assembly rerun in Task 4 used a default `rg` that skipped ignored/hidden addon mirrors, so it missed remaining generated dependency truth under `addons/` and `.addons/`. Focused safe validation on 2026-06-02 consisted of: `git status --short` and `git diff --check` in both relevant repos; `rg -n "mediapipe_config\\.gd|MediaPipeConfig" . --glob '!**/.git/**'` in each repo; `find . \( -path '*/.git/*' -o -path '*/.git' \) -prune -o \( -name 'mediapipe_config.gd' -o -name 'mediapipe_config.gd.uid' \) -print` in `aerobeat-assembly-community`; `rg -uu -n "mediapipe_config\\.gd|MediaPipeConfig" .` in both repos; and `git check-ignore -v addons/aerobeat-input-mediapipe/src/config/mediapipe_config.gd .addons/aerobeat-input-mediapipe/src/config/mediapipe_config.gd` in `aerobeat-assembly-community`.

Exact remaining **live/tests-only** hits are all in the assembly repo’s generated addon mirrors for dependency `aerobeat-input-mediapipe` and are therefore still runtime/test surfaces rather than docs/history only. Primary live source hits:
- `aerobeat-assembly-community/addons/aerobeat-input-mediapipe/src/config/mediapipe_config.gd:1`
- `aerobeat-assembly-community/addons/aerobeat-input-mediapipe/src/input_provider.gd:569`
- `aerobeat-assembly-community/addons/aerobeat-input-mediapipe/src/AeroCameraTracking.gd:13`
- `aerobeat-assembly-community/addons/aerobeat-input-mediapipe/src/providers/camera_tracking_provider.gd:360`
- `aerobeat-assembly-community/addons/aerobeat-input-mediapipe/src/providers/mediapipe_provider.gd:412`
- `aerobeat-assembly-community/addons/aerobeat-input-mediapipe/src/mediapipe_input_with_camera.gd:167,174`

Exact remaining **tests/proving** hits in that same generated dependency surface:
- `aerobeat-assembly-community/addons/aerobeat-input-mediapipe/.testbed/tests/mediapipe_provider_test.gd:8,20,38`
- `aerobeat-assembly-community/addons/aerobeat-input-mediapipe/.testbed/tests/unit/test_mediapipe_process.gd:4,7,11`
- `aerobeat-assembly-community/addons/aerobeat-input-mediapipe/.testbed/tests/unit/test_mediapipe_provider_camera_switch_reset.gd:4,11`
- `aerobeat-assembly-community/addons/aerobeat-input-mediapipe/.testbed/tests/unit/test_mediapipe_server.gd:4,7,10`
- `aerobeat-assembly-community/addons/aerobeat-input-mediapipe/.testbed/tests/unit/test_pose_detector_substrate.gd:4,8,11`
- `aerobeat-assembly-community/addons/aerobeat-input-mediapipe/.testbed/tests/test_mediapipe_logic.gd:45,92`
- `aerobeat-assembly-community/addons/aerobeat-input-mediapipe/.testbed/scripts/mediapipe_provider_test.gd:5,17,34`
- `aerobeat-assembly-community/addons/aerobeat-input-mediapipe/.testbed/scripts/proving_harness.gd:6,881`

The same families are duplicated under `.addons/aerobeat-input-mediapipe/...`; `git check-ignore -v` confirmed both mirror roots are ignored by assembly-community (`addons/*` and `.addons/`), but they are still present on disk as generated dependency surfaces. Non-blocking history/cache/log hits also remain in `.plans/`, `.qa-logs/`, `.godot/`, and `.testbed/.godot/`, but those are not the reason for failure. `aerobeat-input-camera-tracking` itself no longer has live repo-source hits; its remaining matches are plan/bead history only. Verdict: **FAIL** for the QA rerun, and the slice is **not yet safe for final audit** until the generated dependency surface mounted in assembly is actually refreshed to a version that no longer carries `mediapipe_config.gd` / `MediaPipeConfig`, or the scope is explicitly narrowed.
---

### Task 6: Audit why assembly dependency refresh still regenerates the old addon payload

**Bead ID:** `aerobeat-input-camera-tracking-f5k`
**SubAgent:** `primary` (for `research` workflow role)
**Role:** `research`
**References:** `REF-03`, `REF-04`, `REF-05`, `REF-06`
**Prompt:** Audit why `aerobeat-assembly-community` still materializes generated addon surfaces under `addons/aerobeat-input-mediapipe/` and `.addons/aerobeat-input-mediapipe/` that contain `mediapipe_config.gd` / `MediaPipeConfig` after the approved `godotenv-sync` refresh. Focus on dependency declaration/alias mapping, restore/install behavior, nested repo source selection, and whether the consumer is correctly pulling the updated `aerobeat-input-camera-tracking` source or an older addon identity snapshot. Do not patch generated addon mirrors as source. Produce a concise evidence-backed diagnosis and name the narrowest next implementation seam.

**Folders Created/Deleted/Modified:**
- `.plans/`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-assembly-community/` (read-only audit target)

**Files Created/Deleted/Modified:**
- this plan file
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.plans/2026-06-02-assembly-mediapipe-regeneration-audit.md`

**Status:** ✅ Complete

**Results:** Audit completed. Root cause is **stale consumer source selection**, not merely alias naming. Exact dependency declaration in `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-assembly-community/addons.jsonc` still installs addon key `aerobeat-input-mediapipe` from repo `git@github.com:AeroBeat-Workouts/aerobeat-input-camera-tracking.git` at pinned checkout `5bbdf2575c31eab03ea528f4826c1d159f47a1fe` with `subfolder: "/"`. That pinned commit still contains `src/config/mediapipe_config.gd` plus compat references (`git show --stat --oneline --no-patch 5bbdf2575c31eab03ea528f4826c1d159f47a1fe`; `git ls-tree -r --name-only 5bbdf2575c31eab03ea528f4826c1d159f47a1fe | rg 'mediapipe_config\.gd|camera_tracking_config\.gd|input_provider\.gd|AeroCameraTracking\.gd'`). By contrast, the current source repo HEAD in `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking` is `4f63ccd2d131d4192e9675fd6a78572780a7ec0f` (`Retire MediaPipe config shim`), which no longer carries `src/config/mediapipe_config.gd`. In the assembly repo, the generated cache `.addons/aerobeat-input-mediapipe` is indeed checked out at the old pinned commit (`git -C .addons/aerobeat-input-mediapipe rev-parse HEAD` => `5bbdf2575c31eab03ea528f4826c1d159f47a1fe`; remote points at the renamed repo), and `rg -n 'mediapipe_config\.gd|class_name MediaPipeConfig|MediaPipeConfig'` there still shows the legacy files. The installed `addons/aerobeat-input-mediapipe` mirror is then regenerated from that stale payload and is not source of truth; its local nested git state is just a generated install artifact (`git -C addons/aerobeat-input-mediapipe log --oneline -1` => `577ec77 "Initial commit"`). Relevant restore/install behavior from `/home/derrick/.openclaw/workspace/scripts/godotenv-sync`: default path is `--scrub-uids --install`; cache clearing only happens when `--refresh-caches` is explicitly requested. Even so, refresh-caching alone would not fix the problem because the manifest still pins the old shim-bearing checkout. Narrowest next seam: update only the assembly consumer manifest pin in `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-assembly-community/addons.jsonc` to a commit/tag at or after `4f63ccd2d131d4192e9675fd6a78572780a7ec0f` while keeping the install alias key `aerobeat-input-mediapipe` if consumer paths still need it, then rerun `/home/derrick/.openclaw/workspace/scripts/godotenv-sync --repo /home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-assembly-community --refresh-caches --install` and re-QA with `rg -uu -n 'mediapipe_config\.gd|MediaPipeConfig'`. Audit memo written at `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.plans/2026-06-02-assembly-mediapipe-regeneration-audit.md`. References validated: `REF-03`, `REF-04`, `REF-05`.

---

### Task 7: Update assembly addon pin past shim retirement and refresh caches

**Bead ID:** `aerobeat-input-camera-tracking-1is`
**SubAgent:** `primary` (for `coder` workflow role)
**Role:** `coder`
**References:** `REF-03`, `REF-04`, `REF-05`, `REF-06`
**Prompt:** Update `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-assembly-community/addons.jsonc` so the `aerobeat-input-mediapipe` dependency pin points to a commit at or after `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking` commit `4f63ccd2d131d4192e9675fd6a78572780a7ec0f` (`Retire MediaPipe config shim`). Keep the alias key if consumer mount-path assumptions still depend on it. After updating the pin, run `/home/derrick/.openclaw/workspace/scripts/godotenv-sync --repo /home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-assembly-community --refresh-caches --install`, then rerun focused `rg -uu -n 'mediapipe_config\.gd|MediaPipeConfig'` validation in the assembly repo. Do not patch generated addon mirrors as source. Commit/push repo-owned changes by default and update this plan with exact command, validation, and commit hashes.

**Folders Created/Deleted/Modified:**
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-assembly-community/`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.plans/`

**Files Created/Deleted/Modified:**
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-assembly-community/addons.jsonc`
- plan updates as needed

**Status:** ✅ Complete

**Results:** Updated `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-assembly-community/addons.jsonc` so alias key `aerobeat-input-mediapipe` still points at `git@github.com:AeroBeat-Workouts/aerobeat-input-camera-tracking.git` but now checks out commit `4f63ccd2d131d4192e9675fd6a78572780a7ec0f` (`Retire MediaPipe config shim`) instead of stale commit `5bbdf2575c31eab03ea528f4826c1d159f47a1fe`. Ran the approved refresh exactly as `/home/derrick/.openclaw/workspace/scripts/godotenv-sync --repo /home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-assembly-community --refresh-caches --install`; it completed with exit 0 and reported `godotenv-sync: 1 project root(s)`, `actions: refresh-caches, install`, `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-assembly-community: ok`, `refresh-caches: 15 entries`, `restore-deleted-tracked-uids: restored 0 file(s) across 15 nested repo(s)`, and `install: ok`. Then reran the required focused validation exactly as `rg -uu -n 'mediapipe_config\.gd|MediaPipeConfig' /home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-assembly-community`. Remaining hits were reduced to history/log/cache surfaces only: assembly `.qa-logs/*`, assembly `.godot/global_script_class_cache.cfg`, assembly `.godot/editor/filesystem_cache10`, and plan/history files under generated addon mirrors at `addons/aerobeat-input-mediapipe/.plans/**` and `.addons/aerobeat-input-mediapipe/.plans/**`; there were no remaining live addon-source hits under `addons/aerobeat-input-mediapipe/src/**` or `.addons/aerobeat-input-mediapipe/src/**`. This makes the slice ready for the planned QA rerun in Task 8.

---

### Task 8: Re-QA assembly pin update after cache refresh

**Bead ID:** `aerobeat-input-camera-tracking-955`
**SubAgent:** `primary` (for `qa` workflow role)
**Role:** `qa`
**References:** `REF-03`, `REF-04`, `REF-05`, `REF-06`
**Prompt:** Re-run the shim-retirement QA after the assembly consumer pin has been updated and `godotenv-sync --refresh-caches --install` has refreshed the generated dependency surface. Verify whether any remaining `mediapipe_config.gd` / `MediaPipeConfig` hits are still live/tests-only dependency truth or have been reduced to docs/history only. Use focused `rg -uu` searches and safe repo-local validation, and document exact evidence.

**Folders Created/Deleted/Modified:**
- validation-only surfaces as needed

**Files Created/Deleted/Modified:**
- plan updates only unless a minimal QA note is justified

**Status:** ✅ Complete

**Results:** QA reran the approved post-pin, post-cache-refresh validation and the slice now **passes** for the requested seam. Safe repo-local validation on 2026-06-02 consisted of, in both `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-assembly-community` and `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking`: `git status --short`; `git diff --check`; and `rg -uu -n 'mediapipe_config\.gd|MediaPipeConfig' .`. In `aerobeat-assembly-community`, `git status --short` and `git diff --check` were clean. The focused `rg -uu` hits were reduced to non-live surfaces only: `.plans/**` history (including generated dependency mirror `.plans/**` content under both `addons/aerobeat-input-mediapipe/.plans/**` and `.addons/aerobeat-input-mediapipe/.plans/**`), `.qa-logs/task1-runtime.log`, `.qa-logs/task3-runtime.log`, `.qa-logs/task4-runtime.log`, `.qa-logs/oc-dx7-export.log`, `.qa-logs/oc-t29-export.log`, `.qa-logs/oc-wsm-headless-import.log`, plus cache/index files `.godot/global_script_class_cache.cfg` and `.godot/editor/filesystem_cache10`. Crucially, there were **no** remaining live/tests-only hits under `addons/aerobeat-input-mediapipe/src/**`, `.addons/aerobeat-input-mediapipe/src/**`, `addons/aerobeat-input-mediapipe/.testbed/**`, or `.addons/aerobeat-input-mediapipe/.testbed/**`. In `aerobeat-input-camera-tracking`, `rg -uu` hits were likewise limited to `.plans/**`, `.beads/interactions.jsonl`, and `.testbed/.godot/**` cache/history surfaces; there were no live repo-source hits under `src/**`. `git status --short` there showed only pre-existing unrelated plan/worktree noise plus untracked planning artifacts, and `git diff --check` only repeated the pre-existing trailing-whitespace issue in unrelated `.plans/2026-06-01-vendor-import-webcam-replay-2d-skeleton-truth.md`. Verdict: remaining hits are now history/log/cache/doc surfaces only, not live/tests-only dependency truth, so the shim-retirement slice is **safe for final audit**. References revalidated: `REF-03`, `REF-04`, `REF-05`, `REF-06`.

---

### Task 9: Independently audit final truthfulness of shim retirement

**Bead ID:** `aerobeat-input-camera-tracking-tfe`
**SubAgent:** `primary` (for `auditor` workflow role)
**Role:** `auditor`
**References:** `REF-03`, `REF-04`, `REF-05`, `REF-06`
**Prompt:** Independently verify that the final shim-retirement state is truthful after the assembly pin update, cache refresh, and QA rerun: no hidden live/tests-only dependency still relies on `mediapipe_config.gd` / `MediaPipeConfig`, neutral replacements are correct, and no generated addon mirror was treated as source. Produce a concise evidence-backed audit.

**Folders Created/Deleted/Modified:**
- `.plans/`

**Files Created/Deleted/Modified:**
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.plans/2026-06-02-mediapipe-config-shim-final-audit.md`
- this plan file

**Status:** ✅ Complete

**Results:** Independent final audit passed. I rechecked both target repos with focused repo-local evidence rather than trusting earlier claims: in `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-assembly-community`, `addons.jsonc` now keeps the compatibility alias key `aerobeat-input-mediapipe` but pins the renamed source repo `git@github.com:AeroBeat-Workouts/aerobeat-input-camera-tracking.git` to checkout `4f63ccd2d131d4192e9675fd6a78572780a7ec0f`, and `.addons/aerobeat-input-mediapipe` resolves to that same commit. In `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking`, `src/config/mediapipe_config.gd` and its `.uid` are truly gone while active source references now point at `src/config/camera_tracking_config.gd` from `src/input_provider.gd`, `src/providers/camera_tracking_provider.gd`, `src/AeroCameraTracking.gd`, `.testbed/scripts/proving_harness.gd`, and `.testbed/tests/unit/test_pose_detector_substrate.gd`. Fresh `rg -uu -n 'mediapipe_config\.gd|MediaPipeConfig'` sweeps across both repos reduced remaining hits to history/log/cache/index surfaces only: `.plans/**`, `.qa-logs/**`, `.godot/**`, `.testbed/.godot/**`, and `.beads/interactions.jsonl`; there were no remaining live/tests-only hits under `src/**`, `addons/aerobeat-input-mediapipe/src/**`, `.addons/aerobeat-input-mediapipe/src/**`, or either generated mirror’s `.testbed/**`. This confirms the neutral replacement state is correct and that the generated addon mirrors were audited as install/cache artifacts rather than treated as source. Final audit memo written at `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.plans/2026-06-02-mediapipe-config-shim-final-audit.md`. References revalidated: `REF-03`, `REF-04`, `REF-05`, `REF-06`.

---

## Final Results

**Status:** ✅ Complete

**What We Built:** Truthfully retired the repo-source `MediaPipeConfig` shim from `aerobeat-input-camera-tracking`, removed the temporary assembly test consumer that still referenced it, diagnosed and corrected the stale assembly dependency pin, refreshed generated addon/cache surfaces with `godotenv-sync --refresh-caches --install`, and independently verified that the final live state now relies on the neutral `camera_tracking_config.gd` / `CameraTrackingConfig` contract instead of the legacy shim.

**Reference Check:** `REF-03`, `REF-04`, `REF-05`, and `REF-06` were all revalidated. `REF-03` is now absent from repo source as intended; active source references point to `REF-04`; the assembly consumer still uses the compatibility mount alias documented by `REF-05` but now pulls a post-shim-retirement commit; and the temporary sibling consumer from `REF-06` is gone. Remaining `mediapipe_config.gd` / `MediaPipeConfig` hits are limited to plan history, logs, and Godot caches, not live/tests-only dependency truth.

**Commits:**
- No new commit in this audit pass; only plan/audit documentation changed in the coordination repo worktree.

**Lessons Learned:** For GodotEnv-managed consumers, a clean local source repo is not enough. Final truth depends on the consumer manifest pin and regenerated install/cache surfaces matching that source. Hidden/ignored addon mirrors must be audited with `rg -uu` when validating retirement of old resource/class paths, but they must never be patched as if they were source.

---

*Completed on 2026-06-02*
