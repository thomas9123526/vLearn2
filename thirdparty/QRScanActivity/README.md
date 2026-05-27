# QRScanActivity

A small Android app (Java) that provides a **reusable, custom-camera QR-code
scanner activity**. It does **not** use a pre-built scanner UI — the camera
screen, the highlighted scan window, the animations and the result handling are
all implemented here. Decoding is done with **ZXing, bundled offline** inside
the project.

## Features

- **Custom camera activity** (`QRScanActivity`) built on **CameraX** — no
  third-party scanner Activity is used.
- **Centered highlight area**: a dimmed scrim with a clear square scan window,
  framed by teal corner brackets.
- **Scanning animation**: a glowing scan line sweeps up and down the window.
- **"Recognised" animation**: on a successful decode the brackets turn green,
  a green flash fades out, and the device gives a short vibration.
- **Returns the result via `Intent`** so any other app/module can launch this
  activity and read the scanned value.
- **ZXing is fully offline** — the complete ZXing `core` library **source**
  (v3.5.3, Apache-2.0, 238 `.java` files) is vendored into
  `app/src/main/java/com/google/zxing/` and compiled together with the app. No
  ZXing artifact is fetched from the network.
- Java only. `minSdk 24`, `targetSdk 34`.

## Project layout

Two Gradle modules:

- **`:scanner`** (`com.android.library`) — the reusable scanner. Produces
  `scanner-release.aar` / `scanner-debug.aar`. Contains QRScanActivity, the
  custom overlay, the CameraX analyzer, and the vendored ZXing source.
- **`:app`** (`com.android.application`) — a thin demo APK that depends on
  `:scanner` and shows how a caller integrates it.

```
scanner/                              ← com.android.library — produces scanner.aar
 └─ src/main/
     ├─ AndroidManifest.xml           ← QRScanActivity + CAMERA/storage perms
     ├─ assets/license.txt            ← read by MODE_TEST_LICENSE
     ├─ java/
     │   ├─ com/google/zxing/         ← ZXing core SOURCE, vendored (Apache-2.0)
     │   └─ com/example/qrscanactivity/
     │       ├─ QRScanActivity.java   ← the reusable custom-camera activity
     │       ├─ ScannerOverlayView.java
     │       └─ QrCodeAnalyzer.java
     └─ res/                          ← qrscan_* prefixed resources + Scanner theme

app/                                  ← thin demo APK, depends on :scanner
 └─ src/main/
     ├─ AndroidManifest.xml           ← declares MainActivity only
     ├─ java/com/example/qrscanactivity/demo/
     │   └─ MainActivity.java         ← demo launcher
     └─ res/                          ← demo-only resources
```

Namespaces are intentionally split: the library is `com.example.qrscanactivity`
(so `QRScanActivity` keeps its existing FQN) and the demo app is
`com.example.qrscanactivity.demo` (so the two R classes don't collide). The
demo app's `applicationId` stays `com.example.qrscanactivity`, so the installed
package name and the exported `ACTION_SCAN` intent-filter are unchanged.

## Building

This project was created in Android Studio.

1. Open the `QRScanActivity` folder in **Android Studio**.
2. Let it sync — Android Studio creates `local.properties` (the SDK path) and
   downloads Gradle 8.7 automatically.
3. Run the **app** configuration on a device or emulator with a camera.

> **JDK note:** the Android Gradle Plugin requires a **JDK 17 or 21**. This
> machine's command-line Java is 25, which the toolchain does not support, so
> building with `./gradlew` from a terminal will fail. Build from Android
> Studio (it uses its own bundled JDK), or, in
> *Settings → Build, Execution, Deployment → Build Tools → Gradle*, set
> **Gradle JDK** to a bundled JDK 17/21.

## Consuming the AAR in another project

Bundle the scanner directly into a separate Android project:

1. Build the AAR:

   ```
   ./gradlew :scanner:assembleRelease
   ```

   Output: `scanner/build/outputs/aar/scanner-release.aar` (~575 KB).

2. Drop it into your consumer project at `<consumer>/app/libs/scanner.aar`.

3. In your consumer's `app/build.gradle`:

   ```groovy
   dependencies {
       implementation files('libs/scanner.aar')

       // The AAR was compiled against these dependencies. When consumed as a
       // plain file (no .pom is read), declare them yourself in the consumer:
       implementation 'androidx.appcompat:appcompat:1.7.0'
       implementation 'com.google.android.material:material:1.12.0'
       def camerax = "1.3.4"
       implementation "androidx.camera:camera-core:$camerax"
       implementation "androidx.camera:camera-camera2:$camerax"
       implementation "androidx.camera:camera-lifecycle:$camerax"
       implementation "androidx.camera:camera-view:$camerax"
   }
   ```

   (Publish the AAR to a Maven repo with its generated `.pom` and these
   transitive `api` deps resolve automatically — you can drop the manual block.)

4. Use a Material3 app theme in the consumer so the merged `Theme.QRScanActivity.Scanner`
   inflates correctly.

5. Launch from any consumer activity:

   ```java
   ActivityResultLauncher<Intent> scan = registerForActivityResult(
       new ActivityResultContracts.StartActivityForResult(),
       result -> { /* read SCAN_RESULT / LICENSE / LICENSE_BYTES — see below */ });

   scan.launch(new Intent(this, com.example.qrscanactivity.QRScanActivity.class));
   ```

6. The library manifest carries `CAMERA`, `VIBRATE`, `READ_EXTERNAL_STORAGE`
   and `MANAGE_EXTERNAL_STORAGE` into the merged consumer manifest. If your
   consumer doesn't need `MODE_FILE_LICENSE`, strip the sensitive storage perm:

   ```xml
   <uses-permission
       android:name="android.permission.MANAGE_EXTERNAL_STORAGE"
       tools:node="remove" />
   ```

7. ZXing `-keep` rules are bundled in the AAR's `consumer-rules.pro`, so R8
   shrinking in the consumer build won't strip the scanner's classes.

## Using QRScanActivity from another app/module

`QRScanActivity` is `exported`, so a separate application can launch it and get
the result back.

```java
// In the caller:
ActivityResultLauncher<Intent> scan = registerForActivityResult(
        new ActivityResultContracts.StartActivityForResult(), result -> {
    if (result.getResultCode() == RESULT_OK && result.getData() != null) {
        String text   = result.getData().getStringExtra("SCAN_RESULT");
        String format = result.getData().getStringExtra("SCAN_RESULT_FORMAT");
        // use the scanned value...
    }
});

Intent intent = new Intent("com.example.qrscanactivity.SCAN");
intent.setPackage("com.example.qrscanactivity");
// optional prompt shown above the scan window:
intent.putExtra("PROMPT_MESSAGE", "Scan the product code");
scan.launch(intent);
```

Within this same app, `MainActivity` shows the simpler in-app form
(`new Intent(this, QRScanActivity.class)`).

### Result contract

| Extra key            | When           | Meaning                              |
|----------------------|----------------|--------------------------------------|
| `SCAN_RESULT`        | `RESULT_OK`    | The decoded QR-code text             |
| `SCAN_RESULT_FORMAT` | `RESULT_OK`    | Barcode format name, e.g. `QR_CODE`  |
| `LICENSE`            | `RESULT_OK`    | Only in `test_license` mode — contents of `assets/license.txt` |
| `LICENSE_BYTES`      | `RESULT_OK`    | Only in `file_license` mode — `byte[]` contents of the file at `lic_path` |
| `ERROR_MESSAGE`      | `RESULT_CANCELED` | Reason any test mode (or the camera) failed |

`RESULT_CANCELED` with no extras means the user dismissed the scanner.

### Test mode (`test_license`)

Launch `QRScanActivity` with the extra `mode = "test_license"` to bypass the
camera entirely: the activity reads `app/src/main/assets/license.txt`, returns
its contents in the `LICENSE` extra, and finishes immediately. Useful for
integration smoke-tests from another app.

```java
Intent intent = new Intent("com.example.qrscanactivity.SCAN");
intent.setPackage("com.example.qrscanactivity");
intent.putExtra("mode", "test_license");
scan.launch(intent);   // -> RESULT_OK, data.getStringExtra("LICENSE") == "Test QRSCANACTIVITY"
```

The bundled demo screen has a **"Run test_license mode"** button that exercises
this path.

### Test mode (`file_license`)

Launch `QRScanActivity` with `mode = "file_license"` (and optionally
`lic_path = "<absolute path>"`) to read a file from disk and get its raw bytes
back. The camera is **not** started.

If `lic_path` is omitted or blank, the activity falls back to
`QRScanActivity.DEFAULT_LICENSE_PATH`
(`/storage/emulated/0/룡마/가상외국어회화/license/default`).

```java
Intent intent = new Intent("com.example.qrscanactivity.SCAN");
intent.setPackage("com.example.qrscanactivity");
intent.putExtra("mode", "file_license");
intent.putExtra("lic_path", "/sdcard/룡마/가상외국어회화/license/a1.key");
scan.launch(intent);
// onResult: RESULT_OK, data.getByteArrayExtra("LICENSE_BYTES")
```

**Storage permission caveat.** Reading arbitrary paths under `/sdcard/` requires:

- **API ≤ 32:** `READ_EXTERNAL_STORAGE`. QRScanActivity requests it at runtime
  the first time `file_license` mode is used.
- **API ≥ 30 (Android 11+):** `MANAGE_EXTERNAL_STORAGE` ("All Files Access").
  This cannot be granted via the normal runtime dialog. The user must enable it
  manually:
  *Settings → Apps → QR Scanner → Permissions → "Allow management of all files"*.
  Until that is done, `file_license` mode returns `RESULT_CANCELED` with
  `ERROR_MESSAGE` explaining the requirement.

**Size cap.** The file is returned as a single `byte[]` extra in an Intent.
Intent extras cross a Binder transaction with a practical ~1 MB total limit,
so this mode refuses files larger than **512 KiB** (and returns
`ERROR_MESSAGE`). For larger payloads, pass a `content://` URI or use a
`FileProvider` instead — `byte[]` extras are only safe for small blobs.

The demo screen has a **"Run file_license mode"** button that uses the path
`/sdcard/룡마/가상외국어회화/license/a1.key` (overridable via
`@string/demo_license_path`).

## Why the ZXing source is vendored

The requirement is for ZXing to work **offline**, with "all the material in the
project". Rather than a pre-built JAR, the complete official ZXing `core`
library **source** (release `zxing-3.5.3`, Apache License 2.0 — 238 `.java`
files spanning `qrcode`, `common`, `aztec`, `datamatrix`, `oned`, `pdf417`,
`maxicode`, `multi`, `client`) is vendored under:

```
app/src/main/java/com/google/zxing/
```

It is compiled from source together with the app — `app/build.gradle` has **no
ZXing dependency at all**, so resolving ZXing never touches a network
repository. (The AndroidX/CameraX libraries are still normal Gradle
dependencies and are fetched on first sync.)

To update ZXing later, replace the contents of `com/google/zxing/` with the
`core/src/main/java/com/google/zxing/` tree from a newer ZXing release.
