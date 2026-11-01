package vn.edu.vhu.ltdd.gugugaga.admin;

import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertNull;
import static org.junit.Assert.assertTrue;

import org.junit.Test;

import java.util.Map;

import vn.edu.vhu.ltdd.gugugaga.admin.data.GoiApi;
import vn.edu.vhu.ltdd.gugugaga.admin.model.BaoCaoDoanhSo;
import vn.edu.vhu.ltdd.gugugaga.admin.model.YeuCauDoiTrangThai;
import vn.edu.vhu.ltdd.gugugaga.admin.model.YeuCauDuyet;
import vn.edu.vhu.ltdd.gugugaga.admin.model.YeuCauTaoLo;
import vn.edu.vhu.ltdd.gugugaga.admin.model.YeuCauXuLyPhanAnh;
import vn.edu.vhu.ltdd.gugugaga.admin.util.DinhDang;

import com.google.gson.Gson;

/** Kiểm thử JVM (không cần máy ảo) cho phần xử lý dữ liệu thuần. */
public class DinhDangTest {

    @Test
    public void dinhDangTien() {
        assertEquals("320.000 đ", DinhDang.tien(320000));
        assertEquals("2.200.000 đ", DinhDang.tien(2200000));
        assertEquals("0 đ", DinhDang.tien(0));
    }

    @Test
    public void docThongDiepLoiCuaBackend() {
        String json = "{\"loi\":{\"ma\":\"NHA_CUNG_CAP_CHUA_DUYET\",\"thongDiep\":\"Cần duyệt nhà cung cấp trước khi duyệt sản phẩm.\"}}";
        assertEquals("Cần duyệt nhà cung cấp trước khi duyệt sản phẩm.", GoiApi.thongDiepTuJson(json));
    }

    @Test
    public void loiKhongPhaiJsonTraNull() {
        assertNull(GoiApi.thongDiepTuJson("<html>502 Bad Gateway</html>"));
        assertNull(GoiApi.thongDiepTuJson("{}"));
        assertNull(GoiApi.thongDiepTuJson(""));
    }

    @Test
    public void bodyDuyetKhongGuiTruongNull() {
        Gson gson = new Gson();
        assertEquals("{\"trangThai\":\"DA_DUYET\",\"hangSao\":4}", gson.toJson(YeuCauDuyet.duyet(4)));
        assertEquals("{\"trangThai\":\"TU_CHOI\",\"lyDo\":\"Thiếu nhãn\"}", gson.toJson(YeuCauDuyet.tuChoi("Thiếu nhãn")));
    }

    @Test
    public void dinhDangNgayVaThoiDiem() {
        assertEquals("02/03/2026", DinhDang.ngay("2026-03-02"));
        assertEquals("", DinhDang.ngay(null));
        assertEquals("khong-phai-ngay", DinhDang.ngay("khong-phai-ngay"));
        // Backend trả UTC; hiển thị giờ Việt Nam (+7).
        assertEquals("27/02/2026 07:00", DinhDang.thoiDiem("2026-02-27T00:00:00.000Z"));
        assertEquals("01/03/2026 06:30", DinhDang.thoiDiem("2026-02-28T23:30:00Z"));
        assertEquals("", DinhDang.thoiDiem(null));
    }

    @Test
    public void thoiDiemGuiLenCoMuiGio() {
        assertEquals("2026-03-02", DinhDang.ngayIso(2026, 3, 2));
        // API.md: thời điểm gửi lên phải có múi giờ, vd 2026-03-01T07:00:00+07:00.
        assertEquals("2026-03-01T07:05:00+07:00", DinhDang.thoiDiemIso(2026, 3, 1, 7, 5));
        assertEquals("01/03/2026 07:05", DinhDang.thoiDiemDaChon("2026-03-01T07:05:00+07:00"));
    }

    @Test
    public void docLoiTheoTungO() {
        String json = "{\"loi\":{\"ma\":\"DU_LIEU_KHONG_HOP_LE\",\"thongDiep\":\"Dữ liệu không hợp lệ.\","
                + "\"chiTiet\":[{\"truong\":\"hanSuDung\",\"thongDiep\":\"Hạn sử dụng phải sau ngày sản xuất.\"},"
                + "{\"truong\":\"soLuong\",\"thongDiep\":\"Phải là số nguyên.\"}]}}";
        Map<String, String> loi = GoiApi.loiTheoTruong(json);
        assertEquals(2, loi.size());
        assertEquals("Hạn sử dụng phải sau ngày sản xuất.", loi.get("hanSuDung"));
        assertTrue(GoiApi.loiTheoTruong("<html></html>").isEmpty());
        assertTrue(GoiApi.loiTheoTruong(null).isEmpty());
    }

    @Test
    public void bodyGuiLenKhongCoTruongNull() {
        Gson gson = new Gson();
        assertEquals("{\"trangThai\":\"DA_XAC_NHAN\"}", gson.toJson(new YeuCauDoiTrangThai("DA_XAC_NHAN", null)));
        assertEquals("{\"trangThai\":\"DA_HUY\",\"ghiChu\":\"Hết hàng\"}",
                gson.toJson(new YeuCauDoiTrangThai("DA_HUY", "Hết hàng")));
        assertEquals("{\"trangThai\":\"DA_DUYET\"}", gson.toJson(YeuCauDuyet.duyetHoSo()));
        assertEquals("{\"trangThai\":\"DANG_XU_LY\"}", gson.toJson(new YeuCauXuLyPhanAnh("DANG_XU_LY", null)));
        // Không bao giờ gửi maTruyXuat: mã do server sinh.
        String lo = gson.toJson(new YeuCauTaoLo(1, "2026-03-02", "2027-03-02", 100, "Tổ A", null, null));
        assertEquals("{\"sanPhamId\":1,\"ngaySanXuat\":\"2026-03-02\",\"hanSuDung\":\"2027-03-02\","
                + "\"soLuong\":100,\"nguoiSanXuat\":\"Tổ A\"}", lo);
    }

    @Test
    public void doanhSoVuotIntVanDocDung() {
        String json = "{\"tong\":{\"doanhSo\":5000000000,\"soLuong\":1,\"soDon\":1},"
                + "\"theoVung\":[],\"theoHangSao\":[],\"nhaCungCapBanChay\":[]}";
        BaoCaoDoanhSo bc = new Gson().fromJson(json, BaoCaoDoanhSo.class);
        assertEquals(5_000_000_000L, bc.tong.doanhSo);
    }
}
