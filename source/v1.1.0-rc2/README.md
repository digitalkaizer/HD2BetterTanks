# HD2 Better Tanks v1.1.0 RC2 test source

RC2 builds on the RC1 drivetrain work and fixes Storm missile-capacity handling plus DRIVER HUD compatibility.

## Confirmed missile layout

- Storm/Maelstrom has two independent rear missile racks.
- Stock capacity is 10 missiles per rack (20 total).
- DRIVER HUD 1.5.0 identifies the rocket weapon resource as `8aff7f0793a5bced`.
- The corresponding Better Tanks WeaponMagazine entity is `0x8AFF7F0793A5BCED` (`edbca593077fff8a` as the little-endian map key).

## RC2 changes

- Replaces `storm_missiles_total` with `storm_missiles_per_rack` in the public config. Legacy even totals are migrated automatically.
- Patches the exact Storm rocket WeaponMagazine `Capacity` field, rather than only editing the two live rack counters.
- Keeps both live rack counters synchronized to the configured per-rack capacity while preserving missiles already fired during hot reload.
- Rebases the optional Better Tanks integrated HUD on DRIVER HUD 1.5.0 by FireScallion (MIT).
- Makes DRIVER HUD's Bastion cannon/HMG, Storm Gatling belt/reserve, Storm rack capacity, and reload timing aware of Better Tanks configuration.
- Retains RC1 clutch-delay, geared top-speed/torque, Havok turn-scale, and dual throttle/brake ramp changes.

The exact complete RC2 source is included in `HD2_Better_Tanks_v1.1.0_RC2_Source.zip` on this branch. This branch is test-only; `main` remains on the published v1.0.0 until the build is approved.
