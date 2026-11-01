package vn.edu.vhu.ltdd.gugugaga.admin.data;

import android.content.Context;

import java.util.List;

import vn.edu.vhu.ltdd.gugugaga.admin.model.NhaCungCap;
import vn.edu.vhu.ltdd.gugugaga.admin.model.YeuCauDuyet;

/** API hồ sơ nhà cung cấp cho quản trị. */
public class NhaCungCapRepository {
    private static final int KICH_THUOC_TRANG = 100;

    private final Context app;

    public NhaCungCapRepository(Context ctx) {
        this.app = ctx.getApplicationContext();
    }

    /** @param trangThai CHO_DUYET / DA_DUYET / TU_CHOI, hoặc null để lấy tất cả. */
    public void danhSach(String trangThai, KetQuaApi<List<NhaCungCap>> kq) {
        GoiApi.goi(app, ApiClient.get(app).dsNhaCungCapQuanTri(trangThai, 1, KICH_THUOC_TRANG), true,
                GoiApi.chiLayDuLieu(kq));
    }

    public void chiTiet(int id, KetQuaApi<NhaCungCap> kq) {
        GoiApi.goi(app, ApiClient.get(app).chiTietNhaCungCap(id), true, kq);
    }

    /** Chỉ QUAN_TRI; backend trả 409 nếu thiếu ảnh cơ sở hoặc chứng nhận OCOP còn hiệu lực. */
    public void duyet(int id, KetQuaApi<NhaCungCap> kq) {
        GoiApi.goi(app, ApiClient.get(app).duyetNhaCungCap(id, YeuCauDuyet.duyetHoSo()), true, kq);
    }

    public void tuChoi(int id, String lyDo, KetQuaApi<NhaCungCap> kq) {
        GoiApi.goi(app, ApiClient.get(app).duyetNhaCungCap(id, YeuCauDuyet.tuChoi(lyDo)), true, kq);
    }
}
