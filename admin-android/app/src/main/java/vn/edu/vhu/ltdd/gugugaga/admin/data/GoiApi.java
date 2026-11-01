package vn.edu.vhu.ltdd.gugugaga.admin.data;

import android.content.Context;
import android.util.Log;

import androidx.annotation.NonNull;

import com.google.gson.Gson;

import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

import vn.edu.vhu.ltdd.gugugaga.admin.AppConfig;
import vn.edu.vhu.ltdd.gugugaga.admin.R;
import vn.edu.vhu.ltdd.gugugaga.admin.model.DanhSach;
import vn.edu.vhu.ltdd.gugugaga.admin.model.LoiApi;

import retrofit2.Call;
import retrofit2.Callback;
import retrofit2.Response;

/**
 * Gọi API bằng enqueue (chạy nền, không chặn main thread — Lab A2) và chia kết quả
 * thành đủ các nhánh của Phụ lục 2 mục 2.4: thành công / 401 / lỗi máy chủ / lỗi mạng.
 */
public final class GoiApi {
    private static final Gson GSON = new Gson();

    private GoiApi() { }

    /**
     * @param coi401LaHetPhien true với API cần đăng nhập. Với API đăng nhập thì 401 nghĩa là
     *                         sai email/mật khẩu nên chỉ hiển thị thông điệp lỗi.
     */
    public static <T> void goi(Context ctx, Call<T> call, boolean coi401LaHetPhien, KetQuaApi<T> kq) {
        Context app = ctx.getApplicationContext();
        call.enqueue(new Callback<T>() {
            @Override
            public void onResponse(@NonNull Call<T> c, @NonNull Response<T> res) {
                if (res.isSuccessful() && res.body() != null) {
                    kq.thanhCong(res.body());
                } else if (res.code() == 401 && coi401LaHetPhien) {
                    TokenStore.xoa(app);
                    kq.hetPhien();
                } else {
                    String json = docBody(res);
                    String thongDiep = thongDiepTuJson(json);
                    if (thongDiep == null) thongDiep = app.getString(R.string.loi_may_chu, res.code());
                    Map<String, String> theoTruong = res.code() == 400 ? loiTheoTruong(json) : null;
                    if (theoTruong != null && !theoTruong.isEmpty()) kq.loiDuLieu(thongDiep, theoTruong);
                    else kq.loi(thongDiep);
                }
            }

            @Override
            public void onFailure(@NonNull Call<T> c, @NonNull Throwable t) {
                if (c.isCanceled()) return;
                Log.w(AppConfig.TAG, "Gọi API thất bại: " + c.request().url(), t);
                kq.loi(app.getString(R.string.loi_mang));
            }
        });
    }

    /** Đọc body lỗi (chỉ đọc được một lần); không đọc được thì trả null. */
    private static String docBody(Response<?> res) {
        try (okhttp3.ResponseBody body = res.errorBody()) {
            return body == null ? null : body.string();
        } catch (Exception e) {
            return null;
        }
    }

    /**
     * Danh sách có phân trang chỉ cần phần duLieu: bọc callback để repository trả List cho màn hình.
     * Lỗi theo ô (400) vẫn được chuyển tiếp nguyên vẹn.
     */
    static <T> KetQuaApi<DanhSach<T>> chiLayDuLieu(KetQuaApi<List<T>> kq) {
        return new KetQuaApi<DanhSach<T>>() {
            @Override
            public void thanhCong(DanhSach<T> duLieu) {
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

            @Override
            public void loiDuLieu(String thongDiep, Map<String, String> loiTheoTruong) {
                kq.loiDuLieu(thongDiep, loiTheoTruong);
            }
        };
    }

    /**
     * Tách chiTiet[] của lỗi 400 thành bảng tên trường -> lời báo, vd {"hanSuDung": "Hạn sử dụng
     * phải sau ngày sản xuất."}. Trả bảng rỗng nếu không có hoặc JSON sai dạng.
     */
    public static Map<String, String> loiTheoTruong(String json) {
        Map<String, String> kq = new LinkedHashMap<>();
        if (json == null) return kq;
        try {
            LoiApi loi = GSON.fromJson(json, LoiApi.class);
            if (loi == null || loi.loi == null || loi.loi.chiTiet == null) return kq;
            for (LoiApi.ChiTiet ct : loi.loi.chiTiet) {
                if (ct != null && ct.truong != null && !kq.containsKey(ct.truong)) kq.put(ct.truong, ct.thongDiep);
            }
        } catch (RuntimeException ignored) {
            // JSON hỏng: coi như không có lỗi theo ô
        }
        return kq;
    }

    /** Tách thongDiep từ chuỗi JSON lỗi của backend; trả null nếu sai dạng. */
    public static String thongDiepTuJson(String json) {
        if (json == null) return null;
        try {
            LoiApi loi = GSON.fromJson(json, LoiApi.class);
            if (loi != null && loi.loi != null && loi.loi.thongDiep != null && !loi.loi.thongDiep.isEmpty()) {
                return loi.loi.thongDiep;
            }
        } catch (RuntimeException ignored) {
            // JSON hỏng hoặc không phải JSON (vd trang lỗi HTML của proxy).
        }
        return null;
    }
}
