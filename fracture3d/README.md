# Chronofall: Fracture — 3D prototype

[Android APK](https://raw.githubusercontent.com/Kailash913/chronofall/main/downloads/Chronofall3D.apk) | [Windows EXE](https://raw.githubusercontent.com/Kailash913/chronofall/main/downloads/Chronofall3D.exe)

An original geometric 3D arena shooter with a short three-wave story: recover the stolen temporal cores and restore tomorrow. Includes a title menu, guided controls tutorial, segmented Wardens, synthetic shot/hit sounds, aim assist, player-position/health rewind, and enemy slow time. This prototype uses one arena across three escalating encounters; it is not a finished detailed campaign.

WASD moves; left/right arrows turn; Space shoots; Q rewinds; E slows enemies. Touch buttons support the same actions. Training pauses enemy movement until the four actions are completed or 45 seconds pass. Rewind restores recent player position and health; time charge replenishes outside power use.

Mobile-oriented rendering uses low polygon meshes, shared simple geometry, no dynamic shadows, no large textures, no post-processing, and at most seven enemies. Performance has not been measured on physical phones. OpenGL ES 3 required; Android 7+, ARMv7/ARM64. The APK is debug-signed and installs separately from the original 2D game. Windows build requires 64-bit Windows and OpenGL 3.3.

Runtime checks cover startup, mission start, rewind history and charge, three-wave progression, and victory. Native OpenGL rendering inspected on Linux; Android and Windows binaries exported but not device-tested. No saved progression or full audio soundtrack yet.

Open this directory's project.godot in Godot 4.6.3 to edit. Run tests with `godot --headless --path . --script test3d.gd`.
