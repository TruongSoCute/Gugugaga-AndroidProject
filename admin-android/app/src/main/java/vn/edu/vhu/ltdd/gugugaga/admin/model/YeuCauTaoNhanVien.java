package vn.edu.vhu.ltdd.gugugaga.admin.model;

/** Body gửi POST /quan-tri/tai-khoan để tạo tài khoản NHAN_VIEN. */
public class YeuCauTaoNhanVien {
    public final String email;
    public final String matKhau;
    public final String hoTen;
    public final String soDienThoai;

    public YeuCauTaoNhanVien(String email, String matKhau, String hoTen, String soDienThoai) {
        this.email = email;
        this.matKhau = matKhau;
        this.hoTen = hoTen;
        this.soDienThoai = (soDienThoai == null || soDienThoai.trim().isEmpty()) ? null : soDienThoai.trim();
    }
}
