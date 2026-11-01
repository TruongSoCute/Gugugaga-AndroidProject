package vn.edu.vhu.ltdd.gugugaga.admin.data;

import android.content.Context;

import vn.edu.vhu.ltdd.gugugaga.admin.AppConfig;
import vn.edu.vhu.ltdd.gugugaga.admin.R;
import vn.edu.vhu.ltdd.gugugaga.admin.model.KetQuaDangNhap;
import vn.edu.vhu.ltdd.gugugaga.admin.model.YeuCauDangNhap;

/** Đăng nhập cho app Admin: chỉ nhận tài khoản QUAN_TRI hoặc NHAN_VIEN. */
public class AuthRepository {
    private final Context app;

    public AuthRepository(Context ctx) {
        this.app = ctx.getApplicationContext();
    }

    public void dangNhap(String email, String matKhau, KetQuaApi<KetQuaDangNhap> kq) {
        GoiApi.goi(app, ApiClient.get(app).dangNhap(new YeuCauDangNhap(email, matKhau)), false,
                new KetQuaApi<KetQuaDangNhap>() {
                    @Override
                    public void thanhCong(KetQuaDangNhap duLieu) {
                        // App chỉ ẩn bớt chức năng; backend vẫn chặn khách gọi API quản trị bằng 403.
                        if (duLieu.nguoiDung == null || AppConfig.VAI_TRO_KHACH.equals(duLieu.nguoiDung.vaiTro)) {
                            kq.loi(app.getString(R.string.loi_tai_khoan_khach));
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
