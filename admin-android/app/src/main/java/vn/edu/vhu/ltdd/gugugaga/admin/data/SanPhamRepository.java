package vn.edu.vhu.ltdd.gugugaga.admin.data;

import android.content.Context;

import java.util.List;

import vn.edu.vhu.ltdd.gugugaga.admin.model.DanhSach;
import vn.edu.vhu.ltdd.gugugaga.admin.model.SanPham;
import vn.edu.vhu.ltdd.gugugaga.admin.model.YeuCauDuyet;

/** Truy cập API sản phẩm cho màn hình quản trị. Màn hình không gọi Retrofit trực tiếp. */
public class SanPhamRepository {
    /** Form tạo lô cần đủ sản phẩm trong một lần gọi: lấy trang lớn nhất backend cho (100 dòng). */
    private static final int KICH_THUOC_TRANG_CHON = 100;

    private final Context app;

    public SanPhamRepository(Context ctx) {
        this.app = ctx.getApplicationContext();
    }

    /**
     * Một trang sản phẩm cho danh sách quản trị, kèm phanTrang.
     *
     * @param trangThai CHO_DUYET / DA_DUYET / TU_CHOI, hoặc null để lấy tất cả.
     */
    public void danhSach(String trangThai, int trang, int kichThuoc, KetQuaApi<DanhSach<SanPham>> kq) {
        GoiApi.goi(app, ApiClient.get(app).dsSanPhamQuanTri(trangThai, trang, kichThuoc), true, kq);
    }

    /** Tối đa 100 sản phẩm trong một lần, chỉ phần duLieu (Spinner chọn sản phẩm khi tạo lô). */
    public void danhSach(String trangThai, KetQuaApi<List<SanPham>> kq) {
        GoiApi.goi(app, ApiClient.get(app).dsSanPhamQuanTri(trangThai, 1, KICH_THUOC_TRANG_CHON), true,
                GoiApi.chiLayDuLieu(kq));
    }

    public void duyet(int id, int hangSao, KetQuaApi<SanPham> kq) {
        GoiApi.goi(app, ApiClient.get(app).duyetSanPham(id, YeuCauDuyet.duyet(hangSao)), true, kq);
    }

    public void tuChoi(int id, String lyDo, KetQuaApi<SanPham> kq) {
        GoiApi.goi(app, ApiClient.get(app).duyetSanPham(id, YeuCauDuyet.tuChoi(lyDo)), true, kq);
    }
}
