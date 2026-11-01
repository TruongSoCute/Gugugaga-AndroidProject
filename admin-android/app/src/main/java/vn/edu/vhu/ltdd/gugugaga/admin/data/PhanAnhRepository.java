package vn.edu.vhu.ltdd.gugugaga.admin.data;

import android.content.Context;

import java.util.List;

import vn.edu.vhu.ltdd.gugugaga.admin.model.PhanAnh;
import vn.edu.vhu.ltdd.gugugaga.admin.model.YeuCauXuLyPhanAnh;

/** API phản ánh hàng giả, sai mô tả cho nhân sự. */
public class PhanAnhRepository {
    private static final int KICH_THUOC_TRANG = 100;

    private final Context app;

    public PhanAnhRepository(Context ctx) {
        this.app = ctx.getApplicationContext();
    }

    /** @param trangThai MOI / DANG_XU_LY / DA_XU_LY / BAC_BO, hoặc null để lấy tất cả. */
    public void danhSach(String trangThai, KetQuaApi<List<PhanAnh>> kq) {
        GoiApi.goi(app, ApiClient.get(app).dsPhanAnh(trangThai, 1, KICH_THUOC_TRANG), true,
                GoiApi.chiLayDuLieu(kq));
    }

    public void chiTiet(int id, KetQuaApi<PhanAnh> kq) {
        GoiApi.goi(app, ApiClient.get(app).chiTietPhanAnh(id), true, kq);
    }

    /** Chỉ đi tới; backend trả 409 nếu sai thứ tự, 400 nếu thiếu kết quả khi kết thúc. */
    public void xuLy(int id, String trangThai, String ketQuaXuLy, KetQuaApi<PhanAnh> kq) {
        GoiApi.goi(app, ApiClient.get(app).xuLyPhanAnh(id, new YeuCauXuLyPhanAnh(trangThai, ketQuaXuLy)), true, kq);
    }
}
