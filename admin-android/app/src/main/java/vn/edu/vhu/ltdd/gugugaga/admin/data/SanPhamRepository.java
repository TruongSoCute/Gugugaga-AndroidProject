package vn.edu.vhu.ltdd.gugugaga.admin.data;

import android.content.Context;

import java.util.List;

import vn.edu.vhu.ltdd.gugugaga.admin.model.DanhSach;
import vn.edu.vhu.ltdd.gugugaga.admin.model.SanPham;
import vn.edu.vhu.ltdd.gugugaga.admin.model.YeuCauDuyet;

/** Truy cập API sản phẩm cho màn hình quản trị. Màn hình không gọi Retrofit trực tiếp. */
public class SanPhamRepository {
    /** Backend cho tối đa 100 dòng mỗi trang. */
    private static final int KICH_THUOC_TRANG = 100;

    private final Context app;

    public SanPhamRepository(Context ctx) {
        this.app = ctx.getApplicationContext();
    }

    /** @param trangThai CHO_DUYET / DA_DUYET / TU_CHOI, hoặc null để lấy tất cả. */
    public void danhSach(String trangThai, KetQuaApi<List<SanPham>> kq) {
        GoiApi.goi(app, ApiClient.get(app).dsSanPhamQuanTri(trangThai, 1, KICH_THUOC_TRANG), true,
                new KetQuaApi<DanhSach<SanPham>>() {
                    @Override
                    public void thanhCong(DanhSach<SanPham> duLieu) {
                        kq.thanhCong(duLieu.duLieu);
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

    public void duyet(int id, int hangSao, KetQuaApi<SanPham> kq) {
        GoiApi.goi(app, ApiClient.get(app).duyetSanPham(id, YeuCauDuyet.duyet(hangSao)), true, kq);
    }

    public void tuChoi(int id, String lyDo, KetQuaApi<SanPham> kq) {
        GoiApi.goi(app, ApiClient.get(app).duyetSanPham(id, YeuCauDuyet.tuChoi(lyDo)), true, kq);
    }
}
