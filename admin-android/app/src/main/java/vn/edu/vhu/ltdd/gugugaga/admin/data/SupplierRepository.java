package vn.edu.vhu.ltdd.gugugaga.admin.data;

import android.content.Context;

import vn.edu.vhu.ltdd.gugugaga.admin.model.DataList;
import vn.edu.vhu.ltdd.gugugaga.admin.model.Supplier;
import vn.edu.vhu.ltdd.gugugaga.admin.model.ReviewRequest;
import vn.edu.vhu.ltdd.gugugaga.admin.model.CreateSupplierRequest;

/** API hồ sơ nhà cung cấp cho quản trị. */
public class SupplierRepository {
    private final Context app;

    public SupplierRepository(Context ctx) {
        this.app = ctx.getApplicationContext();
    }

    /**
     * Một trang hồ sơ nhà cung cấp, kèm phanTrang.
     *
     * @param trangThai CHO_DUYET / DA_DUYET / TU_CHOI, hoặc null để lấy tất cả.
     */
    public void danhSach(String trangThai, int trang, int kichThuoc, ApiResult<DataList<Supplier>> kq) {
        ApiCall.goi(app, ApiClient.get(app).dsNhaCungCapQuanTri(trangThai, trang, kichThuoc), true, kq);
    }

    public void danhSach(ApiResult<java.util.List<Supplier>> kq) {
        ApiCall.goi(app, ApiClient.get(app).dsNhaCungCapQuanTri(null, 1, 100), true, ApiCall.chiLayDuLieu(kq));
    }

    public void chiTiet(int id, ApiResult<Supplier> kq) {
        ApiCall.goi(app, ApiClient.get(app).chiTietNhaCungCap(id), true, kq);
    }

    public void tao(CreateSupplierRequest body, ApiResult<Supplier> kq) {
        ApiCall.goi(app, ApiClient.get(app).taoNhaCungCap(body), true, kq);
    }

    /** Chỉ QUAN_TRI; backend trả 409 nếu thiếu ảnh cơ sở hoặc chứng nhận OCOP còn hiệu lực. */
    public void duyet(int id, ApiResult<Supplier> kq) {
        ApiCall.goi(app, ApiClient.get(app).duyetNhaCungCap(id, ReviewRequest.duyetHoSo()), true, kq);
    }

    public void tuChoi(int id, String lyDo, ApiResult<Supplier> kq) {
        ApiCall.goi(app, ApiClient.get(app).duyetNhaCungCap(id, ReviewRequest.tuChoi(lyDo)), true, kq);
    }
}
