package vn.edu.vhu.ltdd.gugugaga.admin.ui.sanpham;

import android.os.Bundle;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.fragment.app.Fragment;
import androidx.fragment.app.FragmentManager;
import androidx.lifecycle.ViewModelProvider;
import androidx.recyclerview.widget.LinearLayoutManager;
import androidx.recyclerview.widget.RecyclerView;

import com.google.android.material.floatingactionbutton.ExtendedFloatingActionButton;
import com.google.android.material.snackbar.Snackbar;

import java.util.List;

import vn.edu.vhu.ltdd.gugugaga.admin.AppConfig;
import vn.edu.vhu.ltdd.gugugaga.admin.R;
import vn.edu.vhu.ltdd.gugugaga.admin.data.TokenStore;
import vn.edu.vhu.ltdd.gugugaga.admin.model.SanPham;
import vn.edu.vhu.ltdd.gugugaga.admin.ui.MainActivity;
import vn.edu.vhu.ltdd.gugugaga.admin.ui.chung.BoLoc;
import vn.edu.vhu.ltdd.gugugaga.admin.ui.chung.ChanTaiThem;
import vn.edu.vhu.ltdd.gugugaga.admin.ui.chung.ChuyenDong;
import vn.edu.vhu.ltdd.gugugaga.admin.ui.chung.KhungTrangThai;
import vn.edu.vhu.ltdd.gugugaga.admin.ui.chung.TrangThai;

/**
 * Màn hình 2: danh sách sản phẩm cho quản trị, lọc theo trạng thái duyệt bằng ChipGroup M3.
 * QUAN_TRI duyệt (chọn hạng sao) hoặc từ chối (ghi lý do); NHAN_VIEN chỉ xem (C.1 #2).
 * Hiển thị đủ 3 trạng thái gọi API: đang tải / có dữ liệu (hoặc trống) / lỗi + Thử lại (C.1 #8).
 */
public class SanPhamFragment extends Fragment implements SanPhamAdapter.HanhDong {
    public static final String KET_QUA_CAP_NHAT = "cap_nhat_san_pham";
    public static final String KEY_THONG_BAO = "thong_bao";

    private SanPhamViewModel viewModel;
    private SanPhamAdapter adapter;
    private RecyclerView rv;
    private KhungTrangThai khung;

    @Nullable
    @Override
    public View onCreateView(@NonNull LayoutInflater inflater, @Nullable ViewGroup container,
                             @Nullable Bundle savedInstanceState) {
        return inflater.inflate(R.layout.fragment_san_pham, container, false);
    }

    @Override
    public void onViewCreated(@NonNull View view, @Nullable Bundle savedInstanceState) {
        ((MainActivity) requireActivity()).datTieuDe(R.string.tieu_de_san_pham);
        ExtendedFloatingActionButton fab = view.findViewById(R.id.fabThem);
        fab.setOnClickListener(v -> ((MainActivity) requireActivity()).moManHinh(new TaoSanPhamFragment()));
        ChuyenDong.ganNhanNhe(fab);
        rv = view.findViewById(R.id.rvSanPham);
        ChuyenDong.ganThuGonFab(rv, fab);

        boolean quanTri = AppConfig.VAI_TRO_QUAN_TRI.equals(TokenStore.layVaiTro(requireContext()));
        adapter = new SanPhamAdapter(quanTri, this);
        rv.setLayoutManager(new LinearLayoutManager(requireContext()));
        rv.setAdapter(adapter);

        viewModel = new ViewModelProvider(this).get(SanPhamViewModel.class);
        khung = new KhungTrangThai(view, viewModel::taiLai);
        khung.datChuTrong(R.string.danh_sach_trong);
        ChanTaiThem.gan(this, view, rv, viewModel); // cuộn gần cuối thì tải trang sau
        BoLoc.caiDatChip(view.findViewById(R.id.cgLoc), R.array.trang_thai_nhan,
                R.array.trang_thai_gia_tri, viewModel::chonLoc);

        viewModel.getDanhSach().observe(getViewLifecycleOwner(), this::hienThi);
        viewModel.getThongBao().observe(getViewLifecycleOwner(), sk -> {
            String tb = sk.layNeuChuaXuLy();
            if (tb != null) Snackbar.make(view, tb, Snackbar.LENGTH_LONG).show();
        });
        viewModel.getHetPhien().observe(getViewLifecycleOwner(), het -> {
            if (Boolean.TRUE.equals(het)) ((MainActivity) requireActivity()).dangXuat(true);
        });

        // Nhận kết quả từ hai hộp thoại (Fragment Result API, Lab A8).
        FragmentManager fm = getChildFragmentManager();
        fm.setFragmentResultListener(DuyetSanPhamDialog.REQUEST_KEY, getViewLifecycleOwner(), (k, b) ->
                viewModel.duyet(b.getInt(DuyetSanPhamDialog.KEY_ID), b.getString(DuyetSanPhamDialog.KEY_TEN),
                        b.getInt(DuyetSanPhamDialog.KEY_HANG_SAO)));
        fm.setFragmentResultListener(TuChoiSanPhamDialog.REQUEST_KEY, getViewLifecycleOwner(), (k, b) ->
                viewModel.tuChoi(b.getInt(TuChoiSanPhamDialog.KEY_ID), b.getString(TuChoiSanPhamDialog.KEY_TEN),
                        b.getString(TuChoiSanPhamDialog.KEY_LY_DO)));
        getParentFragmentManager().setFragmentResultListener(KET_QUA_CAP_NHAT, getViewLifecycleOwner(), (k, b) -> {
            String tb = b.getString(KEY_THONG_BAO);
            if (tb != null) Snackbar.make(view, tb, Snackbar.LENGTH_LONG).show();
            viewModel.taiLai();
        });
    }

    private void hienThi(TrangThai<List<SanPham>> tt) {
        if (tt.loai == TrangThai.Loai.THANH_CONG) adapter.capNhat(tt.duLieu);
        khung.hien(tt, rv, tt.duLieu == null || tt.duLieu.isEmpty());
    }

    @Override
    public void onDuyet(SanPham sp) {
        DuyetSanPhamDialog.newInstance(sp.id, sp.ten).show(getChildFragmentManager(), "duyet");
    }

    @Override
    public void onTuChoi(SanPham sp) {
        TuChoiSanPhamDialog.newInstance(sp.id, sp.ten).show(getChildFragmentManager(), "tu_choi");
    }
}
