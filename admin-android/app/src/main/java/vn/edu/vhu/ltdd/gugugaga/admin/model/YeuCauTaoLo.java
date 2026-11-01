package vn.edu.vhu.ltdd.gugugaga.admin.model;

/**
 * Body của POST /lo-san-xuat. Không có maTruyXuat: mã do server sinh.
 * Trường tùy chọn để null thì Gson không gửi.
 */
public class YeuCauTaoLo {
    public final int sanPhamId;
    public final String ngaySanXuat;
    public final String hanSuDung;
    public final int soLuong;
    public final String nguoiSanXuat;
    public final String anhHienTruongUrl;
    public final String ghiChu;

    public YeuCauTaoLo(int sanPhamId, String ngaySanXuat, String hanSuDung, int soLuong,
                       String nguoiSanXuat, String anhHienTruongUrl, String ghiChu) {
        this.sanPhamId = sanPhamId;
        this.ngaySanXuat = ngaySanXuat;
        this.hanSuDung = hanSuDung;
        this.soLuong = soLuong;
        this.nguoiSanXuat = nguoiSanXuat;
        this.anhHienTruongUrl = anhHienTruongUrl;
        this.ghiChu = ghiChu;
    }
}
