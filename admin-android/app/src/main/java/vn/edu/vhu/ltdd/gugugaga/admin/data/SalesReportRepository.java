package vn.edu.vhu.ltdd.gugugaga.admin.data;

import android.content.Context;

import vn.edu.vhu.ltdd.gugugaga.admin.model.SalesReport;

/** API báo cáo doanh số (chỉ QUAN_TRI). */
public class SalesReportRepository {
    private final Context app;

    public SalesReportRepository(Context ctx) {
        this.app = ctx.getApplicationContext();
    }

    /** @param tu, den yyyy-MM-dd hoặc null; backend trả 400 nếu tu > den. */
    public void doanhSo(String tu, String den, ApiResult<SalesReport> kq) {
        ApiCall.goi(app, ApiClient.get(app).baoCaoDoanhSo(tu, den), true, kq);
    }
}
