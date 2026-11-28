package vn.edu.vhu.ltdd.gugugaga.admin.ui.supplier;

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
import vn.edu.vhu.ltdd.gugugaga.admin.model.Supplier;
import vn.edu.vhu.ltdd.gugugaga.admin.ui.MainActivity;
import vn.edu.vhu.ltdd.gugugaga.admin.ui.common.FilterBar;
import vn.edu.vhu.ltdd.gugugaga.admin.ui.common.LoadMoreFooter;
import vn.edu.vhu.ltdd.gugugaga.admin.ui.common.StatePanel;
import vn.edu.vhu.ltdd.gugugaga.admin.ui.common.ScreenLayout;
import vn.edu.vhu.ltdd.gugugaga.admin.ui.common.UiState;

/** Danh sách hồ sơ nhà cung cấp (mở từ tab Tài khoản), lọc theo trạng thái duyệt. */
public class SupplierListFragment extends Fragment {
    public static final String KET_QUA_CAP_NHAT = "cap_nhat_nha_cung_cap";
    public static final String KEY_THONG_BAO = "thong_bao";

    private SupplierListViewModel viewModel;
    private SupplierAdapter adapter;
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
        main.datTieuDe(R.string.tieu_de_nha_cung_cap);
        viewModel = new ViewModelProvider(this).get(SupplierListViewModel.class);

        com.google.android.material.floatingactionbutton.ExtendedFloatingActionButton fab =
                view.findViewById(R.id.fabThem);
        fab.setText(R.string.nut_them_nha_cung_cap);
        fab.setVisibility(View.VISIBLE);
        fab.setOnClickListener(v -> main.moManHinh(new CreateSupplierFragment()));

        rv = view.findViewById(R.id.rvDanhSach);
        khung = new StatePanel(view, viewModel::taiLai);
        khung.datChuTrong(R.string.trong_nha_cung_cap);
        adapter = new SupplierAdapter(ncc ->
                ((MainActivity) requireActivity()).moManHinh(SupplierDetailsFragment.newInstance(ncc.id)));
        rv.setLayoutManager(new LinearLayoutManager(requireContext()));
        rv.setAdapter(adapter);
        LoadMoreFooter.gan(this, view, rv, viewModel); // cuộn gần cuối thì tải trang sau

        FilterBar.caiDatChip(view.findViewById(R.id.cgLoc), R.array.trang_thai_nhan, R.array.trang_thai_gia_tri,
                viewModel::chonLoc);

        viewModel.getDanhSach().observe(getViewLifecycleOwner(), this::hienThi);
        ScreenLayout.quanSatChung(this, viewModel);
        getParentFragmentManager().setFragmentResultListener(KET_QUA_CAP_NHAT, getViewLifecycleOwner(), (k, b) -> {
            String tb = b.getString(KEY_THONG_BAO);
            if (tb != null) ScreenLayout.baoSnackbar(this, tb);
            viewModel.taiLai();
        });
    }

    private void hienThi(UiState<List<Supplier>> tt) {
        if (tt.loai == UiState.Loai.THANH_CONG) adapter.capNhat(tt.duLieu);
        khung.hien(tt, rv, tt.duLieu == null || tt.duLieu.isEmpty());
    }
}
