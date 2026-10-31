package vn.edu.vhu.ltdd.gugugaga.admin.data;

import android.content.Context;
import android.content.SharedPreferences;

import vn.edu.vhu.ltdd.gugugaga.admin.model.KetQuaDangNhap;

/**
 * Lưu phiên đăng nhập bằng SharedPreferences (Phụ lục 2: TokenStore).
 * Chỉ lưu token và thông tin hiển thị; không bao giờ lưu mật khẩu.
 */
public final class TokenStore {
    private static final String TEN_FILE = "gugugaga_admin_phien";
    private static final String KEY_TOKEN = "token";
    private static final String KEY_VAI_TRO = "vai_tro";
    private static final String KEY_HO_TEN = "ho_ten";
    private static final String KEY_EMAIL = "email";

    private TokenStore() { }

    private static SharedPreferences prefs(Context ctx) {
        return ctx.getApplicationContext().getSharedPreferences(TEN_FILE, Context.MODE_PRIVATE);
    }

    public static void luu(Context ctx, KetQuaDangNhap kq) {
        prefs(ctx).edit()
                .putString(KEY_TOKEN, kq.token)
                .putString(KEY_VAI_TRO, kq.nguoiDung.vaiTro)
                .putString(KEY_HO_TEN, kq.nguoiDung.hoTen)
                .putString(KEY_EMAIL, kq.nguoiDung.email)
                .apply();
    }

    public static String layToken(Context ctx) {
        return prefs(ctx).getString(KEY_TOKEN, null);
    }

    public static String layVaiTro(Context ctx) {
        return prefs(ctx).getString(KEY_VAI_TRO, "");
    }

    public static String layHoTen(Context ctx) {
        return prefs(ctx).getString(KEY_HO_TEN, "");
    }

    public static String layEmail(Context ctx) {
        return prefs(ctx).getString(KEY_EMAIL, "");
    }

    public static boolean daDangNhap(Context ctx) {
        return layToken(ctx) != null;
    }

    /** Xóa phiên: dùng khi đăng xuất hoặc khi backend trả 401 (token hết hạn). */
    public static void xoa(Context ctx) {
        prefs(ctx).edit().clear().apply();
    }
}
