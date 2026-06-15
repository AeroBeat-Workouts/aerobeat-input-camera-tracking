# Prototype Matcher Fixture Benchmark

- Benchmark ID: `prototype_matcher_boxing_fixture_derived_v1_straight_only`
- Library ID: `boxing_side_aware_fixture_derived_v1_straight_only`
- Profile: `boxing`
- Generated At: `2026-06-15T19:21:52-04:00`
- Runner: `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/scripts/run_prototype_matcher_fixture_benchmark.py`

## Aggregate

- Fixture count: **3**
- Negative controls clean: **0 / 1**
- Negative-control false-positive classes: `straight_left` x30
- Negative-control false-positive prototypes: `boxing_straight_left_window_03` x22, `boxing_straight_left_window_01` x3, `boxing_straight_left_window_04` x3, `boxing_straight_left_window_02` x2

## Per Fixture

### straight left

- Fixture: `.testbed/assets/fixtures/boxing/straight_left/boxing_guard->straight_left_repeat_04_take_01.yaml`
- Source: `.testbed/assets/fixtures/boxing/straight_left/boxing_guard->straight_left_repeat_04_take_01.mp4`
- Expected event: `punch_left`
- Expected class: `straight_left`
- Attack events emitted: **27**
- Peak snapshot: straight_left via boxing_straight_left_window_04 score=1.000 runner-up=straight_right/boxing_straight_right_window_01 0.687 margin=0.313
- Strongest expected emit: `punch_left` straight_left via boxing_straight_left_window_04 score=1.000 runner-up=straight_right/boxing_straight_right_window_01 0.687 margin=0.313
- Strongest wrong emit: `punch_right` straight_right via boxing_straight_right_window_01 score=0.819 runner-up=straight_left/boxing_straight_left_window_01 0.718 margin=0.101
- Emitted prototype counts: `boxing_straight_right_window_01` x11, `boxing_straight_left_window_04` x7, `boxing_straight_left_window_01` x6, `boxing_straight_left_window_03` x2, `boxing_straight_left_window_02` x1
- Best-snapshot prototype counts: `boxing_straight_right_window_01` x40, `boxing_straight_left_window_01` x20, `boxing_straight_left_window_04` x12, `boxing_straight_left_window_03` x7, `boxing_straight_left_window_02` x4
- emitted expected punch_left 16 time(s)
- also emitted other attack events: punch_right, punch_right, punch_right, punch_right, punch_right, punch_right, punch_right, punch_right, punch_right, punch_right, punch_right
- peak expected-class score 1.000
- peak winner straight_left via boxing_straight_left_window_04 scored 1.000; runner-up straight_right via boxing_straight_right_window_01 scored 0.687 (margin 0.313)
- strongest expected emit used boxing_straight_left_window_04 at 1.000 over runner-up boxing_straight_right_window_01 at 0.687 (margin 0.313)
- strongest wrong emit was punch_right via boxing_straight_right_window_01 at 0.819 over runner-up boxing_straight_left_window_01 at 0.718 (margin 0.101)
- latest matcher reason emit_cooldown_active

Emitted attack events:
- `punch_right` at `1109ms` score=`0.786` prototype=`boxing_straight_right_window_01` class=`straight_right` runner-up=`straight_left/boxing_straight_left_window_01 0.679` margin=`0.108` backend=`prototype_matcher`
- `punch_right` at `1325ms` score=`0.789` prototype=`boxing_straight_right_window_01` class=`straight_right` runner-up=`straight_left/boxing_straight_left_window_01 0.757` margin=`0.032` backend=`prototype_matcher`
- `punch_left` at `1945ms` score=`0.706` prototype=`boxing_straight_left_window_01` class=`straight_left` runner-up=`straight_right/boxing_straight_right_window_01 0.653` margin=`0.053` backend=`prototype_matcher`
- `punch_left` at `2257ms` score=`0.924` prototype=`boxing_straight_left_window_01` class=`straight_left` runner-up=`straight_right/boxing_straight_right_window_01 0.750` margin=`0.174` backend=`prototype_matcher`
- `punch_left` at `2565ms` score=`0.873` prototype=`boxing_straight_left_window_04` class=`straight_left` runner-up=`straight_right/boxing_straight_right_window_01 0.773` margin=`0.100` backend=`prototype_matcher`
- `punch_right` at `2878ms` score=`0.702` prototype=`boxing_straight_right_window_01` class=`straight_right` runner-up=`straight_left/boxing_straight_left_window_01 0.054` margin=`0.649` backend=`prototype_matcher`
- `punch_left` at `3189ms` score=`0.867` prototype=`boxing_straight_left_window_01` class=`straight_left` runner-up=`straight_right/boxing_straight_right_window_01 0.618` margin=`0.249` backend=`prototype_matcher`
- `punch_left` at `3500ms` score=`0.926` prototype=`boxing_straight_left_window_04` class=`straight_left` runner-up=`straight_right/boxing_straight_right_window_01 0.733` margin=`0.193` backend=`prototype_matcher`
- `punch_left` at `3818ms` score=`0.729` prototype=`boxing_straight_left_window_02` class=`straight_left` runner-up=`straight_right/boxing_straight_right_window_01 0.665` margin=`0.064` backend=`prototype_matcher`
- `punch_right` at `4135ms` score=`0.707` prototype=`boxing_straight_right_window_01` class=`straight_right` runner-up=`straight_left/boxing_straight_left_window_01 0.127` margin=`0.580` backend=`prototype_matcher`
- `punch_left` at `4440ms` score=`0.856` prototype=`boxing_straight_left_window_04` class=`straight_left` runner-up=`straight_right/boxing_straight_right_window_01 0.638` margin=`0.218` backend=`prototype_matcher`
- `punch_left` at `4750ms` score=`0.948` prototype=`boxing_straight_left_window_03` class=`straight_left` runner-up=`straight_right/boxing_straight_right_window_01 0.688` margin=`0.260` backend=`prototype_matcher`
- `punch_left` at `5058ms` score=`0.880` prototype=`boxing_straight_left_window_03` class=`straight_left` runner-up=`straight_right/boxing_straight_right_window_01 0.643` margin=`0.237` backend=`prototype_matcher`
- `punch_right` at `5370ms` score=`0.734` prototype=`boxing_straight_right_window_01` class=`straight_right` runner-up=`straight_left/boxing_straight_left_window_01 0.283` margin=`0.451` backend=`prototype_matcher`
- `punch_left` at `5778ms` score=`0.894` prototype=`boxing_straight_left_window_04` class=`straight_left` runner-up=`straight_right/boxing_straight_right_window_01 0.687` margin=`0.207` backend=`prototype_matcher`
- `punch_left` at `6080ms` score=`1.000` prototype=`boxing_straight_left_window_04` class=`straight_left` runner-up=`straight_right/boxing_straight_right_window_01 0.687` margin=`0.313` backend=`prototype_matcher`
- `punch_right` at `6488ms` score=`0.788` prototype=`boxing_straight_right_window_01` class=`straight_right` runner-up=`straight_left/boxing_straight_left_window_01 0.765` margin=`0.024` backend=`prototype_matcher`
- `punch_right` at `6793ms` score=`0.790` prototype=`boxing_straight_right_window_01` class=`straight_right` runner-up=`straight_left/boxing_straight_left_window_01 0.742` margin=`0.049` backend=`prototype_matcher`
- `punch_right` at `7097ms` score=`0.765` prototype=`boxing_straight_right_window_01` class=`straight_right` runner-up=`straight_left/boxing_straight_left_window_01 0.719` margin=`0.047` backend=`prototype_matcher`
- `punch_right` at `7396ms` score=`0.819` prototype=`boxing_straight_right_window_01` class=`straight_right` runner-up=`straight_left/boxing_straight_left_window_01 0.718` margin=`0.101` backend=`prototype_matcher`
- `punch_right` at `7702ms` score=`0.709` prototype=`boxing_straight_right_window_01` class=`straight_right` runner-up=`straight_left/boxing_straight_left_window_04 0.701` margin=`0.008` backend=`prototype_matcher`
- `punch_left` at `8136ms` score=`0.802` prototype=`boxing_straight_left_window_01` class=`straight_left` runner-up=`straight_right/boxing_straight_right_window_01 0.653` margin=`0.149` backend=`prototype_matcher`
- `punch_left` at `8480ms` score=`0.915` prototype=`boxing_straight_left_window_01` class=`straight_left` runner-up=`straight_right/boxing_straight_right_window_01 0.743` margin=`0.172` backend=`prototype_matcher`
- `punch_left` at `8832ms` score=`0.873` prototype=`boxing_straight_left_window_04` class=`straight_left` runner-up=`straight_right/boxing_straight_right_window_01 0.773` margin=`0.100` backend=`prototype_matcher`
- `punch_right` at `9157ms` score=`0.725` prototype=`boxing_straight_right_window_01` class=`straight_right` runner-up=`straight_left/boxing_straight_left_window_01 0.056` margin=`0.669` backend=`prototype_matcher`
- `punch_left` at `9534ms` score=`0.867` prototype=`boxing_straight_left_window_01` class=`straight_left` runner-up=`straight_right/boxing_straight_right_window_01 0.618` margin=`0.249` backend=`prototype_matcher`
- `punch_left` at `9878ms` score=`0.926` prototype=`boxing_straight_left_window_04` class=`straight_left` runner-up=`straight_right/boxing_straight_right_window_01 0.733` margin=`0.193` backend=`prototype_matcher`

### straight right

- Fixture: `.testbed/assets/fixtures/boxing/straight_right/boxing_guard->straight_right_repeat_04_take_01.yaml`
- Source: `.testbed/assets/fixtures/boxing/straight_right/boxing_guard->straight_right_repeat_04_take_01.mp4`
- Expected event: `punch_right`
- Expected class: `straight_right`
- Attack events emitted: **31**
- Peak snapshot: straight_right via boxing_straight_right_window_01 score=1.000 runner-up=straight_left/boxing_straight_left_window_01 0.678 margin=0.322
- Strongest expected emit: `punch_right` straight_right via boxing_straight_right_window_01 score=1.000 runner-up=straight_left/boxing_straight_left_window_01 0.678 margin=0.322
- Emitted prototype counts: `boxing_straight_right_window_04` x22, `boxing_straight_right_window_02` x5, `boxing_straight_right_window_01` x3, `boxing_straight_right_window_03` x1
- Best-snapshot prototype counts: `boxing_straight_right_window_04` x38, `boxing_straight_left_window_01` x13, `boxing_straight_right_window_02` x10, `boxing_straight_right_window_01` x7, `boxing_straight_right_window_03` x3
- emitted expected punch_right 31 time(s)
- peak expected-class score 1.000
- peak winner straight_right via boxing_straight_right_window_01 scored 1.000; runner-up straight_left via boxing_straight_left_window_01 scored 0.678 (margin 0.322)
- strongest expected emit used boxing_straight_right_window_01 at 1.000 over runner-up boxing_straight_left_window_01 at 0.678 (margin 0.322)
- latest matcher reason step_wait

Emitted attack events:
- `punch_right` at `1099ms` score=`0.834` prototype=`boxing_straight_right_window_04` class=`straight_right` runner-up=`straight_left/boxing_straight_left_window_01 0.697` margin=`0.138` backend=`prototype_matcher`
- `punch_right` at `1266ms` score=`0.873` prototype=`boxing_straight_right_window_04` class=`straight_right` runner-up=`straight_left/boxing_straight_left_window_01 0.635` margin=`0.238` backend=`prototype_matcher`
- `punch_right` at `1501ms` score=`0.913` prototype=`boxing_straight_right_window_01` class=`straight_right` runner-up=`straight_left/boxing_straight_left_window_01 0.618` margin=`0.295` backend=`prototype_matcher`
- `punch_right` at `1751ms` score=`1.000` prototype=`boxing_straight_right_window_01` class=`straight_right` runner-up=`straight_left/boxing_straight_left_window_01 0.678` margin=`0.322` backend=`prototype_matcher`
- `punch_right` at `2250ms` score=`0.791` prototype=`boxing_straight_right_window_04` class=`straight_right` runner-up=`straight_left/boxing_straight_left_window_01 0.701` margin=`0.090` backend=`prototype_matcher`
- `punch_right` at `2501ms` score=`0.903` prototype=`boxing_straight_right_window_04` class=`straight_right` runner-up=`straight_left/boxing_straight_left_window_01 0.679` margin=`0.224` backend=`prototype_matcher`
- `punch_right` at `2755ms` score=`0.852` prototype=`boxing_straight_right_window_04` class=`straight_right` runner-up=`straight_left/boxing_straight_left_window_01 0.711` margin=`0.141` backend=`prototype_matcher`
- `punch_right` at `3003ms` score=`0.937` prototype=`boxing_straight_right_window_02` class=`straight_right` runner-up=`straight_left/boxing_straight_left_window_01 0.691` margin=`0.246` backend=`prototype_matcher`
- `punch_right` at `3263ms` score=`0.702` prototype=`boxing_straight_right_window_02` class=`straight_right` runner-up=`straight_left/boxing_straight_left_window_01 0.620` margin=`0.081` backend=`prototype_matcher`
- `punch_right` at `3630ms` score=`0.824` prototype=`boxing_straight_right_window_04` class=`straight_right` runner-up=`straight_left/boxing_straight_left_window_01 0.754` margin=`0.070` backend=`prototype_matcher`
- `punch_right` at `3879ms` score=`0.913` prototype=`boxing_straight_right_window_04` class=`straight_right` runner-up=`straight_left/boxing_straight_left_window_01 0.667` margin=`0.246` backend=`prototype_matcher`
- `punch_right` at `4128ms` score=`0.915` prototype=`boxing_straight_right_window_04` class=`straight_right` runner-up=`straight_left/boxing_straight_left_window_01 0.809` margin=`0.106` backend=`prototype_matcher`
- `punch_right` at `4381ms` score=`0.891` prototype=`boxing_straight_right_window_04` class=`straight_right` runner-up=`straight_left/boxing_straight_left_window_01 0.646` margin=`0.245` backend=`prototype_matcher`
- `punch_right` at `5004ms` score=`0.843` prototype=`boxing_straight_right_window_04` class=`straight_right` runner-up=`straight_left/boxing_straight_left_window_01 0.778` margin=`0.065` backend=`prototype_matcher`
- `punch_right` at `5254ms` score=`0.903` prototype=`boxing_straight_right_window_04` class=`straight_right` runner-up=`straight_left/boxing_straight_left_window_01 0.659` margin=`0.244` backend=`prototype_matcher`
- `punch_right` at `5506ms` score=`0.952` prototype=`boxing_straight_right_window_04` class=`straight_right` runner-up=`straight_left/boxing_straight_left_window_01 0.746` margin=`0.206` backend=`prototype_matcher`
- `punch_right` at `5758ms` score=`0.956` prototype=`boxing_straight_right_window_04` class=`straight_right` runner-up=`straight_left/boxing_straight_left_window_01 0.766` margin=`0.190` backend=`prototype_matcher`
- `punch_right` at `6108ms` score=`0.919` prototype=`boxing_straight_right_window_04` class=`straight_right` runner-up=`straight_left/boxing_straight_left_window_01 0.616` margin=`0.303` backend=`prototype_matcher`
- `punch_right` at `6349ms` score=`0.888` prototype=`boxing_straight_right_window_02` class=`straight_right` runner-up=`straight_left/boxing_straight_left_window_01 0.629` margin=`0.259` backend=`prototype_matcher`
- `punch_right` at `6851ms` score=`0.721` prototype=`boxing_straight_right_window_04` class=`straight_right` runner-up=`straight_left/boxing_straight_left_window_01 0.652` margin=`0.069` backend=`prototype_matcher`
- `punch_right` at `7103ms` score=`0.858` prototype=`boxing_straight_right_window_04` class=`straight_right` runner-up=`straight_left/boxing_straight_left_window_01 0.675` margin=`0.183` backend=`prototype_matcher`
- `punch_right` at `7351ms` score=`0.902` prototype=`boxing_straight_right_window_04` class=`straight_right` runner-up=`straight_left/boxing_straight_left_window_01 0.644` margin=`0.258` backend=`prototype_matcher`
- `punch_right` at `7601ms` score=`0.921` prototype=`boxing_straight_right_window_01` class=`straight_right` runner-up=`straight_left/boxing_straight_left_window_01 0.617` margin=`0.305` backend=`prototype_matcher`
- `punch_right` at `7852ms` score=`0.830` prototype=`boxing_straight_right_window_03` class=`straight_right` runner-up=`straight_left/boxing_straight_left_window_01 0.675` margin=`0.155` backend=`prototype_matcher`
- `punch_right` at `8225ms` score=`0.791` prototype=`boxing_straight_right_window_04` class=`straight_right` runner-up=`straight_left/boxing_straight_left_window_01 0.701` margin=`0.090` backend=`prototype_matcher`
- `punch_right` at `8475ms` score=`0.903` prototype=`boxing_straight_right_window_04` class=`straight_right` runner-up=`straight_left/boxing_straight_left_window_01 0.679` margin=`0.224` backend=`prototype_matcher`
- `punch_right` at `8725ms` score=`0.852` prototype=`boxing_straight_right_window_04` class=`straight_right` runner-up=`straight_left/boxing_straight_left_window_01 0.711` margin=`0.141` backend=`prototype_matcher`
- `punch_right` at `8976ms` score=`0.937` prototype=`boxing_straight_right_window_02` class=`straight_right` runner-up=`straight_left/boxing_straight_left_window_01 0.691` margin=`0.246` backend=`prototype_matcher`
- `punch_right` at `9240ms` score=`0.702` prototype=`boxing_straight_right_window_02` class=`straight_right` runner-up=`straight_left/boxing_straight_left_window_01 0.620` margin=`0.081` backend=`prototype_matcher`
- `punch_right` at `9607ms` score=`0.824` prototype=`boxing_straight_right_window_04` class=`straight_right` runner-up=`straight_left/boxing_straight_left_window_01 0.754` margin=`0.070` backend=`prototype_matcher`
- `punch_right` at `9854ms` score=`0.913` prototype=`boxing_straight_right_window_04` class=`straight_right` runner-up=`straight_left/boxing_straight_left_window_01 0.667` margin=`0.246` backend=`prototype_matcher`

### negative control - running in place

- Fixture: `.testbed/assets/fixtures/boxing/run_in_place/boxing_guard->run_in_place_repeat_01_take_01.yaml`
- Source: `.testbed/assets/fixtures/boxing/run_in_place/boxing_guard->run_in_place_repeat_01_take_01.mp4`
- Expected event: `None`
- Expected class: `None`
- Attack events emitted: **30**
- Peak snapshot: straight_left via boxing_straight_left_window_01 score=0.885 runner-up=straight_right/boxing_straight_right_window_01 0.645 margin=0.240
- Strongest wrong emit: `punch_left` straight_left via boxing_straight_left_window_01 score=0.885 runner-up=straight_right/boxing_straight_right_window_01 0.645 margin=0.240
- Emitted prototype counts: `boxing_straight_left_window_03` x22, `boxing_straight_left_window_01` x3, `boxing_straight_left_window_04` x3, `boxing_straight_left_window_02` x2
- Best-snapshot prototype counts: `boxing_straight_left_window_03` x66, `boxing_straight_left_window_01` x7, `boxing_straight_left_window_02` x7, `boxing_straight_left_window_04` x7
- negative control still emitted attack events: punch_left, punch_left, punch_left, punch_left, punch_left, punch_left, punch_left, punch_left, punch_left, punch_left, punch_left, punch_left, punch_left, punch_left, punch_left, punch_left, punch_left, punch_left, punch_left, punch_left, punch_left, punch_left, punch_left, punch_left, punch_left, punch_left, punch_left, punch_left, punch_left, punch_left
- peak winner straight_left via boxing_straight_left_window_01 scored 0.885; runner-up straight_right via boxing_straight_right_window_01 scored 0.645 (margin 0.240)
- strongest wrong emit was punch_left via boxing_straight_left_window_01 at 0.885 over runner-up boxing_straight_right_window_01 at 0.645 (margin 0.240)
- latest matcher reason emitted

Emitted attack events:
- `punch_left` at `1115ms` score=`0.866` prototype=`boxing_straight_left_window_01` class=`straight_left` runner-up=`straight_right/boxing_straight_right_window_01 0.644` margin=`0.222` backend=`prototype_matcher`
- `punch_left` at `1379ms` score=`0.823` prototype=`boxing_straight_left_window_02` class=`straight_left` runner-up=`straight_right/boxing_straight_right_window_01 0.519` margin=`0.304` backend=`prototype_matcher`
- `punch_left` at `1685ms` score=`0.724` prototype=`boxing_straight_left_window_03` class=`straight_left` runner-up=`straight_right/boxing_straight_right_window_01 0.332` margin=`0.391` backend=`prototype_matcher`
- `punch_left` at `1988ms` score=`0.737` prototype=`boxing_straight_left_window_03` class=`straight_left` runner-up=`straight_right/boxing_straight_right_window_01 0.315` margin=`0.423` backend=`prototype_matcher`
- `punch_left` at `2298ms` score=`0.802` prototype=`boxing_straight_left_window_03` class=`straight_left` runner-up=`straight_right/boxing_straight_right_window_01 0.398` margin=`0.404` backend=`prototype_matcher`
- `punch_left` at `2604ms` score=`0.817` prototype=`boxing_straight_left_window_03` class=`straight_left` runner-up=`straight_right/boxing_straight_right_window_01 0.413` margin=`0.404` backend=`prototype_matcher`
- `punch_left` at `2915ms` score=`0.818` prototype=`boxing_straight_left_window_03` class=`straight_left` runner-up=`straight_right/boxing_straight_right_window_01 0.401` margin=`0.417` backend=`prototype_matcher`
- `punch_left` at `3217ms` score=`0.803` prototype=`boxing_straight_left_window_04` class=`straight_left` runner-up=`straight_right/boxing_straight_right_window_01 0.430` margin=`0.373` backend=`prototype_matcher`
- `punch_left` at `3525ms` score=`0.840` prototype=`boxing_straight_left_window_03` class=`straight_left` runner-up=`straight_right/boxing_straight_right_window_01 0.477` margin=`0.363` backend=`prototype_matcher`
- `punch_left` at `3834ms` score=`0.820` prototype=`boxing_straight_left_window_03` class=`straight_left` runner-up=`straight_right/boxing_straight_right_window_01 0.423` margin=`0.397` backend=`prototype_matcher`
- `punch_left` at `4132ms` score=`0.803` prototype=`boxing_straight_left_window_03` class=`straight_left` runner-up=`straight_right/boxing_straight_right_window_01 0.368` margin=`0.435` backend=`prototype_matcher`
- `punch_left` at `4442ms` score=`0.790` prototype=`boxing_straight_left_window_02` class=`straight_left` runner-up=`straight_right/boxing_straight_right_window_01 0.342` margin=`0.448` backend=`prototype_matcher`
- `punch_left` at `4741ms` score=`0.789` prototype=`boxing_straight_left_window_03` class=`straight_left` runner-up=`straight_right/boxing_straight_right_window_01 0.347` margin=`0.442` backend=`prototype_matcher`
- `punch_left` at `5038ms` score=`0.819` prototype=`boxing_straight_left_window_03` class=`straight_left` runner-up=`straight_right/boxing_straight_right_window_01 0.366` margin=`0.454` backend=`prototype_matcher`
- `punch_left` at `5357ms` score=`0.812` prototype=`boxing_straight_left_window_01` class=`straight_left` runner-up=`straight_right/boxing_straight_right_window_01 0.639` margin=`0.173` backend=`prototype_matcher`
- `punch_left` at `5672ms` score=`0.846` prototype=`boxing_straight_left_window_04` class=`straight_left` runner-up=`straight_right/boxing_straight_right_window_01 0.595` margin=`0.251` backend=`prototype_matcher`
- `punch_left` at `5981ms` score=`0.885` prototype=`boxing_straight_left_window_01` class=`straight_left` runner-up=`straight_right/boxing_straight_right_window_01 0.645` margin=`0.240` backend=`prototype_matcher`
- `punch_left` at `6292ms` score=`0.828` prototype=`boxing_straight_left_window_04` class=`straight_left` runner-up=`straight_right/boxing_straight_right_window_01 0.604` margin=`0.224` backend=`prototype_matcher`
- `punch_left` at `6592ms` score=`0.716` prototype=`boxing_straight_left_window_03` class=`straight_left` runner-up=`straight_right/boxing_straight_right_window_01 0.369` margin=`0.347` backend=`prototype_matcher`
- `punch_left` at `6902ms` score=`0.743` prototype=`boxing_straight_left_window_03` class=`straight_left` runner-up=`straight_right/boxing_straight_right_window_01 0.306` margin=`0.437` backend=`prototype_matcher`
- `punch_left` at `7210ms` score=`0.785` prototype=`boxing_straight_left_window_03` class=`straight_left` runner-up=`straight_right/boxing_straight_right_window_01 0.352` margin=`0.433` backend=`prototype_matcher`
- `punch_left` at `7516ms` score=`0.805` prototype=`boxing_straight_left_window_03` class=`straight_left` runner-up=`straight_right/boxing_straight_right_window_01 0.375` margin=`0.430` backend=`prototype_matcher`
- `punch_left` at `7823ms` score=`0.800` prototype=`boxing_straight_left_window_03` class=`straight_left` runner-up=`straight_right/boxing_straight_right_window_01 0.380` margin=`0.419` backend=`prototype_matcher`
- `punch_left` at `8126ms` score=`0.803` prototype=`boxing_straight_left_window_03` class=`straight_left` runner-up=`straight_right/boxing_straight_right_window_01 0.413` margin=`0.389` backend=`prototype_matcher`
- `punch_left` at `8437ms` score=`0.799` prototype=`boxing_straight_left_window_03` class=`straight_left` runner-up=`straight_right/boxing_straight_right_window_01 0.431` margin=`0.368` backend=`prototype_matcher`
- `punch_left` at `8741ms` score=`0.821` prototype=`boxing_straight_left_window_03` class=`straight_left` runner-up=`straight_right/boxing_straight_right_window_01 0.433` margin=`0.388` backend=`prototype_matcher`
- `punch_left` at `9048ms` score=`0.804` prototype=`boxing_straight_left_window_03` class=`straight_left` runner-up=`straight_right/boxing_straight_right_window_01 0.380` margin=`0.424` backend=`prototype_matcher`
- `punch_left` at `9358ms` score=`0.791` prototype=`boxing_straight_left_window_03` class=`straight_left` runner-up=`straight_right/boxing_straight_right_window_01 0.354` margin=`0.437` backend=`prototype_matcher`
- `punch_left` at `9659ms` score=`0.779` prototype=`boxing_straight_left_window_03` class=`straight_left` runner-up=`straight_right/boxing_straight_right_window_01 0.342` margin=`0.436` backend=`prototype_matcher`
- `punch_left` at `9954ms` score=`0.815` prototype=`boxing_straight_left_window_03` class=`straight_left` runner-up=`straight_right/boxing_straight_right_window_01 0.359` margin=`0.456` backend=`prototype_matcher`
