package vn.edu.vhu.ltdd.gugugaga.admin;

import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertFalse;
import static org.junit.Assert.assertTrue;

import org.junit.Test;

import java.util.Arrays;
import java.util.Collections;

import vn.edu.vhu.ltdd.gugugaga.admin.util.PhanQuyen;
import vn.edu.vhu.ltdd.gugugaga.admin.util.QuyTacTrangThai;

/** Nút nào được hiện ở màn hình đơn hàng, phản ánh, hồ sơ; vai trò nào được dùng app Admin. */
public class QuyTacTrangThaiTest {

    @Test
    public void donHang_chiHienBuocHopLeChoNhanSu() {
        assertEquals(Arrays.asList("DA_XAC_NHAN", "DA_HUY"), QuyTacTrangThai.buocTiepDonHang("CHO_XAC_NHAN"));
        assertEquals(Arrays.asList("DANG_GIAO", "DA_HUY"), QuyTacTrangThai.buocTiepDonHang("DA_XAC_NHAN"));
        assertEquals(Collections.singletonList("DA_GIAO"), QuyTacTrangThai.buocTiepDonHang("DANG_GIAO"));
    }

    @Test
    public void donHang_trangThaiCuoiVaDaNhanKhongCoNut() {
        // DA_NHAN chỉ khách xác nhận; DA_GIAO thì nhân sự đã xong việc; hủy rồi thì không đi tiếp.
        assertTrue(QuyTacTrangThai.buocTiepDonHang("DA_GIAO").isEmpty());
        assertTrue(QuyTacTrangThai.buocTiepDonHang("DA_NHAN").isEmpty());
        assertTrue(QuyTacTrangThai.buocTiepDonHang("DA_HUY").isEmpty());
        assertTrue(QuyTacTrangThai.buocTiepDonHang(null).isEmpty());
        assertTrue(QuyTacTrangThai.buocTiepDonHang("LA").isEmpty());
    }

    @Test
    public void donHang_khongNhayCocKhongQuayLui() {
        assertFalse(QuyTacTrangThai.buocTiepDonHang("CHO_XAC_NHAN").contains("DA_GIAO"));
        assertFalse(QuyTacTrangThai.buocTiepDonHang("DANG_GIAO").contains("DA_HUY"));
        assertFalse(QuyTacTrangThai.buocTiepDonHang("DANG_GIAO").contains("DA_XAC_NHAN"));
    }

    @Test
    public void donHang_chiHuyMoiBatBuocGhiChu() {
        assertTrue(QuyTacTrangThai.donCanGhiChu("DA_HUY"));
        assertFalse(QuyTacTrangThai.donCanGhiChu("DA_XAC_NHAN"));
        assertFalse(QuyTacTrangThai.donCanGhiChu("DANG_GIAO"));
    }

    @Test
    public void phanAnh_chiDiToi() {
        assertEquals(Arrays.asList("DANG_XU_LY", "DA_XU_LY", "BAC_BO"), QuyTacTrangThai.buocTiepPhanAnh("MOI"));
        assertEquals(Arrays.asList("DA_XU_LY", "BAC_BO"), QuyTacTrangThai.buocTiepPhanAnh("DANG_XU_LY"));
        assertTrue(QuyTacTrangThai.buocTiepPhanAnh("DA_XU_LY").isEmpty());
        assertTrue(QuyTacTrangThai.buocTiepPhanAnh("BAC_BO").isEmpty());
    }

    @Test
    public void phanAnh_ketThucBatBuocKetQua() {
        assertTrue(QuyTacTrangThai.phanAnhCanKetQua("DA_XU_LY"));
        assertTrue(QuyTacTrangThai.phanAnhCanKetQua("BAC_BO"));
        assertFalse(QuyTacTrangThai.phanAnhCanKetQua("DANG_XU_LY"));
    }

    @Test
    public void hoSo_nutDuyetVaTuChoiTheoTrangThai() {
        assertTrue(QuyTacTrangThai.coTheDuyetHoSo("CHO_DUYET"));
        assertTrue(QuyTacTrangThai.coTheTuChoiHoSo("CHO_DUYET"));
        assertFalse(QuyTacTrangThai.coTheDuyetHoSo("DA_DUYET"));
        assertTrue(QuyTacTrangThai.coTheTuChoiHoSo("DA_DUYET")); // thu hồi
        assertTrue(QuyTacTrangThai.coTheDuyetHoSo("TU_CHOI")); // duyệt lại
        assertFalse(QuyTacTrangThai.coTheTuChoiHoSo("TU_CHOI"));
    }

    @Test
    public void chiNhanSuDuocDungAppAdmin() {
        assertTrue(PhanQuyen.duocDungAppAdmin("QUAN_TRI"));
        assertTrue(PhanQuyen.duocDungAppAdmin("NHAN_VIEN"));
        assertFalse(PhanQuyen.duocDungAppAdmin("KHACH"));
        assertFalse(PhanQuyen.duocDungAppAdmin("NHA_CUNG_CAP"));
        assertFalse(PhanQuyen.duocDungAppAdmin(null));
        assertFalse(PhanQuyen.duocDungAppAdmin("quan_tri"));
        assertTrue(PhanQuyen.laQuanTri("QUAN_TRI"));
        assertFalse(PhanQuyen.laQuanTri("NHAN_VIEN"));
    }
}
