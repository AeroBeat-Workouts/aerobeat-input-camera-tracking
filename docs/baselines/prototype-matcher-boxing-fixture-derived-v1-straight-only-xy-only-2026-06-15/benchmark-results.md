# Prototype Matcher Fixture Benchmark

- Benchmark ID: `prototype_matcher_boxing_fixture_derived_v1_straight_only`
- Library ID: `boxing_side_aware_fixture_derived_v1_straight_only`
- Profile: `boxing`
- Generated At: `2026-06-15T20:17:48-04:00`
- Runner: `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/scripts/run_prototype_matcher_fixture_benchmark.py`

## Aggregate

- Fixture count: **3**
- Negative controls clean: **0 / 1**
- Negative-control false-positive classes: `straight_left` x27
- Negative-control false-positive prototypes: `boxing_straight_left_window_03` x21, `boxing_straight_left_window_01` x4, `boxing_straight_left_window_02` x1, `boxing_straight_left_window_04` x1

## Per Fixture

### straight left

- Fixture: `.testbed/assets/fixtures/boxing/straight_left/boxing_guard->straight_left_repeat_04_take_01.yaml`
- Source: `.testbed/assets/fixtures/boxing/straight_left/boxing_guard->straight_left_repeat_04_take_01.mp4`
- Expected event: `punch_left`
- Expected class: `straight_left`
- Attack events emitted: **24**
- Peak snapshot: straight_left via boxing_straight_left_window_01 score=0.969 runner-up=straight_right/boxing_straight_right_window_01 0.813 margin=0.155
- Strongest expected emit: `punch_left` straight_left via boxing_straight_left_window_01 score=0.947 runner-up=straight_right/boxing_straight_right_window_01 0.815 margin=0.132
- Strongest wrong emit: `punch_right` straight_right via boxing_straight_right_window_01 score=0.838 runner-up=straight_left/boxing_straight_left_window_04 0.586 margin=0.252
- Emitted prototype counts: `boxing_straight_right_window_01` x12, `boxing_straight_left_window_01` x7, `boxing_straight_left_window_03` x3, `boxing_straight_left_window_04` x2
- Best-snapshot prototype counts: `boxing_straight_right_window_01` x45, `boxing_straight_left_window_01` x18, `boxing_straight_left_window_04` x9, `boxing_straight_left_window_03` x7, `boxing_straight_left_window_02` x2
- emitted expected punch_left 12 time(s)
- also emitted other attack events: punch_right, punch_right, punch_right, punch_right, punch_right, punch_right, punch_right, punch_right, punch_right, punch_right, punch_right, punch_right
- peak expected-class score 0.969
- peak winner straight_left via boxing_straight_left_window_01 scored 0.969; runner-up straight_right via boxing_straight_right_window_01 scored 0.813 (margin 0.155)
- strongest expected emit used boxing_straight_left_window_01 at 0.947 over runner-up boxing_straight_right_window_01 at 0.815 (margin 0.132)
- strongest wrong emit was punch_right via boxing_straight_right_window_01 at 0.838 over runner-up boxing_straight_left_window_04 at 0.586 (margin 0.252)
- latest matcher reason step_wait

Emitted attack events:
- `punch_right` at `1115ms` score=`0.789` prototype=`boxing_straight_right_window_01` class=`straight_right` runner-up=`straight_left/boxing_straight_left_window_04 0.559` margin=`0.230` backend=`prototype_matcher`
- `punch_right` at `1348ms` score=`0.811` prototype=`boxing_straight_right_window_01` class=`straight_right` runner-up=`straight_left/boxing_straight_left_window_01 0.653` margin=`0.158` backend=`prototype_matcher`
- `punch_left` at `2108ms` score=`0.811` prototype=`boxing_straight_left_window_04` class=`straight_left` runner-up=`straight_right/boxing_straight_right_window_01 0.646` margin=`0.165` backend=`prototype_matcher`
- `punch_left` at `2425ms` score=`0.930` prototype=`boxing_straight_left_window_01` class=`straight_left` runner-up=`straight_right/boxing_straight_right_window_01 0.806` margin=`0.124` backend=`prototype_matcher`
- `punch_right` at `2746ms` score=`0.771` prototype=`boxing_straight_right_window_01` class=`straight_right` runner-up=`straight_left/boxing_straight_left_window_04 0.572` margin=`0.199` backend=`prototype_matcher`
- `punch_left` at `3252ms` score=`0.770` prototype=`boxing_straight_left_window_01` class=`straight_left` runner-up=`straight_right/boxing_straight_right_window_01 0.620` margin=`0.150` backend=`prototype_matcher`
- `punch_left` at `3565ms` score=`0.910` prototype=`boxing_straight_left_window_01` class=`straight_left` runner-up=`straight_right/boxing_straight_right_window_01 0.779` margin=`0.131` backend=`prototype_matcher`
- `punch_right` at `3875ms` score=`0.715` prototype=`boxing_straight_right_window_01` class=`straight_right` runner-up=`straight_left/boxing_straight_left_window_02 0.681` margin=`0.034` backend=`prototype_matcher`
- `punch_right` at `4193ms` score=`0.725` prototype=`boxing_straight_right_window_01` class=`straight_right` runner-up=`no_punch/ 0.000` margin=`0.725` backend=`prototype_matcher`
- `punch_left` at `4499ms` score=`0.850` prototype=`boxing_straight_left_window_03` class=`straight_left` runner-up=`straight_right/boxing_straight_right_window_01 0.607` margin=`0.243` backend=`prototype_matcher`
- `punch_left` at `4803ms` score=`0.934` prototype=`boxing_straight_left_window_03` class=`straight_left` runner-up=`straight_right/boxing_straight_right_window_01 0.683` margin=`0.251` backend=`prototype_matcher`
- `punch_left` at `5117ms` score=`0.843` prototype=`boxing_straight_left_window_03` class=`straight_left` runner-up=`straight_right/boxing_straight_right_window_01 0.615` margin=`0.228` backend=`prototype_matcher`
- `punch_right` at `5435ms` score=`0.751` prototype=`boxing_straight_right_window_01` class=`straight_right` runner-up=`no_punch/ 0.000` margin=`0.751` backend=`prototype_matcher`
- `punch_left` at `5847ms` score=`0.809` prototype=`boxing_straight_left_window_01` class=`straight_left` runner-up=`straight_right/boxing_straight_right_window_01 0.674` margin=`0.135` backend=`prototype_matcher`
- `punch_left` at `6143ms` score=`0.905` prototype=`boxing_straight_left_window_01` class=`straight_left` runner-up=`straight_right/boxing_straight_right_window_01 0.691` margin=`0.214` backend=`prototype_matcher`
- `punch_right` at `6562ms` score=`0.816` prototype=`boxing_straight_right_window_01` class=`straight_right` runner-up=`straight_left/boxing_straight_left_window_04 0.643` margin=`0.173` backend=`prototype_matcher`
- `punch_right` at `6861ms` score=`0.816` prototype=`boxing_straight_right_window_01` class=`straight_right` runner-up=`straight_left/boxing_straight_left_window_04 0.611` margin=`0.205` backend=`prototype_matcher`
- `punch_right` at `7170ms` score=`0.783` prototype=`boxing_straight_right_window_01` class=`straight_right` runner-up=`straight_left/boxing_straight_left_window_04 0.585` margin=`0.198` backend=`prototype_matcher`
- `punch_right` at `7465ms` score=`0.838` prototype=`boxing_straight_right_window_01` class=`straight_right` runner-up=`straight_left/boxing_straight_left_window_04 0.586` margin=`0.252` backend=`prototype_matcher`
- `punch_right` at `7768ms` score=`0.722` prototype=`boxing_straight_right_window_01` class=`straight_right` runner-up=`straight_left/boxing_straight_left_window_04 0.561` margin=`0.161` backend=`prototype_matcher`
- `punch_left` at `8337ms` score=`0.852` prototype=`boxing_straight_left_window_04` class=`straight_left` runner-up=`straight_right/boxing_straight_right_window_01 0.666` margin=`0.186` backend=`prototype_matcher`
- `punch_left` at `8688ms` score=`0.947` prototype=`boxing_straight_left_window_01` class=`straight_left` runner-up=`straight_right/boxing_straight_right_window_01 0.815` margin=`0.132` backend=`prototype_matcher`
- `punch_right` at `9057ms` score=`0.751` prototype=`boxing_straight_right_window_01` class=`straight_right` runner-up=`straight_left/boxing_straight_left_window_04 0.527` margin=`0.224` backend=`prototype_matcher`
- `punch_left` at `9611ms` score=`0.770` prototype=`boxing_straight_left_window_01` class=`straight_left` runner-up=`straight_right/boxing_straight_right_window_01 0.620` margin=`0.150` backend=`prototype_matcher`

### straight right

- Fixture: `.testbed/assets/fixtures/boxing/straight_right/boxing_guard->straight_right_repeat_04_take_01.yaml`
- Source: `.testbed/assets/fixtures/boxing/straight_right/boxing_guard->straight_right_repeat_04_take_01.mp4`
- Expected event: `punch_right`
- Expected class: `straight_right`
- Attack events emitted: **29**
- Peak snapshot: straight_right via boxing_straight_right_window_01 score=1.000 runner-up=straight_left/boxing_straight_left_window_01 0.586 margin=0.414
- Strongest expected emit: `punch_right` straight_right via boxing_straight_right_window_01 score=1.000 runner-up=straight_left/boxing_straight_left_window_01 0.586 margin=0.414
- Emitted prototype counts: `boxing_straight_right_window_04` x21, `boxing_straight_right_window_01` x4, `boxing_straight_right_window_02` x3, `boxing_straight_right_window_03` x1
- Best-snapshot prototype counts: `boxing_straight_right_window_04` x36, `boxing_straight_left_window_01` x13, `boxing_straight_right_window_01` x10, `boxing_straight_right_window_02` x10, `boxing_straight_right_window_03` x3
- emitted expected punch_right 29 time(s)
- peak expected-class score 1.000
- peak winner straight_right via boxing_straight_right_window_01 scored 1.000; runner-up straight_left via boxing_straight_left_window_01 scored 0.586 (margin 0.414)
- strongest expected emit used boxing_straight_right_window_01 at 1.000 over runner-up boxing_straight_left_window_01 at 0.586 (margin 0.414)
- latest matcher reason emit_cooldown_active

Emitted attack events:
- `punch_right` at `1113ms` score=`0.775` prototype=`boxing_straight_right_window_04` class=`straight_right` runner-up=`straight_left/boxing_straight_left_window_01 0.552` margin=`0.223` backend=`prototype_matcher`
- `punch_right` at `1274ms` score=`0.837` prototype=`boxing_straight_right_window_04` class=`straight_right` runner-up=`straight_left/boxing_straight_left_window_01 0.518` margin=`0.319` backend=`prototype_matcher`
- `punch_right` at `1502ms` score=`0.901` prototype=`boxing_straight_right_window_01` class=`straight_right` runner-up=`straight_left/boxing_straight_left_window_01 0.524` margin=`0.377` backend=`prototype_matcher`
- `punch_right` at `1750ms` score=`1.000` prototype=`boxing_straight_right_window_01` class=`straight_right` runner-up=`straight_left/boxing_straight_left_window_01 0.586` margin=`0.414` backend=`prototype_matcher`
- `punch_right` at `2251ms` score=`0.727` prototype=`boxing_straight_right_window_04` class=`straight_right` runner-up=`straight_left/boxing_straight_left_window_01 0.639` margin=`0.088` backend=`prototype_matcher`
- `punch_right` at `2502ms` score=`0.868` prototype=`boxing_straight_right_window_04` class=`straight_right` runner-up=`straight_left/boxing_straight_left_window_04 0.616` margin=`0.253` backend=`prototype_matcher`
- `punch_right` at `2754ms` score=`0.809` prototype=`boxing_straight_right_window_04` class=`straight_right` runner-up=`straight_left/boxing_straight_left_window_01 0.658` margin=`0.151` backend=`prototype_matcher`
- `punch_right` at `3002ms` score=`0.919` prototype=`boxing_straight_right_window_02` class=`straight_right` runner-up=`straight_left/boxing_straight_left_window_04 0.637` margin=`0.281` backend=`prototype_matcher`
- `punch_right` at `3628ms` score=`0.762` prototype=`boxing_straight_right_window_04` class=`straight_right` runner-up=`straight_left/boxing_straight_left_window_01 0.716` margin=`0.046` backend=`prototype_matcher`
- `punch_right` at `3879ms` score=`0.934` prototype=`boxing_straight_right_window_04` class=`straight_right` runner-up=`straight_left/boxing_straight_left_window_04 0.657` margin=`0.277` backend=`prototype_matcher`
- `punch_right` at `4131ms` score=`0.914` prototype=`boxing_straight_right_window_01` class=`straight_right` runner-up=`straight_left/boxing_straight_left_window_01 0.714` margin=`0.200` backend=`prototype_matcher`
- `punch_right` at `4380ms` score=`0.907` prototype=`boxing_straight_right_window_04` class=`straight_right` runner-up=`straight_left/boxing_straight_left_window_01 0.575` margin=`0.333` backend=`prototype_matcher`
- `punch_right` at `5005ms` score=`0.792` prototype=`boxing_straight_right_window_04` class=`straight_right` runner-up=`straight_left/boxing_straight_left_window_01 0.712` margin=`0.079` backend=`prototype_matcher`
- `punch_right` at `5255ms` score=`0.927` prototype=`boxing_straight_right_window_04` class=`straight_right` runner-up=`straight_left/boxing_straight_left_window_01 0.637` margin=`0.290` backend=`prototype_matcher`
- `punch_right` at `5506ms` score=`0.943` prototype=`boxing_straight_right_window_04` class=`straight_right` runner-up=`straight_left/boxing_straight_left_window_01 0.697` margin=`0.246` backend=`prototype_matcher`
- `punch_right` at `5754ms` score=`0.950` prototype=`boxing_straight_right_window_04` class=`straight_right` runner-up=`straight_left/boxing_straight_left_window_01 0.701` margin=`0.250` backend=`prototype_matcher`
- `punch_right` at `6104ms` score=`0.912` prototype=`boxing_straight_right_window_04` class=`straight_right` runner-up=`straight_left/boxing_straight_left_window_01 0.538` margin=`0.375` backend=`prototype_matcher`
- `punch_right` at `6350ms` score=`0.850` prototype=`boxing_straight_right_window_02` class=`straight_right` runner-up=`straight_left/boxing_straight_left_window_01 0.530` margin=`0.321` backend=`prototype_matcher`
- `punch_right` at `6852ms` score=`0.734` prototype=`boxing_straight_right_window_04` class=`straight_right` runner-up=`straight_left/boxing_straight_left_window_01 0.564` margin=`0.170` backend=`prototype_matcher`
- `punch_right` at `7102ms` score=`0.803` prototype=`boxing_straight_right_window_04` class=`straight_right` runner-up=`straight_left/boxing_straight_left_window_01 0.532` margin=`0.271` backend=`prototype_matcher`
- `punch_right` at `7352ms` score=`0.881` prototype=`boxing_straight_right_window_04` class=`straight_right` runner-up=`straight_left/boxing_straight_left_window_01 0.550` margin=`0.331` backend=`prototype_matcher`
- `punch_right` at `7604ms` score=`0.921` prototype=`boxing_straight_right_window_01` class=`straight_right` runner-up=`straight_left/boxing_straight_left_window_01 0.522` margin=`0.398` backend=`prototype_matcher`
- `punch_right` at `7854ms` score=`0.786` prototype=`boxing_straight_right_window_03` class=`straight_right` runner-up=`straight_left/boxing_straight_left_window_01 0.563` margin=`0.224` backend=`prototype_matcher`
- `punch_right` at `8227ms` score=`0.727` prototype=`boxing_straight_right_window_04` class=`straight_right` runner-up=`straight_left/boxing_straight_left_window_01 0.639` margin=`0.088` backend=`prototype_matcher`
- `punch_right` at `8477ms` score=`0.868` prototype=`boxing_straight_right_window_04` class=`straight_right` runner-up=`straight_left/boxing_straight_left_window_04 0.616` margin=`0.253` backend=`prototype_matcher`
- `punch_right` at `8726ms` score=`0.809` prototype=`boxing_straight_right_window_04` class=`straight_right` runner-up=`straight_left/boxing_straight_left_window_01 0.658` margin=`0.151` backend=`prototype_matcher`
- `punch_right` at `8978ms` score=`0.919` prototype=`boxing_straight_right_window_02` class=`straight_right` runner-up=`straight_left/boxing_straight_left_window_04 0.637` margin=`0.281` backend=`prototype_matcher`
- `punch_right` at `9603ms` score=`0.762` prototype=`boxing_straight_right_window_04` class=`straight_right` runner-up=`straight_left/boxing_straight_left_window_01 0.716` margin=`0.046` backend=`prototype_matcher`
- `punch_right` at `9856ms` score=`0.934` prototype=`boxing_straight_right_window_04` class=`straight_right` runner-up=`straight_left/boxing_straight_left_window_04 0.657` margin=`0.277` backend=`prototype_matcher`

### negative control - running in place

- Fixture: `.testbed/assets/fixtures/boxing/run_in_place/boxing_guard->run_in_place_repeat_01_take_01.yaml`
- Source: `.testbed/assets/fixtures/boxing/run_in_place/boxing_guard->run_in_place_repeat_01_take_01.mp4`
- Expected event: `None`
- Expected class: `None`
- Attack events emitted: **27**
- Peak snapshot: straight_left via boxing_straight_left_window_01 score=0.880 runner-up=straight_right/boxing_straight_right_window_01 0.577 margin=0.303
- Strongest wrong emit: `punch_left` straight_left via boxing_straight_left_window_01 score=0.873 runner-up=straight_right/boxing_straight_right_window_01 0.557 margin=0.316
- Emitted prototype counts: `boxing_straight_left_window_03` x21, `boxing_straight_left_window_01` x4, `boxing_straight_left_window_02` x1, `boxing_straight_left_window_04` x1
- Best-snapshot prototype counts: `boxing_straight_left_window_03` x68, `boxing_straight_left_window_01` x10, `boxing_straight_left_window_02` x5, `boxing_straight_left_window_04` x3
- negative control still emitted attack events: punch_left, punch_left, punch_left, punch_left, punch_left, punch_left, punch_left, punch_left, punch_left, punch_left, punch_left, punch_left, punch_left, punch_left, punch_left, punch_left, punch_left, punch_left, punch_left, punch_left, punch_left, punch_left, punch_left, punch_left, punch_left, punch_left, punch_left
- peak winner straight_left via boxing_straight_left_window_01 scored 0.880; runner-up straight_right via boxing_straight_right_window_01 scored 0.577 (margin 0.303)
- strongest wrong emit was punch_left via boxing_straight_left_window_01 at 0.873 over runner-up boxing_straight_right_window_01 at 0.557 (margin 0.316)
- latest matcher reason step_wait

Emitted attack events:
- `punch_left` at `1126ms` score=`0.873` prototype=`boxing_straight_left_window_01` class=`straight_left` runner-up=`straight_right/boxing_straight_right_window_01 0.557` margin=`0.316` backend=`prototype_matcher`
- `punch_left` at `1374ms` score=`0.765` prototype=`boxing_straight_left_window_02` class=`straight_left` runner-up=`straight_right/boxing_straight_right_window_01 0.410` margin=`0.355` backend=`prototype_matcher`
- `punch_left` at `2100ms` score=`0.723` prototype=`boxing_straight_left_window_03` class=`straight_left` runner-up=`straight_right/boxing_straight_right_window_01 0.204` margin=`0.519` backend=`prototype_matcher`
- `punch_left` at `2411ms` score=`0.738` prototype=`boxing_straight_left_window_03` class=`straight_left` runner-up=`straight_right/boxing_straight_right_window_01 0.268` margin=`0.470` backend=`prototype_matcher`
- `punch_left` at `2719ms` score=`0.750` prototype=`boxing_straight_left_window_03` class=`straight_left` runner-up=`straight_right/boxing_straight_right_window_01 0.288` margin=`0.461` backend=`prototype_matcher`
- `punch_left` at `3027ms` score=`0.762` prototype=`boxing_straight_left_window_03` class=`straight_left` runner-up=`straight_right/boxing_straight_right_window_01 0.305` margin=`0.457` backend=`prototype_matcher`
- `punch_left` at `3343ms` score=`0.762` prototype=`boxing_straight_left_window_03` class=`straight_left` runner-up=`straight_right/boxing_straight_right_window_01 0.346` margin=`0.415` backend=`prototype_matcher`
- `punch_left` at `3646ms` score=`0.781` prototype=`boxing_straight_left_window_03` class=`straight_left` runner-up=`straight_right/boxing_straight_right_window_01 0.338` margin=`0.443` backend=`prototype_matcher`
- `punch_left` at `3956ms` score=`0.773` prototype=`boxing_straight_left_window_03` class=`straight_left` runner-up=`straight_right/boxing_straight_right_window_01 0.297` margin=`0.476` backend=`prototype_matcher`
- `punch_left` at `4261ms` score=`0.747` prototype=`boxing_straight_left_window_03` class=`straight_left` runner-up=`straight_right/boxing_straight_right_window_01 0.250` margin=`0.497` backend=`prototype_matcher`
- `punch_left` at `4569ms` score=`0.747` prototype=`boxing_straight_left_window_03` class=`straight_left` runner-up=`straight_right/boxing_straight_right_window_01 0.246` margin=`0.500` backend=`prototype_matcher`
- `punch_left` at `4860ms` score=`0.777` prototype=`boxing_straight_left_window_03` class=`straight_left` runner-up=`straight_right/boxing_straight_right_window_01 0.236` margin=`0.541` backend=`prototype_matcher`
- `punch_left` at `5155ms` score=`0.797` prototype=`boxing_straight_left_window_03` class=`straight_left` runner-up=`straight_right/boxing_straight_right_window_01 0.325` margin=`0.472` backend=`prototype_matcher`
- `punch_left` at `5376ms` score=`0.749` prototype=`boxing_straight_left_window_01` class=`straight_left` runner-up=`straight_right/boxing_straight_right_window_01 0.652` margin=`0.097` backend=`prototype_matcher`
- `punch_left` at `5684ms` score=`0.802` prototype=`boxing_straight_left_window_04` class=`straight_left` runner-up=`straight_right/boxing_straight_right_window_01 0.581` margin=`0.221` backend=`prototype_matcher`
- `punch_left` at `5997ms` score=`0.833` prototype=`boxing_straight_left_window_01` class=`straight_left` runner-up=`straight_right/boxing_straight_right_window_01 0.584` margin=`0.249` backend=`prototype_matcher`
- `punch_left` at `6314ms` score=`0.770` prototype=`boxing_straight_left_window_01` class=`straight_left` runner-up=`straight_right/boxing_straight_right_window_01 0.509` margin=`0.261` backend=`prototype_matcher`
- `punch_left` at `7133ms` score=`0.710` prototype=`boxing_straight_left_window_03` class=`straight_left` runner-up=`straight_right/boxing_straight_right_window_01 0.204` margin=`0.506` backend=`prototype_matcher`
- `punch_left` at `7447ms` score=`0.748` prototype=`boxing_straight_left_window_03` class=`straight_left` runner-up=`straight_right/boxing_straight_right_window_01 0.268` margin=`0.480` backend=`prototype_matcher`
- `punch_left` at `7754ms` score=`0.750` prototype=`boxing_straight_left_window_03` class=`straight_left` runner-up=`straight_right/boxing_straight_right_window_01 0.288` margin=`0.461` backend=`prototype_matcher`
- `punch_left` at `8060ms` score=`0.762` prototype=`boxing_straight_left_window_03` class=`straight_left` runner-up=`straight_right/boxing_straight_right_window_01 0.305` margin=`0.457` backend=`prototype_matcher`
- `punch_left` at `8370ms` score=`0.762` prototype=`boxing_straight_left_window_03` class=`straight_left` runner-up=`straight_right/boxing_straight_right_window_01 0.346` margin=`0.415` backend=`prototype_matcher`
- `punch_left` at `8676ms` score=`0.789` prototype=`boxing_straight_left_window_03` class=`straight_left` runner-up=`straight_right/boxing_straight_right_window_01 0.367` margin=`0.422` backend=`prototype_matcher`
- `punch_left` at `8984ms` score=`0.773` prototype=`boxing_straight_left_window_03` class=`straight_left` runner-up=`straight_right/boxing_straight_right_window_01 0.297` margin=`0.476` backend=`prototype_matcher`
- `punch_left` at `9297ms` score=`0.750` prototype=`boxing_straight_left_window_03` class=`straight_left` runner-up=`straight_right/boxing_straight_right_window_01 0.250` margin=`0.499` backend=`prototype_matcher`
- `punch_left` at `9606ms` score=`0.747` prototype=`boxing_straight_left_window_03` class=`straight_left` runner-up=`straight_right/boxing_straight_right_window_01 0.246` margin=`0.500` backend=`prototype_matcher`
- `punch_left` at `9911ms` score=`0.780` prototype=`boxing_straight_left_window_03` class=`straight_left` runner-up=`straight_right/boxing_straight_right_window_01 0.234` margin=`0.546` backend=`prototype_matcher`
