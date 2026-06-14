# Prototype Matcher Fixture Benchmark

- Benchmark ID: `prototype_matcher_boxing_fixture_derived_v1`
- Library ID: `boxing_side_aware_fixture_derived_v1`
- Profile: `boxing`
- Generated At: `2026-06-13T20:42:12-04:00`
- Runner: `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/scripts/run_prototype_matcher_fixture_benchmark.py`

## Aggregate

- Fixture count: **7**
- Negative controls clean: **0 / 1**

## Per Fixture

### straight left

- Fixture: `.testbed/assets/fixtures/boxing/punch_left/boxing_guard->punch_left_repeat_04_take_01.yaml`
- Source: `.testbed/assets/fixtures/boxing/punch_left/boxing_guard->punch_left_repeat_04_take_01.mp4`
- Expected event: `punch_left`
- Expected class: `straight_left`
- Attack events emitted: **29**
- emitted expected punch_left 10 time(s)
- also emitted other attack events: uppercut_left, uppercut_left, hook_right, uppercut_right, uppercut_right, hook_right, hook_right, hook_right, hook_right, hook_right, uppercut_right, uppercut_left, uppercut_left, uppercut_left, uppercut_left, uppercut_right, uppercut_right, uppercut_right, uppercut_right
- peak expected-class score 1.000
- latest matcher reason step_wait

Emitted attack events:
- `uppercut_left` at `1128ms` score=`0.903` class=`uppercut_left` backend=`prototype_matcher`
- `uppercut_left` at `1348ms` score=`0.885` class=`uppercut_left` backend=`prototype_matcher`
- `hook_right` at `1664ms` score=`0.750` class=`hook_right` backend=`prototype_matcher`
- `punch_left` at `1962ms` score=`0.802` class=`straight_left` backend=`prototype_matcher`
- `punch_left` at `2272ms` score=`0.924` class=`straight_left` backend=`prototype_matcher`
- `uppercut_right` at `2579ms` score=`0.905` class=`uppercut_right` backend=`prototype_matcher`
- `uppercut_right` at `2888ms` score=`0.788` class=`uppercut_right` backend=`prototype_matcher`
- `punch_left` at `3193ms` score=`0.867` class=`straight_left` backend=`prototype_matcher`
- `hook_right` at `3505ms` score=`0.948` class=`hook_right` backend=`prototype_matcher`
- `hook_right` at `3814ms` score=`0.879` class=`hook_right` backend=`prototype_matcher`
- `hook_right` at `4127ms` score=`0.858` class=`hook_right` backend=`prototype_matcher`
- `punch_left` at `4429ms` score=`0.857` class=`straight_left` backend=`prototype_matcher`
- `punch_left` at `4731ms` score=`0.976` class=`straight_left` backend=`prototype_matcher`
- `hook_right` at `5040ms` score=`0.872` class=`hook_right` backend=`prototype_matcher`
- `hook_right` at `5349ms` score=`0.840` class=`hook_right` backend=`prototype_matcher`
- `uppercut_right` at `5656ms` score=`0.852` class=`uppercut_right` backend=`prototype_matcher`
- `punch_left` at `5954ms` score=`0.924` class=`straight_left` backend=`prototype_matcher`
- `punch_left` at `6255ms` score=`0.925` class=`straight_left` backend=`prototype_matcher`
- `uppercut_left` at `6472ms` score=`0.895` class=`uppercut_left` backend=`prototype_matcher`
- `uppercut_left` at `6769ms` score=`0.888` class=`uppercut_left` backend=`prototype_matcher`
- `uppercut_left` at `7075ms` score=`0.906` class=`uppercut_left` backend=`prototype_matcher`
- `uppercut_left` at `7382ms` score=`0.925` class=`uppercut_left` backend=`prototype_matcher`
- `uppercut_right` at `7682ms` score=`0.839` class=`uppercut_right` backend=`prototype_matcher`
- `uppercut_right` at `8009ms` score=`0.760` class=`uppercut_right` backend=`prototype_matcher`
- `punch_left` at `8354ms` score=`0.887` class=`straight_left` backend=`prototype_matcher`
- `punch_left` at `8701ms` score=`0.937` class=`straight_left` backend=`prototype_matcher`
- `uppercut_right` at `9030ms` score=`0.813` class=`uppercut_right` backend=`prototype_matcher`
- `uppercut_right` at `9363ms` score=`0.771` class=`uppercut_right` backend=`prototype_matcher`
- `punch_left` at `9707ms` score=`0.945` class=`straight_left` backend=`prototype_matcher`

### straight right

- Fixture: `.testbed/assets/fixtures/boxing/punch_right/boxing_guard->punch_right_repeat_04_take_01.yaml`
- Source: `.testbed/assets/fixtures/boxing/punch_right/boxing_guard->punch_right_repeat_04_take_01.mp4`
- Expected event: `punch_right`
- Expected class: `straight_right`
- Attack events emitted: **33**
- emitted expected punch_right 27 time(s)
- also emitted other attack events: uppercut_left, uppercut_left, uppercut_left, uppercut_left, uppercut_left, uppercut_left
- peak expected-class score 0.982
- latest matcher reason step_wait

Emitted attack events:
- `punch_right` at `1099ms` score=`0.847` class=`straight_right` backend=`prototype_matcher`
- `punch_right` at `1271ms` score=`0.873` class=`straight_right` backend=`prototype_matcher`
- `punch_right` at `1499ms` score=`0.930` class=`straight_right` backend=`prototype_matcher`
- `punch_right` at `1750ms` score=`0.940` class=`straight_right` backend=`prototype_matcher`
- `uppercut_left` at `2251ms` score=`0.829` class=`uppercut_left` backend=`prototype_matcher`
- `punch_right` at `2500ms` score=`0.901` class=`straight_right` backend=`prototype_matcher`
- `punch_right` at `2751ms` score=`0.879` class=`straight_right` backend=`prototype_matcher`
- `punch_right` at `3002ms` score=`0.966` class=`straight_right` backend=`prototype_matcher`
- `uppercut_left` at `3263ms` score=`0.759` class=`uppercut_left` backend=`prototype_matcher`
- `punch_right` at `3626ms` score=`0.814` class=`straight_right` backend=`prototype_matcher`
- `punch_right` at `3876ms` score=`0.917` class=`straight_right` backend=`prototype_matcher`
- `punch_right` at `4128ms` score=`0.924` class=`straight_right` backend=`prototype_matcher`
- `punch_right` at `4376ms` score=`0.932` class=`straight_right` backend=`prototype_matcher`
- `uppercut_left` at `4636ms` score=`0.742` class=`uppercut_left` backend=`prototype_matcher`
- `uppercut_left` at `4888ms` score=`0.759` class=`uppercut_left` backend=`prototype_matcher`
- `punch_right` at `5127ms` score=`0.914` class=`straight_right` backend=`prototype_matcher`
- `punch_right` at `5377ms` score=`0.949` class=`straight_right` backend=`prototype_matcher`
- `punch_right` at `5625ms` score=`0.939` class=`straight_right` backend=`prototype_matcher`
- `punch_right` at `5877ms` score=`0.945` class=`straight_right` backend=`prototype_matcher`
- `punch_right` at `6105ms` score=`0.922` class=`straight_right` backend=`prototype_matcher`
- `punch_right` at `6346ms` score=`0.856` class=`straight_right` backend=`prototype_matcher`
- `punch_right` at `6850ms` score=`0.800` class=`straight_right` backend=`prototype_matcher`
- `punch_right` at `7100ms` score=`0.847` class=`straight_right` backend=`prototype_matcher`
- `punch_right` at `7349ms` score=`0.898` class=`straight_right` backend=`prototype_matcher`
- `punch_right` at `7600ms` score=`0.982` class=`straight_right` backend=`prototype_matcher`
- `punch_right` at `7848ms` score=`0.768` class=`straight_right` backend=`prototype_matcher`
- `uppercut_left` at `8222ms` score=`0.829` class=`uppercut_left` backend=`prototype_matcher`
- `punch_right` at `8473ms` score=`0.901` class=`straight_right` backend=`prototype_matcher`
- `punch_right` at `8723ms` score=`0.879` class=`straight_right` backend=`prototype_matcher`
- `punch_right` at `8972ms` score=`0.966` class=`straight_right` backend=`prototype_matcher`
- `uppercut_left` at `9236ms` score=`0.759` class=`uppercut_left` backend=`prototype_matcher`
- `punch_right` at `9601ms` score=`0.814` class=`straight_right` backend=`prototype_matcher`
- `punch_right` at `9851ms` score=`0.917` class=`straight_right` backend=`prototype_matcher`

### hook left

- Fixture: `.testbed/assets/fixtures/boxing/hook_left/boxing_guard->hook_left_repeat_04_take_01.yaml`
- Source: `.testbed/assets/fixtures/boxing/hook_left/boxing_guard->hook_left_repeat_04_take_01.mp4`
- Expected event: `hook_left`
- Expected class: `hook_left`
- Attack events emitted: **27**
- emitted expected hook_left 10 time(s)
- also emitted other attack events: uppercut_right, uppercut_left, hook_right, hook_right, hook_right, hook_right, hook_right, hook_right, hook_right, uppercut_left, uppercut_left, uppercut_right, uppercut_left, uppercut_right, uppercut_left, hook_right, hook_right
- peak expected-class score 0.980
- latest matcher reason emit_cooldown_active

Emitted attack events:
- `uppercut_right` at `1094ms` score=`0.900` class=`uppercut_right` backend=`prototype_matcher`
- `uppercut_left` at `1333ms` score=`0.885` class=`uppercut_left` backend=`prototype_matcher`
- `hook_right` at `1945ms` score=`0.701` class=`hook_right` backend=`prototype_matcher`
- `hook_left` at `2255ms` score=`0.899` class=`hook_left` backend=`prototype_matcher`
- `hook_left` at `2561ms` score=`0.945` class=`hook_left` backend=`prototype_matcher`
- `hook_left` at `2876ms` score=`0.893` class=`hook_left` backend=`prototype_matcher`
- `hook_right` at `3179ms` score=`0.731` class=`hook_right` backend=`prototype_matcher`
- `hook_left` at `3692ms` score=`0.774` class=`hook_left` backend=`prototype_matcher`
- `hook_left` at `4025ms` score=`0.931` class=`hook_left` backend=`prototype_matcher`
- `hook_left` at `4338ms` score=`0.889` class=`hook_left` backend=`prototype_matcher`
- `hook_right` at `4641ms` score=`0.783` class=`hook_right` backend=`prototype_matcher`
- `hook_right` at `5149ms` score=`0.763` class=`hook_right` backend=`prototype_matcher`
- `hook_left` at `5459ms` score=`0.952` class=`hook_left` backend=`prototype_matcher`
- `hook_left` at `5761ms` score=`0.905` class=`hook_left` backend=`prototype_matcher`
- `hook_right` at `6073ms` score=`0.714` class=`hook_right` backend=`prototype_matcher`
- `hook_right` at `6377ms` score=`0.705` class=`hook_right` backend=`prototype_matcher`
- `hook_right` at `6694ms` score=`0.770` class=`hook_right` backend=`prototype_matcher`
- `hook_left` at `6990ms` score=`0.941` class=`hook_left` backend=`prototype_matcher`
- `uppercut_left` at `7289ms` score=`0.837` class=`uppercut_left` backend=`prototype_matcher`
- `uppercut_left` at `7579ms` score=`0.863` class=`uppercut_left` backend=`prototype_matcher`
- `uppercut_right` at `7834ms` score=`0.897` class=`uppercut_right` backend=`prototype_matcher`
- `uppercut_left` at `8134ms` score=`0.904` class=`uppercut_left` backend=`prototype_matcher`
- `uppercut_right` at `8442ms` score=`0.920` class=`uppercut_right` backend=`prototype_matcher`
- `uppercut_left` at `8745ms` score=`0.898` class=`uppercut_left` backend=`prototype_matcher`
- `hook_right` at `9061ms` score=`0.809` class=`hook_right` backend=`prototype_matcher`
- `hook_right` at `9451ms` score=`0.701` class=`hook_right` backend=`prototype_matcher`
- `hook_left` at `9758ms` score=`0.899` class=`hook_left` backend=`prototype_matcher`

### hook right

- Fixture: `.testbed/assets/fixtures/boxing/hook_right/boxing_guard->hook_right_repeat_04_take_01.yaml`
- Source: `.testbed/assets/fixtures/boxing/hook_right/boxing_guard->hook_right_repeat_04_take_01.mp4`
- Expected event: `hook_right`
- Expected class: `hook_right`
- Attack events emitted: **27**
- emitted expected hook_right 19 time(s)
- also emitted other attack events: punch_left, hook_left, punch_left, hook_left, hook_left, hook_left, hook_left, uppercut_left
- peak expected-class score 0.985
- latest matcher reason emit_cooldown_active

Emitted attack events:
- `hook_right` at `1091ms` score=`0.916` class=`hook_right` backend=`prototype_matcher`
- `punch_left` at `1332ms` score=`0.834` class=`straight_left` backend=`prototype_matcher`
- `hook_right` at `1849ms` score=`0.740` class=`hook_right` backend=`prototype_matcher`
- `hook_right` at `2144ms` score=`0.919` class=`hook_right` backend=`prototype_matcher`
- `hook_right` at `2446ms` score=`0.972` class=`hook_right` backend=`prototype_matcher`
- `hook_left` at `2761ms` score=`0.843` class=`hook_left` backend=`prototype_matcher`
- `punch_left` at `3054ms` score=`0.711` class=`straight_left` backend=`prototype_matcher`
- `hook_right` at `3471ms` score=`0.771` class=`hook_right` backend=`prototype_matcher`
- `hook_right` at `3757ms` score=`0.930` class=`hook_right` backend=`prototype_matcher`
- `hook_right` at `4057ms` score=`0.882` class=`hook_right` backend=`prototype_matcher`
- `hook_left` at `4385ms` score=`0.824` class=`hook_left` backend=`prototype_matcher`
- `hook_left` at `4882ms` score=`0.748` class=`hook_left` backend=`prototype_matcher`
- `hook_right` at `5185ms` score=`0.875` class=`hook_right` backend=`prototype_matcher`
- `hook_right` at `5492ms` score=`0.944` class=`hook_right` backend=`prototype_matcher`
- `hook_right` at `5810ms` score=`0.886` class=`hook_right` backend=`prototype_matcher`
- `hook_left` at `6117ms` score=`0.733` class=`hook_left` backend=`prototype_matcher`
- `hook_right` at `6643ms` score=`0.780` class=`hook_right` backend=`prototype_matcher`
- `hook_left` at `6940ms` score=`0.872` class=`hook_left` backend=`prototype_matcher`
- `hook_right` at `7238ms` score=`0.944` class=`hook_right` backend=`prototype_matcher`
- `hook_right` at `7533ms` score=`0.914` class=`hook_right` backend=`prototype_matcher`
- `hook_right` at `7836ms` score=`0.912` class=`hook_right` backend=`prototype_matcher`
- `hook_right` at `8055ms` score=`0.899` class=`hook_right` backend=`prototype_matcher`
- `hook_right` at `8345ms` score=`0.929` class=`hook_right` backend=`prototype_matcher`
- `hook_right` at `8645ms` score=`0.904` class=`hook_right` backend=`prototype_matcher`
- `uppercut_left` at `8956ms` score=`0.857` class=`uppercut_left` backend=`prototype_matcher`
- `hook_right` at `9559ms` score=`0.705` class=`hook_right` backend=`prototype_matcher`
- `hook_right` at `9848ms` score=`0.919` class=`hook_right` backend=`prototype_matcher`

### uppercut left

- Fixture: `.testbed/assets/fixtures/boxing/uppercut_left/boxing_guard->uppercut_left_repeat_04_take_01.yaml`
- Source: `.testbed/assets/fixtures/boxing/uppercut_left/boxing_guard->uppercut_left_repeat_04_take_01.mp4`
- Expected event: `uppercut_left`
- Expected class: `uppercut_left`
- Attack events emitted: **29**
- emitted expected uppercut_left 18 time(s)
- also emitted other attack events: uppercut_right, hook_right, punch_left, hook_right, hook_right, hook_right, hook_left, hook_right, uppercut_right, hook_right, hook_right
- peak expected-class score 0.993
- latest matcher reason emitted

Emitted attack events:
- `uppercut_right` at `1075ms` score=`0.756` class=`uppercut_right` backend=`prototype_matcher`
- `hook_right` at `1333ms` score=`0.750` class=`hook_right` backend=`prototype_matcher`
- `uppercut_left` at `1625ms` score=`0.851` class=`uppercut_left` backend=`prototype_matcher`
- `uppercut_left` at `1935ms` score=`0.924` class=`uppercut_left` backend=`prototype_matcher`
- `uppercut_left` at `2246ms` score=`0.992` class=`uppercut_left` backend=`prototype_matcher`
- `uppercut_left` at `2546ms` score=`0.928` class=`uppercut_left` backend=`prototype_matcher`
- `punch_left` at `2845ms` score=`0.859` class=`straight_left` backend=`prototype_matcher`
- `hook_right` at `3144ms` score=`0.721` class=`hook_right` backend=`prototype_matcher`
- `hook_right` at `3449ms` score=`0.808` class=`hook_right` backend=`prototype_matcher`
- `uppercut_left` at `3756ms` score=`0.882` class=`uppercut_left` backend=`prototype_matcher`
- `uppercut_left` at `4061ms` score=`0.981` class=`uppercut_left` backend=`prototype_matcher`
- `uppercut_left` at `4371ms` score=`0.951` class=`uppercut_left` backend=`prototype_matcher`
- `uppercut_left` at `4675ms` score=`0.902` class=`uppercut_left` backend=`prototype_matcher`
- `hook_right` at `5299ms` score=`0.719` class=`hook_right` backend=`prototype_matcher`
- `uppercut_left` at `5592ms` score=`0.894` class=`uppercut_left` backend=`prototype_matcher`
- `uppercut_left` at `5901ms` score=`0.965` class=`uppercut_left` backend=`prototype_matcher`
- `uppercut_left` at `6210ms` score=`0.956` class=`uppercut_left` backend=`prototype_matcher`
- `uppercut_left` at `6512ms` score=`0.946` class=`uppercut_left` backend=`prototype_matcher`
- `hook_left` at `6841ms` score=`0.804` class=`hook_left` backend=`prototype_matcher`
- `hook_right` at `7236ms` score=`0.738` class=`hook_right` backend=`prototype_matcher`
- `uppercut_left` at `7536ms` score=`0.837` class=`uppercut_left` backend=`prototype_matcher`
- `uppercut_left` at `7832ms` score=`0.905` class=`uppercut_left` backend=`prototype_matcher`
- `uppercut_left` at `8218ms` score=`0.926` class=`uppercut_left` backend=`prototype_matcher`
- `uppercut_left` at `8426ms` score=`0.929` class=`uppercut_left` backend=`prototype_matcher`
- `uppercut_right` at `8729ms` score=`0.892` class=`uppercut_right` backend=`prototype_matcher`
- `hook_right` at `9028ms` score=`0.752` class=`hook_right` backend=`prototype_matcher`
- `hook_right` at `9337ms` score=`0.769` class=`hook_right` backend=`prototype_matcher`
- `uppercut_left` at `9650ms` score=`0.865` class=`uppercut_left` backend=`prototype_matcher`
- `uppercut_left` at `9949ms` score=`0.947` class=`uppercut_left` backend=`prototype_matcher`

### uppercut right

- Fixture: `.testbed/assets/fixtures/boxing/uppercut_right/boxing_guard->uppercut_right_repeat_04_take_01.yaml`
- Source: `.testbed/assets/fixtures/boxing/uppercut_right/boxing_guard->uppercut_right_repeat_04_take_01.mp4`
- Expected event: `uppercut_right`
- Expected class: `uppercut_right`
- Attack events emitted: **27**
- emitted expected uppercut_right 14 time(s)
- also emitted other attack events: uppercut_left, hook_left, punch_left, hook_left, hook_left, hook_left, hook_left, hook_right, hook_left, hook_left, hook_left, punch_left, hook_left
- peak expected-class score 1.000
- latest matcher reason emitted

Emitted attack events:
- `uppercut_left` at `1077ms` score=`0.769` class=`uppercut_left` backend=`prototype_matcher`
- `hook_left` at `1399ms` score=`0.791` class=`hook_left` backend=`prototype_matcher`
- `punch_left` at `1681ms` score=`0.749` class=`straight_left` backend=`prototype_matcher`
- `uppercut_right` at `1991ms` score=`0.905` class=`uppercut_right` backend=`prototype_matcher`
- `uppercut_right` at `2294ms` score=`1.000` class=`uppercut_right` backend=`prototype_matcher`
- `uppercut_right` at `2601ms` score=`0.933` class=`uppercut_right` backend=`prototype_matcher`
- `hook_left` at `3209ms` score=`0.799` class=`hook_left` backend=`prototype_matcher`
- `uppercut_right` at `3517ms` score=`0.856` class=`uppercut_right` backend=`prototype_matcher`
- `uppercut_right` at `3825ms` score=`0.929` class=`uppercut_right` backend=`prototype_matcher`
- `uppercut_right` at `4128ms` score=`0.931` class=`uppercut_right` backend=`prototype_matcher`
- `hook_left` at `4453ms` score=`0.826` class=`hook_left` backend=`prototype_matcher`
- `hook_left` at `4761ms` score=`0.847` class=`hook_left` backend=`prototype_matcher`
- `hook_left` at `5046ms` score=`0.872` class=`hook_left` backend=`prototype_matcher`
- `hook_right` at `5363ms` score=`0.919` class=`hook_right` backend=`prototype_matcher`
- `uppercut_right` at `5679ms` score=`0.924` class=`uppercut_right` backend=`prototype_matcher`
- `hook_left` at `6211ms` score=`0.764` class=`hook_left` backend=`prototype_matcher`
- `hook_left` at `6489ms` score=`0.812` class=`hook_left` backend=`prototype_matcher`
- `uppercut_right` at `6780ms` score=`0.920` class=`uppercut_right` backend=`prototype_matcher`
- `uppercut_right` at `7132ms` score=`0.932` class=`uppercut_right` backend=`prototype_matcher`
- `uppercut_right` at `7441ms` score=`0.924` class=`uppercut_right` backend=`prototype_matcher`
- `uppercut_right` at `7763ms` score=`0.900` class=`uppercut_right` backend=`prototype_matcher`
- `hook_left` at `8176ms` score=`0.791` class=`hook_left` backend=`prototype_matcher`
- `punch_left` at `8456ms` score=`0.749` class=`straight_left` backend=`prototype_matcher`
- `uppercut_right` at `8759ms` score=`0.905` class=`uppercut_right` backend=`prototype_matcher`
- `uppercut_right` at `9064ms` score=`1.000` class=`uppercut_right` backend=`prototype_matcher`
- `uppercut_right` at `9370ms` score=`0.933` class=`uppercut_right` backend=`prototype_matcher`
- `hook_left` at `9980ms` score=`0.723` class=`hook_left` backend=`prototype_matcher`

### negative control - running in place

- Fixture: `.testbed/assets/fixtures/boxing/run_in_place/boxing_guard->run_in_place_repeat_01_take_01.yaml`
- Source: `.testbed/assets/fixtures/boxing/run_in_place/boxing_guard->run_in_place_repeat_01_take_01.mp4`
- Expected event: `None`
- Expected class: `None`
- Attack events emitted: **30**
- negative control still emitted attack events: punch_left, punch_left, hook_left, hook_left, hook_left, hook_left, hook_left, hook_left, hook_left, hook_left, hook_left, hook_left, hook_left, hook_left, hook_right, hook_right, punch_left, punch_left, hook_left, hook_left, hook_left, hook_left, hook_left, hook_left, hook_left, hook_left, hook_left, hook_left, hook_left, hook_left
- latest matcher reason step_wait

Emitted attack events:
- `punch_left` at `1098ms` score=`0.866` class=`straight_left` backend=`prototype_matcher`
- `punch_left` at `1369ms` score=`0.822` class=`straight_left` backend=`prototype_matcher`
- `hook_left` at `1678ms` score=`0.785` class=`hook_left` backend=`prototype_matcher`
- `hook_left` at `1984ms` score=`0.820` class=`hook_left` backend=`prototype_matcher`
- `hook_left` at `2293ms` score=`0.863` class=`hook_left` backend=`prototype_matcher`
- `hook_left` at `2597ms` score=`0.875` class=`hook_left` backend=`prototype_matcher`
- `hook_left` at `2913ms` score=`0.884` class=`hook_left` backend=`prototype_matcher`
- `hook_left` at `3221ms` score=`0.873` class=`hook_left` backend=`prototype_matcher`
- `hook_left` at `3529ms` score=`0.907` class=`hook_left` backend=`prototype_matcher`
- `hook_left` at `3835ms` score=`0.888` class=`hook_left` backend=`prototype_matcher`
- `hook_left` at `4138ms` score=`0.880` class=`hook_left` backend=`prototype_matcher`
- `hook_left` at `4448ms` score=`0.845` class=`hook_left` backend=`prototype_matcher`
- `hook_left` at `4744ms` score=`0.845` class=`hook_left` backend=`prototype_matcher`
- `hook_left` at `5037ms` score=`0.889` class=`hook_left` backend=`prototype_matcher`
- `hook_right` at `5348ms` score=`0.888` class=`hook_right` backend=`prototype_matcher`
- `hook_right` at `5553ms` score=`0.862` class=`hook_right` backend=`prototype_matcher`
- `punch_left` at `5862ms` score=`0.865` class=`straight_left` backend=`prototype_matcher`
- `punch_left` at `6164ms` score=`0.851` class=`straight_left` backend=`prototype_matcher`
- `hook_left` at `6470ms` score=`0.747` class=`hook_left` backend=`prototype_matcher`
- `hook_left` at `6784ms` score=`0.810` class=`hook_left` backend=`prototype_matcher`
- `hook_left` at `7087ms` score=`0.840` class=`hook_left` backend=`prototype_matcher`
- `hook_left` at `7392ms` score=`0.862` class=`hook_left` backend=`prototype_matcher`
- `hook_left` at `7692ms` score=`0.870` class=`hook_left` backend=`prototype_matcher`
- `hook_left` at `7998ms` score=`0.856` class=`hook_left` backend=`prototype_matcher`
- `hook_left` at `8304ms` score=`0.880` class=`hook_left` backend=`prototype_matcher`
- `hook_left` at `8604ms` score=`0.884` class=`hook_left` backend=`prototype_matcher`
- `hook_left` at `8911ms` score=`0.881` class=`hook_left` backend=`prototype_matcher`
- `hook_left` at `9211ms` score=`0.851` class=`hook_left` backend=`prototype_matcher`
- `hook_left` at `9519ms` score=`0.857` class=`hook_left` backend=`prototype_matcher`
- `hook_left` at `9815ms` score=`0.874` class=`hook_left` backend=`prototype_matcher`
