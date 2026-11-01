package vn.edu.vhu.ltdd.gugugaga.admin.ui.phananh;

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
import vn.edu.vhu.ltdd.gugugaga.admin.model.PhanAnh;
import vn.edu.vhu.ltdd.gugugaga.admin.ui.MainActivity;
import vn.edu.vhu.ltdd.gugugaga.admin.ui.chung.BoLoc;
import vn.edu.vhu.ltdd.gugugaga.admin.ui.chung.KhungTrangThai;
import vn.edu.vhu.ltdd.gugugaga.admin.ui.chung.ManHinh;
import vn.edu.vhu.ltdd.gugugaga.admin.ui.chung.TrangThai;

/** Tab Phản ánh: phản ánh hàng giả, sai mô tả của khách; phản ánh mới xếp trước. */
public class PhanAnhFragment extends Fragment {
    public static final String KET_QUA_CAP_NHAT = "cap_nhat_phan_anh";

    private PhanAnhViewModel viewModel;
    private PhanAnhAdapter adapter;
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
        ((MainActivity) requireActivity()).datTieuDe(R.string.tieu_de_phan_anh);
        viewModel = new ViewModelProvider(this).get(PhanAnhViewModel.class);

        rv = view.findViewById(R.id.rvDanhSach);
        khung = new KhungTrangThai(view, viewModel::taiLai);
        khung.datChuTrong(R.string.trong_phan_anh);
        adapter = new PhanAnhAdapter(pa ->
                ((MainActivity) requireActivity()).moManHinh(ChiTietPhanAnhFragment.newInstance(pa.id)));
        rv.setLayoutManager(new LinearLayoutManager(requireContext()));
        rv.setAdapter(adapter);

        BoLoc.caiDat(view.findViewById(R.id.spLoc), R.array.phan_anh_nhan, R.array.phan_anh_gia_tri,
                viewModel::chonLoc);

        viewModel.getDanhSach().observe(getViewLifecycleOwner(), this::hienThi);
        ManHinh.quanSatChung(this, viewModel);
        getParentFragmentManager().setFragmentResultListener(KET_QUA_CAP_NHAT, getViewLifecycleOwner(),
                (k, b) -> viewModel.taiLai());
    }

    private void hienThi(TrangThai<List<PhanAnh>> tt) {
        if (tt.loai == TrangThai.Loai.THANH_CONG) adapter.capNhat(tt.duLieu);
        khung.hien(tt, rv, tt.duLieu == null || tt.duLieu.isEmpty());
    }
}
