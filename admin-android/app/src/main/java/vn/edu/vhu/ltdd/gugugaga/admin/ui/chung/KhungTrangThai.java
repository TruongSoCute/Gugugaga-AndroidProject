package vn.edu.vhu.ltdd.gugugaga.admin.ui.chung;

import android.view.View;
import android.widget.TextView;

import androidx.annotation.Nullable;
import androidx.annotation.StringRes;
import androidx.core.content.ContextCompat;
import androidx.recyclerview.widget.RecyclerView;
import androidx.swiperefreshlayout.widget.SwipeRefreshLayout;

import vn.edu.vhu.ltdd.gugugaga.admin.R;

/**
 * Ba trạng thái khi gọi API (C.1 #8, Phụ lục 2 mục 2.4): ProgressBar khi đang tải, nội dung
 * (hoặc khối "trống") khi thành công, thông báo lỗi + nút Thử lại khi lỗi. Hỗ trợ kèm
 * SwipeRefreshLayout nếu layout danh sách có kéo xuống để làm mới.
 */
public class KhungTrangThai {
    private final View progress;
    private final View khungTrong;
    private final TextView tvTrong;
    private final View khungLoi;
    private final TextView tvLoi;
    @Nullable
    private final SwipeRefreshLayout swipeRefresh;

    public KhungTrangThai(View goc, Runnable thuLai) {
        progress = goc.findViewById(R.id.progress);
        View kt = goc.findViewById(R.id.khungTrong);
        tvTrong = goc.findViewById(R.id.tvTrong);
        khungTrong = kt != null ? kt : tvTrong;
        khungLoi = goc.findViewById(R.id.khungLoi);
        tvLoi = goc.findViewById(R.id.tvLoi);
        goc.findViewById(R.id.btnThuLai).setOnClickListener(v -> thuLai.run());

        swipeRefresh = goc.findViewById(R.id.swipeRefresh);
        if (swipeRefresh != null) {
            swipeRefresh.setColorSchemeColors(
                    ContextCompat.getColor(goc.getContext(), R.color.xanh_ocop),
                    ContextCompat.getColor(goc.getContext(), R.color.vang_ocop));
            swipeRefresh.setOnRefreshListener(thuLai::run);
        }
    }

    public void datChuTrong(@StringRes int id) {
        tvTrong.setText(id);
    }

    /**
     * @param noiDung View hiện khi có dữ liệu (RecyclerView hoặc ScrollView chi tiết).
     * @param rong    true nếu thành công nhưng không có dữ liệu.
     */
    public void hien(TrangThai<?> tt, View noiDung, boolean rong) {
        boolean dangTai = tt.loai == TrangThai.Loai.DANG_TAI;
        boolean thanhCong = tt.loai == TrangThai.Loai.THANH_CONG;
        if (swipeRefresh != null && !dangTai) {
            swipeRefresh.setRefreshing(false);
        }
        boolean dangKeoLamMoi = swipeRefresh != null && swipeRefresh.isRefreshing();
        progress.setVisibility(dangTai && !dangKeoLamMoi ? View.VISIBLE : View.GONE);
        if (tt.loai == TrangThai.Loai.LOI) {
            tvLoi.setText(tt.thongDiep);
            ChuyenDong.hienMuot(khungLoi);
        } else {
            khungLoi.setVisibility(View.GONE);
        }
        if (thanhCong && !rong) {
            boolean vuaHien = noiDung.getVisibility() != View.VISIBLE;
            ChuyenDong.hienMuot(noiDung);
            if (vuaHien && noiDung instanceof RecyclerView) {
                ChuyenDong.chayHienDanhSach((RecyclerView) noiDung);
            }
        } else {
            noiDung.setVisibility(View.GONE);
        }
        if (thanhCong && rong) {
            ChuyenDong.hienMuot(khungTrong);
        } else {
            khungTrong.setVisibility(View.GONE);
        }
    }
}
