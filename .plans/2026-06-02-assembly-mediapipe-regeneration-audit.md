# Assembly MediaPipe Regeneration Audit

**Date:** 2026-06-02 06:55 EDT
**Scope:** Why `aerobeat-assembly-community` still regenerates `addons/aerobeat-input-mediapipe/` and `.addons/aerobeat-input-mediapipe/` with `mediapipe_config.gd` / `MediaPipeConfig` after the approved `godotenv-sync` refresh.

## Diagnosis

This is **not alias naming only**.

The assembly manifest intentionally keeps the install directory alias `aerobeat-input-mediapipe`, but the actual source selection is still pinned to an **older commit** of the renamed repo:

- Consumer manifest: `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-assembly-community/addons.jsonc`
- Exact entry:
  - addon key: `aerobeat-input-mediapipe`
  - url: `git@github.com:AeroBeat-Workouts/aerobeat-input-camera-tracking.git`
  - checkout: `5bbdf2575c31eab03ea528f4826c1d159f47a1fe`
  - subfolder: `/`

That pinned commit still contains the legacy shim and related references:

- `git show --stat --oneline --no-patch 5bbdf2575c31eab03ea528f4826c1d159f47a1fe`
  - `5bbdf25 Restore camera device signal on compat provider`
- `git ls-tree -r --name-only 5bbdf2575c31eab03ea528f4826c1d159f47a1fe | rg 'mediapipe_config\.gd|camera_tracking_config\.gd|input_provider\.gd|AeroCameraTracking\.gd'`
  shows `src/config/mediapipe_config.gd` still exists in that pinned source snapshot.

The retired-shim source lives at a newer repo commit instead:

- Repo source HEAD in `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking`:
  - `git rev-parse HEAD` -> `4f63ccd2d131d4192e9675fd6a78572780a7ec0f`
  - `git show --stat --oneline --no-patch 4f63ccd2d131d4192e9675fd6a78572780a7ec0f`
  - `4f63ccd Retire MediaPipe config shim`

## Generated Surface Evidence

In the assembly repo after refresh:

- Cache repo HEAD:
  - `git -C .addons/aerobeat-input-mediapipe rev-parse HEAD`
  - result: `5bbdf2575c31eab03ea528f4826c1d159f47a1fe`
- Cache repo remote:
  - `git -C .addons/aerobeat-input-mediapipe remote -v`
  - origin is `git@github.com:AeroBeat-Workouts/aerobeat-input-camera-tracking.git`
- Cache repo still contains shim hits:
  - `rg -n 'mediapipe_config\.gd|class_name MediaPipeConfig|MediaPipeConfig' .addons/aerobeat-input-mediapipe -S`

The installed addon mirror under `addons/` is regenerated from that stale payload, not from current repo HEAD:

- `git -C addons/aerobeat-input-mediapipe rev-parse HEAD` -> `577ec775cdaed99c3b3fa8976b653c921cbb35f4`
- `git -C addons/aerobeat-input-mediapipe log --oneline -1` -> `577ec77 "Initial commit"`
- `rg -n 'mediapipe_config\.gd|class_name MediaPipeConfig|MediaPipeConfig' addons/aerobeat-input-mediapipe -S`
  still shows `src/config/mediapipe_config.gd` and compat references.

That `addons/` commit is not the consumer’s source of truth; it is a generated installed surface. The meaningful source-selection evidence is the `.addons/` cache repo being checked out at `5bbdf25` plus the consumer manifest pinning that same old commit.

## Restore / Install Behavior Conclusion

The approved `godotenv-sync` run did not fail; it faithfully restored what the consumer manifest requested.

Relevant behavior from `/home/derrick/.openclaw/workspace/scripts/godotenv-sync`:

- default actions are `--scrub-uids --install`
- cache refresh happens only when `--refresh-caches` is explicitly requested
- install runs `godotenv addons install`

So there are two truths:

1. Task 4’s refresh did **not** request cache clearing.
2. Even if cache clearing were forced, the manifest still pins checkout `5bbdf25`, so reinstall would still reacquire the old shim-bearing payload.

Therefore the primary issue is **stale source selection in the consumer manifest**, not restore caching alone.

## Narrowest Next Implementation Seam

Update only the assembly consumer dependency declaration in:

- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-assembly-community/addons.jsonc`

Specifically, keep the install alias key `aerobeat-input-mediapipe` if consumer paths still require it, but change the selected source snapshot from:

- `checkout: 5bbdf2575c31eab03ea528f4826c1d159f47a1fe`

to a commit/tag that includes the shim retirement (at minimum `4f63ccd2d131d4192e9675fd6a78572780a7ec0f` or whatever newer approved pin supersedes it), then rerun:

- `/home/derrick/.openclaw/workspace/scripts/godotenv-sync --repo /home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-assembly-community --refresh-caches --install`

and re-check with:

- `rg -uu -n 'mediapipe_config\.gd|MediaPipeConfig' /home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-assembly-community`

## Classification

- **Alias naming only?** No.
- **Stale source selection?** Yes — primary cause.
- **Restore caching?** Secondary amplifier only; refresh alone would not fix the wrong pinned checkout.
- **Something else?** The generated `addons/` mirror is disposable output and should not be treated as source.
