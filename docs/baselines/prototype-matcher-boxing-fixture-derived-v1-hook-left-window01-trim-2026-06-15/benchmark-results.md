# Prototype Matcher Fixture Benchmark

- Benchmark ID: `prototype_matcher_boxing_fixture_derived_v1`
- Library ID: `boxing_side_aware_fixture_derived_v1`
- Profile: `boxing`
- Generated At: `2026-06-15T15:57:28-04:00`
- Runner: `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/scripts/run_prototype_matcher_fixture_benchmark.py`

## Aggregate

- Fixture count: **7**
- Negative controls clean: **0 / 1**
- Negative-control false-positive classes: `hook_left` x23, `straight_left` x4, `hook_right` x2
- Negative-control false-positive prototypes: `boxing_hook_left_window_01` x23, `boxing_hook_right_window_03` x2, `boxing_straight_left_window_01` x2, `boxing_straight_left_window_02` x1, `boxing_straight_left_window_04` x1

## Per Fixture

### straight left

- Fixture: `.testbed/assets/fixtures/boxing/straight_left/boxing_guard->straight_left_repeat_04_take_01.yaml`
- Source: `.testbed/assets/fixtures/boxing/straight_left/boxing_guard->straight_left_repeat_04_take_01.mp4`
- Expected event: `punch_left`
- Expected class: `straight_left`
- Attack events emitted: **29**
- Peak snapshot: straight_left via boxing_straight_left_window_01 score=1.000 runner-up=uppercut_right/boxing_uppercut_right_window_04 0.921 margin=0.079
- Strongest expected emit: `punch_left` straight_left via boxing_straight_left_window_01 score=1.000 runner-up=uppercut_right/boxing_uppercut_right_window_04 0.921 margin=0.079
- Strongest wrong emit: `hook_right` hook_right via boxing_hook_right_window_01 score=0.927 runner-up=straight_left/boxing_straight_left_window_04 0.926 margin=0.001
- Emitted prototype counts: `boxing_uppercut_right_window_04` x10, `boxing_straight_left_window_01` x6, `boxing_uppercut_left_window_02` x5, `boxing_hook_right_window_01` x3, `boxing_straight_left_window_03` x2
- Best-snapshot prototype counts: `boxing_uppercut_right_window_04` x32, `boxing_straight_left_window_01` x16, `boxing_uppercut_left_window_02` x14, `boxing_hook_right_window_01` x6, `boxing_straight_left_window_03` x6
- emitted expected punch_left 9 time(s)
- also emitted other attack events: uppercut_left, uppercut_right, uppercut_right, uppercut_right, uppercut_right, hook_right, hook_right, uppercut_right, hook_right, uppercut_right, uppercut_right, uppercut_right, uppercut_left, uppercut_left, uppercut_left, uppercut_left, uppercut_right, uppercut_right, uppercut_right, uppercut_right
- peak expected-class score 1.000
- peak winner straight_left via boxing_straight_left_window_01 scored 1.000; runner-up uppercut_right via boxing_uppercut_right_window_04 scored 0.921 (margin 0.079)
- strongest expected emit used boxing_straight_left_window_01 at 1.000 over runner-up boxing_uppercut_right_window_04 at 0.921 (margin 0.079)
- strongest wrong emit was hook_right via boxing_hook_right_window_01 at 0.927 over runner-up boxing_straight_left_window_04 at 0.926 (margin 0.001)
- latest matcher reason step_wait

Emitted attack events:
- `uppercut_left` at `1151ms` score=`0.900` prototype=`boxing_uppercut_left_window_02` class=`uppercut_left` runner-up=`uppercut_right/boxing_uppercut_right_window_04 0.857` margin=`0.043` backend=`prototype_matcher`
- `uppercut_right` at `1367ms` score=`0.888` prototype=`boxing_uppercut_right_window_04` class=`uppercut_right` runner-up=`uppercut_left/boxing_uppercut_left_window_02 0.884` margin=`0.004` backend=`prototype_matcher`
- `uppercut_right` at `1690ms` score=`0.756` prototype=`boxing_uppercut_right_window_04` class=`uppercut_right` runner-up=`hook_right/boxing_hook_right_window_01 0.729` margin=`0.027` backend=`prototype_matcher`
- `punch_left` at `1988ms` score=`0.802` prototype=`boxing_straight_left_window_01` class=`straight_left` runner-up=`uppercut_right/boxing_uppercut_right_window_04 0.769` margin=`0.033` backend=`prototype_matcher`
- `punch_left` at `2304ms` score=`0.915` prototype=`boxing_straight_left_window_01` class=`straight_left` runner-up=`uppercut_right/boxing_uppercut_right_window_04 0.911` margin=`0.005` backend=`prototype_matcher`
- `uppercut_right` at `2621ms` score=`0.907` prototype=`boxing_uppercut_right_window_04` class=`uppercut_right` runner-up=`straight_left/boxing_straight_left_window_01 0.884` margin=`0.023` backend=`prototype_matcher`
- `uppercut_right` at `2941ms` score=`0.801` prototype=`boxing_uppercut_right_window_04` class=`uppercut_right` runner-up=`hook_right/boxing_hook_right_window_01 0.743` margin=`0.059` backend=`prototype_matcher`
- `hook_right` at `3254ms` score=`0.789` prototype=`boxing_hook_right_window_01` class=`hook_right` runner-up=`uppercut_right/boxing_uppercut_right_window_04 0.787` margin=`0.002` backend=`prototype_matcher`
- `hook_right` at `3566ms` score=`0.927` prototype=`boxing_hook_right_window_01` class=`hook_right` runner-up=`straight_left/boxing_straight_left_window_04 0.926` margin=`0.001` backend=`prototype_matcher`
- `uppercut_right` at `3885ms` score=`0.866` prototype=`boxing_uppercut_right_window_03` class=`uppercut_right` runner-up=`hook_right/boxing_hook_right_window_01 0.847` margin=`0.019` backend=`prototype_matcher`
- `hook_right` at `4205ms` score=`0.818` prototype=`boxing_hook_right_window_01` class=`hook_right` runner-up=`uppercut_right/boxing_uppercut_right_window_04 0.811` margin=`0.007` backend=`prototype_matcher`
- `uppercut_right` at `4512ms` score=`0.868` prototype=`boxing_uppercut_right_window_03` class=`uppercut_right` runner-up=`straight_left/boxing_straight_left_window_04 0.856` margin=`0.012` backend=`prototype_matcher`
- `punch_left` at `4818ms` score=`0.948` prototype=`boxing_straight_left_window_03` class=`straight_left` runner-up=`uppercut_right/boxing_uppercut_right_window_03 0.916` margin=`0.032` backend=`prototype_matcher`
- `punch_left` at `5137ms` score=`0.876` prototype=`boxing_straight_left_window_03` class=`straight_left` runner-up=`uppercut_right/boxing_uppercut_right_window_03 0.872` margin=`0.004` backend=`prototype_matcher`
- `uppercut_right` at `5454ms` score=`0.839` prototype=`boxing_uppercut_right_window_04` class=`uppercut_right` runner-up=`hook_right/boxing_hook_right_window_01 0.821` margin=`0.018` backend=`prototype_matcher`
- `uppercut_right` at `5767ms` score=`0.868` prototype=`boxing_uppercut_right_window_04` class=`uppercut_right` runner-up=`hook_right/boxing_hook_right_window_01 0.831` margin=`0.037` backend=`prototype_matcher`
- `punch_left` at `6102ms` score=`0.960` prototype=`boxing_straight_left_window_04` class=`straight_left` runner-up=`uppercut_right/boxing_uppercut_right_window_03 0.919` margin=`0.042` backend=`prototype_matcher`
- `punch_left` at `6400ms` score=`0.934` prototype=`boxing_straight_left_window_01` class=`straight_left` runner-up=`uppercut_right/boxing_uppercut_right_window_04 0.924` margin=`0.010` backend=`prototype_matcher`
- `uppercut_left` at `6610ms` score=`0.904` prototype=`boxing_uppercut_left_window_02` class=`uppercut_left` runner-up=`uppercut_right/boxing_uppercut_right_window_04 0.878` margin=`0.025` backend=`prototype_matcher`
- `uppercut_left` at `6826ms` score=`0.872` prototype=`boxing_uppercut_left_window_02` class=`uppercut_left` runner-up=`uppercut_right/boxing_uppercut_right_window_04 0.859` margin=`0.012` backend=`prototype_matcher`
- `uppercut_left` at `7135ms` score=`0.901` prototype=`boxing_uppercut_left_window_02` class=`uppercut_left` runner-up=`uppercut_right/boxing_uppercut_right_window_04 0.874` margin=`0.027` backend=`prototype_matcher`
- `uppercut_left` at `7450ms` score=`0.915` prototype=`boxing_uppercut_left_window_02` class=`uppercut_left` runner-up=`uppercut_right/boxing_uppercut_right_window_04 0.882` margin=`0.033` backend=`prototype_matcher`
- `uppercut_right` at `7750ms` score=`0.893` prototype=`boxing_uppercut_right_window_04` class=`uppercut_right` runner-up=`hook_right/boxing_hook_right_window_01 0.830` margin=`0.063` backend=`prototype_matcher`
- `uppercut_right` at `8082ms` score=`0.740` prototype=`boxing_uppercut_right_window_04` class=`uppercut_right` runner-up=`hook_right/boxing_hook_right_window_01 0.714` margin=`0.026` backend=`prototype_matcher`
- `punch_left` at `8430ms` score=`0.883` prototype=`boxing_straight_left_window_01` class=`straight_left` runner-up=`uppercut_right/boxing_uppercut_right_window_04 0.811` margin=`0.072` backend=`prototype_matcher`
- `punch_left` at `8783ms` score=`1.000` prototype=`boxing_straight_left_window_01` class=`straight_left` runner-up=`uppercut_right/boxing_uppercut_right_window_04 0.921` margin=`0.079` backend=`prototype_matcher`
- `uppercut_right` at `9149ms` score=`0.876` prototype=`boxing_uppercut_right_window_04` class=`uppercut_right` runner-up=`hook_right/boxing_hook_right_window_01 0.835` margin=`0.041` backend=`prototype_matcher`
- `uppercut_right` at `9481ms` score=`0.800` prototype=`boxing_uppercut_right_window_04` class=`uppercut_right` runner-up=`hook_right/boxing_hook_right_window_01 0.741` margin=`0.059` backend=`prototype_matcher`
- `punch_left` at `9830ms` score=`0.939` prototype=`boxing_straight_left_window_01` class=`straight_left` runner-up=`uppercut_right/boxing_uppercut_right_window_04 0.867` margin=`0.073` backend=`prototype_matcher`

### straight right

- Fixture: `.testbed/assets/fixtures/boxing/straight_right/boxing_guard->straight_right_repeat_04_take_01.yaml`
- Source: `.testbed/assets/fixtures/boxing/straight_right/boxing_guard->straight_right_repeat_04_take_01.mp4`
- Expected event: `punch_right`
- Expected class: `straight_right`
- Attack events emitted: **33**
- Peak snapshot: straight_right via boxing_straight_right_window_01 score=1.000 runner-up=uppercut_right/boxing_uppercut_right_window_01 0.861 margin=0.139
- Strongest expected emit: `punch_right` straight_right via boxing_straight_right_window_01 score=1.000 runner-up=uppercut_right/boxing_uppercut_right_window_01 0.861 margin=0.139
- Strongest wrong emit: `uppercut_left` uppercut_left via boxing_uppercut_left_window_02 score=0.827 runner-up=straight_right/boxing_straight_right_window_04 0.791 margin=0.036
- Emitted prototype counts: `boxing_straight_right_window_04` x20, `boxing_uppercut_left_window_02` x4, `boxing_straight_right_window_01` x3, `boxing_straight_right_window_02` x3, `boxing_uppercut_left_window_03` x2
- Best-snapshot prototype counts: `boxing_straight_right_window_04` x35, `boxing_uppercut_left_window_02` x13, `boxing_straight_right_window_01` x8, `boxing_uppercut_left_window_03` x7, `boxing_straight_right_window_02` x5
- emitted expected punch_right 27 time(s)
- also emitted other attack events: uppercut_left, uppercut_left, uppercut_left, uppercut_left, uppercut_left, uppercut_left
- peak expected-class score 1.000
- peak winner straight_right via boxing_straight_right_window_01 scored 1.000; runner-up uppercut_right via boxing_uppercut_right_window_01 scored 0.861 (margin 0.139)
- strongest expected emit used boxing_straight_right_window_01 at 1.000 over runner-up boxing_uppercut_right_window_01 at 0.861 (margin 0.139)
- strongest wrong emit was uppercut_left via boxing_uppercut_left_window_02 at 0.827 over runner-up boxing_straight_right_window_04 at 0.791 (margin 0.036)
- latest matcher reason emit_cooldown_active

Emitted attack events:
- `punch_right` at `1110ms` score=`0.834` prototype=`boxing_straight_right_window_04` class=`straight_right` runner-up=`uppercut_left/boxing_uppercut_left_window_03 0.738` margin=`0.096` backend=`prototype_matcher`
- `punch_right` at `1231ms` score=`0.870` prototype=`boxing_straight_right_window_04` class=`straight_right` runner-up=`uppercut_left/boxing_uppercut_left_window_03 0.746` margin=`0.124` backend=`prototype_matcher`
- `punch_right` at `1465ms` score=`0.913` prototype=`boxing_straight_right_window_01` class=`straight_right` runner-up=`uppercut_right/boxing_uppercut_right_window_01 0.802` margin=`0.111` backend=`prototype_matcher`
- `punch_right` at `1715ms` score=`1.000` prototype=`boxing_straight_right_window_01` class=`straight_right` runner-up=`uppercut_right/boxing_uppercut_right_window_01 0.861` margin=`0.139` backend=`prototype_matcher`
- `uppercut_left` at `2217ms` score=`0.827` prototype=`boxing_uppercut_left_window_02` class=`uppercut_left` runner-up=`straight_right/boxing_straight_right_window_04 0.791` margin=`0.036` backend=`prototype_matcher`
- `punch_right` at `2465ms` score=`0.903` prototype=`boxing_straight_right_window_04` class=`straight_right` runner-up=`uppercut_left/boxing_uppercut_left_window_02 0.822` margin=`0.081` backend=`prototype_matcher`
- `punch_right` at `2717ms` score=`0.852` prototype=`boxing_straight_right_window_04` class=`straight_right` runner-up=`uppercut_left/boxing_uppercut_left_window_02 0.846` margin=`0.007` backend=`prototype_matcher`
- `punch_right` at `2968ms` score=`0.937` prototype=`boxing_straight_right_window_02` class=`straight_right` runner-up=`uppercut_left/boxing_uppercut_left_window_02 0.848` margin=`0.089` backend=`prototype_matcher`
- `uppercut_left` at `3228ms` score=`0.745` prototype=`boxing_uppercut_left_window_03` class=`uppercut_left` runner-up=`straight_right/boxing_straight_right_window_02 0.702` margin=`0.043` backend=`prototype_matcher`
- `punch_right` at `3592ms` score=`0.824` prototype=`boxing_straight_right_window_04` class=`straight_right` runner-up=`uppercut_left/boxing_uppercut_left_window_02 0.805` margin=`0.019` backend=`prototype_matcher`
- `punch_right` at `3845ms` score=`0.913` prototype=`boxing_straight_right_window_04` class=`straight_right` runner-up=`uppercut_left/boxing_uppercut_left_window_02 0.802` margin=`0.111` backend=`prototype_matcher`
- `punch_right` at `4092ms` score=`0.915` prototype=`boxing_straight_right_window_04` class=`straight_right` runner-up=`uppercut_right/boxing_uppercut_right_window_01 0.869` margin=`0.046` backend=`prototype_matcher`
- `punch_right` at `4343ms` score=`0.891` prototype=`boxing_straight_right_window_04` class=`straight_right` runner-up=`uppercut_left/boxing_uppercut_left_window_03 0.764` margin=`0.127` backend=`prototype_matcher`
- `uppercut_left` at `4608ms` score=`0.728` prototype=`boxing_uppercut_left_window_02` class=`uppercut_left` runner-up=`straight_left/boxing_straight_left_window_01 0.639` margin=`0.089` backend=`prototype_matcher`
- `uppercut_left` at `4855ms` score=`0.755` prototype=`boxing_uppercut_left_window_02` class=`uppercut_left` runner-up=`straight_left/boxing_straight_left_window_01 0.655` margin=`0.100` backend=`prototype_matcher`
- `punch_right` at `5094ms` score=`0.923` prototype=`boxing_straight_right_window_04` class=`straight_right` runner-up=`uppercut_left/boxing_uppercut_left_window_03 0.791` margin=`0.132` backend=`prototype_matcher`
- `punch_right` at `5343ms` score=`0.949` prototype=`boxing_straight_right_window_04` class=`straight_right` runner-up=`uppercut_left/boxing_uppercut_left_window_02 0.881` margin=`0.068` backend=`prototype_matcher`
- `punch_right` at `5594ms` score=`0.942` prototype=`boxing_straight_right_window_04` class=`straight_right` runner-up=`uppercut_left/boxing_uppercut_left_window_02 0.829` margin=`0.113` backend=`prototype_matcher`
- `punch_right` at `5845ms` score=`0.949` prototype=`boxing_straight_right_window_04` class=`straight_right` runner-up=`uppercut_left/boxing_uppercut_left_window_02 0.788` margin=`0.161` backend=`prototype_matcher`
- `punch_right` at `6072ms` score=`0.919` prototype=`boxing_straight_right_window_04` class=`straight_right` runner-up=`uppercut_right/boxing_uppercut_right_window_01 0.788` margin=`0.131` backend=`prototype_matcher`
- `punch_right` at `6316ms` score=`0.888` prototype=`boxing_straight_right_window_02` class=`straight_right` runner-up=`uppercut_left/boxing_uppercut_left_window_03 0.725` margin=`0.163` backend=`prototype_matcher`
- `punch_right` at `6817ms` score=`0.803` prototype=`boxing_straight_right_window_04` class=`straight_right` runner-up=`uppercut_left/boxing_uppercut_left_window_02 0.755` margin=`0.048` backend=`prototype_matcher`
- `punch_right` at `7069ms` score=`0.858` prototype=`boxing_straight_right_window_04` class=`straight_right` runner-up=`uppercut_right/boxing_uppercut_right_window_01 0.739` margin=`0.119` backend=`prototype_matcher`
- `punch_right` at `7319ms` score=`0.902` prototype=`boxing_straight_right_window_04` class=`straight_right` runner-up=`uppercut_right/boxing_uppercut_right_window_01 0.771` margin=`0.131` backend=`prototype_matcher`
- `punch_right` at `7569ms` score=`0.921` prototype=`boxing_straight_right_window_01` class=`straight_right` runner-up=`uppercut_right/boxing_uppercut_right_window_01 0.809` margin=`0.112` backend=`prototype_matcher`
- `punch_right` at `7819ms` score=`0.830` prototype=`boxing_straight_right_window_03` class=`straight_right` runner-up=`uppercut_left/boxing_uppercut_left_window_02 0.742` margin=`0.088` backend=`prototype_matcher`
- `uppercut_left` at `8194ms` score=`0.827` prototype=`boxing_uppercut_left_window_02` class=`uppercut_left` runner-up=`straight_right/boxing_straight_right_window_04 0.791` margin=`0.036` backend=`prototype_matcher`
- `punch_right` at `8444ms` score=`0.903` prototype=`boxing_straight_right_window_04` class=`straight_right` runner-up=`uppercut_left/boxing_uppercut_left_window_02 0.822` margin=`0.081` backend=`prototype_matcher`
- `punch_right` at `8694ms` score=`0.852` prototype=`boxing_straight_right_window_04` class=`straight_right` runner-up=`uppercut_left/boxing_uppercut_left_window_02 0.846` margin=`0.007` backend=`prototype_matcher`
- `punch_right` at `8947ms` score=`0.937` prototype=`boxing_straight_right_window_02` class=`straight_right` runner-up=`uppercut_left/boxing_uppercut_left_window_02 0.848` margin=`0.089` backend=`prototype_matcher`
- `uppercut_left` at `9206ms` score=`0.745` prototype=`boxing_uppercut_left_window_03` class=`uppercut_left` runner-up=`straight_right/boxing_straight_right_window_02 0.702` margin=`0.043` backend=`prototype_matcher`
- `punch_right` at `9568ms` score=`0.824` prototype=`boxing_straight_right_window_04` class=`straight_right` runner-up=`uppercut_left/boxing_uppercut_left_window_02 0.805` margin=`0.019` backend=`prototype_matcher`
- `punch_right` at `9820ms` score=`0.913` prototype=`boxing_straight_right_window_04` class=`straight_right` runner-up=`uppercut_left/boxing_uppercut_left_window_02 0.802` margin=`0.111` backend=`prototype_matcher`

### hook left

- Fixture: `.testbed/assets/fixtures/boxing/hook_left/boxing_guard->hook_left_repeat_04_take_01.yaml`
- Source: `.testbed/assets/fixtures/boxing/hook_left/boxing_guard->hook_left_repeat_04_take_01.mp4`
- Expected event: `hook_left`
- Expected class: `hook_left`
- Attack events emitted: **27**
- Peak snapshot: hook_left via boxing_hook_left_window_01 score=0.997 runner-up=straight_left/boxing_straight_left_window_03 0.830 margin=0.167
- Strongest expected emit: `hook_left` hook_left via boxing_hook_left_window_01 score=0.992 runner-up=straight_left/boxing_straight_left_window_03 0.830 margin=0.162
- Strongest wrong emit: `uppercut_right` uppercut_right via boxing_uppercut_right_window_01 score=0.919 runner-up=uppercut_left/boxing_uppercut_left_window_02 0.894 margin=0.024
- Emitted prototype counts: `boxing_hook_left_window_01` x7, `boxing_hook_left_window_04` x5, `boxing_hook_right_window_03` x4, `boxing_uppercut_left_window_01` x4, `boxing_uppercut_right_window_01` x4
- Best-snapshot prototype counts: `boxing_hook_left_window_01` x19, `boxing_hook_right_window_03` x15, `boxing_uppercut_right_window_03` x9, `boxing_uppercut_left_window_01` x8, `boxing_uppercut_right_window_01` x8
- emitted expected hook_left 13 time(s)
- also emitted other attack events: uppercut_right, uppercut_left, hook_right, hook_right, hook_right, hook_right, punch_left, uppercut_left, uppercut_left, uppercut_right, uppercut_right, uppercut_right, uppercut_left, uppercut_right
- peak expected-class score 0.997
- peak winner hook_left via boxing_hook_left_window_01 scored 0.997; runner-up straight_left via boxing_straight_left_window_03 scored 0.830 (margin 0.167)
- strongest expected emit used boxing_hook_left_window_01 at 0.992 over runner-up boxing_straight_left_window_03 at 0.830 (margin 0.162)
- strongest wrong emit was uppercut_right via boxing_uppercut_right_window_01 at 0.919 over runner-up boxing_uppercut_left_window_02 at 0.894 (margin 0.024)
- latest matcher reason emitted

Emitted attack events:
- `uppercut_right` at `1078ms` score=`0.907` prototype=`boxing_uppercut_right_window_01` class=`uppercut_right` runner-up=`uppercut_left/boxing_uppercut_left_window_02 0.883` margin=`0.023` backend=`prototype_matcher`
- `uppercut_left` at `1346ms` score=`0.869` prototype=`boxing_uppercut_left_window_01` class=`uppercut_left` runner-up=`uppercut_right/boxing_uppercut_right_window_04 0.864` margin=`0.005` backend=`prototype_matcher`
- `hook_left` at `2008ms` score=`0.756` prototype=`boxing_hook_left_window_04` class=`hook_left` runner-up=`uppercut_right/boxing_uppercut_right_window_03 0.696` margin=`0.059` backend=`prototype_matcher`
- `hook_left` at `2319ms` score=`0.894` prototype=`boxing_hook_left_window_01` class=`hook_left` runner-up=`uppercut_right/boxing_uppercut_right_window_03 0.870` margin=`0.023` backend=`prototype_matcher`
- `hook_left` at `2631ms` score=`0.992` prototype=`boxing_hook_left_window_01` class=`hook_left` runner-up=`straight_left/boxing_straight_left_window_03 0.830` margin=`0.162` backend=`prototype_matcher`
- `hook_left` at `2943ms` score=`0.901` prototype=`boxing_hook_left_window_01` class=`hook_left` runner-up=`straight_left/boxing_straight_left_window_03 0.845` margin=`0.056` backend=`prototype_matcher`
- `hook_right` at `3255ms` score=`0.745` prototype=`boxing_hook_right_window_03` class=`hook_right` runner-up=`uppercut_right/boxing_uppercut_right_window_03 0.687` margin=`0.058` backend=`prototype_matcher`
- `hook_left` at `3779ms` score=`0.831` prototype=`boxing_hook_left_window_04` class=`hook_left` runner-up=`hook_right/boxing_hook_right_window_03 0.735` margin=`0.096` backend=`prototype_matcher`
- `hook_left` at `4084ms` score=`0.890` prototype=`boxing_hook_left_window_01` class=`hook_left` runner-up=`straight_left/boxing_straight_left_window_02 0.791` margin=`0.098` backend=`prototype_matcher`
- `hook_left` at `4401ms` score=`0.900` prototype=`boxing_hook_left_window_01` class=`hook_left` runner-up=`straight_left/boxing_straight_left_window_03 0.839` margin=`0.060` backend=`prototype_matcher`
- `hook_right` at `4707ms` score=`0.812` prototype=`boxing_hook_right_window_03` class=`hook_right` runner-up=`uppercut_right/boxing_uppercut_right_window_03 0.725` margin=`0.087` backend=`prototype_matcher`
- `hook_left` at `5228ms` score=`0.788` prototype=`boxing_hook_left_window_04` class=`hook_left` runner-up=`hook_right/boxing_hook_right_window_03 0.751` margin=`0.037` backend=`prototype_matcher`
- `hook_left` at `5545ms` score=`0.896` prototype=`boxing_hook_left_window_03` class=`hook_left` runner-up=`hook_right/boxing_hook_right_window_03 0.755` margin=`0.141` backend=`prototype_matcher`
- `hook_left` at `5850ms` score=`0.925` prototype=`boxing_hook_left_window_01` class=`hook_left` runner-up=`straight_left/boxing_straight_left_window_03 0.783` margin=`0.142` backend=`prototype_matcher`
- `hook_right` at `6169ms` score=`0.727` prototype=`boxing_hook_right_window_03` class=`hook_right` runner-up=`uppercut_right/boxing_uppercut_right_window_03 0.649` margin=`0.078` backend=`prototype_matcher`
- `hook_right` at `6471ms` score=`0.716` prototype=`boxing_hook_right_window_03` class=`hook_right` runner-up=`uppercut_right/boxing_uppercut_right_window_03 0.676` margin=`0.040` backend=`prototype_matcher`
- `hook_left` at `6789ms` score=`0.843` prototype=`boxing_hook_left_window_04` class=`hook_left` runner-up=`uppercut_right/boxing_uppercut_right_window_03 0.747` margin=`0.096` backend=`prototype_matcher`
- `punch_left` at `7092ms` score=`0.884` prototype=`boxing_straight_left_window_03` class=`straight_left` runner-up=`uppercut_right/boxing_uppercut_right_window_03 0.871` margin=`0.013` backend=`prototype_matcher`
- `uppercut_left` at `7392ms` score=`0.835` prototype=`boxing_uppercut_left_window_01` class=`uppercut_left` runner-up=`uppercut_right/boxing_uppercut_right_window_03 0.833` margin=`0.002` backend=`prototype_matcher`
- `uppercut_left` at `7689ms` score=`0.853` prototype=`boxing_uppercut_left_window_01` class=`uppercut_left` runner-up=`straight_left/boxing_straight_left_window_04 0.833` margin=`0.019` backend=`prototype_matcher`
- `uppercut_right` at `7944ms` score=`0.897` prototype=`boxing_uppercut_right_window_01` class=`uppercut_right` runner-up=`uppercut_left/boxing_uppercut_left_window_01 0.892` margin=`0.004` backend=`prototype_matcher`
- `uppercut_right` at `8251ms` score=`0.912` prototype=`boxing_uppercut_right_window_01` class=`uppercut_right` runner-up=`uppercut_left/boxing_uppercut_left_window_01 0.889` margin=`0.023` backend=`prototype_matcher`
- `uppercut_right` at `8559ms` score=`0.919` prototype=`boxing_uppercut_right_window_01` class=`uppercut_right` runner-up=`uppercut_left/boxing_uppercut_left_window_02 0.894` margin=`0.024` backend=`prototype_matcher`
- `uppercut_left` at `8860ms` score=`0.887` prototype=`boxing_uppercut_left_window_01` class=`uppercut_left` runner-up=`uppercut_right/boxing_uppercut_right_window_04 0.883` margin=`0.004` backend=`prototype_matcher`
- `uppercut_right` at `9173ms` score=`0.814` prototype=`boxing_uppercut_right_window_03` class=`uppercut_right` runner-up=`hook_right/boxing_hook_right_window_01 0.799` margin=`0.015` backend=`prototype_matcher`
- `hook_left` at `9576ms` score=`0.756` prototype=`boxing_hook_left_window_04` class=`hook_left` runner-up=`uppercut_right/boxing_uppercut_right_window_03 0.696` margin=`0.059` backend=`prototype_matcher`
- `hook_left` at `9879ms` score=`0.912` prototype=`boxing_hook_left_window_01` class=`hook_left` runner-up=`uppercut_right/boxing_uppercut_right_window_03 0.887` margin=`0.025` backend=`prototype_matcher`

### hook right

- Fixture: `.testbed/assets/fixtures/boxing/hook_right/boxing_guard->hook_right_repeat_04_take_01.yaml`
- Source: `.testbed/assets/fixtures/boxing/hook_right/boxing_guard->hook_right_repeat_04_take_01.mp4`
- Expected event: `hook_right`
- Expected class: `hook_right`
- Attack events emitted: **27**
- Peak snapshot: hook_right via boxing_hook_right_window_02 score=0.975 runner-up=straight_left/boxing_straight_left_window_03 0.839 margin=0.137
- Strongest expected emit: `hook_right` hook_right via boxing_hook_right_window_01 score=0.957 runner-up=uppercut_right/boxing_uppercut_right_window_04 0.897 margin=0.060
- Strongest wrong emit: `uppercut_right` uppercut_right via boxing_uppercut_right_window_03 score=0.911 runner-up=hook_right/boxing_hook_right_window_01 0.903 margin=0.008
- Emitted prototype counts: `boxing_hook_right_window_01` x11, `boxing_hook_right_window_04` x5, `boxing_hook_left_window_01` x4, `boxing_hook_right_window_03` x2, `boxing_uppercut_left_window_01` x2
- Best-snapshot prototype counts: `boxing_hook_right_window_01` x28, `boxing_hook_left_window_01` x14, `boxing_hook_right_window_04` x11, `boxing_hook_right_window_03` x10, `boxing_straight_left_window_03` x7
- emitted expected hook_right 19 time(s)
- also emitted other attack events: punch_left, uppercut_left, hook_left, hook_left, hook_left, hook_left, uppercut_right, uppercut_left
- peak expected-class score 0.975
- peak winner hook_right via boxing_hook_right_window_02 scored 0.975; runner-up straight_left via boxing_straight_left_window_03 scored 0.839 (margin 0.137)
- strongest expected emit used boxing_hook_right_window_01 at 0.957 over runner-up boxing_uppercut_right_window_04 at 0.897 (margin 0.060)
- strongest wrong emit was uppercut_right via boxing_uppercut_right_window_03 at 0.911 over runner-up boxing_hook_right_window_01 at 0.903 (margin 0.008)
- latest matcher reason emit_cooldown_active

Emitted attack events:
- `hook_right` at `1122ms` score=`0.903` prototype=`boxing_hook_right_window_01` class=`hook_right` runner-up=`uppercut_right/boxing_uppercut_right_window_04 0.882` margin=`0.021` backend=`prototype_matcher`
- `punch_left` at `1449ms` score=`0.759` prototype=`boxing_straight_left_window_01` class=`straight_left` runner-up=`uppercut_left/boxing_uppercut_left_window_01 0.709` margin=`0.050` backend=`prototype_matcher`
- `hook_right` at `1862ms` score=`0.773` prototype=`boxing_hook_right_window_04` class=`hook_right` runner-up=`straight_left/boxing_straight_left_window_04 0.702` margin=`0.071` backend=`prototype_matcher`
- `hook_right` at `2158ms` score=`0.952` prototype=`boxing_hook_right_window_01` class=`hook_right` runner-up=`uppercut_right/boxing_uppercut_right_window_04 0.871` margin=`0.081` backend=`prototype_matcher`
- `hook_right` at `2464ms` score=`0.957` prototype=`boxing_hook_right_window_01` class=`hook_right` runner-up=`uppercut_right/boxing_uppercut_right_window_04 0.897` margin=`0.060` backend=`prototype_matcher`
- `uppercut_left` at `2784ms` score=`0.805` prototype=`boxing_uppercut_left_window_01` class=`uppercut_left` runner-up=`straight_left/boxing_straight_left_window_03 0.805` margin=`0.000` backend=`prototype_matcher`
- `hook_left` at `3073ms` score=`0.720` prototype=`boxing_hook_left_window_01` class=`hook_left` runner-up=`straight_left/boxing_straight_left_window_02 0.712` margin=`0.007` backend=`prototype_matcher`
- `hook_right` at `3374ms` score=`0.734` prototype=`boxing_hook_right_window_04` class=`hook_right` runner-up=`hook_left/boxing_hook_left_window_01 0.649` margin=`0.085` backend=`prototype_matcher`
- `hook_right` at `3678ms` score=`0.898` prototype=`boxing_hook_right_window_02` class=`hook_right` runner-up=`hook_left/boxing_hook_left_window_01 0.867` margin=`0.031` backend=`prototype_matcher`
- `hook_right` at `3980ms` score=`0.902` prototype=`boxing_hook_right_window_01` class=`hook_right` runner-up=`uppercut_right/boxing_uppercut_right_window_03 0.880` margin=`0.023` backend=`prototype_matcher`
- `hook_left` at `4294ms` score=`0.822` prototype=`boxing_hook_left_window_01` class=`hook_left` runner-up=`straight_left/boxing_straight_left_window_03 0.796` margin=`0.026` backend=`prototype_matcher`
- `hook_right` at `4904ms` score=`0.785` prototype=`boxing_hook_right_window_04` class=`hook_right` runner-up=`hook_left/boxing_hook_left_window_01 0.754` margin=`0.031` backend=`prototype_matcher`
- `hook_right` at `5212ms` score=`0.901` prototype=`boxing_hook_right_window_03` class=`hook_right` runner-up=`hook_left/boxing_hook_left_window_01 0.825` margin=`0.075` backend=`prototype_matcher`
- `hook_right` at `5528ms` score=`0.929` prototype=`boxing_hook_right_window_03` class=`hook_right` runner-up=`uppercut_right/boxing_uppercut_right_window_03 0.864` margin=`0.065` backend=`prototype_matcher`
- `hook_right` at `5838ms` score=`0.891` prototype=`boxing_hook_right_window_01` class=`hook_right` runner-up=`uppercut_right/boxing_uppercut_right_window_03 0.857` margin=`0.034` backend=`prototype_matcher`
- `hook_left` at `6144ms` score=`0.713` prototype=`boxing_hook_left_window_01` class=`hook_left` runner-up=`straight_left/boxing_straight_left_window_03 0.701` margin=`0.013` backend=`prototype_matcher`
- `hook_right` at `6558ms` score=`0.749` prototype=`boxing_hook_right_window_04` class=`hook_right` runner-up=`hook_left/boxing_hook_left_window_01 0.642` margin=`0.107` backend=`prototype_matcher`
- `hook_left` at `6872ms` score=`0.880` prototype=`boxing_hook_left_window_01` class=`hook_left` runner-up=`hook_right/boxing_hook_right_window_04 0.836` margin=`0.044` backend=`prototype_matcher`
- `uppercut_right` at `7175ms` score=`0.911` prototype=`boxing_uppercut_right_window_03` class=`uppercut_right` runner-up=`hook_right/boxing_hook_right_window_01 0.903` margin=`0.008` backend=`prototype_matcher`
- `hook_right` at `7481ms` score=`0.906` prototype=`boxing_hook_right_window_01` class=`hook_right` runner-up=`uppercut_right/boxing_uppercut_right_window_03 0.906` margin=`0.001` backend=`prototype_matcher`
- `hook_right` at `7774ms` score=`0.912` prototype=`boxing_hook_right_window_01` class=`hook_right` runner-up=`uppercut_right/boxing_uppercut_right_window_03 0.900` margin=`0.012` backend=`prototype_matcher`
- `hook_right` at `8060ms` score=`0.880` prototype=`boxing_hook_right_window_01` class=`hook_right` runner-up=`uppercut_right/boxing_uppercut_right_window_04 0.878` margin=`0.003` backend=`prototype_matcher`
- `hook_right` at `8368ms` score=`0.915` prototype=`boxing_hook_right_window_01` class=`hook_right` runner-up=`uppercut_right/boxing_uppercut_right_window_04 0.893` margin=`0.022` backend=`prototype_matcher`
- `hook_right` at `8672ms` score=`0.901` prototype=`boxing_hook_right_window_01` class=`hook_right` runner-up=`uppercut_right/boxing_uppercut_right_window_01 0.868` margin=`0.032` backend=`prototype_matcher`
- `uppercut_left` at `8980ms` score=`0.852` prototype=`boxing_uppercut_left_window_01` class=`uppercut_left` runner-up=`straight_left/boxing_straight_left_window_01 0.823` margin=`0.029` backend=`prototype_matcher`
- `hook_right` at `9596ms` score=`0.773` prototype=`boxing_hook_right_window_04` class=`hook_right` runner-up=`straight_left/boxing_straight_left_window_04 0.702` margin=`0.071` backend=`prototype_matcher`
- `hook_right` at `9887ms` score=`0.952` prototype=`boxing_hook_right_window_01` class=`hook_right` runner-up=`uppercut_right/boxing_uppercut_right_window_03 0.873` margin=`0.079` backend=`prototype_matcher`

### uppercut left

- Fixture: `.testbed/assets/fixtures/boxing/uppercut_left/boxing_guard->uppercut_left_repeat_04_take_01.yaml`
- Source: `.testbed/assets/fixtures/boxing/uppercut_left/boxing_guard->uppercut_left_repeat_04_take_01.mp4`
- Expected event: `uppercut_left`
- Expected class: `uppercut_left`
- Attack events emitted: **29**
- Peak snapshot: uppercut_left via boxing_uppercut_left_window_01 score=1.000 runner-up=uppercut_right/boxing_uppercut_right_window_04 0.904 margin=0.096
- Strongest expected emit: `uppercut_left` uppercut_left via boxing_uppercut_left_window_02 score=0.993 runner-up=uppercut_right/boxing_uppercut_right_window_01 0.881 margin=0.113
- Strongest wrong emit: `uppercut_right` uppercut_right via boxing_uppercut_right_window_03 score=0.925 runner-up=uppercut_left/boxing_uppercut_left_window_02 0.915 margin=0.010
- Emitted prototype counts: `boxing_hook_right_window_02` x6, `boxing_uppercut_left_window_02` x6, `boxing_uppercut_left_window_03` x5, `boxing_uppercut_left_window_01` x4, `boxing_uppercut_right_window_03` x3
- Best-snapshot prototype counts: `boxing_uppercut_left_window_02` x16, `boxing_uppercut_left_window_03` x16, `boxing_hook_right_window_02` x12, `boxing_hook_right_window_03` x11, `boxing_uppercut_left_window_01` x9
- emitted expected uppercut_left 15 time(s)
- also emitted other attack events: uppercut_right, hook_right, uppercut_right, punch_left, hook_right, hook_right, hook_right, hook_left, hook_right, hook_right, uppercut_right, uppercut_right, hook_right, hook_right
- peak expected-class score 1.000
- peak winner uppercut_left via boxing_uppercut_left_window_01 scored 1.000; runner-up uppercut_right via boxing_uppercut_right_window_04 scored 0.904 (margin 0.096)
- strongest expected emit used boxing_uppercut_left_window_02 at 0.993 over runner-up boxing_uppercut_right_window_01 at 0.881 (margin 0.113)
- strongest wrong emit was uppercut_right via boxing_uppercut_right_window_03 at 0.925 over runner-up boxing_uppercut_left_window_02 at 0.915 (margin 0.010)
- latest matcher reason emit_cooldown_active

Emitted attack events:
- `uppercut_right` at `1117ms` score=`0.757` prototype=`boxing_uppercut_right_window_03` class=`uppercut_right` runner-up=`hook_right/boxing_hook_right_window_03 0.750` margin=`0.007` backend=`prototype_matcher`
- `hook_right` at `1402ms` score=`0.742` prototype=`boxing_hook_right_window_02` class=`hook_right` runner-up=`uppercut_right/boxing_uppercut_right_window_03 0.685` margin=`0.057` backend=`prototype_matcher`
- `uppercut_left` at `1698ms` score=`0.854` prototype=`boxing_uppercut_left_window_02` class=`uppercut_left` runner-up=`uppercut_right/boxing_uppercut_right_window_04 0.768` margin=`0.086` backend=`prototype_matcher`
- `uppercut_left` at `2008ms` score=`0.936` prototype=`boxing_uppercut_left_window_01` class=`uppercut_left` runner-up=`uppercut_right/boxing_uppercut_right_window_04 0.860` margin=`0.077` backend=`prototype_matcher`
- `uppercut_left` at `2322ms` score=`0.944` prototype=`boxing_uppercut_left_window_01` class=`uppercut_left` runner-up=`uppercut_right/boxing_uppercut_right_window_04 0.914` margin=`0.031` backend=`prototype_matcher`
- `uppercut_right` at `2635ms` score=`0.916` prototype=`boxing_uppercut_right_window_04` class=`uppercut_right` runner-up=`uppercut_left/boxing_uppercut_left_window_01 0.909` margin=`0.007` backend=`prototype_matcher`
- `punch_left` at `2936ms` score=`0.862` prototype=`boxing_straight_left_window_04` class=`straight_left` runner-up=`uppercut_right/boxing_uppercut_right_window_03 0.839` margin=`0.023` backend=`prototype_matcher`
- `hook_right` at `3245ms` score=`0.735` prototype=`boxing_hook_right_window_03` class=`hook_right` runner-up=`uppercut_right/boxing_uppercut_right_window_03 0.660` margin=`0.075` backend=`prototype_matcher`
- `hook_right` at `3547ms` score=`0.798` prototype=`boxing_hook_right_window_02` class=`hook_right` runner-up=`uppercut_right/boxing_uppercut_right_window_04 0.778` margin=`0.019` backend=`prototype_matcher`
- `uppercut_left` at `3861ms` score=`0.895` prototype=`boxing_uppercut_left_window_03` class=`uppercut_left` runner-up=`uppercut_right/boxing_uppercut_right_window_04 0.804` margin=`0.091` backend=`prototype_matcher`
- `uppercut_left` at `4171ms` score=`0.993` prototype=`boxing_uppercut_left_window_02` class=`uppercut_left` runner-up=`uppercut_right/boxing_uppercut_right_window_01 0.881` margin=`0.113` backend=`prototype_matcher`
- `uppercut_left` at `4481ms` score=`0.946` prototype=`boxing_uppercut_left_window_02` class=`uppercut_left` runner-up=`uppercut_right/boxing_uppercut_right_window_01 0.886` margin=`0.060` backend=`prototype_matcher`
- `uppercut_left` at `4783ms` score=`0.904` prototype=`boxing_uppercut_left_window_02` class=`uppercut_left` runner-up=`uppercut_right/boxing_uppercut_right_window_04 0.901` margin=`0.003` backend=`prototype_matcher`
- `hook_right` at `5412ms` score=`0.726` prototype=`boxing_hook_right_window_02` class=`hook_right` runner-up=`uppercut_right/boxing_uppercut_right_window_03 0.650` margin=`0.076` backend=`prototype_matcher`
- `uppercut_left` at `5708ms` score=`0.918` prototype=`boxing_uppercut_left_window_03` class=`uppercut_left` runner-up=`uppercut_right/boxing_uppercut_right_window_01 0.831` margin=`0.087` backend=`prototype_matcher`
- `uppercut_left` at `6026ms` score=`0.958` prototype=`boxing_uppercut_left_window_03` class=`uppercut_left` runner-up=`uppercut_right/boxing_uppercut_right_window_04 0.876` margin=`0.082` backend=`prototype_matcher`
- `uppercut_left` at `6328ms` score=`0.947` prototype=`boxing_uppercut_left_window_03` class=`uppercut_left` runner-up=`uppercut_right/boxing_uppercut_right_window_01 0.868` margin=`0.079` backend=`prototype_matcher`
- `uppercut_left` at `6636ms` score=`0.946` prototype=`boxing_uppercut_left_window_02` class=`uppercut_left` runner-up=`uppercut_right/boxing_uppercut_right_window_01 0.922` margin=`0.024` backend=`prototype_matcher`
- `hook_left` at `6969ms` score=`0.825` prototype=`boxing_hook_left_window_01` class=`hook_left` runner-up=`straight_left/boxing_straight_left_window_03 0.803` margin=`0.023` backend=`prototype_matcher`
- `hook_right` at `7266ms` score=`0.709` prototype=`boxing_hook_right_window_03` class=`hook_right` runner-up=`uppercut_right/boxing_uppercut_right_window_03 0.649` margin=`0.061` backend=`prototype_matcher`
- `hook_right` at `7567ms` score=`0.811` prototype=`boxing_hook_right_window_02` class=`hook_right` runner-up=`uppercut_right/boxing_uppercut_right_window_04 0.803` margin=`0.008` backend=`prototype_matcher`
- `uppercut_left` at `7865ms` score=`0.870` prototype=`boxing_uppercut_left_window_03` class=`uppercut_left` runner-up=`uppercut_right/boxing_uppercut_right_window_04 0.837` margin=`0.033` backend=`prototype_matcher`
- `uppercut_left` at `8172ms` score=`0.915` prototype=`boxing_uppercut_left_window_01` class=`uppercut_left` runner-up=`uppercut_right/boxing_uppercut_right_window_04 0.906` margin=`0.009` backend=`prototype_matcher`
- `uppercut_left` at `8377ms` score=`0.932` prototype=`boxing_uppercut_left_window_02` class=`uppercut_left` runner-up=`uppercut_right/boxing_uppercut_right_window_03 0.926` margin=`0.006` backend=`prototype_matcher`
- `uppercut_right` at `8655ms` score=`0.925` prototype=`boxing_uppercut_right_window_03` class=`uppercut_right` runner-up=`uppercut_left/boxing_uppercut_left_window_02 0.915` margin=`0.010` backend=`prototype_matcher`
- `uppercut_right` at `8969ms` score=`0.890` prototype=`boxing_uppercut_right_window_03` class=`uppercut_right` runner-up=`hook_right/boxing_hook_right_window_01 0.833` margin=`0.057` backend=`prototype_matcher`
- `hook_right` at `9263ms` score=`0.748` prototype=`boxing_hook_right_window_02` class=`hook_right` runner-up=`uppercut_right/boxing_uppercut_right_window_03 0.691` margin=`0.057` backend=`prototype_matcher`
- `hook_right` at `9572ms` score=`0.801` prototype=`boxing_hook_right_window_02` class=`hook_right` runner-up=`uppercut_left/boxing_uppercut_left_window_03 0.756` margin=`0.045` backend=`prototype_matcher`
- `uppercut_left` at `9882ms` score=`0.866` prototype=`boxing_uppercut_left_window_01` class=`uppercut_left` runner-up=`uppercut_right/boxing_uppercut_right_window_04 0.830` margin=`0.036` backend=`prototype_matcher`

### uppercut right

- Fixture: `.testbed/assets/fixtures/boxing/uppercut_right/boxing_guard->uppercut_right_repeat_04_take_01.yaml`
- Source: `.testbed/assets/fixtures/boxing/uppercut_right/boxing_guard->uppercut_right_repeat_04_take_01.mp4`
- Expected event: `uppercut_right`
- Expected class: `uppercut_right`
- Attack events emitted: **26**
- Peak snapshot: uppercut_right via boxing_uppercut_right_window_01 score=1.000 runner-up=straight_right/boxing_straight_right_window_01 0.863 margin=0.137
- Strongest expected emit: `uppercut_right` uppercut_right via boxing_uppercut_right_window_01 score=1.000 runner-up=straight_right/boxing_straight_right_window_01 0.863 margin=0.137
- Strongest wrong emit: `hook_left` hook_left via boxing_hook_left_window_01 score=0.870 runner-up=straight_left/boxing_straight_left_window_03 0.752 margin=0.117
- Emitted prototype counts: `boxing_uppercut_right_window_01` x10, `boxing_hook_left_window_01` x7, `boxing_uppercut_right_window_03` x3, `boxing_hook_left_window_03` x2, `boxing_uppercut_right_window_04` x2
- Best-snapshot prototype counts: `boxing_hook_left_window_01` x26, `boxing_uppercut_right_window_01` x25, `boxing_uppercut_right_window_03` x12, `boxing_uppercut_right_window_04` x8, `boxing_hook_left_window_03` x4
- emitted expected uppercut_right 15 time(s)
- also emitted other attack events: hook_left, punch_left, hook_left, hook_left, hook_left, hook_left, hook_left, hook_left, hook_left, punch_left, hook_left
- peak expected-class score 1.000
- peak winner uppercut_right via boxing_uppercut_right_window_01 scored 1.000; runner-up straight_right via boxing_straight_right_window_01 scored 0.863 (margin 0.137)
- strongest expected emit used boxing_uppercut_right_window_01 at 1.000 over runner-up boxing_straight_right_window_01 at 0.863 (margin 0.137)
- strongest wrong emit was hook_left via boxing_hook_left_window_01 at 0.870 over runner-up boxing_straight_left_window_03 at 0.752 (margin 0.117)
- latest matcher reason emitted

Emitted attack events:
- `hook_left` at `1355ms` score=`0.778` prototype=`boxing_hook_left_window_01` class=`hook_left` runner-up=`straight_left/boxing_straight_left_window_03 0.652` margin=`0.126` backend=`prototype_matcher`
- `punch_left` at `1652ms` score=`0.770` prototype=`boxing_straight_left_window_01` class=`straight_left` runner-up=`uppercut_right/boxing_uppercut_right_window_03 0.730` margin=`0.040` backend=`prototype_matcher`
- `uppercut_right` at `1964ms` score=`0.912` prototype=`boxing_uppercut_right_window_01` class=`uppercut_right` runner-up=`straight_right/boxing_straight_right_window_01 0.862` margin=`0.050` backend=`prototype_matcher`
- `uppercut_right` at `2278ms` score=`0.980` prototype=`boxing_uppercut_right_window_01` class=`uppercut_right` runner-up=`straight_right/boxing_straight_right_window_01 0.878` margin=`0.102` backend=`prototype_matcher`
- `uppercut_right` at `2580ms` score=`0.938` prototype=`boxing_uppercut_right_window_01` class=`uppercut_right` runner-up=`hook_right/boxing_hook_right_window_01 0.858` margin=`0.080` backend=`prototype_matcher`
- `hook_left` at `3188ms` score=`0.814` prototype=`boxing_hook_left_window_01` class=`hook_left` runner-up=`straight_left/boxing_straight_left_window_03 0.719` margin=`0.094` backend=`prototype_matcher`
- `uppercut_right` at `3495ms` score=`0.858` prototype=`boxing_uppercut_right_window_01` class=`uppercut_right` runner-up=`straight_left/boxing_straight_left_window_01 0.813` margin=`0.045` backend=`prototype_matcher`
- `uppercut_right` at `3813ms` score=`0.918` prototype=`boxing_uppercut_right_window_01` class=`uppercut_right` runner-up=`straight_right/boxing_straight_right_window_01 0.894` margin=`0.023` backend=`prototype_matcher`
- `uppercut_right` at `4120ms` score=`0.927` prototype=`boxing_uppercut_right_window_01` class=`uppercut_right` runner-up=`straight_right/boxing_straight_right_window_01 0.886` margin=`0.042` backend=`prototype_matcher`
- `hook_left` at `4446ms` score=`0.827` prototype=`boxing_hook_left_window_01` class=`hook_left` runner-up=`straight_left/boxing_straight_left_window_03 0.803` margin=`0.024` backend=`prototype_matcher`
- `hook_left` at `4750ms` score=`0.870` prototype=`boxing_hook_left_window_01` class=`hook_left` runner-up=`straight_left/boxing_straight_left_window_03 0.752` margin=`0.117` backend=`prototype_matcher`
- `hook_left` at `5051ms` score=`0.863` prototype=`boxing_hook_left_window_01` class=`hook_left` runner-up=`straight_left/boxing_straight_left_window_03 0.831` margin=`0.032` backend=`prototype_matcher`
- `uppercut_right` at `5371ms` score=`0.946` prototype=`boxing_uppercut_right_window_03` class=`uppercut_right` runner-up=`hook_right/boxing_hook_right_window_01 0.900` margin=`0.046` backend=`prototype_matcher`
- `uppercut_right` at `5683ms` score=`0.933` prototype=`boxing_uppercut_right_window_03` class=`uppercut_right` runner-up=`hook_right/boxing_hook_right_window_01 0.831` margin=`0.103` backend=`prototype_matcher`
- `hook_left` at `6106ms` score=`0.708` prototype=`boxing_hook_left_window_03` class=`hook_left` runner-up=`straight_left/boxing_straight_left_window_03 0.581` margin=`0.127` backend=`prototype_matcher`
- `hook_left` at `6402ms` score=`0.820` prototype=`boxing_hook_left_window_01` class=`hook_left` runner-up=`straight_left/boxing_straight_left_window_04 0.702` margin=`0.117` backend=`prototype_matcher`
- `uppercut_right` at `6701ms` score=`0.885` prototype=`boxing_uppercut_right_window_01` class=`uppercut_right` runner-up=`straight_left/boxing_straight_left_window_01 0.846` margin=`0.038` backend=`prototype_matcher`
- `uppercut_right` at `7148ms` score=`0.944` prototype=`boxing_uppercut_right_window_04` class=`uppercut_right` runner-up=`hook_right/boxing_hook_right_window_01 0.884` margin=`0.059` backend=`prototype_matcher`
- `uppercut_right` at `7456ms` score=`0.942` prototype=`boxing_uppercut_right_window_04` class=`uppercut_right` runner-up=`hook_right/boxing_hook_right_window_01 0.893` margin=`0.049` backend=`prototype_matcher`
- `uppercut_right` at `7773ms` score=`0.922` prototype=`boxing_uppercut_right_window_03` class=`uppercut_right` runner-up=`hook_right/boxing_hook_right_window_01 0.875` margin=`0.048` backend=`prototype_matcher`
- `hook_left` at `8196ms` score=`0.723` prototype=`boxing_hook_left_window_03` class=`hook_left` runner-up=`straight_left/boxing_straight_left_window_03 0.618` margin=`0.106` backend=`prototype_matcher`
- `punch_left` at `8480ms` score=`0.750` prototype=`boxing_straight_left_window_04` class=`straight_left` runner-up=`uppercut_right/boxing_uppercut_right_window_03 0.730` margin=`0.020` backend=`prototype_matcher`
- `uppercut_right` at `8784ms` score=`0.912` prototype=`boxing_uppercut_right_window_01` class=`uppercut_right` runner-up=`straight_right/boxing_straight_right_window_01 0.862` margin=`0.050` backend=`prototype_matcher`
- `uppercut_right` at `9085ms` score=`1.000` prototype=`boxing_uppercut_right_window_01` class=`uppercut_right` runner-up=`straight_right/boxing_straight_right_window_01 0.863` margin=`0.137` backend=`prototype_matcher`
- `uppercut_right` at `9391ms` score=`0.938` prototype=`boxing_uppercut_right_window_01` class=`uppercut_right` runner-up=`hook_right/boxing_hook_right_window_01 0.858` margin=`0.080` backend=`prototype_matcher`
- `hook_left` at `10003ms` score=`0.709` prototype=`boxing_hook_left_window_01` class=`hook_left` runner-up=`straight_left/boxing_straight_left_window_03 0.622` margin=`0.087` backend=`prototype_matcher`

### negative control - running in place

- Fixture: `.testbed/assets/fixtures/boxing/run_in_place/boxing_guard->run_in_place_repeat_01_take_01.yaml`
- Source: `.testbed/assets/fixtures/boxing/run_in_place/boxing_guard->run_in_place_repeat_01_take_01.mp4`
- Expected event: `None`
- Expected class: `None`
- Attack events emitted: **29**
- Peak snapshot: hook_left via boxing_hook_left_window_01 score=0.898 runner-up=straight_left/boxing_straight_left_window_03 0.817 margin=0.081
- Strongest wrong emit: `hook_left` hook_left via boxing_hook_left_window_01 score=0.898 runner-up=straight_left/boxing_straight_left_window_03 0.817 margin=0.081
- Emitted prototype counts: `boxing_hook_left_window_01` x23, `boxing_hook_right_window_03` x2, `boxing_straight_left_window_01` x2, `boxing_straight_left_window_02` x1, `boxing_straight_left_window_04` x1
- Best-snapshot prototype counts: `boxing_hook_left_window_01` x72, `boxing_straight_left_window_01` x5, `boxing_hook_right_window_03` x3, `boxing_straight_left_window_04` x3, `boxing_straight_left_window_02` x2
- negative control still emitted attack events: punch_left, punch_left, hook_left, hook_left, hook_left, hook_left, hook_left, hook_left, hook_left, hook_left, hook_left, hook_left, hook_left, hook_left, hook_right, hook_right, punch_left, punch_left, hook_left, hook_left, hook_left, hook_left, hook_left, hook_left, hook_left, hook_left, hook_left, hook_left, hook_left
- peak winner hook_left via boxing_hook_left_window_01 scored 0.898; runner-up straight_left via boxing_straight_left_window_03 scored 0.817 (margin 0.081)
- strongest wrong emit was hook_left via boxing_hook_left_window_01 at 0.898 over runner-up boxing_straight_left_window_03 at 0.817 (margin 0.081)
- latest matcher reason step_wait

Emitted attack events:
- `punch_left` at `1109ms` score=`0.866` prototype=`boxing_straight_left_window_01` class=`straight_left` runner-up=`uppercut_right/boxing_uppercut_right_window_03 0.820` margin=`0.045` backend=`prototype_matcher`
- `punch_left` at `1359ms` score=`0.822` prototype=`boxing_straight_left_window_02` class=`straight_left` runner-up=`hook_left/boxing_hook_left_window_01 0.807` margin=`0.015` backend=`prototype_matcher`
- `hook_left` at `1703ms` score=`0.769` prototype=`boxing_hook_left_window_01` class=`hook_left` runner-up=`straight_left/boxing_straight_left_window_03 0.724` margin=`0.045` backend=`prototype_matcher`
- `hook_left` at `2013ms` score=`0.814` prototype=`boxing_hook_left_window_01` class=`hook_left` runner-up=`straight_left/boxing_straight_left_window_03 0.745` margin=`0.069` backend=`prototype_matcher`
- `hook_left` at `2323ms` score=`0.877` prototype=`boxing_hook_left_window_01` class=`hook_left` runner-up=`straight_left/boxing_straight_left_window_03 0.796` margin=`0.082` backend=`prototype_matcher`
- `hook_left` at `2636ms` score=`0.898` prototype=`boxing_hook_left_window_01` class=`hook_left` runner-up=`straight_left/boxing_straight_left_window_03 0.817` margin=`0.081` backend=`prototype_matcher`
- `hook_left` at `2946ms` score=`0.883` prototype=`boxing_hook_left_window_01` class=`hook_left` runner-up=`straight_left/boxing_straight_left_window_03 0.809` margin=`0.074` backend=`prototype_matcher`
- `hook_left` at `3261ms` score=`0.894` prototype=`boxing_hook_left_window_01` class=`hook_left` runner-up=`straight_left/boxing_straight_left_window_04 0.803` margin=`0.090` backend=`prototype_matcher`
- `hook_left` at `3568ms` score=`0.890` prototype=`boxing_hook_left_window_01` class=`hook_left` runner-up=`straight_left/boxing_straight_left_window_03 0.827` margin=`0.063` backend=`prototype_matcher`
- `hook_left` at `3883ms` score=`0.890` prototype=`boxing_hook_left_window_01` class=`hook_left` runner-up=`straight_left/boxing_straight_left_window_03 0.822` margin=`0.068` backend=`prototype_matcher`
- `hook_left` at `4184ms` score=`0.868` prototype=`boxing_hook_left_window_01` class=`hook_left` runner-up=`straight_left/boxing_straight_left_window_03 0.803` margin=`0.065` backend=`prototype_matcher`
- `hook_left` at `4496ms` score=`0.867` prototype=`boxing_hook_left_window_01` class=`hook_left` runner-up=`straight_left/boxing_straight_left_window_02 0.790` margin=`0.077` backend=`prototype_matcher`
- `hook_left` at `4791ms` score=`0.853` prototype=`boxing_hook_left_window_01` class=`hook_left` runner-up=`straight_left/boxing_straight_left_window_03 0.792` margin=`0.060` backend=`prototype_matcher`
- `hook_left` at `5090ms` score=`0.874` prototype=`boxing_hook_left_window_01` class=`hook_left` runner-up=`straight_left/boxing_straight_left_window_03 0.819` margin=`0.054` backend=`prototype_matcher`
- `hook_right` at `5409ms` score=`0.885` prototype=`boxing_hook_right_window_03` class=`hook_right` runner-up=`uppercut_right/boxing_uppercut_right_window_03 0.873` margin=`0.012` backend=`prototype_matcher`
- `hook_right` at `5715ms` score=`0.854` prototype=`boxing_hook_right_window_03` class=`hook_right` runner-up=`straight_left/boxing_straight_left_window_04 0.846` margin=`0.008` backend=`prototype_matcher`
- `punch_left` at `6024ms` score=`0.885` prototype=`boxing_straight_left_window_01` class=`straight_left` runner-up=`hook_right/boxing_hook_right_window_03 0.840` margin=`0.044` backend=`prototype_matcher`
- `punch_left` at `6338ms` score=`0.839` prototype=`boxing_straight_left_window_04` class=`straight_left` runner-up=`hook_left/boxing_hook_left_window_01 0.839` margin=`0.000` backend=`prototype_matcher`
- `hook_left` at `6644ms` score=`0.752` prototype=`boxing_hook_left_window_01` class=`hook_left` runner-up=`straight_left/boxing_straight_left_window_03 0.716` margin=`0.036` backend=`prototype_matcher`
- `hook_left` at `6953ms` score=`0.798` prototype=`boxing_hook_left_window_01` class=`hook_left` runner-up=`straight_left/boxing_straight_left_window_03 0.743` margin=`0.055` backend=`prototype_matcher`
- `hook_left` at `7267ms` score=`0.863` prototype=`boxing_hook_left_window_01` class=`hook_left` runner-up=`straight_left/boxing_straight_left_window_03 0.785` margin=`0.078` backend=`prototype_matcher`
- `hook_left` at `7577ms` score=`0.886` prototype=`boxing_hook_left_window_01` class=`hook_left` runner-up=`straight_left/boxing_straight_left_window_03 0.805` margin=`0.081` backend=`prototype_matcher`
- `hook_left` at `7894ms` score=`0.888` prototype=`boxing_hook_left_window_01` class=`hook_left` runner-up=`straight_left/boxing_straight_left_window_03 0.800` margin=`0.089` backend=`prototype_matcher`
- `hook_left` at `8202ms` score=`0.848` prototype=`boxing_hook_left_window_01` class=`hook_left` runner-up=`straight_left/boxing_straight_left_window_03 0.803` margin=`0.046` backend=`prototype_matcher`
- `hook_left` at `8509ms` score=`0.891` prototype=`boxing_hook_left_window_01` class=`hook_left` runner-up=`straight_left/boxing_straight_left_window_03 0.798` margin=`0.092` backend=`prototype_matcher`
- `hook_left` at `8813ms` score=`0.891` prototype=`boxing_hook_left_window_01` class=`hook_left` runner-up=`straight_left/boxing_straight_left_window_03 0.824` margin=`0.067` backend=`prototype_matcher`
- `hook_left` at `9125ms` score=`0.874` prototype=`boxing_hook_left_window_01` class=`hook_left` runner-up=`straight_left/boxing_straight_left_window_03 0.797` margin=`0.077` backend=`prototype_matcher`
- `hook_left` at `9438ms` score=`0.829` prototype=`boxing_hook_left_window_01` class=`hook_left` runner-up=`straight_left/boxing_straight_left_window_03 0.791` margin=`0.038` backend=`prototype_matcher`
- `hook_left` at `9740ms` score=`0.827` prototype=`boxing_hook_left_window_01` class=`hook_left` runner-up=`straight_left/boxing_straight_left_window_03 0.777` margin=`0.049` backend=`prototype_matcher`
