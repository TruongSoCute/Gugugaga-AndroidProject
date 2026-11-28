package vn.edu.vhu.ltdd.gugugaga.admin;

import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertFalse;
import static org.junit.Assert.assertTrue;

import org.junit.Test;

import java.util.Arrays;
import java.util.Collections;

import vn.edu.vhu.ltdd.gugugaga.admin.util.RolePermissions;
import vn.edu.vhu.ltdd.gugugaga.admin.util.StatusTransitions;

/** Nút nào được hiện ở màn hình đơn hàng, phản ánh, hồ sơ; vai trò nào được dùng app Admin. */
public class StatusTransitionsTest {

    @Test
    public void donHang_chiHienBuocHopLeChoNhanSu() {
        assertEquals(Arrays.asList("DA_XAC_NHAN", "DA_HUY"), StatusTransitions.buocTiepDonHang("CHO_XAC_NHAN"));
        assertEquals(Arrays.asList("DANG_GIAO", "DA_HUY"), StatusTransitions.buocTiepDonHang("DA_XAC_NHAN"));
        assertEquals(Collections.singletonList("DA_GIAO"), StatusTransitions.buocTiepDonHang("DANG_GIAO"));
    }

    @Test
    public void donHang_trangThaiCuoiVaDaNhanKhongCoNut() {
        // DA_NHAN chỉ khách xác nhận; DA_GIAO thì nhân sự đã xong việc; hủy rồi thì không đi tiếp.
        assertTrue(StatusTransitions.buocTiepDonHang("DA_GIAO").isEmpty());
        assertTrue(StatusTransitions.buocTiepDonHang("DA_NHAN").isEmpty());
        assertTrue(StatusTransitions.buocTiepDonHang("DA_HUY").isEmpty());
        assertTrue(StatusTransitions.buocTiepDonHang(null).isEmpty());
        assertTrue(StatusTransitions.buocTiepDonHang("LA").isEmpty());
    }

    @Test
    public void donHang_khongNhayCocKhongQuayLui() {
        assertFalse(StatusTransitions.buocTiepDonHang("CHO_XAC_NHAN").contains("DA_GIAO"));
        assertFalse(StatusTransitions.buocTiepDonHang("DANG_GIAO").contains("DA_HUY"));
        assertFalse(StatusTransitions.buocTiepDonHang("DANG_GIAO").contains("DA_XAC_NHAN"));
    }

    @Test
    public void donHang_chiHuyMoiBatBuocGhiChu() {
        assertTrue(StatusTransitions.donCanGhiChu("DA_HUY"));
        assertFalse(StatusTransitions.donCanGhiChu("DA_XAC_NHAN"));
        assertFalse(StatusTransitions.donCanGhiChu("DANG_GIAO"));
    }

    @Test
    public void phanAnh_chiDiToi() {
        assertEquals(Arrays.asList("DANG_XU_LY", "DA_XU_LY", "BAC_BO"), StatusTransitions.buocTiepPhanAnh("MOI"));
        assertEquals(Arrays.asList("DA_XU_LY", "BAC_BO"), StatusTransitions.buocTiepPhanAnh("DANG_XU_LY"));
        assertTrue(StatusTransitions.buocTiepPhanAnh("DA_XU_LY").isEmpty());
        assertTrue(StatusTransitions.buocTiepPhanAnh("BAC_BO").isEmpty());
    }

    @Test
    public void phanAnh_ketThucBatBuocKetQua() {
        assertTrue(StatusTransitions.phanAnhCanKetQua("DA_XU_LY"));
        assertTrue(StatusTransitions.phanAnhCanKetQua("BAC_BO"));
        assertFalse(StatusTransitions.phanAnhCanKetQua("DANG_XU_LY"));
    }

    @Test
    public void hoSo_nutDuyetVaTuChoiTheoTrangThai() {
        assertTrue(StatusTransitions.coTheDuyetHoSo("CHO_DUYET"));
        assertTrue(StatusTransitions.coTheTuChoiHoSo("CHO_DUYET"));
        assertFalse(StatusTransitions.coTheDuyetHoSo("DA_DUYET"));
        assertTrue(StatusTransitions.coTheTuChoiHoSo("DA_DUYET")); // thu hồi
        assertTrue(StatusTransitions.coTheDuyetHoSo("TU_CHOI")); // duyệt lại
        assertFalse(StatusTransitions.coTheTuChoiHoSo("TU_CHOI"));
    }

    @Test
    public void chiNhanSuDuocDungAppAdmin() {
        assertTrue(RolePermissions.duocDungAppAdmin("QUAN_TRI"));
        assertTrue(RolePermissions.duocDungAppAdmin("NHAN_VIEN"));
        assertFalse(RolePermissions.duocDungAppAdmin("KHACH"));
        assertFalse(RolePermissions.duocDungAppAdmin("NHA_CUNG_CAP"));
        assertFalse(RolePermissions.duocDungAppAdmin(null));
        assertFalse(RolePermissions.duocDungAppAdmin("quan_tri"));
        assertTrue(RolePermissions.laQuanTri("QUAN_TRI"));
        assertFalse(RolePermissions.laQuanTri("NHAN_VIEN"));
    }
}
