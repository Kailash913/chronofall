# Chronofall
A complete small three-room 2D puzzle platformer built in Godot 4.6.3.

## Play
Android: install Chronofall.apk (Android 7.0+, ARMv7 or ARM64, OpenGL ES 3 compatible device). This is a debug-signed standalone build for sideloading, not a Play Store release. Allow installation from the app opening the APK if Android requests it.
Windows: run Chronofall.exe on 64-bit Windows 10 or later, with an OpenGL 3.3 compatible graphics driver. No Godot installation required.

Keyboard: A/D or arrows move; Space or Up jumps; Q rewinds; E advances time; R restarts the room; Escape pauses. Android uses the on-screen buttons with multi-touch.

Acquire the gauntlet on the raised platform in the first room. Hold Q to restore the bridge, then release it to cross. Q also retraces up to eight seconds of your movement. Hold E to grow the garden in the second room. In the final room, restore the left bridge, jump onto the moving lift, advance time to build the right bridge, then jump across. Collect the gold memory in each room before entering the exit.

World age stays where you leave it when releasing Q/E. Machinery continues moving; time powers affect its direction and speed. Memories and the gauntlet survive falls and room restarts within the current run. Progress is not saved after closing the game.

## Source
Open project.godot in Godot 4.6.3. All visuals are original procedural drawing. No external game assets or packages are required.
Install official Android/Windows export templates to rebuild. Set local Java SDK and Android SDK paths in Godot Editor Settings. Configure your own Android keystore in the export preset. The distributed APK uses a development signing key.

## Validation
Automated Godot runtime checks cover floor landing, gauntlet acquisition, player rewind, bridge restoration/decay, garden growth, moving lift, all clues, clue retention after falls, all room exits, and victory. Native Linux OpenGL rendering was inspected. APK signing verification passed (v2 and v3). Android and Windows exports succeeded; neither binary has been run on a physical Android device or Windows host here.
