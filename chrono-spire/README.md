# Chrono-Spire

A complete short, three-sector 3D time-manipulation mission built with Godot 4.6.3. Original procedural sci-fi art uses hard color ramps, angular geometry, cyan/amber trims, and a restrained tactical HUD. No Riot/Valorant assets are included.

## Download and play

- [Android release APK](https://raw.githubusercontent.com/Kailash913/chronofall/main/downloads/ChronoSpire.apk)
- [Windows x86_64 ZIP](https://raw.githubusercontent.com/Kailash913/chronofall/main/downloads/ChronoSpire-Windows.zip)
- [Build report, validation and limitations](BUILD_REPORT.md)

Android: ARM64, Android 7.0 or newer. Download the APK, open it and permit installation from that browser if Android prompts. Vulkan is preferred; Godot's OpenGL ES compatibility fallback is enabled. This is a release-signed standalone sideload build, not a Play Store listing. It installs separately from earlier Chronofall prototypes.

Windows: extract the ZIP and run ChronoSpire.exe. No Godot install needed. Direct3D 12 is preferred, with Vulkan/OpenGL compatibility fallbacks enabled. A modern 64-bit Windows version and supported graphics driver are required. The executable is not Authenticode-signed.

## Mission

Agent Vance descends into the Chrono-Spire after a time-crystal containment failure. Reconstruct a fractured catwalk, corrode a titanium door, and reflect a turret's own projectile to reach the Warden Foundry. Defeat Chrono-Stalkers and Temporal Remnants. Rewind the Phase Golem's armor to expose its core, then seal the Singularity.

Three sectors unlock in Temporal Archives; checkpoint unlocks and settings persist between runs. A failed mission can restart at its current sector checkpoint. Re-entering an unlocked sector begins that sector with full health and energy.

## Controls

| Action | Windows | Android |
|---|---|---|
| Move | WASD | Left floating stick |
| Aim | Mouse | Right floating stick / optional gyro |
| Sprint | Shift | Sprint button |
| Jump | Space | Jump button |
| Fire / seal core | Left mouse | Fire button |
| Target lock | Right mouse | Lock button |
| Rewind | Hold Q | Hold Reverse |
| Fast-forward | Hold E | Hold Forward |
| Chrono-bubble | Hold F | Hold Bubble |
| Echo visibility | T | Enabled by default |
| Pause | Escape | Top-right pause button |

Aim at a temporal target and lock it; then hold a power. Without a selected target, rewind retraces Vance's recent position and restores recorded health. Release powers to recharge. Bubble slows enemies and incoming bolts within 18 meters to 10% speed while Vance retains normal movement. Rewinding a locked bolt sends it to its original attacker. The Golem is immune to kinetic damage until a one-second armor rewind opens a five-second vulnerability. Stalkers teleport near Vance's recorded past location when a rewind begins.

The ring buffer retains 480 fixed-tick samples (eight seconds at 60 Hz): transform, linear/angular velocity, structural flags, animation ID and health. Structural restoration/decay is authored along deterministic age states so puzzles remain solvable after waiting longer than the ring's duration. Echoes sample past enemy, bolt and puzzle transforms at one-second intervals out to four seconds; they are silhouettes rather than full duplicate actors.

## Build

Godot 4.6.3 official Android and Windows export templates are required. Configure Java and Android SDK paths in Godot editor settings. This build used Java 21, Android SDK 36/build-tools 36.0.0. Java 17+ is supported by the normal Godot Android setup.

```sh
python3 pipeline/generate_assets.py
godot --headless --editor --quit
godot --headless --script res://tests/test_mechanics.gd
godot --headless --script res://tests/test_touch.gd
godot --headless --fixed-fps 60 --script res://tests/playthrough.gd
# Set these in your shell/secret manager without committing their values:
# GODOT_ANDROID_KEYSTORE_RELEASE_PATH
# GODOT_ANDROID_KEYSTORE_RELEASE_USER
# GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD
python3 pipeline/build.py
```

Outputs: `builds/android/ChronoSpire.apk`, `builds/windows/ChronoSpire.exe`, `builds/checksums.json`, and `logs/`. Windows game data is embedded in the EXE.

## Assets and licensing

The supplied Kenney URL returned HTTP 404. No third-party model or sound download was used. `pipeline/generate_assets.py` generates the beveled mesh and eight original 16-bit mono WAVs (ambient, reverse, forward, step, shot, impact, switch, bubble). Runtime MultiMeshes generate the modular environment and characters. See `assets/ASSET_MANIFEST.json`. These generated assets are offered under CC0-1.0. Godot and its third-party license notices are in `licenses/`.

## Practical scope

This is a short procedural game, not a commercial-scale art production. It has no voice acting, multiplayer, full skeletal character animation, or asset-store models. Mobile draw calls are reduced with instancing, no dynamic shadows, simple materials, and a limited enemy count; adaptive render resolution targets 60 FPS. Phone FPS, thermal behavior, gyro behavior, Direct3D 12, and Vulkan have not been measured on native hardware here. Godot uses its own native/GDScript runtime; Unity URP and IL2CPP do not apply. Texture compression import support is enabled, but geometry and shaders supply the art, with no photographic texture set.
