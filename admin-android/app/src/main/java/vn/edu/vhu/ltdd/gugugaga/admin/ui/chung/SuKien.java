package vn.edu.vhu.ltdd.gugugaga.admin.ui.chung;

/**
 * Sự kiện chỉ xử lý một lần (vd hiện Snackbar). Khi xoay màn hình, LiveData phát lại giá trị
 * cũ; nhờ cờ daXuLy mà thông báo không hiện lại lần nữa.
 */
public final class SuKien<T> {
    private final T noiDung;
    private boolean daXuLy;

    public SuKien(T noiDung) {
        this.noiDung = noiDung;
    }

    /** Trả nội dung ở lần gọi đầu tiên, các lần sau trả null. */
    public T layNeuChuaXuLy() {
        if (daXuLy) return null;
        daXuLy = true;
        return noiDung;
    }
}
