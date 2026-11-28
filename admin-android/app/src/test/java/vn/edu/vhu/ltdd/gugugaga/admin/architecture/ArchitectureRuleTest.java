package vn.edu.vhu.ltdd.gugugaga.admin.architecture;

import static org.junit.Assert.assertTrue;

import com.tngtech.archunit.core.domain.JavaClasses;
import com.tngtech.archunit.core.importer.ClassFileImporter;

import org.junit.Test;

/** Chứng minh quy tắc không "đạt cho có": áp lên lớp ví dụ sai thì phải báo vi phạm. */
public class ArchitectureRuleTest {
    private final JavaClasses viDuSai = new ClassFileImporter()
            .importPackages("vn.edu.vhu.ltdd.gugugaga.admin.ui.invalidexamples");

    @Test
    public void batDuocManHinhGoiThangApiClient() {
        assertTrue(ArchitectureTest.UI_CHI_DUNG_REPOSITORY.evaluate(viDuSai).hasViolation());
    }

    @Test
    public void batDuocRetrofitNgoaiTangData() {
        assertTrue(ArchitectureTest.HTTP_CHI_O_DATA.evaluate(viDuSai).hasViolation());
    }

    @Test
    public void batDuocGoiMangDongBo() {
        assertTrue(ArchitectureTest.KHONG_GOI_MANG_DONG_BO.evaluate(viDuSai).hasViolation());
    }
}
