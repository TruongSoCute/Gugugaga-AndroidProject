
package vn.edu.vhu.ltdd.gugugaga.admin.data;

import android.content.Context;

import java.util.List;

import vn.edu.vhu.ltdd.gugugaga.admin.model.DanhSach;
import vn.edu.vhu.ltdd.gugugaga.admin.model.SanPham;
import vn.edu.vhu.ltdd.gugugaga.admin.model.YeuCauDuyet;

/**
 * Truy cập API sản phẩm cho màn hình quản trị.
 * Màn hình không gọi Retrofit trực tiếp.
 */
public class SanPhamRepository {

    private static final int KICH_THUOC_TRANG = 100;

    private final Context app;

    public SanPhamRepository(Context ctx) {
        this.app = ctx.getApplicationContext();
    }

    /**
     * Lấy danh sách sản phẩm có phân trang.
     *
     * @param trangThai CHO_DUYET / DA_DUYET / TU_CHOI,
     *                  hoặc null để lấy tất cả.
     * @param trang Số trang cần lấy, bắt đầu từ 1.
     * @param kq Kết quả trả về gồm dữ liệu và thông tin phân trang.
     */
    public void danhSach(
            String trangThai,
            int trang,
            KetQuaApi<DanhSach<SanPham>> kq
    ) {
        GoiApi.goi(
                app,
                ApiClient.get(app).dsSanPhamQuanTri(
                        trangThai,
                        trang,
                        KICH_THUOC_TRANG
                ),
                true,
                kq
        );
    }

    /**
     * Phương thức tương thích với code cũ.
     * Dùng cho các màn hình chỉ cần List<SanPham>,
     * ví dụ TaoLoViewModel.
     */
    public void danhSach(
            String trangThai,
            KetQuaApi<List<SanPham>> kq
    ) {
        danhSach(
                trangThai,
                1,
                new KetQuaApi<DanhSach<SanPham>>() {

                    @Override
                    public void thanhCong(DanhSach<SanPham> duLieu) {
                        if (duLieu != null) {
                            kq.thanhCong(duLieu.duLieu);
                        } else {
                            kq.thanhCong(null);
                        }
                    }

                    @Override
                    public void loi(String thongDiep) {
                        kq.loi(thongDiep);
                    }

                    @Override
                    public void hetPhien() {
                        kq.hetPhien();
                    }

                    @Override
                    public void loiDuLieu(
                            String thongDiep,
                            java.util.Map<String, String> loiTheoTruong
                    ) {
                        kq.loiDuLieu(thongDiep, loiTheoTruong);
                    }
                }
        );
    }

    /**
     * Duyệt sản phẩm.
     */
    public void duyet(
            int id,
            int hangSao,
            KetQuaApi<SanPham> kq
    ) {
        GoiApi.goi(
                app,
                ApiClient.get(app).duyetSanPham(
                        id,
                        YeuCauDuyet.duyet(hangSao)
                ),
                true,
                kq
        );
    }

    /**
     * Từ chối sản phẩm.
     */
    public void tuChoi(
            int id,
            String lyDo,
            KetQuaApi<SanPham> kq
    ) {
        GoiApi.goi(
                app,
                ApiClient.get(app).duyetSanPham(
                        id,
                        YeuCauDuyet.tuChoi(lyDo)
                ),
                true,
                kq
        );
    }
}
