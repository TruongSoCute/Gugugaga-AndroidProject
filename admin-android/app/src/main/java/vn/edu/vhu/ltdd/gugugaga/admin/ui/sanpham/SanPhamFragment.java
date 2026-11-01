package vn.edu.vhu.ltdd.gugugaga.admin.ui.sanpham;

import android.os.Bundle;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.AdapterView;
import android.widget.ArrayAdapter;
import android.widget.ProgressBar;
import android.widget.Spinner;
import android.widget.TextView;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.fragment.app.Fragment;
import androidx.fragment.app.FragmentManager;
import androidx.lifecycle.ViewModelProvider;
import androidx.recyclerview.widget.LinearLayoutManager;
import androidx.recyclerview.widget.RecyclerView;

import com.google.android.material.snackbar.Snackbar;

import java.util.List;

import vn.edu.vhu.ltdd.gugugaga.admin.AppConfig;
import vn.edu.vhu.ltdd.gugugaga.admin.R;
import vn.edu.vhu.ltdd.gugugaga.admin.data.TokenStore;
import vn.edu.vhu.ltdd.gugugaga.admin.model.SanPham;
import vn.edu.vhu.ltdd.gugugaga.admin.ui.MainActivity;
import vn.edu.vhu.ltdd.gugugaga.admin.ui.chung.TrangThai;

/**
 * Màn hình 2: danh sách sản phẩm cho quản trị, lọc theo trạng thái duyệt.
 * QUAN_TRI duyệt (chọn hạng sao) hoặc từ chối (ghi lý do); NHAN_VIEN chỉ xem (C.1 #2).
 * Hiển thị đủ 3 trạng thái gọi API: đang tải / có dữ liệu (hoặc trống) / lỗi + Thử lại (C.1 #8).
 */
public class SanPhamFragment extends Fragment implements SanPhamAdapter.HanhDong {
    private SanPhamViewModel viewModel;
    private SanPhamAdapter adapter;
    private RecyclerView rv;
    private ProgressBar progress;
    private TextView tvTrong;
    private View khungLoi;
    private TextView tvLoi;

    @Nullable
    @Override
    public View onCreateView(@NonNull LayoutInflater inflater, @Nullable ViewGroup container,
                             @Nullable Bundle savedInstanceState) {
        return inflater.inflate(R.layout.fragment_san_pham, container, false);
    }

    @Override
    public void onViewCreated(@NonNull View view, @Nullable Bundle savedInstanceState) {
        rv = view.findViewById(R.id.rvSanPham);
        progress = view.findViewById(R.id.progress);
        tvTrong = view.findViewById(R.id.tvTrong);
        khungLoi = view.findViewById(R.id.khungLoi);
        tvLoi = view.findViewById(R.id.tvLoi);
        view.findViewById(R.id.btnThuLai).setOnClickListener(v -> viewModel.taiLai());

        boolean quanTri = AppConfig.VAI_TRO_QUAN_TRI.equals(TokenStore.layVaiTro(requireContext()));
        adapter = new SanPhamAdapter(quanTri, this);
        rv.setLayoutManager(new LinearLayoutManager(requireContext()));
        rv.setAdapter(adapter);

        viewModel = new ViewModelProvider(this).get(SanPhamViewModel.class);
        caiDatSpinner(view.findViewById(R.id.spLoc));

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
    }

    /** Spinner + ArrayAdapter đổ dữ liệu từ arrays.xml (Lab A6). */
    private void caiDatSpinner(Spinner sp) {
        ArrayAdapter<CharSequence> a = ArrayAdapter.createFromResource(requireContext(),
                R.array.trang_thai_nhan, android.R.layout.simple_spinner_item);
        a.setDropDownViewResource(android.R.layout.simple_spinner_dropdown_item);
        sp.setAdapter(a);
        String[] giaTri = getResources().getStringArray(R.array.trang_thai_gia_tri);
        // OnItemSelectedListener có 2 phương thức nên không viết bằng lambda được (Lab A6).
        sp.setOnItemSelectedListener(new AdapterView.OnItemSelectedListener() {
            @Override
            public void onItemSelected(AdapterView<?> parent, View view, int position, long id) {
                String loc = giaTri[position];
                viewModel.chonLoc(loc.isEmpty() ? null : loc);
            }

            @Override
            public void onNothingSelected(AdapterView<?> parent) { }
        });
    }

    private void hienThi(TrangThai<List<SanPham>> tt) {
        progress.setVisibility(tt.loai == TrangThai.Loai.DANG_TAI ? View.VISIBLE : View.GONE);
        khungLoi.setVisibility(tt.loai == TrangThai.Loai.LOI ? View.VISIBLE : View.GONE);
        boolean coDuLieu = tt.loai == TrangThai.Loai.THANH_CONG;
        if (coDuLieu) adapter.capNhat(tt.duLieu);
        boolean rong = coDuLieu && (tt.duLieu == null || tt.duLieu.isEmpty());
        rv.setVisibility(coDuLieu && !rong ? View.VISIBLE : View.GONE);
        tvTrong.setVisibility(rong ? View.VISIBLE : View.GONE);
        if (tt.loai == TrangThai.Loai.LOI) tvLoi.setText(tt.thongDiep);
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
