package vn.edu.vhu.ltdd.gugugaga.admin.util;

import java.util.Locale;

/** Phép tính thuần cho biểu đồ cột tự vẽ (tách khỏi View để kiểm thử không cần máy ảo). */
public final class BieuDo {
    private static final Locale VI = Locale.forLanguageTag("vi-VN");

    private BieuDo() { }

    /** Giá trị lớn nhất (không âm) của dãy, để cột dài nhất chiếm hết chiều rộng. */
    public static long lonNhat(long[] giaTri) {
        long max = 0;
        if (giaTri == null) return 0;
        for (long v : giaTri) if (v > max) max = v;
        return max;
    }

    /**
     * Tỉ lệ chiều dài cột so với cột dài nhất, trong [0, 1]. Ép sang double trước khi chia
     * (Lab A4). Cột lớn nhất bằng 0 (chưa bán được gì) thì mọi cột đều 0, không chia cho 0.
     */
    public static float tiLe(long giaTri, long lonNhat) {
        if (lonNhat <= 0 || giaTri <= 0) return 0f;
        double t = (double) giaTri / (double) lonNhat;
        return (float) Math.min(1.0, t);
    }

    /** Rút gọn số tiền cho nhãn cột: 13015000 -> "13 tr", 4950000 -> "4,9 tr", 690000 -> "690 N". */
    public static String rutGon(long dong) {
        if (dong >= 1_000_000_000L) return so(dong / 1e9) + " tỷ";
        if (dong >= 1_000_000L) return so(dong / 1e6) + " tr";
        if (dong >= 1_000L) return so(dong / 1e3) + " N";
        return String.valueOf(dong);
    }

    /** Một chữ số thập phân, cắt (không làm tròn lên) để không phóng đại doanh số; bỏ ",0". */
    private static String so(double x) {
        double cat = Math.floor(x * 10) / 10;
        if (cat == Math.floor(cat)) return String.format(VI, "%d", (long) cat);
        return String.format(VI, "%.1f", cat);
    }
}
