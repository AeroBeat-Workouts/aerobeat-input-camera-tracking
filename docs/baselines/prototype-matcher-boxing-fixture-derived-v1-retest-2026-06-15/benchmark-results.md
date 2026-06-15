# Prototype Matcher Fixture Benchmark

- Benchmark ID: `prototype_matcher_boxing_fixture_derived_v1`
- Library ID: `boxing_side_aware_fixture_derived_v1`
- Profile: `boxing`
- Generated At: `2026-06-15T14:38:26-04:00`
- Runner: `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/scripts/run_prototype_matcher_fixture_benchmark.py`

## Aggregate

- Fixture count: **7**
- Negative controls clean: **0 / 1**
- Negative-control false-positive classes: `hook_left` x24, `straight_left` x4, `hook_right` x2
- Negative-control false-positive prototypes: `boxing_hook_left_window_01` x24, `boxing_hook_right_window_03` x2, `boxing_straight_left_window_03` x2, `boxing_straight_left_window_01` x1, `boxing_straight_left_window_02` x1

## Per Fixture

### straight left

- Fixture: `.testbed/assets/fixtures/boxing/straight_left/boxing_guard->straight_left_repeat_04_take_01.yaml`
- Source: `.testbed/assets/fixtures/boxing/straight_left/boxing_guard->straight_left_repeat_04_take_01.mp4`
- Expected event: `punch_left`
- Expected class: `straight_left`
- Attack events emitted: **29**
- Peak snapshot: straight_left via boxing_straight_left_window_01 score=1.000 runner-up=uppercut_right/boxing_uppercut_right_window_04 0.913 margin=0.087
- Strongest expected emit: `punch_left` straight_left via boxing_straight_left_window_03 score=0.976 runner-up=uppercut_right/boxing_uppercut_right_window_04 0.930 margin=0.046
- Strongest wrong emit: `hook_right` hook_right via boxing_hook_right_window_01 score=0.941 runner-up=straight_left/boxing_straight_left_window_04 0.931 margin=0.010
- Emitted prototype counts: `boxing_uppercut_right_window_04` x13, `boxing_uppercut_left_window_02` x5, `boxing_straight_left_window_01` x4, `boxing_hook_right_window_01` x3, `boxing_straight_left_window_03` x2
- Best-snapshot prototype counts: `boxing_uppercut_right_window_04` x37, `boxing_straight_left_window_01` x14, `boxing_uppercut_left_window_02` x13, `boxing_hook_right_window_01` x8, `boxing_straight_left_window_03` x5
- emitted expected punch_left 7 time(s)
- also emitted other attack events: uppercut_left, uppercut_right, uppercut_right, uppercut_right, uppercut_right, uppercut_right, hook_right, hook_right, uppercut_right, uppercut_right, hook_right, uppercut_right, uppercut_right, hook_right, uppercut_left, uppercut_left, uppercut_left, uppercut_left, uppercut_right, uppercut_right, uppercut_right, uppercut_right
- peak expected-class score 1.000
- peak winner straight_left via boxing_straight_left_window_01 scored 1.000; runner-up uppercut_right via boxing_uppercut_right_window_04 scored 0.913 (margin 0.087)
- strongest expected emit used boxing_straight_left_window_03 at 0.976 over runner-up boxing_uppercut_right_window_04 at 0.930 (margin 0.046)
- strongest wrong emit was hook_right via boxing_hook_right_window_01 at 0.941 over runner-up boxing_straight_left_window_04 at 0.931 (margin 0.010)
- latest matcher reason emit_cooldown_active

Emitted attack events:
- `uppercut_left` at `1123ms` score=`0.903` prototype=`boxing_uppercut_left_window_02` class=`uppercut_left` runner-up=`uppercut_right/boxing_uppercut_right_window_04 0.860` margin=`0.043` backend=`prototype_matcher`
- `uppercut_right` at `1339ms` score=`0.895` prototype=`boxing_uppercut_right_window_04` class=`uppercut_right` runner-up=`uppercut_left/boxing_uppercut_left_window_02 0.885` margin=`0.010` backend=`prototype_matcher`
- `uppercut_right` at `1661ms` score=`0.801` prototype=`boxing_uppercut_right_window_04` class=`uppercut_right` runner-up=`hook_right/boxing_hook_right_window_01 0.786` margin=`0.015` backend=`prototype_matcher`
- `uppercut_right` at `1962ms` score=`0.773` prototype=`boxing_uppercut_right_window_04` class=`uppercut_right` runner-up=`hook_right/boxing_hook_right_window_01 0.754` margin=`0.019` backend=`prototype_matcher`
- `punch_left` at `2273ms` score=`0.938` prototype=`boxing_straight_left_window_01` class=`straight_left` runner-up=`uppercut_right/boxing_uppercut_right_window_04 0.924` margin=`0.014` backend=`prototype_matcher`
- `uppercut_right` at `2577ms` score=`0.919` prototype=`boxing_uppercut_right_window_04` class=`uppercut_right` runner-up=`straight_left/boxing_straight_left_window_04 0.881` margin=`0.038` backend=`prototype_matcher`
- `uppercut_right` at `2894ms` score=`0.792` prototype=`boxing_uppercut_right_window_04` class=`uppercut_right` runner-up=`hook_right/boxing_hook_right_window_01 0.778` margin=`0.014` backend=`prototype_matcher`
- `hook_right` at `3205ms` score=`0.809` prototype=`boxing_hook_right_window_01` class=`hook_right` runner-up=`uppercut_right/boxing_uppercut_right_window_04 0.806` margin=`0.004` backend=`prototype_matcher`
- `hook_right` at `3512ms` score=`0.941` prototype=`boxing_hook_right_window_01` class=`hook_right` runner-up=`straight_left/boxing_straight_left_window_04 0.931` margin=`0.010` backend=`prototype_matcher`
- `uppercut_right` at `3827ms` score=`0.893` prototype=`boxing_uppercut_right_window_04` class=`uppercut_right` runner-up=`hook_right/boxing_hook_right_window_01 0.863` margin=`0.031` backend=`prototype_matcher`
- `uppercut_right` at `4139ms` score=`0.830` prototype=`boxing_uppercut_right_window_04` class=`uppercut_right` runner-up=`hook_right/boxing_hook_right_window_01 0.828` margin=`0.002` backend=`prototype_matcher`
- `punch_left` at `4444ms` score=`0.912` prototype=`boxing_straight_left_window_03` class=`straight_left` runner-up=`uppercut_right/boxing_uppercut_right_window_04 0.855` margin=`0.057` backend=`prototype_matcher`
- `punch_left` at `4755ms` score=`0.976` prototype=`boxing_straight_left_window_03` class=`straight_left` runner-up=`uppercut_right/boxing_uppercut_right_window_04 0.930` margin=`0.046` backend=`prototype_matcher`
- `hook_right` at `5063ms` score=`0.878` prototype=`boxing_hook_right_window_03` class=`hook_right` runner-up=`uppercut_right/boxing_uppercut_right_window_04 0.868` margin=`0.010` backend=`prototype_matcher`
- `uppercut_right` at `5375ms` score=`0.845` prototype=`boxing_uppercut_right_window_04` class=`uppercut_right` runner-up=`hook_right/boxing_hook_right_window_01 0.840` margin=`0.005` backend=`prototype_matcher`
- `uppercut_right` at `5676ms` score=`0.872` prototype=`boxing_uppercut_right_window_04` class=`uppercut_right` runner-up=`hook_right/boxing_hook_right_window_01 0.852` margin=`0.021` backend=`prototype_matcher`
- `punch_left` at `5975ms` score=`0.937` prototype=`boxing_straight_left_window_04` class=`straight_left` runner-up=`uppercut_right/boxing_uppercut_right_window_04 0.922` margin=`0.014` backend=`prototype_matcher`
- `hook_right` at `6269ms` score=`0.920` prototype=`boxing_hook_right_window_01` class=`hook_right` runner-up=`straight_left/boxing_straight_left_window_04 0.920` margin=`0.000` backend=`prototype_matcher`
- `uppercut_left` at `6492ms` score=`0.895` prototype=`boxing_uppercut_left_window_02` class=`uppercut_left` runner-up=`uppercut_right/boxing_uppercut_right_window_04 0.871` margin=`0.024` backend=`prototype_matcher`
- `uppercut_left` at `6796ms` score=`0.888` prototype=`boxing_uppercut_left_window_02` class=`uppercut_left` runner-up=`uppercut_right/boxing_uppercut_right_window_04 0.869` margin=`0.018` backend=`prototype_matcher`
- `uppercut_left` at `7102ms` score=`0.906` prototype=`boxing_uppercut_left_window_02` class=`uppercut_left` runner-up=`uppercut_right/boxing_uppercut_right_window_04 0.882` margin=`0.023` backend=`prototype_matcher`
- `uppercut_left` at `7408ms` score=`0.931` prototype=`boxing_uppercut_left_window_02` class=`uppercut_left` runner-up=`uppercut_right/boxing_uppercut_right_window_04 0.890` margin=`0.040` backend=`prototype_matcher`
- `uppercut_right` at `7707ms` score=`0.857` prototype=`boxing_uppercut_right_window_04` class=`uppercut_right` runner-up=`hook_right/boxing_hook_right_window_01 0.830` margin=`0.028` backend=`prototype_matcher`
- `uppercut_right` at `8039ms` score=`0.766` prototype=`boxing_uppercut_right_window_04` class=`uppercut_right` runner-up=`hook_right/boxing_hook_right_window_01 0.750` margin=`0.016` backend=`prototype_matcher`
- `punch_left` at `8387ms` score=`0.888` prototype=`boxing_straight_left_window_01` class=`straight_left` runner-up=`uppercut_right/boxing_uppercut_right_window_04 0.882` margin=`0.005` backend=`prototype_matcher`
- `punch_left` at `8729ms` score=`0.937` prototype=`boxing_straight_left_window_01` class=`straight_left` runner-up=`uppercut_right/boxing_uppercut_right_window_04 0.913` margin=`0.024` backend=`prototype_matcher`
- `uppercut_right` at `9059ms` score=`0.855` prototype=`boxing_uppercut_right_window_04` class=`uppercut_right` runner-up=`hook_right/boxing_hook_right_window_01 0.829` margin=`0.026` backend=`prototype_matcher`
- `uppercut_right` at `9399ms` score=`0.810` prototype=`boxing_uppercut_right_window_04` class=`uppercut_right` runner-up=`hook_right/boxing_hook_right_window_01 0.761` margin=`0.048` backend=`prototype_matcher`
- `punch_left` at `9743ms` score=`0.936` prototype=`boxing_straight_left_window_01` class=`straight_left` runner-up=`uppercut_right/boxing_uppercut_right_window_04 0.903` margin=`0.032` backend=`prototype_matcher`

### straight right

- Fixture: `.testbed/assets/fixtures/boxing/straight_right/boxing_guard->straight_right_repeat_04_take_01.yaml`
- Source: `.testbed/assets/fixtures/boxing/straight_right/boxing_guard->straight_right_repeat_04_take_01.mp4`
- Expected event: `punch_right`
- Expected class: `straight_right`
- Attack events emitted: **33**
- Peak snapshot: straight_right via boxing_straight_right_window_01 score=0.982 runner-up=uppercut_right/boxing_uppercut_right_window_01 0.881 margin=0.101
- Strongest expected emit: `punch_right` straight_right via boxing_straight_right_window_01 score=0.982 runner-up=uppercut_right/boxing_uppercut_right_window_01 0.881 margin=0.101
- Strongest wrong emit: `uppercut_left` uppercut_left via boxing_uppercut_left_window_02 score=0.829 runner-up=straight_right/boxing_straight_right_window_04 0.791 margin=0.039
- Emitted prototype counts: `boxing_straight_right_window_04` x20, `boxing_uppercut_left_window_03` x4, `boxing_straight_right_window_01` x3, `boxing_straight_right_window_02` x3, `boxing_uppercut_left_window_02` x2
- Best-snapshot prototype counts: `boxing_straight_right_window_04` x36, `boxing_uppercut_left_window_03` x16, `boxing_straight_right_window_02` x8, `boxing_straight_right_window_01` x6, `boxing_straight_right_window_03` x3
- emitted expected punch_right 27 time(s)
- also emitted other attack events: uppercut_left, uppercut_left, uppercut_left, uppercut_left, uppercut_left, uppercut_left
- peak expected-class score 0.982
- peak winner straight_right via boxing_straight_right_window_01 scored 0.982; runner-up uppercut_right via boxing_uppercut_right_window_01 scored 0.881 (margin 0.101)
- strongest expected emit used boxing_straight_right_window_01 at 0.982 over runner-up boxing_uppercut_right_window_01 at 0.881 (margin 0.101)
- strongest wrong emit was uppercut_left via boxing_uppercut_left_window_02 at 0.829 over runner-up boxing_straight_right_window_04 at 0.791 (margin 0.039)
- latest matcher reason step_wait

Emitted attack events:
- `punch_right` at `1108ms` score=`0.844` prototype=`boxing_straight_right_window_04` class=`straight_right` runner-up=`uppercut_left/boxing_uppercut_left_window_03 0.742` margin=`0.102` backend=`prototype_matcher`
- `punch_right` at `1223ms` score=`0.870` prototype=`boxing_straight_right_window_04` class=`straight_right` runner-up=`uppercut_right/boxing_uppercut_right_window_01 0.761` margin=`0.109` backend=`prototype_matcher`
- `punch_right` at `1463ms` score=`0.916` prototype=`boxing_straight_right_window_01` class=`straight_right` runner-up=`uppercut_right/boxing_uppercut_right_window_01 0.821` margin=`0.095` backend=`prototype_matcher`
- `punch_right` at `1711ms` score=`0.982` prototype=`boxing_straight_right_window_01` class=`straight_right` runner-up=`uppercut_right/boxing_uppercut_right_window_01 0.881` margin=`0.101` backend=`prototype_matcher`
- `uppercut_left` at `2211ms` score=`0.805` prototype=`boxing_uppercut_left_window_02` class=`uppercut_left` runner-up=`straight_left/boxing_straight_left_window_01 0.680` margin=`0.125` backend=`prototype_matcher`
- `punch_right` at `2462ms` score=`0.903` prototype=`boxing_straight_right_window_04` class=`straight_right` runner-up=`uppercut_right/boxing_uppercut_right_window_01 0.835` margin=`0.069` backend=`prototype_matcher`
- `punch_right` at `2712ms` score=`0.852` prototype=`boxing_straight_right_window_04` class=`straight_right` runner-up=`uppercut_left/boxing_uppercut_left_window_02 0.846` margin=`0.007` backend=`prototype_matcher`
- `punch_right` at `2964ms` score=`0.953` prototype=`boxing_straight_right_window_02` class=`straight_right` runner-up=`uppercut_left/boxing_uppercut_left_window_02 0.847` margin=`0.106` backend=`prototype_matcher`
- `uppercut_left` at `3225ms` score=`0.759` prototype=`boxing_uppercut_left_window_03` class=`uppercut_left` runner-up=`straight_right/boxing_straight_right_window_02 0.689` margin=`0.070` backend=`prototype_matcher`
- `punch_right` at `3589ms` score=`0.824` prototype=`boxing_straight_right_window_04` class=`straight_right` runner-up=`uppercut_left/boxing_uppercut_left_window_02 0.804` margin=`0.021` backend=`prototype_matcher`
- `punch_right` at `3840ms` score=`0.913` prototype=`boxing_straight_right_window_04` class=`straight_right` runner-up=`uppercut_right/boxing_uppercut_right_window_01 0.806` margin=`0.107` backend=`prototype_matcher`
- `punch_right` at `4089ms` score=`0.915` prototype=`boxing_straight_right_window_04` class=`straight_right` runner-up=`uppercut_right/boxing_uppercut_right_window_01 0.892` margin=`0.023` backend=`prototype_matcher`
- `punch_right` at `4342ms` score=`0.891` prototype=`boxing_straight_right_window_04` class=`straight_right` runner-up=`uppercut_right/boxing_uppercut_right_window_01 0.782` margin=`0.109` backend=`prototype_matcher`
- `uppercut_left` at `4601ms` score=`0.742` prototype=`boxing_uppercut_left_window_03` class=`uppercut_left` runner-up=`straight_left/boxing_straight_left_window_01 0.652` margin=`0.089` backend=`prototype_matcher`
- `uppercut_left` at `4851ms` score=`0.759` prototype=`boxing_uppercut_left_window_03` class=`uppercut_left` runner-up=`straight_left/boxing_straight_left_window_01 0.668` margin=`0.091` backend=`prototype_matcher`
- `punch_right` at `5091ms` score=`0.923` prototype=`boxing_straight_right_window_04` class=`straight_right` runner-up=`uppercut_left/boxing_uppercut_left_window_03 0.801` margin=`0.121` backend=`prototype_matcher`
- `punch_right` at `5340ms` score=`0.949` prototype=`boxing_straight_right_window_04` class=`straight_right` runner-up=`uppercut_left/boxing_uppercut_left_window_02 0.879` margin=`0.070` backend=`prototype_matcher`
- `punch_right` at `5592ms` score=`0.942` prototype=`boxing_straight_right_window_04` class=`straight_right` runner-up=`uppercut_left/boxing_uppercut_left_window_02 0.832` margin=`0.110` backend=`prototype_matcher`
- `punch_right` at `5843ms` score=`0.949` prototype=`boxing_straight_right_window_04` class=`straight_right` runner-up=`uppercut_right/boxing_uppercut_right_window_01 0.798` margin=`0.152` backend=`prototype_matcher`
- `punch_right` at `6066ms` score=`0.919` prototype=`boxing_straight_right_window_04` class=`straight_right` runner-up=`uppercut_right/boxing_uppercut_right_window_01 0.809` margin=`0.111` backend=`prototype_matcher`
- `punch_right` at `6310ms` score=`0.886` prototype=`boxing_straight_right_window_02` class=`straight_right` runner-up=`uppercut_left/boxing_uppercut_left_window_03 0.741` margin=`0.145` backend=`prototype_matcher`
- `punch_right` at `6816ms` score=`0.803` prototype=`boxing_straight_right_window_04` class=`straight_right` runner-up=`uppercut_left/boxing_uppercut_left_window_03 0.765` margin=`0.037` backend=`prototype_matcher`
- `punch_right` at `7063ms` score=`0.849` prototype=`boxing_straight_right_window_04` class=`straight_right` runner-up=`uppercut_right/boxing_uppercut_right_window_01 0.758` margin=`0.091` backend=`prototype_matcher`
- `punch_right` at `7313ms` score=`0.902` prototype=`boxing_straight_right_window_04` class=`straight_right` runner-up=`uppercut_right/boxing_uppercut_right_window_01 0.790` margin=`0.112` backend=`prototype_matcher`
- `punch_right` at `7563ms` score=`0.940` prototype=`boxing_straight_right_window_01` class=`straight_right` runner-up=`uppercut_right/boxing_uppercut_right_window_01 0.832` margin=`0.108` backend=`prototype_matcher`
- `punch_right` at `7812ms` score=`0.830` prototype=`boxing_straight_right_window_03` class=`straight_right` runner-up=`uppercut_left/boxing_uppercut_left_window_03 0.756` margin=`0.073` backend=`prototype_matcher`
- `uppercut_left` at `8193ms` score=`0.829` prototype=`boxing_uppercut_left_window_02` class=`uppercut_left` runner-up=`straight_right/boxing_straight_right_window_04 0.791` margin=`0.039` backend=`prototype_matcher`
- `punch_right` at `8436ms` score=`0.903` prototype=`boxing_straight_right_window_04` class=`straight_right` runner-up=`uppercut_right/boxing_uppercut_right_window_01 0.835` margin=`0.069` backend=`prototype_matcher`
- `punch_right` at `8689ms` score=`0.852` prototype=`boxing_straight_right_window_04` class=`straight_right` runner-up=`uppercut_left/boxing_uppercut_left_window_02 0.846` margin=`0.007` backend=`prototype_matcher`
- `punch_right` at `8941ms` score=`0.953` prototype=`boxing_straight_right_window_02` class=`straight_right` runner-up=`uppercut_left/boxing_uppercut_left_window_02 0.847` margin=`0.106` backend=`prototype_matcher`
- `uppercut_left` at `9200ms` score=`0.759` prototype=`boxing_uppercut_left_window_03` class=`uppercut_left` runner-up=`straight_right/boxing_straight_right_window_02 0.689` margin=`0.070` backend=`prototype_matcher`
- `punch_right` at `9564ms` score=`0.824` prototype=`boxing_straight_right_window_04` class=`straight_right` runner-up=`uppercut_left/boxing_uppercut_left_window_02 0.804` margin=`0.021` backend=`prototype_matcher`
- `punch_right` at `9818ms` score=`0.913` prototype=`boxing_straight_right_window_04` class=`straight_right` runner-up=`uppercut_right/boxing_uppercut_right_window_01 0.806` margin=`0.107` backend=`prototype_matcher`

### hook left

- Fixture: `.testbed/assets/fixtures/boxing/hook_left/boxing_guard->hook_left_repeat_04_take_01.yaml`
- Source: `.testbed/assets/fixtures/boxing/hook_left/boxing_guard->hook_left_repeat_04_take_01.mp4`
- Expected event: `hook_left`
- Expected class: `hook_left`
- Attack events emitted: **28**
- Peak snapshot: hook_left via boxing_hook_left_window_02 score=0.967 runner-up=hook_right/boxing_hook_right_window_03 0.806 margin=0.161
- Strongest expected emit: `hook_left` hook_left via boxing_hook_left_window_01 score=0.935 runner-up=straight_left/boxing_straight_left_window_03 0.827 margin=0.108
- Strongest wrong emit: `uppercut_right` uppercut_right via boxing_uppercut_right_window_01 score=0.920 runner-up=uppercut_left/boxing_uppercut_left_window_02 0.895 margin=0.026
- Emitted prototype counts: `boxing_hook_right_window_03` x8, `boxing_hook_left_window_01` x6, `boxing_uppercut_left_window_01` x5, `boxing_uppercut_right_window_01` x3, `boxing_hook_left_window_03` x2
- Best-snapshot prototype counts: `boxing_hook_right_window_03` x20, `boxing_hook_left_window_01` x18, `boxing_uppercut_left_window_01` x11, `boxing_uppercut_right_window_01` x9, `boxing_uppercut_right_window_03` x9
- emitted expected hook_left 10 time(s)
- also emitted other attack events: uppercut_right, uppercut_left, hook_right, hook_right, hook_right, hook_right, hook_right, hook_right, hook_right, hook_right, uppercut_left, uppercut_left, uppercut_right, uppercut_left, uppercut_right, uppercut_left, hook_right, hook_right
- peak expected-class score 0.967
- peak winner hook_left via boxing_hook_left_window_02 scored 0.967; runner-up hook_right via boxing_hook_right_window_03 scored 0.806 (margin 0.161)
- strongest expected emit used boxing_hook_left_window_01 at 0.935 over runner-up boxing_straight_left_window_03 at 0.827 (margin 0.108)
- strongest wrong emit was uppercut_right via boxing_uppercut_right_window_01 at 0.920 over runner-up boxing_uppercut_left_window_02 at 0.895 (margin 0.026)
- latest matcher reason emit_cooldown_active

Emitted attack events:
- `uppercut_right` at `1106ms` score=`0.913` prototype=`boxing_uppercut_right_window_01` class=`uppercut_right` runner-up=`uppercut_left/boxing_uppercut_left_window_02 0.901` margin=`0.012` backend=`prototype_matcher`
- `uppercut_left` at `1314ms` score=`0.898` prototype=`boxing_uppercut_left_window_01` class=`uppercut_left` runner-up=`uppercut_right/boxing_uppercut_right_window_04 0.889` margin=`0.009` backend=`prototype_matcher`
- `hook_right` at `1635ms` score=`0.794` prototype=`boxing_hook_right_window_01` class=`hook_right` runner-up=`uppercut_right/boxing_uppercut_right_window_03 0.786` margin=`0.008` backend=`prototype_matcher`
- `hook_right` at `2037ms` score=`0.707` prototype=`boxing_hook_right_window_03` class=`hook_right` runner-up=`uppercut_right/boxing_uppercut_right_window_03 0.680` margin=`0.026` backend=`prototype_matcher`
- `hook_left` at `2352ms` score=`0.901` prototype=`boxing_hook_left_window_01` class=`hook_left` runner-up=`hook_right/boxing_hook_right_window_03 0.853` margin=`0.048` backend=`prototype_matcher`
- `hook_left` at `2663ms` score=`0.935` prototype=`boxing_hook_left_window_01` class=`hook_left` runner-up=`straight_left/boxing_straight_left_window_03 0.827` margin=`0.108` backend=`prototype_matcher`
- `hook_left` at `2971ms` score=`0.878` prototype=`boxing_hook_left_window_01` class=`hook_left` runner-up=`straight_left/boxing_straight_left_window_03 0.845` margin=`0.033` backend=`prototype_matcher`
- `hook_right` at `3278ms` score=`0.740` prototype=`boxing_hook_right_window_03` class=`hook_right` runner-up=`uppercut_right/boxing_uppercut_right_window_03 0.695` margin=`0.045` backend=`prototype_matcher`
- `hook_left` at `3792ms` score=`0.812` prototype=`boxing_hook_left_window_03` class=`hook_left` runner-up=`hook_right/boxing_hook_right_window_03 0.764` margin=`0.048` backend=`prototype_matcher`
- `hook_left` at `4104ms` score=`0.902` prototype=`boxing_hook_left_window_02` class=`hook_left` runner-up=`straight_left/boxing_straight_left_window_02 0.788` margin=`0.114` backend=`prototype_matcher`
- `hook_left` at `4415ms` score=`0.875` prototype=`boxing_hook_left_window_01` class=`hook_left` runner-up=`straight_left/boxing_straight_left_window_03 0.819` margin=`0.056` backend=`prototype_matcher`
- `hook_right` at `4719ms` score=`0.798` prototype=`boxing_hook_right_window_03` class=`hook_right` runner-up=`uppercut_right/boxing_uppercut_right_window_03 0.748` margin=`0.050` backend=`prototype_matcher`
- `hook_right` at `5236ms` score=`0.777` prototype=`boxing_hook_right_window_03` class=`hook_right` runner-up=`hook_left/boxing_hook_left_window_04 0.732` margin=`0.046` backend=`prototype_matcher`
- `hook_left` at `5551ms` score=`0.916` prototype=`boxing_hook_left_window_03` class=`hook_left` runner-up=`hook_right/boxing_hook_right_window_03 0.767` margin=`0.149` backend=`prototype_matcher`
- `hook_left` at `5858ms` score=`0.900` prototype=`boxing_hook_left_window_01` class=`hook_left` runner-up=`straight_left/boxing_straight_left_window_03 0.778` margin=`0.121` backend=`prototype_matcher`
- `hook_right` at `6173ms` score=`0.730` prototype=`boxing_hook_right_window_03` class=`hook_right` runner-up=`uppercut_right/boxing_uppercut_right_window_03 0.674` margin=`0.057` backend=`prototype_matcher`
- `hook_right` at `6473ms` score=`0.721` prototype=`boxing_hook_right_window_03` class=`hook_right` runner-up=`uppercut_right/boxing_uppercut_right_window_03 0.672` margin=`0.049` backend=`prototype_matcher`
- `hook_left` at `6787ms` score=`0.853` prototype=`boxing_hook_left_window_04` class=`hook_left` runner-up=`hook_right/boxing_hook_right_window_03 0.784` margin=`0.068` backend=`prototype_matcher`
- `hook_right` at `7089ms` score=`0.869` prototype=`boxing_hook_right_window_03` class=`hook_right` runner-up=`straight_left/boxing_straight_left_window_03 0.868` margin=`0.001` backend=`prototype_matcher`
- `uppercut_left` at `7390ms` score=`0.847` prototype=`boxing_uppercut_left_window_01` class=`uppercut_left` runner-up=`straight_left/boxing_straight_left_window_03 0.831` margin=`0.017` backend=`prototype_matcher`
- `uppercut_left` at `7682ms` score=`0.860` prototype=`boxing_uppercut_left_window_01` class=`uppercut_left` runner-up=`straight_left/boxing_straight_left_window_04 0.833` margin=`0.027` backend=`prototype_matcher`
- `uppercut_right` at `7933ms` score=`0.898` prototype=`boxing_uppercut_right_window_01` class=`uppercut_right` runner-up=`uppercut_left/boxing_uppercut_left_window_01 0.897` margin=`0.001` backend=`prototype_matcher`
- `uppercut_left` at `8240ms` score=`0.904` prototype=`boxing_uppercut_left_window_01` class=`uppercut_left` runner-up=`uppercut_right/boxing_uppercut_right_window_01 0.895` margin=`0.009` backend=`prototype_matcher`
- `uppercut_right` at `8541ms` score=`0.920` prototype=`boxing_uppercut_right_window_01` class=`uppercut_right` runner-up=`uppercut_left/boxing_uppercut_left_window_02 0.895` margin=`0.026` backend=`prototype_matcher`
- `uppercut_left` at `8852ms` score=`0.898` prototype=`boxing_uppercut_left_window_01` class=`uppercut_left` runner-up=`hook_right/boxing_hook_right_window_01 0.890` margin=`0.008` backend=`prototype_matcher`
- `hook_right` at `9166ms` score=`0.794` prototype=`boxing_hook_right_window_01` class=`hook_right` runner-up=`uppercut_right/boxing_uppercut_right_window_03 0.786` margin=`0.008` backend=`prototype_matcher`
- `hook_right` at `9557ms` score=`0.718` prototype=`boxing_hook_right_window_03` class=`hook_right` runner-up=`hook_left/boxing_hook_left_window_04 0.715` margin=`0.002` backend=`prototype_matcher`
- `hook_left` at `9867ms` score=`0.901` prototype=`boxing_hook_left_window_01` class=`hook_left` runner-up=`hook_right/boxing_hook_right_window_03 0.853` margin=`0.048` backend=`prototype_matcher`

### hook right

- Fixture: `.testbed/assets/fixtures/boxing/hook_right/boxing_guard->hook_right_repeat_04_take_01.yaml`
- Source: `.testbed/assets/fixtures/boxing/hook_right/boxing_guard->hook_right_repeat_04_take_01.mp4`
- Expected event: `hook_right`
- Expected class: `hook_right`
- Attack events emitted: **27**
- Peak snapshot: hook_right via boxing_hook_right_window_01 score=0.985 runner-up=uppercut_right/boxing_uppercut_right_window_04 0.900 margin=0.085
- Strongest expected emit: `hook_right` hook_right via boxing_hook_right_window_01 score=0.972 runner-up=uppercut_right/boxing_uppercut_right_window_04 0.908 margin=0.064
- Strongest wrong emit: `uppercut_right` uppercut_right via boxing_uppercut_right_window_04 score=0.915 runner-up=hook_right/boxing_hook_right_window_01 0.913 margin=0.001
- Emitted prototype counts: `boxing_hook_right_window_01` x9, `boxing_hook_right_window_04` x5, `boxing_hook_left_window_01` x4, `boxing_hook_right_window_03` x2, `boxing_uppercut_left_window_01` x2
- Best-snapshot prototype counts: `boxing_hook_right_window_01` x27, `boxing_hook_left_window_01` x12, `boxing_hook_right_window_04` x12, `boxing_hook_right_window_03` x11, `boxing_straight_left_window_03` x7
- emitted expected hook_right 17 time(s)
- also emitted other attack events: punch_left, uppercut_left, punch_left, hook_left, hook_left, hook_left, hook_left, uppercut_right, uppercut_right, uppercut_left
- peak expected-class score 0.985
- peak winner hook_right via boxing_hook_right_window_01 scored 0.985; runner-up uppercut_right via boxing_uppercut_right_window_04 scored 0.900 (margin 0.085)
- strongest expected emit used boxing_hook_right_window_01 at 0.972 over runner-up boxing_uppercut_right_window_04 at 0.908 (margin 0.064)
- strongest wrong emit was uppercut_right via boxing_uppercut_right_window_04 at 0.915 over runner-up boxing_hook_right_window_01 at 0.913 (margin 0.001)
- latest matcher reason emitted

Emitted attack events:
- `hook_right` at `1088ms` score=`0.916` prototype=`boxing_hook_right_window_01` class=`hook_right` runner-up=`uppercut_right/boxing_uppercut_right_window_04 0.860` margin=`0.057` backend=`prototype_matcher`
- `punch_left` at `1371ms` score=`0.832` prototype=`boxing_straight_left_window_01` class=`straight_left` runner-up=`uppercut_left/boxing_uppercut_left_window_01 0.821` margin=`0.010` backend=`prototype_matcher`
- `hook_right` at `1887ms` score=`0.753` prototype=`boxing_hook_right_window_04` class=`hook_right` runner-up=`straight_left/boxing_straight_left_window_04 0.702` margin=`0.051` backend=`prototype_matcher`
- `hook_right` at `2187ms` score=`0.940` prototype=`boxing_hook_right_window_01` class=`hook_right` runner-up=`uppercut_right/boxing_uppercut_right_window_04 0.892` margin=`0.048` backend=`prototype_matcher`
- `hook_right` at `2496ms` score=`0.972` prototype=`boxing_hook_right_window_01` class=`hook_right` runner-up=`uppercut_right/boxing_uppercut_right_window_04 0.908` margin=`0.064` backend=`prototype_matcher`
- `uppercut_left` at `2815ms` score=`0.806` prototype=`boxing_uppercut_left_window_01` class=`uppercut_left` runner-up=`straight_left/boxing_straight_left_window_03 0.805` margin=`0.002` backend=`prototype_matcher`
- `punch_left` at `3107ms` score=`0.723` prototype=`boxing_straight_left_window_02` class=`straight_left` runner-up=`hook_left/boxing_hook_left_window_01 0.695` margin=`0.027` backend=`prototype_matcher`
- `hook_right` at `3405ms` score=`0.711` prototype=`boxing_hook_right_window_04` class=`hook_right` runner-up=`hook_left/boxing_hook_left_window_02 0.642` margin=`0.069` backend=`prototype_matcher`
- `hook_left` at `3710ms` score=`0.867` prototype=`boxing_hook_left_window_01` class=`hook_left` runner-up=`hook_right/boxing_hook_right_window_03 0.849` margin=`0.018` backend=`prototype_matcher`
- `hook_right` at `4019ms` score=`0.930` prototype=`boxing_hook_right_window_02` class=`hook_right` runner-up=`uppercut_right/boxing_uppercut_right_window_04 0.878` margin=`0.052` backend=`prototype_matcher`
- `hook_left` at `4336ms` score=`0.839` prototype=`boxing_hook_left_window_01` class=`hook_left` runner-up=`straight_left/boxing_straight_left_window_03 0.795` margin=`0.044` backend=`prototype_matcher`
- `hook_right` at `4961ms` score=`0.755` prototype=`boxing_hook_right_window_04` class=`hook_right` runner-up=`hook_left/boxing_hook_left_window_01 0.711` margin=`0.044` backend=`prototype_matcher`
- `hook_right` at `5271ms` score=`0.842` prototype=`boxing_hook_right_window_03` class=`hook_right` runner-up=`hook_left/boxing_hook_left_window_01 0.824` margin=`0.018` backend=`prototype_matcher`
- `hook_right` at `5580ms` score=`0.962` prototype=`boxing_hook_right_window_03` class=`hook_right` runner-up=`uppercut_right/boxing_uppercut_right_window_04 0.860` margin=`0.102` backend=`prototype_matcher`
- `hook_right` at `5886ms` score=`0.888` prototype=`boxing_hook_right_window_01` class=`hook_right` runner-up=`uppercut_right/boxing_uppercut_right_window_04 0.853` margin=`0.035` backend=`prototype_matcher`
- `hook_left` at `6186ms` score=`0.709` prototype=`boxing_hook_left_window_01` class=`hook_left` runner-up=`straight_left/boxing_straight_left_window_03 0.706` margin=`0.004` backend=`prototype_matcher`
- `hook_right` at `6600ms` score=`0.727` prototype=`boxing_hook_right_window_04` class=`hook_right` runner-up=`hook_left/boxing_hook_left_window_01 0.638` margin=`0.089` backend=`prototype_matcher`
- `hook_left` at `6912ms` score=`0.860` prototype=`boxing_hook_left_window_01` class=`hook_left` runner-up=`straight_left/boxing_straight_left_window_03 0.810` margin=`0.050` backend=`prototype_matcher`
- `hook_right` at `7214ms` score=`0.925` prototype=`boxing_hook_right_window_01` class=`hook_right` runner-up=`uppercut_right/boxing_uppercut_right_window_04 0.912` margin=`0.013` backend=`prototype_matcher`
- `uppercut_right` at `7514ms` score=`0.915` prototype=`boxing_uppercut_right_window_04` class=`uppercut_right` runner-up=`hook_right/boxing_hook_right_window_01 0.913` margin=`0.001` backend=`prototype_matcher`
- `hook_right` at `7806ms` score=`0.906` prototype=`boxing_hook_right_window_01` class=`hook_right` runner-up=`uppercut_right/boxing_uppercut_right_window_04 0.893` margin=`0.012` backend=`prototype_matcher`
- `uppercut_right` at `8094ms` score=`0.897` prototype=`boxing_uppercut_right_window_01` class=`uppercut_right` runner-up=`hook_right/boxing_hook_right_window_01 0.880` margin=`0.018` backend=`prototype_matcher`
- `hook_right` at `8395ms` score=`0.924` prototype=`boxing_hook_right_window_01` class=`hook_right` runner-up=`uppercut_right/boxing_uppercut_right_window_01 0.896` margin=`0.028` backend=`prototype_matcher`
- `hook_right` at `8696ms` score=`0.903` prototype=`boxing_hook_right_window_01` class=`hook_right` runner-up=`uppercut_right/boxing_uppercut_right_window_01 0.877` margin=`0.026` backend=`prototype_matcher`
- `uppercut_left` at `9011ms` score=`0.875` prototype=`boxing_uppercut_left_window_01` class=`uppercut_left` runner-up=`straight_left/boxing_straight_left_window_01 0.838` margin=`0.037` backend=`prototype_matcher`
- `hook_right` at `9629ms` score=`0.753` prototype=`boxing_hook_right_window_04` class=`hook_right` runner-up=`straight_left/boxing_straight_left_window_04 0.702` margin=`0.051` backend=`prototype_matcher`
- `hook_right` at `9919ms` score=`0.919` prototype=`boxing_hook_right_window_01` class=`hook_right` runner-up=`uppercut_right/boxing_uppercut_right_window_04 0.888` margin=`0.031` backend=`prototype_matcher`

### uppercut left

- Fixture: `.testbed/assets/fixtures/boxing/uppercut_left/boxing_guard->uppercut_left_repeat_04_take_01.yaml`
- Source: `.testbed/assets/fixtures/boxing/uppercut_left/boxing_guard->uppercut_left_repeat_04_take_01.mp4`
- Expected event: `uppercut_left`
- Expected class: `uppercut_left`
- Attack events emitted: **29**
- Peak snapshot: uppercut_left via boxing_uppercut_left_window_02 score=1.000 runner-up=uppercut_right/boxing_uppercut_right_window_01 0.897 margin=0.103
- Strongest expected emit: `uppercut_left` uppercut_left via boxing_uppercut_left_window_01 score=0.992 runner-up=uppercut_right/boxing_uppercut_right_window_04 0.918 margin=0.074
- Strongest wrong emit: `uppercut_right` uppercut_right via boxing_uppercut_right_window_04 score=0.927 runner-up=uppercut_left/boxing_uppercut_left_window_02 0.917 margin=0.010
- Emitted prototype counts: `boxing_uppercut_left_window_03` x6, `boxing_uppercut_left_window_02` x5, `boxing_hook_right_window_03` x4, `boxing_uppercut_left_window_01` x4, `boxing_hook_right_window_02` x3
- Best-snapshot prototype counts: `boxing_hook_right_window_03` x17, `boxing_uppercut_left_window_02` x17, `boxing_uppercut_left_window_03` x16, `boxing_uppercut_left_window_01` x10, `boxing_uppercut_right_window_04` x7
- emitted expected uppercut_left 15 time(s)
- also emitted other attack events: uppercut_right, hook_right, punch_left, hook_right, hook_right, uppercut_right, uppercut_right, hook_right, punch_left, hook_right, uppercut_right, uppercut_right, hook_right, hook_right
- peak expected-class score 1.000
- peak winner uppercut_left via boxing_uppercut_left_window_02 scored 1.000; runner-up uppercut_right via boxing_uppercut_right_window_01 scored 0.897 (margin 0.103)
- strongest expected emit used boxing_uppercut_left_window_01 at 0.992 over runner-up boxing_uppercut_right_window_04 at 0.918 (margin 0.074)
- strongest wrong emit was uppercut_right via boxing_uppercut_right_window_04 at 0.927 over runner-up boxing_uppercut_left_window_02 at 0.917 (margin 0.010)
- latest matcher reason emit_cooldown_active

Emitted attack events:
- `uppercut_right` at `1089ms` score=`0.756` prototype=`boxing_uppercut_right_window_03` class=`uppercut_right` runner-up=`hook_right/boxing_hook_right_window_03 0.748` margin=`0.008` backend=`prototype_matcher`
- `hook_right` at `1364ms` score=`0.750` prototype=`boxing_hook_right_window_02` class=`hook_right` runner-up=`uppercut_right/boxing_uppercut_right_window_03 0.663` margin=`0.086` backend=`prototype_matcher`
- `uppercut_left` at `1660ms` score=`0.851` prototype=`boxing_uppercut_left_window_02` class=`uppercut_left` runner-up=`hook_right/boxing_hook_right_window_01 0.775` margin=`0.076` backend=`prototype_matcher`
- `uppercut_left` at `1971ms` score=`0.917` prototype=`boxing_uppercut_left_window_01` class=`uppercut_left` runner-up=`uppercut_right/boxing_uppercut_right_window_04 0.871` margin=`0.046` backend=`prototype_matcher`
- `uppercut_left` at `2285ms` score=`0.992` prototype=`boxing_uppercut_left_window_01` class=`uppercut_left` runner-up=`uppercut_right/boxing_uppercut_right_window_04 0.918` margin=`0.074` backend=`prototype_matcher`
- `uppercut_left` at `2579ms` score=`0.924` prototype=`boxing_uppercut_left_window_01` class=`uppercut_left` runner-up=`uppercut_right/boxing_uppercut_right_window_04 0.911` margin=`0.013` backend=`prototype_matcher`
- `punch_left` at `2890ms` score=`0.870` prototype=`boxing_straight_left_window_01` class=`straight_left` runner-up=`uppercut_right/boxing_uppercut_right_window_03 0.849` margin=`0.020` backend=`prototype_matcher`
- `hook_right` at `3198ms` score=`0.720` prototype=`boxing_hook_right_window_03` class=`hook_right` runner-up=`uppercut_right/boxing_uppercut_right_window_03 0.667` margin=`0.053` backend=`prototype_matcher`
- `hook_right` at `3516ms` score=`0.795` prototype=`boxing_hook_right_window_03` class=`hook_right` runner-up=`uppercut_right/boxing_uppercut_right_window_04 0.778` margin=`0.017` backend=`prototype_matcher`
- `uppercut_left` at `3829ms` score=`0.882` prototype=`boxing_uppercut_left_window_03` class=`uppercut_left` runner-up=`uppercut_right/boxing_uppercut_right_window_04 0.808` margin=`0.074` backend=`prototype_matcher`
- `uppercut_left` at `4132ms` score=`0.981` prototype=`boxing_uppercut_left_window_02` class=`uppercut_left` runner-up=`uppercut_right/boxing_uppercut_right_window_01 0.902` margin=`0.080` backend=`prototype_matcher`
- `uppercut_left` at `4449ms` score=`0.951` prototype=`boxing_uppercut_left_window_02` class=`uppercut_left` runner-up=`uppercut_right/boxing_uppercut_right_window_01 0.900` margin=`0.051` backend=`prototype_matcher`
- `uppercut_right` at `4754ms` score=`0.903` prototype=`boxing_uppercut_right_window_01` class=`uppercut_right` runner-up=`uppercut_left/boxing_uppercut_left_window_02 0.902` margin=`0.000` backend=`prototype_matcher`
- `uppercut_right` at `5072ms` score=`0.707` prototype=`boxing_uppercut_right_window_03` class=`uppercut_right` runner-up=`hook_right/boxing_hook_right_window_03 0.690` margin=`0.017` backend=`prototype_matcher`
- `hook_right` at `5393ms` score=`0.725` prototype=`boxing_hook_right_window_03` class=`hook_right` runner-up=`uppercut_right/boxing_uppercut_right_window_03 0.627` margin=`0.098` backend=`prototype_matcher`
- `uppercut_left` at `5688ms` score=`0.894` prototype=`boxing_uppercut_left_window_03` class=`uppercut_left` runner-up=`uppercut_right/boxing_uppercut_right_window_01 0.844` margin=`0.050` backend=`prototype_matcher`
- `uppercut_left` at `6002ms` score=`0.965` prototype=`boxing_uppercut_left_window_03` class=`uppercut_left` runner-up=`uppercut_right/boxing_uppercut_right_window_04 0.869` margin=`0.097` backend=`prototype_matcher`
- `uppercut_left` at `6313ms` score=`0.956` prototype=`boxing_uppercut_left_window_03` class=`uppercut_left` runner-up=`uppercut_right/boxing_uppercut_right_window_01 0.896` margin=`0.060` backend=`prototype_matcher`
- `uppercut_left` at `6624ms` score=`0.946` prototype=`boxing_uppercut_left_window_02` class=`uppercut_left` runner-up=`uppercut_right/boxing_uppercut_right_window_01 0.903` margin=`0.043` backend=`prototype_matcher`
- `punch_left` at `6955ms` score=`0.813` prototype=`boxing_straight_left_window_03` class=`straight_left` runner-up=`uppercut_right/boxing_uppercut_right_window_03 0.789` margin=`0.024` backend=`prototype_matcher`
- `hook_right` at `7349ms` score=`0.727` prototype=`boxing_hook_right_window_03` class=`hook_right` runner-up=`uppercut_right/boxing_uppercut_right_window_03 0.689` margin=`0.038` backend=`prototype_matcher`
- `uppercut_left` at `7645ms` score=`0.825` prototype=`boxing_uppercut_left_window_03` class=`uppercut_left` runner-up=`uppercut_right/boxing_uppercut_right_window_04 0.803` margin=`0.021` backend=`prototype_matcher`
- `uppercut_left` at `7944ms` score=`0.903` prototype=`boxing_uppercut_left_window_03` class=`uppercut_left` runner-up=`uppercut_right/boxing_uppercut_right_window_01 0.881` margin=`0.022` backend=`prototype_matcher`
- `uppercut_left` at `8330ms` score=`0.925` prototype=`boxing_uppercut_left_window_02` class=`uppercut_left` runner-up=`uppercut_right/boxing_uppercut_right_window_04 0.922` margin=`0.003` backend=`prototype_matcher`
- `uppercut_right` at `8633ms` score=`0.927` prototype=`boxing_uppercut_right_window_04` class=`uppercut_right` runner-up=`uppercut_left/boxing_uppercut_left_window_02 0.917` margin=`0.010` backend=`prototype_matcher`
- `uppercut_right` at `8948ms` score=`0.853` prototype=`boxing_uppercut_right_window_04` class=`uppercut_right` runner-up=`hook_right/boxing_hook_right_window_01 0.828` margin=`0.025` backend=`prototype_matcher`
- `hook_right` at `9237ms` score=`0.744` prototype=`boxing_hook_right_window_02` class=`hook_right` runner-up=`uppercut_right/boxing_uppercut_right_window_03 0.665` margin=`0.080` backend=`prototype_matcher`
- `hook_right` at `9545ms` score=`0.783` prototype=`boxing_hook_right_window_02` class=`hook_right` runner-up=`uppercut_right/boxing_uppercut_right_window_04 0.758` margin=`0.025` backend=`prototype_matcher`
- `uppercut_left` at `9865ms` score=`0.884` prototype=`boxing_uppercut_left_window_01` class=`uppercut_left` runner-up=`uppercut_right/boxing_uppercut_right_window_04 0.855` margin=`0.029` backend=`prototype_matcher`

### uppercut right

- Fixture: `.testbed/assets/fixtures/boxing/uppercut_right/boxing_guard->uppercut_right_repeat_04_take_01.yaml`
- Source: `.testbed/assets/fixtures/boxing/uppercut_right/boxing_guard->uppercut_right_repeat_04_take_01.mp4`
- Expected event: `uppercut_right`
- Expected class: `uppercut_right`
- Attack events emitted: **28**
- Peak snapshot: uppercut_right via boxing_uppercut_right_window_01 score=1.000 runner-up=straight_right/boxing_straight_right_window_01 0.860 margin=0.140
- Strongest expected emit: `uppercut_right` uppercut_right via boxing_uppercut_right_window_01 score=1.000 runner-up=straight_right/boxing_straight_right_window_01 0.860 margin=0.140
- Strongest wrong emit: `hook_right` hook_right via boxing_hook_right_window_01 score=0.919 runner-up=uppercut_right/boxing_uppercut_right_window_04 0.901 margin=0.018
- Emitted prototype counts: `boxing_uppercut_right_window_01` x9, `boxing_hook_left_window_01` x5, `boxing_uppercut_right_window_04` x3, `boxing_hook_left_window_02` x2, `boxing_hook_left_window_03` x2
- Best-snapshot prototype counts: `boxing_uppercut_right_window_01` x25, `boxing_hook_left_window_01` x17, `boxing_uppercut_right_window_04` x12, `boxing_hook_left_window_02` x7, `boxing_hook_left_window_03` x7
- emitted expected uppercut_right 15 time(s)
- also emitted other attack events: uppercut_left, hook_left, punch_left, hook_left, punch_left, hook_left, hook_left, hook_right, hook_left, hook_left, hook_left, hook_left, hook_left
- peak expected-class score 1.000
- peak winner uppercut_right via boxing_uppercut_right_window_01 scored 1.000; runner-up straight_right via boxing_straight_right_window_01 scored 0.860 (margin 0.140)
- strongest expected emit used boxing_uppercut_right_window_01 at 1.000 over runner-up boxing_straight_right_window_01 at 0.860 (margin 0.140)
- strongest wrong emit was hook_right via boxing_hook_right_window_01 at 0.919 over runner-up boxing_uppercut_right_window_04 at 0.901 (margin 0.018)
- latest matcher reason emitted

Emitted attack events:
- `uppercut_left` at `1146ms` score=`0.730` prototype=`boxing_uppercut_left_window_01` class=`uppercut_left` runner-up=`straight_left/boxing_straight_left_window_03 0.702` margin=`0.028` backend=`prototype_matcher`
- `hook_left` at `1365ms` score=`0.785` prototype=`boxing_hook_left_window_01` class=`hook_left` runner-up=`straight_left/boxing_straight_left_window_03 0.648` margin=`0.137` backend=`prototype_matcher`
- `punch_left` at `1651ms` score=`0.772` prototype=`boxing_straight_left_window_01` class=`straight_left` runner-up=`hook_right/boxing_hook_right_window_01 0.720` margin=`0.052` backend=`prototype_matcher`
- `uppercut_right` at `1957ms` score=`0.887` prototype=`boxing_uppercut_right_window_01` class=`uppercut_right` runner-up=`straight_right/boxing_straight_right_window_01 0.865` margin=`0.022` backend=`prototype_matcher`
- `uppercut_right` at `2267ms` score=`1.000` prototype=`boxing_uppercut_right_window_01` class=`uppercut_right` runner-up=`straight_right/boxing_straight_right_window_01 0.860` margin=`0.140` backend=`prototype_matcher`
- `uppercut_right` at `2574ms` score=`0.927` prototype=`boxing_uppercut_right_window_01` class=`uppercut_right` runner-up=`hook_right/boxing_hook_right_window_01 0.873` margin=`0.054` backend=`prototype_matcher`
- `hook_left` at `3185ms` score=`0.790` prototype=`boxing_hook_left_window_03` class=`hook_left` runner-up=`straight_left/boxing_straight_left_window_03 0.708` margin=`0.082` backend=`prototype_matcher`
- `uppercut_right` at `3488ms` score=`0.888` prototype=`boxing_uppercut_right_window_02` class=`uppercut_right` runner-up=`straight_left/boxing_straight_left_window_01 0.814` margin=`0.074` backend=`prototype_matcher`
- `uppercut_right` at `3794ms` score=`0.920` prototype=`boxing_uppercut_right_window_01` class=`uppercut_right` runner-up=`straight_right/boxing_straight_right_window_01 0.881` margin=`0.039` backend=`prototype_matcher`
- `uppercut_right` at `4092ms` score=`0.932` prototype=`boxing_uppercut_right_window_01` class=`uppercut_right` runner-up=`straight_right/boxing_straight_right_window_01 0.863` margin=`0.068` backend=`prototype_matcher`
- `punch_left` at `4417ms` score=`0.804` prototype=`boxing_straight_left_window_03` class=`straight_left` runner-up=`hook_left/boxing_hook_left_window_01 0.801` margin=`0.002` backend=`prototype_matcher`
- `hook_left` at `4728ms` score=`0.843` prototype=`boxing_hook_left_window_01` class=`hook_left` runner-up=`straight_left/boxing_straight_left_window_03 0.744` margin=`0.099` backend=`prototype_matcher`
- `hook_left` at `5030ms` score=`0.858` prototype=`boxing_hook_left_window_01` class=`hook_left` runner-up=`straight_left/boxing_straight_left_window_03 0.824` margin=`0.033` backend=`prototype_matcher`
- `hook_right` at `5343ms` score=`0.919` prototype=`boxing_hook_right_window_01` class=`hook_right` runner-up=`uppercut_right/boxing_uppercut_right_window_04 0.901` margin=`0.018` backend=`prototype_matcher`
- `uppercut_right` at `5660ms` score=`0.924` prototype=`boxing_uppercut_right_window_03` class=`uppercut_right` runner-up=`hook_right/boxing_hook_right_window_01 0.859` margin=`0.064` backend=`prototype_matcher`
- `hook_left` at `6187ms` score=`0.750` prototype=`boxing_hook_left_window_03` class=`hook_left` runner-up=`straight_left/boxing_straight_left_window_03 0.620` margin=`0.129` backend=`prototype_matcher`
- `hook_left` at `6466ms` score=`0.791` prototype=`boxing_hook_left_window_02` class=`hook_left` runner-up=`straight_left/boxing_straight_left_window_04 0.779` margin=`0.012` backend=`prototype_matcher`
- `uppercut_right` at `6762ms` score=`0.924` prototype=`boxing_uppercut_right_window_01` class=`uppercut_right` runner-up=`straight_left/boxing_straight_left_window_01 0.857` margin=`0.067` backend=`prototype_matcher`
- `uppercut_right` at `7120ms` score=`0.932` prototype=`boxing_uppercut_right_window_04` class=`uppercut_right` runner-up=`hook_right/boxing_hook_right_window_01 0.899` margin=`0.033` backend=`prototype_matcher`
- `uppercut_right` at `7420ms` score=`0.916` prototype=`boxing_uppercut_right_window_04` class=`uppercut_right` runner-up=`hook_right/boxing_hook_right_window_01 0.914` margin=`0.002` backend=`prototype_matcher`
- `uppercut_right` at `7736ms` score=`0.904` prototype=`boxing_uppercut_right_window_03` class=`uppercut_right` runner-up=`hook_right/boxing_hook_right_window_01 0.887` margin=`0.018` backend=`prototype_matcher`
- `hook_left` at `8041ms` score=`0.701` prototype=`boxing_hook_left_window_01` class=`hook_left` runner-up=`straight_left/boxing_straight_left_window_03 0.630` margin=`0.071` backend=`prototype_matcher`
- `hook_left` at `8341ms` score=`0.771` prototype=`boxing_hook_left_window_02` class=`hook_left` runner-up=`hook_right/boxing_hook_right_window_02 0.758` margin=`0.014` backend=`prototype_matcher`
- `uppercut_right` at `8627ms` score=`0.855` prototype=`boxing_uppercut_right_window_01` class=`uppercut_right` runner-up=`straight_right/boxing_straight_right_window_01 0.818` margin=`0.037` backend=`prototype_matcher`
- `uppercut_right` at `8930ms` score=`0.926` prototype=`boxing_uppercut_right_window_01` class=`uppercut_right` runner-up=`hook_right/boxing_hook_right_window_01 0.846` margin=`0.080` backend=`prototype_matcher`
- `uppercut_right` at `9242ms` score=`0.937` prototype=`boxing_uppercut_right_window_01` class=`uppercut_right` runner-up=`hook_right/boxing_hook_right_window_01 0.861` margin=`0.076` backend=`prototype_matcher`
- `uppercut_right` at `9565ms` score=`0.927` prototype=`boxing_uppercut_right_window_04` class=`uppercut_right` runner-up=`hook_right/boxing_hook_right_window_01 0.872` margin=`0.055` backend=`prototype_matcher`
- `hook_left` at `9964ms` score=`0.713` prototype=`boxing_hook_left_window_01` class=`hook_left` runner-up=`straight_left/boxing_straight_left_window_03 0.611` margin=`0.103` backend=`prototype_matcher`

### negative control - running in place

- Fixture: `.testbed/assets/fixtures/boxing/run_in_place/boxing_guard->run_in_place_repeat_01_take_01.yaml`
- Source: `.testbed/assets/fixtures/boxing/run_in_place/boxing_guard->run_in_place_repeat_01_take_01.mp4`
- Expected event: `None`
- Expected class: `None`
- Attack events emitted: **30**
- Peak snapshot: hook_right via boxing_hook_right_window_03 score=0.903 runner-up=uppercut_right/boxing_uppercut_right_window_04 0.847 margin=0.056
- Strongest wrong emit: `hook_right` hook_right via boxing_hook_right_window_03 score=0.903 runner-up=uppercut_right/boxing_uppercut_right_window_04 0.847 margin=0.056
- Emitted prototype counts: `boxing_hook_left_window_01` x24, `boxing_hook_right_window_03` x2, `boxing_straight_left_window_03` x2, `boxing_straight_left_window_01` x1, `boxing_straight_left_window_02` x1
- Best-snapshot prototype counts: `boxing_hook_left_window_01` x71, `boxing_hook_right_window_03` x5, `boxing_straight_left_window_03` x4, `boxing_straight_left_window_01` x3, `boxing_straight_left_window_02` x3
- negative control still emitted attack events: punch_left, punch_left, hook_left, hook_left, hook_left, hook_left, hook_left, hook_left, hook_left, hook_left, hook_left, hook_left, hook_left, hook_left, hook_right, hook_right, punch_left, punch_left, hook_left, hook_left, hook_left, hook_left, hook_left, hook_left, hook_left, hook_left, hook_left, hook_left, hook_left, hook_left
- peak winner hook_right via boxing_hook_right_window_03 scored 0.903; runner-up uppercut_right via boxing_uppercut_right_window_04 scored 0.847 (margin 0.056)
- strongest wrong emit was hook_right via boxing_hook_right_window_03 at 0.903 over runner-up boxing_uppercut_right_window_04 at 0.847 (margin 0.056)
- latest matcher reason step_wait

Emitted attack events:
- `punch_left` at `1131ms` score=`0.846` prototype=`boxing_straight_left_window_03` class=`straight_left` runner-up=`hook_right/boxing_hook_right_window_03 0.790` margin=`0.056` backend=`prototype_matcher`
- `punch_left` at `1404ms` score=`0.765` prototype=`boxing_straight_left_window_02` class=`straight_left` runner-up=`hook_left/boxing_hook_left_window_01 0.750` margin=`0.016` backend=`prototype_matcher`
- `hook_left` at `1715ms` score=`0.782` prototype=`boxing_hook_left_window_01` class=`hook_left` runner-up=`straight_left/boxing_straight_left_window_03 0.723` margin=`0.059` backend=`prototype_matcher`
- `hook_left` at `2026ms` score=`0.834` prototype=`boxing_hook_left_window_01` class=`hook_left` runner-up=`straight_left/boxing_straight_left_window_03 0.768` margin=`0.066` backend=`prototype_matcher`
- `hook_left` at `2339ms` score=`0.864` prototype=`boxing_hook_left_window_01` class=`hook_left` runner-up=`straight_left/boxing_straight_left_window_03 0.798` margin=`0.066` backend=`prototype_matcher`
- `hook_left` at `2648ms` score=`0.866` prototype=`boxing_hook_left_window_01` class=`hook_left` runner-up=`straight_left/boxing_straight_left_window_03 0.801` margin=`0.065` backend=`prototype_matcher`
- `hook_left` at `2955ms` score=`0.841` prototype=`boxing_hook_left_window_01` class=`hook_left` runner-up=`straight_left/boxing_straight_left_window_03 0.803` margin=`0.038` backend=`prototype_matcher`
- `hook_left` at `3265ms` score=`0.858` prototype=`boxing_hook_left_window_01` class=`hook_left` runner-up=`straight_left/boxing_straight_left_window_03 0.792` margin=`0.066` backend=`prototype_matcher`
- `hook_left` at `3571ms` score=`0.867` prototype=`boxing_hook_left_window_01` class=`hook_left` runner-up=`straight_left/boxing_straight_left_window_03 0.825` margin=`0.042` backend=`prototype_matcher`
- `hook_left` at `3882ms` score=`0.853` prototype=`boxing_hook_left_window_01` class=`hook_left` runner-up=`straight_left/boxing_straight_left_window_03 0.806` margin=`0.047` backend=`prototype_matcher`
- `hook_left` at `4185ms` score=`0.828` prototype=`boxing_hook_left_window_01` class=`hook_left` runner-up=`straight_left/boxing_straight_left_window_03 0.794` margin=`0.033` backend=`prototype_matcher`
- `hook_left` at `4495ms` score=`0.838` prototype=`boxing_hook_left_window_01` class=`hook_left` runner-up=`straight_left/boxing_straight_left_window_03 0.775` margin=`0.063` backend=`prototype_matcher`
- `hook_left` at `4791ms` score=`0.857` prototype=`boxing_hook_left_window_01` class=`hook_left` runner-up=`straight_left/boxing_straight_left_window_03 0.790` margin=`0.067` backend=`prototype_matcher`
- `hook_left` at `5087ms` score=`0.833` prototype=`boxing_hook_left_window_01` class=`hook_left` runner-up=`straight_left/boxing_straight_left_window_03 0.823` margin=`0.010` backend=`prototype_matcher`
- `hook_right` at `5311ms` score=`0.903` prototype=`boxing_hook_right_window_03` class=`hook_right` runner-up=`uppercut_right/boxing_uppercut_right_window_04 0.847` margin=`0.056` backend=`prototype_matcher`
- `hook_right` at `5617ms` score=`0.865` prototype=`boxing_hook_right_window_03` class=`hook_right` runner-up=`straight_left/boxing_straight_left_window_04 0.846` margin=`0.020` backend=`prototype_matcher`
- `punch_left` at `5925ms` score=`0.885` prototype=`boxing_straight_left_window_01` class=`straight_left` runner-up=`hook_right/boxing_hook_right_window_03 0.849` margin=`0.037` backend=`prototype_matcher`
- `punch_left` at `6238ms` score=`0.839` prototype=`boxing_straight_left_window_03` class=`straight_left` runner-up=`hook_left/boxing_hook_left_window_01 0.812` margin=`0.027` backend=`prototype_matcher`
- `hook_left` at `6540ms` score=`0.712` prototype=`boxing_hook_left_window_01` class=`hook_left` runner-up=`hook_right/boxing_hook_right_window_03 0.696` margin=`0.015` backend=`prototype_matcher`
- `hook_left` at `6850ms` score=`0.780` prototype=`boxing_hook_left_window_01` class=`hook_left` runner-up=`straight_left/boxing_straight_left_window_03 0.721` margin=`0.059` backend=`prototype_matcher`
- `hook_left` at `7160ms` score=`0.837` prototype=`boxing_hook_left_window_01` class=`hook_left` runner-up=`straight_left/boxing_straight_left_window_03 0.769` margin=`0.068` backend=`prototype_matcher`
- `hook_left` at `7470ms` score=`0.862` prototype=`boxing_hook_left_window_01` class=`hook_left` runner-up=`straight_left/boxing_straight_left_window_03 0.799` margin=`0.063` backend=`prototype_matcher`
- `hook_left` at `7777ms` score=`0.864` prototype=`boxing_hook_left_window_01` class=`hook_left` runner-up=`straight_left/boxing_straight_left_window_03 0.793` margin=`0.071` backend=`prototype_matcher`
- `hook_left` at `8074ms` score=`0.832` prototype=`boxing_hook_left_window_01` class=`hook_left` runner-up=`straight_left/boxing_straight_left_window_03 0.799` margin=`0.033` backend=`prototype_matcher`
- `hook_left` at `8388ms` score=`0.861` prototype=`boxing_hook_left_window_01` class=`hook_left` runner-up=`straight_left/boxing_straight_left_window_03 0.789` margin=`0.072` backend=`prototype_matcher`
- `hook_left` at `8692ms` score=`0.868` prototype=`boxing_hook_left_window_01` class=`hook_left` runner-up=`straight_left/boxing_straight_left_window_03 0.817` margin=`0.051` backend=`prototype_matcher`
- `hook_left` at `9001ms` score=`0.849` prototype=`boxing_hook_left_window_01` class=`hook_left` runner-up=`straight_left/boxing_straight_left_window_03 0.796` margin=`0.053` backend=`prototype_matcher`
- `hook_left` at `9309ms` score=`0.797` prototype=`boxing_hook_left_window_01` class=`hook_left` runner-up=`straight_left/boxing_straight_left_window_02 0.791` margin=`0.005` backend=`prototype_matcher`
- `hook_left` at `9619ms` score=`0.815` prototype=`boxing_hook_left_window_01` class=`hook_left` runner-up=`straight_left/boxing_straight_left_window_03 0.771` margin=`0.044` backend=`prototype_matcher`
- `hook_left` at `9916ms` score=`0.862` prototype=`boxing_hook_left_window_01` class=`hook_left` runner-up=`straight_left/boxing_straight_left_window_03 0.809` margin=`0.053` backend=`prototype_matcher`
