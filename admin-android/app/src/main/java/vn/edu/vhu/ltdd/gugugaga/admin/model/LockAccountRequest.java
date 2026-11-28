package vn.edu.vhu.ltdd.gugugaga.admin.model;

/** Body gửi PATCH /quan-tri/tai-khoan/{id} để khóa hoặc mở tài khoản. */
public class LockAccountRequest {
    public final boolean dangHoatDong;

    public LockAccountRequest(boolean dangHoatDong) {
        this.dangHoatDong = dangHoatDong;
    }
}
