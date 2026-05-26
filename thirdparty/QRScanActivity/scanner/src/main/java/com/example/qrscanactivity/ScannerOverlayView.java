package com.example.qrscanactivity;

import android.animation.ValueAnimator;
import android.content.Context;
import android.graphics.Canvas;
import android.graphics.LinearGradient;
import android.graphics.Paint;
import android.graphics.Path;
import android.graphics.RectF;
import android.graphics.Shader;
import android.util.AttributeSet;
import android.view.View;
import android.view.animation.AccelerateDecelerateInterpolator;

import androidx.annotation.Nullable;

/**
 * The view drawn on top of the camera preview. It provides:
 * <ul>
 *   <li>a dimmed scrim with a clear, highlighted square "scan window" in the centre;</li>
 *   <li>animated corner brackets framing that window;</li>
 *   <li>a glowing scan line that sweeps up and down while scanning;</li>
 *   <li>a green "recognised" flash once a QR code is decoded.</li>
 * </ul>
 */
public class ScannerOverlayView extends View {

    /** Scan window side length, as a fraction of the smaller view dimension. */
    private static final float BOX_RATIO = 0.70f;
    /** Time for the scan line to travel from one edge of the window to the other. */
    private static final long SCAN_DURATION_MS = 2400L;
    private static final long SUCCESS_DURATION_MS = 700L;

    private final Paint scrimPaint = new Paint(Paint.ANTI_ALIAS_FLAG);
    private final Paint bracketPaint = new Paint(Paint.ANTI_ALIAS_FLAG);
    private final Paint linePaint = new Paint(Paint.ANTI_ALIAS_FLAG);
    private final Paint fillPaint = new Paint(Paint.ANTI_ALIAS_FLAG);

    private final RectF box = new RectF();
    private final Path cornerPath = new Path();

    private final int scrimColor = 0xB3000000;   // ~70% black
    private final int accentColor = 0xFF1DE9B6;  // teal — scanning
    private final int successColor = 0xFF00E676; // green — recognised

    private float density;
    private float cornerLength;

    private float scanFraction;     // 0..1 position of the scan line within the box
    private boolean success;        // true once a QR code has been recognised
    private float successFlash;     // 1..0 fade of the green success flash

    private ValueAnimator scanAnimator;
    private ValueAnimator successAnimator;

    public ScannerOverlayView(Context context) {
        this(context, null);
    }

    public ScannerOverlayView(Context context, @Nullable AttributeSet attrs) {
        this(context, attrs, 0);
    }

    public ScannerOverlayView(Context context, @Nullable AttributeSet attrs, int defStyleAttr) {
        super(context, attrs, defStyleAttr);
        density = getResources().getDisplayMetrics().density;
        cornerLength = 30 * density;

        scrimPaint.setColor(scrimColor);
        scrimPaint.setStyle(Paint.Style.FILL);

        bracketPaint.setColor(accentColor);
        bracketPaint.setStyle(Paint.Style.STROKE);
        bracketPaint.setStrokeWidth(5 * density);
        bracketPaint.setStrokeCap(Paint.Cap.ROUND);
        bracketPaint.setStrokeJoin(Paint.Join.ROUND);

        linePaint.setStyle(Paint.Style.FILL);
        fillPaint.setStyle(Paint.Style.FILL);
    }

    @Override
    protected void onSizeChanged(int w, int h, int oldw, int oldh) {
        super.onSizeChanged(w, h, oldw, oldh);
        float side = Math.min(w, h) * BOX_RATIO;
        float cx = w / 2f;
        float cy = h / 2f;
        box.set(cx - side / 2f, cy - side / 2f, cx + side / 2f, cy + side / 2f);
        buildCornerPath();
        startScanAnimation();
    }

    /** Pre-build the four L-shaped corner brackets. */
    private void buildCornerPath() {
        float len = Math.min(cornerLength, box.width() / 3f);
        float l = box.left, t = box.top, r = box.right, b = box.bottom;
        cornerPath.reset();
        // top-left
        cornerPath.moveTo(l, t + len);
        cornerPath.lineTo(l, t);
        cornerPath.lineTo(l + len, t);
        // top-right
        cornerPath.moveTo(r - len, t);
        cornerPath.lineTo(r, t);
        cornerPath.lineTo(r, t + len);
        // bottom-right
        cornerPath.moveTo(r, b - len);
        cornerPath.lineTo(r, b);
        cornerPath.lineTo(r - len, b);
        // bottom-left
        cornerPath.moveTo(l + len, b);
        cornerPath.lineTo(l, b);
        cornerPath.lineTo(l, b - len);
    }

    @Override
    protected void onDraw(Canvas canvas) {
        super.onDraw(canvas);
        if (box.isEmpty()) {
            return;
        }
        int w = getWidth();
        int h = getHeight();

        // 1. Dim everything except the centre window (four rects = a clear hole).
        canvas.drawRect(0, 0, w, box.top, scrimPaint);
        canvas.drawRect(0, box.bottom, w, h, scrimPaint);
        canvas.drawRect(0, box.top, box.left, box.bottom, scrimPaint);
        canvas.drawRect(box.right, box.top, w, box.bottom, scrimPaint);

        // 2. Animated content inside the window.
        if (success) {
            fillPaint.setColor(withAlpha(successColor, (int) (110 * successFlash)));
            canvas.drawRect(box, fillPaint);
        } else {
            drawScanLine(canvas);
        }

        // 3. Corner brackets — teal while scanning, green once recognised.
        bracketPaint.setColor(success ? successColor : accentColor);
        canvas.drawPath(cornerPath, bracketPaint);
    }

    /** Draw the glowing horizontal scan line at its current position. */
    private void drawScanLine(Canvas canvas) {
        float lineY = box.top + box.height() * scanFraction;
        float glow = 22 * density;
        int transparentAccent = accentColor & 0x00FFFFFF;

        canvas.save();
        canvas.clipRect(box);

        // Soft vertical glow centred on the line.
        linePaint.setShader(new LinearGradient(
                0, lineY - glow, 0, lineY + glow,
                new int[]{transparentAccent, accentColor, transparentAccent},
                new float[]{0f, 0.5f, 1f}, Shader.TileMode.CLAMP));
        canvas.drawRect(box.left, lineY - glow, box.right, lineY + glow, linePaint);

        // Crisp bright core line.
        linePaint.setShader(null);
        linePaint.setColor(accentColor);
        canvas.drawRect(box.left, lineY - 1.4f * density,
                box.right, lineY + 1.4f * density, linePaint);

        canvas.restore();
    }

    private void startScanAnimation() {
        if (scanAnimator != null) {
            scanAnimator.cancel();
        }
        scanAnimator = ValueAnimator.ofFloat(0f, 1f);
        scanAnimator.setDuration(SCAN_DURATION_MS);
        scanAnimator.setRepeatCount(ValueAnimator.INFINITE);
        scanAnimator.setRepeatMode(ValueAnimator.REVERSE);
        scanAnimator.setInterpolator(new AccelerateDecelerateInterpolator());
        scanAnimator.addUpdateListener(a -> {
            scanFraction = (float) a.getAnimatedValue();
            invalidate();
        });
        scanAnimator.start();
    }

    /**
     * Switch the overlay into the "QR code recognised" state: the scan line
     * stops, the brackets turn green and a green flash fades out.
     */
    public void showSuccess() {
        if (success) {
            return;
        }
        success = true;
        if (scanAnimator != null) {
            scanAnimator.cancel();
        }
        successAnimator = ValueAnimator.ofFloat(1f, 0f);
        successAnimator.setDuration(SUCCESS_DURATION_MS);
        successAnimator.addUpdateListener(a -> {
            successFlash = (float) a.getAnimatedValue();
            invalidate();
        });
        successAnimator.start();
        invalidate();
    }

    @Override
    protected void onDetachedFromWindow() {
        super.onDetachedFromWindow();
        if (scanAnimator != null) {
            scanAnimator.cancel();
        }
        if (successAnimator != null) {
            successAnimator.cancel();
        }
    }

    private static int withAlpha(int color, int alpha) {
        int a = Math.max(0, Math.min(255, alpha));
        return (a << 24) | (color & 0x00FFFFFF);
    }
}
