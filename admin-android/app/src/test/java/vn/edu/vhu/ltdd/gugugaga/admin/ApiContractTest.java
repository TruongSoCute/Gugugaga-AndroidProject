package vn.edu.vhu.ltdd.gugugaga.admin;

import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertFalse;
import static org.junit.Assert.assertNotNull;
import static org.junit.Assert.assertNull;
import static org.junit.Assert.assertTrue;
import static org.junit.Assume.assumeTrue;

import org.junit.Before;
import org.junit.Test;

import java.io.IOException;

import vn.edu.vhu.ltdd.gugugaga.admin.data.ApiService;
import vn.edu.vhu.ltdd.gugugaga.admin.data.GoiApi;
import vn.edu.vhu.ltdd.gugugaga.admin.model.DanhSach;
import vn.edu.vhu.ltdd.gugugaga.admin.model.KetQuaDangNhap;
import vn.edu.vhu.ltdd.gugugaga.admin.model.SanPham;
import vn.edu.vhu.ltdd.gugugaga.admin.model.YeuCauDangNhap;
import vn.edu.vhu.ltdd.gugugaga.admin.model.YeuCauDuyet;

import okhttp3.OkHttpClient;
import retrofit2.Response;
import retrofit2.Retrofit;
import retrofit2.converter.gson.GsonConverterFactory;

/**
 * Kiểm thử hợp đồng API với backend THẬT: ApiService và các lớp model của app có đọc/ghi
 * đúng JSON của backend không. Chỉ chạy khi có biến môi trường OCOP_API_TEST_URL
 * (vd http://localhost:3000/) trỏ tới backend vừa chạy db:reset; nếu không thì bỏ qua.
 */
public class ApiContractTest {
    private String baseUrl;

    @Before
    public void setUp() {
        baseUrl = System.getenv("OCOP_API_TEST_URL");
        assumeTrue("Bỏ qua: chưa đặt OCOP_API_TEST_URL", baseUrl != null && !baseUrl.isEmpty());
    }

    private ApiService api(String token) {
        OkHttpClient http = new OkHttpClient.Builder().addInterceptor(chain -> chain.proceed(
                token == null ? chain.request()
                        : chain.request().newBuilder().addHeader("Authorization", "Bearer " + token).build()))
                .build();
        return new Retrofit.Builder().baseUrl(baseUrl).client(http)
                .addConverterFactory(GsonConverterFactory.create()).build().create(ApiService.class);
    }

    private String dangNhap(String email) throws IOException {
        Response<KetQuaDangNhap> r = api(null).dangNhap(new YeuCauDangNhap(email, "Demo@12345")).execute();
        assertTrue(r.isSuccessful());
        return r.body().token;
    }

    @Test
    public void dangNhapDocDungVaiTro() throws IOException {
        KetQuaDangNhap kq = api(null).dangNhap(new YeuCauDangNhap("quantri@ocop.example", "Demo@12345")).execute().body();
        assertNotNull(kq.token);
        assertEquals(AppConfig.VAI_TRO_QUAN_TRI, kq.nguoiDung.vaiTro);
        assertEquals("quantri@ocop.example", kq.nguoiDung.email);
    }

    @Test
    public void saiMatKhauTra401KemThongDiep() throws IOException {
        Response<KetQuaDangNhap> r = api(null).dangNhap(new YeuCauDangNhap("quantri@ocop.example", "sai-mat-khau")).execute();
        assertEquals(401, r.code());
        assertEquals("Email hoặc mật khẩu không đúng.", GoiApi.thongDiepTuJson(r.errorBody().string()));
    }

    @Test
    public void danhSachChoDuyetDocDuocModel() throws IOException {
        DanhSach<SanPham> ds = api(dangNhap("nhanvien@ocop.example"))
                .dsSanPhamQuanTri(AppConfig.TRANG_THAI_CHO_DUYET, 1, 100).execute().body();
        assertNotNull(ds);
        assertFalse(ds.duLieu.isEmpty());
        for (SanPham sp : ds.duLieu) {
            assertEquals(AppConfig.TRANG_THAI_CHO_DUYET, sp.trangThaiDuyet);
            assertNotNull(sp.ten);
            assertNotNull(sp.tenNhaCungCap);
            assertTrue(sp.gia > 0);
            assertNull(sp.hangSao);
        }
        assertEquals(ds.duLieu.size(), ds.phanTrang.tong);
    }

    @Test
    public void nhanVienKhongDuocDuyet_quanTriDuyetDuoc() throws IOException {
        // Sản phẩm 45 (seed) đang chờ duyệt và thuộc nhà cung cấp đã duyệt.
        Response<SanPham> nv = api(dangNhap("nhanvien@ocop.example")).duyetSanPham(45, YeuCauDuyet.duyet(4)).execute();
        assertEquals(403, nv.code());

        Response<SanPham> qt = api(dangNhap("quantri@ocop.example")).duyetSanPham(45, YeuCauDuyet.duyet(4)).execute();
        assertEquals(200, qt.code());
        assertEquals(AppConfig.TRANG_THAI_DA_DUYET, qt.body().trangThaiDuyet);
        assertEquals(Integer.valueOf(4), qt.body().hangSao);
    }

    @Test
    public void tokenGiaTra401() throws IOException {
        assertEquals(401, api("token-gia").dsSanPhamQuanTri(null, 1, 10).execute().code());
    }
}
