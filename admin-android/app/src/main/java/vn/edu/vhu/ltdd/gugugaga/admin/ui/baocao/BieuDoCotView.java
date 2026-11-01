package vn.edu.vhu.ltdd.gugugaga.admin.ui.baocao;

import android.content.Context;
import android.graphics.Canvas;
import android.graphics.Paint;
import android.graphics.RectF;
import android.text.TextPaint;
import android.text.TextUtils;
import android.util.AttributeSet;
import android.view.View;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.core.content.ContextCompat;

import com.google.android.material.color.MaterialColors;

import java.util.ArrayList;
import java.util.List;

import vn.edu.vhu.ltdd.gugugaga.admin.R;
import vn.edu.vhu.ltdd.gugugaga.admin.util.BieuDo;

/**
 * Biểu đồ cột ngang TỰ VẼ bằng Canvas (C.1 #7 cho phép "MPAndroidChart hoặc tự vẽ").
 * Mỗi dòng: nhãn bên trái, cột dài theo tỉ lệ với giá trị lớn nhất, số tiền rút gọn ở cuối cột.
 * Cột ngang dễ đọc hơn cột đứng khi tên vùng dài và màn hình điện thoại hẹp.
 * Phép tính tỉ lệ nằm ở util/BieuDo (Java thuần) để kiểm thử không cần máy ảo.
 */
public class BieuDoCotView extends View {
    private final TextPaint butNhan = new TextPaint(Paint.ANTI_ALIAS_FLAG);
    private final TextPaint butGiaTri = new TextPaint(Paint.ANTI_ALIAS_FLAG);
    private final Paint butCot = new Paint(Paint.ANTI_ALIAS_FLAG);
    private final Paint butNenCot = new Paint(Paint.ANTI_ALIAS_FLAG);
    private final RectF hcn = new RectF();

    private final float caoDong;
    private final float caoCot;
    private final float khoang;
    private final float boGoc;

    private List<String> nhan = new ArrayList<>();
    private long[] giaTri = new long[0];

    public BieuDoCotView(@NonNull Context context) {
        this(context, null);
    }

    public BieuDoCotView(@NonNull Context context, @Nullable AttributeSet attrs) {
        this(context, attrs, 0);
    }

    public BieuDoCotView(@NonNull Context context, @Nullable AttributeSet attrs, int defStyleAttr) {
        super(context, attrs, defStyleAttr);
        // Kích thước lấy từ dimens.xml (dp/sp), không viết cứng px (Lab A3).
        caoDong = getResources().getDimension(R.dimen.bieu_do_cao_dong);
        caoCot = getResources().getDimension(R.dimen.bieu_do_cao_cot);
        khoang = getResources().getDimension(R.dimen.khoang_sm);
        boGoc = getResources().getDimension(R.dimen.khoang_xs);
        float coChu = getResources().getDimension(R.dimen.chu_bieu_do);

        int mauChu = MaterialColors.getColor(this, com.google.android.material.R.attr.colorOnSurface);
        butNhan.setTextSize(coChu);
        butNhan.setColor(mauChu);
        butGiaTri.setTextSize(coChu);
        butGiaTri.setColor(mauChu);
        butGiaTri.setFakeBoldText(true);
        butCot.setColor(ContextCompat.getColor(context, R.color.xanh_ocop));
        butNenCot.setColor(ContextCompat.getColor(context, R.color.xam_nen));
    }

    /** Đổi dữ liệu thì đo lại chiều cao (số dòng có thể khác) và vẽ lại. */
    public void datDuLieu(List<String> nhanMoi, long[] giaTriMoi) {
        nhan = nhanMoi == null ? new ArrayList<>() : new ArrayList<>(nhanMoi);
        giaTri = giaTriMoi == null ? new long[0] : giaTriMoi.clone();
        requestLayout();
        invalidate();
    }

    @Override
    protected void onMeasure(int widthMeasureSpec, int heightMeasureSpec) {
        int rong = MeasureSpec.getSize(widthMeasureSpec);
        int cao = (int) Math.ceil(getPaddingTop() + getPaddingBottom() + soDong() * caoDong);
        setMeasuredDimension(rong, resolveSize(cao, heightMeasureSpec));
    }

    private int soDong() {
        return Math.min(nhan.size(), giaTri.length);
    }

    @Override
    protected void onDraw(@NonNull Canvas canvas) {
        super.onDraw(canvas);
        int n = soDong();
        if (n == 0) return;

        float trai = getPaddingStart();
        float phai = getWidth() - getPaddingEnd();
        float rongNhan = (phai - trai) * 0.32f;

        // Chừa chỗ cho số tiền dài nhất ở cuối cột.
        float rongGiaTri = 0;
        for (int i = 0; i < n; i++) {
            rongGiaTri = Math.max(rongGiaTri, butGiaTri.measureText(BieuDo.rutGon(giaTri[i])));
        }
        float batDauCot = trai + rongNhan + khoang;
        float rongCotToiDa = Math.max(0, phai - batDauCot - rongGiaTri - khoang);
        long lonNhat = BieuDo.lonNhat(giaTri);

        Paint.FontMetrics fm = butNhan.getFontMetrics();
        float lechChu = -(fm.ascent + fm.descent) / 2; // căn chữ giữa dòng theo chiều dọc

        for (int i = 0; i < n; i++) {
            float giua = getPaddingTop() + i * caoDong + caoDong / 2;

            // Nhãn: tên dài thì cắt và thêm "…" (giống ellipsize="end").
            CharSequence ten = TextUtils.ellipsize(nhan.get(i), butNhan, rongNhan, TextUtils.TruncateAt.END);
            canvas.drawText(ten, 0, ten.length(), trai, giua + lechChu, butNhan);

            // Nền mờ cả chiều dài để thấy rõ tỉ lệ, rồi cột màu theo tỉ lệ giá trị/giá trị lớn nhất.
            hcn.set(batDauCot, giua - caoCot / 2, batDauCot + rongCotToiDa, giua + caoCot / 2);
            canvas.drawRoundRect(hcn, boGoc, boGoc, butNenCot);
            float dai = rongCotToiDa * BieuDo.tiLe(giaTri[i], lonNhat);
            if (dai > 0) {
                hcn.set(batDauCot, giua - caoCot / 2, batDauCot + dai, giua + caoCot / 2);
                canvas.drawRoundRect(hcn, boGoc, boGoc, butCot);
            }

            canvas.drawText(BieuDo.rutGon(giaTri[i]), batDauCot + rongCotToiDa + khoang, giua + lechChu, butGiaTri);
        }
    }
}
