package vn.edu.vhu.ltdd.gugugaga.admin.data;

import android.content.Context;

import vn.edu.vhu.ltdd.gugugaga.admin.R;
import vn.edu.vhu.ltdd.gugugaga.admin.model.KetQuaDangNhap;
import vn.edu.vhu.ltdd.gugugaga.admin.model.YeuCauDangNhap;
import vn.edu.vhu.ltdd.gugugaga.admin.util.PhanQuyen;

/**
 * Đăng nhập cho app Admin: chỉ nhận tài khoản QUAN_TRI hoặc NHAN_VIEN. Khách và nhà cung cấp
 * dùng app Client, nên bị từ chối ngay và KHÔNG lưu token.
 */
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
                        // Danh sách trắng: chỉ nhân sự. Backend vẫn chặn vai trò khác bằng 403.
                        if (duLieu.nguoiDung == null || !PhanQuyen.duocDungAppAdmin(duLieu.nguoiDung.vaiTro)) {
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
