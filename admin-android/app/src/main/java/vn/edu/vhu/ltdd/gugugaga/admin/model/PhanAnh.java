package vn.edu.vhu.ltdd.gugugaga.admin.model;

/** Phản ánh hàng giả, sai mô tả (GET /quan-tri/bao-cao-vi-pham và /:id). */
public class PhanAnh {
    public int id;
    public int sanPhamId;
    public String tenSanPham;
    public int nhaCungCapId;
    public String tenNhaCungCap;
    /** null nếu khách không ghi mã lô. */
    public Integer loId;
    public String maTruyXuat;
    public String loai;
    public String noiDung;
    public String anhUrl;
    public String trangThai;
    public String ketQuaXuLy;
    public String xuLyLuc;
    public String taoLuc;
    public String tenNguoiBao;
    public String tenNguoiXuLy;
    /** Chỉ có ở chi tiết, để nhân sự liên hệ người báo. */
    public String emailNguoiBao;
}
