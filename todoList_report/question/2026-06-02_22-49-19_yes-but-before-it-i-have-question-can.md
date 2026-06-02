# yes but before it, I have question. can the setup.ps1 handle environment path fo

Session: `d5a91a17-a96b-414b-9652-b5d2d7c4c94f`
Saved: 2026-06-02T13:49:19.778Z

## User

yes but before it, I have question.
can the setup.ps1 handle environment path for androidstudio and MSVisualStudio2022?

## Assistant

Short answer: **yes for Android Studio path** (useful if it's in a non-standard location like `E:\vm_share\`), **probably not needed for Visual Studio** — Flutter finds VS 2022 automatically via `vswhere.exe` regardless of where it's installed.

Here's what each one actually needs:

| Tool | How Flutter finds it | Env var needed? |
|---|---|---|
| Android Studio | Common install paths, or `flutter config --android-studio-dir=...` | Only if non-standard path |
| Java/JDK | `JAVA_HOME`, or bundled JDK inside Android Studio | **Yes** — often missing |
| Visual Studio 2022 | Auto via `vswhere.exe` (registry) | No, auto-detected |

The practical question is: **is Android Studio in a non-standard location on your machine** (e.g. `E:\vm_share\AndroidStudio` or similar)?

If yes → I'll add a prompt for it to `setup.ps1`, set `ANDROID_STUDIO_HOME`, and auto-derive `JAVA_HOME` from the JDK bundled inside it (at `AndroidStudio\jbr`).

If it's in the default `C:\Program Files\Android\Android Studio` → no env var needed, Flutter finds it automatically.

Which is it on your machine?
