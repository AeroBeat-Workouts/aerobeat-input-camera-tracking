# boxing_side_aware_fixture_derived_v1

Derived prototype library for the boxing prototype matcher.

## Provenance

- Manifest: `.testbed/assets/benchmarks/prototype_matcher_boxing_fixture_derived_v1.benchmark.json`
- Fixture source: `.testbed/assets/fixtures/boxing/` verified YAML windows + matching MP4s
- Pose generation path: `.testbed/scripts/capture_fixture_proving.gd` -> `proving_harness.gd` full pose snapshots
- Derived library: `assets/prototype_libraries/boxing_side_aware_fixture_derived_v1/library.json`
- Derivation report: `assets/prototype_libraries/boxing_side_aware_fixture_derived_v1/derivation_report.json`
- Scratch captures: `.temp/hook-left-window01-final-captures`

## Regenerate

```bash
python3 scripts/derive_prototype_library_from_fixtures.py --manifest .testbed/assets/benchmarks/prototype_matcher_boxing_fixture_derived_v1.benchmark.json --output-library-id boxing_side_aware_fixture_derived_v1
```

Each prototype corresponds to one human-verified gesture window from a fixture YAML file. The pose samples come from headless fixture replay capture reports, not manual seed editing.
