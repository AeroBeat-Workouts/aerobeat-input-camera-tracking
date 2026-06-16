# boxing-punch-classifier-hardened-2026-06-16

Frozen hardened boxing punch-classifier benchmark snapshot anchored to the 2026-06-16 archived dataset and capture reports.

## Frozen inputs

- Benchmark manifest: `.testbed/assets/benchmarks/boxing_punch_classifier_v1.benchmark.json`
- Capture package: `boxing-punch-classifier-hardened-2026-06-16.capture_reports`
- Capture source root: `.temp/boxing-punch-classifier-export/hardened-captures-2026-06-16`
- Alignment basis: `fixture_window_plus_capture_time_origin_offset_from_provider_tracking_ms_since_first_pose`
- Export parameters: `{"frame_count": 8, "max_no_punch_samples": 48, "max_transition_no_punch_samples": 24, "no_punch_stride_ms": 250, "no_punch_window_ms": 250}`
- Split strategy: `chronological_holdout_v1`
- Negative sampling policy: `{"background_windows": "complement_intervals iter_fixed_windows evenly_pick", "transition_windows": "before_and_after_each_punch_window clamped_to_non_punch_intervals evenly_pick"}`

## Dataset anchor

- Dataset: `.temp/boxing-punch-classifier-export/hardened-2026-06-16/dataset.json` sha256=`7d62c6d2581e6cb81d923a39bfad4a19c892de4e01b044a7e1dbdb8d877615be`
- Export summary: `.temp/boxing-punch-classifier-export/hardened-2026-06-16/export-summary.json` sha256=`2d4e9aa05c7ed2e0276e01f10cec120cfb614a172eea61315aabca10f6f92c92`
- Threshold baseline: `.temp/boxing-punch-classifier-export/hardened-2026-06-16/threshold-baseline.json` sha256=`a89539077c750103eb406c67364fed1bdf9c44cbf1a378028af5debc7de5198a`

## Fixtures

### straight_left_fixture
- Fixture YAML: `.testbed/assets/fixtures/boxing/straight_left/boxing_guard->straight_left_repeat_04_take_01.yaml` sha256=`975f8e18feabb3217d7e4f04a5e1eaa2537d4a1f0698028085722fa8f61f653f`
- Source video: `.testbed/assets/fixtures/boxing/straight_left/boxing_guard->straight_left_repeat_04_take_01.mp4` sha256=`082b0e99030b2e2e0d058f4be1e11a6d5f645925f4e55725bbebcd3cb887d7b8`
- Capture report: `.temp/boxing-punch-classifier-export/hardened-captures-2026-06-16/captures/straight_left_fixture/report.json` sha256=`c5e41e97afa72a5ad03d19b03d3d873a4f16d92bb9e778bf796ec60a82e8569e`
- Truth windows: **9**

### straight_right_fixture
- Fixture YAML: `.testbed/assets/fixtures/boxing/straight_right/boxing_guard->straight_right_repeat_04_take_01.yaml` sha256=`5e8835b59185f6ee914b5ecabcef958d8804492c04c5ca4df37587550c99f8c5`
- Source video: `.testbed/assets/fixtures/boxing/straight_right/boxing_guard->straight_right_repeat_04_take_01.mp4` sha256=`07e2558fbdde81792c3b2ea8d222ba15712b99c55c31fe25743a3d0ead354b17`
- Capture report: `.temp/boxing-punch-classifier-export/hardened-captures-2026-06-16/captures/straight_right_fixture/report.json` sha256=`16495685be76429e8b027932d0a95e42463e1108213b0518bbf9538132d5d87d`
- Truth windows: **9**

### hook_left_fixture
- Fixture YAML: `.testbed/assets/fixtures/boxing/hook_left/boxing_guard->hook_left_repeat_04_take_01.yaml` sha256=`fe2b339cb6aeeedf6ce7bd4b819a5aa4b6887e4f659e367f1a9ec552657a0607`
- Source video: `.testbed/assets/fixtures/boxing/hook_left/boxing_guard->hook_left_repeat_04_take_01.mp4` sha256=`765d80aed5f249c2cc251b9e6d4a8318dddf49c0958c28ebcb318ec15b76ae7c`
- Capture report: `.temp/boxing-punch-classifier-export/hardened-captures-2026-06-16/captures/hook_left_fixture/report.json` sha256=`401130af5e2d6c211baee989d8d5b5e831c0bfeacecd29730d8162d7c3288074`
- Truth windows: **9**

### hook_right_fixture
- Fixture YAML: `.testbed/assets/fixtures/boxing/hook_right/boxing_guard->hook_right_repeat_04_take_01.yaml` sha256=`4892becec6442dbe5fbde01a87ead940d60c6b297efafa017a5d0de50156b769`
- Source video: `.testbed/assets/fixtures/boxing/hook_right/boxing_guard->hook_right_repeat_04_take_01.mp4` sha256=`537f0d76edcc10851b90cff0403c5880670279418bb45b96c084ec07ba331250`
- Capture report: `.temp/boxing-punch-classifier-export/hardened-captures-2026-06-16/captures/hook_right_fixture/report.json` sha256=`d51a91bf848c7cc9c836ab6d059b85a4d2066b4e7b5d70f6759fc30f2208fda1`
- Truth windows: **9**

### uppercut_left_fixture
- Fixture YAML: `.testbed/assets/fixtures/boxing/uppercut_left/boxing_guard->uppercut_left_repeat_04_take_01.yaml` sha256=`e42a4f44fd7cc008b178387306efa5bdaa79badecac67ccc16ee7c5e85fdee10`
- Source video: `.testbed/assets/fixtures/boxing/uppercut_left/boxing_guard->uppercut_left_repeat_04_take_01.mp4` sha256=`51985d51a6854963421db281d9e32702726e6dec614e8e402c2f78a8a103e185`
- Capture report: `.temp/boxing-punch-classifier-export/hardened-captures-2026-06-16/captures/uppercut_left_fixture/report.json` sha256=`80b8021fe2436741a74326ccc486f3b322d2a20f10ce9cd5634fa6aebc18ac8b`
- Truth windows: **9**

### uppercut_right_fixture
- Fixture YAML: `.testbed/assets/fixtures/boxing/uppercut_right/boxing_guard->uppercut_right_repeat_04_take_01.yaml` sha256=`9d3ab719277c27ed3f946a7716610673a55a47d4c8ac1340fb502fc20c5c93ee`
- Source video: `.testbed/assets/fixtures/boxing/uppercut_right/boxing_guard->uppercut_right_repeat_04_take_01.mp4` sha256=`7a774cf11f260b6239f3dfda6db10ab1b13acc488310f328ec733c1946dd52b0`
- Capture report: `.temp/boxing-punch-classifier-export/hardened-captures-2026-06-16/captures/uppercut_right_fixture/report.json` sha256=`d1415293a9738fb24c402b4897729694ecdaba840e51d226d921c2c00bd0aba8`
- Truth windows: **9**

### run_in_place_fixture
- Fixture YAML: `.testbed/assets/fixtures/boxing/run_in_place/boxing_guard->run_in_place_repeat_01_take_01.yaml` sha256=`d33932a1dfa830a3da8a6c874cd3c8e7bbe2dee801b58436d75cd73c573c42f0`
- Source video: `.testbed/assets/fixtures/boxing/run_in_place/boxing_guard->run_in_place_repeat_01_take_01.mp4` sha256=`427c228232b75cf00ab99f62450b7bacea7f82e11b28ff2b4c859c6f75d31415`
- Capture report: `.temp/boxing-punch-classifier-export/hardened-captures-2026-06-16/captures/run_in_place_fixture/report.json` sha256=`7f8921a007a1e43f37155e9e0a84b4ec14ae7e94ad48dc174713f16ccb277bd3`
- Truth windows: **2**

### weave_left_fixture
- Fixture YAML: `.testbed/assets/fixtures/boxing/weave_left/boxing_guard->weave_left_repeat_04_take_01.yaml` sha256=`2a72c7814ee0363dd9ddb07ea3f024e2044702dd8cbd0a3d47e1bd4b1115800c`
- Source video: `.testbed/assets/fixtures/boxing/weave_left/boxing_guard->weave_left_repeat_04_take_01.mp4` sha256=`9100978cf5e933f686c0f3043558efe1f6c3da7058ddef01a723103119466afe`
- Capture report: `.temp/boxing-punch-classifier-export/hardened-captures-2026-06-16/captures/weave_left_fixture/report.json` sha256=`f24501a05b0a90882ab169348bed0e67e421f6413bbf8b631bc3111a087e478e`
- Truth windows: **5**

### weave_right_fixture
- Fixture YAML: `.testbed/assets/fixtures/boxing/weave_right/boxing_guard->weave_right_repeat_04_take_01.yaml` sha256=`709241c43cdbd0fa3c9849c9ad123b4ae817c12526faa71fc3d358827dc34a89`
- Source video: `.testbed/assets/fixtures/boxing/weave_right/boxing_guard->weave_right_repeat_04_take_01.mp4` sha256=`c53e905fefcb3358d976f4d52059afada0152d2bb6f3e16c981d8343e2bb3485`
- Capture report: `.temp/boxing-punch-classifier-export/hardened-captures-2026-06-16/captures/weave_right_fixture/report.json` sha256=`fd05da6aaf18872003ea66e2686b3ef0d694bc544fb4e7a1d17fa786bc8cad46`
- Truth windows: **5**

### squat_fixture
- Fixture YAML: `.testbed/assets/fixtures/boxing/squat/boxing_guard->squat_repeat_04_take_01.yaml` sha256=`739063522394fa9d64d4681901eb84cd70cd90b2d3a5f448bd3d6251439e642b`
- Source video: `.testbed/assets/fixtures/boxing/squat/boxing_guard->squat_repeat_04_take_01.mp4` sha256=`cb2c56cd84e1552e9327619320f039c1359287081270ef2071e0e139789f9580`
- Capture report: `.temp/boxing-punch-classifier-export/hardened-captures-2026-06-16/captures/squat_fixture/report.json` sha256=`abac6603ee891eddab66a2792f39b7f97cd7898fecc3a2b4e62d5dda0ba2b3df`
- Truth windows: **5**

### sidestep_left_fixture
- Fixture YAML: `.testbed/assets/fixtures/boxing/sidestep_left/boxing_guard->sidestep_left_repeat_04_take_01.yaml` sha256=`e2c78310d16f62ca16b8655ef17bf6716a6ef68cd91ef229fc0c15cb54e77c72`
- Source video: `.testbed/assets/fixtures/boxing/sidestep_left/boxing_guard->sidestep_left_repeat_04_take_01.mp4` sha256=`33dcc2aca0d830c560b8735314bbf2a58f4e3d88eedbe6688a2d6cefb4e774a1`
- Capture report: `.temp/boxing-punch-classifier-export/hardened-captures-2026-06-16/captures/sidestep_left_fixture/report.json` sha256=`c83133490864378d51b5d32b2d0295f625697e1bbca5052313a63bfbe8d743e6`
- Truth windows: **5**

### sidestep_right_fixture
- Fixture YAML: `.testbed/assets/fixtures/boxing/sidestep_right/boxing_guard->sidestep_right_repeat_03_take_01.yaml` sha256=`8b231e22f916355eabc6ba5034f6778b0d816d2b1b461f1a486a1360b64120b3`
- Source video: `.testbed/assets/fixtures/boxing/sidestep_right/boxing_guard->sidestep_right_repeat_03_take_01.mp4` sha256=`001c25fe91e95079f81060e5edc64d357749f393674ffecc317a18adcf989cda`
- Capture report: `.temp/boxing-punch-classifier-export/hardened-captures-2026-06-16/captures/sidestep_right_fixture/report.json` sha256=`c57dd86f3d8888c73ab8c57299a37d02f57d202232958d48dc554fa0ca9a678a`
- Truth windows: **4**

### leg_lift_left_fixture
- Fixture YAML: `.testbed/assets/fixtures/boxing/leg_lift_left/boxing_guard->leg_lift_left_repeat_04_take_01.yaml` sha256=`624cdab1bb9db222ff42cd25f2071fb3cbf3e41dd642030fa90c6b1ccb254a94`
- Source video: `.testbed/assets/fixtures/boxing/leg_lift_left/boxing_guard->leg_lift_left_repeat_04_take_01.mp4` sha256=`b67e692b95ded92c86e4bc1fcfdde6a10a51f47cafe5f2abf8a7cc8cd48670ce`
- Capture report: `.temp/boxing-punch-classifier-export/hardened-captures-2026-06-16/captures/leg_lift_left_fixture/report.json` sha256=`d8f41b7bc09f9081beb0ac537e531c4105ea75da68d5f1066c91d3ed39a34333`
- Truth windows: **5**

### leg_lift_right_fixture
- Fixture YAML: `.testbed/assets/fixtures/boxing/leg_lift_right/boxing_guard->leg_lift_right_repeat_04_take_01.yaml` sha256=`904f3e2537a61538d55bc4ca141fdf0f6746a41316b13dedbd1ac5d77fc0e4a1`
- Source video: `.testbed/assets/fixtures/boxing/leg_lift_right/boxing_guard->leg_lift_right_repeat_04_take_01.mp4` sha256=`2ca2efa1c0437a0ad865f9c831ef5a66beac5c14165ce99190d14a2949cda54e`
- Capture report: `.temp/boxing-punch-classifier-export/hardened-captures-2026-06-16/captures/leg_lift_right_fixture/report.json` sha256=`41a2cba0dcf36d5c1e066efaa503347814d8c9d14fc1a74ba9cf5350779ca49c`
- Truth windows: **5**

### knee_left_fixture
- Fixture YAML: `.testbed/assets/fixtures/boxing/knee_left/boxing_guard->knee_left_repeat_04_take_01.yaml` sha256=`3b9c7eb5772fb4556a5c008e8cd973838f19c4a02b590bbb569e9165c8322592`
- Source video: `.testbed/assets/fixtures/boxing/knee_left/boxing_guard->knee_left_repeat_04_take_01.mp4` sha256=`e386dff5735fc31e09d3ce1b2613c280398264c9230c846e10af5d34089eee71`
- Capture report: `.temp/boxing-punch-classifier-export/hardened-captures-2026-06-16/captures/knee_left_fixture/report.json` sha256=`a9e5bf9b610736ed0e9010506ab324768685a119c78b9edb084f1ddb8dba10cd`
- Truth windows: **5**

### knee_right_fixture
- Fixture YAML: `.testbed/assets/fixtures/boxing/knee_right/boxing_guard->knee_right_repeat_04_take_01.yaml` sha256=`e13484a9fece067ad1d2218d61a0e4570cce302c2f24fcaf7b6c0ced401e653d`
- Source video: `.testbed/assets/fixtures/boxing/knee_right/boxing_guard->knee_right_repeat_04_take_01.mp4` sha256=`e31891e1096586b7df13dc3c36d585dcbad005fbe5a402c5aaf5938ede2cf96c`
- Capture report: `.temp/boxing-punch-classifier-export/hardened-captures-2026-06-16/captures/knee_right_fixture/report.json` sha256=`10adeda9acf4b209f4cdbd90853ebc837a47c2b439fdd890fc5bf63b7d5ba300`
- Truth windows: **5**

### stance_transition_fixture
- Fixture YAML: `.testbed/assets/fixtures/boxing/stance_transition/boxing_guard->orthodox->center->southpaw_repeat_04_take_01.yaml` sha256=`44eab94787a461e31ee1484738a3b2fe4f1611419a62b27041bcb47f1f18ab2b`
- Source video: `.testbed/assets/fixtures/boxing/stance_transition/boxing_guard->orthodox->center->southpaw_repeat_04_take_01.mp4` sha256=`dc087715fad56819f1de13c0b88f68f10291b71ab9423664c87906ce4919801d`
- Capture report: `.temp/boxing-punch-classifier-export/hardened-captures-2026-06-16/captures/stance_transition_fixture/report.json` sha256=`0edcaa9ef926d218ddf4d7af0b766946c85d2b7c68badaa661315730c704df9f`
- Truth windows: **14**

## Recreate this snapshot target

```bash
python3 scripts/export_boxing_punch_classifier_dataset.py --snapshot-manifest .testbed/assets/benchmarks/boxing_punch_classifier_hardened_2026_06_16.snapshot.json --skip-captures --output-dir .temp/boxing-punch-classifier-export/boxing-punch-classifier-hardened-2026-06-16-rerun
```
