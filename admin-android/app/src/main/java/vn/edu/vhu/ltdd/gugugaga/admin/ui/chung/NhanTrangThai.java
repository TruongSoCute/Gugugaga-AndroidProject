package vn.edu.vhu.ltdd.gugugaga.admin.ui.chung;

import android.content.Context;
import android.widget.TextView;

import androidx.annotation.ColorRes;
import androidx.annotation.StringRes;
import androidx.core.content.ContextCompat;

import vn.edu.vhu.ltdd.gugugaga.admin.R;

/**
 * Đổi mã trạng thái của backend (CHO_XAC_NHAN, MOI, DA_DUYET...) thành chữ tiếng Việt và màu nhãn.
 * Mã trạng thái của đơn, phản ánh và hồ sơ không trùng nhau nên dùng chung một bảng.
 */
public final class NhanTrangThai {
    private NhanTrangThai() { }

    @StringRes
    public static int chu(String ma) {
        if (ma == null) return R.string.tt_khong_ro;
        switch (ma) {
            case "CHO_DUYET": return R.string.trang_thai_cho_duyet;
            case "DA_DUYET": return R.string.trang_thai_da_duyet;
            case "TU_CHOI": return R.string.trang_thai_tu_choi;
            case "CHO_XAC_NHAN": return R.string.tt_cho_xac_nhan;
            case "DA_XAC_NHAN": return R.string.tt_da_xac_nhan;
            case "DANG_GIAO": return R.string.tt_dang_giao;
            case "DA_GIAO": return R.string.tt_da_giao;
            case "DA_NHAN": return R.string.tt_da_nhan;
            case "DA_HUY": return R.string.tt_da_huy;
            case "MOI": return R.string.tt_moi;
            case "DANG_XU_LY": return R.string.tt_dang_xu_ly;
            case "DA_XU_LY": return R.string.tt_da_xu_ly;
            case "BAC_BO": return R.string.tt_bac_bo;
            default: return R.string.tt_khong_ro;
        }
    }

    /** Màu chữ và màu nền: vàng = chờ người xử lý, xanh dương = đang làm, xanh lá = xong, đỏ = hủy/từ chối. */
    private static int[] mau(String ma) {
        if (ma == null) return new int[]{R.color.xam_chu, R.color.xam_nen};
        switch (ma) {
            case "CHO_DUYET":
            case "CHO_XAC_NHAN":
            case "MOI":
                return new int[]{R.color.vang_cho_duyet, R.color.nen_cho_duyet};
            case "DA_XAC_NHAN":
            case "DANG_GIAO":
            case "DANG_XU_LY":
                return new int[]{R.color.xanh_duong_chu, R.color.xanh_duong_nen};
            case "DA_DUYET":
            case "DA_GIAO":
            case "DA_NHAN":
            case "DA_XU_LY":
                return new int[]{R.color.xanh_da_duyet, R.color.nen_da_duyet};
            case "TU_CHOI":
            case "DA_HUY":
                return new int[]{R.color.do_tu_choi, R.color.nen_tu_choi};
            default:
                return new int[]{R.color.xam_chu, R.color.xam_nen};
        }
    }

    /** Gán chữ và màu cho nhãn trạng thái (TextView dùng style NhanTrangThai). */
    public static void gan(TextView tv, String ma) {
        Context ctx = tv.getContext();
        int[] m = mau(ma);
        tv.setText(chu(ma));
        tv.setTextColor(ContextCompat.getColor(ctx, m[0]));
        tv.setBackgroundColor(ContextCompat.getColor(ctx, m[1]));
    }

    /** Nhãn của nút chuyển sang trạng thái `ma` (vd DANG_GIAO -> "Bắt đầu giao"). */
    @StringRes
    public static int nut(String ma) {
        switch (ma) {
            case "DA_XAC_NHAN": return R.string.nut_xac_nhan_don;
            case "DANG_GIAO": return R.string.nut_bat_dau_giao;
            case "DA_GIAO": return R.string.nut_da_giao;
            case "DA_HUY": return R.string.nut_huy_don;
            case "DANG_XU_LY": return R.string.nut_bat_dau_xu_ly;
            case "DA_XU_LY": return R.string.nut_da_xu_ly;
            case "BAC_BO": return R.string.nut_bac_bo;
            default: return chu(ma);
        }
    }

    /** Thao tác "lùi" hoặc dừng (hủy đơn, bác bỏ) vẽ bằng nút viền để khác nút chính. */
    public static boolean laThaoTacPhu(String ma) {
        return "DA_HUY".equals(ma) || "BAC_BO".equals(ma);
    }

    @StringRes
    public static int hinhThucGiao(String ma) {
        if ("NHANH".equals(ma)) return R.string.giao_nhanh;
        if ("NHAN_TAI_CHO".equals(ma)) return R.string.giao_tai_cho;
        return R.string.giao_tieu_chuan;
    }

    @StringRes
    public static int loaiPhanAnh(String ma) {
        if ("HANG_GIA".equals(ma)) return R.string.loai_hang_gia;
        if ("SAI_MO_TA".equals(ma)) return R.string.loai_sai_mo_ta;
        return R.string.loai_khac;
    }

    @ColorRes
    public static int mauChu(String ma) {
        return mau(ma)[0];
    }
}
