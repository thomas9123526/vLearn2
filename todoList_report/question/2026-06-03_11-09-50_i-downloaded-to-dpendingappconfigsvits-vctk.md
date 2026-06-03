# I downloaded to D:\Pending\app_configs\vits-vctk

Session: `cb14393c-1d33-4891-aee0-276d4c902efe`
Saved: 2026-06-03T02:09:50.964Z

## User

I downloaded to D:\Pending\app_configs\vits-vctk

## Assistant

Good. I'll use the `int8` model (38 MB, better for Android). Let me copy the files into the sherpa tts folder, replacing the old Amy model.

## Assistant

Now rebuild the manifest with two named voices — `en_VCTK-amy` (SID 0 = female speaker p225) and `en_VCTK-james` (SID 1 = male speaker p226):

## Assistant

Python isn't in PATH for this shell. Let me run the Python script directly:

## Assistant

Manifest looks correct. Now copy it to the project's `models/` folder and push to device:

## Assistant

Now push everything to the device:

## Assistant

No device connected right now — you'll push when the emulator is running. Let me commit the code change first:

## Assistant

The dart file was already committed. Only `models/manifest.json` needs committing:

## Assistant

Now save the story and then I'll tell you what to do next:

## Assistant

Done. Here's what to do when the emulator is running:

```powershell
adb push "D:\Pending\sherpa_2023\." /storage/emulated/0/Android/data/com.ryongma.vfls/files/models/
```

Then in the app go to **Settings → Storage → Re-verify all** to pick up the new manifest.

After that, switching to a male tutor should use the `en_VCTK-james` voice (SID 1 = VCTK speaker p226, male) and female tutors use `en_VCTK-amy` (SID 0 = p225, female). The VCTK voices sound different from Piper — slightly more robotic but clearly distinguishable male vs female.
