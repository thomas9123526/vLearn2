# plz go recommendation

Session: `d5a91a17-a96b-414b-9652-b5d2d7c4c94f`
Saved: 2026-06-02T13:52:54.764Z

## User

plz go recommendation

## Assistant

My recommendation: add `ANDROID_STUDIO_HOME` and `JAVA_HOME` (auto-detected, prompted to confirm), run `flutter config --android-studio-dir` as part of setup, skip Visual Studio entirely (auto-detected). Let me update `setup.ps1` now.

## Assistant

Now commit with story:

## Assistant

Done. Now run `.\cmds\setup.ps1` in your terminal. It will auto-detect and show you:

- **Android Studio** — checks `C:\Program Files\Android\Android Studio` and `E:\vm_share\...` variants
- **JAVA_HOME** — defaults to the JDK bundled inside Android Studio (`jbr\` folder)
- **Android SDK, Gradle, Pub cache** — same as before

Just press Enter for each one if the detected path looks right, then it runs `flutter config --android-studio-dir` automatically. Finish with `flutter doctor` to confirm everything is green.
