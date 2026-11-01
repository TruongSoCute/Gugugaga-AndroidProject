package vn.edu.vhu.ltdd.gugugaga.admin.ui.chung;

/**
 * Trạng thái một màn hình đang tải dữ liệu từ API: đủ 3 trạng thái của C.1 #8
 * (đang tải / thành công / lỗi) cộng thêm hết phiên đăng nhập.
 */
public final class TrangThai<T> {
    public enum Loai { DANG_TAI, THANH_CONG, LOI, HET_PHIEN }

    public final Loai loai;
    public final T duLieu;
    public final String thongDiep;

    private TrangThai(Loai loai, T duLieu, String thongDiep) {
        this.loai = loai;
        this.duLieu = duLieu;
        this.thongDiep = thongDiep;
    }

    public static <T> TrangThai<T> dangTai() { return new TrangThai<>(Loai.DANG_TAI, null, null); }
    public static <T> TrangThai<T> thanhCong(T duLieu) { return new TrangThai<>(Loai.THANH_CONG, duLieu, null); }
    public static <T> TrangThai<T> loi(String thongDiep) { return new TrangThai<>(Loai.LOI, null, thongDiep); }
    public static <T> TrangThai<T> hetPhien() { return new TrangThai<>(Loai.HET_PHIEN, null, null); }
}
