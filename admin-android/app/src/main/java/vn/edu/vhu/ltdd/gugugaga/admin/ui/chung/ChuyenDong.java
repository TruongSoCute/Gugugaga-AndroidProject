package vn.edu.vhu.ltdd.gugugaga.admin.ui.chung;

import android.animation.ObjectAnimator;
import android.animation.ValueAnimator;
import android.annotation.SuppressLint;
import android.view.HapticFeedbackConstants;
import android.view.MotionEvent;
import android.view.View;
import android.view.animation.DecelerateInterpolator;
import android.view.animation.OvershootInterpolator;
import android.widget.TextView;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.recyclerview.widget.RecyclerView;

import com.google.android.material.floatingactionbutton.ExtendedFloatingActionButton;

import vn.edu.vhu.ltdd.gugugaga.admin.util.DinhDang;

/**
 * Bộ tiện ích chuyển động chuẩn Material 3 Expressive từ lớn đến nhỏ cho app Admin:
 * - Nhấn nén lò xo (micro press-scale) trên thẻ và nút.
 * - Nảy nhẹ kèm rung xúc giác khi chọn chip/tab.
 * - Rung ngang khi báo lỗi nhập liệu.
 * - Đếm số doanh thu KPI mượt kiểu Stripe Dashboard.
 * - Tự thu gọn/mở rộng ExtendedFAB khi cuộn danh sách.
 */
public final class ChuyenDong {
    private ChuyenDong() { }

    /** Gắn hiệu ứng nén nhẹ 0.975x khi chạm và bật lò xo khi thả, không chặn OnClickListener. */
    @SuppressLint("ClickableViewAccessibility")
    public static void ganNhanNhe(@Nullable View v) {
        if (v == null) return;
        v.setOnTouchListener((view, event) -> {
            int action = event.getActionMasked();
            if (action == MotionEvent.ACTION_DOWN) {
                view.animate().cancel();
                view.animate()
                        .scaleX(0.975f)
                        .scaleY(0.975f)
                        .setDuration(90)
                        .setInterpolator(new DecelerateInterpolator())
                        .start();
            } else if (action == MotionEvent.ACTION_UP || action == MotionEvent.ACTION_CANCEL) {
                view.animate().cancel();
                view.animate()
                        .scaleX(1f)
                        .scaleY(1f)
                        .setDuration(180)
                        .setInterpolator(new OvershootInterpolator(1.3f))
                        .start();
            }
            return false;
        });
    }

    /** Nảy nhẹ + rung xúc giác nhẹ khi chuyển chip lọc hoặc tab điều hướng. */
    public static void nhayNhe(@Nullable View v) {
        if (v == null) return;
        v.performHapticFeedback(HapticFeedbackConstants.CLOCK_TICK);
        v.animate().cancel();
        v.animate()
                .scaleX(0.95f)
                .scaleY(0.95f)
                .setDuration(80)
                .withEndAction(() -> v.animate()
                        .scaleX(1f)
                        .scaleY(1f)
                        .setDuration(160)
                        .setInterpolator(new OvershootInterpolator(1.5f))
                        .start())
                .start();
    }

    /** Rung ngang ngắn báo lỗi form (đăng nhập / nhập liệu sai). */
    public static void rungLoi(@Nullable View v) {
        if (v == null) return;
        v.performHapticFeedback(HapticFeedbackConstants.LONG_PRESS);
        ObjectAnimator.ofFloat(v, View.TRANSLATION_X, 0f, -14f, 14f, -10f, 10f, -4f, 4f, 0f)
                .setDuration(320)
                .start();
    }

    /** Hiện mượt một khung nội dung từ trạng thái ẩn (tránh nhấp nháy cứng). */
    public static void hienMuot(@Nullable View v) {
        if (v == null) return;
        if (v.getVisibility() != View.VISIBLE) {
            v.setAlpha(0f);
            v.setVisibility(View.VISIBLE);
            v.animate().cancel();
            v.animate()
                    .alpha(1f)
                    .setDuration(200)
                    .setInterpolator(new DecelerateInterpolator())
                    .start();
        }
    }

    /** Chạy hiệu ứng đếm tăng dần cho số tiền KPI doanh số (kiểu Stripe Dashboard). */
    public static ValueAnimator chaySoTien(@NonNull TextView tv, long giaTriCuoi) {
        if (giaTriCuoi <= 0) {
            tv.setText(DinhDang.tien(giaTriCuoi));
            return null;
        }
        ValueAnimator anim = ValueAnimator.ofFloat(0f, 1f);
        anim.setDuration(540);
        anim.setInterpolator(new DecelerateInterpolator(2f));
        anim.addUpdateListener(a -> {
            float t = (float) a.getAnimatedValue();
            long hienTai = Math.round(giaTriCuoi * t);
            tv.setText(DinhDang.tien(hienTai));
        });
        anim.start();
        return anim;
    }

    /** Chạy lại hiệu ứng đổ tầng cho danh sách khi tải xong hoặc đổi bộ lọc. */
    public static void chayHienDanhSach(@Nullable RecyclerView rv) {
        if (rv == null || rv.getLayoutAnimation() == null) return;
        rv.scheduleLayoutAnimation();
    }

    /** Tự thu gọn nút ExtendedFAB khi cuộn xuống và mở lại khi cuộn lên (Material 3). */
    public static void ganThuGonFab(@Nullable RecyclerView rv, @Nullable ExtendedFloatingActionButton fab) {
        if (rv == null || fab == null) return;
        rv.addOnScrollListener(new RecyclerView.OnScrollListener() {
            @Override
            public void onScrolled(@NonNull RecyclerView recyclerView, int dx, int dy) {
                if (dy > 8 && fab.isExtended()) {
                    fab.shrink();
                } else if (dy < -8 && !fab.isExtended()) {
                    fab.extend();
                }
            }
        });
    }
}
