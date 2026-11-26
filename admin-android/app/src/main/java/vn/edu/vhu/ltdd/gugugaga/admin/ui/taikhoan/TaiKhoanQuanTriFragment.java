package vn.edu.vhu.ltdd.gugugaga.admin.ui.taikhoan;

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

import com.google.android.material.dialog.MaterialAlertDialogBuilder;
import com.google.android.material.floatingactionbutton.ExtendedFloatingActionButton;

import java.util.List;

import vn.edu.vhu.ltdd.gugugaga.admin.R;
import vn.edu.vhu.ltdd.gugugaga.admin.data.TokenStore;
import vn.edu.vhu.ltdd.gugugaga.admin.model.NguoiDung;
import vn.edu.vhu.ltdd.gugugaga.admin.ui.MainActivity;
import vn.edu.vhu.ltdd.gugugaga.admin.ui.chung.ChanTaiThem;
import vn.edu.vhu.ltdd.gugugaga.admin.ui.chung.KhungTrangThai;
import vn.edu.vhu.ltdd.gugugaga.admin.ui.chung.ManHinh;
import vn.edu.vhu.ltdd.gugugaga.admin.ui.chung.TrangThai;

/** Màn hình quản lý tài khoản nhân sự (chỉ QUAN_TRI, mở từ tab Tài khoản). */
public class TaiKhoanQuanTriFragment extends Fragment {
    private TaiKhoanQuanTriViewModel viewModel;
    private TaiKhoanAdapter adapter;
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
        ((MainActivity) requireActivity()).datTieuDe(R.string.tieu_de_tai_khoan_quan_tri);
        viewModel = new ViewModelProvider(this).get(TaiKhoanQuanTriViewModel.class);

        view.findViewById(R.id.khungLoc).setVisibility(View.GONE);
        ExtendedFloatingActionButton fab = view.findViewById(R.id.fabThem);
        fab.setText(R.string.nut_tao_nhan_vien);
        fab.setVisibility(View.VISIBLE);
        fab.setOnClickListener(v -> new TaoNhanVienDialog().show(getChildFragmentManager(), "tao_nhan_vien"));

        rv = view.findViewById(R.id.rvDanhSach);
        khung = new KhungTrangThai(view, viewModel::taiLai);
        khung.datChuTrong(R.string.trong_tai_khoan);
        adapter = new TaiKhoanAdapter(TokenStore.layEmail(requireContext()), this::xacNhanKhoaMo);
        rv.setLayoutManager(new LinearLayoutManager(requireContext()));
        rv.setAdapter(adapter);
        ChanTaiThem.gan(this, view, rv, viewModel);

        viewModel.getDanhSach().observe(getViewLifecycleOwner(), this::hienThi);
        ManHinh.quanSatChung(this, viewModel);
        viewModel.taiLanDau();
    }

    private void xacNhanKhoaMo(NguoiDung u) {
        boolean moKhoa = !u.dangHoatDong;
        new MaterialAlertDialogBuilder(requireContext())
                .setMessage(getString(moKhoa ? R.string.xac_nhan_mo_tai_khoan : R.string.xac_nhan_khoa_tai_khoan, u.email))
                .setPositiveButton(moKhoa ? R.string.nut_mo_tai_khoan : R.string.nut_khoa_tai_khoan,
                        (d, w) -> viewModel.capNhatTrangThai(u, moKhoa))
                .setNegativeButton(R.string.nut_huy, null)
                .show();
    }

    private void hienThi(TrangThai<List<NguoiDung>> tt) {
        if (tt.loai == TrangThai.Loai.THANH_CONG) adapter.capNhat(tt.duLieu);
        khung.hien(tt, rv, tt.duLieu == null || tt.duLieu.isEmpty());
    }
}
