# AeroBeat Boxing Detection Decision Brief — Thresholds vs Classifier vs Monocular Depth

_Date: 2026-06-16_

## Bottom line

**Recommended next path: train a small supervised pose-sequence classifier for boxing punches, while keeping the current threshold detector as the shipping fallback during data collection and rollout.**

### Ranked recommendation

1. **Classifier path first** — best chance of materially improving straight punches **and** giving hooks/uppercuts a real upgrade path.
2. **Threshold-only tuning as the short-term maintenance path** — cheapest way to keep the current detector usable, but likely near its ceiling.
3. **Monocular depth as a later R&D branch, not the next mainline branch** — plausible as a future auxiliary feature for straights, but too much engineering risk for too little confidence right now.

If Derrick wants the plain-English version: **depth is interesting, but classifier work is the first branch that has a believable chance of fixing the actual product problem instead of just moving the failure around.**

---

## What problem actually needs solving

The decision matters only if it improves the product problem AeroBeat actually has:

- **Current straight detection is already somewhat usable** and roughly in the "works often enough to see the shape" zone.
- The most valuable improvement is **more reliable rapid same-side straights in succession**.
- **Co-firing is acceptable** if the game design can tolerate it.
- **Hook and uppercut quality are separate problems.** They probably need better gesture modeling, not just more depth.
- The recent prototype-matcher branch was audited as a dead end because it still cross-fired heavily and kept false positives on negative controls.

That means the real question is not "can monocular depth produce a cool depth map?" It is:

> Can it give AeroBeat a stable enough, low-latency, wrist-local forward signal to improve repeated straights more than a classifier would, at lower overall cost and risk?

My answer after looking at the current repo state and realistic model options is **no, not as the next mainline bet**.

---

## Current repo reality that matters

AeroBeat already has several useful assets for a classifier path:

- human-verified boxing fixture videos under `.testbed/assets/fixtures/boxing/`
- YAML truth windows for expected gestures, e.g. the straight-left fixture windows in `.testbed/assets/fixtures/boxing/straight_left/boxing_guard->straight_left_repeat_04_take_01.yaml`
- capture/report tooling that already exports rich pose/runtime state, e.g. `scripts/derive_prototype_library_from_fixtures.py`, `scripts/run_prototype_matcher_fixture_benchmark.py`, and large per-frame `report.json` artifacts
- existing threshold features and debug surfaces in `src/detectors/pose_detector_substrate.gd`

AeroBeat also already has evidence that **pose-derived forward-depth-like signals are not magic**:

- the 2026-06-12 straight-punch forward-depth-spike experiment added a narrow z-spike gate, but that only proved the signal could be surfaced honestly — not that it solves the product problem by itself
- earlier depth-aware straight experiments in archived plans repeatedly ran into the same failure mode: naive depth/3D truth tends to help identify that a punch is "forward-ish," but **does not by itself solve rearm truth, side ownership, or false-positive control**

That history matters because monocular depth would not replace those problems. It would mostly add another noisy signal source on top of them.

---

## Option 1 — Stay threshold-only and keep tuning

## Verdict

**Keep as the maintenance baseline, not as the main improvement strategy.**

## What it is good at

- lowest engineering cost
- no new inference runtime
- easiest deployment story
- easiest to debug live because every rule is explicit
- acceptable if the goal is just to keep the current straight detector serviceable while another path is built

## What it is bad at

- likely close to the practical ceiling already
- every improvement tends to trade one failure mode for another
- repeated same-side straights are specifically hard because they depend on clean temporal state, rearm truth, and side ownership under foreshortened front-facing motion
- hook/uppercut behavior likely still needs a more structural redesign

## Straight-punch implications

Threshold-only work can probably still buy:

- some better rearm timing
- some better same-side repeat behavior
- some modest false-positive cleanup

But it is unlikely to produce a big jump because the remaining misses are not just "one threshold is wrong." They are closer to:

- temporal ambiguity
- side disambiguation ambiguity
- front-facing foreshortening ambiguity
- overlap between punch families

Those are exactly the kinds of problems where hand-authored rules start getting brittle.

## Hook / uppercut implications

Weak. Threshold-only can continue to tune them, but there is no strong evidence this path will make those gestures robust enough without turning into a long whack-a-mole cycle.

## Overall assessment

**Good fallback. Weak main bet.**

---

## Option 2 — Train a supervised classifier from recorded boxing videos + exported pose + YAML truth labels

## Verdict

**Best next mainline path.**

## Why this fits AeroBeat better than the other two

The classifier path directly matches the repo's strongest assets:

- you already have **videos**
- you already have **human-authored truth windows**
- you already have **per-frame pose/runtime exports or exportable capture reports**
- you already know the main failure cases you care about

That means this is not "start an ML program from zero." It is closer to:

1. export fixed-width pose sequences aligned to the YAML windows
2. generate negative / transition / near-miss windows too
3. train a small temporal classifier on pose features
4. compare it directly against the current threshold detector on the fixture set and fresh live captures

## Why it is likely to help straights

A temporal classifier can learn patterns threshold logic struggles with:

- repeated same-side straights where the second punch begins before the first returns to a perfect neutral shape
- differences between a straight and other arm motions using **sequence shape**, not just one frame or one scalar gate
- side-specific motion with context from shoulder/elbow/wrist trajectory together
- tolerant handling of minor co-firing if the primary class stays stable enough for gameplay

A good small classifier does **not** need raw video as input. For AeroBeat, the likely best first version is a **pose-sequence classifier** using a short rolling window of features such as:

- shoulder/elbow/wrist XY and available Z-like coordinates
- velocities and accelerations
- elbow-shoulder distance / extension ratios
- torso-relative and shoulder-width-normalized features
- hand bbox growth when available
- current threshold detector state as an optional feature, not a source of truth

That keeps runtime cheap and keeps the model focused on the actual gesture problem instead of image appearance.

## Why it is likely to help hooks and uppercuts too

This is the biggest strategic advantage over the depth path.

Hooks and uppercuts probably need a better temporal shape model anyway. A classifier gives one path that can eventually cover:

- straight-left / straight-right
- hook-left / hook-right
- uppercut-left / uppercut-right
- no-punch / guard / transitions

So even if AeroBeat initially trains only straights, the investment generalizes.

## Cost and risk

### Engineering cost

**Moderate**, but mostly in places that create reusable value:

- export tooling / dataset preparation
- window sampling and train/validation split discipline
- a small training script and evaluation harness
- model loading/inference integration
- acceptance testing against fixtures and live play

### Data requirements

Also **moderate**, not extreme.

AeroBeat does not need internet-scale data. It needs:

- enough real clips to cover Derrick's actual stance, speed, framing, lighting, and repeat cadence
- enough negatives and confusing motions to stop overfitting
- enough same-side repeat examples to specifically target the main problem

The existing fixture set is already a good bootstrap, though it is probably too small by itself for production. It does, however, look very good as the seed for a real dataset pipeline.

### Runtime / deployment

Potentially **lighter than monocular depth** if done as a pose classifier.

A tiny MLP / 1D temporal conv / small GRU over pose features should be far cheaper than running a separate per-pixel depth model every frame.

### Main risks

- overfitting to Derrick's clips if the dataset stays narrow
- label quality / alignment work
- needing a clean export pipeline before training is trustworthy

Those are real risks, but they are visible and manageable. More importantly, they are **product-relevant risks** rather than "we shipped a whole new vision subsystem and still are not sure the wrist depth is usable."

## Overall assessment

**Best quality-per-effort path with the best chance of improving straights and opening a future path for hooks/uppercuts.**

---

## Option 3 — Add lightweight monocular depth focused on wrist forward-depth for straights

## Verdict

**Interesting R&D, weak next production bet.**

## Important distinction

There are two very different claims people make about monocular depth:

1. **"This model produces a convincing depth image."**
2. **"This model gives AeroBeat a stable enough wrist-forward signal during rapid punches to improve repeated straights."**

For AeroBeat, only claim #2 matters.

A model can be visually impressive and still fail the real task.

## FastDepth / HoloFastDepth specifically

### What FastDepth is good at

FastDepth is still the strongest argument **for** trying depth on constrained hardware:

- designed specifically for embedded real-time depth
- reported by MIT at **178 FPS on Jetson TX2 GPU** and **27 FPS on TX2 CPU**
- very small compute footprint: **0.37 GMACs** at **224x224** input
- HoloFastDepth shows that an old FastDepth ONNX can be wired into a Unity/Barracuda-style runtime and displayed on-device
- the Medium article reports a rough **~30 FPS** demo on a Samsung Galaxy S9+ using the FastDepth ONNX in Unity Barracuda

### Why that still does not make it the right next path

HoloFastDepth is basically a **demo integration around FastDepth**, not evidence that the output is good enough for high-truth boxing gesture decisions.

The problems for AeroBeat are:

- **224x224 depth is coarse** for wrist-local decisions
- FastDepth is **relative depth**, not metric truth
- rapid punches create **motion blur, foreshortening, self-occlusion, and arm/torso overlap**
- front-facing boxing straights are exactly the case where monocular depth can look globally plausible while still being unstable around the hand edge you actually care about
- same-side repeat detection needs not only forwardness but also **truthful rearm and per-side temporal separation**

So FastDepth is fast enough to be plausible, but not obviously task-accurate enough.

## Other realistic monocular depth candidates

### MiDaS small / mobile variants

MiDaS is the most realistic modern comparison point because it has documented mobile variants:

- MiDaS mobile README reports roughly **8 FPS CPU / 22 FPS GPU / 30 FPS NPU on iPhone 11**
- and roughly **6 FPS CPU / 22 FPS GPU / 4 FPS NNAPI on OnePlus 8** for the small 256 model
- the desktop README also explicitly positions smaller variants like `midas_v21_small_256`, `dpt_swin2_tiny_256`, and `dpt_levit_224` as embedded options

That is useful evidence that mobile-ish depth is possible.

But the same caveat applies: MiDaS gives **relative dense depth**, not hand-specific temporal truth. It is also heavier and more integration-complex than a tiny pose classifier.

### Depth Anything V2 Small

Depth Anything V2 Small is attractive on paper because it is newer and more robust in general scenes, but for AeroBeat it is the wrong first bet:

- still **24.8M parameters**, much larger than FastDepth-class models
- default inference setup is much heavier than the old 224x224 FastDepth-style path
- better general depth detail does not automatically translate into better **rapid wrist-local temporal stability**
- integration complexity is higher, especially if the end goal is just a single extra wrist-depth feature

In other words: it is more modern, but not obviously more product-efficient for this exact use case.

## Straight-punch implications

This is the only place monocular depth has a credible upside.

If depth helps anywhere, it helps here:

- detecting forward travel that 2D XY cannot see well
- separating a real straight from a mostly lateral arm motion
- possibly improving rapid same-side repeat recognition if the return/re-extension shape becomes clearer

But the likely best-case here is **incremental improvement as a fused feature**, not a clean standalone win.

The likely truthful role for monocular depth would be:

- one extra signal in a classifier or detector fusion stack
- maybe wrist or forearm forwardness trend over a short window
- maybe depth delta from shoulder/torso context

That is very different from "depth solves straights by itself."

## Hook / uppercut implications

Mostly weak.

Depth alone is not likely to rescue the current hook/uppercut problems because those classes are more about:

- trajectory shape
- upward vs lateral motion balance
- side ownership
- temporal sequencing

A better temporal gesture model is the stronger answer there.

## Runtime and integration concerns

Even a "lightweight" depth path adds a new subsystem:

- model selection / conversion / runtime engine
- frame preprocessing and postprocessing
- depth smoothing and temporal filtering
- wrist/arm ROI extraction from a dense map
- calibration / normalization so the depth signal is comparable over time
- fusion into the current gesture logic
- end-to-end profiling for latency

That is a lot of work for a path whose main likely payoff is **one more noisy feature**.

## Overall assessment

**Worth revisiting later only if AeroBeat still needs more straight-punch signal after classifier work, or if a tiny spike experiment proves a fused depth feature gives unusually clean same-side repeat gains.**

---

## Head-to-head comparison

| Path | Engineering cost | Data requirement | Runtime cost | Deployment complexity | Straight-punch upside | Hook/uppercut upside | Main risk |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Threshold-only tuning | Low | Low | Lowest | Lowest | Low to moderate | Low | You spend time polishing a near-ceiling approach |
| Pose-sequence classifier | Moderate | Moderate | Low to moderate | Moderate | High | Moderate to high | Overfitting / label quality / dataset prep |
| Monocular depth | Moderate to high | Low to moderate for pretrained use, but high if task-adapting | Moderate to high | High | Moderate at best | Low | Big subsystem cost for a weak or noisy wrist-depth signal |

---

## Why the classifier path beats the depth path for AeroBeat specifically

1. **It attacks the real problem class.**
   - AeroBeat's hardest issues are temporal ambiguity and family overlap, not just missing one depth scalar.

2. **It uses assets the repo already has.**
   - The fixture videos, YAML windows, and capture reports already look like the start of a real supervised dataset pipeline.

3. **It can improve all three punch families.**
   - Depth is mostly a straight-punch helper. A classifier can become the general punch recognizer.

4. **It is likely cheaper at runtime than depth if you classify on pose features.**
   - A tiny temporal classifier over pose landmarks is much lighter than dense depth inference plus feature extraction.

5. **It keeps depth available later as an add-on, instead of betting the roadmap on it now.**
   - If needed, depth can later become just another input feature to the classifier.

---

## Recommended next execution slice

### Recommended decision

**Execute the classifier branch next. Keep threshold-only work alive only as a support path. Do not choose monocular depth as the mainline next branch.**

### Concrete next slice

1. **Build dataset export tooling from existing fixtures and capture reports.**
   - Export fixed-length windows for `straight_left`, `straight_right`, `hook_left`, `hook_right`, `uppercut_left`, `uppercut_right`, plus `no_punch/guard/transition`.
2. **Start with a pose-sequence classifier, not a raw-video model.**
   - Keep the first model tiny and interpretable.
3. **Target the main product seam explicitly.**
   - Oversample or explicitly evaluate **rapid same-side straight succession**.
4. **Keep the threshold detector as the fallback baseline and comparison target.**
   - The new model should have to beat the current detector on fixture truth and live feel.
5. **Only reopen depth if classifier results plateau.**
   - If that happens, test depth only as a fused auxiliary signal for straights, not as a replacement subsystem.

### If Derrick wants the smallest possible bet first

If the goal is maximum caution, the smallest truthful next step is:

- do **one narrow classifier feasibility slice**
- use only the current boxing fixtures plus a few fresh repeated-straight recordings
- train a tiny straight-only pose classifier first
- compare it directly against the threshold detector on same-side repeat cases

That is a better experiment than a depth prototype because the result answers the roadmap question more directly.

---

## Final recommendation in one sentence

**Choose a small pose-sequence classifier as the next mainline branch, keep threshold tuning as the support baseline, and treat monocular depth as a later optional feature experiment rather than the next core strategy.**

---

## Research references used

- Repo plan: `.plans/2026-06-16-boxing-depth-and-classifier-paths-research.md`
- Current threshold config: `assets/boxing.gesture_detection.yaml`
- Current detector/runtime surface: `src/detectors/pose_detector_substrate.gd`
- Straight-left truth windows: `.testbed/assets/fixtures/boxing/straight_left/boxing_guard->straight_left_repeat_04_take_01.yaml`
- Example capture/report surface: `.temp/derived_prototype_library_from_fixtures_retest_2026-06-15/captures/straight_left_fixture/report.json`
- Prototype matcher dead-end review: `docs/reviews/prototype-matcher-threshold-inspired-straight-review-2026-06-16.md`
- Prior narrow forward-depth threshold experiment: `.plans/2026-06-12-straight-punch-depth-spike-threshold-experiment.md`
- FastDepth project: <https://fastdepth.mit.edu/>
- FastDepth repo: <https://github.com/dwofk/fast-depth>
- HoloFastDepth repo: <https://github.com/miso3/HoloFastDepth>
- Medium article: <https://medium.com/xrpractices/monocular-depth-sensing-point-cloud-from-webcam-feed-using-unity-barracuda-d9f1496b5932>
- MiDaS repo / mobile README: <https://github.com/isl-org/MiDaS>
- Depth Anything V2 repo: <https://github.com/DepthAnything/Depth-Anything-V2>
