package vn.edu.vhu.ltdd.gugugaga.admin;

import static org.junit.Assert.assertEquals;

import org.junit.Test;

import vn.edu.vhu.ltdd.gugugaga.admin.util.Charts;

/** Phép tính của biểu đồ cột tự vẽ ở màn hình báo cáo. */
public class ChartsTest {
    private static final float SAI_SO = 1e-6f;

    @Test
    public void cotLonNhatDaiHetCo() {
        long[] doanhSo = {13015000L, 4950000L, 1488000L, 690000L, 0L};
        long max = Charts.lonNhat(doanhSo);
        assertEquals(13015000L, max);
        assertEquals(1f, Charts.tiLe(13015000L, max), SAI_SO);
        assertEquals(4950000f / 13015000f, Charts.tiLe(4950000L, max), SAI_SO);
        assertEquals(0f, Charts.tiLe(0L, max), SAI_SO);
    }

    @Test
    public void chuaBanDuocGiThiKhongChiaChoKhong() {
        long[] rong = {0L, 0L, 0L};
        assertEquals(0L, Charts.lonNhat(rong));
        assertEquals(0f, Charts.tiLe(0L, 0L), SAI_SO);
        assertEquals(0L, Charts.lonNhat(new long[0]));
        assertEquals(0L, Charts.lonNhat(null));
    }

    @Test
    public void tiLeLuonTrongDoanKhongMot() {
        assertEquals(1f, Charts.tiLe(200L, 100L), SAI_SO);
        assertEquals(0f, Charts.tiLe(-5L, 100L), SAI_SO);
        // Doanh số vượt giới hạn int vẫn tính đúng nhờ long.
        assertEquals(0.5f, Charts.tiLe(3_000_000_000L, 6_000_000_000L), SAI_SO);
    }

    @Test
    public void rutGonSoTienChoNhanCot() {
        assertEquals("13 tr", Charts.rutGon(13015000L));
        assertEquals("4,9 tr", Charts.rutGon(4950000L));
        assertEquals("690 N", Charts.rutGon(690000L));
        assertEquals("1,4 tr", Charts.rutGon(1488000L));
        assertEquals("2,5 tỷ", Charts.rutGon(2_500_000_000L));
        assertEquals("0", Charts.rutGon(0L));
    }
}
