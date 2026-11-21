package vn.edu.vhu.ltdd.gugugaga.admin.data;

import android.content.Context;

import vn.edu.vhu.ltdd.gugugaga.admin.model.DanhSach;
import vn.edu.vhu.ltdd.gugugaga.admin.model.NguoiDung;
import vn.edu.vhu.ltdd.gugugaga.admin.model.YeuCauKhoaTaiKhoan;
import vn.edu.vhu.ltdd.gugugaga.admin.model.YeuCauTaoNhanVien;

/** API quản lý tài khoản nhân sự cho quản trị (chỉ QUAN_TRI). */
public class TaiKhoanRepository {
    private final Context app;

    public TaiKhoanRepository(Context ctx) {
        this.app = ctx.getApplicationContext();
    }

    public void danhSach(int trang, int kichThuoc, KetQuaApi<DanhSach<NguoiDung>> kq) {
        GoiApi.goi(app, ApiClient.get(app).dsTaiKhoanQuanTri(trang, kichThuoc), true, kq);
    }

    public void taoNhanVien(YeuCauTaoNhanVien body, KetQuaApi<NguoiDung> kq) {
        GoiApi.goi(app, ApiClient.get(app).taoNhanVien(body), true, kq);
    }

    public void capNhatTrangThai(int id, boolean dangHoatDong, KetQuaApi<NguoiDung> kq) {
        GoiApi.goi(app, ApiClient.get(app).capNhatTrangThaiTaiKhoan(id, new YeuCauKhoaTaiKhoan(dangHoatDong)), true, kq);
    }
}
