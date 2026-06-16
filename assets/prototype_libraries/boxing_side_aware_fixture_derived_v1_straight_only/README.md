# Boxing Side-Aware Fixture Derived V1 Straight-Only

Filtered benchmark-only variant of `boxing_side_aware_fixture_derived_v1` that preserves the committed straight prototypes while omitting hook and uppercut classes.

- Library id: `boxing_side_aware_fixture_derived_v1_straight_only`
- Source library: `../boxing_side_aware_fixture_derived_v1/library.json`
- Kept classes: `straight_left`, `straight_right`
- Kept prototypes: 8 total (4 per straight_left, 4 per straight_right)

This artifact exists only to isolate whether the current prototype matcher can distinguish straight-left and straight-right from the no-punch threshold/rejection path when non-straight prototype competition is removed. Matcher logic, thresholds, cooldowns, and hold behavior remain unchanged.
