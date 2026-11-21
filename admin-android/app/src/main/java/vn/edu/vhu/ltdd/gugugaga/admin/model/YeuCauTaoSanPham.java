package vn.edu.vhu.ltdd.gugugaga.admin.model;

/** Body gửi POST /san-pham để nhân sự nhập sản phẩm mới cho một nhà cung cấp. */
public class YeuCauTaoSanPham {
    public final int nhaCungCapId;
    public final String ten;
    public final int gia;
    public final String donViTinh;
    public final String moTa;
    public final String anhUrl;

    public YeuCauTaoSanPham(int nhaCungCapId, String ten, int gia,
                            String donViTinh, String moTa, String anhUrl) {
        this.nhaCungCapId = nhaCungCapId;
        this.ten = ten;
        this.gia = gia;
        this.donViTinh = donViTinh;
        this.moTa = moTa;
        this.anhUrl = anhUrl;
    }
}
