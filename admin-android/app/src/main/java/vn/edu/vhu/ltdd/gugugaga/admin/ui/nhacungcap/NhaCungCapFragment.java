package vn.edu.vhu.ltdd.gugugaga.admin.ui.nhacungcap;

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
import vn.edu.vhu.ltdd.gugugaga.admin.model.NhaCungCap;
import vn.edu.vhu.ltdd.gugugaga.admin.ui.MainActivity;
import vn.edu.vhu.ltdd.gugugaga.admin.ui.chung.BoLoc;
import vn.edu.vhu.ltdd.gugugaga.admin.ui.chung.KhungTrangThai;
import vn.edu.vhu.ltdd.gugugaga.admin.ui.chung.ManHinh;
import vn.edu.vhu.ltdd.gugugaga.admin.ui.chung.TrangThai;

/** Danh sách hồ sơ nhà cung cấp (mở từ tab Tài khoản), lọc theo trạng thái duyệt. */
public class NhaCungCapFragment extends Fragment {
    public static final String KET_QUA_CAP_NHAT = "cap_nhat_nha_cung_cap";

    private NhaCungCapViewModel viewModel;
    private NhaCungCapAdapter adapter;
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
        ((MainActivity) requireActivity()).datTieuDe(R.string.tieu_de_nha_cung_cap);
        viewModel = new ViewModelProvider(this).get(NhaCungCapViewModel.class);

        rv = view.findViewById(R.id.rvDanhSach);
        khung = new KhungTrangThai(view, viewModel::taiLai);
        khung.datChuTrong(R.string.trong_nha_cung_cap);
        adapter = new NhaCungCapAdapter(ncc ->
                ((MainActivity) requireActivity()).moManHinh(ChiTietNhaCungCapFragment.newInstance(ncc.id)));
        rv.setLayoutManager(new LinearLayoutManager(requireContext()));
        rv.setAdapter(adapter);

        BoLoc.caiDat(view.findViewById(R.id.spLoc), R.array.trang_thai_nhan, R.array.trang_thai_gia_tri,
                viewModel::chonLoc);

        viewModel.getDanhSach().observe(getViewLifecycleOwner(), this::hienThi);
        ManHinh.quanSatChung(this, viewModel);
        getParentFragmentManager().setFragmentResultListener(KET_QUA_CAP_NHAT, getViewLifecycleOwner(),
                (k, b) -> viewModel.taiLai());
    }

    private void hienThi(TrangThai<List<NhaCungCap>> tt) {
        if (tt.loai == TrangThai.Loai.THANH_CONG) adapter.capNhat(tt.duLieu);
        khung.hien(tt, rv, tt.duLieu == null || tt.duLieu.isEmpty());
    }
}
