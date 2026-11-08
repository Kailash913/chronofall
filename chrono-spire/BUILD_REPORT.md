# Chrono-Spire 1.0 build report

## Artifacts

| Target | Local output | Format |
|---|---|---|
| Android | `/workspace/chrono-spire/builds/android/ChronoSpire.apk` | Release-signed ARM64 APK; package `com.chronofall.chronospire`; Android API 24 minimum, target 36 |
| Windows | `/workspace/chrono-spire/builds/windows/ChronoSpire.exe` | PE32+ x86_64 standalone executable with embedded PCK |
| Windows distribution | `/workspace/chrono-spire/builds/windows/ChronoSpire-Windows.zip` | EXE, instructions and engine license notices |

Checksums are in [checksums.json](checksums.json). Signing material is stored privately outside the project and excluded from the repository and source archives.

## Environment and assets

- Existing official Godot **4.6.3** Linux engine and matching official Android/Windows export templates reused; no downgrade to 4.3.
- Python 3.12.14, Node 24.22.1, OpenJDK 21.0.13, Android SDK/build-tools 36.0.0.
- Initial inspection: approximately 3.9 GiB free disk and 9.0 GiB available memory. See [environment log](logs/environment.log).
- The supplied Kenney Starter-Kits URL returned **HTTP 404**. No unverified model download was substituted. See [fetch log](logs/asset-fetch.log) and [asset manifest](assets/ASSET_MANIFEST.json).
- Procedural fallback generated one beveled OBJ used in characters, eight 16-bit mono WAVs, and runtime instanced modular walls, slabs, floors, machinery, character armor and weapon sockets. All generated assets are original and CC0-1.0. No third-party model/audio assets were downloaded.
- Godot's official license and copyright notices were downloaded from its `4.6.3-stable` source tag and accompany the Windows ZIP.

## Validation completed

- [20 mechanics assertions](logs/tests.log): circular wrap/order/state retention; movement onboarding; bridge collision restoration; hinge decay/collision removal; turret spawn; 90% bolt slowdown; reflection; reflected turret kill; checkpoints; Stalker ambush; boss spawn; five-second armor window and expiry; final core interaction.
- [Touch test](logs/touch.log): simultaneous move/look/power inputs, release cleanup, pause and resume.
- [Physical playthrough](logs/playthrough.log): normal collision/movement, bridge, door, turret reflection, foundry combat, boss counter and final seal. Completed in 1,978 simulation ticks, with **70 health and zero falls**, without invulnerability. The controller aims programmatically and is not a human usability test.
- [Rendering check](logs/render.log): original 3D menu, induction, mobile layout, boss and a stress scene rendered on Linux Mesa software OpenGL. Measured frame draw calls: menu **63**, induction **44**, mobile HUD **66**, boss **39**, boss + ten projectiles + echoes + mobile HUD **72**. These are sampled scenes, not a proof of a universal maximum across devices/renderers.
- [Android signature](logs/apk-signature.log): verified APK Signature Schemes v2 and v3.
- [Android alignment](logs/apk-alignment.log): `zipalign -c -P 16 4` exited successfully.
- Android manifest inspected: ARM64 only; API 24 minimum / API 36 target; release export, no debug application flag.
- Windows artifact identified with `file` as a PE32+ x86_64 GUI executable.
- Final mechanics, touch, playthrough, Android export, Windows export and render logs contain no script/build errors.

## Graphics and platform mapping

Godot Mobile renderer is selected for Android with **Vulkan** preferred. Windows selects the Mobile renderer with **Direct3D 12** preferred. Godot Vulkan and OpenGL compatibility fallbacks are enabled. The Linux QA host uses OpenGL compatibility; native Vulkan/D3D12 paths are configured but not executed here.

Godot uses native engine binaries plus GDScript. **URP and IL2CPP are Unity-only and do not apply.** ASTC/ETC2 import support is enabled; flat procedural materials and meshes avoid heavy texture memory. Static geometry is grouped into color-based MultiMeshes. Dynamic shadows and post-processing are disabled. Mobile resolution scales from 55% toward the selected 65/80/100% cap, targeting 60 FPS.

## Remaining verification limits

No physical Android phone or Windows host was available. Native installation, device-specific graphics fallback, gyro behavior, mobile frame rate/thermal load and Direct3D 12 behavior remain unverified. The APK is release-signed for sideloading; the Windows EXE has no Authenticode signature. This is a short complete procedural mission, not commercial-scale art or a long campaign. The echoes show sampled transforms rather than fully animated duplicate characters.

Non-blocking host warnings: the software X11 driver cannot change VSync, and export tooling reports no connected ADB daemon/device. Both exports complete successfully.

## Reproduction

See [README](README.md) and [pipeline/build.py](pipeline/build.py). Each run imports the project, runs all automated mechanics/input/playthrough tests, creates both release exports, and writes checksums. Android signing credentials must be supplied via the documented environment variables; no private key or password is published.
