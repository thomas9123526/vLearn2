# what is the current sherpa-onnx version? like sherpa-onnx-v1.13.0-android.tar.bz

Session: `8d92f8df-87dc-4445-9439-b132351a0dcd`
Saved: 2026-06-02T04:48:17.033Z

## User

what is the current sherpa-onnx version? like sherpa-onnx-v1.13.0-android.tar.bz2

## Assistant

Let me check the project files for the current sherpa-onnx version.

## Assistant

The project uses **`sherpa_onnx: ^1.10.46`** (from [flutter_app/pubspec.yaml:88](flutter_app/pubspec.yaml#L88)).

That means the Android archive in use would be **`sherpa-onnx-v1.10.46-android.tar.bz2`** (or whichever patch version `^1.10.46` resolves to — check `flutter_app/pubspec.lock` for the exact pinned version).

## Assistant

The pinned version is **`1.13.2`**, so the Android archive would be:

```
sherpa-onnx-v1.13.2-android.tar.bz2
```

(`pubspec.yaml` has `^1.10.46` as the constraint, but `pub get` resolved it to `1.13.2`.)
