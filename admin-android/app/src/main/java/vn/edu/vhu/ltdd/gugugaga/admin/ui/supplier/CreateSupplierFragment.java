package vn.edu.vhu.ltdd.gugugaga.admin.ui.supplier;

import android.app.DatePickerDialog;
import android.graphics.Bitmap;
import android.net.Uri;
import android.os.Bundle;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.AdapterView;
import android.widget.ArrayAdapter;
import android.widget.Button;
import android.widget.ImageView;
import android.widget.ProgressBar;
import android.widget.Spinner;
import android.widget.TextView;

import androidx.activity.result.ActivityResultLauncher;
import androidx.activity.result.PickVisualMediaRequest;
import androidx.activity.result.contract.ActivityResultContracts.PickVisualMedia;
import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.fragment.app.Fragment;
import androidx.lifecycle.ViewModelProvider;

import com.google.android.material.textfield.TextInputEditText;
import com.google.android.material.textfield.TextInputLayout;

import java.util.ArrayList;
import java.util.Calendar;
import java.util.Collections;
import java.util.List;
import java.util.Locale;
import java.util.Map;

import vn.edu.vhu.ltdd.gugugaga.admin.R;
import vn.edu.vhu.ltdd.gugugaga.admin.data.ImageRepository;
import vn.edu.vhu.ltdd.gugugaga.admin.data.ApiResult;
import vn.edu.vhu.ltdd.gugugaga.admin.model.SourcingRegion;
import vn.edu.vhu.ltdd.gugugaga.admin.model.CreateSupplierRequest;
import vn.edu.vhu.ltdd.gugugaga.admin.ui.MainActivity;
import vn.edu.vhu.ltdd.gugugaga.admin.ui.common.StatePanel;
import vn.edu.vhu.ltdd.gugugaga.admin.ui.common.ScreenLayout;
import vn.edu.vhu.ltdd.gugugaga.admin.ui.common.UiState;
import vn.edu.vhu.ltdd.gugugaga.admin.util.FormValidation;

/**
 * Form tạo hồ sơ nhà cung cấp kèm chứng nhận (Issue #13).
 * Giữ dữ liệu khi xoay màn hình bằng EditText ID + onSaveInstanceState (Lab A2).
 */
public class CreateSupplierFragment extends Fragment {
    private static final String KEY_VUNG_ID = "vung_id";
    private static final String KEY_NGAY_CAP = "ngay_cap";
    private static final String KEY_NGAY_HET_HAN = "ngay_het_han";

    private CreateSupplierViewModel viewModel;
    private ImageRepository anhRepo;
    private StatePanel khung;
    private View noiDung;
    private Spinner spVung;
    private TextView tvLoiVung;
    private TextInputLayout tilTen, tilNguoiDaiDien, tilSoDienThoai, tilDiaChi, tilAnhCoSo;
    private TextInputLayout tilLoaiCn, tilSoHieuCn, tilNgayCap, tilNgayHetHan, tilAnhCn;
    private TextInputEditText edtTen, edtNguoiDaiDien, edtSoDienThoai, edtDiaChi, edtAnhCoSo;
    private TextInputEditText edtLoaiCn, edtSoHieuCn, edtNgayCap, edtNgayHetHan, edtAnhCn;
    private Button btnChonAnhCoSo, btnChonAnhCn, btnLuu;
    private ProgressBar progressAnhCoSo, progressAnhCn, progressLuu;
    private ImageView ivAnhCoSo, ivAnhCn;

    private final List<Integer> idVung = new ArrayList<>();
    private int vungIdDaChon = -1;
    private String ngayCap;
    private String ngayHetHan;
    private boolean dangLuu;

    private final ActivityResultLauncher<PickVisualMediaRequest> chonAnhCoSoLauncher =
            registerForActivityResult(new PickVisualMedia(), uri -> taiAnh(uri, true));
    private final ActivityResultLauncher<PickVisualMediaRequest> chonAnhCnLauncher =
            registerForActivityResult(new PickVisualMedia(), uri -> taiAnh(uri, false));

    @Nullable
    @Override
    public View onCreateView(@NonNull LayoutInflater inflater, @Nullable ViewGroup container,
                             @Nullable Bundle savedInstanceState) {
        return inflater.inflate(R.layout.fragment_create_supplier, container, false);
    }

    @Override
    public void onViewCreated(@NonNull View view, @Nullable Bundle savedInstanceState) {
        ((MainActivity) requireActivity()).datTieuDe(R.string.tieu_de_tao_nha_cung_cap);
        if (savedInstanceState != null) {
            vungIdDaChon = savedInstanceState.getInt(KEY_VUNG_ID, -1);
            ngayCap = savedInstanceState.getString(KEY_NGAY_CAP);
            ngayHetHan = savedInstanceState.getString(KEY_NGAY_HET_HAN);
        }

        anhXa(view);
        anhRepo = new ImageRepository(requireContext());
        viewModel = new ViewModelProvider(this).get(CreateSupplierViewModel.class);
        khung = new StatePanel(view, viewModel::taiVung);

        if (ngayCap != null) edtNgayCap.setText(ngayCap);
        if (ngayHetHan != null) edtNgayHetHan.setText(ngayHetHan);

        edtNgayCap.setOnClickListener(v -> chonNgay(true));
        edtNgayHetHan.setOnClickListener(v -> chonNgay(false));
        btnChonAnhCoSo.setOnClickListener(v -> chonAnhCoSoLauncher.launch(
                new PickVisualMediaRequest.Builder().setMediaType(PickVisualMedia.ImageOnly.INSTANCE).build()));
        btnChonAnhCn.setOnClickListener(v -> chonAnhCnLauncher.launch(
                new PickVisualMediaRequest.Builder().setMediaType(PickVisualMedia.ImageOnly.INSTANCE).build()));
        btnLuu.setOnClickListener(v -> gui());

        viewModel.getDsVung().observe(getViewLifecycleOwner(), this::hienThiVung);
        viewModel.getDaTao().observe(getViewLifecycleOwner(), sk -> {
            if (sk == null) return;
            var ncc = sk.layNeuChuaXuLy();
            if (ncc == null) return;
            Bundle b = new Bundle();
            b.putString(SupplierListFragment.KEY_THONG_BAO, getString(R.string.da_tao_ncc, ncc.ten));
            getParentFragmentManager().setFragmentResult(SupplierListFragment.KET_QUA_CAP_NHAT, b);
            getParentFragmentManager().popBackStack();
        });
        viewModel.getLoiGui().observe(getViewLifecycleOwner(), sk -> {
            if (sk == null) return;
            CreateSupplierViewModel.LoiGui loi = sk.layNeuChuaXuLy();
            if (loi == null) return;
            datDangLuu(false);
            hienLoiBackend(loi);
        });
        ScreenLayout.quanSatChung(this, viewModel);
        viewModel.taiVungLanDau();
    }

    @Override
    public void onSaveInstanceState(@NonNull Bundle outState) {
        super.onSaveInstanceState(outState);
        outState.putInt(KEY_VUNG_ID, vungIdDaChon);
        outState.putString(KEY_NGAY_CAP, ngayCap);
        outState.putString(KEY_NGAY_HET_HAN, ngayHetHan);
    }

    private void anhXa(View v) {
        noiDung = v.findViewById(R.id.noiDung);
        spVung = v.findViewById(R.id.spVung);
        tvLoiVung = v.findViewById(R.id.tvLoiVung);
        tilTen = v.findViewById(R.id.tilTen);
        tilNguoiDaiDien = v.findViewById(R.id.tilNguoiDaiDien);
        tilSoDienThoai = v.findViewById(R.id.tilSoDienThoai);
        tilDiaChi = v.findViewById(R.id.tilDiaChi);
        tilAnhCoSo = v.findViewById(R.id.tilAnhCoSo);
        tilLoaiCn = v.findViewById(R.id.tilLoaiCn);
        tilSoHieuCn = v.findViewById(R.id.tilSoHieuCn);
        tilNgayCap = v.findViewById(R.id.tilNgayCap);
        tilNgayHetHan = v.findViewById(R.id.tilNgayHetHan);
        tilAnhCn = v.findViewById(R.id.tilAnhCn);

        edtTen = v.findViewById(R.id.edtTen);
        edtNguoiDaiDien = v.findViewById(R.id.edtNguoiDaiDien);
        edtSoDienThoai = v.findViewById(R.id.edtSoDienThoai);
        edtDiaChi = v.findViewById(R.id.edtDiaChi);
        edtAnhCoSo = v.findViewById(R.id.edtAnhCoSo);
        edtLoaiCn = v.findViewById(R.id.edtLoaiCn);
        edtSoHieuCn = v.findViewById(R.id.edtSoHieuCn);
        edtNgayCap = v.findViewById(R.id.edtNgayCap);
        edtNgayHetHan = v.findViewById(R.id.edtNgayHetHan);
        edtAnhCn = v.findViewById(R.id.edtAnhCn);

        btnChonAnhCoSo = v.findViewById(R.id.btnChonAnhCoSo);
        btnChonAnhCn = v.findViewById(R.id.btnChonAnhCn);
        btnLuu = v.findViewById(R.id.btnLuu);
        progressAnhCoSo = v.findViewById(R.id.progressAnhCoSo);
        progressAnhCn = v.findViewById(R.id.progressAnhCn);
        progressLuu = v.findViewById(R.id.progressLuu);
        ivAnhCoSo = v.findViewById(R.id.ivAnhCoSo);
        ivAnhCn = v.findViewById(R.id.ivAnhCn);
    }

    private void hienThiVung(UiState<List<SourcingRegion>> tt) {
        khung.hien(tt, noiDung, tt.duLieu != null && tt.duLieu.isEmpty());
        if (tt.loai != UiState.Loai.THANH_CONG || tt.duLieu == null) return;

        List<String> nhan = new ArrayList<>();
        idVung.clear();
        nhan.add(getString(R.string.chon_vung));
        idVung.add(-1);
        int chon = 0;
        for (SourcingRegion v : tt.duLieu) {
            nhan.add(v.ten);
            idVung.add(v.id);
            if (v.id == vungIdDaChon) chon = idVung.size() - 1;
        }
        ArrayAdapter<String> a = new ArrayAdapter<>(requireContext(), android.R.layout.simple_spinner_item, nhan);
        a.setDropDownViewResource(android.R.layout.simple_spinner_dropdown_item);
        spVung.setAdapter(a);
        spVung.setSelection(chon);
        spVung.setOnItemSelectedListener(new AdapterView.OnItemSelectedListener() {
            @Override
            public void onItemSelected(AdapterView<?> parent, View view, int pos, long id) {
                vungIdDaChon = idVung.get(pos);
                tvLoiVung.setVisibility(View.GONE);
            }

            @Override
            public void onNothingSelected(AdapterView<?> parent) { }
        });
    }

    private void chonNgay(boolean laNgayCap) {
        Calendar c = Calendar.getInstance();
        new DatePickerDialog(requireContext(), (dp, y, m, d) -> {
            String ngay = String.format(Locale.US, "%04d-%02d-%02d", y, m + 1, d);
            if (laNgayCap) {
                ngayCap = ngay;
                edtNgayCap.setText(ngay);
                tilNgayCap.setError(null);
            } else {
                ngayHetHan = ngay;
                edtNgayHetHan.setText(ngay);
                tilNgayHetHan.setError(null);
            }
        }, c.get(Calendar.YEAR), c.get(Calendar.MONTH), c.get(Calendar.DAY_OF_MONTH)).show();
    }

    private void taiAnh(Uri uri, boolean laCoSo) {
        if (uri == null) return;
        ProgressBar p = laCoSo ? progressAnhCoSo : progressAnhCn;
        Button b = laCoSo ? btnChonAnhCoSo : btnChonAnhCn;
        TextInputEditText edt = laCoSo ? edtAnhCoSo : edtAnhCn;
        ImageView iv = laCoSo ? ivAnhCoSo : ivAnhCn;

        p.setVisibility(View.VISIBLE);
        b.setEnabled(false);
        anhRepo.taiLen(uri, "nha-cung-cap", new ApiResult<String>() {
            @Override
            public void thanhCong(String url) {
                if (!isAdded()) return;
                p.setVisibility(View.GONE);
                b.setEnabled(true);
                edt.setText(url);
                xemTruocAnh(url, iv);
            }

            @Override
            public void hetPhien() {
                if (isAdded()) ((MainActivity) requireActivity()).dangXuat(true);
            }

            @Override
            public void loi(String thongDiep) {
                if (!isAdded()) return;
                p.setVisibility(View.GONE);
                b.setEnabled(true);
                ScreenLayout.baoSnackbar(CreateSupplierFragment.this, thongDiep);
            }
        });
    }

    private void xemTruocAnh(String url, ImageView iv) {
        if (!FormValidation.laUrlWeb(url)) {
            iv.setVisibility(View.GONE);
            return;
        }
        anhRepo.tai(url, new ApiResult<Bitmap>() {
            @Override
            public void thanhCong(Bitmap bmp) {
                if (!isAdded()) return;
                iv.setImageBitmap(bmp);
                iv.setVisibility(View.VISIBLE);
            }

            @Override
            public void loi(String thongDiep) { }

            @Override
            public void hetPhien() { }
        });
    }

    private void gui() {
        if (dangLuu) return;
        xoaLoi();

        String ten = chuoi(edtTen);
        String daiDien = chuoi(edtNguoiDaiDien);
        String sdt = chuoi(edtSoDienThoai);
        String diaChi = chuoi(edtDiaChi);
        String anhCoSo = chuoi(edtAnhCoSo);

        if (ten.isEmpty()) {
            tilTen.setError(getString(R.string.loi_ten_ncc_trong));
            edtTen.requestFocus();
            return;
        }
        if (daiDien.isEmpty()) {
            tilNguoiDaiDien.setError(getString(R.string.loi_nguoi_dai_dien_trong));
            edtNguoiDaiDien.requestFocus();
            return;
        }
        if (!sdt.matches("^[0-9]{9,15}$")) {
            tilSoDienThoai.setError(getString(R.string.loi_sdt_sai));
            edtSoDienThoai.requestFocus();
            return;
        }
        if (diaChi.isEmpty()) {
            tilDiaChi.setError(getString(R.string.loi_dia_chi_trong));
            edtDiaChi.requestFocus();
            return;
        }
        if (vungIdDaChon <= 0) {
            tvLoiVung.setText(R.string.loi_chua_chon_vung);
            tvLoiVung.setVisibility(View.VISIBLE);
            spVung.requestFocus();
            return;
        }
        if (!anhCoSo.isEmpty() && !FormValidation.laUrlWeb(anhCoSo)) {
            tilAnhCoSo.setError(getString(R.string.loi_anh_url_sai));
            edtAnhCoSo.requestFocus();
            return;
        }

        String loaiCn = chuoi(edtLoaiCn);
        String soHieu = chuoi(edtSoHieuCn);
        String cap = chuoi(edtNgayCap);
        String hetHan = chuoi(edtNgayHetHan);
        String anhCn = chuoi(edtAnhCn);
        boolean coNhapCn = !soHieu.isEmpty() || !cap.isEmpty() || !hetHan.isEmpty() || !anhCn.isEmpty();

        List<CreateSupplierRequest.Certificate> dsCn = Collections.emptyList();
        if (coNhapCn) {
            if (loaiCn.isEmpty()) {
                tilLoaiCn.setError(getString(R.string.loi_loai_cn_trong));
                edtLoaiCn.requestFocus();
                return;
            }
            if (soHieu.isEmpty()) {
                tilSoHieuCn.setError(getString(R.string.loi_so_hieu_cn_trong));
                edtSoHieuCn.requestFocus();
                return;
            }
            if (cap.isEmpty()) {
                tilNgayCap.setError(getString(R.string.loi_ngay_cap_trong));
                edtNgayCap.requestFocus();
                return;
            }
            if (!hetHan.isEmpty() && !FormValidation.sauNgay(hetHan, cap)) {
                tilNgayHetHan.setError(getString(R.string.loi_het_han_truoc_ngay_cap));
                edtNgayHetHan.requestFocus();
                return;
            }
            if (!anhCn.isEmpty() && !FormValidation.laUrlWeb(anhCn)) {
                tilAnhCn.setError(getString(R.string.loi_anh_url_sai));
                edtAnhCn.requestFocus();
                return;
            }
            dsCn = Collections.singletonList(new CreateSupplierRequest.Certificate(
                    loaiCn,
                    soHieu,
                    cap,
                    hetHan.isEmpty() ? null : hetHan,
                    anhCn.isEmpty() ? null : anhCn));
        }

        datDangLuu(true);
        viewModel.tao(new CreateSupplierRequest(
                ten, daiDien, sdt, diaChi, vungIdDaChon,
                anhCoSo.isEmpty() ? null : anhCoSo,
                dsCn));
    }

    private void hienLoiBackend(CreateSupplierViewModel.LoiGui loi) {
        Map<String, String> m = loi.loiTheoTruong;
        if (m.containsKey("ten")) tilTen.setError(m.get("ten"));
        if (m.containsKey("nguoiDaiDien")) tilNguoiDaiDien.setError(m.get("nguoiDaiDien"));
        if (m.containsKey("soDienThoai")) tilSoDienThoai.setError(m.get("soDienThoai"));
        if (m.containsKey("diaChi")) tilDiaChi.setError(m.get("diaChi"));
        if (m.containsKey("vungId")) {
            tvLoiVung.setText(m.get("vungId"));
            tvLoiVung.setVisibility(View.VISIBLE);
        }
        if (m.containsKey("anhCoSoUrl")) tilAnhCoSo.setError(m.get("anhCoSoUrl"));
        if (m.containsKey("chungNhan[0].loai")) tilLoaiCn.setError(m.get("chungNhan[0].loai"));
        if (m.containsKey("chungNhan[0].soHieu")) tilSoHieuCn.setError(m.get("chungNhan[0].soHieu"));
        if (m.containsKey("chungNhan[0].ngayCap")) tilNgayCap.setError(m.get("chungNhan[0].ngayCap"));
        if (m.containsKey("chungNhan[0].ngayHetHan")) tilNgayHetHan.setError(m.get("chungNhan[0].ngayHetHan"));
        if (m.containsKey("chungNhan[0].anhUrl")) tilAnhCn.setError(m.get("chungNhan[0].anhUrl"));
        if (m.isEmpty() && loi.thongDiep != null) {
            ScreenLayout.baoSnackbar(this, loi.thongDiep);
        }
    }

    private void xoaLoi() {
        tilTen.setError(null);
        tilNguoiDaiDien.setError(null);
        tilSoDienThoai.setError(null);
        tilDiaChi.setError(null);
        tvLoiVung.setVisibility(View.GONE);
        tilAnhCoSo.setError(null);
        tilLoaiCn.setError(null);
        tilSoHieuCn.setError(null);
        tilNgayCap.setError(null);
        tilNgayHetHan.setError(null);
        tilAnhCn.setError(null);
    }

    private void datDangLuu(boolean b) {
        dangLuu = b;
        btnLuu.setEnabled(!b);
        progressLuu.setVisibility(b ? View.VISIBLE : View.GONE);
    }

    private String chuoi(TextInputEditText edt) {
        return edt.getText() == null ? "" : edt.getText().toString().trim();
    }
}
