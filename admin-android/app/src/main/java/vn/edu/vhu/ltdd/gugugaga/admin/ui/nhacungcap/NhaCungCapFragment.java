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
import vn.edu.vhu.ltdd.gugugaga.admin.ui.chung.ChanTaiThem;
import vn.edu.vhu.ltdd.gugugaga.admin.ui.chung.KhungTrangThai;
import vn.edu.vhu.ltdd.gugugaga.admin.ui.chung.ManHinh;
import vn.edu.vhu.ltdd.gugugaga.admin.ui.chung.TrangThai;

/** Danh sách hồ sơ nhà cung cấp (mở từ tab Tài khoản), lọc theo trạng thái duyệt. */
public class NhaCungCapFragment extends Fragment {
    public static final String KET_QUA_CAP_NHAT = "cap_nhat_nha_cung_cap";
    public static final String KEY_THONG_BAO = "thong_bao";

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
        MainActivity main = (MainActivity) requireActivity();
        main.datTieuDe(R.string.tieu_de_nha_cung_cap);
        viewModel = new ViewModelProvider(this).get(NhaCungCapViewModel.class);

        com.google.android.material.floatingactionbutton.ExtendedFloatingActionButton fab =
                view.findViewById(R.id.fabThem);
        fab.setText(R.string.nut_them_nha_cung_cap);
        fab.setVisibility(View.VISIBLE);
        fab.setOnClickListener(v -> main.moManHinh(new TaoNhaCungCapFragment()));

        rv = view.findViewById(R.id.rvDanhSach);
        khung = new KhungTrangThai(view, viewModel::taiLai);
        khung.datChuTrong(R.string.trong_nha_cung_cap);
        adapter = new NhaCungCapAdapter(ncc ->
                ((MainActivity) requireActivity()).moManHinh(ChiTietNhaCungCapFragment.newInstance(ncc.id)));
        rv.setLayoutManager(new LinearLayoutManager(requireContext()));
        rv.setAdapter(adapter);
        ChanTaiThem.gan(this, view, rv, viewModel); // cuộn gần cuối thì tải trang sau

        BoLoc.caiDat(view.findViewById(R.id.spLoc), R.array.trang_thai_nhan, R.array.trang_thai_gia_tri,
                viewModel::chonLoc);

        viewModel.getDanhSach().observe(getViewLifecycleOwner(), this::hienThi);
        ManHinh.quanSatChung(this, viewModel);
        getParentFragmentManager().setFragmentResultListener(KET_QUA_CAP_NHAT, getViewLifecycleOwner(), (k, b) -> {
            String tb = b.getString(KEY_THONG_BAO);
            if (tb != null) ManHinh.baoSnackbar(this, tb);
            viewModel.taiLai();
        });
    }

    private void hienThi(TrangThai<List<NhaCungCap>> tt) {
        if (tt.loai == TrangThai.Loai.THANH_CONG) adapter.capNhat(tt.duLieu);
        khung.hien(tt, rv, tt.duLieu == null || tt.duLieu.isEmpty());
    }
}
