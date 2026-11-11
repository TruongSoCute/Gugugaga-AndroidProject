
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
import android.widget.Toast;

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

public class SanPhamFragment extends Fragment
        implements SanPhamAdapter.HanhDong {

    private SanPhamViewModel viewModel;
    private SanPhamAdapter adapter;

    private RecyclerView rv;
    private ProgressBar progress;
    private ProgressBar progressTaiThem;

    private TextView tvTrong;
    private View khungLoi;
    private TextView tvLoi;

    @Nullable
    @Override
    public View onCreateView(
            @NonNull LayoutInflater inflater,
            @Nullable ViewGroup container,
            @Nullable Bundle savedInstanceState
    ) {
        return inflater.inflate(
                R.layout.fragment_san_pham,
                container,
                false
        );
    }

    @Override
    public void onViewCreated(
            @NonNull View view,
            @Nullable Bundle savedInstanceState
    ) {
        super.onViewCreated(view, savedInstanceState);

        ((MainActivity) requireActivity())
                .datTieuDe(R.string.tieu_de_san_pham);

        rv = view.findViewById(R.id.rvSanPham);
        progress = view.findViewById(R.id.progress);
        progressTaiThem = view.findViewById(R.id.progressTaiThem);
        tvTrong = view.findViewById(R.id.tvTrong);
        khungLoi = view.findViewById(R.id.khungLoi);
        tvLoi = view.findViewById(R.id.tvLoi);

        viewModel = new ViewModelProvider(this)
                .get(SanPhamViewModel.class);

        view.findViewById(R.id.btnThuLai)
                .setOnClickListener(v -> viewModel.taiLai());

        boolean quanTri = AppConfig.VAI_TRO_QUAN_TRI.equals(
                TokenStore.layVaiTro(requireContext())
        );

        // Khởi tạo Adapter và RecyclerView.
        adapter = new SanPhamAdapter(quanTri, this);

        LinearLayoutManager layoutManager =
                new LinearLayoutManager(requireContext());

        rv.setLayoutManager(layoutManager);
        rv.setAdapter(adapter);

        // Tự động tải trang tiếp theo khi cuộn gần cuối.
        rv.addOnScrollListener(new RecyclerView.OnScrollListener() {

            @Override
            public void onScrolled(
                    @NonNull RecyclerView recyclerView,
                    int dx,
                    int dy
            ) {
                super.onScrolled(recyclerView, dx, dy);

                if (dy <= 0) {
                    return;
                }

                int tongSoDong = layoutManager.getItemCount();
                int dongCuoi = layoutManager.findLastVisibleItemPosition();

                if (tongSoDong > 0
                        && dongCuoi >= tongSoDong - 5) {

                    Toast.makeText(
                            requireContext(),
                            "ĐÃ CHẠM CUỐI DANH SÁCH",
                            Toast.LENGTH_SHORT
                    ).show();

                    viewModel.taiTrangTiepTheo();
                }
            }
        });

        // Thiết lập bộ lọc trạng thái.
        caiDatSpinner(view.findViewById(R.id.spLoc));

        // Quan sát danh sách sản phẩm.
        viewModel.getDanhSach().observe(
                getViewLifecycleOwner(),
                this::hienThi
        );

        // Quan sát thông báo.
        viewModel.getThongBao().observe(
                getViewLifecycleOwner(),
                sk -> {
                    if (sk == null) return;

                    String tb = sk.layNeuChuaXuLy();

                    if (tb != null) {
                        Snackbar.make(
                                view,
                                tb,
                                Snackbar.LENGTH_LONG
                        ).show();
                    }
                }
        );

        // Quan sát trạng thái hết phiên.
        viewModel.getHetPhien().observe(
                getViewLifecycleOwner(),
                het -> {
                    if (Boolean.TRUE.equals(het)) {
                        ((MainActivity) requireActivity())
                                .dangXuat(true);
                    }
                }
        );

        // Hiển thị loading khi tải trang tiếp theo.
        viewModel.getDangTaiThem().observe(
                getViewLifecycleOwner(),
                dangTai -> {
                    progressTaiThem.setVisibility(
                            Boolean.TRUE.equals(dangTai)
                                    ? View.VISIBLE
                                    : View.GONE
                    );
                }
        );

        // Hiển thị lỗi tải thêm và cho phép thử lại.
        viewModel.getLoiTaiThem().observe(
                getViewLifecycleOwner(),
                loi -> {
                    if (loi != null && !loi.isEmpty()) {
                        Snackbar.make(
                                view,
                                loi,
                                Snackbar.LENGTH_LONG
                        ).setAction(
                                "Thử lại",
                                v -> viewModel.taiTrangTiepTheo()
                        ).show();
                    }
                }
        );

        // Nhận kết quả từ hộp thoại duyệt sản phẩm.
        FragmentManager fm = getChildFragmentManager();

        fm.setFragmentResultListener(
                DuyetSanPhamDialog.REQUEST_KEY,
                getViewLifecycleOwner(),
                (k, b) -> viewModel.duyet(
                        b.getInt(DuyetSanPhamDialog.KEY_ID),
                        b.getString(DuyetSanPhamDialog.KEY_TEN),
                        b.getInt(DuyetSanPhamDialog.KEY_HANG_SAO)
                )
        );

        // Nhận kết quả từ hộp thoại từ chối sản phẩm.
        fm.setFragmentResultListener(
                TuChoiSanPhamDialog.REQUEST_KEY,
                getViewLifecycleOwner(),
                (k, b) -> viewModel.tuChoi(
                        b.getInt(TuChoiSanPhamDialog.KEY_ID),
                        b.getString(TuChoiSanPhamDialog.KEY_TEN),
                        b.getString(TuChoiSanPhamDialog.KEY_LY_DO)
                )
        );
    }

    /**
     * Thiết lập Spinner lọc trạng thái.
     */
    private void caiDatSpinner(Spinner sp) {

        ArrayAdapter<CharSequence> a =
                ArrayAdapter.createFromResource(
                        requireContext(),
                        R.array.trang_thai_nhan,
                        android.R.layout.simple_spinner_item
                );

        a.setDropDownViewResource(
                android.R.layout.simple_spinner_dropdown_item
        );

        sp.setAdapter(a);

        String[] giaTri =
                getResources().getStringArray(
                        R.array.trang_thai_gia_tri
                );

        sp.setOnItemSelectedListener(
                new AdapterView.OnItemSelectedListener() {

                    @Override
                    public void onItemSelected(
                            AdapterView<?> parent,
                            View view,
                            int position,
                            long id
                    ) {
                        String loc = giaTri[position];

                        viewModel.chonLoc(
                                loc.isEmpty() ? null : loc
                        );
                    }

                    @Override
                    public void onNothingSelected(
                            AdapterView<?> parent
                    ) {
                    }
                }
        );
    }

    /**
     * Hiển thị dữ liệu và trạng thái màn hình.
     */
    private void hienThi(TrangThai<List<SanPham>> tt) {

        if (tt == null) return;

        // Khi tải lại hoặc đổi bộ lọc, xóa dữ liệu cũ.
        if (tt.loai == TrangThai.Loai.DANG_TAI) {
            adapter.capNhat(null);
        }

        progress.setVisibility(
                tt.loai == TrangThai.Loai.DANG_TAI
                        ? View.VISIBLE
                        : View.GONE
        );

        khungLoi.setVisibility(
                tt.loai == TrangThai.Loai.LOI
                        ? View.VISIBLE
                        : View.GONE
        );

        boolean coDuLieu =
                tt.loai == TrangThai.Loai.THANH_CONG;

        if (coDuLieu) {

            List<SanPham> moi = tt.duLieu;

            int soLuongHienTai = adapter.getItemCount();

            if (moi == null) {
                adapter.capNhat(null);

            } else if (moi.size() > soLuongHienTai) {

                // Nối thêm dữ liệu trang mới.
                adapter.themNhieu(
                        moi.subList(
                                soLuongHienTai,
                                moi.size()
                        )
                );

            } else {

                // Thay danh sách khi tải lại hoặc đổi bộ lọc.
                adapter.capNhat(moi);
            }
        }

        boolean rong = coDuLieu
                && (tt.duLieu == null || tt.duLieu.isEmpty());

        rv.setVisibility(
                coDuLieu && !rong
                        ? View.VISIBLE
                        : View.GONE
        );

        tvTrong.setVisibility(
                rong
                        ? View.VISIBLE
                        : View.GONE
        );

        if (tt.loai == TrangThai.Loai.LOI) {
            tvLoi.setText(tt.thongDiep);
        }
    }

    @Override
    public void onDuyet(SanPham sp) {
        DuyetSanPhamDialog.newInstance(sp.id, sp.ten)
                .show(getChildFragmentManager(), "duyet");
    }

    @Override
    public void onTuChoi(SanPham sp) {
        TuChoiSanPhamDialog.newInstance(sp.id, sp.ten)
                .show(getChildFragmentManager(), "tu_choi");
    }
}
