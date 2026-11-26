package vn.edu.vhu.ltdd.gugugaga.admin.data;

import android.content.Context;

import vn.edu.vhu.ltdd.gugugaga.admin.model.DanhSach;
import vn.edu.vhu.ltdd.gugugaga.admin.model.NhaCungCap;
import vn.edu.vhu.ltdd.gugugaga.admin.model.YeuCauDuyet;
import vn.edu.vhu.ltdd.gugugaga.admin.model.YeuCauTaoNhaCungCap;

/** API hồ sơ nhà cung cấp cho quản trị. */
public class NhaCungCapRepository {
    private final Context app;

    public NhaCungCapRepository(Context ctx) {
        this.app = ctx.getApplicationContext();
    }

    /**
     * Một trang hồ sơ nhà cung cấp, kèm phanTrang.
     *
     * @param trangThai CHO_DUYET / DA_DUYET / TU_CHOI, hoặc null để lấy tất cả.
     */
    public void danhSach(String trangThai, int trang, int kichThuoc, KetQuaApi<DanhSach<NhaCungCap>> kq) {
        GoiApi.goi(app, ApiClient.get(app).dsNhaCungCapQuanTri(trangThai, trang, kichThuoc), true, kq);
    }

    public void danhSach(KetQuaApi<java.util.List<NhaCungCap>> kq) {
        GoiApi.goi(app, ApiClient.get(app).dsNhaCungCapQuanTri(null, 1, 100), true, GoiApi.chiLayDuLieu(kq));
    }

    public void chiTiet(int id, KetQuaApi<NhaCungCap> kq) {
        GoiApi.goi(app, ApiClient.get(app).chiTietNhaCungCap(id), true, kq);
    }

    public void tao(YeuCauTaoNhaCungCap body, KetQuaApi<NhaCungCap> kq) {
        GoiApi.goi(app, ApiClient.get(app).taoNhaCungCap(body), true, kq);
    }

    /** Chỉ QUAN_TRI; backend trả 409 nếu thiếu ảnh cơ sở hoặc chứng nhận OCOP còn hiệu lực. */
    public void duyet(int id, KetQuaApi<NhaCungCap> kq) {
        GoiApi.goi(app, ApiClient.get(app).duyetNhaCungCap(id, YeuCauDuyet.duyetHoSo()), true, kq);
    }

    public void tuChoi(int id, String lyDo, KetQuaApi<NhaCungCap> kq) {
        GoiApi.goi(app, ApiClient.get(app).duyetNhaCungCap(id, YeuCauDuyet.tuChoi(lyDo)), true, kq);
    }
}
