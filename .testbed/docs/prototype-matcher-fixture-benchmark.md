# Prototype Matcher Fixture Benchmark

This repo now has a committed replay-fixture benchmark path for the current boxing prototype matcher.

## What it does

The benchmark runner:

- reuses the existing boxing proving scene
- reuses committed boxing replay fixtures
- forces the proving runtime onto the `prototype_matcher` backend through a documented proving-only env override
- captures full fixture state timelines so QA/audit can inspect per-frame matcher debug truth
- emits machine-readable baseline results for the current `boxing_side_aware_v1` library

## Inputs

Manifest:

- `res://assets/benchmarks/prototype_matcher_boxing_v1.benchmark.json`

Representative fixture set in the manifest currently includes:

- straight left
- straight right
- hook left
- hook right
- uppercut left
- uppercut right
- run-in-place negative control

## Run it

From the repo root:

```bash
python3 scripts/run_prototype_matcher_fixture_benchmark.py \
  --manifest .testbed/assets/benchmarks/prototype_matcher_boxing_v1.benchmark.json \
  --output-dir .temp/prototype-matcher-benchmark
```

Outputs:

- `.temp/prototype-matcher-benchmark/benchmark-results.json`
- `.temp/prototype-matcher-benchmark/benchmark-results.md`
- `.temp/prototype-matcher-benchmark/captures/<fixture-id>/report.json`
- `.temp/prototype-matcher-benchmark/captures/<fixture-id>/godot.log`

## Truth surface

Each per-fixture capture now includes:

- fixture event timeline
- full state timeline
- active punch backend snapshot
- prototype matcher debug snapshot per retained state sample
- prototype-backed event payload metadata when an attack signal was emitted

That gives QA/audit enough evidence to answer:

- which attack events the matcher emitted
- which prototype class won
- what score cleared or failed threshold
- whether the matcher stayed below threshold, hit hold/cooldown gates, or emitted the wrong class

## Scope limits

This benchmark is a proving/evaluation path, not a claim that the current library is production-ready.

It does **not** yet:

- retune the matcher broadly
- replace the default boxing runtime backend
- claim saved-session manifest parity for this repo-local proving runner
- convert replay fixture timing windows into pass/fail scoring beyond the baseline findings emitted by the benchmark JSON
