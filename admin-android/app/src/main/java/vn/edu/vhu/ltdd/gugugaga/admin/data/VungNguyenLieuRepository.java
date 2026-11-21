package vn.edu.vhu.ltdd.gugugaga.admin.data;

import android.content.Context;

import java.util.List;

import vn.edu.vhu.ltdd.gugugaga.admin.model.VungNguyenLieu;

/** Truy cập danh sách vùng nguyên liệu. Màn hình không gọi Retrofit trực tiếp. */
public class VungNguyenLieuRepository {
    private final Context app;

    public VungNguyenLieuRepository(Context ctx) {
        this.app = ctx.getApplicationContext();
    }

    public void danhSach(KetQuaApi<List<VungNguyenLieu>> kq) {
        GoiApi.goi(app, ApiClient.get(app).dsVungNguyenLieu(), false, kq);
    }
}
