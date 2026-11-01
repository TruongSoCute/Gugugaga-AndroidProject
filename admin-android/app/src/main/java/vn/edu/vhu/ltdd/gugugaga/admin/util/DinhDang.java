package vn.edu.vhu.ltdd.gugugaga.admin.util;

import java.text.NumberFormat;
import java.util.Locale;

/** Định dạng hiển thị. Tiền lưu bằng int, chỉ định dạng khi hiện ra màn hình (Lab A9). */
public final class DinhDang {
    private static final Locale VI = Locale.forLanguageTag("vi-VN");

    private DinhDang() { }

    /** 320000 -> "320.000 đ" */
    public static String tien(long dong) {
        return NumberFormat.getIntegerInstance(VI).format(dong) + " đ";
    }
}
