package vn.edu.vhu.ltdd.gugugaga.admin.data;

import android.content.Context;

import vn.edu.vhu.ltdd.gugugaga.admin.model.BaoCaoDoanhSo;

/** API báo cáo doanh số (chỉ QUAN_TRI). */
public class BaoCaoRepository {
    private final Context app;

    public BaoCaoRepository(Context ctx) {
        this.app = ctx.getApplicationContext();
    }

    /** @param tu, den yyyy-MM-dd hoặc null; backend trả 400 nếu tu > den. */
    public void doanhSo(String tu, String den, KetQuaApi<BaoCaoDoanhSo> kq) {
        GoiApi.goi(app, ApiClient.get(app).baoCaoDoanhSo(tu, den), true, kq);
    }
}
