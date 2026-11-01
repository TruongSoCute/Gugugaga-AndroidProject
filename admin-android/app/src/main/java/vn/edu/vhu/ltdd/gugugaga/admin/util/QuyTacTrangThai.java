package vn.edu.vhu.ltdd.gugugaga.admin.util;

import java.util.Arrays;
import java.util.Collections;
import java.util.List;

/**
 * Các bước chuyển trạng thái mà app cho HIỆN NÚT, chép theo quy tắc của backend
 * (docs/development/Design_decisions.md). App chỉ ẩn nút cho gọn; backend vẫn là nơi quyết định
 * và trả 403/409 nếu bước chuyển không hợp lệ.
 */
public final class QuyTacTrangThai {
    // Trạng thái đơn hàng
    public static final String DON_CHO_XAC_NHAN = "CHO_XAC_NHAN";
    public static final String DON_DA_XAC_NHAN = "DA_XAC_NHAN";
    public static final String DON_DANG_GIAO = "DANG_GIAO";
    public static final String DON_DA_GIAO = "DA_GIAO";
    public static final String DON_DA_NHAN = "DA_NHAN";
    public static final String DON_DA_HUY = "DA_HUY";

    // Trạng thái phản ánh
    public static final String PA_MOI = "MOI";
    public static final String PA_DANG_XU_LY = "DANG_XU_LY";
    public static final String PA_DA_XU_LY = "DA_XU_LY";
    public static final String PA_BAC_BO = "BAC_BO";

    // Trạng thái duyệt hồ sơ
    public static final String HS_CHO_DUYET = "CHO_DUYET";
    public static final String HS_DA_DUYET = "DA_DUYET";
    public static final String HS_TU_CHOI = "TU_CHOI";

    private QuyTacTrangThai() { }

    /**
     * Bước tiếp theo NHÂN SỰ được làm với đơn hàng:
     * CHO_XAC_NHAN → DA_XAC_NHAN | DA_HUY; DA_XAC_NHAN → DANG_GIAO | DA_HUY; DANG_GIAO → DA_GIAO.
     * DA_NHAN chỉ khách xác nhận, nên nhân sự không có nút.
     */
    public static List<String> buocTiepDonHang(String hienTai) {
        if (DON_CHO_XAC_NHAN.equals(hienTai)) return Arrays.asList(DON_DA_XAC_NHAN, DON_DA_HUY);
        if (DON_DA_XAC_NHAN.equals(hienTai)) return Arrays.asList(DON_DANG_GIAO, DON_DA_HUY);
        if (DON_DANG_GIAO.equals(hienTai)) return Collections.singletonList(DON_DA_GIAO);
        return Collections.emptyList();
    }

    /** Hủy đơn bắt buộc ghi lý do (backend trả 400 nếu thiếu). */
    public static boolean donCanGhiChu(String trangThaiMoi) {
        return DON_DA_HUY.equals(trangThaiMoi);
    }

    /** Phản ánh chỉ đi tới: MOI → DANG_XU_LY | DA_XU_LY | BAC_BO; DANG_XU_LY → DA_XU_LY | BAC_BO. */
    public static List<String> buocTiepPhanAnh(String hienTai) {
        if (PA_MOI.equals(hienTai)) return Arrays.asList(PA_DANG_XU_LY, PA_DA_XU_LY, PA_BAC_BO);
        if (PA_DANG_XU_LY.equals(hienTai)) return Arrays.asList(PA_DA_XU_LY, PA_BAC_BO);
        return Collections.emptyList();
    }

    /** Kết thúc phản ánh (đã xử lý hoặc bác bỏ) bắt buộc ghi kết quả. */
    public static boolean phanAnhCanKetQua(String trangThaiMoi) {
        return PA_DA_XU_LY.equals(trangThaiMoi) || PA_BAC_BO.equals(trangThaiMoi);
    }

    /** Quản trị duyệt được hồ sơ chưa duyệt (kể cả hồ sơ đã từ chối, để duyệt lại). */
    public static boolean coTheDuyetHoSo(String trangThai) {
        return !HS_DA_DUYET.equals(trangThai);
    }

    /** Quản trị từ chối được hồ sơ chờ duyệt, hoặc thu hồi hồ sơ đã duyệt. */
    public static boolean coTheTuChoiHoSo(String trangThai) {
        return !HS_TU_CHOI.equals(trangThai);
    }
}
