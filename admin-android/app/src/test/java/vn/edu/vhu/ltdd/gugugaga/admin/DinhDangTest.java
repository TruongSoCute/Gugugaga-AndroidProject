package vn.edu.vhu.ltdd.gugugaga.admin;

import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertNull;

import org.junit.Test;

import vn.edu.vhu.ltdd.gugugaga.admin.data.GoiApi;
import vn.edu.vhu.ltdd.gugugaga.admin.model.YeuCauDuyet;
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
}
