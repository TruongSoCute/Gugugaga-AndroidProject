package vn.edu.vhu.ltdd.gugugaga.admin.data;

import android.content.Context;

import vn.edu.vhu.ltdd.gugugaga.admin.model.DataList;
import vn.edu.vhu.ltdd.gugugaga.admin.model.User;
import vn.edu.vhu.ltdd.gugugaga.admin.model.LockAccountRequest;
import vn.edu.vhu.ltdd.gugugaga.admin.model.CreateStaffRequest;

/** API quản lý tài khoản nhân sự cho quản trị (chỉ QUAN_TRI). */
public class AccountRepository {
    private final Context app;

    public AccountRepository(Context ctx) {
        this.app = ctx.getApplicationContext();
    }

    public void danhSach(int trang, int kichThuoc, ApiResult<DataList<User>> kq) {
        ApiCall.goi(app, ApiClient.get(app).dsTaiKhoanQuanTri(trang, kichThuoc), true, kq);
    }

    public void taoNhanVien(CreateStaffRequest body, ApiResult<User> kq) {
        ApiCall.goi(app, ApiClient.get(app).taoNhanVien(body), true, kq);
    }

    public void capNhatTrangThai(int id, boolean dangHoatDong, ApiResult<User> kq) {
        ApiCall.goi(app, ApiClient.get(app).capNhatTrangThaiTaiKhoan(id, new LockAccountRequest(dangHoatDong)), true, kq);
    }
}
