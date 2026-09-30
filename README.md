# Tank Config v1.1.0

Tank Config is a configurable overhaul for the **TD-220 Bastion** and **TD-110 Maelstrom** in Helldivers 2. It exposes tank durability, armor, handling, weapons, ammunition, utility systems, cooldowns and fire-control layout through CowboyBingus' Mod Options Menu.

All user-facing defaults are vanilla. With a few exceptions, adjustable values are intentionally constrained to roughly **50% to 200% of stock vanilla values**, giving you room to tune the tanks to your preferred balance without turning every option into an unlimited cheat slider.

## Requirements

- Helldivers 2
- Bingus Shared Loader v18+
- CowboyBingus Mod Options Menu v1.0.1+
- Arsenal for the supported installation method

## Installation

Install the archive through **Arsenal** and enable **Core - Tank Config**.

The **Integrated Tank HUD** option is optional. It displays tank health and ammunition using Tank Config's configured values and live vehicle state.

No manual-install support is provided.

## Configuration

Open **ESC -> MODS** and configure Tank Config from its three sections:

- **Tank Config: General** — shared durability, armor, damage transfer, handling, traction and stratagem cooldown settings.
- **Tank Config: Bastion** — cannon/HMG ammunition, fire rate, reload time and fire-control layout.
- **Tank Config: Maelstrom** — Gatling ammunition, spare belts, reload time, fire rate, smoke, rear missiles and fire-control layout.

Press **APPLY** after changing settings. Some structural or template-based changes are guaranteed on the next freshly spawned tank.

## General Features

- Main health
- Destroyed-tank secondary explosion delay
- Frontal, stowage, side-skirt and structural hull armor classes
- Stowage, side-skirt and other hull-zone damage transfer to main health
- Explosive damage received
- Acceleration
- Steering response
- Throttle response
- Brake response
- Clutch delay
- Geared top speed
- Driving turn authority
- Track traction
- Tank stratagem cooldown

Armor choices are **Light (AV2), Medium (AV3), Heavy (AV4), and Tank (AV5)**.

## Bastion Features

- Cannon total shells
- Coaxial HMG ammunition
- Cannon fire rate
- HMG fire rate
- Cannon reload time
- Standard or inverted fire-control layout

## Maelstrom Features

- Gatling rounds per belt: **300-1000**
- Spare Gatling belts: **3-6**
- Gatling reload time
- Combined Gatling fire rate
- Smoke charges
- Smoke launch delay
- Rear missiles
- Standard or inverted fire-control layout

## Integrated Tank HUD

The optional integrated HUD displays live tank health and ammunition for supported tank seats. It follows configured Bastion and Maelstrom capacities, including Maelstrom Gatling belts and rear missiles.

The HUD includes compatibility work derived from **Driver HUD**. See `THIRD_PARTY_LICENSE.txt` and `CREDITS.txt`.

## Compatibility

- Compatible with **360 Turret Mod** by **IvoryApples**: https://ayakamods.com/members/ivoryapples.399599/
- Mostly compatible with **World of Tanks: Solo Driver** by **M!ni$try0fSc!eиce**. UI problems caused by Solo Driver are outside Tank Config and cannot be reliably corrected by a Tank Config compatibility patch.
- If using Solo Driver, load it **before Tank Config** so Tank Config's fire-control layout can take precedence.
- Avoid combining Tank Config with other mods that directly edit the same tank health, armor, handling, ammunition, weapon timing, smoke, missile-capacity, cooldown or HUD data.

## Downloads

- Nexus Mods: https://www.nexusmods.com/helldivers2/mods/16771
- GitHub Releases: https://github.com/digitalkaizer/HD2TankConfig/releases

## Logs

Tank Config writes runtime information to:

`%LOCALAPPDATA%\CowboyBingus\Helldivers2\Logs\TankConfig.log`

## Support

Ko-fi: https://ko-fi.com/digitalkaizer

## Credits

- **CowboyBingus** — Bingus Shared Loader, Mod Options Menu, and the HD2 modding ecosystem that makes this possible.
- **FireScallion / Driver HUD developer** — Driver HUD compatibility/HUD work used by Tank Config under the included MIT notice.
- **IvoryApples** — 360 Turret Mod compatibility.
