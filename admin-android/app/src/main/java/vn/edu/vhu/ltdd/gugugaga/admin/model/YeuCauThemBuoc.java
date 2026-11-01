package vn.edu.vhu.ltdd.gugugaga.admin.model;

/** Body của POST /lo-san-xuat/:id/buoc. Không gửi thuTu: backend lấy thứ tự kế tiếp. */
public class YeuCauThemBuoc {
    public final String tenBuoc;
    /** ISO 8601 có múi giờ, vd 2026-03-01T07:00:00+07:00. */
    public final String thoiDiem;
    public final String moTa;
    public final String anhUrl;

    public YeuCauThemBuoc(String tenBuoc, String thoiDiem, String moTa, String anhUrl) {
        this.tenBuoc = tenBuoc;
        this.thoiDiem = thoiDiem;
        this.moTa = moTa;
        this.anhUrl = anhUrl;
    }
}
