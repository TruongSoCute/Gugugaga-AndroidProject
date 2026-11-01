package vn.edu.vhu.ltdd.gugugaga.admin.ui.lo;

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
import vn.edu.vhu.ltdd.gugugaga.admin.model.LoSanXuat;
import vn.edu.vhu.ltdd.gugugaga.admin.ui.MainActivity;
import vn.edu.vhu.ltdd.gugugaga.admin.ui.chung.KhungTrangThai;
import vn.edu.vhu.ltdd.gugugaga.admin.ui.chung.ManHinh;
import vn.edu.vhu.ltdd.gugugaga.admin.ui.chung.TrangThai;

/**
 * Tab Lô: danh sách lô sản xuất mới nhất. Nút "Tạo lô" mở form; bấm một lô mở chi tiết có ảnh QR.
 * Form và chi tiết báo kết quả về đây bằng Fragment Result API để tải lại (Lab A8).
 */
public class LoFragment extends Fragment {
    public static final String KET_QUA_CAP_NHAT = "cap_nhat_lo";
    /** Thông báo kèm kết quả (vd "Đã tạo lô ..."), hiện bằng Snackbar ở danh sách. */
    public static final String KEY_THONG_BAO = "thong_bao";

    private LoViewModel viewModel;
    private LoAdapter adapter;
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
        main.datTieuDe(R.string.tieu_de_lo);
        viewModel = new ViewModelProvider(this).get(LoViewModel.class);

        // Danh sách lô không có bộ lọc trạng thái.
        view.findViewById(R.id.tvNhanLoc).setVisibility(View.GONE);
        view.findViewById(R.id.spLoc).setVisibility(View.GONE);
        ExtendedFloatingActionButton fab = view.findViewById(R.id.fabThem);
        fab.setText(R.string.nut_tao_lo);
        fab.setVisibility(View.VISIBLE);
        fab.setOnClickListener(v -> main.moManHinh(new TaoLoFragment()));

        rv = view.findViewById(R.id.rvDanhSach);
        khung = new KhungTrangThai(view, viewModel::taiLai);
        khung.datChuTrong(R.string.trong_lo);
        adapter = new LoAdapter(lo -> main.moManHinh(ChiTietLoFragment.newInstance(lo.id)));
        rv.setLayoutManager(new LinearLayoutManager(requireContext()));
        rv.setAdapter(adapter);

        viewModel.getDanhSach().observe(getViewLifecycleOwner(), this::hienThi);
        ManHinh.quanSatChung(this, viewModel);
        getParentFragmentManager().setFragmentResultListener(KET_QUA_CAP_NHAT, getViewLifecycleOwner(), (k, b) -> {
            String tb = b.getString(KEY_THONG_BAO);
            if (tb != null) ManHinh.baoSnackbar(this, tb);
            viewModel.taiLai();
        });
        viewModel.taiLanDau();
    }

    private void hienThi(TrangThai<List<LoSanXuat>> tt) {
        if (tt.loai == TrangThai.Loai.THANH_CONG) adapter.capNhat(tt.duLieu);
        khung.hien(tt, rv, tt.duLieu == null || tt.duLieu.isEmpty());
    }
}
