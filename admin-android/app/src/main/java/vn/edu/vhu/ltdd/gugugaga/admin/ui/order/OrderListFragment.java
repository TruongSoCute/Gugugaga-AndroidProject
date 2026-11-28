package vn.edu.vhu.ltdd.gugugaga.admin.ui.order;

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

import java.util.List;

import vn.edu.vhu.ltdd.gugugaga.admin.R;
import vn.edu.vhu.ltdd.gugugaga.admin.model.Order;
import vn.edu.vhu.ltdd.gugugaga.admin.ui.MainActivity;
import vn.edu.vhu.ltdd.gugugaga.admin.ui.common.FilterBar;
import vn.edu.vhu.ltdd.gugugaga.admin.ui.common.LoadMoreFooter;
import vn.edu.vhu.ltdd.gugugaga.admin.ui.common.StatePanel;
import vn.edu.vhu.ltdd.gugugaga.admin.ui.common.ScreenLayout;
import vn.edu.vhu.ltdd.gugugaga.admin.ui.common.UiState;

/**
 * Tab Đơn hàng: danh sách mọi đơn, lọc theo trạng thái bằng Spinner. Bấm một đơn mở
 * OrderDetailsFragment; khi chi tiết đổi trạng thái, danh sách nhận Fragment Result và tải lại.
 */
public class OrderListFragment extends Fragment {
    /** Khóa Fragment Result: chi tiết báo "đơn đã đổi" để danh sách tải lại (Lab A8). */
    public static final String KET_QUA_CAP_NHAT = "cap_nhat_don_hang";

    private OrderListViewModel viewModel;
    private OrderAdapter adapter;
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
        ((MainActivity) requireActivity()).datTieuDe(R.string.tieu_de_don_hang);
        viewModel = new ViewModelProvider(this).get(OrderListViewModel.class);

        rv = view.findViewById(R.id.rvDanhSach);
        khung = new StatePanel(view, viewModel::taiLai);
        khung.datChuTrong(R.string.trong_don_hang);
        adapter = new OrderAdapter(don ->
                ((MainActivity) requireActivity()).moManHinh(OrderDetailsFragment.newInstance(don.id)));
        rv.setLayoutManager(new LinearLayoutManager(requireContext()));
        rv.setAdapter(adapter);
        LoadMoreFooter.gan(this, view, rv, viewModel); // cuộn gần cuối thì tải trang sau

        FilterBar.caiDatChip(view.findViewById(R.id.cgLoc), R.array.don_hang_nhan, R.array.don_hang_gia_tri,
                viewModel::chonLoc);

        viewModel.getDanhSach().observe(getViewLifecycleOwner(), this::hienThi);
        ScreenLayout.quanSatChung(this, viewModel);
        getParentFragmentManager().setFragmentResultListener(KET_QUA_CAP_NHAT, getViewLifecycleOwner(),
                (k, b) -> viewModel.taiLai());
    }

    private void hienThi(UiState<List<Order>> tt) {
        if (tt.loai == UiState.Loai.THANH_CONG) adapter.capNhat(tt.duLieu);
        khung.hien(tt, rv, tt.duLieu == null || tt.duLieu.isEmpty());
    }
}
