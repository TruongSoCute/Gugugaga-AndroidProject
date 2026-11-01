package vn.edu.vhu.ltdd.gugugaga.admin.ui.donhang;

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
import vn.edu.vhu.ltdd.gugugaga.admin.model.DonHang;
import vn.edu.vhu.ltdd.gugugaga.admin.ui.MainActivity;
import vn.edu.vhu.ltdd.gugugaga.admin.ui.chung.BoLoc;
import vn.edu.vhu.ltdd.gugugaga.admin.ui.chung.KhungTrangThai;
import vn.edu.vhu.ltdd.gugugaga.admin.ui.chung.ManHinh;
import vn.edu.vhu.ltdd.gugugaga.admin.ui.chung.TrangThai;

/**
 * Tab Đơn hàng: danh sách mọi đơn, lọc theo trạng thái bằng Spinner. Bấm một đơn mở
 * ChiTietDonHangFragment; khi chi tiết đổi trạng thái, danh sách nhận Fragment Result và tải lại.
 */
public class DonHangFragment extends Fragment {
    /** Khóa Fragment Result: chi tiết báo "đơn đã đổi" để danh sách tải lại (Lab A8). */
    public static final String KET_QUA_CAP_NHAT = "cap_nhat_don_hang";

    private DonHangViewModel viewModel;
    private DonHangAdapter adapter;
    private RecyclerView rv;
    private KhungTrangThai khung;

    @Nullable
    @Override
    public View onCreateView(@NonNull LayoutInflater inflater, @Nullable ViewGroup container,
                             @Nullable Bundle savedInstanceState) {
        return inflater.inflate(R.layout.fragment_danh_sach, container, false);
    }

    @Override
    public void onViewCreated(@NonNull View view, @Nullable Bundle savedInstanceState) {
        ((MainActivity) requireActivity()).datTieuDe(R.string.tieu_de_don_hang);
        viewModel = new ViewModelProvider(this).get(DonHangViewModel.class);

        rv = view.findViewById(R.id.rvDanhSach);
        khung = new KhungTrangThai(view, viewModel::taiLai);
        khung.datChuTrong(R.string.trong_don_hang);
        adapter = new DonHangAdapter(don ->
                ((MainActivity) requireActivity()).moManHinh(ChiTietDonHangFragment.newInstance(don.id)));
        rv.setLayoutManager(new LinearLayoutManager(requireContext()));
        rv.setAdapter(adapter);

        BoLoc.caiDat(view.findViewById(R.id.spLoc), R.array.don_hang_nhan, R.array.don_hang_gia_tri,
                viewModel::chonLoc);

        viewModel.getDanhSach().observe(getViewLifecycleOwner(), this::hienThi);
        ManHinh.quanSatChung(this, viewModel);
        getParentFragmentManager().setFragmentResultListener(KET_QUA_CAP_NHAT, getViewLifecycleOwner(),
                (k, b) -> viewModel.taiLai());
    }

    private void hienThi(TrangThai<List<DonHang>> tt) {
        if (tt.loai == TrangThai.Loai.THANH_CONG) adapter.capNhat(tt.duLieu);
        khung.hien(tt, rv, tt.duLieu == null || tt.duLieu.isEmpty());
    }
}
