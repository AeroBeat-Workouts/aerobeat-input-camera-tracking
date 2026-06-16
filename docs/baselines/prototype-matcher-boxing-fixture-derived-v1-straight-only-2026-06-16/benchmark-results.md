# Prototype Matcher Fixture Benchmark

- Benchmark ID: `prototype_matcher_boxing_fixture_derived_v1_straight_only`
- Library ID: `boxing_side_aware_fixture_derived_v1_straight_only`
- Profile: `boxing`
- Generated At: `2026-06-16T10:36:48-04:00`
- Runner: `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/scripts/run_prototype_matcher_fixture_benchmark.py`

## Aggregate

- Fixture count: **3**
- Negative controls clean: **0 / 1**
- Negative-control false-positive classes: `straight_left` x28
- Negative-control false-positive prototypes: `boxing_straight_left_window_01` x24, `boxing_straight_left_window_03` x2, `boxing_straight_left_window_04` x2

## Per Fixture

### straight left

- Fixture: `.testbed/assets/fixtures/boxing/straight_left/boxing_guard->straight_left_repeat_04_take_01.yaml`
- Source: `.testbed/assets/fixtures/boxing/straight_left/boxing_guard->straight_left_repeat_04_take_01.mp4`
- Expected event: `punch_left`
- Expected class: `straight_left`
- Attack events emitted: **31**
- Peak snapshot: straight_left via boxing_straight_left_window_01 score=0.991 runner-up=straight_right/boxing_straight_right_window_04 0.897 margin=0.094
- Strongest expected emit: `punch_left` straight_left via boxing_straight_left_window_01 score=0.991 runner-up=straight_right/boxing_straight_right_window_04 0.897 margin=0.094
- Strongest wrong emit: `punch_right` straight_right via boxing_straight_right_window_04 score=0.921 runner-up=straight_left/boxing_straight_left_window_02 0.533 margin=0.388
- Emitted prototype counts: `boxing_straight_left_window_04` x8, `boxing_straight_right_window_04` x8, `boxing_straight_right_window_03` x6, `boxing_straight_left_window_01` x5, `boxing_straight_left_window_03` x3
- Best-snapshot prototype counts: `boxing_straight_right_window_04` x21, `boxing_straight_left_window_04` x18, `boxing_straight_right_window_03` x18, `boxing_straight_left_window_01` x17, `boxing_straight_left_window_03` x8
- emitted expected punch_left 17 time(s)
- also emitted other attack events: punch_right, punch_right, punch_right, punch_right, punch_right, punch_right, punch_right, punch_right, punch_right, punch_right, punch_right, punch_right, punch_right, punch_right
- peak expected-class score 0.991
- peak winner straight_left via boxing_straight_left_window_01 scored 0.991; runner-up straight_right via boxing_straight_right_window_04 scored 0.897 (margin 0.094)
- strongest expected emit used boxing_straight_left_window_01 at 0.991 over runner-up boxing_straight_right_window_04 at 0.897 (margin 0.094)
- strongest wrong emit was punch_right via boxing_straight_right_window_04 at 0.921 over runner-up boxing_straight_left_window_02 at 0.533 (margin 0.388)
- latest matcher reason step_wait

Emitted attack events:
- `punch_left` at `865ms` score=`0.947` prototype=`boxing_straight_left_window_04` class=`straight_left` runner-up=`straight_right/boxing_straight_right_window_04 0.905` margin=`0.042` backend=`prototype_matcher`
- `punch_left` at `1079ms` score=`0.942` prototype=`boxing_straight_left_window_04` class=`straight_left` runner-up=`straight_right/boxing_straight_right_window_04 0.898` margin=`0.043` backend=`prototype_matcher`
- `punch_right` at `1386ms` score=`0.882` prototype=`boxing_straight_right_window_03` class=`straight_right` runner-up=`straight_left/boxing_straight_left_window_02 0.760` margin=`0.121` backend=`prototype_matcher`
- `punch_right` at `1679ms` score=`0.870` prototype=`boxing_straight_right_window_04` class=`straight_right` runner-up=`straight_left/boxing_straight_left_window_01 0.862` margin=`0.008` backend=`prototype_matcher`
- `punch_left` at `1979ms` score=`0.911` prototype=`boxing_straight_left_window_04` class=`straight_left` runner-up=`straight_right/boxing_straight_right_window_04 0.886` margin=`0.026` backend=`prototype_matcher`
- `punch_left` at `2281ms` score=`0.976` prototype=`boxing_straight_left_window_01` class=`straight_left` runner-up=`straight_right/boxing_straight_right_window_04 0.897` margin=`0.080` backend=`prototype_matcher`
- `punch_right` at `2580ms` score=`0.921` prototype=`boxing_straight_right_window_04` class=`straight_right` runner-up=`straight_left/boxing_straight_left_window_02 0.533` margin=`0.388` backend=`prototype_matcher`
- `punch_right` at `2880ms` score=`0.863` prototype=`boxing_straight_right_window_04` class=`straight_right` runner-up=`straight_left/boxing_straight_left_window_01 0.759` margin=`0.105` backend=`prototype_matcher`
- `punch_left` at `3180ms` score=`0.924` prototype=`boxing_straight_left_window_01` class=`straight_left` runner-up=`straight_right/boxing_straight_right_window_04 0.883` margin=`0.041` backend=`prototype_matcher`
- `punch_left` at `3484ms` score=`0.925` prototype=`boxing_straight_left_window_03` class=`straight_left` runner-up=`straight_right/boxing_straight_right_window_04 0.861` margin=`0.065` backend=`prototype_matcher`
- `punch_right` at `3789ms` score=`0.885` prototype=`boxing_straight_right_window_03` class=`straight_right` runner-up=`straight_left/boxing_straight_left_window_02 0.581` margin=`0.304` backend=`prototype_matcher`
- `punch_right` at `4080ms` score=`0.859` prototype=`boxing_straight_right_window_04` class=`straight_right` runner-up=`straight_left/boxing_straight_left_window_03 0.809` margin=`0.049` backend=`prototype_matcher`
- `punch_left` at `4382ms` score=`0.960` prototype=`boxing_straight_left_window_01` class=`straight_left` runner-up=`straight_right/boxing_straight_right_window_04 0.873` margin=`0.087` backend=`prototype_matcher`
- `punch_left` at `4681ms` score=`0.979` prototype=`boxing_straight_left_window_03` class=`straight_left` runner-up=`straight_right/boxing_straight_right_window_04 0.850` margin=`0.129` backend=`prototype_matcher`
- `punch_right` at `4980ms` score=`0.913` prototype=`boxing_straight_right_window_03` class=`straight_right` runner-up=`straight_left/boxing_straight_left_window_02 0.680` margin=`0.233` backend=`prototype_matcher`
- `punch_right` at `5280ms` score=`0.876` prototype=`boxing_straight_right_window_04` class=`straight_right` runner-up=`straight_left/boxing_straight_left_window_04 0.771` margin=`0.106` backend=`prototype_matcher`
- `punch_left` at `5583ms` score=`0.935` prototype=`boxing_straight_left_window_01` class=`straight_left` runner-up=`straight_right/boxing_straight_right_window_04 0.875` margin=`0.059` backend=`prototype_matcher`
- `punch_left` at `5881ms` score=`0.964` prototype=`boxing_straight_left_window_04` class=`straight_left` runner-up=`straight_right/boxing_straight_right_window_04 0.878` margin=`0.086` backend=`prototype_matcher`
- `punch_left` at `6059ms` score=`0.955` prototype=`boxing_straight_left_window_04` class=`straight_left` runner-up=`straight_right/boxing_straight_right_window_04 0.887` margin=`0.068` backend=`prototype_matcher`
- `punch_left` at `6356ms` score=`0.959` prototype=`boxing_straight_left_window_04` class=`straight_left` runner-up=`straight_right/boxing_straight_right_window_04 0.909` margin=`0.050` backend=`prototype_matcher`
- `punch_left` at `6656ms` score=`0.955` prototype=`boxing_straight_left_window_04` class=`straight_left` runner-up=`straight_right/boxing_straight_right_window_04 0.907` margin=`0.048` backend=`prototype_matcher`
- `punch_left` at `6956ms` score=`0.950` prototype=`boxing_straight_left_window_04` class=`straight_left` runner-up=`straight_right/boxing_straight_right_window_04 0.907` margin=`0.044` backend=`prototype_matcher`
- `punch_left` at `7258ms` score=`0.913` prototype=`boxing_straight_left_window_02` class=`straight_left` runner-up=`straight_right/boxing_straight_right_window_04 0.882` margin=`0.031` backend=`prototype_matcher`
- `punch_right` at `7556ms` score=`0.894` prototype=`boxing_straight_right_window_03` class=`straight_right` runner-up=`straight_left/boxing_straight_left_window_04 0.628` margin=`0.266` backend=`prototype_matcher`
- `punch_right` at `7862ms` score=`0.871` prototype=`boxing_straight_right_window_04` class=`straight_right` runner-up=`straight_left/boxing_straight_left_window_01 0.848` margin=`0.023` backend=`prototype_matcher`
- `punch_left` at `8158ms` score=`0.991` prototype=`boxing_straight_left_window_01` class=`straight_left` runner-up=`straight_right/boxing_straight_right_window_04 0.897` margin=`0.094` backend=`prototype_matcher`
- `punch_right` at `8460ms` score=`0.897` prototype=`boxing_straight_right_window_04` class=`straight_right` runner-up=`straight_left/boxing_straight_left_window_02 0.695` margin=`0.201` backend=`prototype_matcher`
- `punch_right` at `8759ms` score=`0.868` prototype=`boxing_straight_right_window_04` class=`straight_right` runner-up=`straight_left/boxing_straight_left_window_04 0.678` margin=`0.191` backend=`prototype_matcher`
- `punch_right` at `9057ms` score=`0.882` prototype=`boxing_straight_right_window_03` class=`straight_right` runner-up=`straight_left/boxing_straight_left_window_01 0.847` margin=`0.036` backend=`prototype_matcher`
- `punch_left` at `9357ms` score=`0.956` prototype=`boxing_straight_left_window_03` class=`straight_left` runner-up=`straight_right/boxing_straight_right_window_03 0.870` margin=`0.086` backend=`prototype_matcher`
- `punch_right` at `9658ms` score=`0.881` prototype=`boxing_straight_right_window_03` class=`straight_right` runner-up=`straight_left/boxing_straight_left_window_02 0.759` margin=`0.121` backend=`prototype_matcher`

### straight right

- Fixture: `.testbed/assets/fixtures/boxing/straight_right/boxing_guard->straight_right_repeat_04_take_01.yaml`
- Source: `.testbed/assets/fixtures/boxing/straight_right/boxing_guard->straight_right_repeat_04_take_01.mp4`
- Expected event: `punch_right`
- Expected class: `straight_right`
- Attack events emitted: **36**
- Peak snapshot: straight_right via boxing_straight_right_window_03 score=0.977 runner-up=straight_left/boxing_straight_left_window_04 0.872 margin=0.105
- Strongest expected emit: `punch_right` straight_right via boxing_straight_right_window_03 score=0.977 runner-up=straight_left/boxing_straight_left_window_04 0.872 margin=0.105
- Strongest wrong emit: `punch_left` straight_left via boxing_straight_left_window_04 score=0.888 runner-up=straight_right/boxing_straight_right_window_01 0.835 margin=0.053
- Emitted prototype counts: `boxing_straight_right_window_04` x17, `boxing_straight_left_window_04` x8, `boxing_straight_right_window_01` x5, `boxing_straight_right_window_03` x5, `boxing_straight_left_window_01` x1
- Best-snapshot prototype counts: `boxing_straight_right_window_04` x31, `boxing_straight_left_window_04` x17, `boxing_straight_right_window_01` x9, `boxing_straight_right_window_03` x7, `boxing_straight_right_window_02` x4
- emitted expected punch_right 27 time(s)
- also emitted other attack events: punch_left, punch_left, punch_left, punch_left, punch_left, punch_left, punch_left, punch_left, punch_left
- peak expected-class score 0.977
- peak winner straight_right via boxing_straight_right_window_03 scored 0.977; runner-up straight_left via boxing_straight_left_window_04 scored 0.872 (margin 0.105)
- strongest expected emit used boxing_straight_right_window_03 at 0.977 over runner-up boxing_straight_left_window_04 at 0.872 (margin 0.105)
- strongest wrong emit was punch_left via boxing_straight_left_window_04 at 0.888 over runner-up boxing_straight_right_window_01 at 0.835 (margin 0.053)
- latest matcher reason step_wait

Emitted attack events:
- `punch_left` at `867ms` score=`0.888` prototype=`boxing_straight_left_window_04` class=`straight_left` runner-up=`straight_right/boxing_straight_right_window_01 0.835` margin=`0.053` backend=`prototype_matcher`
- `punch_right` at `1126ms` score=`0.921` prototype=`boxing_straight_right_window_03` class=`straight_right` runner-up=`straight_left/boxing_straight_left_window_04 0.895` margin=`0.026` backend=`prototype_matcher`
- `punch_right` at `1366ms` score=`0.957` prototype=`boxing_straight_right_window_04` class=`straight_right` runner-up=`straight_left/boxing_straight_left_window_04 0.907` margin=`0.050` backend=`prototype_matcher`
- `punch_right` at `1618ms` score=`0.953` prototype=`boxing_straight_right_window_04` class=`straight_right` runner-up=`straight_left/boxing_straight_left_window_04 0.903` margin=`0.049` backend=`prototype_matcher`
- `punch_right` at `1868ms` score=`0.878` prototype=`boxing_straight_right_window_03` class=`straight_right` runner-up=`straight_left/boxing_straight_left_window_04 0.875` margin=`0.002` backend=`prototype_matcher`
- `punch_left` at `2130ms` score=`0.802` prototype=`boxing_straight_left_window_04` class=`straight_left` runner-up=`straight_right/boxing_straight_right_window_01 0.690` margin=`0.112` backend=`prototype_matcher`
- `punch_right` at `2367ms` score=`0.923` prototype=`boxing_straight_right_window_01` class=`straight_right` runner-up=`straight_left/boxing_straight_left_window_04 0.869` margin=`0.053` backend=`prototype_matcher`
- `punch_right` at `2617ms` score=`0.951` prototype=`boxing_straight_right_window_04` class=`straight_right` runner-up=`straight_left/boxing_straight_left_window_04 0.908` margin=`0.043` backend=`prototype_matcher`
- `punch_right` at `2869ms` score=`0.952` prototype=`boxing_straight_right_window_04` class=`straight_right` runner-up=`straight_left/boxing_straight_left_window_04 0.929` margin=`0.024` backend=`prototype_matcher`
- `punch_right` at `3119ms` score=`0.936` prototype=`boxing_straight_right_window_04` class=`straight_right` runner-up=`straight_left/boxing_straight_left_window_04 0.905` margin=`0.031` backend=`prototype_matcher`
- `punch_left` at `3368ms` score=`0.808` prototype=`boxing_straight_left_window_04` class=`straight_left` runner-up=`straight_right/boxing_straight_right_window_01 0.665` margin=`0.143` backend=`prototype_matcher`
- `punch_right` at `3620ms` score=`0.896` prototype=`boxing_straight_right_window_01` class=`straight_right` runner-up=`straight_left/boxing_straight_left_window_01 0.890` margin=`0.006` backend=`prototype_matcher`
- `punch_right` at `3869ms` score=`0.977` prototype=`boxing_straight_right_window_03` class=`straight_right` runner-up=`straight_left/boxing_straight_left_window_04 0.872` margin=`0.105` backend=`prototype_matcher`
- `punch_right` at `4119ms` score=`0.959` prototype=`boxing_straight_right_window_04` class=`straight_right` runner-up=`straight_left/boxing_straight_left_window_04 0.940` margin=`0.019` backend=`prototype_matcher`
- `punch_right` at `4369ms` score=`0.960` prototype=`boxing_straight_right_window_04` class=`straight_right` runner-up=`straight_left/boxing_straight_left_window_04 0.902` margin=`0.059` backend=`prototype_matcher`
- `punch_left` at `4629ms` score=`0.851` prototype=`boxing_straight_left_window_04` class=`straight_left` runner-up=`straight_right/boxing_straight_right_window_01 0.757` margin=`0.094` backend=`prototype_matcher`
- `punch_left` at `4881ms` score=`0.840` prototype=`boxing_straight_left_window_04` class=`straight_left` runner-up=`straight_right/boxing_straight_right_window_04 0.790` margin=`0.051` backend=`prototype_matcher`
- `punch_right` at `5121ms` score=`0.924` prototype=`boxing_straight_right_window_01` class=`straight_right` runner-up=`straight_left/boxing_straight_left_window_04 0.896` margin=`0.029` backend=`prototype_matcher`
- `punch_right` at `5372ms` score=`0.976` prototype=`boxing_straight_right_window_04` class=`straight_right` runner-up=`straight_left/boxing_straight_left_window_04 0.915` margin=`0.061` backend=`prototype_matcher`
- `punch_right` at `5622ms` score=`0.970` prototype=`boxing_straight_right_window_04` class=`straight_right` runner-up=`straight_left/boxing_straight_left_window_04 0.929` margin=`0.042` backend=`prototype_matcher`
- `punch_right` at `5874ms` score=`0.969` prototype=`boxing_straight_right_window_04` class=`straight_right` runner-up=`straight_left/boxing_straight_left_window_04 0.907` margin=`0.062` backend=`prototype_matcher`
- `punch_right` at `6085ms` score=`0.962` prototype=`boxing_straight_right_window_04` class=`straight_right` runner-up=`straight_left/boxing_straight_left_window_04 0.887` margin=`0.074` backend=`prototype_matcher`
- `punch_right` at `6334ms` score=`0.953` prototype=`boxing_straight_right_window_04` class=`straight_right` runner-up=`straight_left/boxing_straight_left_window_04 0.887` margin=`0.066` backend=`prototype_matcher`
- `punch_left` at `6584ms` score=`0.825` prototype=`boxing_straight_left_window_04` class=`straight_left` runner-up=`straight_right/boxing_straight_right_window_01 0.654` margin=`0.171` backend=`prototype_matcher`
- `punch_right` at `6836ms` score=`0.935` prototype=`boxing_straight_right_window_01` class=`straight_right` runner-up=`straight_left/boxing_straight_left_window_04 0.892` margin=`0.043` backend=`prototype_matcher`
- `punch_right` at `7089ms` score=`0.950` prototype=`boxing_straight_right_window_03` class=`straight_right` runner-up=`straight_left/boxing_straight_left_window_04 0.894` margin=`0.056` backend=`prototype_matcher`
- `punch_right` at `7336ms` score=`0.957` prototype=`boxing_straight_right_window_04` class=`straight_right` runner-up=`straight_left/boxing_straight_left_window_04 0.907` margin=`0.050` backend=`prototype_matcher`
- `punch_right` at `7585ms` score=`0.952` prototype=`boxing_straight_right_window_04` class=`straight_right` runner-up=`straight_left/boxing_straight_left_window_04 0.903` margin=`0.049` backend=`prototype_matcher`
- `punch_right` at `7837ms` score=`0.878` prototype=`boxing_straight_right_window_03` class=`straight_right` runner-up=`straight_left/boxing_straight_left_window_04 0.875` margin=`0.002` backend=`prototype_matcher`
- `punch_left` at `8098ms` score=`0.807` prototype=`boxing_straight_left_window_04` class=`straight_left` runner-up=`straight_right/boxing_straight_right_window_01 0.689` margin=`0.118` backend=`prototype_matcher`
- `punch_right` at `8337ms` score=`0.920` prototype=`boxing_straight_right_window_01` class=`straight_right` runner-up=`straight_left/boxing_straight_left_window_04 0.872` margin=`0.048` backend=`prototype_matcher`
- `punch_right` at `8588ms` score=`0.956` prototype=`boxing_straight_right_window_04` class=`straight_right` runner-up=`straight_left/boxing_straight_left_window_04 0.908` margin=`0.047` backend=`prototype_matcher`
- `punch_right` at `8838ms` score=`0.951` prototype=`boxing_straight_right_window_04` class=`straight_right` runner-up=`straight_left/boxing_straight_left_window_04 0.927` margin=`0.024` backend=`prototype_matcher`
- `punch_right` at `9093ms` score=`0.936` prototype=`boxing_straight_right_window_04` class=`straight_right` runner-up=`straight_left/boxing_straight_left_window_04 0.907` margin=`0.029` backend=`prototype_matcher`
- `punch_left` at `9339ms` score=`0.810` prototype=`boxing_straight_left_window_04` class=`straight_left` runner-up=`straight_right/boxing_straight_right_window_01 0.680` margin=`0.130` backend=`prototype_matcher`
- `punch_left` at `9590ms` score=`0.868` prototype=`boxing_straight_left_window_01` class=`straight_left` runner-up=`straight_right/boxing_straight_right_window_01 0.825` margin=`0.043` backend=`prototype_matcher`

### negative control - running in place

- Fixture: `.testbed/assets/fixtures/boxing/run_in_place/boxing_guard->run_in_place_repeat_01_take_01.yaml`
- Source: `.testbed/assets/fixtures/boxing/run_in_place/boxing_guard->run_in_place_repeat_01_take_01.mp4`
- Expected event: `None`
- Expected class: `None`
- Attack events emitted: **28**
- Peak snapshot: straight_left via boxing_straight_left_window_01 score=0.973 runner-up=straight_right/boxing_straight_right_window_04 0.812 margin=0.161
- Strongest wrong emit: `punch_left` straight_left via boxing_straight_left_window_01 score=0.973 runner-up=straight_right/boxing_straight_right_window_04 0.812 margin=0.161
- Emitted prototype counts: `boxing_straight_left_window_01` x24, `boxing_straight_left_window_03` x2, `boxing_straight_left_window_04` x2
- Best-snapshot prototype counts: `boxing_straight_left_window_01` x69, `boxing_straight_left_window_03` x8, `boxing_straight_left_window_04` x6
- negative control still emitted attack events: punch_left, punch_left, punch_left, punch_left, punch_left, punch_left, punch_left, punch_left, punch_left, punch_left, punch_left, punch_left, punch_left, punch_left, punch_left, punch_left, punch_left, punch_left, punch_left, punch_left, punch_left, punch_left, punch_left, punch_left, punch_left, punch_left, punch_left, punch_left
- peak winner straight_left via boxing_straight_left_window_01 scored 0.973; runner-up straight_right via boxing_straight_right_window_04 scored 0.812 (margin 0.161)
- strongest wrong emit was punch_left via boxing_straight_left_window_01 at 0.973 over runner-up boxing_straight_right_window_04 at 0.812 (margin 0.161)
- latest matcher reason step_wait

Emitted attack events:
- `punch_left` at `1064ms` score=`0.892` prototype=`boxing_straight_left_window_01` class=`straight_left` runner-up=`straight_right/boxing_straight_right_window_03 0.850` margin=`0.042` backend=`prototype_matcher`
- `punch_left` at `1289ms` score=`0.945` prototype=`boxing_straight_left_window_01` class=`straight_left` runner-up=`straight_right/boxing_straight_right_window_04 0.843` margin=`0.102` backend=`prototype_matcher`
- `punch_left` at `1626ms` score=`0.891` prototype=`boxing_straight_left_window_03` class=`straight_left` runner-up=`straight_right/boxing_straight_right_window_03 0.810` margin=`0.080` backend=`prototype_matcher`
- `punch_left` at `1982ms` score=`0.916` prototype=`boxing_straight_left_window_01` class=`straight_left` runner-up=`straight_right/boxing_straight_right_window_03 0.797` margin=`0.120` backend=`prototype_matcher`
- `punch_left` at `2311ms` score=`0.943` prototype=`boxing_straight_left_window_01` class=`straight_left` runner-up=`straight_right/boxing_straight_right_window_04 0.782` margin=`0.162` backend=`prototype_matcher`
- `punch_left` at `2630ms` score=`0.950` prototype=`boxing_straight_left_window_01` class=`straight_left` runner-up=`straight_right/boxing_straight_right_window_04 0.789` margin=`0.161` backend=`prototype_matcher`
- `punch_left` at `2958ms` score=`0.950` prototype=`boxing_straight_left_window_01` class=`straight_left` runner-up=`straight_right/boxing_straight_right_window_04 0.783` margin=`0.167` backend=`prototype_matcher`
- `punch_left` at `3275ms` score=`0.933` prototype=`boxing_straight_left_window_01` class=`straight_left` runner-up=`straight_right/boxing_straight_right_window_03 0.792` margin=`0.141` backend=`prototype_matcher`
- `punch_left` at `3591ms` score=`0.953` prototype=`boxing_straight_left_window_01` class=`straight_left` runner-up=`straight_right/boxing_straight_right_window_03 0.793` margin=`0.160` backend=`prototype_matcher`
- `punch_left` at `3905ms` score=`0.958` prototype=`boxing_straight_left_window_01` class=`straight_left` runner-up=`straight_right/boxing_straight_right_window_04 0.795` margin=`0.163` backend=`prototype_matcher`
- `punch_left` at `4211ms` score=`0.951` prototype=`boxing_straight_left_window_01` class=`straight_left` runner-up=`straight_right/boxing_straight_right_window_04 0.785` margin=`0.165` backend=`prototype_matcher`
- `punch_left` at `4534ms` score=`0.939` prototype=`boxing_straight_left_window_01` class=`straight_left` runner-up=`straight_right/boxing_straight_right_window_04 0.799` margin=`0.139` backend=`prototype_matcher`
- `punch_left` at `4858ms` score=`0.946` prototype=`boxing_straight_left_window_01` class=`straight_left` runner-up=`straight_right/boxing_straight_right_window_04 0.799` margin=`0.147` backend=`prototype_matcher`
- `punch_left` at `5168ms` score=`0.973` prototype=`boxing_straight_left_window_01` class=`straight_left` runner-up=`straight_right/boxing_straight_right_window_04 0.812` margin=`0.161` backend=`prototype_matcher`
- `punch_left` at `5595ms` score=`0.921` prototype=`boxing_straight_left_window_04` class=`straight_left` runner-up=`straight_right/boxing_straight_right_window_03 0.856` margin=`0.065` backend=`prototype_matcher`
- `punch_left` at `5914ms` score=`0.938` prototype=`boxing_straight_left_window_04` class=`straight_left` runner-up=`straight_right/boxing_straight_right_window_03 0.847` margin=`0.091` backend=`prototype_matcher`
- `punch_left` at `6254ms` score=`0.921` prototype=`boxing_straight_left_window_01` class=`straight_left` runner-up=`straight_right/boxing_straight_right_window_03 0.853` margin=`0.068` backend=`prototype_matcher`
- `punch_left` at `6584ms` score=`0.945` prototype=`boxing_straight_left_window_01` class=`straight_left` runner-up=`straight_right/boxing_straight_right_window_04 0.842` margin=`0.103` backend=`prototype_matcher`
- `punch_left` at `6903ms` score=`0.891` prototype=`boxing_straight_left_window_03` class=`straight_left` runner-up=`straight_right/boxing_straight_right_window_03 0.815` margin=`0.076` backend=`prototype_matcher`
- `punch_left` at `7227ms` score=`0.916` prototype=`boxing_straight_left_window_01` class=`straight_left` runner-up=`straight_right/boxing_straight_right_window_03 0.797` margin=`0.120` backend=`prototype_matcher`
- `punch_left` at `7550ms` score=`0.944` prototype=`boxing_straight_left_window_01` class=`straight_left` runner-up=`straight_right/boxing_straight_right_window_04 0.784` margin=`0.161` backend=`prototype_matcher`
- `punch_left` at `7858ms` score=`0.950` prototype=`boxing_straight_left_window_01` class=`straight_left` runner-up=`straight_right/boxing_straight_right_window_04 0.789` margin=`0.161` backend=`prototype_matcher`
- `punch_left` at `8188ms` score=`0.950` prototype=`boxing_straight_left_window_01` class=`straight_left` runner-up=`straight_right/boxing_straight_right_window_04 0.780` margin=`0.170` backend=`prototype_matcher`
- `punch_left` at `8521ms` score=`0.933` prototype=`boxing_straight_left_window_01` class=`straight_left` runner-up=`straight_right/boxing_straight_right_window_03 0.792` margin=`0.141` backend=`prototype_matcher`
- `punch_left` at `8837ms` score=`0.953` prototype=`boxing_straight_left_window_01` class=`straight_left` runner-up=`straight_right/boxing_straight_right_window_03 0.793` margin=`0.160` backend=`prototype_matcher`
- `punch_left` at `9143ms` score=`0.958` prototype=`boxing_straight_left_window_01` class=`straight_left` runner-up=`straight_right/boxing_straight_right_window_04 0.795` margin=`0.163` backend=`prototype_matcher`
- `punch_left` at `9450ms` score=`0.951` prototype=`boxing_straight_left_window_01` class=`straight_left` runner-up=`straight_right/boxing_straight_right_window_04 0.786` margin=`0.165` backend=`prototype_matcher`
- `punch_left` at `9754ms` score=`0.942` prototype=`boxing_straight_left_window_01` class=`straight_left` runner-up=`straight_right/boxing_straight_right_window_04 0.797` margin=`0.145` backend=`prototype_matcher`
