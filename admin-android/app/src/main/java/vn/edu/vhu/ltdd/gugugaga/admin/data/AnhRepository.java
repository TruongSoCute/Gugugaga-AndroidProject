package vn.edu.vhu.ltdd.gugugaga.admin.data;

import android.content.Context;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.os.Handler;
import android.os.Looper;
import android.util.Log;
import android.util.LruCache;

import androidx.annotation.NonNull;

import java.io.IOException;

import vn.edu.vhu.ltdd.gugugaga.admin.AppConfig;
import vn.edu.vhu.ltdd.gugugaga.admin.R;

import okhttp3.Call;
import okhttp3.Callback;
import okhttp3.Request;
import okhttp3.Response;
import okhttp3.ResponseBody;

/**
 * Tải ảnh từ URL (ảnh cơ sở, chứng nhận, ảnh hiện trường, ảnh phản ánh) bằng enqueue của OkHttp,
 * giải mã thu nhỏ rồi trả Bitmap về main thread. Có bộ nhớ đệm nhỏ để cuộn/xoay không tải lại.
 */
public class AnhRepository {
    /** Cạnh dài nhất sau khi thu nhỏ: đủ nét cho màn hình điện thoại, không tốn bộ nhớ. */
    private static final int CANH_TOI_DA = 1024;
    private static final LruCache<String, Bitmap> DEM = new LruCache<String, Bitmap>(8 * 1024 * 1024) {
        @Override
        protected int sizeOf(String key, Bitmap value) {
            return value.getByteCount();
        }
    };

    private final Context app;
    private final Handler mainThread = new Handler(Looper.getMainLooper());

    public AnhRepository(Context ctx) {
        this.app = ctx.getApplicationContext();
    }

    public void tai(String url, KetQuaApi<Bitmap> kq) {
        Bitmap daCo = DEM.get(url);
        if (daCo != null) {
            kq.thanhCong(daCo);
            return;
        }
        Request req;
        try {
            req = new Request.Builder().url(url).build();
        } catch (IllegalArgumentException e) { // URL sai dạng
            kq.loi(app.getString(R.string.loi_tai_anh));
            return;
        }
        ApiClient.httpAnh().newCall(req).enqueue(new Callback() {
            @Override
            public void onResponse(@NonNull Call call, @NonNull Response res) {
                Bitmap bmp = null;
                try (ResponseBody body = res.body()) {
                    if (res.isSuccessful() && body != null) bmp = giaiMa(body.bytes());
                } catch (IOException e) {
                    Log.w(AppConfig.TAG, "Đọc ảnh thất bại: " + url, e);
                }
                Bitmap kqAnh = bmp;
                mainThread.post(() -> {
                    if (kqAnh == null) {
                        kq.loi(app.getString(R.string.loi_tai_anh));
                    } else {
                        DEM.put(url, kqAnh);
                        kq.thanhCong(kqAnh);
                    }
                });
            }

            @Override
            public void onFailure(@NonNull Call call, @NonNull IOException e) {
                Log.w(AppConfig.TAG, "Tải ảnh thất bại: " + url, e);
                mainThread.post(() -> kq.loi(app.getString(R.string.loi_tai_anh)));
            }
        });
    }

    /** Đọc kích thước trước, rồi giải mã với inSampleSize để không hết bộ nhớ với ảnh lớn. */
    private static Bitmap giaiMa(byte[] du) {
        BitmapFactory.Options o = new BitmapFactory.Options();
        o.inJustDecodeBounds = true;
        BitmapFactory.decodeByteArray(du, 0, du.length, o);
        int mau = 1;
        while (Math.max(o.outWidth, o.outHeight) / mau > CANH_TOI_DA) mau *= 2;
        o.inJustDecodeBounds = false;
        o.inSampleSize = mau;
        return BitmapFactory.decodeByteArray(du, 0, du.length, o);
    }
}
