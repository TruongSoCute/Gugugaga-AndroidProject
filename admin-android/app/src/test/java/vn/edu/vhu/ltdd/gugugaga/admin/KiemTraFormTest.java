package vn.edu.vhu.ltdd.gugugaga.admin;

import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertFalse;
import static org.junit.Assert.assertNull;
import static org.junit.Assert.assertTrue;

import org.junit.Test;

import vn.edu.vhu.ltdd.gugugaga.admin.util.KiemTraForm;
import vn.edu.vhu.ltdd.gugugaga.admin.util.KiemTraForm.Loi;

/** Bốn lớp kiểm tra của form tạo lô (Lab A4), gồm các trường hợp "ác". */
public class KiemTraFormTest {

    @Test
    public void soLuong_hopLe() {
        assertNull(KiemTraForm.soNguyen("120", 1, 10_000_000));
        assertNull(KiemTraForm.soNguyen("  42 ", 1, 10_000_000)); // có khoảng trắng hai đầu
        assertNull(KiemTraForm.soNguyen("10000000", 1, 10_000_000));
    }

    @Test
    public void soLuong_rong() {
        assertEquals(Loi.TRONG, KiemTraForm.soNguyen("", 1, 100));
        assertEquals(Loi.TRONG, KiemTraForm.soNguyen("   ", 1, 100));
        assertEquals(Loi.TRONG, KiemTraForm.soNguyen(null, 1, 100));
    }

    @Test
    public void soLuong_saiDinhDang() {
        assertEquals(Loi.SAI_DINH_DANG, KiemTraForm.soNguyen("abc", 1, 100));
        assertEquals(Loi.SAI_DINH_DANG, KiemTraForm.soNguyen("1.5", 1, 100));
        assertEquals(Loi.SAI_DINH_DANG, KiemTraForm.soNguyen("1.000.000", 1, 100)); // nhiều dấu chấm
        assertEquals(Loi.SAI_DINH_DANG, KiemTraForm.soNguyen("99999999999999999999", 1, 100)); // tràn long
    }

    @Test
    public void soLuong_ngoaiMien() {
        assertEquals(Loi.NGOAI_MIEN, KiemTraForm.soNguyen("0", 1, 100));
        assertEquals(Loi.NGOAI_MIEN, KiemTraForm.soNguyen("-3", 1, 100));
        assertEquals(Loi.NGOAI_MIEN, KiemTraForm.soNguyen("10000001", 1, 10_000_000));
        assertEquals(Loi.NGOAI_MIEN, KiemTraForm.soNguyen("9999999999", 1, 10_000_000)); // lớn hơn int
    }

    @Test
    public void urlAnh() {
        assertTrue(KiemTraForm.laUrlWeb("https://picsum.photos/seed/x/800/500"));
        assertTrue(KiemTraForm.laUrlWeb("http://10.0.2.2:3000/a.png"));
        assertFalse(KiemTraForm.laUrlWeb("ftp://x"));
        assertFalse(KiemTraForm.laUrlWeb("https://"));
        assertFalse(KiemTraForm.laUrlWeb("https://a b.vn"));
        assertFalse(KiemTraForm.laUrlWeb("anh.jpg"));
        assertFalse(KiemTraForm.laUrlWeb(""));
        assertFalse(KiemTraForm.laUrlWeb(null));
    }

    @Test
    public void hanSuDungPhaiSauNgaySanXuat() {
        assertTrue(KiemTraForm.sauNgay("2027-03-02", "2026-03-02"));
        assertFalse(KiemTraForm.sauNgay("2026-03-02", "2026-03-02")); // bằng nhau cũng sai
        assertFalse(KiemTraForm.sauNgay("2026-03-01", "2026-03-02"));
        assertFalse(KiemTraForm.sauNgay(null, "2026-03-02"));
    }
}
