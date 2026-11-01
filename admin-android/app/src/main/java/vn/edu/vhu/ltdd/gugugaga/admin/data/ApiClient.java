package vn.edu.vhu.ltdd.gugugaga.admin.data;

import android.content.Context;

import java.util.concurrent.TimeUnit;

import vn.edu.vhu.ltdd.gugugaga.admin.AppConfig;
import vn.edu.vhu.ltdd.gugugaga.admin.BuildConfig;

import okhttp3.OkHttpClient;
import okhttp3.Request;
import okhttp3.logging.HttpLoggingInterceptor;
import retrofit2.Retrofit;
import retrofit2.converter.gson.GsonConverterFactory;

/**
 * Tạo Retrofit một lần cho cả app (Phụ lục 2 mục 2.3).
 * - Interceptor tự gắn "Authorization: Bearer <token>" nếu đã đăng nhập.
 * - Timeout 90 giây vì Render gói Free cần tới một phút để thức dậy.
 */
public final class ApiClient {
    private static ApiService service;
    private static OkHttpClient httpAnh;

    private ApiClient() { }

    public static synchronized ApiService get(Context ctx) {
        if (service == null) {
            Context app = ctx.getApplicationContext();
            OkHttpClient.Builder http = new OkHttpClient.Builder()
                    .addInterceptor(chain -> {
                        String token = TokenStore.layToken(app);
                        Request.Builder r = chain.request().newBuilder();
                        if (token != null) r.addHeader("Authorization", "Bearer " + token);
                        return chain.proceed(r.build());
                    })
                    .connectTimeout(90, TimeUnit.SECONDS)
                    .readTimeout(90, TimeUnit.SECONDS);

            if (BuildConfig.DEBUG) {
                // Chỉ ghi log ở bản debug và che token để không lộ trong Logcat.
                HttpLoggingInterceptor log = new HttpLoggingInterceptor(
                        msg -> android.util.Log.d(AppConfig.TAG, msg));
                log.setLevel(HttpLoggingInterceptor.Level.BASIC);
                log.redactHeader("Authorization");
                http.addInterceptor(log);
            }

            service = new Retrofit.Builder()
                    .baseUrl(AppConfig.API_BASE_URL) // phải có dấu / ở cuối
                    .client(http.build())
                    .addConverterFactory(GsonConverterFactory.create())
                    .build()
                    .create(ApiService.class);
        }
        return service;
    }

    /**
     * OkHttp riêng để tải ảnh (ảnh cơ sở, ảnh hiện trường...). Ảnh nằm ở máy chủ khác backend
     * nên client này KHÔNG gắn token, tránh lộ token cho bên thứ ba.
     */
    static synchronized OkHttpClient httpAnh() {
        if (httpAnh == null) {
            httpAnh = new OkHttpClient.Builder()
                    .connectTimeout(30, TimeUnit.SECONDS)
                    .readTimeout(30, TimeUnit.SECONDS)
                    .build();
        }
        return httpAnh;
    }
}
