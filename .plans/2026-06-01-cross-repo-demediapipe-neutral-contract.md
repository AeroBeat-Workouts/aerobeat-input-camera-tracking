# Cross-Repo De-MediaPipe Neutral Contract

**Date:** 2026-06-01 22:18 EDT
**Author:** OpenClaw subagent (`research`)
**Owning coordination repo:** `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking`

---

## Goal

Define the target neutral cross-repo contract for the AeroBeat camera-tracking lane and the exact migration sequence that removes MediaPipe-specific seam identities from `aerobeat-input-camera-tracking` while preserving a working path through `aerobeat-tool-camera-tracking` to `aerobeat-vendor-mediapipe-python`.

---

## Executive summary

The current contract overloads `mediapipe_python` as:

- the public provider id,
- the default shared session key,
- the tool backend selector,
- the actual vendor implementation id, and
- the value echoed through runtime payloads and examples.

That is the core contract bug.

The neutral target is to split those identities into **public lane/provider/session concepts** and **vendor implementation concepts**:

- public lane/provider/session identity becomes **`camera_tracking`**
- tool-owned public backend request identity becomes **neutral** and may be omitted entirely by normal callers
- vendor implementation identity remains **`mediapipe_python`**, but only inside vendor-owned or tool-owned backend-resolution seams

The most important behavioral rule is simple:

> `aerobeat-input-camera-tracking` should publish/request/reuse **camera-tracking** sessions and should talk only to the **CameraTracking** contract. It must not choose or name `mediapipe_python` in sharable `src/`.

The tool repo becomes the owner of backend resolution/defaulting. The vendor repo remains free to keep MediaPipe-branded internal runtime/config names. The only explicitly allowed vendor coupling in the input repo remains the `.testbed/addons.jsonc` vendor mount exception for proving.

---

## Contract model

## 1) Identity layers

The neutral contract should distinguish four separate concepts.

### A. Public lane identity

Purpose: what kind of capability this lane provides.

**Target value:** `camera_tracking`

Used for:
- lane metadata
- public docs/examples
- session namespace root
- public provider identity

### B. Public provider identity

Purpose: the provider id visible to `aerobeat-input-core` and in-process session reuse.

**Target value:** `camera_tracking`

Used for:
- `provider_id`
- input-manager priority entries
- provider-session-registry lookups
- shared session metadata

### C. Public backend request identity

Purpose: what a consumer asks the tool layer to resolve.

**Target rule:** normal callers should omit it unless they are intentionally selecting a non-default backend.

When an explicit neutral public selector is needed, use:
- **`camera_tracking_default`** — tool-owned neutral alias for “whatever backend this tool currently resolves by default”

Important: this is a **tool contract id**, not a vendor id.

### D. Vendor implementation identity

Purpose: the concrete backend package/runtime implementation.

**Current value:** `mediapipe_python`

Used for:
- backend factory registration
- vendor runtime bridge/config
- vendor health/diagnostics
- vendor repo internal files, env vars, and asset naming

Important: this stays valid, but it should no longer be the public lane/provider/session identity.

---

## 2) Target public contract

## Public provider/session contract

### `aerobeat-input-camera-tracking`

Target public values:

- `PROVIDER_ID := "camera_tracking"`
- default shared session key root: `camera_tracking`
- session examples:
  - `camera_tracking/desktop_main`
  - `camera_tracking/camera0`
- metadata lane: `camera_tracking`

### Provider-session-registry semantics

The registry remains generic. Only the example/default contract changes.

New example pattern:

```gdscript
var request := AeroProviderSessionRegistry.request_session({
    "provider_id": "camera_tracking",
    "required_capabilities": [AeroInputProvider.Capability.GESTURE_RECOGNITION],
    "metadata_match": {
        "lane": "camera_tracking",
    },
})
```

New session key examples:

- `camera_tracking/desktop_main`
- `camera_tracking/camera0`

### Session-key rule

The session key namespace must not encode the vendor.

Recommended policy:
- root namespace = `camera_tracking`
- suffix = runtime/device/scope qualifier when needed

Examples:
- `camera_tracking`
- `camera_tracking/desktop_main`
- `camera_tracking/camera0`

If the current input-provider behavior still wants a simple single default key, the default should be exactly:
- `camera_tracking`

---

## 3) Target tool/backend contract

## Core rule

`aerobeat-tool-camera-tracking` owns backend resolution.

`aerobeat-input-camera-tracking` must stop emitting a vendor backend id from sharable `src/`.

That means `camera_tracking_provider.gd` should no longer build:

```gdscript
"backend": "mediapipe_python"
```

in the steady state.

Instead, normal public config sent to `CameraTracking.start()` / `change()` should either:

- omit `backend`, or
- set `backend = "camera_tracking_default"` only when an explicit neutral selector is required by the tool contract.

### Resolution behavior

The tool repo should resolve backends in this order:

1. **manual backend already attached**
   - preserve current behavior
2. **explicit vendor id requested and registered**
   - e.g. `mediapipe_python`
   - this remains valid for vendor-owned tests and compatibility callers
3. **explicit neutral public selector requested**
   - `camera_tracking_default`
   - tool resolves this to its configured preferred vendor backend
4. **backend omitted / empty**
   - tool resolves exactly as if `camera_tracking_default` had been requested
5. **no resolvable backend available**
   - fail with a neutral tool-owned error such as `backend_unavailable` or `backend_unregistered`

### Temporary compatibility requirement

During migration, the tool repo should accept **all three** of these request shapes:

- omitted backend
- `backend = "camera_tracking_default"`
- `backend = "mediapipe_python"`

This is the compatibility bridge that lets downstream repos migrate off the vendor name without breaking the working vendor backend.

### Preferred default implementation

Initial tool-owned preferred default should still resolve to:
- `mediapipe_python`

But that fact must live **only** in tool-owned backend-resolution code or config, not in `aerobeat-input-camera-tracking`.

---

## 4) Frame/state/diagnostic identity separation

The current normalized frame/state surfaces echo `backend = "mediapipe_python"` everywhere. That makes vendor identity appear public even after config neutralization.

Target separation:

### Public-facing contract fields

Public runtime/session consumers should care about:
- `provider_id = camera_tracking`
- session key under `camera_tracking/...`
- tracking state, source, frame content, preview status

### Vendor-facing diagnostic fields

The actual implementation id should remain available for diagnostics, but separate from the public lane/provider contract.

Recommended target shape:

- `backend_request`: neutral requested backend id, e.g. `camera_tracking_default` or empty/default
- `backend_impl`: actual resolved vendor backend id, e.g. `mediapipe_python`

### Compatibility bridge

Because multiple repos/tests currently read `frame.backend`, the migration should be staged:

**Transition phase:**
- keep `backend` populated for compatibility
- add the separated tool-owned fields (`backend_request`, `backend_impl`) first
- let `backend` continue to equal `backend_impl` during the bridge window

**Final neutral phase:**
- either redefine `backend` as the public tool-facing backend request id
- or de-emphasize/remove it in favor of the split fields

Recommendation: do **not** try to finish this field-level cleanup first. Land the public provider/session/backend-request split first, then normalize frame/diagnostic naming.

---

## 5) Config resource naming contract

## Public config resources

### In `aerobeat-input-camera-tracking`

Public config source of truth should be:
- file: `src/config/camera_tracking_config.gd`
- class: `CameraTrackingConfig`

The input repo should use only this neutral resource in sharable `src/` and current tests.

### In `aerobeat-tool-camera-tracking`

Continue using:
- `src/CameraTrackingConfig.gd`
- `class_name CameraTrackingConfig`

This is already neutral and should remain the public tool contract.

## Vendor config resources

### In `aerobeat-vendor-mediapipe-python`

Vendor-owned resources may remain branded, for example:
- `MediaPipePythonConfig.gd`
- `MediaPipePythonRuntimeBridge.gd`
- `runtime/mediapipe_runtime_probe.py`

Those are implementation details, not public cross-repo identities.

---

## 6) Temporary compatibility shims

The migration needs explicit bridges.

### Shim A: input config resource shim

Keep temporarily:
- `src/config/mediapipe_config.gd`
- `class_name MediaPipeConfig`

Required behavior:
- remain a thin subclass/alias of the neutral camera-tracking config
- no new code should point at it
- remove only after assembly/resource references are audited and migrated

### Shim B: tool backend-request compatibility

During the bridge window, tool backend resolution must accept:
- omitted backend
- `camera_tracking_default`
- `mediapipe_python`

This avoids breaking:
- old callers still naming the vendor
- new callers using the neutral default
- input-camera-tracking callers that stop naming any backend at all

### Shim C: input-core/provider-session compatibility

During migration, the session registry docs/examples and any priority/default lookups should support the new `camera_tracking` identity while preserving temporary survivability for stale `mediapipe_python` consumers.

Recommended bridge options, in order of preference:

1. update all known in-scope consumers atomically
2. if needed, add a temporary request normalization/lookup fallback where `mediapipe_python` maps to `camera_tracking`
3. remove the fallback after downstream consumers stop relying on it

Important: if a fallback is added, it should live in the appropriate owner repo seam, not as a permanent truth baked back into the input repo’s public identity.

### Shim D: proving/runtime bridge

If `.testbed` proving still needs vendor-root knowledge temporarily, keep it isolated to proving-only files while moving toward a tool-owned helper/descriptor seam.

That bridge is acceptable temporarily.

What is **not** acceptable as the end state:
- sharable `src/` files in `aerobeat-input-camera-tracking` naming MediaPipe vendor ids, runtime entrypoints, or vendor backends

---

## 7) Proving/runtime indirection expectations

## Required boundary

Product-facing `src/` in `aerobeat-input-camera-tracking` should know only:
- the input-core session seam
- the `CameraTracking` tool contract
- neutral camera-tracking config

It should **not** know:
- `mediapipe_python`
- `MediaPipePythonConfig`
- `runtime/mediapipe_runtime_probe.py`
- MediaPipe-branded runtime env/model override names

## Allowed exception

The following remains allowed:
- `.testbed/addons.jsonc` mounting `aerobeat-vendor-mediapipe-python`

That exception is proving/workbench dependency wiring only.

## Recommended proving indirection target

The proving harness should eventually depend on one of these neutral seams:

### Preferred
A **tool-owned backend descriptor / resolver seam** that can answer questions like:
- what backend is the current default?
- is a mounted backend available?
- what runtime prep hooks or runtime configuration does it require?

### Acceptable temporary bridge
A proving-only helper may still reach into the mounted vendor repo, but only inside `.testbed/` and only until the tool-owned seam exists.

## Runtime/config data ownership

Neutral/shared config fields should remain public:
- `source`
- `tracking`
- `preview`
- neutral runtime toggles if genuinely shared across vendors

Vendor-specific runtime/config fields stay vendor-owned:
- Python executable overrides
- vendor runtime entrypoint
- vendor model-asset paths
- vendor-specific env override names
- vendor runtime session artifact paths

If a public config still needs to carry implementation-specific overrides during transition, they should travel as an **opaque vendor-owned subtree** and must not be authored by `aerobeat-input-camera-tracking` sharable `src/`.

---

## 8) Naming recommendations

## Public names

Use these consistently across the neutralized public contract:

- lane id: `camera_tracking`
- provider id: `camera_tracking`
- default session key root: `camera_tracking`
- explicit neutral tool backend selector: `camera_tracking_default`
- addon alias for input repo: `aerobeat-input-camera-tracking`
- public config file: `camera_tracking_config.gd`
- public config class: `CameraTrackingConfig`

## Vendor names

Keep vendor names where they belong:

- vendor backend id: `mediapipe_python`
- vendor config class: `MediaPipePythonConfig`
- vendor runtime bridge: `MediaPipePythonRuntimeBridge`
- vendor runtime entrypoint: `runtime/mediapipe_runtime_probe.py`
- vendor-branded env/model overrides: vendor repo only

---

## 9) Exact cross-repo order of operations

This should be landed in the order below.

## Phase 1 — tool repo owns neutral backend resolution first

**Repo:** `aerobeat-tool-camera-tracking`

Implement first:
- add neutral backend-resolution behavior for omitted backend
- add `camera_tracking_default` support
- keep `mediapipe_python` as an accepted explicit vendor backend id
- keep current preferred implementation resolving to `mediapipe_python`
- make the defaulting story fully tool-owned

Why first:
- this is the seam that lets `aerobeat-input-camera-tracking` stop naming the vendor without breaking startup

Temporary bridge needed here:
- alias/omission resolution from neutral request to current vendor backend

## Phase 2 — input-core adopts neutral provider/session identity

**Repo:** `aerobeat-input-core`

Implement next:
- update docs/examples from `mediapipe_python` to `camera_tracking`
- update `input_priority` so the desktop camera lane prefers `camera_tracking` instead of `mediapipe_python`
- if necessary, add a temporary compatibility lookup path for stale `mediapipe_python` requests during migration

Why second:
- input-core is the public consumer of provider/session identity
- this is where the public provider name becomes real

Temporary bridge needed here:
- optional temporary lookup compatibility for stale `mediapipe_python` requesters

## Phase 3 — input-camera-tracking switches to the neutral public contract

**Repo:** `aerobeat-input-camera-tracking`

Then implement:
- change `PROVIDER_ID` to `camera_tracking`
- change shared/default session key root to `camera_tracking`
- stop emitting `backend = "mediapipe_python"` from `camera_tracking_provider.gd`
- omit backend entirely or use the neutral tool selector only if required by the tool contract
- switch all local public/resource/test references to `camera_tracking_config.gd`
- keep `mediapipe_config.gd` shim temporarily

Why third:
- by this point the upstream tool and input-core seams can accept the neutral values

Temporary bridge needed here:
- retain `mediapipe_config.gd` shim
- keep any proving-only vendor-root references isolated to `.testbed/`

## Phase 4 — vendor repo adapts to the new split without becoming public identity

**Repo:** `aerobeat-vendor-mediapipe-python`

Then implement:
- keep registering/exposing the concrete vendor backend id `mediapipe_python`
- optionally expose tool-consumable descriptor/metadata to support neutral default resolution or proving indirection
- preserve branded runtime/config/env/model internals as vendor-owned implementation detail
- if desired, add split diagnostic fields (`backend_request`, `backend_impl`) at the tool/vendor boundary

Why fourth:
- most of the public identity migration can happen without renaming the vendor repo internals
- vendor changes are mostly about cleaner separation, not public naming

Temporary bridge needed here:
- no rename of internal MediaPipe-branded runtime seams required for the first neutral contract landing

## Phase 5 — proving/runtime indirection cleanup

**Repos:** primarily `aerobeat-input-camera-tracking`, possibly `aerobeat-tool-camera-tracking`, optionally vendor repo

Finally:
- reduce `.testbed` assertions and harness logic that know vendor runtime entrypoint/model-path details directly
- prefer a tool-owned backend descriptor/helper if one is introduced
- keep the allowed `.testbed/addons.jsonc` vendor mount exception intact
- continue to use `godotenv-sync` whenever dependency/workbench state needs refresh for inspection

Why last:
- proving/runtime indirection is real cleanup debt, but it should follow the public contract split rather than block it

---

## 10) Where temporary compatibility bridges are needed

### Required bridge location 1
**Repo:** `aerobeat-tool-camera-tracking`
**Bridge:** neutral backend request -> vendor backend resolution

This is mandatory.

### Required bridge location 2
**Repo:** `aerobeat-input-camera-tracking`
**Bridge:** `MediaPipeConfig` / `mediapipe_config.gd` shim

This is strongly recommended until resource-path usage is audited.

### Likely bridge location 3
**Repo:** `aerobeat-input-core`
**Bridge:** temporary stale-request compatibility for `mediapipe_python`

Use only if an atomic consumer update is not practical.

### Optional bridge location 4
**Repo:** `aerobeat-tool-camera-tracking` or vendor repo
**Bridge:** proving/runtime descriptor/helper so `.testbed` does not need to know `runtime/mediapipe_runtime_probe.py`

Useful, but not required for the first neutral contract landing.

---

## 11) What should *not* be changed in the first migration slice

Do **not** block the neutral contract on these:

- renaming the vendor repo itself
- removing MediaPipe-branded internal runtime filenames from the vendor repo
- removing the `.testbed/addons.jsonc` vendor mount exception
- fully redesigning the normalized tracking-frame schema before the provider/session/backend split is landed

Those can follow.

---

## 12) Recommended implementation-ready target statements

Use these as the implementation truth.

### Public truth

- The AeroBeat desktop camera gameplay provider id is `camera_tracking`.
- Shared provider sessions for this lane publish under the `camera_tracking` namespace.
- `aerobeat-input-camera-tracking` talks only to `aerobeat-tool-camera-tracking` and does not select a vendor backend in sharable `src/`.
- `aerobeat-tool-camera-tracking` owns backend defaulting and resolves the current preferred implementation.

### Vendor truth

- `mediapipe_python` is the current concrete camera-tracking backend implementation id.
- It remains valid inside vendor and tool backend-resolution seams.
- It is no longer the public provider/session identity.

---

## 13) Final recommendation

The exact first implementation pass should be:

1. **tool repo:** make omitted backend and `camera_tracking_default` resolve to `mediapipe_python`
2. **input-core:** adopt `camera_tracking` as the public provider/session identity
3. **input-camera-tracking:** rename provider/session identity to `camera_tracking` and stop naming the vendor backend in sharable `src/`
4. **vendor repo:** adapt only as needed for the new split, without forcing an internal runtime rename yet
5. **later cleanup:** reduce proving/runtime vendor knowledge, keeping only the `.testbed/addons.jsonc` mount exception

That sequence gives the ecosystem a neutral public contract immediately while minimizing churn in the working MediaPipe backend implementation.
