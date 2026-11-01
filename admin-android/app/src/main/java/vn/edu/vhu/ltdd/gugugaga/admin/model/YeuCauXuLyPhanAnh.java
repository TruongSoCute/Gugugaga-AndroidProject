package vn.edu.vhu.ltdd.gugugaga.admin.model;

/** Body của PATCH /quan-tri/bao-cao-vi-pham/:id. ketQuaXuLy bắt buộc khi DA_XU_LY/BAC_BO. */
public class YeuCauXuLyPhanAnh {
    public final String trangThai;
    public final String ketQuaXuLy;

    public YeuCauXuLyPhanAnh(String trangThai, String ketQuaXuLy) {
        this.trangThai = trangThai;
        this.ketQuaXuLy = ketQuaXuLy;
    }
}
