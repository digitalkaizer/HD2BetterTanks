# HD2 Better Tanks v1.1.0 RC1 test source

This directory contains the source changes for the v1.1.0 RC1 test build. The published v1.0.0 source archive remains in the parent `source/` directory until this build is approved for release.

Changes in RC1:

- Added `drivetrain.lua` for exact-build-guarded tracked-vehicle Havok tuning.
- Added `tracked_clutch_delay_seconds` (default `0.0`; stock tank is approximately `0.4`).
- Added `tracked_top_speed_scale` (default `1.2`), implemented as primary transmission ratio / scale plus max engine torque * scale.
- Added `tracked_driving_turn_scale` (default `1.2`), scaling Havok steering max angle and full-angle speed.
- Existing throttle response now writes both internal ramp fields at `+0x170/+0x174`.
- Existing brake response now writes both internal ramp fields at `+0x178/+0x17C`.
- The new Havok drivetrain settings currently apply to tracked player vehicles as a shared runtime layer; Bastion/Storm identity is not separately mapped at this level in RC1.
- Runtime drivetrain writes are guarded to the currently supported executable layout and fail closed on mismatch.

`core.patch` is the delta from the v1.0.0 core source. The complete RC1 source archive is kept with the local test build and will replace the published source archive after approval.
