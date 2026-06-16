# Prototype Matcher Fixture Benchmark

- Benchmark ID: `prototype_matcher_boxing_fixture_derived_v1_straight_only`
- Library ID: `boxing_side_aware_fixture_derived_v1_straight_only`
- Profile: `boxing`
- Generated At: `2026-06-15T20:55:35-04:00`
- Runner: `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/scripts/run_prototype_matcher_fixture_benchmark.py`

## Aggregate

- Fixture count: **3**
- Negative controls clean: **0 / 1**
- Negative-control false-positive classes: `straight_left` x28, `straight_right` x1
- Negative-control false-positive prototypes: `boxing_straight_left_window_02` x21, `boxing_straight_left_window_03` x4, `boxing_straight_left_window_01` x3, `boxing_straight_right_window_01` x1

## Per Fixture

### straight left

- Fixture: `.testbed/assets/fixtures/boxing/straight_left/boxing_guard->straight_left_repeat_04_take_01.yaml`
- Source: `.testbed/assets/fixtures/boxing/straight_left/boxing_guard->straight_left_repeat_04_take_01.mp4`
- Expected event: `punch_left`
- Expected class: `straight_left`
- Attack events emitted: **29**
- Peak snapshot: straight_left via boxing_straight_left_window_04 score=0.998 runner-up=straight_right/boxing_straight_right_window_01 0.955 margin=0.044
- Strongest expected emit: `punch_left` straight_left via boxing_straight_left_window_01 score=0.994 runner-up=straight_right/boxing_straight_right_window_01 0.969 margin=0.025
- Strongest wrong emit: `punch_right` straight_right via boxing_straight_right_window_01 score=0.978 runner-up=straight_left/boxing_straight_left_window_01 0.969 margin=0.009
- Emitted prototype counts: `boxing_straight_right_window_01` x13, `boxing_straight_left_window_01` x4, `boxing_straight_left_window_04` x4, `boxing_straight_right_window_04` x4, `boxing_straight_left_window_02` x3
- Best-snapshot prototype counts: `boxing_straight_right_window_01` x39, `boxing_straight_left_window_01` x14, `boxing_straight_left_window_04` x10, `boxing_straight_right_window_04` x9, `boxing_straight_left_window_02` x7
- emitted expected punch_left 12 time(s)
- also emitted other attack events: punch_right, punch_right, punch_right, punch_right, punch_right, punch_right, punch_right, punch_right, punch_right, punch_right, punch_right, punch_right, punch_right, punch_right, punch_right, punch_right, punch_right
- peak expected-class score 0.998
- peak winner straight_left via boxing_straight_left_window_04 scored 0.998; runner-up straight_right via boxing_straight_right_window_01 scored 0.955 (margin 0.044)
- strongest expected emit used boxing_straight_left_window_01 at 0.994 over runner-up boxing_straight_right_window_01 at 0.969 (margin 0.025)
- strongest wrong emit was punch_right via boxing_straight_right_window_01 at 0.978 over runner-up boxing_straight_left_window_01 at 0.969 (margin 0.009)
- latest matcher reason emit_cooldown_active

Emitted attack events:
- `punch_right` at `1062ms` score=`0.975` prototype=`boxing_straight_right_window_01` class=`straight_right` runner-up=`straight_left/boxing_straight_left_window_04 0.962` margin=`0.013` backend=`prototype_matcher`
- `punch_right` at `1346ms` score=`0.977` prototype=`boxing_straight_right_window_01` class=`straight_right` runner-up=`straight_left/boxing_straight_left_window_01 0.973` margin=`0.004` backend=`prototype_matcher`
- `punch_right` at `1665ms` score=`0.963` prototype=`boxing_straight_right_window_01` class=`straight_right` runner-up=`straight_left/boxing_straight_left_window_04 0.919` margin=`0.044` backend=`prototype_matcher`
- `punch_right` at `1974ms` score=`0.963` prototype=`boxing_straight_right_window_01` class=`straight_right` runner-up=`straight_left/boxing_straight_left_window_04 0.935` margin=`0.028` backend=`prototype_matcher`
- `punch_left` at `2287ms` score=`0.994` prototype=`boxing_straight_left_window_01` class=`straight_left` runner-up=`straight_right/boxing_straight_right_window_01 0.961` margin=`0.032` backend=`prototype_matcher`
- `punch_left` at `2592ms` score=`0.976` prototype=`boxing_straight_left_window_01` class=`straight_left` runner-up=`straight_right/boxing_straight_right_window_01 0.969` margin=`0.008` backend=`prototype_matcher`
- `punch_right` at `2904ms` score=`0.957` prototype=`boxing_straight_right_window_04` class=`straight_right` runner-up=`straight_left/boxing_straight_left_window_04 0.825` margin=`0.132` backend=`prototype_matcher`
- `punch_right` at `3215ms` score=`0.958` prototype=`boxing_straight_right_window_01` class=`straight_right` runner-up=`straight_left/boxing_straight_left_window_04 0.957` margin=`0.001` backend=`prototype_matcher`
- `punch_left` at `3523ms` score=`0.990` prototype=`boxing_straight_left_window_02` class=`straight_left` runner-up=`straight_right/boxing_straight_right_window_01 0.947` margin=`0.043` backend=`prototype_matcher`
- `punch_left` at `3844ms` score=`0.959` prototype=`boxing_straight_left_window_02` class=`straight_left` runner-up=`straight_right/boxing_straight_right_window_01 0.948` margin=`0.011` backend=`prototype_matcher`
- `punch_right` at `4158ms` score=`0.942` prototype=`boxing_straight_right_window_01` class=`straight_right` runner-up=`straight_left/boxing_straight_left_window_04 0.845` margin=`0.096` backend=`prototype_matcher`
- `punch_left` at `4461ms` score=`0.972` prototype=`boxing_straight_left_window_04` class=`straight_left` runner-up=`straight_right/boxing_straight_right_window_01 0.952` margin=`0.020` backend=`prototype_matcher`
- `punch_left` at `4769ms` score=`0.986` prototype=`boxing_straight_left_window_04` class=`straight_left` runner-up=`straight_right/boxing_straight_right_window_01 0.956` margin=`0.030` backend=`prototype_matcher`
- `punch_left` at `5082ms` score=`0.977` prototype=`boxing_straight_left_window_03` class=`straight_left` runner-up=`straight_right/boxing_straight_right_window_01 0.958` margin=`0.019` backend=`prototype_matcher`
- `punch_right` at `5395ms` score=`0.960` prototype=`boxing_straight_right_window_01` class=`straight_right` runner-up=`straight_left/boxing_straight_left_window_04 0.868` margin=`0.092` backend=`prototype_matcher`
- `punch_right` at `5698ms` score=`0.957` prototype=`boxing_straight_right_window_01` class=`straight_right` runner-up=`straight_left/boxing_straight_left_window_04 0.950` margin=`0.006` backend=`prototype_matcher`
- `punch_left` at `5998ms` score=`0.992` prototype=`boxing_straight_left_window_04` class=`straight_left` runner-up=`straight_right/boxing_straight_right_window_01 0.956` margin=`0.036` backend=`prototype_matcher`
- `punch_left` at `6294ms` score=`0.987` prototype=`boxing_straight_left_window_04` class=`straight_left` runner-up=`straight_right/boxing_straight_right_window_01 0.950` margin=`0.037` backend=`prototype_matcher`
- `punch_right` at `6517ms` score=`0.950` prototype=`boxing_straight_right_window_04` class=`straight_right` runner-up=`straight_left/boxing_straight_left_window_04 0.945` margin=`0.005` backend=`prototype_matcher`
- `punch_right` at `6818ms` score=`0.965` prototype=`boxing_straight_right_window_04` class=`straight_right` runner-up=`straight_left/boxing_straight_left_window_04 0.955` margin=`0.011` backend=`prototype_matcher`
- `punch_right` at `7122ms` score=`0.975` prototype=`boxing_straight_right_window_01` class=`straight_right` runner-up=`straight_left/boxing_straight_left_window_04 0.963` margin=`0.011` backend=`prototype_matcher`
- `punch_right` at `7436ms` score=`0.978` prototype=`boxing_straight_right_window_01` class=`straight_right` runner-up=`straight_left/boxing_straight_left_window_01 0.969` margin=`0.009` backend=`prototype_matcher`
- `punch_right` at `7740ms` score=`0.969` prototype=`boxing_straight_right_window_01` class=`straight_right` runner-up=`straight_left/boxing_straight_left_window_04 0.946` margin=`0.023` backend=`prototype_matcher`
- `punch_right` at `8069ms` score=`0.954` prototype=`boxing_straight_right_window_01` class=`straight_right` runner-up=`straight_left/boxing_straight_left_window_04 0.876` margin=`0.078` backend=`prototype_matcher`
- `punch_left` at `8424ms` score=`0.986` prototype=`boxing_straight_left_window_01` class=`straight_left` runner-up=`straight_right/boxing_straight_right_window_01 0.963` margin=`0.023` backend=`prototype_matcher`
- `punch_left` at `8784ms` score=`0.994` prototype=`boxing_straight_left_window_01` class=`straight_left` runner-up=`straight_right/boxing_straight_right_window_01 0.969` margin=`0.025` backend=`prototype_matcher`
- `punch_right` at `9124ms` score=`0.963` prototype=`boxing_straight_right_window_04` class=`straight_right` runner-up=`straight_left/boxing_straight_left_window_04 0.886` margin=`0.077` backend=`prototype_matcher`
- `punch_right` at `9470ms` score=`0.963` prototype=`boxing_straight_right_window_01` class=`straight_right` runner-up=`straight_left/boxing_straight_left_window_04 0.871` margin=`0.092` backend=`prototype_matcher`
- `punch_left` at `9815ms` score=`0.988` prototype=`boxing_straight_left_window_02` class=`straight_left` runner-up=`straight_right/boxing_straight_right_window_01 0.943` margin=`0.045` backend=`prototype_matcher`

### straight right

- Fixture: `.testbed/assets/fixtures/boxing/straight_right/boxing_guard->straight_right_repeat_04_take_01.yaml`
- Source: `.testbed/assets/fixtures/boxing/straight_right/boxing_guard->straight_right_repeat_04_take_01.mp4`
- Expected event: `punch_right`
- Expected class: `straight_right`
- Attack events emitted: **36**
- Peak snapshot: straight_right via boxing_straight_right_window_01 score=1.000 runner-up=straight_left/boxing_straight_left_window_01 0.949 margin=0.051
- Strongest expected emit: `punch_right` straight_right via boxing_straight_right_window_01 score=1.000 runner-up=straight_left/boxing_straight_left_window_01 0.949 margin=0.051
- Strongest wrong emit: `punch_left` straight_left via boxing_straight_left_window_01 score=0.979 runner-up=straight_right/boxing_straight_right_window_01 0.976 margin=0.003
- Emitted prototype counts: `boxing_straight_right_window_04` x17, `boxing_straight_left_window_01` x12, `boxing_straight_right_window_01` x4, `boxing_straight_right_window_03` x2, `boxing_straight_right_window_02` x1
- Best-snapshot prototype counts: `boxing_straight_right_window_04` x34, `boxing_straight_left_window_01` x24, `boxing_straight_right_window_01` x7, `boxing_straight_right_window_03` x4, `boxing_straight_right_window_02` x2
- emitted expected punch_right 24 time(s)
- also emitted other attack events: punch_left, punch_left, punch_left, punch_left, punch_left, punch_left, punch_left, punch_left, punch_left, punch_left, punch_left, punch_left
- peak expected-class score 1.000
- peak winner straight_right via boxing_straight_right_window_01 scored 1.000; runner-up straight_left via boxing_straight_left_window_01 scored 0.949 (margin 0.051)
- strongest expected emit used boxing_straight_right_window_01 at 1.000 over runner-up boxing_straight_left_window_01 at 0.949 (margin 0.051)
- strongest wrong emit was punch_left via boxing_straight_left_window_01 at 0.979 over runner-up boxing_straight_right_window_01 at 0.976 (margin 0.003)
- latest matcher reason step_wait

Emitted attack events:
- `punch_right` at `1085ms` score=`0.973` prototype=`boxing_straight_right_window_04` class=`straight_right` runner-up=`straight_left/boxing_straight_left_window_01 0.951` margin=`0.022` backend=`prototype_matcher`
- `punch_right` at `1235ms` score=`0.980` prototype=`boxing_straight_right_window_04` class=`straight_right` runner-up=`straight_left/boxing_straight_left_window_01 0.959` margin=`0.021` backend=`prototype_matcher`
- `punch_right` at `1466ms` score=`0.981` prototype=`boxing_straight_right_window_01` class=`straight_right` runner-up=`straight_left/boxing_straight_left_window_01 0.958` margin=`0.023` backend=`prototype_matcher`
- `punch_right` at `1714ms` score=`1.000` prototype=`boxing_straight_right_window_01` class=`straight_right` runner-up=`straight_left/boxing_straight_left_window_01 0.949` margin=`0.051` backend=`prototype_matcher`
- `punch_left` at `1974ms` score=`0.928` prototype=`boxing_straight_left_window_01` class=`straight_left` runner-up=`straight_right/boxing_straight_right_window_03 0.910` margin=`0.018` backend=`prototype_matcher`
- `punch_left` at `2214ms` score=`0.943` prototype=`boxing_straight_left_window_01` class=`straight_left` runner-up=`straight_right/boxing_straight_right_window_04 0.941` margin=`0.002` backend=`prototype_matcher`
- `punch_right` at `2464ms` score=`0.972` prototype=`boxing_straight_right_window_04` class=`straight_right` runner-up=`straight_left/boxing_straight_left_window_01 0.969` margin=`0.003` backend=`prototype_matcher`
- `punch_left` at `2714ms` score=`0.976` prototype=`boxing_straight_left_window_01` class=`straight_left` runner-up=`straight_right/boxing_straight_right_window_01 0.976` margin=`0.000` backend=`prototype_matcher`
- `punch_right` at `2968ms` score=`0.985` prototype=`boxing_straight_right_window_04` class=`straight_right` runner-up=`straight_left/boxing_straight_left_window_01 0.975` margin=`0.010` backend=`prototype_matcher`
- `punch_left` at `3225ms` score=`0.947` prototype=`boxing_straight_left_window_01` class=`straight_left` runner-up=`straight_right/boxing_straight_right_window_03 0.938` margin=`0.009` backend=`prototype_matcher`
- `punch_left` at `3477ms` score=`0.923` prototype=`boxing_straight_left_window_01` class=`straight_left` runner-up=`straight_right/boxing_straight_right_window_03 0.895` margin=`0.028` backend=`prototype_matcher`
- `punch_right` at `3718ms` score=`0.979` prototype=`boxing_straight_right_window_04` class=`straight_right` runner-up=`straight_left/boxing_straight_left_window_01 0.943` margin=`0.036` backend=`prototype_matcher`
- `punch_right` at `3967ms` score=`0.990` prototype=`boxing_straight_right_window_04` class=`straight_right` runner-up=`straight_left/boxing_straight_left_window_01 0.967` margin=`0.023` backend=`prototype_matcher`
- `punch_right` at `4216ms` score=`0.992` prototype=`boxing_straight_right_window_04` class=`straight_right` runner-up=`straight_left/boxing_straight_left_window_01 0.965` margin=`0.027` backend=`prototype_matcher`
- `punch_right` at `4466ms` score=`0.972` prototype=`boxing_straight_right_window_03` class=`straight_right` runner-up=`straight_left/boxing_straight_left_window_01 0.954` margin=`0.018` backend=`prototype_matcher`
- `punch_left` at `4717ms` score=`0.932` prototype=`boxing_straight_left_window_01` class=`straight_left` runner-up=`straight_right/boxing_straight_right_window_03 0.858` margin=`0.074` backend=`prototype_matcher`
- `punch_left` at `4968ms` score=`0.939` prototype=`boxing_straight_left_window_01` class=`straight_left` runner-up=`straight_right/boxing_straight_right_window_04 0.935` margin=`0.003` backend=`prototype_matcher`
- `punch_right` at `5220ms` score=`0.989` prototype=`boxing_straight_right_window_04` class=`straight_right` runner-up=`straight_left/boxing_straight_left_window_01 0.961` margin=`0.028` backend=`prototype_matcher`
- `punch_right` at `5467ms` score=`0.991` prototype=`boxing_straight_right_window_04` class=`straight_right` runner-up=`straight_left/boxing_straight_left_window_01 0.973` margin=`0.018` backend=`prototype_matcher`
- `punch_right` at `5717ms` score=`0.993` prototype=`boxing_straight_right_window_04` class=`straight_right` runner-up=`straight_left/boxing_straight_left_window_01 0.971` margin=`0.022` backend=`prototype_matcher`
- `punch_right` at `6076ms` score=`0.982` prototype=`boxing_straight_right_window_04` class=`straight_right` runner-up=`straight_left/boxing_straight_left_window_01 0.947` margin=`0.035` backend=`prototype_matcher`
- `punch_right` at `6315ms` score=`0.975` prototype=`boxing_straight_right_window_01` class=`straight_right` runner-up=`straight_left/boxing_straight_left_window_01 0.942` margin=`0.034` backend=`prototype_matcher`
- `punch_left` at `6566ms` score=`0.930` prototype=`boxing_straight_left_window_01` class=`straight_left` runner-up=`straight_right/boxing_straight_right_window_03 0.889` margin=`0.041` backend=`prototype_matcher`
- `punch_right` at `6819ms` score=`0.952` prototype=`boxing_straight_right_window_04` class=`straight_right` runner-up=`straight_left/boxing_straight_left_window_01 0.941` margin=`0.011` backend=`prototype_matcher`
- `punch_right` at `7070ms` score=`0.978` prototype=`boxing_straight_right_window_04` class=`straight_right` runner-up=`straight_left/boxing_straight_left_window_01 0.960` margin=`0.018` backend=`prototype_matcher`
- `punch_right` at `7315ms` score=`0.981` prototype=`boxing_straight_right_window_04` class=`straight_right` runner-up=`straight_left/boxing_straight_left_window_01 0.958` margin=`0.023` backend=`prototype_matcher`
- `punch_right` at `7567ms` score=`0.984` prototype=`boxing_straight_right_window_01` class=`straight_right` runner-up=`straight_left/boxing_straight_left_window_01 0.957` margin=`0.027` backend=`prototype_matcher`
- `punch_right` at `7816ms` score=`0.955` prototype=`boxing_straight_right_window_03` class=`straight_right` runner-up=`straight_left/boxing_straight_left_window_01 0.932` margin=`0.024` backend=`prototype_matcher`
- `punch_left` at `8078ms` score=`0.931` prototype=`boxing_straight_left_window_01` class=`straight_left` runner-up=`straight_right/boxing_straight_right_window_03 0.877` margin=`0.055` backend=`prototype_matcher`
- `punch_right` at `8318ms` score=`0.976` prototype=`boxing_straight_right_window_04` class=`straight_right` runner-up=`straight_left/boxing_straight_left_window_01 0.953` margin=`0.022` backend=`prototype_matcher`
- `punch_left` at `8567ms` score=`0.975` prototype=`boxing_straight_left_window_01` class=`straight_left` runner-up=`straight_right/boxing_straight_right_window_01 0.972` margin=`0.003` backend=`prototype_matcher`
- `punch_left` at `8817ms` score=`0.979` prototype=`boxing_straight_left_window_01` class=`straight_left` runner-up=`straight_right/boxing_straight_right_window_01 0.976` margin=`0.003` backend=`prototype_matcher`
- `punch_right` at `9067ms` score=`0.980` prototype=`boxing_straight_right_window_02` class=`straight_right` runner-up=`straight_left/boxing_straight_left_window_01 0.964` margin=`0.016` backend=`prototype_matcher`
- `punch_left` at `9316ms` score=`0.931` prototype=`boxing_straight_left_window_01` class=`straight_left` runner-up=`straight_right/boxing_straight_right_window_03 0.881` margin=`0.050` backend=`prototype_matcher`
- `punch_right` at `9567ms` score=`0.949` prototype=`boxing_straight_right_window_04` class=`straight_right` runner-up=`straight_left/boxing_straight_left_window_01 0.930` margin=`0.019` backend=`prototype_matcher`
- `punch_right` at `9818ms` score=`0.987` prototype=`boxing_straight_right_window_04` class=`straight_right` runner-up=`straight_left/boxing_straight_left_window_01 0.958` margin=`0.029` backend=`prototype_matcher`

### negative control - running in place

- Fixture: `.testbed/assets/fixtures/boxing/run_in_place/boxing_guard->run_in_place_repeat_01_take_01.yaml`
- Source: `.testbed/assets/fixtures/boxing/run_in_place/boxing_guard->run_in_place_repeat_01_take_01.mp4`
- Expected event: `None`
- Expected class: `None`
- Attack events emitted: **29**
- Peak snapshot: straight_left via boxing_straight_left_window_03 score=0.973 runner-up=straight_right/boxing_straight_right_window_01 0.938 margin=0.035
- Strongest wrong emit: `punch_left` straight_left via boxing_straight_left_window_02 score=0.971 runner-up=straight_right/boxing_straight_right_window_01 0.901 margin=0.070
- Emitted prototype counts: `boxing_straight_left_window_02` x21, `boxing_straight_left_window_03` x4, `boxing_straight_left_window_01` x3, `boxing_straight_right_window_01` x1
- Best-snapshot prototype counts: `boxing_straight_left_window_02` x62, `boxing_straight_left_window_03` x11, `boxing_straight_left_window_01` x8, `boxing_straight_right_window_01` x5
- negative control still emitted attack events: punch_left, punch_left, punch_left, punch_left, punch_left, punch_left, punch_left, punch_left, punch_left, punch_left, punch_left, punch_left, punch_left, punch_left, punch_left, punch_left, punch_left, punch_left, punch_right, punch_left, punch_left, punch_left, punch_left, punch_left, punch_left, punch_left, punch_left, punch_left, punch_left
- peak winner straight_left via boxing_straight_left_window_03 scored 0.973; runner-up straight_right via boxing_straight_right_window_01 scored 0.938 (margin 0.035)
- strongest wrong emit was punch_left via boxing_straight_left_window_02 at 0.971 over runner-up boxing_straight_right_window_01 at 0.901 (margin 0.070)
- latest matcher reason step_wait

Emitted attack events:
- `punch_left` at `1092ms` score=`0.939` prototype=`boxing_straight_left_window_02` class=`straight_left` runner-up=`straight_right/boxing_straight_right_window_01 0.933` margin=`0.006` backend=`prototype_matcher`
- `punch_left` at `1339ms` score=`0.944` prototype=`boxing_straight_left_window_03` class=`straight_left` runner-up=`straight_right/boxing_straight_right_window_01 0.943` margin=`0.001` backend=`prototype_matcher`
- `punch_left` at `1648ms` score=`0.920` prototype=`boxing_straight_left_window_03` class=`straight_left` runner-up=`straight_right/boxing_straight_right_window_01 0.916` margin=`0.004` backend=`prototype_matcher`
- `punch_left` at `1956ms` score=`0.933` prototype=`boxing_straight_left_window_02` class=`straight_left` runner-up=`straight_right/boxing_straight_right_window_01 0.906` margin=`0.028` backend=`prototype_matcher`
- `punch_left` at `2274ms` score=`0.946` prototype=`boxing_straight_left_window_02` class=`straight_left` runner-up=`straight_right/boxing_straight_right_window_01 0.907` margin=`0.039` backend=`prototype_matcher`
- `punch_left` at `2579ms` score=`0.954` prototype=`boxing_straight_left_window_02` class=`straight_left` runner-up=`straight_right/boxing_straight_right_window_01 0.906` margin=`0.047` backend=`prototype_matcher`
- `punch_left` at `2889ms` score=`0.958` prototype=`boxing_straight_left_window_02` class=`straight_left` runner-up=`straight_right/boxing_straight_right_window_01 0.900` margin=`0.058` backend=`prototype_matcher`
- `punch_left` at `3199ms` score=`0.963` prototype=`boxing_straight_left_window_02` class=`straight_left` runner-up=`straight_right/boxing_straight_right_window_01 0.890` margin=`0.072` backend=`prototype_matcher`
- `punch_left` at `3506ms` score=`0.962` prototype=`boxing_straight_left_window_02` class=`straight_left` runner-up=`straight_right/boxing_straight_right_window_01 0.898` margin=`0.064` backend=`prototype_matcher`
- `punch_left` at `3814ms` score=`0.970` prototype=`boxing_straight_left_window_02` class=`straight_left` runner-up=`straight_right/boxing_straight_right_window_01 0.902` margin=`0.068` backend=`prototype_matcher`
- `punch_left` at `4120ms` score=`0.962` prototype=`boxing_straight_left_window_02` class=`straight_left` runner-up=`straight_right/boxing_straight_right_window_01 0.911` margin=`0.050` backend=`prototype_matcher`
- `punch_left` at `4428ms` score=`0.960` prototype=`boxing_straight_left_window_02` class=`straight_left` runner-up=`straight_right/boxing_straight_right_window_01 0.913` margin=`0.047` backend=`prototype_matcher`
- `punch_left` at `4730ms` score=`0.968` prototype=`boxing_straight_left_window_02` class=`straight_left` runner-up=`straight_right/boxing_straight_right_window_01 0.924` margin=`0.044` backend=`prototype_matcher`
- `punch_left` at `5028ms` score=`0.971` prototype=`boxing_straight_left_window_03` class=`straight_left` runner-up=`straight_right/boxing_straight_right_window_01 0.933` margin=`0.038` backend=`prototype_matcher`
- `punch_left` at `5368ms` score=`0.963` prototype=`boxing_straight_left_window_01` class=`straight_left` runner-up=`straight_right/boxing_straight_right_window_01 0.926` margin=`0.036` backend=`prototype_matcher`
- `punch_left` at `5653ms` score=`0.967` prototype=`boxing_straight_left_window_01` class=`straight_left` runner-up=`straight_right/boxing_straight_right_window_01 0.933` margin=`0.034` backend=`prototype_matcher`
- `punch_left` at `5965ms` score=`0.952` prototype=`boxing_straight_left_window_01` class=`straight_left` runner-up=`straight_right/boxing_straight_right_window_01 0.933` margin=`0.018` backend=`prototype_matcher`
- `punch_left` at `6276ms` score=`0.952` prototype=`boxing_straight_left_window_03` class=`straight_left` runner-up=`straight_right/boxing_straight_right_window_01 0.944` margin=`0.007` backend=`prototype_matcher`
- `punch_right` at `6586ms` score=`0.924` prototype=`boxing_straight_right_window_01` class=`straight_right` runner-up=`straight_left/boxing_straight_left_window_03 0.923` margin=`0.001` backend=`prototype_matcher`
- `punch_left` at `6890ms` score=`0.924` prototype=`boxing_straight_left_window_02` class=`straight_left` runner-up=`straight_right/boxing_straight_right_window_04 0.907` margin=`0.016` backend=`prototype_matcher`
- `punch_left` at `7198ms` score=`0.945` prototype=`boxing_straight_left_window_02` class=`straight_left` runner-up=`straight_right/boxing_straight_right_window_01 0.904` margin=`0.041` backend=`prototype_matcher`
- `punch_left` at `7507ms` score=`0.951` prototype=`boxing_straight_left_window_02` class=`straight_left` runner-up=`straight_right/boxing_straight_right_window_01 0.904` margin=`0.047` backend=`prototype_matcher`
- `punch_left` at `7821ms` score=`0.957` prototype=`boxing_straight_left_window_02` class=`straight_left` runner-up=`straight_right/boxing_straight_right_window_01 0.900` margin=`0.057` backend=`prototype_matcher`
- `punch_left` at `8123ms` score=`0.961` prototype=`boxing_straight_left_window_02` class=`straight_left` runner-up=`straight_right/boxing_straight_right_window_01 0.897` margin=`0.065` backend=`prototype_matcher`
- `punch_left` at `8440ms` score=`0.959` prototype=`boxing_straight_left_window_02` class=`straight_left` runner-up=`straight_right/boxing_straight_right_window_01 0.893` margin=`0.066` backend=`prototype_matcher`
- `punch_left` at `8767ms` score=`0.971` prototype=`boxing_straight_left_window_02` class=`straight_left` runner-up=`straight_right/boxing_straight_right_window_01 0.901` margin=`0.070` backend=`prototype_matcher`
- `punch_left` at `9078ms` score=`0.963` prototype=`boxing_straight_left_window_02` class=`straight_left` runner-up=`straight_right/boxing_straight_right_window_01 0.904` margin=`0.059` backend=`prototype_matcher`
- `punch_left` at `9386ms` score=`0.960` prototype=`boxing_straight_left_window_02` class=`straight_left` runner-up=`straight_right/boxing_straight_right_window_01 0.912` margin=`0.048` backend=`prototype_matcher`
- `punch_left` at `9685ms` score=`0.966` prototype=`boxing_straight_left_window_02` class=`straight_left` runner-up=`straight_right/boxing_straight_right_window_01 0.916` margin=`0.050` backend=`prototype_matcher`
