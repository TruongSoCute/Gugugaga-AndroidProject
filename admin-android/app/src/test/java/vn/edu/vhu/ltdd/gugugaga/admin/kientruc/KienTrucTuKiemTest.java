package vn.edu.vhu.ltdd.gugugaga.admin.kientruc;

import static org.junit.Assert.assertTrue;

import com.tngtech.archunit.core.domain.JavaClasses;
import com.tngtech.archunit.core.importer.ClassFileImporter;

import org.junit.Test;

/** Chứng minh quy tắc không "đạt cho có": áp lên lớp ví dụ sai thì phải báo vi phạm. */
public class KienTrucTuKiemTest {
    private final JavaClasses viDuSai = new ClassFileImporter()
            .importPackages("vn.edu.vhu.ltdd.gugugaga.admin.ui.vidusai");

    @Test
    public void batDuocManHinhGoiThangApiClient() {
        assertTrue(KienTrucTest.UI_CHI_DUNG_REPOSITORY.evaluate(viDuSai).hasViolation());
    }

    @Test
    public void batDuocRetrofitNgoaiTangData() {
        assertTrue(KienTrucTest.HTTP_CHI_O_DATA.evaluate(viDuSai).hasViolation());
    }

    @Test
    public void batDuocGoiMangDongBo() {
        assertTrue(KienTrucTest.KHONG_GOI_MANG_DONG_BO.evaluate(viDuSai).hasViolation());
    }
}
