package vn.edu.vhu.ltdd.gugugaga.admin.data;

import android.content.Context;

import vn.edu.vhu.ltdd.gugugaga.admin.R;
import vn.edu.vhu.ltdd.gugugaga.admin.model.LoginResult;
import vn.edu.vhu.ltdd.gugugaga.admin.model.LoginRequest;
import vn.edu.vhu.ltdd.gugugaga.admin.util.RolePermissions;

/**
 * Đăng nhập cho app Admin: chỉ nhận tài khoản QUAN_TRI hoặc NHAN_VIEN. Khách và nhà cung cấp
 * dùng app Client, nên bị từ chối ngay và KHÔNG lưu token.
 */
public class AuthRepository {
    private final Context app;

    public AuthRepository(Context ctx) {
        this.app = ctx.getApplicationContext();
    }

    public void dangNhap(String email, String matKhau, ApiResult<LoginResult> kq) {
        ApiCall.goi(app, ApiClient.get(app).dangNhap(new LoginRequest(email, matKhau)), false,
                new ApiResult<LoginResult>() {
                    @Override
                    public void thanhCong(LoginResult duLieu) {
                        // Danh sách trắng: chỉ nhân sự. Backend vẫn chặn vai trò khác bằng 403.
                        if (duLieu.nguoiDung == null || !RolePermissions.duocDungAppAdmin(duLieu.nguoiDung.vaiTro)) {
                            kq.loi(app.getString(R.string.loi_tai_khoan_khong_phai_nhan_su));
                            return;
                        }
                        TokenStore.luu(app, duLieu);
                        kq.thanhCong(duLieu);
                    }

                    @Override
                    public void loi(String thongDiep) {
                        kq.loi(thongDiep);
                    }

                    @Override
                    public void hetPhien() {
                        kq.hetPhien();
                    }
                });
    }
}
