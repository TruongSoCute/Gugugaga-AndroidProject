package vn.edu.vhu.ltdd.gugugaga.admin.ui.baocao;

import android.app.DatePickerDialog;
import android.os.Bundle;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.Button;
import android.widget.LinearLayout;
import android.widget.TextView;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.fragment.app.Fragment;
import androidx.lifecycle.ViewModelProvider;

import java.util.ArrayList;
import java.util.Calendar;
import java.util.List;

import vn.edu.vhu.ltdd.gugugaga.admin.R;
import vn.edu.vhu.ltdd.gugugaga.admin.model.BaoCaoDoanhSo;
import vn.edu.vhu.ltdd.gugugaga.admin.ui.MainActivity;
import vn.edu.vhu.ltdd.gugugaga.admin.ui.chung.KhungTrangThai;
import vn.edu.vhu.ltdd.gugugaga.admin.ui.chung.ManHinh;
import vn.edu.vhu.ltdd.gugugaga.admin.ui.chung.TrangThai;
import vn.edu.vhu.ltdd.gugugaga.admin.util.DinhDang;
import vn.edu.vhu.ltdd.gugugaga.admin.util.KiemTraForm;

/**
 * Báo cáo doanh số (chỉ QUAN_TRI, C.1 #7): tổng, biểu đồ cột tự vẽ theo vùng và theo hạng sao,
 * 5 nhà cung cấp bán chạy. Lọc từ ngày/đến ngày bằng DatePickerDialog; khoảng ngày đã chọn lưu
 * bằng onSaveInstanceState (Lab A2), báo cáo đã tải giữ trong ViewModel.
 */
public class BaoCaoFragment extends Fragment {
    private static final String KEY_TU = "tu";
    private static final String KEY_DEN = "den";

    private BaoCaoViewModel viewModel;
    private KhungTrangThai khung;
    private View noiDung;
    private Button btnTu, btnDen;
    private TextView tvLoiLoc, tvTongDoanhSo, tvTongDon, tvTrongTop;
    private BieuDoCotView bdVung, bdHangSao;
    private LinearLayout dsTop;
    private String tu;
    private String den;

    @Nullable
    @Override
    public View onCreateView(@NonNull LayoutInflater inflater, @Nullable ViewGroup container,
                             @Nullable Bundle savedInstanceState) {
        return inflater.inflate(R.layout.fragment_bao_cao, container, false);
    }

    @Override
    public void onViewCreated(@NonNull View view, @Nullable Bundle savedInstanceState) {
        ((MainActivity) requireActivity()).datTieuDe(R.string.tieu_de_bao_cao);
        if (savedInstanceState != null) {
            tu = savedInstanceState.getString(KEY_TU);
            den = savedInstanceState.getString(KEY_DEN);
        }
        viewModel = new ViewModelProvider(this).get(BaoCaoViewModel.class);
        noiDung = view.findViewById(R.id.noiDung);
        btnTu = view.findViewById(R.id.btnTuNgay);
        btnDen = view.findViewById(R.id.btnDenNgay);
        tvLoiLoc = view.findViewById(R.id.tvLoiLoc);
        tvTongDoanhSo = view.findViewById(R.id.tvTongDoanhSo);
        tvTongDon = view.findViewById(R.id.tvTongDon);
        tvTrongTop = view.findViewById(R.id.tvTrongTop);
        bdVung = view.findViewById(R.id.bdVung);
        bdHangSao = view.findViewById(R.id.bdHangSao);
        dsTop = view.findViewById(R.id.dsTop);
        khung = new KhungTrangThai(view, viewModel::taiLai);

        btnTu.setOnClickListener(v -> chonNgay(true));
        btnDen.setOnClickListener(v -> chonNgay(false));
        view.findViewById(R.id.btnXoaLoc).setOnClickListener(v -> {
            tu = null;
            den = null;
            apDungLoc();
        });

        viewModel.getBaoCao().observe(getViewLifecycleOwner(), this::hienThi);
        ManHinh.quanSatChung(this, viewModel);
        apDungLoc();
    }

    @Override
    public void onSaveInstanceState(@NonNull Bundle outState) {
        super.onSaveInstanceState(outState);
        outState.putString(KEY_TU, tu);
        outState.putString(KEY_DEN, den);
    }

    private void chonNgay(boolean laTu) {
        String daChon = laTu ? tu : den;
        Calendar c = Calendar.getInstance();
        if (daChon != null) {
            c.set(Integer.parseInt(daChon.substring(0, 4)), Integer.parseInt(daChon.substring(5, 7)) - 1,
                    Integer.parseInt(daChon.substring(8, 10)));
        }
        new DatePickerDialog(requireContext(), (p, nam, thang0, ngay) -> {
            String iso = DinhDang.ngayIso(nam, thang0 + 1, ngay);
            if (laTu) tu = iso;
            else den = iso;
            apDungLoc();
        }, c.get(Calendar.YEAR), c.get(Calendar.MONTH), c.get(Calendar.DAY_OF_MONTH)).show();
    }

    /** Kiểm tra "từ ngày" không sau "đến ngày" trước khi gọi API (backend cũng trả 400). */
    private void apDungLoc() {
        btnTu.setText(tu == null ? getString(R.string.tu_ngay_trong) : getString(R.string.tu_ngay_x, DinhDang.ngay(tu)));
        btnDen.setText(den == null ? getString(R.string.den_ngay_trong) : getString(R.string.den_ngay_x, DinhDang.ngay(den)));
        boolean sai = tu != null && den != null && KiemTraForm.sauNgay(tu, den);
        tvLoiLoc.setVisibility(sai ? View.VISIBLE : View.GONE);
        if (sai) return;
        viewModel.tai(tu, den);
    }

    private void hienThi(TrangThai<BaoCaoDoanhSo> tt) {
        khung.hien(tt, noiDung, false);
        if (tt.loai != TrangThai.Loai.THANH_CONG) return;
        BaoCaoDoanhSo bc = tt.duLieu;

        tvTongDoanhSo.setText(DinhDang.tien(bc.tong.doanhSo));
        tvTongDon.setText(getString(R.string.tong_don_so_luong, bc.tong.soDon, bc.tong.soLuong));

        List<String> nhanVung = new ArrayList<>();
        long[] dsVung = new long[bc.theoVung.size()];
        for (int i = 0; i < bc.theoVung.size(); i++) {
            nhanVung.add(bc.theoVung.get(i).tenVung);
            dsVung[i] = bc.theoVung.get(i).doanhSo;
        }
        bdVung.datDuLieu(nhanVung, dsVung);
        bdVung.setContentDescription(moTaBieuDo(nhanVung, dsVung));

        List<String> nhanSao = new ArrayList<>();
        long[] dsSao = new long[bc.theoHangSao.size()];
        for (int i = 0; i < bc.theoHangSao.size(); i++) {
            nhanSao.add(getString(R.string.hang_sao_ngan, bc.theoHangSao.get(i).hangSao));
            dsSao[i] = bc.theoHangSao.get(i).doanhSo;
        }
        bdHangSao.datDuLieu(nhanSao, dsSao);
        bdHangSao.setContentDescription(moTaBieuDo(nhanSao, dsSao));

        veTop(bc.nhaCungCapBanChay);
    }

    /** Biểu đồ tự vẽ không có chữ cho trình đọc màn hình, nên ghép mô tả từ số liệu. */
    private String moTaBieuDo(List<String> nhan, long[] giaTri) {
        StringBuilder sb = new StringBuilder();
        for (int i = 0; i < nhan.size(); i++) {
            if (i > 0) sb.append("; ");
            sb.append(nhan.get(i)).append(": ").append(DinhDang.tien(giaTri[i]));
        }
        return sb.toString();
    }

    private void veTop(List<BaoCaoDoanhSo.NhaCungCapBanChay> top) {
        dsTop.removeAllViews();
        boolean co = top != null && !top.isEmpty();
        tvTrongTop.setVisibility(co ? View.GONE : View.VISIBLE);
        if (!co) return;
        LayoutInflater inf = getLayoutInflater();
        for (int i = 0; i < top.size(); i++) {
            BaoCaoDoanhSo.NhaCungCapBanChay n = top.get(i);
            View v = inf.inflate(R.layout.item_top_ncc, dsTop, false);
            ((TextView) v.findViewById(R.id.tvHang)).setText(String.valueOf(i + 1));
            ((TextView) v.findViewById(R.id.tvTenNcc)).setText(n.ten);
            ((TextView) v.findViewById(R.id.tvVungNcc)).setText(getString(R.string.vung_don_so_luong,
                    n.tenVung, n.soDon, n.soLuong));
            ((TextView) v.findViewById(R.id.tvDoanhSoNcc)).setText(DinhDang.tien(n.doanhSo));
            dsTop.addView(v);
        }
    }
}
