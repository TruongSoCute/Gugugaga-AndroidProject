package vn.edu.vhu.ltdd.gugugaga.admin.model;

/** Thông tin tài khoản backend trả về (không bao giờ có mật khẩu). */
public class User {
    public int id;
    public String email;
    public String hoTen;
    public String soDienThoai;
    public String vaiTro;
    public boolean dangHoatDong = true;
    public String taoLuc;
}
