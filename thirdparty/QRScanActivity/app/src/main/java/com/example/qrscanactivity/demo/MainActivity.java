package com.example.qrscanactivity.demo;

import android.content.Intent;
import android.os.Bundle;
import android.view.View;
import android.widget.TextView;

import androidx.activity.result.ActivityResultLauncher;
import androidx.activity.result.contract.ActivityResultContracts;
import androidx.appcompat.app.AppCompatActivity;

import com.example.qrscanactivity.QRScanActivity;

/**
 * A small demo screen that launches {@link QRScanActivity} and displays the
 * returned scan result. It shows exactly how a caller consumes the result.
 */
public class MainActivity extends AppCompatActivity {

    private TextView statusText;
    private TextView resultValue;

    private final ActivityResultLauncher<Intent> scanLauncher = registerForActivityResult(
            new ActivityResultContracts.StartActivityForResult(), result -> {
                Intent data = result.getData();
                if (result.getResultCode() == RESULT_OK && data != null) {
                    byte[] bytes = data.getByteArrayExtra(QRScanActivity.EXTRA_LICENSE_BYTES);
                    if (bytes != null) {
                        String path = data.getStringExtra(QRScanActivity.EXTRA_LICENSE_PATH);
                        statusText.setText(getString(R.string.result_file_license_heading,
                                bytes.length, path != null ? path : "?"));
                        resultValue.setText(hexPreview(bytes, 64));
                        resultValue.setVisibility(View.VISIBLE);
                        return;
                    }
                    String license = data.getStringExtra(QRScanActivity.EXTRA_LICENSE);
                    if (license != null) {
                        statusText.setText(R.string.result_license_heading);
                        resultValue.setText(license);
                        resultValue.setVisibility(View.VISIBLE);
                        return;
                    }
                    String text = data.getStringExtra(QRScanActivity.EXTRA_SCAN_RESULT);
                    String format = data.getStringExtra(QRScanActivity.EXTRA_SCAN_RESULT_FORMAT);
                    statusText.setText(getString(R.string.result_heading, format));
                    resultValue.setText(text);
                    resultValue.setVisibility(View.VISIBLE);
                } else {
                    String err = data != null
                            ? data.getStringExtra(QRScanActivity.EXTRA_ERROR_MESSAGE)
                            : null;
                    statusText.setText(err != null ? err
                            : getString(R.string.result_cancelled));
                    resultValue.setVisibility(View.GONE);
                }
            });

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);

        statusText = findViewById(R.id.status_text);
        resultValue = findViewById(R.id.result_value);

        findViewById(R.id.scan_button).setOnClickListener(v -> launchScanner());
        findViewById(R.id.test_license_button).setOnClickListener(v -> launchLicenseTest());
        findViewById(R.id.file_license_button).setOnClickListener(v -> launchFileLicenseTest());
    }

    private void launchScanner() {
        // Launched here within the same app via its class. A separate app would
        // instead target the exported action:
        //     Intent i = new Intent(QRScanActivity.ACTION_SCAN);
        //     i.setPackage("com.example.qrscanactivity");
        Intent intent = new Intent(this, QRScanActivity.class);
        intent.putExtra(QRScanActivity.EXTRA_PROMPT_MESSAGE, getString(R.string.scan_prompt));
        scanLauncher.launch(intent);
    }

    /** Launch QRScanActivity in test_license mode — no camera, returns assets/license.txt. */
    private void launchLicenseTest() {
        Intent intent = new Intent(this, QRScanActivity.class);
        intent.putExtra(QRScanActivity.EXTRA_MODE, QRScanActivity.MODE_TEST_LICENSE);
        scanLauncher.launch(intent);
    }

    /**
     * Launch QRScanActivity in file_license mode — no camera, reads the license
     * file at {@link R.string#demo_license_path} and returns it as a byte[].
     * Requires that the app has been granted storage access (All Files Access
     * on Android 11+; READ_EXTERNAL_STORAGE on older).
     */
    private void launchFileLicenseTest() {
        Intent intent = new Intent(this, QRScanActivity.class);
        intent.putExtra(QRScanActivity.EXTRA_MODE, QRScanActivity.MODE_FILE_LICENSE);
        intent.putExtra(QRScanActivity.EXTRA_LICENSE_PATH,
                getString(R.string.demo_license_path));
        scanLauncher.launch(intent);
    }

    private static String hexPreview(byte[] bytes, int maxBytes) {
        int n = Math.min(maxBytes, bytes.length);
        StringBuilder sb = new StringBuilder(n * 3);
        for (int i = 0; i < n; i++) {
            if (i > 0 && i % 16 == 0) sb.append('\n');
            else if (i > 0) sb.append(' ');
            sb.append(String.format("%02X", bytes[i] & 0xFF));
        }
        if (bytes.length > n) sb.append("  ...");
        return sb.toString();
    }
}
