# Flutter app — flutter pub get (flutter_app/) Runtime deps: flutter_riverpod ^2.5

Session: `ec7e9529-1399-4642-b1c1-753f53834cc7`
Saved: 2026-06-04T07:11:09.663Z

## User

Flutter app — flutter pub get (flutter_app/)
Runtime deps:


flutter_riverpod ^2.5.1        # state management
riverpod_annotation ^2.3.5
go_router ^14.2.0              # navigation
dio ^5.4.3+1                   # HTTP
retrofit ^4.1.0
pretty_dio_logger ^1.4.0
drift ^2.18.0                  # local SQLite ORM
sqlite3_flutter_libs ^0.5.22   # SQLite native libs
path_provider ^2.1.3
path ^1.9.0
freezed_annotation ^2.4.2
json_annotation ^4.9.0
rive ^0.14.7                   # avatar animation
intl ^0.20.2
cupertino_icons ^1.0.8
cached_network_image ^3.3.1
flutter_svg ^2.0.10+1
fl_chart ^0.68.0
connectivity_plus ^6.0.5
image_picker ^1.1.2
shared_preferences ^2.2.3
flutter_secure_storage ^9.2.2
logger ^2.3.0
collection ^1.18.0
crypto ^3.0.3
equatable ^2.0.5
package_info_plus ^8.0.0
device_info_plus ^10.1.0
pointycastle ^3.9.1            # AES-GCM / ECDH for .ddp decrypt
archive ^3.6.1
asn1lib ^1.6.0
sherpa_onnx ^1.13.0            # on-device STT + TTS (ONNX runtime)
permission_handler ^11.3.1
record ^6.0.0                  # mic capture
audioplayers ^6.0.0            # WAV playback
Dev deps (codegen — run dart run build_runner build):


build_runner ^2.4.11
riverpod_generator ^2.4.0
custom_lint ^0.6.4
riverpod_lint ^2.3.10
drift_dev ^2.18.0
freezed ^2.5.2
json_serializable ^6.8.0
flutter_native_splash ^2.4.4
flutter_lints ^6.0.0

above components are all in pub cache?

## Assistant

Let me check the pub cache.

## Assistant

All packages are cached. Here's the match against your list:

**Runtime deps — all present:**

| Package | Required | Cached |
|---|---|---|
| flutter_riverpod | ^2.5.1 | 2.6.1 ✅ |
| riverpod_annotation | ^2.3.5 | 2.6.1 ✅ |
| go_router | ^14.2.0 | 14.8.1 ✅ |
| dio | ^5.4.3+1 | 5.9.2 ✅ |
| retrofit | ^4.1.0 | 4.9.2 ✅ |
| pretty_dio_logger | ^1.4.0 | 1.4.0 ✅ |
| drift | ^2.18.0 | 2.21.0 ✅ |
| sqlite3_flutter_libs | ^0.5.22 | 0.5.42 ✅ |
| path_provider | ^2.1.3 | 2.1.5 ✅ |
| freezed_annotation | ^2.4.2 | 2.4.4 ✅ |
| json_annotation | ^4.9.0 | 4.9.0 ✅ |
| rive | ^0.14.7 | 0.14.7 ✅ |
| intl | ^0.20.2 | 0.20.2 ✅ |
| fl_chart | ^0.68.0 | 0.68.0 ✅ |
| connectivity_plus | ^6.0.5 | 6.1.5 ✅ |
| image_picker | ^1.1.2 | 1.2.2 ✅ |
| shared_preferences | ^2.2.3 | 2.5.5 ✅ |
| flutter_secure_storage | ^9.2.2 | 9.2.4 ✅ |
| pointycastle | ^3.9.1 | 3.9.1 ✅ |
| archive | ^3.6.1 | 3.6.1 ✅ |
| asn1lib | ^1.6.0 | 1.6.5 ✅ |
| sherpa_onnx | ^1.13.0 | 1.13.2 ✅ |
| permission_handler | ^11.3.1 | 11.4.0 ✅ |
| record | ^6.0.0 | 6.2.0 ✅ |
| audioplayers | ^6.0.0 | 6.6.0 ✅ |
| (all others) | | ✅ |

**Dev deps — all present:** build_runner, riverpod_generator, custom_lint, riverpod_lint, drift_dev, freezed, json_serializable, flutter_native_splash, flutter_lints — all cached.

`flutter pub get` will resolve fully offline. No network needed.
