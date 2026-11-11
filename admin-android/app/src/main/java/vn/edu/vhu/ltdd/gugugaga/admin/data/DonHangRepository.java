
package vn.edu.vhu.ltdd.gugugaga.admin.data;

import android.content.Context;

import java.util.List;

import vn.edu.vhu.ltdd.gugugaga.admin.model.DanhSach;
import vn.edu.vhu.ltdd.gugugaga.admin.model.DonHang;
import vn.edu.vhu.ltdd.gugugaga.admin.model.YeuCauDoiTrangThai;

/**
 * API đơn hàng cho nhân sự.
 * Màn hình không gọi Retrofit trực tiếp.
 */
public class DonHangRepository {

    private static final int KICH_THUOC_TRANG = 100;

    private final Context app;

    public DonHangRepository(Context ctx) {
        this.app = ctx.getApplicationContext();
    }

    /**
     * Lấy danh sách đơn hàng có phân trang.
     *
     * @param trangThai trạng thái đơn hàng, hoặc null để lấy tất cả.
     * @param trang số trang cần lấy.
     */
    public void danhSach(
            String trangThai,
            int trang,
            KetQuaApi<DanhSach<DonHang>> kq
    ) {
        GoiApi.goi(
                app,
                ApiClient.get(app).dsDonHangQuanTri(
                        trangThai,
                        trang,
                        KICH_THUOC_TRANG
                ),
                true,
                kq
        );
    }

    /**
     * Giữ phương thức cũ để tương thích với các màn hình hiện tại.
     */
    public void danhSach(
            String trangThai,
            KetQuaApi<List<DonHang>> kq
    ) {
        GoiApi.goi(
                app,
                ApiClient.get(app).dsDonHangQuanTri(
                        trangThai,
                        1,
                        KICH_THUOC_TRANG
                ),
                true,
                GoiApi.chiLayDuLieu(kq)
        );
    }

    public void chiTiet(int id, KetQuaApi<DonHang> kq) {
        GoiApi.goi(
                app,
                ApiClient.get(app).chiTietDonHang(id),
                true,
                kq
        );
    }

    /**
     * Backend kiểm tra bước chuyển (403/409)
     * và bắt buộc ghiChu khi hủy (400).
     */
    public void doiTrangThai(
            int id,
            String trangThai,
            String ghiChu,
            KetQuaApi<DonHang> kq
    ) {
        GoiApi.goi(
                app,
                ApiClient.get(app).doiTrangThaiDon(
                        id,
                        new YeuCauDoiTrangThai(trangThai, ghiChu)
                ),
                true,
                kq
        );
    }
}
