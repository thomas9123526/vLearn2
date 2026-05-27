# I have to make a large space on c drive. Can i move android sdk and .gradle to E

Session: `1eb40659-e5c9-4cd9-aa44-b57f47d3b5f7`
Saved: 2026-05-27T13:51:31.848Z

## User

I have to make a large space on c drive.
Can i move android sdk and .gradle to E drive? if yes i will move manually and let you know because flutter knows the location and configured the path for it.

## Assistant

Yes, you can move both safely. They're just directories that tools look up via environment variables or config files.

**Android SDK** → set `ANDROID_HOME` (or `ANDROID_SDK_ROOT`) env var to the new E: path. Android Studio and Flutter both read this.

**Gradle cache** (`%USERPROFILE%\.gradle`) → set `GRADLE_USER_HOME` env var to the new E: path.

After you move them manually, set those env vars in System Properties → Environment Variables, then run `flutter doctor` to confirm Flutter finds everything. Let me know when you're done and I can help fix anything that's still pointing at C:.
