# But I'm targeting real phone device finally

Session: `5720bd49-f606-4621-9507-92b65f44e5e5`
Saved: 2026-05-28T17:09:17.671Z

## User

But I'm targeting real phone device finally

## Assistant

Then the zero-peak issue is just LDPlayer's virtual mic not routing host audio — it's not a real bug. On a physical Android phone the microphone captures actual sound, so STT will work.

The `voiceRecognition` audio source change is still the right call for a real device — it's the standard `AudioSource` that Android's speech recognition framework uses, and it applies noise suppression / gain control tuned for voice input. No need to revert it.

So the current state is fine for production:
- **Real phone**: mic captures audio → `peak` will be non-zero → STT transcribes normally
- **LDPlayer**: mic captures silence → empty result (expected limitation of the emulator's audio passthrough)

If you want to test the full STT flow before deploying to a real device, you'd need to configure LDPlayer's microphone passthrough in its settings — but that's optional since real-phone behavior is what matters.
