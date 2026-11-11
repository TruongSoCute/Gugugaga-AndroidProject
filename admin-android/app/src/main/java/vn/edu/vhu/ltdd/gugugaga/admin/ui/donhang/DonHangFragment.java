
package vn.edu.vhu.ltdd.gugugaga.admin.ui.donhang;

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

import java.util.List;

import vn.edu.vhu.ltdd.gugugaga.admin.R;
import vn.edu.vhu.ltdd.gugugaga.admin.model.DonHang;
import vn.edu.vhu.ltdd.gugugaga.admin.ui.MainActivity;
import vn.edu.vhu.ltdd.gugugaga.admin.ui.chung.BoLoc;
import vn.edu.vhu.ltdd.gugugaga.admin.ui.chung.KhungTrangThai;
import vn.edu.vhu.ltdd.gugugaga.admin.ui.chung.ManHinh;
import vn.edu.vhu.ltdd.gugugaga.admin.ui.chung.TrangThai;

/**
 * Tab Đơn hàng: danh sách đơn hàng có bộ lọc và phân trang.
 */
public class DonHangFragment extends Fragment {

    public static final String KET_QUA_CAP_NHAT = "cap_nhat_don_hang";

    private DonHangViewModel viewModel;
    private DonHangAdapter adapter;
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

        main.datTieuDe(R.string.tieu_de_don_hang);

        viewModel = new ViewModelProvider(this).get(DonHangViewModel.class);

        rv = view.findViewById(R.id.rvDanhSach);

        khung = new KhungTrangThai(view, viewModel::taiLai);
        khung.datChuTrong(R.string.trong_don_hang);

        adapter = new DonHangAdapter(don ->
                main.moManHinh(
                        ChiTietDonHangFragment.newInstance(don.id)
                )
        );

        layoutManager = new LinearLayoutManager(requireContext());

        rv.setLayoutManager(layoutManager);
        rv.setAdapter(adapter);

        // Bộ lọc trạng thái đơn hàng.
        BoLoc.caiDat(
                view.findViewById(R.id.spLoc),
                R.array.don_hang_nhan,
                R.array.don_hang_gia_tri,
                viewModel::chonLoc
        );

        // Khu vực trạng thái tải thêm.
        khungTaiThem = view.findViewById(R.id.khungTaiThem);
        pbTaiThem = view.findViewById(R.id.pbTaiThem);
        tvTrangThaiTaiThem = view.findViewById(R.id.tvTrangThaiTaiThem);
        btnThuLai = view.findViewById(R.id.btnThuLai);

        khungTaiThem.setVisibility(View.GONE);

        btnThuLai.setOnClickListener(v ->
                viewModel.taiTrangTiepTheo()
        );

        // Tự động tải thêm khi cuộn gần cuối danh sách.
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

        // Quan sát danh sách.
        viewModel.getDanhSach().observe(
                getViewLifecycleOwner(),
                this::hienThi
        );

        // Quan sát trạng thái tải thêm.
        viewModel.getDangTaiThem().observe(
                getViewLifecycleOwner(),
                dangTai -> capNhatTrangThaiTaiThem()
        );

        // Quan sát lỗi tải thêm.
        viewModel.getLoiTaiThem().observe(
                getViewLifecycleOwner(),
                loi -> capNhatTrangThaiTaiThem()
        );

        ManHinh.quanSatChung(this, viewModel);

        // Nhận kết quả khi đơn hàng thay đổi trạng thái.
        getParentFragmentManager().setFragmentResultListener(
                KET_QUA_CAP_NHAT,
                getViewLifecycleOwner(),
                (k, b) -> viewModel.taiLai()
        );

        viewModel.taiLanDau();
    }

    /**
     * Cập nhật giao diện tải thêm.
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
     * Hiển thị danh sách đơn hàng.
     */
    private void hienThi(TrangThai<List<DonHang>> tt) {

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
