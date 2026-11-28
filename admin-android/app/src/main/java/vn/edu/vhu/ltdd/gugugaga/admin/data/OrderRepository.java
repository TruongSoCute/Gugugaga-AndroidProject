package vn.edu.vhu.ltdd.gugugaga.admin.data;

import android.content.Context;

import vn.edu.vhu.ltdd.gugugaga.admin.model.DataList;
import vn.edu.vhu.ltdd.gugugaga.admin.model.Order;
import vn.edu.vhu.ltdd.gugugaga.admin.model.ChangeStatusRequest;

/** API đơn hàng cho nhân sự. Màn hình không gọi Retrofit trực tiếp. */
public class OrderRepository {
    private final Context app;

    public OrderRepository(Context ctx) {
        this.app = ctx.getApplicationContext();
    }

    /**
     * Một trang đơn hàng (mới nhất trước), kèm phanTrang để màn hình biết còn trang sau không.
     *
     * @param trangThai một trạng thái đơn, hoặc null để lấy tất cả.
     */
    public void danhSach(String trangThai, int trang, int kichThuoc, ApiResult<DataList<Order>> kq) {
        ApiCall.goi(app, ApiClient.get(app).dsDonHangQuanTri(trangThai, trang, kichThuoc), true, kq);
    }

    public void chiTiet(int id, ApiResult<Order> kq) {
        ApiCall.goi(app, ApiClient.get(app).chiTietDonHang(id), true, kq);
    }

    /** Backend kiểm tra bước chuyển (403/409) và bắt buộc ghiChu khi hủy (400). */
    public void doiTrangThai(int id, String trangThai, String ghiChu, ApiResult<Order> kq) {
        ApiCall.goi(app, ApiClient.get(app).doiTrangThaiDon(id, new ChangeStatusRequest(trangThai, ghiChu)), true, kq);
    }
}
