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
import java.util.List;
import java.util.Map;

import vn.edu.vhu.ltdd.gugugaga.admin.data.ApiService;
import vn.edu.vhu.ltdd.gugugaga.admin.data.GoiApi;
import vn.edu.vhu.ltdd.gugugaga.admin.model.BaoCaoDoanhSo;
import vn.edu.vhu.ltdd.gugugaga.admin.model.BuocTruyXuat;
import vn.edu.vhu.ltdd.gugugaga.admin.model.DanhSach;
import vn.edu.vhu.ltdd.gugugaga.admin.model.DonHang;
import vn.edu.vhu.ltdd.gugugaga.admin.model.KetQuaDangNhap;
import vn.edu.vhu.ltdd.gugugaga.admin.model.LoSanXuat;
import vn.edu.vhu.ltdd.gugugaga.admin.model.NhaCungCap;
import vn.edu.vhu.ltdd.gugugaga.admin.model.PhanAnh;
import vn.edu.vhu.ltdd.gugugaga.admin.model.SanPham;
import vn.edu.vhu.ltdd.gugugaga.admin.model.YeuCauDangNhap;
import vn.edu.vhu.ltdd.gugugaga.admin.model.YeuCauDoiTrangThai;
import vn.edu.vhu.ltdd.gugugaga.admin.model.YeuCauDuyet;
import vn.edu.vhu.ltdd.gugugaga.admin.model.YeuCauTaoLo;
import vn.edu.vhu.ltdd.gugugaga.admin.model.YeuCauThemBuoc;
import vn.edu.vhu.ltdd.gugugaga.admin.model.YeuCauXuLyPhanAnh;
import vn.edu.vhu.ltdd.gugugaga.admin.util.DinhDang;
import vn.edu.vhu.ltdd.gugugaga.admin.util.PhanQuyen;
import vn.edu.vhu.ltdd.gugugaga.admin.util.QuyTacTrangThai;

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

    // ---- Vai trò đăng nhập ----

    @Test
    public void khachVaNhaCungCapBiAppTuChoi() throws IOException {
        for (String email : new String[]{"khach1@ocop.example", "ncc1@ocop.example"}) {
            KetQuaDangNhap kq = api(null).dangNhap(new YeuCauDangNhap(email, "Demo@12345")).execute().body();
            assertNotNull(kq);
            assertFalse(email, PhanQuyen.duocDungAppAdmin(kq.nguoiDung.vaiTro));
        }
        String vaiTroNv = api(null).dangNhap(new YeuCauDangNhap("nhanvien@ocop.example", "Demo@12345"))
                .execute().body().nguoiDung.vaiTro;
        assertTrue(PhanQuyen.duocDungAppAdmin(vaiTroNv));
    }

    // ---- Đơn hàng ----

    @Test
    public void donHang_danhSachVaChiTietDocDuocModel() throws IOException {
        ApiService nv = api(dangNhap("nhanvien@ocop.example"));
        DanhSach<DonHang> ds = nv.dsDonHangQuanTri(null, 1, 100).execute().body();
        assertNotNull(ds);
        assertFalse(ds.duLieu.isEmpty());
        DonHang dau = ds.duLieu.get(0);
        assertTrue(dau.id > 0);
        assertTrue(dau.tongTien > 0);
        assertNotNull(dau.trangThai);
        assertNotNull(dau.tenSanPhamDau);

        DonHang ct = nv.chiTietDonHang(dau.id).execute().body();
        assertNotNull(ct);
        assertNotNull(ct.tenNguoiNhan);
        assertNotNull(ct.diaChiGiao);
        assertEquals(ct.tienHang + ct.phiGiao, ct.tongTien);
        assertFalse(ct.chiTiet.isEmpty());
        for (DonHang.DongDon d : ct.chiTiet) {
            assertEquals(20, d.maTruyXuat.length()); // mỗi dòng gắn đúng một lô đã giao
            assertEquals(d.soLuong * d.donGia, d.thanhTien);
        }
        assertFalse(ct.lichSu.isEmpty());
        assertNotNull(ct.lichSu.get(0).thoiDiem);
    }

    @Test
    public void donHang_locTheoTrangThai() throws IOException {
        DanhSach<DonHang> ds = api(dangNhap("nhanvien@ocop.example"))
                .dsDonHangQuanTri(QuyTacTrangThai.DON_DA_HUY, 1, 100).execute().body();
        assertNotNull(ds);
        for (DonHang d : ds.duLieu) assertEquals(QuyTacTrangThai.DON_DA_HUY, d.trangThai);
    }

    @Test
    public void donHang_huyKhongLyDoBi400_nhayCocBi409() throws IOException {
        ApiService nv = api(dangNhap("nhanvien@ocop.example"));
        List<DonHang> cho = nv.dsDonHangQuanTri(QuyTacTrangThai.DON_CHO_XAC_NHAN, 1, 100).execute().body().duLieu;
        assumeTrue("Không còn đơn CHO_XAC_NHAN (cần db:reset)", !cho.isEmpty());
        int id = cho.get(0).id;

        Response<DonHang> thieuLyDo = nv.doiTrangThaiDon(id, new YeuCauDoiTrangThai("DA_HUY", null)).execute();
        assertEquals(400, thieuLyDo.code());
        assertTrue(GoiApi.loiTheoTruong(thieuLyDo.errorBody().string()).containsKey("ghiChu"));

        Response<DonHang> nhayCoc = nv.doiTrangThaiDon(id, new YeuCauDoiTrangThai("DA_GIAO", null)).execute();
        assertEquals(409, nhayCoc.code());
    }

    @Test
    public void donHang_buocHopLeTheoQuyTacCuaAppThanhCong() throws IOException {
        ApiService nv = api(dangNhap("nhanvien@ocop.example"));
        List<DonHang> cho = nv.dsDonHangQuanTri(QuyTacTrangThai.DON_DA_XAC_NHAN, 1, 100).execute().body().duLieu;
        assumeTrue("Không còn đơn DA_XAC_NHAN (cần db:reset)", !cho.isEmpty());
        DonHang don = cho.get(0);
        // Nút đầu tiên app hiện cho đơn DA_XAC_NHAN là DANG_GIAO: backend phải chấp nhận.
        String buoc = QuyTacTrangThai.buocTiepDonHang(don.trangThai).get(0);
        Response<DonHang> r = nv.doiTrangThaiDon(don.id, new YeuCauDoiTrangThai(buoc, null)).execute();
        assertEquals(200, r.code());
        assertEquals(buoc, r.body().trangThai);
        assertEquals(buoc, r.body().lichSu.get(r.body().lichSu.size() - 1).trangThai);
    }

    // ---- Nhà cung cấp ----

    @Test
    public void nhaCungCap_danhSachCoCoTuGui_chiTietCoChungNhan() throws IOException {
        ApiService nv = api(dangNhap("nhanvien@ocop.example"));
        DanhSach<NhaCungCap> ds = nv.dsNhaCungCapQuanTri(null, 1, 100).execute().body();
        assertNotNull(ds);
        boolean coTuGui = false;
        for (NhaCungCap n : ds.duLieu) {
            assertNotNull(n.ten);
            assertNotNull(n.trangThaiDuyet);
            coTuGui |= n.tuGui;
        }
        assertTrue("seed có hồ sơ do nhà cung cấp tự gửi", coTuGui);

        NhaCungCap ct = nv.chiTietNhaCungCap(1).execute().body();
        assertNotNull(ct);
        assertNotNull(ct.anhCoSoUrl);
        assertFalse(ct.chungNhan.isEmpty());
        assertNotNull(ct.chungNhan.get(0).soHieu);
        assertNotNull(ct.nguoiDuyet);
    }

    @Test
    public void nhaCungCap_nhanVienDuyetBi403_duyetLaiBi409() throws IOException {
        Response<NhaCungCap> nv = api(dangNhap("nhanvien@ocop.example"))
                .duyetNhaCungCap(11, YeuCauDuyet.duyetHoSo()).execute();
        assertEquals(403, nv.code());
        // Hồ sơ 1 đã duyệt: duyệt lần nữa bị 409, dữ liệu không đổi.
        Response<NhaCungCap> qt = api(dangNhap("quantri@ocop.example"))
                .duyetNhaCungCap(1, YeuCauDuyet.duyetHoSo()).execute();
        assertEquals(409, qt.code());
        assertNotNull(GoiApi.thongDiepTuJson(qt.errorBody().string()));
    }

    // ---- Lô và QR ----

    @Test
    public void lo_danhSachVaChiTietCoDuongDanQr() throws IOException {
        ApiService nv = api(dangNhap("nhanvien@ocop.example"));
        DanhSach<LoSanXuat> ds = nv.dsLo(1, 100).execute().body();
        assertNotNull(ds);
        assertFalse(ds.duLieu.isEmpty());
        LoSanXuat dau = ds.duLieu.get(0);
        assertEquals(20, dau.maTruyXuat.length());
        assertNotNull(dau.tenSanPham);

        LoSanXuat ct = nv.chiTietLo(dau.id).execute().body();
        assertNotNull(ct);
        assertTrue(ct.duongDanTruyXuat.endsWith("/truy-xuat/" + ct.maTruyXuat));
        assertEquals(dau.soBuoc, ct.cacBuoc.size());
    }

    @Test
    public void lo_taoLoRoiThemBuoc_thoiDiemCoMuiGioDuocChapNhan() throws IOException {
        ApiService nv = api(dangNhap("nhanvien@ocop.example"));
        Response<LoSanXuat> tao = nv.taoLo(new YeuCauTaoLo(1, "2026-10-01", "2027-10-01", 50,
                "Tổ kiểm thử app Admin", null, null)).execute();
        assertEquals(201, tao.code());
        LoSanXuat lo = tao.body();
        assertEquals(20, lo.maTruyXuat.length()); // server sinh mã
        assertNotNull(lo.duongDanTruyXuat);

        Response<BuocTruyXuat> buoc = nv.themBuoc(lo.id, new YeuCauThemBuoc("Thu hoạch",
                DinhDang.thoiDiemIso(2026, 9, 30, 7, 0), "Kiểm thử", null)).execute();
        assertEquals(201, buoc.code());
        assertEquals(1, buoc.body().thuTu);
        assertEquals("2026-09-30T00:00:00.000Z", buoc.body().thoiDiem); // 07:00 +07:00 = 00:00 UTC
    }

    @Test
    public void lo_hanTruocNgaySanXuatBi400DungO() throws IOException {
        Response<LoSanXuat> r = api(dangNhap("nhanvien@ocop.example")).taoLo(new YeuCauTaoLo(1,
                "2026-10-01", "2026-09-01", 50, "Tổ A", null, null)).execute();
        assertEquals(400, r.code());
        Map<String, String> loi = GoiApi.loiTheoTruong(r.errorBody().string());
        assertTrue(loi.containsKey("hanSuDung"));
    }

    // ---- Phản ánh ----

    @Test
    public void phanAnh_danhSachVaChiTiet() throws IOException {
        ApiService nv = api(dangNhap("nhanvien@ocop.example"));
        DanhSach<PhanAnh> ds = nv.dsPhanAnh(null, 1, 100).execute().body();
        assertNotNull(ds);
        assertFalse(ds.duLieu.isEmpty());
        PhanAnh dau = ds.duLieu.get(0);
        assertNotNull(dau.tenSanPham);
        assertNotNull(dau.loai);
        PhanAnh ct = nv.chiTietPhanAnh(dau.id).execute().body();
        assertNotNull(ct);
        assertNotNull(ct.emailNguoiBao);

        for (PhanAnh p : nv.dsPhanAnh(QuyTacTrangThai.PA_MOI, 1, 100).execute().body().duLieu) {
            assertEquals(QuyTacTrangThai.PA_MOI, p.trangThai);
        }
    }

    @Test
    public void phanAnh_ketThucKhongGhiKetQuaBi400() throws IOException {
        ApiService nv = api(dangNhap("nhanvien@ocop.example"));
        List<PhanAnh> moi = nv.dsPhanAnh(QuyTacTrangThai.PA_MOI, 1, 100).execute().body().duLieu;
        assumeTrue("Không còn phản ánh MOI", !moi.isEmpty());
        Response<PhanAnh> r = nv.xuLyPhanAnh(moi.get(0).id,
                new YeuCauXuLyPhanAnh(QuyTacTrangThai.PA_DA_XU_LY, null)).execute();
        assertEquals(400, r.code());
        assertTrue(GoiApi.loiTheoTruong(r.errorBody().string()).containsKey("ketQuaXuLy"));
    }

    @Test
    public void phanAnh_daKetThucKhongQuayLaiDuoc() throws IOException {
        ApiService nv = api(dangNhap("nhanvien@ocop.example"));
        List<PhanAnh> xong = nv.dsPhanAnh(QuyTacTrangThai.PA_DA_XU_LY, 1, 100).execute().body().duLieu;
        assumeTrue(!xong.isEmpty());
        assertTrue(QuyTacTrangThai.buocTiepPhanAnh(QuyTacTrangThai.PA_DA_XU_LY).isEmpty());
        Response<PhanAnh> r = nv.xuLyPhanAnh(xong.get(0).id,
                new YeuCauXuLyPhanAnh(QuyTacTrangThai.PA_DANG_XU_LY, null)).execute();
        assertEquals(409, r.code());
    }

    // ---- Báo cáo doanh số ----

    @Test
    public void baoCao_chiQuanTriXemDuoc() throws IOException {
        assertEquals(403, api(dangNhap("nhanvien@ocop.example")).baoCaoDoanhSo(null, null).execute().code());

        BaoCaoDoanhSo bc = api(dangNhap("quantri@ocop.example")).baoCaoDoanhSo(null, null).execute().body();
        assertNotNull(bc);
        assertTrue(bc.tong.doanhSo > 0);
        assertEquals(3, bc.theoHangSao.size()); // luôn đủ 3, 4, 5 sao
        assertFalse(bc.theoVung.isEmpty());
        assertTrue(bc.nhaCungCapBanChay.size() <= 5);
        long cong = 0;
        for (BaoCaoDoanhSo.TheoVung v : bc.theoVung) cong += v.doanhSo;
        assertEquals(bc.tong.doanhSo, cong);
    }

    @Test
    public void baoCao_tuSauDenBi400() throws IOException {
        Response<BaoCaoDoanhSo> r = api(dangNhap("quantri@ocop.example"))
                .baoCaoDoanhSo("2026-12-31", "2026-01-01").execute();
        assertEquals(400, r.code());
    }
}
