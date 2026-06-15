# Prototype Matcher Fixture Benchmark

- Benchmark ID: `prototype_matcher_boxing_fixture_derived_v1`
- Library ID: `boxing_side_aware_fixture_derived_v1`
- Profile: `boxing`
- Generated At: `2026-06-15T12:19:04-04:00`
- Runner: `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/scripts/run_prototype_matcher_fixture_benchmark.py`

## Aggregate

- Fixture count: **7**
- Negative controls clean: **0 / 1**
- Negative-control false-positive classes: `hook_left` x21, `straight_left` x7, `hook_right` x1
- Negative-control false-positive prototypes: `boxing_hook_left_window_01` x17, `boxing_hook_left_window_03` x4, `boxing_straight_left_window_03` x4, `boxing_straight_left_window_01` x2, `boxing_hook_right_window_01` x1

## Per Fixture

### straight left

- Fixture: `.testbed/assets/fixtures/boxing/straight_left/boxing_guard->straight_left_repeat_04_take_01.yaml`
- Source: `.testbed/assets/fixtures/boxing/straight_left/boxing_guard->straight_left_repeat_04_take_01.mp4`
- Expected event: `punch_left`
- Expected class: `straight_left`
- Attack events emitted: **29**
- Peak snapshot: straight_left via boxing_straight_left_window_04 score=1.000 runner-up=hook_right/boxing_hook_right_window_01 0.911 margin=0.089
- Strongest expected emit: `punch_left` straight_left via boxing_straight_left_window_03 score=0.966 runner-up=hook_right/boxing_hook_right_window_01 0.905 margin=0.061
- Strongest wrong emit: `hook_right` hook_right via boxing_hook_right_window_01 score=0.934 runner-up=straight_left/boxing_straight_left_window_01 0.933 margin=0.000
- Emitted prototype counts: `boxing_hook_right_window_01` x13, `boxing_uppercut_left_window_02` x6, `boxing_straight_left_window_01` x5, `boxing_straight_left_window_03` x2, `boxing_hook_right_window_02` x1
- Best-snapshot prototype counts: `boxing_hook_right_window_01` x34, `boxing_uppercut_left_window_02` x15, `boxing_straight_left_window_01` x13, `boxing_straight_left_window_04` x7, `boxing_straight_left_window_03` x6
- emitted expected punch_left 8 time(s)
- also emitted other attack events: uppercut_left, uppercut_left, hook_right, hook_right, hook_right, hook_right, hook_right, hook_right, hook_right, hook_right, hook_right, hook_right, hook_right, uppercut_left, uppercut_left, uppercut_left, uppercut_left, hook_right, hook_right, uppercut_right, hook_right
- peak expected-class score 1.000
- peak winner straight_left via boxing_straight_left_window_04 scored 1.000; runner-up hook_right via boxing_hook_right_window_01 scored 0.911 (margin 0.089)
- strongest expected emit used boxing_straight_left_window_03 at 0.966 over runner-up boxing_hook_right_window_01 at 0.905 (margin 0.061)
- strongest wrong emit was hook_right via boxing_hook_right_window_01 at 0.934 over runner-up boxing_straight_left_window_01 at 0.933 (margin 0.000)
- latest matcher reason emit_cooldown_active

Emitted attack events:
- `uppercut_left` at `1101ms` score=`0.911` prototype=`boxing_uppercut_left_window_02` class=`uppercut_left` runner-up=`uppercut_right/boxing_uppercut_right_window_04 0.840` margin=`0.071` backend=`prototype_matcher`
- `uppercut_left` at `1372ms` score=`0.886` prototype=`boxing_uppercut_left_window_02` class=`uppercut_left` runner-up=`uppercut_right/boxing_uppercut_right_window_04 0.864` margin=`0.021` backend=`prototype_matcher`
- `hook_right` at `1698ms` score=`0.779` prototype=`boxing_hook_right_window_01` class=`hook_right` runner-up=`uppercut_right/boxing_uppercut_right_window_04 0.774` margin=`0.005` backend=`prototype_matcher`
- `punch_left` at `2009ms` score=`0.783` prototype=`boxing_straight_left_window_01` class=`straight_left` runner-up=`hook_right/boxing_hook_right_window_01 0.758` margin=`0.025` backend=`prototype_matcher`
- `punch_left` at `2326ms` score=`0.908` prototype=`boxing_straight_left_window_01` class=`straight_left` runner-up=`hook_right/boxing_hook_right_window_01 0.905` margin=`0.003` backend=`prototype_matcher`
- `punch_left` at `2645ms` score=`0.902` prototype=`boxing_straight_left_window_04` class=`straight_left` runner-up=`uppercut_right/boxing_uppercut_right_window_04 0.884` margin=`0.018` backend=`prototype_matcher`
- `hook_right` at `2963ms` score=`0.782` prototype=`boxing_hook_right_window_01` class=`hook_right` runner-up=`uppercut_right/boxing_uppercut_right_window_04 0.770` margin=`0.012` backend=`prototype_matcher`
- `hook_right` at `3278ms` score=`0.806` prototype=`boxing_hook_right_window_02` class=`hook_right` runner-up=`uppercut_right/boxing_uppercut_right_window_04 0.766` margin=`0.040` backend=`prototype_matcher`
- `hook_right` at `3613ms` score=`0.934` prototype=`boxing_hook_right_window_01` class=`hook_right` runner-up=`straight_left/boxing_straight_left_window_01 0.933` margin=`0.000` backend=`prototype_matcher`
- `hook_right` at `3937ms` score=`0.876` prototype=`boxing_hook_right_window_01` class=`hook_right` runner-up=`uppercut_right/boxing_uppercut_right_window_04 0.817` margin=`0.059` backend=`prototype_matcher`
- `hook_right` at `4276ms` score=`0.829` prototype=`boxing_hook_right_window_01` class=`hook_right` runner-up=`uppercut_right/boxing_uppercut_right_window_04 0.786` margin=`0.043` backend=`prototype_matcher`
- `hook_right` at `4578ms` score=`0.849` prototype=`boxing_hook_right_window_01` class=`hook_right` runner-up=`straight_left/boxing_straight_left_window_03 0.845` margin=`0.004` backend=`prototype_matcher`
- `punch_left` at `4901ms` score=`0.966` prototype=`boxing_straight_left_window_03` class=`straight_left` runner-up=`hook_right/boxing_hook_right_window_01 0.905` margin=`0.061` backend=`prototype_matcher`
- `punch_left` at `5229ms` score=`0.872` prototype=`boxing_straight_left_window_03` class=`straight_left` runner-up=`hook_right/boxing_hook_right_window_01 0.869` margin=`0.003` backend=`prototype_matcher`
- `hook_right` at `5550ms` score=`0.841` prototype=`boxing_hook_right_window_01` class=`hook_right` runner-up=`uppercut_right/boxing_uppercut_right_window_04 0.803` margin=`0.038` backend=`prototype_matcher`
- `hook_right` at `5857ms` score=`0.858` prototype=`boxing_hook_right_window_01` class=`hook_right` runner-up=`uppercut_right/boxing_uppercut_right_window_04 0.832` margin=`0.026` backend=`prototype_matcher`
- `hook_right` at `6162ms` score=`0.929` prototype=`boxing_hook_right_window_01` class=`hook_right` runner-up=`straight_left/boxing_straight_left_window_04 0.910` margin=`0.018` backend=`prototype_matcher`
- `hook_right` at `6461ms` score=`0.924` prototype=`boxing_hook_right_window_01` class=`hook_right` runner-up=`straight_left/boxing_straight_left_window_01 0.909` margin=`0.015` backend=`prototype_matcher`
- `uppercut_left` at `6689ms` score=`0.899` prototype=`boxing_uppercut_left_window_02` class=`uppercut_left` runner-up=`uppercut_right/boxing_uppercut_right_window_04 0.846` margin=`0.053` backend=`prototype_matcher`
- `uppercut_left` at `6997ms` score=`0.888` prototype=`boxing_uppercut_left_window_02` class=`uppercut_left` runner-up=`uppercut_right/boxing_uppercut_right_window_04 0.837` margin=`0.052` backend=`prototype_matcher`
- `uppercut_left` at `7308ms` score=`0.906` prototype=`boxing_uppercut_left_window_02` class=`uppercut_left` runner-up=`uppercut_right/boxing_uppercut_right_window_04 0.852` margin=`0.054` backend=`prototype_matcher`
- `uppercut_left` at `7620ms` score=`0.933` prototype=`boxing_uppercut_left_window_02` class=`uppercut_left` runner-up=`uppercut_right/boxing_uppercut_right_window_01 0.877` margin=`0.056` backend=`prototype_matcher`
- `hook_right` at `7931ms` score=`0.836` prototype=`boxing_hook_right_window_01` class=`hook_right` runner-up=`uppercut_right/boxing_uppercut_right_window_04 0.818` margin=`0.019` backend=`prototype_matcher`
- `hook_right` at `8242ms` score=`0.754` prototype=`boxing_hook_right_window_01` class=`hook_right` runner-up=`uppercut_right/boxing_uppercut_right_window_04 0.731` margin=`0.023` backend=`prototype_matcher`
- `punch_left` at `8554ms` score=`0.869` prototype=`boxing_straight_left_window_01` class=`straight_left` runner-up=`uppercut_right/boxing_uppercut_right_window_04 0.854` margin=`0.015` backend=`prototype_matcher`
- `punch_left` at `8864ms` score=`0.957` prototype=`boxing_straight_left_window_01` class=`straight_left` runner-up=`uppercut_right/boxing_uppercut_right_window_04 0.892` margin=`0.066` backend=`prototype_matcher`
- `uppercut_right` at `9181ms` score=`0.800` prototype=`boxing_uppercut_right_window_04` class=`uppercut_right` runner-up=`hook_right/boxing_hook_right_window_01 0.785` margin=`0.015` backend=`prototype_matcher`
- `hook_right` at `9494ms` score=`0.768` prototype=`boxing_hook_right_window_01` class=`hook_right` runner-up=`uppercut_right/boxing_uppercut_right_window_04 0.760` margin=`0.008` backend=`prototype_matcher`
- `punch_left` at `9801ms` score=`0.933` prototype=`boxing_straight_left_window_01` class=`straight_left` runner-up=`hook_right/boxing_hook_right_window_01 0.905` margin=`0.028` backend=`prototype_matcher`

### straight right

- Fixture: `.testbed/assets/fixtures/boxing/straight_right/boxing_guard->straight_right_repeat_04_take_01.yaml`
- Source: `.testbed/assets/fixtures/boxing/straight_right/boxing_guard->straight_right_repeat_04_take_01.mp4`
- Expected event: `punch_right`
- Expected class: `straight_right`
- Attack events emitted: **33**
- Peak snapshot: straight_right via boxing_straight_right_window_01 score=0.982 runner-up=uppercut_right/boxing_uppercut_right_window_01 0.799 margin=0.183
- Strongest expected emit: `punch_right` straight_right via boxing_straight_right_window_01 score=0.982 runner-up=uppercut_right/boxing_uppercut_right_window_01 0.799 margin=0.183
- Strongest wrong emit: `uppercut_left` uppercut_left via boxing_uppercut_left_window_02 score=0.828 runner-up=straight_right/boxing_straight_right_window_04 0.792 margin=0.035
- Emitted prototype counts: `boxing_straight_right_window_04` x16, `boxing_straight_right_window_01` x5, `boxing_straight_right_window_02` x4, `boxing_uppercut_left_window_02` x3, `boxing_uppercut_left_window_03` x3
- Best-snapshot prototype counts: `boxing_straight_right_window_04` x29, `boxing_straight_right_window_01` x12, `boxing_uppercut_left_window_03` x12, `boxing_straight_right_window_02` x10, `boxing_uppercut_left_window_02` x7
- emitted expected punch_right 27 time(s)
- also emitted other attack events: uppercut_left, uppercut_left, uppercut_left, uppercut_left, uppercut_left, uppercut_left
- peak expected-class score 0.982
- peak winner straight_right via boxing_straight_right_window_01 scored 0.982; runner-up uppercut_right via boxing_uppercut_right_window_01 scored 0.799 (margin 0.183)
- strongest expected emit used boxing_straight_right_window_01 at 0.982 over runner-up boxing_uppercut_right_window_01 at 0.799 (margin 0.183)
- strongest wrong emit was uppercut_left via boxing_uppercut_left_window_02 at 0.828 over runner-up boxing_straight_right_window_04 at 0.792 (margin 0.035)
- latest matcher reason step_wait

Emitted attack events:
- `punch_right` at `1070ms` score=`0.834` prototype=`boxing_straight_right_window_04` class=`straight_right` runner-up=`uppercut_left/boxing_uppercut_left_window_03 0.748` margin=`0.086` backend=`prototype_matcher`
- `punch_right` at `1233ms` score=`0.876` prototype=`boxing_straight_right_window_04` class=`straight_right` runner-up=`uppercut_left/boxing_uppercut_left_window_03 0.756` margin=`0.120` backend=`prototype_matcher`
- `punch_right` at `1471ms` score=`0.930` prototype=`boxing_straight_right_window_01` class=`straight_right` runner-up=`uppercut_right/boxing_uppercut_right_window_01 0.794` margin=`0.136` backend=`prototype_matcher`
- `punch_right` at `1717ms` score=`0.940` prototype=`boxing_straight_right_window_01` class=`straight_right` runner-up=`uppercut_right/boxing_uppercut_right_window_01 0.848` margin=`0.092` backend=`prototype_matcher`
- `uppercut_left` at `2219ms` score=`0.828` prototype=`boxing_uppercut_left_window_02` class=`uppercut_left` runner-up=`straight_right/boxing_straight_right_window_04 0.792` margin=`0.035` backend=`prototype_matcher`
- `punch_right` at `2467ms` score=`0.902` prototype=`boxing_straight_right_window_04` class=`straight_right` runner-up=`uppercut_left/boxing_uppercut_left_window_02 0.822` margin=`0.081` backend=`prototype_matcher`
- `punch_right` at `2724ms` score=`0.879` prototype=`boxing_straight_right_window_02` class=`straight_right` runner-up=`uppercut_left/boxing_uppercut_left_window_02 0.847` margin=`0.032` backend=`prototype_matcher`
- `punch_right` at `2969ms` score=`0.966` prototype=`boxing_straight_right_window_02` class=`straight_right` runner-up=`uppercut_left/boxing_uppercut_left_window_02 0.849` margin=`0.116` backend=`prototype_matcher`
- `uppercut_left` at `3231ms` score=`0.753` prototype=`boxing_uppercut_left_window_03` class=`uppercut_left` runner-up=`straight_right/boxing_straight_right_window_02 0.655` margin=`0.098` backend=`prototype_matcher`
- `punch_right` at `3595ms` score=`0.821` prototype=`boxing_straight_right_window_04` class=`straight_right` runner-up=`uppercut_left/boxing_uppercut_left_window_02 0.804` margin=`0.017` backend=`prototype_matcher`
- `punch_right` at `3845ms` score=`0.917` prototype=`boxing_straight_right_window_01` class=`straight_right` runner-up=`uppercut_left/boxing_uppercut_left_window_02 0.804` margin=`0.113` backend=`prototype_matcher`
- `punch_right` at `4095ms` score=`0.912` prototype=`boxing_straight_right_window_04` class=`straight_right` runner-up=`uppercut_right/boxing_uppercut_right_window_01 0.861` margin=`0.051` backend=`prototype_matcher`
- `punch_right` at `4345ms` score=`0.952` prototype=`boxing_straight_right_window_03` class=`straight_right` runner-up=`uppercut_left/boxing_uppercut_left_window_03 0.771` margin=`0.181` backend=`prototype_matcher`
- `uppercut_left` at `4604ms` score=`0.735` prototype=`boxing_uppercut_left_window_03` class=`uppercut_left` runner-up=`straight_left/boxing_straight_left_window_01 0.633` margin=`0.102` backend=`prototype_matcher`
- `uppercut_left` at `4856ms` score=`0.755` prototype=`boxing_uppercut_left_window_02` class=`uppercut_left` runner-up=`straight_left/boxing_straight_left_window_01 0.648` margin=`0.106` backend=`prototype_matcher`
- `punch_right` at `5095ms` score=`0.914` prototype=`boxing_straight_right_window_04` class=`straight_right` runner-up=`uppercut_left/boxing_uppercut_left_window_03 0.793` margin=`0.121` backend=`prototype_matcher`
- `punch_right` at `5344ms` score=`0.946` prototype=`boxing_straight_right_window_04` class=`straight_right` runner-up=`uppercut_left/boxing_uppercut_left_window_02 0.883` margin=`0.063` backend=`prototype_matcher`
- `punch_right` at `5595ms` score=`0.954` prototype=`boxing_straight_right_window_04` class=`straight_right` runner-up=`uppercut_left/boxing_uppercut_left_window_02 0.833` margin=`0.121` backend=`prototype_matcher`
- `punch_right` at `5845ms` score=`0.946` prototype=`boxing_straight_right_window_04` class=`straight_right` runner-up=`uppercut_left/boxing_uppercut_left_window_03 0.794` margin=`0.152` backend=`prototype_matcher`
- `punch_right` at `6067ms` score=`0.932` prototype=`boxing_straight_right_window_04` class=`straight_right` runner-up=`uppercut_right/boxing_uppercut_right_window_01 0.788` margin=`0.144` backend=`prototype_matcher`
- `punch_right` at `6190ms` score=`0.923` prototype=`boxing_straight_right_window_04` class=`straight_right` runner-up=`uppercut_right/boxing_uppercut_right_window_01 0.756` margin=`0.167` backend=`prototype_matcher`
- `punch_right` at `6820ms` score=`0.799` prototype=`boxing_straight_right_window_03` class=`straight_right` runner-up=`uppercut_left/boxing_uppercut_left_window_02 0.761` margin=`0.039` backend=`prototype_matcher`
- `punch_right` at `7069ms` score=`0.857` prototype=`boxing_straight_right_window_04` class=`straight_right` runner-up=`uppercut_left/boxing_uppercut_left_window_03 0.747` margin=`0.109` backend=`prototype_matcher`
- `punch_right` at `7316ms` score=`0.907` prototype=`boxing_straight_right_window_04` class=`straight_right` runner-up=`uppercut_right/boxing_uppercut_right_window_01 0.761` margin=`0.147` backend=`prototype_matcher`
- `punch_right` at `7569ms` score=`0.982` prototype=`boxing_straight_right_window_01` class=`straight_right` runner-up=`uppercut_right/boxing_uppercut_right_window_01 0.799` margin=`0.183` backend=`prototype_matcher`
- `punch_right` at `7819ms` score=`0.763` prototype=`boxing_straight_right_window_04` class=`straight_right` runner-up=`uppercut_left/boxing_uppercut_left_window_03 0.748` margin=`0.015` backend=`prototype_matcher`
- `uppercut_left` at `8190ms` score=`0.803` prototype=`boxing_uppercut_left_window_02` class=`uppercut_left` runner-up=`straight_right/boxing_straight_right_window_04 0.665` margin=`0.138` backend=`prototype_matcher`
- `punch_right` at `8441ms` score=`0.902` prototype=`boxing_straight_right_window_04` class=`straight_right` runner-up=`uppercut_left/boxing_uppercut_left_window_02 0.822` margin=`0.081` backend=`prototype_matcher`
- `punch_right` at `8692ms` score=`0.879` prototype=`boxing_straight_right_window_02` class=`straight_right` runner-up=`uppercut_left/boxing_uppercut_left_window_02 0.847` margin=`0.032` backend=`prototype_matcher`
- `punch_right` at `8940ms` score=`0.966` prototype=`boxing_straight_right_window_02` class=`straight_right` runner-up=`uppercut_left/boxing_uppercut_left_window_02 0.849` margin=`0.116` backend=`prototype_matcher`
- `uppercut_left` at `9202ms` score=`0.753` prototype=`boxing_uppercut_left_window_03` class=`uppercut_left` runner-up=`straight_right/boxing_straight_right_window_02 0.655` margin=`0.098` backend=`prototype_matcher`
- `punch_right` at `9567ms` score=`0.821` prototype=`boxing_straight_right_window_04` class=`straight_right` runner-up=`uppercut_left/boxing_uppercut_left_window_02 0.804` margin=`0.017` backend=`prototype_matcher`
- `punch_right` at `9821ms` score=`0.917` prototype=`boxing_straight_right_window_01` class=`straight_right` runner-up=`uppercut_left/boxing_uppercut_left_window_02 0.804` margin=`0.113` backend=`prototype_matcher`

### hook left

- Fixture: `.testbed/assets/fixtures/boxing/hook_left/boxing_guard->hook_left_repeat_04_take_01.yaml`
- Source: `.testbed/assets/fixtures/boxing/hook_left/boxing_guard->hook_left_repeat_04_take_01.mp4`
- Expected event: `hook_left`
- Expected class: `hook_left`
- Attack events emitted: **26**
- Peak snapshot: hook_left via boxing_hook_left_window_04 score=1.000 runner-up=hook_right/boxing_hook_right_window_02 0.895 margin=0.105
- Strongest expected emit: `hook_left` hook_left via boxing_hook_left_window_04 score=1.000 runner-up=hook_right/boxing_hook_right_window_02 0.895 margin=0.105
- Strongest wrong emit: `uppercut_right` uppercut_right via boxing_uppercut_right_window_01 score=0.918 runner-up=uppercut_left/boxing_uppercut_left_window_01 0.904 margin=0.014
- Emitted prototype counts: `boxing_hook_left_window_01` x5, `boxing_hook_right_window_02` x5, `boxing_hook_left_window_03` x3, `boxing_uppercut_left_window_01` x3, `boxing_uppercut_right_window_01` x3
- Best-snapshot prototype counts: `boxing_hook_left_window_01` x14, `boxing_hook_right_window_02` x13, `boxing_hook_right_window_03` x12, `boxing_hook_left_window_03` x11, `boxing_uppercut_left_window_01` x8
- emitted expected hook_left 10 time(s)
- also emitted other attack events: uppercut_right, uppercut_left, hook_right, hook_right, hook_right, hook_right, hook_right, hook_right, hook_right, uppercut_left, uppercut_right, uppercut_right, uppercut_right, uppercut_left, hook_right, hook_right
- peak expected-class score 1.000
- peak winner hook_left via boxing_hook_left_window_04 scored 1.000; runner-up hook_right via boxing_hook_right_window_02 scored 0.895 (margin 0.105)
- strongest expected emit used boxing_hook_left_window_04 at 1.000 over runner-up boxing_hook_right_window_02 at 0.895 (margin 0.105)
- strongest wrong emit was uppercut_right via boxing_uppercut_right_window_01 at 0.918 over runner-up boxing_uppercut_left_window_01 at 0.904 (margin 0.014)
- latest matcher reason step_wait

Emitted attack events:
- `uppercut_right` at `1096ms` score=`0.905` prototype=`boxing_uppercut_right_window_01` class=`uppercut_right` runner-up=`uppercut_left/boxing_uppercut_left_window_02 0.887` margin=`0.018` backend=`prototype_matcher`
- `uppercut_left` at `1378ms` score=`0.885` prototype=`boxing_uppercut_left_window_01` class=`uppercut_left` runner-up=`hook_right/boxing_hook_right_window_01 0.884` margin=`0.001` backend=`prototype_matcher`
- `hook_right` at `2001ms` score=`0.720` prototype=`boxing_hook_right_window_02` class=`hook_right` runner-up=`uppercut_right/boxing_uppercut_right_window_03 0.663` margin=`0.057` backend=`prototype_matcher`
- `hook_left` at `2322ms` score=`0.920` prototype=`boxing_hook_left_window_01` class=`hook_left` runner-up=`hook_right/boxing_hook_right_window_02 0.868` margin=`0.053` backend=`prototype_matcher`
- `hook_left` at `2635ms` score=`0.927` prototype=`boxing_hook_left_window_01` class=`hook_left` runner-up=`straight_left/boxing_straight_left_window_03 0.845` margin=`0.083` backend=`prototype_matcher`
- `hook_left` at `2950ms` score=`0.882` prototype=`boxing_hook_left_window_01` class=`hook_left` runner-up=`straight_left/boxing_straight_left_window_03 0.861` margin=`0.022` backend=`prototype_matcher`
- `hook_right` at `3270ms` score=`0.712` prototype=`boxing_hook_right_window_03` class=`hook_right` runner-up=`uppercut_right/boxing_uppercut_right_window_03 0.696` margin=`0.016` backend=`prototype_matcher`
- `hook_left` at `3795ms` score=`0.789` prototype=`boxing_hook_left_window_03` class=`hook_left` runner-up=`hook_right/boxing_hook_right_window_02 0.737` margin=`0.052` backend=`prototype_matcher`
- `hook_left` at `4109ms` score=`0.914` prototype=`boxing_hook_left_window_02` class=`hook_left` runner-up=`straight_left/boxing_straight_left_window_02 0.794` margin=`0.121` backend=`prototype_matcher`
- `hook_left` at `4427ms` score=`0.877` prototype=`boxing_hook_left_window_01` class=`hook_left` runner-up=`straight_left/boxing_straight_left_window_03 0.857` margin=`0.020` backend=`prototype_matcher`
- `hook_right` at `4742ms` score=`0.757` prototype=`boxing_hook_right_window_02` class=`hook_right` runner-up=`uppercut_right/boxing_uppercut_right_window_03 0.754` margin=`0.003` backend=`prototype_matcher`
- `hook_right` at `5170ms` score=`0.736` prototype=`boxing_hook_right_window_02` class=`hook_right` runner-up=`uppercut_right/boxing_uppercut_right_window_03 0.689` margin=`0.047` backend=`prototype_matcher`
- `hook_left` at `5475ms` score=`0.907` prototype=`boxing_hook_left_window_03` class=`hook_left` runner-up=`hook_right/boxing_hook_right_window_02 0.771` margin=`0.135` backend=`prototype_matcher`
- `hook_left` at `5784ms` score=`0.902` prototype=`boxing_hook_left_window_03` class=`hook_left` runner-up=`straight_left/boxing_straight_left_window_03 0.799` margin=`0.104` backend=`prototype_matcher`
- `hook_left` at `6114ms` score=`0.792` prototype=`boxing_hook_left_window_01` class=`hook_left` runner-up=`straight_left/boxing_straight_left_window_03 0.723` margin=`0.070` backend=`prototype_matcher`
- `hook_right` at `6420ms` score=`0.741` prototype=`boxing_hook_right_window_03` class=`hook_right` runner-up=`uppercut_right/boxing_uppercut_right_window_03 0.709` margin=`0.032` backend=`prototype_matcher`
- `hook_right` at `6745ms` score=`0.750` prototype=`boxing_hook_right_window_02` class=`hook_right` runner-up=`uppercut_right/boxing_uppercut_right_window_03 0.716` margin=`0.034` backend=`prototype_matcher`
- `hook_left` at `7047ms` score=`1.000` prototype=`boxing_hook_left_window_04` class=`hook_left` runner-up=`hook_right/boxing_hook_right_window_02 0.895` margin=`0.105` backend=`prototype_matcher`
- `hook_right` at `7353ms` score=`0.837` prototype=`boxing_hook_right_window_01` class=`hook_right` runner-up=`straight_left/boxing_straight_left_window_03 0.837` margin=`0.000` backend=`prototype_matcher`
- `uppercut_left` at `7690ms` score=`0.866` prototype=`boxing_uppercut_left_window_01` class=`uppercut_left` runner-up=`straight_left/boxing_straight_left_window_04 0.832` margin=`0.033` backend=`prototype_matcher`
- `uppercut_right` at `8045ms` score=`0.898` prototype=`boxing_uppercut_right_window_04` class=`uppercut_right` runner-up=`uppercut_left/boxing_uppercut_left_window_01 0.897` margin=`0.001` backend=`prototype_matcher`
- `uppercut_right` at `8353ms` score=`0.918` prototype=`boxing_uppercut_right_window_01` class=`uppercut_right` runner-up=`uppercut_left/boxing_uppercut_left_window_01 0.904` margin=`0.014` backend=`prototype_matcher`
- `uppercut_right` at `8660ms` score=`0.915` prototype=`boxing_uppercut_right_window_01` class=`uppercut_right` runner-up=`uppercut_left/boxing_uppercut_left_window_02 0.898` margin=`0.017` backend=`prototype_matcher`
- `uppercut_left` at `8967ms` score=`0.900` prototype=`boxing_uppercut_left_window_01` class=`uppercut_left` runner-up=`uppercut_right/boxing_uppercut_right_window_04 0.897` margin=`0.003` backend=`prototype_matcher`
- `hook_right` at `9284ms` score=`0.793` prototype=`boxing_hook_right_window_01` class=`hook_right` runner-up=`uppercut_right/boxing_uppercut_right_window_04 0.764` margin=`0.028` backend=`prototype_matcher`
- `hook_right` at `9685ms` score=`0.720` prototype=`boxing_hook_right_window_02` class=`hook_right` runner-up=`uppercut_right/boxing_uppercut_right_window_03 0.663` margin=`0.057` backend=`prototype_matcher`

### hook right

- Fixture: `.testbed/assets/fixtures/boxing/hook_right/boxing_guard->hook_right_repeat_04_take_01.yaml`
- Source: `.testbed/assets/fixtures/boxing/hook_right/boxing_guard->hook_right_repeat_04_take_01.mp4`
- Expected event: `hook_right`
- Expected class: `hook_right`
- Attack events emitted: **27**
- Peak snapshot: hook_right via boxing_hook_right_window_01 score=0.979 runner-up=uppercut_right/boxing_uppercut_right_window_04 0.883 margin=0.096
- Strongest expected emit: `hook_right` hook_right via boxing_hook_right_window_02 score=0.961 runner-up=hook_left/boxing_hook_left_window_04 0.864 margin=0.097
- Strongest wrong emit: `uppercut_right` uppercut_right via boxing_uppercut_right_window_01 score=0.874 runner-up=hook_right/boxing_hook_right_window_01 0.856 margin=0.018
- Emitted prototype counts: `boxing_hook_right_window_01` x10, `boxing_hook_left_window_01` x4, `boxing_hook_right_window_02` x3, `boxing_hook_right_window_04` x3, `boxing_straight_left_window_03` x3
- Best-snapshot prototype counts: `boxing_hook_right_window_01` x29, `boxing_hook_left_window_01` x13, `boxing_hook_right_window_04` x10, `boxing_hook_right_window_02` x9, `boxing_straight_left_window_01` x7
- emitted expected hook_right 17 time(s)
- also emitted other attack events: punch_left, punch_left, punch_left, hook_left, hook_left, hook_left, punch_left, hook_left, uppercut_right, punch_left
- peak expected-class score 0.979
- peak winner hook_right via boxing_hook_right_window_01 scored 0.979; runner-up uppercut_right via boxing_uppercut_right_window_04 scored 0.883 (margin 0.096)
- strongest expected emit used boxing_hook_right_window_02 at 0.961 over runner-up boxing_hook_left_window_04 at 0.864 (margin 0.097)
- strongest wrong emit was uppercut_right via boxing_uppercut_right_window_01 at 0.874 over runner-up boxing_hook_right_window_01 at 0.856 (margin 0.018)
- latest matcher reason emit_cooldown_active

Emitted attack events:
- `hook_right` at `1069ms` score=`0.898` prototype=`boxing_hook_right_window_01` class=`hook_right` runner-up=`uppercut_right/boxing_uppercut_right_window_04 0.862` margin=`0.036` backend=`prototype_matcher`
- `punch_left` at `1370ms` score=`0.831` prototype=`boxing_straight_left_window_01` class=`straight_left` runner-up=`uppercut_left/boxing_uppercut_left_window_01 0.821` margin=`0.010` backend=`prototype_matcher`
- `hook_right` at `1888ms` score=`0.741` prototype=`boxing_hook_right_window_04` class=`hook_right` runner-up=`straight_left/boxing_straight_left_window_04 0.730` margin=`0.011` backend=`prototype_matcher`
- `hook_right` at `2192ms` score=`0.926` prototype=`boxing_hook_right_window_01` class=`hook_right` runner-up=`uppercut_right/boxing_uppercut_right_window_04 0.836` margin=`0.090` backend=`prototype_matcher`
- `hook_right` at `2510ms` score=`0.960` prototype=`boxing_hook_right_window_01` class=`hook_right` runner-up=`uppercut_right/boxing_uppercut_right_window_04 0.887` margin=`0.073` backend=`prototype_matcher`
- `punch_left` at `2839ms` score=`0.816` prototype=`boxing_straight_left_window_03` class=`straight_left` runner-up=`uppercut_left/boxing_uppercut_left_window_01 0.806` margin=`0.009` backend=`prototype_matcher`
- `punch_left` at `3143ms` score=`0.728` prototype=`boxing_straight_left_window_03` class=`straight_left` runner-up=`hook_left/boxing_hook_left_window_01 0.700` margin=`0.029` backend=`prototype_matcher`
- `hook_left` at `3577ms` score=`0.781` prototype=`boxing_hook_left_window_01` class=`hook_left` runner-up=`hook_right/boxing_hook_right_window_04 0.763` margin=`0.018` backend=`prototype_matcher`
- `hook_right` at `3879ms` score=`0.961` prototype=`boxing_hook_right_window_02` class=`hook_right` runner-up=`hook_left/boxing_hook_left_window_04 0.864` margin=`0.097` backend=`prototype_matcher`
- `hook_right` at `4193ms` score=`0.911` prototype=`boxing_hook_right_window_02` class=`hook_right` runner-up=`uppercut_right/boxing_uppercut_right_window_03 0.820` margin=`0.090` backend=`prototype_matcher`
- `hook_left` at `4519ms` score=`0.816` prototype=`boxing_hook_left_window_01` class=`hook_left` runner-up=`straight_left/boxing_straight_left_window_03 0.787` margin=`0.030` backend=`prototype_matcher`
- `hook_left` at `5038ms` score=`0.733` prototype=`boxing_hook_left_window_01` class=`hook_left` runner-up=`hook_right/boxing_hook_right_window_04 0.732` margin=`0.001` backend=`prototype_matcher`
- `hook_right` at `5353ms` score=`0.843` prototype=`boxing_hook_right_window_02` class=`hook_right` runner-up=`hook_left/boxing_hook_left_window_01 0.809` margin=`0.034` backend=`prototype_matcher`
- `hook_right` at `5669ms` score=`0.950` prototype=`boxing_hook_right_window_03` class=`hook_right` runner-up=`uppercut_right/boxing_uppercut_right_window_03 0.837` margin=`0.113` backend=`prototype_matcher`
- `hook_right` at `5982ms` score=`0.897` prototype=`boxing_hook_right_window_01` class=`hook_right` runner-up=`uppercut_right/boxing_uppercut_right_window_04 0.826` margin=`0.072` backend=`prototype_matcher`
- `punch_left` at `6305ms` score=`0.722` prototype=`boxing_straight_left_window_03` class=`straight_left` runner-up=`hook_left/boxing_hook_left_window_01 0.714` margin=`0.008` backend=`prototype_matcher`
- `hook_right` at `6851ms` score=`0.787` prototype=`boxing_hook_right_window_04` class=`hook_right` runner-up=`straight_left/boxing_straight_left_window_03 0.689` margin=`0.098` backend=`prototype_matcher`
- `hook_left` at `7158ms` score=`0.851` prototype=`boxing_hook_left_window_01` class=`hook_left` runner-up=`hook_right/boxing_hook_right_window_04 0.840` margin=`0.011` backend=`prototype_matcher`
- `hook_right` at `7471ms` score=`0.946` prototype=`boxing_hook_right_window_01` class=`hook_right` runner-up=`uppercut_right/boxing_uppercut_right_window_04 0.883` margin=`0.063` backend=`prototype_matcher`
- `hook_right` at `7778ms` score=`0.924` prototype=`boxing_hook_right_window_01` class=`hook_right` runner-up=`uppercut_left/boxing_uppercut_left_window_01 0.856` margin=`0.067` backend=`prototype_matcher`
- `hook_right` at `8085ms` score=`0.917` prototype=`boxing_hook_right_window_01` class=`hook_right` runner-up=`uppercut_right/boxing_uppercut_right_window_04 0.860` margin=`0.057` backend=`prototype_matcher`
- `uppercut_right` at `8259ms` score=`0.874` prototype=`boxing_uppercut_right_window_01` class=`uppercut_right` runner-up=`hook_right/boxing_hook_right_window_01 0.856` margin=`0.018` backend=`prototype_matcher`
- `hook_right` at `8488ms` score=`0.920` prototype=`boxing_hook_right_window_01` class=`hook_right` runner-up=`uppercut_right/boxing_uppercut_right_window_01 0.888` margin=`0.033` backend=`prototype_matcher`
- `hook_right` at `8801ms` score=`0.882` prototype=`boxing_hook_right_window_01` class=`hook_right` runner-up=`uppercut_right/boxing_uppercut_right_window_01 0.875` margin=`0.008` backend=`prototype_matcher`
- `hook_right` at `9115ms` score=`0.902` prototype=`boxing_hook_right_window_01` class=`hook_right` runner-up=`uppercut_right/boxing_uppercut_right_window_04 0.862` margin=`0.040` backend=`prototype_matcher`
- `punch_left` at `9447ms` score=`0.759` prototype=`boxing_straight_left_window_01` class=`straight_left` runner-up=`uppercut_left/boxing_uppercut_left_window_01 0.718` margin=`0.041` backend=`prototype_matcher`
- `hook_right` at `9875ms` score=`0.723` prototype=`boxing_hook_right_window_04` class=`hook_right` runner-up=`straight_left/boxing_straight_left_window_04 0.709` margin=`0.014` backend=`prototype_matcher`

### uppercut left

- Fixture: `.testbed/assets/fixtures/boxing/uppercut_left/boxing_guard->uppercut_left_repeat_04_take_01.yaml`
- Source: `.testbed/assets/fixtures/boxing/uppercut_left/boxing_guard->uppercut_left_repeat_04_take_01.mp4`
- Expected event: `uppercut_left`
- Expected class: `uppercut_left`
- Attack events emitted: **29**
- Peak snapshot: uppercut_left via boxing_uppercut_left_window_02 score=1.000 runner-up=uppercut_right/boxing_uppercut_right_window_01 0.867 margin=0.133
- Strongest expected emit: `uppercut_left` uppercut_left via boxing_uppercut_left_window_01 score=1.000 runner-up=uppercut_right/boxing_uppercut_right_window_04 0.895 margin=0.105
- Strongest wrong emit: `uppercut_right` uppercut_right via boxing_uppercut_right_window_01 score=0.908 runner-up=uppercut_left/boxing_uppercut_left_window_02 0.906 margin=0.002
- Emitted prototype counts: `boxing_uppercut_left_window_02` x6, `boxing_uppercut_left_window_03` x6, `boxing_uppercut_left_window_01` x5, `boxing_hook_right_window_01` x3, `boxing_hook_right_window_02` x3
- Best-snapshot prototype counts: `boxing_uppercut_left_window_02` x20, `boxing_uppercut_left_window_03` x16, `boxing_uppercut_left_window_01` x12, `boxing_hook_right_window_04` x9, `boxing_hook_right_window_02` x6
- emitted expected uppercut_left 17 time(s)
- also emitted other attack events: hook_right, hook_right, punch_left, hook_right, hook_right, uppercut_right, hook_right, hook_right, hook_right, hook_right, hook_right, hook_right
- peak expected-class score 1.000
- peak winner uppercut_left via boxing_uppercut_left_window_02 scored 1.000; runner-up uppercut_right via boxing_uppercut_right_window_01 scored 0.867 (margin 0.133)
- strongest expected emit used boxing_uppercut_left_window_01 at 1.000 over runner-up boxing_uppercut_right_window_04 at 0.895 (margin 0.105)
- strongest wrong emit was uppercut_right via boxing_uppercut_right_window_01 at 0.908 over runner-up boxing_uppercut_left_window_02 at 0.906 (margin 0.002)
- latest matcher reason emit_cooldown_active

Emitted attack events:
- `hook_right` at `1077ms` score=`0.735` prototype=`boxing_hook_right_window_01` class=`hook_right` runner-up=`uppercut_right/boxing_uppercut_right_window_03 0.707` margin=`0.028` backend=`prototype_matcher`
- `hook_right` at `1344ms` score=`0.748` prototype=`boxing_hook_right_window_02` class=`hook_right` runner-up=`uppercut_right/boxing_uppercut_right_window_03 0.689` margin=`0.059` backend=`prototype_matcher`
- `uppercut_left` at `1643ms` score=`0.850` prototype=`boxing_uppercut_left_window_02` class=`uppercut_left` runner-up=`hook_right/boxing_hook_right_window_02 0.789` margin=`0.061` backend=`prototype_matcher`
- `uppercut_left` at `1958ms` score=`0.917` prototype=`boxing_uppercut_left_window_01` class=`uppercut_left` runner-up=`uppercut_right/boxing_uppercut_right_window_04 0.828` margin=`0.089` backend=`prototype_matcher`
- `uppercut_left` at `2263ms` score=`1.000` prototype=`boxing_uppercut_left_window_01` class=`uppercut_left` runner-up=`uppercut_right/boxing_uppercut_right_window_04 0.895` margin=`0.105` backend=`prototype_matcher`
- `uppercut_left` at `2563ms` score=`0.924` prototype=`boxing_uppercut_left_window_01` class=`uppercut_left` runner-up=`uppercut_right/boxing_uppercut_right_window_01 0.905` margin=`0.019` backend=`prototype_matcher`
- `punch_left` at `2865ms` score=`0.856` prototype=`boxing_straight_left_window_01` class=`straight_left` runner-up=`uppercut_right/boxing_uppercut_right_window_01 0.810` margin=`0.046` backend=`prototype_matcher`
- `hook_right` at `3175ms` score=`0.728` prototype=`boxing_hook_right_window_04` class=`hook_right` runner-up=`uppercut_right/boxing_uppercut_right_window_03 0.703` margin=`0.025` backend=`prototype_matcher`
- `hook_right` at `3484ms` score=`0.801` prototype=`boxing_hook_right_window_03` class=`hook_right` runner-up=`uppercut_right/boxing_uppercut_right_window_04 0.789` margin=`0.012` backend=`prototype_matcher`
- `uppercut_left` at `3802ms` score=`0.899` prototype=`boxing_uppercut_left_window_03` class=`uppercut_left` runner-up=`uppercut_right/boxing_uppercut_right_window_04 0.789` margin=`0.110` backend=`prototype_matcher`
- `uppercut_left` at `4097ms` score=`0.988` prototype=`boxing_uppercut_left_window_02` class=`uppercut_left` runner-up=`uppercut_right/boxing_uppercut_right_window_01 0.873` margin=`0.115` backend=`prototype_matcher`
- `uppercut_left` at `4406ms` score=`0.953` prototype=`boxing_uppercut_left_window_02` class=`uppercut_left` runner-up=`uppercut_right/boxing_uppercut_right_window_01 0.872` margin=`0.081` backend=`prototype_matcher`
- `uppercut_right` at `4717ms` score=`0.908` prototype=`boxing_uppercut_right_window_01` class=`uppercut_right` runner-up=`uppercut_left/boxing_uppercut_left_window_02 0.906` margin=`0.002` backend=`prototype_matcher`
- `hook_right` at `5230ms` score=`0.716` prototype=`boxing_hook_right_window_04` class=`hook_right` runner-up=`uppercut_right/boxing_uppercut_right_window_03 0.658` margin=`0.058` backend=`prototype_matcher`
- `uppercut_left` at `5542ms` score=`0.877` prototype=`boxing_uppercut_left_window_03` class=`uppercut_left` runner-up=`uppercut_right/boxing_uppercut_right_window_04 0.797` margin=`0.080` backend=`prototype_matcher`
- `uppercut_left` at `5857ms` score=`0.940` prototype=`boxing_uppercut_left_window_03` class=`uppercut_left` runner-up=`straight_right/boxing_straight_right_window_03 0.834` margin=`0.106` backend=`prototype_matcher`
- `uppercut_left` at `6159ms` score=`0.938` prototype=`boxing_uppercut_left_window_03` class=`uppercut_left` runner-up=`uppercut_right/boxing_uppercut_right_window_01 0.851` margin=`0.087` backend=`prototype_matcher`
- `uppercut_left` at `6471ms` score=`0.932` prototype=`boxing_uppercut_left_window_02` class=`uppercut_left` runner-up=`uppercut_right/boxing_uppercut_right_window_04 0.878` margin=`0.054` backend=`prototype_matcher`
- `hook_right` at `6771ms` score=`0.822` prototype=`boxing_hook_right_window_01` class=`hook_right` runner-up=`uppercut_right/boxing_uppercut_right_window_04 0.814` margin=`0.009` backend=`prototype_matcher`
- `hook_right` at `7188ms` score=`0.722` prototype=`boxing_hook_right_window_04` class=`hook_right` runner-up=`uppercut_right/boxing_uppercut_right_window_03 0.659` margin=`0.064` backend=`prototype_matcher`
- `uppercut_left` at `7496ms` score=`0.813` prototype=`boxing_uppercut_left_window_03` class=`uppercut_left` runner-up=`uppercut_right/boxing_uppercut_right_window_04 0.799` margin=`0.015` backend=`prototype_matcher`
- `uppercut_left` at `7799ms` score=`0.873` prototype=`boxing_uppercut_left_window_03` class=`uppercut_left` runner-up=`uppercut_right/boxing_uppercut_right_window_01 0.822` margin=`0.052` backend=`prototype_matcher`
- `uppercut_left` at `8098ms` score=`0.922` prototype=`boxing_uppercut_left_window_01` class=`uppercut_left` runner-up=`uppercut_right/boxing_uppercut_right_window_04 0.894` margin=`0.029` backend=`prototype_matcher`
- `uppercut_left` at `8276ms` score=`0.931` prototype=`boxing_uppercut_left_window_02` class=`uppercut_left` runner-up=`hook_right/boxing_hook_right_window_01 0.909` margin=`0.022` backend=`prototype_matcher`
- `uppercut_left` at `8588ms` score=`0.921` prototype=`boxing_uppercut_left_window_02` class=`uppercut_left` runner-up=`hook_right/boxing_hook_right_window_01 0.913` margin=`0.008` backend=`prototype_matcher`
- `hook_right` at `8899ms` score=`0.840` prototype=`boxing_hook_right_window_01` class=`hook_right` runner-up=`uppercut_right/boxing_uppercut_right_window_01 0.828` margin=`0.012` backend=`prototype_matcher`
- `hook_right` at `9193ms` score=`0.731` prototype=`boxing_hook_right_window_02` class=`hook_right` runner-up=`uppercut_right/boxing_uppercut_right_window_03 0.669` margin=`0.062` backend=`prototype_matcher`
- `hook_right` at `9505ms` score=`0.793` prototype=`boxing_hook_right_window_02` class=`hook_right` runner-up=`uppercut_left/boxing_uppercut_left_window_03 0.757` margin=`0.036` backend=`prototype_matcher`
- `uppercut_left` at `9816ms` score=`0.865` prototype=`boxing_uppercut_left_window_01` class=`uppercut_left` runner-up=`uppercut_right/boxing_uppercut_right_window_04 0.809` margin=`0.057` backend=`prototype_matcher`

### uppercut right

- Fixture: `.testbed/assets/fixtures/boxing/uppercut_right/boxing_guard->uppercut_right_repeat_04_take_01.yaml`
- Source: `.testbed/assets/fixtures/boxing/uppercut_right/boxing_guard->uppercut_right_repeat_04_take_01.mp4`
- Expected event: `uppercut_right`
- Expected class: `uppercut_right`
- Attack events emitted: **26**
- Peak snapshot: uppercut_right via boxing_uppercut_right_window_01 score=1.000 runner-up=straight_left/boxing_straight_left_window_01 0.835 margin=0.165
- Strongest expected emit: `uppercut_right` uppercut_right via boxing_uppercut_right_window_01 score=0.947 runner-up=straight_right/boxing_straight_right_window_01 0.859 margin=0.088
- Strongest wrong emit: `hook_right` hook_right via boxing_hook_right_window_01 score=0.934 runner-up=uppercut_right/boxing_uppercut_right_window_04 0.867 margin=0.067
- Emitted prototype counts: `boxing_uppercut_right_window_01` x9, `boxing_hook_left_window_03` x5, `boxing_hook_right_window_01` x2, `boxing_uppercut_right_window_04` x2, `boxing_hook_left_window_01` x1
- Best-snapshot prototype counts: `boxing_uppercut_right_window_01` x26, `boxing_hook_right_window_01` x11, `boxing_hook_left_window_03` x9, `boxing_hook_left_window_01` x8, `boxing_hook_left_window_02` x8
- emitted expected uppercut_right 13 time(s)
- also emitted other attack events: uppercut_left, hook_left, hook_left, hook_left, hook_left, hook_left, hook_right, hook_right, hook_left, hook_left, hook_right, hook_left, punch_left
- peak expected-class score 1.000
- peak winner uppercut_right via boxing_uppercut_right_window_01 scored 1.000; runner-up straight_left via boxing_straight_left_window_01 scored 0.835 (margin 0.165)
- strongest expected emit used boxing_uppercut_right_window_01 at 0.947 over runner-up boxing_straight_right_window_01 at 0.859 (margin 0.088)
- strongest wrong emit was hook_right via boxing_hook_right_window_01 at 0.934 over runner-up boxing_uppercut_right_window_04 at 0.867 (margin 0.067)
- latest matcher reason step_wait

Emitted attack events:
- `uppercut_left` at `1107ms` score=`0.730` prototype=`boxing_uppercut_left_window_01` class=`uppercut_left` runner-up=`hook_left/boxing_hook_left_window_04 0.702` margin=`0.028` backend=`prototype_matcher`
- `hook_left` at `1401ms` score=`0.792` prototype=`boxing_hook_left_window_03` class=`hook_left` runner-up=`straight_left/boxing_straight_left_window_03 0.682` margin=`0.110` backend=`prototype_matcher`
- `uppercut_right` at `1691ms` score=`0.752` prototype=`boxing_uppercut_right_window_03` class=`uppercut_right` runner-up=`straight_left/boxing_straight_left_window_04 0.747` margin=`0.006` backend=`prototype_matcher`
- `uppercut_right` at `2001ms` score=`0.947` prototype=`boxing_uppercut_right_window_01` class=`uppercut_right` runner-up=`straight_right/boxing_straight_right_window_01 0.866` margin=`0.080` backend=`prototype_matcher`
- `uppercut_right` at `2320ms` score=`0.947` prototype=`boxing_uppercut_right_window_01` class=`uppercut_right` runner-up=`straight_right/boxing_straight_right_window_01 0.859` margin=`0.088` backend=`prototype_matcher`
- `uppercut_right` at `2636ms` score=`0.934` prototype=`boxing_uppercut_right_window_01` class=`uppercut_right` runner-up=`hook_right/boxing_hook_right_window_01 0.871` margin=`0.063` backend=`prototype_matcher`
- `hook_left` at `3272ms` score=`0.801` prototype=`boxing_hook_left_window_03` class=`hook_left` runner-up=`straight_left/boxing_straight_left_window_03 0.726` margin=`0.075` backend=`prototype_matcher`
- `uppercut_right` at `3589ms` score=`0.900` prototype=`boxing_uppercut_right_window_02` class=`uppercut_right` runner-up=`straight_left/boxing_straight_left_window_01 0.805` margin=`0.095` backend=`prototype_matcher`
- `uppercut_right` at `3913ms` score=`0.909` prototype=`boxing_uppercut_right_window_01` class=`uppercut_right` runner-up=`straight_right/boxing_straight_right_window_01 0.871` margin=`0.038` backend=`prototype_matcher`
- `uppercut_right` at `4224ms` score=`0.928` prototype=`boxing_uppercut_right_window_01` class=`uppercut_right` runner-up=`straight_right/boxing_straight_right_window_01 0.857` margin=`0.071` backend=`prototype_matcher`
- `hook_left` at `4557ms` score=`0.811` prototype=`boxing_hook_left_window_04` class=`hook_left` runner-up=`straight_left/boxing_straight_left_window_03 0.792` margin=`0.019` backend=`prototype_matcher`
- `hook_left` at `4871ms` score=`0.842` prototype=`boxing_hook_left_window_03` class=`hook_left` runner-up=`straight_left/boxing_straight_left_window_03 0.770` margin=`0.071` backend=`prototype_matcher`
- `hook_left` at `5179ms` score=`0.860` prototype=`boxing_hook_left_window_01` class=`hook_left` runner-up=`straight_left/boxing_straight_left_window_03 0.827` margin=`0.033` backend=`prototype_matcher`
- `hook_right` at `5502ms` score=`0.929` prototype=`boxing_hook_right_window_01` class=`hook_right` runner-up=`uppercut_right/boxing_uppercut_right_window_03 0.883` margin=`0.046` backend=`prototype_matcher`
- `hook_right` at `5834ms` score=`0.864` prototype=`boxing_hook_right_window_02` class=`hook_right` runner-up=`uppercut_right/boxing_uppercut_right_window_03 0.854` margin=`0.010` backend=`prototype_matcher`
- `hook_left` at `6263ms` score=`0.704` prototype=`boxing_hook_left_window_03` class=`hook_left` runner-up=`straight_left/boxing_straight_left_window_03 0.578` margin=`0.126` backend=`prototype_matcher`
- `hook_left` at `6563ms` score=`0.835` prototype=`boxing_hook_left_window_02` class=`hook_left` runner-up=`straight_left/boxing_straight_left_window_04 0.706` margin=`0.129` backend=`prototype_matcher`
- `uppercut_right` at `6867ms` score=`0.893` prototype=`boxing_uppercut_right_window_01` class=`uppercut_right` runner-up=`straight_left/boxing_straight_left_window_01 0.847` margin=`0.046` backend=`prototype_matcher`
- `uppercut_right` at `7306ms` score=`0.925` prototype=`boxing_uppercut_right_window_04` class=`uppercut_right` runner-up=`hook_right/boxing_hook_right_window_01 0.899` margin=`0.026` backend=`prototype_matcher`
- `uppercut_right` at `7540ms` score=`0.910` prototype=`boxing_uppercut_right_window_04` class=`uppercut_right` runner-up=`hook_right/boxing_hook_right_window_01 0.907` margin=`0.004` backend=`prototype_matcher`
- `hook_right` at `7864ms` score=`0.934` prototype=`boxing_hook_right_window_01` class=`hook_right` runner-up=`uppercut_right/boxing_uppercut_right_window_04 0.867` margin=`0.067` backend=`prototype_matcher`
- `hook_left` at `8415ms` score=`0.792` prototype=`boxing_hook_left_window_03` class=`hook_left` runner-up=`straight_left/boxing_straight_left_window_03 0.682` margin=`0.110` backend=`prototype_matcher`
- `punch_left` at `8706ms` score=`0.767` prototype=`boxing_straight_left_window_01` class=`straight_left` runner-up=`uppercut_right/boxing_uppercut_right_window_03 0.744` margin=`0.023` backend=`prototype_matcher`
- `uppercut_right` at `9014ms` score=`0.922` prototype=`boxing_uppercut_right_window_01` class=`uppercut_right` runner-up=`straight_right/boxing_straight_right_window_01 0.866` margin=`0.055` backend=`prototype_matcher`
- `uppercut_right` at `9331ms` score=`0.947` prototype=`boxing_uppercut_right_window_01` class=`uppercut_right` runner-up=`straight_right/boxing_straight_right_window_01 0.845` margin=`0.102` backend=`prototype_matcher`
- `uppercut_right` at `9650ms` score=`0.934` prototype=`boxing_uppercut_right_window_01` class=`uppercut_right` runner-up=`hook_right/boxing_hook_right_window_01 0.871` margin=`0.063` backend=`prototype_matcher`

### negative control - running in place

- Fixture: `.testbed/assets/fixtures/boxing/run_in_place/boxing_guard->run_in_place_repeat_01_take_01.yaml`
- Source: `.testbed/assets/fixtures/boxing/run_in_place/boxing_guard->run_in_place_repeat_01_take_01.mp4`
- Expected event: `None`
- Expected class: `None`
- Attack events emitted: **29**
- Peak snapshot: hook_left via boxing_hook_left_window_01 score=0.894 runner-up=straight_left/boxing_straight_left_window_03 0.846 margin=0.049
- Strongest wrong emit: `hook_right` hook_right via boxing_hook_right_window_01 score=0.894 runner-up=uppercut_right/boxing_uppercut_right_window_03 0.825 margin=0.069
- Emitted prototype counts: `boxing_hook_left_window_01` x17, `boxing_hook_left_window_03` x4, `boxing_straight_left_window_03` x4, `boxing_straight_left_window_01` x2, `boxing_hook_right_window_01` x1
- Best-snapshot prototype counts: `boxing_hook_left_window_01` x57, `boxing_hook_left_window_03` x10, `boxing_straight_left_window_01` x6, `boxing_straight_left_window_02` x4, `boxing_straight_left_window_03` x4
- negative control still emitted attack events: punch_left, punch_left, hook_left, hook_left, hook_left, hook_left, hook_left, hook_left, hook_left, hook_left, hook_left, punch_left, hook_left, hook_left, hook_right, punch_left, punch_left, punch_left, hook_left, hook_left, hook_left, hook_left, hook_left, hook_left, hook_left, hook_left, hook_left, punch_left, hook_left
- peak winner hook_left via boxing_hook_left_window_01 scored 0.894; runner-up straight_left via boxing_straight_left_window_03 scored 0.846 (margin 0.049)
- strongest wrong emit was hook_right via boxing_hook_right_window_01 at 0.894 over runner-up boxing_uppercut_right_window_03 at 0.825 (margin 0.069)
- latest matcher reason step_wait

Emitted attack events:
- `punch_left` at `1106ms` score=`0.880` prototype=`boxing_straight_left_window_01` class=`straight_left` runner-up=`uppercut_left/boxing_uppercut_left_window_01 0.824` margin=`0.056` backend=`prototype_matcher`
- `punch_left` at `1315ms` score=`0.820` prototype=`boxing_straight_left_window_03` class=`straight_left` runner-up=`hook_left/boxing_hook_left_window_01 0.814` margin=`0.006` backend=`prototype_matcher`
- `hook_left` at `1626ms` score=`0.752` prototype=`boxing_hook_left_window_03` class=`hook_left` runner-up=`straight_left/boxing_straight_left_window_02 0.712` margin=`0.040` backend=`prototype_matcher`
- `hook_left` at `1936ms` score=`0.791` prototype=`boxing_hook_left_window_03` class=`hook_left` runner-up=`straight_left/boxing_straight_left_window_03 0.753` margin=`0.038` backend=`prototype_matcher`
- `hook_left` at `2249ms` score=`0.840` prototype=`boxing_hook_left_window_01` class=`hook_left` runner-up=`straight_left/boxing_straight_left_window_03 0.797` margin=`0.043` backend=`prototype_matcher`
- `hook_left` at `2555ms` score=`0.868` prototype=`boxing_hook_left_window_01` class=`hook_left` runner-up=`straight_left/boxing_straight_left_window_03 0.821` margin=`0.047` backend=`prototype_matcher`
- `hook_left` at `2865ms` score=`0.868` prototype=`boxing_hook_left_window_01` class=`hook_left` runner-up=`straight_left/boxing_straight_left_window_03 0.813` margin=`0.055` backend=`prototype_matcher`
- `hook_left` at `3169ms` score=`0.837` prototype=`boxing_hook_left_window_01` class=`hook_left` runner-up=`straight_left/boxing_straight_left_window_03 0.821` margin=`0.016` backend=`prototype_matcher`
- `hook_left` at `3482ms` score=`0.864` prototype=`boxing_hook_left_window_01` class=`hook_left` runner-up=`straight_left/boxing_straight_left_window_03 0.811` margin=`0.053` backend=`prototype_matcher`
- `hook_left` at `3788ms` score=`0.866` prototype=`boxing_hook_left_window_01` class=`hook_left` runner-up=`straight_left/boxing_straight_left_window_03 0.834` margin=`0.032` backend=`prototype_matcher`
- `hook_left` at `4088ms` score=`0.852` prototype=`boxing_hook_left_window_01` class=`hook_left` runner-up=`straight_left/boxing_straight_left_window_03 0.817` margin=`0.035` backend=`prototype_matcher`
- `punch_left` at `4402ms` score=`0.806` prototype=`boxing_straight_left_window_03` class=`straight_left` runner-up=`hook_left/boxing_hook_left_window_01 0.801` margin=`0.005` backend=`prototype_matcher`
- `hook_left` at `4707ms` score=`0.833` prototype=`boxing_hook_left_window_01` class=`hook_left` runner-up=`straight_left/boxing_straight_left_window_03 0.793` margin=`0.039` backend=`prototype_matcher`
- `hook_left` at `5003ms` score=`0.867` prototype=`boxing_hook_left_window_01` class=`hook_left` runner-up=`straight_left/boxing_straight_left_window_03 0.832` margin=`0.035` backend=`prototype_matcher`
- `hook_right` at `5426ms` score=`0.894` prototype=`boxing_hook_right_window_01` class=`hook_right` runner-up=`uppercut_right/boxing_uppercut_right_window_03 0.825` margin=`0.069` backend=`prototype_matcher`
- `punch_left` at `5731ms` score=`0.848` prototype=`boxing_straight_left_window_04` class=`straight_left` runner-up=`hook_right/boxing_hook_right_window_01 0.839` margin=`0.009` backend=`prototype_matcher`
- `punch_left` at `6043ms` score=`0.877` prototype=`boxing_straight_left_window_01` class=`straight_left` runner-up=`uppercut_right/boxing_uppercut_right_window_03 0.820` margin=`0.057` backend=`prototype_matcher`
- `punch_left` at `6356ms` score=`0.820` prototype=`boxing_straight_left_window_03` class=`straight_left` runner-up=`hook_left/boxing_hook_left_window_01 0.814` margin=`0.006` backend=`prototype_matcher`
- `hook_left` at `6662ms` score=`0.752` prototype=`boxing_hook_left_window_03` class=`hook_left` runner-up=`straight_left/boxing_straight_left_window_02 0.720` margin=`0.032` backend=`prototype_matcher`
- `hook_left` at `6971ms` score=`0.794` prototype=`boxing_hook_left_window_03` class=`hook_left` runner-up=`straight_left/boxing_straight_left_window_03 0.740` margin=`0.054` backend=`prototype_matcher`
- `hook_left` at `7280ms` score=`0.839` prototype=`boxing_hook_left_window_01` class=`hook_left` runner-up=`straight_left/boxing_straight_left_window_03 0.797` margin=`0.042` backend=`prototype_matcher`
- `hook_left` at `7583ms` score=`0.861` prototype=`boxing_hook_left_window_01` class=`hook_left` runner-up=`straight_left/boxing_straight_left_window_03 0.813` margin=`0.048` backend=`prototype_matcher`
- `hook_left` at `7891ms` score=`0.865` prototype=`boxing_hook_left_window_01` class=`hook_left` runner-up=`straight_left/boxing_straight_left_window_03 0.811` margin=`0.054` backend=`prototype_matcher`
- `hook_left` at `8202ms` score=`0.837` prototype=`boxing_hook_left_window_01` class=`hook_left` runner-up=`straight_left/boxing_straight_left_window_03 0.821` margin=`0.016` backend=`prototype_matcher`
- `hook_left` at `8518ms` score=`0.863` prototype=`boxing_hook_left_window_01` class=`hook_left` runner-up=`straight_left/boxing_straight_left_window_03 0.811` margin=`0.052` backend=`prototype_matcher`
- `hook_left` at `8819ms` score=`0.872` prototype=`boxing_hook_left_window_01` class=`hook_left` runner-up=`straight_left/boxing_straight_left_window_03 0.837` margin=`0.035` backend=`prototype_matcher`
- `hook_left` at `9125ms` score=`0.852` prototype=`boxing_hook_left_window_01` class=`hook_left` runner-up=`straight_left/boxing_straight_left_window_03 0.817` margin=`0.035` backend=`prototype_matcher`
- `punch_left` at `9444ms` score=`0.806` prototype=`boxing_straight_left_window_03` class=`straight_left` runner-up=`hook_left/boxing_hook_left_window_01 0.801` margin=`0.005` backend=`prototype_matcher`
- `hook_left` at `9745ms` score=`0.819` prototype=`boxing_hook_left_window_01` class=`hook_left` runner-up=`straight_left/boxing_straight_left_window_03 0.792` margin=`0.027` backend=`prototype_matcher`
