package vn.edu.vhu.ltdd.gugugaga.admin.ui.common;

/**
 * Trạng thái một màn hình đang tải dữ liệu từ API: đủ 3 trạng thái của C.1 #8
 * (đang tải / thành công / lỗi) cộng thêm hết phiên đăng nhập.
 */
public final class UiState<T> {
    public enum Loai { DANG_TAI, THANH_CONG, LOI, HET_PHIEN }

    public final Loai loai;
    public final T duLieu;
    public final String thongDiep;

    private UiState(Loai loai, T duLieu, String thongDiep) {
        this.loai = loai;
        this.duLieu = duLieu;
        this.thongDiep = thongDiep;
    }

    public static <T> UiState<T> dangTai() { return new UiState<>(Loai.DANG_TAI, null, null); }
    public static <T> UiState<T> thanhCong(T duLieu) { return new UiState<>(Loai.THANH_CONG, duLieu, null); }
    public static <T> UiState<T> loi(String thongDiep) { return new UiState<>(Loai.LOI, null, thongDiep); }
    public static <T> UiState<T> hetPhien() { return new UiState<>(Loai.HET_PHIEN, null, null); }
}
