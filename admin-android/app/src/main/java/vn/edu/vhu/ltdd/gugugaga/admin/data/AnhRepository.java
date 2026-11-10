package vn.edu.vhu.ltdd.gugugaga.admin.data;

import android.content.Context;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.net.Uri;
import android.os.Handler;
import android.os.Looper;
import android.util.Log;
import android.util.LruCache;

import androidx.annotation.NonNull;

import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.io.InputStream;

import vn.edu.vhu.ltdd.gugugaga.admin.AppConfig;
import vn.edu.vhu.ltdd.gugugaga.admin.R;
import vn.edu.vhu.ltdd.gugugaga.admin.model.KetQuaTaiAnh;

import okhttp3.Call;
import okhttp3.Callback;
import okhttp3.MediaType;
import okhttp3.Request;
import okhttp3.RequestBody;
import okhttp3.Response;
import okhttp3.ResponseBody;

/**
 * Tải ảnh từ URL (ảnh cơ sở, chứng nhận, ảnh hiện trường, ảnh phản ánh) bằng enqueue của OkHttp,
 * giải mã thu nhỏ rồi trả Bitmap về main thread. Có bộ nhớ đệm nhỏ để cuộn/xoay không tải lại.
 */
public class AnhRepository {
    /** Cạnh dài nhất sau khi thu nhỏ: đủ nét cho màn hình điện thoại, không tốn bộ nhớ. */
    private static final int CANH_TOI_DA = 1024;
    private static final int KICH_THUOC_TOI_DA = 5 * 1024 * 1024;
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

    public void taiLen(Uri uri, String mucDich, KetQuaApi<String> kq) {
        new Thread(() -> {
            byte[] duLieu;
            try {
                duLieu = docGioiHan(uri, KICH_THUOC_TOI_DA);
            } catch (IOException e) {
                Log.w(AppConfig.TAG, "Đọc ảnh từ máy thất bại: " + uri, e);
                mainThread.post(() -> kq.loi(app.getString(R.string.loi_doc_anh_tu_may)));
                return;
            }
            if (duLieu == null) {
                mainThread.post(() -> kq.loi(app.getString(R.string.loi_anh_qua_lon)));
                return;
            }
            if (duLieu.length == 0) {
                mainThread.post(() -> kq.loi(app.getString(R.string.loi_doc_anh_tu_may)));
                return;
            }
            Bitmap xemTruoc = giaiMa(duLieu);
            String loai = loaiMime(uri, duLieu);
            Bitmap bmpDem = xemTruoc;
            RequestBody body = RequestBody.create(duLieu, MediaType.parse(loai));
            GoiApi.goi(app, ApiClient.get(app).taiLenAnh(mucDich, body), true, new KetQuaApi<KetQuaTaiAnh>() {
                @Override
                public void thanhCong(KetQuaTaiAnh phanHoi) {
                    if (phanHoi == null || phanHoi.url == null || phanHoi.url.isEmpty()) {
                        kq.loi(app.getString(R.string.loi_tai_len_anh));
                        return;
                    }
                    if (bmpDem != null) DEM.put(phanHoi.url, bmpDem);
                    kq.thanhCong(phanHoi.url);
                }

                @Override
                public void loi(String thongDiep) {
                    kq.loi(thongDiep);
                }

                @Override
                public void hetPhien() {
                    kq.hetPhien();
                }
            });
        }).start();
    }

    /** Đọc tối đa gioiHan byte; nếu tệp dài hơn gioiHan thì dừng ngay và trả null để không tràn bộ nhớ. */
    private byte[] docGioiHan(Uri uri, int gioiHan) throws IOException {
        try (InputStream in = app.getContentResolver().openInputStream(uri)) {
            if (in == null) return new byte[0];
            ByteArrayOutputStream out = new ByteArrayOutputStream();
            byte[] dem = new byte[8192];
            int tong = 0;
            int doc;
            while ((doc = in.read(dem)) != -1) {
                tong += doc;
                if (tong > gioiHan) return null;
                out.write(dem, 0, doc);
            }
            return out.toByteArray();
        }
    }

    private String loaiMime(Uri uri, byte[] du) {
        if (du.length >= 12) {
            if ((du[0] & 0xFF) == 0x89 && du[1] == 0x50 && du[2] == 0x4E && du[3] == 0x47) return "image/png";
            if (du[0] == 'R' && du[1] == 'I' && du[2] == 'F' && du[3] == 'F'
                    && du[8] == 'W' && du[9] == 'E' && du[10] == 'B' && du[11] == 'P') return "image/webp";
            if ((du[0] & 0xFF) == 0xFF && (du[1] & 0xFF) == 0xD8 && (du[2] & 0xFF) == 0xFF) return "image/jpeg";
        }
        String mime = app.getContentResolver().getType(uri);
        if ("image/png".equals(mime) || "image/webp".equals(mime) || "image/jpeg".equals(mime)) return mime;
        return "image/jpeg";
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
