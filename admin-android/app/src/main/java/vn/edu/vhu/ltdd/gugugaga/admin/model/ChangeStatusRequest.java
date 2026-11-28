package vn.edu.vhu.ltdd.gugugaga.admin.model;

/** Body của PATCH /don-hang/:id/trang-thai. ghiChu = null thì Gson không gửi. */
public class ChangeStatusRequest {
    public final String trangThai;
    public final String ghiChu;

    public ChangeStatusRequest(String trangThai, String ghiChu) {
        this.trangThai = trangThai;
        this.ghiChu = ghiChu;
    }
}
