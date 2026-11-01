package vn.edu.vhu.ltdd.gugugaga.admin.util;

/** Vai trò nào được dùng app Admin. Backend vẫn chặn bằng 403 với mọi API quản trị. */
public final class PhanQuyen {
    public static final String QUAN_TRI = "QUAN_TRI";
    public static final String NHAN_VIEN = "NHAN_VIEN";

    private PhanQuyen() { }

    /** Chỉ nhân sự (QUAN_TRI, NHAN_VIEN); KHACH, NHA_CUNG_CAP hay vai trò lạ đều bị từ chối. */
    public static boolean duocDungAppAdmin(String vaiTro) {
        return QUAN_TRI.equals(vaiTro) || NHAN_VIEN.equals(vaiTro);
    }

    public static boolean laQuanTri(String vaiTro) {
        return QUAN_TRI.equals(vaiTro);
    }
}
