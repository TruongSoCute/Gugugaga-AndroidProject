package vn.edu.vhu.ltdd.gugugaga.admin.data;

import android.content.Context;

import vn.edu.vhu.ltdd.gugugaga.admin.model.DanhSach;
import vn.edu.vhu.ltdd.gugugaga.admin.model.DonHang;
import vn.edu.vhu.ltdd.gugugaga.admin.model.YeuCauDoiTrangThai;

/** API đơn hàng cho nhân sự. Màn hình không gọi Retrofit trực tiếp. */
public class DonHangRepository {
    private final Context app;

    public DonHangRepository(Context ctx) {
        this.app = ctx.getApplicationContext();
    }

    /**
     * Một trang đơn hàng (mới nhất trước), kèm phanTrang để màn hình biết còn trang sau không.
     *
     * @param trangThai một trạng thái đơn, hoặc null để lấy tất cả.
     */
    public void danhSach(String trangThai, int trang, int kichThuoc, KetQuaApi<DanhSach<DonHang>> kq) {
        GoiApi.goi(app, ApiClient.get(app).dsDonHangQuanTri(trangThai, trang, kichThuoc), true, kq);
    }

    public void chiTiet(int id, KetQuaApi<DonHang> kq) {
        GoiApi.goi(app, ApiClient.get(app).chiTietDonHang(id), true, kq);
    }

    /** Backend kiểm tra bước chuyển (403/409) và bắt buộc ghiChu khi hủy (400). */
    public void doiTrangThai(int id, String trangThai, String ghiChu, KetQuaApi<DonHang> kq) {
        GoiApi.goi(app, ApiClient.get(app).doiTrangThaiDon(id, new YeuCauDoiTrangThai(trangThai, ghiChu)), true, kq);
    }
}
