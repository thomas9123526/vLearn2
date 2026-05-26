# Can you tell me if my suggestion is possible? So the android apk size is big, ab

Session: `c8b9bc59-8e0b-457d-a3e0-6557fcbf5b50`
Saved: 2026-05-26T15:54:45.182Z

## User

Can you tell me if my suggestion is possible?

So the android apk size is big, above 210mb.
I extract the apk and analyze the files and found that .so files sizes are bigger.

Is it possible to compress them using datamanage and when the app launches , the app uncompress or copy those so files to particular folder and  manually load .so files like System.load("absolute path ")

Is it possible? You can see so files list in png file.
But I'm not sure if i can compress libflutter.so also .

## Assistant

Let me check the current build settings first — your numbers suggest a few standard wins before the manual-load path.

## Assistant

Yes, technically possible — but you're looking at a debug build right now (the path is `apk/debug/...` and `libVkLayer_khronos_validation.so` is a debug-only Vulkan layer). Before the custom decompress route, you can probably get to a normal-sized APK with three settings changes. Then the manual-load trick is a fallback for what's still too big.

## What's bloating the APK now

Your `app/build.gradle.kts` has:
- ✅ `abiFilters += listOf("arm64-v8a", "x86_64")` — good for one ABI, but **x86_64 is emulator-only**. Real phones are arm64.
- ❌ No `useLegacyPackaging` flag — AGP 8 default leaves `.so` files **uncompressed** in the APK for direct `mmap`.
- ❌ No per-ABI splits.

## Standard wins (try in this order — costs ~10 min, saves ~70-80%)

### 1. Build release, not debug
The screenshot is from `outputs/apk/debug/`. Release strips a lot:

```bash
cd flutter_app
flutter build apk --release
```

Expected drops in `lib/arm64-v8a/`:
- `libVkLayer_khronos_validation.so` (14 MB) → **gone** (debug-only)
- `libflutter.so` (36 MB) → ~14 MB (debug symbols stripped)
- `libonnxruntime.so` (25 MB) → ~15 MB (no debug symbols)

### 2. Drop x86_64 from the release APK
Edit [flutter_app/android/app/build.gradle.kts:38](flutter_app/android/app/build.gradle.kts#L38):

```kotlin
abiFilters += listOf("arm64-v8a")  // x86_64 only needed for emulator builds
```

Halves the APK at one stroke.

### 3. Compress `.so` files inside the APK
Add to the `android { ... }` block:

```kotlin
packaging {
    jniLibs {
        useLegacyPackaging = true   // DEFLATE .so inside APK; Android extracts at install
    }
}
```

Further ~30-50% off the `.so` payload. Note: increases install-time disk a bit (extracted *and* compressed-in-APK copies coexist on disk briefly).

### 4. (Optional) Per-ABI split / AAB
```bash
flutter build apk --release --split-per-abi
# or for Play Store:
flutter build appbundle --release
```

After 1-3 you should be at **~40-60 MB**. If that's enough, stop here — you've avoided a pile of complexity.

---

## Your idea: pack .so via datamanage, `System.load` at runtime

**Yes, it works for every `.so` you control** — but with one big caveat.

### How it would work
1. At ship time: take e.g. `libonnxruntime.so` out of `jniLibs`, compress it into a `.ddp` chunk via datamanage, ship that chunk.
2. First launch: a custom `Application.attachBaseContext()` checks if the unpacked copy exists at `getNoBackupFilesDir()/native/libonnxruntime.so`. If not, decompress from `assets/` (or wherever the `.ddp` lives) into that path.
3. Before any code that needs the lib runs, call:
   ```kotlin
   System.load(File(noBackupDir, "native/libonnxruntime.so").absolutePath)
   ```
4. Subsequent `System.loadLibrary("onnxruntime")` calls inside ONNX Runtime's JNI bridge find it already loaded and become no-ops.

This pattern is used by big-bundle apps (e.g., apps that ship multiple Tensorflow models / WebRTC). It's well-trodden territory; the constraints are:

- **App-private exec-mountable storage only.** `/data/data/<pkg>/files/...` (or `getNoBackupFilesDir()`) is `noexec=false`, so `System.load` works. External storage (`/sdcard`) is `noexec` on Android 10+ — **don't put the `.so` there**.
- **Must run before the JNI that needs it.** For libs invoked from a Flutter plugin, your custom Application's `attachBaseContext` (NOT `onCreate`) is the right hook.
- **Set `extractNativeLibs="false"` in `AndroidManifest.xml`** if you're shipping packed libs that aren't in `lib/` — the manifest flag tells Android not to extract or look at the APK's lib dir for them.

### libflutter.so — the one you asked about

**Risky.** Flutter's own Java code does `System.loadLibrary("flutter")` very early — before your `attachBaseContext` returns in many embedding paths. To intercept, you'd need to:

1. Move `libflutter.so` out of `lib/arm64-v8a/` into your datamanage pack.
2. Override `FlutterApplication` (your `MainActivity` parent is the `FlutterActivity`, but the loader sits in `io.flutter.app.FlutterApplication.onCreate`).
3. In the override, decompress and `System.load("/absolute/path/libflutter.so")` **before** calling `super.onCreate()`.
4. Hope no future Flutter Embedding version changes the load timing.

I'd **not** do this. The savings (~14 MB on `libflutter.so` after step 1+2+3 above) aren't worth the upgrade footgun every time you bump the Flutter SDK.

### What I would pack via datamanage

The candidates that are *yours* (no framework involvement) and big enough to be worth the complexity:

| Lib | Release-ish size | Pack? |
|---|---|---|
| `libonnxruntime.so` | ~15 MB | ✅ best ROI |
| `librive_native.so` | ~3 MB | maybe |
| `libsherpa-onnx-c-api.so` | ~2 MB | maybe |
| everything else | < 2 MB | no — overhead exceeds savings |
| `libflutter.so` | ~14 MB | ❌ too risky |

If you ship ONNX models via datamanage anyway (which you do — `sherpa_2023/` is already on the user's external storage), packing `libonnxruntime.so` next to them is a natural fit: same code path that unpacks the models can unpack the .so. App-private storage for the .so, external for the models.

---

## My recommendation

1. Do steps 1-3 above first (~10 min). Measure the new APK size.
2. If you're > 80 MB and need to push lower, pack **only `libonnxruntime.so`** via datamanage, into `getNoBackupFilesDir()/native/`, load via `System.load` in `MainApplication.attachBaseContext` before the platform channels initialize.
3. Leave `libflutter.so` in `lib/` forever — the Flutter SDK can rearrange its loader behavior across versions, and trying to be clever about it costs more in upgrade pain than the 14 MB is worth.

Want me to draft the step-1-3 build.gradle changes + measure a release APK, or skip straight to the libonnxruntime.so pack-and-extract scaffold?
