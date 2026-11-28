package vn.edu.vhu.ltdd.gugugaga.admin.ui.common;

import android.view.View;
import android.widget.TextView;

import androidx.fragment.app.Fragment;
import androidx.recyclerview.widget.RecyclerView;

import vn.edu.vhu.ltdd.gugugaga.admin.R;

/**
 * Dòng dưới danh sách khi phân trang (layout khung_tai_them.xml): "Đang tải thêm…" khi tải
 * trang sau, hoặc lỗi + nút Thử lại nếu trang sau lỗi. Gom việc lặp lại ở mọi màn hình danh
 * sách: gắn LoadMoreScrollListener vào RecyclerView và quan sát LiveData tải thêm của ViewModel.
 */
public final class LoadMoreFooter {
    private final View khung;
    private final View progress;
    private final TextView tvTaiThem;
    private final View btnThuLai;

    private LoadMoreFooter(View goc, Runnable thuLai) {
        khung = goc.findViewById(R.id.khungTaiThem);
        progress = goc.findViewById(R.id.pbTaiThem);
        tvTaiThem = goc.findViewById(R.id.tvTaiThem);
        btnThuLai = goc.findViewById(R.id.btnThuLaiTaiThem);
        btnThuLai.setOnClickListener(v -> thuLai.run());
    }

    /** Gọi trong onViewCreated, sau khi đã gắn LayoutManager và adapter cho rv. */
    public static void gan(Fragment f, View goc, RecyclerView rv, FilteredListViewModel<?> vm) {
        LoadMoreFooter chan = new LoadMoreFooter(goc, vm::taiThem);
        rv.addOnScrollListener(new LoadMoreScrollListener(vm::taiThem));
        vm.getDangTaiThem().observe(f.getViewLifecycleOwner(), chan::hienDangTai);
        vm.getLoiTaiThem().observe(f.getViewLifecycleOwner(), sk -> {
            String loi = sk.layNeuChuaXuLy();
            if (loi != null) chan.hienLoi(loi);
        });
    }

    private void hienDangTai(Boolean dangTai) {
        boolean co = Boolean.TRUE.equals(dangTai);
        khung.setVisibility(co ? View.VISIBLE : View.GONE);
        progress.setVisibility(View.VISIBLE);
        tvTaiThem.setText(R.string.dang_tai_them);
        btnThuLai.setVisibility(View.GONE);
    }

    private void hienLoi(String thongDiep) {
        khung.setVisibility(View.VISIBLE);
        progress.setVisibility(View.GONE);
        tvTaiThem.setText(thongDiep);
        btnThuLai.setVisibility(View.VISIBLE);
    }
}
