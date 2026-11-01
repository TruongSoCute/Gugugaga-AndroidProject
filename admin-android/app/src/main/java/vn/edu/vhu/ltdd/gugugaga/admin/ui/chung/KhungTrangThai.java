package vn.edu.vhu.ltdd.gugugaga.admin.ui.chung;

import android.view.View;
import android.widget.TextView;

import androidx.annotation.StringRes;

import vn.edu.vhu.ltdd.gugugaga.admin.R;

/**
 * Ba trạng thái khi gọi API (C.1 #8, Phụ lục 2 mục 2.4): ProgressBar khi đang tải, nội dung
 * (hoặc dòng "trống") khi thành công, thông báo lỗi + nút Thử lại khi lỗi. Dùng với layout
 * khung_trang_thai.xml được include vào FrameLayout của màn hình.
 */
public class KhungTrangThai {
    private final View progress;
    private final TextView tvTrong;
    private final View khungLoi;
    private final TextView tvLoi;

    public KhungTrangThai(View goc, Runnable thuLai) {
        progress = goc.findViewById(R.id.progress);
        tvTrong = goc.findViewById(R.id.tvTrong);
        khungLoi = goc.findViewById(R.id.khungLoi);
        tvLoi = goc.findViewById(R.id.tvLoi);
        goc.findViewById(R.id.btnThuLai).setOnClickListener(v -> thuLai.run());
    }

    public void datChuTrong(@StringRes int id) {
        tvTrong.setText(id);
    }

    /**
     * @param noiDung View hiện khi có dữ liệu (RecyclerView hoặc ScrollView chi tiết).
     * @param rong    true nếu thành công nhưng không có dữ liệu.
     */
    public void hien(TrangThai<?> tt, View noiDung, boolean rong) {
        boolean thanhCong = tt.loai == TrangThai.Loai.THANH_CONG;
        progress.setVisibility(tt.loai == TrangThai.Loai.DANG_TAI ? View.VISIBLE : View.GONE);
        khungLoi.setVisibility(tt.loai == TrangThai.Loai.LOI ? View.VISIBLE : View.GONE);
        if (tt.loai == TrangThai.Loai.LOI) tvLoi.setText(tt.thongDiep);
        noiDung.setVisibility(thanhCong && !rong ? View.VISIBLE : View.GONE);
        tvTrong.setVisibility(thanhCong && rong ? View.VISIBLE : View.GONE);
    }
}
