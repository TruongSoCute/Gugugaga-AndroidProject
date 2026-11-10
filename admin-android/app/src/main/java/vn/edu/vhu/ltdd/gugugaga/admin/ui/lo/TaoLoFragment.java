package vn.edu.vhu.ltdd.gugugaga.admin.ui.lo;

import android.app.DatePickerDialog;
import android.net.Uri;
import android.os.Bundle;
import android.text.Editable;
import android.text.TextWatcher;
import android.util.Log;
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
import android.widget.Toast;

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
import java.util.List;
import java.util.Map;

import vn.edu.vhu.ltdd.gugugaga.admin.AppConfig;
import vn.edu.vhu.ltdd.gugugaga.admin.R;
import vn.edu.vhu.ltdd.gugugaga.admin.data.AnhRepository;
import vn.edu.vhu.ltdd.gugugaga.admin.data.KetQuaApi;
import vn.edu.vhu.ltdd.gugugaga.admin.model.LoSanXuat;
import vn.edu.vhu.ltdd.gugugaga.admin.model.SanPham;
import vn.edu.vhu.ltdd.gugugaga.admin.model.VungNguyenLieu;
import vn.edu.vhu.ltdd.gugugaga.admin.model.YeuCauTaoLo;
import vn.edu.vhu.ltdd.gugugaga.admin.ui.MainActivity;
import vn.edu.vhu.ltdd.gugugaga.admin.ui.chung.KhungTrangThai;
import vn.edu.vhu.ltdd.gugugaga.admin.ui.chung.ManHinh;
import vn.edu.vhu.ltdd.gugugaga.admin.ui.chung.NhanTrangThai;
import vn.edu.vhu.ltdd.gugugaga.admin.ui.chung.TrangThai;
import vn.edu.vhu.ltdd.gugugaga.admin.util.DinhDang;
import vn.edu.vhu.ltdd.gugugaga.admin.util.KiemTraForm;

/**
 * Form tạo lô sản xuất (C.1 #5, #9):
 * - Spinner sản phẩm nạp từ GET /quan-tri/san-pham (Lab A6);
 * - ngày sản xuất, hạn sử dụng chọn bằng DatePickerDialog;
 * - kiểm tra theo thứ tự trên màn hình: rỗng → định dạng → miền giá trị (Lab A4), sai ô nào
 *   setError + requestFocus ô đó rồi dừng; lỗi 400 của backend cũng hiện đúng ô;
 * - dữ liệu đang nhập giữ khi xoay: EditText có id tự khôi phục, phần còn lại (sản phẩm đã chọn,
 *   hai ngày đã chọn) lưu bằng onSaveInstanceState với khóa KEY_... (Lab A2).
 * Mã truy xuất do server sinh; app không gửi.
 */
public class TaoLoFragment extends Fragment {
    private static final String KEY_SAN_PHAM_ID = "san_pham_id";
    private static final String KEY_VUNG_ID = "vung_id";
    private static final String KEY_NGAY_SAN_XUAT = "ngay_san_xuat";
    private static final String KEY_HAN_SU_DUNG = "han_su_dung";
    private static final String KEY_ANH_URL = "anh_url";
    private static final int SO_LUONG_TOI_DA = 10_000_000; // giống giới hạn của backend

    private TaoLoViewModel viewModel;
    private AnhRepository anhRepo;
    private KhungTrangThai khung;
    private View noiDung;
    private Spinner spSanPham, spVungNguyenLieu;
    private TextView tvLoiSanPham, tvLoiVungNguyenLieu, tvTrangThaiAnh;
    private TextInputLayout tilNgaySanXuat, tilHanSuDung, tilSoLuong, tilNguoiSanXuat, tilAnh, tilGhiChu;
    private TextInputEditText edtNgaySanXuat, edtHanSuDung, edtSoLuong, edtNguoiSanXuat, edtAnh, edtGhiChu;
    private Button btnChonAnh, btnLuu;
    private ProgressBar progressTaiAnh, progressLuu;
    private ImageView ivXemTruocAnh;

    private final ActivityResultLauncher<PickVisualMediaRequest> chonAnhLauncher =
            registerForActivityResult(new PickVisualMedia(), this::xuLyAnhDaChon);

    /** Danh sách id song song với các mục của Spinner; mục 0 là "Chọn sản phẩm" (id -1). */
    private final List<Integer> idSanPham = new ArrayList<>();
    private final List<SanPham> danhSachSanPham = new ArrayList<>();
    private final List<Integer> idVungNguyenLieu = new ArrayList<>();
    private int sanPhamIdDaChon = -1;
    private int vungNguyenLieuIdDaChon = -1;
    private int vungMacDinhCuaSanPham = -1;
    private boolean khoiPhucVungDaLuu;
    private boolean dangGuiLo;
    private boolean dangTaiAnh;
    private String ngaySanXuat;
    private String hanSuDung;
    private String anhUrlDaTai;

    @Nullable
    @Override
    public View onCreateView(@NonNull LayoutInflater inflater, @Nullable ViewGroup container,
                             @Nullable Bundle savedInstanceState) {
        return inflater.inflate(R.layout.fragment_tao_lo, container, false);
    }

    @Override
    public void onViewCreated(@NonNull View view, @Nullable Bundle savedInstanceState) {
        ((MainActivity) requireActivity()).datTieuDe(R.string.tieu_de_tao_lo);
        // Khôi phục dữ liệu không nằm trong EditText (Lab A2): làm TRƯỚC khi nạp Spinner.
        if (savedInstanceState != null) {
            sanPhamIdDaChon = savedInstanceState.getInt(KEY_SAN_PHAM_ID, -1);
            vungNguyenLieuIdDaChon = savedInstanceState.getInt(KEY_VUNG_ID, -1);
            khoiPhucVungDaLuu = vungNguyenLieuIdDaChon != -1;
            ngaySanXuat = savedInstanceState.getString(KEY_NGAY_SAN_XUAT);
            hanSuDung = savedInstanceState.getString(KEY_HAN_SU_DUNG);
            anhUrlDaTai = savedInstanceState.getString(KEY_ANH_URL);
        }
        anhXa(view);
        anhRepo = new AnhRepository(requireContext());
        viewModel = new ViewModelProvider(this).get(TaoLoViewModel.class);
        khung = new KhungTrangThai(view, viewModel::taiLaiDuLieu);

        edtNgaySanXuat.setOnClickListener(v -> chonNgay(true));
        edtHanSuDung.setOnClickListener(v -> chonNgay(false));
        btnChonAnh.setOnClickListener(v -> chonAnhLauncher.launch(new PickVisualMediaRequest.Builder()
                .setMediaType(PickVisualMedia.ImageOnly.INSTANCE)
                .build()));
        edtAnh.addTextChangedListener(new TextWatcher() {
            @Override
            public void beforeTextChanged(CharSequence s, int start, int count, int after) { }

            @Override
            public void onTextChanged(CharSequence s, int start, int before, int count) { }

            @Override
            public void afterTextChanged(Editable s) {
                tilAnh.setError(null);
                capNhatXemTruocAnh();
            }
        });
        btnLuu.setOnClickListener(v -> xuLyLuu());

        viewModel.getSanPham().observe(getViewLifecycleOwner(), this::hienSanPham);
        viewModel.getVungNguyenLieu().observe(getViewLifecycleOwner(), this::hienVungNguyenLieu);
        viewModel.getDangTaiAnh().observe(getViewLifecycleOwner(), dang -> {
            dangTaiAnh = Boolean.TRUE.equals(dang);
            capNhatNutLuu();
            btnChonAnh.setEnabled(!dangTaiAnh);
            progressTaiAnh.setVisibility(dangTaiAnh ? View.VISIBLE : View.GONE);
        });
        viewModel.getTrangThaiAnh().observe(getViewLifecycleOwner(), trangThai -> {
            if (trangThai != null) {
                tvTrangThaiAnh.setText(trangThai);
                tvTrangThaiAnh.setVisibility(View.VISIBLE);
            }
        });
        viewModel.getAnhDaTai().observe(getViewLifecycleOwner(), url -> {
            if (url != null && !url.isEmpty()) {
                anhUrlDaTai = url;
                edtAnh.setText(url);
                capNhatXemTruocAnh();
            }
        });
        viewModel.getDangGui().observe(getViewLifecycleOwner(), dangGui -> {
            dangGuiLo = Boolean.TRUE.equals(dangGui);
            capNhatNutLuu();
            progressLuu.setVisibility(dangGuiLo ? View.VISIBLE : View.GONE);
        });
        viewModel.getLoiTheoTruong().observe(getViewLifecycleOwner(), sk -> {
            Map<String, String> loi = sk.layNeuChuaXuLy();
            if (loi != null) hienLoiTheoTruong(loi);
        });
        viewModel.getDaTao().observe(getViewLifecycleOwner(), sk -> {
            LoSanXuat lo = sk.layNeuChuaXuLy();
            if (lo != null) daTaoXong(lo);
        });
        ManHinh.quanSatChung(this, viewModel);
        viewModel.taiSanPhamLanDau();
    }

    @Override
    public void onSaveInstanceState(@NonNull Bundle outState) {
        super.onSaveInstanceState(outState); // luôn gọi super để EditText tự lưu chữ đang nhập
        outState.putInt(KEY_SAN_PHAM_ID, sanPhamIdDaChon);
        outState.putInt(KEY_VUNG_ID, vungNguyenLieuIdDaChon);
        outState.putString(KEY_NGAY_SAN_XUAT, ngaySanXuat);
        outState.putString(KEY_HAN_SU_DUNG, hanSuDung);
        outState.putString(KEY_ANH_URL, edtAnh != null ? chuoi(edtAnh) : anhUrlDaTai);
    }

    private void anhXa(View v) {
        noiDung = v.findViewById(R.id.noiDung);
        spSanPham = v.findViewById(R.id.spSanPham);
        spVungNguyenLieu = v.findViewById(R.id.spVungNguyenLieu);
        tvLoiSanPham = v.findViewById(R.id.tvLoiSanPham);
        tvLoiVungNguyenLieu = v.findViewById(R.id.tvLoiVungNguyenLieu);
        tvTrangThaiAnh = v.findViewById(R.id.tvTrangThaiAnh);
        tilNgaySanXuat = v.findViewById(R.id.tilNgaySanXuat);
        tilHanSuDung = v.findViewById(R.id.tilHanSuDung);
        tilSoLuong = v.findViewById(R.id.tilSoLuong);
        tilNguoiSanXuat = v.findViewById(R.id.tilNguoiSanXuat);
        tilAnh = v.findViewById(R.id.tilAnhHienTruong);
        tilGhiChu = v.findViewById(R.id.tilGhiChu);
        edtNgaySanXuat = v.findViewById(R.id.edtNgaySanXuat);
        edtHanSuDung = v.findViewById(R.id.edtHanSuDung);
        edtSoLuong = v.findViewById(R.id.edtSoLuong);
        edtNguoiSanXuat = v.findViewById(R.id.edtNguoiSanXuat);
        edtAnh = v.findViewById(R.id.edtAnhHienTruong);
        edtGhiChu = v.findViewById(R.id.edtGhiChu);
        btnChonAnh = v.findViewById(R.id.btnChonAnh);
        progressTaiAnh = v.findViewById(R.id.progressTaiAnh);
        ivXemTruocAnh = v.findViewById(R.id.ivXemTruocAnh);
        btnLuu = v.findViewById(R.id.btnLuu);
        progressLuu = v.findViewById(R.id.progressLuu);
    }

    /** Spinner + ArrayAdapter với List (Lab A6). Chọn lại sản phẩm đã chọn trước khi xoay. */
    private void hienSanPham(TrangThai<List<SanPham>> tt) {
        khung.hien(tt, noiDung, false);
        if (tt.loai != TrangThai.Loai.THANH_CONG) return;

        List<String> nhan = new ArrayList<>();
        idSanPham.clear();
        danhSachSanPham.clear();
        nhan.add(getString(R.string.chon_san_pham));
        idSanPham.add(-1);
        danhSachSanPham.add(null);
        int viTriChon = 0;
        for (SanPham sp : tt.duLieu) {
            String ten = AppConfig.TRANG_THAI_DA_DUYET.equals(sp.trangThaiDuyet) ? sp.ten
                    : getString(R.string.ten_kem_trang_thai, sp.ten, getString(NhanTrangThai.chu(sp.trangThaiDuyet)));
            nhan.add(getString(R.string.ncc_vung, ten, sp.tenNhaCungCap));
            idSanPham.add(sp.id);
            danhSachSanPham.add(sp);
            if (sp.id == sanPhamIdDaChon) viTriChon = idSanPham.size() - 1;
        }
        ArrayAdapter<String> a = new ArrayAdapter<>(requireContext(), android.R.layout.simple_spinner_item, nhan);
        a.setDropDownViewResource(android.R.layout.simple_spinner_dropdown_item);
        spSanPham.setAdapter(a);
        spSanPham.setOnItemSelectedListener(new AdapterView.OnItemSelectedListener() {
            @Override
            public void onItemSelected(AdapterView<?> parent, View view, int position, long id) {
                sanPhamIdDaChon = idSanPham.get(position);
                if (sanPhamIdDaChon != -1) {
                    tvLoiSanPham.setVisibility(View.GONE);
                    SanPham sp = danhSachSanPham.get(position);
                    vungMacDinhCuaSanPham = sp == null ? -1 : sp.vungId;
                    if (khoiPhucVungDaLuu) {
                        khoiPhucVungDaLuu = false;
                    } else {
                        vungNguyenLieuIdDaChon = vungMacDinhCuaSanPham;
                    }
                    chonLaiViTriVung();
                }
            }

            @Override
            public void onNothingSelected(AdapterView<?> parent) { }
        });
        spSanPham.setSelection(viTriChon);
        // Hiện lại ngày đã chọn (giá trị ISO lưu trong Bundle, ô chỉ để hiển thị).
        edtNgaySanXuat.setText(DinhDang.ngay(ngaySanXuat));
        edtHanSuDung.setText(DinhDang.ngay(hanSuDung));
        if (chuoi(edtAnh).isEmpty() && anhUrlDaTai != null && !anhUrlDaTai.isEmpty()) {
            edtAnh.setText(anhUrlDaTai);
        } else {
            capNhatXemTruocAnh();
        }
    }

    private void xuLyAnhDaChon(Uri uri) {
        if (uri == null) return;
        tilAnh.setError(null);
        viewModel.taiAnh(uri);
    }

    private void capNhatXemTruocAnh() {
        String url = chuoi(edtAnh);
        anhUrlDaTai = url;
        if (KiemTraForm.laUrlWeb(url)) {
            hienAnhTheoUrlHienTai(url);
        } else {
            ivXemTruocAnh.setVisibility(View.GONE);
        }
    }

    private void capNhatNutLuu() {
        if (btnLuu != null) btnLuu.setEnabled(!dangGuiLo && !dangTaiAnh);
    }

    private void hienAnhTheoUrlHienTai(String url) {
        ivXemTruocAnh.setVisibility(View.VISIBLE);
        ivXemTruocAnh.setImageDrawable(null);
        anhRepo.tai(url, new KetQuaApi<android.graphics.Bitmap>() {
            @Override
            public void thanhCong(android.graphics.Bitmap anh) {
                if (url.equals(chuoi(edtAnh))) ivXemTruocAnh.setImageBitmap(anh);
            }

            @Override
            public void loi(String thongDiep) {
                if (url.equals(chuoi(edtAnh))) ivXemTruocAnh.setVisibility(View.GONE);
            }

            @Override
            public void hetPhien() { }
        });
    }

    private void hienVungNguyenLieu(TrangThai<List<VungNguyenLieu>> tt) {
        if (tt.loai == TrangThai.Loai.DANG_TAI) {
            spVungNguyenLieu.setEnabled(false);
            return;
        }
        if (tt.loai != TrangThai.Loai.THANH_CONG) {
            spVungNguyenLieu.setEnabled(false);
            if (tt.loai == TrangThai.Loai.LOI) {
                vungNguyenLieuIdDaChon = -1;
                tvLoiVungNguyenLieu.setText(getString(R.string.loi_tai_vung_dung_mac_dinh, tt.thongDiep));
                tvLoiVungNguyenLieu.setVisibility(View.VISIBLE);
                tvLoiVungNguyenLieu.setOnClickListener(v -> viewModel.taiVungNguyenLieu());
            }
            return;
        }
        tvLoiVungNguyenLieu.setOnClickListener(null);
        tvLoiVungNguyenLieu.setVisibility(View.GONE);
        List<String> nhan = new ArrayList<>();
        idVungNguyenLieu.clear();
        nhan.add(getString(R.string.chon_vung_nguyen_lieu));
        idVungNguyenLieu.add(-1);
        int viTriChon = 0;
        for (VungNguyenLieu vung : tt.duLieu) {
            nhan.add(vung.ten);
            idVungNguyenLieu.add(vung.id);
            if (vung.id == vungNguyenLieuIdDaChon) viTriChon = idVungNguyenLieu.size() - 1;
        }
        ArrayAdapter<String> a = new ArrayAdapter<>(requireContext(), android.R.layout.simple_spinner_item, nhan);
        a.setDropDownViewResource(android.R.layout.simple_spinner_dropdown_item);
        spVungNguyenLieu.setAdapter(a);
        spVungNguyenLieu.setEnabled(true);
        spVungNguyenLieu.setOnItemSelectedListener(new AdapterView.OnItemSelectedListener() {
            @Override
            public void onItemSelected(AdapterView<?> parent, View view, int position, long id) {
                vungNguyenLieuIdDaChon = idVungNguyenLieu.get(position);
                if (vungNguyenLieuIdDaChon != -1) tvLoiVungNguyenLieu.setVisibility(View.GONE);
            }

            @Override
            public void onNothingSelected(AdapterView<?> parent) { }
        });
        spVungNguyenLieu.setSelection(viTriChon);
    }

    private void chonLaiViTriVung() {
        if (spVungNguyenLieu.getAdapter() == null) return;
        for (int i = 0; i < idVungNguyenLieu.size(); i++) {
            if (idVungNguyenLieu.get(i) == vungNguyenLieuIdDaChon) {
                spVungNguyenLieu.setSelection(i);
                return;
            }
        }
    }

    private void chonNgay(boolean laNgaySanXuat) {
        String daChon = laNgaySanXuat ? ngaySanXuat : hanSuDung;
        Calendar c = Calendar.getInstance();
        if (daChon != null) {
            c.set(Integer.parseInt(daChon.substring(0, 4)), Integer.parseInt(daChon.substring(5, 7)) - 1,
                    Integer.parseInt(daChon.substring(8, 10)));
        } else if (!laNgaySanXuat) {
            c.add(Calendar.YEAR, 1); // gợi ý hạn sử dụng một năm sau
        }
        new DatePickerDialog(requireContext(), (picker, nam, thang0, ngay) -> {
            String iso = DinhDang.ngayIso(nam, thang0 + 1, ngay); // tháng của DatePicker tính từ 0
            if (laNgaySanXuat) {
                ngaySanXuat = iso;
                edtNgaySanXuat.setText(DinhDang.ngay(iso));
                tilNgaySanXuat.setError(null);
            } else {
                hanSuDung = iso;
                edtHanSuDung.setText(DinhDang.ngay(iso));
                tilHanSuDung.setError(null);
            }
        }, c.get(Calendar.YEAR), c.get(Calendar.MONTH), c.get(Calendar.DAY_OF_MONTH)).show();
    }

    /** Kiểm tra theo thứ tự trên màn hình; sai ô nào báo tại ô đó và return ngay (Lab A4, A6). */
    private void xuLyLuu() {
        xoaLoi();
        if (sanPhamIdDaChon == -1) {
            // Lựa chọn chưa chọn thì báo bằng Toast (Lab A6), kèm dòng đỏ dưới Spinner.
            tvLoiSanPham.setVisibility(View.VISIBLE);
            Toast.makeText(requireContext(), R.string.loi_chua_chon_san_pham, Toast.LENGTH_SHORT).show();
            spSanPham.requestFocus();
            return;
        }
        // Khi danh mục vùng không tải được, null cho phép backend dùng vùng mặc định của sản phẩm.
        if (vungNguyenLieuIdDaChon == -1
                && viewModel.getVungNguyenLieu().getValue() != null
                && viewModel.getVungNguyenLieu().getValue().loai == TrangThai.Loai.THANH_CONG) {
            tvLoiVungNguyenLieu.setText(R.string.loi_chua_chon_vung_nguyen_lieu);
            tvLoiVungNguyenLieu.setVisibility(View.VISIBLE);
            Toast.makeText(requireContext(), R.string.loi_chua_chon_vung_nguyen_lieu, Toast.LENGTH_SHORT).show();
            spVungNguyenLieu.requestFocus();
            return;
        }
        if (ngaySanXuat == null) {
            baoLoi(tilNgaySanXuat, null, getString(R.string.loi_ngay_san_xuat_trong));
            return;
        }
        if (hanSuDung == null) {
            baoLoi(tilHanSuDung, null, getString(R.string.loi_han_su_dung_trong));
            return;
        }
        if (!KiemTraForm.sauNgay(hanSuDung, ngaySanXuat)) {
            baoLoi(tilHanSuDung, null, getString(R.string.loi_han_truoc_ngay_san_xuat));
            return;
        }
        String soLuongChu = chuoi(edtSoLuong);
        KiemTraForm.Loi loiSoLuong = KiemTraForm.soNguyen(soLuongChu, 1, SO_LUONG_TOI_DA);
        if (loiSoLuong == KiemTraForm.Loi.TRONG) {
            baoLoi(tilSoLuong, edtSoLuong, getString(R.string.loi_so_luong_trong));
            return;
        }
        if (loiSoLuong == KiemTraForm.Loi.SAI_DINH_DANG) {
            baoLoi(tilSoLuong, edtSoLuong, getString(R.string.loi_so_luong_sai));
            return;
        }
        if (loiSoLuong == KiemTraForm.Loi.NGOAI_MIEN) {
            baoLoi(tilSoLuong, edtSoLuong, getString(R.string.loi_so_luong_mien, SO_LUONG_TOI_DA));
            return;
        }
        String nguoiSanXuat = chuoi(edtNguoiSanXuat);
        if (nguoiSanXuat.isEmpty()) {
            baoLoi(tilNguoiSanXuat, edtNguoiSanXuat, getString(R.string.loi_nguoi_san_xuat_trong));
            return;
        }
        String anh = chuoi(edtAnh);
        if (!anh.isEmpty() && !KiemTraForm.laUrlWeb(anh)) {
            baoLoi(tilAnh, edtAnh, getString(R.string.loi_url_anh));
            return;
        }
        String ghiChu = chuoi(edtGhiChu);

        Log.d(AppConfig.TAG, "Gửi tạo lô cho sản phẩm " + sanPhamIdDaChon
                + ", vùng " + vungNguyenLieuIdDaChon);
        viewModel.taoLo(new YeuCauTaoLo(sanPhamIdDaChon, ngaySanXuat, hanSuDung,
                Integer.parseInt(soLuongChu.trim()), vungNguyenLieuIdDaChon == -1 ? null : vungNguyenLieuIdDaChon, nguoiSanXuat,
                anh.isEmpty() ? null : anh, ghiChu.isEmpty() ? null : ghiChu));
    }

    private void xoaLoi() {
        tvLoiSanPham.setVisibility(View.GONE);
        tvLoiVungNguyenLieu.setVisibility(View.GONE);
        for (TextInputLayout t : new TextInputLayout[]{tilNgaySanXuat, tilHanSuDung, tilSoLuong,
                tilNguoiSanXuat, tilAnh, tilGhiChu}) {
            t.setError(null);
        }
    }

    private void baoLoi(TextInputLayout til, TextInputEditText edt, String loi) {
        til.setError(loi);
        if (edt != null) edt.requestFocus();
    }

    /** Lỗi 400 của backend có chiTiet[].truong: hiện lỗi đúng ô tương ứng. */
    private void hienLoiTheoTruong(Map<String, String> loi) {
        for (Map.Entry<String, String> e : loi.entrySet()) {
            TextInputLayout til = oTheoTruong(e.getKey());
            if (til != null) til.setError(e.getValue());
            else if ("sanPhamId".equals(e.getKey())) tvLoiSanPham.setVisibility(View.VISIBLE);
            else if ("vungNguyenLieuId".equals(e.getKey())) {
                tvLoiVungNguyenLieu.setText(e.getValue());
                tvLoiVungNguyenLieu.setVisibility(View.VISIBLE);
            }
        }
    }

    private TextInputLayout oTheoTruong(String truong) {
        switch (truong) {
            case "ngaySanXuat": return tilNgaySanXuat;
            case "hanSuDung": return tilHanSuDung;
            case "soLuong": return tilSoLuong;
            case "nguoiSanXuat": return tilNguoiSanXuat;
            case "anhHienTruongUrl": return tilAnh;
            case "ghiChu": return tilGhiChu;
            default: return null;
        }
    }

    /** Gửi kết quả cho danh sách lô (Fragment Result API) rồi quay lại (Lab A8). */
    private void daTaoXong(LoSanXuat lo) {
        Bundle kq = new Bundle();
        kq.putString(LoFragment.KEY_THONG_BAO, getString(R.string.da_tao_lo, lo.maTruyXuat));
        getParentFragmentManager().setFragmentResult(LoFragment.KET_QUA_CAP_NHAT, kq);
        getParentFragmentManager().popBackStack();
    }

    private static String chuoi(TextInputEditText edt) {
        return edt.getText() == null ? "" : edt.getText().toString().trim();
    }
}
