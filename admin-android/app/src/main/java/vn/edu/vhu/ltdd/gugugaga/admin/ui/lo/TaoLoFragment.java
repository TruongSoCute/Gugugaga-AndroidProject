package vn.edu.vhu.ltdd.gugugaga.admin.ui.lo;

import android.app.DatePickerDialog;
import android.os.Bundle;
import android.util.Log;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.AdapterView;
import android.widget.ArrayAdapter;
import android.widget.Button;
import android.widget.ProgressBar;
import android.widget.Spinner;
import android.widget.TextView;
import android.widget.Toast;

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
import vn.edu.vhu.ltdd.gugugaga.admin.model.LoSanXuat;
import vn.edu.vhu.ltdd.gugugaga.admin.model.SanPham;
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
    private static final String KEY_NGAY_SAN_XUAT = "ngay_san_xuat";
    private static final String KEY_HAN_SU_DUNG = "han_su_dung";
    private static final int SO_LUONG_TOI_DA = 10_000_000; // giống giới hạn của backend

    private TaoLoViewModel viewModel;
    private KhungTrangThai khung;
    private View noiDung;
    private Spinner spSanPham;
    private TextView tvLoiSanPham;
    private TextInputLayout tilNgaySanXuat, tilHanSuDung, tilSoLuong, tilNguoiSanXuat, tilAnh, tilGhiChu;
    private TextInputEditText edtNgaySanXuat, edtHanSuDung, edtSoLuong, edtNguoiSanXuat, edtAnh, edtGhiChu;
    private Button btnLuu;
    private ProgressBar progressLuu;

    /** Danh sách id song song với các mục của Spinner; mục 0 là "Chọn sản phẩm" (id -1). */
    private final List<Integer> idSanPham = new ArrayList<>();
    private int sanPhamIdDaChon = -1;
    private String ngaySanXuat;
    private String hanSuDung;

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
            ngaySanXuat = savedInstanceState.getString(KEY_NGAY_SAN_XUAT);
            hanSuDung = savedInstanceState.getString(KEY_HAN_SU_DUNG);
        }
        anhXa(view);
        viewModel = new ViewModelProvider(this).get(TaoLoViewModel.class);
        khung = new KhungTrangThai(view, viewModel::taiSanPham);

        edtNgaySanXuat.setOnClickListener(v -> chonNgay(true));
        edtHanSuDung.setOnClickListener(v -> chonNgay(false));
        btnLuu.setOnClickListener(v -> xuLyLuu());

        viewModel.getSanPham().observe(getViewLifecycleOwner(), this::hienSanPham);
        viewModel.getDangGui().observe(getViewLifecycleOwner(), dangGui -> {
            boolean dang = Boolean.TRUE.equals(dangGui);
            btnLuu.setEnabled(!dang);
            progressLuu.setVisibility(dang ? View.VISIBLE : View.GONE);
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
        outState.putString(KEY_NGAY_SAN_XUAT, ngaySanXuat);
        outState.putString(KEY_HAN_SU_DUNG, hanSuDung);
    }

    private void anhXa(View v) {
        noiDung = v.findViewById(R.id.noiDung);
        spSanPham = v.findViewById(R.id.spSanPham);
        tvLoiSanPham = v.findViewById(R.id.tvLoiSanPham);
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
        btnLuu = v.findViewById(R.id.btnLuu);
        progressLuu = v.findViewById(R.id.progressLuu);
    }

    /** Spinner + ArrayAdapter với List (Lab A6). Chọn lại sản phẩm đã chọn trước khi xoay. */
    private void hienSanPham(TrangThai<List<SanPham>> tt) {
        khung.hien(tt, noiDung, false);
        if (tt.loai != TrangThai.Loai.THANH_CONG) return;

        List<String> nhan = new ArrayList<>();
        idSanPham.clear();
        nhan.add(getString(R.string.chon_san_pham));
        idSanPham.add(-1);
        int viTriChon = 0;
        for (SanPham sp : tt.duLieu) {
            String ten = AppConfig.TRANG_THAI_DA_DUYET.equals(sp.trangThaiDuyet) ? sp.ten
                    : getString(R.string.ten_kem_trang_thai, sp.ten, getString(NhanTrangThai.chu(sp.trangThaiDuyet)));
            nhan.add(getString(R.string.ncc_vung, ten, sp.tenNhaCungCap));
            idSanPham.add(sp.id);
            if (sp.id == sanPhamIdDaChon) viTriChon = idSanPham.size() - 1;
        }
        ArrayAdapter<String> a = new ArrayAdapter<>(requireContext(), android.R.layout.simple_spinner_item, nhan);
        a.setDropDownViewResource(android.R.layout.simple_spinner_dropdown_item);
        spSanPham.setAdapter(a);
        spSanPham.setSelection(viTriChon);
        spSanPham.setOnItemSelectedListener(new AdapterView.OnItemSelectedListener() {
            @Override
            public void onItemSelected(AdapterView<?> parent, View view, int position, long id) {
                sanPhamIdDaChon = idSanPham.get(position);
                if (sanPhamIdDaChon != -1) tvLoiSanPham.setVisibility(View.GONE);
            }

            @Override
            public void onNothingSelected(AdapterView<?> parent) { }
        });
        // Hiện lại ngày đã chọn (giá trị ISO lưu trong Bundle, ô chỉ để hiển thị).
        edtNgaySanXuat.setText(DinhDang.ngay(ngaySanXuat));
        edtHanSuDung.setText(DinhDang.ngay(hanSuDung));
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

        Log.d(AppConfig.TAG, "Gửi tạo lô cho sản phẩm " + sanPhamIdDaChon);
        viewModel.taoLo(new YeuCauTaoLo(sanPhamIdDaChon, ngaySanXuat, hanSuDung,
                Integer.parseInt(soLuongChu.trim()), nguoiSanXuat,
                anh.isEmpty() ? null : anh, ghiChu.isEmpty() ? null : ghiChu));
    }

    private void xoaLoi() {
        tvLoiSanPham.setVisibility(View.GONE);
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
