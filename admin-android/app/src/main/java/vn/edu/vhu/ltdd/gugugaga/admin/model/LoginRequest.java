package vn.edu.vhu.ltdd.gugugaga.admin.model;

/** Body của POST /auth/dang-nhap. Tên trường khớp JSON của backend (Phụ lục 2). */
public class LoginRequest {
    public final String email;
    public final String matKhau;

    public LoginRequest(String email, String matKhau) {
        this.email = email;
        this.matKhau = matKhau;
    }
}
