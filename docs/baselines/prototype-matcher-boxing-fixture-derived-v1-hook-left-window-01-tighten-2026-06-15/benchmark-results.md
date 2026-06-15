# Prototype Matcher Fixture Benchmark

- Benchmark ID: `prototype_matcher_boxing_fixture_derived_v1`
- Library ID: `boxing_side_aware_fixture_derived_v1`
- Profile: `boxing`
- Generated At: `2026-06-15T15:45:08-04:00`
- Runner: `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/scripts/run_prototype_matcher_fixture_benchmark.py`

## Aggregate

- Fixture count: **7**
- Negative controls clean: **0 / 1**
- Negative-control false-positive classes: `straight_left` x13, `hook_left` x4, `hook_right` x3
- Negative-control false-positive prototypes: `boxing_straight_left_window_04` x8, `boxing_straight_left_window_03` x5, `boxing_hook_left_window_04` x3, `boxing_hook_right_window_04` x3, `boxing_hook_left_window_01` x1

## Per Fixture

### straight left

- Fixture: `.testbed/assets/fixtures/boxing/straight_left/boxing_guard->straight_left_repeat_04_take_01.yaml`
- Source: `.testbed/assets/fixtures/boxing/straight_left/boxing_guard->straight_left_repeat_04_take_01.mp4`
- Expected event: `punch_left`
- Expected class: `straight_left`
- Attack events emitted: **20**
- Peak snapshot: straight_left via boxing_straight_left_window_02 score=1.000 runner-up=uppercut_right/boxing_uppercut_right_window_01 0.823 margin=0.177
- Strongest expected emit: `punch_left` straight_left via boxing_straight_left_window_03 score=0.967 runner-up=hook_right/boxing_hook_right_window_01 0.927 margin=0.041
- Strongest wrong emit: `uppercut_left` uppercut_left via boxing_uppercut_left_window_04 score=0.919 runner-up=uppercut_right/boxing_uppercut_right_window_01 0.875 margin=0.044
- Emitted prototype counts: `boxing_hook_right_window_01` x6, `boxing_straight_left_window_01` x3, `boxing_uppercut_left_window_04` x3, `boxing_uppercut_right_window_01` x3, `boxing_straight_left_window_03` x2
- Best-snapshot prototype counts: `boxing_hook_right_window_01` x17, `boxing_uppercut_left_window_04` x9, `boxing_straight_left_window_01` x8, `boxing_uppercut_right_window_01` x8, `boxing_straight_left_window_03` x6
- emitted expected punch_left 8 time(s)
- also emitted other attack events: uppercut_left, uppercut_right, uppercut_right, uppercut_right, hook_right, hook_right, hook_right, hook_right, hook_right, hook_right, uppercut_left, uppercut_left
- peak expected-class score 1.000
- peak winner straight_left via boxing_straight_left_window_02 scored 1.000; runner-up uppercut_right via boxing_uppercut_right_window_01 scored 0.823 (margin 0.177)
- strongest expected emit used boxing_straight_left_window_03 at 0.967 over runner-up boxing_hook_right_window_01 at 0.927 (margin 0.041)
- strongest wrong emit was uppercut_left via boxing_uppercut_left_window_04 at 0.919 over runner-up boxing_uppercut_right_window_01 at 0.875 (margin 0.044)
- latest matcher reason emit_cooldown_active

Emitted attack events:
- `uppercut_left` at `1533ms` score=`0.919` prototype=`boxing_uppercut_left_window_04` class=`uppercut_left` runner-up=`uppercut_right/boxing_uppercut_right_window_01 0.875` margin=`0.044` backend=`prototype_matcher`
- `uppercut_right` at `1919ms` score=`0.894` prototype=`boxing_uppercut_right_window_01` class=`uppercut_right` runner-up=`uppercut_left/boxing_uppercut_left_window_04 0.872` margin=`0.022` backend=`prototype_matcher`
- `punch_left` at `2563ms` score=`0.834` prototype=`boxing_straight_left_window_02` class=`straight_left` runner-up=`hook_right/boxing_hook_right_window_01 0.772` margin=`0.062` backend=`prototype_matcher`
- `punch_left` at `3118ms` score=`0.795` prototype=`boxing_straight_left_window_01` class=`straight_left` runner-up=`hook_right/boxing_hook_right_window_01 0.790` margin=`0.004` backend=`prototype_matcher`
- `punch_left` at `3646ms` score=`0.935` prototype=`boxing_straight_left_window_01` class=`straight_left` runner-up=`hook_right/boxing_hook_right_window_01 0.897` margin=`0.038` backend=`prototype_matcher`
- `uppercut_right` at `4173ms` score=`0.901` prototype=`boxing_uppercut_right_window_01` class=`uppercut_right` runner-up=`straight_left/boxing_straight_left_window_03 0.897` margin=`0.003` backend=`prototype_matcher`
- `uppercut_right` at `4691ms` score=`0.815` prototype=`boxing_uppercut_right_window_01` class=`uppercut_right` runner-up=`hook_right/boxing_hook_right_window_01 0.798` margin=`0.018` backend=`prototype_matcher`
- `punch_left` at `5231ms` score=`0.871` prototype=`boxing_straight_left_window_01` class=`straight_left` runner-up=`hook_right/boxing_hook_right_window_01 0.836` margin=`0.035` backend=`prototype_matcher`
- `punch_left` at `5775ms` score=`0.967` prototype=`boxing_straight_left_window_03` class=`straight_left` runner-up=`hook_right/boxing_hook_right_window_01 0.927` margin=`0.041` backend=`prototype_matcher`
- `hook_right` at `6325ms` score=`0.884` prototype=`boxing_hook_right_window_01` class=`hook_right` runner-up=`uppercut_right/boxing_uppercut_right_window_01 0.817` margin=`0.067` backend=`prototype_matcher`
- `hook_right` at `6898ms` score=`0.852` prototype=`boxing_hook_right_window_01` class=`hook_right` runner-up=`uppercut_right/boxing_uppercut_right_window_01 0.817` margin=`0.035` backend=`prototype_matcher`
- `punch_left` at `7416ms` score=`0.888` prototype=`boxing_straight_left_window_03` class=`straight_left` runner-up=`uppercut_left/boxing_uppercut_left_window_01 0.852` margin=`0.035` backend=`prototype_matcher`
- `punch_left` at `7966ms` score=`0.934` prototype=`boxing_straight_left_window_04` class=`straight_left` runner-up=`hook_right/boxing_hook_right_window_01 0.901` margin=`0.033` backend=`prototype_matcher`
- `punch_left` at `8438ms` score=`0.906` prototype=`boxing_straight_left_window_04` class=`straight_left` runner-up=`hook_right/boxing_hook_right_window_04 0.891` margin=`0.015` backend=`prototype_matcher`
- `hook_right` at `8891ms` score=`0.844` prototype=`boxing_hook_right_window_01` class=`hook_right` runner-up=`uppercut_right/boxing_uppercut_right_window_01 0.838` margin=`0.006` backend=`prototype_matcher`
- `hook_right` at `9330ms` score=`0.861` prototype=`boxing_hook_right_window_01` class=`hook_right` runner-up=`uppercut_right/boxing_uppercut_right_window_01 0.827` margin=`0.034` backend=`prototype_matcher`
- `hook_right` at `9763ms` score=`0.914` prototype=`boxing_hook_right_window_01` class=`hook_right` runner-up=`straight_left/boxing_straight_left_window_03 0.891` margin=`0.023` backend=`prototype_matcher`
- `hook_right` at `10178ms` score=`0.905` prototype=`boxing_hook_right_window_01` class=`hook_right` runner-up=`straight_left/boxing_straight_left_window_01 0.900` margin=`0.005` backend=`prototype_matcher`
- `uppercut_left` at `10511ms` score=`0.896` prototype=`boxing_uppercut_left_window_04` class=`uppercut_left` runner-up=`uppercut_right/boxing_uppercut_right_window_01 0.870` margin=`0.026` backend=`prototype_matcher`
- `uppercut_left` at `10966ms` score=`0.898` prototype=`boxing_uppercut_left_window_04` class=`uppercut_left` runner-up=`uppercut_right/boxing_uppercut_right_window_01 0.867` margin=`0.030` backend=`prototype_matcher`

### straight right

- Fixture: `.testbed/assets/fixtures/boxing/straight_right/boxing_guard->straight_right_repeat_04_take_01.yaml`
- Source: `.testbed/assets/fixtures/boxing/straight_right/boxing_guard->straight_right_repeat_04_take_01.mp4`
- Expected event: `punch_right`
- Expected class: `straight_right`
- Attack events emitted: **29**
- Peak snapshot: straight_right via boxing_straight_right_window_02 score=1.000 runner-up=uppercut_left/boxing_uppercut_left_window_04 0.859 margin=0.141
- Strongest expected emit: `punch_right` straight_right via boxing_straight_right_window_02 score=1.000 runner-up=uppercut_left/boxing_uppercut_left_window_04 0.859 margin=0.141
- Strongest wrong emit: `uppercut_left` uppercut_left via boxing_uppercut_left_window_04 score=0.846 runner-up=straight_right/boxing_straight_right_window_04 0.820 margin=0.026
- Emitted prototype counts: `boxing_straight_right_window_03` x11, `boxing_uppercut_left_window_04` x8, `boxing_straight_right_window_01` x5, `boxing_straight_right_window_02` x2, `boxing_straight_right_window_04` x2
- Best-snapshot prototype counts: `boxing_straight_right_window_03` x20, `boxing_uppercut_left_window_04` x17, `boxing_straight_right_window_01` x12, `boxing_straight_right_window_02` x4, `boxing_straight_right_window_04` x3
- emitted expected punch_right 20 time(s)
- also emitted other attack events: uppercut_left, uppercut_left, uppercut_left, uppercut_left, uppercut_left, uppercut_left, uppercut_left, uppercut_left, uppercut_left
- peak expected-class score 1.000
- peak winner straight_right via boxing_straight_right_window_02 scored 1.000; runner-up uppercut_left via boxing_uppercut_left_window_04 scored 0.859 (margin 0.141)
- strongest expected emit used boxing_straight_right_window_02 at 1.000 over runner-up boxing_uppercut_left_window_04 at 0.859 (margin 0.141)
- strongest wrong emit was uppercut_left via boxing_uppercut_left_window_04 at 0.846 over runner-up boxing_straight_right_window_04 at 0.820 (margin 0.026)
- latest matcher reason window_not_full

Emitted attack events:
- `punch_right` at `1501ms` score=`0.841` prototype=`boxing_straight_right_window_01` class=`straight_right` runner-up=`uppercut_left/boxing_uppercut_left_window_04 0.807` margin=`0.034` backend=`prototype_matcher`
- `punch_right` at `1675ms` score=`0.890` prototype=`boxing_straight_right_window_03` class=`straight_right` runner-up=`uppercut_right/boxing_uppercut_right_window_01 0.814` margin=`0.076` backend=`prototype_matcher`
- `punch_right` at `2000ms` score=`0.929` prototype=`boxing_straight_right_window_01` class=`straight_right` runner-up=`uppercut_right/boxing_uppercut_right_window_01 0.850` margin=`0.078` backend=`prototype_matcher`
- `punch_right` at `2283ms` score=`0.966` prototype=`boxing_straight_right_window_01` class=`straight_right` runner-up=`uppercut_right/boxing_uppercut_right_window_01 0.889` margin=`0.076` backend=`prototype_matcher`
- `uppercut_left` at `2575ms` score=`0.746` prototype=`boxing_uppercut_left_window_04` class=`uppercut_left` runner-up=`straight_left/boxing_straight_left_window_01 0.696` margin=`0.050` backend=`prototype_matcher`
- `uppercut_left` at `2938ms` score=`0.846` prototype=`boxing_uppercut_left_window_04` class=`uppercut_left` runner-up=`straight_right/boxing_straight_right_window_04 0.820` margin=`0.026` backend=`prototype_matcher`
- `punch_right` at `3276ms` score=`0.908` prototype=`boxing_straight_right_window_03` class=`straight_right` runner-up=`uppercut_left/boxing_uppercut_left_window_04 0.860` margin=`0.048` backend=`prototype_matcher`
- `punch_right` at `3628ms` score=`1.000` prototype=`boxing_straight_right_window_02` class=`straight_right` runner-up=`uppercut_left/boxing_uppercut_left_window_04 0.859` margin=`0.141` backend=`prototype_matcher`
- `punch_right` at `4049ms` score=`0.902` prototype=`boxing_straight_right_window_02` class=`straight_right` runner-up=`uppercut_left/boxing_uppercut_left_window_04 0.871` margin=`0.031` backend=`prototype_matcher`
- `uppercut_left` at `4445ms` score=`0.815` prototype=`boxing_uppercut_left_window_04` class=`uppercut_left` runner-up=`straight_left/boxing_straight_left_window_01 0.714` margin=`0.101` backend=`prototype_matcher`
- `uppercut_left` at `4820ms` score=`0.734` prototype=`boxing_uppercut_left_window_04` class=`uppercut_left` runner-up=`straight_left/boxing_straight_left_window_01 0.714` margin=`0.021` backend=`prototype_matcher`
- `punch_right` at `5153ms` score=`0.908` prototype=`boxing_straight_right_window_03` class=`straight_right` runner-up=`uppercut_left/boxing_uppercut_left_window_04 0.821` margin=`0.087` backend=`prototype_matcher`
- `punch_right` at `5481ms` score=`0.939` prototype=`boxing_straight_right_window_03` class=`straight_right` runner-up=`uppercut_right/boxing_uppercut_right_window_01 0.875` margin=`0.064` backend=`prototype_matcher`
- `punch_right` at `5814ms` score=`0.924` prototype=`boxing_straight_right_window_03` class=`straight_right` runner-up=`uppercut_right/boxing_uppercut_right_window_01 0.842` margin=`0.082` backend=`prototype_matcher`
- `uppercut_left` at `6160ms` score=`0.833` prototype=`boxing_uppercut_left_window_04` class=`uppercut_left` runner-up=`straight_right/boxing_straight_right_window_03 0.787` margin=`0.046` backend=`prototype_matcher`
- `uppercut_left` at `6433ms` score=`0.751` prototype=`boxing_uppercut_left_window_04` class=`uppercut_left` runner-up=`straight_left/boxing_straight_left_window_01 0.674` margin=`0.077` backend=`prototype_matcher`
- `punch_right` at `6815ms` score=`0.940` prototype=`boxing_straight_right_window_04` class=`straight_right` runner-up=`uppercut_left/boxing_uppercut_left_window_04 0.828` margin=`0.112` backend=`prototype_matcher`
- `punch_right` at `7157ms` score=`0.934` prototype=`boxing_straight_right_window_03` class=`straight_right` runner-up=`uppercut_left/boxing_uppercut_left_window_04 0.825` margin=`0.109` backend=`prototype_matcher`
- `punch_right` at `7495ms` score=`0.939` prototype=`boxing_straight_right_window_03` class=`straight_right` runner-up=`uppercut_left/boxing_uppercut_left_window_04 0.868` margin=`0.071` backend=`prototype_matcher`
- `punch_right` at `7766ms` score=`0.938` prototype=`boxing_straight_right_window_03` class=`straight_right` runner-up=`uppercut_left/boxing_uppercut_left_window_04 0.866` margin=`0.072` backend=`prototype_matcher`
- `punch_right` at `8225ms` score=`0.938` prototype=`boxing_straight_right_window_03` class=`straight_right` runner-up=`uppercut_right/boxing_uppercut_right_window_01 0.832` margin=`0.106` backend=`prototype_matcher`
- `punch_right` at `8469ms` score=`0.873` prototype=`boxing_straight_right_window_03` class=`straight_right` runner-up=`uppercut_left/boxing_uppercut_left_window_04 0.799` margin=`0.073` backend=`prototype_matcher`
- `uppercut_left` at `8751ms` score=`0.704` prototype=`boxing_uppercut_left_window_02` class=`uppercut_left` runner-up=`straight_left/boxing_straight_left_window_01 0.590` margin=`0.113` backend=`prototype_matcher`
- `punch_right` at `9048ms` score=`0.858` prototype=`boxing_straight_right_window_04` class=`straight_right` runner-up=`uppercut_left/boxing_uppercut_left_window_04 0.790` margin=`0.068` backend=`prototype_matcher`
- `punch_right` at `9368ms` score=`0.867` prototype=`boxing_straight_right_window_01` class=`straight_right` runner-up=`uppercut_right/boxing_uppercut_right_window_01 0.808` margin=`0.059` backend=`prototype_matcher`
- `punch_right` at `9668ms` score=`0.910` prototype=`boxing_straight_right_window_03` class=`straight_right` runner-up=`uppercut_right/boxing_uppercut_right_window_01 0.831` margin=`0.080` backend=`prototype_matcher`
- `punch_right` at `10041ms` score=`0.958` prototype=`boxing_straight_right_window_01` class=`straight_right` runner-up=`uppercut_right/boxing_uppercut_right_window_01 0.875` margin=`0.083` backend=`prototype_matcher`
- `uppercut_left` at `10327ms` score=`0.795` prototype=`boxing_uppercut_left_window_04` class=`uppercut_left` runner-up=`straight_left/boxing_straight_left_window_01 0.734` margin=`0.061` backend=`prototype_matcher`
- `uppercut_left` at `10679ms` score=`0.758` prototype=`boxing_uppercut_left_window_04` class=`uppercut_left` runner-up=`straight_left/boxing_straight_left_window_01 0.710` margin=`0.048` backend=`prototype_matcher`

### hook left

- Fixture: `.testbed/assets/fixtures/boxing/hook_left/boxing_guard->hook_left_repeat_04_take_01.yaml`
- Source: `.testbed/assets/fixtures/boxing/hook_left/boxing_guard->hook_left_repeat_04_take_01.mp4`
- Expected event: `hook_left`
- Expected class: `hook_left`
- Attack events emitted: **21**
- Peak snapshot: hook_left via boxing_hook_left_window_01 score=1.000 runner-up=hook_right/boxing_hook_right_window_04 0.880 margin=0.120
- Strongest expected emit: `hook_left` hook_left via boxing_hook_left_window_04 score=0.974 runner-up=hook_right/boxing_hook_right_window_04 0.837 margin=0.137
- Strongest wrong emit: `uppercut_right` uppercut_right via boxing_uppercut_right_window_01 score=0.916 runner-up=uppercut_left/boxing_uppercut_left_window_01 0.897 margin=0.019
- Emitted prototype counts: `boxing_hook_right_window_01` x4, `boxing_hook_right_window_04` x4, `boxing_hook_left_window_04` x3, `boxing_hook_left_window_01` x2, `boxing_hook_left_window_03` x2
- Best-snapshot prototype counts: `boxing_hook_right_window_04` x15, `boxing_hook_right_window_01` x11, `boxing_hook_left_window_01` x8, `boxing_hook_left_window_04` x7, `boxing_hook_left_window_03` x6
- emitted expected hook_left 8 time(s)
- also emitted other attack events: uppercut_right, uppercut_left, punch_left, punch_left, hook_right, hook_right, punch_left, hook_right, hook_right, hook_right, hook_right, hook_right, hook_right
- peak expected-class score 1.000
- peak winner hook_left via boxing_hook_left_window_01 scored 1.000; runner-up hook_right via boxing_hook_right_window_04 scored 0.880 (margin 0.120)
- strongest expected emit used boxing_hook_left_window_04 at 0.974 over runner-up boxing_hook_right_window_04 at 0.837 (margin 0.137)
- strongest wrong emit was uppercut_right via boxing_uppercut_right_window_01 at 0.916 over runner-up boxing_uppercut_left_window_01 at 0.897 (margin 0.019)
- latest matcher reason emitted

Emitted attack events:
- `uppercut_right` at `1454ms` score=`0.916` prototype=`boxing_uppercut_right_window_01` class=`uppercut_right` runner-up=`uppercut_left/boxing_uppercut_left_window_01 0.897` margin=`0.019` backend=`prototype_matcher`
- `uppercut_left` at `1747ms` score=`0.904` prototype=`boxing_uppercut_left_window_01` class=`uppercut_left` runner-up=`hook_right/boxing_hook_right_window_01 0.886` margin=`0.018` backend=`prototype_matcher`
- `hook_left` at `2177ms` score=`0.743` prototype=`boxing_hook_left_window_02` class=`hook_left` runner-up=`hook_right/boxing_hook_right_window_04 0.739` margin=`0.004` backend=`prototype_matcher`
- `hook_left` at `2613ms` score=`0.796` prototype=`boxing_hook_left_window_04` class=`hook_left` runner-up=`hook_right/boxing_hook_right_window_04 0.770` margin=`0.025` backend=`prototype_matcher`
- `hook_left` at `3144ms` score=`0.916` prototype=`boxing_hook_left_window_01` class=`hook_left` runner-up=`hook_right/boxing_hook_right_window_01 0.902` margin=`0.014` backend=`prototype_matcher`
- `punch_left` at `3564ms` score=`0.853` prototype=`boxing_straight_left_window_04` class=`straight_left` runner-up=`hook_left/boxing_hook_left_window_01 0.842` margin=`0.011` backend=`prototype_matcher`
- `punch_left` at `4002ms` score=`0.865` prototype=`boxing_straight_left_window_04` class=`straight_left` runner-up=`hook_left/boxing_hook_left_window_01 0.800` margin=`0.065` backend=`prototype_matcher`
- `hook_right` at `4543ms` score=`0.788` prototype=`boxing_hook_right_window_04` class=`hook_right` runner-up=`uppercut_right/boxing_uppercut_right_window_04 0.746` margin=`0.042` backend=`prototype_matcher`
- `hook_right` at `5172ms` score=`0.733` prototype=`boxing_hook_right_window_01` class=`hook_right` runner-up=`uppercut_right/boxing_uppercut_right_window_04 0.653` margin=`0.080` backend=`prototype_matcher`
- `hook_left` at `5741ms` score=`0.898` prototype=`boxing_hook_left_window_04` class=`hook_left` runner-up=`hook_right/boxing_hook_right_window_04 0.829` margin=`0.068` backend=`prototype_matcher`
- `punch_left` at `6206ms` score=`0.848` prototype=`boxing_straight_left_window_03` class=`straight_left` runner-up=`hook_left/boxing_hook_left_window_01 0.817` margin=`0.031` backend=`prototype_matcher`
- `hook_left` at `6724ms` score=`0.869` prototype=`boxing_hook_left_window_03` class=`hook_left` runner-up=`straight_left/boxing_straight_left_window_04 0.800` margin=`0.069` backend=`prototype_matcher`
- `hook_right` at `7218ms` score=`0.831` prototype=`boxing_hook_right_window_04` class=`hook_right` runner-up=`uppercut_right/boxing_uppercut_right_window_03 0.757` margin=`0.074` backend=`prototype_matcher`
- `hook_right` at `7721ms` score=`0.755` prototype=`boxing_hook_right_window_01` class=`hook_right` runner-up=`uppercut_right/boxing_uppercut_right_window_04 0.670` margin=`0.084` backend=`prototype_matcher`
- `hook_left` at `8200ms` score=`0.974` prototype=`boxing_hook_left_window_04` class=`hook_left` runner-up=`hook_right/boxing_hook_right_window_04 0.837` margin=`0.137` backend=`prototype_matcher`
- `hook_left` at `8699ms` score=`0.865` prototype=`boxing_hook_left_window_01` class=`hook_left` runner-up=`straight_left/boxing_straight_left_window_04 0.818` margin=`0.047` backend=`prototype_matcher`
- `hook_left` at `9170ms` score=`0.841` prototype=`boxing_hook_left_window_03` class=`hook_left` runner-up=`hook_right/boxing_hook_right_window_04 0.776` margin=`0.064` backend=`prototype_matcher`
- `hook_right` at `9557ms` score=`0.791` prototype=`boxing_hook_right_window_04` class=`hook_right` runner-up=`uppercut_right/boxing_uppercut_right_window_03 0.769` margin=`0.022` backend=`prototype_matcher`
- `hook_right` at `9985ms` score=`0.778` prototype=`boxing_hook_right_window_01` class=`hook_right` runner-up=`uppercut_right/boxing_uppercut_right_window_04 0.714` margin=`0.064` backend=`prototype_matcher`
- `hook_right` at `10391ms` score=`0.915` prototype=`boxing_hook_right_window_04` class=`hook_right` runner-up=`straight_left/boxing_straight_left_window_04 0.888` margin=`0.027` backend=`prototype_matcher`
- `hook_right` at `10799ms` score=`0.871` prototype=`boxing_hook_right_window_01` class=`hook_right` runner-up=`uppercut_left/boxing_uppercut_left_window_01 0.870` margin=`0.002` backend=`prototype_matcher`

### hook right

- Fixture: `.testbed/assets/fixtures/boxing/hook_right/boxing_guard->hook_right_repeat_04_take_01.yaml`
- Source: `.testbed/assets/fixtures/boxing/hook_right/boxing_guard->hook_right_repeat_04_take_01.mp4`
- Expected event: `hook_right`
- Expected class: `hook_right`
- Attack events emitted: **21**
- Peak snapshot: hook_right via boxing_hook_right_window_03 score=1.000 runner-up=straight_left/boxing_straight_left_window_04 0.767 margin=0.233
- Strongest expected emit: `hook_right` hook_right via boxing_hook_right_window_03 score=1.000 runner-up=straight_left/boxing_straight_left_window_04 0.767 margin=0.233
- Strongest wrong emit: `punch_left` straight_left via boxing_straight_left_window_04 score=0.810 runner-up=uppercut_left/boxing_uppercut_left_window_01 0.798 margin=0.011
- Emitted prototype counts: `boxing_hook_right_window_01` x6, `boxing_hook_right_window_02` x4, `boxing_hook_right_window_04` x4, `boxing_straight_left_window_04` x4, `boxing_straight_left_window_03` x2
- Best-snapshot prototype counts: `boxing_hook_right_window_01` x16, `boxing_hook_right_window_02` x13, `boxing_hook_right_window_04` x11, `boxing_straight_left_window_04` x9, `boxing_straight_left_window_03` x8
- emitted expected hook_right 15 time(s)
- also emitted other attack events: punch_left, punch_left, punch_left, punch_left, punch_left, punch_left
- peak expected-class score 1.000
- peak winner hook_right via boxing_hook_right_window_03 scored 1.000; runner-up straight_left via boxing_straight_left_window_04 scored 0.767 (margin 0.233)
- strongest expected emit used boxing_hook_right_window_03 at 1.000 over runner-up boxing_straight_left_window_04 at 0.767 (margin 0.233)
- strongest wrong emit was punch_left via boxing_straight_left_window_04 at 0.810 over runner-up boxing_uppercut_left_window_01 at 0.798 (margin 0.011)
- latest matcher reason emitted

Emitted attack events:
- `hook_right` at `1454ms` score=`0.917` prototype=`boxing_hook_right_window_01` class=`hook_right` runner-up=`uppercut_left/boxing_uppercut_left_window_01 0.881` margin=`0.036` backend=`prototype_matcher`
- `punch_left` at `1895ms` score=`0.792` prototype=`boxing_straight_left_window_03` class=`straight_left` runner-up=`hook_right/boxing_hook_right_window_03 0.781` margin=`0.011` backend=`prototype_matcher`
- `hook_right` at `2307ms` score=`0.794` prototype=`boxing_hook_right_window_02` class=`hook_right` runner-up=`straight_left/boxing_straight_left_window_04 0.682` margin=`0.112` backend=`prototype_matcher`
- `hook_right` at `2728ms` score=`0.897` prototype=`boxing_hook_right_window_01` class=`hook_right` runner-up=`uppercut_right/boxing_uppercut_right_window_04 0.823` margin=`0.074` backend=`prototype_matcher`
- `hook_right` at `3160ms` score=`0.964` prototype=`boxing_hook_right_window_01` class=`hook_right` runner-up=`uppercut_right/boxing_uppercut_right_window_01 0.876` margin=`0.088` backend=`prototype_matcher`
- `hook_right` at `3655ms` score=`0.936` prototype=`boxing_hook_right_window_01` class=`hook_right` runner-up=`uppercut_left/boxing_uppercut_left_window_01 0.861` margin=`0.075` backend=`prototype_matcher`
- `punch_left` at `4094ms` score=`0.797` prototype=`boxing_straight_left_window_04` class=`straight_left` runner-up=`uppercut_left/boxing_uppercut_left_window_01 0.758` margin=`0.039` backend=`prototype_matcher`
- `hook_right` at `4534ms` score=`0.871` prototype=`boxing_hook_right_window_02` class=`hook_right` runner-up=`hook_left/boxing_hook_left_window_01 0.671` margin=`0.200` backend=`prototype_matcher`
- `punch_left` at `5057ms` score=`0.775` prototype=`boxing_straight_left_window_04` class=`straight_left` runner-up=`hook_left/boxing_hook_left_window_01 0.770` margin=`0.005` backend=`prototype_matcher`
- `hook_right` at `5667ms` score=`0.943` prototype=`boxing_hook_right_window_04` class=`hook_right` runner-up=`straight_left/boxing_straight_left_window_04 0.847` margin=`0.096` backend=`prototype_matcher`
- `hook_right` at `6202ms` score=`0.886` prototype=`boxing_hook_right_window_04` class=`hook_right` runner-up=`straight_left/boxing_straight_left_window_04 0.826` margin=`0.060` backend=`prototype_matcher`
- `hook_right` at `6749ms` score=`1.000` prototype=`boxing_hook_right_window_03` class=`hook_right` runner-up=`straight_left/boxing_straight_left_window_04 0.767` margin=`0.233` backend=`prototype_matcher`
- `hook_right` at `7234ms` score=`0.754` prototype=`boxing_hook_right_window_02` class=`hook_right` runner-up=`straight_left/boxing_straight_left_window_03 0.683` margin=`0.071` backend=`prototype_matcher`
- `punch_left` at `7735ms` score=`0.799` prototype=`boxing_straight_left_window_04` class=`straight_left` runner-up=`hook_right/boxing_hook_right_window_04 0.792` margin=`0.007` backend=`prototype_matcher`
- `hook_right` at `8215ms` score=`0.978` prototype=`boxing_hook_right_window_04` class=`hook_right` runner-up=`uppercut_right/boxing_uppercut_right_window_03 0.840` margin=`0.139` backend=`prototype_matcher`
- `hook_right` at `8723ms` score=`0.937` prototype=`boxing_hook_right_window_01` class=`hook_right` runner-up=`uppercut_right/boxing_uppercut_right_window_01 0.863` margin=`0.075` backend=`prototype_matcher`
- `punch_left` at `9173ms` score=`0.810` prototype=`boxing_straight_left_window_04` class=`straight_left` runner-up=`uppercut_left/boxing_uppercut_left_window_01 0.798` margin=`0.011` backend=`prototype_matcher`
- `hook_right` at `9711ms` score=`0.746` prototype=`boxing_hook_right_window_02` class=`hook_right` runner-up=`straight_left/boxing_straight_left_window_03 0.662` margin=`0.084` backend=`prototype_matcher`
- `punch_left` at `10128ms` score=`0.763` prototype=`boxing_straight_left_window_03` class=`straight_left` runner-up=`hook_left/boxing_hook_left_window_01 0.742` margin=`0.021` backend=`prototype_matcher`
- `hook_right` at `10540ms` score=`0.934` prototype=`boxing_hook_right_window_04` class=`hook_right` runner-up=`uppercut_right/boxing_uppercut_right_window_03 0.881` margin=`0.053` backend=`prototype_matcher`
- `hook_right` at `10957ms` score=`0.928` prototype=`boxing_hook_right_window_01` class=`hook_right` runner-up=`uppercut_left/boxing_uppercut_left_window_01 0.885` margin=`0.043` backend=`prototype_matcher`

### uppercut left

- Fixture: `.testbed/assets/fixtures/boxing/uppercut_left/boxing_guard->uppercut_left_repeat_04_take_01.yaml`
- Source: `.testbed/assets/fixtures/boxing/uppercut_left/boxing_guard->uppercut_left_repeat_04_take_01.mp4`
- Expected event: `uppercut_left`
- Expected class: `uppercut_left`
- Attack events emitted: **20**
- Peak snapshot: uppercut_left via boxing_uppercut_left_window_01 score=0.983 runner-up=uppercut_right/boxing_uppercut_right_window_01 0.910 margin=0.074
- Strongest expected emit: `uppercut_left` uppercut_left via boxing_uppercut_left_window_04 score=0.975 runner-up=uppercut_right/boxing_uppercut_right_window_01 0.914 margin=0.061
- Strongest wrong emit: `uppercut_right` uppercut_right via boxing_uppercut_right_window_01 score=0.948 runner-up=uppercut_left/boxing_uppercut_left_window_04 0.941 margin=0.006
- Emitted prototype counts: `boxing_uppercut_left_window_04` x5, `boxing_hook_right_window_04` x4, `boxing_uppercut_left_window_01` x3, `boxing_uppercut_right_window_01` x3, `boxing_hook_left_window_03` x1
- Best-snapshot prototype counts: `boxing_uppercut_left_window_04` x16, `boxing_hook_right_window_04` x13, `boxing_uppercut_right_window_01` x10, `boxing_uppercut_left_window_01` x8, `boxing_uppercut_left_window_02` x3
- emitted expected uppercut_left 9 time(s)
- also emitted other attack events: hook_right, hook_right, punch_left, uppercut_right, hook_right, uppercut_right, uppercut_right, hook_left, hook_right, uppercut_right, punch_left
- peak expected-class score 0.983
- peak winner uppercut_left via boxing_uppercut_left_window_01 scored 0.983; runner-up uppercut_right via boxing_uppercut_right_window_01 scored 0.910 (margin 0.074)
- strongest expected emit used boxing_uppercut_left_window_04 at 0.975 over runner-up boxing_uppercut_right_window_01 at 0.914 (margin 0.061)
- strongest wrong emit was uppercut_right via boxing_uppercut_right_window_01 at 0.948 over runner-up boxing_uppercut_left_window_04 at 0.941 (margin 0.006)
- latest matcher reason emit_cooldown_active

Emitted attack events:
- `hook_right` at `1507ms` score=`0.786` prototype=`boxing_hook_right_window_04` class=`hook_right` runner-up=`uppercut_right/boxing_uppercut_right_window_04 0.734` margin=`0.052` backend=`prototype_matcher`
- `hook_right` at `1803ms` score=`0.782` prototype=`boxing_hook_right_window_04` class=`hook_right` runner-up=`uppercut_right/boxing_uppercut_right_window_03 0.716` margin=`0.066` backend=`prototype_matcher`
- `uppercut_left` at `2218ms` score=`0.869` prototype=`boxing_uppercut_left_window_04` class=`uppercut_left` runner-up=`hook_right/boxing_hook_right_window_01 0.795` margin=`0.074` backend=`prototype_matcher`
- `uppercut_left` at `2652ms` score=`0.926` prototype=`boxing_uppercut_left_window_01` class=`uppercut_left` runner-up=`hook_right/boxing_hook_right_window_01 0.838` margin=`0.087` backend=`prototype_matcher`
- `uppercut_left` at `3070ms` score=`0.962` prototype=`boxing_uppercut_left_window_01` class=`uppercut_left` runner-up=`uppercut_right/boxing_uppercut_right_window_01 0.913` margin=`0.049` backend=`prototype_matcher`
- `uppercut_left` at `3556ms` score=`0.926` prototype=`boxing_uppercut_left_window_01` class=`uppercut_left` runner-up=`uppercut_right/boxing_uppercut_right_window_01 0.909` margin=`0.017` backend=`prototype_matcher`
- `punch_left` at `3991ms` score=`0.854` prototype=`boxing_straight_left_window_01` class=`straight_left` runner-up=`uppercut_right/boxing_uppercut_right_window_01 0.820` margin=`0.034` backend=`prototype_matcher`
- `uppercut_right` at `4439ms` score=`0.773` prototype=`boxing_uppercut_right_window_03` class=`uppercut_right` runner-up=`hook_right/boxing_hook_right_window_04 0.772` margin=`0.001` backend=`prototype_matcher`
- `hook_right` at `4992ms` score=`0.835` prototype=`boxing_hook_right_window_04` class=`hook_right` runner-up=`uppercut_right/boxing_uppercut_right_window_03 0.796` margin=`0.040` backend=`prototype_matcher`
- `uppercut_left` at `5603ms` score=`0.892` prototype=`boxing_uppercut_left_window_02` class=`uppercut_left` runner-up=`uppercut_right/boxing_uppercut_right_window_01 0.825` margin=`0.067` backend=`prototype_matcher`
- `uppercut_left` at `6162ms` score=`0.926` prototype=`boxing_uppercut_left_window_04` class=`uppercut_left` runner-up=`uppercut_right/boxing_uppercut_right_window_01 0.921` margin=`0.005` backend=`prototype_matcher`
- `uppercut_right` at `6700ms` score=`0.928` prototype=`boxing_uppercut_right_window_01` class=`uppercut_right` runner-up=`uppercut_left/boxing_uppercut_left_window_04 0.909` margin=`0.018` backend=`prototype_matcher`
- `uppercut_right` at `7249ms` score=`0.936` prototype=`boxing_uppercut_right_window_01` class=`uppercut_right` runner-up=`uppercut_left/boxing_uppercut_left_window_04 0.889` margin=`0.047` backend=`prototype_matcher`
- `hook_left` at `7776ms` score=`0.784` prototype=`boxing_hook_left_window_03` class=`hook_left` runner-up=`uppercut_right/boxing_uppercut_right_window_03 0.750` margin=`0.034` backend=`prototype_matcher`
- `hook_right` at `8308ms` score=`0.776` prototype=`boxing_hook_right_window_04` class=`hook_right` runner-up=`uppercut_right/boxing_uppercut_right_window_03 0.762` margin=`0.014` backend=`prototype_matcher`
- `uppercut_left` at `8817ms` score=`0.916` prototype=`boxing_uppercut_left_window_04` class=`uppercut_left` runner-up=`uppercut_right/boxing_uppercut_right_window_01 0.853` margin=`0.063` backend=`prototype_matcher`
- `uppercut_left` at `9251ms` score=`0.975` prototype=`boxing_uppercut_left_window_04` class=`uppercut_left` runner-up=`uppercut_right/boxing_uppercut_right_window_01 0.914` margin=`0.061` backend=`prototype_matcher`
- `uppercut_left` at `9669ms` score=`0.969` prototype=`boxing_uppercut_left_window_04` class=`uppercut_left` runner-up=`uppercut_right/boxing_uppercut_right_window_01 0.906` margin=`0.063` backend=`prototype_matcher`
- `uppercut_right` at `10090ms` score=`0.948` prototype=`boxing_uppercut_right_window_01` class=`uppercut_right` runner-up=`uppercut_left/boxing_uppercut_left_window_04 0.941` margin=`0.006` backend=`prototype_matcher`
- `punch_left` at `10556ms` score=`0.825` prototype=`boxing_straight_left_window_04` class=`straight_left` runner-up=`hook_right/boxing_hook_right_window_04 0.785` margin=`0.040` backend=`prototype_matcher`

### uppercut right

- Fixture: `.testbed/assets/fixtures/boxing/uppercut_right/boxing_guard->uppercut_right_repeat_04_take_01.yaml`
- Source: `.testbed/assets/fixtures/boxing/uppercut_right/boxing_guard->uppercut_right_repeat_04_take_01.mp4`
- Expected event: `uppercut_right`
- Expected class: `uppercut_right`
- Attack events emitted: **20**
- Peak snapshot: uppercut_right via boxing_uppercut_right_window_01 score=0.995 runner-up=straight_right/boxing_straight_right_window_01 0.920 margin=0.075
- Strongest expected emit: `uppercut_right` uppercut_right via boxing_uppercut_right_window_01 score=0.995 runner-up=straight_right/boxing_straight_right_window_01 0.920 margin=0.075
- Strongest wrong emit: `punch_right` straight_right via boxing_straight_right_window_01 score=0.924 runner-up=uppercut_right/boxing_uppercut_right_window_01 0.915 margin=0.009
- Emitted prototype counts: `boxing_uppercut_right_window_01` x7, `boxing_hook_left_window_01` x5, `boxing_hook_right_window_01` x2, `boxing_uppercut_right_window_04` x2, `boxing_straight_left_window_04` x1
- Best-snapshot prototype counts: `boxing_uppercut_right_window_01` x18, `boxing_hook_left_window_01` x16, `boxing_hook_right_window_01` x9, `boxing_uppercut_right_window_03` x4, `boxing_straight_right_window_01` x3
- emitted expected uppercut_right 10 time(s)
- also emitted other attack events: punch_left, hook_left, hook_left, punch_right, uppercut_left, hook_left, hook_right, hook_right, hook_left, hook_left
- peak expected-class score 0.995
- peak winner uppercut_right via boxing_uppercut_right_window_01 scored 0.995; runner-up straight_right via boxing_straight_right_window_01 scored 0.920 (margin 0.075)
- strongest expected emit used boxing_uppercut_right_window_01 at 0.995 over runner-up boxing_straight_right_window_01 at 0.920 (margin 0.075)
- strongest wrong emit was punch_right via boxing_straight_right_window_01 at 0.924 over runner-up boxing_uppercut_right_window_01 at 0.915 (margin 0.009)
- latest matcher reason step_wait

Emitted attack events:
- `punch_left` at `1524ms` score=`0.729` prototype=`boxing_straight_left_window_04` class=`straight_left` runner-up=`uppercut_left/boxing_uppercut_left_window_01 0.726` margin=`0.003` backend=`prototype_matcher`
- `hook_left` at `1899ms` score=`0.808` prototype=`boxing_hook_left_window_01` class=`hook_left` runner-up=`straight_left/boxing_straight_left_window_03 0.734` margin=`0.075` backend=`prototype_matcher`
- `uppercut_right` at `2324ms` score=`0.842` prototype=`boxing_uppercut_right_window_04` class=`uppercut_right` runner-up=`straight_left/boxing_straight_left_window_01 0.808` margin=`0.034` backend=`prototype_matcher`
- `uppercut_right` at `2747ms` score=`0.947` prototype=`boxing_uppercut_right_window_01` class=`uppercut_right` runner-up=`straight_right/boxing_straight_right_window_01 0.897` margin=`0.050` backend=`prototype_matcher`
- `uppercut_right` at `3171ms` score=`0.995` prototype=`boxing_uppercut_right_window_01` class=`uppercut_right` runner-up=`straight_right/boxing_straight_right_window_01 0.920` margin=`0.075` backend=`prototype_matcher`
- `uppercut_right` at `3651ms` score=`0.939` prototype=`boxing_uppercut_right_window_01` class=`uppercut_right` runner-up=`uppercut_left/boxing_uppercut_left_window_01 0.892` margin=`0.047` backend=`prototype_matcher`
- `hook_left` at `4359ms` score=`0.750` prototype=`boxing_hook_left_window_01` class=`hook_left` runner-up=`straight_left/boxing_straight_left_window_04 0.700` margin=`0.049` backend=`prototype_matcher`
- `uppercut_right` at `4845ms` score=`0.870` prototype=`boxing_uppercut_right_window_01` class=`uppercut_right` runner-up=`straight_right/boxing_straight_right_window_01 0.844` margin=`0.026` backend=`prototype_matcher`
- `punch_right` at `5439ms` score=`0.924` prototype=`boxing_straight_right_window_01` class=`straight_right` runner-up=`uppercut_right/boxing_uppercut_right_window_01 0.915` margin=`0.009` backend=`prototype_matcher`
- `uppercut_right` at `6070ms` score=`0.963` prototype=`boxing_uppercut_right_window_01` class=`uppercut_right` runner-up=`straight_right/boxing_straight_right_window_01 0.924` margin=`0.039` backend=`prototype_matcher`
- `uppercut_left` at `6615ms` score=`0.832` prototype=`boxing_uppercut_left_window_01` class=`uppercut_left` runner-up=`straight_left/boxing_straight_left_window_04 0.832` margin=`0.000` backend=`prototype_matcher`
- `hook_left` at `7140ms` score=`0.833` prototype=`boxing_hook_left_window_01` class=`hook_left` runner-up=`straight_left/boxing_straight_left_window_04 0.792` margin=`0.041` backend=`prototype_matcher`
- `uppercut_right` at `7642ms` score=`0.836` prototype=`boxing_uppercut_right_window_03` class=`uppercut_right` runner-up=`straight_left/boxing_straight_left_window_04 0.829` margin=`0.007` backend=`prototype_matcher`
- `hook_right` at `8151ms` score=`0.923` prototype=`boxing_hook_right_window_01` class=`hook_right` runner-up=`uppercut_right/boxing_uppercut_right_window_01 0.888` margin=`0.035` backend=`prototype_matcher`
- `hook_right` at `8691ms` score=`0.870` prototype=`boxing_hook_right_window_01` class=`hook_right` runner-up=`uppercut_left/boxing_uppercut_left_window_01 0.840` margin=`0.030` backend=`prototype_matcher`
- `hook_left` at `9248ms` score=`0.737` prototype=`boxing_hook_left_window_01` class=`hook_left` runner-up=`straight_left/boxing_straight_left_window_04 0.660` margin=`0.077` backend=`prototype_matcher`
- `hook_left` at `9605ms` score=`0.835` prototype=`boxing_hook_left_window_01` class=`hook_left` runner-up=`straight_left/boxing_straight_left_window_04 0.723` margin=`0.112` backend=`prototype_matcher`
- `uppercut_right` at `9988ms` score=`0.863` prototype=`boxing_uppercut_right_window_04` class=`uppercut_right` runner-up=`straight_left/boxing_straight_left_window_03 0.819` margin=`0.043` backend=`prototype_matcher`
- `uppercut_right` at `10374ms` score=`0.952` prototype=`boxing_uppercut_right_window_01` class=`uppercut_right` runner-up=`straight_right/boxing_straight_right_window_01 0.889` margin=`0.064` backend=`prototype_matcher`
- `uppercut_right` at `10717ms` score=`0.915` prototype=`boxing_uppercut_right_window_01` class=`uppercut_right` runner-up=`uppercut_left/boxing_uppercut_left_window_01 0.901` margin=`0.014` backend=`prototype_matcher`

### negative control - running in place

- Fixture: `.testbed/assets/fixtures/boxing/run_in_place/boxing_guard->run_in_place_repeat_01_take_01.yaml`
- Source: `.testbed/assets/fixtures/boxing/run_in_place/boxing_guard->run_in_place_repeat_01_take_01.mp4`
- Expected event: `None`
- Expected class: `None`
- Attack events emitted: **20**
- Peak snapshot: hook_right via boxing_hook_right_window_04 score=0.918 runner-up=uppercut_left/boxing_uppercut_left_window_01 0.840 margin=0.078
- Strongest wrong emit: `hook_right` hook_right via boxing_hook_right_window_04 score=0.918 runner-up=uppercut_left/boxing_uppercut_left_window_01 0.840 margin=0.078
- Emitted prototype counts: `boxing_straight_left_window_04` x8, `boxing_straight_left_window_03` x5, `boxing_hook_left_window_04` x3, `boxing_hook_right_window_04` x3, `boxing_hook_left_window_01` x1
- Best-snapshot prototype counts: `boxing_straight_left_window_04` x25, `boxing_straight_left_window_03` x17, `boxing_hook_right_window_04` x8, `boxing_hook_left_window_04` x6, `boxing_hook_left_window_01` x3
- negative control still emitted attack events: punch_left, punch_left, hook_left, hook_left, punch_left, punch_left, punch_left, punch_left, punch_left, punch_left, punch_left, punch_left, punch_left, punch_left, hook_right, hook_right, hook_right, punch_left, hook_left, hook_left
- peak winner hook_right via boxing_hook_right_window_04 scored 0.918; runner-up uppercut_left via boxing_uppercut_left_window_01 scored 0.840 (margin 0.078)
- strongest wrong emit was hook_right via boxing_hook_right_window_04 at 0.918 over runner-up boxing_uppercut_left_window_01 at 0.840 (margin 0.078)
- latest matcher reason step_wait

Emitted attack events:
- `punch_left` at `1647ms` score=`0.870` prototype=`boxing_straight_left_window_03` class=`straight_left` runner-up=`hook_right/boxing_hook_right_window_04 0.844` margin=`0.026` backend=`prototype_matcher`
- `punch_left` at `1957ms` score=`0.849` prototype=`boxing_straight_left_window_03` class=`straight_left` runner-up=`hook_right/boxing_hook_right_window_04 0.812` margin=`0.036` backend=`prototype_matcher`
- `hook_left` at `2383ms` score=`0.786` prototype=`boxing_hook_left_window_04` class=`hook_left` runner-up=`straight_left/boxing_straight_left_window_04 0.780` margin=`0.006` backend=`prototype_matcher`
- `hook_left` at `2824ms` score=`0.793` prototype=`boxing_hook_left_window_01` class=`hook_left` runner-up=`straight_left/boxing_straight_left_window_04 0.791` margin=`0.002` backend=`prototype_matcher`
- `punch_left` at `3257ms` score=`0.826` prototype=`boxing_straight_left_window_04` class=`straight_left` runner-up=`hook_left/boxing_hook_left_window_01 0.808` margin=`0.018` backend=`prototype_matcher`
- `punch_left` at `3733ms` score=`0.843` prototype=`boxing_straight_left_window_04` class=`straight_left` runner-up=`hook_left/boxing_hook_left_window_01 0.813` margin=`0.029` backend=`prototype_matcher`
- `punch_left` at `4163ms` score=`0.837` prototype=`boxing_straight_left_window_04` class=`straight_left` runner-up=`hook_left/boxing_hook_left_window_01 0.805` margin=`0.032` backend=`prototype_matcher`
- `punch_left` at `4610ms` score=`0.834` prototype=`boxing_straight_left_window_03` class=`straight_left` runner-up=`hook_right/boxing_hook_right_window_04 0.812` margin=`0.022` backend=`prototype_matcher`
- `punch_left` at `5248ms` score=`0.840` prototype=`boxing_straight_left_window_04` class=`straight_left` runner-up=`hook_right/boxing_hook_right_window_04 0.827` margin=`0.013` backend=`prototype_matcher`
- `punch_left` at `5867ms` score=`0.849` prototype=`boxing_straight_left_window_04` class=`straight_left` runner-up=`hook_right/boxing_hook_right_window_04 0.803` margin=`0.046` backend=`prototype_matcher`
- `punch_left` at `6386ms` score=`0.831` prototype=`boxing_straight_left_window_04` class=`straight_left` runner-up=`hook_left/boxing_hook_left_window_01 0.776` margin=`0.054` backend=`prototype_matcher`
- `punch_left` at `6861ms` score=`0.832` prototype=`boxing_straight_left_window_03` class=`straight_left` runner-up=`hook_left/boxing_hook_left_window_01 0.779` margin=`0.053` backend=`prototype_matcher`
- `punch_left` at `7362ms` score=`0.812` prototype=`boxing_straight_left_window_04` class=`straight_left` runner-up=`hook_left/boxing_hook_left_window_01 0.771` margin=`0.041` backend=`prototype_matcher`
- `punch_left` at `7857ms` score=`0.846` prototype=`boxing_straight_left_window_04` class=`straight_left` runner-up=`hook_left/boxing_hook_left_window_01 0.790` margin=`0.056` backend=`prototype_matcher`
- `hook_right` at `8498ms` score=`0.918` prototype=`boxing_hook_right_window_04` class=`hook_right` runner-up=`uppercut_left/boxing_uppercut_left_window_01 0.840` margin=`0.078` backend=`prototype_matcher`
- `hook_right` at `8887ms` score=`0.891` prototype=`boxing_hook_right_window_04` class=`hook_right` runner-up=`uppercut_left/boxing_uppercut_left_window_01 0.854` margin=`0.036` backend=`prototype_matcher`
- `hook_right` at `9306ms` score=`0.877` prototype=`boxing_hook_right_window_04` class=`hook_right` runner-up=`uppercut_left/boxing_uppercut_left_window_01 0.859` margin=`0.018` backend=`prototype_matcher`
- `punch_left` at `9693ms` score=`0.861` prototype=`boxing_straight_left_window_03` class=`straight_left` runner-up=`hook_right/boxing_hook_right_window_04 0.839` margin=`0.022` backend=`prototype_matcher`
- `hook_left` at `10081ms` score=`0.774` prototype=`boxing_hook_left_window_04` class=`hook_left` runner-up=`straight_left/boxing_straight_left_window_04 0.769` margin=`0.005` backend=`prototype_matcher`
- `hook_left` at `10494ms` score=`0.785` prototype=`boxing_hook_left_window_04` class=`hook_left` runner-up=`straight_left/boxing_straight_left_window_04 0.782` margin=`0.003` backend=`prototype_matcher`
