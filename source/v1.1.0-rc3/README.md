# HD2 Better Tanks v1.1.0 RC3 test source

RC3 adds optional integration with CowboyBingus Mod Options Menu API 1 while retaining the RC2 drivetrain, Storm missile-capacity, and DRIVER HUD 1.5.0 compatibility work.

## Mod Options Menu integration

- Registers all 57 numeric Better Tanks settings when `ModOptionsMenu.api == 1` is present.
- Uses two menu categories because Mod Options Menu supports 32 rows per category:
  - `BETTER TANKS - BASTION`: 29 options, including the 3 shared tracked-drivetrain settings.
  - `BETTER TANKS - STORM`: 28 options.
- `digitalKaizer-BetterTanks.ini` remains authoritative.
- At startup the menu is synchronized from the INI, overriding stale values in Mod Options Menu's own saved-value store.
- Pressing APPLY queues changed values and rewrites only the matching numeric values in the Better Tanks INI while preserving comments and ordering.
- Better Tanks remains fully functional if Mod Options Menu is not installed.
- Restart Helldivers 2 for guaranteed application of every setting. Some Storm weapon settings already support runtime hot reload.

The bridge source is `mod_options_bridge.lua` in this directory. Mod Options Menu v1.0.1 currently requires Bingus Shared Loader v18+ for its native menu integration.