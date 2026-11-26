package vn.edu.vhu.ltdd.gugugaga.admin.ui.sanpham;

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
import java.util.List;
import java.util.Map;

import vn.edu.vhu.ltdd.gugugaga.admin.R;
import vn.edu.vhu.ltdd.gugugaga.admin.data.AnhRepository;
import vn.edu.vhu.ltdd.gugugaga.admin.data.KetQuaApi;
feature/admin-pagination
import vn.edu.vhu.ltdd.gugugaga.admin.data.NhaCungCapRepository;
import vn.edu.vhu.ltdd.gugugaga.admin.data.SanPhamRepository;
import vn.edu.vhu.ltdd.gugugaga.admin.model.KetQuaTaiAnh;
import vn.edu.vhu.ltdd.gugugaga.admin.model.NhaCungCap;
import vn.edu.vhu.ltdd.gugugaga.admin.model.SanPham;
import vn.edu.vhu.ltdd.gugugaga.admin.model.YeuCauTaoSanPham;
import vn.edu.vhu.ltdd.gugugaga.admin.ui.MainActivity;

public class TaoSanPhamFragment extends Fragment {

    private Spinner spNhaCungCap;

    private EditText edtTenSanPham;
    private EditText edtMoTa;
    private EditText edtDonViTinh;
    private EditText edtGia;

    private ImageView imgAnhSanPham;

    private Button btnChonAnhSanPham;
    private Button btnLuuSanPham;

    private NhaCungCapRepository nhaCungCapRepository;
    private SanPhamRepository sanPhamRepository;
    private AnhRepository anhRepository;

    private final List<NhaCungCap> danhSachNhaCungCap =
            new ArrayList<>();

    private String anhSanPhamUrl;

    private boolean dangTaiAnh = false;
    private boolean daTaiDanhSachNhaCungCap = false;

    private final ExecutorService executor =
            Executors.newSingleThreadExecutor();

    private ActivityResultLauncher<String> chonAnhLauncher;

    @Override
    public void onCreate(@Nullable Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        chonAnhLauncher = registerForActivityResult(
                new ActivityResultContracts.GetContent(),
                uri -> {
                    if (uri != null) {
                        xuLyAnh(uri);
                    }
                }
        );

        if (savedInstanceState != null) {
            anhSanPhamUrl = savedInstanceState.getString("anhSanPhamUrl");
        }
    }

    @Nullable
    @Override
    public View onCreateView(
            @NonNull LayoutInflater inflater,
            @Nullable ViewGroup container,
            @Nullable Bundle savedInstanceState
    ) {
        return inflater.inflate(
                R.layout.fragment_tao_san_pham,
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

        nhaCungCapRepository =
                new NhaCungCapRepository(requireContext());

        sanPhamRepository =
                new SanPhamRepository(requireContext());

        anhRepository =
                new AnhRepository(requireContext());

        spNhaCungCap =
                view.findViewById(R.id.spNhaCungCap);

        edtTenSanPham =
                view.findViewById(R.id.edtTenSanPham);

        edtMoTa =
                view.findViewById(R.id.edtMoTa);

        edtDonViTinh =
                view.findViewById(R.id.edtDonViTinh);

        edtGia =
                view.findViewById(R.id.edtGia);

        imgAnhSanPham =
                view.findViewById(R.id.imgAnhSanPham);

        btnChonAnhSanPham =
                view.findViewById(R.id.btnChonAnhSanPham);

        btnLuuSanPham =
                view.findViewById(R.id.btnLuuSanPham);

        btnChonAnhSanPham.setOnClickListener(v ->
                chonAnhLauncher.launch("image/*")
        );

        btnLuuSanPham.setOnClickListener(v ->
                taoSanPham()
        );

        taiDanhSachNhaCungCap();
    }

    // =====================================
    // TẢI DANH SÁCH NHÀ CUNG CẤP
    // =====================================

    private void taiDanhSachNhaCungCap() {

        nhaCungCapRepository.danhSach(
                null,
                new KetQuaApi<List<NhaCungCap>>() {

                    @Override
                    public void thanhCong(List<NhaCungCap> duLieu) {

                        if (!isAdded()) return;

                        danhSachNhaCungCap.clear();

                        if (duLieu != null) {
                            for (NhaCungCap ncc : duLieu) {

                                if (ncc != null
                                        && "DA_DUYET".equalsIgnoreCase(
                                        ncc.trangThaiDuyet
                                )) {
                                    danhSachNhaCungCap.add(ncc);
                                }
                            }
                        }

                        hienThiDanhSachNhaCungCap();
                    }

                    @Override
                    public void loi(String thongDiep) {

                        if (!isAdded()) return;

                        Toast.makeText(
                                requireContext(),
                                thongDiep,
                                Toast.LENGTH_LONG
                        ).show();
                    }

                    @Override
                    public void hetPhien() {

                        if (!isAdded()) return;

                        Toast.makeText(
                                requireContext(),
                                "Phiên đăng nhập đã hết hạn.",
                                Toast.LENGTH_LONG
                        ).show();
                    }
                }
        );
    }

    private void hienThiDanhSachNhaCungCap() {

        List<String> tenNhaCungCap = new ArrayList<>();

        for (NhaCungCap ncc : danhSachNhaCungCap) {
            tenNhaCungCap.add(ncc.ten);
        }

        if (tenNhaCungCap.isEmpty()) {
            tenNhaCungCap.add("Chưa có nhà cung cấp được duyệt");
        }

        ArrayAdapter<String> adapter =
                new ArrayAdapter<>(
                        requireContext(),
                        android.R.layout.simple_spinner_item,
                        tenNhaCungCap
                );

        adapter.setDropDownViewResource(
                android.R.layout.simple_spinner_dropdown_item
        );

        spNhaCungCap.setAdapter(adapter);

        daTaiDanhSachNhaCungCap = true;

        if (danhSachNhaCungCap.isEmpty()) {
            spNhaCungCap.setEnabled(false);
            btnLuuSanPham.setEnabled(false);

            Toast.makeText(
                    requireContext(),
                    "Cần có nhà cung cấp đã được duyệt trước khi tạo sản phẩm.",
                    Toast.LENGTH_LONG
            ).show();
        }
    }

    // =====================================
    // CHỌN VÀ UPLOAD ẢNH
    // =====================================

    private void xuLyAnh(Uri uri) {

        String mimeType = requireContext()
                .getContentResolver()
                .getType(uri);

        if (mimeType == null
                || !(mimeType.equals("image/jpeg")
                || mimeType.equals("image/png")
                || mimeType.equals("image/webp"))) {

            Toast.makeText(
                    requireContext(),
                    "Chỉ hỗ trợ ảnh JPG, PNG hoặc WEBP.",
                    Toast.LENGTH_SHORT
            ).show();

            return;
        }

        try {
            imgAnhSanPham.setImageURI(uri);
        } catch (Exception e) {
            Toast.makeText(
                    requireContext(),
                    "Không thể hiển thị ảnh.",
                    Toast.LENGTH_SHORT
            ).show();
            return;
        }

        btnChonAnhSanPham.setEnabled(false);
        btnChonAnhSanPham.setText("Đang tải ảnh lên...");

        dangTaiAnh = true;

        executor.execute(() -> {

            try (
                    InputStream input = requireContext()
                            .getContentResolver()
                            .openInputStream(uri);

                    ByteArrayOutputStream output =
                            new ByteArrayOutputStream()
            ) {

                if (input == null) {
                    throw new IOException("Không đọc được ảnh.");
                }

                byte[] buffer = new byte[8192];
                int length;

                while ((length = input.read(buffer)) != -1) {

                    output.write(buffer, 0, length);

                    if (output.size() > 5 * 1024 * 1024) {
                        throw new IOException(
                                "Ảnh không được vượt quá 5 MB."
                        );
                    }
                }

                byte[] duLieuAnh = output.toByteArray();

                if (!isAdded()) return;

                requireActivity().runOnUiThread(() -> {

                    anhRepository.taiLen(
                            duLieuAnh,
                            mimeType,
                            "san-pham",
                            new KetQuaApi<KetQuaTaiAnh>() {

                                @Override
                                public void thanhCong(KetQuaTaiAnh ketQua) {

                                    if (!isAdded()) return;

                                    anhSanPhamUrl = ketQua.url;
                                    ketThucUploadAnh();

                                    Toast.makeText(
                                            requireContext(),
                                            "Tải ảnh thành công!",
                                            Toast.LENGTH_SHORT
                                    ).show();
                                }

                                @Override
                                public void loi(String thongDiep) {

                                    if (!isAdded()) return;

                                    ketThucUploadAnh();

                                    Toast.makeText(
                                            requireContext(),
                                            thongDiep,
                                            Toast.LENGTH_LONG
                                    ).show();
                                }

                                @Override
                                public void hetPhien() {

                                    if (!isAdded()) return;

                                    ketThucUploadAnh();

                                    Toast.makeText(
                                            requireContext(),
                                            "Phiên đăng nhập đã hết hạn.",
                                            Toast.LENGTH_LONG
                                    ).show();
                                }
                            }
                    );
                });

            } catch (Exception e) {

                if (!isAdded()) return;

                requireActivity().runOnUiThread(() -> {

                    ketThucUploadAnh();

                    Toast.makeText(
                            requireContext(),
                            e.getMessage(),
                            Toast.LENGTH_LONG
                    ).show();
                });
            }
        });
    }

    private void ketThucUploadAnh() {

        dangTaiAnh = false;

        btnChonAnhSanPham.setEnabled(true);
        btnChonAnhSanPham.setText("Chọn ảnh sản phẩm");
    }

    // =====================================
    // TẠO SẢN PHẨM
    // =====================================

    private void taoSanPham() {

        if (dangTaiAnh) {
            Toast.makeText(
                    requireContext(),
                    "Vui lòng chờ tải ảnh hoàn tất.",
                    Toast.LENGTH_SHORT
            ).show();
            return;
        }

        if (danhSachNhaCungCap.isEmpty()) {
            Toast.makeText(
                    requireContext(),
                    "Chưa có nhà cung cấp được duyệt.",
                    Toast.LENGTH_SHORT
            ).show();
            return;
        }

        String ten = edtTenSanPham.getText()
                .toString().trim();

        String moTa = edtMoTa.getText()
                .toString().trim();

        String donViTinh = edtDonViTinh.getText()
                .toString().trim();

        String giaText = edtGia.getText()
                .toString().trim();

        if (ten.isEmpty()) {
            edtTenSanPham.setError(
                    "Vui lòng nhập tên sản phẩm."
            );
            edtTenSanPham.requestFocus();
            return;
        }

        if (giaText.isEmpty()) {
            edtGia.setError(
                    "Vui lòng nhập giá sản phẩm."
            );
            edtGia.requestFocus();
            return;
        }

        int gia;

        try {
            gia = Integer.parseInt(giaText);

            if (gia < 1 || gia > 1000000000) {
                throw new NumberFormatException();
            }

        } catch (NumberFormatException e) {

            edtGia.setError(
                    "Giá phải từ 1 đến 1.000.000.000 VNĐ."
            );
            edtGia.requestFocus();
            return;
        }

        int viTri = spNhaCungCap.getSelectedItemPosition();

        if (viTri < 0 || viTri >= danhSachNhaCungCap.size()) {
            Toast.makeText(
                    requireContext(),
                    "Vui lòng chọn nhà cung cấp.",
                    Toast.LENGTH_SHORT
            ).show();
            return;
        }

        NhaCungCap nhaCungCap =
                danhSachNhaCungCap.get(viTri);

        YeuCauTaoSanPham yeuCau =
                new YeuCauTaoSanPham();

        yeuCau.nhaCungCapId = nhaCungCap.id;
        yeuCau.ten = ten;
        yeuCau.moTa = moTa.isEmpty() ? null : moTa;
        yeuCau.donViTinh =
                donViTinh.isEmpty() ? null : donViTinh;
        yeuCau.gia = gia;
        yeuCau.anhUrl = anhSanPhamUrl;

        btnLuuSanPham.setEnabled(false);
        btnLuuSanPham.setText("Đang tạo sản phẩm...");

        sanPhamRepository.tao(
                yeuCau,
                new KetQuaApi<SanPham>() {

                    @Override
                    public void thanhCong(SanPham ketQua) {

                        if (!isAdded()) return;

                        btnLuuSanPham.setEnabled(true);
                        btnLuuSanPham.setText("Tạo sản phẩm");

                        Toast.makeText(
                                requireContext(),
                                "Tạo sản phẩm thành công! Sản phẩm đang chờ duyệt.",
                                Toast.LENGTH_LONG
                        ).show();

                        requireActivity()
                                .getOnBackPressedDispatcher()
                                .onBackPressed();
                    }

                    @Override
                    public void loi(String thongDiep) {

                        if (!isAdded()) return;

                        btnLuuSanPham.setEnabled(true);
                        btnLuuSanPham.setText("Tạo sản phẩm");

                        Toast.makeText(
                                requireContext(),
                                thongDiep,
                                Toast.LENGTH_LONG
                        ).show();
                    }

                    @Override
                    public void hetPhien() {

                        if (!isAdded()) return;

                        btnLuuSanPham.setEnabled(true);
                        btnLuuSanPham.setText("Tạo sản phẩm");

                        Toast.makeText(
                                requireContext(),
                                "Phiên đăng nhập đã hết hạn.",
                                Toast.LENGTH_LONG
                        ).show();
                    }
                }
        );
    }

    @Override
    public void onSaveInstanceState(@NonNull Bundle outState) {
        super.onSaveInstanceState(outState);
        outState.putString("anhSanPhamUrl", anhSanPhamUrl);
    }

    @Override
    public void onDestroy() {
        super.onDestroy();
        executor.shutdown();
=======
import vn.edu.vhu.ltdd.gugugaga.admin.model.NhaCungCap;
import vn.edu.vhu.ltdd.gugugaga.admin.model.YeuCauTaoSanPham;
import vn.edu.vhu.ltdd.gugugaga.admin.ui.MainActivity;
import vn.edu.vhu.ltdd.gugugaga.admin.ui.chung.KhungTrangThai;
import vn.edu.vhu.ltdd.gugugaga.admin.ui.chung.ManHinh;
import vn.edu.vhu.ltdd.gugugaga.admin.ui.chung.TrangThai;
import vn.edu.vhu.ltdd.gugugaga.admin.util.KiemTraForm;

/**
 * Form tạo sản phẩm mới cho một nhà cung cấp đã chọn (Issue #13).
 * Hỗ trợ tải ảnh đại diện sản phẩm qua AnhRepository (mucDich = "san-pham").
 */
public class TaoSanPhamFragment extends Fragment {
    private static final String KEY_NCC_ID = "ncc_id";
    private static final int GIA_TOI_DA = 1_000_000_000;

    private TaoSanPhamViewModel viewModel;
    private AnhRepository anhRepo;
    private KhungTrangThai khung;
    private View noiDung;
    private Spinner spNhaCungCap;
    private TextView tvLoiNcc;
    private TextInputLayout tilTen, tilGia, tilDonViTinh, tilMoTa, tilAnh;
    private TextInputEditText edtTen, edtGia, edtDonViTinh, edtMoTa, edtAnh;
    private Button btnChonAnh, btnLuu;
    private ProgressBar progressAnh, progressLuu;
    private ImageView ivAnh;

    private final List<Integer> idNcc = new ArrayList<>();
    private int nccIdDaChon = -1;
    private boolean dangLuu;

    private final ActivityResultLauncher<PickVisualMediaRequest> chonAnhLauncher =
            registerForActivityResult(new PickVisualMedia(), this::xuLyAnhDaChon);

    @Nullable
    @Override
    public View onCreateView(@NonNull LayoutInflater inflater, @Nullable ViewGroup container,
                             @Nullable Bundle savedInstanceState) {
        return inflater.inflate(R.layout.fragment_tao_san_pham, container, false);
    }

    @Override
    public void onViewCreated(@NonNull View view, @Nullable Bundle savedInstanceState) {
        ((MainActivity) requireActivity()).datTieuDe(R.string.tieu_de_tao_san_pham);
        if (savedInstanceState != null) {
            nccIdDaChon = savedInstanceState.getInt(KEY_NCC_ID, -1);
        }

        anhXa(view);
        anhRepo = new AnhRepository(requireContext());
        viewModel = new ViewModelProvider(this).get(TaoSanPhamViewModel.class);
        khung = new KhungTrangThai(view, viewModel::taiNcc);

        btnChonAnh.setOnClickListener(v -> chonAnhLauncher.launch(
                new PickVisualMediaRequest.Builder().setMediaType(PickVisualMedia.ImageOnly.INSTANCE).build()));
        btnLuu.setOnClickListener(v -> gui());

        viewModel.getDsNcc().observe(getViewLifecycleOwner(), this::hienThiNcc);
        viewModel.getDaTao().observe(getViewLifecycleOwner(), sk -> {
            if (sk == null) return;
            var sp = sk.layNeuChuaXuLy();
            if (sp == null) return;
            Bundle b = new Bundle();
            b.putString(SanPhamFragment.KEY_THONG_BAO, getString(R.string.da_tao_sp, sp.ten));
            getParentFragmentManager().setFragmentResult(SanPhamFragment.KET_QUA_CAP_NHAT, b);
            getParentFragmentManager().popBackStack();
        });
        viewModel.getLoiGui().observe(getViewLifecycleOwner(), sk -> {
            if (sk == null) return;
            TaoSanPhamViewModel.LoiGui loi = sk.layNeuChuaXuLy();
            if (loi == null) return;
            datDangLuu(false);
            hienLoiBackend(loi);
        });
        ManHinh.quanSatChung(this, viewModel);
        viewModel.taiNccLanDau();
    }

    @Override
    public void onSaveInstanceState(@NonNull Bundle outState) {
        super.onSaveInstanceState(outState);
        outState.putInt(KEY_NCC_ID, nccIdDaChon);
    }

    private void anhXa(View v) {
        noiDung = v.findViewById(R.id.noiDung);
        spNhaCungCap = v.findViewById(R.id.spNhaCungCap);
        tvLoiNcc = v.findViewById(R.id.tvLoiNcc);
        tilTen = v.findViewById(R.id.tilTen);
        tilGia = v.findViewById(R.id.tilGia);
        tilDonViTinh = v.findViewById(R.id.tilDonViTinh);
        tilMoTa = v.findViewById(R.id.tilMoTa);
        tilAnh = v.findViewById(R.id.tilAnh);
        edtTen = v.findViewById(R.id.edtTen);
        edtGia = v.findViewById(R.id.edtGia);
        edtDonViTinh = v.findViewById(R.id.edtDonViTinh);
        edtMoTa = v.findViewById(R.id.edtMoTa);
        edtAnh = v.findViewById(R.id.edtAnh);
        btnChonAnh = v.findViewById(R.id.btnChonAnh);
        btnLuu = v.findViewById(R.id.btnLuu);
        progressAnh = v.findViewById(R.id.progressAnh);
        progressLuu = v.findViewById(R.id.progressLuu);
        ivAnh = v.findViewById(R.id.ivAnh);
    }

    private void hienThiNcc(TrangThai<List<NhaCungCap>> tt) {
        khung.hien(tt, noiDung, tt.duLieu != null && tt.duLieu.isEmpty());
        if (tt.loai != TrangThai.Loai.THANH_CONG || tt.duLieu == null) return;

        List<String> nhan = new ArrayList<>();
        idNcc.clear();
        nhan.add(getString(R.string.chon_nha_cung_cap));
        idNcc.add(-1);
        int chon = 0;
        for (NhaCungCap n : tt.duLieu) {
            if ("TU_CHOI".equals(n.trangThaiDuyet)) continue;
            nhan.add(n.ten + " (" + n.tenVung + ")");
            idNcc.add(n.id);
            if (n.id == nccIdDaChon) chon = idNcc.size() - 1;
        }
        ArrayAdapter<String> a = new ArrayAdapter<>(requireContext(), android.R.layout.simple_spinner_item, nhan);
        a.setDropDownViewResource(android.R.layout.simple_spinner_dropdown_item);
        spNhaCungCap.setAdapter(a);
        spNhaCungCap.setSelection(chon);
        spNhaCungCap.setOnItemSelectedListener(new AdapterView.OnItemSelectedListener() {
            @Override
            public void onItemSelected(AdapterView<?> parent, View view, int pos, long id) {
                nccIdDaChon = idNcc.get(pos);
                tvLoiNcc.setVisibility(View.GONE);
            }

            @Override
            public void onNothingSelected(AdapterView<?> parent) { }
        });
    }

    private void xuLyAnhDaChon(Uri uri) {
        if (uri == null) return;
        progressAnh.setVisibility(View.VISIBLE);
        btnChonAnh.setEnabled(false);
        anhRepo.taiLen(uri, "san-pham", new KetQuaApi<String>() {
            @Override
            public void thanhCong(String url) {
                if (!isAdded()) return;
                progressAnh.setVisibility(View.GONE);
                btnChonAnh.setEnabled(true);
                edtAnh.setText(url);
                xemTruocAnh(url);
            }

            @Override
            public void hetPhien() {
                if (isAdded()) ((MainActivity) requireActivity()).dangXuat(true);
            }

            @Override
            public void loi(String thongDiep) {
                if (!isAdded()) return;
                progressAnh.setVisibility(View.GONE);
                btnChonAnh.setEnabled(true);
                ManHinh.baoSnackbar(TaoSanPhamFragment.this, thongDiep);
            }
        });
    }

    private void xemTruocAnh(String url) {
        if (!KiemTraForm.laUrlWeb(url)) {
            ivAnh.setVisibility(View.GONE);
            return;
        }
        anhRepo.tai(url, new KetQuaApi<Bitmap>() {
            @Override
            public void thanhCong(Bitmap bmp) {
                if (!isAdded()) return;
                ivAnh.setImageBitmap(bmp);
                ivAnh.setVisibility(View.VISIBLE);
            }

            @Override
            public void loi(String thongDiep) { }

            @Override
            public void hetPhien() { }
        });
    }

    private void gui() {
        if (dangLuu) return;
        tvLoiNcc.setVisibility(View.GONE);
        tilTen.setError(null);
        tilGia.setError(null);
        tilDonViTinh.setError(null);
        tilMoTa.setError(null);
        tilAnh.setError(null);

        if (nccIdDaChon <= 0) {
            tvLoiNcc.setText(R.string.loi_chua_chon_ncc);
            tvLoiNcc.setVisibility(View.VISIBLE);
            spNhaCungCap.requestFocus();
            return;
        }
        String ten = chuoi(edtTen);
        if (ten.isEmpty()) {
            tilTen.setError(getString(R.string.loi_ten_sp_trong));
            edtTen.requestFocus();
            return;
        }
        String giaStr = chuoi(edtGia);
        KiemTraForm.Loi loiGia = KiemTraForm.soNguyen(giaStr, 1, GIA_TOI_DA);
        if (loiGia == KiemTraForm.Loi.TRONG) {
            tilGia.setError(getString(R.string.loi_gia_trong));
            edtGia.requestFocus();
            return;
        }
        if (loiGia != null) {
            tilGia.setError(getString(R.string.loi_gia_sai));
            edtGia.requestFocus();
            return;
        }
        String anh = chuoi(edtAnh);
        if (!anh.isEmpty() && !KiemTraForm.laUrlWeb(anh)) {
            tilAnh.setError(getString(R.string.loi_anh_url_sai));
            edtAnh.requestFocus();
            return;
        }

        String dvt = chuoi(edtDonViTinh);
        String moTa = chuoi(edtMoTa);
        datDangLuu(true);
        viewModel.tao(new YeuCauTaoSanPham(
                nccIdDaChon,
                ten,
                Integer.parseInt(giaStr),
                dvt.isEmpty() ? null : dvt,
                moTa.isEmpty() ? null : moTa,
                anh.isEmpty() ? null : anh));
    }

    private void hienLoiBackend(TaoSanPhamViewModel.LoiGui loi) {
        Map<String, String> m = loi.loiTheoTruong;
        if (m.containsKey("nhaCungCapId")) {
            tvLoiNcc.setText(m.get("nhaCungCapId"));
            tvLoiNcc.setVisibility(View.VISIBLE);
        }
        if (m.containsKey("ten")) tilTen.setError(m.get("ten"));
        if (m.containsKey("gia")) tilGia.setError(m.get("gia"));
        if (m.containsKey("donViTinh")) tilDonViTinh.setError(m.get("donViTinh"));
        if (m.containsKey("moTa")) tilMoTa.setError(m.get("moTa"));
        if (m.containsKey("anhUrl")) tilAnh.setError(m.get("anhUrl"));
        if (m.isEmpty() && loi.thongDiep != null) {
            ManHinh.baoSnackbar(this, loi.thongDiep);
        }
    }

    private void datDangLuu(boolean b) {
        dangLuu = b;
        btnLuu.setEnabled(!b);
        progressLuu.setVisibility(b ? View.VISIBLE : View.GONE);
    }

    private String chuoi(TextInputEditText edt) {
        return edt.getText() == null ? "" : edt.getText().to
          main
    }
}
