package com.example.qrscanactivity;

import android.Manifest;
import android.content.Intent;
import android.content.pm.PackageManager;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.os.Build;
import android.os.Bundle;
import android.os.Environment;
import android.os.Handler;
import android.os.Looper;
import android.os.VibrationEffect;
import android.os.Vibrator;
import android.util.Size;
import android.view.View;
import android.view.WindowManager;
import android.widget.ImageButton;
import android.widget.TextView;
import android.widget.Toast;

import androidx.activity.result.ActivityResultLauncher;
import androidx.activity.result.contract.ActivityResultContracts;
import androidx.annotation.NonNull;
import androidx.appcompat.app.AppCompatActivity;
import androidx.camera.core.Camera;
import androidx.camera.core.CameraSelector;
import androidx.camera.core.ImageAnalysis;
import androidx.camera.core.Preview;
import androidx.camera.core.resolutionselector.ResolutionSelector;
import androidx.camera.core.resolutionselector.ResolutionStrategy;
import androidx.camera.lifecycle.ProcessCameraProvider;
import androidx.camera.view.PreviewView;
import androidx.core.content.ContextCompat;

import com.google.common.util.concurrent.ListenableFuture;
import com.google.zxing.BarcodeFormat;
import com.google.zxing.BinaryBitmap;
import com.google.zxing.DecodeHintType;
import com.google.zxing.MultiFormatReader;
import com.google.zxing.NotFoundException;
import com.google.zxing.RGBLuminanceSource;
import com.google.zxing.Result;
import com.google.zxing.common.HybridBinarizer;

import java.io.BufferedReader;
import java.io.ByteArrayOutputStream;
import java.io.File;
import java.io.FileInputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.nio.charset.StandardCharsets;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Comparator;
import java.util.EnumMap;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

/**
 * A self-contained, reusable QR-code scanner built on a <b>custom camera</b>
 * (CameraX) and the bundled offline ZXing library.
 *
 * <h3>Using it from another app</h3>
 * This activity is exported. Another application can launch it and receive the
 * scan result back through {@code onActivityResult} /
 * {@code registerForActivityResult}:
 *
 * <pre>{@code
 * Intent intent = new Intent("com.example.qrscanactivity.SCAN");
 * intent.setPackage("com.example.qrscanactivity");
 * // optional: intent.putExtra(QRScanActivity.EXTRA_PROMPT_MESSAGE, "Scan a ticket");
 * startActivityForResult(intent, REQUEST_SCAN);
 * }</pre>
 *
 * On success the result {@link Intent} carries:
 * <ul>
 *   <li>{@link #EXTRA_SCAN_RESULT} — the decoded text</li>
 *   <li>{@link #EXTRA_SCAN_RESULT_FORMAT} — the barcode format, e.g. {@code "QR_CODE"}</li>
 * </ul>
 */
public class QRScanActivity extends AppCompatActivity {

    /** Intent action other apps can use to launch this scanner. */
    public static final String ACTION_SCAN = "com.example.qrscanactivity.SCAN";

    /** Optional input extra (String): a prompt shown above the scan window. */
    public static final String EXTRA_PROMPT_MESSAGE = "PROMPT_MESSAGE";

    /** Output extra (String) on RESULT_OK: the decoded QR-code text. */
    public static final String EXTRA_SCAN_RESULT = "SCAN_RESULT";

    /** Output extra (String) on RESULT_OK: the barcode format name. */
    public static final String EXTRA_SCAN_RESULT_FORMAT = "SCAN_RESULT_FORMAT";

    /** Output extra (String) on RESULT_CANCELED: why scanning could not start. */
    public static final String EXTRA_ERROR_MESSAGE = "ERROR_MESSAGE";

    /**
     * Input extra (String): activity mode. When set to {@link #MODE_TEST_LICENSE}
     * the camera is not started; the activity reads <code>assets/license.txt</code>,
     * returns its contents in {@link #EXTRA_LICENSE} and finishes immediately.
     */
    public static final String EXTRA_MODE = "mode";

    /** {@link #EXTRA_MODE} value: bypass scanning and return the bundled license. */
    public static final String MODE_TEST_LICENSE = "test_license";

    /**
     * {@link #EXTRA_MODE} value: bypass scanning, read the file at
     * {@link #EXTRA_LICENSE_PATH}, return its bytes in
     * {@link #EXTRA_LICENSE_BYTES}, and finish.
     */
    public static final String MODE_FILE_LICENSE = "file_license";

    /**
     * Input extra (String): absolute directory path containing one or
     * more `.png` files that hold QR codes. When this extra is present
     * (and non-empty) the activity skips the camera entirely, decodes
     * every PNG in that directory, and returns the decoded text in
     * {@link #EXTRA_SCAN_RESULTS} (and the first one in
     * {@link #EXTRA_SCAN_RESULT} for back-compat). Requires the same
     * MANAGE_EXTERNAL_STORAGE / READ_EXTERNAL_STORAGE access as
     * {@link #MODE_FILE_LICENSE}.
     */
    public static final String EXTRA_QR_PNG = "EXTRA_QR_PNG";

    /**
     * Output extra (String[]) on RESULT_OK in PNG-directory mode:
     * every QR-code text decoded from the scanned `.png` files, in
     * newest-file-first order.
     */
    public static final String EXTRA_SCAN_RESULTS = "SCAN_RESULTS";

    /** Output extra (String) on RESULT_OK in {@link #MODE_TEST_LICENSE} mode. */
    public static final String EXTRA_LICENSE = "LICENSE";

    /** Input extra (String) — absolute path of the license file to load. */
    public static final String EXTRA_LICENSE_PATH = "lic_path";

    /** Output extra (byte[]) on RESULT_OK in {@link #MODE_FILE_LICENSE} mode. */
    public static final String EXTRA_LICENSE_BYTES = "LICENSE_BYTES";

    /** Asset filename returned for {@link #MODE_TEST_LICENSE}. */
    private static final String LICENSE_ASSET = "license.txt";

    /**
     * Default path used for {@link #MODE_FILE_LICENSE} when the caller does not
     * supply {@link #EXTRA_LICENSE_PATH} (or supplies an empty string).
     */
    public static final String DEFAULT_LICENSE_PATH =
            "/storage/emulated/0/룡마/가상외국어회화/license/default";

    /**
     * Hard cap on the file size returnable via {@link #EXTRA_LICENSE_BYTES}.
     * Intent extras cross a Binder transaction with a practical ~1 MB total
     * limit; we stay well below it to avoid TransactionTooLargeException.
     */
    private static final long MAX_LICENSE_FILE_BYTES = 512L * 1024L;

    /** Delay before returning, so the success animation has time to play. */
    private static final long RESULT_DELAY_MS = 850L;

    private PreviewView previewView;
    private ScannerOverlayView overlayView;
    private TextView resultText;
    private ImageButton torchButton;

    private ExecutorService cameraExecutor;
    private QrCodeAnalyzer analyzer;
    private Camera camera;
    private boolean torchOn;

    /** Guards against handling more than one decoded result. */
    private boolean handled;

    private final ActivityResultLauncher<String> permissionLauncher =
            registerForActivityResult(new ActivityResultContracts.RequestPermission(), granted -> {
                if (granted) {
                    startCamera();
                } else {
                    finishWithError(getString(R.string.qrscan_error_camera_permission));
                }
            });

    /**
     * Set by {@link #handleQrPngMode()} so the storage-permission
     * callback knows whether the caller is in file-license mode or
     * qr-png-directory mode. Without this flag the existing legacy
     * launcher would always call {@link #readLicenseFileAndFinish()}.
     */
    private boolean pendingQrPngScan;

    private final ActivityResultLauncher<String> storagePermissionLauncher =
            registerForActivityResult(new ActivityResultContracts.RequestPermission(), granted -> {
                if (granted) {
                    if (pendingQrPngScan) {
                        pendingQrPngScan = false;
                        scanQrPngsAndFinish();
                    } else {
                        readLicenseFileAndFinish();
                    }
                } else {
                    returnError("Storage permission denied");
                }
            });

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        // Test hooks: caller can bypass the camera entirely via EXTRA_MODE.
        String mode = getIntent().getStringExtra(EXTRA_MODE);
        if (MODE_TEST_LICENSE.equals(mode)) {
            finishWithLicense();
            return;
        }
        if (MODE_FILE_LICENSE.equals(mode)) {
            handleFileLicenseMode();
            return;
        }

        // PNG-directory scan: triggered by presence of EXTRA_QR_PNG.
        // No mode token needed -- the extra alone disambiguates from
        // the camera flow.
        String qrPngDir = getIntent().getStringExtra(EXTRA_QR_PNG);
        if (qrPngDir != null && !qrPngDir.trim().isEmpty()) {
            handleQrPngMode();
            return;
        }

        getWindow().addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON);
        setContentView(R.layout.qrscan_activity);

        previewView = findViewById(R.id.preview_view);
        overlayView = findViewById(R.id.overlay_view);
        resultText = findViewById(R.id.result_text);
        torchButton = findViewById(R.id.torch_button);
        TextView promptText = findViewById(R.id.prompt_text);
        ImageButton closeButton = findViewById(R.id.close_button);

        // Let the caller override the on-screen prompt.
        String prompt = getIntent().getStringExtra(EXTRA_PROMPT_MESSAGE);
        if (prompt != null && !prompt.trim().isEmpty()) {
            promptText.setText(prompt);
        }

        closeButton.setOnClickListener(v -> cancelScan());
        torchButton.setOnClickListener(v -> toggleTorch());

        cameraExecutor = Executors.newSingleThreadExecutor();

        if (ContextCompat.checkSelfPermission(this, Manifest.permission.CAMERA)
                == PackageManager.PERMISSION_GRANTED) {
            startCamera();
        } else {
            permissionLauncher.launch(Manifest.permission.CAMERA);
        }
    }

    /** Asynchronously obtain the camera provider, then bind the use cases. */
    private void startCamera() {
        final ListenableFuture<ProcessCameraProvider> future =
                ProcessCameraProvider.getInstance(this);
        future.addListener(() -> {
            try {
                bindUseCases(future.get());
            } catch (Exception e) {
                finishWithError(getString(R.string.qrscan_error_camera_start));
            }
        }, ContextCompat.getMainExecutor(this));
    }

    /** Wire up the preview + frame-analysis use cases to this activity's lifecycle. */
    private void bindUseCases(@NonNull ProcessCameraProvider cameraProvider) {
        Preview preview = new Preview.Builder().build();
        preview.setSurfaceProvider(previewView.getSurfaceProvider());

        // ~720p analysis frames: a good balance of decode range vs. speed.
        ResolutionSelector resolutionSelector = new ResolutionSelector.Builder()
                .setResolutionStrategy(new ResolutionStrategy(new Size(1280, 720),
                        ResolutionStrategy.FALLBACK_RULE_CLOSEST_HIGHER_THEN_LOWER))
                .build();

        ImageAnalysis imageAnalysis = new ImageAnalysis.Builder()
                .setResolutionSelector(resolutionSelector)
                .setBackpressureStrategy(ImageAnalysis.STRATEGY_KEEP_ONLY_LATEST)
                .build();

        analyzer = new QrCodeAnalyzer(result -> runOnUiThread(() -> onQrDecoded(result)));
        imageAnalysis.setAnalyzer(cameraExecutor, analyzer);

        try {
            cameraProvider.unbindAll();
            camera = cameraProvider.bindToLifecycle(this, CameraSelector.DEFAULT_BACK_CAMERA,
                    preview, imageAnalysis);
            torchButton.setVisibility(
                    camera.getCameraInfo().hasFlashUnit() ? View.VISIBLE : View.GONE);
        } catch (Exception e) {
            finishWithError(getString(R.string.qrscan_error_camera_bind));
        }
    }

    /** Called on the UI thread once a QR code has been decoded. */
    private void onQrDecoded(@NonNull Result result) {
        if (handled) {
            return;
        }
        handled = true;
        if (analyzer != null) {
            analyzer.stop();
        }

        // Play the "recognised" animation and give haptic feedback.
        overlayView.showSuccess();
        resultText.setText(result.getText());
        resultText.setVisibility(View.VISIBLE);
        vibrate();

        final String text = result.getText();
        final String format = result.getBarcodeFormat() != null
                ? result.getBarcodeFormat().name() : "QR_CODE";

        new Handler(Looper.getMainLooper()).postDelayed(() -> {
            Intent data = new Intent();
            data.putExtra(EXTRA_SCAN_RESULT, text);
            data.putExtra(EXTRA_SCAN_RESULT_FORMAT, format);
            setResult(RESULT_OK, data);
            finish();
        }, RESULT_DELAY_MS);
    }

    private void toggleTorch() {
        if (camera == null || !camera.getCameraInfo().hasFlashUnit()) {
            return;
        }
        torchOn = !torchOn;
        camera.getCameraControl().enableTorch(torchOn);
        torchButton.setImageResource(torchOn ? R.drawable.qrscan_ic_torch_on : R.drawable.qrscan_ic_torch_off);
        torchButton.setSelected(torchOn);
    }

    private void vibrate() {
        Vibrator vibrator = (Vibrator) getSystemService(VIBRATOR_SERVICE);
        if (vibrator == null || !vibrator.hasVibrator()) {
            return;
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            vibrator.vibrate(VibrationEffect.createOneShot(140, VibrationEffect.DEFAULT_AMPLITUDE));
        } else {
            vibrator.vibrate(140);
        }
    }

    /** User dismissed the scanner — return RESULT_CANCELED. */
    private void cancelScan() {
        setResult(RESULT_CANCELED);
        finish();
    }

    /** Camera could not be started — report the reason back to the caller. */
    private void finishWithError(@NonNull String message) {
        Toast.makeText(this, message, Toast.LENGTH_LONG).show();
        Intent data = new Intent();
        data.putExtra(EXTRA_ERROR_MESSAGE, message);
        setResult(RESULT_CANCELED, data);
        finish();
    }

    @Override
    protected void onDestroy() {
        if (analyzer != null) {
            analyzer.stop();
        }
        if (cameraExecutor != null) {
            cameraExecutor.shutdown();
        }
        super.onDestroy();
    }

    /** Read {@value #LICENSE_ASSET} from the APK assets and finish RESULT_OK. */
    private void finishWithLicense() {
        String license = readAsset(LICENSE_ASSET);
        Intent data = new Intent();
        if (license != null) {
            data.putExtra(EXTRA_LICENSE, license);
            setResult(RESULT_OK, data);
        } else {
            data.putExtra(EXTRA_ERROR_MESSAGE,
                    "Could not read asset: " + LICENSE_ASSET);
            setResult(RESULT_CANCELED, data);
        }
        finish();
    }

    private String readAsset(@NonNull String name) {
        try (InputStream is = getAssets().open(name);
             BufferedReader r = new BufferedReader(
                     new InputStreamReader(is, StandardCharsets.UTF_8))) {
            StringBuilder sb = new StringBuilder();
            char[] buf = new char[1024];
            int n;
            while ((n = r.read(buf)) != -1) {
                sb.append(buf, 0, n);
            }
            return sb.toString();
        } catch (IOException e) {
            return null;
        }
    }

    // ===== MODE_FILE_LICENSE =================================================

    /** Check storage permissions, then read the license file at the resolved path. */
    private void handleFileLicenseMode() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            // Scoped storage on API 30+: only MANAGE_EXTERNAL_STORAGE lets us
            // read arbitrary paths under /sdcard. The user must grant it via
            // system Settings; there is no runtime permission dialog for this.
            if (!Environment.isExternalStorageManager()) {
                returnError("Grant 'All files access' to this app in system "
                        + "Settings (Apps -> QR Scanner -> Permissions), then retry.");
                return;
            }
            readLicenseFileAndFinish();
        } else {
            if (ContextCompat.checkSelfPermission(this,
                    Manifest.permission.READ_EXTERNAL_STORAGE)
                    == PackageManager.PERMISSION_GRANTED) {
                readLicenseFileAndFinish();
            } else {
                storagePermissionLauncher.launch(Manifest.permission.READ_EXTERNAL_STORAGE);
            }
        }
    }

    /**
     * Return the caller-supplied {@link #EXTRA_LICENSE_PATH}, or
     * {@link #DEFAULT_LICENSE_PATH} when the extra is missing or blank.
     */
    @NonNull
    private String resolveLicensePath() {
        String path = getIntent().getStringExtra(EXTRA_LICENSE_PATH);
        if (path == null || path.trim().isEmpty()) {
            return DEFAULT_LICENSE_PATH;
        }
        return path;
    }

    /** Read the resolved license path and finish with byte[] in EXTRA_LICENSE_BYTES. */
    private void readLicenseFileAndFinish() {
        String path = resolveLicensePath();

        File file = new File(path);
        if (!file.exists())  { returnError("File does not exist: " + path); return; }
        if (!file.isFile())  { returnError("Not a regular file: " + path); return; }
        if (!file.canRead()) { returnError("File is not readable: " + path); return; }
        if (file.length() > MAX_LICENSE_FILE_BYTES) {
            returnError("File too large to return via Intent ("
                    + file.length() + " bytes, max " + MAX_LICENSE_FILE_BYTES + ")");
            return;
        }
        try {
            byte[] bytes = readAllBytes(file);
            Intent data = new Intent();
            data.putExtra(EXTRA_LICENSE_BYTES, bytes);
            data.putExtra(EXTRA_LICENSE_PATH, path);
            setResult(RESULT_OK, data);
            finish();
        } catch (IOException e) {
            returnError("Failed to read " + path + ": " + e.getMessage());
        } catch (SecurityException e) {
            returnError("Permission denied reading " + path + ": " + e.getMessage());
        }
    }

    private static byte[] readAllBytes(@NonNull File file) throws IOException {
        try (InputStream in = new FileInputStream(file);
             ByteArrayOutputStream out = new ByteArrayOutputStream(
                     (int) Math.max(64, file.length()))) {
            byte[] buf = new byte[8192];
            int n;
            while ((n = in.read(buf)) != -1) {
                out.write(buf, 0, n);
            }
            return out.toByteArray();
        }
    }

    /** Error return used by no-UI modes (no Toast, the caller surfaces the message). */
    private void returnError(@NonNull String message) {
        Intent data = new Intent();
        data.putExtra(EXTRA_ERROR_MESSAGE, message);
        setResult(RESULT_CANCELED, data);
        finish();
    }

    // ===== PNG-directory QR scanning =========================================

    /**
     * Gate the PNG-directory scan behind the same storage-permission
     * flow as MODE_FILE_LICENSE: MANAGE_EXTERNAL_STORAGE on API 30+,
     * runtime READ_EXTERNAL_STORAGE on older OSes.
     */
    private void handleQrPngMode() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            if (!Environment.isExternalStorageManager()) {
                returnError("Grant 'All files access' to this app in system "
                        + "Settings (Apps -> QR Scanner -> Permissions), then retry.");
                return;
            }
            scanQrPngsAndFinish();
        } else {
            if (ContextCompat.checkSelfPermission(this,
                    Manifest.permission.READ_EXTERNAL_STORAGE)
                    == PackageManager.PERMISSION_GRANTED) {
                scanQrPngsAndFinish();
            } else {
                pendingQrPngScan = true;
                storagePermissionLauncher.launch(Manifest.permission.READ_EXTERNAL_STORAGE);
            }
        }
    }

    /**
     * Walk the caller-supplied directory, decode every .png file as a
     * QR code, return all successful decodes via EXTRA_SCAN_RESULTS
     * (newest file first), and finish RESULT_OK. If nothing decodes,
     * finish RESULT_CANCELED with EXTRA_ERROR_MESSAGE.
     */
    private void scanQrPngsAndFinish() {
        String dirPath = getIntent().getStringExtra(EXTRA_QR_PNG);
        if (dirPath == null || dirPath.trim().isEmpty()) {
            returnError("EXTRA_QR_PNG directory path is empty.");
            return;
        }
        File dir = new File(dirPath);
        if (!dir.exists())      { returnError("Directory does not exist: " + dirPath); return; }
        if (!dir.isDirectory()) { returnError("Not a directory: " + dirPath); return; }

        File[] pngsRaw;
        try {
            pngsRaw = dir.listFiles((f) -> f.isFile()
                    && f.getName().toLowerCase().endsWith(".png"));
        } catch (SecurityException e) {
            returnError("Permission denied listing " + dirPath + ": " + e.getMessage());
            return;
        }
        if (pngsRaw == null || pngsRaw.length == 0) {
            returnError("No .png files found in " + dirPath);
            return;
        }

        // Newest-first so the caller can verify the most recent license
        // QR before retrying older ones.
        File[] pngs = pngsRaw.clone();
        Arrays.sort(pngs, new Comparator<File>() {
            @Override public int compare(File a, File b) {
                return Long.compare(b.lastModified(), a.lastModified());
            }
        });

        List<String> decoded = new ArrayList<>();
        List<String> failures = new ArrayList<>();
        for (File png : pngs) {
            String text = decodeQrPngFile(png);
            if (text != null) {
                decoded.add(text);
            } else {
                failures.add(png.getName());
            }
        }
        if (decoded.isEmpty()) {
            returnError("Found " + pngs.length + " PNG file(s) but none "
                    + "contained a decodable QR code.");
            return;
        }

        Intent data = new Intent();
        data.putExtra(EXTRA_SCAN_RESULT, decoded.get(0));
        data.putExtra(EXTRA_SCAN_RESULT_FORMAT, "QR_CODE");
        data.putExtra(EXTRA_SCAN_RESULTS,
                decoded.toArray(new String[0]));
        setResult(RESULT_OK, data);
        finish();
    }

    /**
     * Decode a single PNG as a QR code. Returns the decoded text on
     * success, or null if the file isn't a valid image / contains no
     * QR / is unreadable. ZXing's HybridBinarizer + RGBLuminanceSource
     * is the standard "decode a still image" recipe.
     */
    private static String decodeQrPngFile(@NonNull File file) {
        Bitmap bitmap;
        try {
            BitmapFactory.Options opts = new BitmapFactory.Options();
            opts.inPreferredConfig = Bitmap.Config.ARGB_8888;
            bitmap = BitmapFactory.decodeFile(file.getAbsolutePath(), opts);
        } catch (Exception e) {
            return null;
        }
        if (bitmap == null) {
            return null;
        }
        try {
            int width = bitmap.getWidth();
            int height = bitmap.getHeight();
            int[] pixels = new int[width * height];
            bitmap.getPixels(pixels, 0, width, 0, 0, width, height);

            RGBLuminanceSource source = new RGBLuminanceSource(width, height, pixels);
            BinaryBitmap binary = new BinaryBitmap(new HybridBinarizer(source));

            Map<DecodeHintType, Object> hints = new EnumMap<>(DecodeHintType.class);
            hints.put(DecodeHintType.POSSIBLE_FORMATS,
                    Arrays.asList(BarcodeFormat.QR_CODE));
            // TRY_HARDER trades CPU for a higher decode rate on rough
            // or low-contrast images. The set is tiny so it's cheap.
            hints.put(DecodeHintType.TRY_HARDER, Boolean.TRUE);

            try {
                Result r = new MultiFormatReader().decode(binary, hints);
                return r.getText();
            } catch (NotFoundException nf) {
                return null;
            }
        } finally {
            bitmap.recycle();
        }
    }
}
