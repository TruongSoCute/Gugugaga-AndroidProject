package vn.edu.vhu.ltdd.gugugaga.admin.kientruc;

import static com.tngtech.archunit.base.DescribedPredicate.not;
import static com.tngtech.archunit.core.domain.JavaClass.Predicates.resideInAPackage;
import static com.tngtech.archunit.core.domain.JavaClass.Predicates.simpleNameEndingWith;
import static com.tngtech.archunit.core.domain.JavaClass.Predicates.simpleName;
import static com.tngtech.archunit.lang.syntax.ArchRuleDefinition.classes;
import static com.tngtech.archunit.lang.syntax.ArchRuleDefinition.noClasses;
import static com.tngtech.archunit.library.Architectures.layeredArchitecture;
import static com.tngtech.archunit.library.GeneralCodingRules.NO_CLASSES_SHOULD_ACCESS_STANDARD_STREAMS;
import static com.tngtech.archunit.library.GeneralCodingRules.NO_CLASSES_SHOULD_USE_JAVA_UTIL_LOGGING;

import com.tngtech.archunit.core.domain.JavaClass;
import com.tngtech.archunit.core.domain.JavaConstructor;
import com.tngtech.archunit.core.importer.ImportOption;
import com.tngtech.archunit.core.importer.Location;
import com.tngtech.archunit.junit.AnalyzeClasses;
import com.tngtech.archunit.junit.ArchTest;
import com.tngtech.archunit.junit.ArchUnitRunner;
import com.tngtech.archunit.lang.ArchCondition;
import com.tngtech.archunit.lang.ArchRule;
import com.tngtech.archunit.lang.ConditionEvents;
import com.tngtech.archunit.lang.SimpleConditionEvent;

import org.junit.runner.RunWith;

/**
 * Kiểm tra kiến trúc app Admin bằng ArchUnit (docs/development/Architecture.md, mục Hai app).
 * Chạy cùng ./gradlew testDebugUnitTest. Khi một quy tắc bị vi phạm, sửa code cho đúng tầng;
 * không nới quy tắc khi nhóm chưa thống nhất.
 *
 * Các tầng:  ui  →  data  →  model ;  util dùng chung, AppConfig/BuildConfig/R ở gói gốc.
 */
@RunWith(ArchUnitRunner.class)
@AnalyzeClasses(packages = "vn.edu.vhu.ltdd.gugugaga.admin", importOptions = KienTrucTest.KhongGomTest.class)
public class KienTrucTest {

    /** Unit test Android biên dịch vào thư mục ...UnitTest..., không theo mẫu mặc định của ArchUnit. */
    public static class KhongGomTest implements ImportOption {
        @Override
        public boolean includes(Location location) {
            return !location.contains("UnitTest") && !location.contains("/test/");
        }
    }

    // ---- Phân tầng ----

    /** ui → data → model; không tầng nào được phụ thuộc ngược lên ui. */
    @ArchTest
    static final ArchRule PHAN_TANG = layeredArchitecture()
            .consideringOnlyDependenciesInLayers()
            .layer("UI").definedBy("..admin.ui..")
            .layer("Data").definedBy("..admin.data..")
            .layer("Model").definedBy("..admin.model..")
            .layer("Util").definedBy("..admin.util..")
            .whereLayer("UI").mayNotBeAccessedByAnyLayer()
            .whereLayer("Data").mayOnlyBeAccessedByLayers("UI")
            .whereLayer("Model").mayOnlyBeAccessedByLayers("UI", "Data")
            .whereLayer("Util").mayOnlyBeAccessedByLayers("UI", "Data");

    /**
     * Màn hình không gọi API trực tiếp: ui chỉ dùng repository, KetQuaApi và TokenStore của
     * tầng data; không đụng tới ApiClient, ApiService, GoiApi.
     */
    @ArchTest
    static final ArchRule UI_CHI_DUNG_REPOSITORY = noClasses()
            .that().resideInAPackage("..admin.ui..")
            .should().dependOnClassesThat(resideInAPackage("..admin.data..")
                    .and(not(simpleNameEndingWith("Repository")))
                    .and(not(simpleName("KetQuaApi")))
                    .and(not(simpleName("TokenStore"))))
            .because("màn hình gọi API qua repository (Architecture.md)");

    /** Retrofit và OkHttp chỉ nằm trong tầng data (Phụ lục 2: ApiService, ApiClient). */
    @ArchTest
    static final ArchRule HTTP_CHI_O_DATA = noClasses()
            .that().resideOutsideOfPackage("..admin.data..")
            .should().dependOnClassesThat().resideInAnyPackage("retrofit2..", "okhttp3..")
            .because("chỉ tầng data gọi mạng");

    /** Gson chỉ ở tầng data; model được dùng annotation như @SerializedName. */
    @ArchTest
    static final ArchRule GSON_CHI_O_DATA = noClasses()
            .that().resideOutsideOfPackage("..admin.data..")
            .should().dependOnClassesThat(resideInAPackage("com.google.gson..")
                    .and(not(resideInAPackage("com.google.gson.annotations.."))))
            .because("đọc/ghi JSON là việc của tầng data");

    /** Token chỉ đọc/ghi qua TokenStore (một chỗ quản lý phiên đăng nhập). */
    @ArchTest
    static final ArchRule SHARED_PREFS_CHI_O_TOKEN_STORE = noClasses()
            .that().doNotHaveSimpleName("TokenStore")
            .should().dependOnClassesThat().haveFullyQualifiedName("android.content.SharedPreferences")
            .because("phiên đăng nhập do TokenStore quản lý (Phụ lục 2)");

    /** Model là lớp dữ liệu thuần, không phụ thuộc Android hay tầng khác. */
    @ArchTest
    static final ArchRule MODEL_THUAN = classes()
            .that().resideInAPackage("..admin.model..")
            .should().onlyDependOnClassesThat()
            .resideInAnyPackage("..admin.model..", "java..", "com.google.gson.annotations..");

    /** util chỉ chứa hàm thuần Java. */
    @ArchTest
    static final ArchRule UTIL_THUAN = classes()
            .that().resideInAPackage("..admin.util..")
            .should().onlyDependOnClassesThat().resideInAnyPackage("..admin.util..", "java..");

    /** Tầng data không biết gì về giao diện. */
    @ArchTest
    static final ArchRule DATA_KHONG_DUNG_GIAO_DIEN = noClasses()
            .that().resideInAPackage("..admin.data..")
            .should().dependOnClassesThat().resideInAnyPackage(
                    "android.view..", "android.widget..", "androidx.fragment..",
                    "androidx.appcompat..", "com.google.android.material..", "androidx.lifecycle..");

    // ---- Quy ước rút từ lab ----

    /** Lab A2: không gọi mạng đồng bộ trên main thread (gây ANR) — dùng enqueue, không dùng execute. */
    @ArchTest
    static final ArchRule KHONG_GOI_MANG_DONG_BO = noClasses()
            .should().callMethod("retrofit2.Call", "execute")
            .because("gọi đồng bộ trên main thread gây ANR (Lab A2); dùng enqueue");

    /** Lab A8: Fragment chỉ có constructor rỗng; dữ liệu truyền qua newInstance + arguments. */
    @ArchTest
    static final ArchRule FRAGMENT_CONSTRUCTOR_RONG = classes()
            .that().areAssignableTo("androidx.fragment.app.Fragment")
            .and().resideInAPackage("..admin..")
            .should(chiCoConstructorKhongThamSo())
            .because("hệ thống tạo lại Fragment bằng constructor rỗng khi xoay màn hình (Lab A8)");

    /** ViewModel sống lâu hơn Activity/Fragment: không được giữ View, Activity, Fragment (rò rỉ bộ nhớ). */
    @ArchTest
    static final ArchRule VIEWMODEL_KHONG_GIU_GIAO_DIEN = noClasses()
            .that().areAssignableTo("androidx.lifecycle.ViewModel")
            .should().dependOnClassesThat().resideInAnyPackage(
                    "android.view..", "android.widget..", "androidx.fragment..", "androidx.appcompat..")
            .orShould().dependOnClassesThat().areAssignableTo("android.app.Activity");

    /** Lab A1: ghi log bằng android.util.Log với TAG, không dùng System.out / System.err. */
    @ArchTest
    static final ArchRule KHONG_SYSTEM_OUT = NO_CLASSES_SHOULD_ACCESS_STANDARD_STREAMS;

    @ArchTest
    static final ArchRule KHONG_JAVA_UTIL_LOGGING = NO_CLASSES_SHOULD_USE_JAVA_UTIL_LOGGING;

    static ArchCondition<JavaClass> chiCoConstructorKhongThamSo() {
        return new ArchCondition<JavaClass>("chỉ có constructor không tham số") {
            @Override
            public void check(JavaClass lop, ConditionEvents events) {
                for (JavaConstructor c : lop.getConstructors()) {
                    if (!c.getRawParameterTypes().isEmpty()) {
                        events.add(SimpleConditionEvent.violated(lop,
                                lop.getName() + " có constructor có tham số: " + c.getFullName()));
                    }
                }
            }
        };
    }
}
