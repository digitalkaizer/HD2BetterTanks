# HD2 Tank Config source

The original v1.0.0 Better Tanks source archive is preserved here as six split Base64 parts.

Run:

```bash
python rebuild_source_archive.py
```

This reconstructs:

`HD2_Better_Tanks_v1.0.0_Source.tar.xz`

Base archive SHA-256:

`503f8a2f9f0b70ce62f950532a5ffffc851b9be616c62ed759039c77c87d8da7`

## Current Tank Config development delta

The latest committed Tank Config source delta is:

`Tank_Config_v1.1.0_RC12.patch`

RC12 changes the Maelstrom runtime/HUD discovery logic so it accepts the full supported configuration range for identification rather than using the currently selected target value as a hard ceiling. This fixes the case where lowering spare Gatling belts from 8 to 5 prevented the TD-110 four-magazine cluster from binding until enough reloads had occurred. It also updates the driver HUD to accept live Gatling and missile values across the supported ranges without reintroducing the periodic whole-pool scans removed in RC9.

The RC12 patch is a delta from the RC11 source tree.

## Historical v1.0.0 hotfix

The v1.0.0 release included the Bastion HMG HUD capacity fix in:

`HMG_HUD_hotfix.patch`

After extracting the reconstructed v1.0.0 source archive, apply it from the extracted source directory with:

```bash
patch -p1 < ../HMG_HUD_hotfix.patch
```
