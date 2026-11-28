package vn.edu.vhu.ltdd.gugugaga.admin.data;

import android.content.Context;

import java.util.List;

import vn.edu.vhu.ltdd.gugugaga.admin.model.SourcingRegion;

/** Truy cập danh sách vùng nguyên liệu. Màn hình không gọi Retrofit trực tiếp. */
public class SourcingRegionRepository {
    private final Context app;

    public SourcingRegionRepository(Context ctx) {
        this.app = ctx.getApplicationContext();
    }

    public void danhSach(ApiResult<List<SourcingRegion>> kq) {
        ApiCall.goi(app, ApiClient.get(app).dsVungNguyenLieu(), false, kq);
    }
}
