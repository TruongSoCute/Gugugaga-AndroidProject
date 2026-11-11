
package vn.edu.vhu.ltdd.gugugaga.admin.ui.lo;

import android.os.Bundle;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.Button;
import android.widget.LinearLayout;
import android.widget.ProgressBar;
import android.widget.TextView;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.fragment.app.Fragment;
import androidx.lifecycle.ViewModelProvider;
import androidx.recyclerview.widget.LinearLayoutManager;
import androidx.recyclerview.widget.RecyclerView;

import com.google.android.material.floatingactionbutton.ExtendedFloatingActionButton;

import java.util.List;

import vn.edu.vhu.ltdd.gugugaga.admin.R;
import vn.edu.vhu.ltdd.gugugaga.admin.model.LoSanXuat;
import vn.edu.vhu.ltdd.gugugaga.admin.ui.MainActivity;
import vn.edu.vhu.ltdd.gugugaga.admin.ui.chung.KhungTrangThai;
import vn.edu.vhu.ltdd.gugugaga.admin.ui.chung.ManHinh;
import vn.edu.vhu.ltdd.gugugaga.admin.ui.chung.TrangThai;

/**
 * Tab Lô: danh sách lô sản xuất có phân trang.
 */
public class LoFragment extends Fragment {

    public static final String KET_QUA_CAP_NHAT = "cap_nhat_lo";
    public static final String KEY_THONG_BAO = "thong_bao";

    private LoViewModel viewModel;
    private LoAdapter adapter;
    private RecyclerView rv;
    private KhungTrangThai khung;
    private LinearLayoutManager layoutManager;

    private LinearLayout khungTaiThem;
    private ProgressBar pbTaiThem;
    private TextView tvTrangThaiTaiThem;
    private Button btnThuLai;

    @Nullable
    @Override
    public View onCreateView(
            @NonNull LayoutInflater inflater,
            @Nullable ViewGroup container,
            @Nullable Bundle savedInstanceState
    ) {
        return inflater.inflate(
                R.layout.fragment_danh_sach,
                container,
                false
        );
    }

    @Override
    public void onViewCreated(
            @NonNull View view,
            @Nullable Bundle savedInstanceState
    ) {
        MainActivity main = (MainActivity) requireActivity();

        main.datTieuDe(R.string.tieu_de_lo);

        viewModel = new ViewModelProvider(this).get(LoViewModel.class);

        // Danh sách lô không có bộ lọc trạng thái.
        view.findViewById(R.id.tvNhanLoc).setVisibility(View.GONE);
        view.findViewById(R.id.spLoc).setVisibility(View.GONE);

        ExtendedFloatingActionButton fab =
                view.findViewById(R.id.fabThem);

        fab.setText(R.string.nut_tao_lo);
        fab.setVisibility(View.VISIBLE);
        fab.setOnClickListener(v ->
                main.moManHinh(new TaoLoFragment())
        );

        // Khởi tạo RecyclerView.
        rv = view.findViewById(R.id.rvDanhSach);

        khung = new KhungTrangThai(view, viewModel::taiLai);
        khung.datChuTrong(R.string.trong_lo);

        adapter = new LoAdapter(
                lo -> main.moManHinh(
                        ChiTietLoFragment.newInstance(lo.id)
                )
        );

        layoutManager = new LinearLayoutManager(requireContext());

        rv.setLayoutManager(layoutManager);
        rv.setAdapter(adapter);

        // Khởi tạo khu vực trạng thái tải thêm.
        khungTaiThem = view.findViewById(R.id.khungTaiThem);
        pbTaiThem = view.findViewById(R.id.pbTaiThem);
        tvTrangThaiTaiThem = view.findViewById(R.id.tvTrangThaiTaiThem);
        btnThuLai = view.findViewById(R.id.btnThuLaiTaiThem);
        khungTaiThem.setVisibility(View.GONE);

        btnThuLai.setOnClickListener(v ->
                viewModel.taiTrangTiepTheo()
        );

        // Phát hiện khi người dùng cuộn gần cuối danh sách.
        rv.addOnScrollListener(new RecyclerView.OnScrollListener() {

            @Override
            public void onScrolled(
                    @NonNull RecyclerView recyclerView,
                    int dx,
                    int dy
            ) {
                super.onScrolled(recyclerView, dx, dy);

                if (dy <= 0) return;

                int tongSoDong = layoutManager.getItemCount();
                int dongCuoi = layoutManager.findLastVisibleItemPosition();

                if (tongSoDong > 0
                        && dongCuoi >= tongSoDong - 5) {

                    viewModel.taiTrangTiepTheo();
                }
            }
        });

        // Quan sát danh sách dữ liệu.
        viewModel.getDanhSach().observe(
                getViewLifecycleOwner(),
                this::hienThi
        );

        // Quan sát trạng thái đang tải thêm.
        viewModel.getDangTaiThem().observe(
                getViewLifecycleOwner(),
                dangTai -> capNhatTrangThaiTaiThem()
        );

        // Quan sát lỗi tải trang tiếp theo.
        viewModel.getLoiTaiThem().observe(
                getViewLifecycleOwner(),
                loi -> capNhatTrangThaiTaiThem()
        );

        ManHinh.quanSatChung(this, viewModel);

        // Nhận kết quả từ màn hình tạo lô hoặc chi tiết lô.
        getParentFragmentManager().setFragmentResultListener(
                KET_QUA_CAP_NHAT,
                getViewLifecycleOwner(),
                (k, b) -> {
                    String tb = b.getString(KEY_THONG_BAO);

                    if (tb != null) {
                        ManHinh.baoSnackbar(this, tb);
                    }

                    viewModel.taiLai();
                }
        );

        viewModel.taiLanDau();
    }

    /**
     * Cập nhật giao diện trạng thái tải thêm.
     */
    private void capNhatTrangThaiTaiThem() {

        Boolean dangTai = viewModel.getDangTaiThem().getValue();
        String loi = viewModel.getLoiTaiThem().getValue();

        boolean dangTaiThem = Boolean.TRUE.equals(dangTai);
        boolean coLoi = loi != null && !loi.trim().isEmpty();

        if (!dangTaiThem && !coLoi) {
            khungTaiThem.setVisibility(View.GONE);
            return;
        }

        khungTaiThem.setVisibility(View.VISIBLE);

        if (dangTaiThem) {
            pbTaiThem.setVisibility(View.VISIBLE);
            tvTrangThaiTaiThem.setText("Đang tải thêm...");
            btnThuLai.setVisibility(View.GONE);
        } else {
            pbTaiThem.setVisibility(View.GONE);
            tvTrangThaiTaiThem.setText(loi);
            btnThuLai.setVisibility(View.VISIBLE);
        }
    }

    /**
     * Hiển thị danh sách lô sản xuất.
     */
    private void hienThi(TrangThai<List<LoSanXuat>> tt) {

        if (tt.loai == TrangThai.Loai.THANH_CONG) {
            adapter.capNhat(tt.duLieu);
        }

        khung.hien(
                tt,
                rv,
                tt.duLieu == null || tt.duLieu.isEmpty()
        );
    }
}
