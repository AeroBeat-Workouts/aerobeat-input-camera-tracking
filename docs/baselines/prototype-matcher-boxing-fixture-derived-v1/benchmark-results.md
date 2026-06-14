# Prototype Matcher Fixture Benchmark

- Benchmark ID: `prototype_matcher_boxing_fixture_derived_v1`
- Library ID: `boxing_side_aware_fixture_derived_v1`
- Profile: `boxing`
- Generated At: `2026-06-13T21:43:01-04:00`
- Runner: `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/scripts/run_prototype_matcher_fixture_benchmark.py`

## Aggregate

- Fixture count: **7**
- Negative controls clean: **0 / 1**
- Negative-control false-positive classes: `hook_left` x25, `straight_left` x3, `hook_right` x2
- Negative-control false-positive prototypes: `hook_left_hook_left_fixture_window_01` x21, `hook_left_hook_left_fixture_window_03` x4, `hook_right_hook_right_fixture_window_03` x2, `straight_left_straight_left_fixture_window_01` x2, `straight_left_straight_left_fixture_window_02` x1

## Per Fixture

### straight left

- Fixture: `.testbed/assets/fixtures/boxing/punch_left/boxing_guard->punch_left_repeat_04_take_01.yaml`
- Source: `.testbed/assets/fixtures/boxing/punch_left/boxing_guard->punch_left_repeat_04_take_01.mp4`
- Expected event: `punch_left`
- Expected class: `straight_left`
- Attack events emitted: **30**
- Peak snapshot: straight_left via straight_left_straight_left_fixture_window_01 score=0.986 runner-up=uppercut_right/uppercut_right_uppercut_right_fixture_window_04 0.907 margin=0.079
- Strongest expected emit: `punch_left` straight_left via straight_left_straight_left_fixture_window_03 score=0.976 runner-up=uppercut_right/uppercut_right_uppercut_right_fixture_window_04 0.903 margin=0.073
- Strongest wrong emit: `hook_right` hook_right via hook_right_hook_right_fixture_window_01 score=0.941 runner-up=straight_left/straight_left_straight_left_fixture_window_04 0.926 margin=0.014
- Emitted prototype counts: `uppercut_right_uppercut_right_fixture_window_04` x8, `hook_right_hook_right_fixture_window_01` x6, `uppercut_left_uppercut_left_fixture_window_02` x6, `straight_left_straight_left_fixture_window_01` x5, `straight_left_straight_left_fixture_window_03` x2
- Best-snapshot prototype counts: `uppercut_right_uppercut_right_fixture_window_04` x25, `hook_right_hook_right_fixture_window_01` x19, `uppercut_left_uppercut_left_fixture_window_02` x15, `straight_left_straight_left_fixture_window_01` x14, `straight_left_straight_left_fixture_window_03` x6
- emitted expected punch_left 10 time(s)
- also emitted other attack events: uppercut_left, uppercut_left, hook_right, hook_right, uppercut_right, uppercut_right, hook_right, hook_right, hook_right, hook_right, uppercut_right, uppercut_left, uppercut_left, uppercut_left, uppercut_left, uppercut_right, uppercut_right, uppercut_right, uppercut_right, uppercut_right
- peak expected-class score 0.986
- peak winner straight_left via straight_left_straight_left_fixture_window_01 scored 0.986; runner-up uppercut_right via uppercut_right_uppercut_right_fixture_window_04 scored 0.907 (margin 0.079)
- strongest expected emit used straight_left_straight_left_fixture_window_03 at 0.976 over runner-up uppercut_right_uppercut_right_fixture_window_04 at 0.903 (margin 0.073)
- strongest wrong emit was hook_right via hook_right_hook_right_fixture_window_01 at 0.941 over runner-up straight_left_straight_left_fixture_window_04 at 0.926 (margin 0.014)
- latest matcher reason emit_cooldown_active

Emitted attack events:
- `uppercut_left` at `1114ms` score=`0.903` prototype=`uppercut_left_uppercut_left_fixture_window_02` class=`uppercut_left` runner-up=`uppercut_right/uppercut_right_uppercut_right_fixture_window_04 0.852` margin=`0.051` backend=`prototype_matcher`
- `uppercut_left` at `1333ms` score=`0.885` prototype=`uppercut_left_uppercut_left_fixture_window_02` class=`uppercut_left` runner-up=`uppercut_right/uppercut_right_uppercut_right_fixture_window_04 0.882` margin=`0.002` backend=`prototype_matcher`
- `hook_right` at `1653ms` score=`0.786` prototype=`hook_right_hook_right_fixture_window_01` class=`hook_right` runner-up=`uppercut_right/uppercut_right_uppercut_right_fixture_window_04 0.782` margin=`0.004` backend=`prototype_matcher`
- `hook_right` at `1951ms` score=`0.754` prototype=`hook_right_hook_right_fixture_window_01` class=`hook_right` runner-up=`uppercut_right/uppercut_right_uppercut_right_fixture_window_04 0.753` margin=`0.001` backend=`prototype_matcher`
- `punch_left` at `2263ms` score=`0.915` prototype=`straight_left_straight_left_fixture_window_01` class=`straight_left` runner-up=`uppercut_right/uppercut_right_uppercut_right_fixture_window_04 0.907` margin=`0.009` backend=`prototype_matcher`
- `uppercut_right` at `2562ms` score=`0.913` prototype=`uppercut_right_uppercut_right_fixture_window_04` class=`uppercut_right` runner-up=`hook_right/hook_right_hook_right_fixture_window_01 0.879` margin=`0.033` backend=`prototype_matcher`
- `uppercut_right` at `2870ms` score=`0.797` prototype=`uppercut_right_uppercut_right_fixture_window_04` class=`uppercut_right` runner-up=`hook_right/hook_right_hook_right_fixture_window_01 0.778` margin=`0.019` backend=`prototype_matcher`
- `punch_left` at `3187ms` score=`0.867` prototype=`straight_left_straight_left_fixture_window_01` class=`straight_left` runner-up=`hook_right/hook_right_hook_right_fixture_window_01 0.824` margin=`0.043` backend=`prototype_matcher`
- `hook_right` at `3494ms` score=`0.941` prototype=`hook_right_hook_right_fixture_window_01` class=`hook_right` runner-up=`straight_left/straight_left_straight_left_fixture_window_04 0.926` margin=`0.014` backend=`prototype_matcher`
- `hook_right` at `3810ms` score=`0.863` prototype=`hook_right_hook_right_fixture_window_01` class=`hook_right` runner-up=`uppercut_right/uppercut_right_uppercut_right_fixture_window_04 0.861` margin=`0.001` backend=`prototype_matcher`
- `hook_right` at `4126ms` score=`0.828` prototype=`hook_right_hook_right_fixture_window_01` class=`hook_right` runner-up=`uppercut_right/uppercut_right_uppercut_right_fixture_window_04 0.817` margin=`0.011` backend=`prototype_matcher`
- `punch_left` at `4433ms` score=`0.857` prototype=`straight_left_straight_left_fixture_window_04` class=`straight_left` runner-up=`uppercut_right/uppercut_right_uppercut_right_fixture_window_03 0.834` margin=`0.022` backend=`prototype_matcher`
- `punch_left` at `4748ms` score=`0.976` prototype=`straight_left_straight_left_fixture_window_03` class=`straight_left` runner-up=`uppercut_right/uppercut_right_uppercut_right_fixture_window_04 0.903` margin=`0.073` backend=`prototype_matcher`
- `punch_left` at `5052ms` score=`0.867` prototype=`straight_left_straight_left_fixture_window_03` class=`straight_left` runner-up=`hook_right/hook_right_hook_right_fixture_window_03 0.860` margin=`0.007` backend=`prototype_matcher`
- `hook_right` at `5358ms` score=`0.840` prototype=`hook_right_hook_right_fixture_window_01` class=`hook_right` runner-up=`uppercut_right/uppercut_right_uppercut_right_fixture_window_04 0.835` margin=`0.005` backend=`prototype_matcher`
- `uppercut_right` at `5656ms` score=`0.852` prototype=`uppercut_right_uppercut_right_fixture_window_04` class=`uppercut_right` runner-up=`hook_right/hook_right_hook_right_fixture_window_01 0.852` margin=`0.001` backend=`prototype_matcher`
- `punch_left` at `5955ms` score=`0.924` prototype=`straight_left_straight_left_fixture_window_04` class=`straight_left` runner-up=`hook_right/hook_right_hook_right_fixture_window_01 0.911` margin=`0.013` backend=`prototype_matcher`
- `punch_left` at `6252ms` score=`0.925` prototype=`straight_left_straight_left_fixture_window_01` class=`straight_left` runner-up=`hook_right/hook_right_hook_right_fixture_window_01 0.920` margin=`0.004` backend=`prototype_matcher`
- `uppercut_left` at `6472ms` score=`0.895` prototype=`uppercut_left_uppercut_left_fixture_window_02` class=`uppercut_left` runner-up=`uppercut_right/uppercut_right_uppercut_right_fixture_window_04 0.860` margin=`0.035` backend=`prototype_matcher`
- `uppercut_left` at `6771ms` score=`0.888` prototype=`uppercut_left_uppercut_left_fixture_window_02` class=`uppercut_left` runner-up=`uppercut_right/uppercut_right_uppercut_right_fixture_window_04 0.855` margin=`0.033` backend=`prototype_matcher`
- `uppercut_left` at `7071ms` score=`0.906` prototype=`uppercut_left_uppercut_left_fixture_window_02` class=`uppercut_left` runner-up=`uppercut_right/uppercut_right_uppercut_right_fixture_window_04 0.879` margin=`0.027` backend=`prototype_matcher`
- `uppercut_left` at `7372ms` score=`0.925` prototype=`uppercut_left_uppercut_left_fixture_window_02` class=`uppercut_left` runner-up=`uppercut_right/uppercut_right_uppercut_right_fixture_window_04 0.874` margin=`0.052` backend=`prototype_matcher`
- `uppercut_right` at `7682ms` score=`0.839` prototype=`uppercut_right_uppercut_right_fixture_window_04` class=`uppercut_right` runner-up=`hook_right/hook_right_hook_right_fixture_window_01 0.830` margin=`0.009` backend=`prototype_matcher`
- `uppercut_right` at `7999ms` score=`0.760` prototype=`uppercut_right_uppercut_right_fixture_window_04` class=`uppercut_right` runner-up=`hook_right/hook_right_hook_right_fixture_window_01 0.750` margin=`0.010` backend=`prototype_matcher`
- `uppercut_right` at `8304ms` score=`0.890` prototype=`uppercut_right_uppercut_right_fixture_window_04` class=`uppercut_right` runner-up=`straight_left/straight_left_straight_left_fixture_window_01 0.884` margin=`0.006` backend=`prototype_matcher`
- `punch_left` at `8607ms` score=`0.923` prototype=`straight_left_straight_left_fixture_window_01` class=`straight_left` runner-up=`uppercut_right/uppercut_right_uppercut_right_fixture_window_04 0.901` margin=`0.022` backend=`prototype_matcher`
- `uppercut_right` at `8913ms` score=`0.813` prototype=`uppercut_right_uppercut_right_fixture_window_04` class=`uppercut_right` runner-up=`hook_right/hook_right_hook_right_fixture_window_01 0.797` margin=`0.017` backend=`prototype_matcher`
- `uppercut_right` at `9218ms` score=`0.771` prototype=`uppercut_right_uppercut_right_fixture_window_04` class=`uppercut_right` runner-up=`hook_right/hook_right_hook_right_fixture_window_01 0.757` margin=`0.014` backend=`prototype_matcher`
- `punch_left` at `9523ms` score=`0.945` prototype=`straight_left_straight_left_fixture_window_01` class=`straight_left` runner-up=`uppercut_right/uppercut_right_uppercut_right_fixture_window_04 0.894` margin=`0.051` backend=`prototype_matcher`
- `punch_left` at `9829ms` score=`0.916` prototype=`straight_left_straight_left_fixture_window_02` class=`straight_left` runner-up=`uppercut_right/uppercut_right_uppercut_right_fixture_window_04 0.905` margin=`0.010` backend=`prototype_matcher`

### straight right

- Fixture: `.testbed/assets/fixtures/boxing/punch_right/boxing_guard->punch_right_repeat_04_take_01.yaml`
- Source: `.testbed/assets/fixtures/boxing/punch_right/boxing_guard->punch_right_repeat_04_take_01.mp4`
- Expected event: `punch_right`
- Expected class: `straight_right`
- Attack events emitted: **33**
- Peak snapshot: straight_right via straight_right_straight_right_fixture_window_01 score=0.982 runner-up=uppercut_right/uppercut_right_uppercut_right_fixture_window_01 0.823 margin=0.158
- Strongest expected emit: `punch_right` straight_right via straight_right_straight_right_fixture_window_01 score=0.982 runner-up=uppercut_right/uppercut_right_uppercut_right_fixture_window_01 0.823 margin=0.158
- Strongest wrong emit: `uppercut_left` uppercut_left via uppercut_left_uppercut_left_fixture_window_02 score=0.829 runner-up=straight_right/straight_right_straight_right_fixture_window_04 0.783 margin=0.046
- Emitted prototype counts: `straight_right_straight_right_fixture_window_04` x15, `straight_right_straight_right_fixture_window_01` x5, `straight_right_straight_right_fixture_window_02` x4, `uppercut_left_uppercut_left_fixture_window_03` x4, `uppercut_left_uppercut_left_fixture_window_02` x3
- Best-snapshot prototype counts: `straight_right_straight_right_fixture_window_04` x31, `uppercut_left_uppercut_left_fixture_window_03` x16, `straight_right_straight_right_fixture_window_02` x10, `straight_right_straight_right_fixture_window_01` x9, `straight_right_straight_right_fixture_window_03` x3
- emitted expected punch_right 26 time(s)
- also emitted other attack events: uppercut_left, uppercut_left, uppercut_left, uppercut_left, uppercut_left, uppercut_left, uppercut_left
- peak expected-class score 0.982
- peak winner straight_right via straight_right_straight_right_fixture_window_01 scored 0.982; runner-up uppercut_right via uppercut_right_uppercut_right_fixture_window_01 scored 0.823 (margin 0.158)
- strongest expected emit used straight_right_straight_right_fixture_window_01 at 0.982 over runner-up uppercut_right_uppercut_right_fixture_window_01 at 0.823 (margin 0.158)
- strongest wrong emit was uppercut_left via uppercut_left_uppercut_left_fixture_window_02 at 0.829 over runner-up straight_right_straight_right_fixture_window_04 at 0.783 (margin 0.046)
- latest matcher reason emit_cooldown_active

Emitted attack events:
- `punch_right` at `1090ms` score=`0.847` prototype=`straight_right_straight_right_fixture_window_04` class=`straight_right` runner-up=`uppercut_left/uppercut_left_uppercut_left_fixture_window_03 0.747` margin=`0.100` backend=`prototype_matcher`
- `punch_right` at `1232ms` score=`0.873` prototype=`straight_right_straight_right_fixture_window_04` class=`straight_right` runner-up=`uppercut_left/uppercut_left_uppercut_left_fixture_window_03 0.767` margin=`0.106` backend=`prototype_matcher`
- `punch_right` at `1468ms` score=`0.930` prototype=`straight_right_straight_right_fixture_window_01` class=`straight_right` runner-up=`uppercut_right/uppercut_right_uppercut_right_fixture_window_01 0.814` margin=`0.115` backend=`prototype_matcher`
- `punch_right` at `1715ms` score=`0.940` prototype=`straight_right_straight_right_fixture_window_01` class=`straight_right` runner-up=`uppercut_right/uppercut_right_uppercut_right_fixture_window_01 0.875` margin=`0.065` backend=`prototype_matcher`
- `uppercut_left` at `2216ms` score=`0.829` prototype=`uppercut_left_uppercut_left_fixture_window_02` class=`uppercut_left` runner-up=`straight_right/straight_right_straight_right_fixture_window_04 0.783` margin=`0.046` backend=`prototype_matcher`
- `punch_right` at `2466ms` score=`0.901` prototype=`straight_right_straight_right_fixture_window_04` class=`straight_right` runner-up=`uppercut_left/uppercut_left_uppercut_left_fixture_window_03 0.827` margin=`0.074` backend=`prototype_matcher`
- `punch_right` at `2714ms` score=`0.879` prototype=`straight_right_straight_right_fixture_window_02` class=`straight_right` runner-up=`uppercut_left/uppercut_left_uppercut_left_fixture_window_02 0.846` margin=`0.033` backend=`prototype_matcher`
- `punch_right` at `2965ms` score=`0.966` prototype=`straight_right_straight_right_fixture_window_02` class=`straight_right` runner-up=`uppercut_left/uppercut_left_uppercut_left_fixture_window_02 0.847` margin=`0.119` backend=`prototype_matcher`
- `uppercut_left` at `3225ms` score=`0.759` prototype=`uppercut_left_uppercut_left_fixture_window_03` class=`uppercut_left` runner-up=`straight_right/straight_right_straight_right_fixture_window_02 0.655` margin=`0.104` backend=`prototype_matcher`
- `punch_right` at `3591ms` score=`0.814` prototype=`straight_right_straight_right_fixture_window_04` class=`straight_right` runner-up=`uppercut_left/uppercut_left_uppercut_left_fixture_window_02 0.804` margin=`0.010` backend=`prototype_matcher`
- `punch_right` at `3842ms` score=`0.917` prototype=`straight_right_straight_right_fixture_window_04` class=`straight_right` runner-up=`uppercut_left/uppercut_left_uppercut_left_fixture_window_02 0.801` margin=`0.116` backend=`prototype_matcher`
- `punch_right` at `4090ms` score=`0.924` prototype=`straight_right_straight_right_fixture_window_04` class=`straight_right` runner-up=`uppercut_right/uppercut_right_uppercut_right_fixture_window_01 0.885` margin=`0.039` backend=`prototype_matcher`
- `punch_right` at `4341ms` score=`0.932` prototype=`straight_right_straight_right_fixture_window_03` class=`straight_right` runner-up=`uppercut_left/uppercut_left_uppercut_left_fixture_window_03 0.779` margin=`0.153` backend=`prototype_matcher`
- `uppercut_left` at `4601ms` score=`0.742` prototype=`uppercut_left_uppercut_left_fixture_window_03` class=`uppercut_left` runner-up=`straight_left/straight_left_straight_left_fixture_window_01 0.639` margin=`0.102` backend=`prototype_matcher`
- `uppercut_left` at `4851ms` score=`0.759` prototype=`uppercut_left_uppercut_left_fixture_window_03` class=`uppercut_left` runner-up=`straight_left/straight_left_straight_left_fixture_window_01 0.655` margin=`0.104` backend=`prototype_matcher`
- `punch_right` at `5091ms` score=`0.914` prototype=`straight_right_straight_right_fixture_window_04` class=`straight_right` runner-up=`uppercut_left/uppercut_left_uppercut_left_fixture_window_03 0.801` margin=`0.112` backend=`prototype_matcher`
- `punch_right` at `5342ms` score=`0.949` prototype=`straight_right_straight_right_fixture_window_04` class=`straight_right` runner-up=`uppercut_left/uppercut_left_uppercut_left_fixture_window_02 0.879` margin=`0.070` backend=`prototype_matcher`
- `punch_right` at `5592ms` score=`0.939` prototype=`straight_right_straight_right_fixture_window_04` class=`straight_right` runner-up=`uppercut_left/uppercut_left_uppercut_left_fixture_window_02 0.832` margin=`0.106` backend=`prototype_matcher`
- `punch_right` at `5841ms` score=`0.945` prototype=`straight_right_straight_right_fixture_window_04` class=`straight_right` runner-up=`uppercut_right/uppercut_right_uppercut_right_fixture_window_01 0.793` margin=`0.152` backend=`prototype_matcher`
- `punch_right` at `6068ms` score=`0.922` prototype=`straight_right_straight_right_fixture_window_01` class=`straight_right` runner-up=`uppercut_right/uppercut_right_uppercut_right_fixture_window_01 0.802` margin=`0.120` backend=`prototype_matcher`
- `punch_right` at `6309ms` score=`0.856` prototype=`straight_right_straight_right_fixture_window_04` class=`straight_right` runner-up=`uppercut_left/uppercut_left_uppercut_left_fixture_window_03 0.741` margin=`0.115` backend=`prototype_matcher`
- `punch_right` at `6808ms` score=`0.800` prototype=`straight_right_straight_right_fixture_window_03` class=`straight_right` runner-up=`uppercut_left/uppercut_left_uppercut_left_fixture_window_03 0.765` margin=`0.035` backend=`prototype_matcher`
- `punch_right` at `7059ms` score=`0.856` prototype=`straight_right_straight_right_fixture_window_04` class=`straight_right` runner-up=`uppercut_right/uppercut_right_uppercut_right_fixture_window_01 0.751` margin=`0.105` backend=`prototype_matcher`
- `punch_right` at `7311ms` score=`0.906` prototype=`straight_right_straight_right_fixture_window_01` class=`straight_right` runner-up=`uppercut_right/uppercut_right_uppercut_right_fixture_window_01 0.784` margin=`0.123` backend=`prototype_matcher`
- `punch_right` at `7557ms` score=`0.982` prototype=`straight_right_straight_right_fixture_window_01` class=`straight_right` runner-up=`uppercut_right/uppercut_right_uppercut_right_fixture_window_01 0.823` margin=`0.158` backend=`prototype_matcher`
- `punch_right` at `7808ms` score=`0.768` prototype=`straight_right_straight_right_fixture_window_04` class=`straight_right` runner-up=`uppercut_left/uppercut_left_uppercut_left_fixture_window_03 0.756` margin=`0.012` backend=`prototype_matcher`
- `uppercut_left` at `8183ms` score=`0.805` prototype=`uppercut_left_uppercut_left_fixture_window_02` class=`uppercut_left` runner-up=`straight_left/straight_left_straight_left_fixture_window_01 0.667` margin=`0.138` backend=`prototype_matcher`
- `punch_right` at `8431ms` score=`0.901` prototype=`straight_right_straight_right_fixture_window_04` class=`straight_right` runner-up=`uppercut_left/uppercut_left_uppercut_left_fixture_window_03 0.827` margin=`0.074` backend=`prototype_matcher`
- `punch_right` at `8685ms` score=`0.878` prototype=`straight_right_straight_right_fixture_window_02` class=`straight_right` runner-up=`uppercut_left/uppercut_left_uppercut_left_fixture_window_02 0.839` margin=`0.039` backend=`prototype_matcher`
- `punch_right` at `8933ms` score=`0.966` prototype=`straight_right_straight_right_fixture_window_02` class=`straight_right` runner-up=`uppercut_left/uppercut_left_uppercut_left_fixture_window_02 0.847` margin=`0.119` backend=`prototype_matcher`
- `uppercut_left` at `9193ms` score=`0.759` prototype=`uppercut_left_uppercut_left_fixture_window_03` class=`uppercut_left` runner-up=`straight_right/straight_right_straight_right_fixture_window_02 0.655` margin=`0.104` backend=`prototype_matcher`
- `uppercut_left` at `9562ms` score=`0.786` prototype=`uppercut_left_uppercut_left_fixture_window_02` class=`uppercut_left` runner-up=`straight_right/straight_right_straight_right_fixture_window_04 0.733` margin=`0.054` backend=`prototype_matcher`
- `punch_right` at `9810ms` score=`0.917` prototype=`straight_right_straight_right_fixture_window_04` class=`straight_right` runner-up=`uppercut_left/uppercut_left_uppercut_left_fixture_window_02 0.801` margin=`0.116` backend=`prototype_matcher`

### hook left

- Fixture: `.testbed/assets/fixtures/boxing/hook_left/boxing_guard->hook_left_repeat_04_take_01.yaml`
- Source: `.testbed/assets/fixtures/boxing/hook_left/boxing_guard->hook_left_repeat_04_take_01.mp4`
- Expected event: `hook_left`
- Expected class: `hook_left`
- Attack events emitted: **27**
- Peak snapshot: hook_left via hook_left_hook_left_fixture_window_04 score=0.980 runner-up=straight_left/straight_left_straight_left_fixture_window_03 0.892 margin=0.088
- Strongest expected emit: `hook_left` hook_left via hook_left_hook_left_fixture_window_04 score=0.961 runner-up=straight_left/straight_left_straight_left_fixture_window_03 0.889 margin=0.072
- Strongest wrong emit: `uppercut_right` uppercut_right via uppercut_right_uppercut_right_fixture_window_01 score=0.920 runner-up=uppercut_left/uppercut_left_uppercut_left_fixture_window_02 0.895 margin=0.025
- Emitted prototype counts: `hook_left_hook_left_fixture_window_01` x6, `hook_right_hook_right_fixture_window_03` x6, `uppercut_left_uppercut_left_fixture_window_01` x4, `uppercut_right_uppercut_right_fixture_window_01` x3, `hook_left_hook_left_fixture_window_03` x2
- Best-snapshot prototype counts: `hook_left_hook_left_fixture_window_01` x16, `hook_right_hook_right_fixture_window_03` x13, `hook_left_hook_left_fixture_window_03` x12, `uppercut_left_uppercut_left_fixture_window_01` x9, `uppercut_right_uppercut_right_fixture_window_03` x9
- emitted expected hook_left 10 time(s)
- also emitted other attack events: uppercut_right, uppercut_left, hook_right, hook_right, hook_right, hook_right, hook_right, hook_right, uppercut_right, punch_left, uppercut_left, uppercut_right, uppercut_left, uppercut_right, uppercut_left, hook_right, hook_right
- peak expected-class score 0.980
- peak winner hook_left via hook_left_hook_left_fixture_window_04 scored 0.980; runner-up straight_left via straight_left_straight_left_fixture_window_03 scored 0.892 (margin 0.088)
- strongest expected emit used hook_left_hook_left_fixture_window_04 at 0.961 over runner-up straight_left_straight_left_fixture_window_03 at 0.889 (margin 0.072)
- strongest wrong emit was uppercut_right via uppercut_right_uppercut_right_fixture_window_01 at 0.920 over runner-up uppercut_left_uppercut_left_fixture_window_02 at 0.895 (margin 0.025)
- latest matcher reason emit_cooldown_active

Emitted attack events:
- `uppercut_right` at `1080ms` score=`0.900` prototype=`uppercut_right_uppercut_right_fixture_window_01` class=`uppercut_right` runner-up=`uppercut_left/uppercut_left_uppercut_left_fixture_window_02 0.882` margin=`0.019` backend=`prototype_matcher`
- `uppercut_left` at `1322ms` score=`0.881` prototype=`uppercut_left_uppercut_left_fixture_window_01` class=`uppercut_left` runner-up=`hook_right/hook_right_hook_right_fixture_window_01 0.873` margin=`0.008` backend=`prototype_matcher`
- `hook_right` at `1932ms` score=`0.701` prototype=`hook_right_hook_right_fixture_window_03` class=`hook_right` runner-up=`uppercut_right/uppercut_right_uppercut_right_fixture_window_03 0.685` margin=`0.015` backend=`prototype_matcher`
- `hook_left` at `2243ms` score=`0.918` prototype=`hook_left_hook_left_fixture_window_01` class=`hook_left` runner-up=`hook_right/hook_right_hook_right_fixture_window_01 0.875` margin=`0.044` backend=`prototype_matcher`
- `hook_left` at `2541ms` score=`0.943` prototype=`hook_left_hook_left_fixture_window_01` class=`hook_left` runner-up=`straight_left/straight_left_straight_left_fixture_window_03 0.842` margin=`0.101` backend=`prototype_matcher`
- `hook_left` at `2853ms` score=`0.898` prototype=`hook_left_hook_left_fixture_window_01` class=`hook_left` runner-up=`straight_left/straight_left_straight_left_fixture_window_03 0.854` margin=`0.043` backend=`prototype_matcher`
- `hook_right` at `3158ms` score=`0.731` prototype=`hook_right_hook_right_fixture_window_03` class=`hook_right` runner-up=`uppercut_right/uppercut_right_uppercut_right_fixture_window_03 0.695` margin=`0.036` backend=`prototype_matcher`
- `hook_left` at `3670ms` score=`0.774` prototype=`hook_left_hook_left_fixture_window_03` class=`hook_left` runner-up=`hook_right/hook_right_hook_right_fixture_window_03 0.747` margin=`0.027` backend=`prototype_matcher`
- `hook_left` at `3978ms` score=`0.931` prototype=`hook_left_hook_left_fixture_window_02` class=`hook_left` runner-up=`straight_left/straight_left_straight_left_fixture_window_02 0.801` margin=`0.129` backend=`prototype_matcher`
- `hook_left` at `4292ms` score=`0.889` prototype=`hook_left_hook_left_fixture_window_01` class=`hook_left` runner-up=`straight_left/straight_left_straight_left_fixture_window_03 0.851` margin=`0.038` backend=`prototype_matcher`
- `hook_right` at `4596ms` score=`0.783` prototype=`hook_right_hook_right_fixture_window_03` class=`hook_right` runner-up=`uppercut_right/uppercut_right_uppercut_right_fixture_window_03 0.748` margin=`0.035` backend=`prototype_matcher`
- `hook_right` at `5108ms` score=`0.763` prototype=`hook_right_hook_right_fixture_window_03` class=`hook_right` runner-up=`uppercut_right/uppercut_right_uppercut_right_fixture_window_03 0.728` margin=`0.035` backend=`prototype_matcher`
- `hook_left` at `5419ms` score=`0.952` prototype=`hook_left_hook_left_fixture_window_03` class=`hook_left` runner-up=`hook_right/hook_right_hook_right_fixture_window_03 0.755` margin=`0.198` backend=`prototype_matcher`
- `hook_left` at `5728ms` score=`0.893` prototype=`hook_left_hook_left_fixture_window_01` class=`hook_left` runner-up=`straight_left/straight_left_straight_left_fixture_window_03 0.793` margin=`0.100` backend=`prototype_matcher`
- `hook_right` at `6047ms` score=`0.714` prototype=`hook_right_hook_right_fixture_window_03` class=`hook_right` runner-up=`uppercut_right/uppercut_right_uppercut_right_fixture_window_03 0.674` margin=`0.040` backend=`prototype_matcher`
- `hook_right` at `6348ms` score=`0.705` prototype=`hook_right_hook_right_fixture_window_02` class=`hook_right` runner-up=`uppercut_right/uppercut_right_uppercut_right_fixture_window_03 0.664` margin=`0.041` backend=`prototype_matcher`
- `uppercut_right` at `6660ms` score=`0.764` prototype=`uppercut_right_uppercut_right_fixture_window_03` class=`uppercut_right` runner-up=`hook_right/hook_right_hook_right_fixture_window_03 0.757` margin=`0.007` backend=`prototype_matcher`
- `hook_left` at `6965ms` score=`0.961` prototype=`hook_left_hook_left_fixture_window_04` class=`hook_left` runner-up=`straight_left/straight_left_straight_left_fixture_window_03 0.889` margin=`0.072` backend=`prototype_matcher`
- `punch_left` at `7261ms` score=`0.833` prototype=`straight_left_straight_left_fixture_window_04` class=`straight_left` runner-up=`uppercut_left/uppercut_left_uppercut_left_fixture_window_01 0.828` margin=`0.005` backend=`prototype_matcher`
- `uppercut_left` at `7581ms` score=`0.863` prototype=`uppercut_left_uppercut_left_fixture_window_01` class=`uppercut_left` runner-up=`straight_left/straight_left_straight_left_fixture_window_04 0.834` margin=`0.029` backend=`prototype_matcher`
- `uppercut_right` at `7846ms` score=`0.897` prototype=`uppercut_right_uppercut_right_fixture_window_01` class=`uppercut_right` runner-up=`uppercut_left/uppercut_left_uppercut_left_fixture_window_01 0.897` margin=`0.000` backend=`prototype_matcher`
- `uppercut_left` at `8154ms` score=`0.904` prototype=`uppercut_left_uppercut_left_fixture_window_01` class=`uppercut_left` runner-up=`uppercut_right/uppercut_right_uppercut_right_fixture_window_04 0.904` margin=`0.000` backend=`prototype_matcher`
- `uppercut_right` at `8454ms` score=`0.920` prototype=`uppercut_right_uppercut_right_fixture_window_01` class=`uppercut_right` runner-up=`uppercut_left/uppercut_left_uppercut_left_fixture_window_02 0.895` margin=`0.025` backend=`prototype_matcher`
- `uppercut_left` at `8760ms` score=`0.898` prototype=`uppercut_left_uppercut_left_fixture_window_01` class=`uppercut_left` runner-up=`uppercut_right/uppercut_right_uppercut_right_fixture_window_04 0.888` margin=`0.010` backend=`prototype_matcher`
- `hook_right` at `9083ms` score=`0.794` prototype=`hook_right_hook_right_fixture_window_01` class=`hook_right` runner-up=`uppercut_right/uppercut_right_uppercut_right_fixture_window_03 0.786` margin=`0.008` backend=`prototype_matcher`
- `hook_right` at `9475ms` score=`0.701` prototype=`hook_right_hook_right_fixture_window_03` class=`hook_right` runner-up=`uppercut_right/uppercut_right_uppercut_right_fixture_window_03 0.685` margin=`0.015` backend=`prototype_matcher`
- `hook_left` at `9777ms` score=`0.899` prototype=`hook_left_hook_left_fixture_window_01` class=`hook_left` runner-up=`hook_right/hook_right_hook_right_fixture_window_01 0.862` margin=`0.037` backend=`prototype_matcher`

### hook right

- Fixture: `.testbed/assets/fixtures/boxing/hook_right/boxing_guard->hook_right_repeat_04_take_01.yaml`
- Source: `.testbed/assets/fixtures/boxing/hook_right/boxing_guard->hook_right_repeat_04_take_01.mp4`
- Expected event: `hook_right`
- Expected class: `hook_right`
- Attack events emitted: **27**
- Peak snapshot: hook_right via hook_right_hook_right_fixture_window_01 score=0.975 runner-up=uppercut_right/uppercut_right_uppercut_right_fixture_window_04 0.899 margin=0.076
- Strongest expected emit: `hook_right` hook_right via hook_right_hook_right_fixture_window_01 score=0.972 runner-up=uppercut_right/uppercut_right_uppercut_right_fixture_window_04 0.906 margin=0.066
- Strongest wrong emit: `uppercut_right` uppercut_right via uppercut_right_uppercut_right_fixture_window_01 score=0.887 runner-up=hook_right/hook_right_hook_right_fixture_window_01 0.880 margin=0.007
- Emitted prototype counts: `hook_right_hook_right_fixture_window_01` x10, `hook_right_hook_right_fixture_window_04` x4, `hook_left_hook_left_fixture_window_01` x3, `hook_right_hook_right_fixture_window_03` x3, `hook_left_hook_left_fixture_window_04` x2
- Best-snapshot prototype counts: `hook_right_hook_right_fixture_window_01` x30, `hook_left_hook_left_fixture_window_01` x15, `hook_right_hook_right_fixture_window_04` x9, `straight_left_straight_left_fixture_window_01` x8, `hook_right_hook_right_fixture_window_03` x6
- emitted expected hook_right 18 time(s)
- also emitted other attack events: punch_left, hook_left, punch_left, hook_left, hook_left, hook_left, hook_left, uppercut_right, uppercut_left
- peak expected-class score 0.975
- peak winner hook_right via hook_right_hook_right_fixture_window_01 scored 0.975; runner-up uppercut_right via uppercut_right_uppercut_right_fixture_window_04 scored 0.899 (margin 0.076)
- strongest expected emit used hook_right_hook_right_fixture_window_01 at 0.972 over runner-up uppercut_right_uppercut_right_fixture_window_04 at 0.906 (margin 0.066)
- strongest wrong emit was uppercut_right via uppercut_right_uppercut_right_fixture_window_01 at 0.887 over runner-up hook_right_hook_right_fixture_window_01 at 0.880 (margin 0.007)
- latest matcher reason step_wait

Emitted attack events:
- `hook_right` at `1122ms` score=`0.904` prototype=`hook_right_hook_right_fixture_window_01` class=`hook_right` runner-up=`uppercut_right/uppercut_right_uppercut_right_fixture_window_04 0.875` margin=`0.029` backend=`prototype_matcher`
- `punch_left` at `1413ms` score=`0.779` prototype=`straight_left_straight_left_fixture_window_01` class=`straight_left` runner-up=`uppercut_left/uppercut_left_uppercut_left_fixture_window_01 0.737` margin=`0.041` backend=`prototype_matcher`
- `hook_right` at `1817ms` score=`0.740` prototype=`hook_right_hook_right_fixture_window_04` class=`hook_right` runner-up=`straight_left/straight_left_straight_left_fixture_window_04 0.707` margin=`0.033` backend=`prototype_matcher`
- `hook_right` at `2112ms` score=`0.919` prototype=`hook_right_hook_right_fixture_window_01` class=`hook_right` runner-up=`uppercut_right/uppercut_right_uppercut_right_fixture_window_04 0.880` margin=`0.039` backend=`prototype_matcher`
- `hook_right` at `2414ms` score=`0.972` prototype=`hook_right_hook_right_fixture_window_01` class=`hook_right` runner-up=`uppercut_right/uppercut_right_uppercut_right_fixture_window_04 0.906` margin=`0.066` backend=`prototype_matcher`
- `hook_left` at `2723ms` score=`0.834` prototype=`hook_left_hook_left_fixture_window_04` class=`hook_left` runner-up=`straight_left/straight_left_straight_left_fixture_window_03 0.807` margin=`0.027` backend=`prototype_matcher`
- `punch_left` at `3016ms` score=`0.711` prototype=`straight_left_straight_left_fixture_window_03` class=`straight_left` runner-up=`hook_left/hook_left_hook_left_fixture_window_01 0.704` margin=`0.007` backend=`prototype_matcher`
- `hook_right` at `3439ms` score=`0.783` prototype=`hook_right_hook_right_fixture_window_04` class=`hook_right` runner-up=`hook_left/hook_left_hook_left_fixture_window_01 0.761` margin=`0.022` backend=`prototype_matcher`
- `hook_right` at `3734ms` score=`0.930` prototype=`hook_right_hook_right_fixture_window_02` class=`hook_right` runner-up=`hook_left/hook_left_hook_left_fixture_window_04 0.907` margin=`0.023` backend=`prototype_matcher`
- `hook_right` at `4037ms` score=`0.894` prototype=`hook_right_hook_right_fixture_window_03` class=`hook_right` runner-up=`uppercut_right/uppercut_right_uppercut_right_fixture_window_04 0.845` margin=`0.049` backend=`prototype_matcher`
- `hook_left` at `4353ms` score=`0.824` prototype=`hook_left_hook_left_fixture_window_01` class=`hook_left` runner-up=`straight_left/straight_left_straight_left_fixture_window_03 0.781` margin=`0.043` backend=`prototype_matcher`
- `hook_left` at `4852ms` score=`0.748` prototype=`hook_left_hook_left_fixture_window_01` class=`hook_left` runner-up=`hook_right/hook_right_hook_right_fixture_window_04 0.741` margin=`0.007` backend=`prototype_matcher`
- `hook_right` at `5157ms` score=`0.850` prototype=`hook_right_hook_right_fixture_window_03` class=`hook_right` runner-up=`hook_left/hook_left_hook_left_fixture_window_04 0.825` margin=`0.025` backend=`prototype_matcher`
- `hook_right` at `5465ms` score=`0.944` prototype=`hook_right_hook_right_fixture_window_03` class=`hook_right` runner-up=`hook_left/hook_left_hook_left_fixture_window_04 0.876` margin=`0.068` backend=`prototype_matcher`
- `hook_right` at `5777ms` score=`0.889` prototype=`hook_right_hook_right_fixture_window_01` class=`hook_right` runner-up=`uppercut_right/uppercut_right_uppercut_right_fixture_window_04 0.858` margin=`0.030` backend=`prototype_matcher`
- `hook_left` at `6096ms` score=`0.733` prototype=`hook_left_hook_left_fixture_window_01` class=`hook_left` runner-up=`straight_left/straight_left_straight_left_fixture_window_03 0.721` margin=`0.012` backend=`prototype_matcher`
- `hook_right` at `6618ms` score=`0.780` prototype=`hook_right_hook_right_fixture_window_04` class=`hook_right` runner-up=`hook_left/hook_left_hook_left_fixture_window_01 0.695` margin=`0.085` backend=`prototype_matcher`
- `hook_left` at `6917ms` score=`0.872` prototype=`hook_left_hook_left_fixture_window_04` class=`hook_left` runner-up=`hook_right/hook_right_hook_right_fixture_window_03 0.848` margin=`0.024` backend=`prototype_matcher`
- `hook_right` at `7221ms` score=`0.945` prototype=`hook_right_hook_right_fixture_window_01` class=`hook_right` runner-up=`uppercut_right/uppercut_right_uppercut_right_fixture_window_04 0.906` margin=`0.039` backend=`prototype_matcher`
- `hook_right` at `7513ms` score=`0.915` prototype=`hook_right_hook_right_fixture_window_01` class=`hook_right` runner-up=`uppercut_right/uppercut_right_uppercut_right_fixture_window_04 0.890` margin=`0.025` backend=`prototype_matcher`
- `hook_right` at `7811ms` score=`0.912` prototype=`hook_right_hook_right_fixture_window_01` class=`hook_right` runner-up=`uppercut_right/uppercut_right_uppercut_right_fixture_window_04 0.894` margin=`0.018` backend=`prototype_matcher`
- `uppercut_right` at `7996ms` score=`0.887` prototype=`uppercut_right_uppercut_right_fixture_window_01` class=`uppercut_right` runner-up=`hook_right/hook_right_hook_right_fixture_window_01 0.880` margin=`0.007` backend=`prototype_matcher`
- `hook_right` at `8293ms` score=`0.924` prototype=`hook_right_hook_right_fixture_window_01` class=`hook_right` runner-up=`uppercut_right/uppercut_right_uppercut_right_fixture_window_04 0.893` margin=`0.032` backend=`prototype_matcher`
- `hook_right` at `8592ms` score=`0.904` prototype=`hook_right_hook_right_fixture_window_01` class=`hook_right` runner-up=`uppercut_right/uppercut_right_uppercut_right_fixture_window_01 0.874` margin=`0.031` backend=`prototype_matcher`
- `uppercut_left` at `8913ms` score=`0.875` prototype=`uppercut_left_uppercut_left_fixture_window_01` class=`uppercut_left` runner-up=`straight_left/straight_left_straight_left_fixture_window_01 0.841` margin=`0.034` backend=`prototype_matcher`
- `hook_right` at `9517ms` score=`0.740` prototype=`hook_right_hook_right_fixture_window_04` class=`hook_right` runner-up=`straight_left/straight_left_straight_left_fixture_window_04 0.707` margin=`0.033` backend=`prototype_matcher`
- `hook_right` at `9817ms` score=`0.919` prototype=`hook_right_hook_right_fixture_window_01` class=`hook_right` runner-up=`uppercut_right/uppercut_right_uppercut_right_fixture_window_04 0.880` margin=`0.039` backend=`prototype_matcher`

### uppercut left

- Fixture: `.testbed/assets/fixtures/boxing/uppercut_left/boxing_guard->uppercut_left_repeat_04_take_01.yaml`
- Source: `.testbed/assets/fixtures/boxing/uppercut_left/boxing_guard->uppercut_left_repeat_04_take_01.mp4`
- Expected event: `uppercut_left`
- Expected class: `uppercut_left`
- Attack events emitted: **29**
- Peak snapshot: uppercut_left via uppercut_left_uppercut_left_fixture_window_02 score=0.993 runner-up=uppercut_right/uppercut_right_uppercut_right_fixture_window_01 0.892 margin=0.102
- Strongest expected emit: `uppercut_left` uppercut_left via uppercut_left_uppercut_left_fixture_window_01 score=0.992 runner-up=uppercut_right/uppercut_right_uppercut_right_fixture_window_04 0.903 margin=0.089
- Strongest wrong emit: `uppercut_right` uppercut_right via uppercut_right_uppercut_right_fixture_window_04 score=0.915 runner-up=uppercut_left/uppercut_left_uppercut_left_fixture_window_02 0.914 margin=0.000
- Emitted prototype counts: `uppercut_left_uppercut_left_fixture_window_02` x6, `uppercut_left_uppercut_left_fixture_window_03` x6, `uppercut_left_uppercut_left_fixture_window_01` x4, `hook_right_hook_right_fixture_window_03` x3, `uppercut_right_uppercut_right_fixture_window_03` x3
- Best-snapshot prototype counts: `uppercut_left_uppercut_left_fixture_window_02` x18, `uppercut_left_uppercut_left_fixture_window_03` x17, `hook_right_hook_right_fixture_window_03` x13, `uppercut_left_uppercut_left_fixture_window_01` x13, `uppercut_right_uppercut_right_fixture_window_03` x7
- emitted expected uppercut_left 16 time(s)
- also emitted other attack events: uppercut_right, hook_right, punch_left, hook_right, hook_right, uppercut_right, hook_right, hook_left, hook_right, uppercut_right, uppercut_right, hook_right, hook_right
- peak expected-class score 0.993
- peak winner uppercut_left via uppercut_left_uppercut_left_fixture_window_02 scored 0.993; runner-up uppercut_right via uppercut_right_uppercut_right_fixture_window_01 scored 0.892 (margin 0.102)
- strongest expected emit used uppercut_left_uppercut_left_fixture_window_01 at 0.992 over runner-up uppercut_right_uppercut_right_fixture_window_04 at 0.903 (margin 0.089)
- strongest wrong emit was uppercut_right via uppercut_right_uppercut_right_fixture_window_04 at 0.915 over runner-up uppercut_left_uppercut_left_fixture_window_02 at 0.914 (margin 0.000)
- latest matcher reason emit_cooldown_active

Emitted attack events:
- `uppercut_right` at `1081ms` score=`0.756` prototype=`uppercut_right_uppercut_right_fixture_window_03` class=`uppercut_right` runner-up=`hook_right/hook_right_hook_right_fixture_window_03 0.735` margin=`0.021` backend=`prototype_matcher`
- `hook_right` at `1334ms` score=`0.734` prototype=`hook_right_hook_right_fixture_window_02` class=`hook_right` runner-up=`uppercut_right/uppercut_right_uppercut_right_fixture_window_03 0.663` margin=`0.070` backend=`prototype_matcher`
- `uppercut_left` at `1630ms` score=`0.855` prototype=`uppercut_left_uppercut_left_fixture_window_02` class=`uppercut_left` runner-up=`hook_right/hook_right_hook_right_fixture_window_01 0.775` margin=`0.081` backend=`prototype_matcher`
- `uppercut_left` at `1936ms` score=`0.917` prototype=`uppercut_left_uppercut_left_fixture_window_01` class=`uppercut_left` runner-up=`uppercut_right/uppercut_right_uppercut_right_fixture_window_04 0.849` margin=`0.068` backend=`prototype_matcher`
- `uppercut_left` at `2236ms` score=`0.992` prototype=`uppercut_left_uppercut_left_fixture_window_01` class=`uppercut_left` runner-up=`uppercut_right/uppercut_right_uppercut_right_fixture_window_04 0.903` margin=`0.089` backend=`prototype_matcher`
- `uppercut_left` at `2538ms` score=`0.924` prototype=`uppercut_left_uppercut_left_fixture_window_01` class=`uppercut_left` runner-up=`uppercut_right/uppercut_right_uppercut_right_fixture_window_04 0.902` margin=`0.022` backend=`prototype_matcher`
- `punch_left` at `2844ms` score=`0.859` prototype=`straight_left_straight_left_fixture_window_01` class=`straight_left` runner-up=`uppercut_right/uppercut_right_uppercut_right_fixture_window_03 0.845` margin=`0.014` backend=`prototype_matcher`
- `hook_right` at `3142ms` score=`0.721` prototype=`hook_right_hook_right_fixture_window_03` class=`hook_right` runner-up=`uppercut_right/uppercut_right_uppercut_right_fixture_window_03 0.667` margin=`0.054` backend=`prototype_matcher`
- `hook_right` at `3450ms` score=`0.808` prototype=`hook_right_hook_right_fixture_window_03` class=`hook_right` runner-up=`uppercut_right/uppercut_right_uppercut_right_fixture_window_04 0.803` margin=`0.006` backend=`prototype_matcher`
- `uppercut_left` at `3766ms` score=`0.937` prototype=`uppercut_left_uppercut_left_fixture_window_03` class=`uppercut_left` runner-up=`uppercut_right/uppercut_right_uppercut_right_fixture_window_04 0.801` margin=`0.136` backend=`prototype_matcher`
- `uppercut_left` at `4068ms` score=`0.981` prototype=`uppercut_left_uppercut_left_fixture_window_02` class=`uppercut_left` runner-up=`uppercut_right/uppercut_right_uppercut_right_fixture_window_01 0.893` margin=`0.088` backend=`prototype_matcher`
- `uppercut_left` at `4372ms` score=`0.951` prototype=`uppercut_left_uppercut_left_fixture_window_02` class=`uppercut_left` runner-up=`uppercut_right/uppercut_right_uppercut_right_fixture_window_01 0.892` margin=`0.059` backend=`prototype_matcher`
- `uppercut_left` at `4672ms` score=`0.902` prototype=`uppercut_left_uppercut_left_fixture_window_02` class=`uppercut_left` runner-up=`uppercut_right/uppercut_right_uppercut_right_fixture_window_01 0.898` margin=`0.005` backend=`prototype_matcher`
- `uppercut_right` at `4974ms` score=`0.707` prototype=`uppercut_right_uppercut_right_fixture_window_03` class=`uppercut_right` runner-up=`hook_right/hook_right_hook_right_fixture_window_03 0.673` margin=`0.034` backend=`prototype_matcher`
- `hook_right` at `5296ms` score=`0.723` prototype=`hook_right_hook_right_fixture_window_04` class=`hook_right` runner-up=`uppercut_right/uppercut_right_uppercut_right_fixture_window_03 0.628` margin=`0.095` backend=`prototype_matcher`
- `uppercut_left` at `5596ms` score=`0.894` prototype=`uppercut_left_uppercut_left_fixture_window_03` class=`uppercut_left` runner-up=`uppercut_right/uppercut_right_uppercut_right_fixture_window_01 0.838` margin=`0.056` backend=`prototype_matcher`
- `uppercut_left` at `5909ms` score=`0.962` prototype=`uppercut_left_uppercut_left_fixture_window_03` class=`uppercut_left` runner-up=`uppercut_right/uppercut_right_uppercut_right_fixture_window_01 0.865` margin=`0.097` backend=`prototype_matcher`
- `uppercut_left` at `6215ms` score=`0.953` prototype=`uppercut_left_uppercut_left_fixture_window_03` class=`uppercut_left` runner-up=`uppercut_right/uppercut_right_uppercut_right_fixture_window_01 0.880` margin=`0.073` backend=`prototype_matcher`
- `uppercut_left` at `6521ms` score=`0.946` prototype=`uppercut_left_uppercut_left_fixture_window_02` class=`uppercut_left` runner-up=`uppercut_right/uppercut_right_uppercut_right_fixture_window_01 0.911` margin=`0.034` backend=`prototype_matcher`
- `hook_left` at `6847ms` score=`0.804` prototype=`hook_left_hook_left_fixture_window_01` class=`hook_left` runner-up=`straight_left/straight_left_straight_left_fixture_window_03 0.789` margin=`0.015` backend=`prototype_matcher`
- `hook_right` at `7235ms` score=`0.738` prototype=`hook_right_hook_right_fixture_window_04` class=`hook_right` runner-up=`uppercut_right/uppercut_right_uppercut_right_fixture_window_03 0.681` margin=`0.057` backend=`prototype_matcher`
- `uppercut_left` at `7534ms` score=`0.837` prototype=`uppercut_left_uppercut_left_fixture_window_03` class=`uppercut_left` runner-up=`uppercut_right/uppercut_right_uppercut_right_fixture_window_04 0.784` margin=`0.053` backend=`prototype_matcher`
- `uppercut_left` at `7830ms` score=`0.905` prototype=`uppercut_left_uppercut_left_fixture_window_03` class=`uppercut_left` runner-up=`uppercut_right/uppercut_right_uppercut_right_fixture_window_01 0.892` margin=`0.013` backend=`prototype_matcher`
- `uppercut_left` at `8214ms` score=`0.925` prototype=`uppercut_left_uppercut_left_fixture_window_02` class=`uppercut_left` runner-up=`uppercut_right/uppercut_right_uppercut_right_fixture_window_04 0.911` margin=`0.014` backend=`prototype_matcher`
- `uppercut_right` at `8515ms` score=`0.915` prototype=`uppercut_right_uppercut_right_fixture_window_04` class=`uppercut_right` runner-up=`uppercut_left/uppercut_left_uppercut_left_fixture_window_02 0.914` margin=`0.000` backend=`prototype_matcher`
- `uppercut_right` at `8826ms` score=`0.863` prototype=`uppercut_right_uppercut_right_fixture_window_03` class=`uppercut_right` runner-up=`hook_right/hook_right_hook_right_fixture_window_01 0.852` margin=`0.011` backend=`prototype_matcher`
- `hook_right` at `9125ms` score=`0.744` prototype=`hook_right_hook_right_fixture_window_02` class=`hook_right` runner-up=`uppercut_right/uppercut_right_uppercut_right_fixture_window_03 0.665` margin=`0.080` backend=`prototype_matcher`
- `hook_right` at `9435ms` score=`0.792` prototype=`hook_right_hook_right_fixture_window_03` class=`hook_right` runner-up=`uppercut_left/uppercut_left_uppercut_left_fixture_window_03 0.741` margin=`0.051` backend=`prototype_matcher`
- `uppercut_left` at `9750ms` score=`0.865` prototype=`uppercut_left_uppercut_left_fixture_window_01` class=`uppercut_left` runner-up=`uppercut_right/uppercut_right_uppercut_right_fixture_window_04 0.825` margin=`0.040` backend=`prototype_matcher`

### uppercut right

- Fixture: `.testbed/assets/fixtures/boxing/uppercut_right/boxing_guard->uppercut_right_repeat_04_take_01.yaml`
- Source: `.testbed/assets/fixtures/boxing/uppercut_right/boxing_guard->uppercut_right_repeat_04_take_01.mp4`
- Expected event: `uppercut_right`
- Expected class: `uppercut_right`
- Attack events emitted: **27**
- Peak snapshot: uppercut_right via uppercut_right_uppercut_right_fixture_window_01 score=1.000 runner-up=straight_right/straight_right_straight_right_fixture_window_01 0.859 margin=0.141
- Strongest expected emit: `uppercut_right` uppercut_right via uppercut_right_uppercut_right_fixture_window_01 score=1.000 runner-up=straight_right/straight_right_straight_right_fixture_window_01 0.859 margin=0.141
- Strongest wrong emit: `hook_right` hook_right via hook_right_hook_right_fixture_window_01 score=0.919 runner-up=uppercut_right/uppercut_right_uppercut_right_fixture_window_04 0.904 margin=0.015
- Emitted prototype counts: `uppercut_right_uppercut_right_fixture_window_01` x8, `hook_left_hook_left_fixture_window_03` x6, `hook_left_hook_left_fixture_window_02` x2, `uppercut_right_uppercut_right_fixture_window_03` x2, `uppercut_right_uppercut_right_fixture_window_04` x2
- Best-snapshot prototype counts: `uppercut_right_uppercut_right_fixture_window_01` x23, `uppercut_right_uppercut_right_fixture_window_04` x12, `hook_left_hook_left_fixture_window_03` x11, `hook_left_hook_left_fixture_window_01` x9, `hook_left_hook_left_fixture_window_02` x8
- emitted expected uppercut_right 13 time(s)
- also emitted other attack events: uppercut_left, hook_left, punch_left, hook_left, hook_left, hook_left, hook_left, hook_right, hook_left, hook_left, hook_left, hook_left, punch_right, hook_left
- peak expected-class score 1.000
- peak winner uppercut_right via uppercut_right_uppercut_right_fixture_window_01 scored 1.000; runner-up straight_right via straight_right_straight_right_fixture_window_01 scored 0.859 (margin 0.141)
- strongest expected emit used uppercut_right_uppercut_right_fixture_window_01 at 1.000 over runner-up straight_right_straight_right_fixture_window_01 at 0.859 (margin 0.141)
- strongest wrong emit was hook_right via hook_right_hook_right_fixture_window_01 at 0.919 over runner-up uppercut_right_uppercut_right_fixture_window_04 at 0.904 (margin 0.015)
- latest matcher reason step_wait

Emitted attack events:
- `uppercut_left` at `1118ms` score=`0.730` prototype=`uppercut_left_uppercut_left_fixture_window_01` class=`uppercut_left` runner-up=`hook_left/hook_left_hook_left_fixture_window_04 0.714` margin=`0.016` backend=`prototype_matcher`
- `hook_left` at `1367ms` score=`0.801` prototype=`hook_left_hook_left_fixture_window_03` class=`hook_left` runner-up=`straight_left/straight_left_straight_left_fixture_window_03 0.708` margin=`0.093` backend=`prototype_matcher`
- `punch_left` at `1654ms` score=`0.749` prototype=`straight_left_straight_left_fixture_window_01` class=`straight_left` runner-up=`hook_left/hook_left_hook_left_fixture_window_02 0.722` margin=`0.027` backend=`prototype_matcher`
- `uppercut_right` at `1963ms` score=`0.905` prototype=`uppercut_right_uppercut_right_fixture_window_01` class=`uppercut_right` runner-up=`straight_right/straight_right_straight_right_fixture_window_01 0.866` margin=`0.039` backend=`prototype_matcher`
- `uppercut_right` at `2264ms` score=`1.000` prototype=`uppercut_right_uppercut_right_fixture_window_01` class=`uppercut_right` runner-up=`straight_right/straight_right_straight_right_fixture_window_01 0.859` margin=`0.141` backend=`prototype_matcher`
- `uppercut_right` at `2570ms` score=`0.933` prototype=`uppercut_right_uppercut_right_fixture_window_01` class=`uppercut_right` runner-up=`hook_right/hook_right_hook_right_fixture_window_01 0.865` margin=`0.068` backend=`prototype_matcher`
- `hook_left` at `3179ms` score=`0.723` prototype=`hook_left_hook_left_fixture_window_03` class=`hook_left` runner-up=`straight_left/straight_left_straight_left_fixture_window_03 0.634` margin=`0.089` backend=`prototype_matcher`
- `uppercut_right` at `3481ms` score=`0.856` prototype=`uppercut_right_uppercut_right_fixture_window_02` class=`uppercut_right` runner-up=`hook_right/hook_right_hook_right_fixture_window_01 0.793` margin=`0.062` backend=`prototype_matcher`
- `uppercut_right` at `3790ms` score=`0.919` prototype=`uppercut_right_uppercut_right_fixture_window_01` class=`uppercut_right` runner-up=`straight_right/straight_right_straight_right_fixture_window_01 0.871` margin=`0.049` backend=`prototype_matcher`
- `uppercut_right` at `4090ms` score=`0.931` prototype=`uppercut_right_uppercut_right_fixture_window_01` class=`uppercut_right` runner-up=`straight_right/straight_right_straight_right_fixture_window_01 0.861` margin=`0.069` backend=`prototype_matcher`
- `hook_left` at `4411ms` score=`0.826` prototype=`hook_left_hook_left_fixture_window_04` class=`hook_left` runner-up=`straight_left/straight_left_straight_left_fixture_window_03 0.791` margin=`0.035` backend=`prototype_matcher`
- `hook_left` at `4727ms` score=`0.847` prototype=`hook_left_hook_left_fixture_window_03` class=`hook_left` runner-up=`straight_left/straight_left_straight_left_fixture_window_03 0.765` margin=`0.082` backend=`prototype_matcher`
- `hook_left` at `5021ms` score=`0.876` prototype=`hook_left_hook_left_fixture_window_01` class=`hook_left` runner-up=`straight_left/straight_left_straight_left_fixture_window_03 0.840` margin=`0.036` backend=`prototype_matcher`
- `hook_right` at `5323ms` score=`0.919` prototype=`hook_right_hook_right_fixture_window_01` class=`hook_right` runner-up=`uppercut_right/uppercut_right_uppercut_right_fixture_window_04 0.904` margin=`0.015` backend=`prototype_matcher`
- `uppercut_right` at `5643ms` score=`0.924` prototype=`uppercut_right_uppercut_right_fixture_window_03` class=`uppercut_right` runner-up=`hook_right/hook_right_hook_right_fixture_window_01 0.859` margin=`0.064` backend=`prototype_matcher`
- `hook_left` at `6065ms` score=`0.704` prototype=`hook_left_hook_left_fixture_window_03` class=`hook_left` runner-up=`straight_left/straight_left_straight_left_fixture_window_03 0.577` margin=`0.127` backend=`prototype_matcher`
- `hook_left` at `6342ms` score=`0.829` prototype=`hook_left_hook_left_fixture_window_02` class=`hook_left` runner-up=`straight_left/straight_left_straight_left_fixture_window_04 0.697` margin=`0.133` backend=`prototype_matcher`
- `uppercut_right` at `6637ms` score=`0.881` prototype=`uppercut_right_uppercut_right_fixture_window_01` class=`uppercut_right` runner-up=`straight_left/straight_left_straight_left_fixture_window_01 0.846` margin=`0.035` backend=`prototype_matcher`
- `uppercut_right` at `7082ms` score=`0.932` prototype=`uppercut_right_uppercut_right_fixture_window_04` class=`uppercut_right` runner-up=`hook_right/hook_right_hook_right_fixture_window_01 0.899` margin=`0.033` backend=`prototype_matcher`
- `uppercut_right` at `7393ms` score=`0.924` prototype=`uppercut_right_uppercut_right_fixture_window_04` class=`uppercut_right` runner-up=`hook_right/hook_right_hook_right_fixture_window_01 0.914` margin=`0.010` backend=`prototype_matcher`
- `uppercut_right` at `7712ms` score=`0.900` prototype=`uppercut_right_uppercut_right_fixture_window_03` class=`uppercut_right` runner-up=`hook_right/hook_right_hook_right_fixture_window_01 0.887` margin=`0.013` backend=`prototype_matcher`
- `hook_left` at `8130ms` score=`0.791` prototype=`hook_left_hook_left_fixture_window_03` class=`hook_left` runner-up=`straight_left/straight_left_straight_left_fixture_window_03 0.619` margin=`0.172` backend=`prototype_matcher`
- `hook_left` at `8411ms` score=`0.749` prototype=`hook_left_hook_left_fixture_window_02` class=`hook_left` runner-up=`hook_right/hook_right_hook_right_fixture_window_01 0.739` margin=`0.010` backend=`prototype_matcher`
- `punch_right` at `8709ms` score=`0.897` prototype=`straight_right_straight_right_fixture_window_01` class=`straight_right` runner-up=`uppercut_right/uppercut_right_uppercut_right_fixture_window_01 0.869` margin=`0.028` backend=`prototype_matcher`
- `uppercut_right` at `9014ms` score=`0.985` prototype=`uppercut_right_uppercut_right_fixture_window_01` class=`uppercut_right` runner-up=`hook_right/hook_right_hook_right_fixture_window_01 0.851` margin=`0.134` backend=`prototype_matcher`
- `uppercut_right` at `9316ms` score=`0.933` prototype=`uppercut_right_uppercut_right_fixture_window_01` class=`uppercut_right` runner-up=`hook_right/hook_right_hook_right_fixture_window_01 0.861` margin=`0.072` backend=`prototype_matcher`
- `hook_left` at `9932ms` score=`0.723` prototype=`hook_left_hook_left_fixture_window_03` class=`hook_left` runner-up=`straight_left/straight_left_straight_left_fixture_window_03 0.634` margin=`0.089` backend=`prototype_matcher`

### negative control - running in place

- Fixture: `.testbed/assets/fixtures/boxing/run_in_place/boxing_guard->run_in_place_repeat_01_take_01.yaml`
- Source: `.testbed/assets/fixtures/boxing/run_in_place/boxing_guard->run_in_place_repeat_01_take_01.mp4`
- Expected event: `None`
- Expected class: `None`
- Attack events emitted: **30**
- Peak snapshot: hook_left via hook_left_hook_left_fixture_window_01 score=0.907 runner-up=straight_left/straight_left_straight_left_fixture_window_03 0.850 margin=0.058
- Strongest wrong emit: `hook_left` hook_left via hook_left_hook_left_fixture_window_01 score=0.907 runner-up=straight_left/straight_left_straight_left_fixture_window_03 0.850 margin=0.058
- Emitted prototype counts: `hook_left_hook_left_fixture_window_01` x21, `hook_left_hook_left_fixture_window_03` x4, `hook_right_hook_right_fixture_window_03` x2, `straight_left_straight_left_fixture_window_01` x2, `straight_left_straight_left_fixture_window_02` x1
- Best-snapshot prototype counts: `hook_left_hook_left_fixture_window_01` x65, `hook_left_hook_left_fixture_window_03` x9, `hook_right_hook_right_fixture_window_03` x4, `straight_left_straight_left_fixture_window_01` x4, `straight_left_straight_left_fixture_window_02` x3
- negative control still emitted attack events: punch_left, punch_left, hook_left, hook_left, hook_left, hook_left, hook_left, hook_left, hook_left, hook_left, hook_left, hook_left, hook_left, hook_left, hook_right, hook_right, punch_left, hook_left, hook_left, hook_left, hook_left, hook_left, hook_left, hook_left, hook_left, hook_left, hook_left, hook_left, hook_left, hook_left
- peak winner hook_left via hook_left_hook_left_fixture_window_01 scored 0.907; runner-up straight_left via straight_left_straight_left_fixture_window_03 scored 0.850 (margin 0.058)
- strongest wrong emit was hook_left via hook_left_hook_left_fixture_window_01 at 0.907 over runner-up straight_left_straight_left_fixture_window_03 at 0.850 (margin 0.058)
- latest matcher reason emit_cooldown_active

Emitted attack events:
- `punch_left` at `1081ms` score=`0.866` prototype=`straight_left_straight_left_fixture_window_01` class=`straight_left` runner-up=`uppercut_right/uppercut_right_uppercut_right_fixture_window_03 0.807` margin=`0.058` backend=`prototype_matcher`
- `punch_left` at `1342ms` score=`0.823` prototype=`straight_left_straight_left_fixture_window_02` class=`straight_left` runner-up=`hook_left/hook_left_hook_left_fixture_window_01 0.793` margin=`0.030` backend=`prototype_matcher`
- `hook_left` at `1641ms` score=`0.789` prototype=`hook_left_hook_left_fixture_window_03` class=`hook_left` runner-up=`straight_left/straight_left_straight_left_fixture_window_03 0.732` margin=`0.057` backend=`prototype_matcher`
- `hook_left` at `1946ms` score=`0.820` prototype=`hook_left_hook_left_fixture_window_03` class=`hook_left` runner-up=`straight_left/straight_left_straight_left_fixture_window_03 0.752` margin=`0.068` backend=`prototype_matcher`
- `hook_left` at `2256ms` score=`0.863` prototype=`hook_left_hook_left_fixture_window_01` class=`hook_left` runner-up=`straight_left/straight_left_straight_left_fixture_window_03 0.808` margin=`0.056` backend=`prototype_matcher`
- `hook_left` at `2556ms` score=`0.875` prototype=`hook_left_hook_left_fixture_window_01` class=`hook_left` runner-up=`straight_left/straight_left_straight_left_fixture_window_03 0.823` margin=`0.051` backend=`prototype_matcher`
- `hook_left` at `2865ms` score=`0.884` prototype=`hook_left_hook_left_fixture_window_01` class=`hook_left` runner-up=`straight_left/straight_left_straight_left_fixture_window_03 0.819` margin=`0.066` backend=`prototype_matcher`
- `hook_left` at `3165ms` score=`0.873` prototype=`hook_left_hook_left_fixture_window_01` class=`hook_left` runner-up=`straight_left/straight_left_straight_left_fixture_window_03 0.812` margin=`0.061` backend=`prototype_matcher`
- `hook_left` at `3471ms` score=`0.907` prototype=`hook_left_hook_left_fixture_window_01` class=`hook_left` runner-up=`straight_left/straight_left_straight_left_fixture_window_03 0.850` margin=`0.058` backend=`prototype_matcher`
- `hook_left` at `3783ms` score=`0.888` prototype=`hook_left_hook_left_fixture_window_01` class=`hook_left` runner-up=`straight_left/straight_left_straight_left_fixture_window_03 0.831` margin=`0.058` backend=`prototype_matcher`
- `hook_left` at `4078ms` score=`0.878` prototype=`hook_left_hook_left_fixture_window_01` class=`hook_left` runner-up=`straight_left/straight_left_straight_left_fixture_window_03 0.812` margin=`0.067` backend=`prototype_matcher`
- `hook_left` at `4386ms` score=`0.845` prototype=`hook_left_hook_left_fixture_window_01` class=`hook_left` runner-up=`straight_left/straight_left_straight_left_fixture_window_03 0.802` margin=`0.043` backend=`prototype_matcher`
- `hook_left` at `4678ms` score=`0.840` prototype=`hook_left_hook_left_fixture_window_01` class=`hook_left` runner-up=`straight_left/straight_left_straight_left_fixture_window_03 0.796` margin=`0.044` backend=`prototype_matcher`
- `hook_left` at `4974ms` score=`0.889` prototype=`hook_left_hook_left_fixture_window_01` class=`hook_left` runner-up=`straight_left/straight_left_straight_left_fixture_window_03 0.828` margin=`0.061` backend=`prototype_matcher`
- `hook_right` at `5289ms` score=`0.888` prototype=`hook_right_hook_right_fixture_window_03` class=`hook_right` runner-up=`uppercut_right/uppercut_right_uppercut_right_fixture_window_04 0.829` margin=`0.059` backend=`prototype_matcher`
- `hook_right` at `5593ms` score=`0.853` prototype=`hook_right_hook_right_fixture_window_03` class=`hook_right` runner-up=`straight_left/straight_left_straight_left_fixture_window_04 0.851` margin=`0.002` backend=`prototype_matcher`
- `punch_left` at `5899ms` score=`0.886` prototype=`straight_left_straight_left_fixture_window_01` class=`straight_left` runner-up=`hook_right/hook_right_hook_right_fixture_window_03 0.838` margin=`0.049` backend=`prototype_matcher`
- `hook_left` at `6206ms` score=`0.839` prototype=`hook_left_hook_left_fixture_window_01` class=`hook_left` runner-up=`straight_left/straight_left_straight_left_fixture_window_03 0.831` margin=`0.008` backend=`prototype_matcher`
- `hook_left` at `6507ms` score=`0.756` prototype=`hook_left_hook_left_fixture_window_03` class=`hook_left` runner-up=`straight_left/straight_left_straight_left_fixture_window_02 0.703` margin=`0.054` backend=`prototype_matcher`
- `hook_left` at `6818ms` score=`0.798` prototype=`hook_left_hook_left_fixture_window_03` class=`hook_left` runner-up=`straight_left/straight_left_straight_left_fixture_window_03 0.748` margin=`0.051` backend=`prototype_matcher`
- `hook_left` at `7125ms` score=`0.848` prototype=`hook_left_hook_left_fixture_window_01` class=`hook_left` runner-up=`straight_left/straight_left_straight_left_fixture_window_03 0.794` margin=`0.054` backend=`prototype_matcher`
- `hook_left` at `7428ms` score=`0.868` prototype=`hook_left_hook_left_fixture_window_01` class=`hook_left` runner-up=`straight_left/straight_left_straight_left_fixture_window_03 0.812` margin=`0.056` backend=`prototype_matcher`
- `hook_left` at `7737ms` score=`0.875` prototype=`hook_left_hook_left_fixture_window_01` class=`hook_left` runner-up=`straight_left/straight_left_straight_left_fixture_window_03 0.805` margin=`0.070` backend=`prototype_matcher`
- `hook_left` at `8040ms` score=`0.847` prototype=`hook_left_hook_left_fixture_window_01` class=`hook_left` runner-up=`straight_left/straight_left_straight_left_fixture_window_03 0.815` margin=`0.032` backend=`prototype_matcher`
- `hook_left` at `8347ms` score=`0.883` prototype=`hook_left_hook_left_fixture_window_01` class=`hook_left` runner-up=`straight_left/straight_left_straight_left_fixture_window_03 0.805` margin=`0.078` backend=`prototype_matcher`
- `hook_left` at `8651ms` score=`0.895` prototype=`hook_left_hook_left_fixture_window_01` class=`hook_left` runner-up=`straight_left/straight_left_straight_left_fixture_window_03 0.831` margin=`0.064` backend=`prototype_matcher`
- `hook_left` at `8962ms` score=`0.874` prototype=`hook_left_hook_left_fixture_window_01` class=`hook_left` runner-up=`straight_left/straight_left_straight_left_fixture_window_03 0.818` margin=`0.056` backend=`prototype_matcher`
- `hook_left` at `9270ms` score=`0.821` prototype=`hook_left_hook_left_fixture_window_01` class=`hook_left` runner-up=`straight_left/straight_left_straight_left_fixture_window_03 0.800` margin=`0.021` backend=`prototype_matcher`
- `hook_left` at `9576ms` score=`0.834` prototype=`hook_left_hook_left_fixture_window_01` class=`hook_left` runner-up=`straight_left/straight_left_straight_left_fixture_window_03 0.786` margin=`0.048` backend=`prototype_matcher`
- `hook_left` at `9867ms` score=`0.885` prototype=`hook_left_hook_left_fixture_window_01` class=`hook_left` runner-up=`straight_left/straight_left_straight_left_fixture_window_03 0.826` margin=`0.059` backend=`prototype_matcher`
