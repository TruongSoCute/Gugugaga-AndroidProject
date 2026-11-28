package vn.edu.vhu.ltdd.gugugaga.admin.ui.batch;

import android.os.Bundle;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.fragment.app.Fragment;
import androidx.lifecycle.ViewModelProvider;
import androidx.recyclerview.widget.LinearLayoutManager;
import androidx.recyclerview.widget.RecyclerView;

import com.google.android.material.floatingactionbutton.ExtendedFloatingActionButton;

import java.util.List;

import vn.edu.vhu.ltdd.gugugaga.admin.R;
import vn.edu.vhu.ltdd.gugugaga.admin.model.ProductionBatch;
import vn.edu.vhu.ltdd.gugugaga.admin.ui.MainActivity;
import vn.edu.vhu.ltdd.gugugaga.admin.ui.common.LoadMoreFooter;
import vn.edu.vhu.ltdd.gugugaga.admin.ui.common.Animations;
import vn.edu.vhu.ltdd.gugugaga.admin.ui.common.StatePanel;
import vn.edu.vhu.ltdd.gugugaga.admin.ui.common.ScreenLayout;
import vn.edu.vhu.ltdd.gugugaga.admin.ui.common.UiState;

/**
 * Tab Lô: danh sách lô sản xuất mới nhất. Nút "Tạo lô" mở form; bấm một lô mở chi tiết có ảnh QR.
 * Form và chi tiết báo kết quả về đây bằng Fragment Result API để tải lại (Lab A8).
 */
public class BatchListFragment extends Fragment {
    public static final String KET_QUA_CAP_NHAT = "cap_nhat_lo";
    /** Thông báo kèm kết quả (vd "Đã tạo lô ..."), hiện bằng Snackbar ở danh sách. */
    public static final String KEY_THONG_BAO = "thong_bao";

    private BatchListViewModel viewModel;
    private BatchAdapter adapter;
    private RecyclerView rv;
    private StatePanel khung;

    @Nullable
    @Override
    public View onCreateView(@NonNull LayoutInflater inflater, @Nullable ViewGroup container,
                             @Nullable Bundle savedInstanceState) {
        return inflater.inflate(R.layout.fragment_list, container, false);
    }

    @Override
    public void onViewCreated(@NonNull View view, @Nullable Bundle savedInstanceState) {
        MainActivity main = (MainActivity) requireActivity();
        main.datTieuDe(R.string.tieu_de_lo);
        viewModel = new ViewModelProvider(this).get(BatchListViewModel.class);

        // Danh sách lô không có bộ lọc trạng thái.
        view.findViewById(R.id.khungLoc).setVisibility(View.GONE);
        ExtendedFloatingActionButton fab = view.findViewById(R.id.fabThem);
        fab.setText(R.string.nut_tao_lo);
        fab.setVisibility(View.VISIBLE);
        fab.setOnClickListener(v -> main.moManHinh(new CreateBatchFragment()));
        Animations.ganNhanNhe(fab);

        rv = view.findViewById(R.id.rvDanhSach);
        Animations.ganThuGonFab(rv, fab);
        khung = new StatePanel(view, viewModel::taiLai);
        khung.datChuTrong(R.string.trong_lo);
        adapter = new BatchAdapter(lo -> main.moManHinh(BatchDetailsFragment.newInstance(lo.id)));
        rv.setLayoutManager(new LinearLayoutManager(requireContext()));
        rv.setAdapter(adapter);
        LoadMoreFooter.gan(this, view, rv, viewModel); // cuộn gần cuối thì tải trang sau

        viewModel.getDanhSach().observe(getViewLifecycleOwner(), this::hienThi);
        ScreenLayout.quanSatChung(this, viewModel);
        getParentFragmentManager().setFragmentResultListener(KET_QUA_CAP_NHAT, getViewLifecycleOwner(), (k, b) -> {
            String tb = b.getString(KEY_THONG_BAO);
            if (tb != null) ScreenLayout.baoSnackbar(this, tb);
            viewModel.taiLai();
        });
        viewModel.taiLanDau();
    }

    private void hienThi(UiState<List<ProductionBatch>> tt) {
        if (tt.loai == UiState.Loai.THANH_CONG) adapter.capNhat(tt.duLieu);
        khung.hien(tt, rv, tt.duLieu == null || tt.duLieu.isEmpty());
    }
}
