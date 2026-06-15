# Prototype Matcher Fixture Benchmark

- Benchmark ID: `prototype_matcher_boxing_fixture_derived_v1`
- Library ID: `boxing_side_aware_fixture_derived_v1`
- Profile: `boxing`
- Generated At: `2026-06-15T15:51:44-04:00`
- Runner: `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/scripts/run_prototype_matcher_fixture_benchmark.py`

## Aggregate

- Fixture count: **7**
- Negative controls clean: **0 / 1**
- Negative-control false-positive classes: `hook_left` x19, `hook_right` x2, `straight_left` x2
- Negative-control false-positive prototypes: `boxing_hook_left_window_04` x10, `boxing_hook_left_window_01` x9, `boxing_straight_left_window_01` x2, `boxing_hook_right_window_01` x1, `boxing_hook_right_window_04` x1

## Per Fixture

### straight left

- Fixture: `.testbed/assets/fixtures/boxing/straight_left/boxing_guard->straight_left_repeat_04_take_01.yaml`
- Source: `.testbed/assets/fixtures/boxing/straight_left/boxing_guard->straight_left_repeat_04_take_01.mp4`
- Expected event: `punch_left`
- Expected class: `straight_left`
- Attack events emitted: **29**
- Peak snapshot: straight_left via boxing_straight_left_window_04 score=1.000 runner-up=hook_right/boxing_hook_right_window_04 0.884 margin=0.116
- Strongest expected emit: `punch_left` straight_left via boxing_straight_left_window_04 score=1.000 runner-up=hook_right/boxing_hook_right_window_04 0.884 margin=0.116
- Strongest wrong emit: `uppercut_left` uppercut_left via boxing_uppercut_left_window_04 score=0.922 runner-up=uppercut_right/boxing_uppercut_right_window_01 0.895 margin=0.027
- Emitted prototype counts: `boxing_hook_right_window_04` x8, `boxing_straight_left_window_01` x6, `boxing_uppercut_left_window_04` x4, `boxing_hook_right_window_01` x3, `boxing_uppercut_right_window_01` x3
- Best-snapshot prototype counts: `boxing_hook_right_window_04` x24, `boxing_straight_left_window_01` x14, `boxing_uppercut_left_window_04` x12, `boxing_uppercut_right_window_01` x11, `boxing_hook_right_window_01` x10
- emitted expected punch_left 11 time(s)
- also emitted other attack events: uppercut_left, uppercut_left, uppercut_right, uppercut_right, hook_right, hook_right, hook_right, hook_right, hook_right, hook_right, hook_right, hook_right, uppercut_left, uppercut_left, hook_right, uppercut_right, hook_right, hook_right
- peak expected-class score 1.000
- peak winner straight_left via boxing_straight_left_window_04 scored 1.000; runner-up hook_right via boxing_hook_right_window_04 scored 0.884 (margin 0.116)
- strongest expected emit used boxing_straight_left_window_04 at 1.000 over runner-up boxing_hook_right_window_04 at 0.884 (margin 0.116)
- strongest wrong emit was uppercut_left via boxing_uppercut_left_window_04 at 0.922 over runner-up boxing_uppercut_right_window_01 at 0.895 (margin 0.027)
- latest matcher reason step_wait

Emitted attack events:
- `uppercut_left` at `1166ms` score=`0.873` prototype=`boxing_uppercut_left_window_04` class=`uppercut_left` runner-up=`uppercut_right/boxing_uppercut_right_window_01 0.869` margin=`0.004` backend=`prototype_matcher`
- `uppercut_left` at `1415ms` score=`0.922` prototype=`boxing_uppercut_left_window_04` class=`uppercut_left` runner-up=`uppercut_right/boxing_uppercut_right_window_01 0.895` margin=`0.027` backend=`prototype_matcher`
- `punch_left` at `1748ms` score=`0.791` prototype=`boxing_straight_left_window_03` class=`straight_left` runner-up=`hook_right/boxing_hook_right_window_04 0.789` margin=`0.002` backend=`prototype_matcher`
- `punch_left` at `2054ms` score=`0.826` prototype=`boxing_straight_left_window_01` class=`straight_left` runner-up=`hook_right/boxing_hook_right_window_01 0.788` margin=`0.037` backend=`prototype_matcher`
- `punch_left` at `2369ms` score=`0.981` prototype=`boxing_straight_left_window_01` class=`straight_left` runner-up=`uppercut_right/boxing_uppercut_right_window_01 0.897` margin=`0.084` backend=`prototype_matcher`
- `uppercut_right` at `2690ms` score=`0.903` prototype=`boxing_uppercut_right_window_01` class=`uppercut_right` runner-up=`hook_right/boxing_hook_right_window_04 0.876` margin=`0.027` backend=`prototype_matcher`
- `uppercut_right` at `3007ms` score=`0.811` prototype=`boxing_uppercut_right_window_01` class=`uppercut_right` runner-up=`hook_right/boxing_hook_right_window_04 0.802` margin=`0.009` backend=`prototype_matcher`
- `hook_right` at `3318ms` score=`0.838` prototype=`boxing_hook_right_window_04` class=`hook_right` runner-up=`straight_left/boxing_straight_left_window_01 0.822` margin=`0.016` backend=`prototype_matcher`
- `hook_right` at `3645ms` score=`0.915` prototype=`boxing_hook_right_window_01` class=`hook_right` runner-up=`straight_left/boxing_straight_left_window_01 0.874` margin=`0.041` backend=`prototype_matcher`
- `hook_right` at `3965ms` score=`0.887` prototype=`boxing_hook_right_window_01` class=`hook_right` runner-up=`uppercut_right/boxing_uppercut_right_window_01 0.842` margin=`0.045` backend=`prototype_matcher`
- `hook_right` at `4307ms` score=`0.856` prototype=`boxing_hook_right_window_01` class=`hook_right` runner-up=`uppercut_right/boxing_uppercut_right_window_01 0.796` margin=`0.060` backend=`prototype_matcher`
- `hook_right` at `4611ms` score=`0.854` prototype=`boxing_hook_right_window_04` class=`hook_right` runner-up=`uppercut_left/boxing_uppercut_left_window_01 0.845` margin=`0.009` backend=`prototype_matcher`
- `punch_left` at `4924ms` score=`0.900` prototype=`boxing_straight_left_window_04` class=`straight_left` runner-up=`hook_right/boxing_hook_right_window_04 0.898` margin=`0.002` backend=`prototype_matcher`
- `punch_left` at `5253ms` score=`1.000` prototype=`boxing_straight_left_window_04` class=`straight_left` runner-up=`hook_right/boxing_hook_right_window_04 0.884` margin=`0.116` backend=`prototype_matcher`
- `hook_right` at `5575ms` score=`0.878` prototype=`boxing_hook_right_window_04` class=`hook_right` runner-up=`uppercut_right/boxing_uppercut_right_window_01 0.841` margin=`0.037` backend=`prototype_matcher`
- `hook_right` at `5888ms` score=`0.864` prototype=`boxing_hook_right_window_04` class=`hook_right` runner-up=`uppercut_right/boxing_uppercut_right_window_01 0.840` margin=`0.025` backend=`prototype_matcher`
- `hook_right` at `6191ms` score=`0.913` prototype=`boxing_hook_right_window_04` class=`hook_right` runner-up=`straight_left/boxing_straight_left_window_01 0.880` margin=`0.033` backend=`prototype_matcher`
- `punch_left` at `6494ms` score=`0.921` prototype=`boxing_straight_left_window_01` class=`straight_left` runner-up=`hook_right/boxing_hook_right_window_04 0.910` margin=`0.011` backend=`prototype_matcher`
- `punch_left` at `6716ms` score=`0.886` prototype=`boxing_straight_left_window_01` class=`straight_left` runner-up=`uppercut_right/boxing_uppercut_right_window_01 0.862` margin=`0.024` backend=`prototype_matcher`
- `punch_left` at `7026ms` score=`0.872` prototype=`boxing_straight_left_window_01` class=`straight_left` runner-up=`uppercut_left/boxing_uppercut_left_window_04 0.866` margin=`0.006` backend=`prototype_matcher`
- `uppercut_left` at `7333ms` score=`0.883` prototype=`boxing_uppercut_left_window_04` class=`uppercut_left` runner-up=`uppercut_right/boxing_uppercut_right_window_01 0.875` margin=`0.008` backend=`prototype_matcher`
- `uppercut_left` at `7643ms` score=`0.893` prototype=`boxing_uppercut_left_window_04` class=`uppercut_left` runner-up=`uppercut_right/boxing_uppercut_right_window_01 0.891` margin=`0.002` backend=`prototype_matcher`
- `hook_right` at `7956ms` score=`0.851` prototype=`boxing_hook_right_window_04` class=`hook_right` runner-up=`uppercut_right/boxing_uppercut_right_window_01 0.830` margin=`0.021` backend=`prototype_matcher`
- `punch_left` at `8269ms` score=`0.819` prototype=`boxing_straight_left_window_02` class=`straight_left` runner-up=`hook_right/boxing_hook_right_window_01 0.781` margin=`0.037` backend=`prototype_matcher`
- `punch_left` at `8571ms` score=`0.974` prototype=`boxing_straight_left_window_01` class=`straight_left` runner-up=`hook_right/boxing_hook_right_window_04 0.867` margin=`0.107` backend=`prototype_matcher`
- `uppercut_right` at `8890ms` score=`0.908` prototype=`boxing_uppercut_right_window_01` class=`uppercut_right` runner-up=`straight_left/boxing_straight_left_window_01 0.890` margin=`0.018` backend=`prototype_matcher`
- `hook_right` at `9210ms` score=`0.843` prototype=`boxing_hook_right_window_04` class=`hook_right` runner-up=`uppercut_right/boxing_uppercut_right_window_01 0.837` margin=`0.007` backend=`prototype_matcher`
- `punch_left` at `9520ms` score=`0.888` prototype=`boxing_straight_left_window_02` class=`straight_left` runner-up=`hook_right/boxing_hook_right_window_04 0.804` margin=`0.084` backend=`prototype_matcher`
- `hook_right` at `9837ms` score=`0.893` prototype=`boxing_hook_right_window_04` class=`hook_right` runner-up=`straight_left/boxing_straight_left_window_01 0.890` margin=`0.003` backend=`prototype_matcher`

### straight right

- Fixture: `.testbed/assets/fixtures/boxing/straight_right/boxing_guard->straight_right_repeat_04_take_01.yaml`
- Source: `.testbed/assets/fixtures/boxing/straight_right/boxing_guard->straight_right_repeat_04_take_01.mp4`
- Expected event: `punch_right`
- Expected class: `straight_right`
- Attack events emitted: **37**
- Peak snapshot: straight_right via boxing_straight_right_window_02 score=0.988 runner-up=uppercut_left/boxing_uppercut_left_window_04 0.856 margin=0.132
- Strongest expected emit: `punch_right` straight_right via boxing_straight_right_window_02 score=0.988 runner-up=uppercut_left/boxing_uppercut_left_window_04 0.856 margin=0.132
- Strongest wrong emit: `uppercut_left` uppercut_left via boxing_uppercut_left_window_04 score=0.804 runner-up=straight_left/boxing_straight_left_window_01 0.799 margin=0.004
- Emitted prototype counts: `boxing_straight_right_window_04` x17, `boxing_straight_right_window_01` x6, `boxing_uppercut_left_window_04` x5, `boxing_straight_left_window_01` x3, `boxing_straight_right_window_02` x3
- Best-snapshot prototype counts: `boxing_straight_right_window_04` x34, `boxing_straight_right_window_01` x11, `boxing_uppercut_left_window_04` x8, `boxing_straight_left_window_01` x7, `boxing_straight_right_window_02` x7
- emitted expected punch_right 28 time(s)
- also emitted other attack events: punch_left, uppercut_left, punch_left, uppercut_left, uppercut_left, uppercut_left, punch_left, uppercut_left, uppercut_left
- peak expected-class score 0.988
- peak winner straight_right via boxing_straight_right_window_02 scored 0.988; runner-up uppercut_left via boxing_uppercut_left_window_04 scored 0.856 (margin 0.132)
- strongest expected emit used boxing_straight_right_window_02 at 0.988 over runner-up boxing_uppercut_left_window_04 at 0.856 (margin 0.132)
- strongest wrong emit was uppercut_left via boxing_uppercut_left_window_04 at 0.804 over runner-up boxing_straight_left_window_01 at 0.799 (margin 0.004)
- latest matcher reason step_wait

Emitted attack events:
- `punch_right` at `1167ms` score=`0.888` prototype=`boxing_straight_right_window_04` class=`straight_right` runner-up=`straight_left/boxing_straight_left_window_01 0.810` margin=`0.078` backend=`prototype_matcher`
- `punch_right` at `1338ms` score=`0.918` prototype=`boxing_straight_right_window_04` class=`straight_right` runner-up=`uppercut_right/boxing_uppercut_right_window_01 0.813` margin=`0.105` backend=`prototype_matcher`
- `punch_right` at `1588ms` score=`0.923` prototype=`boxing_straight_right_window_03` class=`straight_right` runner-up=`uppercut_right/boxing_uppercut_right_window_01 0.845` margin=`0.078` backend=`prototype_matcher`
- `punch_right` at `1838ms` score=`0.870` prototype=`boxing_straight_right_window_01` class=`straight_right` runner-up=`straight_left/boxing_straight_left_window_01 0.818` margin=`0.052` backend=`prototype_matcher`
- `punch_left` at `2100ms` score=`0.752` prototype=`boxing_straight_left_window_01` class=`straight_left` runner-up=`uppercut_left/boxing_uppercut_left_window_04 0.734` margin=`0.018` backend=`prototype_matcher`
- `punch_right` at `2338ms` score=`0.928` prototype=`boxing_straight_right_window_01` class=`straight_right` runner-up=`uppercut_right/boxing_uppercut_right_window_01 0.893` margin=`0.034` backend=`prototype_matcher`
- `punch_right` at `2588ms` score=`0.900` prototype=`boxing_straight_right_window_04` class=`straight_right` runner-up=`straight_left/boxing_straight_left_window_01 0.830` margin=`0.070` backend=`prototype_matcher`
- `punch_right` at `2838ms` score=`0.890` prototype=`boxing_straight_right_window_02` class=`straight_right` runner-up=`uppercut_left/boxing_uppercut_left_window_04 0.848` margin=`0.043` backend=`prototype_matcher`
- `punch_right` at `3089ms` score=`0.988` prototype=`boxing_straight_right_window_02` class=`straight_right` runner-up=`uppercut_left/boxing_uppercut_left_window_04 0.856` margin=`0.132` backend=`prototype_matcher`
- `uppercut_left` at `3351ms` score=`0.727` prototype=`boxing_uppercut_left_window_04` class=`uppercut_left` runner-up=`straight_left/boxing_straight_left_window_01 0.713` margin=`0.014` backend=`prototype_matcher`
- `punch_right` at `3588ms` score=`0.864` prototype=`boxing_straight_right_window_04` class=`straight_right` runner-up=`straight_left/boxing_straight_left_window_01 0.818` margin=`0.046` backend=`prototype_matcher`
- `punch_right` at `3841ms` score=`0.932` prototype=`boxing_straight_right_window_04` class=`straight_right` runner-up=`uppercut_right/boxing_uppercut_right_window_01 0.825` margin=`0.107` backend=`prototype_matcher`
- `punch_right` at `4094ms` score=`0.931` prototype=`boxing_straight_right_window_04` class=`straight_right` runner-up=`straight_left/boxing_straight_left_window_01 0.919` margin=`0.012` backend=`prototype_matcher`
- `punch_right` at `4341ms` score=`0.985` prototype=`boxing_straight_right_window_03` class=`straight_right` runner-up=`uppercut_right/boxing_uppercut_right_window_01 0.812` margin=`0.173` backend=`prototype_matcher`
- `punch_left` at `4603ms` score=`0.791` prototype=`boxing_straight_left_window_01` class=`straight_left` runner-up=`uppercut_left/boxing_uppercut_left_window_04 0.783` margin=`0.008` backend=`prototype_matcher`
- `uppercut_left` at `4852ms` score=`0.804` prototype=`boxing_uppercut_left_window_04` class=`uppercut_left` runner-up=`straight_left/boxing_straight_left_window_01 0.799` margin=`0.004` backend=`prototype_matcher`
- `punch_right` at `5092ms` score=`0.940` prototype=`boxing_straight_right_window_04` class=`straight_right` runner-up=`uppercut_left/boxing_uppercut_left_window_04 0.825` margin=`0.115` backend=`prototype_matcher`
- `punch_right` at `5340ms` score=`0.974` prototype=`boxing_straight_right_window_04` class=`straight_right` runner-up=`straight_left/boxing_straight_left_window_01 0.881` margin=`0.094` backend=`prototype_matcher`
- `punch_right` at `5592ms` score=`0.973` prototype=`boxing_straight_right_window_04` class=`straight_right` runner-up=`straight_left/boxing_straight_left_window_01 0.855` margin=`0.117` backend=`prototype_matcher`
- `punch_right` at `5844ms` score=`0.965` prototype=`boxing_straight_right_window_04` class=`straight_right` runner-up=`straight_left/boxing_straight_left_window_01 0.849` margin=`0.116` backend=`prototype_matcher`
- `punch_right` at `6069ms` score=`0.931` prototype=`boxing_straight_right_window_04` class=`straight_right` runner-up=`uppercut_right/boxing_uppercut_right_window_01 0.836` margin=`0.095` backend=`prototype_matcher`
- `punch_right` at `6187ms` score=`0.934` prototype=`boxing_straight_right_window_04` class=`straight_right` runner-up=`uppercut_right/boxing_uppercut_right_window_01 0.820` margin=`0.114` backend=`prototype_matcher`
- `uppercut_left` at `6441ms` score=`0.732` prototype=`boxing_uppercut_left_window_04` class=`uppercut_left` runner-up=`straight_left/boxing_straight_left_window_01 0.723` margin=`0.009` backend=`prototype_matcher`
- `uppercut_left` at `6698ms` score=`0.713` prototype=`boxing_uppercut_left_window_02` class=`uppercut_left` runner-up=`straight_left/boxing_straight_left_window_01 0.706` margin=`0.007` backend=`prototype_matcher`
- `punch_right` at `6956ms` score=`0.886` prototype=`boxing_straight_right_window_01` class=`straight_right` runner-up=`straight_left/boxing_straight_left_window_01 0.842` margin=`0.044` backend=`prototype_matcher`
- `punch_right` at `7195ms` score=`0.900` prototype=`boxing_straight_right_window_04` class=`straight_right` runner-up=`uppercut_left/boxing_uppercut_left_window_04 0.796` margin=`0.104` backend=`prototype_matcher`
- `punch_right` at `7443ms` score=`0.925` prototype=`boxing_straight_right_window_01` class=`straight_right` runner-up=`uppercut_right/boxing_uppercut_right_window_01 0.837` margin=`0.089` backend=`prototype_matcher`
- `punch_right` at `7692ms` score=`0.982` prototype=`boxing_straight_right_window_01` class=`straight_right` runner-up=`uppercut_right/boxing_uppercut_right_window_01 0.883` margin=`0.099` backend=`prototype_matcher`
- `punch_left` at `7952ms` score=`0.764` prototype=`boxing_straight_left_window_01` class=`straight_left` runner-up=`uppercut_left/boxing_uppercut_left_window_04 0.736` margin=`0.028` backend=`prototype_matcher`
- `punch_right` at `8190ms` score=`0.844` prototype=`boxing_straight_right_window_04` class=`straight_right` runner-up=`straight_left/boxing_straight_left_window_01 0.837` margin=`0.008` backend=`prototype_matcher`
- `punch_right` at `8443ms` score=`0.918` prototype=`boxing_straight_right_window_04` class=`straight_right` runner-up=`uppercut_left/boxing_uppercut_left_window_04 0.854` margin=`0.064` backend=`prototype_matcher`
- `punch_right` at `8689ms` score=`0.890` prototype=`boxing_straight_right_window_04` class=`straight_right` runner-up=`straight_left/boxing_straight_left_window_01 0.844` margin=`0.046` backend=`prototype_matcher`
- `punch_right` at `8942ms` score=`0.938` prototype=`boxing_straight_right_window_02` class=`straight_right` runner-up=`uppercut_left/boxing_uppercut_left_window_04 0.838` margin=`0.100` backend=`prototype_matcher`
- `uppercut_left` at `9202ms` score=`0.798` prototype=`boxing_uppercut_left_window_04` class=`uppercut_left` runner-up=`straight_left/boxing_straight_left_window_01 0.778` margin=`0.020` backend=`prototype_matcher`
- `uppercut_left` at `9468ms` score=`0.739` prototype=`boxing_uppercut_left_window_04` class=`uppercut_left` runner-up=`straight_left/boxing_straight_left_window_01 0.739` margin=`0.001` backend=`prototype_matcher`
- `punch_right` at `9691ms` score=`0.928` prototype=`boxing_straight_right_window_01` class=`straight_right` runner-up=`uppercut_left/boxing_uppercut_left_window_04 0.840` margin=`0.088` backend=`prototype_matcher`
- `punch_right` at `9941ms` score=`0.945` prototype=`boxing_straight_right_window_04` class=`straight_right` runner-up=`uppercut_left/boxing_uppercut_left_window_04 0.860` margin=`0.086` backend=`prototype_matcher`

### hook left

- Fixture: `.testbed/assets/fixtures/boxing/hook_left/boxing_guard->hook_left_repeat_04_take_01.yaml`
- Source: `.testbed/assets/fixtures/boxing/hook_left/boxing_guard->hook_left_repeat_04_take_01.mp4`
- Expected event: `hook_left`
- Expected class: `hook_left`
- Attack events emitted: **23**
- Peak snapshot: hook_left via boxing_hook_left_window_01 score=0.994 runner-up=straight_left/boxing_straight_left_window_04 0.869 margin=0.125
- Strongest expected emit: `hook_left` hook_left via boxing_hook_left_window_01 score=0.994 runner-up=straight_left/boxing_straight_left_window_04 0.869 margin=0.125
- Strongest wrong emit: `uppercut_left` uppercut_left via boxing_uppercut_left_window_01 score=0.924 runner-up=uppercut_right/boxing_uppercut_right_window_01 0.916 margin=0.008
- Emitted prototype counts: `boxing_hook_right_window_01` x7, `boxing_hook_left_window_01` x5, `boxing_hook_left_window_04` x4, `boxing_uppercut_left_window_01` x3, `boxing_hook_right_window_04` x2
- Best-snapshot prototype counts: `boxing_hook_right_window_01` x19, `boxing_hook_left_window_01` x15, `boxing_hook_left_window_04` x13, `boxing_uppercut_left_window_01` x7, `boxing_hook_right_window_04` x5
- emitted expected hook_left 9 time(s)
- also emitted other attack events: uppercut_right, hook_right, uppercut_right, hook_right, hook_right, hook_right, hook_right, hook_right, hook_right, hook_right, hook_right, uppercut_left, uppercut_left, uppercut_left
- peak expected-class score 0.994
- peak winner hook_left via boxing_hook_left_window_01 scored 0.994; runner-up straight_left via boxing_straight_left_window_04 scored 0.869 (margin 0.125)
- strongest expected emit used boxing_hook_left_window_01 at 0.994 over runner-up boxing_straight_left_window_04 at 0.869 (margin 0.125)
- strongest wrong emit was uppercut_left via boxing_uppercut_left_window_01 at 0.924 over runner-up boxing_uppercut_right_window_01 at 0.916 (margin 0.008)
- latest matcher reason emit_cooldown_active

Emitted attack events:
- `uppercut_right` at `1496ms` score=`0.923` prototype=`boxing_uppercut_right_window_01` class=`uppercut_right` runner-up=`uppercut_left/boxing_uppercut_left_window_01 0.922` margin=`0.001` backend=`prototype_matcher`
- `hook_right` at `1908ms` score=`0.858` prototype=`boxing_hook_right_window_01` class=`hook_right` runner-up=`uppercut_right/boxing_uppercut_right_window_01 0.856` margin=`0.002` backend=`prototype_matcher`
- `uppercut_right` at `2308ms` score=`0.735` prototype=`boxing_uppercut_right_window_03` class=`uppercut_right` runner-up=`hook_left/boxing_hook_left_window_02 0.728` margin=`0.007` backend=`prototype_matcher`
- `hook_right` at `2698ms` score=`0.817` prototype=`boxing_hook_right_window_01` class=`hook_right` runner-up=`hook_left/boxing_hook_left_window_04 0.807` margin=`0.011` backend=`prototype_matcher`
- `hook_left` at `3093ms` score=`0.994` prototype=`boxing_hook_left_window_01` class=`hook_left` runner-up=`straight_left/boxing_straight_left_window_04 0.869` margin=`0.125` backend=`prototype_matcher`
- `hook_left` at `3490ms` score=`0.936` prototype=`boxing_hook_left_window_01` class=`hook_left` runner-up=`straight_left/boxing_straight_left_window_04 0.867` margin=`0.069` backend=`prototype_matcher`
- `hook_left` at `3896ms` score=`0.875` prototype=`boxing_hook_left_window_01` class=`hook_left` runner-up=`straight_left/boxing_straight_left_window_04 0.859` margin=`0.015` backend=`prototype_matcher`
- `hook_right` at `4294ms` score=`0.788` prototype=`boxing_hook_right_window_04` class=`hook_right` runner-up=`hook_left/boxing_hook_left_window_03 0.735` margin=`0.053` backend=`prototype_matcher`
- `hook_right` at `4699ms` score=`0.757` prototype=`boxing_hook_right_window_01` class=`hook_right` runner-up=`uppercut_right/boxing_uppercut_right_window_03 0.714` margin=`0.043` backend=`prototype_matcher`
- `hook_left` at `5116ms` score=`0.926` prototype=`boxing_hook_left_window_04` class=`hook_left` runner-up=`straight_left/boxing_straight_left_window_04 0.827` margin=`0.099` backend=`prototype_matcher`
- `hook_left` at `5507ms` score=`0.912` prototype=`boxing_hook_left_window_01` class=`hook_left` runner-up=`straight_left/boxing_straight_left_window_04 0.824` margin=`0.088` backend=`prototype_matcher`
- `hook_right` at `5922ms` score=`0.781` prototype=`boxing_hook_right_window_01` class=`hook_right` runner-up=`hook_left/boxing_hook_left_window_04 0.772` margin=`0.009` backend=`prototype_matcher`
- `hook_right` at `6317ms` score=`0.777` prototype=`boxing_hook_right_window_04` class=`hook_right` runner-up=`hook_left/boxing_hook_left_window_02 0.709` margin=`0.068` backend=`prototype_matcher`
- `hook_right` at `6703ms` score=`0.794` prototype=`boxing_hook_right_window_01` class=`hook_right` runner-up=`uppercut_right/boxing_uppercut_right_window_04 0.710` margin=`0.084` backend=`prototype_matcher`
- `hook_left` at `7111ms` score=`0.922` prototype=`boxing_hook_left_window_04` class=`hook_left` runner-up=`straight_left/boxing_straight_left_window_04 0.812` margin=`0.110` backend=`prototype_matcher`
- `hook_left` at `7498ms` score=`0.977` prototype=`boxing_hook_left_window_04` class=`hook_left` runner-up=`straight_left/boxing_straight_left_window_04 0.838` margin=`0.139` backend=`prototype_matcher`
- `hook_left` at `7922ms` score=`0.765` prototype=`boxing_hook_left_window_04` class=`hook_left` runner-up=`hook_right/boxing_hook_right_window_01 0.761` margin=`0.005` backend=`prototype_matcher`
- `hook_right` at `8313ms` score=`0.787` prototype=`boxing_hook_right_window_01` class=`hook_right` runner-up=`uppercut_right/boxing_uppercut_right_window_01 0.687` margin=`0.100` backend=`prototype_matcher`
- `hook_right` at `8731ms` score=`0.811` prototype=`boxing_hook_right_window_01` class=`hook_right` runner-up=`uppercut_right/boxing_uppercut_right_window_01 0.717` margin=`0.094` backend=`prototype_matcher`
- `hook_left` at `9126ms` score=`0.897` prototype=`boxing_hook_left_window_01` class=`hook_left` runner-up=`hook_right/boxing_hook_right_window_04 0.882` margin=`0.014` backend=`prototype_matcher`
- `uppercut_left` at `9515ms` score=`0.878` prototype=`boxing_uppercut_left_window_01` class=`uppercut_left` runner-up=`hook_right/boxing_hook_right_window_01 0.874` margin=`0.004` backend=`prototype_matcher`
- `uppercut_left` at `9897ms` score=`0.892` prototype=`boxing_uppercut_left_window_01` class=`uppercut_left` runner-up=`hook_right/boxing_hook_right_window_01 0.873` margin=`0.019` backend=`prototype_matcher`
- `uppercut_left` at `10220ms` score=`0.924` prototype=`boxing_uppercut_left_window_01` class=`uppercut_left` runner-up=`uppercut_right/boxing_uppercut_right_window_01 0.916` margin=`0.008` backend=`prototype_matcher`

### hook right

- Fixture: `.testbed/assets/fixtures/boxing/hook_right/boxing_guard->hook_right_repeat_04_take_01.yaml`
- Source: `.testbed/assets/fixtures/boxing/hook_right/boxing_guard->hook_right_repeat_04_take_01.mp4`
- Expected event: `hook_right`
- Expected class: `hook_right`
- Attack events emitted: **23**
- Peak snapshot: hook_right via boxing_hook_right_window_01 score=0.983 runner-up=uppercut_left/boxing_uppercut_left_window_01 0.844 margin=0.139
- Strongest expected emit: `hook_right` hook_right via boxing_hook_right_window_01 score=0.975 runner-up=uppercut_left/boxing_uppercut_left_window_01 0.862 margin=0.112
- Strongest wrong emit: `hook_left` hook_left via boxing_hook_left_window_01 score=0.900 runner-up=hook_right/boxing_hook_right_window_04 0.873 margin=0.027
- Emitted prototype counts: `boxing_hook_right_window_01` x7, `boxing_hook_left_window_01` x6, `boxing_hook_right_window_02` x4, `boxing_hook_right_window_04` x2, `boxing_hook_left_window_04` x1
- Best-snapshot prototype counts: `boxing_hook_left_window_01` x18, `boxing_hook_right_window_01` x16, `boxing_hook_right_window_02` x11, `boxing_hook_right_window_04` x11, `boxing_hook_left_window_04` x4
- emitted expected hook_right 14 time(s)
- also emitted other attack events: uppercut_left, hook_left, hook_left, hook_left, hook_left, hook_left, hook_left, punch_left, hook_left
- peak expected-class score 0.983
- peak winner hook_right via boxing_hook_right_window_01 scored 0.983; runner-up uppercut_left via boxing_uppercut_left_window_01 scored 0.844 (margin 0.139)
- strongest expected emit used boxing_hook_right_window_01 at 0.975 over runner-up boxing_uppercut_left_window_01 at 0.862 (margin 0.112)
- strongest wrong emit was hook_left via boxing_hook_left_window_01 at 0.900 over runner-up boxing_hook_right_window_04 at 0.873 (margin 0.027)
- latest matcher reason window_not_full

Emitted attack events:
- `hook_right` at `1610ms` score=`0.921` prototype=`boxing_hook_right_window_01` class=`hook_right` runner-up=`uppercut_left/boxing_uppercut_left_window_01 0.881` margin=`0.040` backend=`prototype_matcher`
- `uppercut_left` at `1928ms` score=`0.865` prototype=`boxing_uppercut_left_window_01` class=`uppercut_left` runner-up=`straight_left/boxing_straight_left_window_01 0.846` margin=`0.019` backend=`prototype_matcher`
- `hook_right` at `2312ms` score=`0.769` prototype=`boxing_hook_right_window_02` class=`hook_right` runner-up=`hook_left/boxing_hook_left_window_01 0.688` margin=`0.081` backend=`prototype_matcher`
- `hook_right` at `2705ms` score=`0.792` prototype=`boxing_hook_right_window_01` class=`hook_right` runner-up=`hook_left/boxing_hook_left_window_01 0.765` margin=`0.028` backend=`prototype_matcher`
- `hook_right` at `3101ms` score=`0.975` prototype=`boxing_hook_right_window_01` class=`hook_right` runner-up=`uppercut_left/boxing_uppercut_left_window_01 0.862` margin=`0.112` backend=`prototype_matcher`
- `hook_right` at `3504ms` score=`0.928` prototype=`boxing_hook_right_window_01` class=`hook_right` runner-up=`uppercut_left/boxing_uppercut_left_window_01 0.880` margin=`0.049` backend=`prototype_matcher`
- `hook_left` at `3907ms` score=`0.878` prototype=`boxing_hook_left_window_01` class=`hook_left` runner-up=`straight_left/boxing_straight_left_window_04 0.859` margin=`0.019` backend=`prototype_matcher`
- `hook_right` at `4318ms` score=`0.765` prototype=`boxing_hook_right_window_03` class=`hook_right` runner-up=`hook_left/boxing_hook_left_window_01 0.723` margin=`0.042` backend=`prototype_matcher`
- `hook_right` at `4715ms` score=`0.814` prototype=`boxing_hook_right_window_02` class=`hook_right` runner-up=`hook_left/boxing_hook_left_window_01 0.797` margin=`0.017` backend=`prototype_matcher`
- `hook_left` at `5092ms` score=`0.900` prototype=`boxing_hook_left_window_01` class=`hook_left` runner-up=`hook_right/boxing_hook_right_window_04 0.873` margin=`0.027` backend=`prototype_matcher`
- `hook_right` at `5493ms` score=`0.912` prototype=`boxing_hook_right_window_01` class=`hook_right` runner-up=`hook_left/boxing_hook_left_window_01 0.866` margin=`0.046` backend=`prototype_matcher`
- `hook_left` at `5920ms` score=`0.870` prototype=`boxing_hook_left_window_01` class=`hook_left` runner-up=`straight_left/boxing_straight_left_window_04 0.845` margin=`0.024` backend=`prototype_matcher`
- `hook_right` at `6306ms` score=`0.745` prototype=`boxing_hook_right_window_02` class=`hook_right` runner-up=`hook_left/boxing_hook_left_window_01 0.655` margin=`0.090` backend=`prototype_matcher`
- `hook_left` at `6734ms` score=`0.854` prototype=`boxing_hook_left_window_04` class=`hook_left` runner-up=`straight_left/boxing_straight_left_window_04 0.805` margin=`0.048` backend=`prototype_matcher`
- `hook_left` at `7126ms` score=`0.865` prototype=`boxing_hook_left_window_01` class=`hook_left` runner-up=`hook_right/boxing_hook_right_window_04 0.864` margin=`0.001` backend=`prototype_matcher`
- `hook_right` at `7520ms` score=`0.971` prototype=`boxing_hook_right_window_04` class=`hook_right` runner-up=`hook_left/boxing_hook_left_window_01 0.854` margin=`0.117` backend=`prototype_matcher`
- `hook_left` at `7944ms` score=`0.870` prototype=`boxing_hook_left_window_01` class=`hook_left` runner-up=`straight_left/boxing_straight_left_window_04 0.849` margin=`0.020` backend=`prototype_matcher`
- `punch_left` at `8360ms` score=`0.748` prototype=`boxing_straight_left_window_04` class=`straight_left` runner-up=`hook_left/boxing_hook_left_window_01 0.729` margin=`0.019` backend=`prototype_matcher`
- `hook_right` at `8738ms` score=`0.806` prototype=`boxing_hook_right_window_02` class=`hook_right` runner-up=`hook_left/boxing_hook_left_window_01 0.731` margin=`0.075` backend=`prototype_matcher`
- `hook_left` at `9144ms` score=`0.898` prototype=`boxing_hook_left_window_01` class=`hook_left` runner-up=`straight_left/boxing_straight_left_window_04 0.857` margin=`0.042` backend=`prototype_matcher`
- `hook_right` at `9544ms` score=`0.929` prototype=`boxing_hook_right_window_04` class=`hook_right` runner-up=`hook_left/boxing_hook_left_window_01 0.885` margin=`0.044` backend=`prototype_matcher`
- `hook_right` at `9934ms` score=`0.922` prototype=`boxing_hook_right_window_01` class=`hook_right` runner-up=`uppercut_left/boxing_uppercut_left_window_01 0.887` margin=`0.035` backend=`prototype_matcher`
- `hook_right` at `10317ms` score=`0.936` prototype=`boxing_hook_right_window_01` class=`hook_right` runner-up=`uppercut_left/boxing_uppercut_left_window_01 0.886` margin=`0.050` backend=`prototype_matcher`

### uppercut left

- Fixture: `.testbed/assets/fixtures/boxing/uppercut_left/boxing_guard->uppercut_left_repeat_04_take_01.yaml`
- Source: `.testbed/assets/fixtures/boxing/uppercut_left/boxing_guard->uppercut_left_repeat_04_take_01.mp4`
- Expected event: `uppercut_left`
- Expected class: `uppercut_left`
- Attack events emitted: **23**
- Peak snapshot: uppercut_left via boxing_uppercut_left_window_02 score=1.000 runner-up=straight_right/boxing_straight_right_window_03 0.840 margin=0.160
- Strongest expected emit: `uppercut_left` uppercut_left via boxing_uppercut_left_window_01 score=0.972 runner-up=uppercut_right/boxing_uppercut_right_window_01 0.871 margin=0.101
- Strongest wrong emit: `uppercut_right` uppercut_right via boxing_uppercut_right_window_01 score=0.940 runner-up=uppercut_left/boxing_uppercut_left_window_01 0.901 margin=0.039
- Emitted prototype counts: `boxing_uppercut_left_window_04` x5, `boxing_uppercut_left_window_01` x3, `boxing_uppercut_right_window_01` x3, `boxing_hook_left_window_04` x2, `boxing_hook_right_window_01` x2
- Best-snapshot prototype counts: `boxing_uppercut_left_window_04` x16, `boxing_uppercut_left_window_01` x12, `boxing_uppercut_right_window_01` x10, `boxing_hook_right_window_04` x7, `boxing_hook_right_window_01` x6
- emitted expected uppercut_left 12 time(s)
- also emitted other attack events: hook_right, hook_right, uppercut_right, hook_left, hook_right, punch_right, uppercut_right, punch_left, hook_right, hook_left, uppercut_right
- peak expected-class score 1.000
- peak winner uppercut_left via boxing_uppercut_left_window_02 scored 1.000; runner-up straight_right via boxing_straight_right_window_03 scored 0.840 (margin 0.160)
- strongest expected emit used boxing_uppercut_left_window_01 at 0.972 over runner-up boxing_uppercut_right_window_01 at 0.871 (margin 0.101)
- strongest wrong emit was uppercut_right via boxing_uppercut_right_window_01 at 0.940 over runner-up boxing_uppercut_left_window_01 at 0.901 (margin 0.039)
- latest matcher reason window_not_full

Emitted attack events:
- `hook_right` at `1602ms` score=`0.777` prototype=`boxing_hook_right_window_01` class=`hook_right` runner-up=`uppercut_right/boxing_uppercut_right_window_01 0.720` margin=`0.057` backend=`prototype_matcher`
- `hook_right` at `2000ms` score=`0.772` prototype=`boxing_hook_right_window_04` class=`hook_right` runner-up=`uppercut_left/boxing_uppercut_left_window_01 0.686` margin=`0.085` backend=`prototype_matcher`
- `uppercut_left` at `2406ms` score=`0.860` prototype=`boxing_uppercut_left_window_01` class=`uppercut_left` runner-up=`uppercut_right/boxing_uppercut_right_window_01 0.814` margin=`0.045` backend=`prototype_matcher`
- `uppercut_left` at `2800ms` score=`0.972` prototype=`boxing_uppercut_left_window_01` class=`uppercut_left` runner-up=`uppercut_right/boxing_uppercut_right_window_01 0.871` margin=`0.101` backend=`prototype_matcher`
- `uppercut_left` at `3199ms` score=`0.952` prototype=`boxing_uppercut_left_window_01` class=`uppercut_left` runner-up=`uppercut_right/boxing_uppercut_right_window_01 0.913` margin=`0.039` backend=`prototype_matcher`
- `uppercut_right` at `3600ms` score=`0.940` prototype=`boxing_uppercut_right_window_01` class=`uppercut_right` runner-up=`uppercut_left/boxing_uppercut_left_window_01 0.901` margin=`0.039` backend=`prototype_matcher`
- `hook_left` at `4023ms` score=`0.880` prototype=`boxing_hook_left_window_04` class=`hook_left` runner-up=`straight_left/boxing_straight_left_window_04 0.806` margin=`0.074` backend=`prototype_matcher`
- `hook_right` at `4421ms` score=`0.762` prototype=`boxing_hook_right_window_01` class=`hook_right` runner-up=`uppercut_left/boxing_uppercut_left_window_03 0.710` margin=`0.052` backend=`prototype_matcher`
- `uppercut_left` at `4806ms` score=`0.846` prototype=`boxing_uppercut_left_window_02` class=`uppercut_left` runner-up=`straight_right/boxing_straight_right_window_01 0.825` margin=`0.021` backend=`prototype_matcher`
- `uppercut_left` at `5209ms` score=`0.910` prototype=`boxing_uppercut_left_window_04` class=`uppercut_left` runner-up=`straight_right/boxing_straight_right_window_01 0.849` margin=`0.061` backend=`prototype_matcher`
- `punch_right` at `5601ms` score=`0.905` prototype=`boxing_straight_right_window_01` class=`straight_right` runner-up=`uppercut_left/boxing_uppercut_left_window_04 0.896` margin=`0.009` backend=`prototype_matcher`
- `uppercut_right` at `5998ms` score=`0.913` prototype=`boxing_uppercut_right_window_01` class=`uppercut_right` runner-up=`uppercut_left/boxing_uppercut_left_window_04 0.893` margin=`0.020` backend=`prototype_matcher`
- `punch_left` at `6416ms` score=`0.909` prototype=`boxing_straight_left_window_01` class=`straight_left` runner-up=`uppercut_right/boxing_uppercut_right_window_01 0.887` margin=`0.022` backend=`prototype_matcher`
- `uppercut_left` at `6796ms` score=`0.741` prototype=`boxing_uppercut_left_window_03` class=`uppercut_left` runner-up=`hook_right/boxing_hook_right_window_01 0.702` margin=`0.039` backend=`prototype_matcher`
- `hook_right` at `7204ms` score=`0.781` prototype=`boxing_hook_right_window_04` class=`hook_right` runner-up=`uppercut_right/boxing_uppercut_right_window_01 0.724` margin=`0.057` backend=`prototype_matcher`
- `uppercut_left` at `7606ms` score=`0.903` prototype=`boxing_uppercut_left_window_04` class=`uppercut_left` runner-up=`straight_right/boxing_straight_right_window_01 0.869` margin=`0.034` backend=`prototype_matcher`
- `uppercut_left` at `8003ms` score=`0.916` prototype=`boxing_uppercut_left_window_04` class=`uppercut_left` runner-up=`straight_right/boxing_straight_right_window_01 0.888` margin=`0.028` backend=`prototype_matcher`
- `uppercut_left` at `8401ms` score=`0.928` prototype=`boxing_uppercut_left_window_04` class=`uppercut_left` runner-up=`straight_right/boxing_straight_right_window_01 0.902` margin=`0.026` backend=`prototype_matcher`
- `uppercut_left` at `8790ms` score=`0.945` prototype=`boxing_uppercut_left_window_04` class=`uppercut_left` runner-up=`uppercut_right/boxing_uppercut_right_window_01 0.923` margin=`0.023` backend=`prototype_matcher`
- `hook_left` at `9196ms` score=`0.857` prototype=`boxing_hook_left_window_04` class=`hook_left` runner-up=`straight_left/boxing_straight_left_window_04 0.817` margin=`0.040` backend=`prototype_matcher`
- `uppercut_left` at `9599ms` score=`0.760` prototype=`boxing_uppercut_left_window_03` class=`uppercut_left` runner-up=`hook_right/boxing_hook_right_window_01 0.748` margin=`0.012` backend=`prototype_matcher`
- `uppercut_left` at `9979ms` score=`0.829` prototype=`boxing_uppercut_left_window_02` class=`uppercut_left` runner-up=`hook_right/boxing_hook_right_window_04 0.820` margin=`0.008` backend=`prototype_matcher`
- `uppercut_right` at `10373ms` score=`0.905` prototype=`boxing_uppercut_right_window_01` class=`uppercut_right` runner-up=`uppercut_left/boxing_uppercut_left_window_04 0.900` margin=`0.005` backend=`prototype_matcher`

### uppercut right

- Fixture: `.testbed/assets/fixtures/boxing/uppercut_right/boxing_guard->uppercut_right_repeat_04_take_01.yaml`
- Source: `.testbed/assets/fixtures/boxing/uppercut_right/boxing_guard->uppercut_right_repeat_04_take_01.mp4`
- Expected event: `uppercut_right`
- Expected class: `uppercut_right`
- Attack events emitted: **23**
- Peak snapshot: uppercut_right via boxing_uppercut_right_window_01 score=1.000 runner-up=straight_left/boxing_straight_left_window_01 0.898 margin=0.102
- Strongest expected emit: `uppercut_right` uppercut_right via boxing_uppercut_right_window_01 score=1.000 runner-up=straight_left/boxing_straight_left_window_01 0.898 margin=0.102
- Strongest wrong emit: `hook_right` hook_right via boxing_hook_right_window_04 score=0.920 runner-up=uppercut_right/boxing_uppercut_right_window_01 0.890 margin=0.031
- Emitted prototype counts: `boxing_uppercut_right_window_01` x9, `boxing_hook_left_window_01` x4, `boxing_hook_left_window_04` x3, `boxing_hook_right_window_01` x2, `boxing_hook_right_window_04` x2
- Best-snapshot prototype counts: `boxing_uppercut_right_window_01` x23, `boxing_hook_left_window_04` x11, `boxing_hook_right_window_01` x10, `boxing_hook_left_window_01` x9, `boxing_hook_right_window_04` x3
- emitted expected uppercut_right 11 time(s)
- also emitted other attack events: hook_left, punch_left, hook_left, hook_left, hook_left, hook_left, hook_right, hook_right, hook_left, hook_right, hook_right, hook_left
- peak expected-class score 1.000
- peak winner uppercut_right via boxing_uppercut_right_window_01 scored 1.000; runner-up straight_left via boxing_straight_left_window_01 scored 0.898 (margin 0.102)
- strongest expected emit used boxing_uppercut_right_window_01 at 1.000 over runner-up boxing_straight_left_window_01 at 0.898 (margin 0.102)
- strongest wrong emit was hook_right via boxing_hook_right_window_04 at 0.920 over runner-up boxing_uppercut_right_window_01 at 0.890 (margin 0.031)
- latest matcher reason emitted

Emitted attack events:
- `uppercut_right` at `1648ms` score=`0.793` prototype=`boxing_uppercut_right_window_03` class=`uppercut_right` runner-up=`hook_left/boxing_hook_left_window_01 0.762` margin=`0.031` backend=`prototype_matcher`
- `hook_left` at `2021ms` score=`0.882` prototype=`boxing_hook_left_window_04` class=`hook_left` runner-up=`straight_left/boxing_straight_left_window_04 0.771` margin=`0.111` backend=`prototype_matcher`
- `punch_left` at `2424ms` score=`0.850` prototype=`boxing_straight_left_window_01` class=`straight_left` runner-up=`uppercut_right/boxing_uppercut_right_window_01 0.840` margin=`0.010` backend=`prototype_matcher`
- `uppercut_right` at `2826ms` score=`1.000` prototype=`boxing_uppercut_right_window_01` class=`uppercut_right` runner-up=`straight_left/boxing_straight_left_window_01 0.898` margin=`0.102` backend=`prototype_matcher`
- `uppercut_right` at `3223ms` score=`0.952` prototype=`boxing_uppercut_right_window_01` class=`uppercut_right` runner-up=`straight_right/boxing_straight_right_window_01 0.902` margin=`0.050` backend=`prototype_matcher`
- `uppercut_right` at `3633ms` score=`0.921` prototype=`boxing_uppercut_right_window_01` class=`uppercut_right` runner-up=`uppercut_left/boxing_uppercut_left_window_01 0.890` margin=`0.031` backend=`prototype_matcher`
- `hook_left` at `4312ms` score=`0.799` prototype=`boxing_hook_left_window_01` class=`hook_left` runner-up=`straight_left/boxing_straight_left_window_04 0.735` margin=`0.064` backend=`prototype_matcher`
- `uppercut_right` at `4732ms` score=`0.901` prototype=`boxing_uppercut_right_window_01` class=`uppercut_right` runner-up=`straight_left/boxing_straight_left_window_01 0.864` margin=`0.037` backend=`prototype_matcher`
- `uppercut_right` at `5134ms` score=`0.925` prototype=`boxing_uppercut_right_window_01` class=`uppercut_right` runner-up=`straight_right/boxing_straight_right_window_01 0.915` margin=`0.010` backend=`prototype_matcher`
- `uppercut_right` at `5549ms` score=`0.922` prototype=`boxing_uppercut_right_window_01` class=`uppercut_right` runner-up=`straight_right/boxing_straight_right_window_01 0.914` margin=`0.008` backend=`prototype_matcher`
- `hook_left` at `5987ms` score=`0.868` prototype=`boxing_hook_left_window_01` class=`hook_left` runner-up=`straight_left/boxing_straight_left_window_04 0.843` margin=`0.025` backend=`prototype_matcher`
- `hook_left` at `6394ms` score=`0.906` prototype=`boxing_hook_left_window_04` class=`hook_left` runner-up=`straight_left/boxing_straight_left_window_04 0.818` margin=`0.088` backend=`prototype_matcher`
- `hook_left` at `6783ms` score=`0.897` prototype=`boxing_hook_left_window_01` class=`hook_left` runner-up=`straight_left/boxing_straight_left_window_04 0.833` margin=`0.063` backend=`prototype_matcher`
- `hook_right` at `7190ms` score=`0.920` prototype=`boxing_hook_right_window_04` class=`hook_right` runner-up=`uppercut_right/boxing_uppercut_right_window_01 0.890` margin=`0.031` backend=`prototype_matcher`
- `hook_right` at `7623ms` score=`0.878` prototype=`boxing_hook_right_window_01` class=`hook_right` runner-up=`uppercut_right/boxing_uppercut_right_window_01 0.853` margin=`0.025` backend=`prototype_matcher`
- `uppercut_right` at `8043ms` score=`0.786` prototype=`boxing_uppercut_right_window_04` class=`uppercut_right` runner-up=`hook_left/boxing_hook_left_window_01 0.763` margin=`0.023` backend=`prototype_matcher`
- `hook_left` at `8454ms` score=`0.886` prototype=`boxing_hook_left_window_04` class=`hook_left` runner-up=`straight_left/boxing_straight_left_window_04 0.763` margin=`0.123` backend=`prototype_matcher`
- `uppercut_right` at `8821ms` score=`0.877` prototype=`boxing_uppercut_right_window_01` class=`uppercut_right` runner-up=`straight_left/boxing_straight_left_window_01 0.863` margin=`0.014` backend=`prototype_matcher`
- `uppercut_right` at `9199ms` score=`0.947` prototype=`boxing_uppercut_right_window_01` class=`uppercut_right` runner-up=`straight_right/boxing_straight_right_window_01 0.870` margin=`0.077` backend=`prototype_matcher`
- `uppercut_right` at `9595ms` score=`0.901` prototype=`boxing_uppercut_right_window_01` class=`uppercut_right` runner-up=`uppercut_left/boxing_uppercut_left_window_01 0.900` margin=`0.002` backend=`prototype_matcher`
- `hook_right` at `9923ms` score=`0.910` prototype=`boxing_hook_right_window_04` class=`hook_right` runner-up=`uppercut_right/boxing_uppercut_right_window_01 0.892` margin=`0.018` backend=`prototype_matcher`
- `hook_right` at `10327ms` score=`0.899` prototype=`boxing_hook_right_window_01` class=`hook_right` runner-up=`uppercut_left/boxing_uppercut_left_window_01 0.876` margin=`0.024` backend=`prototype_matcher`
- `hook_left` at `10731ms` score=`0.787` prototype=`boxing_hook_left_window_01` class=`hook_left` runner-up=`straight_left/boxing_straight_left_window_04 0.734` margin=`0.053` backend=`prototype_matcher`

### negative control - running in place

- Fixture: `.testbed/assets/fixtures/boxing/run_in_place/boxing_guard->run_in_place_repeat_01_take_01.yaml`
- Source: `.testbed/assets/fixtures/boxing/run_in_place/boxing_guard->run_in_place_repeat_01_take_01.mp4`
- Expected event: `None`
- Expected class: `None`
- Attack events emitted: **23**
- Peak snapshot: hook_left via boxing_hook_left_window_04 score=0.935 runner-up=straight_left/boxing_straight_left_window_04 0.845 margin=0.089
- Strongest wrong emit: `hook_left` hook_left via boxing_hook_left_window_04 score=0.935 runner-up=straight_left/boxing_straight_left_window_04 0.845 margin=0.089
- Emitted prototype counts: `boxing_hook_left_window_04` x10, `boxing_hook_left_window_01` x9, `boxing_straight_left_window_01` x2, `boxing_hook_right_window_01` x1, `boxing_hook_right_window_04` x1
- Best-snapshot prototype counts: `boxing_hook_left_window_04` x31, `boxing_hook_left_window_01` x27, `boxing_straight_left_window_01` x4, `boxing_hook_right_window_01` x2, `boxing_hook_right_window_04` x2
- negative control still emitted attack events: punch_left, hook_left, hook_left, hook_left, hook_left, hook_left, hook_left, hook_left, hook_left, hook_left, hook_left, hook_left, hook_left, hook_left, hook_right, hook_right, punch_left, hook_left, hook_left, hook_left, hook_left, hook_left, hook_left
- peak winner hook_left via boxing_hook_left_window_04 scored 0.935; runner-up straight_left via boxing_straight_left_window_04 scored 0.845 (margin 0.089)
- strongest wrong emit was hook_left via boxing_hook_left_window_04 at 0.935 over runner-up boxing_straight_left_window_04 at 0.845 (margin 0.089)
- latest matcher reason step_wait

Emitted attack events:
- `punch_left` at `1588ms` score=`0.836` prototype=`boxing_straight_left_window_01` class=`straight_left` runner-up=`uppercut_left/boxing_uppercut_left_window_01 0.819` margin=`0.017` backend=`prototype_matcher`
- `hook_left` at `1978ms` score=`0.814` prototype=`boxing_hook_left_window_04` class=`hook_left` runner-up=`straight_left/boxing_straight_left_window_04 0.812` margin=`0.003` backend=`prototype_matcher`
- `hook_left` at `2379ms` score=`0.885` prototype=`boxing_hook_left_window_04` class=`hook_left` runner-up=`straight_left/boxing_straight_left_window_04 0.833` margin=`0.052` backend=`prototype_matcher`
- `hook_left` at `2776ms` score=`0.908` prototype=`boxing_hook_left_window_04` class=`hook_left` runner-up=`straight_left/boxing_straight_left_window_04 0.839` margin=`0.069` backend=`prototype_matcher`
- `hook_left` at `3200ms` score=`0.935` prototype=`boxing_hook_left_window_04` class=`hook_left` runner-up=`straight_left/boxing_straight_left_window_04 0.845` margin=`0.089` backend=`prototype_matcher`
- `hook_left` at `3584ms` score=`0.925` prototype=`boxing_hook_left_window_04` class=`hook_left` runner-up=`straight_left/boxing_straight_left_window_04 0.857` margin=`0.068` backend=`prototype_matcher`
- `hook_left` at `3983ms` score=`0.886` prototype=`boxing_hook_left_window_01` class=`hook_left` runner-up=`straight_left/boxing_straight_left_window_04 0.854` margin=`0.032` backend=`prototype_matcher`
- `hook_left` at `4388ms` score=`0.901` prototype=`boxing_hook_left_window_01` class=`hook_left` runner-up=`straight_left/boxing_straight_left_window_04 0.851` margin=`0.051` backend=`prototype_matcher`
- `hook_left` at `4775ms` score=`0.911` prototype=`boxing_hook_left_window_01` class=`hook_left` runner-up=`straight_left/boxing_straight_left_window_04 0.871` margin=`0.040` backend=`prototype_matcher`
- `hook_left` at `5174ms` score=`0.904` prototype=`boxing_hook_left_window_01` class=`hook_left` runner-up=`straight_left/boxing_straight_left_window_04 0.866` margin=`0.038` backend=`prototype_matcher`
- `hook_left` at `5565ms` score=`0.878` prototype=`boxing_hook_left_window_01` class=`hook_left` runner-up=`straight_left/boxing_straight_left_window_04 0.854` margin=`0.024` backend=`prototype_matcher`
- `hook_left` at `5964ms` score=`0.883` prototype=`boxing_hook_left_window_01` class=`hook_left` runner-up=`straight_left/boxing_straight_left_window_04 0.836` margin=`0.047` backend=`prototype_matcher`
- `hook_left` at `6340ms` score=`0.890` prototype=`boxing_hook_left_window_01` class=`hook_left` runner-up=`straight_left/boxing_straight_left_window_04 0.859` margin=`0.031` backend=`prototype_matcher`
- `hook_left` at `6735ms` score=`0.882` prototype=`boxing_hook_left_window_01` class=`hook_left` runner-up=`straight_left/boxing_straight_left_window_04 0.846` margin=`0.036` backend=`prototype_matcher`
- `hook_right` at `7072ms` score=`0.919` prototype=`boxing_hook_right_window_04` class=`hook_right` runner-up=`uppercut_left/boxing_uppercut_left_window_01 0.854` margin=`0.065` backend=`prototype_matcher`
- `hook_right` at `7413ms` score=`0.880` prototype=`boxing_hook_right_window_01` class=`hook_right` runner-up=`uppercut_left/boxing_uppercut_left_window_01 0.853` margin=`0.028` backend=`prototype_matcher`
- `punch_left` at `7808ms` score=`0.899` prototype=`boxing_straight_left_window_01` class=`straight_left` runner-up=`uppercut_left/boxing_uppercut_left_window_01 0.859` margin=`0.040` backend=`prototype_matcher`
- `hook_left` at `8214ms` score=`0.867` prototype=`boxing_hook_left_window_01` class=`hook_left` runner-up=`straight_left/boxing_straight_left_window_04 0.834` margin=`0.033` backend=`prototype_matcher`
- `hook_left` at `8620ms` score=`0.826` prototype=`boxing_hook_left_window_04` class=`hook_left` runner-up=`straight_left/boxing_straight_left_window_04 0.822` margin=`0.003` backend=`prototype_matcher`
- `hook_left` at `9022ms` score=`0.885` prototype=`boxing_hook_left_window_04` class=`hook_left` runner-up=`straight_left/boxing_straight_left_window_04 0.814` margin=`0.071` backend=`prototype_matcher`
- `hook_left` at `9412ms` score=`0.917` prototype=`boxing_hook_left_window_04` class=`hook_left` runner-up=`straight_left/boxing_straight_left_window_04 0.851` margin=`0.065` backend=`prototype_matcher`
- `hook_left` at `9817ms` score=`0.932` prototype=`boxing_hook_left_window_04` class=`hook_left` runner-up=`straight_left/boxing_straight_left_window_04 0.861` margin=`0.071` backend=`prototype_matcher`
- `hook_left` at `10224ms` score=`0.920` prototype=`boxing_hook_left_window_04` class=`hook_left` runner-up=`straight_left/boxing_straight_left_window_04 0.857` margin=`0.063` backend=`prototype_matcher`
