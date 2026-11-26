package vn.edu.vhu.ltdd.gugugaga.admin.ui.dangnhap;

import android.content.Context;
import android.graphics.Canvas;
import android.graphics.Paint;
import android.graphics.Path;
import android.graphics.RadialGradient;
import android.graphics.Shader;
import android.util.AttributeSet;
import android.view.View;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.core.content.ContextCompat;

import vn.edu.vhu.ltdd.gugugaga.admin.R;

/**
 * Nền đường đồng mức địa hình vùng nguyên liệu OCOP vẽ bằng Canvas,
 * tạo bản sắc độc bản cho màn hình đăng nhập đồng bộ với app Client.
 */
public class NenDiaHinhView extends View {
    private final Paint butNet = new Paint(Paint.ANTI_ALIAS_FLAG);
    private final Paint butCham = new Paint(Paint.ANTI_ALIAS_FLAG);
    private final Paint butAnhSang = new Paint(Paint.ANTI_ALIAS_FLAG);
    private final Path duong = new Path();
    private final int mauXanh;

    public NenDiaHinhView(@NonNull Context context) {
        this(context, null);
    }

    public NenDiaHinhView(@NonNull Context context, @Nullable AttributeSet attrs) {
        this(context, attrs, 0);
    }

    public NenDiaHinhView(@NonNull Context context, @Nullable AttributeSet attrs, int defStyleAttr) {
        super(context, attrs, defStyleAttr);
        mauXanh = ContextCompat.getColor(context, R.color.xanh_ocop);
        butNet.setStyle(Paint.Style.STROKE);
        butNet.setStrokeWidth(getResources().getDisplayMetrics().density * 1.2f);
        butNet.setColor(datAlpha(mauXanh, 24));
        butCham.setStyle(Paint.Style.FILL);
        butCham.setColor(datAlpha(mauXanh, 28));
    }

    private static int datAlpha(int mau, int alpha) {
        return (mau & 0x00FFFFFF) | (alpha << 24);
    }

    @Override
    protected void onSizeChanged(int w, int h, int oldw, int oldh) {
        super.onSizeChanged(w, h, oldw, oldh);
        if (w <= 0 || h <= 0) return;
        butAnhSang.setShader(new RadialGradient(
                w * 0.85f, h * 0.10f, w * 0.9f,
                datAlpha(mauXanh, 28), 0x00000000, Shader.TileMode.CLAMP));
    }

    @Override
    protected void onDraw(@NonNull Canvas canvas) {
        super.onDraw(canvas);
        float w = getWidth();
        float h = getHeight();
        float dp = getResources().getDisplayMetrics().density;

        canvas.drawRect(0, 0, w, h, butAnhSang);

        for (int i = 0; i < 6; i++) {
            duong.reset();
            float y0 = (32 + i * 34) * dp;
            duong.moveTo(-20 * dp, y0 + 24 * dp);
            duong.cubicTo(
                    w * 0.28f, y0 - (22 + i * 4) * dp,
                    w * 0.62f, y0 + (48 + i * 3) * dp,
                    w + 20 * dp, y0 - 8 * dp);
            canvas.drawPath(duong, butNet);
        }

        for (int row = 0; row < 4; row++) {
            for (int col = 0; col < 6; col++) {
                canvas.drawCircle(w - (24 + col * 18) * dp, (28 + row * 18) * dp, 1.5f * dp, butCham);
            }
        }
    }
}
