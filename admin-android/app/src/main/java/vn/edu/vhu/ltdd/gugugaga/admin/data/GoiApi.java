package vn.edu.vhu.ltdd.gugugaga.admin.data;

import android.content.Context;
import android.util.Log;

import androidx.annotation.NonNull;

import com.google.gson.Gson;

import vn.edu.vhu.ltdd.gugugaga.admin.AppConfig;
import vn.edu.vhu.ltdd.gugugaga.admin.R;
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
                    kq.loi(thongDiepLoi(app, res));
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

    /** Lấy loi.thongDiep do backend gửi; nếu không đọc được thì báo mã HTTP. */
    static String thongDiepLoi(Context app, Response<?> res) {
        String tuBackend = docThongDiep(res);
        return tuBackend != null ? tuBackend : app.getString(R.string.loi_may_chu, res.code());
    }

    private static String docThongDiep(Response<?> res) {
        try (okhttp3.ResponseBody body = res.errorBody()) {
            return body == null ? null : thongDiepTuJson(body.string());
        } catch (Exception e) {
            return null;
        }
    }

    /** Tách thongDiep từ chuỗi JSON lỗi của backend; trả null nếu sai dạng. */
    public static String thongDiepTuJson(String json) {
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
