package vn.edu.vhu.ltdd.gugugaga.admin;

/** Hằng số dùng chung của app Admin. */
public final class AppConfig {
    /** TAG log chứa mã nhóm "gugugaga" (C.1 #10, Lab A1): lọc Logcat bằng tag:GUGUGAGA_ADMIN. */
    public static final String TAG = "GUGUGAGA_ADMIN";

    /** Địa chỉ backend, khai báo trong gradle.properties (debug/release khác nhau). */
    public static final String API_BASE_URL = BuildConfig.API_BASE_URL;

    public static final String VAI_TRO_QUAN_TRI = "QUAN_TRI";
    public static final String VAI_TRO_NHAN_VIEN = "NHAN_VIEN";
    public static final String VAI_TRO_KHACH = "KHACH";

    public static final String TRANG_THAI_CHO_DUYET = "CHO_DUYET";
    public static final String TRANG_THAI_DA_DUYET = "DA_DUYET";
    public static final String TRANG_THAI_TU_CHOI = "TU_CHOI";

    private AppConfig() { }
}
